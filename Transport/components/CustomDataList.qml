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

    function append(itemData) {
        dataListModel.append(itemData);
    }

    function clear() {
        dataListModel.clear();
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
                    text: value
                    wrapMode: Text.WordWrap
                    fontSize: fontScale ? fontScale : "normal"
                    font.underline: url ? true : false

                    Layout.fillWidth: true
                }
            }

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: "#ddd"
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if(url) {
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
