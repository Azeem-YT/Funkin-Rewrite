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
#if sys
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

class GraphicsSettings extends BaseOptionsMenu
{
	override function create() {
		var option:OptionPref = new OptionPref(
			'fpsCounter', 
			"FPS Counter",
			'bool',
			true
		);
		pushOption(option);

		var option:OptionPref = new OptionPref(
			'antialiasing', 
			"Antialiasing",
			'bool',
			true
		);
		pushOption(option);

		var option:OptionPref = new OptionPref(
			'fpsCap', 
			"Framerate",
			'float',
			60.0
		);
		pushOption(option);

		option.maxValue = 360.0;
		option.minValue = 30.0;
		option.valueToAdd = 1.0;
						
		var option:OptionPref = new OptionPref(
			'showMem', 
			"Memory Counter",
			'bool',
			true
		);
		pushOption(option);
		
		var option:OptionPref = new OptionPref(
			'rainbowFps', 
			"Rainbow FPS Counter",
			'bool',
			true
		);
		pushOption(option);

		#if sys
		if (FileSystem.isDirectory(Paths.mods('options/graphics/'))) {
			for (file in FileSystem.readDirectory(Paths.mods('options/graphics/'))) {
				var filePath:String = Paths.mods('options/graphics/') + file;
				if (file.endsWith('.txt')) {
					pushOption(CoolUtil.optionFromText(filePath));
				}
			}
		}
		#end

		super.create();
	}
}