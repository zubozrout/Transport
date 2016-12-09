import QtQuick 2.4
import Ubuntu.Components 1.3
import QtQuick.Layouts 1.1

Item {
    id: errorMessage
    anchors {
        left: parent.left
        right: parent.right
    }

    property var value: ""
    property var iconPath: ""
    property var visibilityTime: 10000

    height: value ? errorRectangle.height : 0
    clip: true

    onValueChanged: {
        if(value && visibilityTime && visibilityTime > 1000) {
            errorVisibleTimer.start();
        }
    }

    Rectangle {
        id: errorRectangle
        anchors {
            left: parent.left
            right: parent.right
        }
        height: errorRow.height + 2*errorRow.anchors.margins + errorLineSeparator.height
        color: pageLayout.baseColor

        RowLayout {
            id: errorRow
            anchors {
                left: parent.left
                right: parent.right
                margins: units.gu(2)
                verticalCenter: parent.verticalCenter
            }
            spacing: units.gu(2)

            Icon {
                source: errorMessage.iconPath || "../images/error.svg"
                width: units.gu(3)
                height: width

                Layout.fillWidth: false
            }

            Label {
                text: errorMessage.value || ""
                color: pageLayout.highlightedTextColor
                font.pixelSize: FontUtils.sizeToPixels("normal")
                font.bold: false
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap

                Layout.fillWidth: true
            }
        }

        Rectangle {
            id: errorLineSeparator
            anchors {
                left: parent.left
                right: parent.right
                bottom: errorRectangle.bottom
            }
            height: 1
            color: pageLayout.colorPalete["secondaryBG"] || "#333"
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                errorMessage.value = "";
            }
        }

        Timer {
            id: errorVisibleTimer
            interval: errorMessage.visibilityTime || 1000
            repeat: false
            onTriggered: {
                errorMessage.value = "";
            }
        }
    }
}
