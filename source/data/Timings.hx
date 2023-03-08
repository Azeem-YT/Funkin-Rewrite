package data;

class Timings
{
	public var imageName:String = 'sick';
	public var name:String = 'sick';
	public var hitWindow:Int = 0;
	public var score:Int = 350;
	public var noteSplash:Bool = true;

	public function new(rating:String) {
		this.name = rating;
		this.imageName = rating;
		getHitWindow();
	}

	public function getHitWindow() {
		if (Reflect.getProperty(PlayerPrefs, name + 'Window') != null) {
			hitWindow = Reflect.getProperty(PlayerPrefs, name + 'Window');
			return;
		}

		hitWindow = 0;
		name = 'shit';
		score = 50;
	}

	public function increaseCount()
		return Reflect.setProperty(PlayState, name + 's', Reflect.getProperty(PlayState, name + 's') + 1);
}