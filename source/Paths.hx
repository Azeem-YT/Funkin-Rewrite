package;

import flixel.FlxG;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import lime.utils.Assets;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import flash.media.Sound;
import data.*;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

using StringTools;

class Paths
{
	public static var modInst:Map<String, Sound> = new Map<String, Sound>();
	public static var modVoices:Map<String, Sound> = new Map<String, Sound>();
	public static var loadedSounds:Map<String, Sound> = new Map<String, Sound>();
	public static var cachedTexts:Map<String, String> = new Map<String, String>();
	public static var moddedGraphicsLoaded:Map<String, Bool> = new Map<String, Bool>();
	public static var graphicsLoaded:Map<String, Bool> = new Map<String, Bool>();
	public static var currentSongDir:String = 'assets/songs/tutorial';
	public static var currentLevel:String = '';
	public static var SOUND_EXT:String = #if web 'mp3' #else 'ogg'#end;

	#if sys
	public static var ignoredFolders:Array<String> = [
		'hscript',
		'characters',
		'data', 
		'images', 
		'music', 
		'note_types',
		'scripts', 
		'songs',
		'sounds', 
		'weeks'
	];
	#end

	public static function setCurrentLevel(level:String){
		currentLevel = level;
	}

	inline static public function getAssetDirectory(key:String, ?library:String = '', ?type:AssetType = IMAGE) {

		if (library != null && library.length > 1)
			return getLibraryPath(key, library);

		var levelPath = getLibraryPath(key, "shared");
		if (OpenFlAssets.exists(levelPath, type))
				return levelPath;

		if (Assets.exists(getLibraryPath(key, 'shared')))
			return getLibraryPath(key, 'shared');

		return getPreloadPath(key);
	}

	inline static public function getLibraryPath(key:String, library:String)
		return '$library:assets/$library/$key';

	inline static public function getPreloadPath(key:String = null)
		return ((key == null) ? 'assets/' : 'assets/$key');

	inline static public function file(file:String, ?library:String, ?type:AssetType = IMAGE) {
		#if sys
		if (FileSystem.exists(mods(file)))
			return mods(file);
		#end

		return getAssetDirectory(file, library, type);
	}

	inline static public function txt(key:String, ?library:String, ?cacheText:Bool = false) {
		var path:String = getAssetDirectory('$key.txt', library, TEXT);

		#if sys
		if (FileSystem.exists(mods('$key.txt')))
			return mods('key.txt');
		#end

		if (cachedTexts.exists(path) && cacheText)
			return cachedTexts.get(path);

		if (Assets.exists(path) && !cachedTexts.exists(path) && cacheText)
			cachedTexts.set(path, Assets.getText(path));

		return path;
	}

	inline static public function xml(key:String, ?library:String, ?cacheText:Bool = false) {
		var path:String = getAssetDirectory('$key.xml', library, TEXT);

		#if sys
		if (FileSystem.exists(mods('$key.xml')))
			return mods('key.xml');
		#end

		if (cachedTexts.exists(path) && cacheText)
			return cachedTexts.get(path);

		if (Assets.exists(path) && !cachedTexts.exists(path) && cacheText)
			cachedTexts.set(path, Assets.getText(path));

		return path;
	}

	inline static public function lua(key:String, ?library:String) {
		#if sys
		if (FileSystem.exists(mods('$key.lua')))
			return mods('$key.lua');
		#end

		return getAssetDirectory('$key.lua', library, TEXT);
	}

	inline static public function json(key:String, ?library:String, ?cacheText:Bool = false) {
		var path:String = getAssetDirectory('$key.json', library, TEXT);

		#if sys
		if (FileSystem.exists(mods('$key.json')))
			return mods('$key.json');
		#end

		if (cachedTexts.exists(path) && cacheText)
			return cachedTexts.get(path);

		if (Assets.exists(path) && !cachedTexts.exists(path) && cacheText)
			cachedTexts.set(path, Assets.getText(path));

		return path;
	}

