import QtQuick 2.4
import QtPositioning 5.2
import QtLocation 5.3
import Ubuntu.Components 1.3
import QtQuick.Layouts 1.1
import QtQuick.LocalStorage 2.0
import Ubuntu.Components.Popups 1.0

import "engine.js" as Engine
import "localStorage.js" as DB

Page {
    id: mapRoutePage
    visible: false
    clip: true

    property var typeid: null
    property var routeStart: null

    function clearRoute() {
        routeStart = null;

        polyLineListModel.clear();
        stationListModel.clear();
    }

    function renderRoute(route) {
        var firstActive = null;
        for(var i = 0; i < route.length; i++) {
            var lineColor = route[i].lineColor;
            if(lineColor == "#444") {
                lineColor = Engine.randomColor(1);
            }
            for(var j = 0; j < route[i].stations.length; j++) {
                if(!firstActive && route[i].stations[j].active) {
                    firstActive = route[i].stations[j];
                }

                var linePolyLine = [];
                for(var k = 0; k < route[i].stations[j].route.length; k++) {
                    linePolyLine.push(route[i].stations[j].route[k]);
                }

                var sequenceActive = true;
                if(route[i].stations[j + 1]) {
                    sequenceActive = route[i].stations[j].active && route[i].stations[j + 1].active;
                }
                if(linePolyLine.length > 0) {
                    polyLineListModel.append({"active": sequenceActive, "num": route[i].num, "lineColor": lineColor, "linePath": JSON.stringify(linePolyLine)});
                }
                stationListModel.append({"typeid": mapRoutePage.typeid, "active": route[i].stations[j].active, "num": route[i].num, "type": route[i].type, "lineColor": route[i].lineColor, "station": route[i].stations[j].station, "stop_time": route[i].stations[j].stop_time, "stop_datetime": route[i].stations[j].stop_datetime, "latitude": route[i].stations[j].statCoorX, "longitude": route[i].stations[j].statCoorY});
            }
        }
        routeStart = QtPositioning.coordinate(firstActive.statCoorX, firstActive.statCoorY);
        routeMap.center = routeStart;
    }

    onVisibleChanged: {
        if(!visible) {
            clearRoute();
        }
    }

    header: PageHeader {
        id: mapRoutePageHeader
        title: i18n.tr("Show route on map")

        trailingActionBar {
            actions: [
                Action {
                    iconName: gpsMarker.lock ? "lock" : "gps"
                    text: gpsMarker.lock ? i18n.tr("Unlock GPS position") : i18n.tr("Lock to GPS")
                    onTriggered: {
                        if(!gpsMarker.lock && positionSource.valid) {
                            lockOnTheActiveAction.lock = false;
                            gpsMarker.lock = true;
                        }
                        else {
                            gpsMarker.lock = false;
                        }
                    }
                },
                Action {
                    iconName: "start"
                    text: i18n.tr("Route start")
                    onTriggered: {
                        gpsMarker.lock = false;
                        lockOnTheActiveAction.lock = false;
                        routeMap.center = routeStart;
                    }
                },
                Action {
                    id: lockOnTheActiveAction
                    iconName: lock ? "lock" : "lock-broken"
                    text: lock ? i18n.tr("Stop tracking route") : i18n.tr("Track route")
                    property bool lock: false
                    onTriggered: {
                        if(!lock) {
                            gpsMarker.lock = false;
                            routeMap.center = routeStart;
                        }
                        lock = !lock;
                    }

                    onLockChanged: {
                        if(lock) {
                            routeMap.gesture.panEnabled = false;
                        }
                        else {
                            routeMap.gesture.panEnabled = true;
                        }
                    }
                }
            ]
            numberOfSlots: 1
        }

        StyleHints {
            foregroundColor: "#fff"
            backgroundColor: "#3949AB"
        }
    }

    Rectangle {
        anchors.top: mapRoutePageHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        Plugin {
            id: mapPlugin
            preferred: "osm"
        }

        Map {
            id: routeMap
            anchors.fill: parent
            plugin: mapPlugin
            zoomLevel: maximumZoomLevel - 3
            gesture.enabled: true
            center: positionSource.position.coordinate

            onCenterChanged: {
                if(center != gpsMarker.coordinate) {
                    gpsMarker.lock = false;
                }
                else {
                    center = positionSource.position.coordinate;
                }
            }

            MapQuickItem {
                id: gpsMarker
                anchorPoint.x: gpsMarkerIcon.width/4
                anchorPoint.y: gpsMarkerIcon.height
                coordinate: positionSource.position.coordinate
                z: stationListModel.count * 100 * (polyLineListModel.count * 100) + 1

                property bool lock: false

                sourceItem: Image {
                    id: gpsMarkerIcon
                    source: "icons/map_position.svg"
                    width: units.gu(4)
                    height: width
                    sourceSize.width: width
                    sourceSize.height: height
                }

                onLockChanged: {
                    if(lock) {
                        routeMap.gesture.panEnabled = false;
                        routeMap.center = coordinate;
                    }
                    else {
                        routeMap.gesture.panEnabled = true;
                    }
                }

                onCoordinateChanged: {
                    if(lock) {
                        routeMap.center = coordinate;
                    }

                    if(coordinate == routeMap.center) {
                        gpsMarkerIcon.width = units.gu(8);
                    }
                    else {
                        gpsMarkerIcon.width = units.gu(4);
                    }
                }
            }

            ListModel {
                id: polyLineListModel
                property var randomColors: []
            }

            MapItemView {
                model: polyLineListModel

                delegate: MapPolyline {
                    line.width: active ? routeMap.zoomLevel/2 : routeMap.zoomLevel/4
                    line.color: active ? lineColor : "#000"
                    opacity: active ? 1 : (routeMap.zoomLevel < routeMap.maximumZoomLevel - 7 ? 0 : 0.5)
                    path: JSON.parse(linePath)
                    z: active ? index * 100 : index
                }
            }

            ListModel {
                id: stationListModel
            }

            MapItemView {
                model: stationListModel

                delegate: MapQuickItem {
                    id: stopMarker
                    coordinate: QtPositioning.coordinate(latitude, longitude)
                    anchorPoint.x: stopMarkerIcon.width/2
                    anchorPoint.y: stopMarkerIcon.height/2
                    opacity: active ? 1 : 0.5
                    visible: active ? routeMap.zoomLevel > routeMap.maximumZoomLevel - 7 : routeMap.zoomLevel > routeMap.maximumZoomLevel - 5
                    z: active ? index * 100 * (polyLineListModel.count * 100) : index * 100

                    sourceItem: Rectangle {
                        id: stopMarkerIcon
                        width: active ? units.gu(2) : units.gu(1.5)
                        height: width
                        radius: width
                        color: active ? "#3949AB" : "#d00"

                        Rectangle {
                            anchors.margins: parent.width/5
                            anchors.fill: parent
                            radius: width
                            color: "#fff"
                        }

                        Rectangle {
                            anchors.left: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.margins: units.gu(0.5)
                            width: stationRow.width + 2*stationRow.anchors.margins
                            height: stationRow.height + 2*stationRow.anchors.margins
                            color: Qt.rgba(1, 1, 1, 0.75)
                            visible: active && routeMap.zoomLevel > routeMap.maximumZoomLevel - 5

                            RowLayout {
                                id: stationRow
                                anchors.margins: units.gu(0.5)
                                anchors.centerIn: parent
                                spacing: units.gu(0.5)
                                Layout.fillWidth: true

                                Image {
                                    Layout.fillWidth: false
                                    width: units.gu(2.5)
                                    height: width
                                    sourceSize.width: width
                                    fillMode: Image.PreserveAspectFit
                                    source: "icons/" + type.toLowerCase() + ".svg";
                                }

                                Label {
                                    id: stationNum
                                    Layout.fillWidth: true
                                    text: num
                                    font.pixelSize: FontUtils.sizeToPixels("small")
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
                                    wrapMode: Text.WordWrap
                                    color: "#000"
                                }

                                Label {
                                    id: stationLabel
                                    Layout.fillWidth: true
                                    text: station
                                    font.pixelSize: FontUtils.sizeToPixels("small")
                                    font.bold: true
                                    wrapMode: Text.WordWrap
                                    color: "#000"
                                }
                                Label {
                                    id: stationTime
                                    Layout.fillWidth: true
                                    text: "- " + stop_time
                                    font.pixelSize: FontUtils.sizeToPixels("small")
                                    wrapMode: Text.WordWrap
                                    color: "#000"
                                }
                            }
                        }

                        Component {
                            id: stationDialog

                            Dialog {
                                id: stationDialogue
                                title: station
                                text: i18n.tr("Line") + ": " + num + "\n(" + stop_time + ")"

                                Button {
                                    text: i18n.tr("Close")
                                    onClicked: PopupUtils.close(stationDialogue)
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: PopupUtils.open(stationDialog)
                        }
                    }

                    Timer {
                        interval: 20000
                        running: true
                        repeat: true
                        triggeredOnStart: true
                        property var lockActive: lockOnTheActiveAction.lock

                        onLockActiveChanged: {
                            if(lockActive) {
                                start();
                            }
                        }

                        onTriggered: {
                            if(active) {
                                var current_date = new Date();
                                current_date.setSeconds(0,0);
                                if(stop_datetime <= current_date) {
                                    repeat = false;
                                    stopMarkerIcon.color = "#ed0";
                                    if(lockOnTheActiveAction.lock) {
                                        routeMap.center = QtPositioning.coordinate(latitude, longitude);
                                    }
                                }
                                else {
                                    repeat = true;
                                    stopMarkerIcon.color = "#3949AB"
                                }
                            }
                            else {
                                repeat = false;
                            }
                        }
                    }
                }
            }
        }
    }
}
