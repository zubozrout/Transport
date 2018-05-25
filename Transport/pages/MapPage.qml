import QtQuick 2.4
import Ubuntu.Components 1.3
import QtQuick.Layouts 1.1
import QtLocation 5.3
import QtPositioning 5.2

import "../components"

import "../transport-api.js" as Transport
import "../generalfunctions.js" as GeneralFunctions

Page {
    id: mapPage
    header: PageHeader {
        id: pageHeader
        title: i18n.tr("Map")
        
        /*
        extension: Sections {
            id: mapSections
            anchors {
                left: parent.left
                right: parent.right
                leftMargin: units.gu(2)
                bottom: parent.bottom
            }
            model: [i18n.tr("One"), i18n.tr("Two")]
            selectedIndex: 0

            StyleHints {
                sectionColor: pageLayout.colorPalete.secondaryBG
                selectedSectionColor: pageLayout.colorPalete.headerText
            }
        }
        */
        
        trailingActionBar {
            actions: [
                Action {
                    iconName: "location"
                    text: i18n.tr("Location")
                    onTriggered: {
                        map.center = positionSource.position.coordinate;
                    }
                }
           ]
        }

        StyleHints {
            foregroundColor: pageLayout.colorPalete["headerText"]
            backgroundColor: pageLayout.colorPalete["headerBG"]
        }
    }

    clip: true
    
    property bool customLocation: false
    property bool locationDisplayed: false
    
    onVisibleChanged: {
		polyLineListModel.clear();
		stationListModel.clear();
		positionSource.update();
	}
    
    function renderRoute(connectionDetail) {
		mapPage.customLocation = true;
		var mapPositionSynced = false;
			
		for(var i = 0; i < connectionDetail.trainLength(); i++) {
			var trainDetail = connectionDetail.getTrain(i);
			var routeCoors = trainDetail.routeCoors;
						
			var color = "#5D4037";
			if(trainDetail.trainInfo.typeName === "metro") {
				switch(trainDetail.trainInfo.num.toLowerCase()) {
					case "a":
						color = "#1B5E20";
						break;
					case "b":
						color = "#FBC02D";
						break;
					case "c":
						color = "#B71C1C";
						break;
					case "d":
						color = "#0D47A1";
						break;
					default:
						color = "#5D4037";
				}
			}
			else {
				color = "#";
				color += i % 2 === 0 ? "d" : "0";
				color += i % 2 === 0 ? "0" : "d";
				color += "0";
			}
			
			for(var j = 0; j < routeCoors.length; j++) {
				var coorXarray = routeCoors[j].coorX;
				var coorYarray = routeCoors[j].coorY;
				
				if(typeof coorXarray !== typeof undefined && typeof coorYarray !== typeof undefined) {
					if(coorXarray.length === coorYarray.length) {
						var routePart = [];
						for(var k = 0; k < coorXarray.length; k++) {
							routePart.push({
								"latitude": coorXarray[k],
								"longitude": coorYarray[k]
							});	
						}
												
						polyLineListModel.append({
							"linePath": JSON.stringify(routePart),
							"active": routeCoors[j].active,
							"lineColor": color
						});
					}
				}
			}
			
			var route = trainDetail.route;
			var from = trainDetail.from || 0;
			var to = trainDetail.to || route.length;
			for(var j = 0; j < route.length; j++) {
				var currentStation = route[j].station;
				var currentStation = route[j].station;
				var active = j >= from && j <= to;
																
				stationListModel.append({
					"latitude": currentStation.coorX,
					"longitude": currentStation.coorY,
					"active": active,
					"pointColor": color
				});
				
				if(active && !mapPositionSynced) {
					map.center = QtPositioning.coordinate(currentStation.coorX, currentStation.coorY);
					map.zoomLevel = map.maximumZoomLevel - 5;
					mapPage.locationDisplayed = true;
					mapPositionSynced = true;
				}
			}
		}
	}
    
    PositionSourceItem {
        id: positionSource
        active: mapPage.visible
    }

    Rectangle {
        anchors.top: pageHeader.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        Plugin {
            id: mapPlugin
            preferred: "osm"
        }
        
		Map {
            id: map
            anchors.fill: parent
            plugin: mapPlugin
            zoomLevel: maximumZoomLevel - 3
            gesture.enabled: true
            gesture.acceptedGestures: MapGestureArea.PinchGesture | MapGestureArea.PanGesture

            MapQuickItem {
                id: gpsMarker
                anchorPoint.x: gpsMarkerIcon.width / 4
                anchorPoint.y: gpsMarkerIcon.height
                coordinate: positionSource.position.coordinate
                z: 10000

                property bool firstTimeLocationFound: false

                sourceItem: Image {
                    id: gpsMarkerIcon
                    source: "../images/map-pin-red.svg"
                    width: units.gu(4)
                    height: width
                    fillMode: Image.PreserveAspectFit
                    sourceSize.width: width
                    sourceSize.height: height
                }

                onCoordinateChanged: {
                    if(!mapPage.customLocation && !mapPage.locationDisplayed) {
                        map.center = positionSource.position.coordinate;
                        mapPage.locationDisplayed = true;
                    }
                }
            }
			
			ListModel {
				id: polyLineListModel
			}

			MapItemView {
				model: polyLineListModel

				delegate: MapPolyline {
					id: polyline
					line.width: active ? map.zoomLevel : map.zoomLevel / 4
					line.color: active ? lineColor : "#000"
					opacity: 1
					path: JSON.parse(linePath)
					z: index
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
                    anchorPoint.x: stopMarkerIcon.width / 2
                    anchorPoint.y: stopMarkerIcon.height / 2
                    z: index * 100

                    sourceItem: Rectangle {
                        id: stopMarkerIcon
                        width: active ? map.zoomLevel * (3 / 2) : map.zoomLevel
                        height: width
                        radius: width
                        color: active ? pointColor : "#000"
                        
                        Rectangle {
							anchors {
								horizontalCenter: parent.horizontalCenter
								verticalCenter: parent.verticalCenter
							}
							width: parent.width / 2
							height: width
							radius: width
							color: "#fff"
						}
                    }
                }
            }
        }
        
        Rectangle {
			id: mapToolBar
			anchors {
				right: parent.right
				bottom: parent.bottom
				margins: units.gu(2)
			}
			width: childrenRect.width
			height: childrenRect.height
			color: "transparent"
			
			property var zoomButtonsSize: units.gu(6)
			
			ColumnLayout {
				spacing: units.gu(2)
				Layout.fillWidth: true
                Layout.fillHeight: true
				
				Rectangle {
					width: mapToolBar.zoomButtonsSize
					height: mapToolBar.zoomButtonsSize
					color: pageLayout.colorPalete["headerBG"]
					radius: width
					
					Label {
						anchors.fill: parent
						text: "+"
						color: "#fff"
						font.bold: true
						font.pixelSize: FontUtils.sizeToPixels("x-large")
						horizontalAlignment: Text.AlignHCenter
						verticalAlignment: Text.AlignVCenter
					}
					
					MouseArea {
						anchors.fill: parent
						onClicked: {
							if(map.zoomLevel < map.maximumZoomLevel) {
								map.zoomLevel = map.zoomLevel += 1;
							}
						}
					}
				}
				
				Rectangle {
					width: mapToolBar.zoomButtonsSize
					height: mapToolBar.zoomButtonsSize
					color: pageLayout.colorPalete["headerBG"]
					radius: width
					
					Label {
						anchors.fill: parent
						text: "-"
						color: "#fff"
						font.bold: true
						font.pixelSize: FontUtils.sizeToPixels("x-large")
						horizontalAlignment: Text.AlignHCenter
						verticalAlignment: Text.AlignVCenter
					}
					
					MouseArea {
						anchors.fill: parent
						onClicked: {
							if(map.zoomLevel > map.minimumZoomLevel) {
								map.zoomLevel = map.zoomLevel -= 1;
							}
						}
					}
				}
				
			}
		}
    }
}
