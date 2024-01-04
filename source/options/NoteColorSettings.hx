package options;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxBasic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.effects.FlxFlicker;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.util.FlxTimer;
import flixel.math.FlxMath;
import flixel.FlxCamera;
import flixel.addons.transition.FlxTransitionableState;
import states.*;
import data.*;
import substates.*;
import gameObjects.*;
import gameObjects.notes.*;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

class NoteColorSettings extends MusicBeatSubstate
{
	public var alphaOptions:FlxTypedGroup<Alphabet>;
	public var backGround:FlxSprite;
	public var curSelected:Int = 0;
	public var curSelectedOption:Int = 0;
	public var holdTimer:Float = 0;
	public var isGenerated:Bool = false;
	public var isOnMove:Bool = false;

	public var settingText:Array<Array<Alphabet>> = [[], [], [], []];
	public var settingsNumText:Array<Array<Alphabet>> = [[], [], [], []];

	public var notes:FlxTypedGroup<Note>;

	override function create() {
		super.create();

		isGenerated = false;

		settingText = [[], [], [], []];
		settingsNumText = [[], [], [], []];

		backGround = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		backGround.color = 0xFFea71fd;
		backGround.scrollFactor.x = 0;
		backGround.scrollFactor.y = 0.18;
		backGround.setGraphicSize(Std.int(backGround.width * 1.1));
		backGround.updateHitbox();
		backGround.screenCenter();
		backGround.antialiasing = true;
		add(backGround);

		notes = new FlxTypedGroup<Note>();
		add(notes);

		for (i in 0...4) {
			var note:Note = new Note(0, i, null, false, null, true, 0);
			note.y = 50 + (175 * i);
			note.x = 100;
			notes.add(note);
		}

		generateAlpha();
	}

	private function generateAlpha()
	{
		if (isGenerated) remove(alphaOptions);

		alphaOptions = new FlxTypedGroup<Alphabet>();
		add(alphaOptions);

		var shit:Int = 0;

		for (i in 0...notes.members.length) {
			var noteMember:Note = notes.members[i];

			var hueTxt:Alphabet = new Alphabet(noteMember.x + 350, noteMember.y, "Hue", false);
			hueTxt.alpha = 0.6;
			hueTxt.alphabetID = 0;
			alphaOptions.add(hueTxt);
			settingText[i][0] = hueTxt;

			var hueNum:Alphabet = new Alphabet(hueTxt.x, hueTxt.y + 100, Std.string(PlayerPrefs.noteColors[i][0]), false);
			hueNum.alpha = 0.6;
			hueNum.alphabetID = 0;
			alphaOptions.add(hueNum);

			settingsNumText[i][0] = hueNum;

			var saturationTxt:Alphabet = new Alphabet(hueTxt.x + 250, noteMember.y, "Saturation", false);
			saturationTxt.alpha = 0.6;
			saturationTxt.alphabetID = 1;
			alphaOptions.add(saturationTxt);
			settingText[i][1] = saturationTxt;

			var saturationNum:Alphabet = new Alphabet(saturationTxt.x, saturationTxt.y + 100, Std.string(PlayerPrefs.noteColors[i][1]), false);
			saturationNum.alpha = 0.6;
			saturationNum.alphabetID = 1;
			alphaOptions.add(saturationNum);

			settingsNumText[i][1] = saturationNum;

			var brightnessTxt:Alphabet = new Alphabet(saturationTxt.x + 250, noteMember.y, "Brightness", false);
			brightnessTxt.alpha = 0.6;
			brightnessTxt.alphabetID = 2;
			alphaOptions.add(brightnessTxt);
			settingText[i][2] = brightnessTxt;

			var brightnessNum:Alphabet = new Alphabet(brightnessTxt.x, brightnessTxt.y + 100, Std.string(PlayerPrefs.noteColors[i][2]), false);
			brightnessNum.alpha = 0.6;
			brightnessNum.alphabetID = 2;
			alphaOptions.add(brightnessNum);

			settingsNumText[i][2] = brightnessNum;
		}

		alphaOptions.members[curSelected].alpha = 1;
		settingsNumText[curSelected][curSelectedOption].alpha = 1;

		isGenerated = true;
	}

	function changeSelection(?change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = settingText.length - 1;
		if (curSelected >= settingText.length - 1)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in settingText[curSelected]) {
			item.alpha = 0.6;

			if (item.alphabetID == curSelected) item.alpha = 1;
		}

		for (i in 0...settingsNumText[curSelected].length) settingsNumText[curSelected][i].alpha = 0.6;
		settingsNumText[curSelected][curSelectedOption].alpha = 1;
	}

	function changeOption(?change:Int = 0) {
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelectedOption += change;

		if (curSelectedOption < 0)
			curSelectedOption = settingsNumText[curSelected].length - 1;
		if (curSelectedOption >= settingsNumText[curSelected].length)
			curSelectedOption = 0;

		var bullShit:Int = 0;

		for (item in settingsNumText[curSelected]) {
			item.alpha = 0.6;
			settingText[curSelected][curSelectedOption].alpha = 0.6;

			if (item.alphabetID == curSelectedOption) {
				settingText[curSelected][curSelectedOption].alpha = 1;
				item.alpha = 1;
			}
		}
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		var upP = controls.UI_UP_P;
		var downP = controls.UI_DOWN_P;
		var rightP = controls.UI_RIGHT_P;
		var leftP = controls.UI_LEFT_P;
		var accepted = controls.ACCEPT;

		if (!isOnMove) {
			if (upP) changeSelection(-1);
			if (downP) changeSelection(1);
			if (rightP) changeOption(1);
			if (leftP) changeOption(-1);
		}

		if (controls.BACK) close();
	}
}