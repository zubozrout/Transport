import QtQuick 2.4
import Ubuntu.Components 1.3
import QtQuick.Layouts 1.1
import Ubuntu.Components.Popups 1.0

import "../components"

import "../transport-api.js" as Transport
import "../generalfunctions.js" as GeneralFunctions

Page {
    id: connectionsPage
    header: PageHeader {
        id: pageHeader
        title: i18n.tr("Connections")

        StyleHints {
            foregroundColor: pageLayout.colorPalete["headerText"]
            backgroundColor: pageLayout.colorPalete["headerBG"]
        }

        trailingActionBar {
            actions: [
                Action {
                    id: trailinginfo
                    iconName: "info"
                    text: i18n.tr("Info")
                    visible: false
                    onTriggered: {
                        PopupUtils.open(infoBox);
                    }
                },
                Action {
                    id: trailingNext
                    iconName: "next"
                    text: i18n.tr("Next")
                    visible: false
                    onTriggered: {
                        var allConnections = Transport.transportOptions.getSelectedTransport().getAllConnections();
                        var currentConnectionIndex = allConnections.indexOf(connections);
                        var newConnectionIndex = currentConnectionIndex < allConnections.length - 1 ? currentConnectionIndex + 1 : 0;
                        var selectedConnection = allConnections[newConnectionIndex];
                        connections = selectedConnection;
                        renderAllConnections(selectedConnection);
                        updateConnectionDetail();

                        console.log(currentConnectionIndex, newConnectionIndex, "all:", allConnections.length);
                    }
                },
                Action {
                    id: trailingPrevious
                    iconName: "previous"
                    text: i18n.tr("Previous")
                    visible: false
                    onTriggered: {
                        var allConnections = Transport.transportOptions.getSelectedTransport().getAllConnections();
                        var currentConnectionIndex = allConnections.indexOf(connections);
                        var newConnectionIndex = currentConnectionIndex > 0 ? currentConnectionIndex - 1 : allConnections.length - 1;
                        var selectedConnection = allConnections[newConnectionIndex];
                        connections = selectedConnection;
                        renderAllConnections(selectedConnection);
                        updateConnectionDetail();

                        console.log(currentConnectionIndex, newConnectionIndex, "all:", allConnections.length);
                    }
                }
            ]
            numberOfSlots: 4
        }
    }

    clip: true

    property var connections: null
    property var transport: null
    property string overviewText: ""

    onVisibleChanged: {
        if(visible) {
            var currentTransport = Transport.transportOptions.getSelectedTransport();
            if(currentTransport) {
                if(transport !== null && transport !== currentTransport) {
                    var allConnections = currentTransport.getAllConnections();
                    if(allConnections.length > 0) {
                        renderAllConnections(allConnections[0]);
                    }
                    else {
                        connectionsModel.clearAll();
                    }
                    enableHeaderButtons(allConnections);
                }
                transport = currentTransport;
            }

            updateConnectionDetail();
        }
    }

    function updateConnectionDetail() {
        if(Transport.transportOptions.getSelectedTransport()) {
            var allConnections = Transport.transportOptions.getSelectedTransport().getAllConnections();
            if(allConnections.length > 0) {
                var currentConnectionIndex = allConnections.indexOf(connections);
                var currentConnection = allConnections[currentConnectionIndex];

                if(currentConnection) {
                    var from = "";
                    if(currentConnection.from) {
                        from = (currentConnection.from.getName());
                    }
                    var to = "";
                    if(currentConnection.to) {
                        to = (currentConnection.to.getName());
                    }
                    var via = "";
                    if(currentConnection.via) {
                        via = (currentConnection.via.getName());
                    }

                    var connectionsLength = currentConnection.connections.length;

                    var finalText = i18n.tr("Journey start: %1", from).arg(from) + "\n";
                    finalText += i18n.tr("Journey end: %1", to).arg(to) + "\n";
                    finalText += (via ? i18n.tr("Transfering at: %1", via).arg(via) + "\n" : "");
                    finalText += i18n.tr("Number of results: %1", connectionsLength).arg(connectionsLength) + "\n";
                    this.overviewText = finalText;

                    return true;
                }
            }
        }
        return false;
    }

    function enableHeaderButtons(connections) {
        if(connections.length > 1) {
            trailingNext.visible = true;
            trailingPrevious.visible = true;
        }
        else {
            trailingNext.visible = false;
            trailingPrevious.visible = false;
        }

        if(connections.length > 0) {
            trailinginfo.visible = true;
        }
        else {
            trailinginfo.visible = false;
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
                updateConnectionDetail();
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
                updateConnectionDetail();
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

    Component {
        id: infoBox

        Dialog {
            id: infoBoxDialogue
            title: i18n.tr("Connection overview info")
            text: connectionsPage.overviewText
            Button {
                text: i18n.tr("Ok")
                onClicked: PopupUtils.close(infoBoxDialogue)
            }
        }
    }

    CallbackTimer {
        id: loadTimeout
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

    Rectangle {
        id: pullInfo
        anchors {
            top: pageHeader.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        color: Qt.rgba(255, 255, 255, 0.8)
        z: 10
        visible: false

        Label {
            anchors {
                centerIn: parent
                margins: units.gu(2)
            }
            text: i18n.tr("Keep pulled to load more")
        }
    }
    
    ErrorMessage {
		id: errorMessage
		anchors.top: pageHeader.bottom
	}

    Flickable {
        id: connectionsFlickable
        anchors {
			top: errorMessage.bottom
			right: parent.right
			bottom: parent.bottom
			left: parent.left
		}
        contentWidth: parent.width
        contentHeight: connectionsView.contentHeight

        property var sensitivity: 150
        clip: true

        function checkDrag() {
            if(contentHeight > 0 && progressLine.state == "idle") {
                var topEdge = contentY + pageHeader.height;
                var bottomEdge = topEdge + height - pageHeader.height;

                if(bottomEdge > contentHeight + sensitivity) {
                    // Load more (next) connections;
                    return "append";
                }

                if(topEdge < -sensitivity) {
                    // Load more (previous) connections;
                    return "prepend";
                }
            }
            return false;
        }

        function drag() {
            var drag = connectionsFlickable.checkDrag();
            if(drag === "append") {
                connectionsPage.appendConnections();
                return true;
            }
            else if(drag === "prepend") {
                connectionsPage.prependConnections();
                return true;
            }
            return;
        }

        onContentYChanged: {
            if(connectionsFlickable.checkDrag()) {
                if(!dragTimer.running) {
                    pullInfo.visible = true;
                    dragTimer.go(function() {
                        pullInfo.visible = false;
                        connectionsFlickable.drag();
                    }, 750);
                }
            }
        }

        CallbackTimer {
            id: dragTimer
        }

        ListView {
            id: connectionsView
            anchors.fill: parent
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
