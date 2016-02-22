import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.ListItems 1.3 as ListItem
import QtQuick.LocalStorage 2.0

import "engine.js" as Engine
import "localStorage.js" as DB

Page {
    id: trasport_selector_page
    title: i18n.tr("Výběr dopravce")
    visible: false
    clip: true
    head.locked: true

    property var selectedItem: optionsList.model_context[optionsList.selectedIndex] ? optionsList.model_context[optionsList.selectedIndex] : 0
    property var selectedName: typeModel.count > 0 && optionsList.selectedIndex < typeModel.count && typeModel.get(optionsList.selectedIndex).name ? typeModel.get(optionsList.selectedIndex).name : ""

    ListModel {
        id: typeModel
    }

    ListItem.ItemSelector {
        id: optionsList
        expanded: true
        model: typeModel
        multiSelection: false
        containerHeight: parent.height
        selectedIndex: typeModel.count

        property var model_context: []

        Component.onCompleted: {
            optionsList.updateContent();
            Engine.getOptions(function(response) {
                Engine.saveOptions(response);
                optionsList.updateContent();
            });
        }

        onSelectedIndexChanged: {
            getTextFieldContentFromDB(true);
            from_list_model.clear();
            to_list_model.clear();
            via_list_model.clear();
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
                if(types[i].name == DB.getSetting("optionsList")) {
                    selectedIndex = i;
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
                    from_list_model.clear();
                }
            }
            else {
                from.text = "";
            }

            if(DB.getSetting("to" + optionsList.model_context[optionsList.selectedIndex])) {
                if(to.displayText == "" || force) {
                    to.text = DB.getSetting("to" + optionsList.model_context[optionsList.selectedIndex]);
                    to_list_model.clear();
                }
            }
            else {
                to.text = "";
            }

            if(DB.getSetting("via" + optionsList.model_context[optionsList.selectedIndex])) {
                if(via.displayText == "" || force) {
                    via.text = DB.getSetting("via" + optionsList.model_context[optionsList.selectedIndex]);
                    via_list_model.clear();
                }
            }
            else {
                via.text = "";
            }
        }
    }
}

