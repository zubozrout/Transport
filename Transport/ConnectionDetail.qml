import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.0
import QtQuick.LocalStorage 2.0
import QtQuick.Layouts 1.1

import "engine.js" as Engine
import "localStorage.js" as DB

Page {
    id: connection_detail
    visible: false
    clip: true

    property var detail_array: ({})
    property var current_id: null
    property var console_out: connection_detail_head_sections.selectedIndex == 0 ? console_out_full : console_out_basic
    property var console_out_full: null
    property var console_out_basic: null

    property var detail: null
    property var trains: null
    property var distance: ""
    property var timeLength: ""
    property var price: ""

    property var sections: []

    header: PageHeader {
        id: connection_detail_page_header
        title: i18n.tr("Connection detail")
        flickable: connection_detail_flickable

        leadingActionBar.actions: [
            Action {
                iconName: "back"
                text: "Back"
                onTriggered: pageLayout.removePages(connection_detail)
            }
        ]

        trailingActionBar {
            actions: [
                Action {
                    iconName: "edit-copy"
                    text: i18n.tr("Copy")
                    onTriggered: {
                        Clipboard.push(connection_detail.console_out);
                        detailAnim.start();
                    }
                },
                Action {
                    id: loadMapAction
                    iconSource: "icons/stop_location.svg"
                    text: i18n.tr("Show route on map")
                    visible: enabled
                    onTriggered: {
                        pageLayout.addPageToNextColumn(connection_detail, mapRoutePage);
                        mapRoutePage.renderRoute();
                    }
                }
            ]
        }

        extension: Sections {
            id: connection_detail_head_sections
            anchors {
                left: parent.left
                leftMargin: units.gu(2)
                bottom: parent.bottom
            }
            model: [i18n.tr("All stations"), i18n.tr("Only passed stations")]
            selectedIndex: 0
            property bool selectedIndexOverrwrite: false

            StyleHints {
                sectionColor: UbuntuColors.lightGrey
                selectedSectionColor: "#fff"
            }

            onSelectedIndexChanged: {
                selectedIndexOverrwrite = true;
            }
        }

        StyleHints {
            foregroundColor: "#fff"
            backgroundColor: "#3949AB"
        }
    }

    onVisibleChanged: {
        if(!connection_detail_head_sections.selectedIndexOverrwrite) {
            connection_detail_head_sections.selectedIndex = DB.getSetting("settings_show_all_or_passed") == true ? 0 : 1;
            connection_detail_head_sections.selectedIndexOverrwrite = false;
        }
    }

    function loadConnectionDetail(i, trains, trainDataRoute, model) {
        var p_distance = Engine.parseTrainsAPI(trains[i], "distance");
        var p_timeLength = Engine.parseTrainsAPI(trains[i], "timeLength");
        var start_time = new Date(Engine.parseDate(Engine.parseTrainsAPI(trains[i], "dateTime1")));
        var end_time = new Date(Engine.parseDate(Engine.parseTrainsAPI(trains[i], "dateTime2")));
        var from = Engine.parseTrainsAPI(trains[i], "from");
        var to = Engine.parseTrainsAPI(trains[i], "to");
        var dateIterator = new Date(start_time);

        mapRoutePage.route[i].stations = [];

        for(var j = 0; j < trainDataRoute.length; j++) {
            var departure = Engine.parseTrainDataRouteAPI(trainDataRoute[j], "depTime");
            var arrival = Engine.parseTrainDataRouteAPI(trainDataRoute[j], "arrTime");
            var stationName = Engine.parseTrainDataRouteAPI(trainDataRoute[j], "name");
            var statCoorX = Engine.parseTrainDataRouteAPI(trainDataRoute[j], "statCoorX");
            var statCoorY = Engine.parseTrainDataRouteAPI(trainDataRoute[j], "statCoorY");
            var coorX = Engine.parseTrainDataRouteAPI(trainDataRoute[j], "coorX");
            var coorY = Engine.parseTrainDataRouteAPI(trainDataRoute[j], "coorY");
            var coorModel = [];
            if(coorX && coorY && coorX.length == coorY.length) {
                for(var c = 0; c < coorX.length; c++) {
                    coorModel[c] = {"latitude": coorX[c], "longitude": coorY[c]};
                }
            }

            var active = (from && to) ? (j >= from && j <= to) : from && !to ? j >= from : to && !from ? j <= to : false;
            var stop_time = (departure && arrival) ? arrival + " → " + departure : departure ? departure : arrival;

            var stop_datetime = null;
            if(active) {
                var stopDate = new Date(dateIterator);
                var hour = Number(stop_time.split(" ")[0].split(":")[0]);
                hour = hour == 24 ? 0 : hour;
                var minute = Number(stop_time.split(" ")[0].split(":")[1]);

                stopDate.setHours(hour, minute);
                if(hour < dateIterator.getHours()) {
                    stopDate.setTime(stopDate.getTime() + 86400000);
                }
                dateIterator = stopDate;
                stop_datetime = stopDate;

                connection_detail.console_out_basic += "*\t" + stationName + " (" + stop_time + ")" + "\n";
            }
            connection_detail.console_out_full += (active ? "*\t" : "\t") + stationName + " (" + stop_time + ")" + "\n";

            if(statCoorX && statCoorY) {
                mapRoutePage.route[i].stations.push({"active": active, "station": stationName, "statCoorX": statCoorX, "statCoorY": statCoorY, "route": coorModel});
                loadMapAction.enabled = true;
            }
            else {
                loadMapAction.enabled = false;
            }

            model.append({"stationName":stationName,"stop_time":stop_time,"stop_datetime":stop_datetime,"active":active,"from":from,"to":to});
        }
    }

    function loadConnectionDetailInfo(detail, trains, infomodel) {
        connection_detail.console_out_basic = "";
        connection_detail.console_out_full = "";

        for(var i = 0; i < trains.length; i++) {
            var trainData = Engine.parseTrainsAPI(trains[i], "trainData");
            var trainDataInfo = Engine.parseTrainsAPI(trains[i], "info");
            var trainDataRoute = Engine.parseTrainsAPI(trains[i], "route");
            var num = Engine.parseTrainDataInfoAPI(trainDataInfo, "num1");
            var type = Engine.parseTrainDataInfoAPI(trainDataInfo, "type").toLowerCase();
            var typeName = Engine.parseTrainDataInfoAPI(trainDataInfo, "typeName");
            var typeId = Engine.parseTrainDataInfoAPI(trainDataInfo, "id");
            var typeNameFromId = (type == "ntram") ? "ntram" : ((type == "nbus") ? "nbus" : Engine.transportIdToName(typeId));
            var fixedCodes = Engine.parseTrainDataInfoAPI(trainDataInfo, "fixedCodes");
            var desc = "";
            if(typeof fixedCodes !== typeof undefined) {
                for(var j = 0; j < fixedCodes.length; j++) {
                    desc += fixedCodes[j]["desc"] + "\n";
                }
            }

            var start_stop = Engine.parseTrainDataRouteAPI(trainDataRoute[0], "name");
            var end_stop = Engine.parseTrainDataRouteAPI(trainDataRoute[1], "name");
            var start_time = new Date(Engine.parseDate(Engine.parseTrainsAPI(trains[i], "dateTime1")));
            var end_time = new Date(Engine.parseDate(Engine.parseTrainsAPI(trains[i], "dateTime2")));
            var sameDay = false;
            var start_time_readable = Engine.readableDate(start_time, "datetime");
            var end_time_readable = Engine.readableDate(end_time, "datetime");
            if(start_time.getDate() == end_time.getDate()) {
                sameDay = true;
                start_time_readable = Engine.readableDate(start_time, "time");
                end_time_readable = Engine.readableDate(end_time, "time");
            }
            var lineColor = Engine.parseColor(typeNameFromId, num);

            mapRoutePage.route[i] = {"num": num, "type": typeNameFromId, "lineColor": lineColor, "stations": null};
            infomodel.append({"detail":detail,"start_time":start_time_readable,"end_time":end_time_readable,"num":num,"type":typeNameFromId,"typeName":typeName,"desc":desc,"lineColor":lineColor});
        }
    }

    onCurrent_idChanged: {
        if(current_id != null) {
            connection_trains_detail_info_model.clear();

            detail = (current_id && detail_array[current_id]) ? detail_array[current_id] : null;
            if(detail != null && detail != "") {
                trains = Engine.parseConnectionsAPI(detail, "trains");
                distance = Engine.parseConnectionsAPI(detail, "distance");
                timeLength = Engine.parseConnectionsAPI(detail, "timeLength");
                price = Engine.parseConnectionsAPI(detail, "price");

                loadConnectionDetailInfo(detail, trains, connection_trains_detail_info_model);
            }
            else {
                statusMessagelabel.text = i18n.tr("An error occured while asking for the connection detail. The most probable cause is the expiration of the search results, please try again from scratch.");
                statusMessageBox.visible = true;
                pageLayout.removePages(search_page);
            }
        }
    }

    Component {
        id: trainsDetailInfoDelegate

        Item {
            width: connection_detail_view_column.width
            height: stationColumnList.height

            Column {
                id: stationColumnList
                width: parent.width
                spacing: units.gu(2)

                Rectangle {
                    width: parent.width
                    height: childrenRect.height
                    color: "transparent"

                    Column {
                        width: parent.width; spacing: units.gu(1)
                        Column {
                            width: parent.width; spacing: units.gu(0.25)
                            Row {
                                width: parent.width
                                spacing: units.gu(2)
                                Image { width: units.gu(4); height: width; sourceSize.width: width; fillMode: Image.PreserveAspectFit; source: "icons/" + type + ".svg"; anchors.bottom: parent.bottom; }
                                Text { text: typeName.toUpperCase(); font.pixelSize: FontUtils.sizeToPixels("large"); wrapMode: Text.WordWrap; anchors.verticalCenter: parent.verticalCenter; }
                                Text { text: num; font.bold: true; font.pixelSize: FontUtils.sizeToPixels("x-large"); wrapMode: Text.WordWrap; color: lineColor; anchors.verticalCenter: parent.verticalCenter; }
                            }
                            Text { text: desc; wrapMode: Text.WordWrap; font.italic: true; width: parent.width; }
                        }
                        RowLayout {
                            width: parent.width
                            spacing: units.gu(2)
                            Text { text: i18n.tr("Departure:") + " " + start_time; wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignLeft; Layout.fillWidth: true; }
                            Text { text: i18n.tr("Arrival:") + " " + end_time; wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignRight; Layout.fillWidth: true; }
                        }
                        Rectangle {
                            color: "#ddd"
                            width: connection_detail.width
                            anchors.horizontalCenter: parent.horizontalCenter
                            height: 1
                        }
                    }
                }

                ListView {
                    id: connections_detail_view
                    width: parent.width
                    height: childrenRect.height
                    interactive: false

                    model: ListModel {
                        id: connection_trains_detail_model
                    }
                    delegate: trainsDetailDelegate
                }
            }

            Component.onCompleted: {
                if(index > 0) {
                    connection_detail.console_out_basic += "\n";
                    connection_detail.console_out_full += "\n";
                }
                connection_detail.console_out_basic += "→\t" +  num + " (" + type + ")" + "\n";
                connection_detail.console_out_full += "→\t" +  num + " (" + type + ")" + "\n";

                loadConnectionDetail(index, connection_detail.trains, Engine.parseTrainsAPI(connection_detail.trains[index], "route"), connection_trains_detail_model);
            }
        }
    }

    Component {
        id: trainsDetailDelegate

        Item {
            width: parent.width
            height: stationColumnList.height

            Column {
                id: stationColumnList
                visible: active || connection_detail_head_sections.selectedIndex == 0
                width: parent.width

                Rectangle {
                    width: connection_detail.width
                    height: station_detail_row.implicitHeight * (3/2)
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: index%2 == 1 ? "#eee" : "transparent"
                    visible: parent.visible

                    RowLayout {
                        id: station_detail_row
                        width: stationColumnList.width
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: units.gu(2)

                        Rectangle {
                            id: locator
                            height: parent.height/2
                            width: height
                            radius: height
                            visible: false
                        }

                        Text {
                            text: stationName
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignLeft
                            Layout.fillWidth: true
                            font.bold: active
                        }

                        Text {
                            text: stop_time
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignRight
                            Layout.fillWidth: true
                            font.bold: active
                        }
                    }
                }
            }

            Timer {
                interval: 20000
                running: true
                repeat: true
                triggeredOnStart: true

                onTriggered: {
                    if(active) {
                        locator.visible = true;
                        var current_date = new Date();
                        current_date.setSeconds(0,0);
                        locator.color = stop_datetime <= current_date ? "#333" : "#ddd";
                    }
                    else {
                        locator.visible = false;
                        repeat = false;
                    }
                }
            }
        }
    }

    ActivityIndicator {
        id: detailActivity
        anchors.centerIn: parent
        running: !connection_detail_flickable.visible
    }

    Flickable {
        id: connection_detail_flickable
        anchors.fill: parent
        contentHeight: connection_detail_view_column.childrenRect.height + 2*connection_detail_view_column.anchors.margins
        contentWidth: parent.width
        visible: connection_detail.current_id != null
        clip: true

        Column {
            id: connection_detail_view_column
            anchors {
                fill: parent
                margins: units.gu(2)
            }
            spacing: units.gu(2)

            RowLayout {
                width: parent.width
                spacing: units.gu(2)
                Text { text: distance ? i18n.tr("Distance:") + " " + distance : ""; wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignLeft; verticalAlignment: Text.AlignVCenter; }
                Text { text: timeLength ? i18n.tr("Time total:") + " " + timeLength : ""; wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignLeft; verticalAlignment: Text.AlignVCenter; }
                Text { text: price ? i18n.tr("Price:") + " " + price : ""; wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignRight; verticalAlignment: Text.AlignVCenter; Layout.fillWidth: true; }
            }

            Rectangle {
                color: "#ddd"
                width: connection_detail.width
                anchors.horizontalCenter: parent.horizontalCenter
                height: 1
            }

            Repeater {
                id: connections_detail_info_view
                width: parent.width
                height: childrenRect.height

                model: ListModel {
                    id: connection_trains_detail_info_model
                }
                delegate: trainsDetailInfoDelegate
            }
        }
    }

    Scrollbar {
        flickableItem: connection_detail_flickable
        align: Qt.AlignTrailing
    }

    Rectangle {
        id: connectionDetailCoppiedConfirmation
        anchors.fill: parent
        color: "#fff"
        opacity: 0
        visible: opacity == 0 ? false : true

        Icon {
            anchors.centerIn: parent
            width: parent.width > parent.height ? parent.height/2 : parent.width/2
            height: width
            name: "ok"
            color: UbuntuColors.green
        }

        SequentialAnimation on opacity {
            id: detailAnim
            running: false
            loops: 1
            NumberAnimation { from: 0; to: 1; duration: 1000; easing.type: Easing.InOutQuad }
            PauseAnimation { duration: 2000; }
            NumberAnimation { from: 1; to: 0; duration: 5000; easing.type: Easing.InOutQuad }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                detailAnim.stop();
                parent.opacity = 0;
            }
        }
    }
}
