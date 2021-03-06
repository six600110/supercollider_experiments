////////////////////////////////////////////////////////////////////////

// GUI to control a synth
s.boot;
s.quit;


(
SynthDef("trem", { arg freq=800, rate=8, amp=0.1; 
	var osc;
	freq = Lag.kr(freq, 0.3);
	osc = LFTri.ar(freq, 0, SinOsc.kr( rate + [0,0.1],0,amp).max(0));
	Out.ar(0, osc) 
}).writeDefFile;
Server.local.sendMsg("/d_load", SynthDef.synthDefDir ++ "trem.scsyndef");
)

(
var w, f, d, values, server, id, isOn = false;
var b1, b2, s;

values = IdentityDictionary.new;
server = Server.local;

f = { arg name, spec = \lin, guispec;
	var height = 20, v, s, n;
	guispec = guispec ? spec;
	spec = spec.asSpec;
	guispec = guispec.asSpec;

	v = GUI.staticText.new(w, Rect(0, 0, 72, height));
	v.font = GUI.font.new("Helvetica", 12);
	v.stringColor = Color.black;
	v.align = \right;
	
	s = GUI.slider.new(w, Rect(0, 0, 182, height));
	s.resize = 2;
	s.action = { 
		var val, guival, step;
		val = spec.map(s.value);
		values.put(name, val);
		if (isOn, { server.sendMsg("/n_set", id, name, val); });
		guival = guispec.map(s.value);
		step = pow(10, floor(min(0, guival.abs.log10 - 2)));
		v.string = guival.round(step).asString ++ guispec.units;
	};
	s.value = spec.unmap(spec.default);
	s.action.value;
	
	n = GUI.staticText.new(w, Rect(0, 0, 72, height));	n.string = name;
	n.stringColor = Color.black;
	n.font = GUI.font.new("Helvetica", 12);
	n.resize = 3;
	
	w.view.decorator.nextLine;
};

id = 2001;
w = GUI.window.new("trem", Rect(512, 64, 360, 130));
w.view.decorator = d = FlowLayout(w.view.bounds);

b1 = GUI.button.new(w, Rect(0,0, 80, 24));
b1.states = [["Load", Color.black, Color.green]];
b1.action = { arg view; 
	server.sendMsg("/d_load", "synthdefs/trem.scsyndef");
};
b1.enabled = server.serverRunning;

b2 = GUI.button.new(w, Rect(0,0, 80, 24));
b2.states = [
	["Play", Color.black, Color.green],
	["Stop", Color.white, Color.red],
];
b2.action = { arg view; 
	var msg;
	if (view.value == 1, {
		isOn = true;
		msg = ["/s_new", "trem", 2001, 1, 0];
		values.keysValuesDo({ arg key, value; 
			msg = msg.addAll([key, value]); 
		});
		server.performList(\sendMsg, msg); 
	},{
		isOn = false;
		server.sendMsg("/n_free", 2001); 
	});
};
b2.enabled = server.serverRunning;
d.nextLine;

f.value(\freq, \freq);
f.value(\rate, \lofreq);
f.value(\amp, \amp, \db);

a = SimpleController(server);
f = { arg server; 
	b1.enabled = server.serverRunning;
	b2.enabled = server.serverRunning;
	if (server.serverRunning.not, { b2.value = 0 });
};
a.put(\serverRunning, f);
w.onClose = { 
	if (isOn, { server.sendMsg("/n_free", 2001) });
 	a.remove;
};

w.front;
)

////////////////////////////////////////////////////////////////////////
