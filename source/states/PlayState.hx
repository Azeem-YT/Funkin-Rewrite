package states;

import flixel.FlxState;
//import WiggleEffect.WiggleEffectType;
import data.Song.SwagSong;
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
import flixel.group.FlxGroup;
import flxanimate.FlxAnimate;
import hxCodec.*;
import substates.*;
import engine.*;
import gameObjects.notes.Strum.StaticArrow;
import gameObjects.notes.*;
import gameObjects.dialogue.*;
import gameObjects.*;
import data.*;
import shaders.*;

import data.Section.SwagSection;

import data.Stage.StageData;

import mappedEvents.*;
import mappedEvents.Event.EventData;

#if ALLOW_HSCRIPT
import modding.HScript;
#end

#if ALLOW_LUA
import modding.LuaState;
#end

#if sys
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

class PlayState extends MusicBeatState
{
	public static var instance:PlayState = null;
	public static var SONG:SwagSong = null;
	public static var EVENTS:EventData = null;
	public static var curStage:String = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	//Lua & Hscript Shit
	#if ALLOW_LUA
	public static var luaSprites:Map<String, LuaSprite> = new Map<String, LuaSprite>();
	public static var luaTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public static var luaSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public static var luaTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public static var luaCameras:Map<String, LuaCamera> = new Map<String, LuaCamera>();
	public static var luaShaders:Map<String, Array<String>> = new Map<String, Array<String>>();
	#end
	public static var globalVariables:Map<String, Dynamic> = new Map<String, Dynamic>();
	public static var playStatecams:Map<String, FlxCamera> = new Map<String, FlxCamera>();

	#if sys
	public static var cameraShaders:Map<String, FlxRuntimeShader> = new Map<String, FlxRuntimeShader>();
	#end
	
	public static var positionMap:Map<String, Array<Float>> = new Map<String, Array<Float>>();

	public static var bfChars:Map<String, Boyfriend> = new Map<String, Boyfriend>();
	public static var gfChars:Map<String, Character> = new Map<String, Character>();
	public static var dadChars:Map<String, Character> = new Map<String, Character>();

	public static var boyfriendGroup:FlxSpriteGroup;
	public static var dadGroup:FlxSpriteGroup;
	public static var gfGroup:FlxSpriteGroup;

	public static var practiceMode:Bool = false;
	public static var deathCounter:Int = 0;
	public static var practiceUsed:Bool = false;
	public static var isPixelNotes:Bool = false;

	public static var isDead:Bool = false;

	public static var dad:Character;
	public static var gf:Character;
	public static var boyfriend:Boyfriend;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var lastNoteHit:Note = null;
	public var lastBotHits:Array<Note> = [];
	public var eventArray:Array<Event> = [];
	public static var totalNotes:Int = 0;

	public static var strumLine:FlxSprite;
	public var curSection:Int = 0;

	public var camFollow:FlxObject;
	public var camPos:FlxPoint;
	public var lightFadeShader:BuildingShaders;

	public static var prevCamFollow:FlxObject;

	public static var strumLineNotes:FlxTypedGroup<StaticArrow>;
	public static var strumLines:FlxTypedGroup<Strum>;
	public static var playerStrums:Strum;
	public static var opponentStrums:Strum;
	public static var gfStrums:Strum;

	public static var playerLane:Int = 1;
	public var numbOfStrums:Int = 2;

	public var camZooming:Bool = false;
	public var curSong:String = "";

	public var gfSpeed:Int = 1;
	public var health:Float = 1;
	public var combo:Int = 0;
	public var sicks:Int = 0;
	public var goods:Int = 0;
	public var bads:Int = 0;
	public var shits:Int = 0;
	public var misses:Int = 0;
	public var zoomSpeed:Int = 4;

	public static var timingData:Array<Timings> = [];

	public var songLength:Float = 0;

	public var libraryToUse:String = null;

	public static var hudGroup:HudGroup;

	public var generatedMusic:Bool = false;
	public var startingSong:Bool = false;

	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camNotes:FlxCamera;
	public var camOverlay:FlxCamera;
	public var skipCountdown:Bool = false;

	var dialogue:Array<String> = ['blah blah blah', 'coolswag'];

	public static var seenCutscene:Bool = false;

	public var vocals:FlxSound;

	public var usedPractice:Bool = false;

	//Week 2
	public var halloweenBG:EngineSprite;
	public var isHalloween:Bool = false;
	public var halloweenLevel:Bool = false;

	//Week 3
	public var phillyCityLights:FlxTypedGroup<EngineSprite>;
	public var phillyTrain:EngineSprite;
	public var trainSound:FlxSound;

	//Week 4
	public var limo:EngineSprite;
	public var grpLimoDancers:FlxTypedGroup<BackgroundDancer>;
	public var fastCar:FlxSprite;

	//Week 5
	public var upperBoppers:EngineSprite;
	public var bottomBoppers:EngineSprite;
	public var santa:EngineSprite;

	//Week 6
	public var bgGirls:BackgroundGirls;
	//public var wiggleShit:WiggleEffect = new WiggleEffect();

	//Week 7
	public var foregroundSprites:FlxTypedGroup<BGSprite>;
	public var tankGround:BGSprite;
	public var tankWatchtower:BGSprite;
	public var smokeLeft:BGSprite;
	public var smokeRight:BGSprite;
	public var tankRuins:BGSprite;
	public var tankBuildings:BGSprite;
	public var tankMountains:BGSprite;
	public var tankClouds:BGSprite;
	public var tankSky:BGSprite;
	public var tankRolling:BGSprite;
	public var tankmanRun:FlxTypedGroup<TankmenBG>;

