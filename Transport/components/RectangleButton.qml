import QtQuick 2.4

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

    function updateSizes() {
        var buttonWidthWithPadding = buttonText.contentWidth * (5/3);
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
            if(rectangleButton.enabled && typeof rectangleButton.callback !== typeof undefined) {
                if(rectangleButton.callback) {
                    rectangleButton.callback();
                }
            }
        }
    }
}
