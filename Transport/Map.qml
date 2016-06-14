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
    id: mapPage
    visible: false
    clip: true

    header: PageHeader {
        id: mapPageHeader
        title: i18n.tr("Station locator")

        trailingActionBar {
            actions: [
                Action {
                    iconName: gpsMarker.lock ? "lock" : "gps"
                    text: gpsMarker.lock ? i18n.tr("Unlock GPS position") : i18n.tr("Lock to GPS")
                    onTriggered: {
                        if(!gpsMarker.lock && positionSource.valid) {
                            gpsMarker.lock = true;
                        }
                        else {
                            gpsMarker.lock = false;
                        }
                    }
                },
                Action {
                    id: nearbyAction
                    iconName: used ? "torch-on" : "torch-off"
                    text: i18n.tr("Nearby stations")
                    property var used: false
                    property var lastFocus: -1

                    function focusOnNext() {
                        if(stationListModel.count == 0) {
                            statusMessagelabel.text = i18n.tr("Unfortunately no nearby stations were found.");
                            statusMessageErrorlabel.text = "";
                            statusMessageBox.visible = true;
                            used = false;
                            return;
                        }
                        used = true;
                        gpsMarker.lock = false;

                        if(lastFocus < stationListModel.count) {
                            if(lastFocus < 0) {
                                lastFocus = 0;
                                stationMap.fitViewportToMapItems();
                                return;
                            }
                            stationMap.center = QtPositioning.coordinate(stationListModel.get(lastFocus).coorX, stationListModel.get(lastFocus).coorY);
                            if(lastFocus == stationListModel.count - 1) {
                                lastFocus = 0;
                            }
                            else {
                                lastFocus++;
                            }
                        }
                        else {
                            lastFocus = 0;
                        }
                    }

                    onTriggered: {
                        stationListModel.clear();
                        if(used) {
                            used = false;
                            lastFocus = -1;
                        }
                        else {
                            var options = transport_selector_page.selectedItem;
                            var coordinate = positionSource.position.coordinate;
                            if(positionSource.valid) {
                                var geoPosition = DB.getNearbyStops(options, {"x": coordinate.latitude, "y": coordinate.longitude});
                                for(var i = 0; i < geoPosition.length; i++) {
                                    if(geoPosition[i].coorX && geoPosition[i].coorY) {
                                        stationListModel.append({"typeid": options, "name": geoPosition[i].name, "coorX": geoPosition[i].coorX, "coorY": geoPosition[i].coorY});
                                    }
                                }
                                focusOnNext();
                            }
                        }
                    }
                },
                Action {
                    iconName: "next"
                    text: i18n.tr("Go to next")
                    enabled: nearbyAction.used
                    visible: enabled
                    onTriggered: {
                        gpsMarker.lock = false;
                        nearbyAction.focusOnNext();
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
                        stationMap.gesture.panEnabled = false;
                        stationMap.center = coordinate;
                    }
                    else {
                        stationMap.gesture.panEnabled = true;
                    }
                }

                onCoordinateChanged: {
                    if(lock) {
                        stationMap.center = coordinate;
                    }
                }
            }

            ListModel {
                id: stationListModel
            }

            MapItemView {
                model: stationListModel

                delegate: MapQuickItem {
                    id: stopMarker
                    anchorPoint.x: stopMarkerIcon.width/4
                    anchorPoint.y: stopMarkerIcon.height
                    coordinate: QtPositioning.coordinate(coorX, coorY);

                    sourceItem: Image {
                        id: stopMarkerIcon
                        source: "icons/map_stop.svg"
                        width: units.gu(4)
                        height: width
                        sourceSize.width: width
                        sourceSize.height: height

                        Rectangle {
                            anchors.left: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.margins: units.gu(0.5)
                            width: stationRow.width + 2*stationRow.anchors.margins
                            height: stationRow.height + 2*stationRow.anchors.margins
                            color: Qt.rgba(1, 1, 1, 0.75)
                            visible: stationMap.zoomLevel > stationMap.maximumZoomLevel - 5

                            RowLayout {
                                id: stationRow
                                anchors.margins: units.gu(0.5)
                                anchors.centerIn: parent
                                spacing: units.gu(0.5)
                                Layout.fillWidth: true

                                Label {
                                    id: stationLabel
                                    Layout.fillWidth: true
                                    text: name
                                    font.pixelSize: FontUtils.sizeToPixels("small")
                                    font.bold: true
                                    wrapMode: Text.WordWrap
                                    color: "#000"
                                }
                            }
                        }

                        Component {
                            id: stationDialog

                            Dialog {
                                id: stationDialogue
                                title: name

                                function selectAndExit() {
                                    (function() {
                                        Engine.fillStopMatch(typeid, Engine.getLatestSearchFrom(typeid, {"name": name, "coorX": stopMarker.coordinate.latitude, "coorY": stopMarker.coordinate.longitude}));
                                        PopupUtils.close(stationDialogue);
                                        pageLayout.removePages(pageLayout.primaryPage);
                                    })();
                                }

                                Button {
                                    text: i18n.tr("Close")
                                    onClicked: PopupUtils.close(stationDialogue)
                                }

                                Button {
                                    text: i18n.tr("Select and go to homepage")
                                    color: UbuntuColors.green
                                    onClicked: stationDialogue.selectAndExit()
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: PopupUtils.open(stationDialog)
                        }
                    }
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
                            var options = transport_selector_page.selectedItem;
                            stationListModel.clear();
                            stationListModel.append({"typeid": options, "name": mapQuery.text, "coorX": mapQuery.coorX, "coorY": mapQuery.coorY});
                            stationMap.center = QtPositioning.coordinate(mapQuery.coorX, mapQuery.coorY);
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
