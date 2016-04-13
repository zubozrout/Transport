import QtQuick 2.4
import Ubuntu.Components 1.3
import QtQuick.LocalStorage 2.0

import "engine.js" as Engine
import "localStorage.js" as DB

Item {
    id: departureTimer
    /*
    property alias routeStart: undefined
    property alias routeEnd: undefined
    property alias startTime: undefined
    property alias remainingTime: undefined
    property alias timeColor: undefined
    */

    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true

        onTriggered: {
            if(isNaN(departureTimer.startTime)) {
                repeat = false;
                departureTimer.remainingTime = " ";
                return;
            }

            var now = new Date();
            now.setSeconds(0,0);
            var diff = Math.round((departureTimer.startTime - now) / 60000);
            if(Math.abs(diff) <= 1440 && departureTimer.startTime.getDate() >= now.getDate()) {
                if(diff < 0) {
                    if(diff > -59) {
                        var minutes = Math.abs(diff);
                        departureTimer.remainingTime = i18n.tr("%1 minute ago", "%1 minutes ago", minutes).arg(minutes);
                    }
                    else {
                        departureTimer.remainingTime = i18n.tr("departed");
                        repeat = false;
                    }
                    departureTimer.timeColor = "#B71C1C";
                    return;
                }
                else {
                    var minutes = diff;
                    var hours = 0;
                    if(diff > 59) {
                        hours = Math.floor(minutes/60);
                        minutes = diff - hours*60;
                    }

                    if(hours > 0) {
                        departureTimer.remainingTime = i18n.tr("in %1 hour", "in %1 hours", hours).arg(hours);
                        if(minutes > 0) {
                            departureTimer.remainingTime += " " + i18n.tr("and %1 minute", "and %1 minutes", minutes).arg(minutes);
                        }
                    }
                    else {
                        if(minutes == 0) {
                            departureTimer.remainingTime = i18n.tr("just now");
                        }
                        else {
                            departureTimer.remainingTime = i18n.tr("in %1 minute", "in %1 minutes", minutes).arg(minutes);
                        }
                    }
                    departureTimer.timeColor = "#33691E";
                    return;
                }
            }
            else {
                if(departureTimer.routeStart) {
                    departureTimer.remainingTime = Engine.dateToReadableFormat(departureTimer.routeStart);
                    if(departureTimer.routeEnd && departureTimer.remainingTime != Engine.dateToReadableFormat(departureTimer.routeEnd)) {
                        departureTimer.remainingTime += " → " + Engine.dateToReadableFormat(departureTimer.routeEnd);
                    }
                }
                else {
                    departureTimer.remainingTime = "";
                }
                return;
            }
        }
    }
}
