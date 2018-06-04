import QtQuick 2.4
import Ubuntu.Components 1.3
import QtQuick.Layouts 1.1
import Ubuntu.Components.Popups 1.0

import "../components"

import "../transport-api.js" as Transport
import "../generalfunctions.js" as GeneralFunctions

import "../components"

Page {
    id: searchPage
    header: PageHeader {
        id: pageHeader
        title: i18n.tr("Transport")
        flickable: searchFlickable

        StyleHints {
            foregroundColor: pageLayout.colorPalete["headerText"]
            backgroundColor: pageLayout.colorPalete["headerBG"]
        }

        leadingActionBar {
            actions: [
                Action {
					id: headerLeadingSearchResultsIcon
                    iconName: "search"
                    text: i18n.tr("Search results")
                    onTriggered: {
                        pageLayout.addPageToNextColumn(searchPage, connectionsPage);
                    }
                    enabled: false
                },
                Action {
					id: headerTrailingBearbyStationIcon
                    iconSource: Qt.resolvedUrl("../images/icon-stop.svg")
                    text: i18n.tr("Nearby station")
                    onTriggered: {
						positionSource.append(function(source) {
							if(source.isValid) {
								var matchFound = searchPage.findClosestRouteInHistory(null, true);
								if(!matchFound) {
									errorMessage.value = i18n.tr("No cached nearby stations found");
								}
							}
							else {
								errorMessage.value = i18n.tr("Location search disabled or not functional");
							}
						});
                    }
                },
                Action {
					id: headerTrailingBearbyRouteIcon
                    iconSource: Qt.resolvedUrl("../images/icon-route.svg")
                    text: i18n.tr("Nearby route")
                    onTriggered: {
						positionSource.append(function(source) {
							if(source.isValid) {
								var matchFound = searchPage.findClosestRouteInHistory();
								if(!matchFound) {
									errorMessage.value = i18n.tr("No cached nearby routes found");
								}
							}
							else {
								errorMessage.value = i18n.tr("Location search disabled or not functional");
							}
						});
                    }
                },
                Action {
                    iconName: "map"
                    text: i18n.tr("Map page")
                    onTriggered: {
						mapPage.cleanPage(true);
                        pageLayout.addPageToNextColumn(searchPage, mapPage);
                        mapPage.renderAllDBStations(Transport.transportOptions.getSelectedId());
                    }
                },
                Action {
                    iconName: "settings"
                    text: i18n.tr("Settings")
                    onTriggered: {
                        pageLayout.addPageToNextColumn(searchPage, settingsPage);
                    }
                },
                Action {
                    iconName: "help"
                    text: i18n.tr("About")
                    onTriggered: {
                        pageLayout.addPageToNextColumn(searchPage, aboutPage);
                    }
                }
            ]
            numberOfSlots: 0
        }

        trailingActionBar {
            actions: [
                Action {
					id: headerTrailingSearchResultsIcon
                    iconName: "search"
                    text: i18n.tr("Search results")
                    onTriggered: {
                        pageLayout.addPageToNextColumn(searchPage, connectionsPage);
                    }
                    enabled: false
                    visible: enabled
                }
           ]
           numberOfSlots: 1
        }
    }

    clip: true
    
    function search() {
        var fromVal = from.selectedStop ? from.selectedStop : from.value;
        var toVal = to.selectedStop ? to.selectedStop : to.value;
        var viaVal = advancedSearchSwitch.checked ? (via.selectedStop ? via.selectedStop : via.value) : null;
                
        var selectedTransport = Transport.transportOptions.getSelectedTransport();

        if(selectedTransport && fromVal && toVal) {
            selectedTransport.abortAll();

            var dateTime = null
            if(customDateSwitch.checked) {
                var Pdate = Qt.formatDate(datetimePicker.datePicker.date, "d.M.yyyy");
                var Ptime = Qt.formatTime(datetimePicker.timePicker.date, "hh:mm");
                dateTime = Pdate + " " + Ptime;
            }

            var departure = arrivalDeparturePicker.departure;

            var connection = selectedTransport.createConnection({
                from: fromVal,
                to: toVal,
                via: viaVal,
                departure: departure,
                time: dateTime
            });

            setProgressIndicatorRunning(true);
            connection.search({}, function(object, state) {
                setProgressIndicatorRunning(false);
                if(state) {
                    errorMessage.value = "";
                    if(state === "ABORT") {
                    }
                    else if(state === "FAIL") {
                        errorMessage.value = i18n.tr("Search failed");
                    }
                    else if(state === "SUCCESS") {
                        if(object) {
                            connectionsPage.connections = connection;
                            connectionsPage.renderAllConnections(connection);
                            pageLayout.addPageToNextColumn(searchPage, connectionsPage);

                            connectionsPage.enableHeaderButtons(selectedTransport.getAllConnections());
                            headerLeadingSearchResultsIcon.enabled = true;
                            headerTrailingSearchResultsIcon.enabled = true;
                        }
                    }
                }
            });
        }
    }

    function lastSearchPopulate() {
        var modelData = Transport.transportOptions.dbConnection.getSearchHistory();
        if(modelData.length > 0) {
            var lastSearched = modelData[0];
            var newSelectedTransport = Transport.transportOptions.selectTransportById(lastSearched.typeid);
            transportSelectorPage.selectedIndexChange();
            if(newSelectedTransport) {
                if(lastSearched.stopidfrom >= 0 && lastSearched.stopnamefrom) {
                    GeneralFunctions.setStopData(from, lastSearched.stopidfrom, lastSearched.stopnamefrom, lastSearched.typeid);
                }
                if(lastSearched.stopidto >= 0 && lastSearched.stopnameto) {
                    GeneralFunctions.setStopData(to, lastSearched.stopidto, lastSearched.stopnameto, lastSearched.typeid);
                }
                if(lastSearched.stopidvia >= 0 && lastSearched.stopnamevia) {
                    GeneralFunctions.setStopData(via, lastSearched.stopidvia, lastSearched.stopnamevia, lastSearched.typeid);
                    advancedSearchSwitch.checked = true;
                }
                else {
                    advancedSearchSwitch.checked = false;
                }
            }
        }
    }

    function setSelectedTransportLabelValue(data) {
        transportOptionLabel.ok = data.ok || false;
        transportOptionLabel.text = data.value || "";
    }

    function setProgressIndicatorRunning(running) {
        if(running === true) {
            itemActivity.running = true;
        }
        else {
            itemActivity.running = false;
        }
    }
    
    function populateSearch(historyData) {
		var newSelectedTransport = Transport.transportOptions.selectTransportById(historyData.typeid);
		transportSelectorPage.selectedIndexChange();
		if(historyData.stopidfrom >= 0 && historyData.stopnamefrom) {
			GeneralFunctions.setStopData(from, historyData.stopidfrom, historyData.stopnamefrom, historyData.typeid);
		}
		if(historyData.stopidto >= 0 && historyData.stopnameto) {
			GeneralFunctions.setStopData(to, historyData.stopidto, historyData.stopnameto, historyData.typeid);
		}
		if(historyData.stopidvia >= 0 && historyData.stopnamevia) {
			GeneralFunctions.setStopData(via, historyData.stopidvia, historyData.stopnamevia, historyData.typeid);
			advancedSearchSwitch.checked = true;
		}
		else {
			advancedSearchSwitch.checked = false;
		}
	}
	
	function findClosestRouteInHistory(stops, justStop) {
		var coords = positionSource.position.coordinate;
		if(!coords.isValid) {
			return false;
		}
		
		var stops = stops || Transport.transportOptions.searchSavedStationsByLocation(coords);
		
		if(!justStop) {
			var searchHistory = Transport.transportOptions.dbConnection.getSearchHistory();
					
			// Search for a searched route with the closest from or to station
			var stationFound = false;
			var stopsFoundInSearchHistory = [];
			for(var i = 0; i < stops.length; i++) {
				var stop = stops[i];
				for(var j = 0; j < searchHistory.length; j++) {
					var historyItem = searchHistory[j];
					
					var hisrotyItemAlreadyRegistered = false;
					for(var k = 0; k < stopsFoundInSearchHistory.length; k++) {
						if(stopsFoundInSearchHistory[k].historyIndex === j) {
							hisrotyItemAlreadyRegistered = true;
							break;
						}
					}
					
					if(!hisrotyItemAlreadyRegistered && stop.key === historyItem.typeid) {
						if(stop.item === historyItem.stopidfrom) {
							stopsFoundInSearchHistory.push({
								type: "from",
								stop: stop,
								closestIndex: i,
								historyIndex: j,
								searchHistory: historyItem
							});
						}
						else if(stop.item === historyItem.stopidto) {
							var searchHistoryCopy = JSON.parse(JSON.stringify(historyItem));
							if(historyItem.stopidto >= 0 && historyItem.stopnameto) {
								searchHistoryCopy.stopidfrom = historyItem.stopidto;
								searchHistoryCopy.stopnamefrom = historyItem.stopnameto;
							}
							if(historyItem.stopidfrom >= 0 && historyItem.stopnamefrom) {
								searchHistoryCopy.stopidto = historyItem.stopidfrom;
								searchHistoryCopy.stopnameto = historyItem.stopnamefrom;
							}
													
							stopsFoundInSearchHistory.push({
								type: "to",
								stop: stop,
								closestIndex: i,
								historyIndex: j,
								searchHistory: searchHistoryCopy
							});
						}
					}
				}
			}
			
			stopsFoundInSearchHistory.sort(function(a, b) {
				var indexDestination = (a.type === "from" ? -1 : 1) - (b.type === "from" ? -1 : 1);
				var indexPosition = a.closestIndex - b.closestIndex;
				var indexHistory = a.historyIndex - b.historyIndex;
				return indexPosition || indexHistory || indexDestination;
				// return Math.min(indexPosition, 0.5 * indexHistory);
			});
			
			for(var i = 0; i < stopsFoundInSearchHistory.length; i++) {
				populateSearch(stopsFoundInSearchHistory[i].searchHistory);
				stationFound = true;
				break;
			}
		}
		
		// Place at least closest stop to the "From" field if no route match was found
		if(!stationFound) {
			for(var i = 0; i < stops.length; i++) {
				var newSelectedTransport = Transport.transportOptions.selectTransportById(stops[i].key);
				transportSelectorPage.selectedIndexChange();
				GeneralFunctions.setStopData(from, stops[i].item, stops[i].value, stops[i].key);
				to.empty();
				via.empty();
				stationFound = true;
				break;
			}
		}
		
		return stationFound;
	}
	
	function init() {
		lastSearchPopulate();
		
		var geoLocation = Number(Transport.transportOptions.getDBSetting("geolocation-on-start") || 0);
		if(geoLocation === 0) {
			positionSource.append(function(source) {
				searchPage.findClosestRouteInHistory();
			});
		}
	}
	
	Component.onCompleted: {
		init();
	}

    Rectangle {
        anchors.fill: parent
        color: pageLayout.baseColor

        Flickable {
            id: searchFlickable
            anchors.fill: parent
            contentWidth: parent.width
            contentHeight: errorMessage.height + searchColumn.implicitHeight + 2*searchColumn.anchors.margins + (customDateSwitch.checked ? 0 : units.gu(20)) + units.gu(4)
            flickableDirection: Flickable.VerticalFlick

            ErrorMessage {
                id: errorMessage
            }

            Column {
                id: searchColumn
                anchors {
                    top: errorMessage.bottom
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    margins: units.gu(1)
                }
                spacing: units.gu(2)

                Row {
                    width: parent.width
                    height: units.gu(4)
                    spacing: units.gu(2)

                    Label {
                        id: transportOptionLabel
                        width: parent.width - searchButton.width - parent.spacing
                        height: parent.height
                        text: ""

                        color: pageLayout.baseTextColor
                        font.pixelSize: FontUtils.sizeToPixels("normal")
                        font.bold: true
                        wrapMode: Text.WordWrap
                        verticalAlignment: Text.AlignVCenter

                        property bool ok: false

                        onTextChanged: {
                            from.empty();
                            to.empty();
                        }
                    }

                    Button {
                        id: searchButton
                        width: units.gu(4)
                        height: parent.height
                        color: "transparent"

                        onClicked: pageLayout.addPageToNextColumn(searchPage, transportSelectorPage)

                        Icon {
                            anchors.fill: parent
                            name: "view-list-symbolic"
                            color: pageLayout.baseTextColor
                        }
                    }
                }

                StopSearch {
                    id: from
                    z: 10

                    property var searchFunction: searchPage.search
                    property var errorMessageComponent: errorMessage
                }

                Button {
                    id: switchStationsButton
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: units.gu(3)
                    height: width
                    color: "transparent"

                    onClicked: {
                        var fromData = from.getData();
                        var toData = to.getData();
                        from.setData(toData);
                        to.setData(fromData);
                    }

                    Icon {
                        anchors.fill: parent
                        name: "swap"
                        color: pageLayout.baseTextColor
                    }
                }

                StopSearch {
                    id: to
                    z: 9

                    property var searchFunction: searchPage.search
                    property var errorMessageComponent: errorMessage.value
                }

                RowLayout {
                    width: parent.width
                    spacing: units.gu(2)
                    height: childrenRect.height
                    Layout.fillWidth: true

                    Label {
                        text: i18n.tr("Via")
                        color: pageLayout.baseTextColor
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    Switch {
                        id: advancedSearchSwitch
                        checked: false
                        Layout.fillWidth: false
                    }
                }

                StopSearch {
                    id: via
                    z: 8
                    visible: advancedSearchSwitch.checked

                    property var searchFunction: searchPage.search
                    property var errorMessageComponent: errorMessage.value
                }

                RowLayout {
                    width: parent.width
                    spacing: units.gu(2)
                    height: childrenRect.height
                    Layout.fillWidth: true

                    Label {
                        text: i18n.tr("Custom date")
                        color: pageLayout.baseTextColor
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    Switch {
                        id: customDateSwitch
                        checked: false
                        Layout.fillWidth: false
                    }
                }

                DatePicker {
                    id: datetimePicker
                    visible: customDateSwitch.checked
                }

                RowPicker {
                    id: arrivalDeparturePicker

                    property bool departure: true
                    property var render: function(model) {
                        clear();
                        initialize([i18n.tr("Departure"), i18n.tr("Arrival")], 0, function(itemIndex) {
                            arrivalDeparturePicker.departure = itemIndex === 0;
                        });
                    }

                    Component.onCompleted: {
                        arrivalDeparturePicker.update(function(model) { arrivalDeparturePicker.render(model) });
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: "#ddd"
                }

                RectangleButton {
                    id: rectangleButton
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: itemActivity.running ? i18n.tr("Abort search") : i18n.tr("Search")
                    enabled: transportOptionLabel.ok && from.value && to.value
                    color: active ? pageLayout.colorPalete["headerBG"] : "#ddd"
                    z: 1

                    ActivityIndicator {
                        id: itemActivity
                        anchors {
                            fill: parent
                            centerIn: parent
                            margins: parent.height/6
                        }
                        running: false
                    }

                    Component.onCompleted: {
                        setCallback(function() {
                            if(!itemActivity.running) {
                                searchPage.search();
                            }
                            else {
                                var selectedTransport = Transport.transportOptions.getSelectedTransport();
                                if(selectedTransport) {
                                    selectedTransport.abortAll();
                                }
                            }
                        });
                    }
                }
            }
        }

        Scrollbar {
            flickableItem: searchFlickable
            align: Qt.AlignTrailing
        }
    }

    RecentBottomEdge {
        id: bottomEdge
    }
}
