import QtQuick 2.4
import QtPositioning 5.2
import QtLocation 5.3
import Ubuntu.Components 1.3
import QtQuick.Layouts 1.1
import QtQuick.LocalStorage 2.0

import "engine.js" as Engine
import "localStorage.js" as DB

Page {
    id: mapPage
    visible: false
    clip: true

    header: PageHeader {
        id: mapPageHeader
        title: i18n.tr("Show station on map")

        trailingActionBar {
            actions: [
                Action {
                    iconName: "gps"
                    text: i18n.tr("Show my current location")
                    enabled: stationMap.center != positionSource.position.coordinate
                    visible: enabled
                    onTriggered: stationMap.center = positionSource.position.coordinate
                }
            ]
        }

        StyleHints {
            foregroundColor: "#fff"
            backgroundColor: "#3949AB"
        }
    }

    Rectangle {
        anchors.top: mapPageHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        Plugin {
            id: mapPlugin
            preferred: "osm"
        }

        Map {
            id: stationMap
            anchors.fill: parent
            anchors.topMargin: units.gu(0.25)
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

                sourceItem: Image {
                    id: gpsMarkerIcon
                    source: "icons/map_position.svg"
                    width: stationMap.markerIconSize()
                    height: width
                    sourceSize.width: width
                    sourceSize.height: height
                }
            }

            MapQuickItem {
                id: stopMarker
                anchorPoint.x: stopMarkerIcon.width/4
                anchorPoint.y: stopMarkerIcon.height

                sourceItem: Image {
                    id: stopMarkerIcon
                    source: "icons/map_stop.svg"
                    width: stationMap.markerIconSize()
                    height: width
                    sourceSize.width: width
                    sourceSize.height: height
                }
            }
        }

        Rectangle {
            id: mapQueryRectangle
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: mapQuerySearchLayout.height + units.gu(2)
            color: Qt.rgba(1, 1, 1, 0.75)

            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 1) }
                GradientStop { position: 0.7; color: Qt.rgba(1, 1, 1, 0.7) }
                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0) }
            }

            RowLayout {
                id: mapQuerySearchLayout
                anchors.centerIn: parent
                width: parent.width - units.gu(2)
                spacing: units.gu(1)
                Layout.fillWidth: true

                StationQuery {
                    id: mapQuery
                    Layout.fillWidth: true
                    property string placeholder: i18n.tr("Station")
                }

                Button {
                    height: units.gu(4)
                    Layout.fillWidth: true
                    Layout.minimumWidth: height
                    Layout.preferredWidth: height
                    Layout.maximumWidth: height
                    color: "#3949AB"
                    iconName: "search"
                    onClicked: {
                        if(enabled) {
                            stationMap.center = QtPositioning.coordinate(mapQuery.coorX, mapQuery.coorY);
                            stopMarker.coordinate = QtPositioning.coordinate(mapQuery.coorX, mapQuery.coorY);
                        }
                    }
                    enabled: mapQuery.text != "" && !isNaN(mapQuery.coorX) && mapQuery.coorX != 0 && !isNaN(mapQuery.coorY) && mapQuery.coorY != 0

                    StyleHints {

                    }
                }
            }
        }
    }
}
