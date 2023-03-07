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
import sys.FileSystem;
import sys.io.File;
import lime.app.Application;

class Main extends Sprite
{
	var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var initialState:Class<FlxState> = TitleState; // The FlxState the game starts with.
	var zoom:Float = -1; // If -1, zoom is automatically calculated to fit the window dimensions.
	var skipSplash:Bool = true; // Whether to skip the flixel splash screen that appears in release mode.
	var startFullscreen:Bool = false;
	public static var currentState:String = 'TitleState';
	public static var framerateCounter:FPS;
	public static var fpsCap:Float = 60;
	public static var gotFPS:Bool = false;
	public static var loggedErrors:Array<String> = [];

	public static function main():Void {
		addChild(new Main());
	}

	public function new() {
		super();

		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, gameCrashed);

		if (stage != null) {
			init();
		}
		else {
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
	}

	private function init(?E:Event):Void {
		if (hasEventListener(Event.ADDED_TO_STAGE)) {
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}

		setupGame();
	}

	private function setupGame():Void {
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (zoom == -1) {
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
		
		trace("Starting...");
	}

	public static function getFPSCounter()
	{
		if (!gotFPS) {
			framerateCounter = new FPS(10, 3, 0xFFFFFF);
			Lib.current.addChild(framerateCounter);
			trace("Adding FPS Counter...");
			gotFPS = true;
		}
	}

	public static function setFPSVisible()
	{
		if (framerateCounter != null)
			framerateCounter.visible = PlayerPrefs.fpsCounter;
	}

	public static function gameCrashed(errorMsg:UncaughtErrorEvent)
	{
		var error:String = "Game Crashed!\n";
		var crashPath:String;
		var stack:Array<StackItem> = CallStack.exceptionStack(true);
		var curDate:String = Date.now().toString();

		curDate = StringTools.replace(curDate, " ", "_");
		curDate = StringTools.replace(curDate, ":", "'");

		crashPath = "crashs/UE_Crash" + curDate + ".txt";

		if (!FileSystem.exists("crashs/"))
			FileSystem.createDirectory("crashs/");

		for (stackItem in stack)
		{
			switch (stackItem)
			{
				case FilePos(s, file, line, column):
					error += file + " (line " + line + ")\n";
				default:
					Sys.println(stackItem);
					error += Std.string(stackItem);
			}
		}

		error += 'Logged Errors: \n';
		for (i in 0...loggedErrors.length) {
			error += '\n' + loggedErrors[i];
		}

		var errorShit:String = 'Unknown';

		if (errorMsg != null)
			errorShit = errorMsg.error;

		error += '\nUncaught Error: ' + errorShit + '\nThis is most likey because this version is unfinished. Check for Updates! ';

		File.saveContent(crashPath, error + "\n");

		Application.current.window.alert(error, "Error!");
		DiscordClient.shutdown();
		Sys.exit(1);
	}
}
