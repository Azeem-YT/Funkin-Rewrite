package states;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import states.*;

import flixel.math.FlxMath;

using StringTools;

class MainMenuState extends MusicBeatState
{
	var curSelected:Int = 0;

	var menuItems:FlxTypedGroup<FlxSprite>;

	#if switch
	var optionShit:Array<String> = ['story mode', 'freeplay'];
	#else
	var optionShit:Array<String> = ['story mode', 'freeplay', 'donate', 'options'];
	#end

	var magenta:FlxSprite;
	var camFollow:FlxObject;

	var versionShit:FlxText;
	var gameVersion:String = "v2.7.1" + '\nNova Engine v' + TitleState.currentVersion;

	override function create()
	{
		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		if (!FlxG.sound.music.playing)
		{
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
		}

		persistentUpdate = true;

		var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
		bg.scrollFactor.x = 0;
		bg.scrollFactor.y = 0.18;
		bg.setGraphicSize(Std.int(bg.width * 1.1));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = true;
		add(bg);

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		magenta.scrollFactor.x = 0;
		magenta.scrollFactor.y = 0.18;
		magenta.setGraphicSize(Std.int(magenta.width * 1.1));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.antialiasing = true;
		magenta.color = 0xFFfd719b;
		add(magenta);

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		var tex = Paths.getSparrowAtlas('FNF_main_menu_assets');

		for (i in 0...optionShit.length)
		{
			var menuItem:FlxSprite = new FlxSprite(0, 60 + (i * 160));
			menuItem.frames = tex;
			menuItem.animation.addByPrefix('idle', optionShit[i] + " basic", 24);
			menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 24);
			menuItem.animation.play('idle');
			menuItem.ID = i;
			menuItems.add(menuItem);
			menuItem.scrollFactor.set();
			menuItem.antialiasing = true;
		}

		FlxG.camera.follow(camFollow, null, 0.06);
		
		var splitText:Array<String> = gameVersion.split('\n');
		var numberOfN:Int = splitText.length;

		versionShit = new FlxText(5, FlxG.height - (18 * numberOfN), 0, gameVersion, 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);

		changeItem();

		super.create();
	}

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8) {
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		if (!selectedSomethin) {
			if (controls.UI_UP_P) {
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(-1);
			}

			if (controls.UI_DOWN_P) {
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(1);
			}

			if (controls.BACK) {
				FlxG.switchState(new TitleState());
			}

			if (controls.ACCEPT) {
				switch (optionShit[curSelected]) {
					case 'donate':
						#if linux
						Sys.command('/usr/bin/xdg-open', ["https://ninja-muffin24.itch.io/funkin", "&"]);
						#else
						FlxG.openURL('https://ninja-muffin24.itch.io/funkin');
						#end
					default:
						selectMenu(optionShit[curSelected]);
				}
			}
		}

		super.update(elapsed);

		menuItems.forEach(function(spr:FlxSprite) {
			spr.screenCenter(X);
		});

		var menuItem:FlxSprite = menuItems.members[curSelected];

		camFollow.y = FlxMath.lerp(menuItem.y, (20 * curSelected), CoolUtil.elapsedLerp(elapsed * 10));
	}

	public function selectMenu(name:String = 'story mode') {
		var spr:FlxSprite = menuItems.members[curSelected];
		selectedSomethin = true;
		FlxG.sound.play(Paths.sound('confirmMenu'));

		for (i in 0...menuItems.members.length) {
			if (i != curSelected)
				FlxTween.tween(menuItems.members[i], {alpha: 0}, 0.4, {ease: FlxEase.quadOut});
		}

		FlxFlicker.flicker(magenta, 1.1, 0.15, false);

		FlxFlicker.flicker(spr, 1, 0.15, false, false, function(flick:FlxFlicker) {
			var daChoice:String = optionShit[curSelected];

			switch (daChoice) {
				case 'story mode':
					FlxG.switchState(new StoryMenuState());
					trace("Story Menu Selected");
				case 'freeplay':
					FlxG.switchState(new FreeplayState());
				case 'options':
					FlxG.switchState(new options.OptionsState());
			}
		});
	}

	function changeItem(huh:Int = 0)
	{
		curSelected += huh;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;

		menuItems.forEach(function(spr:FlxSprite) {
			spr.animation.play('idle');

			if (spr.ID == curSelected) {
				spr.animation.play('selected');
				camFollow.setPosition(spr.getGraphicMidpoint().x, spr.getGraphicMidpoint().y);
			}

			spr.updateHitbox();
		});
	}
}
