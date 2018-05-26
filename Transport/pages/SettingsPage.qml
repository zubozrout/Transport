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
                        rowPickerA.update(function(model) { rowPickerA.render(model) });
                        rowPickerB.update(function(model) { rowPickerB.render(model) });
                        rowPickerC.update(function(model) { rowPickerC.render(model) });
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
                        rowPickerA.update(function(model) { rowPickerA.render(model) });
                        rowPickerB.update(function(model) { rowPickerB.render(model) });
                        rowPickerC.update(function(model) { rowPickerC.render(model) });
                    });

                    customDataList.append({
                        value: i18n.tr("Renew all Transport options data"),
                        buttonIcon: "reload",
                        bottomBorder: true
                    });
                }
                
                RowPicker {
                    id: rowPickerA

                    property var render: function(model) {
                        clear();

                        var options = [i18n.tr("Yes"), i18n.tr("No")];
                                                
                        var index = Number(Transport.transportOptions.getDBSetting("geolocation-on-start") || 0)

                        initialize(options, index, function(itemIndex) {
                            Transport.transportOptions.saveDBSetting("geolocation-on-start", itemIndex);
                        });
                    }

                    Component.onCompleted: {
                        setTite(i18n.tr("Use GeoLocation search on start?"));
                        rowPickerA.update(function(model) { rowPickerA.render(model) });
                    }
                }
                
                RowPicker {
                    id: rowPickerB

                    property var render: function(model) {
                        clear();

                        var options = [i18n.tr("Yes"), i18n.tr("No")];
                                                
                        var index = Number(Transport.transportOptions.getDBSetting("connection-detail-coords") || 0)

                        initialize(options, index, function(itemIndex) {
                            Transport.transportOptions.saveDBSetting("connection-detail-coords", itemIndex);
                        });
                    }

                    Component.onCompleted: {
                        setTite(i18n.tr("Download route map coords with every connection detail query"));
                        rowPickerB.update(function(model) { rowPickerB.render(model) });
                    }
                }

                RowPicker {
                    id: rowPickerC

                    property var render: function(model) {
                        clear();

                        var options = [i18n.tr("Weekly"), i18n.tr("Daily"), i18n.tr("Everytime"), i18n.tr("Never")];
                        var index = Number(Transport.transportOptions.getDBSetting("check-frequency") || 0);

                        initialize(options, index, function(itemIndex) {
                            Transport.transportOptions.saveDBSetting("check-frequency", itemIndex);
                        });
                    }

                    Component.onCompleted: {
                        setTite(i18n.tr("How often would you like the transport options data to be refreshed?"));
                        rowPickerC.update(function(model) { rowPickerC.render(model) });
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
