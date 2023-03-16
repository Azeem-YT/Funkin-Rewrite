package data;

import data.Section.SwagSection;
import haxe.Json;
import haxe.format.JsonParser;
import lime.utils.Assets;
import mappedEvents.Event;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

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

	public static var currentDirectory:String = 'assets/data/tutorial/';

	public function new(song, notes, bpm)
	{
		this.song = song;
		this.notes = notes;
		this.bpm = bpm;
	}

	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
	{
		var rawJson:String = null;
		
		var pathDirectory = Paths.json('data/' + folder.toLowerCase() + '/' + jsonInput.toLowerCase());
		rawJson = Paths.getContent(pathDirectory);

		while (!rawJson.endsWith("}") && rawJson != null) {
			rawJson = rawJson.substr(0, rawJson.length - 1);
		}

		if (rawJson != null)
			return parseJSONshit(rawJson);

		return null;
	}

	public function loadEvents(folder:String):EventData {
		var rawJson:String = null;

		rawJson = Paths.getContent(Paths.json('data/' + folder.toLowerCase() + '/events'));

		while (!rawJson.endsWith("}") && rawJson != null) {
			rawJson = rawJson.substr(0, rawJson.length - 1);
		}

		if (rawJson != null)
			return cast Json.parse(rawJson);

		return null;
	}

	public static function parseJSONshit(rawJson:String):SwagSong
	{
		var swagShit:SwagSong = cast Json.parse(rawJson).song;
		swagShit.validScore = true;
		return swagShit;
	}
}
