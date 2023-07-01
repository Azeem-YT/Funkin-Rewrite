package data;

import states.*;
import data.*;

class Timings
{
	public var imageName:String = 'sick';
	public var name:String = 'sick';
	public var hitWindow:Int = 0;
	public var score:Int = 500;
	public var noteSplashes:Bool = true;
	public var accuracyMod:Float = 1;
	public var healthMod:Float = 1;

	public function new(rating:String) {
		this.name = rating;
		this.imageName = rating;
		getHitWindow();
	}

	public function getHitWindow() {
		if (Reflect.getProperty(PlayerPrefs, name + 'Window') != null && 
			Std.isOfType(Reflect.getProperty(PlayerPrefs, name + 'Window'), Float)) {

			hitWindow = Reflect.getProperty(PlayerPrefs, name + 'Window');
			return;
		}

		hitWindow = 1000;
		noteSplashes = false;
	}

	public function increaseCounter()
		return Reflect.setProperty(PlayState.instance, name + 's', Reflect.getProperty(PlayState.instance, name + 's') + 1);
}