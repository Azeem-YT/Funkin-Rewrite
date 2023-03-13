package gameObjects;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
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
import flixel.group.FlxSpriteGroup;
#if sys
import sys.io.File;
import sys.FileSystem;
#end

class AlphaCheckbox extends FlxSpriteGroup
{
	public var alphaParent:Alphabet;
	public var alphabet:Alphabet;
	public var alphaText:String = "";
	public var targetY:Float;
	public var checked:Bool = false;
	public var offsetMap:Map<String, Array<Dynamic>>;
	public var checkbox:FlxSprite;

	public function new(x:Float, y:Float, curValue:Bool = false)
	{
		super(x, y);

		checked = curValue;
		offsetMap = new Map<String, Array<Dynamic>>();

		checkbox = new FlxSprite();
		checkbox.frames = Paths.getSparrowAtlas('checkboxThingie', 'shared');
		checkbox.animation.addByPrefix('false-finished', 'Check Box unselected');
		checkbox.animation.addByIndices('false', 'Check Box selecting animation', [10, 9, 8, 7, 6, 5, 4, 3, 2, 1], "", 24, false);
		checkbox.animation.addByPrefix('true-finished', 'Check Box Selected Static');
		checkbox.animation.addByIndices('true', 'Check Box selecting animation', [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], "", 24, false);
		checkbox.antialiasing = true;
		checkbox.setGraphicSize(Std.int(0.7 * checkbox.width));
		checkbox.updateHitbox();
		add(checkbox);
		addOffset('false', 20, 80);
		addOffset('true', 20, 70);
		addOffset('true-finished', getOffset('true', 0) - 8, getOffset('true', 1) - 22);
		addOffset('false-finished', 0, 0);

		switchCheck(checked);
		visible = true;
		alpha = 1;
	}

	public function addOffset(animName:String, xOffset:Float = 0, yOffset:Float = 0) {
		offsetMap[animName] = [xOffset, yOffset];
	}

	public function getOffset(anim:String, i:Int):Float
	{
		var theOffset:Float = 0;
		switch (i)
		{
			case 0:
				if (offsetMap.exists(anim))
					theOffset = offsetMap.get(anim)[0];
			case 1:
				if (offsetMap.exists(anim))
					theOffset = offsetMap.get(anim)[1];
		}

		return theOffset;
	}

	public function switchCheck(value:Bool = false) {
		checked = value;

		playAnim(Std.string(value), true);
	}

	public function playAnim(name:String, forced:Bool = false)
	{
		checkbox.animation.play(name, forced);
		
		if (offsetMap.exists(name))
			checkbox.offset.set(offsetMap.get(name)[0], offsetMap.get(name)[1]);
		else
			checkbox.offset.set(0, 0);
	}
}
