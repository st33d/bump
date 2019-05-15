package {
	import com.adobe.serialization.json.JSON;
	import com.robotacid.ai.Node;
	import com.robotacid.engine.Entity;
	import com.robotacid.engine.Level;
	import com.robotacid.engine.LevelData;
	import com.robotacid.engine.Room;
	import com.robotacid.geom.Pixel;
	import com.robotacid.geom.Trig;
	import com.robotacid.gfx.*;
	import com.robotacid.sound.gameSoundsInit;
	import com.robotacid.sound.SoundManager;
	import com.robotacid.sound.SoundQueue;
	import com.robotacid.ui.Dialog;
	//import com.robotacid.ui.editor.RoomPainter;
	//import com.robotacid.ui.editor.RoomPalette;
	import com.robotacid.ui.FileManager;
	import com.robotacid.ui.ProgressBar;
	import com.robotacid.ui.TextBox;
	import com.robotacid.ui.Key;
	import com.robotacid.ui.TitleMenu;
	import com.robotacid.ui.Transition;
	import com.robotacid.ui.UIManager;
	import com.robotacid.util.clips.stopClips;
	import com.robotacid.util.FPS;
	import com.robotacid.util.HiddenInt;
	import com.robotacid.util.misc.onScreen;
	import com.robotacid.util.LZW;
	import com.robotacid.util.RLE;
	import com.robotacid.util.XorRandom;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Graphics;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.StageQuality;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TouchEvent;
	import flash.external.ExternalInterface;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.media.Sound;
	import flash.net.SharedObject;
	import flash.text.TextField;
	import flash.ui.Keyboard;
	import flash.ui.Mouse;
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
	
	/**
	 * Red Rogue
	 *
	 * A roguelike platform game
	 * 
	 * This is the top level class that serves as a Controller to the rest of the code
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	
	//[SWF(width = "640", height = "480", frameRate="30", backgroundColor = "#000000")]
	
	public class Game extends Sprite {
		
		public static const VERSION_NUM:Number = 0;
		
		public static const TEST_BED_INIT:Boolean = false;
		public static const ONLINE:Boolean = false;
		
		public static var MOBILE:Boolean = false;
		
		public static var game:Game;
		public static var renderer:Renderer;
		public static var debug:Graphics;
		public static var debugStay:Graphics;
		public static var debugShape:Shape;
		public static var debugStayShape:Shape;
		public static var dialog:Dialog;
		
		// core engine objects
		//public var player:Player;
		public var titleMenu:TitleMenu;
		public var level:Level;
		//public var roomPainter:RoomPainter;
		public var soundQueue:SoundQueue;
		public var transition:Transition;
		
		// graphics
		
		// ui
		
		public var focusPrompt:Sprite;
		public var deathPrompt:Sprite;
		public var fpsText:TextBox;
		
		// debug
		public var info:TextField;
		
		// states
		public var state:int;
		public var focusPreviousState:int;
		public var frameCount:int;
		public var mousePressedCount:int;
		public var mouseReleasedCount:int;
		public var mousePressed:Boolean;
		public var mouseVx:Number;
		public var mouseVy:Number;
		private var lastMouseX:Number;
		private var lastMouseY:Number;
		public var paused:Boolean;
		public var shakeDirX:int;
		public var shakeDirY:int;
		public var forceFocus:Boolean = false;
		public var mouseCorner:int;
		public var regainedFocus:Boolean = false;
		public var currentLevel:int;
		public var currentLevelType:int;
		public var currentLevelObj:Object;
		public var editing:Boolean;
		public var modifiedLevel:Boolean;
		
		private var hideMouseFrames:int;
		
		// temp variables
		private var i:int;
		public static var point:Point = new Point();
		
		// CONSTANTS
		
		public static const SCALE:Number = 16;
		public static const INV_SCALE:Number = 1.0 / SCALE;
		
		// states
		public static const GAME:int = 0;
		public static const MENU:int = 1;
		public static const DIALOG:int = 2;
		public static const SEGUE:int = 3;
		public static const TITLE:int = 4;
		public static const INSTRUCTIONS:int = 5;
		public static const EPILOGUE:int = 6;
		public static const UNFOCUSED:int = 7;
		
		public static const WIDTH:Number = 256;//
		public static const HEIGHT:Number = 240;//
		
		// game key properties
		public static const UP_KEY:int = 0;
		public static const DOWN_KEY:int = 1;
		public static const LEFT_KEY:int = 2;
		public static const RIGHT_KEY:int = 3;
		public static const MENU_KEY:int = 4;
		
		public static const MAX_LEVEL:int = 20;
		
		public static const TURN_FRAMES:int = 2;
		public static const HIDE_MOUSE_FRAMES:int = 45;
		public static const DEATH_FADE_COUNT:int = 15;
		
		public static const UP:int = LevelData.UP;
		public static const RIGHT:int = LevelData.RIGHT;
		public static const DOWN:int = LevelData.DOWN;
		public static const LEFT:int = LevelData.LEFT;
		
		public static var fullscreenOn:Boolean;
		public static var allowScriptAccess:Boolean;
		
		public static const SOUND_DIST_MAX:int = 12;
		public static const INV_SOUND_DIST_MAX:Number = 1.0 / SOUND_DIST_MAX;
		public static const SOUND_HORIZ_DIST_MULTIPLIER:Number = 1.5;
		
		public function Game():void {
			
			game = this;
			UserData.game = this;
			FX.game = this;
			Dialog.game = this;
			Level.game = this;
			TitleMenu.game = this;
			//RoomPainter.game = this;
			//RoomPalette.game = this;
			Entity.game = this;
			
			// detect allowScriptAccess for tracking
			allowScriptAccess = ExternalInterface.available;
			if(allowScriptAccess){
				try{
					ExternalInterface.call("");
				} catch(e:Error){
					allowScriptAccess = false;
				}
			}
			
			var byteArray:ByteArray;
			
			Library.initLevels();
			
			// init UserData
			UserData.initSettings();
			UserData.initGameState();
			UserData.pull();
			// check the game is alive
			if(UserData.gameState.dead) UserData.initGameState();
			
			if(UserData.settings.bestScore) LevelData.bestScore = UserData.settings.bestScore;
			
			// misc static settings
			
			state = GAME;
			//state = MENU;
			
			TextBox.init();
			
			renderer = new Renderer(this);
			renderer.init();
			
			ProgressBar.initGlowTable();
			
			transition = new Transition();
			
			FPS.start();
			
			// SOUND INIT
			SoundManager.init();
			soundQueue = new SoundQueue();
			gameSoundsInit();
			
			if (stage) addedToStage();
			else addEventListener(Event.ADDED_TO_STAGE, addedToStage);
		}
		
		private function addedToStage(e:Event = null):void{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			
			// KEYS INIT
			if(!Key.initialized){
				Key.init(stage);
				Key.custom = UserData.settings.customKeys.slice();
				Key.hotKeyTotal = 10;
			}
			
			// GRAPHICS INIT
			var scaleRatio:Number;
			if(MOBILE){
				scaleRatio = stage.stageWidth / HEIGHT;
			} else {
				scaleRatio = stage.stageWidth / WIDTH;
			}
			scaleX = scaleY = scaleRatio;
			stage.quality = StageQuality.LOW;
			
			// GAME INIT
			
			init();
		}
		
		/* The initialisation is quite long, so I'm breaking it up with some comment lines */
		private function init():void {
			
			// GAME GFX AND UI INIT
			if(state == GAME || state == MENU){
				renderer.createRenderLayers(this);
				
			} else if(state == TITLE){
			}
			
			addChild(transition);
			
			// menu init
			
			
			if(!focusPrompt){
				focusPrompt = new Sprite();
				focusPrompt.addChild(screenText("bump!\n\n________\n________\n________\n________\n____ _ _\n________\n  __    \n  __    \n\nq-w-e-a-s-d to move\nr to restart\nclick to play\n\n\n\n\n\nyou can also use\nu-i-o-j-k-l to move"));
				stage.addEventListener(Event.DEACTIVATE, onFocusLost);
				stage.addEventListener(Event.ACTIVATE, onFocus);
			}
			
			// CREATE FIRST LEVEL =================================================================
			if(state == GAME || state == MENU){
				
				/**/	
				// debugging textfield
				info = new TextField();
				addChild(info);
				info.textColor = 0xFFFFFF;
				info.selectable = false;
				info.text = "";
				info.visible = true;
				
				// fps text box
				fpsText = new TextBox(24, 12);
				fpsText.x = WIDTH - (fpsText.width + 2);
				fpsText.y = HEIGHT - (fpsText.height + 2);
				addChild(fpsText);
				fpsText.visible = false;
				
				// STATES
				
				frameCount = 1;
				currentLevel = 0;
				currentLevelType = Room.PUZZLE;
				currentLevelObj = null;
				
				// LISTS
				
				//entities = new Vector.<Entity>();
				
				titleMenu = new TitleMenu();
				
				if(state == GAME) initLevel();
				//player = new Player(25, 25, level);
				
			} else if(state == TITLE){
			}
			
			// fire up listeners
			addListeners();
			
			// this is a hack to force clicking on the game when the browser first pulls in the swf
			if(forceFocus){
				onFocusLost();
				forceFocus = false;
			} else {
			}
		}
		
		public function initLevel():void{
			var checkView:Boolean = level ? level.checkView : false;
			level = new Level(currentLevelType, currentLevelObj);
			//level.checkView = level.checkButton.active = checkView;
			renderer.reset();
			//roomPainter = new RoomPainter(level.data);
			//roomPainter.setActive(true);
			state = GAME;
		}
		
		/* Pedantically clear all memory and re-init the project */
		public function reset(newGame:Boolean = true):void{
			removeEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			removeEventListener(MouseEvent.MOUSE_UP, mouseUp);
			removeEventListener(Event.ENTER_FRAME, main);
			stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyPressed);
			stage.removeEventListener(Event.DEACTIVATE, onFocusLost);
			stage.removeEventListener(Event.ACTIVATE, onFocus);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
			//removeEventListener(TouchEvent.TOUCH_BEGIN, touchBegin);
			while(numChildren > 0){
				removeChildAt(0);
			}
			level = null;
			if(newGame){
				UserData.initGameState();
				UserData.push();
			}
			SoundManager.musicTimes = {};
			init();
		}
		
		private function addListeners():void{
			stage.addEventListener(Event.DEACTIVATE, onFocusLost);
			stage.addEventListener(Event.ACTIVATE, onFocus);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			stage.addEventListener(MouseEvent.MOUSE_UP, mouseUp);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyPressed);
			//addEventListener(TouchEvent.TOUCH_BEGIN, touchBegin);
			//addEventListener(TouchEvent.TOUCH_END, touchEnd);
			addEventListener(Event.ENTER_FRAME, main);
		}
		
		// =================================================================================================
		// MAIN LOOP
		// =================================================================================================
		
		private function main(e:Event):void {
			
			if(fpsText && fpsText.visible) fpsText.text = "f:" + FPS.value;
			debug.clear();
			debug.lineStyle(1, 0x00FF00);
			debugShape.x = -renderer.canvasPoint.x;
			debugShape.y = -renderer.canvasPoint.y;
			
			
			// copy out these debug tools when needed
			//var t:int = getTimer();
			//info.text = game.player.mapX + " " + game.player.mapY;
			//info.appendText("pixels" + (getTimer() - t) + "\n"); t = getTimer();
			
			if(transition.visible) transition.main();
			
			if(state == GAME) {
				
				//if(roomPainter.active) roomPainter.main();
				
				if(level.active && transition.dir < 1) level.main();
				
				soundQueue.play();
				
				renderer.main();
				
				//var xSlope:Number = (WIDTH / HEIGHT) * mouseY;
				//var ySlope:Number = HEIGHT - (HEIGHT / WIDTH) * mouseX;
				//trace(mouseCorner);
				//debug.drawCircle(-renderer.canvas.x + xSlope, -renderer.canvas.y + mouseY,2);
				//debug.drawCircle( -renderer.canvas.x + mouseX, -renderer.canvas.y + ySlope, 2);
				/*var mx:int = renderer.canvas.mouseX * INV_SCALE;
				var my:int = renderer.canvas.mouseY * INV_SCALE;
				if(mousePressedCount == frameCount){
				}*/
				
				ProgressBar.glowCount = frameCount % ProgressBar.glowTable.length;
					
			} else if(state == INSTRUCTIONS){
				
			} else if(state == MENU){
				if(transition.dir < 1) titleMenu.main();
				renderer.main();
				
			}
			
			// hide the mouse when not in use
			//if(hideMouseFrames < HIDE_MOUSE_FRAMES){
				//hideMouseFrames++;
				//if(hideMouseFrames >= HIDE_MOUSE_FRAMES){
					//Mouse.hide();
				//}
			//}
			
			mouseVx = mouseX - lastMouseX;
			mouseVy = mouseY - lastMouseY;
			lastMouseX = mouseX;
			lastMouseY = mouseY;
			frameCount++;
		}
		
		/* Pause the game and make the inventory screen visible */
		public function pauseGame():void{
			if(state == GAME){
				state = MENU;
			} else if(state == MENU){
				state = GAME;
			}
		}
		
		public function setNextGame(type:int, levelNum:int = 0):void{
			modifiedLevel = false;
			currentLevel = levelNum;
			currentLevelType = type;
			if(type == Room.ADVENTURE){
				currentLevelObj = null;
			} else if(type == Room.PUZZLE){
				currentLevelObj = Library.levels[levelNum];
			}
		}
		
		public function puzzleWin():void{
			if(!editing || !modifiedLevel){
				currentLevel++;
				currentLevelObj = currentLevel < Library.TOTAL_LEVELS ? Library.levels[currentLevel] : null;
			}
			if(currentLevelObj){
				var str:String = (currentLevel < 10 ? "0" : "") + currentLevel;
				transition.begin(nextLevel, DEATH_FADE_COUNT, DEATH_FADE_COUNT, str, 30, null, 30);
			} else {
				transition.begin(quit, DEATH_FADE_COUNT, DEATH_FADE_COUNT, "\"poo-tee-weet?\"", 90, null, 30);
			}
		}
		
		public function blackOut():void{
			renderer.reset();
			state = SEGUE;
		}
		
		public function nextLevel():void{
			if(!editing) saveProgress();
			initLevel();
		}
		
		private function saveProgress():void{
			if(!editing){
				UserData.settings.completed[currentLevel - 1] = true;
				UserData.settings.bestScore = LevelData.bestScore;
				UserData.push(true);
			}
		}
		
		public static var newBest:Boolean = false;
		
		public function death():void{
			var str:String = "dead";
			if(level.data.food <= 0) str = "time out";
			if(newBest){
				str += "\n\nnew best\n\n";
				var nStr:String;
				nStr = "" + LevelData.bestScore;
				while(nStr.length < 6) nStr = "0" + nStr;
				str += nStr;
				newBest = false;
			}
			transition.begin(initLevel, 0, 0, str, 60, saveProgress, 60);
		}
		
		public function quit():void{
			saveProgress();
			renderer.reset();
			state = MENU;
		}
		
		public function screenText(str:String):TextBox{
			var textBox:TextBox = new TextBox(WIDTH, HEIGHT, 0xFF000000, 0xFF000000);
			textBox.align = "center";
			textBox.alignVert = "center";
			textBox.text = str;
			return textBox;
		}
		
		private function mouseDown(e:MouseEvent = null):void{
			// ignore the first click returning to the game
			if(!MOBILE){
				if(regainedFocus){
					regainedFocus = false;
					return;
				}
			}
			mousePressed = true;
			mousePressedCount = frameCount;
			lastMouseX = mouseX;
			lastMouseY = mouseY;
			setMouseCorner();
		}
		
		private function mouseUp(e:MouseEvent = null):void{
			mousePressed = false;
			mouseReleasedCount = frameCount;
			if(Boolean(UIManager.mousePressedCallback)){
				UIManager.mousePressedCallback();
				UIManager.mousePressedCallback = null;
			}
		}
		
		private function mouseMove(e:MouseEvent):void{
			if(hideMouseFrames >= HIDE_MOUSE_FRAMES) Mouse.show();
			hideMouseFrames = 0;
			setMouseCorner();
		}
		
		private function setMouseCorner():void{
			//var xSlope:Number = (WIDTH / HEIGHT) * mouseY;
			//var ySlope:Number = HEIGHT - (HEIGHT / WIDTH) * mouseX;
			var x:Number = mouseX - (WIDTH - HEIGHT) * 0.5;
			var y:Number = mouseY;
			var xSlope:Number = y;
			var ySlope:Number = HEIGHT - x;
			if(x > xSlope && y > ySlope){
				mouseCorner = LevelData.RIGHT
			} else if(x > xSlope && y < ySlope){
				mouseCorner = LevelData.UP
			} else if(x < xSlope && y > ySlope){
				mouseCorner = LevelData.DOWN
			} else if(x < xSlope && y < ySlope){
				mouseCorner = LevelData.LEFT
			}
			if(Math.abs(mouseX - WIDTH * 0.5) < SCALE * 0.75 && Math.abs(mouseY - HEIGHT * 0.5) < SCALE * 0.75){
				mouseCorner = 0;
			}
		}
		
		private function keyPressed(e:KeyboardEvent):void{
			if(Key.lockOut) return;
			/*if(Key.customDown(MENU_KEY) && !Game.dialog){
				if(state == INSTRUCTIONS){
				} else if(state == TITLE){
				} else if(state == EPILOGUE){
				} else {
					pauseGame();
				}
			}*/
			if(Key.isDown(Keyboard.CONTROL) && Key.isDown(Keyboard.SHIFT) && Key.isDown(Keyboard.ENTER)){
				if(fpsText) fpsText.visible = true;
			}
			if(Key.isDown(Key.R)){
				initLevel();
			}
			if(Key.isDown(Key.T)){
				//LevelData.printPathMap();
			}
			//if(Key.isDown(Key.P)){
				//var tempBitmap:BitmapData = new BitmapData(Game.WIDTH * game.scaleX, Game.HEIGHT * game.scaleY, true, 0x0);
				//tempBitmap.draw(this, transform.matrix);
				//FileManager.save(PNGEncoder.encode(tempBitmap), "screenshot.png");
			//}
			if(
				Key.isDown(Keyboard.SPACE)
			){
				level.undo();
			}
			if(
				Key.isDown(Keyboard.CONTROL) ||
				Key.isDown(Keyboard.SHIFT) ||
				Key.isDown(Keyboard.CONTROL)
			){
				level.toggleCheckView();
			}
			/**/
			/*if(Key.isDown(Key.Y)){
				level.takeTurn(Level.UP);
			}
			if(Key.isDown(Key.T)){
				var portal:Portal = Portal.createPortal(Portal.MINION, game.player.mapX, game.player.mapY);
				portal.setCloneTemplate();
			}
			if(Key.isDown(Key.T)){
				if(balrog) balrog.death();
			}
			if(Key.isDown(Key.K)){
				//player.jump();
				player.setAsleep(true);
			}
			if(Key.isDown(Key.T)){
				renderer.gifBuffer.save();
			}
			if(Key.isDown(Key.T)){
				miniMap.reveal();
			}
			if(Key.isDown(Key.P)){
				//minion.death("key");
				player.levelUp();
			}*/
		}
		
		/* Play a sound at a volume based on the distance to the player */
		public function createDistSound(mapX:int, mapY:int, name:String, names:Array = null, volume:Number = 1):void{
			var dist:Number = Math.abs(level.data.player.x - mapX) * SOUND_HORIZ_DIST_MULTIPLIER + Math.abs(level.data.player.y - mapY);
			if(dist < SOUND_DIST_MAX){
				if(names) soundQueue.addRandom(name, names, (SOUND_DIST_MAX - dist) * INV_SOUND_DIST_MAX * volume);
				else if(name) soundQueue.add(name, (SOUND_DIST_MAX - dist) * INV_SOUND_DIST_MAX * volume);
			}
		}
		
		/* When the flash object loses focus we put up a splash screen to encourage players to click to play */
		private function onFocusLost(e:Event = null):void{
			if(state == UNFOCUSED) return;
			focusPreviousState = state;
			state = UNFOCUSED;
			Key.clearKeys();
			addChild(focusPrompt);
		}
		
		/* When focus returns we remove the splash screen -
		 * 
		 * WARNING: Activating fullscreen mode causes this method to be fired twice by the Flash Player
		 * for some unknown reason.
		 * 
		 * Any modification to this method should take this into account and protect against repeat calls
		 */
		private function onFocus(e:Event = null):void{
			if(focusPrompt.parent) focusPrompt.parent.removeChild(focusPrompt);
			if(state == UNFOCUSED) state = focusPreviousState;
			regainedFocus = true;
		}
		
	}
	
}