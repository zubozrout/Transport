"use strict";

var ConnectionDetail = function(data) {
    this.data = data || {};

    this.id = this.data.id || 0;
    this.distance = this.data.distance || 0;
    this.timeLength = this.data.timeLength || 0;
    this.price = this.data.price || 0;
    this.trains = this.data.trains || [];

    return this;
}

ConnectionDetail.prototype.parseTrain = function(trainData) {
    trainData = trainData || {};
    var train = {};
    train.hasOwnProperty()
}

ConnectionDetail.prototype.toString = function() {
    return JSON.stringify(this.data);
}
