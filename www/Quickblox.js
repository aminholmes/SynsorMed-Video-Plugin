

	var exec = require("cordova/exec");


	var videoPlugin = {};
	
	videoPlugin.initVideo = function()
	{
		console.log("I am about to go to native");
		exec(null, null, "videoPlugin", "initQB", []);	
	}

	videoPlugin.initialize = function(appID, success, error) {
		exec(success, error, "videoPlugin", "initQB", [appID]);
	};

	videoPlugin.authenticate = function(token, type, success, error) {
		exec(success, error, "videoPlugin", "authent", [token, type]);
	};

	videoPlugin.getStatus = function(userID, on) {
		exec(function(available) { available ? on(true) : on(false); }, null, "videoPlugin", "getStatus", [userID]);
	};

	videoPlugin.createCall = function(userID,isProvider,allowSwitch) {
		exec(null, null, "videoPlugin", "createCall", [userID,isProvider,allowSwitch]);
	};

	videoPlugin.disconnect = function() {
		exec(null, null, "videoPlugin", "disconnect", []);
	};

	videoPlugin.setAudioRoute = function(speakers) {
		exec(null, null, "videoPlugin", "setAudioRoute", [speakers]);
	};
	
	videoPlugin.acceptCall = function(){
   
   		exec(null,null,"videoPlugin","acceptCall",[]);
   
   };
   
   videoPlugin.hangUp = function(){
   
   		exec(null,null,"videoPlugin","hangUp",[]);
   
   };

	videoPlugin.internal = {
		callCreated: function(callID, status) {
			//var call = new WeemoCall(callID, displayName);
			//calls[callID] = call;
			//Weemo.onCallCreated(call);
			console.log("Incoming call: JS, status is: " + status);
			angular.element(document.querySelector('#pageContainer')).scope().$broadcast('callchange',status);
		},

		callStatusChanged: function(callID, status) {
            console.log("Call status just changed in JS to: " + status);
               //console.log("The callID in js is: " + callID);
			/*var call = calls[callID];
               if (!call) {
               console.log("Call does not exist in js. Returning");
               return ;
               }
               if (status == 0) {
               console.log("Status is 0 in js. Returning");
               return ;
               }
			call._setCallStatus(status);
			call.onCallStatusChanged(status);
			*/
			angular.element(document.querySelector('#pageContainer')).scope().$broadcast('callchange',status);

		},

		videoInChanged: function(callID, receiving) {
			var call = calls[callID];
			if (!call) return ;
			call._setReceivingVideo(receiving);
			call.onVideoInChanged(receiving);
		},

		connectionChanged: function(status) {
			Weemo.onConnectionChanged(status);
		},

		audioRouteChanged: function(speakers) {
			Weemo.onAudioRouteChanged(speakers);
		}
	};

	module.exports = videoPlugin;


