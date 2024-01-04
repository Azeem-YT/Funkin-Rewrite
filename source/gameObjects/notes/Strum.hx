package gameObjects.notes; 

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxBasic;
import flixel.graphics.FlxGraphic;
import helpers.*;
import haxe.Json;
import lime.utils.Assets;
import data.*;
import states.*;
import flixel.tweens.*;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

typedef SplashData = 
{
	var purpleData:ShitData;
	var blueData:ShitData;
	var greenData:ShitData;
	var redData:ShitData;
	var splashTexture:String;
	var splashWidth:Int;
	var splashHeight:Int;
	var useFrames:Bool;
	var xOffset:Float;
    var yOffset:Float;
}

typedef ShitData = 
{
	var anim:String;
	var hasRandom:Bool;
	var splashFrames:Array<Int>;
}

class NoteSplashData //Data for the current note splash data is stored here
{
	public static var splashData:SplashData = null;
	public static var texture:String = 'noteSplashes';
	public static var splashFrames:Array<Array<Int>> = null;
	public static var isFrames:Bool = false;
	public static var splashWidth:Int = 10;
	public static var splashHeight:Int = 10;
	public static var xOffset:Float = 10;
	public static var yOffset:Float = 10;

	public static function reloadJson(tex:String) {
		if (texture == tex)
			return;

		var splashTex:String = 'noteSplashes';

		if (tex != null && tex.length > 0) splashTex = tex;

		#if sys
		if (FileSystem.exists(Paths.json('noteSplashes/' + splashTex))) 
		#else
		if (Assets.exists(Paths.json('noteSplashes/' + splashTex)))
		#end
		{
			#if sys
			splashData = Json.parse(File.getContent(Paths.json('noteSplashes/' + splashTex)));
			#else
			splashData = Json.parse(Assets.getText(Paths.json('noteSplashes/' + splashTex)));
			#end

			if (splashData.useFrames) {
				splashFrames[0] = splashData.purpleData.splashFrames;
				splashFrames[1] = splashData.blueData.splashFrames;
				splashFrames[2] = splashData.greenData.splashFrames;
				splashFrames[3] = splashData.redData.splashFrames;
				isFrames = true;
			}

		}
		else {
			splashData = null;
		}

		texture = splashTex;
	}
}

class NoteSplash extends FlxSprite
{
	public var splashDirs:Array<String> = ['purple', 'blue', 'green', 'red'];
	public var animToPlay:String = '';
	public var splashData:SplashData = null;
	public var texture(default, set):String;
	public var splashFrames:Array<Array<Int>> = null;
	public var isFrames:Bool = false;
	public var noteSplashID:String = '';
	public var noteData:Int = 0;

	public function new(x:Float, y:Float = 0, noteData:Int = 0) {
		super(x, y);

		texture = NoteSplashData.texture;
	}

	inline function set_texture(tex:String):String {
		var splashSkin:String = '';

		if (tex != null) splashSkin = tex;

		if (splashSkin.length < 1) {
			if (PlayState.SONG != null)
				splashSkin = PlayState.SONG.splashTexture;

			if (splashSkin == null || splashSkin == '') {
				splashSkin = 'noteSplashes';
			}
		}

		NoteSplashData.reloadJson(splashSkin);

		if (NoteSplashData.isFrames) {
			loadGraphic(tex, true, NoteSplashData.splashWidth, NoteSplashData.splashHeight);
		}
		else {
			frames = Paths.getSparrowAtlas(tex);
		}

		if (graphic == null && isFrames || frames == null && !isFrames)
			frames = Paths.getSparrowAtlas('noteSplashes');

		addAnimations();
		updateHitbox();

		texture = tex;

		return tex;
	}

	public function addSplash(x:Float, y:Float, noteData:Int) {
        animToPlay = splashDirs[noteData];

        setPosition(x - 70, y - 70);

        if (splashData != null)
            offset.set(NoteSplashData.xOffset, NoteSplashData.yOffset);
        else
            offset.set(10, 10);

		alpha = 0.6;
		var animToPlay:String = 'note$noteData-' + FlxG.random.int(1, 2);
        playAnim(animToPlay);
    }

