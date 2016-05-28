import QtQuick 2.4
import Ubuntu.Components 1.3

import "localStorage.js" as DB

Page {
    id: about_page
    visible: false
    clip: true

    header: PageHeader {
        id: about_page_header
        title: i18n.tr("About")
        flickable: about_page_flickable

        StyleHints {
            foregroundColor: "#fff"
            backgroundColor: "#3949AB"
        }
    }

    Flickable {
        id: about_page_flickable
        anchors.fill: parent
        contentHeight: about_page_column.childrenRect.height + (2 * about_page_column.anchors.margins)
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
                text: i18n.tr("Main branch version:") + " " + "0.9"
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
                    duration: 5000
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
                            backgroundColor = Qt.rgba(Math.random(), Math.random(), Math.random(), 1);
                            DB.saveSetting("user_color", backgroundColor);
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
                text: i18n.tr("Transport") + " - " + i18n.tr("Timetables")
                wrapMode: Text.Wrap
                font.pixelSize: FontUtils.sizeToPixels("x-large")
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                width: parent.width
                text: i18n.tr("This application is based upon an API provided by CHAPS s.r.o. company.") + " info@chaps.cz\n\n" + i18n.tr("You can find the documentation of the API service here http://docs.crws.apiary.io/");
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
                text: i18n.tr("Thank you everyone who helped translating this app.");
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
                text: "Martin Kozub, @zubozrout"
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

