.pragma library
.import QtQuick.LocalStorage 2.0 as Sql
.import QtQml 2.0 as QML

"use strict";

Qt.include("DB.js");
Qt.include("generalfunctions.js");

var includeFolder = "transport-api/";
Qt.include(includeFolder + "generaltransport.js");
Qt.include(includeFolder + "transportoptions.js");
Qt.include(includeFolder + "transportoption.js");
Qt.include(includeFolder + "cityoptions.js");
Qt.include(includeFolder + "stop.js");
Qt.include(includeFolder + "connections.js");
Qt.include(includeFolder + "connection.js");
Qt.include(includeFolder + "connectiondetail.js");

var transportOptions = new TransportOptions({
    dbConnection: new DBConnection("0.2")
});
