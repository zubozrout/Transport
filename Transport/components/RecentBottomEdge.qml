import QtQuick 2.4
import Ubuntu.Components 1.3
import QtQuick.Layouts 1.1
import Ubuntu.Components.Popups 1.0

import "../transport-api.js" as Transport
import "../generalfunctions.js" as GeneralFunctions

BottomEdge {
    id: bottomEdge
    height: parent.height
    hint.text: i18n.tr("Recent searches")

    Component.onCompleted: {
        QuickUtils.mouseAttached = true;
    }

    contentComponent: Rectangle {
        width: bottomEdge.width
        height: bottomEdge.height
        opacity: bottomEdge.dragProgress

        PageHeader {
            id: recentPageHeader
            title: i18n.tr("Recent searches")

            trailingActionBar {
                actions: [
                    Action {
                        iconName: "delete"
                        text: i18n.tr("Delete all searches")
                        onTriggered: PopupUtils.open(confirmDeletingAllHistory)
                        enabled: recentListModel.count > 0
                        visible: enabled
                    }
                ]
            }

            StyleHints {
                foregroundColor: pageLayout.colorPalete["headerText"]
                backgroundColor: pageLayout.colorPalete["headerBG"]
            }
        }

        Component {
            id: confirmDeletingAllHistory

            Dialog {
                id: confirmDeletingAllHistoryDialogue
                title: i18n.tr("Attention")
                text: i18n.tr("Do you really want to delete the whole search history?")
                Button {
                    text: i18n.tr("No")
                    onClicked: PopupUtils.close(confirmDeletingAllHistoryDialogue)
                }
                Button {
                    text: i18n.tr("Yes")
                    color: UbuntuColors.red
                    onClicked: {
                        Transport.transportOptions.dbConnection.deleteAllSearchHistory();
                        PopupUtils.close(confirmDeletingAllHistoryDialogue);
                        bottomEdge.collapse();
                    }
                }
            }
        }

        Component {
            id: recentChildDelegate

            ListItem {
                width: parent.width
                divider.visible: true
                height: recentChildDelegateLayoutWrapper.height

                Component {
                    id: confirmDeletingHistoryEntry

                    Dialog {
                        id: confirmDeletingHistoryEntryDialogue
                        title: i18n.tr("Attention")
                        text: i18n.tr("Do you really want to delete this history entry?")
                        Button {
                            text: i18n.tr("No")
                            onClicked: PopupUtils.close(confirmDeletingHistoryEntryDialogue)
                        }
                        Button {
                            text: i18n.tr("Yes")
                            color: UbuntuColors.red
                            onClicked: {
                                Transport.transportOptions.dbConnection.deleteSearchHistory(ID);
                                PopupUtils.close(confirmDeletingHistoryEntryDialogue);
                                bottomEdge.collapse();
                            }
                        }
                    }
                }

                leadingActions: ListItemActions {
                    actions: [
                        Action {
                            iconName: "delete"
                            enabled: true
                            visible: true
                            onTriggered: {
                                PopupUtils.open(confirmDeletingHistoryEntry);
                            }
                        }
                    ]
                }
                
                Rectangle {
					id: recentChildDelegateLayoutWrapper
					anchors {
						left: parent.left
						right: parent.right
					}
					height: recentChildDelegateLayout.height + recentChildDelegateLayout.anchors.topMargin + recentChildDelegateLayout.anchors.bottomMargin
					color: index % 2 === 0 ? "transparent" : "#efefef"
					
					RowLayout {
						id: recentChildDelegateLayout
						anchors {
							centerIn: parent
							topMargin: units.gu(1)
							rightMargin: units.gu(2)
							bottomMargin: units.gu(1)
							leftMargin: units.gu(2)
						}
						spacing: units.gu(2)
						Layout.fillWidth: true
						width: parent.width - anchors.leftMargin - anchors.rightMargin

						Rectangle {
							id: recentChildDelegateIndex
							width: units.gu(3)
							height: width
							color: "transparent"

							Text {
								anchors.fill: parent
								horizontalAlignment: Text.AlignHCenter
								verticalAlignment: Text.AlignVCenter
								text: (index + 1) + "."
								font.pixelSize: FontUtils.sizeToPixels("large")
								font.bold: true
								wrapMode: Text.WordWrap
							}
						}

						ColumnLayout {
							id: historyMainColumnLayout
							spacing: units.gu(0.25)
							Layout.fillWidth: true

							RowLayout {
								spacing: units.gu(2)
								Layout.fillWidth: true

								Text {
									text: {
										var langCode = Transport.langCode(true);
										return Transport.transportOptions.getTransportById(typeid).getName(langCode);
									}
									font.pixelSize: FontUtils.sizeToPixels("small")
									font.bold: true
									horizontalAlignment: Text.AlignLeft
									wrapMode: Text.WordWrap
									Layout.fillWidth: true
								}

								Text {
									text: GeneralFunctions.dateToString(new Date(date.replace(/-/g, "/")))
									font.pixelSize: FontUtils.sizeToPixels("small")
									horizontalAlignment: Text.AlignRight
									wrapMode: Text.WordWrap
									Layout.fillWidth: true
								}
							}

							RowLayout {
								id: historyRowLayout
								spacing: units.gu(1)
								Layout.fillWidth: true
									
								ColumnLayout {
									id: fromStationColumn
									anchors.top: parent.top
									spacing: units.gu(0.25)
									Layout.fillWidth: false
									Layout.preferredWidth: historyMainColumnLayout.width / 2
									
									Text {
										text: i18n.tr("From")
										font.pixelSize: FontUtils.sizeToPixels("small")
										font.bold: false
										horizontalAlignment: Text.AlignLeft
										Layout.fillWidth: true
										wrapMode: Text.WordWrap
									}

									Text {
										text: stopnamefrom
										font.pixelSize: FontUtils.sizeToPixels("normal")
										font.bold: true
										horizontalAlignment: Text.AlignLeft
										Layout.fillWidth: true
										wrapMode: Text.WordWrap
									}
								}
									
								ColumnLayout {
									id: toStationColumn
									anchors.top: parent.top
									spacing: units.gu(0.25)
									Layout.fillWidth: true
									
									Text {
										text: i18n.tr("To")
										font.pixelSize: FontUtils.sizeToPixels("small")
										font.bold: false
										horizontalAlignment: Text.AlignLeft
										Layout.fillWidth: true
										wrapMode: Text.WordWrap
									}

									Text {
										text: stopnameto
										font.pixelSize: FontUtils.sizeToPixels("normal")
										font.bold: true
										horizontalAlignment: Text.AlignLeft
										Layout.fillWidth: true
										wrapMode: Text.WordWrap
									}
								}
							}

							Text {
								text: visible ? i18n.tr("Via") + ": " + stopnamevia : ""
								font.pixelSize: FontUtils.sizeToPixels("small")
								Layout.fillWidth: true
								horizontalAlignment: Text.AlignLeft
								wrapMode: Text.WordWrap
								visible: typeof stopidvia !== typeof undefined && stopidvia >= 0 && stopnamevia ? true : false
							}
						}
					}
				}

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        var newSelectedTransport = Transport.transportOptions.selectTransportById(typeid);
                        transportSelectorPage.selectedIndexChange();
                        if(newSelectedTransport) {
                            if(stopidfrom >= 0 && stopnamefrom) {
                                GeneralFunctions.setStopData(from, stopidfrom, stopnamefrom, typeid);
                            }
                            if(stopidto >= 0 && stopnameto) {
                                GeneralFunctions.setStopData(to, stopidto, stopnameto, typeid);
                            }
                            if(stopidvia >= 0 && stopnamevia) {
                                GeneralFunctions.setStopData(via, stopidvia, stopnamevia, typeid);
                                advancedSearchSwitch.checked = true;
                            }
                            else {
								via.empty();
                                advancedSearchSwitch.checked = false;
                            }
                        }
                        bottomEdge.collapse();
                    }
                }
            }
        }

        ListView {
            id: recentListView
            anchors.top: recentPageHeader.bottom
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            clip: true

            model: ListModel {
                id: recentListModel

                onCountChanged: {
                    bottomEdge.visible = count > 0 ? true : false;
                }
            }
            delegate: recentChildDelegate

            function refresh() {
                var modelData = Transport.transportOptions.dbConnection.getSearchHistory();
                model.clear();
                for(var i = 0; i < modelData.length; i++) {
					modelData[i].stopnamevia = modelData[i].stopnamevia || ""; // Hack for ListModel to always register this key
                    model.append(modelData[i]);
                }
            }

            Component.onCompleted: {
                refresh();
            }

            onVisibleChanged: {
                if(visible) {
                    refresh();
                }
            }

            Scrollbar {
                flickableItem: recentListView
                align: Qt.AlignTrailing
            }
        }
    }
}
