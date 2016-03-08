import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.0
import QtQuick.LocalStorage 2.0
import QtQuick.Layouts 1.1

import "engine.js" as Engine
import "localStorage.js" as DB

Page {
    id: connection_detail
    title: i18n.tr("Detail spojení")
    visible: false
    clip: true
    head.locked: true

    property var detail_array: ({})
    property var current_id: null
    property var console_out: null

    property var detail: null
    property var trains: null
    property var distance: ""
    property var timeLength: ""
    property var price: ""

    property var sections: []

    head.actions: [
        Action {
            iconName: "edit-copy"
            text: i18n.tr("Kopírovat")
            onTriggered: {
                Clipboard.push(connection_detail.console_out);
                detailAnim.start();
            }
        }
    ]

    head {
        sections {
            model: [i18n.tr("Všechny zastávky"), i18n.tr("Jen projížděné zastávky")]
            selectedIndex: DB.getSetting("settings_show_all_or_passed") == true ? 0 : 1;
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

        for(var j = 0; j < trainDataRoute.length; j++) {
            var departure = Engine.parseTrainDataRouteAPI(trainDataRoute[j], "depTime");
            var arrival = Engine.parseTrainDataRouteAPI(trainDataRoute[j], "arrTime");
            var stationName = Engine.parseTrainDataRouteAPI(trainDataRoute[j], "name");

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
            }

            model.append({"stationName":stationName,"stop_time":stop_time,"stop_datetime":stop_datetime,"active":active,"from":from,"to":to});
            connection_detail.console_out += (active ? "*\t" : "\t") + stationName + "(" + stop_time + ")" + "\n";
        }
    }

    function loadConnectionDetailInfo(detail, trains, infomodel) {
        connection_detail.console_out = "";
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
                statusMessagelabel.text = i18n.tr("Detail spojení nebylo možné načíst.\nNejčastější příčinou je vypršení platnosti identifikátoru. Zkuste prosím vyhledat dané spojení znova.");
                statusAnim.start();
                pageLayout.removePages(connection_detail);
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
                            Text { text: i18n.tr("Odjezd:") + " " + start_time; wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignLeft; Layout.fillWidth: true; }
                            Text { text: i18n.tr("Příjezd:") + " " + end_time; wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignRight; Layout.fillWidth: true; }
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
                connection_detail.console_out += "→\t" +  type + "(" + num + ")" + "\n";
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
                visible: active || connection_detail.head.sections.selectedIndex == 0
                width: parent.width
                height: !visible ? 0 : childrenRect.height

                Rectangle {
                    width: connection_detail.width
                    height: (3/2)*station_detail_row.height
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: index%2 == 1 ? "#eee" : "transparent"

                    RowLayout {
                        id: station_detail_row
                        width: stationColumnList.width
                        height: childrenRect.height
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: units.gu(2)
                        Rectangle { id: locator; height: parent.height/2; width: height; radius: height; visible: false; }
                        Text { text: stationName; wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignLeft; Layout.fillWidth: true; font.bold: active }
                        Text { text: stop_time; wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignRight; Layout.fillWidth: true; font.bold: active }
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
                Text { text: distance ? i18n.tr("Vzdálenost") + ": " + distance : ""; wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignLeft; verticalAlignment: Text.AlignVCenter; }
                Text { text: timeLength ? i18n.tr("Celkový čas") + ": " + timeLength : ""; wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignLeft; verticalAlignment: Text.AlignVCenter; }
                Text { text: price ? i18n.tr("Cena") + ": " + price : ""; wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignRight; verticalAlignment: Text.AlignVCenter; Layout.fillWidth: true; }
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
        id: settingsSaveStatus
        anchors.fill: parent
        color: "#fff"
        opacity: 0
        visible: opacity == 0 ? false : true

        Icon {
            anchors.centerIn: parent
            width: parent.width > parent.height ? parent.height : parent.width
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
