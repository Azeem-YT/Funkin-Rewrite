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

		interp.variables.set("Sys", Sys);
		interp.variables.set("Std", Std);
		interp.variables.set("FlxMath", FlxMath);
		interp.variables.set("Conductor", Conductor);
		interp.variables.set("MusicBeatState", MusicBeatState);
		interp.variables.set("PlayState", PlayState);
		interp.variables.set("Note", Note);
		interp.variables.set("Paths", Paths);
		interp.variables.set("Character", Character);
		interp.variables.set("Boyfriend", Boyfriend);
		interp.variables.set("StringTools", StringTools);
		interp.variables.set("FlxG", FlxG);
		interp.variables.set("FlxTimer", FlxTimer);
		interp.variables.set("FlxTween", FlxTween);
		interp.variables.set("FlxEase", FlxEase);
		interp.variables.set("FlxSprite", FlxSprite);
		interp.variables.set("FlxText", FlxText);
		interp.variables.set("FlxTypedGroup", FlxTypedGroup);
		interp.variables.set("FlxGroup", FlxGroup);
		interp.variables.set("FlxTypedSpriteGroup", FlxTypedSpriteGroup);
		interp.variables.set("FlxCamera", FlxCamera);
		interp.variables.set("FlxPoint", FlxPoint);
		interp.variables.set("FlxAxes", flixel.util.FlxAxes);
		interp.variables.set("FlxAnimate", flxanimate.FlxAnimate);
		interp.variables.set("Song", Song);
		interp.variables.set("Strum", Strum);
		interp.variables.set("StaticArrow", Strum.StaticArrow);
		interp.variables.set("PlayerPrefs", PlayerPrefs);
		interp.variables.set("FlxBackdrop", FlxBackdrop);
		interp.variables.set("Xml", Xml);
		interp.variables.set("Reflect", Reflect);
		interp.variables.set("Math", Math);
		interp.variables.set("BGSprite", BGSprite);
		interp.variables.set("Array", Array);
		interp.variables.set("HScript", HScript);
		interp.variables.set("Parser", Parser);
		interp.variables.set("Main", Main);
		interp.variables.set("playSound", FlxG.sound.play);
		interp.variables.set("trace", traceText);

		setInstance();

		#if sys
		interp.variables.set("File", File);
		interp.variables.set("FileSystem", FileSystem);
		#end

		#if desktop
		interp.variables.set("Event", Event);
		interp.variables.set('FlxRuntimeShader', FlxRuntimeShader);
		interp.variables.set("ShaderFilter", ShaderFilter);
		#end

		interp.variables.set("addLibrary", addLibrary);
		interp.variables.set("exists", exists);
		interp.variables.set("exit", exit);
		interp.variables.set("get", get);
		interp.variables.set("set", set);

		setNameFromPath(path);

		if (contents != null && path != '') {
			try {
				interp.execute(contents);
			}
			catch(e:Dynamic) {
				trace(e);
				exit();
			}
		}
		else
			exit();

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

	public function exit():Dynamic
		return this.isAlive = false;

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
	#end

	#if ALLOW_HSCRIPT
	public function exists(field:String):Bool
		return (isAlive ? interp.variables.exists(field) : false);
	#end

	public function traceText(text:Dynamic)
		return trace(text);

	public function getAbstract(className:String, libPackage:String, variable:String):Dynamic {
		if (className == null || className == '') return null;

		var packageStr:String = '';
		if (libPackage.length > 0) {
			packageStr = '$libPackage.';
		}

		var classVariable:Dynamic = null;

		try {
			 classVariable = Reflect.getProperty(Type.getClass(packageStr + className), variable);
		}
		catch(e:Dynamic) {
			trace(e);

			classVariable = null;
		}

		return classVariable;
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
			var killMeNow:String = StringTools.replace(splitPath[splitPath.length - 1], ".hx", "");
			moduleID = killMeNow;
		}
		else 
			moduleID = 'Unknown HScript';
	}
}