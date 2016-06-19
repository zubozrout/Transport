// A custom's "xmlhttprequest" wrapper
function request(url, callback) {
    api.request = url;
    api.callback = callback;
    return url;
}

function langCode(toInt) {
    var locale = Qt.locale().name;
    var lang = "";
    var int = 0;

    switch(locale.substring(0,2)) {
        case "en":
            lang = "ENGLISH";
            int = 1;
            break;
        case "de":
            lang = "GERMAN";
            int = 2;
            break;
        case "cs":
            lang = "CZECH";
            int = 0;
            break;
        case "sk":
            lang = "SLOVAK";
            int = 3;
            break;
        case "pl":
            lang = "POLISH";
            int = 4;
            break;
        default:
            lang = "ENGLISH";
            int = 1;
            break;
    }

    if(typeof toInt !== typeof undefined && toInt == true) {
        return int;
    }
    return lang;
}

function urlCommon(userDesc, lang) {
    var locale = Qt.locale().name;
    if(typeof lang == typeof undefined) {
        lang = langCode();
    }

    var out = "lang=" + lang;
    if(typeof userDesc !== typeof undefined && userDesc) {
        out = "userDesc=" + userDesc + "&" + out;
    }
    return out;
}

function fetchTrasports(call) {
    var dateTime = new Date();
    DB.saveSetting("fetch_transport_options_timestamp", dateTime.toString());
    return request("https://ext.crws.cz/api/?" + urlCommon("ubuntu"), function(response){call(parseOptions(response));});
}

function getOptions(call) {
    var fetch = DB.getSetting("fetch_transport_options_on_each_start");
    var lastDate = new Date(DB.getSetting("fetch_transport_options_timestamp"));
    if(fetch || (lastDate && (new Date() - lastDate) > 60*60*24*7*1000) || DB.getAllTypes().length == 0) {
        fetchTrasports(call);
    }
}

function parseOptions(response_string) {
    var obj = JSON.parse(response_string);
    if(typeof obj.data === typeof undefined) {
        return;
    }
    var options = [];
    for(var i = 0; i < obj.data.length; i++) {
        var transportName = typeof obj.data[i].name !== typeof undefined ? JSON.stringify(obj.data[i].name) : "";
        var transportNameExt = typeof obj.data[i].nameExt !== typeof undefined ? JSON.stringify(obj.data[i].nameExt) : "";
        var transportTitle = typeof obj.data[i].timetableInfo[0].title !== typeof undefined ? JSON.stringify(obj.data[i].timetableInfo[0].title) : "";
        var transportCity = typeof obj.data[i].timetableInfo[0].city !== typeof undefined ? JSON.stringify(obj.data[i].timetableInfo[0].city) : "";
        var transportDescription = typeof obj.data[i].timetableInfo[0].description !== typeof undefined ? JSON.stringify(obj.data[i].timetableInfo[0].description) : "";
        var transportHomeState = typeof obj.data[i].timetableInfo[0].homeState !== typeof undefined ? JSON.stringify(obj.data[i].timetableInfo[0].homeState) : "";
        var transportTrTypes = typeof obj.data[i].timetableInfo[0].trTypes !== typeof undefined ? JSON.stringify(obj.data[i].timetableInfo[0].trTypes) : "";
        var transportTtValidFrom = typeof obj.data[i].timetableInfo[0].ttValidFrom !== typeof undefined ? JSON.stringify(obj.data[i].timetableInfo[0].ttValidFrom) : "";
        var transportTtValidTo = typeof obj.data[i].timetableInfo[0].ttValidTo !== typeof undefined ? JSON.stringify(obj.data[i].timetableInfo[0].ttValidTo) : "";
        options.push({id: obj.data[i].id, name: transportName, nameExt: transportNameExt, title: transportTitle, city: transportCity, description: transportDescription, homeState: transportHomeState, trTypes: transportTrTypes, ttValidFrom: transportTtValidFrom, ttValidTo: transportTtValidTo});
    }
    var types = DB.getAllTypes();
    for(var i = 0; i < types.length; i++) {
        var type = types[i].id;
        var transportName = types[i].name;
        var typeInOptions = false;
        for(var j = 0; j < options.length; j++) {
            if(type == options[j].id && transportName == options[j].name) {
                typeInOptions = true;
            }
        }
        if(!typeInOptions) {
            DB.deleteType(type);
        }
    }
    return options;
}

