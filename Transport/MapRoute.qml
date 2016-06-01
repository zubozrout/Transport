import QtQuick 2.4
import QtPositioning 5.2
import QtLocation 5.3
import Ubuntu.Components 1.3
import QtQuick.Layouts 1.1
import QtQuick.LocalStorage 2.0

import "engine.js" as Engine
import "localStorage.js" as DB

Page {
    id: mapRoutePage
    visible: false
    clip: true

    property var route: []

    function renderRoute() {
        polyLineListModel.clear();
        stationListModel.clear();

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
                    var sequenceActive = route[i].stations[j].active && route[i].stations[j + 1].active;
                }
                polyLineListModel.append({"active": sequenceActive, "num": route[i].num, "lineColor": lineColor, "linePath": JSON.stringify(linePolyLine)});
                stationListModel.append({"active": route[i].stations[j].active, "num": route[i].num, "type": route[i].type, "lineColor": route[i].lineColor, "station": route[i].stations[j].station, "latitude": route[i].stations[j].statCoorX, "lontitude": route[i].stations[j].statCoorY});
            }
        }
        routeMap.center = QtPositioning.coordinate(firstActive.statCoorX, firstActive.statCoorY);
    }

    header: PageHeader {
        id: mapRoutePageHeader
        title: i18n.tr("Show route on map")

        trailingActionBar {
            actions: [
                Action {
                    iconName: "gps"
                    text: i18n.tr("Show my current location")
                    enabled: routeMap.center != positionSource.position.coordinate
                    visible: enabled
                    onTriggered: routeMap.center = positionSource.position.coordinate
                }
            ]
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

            property var axe: Math.sqrt(width*width - height*height)

            function markerIconSize() {
                var minSize = units.gu(6)
                var countSize = axe / 8;
                if(countSize > minSize) {
                    return countSize;
                }
                return minSize;
            }

            MapQuickItem {
                id: gpsMarker
                anchorPoint.x: gpsMarkerIcon.width/4
                anchorPoint.y: gpsMarkerIcon.height
                coordinate: positionSource.position.coordinate
                z: stationListModel.count * 100 * (polyLineListModel.count * 100) + 1

                sourceItem: Image {
                    id: gpsMarkerIcon
                    source: "icons/map_position.svg"
                    width: routeMap.markerIconSize()
                    height: width
                    sourceSize.width: width
                    sourceSize.height: height
                }
            }

            ListModel {
                id: polyLineListModel
                property var randomColors: []
            }

            MapItemView {
                model: polyLineListModel

                delegate: MapPolyline {
                    line.width: active ? routeMap.markerIconSize()/6 : routeMap.markerIconSize()/12
                    line.color: active ? lineColor : "#000"
                    opacity: active ? 1 : 0.5
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
                    coordinate: QtPositioning.coordinate(latitude, lontitude)
                    anchorPoint.x: stopMarkerIcon.width/2
                    anchorPoint.y: stopMarkerIcon.height/2
                    z: active ? index * 100 * (polyLineListModel.count * 100) : index * 100

                    sourceItem: Rectangle {
                        id: stopMarkerIcon
                        width: active ? computeSize() : computeSize()/2
                        height: width
                        radius: width
                        color: active ? "#3949AB" : "#d00"
                        opacity: active ? 1 : 0.5

                        function computeSize() {
                            return (routeMap.markerIconSize()/30) * routeMap.zoomLevel;
                        }

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
                                    width: units.gu(4)
                                    height: width
                                    sourceSize.width: width
                                    fillMode: Image.PreserveAspectFit
                                    source: "icons/" + type.toLowerCase() + ".svg";
                                }

                                Label {
                                    id: stationNum
                                    Layout.fillWidth: true
                                    text: num
                                    font.pixelSize: FontUtils.sizeToPixels("normal")
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
                                    wrapMode: Text.WordWrap
                                    color: "#000"
                                }

                                Label {
                                    id: stationLabel
                                    Layout.fillWidth: true
                                    text: station
                                    font.pixelSize: FontUtils.sizeToPixels("normal")
                                    font.bold: true
                                    wrapMode: Text.WordWrap
                                    color: "#000"
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
