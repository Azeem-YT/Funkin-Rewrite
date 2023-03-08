package;

import flixel.FlxState;
import WiggleEffect.WiggleEffectType;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import haxe.Json;
import lime.utils.Assets;
import openfl.display.BlendMode;
import openfl.display.StageQuality;
import openfl.filters.ShaderFilter;
import openfl.Lib;
import openfl.display3D.textures.VideoTexture;
import openfl.geom.Matrix;
import openfl.display.BitmapData;
import lime.app.Application;
import openfl.utils.AssetType;
import flash.display.BlendMode;
import openfl.filters.BitmapFilter;
import flixel.group.FlxSpriteGroup;
import hxCodec.*;
import Stage;
import Note;
import Strum.StaticArrow;
import sys.FileSystem;
import sys.io.File;
import LuaState;
import DialogueState;
import data.*;
import gameObjects.*;

class PlayState extends MusicBeatState
{
	public static var instance:PlayState = null;
	public static var SONG:SwagSong = null;
	public static var curStage:String = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	//Lua & Hscript Shit
	public static var luaSprites:Map<String, LuaSprite> = new Map<String, LuaSprite>();
	public static var luaTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public static var luaSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public static var luaTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public static var luaShaders:Map<String, Array<String>> = new Map<String, Array<String>>();
	public static var cameraShaders:Map<String, FlxRuntimeShader> = new Map<String, FlxRuntimeShader>();
	public static var globalVariables:Map<String, Dynamic> = new Map<String, Dynamic>();
	public static var playStatecams:Map<String, FlxCamera> = new Map<String, FlxCamera>();

	public static var boyfriendX:Float = 770;
	public static var boyfriendY:Float = 450;
	public static var gfX:Float = 400;
	public static var gfY:Float = 130;
	public static var dadX:Float = 100;
	public static var dadY:Float = 100;

	public static var positionMap:Map<String, Array<Float>> = new Map<String, Array<Float>>();

	public static var bfChars:Map<String, Boyfriend> = new Map<String, Boyfriend>();
	public static var gfChars:Map<String, Character> = new Map<String, Character>();
	public static var dadChars:Map<String, Character> = new Map<String, Character>();

	public static var practiceMode:Bool = false;
	public static var deathCounter:Int = 0;
	public static var practiceUsed:Bool = false;
	public static var isPixelNotes:Bool = false;

	public static var dad:Character;
	public static var gf:Character;
	public static var boyfriend:Boyfriend;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var lastNoteHit:Note = null;
	public var lastBotHits:Array<Note> = [];
	public static var totalNotes:Int = 0;

	public static var strumLine:FlxSprite;
	public var curSection:Int = 0;

	public var camFollow:FlxObject;
	public var camPos:FlxPoint;

	public static var prevCamFollow:FlxObject;

	public static var strumLineNotes:FlxTypedGroup<StaticArrow>;
	public static var strumLines:FlxTypedGroup<Strum>;
	public static var playerStrums:Strum;
	public static var opponentStrums:Strum;
	public static var gfStrums:Strum;

	public var playerLane:Int = 1;
	public var numbOfStrums:Int = 2;

	public var camZooming:Bool = false;
	public var curSong:String = "";

	public var gfSpeed:Int = 1;
	public var health:Float = 1;
	public var combo:Int = 0;
	public var sicks:Int;
	public var goods:Int;
	public var bads:Int;
	public var shits:Int;
	public var misses:Int;

	public static var timingData:Array<Timings> = [];

	public var hudGroup:HudGroup;

