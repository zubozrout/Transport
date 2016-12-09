import QtQuick 2.4
import Ubuntu.Components 1.3
import QtQuick.Layouts 1.1

import "../components"

import "../transport-api.js" as Transport
import "../generalfunctions.js" as GeneralFunctions

Page {
    id: connectionsPage
    header: PageHeader {
        id: pageHeader
        title: i18n.tr("Connections")
        flickable: connectionsFlickable

        StyleHints {
            foregroundColor: "#fff"
            backgroundColor: pageLayout.headerColor
        }

        trailingActionBar {
            actions: [
                Action {
                    iconName: "next"
                    text: i18n.tr("Next")
                    onTriggered: {
                        var allConnections = Transport.transportOptions.getSelectedTransport().getAllConnections();
                        var currentConnectionIndex = allConnections.indexOf(connections);
                        var newConnectionIndex = currentConnectionIndex < allConnections.length - 1 ? currentConnectionIndex + 1 : 0;
                        var selectedConnection = allConnections[newConnectionIndex];
                        connections = selectedConnection;
                        renderAllConnections(selectedConnection);
                    }
                },
                Action {
                    iconName: "previous"
                    text: i18n.tr("Previous")
                    onTriggered: {
                        var allConnections = Transport.transportOptions.getSelectedTransport().getAllConnections();
                        var currentConnectionIndex = allConnections.indexOf(connections);
                        var newConnectionIndex = currentConnectionIndex > 0 ? currentConnectionIndex - 1 : allConnections.length - 1;
                        var selectedConnection = allConnections[newConnectionIndex];
                        connections = selectedConnection;
                        renderAllConnections(selectedConnection);
                    }
                }
           ]
        }
    }

    clip: true

    property var connections: null
    property var transport: null

    onVisibleChanged: {
        if(visible) {
            var currentTransport = Transport.transportOptions.getSelectedTransport();
            if(transport !== null && transport !== currentTransport) {
                var connections = currentTransport.getAllConnections();
                if(connections.length > 0) {
                    renderAllConnections(connections[0]);
                }
            }
            transport = Transport.transportOptions.getSelectedTransport();
        }
    }

    function appendConnections() {
        if(connectionsPage.connections) {
            progressLine.state = "running";

            loadTimeout.go(function() {
                if(progressLine.state === "running") {
                    connectionsPage.connections.abort();
                    progressLine.state = "idle";
                    errorMessage.value = i18n.tr("Loading following connections timed out");
                }
            });

            connectionsPage.connections.getNext(false, function(connection, state) {
                if(state === "SUCCESS") {
                    insertConnectionsRender(connection.getLastConnections());
                }
                else if(state !== "ABORT") {
                    errorMessage.value = i18n.tr("Loading following connections failed");
                }
                progressLine.state = "idle";
            });
        }
    }

    function prependConnections() {
        if(connectionsPage.connections) {
            progressLine.state = "running";

            loadTimeout.go(function() {
                if(progressLine.state === "running") {
                    connectionsPage.connections.abort();
                    progressLine.state = "idle";
                    errorMessage.value = i18n.tr("Loading previous connections timed out");
                }
            });

            connectionsPage.connections.getNext(true, function(connection, state) {
                if(state === "SUCCESS") {
                    var prevLength = connectionsModel.count;

                    renderAllConnections(connection);
                    connectionsView.forceLayout();

                    var newItemsCount = connection.connections.length - prevLength;

                    var topSize = 0;
                    var iterator = 0;
                    for(var child in connectionsView.contentItem.children) {
                        if(iterator >= newItemsCount) {
                            break;
                        }

                        topSize += connectionsView.contentItem.children[child].height;
                        iterator++;
                    }

                    connectionsFlickable.contentY = topSize;
                }
                else if(state !== "ABORT") {
                    errorMessage.value = i18n.tr("Loading previous connections failed");
                }
                progressLine.state = "idle";
            });
        }
    }

    function renderAllConnections(connection) {
        if(connection) {
            connectionsModel.clearAll();
            insertConnectionsRender(connection.connections);
        }
    }

    function insertConnectionsRender(connections) {
        if(connections) {
            for(var i = 0; i < connections.length; i++) {
                connectionsModel.append({
                    distance: connections[i].getDistance(),
                    timeLength: connections[i].getTimeLength()
                });
                connectionsModel.childModel.push(connections[i]);
            }
        }
    }

    Timer {
        id: loadTimeout
        interval: 10000
        repeat: false

        property var callback: null

        onTriggered: {
            if(typeof callback === "function") {
                callback();
            }
        }

        function go(call) {
            callback = call;
            start();
        }
    }

    ConnectionsDelegate {
        id: connectionsDelegate
    }

    RoutesDelegate {
        id: routesDelegate
    }

    ProgressLine {
        id: progressLine
        anchors {
            top: pageHeader.bottom
        }
        z: 10
    }

    Flickable {
        id: connectionsFlickable
        anchors.fill: parent
        contentWidth: parent.width
        contentHeight: errorMessage.height + connectionsView.contentHeight

        property var sensitivity: 150
        property var topblock: false
        property var bottomblock: false

        onContentYChanged: {
            if(contentHeight > 0 && progressLine.state == "idle") {
                var topEdge = contentY + pageHeader.height;
                var bottomEdge = topEdge + height - pageHeader.height;
                if(!bottomblock) {
                    if(bottomEdge > contentHeight + sensitivity) {
                        // Load more (next) connections;
                        connectionsPage.appendConnections();
                        bottomblock = true;
                    }
                }
                if(!topblock) {
                    if(topEdge < -sensitivity) {
                        // Load more (previous) connections;
                        connectionsPage.prependConnections();
                        topblock = true;
                    }
                }
                if(bottomblock || topblock) {
                    if(bottomEdge <= contentHeight) {
                        bottomblock = false;
                    }
                    if(topEdge >= 0) {
                        topblock = false;
                    }
                }
            }
        }

        ErrorMessage {
            id: errorMessage
        }

        ListView {
            id: connectionsView
            anchors {
                top: errorMessage.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }

            interactive: false
            delegate: connectionsDelegate

            model: ListModel {
                id: connectionsModel
                property var childModel: []

                function clearAll() {
                    this.clear();
                    this.childModel = [];
                }
            }
        }
    }

    Scrollbar {
        flickableItem: connectionsFlickable
        align: Qt.AlignTrailing
    }
}
