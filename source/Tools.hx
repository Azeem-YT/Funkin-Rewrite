package;

import flixel.FlxG;
import flixel.FlxSprite;
import gameObject.*;
import data.*;
import states.*;

class Tools //Im too lazy to add more stuff
{
	public static function getImagePixelWidth(texture:String = ''):Int {
        if (texture != null && texture != '') {
            var sprite:FlxSprite = new FlxSprite().loadGraphic(Paths.image(texture));

            if (sprite != null)
                return Math.floor(sprite.width / 4);
        }

        return 0;
    }
    
    public static function getImagePixelHeight(texture:String = ''):Int {
        if (texture != null && texture != '') {
            var sprite:FlxSprite = new FlxSprite().loadGraphic(Paths.image(texture));
            if (sprite != null)
                return Math.floor(sprite.height / 5);
        }

        return 0;
    }
}