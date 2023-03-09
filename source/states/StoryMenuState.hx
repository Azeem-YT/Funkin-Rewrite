package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.net.curl.CURLCode;
import helpers.*;
import haxe.Json;
import haxe.format.JsonParser;
import flixel.graphics.FlxGraphic;
import sys.FileSystem;
import sys.io.File;

import data.*;
import states.*;
import gameObjects.*;
import engine.*;

using StringTools;

typedef WeekJson =
{
	var songs:Array<String>;
	var menuChars:Array<String>;
	var startUnlocked:Bool;
	var weekName:String;
	var difficultys:Array<String>;
	var weekImg:String;
	var weekData:String;
}

class StoryMenuState extends MusicBeatState
{
	public static var unlockedWeeks:Map<String, Bool> = new Map<String, Bool>();

	public var weekData:Array<WeekFile> = [];
	public var curFile:WeekFile = null;

	public var diffArray:Array<String> = [
		'easy',
		'normal',
		'hard'
	];

	public var scoreText:FlxText;

	public var curDifficulty:Int = 1;

	public var txtWeekTitle:FlxText;

	public var curWeek:Int = 0;

	public var txtTracklist:FlxText;

	public var grpWeekText:FlxTypedGroup<MenuItem>;
	public var grpWeekCharacters:FlxTypedGroup<MenuCharacter>;

	public var grpLocks:FlxTypedGroup<FlxSprite>;

	public var difficultySelectors:FlxGroup;
	public var sprDifficulty:FlxSprite;
	public var leftArrow:FlxSprite;
	public var rightArrow:FlxSprite;

	public static var instance:StoryMenuState;

	override function create()
	{
		instance = this;

		if (FlxG.save.data.unlockedWeeks != null) {
			unlockedWeeks = FlxG.save.data.unlockedWeeks;

			if (!unlockedWeeks.exists('tutorial'))
				setUnlocked('tutorial');
		}
		else
		{
			if (!unlockedWeeks.exists('tutorial'))
				setUnlocked('tutorial');

			FlxG.save.data.unlockedWeeks = unlockedWeeks;
		}

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		if (FlxG.sound.music != null)
		{
			if (!FlxG.sound.music.playing)
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
		}

		persistentUpdate = persistentDraw = true;

		scoreText = new FlxText(10, 10, 0, "SCORE: 49324858", 36);
		scoreText.setFormat("VCR OSD Mono", 32);

		txtWeekTitle = new FlxText(FlxG.width * 0.7, 10, 0, "", 32);
		txtWeekTitle.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, RIGHT);
		txtWeekTitle.alpha = 0.7;

		var rankText:FlxText = new FlxText(0, 10);
		rankText.text = 'RANK: GREAT';
		rankText.setFormat(Paths.font("vcr.ttf"), 32);
		rankText.size = scoreText.size;
		rankText.screenCenter(X);

		var ui_tex = Paths.getSparrowAtlas('campaign_menu_UI_assets');
		var yellowBG:FlxSprite = new FlxSprite(0, 56).makeGraphic(FlxG.width, 400, 0xFFF9CF51);

		grpWeekText = new FlxTypedGroup<MenuItem>();
		add(grpWeekText);

