"use strict";

var ConnectionDetail = function(data) {
    this.data = data || {};
    return this;
}

ConnectionDetail.prototype.toString = function() {
    return JSON.stringify(this.data);
}
