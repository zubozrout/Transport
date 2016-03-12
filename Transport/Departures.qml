import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Pickers 1.3
import QtQuick.Layouts 1.1
import QtQuick.LocalStorage 2.0

import "engine.js" as Engine
import "localStorage.js" as DB

Page {
    id: departures_page
    visible: false
    clip: true

    property var starting_station: ""
    property var destination_colors: [{}]

    header: PageHeader {
        id: departures_page_header
        title: i18n.tr("Station departures")

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
        if(typeof records == typeof undefined) {
            statusMessagelabel.text = i18n.tr("No departures were found for the selected station.");
            statusMessageBox.visible = true;
            pageLayout.removePages(departures_page);
        }
        departures_list_model.clear();

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

            departures_list_model.append({"num":num, "type":type, "typeName":typeName, "desc":desc, "dateTime":dateTime, "parsedDateTime":parsedDateTime, "destination":destination, "heading":heading, "lineColor":lineColor, "vehicleIcon":"icons/" + typeNameFromId + ".svg", "textOutput": textOutput});
            if(!destination_colors.hasOwnProperty(destination)) {
                destination_colors[destination] = randomColor(0);
            }
        }
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
            height: departures_child_delegate_column.height + 2 * departures_child_delegate_column.anchors.margins
            divider.visible: true

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
                            color: departures_page.destination_colors[destination]

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
                        spacing: units.gu(2)
                        Layout.fillWidth: true

                        Text {
                            text: (destination) ? i18n.tr("Destination:") : ""
                            wrapMode: Text.WordWrap
                            visible: text != ""
                            Layout.fillWidth: false
                        }

                        Text {
                            text: (destination) ? destination : ""
                            wrapMode: Text.WordWrap
                            font.bold: true
                            visible: text != ""
                            Layout.fillWidth: true
                        }
                    }

                    Text {
                        text: (heading) ? i18n.tr("Via:") + " " + heading : ""
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

                Timer {
                    interval: 30000
                    running: true
                    repeat: true
                    triggeredOnStart: true

                    onTriggered: {
                        if(isNaN(time_in.routeStart)) {
                            repeat = false;
                            time_in.remaining = " ";
                            return;
                        }

                        var now = new Date();
                        now.setSeconds(0,0);
                        var diff = Math.round((time_in.routeStart - now) / 60000);
                        if(diff <= 1440) {
                            if(diff < 0) {
                                time_in.remaining = i18n.tr("departed");
                                time_in.color = "#B71C1C";
                                repeat = false;
                                return;
                            }
                            else {
                                var minutes = diff;
                                var hours = 0;
                                if(diff > 59) {
                                    hours = Math.floor(minutes/60);
                                    minutes = diff - hours*60;
                                }

                                if(hours > 0) {
                                    time_in.remaining = i18n.tr("in %1 hour", "in %1 hours", hours).arg(hours);
                                    if(minutes > 0) {
                                        time_in.remaining += " " + i18n.tr("and %1 minute", "and %1 minutes", minutes).arg(minutes);
                                    }
                                }
                                else {
                                    if(minutes == 0) {
                                        time_in.remaining = i18n.tr("just now");
                                    }
                                    else {
                                        time_in.remaining = i18n.tr("in %1 minute", "in %1 minutes", minutes).arg(minutes);
                                    }
                                }
                                time_in.color = "#33691E";
                            }
                        }
                        else {
                            time_in.remaining = Engine.dateToReadableFormat(connection_info.routeStart) + " → " + Engine.dateToReadableFormat(connection_info.routeEnd);
                            return;
                        }
                    }
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
        contentHeight: departures_column.implicitHeight + 2 * departures_column.anchors.margins + scrollToTopButton.height
        contentWidth: parent.width

        Column {
            id: departures_column
            anchors {
                fill: parent
                margins: units.gu(2)
            }
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

                                        return departure_label.text + " " + i18n.tr("at") + " " + hours + ":" + minutes + ", " + date + "." + month + "." + year;
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
            margins: units.gu(2)
            bottom: parent.bottom
            right: parent.right
        }
        width: units.gu(5)
        height: width
        radius: width
        color: "#3949AB"
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
