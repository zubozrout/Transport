import QtQuick 2.4
import Ubuntu.Components 1.3

Rectangle {
    id: rectangleButton
    width: parent.width
    height: 40
    color: rectangleButton.enabled ? (active ? "#333" : "#ddd") : "#eee"

    property bool active: false
    property bool enabled: false
    property string text: ""
    property var textColor: "#333"
    property var callback: null

    property var horizontalMargins: units.gu(3)

    function updateSizes() {
        var buttonWidthWithPadding = buttonText.contentWidth + 2 * horizontalMargins;
        var buttonHeightWithPadding = 2 * buttonText.contentHeight;
        width = parent.width > buttonWidthWithPadding ? buttonWidthWithPadding : parent.width;
        height = buttonHeightWithPadding;
    }

    function setCallback(callbackFunction) {
        callback = callbackFunction;
    }

    Text {
        id: buttonText
        anchors.fill: parent
        wrapMode: Text.NoWrap
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: rectangleButton.text
        color: rectangleButton.enabled ? textColor : "#888"

        onTextChanged: {
            updateSizes();
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            if(rectangleButton.enabled) {
                Haptics.play();

                if(typeof rectangleButton.callback !== typeof undefined) {
                    if(rectangleButton.callback) {
                        rectangleButton.callback();
                    }
                }
            }
        }
    }
}
