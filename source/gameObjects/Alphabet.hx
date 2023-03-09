package gameObjects;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.util.FlxTimer;

using StringTools;

/**
 * Loosley based on FlxTypeText lolol
 */
class Alphabet extends FlxSpriteGroup
{
	public var delay:Float = 0.05;
	public var paused:Bool = false;

	// for menu shit
	public var targetY:Float = 0;
	public var disableX:Bool = false;
	public var xShit = 100;
	public var isMenuItem:Bool = false;
	public var alphaChars:Array<AlphaCharacter> = [];
	public var lastLetter:Int = 0;
	public var optionItem:Bool = false;
	public var typeSpeed:Float = 0.05;
	public var inDialogue:Bool = false;

	public var onType:Void -> Void;

	public var text:String = "";

	var _finalText:String = "";
	var _curText:String = "";

	public var widthOfWords:Float = FlxG.width;

	var yMulti:Float = 1;

	// custom shit
	// amp, backslash, question mark, apostrophy, comma, angry faic, period
	public var lastSprite:AlphaCharacter = null;
	public var firstSprite:AlphaCharacter = null;
	var xPosResetted:Bool = false;
	var lastWasSpace:Bool = false;

	var splitWords:Array<String> = [];

	var isBold:Bool = false;

	public function new(x:Float, y:Float, text:String = "", ?bold:Bool = false, ?typed:Bool = false, ?inDialogue:Bool = false, ?typeSpeed:Float = 0.05)
	{
		super(x, y);

		_finalText = text;
		this.text = text;
		isBold = bold;
		this.typeSpeed = typeSpeed;
		this.inDialogue = inDialogue;
		yMulti = 0;
		xPosResetted = false;

		if (this.typeSpeed <= 0) {
			trace('Type Speed is less than 0');
			this.typeSpeed = 0.05;
		}

		if (text != "")
		{
			if (typed)
				startTypedText();
			else
				addText();
		}
	}

	public function addText()
	{
		doSplitWords();

		createText(splitWords);
	}

	public function createText(newCharacters:Array<String>) {

		var loopNum:Int = 0;

		var xPos:Float = 0;
		var curRow:Int = 0;

		for (character in newCharacters)
		{
			if (_finalText.fastCodeAt(loopNum) == "\n".code)
			{
				yMulti += 1;
				xPosResetted = true;
				xPos = 0;
				curRow += 1;
			}

			if (splitWords[loopNum] == " ")
				lastWasSpace = true;

			var isNumber:Bool = AlphaCharacter.numbers.contains(splitWords[loopNum]);
			var isSymbol:Bool = AlphaCharacter.symbols.contains(splitWords[loopNum]);

			if (AlphaCharacter.alphabet.indexOf(splitWords[loopNum].toLowerCase()) != -1 || isNumber || isSymbol)
			{
				if (lastSprite != null && !xPosResetted) {
					lastSprite.updateHitbox();
					xPos += lastSprite.width + 3;
				}
				else
					xPosResetted = false;

				if (lastWasSpace) {
					xPos += 20;
					lastWasSpace = false;
				}

				var letter:AlphaCharacter = new AlphaCharacter(xPos, curRow * yMulti);
				letter.row = curRow;
				if (isBold) {
					letter.createBold(splitWords[loopNum]);
				}
				else
				{
					if (isNumber)
						letter.createNumber(splitWords[loopNum]);
					else if (isSymbol)
						letter.createSymbol(splitWords[loopNum]);
					else
						letter.createLetter(splitWords[loopNum]);

					letter.x += 90;
				}

				add(letter);

				if (firstSprite == null)
					firstSprite = letter;

				lastSprite = letter;
			}

			loopNum += 1;
		} 
	}

	public function setText(newText:String)
	{
		removeLetters();
		_finalText = newText;
		text = newText;
		createText(newText.split(''));
	}

	public function removeLetters()
	{
		forEach(function(lttr:FlxSprite){
			lttr.kill();
			lttr.destroy();
			remove(lttr);
		});

		lastSprite = null;
		firstSprite = null;

		alphaChars = [];
	}

	function doSplitWords():Void
	{
		splitWords = _finalText.split("");
	}

	public var personTalking:String = 'gf';

