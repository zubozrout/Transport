"use strict";

var TransportOptions = function(data) {
    data = data || {};

    this.id = "id";
    this.transportsData = {};
    this.transports = [];

    this.callback = data.callback || null;
    this.dbConnection = data.dbConnection || null;

    this.transportOptionPrefix = "transportOption-";

    this.selectedIndex = -1;
    return this;
}

TransportOptions.prototype.clearAll = function(database) {
    console.log("Clearing app data...");
    if(database === true) {
        console.log("Dropping tables...");
        this.dbConnection.dropTables();
        console.log("Re-creating tables...");
        this.dbConnection.createTables();
    }

    console.log("Clearing this instance cached data...");
    this.transportsData = {};
    this.transports = [];

    if(this.callback) {
        console.log("Calling update info callback...");
        this.callback(this);
    }
}

TransportOptions.prototype.fetchTrasports = function(forceServer, callback) {
    var transportOptions = null;
    if(this.dbConnection) {
        transportOptions = this.dbConnection.getDataJSON("transportOptions");
    }

    var checkServer = forceServer || !transportOptions || GeneralTranport.dateOlderThan(new Date(transportOptions.date), new Date(), "week");
    if(checkServer) {
        this.fetchServerTransports(callback);
    }
    else {
        this.fetchDBTransports(transportOptions, callback);
    }

    return this;
}

TransportOptions.prototype.fetchDBTransports = function(transportOptions, callback) {
    console.log("Fetching local DB transport info ...");
    this.transportsData = GeneralTranport.stringToObj(transportOptions.value);
    this.parseAllTransports();
    this.selectIndex(this.transports.length - 1);

    if(this.callback) {
        this.callback(this);
    }

    if(callback) {
        callback(self);
    }
}

TransportOptions.prototype.fetchServerTransports = function(callback) {
    console.log("Fetching server-side (CHAPS s.r.o.) transport info ...");
    var self = this;
    this.request = GeneralTranport.getContent("https://ext.crws.cz/api/", function(response) {
        if(response && response.data) {
            if(self.dbConnection) {
                self.dbConnection.saveDataJSON("transportOptions", response.data);
            }
            self.transportsData = GeneralTranport.stringToObj(response.data);
            self.parseAllTransports();
            self.selectIndex(self.transports.length - 1);

            if(self.callback) {
                self.callback(self);
            }

            if(callback) {
                callback(self);
            }
        }
    });
}

TransportOptions.prototype.parseAllTransports = function() {
    this.transports.length = 0;
    for(var key in this.transportsData.data) {
        var newTransportOption = new TransportOption({
            raw: this.transportsData.data[key],
            dbConnection: this.dbConnection
        })
        this.transports.push(newTransportOption);

        var workingID = newTransportOption.getId();
        var newConnectionData = this.transportsData.data[key];
        var oldConnectionDataSource = this.dbConnection.getDataJSON(this.transportOptionPrefix + workingID);

        if(oldConnectionDataSource) {
            var oldConnectionData = GeneralTranport.stringToObj(oldConnectionDataSource.value);
            if(oldConnectionData.ttValidFrom !== newConnectionData.ttValidFrom || oldConnectionData.ttValidTo !== newConnectionData.ttValidTo) {
                this.saveNewConnectionInfo(workingID, newConnectionData);
                this.dbConnection.clearStationsForId(workingID);
            }
        }
        else {
            this.saveNewConnectionInfo(workingID, newConnectionData);
        }
    }

    return this;
}

TransportOptions.prototype.saveNewConnectionInfo = function(id, newConnectionData) {
    this.dbConnection.saveDataJSON(this.transportOptionPrefix + id, JSON.stringify({
        id: newConnectionData.id,
        loaded: newConnectionData.loaded,
        name: newConnectionData.name,
        nameExt: newConnectionData.nameExt,
        ttValidFrom: newConnectionData.ttValidFrom,
        ttValidTo: newConnectionData.ttValidTo
    }));
}

TransportOptions.prototype.selectIndex = function(index) {
    if(this.transports.length > index && index >= 0) {
        this.selectedIndex = index;
    }
    return this;
}

TransportOptions.prototype.getTransportIndexById = function(id) {
    for(var i = 0; i < this.transports.length; i++) {
        if(this.transports[i].id === id) {
            return i;
        }
    }
    return false;
}

TransportOptions.prototype.getTransportById = function(id) {
    var index = this.getTransportIndexById(id);
    if(index !== false) {
        return this.transports[index];
    }
    return false;
}

TransportOptions.prototype.selectTransportById = function(id) {
    var transport = this.getTransportIndexById(id);
    if(transport !== false) {
        this.selectIndex(transport);
        return this.getSelectedTransport();
    }
    return false;
}

TransportOptions.prototype.getSelectedIndex = function() {
    return this.selectedIndex;
}

TransportOptions.prototype.getSelectedId = function() {
    if(this.transports.length > 0) {
        return this.transports[this.getSelectedIndex()].getId();
    }
    return null;
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

TransportOptions.prototype.abort = function() {
    if(this.request) {
        this.request.abort();
    }
}

