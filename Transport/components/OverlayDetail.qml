import QtQuick 2.4
import Ubuntu.Components 1.3

Rectangle {
    id: overlayDetail
    anchors.fill: parent
    color: pageLayout.colorPalete["baseBG"]
    visible: false
    clip: true

    property var flickable: overlayDetailFlickable
    property var overlayDetailData: null

    onOverlayDetailDataChanged: {
        if(overlayDetailData != null && Object.keys(overlayDetailData).length > 0) {
            detailTitle.text = overlayDetailData.title || "";
            detailText.text = overlayDetailData.text || "";
        }
    }

    Flickable {
        id: overlayDetailFlickable
        anchors.fill: parent
        contentWidth: parent.width
        contentHeight: overlayDetailRectangle.height

        Rectangle {
            id: overlayDetailRectangle
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: units.gu(2)
            }
            color: "transparent"
            height: overlayDetailColumn.height + 2 * anchors.margins

            Column {
                id: overlayDetailColumn
                anchors {
                    left: parent.left
                    right: parent.right
                }
                spacing: units.gu(2)

                Label {
                    id: detailTitle
                    horizontalAlignment: Text.AlignHCenter
                    fontSize: "large"
                    color: pageLayout.colorPalete["baseText"]
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: pageLayout.colorPalete["baseText"]
                }

                Label {
                    id: detailText
                    color: pageLayout.colorPalete["baseText"]
                }
            }
        }
    }

    Scrollbar {
        flickableItem: overlayDetailFlickable
        align: Qt.AlignTrailing
    }
}
