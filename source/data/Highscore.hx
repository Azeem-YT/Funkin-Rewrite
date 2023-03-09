package data;

import flixel.FlxG;

class Highscore
{
	#if (haxe >= "4.0.0")
	public static var songScores:Map<String, Int> = new Map();
	public static var weekScores:Map<String, Int> = new Map();
	public static var beatenSongs:Map<String, Bool> = new Map();
	#else
	public static var songScores:Map<String, Int> = new Map<String, Int>();
	public static var weekScores:Map<String, Int> = new Map<String, Int>();
	public static var beatenSongs:Map<String, Bool> = new Map<String, Bool>();
	#end


	public static function saveScore(song:String, score:Int = 0, ?diff:String = ''):Void
	{
		var daSong:String = formatSong(song, diff);

		if (songScores.exists(daSong))
		{
			if (songScores.get(daSong) < score)
				setScore(daSong, score);
		}
		else
			setWeekScore(daSong, score);
	}

	public static function saveWeekScore(weekName:String, score:Int = 0, ?diff:String = ''):Void
	{
		var daWeek:String = weekName;

		if (weekScores.exists(daWeek))
		{
			if (weekScores.get(daWeek) < score)
				setScore(daWeek, score);
		}
		else
			setScore(daWeek, score);
	}

	/**
	 * YOU SHOULD FORMAT SONG WITH formatSong() BEFORE TOSSING IN SONG VARIABLE
	 */
	static function setScore(song:String, score:Int):Void
	{
		// Reminder that I don't need to format this song, it should come formatted!
		songScores.set(song, score);
		FlxG.save.data.songScores = songScores;
		FlxG.save.flush();
	}

	public static function songBeat(song:String):Bool
	{
		song = song.toLowerCase();
		if (beatenSongs.exists(song))
			return true;
		else
			return false;
	}

	public static function saveSongBeat(song:String)
	{
		song = song.toLowerCase();
		beatenSongs.set(song, true);
		FlxG.save.data.beatenSongs = beatenSongs;
		FlxG.save.flush();
	}

	static function setWeekScore(week:String, score:Int):Void
	{
		weekScores.set(week, score);
		FlxG.save.data.weekScores = weekScores;
		FlxG.save.flush();
	}

	public static function formatSong(song:String, diff:String = ''):String
	{
		var daSong:String = song;

		daSong = daSong + diff;

		return daSong;
	}

	public static function getScore(song:String, diff:String = ''):Int
	{
		if (!songScores.exists(formatSong(song, diff)))
			setScore(formatSong(song, diff), 0);

		return songScores.get(formatSong(song, diff));
	}

	public static function getWeekScore(week:String, diff:String = ''):Int
	{
		if (!weekScores.exists(formatSong(week, diff)))
			setWeekScore(formatSong(week, diff), 0);

		return weekScores.get(formatSong(week, diff));
	}

	public static function load():Void
	{
		if (FlxG.save.data.songScores != null)
		{
			songScores = FlxG.save.data.songScores;
		}
		if (FlxG.save.data.weekScores != null)
		{
			weekScores = FlxG.save.data.weekScores;
		}

		if (FlxG.save.data.beatenSongs != null)
			beatenSongs = FlxG.save.data.beatenSongs;
	}
}
