package gameObjects.notes;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.system.*;
import flixel.util.*;
import flixel.*;
import flixel.text.*;
import flixel.math.*;
import flixel.graphics.*;
import lime.utils.Assets;
import flixel.FlxG;
import helpers.*;
import gameObjects.*;
import data.*;
import states.*;

using StringTools;

class Note extends FlxSprite
{
	public var strumTime:Float = 0;

	public var mustPress:Bool = false;
	public var noteData:Int = 0;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var prevNote:Note;
	public var ignoreNote = false;
	public var rating:String = "sick";
	public var strumID:Int = 0;
	public var sustainHit:Bool = false;
	public var notePos:Int = 0;
	public var canGhost:Bool = false;
	public var noteHit:Bool = true;

	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;
	public var noAnim:Bool = false;
	public var modifiedNote:Bool = false;
	public var isPixelNote:Bool = false;

	public var noteScore:Float = 1;

	public static var swagWidth:Float = 160 * 0.7;
	public static var PURP_NOTE:Int = 0;
	public static var GREEN_NOTE:Int = 2;
	public static var BLUE_NOTE:Int = 1;
	public static var RED_NOTE:Int = 3;

	public var susNotes:Array<Note> = [];
	public var stopHit:Bool = false;
	public var ignoreSus(default, set):Bool = false;

	var playerStyle:String;
	var opponentStyle:String;
	public var curStyle:String = 'normal';
	public var isPlayer:Bool = false;
	public var texture(default, set):String = 'NOTE_assets';
	public var noteType(default, set):String = 'default';
	public var initScale:Float = 1;

	//HScript & Lua Stuff
	public var noteXOffset:Float = 0;
	public var noteYOffset:Float = 0;
	public var healthGain:Float = 0.04;
	public var healthLoss:Float = 0.05;
	public var hitCauseMiss:Bool = false;

	public var customAnims:Bool = false;
	public var inCharter:Bool = false;

	public var daAnims:Array<String> = [];
	public var isThreePlayerNote:Bool = false;
	public var modifiedPos:Bool = false;
	public var modifiedX:Float = 0;
	public var playerLane:Int = 1;
	public var strumLane:Int = 0;

	public static var arrowColors:Array<Float> = [1, 1, 1, 1];
	public static var arrowNames:Array<String> = ["left", "down", "up", "right"];

	inline function set_texture(tex:String) {
		reloadSkin(tex, isPixelNote);

		texture = tex;
		return tex;
	}

