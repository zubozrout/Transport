import QtQuick 2.4
import Ubuntu.Components 1.3
import QtQuick.Layouts 1.1

import "../components"

import "../transport-api.js" as Transport
import "../generalfunctions.js" as GeneralFunctions

Page {
    id: connectionDetailPage
    header: PageHeader {
        id: pageHeader
        title: i18n.tr("Connection detail")
        flickable: connectionDetailFlickable

        StyleHints {
            foregroundColor: "#fff"
            backgroundColor: pageLayout.headerColor
        }
    }

    property var detail: null

    function renderDetail(detail) {
        if(detail) {
            console.log(detail.id);
            console.log(detail.distance);
            console.log(detail.timeLength);
            console.log(detail.price);

            connectionDetailModel.append({});
        }
    }

    Flickable {
        id: connectionDetailFlickable
        anchors.fill: parent
        contentWidth: parent.width
        contentHeight: connectionDetailView.contentHeight

        ListView {
            id: connectionDetailView
            anchors.fill: parent
            interactive: false
            delegate: connectionDetailDelegate

            model: ListModel {
                id: connectionDetailModel
            }
        }
    }

    Scrollbar {
        flickableItem: connectionDetailFlickable
        align: Qt.AlignTrailing
    }
}
