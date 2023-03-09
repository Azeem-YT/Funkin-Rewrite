package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.app.Application;

class ErrorState extends MusicBeatState
{
	var errorText(default, set):String;
	var displayText:FlxText;
	public static var song:String = 'Test';

	override function create() {
		super.create();

		displayText = new FlxText(0, 0, FlxG.width, "", 32);
		displayText.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, CENTER);
		displayText.screenCenter();
		add(displayText);

		errorText = 'HEY! A error occured with the song json!\n Press ENTER to return to the menu or Press C to \ngo to the Charting State';
		Main.loggedErrors.push('Error on Loading song - $song');
	}

	override function update(elapsed:Float)
	{
		if (FlxG.keys.justPressed.ENTER) {
			FlxG.switchState(new FreeplayState()); //Change Later!!!
		}

		if (FlxG.keys.justPressed.C) {
			FlxG.switchState(new FreeplayState());
		}
		
		super.update(elapsed);
	}

	inline function set_errorText(text:String):String {
		if (displayText != null)
			displayText.text = text;

		return text;
	}
}