	inline function set_noteType(type:String) {
		switch (type) {
			case 'noAnim':
				noAnim = true;
			default:
				type = 'default';
		}

		noteType = type;
		return type;
	}

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?noteType:String = 'none', ?inCharter:Bool = false, ?strumID:Int = 0)
	{
		super();

		if (prevNote == null)
			prevNote = this;

		this.prevNote = prevNote;
		isSustainNote = sustainNote;
		this.strumID = strumID;
		this.isPlayer = (this.strumID == playerLane);
		strumLane = this.strumID + 1;
		this.mustPress = isPlayer;
		this.inCharter = inCharter;

		if (noteType != null && noteType != "default" && noteType != "")
			this.noteType = noteType;
		else {
			this.noteType = 'default';
		}

		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		y -= 2000;
		this.strumTime = strumTime;

		this.noteData = noteData;

		if (noteData > 3)
			this.noteData = 3;

		if (inCharter) {
			reloadSkin('NOTE_assets', false);
		}
		else {
			curStyle = PlayState.SONG.arrowTexture;
			checkNoteStyle(PlayState.SONG.arrowTexture);
		}
	}

	public function checkNoteStyle(style:String = '') {
		if (style == 'pixel') {
			isPixelNote = true;
			texture = 'pixel_arrows';
		}
		else {
			isPixelNote = PlayState.isPixelNotes;
			texture = '';
		}
	}

	public function reloadSkin(texture:String = '', isPixel:Bool = false)
	{
		var noteSkin:String = texture;
		if (noteSkin == null) noteSkin = '';

		if (texture.length < 1) {
			noteSkin = PlayState.SONG.arrowTexture;
			if (noteSkin == null || noteSkin.length < 1) {
				noteSkin = 'NOTE_assets';
			}
		}

		if (isPixel) {
			if (isSustainNote) {
				var imgWidth:Int = Tools.getImagePixelWidth(texture + 'ENDS');
				var imgHeight:Int = Tools.getImagePixelHeight(texture + 'ENDS') * 2;

				loadGraphic(Paths.image(texture + 'ENDS'), true, imgWidth, imgHeight);
			}
			else {
				var imgWidth:Int = Tools.getImagePixelWidth(texture);
				var imgHeight:Int = Tools.getImagePixelHeight(texture);

				loadGraphic(Paths.image(texture), true, imgWidth, imgHeight);
			}

			loadAnimations(true);
			antialiasing = false;
		}
		else  {
			frames = Paths.getSparrowAtlas(noteSkin);
			loadAnimations(false);
			antialiasing = PlayerPrefs.antialiasing;
		}

		if (graphic == null && isPixel || frames == null && !isPixel) {
			frames = Paths.getSparrowAtlas('NOTE_assets', 'shared');
			loadAnimations(false);
			antialiasing = PlayerPrefs.antialiasing;
		}

		var graphicsSize:Int = Std.int(width * 0.7);

		if (isPixel)
			graphicsSize = Std.int(width * PlayState.daPixelZoom);

		setGraphicSize(graphicsSize);
		 
		doAnim();
		updateHitbox();
	}

	public function charterNote() {
		frames = Paths.getSparrowAtlas("NOTE_assets", "shared");
		loadAnimations(false);
		doAnim();

		setGraphicSize(Std.int(width * 0.7));
		updateHitbox();
		antialiasing = PlayerPrefs.antialiasing;
	}

	function loadDefaultNote()
	{
		switch (curStyle) {
			case 'pixel':
				reloadSkin('pixel_arrows', true);
			default:
				frames = Paths.getSparrowAtlas("NOTE_assets", "shared");
				loadAnimations(false);
				setGraphicSize(Std.int(width * 0.7));
				updateHitbox();
				antialiasing = PlayerPrefs.antialiasing;
		}

		doAnim();
	}

	inline public function set_ignoreSus(value:Bool):Bool {
		for (sus in susNotes) {
			sus.ignoreNote = value;
			sus.stopHit = value;
			sus.noAnim = true;
		}

		return value;
	}

	public function loadAnimations(isPixel:Bool = false)
	{
		if (isPixel) {
			if (isSustainNote) {
				animation.add('purpleholdend', [4]);
				animation.add('greenholdend', [6]);
				animation.add('redholdend', [7]);
				animation.add('blueholdend', [5]);

				animation.add('purplehold', [0]);
				animation.add('greenhold', [2]);
				animation.add('redhold', [3]);
				animation.add('bluehold', [1]);
			}
			else {
				animation.add('greenScroll', [6]);
				animation.add('redScroll', [7]);
				animation.add('blueScroll', [5]);
				animation.add('purpleScroll', [4]);
			}
		}
		else {
			animation.addByPrefix('greenScroll', 'green0');
			animation.addByPrefix('redScroll', 'red0');
			animation.addByPrefix('blueScroll', 'blue0');
			animation.addByPrefix('purpleScroll', 'purple0');

			animation.addByPrefix('purpleholdend', 'pruple end hold');
			animation.addByPrefix('greenholdend', 'green hold end');
			animation.addByPrefix('redholdend', 'red hold end');
			animation.addByPrefix('blueholdend', 'blue hold end');

			animation.addByPrefix('purplehold', 'purple hold piece');
			animation.addByPrefix('greenhold', 'green hold piece');
			animation.addByPrefix('redhold', 'red hold piece');
			animation.addByPrefix('bluehold', 'blue hold piece');
		}
	}

	public function doAnim()
	{
		switch (noteData) {
			case 0:
				animation.play('purpleScroll');
			case 1:
				animation.play('blueScroll');
			case 2:
				animation.play('greenScroll');
			case 3:
				animation.play('redScroll');
		}

		doSustainThing();
	}

	public function doSustainThing() {
		if (isSustainNote) {
			if (prevNote != null) {
				if (PlayerPrefs.downscroll)
					angle = 180;

				noteScore * 0.2;
				alpha = 0.6;

				if (PlayerPrefs.middlescroll && !isPlayer && !inCharter)
					alpha = 0;

				switch (noteData)
				{
					case 2:
						animation.play('greenholdend');
					case 3:
						animation.play('redholdend');
					case 1:
						animation.play('blueholdend');
					case 0:
						animation.play('purpleholdend');
				}

				updateHitbox();

				if (prevNote.isSustainNote)
				{
					switch (prevNote.noteData)
					{
						case 0:
							prevNote.animation.play('purplehold');
						case 1:
							prevNote.animation.play('bluehold');
						case 2:
							prevNote.animation.play('greenhold');
						case 3:
							prevNote.animation.play('redhold');
					}

					if (!animation.curAnim.name.endsWith('end')) scale.y *= Conductor.stepCrochet / 100 * 1.5 * PlayState.instance.songSpeed;
					prevNote.updateHitbox();
				}
			}
		}
	}

	public function resizeScale(speed:Float) {
		if (isSustainNote && (animation.curAnim != null && !animation.curAnim.name.endsWith('end'))) {
			scale.y *= speed / PlayState.instance.songSpeed;
			updateHitbox();
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		var canPress:Bool = (playerLane == strumID);
		isPlayer = canPress;

		if (canPress)
		{
			if (PlayerPrefs.botplay)
				canBeHit = (strumTime <= Conductor.songPosition);
			else
			{
				if (strumTime > Conductor.songPosition - Conductor.safeZoneOffset
					&& strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * 0.5))
					canBeHit = true;
				else
					canBeHit = false;

				if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset)
					tooLate = true;
			}
		}
		else
		{
			canBeHit = false;

			if (strumTime <= Conductor.songPosition)
				wasGoodHit = true;
		}

		if (tooLate)
			if (alpha > 0.3)
				alpha = 0.3;
	}
}