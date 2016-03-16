import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Pickers 1.0
import Ubuntu.Components.ListItems 1.3 as ListItem
import QtQuick.LocalStorage 2.0
import Ubuntu.Components.Popups 1.0

import "engine.js" as Engine
import "localStorage.js" as DB

Page {
    id: settings_page
    visible: false
    clip: true

    header: PageHeader {
        id: settings_page_header
        title: i18n.tr("Settings")
        flickable: settings_flickable

        StyleHints {
            foregroundColor: "#fff"
            backgroundColor: "#3949AB"
        }
    }

    onVisibleChanged: {
        if(visible) {
            savedBgColorSwitch.checkForSavedColor();
        }
    }

    Flickable {
        id: settings_flickable
        anchors.fill: parent
        contentHeight: settings_page_column.childrenRect.height + 2*settings_page_column.anchors.margins
        contentWidth: parent.width

        Column {
            id: settings_page_column
            anchors {
                fill: parent
                margins: units.gu(2)
            }
            spacing: units.gu(2)

            Label {
                id: settings_public_transport_count_label
                width: parent.width
                text: i18n.tr("Count of fetched connections per page")
                wrapMode: Text.WordWrap
            }

            Row {
                spacing: units.gu(2)
                anchors.horizontalCenter: parent.horizontalCenter

                TextField {
                    id: settings_transport_count_text
                    inputMethodHints: Qt.ImhFormattedNumbersOnly

                    function validation() {
                        var tmptext = !DB.getSetting("settings_transport_count") || isNaN(DB.getSetting("settings_transport_count")) || parseInt(DB.getSetting("settings_transport_count")) < 1 ? "10" : parseInt(DB.getSetting("settings_transport_count"));
                        DB.saveSetting("settings_transport_count", tmptext);
                        return tmptext;
                    }

                    Component.onCompleted: {
                        text = validation();
                    }

                    onTextChanged: {
                        DB.saveSetting("settings_transport_count", text);
                        validation();
                    }

                    onFocusChanged: {
                        text = validation();
                    }
                }
            }

            Label {
                id: show_all_or_passed_label
                width: parent.width
                text: i18n.tr("Display all line stops in the connection detail?")
                wrapMode: Text.WordWrap
            }

            Row {
                spacing: units.gu(2)
                anchors.horizontalCenter: parent.horizontalCenter

                Switch {
                    id: show_all_or_passed_switch
                    checked: true

                    Component.onCompleted: {
                        checked = DB.getSetting("settings_show_all_or_passed");
                        DB.saveSetting("settings_show_all_or_passed", checked);
                    }

                    onCheckedChanged: {
                        DB.saveSetting("settings_show_all_or_passed", checked);
                    }
                }
            }

            Label {
                id: fetch_transport_options_on_each_start_label
                width: parent.width
                text: i18n.tr("Download and refresh all transport options on each application start?")
                wrapMode: Text.WordWrap
            }

            Row {
                spacing: units.gu(2)
                anchors.horizontalCenter: parent.horizontalCenter

                Switch {
                    id: fetch_transport_options_on_each_start_switch
                    checked: true

                    Component.onCompleted: {
                        checked = DB.getSetting("fetch_transport_options_on_each_start");
                        DB.saveSetting("fetch_transport_options_on_each_start", checked);
                    }

                    onCheckedChanged: {
                        DB.saveSetting("fetch_transport_options_on_each_start", checked);
                    }
                }
            }

            Row {
                spacing: units.gu(2)
                anchors.horizontalCenter: parent.horizontalCenter

                Button {
                    id: fetch_transport_options_now
                    text: i18n.tr("Refresh transport options")
                    color: "#3949AB"

                    onClicked: {
                        Engine.fetchTrasports(function(response) {
                            Engine.saveOptions(response);
                        });
                    }
                }
            }

            Item {
                height: childrenRect.height
                width: parent.width
                visible: savedBgColorSwitch.checked

                Column {
                    width: parent.width
                    spacing: units.gu(2)

                    Label {
                        id: savedBgColor
                        width: parent.width
                        text: i18n.tr("Keep background color saved")
                        wrapMode: Text.WordWrap
                    }

                    Row {
                        spacing: units.gu(2)
                        anchors.horizontalCenter: parent.horizontalCenter

                        Switch {
                            id: savedBgColorSwitch
                            checked: true

                            function checkForSavedColor() {
                                checked = DB.getSetting("user_color") != null ? true : false;
                                if(checked) {
                                    backgroundColor = DB.getSetting("user_color");
                                }
                            }

                            Component.onCompleted: {
                                checkForSavedColor();
                            }

                            onCheckedChanged: {
                                if(!checked) {
                                    DB.saveSetting("user_color", null);
                                    backgroundColor = "#fff";
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: "#ddd"
            }

            Row {
                spacing: units.gu(2)
                anchors.horizontalCenter: parent.horizontalCenter

                Button {
                    id: button_clear_cache
                    text: i18n.tr("Clear cache")
                    color: UbuntuColors.red
                    onClicked: PopupUtils.open(confirm_clearcache_dialog)
                }
                Component {
                    id: confirm_clearcache_dialog
                    Dialog {
                        id: confirm_clearcache_dialogue
                        title: i18n.tr("Attention")
                        text: i18n.tr("Do you really want to clear all application data?")
                        Button {
                            text: i18n.tr("No")
                            onClicked: PopupUtils.close(confirm_clearcache_dialogue)
                        }
                        Button {
                            text: i18n.tr("Yes")
                            color: UbuntuColors.red
                            onClicked: {
                                DB.clearLocalStorage();
                                PopupUtils.close(confirm_clearcache_dialogue);
                            }
                        }
                    }
                }
            }
        }
    }

    Scrollbar {
        flickableItem: settings_flickable
        align: Qt.AlignTrailing
    }
}