		var blackBarThingie:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 56, FlxColor.BLACK);
		add(blackBarThingie);

		grpWeekCharacters = new FlxTypedGroup<MenuCharacter>();

		grpLocks = new FlxTypedGroup<FlxSprite>();
		add(grpLocks);
		
		var directorys:Array<String> = [Paths.mods(), Paths.getPreloadPath()];

		for (i in 0...directorys.length) {
			var dir:String = directorys[i] + 'weeks/';

			if (FileSystem.isDirectory(dir)) {
				for (file in FileSystem.readDirectory(dir)) {
					if (file.endsWith('.json')) {
						var weekFile:WeekFile = new WeekFile(dir + file);

						if (unlockedWeeks.exists(weekFile.weekData))
							weekFile.weekUnlocked = true;

						weekData.push(weekFile);
					}
				}
			}

		}

		curFile = weekData[curWeek];

		for (i in 0...weekData.length)
		{
			var isUnlocked:Bool = weekData[i].weekUnlocked;

			var weekThing:MenuItem = new MenuItem(0, yellowBG.y + yellowBG.height + 10, weekData[i].weekImage);
			weekThing.y += ((weekThing.height + 20) * i);
			weekThing.targetY = i;
			grpWeekText.add(weekThing);

			weekThing.screenCenter(X);
			weekThing.antialiasing = true;
			// weekThing.updateHitbox();

			// Needs an offset thingie
			if (!isUnlocked)
			{
				var lock:FlxSprite = new FlxSprite(weekThing.width + 10 + weekThing.x);
				lock.frames = ui_tex;
				lock.animation.addByPrefix('lock', 'lock');
				lock.animation.play('lock');
				lock.ID = i;
				lock.antialiasing = true;
				grpLocks.add(lock);
			}
		}

		for (char in 0...3)
		{
			var weekCharacterThing:MenuCharacter = new MenuCharacter((FlxG.width * 0.25) * (1 + char) - 150, curFile.weekCharacters[char]);
			weekCharacterThing.y += 70;
			weekCharacterThing.antialiasing = true;
			switch (weekCharacterThing.character)
			{
				case 'dad':
					weekCharacterThing.setGraphicSize(Std.int(weekCharacterThing.width * 0.5));
					weekCharacterThing.updateHitbox();

				case 'bf':
					weekCharacterThing.setGraphicSize(Std.int(weekCharacterThing.width * 0.9));
					weekCharacterThing.updateHitbox();
					weekCharacterThing.x -= 80;
				case 'gf':
					weekCharacterThing.setGraphicSize(Std.int(weekCharacterThing.width * 0.5));
					weekCharacterThing.updateHitbox();
				case 'pico':
					weekCharacterThing.flipX = true;
				case 'parents-christmas':
					weekCharacterThing.setGraphicSize(Std.int(weekCharacterThing.width * 0.9));
					weekCharacterThing.updateHitbox();
			}

			grpWeekCharacters.add(weekCharacterThing);
		}

		difficultySelectors = new FlxGroup();
		add(difficultySelectors);

		leftArrow = new FlxSprite(grpWeekText.members[0].x + grpWeekText.members[0].width + 10, grpWeekText.members[0].y + 10);
		leftArrow.frames = ui_tex;
		leftArrow.animation.addByPrefix('idle', "arrow left");
		leftArrow.animation.addByPrefix('press', "arrow push left");
		leftArrow.animation.play('idle');
		difficultySelectors.add(leftArrow);

		sprDifficulty = new FlxSprite(leftArrow.x + 130, leftArrow.y);
		changeDifficulty();
		difficultySelectors.add(sprDifficulty);

		rightArrow = new FlxSprite(sprDifficulty.x + sprDifficulty.width + 50, leftArrow.y);
		rightArrow.frames = ui_tex;
		rightArrow.animation.addByPrefix('idle', 'arrow right');
		rightArrow.animation.addByPrefix('press', "arrow push right", 24, false);
		rightArrow.animation.play('idle');
		difficultySelectors.add(rightArrow);

		add(yellowBG);
		add(grpWeekCharacters);

		txtTracklist = new FlxText(FlxG.width * 0.05, yellowBG.x + yellowBG.height + 100, 0, "Tracks", 32);
		txtTracklist.alignment = CENTER;
		txtTracklist.font = rankText.font;
		txtTracklist.color = 0xFFe55777;
		add(txtTracklist);
		// add(rankText);
		add(scoreText);
		add(txtWeekTitle);

		updateText();

		super.create();
	}

	override function update(elapsed:Float)
	{
		// scoreText.setFormat('VCR OSD Mono', 32);
		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, 0.5));

		scoreText.text = "WEEK SCORE:" + lerpScore;

		txtWeekTitle.text = curFile.weekName;
		txtWeekTitle.x = FlxG.width - (txtWeekTitle.width + 10);

		// FlxG.watch.addQuick('font', scoreText.font);

		difficultySelectors.visible = curFile.weekUnlocked;

		grpLocks.forEach(function(lock:FlxSprite)
		{
			lock.y = grpWeekText.members[lock.ID].y;
		});

		if (!movedBack)
		{
			if (!selectedWeek) {
				if (controls.UI_UP_P)
					changeWeek(-1);

				if (controls.UI_DOWN_P)
					changeWeek(1);

				if (controls.UI_RIGHT)
					rightArrow.animation.play('press')
				else
					rightArrow.animation.play('idle');

				if (controls.UI_LEFT)
					leftArrow.animation.play('press');
				else
					leftArrow.animation.play('idle');

				if (controls.UI_RIGHT_P)
					changeDifficulty(1);

				if (controls.UI_LEFT_P)
					changeDifficulty(-1);
			}

			if (controls.ACCEPT) {
				selectWeek();
			}
		}

		//if (controls.BACK && !movedBack && !selectedWeek)
		//{
		//	FlxG.sound.play(Paths.sound('cancelMenu'));
		//	movedBack = true;
		//	FlxG.switchState(new MainMenuState());
		//}

		super.update(elapsed);
	}

	var movedBack:Bool = false;
	var selectedWeek:Bool = false;
	var stopspamming:Bool = false;

	function selectWeek()
	{
		if (curWeek >= 0 && curFile.weekUnlocked)
		{
			if (stopspamming == false) {
				FlxG.sound.play(Paths.sound('confirmMenu'));

				grpWeekText.members[curWeek].startFlashing();
				grpWeekCharacters.members[1].animation.play('bfConfirm');
				stopspamming = true;
			}

			PlayState.storyPlaylist = curFile.songs;
			PlayState.isStoryMode = true;
			selectedWeek = true;

			var diffic = "";

			diffic = '-' + diffArray[curDifficulty];

			if (diffic == '-normal')
				diffic = '';
			
			PlayState.diffArray = diffArray;
			PlayState.storyDifficulty = curDifficulty;
			PlayState.weekName = curFile.weekData;

			PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + diffic, PlayState.storyPlaylist[0].toLowerCase());
			PlayState.storyWeek = curWeek;
			PlayState.campaignScore = 0;

			if (PlayState.SONG == null) {
				ErrorState.song = PlayState.storyPlaylist[0];
				FlxG.switchState(new ErrorState());
			}
			else
				new FlxTimer().start(1, function(tmr:FlxTimer) {
					LoadingState.loadAndSwitchState(new PlayState(), true);
				});
		}
	}

	function changeDifficulty(change:Int = 0):Void
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = diffArray.length - 1;
		if (curDifficulty >= diffArray.length)
			curDifficulty = 0;

		var diffGraphic:FlxGraphic = difficultyGraphic(diffArray[curDifficulty]);

		if (sprDifficulty.graphic != diffGraphic) {
			sprDifficulty.loadGraphic(diffGraphic);
			sprDifficulty.x = leftArrow.x + (260 - sprDifficulty.width) / 2;
		}

		sprDifficulty.alpha = 0;

		// USING THESE WEIRD VALUES SO THAT IT DOESNT FLOAT UP
		sprDifficulty.y = leftArrow.y - 15;

		#if !switch
		intendedScore = Highscore.getWeekScore(weekData[curWeek].weekData, diffArray[curDifficulty]);
		#end

		FlxTween.tween(sprDifficulty, {y: leftArrow.y + 15, alpha: 1}, 0.07);
	}

	var lerpScore:Int = 0;
	var intendedScore:Int = 0;

	function changeWeek(change:Int = 0):Void
	{
		curWeek += change;

		if (curWeek >= weekData.length)
			curWeek = 0;
		if (curWeek < 0)
			curWeek = weekData.length - 1;

		curFile = weekData[curWeek];

		if (curFile.difficultys != null)
			diffArray = curFile.difficultys;
		else
			diffArray = ['easy', 'normal', 'hard'];

		var bullShit:Int = 0;

		for (item in grpWeekText.members) {
			item.targetY = bullShit - curWeek;
			if (item.targetY == Std.int(0) && curFile.weekUnlocked)
				item.alpha = 1;
			else
				item.alpha = 0.6;

			bullShit++;
		}

		FlxG.sound.play(Paths.sound('scrollMenu'));

		updateText();
	}

	function updateText()
	{
		grpWeekCharacters.members[0].animation.play(curFile.weekCharacters[0]);
		grpWeekCharacters.members[1].animation.play(curFile.weekCharacters[1]);
		grpWeekCharacters.members[2].animation.play(curFile.weekCharacters[2]);

		txtTracklist.text = "Tracks\n";
		if (grpWeekCharacters.members[0].animation.curAnim != null) {
			switch (grpWeekCharacters.members[0].animation.curAnim.name)
			{
				case 'parents-christmas':
					grpWeekCharacters.members[0].offset.set(200, 200);
					grpWeekCharacters.members[0].setGraphicSize(Std.int(grpWeekCharacters.members[0].width * 0.99));

				case 'senpai':
					grpWeekCharacters.members[0].offset.set(130, 0);
					grpWeekCharacters.members[0].setGraphicSize(Std.int(grpWeekCharacters.members[0].width * 1.4));

				case 'mom':
					grpWeekCharacters.members[0].offset.set(100, 200);
					grpWeekCharacters.members[0].setGraphicSize(Std.int(grpWeekCharacters.members[0].width * 1));

				case 'dad':
					grpWeekCharacters.members[0].offset.set(120, 200);
					grpWeekCharacters.members[0].setGraphicSize(Std.int(grpWeekCharacters.members[0].width * 1));

				default:
					grpWeekCharacters.members[0].offset.set(100, 100);
					grpWeekCharacters.members[0].setGraphicSize(Std.int(grpWeekCharacters.members[0].width * 1));
					// grpWeekCharacters.members[0].updateHitbox();
			}
		}

		var songArray:Array<String> = weekData[curWeek].songs;

		for (i in songArray) {
			txtTracklist.text += "\n" + i;
		}

		txtTracklist.text = txtTracklist.text.toUpperCase();

		txtTracklist.screenCenter(X);
		txtTracklist.x -= FlxG.width * 0.35;

		#if !switch
		intendedScore = Highscore.getWeekScore(weekData[curWeek].weekData, diffArray[curDifficulty]);
		#end
	}

	public static function setUnlocked(weekName:String) {
		if (!unlockedWeeks.exists(weekName)) {
			unlockedWeeks.set(weekName, true);
		}
	}

	public function difficultyGraphic(diff:String = 'normal'):FlxGraphic {
		var graphic:FlxSprite = new FlxSprite();

		if (diff != null && diff != '')	{
			graphic.loadGraphic(Paths.image('story_assets/' + diff));
		}

		if (graphic == null)
			graphic.loadGraphic('normal');

		return graphic.graphic;
	}

	public function getHidden(week:String):Bool
	{
		var returnBool:Bool = !unlockedWeeks.get(week);

		return returnBool;
	}
}

