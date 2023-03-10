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
	var prefix:String;
	var hasRandom:Bool;
	var splashFrames:Array<Int>;
	var fps:Int;
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
		var texturePath:String = 'noteSplashes';
		
		var splashTex:String = 'noteSplashes';

		if (PlayState.SONG != null)
			splashTex = PlayState.SONG.splashTexture;

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

			texturePath = splashTex;

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
			texturePath = splashTex;
		}

		texture = texturePath;
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

		if (isFrames && splashData != null) {
			loadGraphic(tex, true, splashData.splashWidth, splashData.splashHeight);
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
            offset.set(splashData.xOffset, splashData.yOffset);
        else
            offset.set(150, 75);

		alpha = 0.6;
        playAnim('note' + noteData);
    }

	public function addAnimations() {
		var defaultAnim:String = 'note splash ';

		if (splashData != null) {
			if (isFrames) {
				animation.add('note0', splashFrames[0], splashData.purpleData.fps, false);
				animation.add('note1', splashFrames[1], splashData.blueData.fps, false);
				animation.add('note2', splashFrames[2], splashData.greenData.fps, false);
				animation.add('note3', splashFrames[3], splashData.redData.fps, false);
			}
			else {
				for (i in 0...4) {
					var splashShit:ShitData = null;

					switch (i) {
						case 0:
							splashShit = splashData.purpleData;
						case 1:
							splashShit = splashData.blueData;
						case 2:
							splashShit = splashData.greenData;
						case 3:
							splashShit = splashData.redData;
						default:
							splashShit = splashData.purpleData;
					}

					if (splashShit != null) {
						if (splashShit.hasRandom) {
							var splitShit:Array<String> = splashShit.prefix.split('split');

							var firstAnim:String = splitShit[0];
							var secondAnim:String = '';

							if (splitShit[1] != null)
								secondAnim = splitShit[1];

							var animToAdd:String = firstAnim + FlxG.random.int(1, 2) + secondAnim;
							animation.addByPrefix('note' + i, animToAdd, splashShit.fps, false);
						}
						else
							animation.addByPrefix('note' + i, splashShit.prefix, splashShit.fps, false);
					}
					else
						animation.addByPrefix('note' + i, defaultAnim + splashDirs[i], splashShit.fps, false);
				}

			}
		}
		else {
			animation.addByPrefix('note0', defaultAnim + 'purple', 24, false);
            animation.addByPrefix('note1', defaultAnim + 'blue', 24, false);
            animation.addByPrefix('note2', defaultAnim + 'green', 24, false);
            animation.addByPrefix('note3', defaultAnim + 'red', 24, false);
		}

		antialiasing = PlayerPrefs.antialiasing;
	}

	public function playAnim(anim:String)
       return animation.play(anim, true);

	override function update(elapsed:Float) {
		if(animation.curAnim != null && animation.curAnim.finished)
                kill();

		if (animation.curAnim == null)
			kill();

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
	public var alphaTo:Float = 0.9;
	public var arrowDirs:Array<String> = ['left', 'down', 'up', 'right'];
	public var isPlayer:Bool = false;
	public var daPixelZoom:Float = 6;
	public var texture(default, set):String = 'NOTE_assets';
	public var isPixelStrum:Bool = false;

	inline function set_texture(tex:String) {
		if (tex != null && tex != '') {
			reloadSkin(tex, isPixelStrum);
		}
		else
			loadDefault();

		texture = tex;
		return tex;
	}

	function loadDefault()
	{
		switch (texture) {
			case 'pixel':
				loadGraphic(Paths.image('pixel_arrows'), true, 17, 17);
				addArrowAnim(true);
			default:
				frames = Paths.getSparrowAtlas("NOTE_assets", "shared");
				addArrowAnim(false);
		}

		playAnim('static');
	}

	public function new(x:Float, y:Float, noteData:Int = 0)
	{
		super(x, y);

		animOffsets = new Map<String, Array<Dynamic>>();

		this.noteData = noteData;

		updateHitbox();
		scrollFactor.set();
	}

	public function playAnim(animName:String, ?forced:Bool = false)
	{
		animation.play(animName, forced);
		updateHitbox();

		switch (animName){
			case 'confirm':
				centerOffsets();
			if (!isPixelStrum) {
				offset.x += 25;
				offset.y += 25;
			}
			default:
				centerOffsets();
		}
	}

	override public function update(elapsed:Float){
		super.update(elapsed);

		if (!isPlayer && animation.curAnim != null && animation.curAnim.finished && animation.curAnim.name != 'static')
			playAnim('static', true);
	}

	public function addArrowAnim(isPixel:Bool = false) {
		if (isPixel) {
			switch (noteData)
			{
				case 0:
					animation.add('static', [0]);
					animation.add('pressed', [4, 8], 12, false);
					animation.add('confirm', [12, 16], 24, false);
				case 1:
					animation.add('static', [1]);
					animation.add('pressed', [5, 9], 12, false);
					animation.add('confirm', [13, 17], 24, false);
				case 2:
					animation.add('static', [2]);
					animation.add('pressed', [6, 10], 12, false);
					animation.add('confirm', [14, 18], 12, false);
				case 3:
					animation.add('static', [3]);
					animation.add('pressed', [7, 11], 12, false);
					animation.add('confirm', [15, 19], 24, false);
				default:
					animation.add('static', [2]);
					animation.add('pressed', [6, 10], 12, false);
					animation.add('confirm', [14, 18], 12, false);
					trace('noteData is over 4 or under 0');
			}
			setGraphicSize(Std.int(width * daPixelZoom));
			updateHitbox();
			antialiasing = false;
			scrollFactor.set();
		}
		else 
		{
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

			setGraphicSize(Std.int(width * 0.7));
			antialiasing = PlayerPrefs.antialiasing;
			updateHitbox();
			scrollFactor.set();
		}
	}

	public function reloadSkin(texture:String = '', isPixel:Bool = false) {
		var noteSkin:String = texture;
		var noteAnim:String = '';
		if (noteSkin == null) noteSkin = '';

		if (animation.curAnim != null) {
			noteAnim = animation.curAnim.name;
		}

		if (texture.length < 1) {
			if (PlayState.SONG != null)
				noteSkin = PlayState.SONG.arrowTexture;

			if (noteSkin == null || noteSkin.length < 1) {
				noteSkin = 'NOTE_assets';
			}
		}

		if (isPixel) {
			var imgWidth:Int = Tools.getImagePixelWidth(texture);
			var imgHeight:Int = Tools.getImagePixelHeight(texture);

			loadGraphic(Paths.image(texture), true, imgWidth, imgHeight);

			setGraphicSize(Std.int(width * PlayState.daPixelZoom));
			addArrowAnim(true);
			antialiasing = false;
		}
		else  {
			frames = Paths.getSparrowAtlas(noteSkin);
			addArrowAnim(false);
			antialiasing = PlayerPrefs.antialiasing;
		}

		if (this == null) {
			frames = Paths.getSparrowAtlas('NOTE_assets');
			addArrowAnim(false);
			antialiasing = PlayerPrefs.antialiasing;
		}
		 
		playAnim('static');
			
		updateHitbox();
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
	public var playstateInstance:PlayState;
	public var numbOfArrows:Int = 0;
	public var playerNumb:Int = 2;
	public var downScroll:Bool = false;
	public var strumID:Int = 0;
	public var autoPlay:Bool = true;
	public var texture:String = 'NOTE_assets';
	public var style:String = 'normal';
	public var singDirs:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public function new(x:Float, ?instance:PlayState, ?noteSkin:String = 'NOTE_assets', ?strumChar:Character, ?downscroll:Bool = false, ?strumID:Int = 0)
	{
		super();

		if (instance != null)
			playstateInstance = instance;
		else
			playstateInstance = new PlayState(); //To prevent crash

		strums = new FlxTypedGroup<StaticArrow>();
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();
		playerNumb = playstateInstance.numbOfStrums;
		changeCharacter(strumChar);
		this.strumID = strumID;
		downScroll = downscroll;

		if (strumCharacter == null) {
			switch (strumID) {
				case 0:
					strumCharacter = PlayState.dad;
				case 1:
					strumCharacter = PlayState.boyfriend;
				case 2:
					strumCharacter = PlayState.gf;
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
				if (strumCharacter.animation.curAnim.name == strumCharacter.idleDance &&
					curBeat % charIdle == 0)
					strumCharacter.dance();
		}
	}

	public function addArrowPixel(noteData:Int, ?noteSkin:String = 'pixel_arrows') {
		var arrowValue:Int = playerNumb - 1;
		var arrowY:Float = 50;

		if (downScroll)
			arrowY = FlxG.height - 150;

		var staticArrow:StaticArrow = new StaticArrow(0, arrowY, noteData);
		staticArrow.isPixelStrum = true;
		staticArrow.texture = noteSkin;
		staticArrow.ID = noteData;
		staticArrow.x += Note.swagWidth * noteData * (2 / (arrowValue * 2));
		strums.add(staticArrow);
		staticArrow.isPlayer = (strumID == playstateInstance.playerLane);
		staticArrow.originAngle = 0;
		staticArrow.alphaTo = 1;
		staticArrow.playAnim('static');

		switch (playerNumb) {
			case 3:
				staticArrow.x += 50;
				if (strumID > 0)
					staticArrow.x += 400 * strumID;
				staticArrow.x += Note.swagWidth * (noteData / 3);
			case 4:
				staticArrow.x += 15;
				staticArrow.x += 310 * strumID;
				staticArrow.x += Note.swagWidth * (noteData / 3);
			case 2:
				switch (strumID) {
					case 1:
						staticArrow.x += FlxG.width / 1.75;
					default:
						staticArrow.x += 100;
				}
		}

		staticArrow.initX = staticArrow.x;
		staticArrow.initY = staticArrow.y;
		numbOfArrows++;
	}

	public function addArrow(noteData:Int, ?noteSkin:String = 'NOTE_assets'){
		var arrowValue:Int = playerNumb - 1;
		var arrowY:Float = 50;

		if (downScroll)
			arrowY = FlxG.height - 150;

		var staticArrow:StaticArrow = new StaticArrow(0, arrowY, noteData);
		staticArrow.texture = noteSkin;
		staticArrow.ID = noteData;
		staticArrow.x += Note.swagWidth * noteData * (2 / (arrowValue * 2));
		strums.add(staticArrow);
		staticArrow.isPlayer = (strumID == playstateInstance.playerLane);
		staticArrow.originAngle = 0;
		staticArrow.alphaTo = 1;
		staticArrow.playAnim('static');

		switch (playerNumb) {
			case 3:
				staticArrow.x += 50;
				if (strumID > 0)
					staticArrow.x += 400 * strumID;
				staticArrow.x += Note.swagWidth * (noteData / 3);
			case 4:
				staticArrow.x += 15;
				staticArrow.x += 310 * strumID;
				staticArrow.x += Note.swagWidth * (noteData / 3);
			case 2:
				switch (strumID) {
					case 1:
						staticArrow.x += FlxG.width / 1.75;
					default:
						staticArrow.x += 100;
				}
		}

		staticArrow.initX = staticArrow.x;
		staticArrow.initY = staticArrow.y;
		numbOfArrows++;
	}

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

	public function playCharAnim(noteData:Int = 0, altAnim:Bool = false, canAnim:Bool = true, isOpponent:Bool = true, ?doGhost:Bool = false){
		if (strumCharacter != null && strumCharacter.canSing){
			if (canAnim && !doGhost) {
				if (altAnim){
					strumCharacter.playAnim(singDirs[noteData] + '-alt', true);
				}
				else
					strumCharacter.playAnim(singDirs[noteData], true);

				if (playstateInstance.playerLane != strumID)
					strumCharacter.holdTimer = 0;
			}

			if (doGhost) 
				playstateInstance.doGhost(strumCharacter, singDirs[noteData], isOpponent);
		}
	}

	public function changeCharacter(char:Character) {
		if (strumCharacter != null)
			strumCharacter.usedOnStrum = false;
		
		char.usedOnStrum = true;
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