function saveOptions(options) {
    for(var key in options) {
        /*
        var typeMap = new Map();
        typeMap.set("type", options[key]["id"]);
        typeMap.set("name", options[key]["name"]);
        typeMap.set("nameExt", options[key]["nameExt"]);
        typeMap.set("title", options[key]["title"]);
        typeMap.set("city", options[key]["city"]);
        typeMap.set("description", options[key]["description"]);
        typeMap.set("homeState", options[key]["homeState"]);
        typeMap.set("trTypes", options[key]["trTypes"]);
        typeMap.set("ttValidFrom", options[key]["ttValidFrom"]);
        typeMap.set("ttValidTo", options[key]["ttValidTo  "]);
        DB.appendNewType(typeMap);
        */

        DB.appendNewType({
             "type": options[key]["id"],
             "name": options[key]["name"],
             "nameExt": options[key]["nameExt"],
             "title": options[key]["title"],
             "city": options[key]["city"],
             "description": options[key]["description"],
             "homeState": options[key]["homeState"],
             "trTypes": options[key]["trTypes"],
             "ttValidFrom": options[key]["ttValidFrom"],
             "ttValidTo": options[key]["ttValidTo"]
         });
    }
    transport_selector_page.update();
}

function getStops(city, mask, limit, call, geo) {
    var mask = typeof geo !== typeof undefined && geo ? "?coor=" + geo : "?mask=" + mask;
    var searchMode = "EXACT";
    return request("https://ext.crws.cz/api/" + city + "/timetableObjects/0" + mask + "&ttInfoDetails=ITEM&ttInfoDetails=COOR" + "&searchMode=" + searchMode + "&maxCount=" + limit + "&" + urlCommon("ubuntu"), call);
}

function parseStops(response_string) {
    if(!response_string) {
        return;
    }

    var obj = JSON.parse(response_string);
    var stops = [];
    if(!(obj.data == null || typeof obj.data === typeof undefined)) {
        for(var i = 0; i < obj.data.length; i++) {
            stops.push({name: obj.data[i].item.name, coorX: obj.data[i].coorX, coorY: obj.data[i].coorY});
        }
    }
    return stops;
}

/*
city = option code
time = date of departure/arrival in format of "7.10.2015 20:13"
departure_time = defines whether time is of departure (true) or arrival (false)
from = departure station name
to = arrival station name
limit = number of connections
call = function to call once data is downloaded
*/
function getConnections(city, time, departure_time, from, to, via, change, limit, call) {
    if(time != "") {
        time = "&dateTime=" + time;
    }
    if(via != "") {
        via = "&via=" + via;
    }
    change = !change ? "&change=0" : "";
    return request("https://ext.crws.cz/api/" + city + "/connections?from=" + from + "&to=" + to + via + change + time + "&isDep=" + departure_time + "&maxObjectsCount=2&maxCount=" + limit + "&ttInfoDetails=TRTYPEID_ITEM" + "&" + urlCommon("ubuntu"), function(response){call(parseConnections(response));});
}

function getConnectionsFB(city, handle, connection_id, count, forward, call) {
    var direction = forward ? "true" : "false";
    return request("https://ext.crws.cz/api/" + city + "/connections/" + handle + "?connId=" + connection_id + "&prevConn=" + direction + "&listedConnCount=" + 0 + "&maxCount=" + count + "&" + urlCommon("ubuntu"), function(response){call(parseConnections(response));});
}

function parseConnections(response_string) {
    if(!response_string) {
        return;
    }
    var obj = checkForError(JSON.parse(response_string));
    if(obj == "ERROR") {
        return obj;
    }

    var local_handle = parseAPI(obj, "handle");
    if(typeof local_handle !== typeof undefined && local_handle) {
        handle = local_handle;
        return obj;
    }
    if(parseAPI(obj, "connections").length > 0) {
        return obj;
    }
    return response_string;
}

