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
import flixel.math.FlxPoint;
import flixel.FlxCamera;
import flixel.addons.transition.FlxTransitionableState;
import options.OptionsState;
import flixel.FlxObject;

import states.*;
import data.*;
import substates.*;
import gameObjects.*;

using StringTools;

class BaseOptionsMenu extends MusicBeatSubstate
{
	public var alphaOptions:FlxTypedGroup<Alphabet>;
	public var settingOptions:Array<OptionPref>;
	public var curSelected:Int = 0;
	public var curOption:String = "";
	public var canMove:Bool = true;
	public var onExit:Void -> Void;
	public var holdTimer:Float = 0;
	
	override function create()
	{		
		var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFFea71fd;
		bg.scrollFactor.x = 0;
		bg.scrollFactor.y = 0.18;
		bg.setGraphicSize(Std.int(bg.width * 1.1));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = true;
		add(bg);

		generateOptions();
		changeSelection();
		canMove = true;
	}

	private function generateOptions()
	{
		alphaOptions = new FlxTypedGroup<Alphabet>();
		add(alphaOptions);

		var shit:Int = 0;

		for (i in 0...settingOptions.length) {
			var optionText:Alphabet = new Alphabet(250, 0, settingOptions[i].optionName, false);
			optionText.isMenuItem = true;
			alphaOptions.add(optionText);

			switch (settingOptions[i].optionType)
			{
				case 'bool':
					add(settingOptions[i].checkmark);
					settingOptions[i].changeCheckmark();
				case 'float' | 'int':
					add(settingOptions[i].selector);
				case 'string':
					add(settingOptions[i].stringSelector);
			}
		}
		alphaOptions.members[curSelected].alpha = 1;
	}

	function changeSelection(?change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = settingOptions.length - 1;
		if (curSelected >= settingOptions.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in alphaOptions.members) {
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;

			if (item.targetY == 0)
				item.alpha = 1;
		}
	}

	override function update(elapsed:Float)
	{
		var upP = controls.UI_UP_P;
		var downP = controls.UI_DOWN_P;
		var accepted = controls.ACCEPT;

		if (upP && canMove)
			changeSelection(-1);

		if (downP && canMove)
			changeSelection(1);

		if (controls.BACK && canMove) {
			if (onExit != null)
				onExit();
							
			close();
		}

		for (i in 0...settingOptions.length){
			var alphaText:Alphabet = alphaOptions.members[i];
			switch (settingOptions[i].optionType)
			{
				case 'bool':
					var checkmark:AlphaCheckbox = settingOptions[i].checkmark;
					var checkbox:FlxSprite = checkmark.checkbox;

					if (checkbox.animation.curAnim != null && checkbox.animation.curAnim.finished) {
						switch (checkbox.animation.curAnim.name)
						{
							case 'true':
								checkmark.playAnim('true-finished', true);
							case 'false':
								checkmark.playAnim('false-finished', true);
						}
					}

					checkbox.x = alphaText.lastSprite.x + 50;
					checkbox.y = alphaText.lastSprite.y - 50;

				case 'int' | 'float':
					var selector:AlphaSelector = settingOptions[i].selector;
					selector.valueText.y = alphaText.lastSprite.y;
					selector.valueText.x = alphaText.lastSprite.x + (alphaText.lastSprite.width * 2);
				case 'string':
					var selector:StringSelector = settingOptions[i].stringSelector;
					selector.x = alphaText.x - (alphaText.lastSprite.width * 2) / 8;
					selector.y = alphaText.firstSprite.y - (alphaText.lastSprite.height / 3);
			}
		}

		var mainText:Alphabet = alphaOptions.members[curSelected];

		switch (settingOptions[curSelected].optionType)
		{
			case 'bool' | 'function':
				updateEnter(elapsed);
			case 'int' | 'float' | 'string':
				updateSelector(elapsed);
		}

		super.update(elapsed);
	}

