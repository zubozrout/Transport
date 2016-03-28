import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItemSelector
import QtQuick.LocalStorage 2.0

import "engine.js" as Engine
import "localStorage.js" as DB

Page {
    id: trasport_selector_page
    visible: false
    clip: true

    header: PageHeader {
        id: trasport_selector_page_header
        title: i18n.tr("Transport selector")

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

    property var selectedItem: optionsList.model_context[optionsList.selectedIndex] ? optionsList.model_context[optionsList.selectedIndex] : 0
    property var selectedName: typeModel.count > 0 && optionsList.selectedIndex < typeModel.count && typeModel.get(optionsList.selectedIndex).name ? typeModel.get(optionsList.selectedIndex).name : ""
    property var usedTypes: []

    onVisibleChanged: {
        if(visible) {
            optionsList.updateContent();
            usedTypes = DB.getAllUsedTypes();
        }
    }

    ListModel {
        id: typeModel
    }

    Component {
        id: transportOption

        ListItem {
            width: parent.width
            height: tranportLabel.contentHeight + units.gu(2)
            divider.visible: true

            Rectangle {
                anchors.fill: parent
                color: optionsList.selectedIndex == index ? UbuntuColors.lightGrey : "transparent"

                Label {
                    id: tranportLabel
                    anchors.fill: parent
                    anchors.margins: units.gu(2)
                    text: name
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.Wrap
                    font.pixelSize: {
                        if(usedTypes.indexOf(name) > -1) {
                            return FontUtils.sizeToPixels("large");
                        }
                        return FontUtils.sizeToPixels("normal");
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        optionsList.selectedIndex = index;
                        optionsList.delegateClicked(index);
                    }
                }
            }
        }
    }

    ListItemSelector.ItemSelector {
        id: optionsList
        expanded: true
        model: typeModel
        delegate: transportOption
        multiSelection: false
        selectedIndex: typeModel.count
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.top: trasport_selector_page_header.bottom
        containerHeight: height
        clip: true

        property var model_context: []
        property var userSelection: -1

        Component.onCompleted: {
            optionsList.updateContent();
            Engine.getOptions(function(response) {
                Engine.saveOptions(response);
                optionsList.updateContent();
            });
        }

        onSelectedIndexChanged: {
            getTextFieldContentFromDB(true);
            from.stationInputModel.clear();
            to.stationInputModel.clear();
            via.stationInputModel.clear();
        }

        onDelegateClicked: {
            api.abort();
            if(pageLayout != null) {
                pageLayout.removePages(trasport_selector_page);
            }
        }

        function updateContent() {
            var types = DB.getAllTypes();
            for(var i = 0; i < types.length; i++) {
                if(model_context.indexOf(types[i].id) == -1) {
                    model_context.push(types[i].id);
                    typeModel.append({name : types[i].name});
                }
                if(userSelection < 0 && types[i].name == DB.getSetting("optionsList")) {
                    selectedIndex = i;
                    userSelection = i;
                }
            }
            getTextFieldContentFromDB(false);
            if(selectedIndex >= typeModel.count) {
                selectedIndex = 0;
            }
        }

        function getTextFieldContentFromDB(force) {
            if(DB.getSetting("from" + optionsList.model_context[optionsList.selectedIndex])) {
                if(from.displayText == "" || force) {
                    from.text = DB.getSetting("from" + optionsList.model_context[optionsList.selectedIndex]);
                    from.stationInputModel.clear();
                }
            }
            else {
                from.text = "";
            }

            if(DB.getSetting("to" + optionsList.model_context[optionsList.selectedIndex])) {
                if(to.displayText == "" || force) {
                    to.text = DB.getSetting("to" + optionsList.model_context[optionsList.selectedIndex]);
                    to.stationInputModel.clear();
                }
            }
            else {
                to.text = "";
            }

            if(DB.getSetting("via" + optionsList.model_context[optionsList.selectedIndex])) {
                if(via.displayText == "" || force) {
                    via.text = DB.getSetting("via" + optionsList.model_context[optionsList.selectedIndex]);
                    via.stationInputModel.clear();
                }
            }
            else {
                via.text = "";
            }
        }
    }
}

