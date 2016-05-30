import QtQuick 2.4
import Ubuntu.Components 1.3
import QtQuick.LocalStorage 2.0
import QtQuick.Layouts 1.1
import Ubuntu.Components.Popups 1.0

import "engine.js" as Engine
import "localStorage.js" as DB

Page {
    id: transport_selector_page
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
                onTriggered: pageLayout.removePages(transport_selector_page)
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

    property date minimumDate: new Date()
    property date maximumDate: new Date()

    function reMapDate(object) {
        var fday = object.ttValidFrom.split(".")[0];
        var fmonth = object.ttValidFrom.split(".")[1];
        var fyear = object.ttValidFrom.split(".")[2];

        var fromFinalDate = new Date();
        fromFinalDate.setFullYear(fyear, fmonth - 1, fday);
        fromFinalDate.setHours(0, 0, 0, 0);

        var tday = object.ttValidTo.split(".")[0];
        var tmonth = object.ttValidTo.split(".")[1];
        var tyear = object.ttValidTo.split(".")[2];

        var toFinalDate = new Date();
        toFinalDate.setFullYear(tyear, tmonth - 1, tday);
        toFinalDate.setHours(0, 0, 0, 0);

        transport_selector_page.minimumDate = fromFinalDate;
        transport_selector_page.maximumDate = toFinalDate;

        if(!DB.getSetting("settings_ignore_transport_expire_dates")) {
            datePicker.setTransportDates();
        }
    }

    function selectItemByIdLocal(id, forceOverwrite) {
        for(var i = 0; i < restListModel.count; i++) {
            if(restListModel.get(i).id == id) {
                selectedItem = restListModel.get(i).id;
                selectedName = restListModel.get(i).nameExt;
                reMapDate(restListModel.get(i));
                confirm();

                lastUsedTransport = selectedItem;
                getTextFieldContentFromDB(forceOverwrite);
                from.stationInputModel.clear();
                to.stationInputModel.clear();
                via.stationInputModel.clear();
            }
        }
    }

    function selectItemById(id) {
        selectItemByIdLocal(id, false);
    }

    function getTextFieldContentFromDB(force) {
        if(DB.getSetting("fromObj" + selectedItem)) {
            if(from.displayText == "" || force) {
                var fromObj = JSON.parse(DB.getSetting("fromObj" + selectedItem));
                from.text = fromObj.name;
                from.coorX = fromObj.x;
                from.coorY = fromObj.y;
                from.stationInputModel.clear();
            }
        }
        else {
            from.text = "";
        }

        if(DB.getSetting("toObj" + selectedItem)) {
            if(to.displayText == "" || force) {
                var toObj = JSON.parse(DB.getSetting("toObj" + selectedItem));
                to.text = toObj.name;
                to.coorX = toObj.x;
                to.coorY = toObj.y;
                to.stationInputModel.clear();
            }
        }
        else {
            to.text = "";
        }

        if(DB.getSetting("viaObj" + selectedItem)) {
            if(via.displayText == "" || force) {
                if(viaObj) {
                    var viaObj = JSON.parse(DB.getSetting("viaObj" + selectedItem));
                    if(viaObj.name != from.displayText && viaObj.name != to.displayText) {
                        via.text = viaObj.name;
                        via.coorX = viaObj.x;
                        via.coorY = viaObj.y;
                    }
                    via.stationInputModel.clear();
                }
            }
        }
        else {
            via.text = "";
        }
    }

    function confirm() {
        api.abort();
        if(pageLayout != null) {
            pageLayout.removePages(transport_selector_page);
        }
    }

    function update() {
        knownListView.update();
        restListView.update();
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
                    id: transportDelegateItem
                    width: parent.width
                    height: transportDelegateRectangle.height + 2*transportDelegateRectangle.anchors.margins
                    divider.visible: true
                    color: selectedItem == id ? UbuntuColors.lightGrey : "transparent"

                    property var expanded: false

                    Component.onCompleted: {
                        if(knownList && lastUsedTransport == id) {
                            transport_selector_page.selectItemByIdLocal(id, true);
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
                                    if(id == transport_selector_page.selectedItem) {
                                        transport_selector_page.selectedItem = "";
                                        transport_selector_page.selectedName = "";
                                    }
                                    transport_selector_page.getTextFieldContentFromDB(true);
                                    transport_selector_page.confirm();
                                    transport_selector_page.update();
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
                            transport_selector_page.selectItemByIdLocal(id, true);
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
                                text: nameExt
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
                                    text: name
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
                        text: i18n.tr("Used transport types") + " (" + knownListModel.count + ")"
                        width: parent.width
                        font.italic: true
                        wrapMode: Text.WordWrap
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                visible: knownListModel.count <= 0 ? false : true
            }

            ListView {
                id: knownListView
                width: parent.width
                height: childrenRect.height
                interactive: false
                model: ListModel {
                    id: knownListModel
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
                    knownListModel.clear();

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
                            knownListModel.append({knownList: true, id: index, name: name, nameExt: nameExt, title: title, city: city, description: description, homeState: homeState, trTypes: trTypes, ttValidFrom: ttValidFrom, ttValidTo: ttValidTo});
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: UbuntuColors.lightGrey
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

                Component.onCompleted: update()

                function update() {
                    restListModel.clear();

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
                        restListModel.append({knownList: false, id: index, name: name, nameExt: nameExt, title: title, city: city, description: description, homeState: homeState, trTypes: trTypes, ttValidFrom: ttValidFrom, ttValidTo: ttValidTo});
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