	private function updateSelector(elapsed:Float)
	{
		var thePref:OptionPref = settingOptions[curSelected];
		
		switch (thePref.optionType) {
			case 'int' | 'float':
				if (controls.UI_LEFT || controls.UI_RIGHT) {
					/*
					var release = (controls.UI_LEFT_R || controls.UI_RIGHT_R); */
					var pressed = (controls.UI_LEFT_P || controls.UI_RIGHT_P);

					if (controls.UI_LEFT_P || controls.UI_RIGHT_P) {
						switch (thePref.optionType) {
							case 'int' | 'float':
								var toAdd:Dynamic = (controls.UI_LEFT ? -thePref.valueToAdd : thePref.valueToAdd);
								var roundedValue:Dynamic = (thePref.optionType == 'int' ? Math.round(toAdd) : FlxMath.roundDecimal(toAdd, thePref.decimals));
								var finalValue:Dynamic = thePref.curValue + roundedValue;

								var roundedMax:Dynamic = (thePref.optionType == 'int' ? Math.round(thePref.maxValue) : FlxMath.roundDecimal(thePref.maxValue, thePref.decimals));
								var roundedMin:Dynamic = (thePref.optionType == 'int' ? Math.round(thePref.minValue) : FlxMath.roundDecimal(thePref.minValue, thePref.decimals));

								if (finalValue > roundedMax)
									finalValue = roundedMax;

								if (finalValue < roundedMin)
									finalValue = roundedMin;

								thePref.curValue = finalValue;
								thePref.selector.setText(Std.string(thePref.curValue));
								thePref.setValue(thePref.curValue);
							case 'string':
								var change:Int = (controls.UI_LEFT_P ? -1 : 1);
								thePref.changeSelection(change);
								thePref.setValue(thePref.optionSelected);
								trace('string: ' + thePref.getValue());
						}
					}
					else {
						switch (thePref.optionType) {
							case 'int' | 'float':
								holdTimer += elapsed;

								if (holdTimer > 0.5) {
									switch (thePref.optionType) {
										case 'int':
											var toAdd:Dynamic = (controls.UI_LEFT ? -thePref.valueToAdd : thePref.valueToAdd);
											var finalValue:Int = thePref.curValue + Math.round(toAdd);
											var roundedMax:Int = Math.round(thePref.maxValue);
											var roundedMin:Int = Math.round(thePref.minValue);

											if (finalValue > roundedMax)
												finalValue = roundedMax;

											if (finalValue < roundedMin)
												finalValue = roundedMin;

											thePref.curValue = finalValue;
											thePref.selector.setText(Std.string(thePref.curValue));
											thePref.setValue(thePref.curValue);
										case 'float':
											var toAdd:Dynamic = (controls.UI_LEFT ? -thePref.valueToAdd : thePref.valueToAdd);
											var finalValue:Float = thePref.curValue + FlxMath.roundDecimal(toAdd, thePref.decimals);
											var roundedMax:Float = FlxMath.roundDecimal(thePref.maxValue, thePref.decimals);
											var roundedMin:Float = FlxMath.roundDecimal(thePref.minValue, thePref.decimals);

											if (finalValue > roundedMax)
												finalValue = roundedMax;

											if (finalValue < roundedMin)
												finalValue = roundedMin;

											thePref.curValue = finalValue;
											thePref.selector.setText(Std.string(thePref.curValue));
											thePref.setValue(thePref.curValue);
									}
								}
						}
					}

					switch (thePref.variableName) {
						case 'fpsCap':
							PlayerPrefs.setFramerate();
					}
				}
				else if (controls.UI_LEFT_R || controls.UI_RIGHT_R) {
					holdTimer = 0;
				}
		}
	}

	private function updateEnter(elapsed:Float)
	{
		var thePref:OptionPref = settingOptions[curSelected];

		if (controls.ACCEPT){
			if (thePref.optionType == 'bool') {
				var curValue:Bool = thePref.getValue();
				thePref.setValue(!curValue);
				thePref.changeCheckmark();

				switch (thePref.variableName) {
					case 'fpsCounter':
						Main.setFPSVisible();
				}
			}
			else if (thePref.optionType == 'function') {
				thePref.enterFunction();
			}
		}
	}

	private function pushOption(option:OptionPref) {
		if (settingOptions == null)
			settingOptions = [];

		settingOptions.push(option);
	}

	function getValue(variable):Dynamic
		return Reflect.getProperty(PlayerPrefs, variable);
}