	override public function create() {
		instance = this;
		usedPractice = false;
		skipIntro = false;

		super.create();

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		sicks = 0;
		bads = 0;
		shits = 0;
		goods = 0;
		totalNotes = 0;
		
		misses = 0; //reset score

		bfChars.clear();
		gfChars.clear();
		dadChars.clear();

		luaSprites.clear();
		luaTweens.clear();
		luaSounds.clear();
		luaTimers.clear();
		luaShaders.clear();
		cameraShaders.clear();

		globalVariables.clear();
		playStatecams.clear();

		destroyModules();
		loadedScripts = [];

		camGame = new FlxCamera();
		camNotes = new FlxCamera();
		camNotes.bgColor.alpha = 0;
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		playStatecams.set('camGame', camGame);
		addCamera(camNotes, 'camNotes');
		addCamera(camHUD, 'camHUD');

		FlxCamera.defaultCameras = [camGame];

		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		switch (SONG.song.toLowerCase()) {
			case 'senpai':
				dialogue = CoolUtil.coolTextFile(Paths.txt('data/senpai/senpaiDialogue'));
			case 'roses':
				dialogue = CoolUtil.coolTextFile(Paths.txt('data/roses/rosesDialogue'));
			case 'thorns':
				dialogue = CoolUtil.coolTextFile(Paths.txt('data/thorns/thornsDialogue'));
		}

		diffText = '-' + diffArray[storyDifficulty];

		if (diffText == '-normal')
			diffText = '';

		curStage = SONG.stage;

		if (SONG.stage == null)
		{
			switch (SONG.song.toLowerCase())
			{
				case 'tutorial' | 'bopeebo' | 'fresh' | 'dadbattle':
					curStage = 'stage';
				case 'spookeez' | 'south' | 'monster':
					curStage = 'spooky';
				case 'pico' | 'blammed' | 'philly' | 'philly-nice':
					curStage = 'philly';
				case 'milf' | 'satin-panties' | 'high':
					curStage = 'limo';
				case 'cocoa' | 'eggnog':
					curStage = 'mall';
				case 'winter-horrorland':
					curStage = 'mallEvil';
				case 'senpai' | 'roses':
					curStage = 'school';
				case 'thorns':
					curStage = 'schoolEvil';
				case 'ugh' | 'guns' | 'stress':
					curStage = 'tank';
			}
		}

		var gfVersion:String = 'gf';

		if (SONG.gfVersion != null)
		{
			gfVersion = SONG.gfVersion;
		}
		else
		{
			switch (curStage)
			{
				case 'limo':
					gfVersion = 'gf-car';
				case 'mall' | 'mallEvil':
					gfVersion = 'gf-christmas';
				case 'school':
					gfVersion = 'gf-pixel';
				case 'schoolEvil':
					gfVersion = 'gf-pixel';
				default:
					gfVersion = 'gf';
			}

			switch (SONG.song.toLowerCase())
			{
				case 'ugh' | 'guns':
					gfVersion = 'gf-tankmen';
				case 'stress':
					gfVersion = "pico-speaker";
			}
		}

		var stageData:StageData = Stage.loadData(curStage);
		positionMap.set('boyfriend', stageData.boyfriendPos[0]);
		positionMap.set('boyfriend', stageData.boyfriendPos[1]);
		positionMap.set('gf', stageData.gfPos[0]);
		positionMap.set('gf', stageData.gfPos[0]);
		positionMap.set('dad', stageData.dadPos[0]);
		positionMap.set('dad', stageData.dadPos[1]);
		defaultCamZoom = stageData.camZoom;

		boyfriendGroup = new FlxSpriteGroup(positionMap.get('boyfriend')[0], positionMap.get('boyfriend')[1]);
		dadGroup = new FlxSpriteGroup(positionMap.get('dad')[0], positionMap.get('dad')[1]);
		gfGroup = new FlxSpriteGroup(positionMap.get('gf')[0], positionMap.get('gf')[1]);

		boyfriend = new Boyfriend(0, 0, SONG.player1);
		if (boyfriend.frames == null){
			boyfriend = new Boyfriend(0, 0, 'bf');
			trace("Boyfriend character does not exists or has an error, sorry.");
		}

		gf = new Character(0, 0, gfVersion);
		if (gf.frames == null){
			gf = new Character(0, 0, 'gf');
			trace("Gf character does not exists or has an error, sorry.");
		}

		if (stageData.hidegf)
			gf.visible = false;

		dad = new Character(0, 0, SONG.player2);
		if (dad.frames == null){
			dad = new Character(0, 0, 'dad');
			trace("Dad character does not exists or has an error, sorry.");
		}

		var directorys:Array<String> = [Paths.mods(), Paths.getAssetDirectory()];

		switch (curStage)
		{
			case 'stage':
			{
				curStage = 'stage';

				var bg:EngineSprite = new EngineSprite(-600, -200).loadGraphic(Paths.image('stageback', 'shared'));
				bg.antialiasing = FlxG.save.data.antialiasing;
				bg.scrollFactor.set(0.9, 0.9);
				bg.active = false;
				add(bg);

				var stageFront:EngineSprite = new EngineSprite(-650, 600).loadGraphic(Paths.image('stagefront', 'shared'));
				stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
				stageFront.updateHitbox();
				stageFront.antialiasing = FlxG.save.data.antialiasing;
				stageFront.scrollFactor.set(0.9, 0.9);
				stageFront.active = false;
				add(stageFront);

				var stageCurtains:EngineSprite = new EngineSprite(-500, -300).loadGraphic(Paths.image('stagecurtains', 'shared'));
				stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
				stageCurtains.updateHitbox();
				stageCurtains.antialiasing = FlxG.save.data.antialiasing;
				stageCurtains.scrollFactor.set(1.3, 1.3);
				stageCurtains.active = false;
				add(stageCurtains);
			}

			case 'spooky':
			{
				curStage = 'spooky';
				halloweenLevel = true;

				var hallowTex = Paths.getSparrowAtlas('halloween_bg', 'week2');

				halloweenBG = new EngineSprite(-200, -100);
				halloweenBG.frames = hallowTex;
				halloweenBG.animation.addByPrefix('idle', 'halloweem bg0');
				halloweenBG.animation.addByPrefix('lightning', 'halloweem bg lightning strike', 24, false);
				halloweenBG.playAnim('idle');
				halloweenBG.antialiasing = FlxG.save.data.antialiasing;
				add(halloweenBG);

				isHalloween = true;
			}
			case 'philly':
			{
				curStage = 'philly';

				var bg:EngineSprite = new EngineSprite(-100).loadGraphic(Paths.image('philly/sky', 'week3'));
				bg.scrollFactor.set(0.1, 0.1);
				add(bg);

				var city:EngineSprite = new EngineSprite(-10).loadGraphic(Paths.image('philly/city', 'week3'));
				city.scrollFactor.set(0.3, 0.3);
				city.setGraphicSize(Std.int(city.width * 0.85));
				city.updateHitbox();
				add(city);

				phillyCityLights = new FlxTypedGroup<EngineSprite>();
				add(phillyCityLights);

				for (i in 0...5)
				{
					var light:EngineSprite = new EngineSprite(city.x).loadGraphic(Paths.image('philly/win' + i, 'week3'));
					light.scrollFactor.set(0.3, 0.3);
					light.visible = false;
					light.setGraphicSize(Std.int(light.width * 0.85));
					light.updateHitbox();
					light.antialiasing = FlxG.save.data.antialiasing;
					phillyCityLights.add(light);
				}

				var streetBehind:EngineSprite = new EngineSprite(-40, 50).loadGraphic(Paths.image('philly/behindTrain', 'week3'));
				add(streetBehind);

				phillyTrain = new EngineSprite(2000, 360).loadGraphic(Paths.image('philly/train', 'week3'));
				add(phillyTrain);

				trainSound = new FlxSound().loadEmbedded(Paths.sound('train_passes', 'shared'));
				FlxG.sound.list.add(trainSound);

				// var cityLights:EngineSprite = new EngineSprite().loadGraphic(AssetPaths.win0.png);

				var street:EngineSprite = new EngineSprite(-40, streetBehind.y).loadGraphic(Paths.image('philly/street', 'week3'));
				add(street);
			}
			case 'limo':
			{
				curStage = 'limo';

				var skyBG:EngineSprite = new EngineSprite(-120, -50).loadGraphic(Paths.image('limo/limoSunset', 'week4'));
				skyBG.scrollFactor.set(0.1, 0.1);
				skyBG.antialiasing = FlxG.save.data.antialiasing;
				add(skyBG);

				var bgLimo:EngineSprite = new EngineSprite(-200, 480);
				bgLimo.frames = Paths.getSparrowAtlas('limo/bgLimo', 'week4');
				bgLimo.animation.addByPrefix('drive', "background limo pink", 24);
				bgLimo.playAnim('drive');
				bgLimo.scrollFactor.set(0.4, 0.4);
				bgLimo.antialiasing = FlxG.save.data.antialiasing;
				add(bgLimo);
				
				grpLimoDancers = new FlxTypedGroup<BackgroundDancer>();
				add(grpLimoDancers);

				for (i in 0...5)
				{
					var dancer:BackgroundDancer = new BackgroundDancer((370 * i) + 130, bgLimo.y - 400);
					dancer.scrollFactor.set(0.4, 0.4);
					grpLimoDancers.add(dancer);
				}

				var overlayShit:EngineSprite = new EngineSprite(-500, -600).loadGraphic(Paths.image('limo/limoOverlay', 'week4'));
				overlayShit.alpha = 0.5;
				// add(overlayShit);

				// var shaderBullshit = new BlendModeEffect(new OverlayShader(), FlxColor.RED);

				// FlxG.camera.setFilters([new ShaderFilter(cast shaderBullshit.shader)]);

				// overlayShit.shader = shaderBullshit;

				var limoTex = Paths.getSparrowAtlas('limo/limoDrive', 'week4');

				limo = new EngineSprite(-120, 550);
				limo.frames = limoTex;
				limo.animation.addByPrefix('drive', "Limo stage", 24);
				limo.playAnim('drive');
				limo.antialiasing = FlxG.save.data.antialiasing;

				fastCar = new EngineSprite(-300, 160).loadGraphic(Paths.image('limo/fastCarLol', 'week4'));
				fastCar.antialiasing = FlxG.save.data.antialiasing;
				// add(limo);
			}
		case 'mall':
			{
				curStage = 'mall';

				var bg:EngineSprite = new EngineSprite(-1000, -500).loadGraphic(Paths.image('christmas/bgWalls', 'week5'));
				bg.antialiasing = FlxG.save.data.antialiasing;
				bg.scrollFactor.set(0.2, 0.2);
				bg.active = false;
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				add(bg);

				upperBoppers = new EngineSprite(-240, -90);
				upperBoppers.frames = Paths.getSparrowAtlas('christmas/upperBop', 'week5');
				upperBoppers.animation.addByPrefix('bop', "Upper Crowd Bob", 24, false);
				upperBoppers.antialiasing = FlxG.save.data.antialiasing;
				upperBoppers.scrollFactor.set(0.33, 0.33);
				upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
				upperBoppers.updateHitbox();
				add(upperBoppers);

				var bgEscalator:EngineSprite = new EngineSprite(-1100, -600).loadGraphic(Paths.image('christmas/bgEscalator', 'week5'));
				bgEscalator.antialiasing = FlxG.save.data.antialiasing;
				bgEscalator.scrollFactor.set(0.3, 0.3);
				bgEscalator.active = false;
				bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
				bgEscalator.updateHitbox();
				add(bgEscalator);

				var tree:EngineSprite = new EngineSprite(370, -250).loadGraphic(Paths.image('christmas/christmasTree', 'week5'));
				tree.antialiasing = FlxG.save.data.antialiasing;
				tree.scrollFactor.set(0.40, 0.40);
				add(tree);

				bottomBoppers = new EngineSprite(-300, 140);
				bottomBoppers.frames = Paths.getSparrowAtlas('christmas/bottomBop', 'week5');
				bottomBoppers.animation.addByPrefix('bop', 'Bottom Level Boppers', 24, false);
				bottomBoppers.antialiasing = FlxG.save.data.antialiasing;
				bottomBoppers.scrollFactor.set(0.9, 0.9);
				bottomBoppers.setGraphicSize(Std.int(bottomBoppers.width * 1));
				bottomBoppers.updateHitbox();
				add(bottomBoppers);

				var fgSnow:EngineSprite = new EngineSprite(-600, 700).loadGraphic(Paths.image('christmas/fgSnow', 'week5'));
				fgSnow.active = false;
				fgSnow.antialiasing = FlxG.save.data.antialiasing;
				add(fgSnow);

				santa = new EngineSprite(-840, 150);
				santa.frames = Paths.getSparrowAtlas('christmas/santa', 'week5');
				santa.animation.addByPrefix('idle', 'santa idle in fear', 24, false);
				santa.antialiasing = FlxG.save.data.antialiasing;
				add(santa);
			}
		case 'mallEvil':
			{
				curStage = 'mallEvil';

				var bg:EngineSprite = new EngineSprite(-400, -500).loadGraphic(Paths.image('christmas/evilBG', 'week5'));
				bg.antialiasing = FlxG.save.data.antialiasing;
				bg.scrollFactor.set(0.2, 0.2);
				bg.active = false;
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				add(bg);

				var evilTree:EngineSprite = new EngineSprite(300, -300).loadGraphic(Paths.image('christmas/evilTree', 'week5'));
				evilTree.antialiasing = FlxG.save.data.antialiasing;
				evilTree.scrollFactor.set(0.2, 0.2);
				add(evilTree);

				var evilSnow:EngineSprite = new EngineSprite(-200, 700).loadGraphic(Paths.image("christmas/evilSnow", 'week5'));
				evilSnow.antialiasing = FlxG.save.data.antialiasing;
				add(evilSnow);
			}
		case 'school':
			{
				curStage = 'school';

				var bgSky = new EngineSprite().loadGraphic(Paths.image('weeb/weebSky', 'week6'));
				bgSky.scrollFactor.set(0.1, 0.1);
				add(bgSky);

				var repositionShit = -200;

				var bgSchool:EngineSprite = new EngineSprite(repositionShit, 0).loadGraphic(Paths.image('weeb/weebSchool', 'week6'));
				bgSchool.scrollFactor.set(0.6, 0.90);
				add(bgSchool);

				var bgStreet:EngineSprite = new EngineSprite(repositionShit).loadGraphic(Paths.image('weeb/weebStreet', 'week6'));
				bgStreet.scrollFactor.set(0.95, 0.95);
				add(bgStreet);

				var fgTrees:EngineSprite = new EngineSprite(repositionShit + 170, 130).loadGraphic(Paths.image('weeb/weebTreesBack', 'week6'));
				fgTrees.scrollFactor.set(0.9, 0.9);
				add(fgTrees);

				var bgTrees:EngineSprite = new EngineSprite(repositionShit - 380, -800);
				var treetex = Paths.getPackerAtlas('weeb/weebTrees', 'week6');
				bgTrees.frames = treetex;
				bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
				bgTrees.playAnim('treeLoop');
				bgTrees.scrollFactor.set(0.85, 0.85);
				add(bgTrees);

				var treeLeaves:EngineSprite = new EngineSprite(repositionShit, -40);
				treeLeaves.frames = Paths.getSparrowAtlas('weeb/petals', 'week6');
				treeLeaves.animation.addByPrefix('leaves', 'PETALS ALL', 24, true);
				treeLeaves.playAnim('leaves');
				treeLeaves.scrollFactor.set(0.85, 0.85);
				add(treeLeaves);

				var widShit = Std.int(bgSky.width * 6);

				bgSky.setGraphicSize(widShit);
				bgSchool.setGraphicSize(widShit);
				bgStreet.setGraphicSize(widShit);
				bgTrees.setGraphicSize(Std.int(widShit * 1.4));
				fgTrees.setGraphicSize(Std.int(widShit * 0.8));
				treeLeaves.setGraphicSize(widShit);

				fgTrees.updateHitbox();
				bgSky.updateHitbox();
				bgSchool.updateHitbox();
				bgStreet.updateHitbox();
				bgTrees.updateHitbox();
				treeLeaves.updateHitbox();

				bgGirls = new BackgroundGirls(-100, 190);
				bgGirls.scrollFactor.set(0.9, 0.9);

				if (SONG.song.toLowerCase() == 'roses') {
					bgGirls.getScared();
				}

				bgGirls.setGraphicSize(Std.int(bgGirls.width * daPixelZoom));
				bgGirls.updateHitbox();
				add(bgGirls);
			}
		case 'schoolEvil':
			{
				curStage = 'schoolEvil';

				var waveEffectBG = new FlxWaveEffect(FlxWaveMode.ALL, 2, -1, 3, 2);
				var waveEffectFG = new FlxWaveEffect(FlxWaveMode.ALL, 2, -1, 5, 2);

				var posX = 400;
				var posY = 200;

				var bg:EngineSprite = new EngineSprite(posX, posY);
				bg.frames = Paths.getSparrowAtlas('weeb/animatedEvilSchool', 'week6');
				bg.animation.addByPrefix('idle', 'background 2', 24);
				bg.playAnim('idle');
				bg.scrollFactor.set(0.8, 0.9);
				bg.scale.set(6, 6);
				add(bg);
			}
		case 'tank':
			{	
				defaultCamZoom = 0.9;
				curStage = "tank";

				tankSky = new BGSprite("tankSky", -400, -400 , 0, 0);
				add(tankSky);

				tankClouds = new BGSprite("tankClouds", FlxG.random.int(-700,-100), FlxG.random.int(-20,20), 0.1, 0.1);
				tankClouds.active = true;
				tankClouds.velocity.x = FlxG.random.float(5, 15);
				add(tankClouds);

				tankMountains = new BGSprite("tankMountains",-300,-20, 0.2, 0.2);
				tankMountains.setGraphicSize(Std.int(1.2 * tankMountains.width));
				tankMountains.updateHitbox();
				add(tankMountains);

				tankBuildings = new BGSprite("tankBuildings", -200,0, 0.3, 0.3);
				tankBuildings.setGraphicSize(Std.int(1.1* tankBuildings.width));
				tankBuildings.updateHitbox();
				add(tankBuildings);

				tankRuins = new BGSprite("tankRuins", -200, 0, 0.35, 0.35);
				tankRuins.setGraphicSize(Std.int(1.1* tankRuins.width));
				tankRuins.updateHitbox();
				add(tankRuins);

				smokeLeft = new BGSprite("smokeLeft", -200, -100, 0.4, 0.4,["SmokeBlurLeft"], true);
				add(smokeLeft);

				smokeRight = new BGSprite("smokeRight", 1100, -100, 0.4, 0.4,["SmokeRight"],true);
				add(smokeRight);

				tankWatchtower = new BGSprite("tankWatchtower", 100, 50, 0.5, 0.5,["watchtower gradient color"]);
				add(tankWatchtower);

				tankRolling = new BGSprite("tankRolling", 300, 300, 0.5, 0.5,["BG tank w lighting"], true);
				add(tankRolling);

				tankmanRun = new FlxTypedGroup<TankmenBG>();
				add(tankmanRun);

				tankGround = new BGSprite("tankGround", -420, -150);
				tankGround.setGraphicSize(Std.int(1.15* tankGround.width));
				tankGround.updateHitbox();
				add(tankGround);

				moveTank();

				foregroundSprites = new FlxTypedGroup<BGSprite>();

				var tank0 = new BGSprite("tank0", -500, 650, 1.7, 1.5, ["fg"]);
				foregroundSprites.add(tank0);

				var tank1 = new BGSprite("tank1",-300, 750, 2, 0.2, ["fg"]);
				foregroundSprites.add(tank1);

				var tank2 = new BGSprite("tank2", 450, 940, 1.5, 1.5, ["foreground"]);
				foregroundSprites.add(tank2);

				var tank3 = new BGSprite("tank4", 1300, 900, 1.5, 1.5, ["fg"]);
				foregroundSprites.add(tank3);

				var tank4 = new BGSprite("tank5", 1620, 700, 1.5, 1.5, ["fg"]);
				foregroundSprites.add(tank4);

				var tank5 = new BGSprite("tank3", 1300, 1200, 3.5, 2.5, ["fg"]);
				foregroundSprites.add(tank5);
			}
		}

		camPos = new FlxPoint(dad.getGraphicMidpoint().x, dad.getGraphicMidpoint().y);

		add(gfGroup);

		if (curStage == 'limo') {
			resetFastCar();
			addBehindChar(fastCar, gf);
			add(limo);
		}

		add(dadGroup);
		add(boyfriendGroup);

		addCharacter(gf, true);
		addCharacter(boyfriend);
		addCharacter(dad);

		switch (curStage) {
			case 'schoolEvil':
				var evilTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069);
				addBehindChar(evilTrail, dad);
			case 'tank':
				add(foregroundSprites);
		}

