import QtQuick 2.4
import QtPositioning 5.2

import "../transport-api.js" as Transport
import "../generalfunctions.js" as GeneralFunctions

PositionSource {
	id: positionSource
	updateInterval: 1000
	active: true
	
	property bool isValid: false;
	
	onPositionChanged: {
		if(!isNaN(position.coordinate.latitude) && !isNaN(position.coordinate.longitude)) {
			isValid = true;
		}
		else {
			isValid = false;
		}
	}
}
