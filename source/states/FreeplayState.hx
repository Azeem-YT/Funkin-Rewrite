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
import sys.FileSystem;
import sys.io.File;
import flixel.FlxCamera;

import data.*;
import states.*;
import gameObjects.*;
import engine.*;

using StringTools;

typedef FreeplayData = {
	var songs:Array<String>;
	var weekColors:Array<Int>;
	var difficultys:Array<String>;
}

typedef SongData = {
	var hidden:Bool;
	var song:String;
	var charIcon:String;
	var colors:Array<Int>;
	var hiddenUntilUnlocked:Bool;
}

class FreeplayState extends MusicBeatState
{
	var songs:Array<SongMetadata> = [];
	var checkSongs:Array<SongMetadata> = [];

	var selector:FlxText;
	var curSelected:Int = 0;
	var curDifficulty:Int = 1;

	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var intendedScore:Int = 0;
	var scoreBG:FlxSprite;
	var bg:FlxSprite;
	var intendedColor:FlxColor = FlxColor.WHITE;
	var colorTween:FlxTween;
	var songColors:Map<String, Array<Int>> = [];
	var coolColors:Map<Int, Array<Int>> = [
		0 => [146, 113, 253],
		1 => [146, 113, 253],
		2 => [146, 113, 253],
		3 => [148, 22, 83],
		4 => [252, 150, 215],
		5 => [160, 209, 255],
		6 => [255, 120, 191],
	];
	var jsonList:Array<FreeplayData> = [];
	var songList:Array<Dynamic> = [];
	var diffMap:Map<String, Array<String>> = [];

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;

	private var iconArray:Array<HealthIcon> = [];

	public static var diffArray:Array<String> = ['easy', 'normal', 'hard'];
	public var pushedSongs:Map<String, Bool>;
	public var camMAIN:FlxCamera;

	public var diff:String = '';

