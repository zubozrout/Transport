import QtQuick 2.4
import Ubuntu.Components 1.3
import QtQuick.Layouts 1.1
import QtQuick.LocalStorage 2.0

import "engine.js" as Engine
import "localStorage.js" as DB

Page {
    id: result_page  
    visible: false
    clip: true

    property var response: []

    header: PageHeader {
        id: result_page_header
        title: i18n.tr("Connection results")

        trailingActionBar {
            actions: [
                Action {
                    iconName: "go-next"
                    text: i18n.tr("Next")
                    onTriggered: search_page.search("next");
                },
                Action {
                    iconName: "go-previous"
                    text: i18n.tr("Previous")
                    onTriggered: search_page.search("previous");
                }
            ]
        }

        StyleHints {
            foregroundColor: "#fff"
            backgroundColor: "#3949AB"
        }
    }

    function clear() {
        response = [];
        connections_list_model.clear();
    }

    function render(connections) {
        for(var i = 0; i < connections.length; i++) {
            var id = Engine.parseConnectionsAPI(connections[i], "id");
            if(i == 0) {
                first_id = id;
            }
            if(i == connections.length - 1) {
                last_id = id;
            }
            connections_list_model.append( {"connection_id": id} );
        }
        connections_list_view.positionViewAtBeginning();
    }

    ActivityIndicator {
        id: resultsActivity
        anchors.centerIn: parent
        running: api.running
        z: 10
    }

    Component {
        id: connection_child_delegate
        Item {
            width: parent.width
            height: childrenRect.height

            Column {
                id: connection_child_detail_column_wrapper
                height: childrenRect.height
                width: parent.width

                RowLayout { width: parent.width; spacing: units.gu(2);
                    Column {
                        Image { anchors.horizontalCenter: parent.horizontalCenter; width: units.gu(4); height: width; sourceSize.width: width; fillMode: Image.PreserveAspectFit; source: vehicle_icon; }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: line_number; font.bold: true; color: line_color; font.pixelSize: FontUtils.sizeToPixels("large"); }
                    }

                    GridLayout { Layout.fillWidth: true; columns: 2;
                        Text { text: start_stop; wrapMode: Text.WordWrap; }
                        Text { text: start_time; horizontalAlignment: Text.AlignRight; Layout.fillWidth: true; }
                        Text { text: end_stop; wrapMode: Text.WordWrap; }
                        Text { text: end_time; horizontalAlignment: Text.AlignRight; Layout.fillWidth: true; }
                    }
                }
            }
        }
    }

    Component {
        id: connectionsDelegate

        ListItem {
            width: parent.width
            height: connection_padding.height + 2*connection_padding.anchors.margins
            anchors.horizontalCenter: parent.horizontalCenter
            divider.visible: true

            trailingActions: ListItemActions {
                actions: [
                    Action {
                        iconName: "edit-copy"
                        onTriggered: Clipboard.push(connection_info.text_output)
                    },
                    Action {
                        iconName: "view-expand"
                        onTriggered: {
                            connection_detail.current_id = null;
                            var options = trasport_selector_page.selectedItem;
                            Engine.connectionDetail(options, connection_id, function(response, id){connection_box.color = "#fafaef"; return Engine.showConnectionDetail(response, id);});
                        }
                    }
                ]
            }

            Rectangle {
                id: connection_box
                width: parent.width
                height: parent.height
                color: connection_detail.detail_array[handle + connection_id] ? "#fafaef" : "#fff"

                Rectangle {
                    id: connection_padding
                    anchors {
                        left: parent.left
                        right: parent.right
                        margins: units.gu(2)
                        verticalCenter: parent.verticalCenter
                    }
                    height: childrenRect.height
                    color: "transparent"

                    Column {
                        id: connection_info
                        width: parent.width
                        height: childrenRect.height
                        spacing: units.gu(1)

                        property var text_output: ""
                        property var text_desc: ""

                        property var connection: Engine.parseAPI(result_page.response, "connections")[index]
                        property var trains: Engine.parseConnectionsAPI(connection, "trains")
                        property var routeStart: new Date(Engine.parseDate(Engine.parseTrainsAPI(trains[0], "dateTime1")))
                        property var routeEnd: new Date(Engine.parseDate(Engine.parseTrainsAPI(trains[trains.length-1], "dateTime2")))
                        property var routeLength: Engine.parseConnectionsAPI(connection, "timeLength")
                        property var routeDistance: Engine.parseConnectionsAPI(connection, "distance")

                        Grid {
                            columns: 2
                            width: parent.width
                            height: childrenRect.height

                            Text {
                                id: time_in
                                width: parent.width - time_length.contentWidth
                                text: remaining
                                property var remaining: 0
                                property var routeStart: connection_info.routeStart
                            }

                            Text {
                                id: time_length
                                text: connection_info.routeLength + (typeof connection_info.routeDistance !== typeof undefined ? ", " + connection_info.routeDistance : "")
                                color: "#666"
                            }

                            onWidthChanged: {
                                if(time_length.contentWidth + time_in.contentWidth > width) {
                                    columns = 1;
                                }
                                else {
                                    columns = 2;
                                }
                            }
                        }

                        Column {
                            id: connection_info_col
                            spacing: units.gu(2)
                            width: parent.width
                            height: childrenRect.height

                            property var tmp_route_objects: []

                            Component.onDestruction: {
                                for(var i = children.length; i > 0 ; i--) {
                                    children[i-1].destroy();
                                }
                                tmp_route_objects = [];
                            }

                            ListView {
                                id: connection_list_view_child
                                width: parent.width
                                height: childrenRect.height

                                spacing: units.gu(2)

                                model: ListModel {
                                    id: connection_list_model_child
                                }

                                delegate: connection_child_delegate
                            }
                        }

                        Component.onCompleted: {
                            if(Object.keys(result_page.response).length <= 0) {
                                return;
                            }

                            for(var i = 0; i < connection_info.trains.length; i++) {
                                var trainData = Engine.parseTrainsAPI(connection_info.trains[i], "trainData");
                                var trainDataInfo = Engine.parseTrainsAPI(connection_info.trains[i], "info");
                                var trainDataRoute = Engine.parseTrainsAPI(connection_info.trains[i], "route");
                                var num = Engine.parseTrainDataInfoAPI(trainDataInfo, "num1");
                                var type = Engine.parseTrainDataInfoAPI(trainDataInfo, "type").toLowerCase();
                                var typeName = Engine.parseTrainDataInfoAPI(trainDataInfo, "typeName");
                                var typeId = Engine.parseTrainDataInfoAPI(trainDataInfo, "id");
                                var typeNameFromId = (type == "ntram") ? "ntram" : ((type == "nbus") ? "nbus" : Engine.transportIdToName(typeId));
                                var line_color = Engine.parseColor(typeNameFromId, num);

                                var start_stop = Engine.parseTrainDataRouteAPI(trainDataRoute[0], "name");
                                var end_stop = Engine.parseTrainDataRouteAPI(trainDataRoute[1], "name");
                                var start_time = Engine.parseTrainsAPI(connection_info.trains[i], "dateTime1");
                                var end_time = Engine.parseTrainsAPI(connection_info.trains[i], "dateTime2");
                                var start_time_date = new Date(Engine.parseDate(start_time));
                                var end_time_date = new Date(Engine.parseDate(end_time));
                                var sameDay = false;
                                if(start_time_date.getDate() == end_time_date.getDate()) {
                                    sameDay = true;
                                    start_time = start_time.split(" ").pop();
                                    end_time = end_time.split(" ").pop();
                                }

                                connection_list_model_child.append({"start_stop":start_stop,"end_stop":end_stop,"start_time":start_time,"end_time":end_time,"line_number":num,"line_type":type,"line_color":line_color,"vehicle_icon":"icons/" + typeNameFromId + ".svg"});

                                // Text output
                                connection_info.text_output += "* " + num + " (" + typeName + ")\n";
                                connection_info.text_output += "\t→ " + start_stop + " (" + start_time + ")\n";
                                connection_info.text_output += "\t← " + end_stop + " (" + end_time + ")";
                                connection_info.text_output += (i != connection_info.trains.length - 1) ? "\n" : "";
                                connection_info.text_desc += start_stop + " → " + end_stop + "\n";
                            }
                        }
                    }

                    DepartureTimer {
                        property alias routeStart: connection_info.routeStart
                        property alias routeEnd: connection_info.routeEnd
                        property alias startTime: time_in.routeStart
                        property alias remainingTime: time_in.remaining
                        property alias timeColor: time_in.color
                    }
                }

                MouseArea {
                    anchors.fill: parent

                    onClicked: {
                        connection_detail.current_id = null;
                        var options = trasport_selector_page.selectedItem;
                        Engine.connectionDetail(options, connection_id, function(response, id){connection_box.color = "#fafaef"; return Engine.showConnectionDetail(response, id);});
                    }
                }
            }
        }
    }

    ListView {
        id: connections_list_view
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.top: result_page_header.bottom

        model: ListModel {
            id: connections_list_model
        }
        delegate: connectionsDelegate

        Scrollbar {
            flickableItem: connections_list_view
            align: Qt.AlignTrailing
        }
    }
}
