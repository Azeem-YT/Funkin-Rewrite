package gameObjects;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.animation.FlxBaseAnimation;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.tweens.FlxTween;
import flixel.util.FlxSort;
import flixel.graphics.frames.FlxFrame;
import openfl.utils.Assets;
import haxe.Json;
import haxe.format.JsonParser;
import data.Section.SwagSection;
import data.Conductor;
import data.Song;
import states.*;
import data.PlayerPrefs;
import flixel.group.FlxSpriteGroup;
#if sys
import sys.io.File;
import sys.FileSystem;
#end

using StringTools;

typedef CharData =
{
	var flipX:Bool;
	var camOffset:Array<Float>;
	var scale:Float;
	var healthIcon:String;
	var animatedIcon:Bool;
	var idleOnBeat:Int;
	var animations:Array<AnimData>;
	var positionOffset:Array<Float>;
	var healthColors:Array<Int>;
	var image:String; //If porting from psych engine
	var deathCharacter:String;
	var deathSound:String;
	var noAntialiasing:Bool;
	var atlasType:String;
	var sing_duration:Dynamic;
}

typedef AnimData =
{
	var prefix:String;
	var anim:String;
	var indices:Array<Int>;
	var fps:Int;
	var loop:Bool;
	var offset:Array<Float>;
}

class Character extends EngineSprite
{
	public var isPlayer:Bool = false;
	public var curCharacter:String = 'bf';
	public var debugMode:Bool = false;

	public var holdTimer:Float = 0;
	public var heyTimer:Float = 0;
	public var stunned:Bool = false;

	public var idleDance:String = 'idle';
	public var forceNoIdle:Bool = false;
	public var camOffset:Array<Float> = [0,0];

	public var animationNotes:Array<Dynamic> = [];
	public var positionOffset:Array<Float> = [0, 0];
	public var canSing:Bool = true;
	public var healthColors:Array<Int> = [128, 128, 128];
	public var idleOnBeat:Int = 2;
	public var singDuration:Float = 4;

	public var danced:Bool = false;

	public var usedOnStrum:Bool = false;
	public var danceIdle:Bool = false;

	public var healthIcon:String;

	public var charData:CharData;
	public var animArray:Array<AnimData>;
	public var deathCharacter:String = 'bf';
	public var deathSound:String = null;

	public var ghostGroup:FlxSpriteGroup;

