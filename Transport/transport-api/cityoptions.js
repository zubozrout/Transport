"use strict";

var CityOptions = function(data) {
    data = data || {};
    this.id = data.id || null;
    this.dbConnection = data.dbConnection || null;
    this.limit = 10;
    this.minSearchTriggerLength = 5;
    this.searchMode = "EXACT";

    this.stops = [];

    return this;
}

CityOptions.prototype.getStops = function(mask, call, failCall) {
    mask = mask || "";
    if(!mask) {
        return false;
    }

    this.abort();

    var transportOptions = null;
    if(this.dbConnection) {
        transportOptions = this.dbConnection.getStationsByName(this.id, mask);
    }

    if(transportOptions && transportOptions.length > 0) {
        for(var i = 0; i < transportOptions.length; i++) {
            var response = {};
            response.item = {};
            response.item.item = transportOptions[i].item;
            response.item.name = transportOptions[i].value;
            response.coorX = transportOptions[i].coorX;
            response.coorY = transportOptions[i].coorX;
            this.parseStop(response);
        }
        call(this, "DB");
    }

    if(!transportOptions || transportOptions.length < this.minSearchTriggerLength) {
        var self = this;
        this.request = GeneralTranport.getContent("https://ext.crws.cz/api/" + this.id + "/timetableObjects/0?mask=" + mask + "&ttInfoDetails=ITEM&ttInfoDetails=COOR" + "&searchMode=" + this.searchMode + "&maxCount=" + this.limit, function(response) {
            if(response && response.data) {
                self.parseStops(GeneralTranport.stringToObj(response.data));
                call(self, {
                    caller: self,
                    source: "REMOTE",
                    status: response.status
                });
            }
            else {
                failCall(self, {
                    caller: self,
                    source: "REMOTE",
                    status: response.status
                });
            }
        });
    }

    return this;
}

CityOptions.prototype.abort = function() {
    if(this.request) {
        this.request.abort();
    }
}

CityOptions.prototype.parseStops = function(stops) {
    stops.data = stops.data || {};
    for(var key in stops.data) {
        this.parseStop(stops.data[key]);
    }
    return this;
}

CityOptions.prototype.parseStop = function(data) {
    data = data || {};
    var newStop = new Stop(data, {
        transportID: this.id,
        dbConnection: this.dbConnection
    });

    var exists = false;
    for(var i = 0; i < this.stops.length; i++) {
        if(this.stops[i].getItem() === newStop.getItem()) {
            exists = true;
        }
    }

    if(!exists) {
        this.stops.push(newStop);
    }
    return this;
}

CityOptions.prototype.getInnerStops = function(mask) {
    var results = [];
    for(var i = 0; i < this.stops.length; i++) {
        var strippedStopName = GeneralTranport.baseString(this.stops[i].getName());
        var strippedMask = GeneralTranport.baseString(mask);

        if(strippedStopName.indexOf(strippedMask) !== -1) {
            results.push(this.stops[i]);
            if(results.length === this.limit) {
                break;
            }
        }
    }
    return results;
}

CityOptions.prototype.getStopsByItem = function(item) {
    for(var i = 0; i < this.stops.length; i++) {
        if(this.stops[i].getItem() === item) {
            return this.stops[i];
        }
    }
    return false;
}

