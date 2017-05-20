"use strict";

var Connections = function(data) {
    data = data || {};
    this.id = data.id || null;
    this.dbConnection = data.dbConnection || null;
    this.data = data.data || {};

    var from = this.data.from || null;
    if(from) {
        this.from = new Stop(from.data || from, from.parentData || {});
    }

    var to = this.data.to || null;
    if(to) {
        this.to = new Stop(to.data || to, to.parentData || {});
    }

    var via = this.data.via || null;
    if(via) {
        this.via = new Stop(via.data || via, via.parentData || {});
    }

    this.change = this.data.change || 0;
    this.time = this.data.time || null;
    this.departure = typeof this.data.departure !== typeof undefined ? this.data.departure : true;

    this.limit = this.data.limit || 10;
    this.searchMode = this.data.searchMode || "EXACT";

    this.config = {};
    this.config.saveStopsToDB = true;
    this.config.saveSearchToDB = true;

    this.connections = [];
    this.handle = null;

    this.map = {
        forward: [],
        backward: [],
        forwardPosition: 0,
        backwardPosition: 0
    };

    return this;
}

Connections.prototype.search = function(params, callback) {
    this.lastCallback = callback;

    params = params || {};
    var time = params.time || this.time;
    var via = params.via || this.via;
    var departure = typeof params.departure !== typeof undefined ? params.departure : this.departure;

    if(!this.from instanceof Stop) {
        return false;
    }
    if(!this.to instanceof Stop) {
        return false
    }
    if(via && !via instanceof Stop) {
        return false;
    }

    var requestURL = "https://ext.crws.cz/api/";
    requestURL += this.id + "/connections";
    requestURL += "?from=" + this.from.getName();
    requestURL += "&to=" + this.to.getName();
    requestURL += via ? ("&via=" + via.getName()) : "";
    requestURL += this.change ? ("&change=" + this.change) : "";
    requestURL += time ? ("&dateTime=" + time) : "";
    requestURL += "&isDep=" + departure;
    requestURL += "&maxObjectsCount=2";
    requestURL += "&maxCount=" + this.limit;
    requestURL += "&ttInfoDetails=TRTYPEID_ITEM";

    var self = this;
    this.request = GeneralTranport.getContent(requestURL, function(response) {
        if(response && response.data) {
            if(self.parseResponse(GeneralTranport.stringToObj(response.data))) {
                if(callback) {
                    callback(self, "SUCCESS");
                }
            }
            else {
                callback(false, "FAIL");
            }
        }
        else {
            callback(false, response.status === 0 ? "ABORT" : "FAIL");
        }
    });

    if(this.config.saveStopsToDB) {
        this.saveStopToDB(this.from);
        this.saveStopToDB(this.to);
        if(via) {
            this.saveStopToDB(via);
        }
    }

    if(this.config.saveSearchToDB) {
        this.saveConnectionToDB({
            id: this.id,
            from: this.from.getItem(),
            to: this.to.getItem(),
            via: via ? via.getItem() : null
        });
    }

    return this;
}

Connections.prototype.saveStopToDB = function(stop) {
    if(stop && stop instanceof Stop) {
        stop.saveToDB();
    }
    return this;
}

Connections.prototype.saveConnectionToDB = function(data) {
    if(this.dbConnection) {
        this.dbConnection.appendSearchToHistory(data);
    }
    return this;
}

Connections.prototype.getNext = function(backwards, callback) {
    if(this.handle && this.connections.length > 0) {
        this.lastCallback = callback;

        var connectionId = backwards ? this.connections[0].id : this.connections[this.connections.length - 1].id;
        if(connectionId) {
            var requestURL = "https://ext.crws.cz/api/";
            requestURL += this.id + "/connections/";
            requestURL += this.handle;
            requestURL += "?connId=" + connectionId;
            requestURL += "&prevConn=" + (backwards ? "true" : "false");
            requestURL += "&listedConnCount=0";
            requestURL += "&maxCount=" + this.limit;

            var self = this;
            console.log(requestURL);
            this.request = GeneralTranport.getContent(requestURL, function(response) {
                if(response && response.data) {
                    if(self.parseConnInfo(GeneralTranport.stringToObj(response.data), backwards)) {
                        if(callback) {
                            callback(self, "SUCCESS");
                        }
                    }
                    else {
                        if(callback) {
                            callback(self, "FAIL");
                        }
                    }
                }
            });
        }
    }
    return this;
}

Connections.prototype.abort = function() {
    if(this.request) {
        if(this.lastCallback) {
            this.lastCallback(this, "ABORT");
        }
        this.request.abort();
    }
}

Connections.prototype.parseResponse = function(response) {
    this.response = response || {};
    this.handle = this.response.handle;

    if(this.parseConnInfo(this.response.connInfo)) {
        return true;
    }

    return false;
}

Connections.prototype.parseConnInfo = function(connInfo, prepend) {
    if(connInfo) {
        var allowPrev = connInfo.allowPrev || false;
        var allowNext = connInfo.allowNext || false;
        this.parseConnections(connInfo.connections, prepend);
        return true;
    }
    return false;
}

Connections.prototype.parseConnections = function(connections, prepend) {
    if(connections) {
        var connectionBunde = [];
        for(var key in connections) {
            var newConnection = new Connection(this, connections[key]);
            if(!this.checkIfConnectionExists(newConnection)) {
                connectionBunde.push(newConnection);
            }
        }

        if(!prepend) {
            Array.prototype.push.apply(this.connections, connectionBunde);
            Array.prototype.push.apply(this.map.forward, connectionBunde);
            this.map.forwardPosition += connectionBunde.length;
        }
        else {
            Array.prototype.unshift.apply(this.connections, connectionBunde);
            Array.prototype.unshift.apply(this.map.backward, connectionBunde);
            this.map.backwardPosition += connectionBunde.length;
        }
    }
}

Connections.prototype.checkIfConnectionExists = function(connection) {
    for(var i = 0; i < this.connections.length; i++) {
        if(this.connections[i].id === connection.id) {
            return true;
        }
    }
    return false;
}

Connections.prototype.getAllConnections = function(position) {
    return this.connections;
}

Connections.prototype.clearAllConnections = function() {
    this.connections = [];
    return this;
}

Connections.prototype.getConnectionsInInterval = function(from, to) {
    if(this.connections && this.connections.length > 0 && from <= to) {
        if(from >= 0 && from < this.connections.length) {
            if(to >= 0 && to < this.connections.length) {
                var connectionsDuplicate = this.connections.slice(0);
                connectionsDuplicate.splice(0, from);
                connectionsDuplicate.splice(to + 1, this.connections.length - 1);
                return connectionsDuplicate;
            }
        }
    }
    return this.connections;
}

Connections.prototype.getLastConnections = function(position) {
    return this.map.forward.slice(this.map.forward.length - this.limit);
}

Connections.prototype.getFirstConnections = function(position) {
    return this.map.backward.slice(0, this.limit);
}

