import QtQuick 2.4
import Ubuntu.Components 1.3

import "pages"

/*!
    \brief MainView with a Label and Button elements.
*/

MainView {
    // objectName for functional testing purposes (autopilot-qt5)
    objectName: "mainView"

    // Note! applicationName needs to match the "name" field of the click manifest
    applicationName: "transport.zubozrout"

    width: units.gu(100)
    height: units.gu(75)

    AdaptivePageLayout {
        id: pageLayout
        anchors.fill: parent
        primaryPage: searchPage

        property var colorPalete: {
            "headerBG": "#00796b",
            "headerText": "#fff",
            "baseBG": "#fff",
            "baseText": "#333",
            "baseAlternateText": "#b22",
            "secondaryBG": "#b2dfdb",
            "secondaryText": "#333",
            "highlightBG": "#eee",
            "highlightText": "#333"
        }

        property var headerColor: "#00796b"
        property var baseColor: "#fff"
        property var baseTextColor: "#333"
        property var secondaryColor: "#b2dfdb"
        property var highlightedTextColor: "#b22"

        layouts: [
            PageColumnsLayout {
                when: width > units.gu(80)
                PageColumn {
                    minimumWidth: units.gu(40)
                    maximumWidth: units.gu(50)
                    preferredWidth: units.gu(40)
                }
                PageColumn {
                    fillWidth: true
                }
            },
            PageColumnsLayout {
                when: true
                PageColumn {
                    fillWidth: true
                    minimumWidth: units.gu(30)
                }
            }
        ]

        SearchPage {
            id: searchPage
        }

        TransportSelectorPage {
            id: transportSelectorPage
        }

        ConnectionsPage {
            id: connectionsPage
        }

        ConnectionDetailPage {
            id: connectionDetailPage
        }

        AboutPage {
            id: aboutPage
        }

        SettingsPage {
            id: settingsPage
        }
    }
}


