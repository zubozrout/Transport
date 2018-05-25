import QtQuick 2.4
import Ubuntu.Components 1.3
import "../components"

Page {
    id: aboutPage
    header: PageHeader {
        id: pageHeader
        title: i18n.tr("About Transport App")
        flickable: aboutFlickable

        StyleHints {
            foregroundColor: pageLayout.colorPalete["headerText"]
            backgroundColor: pageLayout.colorPalete["headerBG"]
        }
    }

    clip: true

    Flickable {
        id: aboutFlickable
        anchors.fill: parent
        contentHeight: aboutFlickableRectangle.height

        Rectangle {
            id: aboutFlickableRectangle
            anchors {
                left: parent.left
                right: parent.right
                margins: units.gu(1)
            }
            height: childrenRect.height + 2 * anchors.margins

            Column {
                id: aboutColumn
                anchors {
                    left: parent.left
                    right: parent.right
                }
                spacing: units.gu(2)

                CustomDataList {
                    id: customDataList
                }

                Component.onCompleted: {
                    customDataList.append({value: i18n.tr("Transport") + " v1.2\nUbuntu Touch + UBports", fontScale: "large", imageSource: "../transport.svg", imageWidth: units.gu(10), bottomBorder: true});
                    customDataList.append({value: i18n.tr("Transport is here to allow you searching for Czech and Slovak public transport connections."), bottomBorder: true});
                    customDataList.append({value: i18n.tr("This application is based upon an API provided by CHAPS s.r.o. company.") + " info@chaps.cz\n\n" + i18n.tr("You can find the documentation of the API service here http://docs.crws.apiary.io/"), bottomBorder: true});
                    customDataList.append({value: i18n.tr("Feel free to report bugs on the github page but please note many of the existing bugs are know and the reason why they are not fixed yet is the fact I don't have enough time to take care of those just yet."), fontScale: "small", bottomBorder: true});
                    customDataList.append({value: i18n.tr("Check out project's GitHub page"), url: "https://github.com/zubozrout/Transport/tree/devel/Transport", bottomBorder: true});
                    customDataList.append({value: i18n.tr("GDPR notice: CHAPS s.r.o. API doesn't collect any personal data but can log searched values combined with IP addresses and a platform string passed with every single query - \"ubuntu\"."), fontScale: "small", bottomBorder: false});
                }
            }
        }
    }

    Scrollbar {
        flickableItem: aboutFlickable
        align: Qt.AlignTrailing
    }
}
