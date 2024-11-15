package;

import flixel.input.keyboard.FlxKey;
import lime.app.Application;
import flixel.input.FlxInput.FlxInputState;
import Conductor.BPMChangeEvent;
import flixel.FlxG;
import flixel.addons.ui.FlxUIState;
import flixel.math.FlxRect;
import flixel.util.FlxTimer;
import flixel.addons.transition.FlxTransitionableState;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.FlxState;
import flixel.FlxCamera;
import flixel.FlxBasic;
#if mobile
import mobile.MobileControls;
import mobile.flixel.FlxVirtualPad;
import flixel.FlxCamera;
import flixel.input.actions.FlxActionInput;
import flixel.util.FlxDestroyUtil;
#end

class MusicBeatState extends FlxUIState
{
	private var curSection:Int = 0;
	private var stepsToDo:Int = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	private var curDecStep:Float = 0;
	private var curDecBeat:Float = 0;
	private var controls(get, never):Controls;

	public static var camBeat:FlxCamera;

	public static inline var TILE_SIZE:Int = 16;

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	#if mobile
		var mobileControls:MobileControls;
		var virtualPad:FlxVirtualPad;
		var trackedInputsMobileControls:Array<FlxActionInput> = [];
		var trackedInputsVirtualPad:Array<FlxActionInput> = [];

		public function addVirtualPad(DPad:FlxDPadMode, Action:FlxActionMode)
		{
		    if (virtualPad != null)
			removeVirtualPad();

			virtualPad = new FlxVirtualPad(DPad, Action);
		    add(virtualPad);

			controls.setVirtualPadUI(virtualPad, DPad, Action);
			trackedInputsVirtualPad = controls.trackedInputsUI;
			controls.trackedInputsUI = [];
		}

		public function removeVirtualPad()
		{
			if (trackedInputsVirtualPad.length > 0)
			controls.removeVirtualControlsInput(trackedInputsVirtualPad);

			if (virtualPad != null)
			remove(virtualPad);
		}

		public function addMobileControls(DefaultDrawTarget:Bool = true)
		{
			if (mobileControls != null)
			removeMobileControls();

			mobileControls = new MobileControls();

			switch (MobileControls.mode)
			{
				case 'Pad-Right' | 'Pad-Left' | 'Pad-Custom':
				controls.setVirtualPadNOTES(mobileControls.virtualPad, RIGHT_FULL, NONE);
				case 'Pad-Duo':
				controls.setVirtualPadNOTES(mobileControls.virtualPad, BOTH_FULL, NONE);
				case 'Hitbox':
				controls.setHitBox(mobileControls.hitbox);
				case 'Keyboard': // do nothing
			}

			trackedInputsMobileControls = controls.trackedInputsNOTES;
			controls.trackedInputsNOTES = [];

			var camControls:FlxCamera = new FlxCamera();
			FlxG.cameras.add(camControls, DefaultDrawTarget);
			camControls.bgColor.alpha = 0;

			mobileControls.cameras = [camControls];
			mobileControls.visible = false;
			add(mobileControls);
		}

		public function removeMobileControls()
		{
			if (trackedInputsMobileControls.length > 0)
			controls.removeVirtualControlsInput(trackedInputsMobileControls);

			if (mobileControls != null)
			remove(mobileControls);
		}

		public function addVirtualPadCamera(DefaultDrawTarget:Bool = true)
		{
			if (virtualPad != null)
			{
				var camControls:FlxCamera = new FlxCamera();
				FlxG.cameras.add(camControls, DefaultDrawTarget);
				camControls.bgColor.alpha = 0;
				virtualPad.cameras = [camControls];
			}
		}
		#end

		override function destroy()
		{
			#if mobile
			if (trackedInputsMobileControls.length > 0)
			controls.removeVirtualControlsInput(trackedInputsMobileControls);

			if (trackedInputsVirtualPad.length > 0)
			controls.removeVirtualControlsInput(trackedInputsVirtualPad);
			#end

			super.destroy();
			clear_memory();

			#if mobile
			if (virtualPad != null)
			virtualPad = FlxDestroyUtil.destroy(virtualPad);

			if (mobileControls != null)
			mobileControls = FlxDestroyUtil.destroy(mobileControls);
			#end
		}
	
	override function create() {
		camBeat = FlxG.camera;
		var skip:Bool = FlxTransitionableState.skipNextTransOut;
		super.create();

		if(!skip) {
			openSubState(new CustomFadeTransition(0.7, true));
		}
		FlxTransitionableState.skipNextTransOut = false;
	}

	override public function new() {
		clear_memory();
		super();
	}