function connectionDetail(city, id, call) {
    var connection_id = handle + id;
    if(Object.keys(connection_detail.detail_array).length == 0  || !connection_detail.detail_array[connection_id]) {
        return request("https://ext.crws.cz/api/" + city + "/connections/" + handle + "/" + id + "?ttDetails=ROUTE_FULL&ttDetails=TRAIN_INFO&ttDetails=TRTYPE_IN_ID&ttDetails=PRICES&ttDetails=FIXED_CODES&ttDetails=COOR&ttDetails=ROUTE_COOR&" + urlCommon("ubuntu"), function(response){call(parseConnectionDetail(response), id);});
    }
    else {
        showConnectionDetail(city, null, id);
    }
}

function parseConnectionDetail(response_string) {
    if(!response_string) {
        return;
    }
    var response = checkForError(JSON.parse(response_string));
    if(response == "ERROR") {
        return null;
    }
    return response;
}

/*
city = option code
stop = stop name
time = date of departure/arrival in format of "7.10.2015 20:13"
isDeb = is departure?
line = number or code of the line
limit = number of connections
call = function to call once data is downloaded
*/
function getDepartures(city, stop, time, isDep, line, limit, call) {
    time = (time != "") ? "&dateTime=" + time : "";
    isDep = (isDep != "") ? "&isDep=" + isDep : "";
    line = (line != "") ? "&line=" + line : "";
    limit = "&maxObjectsCount=" + limit;

    return request("https://ext.crws.cz/api/" + city + "/departureTables?from=" + stop + time + isDep + line + limit + "&ttInfoDetails=TRTYPEID_ITEM" + "&" + urlCommon("ubuntu"), function(response){call(parseDepartures(response));});
}

function parseDepartures(response_string) {
    if(!response_string) {
        return;
    }
    var obj = checkForError(JSON.parse(response_string));
    if(obj == "ERROR") {
        return obj;
    }

    var records = parseAPI(obj, "records");
    if(records) {
        records.start = parseAPI(obj, "fromObjectsName");
    }
    return records;
}

function completeFromDB(city, text, model) {
    var stops = DB.getRelevantStops(city, text);
    var stopNames = stops.map(function(stop) {return stop.name;});
    for(var i = 0; i < stops.length; i++) {
        for(var j = 0; j < model.count; j++) {
            if(stopNames.indexOf(model.get(j).name) == -1) {
                model.remove(j);
            }
        }
        var set = false;
        for(var j = 0; j < model.count; j++) {
            if(model.get(j).name == stops[i].name) {
                set = true;
            }
        }
        if(!set && model.count < 10) {
            model.append({"name": stops[i].name, "coorX": stops[i].coorX, "coorY": stops[i].coorY});
        }
    }
    return stops;
}

function complete(city, text, model) {
    if(text != "") {
        model.clear();
        var DBstops = completeFromDB(city, text, model);
        return getStops(city, text, 10, function(response){fill_from(parseStops(response), city, text, model, DBstops);});
    }
}

function fill_from(response, city, text, model, DBstops) {
    if(!response) {
        return;
    }
    var responseStopNames = response.map(function(stop) {return stop.name;});
    for(var i = 0; i < response.length; i++) {
        /* Won't remove DB findings if commented out
        for(var j = 0; j < model.count; j++) {
            if(responseStopNames.indexOf(model.get(j).name) == -1) {
                model.remove(j);
            }
        }
        */
        var set = false;
        for(var j = 0; j < model.count; j++) {
            if(model.get(j).name == response[i].name) {
                set = true;
                model.set(j, {"name": response[i].name, "coorX": response[i].coorX, "coorY": response[i].coorY});
            }
        }
        if(!set && model.count < 10) {
            model.append({"name": response[i].name, "coorX": response[i].coorX, "coorY": response[i].coorY});
        }
    }
}

