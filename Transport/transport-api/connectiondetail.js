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

ConnectionDetail.prototype.stop = function(stop, dateArrCopy, dateDepCopy) {
    stop = stop || {};

    var arrTime = dateArrCopy || "";
    var depTime = dateDepCopy || "";

    var stopData = {};
    stopData.station = this.station(stop.station);
    stopData.arrTime = stop.arrTime ? arrTime.toString() : "";
    stopData.depTime = stop.depTime ? depTime.toString() : "";
    stopData.dist = stop.dist || "";
    return {
        stopData: stopData,
        arrTime: arrTime,
        depTime: depTime
    };
}

ConnectionDetail.prototype.checkStops = function(data) {
    data = data || {};

    var route = data.route || [];
    var routeDateDep = data.dateTime1 || new Date(); // Route departure
    var routeDateArr = data.dateTime2 || new Date(); // Route arrival
    var from = data.from || 0; // Route start
    var to = data.to || route.length - 1; // Route end

    var stops = [];
    if(route) {
        var stopInfo = [];
        var i;

        for(i = 0; i < route.length; i++) {
            if(i < from) {
                route[i].routeStarted = false;
            }
            else {
                route[i].routeStarted = true;
            }

            if(i <= to) {
                route[i].routeEnded = false;
            }
            else {
                route[i].routeEnded = true;
            }

            var stopArrTime = route[i].arrTime || null;
            var stopDepTime = route[i].depTime || null;

            var prevStop = (i - 1 >= 0) ? route[i - 1] : null;

            if(prevStop) {
                route[i].dateArr = this.timeStringToDate(stopArrTime, prevStop.dateArr || prevStop.dateDep);
                route[i].dateDep = this.timeStringToDate(stopDepTime, prevStop.dateDep || prevStop.dateArr);
            }
            else {
                route[i].dateArr = this.timeStringToDate(stopArrTime, routeDateDep);
                route[i].dateDep = this.timeStringToDate(stopDepTime, routeDateDep);
            }
        }

        var fromStopArrival = route[from].dateArr || route[from].dateDep;
        var fromStopDeparture = route[from].dateDep || route[from].dateArr;
        var toStopArrival = route[to].dateArr || route[to].dateDep;
        var toStopDeparture = route[to].dateDep || route[to].dateArr;

        var prevStopArrival = fromStopArrival;
        var prevStopDeparture = fromStopDeparture;
        for(i = from + 1; i < to; i++) {
            if(route[i].dateArr && route[i].dateArr < prevStopArrival) {
                for(var j = i; j < to; j++) {
                    route[j].dateArr.setDate(prevStopArrival.getDate() + 1);
                }
            }
            if(route[i].dateDep && route[i].dateDep < prevStopDeparture) {
                for(var j = i; j < to; j++) {
                    route[i].dateDep.setDate(prevStopDeparture.getDate() + 1);
                }
            }
            prevStopArrival = route[i].dateArr || route[i].dateDep;
            prevStopDeparture = route[i].dateDep || route[i].dateArr;
        }

        prevStopArrival = toStopArrival;
        prevStopDeparture = toStopDeparture;
        for(i = to + 1; i < route.length; i++) {
            if(route[i].dateArr && route[i].dateArr < prevStopArrival) {
                for(var j = i; j < to; j++) {
                    route[j].dateArr.setDate(prevStopArrival.getDate() + 1);
                }
            }
            if(route[i].dateDep && route[i].dateDep < prevStopDeparture) {
                for(var j = i; j < to; j++) {
                    route[i].dateDep.setDate(prevStopDeparture.getDate() + 1);
                }
            }
            prevStopArrival = route[i].dateArr || route[i].dateDep;
            prevStopDeparture = route[i].dateDep || route[i].dateArr;
        }

        var followingStopArrival = fromStopArrival;
        var followingStopDeparture = fromStopDeparture;
        for(i = from - 1; i >= 0; i--) {
            if(route[i].dateArr && route[i].dateArr > followingStopArrival) {
                route[i].dateArr.setDate(followingStopArrival.getDate() - 1);
            }
            if(route[i].dateDep && route[i].dateDep > followingStopDeparture) {
                route[i].dateDep.setDate(followingStopDeparture.getDate() - 1);
            }
            followingStopArrival = route[i].dateArr || route[i].dateDep;
            followingStopDeparture = route[i].dateDep || route[i].dateArr;
        }

        for(var i = 0; i < route.length; i++) {
            var stop = this.stop(route[i], route[i].dateArr, route[i].dateDep);
            stop.stopData.routeStarted = route[i].routeStarted;
            stop.stopData.routeEnded = route[i].routeEnded;
            stop.stopData.stopPassed = route[i].routeStarted && !route[i].routeEnded;
            stops.push(stop.stopData);
        }
    }
    return stops;
}

ConnectionDetail.prototype.trainRoute = function(data) {
    return this.checkStops(data);
}

ConnectionDetail.prototype.trainRouteCoors = function(data) {
    var route = data.route || [];
    var paths = [];
    for(var i = 0; i < route.length; i++) {
		var path = {};
		path.coorX = route[i].coorX;
		path.coorY = route[i].coorY;
		path.active = i >= (data.from || 0) && i < (data.to || route.length);
		paths.push(path);
	}
	return paths;
}

ConnectionDetail.prototype.parseTrainDetail = function(train) {
    train = train || {};
    var detailData = {};
    detailData.from = train.from || "";
    detailData.to = train.to || "";
    detailData.dateTime1 = train.dateTime1 ? dateStringtoDate(String(train.dateTime1)) : "";
    detailData.dateTime2 = train.dateTime2 ? dateStringtoDate(String(train.dateTime2)) : "";
    detailData.distance = train.distance || "";
    detailData.timeLength = train.timeLength || "";
    detailData.stdChange = train.stdChange || 0;
    detailData.from = train.from || 0;
    detailData.to = train.to || (train.trainData ? train.trainData.route.length : 0)
    detailData.trainInfo = this.trainInfo(train.trainData);
    detailData.route = this.trainRoute({
        route: train.trainData.route,
        dateTime1: detailData.dateTime1,
        dateTime2: detailData.dateTime2,
        from: train.from,
        to: train.to
    });
    detailData.routeCoors = this.trainRouteCoors({
		route: train.trainData.route,
		from: train.from,
        to: train.to
	});
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
    if(timeString && date) {
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

ConnectionDetail.prototype.whoAmI = function() {
    return "ConnectionDetail";
}
