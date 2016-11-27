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
            topMargin: units.gu(1)
            bottomMargin: units.gu(1)
        }
        height: childrenRect.height
        color: "transparent"

        RowLayout {
            id: routeRow
            anchors {
                left: parent.left
                right: parent.right
            }
            spacing: units.gu(2)

            ColumnLayout {
                Layout.fillWidth: false
                Layout.fillHeight: true
                Layout.minimumWidth: units.gu(4)
                Layout.preferredWidth: units.gu(4)
                spacing: units.gu(0.05)

                Image {
                    width: parent.width
                    height: width
                    fillMode: Image.PreserveAspectFit
                    horizontalAlignment: Image.AlignHCenter
                    verticalAlignment: Image.AlignVCenter
                    sourceSize.width: width
                    sourceSize.height: height
                    source: type ? "../icons/" + GeneralFunctions.getTranpsortType(typeIndex) + ".svg" : "../icons/empty.svg"

                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignCenter
                }

                Label {
                    text: num
                    font.pixelSize: FontUtils.sizeToPixels("large")
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap

                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignCenter
                }
            }

            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 2

                Label {
                    text: from.name || ""
                    font.pixelSize: FontUtils.sizeToPixels("normal")
                    font.bold: false
                    wrapMode: Text.WordWrap

                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignLeft
                }

                Label {
                    text: from.time || ""
                    font.pixelSize: FontUtils.sizeToPixels("normal")
                    font.bold: false
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignRight

                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignLeft
                }

                Label {
                    text: to.name || ""
                    font.pixelSize: FontUtils.sizeToPixels("normal")
                    font.bold: false
                    wrapMode: Text.WordWrap

                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignLeft
                }

                Label {
                    text: to.time || ""
                    font.pixelSize: FontUtils.sizeToPixels("normal")
                    font.bold: false
                    horizontalAlignment: Text.AlignRight
                    wrapMode: Text.WordWrap

                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignRight
                }
            }
        }
    }
}
