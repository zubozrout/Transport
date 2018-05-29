import QtQuick 2.4
import Transport 1.0

Api {
    id: api

    property var callback: null

    onResponseChanged: {
        if(callback && response) {
            callback({
                response: response,
                statusCode: statusCode
            });
        }
        else if(callback && !response) {
            console.log("server not responing");
            callback({
                statusCode: "OFFLINE"
            });
        }
        callback = null;
    }

    function abort() {
        if(running && callback) {
            callback = null;
            request = "";
        }
    }
}
