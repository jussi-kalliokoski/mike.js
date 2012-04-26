var Mike = function () {

function extend (obj) {
	var k, n;

	for (n=1; n < arguments.length; n++) {
		for (k in arguments[n]) {
			if (arguments[n].hasOwnProperty(k)) {
				obj[k] = arguments[n][k];
			}
		}
	}

	return k;
}

function EventEmitter (target) {
	extend(target, EventEmitter.prototype);
	target._listeners = {};
}

EventEmitter.prototype = {
	_listeners: null,

	emit: function (name, args) {
		if (this._listeners[name]) {
			for (var i=0; i<this._listeners[name].length; i++) {
				this._listeners[name][i].apply(this, args);
			}
		}
		return this;
	},

	on: function (name, listener) {
		this._listeners[name] = this._listeners[name] || [];
		this._listeners[name].push(listener);
		return this;
	},

	off: function (name, listener) {
		if (this._listeners[name]) {
			if (!listener) {
				delete this._listeners[name];
				return this;
			}

			for (var i=0; i<this._listeners[name].length; i++) {
				if (this._listeners[name][i] === listener) {
					this._listeners[name].splice(i--, 1);
				}
			}

			if (!this._listeners[name].length) {
				delete this._listeners[name];
			}
		}
		return this;
	},

	once: function (name, listener) {
		var self = this;

		return this.on(name, function l () {
			this.off(name, l);
			return listener.apply(this, arguments);
		});
	}
};

function Mike (options) {
	extend(this, options || {});
	this.id = this.id ||  'mike' + (+new Date()) + Math.random();
	EventEmitter(this);

	this.createDOM();
	Mike.add(this);

	this.on('microphonechange', function () {
		if (this.settings) this.setParam(this.settings);
	});
}

Mike.prototype = {
	parentElement: null,
	domElement: null,
	id: null,
	settings: null,
	index: null,
	swfPath: 'mike.swf',
	objectName: 'Mike',

	createDOM: function () {
		var obj = document.createElement('object');
		obj.innerHTML = '<param name="movie" value="' + this.swfPath + '" />' +
			'<param name="FlashVars" value="id=' + this.id + '&amp;objectName=' +
			this.objectName + '">';

		obj.className = 'mike-js';
		obj.id = this.id;
		obj.type = 'application/x-shockwave-flash';
		obj.data = this.swfPath;
		obj.width = 215;
		obj.height = 138;

		this.parentElement = this.parentElement || document.body;
		this.domElement = obj;

		this.parentElement.appendChild(obj);
	},

	start: function () {
		return this.domElement.start();
	},

	stop: function () {
		return this.domElement.stop();
	},

	setParam: function (name, value) {
		var k;

		if (arguments.length === 1) {
			for (k in name) {
				if (name.hasOwnProperty(k)) {
					this.setParam(k, name[k]);
				}
			}
		} else {
			this.domElement.setParam(name, value);
		}
	},

	getParam: function (name) {
		return this.domElement.getParam(name);
	},

	setLoopBack: function (value) {
		return this.domElement.setLoopback(value);
	},

	setSilenceLevel: function (value) {
		return this.domElement.setSilenceLevel(value);
	},

	setUseEchoSuppression: function (value) {
		return this.domElement.setUseEchoSuppression(value);
	},

	getMicrophones: function () {
		return this.domElement.getMicrophones();
	},

	setMicrophone: function (index) {
		this.index = null;

		var r = this.domElement.setMicrophone(index);

		if (r === Mike.ERROR_NO_ERROR) {
			this.index = index || 0;

			this.emit('microphonechange', []);
		}

		return r;
	}
};

var SoundCodec = {
	NELLYMOSER: 'nellymoser',
	SPEEX: 'speex'
};

/* Declare static */
extend(Mike, {
	ERROR_NO_ERROR: 0,
	ERROR_INVALID_VERSION: 1,
	ERROR_NOT_SUPPORTED: 2,
	ERROR_NOT_AVAILABLE: 3,

	list: [],

	SoundCodec: SoundCodec,

	add: function (mike) {
		this.list.push(mike);
		this.list[mike.id] = mike;
	}
});

/* populate event handlers */

void function (names, i) {

	function eventTransmitter(name) {
		Mike['on' + name] = function (id) {
			/* We'll just ignore this, probably from a previous instance */
			if (!this.list[id]) return;

			try {
				this.list[id].emit(name, [].slice.call(arguments, 1));
			} catch (e) {
				console.error(e, id);
			}
		};
	}

	for (i=0; i<names.length; i++) {
		eventTransmitter(names[i]);
	}

	names = null;

}(['ready', 'error', 'data', 'statechange', 'activity']);

return Mike;

}();
