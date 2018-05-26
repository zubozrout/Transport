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
        
        trailingActionBar {
            actions: [
                Action {
                    iconName: "map"
                    text: i18n.tr("Map page")
                    onTriggered: {
						mapPage.cleanPage(false);
                        pageLayout.addPageToNextColumn(connectionDetailPage, mapPage);
                        mapPage.renderRoute(connectionDetailPage.detail);
                    }
                }
            ]
            numberOfSlots: 1
        }

        extension: Sections {
            id: connectionDetailSections
            anchors {
                left: parent.left
                right: parent.right
                leftMargin: units.gu(2)
                bottom: parent.bottom
            }
            model: [i18n.tr("Only passed stations"), i18n.tr("All stations")]
            selectedIndex: 0

            StyleHints {
                sectionColor: pageLayout.colorPalete.secondaryBG
                selectedSectionColor: pageLayout.colorPalete.headerText
            }
        }

        StyleHints {
            foregroundColor: pageLayout.colorPalete["headerText"]
            backgroundColor: pageLayout.colorPalete["headerBG"]
        }
    }

    clip: true

    property var detail: null

    function renderDetail(detail) {
        connectionDetailModel.clearAll();
        if(detail) {
			connectionDetailPage.detail = detail;
            distanceLabel.text = detail.distance;
            timeLabel.text = detail.timeLength;
            priceLabel.text = detail.price;

            for(var i = 0; i < detail.trainLength(); i++) {
                connectionDetailModel.append(detail.getTrain(i));
                connectionDetailModel.childModel.push(detail.getTrain(i).route)
            }
        }
    }

    ConnectionDetailDelegate {
        id: connectionDetailDelegate
    }

    Flickable {
        id: connectionDetailFlickable
        anchors.fill: parent
        contentWidth: parent.width
        contentHeight: connectionDetailColumn.spacing + connectionDetailColumn.anchors.bottomMargin + dataBar.height + connectionDetailView.height

        ColumnLayout {
            id: connectionDetailColumn
            anchors {
                left: parent.left
                right: parent.right
                bottomMargin: units.gu(2)
            }
            spacing: units.gu(2)

            Rectangle {
                id: dataBar
                color: pageLayout.secondaryColor
                anchors {
                    left: parent.left
                    right: parent.right
                }
                height: dataBarRow.height + 2 * dataBarRow.anchors.margins

                RowLayout {
                    id: dataBarRow
                    anchors {
                        left: parent.left
                        right: parent.right
                        margins: units.gu(1)
                        verticalCenter: parent.verticalCenter
                    }
                    Layout.fillHeight: false
                    spacing: units.gu(2)

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: false

                        Label {
                            text: i18n.tr("Distance")
                            color: pageLayout.baseTextColor
                            wrapMode: Text.WordWrap
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            Layout.fillWidth: true
                        }

                        Label {
                            id: distanceLabel
                            text: ""
                            color: pageLayout.baseTextColor
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                            Layout.fillWidth: true
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: false

                        Label {
                            text: i18n.tr("Time length")
                            color: pageLayout.baseTextColor
                            wrapMode: Text.WordWrap
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            Layout.fillWidth: true
                        }

                        Label {
                            id: timeLabel
                            text: ""
                            color: pageLayout.baseTextColor
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                            Layout.fillWidth: true
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: false

                        Label {
                            text: i18n.tr("Price")
                            color: pageLayout.baseTextColor
                            wrapMode: Text.WordWrap
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            Layout.fillWidth: true
                        }

                        Label {
                            id: priceLabel
                            text: ""
                            color: pageLayout.baseTextColor
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                            Layout.fillWidth: true
                        }
                    }
                }
            }

            ListView {
                id: connectionDetailView
                anchors {
                    left: parent.left
                    right: parent.right
                }
                height: contentHeight
                interactive: false
                delegate: connectionDetailDelegate
                spacing: units.gu(2)

                model: ListModel {
                    id: connectionDetailModel
                    property var childModel: []

                    function clearAll() {
                        this.clear();
                        this.childModel = [];
                    }
                }
            }
        }
    }

    Scrollbar {
        flickableItem: connectionDetailFlickable
        align: Qt.AlignTrailing
    }
}
