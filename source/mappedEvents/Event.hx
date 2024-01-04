package mappedEvents;

import flixel.FlxG;

using StringTools;

typedef Events = {
	var time:Float;
	var eventName:String;
	var value1:String;
	var value2:String;
}

typedef EventData = {
	var eventsNova:Array<Array<Events>>; //Events
	var events:Array<Dynamic>; //Psych Engine Support
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
