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
        title: i18n.tr("Transport Basic")
        flickable: searchFlickable

        StyleHints {
            foregroundColor: "#fff"
            backgroundColor: pageLayout.headerColor
        }

        trailingActionBar {
            actions: [
                Action {
                    iconName: "search"
                    text: "search"
                    onTriggered: {
                        pageLayout.addPageToNextColumn(searchPage, connectionsPage);
                    }
                }
           ]
        }
    }

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

            var connection = selectedTransport.createConnection({
                from: fromVal,
                to: toVal,
                via: viaVal,
                time: dateTime
            });

            itemActivity.running = true;
            connection.search({}, function(object) {
                itemActivity.running = false;
                if(object) {
                    connectionsPage.connections = connection;
                    connectionsPage.renderAllConnections(connection);
                    pageLayout.addPageToNextColumn(searchPage, connectionsPage);
                }
            });
        }
    }

    Rectangle {
        anchors.fill: parent
        color: pageLayout.baseColor

        Flickable {
            id: searchFlickable
            anchors.fill: parent
            contentWidth: parent.width
            contentHeight: searchColumn.implicitHeight + 2*searchColumn.anchors.margins

            Column {
                id: searchColumn
                anchors {
                    fill: parent
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

                Button {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: i18n.tr("Search")
                    color: "#fff"
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
                        searchPage.search();
                    }
                }
            }
        }

        Scrollbar {
            flickableItem: searchFlickable
            align: Qt.AlignTrailing
        }
    }
}