	public function addAnimations() {
		for (i in 0...4) {
			var splashData:SplashData = NoteSplashData.splashData;
			for (a in 1...3) {
				var defaultAnim:String = 'note impact ' + a + ' ' + splashDirs[i];
				if (splashData != null)	{
					if (NoteSplashData.isFrames) {
						animation.add('note$i-' + a, splashFrames[i], 24, false);
					}
					else  {
						var splashAnim:ShitData = null;
						switch (i) {
							case 0:
								splashAnim = splashData.purpleData;
							case 1:
								splashAnim = splashData.blueData;
							case 2:
								splashAnim = splashData.greenData;
							case 3:
								splashAnim = splashData.redData;
							default:
								splashAnim = splashData.purpleData;
						}

						if (splashAnim != null) {
							if (splashAnim.hasRandom) {
								var splitShit:Array<String> = splashAnim.anim.split("$split$");

								var firstAnim:String = splitShit[0];
								var secondAnim:String = '';

								if (splitShit[1] != null) {
									secondAnim = splitShit[1];

									var animToAdd:String = firstAnim + a + secondAnim;
									for (i in 1...2)
										animation.addByPrefix('note$i-' + a, animToAdd, 24, false);
								}
								else
									animation.addByPrefix('note$i-' + a, splashAnim.anim, 24, false);
							}
							else
								animation.addByPrefix('note$i-' + a, defaultAnim, 24, false);

						}
						else
							animation.addByPrefix('note$i-' + a, defaultAnim, 24, false);

					}
				}
				else
					animation.addByPrefix('note$i-' + a, defaultAnim, 24, false);
			}
		}

		antialiasing = PlayerPrefs.antialiasing;
	}

	public function playAnim(anim:String)
       return animation.play(anim, true);

	override function update(elapsed:Float) {
		if(animation.curAnim != null && animation.curAnim.finished)
                kill();

		if (frames == null || animation.curAnim == null) kill();

		super.update(elapsed);
	}
}

class StaticArrow extends FlxSprite
{
	public var animOffsets:Map<String, Array<Dynamic>>;
	public var noteData:Int = 0;

	public var initX:Float;
	public var initY:Float;

	public var originAngle:Float;
	public var daPixelZoom:Float = 6;
	public var texture(default, set):String = '';
	public var isPixel:Bool = false;
	public var isDownscroll(default, set):Bool = false;
	public var isPlayer:Bool = false;

	public var modified:Bool = false;
	
	var player:Int = 0;

	inline function set_isDownscroll(val:Bool):Bool {
		isDownscroll = val;

		if (!modified) {
			var strumLineY:Float = 50;
			if (isDownscroll) strumLineY = FlxG.height - 150;
			y = strumLineY;
		}

		return val;
	}

	inline function set_texture(tex:String) {	
		if (texture != tex || (tex == null || tex == '')) {
			texture = tex;
			reloadStrum();
		}

		return tex;
	}

	public function new(x:Float, y:Float, noteData:Int = 0, player:Int = 0)
	{
		super(x, y);

		animOffsets = new Map<String, Array<Dynamic>>();

		this.noteData = noteData;
		this.player = player;

		texture = '';

		updateHitbox();
		scrollFactor.set();
	}

	public function playAnim(animName:String, ?forced:Bool = false)
	{
		animation.play(animName, forced);
		if (animation.curAnim == null) return;

		centerOffsets();
		centerOrigin();
	}

	override public function update(elapsed:Float){
		super.update(elapsed);

		if (!isPlayer && animation.curAnim != null && animation.curAnim.finished && animation.curAnim.name != 'static')
			playAnim('static', true);
	}

