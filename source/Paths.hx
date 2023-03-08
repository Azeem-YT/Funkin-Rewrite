package;

import flixel.FlxG;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import lime.utils.Assets;
import flixel.FlxSprite;
import sys.io.File;
import sys.FileSystem;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import flash.media.Sound;
import data.*;

class Paths
{
	public static var modInst:Map<String, Sound> = new Map<String, Sound>();
	public static var modVoices:Map<String, Sound> = new Map<String, Sound>();
	public static var loadedSounds:Map<String, Sound> = new Map<String, Sound>();
	public static var currentSongDir:String = 'assets/songs/tutorial';
	public static var moddedGraphicsLoaded:Map<String, Bool> = new Map<String, Bool>();
	public static var graphicIsLoaded:Map<String, Bool> = new Map<String, Bool>();

	inline static public function getAssetDirectory(key:String, ?library:String = '') {

		if (library != null)
			return getLibraryPath(key, library);

		return getPreloadPath(key);
	}

	inline static public function getLibraryPath(key:String, library:String)
		return 'assets/$library/$key';

	inline static public function getPreloadPath(key:String)
		return (key != null ? 'assets/' : 'assets/$key');

	inline static public function file(file:String, ?library:String) {
		if (FileSystem.exists(file))
			return mods(file);

		return getAssetDirectory(file, library);
	}

	inline static public function txt(key:String, ?library:String) {
		if (FileSystem.exists(mods('$key.txt')))
			return mods('key.txt');

		return getAssetDirectory('$key.txt', library);
	}

	inline static public function xml(key:String, ?library:String) {
		if (FileSystem.exists(mods('$key.xml')))
			return mods('key.xml');
		
		return getAssetDirectory('$key.xml', library);
	}

	inline static public function lua(key:String, ?library:String) {
		if (FileSystem.exists(mods('$key.lua')))
			return mods('$key.lua');

		return getAssetDirectory('$key.lua', library);
	}

	inline static public function json(key:String, ?library:String) {
		if (FileSystem.exists(mods('$key.json')))
			return mods('$key.json');

		return getAssetDirectory('$key.json', library);
	}

	inline static public function image(key:String, ?library:String = '') {
		var graphicImage:FlxGraphic = getImage(key, library);

		if (graphicImage != null)
			return graphicImage;

		return imagePth(key, library);
	}

	inline static public function randomSound(key:String, min:Int, max:Int, ?library:String = '') {
		var soundKey:String = key + FlxG.random.int(min, max);

		var soundFile:Sound = null;

		if (FileSystem.exists(soundKey))
		{
			if (!loadedSounds.exists(soundKey))
				loadedSounds.set(soundKey, Sound.fromFile(soundKey));

			soundFile = loadedSounds.get(soundKey);
		}

		if (soundFile != null)
			return soundFile;

		return sound(soundKey, library);
	}

	inline static public function imagePth(key:String, ?library:String = '')
		return getAssetDirectory('images/$key.png', library);

	inline static public function sound(key:String, ?library:String = '') {
		var soundFile:Sound = null;

		if (FileSystem.exists(modSounds)) {
			if (!loadedSounds.exists(key))
				loadedSounds.set(key, Sound.fromFile(modSounds(key)));

			soundFile = loadedSounds.get(key);
		}

		if (soundFile != null)
			return soundFile;

		return soundAsset(key, library);
	}

	inline static public function music(key:String, ?library:String = '') {
		var soundFile:Sound = null;

		if (FileSystem.exists(modMusic)) {
			if (!loadedSounds.exists(key))
				loadedSounds.set(key, Sound.fromFile(modSounds(key)));

			soundFile = loadedSounds.get(key);
		}

		if (soundFile != null)
			return soundFile;

		return getAssetDirectory('music/$key.ogg', library);
	}

	inline static public function soundAsset(key:String, ?library)
		return getAssetDirectory('sounds/$key.ogg', library);

	inline static public function characterFile(char:String, ?isPlayer:Bool = false) {
		if (isPlayer && FileSystem.exists(mods('characters/$char-player.json')))
			return mods('characters/$char-player.json');

		if (FileSystem.exists(mods('characters/$char.json')))
			return mods('characters/$char.json');

		if (isPlayer && Assets.exists(getAssetDirectory('characters/$char-player.json')))
			return getAssetDirectory('characters/$char-player.json');

		return getAssetDirectory('characters/$char.json');
	}

