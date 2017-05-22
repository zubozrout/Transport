import QtQuick 2.4
import Ubuntu.Components 1.3

Page {
    id: aboutPage
    header: PageHeader {
        id: pageHeader
        title: i18n.tr("About")
        flickable: aboutFlickable

        StyleHints {
            foregroundColor: pageLayout.colorPalete["headerText"]
            backgroundColor: pageLayout.colorPalete["headerBG"]
        }
    }

    clip: true

    Flickable {
        id: aboutFlickable
        anchors.fill: parent
        contentHeight: aboutColumn.childrenRect.height + 2 * aboutFlickableRectangle.anchors.margins

        Rectangle {
            id: aboutFlickableRectangle
            anchors {
                fill: parent
                margins: units.gu(1)
            }

            Column {
                id: aboutColumn
                anchors {
                    left: parent.left
                    right: parent.right
                }
                spacing: units.gu(2)

                Component {
                    id: aboutEntry
                    Item {
                        height: label.height + units.gu(4)
                        width: parent.width

                        Label {
                            id: label
                            text: value
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: contentHeight
                            wrapMode: Text.WordWrap
                            fontSize: fontScale ? fontScale : "normal"
                            font.underline: url ? true : false
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
                    id: aboutList
                    anchors {
                        left: parent.left
                        right: parent.right
                        margins: units.gu(2)
                    }
                    delegate: aboutEntry
                    model: ListModel {
                        id: aboutModel
                    }
                    height: childrenRect.height
                    interactive: false

                    Component.onCompleted: {
                        aboutModel.append({value: i18n.tr("Transport") + " - starting from scratch", fontScale: "large"});
                        aboutModel.append({value: i18n.tr("Transport is here to allow you searching for Czech and Slovak public transport connections.")});
                        aboutModel.append({value: i18n.tr("This application is based upon an API provided by CHAPS s.r.o. company.") + " info@chaps.cz\n\n" + i18n.tr("You can find the documentation of the API service here http://docs.crws.apiary.io/")});
                        aboutModel.append({value: i18n.tr("Feel free to report bugs on the github page but please note many of the existing bugs are know and the reason why they are not fixed yet is the fact I don't have enough time to take care of those just yet."), fontScale: "small"});
                        aboutModel.append({value: i18n.tr("Check out project's GitHub page"), url: "https://github.com/zubozrout/Transport/tree/devel/Transport"});
                    }
                }
            }
        }
    }

    Scrollbar {
        flickableItem: aboutFlickable
        align: Qt.AlignTrailing
    }
}
