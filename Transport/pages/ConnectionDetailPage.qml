import QtQuick 2.4
import Ubuntu.Components 1.3
import QtQuick.Layouts 1.2

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
            distanceLabel.text = detail.distance || "";
            timeLabel.text = detail.timeLength || "";
            priceLabel.text = detail.price || "";

            for(var i = 0; i < detail.trainLength(); i++) {
                connectionDetailModel.append(detail.getTrain(i));
                connectionDetailModel.childModel.push(detail.getTrain(i).route)
            }
            
            connectionDetailView.forceLayout(); // Fix ListView's height
        }
    }

    ConnectionDetailDelegate {
        id: connectionDetailDelegate
    }

    Flickable {
        id: connectionDetailFlickable
        anchors.fill: parent
        contentWidth: parent.width
        contentHeight: wrappingRectangle.height + wrappingRectangle.anchors.topMargin + wrappingRectangle.anchors.bottomMargin
		
		Rectangle {
			id: wrappingRectangle
			anchors {
				left: parent.left
				right: parent.right
				topMargin: units.gu(2)
				bottomMargin: units.gu(2)
				verticalCenter: parent.verticalCenter
			}
			height: 2 * connectionDetailColumn.spacing + dataBarRow.height + delimiter.height + connectionDetailView.height
			color: "transparent"
			
			ColumnLayout {
				id: connectionDetailColumn
				anchors {
					left: parent.left
					right: parent.right
				}
				spacing: units.gu(2)

				RowLayout {
					id: dataBarRow
					anchors {
						left: parent.left
						right: parent.right
						leftMargin: units.gu(2)
						rightMargin: units.gu(2)
					}
					Layout.maximumWidth: parent.width - anchors.rightMargin
					spacing: units.gu(2)

					ColumnLayout {
						anchors.top: parent.top
						Layout.fillWidth: true
						
						Label {
							text: i18n.tr("Distance")
							Layout.fillWidth: true
							color: pageLayout.baseTextColor
							wrapMode: Text.WordWrap
							font.bold: true
						}

						Label {
							id: distanceLabel
							text: ""
							Layout.fillWidth: true
							color: pageLayout.baseTextColor
							wrapMode: Text.WordWrap
						}
					}

					ColumnLayout {
						anchors.top: parent.top
						Layout.fillWidth: true

						Label {
							text: i18n.tr("Time length")
							Layout.fillWidth: true
							color: pageLayout.baseTextColor
							wrapMode: Text.WordWrap
							font.bold: true
						}

						Label {
							id: timeLabel
							text: ""
							Layout.fillWidth: true
							color: pageLayout.baseTextColor
							wrapMode: Text.WordWrap
						}
					}

					ColumnLayout {
						anchors.top: parent.top
						Layout.fillWidth: true
						Layout.maximumWidth: parent.width / 3

						Label {
							text: i18n.tr("Price")
							Layout.fillWidth: true
							color: pageLayout.baseTextColor
							wrapMode: Text.WordWrap
							font.bold: true
						}

						Label {
							id: priceLabel
							text: ""
							Layout.fillWidth: true
							color: pageLayout.baseTextColor
							wrapMode: Text.WordWrap
						}
					}
				}
				
				Rectangle {
					id: delimiter
					Layout.fillWidth: true
					height: 1
					color: pageLayout.colorPalete["headerBG"]
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
    }

    Scrollbar {
        flickableItem: connectionDetailFlickable
        align: Qt.AlignTrailing
    }
}