	public static function clear_memory():Void {
		// Remove cached assets (prevents memory leaks that i can prevent)

		// Remove lingering sounds from the sound list
		FlxG.sound.list.forEachAlive(function(sound:flixel.sound.FlxSound):Void {
			FlxG.sound.list.remove(sound, true);
			sound.stop();
			sound.destroy();
		});
		FlxG.sound.list.clear();

		FlxG.bitmap.clearCache();

		// Clear actual assets from OpenFL and Lime itself
		var cache:openfl.utils.AssetCache = cast openfl.utils.Assets.cache;
		var lime_cache:lime.utils.AssetCache = cast lime.utils.Assets.cache;

		// this totally isn't copied from polymod/backends/OpenFLBackend.hx trust me
		for (key in cache.bitmapData.keys())
			cache.bitmapData.remove(key);
		for (key in cache.font.keys())
			cache.font.remove(key);
		@:privateAccess
		try{
			for (key in cache.sound.keys()) {
				cache.sound.get(key).close();
				cache.sound.remove(key);
			}
		}
		catch(e){
			trace(e);
		}

		// this totally isn't copied from polymod/backends/LimeBackend.hx trust me
		for (key in lime_cache.image.keys())
			lime_cache.image.remove(key);
		for (key in lime_cache.font.keys())
			lime_cache.font.remove(key);
		for (key in lime_cache.audio.keys()) {
			lime_cache.audio.get(key).dispose();
			lime_cache.audio.remove(key);
		};

		lime.utils.Assets.cache.clear();
		openfl.utils.Assets.cache.clear();

		// Compact the garbage collector
		#if cpp
		cpp.vm.Gc.compact();
		#end
		//Clear mod assets
		//Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
	}


	override function update(elapsed:Float)
	{
		//everyStep();
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep)
		{
			if(curStep > 0)
				stepHit();

			if(PlayState.SONG != null)
			{
				if (oldStep < curStep)
					updateSection();
				else
					rollbackSection();
			}
		}

		if(FlxG.save.data != null) FlxG.save.data.fullscreen = FlxG.fullscreen;

		super.update(elapsed);

		if (FlxG.keys.checkStatus(FlxKey.F11, FlxInputState.JUST_PRESSED)) //shadowmario is mid and doesnt wanna add f11 fullscreen for whatever reason
			FlxG.fullscreen = !FlxG.fullscreen;
	}

	private function updateSection():Void
	{
		if(stepsToDo < 1) stepsToDo = Math.round(getBeatsOnSection() * 4);
		while(curStep >= stepsToDo)
		{
			curSection++;
			var beats:Float = getBeatsOnSection();
			stepsToDo += Math.round(beats * 4);
			sectionHit();
		}
	}

	private function rollbackSection():Void
	{
		if(curStep < 0) return;

		var lastSection:Int = curSection;
		curSection = 0;
		stepsToDo = 0;
		for (i in 0...PlayState.SONG.notes.length)
		{
			if (PlayState.SONG.notes[i] != null)
			{
				stepsToDo += Math.round(getBeatsOnSection() * 4);
				if(stepsToDo > curStep) break;
				
				curSection++;
			}
		}

		if(curSection > lastSection) sectionHit();
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
		curDecBeat = curDecStep/4;
	}

	private function updateCurStep():Void
	{
		var lastChange = Conductor.getBPMFromSeconds(Conductor.songPosition);

		var shit = ((Conductor.songPosition - ClientPrefs.noteOffset) - lastChange.songTime) / lastChange.stepCrochet;
		curDecStep = lastChange.stepTime + shit;
		curStep = lastChange.stepTime + Math.floor(shit);
	}



	override function startOutro(onOutroComplete:()->Void):Void
		{
			if (!FlxTransitionableState.skipNextTransIn)
			{
				FlxG.state.openSubState(new CustomFadeTransition(0.6, false));
	
				CustomFadeTransition.finishCallback = onOutroComplete;
	
				return;
			}
	
			FlxTransitionableState.skipNextTransIn = false;
	
			onOutroComplete();
			FlxG.mouse.load(Paths.image("pointer").bitmap);
			FlxG.mouse.visible = false;
		}

	public static function resetState() {
		FlxG.switchState(() ->FlxG.state);
	}

	public static function getState():MusicBeatState {
		var curState:Dynamic = FlxG.state;
		var leState:MusicBeatState = curState;
		return leState;
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		//trace('Beat: ' + curBeat);
	}

	public function sectionHit():Void
	{
		//trace('Section: ' + curSection + ', Beat: ' + curBeat + ', Step: ' + curStep);
	}

	function getBeatsOnSection()
	{
		var val:Null<Float> = 4;
		if(PlayState.SONG != null && PlayState.SONG.notes[curSection] != null) val = PlayState.SONG.notes[curSection].sectionBeats;
		return val == null ? 4 : val;
	}
}
