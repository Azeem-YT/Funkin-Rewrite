package;

import flixel.FlxGame;
import flixel.FlxG;
import flixel.FlxState;
import openfl.Assets;
import openfl.Lib;
import FPS;
import openfl.display.Sprite;
import openfl.events.Event;
import haxe.CallStack.StackItem;
import haxe.CallStack;
import openfl.events.UncaughtErrorEvent;
import lime.app.Application;

import states.*;
import data.*;

class Main extends Sprite
{
	var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var initialState:Class<FlxState> = TitleState; // The FlxState the game starts with.
	var zoom:Float = -1; // If -1, zoom is automatically calculated to fit the window dimensions.
	var skipSplash:Bool = true; // Whether to skip the flixel splash screen that appears in release mode.
	var startFullscreen:Bool = false;
	public static var currentState:String = 'TitleState';
	public static var gotFPS:Bool = false;
	public static var fpsCap:Float = 60;
	public static var loggedErrors:Array<String> = [];

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void
	{
		Lib.current.addChild(new Main());
	}

	public function new()
	{
		super();

		if (stage != null) {
			init();
		}
		else {
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
	}

	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}

		setupGame();
	}

	public static var framerateCounter:FPS;

	private function setupGame():Void
	{
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (zoom == -1)
		{
			var ratioX:Float = stageWidth / gameWidth;
			var ratioY:Float = stageHeight / gameHeight;
			zoom = Math.min(ratioX, ratioY);
			gameWidth = Math.ceil(stageWidth / zoom);
			gameHeight = Math.ceil(stageHeight / zoom);
		}

		#if !debug
		initialState = TitleState;
		#end

		FlxG.signals.preStateSwitch.add(function(){
			Paths.destroyImages();
		});

		FlxG.signals.postStateSwitch.add(function(){
			currentState = Std.string(Type.getClass(FlxG.state));
		});

		addChild(new FlxGame(gameWidth, gameHeight, initialState, zoom, 60, 60, skipSplash, startFullscreen));
		Paths.resetMods();
	}

	private override function __update(transformOnly:Bool, updateChildren:Bool)
	{
		super.__update(transformOnly, updateChildren); //If you wanna update something in Main.

	}

	public static function getFPSCounter() {
		if (!gotFPS) {
			framerateCounter = new FPS(10, 3, 0xFFFFFF);
			Lib.current.addChild(framerateCounter);
			trace("Adding FPS Counter...");
			gotFPS = true;
		}
	}

	public static function setFPSVisible() {
		if (framerateCounter != null)
			framerateCounter.visible = PlayerPrefs.fpsCounter;
	}
}
