import QtQuick 2.4
import Ubuntu.Components 1.3
//import Transport 1.0
import QtQuick.LocalStorage 2.0

import "transport-api.js" as Transport
import "generalfunctions.js" as GeneralFunctions

import "pages"

/*!
    \brief MainView with a Label and Button elements.
*/

MainView {
    // objectName for functional testing purposes (autopilot-qt5)
    objectName: "mainView"

    // Note! applicationName needs to match the "name" field of the click manifest
    applicationName: "transport-basic.zubozrout"

    width: units.gu(100)
    height: units.gu(75)

    AdaptivePageLayout {
        id: pageLayout
        anchors.fill: parent
        primaryPage: searchPage

        property var headerColor: "#00796b"
        property var baseColor: "#fff"
        property var baseTextColor: "#333"
        property var secondaryColor: "#b2dfdb"

        SearchPage {
            id: searchPage
        }

        TransportSelectorPage {
            id: transportSelectorPage
        }

        ConnectionsPage {
            id: connectionsPage
        }
    }
}


