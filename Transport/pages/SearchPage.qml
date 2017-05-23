import QtQuick 2.4
import Ubuntu.Components 1.3
import QtQuick.Layouts 1.1

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

        trailingActionBar {
            actions: [
                Action {
                    iconName: "help"
                    text: i18n.tr("About")
                    onTriggered: {
                        pageLayout.addPageToNextColumn(searchPage, aboutPage);
                    }
                },
                Action {
                    iconName: "search"
                    text: i18n.tr("Search")
                    onTriggered: {
                        pageLayout.addPageToNextColumn(searchPage, connectionsPage);
                    }
                }
           ]
        }
    }

    clip: true

    function search() {
        var fromVal = from.selectedStop ? from.selectedStop : from.value;
        var toVal = to.selectedStop ? to.selectedStop : to.value;
        var viaVal = advancedSearchSwitch.checked ? (via.selectedStop ? via.selectedStop : via.value) : "";

        var selectedTransport = Transport.transportOptions.getSelectedTransport();

        if(selectedTransport && fromVal && toVal) {
            selectedTransport.abortAll();

            var dateTime = null
            if(customDateSwitch.checked) {
                var Pdate = Qt.formatDate(datetimePicker.datePicker.date, "d.M.yyyy");
                var Ptime = Qt.formatTime(datetimePicker.timePicker.date, "hh:mm");
                dateTime = Pdate + " " + Ptime;
            }

            var departure = !arrivalSearchSwitch.checked || false;

            var connection = selectedTransport.createConnection({
                from: fromVal,
                to: toVal,
                via: viaVal,
                departure: departure,
                time: dateTime
            });

            itemActivity.running = true;
            connection.search({}, function(object, state) {
                itemActivity.running = false;
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

                            connectionsPage.enablePrevNextButtons(selectedTransport.getAllConnections());
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
            if(newSelectedTransport) {
                /*
                from.empty();
                to.empty();
                via.empty();
                */

                var langCode = Transport.langCode(true);
                transportSelectorPage.selectedTransport = newSelectedTransport.getName(langCode);

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

    Component.onCompleted: {
        lastSearchPopulate();
    }

    Rectangle {
        anchors.fill: parent
        color: pageLayout.baseColor

        Flickable {
            id: searchFlickable
            anchors.fill: parent
            contentWidth: parent.width
            contentHeight: errorMessage.height + searchColumn.implicitHeight + 2*searchColumn.anchors.margins + (customDateSwitch.checked ? 0 : units.gu(20)) + units.gu(4)

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
                        text: transportSelectorPage.selectedTransport || i18n.tr("Select transport method");

                        color: pageLayout.baseTextColor
                        font.pixelSize: FontUtils.sizeToPixels("normal")
                        font.bold: true
                        wrapMode: Text.WordWrap
                        verticalAlignment: Text.AlignVCenter

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

                RowLayout {
                    width: parent.width
                    spacing: units.gu(2)
                    height: childrenRect.height
                    Layout.fillWidth: true

                    Label {
                        text: !arrivalSearchSwitch.checked ? i18n.tr("Departure") : i18n.tr("Arrival")
                        color: pageLayout.baseTextColor
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    Button {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: itemActivity.running ? i18n.tr("Abort search") : i18n.tr("Search")
                        color: itemActivity.running ? UbuntuColors.red : "#fff"
                        enabled: transportSelectorPage.selectedTransport && from.value && to.value
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

                        onClicked: {
                            if(!itemActivity.running) {
                                searchPage.search();
                            }
                            else {
                                var selectedTransport = Transport.transportOptions.getSelectedTransport();
                                if(selectedTransport) {
                                    selectedTransport.abortAll();
                                }
                            }
                        }
                    }

                    Switch {
                        id: arrivalSearchSwitch
                        checked: false
                        Layout.fillWidth: false
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
