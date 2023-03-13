package options;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxBasic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.effects.FlxFlicker;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.util.FlxTimer;
import flixel.math.FlxMath;
import flixel.FlxCamera;
import flixel.addons.transition.FlxTransitionableState;
import flixel.FlxSubState;
import flixel.group.FlxGroup;
import flixel.util.FlxSignal;
import flixel.util.typeLimit.*;

import states.*;
import substates.*;
import data.*;

using StringTools;

class OptionsState extends MusicBeatState //Week 7 Options state is goofy
{	
	public var curState:String = 'Options';
	public var curSubState:MusicBeatSubstate = null;
	public var items:TextMenuList;
	public var canExit = true;
	public var enabled:Bool = true;

	override function create() {
		var menuBG = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		menuBG.color = 0xFFea71fd;
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.scrollFactor.set(0, 0);
		add(menuBG);

		add(items = new TextMenuList());
		createItem('preferences', function() openSub('prefs'));
		createItem("controls", function() openSub('controls'));
		createItem('Graphics', function() openSub('graphics'));
		createItem("exit", exit);

		enabled = true;
	}

	function createItem(name:String, callback:Void->Void, fireInstantly = false) {
		var item = items.createItem(0, 100 + items.length * 100, name, Bold, callback);
		item.fireInstantly = fireInstantly;
		item.screenCenter(X);
		return item;
	}

	public function getSubState(state:String = 'prefs') {
		var returnSub:MusicBeatSubstate;
		var dynamicState:Dynamic = null;
		switch (state) {
			case 'prefs':
				dynamicState = new Preferences();
			case 'controls':
				dynamicState = new ControlsMenu();
			case 'graphics':
				dynamicState = new GraphicsSettings();
		}

		returnSub = dynamicState;

		return returnSub;
	}

	override function update(elapsed:Float) {
		
		if (enabled && controls.BACK)
			exit();

		super.update(elapsed);
	}

	public function openSub(state:String = 'prefs') {
		curSubState = getSubState(state);

		if (curSubState != null) {
			openSubState(curSubState);
			curState = state;
			setEnabled(false);
			canExit = false;

			curSubState.closeCallback = function() {
				curSubState.close();
				canExit = true;
				setEnabled(true);
			}

			trace('Opening sub: $state');
		}
	}

	public function setEnabled(value:Bool) {
		items.enabled = value;
		enabled = value;
	}

	public function exit() {
		items.enabled = false;
		enabled = false;
		FlxG.switchState(new MainMenuState());
	}
}