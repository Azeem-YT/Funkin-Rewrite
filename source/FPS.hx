package;

import haxe.Timer;
import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFormat;
import flixel.math.FlxMath;
import openfl.system.System;
import openfl.display._internal.stats.Context3DStats;
import openfl.display._internal.stats.DrawCallContext;
import openfl.Lib;
import flixel.FlxG;
import flixel.util.FlxColor;
import data.*;

class FPS extends TextField
{
	public var currentFPS(default, null):Int;

	private var cacheCount:Int;
	private var currentTime:Float;
	private var times:Array<Float>;
	private var memoryCount:Float;
	private var maxMemory:Float;
	private var versionText:String = "Funkin' Nova Engine";
	private var fps_time:Float = 0;
	private var fps_hue:Int = 0;
	public static var currentClass:Dynamic = 'TitleState';

	public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
	{
		super();

		this.x = x;
		this.y = y;

		currentFPS = 0;
		selectable = false;
		mouseEnabled = false;
		defaultTextFormat = new TextFormat("_sans", Std.int(13.5), color);
		autoSize = LEFT;
		text = "FPS: ";

		cacheCount = 0;
		currentTime = 0;
		times = [];

		addEventListener(Event.ENTER_FRAME, function(e)
		{
			var time = Lib.getTimer();
			__enterFrame(time - currentTime);
		});
	}

	override function __update(transformOnly:Bool, updateChildren:Bool) {
		fps_time += FlxG.elapsed * 50;
		fps_hue = Std.int(fps_time);

		super.__update(updateChildren, updateChildren);
	}

	private override function __enterFrame(deltaTime:Float):Void
	{
		currentTime += deltaTime;
		times.push(currentTime);

		while (times[0] < currentTime - 1000)
		{
			times.shift();
		}

		var currentCount = times.length;
		currentFPS = Math.round((currentCount + cacheCount) / 4);

		visible = PlayerPrefs.fpsCounter;

		if (currentCount != cacheCount) {
			memoryCount = Math.abs(FlxMath.roundDecimal(System.totalMemory / 1000000, 1));
			if (maxMemory < memoryCount)
				maxMemory = memoryCount;

			text = "FPS: " + currentFPS;

			if (PlayerPrefs.showMem)
				text += '\nMemory: ' + memoryCount + ' MB\nMax Memory: ' + maxMemory + ' MB';

			#if debug
			text += '\nCurrent State: ' + Main.currentState;
			#end

			text += '\n' + versionText;


			if (PlayerPrefs.rainbowFps)
				textColor = FlxColor.fromHSB(fps_hue, 1, 1, 1);
			else
				textColor = 0xFFFFFFFF;

			#if (gl_stats && !disable_cffi && (!html5 || !canvas))
			text += "\ntotalDC: " + Context3DStats.totalDrawCalls();
			text += "\nstageDC: " + Context3DStats.contextDrawCalls(DrawCallContext.STAGE);
			text += "\nstage3DDC: " + Context3DStats.contextDrawCalls(DrawCallContext.STAGE3D);
			#end
		}

		cacheCount = currentCount;
	}
}

class FPSColors
{
	public static var colors:Array<Int> = [
		 0xFF0000FF,
		 0xFF8B4513,
		 0xFF00FFFF,
		 0xFF808080,
		 0xFF008000,
		 0xFF00FF00,
		 0xFFFF00FF,
		 0xFFFFA500,
		 0xFFFFC0CB,
		 0xFF800080,
		 0xFFFF0000,
		 0xFFFFFF00
	];

}