	inline static public function inst(song:String):Any {
		song = song.toLowerCase();

		var songFile:Sound = null;

		if (FileSystem.exists(modinst(song)))
		{
			if (!modInst.exists(song))
				modInst.set(song, Sound.fromFile(modinst(song)));

			songFile = modInst.get(song);
		}

		if (songFile != null)
			return songFile;

		return getAssetDirectory('songs/$song/Inst.ogg');
	}

	inline static public function voices(song:String):Any {
		song = song.toLowerCase();

		var songFile:Sound = null;

		if (FileSystem.exists(modvoices(song)))
		{
			if (!modVoices.exists(song))
				modVoices.set(song, Sound.fromFile(modvoices(song)));

			songFile = modVoices.get(song);
		}

		if (songFile != null)
			return songFile;

		return getAssetDirectory('songs/$song/Inst.ogg');
	}

	inline static public function font(key:String)
	{
		if (FileSystem.exists(modFonts('$key')))
			return modFonts('$key');
		else
			getAssetDirectory('$key');
	}

	inline static public function getPackerAtlas(key:String, ?library:String = '')
		return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library), packerTxt(key, library'));

	inline static public function getSparrowAtlas(key:String, ?library:String = '')
		return FlxAtlasFrames.fromSparrow(image(key, library), sparrowXml('images/$key.xml', library));

	inline static public function packerTxt(key:String, ?library:String = ''):Any {
		if (FileSystem.exists(mods('images/$key.txt')))
			return File.getContent(mods('images/$key.txt'));

		if (Assets.exists(getAssetDirectory('images/$key.txt', library))
			return Assets.getText(getAssetDirectory('images/$key.txt', library));

		return getAssetDirectory('images/$key.txt', library);
	}

	inline static public function sparrowXml(key:String, ?library:String = ''):Any {
		var assetPath:String = getAssetDirectory('images/$key.xml', library);

		if (FileSystem.exists(mods('images/$key.xml')))
			return File.getContent('images/$key.xml');

		if (Assets.exists(assetPath))
			return Assets.getText(assetPath);

		return assetPath;
	}

	inline static public function getImage(key:String, ?library:String = ''):FlxGraphic
	{
		if (FileSystem.exists(modImages(key)))
		{
			if (!graphicIsLoaded.exists(key))
			{
				var bitmap:BitmapData = BitmapData.fromFile(modImages(key));
				var graphic:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, key);
				graphic.persist = true;
				FlxG.bitmap.addGraphic(graphic);
				graphicIsLoaded.set(key, true);
			}

			return FlxG.bitmap.get(key);
		}
		else if (Assets.exists(imagePth(key, library))) {
			if (!graphicIsLoaded.exists(key)) {
				var bitmap:BitmapData = BitmapData.fromFile(imagePth(key, library));
				var graphic:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, key);
				graphic.persist = true;
				FlxG.bitmap.addGraphic(graphic);
				graphicIsLoaded.set(key, true);
			}

			return FlxG.bitmap.get(key);
		}

		return null;
	}

	inline static public function destroyImages() {
		if (!GameChanges.persistentCache) {
			for (image in moddedGraphicsLoaded.keys()) {
				var graphic:FlxGraphic = FlxG.bitmap.get(image);
				if (graphic != null) {
					FlxG.bitmap.removeByKey(image);
					graphic.bitmap.dispose();
					graphic.destroy();
				}
			}

			for (image in graphicIsLoaded.keys()) {
				var graphic:FlxGraphic = FlxG.bitmap.get(image);
				if (graphic != null) {
					FlxG.bitmap.removeByKey(image);
					graphic.bitmap.dispose();
					graphic.destroy();
				}
			}

			moddedGraphicsLoaded.clear();
			graphicIsLoaded.clear();
		}
	}

	inline static public function mods(key:String = '')
		return 'mods/$key';

	inline static public function modSounds(key:String)
		return mods('sounds/$key.ogg');

	inline static public function modMusic(key:String)
		return mods('music/$key.ogg');

	inline static public function hscript(key:String, ?library:String) {		
		if (FileSystem.exists(mods('$key.hxs')))
			return mods('$key.hxs');

		return getAssetDirectory('$key.hxs', library);
	}
}