	override function create()
	{
		// var gameCam:FlxCamera = FlxG.camera;
		camMAIN = new FlxCamera(0, 0, FlxG.width, FlxG.height);
		FlxG.cameras.reset(camMAIN);
		FlxCamera.defaultCameras = [camMAIN];

		pushedSongs = new Map<String, Bool>();
		pushedSongs.clear();

		var directorys:Array<String> = [Paths.mods(), Paths.getPreloadPath()];

		for (i in 0...directorys.length)
		{
			var initSonglist = CoolUtil.coolTextFile(directorys[i] + 'data/freeplaySonglist.txt');
			var jsonDir:String = directorys[i] + 'freeplay/';

			if (initSonglist.length > 0 && initSonglist != null) {
				for (i in 0...initSonglist.length) {
					var stuff:Array<String> = initSonglist[i].split(',');
					songList.push([stuff[0], stuff[2], stuff[3], stuff[1]]);
				}
			}

			if (FileSystem.exists(jsonDir))
			{
				for (file in FileSystem.readDirectory(jsonDir))
				{
					if (file.endsWith('.json') && !diffMap.exists(jsonFileName(file)))
					{
						var jsonData = Json.parse(File.getContent(jsonDir + file));
						var jsonName = StringTools.replace(file, ".json", "");
						trace("Trying to load Json: " + file);

						if (jsonData != null)
						{
							for (i in 0...jsonData.songs.length)
							{
								var songData = jsonData.songs[i];

								var isUnlocked:Bool = true;

								if (songData.hiddenUntilUnlocked)
								{
									if (Highscore.songBeat(songData.song))
										isUnlocked = true;
									else
										isUnlocked = false;
								}

								if (isUnlocked) {
									if (songData.colors == null)
										songList.push([songData.song, songData.charIcon, (jsonData.weekColors != null ? jsonData.weekColors : [146, 113, 253])]);
									else
										songList.push([songData.song, songData.charIcon, songData.colors]);
								}
							}
						}

					}
					else
						trace('File has an error');

					for (i in 0...songList.length) {
						if (songList[i][3] != null)
							checkSongs.push(new SongMetadata(songList[i][0], songList[i][3], songList[i][1], songList[i][2]));
						else
							checkSongs.push(new SongMetadata(songList[i][0], -1, songList[i][1], songList[i][2]));
					}


				}
			}
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

		for (i in 0...checkSongs.length) {
			if (checkSongs[i].songName != null && checkSongs[i].songName != '')
				songs.push(new SongMetadata(checkSongs[i].songName, checkSongs[i].week, checkSongs[i].songCharacter, checkSongs[i].songColors));
		}

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

	public function addSong(songName:String, weekNum:Int, songCharacter:String, colors:Array<Int>)
	{
		songs.push(new SongMetadata(songName, weekNum, songCharacter, (colors == null ? [0, 0, 0] : colors)));
	}

	public function jsonFileName(jsonName:String):String {
		return jsonName.replace('.json', '');
	}

	public function addWeek(songs:Array<String>, weekNum:Int, ?songCharacters:Array<String>, ?colors:Array<Int>)
	{
		if (songCharacters == null)
			songCharacters = ['bf'];

		var num:Int = 0;
		for (song in songs)
		{
			addSong(song, weekNum, songCharacters[num], colors);

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

		var upP = controls.UI_UP_P;
		var downP = controls.UI_DOWN_P;
		var accepted = controls.ACCEPT;

		if (upP)
		{
			changeSelection(-1);
		}
		if (downP)
		{
			changeSelection(1);
		}

		if (controls.UI_LEFT_P)
			changeDiff(-1);
		if (controls.UI_RIGHT_P)
			changeDiff(1);

		if (controls.BACK) {
			//FlxG.switchState(new MainMenuState());
		}

		if (accepted)
		{
			var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), diff);

			PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
			PlayState.isStoryMode = false;
			PlayState.diffArray = diffArray;
			PlayState.storyDifficulty = curDifficulty;

			PlayState.storyWeek = songs[curSelected].week;
			trace('CUR WEEK' + PlayState.storyWeek);
			if (PlayState.SONG != null)
				LoadingState.loadAndSwitchState(new PlayState());
			else {
				ErrorState.song = songs[curSelected].songName;
				FlxG.switchState(new ErrorState());
			}
		}
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

		diffArray = [];

		#if sys
		var directorys:Array<String> = [Paths.getPreloadPath()];

		#if desktop
		directorys.push(Paths.mods());
		#end

		for (dir in 0...directorys.length)
		{
			var songPath = directorys[dir] + 'data/' + songs[curSelected].songName + '/';

			if (FileSystem.isDirectory(songPath))
			{
				for (file in FileSystem.readDirectory(songPath))
				{
					var path = haxe.io.Path.join([songPath, file]);
					if (file.startsWith(songs[curSelected].songName.toLowerCase()) && file.endsWith('.json'))
					{
						var diffToAdd:String = '';

						var songName:String = StringTools.replace(file, '.json', '');
						diffToAdd = songName;

						diffToAdd = songDiff(diffToAdd);

						if (diffToAdd == songName)
							diffToAdd = '';

						if (diffToAdd == '')
							diffToAdd = 'normal';

						if (!diffArray.contains(diffToAdd))
							if (diffToAdd != songs[curSelected].songName.toLowerCase())
								diffArray.push(diffToAdd);
					}
				}
			}
		}
		#else
		diffArray = ['EASY', 'NORMAL', 'HARD'];
		#end

		// selector.y = (70 * curSelected) + 30;

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, diff);
		// lerpScore = 0;
		#end

		var bullShit:Int = 0;

		for (i in 0...iconArray.length)
		{
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
			var weekInt:Int = songs[curSelected].week;
			var cool:FlxColor = FlxColor.WHITE;
			if (coolColors.exists(weekInt))
				cool = FlxColor.fromRGB(coolColors.get(weekInt)[0], coolColors.get(weekInt)[1], coolColors.get(weekInt)[2]);

			if (cool != intendedColor)
			{
				if (colorTween != null)
					colorTween.cancel;

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
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var songColors:Array<Int>;

	public function new(song:String, week:Int = 0, songCharacter:String, colors:Array<Int>)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.songColors = colors;
	}
}
