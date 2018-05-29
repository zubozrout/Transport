import QtQuick 2.4
import QtPositioning 5.2

import "../transport-api.js" as Transport
import "../generalfunctions.js" as GeneralFunctions

PositionSource {
	id: positionSource
	updateInterval: 10000
	active: true
	
	property var functionsToRunOnUpdate: []
	property var isValid: false
	
	function append(func) {
		if(position.coordinate.isValid) {
			func(positionSource);
		}
		else {
			functionsToRunOnUpdate.push(func);
			update();
		}
	}
	
	function runAll() {
		for(var i = 0; i < functionsToRunOnUpdate.length; i++) {
			functionsToRunOnUpdate[i](positionSource);
		}
		functionsToRunOnUpdate = [];
	}
	
	onUpdateTimeout: {
		isValid = false;
		runAll();
	}
	
	onPositionChanged: {
		if(position.coordinate.isValid) {
			isValid = true;
					
			Transport.transportOptions.saveDBSetting("last-geo-positionX", position.coordinate.latitude);
			Transport.transportOptions.saveDBSetting("last-geo-positionY", position.coordinate.longitude);
			
			runAll();
		}
		else {
			isValid = false;
		}
	}
}
