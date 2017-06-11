import QtQuick 2.4
import Ubuntu.Components 1.3
import QtQuick.Layouts 1.1

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

                Label {
                    id: label
                    text: typeof value !== typeof undefined ? value : ""
                    wrapMode: Text.WordWrap
                    fontSize: typeof fontScale !== typeof undefined ? fontScale : "normal"
                    font.underline: typeof url !== typeof undefined ? true : false
                    visible: value !== "" ? true : false

                    Layout.fillWidth: true
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
                        var callback = customDataList.hasCallback(index);
                        if(callback) {
                            callback();
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
