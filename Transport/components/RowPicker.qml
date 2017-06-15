import QtQuick 2.4
import QtQuick.Layouts 1.1
import Ubuntu.Components 1.3

Item {
    id: rowPicker
    anchors {
        left: parent.left
        right: parent.right
    }
    height: childrenRect.height

    property var callbacks: [{}]

    function setTite(title) {
        titleText.text = title || "";
    }

    function initialize(options, selectedIndex, callback) {
        var index = Number(selectedIndex) || 0;

        for(var i = 0; i < options.length; i++) {
            append({
                textContent: options[i],
                buttonActive: Number(i) === Number(index) ? true : false
            });

            if(typeof callback !== typeof undefined) {
                setCallbackFor(i, function(itemIndex) {
                    callback(itemIndex);
                });
            }
        }
    }

    function append(itemData) {
        itemData.buttonActive = itemData.buttonActive || false;
        rowListModel.append(itemData);
    }

    function count() {
        return rowListModel.count;
    }

    function clear() {
        rowListModel.clear();
    }

    function setCallbackFor(n, callback) {
        callbacks[n] = callback;
    }

    function hasCallback(n) {
        if(typeof callbacks[n] === typeof function() {}) {
            return callbacks[n];
        }
        return false;
    }

    function selectItem(n) {
        for(var i = 0; i < rowListModel.count; i++) {
            var item = rowListModel.get(i);
            rowListModel.setProperty(i, "buttonActive", i === n ? true : false);
        }
    }

    function update(procedure) {
        if(procedure) {
            procedure(rowListModel);
        }
    }

    Component {
        id: rowButton

        Rectangle {
            id: button
            width: rowButtonsLayout.width / rowListModel.count - rowButtonsLayout.spacing
            height: 2 * buttonText.contentHeight
            color: active ? pageLayout.colorPalete["headerBG"] : "#ddd";

            property bool active: buttonActive || false

            Text {
                id: buttonText
                anchors.fill: parent
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: textContent
                color: parent.active ? pageLayout.colorPalete["headerText"] : "#000"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    Haptics.play();
                    var callback = rowPicker.hasCallback(index);
                    if(callback) {
                        callback(index);
                    }
                    rowPicker.selectItem(index);
                }
            }
        }
    }

    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            margins: units.gu(2)
        }
        height: childrenRect.height + 2 * anchors.margins

        ColumnLayout {
            anchors {
                left: parent.left
                right: parent.right
            }
            spacing: units.gu(2)

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                }
                height: titleText.contentHeight * 2

                Text {
                    id: titleText
                    anchors.fill: parent
                    wrapMode: Text.WordWrap
                    verticalAlignment: Text.AlignVCenter
                    font.pointSize: units.gu(1.75)
                    text: ""
                    visible: text !== ""
                }
            }

            ListView {
                id: rowButtonsLayout
                anchors {
                    left: parent.left
                    right: parent.right
                }
                model: ListModel {
                    id: rowListModel
                }
                spacing: 1
                interactive: false
                orientation: Qt.Horizontal
                delegate: rowButton
            }
        }
    }
}
