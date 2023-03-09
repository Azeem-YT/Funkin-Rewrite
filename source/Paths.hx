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

	inline static public function getAssetDirectory(key:String, ?library:String = '', ?type:AssetType = IMAGE) {

		if (library != null && library.length > 1)
			return getLibraryPath(key, library);

		var levelPath = getLibraryPath(key, "shared");
		if (OpenFlAssets.exists(levelPath, type))
				return levelPath;

		if (Assets.exists(getLibraryPath(key, 'shared')) && (library != null && library.length > 0))
			return getLibraryPath(key, 'shared');

		return getPreloadPath(key);
	}

	inline static public function getLibraryPath(key:String, library:String)
		return '$library:assets/$library/$key';

	inline static public function getPreloadPath(key:String = null)
		return ((key == null) ? 'assets/' : 'assets/$key');

	inline static public function file(file:String, ?library:String, ?type:AssetType = IMAGE) {
		if (FileSystem.exists(file))
			return mods(file);

		return getAssetDirectory(file, library, type);
	}

	inline static public function txt(key:String, ?library:String) {
		if (FileSystem.exists(mods('$key.txt')))
			return mods('key.txt');

		return getAssetDirectory('$key.txt', library, TEXT);
	}

	inline static public function xml(key:String, ?library:String) {
		if (FileSystem.exists(mods('$key.xml')))
			return mods('key.xml');
		
		return getAssetDirectory('$key.xml', library, TEXT);
	}

	inline static public function lua(key:String, ?library:String) {
		if (FileSystem.exists(mods('$key.lua')))
			return mods('$key.lua');

		return getAssetDirectory('$key.lua', library, TEXT);
	}

	inline static public function json(key:String, ?library:String) {
		if (FileSystem.exists(mods('$key.json')))
			return mods('$key.json');

		return getAssetDirectory('$key.json', library, TEXT);
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

		if (FileSystem.exists(modSounds(key))) {
			if (!loadedSounds.exists(key))
				loadedSounds.set(key, Sound.fromFile(modSounds(key)));

			soundFile = loadedSounds.get(key);
		}

		if (soundFile != null)
			return soundFile;

		return soundAsset(key, library);
	}

	inline static public function music(key:String, ?library:String = ''):Any {
		var soundFile:Sound = null;

		if (FileSystem.exists(modMusic(key))) {
			if (!loadedSounds.exists(key))
				loadedSounds.set(key, Sound.fromFile(modSounds(key)));

			soundFile = loadedSounds.get(key);
		}

		if (soundFile != null)
			return soundFile;

		return getAssetDirectory('music/$key.ogg', library, SOUND);
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

		if (FileSystem.exists(modinst(song))) {
			if (!modInst.exists(song))
				modInst.set(song, Sound.fromFile(modinst(song)));

			songFile = modInst.get(song);
		}

		if (songFile != null)
			return songFile;

		return 'songs:assets/songs/$song/Inst.ogg';
	}

	inline static public function voices(song:String):Any {
		song = song.toLowerCase();

		var songFile:Sound = null;

		if (FileSystem.exists(modvoices(song))) {
			if (!modVoices.exists(song))
				modVoices.set(song, Sound.fromFile(modvoices(song)));

			songFile = modVoices.get(song);
		}

		if (songFile != null)
			return songFile;

		return 'songs:assets/songs/$song/Voices.ogg';
	}

	inline static public function font(key:String)
	{
		if (FileSystem.exists(modFonts('$key')))
			return modFonts('$key');

		return getAssetDirectory('$key');
	}

	inline static public function getPackerAtlas(key:String, ?library:String)
		return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library), packerTxt(key, library));

	inline static public function getSparrowAtlas(key:String, ?library:String = '')
		return FlxAtlasFrames.fromSparrow(image(key, library), sparrowXml(key, library));

	inline static public function packerTxt(key:String, ?library:String = ''):Any {
		if (FileSystem.exists(mods('images/$key.txt')))
			return File.getContent(mods('images/$key.txt'));

		if (Assets.exists(getAssetDirectory('images/$key.txt', library)))
			return Assets.getText(getAssetDirectory('images/$key.txt', library));

		return getAssetDirectory('images/$key.txt', library);
	}

	inline static public function getContent(path:String) {
		if (FileSystem.exists(path))
			return File.getContent(path);

		if (Assets.exists(path))
			return Assets.getText(path);

		return null;
	}

	inline static public function sparrowXml(key:String, ?library:String = ''):Any {
		var assetPath:String = getAssetDirectory('images/$key.xml', library);

		if (FileSystem.exists(mods('images/$key.xml')))
			return File.getContent('images/$key.xml');

		if (Assets.exists(assetPath))
			return Assets.getText(assetPath);

		return assetPath;
	}

	inline static public function getImage(key:String, ?library:String = '', ?graphicOnAsset:Bool = false):FlxGraphic
	{
		var graphic:FlxGraphic = null;

		if (FileSystem.exists(modImages(key)))
		{
			if (!moddedGraphicsLoaded.exists(key)) {
				var bitmap:BitmapData = BitmapData.fromFile(modImages(key));
				var graphic:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, key);
				graphic.persist = true;
				FlxG.bitmap.addGraphic(graphic);
				graphicIsLoaded.set(key, true);
			}

			if (FlxG.bitmap.get(key) != null) {
				graphic = FlxG.bitmap.get(key);
			}
		}
		
		if (Assets.exists(imagePth(key, library)) && graphic == null && graphicOnAsset) {
			if (!graphicIsLoaded.exists(key)) {
				var bitmap:BitmapData = BitmapData.fromFile(imagePth(key, library));
				var graphic:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, key);
				graphic.persist = true;
				FlxG.bitmap.addGraphic(graphic);
				graphicIsLoaded.set(key, true);
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

	inline static public function video(key:String, ?exten:String = 'mp4') {
		if (FileSystem.exists(mods('videos/$key.$exten')))
			return mods('videos/$key.$exten');

		return getAssetDirectory('videos/$key.$exten');
	}

	inline static public function mods(key:String = '')
		return (key != null ? 'mods/' : 'mods/$key');

	inline static public function modSounds(key:String)
		return mods('sounds/$key.ogg');

	inline static public function modMusic(key:String)
		return mods('music/$key.ogg');

	inline static public function modImages(key:String)
		return mods('images/$key.png');

	inline static public function modFonts(key:String)
		return mods(key);

	inline static public function modvoices(song:String)
		return mods('songs/${song.toLowerCase()}/Voices.ogg');

	inline static public function modinst(song:String)
		return mods('songs/${song.toLowerCase()}/Inst.ogg');

	inline static public function hscript(key:String, ?library:String) {		
		if (FileSystem.exists(mods('$key.hxs')))
			return mods('$key.hxs');

		return getAssetDirectory('$key.hxs', library);
	}
}