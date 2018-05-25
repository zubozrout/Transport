"use strict";

function langCode(toInt) {
    var locale = Qt.locale().name;
    var lang = "";
    var num = 0;

    switch(locale.substring(0,2)) {
        case "en":
            lang = "ENGLISH";
            num = 1;
            break;
        case "de":
            lang = "GERMAN";
            num = 2;
            break;
        case "cs":
            lang = "CZECH";
            num = 0;
            break;
        case "sk":
            lang = "SLOVAK";
            num = 3;
            break;
        case "pl":
            lang = "POLISH";
            num = 4;
            break;
        default:
            lang = "ENGLISH";
            num = 1;
            break;
    }

    if(typeof toInt !== typeof undefined && toInt === true) {
        return num;
    }
    return lang;
}

function getTranpsortType(index) {
    switch(index) {
    case 1:
       return "train";
    case 2:
        return "bus";
    case 3:
        return "tram";
    case 4:
       return "trol";
    case 5:
       return "metro";
    case 6:
       return "ship";
    case 7:
       return "air";
    case 8:
       return "taxi";
    case 9:
       return "cableway";
    default:
       return "empty";
    }
}

function dateStringtoDate(dateString) {
    if(!dateString) {
        return "";
    }

    var parts = dateString.split(" ");
    var date = parts[0];
    var time = parts[1];

    var dateTime = {
        day: 0,
        month: 0,
        year: 0,
        hours: 0,
        minutes: 0
    }

    if(date) {
        var dateParts = date.split(".");
        dateTime.day = dateParts[0];
        dateTime.month = parseInt(dateParts[1]) - 1;
        dateTime.year = dateParts[2];
    }

    if(time) {
        var timeParts = time.split(":");
        dateTime.hours = timeParts[0];
        dateTime.minutes = timeParts[1];
    }

    var finalDate = new Date(dateTime.year, dateTime.month, dateTime.day, dateTime.hours, dateTime.minutes, 0, 0, {timeZone:"Europe/Prague"});

    return finalDate;
}

function dateToTimeString(date) {
    if(date) {
        date = new Date(date);

        var hours = String(date.getHours());
        var minutes = String(date.getMinutes());
        if(hours.length === 1) {
            hours = "0" + hours;
        }
        if(minutes.length === 1) {
            minutes = "0" + minutes;
        }
        return hours + ":" + minutes;
    }
    return "";
}

function dateToString(date) {
    if(date) {
        date = new Date(date);

        var day = date.getDate();
        var month = date.getMonth() + 1;
        var year = date.getFullYear();

        return day + "." + month + "." + year + " " + dateToTimeString(date);
    }
    return "";
}

function lineColor(line) {
    if(line.toLowerCase() === "a") {
        return "#080"; // Green
    }
    if(line.toLowerCase() === "b") {
        return "#ec1"; // Yellow
    }
    if(line.toLowerCase() === "c") {
        return "#d00"; // Red
    }
    if(line.toLowerCase() === "d") {
        return "#00d"; // Blue
    }
    return "#000";
}

function setStopData(stopSearch, stopidfrom, stopnamefrom, typeid) {
    stopSearch.setData({
        selectedStop: new Transport.Stop({
            item: {
                item: stopidfrom,
                name: stopnamefrom
        }
        }, {
            transportID: typeid,
            dbConnection: Transport.transportOptions.dbConnection
        }),
        value: stopnamefrom
    });
}

// SOURCE: http://stackoverflow.com/a/21623206/1642887
function latLongDistance(lat1, lon1, lat2, lon2) {
  var p = Math.PI / 180;
  var c = Math.cos;
  var a = 0.5 - c((lat2 - lat1) * p)/2 + c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p))/2;

  return 12742 * Math.asin(Math.sqrt(a)); // 2 * R; R = 6371 km
}