function showConnectionsFB(response) {
    response = checkForError(response);
    if(response == "ERROR") {
        pageLayout.removePages(search_page);
        return response;
    }
    else {
        var connections = parseAPI(response, "connections");
        if(connections.length <= 0) {
            statusMessagelabel.text = i18n.tr("Could not load next connection results.");
            statusMessageErrorlabel.text = "\n\n" + connections;
            statusMessageBox.visible = true;
            return;
        }
        result_page.clear();
        result_page.response = response;
        result_page.typeid = transport_selector_page.selectedItem;
        result_page.render(connections);
    }
}

function showConnections(response) {
    response = checkForError(response);
    if(response == "ERROR") {
        pageLayout.removePages(search_page);
        return response;
    }
    else {
        var connections = parseAPI(response, "connections");
        if(connections.length <= 0) {
            statusMessagelabel.text = i18n.tr("No results matching input parameters were found.");
            statusMessageErrorlabel.text = "\n\n" + connections;
            statusMessageBox.visible = true;
            return;
        }
        result_page.clear();
        result_page.response = response;
        result_page.typeid = transport_selector_page.selectedItem;
        result_page.render(connections);
        pageLayout.addPageToNextColumn(search_page, result_page);
    }
}

function showConnectionDetail(typeid, detail, id) {
    var connection_id = handle + id;
    if(detail != null && (connection_detail.detail_array == null || !connection_detail.detail_array[connection_id])) {
        connection_detail.detail_array[connection_id] = detail;
    }
    connection_detail.current_id = connection_id;
    connection_detail.typeid = typeid;
    if(connection_detail.detail_array.hasOwnProperty(connection_id)) {
        pageLayout.addPageToCurrentColumn(result_page, connection_detail);
    }
    else {
        statusMessagelabel.text = i18n.tr("Could not load connection detail.");
        statusMessageBox.visible = true;
    }
    return detail;
}

/* ↓↓↓ IDOS API Parser ↓↓↓ */
function parseStationObjectAPI(station, value) {
    var object = (typeof station["timetableObject"]["item"] !== typeof undefined) ? station["timetableObject"]["item"] : station["masks"];
    switch(value) {
        case "listId":
            return object[0]["listId"];
        case "item":
            return object[0]["item"];
        case "name":
            return object[0]["name"];
        case "coorX":
            if(typeof object[0]["coorX"] !== typeof undefined) {
                return object[0]["coorX"];
            }
            else {
                return null;
            }
        case "coorY":
            if(typeof object[0]["coorY"] !== typeof undefined) {
                return object[0]["coorY"];
            }
            else {
                return null;
            }
        default:
            return object[0]["name"];
    }
}

function parseTrainDataInfoAPI(trainDataInfo, value) {
    switch(value) {
        case "train":
            return trainDataInfo["train"];
        case "num1":
            return trainDataInfo["num1"];
        case "type":
            return trainDataInfo["type"];
        case "typeName":
            return trainDataInfo["typeName"];
        case "flags":
            return trainDataInfo["flags"];
        case "color":
            return trainDataInfo["color"];
        case "id":
            return trainDataInfo["id"];
        case "fixedCodes":
            return trainDataInfo["fixedCodes"];
        default:
            return trainDataInfo["id"];
    }
}

function parseTrainDataRouteAPI(route, value) {
    switch(value) {
        case "station":
            return route["station"]["station"];
        case "name":
            return route["station"]["name"];
        case "statCoorX":
            if(typeof route["station"]["coorX"] !== typeof undefined) {
                return route["station"]["coorX"];
            }
            else {
                return null;
            }
        case "statCoorY":
            if(typeof route["station"]["coorY"] !== typeof undefined) {
                return route["station"]["coorY"];
            }
            else {
                return null;
            }
        case "fixedCodes":
            return route["station"]["fixedCodes"];
        case "key":
            return route["station"]["key"];
        case "depTime":
            if(typeof route["depTime"] !== typeof undefined) {
                return route["depTime"];
            }
            return null;
        case "arrTime":
            if(typeof route["arrTime"] !== typeof undefined) {
                return route["arrTime"];
            }
            return null;
        case "coorX":
            if(typeof route["coorX"] !== typeof undefined) {
                return String(route["coorX"]).replace(/^\[?|\]?$/, "").split(",");
            }
            return null;
        case "coorY":
            if(typeof route["coorY"] !== typeof undefined) {
                return String(route["coorY"]).replace(/^\[?|\]?$/, "").split(",");
            }
            return null;
        case "dist":
            return route["dist"];
        default:
            return route["id"];
    }
}

