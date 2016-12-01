"use strict";

var ConnectionDetail = function(data) {
    this.data = data || {};

    this.id = this.data.id || 0;
    this.distance = this.data.distance || 0;
    this.timeLength = this.data.timeLength || 0;
    this.price = this.data.price || 0;
    this.trains = this.data.trains || [];

    this.parsedTrains = [];
    this.parseTrains();

    return this;
}

ConnectionDetail.prototype.trainInfo = function(trainData) {
    trainData = trainData || {};
    var info = trainData.info;
    var trainInfo = {};
    trainInfo.train = info.train || 0;
    trainInfo.num = info.num1 || 0;
    trainInfo.type = info.type || "";
    trainInfo.typeName = info.typeName || "";
    trainInfo.color = info.color || "00000000";
    trainInfo.id = info.id || 0;
    trainInfo.fixedCodes = info.fixedCodes || [];
    return trainInfo;
}

ConnectionDetail.prototype.station = function(station) {
    station = station || {};
    var stationData = {};
    stationData.station = station.station || 0;
    stationData.name = station.name || "";
    stationData.key = station.key || "";
    stationData.coorX = station.coorX || "";
    stationData.coorY = station.coorY || "";
    return stationData;
}

ConnectionDetail.prototype.stop = function(stop, dateStartCopy, dateEndCopy) {
    stop = stop || {};

    var depTime = dateStartCopy || "";
    var arrTime = dateEndCopy || "";

    var stopData = {};
    stopData.station = this.station(stop.station);
    stopData.depTime = stop.depTime ? depTime.toString() : "";
    stopData.arrTime = stop.arrTime ? arrTime.toString() : "";
    stopData.dist = stop.dist || "";
    return {
        stopData: stopData,
        depTime: depTime,
        arrTime: arrTime
    };
}

ConnectionDetail.prototype.checkStops = function(route, dateStart, dateEnd) {
    route = route || [];

    dateStart = dateStart || new Date();
    dateEnd = dateEnd || new Date();

    var stops = [];
    if(route) {
        var stopInfo = [];
        var routeStarted = false;
        var routeEnded = false;
        for(var i = 0; i < route.length; i++) {
            var stopDepTime = route[i].depTime || null;
            var stopArrTime = route[i].arrTime || null;

            var prevStop = (stops.lenght > 0 && stops.length - 1 === i) ? stops[i - 1] : null;

            var dateStartCopy = this.timeStringToDate(stopDepTime, dateStart);
            var dateEndCopy = this.timeStringToDate(stopArrTime, dateEnd);
            if(!routeStarted && dateStartCopy) {
                if(prevStop) {
                    if(dateStartCopy > prevStop.arrTime) {
                        dateStartCopy.setDate(dateStartCopy.getDate() - 1);
                    }
                }
                else if(dateStartCopy < dateStart) {
                }
                else {
                    routeStarted = true;
                }
            }
            else {
                if(prevStop) {
                    if(dateStartCopy && dateStartCopy > prevStop.depTime) {
                        dateStartCopy.setDate(dateStartCopy.getDate() + 1);
                    }
                }
                if(dateStartCopy && dateStartCopy > dateEnd) {
                    routeEnded = true;
                }
                if(dateEndCopy && dateEndCopy > dateEnd) {
                    routeEnded = true;
                }
            }

            var stop = this.stop(route[i], dateStartCopy, dateEndCopy);
            stop.stopData.routeStarted = routeStarted;
            stop.stopData.routeEnded = routeEnded;
            stop.stopData.stopPassed = routeStarted && !routeEnded;
            stops.push(stop.stopData);
        }
    }
    return stops;
}


ConnectionDetail.prototype.trainRoute = function(route, dateStart, dateEnd) {
    return this.checkStops(route, dateStart, dateEnd);
}

ConnectionDetail.prototype.parseTrainDetail = function(train) {
    train = train || {};
    var detailData = {};
    detailData.from = train.from || "";
    detailData.to = train.to || "";
    detailData.dateTime1 = train.dateTime1 ? dateStringtoDate(train.dateTime1) : "";
    detailData.dateTime2 = train.dateTime2 ? dateStringtoDate(train.dateTime2) : "";
    detailData.distance = train.distance || "";
    detailData.timeLength = train.timeLength || "";
    detailData.trainInfo = this.trainInfo(train.trainData);
    detailData.route = this.trainRoute(train.trainData.route, detailData.dateTime1, detailData.dateTime2);
    return detailData;
}

ConnectionDetail.prototype.parseTrains = function() {
    for(var i = 0; i < this.trains.length; i++) {
        this.parsedTrains.push(this.parseTrainDetail(this.trains[i]));
    }
}

ConnectionDetail.prototype.trainLength = function(index) {
    return this.parsedTrains.length;
}

ConnectionDetail.prototype.getTrain = function(index) {
    if(index >= 0 && index < this.parsedTrains.length) {
        return this.parsedTrains[index];
    }
    return null;
}

ConnectionDetail.prototype.timeStringToDate = function(timeString, date) {
    if(timeString) {
        var dateCopy = new Date(date);
        var timeParts = timeString.split(":");
        dateCopy.setHours(timeParts[0], timeParts[1], 0, 0);
        return dateCopy;
    }
    return null;
}

ConnectionDetail.prototype.toString = function() {
    return JSON.stringify(this.data);
}
