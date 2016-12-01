import QtQuick 2.4
import Ubuntu.Components 1.3
import QtQuick.Layouts 1.1

import "../generalfunctions.js" as GeneralFunctions

Component {
    id: connectionDetailDelegate

    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
        }
        height: 2*routeColumn.spacing + transportRow.height + routeHeader.height + connectionDetailRoutesView.contentHeight
        color: "transparent"

        ConnectionDetailRoutesDelegate {
            id: connectionDetailRoutesDelegate
        }

        ColumnLayout {
            id: routeColumn
            anchors {
                left: parent.left
                right: parent.right
            }
            spacing: units.gu(2)

            RowLayout {
                id: transportRow
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: units.gu(2)
                }
                spacing: units.gu(1)

                Image {
                    id: transportIcon
                    width: units.gu(3)
                    height: width
                    fillMode: Image.PreserveAspectFit
                    horizontalAlignment: Image.AlignHCenter
                    verticalAlignment: Image.AlignVCenter
                    sourceSize.width: width
                    sourceSize.height: height
                    source: trainInfo.id ? "../icons/" + GeneralFunctions.getTranpsortType(trainInfo.id) + ".svg" : "../icons/empty.svg"

                    Layout.fillWidth: false
                    Layout.fillHeight: true
                }

                Label {
                    text: trainInfo.num || ""
                    font.pixelSize: FontUtils.sizeToPixels("large")
                    font.bold: true
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.WordWrap

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }

            Row {
                id: routeHeader
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: units.gu(2)
                }

                Label {
                    text: i18n.tr("Station name")
                    width: parent.width/2
                    horizontalAlignment: Text.AlignLeft
                    wrapMode: Text.WordWrap
                }

                Label {
                    text: i18n.tr("Departure")
                    width: parent.width/4
                    horizontalAlignment: Text.AlignLeft
                    wrapMode: Text.WordWrap
                }

                Label {
                    text: i18n.tr("Arrival")
                    width: parent.width/4
                    horizontalAlignment: Text.AlignLeft
                    wrapMode: Text.WordWrap
                }
            }

            ListView {
                id: connectionDetailRoutesView
                anchors {
                    left: parent.left
                    right: parent.right
                }
                implicitHeight: contentHeight
                interactive: false
                delegate: connectionDetailRoutesDelegate

                model: ListModel {
                    id: connectionDetailRoutesModel
                }

                Component.onCompleted: {
                    var stops = connectionDetailModel.childModel[index];
                    //distInfoLabel.text = stops.dist ? (stops.dist + " " + i18n.tr("km")) : "";
                    if(stops) {
                        for(var i = 0; i < stops.length; i++) {
                            connectionDetailRoutesModel.append(stops[i]);
                        }
                    }
                }
            }
        }
    }
}
