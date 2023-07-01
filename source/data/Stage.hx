package data;

#if desktop
import sys.io.File;
import sys.FileSystem;
#end
import openfl.utils.Assets;
import haxe.Json;
import haxe.format.JsonParser;

using StringTools;

typedef StageData =
{
	var boyfriendPos:Array<Float>;
	var dadPos:Array<Float>;
	var gfPos:Array<Float>;
	var camZoom:Float;
	var directory:String;
	var ratingFolder:String;
	var hidegf:Bool;
}

class Stage 
{
	public static var directory:String = 'tutorial';

	public var boyfriendPos:Array<Float>;
	public var dadPos:Array<Float>;
	public var gfPos:Array<Float>;
	public var camZoom:Float;

	public static function loadData(curStage:String = 'stage'):StageData
	{
		var jsonData = null;

		#if sys
		if (FileSystem.exists(Paths.mods('stages/$curStage.json'))) {
			jsonData = Json.parse(File.getContent(Paths.mods('stages/$curStage.json')));
		}
		else #end if (Assets.exists(Paths.getPreloadPath('stages/$curStage.json'))) {
			jsonData = Json.parse(Assets.getText(Paths.getPreloadPath('stages/$curStage.json')));
		}

		if (jsonData == null) {
			jsonData = loadDefaultData(jsonData);
			trace('Stage Error! Loaded default json');
		}

		return jsonData;
	}

	public static function loadDefaultData(jsonData = null):Any
	{
		jsonData = {
			"boyfriendPos": [770.0, 450.0],
			"dadPos": [100.0, 100.0],
			"gfPos": [400.0, 130.0],
			"camZoom": 1.0,
			"directory": "tutorial",
			"ratingFolder": "default",
			"hidegf": false
		};

		return jsonData;
	}

}