	public function new(x:Float, y:Float, ?character:String = "bf", ?isPlayer:Bool = false)
	{
		super(x, y);

		ghostGroup = new FlxSpriteGroup(0, 0);

		curCharacter = character;
		this.isPlayer = isPlayer;
		antialiasing = PlayerPrefs.antialiasing;
		resetVars();

		switch (curCharacter) {
			default:
				var path = Paths.characterFile(curCharacter, isPlayer);

				#if sys
				if (!FileSystem.exists(path)) {
					curCharacter = 'bf';
					path = Paths.characterFile(curCharacter, isPlayer);
				}
				#else
				if (!Assets.exists(path)) {
					curCharacter = 'bf';
					path = Paths.characterFile(curCharacter, isPlayer);
				}
				#end

				#if sys
				if (FileSystem.exists(path))
					charData = Json.parse(File.getContent(path));
				#else
				if (Assets.exists(path))
					charData = Json.parse(Assets.getText(path));
				#end

				if (Paths.getContent(path) != null)
					charData = Json.parse(Paths.getContent(path));

				if (charData != null) {
					switch (charData.atlasType) {
						case 'packer':
							frames = Paths.getPackerAtlas(charData.image);
						case 'sparrow':
							frames = Paths.getSparrowAtlas(charData.image);
						default:
							frames = Paths.getSparrowAtlas(charData.image);
					}

					if (charData.camOffset != null && charData.camOffset.length > 0)
						camOffset = charData.camOffset;
					
					healthIcon = ((charData.healthIcon != null && charData.healthIcon != '') ? charData.healthIcon : 'face');
				
					if (frames != null) {
						animArray = charData.animations;

						positionOffset = charData.positionOffset;

						if (animArray != null && animArray.length > 0) {
							for (anim in animArray) {
								if (anim.anim != null && anim.anim != "") {
									if (anim.indices != null && anim.indices.length > 0)
										animation.addByIndices(anim.anim, anim.prefix, anim.indices, "", anim.fps, anim.loop, charData.flipX);
									else
										animation.addByPrefix(anim.anim, anim.prefix, anim.fps, anim.loop);

									if (anim.offset != null && anim.offset.length > 0)
										addOffset(anim.anim, anim.offset[0], anim.offset[1]);
									else
										addOffset(anim.anim, 0, 0);
								}
							}

							flipX = charData.flipX;
						}

						if (charData.scale != 1)
							setGraphicSize(Std.int(width * charData.scale));

						if (charData.deathCharacter != null)
							deathCharacter = charData.deathCharacter;

						if (charData.deathSound != null)
							deathSound = charData.deathSound;

						if (charData.noAntialiasing)
							antialiasing = false;

						idleOnBeat = charData.idleOnBeat;

						if (charData.healthColors != null && charData.healthColors.length == 3)
							healthColors = charData.healthColors;

						if (charData.sing_duration != null)
							singDuration = charData.sing_duration;
					}
					else
						loadDefaultBF();
				}
				else
					loadDefaultBF();
		}

		if (healthIcon == null)
			healthIcon = curCharacter;

		getIdle();
		dance();

		if (isPlayer)
			flipX = !flipX;

		if (idleOnBeat <= 0)
			idleOnBeat = 1;
			
		switch (curCharacter) {
			case 'pico-speaker':
				loadMappedAnims();
				playAnim('shoot1');
		}

		updateHitbox();
	}

	public function loadDefaultBF() {
		frames = Paths.getSparrowAtlas('characters/BOYFRIEND');
		quickAnimAdd('idle', 'BF idle dance');
		quickAnimAdd('singUP', 'BF NOTE UP0');
		quickAnimAdd('singLEFT', 'BF NOTE LEFT0');
		quickAnimAdd('singRIGHT', 'BF NOTE RIGHT0');
		quickAnimAdd('singDOWN', 'BF NOTE DOWN0');
		quickAnimAdd('singUPmiss', 'BF NOTE UP MISS');
		quickAnimAdd('singLEFTmiss', 'BF NOTE LEFT MISS');
		quickAnimAdd('singRIGHTmiss', 'BF NOTE RIGHT MISS');
		quickAnimAdd('singDOWNmiss', 'BF NOTE DOWN MISS');
		quickAnimAdd('hey', 'BF HEY');
		quickAnimAdd('firstDeath', "BF dies");
		quickAnimAdd('deathConfirm', "BF Dead confirm");

		animation.addByPrefix('deathLoop', "BF Dead Loop", 24, true);
		animation.addByPrefix('scared', 'BF idle shaking', 24, true);

		playAnim('idle');

		flipX = true;
		trace('default bf');
	}

	/*
	public function loadOffsetFile(character:String) {
		var offset:Array<String> = CoolUtil.coolTextFile(Paths.txt('offsets/' + character + "Offsets"));

		for (i in 0...offset.length) {
			var data:Array<String> = offset[i].split(' ');
			addOffset(data[0], Std.parseInt(data[1]), Std.parseInt(data[2]));
		}
	} */

