package modding;

#if ALLOW_LUA
import llua.Lua;
import llua.LuaL;
import llua.State;
import llua.Convert;
#end

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.effects.FlxTrail;
import flixel.input.keyboard.FlxKey;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.text.FlxText;
import flixel.FlxCamera;
import flixel.util.FlxColor;
import flixel.FlxBasic;
import flixel.FlxObject;
import openfl.Lib;
import openfl.display.BlendMode;
import openfl.utils.Assets;
import flixel.math.FlxMath;
import flixel.system.FlxAssets.FlxShader;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import Type.ValueType;
import openfl.filters.ShaderFilter;
import flixel.util.FlxTimer;
import openfl.filters.BitmapFilter;
import gameObjects.*;
import gameObjects.notes.*;
import engine.*;
import states.*;
import data.*;

import gameObjects.notes.Strum.StaticArrow;

#if sys
import FlxRuntimeShader;
import flash.display.Shader;
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

class LuaState
{
	#if ALLOW_LUA
	public var lua:State;
	#end
	public var isClosed:Bool = false;
	public var playstate:PlayState;

	public static var errorStop:Dynamic = 1;
	public static var stopFunc:Dynamic = 0;
	public static var continueFunc:Dynamic = 2;
	public var scriptName:String;

	#if ALLOW_HSCRIPT
	public var hscript:HScript;
	#end

