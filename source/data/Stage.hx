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

		var stagePath:String = 'stages/$curStage/$curStage.json';
		var stagePathAlt:String = 'stages/$curStage.json';

		jsonData = getStageData(curStage, [stagePath, stagePathAlt]);

		if (jsonData == null) {
			jsonData = loadDefaultData(jsonData);
			trace('Stage Error!');
		}

		return jsonData;
	}

	public static function loadDefaultData(jsonData = null):StageData
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

		trace("Loading default stage data.");

		return jsonData;
	}


	public static function getStageData(stage:String, dirs:Array<String>):StageData {
		if (dirs.length < 1) dirs.push('stages/$stage/$stage.json');

		for (path in dirs) {
			#if sys
			var modPth:String = Paths.mods(path);
			if (!modPth.endsWith('.json')) modPth += '.json';
			if (FileSystem.exists(modPth)) return Json.parse(File.getContent(modPth));
			#end

			var assPath:String = Paths.getPreloadPath(path);
			if (!assPath.endsWith('.json')) assPath += '.json';
			if (Assets.exists(modPth)) return Json.parse(Assets.getText(assPath));
		}

		return loadDefaultData();
	}
}