	override function update(elapsed:Float)
	{
		if (!debugMode && animation.curAnim != null)
		{
			if (isPlayer) {
				if (animation.curAnim.name.startsWith('sing')) //Fix for opponent side option
					holdTimer += elapsed;
				else
					holdTimer = 0;
			}
			else {
				if (animation.curAnim.name.startsWith('sing'))
					holdTimer += elapsed;
			}

			if (isPlayer) {
				if (animation.curAnim.name.endsWith('miss') && animation.curAnim.finished && !debugMode)
					playAnim('idle', true);
			}

			if (animation.curAnim.name.startsWith("hey") && heyTimer > 0) {
				if (heyTimer >= Conductor.stepCrochet * 0.001 * 2) {
					dance();
					holdTimer = 0;
				}
			}

			if (!isPlayer && holdTimer >= Conductor.stepCrochet * 0.001 * singDuration) {
				dance();
				holdTimer = 0;
			}
		}

		switch (curCharacter)
		{
			case 'pico-speaker':
					forceNoIdle = true;

					if(animationNotes.length > 0 && Conductor.songPosition >= animationNotes[0][0])
					{
						var noteData:Int = 1;
						if(animationNotes[0][1] > 2) 
							noteData = 3;

						noteData += FlxG.random.int(0, 1);
						playAnim('shoot' + noteData, true);
						animationNotes.shift();
					}

					if (animation.curAnim != null)
						if (animation.curAnim.finished) 
							playAnim(animation.curAnim.name, false, false, animation.curAnim.frames.length - 3);
			case 'gf':
				if (animation.curAnim.name == 'hairFall' && animation.curAnim.finished && animation.curAnim != null)
					playAnim('danceRight');
			case 'tankman':
				if ((animation.curAnim.name == 'singDOWN-alt' || animation.curAnim.name == 'singUP-alt') && !animation.curAnim.finished && animation.curAnim != null)
					forceNoIdle = true;
		}

		if (animation.curAnim != null) {
			if (animation.curAnim.finished && !forceNoIdle)
				forceNoIdle = false;
		}

		super.update(elapsed);
	}

	public function getIdle()
	{
		switch (curCharacter)
		{
			case 'gf':
				danceIdle = true;
			case 'gf-christmas':
				danceIdle = true;
			case 'gf-car':
				danceIdle = true;
			case 'gf-pixel':
				danceIdle = true;
			case 'spooky':
				danceIdle = true;
			default:
				danceIdle = (animation.getByName('danceLeft') != null && animation.getByName('danceRight') != null);
		}
	}

	public function dance()
	{
		if (!debugMode && !forceNoIdle)
		{
			if (danceIdle)
			{
				danced = !danced;

				if (danced)
					playAnim('danceRight');
				else
					playAnim('danceLeft');
			}
			else
				playAnim(idleDance);
		}
	}

	public function playHey() {
		if (curCharacter == 'gf')
			playAnim("cheer", true);
		else
			playAnim("hey", true);

		heyTimer = 0.20;
	}

	override public function playAnim(AnimName:String, Forced:Bool = false, Reversed:Bool = false, Frame:Int = 0)
	{
		super.playAnim(AnimName, Forced, Reversed, Frame);

		if (curCharacter == 'gf') {
			if (AnimName == 'singLEFT') {
				danced = true;
			}
			else if (AnimName == 'singRIGHT') {
				danced = false;
			}

			if (AnimName == 'singUP' || AnimName == 'singDOWN') {
				danced = !danced;
			}
		}
	}

	public function loadMappedAnims() {
		var jsonData:Array<SwagSection> = Song.loadFromJson('picospeaker', 'stress').notes;

		for (section in jsonData)
		{
			for (sectionNote in section.sectionNotes) {
				animationNotes.push(sectionNote);
			}
		}

		TankmenBG.animationNotes = animationNotes;
		animationNotes.sort(sortNotes);
	}

	public function sortNotes(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);

	public function resetVars() {
		camOffset = [0,0];
		animationNotes = [];
		positionOffset = [0, 0];
		deathCharacter = 'bf';
		deathSound = null;
		idleDance = 'idle';
		healthIcon = null;
		idleOnBeat = 2;
		canSing = true;
		animOffsets.clear();
	}
}