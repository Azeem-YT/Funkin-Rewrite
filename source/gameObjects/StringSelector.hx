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
import options.AtlasText;
import flixel.group.FlxSpriteGroup;
#if desktop
import sys.io.File;
import sys.FileSystem;
#end

class StringSelector extends FlxSpriteGroup
{
	public var menuText:AtlasText;
	public var alphaText:String = "";
	public var selectorRight:FlxSprite;
	public var selectorLeft:FlxSprite;
	var selected:Int = 0;

	public function new(x:Float, y:Float, curValue:String, defaultValue:String)
	{
		super(x, y);

		if (curValue != '' && curValue != null) alphaText = curValue; else alphaText = defaultValue;
		
		menuText = new AtlasText(0, 0, alphaText);
		add(menuText);

		selectorLeft = new FlxSprite(0, 0);
		selectorLeft.frames = Paths.getSparrowAtlas('campaign_menu_UI_assets');
		selectorLeft.animation.addByPrefix('idle', "arrow left");
		selectorLeft.animation.addByPrefix('press', "arrow push left");
		selectorLeft.animation.play('idle');
		add(selectorLeft);

		selectorRight = new FlxSprite(0, 0);
		selectorRight.frames = Paths.getSparrowAtlas('campaign_menu_UI_assets');
		selectorRight.animation.addByPrefix('idle', "arrow right");
		selectorRight.animation.addByPrefix('press', "arrow push right");
		selectorRight.animation.play('idle');
		add(selectorRight);

		alpha = 1;
		visible = true;
	}

	public function setText(text:String = 'Default')
		return menuText.text = text;

	override function update(elapsed:Float) {
		if (selectorLeft != null) {
			var selectorX:Float = 0;
			var selectorY:Float = 0;

			if (menuText.lastCharacter != null) {
				selectorX = menuText.firstCharacter.x - menuText.firstCharacter.width;
				selectorY = menuText.firstCharacter.y - 5;
			}

			if (selectorLeft.animation.curAnim != null && selectorLeft.animation.curAnim.finished)
				playAnim(selectorLeft, "idle");

			selectorLeft.x = selectorX;
			selectorLeft.y = selectorY;
		}
		
		if (selectorRight != null) {
			var selectorX:Float = 0;
			var selectorY:Float = 0;

			if (menuText.lastCharacter != null) {
				selectorX = menuText.lastCharacter.x + menuText.lastCharacter.width;
				selectorY = menuText.firstCharacter.y - 5;
			}
			
			if (selectorRight.animation.curAnim != null && selectorRight.animation.curAnim.finished)
				playAnim(selectorLeft, "idle");

			selectorRight.x = selectorX;
			selectorRight.y = selectorY;
		}

		super.update(elapsed);
	}

	public function playAnim(sprite:FlxSprite, anim:String, forced:Bool = false){
		if (sprite != null) {
			sprite.animation.play(anim, forced);
		}
	}

	public function onLeft() {
		playAnim(selectorLeft, 'press', true);
	}

	public function onRight() {
		playAnim(selectorRight, 'press', true);
	}
}
