"use strict";

var Connections = function(id, data) {
    this.id = id || null;
    this.data = data || {};
    var from = this.data.from || null;
    if(from) {
        this.from = new Stop(from.data, from.parentData || {});
    }
    var to = this.data.to || null;
    if(to) {
        this.to = new Stop(to.data, to.parentData || {});
    }
    var via = this.data.via || null;
    if(via) {
        this.via = new Stop(via.data, via.parentData || {});
    }
    this.change = this.data.change || 0;
    this.time = this.data.time || null;
    this.departure = typeof this.data.departure !== typeof undefined ? this.data.departure : true;

    this.limit = this.data.limit || 10;
    this.searchMode = this.data.searchMode || "EXACT";

    this.saveStopsToDBOnSearchDefault = true;
    this.saveStopsToDBOnSearchFailureDefault = false;

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
    var saveToDB = params.saveToDB || this.saveStopsToDBOnSearchDefault;
    var saveToDBonFailure = params.saveToDBonFailure || this.saveStopsToDBOnSearchDefault;

    var fromValue = this.from;
    if(this.from instanceof Stop) {
        fromValue = this.from.getName();
    }
    var toValue = this.to;
    if(this.to instanceof Stop) {
        toValue = this.to.getName();
    }
    var viaValue = via;
    if(this.via instanceof Stop) {
        viaValue = this.via.getName();
    }

    var requestURL = "https://ext.crws.cz/api/";
    requestURL += this.id + "/connections";
    requestURL += "?from=" + fromValue;
    requestURL += "&to=" + toValue;
    requestURL += viaValue ? ("&via=" + viaValue) : "";
    requestURL += this.change ? ("&change=" + this.change) : "";
    requestURL += time ? ("&dateTime=" + time) : "";
    requestURL += "&isDep=" + departure;
    requestURL += "&maxObjectsCount=2";
    requestURL += "&maxCount=" + this.limit;
    requestURL += "&ttInfoDetails=TRTYPEID_ITEM";

    var self = this;
    this.request = GeneralTranport.getContent(requestURL, function(response) {
        if(response) {
            if(self.parseResponse(GeneralTranport.stringToObj(response))) {
                if(callback) {
                    callback(self, "SUCCESS");
                }

                if(!saveToDBonFailure && saveToDB) {
                    self.saveStopsToDB(via);
                }
            }
            else {
                callback(false, "FAIL");
            }
        }
        else {
            callback(false, "FAIL");
        }
    });

    if(saveToDBonFailure) {
        this.saveStopsToDB(via);
    }

    return this;
}

Connections.prototype.saveStopsToDB = function(via) {
    if(this.from && this.from instanceof Stop) {
        this.from.saveToDB();
    }
    if(this.to && this.to instanceof Stop) {
        this.to.saveToDB();
    }
    if(via && via instanceof Stop) {
        via.saveToDB();
    }
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
                if(response) {
                    if(self.parseConnInfo(GeneralTranport.stringToObj(response), backwards)) {
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

