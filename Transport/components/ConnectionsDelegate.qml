import QtQuick 2.4
import Ubuntu.Components 1.3
import QtQuick.Layouts 1.1

import "../generalfunctions.js" as GeneralFunctions

Component {
    id: connectionsDelegate

    ListItem {
        id: connectionsDelegateItem
        anchors {
            left: parent.left
            right: parent.right
        }
        height: connectionsDelegateItemRectangle.height + 2*connectionsDelegateItemRectangle.anchors.margins
        divider.visible: true

        property var connection: null
        property var detail: null

        function openConnectionDetail() {
            if(connectionsDelegateItem.connection) {
                if(connectionsDelegateItem.detail !== null) {
                    connectionDetailPage.renderDetail(connectionsDelegateItem.detail.getConnectionDetail());
                    pageLayout.addPageToCurrentColumn(connectionsPage, connectionDetailPage);
                    connectionsDelegateItem.state = "complete";
                }
                else if(connectionsDelegateItem.state !== "loading") {
                    connectionsDelegateItem.state = "loading";
                    connectionsDelegateItem.connection.getDetail(function(object, state) {
                        if(state === "SUCCESS") {
                            if(object) {
                                connectionsDelegateItem.detail = object;
                                connectionDetailPage.renderDetail(object.getConnectionDetail());
                                pageLayout.addPageToCurrentColumn(connectionsPage, connectionDetailPage);
                                connectionsDelegateItem.state = "complete";
                            }
                            else {
                                connectionsDelegateItem.state = "empty";
                                errorMessage.value = i18n.tr("Could not load connection detail");
                            }
                        }
                        else if(state !== "ABORT") {
                            connectionsDelegateItem.state = "empty";
                            errorMessage.value = i18n.tr("Could not load connection detail");
                        }
                    });
                }
            }
        }

        states: [
            State {
                name: "empty"
                PropertyChanges { target: itemActivity; running: false }
                PropertyChanges { target: connectionsDelegateItem; color: "transparent" }
            },
            State {
                name: "complete"
                PropertyChanges { target: itemActivity; running: false }
                PropertyChanges { target: connectionsDelegateItem; color: "#eee" }
            },
            State {
                name: "loading"
                PropertyChanges { target: itemActivity; running: true }
                PropertyChanges { target: connectionsDelegateItem; color: "#eee" }
            }
        ]

        state: "empty"

        trailingActions: ListItemActions {
            actions: [
                Action {
                    iconName: "edit-copy"
                    onTriggered: {
                        var clipboardText = "";
                        for(var i = 0; i < routesModel.count; i++) {
                            var route = routesModel.get(i);
                            clipboardText += route.num + " (" + route.type + ")\n";
                            clipboardText += " - " + route.from.name + " " + route.from.time + "\n";
                            clipboardText += " - " + route.to.name + " " + route.to.time + "\n";
                        }
                        Clipboard.push(clipboardText);
                    }
                },
                Action {
                    iconName: "view-expand"
                    onTriggered: {
                        if(progressLine.state !== "running") {
                            connectionsDelegateItem.openConnectionDetail();
                        }
                    }
                },
                Action {
                    iconName: "cancel"
                    visible: connectionsDelegateItem.state === "loading"
                    onTriggered: {
                        connectionsDelegateItem.connection.abort();
                        connectionsDelegateItem.state = "empty";
                    }
                }
            ]
        }

        Rectangle {
            anchors {
                fill: parent
            }
            color: Qt.rgba(255, 255, 255, 0.75)
            z: 1
            visible: itemActivity.running

            ActivityIndicator {
                id: itemActivity
                anchors.centerIn: parent
                running: false
            }
        }

        Rectangle {
            id: connectionsDelegateItemRectangle
            anchors {
                left: parent.left
                right: parent.right
                margins: units.gu(2)
            }
            height: connectionColumn.height + 2*anchors.margins
            color: "transparent"

            Column {
                id: connectionColumn
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                height: connectionRow.height + routesView.height
                spacing: units.gu(2)

                RowLayout {
                    id: connectionRow
                    anchors {
                        left: parent.left
                        right: parent.right
                    }
                    spacing: units.gu(2)

                    Label {
                        id: timeToLabel
                        text: "N/A"
                        font.pixelSize: FontUtils.sizeToPixels("normal")
                        font.bold: true
                        horizontalAlignment: Text.AlignLeft
                        wrapMode: Text.WordWrap

                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignLeft

                        property var departureTime: null
                        property var arrivalTime: null
                    }

                    Label {
                        id: timeLengthLabel
                        text: timeLength
                        font.pixelSize: FontUtils.sizeToPixels("normal")
                        font.bold: false
                        horizontalAlignment: Text.AlignRight
                        wrapMode: Text.WordWrap

                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignRight
                    }
                }

                ListView {
                    id: routesView
                    anchors {
                        left: parent.left
                        right: parent.right
                    }
                    interactive: false
                    height: childrenRect.height
                    delegate: routesDelegate
                    spacing: units.gu(1)

                    model: ListModel {
                        id: routesModel
                    }

                    Component.onCompleted: {
                        connectionsDelegateItem.connection = connectionsModel.childModel[index];
                        var trains = connectionsDelegateItem.connection.trains;
                        if(trains) {
                            for(var i = 0; i < trains.length; i++) {
                                var train = trains[i];
                                var trainData = train.trainData || {};
                                var trainInfo = trainData.info || {};

                                if(i === 0) {
                                    timeToLabel.departureTime = GeneralFunctions.dateStringtoDate(train.dateTime1);
                                }
                                else if(i === trains.length - 1) {
                                    timeToLabel.arrivalTime = GeneralFunctions.dateStringtoDate(train.dateTime2);
                                }

                                var detail = {};
                                detail.num = trainInfo.num1 || "";
                                detail.type = trainInfo.type || "";
                                detail.typeName = trainInfo.typeName || "";
                                detail.typeIndex = trainInfo.id || 0;
                                detail.lineColor = GeneralFunctions.lineColor(detail.num);
                                detail.desc = trainInfo.fixedCodes ? trainInfo.fixedCodes.desc : "";

                                var routes = trainData.route;
                                for(var j = 0; j < routes.length; j++) {
                                    var station = routes[j];
                                    if(j%2 == 0) {
                                        detail.from = {
                                            name: station.station.name,
                                            time: station.depTime,
                                            desc: station.station.fixedCodes ? station.station.fixedCodes.desc : ""
                                        };
                                    }
                                    else {
                                        detail.to = {
                                            name: station.station.name,
                                            time: station.arrTime || station.depTime,
                                            desc: station.station.fixedCodes ? station.station.fixedCodes.desc : ""
                                        };
                                    }
                                }
                                routesModel.append(detail);
                            }
                        }

                        if(connectionsDelegateItem.connection && connectionsDelegateItem.connection.detail !== null) {
                            connectionsDelegateItem.state = "complete";
                        }
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if(progressLine.state !== "running") {
                    connectionsDelegateItem.openConnectionDetail();
                }
            }
        }

        Timer {
            running: parent.visible
            triggeredOnStart: true
            interval: 1000
            repeat: true
            onTriggered: {
                if(timeToLabel.departureTime) {
                    var currentDate = new Date();
                    var departureDate = timeToLabel.departureTime;

                    if(currentDate - 60000 <= departureDate) {
                        var delta = (departureDate - currentDate) / 1000;
                        var days = Math.floor(delta / 3600 / 24);
                        var hours = Math.floor(delta / 3600) % 24;
                        var minutes = Math.floor(delta / 60) % 60;
                        var seconds = Math.floor(delta) % 60;

                        if(days <= 0) {
                            if(hours < 1) {
                                if(minutes <= 0) {
                                    timeToLabel.text = i18n.tr("now");
                                }
                                else {
                                    minutes++;
                                    timeToLabel.text = i18n.tr("in %1 minute", "in %1 minutes", minutes).arg(minutes);
                                }
                            }
                            else {
                                if(hours < 10) {
                                    hours = "0" + hours;
                                }

                                if(minutes < 10) {
                                    minutes = "0" + minutes;
                                }

                                if(seconds < 10) {
                                    seconds = "0" + seconds;
                                }

                                timeToLabel.text = hours + ":" + minutes + ":" + seconds;
                            }
                        }
                        else {
                            timeToLabel.text = i18n.tr("in %1 day", "in %1 days", days).arg(days);
                        }
                        timeToLabel.color = pageLayout.colorPalete["headerBG"];
                    }
                    else {
                        timeToLabel.text = i18n.tr("departed");
                        timeToLabel.color = pageLayout.colorPalete["warningText"];
                        repeat = false;
                    }
                }
            }
        }
    }
}