	public function new(luaPath:String) {
		if (PlayState.instance != null) playstate = PlayState.instance;
		else playstate = new PlayState();

		#if ALLOW_LUA
		lua = LuaL.newstate();
		LuaL.openlibs(lua);
		Lua.init_callbacks(lua);
		#end

		#if ALLOW_LUA
		trace('Trying to load file: $luaPath');
		var luaFile:Dynamic = LuaL.dofile(lua, luaPath);
		var error:String = Lua.tostring(lua, luaFile);
		if (error != null && luaFile != 0) {
			trace('Error on lua script: ' + error);
			#if windows
			lime.app.Application.current.window.alert(error, "Error on lua script!");
			#end
			lua = null;
			isClosed = true;
			return;
		}
		#end

		#if ALLOW_HSCRIPT
		hscript = new HScript('');
		#end

		var luaSplit:Array<String> = luaPath.split('/');
		scriptName = luaSplit[luaSplit.length - 1];
		scriptName.replace('.lua', '');

		hscript.moduleID = "Lua Script: $scriptName";

		setVar('curBPM', Conductor.bpm);
		setVar('scrollSpeed', PlayState.SONG.speed);
		setVar('crochet', Conductor.crochet);
		setVar('stepCrochet', Conductor.stepCrochet);
		setVar('songLength', FlxG.sound.music.length);
		setVar('songName', PlayState.SONG.song);
		setVar('curStage', PlayState.SONG.stage);
		setVar('isStoryMode', PlayState.isStoryMode);
		setVar('diffNumber', PlayState.storyDifficulty);

		setVar('curBeat', 0);
		setVar('curStep', 0);

		setVar('downscroll', PlayerPrefs.downscroll);
		setVar('middlescroll', PlayerPrefs.middlescroll);
		setVar('framerate', PlayerPrefs.fpsCap);
		setVar('ghostTapping', PlayerPrefs.ghostTapping);
		setVar('healthBarAlpha', PlayerPrefs.healthAlpha);
		setVar('timeBarAlpha', PlayerPrefs.timeBarAlpha);
		setVar('disableReset', PlayerPrefs.disableReset);
		setVar('camZooming', PlayerPrefs.camCanZoom);
		setVar('noteSplashes', PlayerPrefs.noteSplashes);
		setVar('botplay', PlayerPrefs.botplay);
		setVar('songPosition', Conductor.songPosition);

		setVar('errorStop', errorStop);
		setVar('stopFunc', stopFunc);
		setVar('continueFunc', continueFunc);
		
		#if ALLOW_LUA
		Lua_helper.add_callback(lua, "setSpriteShader", function(obj:String, shaderName:String) {
			setSpriteShader(obj, shaderName);
		});
		
		Lua_helper.add_callback(lua, "removeSpriteShader", function(obj:String) {
			var sprite:FlxSprite = getSprite(obj);

			if (sprite != null) {
				if (sprite.shader != null) {
					sprite.shader = null;
				}
			}
		});
		
		Lua_helper.add_callback(lua, "setCameraShader", function(obj:String, shaderName:String) {
			if (getLuaCamera(obj) == null) return;

			if (!PlayState.luaShaders.exists(shaderName)) initLuaShader(shaderName);
			if (PlayState.luaShaders.get(shaderName) == null) return;

			var shaderArgs:Array<String> = PlayState.luaShaders.get(shaderName);

			#if sys
			var camera:Dynamic = getLuaCamera(obj);

			if (Std.isOfType(camera, FlxCamera)) {		
				var shader:FlxRuntimeShader = new FlxRuntimeShader(shaderArgs[0], shaderArgs[1]);
				if (shader != null) {
					var cameraFilter:ShaderFilter = new ShaderFilter(shader);
					camera.setFilters([cameraFilter]);
				}
			}
			else {
				var shader:FlxRuntimeShader = new FlxRuntimeShader(shaderArgs[0], shaderArgs[1]);
				camera.pushShader(shader);
			}
			#end
		});
		
		Lua_helper.add_callback(lua, "removeCameraShader", function(name:String) {
			if (getLuaCamera(name) != null) {
				var camera:FlxCamera = getLuaCamera(name);
				camera.setFilters([]);
			}
		});

		Lua_helper.add_callback(lua, "makeCamera", function(name:String, x:Int = 0, y:Int = 0, width:Int = 0, height:Int = 0, zoom:Float = 0) {
			var camera:LuaCamera = new LuaCamera(name, x, y, width, height, zoom);
			playstate.addCamera(camera, name);
		});

		Lua_helper.add_callback(lua, "makeNewSprite", function(name:String, imgPath:String, x:Float, y:Float) {
			makeLuaSprite(name, imgPath, x, y);
		});

		Lua_helper.add_callback(lua, "makeAnimatedSprite", function(name:String, imgPath:String, x:Float, y:Float, atlasType:String = 'sparrow') {
			makeAnimatedSprite(name, imgPath, x, y, atlasType);
		});
		
		Lua_helper.add_callback(lua, "loadGraphic", function(obj:String, imgPath:String, ?gridX:Int = 0, ?gridY:Int = 0, ?animated:Null<Bool> = false) {
			var sprite:FlxSprite = getSprite(obj);

			if (sprite != null) {
				if (animated == null)
					animated = (gridX != 0 || gridY != 0);

				sprite.loadGraphic(Paths.image(imgPath), animated, gridX, gridY);
			}
		});
		
		Lua_helper.add_callback(lua, "makeGraphic", function(name:String, width:Int, height:Int, color:String) {
			var realColor:Int = colorFromString(color);

			var sprite:FlxSprite = PlayState.luaSprites.get(name);
			if (sprite != null) {
				sprite.makeGraphic(width, height, realColor);
				return;
			}
			else {
				sprite = Reflect.getProperty(PlayState, name);
				if (sprite != null)
					sprite.makeGraphic(width, height, realColor);
			}
		});
		
		Lua_helper.add_callback(lua, "addAnimByPrefix", function(id:String, anim:String, prefix:String, fps:Int = 24, looped:Bool = false) {
			addAnimByPrefix(id, anim, prefix, fps, looped);
		});
		
		Lua_helper.add_callback(lua, "addAnimByIndices", function(id:String, anim:String, prefix:String, indices:String, fps:Int = 24) {
			addAnimByIndices(id, anim, prefix, indices, fps, false);
		});
		
		Lua_helper.add_callback(lua, "addAnimByIndicesLoop", function(id:String, anim:String, prefix:String, indices:String, fps:Int = 24) { //Can't have more than 5 args
			addAnimByIndices(id, anim, prefix, indices, fps, true);
		});

		Lua_helper.add_callback(lua, "setScrollFactor", function(name:String, x:Float, y:Float) { //Can't have more than 5 args
			if (PlayState.luaSprites.exists(name)) {
				var luaSprite:LuaSprite = PlayState.luaSprites.get(name);
				if (luaSprite != null)
					luaSprite.scrollFactor.set(x, y);

				return;
			}

			var sprite:FlxSprite = Reflect.getProperty(PlayState, name);
			if (sprite != null)
				sprite.scrollFactor.set(x, y);
		});

		Lua_helper.add_callback(lua, "setObjectScale", function(name:String, xScale:Float, yScale:Float) {
			setObjectScale(name, xScale, yScale);
		});
		
		Lua_helper.add_callback(lua, "addSprite", function(name:String, front:Bool) {
			addLuaSprite(name, front);
		});

		Lua_helper.add_callback(lua, "removeSprite", function(name:String, erase:Bool) {
			removeLuaSprite(name, erase);
		});
		
		Lua_helper.add_callback(lua, "playAnim", function(name:String, forced:Bool) {
			var sprite:Dynamic = getSprite(name);

			if (sprite != null) {
				if (Std.isOfType(sprite, LuaSprite))
					sprite.playAnim(name, forced);
				else
					sprite.animation.play(name, forced);
			}
		});

		Lua_helper.add_callback(lua, "playMusic", function(sound:String, volume:Float = 1, loop:Bool = false) {
			FlxG.sound.playMusic(Paths.music(sound), volume, loop);
		});

		Lua_helper.add_callback(lua, "loadSong", function(song:String, diffNumb:Int = -1) {
			if (song == null || song.length < 1) song = PlayState.SONG.song;
			if (diffNumb < 0) diffNumb = PlayState.storyDifficulty;

			var diff:String = CoolUtil.difficultyArray[diffNumb];
			if (diff == null) diff = '';

			var songShit = Highscore.formatSong(song, diff);
			PlayState.SONG = Song.loadFromJson(songShit, song);
			PlayState.storyDifficulty = diffNumb;
			playstate.persistentUpdate = false;
			LoadingState.loadAndSwitchState(new PlayState());

			FlxG.sound.music.pause();
			FlxG.sound.music.volume = 0;
			if (playstate.vocals != null){
				playstate.vocals.pause();
				playstate.vocals.volume = 0;
			}
		});

		Lua_helper.add_callback(lua, "getProperty", function(variable:String) {
			var varArray:Array<String> = variable.split('.');

			if (varArray.length > 1) {
				var object = getObject(varArray[0]);

				for (i in 1...varArray.length - 1)
					object = Reflect.getProperty(object, varArray[i]);

				return Reflect.getProperty(object, varArray[varArray.length - 1]);
			}
				
			return Reflect.getProperty(playstate, variable);
		});
		
		Lua_helper.add_callback(lua, "setProperty", function(variable:String, value:Dynamic) {
			var varArray:Array<String> = variable.split('.');

			if (varArray.length > 1) {
				var object = getObject(varArray[0]);

				for (i in 1...varArray.length - 1)
					object = Reflect.getProperty(object, varArray[i]);

				return Reflect.setProperty(object, varArray[varArray.length - 1], value);
			}

			return Reflect.setProperty(playstate, variable, value);
		});
		
		Lua_helper.add_callback(lua, "setObjectCamera", function(name:String, cameraName:String) {
			var sprite:Dynamic = getObject(name);

			if (sprite != null) {
				sprite.cameras = [playstate.cameraFromString(cameraName)];
			}
		});

		Lua_helper.add_callback(lua, "tweenX", function(tweenID:String, object:String, value:Dynamic, duration:Float, ease:String) {
			tweenX(tweenID, object, value, duration, ease);
		});

		Lua_helper.add_callback(lua, "tweenY", function(tweenID:String, object:String, value:Dynamic, duration:Float, ease:String) {
			tweenY(tweenID, object, value, duration, ease);
		});

		Lua_helper.add_callback(lua, "tweenAlpha", function(tweenID:String, object:String, value:Dynamic, duration:Float, ease:String) {
			tweenAlpha(tweenID, object, value, duration, ease);
		});

		Lua_helper.add_callback(lua, "tweenAngle", function(tweenID:String, object:String, value:Dynamic, duration:Float, ease:String) {
			tweenAngle(tweenID, object, value, duration, ease);
		});

		Lua_helper.add_callback(lua, "tweenColor", function(tweenID:String, object:String, value:Dynamic, duration:Float, ease:String) {
			tweenColor(tweenID, object, value, duration, ease);
		});
		
		Lua_helper.add_callback(lua, "setSpriteBlend", function(name:String, blend:String) {
			var sprite:FlxSprite = getSprite(name);

			if (sprite != null) {
				sprite.blend = blendFromString(blend);
			}
		});
		
		Lua_helper.add_callback(lua, "gameTrace", function(text:String = '') {
			trace(text);
		});

		Lua_helper.add_callback(lua, "getGlobal", function(obj:String) {
			if (PlayState.globalVariables.exists(obj)) {
				return PlayState.globalVariables.get(obj);
			}

			return null;
		});
		
		Lua_helper.add_callback(lua, "setGlobal", function(obj:String, variable:String, value:Dynamic) {
			if (PlayState.globalVariables.exists(obj)) {
				var globalVar:Dynamic = PlayState.globalVariables.get(obj);
				if (globalVar != null)
					Reflect.setProperty(globalVar, variable, value);
			}
		});

		Lua_helper.add_callback(lua, "openURL", function(url:String) {
			#if linux
			Sys.command('/usr/bin/xdg-open', [url]);
			#else
			FlxG.openURL(url);
			#end
		});
		
		Lua_helper.add_callback(lua, "doFunction", function(functionVar:String, args:Array<Dynamic>) {
			var varArray:Array<String> = functionVar.split('.');
			var func = Reflect.getProperty(PlayState.instance, functionVar);

			if (varArray.length > 1) {
				for (i in 1...varArray.length - 1)
					func = Reflect.getProperty(func, varArray[i]);
			}

			Reflect.callMethod(null, func, args);
		});

		Lua_helper.add_callback(lua, "doFunctionFromClass", function(className:String, functionVar:String, args:Array<Dynamic>) {
			try {
				var varArray:Array<String> = functionVar.split('.');
				var func = Reflect.getProperty(Type.resolveClass(className), functionVar);

				if (varArray.length > 1) {
					for (i in 1...varArray.length - 1)
						func = Reflect.getProperty(func, varArray[i]);
				}

				Reflect.callMethod(null, func, args);
			}
			catch(e:Dynamic) {
				trace(e);
			}
		});

		Lua_helper.add_callback(lua, "runCode", function(codeToRun:String) {
			if (codeToRun != null && codeToRun != '') {
				try {
					hscript.runCode(codeToRun);
				}
				catch(e:Dynamic) {
					trace(e);
				}
			}
		});
		
		Lua_helper.add_callback(lua, "addLibrary", function(name:String = null, packageNme:String = '') {
			if (hscript != null) {
				hscript.addLibrary(name, packageNme);
			}
		});
		
		Lua_helper.add_callback(lua, "isOfType", function(variable:Dynamic, type:String) {
			try {
				if (variable != null) {
					if (Std.isOfType(variable, Type.resolveClass(type)))
						return true;
				}
			}
			catch(e:Dynamic) {
				trace(e);
			}

			return false;
		});

		Lua_helper.add_callback(lua, "pressed", function(key:String) {
			return Reflect.getProperty(FlxG.keys.pressed, key);
		});
		
		Lua_helper.add_callback(lua, "justPressed", function(key:String) {
			return Reflect.getProperty(FlxG.keys.justPressed, key);
		});

		Lua_helper.add_callback(lua, "justReleased", function(key:String){
			return Reflect.getProperty(FlxG.keys.justReleased, key);
		});

		Lua_helper.add_callback(lua, "getRandom", function(type:String = 'int', min:Dynamic, max:Dynamic){

			type = type.toLowerCase();

			if (type == 'integer')
				type = 'int';

			return switch (type) {
				case 'int': FlxG.random.int(min, max);
				case 'float': FlxG.random.float(min, max);
				default: FlxG.random.int(min, max);
			}
		});

		Lua_helper.add_callback(lua, "getRandomBool", function(chance:Float = 50){
			return FlxG.random.bool(chance);
		});

		Lua_helper.add_callback(lua, "getStrumFromStrumline", function(strumNumber:Int, strumID:Int){
			if (PlayState.strumLines != null && PlayState.strumLines.members[strumNumber] != null && PlayState.strumLines.members[strumNumber].strums != null  && PlayState.strumLines.members[strumNumber].strums.members[strumID] != null) {
				return getStrumNote(strumNumber, strumID);
			}

			return null;
		});

		Lua_helper.add_callback(lua, "tweenNoteX", function(tweenTag:String, strumNumber:Int, strumID:Int, value:Dynamic, duration:Float, ease:String){
			resetTween(tweenTag);

			var staticArrow:StaticArrow = getStrumNote(strumNumber, strumID);

			if (staticArrow != null) {
				var tween:FlxTween = FlxTween.tween(staticArrow, {x: value}, duration, {
					ease: easeFromString(ease),
					onComplete: function(twn:FlxTween) {
						playstate.callLua('onTweenComplete', [tweenTag]);
					}
				});

				PlayState.luaTweens.set(tweenTag, tween);
			}
		});

		Lua_helper.add_callback(lua, "tweenNoteY", function(tweenTag:String, strumNumber:Int, strumID:Int, value:Dynamic, duration:Float, ease:String){
			resetTween(tweenTag);

			var staticArrow:StaticArrow = getStrumNote(strumNumber, strumID);

			if (staticArrow != null) {
				var tween:FlxTween = FlxTween.tween(staticArrow, {y: value}, duration, {
					ease: easeFromString(ease),
					onComplete: function(twn:FlxTween) {
						playstate.callLua('onTweenComplete', [tweenTag]);
					}
				});

				PlayState.luaTweens.set(tweenTag, tween);
			}
		});

		Lua_helper.add_callback(lua, "tweenNoteAngle", function(tweenTag:String, strumNumber:Int, strumID:Int, value:Dynamic, duration:Float, ease:String){
			resetTween(tweenTag);

			var staticArrow:StaticArrow = getStrumNote(strumNumber, strumID);

			if (staticArrow != null) {
				var tween:FlxTween = FlxTween.tween(staticArrow, {angle: value}, duration, {
					ease: easeFromString(ease),
					onComplete: function(twn:FlxTween) {
						playstate.callLua('onTweenComplete', [tweenTag]);
					}
				});

				PlayState.luaTweens.set(tweenTag, tween);
			}
		});

		Lua_helper.add_callback(lua, "tweenNoteAlpha", function(tweenTag:String, strumNumber:Int, strumID:Int, value:Dynamic, duration:Float, ease:String){
			resetTween(tweenTag);

			var staticArrow:StaticArrow = getStrumNote(strumNumber, strumID);

			if (staticArrow != null) {
				var tween:FlxTween = FlxTween.tween(staticArrow, {alpha: value}, duration, {
					ease: easeFromString(ease),
					onComplete: function(twn:FlxTween) {
						playstate.callLua('onTweenComplete', [tweenTag]);
					}
				});

				PlayState.luaTweens.set(tweenTag, tween);
			}
		});

		Lua_helper.add_callback(lua, "createNewStrumline", function(x:Float, arrowTexture:String, downscroll:Bool){
			var strumline:Strum = new Strum(x, playstate, arrowTexture, null, downscroll);
			PlayState.strumLines.add(strumline);
			for (i in 0...3)
					PlayState.strumLineNotes.add(strumline.strums.members[i]);
		});

		Lua_helper.add_callback(lua, "startDialogue", function(dataPath:String){
			playstate.startDialogue(dataPath);
		});

		Lua_helper.add_callback(lua, "setCharacterX", function(name:String, val:Float) {
			switch (name) {
				case 'boyfriend' | 'bf' | 'player':
					PlayState.boyfriendGroup.x = val;
				case 'girlfriend' | 'gf':
					PlayState.gfGroup.x = val;
				case 'opponent' | 'dad':
					PlayState.dadGroup.x = val;
			}
		});
		
		Lua_helper.add_callback(lua, "setCharacterY", function(name:String, val:Float) {
			switch (name) {
				case 'boyfriend' | 'bf' | 'player':
					PlayState.boyfriendGroup.y = val;
				case 'girlfriend' | 'gf':
					PlayState.gfGroup.y = val;
				case 'opponent' | 'dad':
					PlayState.dadGroup.y = val;
			}
		});

		Lua_helper.add_callback(lua, "getPropertyFromGroup", function(obj:String, index:Int, variable:Dynamic) {
			var object:Dynamic = getObject(obj);

			var varArray:Array<String> = variable.split('.');

			if (object == null) {
				if (Std.isOfType(object, FlxTypedGroup) || Std.isOfType(object, FlxSpriteGroup))
					return getPropertyFromTypedGroup(object.members[index], variable);

				if (varArray.length > 1) {
					var what:Dynamic = Reflect.getProperty(object[index], varArray[0]);

					for (i in 1...varArray.length - 1)
						what = Reflect.getProperty(what, varArray[i]);

					return Reflect.getProperty(what, varArray[varArray.length - 1]);
				}
			}

			return Reflect.getProperty(object[index], variable);
		});
		
		Lua_helper.add_callback(lua, "setPropertyFromGroup", function(obj:String, index:Int, variable:Dynamic, value:Dynamic) {
			var object:Dynamic = getObject(obj);

			var varArray:Array<String> = variable.split('.');

			if (object == null) {
				if (Std.isOfType(object, FlxTypedGroup) || Std.isOfType(object, FlxSpriteGroup))
					return setPropertyFromTypedGroup(object.members[index], variable, value);

				if (varArray.length > 1) {
					var what:Dynamic = Reflect.getProperty(object[index], varArray[0]);

					for (i in 1...varArray.length - 1)
						what = Reflect.getProperty(what, varArray[i]);

					return Reflect.setProperty(what, varArray[varArray.length - 1], value);
				}
			}

			return Reflect.setProperty(object[index], variable, value);
		});
		
		Lua_helper.add_callback(lua, "getPropertyFromClass", function(className:String, variable:String) {
			var varArray:Array<String> = variable.split('.');
			if (varArray.length > 1) {
				var classVariable:Dynamic = Reflect.getProperty(Type.resolveClass(className), varArray[0]);

				for (i in 1...varArray.length - 1)
					classVariable = Reflect.getProperty(classVariable, varArray[i]);

				Reflect.getProperty(classVariable, varArray[varArray.length - 1]);
			}

			Reflect.getProperty(Type.resolveClass(className), variable);
		});
		
		Lua_helper.add_callback(lua, "setPropertyFromClass", function(className:String, variable:String, value:Dynamic) {
			var varArray:Array<String> = variable.split('.');
			if (varArray.length > 1) {
				var classVariable:Dynamic = Reflect.getProperty(Type.resolveClass(className), varArray[0]);

				for (i in 1...varArray.length - 1)
					classVariable = Reflect.getProperty(classVariable, varArray[i]);

				Reflect.setProperty(classVariable, varArray[varArray.length - 1], value);
			}

			Reflect.setProperty(Type.resolveClass(className), variable, value);
		});
				
		Lua_helper.add_callback(lua, "precacheImage", function(key:String) {
			Paths.image(key);
		});
		
		Lua_helper.add_callback(lua, "precacheSound", function(name:String) {
			Paths.sound(name);
		});
				
		Lua_helper.add_callback(lua, "getShaderBool", function(obj:String, prop:String) {
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				return null;
			}

			#if sys
			return shader.getBool(prop);
			#end

			return null;
		});
		Lua_helper.add_callback(lua, "getShaderBoolArray", function(obj:String, prop:String) {
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				return null;
			}

			#if sys
			return shader.getBoolArray(prop);
			#end

			return null;
		});
		Lua_helper.add_callback(lua, "getShaderInt", function(obj:String, prop:String) {
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				return null;
			}

			#if sys
			return shader.getInt(prop);
			#end

			return null;
		});

		Lua_helper.add_callback(lua, "getShaderIntArray", function(obj:String, prop:String) {
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				return null;
			}

			#if sys
			return shader.getIntArray(prop);
			#end

			return null;
		});

		Lua_helper.add_callback(lua, "getShaderFloat", function(obj:String, prop:String) {
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				return null;
			}

			#if sys
			return shader.getFloat(prop);
			#end

			return null;
		});
		Lua_helper.add_callback(lua, "getShaderFloatArray", function(obj:String, prop:String) {
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				return null;
			}

			#if sys
			return shader.getFloatArray(prop);
			#end

			return null;
		});

		Lua_helper.add_callback(lua, "setShaderBool", function(obj:String, prop:String, value:Bool) {
			var shader:FlxRuntimeShader = getShader(obj);
			if(shader == null) return;

			#if sys
			shader.setBool(prop, value);
			#end
		});

		Lua_helper.add_callback(lua, "setShaderBoolArray", function(obj:String, prop:String, values:Dynamic) {
			var shader:FlxRuntimeShader = getShader(obj);
			if(shader == null) return;

			#if sys
			shader.setBoolArray(prop, values);
			#end
		});

		Lua_helper.add_callback(lua, "setShaderInt", function(obj:String, prop:String, value:Int) {
			var shader:FlxRuntimeShader = getShader(obj);
			if(shader == null) return;

			#if sys
			shader.setInt(prop, value);
			#end
		});

		Lua_helper.add_callback(lua, "setShaderIntArray", function(obj:String, prop:String, values:Dynamic) {
			var shader:FlxRuntimeShader = getShader(obj);
			if(shader == null) return;

			#if sys
			shader.setIntArray(prop, values);
			#end
		});

		Lua_helper.add_callback(lua, "setShaderFloat", function(obj:String, prop:String, value:Float) {
			var shader:FlxRuntimeShader = getShader(obj);
			if(shader == null) return;

			#if sys
			shader.setFloat(prop, value);
			#end
		});

		Lua_helper.add_callback(lua, "setShaderFloatArray", function(obj:String, prop:String, values:Dynamic) {
			var shader:FlxRuntimeShader = getShader(obj);
			if(shader == null) return;

			#if sys
			shader.setFloatArray(prop, values);
			#end
		});
		#end
	}

	public function setSpriteShader(obj:String, shader:String) {
		#if sys
		if (!PlayState.luaShaders.exists(shader))
			initLuaShader(shader);

		if (!PlayState.luaShaders.exists(shader))
			return;

		var sprite:FlxSprite = getSprite(obj);

		if (sprite != null) {
			var shadershit:Array<String> = PlayState.luaShaders.get(shader);
			sprite.shader = new FlxRuntimeShader(shadershit[0], shadershit[1]);
		}
		#end
	}

	public function initLuaShader(shader:String) {
		#if sys
		var directorys:Array<String> = [Paths.mods('shaders/')];

		for (dir in directorys) {
			if (FileSystem.isDirectory(dir))
			{
				var canPush:Bool = false;

				var fragPath:String = dir + shader + '.frag';
				var vertPath:String = dir + shader + '.vert';

				var fragFile:String = null;
				var vertFile:String = null;

				if (FileSystem.exists(fragPath)) {
					fragFile = File.getContent(fragPath);
					canPush = true;
				}
				else
					fragFile = null;

				if (FileSystem.exists(vertPath)) {
					vertFile = File.getContent(vertPath);
					canPush = true;
				}
				else
					vertFile = null;

				if (canPush)
					PlayState.luaShaders.set(shader, [fragFile, vertFile]);
			}
		}
		#end
	}

	public function getStringVal(str:String, val:String):Dynamic {
		switch(str.toLowerCase().trim()) {
			case 'startswith':
				return str.startsWith(val);
			case 'split':
				return str.split(val);
			case 'endswith':
				return str.endsWith(val);
			case 'trim':
				return str.trim();
		}
		return false;
	}

	public function setVar(variable:String, obj:Dynamic) {
		#if ALLOW_LUA
		if (lua == null)
			return;

		Convert.toLua(lua, obj);
		Lua.setglobal(lua, variable);
		#end
	}

	public function callFunc(func:String, args:Array<Dynamic>):Dynamic {
		#if ALLOW_LUA
		if (isClosed || lua == null)
			return continueFunc;

		try {
			Lua.getglobal(lua, func);

			var variableType:Int = Lua.type(lua, -1);

			if (variableType != Lua.LUA_TFUNCTION) {
				Lua.pop(lua, 1);
				return continueFunc;
			}

			for (arg in args) {
				Convert.toLua(lua, arg);
			}

			var luaOk:Int = Lua.pcall(lua, args.length, 1, 0);
			if (luaOk != Lua.LUA_OK) {
				//playstate.addNotification("Error with function " + func + ' on script: ' + scriptName);
				trace("Error with function " + func + ' on script: ' + scriptName);
				return continueFunc;
			}

			var returnValue:Dynamic = cast Convert.fromLua(lua, -1);
			if (returnValue == null)
				returnValue = continueFunc;

			Lua.pop(lua, 1);
			return returnValue;
		}
		catch (e:Dynamic) {
			Main.loggedErrors.push(Std.string(e));
			trace(e);
		}
		#end

		return continueFunc;
	}

	public function removeTag(id:String) {
		var sprite:LuaSprite = null;

		if (!PlayState.luaSprites.exists(id))
			return;

		sprite = PlayState.luaSprites.get(id);
		if (sprite.wasAdded) {
			sprite.wasAdded = false;
			if (sprite != null) {
				sprite.kill();
				sprite.destroy();
			}
		}

	}

	public function makeLuaSprite(spriteID:String, image:String, x:Float, y:Float) {
		spriteID = spriteID.replace('.', '');
		removeTag(spriteID);

		var sprite:LuaSprite = new LuaSprite(x, y);
		if (image != null && image != '')
			sprite.loadGraphic(Paths.image(image));

		if (sprite != null) {
			sprite.antialiasing = PlayerPrefs.antialiasing;
			PlayState.luaSprites.set(spriteID, sprite);
			sprite.active = true;
		}
	}

	public function makeAnimatedSprite(spriteID:String, imagePath:String, ?x:Float = 0, ?y:Float = 0, atlasType:String = 'sparrow') {
		spriteID = spriteID.replace('.', '');
		removeTag(spriteID);
		var sprite:LuaSprite = new LuaSprite(x, y);
		switch (atlasType) {
			case 'sparrow':
				sprite.frames = Paths.getSparrowAtlas(imagePath);
			case 'packer':
				sprite.frames = Paths.getPackerAtlas(imagePath);
			default:
				sprite.frames = Paths.getSparrowAtlas(imagePath);
		}

		if (sprite != null) {
			sprite.antialiasing = PlayerPrefs.antialiasing;
			PlayState.luaSprites.set(spriteID, sprite);
		}
	}

	public function addAnimByPrefix(spriteID:String, anim:String, prefix:String, fps:Int = 24, loop:Bool = false) {
		var sprite:FlxSprite = null;
		if (!PlayState.luaSprites.exists(spriteID))
			return;

		sprite = PlayState.luaSprites.get(spriteID);

		if (sprite != null) {
			sprite.animation.addByPrefix(anim, prefix, fps, loop);
			if (sprite.animation.curAnim == null) {
				sprite.animation.play(anim, true);
			}
		} else{
			sprite = Reflect.getProperty(PlayState, spriteID);
			if (sprite != null) {
				sprite.animation.addByPrefix(anim, prefix, fps, loop);
				if (sprite.animation.curAnim == null) {
					sprite.animation.play(anim, true);
				}
			}
		}
	}

	public function addLuaSprite(name:String, front:Bool) {
		if (PlayState.luaSprites.exists(name)) {
			var luaSprite:LuaSprite = PlayState.luaSprites.get(name);
			if (luaSprite != null) {
				if (front) {
					playstate.add(luaSprite);
					luaSprite.wasAdded = true;
				}
				else {
					var pos:Int = playstate.getBehindPos();
					playstate.insert(pos, luaSprite);
					luaSprite.wasAdded = true;
				}
			}

		}
	}
	
	public function removeLuaSprite(name:String, erase:Bool) {
		if (PlayState.luaSprites.exists(name)) {
			var luaSprite:LuaSprite = PlayState.luaSprites.get(name);

			if (erase) {
				luaSprite.kill();
				luaSprite.destroy();
				PlayState.luaSprites.remove(name);
			}

			if (luaSprite.wasAdded) {
				luaSprite.wasAdded = false;
				playstate.remove(luaSprite);
			}

		}
	}

	public function addAnimByIndices(name:String, anim:String, prefix:String, indices:String, fps:Int = 24, loop:Bool = false) {
		var indicesArray:Array<Int> = getIndicesFromString(indices);
		var sprite:LuaSprite = null;
		var flSprite:FlxSprite = null;

		if (PlayState.luaSprites.exists(name))
			sprite = PlayState.luaSprites.get(name);
		else
			flSprite = Reflect.getProperty(PlayState, name);

		if (sprite != null) {
			sprite.animation.addByIndices(anim, prefix, indicesArray, '', fps, loop);
			if(sprite.animation.curAnim == null) {
				sprite.animation.play(name, true);
			}
		} else if (flSprite != null) {
			flSprite.animation.addByIndices(anim, prefix, indicesArray, '', fps, loop);
			if(flSprite.animation.curAnim == null) {
				flSprite.animation.play(name, true);
			}
		}
	}

	public function getIndicesFromString(str:String):Array<Int> {
		str.replace('[', '');
		str.replace(']', '');

		var strArray:Array<String> = str.trim().split(',');
		var returnValue:Array<Int> = [];

		for (i in 0...strArray.length)
			returnValue.push(Std.parseInt(strArray[i]));

		return returnValue;
	}

	public function getSprite(name):Dynamic {
		if (PlayState.luaSprites.exists(name)) return PlayState.luaSprites.get(name);
		if (Std.isOfType(Reflect.getProperty(PlayState, name), FlxSprite) || Std.isOfType(Reflect.getProperty(PlayState, name), LuaSprite))
			return Reflect.getProperty(PlayState, name);

		return null;
	}

	public function getShaderObject(name:String):Dynamic {
		if (PlayState.playStatecams.exists(name)) return PlayState.playStatecams.get(name);
		if (PlayState.luaSprites.exists(name)) return PlayState.luaSprites.get(name);
		if (Std.isOfType(Reflect.getProperty(PlayState, name), LuaSprite) || Std.isOfType(Reflect.getProperty(PlayState, name), FlxSprite) || Std.isOfType(Reflect.getProperty(PlayState, name), FlxCamera))
			return Reflect.getProperty(PlayState, name);

		return null;
	}

	public function setObjectScale(name:String, xScale:Float, yScale:Float) {
		var obj:Dynamic = getSprite(name);
		var sprite:FlxSprite = obj;

		if (sprite != null)
			sprite.scale.set(xScale, yScale);
	}

	public function tweenX(id:String, obj:String, value:Dynamic, duration:Float, ease:String) {
		resetTween(id);
		var objectToTween:Dynamic = getSprite(id);

		if (objectToTween != null) {
			var tween:FlxTween = FlxTween.tween(objectToTween, {x: value}, duration, {
				ease: easeFromString(ease),
				onComplete: function(twn:FlxTween) {
					playstate.callLua('onTweenComplete', [id]);
					PlayState.luaTweens.remove(id);
				} 
			});

			PlayState.luaTweens.set(id, tween);
		}
	}
	
	public function tweenY(id:String, obj:String, value:Dynamic, duration:Float, ease:String) { //Just Copy and Pasted lol
		resetTween(id);
		var objectToTween:Dynamic = getSprite(id);

		if (objectToTween != null) {
			var tween:FlxTween = FlxTween.tween(objectToTween, {y: value}, duration, {
				ease: easeFromString(ease),
				onComplete: function(twn:FlxTween) {
					playstate.callLua('onTweenComplete', [id]);
					PlayState.luaTweens.remove(id);
				} 
			});

			PlayState.luaTweens.set(id, tween);
		}
	}
	
	public function tweenAngle(id:String, obj:String, value:Dynamic, duration:Float, ease:String) { //Just Copy and Pasted lol
		resetTween(id);
		var objectToTween:Dynamic = getSprite(id);

		if (objectToTween != null) {
			var tween:FlxTween = FlxTween.tween(objectToTween, {angle: value}, duration, {
				ease: easeFromString(ease),
				onComplete: function(twn:FlxTween) {
					playstate.callLua('onTweenComplete', [id]);
					PlayState.luaTweens.remove(id);
				} 
			});

			PlayState.luaTweens.set(id, tween);
		}
	}
	
	public function tweenAlpha(id:String, obj:String, value:Dynamic, duration:Float, ease:String) { //Just Copy and Pasted lol
		resetTween(id);
		var objectToTween:Dynamic = getSprite(id);

		if (objectToTween != null) {
			var tween:FlxTween = FlxTween.tween(objectToTween, {alpha: value}, duration, {
				ease: easeFromString(ease),
				onComplete: function(twn:FlxTween) {
					playstate.callLua('onTweenComplete', [id]);
					PlayState.luaTweens.remove(id);
				} 
			});

			PlayState.luaTweens.set(id, tween);
		}
	}
	
	public function tweenColor(id:String, obj:String, colorShit:String, duration:Float, ease:String) {
		resetTween(id);
		var objectToTween:Dynamic = getSprite(id);

		if (objectToTween != null) {
			var color:Int = colorFromString(colorShit);
			var currentColor:FlxColor = objectToTween.color;
			currentColor.alphaFloat = objectToTween.alpha;

			var tween:FlxTween = FlxTween.color(objectToTween, duration, currentColor, color, {
				ease: easeFromString(ease),
				onComplete: function(twn:FlxTween) {
					playstate.callLua('onTweenComplete', [id]);
					PlayState.luaTweens.remove(id);
				} 
			});

			PlayState.luaTweens.set(id, tween);
		}
	}

	public function resetTween(name:String) {
		if (PlayState.luaTweens.exists(name)) {
			var tween = PlayState.luaTweens.get(name);
			tween.cancel();
			tween.destroy();
			PlayState.luaTweens.remove(name);
		}
	}	

	public function colorFromString(str:String):Int {
		var returnColor:Int = Std.parseInt(str);
		if (!str.startsWith('0x'))
			returnColor = Std.parseInt('0xff' + str);

		if (Math.isNaN(returnColor))
			returnColor = FlxColor.fromString(str);

		return returnColor;
	}

	public function getStrumNote(strumlane:Int = 0, strumID:Int = 0):StaticArrow {
		if (strumID > 3)
			strumID = 3;

		if (strumlane > playstate.numbOfStrums - 1)
			strumlane = playstate.numbOfStrums - 1;

		if (PlayState.strumLines.members[strumlane] != null && PlayState.strumLines.members[strumlane].strums.members[strumID] != null)
			return PlayState.strumLines.members[strumlane].strums.members[strumID];

		return null;
	}

	public function getPropertyFromTypedGroup(groupObject:Dynamic, variable:String = null) {
		if (groupObject == null || variable == null)
			return null;

		var object:Dynamic = groupObject;

		var varArray:Array<String> = variable.split('.');
		if (varArray.length > 1) {
			for (i in 1...varArray.length - 1)
				object = Reflect.getProperty(object, varArray[i]);

			return Reflect.getProperty(object, varArray[varArray.length - 1]);
		}

		return object.getProperty(object, variable);
	}

	public function setPropertyFromTypedGroup(groupObject:Dynamic, variable:String = null, value:Dynamic) {
		if (groupObject == null || variable == null)
			return null;

		var object:Dynamic = groupObject;

		var varArray:Array<String> = variable.split('.');
		if (varArray.length > 1) {
			for (i in 1...varArray.length - 1)
				object = Reflect.getProperty(object, varArray[i]);

			return Reflect.setProperty(object, varArray[varArray.length - 1], value);
		}

		return Reflect.setProperty(object, variable, value);
	}

	public function getShader(object:String):FlxRuntimeShader {
		#if sys
		var spriteObj:Dynamic = getShaderObject(object);

		if (spriteObj != null) {
			var spriteShader:Dynamic = null;

			if (Std.isOfType(spriteObj, FlxCamera) && PlayState.cameraShaders.exists(object)) {
				spriteShader = PlayState.cameraShaders.get(object);
			}
			else {
				spriteShader = spriteObj.shader;
			}
			var shader:FlxRuntimeShader = spriteShader;
			return shader;
		}
		#end

		return null;
	}

	public function getObject(name:String):Dynamic {
		if (PlayState.luaSprites.exists(name)) return PlayState.luaSprites.get(name);
		if (Reflect.getProperty(playstate, name) != null) return Reflect.getProperty(playstate, name);
		if (Reflect.getProperty(PlayState, name) != null) return Reflect.getProperty(PlayState, name);

		return null;
	}

	public function getLuaCamera(name:String):Dynamic {
		if (PlayState.luaCameras.exists(name)) return PlayState.luaCameras.get(name);
		if (Std.isOfType(Reflect.getProperty(playstate, name), FlxCamera) || Std.isOfType(Reflect.getProperty(playstate, name), LuaCamera))
			return Reflect.getProperty(playstate, name);

		return null;
	}

	public function easeFromString(ease:String) {
		switch(ease.toLowerCase().trim()) {
			case 'backin': return FlxEase.backIn;
			case 'backinout': return FlxEase.backInOut;
			case 'backout': return FlxEase.backOut;
			case 'bouncein': return FlxEase.bounceIn;
			case 'bounceinout': return FlxEase.bounceInOut;
			case 'bounceout': return FlxEase.bounceOut;
			case 'circin': return FlxEase.circIn;
			case 'circinout': return FlxEase.circInOut;
			case 'circout': return FlxEase.circOut;
			case 'cubein': return FlxEase.cubeIn;
			case 'cubeinout': return FlxEase.cubeInOut;
			case 'cubeout': return FlxEase.cubeOut;
			case 'elasticin': return FlxEase.elasticIn;
			case 'elasticinout': return FlxEase.elasticInOut;
			case 'elasticout': return FlxEase.elasticOut;
			case 'expoin': return FlxEase.expoIn;
			case 'expoinout': return FlxEase.expoInOut;
			case 'expoout': return FlxEase.expoOut;
			case 'quadin': return FlxEase.quadIn;
			case 'quadinout': return FlxEase.quadInOut;
			case 'quadout': return FlxEase.quadOut;
			case 'quartin': return FlxEase.quartIn;
			case 'quartinout': return FlxEase.quartInOut;
			case 'quartout': return FlxEase.quartOut;
			case 'quintin': return FlxEase.quintIn;
			case 'quintinout': return FlxEase.quintInOut;
			case 'quintout': return FlxEase.quintOut;
			case 'sinein': return FlxEase.sineIn;
			case 'sineinout': return FlxEase.sineInOut;
			case 'sineout': return FlxEase.sineOut;
			case 'smoothstepin': return FlxEase.smoothStepIn;
			case 'smoothstepinout': return FlxEase.smoothStepInOut;
			case 'smoothstepout': return FlxEase.smoothStepInOut;
			case 'smootherstepin': return FlxEase.smootherStepIn;
			case 'smootherstepinout': return FlxEase.smootherStepInOut;
			case 'smootherstepout': return FlxEase.smootherStepOut;
		}
		return FlxEase.linear;
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

	public function close() {
		#if ALLOW_LUA
		if (lua == null)
			return;

		Lua.close(lua);
		lua = null;
		isClosed = true;
		#end
	}
}

