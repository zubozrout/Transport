"use strict";

var Departures = function(parent, data) {
    this.parent = parent || {};
    this.data = data || {};
    this.id = this.data.id || null;
    this.trains = this.data.trains || [];

    this.getRouteCoors = false;

    this.detail();
    return this;
}