	public function reloadStrum() {
		var lastAnim:String = null;
		var lastFrame:Int = 0;

		if (animation.curAnim != null) {
			lastAnim = animation.curAnim.name;
			lastFrame = animation.curAnim.curFrame;
		}

		if (isPixel) {
			var staticArrow:Int = noteData;
			var justPressed:Int = 4 + noteData;
			var pressed:Int = 8 + noteData;
			var justConfirmed:Int = 12 + noteData;
			var confirmed:Int = 16 + noteData;

			loadGraphic(Paths.image('pixelUI/' + texture));
			var width = this.width / 4;
			var height = this.height / 5;

			loadGraphic(Paths.image('pixelUI/' + texture), true, Math.floor(width), Math.floor(height));

			antialiasing = false;
			setGraphicSize(Std.int(width * daPixelZoom));

			animation.add('green', [6]);
			animation.add('red', [7]);
			animation.add('blue', [5]);
			animation.add('purple', [4]);

			animation.add('static', [staticArrow]);
			animation.add('pressed', [justPressed, pressed], 12, false);
			animation.add('confirm', [justConfirmed, confirmed], 24, false);
		}
		else {
			var noteSkin:String = texture;

			if (noteSkin == null || noteSkin.length < 1) {
				if (PlayState.SONG != null) noteSkin = PlayState.SONG.arrowTexture;

				if (noteSkin == null || noteSkin.length < 1) {
					noteSkin = 'NOTE_assets';
				}
			}

			frames = Paths.getSparrowAtlas(noteSkin);
			animation.addByPrefix('green', 'arrowUP');
			animation.addByPrefix('blue', 'arrowDOWN');
			animation.addByPrefix('purple', 'arrowLEFT');
			animation.addByPrefix('red', 'arrowRIGHT');
			
			antialiasing = PlayerPrefs.antialiasing;
			setGraphicSize(Std.int(width * 0.7));

			switch (noteData) {
				case 0:
					animation.addByPrefix('static', 'arrowLEFT');
					animation.addByPrefix('pressed', 'left press', 24, false);
					animation.addByPrefix('confirm', 'left confirm', 24, false);
				case 1:
					animation.addByPrefix('static', 'arrowDOWN');
					animation.addByPrefix('pressed', 'down press', 24, false);
					animation.addByPrefix('confirm', 'down confirm', 24, false);
				case 2:
					animation.addByPrefix('static', 'arrowUP');
					animation.addByPrefix('pressed', 'up press', 24, false);
					animation.addByPrefix('confirm', 'up confirm', 24, false);
				case 3:
					animation.addByPrefix('static', 'arrowRIGHT');
					animation.addByPrefix('pressed', 'right press', 24, false);
					animation.addByPrefix('confirm', 'right confirm', 24, false);
			}
		}

		updateHitbox();

		if (lastAnim != null) {
			animation.play(lastAnim, true, false, lastFrame);
		}
	}

	public function addOffset(animName:String, x:Float = 0, y:Float = 0){
		animOffsets[animName] = [x, y];
	}
}

class Strum extends FlxTypedGroup<FlxBasic>
{	
	public var strums:FlxTypedGroup<StaticArrow>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;
	public var strumCharacter:Character = null;
	public var instance:PlayState;
	public var numbOfArrows:Int = 0;
	public var playerNumb:Int = 2;
	public var downScroll:Bool = false;
	public var strumID:Int = 0;
	public var autoPlay:Bool = true;
	public var texture:String = 'NOTE_assets';
	public var style:String = 'normal';
	public var singDirs:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public function new(x:Float, ?instance:PlayState, ?noteSkin:String = 'NOTE_assets', ?strumChar:Character, ?strumID:Int = 0)
	{
		super();

		if (instance != null) this.instance = instance; else this.instance = new PlayState();

		strums = new FlxTypedGroup<StaticArrow>();
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();
		playerNumb = instance.numbOfStrums;
		changeCharacter(strumChar);
		this.strumID = strumID;

		if (strumCharacter == null) {
			switch (strumID) {
				case 0:
					changeCharacter(PlayState.dad);
				case 1:
					changeCharacter(PlayState.boyfriend);
				case 2:
					changeCharacter(PlayState.gf);
			}
		}

		add(strums);
		add(grpNoteSplashes);

		switch (noteSkin) {
			case 'pixel':
				for (i in 0...4)
					addArrowPixel(i, 'pixel_arrows');
			default:
				for (i in 0...4)
					addArrow(i, noteSkin);
		}

		var preloadSplash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(preloadSplash);
		preloadSplash.alpha = 0;
	}

	public function onBeat(curBeat:Int) { //Hehe

		if (strumCharacter != null) {
			if (autoPlay && strumCharacter.isPlayer)
				strumCharacter.isPlayer = false;

			var charIdle:Int = strumCharacter.idleOnBeat;

			if (charIdle == 0)
				charIdle = 1;

			if (strumCharacter.danceIdle) {
				if (!strumCharacter.animation.curAnim.name.startsWith("sing") && curBeat % charIdle == 0)
					strumCharacter.dance();
			}
			else
				if (strumCharacter.animation.curAnim.name == strumCharacter.idleDance && curBeat % charIdle == 0)
					strumCharacter.dance();
		}
	}