	public function startTypedText():Void
	{
		_finalText = text;
		doSplitWords();

		// trace(arrayShit);

		var loopNum:Int = 0;

		var xPos:Float = 0;
		var curRow:Int = 0;

		new FlxTimer().start(typeSpeed, function(tmr:FlxTimer)
		{
			if (_finalText.fastCodeAt(loopNum) == "\n".code)
			{
				yMulti += 1;
				xPosResetted = true;
				xPos = 0;
				curRow += 1;
			}

			if (splitWords[loopNum] == " ")
				lastWasSpace = true;

			var isNumber:Bool = AlphaCharacter.numbers.contains(splitWords[loopNum]);
			var isSymbol:Bool = AlphaCharacter.symbols.contains(splitWords[loopNum]);

			if (AlphaCharacter.alphabet.indexOf(splitWords[loopNum].toLowerCase()) != -1 || isNumber || isSymbol)
			{
				if (lastSprite != null && !xPosResetted) {
					lastSprite.updateHitbox();
					xPos += lastSprite.width + 3;
				}
				else
					xPosResetted = false;

				if (lastWasSpace) {
					xPos += 20;
					lastWasSpace = false;
				}

				var letter:AlphaCharacter = new AlphaCharacter(xPos, 55 * yMulti);
				letter.row = curRow;
				if (inDialogue) {
					letter.scale.set(0.7, 0.7);
				}

				if (isNumber)
					letter.createNumber(splitWords[loopNum]);
				else if (isSymbol)
					letter.createSymbol(splitWords[loopNum]);
				else {
					if (isBold)
						letter.createBold(splitWords[loopNum]);
					else {
						letter.createLetter(splitWords[loopNum]);
						letter.x += 90;
					}
				}

				add(letter);

				lastSprite = letter;
			}

			loopNum += 1;

			tmr.time = FlxG.random.float(0.04, 0.09);

			if (onType != null)
				onType();
		}, splitWords.length);
	}

	override function update(elapsed:Float)
	{
		if (isMenuItem)
		{
			var scaledY = FlxMath.remapToRange(targetY, 0, 1, 0, 1.3);

			y = FlxMath.lerp(y, (scaledY * 120) + (FlxG.height * 0.48), 0.16);

			if (optionItem)
				x = FlxMath.lerp(x, (targetY * 20 * 3) + 90 * 1.1, 0.16);
			else
				x = FlxMath.lerp(x, (targetY * 20) + 90, 0.16);
		}

		super.update(elapsed);
	}
}

class AlphaCharacter extends FlxSprite
{
	public static var alphabet:String = "abcdefghijklmnopqrstuvwxyz";

	public static var numbers:String = "1234567890";

	public static var symbols:String = "|~#$%()*+-:;<=>@[]^_.,'!?";

	public var row:Int = 0;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		var tex = Paths.getSparrowAtlas('alphabet');
		frames = tex;

		antialiasing = true;
	}

	public function createBold(letter:String)
	{
		animation.addByPrefix(letter, letter.toUpperCase() + " bold", 24);
		animation.play(letter);
		updateHitbox();
	}

	public function createLetter(letter:String):Void
	{
		var letterCase:String = "lowercase";
		if (letter.toLowerCase() != letter) {
			letterCase = 'capital';
		}

		animation.addByPrefix(letter, letter + " " + letterCase, 24);
		animation.play(letter);
		updateHitbox();

		y = (110 - height);
		y += row * 60;
	}

	public function createNumber(letter:String):Void
	{
		animation.addByPrefix(letter, letter, 24);
		animation.play(letter);

		updateHitbox();
	}

	public function createSymbol(letter:String)
	{
		switch (letter)
		{
			case '.':
				animation.addByPrefix(letter, 'period', 24);
				animation.play(letter);
				y += 50;
			case "'":
				animation.addByPrefix(letter, 'apostraphie', 24);
				animation.play(letter);
			case "?":
				animation.addByPrefix(letter, 'question mark', 24);
				animation.play(letter);
			case "!":
				animation.addByPrefix(letter, 'exclamation point', 24);
				animation.play(letter);
			case "$": 
				animation.addByPrefix(letter, 'dollarsign', 24);
				animation.play(letter);
			case "}":
				animation.addByPrefix(letter, 'end parentheses', 24);
				animation.play(letter);
			case "{":
				animation.addByPrefix(letter, 'start parentheses', 24);
				animation.play(letter);
			default:
				animation.addByPrefix(letter, letter, 24);
				animation.play(letter);
		}
		updateHitbox();
	}
}
