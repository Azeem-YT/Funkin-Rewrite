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

class NotesMenu extends BaseOptionsMenu
{
	override function create() {
		var stylePrefs:Array<String> = ["default", "normal", "pixel"];

		#if sys
		if (FileSystem.exists(Paths.mods('noteStyles/'))) {
			for (style in FileSystem.readDirectory(Paths.mods('noteStyles/'))) {
				if (style.endsWith('.json'))
					stylePrefs.push(style.substr(0, style.length - 5));
			}
		}
		#end

		var option:OptionPref = new OptionPref (
			'noteStyle',
			"Note Style",
			'string',
			"default",
			stylePrefs
		);
		pushOption(option);

		var option:OptionPref = new OptionPref (
			'noteAnim',
			"Animation Style",
			'string',
			"default",
			[
				'default',
				'finish'
			]
		);
		pushOption(option);

		super.create();
	}
}