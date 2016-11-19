import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Pickers 1.0

import "../transport-api.js" as Transport

Column {
    id: datetimePicker
    anchors {
        left: parent.left
        right: parent.right
    }
    spacing: units.gu(1)

    property var pickerHeight: units.gu(14)
    property var datePicker: dateYMDPicker
    property var timePicker: dateHMPicker

    DatePicker {
        id: dateYMDPicker
        mode: "Years|Months|Days"
        anchors.horizontalCenter: parent.horizontalCenter
        height: datetimePicker.pickerHeight
        date: new Date()

        property bool customDateSet: false

        onVisibleChanged: {
            if(!customDateSet) {
                var selectedTransport = Transport.transportOptions.getSelectedTransport();
                if(selectedTransport) {
                    minimum = selectedTransport.getValidity().from;
                    maximum = selectedTransport.getValidity().to;

                    var currentDate = new Date();
                    if(minimum <= currentDate <= maximum) {
                        date = currentDate;
                    }

                    customDateSet = true;
                }
            }
        }
    }

    DatePicker {
        id: dateHMPicker
        mode: "Hours|Minutes"
        anchors.horizontalCenter: parent.horizontalCenter
        height: datetimePicker.pickerHeight
        date: new Date()
    }

    Label {
        text: i18n.tr("Selected date:") + " " + Qt.formatDate(dateYMDPicker.date, "dd.MM.yyyy") + ", " + Qt.formatTime(dateHMPicker.date, "hh:mm")
        width: parent.width
        font.pixelSize: FontUtils.sizeToPixels("normal")
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        color: pageLayout.baseTextColor
    }
}
