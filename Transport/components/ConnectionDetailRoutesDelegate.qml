import QtQuick 2.4
import Ubuntu.Components 1.3
import QtQuick.Layouts 1.1

import "../generalfunctions.js" as GeneralFunctions

Component {
    id: connectionDetailRoutesDelegate

    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
        }
        visible: !stopPassed && connectionDetailSections.selectedIndex === 0 ? false : true
        height: visible ? stationColumn.height : true
        color: index%2 === 0 ? "transparent" : pageLayout.colorPalete.highlightBG

        Row {
            id: stationColumn
            anchors {
                left: parent.left
                right: parent.right
                leftMargin: units.gu(2)
                rightMargin: units.gu(2)
            }
            spacing: units.gu(1)

            Rectangle {
                id: positionIndicator
                anchors.verticalCenter: parent.verticalCenter
                width: units.gu(1.5)
                height: width
                color: pageLayout.colorPalete["headerBG"]
                radius: width
                opacity: 0

                Timer {
                    repeat: true
                    interval: 5000
                    triggeredOnStart: true
                    running: visible
                    onTriggered: {
                        if(checkStationPassed()) {
                            positionIndicator.opacity = 1;
                        }
                        else {
                            positionIndicator.opacity = 0;
                        }
                    }

                    function checkStationPassed() {
                        var currentDate = new Date();
                        if(arrTime) {
                            if(new Date(arrTime) <= currentDate) {
                                return true;
                            }
                            return false;
                        }
                        if(depTime) {
                            if(new Date(depTime) <= currentDate) {
                                return true;
                            }
                            return false;
                        }
                    }
                }
            }

            Label {
                text: station.name || ""
                font.pixelSize: FontUtils.sizeToPixels("normal")
                font.bold: stopPassed ? true : false
                horizontalAlignment: Text.AlignLeft
                wrapMode: Text.WordWrap
                width: parent.width/2
            }

            Label {
                text: GeneralFunctions.dateToTimeString(arrTime)
                font.pixelSize: FontUtils.sizeToPixels("normal")
                font.bold: stopPassed ? true : false
                horizontalAlignment: Text.AlignLeft
                wrapMode: Text.WordWrap
                width: parent.width/4 - parent.spacing
            }

            Label {
                text: GeneralFunctions.dateToTimeString(depTime)
                font.pixelSize: FontUtils.sizeToPixels("normal")
                font.bold: stopPassed ? true : false
                horizontalAlignment: Text.AlignLeft
                wrapMode: Text.WordWrap
                width: parent.width/4 - parent.spacing
            }            
        }
    }
}