		Conductor.songPosition = -5000;

		strumLine = new FlxSprite(0, 50).makeGraphic(FlxG.width, 10);
		strumLine.scrollFactor.set();

		if (PlayerPrefs.downscroll && FlxG.save.data.strumOffset == 0)
			strumLine.y = FlxG.height - 150;

		strumLines = new FlxTypedGroup<Strum>();
		add(strumLines);

		strumLineNotes = new FlxTypedGroup<StaticArrow>();
		add(strumLineNotes);

		if (PlayerPrefs.playOpponent)
			playerLane = 0;

		generateSong(SONG.song);

		regenStrums();

		camFollow = new FlxObject(0, 0, 1, 1);

		camFollow.setPosition(camPos.x, camPos.y);

		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}

		add(camFollow);

		FlxG.camera.follow(camFollow, LOCKON, 0.04);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow.getPosition());

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;

		hudGroup = new HudGroup(this);
		add(hudGroup);

		timeGroup = new FlxSpriteGroup(0, 0);
		timeGroup.cameras = [camHUD];
		add(timeGroup);

		strumLineNotes.cameras = [camNotes];
		strumLines.cameras = [camNotes];
		for (i in 0...strumLines.length) {
			strumLines.members[i].strums.cameras = [camNotes];
			strumLines.members[i].grpNoteSplashes.cameras = [camNotes];
		}
		notes.cameras = [camNotes];
		hudGroup.cameras = [camHUD];
		doof.cameras = [camHUD];
		startingSong = true;

		if (isStoryMode && !seenCutscene)
		{
			seenCutscene = true;

			var songLowerCase:String = curSong.toLowerCase();

			switch (curSong.toLowerCase())
			{
				case "winter-horrorland":
					var blackScreen:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
					add(blackScreen);
					blackScreen.scrollFactor.set();
					camHUD.visible = false;

					new FlxTimer().start(0.1, function(tmr:FlxTimer)
					{
						remove(blackScreen);
						FlxG.sound.play(Paths.sound('Lights_Turn_On'));
						camFollow.y = -2050;
						camFollow.x += 200;
						FlxG.camera.focusOn(camFollow.getPosition());
						FlxG.camera.zoom = 1.5;

						new FlxTimer().start(0.8, function(tmr:FlxTimer)
						{
							camHUD.visible = true;
							remove(blackScreen);
							FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 2.5, {
								ease: FlxEase.quadInOut,
								onComplete: function(twn:FlxTween)
								{
									startCountdown();
								}
							});
						});
					});
				case 'senpai':
					schoolIntro(doof);
				case 'roses':
					FlxG.sound.play(Paths.sound('ANGRY'));
					schoolIntro(doof);
				case 'thorns':
					schoolIntro(doof);
				case 'ugh':
					playCutscene('ughCutscene.mp4');
				case 'guns':
					playCutscene('gunsCutscene.mp4');
				case 'stress':
					playCutscene('stressCutscene.mp4');
				default:
					startCountdown();
			}
		}
		else
		{
			var songLowerCase:String = curSong.toLowerCase();
			switch (songLowerCase) {
				default:
					startCountdown();
			}
		}

		if (SONG.song.toLowerCase() == 'tutorial' && dad.curCharacter.startsWith('gf')) {
			dad.setPosition(positionMap.get('gf')[0], positionMap.get('gf')[1]);
			gf.visible = false;
		}
	}

	public function startPosition(char:Character, isGF:Bool = false) {
		if (isGF && dad.curCharacter.startsWith('gf')) {
			char.setPosition(gfX, gfY);
			char.scrollFactor.set(0.95, 0.95);
		}

		if (char.positionOffset != null) {
			char.x += char.positionOffset[0];
			char.y += char.positionOffset[1];
		}
	}

	public function addBehindChar(obj:FlxObject, char:Character) {
		if (char != null) {
			var index:Int = members.indexOf(char.ghostGroup);
			insert(index, obj);
			return;
		}

		add(obj);
	}

	public function addCharacter(char:Character, isGF:Bool = false) {
		var charGroup:FlxSpriteGroup = dadGroup;

		if (char == boyfriend) {
			charGroup = boyfriendGroup;
			trace('add boyfriend ' + boyfriend.curCharacter);
		}

		if (char == gf) {
			charGroup = gfGroup;
			trace('add gf ' + gf.curCharacter);
		}

		if (char != null) {
			add(char.ghostGroup);
			charGroup.add(char);
		}

		startPosition(char, isGF);
	}

	var tankX:Float = 400;
	var tankSpeed:Float = FlxG.random.float(5, 7);
	var tankAngle:Float = FlxG.random.int(-90, 45);

	function moveTank(?elapsed:Float = 0)
	{
		if (!inCutscene)
		{
			tankAngle += elapsed * tankSpeed;
			tankRolling.angle = (tankAngle - 90 + 15);
			tankRolling.x = (tankX + 1500 * Math.cos(Math.PI / 180 * (1 * tankAngle + 180)));
			tankRolling.y = (1300 + 1100 * Math.sin(Math.PI / 180 * (1 * tankAngle + 180)));
		}
	}

	function playCutscene(name:String, atEndOfSong:Bool = false)
	{
		inCutscene = true;
		FlxG.sound.music.stop();

		var video:VideoHandler = new VideoHandler();
		video.finishCallback = function()
		{
			if (atEndOfSong)
			{
				if (storyPlaylist.length <= 0)
					FlxG.switchState(new StoryMenuState());
				else
				{
					SONG = Song.loadFromJson(storyPlaylist[0].toLowerCase());
					if (SONG != null)
						FlxG.switchState(new PlayState());
					else {
						FlxG.switchState(new ErrorState());
						ErrorState.song = storyPlaylist[0].toLowerCase();
					}
				}
			}
			else
				startCountdown();

			trace('Video $name has finished!');
		}
		video.playVideo(Paths.video(name));
		trace('Playing Video $name');
	}

	public function playVideo(fileName:String) {
		var video:VideoHandler = new VideoHandler();
		video.finishCallback = function() {
			trace('Video $fileName has finished!');
		}
		video.playVideo(Paths.video(fileName));
		trace('Playing Video $fileName');
	}

	function schoolIntro(?dialogueBox:DialogueBox):Void
	{
		if (doof != null) {
			var black:EngineSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
			black.scrollFactor.set();
			add(black);

			var red:EngineSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
			red.scrollFactor.set();

			var senpaiEvil:EngineSprite = new EngineSprite();
			senpaiEvil.frames = Paths.getSparrowAtlas('weeb/senpaiCrazy');
			senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
			senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
			senpaiEvil.scrollFactor.set();
			senpaiEvil.updateHitbox();
			senpaiEvil.screenCenter();

			if (SONG.song.toLowerCase() == 'roses' || SONG.song.toLowerCase() == 'thorns')
			{
				remove(black);

				if (SONG.song.toLowerCase() == 'thorns') {
					camHUD.alpha = 0;
					add(red);
				}
			}

			new FlxTimer().start(0.3, function(tmr:FlxTimer)
			{
				black.alpha -= 0.15;

				if (black.alpha > 0)
				{
					tmr.reset(0.3);
				}
				else
				{
					if (dialogueBox != null)
					{
						inCutscene = true;

						if (SONG.song.toLowerCase() == 'thorns')
						{
							add(senpaiEvil);
							senpaiEvil.alpha = 0;
							new FlxTimer().start(0.3, function(swagTimer:FlxTimer)
							{
								senpaiEvil.alpha += 0.15;
								if (senpaiEvil.alpha < 1)
								{
									swagTimer.reset();
								}
								else
								{
									senpaiEvil.playAnim('idle');
									FlxG.sound.play(Paths.sound('Senpai_Dies'), 1, false, null, true, function()
									{
										remove(senpaiEvil);
										remove(red);
										FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function() {
											add(dialogueBox);
											camHUD.alpha = 1;
										}, true);
									});
									new FlxTimer().start(3.2, function(deadTime:FlxTimer)
									{
										FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
									});
								}
							});
						}
						else
						{
							add(dialogueBox);
						}
					}
					else
						startCountdown();

					remove(black);
				}
			});
		}
		else
			startCountdown();
	}

	function startCountdown():Void {
		inCutscene = false;
		talking = false;
		startedCountdown = true;
		Conductor.songPosition = 0;
		Conductor.songPosition -= Conductor.crochet * 5;

		var swagCounter:Int = 0;

		if (skipIntro) {
			swagCounter = 4;
			Conductor.songPosition = 0;
		}

		startTimer = new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
		{
			dad.dance();
			gf.dance();
			boyfriend.dance();

			var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
			introAssets.set('default', ['ready', "set", "go"]);
			introAssets.set('school', ['weeb/pixelUI/ready-pixel', 'weeb/pixelUI/set-pixel', 'weeb/pixelUI/date-pixel']);
			introAssets.set('schoolEvil', ['weeb/pixelUI/ready-pixel', 'weeb/pixelUI/set-pixel', 'weeb/pixelUI/date-pixel']);

			var introAlts:Array<String> = introAssets.get('default');
			var altSuffix:String = "";

			for (value in introAssets.keys())
			{
				if (value == curStage)
				{
					introAlts = introAssets.get(value);
					altSuffix = '-pixel';
				}
			}

			switch (swagCounter)
			{
				case 0:	
					FlxG.sound.play(Paths.sound('intro3'), 0.6);
				case 1:
					var ready:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[0]));
					ready.scrollFactor.set();
					ready.updateHitbox();

					if (curStage.startsWith('school'))
						ready.setGraphicSize(Std.int(ready.width * daPixelZoom));

					ready.screenCenter();
					add(ready);
					FlxTween.tween(ready, {y: ready.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							ready.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('intro2'), 0.6);
				case 2:
					var set:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[1]));
					set.scrollFactor.set();

					if (curStage.startsWith('school'))
						set.setGraphicSize(Std.int(set.width * daPixelZoom));

					set.screenCenter();
					add(set);
					FlxTween.tween(set, {y: set.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							set.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('intro1'), 0.6);
				case 3:
					var go:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[2]));
					go.scrollFactor.set();

					if (curStage.startsWith('school'))
						go.setGraphicSize(Std.int(go.width * daPixelZoom));

					go.updateHitbox();

					go.screenCenter();
					add(go);
					FlxTween.tween(go, {y: go.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							go.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('introGo'), 0.6);
				case 4:
					//Nothing
				}

				swagCounter += 1;
			}, 5);
		}
	}

	var startTimer:FlxTimer;
	var perfectMode:Bool = false;

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	function startSong():Void
	{
		startingSong = false;
		songStarted = true;
		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		FlxG.sound.playMusic(Paths.inst(CoolUtil.spaceToDash(PlayState.SONG.song)), 1, false);
		FlxG.sound.music.onComplete = endSong;
		vocals.play();

		#if desktop
		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;

		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC, true, songLength);
		#end

		var seconds:Float = songLength / 1000;
		seconds = Math.round(seconds);

		timeLength = FlxStringUtil.formatTime(seconds, false);

		if (songLength <= 0)
			songLength = 10000;

		createTimeBar();

		switch (curStage) {
			case 'tank':
				foregroundSprites.forEach(function(spr:BGSprite) {
					spr.dance();
				});
		}
	}

	public functio createTimeBar() {
		timeText = new FlxText(FlxG.width / 2  - 215, strumLine.y - (PlayerPrefs.downscroll ? -100 : 40), 400, "0:00/???", 60);
		timeText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeText.scrollFactor.set();
		timeText.borderSize = 2;
		timeText.alpha = 0;

		timeBG = new FlxSprite(0, timeText.y + 7).loadGraphic(Paths.image('healthBar'));
		timeBG.screenCenter(X);
		timeBG.scrollFactor.set();
		timeBG.alpha = 0;
		timeGroup.add(timeBG);

		timeBar = new FlxBar(timeBG.x + 4, timeBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBG.width - 8), Std.int(timeBG.height - 8), Conductor,
			'songPosition', 0, Math.round(songLength));
		timeBar.scrollFactor.set();
		timeBar.createFilledBar(FlxColor.BLACK, FlxColor.WHITE);
		timeBar.alpha = 0;
		timeGroup.add(timeBar);
		timeGroup.add(timeText);

		if (PlayerPrefs.timeType != 'Disabled') {
			FlxTween.tween(timeBG, {alpha: 1}, 0.5);
			FlxTween.tween(timeBar, {alpha: 1}, 0.5);
			FlxTween.tween(timeText, {alpha: 1}, 0.5);
		}
	}

	var debugNum:Int = 0;

	public function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());

		var songData = SONG;
		Conductor.changeBPM(songData.bpm);

		curSong = songData.song;
		trace(songData.speed);

		songSpeed = songData.speed;

		if (SONG.needsVoices)
			vocals = new FlxSound().loadEmbedded(Paths.voices(CoolUtil.spaceToDash(PlayState.SONG.song)));
		else
			vocals = new FlxSound();

		FlxG.sound.list.add(vocals);

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var playerCounter:Int = 0;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped
		for (section in noteData)
		{
			var coolSection:Int = Std.int(section.lengthInSteps / 4);

			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var playerData = Std.int(songNotes[1] / 4);
				var daNoteData:Int = Std.int(songNotes[1] % 4);
				var noteLane:Int = playerData;

				if (playerData > numbOfStrums)
					playerData = numbOfStrums;

				var gottaHitNote:Bool = false;

				if (noteLane <= 2) {
					gottaHitNote = !section.mustHitSection;

					if (!gottaHitNote)
						switch (noteLane) {
							case 0:
								noteLane = 1;
							case 1 :
								noteLane = 0;
						}
				}

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;
				if (daNoteData > -1) {
					var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote, false, false, Std.string(songNotes[3]), false, noteLane);
					swagNote.sustainLength = songNotes[2];
					swagNote.playerLane = playerLane;
					swagNote.scrollFactor.set();

					var susLength:Float = swagNote.sustainLength;

					susLength = susLength / Conductor.stepCrochet;

					unspawnNotes.push(swagNote);

					for (susNote in 0...Math.floor(susLength))
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

						var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + Conductor.stepCrochet, daNoteData, oldNote, true, gottaHitNote, songNotes[3], false, noteLane);
						sustainNote.playerLane = playerLane;
						sustainNote.scrollFactor.set();
						if (daNoteData > -1) {
							unspawnNotes.push(sustainNote);
						}
					}

					if (swagNote.isPlayer && !swagNote.isSustainNote)
						totalNotes++;
				}
			}
			daBeats += 1;
		}

		unspawnNotes.sort(sortByShit);

		for (i in 0...unspawnNotes.length) {
			var nextNote:Note = null;
			var curNote:Note = unspawnNotes[i];

			if (unspawnNotes[i + 1] != null)
				nextNote = unspawnNotes[i + 1];

			if (nextNote != null) {
				if (curNote.strumTime == nextNote.strumTime && (nextNote.noteData == curNote.noteData))
					unspawnNotes.remove(nextNote);
			}
		}//Get rid of stacked notes;

		generatedMusic = true;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);

	public function regenStrums(){
		if (strumLines != null) {
			strumLines.forEach(function(strumline:Strum){
				strumLines.remove(strumline);
			});
		}

		if (SONG.numbPlayers <= 0)
			SONG.numbPlayers = 2;

		if (SONG.numbPlayers > 2)
		{

			numbOfStrums = SONG.numbPlayers;
			for (i in 0...SONG.numbPlayers){
				var playerNumb:Int = i + 1;
				var strumLine:Strum = new Strum(0, this, (playerNumb == playerLane ? bfNoteStyle : dadNoteStyle), null, PlayerPrefs.downscroll, i);
				strumLines.add(strumLine);
				for (i in 0...3)
					strumLineNotes.add(strumLine.strums.members[i]);
			}
		}
		else
		{
			numbOfStrums = 2;
			playerStrums = new Strum(0, this, bfNoteStyle, boyfriend, PlayerPrefs.downscroll, 1);
			opponentStrums = new Strum(0, this, dadNoteStyle, dad, PlayerPrefs.downscroll, 0);

			strumLines.add(opponentStrums);
			strumLines.add(playerStrums);
		}

		for (i in 0...strumLines.length) {
			if (strumLines.members[i].strumID != playerLane)
				strumLines.members[i].autoPlay = true;
		}
	}

	function tweenCamIn():Void {
		FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});
	}

	override function openSubState(SubState:FlxSubState) {
		if (paused)
		{
			if (FlxG.sound.music != null) {
				FlxG.sound.music.pause();
				vocals.pause();
			}

			if (!startTimer.finished)
				startTimer.active = false;
		}

		super.openSubState(SubState);
	}

	override function closeSubState() {
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong) {
				resyncVocals();
			}

			if (!startTimer.finished)
				startTimer.active = true;

			paused = false;
		}

		super.closeSubState();
	}

	function resyncVocals():Void {
		vocals.pause();

		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time;
		vocals.time = Conductor.songPosition;
		vocals.play();
	}

	inline function set_songSpeed(value:Float):Float {
		if (generatedMusic && songSpeed != value) {
			for (daNote in notes) daNote.resizeScale(value);
			for (daNote in unspawnNotes) daNote.resizeScale(value);
		}

		songSpeed = value;

		return value;
	}

	public var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;

	override public function update(elapsed:Float) {
		#if !debug
		perfectMode = false;
		#end

		if (FlxG.keys.justPressed.NINE)
		{
			if (iconP1.animation.curAnim.name == 'bf-old')
				iconP1.animation.play(SONG.player1);
			else
				iconP1.animation.play('bf-old');
		}

		switch (curStage)
		{
			case 'tank':
				moveTank(elapsed);
			case 'philly':
				if (trainMoving)
				{
					trainFrameTiming += elapsed;

					if (trainFrameTiming >= 1 / 24)
					{
						updateTrainPos();
						trainFrameTiming = 0;
					}
				}
				// phillyCityLights.members[curLight].alpha -= (Conductor.crochet / 1000) * FlxG.elapsed;
		}

		super.update(elapsed);

		if (controls.PAUSE && startedCountdown && canPause) {
			persistentUpdate = false;
			persistentDraw = true;
			paused = true;

			openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
		}

		if (persistentUpdate && paused)
			persistentUpdate = false;

		if (FlxG.keys.justPressed.SEVEN)
			FlxG.switchState(new ChartingState());

		hudGroup.iconP1.setGraphicSize(Std.int(FlxMath.lerp(150, iconP1.width, 0.50)));
		hudGroup.iconP2.setGraphicSize(Std.int(FlxMath.lerp(150, iconP2.width, 0.50)));

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		var iconOffset:Int = 26;

		hudGroup.iconP1.x = hudGroup.healthBar.x + (hudGroup.healthBar.width * (FlxMath.remapToRange(hudGroup.healthBar.percent, 0, 100, 100, 0) * 0.01) - iconOffset);
		hudGroup.iconP2.x = hudGroup.healthBar.x + (hudGroup.healthBar.width * (FlxMath.remapToRange(hudGroup.healthBar.percent, 0, 100, 100, 0) * 0.01)) - (hudGroup.iconP2.width - iconOffset);

		if (health > 2)
			health = 2;

		if (health < 0)
			health = 0;

		if (healthBar.percent < 20)
			iconP1.animation.curAnim.curFrame = 1;
		else
			iconP1.animation.curAnim.curFrame = 0;

		if (healthBar.percent > 80)
			iconP2.animation.curAnim.curFrame = 1;
		else
			iconP2.animation.curAnim.curFrame = 0;

		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += FlxG.elapsed * 1000;
				if (Conductor.songPosition >= 0)
					startSong();
			}
		}
		else
		{
			// Conductor.songPosition = FlxG.sound.music.time;
			Conductor.songPosition += FlxG.elapsed * 1000;
			if (!paused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;

					curTime = Math.round(songTime / 1000);

					var numbSeconds:Float = curTime;
					switch (PlayerPrefs.timeType)
					{
						case 'Time Elapsed':
							timeText.text = FlxStringUtil.formatTime(numbSeconds, false) + '/' + timeLength;
						case 'Song Name':
							timeText.text = SONG.song;
					}
				}
			}
		}

		if (generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null)
		{
			if (!stopCamera) {
				if (SONG.notes[Std.int(curStep / 16)].mustHitSection)
					moveCam();
				else
					moveCam(true);
			}
		}

		if (camZooming && PlayerPrefs.camCanZoom)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, 0.95);
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, 0.95);
		}

		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		if (curSong == 'Fresh')
		{
			switch (curBeat)
			{
				case 16:
					camZooming = true;
					gfSpeed = 2;
				case 48:
					gfSpeed = 1;
				case 80:
					gfSpeed = 2;
				case 112:
					gfSpeed = 1;
				case 163:
					// FlxG.sound.music.stop();
					// FlxG.switchState(new TitleState());
			}
		}

		if (curSong == 'Bopeebo')
		{
			switch (curBeat)
			{
				case 128, 129, 130:
					vocals.volume = 0;
					// FlxG.sound.music.stop();
					// FlxG.switchState(new PlayState());
			}
		}

		if (controls.RESET && !PlayerPrefs.disableReset)
			health = 0;

		if (health <= 0 && !practiceMode && !PlayerPrefs.botplay) {
			killPlayer();
			deathCounter += 1;
		}

		if (unspawnNotes[0] != null)
		{
			if (unspawnNotes[0].strumTime - Conductor.songPosition < 1500)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.add(dunceNote);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic)
		{
			notes.forEachAlive(function(daNote:Note)
			{
				
				if ((PlayerPrefs.downscroll && daNote.y < -daNote.height)
					|| (!PlayerPrefs.downscroll && daNote.y > FlxG.height))
				{
					daNote.active = false;
					daNote.visible = false;
				}
				else
				{
					daNote.visible = true;
					daNote.active = true;
				}


				var isPlayer:Bool = daNote.isPlayer;
				var thirdPlayer:Bool = daNote.isThreePlayerNote;
				var isSustain:Bool = daNote.isSustainNote;
				var strumId:Int = daNote.strumID;
				var strumToGo:FlxTypedGroup<StaticArrow>;
				var modifiedX:Float = daNote.modifiedX;
				var goodHit:Bool = daNote.wasGoodHit;
				var prevNote:Note = daNote.prevNote;
				var mustPress:Bool = daNote.mustPress;
				var canBeHit:Bool = daNote.canBeHit;

				var sustainModifier:Float = 0;

				if (strumLines.members[strumId] != null)
					strumToGo = strumLines.members[strumId].strums;
				else
					strumToGo = strumLines.members[0].strums;

				var daNoteY:Float = (strumToGo.members[daNote.noteData].y - (Conductor.songPosition - daNote.strumTime) * (0.45 * FlxMath.roundDecimal(songSpeed, 2)));

				if (PlayerPrefs.downscroll)
					daNoteY = (strumToGo.members[daNote.noteData].y - (Conductor.songPosition - daNote.strumTime) * (-0.45 * FlxMath.roundDecimal(songSpeed, 2)));

				daNote.y = daNoteY;

				if (isSustain)
					sustainModifier = 37;

				if (!daNote.modifiedPos)
					daNote.x = strumToGo.members[daNote.noteData].x + sustainModifier;
				else
					daNote.x = modifiedX;

				if (!daNote.modifiedNote)
				{
					if (daNote.isSustainNote)
						daNote.alpha = strumToGo.members[daNote.noteData].alpha * 0.6;
					else
						daNote.alpha = strumToGo.members[daNote.noteData].alpha;

					daNote.visible = strumToGo.members[daNote.noteData].visible;

					if (!daNote.isSustainNote)
						daNote.angle = strumToGo.members[daNote.noteData].angle;
				}

				var strumLineMid = strumLine.y + Note.swagWidth / 2;

				if (PlayerPrefs.downscroll) {
					if (daNote.isSustainNote
						&& daNote.y - daNote.offset.y <= strumLineMid
						&& ((daNote.strumID != playerLane) || (daNote.wasGoodHit || daNote.prevNote.wasGoodHit)))
					{
						// clipRect is applied to graphic itself so use frame Heights
						var swagRect:FlxRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);

						swagRect.height = (strumLineMid - daNote.y) / daNote.scale.y;
						swagRect.y = daNote.frameHeight - swagRect.height;
						daNote.clipRect = swagRect;
					}
				}
				else {
					if (daNote.isSustainNote
						&& daNote.y + daNote.offset.y <= strumLineMid
						&& ((daNote.strumID != playerLane) || (daNote.wasGoodHit || daNote.prevNote.wasGoodHit)))
					{
						var swagRect:FlxRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);

						swagRect.y = (strumLineMid - daNote.y) / daNote.scale.y;
						swagRect.height -= swagRect.y;
						daNote.clipRect = swagRect;
					}
				}

				if ((daNote.strumID == playerLane) && PlayerPrefs.botplay && canBeHit && !daNote.ignoreNote)
					goodNoteHit(daNote);

				if (goodHit && (daNote.strumID != playerLane))
				{
					if (SONG.song != 'Tutorial')
						camZooming = true;

					opponentHit(daNote);

					if (SONG.needsVoices)
						vocals.volume = 1;
					
					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}

				// WIP interpolation shit? Need to fix the pause issue
				// daNote.y = (strumLine.y - (songTime - daNote.strumTime) * (0.45 * PlayState.SONG.speed));

				var noteLate:Bool = false;

				if (PlayerPrefs.downscroll)
					noteLate = (daNote.y >= strumLine.y + 106);
				else
					noteLate = (daNote.y < -daNote.height);

				if (noteLate && (daNote.strumID == playerLane))
				{
					if ((daNote.isSustainNote && !daNote.sustainHit || !daNote.isSustainNote) && !daNote.ignoreNote && !daNote.hitCauseMiss && !PlayerPrefs.botplay)
					{
						vocals.volume = 0;
						noteMiss(daNote.noteData, daNote);
					}

					daNote.active = false;
					daNote.visible = false;

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}
			});
		}

		if (!inCutscene) {
			keyShit();
		}

		#if debug
		if (FlxG.keys.justPressed.ONE && !endingSong && !startingSong)
			endSong();
		#end

		camNotes.zoom = camHUD.zoom;
	}

	function endSong():Void
	{
		seenCutscene = false;
		canPause = false;
		deathCounter = 0;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;

		if (SONG.validScore && !usedPractice && !PlayerPrefs.botplay) {
			Highscore.saveScore(SONG.song.toLowerCase(), songScore, diffText);
			Highscore.saveSongBeat(SONG.song);
		}

		if (isStoryMode)
		{
			campaignScore += songScore;

			storyPlaylist.remove(storyPlaylist[0]);

			if (storyPlaylist.length <= 0)
			{
				FlxG.sound.playMusic(Paths.music('freakyMenu'));

				transIn = FlxTransitionableState.defaultTransIn;
				transOut = FlxTransitionableState.defaultTransOut;

				FlxG.switchState(new StoryMenuState());

				StoryMenuState.setUnlocked(weekName);

				if (SONG.validScore && !usedPractice) {
					Highscore.saveWeekScore(weekName, campaignScore, diffText);
				}
			}
			else
			{
				var difficulty:String = diffText;

				trace('LOADING NEXT SONG');
				trace(PlayState.storyPlaylist[0].toLowerCase() + difficulty);

				if (SONG.song.toLowerCase() == 'eggnog')
				{
					var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
						-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
					blackShit.scrollFactor.set();
					add(blackShit);
					camHUD.visible = false;

					FlxG.sound.play(Paths.sound('Lights_Shut_off'));
				}

				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
				prevCamFollow = camFollow;

				PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + difficulty, PlayState.storyPlaylist[0]);
				FlxG.sound.music.stop();

				if (PlayState.SONG != null)
					LoadingState.loadAndSwitchState(new PlayState());
				else {
					ErrorState.song = PlayState.storyPlaylist[0];
					FlxG.switchState(new ErrorState());
				}
			}
		}
		else
		{
			trace('WENT BACK TO FREEPLAY??');
			FlxG.switchState(new FreeplayState());
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
		}
	}

	public var totalNotesHit:Int;
	public var ratingAccurracy:Float = 0;

	public function judgeTiming(timing:Float):Timings {
		for (i in 0...timingData.length) {

			if (i == timingData.length - 1)
				break;

			if (timing <= timingData[i].hitWindow)
				return rating;
		}

		return timingData[timingData.length - 1];
	}

	public function popUpScore(daNote:Note):Void
	{
		var daStrumline:Strum = strumLines.members[playerLane];

		var noteDiff:Float = Math.abs(daNote.strumTime - Conductor.songPosition);
		// boyfriend.playAnim('hey');
		vocals.volume = 1;

		var placement:String = Std.string(combo);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.cameras = [camOverlay];
		coolText.screenCenter();
		//

		var rating:FlxSprite = new FlxSprite();
		var score:Int = 0;

		var daRating:Timings = judgeTiming(noteDiff);
		if (!PlayerPrefs.botplay) {
			daNote.rating = daRating.name;
			daRating.increaseCounter();
			score = daRating.score;
		}

		if (daRating.noteSplashes && PlayerPrefs.noteSplashes)
			daStrumline.callNoteSplash(daNote.noteData);

		songScore += score;

		var pixelShitPart1:String = "";
		var pixelShitPart2:String = '';

		if (curStage.startsWith('school')) {
			pixelShitPart1 = 'pixelUI/';
			pixelShitPart2 = '-pixel';
		}

		if (curStage.startsWith('school'))
			rating.loadGraphic(Paths.image('ratings/' + pixelShitPart1 + daRating + pixelShitPart2, 'shared'));
		else
			rating.loadGraphic(Paths.image('ratings/' + daRating, 'shared'));
		rating.cameras = [camOverlay];
		rating.screenCenter();
		rating.x = coolText.x - 50;
		rating.y -= 60;
		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);

		if (curStage.startsWith('school'))
			rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.7));
		else
			rating.setGraphicSize(Std.int(rating.width * 0.7));

		if (curStage.startsWith('school'))
			rating.antialiasing = false;
		else
			rating.antialiasing = PlayerPrefs.antialiasing;

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image('ratings/' + pixelShitPart1 + 'combo' + pixelShitPart2, "shared"));
		comboSpr.cameras = [camOverlay];
		comboSpr.screenCenter();
		comboSpr.x = coolText.x;
		comboSpr.acceleration.y = 600;
		comboSpr.velocity.y -= 150;
		comboSpr.antialiasing = PlayerPrefs.antialiasing;

		comboSpr.velocity.x += FlxG.random.int(1, 10);
		if (curStage.startsWith('school'))
			comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.7));
		else
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
		add(rating);

		if (curStage.startsWith('school')) {
			rating.antialiasing = false;
			comboSpr.antialiasing = false;
		}

		comboSpr.updateHitbox();
		rating.updateHitbox();

		var seperatedScore:Array<Int> = [];

		seperatedScore.push(Math.floor(combo / 100));
		seperatedScore.push(Math.floor((combo - (seperatedScore[0] * 100)) / 10));
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image('ratings/' + pixelShitPart1 + 'num' + Std.int(i) + pixelShitPart2, "shared"));
			numScore.cameras = [camOverlay];
			numScore.screenCenter();
			numScore.x = coolText.x +  (43 * daLoop) - 90;
			numScore.y += 80;

			if (!curStage.startsWith('school'))
			{
				numScore.antialiasing = PlayerPrefs.antialiasing;
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			}
			else
			{
				numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
			}
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);

			if (combo >= 10 || combo == 0)
				add(numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002
			});

			daLoop++;
		}

		coolText.text = Std.string(seperatedScore);

		FlxTween.tween(rating, {alpha: 0}, 0.2, {
			startDelay: Conductor.crochet * 0.001
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
			onComplete: function(tween:FlxTween)
			{
				coolText.destroy();
				comboSpr.destroy();

				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.001
		});

		curSection += 1;
	}

	public var ratingDisplay:String = "?";
	public var accuracyDisplay:String = '0.00';
	public var ratingAccuracy:Float = 0.00

	public function updateScore() {
		var ratingRankStr:String = '';
		var ratingText:String = 'CLEAR';

		if (totalNotesHit < 1)
			ratingDisplay = "?";
		else
			ratingAccuracy = Math.min(1, Math.max(ratingAccurracy / totalNotesHit));

		for (i in 0...ratingRank.length) {
			if (ratingAccuracy < ratingRank[i][1]) {
				ratingRankStr = ratingRank[i][0];
				break;
			}
		}

		if (sicks > 0 && (goods == 0 && bads == 0 && shits == 0)) ratingText = 'PFC';
		else if (goods > 0 && (bads == 0 && shits == 0)) ratingText = 'GFC';
		else if (bads > 0 || shits > 0) ratingText = 'FC';
		else if (misses > 1 && misses < 10) ratingText = 'SDCB';
		else if (misses > 10) ratingText = 'CLEAR';

		ratingDisplay = 'Accuracy: ' + Std.string(ratingAccuracy * 100) + '% [' + ratingText + '] | Rank: ' + ratingRankStr;
	}

	public var ratingRank:Array<Dynamic> = [
		['F', 0],
		['D', 0.6],
		['C', 0.65],
		['B', 0.7],
		['A', 0.8],
		['S', 0.9],
		['S+', 1]
	];

	public function keyShit():Void
	{
		// HOLDING
		var up = controls.NOTE_UP;
		var right = controls.NOTE_RIGHT;
		var down = controls.NOTE_DOWN;
		var left = controls.NOTE_LEFT;

		var upP = controls.NOTE_UP_P;
		var rightP = controls.NOTE_RIGHT_P;
		var downP = controls.NOTE_DOWN_P;
		var leftP = controls.NOTE_LEFT_P;

		var upR = controls.NOTE_UP_R;
		var rightR = controls.NOTE_RIGHT_R;
		var downR = controls.NOTE_DOWN_R;
		var leftR = controls.NOTE_LEFT_R;

		var holdArray:Array<Bool> = [left, down, up, right];
		var pressArray:Array<Bool> = [leftP, downP, upP, rightP];
		var releaseArray:Array<Bool> = [leftR, downR, upR, rightR];

		if (PlayerPrefs.botplay) {
			holdArray = [false, false, false, false];
			pressArray = [false, false, false, false];
			releaseArray = [false, false, false, false];
		}

		// FlxG.watch.addQuick('asdfa', upP);
		if ((pressArray[2] || pressArray[3] || pressArray[1] || pressArray[0]) && !boyfriend.stunned && generatedMusic)
		{
			var possibleNotes:Array<Note> = [];

			var ignoreList:Array<Int> = [];

			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.canBeHit && !daNote.tooLate && !daNote.wasGoodHit)
				{
					// the sorting probably doesn't need to be in here? who cares lol
					possibleNotes.push(daNote);
					possibleNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));
				}
			});

			if (possibleNotes.length > 0)
			{
				var daNote = possibleNotes[0];

				// Jump notes
				if (possibleNotes.length >= 2)
				{
					if (possibleNotes[0].strumTime == possibleNotes[1].strumTime)
					{
						for (coolNote in possibleNotes)
						{
							var controlArray:Array<Bool> = [];

							controlArray = pressArray;

							if (controlArray[coolNote.noteData])
								goodNoteHit(coolNote);
						}
					}
					else if (possibleNotes[0].noteData == possibleNotes[1].noteData)
					{
						var controlArray:Array<Bool> = [];

						controlArray = pressArray;

						if (controlArray[daNote.noteData])
							goodNoteHit(daNote);
					}
					else
					{
						for (coolNote in possibleNotes)
						{
							var controlArray:Array<Bool> = [];

							controlArray = pressArray;
								
							if (controlArray[coolNote.noteData])
								goodNoteHit(coolNote);
						}
					}
				}
				else // regular notes?
				{
					var controlArray:Array<Bool> = [];

					controlArray = pressArray;

					if (controlArray[daNote.noteData])
						goodNoteHit(daNote);
				}
			}
			else if (!PlayerPrefs.ghostTapping)
			{
				for (i in 0...pressArray.length)
					if (pressArray[i])
						noteMiss(i, null);
			}
		}

		if ((holdArray[2] || holdArray[3] || holdArray[1] || holdArray[0]) && !boyfriend.stunned && generatedMusic)
		{
			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.canBeHit && daNote.isSustainNote)
				{
					if (holdArray[daNote.noteData])
						goodNoteHit(daNote);
				}
			});
		}

		var strumLine:Strum = strumLines.members[playerLane];
		var bf:Character = strumLine.strumCharacter;
		strumLine.autoPlay = PlayerPrefs.botplay;

		if (bf != null) { //Character Shit
			bf.isPlayer = !strumLine.autoPlay;

			if (left || down || up || right)
				bf.holdTimer = 0;

			if (!strumLine.autoPlay)
			{
				if (bf.holdTimer > Conductor.stepCrochet * 4 * 0.001 && !up && !down && !right && !left) {
					if (bf.animation.curAnim.name.startsWith('sing') && !bf.animation.curAnim.name.endsWith('miss')) {
						bf.dance();
					}
				}
			}
		}

		for (i in 0...strumLine.strums.length) {
			if (pressArray[i] && strumLine.strums.members[i].animation.curAnim.name != 'confirm')
				strumLine.strums.members[i].playAnim('pressed');
			if (releaseArray[i])
				strumLine.strums.members[i].playAnim('static');
		}
	}

	function pressNoteMiss(direction:Int = 1) {
		health -= 0.05;

		if (combo > 5 && gf.animOffsets.exists('sad')) {
			gf.playAnim('sad');
		}

		combo = 0;
		misses++;

		songScore -= 10;

		FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));

		var strumCharacter:Character = strumLines.members[playerLane].strumCharacter;

		if (strumCharacter != null) {
			switch (direction)
			{
				case 0:
					strumCharacter.playAnim('singLEFTmiss', true);
				case 1:
					strumCharacter.playAnim('singDOWNmiss', true);
				case 2:
					strumCharacter.playAnim('singUPmiss', true);
				case 3:
					strumCharacter.playAnim('singRIGHTmiss', true);
			}
		}
	}

	function noteMiss(direction:Int = 1, daNote:Note):Void
	{
		if (daNote == null)
			health -= 0.05;
		else
			health -= daNote.healthLoss;

		if (combo > 5 && gf.animOffsets.exists('sad')) {
			gf.playAnim('sad');
		}

		combo = 0;
		misses++;

		songScore -= 10;

		FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));

		new FlxTimer().start(5 / 60, function(tmr:FlxTimer)
		{
			boyfriend.stunned = false;
		});

		var strumCharacter:Character = strumLines.members[playerLane].strumCharacter;

		if (strumCharacter != null) {
			switch (direction)
			{
				case 0:
					strumCharacter.playAnim('singLEFTmiss', true);
				case 1:
					strumCharacter.playAnim('singDOWNmiss', true);
				case 2:
					strumCharacter.playAnim('singUPmiss', true);
				case 3:
					strumCharacter.playAnim('singRIGHTmiss', true);
			}
		}
	}

	function goodNoteHit(note:Note):Void
	{
		if (SONG.song != 'Tutorial')
			camZooming = true;

		var playerStrum:Strum = strumLines.members[playerLane];

		if (!note.wasGoodHit)
		{
			if (note.hitCauseMiss)
			{
				noteMiss(note.noteData, note);

				note.wasGoodHit = true;

				if (!note.isSustainNote) {
					note.kill();
					notes.remove(note, true);
					note.destroy();
				}

				playerStrum.strums.members[note.noteData].playAnim('confirm', true);

				return;
			}

			health += note.healthGain;

			if (!note.isSustainNote) {
				popUpScore(note);
				combo += 1;
			}

			note.noteHit = true;

			var useAltAnim:Bool = false;

			if (note.noteType == 'Alt-Anim' || note.noteType == 'Alt Anim')
				useAltAnim = true;

			if (lastNoteHit != null) {
				if (!lastNoteHit.isSustainNote && lastNoteHit.strumTime == note.strumTime) {
					if (playerStrum.strumCharacter != null && playerStrum.strumCharacter.animation.curAnim.name.startsWith('sing'))
						note.canGhost = true;
				}
			}

			playerStrum.playCharAnim(note.noteData, useAltAnim, !note.noAnim, false, note.canGhost);
			playerStrum.strums.members[note.noteData].playAnim('confirm', true);

			note.wasGoodHit = true;
			vocals.volume = 1;

			if (note.isSustainNote) {
				note.sustainHit = true;
			}

			lastNoteHit = note;

			if (!note.isSustainNote)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}
	}

	public function doGhost(char:Character, animName:String = '', isOpponent:Bool = true) {
		var ghost:FlxSprite = new FlxSprite(0, 0);
		var character:Character = char;
		var ghostSprite:FlxTypedGroup<FlxSprite> = char.ghostGroup;

		if (character != null) {
				var animData:Array<Dynamic> = character.animOffsets.get(animName);
				ghost.frames = character.frames;
				ghost.animation.copyFrom(character.animation);
				ghost.x = character.x;
				ghost.y = character.y;
				ghost.animation.play(animName, true);
				ghost.offset.set(animData[0], animData[1]);
				ghost.flipX = character.flipX;
				ghost.flipY = character.flipY;
				ghost.visible = character.visible;
				ghost.color = FlxColor.fromRGB(character.healthColors[0], character.healthColors[1], character.healthColors[2]);
				ghost.blend = LIGHTEN;
				ghostSprite.add(ghost);

				new FlxTimer().start(0.5, function(tmr:FlxTimer){
					var x:Float = 0;
					var y:Float = 0;

					if (animName.endsWith('LEFT'))
						x = -20;
					else if (animName.endsWith('RIGHT'))
						x = 20;
					else if (animName.endsWith('DOWN'))
						y = 20;
					else if (animName.endsWith('UP'))
						y = -20;

					if (y > 0 || y < 0)
						FlxTween.tween(ghost, {y: ghost.y + y}, 0.7);
					else
						FlxTween.tween(ghost, {x: ghost.x + x}, 0.7);

					var ghostTween:FlxTween = FlxTween.tween(ghost, {alpha: 0}, 0.7, {
						ease: FlxEase.linear,
						onComplete: function(tween:FlxTween) {
							ghostSprite.remove(ghost);
						}
					});

				});
		}
	}

	var fastCarCanDrive:Bool = true;

	function resetFastCar():Void
	{
		fastCar.x = -12600;
		fastCar.y = FlxG.random.int(140, 250);
		fastCar.velocity.x = 0;
		fastCarCanDrive = true;
	}

	function fastCarDrive()
	{
		FlxG.sound.play(Paths.soundRandom('carPass', 0, 1), 0.7);

		fastCar.velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;
		fastCarCanDrive = false;
		new FlxTimer().start(2, function(tmr:FlxTimer)
		{
			resetFastCar();
		});
	}

	var trainMoving:Bool = false;
	var trainFrameTiming:Float = 0;

	var trainCars:Int = 8;
	var trainFinishing:Bool = false;
	var trainCooldown:Int = 0;

	function trainStart():Void
	{
		trainMoving = true;
		if (!trainSound.playing)
			trainSound.play(true);
	}

	var startedMoving:Bool = false;

	function updateTrainPos():Void
	{
		if (trainSound.time >= 4700)
		{
			startedMoving = true;
			gf.playAnim('hairBlow');
		}

		if (startedMoving)
		{
			phillyTrain.x -= 400;

			if (phillyTrain.x < -2000 && !trainFinishing)
			{
				phillyTrain.x = -1150;
				trainCars -= 1;

				if (trainCars <= 0)
					trainFinishing = true;
			}

			if (phillyTrain.x < -4000 && trainFinishing)
				trainReset();
		}
	}

	function trainReset():Void
	{
		gf.playAnim('hairFall');
		phillyTrain.x = FlxG.width + 200;
		trainMoving = false;
		// trainSound.stop();
		// trainSound.time = 0;
		trainCars = 8;
		trainFinishing = false;
		startedMoving = false;
	}

	function lightningStrikeShit():Void
	{
		FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
		halloweenBG.playAnim('lightning');

		lightningStrikeBeat = curBeat;
		lightningOffset = FlxG.random.int(8, 24);

		boyfriend.playAnim('scared', true);
		gf.playAnim('scared', true);
	}

	override function stepHit()
	{
		super.stepHit();
		if (FlxG.sound.music.time > Conductor.songPosition + 20 || FlxG.sound.music.time < Conductor.songPosition - 20) {
			resyncVocals();
		}
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;

	override function beatHit()
	{
		super.beatHit();

		if (generatedMusic) {
			notes.sort(FlxSort.byY, FlxSort.DESCENDING);
		}

		if (SONG.notes[Math.floor(curStep / 16)] != null) {
			if (SONG.notes[Math.floor(curStep / 16)].changeBPM) {
				Conductor.changeBPM(SONG.notes[Math.floor(curStep / 16)].bpm);
			}
		}
		wiggleShit.update(Conductor.crochet);

		if (curSong.toLowerCase() == 'milf' && curBeat >= 168 && curBeat < 200 && camZooming && FlxG.camera.zoom < 1.35){
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
		}

		if (camZooming && FlxG.camera.zoom < 1.35 && 
			curBeat % 4 == 0 && PlayerPrefs.camCanZoom) {
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
		}

		iconP1.setGraphicSize(Std.int(iconP1.width + 30));
		iconP2.setGraphicSize(Std.int(iconP2.width + 30));

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		for (i in 0...strumLines.length)
			strumLines.members[i].onBeat(curBeat);

		var gfIdle:Int = gf.idleOnBeat;

		if (curBeat % gfIdle == 0 && !gf.usedOnStrum)
			gf.dance();

		if (!boyfriend.usedOnStrum && curBeat % boyfriend.idleOnBeat == 0)
			boyfriend.dance();

		if (!dad.usedOnStrum && curBeat % dad.idleOnBeat == 0)
			dad.dance();

		if (curBeat % 8 == 7 && curSong == 'Bopeebo')
			boyfriend.playAnim('hey', true);

		if (curBeat % 16 == 15 && SONG.song == 'Tutorial' && dad.curCharacter == 'gf' && curBeat > 16 && curBeat < 48) {
			boyfriend.playHey();
			dad.playHey();
		}

		switch (curStage)
		{
			case 'tank':
				tankWatchtower.dance();

				foregroundSprites.forEach(function(spr:BGSprite)
				{
					spr.dance();
				});
			case 'school':
				if (bgGirls != null)
					bgGirls.dance();

			case 'mall':
				upperBoppers.animation.play('bop', true);
				bottomBoppers.animation.play('bop', true);
				santa.animation.play('idle', true);

			case 'limo':
				grpLimoDancers.forEach(function(dancer:BackgroundDancer)
				{
						dancer.dance();
				});

				if (FlxG.random.bool(10) && fastCarCanDrive)
					fastCarDrive();
			case "philly":
				if (!trainMoving)
					trainCooldown += 1;

				if (curBeat % 4 == 0)
				{
					phillyCityLights.forEach(function(light:FlxSprite)
					{
						light.visible = false;
					});

					curLight = FlxG.random.int(0, phillyCityLights.length - 1);

					phillyCityLights.members[curLight].visible = true;
					// phillyCityLights.members[curLight].alpha = 1;
				}

				if (curBeat % 8 == 4 && FlxG.random.bool(30) && !trainMoving && trainCooldown > 8)
				{
					trainCooldown = FlxG.random.int(-4, 0);
					trainStart();
				}
		}

		if (isHalloween && FlxG.random.bool(10) && curBeat > lightningStrikeBeat + lightningOffset) {
			lightningStrikeShit();
		}
	}

	var curLight:Int = 0;

	public function moveCam(isOpponent:Bool = false)
	{
		if (isOpponent) {
			var offsetY:Float = dad.camOffset[1];
			var offsetX:Float = dad.camOffset[0];

			camFollow.setPosition(dad.getMidpoint().x + 150 + offsetX, dad.getMidpoint().y - 100 + offsetY);

			if (SONG.song.toLowerCase() == 'tutorial' && isOpponent && dad.curCharacter == 'gf') {
				tweenCamIn();
			}
		}
		else
		{
			var offsetY:Float = boyfriend.camOffset[1];
			var offsetX:Float = boyfriend.camOffset[0];

			camFollow.setPosition(boyfriend.getMidpoint().x - 100 + offsetX, boyfriend.getMidpoint().y - 100 + offsetY);

			if (SONG.song.toLowerCase() == 'tutorial' && dad.curCharacter == 'gf'){
				FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});
			}
		}
	}

	public function opponentHit(daNote:Note) {
		var strumList:Strum = strumLines.members[daNote.strumID];

		daNote.noteHit = true;
		var useAltAnim:Bool = false;

		if (daNote.noteType == 'Alt-Anim' || daNote.noteType == 'Alt Anim')
			useAltAnim = true;

		if (lastBotHits[daNote.strumID] != null)
			if (!lastBotHits[daNote.strumID].isSustainNote && lastBotHits[daNote.strumID].strumTime == daNote.strumTime)
				daNote.canGhost = true;

		if (strumList != null && !daNote.hitCauseMiss){
			strumList.strums.members[daNote.noteData].playAnim('confirm', true);
			strumList.playCharAnim(daNote.noteData, useAltAnim, !daNote.noAnim, true, daNote.canGhost);
		}

		lastBotHits[daNote.strumID] = daNote;
	}

	public function addCamera(cam:FlxCamera, camID:String = '') {
		FlxG.cameras.add(cam);
		if (camID != null && camID != '')
			playStatecams.set(camID, cam);
	}

	public function cameraFromString(camName:String):FlxCamera {
		if (playStatecams.get(camName) == null)
			return camGame;

		return playStatecams.get(camName);
	}

	public function killPlayer()
	{
		boyfriend.stunned = true;

		persistentUpdate = false;
		persistentDraw = false;
		paused = true;

		vocals.stop();
		FlxG.sound.music.stop();

		openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
			
		#if desktop
		DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + " (" + storyDifficultyText + ")", iconRPC);
		#end
	}

	public function getBehindPos():Int {
		var index:Int = members.indexOf(gfGroup);
		var dadIndex:Int = members.indexOf(dadGhosts);
		var bfIndex:Int = members.indexOf(bfGhosts);

		if (bfIndex < index)
			index = bfIndex;

		if (dadIndex < bfIndex)
			index = dadIndex;
			
		return index;
	}

	public function changeCharacter(name:String, id:Int = 0) {
		switch (id) {
			case 0:
				var lastAlpha:Float = boyfriend.alpha;
				boyfriend.alpha = 0.0001;
				if (!bfChars.exists(newCharacter))
				{
					var newChar:Boyfriend = new Boyfriend(0, 0, newCharacter);
					newChar.setPosition(boyfriendX + newChar.positionOffset[0], boyfriendY + newChar.positionOffset[1]);
					addCharacter(newChar);
					newChar.alpha = 0.00001;
					bfChars.set(newCharacter, newChar);
				}
				remove(boyfriend.ghostGroup);
				boyfriend = bfChars.get(newCharacter);
				boyfriend.alpha = lastAlpha;
				if (playerStrums != null)
					playerStrums.changeCharacter(boyfriend);
				else
					strumLines.members[playerLane].changeCharacter(boyfriend);
				iconP1.changeIcon(newCharacter, true, null);
			case 1:
				var lastAlpha:Float = dad.alpha;
				dad.alpha = 0.0001;
				if (!dadChars.exists(newCharacter))
				{
					var newChar:Character = new Character(0, 0, newCharacter);
					newChar.setPosition(dadX + newChar.positionOffset[0], dadY + newChar.positionOffset[1]);
					addCharacter(newChar);
					newChar.alpha = 0.00001;
					dadChars.set(newCharacter, newChar);
				}
				remove(dad.ghostGroup);
				dad = dadChars.get(newCharacter);
				dad.alpha = lastAlpha;
				if (opponentStrums != null)
					opponentStrums.changeCharacter(dad);
				else
					strumLines.members[0].changeCharacter(dad);
				iconP2.changeIcon(newCharacter, false, null);
			case 2:
				var lastAlpha:Float = gf.alpha;
				gf.alpha = 0.0001;
				if (!gfChars.exists(newCharacter))
				{
					var newChar:Character = new Character(0, 0, newCharacter);
					newChar.setPosition(gfX + newChar.positionOffset[0], gfY + newChar.positionOffset[1]);
					addCharacter(newChar);
					newChar.alpha = 0.00001;
					startCharacterScript(newChar.curCharacter);
					gfChars.set(newCharacter, newChar);
				}
				if (strumLines.members[2] != null)
					strumLines.members[2].strumCharacter = gf;

				gf = gfChars.get(newCharacter);
				gf.alpha = lastAlpha;
		}
	}
}