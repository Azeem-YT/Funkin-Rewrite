package states;

import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import lime.utils.Assets;
import haxe.Json;
import haxe.format.JsonParser;
import flixel.FlxCamera;
import flixel.effects.FlxFlicker;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

import data.*;
import states.*;
import gameObjects.*;
import engine.*;
import states.StoryMenuState.WeekFile;

using StringTools;

typedef SongData = {
	var hidden:Bool;
	var song:String;
	var charIcon:String;
	var weekColors:Array<Int>;
	var difficultys:Array<String>;
}

class FreeplayState extends MusicBeatState
{
	public var songs:Array<SongMetadata> = [];
	var checkSongs:Array<SongMetadata> = [];

	public var selector:FlxText;
	public var curSelected:Int = 0;
	public var curDifficulty:Int = 1;

	public var scoreText:FlxText;
	public var diffText:FlxText;
	public var lerpScore:Int = 0;
	public var intendedScore:Int = 0;
	public var intendedColor:FlxColor = FlxColor.WHITE;
	public var scoreBG:FlxSprite;
	public var bg:FlxSprite;
	public var colorTween:FlxTween;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;

	private var iconArray:Array<HealthIcon> = [];

	public var diffArray:Array<String> = ['easy', 'normal', 'hard'];
	public var camMAIN:FlxCamera;

	public var diff:String = '';

	var weekData:Array<WeekFile> = [];

	override function create()
	{
		// var gameCam:FlxCamera = FlxG.camera;
		camMAIN = new FlxCamera(0, 0, FlxG.width, FlxG.height);
		FlxG.cameras.reset(camMAIN);
		FlxCamera.defaultCameras = [camMAIN];

		var directorys:Array<String> = [Paths.getPreloadPath()];

		#if sys
		directorys.insert(0, Paths.mods());
		#end

		#if sys
		for (i in 0...directorys.length) {
			var dir:String = directorys[i] + 'weeks/';

			if (FileSystem.isDirectory(dir)) {
				for (file in FileSystem.readDirectory(dir)) {
					if (file.endsWith('.json')) {
						var weekFile:WeekFile = new WeekFile(dir + file);

						if (StoryMenuState.unlockedWeeks.exists(weekFile.weekData))
							weekFile.weekUnlocked = true;

						weekData.push(weekFile);
					}
				}
			}
		}
		#else
		var weekList:Array<String> = CoolUtil.coolTextFile(Paths.getPreloadPath('weeks/weekList.txt'));
		for (i in 0...weekList.length) {
			var file:String = weekList[i];

			if (Assets.exists(Paths.getPreloadPath('weeks/$file.json'))) {
				var weekFile:WeekFile = new WeekFile(Paths.getPreloadPath('weeks/$file.json'));

				if (StoryMenuState.unlockedWeeks.exists(weekFile.weekData) || weekFile.startUnlocked)
					weekFile.weekUnlocked = true;

				if (!weekFile.hiddenFreeplay)
					weekData.push(weekFile); 
			}
		}
		#end

		for (i in 0...weekData.length) {
			var weekFile:WeekFile = weekData[i];
			var weekSongs:Array<String> = [];
			var iconArray:Array<String> = [];

			if (weekFile != null) {
				for (a in 0...weekFile.songs.length) {
					var song:Array<Dynamic> = weekFile.songs[a];
					var freeplayColor:Array<Int> = weekFile.freeplayColor;
					var weekData:String = weekFile.weekData;
					var songName:String = song[0];
					var icon:String = 'bf';

					if (song[1] != null)
						icon = song[1];

					var difficultys:Array<String> = weekFile.difficultys;

					if (icon == null) icon = 'bf';

					if (weekData == null) weekData = 'week' + i;

					if (freeplayColor == null) freeplayColor = [255, 255, 255];

					if (difficultys == null) difficultys = ['easy', 'normal', 'hard'];

					addSong(songName, weekData, icon, freeplayColor, difficultys);
				}
			}
		}

		if (songs.length <= 0) {
			addSong('Tutorial', 'tutorial', 'gf', [255, 255, 255], ['easy', 'normal', 'hard']);
		}

		if (FlxG.sound.music != null) {
			if (!FlxG.sound.music.playing)
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
		}

		var isDebug:Bool = false;

		#if debug
		isDebug = true;
		#end
		/*
		if (StoryMenuState.weekUnlocked[2] || isDebug)
			addWeek(['Bopeebo', 'Fresh', 'Dadbattle'], 1, ['dad']);

		if (StoryMenuState.weekUnlocked[2] || isDebug)
			addWeek(['Spookeez', 'South', 'Monster'], 2, ['spooky']);

		if (StoryMenuState.weekUnlocked[3] || isDebug)
			addWeek(['Pico', 'Philly', 'Blammed'], 3, ['pico']);

		if (StoryMenuState.weekUnlocked[4] || isDebug)
			addWeek(['Satin-Panties', 'High', 'Milf'], 4, ['mom']);

		if (StoryMenuState.weekUnlocked[5] || isDebug)
			addWeek(['Cocoa', 'Eggnog', 'Winter-Horrorland'], 5, ['parents-christmas', 'parents-christmas', 'monster-christmas']);

		if (StoryMenuState.weekUnlocked[6] || isDebug)
			addWeek(['Senpai', 'Roses', 'Thorns'], 6, ['senpai', 'senpai', 'spirit']); */

		// LOAD MUSIC

		// LOAD CHARACTERS

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		add(bg);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, songs[i].songName, true, false);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpSongs.add(songText);

			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			add(icon);

			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		// scoreText.autoSize = false;
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		// scoreText.alignment = RIGHT;

		scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 66, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		add(diffText);

		add(scoreText);

		changeSelection();
		changeDiff();

		// FlxG.sound.playMusic(Paths.music('title'), 0);
		// FlxG.sound.music.fadeIn(2, 0, 0.8);
		selector = new FlxText();

		selector.size = 40;
		selector.text = ">";
		// add(selector);

		var swag:Alphabet = new Alphabet(1, 0, "swag");

		// JUST DOIN THIS SHIT FOR TESTING!!!
		/* 
			var md:String = Markdown.markdownToHtml(Assets.getText('CHANGELOG.md'));

			var texFel:TextField = new TextField();
			texFel.width = FlxG.width;
			texFel.height = FlxG.height;
			// texFel.
			texFel.htmlText = md;

			FlxG.stage.addChild(texFel);

			// scoreText.textField.htmlText = md;

			trace(md);
		 */

		super.create();
	}

	public function addSong(song:String, weekName:String, songCharacter:String, colors:Array<Int>, difficultys:Array<String>) {
		songs.push(new SongMetadata(song, weekName, songCharacter, colors, difficultys));
	}

	public function jsonFileName(jsonName:String):String {
		return jsonName.replace('.json', '');
	}

	public function addWeek(songs:Array<String>, weekName:String, ?songCharacters:Array<String>, ?colors:Array<Int>, ?difficultys:Array<String>)
	{
		if (songCharacters == null) {
			songCharacters = [];

			for (i in 0...songs.length)
				songCharacters.push('bf');
		}

		var num:Int = 0;
		for (song in songs) {
			addSong(song, weekName, songCharacters[num], colors, difficultys);

			if (songCharacters.length != 1)
				num++;
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, 0.4));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;

		scoreText.text = "PERSONAL BEST: " + Math.round(lerpScore);
		positionHighscore();

		if (controls.UI_UP_P)
			changeSelection(-1);

		if (controls.UI_DOWN_P)
			changeSelection(1);

		if (controls.UI_LEFT_P)
			changeDiff(-1);
		if (controls.UI_RIGHT_P)
			changeDiff(1);

		if (controls.BACK)
			FlxG.switchState(new MainMenuState());

		if (controls.ACCEPT)
			loadSong();
	}

	public function loadSong() {
		for (i in 0...grpSongs.members.length) {
			if (i == curSelected)
				grpSongs.members[i].moveX = false;
			else
				grpSongs.members[i].targetY = grpSongs.members[curSelected].targetY + 5; //Make Sure it goes off screen
		}

		FlxG.sound.play(Paths.sound('confirmMenu'));

		var oldX:Float = grpSongs.members[curSelected].x;
		var screenCenteredX:Float = 0;
		grpSongs.members[curSelected].screenCenter(X);
		screenCenteredX = grpSongs.members[curSelected].x;
		grpSongs.members[curSelected].x = oldX;

		FlxTween.tween(grpSongs.members[curSelected], {x: screenCenteredX - 50}, 0.25);
		FlxFlicker.flicker(grpSongs.members[curSelected], 1, 0.06, true, false, function(flicker:FlxFlicker){
			var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), diff);

			PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
			PlayState.isStoryMode = false;
			PlayState.diffArray = diffArray;
			PlayState.storyDifficulty = curDifficulty;

			if (PlayState.SONG != null)
				LoadingState.loadAndSwitchState(new PlayState());
			else {
				ErrorState.song = songs[curSelected].songName;
				FlxG.switchState(new ErrorState());
			}
		});
	}

	function changeDiff(change:Int = 0)
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = diffArray.length - 1;
		if (curDifficulty >= diffArray.length)
			curDifficulty = 0;

		if (diffArray[curDifficulty] != '-' + diffArray[curDifficulty])
			diff = '-' + diffArray[curDifficulty];
		else
			diff = diffArray[curDifficulty];

		if (diff == '-normal')
			diff = '';

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, diff);
		#end
		diffText.text = "< " + diffArray[curDifficulty].toUpperCase() + " >";
	}

	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;

		if (curSelected >= songs.length)
			curSelected = 0;

		diffArray = songs[curSelected].difficultys;

		// selector.y = (70 * curSelected) + 30;

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, diff);
		// lerpScore = 0;
		#end

		var bullShit:Int = 0;

		for (i in 0...iconArray.length) {
			iconArray[i].alpha = 0.6;
		}

		iconArray[curSelected].alpha = 1;

		if (songs[curSelected].songColors != null)
		{
			var color:FlxColor = FlxColor.fromRGB(songs[curSelected].songColors[0], songs[curSelected].songColors[1], songs[curSelected].songColors[2]);

			if (color != intendedColor)
			{
				if (colorTween != null)
					colorTween.cancel;

				intendedColor = color;

				colorTween = FlxTween.color(bg, 1, bg.color, intendedColor, {
					onComplete: function(tween:FlxTween){
						colorTween = null;
					}
				});
			}
		}
		else
		{
			var songColors:Array<Int> = songs[curSelected].songColors;
			var cool:FlxColor = FlxColor.fromRGB(songColors[0], songColors[1], songColors[2]);

			if (cool != intendedColor) {
				if (colorTween != null)
					colorTween.cancel();

				intendedColor = cool;

				colorTween = FlxTween.color(bg, 1, bg.color, intendedColor, {
					onComplete: function(tween:FlxTween){
						colorTween = null;
					}
				});
			}

		}

		for (item in grpSongs.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));
			}
		}

		changeDiff();
	}

	private function positionHighscore()
	{
		scoreText.x = (FlxG.width - scoreText.width - 6);
		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = (FlxG.width - scoreBG.scale.x / 2);
		diffText.x = Std.int(scoreBG.x + (scoreBG.width / 2));
		diffText.x -= diffText.width / 2;
	}

	private function songDiff(text:String):String {
		text = StringTools.replace(text, '.json', "");
		text = StringTools.replace(text, songs[curSelected].songName.toLowerCase() + '-', "");
		return text;
	}
}

class SongMetadata
{
	public var songName:String = "";
	public var weekName:String = 'default';
	public var songCharacter:String = "";
	public var songColors:Array<Int>;
	public var difficultys:Array<String> = ['easy', 'normal', 'hard'];

	public function new(song:String, weekName:String, songCharacter:String, colors:Array<Int>, difficultys:Array<String>)
	{
		this.songName = song;
		this.weekName = weekName;
		this.songCharacter = songCharacter;
		this.songColors = colors;
		this.difficultys = difficultys;

		if (colors == null)
			this.songColors = [255, 255, 255];

		if (difficultys == null)
			this.difficultys = ['easy', 'normal', 'hard'];
	}
}