	inline static public function image(key:String, ?library:String = '', ?graphicOnAsset:Bool = false):Any {
		var graphicImage:FlxGraphic = getImage(key, library, graphicOnAsset);

		if (graphicImage != null)
			return graphicImage;

		return imagePth(key, library);
	}

	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String = ''):Any
		return sound(Std.string(key + FlxG.random.int(min, max)), library);

	inline static public function imagePth(key:String, ?library:String = '')
		return getAssetDirectory('images/$key.png', library, TEXT);

	inline static public function sound(key:String, ?library:String = ''):Any {
		var soundFile:Sound = null;
		#if sys
		if (FileSystem.exists(modSounds(key))) {
			if (!loadedSounds.exists(key))
				loadedSounds.set(key, Sound.fromFile(modSounds(key)));

			soundFile = loadedSounds.get(key);
		}
		#end

		if (soundFile != null)
			return soundFile;

		return soundAsset(key, library);
	}

	inline static public function music(key:String, ?library:String = ''):Any {
		var soundFile:Sound = null;

		#if sys
		if (FileSystem.exists(modMusic(key))) {
			if (!loadedSounds.exists(key))
				loadedSounds.set(key, Sound.fromFile(modSounds(key)));

			soundFile = loadedSounds.get(key);
		}
		#end

		if (soundFile != null)
			return soundFile;

		return getAssetDirectory('music/$key.$SOUND_EXT', library, SOUND);
	}

	inline static public function soundAsset(key:String, ?library:String = null)
		return getAssetDirectory('sounds/$key.$SOUND_EXT', library);

	inline static public function characterFile(char:String, ?isPlayer:Bool = false) {
		#if sys
		if (isPlayer && FileSystem.exists(modJson('characters/$char-player')))
			return modJson('characters/$char-player');

		if (FileSystem.exists(modJson('characters/$char')))
			return modJson('characters/$char');
		#end

		if (isPlayer && Assets.exists(getAssetDirectory('characters/$char-player.json')))
			return getAssetDirectory('characters/$char-player.json');

		return getAssetDirectory('characters/$char.json');
	}

	inline static public function inst(song:String):Any {
		song = song.toLowerCase();

		var songFile:Sound = null;
		#if sys
		if (FileSystem.exists(modinst(song))) {
			if (!modInst.exists(song))
				modInst.set(song, Sound.fromFile(modinst(song)));

			songFile = modInst.get(song);
		}
		#end

		if (songFile != null)
			return songFile;

		return 'songs:assets/songs/$song/Inst.$SOUND_EXT';
	}

	inline static public function voices(song:String):Any {
		song = song.toLowerCase();

		var songFile:Sound = null;

		#if sys
		if (FileSystem.exists(modvoices(song))) {
			if (!modVoices.exists(song))
				modVoices.set(song, Sound.fromFile(modvoices(song)));

			songFile = modVoices.get(song);
		}
		#end

		if (songFile != null)
			return songFile;

		return 'songs:assets/songs/$song/Voices.$SOUND_EXT';
	}

	inline static public function font(key:String)
	{
		#if sys
		if (FileSystem.exists(modFonts(key)))
			return modFonts(key);
		#end

		return getAssetDirectory('fonts/$key');
	}

	inline static public function getPackerAtlas(key:String, ?library:String)
		return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library), packerTxt(key, library));

	inline static public function getSparrowAtlas(key:String, ?library:String = '')
		return FlxAtlasFrames.fromSparrow(image(key, library), sparrowXml(key, library));

	inline static public function packerTxt(key:String, ?library:String = ''):Any {
		#if sys
		if (FileSystem.exists(modTxt('images/$key')))
			return File.getContent(modTxt('images/$key'));
		#end

		if (Assets.exists(getAssetDirectory('images/$key.txt', library)))
			return Assets.getText(getAssetDirectory('images/$key.txt', library));

		return getAssetDirectory('images/$key.txt', library);
	}

	inline static public function getContent(path:String) {
		#if sys
		if (FileSystem.exists(path) && isModPath(path))
			return File.getContent(path);
		#end

		if (Assets.exists(path))
			return Assets.getText(path);

		return null;
	}

	inline static public function sparrowXml(key:String, ?library:String = ''):Any {
		var assetPath:String = getAssetDirectory('images/$key.xml', library);

		#if sys
		if (FileSystem.exists(modXml('images/$key')))
			return File.getContent(modXml('images/$key'));
		#end

		if (Assets.exists(assetPath))
			return Assets.getText(assetPath);

		return assetPath;
	}

	inline static public function hscript(key:String, ?library:String) {	
		#if sys
		if (FileSystem.exists(mods('$key.hx')))
			return mods('$key.hx');
		#end

		return getAssetDirectory('$key.hx', library);
	}

	inline static public function stateDirectory(stateName:String) {
		return mods('states/$stateName/$stateName.hx');
	}

	inline static public function getImage(key:String, ?library:String = '', ?graphicOnAsset:Bool = false):FlxGraphic
	{
		var graphic:FlxGraphic = null;

		#if sys
		if (FileSystem.exists(modImages(key)))
		{
			if (!moddedGraphicsLoaded.exists(key)) {
				var bitmap:BitmapData = BitmapData.fromFile(modImages(key));
				var graphic:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, key);
				graphic.persist = true;
				FlxG.bitmap.addGraphic(graphic);
				graphicsLoaded.set(key, true);
			}

			if (FlxG.bitmap.get(key) != null) {
				graphic = FlxG.bitmap.get(key);
			}
		}
		#end
		
		if ((Assets.exists(imagePth(key, library)) && graphic == null) && graphicOnAsset) {
			if (!graphicsLoaded.exists(key)) {
				var bitmap:BitmapData = BitmapData.fromFile(imagePth(key, library));
				var graphic:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, key);
				graphic.persist = true;
				FlxG.bitmap.addGraphic(graphic);
				graphicsLoaded.set(key, true);
			}

			if (FlxG.bitmap.get(key) != null) {
				graphic = FlxG.bitmap.get(key);
			}
		}

		return graphic;
	}

	inline static public function destroyImages() {
		if (!PlayerPrefs.persistentCache) {
			for (image in moddedGraphicsLoaded.keys()) {
				var graphic:FlxGraphic = FlxG.bitmap.get(image);
				if (graphic != null) {
					FlxG.bitmap.removeByKey(image);
					graphic.bitmap.dispose();
					graphic.destroy();
				}
			}

			for (image in graphicsLoaded.keys()) {
				var graphic:FlxGraphic = FlxG.bitmap.get(image);
				if (graphic != null) {
					FlxG.bitmap.removeByKey(image);
					graphic.bitmap.dispose();
					graphic.destroy();
				}
			}

			moddedGraphicsLoaded.clear();
			graphicsLoaded.clear();
		}
	}

	inline static public function video(key:String, ?exten:String = 'mp4') {
		#if sys
		if (FileSystem.exists(modVideos(key, exten)))
			return modVideos('videos/$key.$exten');
		#end

		return getAssetDirectory('videos/$key.$exten');
	}

	#if sys
	inline static public function mods(key:String = '')
		return ((key == null || key == '') ? 'mods/' : 'mods/$key');

	inline static public function modSounds(key:String)
		return mods('sounds/$key.$SOUND_EXT');

	inline static public function modMusic(key:String)
		return mods('music/$key.$SOUND_EXT');

	inline static public function modImages(key:String)
		return mods('images/$key.png');

	inline static public function modFonts(key:String)
		return mods('fonts/$key');

	inline static public function modvoices(song:String)
		return mods('songs/${song.toLowerCase()}/Voices.$SOUND_EXT');

	inline static public function modinst(song:String)
		return mods('songs/${song.toLowerCase()}/Inst.$SOUND_EXT');

	inline static public function modVideos(vid:String, ?exten:String = 'mp4')
		return mods('videos/$vid.$exten');

	inline static public function modXml(key:String)
		return mods('$key.xml');

	inline static public function modTxt(key:String)
		return mods('$key.txt');

	inline static public function modJson(key:String)
		return mods('$key.xml');

	inline static public function isModPath(path:String):Bool
		return path.startsWith('mods/');

	#end
}