import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Pickers 1.3
import QtQuick.Layouts 1.1
import QtQuick.LocalStorage 2.0
import Ubuntu.Connectivity 1.0
import QtPositioning 5.2

import Transport 1.0

import "engine.js" as Engine
import "localStorage.js" as DB

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

    property var db: null
    property var handle: null
    property var first_id: null
    property var last_id: null

    // Common functions:
    function saveStationToDb(textfield) {
        if(textfield.text && textfield.coorX && textfield.coorY) {
            var hasTransportStop = DB.hasTransportStop(transport_selector_page.selectedItem);
            var id = DB.appendNewStop(transport_selector_page.selectedItem, textfield.text, {x: textfield.coorX, y: textfield.coorY});
            if(!hasTransportStop) {
                transport_selector_page.update();
            }
            return id;
        }
        else {
            var nameMatch = DB.getStopByName({"id": transport_selector_page.selectedItem, "name": textfield.text});
            if(nameMatch) {
                return nameMatch.id;
            }
        }
        return null;
    }

    function saveSearchCombination(transport, fromID, toID, viaID) {
        DB.appendSearchToHistory({
            "typeid": transport,
             "stopidfrom": fromID ? fromID : "",
             "stopidto": toID ? toID : "",
             "stopidvia": viaID ? viaID : ""
        });
    }

    function checkClear(textfield, listview, model) {
        if(!model) {
            model = textfield.stationInputModel;
        }

        if(listview.currentIndex >= 0 && typeof model.get(listview.currentIndex) !== typeof undefined && model.get(listview.currentIndex).name == textfield.displayText) {
            api.abort();
            listview.lastSelected = model.get(listview.currentIndex).name;
            model.clear();
        }
    }

    function stationInputChanged(textfield, listview, model) {
        search.resetState();
        api.abort();
        if(textfield.focus && textfield.displayText != listview.lastSelected) {
            if(!model) {
                model = textfield.stationInputModel;
            }
            Engine.complete(transport_selector_page.selectedItem, textfield.displayText, model);
            checkClear(textfield, listview, model);
        }
    }

    Connections {
        target: Connectivity

        onOnlineChanged: {
            connectivityStatus(true);
        }

        Component.onCompleted: {
            connectivityStatus(false);
        }

        function connectivityStatus(abort) {
            if(!Connectivity.online){
                if(abort) {
                    api.abort();
                }
                offlineMessageBox.state = "OFFLINE";
            }
            else {
                offlineMessageBox.state = "ONLINE";
            }
        }
    }

    Api {
        id: api
        property var callback: null

        onResponseChanged: {
            if(callback && response) {
                callback(response);
            }
            else if(offlineMessageBox.state == "ONLINE" && callback && !response) {
                statusMessagelabel.text = i18n.tr("Server is not responding. Please try again later.");
                statusMessageErrorlabel.text = i18n.tr("There was no server response received.");
                statusMessageBox.visible = true;
            }
            callback = null;
        }

        function abort() {
            if(running && callback) {
                callback = null;
                request = "";
            }
        }
    }

    PositionSource {
        id: positionSource
        updateInterval: 1000
        active: true

        property bool firstSuccessfullRun: false

        function isValid() {
            if(valid && !isNaN(positionSource.position.coordinate.latitude) && !isNaN(positionSource.position.coordinate.longitude)) {
                return true;
            }
            return false;
        }

        function searchForTheNearestStop() {
            if(isValid()) {
                firstSuccessfullRun = Engine.setGeoPositionMatch(positionSource.position.coordinate, transport_selector_page.selectedItem, from, to, via);
            }
        }

        onPositionChanged: {
            if(!firstSuccessfullRun) {
                searchForTheNearestStop();
            }
        }
    }

    Rectangle {
        id: offlineMessageBox
        width: parent.width
        anchors.bottom: parent.bottom
        color: UbuntuColors.red

        state: "ONLINE"

        states: [
            State {
                name: "ONLINE"
                PropertyChanges { target: offlineMessageBox; height: 0}
                PropertyChanges { target: offlineMessageBox; visible: false}
            },
            State {
                name: "OFFLINE"
                PropertyChanges { target: offlineMessageBox; height: offlineMessageBoxText.contentHeight * 2}
                PropertyChanges { target: offlineMessageBox; visible: true}
            }
        ]

        Label {
            id: offlineMessageBoxText
            width: parent.width
            anchors.centerIn: parent
            color: "#fff"
            wrapMode: Text.WordWrap
            text: i18n.tr("You're now offline")
            font.pixelSize: FontUtils.sizeToPixels("normal")
            horizontalAlignment: Text.AlignHCenter
        }
    }

    AdaptivePageLayout {
        id: pageLayout
        anchors {
            top: parent.top
            right: parent.right
            left: parent.left
            bottom: offlineMessageBox.top
        }

        primaryPage: search_page

        layouts: PageColumnsLayout {
            when: width > units.gu(80)
            PageColumn {
                fillWidth: true
                minimumWidth: units.gu(25)
                maximumWidth: units.gu(70)
                preferredWidth: units.gu(40)
            }
            PageColumn {
                fillWidth: true
                minimumWidth: units.gu(45)
            }
        }

        Page {
            id: search_page
            visible: false
            clip: true

            header: PageHeader {
                id: search_page_header
                title: i18n.tr("Transport")
                flickable: search_page_flickable

                leadingActionBar.actions: [
                    Action {
                        iconName: "go-to"
                        text: i18n.tr("Connection results")
                        enabled: Object.keys(result_page.response).length > 0 ? !result_page.visible : false
                        visible: enabled
                        onTriggered: pageLayout.addPageToNextColumn(search_page, result_page)
                    }
                ]

                trailingActionBar {
                    actions: [
                        Action {
                            iconName: "gps"
                            text: i18n.tr("Find nearest stop")
                            visible: enabled
                            onTriggered: positionSource.searchForTheNearestStop();
                        },
                        Action {
                            iconName: "go-to"
                            text: i18n.tr("Connection results")
                            enabled: Object.keys(result_page.response).length > 0 ? !result_page.visible : false
                            visible: enabled
                            onTriggered: pageLayout.addPageToNextColumn(search_page, result_page)
                        },
                        Action {
                            iconSource: "icons/stop.svg"
                            iconName: "event"
                            text: i18n.tr("Station departures")
                            onTriggered: pageLayout.addPageToNextColumn(search_page, departures_page)
                        },
                        Action {
                            iconSource: "icons/stop_location.svg"
                            text: i18n.tr("Station locator")
                            visible: enabled
                            onTriggered: pageLayout.addPageToNextColumn(search_page, mapPage)
                        },
                        Action {
                            iconName: "settings"
                            text: i18n.tr("Settings")
                            onTriggered: pageLayout.addPageToNextColumn(search_page, settings_page)
                        },
                        Action {
                            iconName: "help"
                            text: i18n.tr("About")
                            onTriggered: pageLayout.addPageToNextColumn(search_page, about_page)
                        }
                    ]
                    numberOfSlots: 2
                }

                StyleHints {
                    foregroundColor: "#fff"
                    backgroundColor: "#3949AB"
                }
            }

            function search(state) {
                if(!from.displayText || !to.displayText) {
                    return;
                }
                api.abort();

                var count = Number(DB.getSetting("settings_transport_count"));
                count = count || count <= 0 ? count : 10;
                var options = transport_selector_page.selectedItem;

                if(typeof state !== typeof undefined) {
                    switch(state) {
                        case "previous":
                            if(first_id != null) {
                                Engine.getConnectionsFB(options, handle, first_id, count, true, Engine.showConnectionsFB);
                            }
                            return;
                        case "next":
                            if(last_id != null) {
                                Engine.getConnectionsFB(options, handle, last_id, count, false, Engine.showConnectionsFB);
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
                var allowChange_final = advanced_switch.checked ? !direct_checkbox.checked : true;
                Engine.getConnections(options, date_time, departure_final, from.displayText, to.displayText, via_final, allowChange_final, count, Engine.showConnections);

                // DB save selected values:
                DB.saveSetting("fromObj" + options, JSON.stringify({"name": from.displayText, "x": from.coorX, "y": from.coorY}));
                DB.saveSetting("toObj" + options, JSON.stringify({"name": to.displayText, "x": to.coorX, "y": to.coorY}));
                var fromID = saveStationToDb(from);
                var toID = saveStationToDb(to);
                if(advanced_switch.checked) {
                    DB.saveSetting("viaObj" + options, JSON.stringify({"name": via.displayText, "x": via.coorX, "y": via.coorY}));
                    var viaID = saveStationToDb(via);
                    saveSearchCombination(options, fromID, toID, viaID);
                }
                else {
                    DB.saveSetting("viaObj" + options, "");
                    saveSearchCombination(options, fromID, toID, null);
                }
                DB.saveSetting("optionsList", transport_selector_page.selectedItem);
            }

            Flickable {
                id: search_page_flickable
                anchors.fill: parent
                contentHeight: search_column.implicitHeight + 2 * search_column.anchors.margins
                contentWidth: parent.width
                clip: true

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
                            text: transport_selector_page.selectedName ? transport_selector_page.selectedName : i18n.tr("No transport option selected")
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

                            onClicked: pageLayout.addPageToNextColumn(search_page, transport_selector_page);
                        }
                    }

                    Rectangle {
                        color: "#ddd"
                        width: parent.width
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: 1
                    }

                    Column {
                        id: startEndStationsColumn
                        width: parent.width
                        height: childrenRect.height
                        spacing: 0

                        StationQuery {
                            id: from
                            property string placeholder: i18n.tr("From")
                        }

                        Button {
                            width: units.gu(4)
                            anchors.horizontalCenter: parent.horizontalCenter
                            iconName: "swap"
                            color: "transparent"
                            onClicked: {
                                var tmp_text = from.displayText;
                                from.text = to.displayText;
                                to.text = tmp_text;
                            }
                        }

                        StationQuery {
                            id: to
                            property string placeholder: i18n.tr("To")
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
                            text: i18n.tr("Advanced options")
                            anchors.verticalCenter: parent.verticalCenter
                            wrapMode: Text.WordWrap
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

                        StationQuery {
                            id: via
                            property string placeholder: i18n.tr("Via")
                        }

                        Row {
                            spacing: units.gu(2)
                            anchors.horizontalCenter: parent.horizontalCenter

                            Label {
                                id: direct_label
                                text: i18n.tr("Only direct connections")
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            CheckBox {
                                id: direct_checkbox
                                checked: false
                                anchors.verticalCenter: parent.verticalCenter
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
                                            PropertyChanges { target: nowLabel; text: i18n.tr("Now") }
                                        },
                                        State {
                                            name: "CUSTOM"
                                            PropertyChanges {
                                                target: nowLabel
                                                text: {
                                                    var hours = timePicker.date.getHours();
                                                    var minutes = timePicker.date.getMinutes();
                                                    if(parseInt(minutes) < 10) {
                                                        minutes = "0" + minutes;
                                                    }
                                                    var date = datePicker.date.getDate();
                                                    var month = datePicker.date.getMonth() + 1;
                                                    var year = datePicker.date.getFullYear();

                                                    var begginingStarting = departure_label.state == "DEPARTURE" ? i18n.tr("Departure at") : i18n.tr("Arrival at");
                                                    return begginingStarting + " " + hours + ":" + minutes + ", " + date + "." + month + "." + year;
                                                }
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
                                            PropertyChanges { target: departure_label; text: i18n.tr("Departure") }
                                        },
                                        State {
                                            name: "ARRIVAL"
                                            PropertyChanges { target: departure_label; text: i18n.tr("Arrival") }
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
                            Component.onCompleted: {
                                if(DB.getSetting("settings_ignore_transport_expire_dates")) {
                                    setDefaults();
                                }
                            }

                            function setDefaults() {
                                var di = new Date();
                                di.setDate(di.getDate() - 3);
                                minimum = di;

                                var da = new Date();
                                da.setDate(da.getDate() + 366);
                                maximum = da;
                            }

                            function setTransportDates() {
                                minimum = transport_selector_page.minimumDate;
                                maximum = transport_selector_page.maximumDate;
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
                        text: i18n.tr("Search")
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
                            if(from.displayText != "" && to.displayText != "") {
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
                        text: i18n.tr("Does the search take too long? You can stop it by clicking here.")
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

            RecentBottomEdge {
                id: bottomEdge
            }
        }

        Page{
            Transport {
                id: transport_selector_page
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
            Departures {
                id: departures_page
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

        Page{
            Map {
                id: mapPage
            }
        }

        Page{
            MapRoute {
                id: mapRoutePage
            }
        }
    }

    Rectangle {
        id: statusMessageBox
        anchors.fill: parent
        color: "#fff"
        opacity: 0
        visible: false

        onVisibleChanged: {
            if(visible) {
                statusAnim.start();
            }
            else {
                opacity = 0;
            }
        }

        SequentialAnimation on opacity {
            id: statusAnim
            running: false
            loops: 1
            NumberAnimation { from: 0; to: 1; duration: 1000; easing.type: Easing.InOutQuad }
        }

        Flickable {
            anchors.fill: parent
            anchors.margins: units.gu(2)
            contentWidth: width
            contentHeight: statusMessageColumn.height
            clip: true

            Column {
                id: statusMessageColumn
                width: parent.width
                height: childrenRect.height
                spacing: units.gu(2)

                Button {
                    iconName: "close"
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: "transparent"
                    onClicked: {
                        statusMessageBox.visible = false;
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: "#ddd"
                }

                Image {
                    source: "error.svg"
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: units.gu(12)
                    height: width
                    sourceSize.width: width
                    sourceSize.height: height
                    fillMode: Image.PreserveAspectFit
                }

                Label {
                    id: statusMessagelabel
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    font.pixelSize: FontUtils.sizeToPixels("large")
                    text: ""
                }

                Label {
                    id: statusMessageErrorlabel
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.WordWrap
                    font.pixelSize: FontUtils.sizeToPixels("small")
                    text: ""
                }

                Button {
                    iconName: "edit-copy"
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: "transparent"
                    onClicked: {
                        Clipboard.push(statusMessageErrorlabel.text);
                        statusMessageBox.visible = false;
                    }
                    visible: /^\s+$/.test(statusMessageErrorlabel.text) ? false : true
                }
            }
        }
    }
}

