import QtQuick 2.4
import Ubuntu.Components 1.3
import QtQuick.LocalStorage 2.0
import QtQuick.Layouts 1.1
import Ubuntu.Components.Popups 1.0

import "../components"

import "../transport-api.js" as Transport

Page {
    id: transportSelectorPage
    header: PageHeader {
        id: pageHeader
        title: i18n.tr("Select a transport option")
        flickable: transportSelectorFlickable

        StyleHints {
            foregroundColor: "#fff"
            backgroundColor: pageLayout.headerColor
        }
    }

    clip: true

    property var selectedTransport: null

    Flickable {
        id: transportSelectorFlickable
        anchors.fill: parent
        contentWidth: parent.width
        contentHeight: transportSelectorColumn.childrenRect.height

        Column {
            id: transportSelectorColumn
            anchors.fill: parent

            Component {
                id: transportDelegate

                ListItem {
                    id: transportDelegateItem
                    width: parent.width
                    height: transportDelegateRectangle.height + 2 * transportDelegateRectangle.anchors.margins
                    divider.visible: true

                    onVisibleChanged: {
                        this.color = Transport.transportOptions.getSelectedIndex() === index ? pageLayout.secondaryColor : "transparent";
                    }

                    property var expanded: false

                    trailingActions: ListItemActions {
                        actions: [
                            Action {
                                iconName: "view-expand"
                                onTriggered: {
                                    expanded = !expanded;
                                    if(expanded) {
                                        iconName = "view-collapse";
                                    }
                                    else {
                                        iconName = "view-expand";
                                    }
                                }
                            }
                        ]
                    }

                    Rectangle {
                        id: transportDelegateRectangle
                        anchors {
                            left: parent.left
                            right: parent.right
                            margins: units.gu(2)
                            verticalCenter: parent.verticalCenter
                        }
                        height: childrenRect.height
                        color: "transparent"

                        Column {
                            id: transportDelegateColumn
                            width: parent.width

                            Label {
                                text: nameExt
                                width: parent.width
                                font.pixelSize: FontUtils.sizeToPixels("normal")
                                wrapMode: Text.WordWrap
                            }

                            Column {
                                width: parent.width
                                visible: expanded

                                Rectangle {
                                    width: parent.width
                                    height: units.gu(2)
                                    color: "transparent"
                                }

                                Label {
                                    text: name
                                    width: parent.width
                                    font.bold: true
                                    wrapMode: Text.WordWrap
                                }


                                Label {
                                    text: title
                                    width: parent.width
                                    wrapMode: Text.WordWrap
                                    visible: this.text != nameExt.text
                                }

                                Label {
                                    text: homeState
                                    width: parent.width
                                    font.bold: true
                                    wrapMode: Text.WordWrap
                                    visible: this.text != ""
                                }

                                GridLayout {
                                    width: parent.width
                                    columns: 2

                                    Label {
                                        text: i18n.tr("City:") + " "
                                        wrapMode: Text.WordWrap
                                        visible: city !== ""
                                    }

                                    Label {
                                        text: city
                                        font.bold: true
                                        wrapMode: Text.WordWrap
                                        visible: city
                                        Layout.fillWidth: true
                                    }

                                    Label {
                                        text: i18n.tr("Valid from:") + " "
                                        wrapMode: Text.WordWrap
                                        visible: validFrom.text !== ""
                                    }

                                    Label {
                                        id: validFrom
                                        text: ttValidFrom
                                        wrapMode: Text.WordWrap
                                        visible: this.text !== ""
                                        Layout.fillWidth: true
                                    }

                                    Label {
                                        text: i18n.tr("Expires:") + " "
                                        wrapMode: Text.WordWrap
                                        visible: validTo.text !== ""
                                    }

                                    Label {
                                        id: validTo
                                        text: ttValidTo
                                        wrapMode: Text.WordWrap
                                        visible: this.text !== ""
                                        Layout.fillWidth: true
                                    }
                                }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            Transport.transportOptions.selectIndex(index);
                            pageLayout.removePages(transportSelectorPage);
                            transportSelectorPage.selectedTransport = name;
                        }
                    }
                }
            }

            ListItem {
                Rectangle {
                    anchors {
                        margins: units.gu(2)
                        left: parent.left
                        right: parent.right
                    }
                    height: parent.height
                    color: "transparent"

                    Label {
                        text: i18n.tr("All transport types") + " (" + restListModel.count + ")"
                        width: parent.width
                        font.italic: true
                        wrapMode: Text.WordWrap
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    ActivityIndicator {
                        anchors.centerIn: parent
                        running: restListView.inProgress
                        z: 1
                    }
                }
            }

            ListView {
                id: restListView
                width: parent.width
                height: childrenRect.height
                interactive: false
                model: ListModel {
                    id: restListModel
                }
                delegate: transportDelegate

                property bool inProgress: false

                Component.onCompleted: update()

                function update() {
                    var inProgress = this.inProgress;
                    inProgress = true;
                    Transport.transportOptions.setTransportUpdateCallback(function(options) {
                        inProgress = false;
                        if(options) {
                            var langCode = Transport.langCode(true);
                            for(var i = 0; i < options.transports.length; i++) {
                                var item = {};
                                item.name = options.transports[i].getName(langCode);
                                item.nameExt = options.transports[i].getNameExt(langCode);
                                item.description = options.transports[i].getDescription(langCode);
                                item.title = options.transports[i].getTitle(langCode);
                                item.city = options.transports[i].getCity(langCode);
                                item.homeState = options.transports[i].getHomeState();
                                item.ttValidFrom = options.transports[i].getTimetableInfo().ttValidFrom;
                                item.ttValidTo = options.transports[i].getTimetableInfo().ttValidTo;
                                restListModel.append(item);
                            }

                            transportSelectorPage.selectedTransport = options.getSelectedTransport().getName(langCode);
                        }
                    });

                    Transport.transportOptions.fetchTrasports();
                }
            }
        }
    }

    Scrollbar {
        flickableItem: transportSelectorFlickable
        align: Qt.AlignTrailing
    }
}
