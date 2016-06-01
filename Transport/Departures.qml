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

    property var destinations: ({})
    property var lines: []

    header: PageHeader {
        id: departures_page_header
        title: i18n.tr("Station departures")

        trailingActionBar {
            actions: [
                Action {
                    iconName: "search"
                    text: i18n.tr("Search")
                    enabled: departures_list_model.count == 0 ? false : true
                    visible: enabled
                    onTriggered: departures_page_flickable_search.state == "DISPLAYED" ? departures_page_flickable_search.state = "CLOSED" : departures_page_flickable_search.state = "DISPLAYED"
                },
                Action {
                    iconName: "filters"
                    text: i18n.tr("Filter results")
                    enabled: departures_list_model.count == 0 ? false : true
                    visible: enabled
                    onTriggered: departures_page_flickable_filter.state == "DISPLAYED" ? departures_page_flickable_filter.state = "CLOSED" : departures_page_flickable_filter.state = "DISPLAYED"
                }
            ]
        }

        StyleHints {
            foregroundColor: "#fff"
            backgroundColor: "#3949AB"
        }
    }

    onVisibleChanged: {
        var options = transport_selector_page.selectedItem;
        var departuresStopObj = JSON.parse(DB.getSetting("departuresStopObj" + options));
        if(departuresStopObj && stations.displayText == "") {
            stations.text = departuresStopObj.name;
            stations.coorX = departuresStopObj.x;
            stations.coorY = departuresStopObj.y;
            stations.stationInputModel.clear();
        }
    }

    function renderDepartures(records) {
        if(typeof records == typeof undefined || records.length == 0) {
            statusMessagelabel.text = i18n.tr("No departures were found for the selected station.");
            statusMessageBox.visible = true;
            departures_page_flickable_search.state = "DISPLAYED";
            return;
        }

        departures_list_model.clear();
        destinations = {};
        lines = [];
        departures_page_flickable_search.state = "CLOSED";

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
                destinations[destination] = Engine.randomColor(0);
            }

            if(lines.indexOf(num) < 0) {
                lines.push(num);
            }
        }
        destinationSelector.model = Object.keys(destinations);
        lineSelector.model = lines;
    }

    function search() {
        var options = transport_selector_page.selectedItem;
        var date_time = "";
        if(nowLabel.state != "NOW") {
            var Ptime = Qt.formatTime(timeButton.date, "hh:mm");
            var Pdate = Qt.formatDate(dateButton.date, "d.M.yyyy");
            date_time = Pdate + " " + Ptime;
        }
        Engine.getDepartures(options, stations.displayText, date_time, "", "", "", departures_page.renderDepartures);

        DB.saveSetting("departuresStopObj" + options, JSON.stringify({"name": stations.displayText, "x": stations.coorX, "y": stations.coorY}));
        departures_start.station = stations.displayText;
    }

    Component {
        id: departures_child_delegate

        ListItem {
            width: parent.width
            height: visible ? departures_child_background.height : 0
            divider.visible: true
            visible: {
                if(departures_page_flickable_filter.state == "DISPLAYED") {
                    if(filter_by_destination_checkbox.checked && !filter_by_line_checkbox.checked) {
                        return destinationSelector.model[destinationSelector.selectedIndex] == destination;
                    }
                    if(filter_by_line_checkbox.checked && !filter_by_destination_checkbox.checked) {
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
                id: departures_child_background
                anchors {
                    left: parent.left
                    right: parent.right
                }
                height: departures_child_delegate_column.height + units.gu(0.3)
                color: expanded ? "#fafaef" : "#fff"

                Column {
                    id: departures_child_delegate_column
                    anchors.margins: units.gu(2)
                    anchors.centerIn: parent
                    width: parent.width - 2 * anchors.margins
                    spacing: units.gu(1)

                    RowLayout {
                        width: parent.width
                        spacing: units.gu(1)
                        Layout.fillWidth: true

                        Image {
                            anchors.verticalCenter: parent.verticalCenter
                            width: units.gu(3)
                            height: width
                            sourceSize.width: width
                            fillMode: Image.PreserveAspectFit
                            source: vehicleIcon
                            Layout.fillWidth: false
                        }

                        Rectangle {
                            width: units.gu(4)
                            height: width/2
                            radius: 4
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

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: (num) ? num : ""
                            wrapMode: Text.WordWrap
                            font.bold: true
                            color: lineColor
                            visible: text != ""
                            Layout.fillWidth: false
                        }

                        Text {
                            text: destination
                            wrapMode: Text.WordWrap
                            font.pixelSize: FontUtils.sizeToPixels("small")
                            visible: text != ""
                            Layout.fillWidth: false
                        }

                        Text {
                            id: time_in
                            width: parent.width
                            text: remaining
                            horizontalAlignment: Text.AlignRight
                            wrapMode: Text.WordWrap
                            font.pixelSize: FontUtils.sizeToPixels("small")
                            Layout.fillWidth: true
                            property var remaining: 0
                            property var routeStart: parsedDateTime
                        }

                        Text {
                            text: (dateTime) ? dateTime.split(" ").pop() : ""
                            wrapMode: Text.WordWrap
                            visible: text != ""
                            Layout.fillWidth: false
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: units.gu(0.25)
                        visible: expanded

                        Text {
                            text: (typeName) ? typeName.toUpperCase() : ""
                            font.bold: true
                            wrapMode: Text.WordWrap
                            visible: text != ""
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
                        }

                        RowLayout {
                            width: parent.width
                            spacing: units.gu(1)
                            Layout.fillWidth: true

                            Text {
                                text: (destination) ? i18n.tr("To") + ":" : ""
                                wrapMode: Text.WordWrap
                                visible: text != ""
                                Layout.fillWidth: false
                            }

                            Text {
                                text: (destination) ? destination : ""
                                wrapMode: Text.WordWrap
                                visible: text != ""
                                Layout.fillWidth: true
                            }
                        }


                        Text {
                            text: (heading) ? i18n.tr("Via") + ":" + " " + heading : ""
                            width: parent.width
                            wrapMode: Text.WordWrap
                            visible: text != ""
                        }

                        Text {
                            text: (desc) ? desc : ""
                            width: parent.width
                            wrapMode: Text.WordWrap
                            font.italic: true
                            visible: text != ""
                        }

                        Rectangle {
                            width: parent.width
                            height: units.gu(1.5)
                            color: "transparent"
                        }
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
        id: departures_page_flickable_search
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: departures_page_header.bottom
        contentWidth: parent.width
        z: 2
        state: "DISPLAYED"
        clip: true

        states: [
            State {
                name: "DISPLAYED"
                PropertyChanges { target: departures_search; visible: true }
                PropertyChanges { target: departures_on_search; visible: false }
                PropertyChanges { target: departures_page_flickable_search; contentHeight: departures_search.height }
                PropertyChanges { target: departures_page_flickable_search; height: departures_search.height }
            },
            State {
                name: "CLOSED"
                PropertyChanges { target: departures_search; visible: false }
                PropertyChanges { target: departures_on_search; visible: true }
                PropertyChanges { target: departures_page_flickable_search; contentHeight: departures_on_search.height }
                PropertyChanges { target: departures_page_flickable_search; height: departures_on_search.height }
            }
        ]

        Column {
            id: departures_on_search
            width: parent.width

            Label {
                id: departures_start
                width: parent.width
                height: contentHeight + units.gu(1)
                text: i18n.tr("Station") + ": " + station
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
                property var station: ""
            }
        }

        Rectangle {
            id: departures_search
            width: parent.width
            height: departures_search_column.implicitHeight + 2 * departures_search_column.anchors.margins
            color: "transparent"

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

                    state: (stations.displayText == "") ? "DISABLED" : (api.running ? "ACTIVE" : "ENABLED")

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
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: "#ddd"
        }
    }

    Flickable {
        id: departures_page_flickable_filter
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: departures_page_flickable_search.bottom
        contentHeight: departures_filter.height
        contentWidth: parent.width
        z: 1
        state: "CLOSED"
        clip: true

        states: [
            State {
                name: "DISPLAYED"
                PropertyChanges { target: departures_page_flickable_filter; visible: true }
                PropertyChanges { target: departures_page_flickable_filter; height: departures_filter.height }
            },
            State {
                name: "CLOSED"
                PropertyChanges { target: departures_page_flickable_filter; visible: false }
                PropertyChanges { target: departures_page_flickable_filter; height: 0 }
            }
        ]

        Rectangle {
            id: departures_filter
            anchors {
                margins: units.gu(2)
                left: parent.left
                right: parent.right
            }
            height: departures_filter_column.implicitHeight + 2 * departures_filter.anchors.margins
            color: "transparent"

            Column {
                id: departures_filter_column
                anchors.centerIn: parent
                width: parent.width
                spacing: units.gu(2)

                RowLayout {
                    width: parent.width
                    Layout.fillWidth: true
                    spacing: units.gu(2)

                    CheckBox {
                        id: filter_by_line_checkbox
                        checked: true
                        Layout.fillWidth: false

                        onCheckedChanged: {
                            if(checked) {
                                filter_by_destination_checkbox.checked = false;
                            }
                            else {
                                if(!filter_by_destination_checkbox.checked) {
                                    departures_page_flickable_filter.state = "CLOSED";
                                    filter_by_line_checkbox.checked = true;
                                }
                            }
                        }
                    }

                    Label {
                        text: i18n.tr("Filter by line")
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }

                    CheckBox {
                        id: filter_by_destination_checkbox
                        checked: false
                        Layout.fillWidth: false

                        onCheckedChanged: {
                            if(checked) {
                                filter_by_line_checkbox.checked = false;
                            }
                            else {
                                if(!filter_by_line_checkbox.checked) {
                                    departures_page_flickable_filter.state = "CLOSED";
                                    filter_by_line_checkbox.checked = true;
                                }
                            }
                        }
                    }

                    Label {
                        text: i18n.tr("Filter by destination")
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                    }
                }

                ListItemSelector.ItemSelector {
                    id: destinationSelector
                    containerHeight: model.length > 5 ? 5 * itemHeight : model.length * itemHeight
                    expanded: false
                    model: []
                    visible: model.length > 0 && filter_by_destination_checkbox.checked
                }

                ListItemSelector.ItemSelector {
                    id: lineSelector
                    containerHeight: model.length > 5 ? 5 * itemHeight : model.length * itemHeight
                    expanded: false
                    model: []
                    visible: model.length > 0 && filter_by_line_checkbox.checked
                }
            }
        }
    }

    ListView {
        id: departures_list_view
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.top: departures_page_flickable_filter.bottom
        clip: true

        model: ListModel {
            id: departures_list_model
        }
        delegate: departures_child_delegate
    }

    Rectangle {
        id: scrollToTopButton
        anchors {
            margins: units.gu(3)
            top: departures_list_view.top
            right: parent.right
        }
        width: units.gu(7)
        height: width
        radius: width
        color: "#000"
        opacity: 0.85
        visible: departures_list_view.contentY > 2 * parent.height

        Icon {
            anchors.fill: parent
            anchors.margins: units.gu(1)
            name: "up"
            color: "#fff"
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                departures_list_view.contentY = 0;
            }
        }
    }

    Scrollbar {
        flickableItem: departures_list_view
        align: Qt.AlignTrailing
    }
}
