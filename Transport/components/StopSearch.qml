import QtQuick 2.4
import Ubuntu.Components 1.3
import QtQuick.Layouts 1.1

import "../transport-api.js" as Transport
import "../generalfunctions.js" as GeneralFunctions

Item {
    id: searchItem
    width: parent.width
    height: childrenRect.height

    property var selectedStop: null
    property var value: textField.displayText
    property var running: itemActivity.running

    function getData() {
        var model = [];
        for(var i = 0; i < optionsModel.count; i++) {
            model.push({item: optionsModel.get(i).item, name: optionsModel.get(i).name});
        }

        return {
            model: model,
            selectedStop: selectedStop,
            value: value
        };
    }

    function setData(data) {
        data = data || {};
        if(data.value) {
            textField.setTextWithNoSignal(data.value);
        }
        if(typeof data.model !== typeof undefined && data.model.length > 0) {
            optionsModel.clear();
            for(var i = 0; i < data.model.length; i++) {
                optionsModel.append(data.model[i]);
            }
        }
        if(typeof data.selectedStop !== typeof undefined) {
            selectedStop = data.selectedStop;
        }
    }

    function empty() {
        textField.text = "";
        optionsModel.clear();
    }

    ColumnLayout {
        anchors {
            left: parent.left
            right: parent.right
        }
        spacing: 0

        TextField {
            id: textField
            anchors {
                left: parent.left
                right: parent.right
            }
            placeholderText: i18n.tr("station name")

            property bool noSignal: false
            property var cityOptions: null
            property var lastTextValue: null

            onDisplayTextChanged: {
                if(lastTextValue !== textField.displayText) {
                    textChange();
                }
                lastTextValue = textField.displayText;
            }

            onFocusChanged: {
                if(!focus) {
                    optionsView.state = "hidden";
                    if(textField.cityOptions) {
                        textField.cityOptions.abort();
                    }
                }
                else {
                    optionsView.state = "visible";
                }
            }

            onAccepted: {
                if(searchItem.searchFunction) {
                    searchItem.searchFunction();
                }
            }

            function setTextWithNoSignal(text) {
                textField.noSignal = true;
                textField.text = text;
                textField.noSignal = false;
            }

            function textChange() {
                if(!textField.noSignal) {
                    var search = textField.displayText || textField.text;

                    var transportOption = Transport.transportOptions.getSelectedTransport();
                    if(transportOption && search !== "") {
                        itemActivity.running = true;
                        optionsView.state = "visible";
                        cityOptions = transportOption.searchStations(search, function(options, source) {
                            if(options) {
                                if(source === "REMOTE") {
                                    itemActivity.running = false;
                                }

                                var fetchedStops = options.getInnerStops(search);
                                if(fetchedStops.length > 0) {
                                    optionsModel.clear()
                                    for(var i = 0; i < fetchedStops.length; i++) {
                                        optionsModel.append({
                                            item: fetchedStops[i].getItem(),
                                            name: fetchedStops[i].getName()
                                        });
                                    }
                                }
                            }
                            else {
                                itemActivity.running = false;
                            }
                        }, function(options) {
                            if(!options.request) {
                                itemActivity.running = false;
                            }
                        });
                    }
                    else {
                        optionsView.state = "hidden";
                        if(textField.cityOptions) {
                            textField.cityOptions.abort();
                            itemActivity.running = false;
                        }
                    }
                }
            }

            ActivityIndicator {
                id: itemActivity
                anchors {
                    fill: parent
                    centerIn: parent
                    margins: parent.height/6
                }
                running: false
            }
        }

        Component {
            id: optionsDelegate

            Rectangle {
                id: optionDelegateItemRectangle
                anchors {
                    left: parent.left
                    right: parent.right
                }
                height: stationName.contentHeight + 2*stationName.anchors.margins
                color: Qt.rgba(255, 255, 255, 0.8)
                clip: true

                Label {
                    id: stationName
                    anchors {
                        left: parent.left
                        right: parent.right
                        margins: units.gu(1)
                        centerIn: parent
                    }
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: name
                    font.pixelSize: FontUtils.sizeToPixels("normal")
                    wrapMode: Text.WordWrap
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        selectedStop = Transport.transportOptions.getSelectedTransport().cityOptions.getStopsByItem(item);
                        if(selectedStop) {
                            if(textField.cityOptions) {
                                textField.cityOptions.abort();
                                itemActivity.running = false;
                            }
                            textField.setTextWithNoSignal(selectedStop.getName());
                            textField.focus = false;
                        }
                    }
                }
            }
        }

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
            }
            height: optionsView.height
            color: pageLayout.headerColor

            ListView {
                id: optionsView
                anchors {
                    left: parent.left
                    right: parent.right
                }
                interactive: false
                height: childrenRect.height
                delegate: optionsDelegate

                model: ListModel {
                    id: optionsModel
                }

                state: "hidden"

                states: [
                    State {
                        name: "visible"
                        PropertyChanges { target: optionsView; visible: true }
                        PropertyChanges { target: optionsView; height: childrenRect.height }
                    },
                    State {
                        name: "hidden"
                        PropertyChanges { target: optionsView; visible: false }
                        PropertyChanges { target: optionsView; height: 0 }
                    }
                ]
            }
        }
    }
}
