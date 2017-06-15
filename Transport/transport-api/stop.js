"use strict";

var Stop = function(data, parentData) {
    if(typeof data === typeof "string") {
        this.basic = true;
        this.value = data;
    }
    else {
        this.basic = false;
        this.data = data || {};
        this.id = this.data.id || -1;
        this.data.item = this.data.item || {};
    }

    this.parentData = parentData || {};
    this.transportID = this.parentData.transportID || null;
    this.dbConnection = this.parentData.dbConnection || null;
    return this;
}

Stop.prototype.getName = function() {
    if(!this.basic) {
        return this.data.item.name || null;
    }
    return this.value || null;
}

Stop.prototype.getListId = function() {
    if(!this.basic) {
        return this.data.item.listId || null;
    }
    return null;
}

Stop.prototype.getItem = function() {
    if(!this.basic) {
        return this.data.item.item || null;
    }
    return null;
}

Stop.prototype.setItem = function(item) {
    if(!this.basic) {
        this.data.item.item = item;
        return true;
    }
    return false;
}

Stop.prototype.getCoor = function() {
    if(!this.basic) {
        return {
            coorX: this.data.coorX,
            coorY: this.data.coorY
        };
    }
    return null;
}

Stop.prototype.saveToDB = function() {
    if(!this.basic && this.transportID && this.dbConnection) {
        return this.dbConnection.saveStation(this.transportID, {
            value: this.getName(),
            item: this.getItem(),
            listId: this.getListId(),
            coorX: this.getCoor().coorX,
            coorY: this.getCoor().coorY
        });
    }
    return false;
}
