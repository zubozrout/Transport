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
        
        trailingActionBar {
            actions: [
                Action {
                    iconName: "location"
                    text: i18n.tr("Location")
                    visible: positionSource.isValid
                    onTriggered: {
                        map.center = gpsMarker.coordinate;
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
	
	function cleanPage(fetchGPS) {
		polyLineListModel.clear();
		stationListModel.clear();
		positionSource.update();
		
		if(fetchGPS) {
			var savedDbPositionX = Transport.transportOptions.getDBSetting("last-geo-positionX") || null;
			var savedDbPositionY = Transport.transportOptions.getDBSetting("last-geo-positionY") || null;
			if(savedDbPositionX && savedDbPositionY) {
				map.center = QtPositioning.coordinate(savedDbPositionX, savedDbPositionY);
			}
			else {
				map.center = QtPositioning.coordinate(50.0755381, 14.4378005); // Default position to Prague
			}
			
			mapPage.locationDisplayed = false;
			mapPage.customLocation = false;
		}
		map.init();
	}
    
    function renderRoute(connectionDetail) {
		mapPage.customLocation = true;
		var mapPositionSynced = false;
		
		var polyLinesToTender = [];
		var stationsToRender = [];
				
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
												
						polyLinesToTender.push({
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
																
				stationsToRender.push({
					"latitude": currentStation.coorX,
					"longitude": currentStation.coorY,
					"value": station.value,
					"key": station.key,
					"item": station.item,
					"active": active,
					"pointColor": color
				});
				
				if(i === 0 && active && !mapPositionSynced) {
					map.center = QtPositioning.coordinate(currentStation.coorX, currentStation.coorY);
					map.zoomLevel = map.maximumZoomLevel - 5;
					mapPage.locationDisplayed = true;
					mapPositionSynced = true;
				}
			}
		}
		
		var zIndex = 1;
		for(var i = 0; i < polyLinesToTender.length; i++) {
			polyLinesToTender[i].zIndex = zIndex;
			polyLineListModel.append(polyLinesToTender[i]);
			zIndex++;
		}
		
		for(var i = 0; i < stationsToRender.length; i++) {
			stationsToRender[i].zIndex = zIndex;
			stationListModel.append(stationsToRender[i]);
			zIndex++;
		}
	}
	
	function renderAllDBStations(transportID) {
		transportID = transportID || null;
		var stations = Transport.transportOptions.dbConnection.getAllStations(transportID);
		var stationsToRender = [];
		for(var i = 0; i < stations.length; i++) {
			var station = stations[i];
			
			var renderStation = true;
			for(var j = 0; j < stationsToRender.length; j++) {
				if(stationsToRender[j].latitude === station.coorX) {
					if(stationsToRender[j].longitude === station.coorY) {
						if(Transport.GeneralTranport.baseString(stationsToRender[j].value) === Transport.GeneralTranport.baseString(station.value)) {
							renderStation = false;
						}
						station.coorX += 0.0003;
						station.coorY += 0.0003;
					}
				}
			}
			
			if(renderStation) {
				stationsToRender.push({
					"latitude": station.coorX,
					"longitude": station.coorY,
					"value": station.value,
					"key": station.key,
					"item": station.item,
					"active": station.key === transportID,
					"pointColor": pageLayout.colorPalete["headerBG"]
				});
			}
		}
		
		var zIndex = 1;
		for(var i = 0; i < stationsToRender.length; i++) {
			stationsToRender[i].zIndex = zIndex;
			stationListModel.append(stationsToRender[i]);
			zIndex++;
		}
	}
    
    PositionSourceItem {
        id: positionSource
        active: mapPage.visible
        
        onPositionChanged: {
			console.log("onPositionChanged");
			gpsMarker.updatePosition();
		}
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
            gesture.enabled: true
            gesture.acceptedGestures: MapGestureArea.PinchGesture | MapGestureArea.PanGesture | MapGestureArea.FlickGesture
            gesture.flickDeceleration: 3000
            
            function init() {
				zoomLevel = maximumZoomLevel - 3;
			}
			
			Component.onCompleted: {
				init();
			}

            MapQuickItem {
                id: gpsMarker
                anchorPoint.x: gpsMarkerIcon.width / 4
                anchorPoint.y: gpsMarkerIcon.height
                z: 10000
                visible: positionSource.isValid

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
                
                function updatePosition() {
					if(positionSource.isValid) {
						var coords = positionSource.position.coordinate;
						coordinate = coords;
						map.center = coords;
						Transport.transportOptions.saveDBSetting("last-geo-positionX", coords.latitude);
						Transport.transportOptions.saveDBSetting("last-geo-positionY", coords.longitude);
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
					z: zIndex
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
                    z: zIndex

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
						
						Label {
							anchors {
								bottom: parent.top
								horizontalCenter: parent.horizontalCenter
								margins: units.gu(0.25)
							}
							text: value
							color: "#000"
							font.bold: false
							font.pixelSize: FontUtils.sizeToPixels("xx-small")
							visible: map.zoomLevel > map.maximumZoomLevel - 4
							horizontalAlignment: Text.AlignHCenter
						}
						
						Component.onCompleted: {
							if(index === 0) {
								map.fitViewportToMapItems();
							}
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
				rightMargin: units.gu(2)
				bottomMargin: units.gu(4)
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
						text: "−"
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
