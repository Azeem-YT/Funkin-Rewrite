package gameObjects.dialogue;

import flixel.FlxG;
import flixel.addons.text.FlxTypeText;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import haxe.Json;
import haxe.format.JsonParser;
import states.*;
import data.*;

#if sys
import sys.FileSystem;
import sys.io.File;
#end
import openfl.utils.Assets;

using StringTools;

typedef JsonData = {
	var dialogueData:Array<DialogueThing>;
	var startBox:String;
	var gameVisible:Null<Bool>;
	var useSong:Null<Bool>;
	var songPath:String;
	var songFadeIn:Bool;
}

typedef DialogueThing = {
	var char:String;
	var animName:String;
	var dialogue:String;
	var dialogueSpeed:Float;
	var boxType:String;
}

typedef CharFile = {
	var imgPath:String;
	var charAlignment:String;
	var noAntialiasing:Bool;
	var animations:Array<DialogueAnimData>;
	var posOffset:Array<Float>;
	var scale:Float;
}

typedef DialogueAnimData = {
	var anim:String;
	var name:String;
	var looped:Bool;
	var indices:Array<Int>;
	var offsets:Array<Float>;
}

class DialogueCharacter extends FlxSprite
{
	public var jsonData:CharFile = null;
	public var animOffsets:Map<String, Dynamic> = new Map<String, Dynamic>();
	public var animationData:Map<String, DialogueAnimData> = new Map<String, DialogueAnimData>();
	public var posOffset:Array<Float> = [0, 0];
	public var charAlignment:String = 'left';
	public var curCharacter:String = 'bf';
	public var defaultAnim:String = null;
	public var alignment:String = 'right';

	public function new(x:Float = 0, y:Float = 0, character:String = 'bf')
	{
		super(x, y);

		if (character == null)
			character = 'bf';

		jsonData = returnJsonData();
		frames = Paths.getSparrowAtlas('dialogue/' + jsonData.imgPath);
		if (jsonData.charAlignment != null)
			alignment = jsonData.charAlignment;
		getAnims();
		antialiasing = PlayerPrefs.antialiasing;
		if (jsonData.noAntialiasing)
			antialiasing = false;
	}

	public function getAnims() {
		animOffsets.clear();
		animationData.clear();
		if (jsonData.animations != null && jsonData.animations.length > 0) {
			for (animData in jsonData.animations) {
				if (animData.indices != null && animData.indices.length > 1)
					animation.addByIndices(animData.anim, animData.name, animData.indices, '', 24, animData.looped);
				else
					animation.addByPrefix(animData.anim, animData.name, 24, animData.looped);

				if (animData.offsets != null && animData.offsets.length > 0)
					addOffset(animData.anim, animData.offsets[0], animData.offsets[1]);
				else
					addOffset(animData.anim, 0, 0);

				if (defaultAnim == null)
					defaultAnim = animData.anim;

				animationData.set(animData.anim, animData);
			}
		}

		if (jsonData.charAlignment != null && charAlignment != '')
			charAlignment = jsonData.charAlignment;

		if (jsonData.posOffset != null && jsonData.posOffset.length > 0)
			posOffset = jsonData.posOffset;
	}

	public function addOffset(animName:String, xOffset:Float = 0, yOffset:Float = 0) {
		animOffsets.set(animName, [xOffset, yOffset]);
	}

	public function returnPosOffset(id:Int = 0):Float
		return posOffset[id];

	public function playAnim(animName:String, forced:Bool = true) {
		if (animOffsets.exists(animName)) {
			animation.play(animName, forced);
		}
		else
			animation.play(defaultAnim, forced);

		var daOffsets:Array<Float> = [0, 0];

		if (animOffsets.exists(animName))
			daOffsets = animOffsets.get(animName);

		offset.set(daOffsets[0], daOffsets[1]);
	}

	public function returnJsonData():CharFile
	{
		var endPath:String = 'dialogue/' + curCharacter + '.json';
		var path:String = '';
		var rawJson = null;
		var returnJson:CharFile = null;

		#if sys
		if (FileSystem.exists(Paths.mods(endPath))) {
			path = Paths.mods(endPath);
		}
		else
			path = Paths.getPreloadPath(endPath);

		rawJson = File.getContent(path);
		#else
		path = Paths.getPreloadPath(endPath);
		rawJson = Assets.getText(path);
		#end

		returnJson = cast Json.parse(rawJson);

		return returnJson;
	}
}

class DialogueState extends FlxSpriteGroup
{
   public var dialogueData:JsonData = null;
   public var currentDialogue:DialogueThing = null;
   public var dialogueList:Array<String> = [];
   public var dialogueText:Alphabet;

   public var finishThing:Void -> Void;
   public var box:FlxSprite = null;
   public var startBox:String = 'normal';
   public var characterToUse:Array<DialogueCharacter> = [];
   public var loadedChars:Map<String, DialogueCharacter>;
   public var blackBG:FlxSprite = null;
   public var useBG:Bool = false;
   public var curDialogue:Int = 0;
   public var currentChar:DialogueCharacter = null;
   var dialogueOpened:Bool = false;
   var dialogueStarted:Bool = false;
   var dialogueEnded:Bool = false;
   var invisibleChar:Bool = true;

   public var curCharacter:String = 'bf';
   public var boxTypes:Array<String> = ['normal', 'angry'];

