"use strict";

var Connection = function(parent, data) {
    this.parent = parent || {};
    this.data = data || {};
    this.id = this.data.id || null;
    this.trains = this.data.trains || [];

    this.getRouteCoors = false;

    this.detail = null;

    //this.getDetail();
    return this;
}

Connection.prototype.toString = function() {
    return JSON.stringify(this.data);
}

Connection.prototype.getDetail = function() {
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
                self.parseDetail(GeneralTranport.stringToObj(response));
            }
        });
    }
    return this;
}

Connection.prototype.abort = function() {
    if(this.request) {
        this.request.abort();
    }
}

Connection.prototype.parseDetail = function(response) {
    this.detail = new ConnectionDetail(response);
    return this;
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