	var tankCutscene:CutsceneGroup;

	public static var weekName:String = "";
	public var songHasInfo:Bool = false;

	private var endingSong:Bool = false;

	#if ALLOW_HSCRIPT
	public static var hscriptArray:Array<HScript> = [];
	#end

	#if ALLOW_LUA
	public static var luaArray:Array<LuaState> = [];
	#end

	var talking:Bool = true;
	public var songScore:Int = 0;
	public var scoreTxt:FlxText;
	public var scoreDivider:String = ' | ';

	public static var curElapsed:Float = 0;

	public static var campaignScore:Int = 0;

	public static var defaultCamZoom:Float = 1.05;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;

	public var doof:DialogueBox;
	public var dialogueBox:DialogueState;

	public var inCutscene:Bool = false;

	public var songStarted:Bool;
	public static var skipArrowTween:Bool = false;
	public var stopCamera:Bool = false;

	public var songSpeed(default, set):Float = 1;
	public var curTime:Float = 0;

	public var timeText:FlxText;
	public var timeBG:FlxSprite;
	public var timeBar:FlxBar;
	public var timeLength:String = "0:00";
	public var timeGroup:FlxSpriteGroup;

	public static var diffArray:Array<String> = ['easy', 'normal', 'hard'];
	public var diffText:String = '';

	public var skipIntro:Bool = false;
	public static var arrowDirs:Array<String> = ['left', 'down', 'up', 'right'];

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

		isDead = false;

		bfChars.clear();
		gfChars.clear();
		dadChars.clear();
		positionMap.clear();

		#if ALLOW_LUA
		luaSprites.clear();
		luaTweens.clear();
		luaSounds.clear();
		luaTimers.clear();
		luaShaders.clear();
		luaCameras.clear();
		#if sys
		cameraShaders.clear();
		#end
		#end

		globalVariables.clear();
		playStatecams.clear();

		libraryToUse = null;

		camGame = new FlxCamera();
		camNotes = new FlxCamera();
		camNotes.bgColor.alpha = 0;
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camOverlay = new FlxCamera();
		camOverlay.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		playStatecams.set('camGame', camGame);
		addCamera(camNotes, 'camNotes');
		addCamera(camHUD, 'camHUD');
		addCamera(camOverlay, 'camOverlay');