function parseTrainsAPI(trains, value) {
    if(typeof trains === typeof undefined) {
        return false;
    }
    switch(value) {
        case "trainData":
            return trains["trainData"];
        case "info":
            return trains["trainData"]["info"];
        case "route":
            return trains["trainData"]["route"];
        case "dateTime1":
            return trains["dateTime1"];
        case "dateTime2":
            return trains["dateTime2"];
        case "distance":
            return trains["distance"];
        case "timeLength":
            return trains["timeLength"];
        case "delay":
            return trains["delay"];
        case "from":
            if(typeof trains["from"] !== typeof undefined) {
                return trains["from"];
            }
            return null;
        case "to":
            if(typeof trains["to"] !== typeof undefined) {
                return trains["to"];
            }
            return null;
        default:
            return trains["trainData"];
    }
}

function parseConnectionsAPI(connections, value) {
    if(typeof connections === typeof undefined) {
        return false;
    }
    switch(value) {
        case "id":
            return connections["id"];
        case "distance":
            return connections["distance"];
        case "timeLength":
            return connections["timeLength"];
        case "price":
            return connections["price"];
        case "trains":
            return connections["trains"];
        default:
            return connections["id"];
    }
}

function parseDeparturesAPI(records, value) {
    if(typeof records === typeof undefined) {
        return false;
    }
    switch(value) {
        case "id":
            return records["info"]["id"];
        case "num":
            return records["info"]["num1"];
        case "type":
            if(typeof records["info"] !== typeof undefined) {
                return records["info"]["type"];
            }
            return null;
        case "typeName":
            return records["info"]["typeName"];
        case "desc":
            if(typeof records["info"]["fixedCodes"] !== typeof undefined) {
                if(typeof records["info"]["fixedCodes"][0]["desc"] !== typeof undefined) {
                    return records["info"]["fixedCodes"][0]["desc"];
                }
            }
            return null;
        case "dateTime":
            return records["dateTime"];
        case "destination":
            return records["destination"];
        case "direction":
            return records["direction"];
        default:
            return records["info"]["id"];
    }
}

function checkForError(response) {
    if(typeof response === typeof undefined) {
        return "ERROR";
    }

    if(Object(response) != response) {
        return "ERROR";
    }

    if(typeof response.exceptionCode !== typeof undefined) {
        statusMessagelabel.text = i18n.tr("An error occured");
        statusMessageErrorlabel.text = "exceptionCode: " + response.exceptionCode + "\n";
        statusMessageErrorlabel.text += "exceptionEnum: " + response.exceptionEnum + "\n";
        statusMessageErrorlabel.text += "exceptionMessage: " + response.exceptionMessage + "\n";
        statusMessageBox.visible = true;
        return "ERROR";
    }
    return response;
}

function parseAPI(response, value) {
    response = checkForError(response);
    if(response == "ERROR") {
        return response;
    }

    switch(value) {
        case "combId":
            return response["combId"];
        case "fromObjects":
            return response["fromObjects"];
        case "fromObjectsName":
            var fromObjects = response["fromObjects"];
            var fromObjectsName = [];
            if(fromObjects.length > 1) {
                for(var i = 0; i < fromObjects.length; i++) {
                    fromObjectsName.push(parseStationObjectAPI(response["fromObjects"][i], "name"));
                }
            }
            else {
                fromObjectsName = parseStationObjectAPI(response["fromObjects"], "name");
            }
            return fromObjectsName;
        case "toObjects":
            return response["toObjects"];
        case "toObjectsName":
            var toObjects = response["toObjects"];
            var toObjectsName = [];
            for(var i = 0; i < toObjects.length; i++) {
                toObjectsName.push(parseStationObjectAPI(response["toObjects"][i], "name"));
            }
            return toObjectsName;
        case "handle":
            return response["handle"];
        case "connInfo":
            return response["connInfo"];
        case "connections":
            if(typeof response["connInfo"] === typeof undefined) {
                if(typeof response["connections"] !== typeof undefined) {
                    return response["connections"];
                }
                return [];
            }
            return response["connInfo"]["connections"];
        case "records":
            return response["records"];
        default:
            return response["combId"];
    }
}

