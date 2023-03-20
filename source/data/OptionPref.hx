package data;

import flixel.*;
import flixel.math.FlxMath;
import options.OptionsState;
import gameObjects.*;
import data.*;

using StringTools;

class OptionPref
{
	public var optionType:String;
	public var optionName:String;
	public var curValue:Dynamic = 0;

	public var minValue:Dynamic = 0;
	public var maxValue:Float = 30;
	public var curSelected:Int = 0;
	public var optionsArray:Array<String> = [];
	public var optionSelected:String = '';

	public var valueToAdd:Float = 1;
	public var enterFunction:Void -> Void;

	public var checkmark:AlphaCheckbox;
	public var selector:AlphaSelector;
	public var stringSelector:StringSelector;

	public var variableName:String;
	public var decimals:Int = 2;

	public function new(variableName:String, optionText:String, optionType:String, defaultValue:Dynamic = null, ?options:Array<String>, ?enterFunc:Void -> Void)
	{
		this.optionType = optionType;
		this.variableName = variableName;
		optionName = optionText;
		this.curValue = getValue();

		switch (optionType)
		{
			case 'integer':
				optionType = 'int';
			case 'percent':
				optionType = 'float';
			case 'booleen':
				optionType = 'bool';
			case 'fl':
				optionType = 'float';
			case 'str':
				optionType = 'string';
		}

		switch (this.optionType) {
			case 'bool':
				checkmark = new AlphaCheckbox(0, 0, getValue());
			case 'float':
				selector = new AlphaSelector(0, 0, curValue, defaultValue, 'Float');
			case 'int':
				selector = new AlphaSelector(0, 0, curValue, defaultValue, 'Int');
			case 'string':
				optionsArray = options;
				stringSelector = new StringSelector(0, 0, curValue, defaultValue);
				if (!Std.isOfType(curValue, String))
					stringSelector.setText(Std.string(curValue));
			case 'function':
				enterFunction = enterFunc;
		}
	}

	public function changeCheckmark() {
		if (checkmark != null)
			checkmark.switchCheck(curValue);
	}

	public function changeSelection(change:Int) {
		curSelected += change;

		if (curSelected < 0)
			curSelected = optionsArray.length - 1;
		if (curSelected >= optionsArray.length)
			curSelected = 0;

		optionSelected = optionsArray[curSelected];
		stringSelector.setText(optionSelected);
		setValue(optionSelected);
	}

	public function getValue():Dynamic {	

		if (Reflect.getProperty(PlayerPrefs, variableName) != null) {
			if (optionType == 'string') {
				if (PlayerPrefs.selectedOption.exists(variableName))
					curSelected = PlayerPrefs.selectedOption.get(variableName);
			}
			return Reflect.getProperty(PlayerPrefs, variableName);
		}

		return PlayerPrefs.modVariables.get(variableName);
	}

	public function setSelectorText(text:String = 'Unknown') {
		if (selector != null)
			selector.setText(text);
	}

	public function setValue(value:Dynamic) {
		if (Reflect.getProperty(PlayerPrefs, variableName) != null) {
			Reflect.setProperty(PlayerPrefs, variableName, value);
			if (optionType == 'string')
				PlayerPrefs.selectedOption.set(variableName, curSelected);
		}
		else {
			PlayerPrefs.modVariables.set(variableName, value);
			if (optionType == 'string')
				PlayerPrefs.selectedOption.set(variableName, curSelected);
		}
		PlayerPrefs.savePrefs();
		curValue = value;
	}
}