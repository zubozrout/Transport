import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Pickers 1.3
import Ubuntu.Components.Themes 1.3
import Ubuntu.Components.ListItems 1.3 as ListItem
import QtQuick.Layouts 1.1
import QtQuick.LocalStorage 2.0

import Transport 1.0

import "engine.js" as Engine
import "localStorage.js" as DB

/*!
    \brief MainView with a Label and Button elements.
*/

MainView {
    // objectName for functional testing purposes (autopilot-qt5)
    objectName: "mainView"

    // Note! applicationName needs to match the "name" field of the click manifest
    applicationName: "transport.zubozrout"

    /*
     This property enables the application to change orientation
     when the device is rotated. The default is false.
    */
    automaticOrientation: true

    width: units.gu(100)
    height: units.gu(75)

    property var db: null;
    property var handle: null
    property var first_id: null
    property var last_id: null

    // Common functions:
    function saveStationToDb(textfield, listview, model) {
        if(listview.lastSelected && listview.lastSelected == textfield.displayText) {
            DB.appendNewStop(trasport_selector_page.selectedItem, listview.lastSelected);
        }
    }

    function checkClear(textfield, listview, model) {
        if(listview.currentIndex >= 0 && typeof model.get(listview.currentIndex) !== typeof undefined && model.get(listview.currentIndex).name == textfield.displayText) {
            api.abort();
            listview.lastSelected = model.get(listview.currentIndex).name;
            model.clear();
        }
    }

    function stationInputChanged(textfield, listview, model) {
        search.resetState();
        if(textfield.focus && textfield.displayText != listview.lastSelected) {
            Engine.complete(trasport_selector_page.selectedItem, textfield.displayText, model);
            checkClear(textfield, listview, model);
        }
    }

    Api {
        id: api
        property var callback: null;

        onResponseChanged: {
            if(callback && response) {
                callback(response);
            }
        }

        function abort() {
            if(running && callback) {
                callback = null;
                request = "";
            }
        }
    }

    AdaptivePageLayout {
        id: pageLayout
        anchors.fill: parent
        primaryPage: search_page

        layouts: PageColumnsLayout {
            when: width > units.gu(80)
            PageColumn {
                fillWidth: true
                minimumWidth: units.gu(25)
                maximumWidth: units.gu(50)
                preferredWidth: units.gu(40)
            }
            PageColumn {
                fillWidth: true
                minimumWidth: units.gu(45)
            }
        }

        Page {
            id: search_page
            title: i18n.tr("Transport")
            visible: false
            clip: true
            head.locked: true

            head.actions: [
                Action {
                    iconName: "settings"
                    text: i18n.tr("Nastavení")
                    onTriggered: pageLayout.addPageToNextColumn(search_page, settings_page);
                },
                Action {
                    iconName: "help"
                    text: i18n.tr("O aplikaci")
                    onTriggered: pageLayout.addPageToNextColumn(search_page, about_page);
                },
                Action {
                    iconName: "go-to"
                    text: i18n.tr("Výsledky vyhledávání")
                    enabled: Object.keys(result_page.response).length > 0 ? true : false
                    onTriggered: pageLayout.addPageToNextColumn(search_page, result_page);
                }
            ]

            function search(state) {
                if(!from.displayText || !to.displayText) {
                    return;
                }
                api.abort();

                var count = Number(DB.getSetting("settings_transport_count"));
                count = count || count <= 0 ? count : 10;
                var options = trasport_selector_page.selectedItem;

                if(typeof state !== typeof undefined) {
                    switch(state) {
                        case "previous":
                            if(first_id != null) {
                                Engine.getConnectionsFB("ABCz", handle, first_id, count, true, Engine.showConnectionsFB);
                            }
                            return;
                        case "next":
                            if(last_id != null) {
                                Engine.getConnectionsFB("ABCz", handle, last_id, count, false, Engine.showConnectionsFB);
                            }
                            return;
                        default:
                            return;
                    }
                }

                var date_time = "";
                if(nowLabel.state != "NOW") {
                    var Ptime = Qt.formatTime(timePicker.date, "hh:mm");
                    var Pdate = Qt.formatDate(datePicker.date, "d.M.yyyy");
                    date_time = Pdate + " " + Ptime;
                }

                var departure_final = (departure_label.state == "DEPARTURE");
                var via_final = advanced_switch.checked ? via.displayText : "";
                Engine.getConnections(options, date_time, departure_final, from.displayText, to.displayText, via_final, count, Engine.showConnections);

                // DB save selected values:
                DB.saveSetting("from" + options, from.displayText);
                DB.saveSetting("to" + options, to.displayText);
                if(advanced_switch.checked) {
                    DB.saveSetting("via" + options, via.displayText);
                    DB.appendNewStop(options, via.displayText);
                }
                else {
                    DB.saveSetting("via" + options, "");
                }
                DB.saveSetting("optionsList", trasport_selector_page.selectedName);
                saveStationToDb(from, from_list_view, from_list_model);
                saveStationToDb(to, to_list_view, to_list_model);
                saveStationToDb(via, via_list_view, via_list_model);
            }

            Flickable {
                id: search_page_flickable
                anchors.fill: parent
                contentHeight: search_column.implicitHeight + 2* search_column.anchors.margins
                contentWidth: parent.width

                Column {
                    id: search_column
                    anchors {
                        fill: parent
                        margins: units.gu(2)
                    }
                    spacing: units.gu(2)

                    RowLayout {
                        width: parent.width
                        spacing: units.gu(2)

                        Label {
                            text: trasport_selector_page.selectedName
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                            font.pixelSize: FontUtils.sizeToPixels("large")
                        }

                        Button {
                            height: units.gu(3)
                            Layout.fillWidth: true
                            Layout.minimumWidth: height
                            Layout.preferredWidth: height
                            Layout.maximumWidth: height
                            iconName: "view-list-symbolic"
                            color: "transparent"

                            onClicked: pageLayout.addPageToNextColumn(search_page, trasport_selector_page);
                        }
                    }

                    Rectangle {
                        color: "#ddd"
                        width: parent.width
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: 1
                    }

                    Column {
                        width: parent.width
                        clip: true

                        TextField {
                            id: from
                            width: parent.width
                            placeholderText: i18n.tr("Z")
                            hasClearButton: true
                            onDisplayTextChanged: stationInputChanged(from, from_list_view, from_list_model);

                            onFocusChanged: {
                                if(focus) {
                                    from_help.visible = true;
                                }
                                else {
                                    from_help.visible = false;
                                }
                            }
                        }

                        Rectangle {
                            id: from_help
                            width: parent.width
                            height: from_list_view.contentHeight
                            color: "#E8EAF6"
                            clip: true

                            Component {
                                id: fromDelegate
                                Item {
                                    anchors.margins: units.gu(2); width: from_help.width; height: from_stop.paintedHeight + units.gu(2)
                                    Text { id: from_stop; text: name; anchors.centerIn: parent; wrapMode: Text.Wrap }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            var name = from_list_model.get(index).name;
                                            if(name != "") {
                                                Qt.inputMethod.commit();
                                                from_list_view.currentIndex = index;
                                                from.text = name;
                                                from.focus = false;
                                            }
                                        }
                                    }
                                }
                            }

                            ListView {
                                id: from_list_view
                                anchors.fill: parent
                                model: ListModel { id: from_list_model }
                                delegate: fromDelegate
                                highlight: Rectangle { color: "#9FA8DA" }
                                onCurrentIndexChanged: checkClear(from, from_list_view, model)
                                property var lastSelected: null
                            }
                        }
                    }

                    Button {
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: "#3949AB"

                        Image {
                            anchors.fill: parent;
                            source: "switch.svg";
                            scale: 0.5
                        }

                        onClicked: {
                            var tmp_text = from.text;
                            from.text = to.text;
                            to.text = tmp_text;
                        }
                    }

                    Column {
                        width: parent.width
                        clip: true

                        TextField {
                            id: to
                            width: parent.width
                            placeholderText: i18n.tr("Do")
                            hasClearButton: true
                            onDisplayTextChanged: stationInputChanged(to, to_list_view, to_list_model);


                            onFocusChanged: {
                                if(focus) {
                                    to_help.visible = true;
                                }
                                else {
                                    to_help.visible = false;
                                }
                            }
                        }

                        Rectangle {
                            id: to_help
                            width: parent.width
                            height: to_list_view.contentHeight
                            color: "#E8EAF6"
                            clip: true

                            Component {
                                id: toDelegate
                                Item {
                                    anchors.margins: units.gu(2); width: to_help.width; height: to_stop.paintedHeight + units.gu(2)
                                    Text { id: to_stop; text: name; anchors.centerIn: parent; wrapMode: Text.Wrap }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            var name = to_list_model.get(index).name;
                                            if(name != "") {
                                                Qt.inputMethod.commit();
                                                to_list_view.currentIndex = index;
                                                to.text = name;
                                                to.focus = false;
                                            }
                                        }
                                    }
                                }
                            }

                            ListView {
                                id: to_list_view
                                anchors.fill: parent
                                model: ListModel { id: to_list_model }
                                delegate: toDelegate
                                highlight: Rectangle { color: "#9FA8DA" }
                                onCurrentIndexChanged: checkClear(to, to_list_view, model)
                                property var lastSelected: null
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: "#ddd"
                    }

                    Row {
                        spacing: units.gu(2)
                        anchors.horizontalCenter: parent.horizontalCenter

                        Label {
                            id: avanced_label
                            text: i18n.tr("Rozšířené hledání")
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Switch {
                            id: advanced_switch
                            checked: via.displayText == "" ? false : true
                            anchors.verticalCenter: parent.verticalCenter

                            onCheckedChanged: {
                                if(!checked) {
                                    advanced_options.visible = false;
                                }
                                else {
                                    advanced_options.visible = true;
                                }
                            }
                        }
                    }

                    Column {
                        id: advanced_options
                        width: parent.width
                        spacing: units.gu(2)
                        visible: false

                        Column {
                            width: parent.width
                            clip: true

                            TextField {
                                id: via
                                width: parent.width
                                placeholderText: i18n.tr("Přes")
                                hasClearButton: true
                                onDisplayTextChanged: stationInputChanged(via, via_list_view, via_list_model);

                                onFocusChanged: {
                                    if(focus) {
                                        via_help.visible = true;
                                    }
                                    else {
                                        via_help.visible = false;
                                    }
                                }
                            }

                            Rectangle {
                                id: via_help
                                width: parent.width
                                height: via_list_view.contentHeight
                                color: "#E8EAF6"
                                clip: true

                                Component {
                                    id: viaDelegate
                                    Item {
                                        anchors.margins: units.gu(2); width: via_help.width; height: via_stop.paintedHeight + units.gu(2)
                                        Text { id: via_stop; text: name; anchors.centerIn: parent; wrapMode: Text.Wrap }
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                var name = via_list_model.get(index).name;
                                                if(name != "") {
                                                    Qt.inputMethod.commit();
                                                    via_list_view.currentIndex = index;
                                                    via.text = name;
                                                    via.focus = false;
                                                }
                                            }
                                        }
                                    }
                                }

                                ListView {
                                    id: via_list_view
                                    anchors.fill: parent
                                    model: ListModel { id: via_list_model }
                                    delegate: viaDelegate
                                    highlight: Rectangle { color: "#9FA8DA" }
                                    onCurrentIndexChanged: checkClear(via, via_list_view, model)
                                    property var lastSelected: null
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: "#ddd"
                    }

                    Rectangle {
                        width: parent.width
                        height: childrenRect.height
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: "transparent"

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
                                            PropertyChanges { target: nowLabel; text: i18n.tr("Teď") }
                                        },
                                        State {
                                            name: "CUSTOM"
                                            PropertyChanges {
                                                target: nowLabel
                                                text: departure_label.text + " " + i18n.tr("v") + " " + timePicker.date.getHours() + ":" + timePicker.date.getMinutes() + ", " + datePicker.date.getDate() + "." + (datePicker.date.getMonth() + 1) + "." + datePicker.date.getFullYear();
                                            }
                                        }
                                    ]
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: false
                                spacing: units.gu(2)
                                Switch {
                                    id: departure_switch
                                    checked: true
                                    anchors.verticalCenter: parent.verticalCenter

                                    onCheckedChanged: {
                                        if(checked) {
                                            departure_label.state = "DEPARTURE";
                                        }
                                        else {
                                            departure_label.state = "ARRIVAL";
                                        }
                                    }
                                }

                                Label {
                                    id: departure_label
                                    Layout.fillWidth: true
                                    wrapMode: Text.WordWrap
                                    state: "DEPARTURE"

                                    states: [
                                        State {
                                            name: "DEPARTURE"
                                            PropertyChanges { target: departure_label; text: i18n.tr("Odjezd") }
                                        },
                                        State {
                                            name: "ARRIVAL"
                                            PropertyChanges { target: departure_label; text: i18n.tr("Příjezd") }
                                        }
                                    ]
                                }
                            }
                        }
                    }

                    Column {
                        id: time_date_picker
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: units.gu(2)
                        visible: false

                        /*
                        Button {
                            id: timeButton
                            text: i18n.tr("Změnit čas")
                            property date date: new Date()
                            onClicked: PickerPanel.openDatePicker(timeButton, "date", "Hours|Minutes");
                        }

                        Button {
                            id: dateButton
                            text: i18n.tr("Změnit datum")
                            property date date: new Date()
                            onClicked: PickerPanel.openDatePicker(dateButton, "date", "Years|Months|Days");
                        }
                        */

                        DatePicker {
                            id: timePicker
                            anchors.horizontalCenter: parent.horizontalCenter
                            mode: "Hours|Minutes"
                            date: new Date()
                        }

                        DatePicker {
                            id: datePicker
                            anchors.horizontalCenter: parent.horizontalCenter
                            mode: "Years|Months|Days"
                            date: new Date()
                            minimum: {
                                var d = new Date();
                                d.setDate(d.getDate() - 3);
                                return d;
                            }
                            maximum: {
                                var d = new Date();
                                d.setDate(d.getDate() + 366);
                                return d;
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: "#ddd"
                    }

                    Button {
                        id: search
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: i18n.tr("Hledat")
                        focus: true
                        color: "#3949AB"

                        onClicked: {
                            search_page.search();
                        }

                        state: "DISABLED"

                        states: [
                            State {
                                name: "ENABLED"
                                PropertyChanges { target: search; enabled: true }
                                PropertyChanges { target: search; color: "#3949AB" }
                                PropertyChanges { target: searching_too_long_timer; running: false }
                                PropertyChanges { target: searching_too_long; visible: false }
                            },
                            State {
                                name: "DISABLED"
                                PropertyChanges { target: search; enabled: false }
                                PropertyChanges { target: search; color: UbuntuColors.coolGrey }
                                PropertyChanges { target: searching_too_long_timer; running: false }
                                PropertyChanges { target: searching_too_long; visible: false }
                            },
                            State {
                                name: "ACTIVE"
                                PropertyChanges { target: search; enabled: false }
                                PropertyChanges { target: search; color: UbuntuColors.warmGrey }
                                PropertyChanges { target: searching_too_long_timer; running: true }
                                PropertyChanges { target: searching_too_long; visible: false }
                            }
                        ]

                        function resetState() {
                            if((from.displayText != "" && to.displayText != "") || (from.text != "" && to.text != "")) {
                                state = "ENABLED";
                            }
                            else {
                                state = "DISABLED";
                            }
                        }

                        ActivityIndicator {
                            id: searchActivity
                            anchors.fill: parent
                            running: api.running

                            onRunningChanged: {
                                if(running) {
                                    search.state = "ACTIVE";
                                }
                                else {
                                    search.resetState();
                                }
                            }
                        }

                        Timer {
                            id: searching_too_long_timer
                            interval: 3000
                            running: false
                            repeat: false
                            onTriggered: searching_too_long.visible = true;
                        }
                    }

                    Label {
                        id: searching_too_long
                        width: parent.width
                        text: i18n.tr("Trvá vyhledávání příliš dlouho? Klepnutím na tento text ho můžete zastavit.")
                        color: "#3949AB"
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                        visible: false

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                api.abort();
                                searching_too_long.visible = false;
                            }
                        }
                    }
                }
            }

            Scrollbar {
                flickableItem: search_page_flickable
                align: Qt.AlignTrailing
            }
        }

        Page{
            Transport {
                id: trasport_selector_page
            }
        }

        Page{
            Results {
                id: result_page
            }
        }

        Page{
            ConnectionDetail {
                id: connection_detail
            }
        }

        Page{
            Settings {
                id: settings_page
            }
        }

        Page{
            About {
                id: about_page
            }
        }
    }

    Rectangle {
        id: statusMessageBox
        anchors.fill: parent
        color: "#fff"
        opacity: 0
        visible: opacity == 0 ? false : true

        Column {
            anchors.centerIn: parent
            width: parent.width
            spacing: units.gu(2)

            Image {
                source: "sad.svg"
                anchors.horizontalCenter: parent.horizontalCenter
                width: units.gu(12)
                height: width
                fillMode: Image.PreserveAspectFit
            }

            Label {
                id: statusMessagelabel
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.WordWrap
                font.pixelSize: FontUtils.sizeToPixels("large")
                text: ""
            }
        }

        SequentialAnimation on opacity {
            id: statusAnim
            running: false
            loops: 1
            NumberAnimation { from: 0; to: 1; duration: 1000; easing.type: Easing.InOutQuad }
            PauseAnimation { duration: 5000; }
            NumberAnimation { from: 1; to: 0; duration: 5000; easing.type: Easing.InOutQuad }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                statusAnim.stop();
                parent.opacity = 0;
            }
        }
    }
}

