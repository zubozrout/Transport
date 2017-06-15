import QtQuick 2.4
import Ubuntu.Components 1.3
import QtQuick.Layouts 1.1
import Ubuntu.Components.Popups 1.0

Item {
    id: customDataList
    anchors {
        left: parent.left
        right: parent.right
    }
    height: dataList.height

    property var callbacks: [{}]

    function append(itemData) {
        dataListModel.append(itemData);
    }

    function count() {
        return dataListModel.count;
    }

    function clear() {
        dataListModel.clear();
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

    Component {
        id: entry

        Item {
            height: layout.height + units.gu(4)
            width: parent.width

            Component {
                id: confirmAction

                Dialog {
                    id: confirmActionDialogue
                    title: i18n.tr("Do you really want to proceed with this action?")
                    text: typeof value !== typeof undefined ? value : ""
                    Button {
                        text: i18n.tr("No")
                        onClicked: PopupUtils.close(confirmActionDialogue)
                    }
                    Button {
                        text: i18n.tr("Yes")
                        color: UbuntuColors.red
                        onClicked: {
                            var callback = customDataList.hasCallback(index);
                            if(callback) {
                                callback();
                            }
                            PopupUtils.close(confirmActionDialogue);
                        }
                    }
                }
            }

            RowLayout {
                id: layout
                width: parent.width
                spacing: units.gu(2)
                anchors.verticalCenter: parent.verticalCenter

                Image {
                    id: icon
                    visible: source ? true : false
                    width: 0
                    fillMode: Image.PreserveAspectFit
                    smooth: true

                    Layout.fillWidth: false

                    Component.onCompleted: {
                        if(typeof imageSource !== typeof undefined) {
                            if(typeof imageWidth !== typeof undefined) {
                                width = imageWidth;
                            }
                            else {
                                width = 80;
                            }
                            sourceSize.width = width;

                            source = imageSource;
                        }
                    }
                }

                Text {
                    id: label
                    text: typeof value !== typeof undefined ? value : ""
                    wrapMode: Text.WordWrap
                    font.pointSize: fontSizeCounter();
                    font.underline: typeof url !== typeof undefined ? true : false
                    visible: value !== "" ? true : false

                    Layout.fillWidth: true

                    function fontSizeCounter() {
                        if(typeof fontScale !== typeof undefined) {
                            if(fontScale === "large") {
                                return units.gu(1.75);
                            }
                            else if("small") {
                                return units.gu(1);
                            }
                            else {
                                return units.gu(1.35);
                            }
                        }
                        return units.gu(1.35);
                    }
                }

                Button {
                    id: button
                    iconName: typeof buttonIcon !== typeof undefined ? buttonIcon : "add"
                    color: "transparent"
                    visible: customDataList.hasCallback(index) ? true : false

                    Layout.minimumWidth: units.gu(4)
                    Layout.maximumWidth: units.gu(4)
                    Layout.preferredWidth: units.gu(4)
                    Layout.fillWidth: false

                    onClicked: {
                        if(customDataList.hasCallback(index)) {
                            PopupUtils.open(confirmAction);
                        }
                    }
                }
            }

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: "#ddd"
                visible: typeof bottomBorder !== typeof undefined && bottomBorder === true
            }

            MouseArea {
                anchors.fill: parent
                enabled: typeof url !== typeof undefined ? true : false
                onClicked: {
                    if(typeof url !== typeof undefined) {
                        Qt.openUrlExternally(url);
                    }
                }
            }
        }
    }

    ListView {
        id: dataList
        anchors {
            left: parent.left
            right: parent.right
            margins: units.gu(2)
        }
        height: contentHeight
        interactive: false

        delegate: entry
        model: ListModel {
            id: dataListModel
        }
    }
}
