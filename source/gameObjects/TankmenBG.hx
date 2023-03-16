package gameObjects;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;

import data.*;

class TankmenBG extends FlxSprite
{
	public static var animationNotes:Array<Dynamic> = [];
	private var tankSpeed:Float;
	private var endingOffset:Float;
	private var goingRight:Bool;
	public var strumTime:Float;

	public function new(x:Float, y:Float, isGoingRight:Bool)
	{
		tankSpeed = 0.7;
		strumTime = 0;
		goingRight = isGoingRight;
		super(x, y);

		frames = Paths.getSparrowAtlas('tankmanKilled1', 'week7');
		antialiasing = true;
		animation.addByPrefix('run', 'tankman running', 24, true);
		animation.addByPrefix('shot', 'John Shot ' + FlxG.random.int(1, 2), 24, false);

		animation.play('run');
		animation.curAnim.curFrame = FlxG.random.int(0, animation.curAnim.numFrames - 1);

		updateHitbox();

		setGraphicSize(Std.int(width * 0.8));
		updateHitbox();
	}

	public function resetShit(x:Float, y:Float, isGoingRight:Bool):Void
	{
		setPosition(x, y);
		goingRight = isGoingRight;
		endingOffset = FlxG.random.float(50, 200);
		tankSpeed = FlxG.random.float(0.6, 1);

		if (goingRight)
			flipX = true;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		visible = (x > -0.5 * FlxG.width && x < 1.2 * FlxG.width);

		if(animation.curAnim.name == "run")
		{
			var endDirection:Float = (FlxG.width * 0.74) + endingOffset;

			if (goingRight) {
				endDirection = (FlxG.width * 0.02) - endingOffset;
				x = (endDirection + (Conductor.songPosition - strumTime) * tankSpeed);
			}
			else {
				x = (endDirection - (Conductor.songPosition - strumTime) * tankSpeed);
			}
		}

		if (Conductor.songPosition > strumTime) {
			animation.play('shot');
			if (goingRight) {
				offset.y = 200;
				offset.x = 300;
			}
		}

		if (animation.curAnim.name == 'shot' && animation.curAnim.curFrame >= animation.curAnim.frames.length - 1)
			kill();
	}
}