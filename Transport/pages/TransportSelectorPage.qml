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
            foregroundColor: pageLayout.colorPalete["headerText"]
            backgroundColor: pageLayout.colorPalete["headerBG"]
        }

        trailingActionBar {
            actions: [
                Action {
                    iconName: "reload"
                    text: i18n.tr("Refresh transport options")
                    onTriggered: {
                        progressLine.state = "running";
                        Transport.transportOptions.fetchTrasports(true, function() {
                            progressLine.state = "idle";
                        });
                    }
                }
           ]
        }
    }

    clip: true

    function selectedIndexChange() {
        var selectedTransport = Transport.transportOptions.getSelectedTransport();
        if(selectedTransport) {
            searchPage.setSelectedTransportLabelValue({
                ok: true,
                value: selectedTransport.getName(Transport.langCode(true))
            });
        }
        else {
            searchPage.setSelectedTransportLabelValue({
                ok: false,
                value: i18n.tr("Select a transport method")
            });
        }
    }

    function update() {
        progressLine.state = "running";
        Transport.transportOptions.setTransportUpdateCallback(function(options) {
            progressLine.state = "idle";
            if(options) {
                usedListModel.clear();
                restListModel.clear();
                var langCode = Transport.langCode(true);
                for(var i = 0; i < options.transports.length; i++) {
                    var transportUsed = options.transports[i].isUsed();

                    var item = {};
                    item.id = options.transports[i].getId();
                    item.name = options.transports[i].getName(langCode);
                    item.nameExt = options.transports[i].getNameExt(langCode);
                    item.description = options.transports[i].getDescription(langCode);
                    item.title = options.transports[i].getTitle(langCode);
                    item.city = options.transports[i].getCity(langCode);
                    item.homeState = options.transports[i].getHomeState();
                    item.ttValidFrom = options.transports[i].getTimetableInfo().ttValidFrom;
                    item.ttValidTo = options.transports[i].getTimetableInfo().ttValidTo;
                    item.isUsed = transportUsed;
                    restListModel.append(item);

                    if(transportUsed && options.transports.length > 10) {
                        usedListModel.append(item);
                    }
                }
            }

            selectedIndexChange();
        });

        Transport.transportOptions.fetchTrasports();
    }

    ProgressLine {
        id: progressLine
        anchors {
            top: pageHeader.bottom
        }
        z: 10
    }

    Flickable {
        id: transportSelectorFlickable
        anchors.fill: parent
        contentWidth: parent.width
        contentHeight: transportSelectorColumn.height

        Column {
            id: transportSelectorColumn
            anchors {
                left: parent.left
                right: parent.right
            }
            height: childrenRect.height

            Component {
                id: transportDelegate

                ListItem {
                    id: transportDelegateItem
                    width: parent.width
                    height: transportDelegateRectangle.height + 2 * transportDelegateRectangle.anchors.margins
                    divider.visible: true

                    onVisibleChanged: {
                        this.color = Transport.transportOptions.getSelectedId() === id ? pageLayout.secondaryColor : "transparent";
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
                            },
                            Action {
                                iconName: "delete"
                                onTriggered: PopupUtils.open(confirmStationStopRemoval)
                                visible: isUsed ? true : false
                            }
                        ]
                    }

                    Component {
                        id: confirmStationStopRemoval

                        Dialog {
                            id: confirmStationStopRemovalDialogue
                            title: i18n.tr("Attention")
                            text: i18n.tr("Do you really want to delete all saved stops for %1 transport option?").arg((name ? name : ""))
                            Button {
                                text: i18n.tr("No")
                                onClicked: PopupUtils.close(confirmStationStopRemovalDialogue)
                            }
                            Button {
                                text: i18n.tr("Yes")
                                color: UbuntuColors.red
                                onClicked: {
                                    Transport.transportOptions.dbConnection.clearStationsForId(id);
                                    PopupUtils.close(confirmStationStopRemovalDialogue);
                                    pageLayout.removePages(transportSelectorPage);
                                }
                            }
                        }
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

                            RowLayout {
                                spacing: units.gu(2)

                                Icon {
                                    name: "favorite-selected"
                                    width: visible ? units.gu(2) : 0
                                    color: pageLayout.colorPalete["headerBG"]
                                    visible: isUsed ? true : false
                                }

                                Label {
                                    text: nameExt
                                    font.pixelSize: FontUtils.sizeToPixels("normal")
                                    color: isUsed ? pageLayout.colorPalete["baseAlternateText"] : pageLayout.colorPalete["baseText"]
                                    wrapMode: Text.WordWrap

                                    Layout.fillWidth: true
                                }
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
                                    visible: this.text !== nameExt.text
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
                            Transport.transportOptions.selectTransportById(id);
                            transportSelectorPage.selectedIndexChange();
                            pageLayout.removePages(transportSelectorPage);
                        }
                    }
                }
            }

            ListItem {
                visible: usedListModel.count > 0 && usedListModel.count !== restListModel.count

                Rectangle {
                    anchors {
                        margins: units.gu(2)
                        left: parent.left
                        right: parent.right
                    }
                    height: parent.height
                    color: "transparent"

                    Label {
                        text: i18n.tr("Used transport types") + " (" + usedListModel.count + ")"
                        width: parent.width
                        font.italic: true
                        wrapMode: Text.WordWrap
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            ListView {
                id: usedListView
                width: parent.width
                height: childrenRect.height
                interactive: false
                model: ListModel {
                    id: usedListModel
                }
                delegate: transportDelegate
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
                        running: progressLine.state === "running"
                        z: 1
                    }

                    Button {
                        width: units.gu(4)
                        anchors {
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                        }
                        visible: usedListModel.count > 0
                        color: "transparent"

                        onClicked: {
                            restListView.visible = !restListView.visible
                        }

                        Icon {
                            anchors.fill: parent
                            name: "search"
                            color: pageLayout.baseTextColor
                        }
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

                Component.onCompleted: {
                    transportSelectorPage.update();
                    visible = usedListModel.count === 0;
                }
            }
        }
    }

    Scrollbar {
        flickableItem: transportSelectorFlickable
        align: Qt.AlignTrailing
    }
}
