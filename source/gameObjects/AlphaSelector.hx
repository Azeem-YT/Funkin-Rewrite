package gameObjects;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import flixel.animation.FlxBaseAnimation;
import flixel.graphics.frames.FlxFrame;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import options.OptionsState;
import options.AtlasText;
import flixel.group.FlxSpriteGroup;
#if sys
import sys.io.File;
import sys.FileSystem;
#end

class AlphaSelector extends FlxSpriteGroup
{
	public var valueText:AtlasText;
	public var alphaText:String = "";
	public var targetY:Float;
	public var curValue:Float = 0;
	//public var selectorRight:FlxSprite;
	//public var selectorLeft:FlxSprite;

	public function new(x:Float, y:Float, curValue:Dynamic = 0, defaultVal:Dynamic, valueType:String)
	{
		super(x, y);

		valueText = new AtlasText(0, 0, Std.string(curValue));
		add(valueText);

		visible = true;
		alpha = 1;
	}

	public function setText(newText:String) {
		valueText.text = newText;
	}
}
