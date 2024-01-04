package modding;

import flixel.system.*;
import flixel.util.*;
import flixel.*;
import flixel.text.*;
import flixel.math.*;
import flixel.graphics.*;
import flixel.input.*;
import flixel.input.keyboard.*;
import flixel.addons.display.FlxBackdrop;
import haxe.Exception;
import haxe.ds.StringMap;
import openfl.display.GraphicsShader;
import openfl.display.Shader;
import openfl.filters.ShaderFilter;
import openfl.filters.BitmapFilter;
import flixel.graphics.tile.FlxGraphicsShader;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.text.FlxText.FlxTextBorderStyle;
import lime.utils.Assets;
import openfl.display.BlendMode;
import data.*;
import states.*;
import substates.*;
import gameObjects.*;
import gameObjects.notes.*;
import shaders.FlxRuntimeShader as FlxRunShader;

import mappedEvents.Event;
#if sys
import sys.FileSystem;
import sys.io.File;
import sys.thread.Thread;
#end

#if ALLOW_HSCRIPT
import hscript.Expr;
import hscript.Interp;
import hscript.Parser;
#end

using StringTools;

class HScript
{
	public static var FUNCTION_CONTINUE = 0;
	public static var FUNCTION_STOP = 1;

	#if ALLOW_HSCRIPT
	public var parser:Parser;
	public var interp:Interp;
	#end
	public var isAlive:Bool = true;
	public var moduleID:String = null;

	public var instance:FlxState;

	public function new(path:String)
	{
		var hxsFile:String = '';

		#if ALLOW_HSCRIPT
		#if sys
		if (FileSystem.exists(path))
			hxsFile = File.getContent(path);
		#else
		if (Assets.exists(path))
			hxsFile = Paths.getText(path);
		#end

		var contents:Expr = null;

		parser = new Parser();
		parser.allowTypes = true;

		if (hxsFile != '' && hxsFile != null)
			contents = parser.parseString(hxsFile);

		interp = new Interp();

		set("Sys", Sys);
		set("Std", Std);
		set("FlxMath", FlxMath);
		set("Conductor", Conductor);
		set("MusicBeatState", MusicBeatState);
		set("PlayState", PlayState);
		set("Note", Note);
		set("Paths", Paths);
		set("Character", Character);
		set("Boyfriend", Boyfriend);
		set("StringTools", StringTools);
		set("FlxG", FlxG);
		set("FlxTimer", FlxTimer);
		set("FlxTween", FlxTween);
		set("FlxEase", FlxEase);
		set("FlxSprite", FlxSprite);
		set("FlxText", FlxText);
		set("FlxTypedGroup", FlxTypedGroup);
		set("FlxGroup", FlxGroup);
		set("FlxTypedSpriteGroup", FlxTypedSpriteGroup);
		set("FlxCamera", FlxCamera);
		set("FlxAnimate", flxanimate.FlxAnimate);
		set("Song", Song);
		set("Strum", Strum);
		set("StaticArrow", Strum.StaticArrow);
		set("PlayerPrefs", PlayerPrefs);
		set("FlxBackdrop", FlxBackdrop);
		set("Xml", Xml);
		set("Reflect", Reflect);
		set("Math", Math);
		set("BGSprite", BGSprite);
		set("Array", Array);
		set("HScript", HScript);
		set("Parser", Parser);
		set("Main", Main);
		set("playSound", FlxG.sound.play);
		set("getOption", PlayerPrefs.getOptionValue);
		set("trace", traceText);

		setInstance();

		#if sys
		interp.variables.set("File", File);
		interp.variables.set("FileSystem", FileSystem);
		#end

		#if desktop
		interp.variables.set("Event", Event);
		interp.variables.set('FlxRuntimeShader', FlxRunShader);
		interp.variables.set("ShaderFilter", ShaderFilter);
		#end

		interp.variables.set("addLibrary", addLibrary);
		interp.variables.set("exists", exists);
		interp.variables.set("close", close);
		interp.variables.set("get", get);
		interp.variables.set("set", set);

		setNameFromPath(path);

		if (contents != null && path != '') {
			try {
				interp.execute(contents);
			}
			catch(e:Dynamic) {
				trace(e);
				close();
			}
		}
		else
			close();

		if (exists('onCreate') && isAlive)
			get('onCreate')();
		#end
	}


	public function getInstance():Dynamic
		return instance;

	public function setInstance(?state:FlxState) {
		var gameInstance:FlxState = state;
		if (gameInstance == null) gameInstance = FlxG.state;
		instance = gameInstance;
		#if ALLOW_HSCRIPT
		interp.variables.set("add", instance.add);
		interp.variables.set("remove", instance.remove);
		interp.variables.set("game", gameInstance);
		interp.variables.set("instance", gameInstance);
		#end
	}

	public function close():Dynamic {
		#if ALLOW_HSCRIPT
		interp = null;
		#end
		return this.isAlive = false;
	}

	#if ALLOW_HSCRIPT
	public function get(field:String):Dynamic
		return (isAlive ? interp.variables.get(field) : null);

	public function set(field:String, value:Dynamic) {
		if (isAlive)
			interp.variables.set(field, value);
	}
	#end

	public function runCode(codeToRun:String):Dynamic {
		#if ALLOW_HSCRIPT
		parser.line = 1;
		parser.allowTypes = true;
		return interp.execute(parser.parseString(codeToRun));
		#end
	}

	#if ALLOW_HSCRIPT
	public function addLibrary(lib:String, libPackage:String = '') {			
		if (isAlive && (lib != null && lib != '')) {
			try {
				var packageStr:String = '';
				if (libPackage.length > 0) {
					packageStr = '$libPackage.';
				}

				interp.variables.set(lib, Type.resolveClass(packageStr + lib));
			}
			catch(e:Dynamic) {
				trace(e);
			}
		}
	}

	public function exists(field:String):Bool
		return (isAlive ? interp.variables.exists(field) : false);
	#end

	public function traceText(text:Dynamic)
		return trace(text);

	public function call(func:String, args:Array<Dynamic>):Dynamic {
		if (func == null || !exists(func) || !isAlive) return null;

		return Reflect.callMethod(null, get(func), args);
	}

	public function blendFromString(blend:String):BlendMode {
		switch(blend.toLowerCase().trim()) {
			case 'add': return ADD;
			case 'alpha': return ALPHA;
			case 'darken': return DARKEN;
			case 'difference': return DIFFERENCE;
			case 'erase': return ERASE;
			case 'hardlight': return HARDLIGHT;
			case 'invert': return INVERT;
			case 'layer': return LAYER;
			case 'lighten': return LIGHTEN;
			case 'multiply': return MULTIPLY;
			case 'overlay': return OVERLAY;
			case 'screen': return SCREEN;
			case 'shader': return SHADER;
			case 'subtract': return SUBTRACT;
		}
		return NORMAL;
	}

	public function setNameFromPath(text:String = '') {
		if (text != null && text != '') {
			var splitPath:Array<String> = text.split('/');
			moduleID = splitPath[splitPath.length - 1];
		}
		else 
			moduleID = 'Unknown HScript';
	}
}