import QtQuick 2.4

Timer {
    id: callbackTimer
    interval: 10000
    repeat: false

    property var callback: null

    onTriggered: {
        if(typeof callback === "function") {
            callback();
        }
    }

    function go(call, time) {
        interval = time || 10000
        callback = call;
        start();
    }
}
