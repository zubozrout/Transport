import QtQuick 2.4
import Ubuntu.Components 1.3
import QtQuick.Layouts 1.1

import "engine.js" as Engine
import "localStorage.js" as DB

BottomEdge {
    id: bottomEdge
    height: parent.height
    hint.text: i18n.tr("Recent searches")

    contentComponent: Rectangle {
        width: bottomEdge.width
        height: bottomEdge.height
        opacity: bottomEdge.dragProgress

        PageHeader {
            id: recentPageHeader
            title: i18n.tr("Recent searches")

            StyleHints {
                foregroundColor: "#fff"
                backgroundColor: "#3949AB"
            }
        }

        Component {
            id: recentChildDelegate

            ListItem {
                width: parent.width
                divider.visible: true
                height: recentChildDelegateLayout.height + 2*recentChildDelegateLayout.anchors.margins

                RowLayout {
                    id: recentChildDelegateLayout
                    anchors {
                        centerIn: parent
                        margins: units.gu(2)
                    }
                    width: parent.width - 2*anchors.margins
                    spacing: units.gu(2)
                    Layout.fillWidth: true

                    Rectangle {
                        id: recentChildDelegateIndex
                        anchors.verticalCenter: parent.verticalCenter
                        width: units.gu(3)
                        height: width
                        color: "#fff"
                        radius: width

                        Text {
                            anchors.fill: parent
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text: (index + 1) + "."
                            font.pixelSize: FontUtils.sizeToPixels("large")
                            font.bold: true
                            wrapMode: Text.WordWrap
                        }
                    }

                    ColumnLayout {
                        anchors.margins: units.gu(2)
                        spacing: units.gu(0.25)
                        Layout.fillWidth: true

                        RowLayout {
                            width: parent.width
                            spacing: units.gu(1)
                            Layout.fillWidth: true

                            Text {
                                text: JSON.parse(typename)[Engine.langCode(true)]
                                font.pixelSize: FontUtils.sizeToPixels("small")
                                font.bold: true
                                horizontalAlignment: Text.AlignLeft
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }

                            Text {
                                text: Engine.dateToReadableFormat(new Date(date.replace(/-/g, "/")), true)
                                font.pixelSize: FontUtils.sizeToPixels("small")
                                horizontalAlignment: Text.AlignRight
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }

                        RowLayout {
                            width: parent.width
                            spacing: units.gu(1)
                            Layout.fillWidth: true

                            Text {
                                text: i18n.tr("From") + ":"
                                font.pixelSize: FontUtils.sizeToPixels("normal")
                                horizontalAlignment: Text.AlignLeft
                                Layout.fillWidth: false
                                wrapMode: Text.WordWrap
                            }

                            Text {
                                text: stopfrom
                                font.pixelSize: FontUtils.sizeToPixels("normal")
                                font.bold: true
                                horizontalAlignment: Text.AlignLeft
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                            }

                            Text {
                                text: i18n.tr("To") + ":"
                                font.pixelSize: FontUtils.sizeToPixels("normal")
                                horizontalAlignment: Text.AlignRight
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                            }

                            Text {
                                text: stopto
                                font.pixelSize: FontUtils.sizeToPixels("normal")
                                font.bold: true
                                horizontalAlignment: Text.AlignLeft
                                Layout.fillWidth: false
                                wrapMode: Text.WordWrap
                            }
                        }

                        Text {
                            text: visible ? i18n.tr("Via") + ": " + stopvia : ""
                            font.pixelSize: FontUtils.sizeToPixels("small")
                            width: parent.width
                            horizontalAlignment: Text.AlignLeft
                            wrapMode: Text.WordWrap
                            visible: typeof stopvia !== typeof undefined && stopvia ? true : false
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        transport_selector_page.selectItemById(typeid);

                        from.text = stopfrom;
                        from.coorX = stopfromx;
                        from.coorY = stopfromy;

                        to.text = stopto;
                        to.coorX = stoptox;
                        to.coorY = stoptoy;

                        if(typeof stopvia !== typeof undefined && stopvia) {
                            via.text = stopvia;
                            via.coorX = stopviax;
                            via.coorY = stopviay;
                        }

                        bottomEdge.collapse();
                    }
                }
            }
        }

        ListView {
            id: recentListView
            anchors.top: recentPageHeader.bottom
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            clip: true

            model: ListModel {
                id: recentListModel

                onCountChanged: {
                    bottomEdge.visible = count > 0 ? true : false;
                }
            }
            delegate: recentChildDelegate

            function refresh() {
                model.clear();
                var modelData = DB.getSearchHistory();
                for(var i = 0; i < modelData.length; i++) {
                    model.append(modelData[i]);
                }
            }

            Component.onCompleted: {
                refresh();
            }

            onVisibleChanged: {
                if(visible) {
                    refresh();
                }
            }

            Scrollbar {
                flickableItem: recentListView
                align: Qt.AlignTrailing
            }
        }
    }
}
