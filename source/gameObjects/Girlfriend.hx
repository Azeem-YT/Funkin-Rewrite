package gameObjects;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.util.FlxTimer;
import data.*;

using StringTools;

class Girlfriend extends Character
{
	public function new(x:Float, y:Float, ?char:String = 'gf') {
		super(x, y, char);
	}

	override function update(elapsed:Float) {
		switch (curCharacter) {
			case 'pico-speaker':
					forceNoIdle = true;

					if (animationNotes.length > 0 && Conductor.songPosition >= animationNotes[0][0]) {
						var noteData:Int = 1;
						if(animationNotes[0][1] > 2) 
							noteData = 3;

						noteData += FlxG.random.int(0, 1);
						playAnim('shoot' + noteData, true);
						animationNotes.shift();
					}

					if (animation.curAnim != null && animation.curAnim.finished)
						playAnim(animation.curAnim.name, false, false, animation.curAnim.frames.length - 3);
			case 'gf':
				if (animation.curAnim.name == 'hairFall' && animation.curAnim.finished && animation.curAnim != null)
					playAnim('danceRight');
		}


		super.update(elapsed);
	}
}
