"use strict";

var TransportOption = function(data) {
    data = data || {};
    this.data = data.raw || {};
    this.id = this.data.id || null;
    this.dbConnection = data.dbConnection || null;

    this.cityOptions = null;
    this.connections = [];

    return this;
}

TransportOption.prototype.isUsed = function() {
    var allUsedConnectionTypes = this.dbConnection.getAllUsedTypesFromSavedStations();
    return allUsedConnectionTypes.indexOf(this.id) > -1;
}

TransportOption.prototype.getId = function(locale) {
    return this.id;
}

TransportOption.prototype.getName = function(locale) {
    if(!this.name) {
        locale = locale || 0;
        this.name = this.data.name ? this.data.name[locale] : "";
    }
    return this.name;
}

TransportOption.prototype.getNameExt = function(locale) {
    if(!this.nameExt) {
        locale = locale || 0;
        this.nameExt = this.data.nameExt ? this.data.nameExt[locale] : "";
    }
    return this.nameExt;
}

TransportOption.prototype.getTitle = function(locale) {
    if(!this.title) {
        locale = locale || 0;
        this.title = this.data.title ? this.data.title[locale] : "";
    }
    return this.title;
}

TransportOption.prototype.getDescription = function(locale) {
    if(!this.description) {
        locale = locale || 0;
        this.description = this.data.description ? this.data.description[locale] : "";
    }
    return this.description;
}

TransportOption.prototype.getCity = function(locale) {
    if(!this.city) {
        locale = locale || 0;
        this.city = this.getTimetableInfo(0).city ? this.getTimetableInfo().city[locale] : "";
    }
    return this.city;
}

TransportOption.prototype.getHomeState = function() {
    if(!this.homeState) {
        var homeState = this.getTimetableInfo().homeState;
        if(homeState) {
            if(homeState.indexOf("CZ") !== -1) {
                this.homeState = qsTr("Czech Republic");
            }
            else if(homeState.indexOf("SK") !== -1) {
                this.homeState = qsTr("Slovak Republic");
            }

            if(homeState.indexOf("*") !== -1) {
                this.homeState += "*";
            }
        }
    }
    return this.homeState;
}

TransportOption.prototype.getTimetableInfo = function(index) {
    index = index || 0;
    if(this.data.timetableInfo) {
        return this.data.timetableInfo[index];
    }
    return {};
}

TransportOption.prototype.getValidity = function(index) {
    var timetableInfo = this.getTimetableInfo(index);
    var froms = timetableInfo.ttValidFrom.split(".");
    var tos = timetableInfo.ttValidTo.split(".");
    var from = new Date(froms[2], froms[1] - 1, froms[0], 0, 0, 0, 0);
    var to = new Date(tos[2], tos[1] - 1, tos[0], 0, 0, 0, 0);

    return {
        from: from,
        to: to
    };
}

TransportOption.prototype.getConnectionParmsInfo = function() {
	return this.data.connectionParmsInfo;
}

TransportOption.prototype.searchStations = function(mask, call, failCall) {
    if(!this.cityOptions) {
        this.cityOptions = new CityOptions({
            id: this.id,
            dbConnection: this.dbConnection
        });

        if(!this.cityOptions) {
            this.cityOptions.abort();
            if(failCall) {
                failCall(this.cityOptions);
            }
        }
    }

    return this.cityOptions.getStops(mask, call, failCall);
}

TransportOption.prototype.searchSavedStationsByLocation = function(coords) {
    return this.dbConnection.getNearbyStopsByKey(this.id, coords)
}

TransportOption.prototype.abort = function() {
    if(this.request) {
        this.request.abort();
    }
}

TransportOption.prototype.abortAll = function() {
    if(this.cityOptions) {
        this.cityOptions.abort();
    }
    if(this.connections) {
        for(var i = 0; i < this.connections.length; i++) {
            this.connections[i].abort();
        }
    }
}

TransportOption.prototype.createConnection = function(data) {
    var oldConnection = this.checkIfConnectionExists(data);
    if(!oldConnection) {
        var connection = new Connections({
            id: this.id,
            dbConnection: this.dbConnection,
            data: data
        });
        this.connections.push(connection);
        return connection;
    }
    oldConnection.clearAllConnections();
    return oldConnection;
}

TransportOption.prototype.checkIfConnectionExists = function(data) {
    for(var i = 0; i < this.connections.length; i++) {
        var connectionData = this.connections[i].data;
        var forcestring = false;
        var compareStop = function(stopA, stopB) {
            if(stopA && stopB) {
                var stopAID = "";
                if(stopA instanceof Stop) {
                    stopAID = stopA.getItem();
                }
                else {
                    if(typeof stopA === typeof "string") {
                        stopAID = stopA;
                        forcestring = true;
                    }
                    else {
                        stopAID = stopA.data.item.id;
                    }
                }

                var stopBID = "";
                if(stopB instanceof Stop) {
                    stopBID = stopB.getItem();
                }
                else {
                    if(typeof stopBID === typeof "string") {
                        stopBID = stopB;
                    }
                    else {
                        if(forcestring) {
                            stopBID = stopB.data.item.name;
                        }
                        else {
                            stopBID = stopB.data.item.id;
                        }
                    }
                }

                if(stopAID === stopBID) {
                    return true;
                }
                return false;
            }
            else if(stopA && !stopB || !stopA && stopB) {
                return false;
            }
            return true;
        }
        if(compareStop(data.from, connectionData.from) && compareStop(data.to, connectionData.to) && compareStop(data.via, connectionData.via)) {
            if(connectionData.departure === data.departure && connectionData.time === data.time && connectionData.change === data.change) {
                return this.connections[i];
            }
        }
    }
    return null;
}

TransportOption.prototype.removeConnectionById = function(id) {
    for(var i = 0; i < this.connections.length; i++) {
        if(this.connections[i].id === id) {
            this.connections.splice(i, 1);
        }
    }
    return this;
}

TransportOption.prototype.getAllConnections = function() {
    var connections = [];
    for(var i = 0; i < this.connections.length; i++) {
        if(this.connections[i].getAllConnections().length > 0) {
            connections.push(this.connections[i]);
        }
    }
    return connections;
}

TransportOption.prototype.departures = function(data) {
    if(data) {
        var stop = data.stop;
        var time = data.time;
        var isDep = data.isDep || false;
        var line = data.line || null;
        var limit = 10;

        var requestURL = "https://ext.crws.cz/api/"
        requestURL += this.id + "/departureTables";
        requestURL += "?from=" + stop;
        requestURL += time ? ("&dateTime=" + time) : "";
        requestURL += "&isDep=" + isDep;
        requestURL += line ? "&line=" + line : "";
        requestURL += "&maxObjectsCount=" + limit;
        requestURL += "&ttInfoDetails=TRTYPEID_ITEM";

        var self = this;
        this.request = GeneralTranport.getContent(requestURL, function(response) {
            if(response && response.data) {
                console.log(response.data);
            }
        });
    }
    return this;
}

