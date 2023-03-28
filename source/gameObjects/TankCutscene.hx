package gameObjects;

import flixel.FlxSprite;
import flixel.system.FlxSound;

class TankCutscene extends FlxSprite
{
	public var startSyncAudio:FlxSound;

	public function new(x:Float, y:Float) {
		super(x, y);
	}

	var startedPlayingSound:Bool = false;

	public function stopAudio() {
		if (startedPlayingSound) startSyncAudio.stop();
	}

	override function update(elapsed:Float)
	{
		if (animation.curAnim != null && animation.curAnim.curFrame >= 1 && !startedPlayingSound) {
			startSyncAudio.play();
			startedPlayingSound = true;
		}

		super.update(elapsed);
	}
}
