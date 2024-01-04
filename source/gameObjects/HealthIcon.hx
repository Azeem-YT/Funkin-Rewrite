package gameObjects;

import flixel.FlxSprite;
import lime.utils.Assets;
import flixel.ui.FlxBar;
import Paths.FileTypes;
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
		var iconName:String = 'icons/$char';

		if (!Paths.exists(iconName, '', IMAGE)) iconName = 'icons/icon-$char';
		if (!Paths.exists(iconName, '', IMAGE)) iconName = 'icons/icon-face';
		
		var graphic = Paths.image(iconName);
		loadGraphic(graphic, true, 150, 150);
		animation.add(char, [0, 1], 0, false, isPlayer);
		animation.play(char);
		antialiasing = true;

		if (char.endsWith('-pixel')) {
			antialiasing = false;
		}

		if (antialiasing) antialiasing = PlayerPrefs.antialiasing;
	}

	public function updateIcon(p:Int = 1, healthBar:FlxBar) {
		if (animation.curAnim == null || healthBar == null) return;

		if (p == 1) {
			if (healthBar.percent > 80) animation.curAnim.curFrame = 1;
			else animation.curAnim.curFrame = 0;
			return;
		}

		if (healthBar.percent > 80) animation.curAnim.curFrame = 1;
		else animation.curAnim.curFrame = 0;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (sprTracker != null) setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);
	}
}
