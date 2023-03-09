package data;

import data.Section.SwagSection;
import haxe.Json;
import haxe.format.JsonParser;
import lime.utils.Assets;

import sys.io.File;
import sys.FileSystem;

using StringTools;

typedef SwagSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var bpm:Null<Int>;
	var needsVoices:Bool;
	var speed:Float;

	var player1:String;
	var player2:String;
	var gfVersion:String;
	var stage:String;
	var arrowTexture:String;
	var numbPlayers:Int;
	var threePlayer:Bool;
	var splashTexture:String;
	var validScore:Bool;
}

class Song
{
	public var song:String;
	public var notes:Array<SwagSection>;
	public var bpm:Int;
	public var needsVoices:Bool = true;
	public var speed:Float = 1;

	public var player1:String = 'bf';
	public var player2:String = 'dad';
	public var gfVersion:String = 'gf';

	public static var currentDirectory:String = 'assets/data/tutorial';

	public function new(song, notes, bpm)
	{
		this.song = song;
		this.notes = notes;
		this.bpm = bpm;
	}

	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
	{
		var rawJson:String = null;
		
		var currentDirectory = Paths.json('data/' + folder.toLowerCase() + '/' + jsonInput.toLowerCase());
		rawJson = Paths.getContent(currentDirectory);

		while (!rawJson.endsWith("}") && rawJson != null) {
			rawJson = rawJson.substr(0, rawJson.length - 1);
		}

		if (rawJson != null)
			return parseJSONshit(rawJson);

		return null;
	}

	public static function parseJSONshit(rawJson:String):SwagSong
	{
		var swagShit:SwagSong = cast Json.parse(rawJson).song;
		swagShit.validScore = true;
		if (swagShit.bpm == null) swagShit.bpm = 100;
		return swagShit;
	}
}