	public function addArrowPixel(noteData:Int, ?noteSkin:String = 'pixel_arrows') {

		var staticArrow:StaticArrow = new StaticArrow(0, 0, noteData);
		staticArrow.isPixel = true;
		staticArrow.texture = noteSkin;
		staticArrow.ID = noteData;
		strums.add(staticArrow);
		staticArrow.isPlayer = (strumID == PlayState.playerLane);
		staticArrow.originAngle = 0;
		staticArrow.playAnim('static');

		arrowPosition(staticArrow);

		staticArrow.initX = staticArrow.x;
		staticArrow.initY = staticArrow.y;
		numbOfArrows++;
	}

	public function addArrow(noteData:Int, ?noteSkin:String = 'NOTE_assets'){
		var staticArrow:StaticArrow = new StaticArrow(0, 0, noteData, strumID);
		staticArrow.texture = noteSkin;
		staticArrow.ID = noteData;
		strums.add(staticArrow);
		staticArrow.isPlayer = (strumID == PlayState.playerLane);
		staticArrow.originAngle = 0;
		staticArrow.playAnim('static');

		arrowPosition(staticArrow);

		staticArrow.initX = staticArrow.x;
		staticArrow.initY = staticArrow.y;
		numbOfArrows++;
	}

	public function setmiddlescroll(val:Bool = false, instant:Bool = true) {

		var arrowX:Float = ((strumID == PlayState.playerLane) ? 400 : -500);

		if (!val) {
			for (noteData in 0...strums.members.length)
				arrowPosition(strums.members[noteData]);

			return;
		}
	
		if (instant) {
			for (noteData in 0...strums.members.length) {
				var arrow:StaticArrow = strums.members[noteData];

				arrow.x = arrowX + (Note.swagWidth * noteData);
			}

			return;
		}

		for (noteData in 0...strums.members.length) {
			var arrow:StaticArrow = strums.members[noteData];

			var arrowTween:FlxTween = FlxTween.tween(arrow, {x : arrowX + (Note.swagWidth * noteData)}, 2);
		}

		return;
	}

	public function arrowPosition(strumArrow:StaticArrow)	{
		if (strumArrow == null) return;
	
		var arrowValue:Int = playerNumb - 1;
		var noteData:Int = strumArrow.noteData;
		var arrowX:Float = Note.swagWidth * noteData;
		arrowX += 50;
		arrowX += ((FlxG.width / instance.numbOfStrums) * strumID);

		strumArrow.x = arrowX;
	}

	public function setdownscroll(val:Bool = false)
		return for (arrow in strums.members) arrow.isDownscroll = val;

	public function getArrowByNumb(numb:Int = 0):StaticArrow {
		var returnArrow:StaticArrow = strums.members[0];

		if (strums.members[numb] != null)
			returnArrow = strums.members[numb];

		return returnArrow;
	}

	public function getArrowByString(arrowDir:String = 'left'):StaticArrow {
		var returnArrow:StaticArrow = strums.members[0];

		arrowDir = arrowDir.toLowerCase();

		switch (arrowDir){
			case 'left':
				returnArrow = strums.members[0];
			case 'down':
				returnArrow = strums.members[1];
			case 'up':
				returnArrow = strums.members[2];
			case 'right':
				returnArrow = strums.members[3];
		}

		return returnArrow;
	}

	public function playCharAnim(noteData:Int = 0, altAnim:Bool = false, canAnim:Bool = true, isOpponent:Bool = true){
		if (strumCharacter != null && strumCharacter.canSing){
			if (canAnim) {
				if (altAnim){
					strumCharacter.playAnim(singDirs[noteData] + '-alt', true);
				}
				else
					strumCharacter.playAnim(singDirs[noteData], true);

				if (strumID != PlayState.playerLane)
					strumCharacter.holdTimer = 0;
			}
		}
	}

	public function changeCharacter(char:Character) {
		if (strumCharacter != null) strumCharacter.usedOnStrum = false;
		if (char != null) char.usedOnStrum = true;
		strumCharacter = char;
	}

	public function callNoteSplash(noteData:Int = 0){
		var strumArrow:StaticArrow = null;
		if (strums.members[noteData] != null) {
			strumArrow = strums.members[noteData];
		}

		if (strumArrow != null)
			spawnNoteSplash(strumArrow.x, strumArrow.y, noteData);
    }

    public function spawnNoteSplash(x:Float, y:Float, noteData:Int) {
        var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
        splash.addSplash(x, y, noteData);
        grpNoteSplashes.add(splash);
    }
}