function parseDetailAPI(response, value) {
    switch(value) {
        case "connections":
            return response["connections"];
        default:
            return response["connections"];
    }
}

/* Support functions */
function parseColor(type, num) {
    var line_color = "#444";
    if(type.toLowerCase() == "metro" && num == "A") {
        line_color = "#2E7D32";
    }
    else if(type.toLowerCase() == "metro" && num == "B") {
        line_color = "#F9A825";
    }
    else if(type.toLowerCase() == "metro" && num == "C") {
        line_color = "#B71C1C";
    }
    return line_color;
}

function parseDate(datetime) {
    if(typeof datetime === typeof undefined || datetime == false) {
        return false;
    }

    var d_date = datetime.split(" ")[0];
    var d_time = datetime.split(" ")[1];

    var dDate = d_date.split(".");
    var dTime = d_time.split(":");

    var dep_date = new Date();
    dep_date.setDate(dDate[0]);
    dep_date.setMonth(dDate[1] - 1);
    dep_date.setFullYear(dDate[2]);

    dep_date.setHours(dTime[0]);
    dep_date.setMinutes(dTime[1]);
    dep_date.setSeconds(0,0);

    return dep_date.toISOString();
}

function readableDate(date, format) {
    if(typeof date !== typeof undefined) {
        switch(format) {
            case "datetime":
                return date.getDate() + "." + (date.getMonth() + 1) + "." + date.getFullYear() + ", " + readableDate(date, "time");
            case "time":
                var hours = String(date.getHours());
                if(hours.length == 1) {
                    hours = "0" + hours;
                }
                var minutes = String(date.getMinutes());
                if(minutes.length == 1) {
                    minutes = "0" + minutes;
                }
                return hours + ":" + minutes;
             default:
                 return date.toString();
        }
    }
    return null;
}

function dateToReadableFormat(date, returnTime) {
    if(!date.getDate()) {
        return "";
    }
    var dateStr = date.getDate() + "." + (date.getMonth() + 1) + "." + date.getFullYear();
    if(typeof returnTime !== typeof undefined && returnTime == true) {
        var hours = date.getHours();
        if(hours.toString().length == 1) {
            hours = "0" + hours;
        }
        var minutes = date.getMinutes();
        if(minutes.toString().length == 1) {
            minutes = "0" + minutes;
        }

        dateStr += ", " + hours + ":" + minutes;
    }
    return dateStr;
}

function transportIdToName(id) {
    var ttypes = ["empty", "train", "bus", "tram", "trol", "metro", "ship", "air", "taxi", "cableway"];
    if(Number(id) < ttypes.length) {
        return ttypes[Number(id)];
    }
    return ttypes[0];
}

function clearLocalStorage() {
    DB.clearLocalStorage();
    transport_selector_page.update();
}

function randomColor(brightness){
    function randomChannel(brightness){
        var r = 255 - brightness;
        var n = 0|((Math.random() * r) + brightness);
        var s = n.toString(16);
        return (s.length == 1) ? "0" + s : s;
    }
    return "#" + randomChannel(brightness) + randomChannel(brightness) + randomChannel(brightness);
}

// SOURCE: http://stackoverflow.com/a/21623206/1642887
function latLongDistance(lat1, lon1, lat2, lon2) {
  var p = Math.PI / 180;
  var c = Math.cos;
  var a = 0.5 - c((lat2 - lat1) * p)/2 + c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p))/2;

  return 12742 * Math.asin(Math.sqrt(a)); // 2 * R; R = 6371 km
}

