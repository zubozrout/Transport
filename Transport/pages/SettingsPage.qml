import QtQuick 2.4
import Ubuntu.Components 1.3

import "../components"

import "../transport-api.js" as Transport

Page {
    id: settingsPage
    header: PageHeader {
        id: pageHeader
        title: i18n.tr("Settings")
        flickable: settingsFlickable

        StyleHints {
            foregroundColor: pageLayout.colorPalete["headerText"]
            backgroundColor: pageLayout.colorPalete["headerBG"]
        }
    }

    clip: true

    Flickable {
        id: settingsFlickable
        anchors.fill: parent
        contentHeight: settingsFlickableRectangle.height

        Rectangle {
            id: settingsFlickableRectangle
            anchors {
                left: parent.left
                right: parent.right
                margins: units.gu(1)
            }
            height: childrenRect.height + 2 * anchors.margins

            Column {
                id: aboutColumn
                anchors {
                    left: parent.left
                    right: parent.right
                }
                spacing: units.gu(2)

                CustomDataList {
                    id: customDataList
                }

                Component.onCompleted: {
                    customDataList.append({
                        value: i18n.tr("Clear cache"),
                        fontScale: "large",
                        bottomBorder: false
                    });

                    customDataList.setCallbackFor(customDataList.count(), function() {
                        Transport.transportOptions.clearAll(true);
                        rowPicker.update(function(model) { rowPicker.render(model) });
                    });

                    customDataList.append({
                        value: i18n.tr("By pressing this button you'll delete all saved data including search history, cached stations and respective transport option settings."),
                        buttonIcon: "delete",
                        bottomBorder: true
                    });

                    customDataList.append({
                        value: i18n.tr("Refresh data"),
                        fontScale: "large",
                        bottomBorder: false
                    });

                    customDataList.setCallbackFor(customDataList.count(), function() {
                        transportSelectorPage.serverUpdate();
                        rowPicker.update(function(model) { rowPicker.render(model) });
                    });

                    customDataList.append({
                        value: i18n.tr("Renew all Transport options data"),
                        buttonIcon: "reload",
                        bottomBorder: true
                    });
                }

                RowPicker {
                    id: rowPicker

                    property var render: function(model) {
                        clear();

                        var options = [i18n.tr("Weekly"), i18n.tr("Daily"), i18n.tr("Everytime")];
                        var index = Transport.transportOptions.getDBSetting("check-frequency") || 0;

                        initialize(options, index, function(itemIndex) {
                            Transport.transportOptions.saveDBSetting("check-frequency", itemIndex);
                        });
                    }

                    Component.onCompleted: {
                        setTite( i18n.tr("How often would you like the transport options data to be refreshed?"));
                        rowPicker.update(function(model) { rowPicker.render(model) });
                    }
                }
            }
        }
    }

    Scrollbar {
        flickableItem: settingsFlickable
        align: Qt.AlignTrailing
    }
}
