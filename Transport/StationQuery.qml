import QtQuick 2.4
import Ubuntu.Components 1.3

Item {
    id: stationQuery
    width: parent.width
    height: childrenRect.height

    property alias text: stationInput.text
    property alias displayText: stationInput.displayText
    property alias stationInputListView: stationInput_list_view
    property alias stationInputModel: stationInput_list_model
    property var coorX: null
    property var coorY: null

    property var lastDisplayTextValue: null

    Column {
        width: parent.width
        height: childrenRect.height
        clip: true

        TextField {
            id: stationInput
            width: parent.width
            placeholderText: stationQuery.placeholder
            hasClearButton: true
            onDisplayTextChanged: {
                if(lastDisplayTextValue != displayText) {
                    stationQuery.coorX = null;
                    stationQuery.coorY = null;
                    stationInputChanged(stationInput, stationInput_list_view, stationInput_list_model);
                    lastDisplayTextValue = displayText;
                }
            }

            onFocusChanged: {
                if(focus) {
                    stationInput_help.visible = true;
                }
                else {
                    stationInput_help.visible = false;
                }
            }
        }

        Rectangle {
            id: stationInput_help
            width: parent.width
            height: visible ? stationInput_list_view.contentHeight : 0
            color: "#E8EAF6"
            clip: true

            Component {
                id: stationInputDelegate
                Item {
                    anchors.margins: units.gu(2)
                    width: stationInput_help.width
                    height: stationInput_stop.paintedHeight + units.gu(2)

                    Text {
                        id: stationInput_stop
                        text: name
                        anchors.fill: parent
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        wrapMode: Text.Wrap
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            var item = stationInput_list_model.get(index);
                            var name = item.name;
                            var coorX = item.coorX ? item.coorX : null;
                            var coorY = item.coorY ? item.coorY : null;
                            if(name != "") {
                                Qt.inputMethod.commit();
                                stationInput_list_view.currentIndex = index;
                                stationInput.text = name;
                                stationQuery.coorX = coorX;
                                stationQuery.coorY = coorY;
                                stationInput.focus = false;
                            }
                        }
                    }
                }
            }

            ListView {
                id: stationInput_list_view
                anchors.fill: parent
                model: ListModel { id: stationInput_list_model }
                delegate: stationInputDelegate
                highlight: Rectangle { color: "#9FA8DA" }
                onCurrentIndexChanged: checkClear(stationInput, stationInput_list_view, model)
                property var lastSelected: null
                clip: true
            }
        }
    }
}