function getLatestSearchFrom(typeid, from) {
    var searchHistory = DB.getSearchHistory(typeid);
    var obj = {};

    obj.from = {}
    obj.from.name = from.name;
    obj.from.lat = from.coorX;
    obj.from.long = from.coorY;

    var match = false;
    for(var i = 0; i < searchHistory.length; i++) {
        if(searchHistory[i].stopfrom == from.name) {
            obj.to = {}
            obj.to.name = searchHistory[i].stopto;
            obj.to.lat = searchHistory[i].stoptox;
            obj.to.long = searchHistory[i].stoptoy;

            if(searchHistory[i].stopvia) {
                obj.via = {}
                obj.via.name = searchHistory[i].stopvia;
                obj.via.lat = searchHistory[i].stopviax;
                obj.via.long = searchHistory[i].stopviay;
            }
            break;
        }
    }

    return obj;
}

// Get stop based on current selected transport typeid and geolocation and try to match an existing (newest) search on it
// requires {selectedItem, lat, long}
// returns {from:[{name, lat, long}], to:[{name, lat, long}], via:[{name, lat, long}]} (to and via may be null), or empty object if no match was found
function geoPositionMatch(data) {
    var obj = {};
    if(data.selectedItem) {
        var geoPosition = DB.getNearbyStops(data.selectedItem, {"x": data.lat, "y": data.long});

        if(geoPosition.length > 0) {
            obj = getLatestSearchFrom(data.selectedItem, geoPosition[0]);
        }
    }
    return obj;
}

function fillStopMatch(transport, stopMatch) {
    if(stopMatch.from) {
        transport_selector_page.selectItemById(transport);

        from.text = stopMatch.from.name;
        from.coorX = stopMatch.from.lat;
        from.coorY = stopMatch.from.long;

        if(stopMatch.to) {
            to.text = stopMatch.to.name;
            to.coorX = stopMatch.to.lat;
            to.coorY = stopMatch.to.long;

            if(stopMatch.via) {
                via.text = stopMatch.via.name;
                via.coorX = stopMatch.via.lat;
                via.coorY = stopMatch.via.long;
            }
        }
        else {
            to.text = "";
            via.text = "";
        }

        return true;
    }
    return false;
}

function setGeoPositionMatch(coordinate, transport, from, to, via) {
    var stopMatch = geoPositionMatch({
        "selectedItem": transport,
        "lat": coordinate.latitude,
        "long": coordinate.longitude
    });

    return fillStopMatch(transport, stopMatch);
}

function saveStationToDb(textfield) {
    if(textfield.text && textfield.coorX && textfield.coorY) {
        var hasTransportStop = DB.hasTransportStop(transport_selector_page.selectedItem);
        var id = DB.appendNewStop(transport_selector_page.selectedItem, textfield.text, {x: textfield.coorX, y: textfield.coorY});
        if(!hasTransportStop) {
            transport_selector_page.update();
        }
        return id;
    }
    else {
        var nameMatch = DB.getStopByName({"id": transport_selector_page.selectedItem, "name": textfield.text});
        if(nameMatch) {
            return nameMatch.id;
        }
    }
    return null;
}

function saveSearchCombination(transport, fromID, toID, viaID) {
    DB.appendSearchToHistory({
        "typeid": transport,
         "stopidfrom": fromID ? fromID : "",
         "stopidto": toID ? toID : "",
         "stopidvia": viaID ? viaID : ""
    });
}

function checkClear(textfield, listview, model) {
    if(!model) {
        model = textfield.stationInputModel;
    }

    if(listview.currentIndex >= 0 && typeof model.get(listview.currentIndex) !== typeof undefined && model.get(listview.currentIndex).name == textfield.displayText) {
        api.abort();
        listview.lastSelected = model.get(listview.currentIndex).name;
        model.clear();
    }
}

function stationInputChanged(textfield, listview, model) {
    search.resetState();
    api.abort();
    if(textfield.focus && textfield.displayText != listview.lastSelected) {
        if(!model) {
            model = textfield.stationInputModel;
        }
        complete(transport_selector_page.selectedItem, textfield.displayText, model);
        checkClear(textfield, listview, model);
    }
}
