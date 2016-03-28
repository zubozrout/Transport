import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Pickers 1.3
import Ubuntu.Components.ListItems 1.3 as ListItemSelector
import QtQuick.Layouts 1.1
import QtQuick.LocalStorage 2.0

import "engine.js" as Engine
import "localStorage.js" as DB

Page {
    id: departures_page
    visible: false
    clip: true

    property var starting_station: ""
    property var destinations: ({})
    property var lines: []

    header: PageHeader {
        id: departures_page_header
        title: i18n.tr("Station departures")

        trailingActionBar {
            actions: [
                Action {
                    iconName: departures_search.visible ? "go-up" : "go-down"
                    text: i18n.tr("Search")
                    visible: departures_list_model.count == 0 ? false : true
                    onTriggered: departures_search.visible = !departures_search.visible
                },
                Action {
                    iconName: "filters"
                    text: i18n.tr("Filter results")
                    enabled: departures_list_model.count == 0 ? false : true
                    visible: enabled
                    onTriggered: departures_filter.visible = !departures_filter.visible
                }
            ]
        }

        StyleHints {
            foregroundColor: "#fff"
            backgroundColor: "#3949AB"
        }
    }

    onVisibleChanged: {
        if(DB.getSetting("departuresStop" + trasport_selector_page.selectedItem) && stations.text == "") {
            stations.text = DB.getSetting("departuresStop" + trasport_selector_page.selectedItem);
        }
    }

    function randomColor(brightness){
        function randomChannel(brightness){
            var r = 255 - brightness;
            var n = 0|((Math.random() * r) + brightness);
            var s = n.toString(16);
            return (s.length == 1) ? "0" + s : s;
        }
        return "#" + randomChannel(brightness) + randomChannel(brightness) + randomChannel(brightness);
    }

    function renderDepartures(records) {
        if(typeof records == typeof undefined || records.length == 0) {
            statusMessagelabel.text = i18n.tr("No departures were found for the selected station.");
            statusMessageBox.visible = true;
            departures_search_column.visible = true;
            return;
        }

        departures_list_model.clear();
        destinations = {};
        lines = [];
        departures_search.visible = false;

        var start = records["start"];
        for(var i = 0; i < records.length; i++) {
            var record = records[i];
            var num = Engine.parseDeparturesAPI(record, "num");
            var type = Engine.parseDeparturesAPI(record, "type").toLowerCase();
            var typeName = Engine.parseDeparturesAPI(record, "typeName");
            var typeId = Engine.parseDeparturesAPI(record, "id");
            var desc = Engine.parseDeparturesAPI(record, "desc");
            var dateTime = Engine.parseDeparturesAPI(record, "dateTime");
            var destination = Engine.parseDeparturesAPI(record, "destination");
            var direction = Engine.parseDeparturesAPI(record, "direction");
            var heading = direction ? direction.join(", ") : "";
            var typeNameFromId = (type == "ntram") ? "ntram" : ((type == "nbus") ? "nbus" : Engine.transportIdToName(typeId));
            var lineColor = Engine.parseColor(typeNameFromId, num);
            var parsedDateTime = new Date(Engine.parseDate(dateTime));

            // Text output
            var textOutput = "* " + num + " (" + typeName + ") - " + start + " - " + dateTime + "\n";
            textOutput += "\t→ ";
            textOutput += heading ? "" + heading + " → " : "";
            textOutput += "** " + destination + " **\n";

            departures_list_model.append({"start":start, "num":num, "type":type, "typeName":typeName, "desc":desc, "dateTime":dateTime, "parsedDateTime":parsedDateTime, "destination":destination, "heading":heading, "lineColor":lineColor, "vehicleIcon":"icons/" + typeNameFromId + ".svg", "textOutput": textOutput});
            if(!destinations.hasOwnProperty(destination)) {
                destinations[destination] = randomColor(0);
            }

            if(lines.indexOf(num) < 0) {
                lines.push(num);
            }
        }
        destinationSelector.model = Object.keys(destinations);
        lineSelector.model = lines;
    }

    function search() {
        var date_time = "";
        if(nowLabel.state != "NOW") {
            var Ptime = Qt.formatTime(timeButton.date, "hh:mm");
            var Pdate = Qt.formatDate(dateButton.date, "d.M.yyyy");
            date_time = Pdate + " " + Ptime;
        }
        Engine.getDepartures(trasport_selector_page.selectedItem, stations.text, date_time, "", "", "", departures_page.renderDepartures);

        DB.saveSetting("departuresStop" + trasport_selector_page.selectedItem, stations.text);
    }

    Component {
        id: departures_child_delegate

        ListItem {
            width: parent.width
            height: visible ? departures_child_delegate_column.height + 2 * departures_child_delegate_column.anchors.margins : 0
            divider.visible: true
            visible: {
                if(departures_filter.visible) {
                    if(filterSwitch.state == "DESTINATION") {
                        return destinationSelector.model[destinationSelector.selectedIndex] == destination;
                    }
                    if(filterSwitch.state == "LINE") {
                        return lineSelector.model[lineSelector.selectedIndex] == num;
                    }
                }
                return true;
            }

            property var expanded: false

            trailingActions: ListItemActions {
                actions: [
                    Action {
                        iconName: "edit-copy"
                        onTriggered: Clipboard.push(textOutput)
                    },
                    Action {
                        iconName: "view-expand"
                        onTriggered: {
                            expanded = !expanded;
                            if(expanded) {
                                iconName = "view-collapse";
                            }
                            else {
                                iconName = "view-expand";
                            }
                        }
                    }
                ]
            }

            Rectangle {
                anchors.fill: parent
                color: expanded ? "#fafaef" : "#fff"

                Column {
                    id: departures_child_delegate_column
                    anchors.margins: units.gu(2)
                    anchors.centerIn: parent
                    width: parent.width - 2 * anchors.margins
                    spacing: units.gu(1)

                    RowLayout {
                        width: parent.width
                        spacing: units.gu(2)
                        Layout.fillWidth: true

                        Text {
                            id: time_in
                            width: parent.width
                            text: remaining
                            Layout.fillWidth: true
                            property var remaining: 0
                            property var routeStart: parsedDateTime
                        }

                        Text {
                            text: (dateTime) ? dateTime : ""
                            wrapMode: Text.WordWrap
                            visible: text != ""
                            Layout.fillWidth: false
                        }
                    }

                    RowLayout {
                        width: parent.width
                        spacing: units.gu(2)
                        Layout.fillWidth: true

                        Image {
                            width: units.gu(4)
                            height: width
                            sourceSize.width: width
                            fillMode: Image.PreserveAspectFit
                            source: vehicleIcon
                            Layout.fillWidth: false
                        }

                        Text {
                            text: (num) ? num : ""
                            wrapMode: Text.WordWrap
                            font.pixelSize: FontUtils.sizeToPixels("large")
                            font.bold: true
                            color: lineColor
                            visible: text != ""
                            Layout.fillWidth: false
                        }

                        Text {
                            text: (typeName) ? typeName.toUpperCase() : ""
                            wrapMode: Text.WordWrap
                            visible: text != ""
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            width: units.gu(4)
                            height: width
                            radius: width
                            color: (typeof departures_page.destinations[destination] !== typeof undefined) ? departures_page.destinations[destination] : "#333"

                            Text {
                                anchors.fill: parent
                                text: destination.split(" ").map(function(item){return item[0]}).join("").substring(0, 2).toUpperCase()
                                font.pixelSize: FontUtils.sizeToPixels("normal")
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                color: "#fff"
                            }
                        }
                    }

                    RowLayout {
                        width: parent.width
                        spacing: units.gu(1)
                        Layout.fillWidth: true

                        Text {
                            text: (start) ? i18n.tr("From") + ":" : ""
                            wrapMode: Text.WordWrap
                            visible: text != ""
                            Layout.fillWidth: false
                        }

                        Text {
                            text: (start) ? start : ""
                            wrapMode: Text.WordWrap
                            visible: text != ""
                            Layout.fillWidth: true
                        }

                        Text {
                            text: (destination) ? i18n.tr("To") + ":" : ""
                            wrapMode: Text.WordWrap
                            visible: text != ""
                            Layout.fillWidth: false
                        }

                        Text {
                            text: (destination) ? destination : ""
                            wrapMode: Text.WordWrap
                            font.bold: true
                            visible: text != ""
                            Layout.fillWidth: false
                        }
                    }

                    Text {
                        text: (heading) ? i18n.tr("Via") + ":" + " " + heading : ""
                        width: parent.width
                        wrapMode: Text.WordWrap
                        visible: expanded && text != ""
                    }

                    Text {
                        text: (desc) ? desc : ""
                        width: parent.width
                        wrapMode: Text.WordWrap
                        font.italic: true
                        visible: expanded && text != ""
                    }
                }

                DepartureTimer {
                    property alias routeStart: time_in.routeStart
                    property alias startTime: time_in.routeStart
                    property alias remainingTime: time_in.remaining
                    property alias timeColor: time_in.color
                }
            }
        }
    }

    Flickable {
        id: departures_page_flickable
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.top: departures_page_header.bottom
        contentHeight: departures_column.implicitHeight
        contentWidth: parent.width
        clip: true

        Column {
            id: departures_column
            anchors.fill: parent

            Rectangle {
                id: departures_search
                width: parent.width
                height: departures_search_column.implicitHeight + 2 * departures_search_column.anchors.margins
                color: "transparent"
                visible: true

                onVisibleChanged: {
                    if(visible) {
                        departures_page_flickable.contentY = 0;
                    }
                }

                Column {
                    id: departures_search_column
                    anchors.fill: parent
                    anchors.margins: units.gu(2)
                    spacing: units.gu(2)

                    StationQuery {
                        id: stations
                        property string placeholder: i18n.tr("Station")
                    }

                    RowLayout {
                        width: parent.width
                        spacing: units.gu(2)

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: units.gu(2)

                            Switch {
                                id: nowSwitch
                                checked: true
                                anchors.verticalCenter: parent.verticalCenter

                                onCheckedChanged: {
                                    if(checked) {
                                        nowLabel.state = "NOW";
                                        time_date_picker.visible = false;
                                    }
                                    else {
                                        nowLabel.state = "CUSTOM";
                                        time_date_picker.visible = true;
                                    }
                                }
                            }

                            Label {
                                id: nowLabel
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                                state: "NOW"
                                states: [
                                    State {
                                        name: "NOW"
                                        PropertyChanges { target: nowLabel; text: i18n.tr("Now") }
                                    },
                                    State {
                                        name: "CUSTOM"
                                        PropertyChanges {
                                            target: nowLabel
                                            text: {
                                                var hours = timeButton.date.getHours();
                                                var minutes = timeButton.date.getMinutes();
                                                if(parseInt(minutes) < 10) {
                                                    minutes = "0" + minutes;
                                                }

                                                var date = dateButton.date.getDate();
                                                var month = dateButton.date.getMonth() + 1;
                                                var year = dateButton.date.getFullYear();

                                                return i18n.tr("Departure at") + " " + hours + ":" + minutes + ", " + date + "." + month + "." + year;
                                            }
                                        }
                                    }
                                ]
                            }
                        }
                    }

                    Column {
                        id: time_date_picker
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: units.gu(2)
                        visible: false

                        RowLayout {
                            height: childrenRect.height
                            Layout.fillWidth: true
                            spacing: units.gu(2)

                            Button {
                                id: timeButton
                                text: i18n.tr("Change time")
                                property date date: new Date()
                                onClicked: PickerPanel.openDatePicker(timeButton, "date", "Hours|Minutes");
                            }

                            Button {
                                id: dateButton
                                text: i18n.tr("Change date")
                                property date date: new Date()
                                onClicked: PickerPanel.openDatePicker(dateButton, "date", "Years|Months|Days");
                            }
                        }
                    }

                    Button {
                        id: search
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: i18n.tr("Search")
                        focus: true
                        color: "#3949AB"

                        onClicked: {
                            departures_page.search();
                        }

                        state: (stations.text == "") ? "DISABLED" : (api.running ? "ACTIVE" : "ENABLED")

                        states: [
                            State {
                                name: "ENABLED"
                                PropertyChanges { target: search; enabled: true }
                                PropertyChanges { target: search; color: "#3949AB" }
                            },
                            State {
                                name: "DISABLED"
                                PropertyChanges { target: search; enabled: false }
                                PropertyChanges { target: search; color: UbuntuColors.coolGrey }
                            },
                            State {
                                name: "ACTIVE"
                                PropertyChanges { target: search; enabled: false }
                                PropertyChanges { target: search; color: UbuntuColors.warmGrey }
                            }
                        ]

                        ActivityIndicator {
                            id: searchActivity
                            anchors.fill: parent
                            running: api.running
                        }
                    }
                }
            }
            Rectangle {
                id: departures_filter
                width: parent.width
                height: departures_filter_column.implicitHeight + 2 * departures_filter_column.anchors.margins
                color: "transparent"
                visible: false

                onVisibleChanged: {
                    if(visible) {
                        departures_page_flickable.contentY = 0;
                    }
                }

                Column {
                    id: departures_filter_column
                    anchors.fill: parent
                    anchors.margins: units.gu(2)
                    spacing: units.gu(2)

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: units.gu(2)

                        Switch {
                            id: filterSwitch
                            checked: true
                            anchors.verticalCenter: parent.verticalCenter

                            state: "LINE"
                            states: [
                                State {
                                    name: "LINE"
                                    PropertyChanges { target: filterLabel; text: i18n.tr("Filter by line") }
                                },
                                State {
                                    name: "DESTINATION"
                                    PropertyChanges { target: filterLabel; text: i18n.tr("Filter by destination") }
                                }
                            ]

                            onCheckedChanged: {
                                if(checked) {
                                    state = "LINE";
                                }
                                else {
                                    state = "DESTINATION";
                                }
                            }
                        }

                        Label {
                            id: filterLabel
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                        }
                    }

                    ListItemSelector.ItemSelector {
                        id: destinationSelector
                        containerHeight: model.length > 5 ? 5 * itemHeight : model.length * itemHeight
                        expanded: false
                        model: []
                        visible: model.length > 0 && filterSwitch.state == "DESTINATION"
                    }

                    ListItemSelector.ItemSelector {
                        id: lineSelector
                        containerHeight: model.length > 5 ? 5 * itemHeight : model.length * itemHeight
                        expanded: false
                        model: []
                        visible: model.length > 0 && filterSwitch.state == "LINE"
                    }
                }
            }

            Rectangle {
                color: "#ddd"
                width: parent.width
                anchors.horizontalCenter: parent.horizontalCenter
                height: 1
            }

            ListView {
                id: departures_list_view
                height: childrenRect.height
                width: departures_page.width
                anchors.horizontalCenter: parent.horizontalCenter
                interactive: false

                model: ListModel {
                    id: departures_list_model
                }
                delegate: departures_child_delegate
            }
        }
    }

    Rectangle {
        id: scrollToTopButton
        anchors {
            margins: units.gu(3)
            top: departures_page_flickable.top
            right: departures_page_flickable.right
        }
        width: units.gu(6)
        height: width
        radius: width
        color: "#333"
        opacity: 0.85
        visible: departures_page_flickable.contentY > departures_page.height

        Icon {
            anchors.fill: parent
            anchors.margins: units.gu(1)
            name: "up"
            color: "#fff"
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                departures_page_flickable.contentY = 0;
            }
        }
    }

    Scrollbar {
        flickableItem: departures_page_flickable
        align: Qt.AlignTrailing
    }
}