		FlxCamera.defaultCameras = [camGame];

		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null)
			SONG = Song.loadFromJson('tutorial', 'tutorial-hard');

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

		var difficultyText:String = '';

		if (CoolUtil.difficultyArray[storyDifficulty] != null)
			difficultyText = '-' + difficultyText.toLowerCase();

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
		positionMap.set('boyfriend', stageData.boyfriendPos);
		positionMap.set('gf', stageData.gfPos);
		positionMap.set('dad', stageData.dadPos);
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

		var directorys:Array<String> = [Paths.getPreloadPath()];

		#if sys
		directorys.insert(0, Paths.mods());
		#end

		switch (curStage)
		{
			case 'stage':
			{
				curStage = 'stage';

				var bg:EngineSprite = new EngineSprite(-600, -200);
				bg.loadGraphic(Paths.image('stageback', 'shared'));
				bg.antialiasing = FlxG.save.data.antialiasing;
				bg.scrollFactor.set(0.9, 0.9);
				bg.active = false;
				add(bg);

				var stageFront:EngineSprite = new EngineSprite(-650, 600);
				stageFront.loadGraphic(Paths.image('stagefront', 'shared'));
				stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
				stageFront.updateHitbox();
				stageFront.antialiasing = FlxG.save.data.antialiasing;
				stageFront.scrollFactor.set(0.9, 0.9);
				stageFront.active = false;
				add(stageFront);

				var stageCurtains:EngineSprite = new EngineSprite(-500, -300);
				stageCurtains.loadGraphic(Paths.image('stagecurtains', 'shared'));
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

				var bg:EngineSprite = new EngineSprite(-100);
				bg.loadGraphic(Paths.image('philly/sky', 'week3'));
				bg.scrollFactor.set(0.1, 0.1);
				add(bg);

				var city:EngineSprite = new EngineSprite(-10);
				city.loadGraphic(Paths.image('philly/city', 'week3'));
				city.scrollFactor.set(0.3, 0.3);
				city.setGraphicSize(Std.int(city.width * 0.85));
				city.updateHitbox();
				add(city);

				lightFadeShader = new BuildingShaders();

				phillyCityLights = new FlxTypedGroup<EngineSprite>();
				add(phillyCityLights);

				for (i in 0...5)
				{
					var light:EngineSprite = new EngineSprite(city.x);
					light.loadGraphic(Paths.image('philly/win' + i, 'week3'));
					light.scrollFactor.set(0.3, 0.3);
					light.visible = false;
					light.setGraphicSize(Std.int(light.width * 0.85));
					light.updateHitbox();
					light.antialiasing = FlxG.save.data.antialiasing;
					light.shader = lightFadeShader.shader;
					phillyCityLights.add(light);
				}

				var streetBehind:EngineSprite = new EngineSprite(-40, 50);
				streetBehind.loadGraphic(Paths.image('philly/behindTrain', 'week3'));
				add(streetBehind);

				phillyTrain = new EngineSprite(2000, 360);
				phillyTrain.loadGraphic(Paths.image('philly/train', 'week3'));
				add(phillyTrain);

				trainSound = new FlxSound().loadEmbedded(Paths.sound('train_passes', 'shared'));
				FlxG.sound.list.add(trainSound);

				// var cityLights:EngineSprite = new EngineSprite().loadGraphic(AssetPaths.win0.png);

				var street:EngineSprite = new EngineSprite(-40, streetBehind.y);
				street.loadGraphic(Paths.image('philly/street', 'week3'));
				add(street);
			}
			case 'limo':
			{
				curStage = 'limo';

				var skyBG:EngineSprite = new EngineSprite(-120, -50);
				skyBG.loadGraphic(Paths.image('limo/limoSunset', 'week4'));
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

				var overlayShit:EngineSprite = new EngineSprite(-500, -600);
				overlayShit.loadGraphic(Paths.image('limo/limoOverlay', 'week4'));
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

				fastCar = new EngineSprite(-300, 160);
				fastCar.loadGraphic(Paths.image('limo/fastCarLol', 'week4'));
				fastCar.antialiasing = FlxG.save.data.antialiasing;
				// add(limo);
			}
		case 'mall':
			{
				curStage = 'mall';

				var bg:EngineSprite = new EngineSprite(-1000, -500);
				bg.loadGraphic(Paths.image('christmas/bgWalls', 'week5'));
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

				var bgEscalator:EngineSprite = new EngineSprite(-1100, -600);
				bgEscalator.loadGraphic(Paths.image('christmas/bgEscalator', 'week5'));
				bgEscalator.antialiasing = FlxG.save.data.antialiasing;
				bgEscalator.scrollFactor.set(0.3, 0.3);
				bgEscalator.active = false;
				bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
				bgEscalator.updateHitbox();
				add(bgEscalator);

				var tree:EngineSprite = new EngineSprite(370, -250);
				tree.loadGraphic(Paths.image('christmas/christmasTree', 'week5'));
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

				var fgSnow:EngineSprite = new EngineSprite(-600, 700);
				fgSnow.loadGraphic(Paths.image('christmas/fgSnow', 'week5'));
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

				var bg:EngineSprite = new EngineSprite(-400, -500);
				bg.loadGraphic(Paths.image('christmas/evilBG', 'week5'));
				bg.antialiasing = FlxG.save.data.antialiasing;
				bg.scrollFactor.set(0.2, 0.2);
				bg.active = false;
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				add(bg);

				var evilTree:EngineSprite = new EngineSprite(300, -300);
				evilTree.loadGraphic(Paths.image('christmas/evilTree', 'week5'));
				evilTree.antialiasing = FlxG.save.data.antialiasing;
				evilTree.scrollFactor.set(0.2, 0.2);
				add(evilTree);

				var evilSnow:EngineSprite = new EngineSprite(-200, 700);
				evilSnow.loadGraphic(Paths.image("christmas/evilSnow", 'week5'));
				evilSnow.antialiasing = FlxG.save.data.antialiasing;
				add(evilSnow);
			}
		case 'school':
			{
				curStage = 'school';

				var bgSky = new EngineSprite();
				bgSky.loadGraphic(Paths.image('weeb/weebSky', 'week6'));
				bgSky.scrollFactor.set(0.1, 0.1);
				add(bgSky);

				var repositionShit = -200;

				var bgSchool:EngineSprite = new EngineSprite(repositionShit, 0);
				bgSchool.loadGraphic(Paths.image('weeb/weebSchool', 'week6'));
				bgSchool.scrollFactor.set(0.6, 0.90);
				add(bgSchool);

				var bgStreet:EngineSprite = new EngineSprite(repositionShit);
				bgStreet.loadGraphic(Paths.image('weeb/weebStreet', 'week6'));
				bgStreet.scrollFactor.set(0.95, 0.95);
				add(bgStreet);

				var fgTrees:EngineSprite = new EngineSprite(repositionShit + 170, 130);
				fgTrees.loadGraphic(Paths.image('weeb/weebTreesBack', 'week6'));
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

				libraryToUse = 'week7';

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

				tankCutscene = new CutsceneGroup(SONG.song.toLowerCase(), false, this);
			}
		}

		camPos = new FlxPoint(dad.getGraphicMidpoint().x, dad.getGraphicMidpoint().y);

		add(gfGroup);

		if (tankCutscene != null) {
			tankCutscene.addLayer('gf');
			tankCutscene.addLayer('bf');
		}

		switch (gfVersion)
		{
			case 'pico-speaker':
				var tempTankman:TankmenBG = new TankmenBG(20, 500, true);
				tempTankman.strumTime = 10;
				tempTankman.resetShit(20, 600, true);
				tankmanRun.add(tempTankman);

				for (i in 0...TankmenBG.animationNotes.length)
				{
					if (FlxG.random.bool(16))
					{
						var tankman:TankmenBG = tankmanRun.recycle(TankmenBG);
						// new TankmenBG(500, 200 + FlxG.random.int(50, 100), TankmenBG.animationNotes[i][1] < 2);
						tankman.strumTime = TankmenBG.animationNotes[i][0];
						tankman.resetShit(500, 200 + FlxG.random.int(50, 100), TankmenBG.animationNotes[i][1] < 2);
						tankmanRun.add(tankman);
					}
				}
		}

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

		startHscriptOnFolder('hscript/');
		startLuaOnFolder('scripts/');

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

		startHscriptOnFolder('note_types/');
		startLuaOnFolder('note_types/');

		regenStrums();

		camFollow = new FlxObject(0, 0, 1, 1);
		moveCam();

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
		if (doof != null)
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
					camNotes.visible = false;

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
							camNotes.visible = true;
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
					ughIntro();
				case 'guns':
					gunsIntro();
				case 'stress':
					stressIntro();
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

		timingData.push(new Timings('sick'));
		
		var goodRating:Timings = new Timings('good');
		goodRating.noteSplashes = false;
		goodRating.score = 100;
		goodRating.accuracyMod = 0.75;
		goodRating.healthMod = 0.75;
		timingData.push(goodRating);

		var badRating:Timings = new Timings('bad');
		badRating.noteSplashes = false;
		badRating.score = 50;
		badRating.accuracyMod = 0.5;
		badRating.healthMod = 0.5;
		timingData.push(badRating);

		var shitRating:Timings = new Timings('shit');
		shitRating.noteSplashes = false;
		shitRating.score = -100;
		shitRating.accuracyMod = -1;
		shitRating.healthMod = -1;
		timingData.push(shitRating);
	}

	function ughIntro() 
	{
		inCutscene = true;

		FlxG.sound.playMusic(Paths.music('DISTORTO'), 0);
		FlxG.sound.music.fadeIn(5, 0, 0.5);

		camHUD.visible = false;
		camNotes.visible = false;

		dad.visible = false;
		add(tankCutscene);
		tankCutscene.startCutscene('ugh');
	}

	function gunsIntro() 
	{
		inCutscene = true;

		moveCam(true);
		FlxG.sound.playMusic(Paths.music('DISTORTO'), 0);
		FlxG.sound.music.fadeIn(5, 0, 0.5);

		camHUD.visible = false;
		camNotes.visible = false;

		add(tankCutscene);
		tankCutscene.startCutscene('guns');
	}

	function stressIntro()
	{
		inCutscene = true;

		camHUD.visible = false;
		camNotes.visible = false;

		add(tankCutscene);
		tankCutscene.startCutscene('stress');
	}

	public function endTheScene() {
		if (tankCutscene != null) {
			remove(tankCutscene);
		}

		moveCam(true);
		camHUD.visible = true;
		camNotes.visible = true;
		startCountdown();
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

	public static function addCharacter(char:Character, isGF:Bool = false) {
		var charGroup:FlxSpriteGroup = dadGroup;

		if (Std.isOfType(char, Boyfriend)) {
			charGroup = boyfriendGroup;
		}

		if (char == gf) {
			charGroup = gfGroup;
		}

		if (char != null && charGroup != null) {
			charGroup.add(char.ghostGroup);
			char.ghostGroup.setPosition(0, 0); //crazy
			charGroup.add(char);
		}

		instance.startPosition(char, isGF);
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
		#if sys
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
		#else
		startCountdown();
		#end
	}

	public function playVideo(fileName:String) {
		#if sys
		var video:VideoHandler = new VideoHandler();
		video.finishCallback = function() {
			trace('Video $fileName has finished!');
		}
		video.playVideo(Paths.video(fileName));
		trace('Playing Video $fileName');
		#else
		startCountdown();
		#end
	}

	public function startDialogue(jsonPath:String = null) {
		if (jsonPath != null) {
			var rawJson = null;

			#if sys
			if (FileSystem.exists(jsonPath))
				rawJson = File.getContent(jsonPath);
			#else
			if (Assets.exists(jsonPath))
				rawJson = Assets.getText(jsonPath);
			#end

			if (rawJson != null) {
				inCutscene = true;
				var jsonData:DialogueState.JsonData = Json.parse(rawJson);

				if (jsonData.dialogueData.length <= 0) {
					startCountdown();
					trace('Error! No dialogue lines found!');
					return;
				}

				dialogueBox = new DialogueState(jsonData);
				dialogueBox.cameras = [camOverlay];
				add(dialogueBox);
				if(endingSong) {
					dialogueBox.finishThing = function() {callLua('onDialogueFinish', []); endSong();};
				}
				else {
					dialogueBox.finishThing = function() {callLua('onDialogueFinish', []); startCountdown();};
				}
			} else {
				trace('Dialogue File is not found or has an error!');
				FlxG.log.warn('Dialogue File is not found or has an error!');
				if(endingSong) {
					callLua('onDialogueFinish', []);
					endSong();
				}
				else {
					callLua('onDialogueFinish', []);
					startCountdown();
				}
			}

		}
		else {
			trace('Dialogue File is not found or has an error!');
			FlxG.log.warn('Dialogue File is not found or has an error!');

			if(endingSong) {
				callLua('onDialogueFinish', []);
				endSong();
			}
			else {
				callLua('onDialogueFinish', []);
				startCountdown();
			}

		}
	}

	function schoolIntro(?dialogueBox:DialogueBox):Void
	{
		var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		add(black);

		var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();

		var senpaiEvil:FlxSprite = new FlxSprite();
		senpaiEvil.frames = Paths.getSparrowAtlas('weeb/senpaiCrazy');
		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * daPixelZoom));
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();
		senpaiEvil.x += senpaiEvil.width / 5;

		camFollow.setPosition(camPos.x, camPos.y);

		if (SONG.song.toLowerCase() == 'roses' || SONG.song.toLowerCase() == 'thorns')
		{
			remove(black);

			if (SONG.song.toLowerCase() == 'thorns')
			{
				add(red);
				camHUD.visible = false;
				camNotes.visible = false;
			}
			else
				FlxG.sound.play(Paths.sound('ANGRY'));
			// moved senpai angry noise in here to clean up cutscene switch case lol
		}

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			black.alpha -= 0.15;

			if (black.alpha > 0)
				tmr.reset(0.3);
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
								swagTimer.reset();
							else
							{
								senpaiEvil.animation.play('idle');
								FlxG.sound.play(Paths.sound('Senpai_Dies'), 1, false, null, true, function()
								{
									remove(senpaiEvil);
									remove(red);
									FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function()
									{
										add(dialogueBox);
										camHUD.visible = true;
										camNotes.visible = true;
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
						add(dialogueBox);
				}
				else
					startCountdown();

				remove(black);
			}
		});
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

			}

				swagCounter += 1;
		}, 5);
	}

	var startTimer:FlxTimer;
	var perfectMode:Bool = false;

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	function startSong():Void {
		startingSong = false;
		songStarted = true;
		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		FlxG.sound.playMusic(Paths.inst(CoolUtil.spaceToDash(PlayState.SONG.song)), 1, false);
		FlxG.sound.music.onComplete = endSong;
		vocals.play();

		songLength = FlxG.sound.music.length;

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

	var debugNum:Int = 0;

	public function createTimeBar() {
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

	public function get_events() 
	{
		var jsonData:EventData = EVENTS;

		if (jsonData != null && jsonData.events != null) {
			var eventSections = jsonData.events;
			for (section in EVENTS.events)
			{
				var eventArry:Array<Dynamic> = section.eventsArray;

				for (eventNote in eventArry) {
					var strumTime:Float = eventNote[0];
					var eventNme:String = eventNote[1];
					var value1:String = eventNote[2];
					var value2:String = eventNote[3];

					eventArray.push(new Event(strumTime, eventNme, value1, value2));
				}
			}
		}

		eventArray.sort(sortByTime);
	}

	public function sortByTime(event1:Event, event2:Event):Int
		return FlxSort.byValues(FlxSort.ASCENDING, event1.time, event2.time);

	function generateSong(dataPath:String):Void {
		var songData = SONG;
		Conductor.changeBPM(songData.bpm);

		curSong = songData.song;

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

		eventArray = [];

		if (EVENTS == null) {
			#if sys
			if (FileSystem.exists(Paths.json('data/${SONG.song.toLowerCase()}/events'))) {
				EVENTS = Song.loadEvents(SONG.song);
			}
			#else
			if (Assets.exists(Paths.json('data/${SONG.song.toLowerCase()}/events'))) {
				var jsonData:EventData = Song.loadEvents(SONG.song);
				EVENTS = jsonData;
			}
			#end

			if (EVENTS != null)
				get_events();
		}
		else
			get_events();

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

				if (noteLane <= 1) {
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
					var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote, false, Std.string(songNotes[3]), false, noteLane);
					swagNote.sustainLength = songNotes[2];
					swagNote.playerLane = playerLane;
					swagNote.scrollFactor.set();

					var susLength:Float = swagNote.sustainLength;

					susLength = susLength / Conductor.stepCrochet;

					unspawnNotes.push(swagNote);

					for (susNote in 0...Math.floor(susLength))
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

						var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + Conductor.stepCrochet, daNoteData, oldNote, true, songNotes[3], false, noteLane);
						sustainNote.playerLane = playerLane;
						sustainNote.scrollFactor.set();
						if (daNoteData > -1) {
							swagNote.susNotes.push(sustainNote);
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
				var strumLine:Strum = new Strum(0, this, SONG.arrowTexture, null, PlayerPrefs.downscroll, i);
				strumLines.add(strumLine);
				for (i in 0...3)
					strumLineNotes.add(strumLine.strums.members[i]);
			}
		}
		else
		{
			numbOfStrums = 2;
			playerStrums = new Strum(0, this, SONG.arrowTexture, boyfriend, PlayerPrefs.downscroll, 1);
			opponentStrums = new Strum(0, this, SONG.arrowTexture, dad, PlayerPrefs.downscroll, 0);

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
		if (generatedMusic) {
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

			if (!paused) {
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

		var iconP1:HealthIcon = hudGroup.iconP1;
		var iconP2:HealthIcon = hudGroup.iconP2;
		var healthBar:FlxBar = hudGroup.healthBar;

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
				lightFadeShader.update((Conductor.crochet / 1000) * FlxG.elapsed * 1.5);
				// phillyCityLights.members[curLight].alpha -= (Conductor.crochet / 1000) * FlxG.elapsed;
		}

		callHscript('onUpdate', [elapsed]);
		callLua('onUpdate', [elapsed]);

		super.update(elapsed);

		if (controls.PAUSE && startedCountdown && canPause) {
			persistentUpdate = false;
			persistentDraw = true;
			paused = true;

			openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
		}

		if (FlxG.keys.justPressed.SEVEN)
			FlxG.switchState(new ChartingState());

		if (FlxG.keys.justPressed.EIGHT)
			FlxG.switchState(new EventCharter());

		if (iconP1 != null) {
			iconP1.setGraphicSize(Std.int(FlxMath.lerp(150, iconP1.width, 0.50)));
			iconP1.updateHitbox();
		}

		if (hudGroup.iconP2 != null) {
			hudGroup.iconP2.setGraphicSize(Std.int(FlxMath.lerp(150, iconP2.width, 0.50)));
			iconP2.updateHitbox();
		}

		var iconOffset:Int = 26;

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01) - iconOffset);
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (iconP2.width - iconOffset);

		if (health > 2)
			health = 2;

		if (health < 0)
			health = 0;

		if (hudGroup.healthBar.percent < 20)
			iconP1.animation.curAnim.curFrame = 1;
		else
			iconP1.animation.curAnim.curFrame = 0;

		if (hudGroup.healthBar.percent > 80)
			iconP2.animation.curAnim.curFrame = 1;
		else
			iconP2.animation.curAnim.curFrame = 0;

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
		}

		updateScore();

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

		checkEvent();

		if (!inCutscene) {
			keyShit();
		}

		#if debug
		if (FlxG.keys.justPressed.ONE && !endingSong && !startingSong)
			endSong();
		#end

		camNotes.zoom = camHUD.zoom;

		callHscript('onUpdatePost', [elapsed]);
		callLua('onUpdatePost', [elapsed]);
	}

	public function checkEvent() {
		if (eventArray.length < 1)
			return;

		var strumTime:Float = eventArray[0].time;

		if (Conductor.songPosition < strumTime)
			return;

		var value1:String = eventArray[0].value1;
		var value2:String = eventArray[0].value2;

		if (value1 == null)
			value1 = '';

		if (value2 == null)
			value2 = '';

		var eventName:String = eventArray[0].eventName;

		triggerEvent(eventName, value1, value2);
		eventArray.shift();
	}

	function endSong():Void
	{
		callHscript('onEndSong', []);
		var retValue:Dynamic = callLua('onEndSong', []);

		if (retValue != LuaState.stopFunc) {
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

						switch (SONG.song.toLowerCase()) {
							case 'eggnog':
								var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
								-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
								blackShit.scrollFactor.set();
								add(blackShit);
								camNotes.visible = false;
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
				else {
					trace('WENT BACK TO FREEPLAY??');
					FlxG.switchState(new FreeplayState());
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
				}
		}
	}

	public var totalNotesHit:Int = 0;

	public function judgeTiming(timing:Float):Timings {
		for (i in 0...timingData.length - 1) {

			if (i == timingData.length - 1)
				break;

			if (timing <= timingData[i].hitWindow)
				return timingData[i];
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
		coolText.cameras = [camHUD];
		coolText.screenCenter();
		//

		var rating:FlxSprite = new FlxSprite();
		var score:Int = 0;

		var daRating:Timings = judgeTiming(noteDiff);

		if (!PlayerPrefs.botplay) {
			daNote.rating = daRating.name;
			daRating.increaseCounter();
			ratingAccuracy += daRating.accuracyMod;
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
			rating.loadGraphic(Paths.image('ratings/$pixelShitPart1${daRating.name}$pixelShitPart2', 'shared'));
		else
			rating.loadGraphic(Paths.image('ratings/${daRating.name}', 'shared'));
		rating.cameras = [camHUD];
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

		var comboSpr:FlxSprite = new FlxSprite();
		if (curStage.startsWith('school'))
			comboSpr.loadGraphic(Paths.image('ratings/$pixelShitPart1/combo$pixelShitPart2', 'shared'));
		else
			comboSpr.loadGraphic(Paths.image('ratings/combo', 'shared'));
		comboSpr.cameras = [camHUD];
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
			numScore.cameras = [camHUD];
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
	public var calculatedAccuracy:Float = 0.00;
	public var ratingAccuracy:Float = 0.00;

	public function updateScore() {
		var ratingRankStr:String = '';
		var ratingText:String = '?';

		if (totalNotesHit < 1)
			ratingDisplay = "?";
		else
			calculatedAccuracy = Math.min(1, Math.max(0, ratingAccuracy / totalNotesHit));

		for (i in 0...ratingRank.length) {
			if (ratingAccuracy < ratingRank[i][1]) {
				ratingRankStr = ratingRank[i][0];
				break;
			}
		}

		if (sicks > 0 && (goods == 0 && bads == 0 && shits == 0 && misses == 0)) ratingText = 'PFC';
		else if (goods > 0 && (bads == 0 && shits == 0 && misses == 0)) ratingText = 'GFC';
		else if ((bads > 0 || shits > 0) && misses == 0) ratingText = 'FC';
		else if (misses > 1 && misses < 10) ratingText = 'SDCB';
		else if (misses > 10) ratingText = 'CLEAR';

		hudGroup.scoreTxt.text = 'Score: $songScore | Misses: $misses | Accuracy: ' + Std.string(FlxMath.roundDecimal(calculatedAccuracy * 100, 2)) + '% [$ratingText] | Rank: $ratingRankStr';
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

		callHscript('onPressedNoteMiss', [direction]);
		callLua('onPressedNoteMiss', [direction]);
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

		callHscript('onNoteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
		callLua('onNoteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
		daNote.ignoreSus = true;
	}

	function goodNoteHit(note:Note):Void
	{
		if (SONG.song != 'Tutorial')
			camZooming = true;

		var playerStrum:Strum = strumLines.members[playerLane];

		if (note.stopHit)
			return;

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

			var noteRating:Timings = judgeTiming(Math.abs(note.strumTime - Conductor.songPosition));

			health += note.healthGain * noteRating.healthMod;

			if (!note.isSustainNote) {
				totalNotesHit += 1;
				popUpScore(note);
				combo += 1;
			}

			note.noteHit = true;

			var useAltAnim:Bool = false;

			if (note.noteType == 'Alt-Anim' || note.noteType == 'Alt Anim')
				useAltAnim = true;

			if (lastNoteHit != null) {
				if (!lastNoteHit.isSustainNote && lastNoteHit.strumTime == note.strumTime) {
					note.canGhost = true;
					//note.ignoreSus = true;
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

			callHscript('onGoodNoteHit', [notes.members.indexOf(note), note.noteData, note.noteType, note.isSustainNote]);
			callLua('onGoodNoteHit', [notes.members.indexOf(note), note.noteData, note.noteType, note.isSustainNote]);

			if (!note.isSustainNote) {
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}
	}

	public function doGhost(char:Character, animName:String = '', isOpponent:Bool = true) {
		var ghost:FlxSprite = new FlxSprite(0, 0);
		var character:Character = char;
		var ghostSprite:FlxSpriteGroup = char.ghostGroup;

		if (character != null) {
				var animData:Array<Dynamic> = character.animOffsets.get(animName);
				if (animData == null)
					animData = [0, 0];

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

		callHscript('onStepHit', [curStep]);
		callLua('onStepHit', []);
		setLua('curStep', curStep);
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;

	override function beatHit()
	{
		super.beatHit();

		var iconP1:HealthIcon = hudGroup.iconP1;
		var iconP2:HealthIcon = hudGroup.iconP2;
		var healthBar:FlxBar = hudGroup.healthBar;

		if (generatedMusic) {
			notes.sort(FlxSort.byY, FlxSort.DESCENDING);
		}

		if (SONG.notes[Math.floor(curStep / 16)] != null) {
			if (SONG.notes[Math.floor(curStep / 16)].changeBPM) {
				Conductor.changeBPM(SONG.notes[Math.floor(curStep / 16)].bpm);
			}
		}
		//wiggleShit.update(Conductor.crochet);

		if (camZooming && FlxG.camera.zoom < 1.35 && 
			curBeat % zoomSpeed == 0 && PlayerPrefs.camCanZoom) {
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
					lightFadeShader.reset();

					phillyCityLights.forEach(function(light:EngineSprite)
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

		callHscript('onBeatHit', [curBeat]);
		callLua('onBeatHit', []);
		setLua('curBeat', curBeat);
	}

	var curLight:Int = 0;

	public function moveCam(isOpponent:Bool = false)
	{
		if (isOpponent) {
			var offsetY:Float = dad.camOffset[1];
			var offsetX:Float = dad.camOffset[0];
			var camX:Float = dad.getMidpoint().x + 150 + offsetX;
			var camY:Float = dad.getMidpoint().y - 100 + offsetY;

			if (camFollow.x != camX && camFollow.y != camY) {
				camFollow.setPosition(camX, camY);

				if (SONG.song.toLowerCase() == 'tutorial' && dad.curCharacter == 'gf')
					tweenCamIn();

				callHscript('onCameraMove', [true]);
				callLua('onCameraMove', [true]);
			}
		}
		else
		{
			var offsetY:Float = boyfriend.camOffset[1];
			var offsetX:Float = boyfriend.camOffset[0];
			var camX:Float = boyfriend.getMidpoint().x - 100 + offsetX;
			var camY:Float = boyfriend.getMidpoint().y - 100 + offsetY;

			if (camFollow.x != camX && camFollow.y != camY) {
				camFollow.setPosition(camX, camY);

				if (SONG.song.toLowerCase() == 'tutorial' && dad.curCharacter == 'gf')
					tweenCamOut();
					
				callHscript('onCameraMove', [false]);
				callLua('onCameraMove', [false]);
			}

		}
	}

	public function tweenCamOut()
		return FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});

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

		callHscript('onOpponentHit', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote, daNote.strumID]);
		callLua('onOpponentHit', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote, daNote.strumID]);
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
		callHscript('onDeath', []);
		var retValue:Dynamic = callLua('onDeath', []);
		if (retValue != LuaState.continueFunc) {
			persistentUpdate = false;
			persistentDraw = false;
			deathCounter += 1;
			paused = true;

			vocals.stop();
			FlxG.sound.music.stop();
			isDead = true;
			openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
		}
	}

	public function triggerEvent(eventName:String, value1:String = '', value2:String = '') {
		switch (eventName) {
			case 'Change Character':
				var id:Int = 0;
				id = Std.parseInt(value2);

				if (Math.isNaN(id)) {
					switch (value2) {
						case 'bf' | 'boyfriend':
							id = 0;
						case 'gf' | 'girlfriend':
							id = 2;
						case 'dad' | 'opponent':
							id = 1;
						default:
							id = 0;
					}
				}

				changeCharacter(value1, id);
			case 'Play Hey':
				var id:Int = 0;
				id = Std.parseInt(value1);

				if (Math.isNaN(id)) {
					switch (value1) {
						case 'bf' | 'boyfriend':
							id = 0;
						case 'gf' | 'girlfriend':
							id = 2;
						case 'dad' | 'opponent':
							id = 1;
						default:
							id = 0;
					}
				}
					
				switch (id) {
					case 0:
						boyfriend.playHey();
					case 1:
						dad.playHey();
					case 2:
						gf.playHey();
				}
			case 'Set GF Speed':
				var value:Int = Std.parseInt(value1);

				if (Math.isNaN(value))
					value = 2;

				gf.idleOnBeat = value;
			case 'Play Animation':
				var char:Character = dad;

				switch (value1) {
					case 'bf' | 'boyfriend':
						char = boyfriend;
					case 'gf' | 'girlfriend':
						char = gf;
					case 'dad' | 'opponent':
						char = dad;
				}

				if (char != null) {
					char.playAnim(value2, true);
					char.specialAnim = true;
				}
			case 'Change Scroll Speed':
				var value:Float = 1;

				if (!Math.isNaN(Std.parseFloat(value1)))
					value = Std.parseFloat(value1);

				songSpeed = value;
			case 'Set Zoom Speed':
				var value:Int = 4;

				if (!Math.isNaN(Std.parseInt(value1)))
					value = Std.parseInt(value1);

				zoomSpeed = value;
		}

		callHscript('onEvent', [eventName, value1, value2]);
		callLua('onEvent', [eventName, value1, value2]);
	}

	public function getBehindPos():Int {
		var index:Int = members.indexOf(gfGroup);
		var dadIndex:Int = members.indexOf(dad.ghostGroup);
		var bfIndex:Int = members.indexOf(boyfriend.ghostGroup);

		if (bfIndex < index)
			index = bfIndex;

		if (dadIndex < bfIndex)
			index = dadIndex;
			
		return index;
	}

	public function callHscript(func:String = null, args:Array<Dynamic>) { 
		#if ALLOW_HSCRIPT
		for (hscript in hscriptArray) {
			if (func != null && hscript.exists(func) && hscript.isAlive) {
				Reflect.callMethod(null, hscript.get(func), args);
			}
		}
		#end
	}

	public function setHscript(variable:String, data:Dynamic) {
		#if ALLOW_HSCRIPT
		for (hscript in hscriptArray) {
			if (hscript.isAlive)
				hscript.set(variable, data);
		}
		#end
	}

	public function callLua(func:String = null, args:Array<Dynamic>) {
		var returnValue:Dynamic = LuaState.continueFunc;
		#if ALLOW_LUA
		for (luaScript in luaArray) {
			var gotValue = luaScript.callFunc(func, args);

			if (gotValue == LuaState.errorStop)
				break;

			if (gotValue != null && gotValue != LuaState.continueFunc)
				returnValue = gotValue;
		}
		#end

		return returnValue;
	}

	public function setLua(variable:String, data:Dynamic) {
		#if ALLOW_LUA
		for (luaScript in luaArray)
			luaScript.setVar(variable, data);
		#end
	}

	public function startHscriptOnFolder(folder:String = null) {
		if (folder == null) return;
		if (!folder.endsWith('/')) folder += '/';

		#if (ALLOW_HSCRIPT && sys)
		var directorys:Array<String> = [Paths.mods(), Paths.getPreloadPath()];

		for (i in 0...directorys.length) {
			var finalDir:String = directorys[i] + folder;

			if (FileSystem.exists(finalDir)) {
				for (file in FileSystem.readDirectory(finalDir)) {
					startHscript(finalDir + file);
				}
			}

		}
		#end
	}

	public function startHscript(path:String) {
		#if ALLOW_HSCRIPT
		if (path.endsWith('.hx')) {
			var hscript:HScript = new HScript(path);
			hscriptArray.push(hscript);
		}
		#end
	}

	public function startLuaOnFolder(folder:String) {
		if (!folder.endsWith('/')) folder += '/';

		#if (ALLOW_LUA && sys)
		var directorys:Array<String> = [Paths.mods(folder), Paths.getPreloadPath(folder)];

		for (i in 0...directorys.length) {
			var path:String = directorys[i];

			if (FileSystem.exists(path)) {
				for (file in FileSystem.readDirectory(path)) {
					if (file.endsWith('.lua'))
						startLuaScript(path + file);
				}
			}
		}
		#end
	}

	public function startLuaScript(path:String) {
		#if ALLOW_LUA
		if (path.endsWith('.lua')) {
			var luaScript:LuaState = new LuaState(path);
			luaScript.callFunc('onCreate', []);
			luaArray.push(luaScript);
		}
		else
			trace("Path ($path) is not a lua script path");
		#end
	}

	public static function getPosition(char:String = 'boyfriend', id:Int = 0)
		return (positionMap.exists(char) ? positionMap.get(char)[id] : 0);

	public static function changeCharacter(newCharacter:String, id:Int = 0) {
		switch (id) {
			case 0:
				var lastAlpha:Float = boyfriend.alpha;
				boyfriend.alpha = 0.0001;
				if (!bfChars.exists(newCharacter))
				{
					var newChar:Boyfriend = new Boyfriend(0, 0, newCharacter);
					addCharacter(newChar);
					newChar.alpha = 0.00001;
					bfChars.set(newCharacter, newChar);
				}
				boyfriendGroup.remove(boyfriend.ghostGroup);
				boyfriend = bfChars.get(newCharacter);
				boyfriend.alpha = lastAlpha;
				if (playerStrums != null)
					playerStrums.changeCharacter(boyfriend);
				else
					strumLines.members[playerLane].changeCharacter(boyfriend);
				hudGroup.iconP1.changeIcon(newCharacter, true, null);
			case 1:
				var lastAlpha:Float = dad.alpha;
				dad.alpha = 0.0001;
				if (!dadChars.exists(newCharacter))
				{
					var newChar:Character = new Character(0, 0, newCharacter);
					addCharacter(newChar);
					newChar.alpha = 0.00001;
					dadChars.set(newCharacter, newChar);
				}
				dadGroup.remove(dad.ghostGroup);
				dad = dadChars.get(newCharacter);
				dad.alpha = lastAlpha;

				if (opponentStrums != null) 
					opponentStrums.changeCharacter(dad); 
				else
					strumLines.members[0].changeCharacter(dad);

				hudGroup.iconP2.changeIcon(newCharacter, false, null);
			case 2:
				var lastAlpha:Float = gf.alpha;
				gf.alpha = 0.0001;
				if (!gfChars.exists(newCharacter))
				{
					var newChar:Character = new Character(0, 0, newCharacter);
					addCharacter(newChar);
					newChar.alpha = 0.00001;
					gfChars.set(newCharacter, newChar);
				}

				if (strumLines.members[2] != null)
					strumLines.members[2].strumCharacter = gf;

				gf = gfChars.get(newCharacter);
				gf.alpha = lastAlpha;
		}
	}
}
