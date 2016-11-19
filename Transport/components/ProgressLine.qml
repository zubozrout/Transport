import QtQuick 2.4
import Ubuntu.Components 1.3

Rectangle {
    id: progressLine
    width: parent.width
    height: units.gu(0.5)
    color: "transparent"

    states: [
        State {
            name: "idle"
            PropertyChanges { target: animation; running: false }
            PropertyChanges { target: progressLine; visible: false }
        },
        State {
            name: "running"
            PropertyChanges { target: animation; running: true }
            PropertyChanges { target: progressLine; visible: true }
        }
    ]

    state: "idle"

    Rectangle {
        id: flyer
        width: parent.width / 3
        height: parent.height
        color: UbuntuColors.orange

        property var xStart: 0
        property var xEnd: progressLine.width - width

        SequentialAnimation on x {
            id: animation
            loops: Animation.Infinite

            NumberAnimation {
                from: flyer.xStart; to: flyer.xEnd
                easing.type: Easing.InOutCubic; duration: 600
            }
            NumberAnimation {
                from: flyer.xEnd; to: flyer.xStart
                easing.type: Easing.InOutCubic; duration: 1000
            }
        }
    }
}