class WeekFile
{
	public var songs:Array<String> = ['Tutorial'];
	public var weekCharacters:Array<Dynamic> = ['dad', 'bf', 'gf'];
	public var weekUnlocked:Bool = true;
	public var weekScore:Int = 0;
	public var startUnlocked:Bool = true;
	public var weekImage:String = 'week0';
	public var weekName:String = 'defaultWeek';
	public var difficultys:Array<String> = ['easy', 'normal', 'hard'];
	public var weekData:String = 'defaultJson';
	public var jsonFile:String = 'defaultJson';

	public function new(jsonPath:String = '') {
		var loadedJson:WeekJson = parseJson(jsonPath);

		var splitPath:Array<String> = jsonPath.split('/');
		jsonFile = StringTools.replace(splitPath[splitPath.length - 1], '.json', '');

		this.songs = loadedJson.songs;
		this.weekCharacters = loadedJson.menuChars;
		this.startUnlocked = loadedJson.startUnlocked;
		this.difficultys = loadedJson.difficultys;
		this.weekImage = loadedJson.weekImg;
		this.weekName = loadedJson.weekName;
		
		if (loadedJson.weekData != null)
			this.weekData = loadedJson.weekData;
		else
			this.weekData = jsonFile;
	}

	public function parseJson(path:String = null):WeekJson {
		var rawJson:WeekJson = null;

		if (path != null && path != '') {
			if (FileSystem.exists(path))
			rawJson = Json.parse(File.getContent(path));
		}

		if (rawJson == null)
			rawJson = defaultWeek();

		return rawJson;
	}

	public function defaultWeek():WeekJson {
		var jsonData:WeekJson;

		jsonData = {
			"songs": ['Tutorial'],
			"menuChars": ['dad', 'bf', 'gf'],
			"startUnlocked": true,
			"difficultys": ['easy', 'normal', 'hard'],
			"weekName": "defaultWeek",
			"weekImg": "week0",
			"weekData": "defaultWeek"
		};

		return jsonData;
	}
}
