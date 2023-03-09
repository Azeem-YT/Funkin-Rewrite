package gameObjects;

import flixel.FlxSprite;
import lime.utils.Assets;
import data.*;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

typedef AnimatedData = 
{
	var losingAnim:String;
	var neutralAnim:String;
	var image:String;
}

class HealthIcon extends FlxSprite
{
	/**
	 * Used for FreeplayState! If you use it elsewhere, prob gonna annoying
	 */
	public var sprTracker:FlxSprite;

	public function new(char:String = 'bf', isPlayer:Bool = false, ?animData:AnimatedData)
	{
		super();
		changeIcon(char, isPlayer, animData);
		scrollFactor.set();
	}

	public function changeIcon(char:String, isPlayer:Bool = false, ?animData:AnimatedData)
	{
		if (animData != null){
			frames = Paths.getSparrowAtlas(animData.image);
			animation.addByPrefix("winning", animData.neutralAnim, 24, true);
		}
		else
		{
			var imageIsString:Bool = Std.isOfType(Paths.image('icons/$char'), String);
			var graphicShit:Dynamic = Paths.image('icons/$char');
			var graphicsAlt:Dynamic = Paths.image('icons/icon-$char');

			if (graphicShit != null)
				loadGraphic(graphicShit, true, 150, 150);
			
			if (graphicsAlt != null && graphic == null)
				loadGraphic(graphicsAlt, true, 150, 150);

			if (graphic == null) {
				loadGraphic(Paths.image('icons/icon-face'), true, 150, 150);
			}
			
			animation.add(char, [0, 1], 0, false, isPlayer);
			animation.play(char);
			antialiasing = true;
		}

		if (char.endsWith('-pixel')) {
			antialiasing = false;
		}

		if (antialiasing)
			antialiasing = PlayerPrefs.antialiasing;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);
	}
}