class LuaSprite extends FlxSprite
{
	public var animOffsets:Map<String, Dynamic>;
	public var wasAdded:Bool = false;

	public function new(x:Float, y:Float) {
		animOffsets = new Map<String, Dynamic>();

		super(x, y);
	}

	public function addOffset(name:String, x:Float, y:Float)
		animOffsets[name] = [x, y];

	public function playAnim(animName:String, forced:Bool = false, reversed:Bool = false, framerate:Int = 24) {
		if (animation.getByName(animName) != null) {
			var offsets:Array<Float> = animOffsets.get(animName);

			animation.play(animName, forced, reversed, framerate);

			if (animOffsets.exists(animName))
				offset.set(offsets[0], offsets[1]);
			else
				offset.set(0, 0);
		}
	}
}

class LuaCamera extends FlxCamera
{
	public var id:String = 'default ID';
	public var cameraShaders:Array<BitmapFilter> = [];

	public function new(id:String, x:Int, y:Int, width:Int, height:Int, zoom:Float) {
		super(x, y, width, height, zoom);

		if (id != null) this.id = id;
	}

	public function pushShader(shader:Shader) { //Class made only for shaders lol
		var cameraFilter:ShaderFilter = new ShaderFilter(shader);
		cameraShaders.push(cameraFilter);
		setFilters(cameraShaders);
	}
}

class LuaCharacter extends Character {
	public var isAdded:Bool = false; //Unsed for now
}