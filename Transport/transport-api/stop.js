"use strict";

var Stop = function(data, parentData) {
    this.data = data || {};
    this.data.item = this.data.item || {};

    this.parentData = parentData || {};
    this.transportID = this.parentData.transportID || null;
    this.dbConnection = this.parentData.dbConnection || null;

    return this;
}

Stop.prototype.getName = function() {
    return this.data.item.name || null;
}

Stop.prototype.getListId = function() {
    return this.data.item.listId || null;
}

Stop.prototype.getItem = function() {
    return this.data.item.item || null;
}

Stop.prototype.getCoor = function() {
    return {
        coorX: this.data.coorX,
        coorY: this.data.coorY
    };
}

Stop.prototype.saveToDB = function() {
    if(this.transportID && this.dbConnection) {
        this.dbConnection.saveStation(this.transportID, {
            value: this.getName(),
            item: this.getItem(),
            coorX: this.getCoor().coorX,
            coorY: this.getCoor().coorY
        });
    }
}
