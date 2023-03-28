package gameObjects;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxTimer;
import flxanimate.FlxAnimate;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.group.*;
import data.*;
import states.*;

//Pushed the cutscenes to this group so you could skip it if u wanted

class CutsceneGroup extends FlxGroup
{
	public var cutsceneStarted:Bool = false;

	public var tankCutscene:TankCutscene;
	public var gfCutsceneLayer:CutsceneLayer;
	public var bfCutsceneLayer:CutsceneLayer;

	public var cutsceneTimers:Array<FlxTimer> = [];

	public function new(name:String, instantStart:Bool = true, instance:PlayState = null) {
		super();
				
		if (instantStart)
			startCutscene(name);
	}

	public function addLayer(name:String = 'gf') {
		switch (name) {
			case 'gf':
				gfCutsceneLayer = new CutsceneLayer();
				gfCutsceneLayer.wasAdded = true;
				add(gfCutsceneLayer);

			case 'bf':
				bfCutsceneLayer = new CutsceneLayer();
				bfCutsceneLayer.wasAdded = true;
				add(bfCutsceneLayer);
			default:
				bfCutsceneLayer = new CutsceneLayer();
				bfCutsceneLayer.wasAdded = true;
				add(bfCutsceneLayer);
		}
	}

	public function startCutscene(name:String) {
		switch (name){
			case 'ugh':
				tankCutscene = new TankCutscene(-20, 320);
				tankCutscene.frames = Paths.getSparrowAtlas('cutsceneStuff/tankTalkSong1');
				tankCutscene.animation.addByPrefix('wellWell', 'TANK TALK 1 P1', 24, false);
				tankCutscene.animation.addByPrefix('killYou', 'TANK TALK 1 P2', 24, false);
				tankCutscene.animation.play('wellWell');
				tankCutscene.antialiasing = true;
				gfCutsceneLayer.add(tankCutscene);

				FlxG.camera.zoom *= 1.2;
				PlayState.instance.camFollow.y += 100;

				tankCutscene.startSyncAudio = FlxG.sound.load(Paths.sound('wellWellWell', 'week7'));

				cutsceneTimers.push(new FlxTimer().start(3, function(tmr:FlxTimer)
				{
					PlayState.instance.moveCam();
					FlxTween.tween(FlxG.camera, {zoom: PlayState.defaultCamZoom * 1.2}, 0.27, {ease: FlxEase.quadInOut});

					cutsceneTimers.push(new FlxTimer().start(1.5, function(bep:FlxTimer)
					{
						PlayState.boyfriend.playAnim('singUP');
						// play sound
						FlxG.sound.play(Paths.sound('bfBeep', 'week7'), function()
						{
							PlayState.boyfriend.playAnim('idle');
						});
					}));

					cutsceneTimers.push(new FlxTimer().start(3, function(swaggy:FlxTimer)
					{
						PlayState.instance.moveCam(true);
						FlxTween.tween(FlxG.camera, {zoom: PlayState.defaultCamZoom * 1.2}, 0.5, {ease: FlxEase.quadInOut});
						tankCutscene.animation.play('killYou');
						FlxG.sound.play(Paths.sound('killYou', 'week7'));
						cutsceneTimers.push(new FlxTimer().start(6.1, function(swagasdga:FlxTimer)
						{
							FlxTween.tween(FlxG.camera, {zoom: PlayState.defaultCamZoom}, (Conductor.crochet / 1000) * 5, {ease: FlxEase.quadInOut});

							FlxG.sound.music.fadeOut((Conductor.crochet / 1000) * 5, 0);

							new FlxTimer().start((Conductor.crochet / 1000) * 5, function(money:FlxTimer)
							{
								PlayState.dad.visible = true;
								gfCutsceneLayer.remove(tankCutscene);
							});

							PlayState.instance.endTheScene();
						}));
					}));
				}));
			case 'guns':
				PlayState.instance.moveCam(true);

				FlxTween.tween(FlxG.camera, {zoom: PlayState.defaultCamZoom * 1.3}, 4, {ease: FlxEase.quadInOut});

				PlayState.dad.visible = false;
				tankCutscene = new TankCutscene(20, 320);
				tankCutscene.frames = Paths.getSparrowAtlas('cutsceneStuff/tankTalkSong2');
				tankCutscene.animation.addByPrefix('tankyguy', 'TANK TALK 2', 24, false);
				tankCutscene.animation.play('tankyguy');
				tankCutscene.antialiasing = true;
				gfCutsceneLayer.add(tankCutscene);

				tankCutscene.startSyncAudio = FlxG.sound.load(Paths.sound('tankSong2', 'week7'));

				cutsceneTimers.push(new FlxTimer().start(4.1, function(ugly:FlxTimer)
				{
					FlxTween.tween(FlxG.camera, {zoom: PlayState.defaultCamZoom * 1.4}, 0.4, {ease: FlxEase.quadOut});
					FlxTween.tween(FlxG.camera, {zoom: PlayState.defaultCamZoom * 1.3}, 0.7, {ease: FlxEase.quadInOut, startDelay: 0.45});

					PlayState.gf.playAnim('sad');
				}));

				cutsceneTimers.push(new FlxTimer().start(11, function(tmr:FlxTimer)
				{
					FlxG.sound.music.fadeOut((Conductor.crochet / 1000) * 5, 0);

					FlxTween.tween(FlxG.camera, {zoom: PlayState.defaultCamZoom}, (Conductor.crochet * 5) / 1000, {ease: FlxEase.quartIn});
					endScene();
				}));
			case 'stress':	
				var cutsceneShit:FlxSprite = new FlxSprite(0, -150);
				cutsceneShit.frames = Paths.getSparrowAtlas('cutsceneStuff/gfTankmenCutsceneDemon');
				cutsceneShit.animation.addByPrefix('anim', 'GF Turnin Demon W Effect', 24, false);
				cutsceneShit.animation.play('anim', true);

				var picoShoot:FlxAnimate = new FlxAnimate(100, 75, Paths.getPreloadPath('images/cutsceneStuff/picoShoot'));
				picoShoot.anim.addBySymbol('shoot', 'Pico Saves them sequence', 24, false); //W

				var bfCatchGf:FlxSprite = new FlxSprite(PlayState.boyfriend.x - 10, PlayState.boyfriend.y - 90);
				bfCatchGf.frames = Paths.getSparrowAtlas('characters/bfAndGF');
				bfCatchGf.animation.addByPrefix('catch', 'BF catches GF', 24, false);
				bfCatchGf.antialiasing = true;

				PlayState.instance.moveCam(true);
				PlayState.dad.visible = false;
				PlayState.gf.alpha = 0.01;

				var gfTankmen:FlxSprite = new FlxSprite(210, 70);
				gfTankmen.frames = Paths.getSparrowAtlas('characters/gfTankmen');
				gfTankmen.animation.addByPrefix('loop', 'GF Dancing at Gunpoint', 24, true);
				gfTankmen.animation.play('loop');
				gfTankmen.antialiasing = true;
				gfCutsceneLayer.add(gfTankmen);

				tankCutscene = new TankCutscene(-70, 320);
				tankCutscene.frames = Paths.getSparrowAtlas('cutsceneStuff/tankTalkSong3-pt1');
				tankCutscene.animation.addByPrefix('tankyguy', 'TANK TALK 3 P1 UNCUT', 24, false);
				tankCutscene.animation.play('tankyguy');

				tankCutscene.antialiasing = true;
				bfCutsceneLayer.add(tankCutscene);

				var alsoTankCutscene:FlxSprite = new FlxSprite(20, 320);
				alsoTankCutscene.frames = Paths.getSparrowAtlas('cutsceneStuff/tankTalkSong3-pt2');
				alsoTankCutscene.animation.addByPrefix('swagTank', 'TANK TALK 3 P2 UNCUT', 24, false);
				alsoTankCutscene.antialiasing = true;
				bfCutsceneLayer.add(alsoTankCutscene);
				alsoTankCutscene.y = FlxG.height + 100;

				PlayState.instance.camFollow.setPosition(PlayState.gf.x + 350, PlayState.gf.y + 560);
				FlxG.camera.focusOn(PlayState.instance.camFollow.getPosition());

				PlayState.boyfriend.visible = false;

				var fakeBF:Character = new Character(PlayState.boyfriend.x, PlayState.boyfriend.y, 'bf', true);
				bfCutsceneLayer.add(fakeBF);

				add(bfCatchGf);
				bfCatchGf.visible = false;

				if (!PlayerPrefs.getOptionValue('censor-naughty'))
					tankCutscene.startSyncAudio = FlxG.sound.play(Paths.sound('stressCutscene', 'week7'));
				else
				{
					tankCutscene.startSyncAudio = FlxG.sound.play(Paths.sound('song3censor', 'week7'));
					// cutsceneSound.loadEmbedded(Paths.sound('song3censor'));

					var censor:FlxSprite = new FlxSprite();
					censor.frames = Paths.getSparrowAtlas('cutsceneStuff/censor');
					censor.animation.addByPrefix('censor', 'mouth censor', 24);
					censor.animation.play('censor');
					add(censor);
					censor.visible = false;
					//

					cutsceneTimers.push(new FlxTimer().start(4.6, function(censorTimer:FlxTimer)
					{
						censor.visible = true;
						censor.setPosition(PlayState.dad.x + 160, PlayState.dad.y + 180);

						new FlxTimer().start(0.2, function(endThing:FlxTimer)
						{
							censor.visible = false;
						});
					}));

					cutsceneTimers.push(new FlxTimer().start(25.1, function(censorTimer:FlxTimer)
					{
						censor.visible = true;
						censor.setPosition(PlayState.dad.x + 120, PlayState.dad.y + 170);

						cutsceneTimers.push(new FlxTimer().start(0.9, function(endThing:FlxTimer)
						{
							censor.visible = false;
						}));
					}));

					cutsceneTimers.push(new FlxTimer().start(30.7, function(censorTimer:FlxTimer)
					{
						censor.visible = true;
						censor.setPosition(PlayState.dad.x + 210, PlayState.dad.y + 190);

						new FlxTimer().start(0.4, function(endThing:FlxTimer)
						{
							censor.visible = false;
						});
					}));

					cutsceneTimers.push(new FlxTimer().start(33.8, function(censorTimer:FlxTimer)
					{
						censor.visible = true;
						censor.setPosition(PlayState.dad.x + 180, PlayState.dad.y + 170);

						new FlxTimer().start(0.6, function(endThing:FlxTimer)
						{
							censor.visible = false;
						});
					}));
				}

				FlxG.camera.zoom = PlayState.defaultCamZoom * 1.15;

				PlayState.instance.camFollow.x -= 200;

				// cutsceneSound.onComplete = startCountdown;

				// Cunt 1
				cutsceneTimers.push(new FlxTimer().start(31.5, function(cunt:FlxTimer)
				{
					PlayState.instance.moveCam();
					FlxG.camera.zoom = PlayState.defaultCamZoom * 1.4;
					FlxTween.tween(FlxG.camera, {zoom: FlxG.camera.zoom + 0.1}, 0.5, {ease: FlxEase.elasticOut});
					FlxG.camera.focusOn(PlayState.instance.camFollow.getPosition());
					PlayState.boyfriend.playAnim('singUPmiss');
					PlayState.boyfriend.animation.finishCallback = function(animFinish:String)
					{
						PlayState.instance.camFollow.x -= 400;
						PlayState.instance.camFollow.y -= 150;
						FlxG.camera.zoom /= 1.4;
						FlxG.camera.focusOn(PlayState.instance.camFollow.getPosition());

						PlayState.boyfriend.animation.finishCallback = null;
					};
				}));

				cutsceneTimers.push(new FlxTimer().start(15.1, function(tmr:FlxTimer)
				{
					PlayState.instance.camFollow.setPosition(PlayState.gf.getMidpoint().x, PlayState.gf.getMidpoint().y);
					FlxTween.tween(FlxG.camera, {zoom: FlxG.camera.zoom * 1.3}, 2.1, {
						ease: FlxEase.quadInOut
					});

					cutsceneTimers.push(new FlxTimer().start(2.2, function(swagTimer:FlxTimer)
					{
						FlxG.camera.zoom = 0.8;
						PlayState.boyfriend.visible = false;
						bfCatchGf.visible = true;
						bfCatchGf.animation.play('catch');
						bfCutsceneLayer.remove(fakeBF);

						bfCatchGf.animation.finishCallback = function(anim:String)
						{
							bfCatchGf.visible = false;
							PlayState.boyfriend.visible = true;
						};

						cutsceneTimers.push(new FlxTimer().start(3, function(weedShitBaby:FlxTimer)
						{
							PlayState.instance.camFollow.y += 180;
							PlayState.instance.camFollow.x -= 80;
						}));

						cutsceneTimers.push(new FlxTimer().start(2.3, function(gayLol:FlxTimer)
						{
							bfCutsceneLayer.remove(tankCutscene);
							alsoTankCutscene.y = 320;
							alsoTankCutscene.animation.play('swagTank');
						}));
					}));

					PlayState.gf.visible = false;
					gfCutsceneLayer.add(cutsceneShit);
					gfCutsceneLayer.remove(gfTankmen);

					cutsceneShit.animation.finishCallback = function(anim:String) {
						cutsceneShit.visible = false;
						gfCutsceneLayer.add(picoShoot);
						picoShoot.anim.play('shoot', true);
					};

					picoShoot.anim.onComplete = function() {
						PlayState.gf.alpha = 1;
						PlayState.gf.visible = true;
						gfCutsceneLayer.remove(picoShoot);
					}

					// add(cutsceneShit);
					cutsceneTimers.push(new FlxTimer().start(20, function(alsoTmr:FlxTimer)
					{
						PlayState.dad.visible = true;
						endScene();
					}));
				}));
			default:
				endScene();
		}
	}

	public function endScene() {
		if (gfCutsceneLayer != null && gfCutsceneLayer.wasAdded) remove(gfCutsceneLayer);
		if (bfCutsceneLayer != null && bfCutsceneLayer.wasAdded) remove(bfCutsceneLayer);
		for (timer in cutsceneTimers) if (timer != null) timer.cancel();
		if (tankCutscene != null) tankCutscene.stopAudio();
		if (PlayState.dad != null) PlayState.dad.visible = true;
		if (PlayState.boyfriend != null) PlayState.boyfriend.visible = true;
		if (PlayState.gf != null) PlayState.gf.visible = true;
		for (sound in 0...FlxG.sound.defaultSoundGroup.sounds.length) FlxG.sound.defaultSoundGroup.sounds[sound].stop();
		PlayState.instance.endTheScene();
	}

	override function update(elapsed:Float) {
		if (FlxG.keys.justPressed.SPACE) {
			endScene();
		}

		super.update(elapsed);
	}
}

class CutsceneLayer extends FlxGroup {
	public var wasAdded:Bool = false;
}