package options;

import flixel.FlxG;
import states.*;

class PlayStateSettings {

	public static var middlescroll(default, set):Bool = false;
	public static var downscroll(default, set):Bool = false;
	public static var scroll_speed(default, set):Float = 1;

	public static var instantMove:Bool = true;

	inline static public function set_middlescroll(val:Bool):Bool {
		if (PlayState.instance != null) {
			for (strum in PlayState.strumLines)
				if (strum != null)
					strum.setmiddlescroll(val, instantMove);
		}

		middlescroll = val;
		return val;
	}

	inline static public function set_downscroll(val:Bool):Bool {
		if (PlayState.instance != null) {
			for (strum in PlayState.strumLines)
				if (strum != null)
					strum.setdownscroll(val);
		}

		middlescroll = val;
		return val;
	}

	inline static public function set_scroll_speed(val:Float):Float {
		if (PlayState.instance != null && PlayState.instance.generatedMusic) {
			for (daNote in PlayState.instance.notes) daNote.resizeScale(val);
			for (daNote in PlayState.instance.unspawnNotes) daNote.resizeScale(val);
		}

		scroll_speed = val;
		return val;
	}
}