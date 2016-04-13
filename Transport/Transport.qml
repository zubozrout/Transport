
import QtQuick 2.4
import Ubuntu.Components 1.3
import QtQuick.LocalStorage 2.0
import QtQuick.Layouts 1.1
import Ubuntu.Components.Popups 1.0

import "engine.js" as Engine
import "localStorage.js" as DB

Page {
    id: trasport_selector_page
    visible: false
    clip: true

    header: PageHeader {
        id: trasportSelectorPageHeader
        title: i18n.tr("Transport selector")
        flickable: transportSelectorFlickable

        leadingActionBar.actions: [
            Action {
                iconName: "back"
                text: "Back"
                onTriggered: pageLayout.removePages(trasport_selector_page)
            }
        ]

        StyleHints {
            foregroundColor: "#fff"
            backgroundColor: "#3949AB"
        }
    }

    property var selectedItem: 0
    property var selectedName: ""
    property var lastUsedTransport: ""

    function getTextFieldContentFromDB(force) {
        if(DB.getSetting("from" + selectedItem)) {
            if(from.displayText == "" || force) {
                from.text = DB.getSetting("from" + selectedItem);
                from.stationInputModel.clear();
            }
        }
        else {
            from.text = "";
        }

        if(DB.getSetting("to" + selectedItem)) {
            if(to.displayText == "" || force) {
                to.text = DB.getSetting("to" + selectedItem);
                to.stationInputModel.clear();
            }
        }
        else {
            to.text = "";
        }

        if(DB.getSetting("via" + selectedItem)) {
            if(via.displayText == "" || force) {
                via.text = DB.getSetting("via" + selectedItem);
                via.stationInputModel.clear();
            }
        }
        else {
            via.text = "";
        }
    }

    function confirm() {
        api.abort();
        if(pageLayout != null) {
            pageLayout.removePages(trasport_selector_page);
        }
    }

    function update() {
        knownListView.update();
        restListView.update();
    }

    onSelectedItemChanged: {
        lastUsedTransport = selectedItem;
        getTextFieldContentFromDB(true);
        from.stationInputModel.clear();
        to.stationInputModel.clear();
        via.stationInputModel.clear();
    }

    onVisibleChanged: {
        if(visible) {
            update();
        }
    }

    Component.onCompleted: {
        lastUsedTransport = DB.getSetting("optionsList");
    }

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
                    width: parent.width
                    divider.visible: true
                    color: selectedItem == id ? UbuntuColors.lightGrey : "transparent"

                    property var expanded: false

                    Component.onCompleted: {
                        if(knownList && lastUsedTransport == id) {
                            trasport_selector_page.selectedItem = id;
                            trasport_selector_page.selectedName = name;
                        }
                    }

                    Component {
                        id: confirmDeletingAllTransportStops

                        Dialog {
                            id: confirmDeletingAllTransportStopsDialogue
                            title: i18n.tr("Attention")
                            text: i18n.tr("Do you really want to delete all saved stations for %1 transport?").arg(name)
                            Button {
                                text: i18n.tr("No")
                                onClicked: PopupUtils.close(confirmDeletingAllTransportStopsDialogue)
                            }
                            Button {
                                text: i18n.tr("Yes")
                                color: UbuntuColors.red
                                onClicked: {
                                    DB.deleteAllTransportStops(id);
                                    PopupUtils.close(confirmDeletingAllTransportStopsDialogue);
                                    trasport_selector_page.selectedItem = "";
                                    trasport_selector_page.selectedName = "";
                                    trasport_selector_page.getTextFieldContentFromDB(true);
                                    trasport_selector_page.confirm();
                                }
                            }
                        }
                    }

                    leadingActions: ListItemActions {
                        actions: [
                            Action {
                                iconName: "delete"
                                enabled: knownList
                                visible: knownList
                                onTriggered: {
                                    PopupUtils.open(confirmDeletingAllTransportStops);
                                }
                            }
                        ]
                    }

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

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            trasport_selector_page.selectedItem = id;
                            trasport_selector_page.selectedName = name;
                            trasport_selector_page.confirm();
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

                            Label {
                                text: name
                                width: parent.width
                                font.pixelSize: knownList ? FontUtils.sizeToPixels("large") : FontUtils.sizeToPixels("normal")
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
                                    text: nameExt
                                    width: parent.width
                                    font.bold: true
                                    wrapMode: Text.WordWrap
                                }


                                Label {
                                    text: title
                                    width: parent.width
                                    wrapMode: Text.WordWrap
                                    visible: title != nameExt
                                }

                                Label {
                                    text: homeState != "" ? (homeState == "CZ" ? i18n.tr("Czech Republic") : i18n.tr("Slovak Republic")) : ""
                                    width: parent.width
                                    font.bold: true
                                    wrapMode: Text.WordWrap
                                    visible: homeState != ""
                                }

                                GridLayout {
                                    width: parent.width
                                    columns: 2

                                    Label {
                                        text: i18n.tr("City:") + " "
                                        wrapMode: Text.WordWrap
                                        visible: city != ""
                                    }

                                    Label {
                                        text: city
                                        font.bold: true
                                        wrapMode: Text.WordWrap
                                        visible: city != ""
                                        Layout.fillWidth: true
                                    }

                                    Label {
                                        text: i18n.tr("Vehicle types:") + " "
                                        wrapMode: Text.WordWrap
                                        visible: trTypes != ""
                                    }

                                    Label {
                                        text: trTypes
                                        font.italic: true
                                        wrapMode: Text.WordWrap
                                        visible: trTypes != ""
                                        Layout.fillWidth: true
                                    }

                                    Label {
                                        text: i18n.tr("Valid from:") + " "
                                        wrapMode: Text.WordWrap
                                        visible: ttValidFrom != ""
                                    }

                                    Label {
                                        text: ttValidFrom
                                        wrapMode: Text.WordWrap
                                        visible: ttValidFrom != ""
                                        Layout.fillWidth: true
                                    }

                                    Label {
                                        text: i18n.tr("Expires:") + " "
                                        wrapMode: Text.WordWrap
                                        visible: ttValidTo != ""
                                    }

                                    Label {
                                        text: ttValidTo
                                        wrapMode: Text.WordWrap
                                        visible: ttValidTo != ""
                                        Layout.fillWidth: true
                                    }
                                }
                            }
                        }
                    }
                }
            }

            ListView {
                id: knownListView
                width: parent.width
                height: childrenRect.height

                interactive: false

                model: ListModel {
                    id: knownListMmodel
                }
                delegate: transportDelegate

                Component.onCompleted: {
                    update();
                    Engine.getOptions(function(response) {
                        Engine.saveOptions(response);
                        update();
                    });
                }

                function update() {
                    knownListMmodel.clear();

                    var types = DB.getAllTypes();
                    var usedTypes = DB.getAllUsedTypes();
                    var position = Engine.langCode(true);
                    for(var i = 0; i < types.length; i++) {
                        var index = types[i].id;
                        if(usedTypes.indexOf(index) > -1) {
                            var name = types[i].name ? types[i].name[position] : "";
                            var nameExt = types[i].nameExt ? types[i].nameExt[position] : "";
                            var title = types[i].title ? types[i].title[position] : "";
                            var city = types[i].city ? types[i].city[position] : "";
                            var description = types[i].description ? types[i].description[position] : "";
                            var homeState = types[i].homeState ? types[i].homeState.replace("*", "") : "";
                            var trTypes = "";
                            for(var j = 0; j < types[i].trTypes.length; j++) {
                                trTypes += (j != 0 ? ", " : "") + types[i].trTypes[j].name[position];
                            }
                            var ttValidFrom = types[i].ttValidFrom ? types[i].ttValidFrom : "";
                            var ttValidTo = types[i].ttValidTo ? types[i].ttValidTo : "";
                            knownListMmodel.append({knownList: true, id: index, name: name, nameExt: nameExt, title: title, city: city, description: description, homeState: homeState, trTypes: trTypes, ttValidFrom: ttValidFrom, ttValidTo: ttValidTo});
                        }
                    }
                }
            }

            Column {
                width: parent.width
                spacing: 1

                Rectangle {
                    width: parent.width
                    height: 1
                    color: "#ddd"
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: "#ddd"
                }
            }

            ListView {
                id: restListView
                width: parent.width
                height: childrenRect.height
                interactive: false

                model: ListModel {
                    id: restListMmodel
                }
                delegate: transportDelegate

                Component.onCompleted: update()

                function update() {
                    restListMmodel.clear();

                    var types = DB.getAllTypes();
                    var usedTypes = DB.getAllUsedTypes();
                    var position = Engine.langCode(true);
                    for(var i = 0; i < types.length; i++) {
                        var index = types[i].id;
                        var name = types[i].name ? types[i].name[position] : "";
                        var nameExt = types[i].nameExt ? types[i].nameExt[position] : "";
                        var title = types[i].title ? types[i].title[position] : "";
                        var city = types[i].city ? types[i].city[position] : "";
                        var description = types[i].description ? types[i].description[position] : "";
                        var homeState = types[i].homeState ? types[i].homeState.replace("*", "") : "";
                        var trTypes = "";
                        for(var j = 0; j < types[i].trTypes.length; j++) {
                            trTypes += (j != 0 ? ", " : "") + types[i].trTypes[j].name[position];
                        }
                        var ttValidFrom = types[i].ttValidFrom ? types[i].ttValidFrom : "";
                        var ttValidTo = types[i].ttValidTo ? types[i].ttValidTo : "";
                        restListMmodel.append({knownList: false, id: index, name: name, nameExt: nameExt, title: title, city: city, description: description, homeState: homeState, trTypes: trTypes, ttValidFrom: ttValidFrom, ttValidTo: ttValidTo});
                    }
                }
            }
        }
    }

    Scrollbar {
        flickableItem: transportSelectorFlickable
        align: Qt.AlignTrailing
    }
}
