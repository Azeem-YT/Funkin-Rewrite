package timeEvents;

import flixel.FlxG;

using StringTools;

typedef EventData = {
	var events:Array<Dynamic>;
}

class Event
{
	public var time:Float;
	public var eventName:String;
	public var value1:String;
	public var value2:String;

	public function new(songTime:Float, event:String, val1:String = '', val2:String = '') {
		time = songTime;
		eventName = event;
		value1 = val1;
		value2 = val2;
	}
}
