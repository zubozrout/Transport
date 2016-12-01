"use strict";

var Connection = function(parent, data) {
    this.parent = parent || {};
    this.data = data || {};
    this.id = this.data.id || null;
    this.trains = this.data.trains || [];

    this.getRouteCoors = false;

    this.detail = null;

    return this;
}

Connection.prototype.toString = function() {
    return JSON.stringify(this.data);
}

Connection.prototype.getDetail = function(callback, forceUpdate) {
    this.lastCallback = callback;
    if(!forceUpdate && this.detail !== null && callback) {
        callback(this, "SUCCESS");
        return;
    }

    var connectionsID = this.parent.id;
    var handle = this.parent.handle;

    if(connectionsID && handle && this.id) {
        var requestURL = "https://ext.crws.cz/api/";
        requestURL += connectionsID + "/connections/";
        requestURL += handle + "/";
        requestURL += this.id;
        requestURL += "?ttDetails=ROUTE_FULL&ttDetails=TRAIN_INFO&ttDetails=TRTYPE_IN_ID&ttDetails=PRICES&ttDetails=FIXED_CODES&ttDetails=COOR";
        requestURL += this.getRouteCoors ? "&ttDetails=ROUTE_COOR&" : "";

        var self = this;
        this.request = GeneralTranport.getContent(requestURL, function(response) {
            if(response) {
                if(self.parseDetail(GeneralTranport.stringToObj(response))) {
                    if(callback) {
                        callback(self, "SUCCESS");
                    }
                    else {
                        callback(self, "FAIL");
                    }
                }
                else {
                    callback(self, "FAIL");
                }
            }
        });
    }
    return this;
}

Connection.prototype.abort = function() {
    if(this.request) {
        if(this.lastCallback) {
            this.lastCallback(this, "ABORT");
        }
        this.request.abort();
    }
}

Connection.prototype.parseDetail = function(response) {
    this.detail = new ConnectionDetail(response);
    if(this.detail.trainLength() > 0) {
        return true;
    }

    return false;
}

Connection.prototype.getTrain = function(index) {
    if(index >= 0 && index < this.trains.length) {
        return this.trains[index];
    }
    return false;
}

Connection.prototype.getRoute = function(index) {
    return this.route;
}

Connection.prototype.getDistance = function() {
    return this.data.distance;
}

Connection.prototype.getTimeLength = function() {
    return this.data.timeLength;
}

Connection.prototype.getConnectionDetail = function() {
    return this.detail || null;
}
