package modding;

import states.*;
import engine.*;
import shaders.*;


class ModState extends MusicBeatState
{
	#if ALLOW_HSCRIPT
	public var script:HScript;
	#end

	public static var instance:ModState;
	public static var stateName:String = 'ModState';
	
	override function create() {
		instance = this;

		super.create();

		script = new HScript(Paths.stateDirectory(stateName));
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		#if ALLOW_HSCRIPT
		runFunction('onUpdate', [elapsed]);
		#end
	}

	public function runFunction(name:String, vars:Array<Dynamic>) {
		#if ALLOW_HSCRIPT
		if (script.exists(name))
			Reflect.callMethod(null, script.get, vars);
		#end
	}
}