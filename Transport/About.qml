import QtQuick 2.4
import Ubuntu.Components 1.3

import "localStorage.js" as DB

Page {
    id: about_page
    title: i18n.tr("O Aplikaci")
    visible: false
    clip: true
    head.locked: true

    Flickable {
        id: about_page_flickable
        anchors.fill: parent
        contentHeight: about_page_column.childrenRect.height + 2*about_page_column.anchors.margins
        contentWidth: parent.width

        Column {
            id: about_page_column
            anchors {
                fill: parent
                margins: units.gu(2)
            }
            width: parent.width
            spacing: units.gu(2)

            Text {
                anchors.right: parent.right
                text: i18n.tr("Verze hlavní větve") + ": " + "0.7"
                wrapMode: Text.Wrap
                font.pixelSize: FontUtils.sizeToPixels("small")
            }

            Image {
                id: aboutImage
                source: "tram.svg"
                width: units.gu(35)
                height: width
                fillMode: Image.PreserveAspectFit
                sourceSize.width: width
                anchors.horizontalCenter: parent.horizontalCenter

                RotationAnimator {
                    id: easterEggAnim
                    target: aboutImage
                    from: 0
                    to: 10 * (Math.round(Math.random())%2 == 0 ? 360 : -360)
                    duration: 4000
                    running: false
                    easing.type: Easing.InOutElastic
                }

                Timer {
                    id: easterEggTimer
                    interval: Math.floor(easterEggAnim.duration/2)
                    running: false
                    repeat: false
                    triggeredOnStart: false
                    onTriggered: {
                        parent.width += (parent.width <= parent.parent.width - units.gu(2)) ? units.gu(2) : 0;
                        parent.mirror = !parent.mirror;
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    property int badCounter: 0
                    onDoubleClicked: {
                        if(badCounter > 10) {
                            headerColor = Qt.rgba(Math.random(), Math.random(), Math.random(), 1);
                            DB.saveSetting("user_color", headerColor);
                        }
                        if(!easterEggAnim.running) {
                            easterEggAnim.start();
                            easterEggTimer.start();
                        }
                        else {
                            badCounter++;
                        }
                    }
                }
            }

            Text {
                width: parent.width
                text: i18n.tr("Transport") + " - " + i18n.tr("Jízdní řády")
                wrapMode: Text.Wrap
                font.pixelSize: FontUtils.sizeToPixels("x-large")
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                width: parent.width
                text: i18n.tr("Tato aplikace využívá API jehož dokumentace je dostupná na adrese http://docs.crws.apiary.io/") + "\n\n\"" + i18n.tr("Službu provozuje společnost CHAPS spol. s.r.o., identifikátor klienta žádejte na info@chaps.cz.") + "\"";
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
            }

            Rectangle {
                color: "#ddd"
                width: parent.width
                anchors.horizontalCenter: parent.horizontalCenter
                height: 1
            }

            Text {
                width: parent.width
                text: i18n.tr("Martin Kozub, @zubozrout")
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: FontUtils.sizeToPixels("small")

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        Qt.openUrlExternally("https://github.com/zubozrout/Transport");
                    }
                }
            }
        }
    }

    Scrollbar {
        flickableItem: about_page_flickable
        align: Qt.AlignTrailing
    }
}

