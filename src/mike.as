package {
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.media.Microphone;
	import flash.media.SoundCodec;
	import flash.events.StatusEvent;
	import flash.events.ActivityEvent;
	import flash.events.SampleDataEvent;
	import flash.external.ExternalInterface;
	import flash.system.Security;
	import flash.system.Capabilities;

	public class mike extends Sprite {
		private var mic:Microphone	= null;
		private var JSObject:String	= null;
		private var id:String		= null;

		/* Error types */
		public const ERROR_NO_ERROR:Number		= 0;
		public const ERROR_INVALID_VERSION:Number	= 1;
		public const ERROR_NOT_SUPPORTED:Number		= 2;
		public const ERROR_NOT_AVAILABLE:Number		= 3;

		public function mike () {
			var options:Object = this.loaderInfo.parameters;

			JSObject = options.objectName || "Mike";
			id = options.id;

			if (!this.checkVersion()) {
				error(ERROR_INVALID_VERSION);
				return;
			}

			Security.showSettings("2");

			this.setupInterface();

			ExternalInterface.call(JSObject + '.onready', id);
		}

		/* External Interface */

		public function start () : void {
			mic.addEventListener(SampleDataEvent.SAMPLE_DATA, onSampleData);
		}

		public function stop () : void {
			mic.removeEventListener(SampleDataEvent.SAMPLE_DATA, onSampleData);
		}

		public function setParam (name:String, value:*) : void {
			mic[name] = value;
		}

		public function getParam (name:String) : * {
			return mic[name];
		}

		public function setLoopBack (value:*) : * {
			return mic.setLoopBack(value);
		}

		public function setSilenceLevel (a:*, b:*) : * {
			return mic.setSilenceLevel(a, b);
		}

		public function setUseEchoSuppression (value:*) : * {
			return mic.setUseEchoSuppression(value);
		}

		public function setMicrophone (index:*) : Number {
			mic = Microphone.getMicrophone();

			if (mic != null) {
				mic.addEventListener(StatusEvent.STATUS, onStateChange);
				mic.addEventListener(ActivityEvent.ACTIVITY, onActivity);
			} else if (Microphone.isSupported === false) {
				return ERROR_NOT_SUPPORTED;
			} else {
				return ERROR_NOT_AVAILABLE;
			}

			return ERROR_NO_ERROR;
		}

		public function getMicrophones () : Array {
			var list:Array = new Array();

			for (var i:Number=0; i < Microphone.names.length; i++) {
				list[i] = Microphone.names[i];
			}

			return list;
		}

		/* Event Handlers */

		public function onSampleData (event:SampleDataEvent) : void {
			var data:Array = new Array();

			while (event.data.bytesAvailable) {
				var sample:Number = event.data.readFloat();
				data.push(sample);
			}

			ExternalInterface.call(JSObject + '.ondata', id, data);
		}

		public function onStateChange (event:StatusEvent) : void {
			ExternalInterface.call(JSObject + '.onstatechange', id, event);
		}

		public function onActivity (event:ActivityEvent) : void {
			ExternalInterface.call(JSObject + '.onactivity', id, event);
		}

		/* Private helper methods */

		private function setupInterface () : void {
			ExternalInterface.addCallback("start", start);
			ExternalInterface.addCallback("stop", stop);
			ExternalInterface.addCallback("setParam", setParam);
			ExternalInterface.addCallback("getParam", getParam);
			ExternalInterface.addCallback("setLoopBack", setLoopBack);
			ExternalInterface.addCallback("setSilenceLevel", setSilenceLevel);
			ExternalInterface.addCallback("setUseEchoSuppression", setUseEchoSuppression);
			ExternalInterface.addCallback("setMicrophone", setMicrophone);
			ExternalInterface.addCallback("getMicrophones", getMicrophones);
		}

		private function checkVersion () : Boolean {
			var flashPlayerVersion:String = Capabilities.version;
			var osArray:Array = flashPlayerVersion.split(' ');
			var versionArray:Array = osArray[1].split(',');
			var majorVersion:Number = parseInt(versionArray[0]);
			var majorRevision:Number = parseInt(versionArray[1]) / 10;

			return majorVersion + majorRevision >= 10.1;
		}

		private function error (code:Number) : void {
			ExternalInterface.call(JSObject + '.onerror', id, code);
		}
	}
}
