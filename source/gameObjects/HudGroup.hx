package gameObjects;

import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import states.*;
import data.*;

class HudGroup extends FlxSpriteGroup
{
	public var scoreTxt:FlxText;
	public var watermark:FlxText;

	public var healthBarBG:FlxSprite;
	public var healthBar:FlxBar; 
	public var healthBarMax:Float = 2;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;

	public var gameInstance:PlayState;

	public function new(?instance:PlayState = null) {
		super();

		if (instance == null) gameInstance = new PlayState(); else gameInstance = instance;

		var healthP1:String = 'face';
		var healthP2:String = 'face';

		reloadHealthBar();

		if (PlayState.dad != null) healthP2 = PlayState.dad.healthIcon;
		if (PlayState.boyfriend != null) healthP1 = PlayState.boyfriend.healthIcon;

		if (PlayerPrefs.playOpponent) {
			healthP2 = PlayState.boyfriend.healthIcon;
			healthP1 = PlayState.dad.healthIcon;
		}

		iconP1 = new HealthIcon(healthP1, true, null);
		iconP1.y = healthBar.y - (iconP1.height / 2);
		add(iconP1);

		iconP2 = new HealthIcon(healthP2, false, null);
		iconP2.y = healthBar.y - (iconP2.height / 2);
		add(iconP2);

		var scoreX:Float = FlxG.width / 20;

		scoreTxt = new FlxText(scoreX, FlxG.height * 0.8, 0, "");
		scoreTxt.setFormat(Paths.font('vcr.ttf'), 26);
		scoreTxt.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 1.5);
		scoreTxt.scrollFactor.set();
		add(scoreTxt);

		watermark = new FlxText(0, 0, 0, "Funkin' Rewrite");
		watermark.setFormat(Paths.font('vcr.ttf'), 18);
		watermark.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 2);
		add(watermark);
	}

	public function reloadHealthBar() {
		if (healthBar != null) remove(healthBar);
		if (healthBarBG != null) remove(healthBarBG);

		var BarX:Float = FlxG.width / 2;

		healthBarBG = new FlxSprite(BarX, FlxG.height * 0.9).loadGraphic(Paths.image('healthBar'));
		healthBarBG.scrollFactor.set();
		add(healthBarBG);

		if (PlayerPrefs.downscroll)
			healthBarBG.y = 50;

		var colorArrayP1:Array<Int> = [128, 128, 128];
		var colorArrayP2:Array<Int> = [128, 128, 128];

		if (PlayState.dad != null) colorArrayP1 = PlayState.dad.healthColors;	
		if (PlayState.boyfriend != null) colorArrayP2 = PlayState.boyfriend.healthColors;

		if (PlayerPrefs.playOpponent) {
			colorArrayP1 = PlayState.boyfriend.healthColors;
			colorArrayP2 = PlayState.dad.healthColors;
		}

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), gameInstance,
			'health', 0, healthBarMax);
		healthBar.scrollFactor.set();
		healthBar.createFilledBar(FlxColor.fromRGB(colorArrayP1[0], colorArrayP1[1], 
		colorArrayP1[2]), FlxColor.fromRGB(colorArrayP2[0], colorArrayP2[1], 
		colorArrayP2[2]));
		add(healthBar);
	}
}