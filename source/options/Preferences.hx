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
#if desktop
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

class Preferences extends BaseOptionsMenu
{
	override function create() {

		var option:OptionPref = new OptionPref(
			'downscroll', 
			"Downscroll",
			'bool',
			false
		);
		pushOption(option);

		var option:OptionPref = new OptionPref(
			'middlescroll', 
			"Middlescroll",
			'bool',
			false
		);
		pushOption(option);

		var option:OptionPref = new OptionPref(
			'ghostTapping', 
			"Ghost Tapping",
			'bool',
			true
		);
		pushOption(option);

		var option:OptionPref = new OptionPref(
			'camCanZoom', 
			"Cam Zooming",
			'bool',
			false
		);
		pushOption(option);

		var option:OptionPref = new OptionPref(
			'botplay', 
			"Botplay",
			'bool',
			false
		);
		pushOption(option);

		var option:OptionPref = new OptionPref(
			'disableReset', 
			"Disable Reset",
			'bool',
			false
		);
		pushOption(option);

		var option:OptionPref = new OptionPref(
			'playOpponent', 
			"Play Opponent",
			'bool',
			false
		);
		pushOption(option);

		var option:OptionPref = new OptionPref(
			'marvelousRating', 
			"Marvelous Rating",
			'bool',
			true
		);
		pushOption(option);

		var option:OptionPref = new OptionPref(
			'timeType', 
			"Time Bar Type",
			'string',
			'Time Elapsed',
			[
				'Time Elapsed',
				'Song Name',
				'Disabled'
			]
		);
		pushOption(option);

		#if sys
		if (FileSystem.isDirectory(Paths.mods('options/preferences/'))) {
			for (file in FileSystem.readDirectory(Paths.mods('options/preferences/'))) {
				var filePath:String = Paths.mods('options/preferences/') + file;
				if (file.endsWith('.txt')) {
					pushOption(CoolUtil.optionFromText(filePath));
				}
			}
		}
		#end

		super.create();
	}
}