   public function new(dialogue:JsonData, ?songName:String = null) 
   {
		super();

		dialogueData = dialogue;
		loadedChars = new Map<String, DialogueCharacter>();

		if (dialogue.useSong != null)
			if (dialogue.useSong && dialogue.songPath != null) {
				FlxG.sound.playMusic(Paths.music(dialogue.songPath), (dialogue.songFadeIn ? 0 : 1));
				if (dialogue.songFadeIn)
					FlxG.sound.music.fadeIn(2, 0, 1);
			}

		if (dialogue.gameVisible != null)
			if (!dialogue.gameVisible)
				useBG = true;

		if (useBG) {
			blackBG = new FlxSprite().makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
			blackBG.scrollFactor.set();
			blackBG.visible = true;
			blackBG.alpha = 1;
			add(blackBG);
		}

		box = new FlxSprite(FlxG.width / 16, 375);
		box.frames = Paths.getSparrowAtlas('speech_bubble_talking');
		box.antialiasing = PlayerPrefs.antialiasing;
		box.animation.addByPrefix('normalOpen', 'Speech Bubble Normal Open', 24, false);
		box.animation.addByPrefix('normal', 'speech bubble normal', 24, true);
		box.animation.addByPrefix('loudOpen', 'speech bubble loud open', 24, false);
		box.animation.addByPrefix('loud', 'AHH speech bubble', 24, true);

		if (dialogue.startBox != null)
			startBox = dialogue.startBox;

		loadCharacters();
		getDialogueList();
		openDialogueBox();
   }

   public function getDialogueList() {
		for (data in dialogueData.dialogueData)
			dialogueList.push(data.dialogue); 
   }

   public function openDialogueBox() {
		add(box);
		dialogueOpened = false;
		if (box != null) {
			switch (startBox) {
				case 'normal':
					box.animation.play('normalOpen', true);
				case 'loud':
					box.animation.play('loudOpen', true);
				default:
					box.animation.play('normalOpen', true);
			}
		}
   }

   public function setDialogueText(text:String) {
		if (dialogueText != null)
			remove(dialogueText);

		setCharacter(currentDialogue.char, currentDialogue.animName);

		dialogueText = new Alphabet(FlxG.width / 16, box.y + 50, text, false, true, true, currentDialogue.dialogueSpeed);
		dialogueText.alpha = 1;
		add(dialogueText);
   }

   override function update(elapsed:Float) 
   {
		if (box.animation.curAnim != null)
		{
			if (box.animation.curAnim.name == 'normalOpen' && box.animation.curAnim.finished) {
				box.animation.play('normal');
				dialogueOpened = true;
			}
			else if (box.animation.curAnim.name == 'loudOpen' && box.animation.curAnim.finished)
			{
				box.animation.play('loud');
				dialogueOpened = true;
			}
		}

		if (dialogueOpened && !dialogueStarted) {
			startDialogue();
			dialogueStarted = true;
		}

		if ((FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.SPACE)  && dialogueStarted == true) {
			if (dialogueList[1] == null && dialogueList[0] != null) {
				if (!dialogueEnded) {
					dialogueEnded = true;
					if (dialogueData.songFadeIn)
						FlxG.sound.music.fadeOut(2.2, 0);

					new FlxTimer().start(0.2, function(tmr:FlxTimer){
						box.alpha -= 1 / 5;
						if (useBG)
							blackBG.alpha -= 1 / 5 * 0.7;
						destroyCharacters();
						dialogueText.alpha = 1 / 5;
					});

					FlxTween.tween(box, {alpha: 0.0}, 1.5, {
						onComplete: function(twn:FlxTween){
							finishThing();
							kill();
						}
					});
					FlxTween.tween(dialogueText, {alpha: 0.0}, 1.5);
					if (useBG)
						FlxTween.tween(blackBG, {alpha: 0.0}, 1.5);
				}
			}
			else {
				continueDialogue();
			}
		}

		super.update(elapsed);
   }

   public function startDialogue() {
		curDialogue = 0;
		currentDialogue = dialogueData.dialogueData[0];
		setDialogueText(currentDialogue.dialogue);
   }

   public function continueDialogue() {
		curDialogue++;
		currentDialogue = dialogueData.dialogueData[curDialogue];
		dialogueList.remove(dialogueList[0]);
		setDialogueText(currentDialogue.dialogue);
   }

   public function setCharacter(char:String = 'bf', ?animName:String = '') {
		if (loadedChars.exists(char)) {
			currentChar = loadedChars.get(char);
			invisibleChar = false;
		}
		else {
			currentChar = null;
			invisibleChar = true;
		}

		if (!invisibleChar)
			currentChar.playAnim(animName);
   }

   public function loadCharacters() {
		for (i in 0...dialogueData.dialogueData.length) {
			if (!loadedChars.exists(dialogueData.dialogueData[i].char)) {
				var preloadChar:DialogueCharacter = new DialogueCharacter(0, 0, dialogueData.dialogueData[i].char);
				add(preloadChar);
				loadedChars.set(preloadChar.curCharacter, preloadChar);
			}
		}

		for (char in loadedChars.keys()) {
			var dialogueChar:DialogueCharacter = loadedChars.get(char);
			var x:Float = AligenmentFromString(loadedChars.get(char).charAlignment);
			var y:Float = box.y - (box.height / 1.75);

			x += dialogueChar.returnPosOffset(0);
			y += dialogueChar.returnPosOffset(1);

			dialogueChar.setPosition(x, y);
		}
   }

   public function destroyCharacters() {
		for (char in loadedChars.keys()) {
			var dialogueChar:DialogueCharacter = loadedChars.get(char);
			dialogueChar.kill();
			remove(dialogueChar);
		}
   }

   public function AligenmentFromString(alignment:String = null):Float
   {
		alignment = alignment.toLowerCase().trim();
		var returnValue:Float = -20;

		switch (alignment) {
			case 'left':
				returnValue = box.getMidpoint().x * 1.5;
			case 'middle':
				returnValue = box.getMidpoint().x / 1.5;
			case 'right':
				returnValue = box.y + (box.getMidpoint().x / 2);
			default:
				returnValue = -20;
		}

		return returnValue;
   }
}