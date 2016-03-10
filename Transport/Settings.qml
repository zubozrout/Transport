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
        title: i18n.tr("Nastavení")
        flickable: settings_flickable

        trailingActionBar {
            actions: [
                Action {
                    iconName: "save"
                    text: i18n.tr("Uložit")
                    onTriggered: {
                        saveSettings();
                        settingsAnim.start();
                    }
                }
            ]
        }

        StyleHints {
            foregroundColor: "#fff"
            backgroundColor: "#3949AB"
        }
    }


    function saveSettings() {
        // transport count
        if(!isNaN(settings_transport_count_text.text) && (settings_transport_count_text.text > 0 && settings_transport_count_text.text < 100)) {
            DB.saveSetting("settings_transport_count", settings_transport_count_text.text);
        }
        else {
            settings_transport_count_text.text = DB.getSetting("settings_transport_count");
        }

        // settings_show_all_or_passed
        DB.saveSetting("settings_show_all_or_passed", show_all_or_passed_switch.checked);

        // settings_fetch_transport_options_on_each_start
        DB.saveSetting("fetch_transport_options_on_each_start", fetch_transport_options_on_each_start_switch.checked);
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
                text: i18n.tr("Počet vyhledávaných spojení na stránku")
                wrapMode: Text.WordWrap
            }

            Row {
                spacing: units.gu(2)
                anchors.horizontalCenter: parent.horizontalCenter

                TextField {
                    id: settings_transport_count_text
                    inputMethodHints: Qt.ImhFormattedNumbersOnly

                    Component.onCompleted: {
                        text = DB.getSetting("settings_transport_count") == null || isNaN(DB.getSetting("settings_transport_count")) ? "10" : DB.getSetting("settings_transport_count");
                        DB.saveSetting("settings_transport_count", text);
                    }
                }
            }

            Label {
                id: show_all_or_passed_label
                width: parent.width
                text: i18n.tr("Zobrazovat v detailu spojení ve výchozím stavu všechny zastávky projížděné danými linkami?")
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
                }
            }

            Label {
                id: fetch_transport_options_on_each_start_label
                width: parent.width
                text: i18n.tr("Stahovat seznam dostupných dopravců při každém startu aplikace?")
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
                }
            }

            Row {
                spacing: units.gu(2)
                anchors.horizontalCenter: parent.horizontalCenter

                Button {
                    id: fetch_transport_options_now
                    text: i18n.tr("Obnovit seznam dopravců")
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
                        text: i18n.tr("Ponechat uloženu barvu pozadí")
                        wrapMode: Text.WordWrap
                    }

                    Row {
                        spacing: units.gu(2)
                        anchors.horizontalCenter: parent.horizontalCenter

                        Switch {
                            id: savedBgColorSwitch
                            checked: true

                            Component.onCompleted: {
                                checked = DB.getSetting("user_color") != null ? true : false;
                                if(checked) {
                                    headerColor = DB.getSetting("user_color");
                                }
                            }

                            onCheckedChanged: {
                                if(!checked) {
                                    DB.saveSetting("user_color", null);
                                    headerColor = "transparent";
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
                    text: i18n.tr("Vymazat mezipaměť")
                    color: UbuntuColors.red
                    onClicked: PopupUtils.open(confirm_clearcache_dialog)
                }
                Component {
                    id: confirm_clearcache_dialog
                    Dialog {
                        id: confirm_clearcache_dialogue
                        title: i18n.tr("Pozor!")
                        text: i18n.tr("Sktečně chcete vymazat veškerá uložená data této aplikace?")
                        Button {
                            text: i18n.tr("Ne")
                            onClicked: PopupUtils.close(confirm_clearcache_dialogue)
                        }
                        Button {
                            text: i18n.tr("Ano")
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

    Rectangle {
        id: settingsSaveStatus
        anchors.fill: parent
        color: "#fff"
        opacity: 0
        visible: opacity == 0 ? false : true

        Icon {
            anchors.centerIn: parent
            width: parent.width > parent.height ? parent.height : parent.width
            height: width
            name: "ok"
            color: UbuntuColors.green
        }

        SequentialAnimation on opacity {
            id: settingsAnim
            running: false
            loops: 1
            NumberAnimation { from: 0; to: 1; duration: 1000; easing.type: Easing.InOutQuad }
            PauseAnimation { duration: 2000; }
            NumberAnimation { from: 1; to: 0; duration: 5000; easing.type: Easing.InOutQuad }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                settingsAnim.stop();
                parent.opacity = 0;
            }
        }
    }
}
