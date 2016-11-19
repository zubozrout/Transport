"use strict";

var TransportOptions = function(data) {
    data = data || {};

    this.id = "id";
    this.transportsData = {};
    this.transports = [];

    this.callback = data.callback || null;
    this.dbConnection = data.dbConnection || null;

    this.selectedIndex = -1;
    return this;
}

TransportOptions.prototype.fetchTrasports = function(forceServer) {
    var transportOptions = null;
    if(this.dbConnection) {
        transportOptions = this.dbConnection.getDataJSON("transportOptions");
    }

    var checkServer = forceServer || !transportOptions || GeneralTranport.dateOlderThan(new Date(transportOptions.date), new Date(), "week");
    if(checkServer) {
        this.fetchServerTransports();
    }
    else {
        this.fetchDBTransports(transportOptions);
    }

    return this;
}

TransportOptions.prototype.fetchDBTransports = function(transportOptions) {
    this.transportsData = GeneralTranport.stringToObj(transportOptions.value);
    this.parseAllTransports();
    this.selectIndex(this.transports.length - 1);

    if(this.callback) {
        this.callback(this);
    }
}

TransportOptions.prototype.fetchServerTransports = function() {
    var self = this;
    GeneralTranport.getContent("https://ext.crws.cz/api/", function(response) {
        if(response) {
            if(self.dbConnection) {
                self.dbConnection.saveDataJSON("transportOptions", response);
            }
            self.transportsData = GeneralTranport.stringToObj(response);
            self.parseAllTransports();
            self.selectIndex(self.transports.length - 1);

            if(self.callback) {
                self.callback(self);
            }
        }
    });
}

TransportOptions.prototype.parseAllTransports = function() {
    for(var key in this.transportsData.data) {
        this.transports.push(new TransportOption({
             raw: this.transportsData.data[key],
             dbConnection: this.dbConnection
         }));
    }

    return this;
}

TransportOptions.prototype.selectIndex = function(index) {
    if(this.transports.length > index && index >= 0) {
        this.selectedIndex = index;
    }
    return this;
}

TransportOptions.prototype.getSelectedIndex = function() {
    return this.selectedIndex;
}

TransportOptions.prototype.getSelectedTransport = function() {
    if(this.getSelectedIndex() >= 0) {
        return this.transports[this.getSelectedIndex()];
    }
    return null;
}

TransportOptions.prototype.setTransportUpdateCallback = function(callback) {
    this.callback = callback;
    return this;
}
