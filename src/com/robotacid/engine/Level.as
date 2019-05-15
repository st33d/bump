package com.robotacid.engine {
	import com.robotacid.geom.Pixel;
	import com.robotacid.gfx.BlitClip;
	import com.robotacid.gfx.BlitRect;
	import com.robotacid.gfx.BlitSprite;
	import com.robotacid.gfx.FoodClockFX;
	import com.robotacid.gfx.Renderer;
	import com.robotacid.ui.BlitButton;
	import com.robotacid.ui.TextBox;
	import com.robotacid.ui.Key;
	import com.robotacid.ui.UIManager;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Shape;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.ui.Keyboard;
	import flash.utils.getTimer;
	/**
	 * Manages updating play and rendering it
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class Level {
		
		public static var renderer:Renderer;
		public static var game:Game;
		
		public var data:LevelData;
		public var previousData:LevelData;
		public var room:Room;
		public var blackOutMap:Array;
		
		public var uiManager:UIManager;
		public var foodClockGfx:FoodClockFX;
		public var undoButton:BlitButton;
		public var checkButton:BlitButton;
		public var settingsButton:BlitButton;
		public var resumeButton:BlitButton;
		public var quitButton:BlitButton;
		public var textBox:TextBox;
		
		public var active:Boolean;
		public var state:int;
		public var phase:int;
		public var animCount:int;
		public var keyDown:Boolean;
		public var canUndo:Boolean;
		public var checkView:Boolean;
		public var animAccCount:int;
		public var animDelay:int;
		public var moveStep:Number;
		public var restStep:Number;
		
		public var jumpTurns:int;
		
		public static const JUMP_TURNS_TOTAL:int = 2;
		
		private var blinkCount:int;
		public var blink:Boolean;
		
		// temp
		private var p:Point;
		
		// states
		public static const IDLE:int = 0;
		public static const ANIMATE:int = 1;
		
		// phases
		public static const PLAYER_PHASE:int = 0;
		public static const ENEMY_PHASE:int = 1;
		
		
		public static const SCALE:Number = Game.SCALE;
		public static const INV_SCALE:Number = 1 / Game.SCALE;
		public static const ANIM_FRAMES_MAX:int = 3;
		public static const ANIM_FRAMES_MIN:int = 2;
		public static const ANIM_ACC_DELAY:int = 10;
		public static const BLINK_DELAY:int = 30;
		public static const BLINK_DELAY_VISIBLE:int = 10;
		// turner rotation frames
		public static const TURNER_N:int = 0;
		public static const TURNER_NE:int = 1;
		public static const TURNER_E:int = 2;
		public static const TURNER_SE:int = 3;
		public static const TURNER_S:int = 4;
		public static const TURNER_SW:int = 5;
		public static const TURNER_W:int = 6;
		public static const TURNER_NW:int = 7;
		
		public static const MAP_HEIGHT:int = ROOM_HEIGHT;
		public static const ROOM_WIDTH:int = 16;
		public static const ROOM_HEIGHT:int = 15;
		public static const MAP_WIDTH:int = ROOM_WIDTH * 3;
		
		public function Level(type:int = Room.PUZZLE, dataObj:Object = null) {
			active = true;
			room = new Room(type, ROOM_WIDTH, ROOM_HEIGHT);
			if(!LevelData.initialised) LevelData.init();
			var dataWidth:int = MAP_WIDTH;
			var dataHeight:int = MAP_HEIGHT;
			data = new LevelData(room, dataWidth, dataHeight);
			if(dataObj){
				data.loadData(dataObj);
				if(type == Room.PUZZLE){
					//blackOutMap = data.getBlackOutMap();
				}
			}
			textBox = new TextBox(128, 32, 0x0, 0x0);
			state = IDLE;
			phase = PLAYER_PHASE;
			animDelay = ANIM_FRAMES_MAX;
			animAccCount = ANIM_ACC_DELAY;
			data.killCallback = kill;
			data.displaceCallback = displaceCamera;
			data.endingCallback = ending;
			data.ratchetCallback = ratchet;
			keyDown = false;
			blink = true;
			renderer.playerBlit.data = renderer.playerBuffer.data.clone();
			foodClockGfx = new FoodClockFX(renderer.playerBlit, Renderer.WALL_COL);
			renderer.numberBlit.setValue(data.food);
			previousData = data.copy();
			canUndo = false;
			
			uiManager = new UIManager();
			//checkButton = uiManager.addButton(Game.WIDTH - (renderer.checkButtonBlit.width + 2), 2, renderer.checkButtonBlit, toggleCheckView, new Rectangle(0, -2, renderer.checkButtonBlit.width + 2, renderer.checkButtonBlit.height + 2));
			//undoButton = uiManager.addButton(2, Game.HEIGHT - (renderer.undoButtonBlit.height + 2), renderer.leftButtonBlit, undo, new Rectangle(-2, 0, renderer.checkButtonBlit.width + 2, renderer.checkButtonBlit.height + 2));
			//undoButton.visible = false;
			//settingsButton = uiManager.addButton(Game.WIDTH - (renderer.settingsButtonBlit.width + 2), Game.HEIGHT - (renderer.settingsButtonBlit.height + 2), renderer.settingsButtonBlit, openSettings, new Rectangle(0, 0, renderer.settingsButtonBlit.width + 2, renderer.checkButtonBlit.height + 2));
			
			uiManager.addGroup();
			uiManager.changeGroup(1);
			var border:int = 2;
			var buttonRect:Rectangle = new Rectangle(0, 0, Game.SCALE * 2, Game.SCALE * 2);
			//uiManager.addButton(Game.WIDTH * 0.5 - 2 * Game.SCALE + border, Game.HEIGHT * 0.5 - Game.SCALE + border, renderer.backButtonBlit, quit, buttonRect);
			//uiManager.addButton(Game.WIDTH * 0.5 + 0 * Game.SCALE + border, Game.HEIGHT * 0.5 - Game.SCALE + border, renderer.playButtonBlit, resume, buttonRect);
			uiManager.changeGroup(0);
		}
		
		private function resume():void{
			uiManager.changeGroup(0);
		}
		
		private function quit():void{
			game.transition.begin(game.quit, 10, 10);
		}
		
		private function ratchet():void{
			//renderer.camera.displace( -room.width * SCALE, 0);
			renderer.displace( -room.width * SCALE, 0);
		}
		
		public function main():void{
			
			if(uiManager.active) uiManager.update(
				game.mouseX,
				game.mouseY,
				game.mousePressed,
				game.mousePressedCount == game.frameCount
			);
			
			var dir:int;
			if(state == IDLE){
				if(phase == PLAYER_PHASE){
					
					if(!uiManager.mouseLock && uiManager.currentGroup == 0) dir = getInput();
					
					var playerProperty:int = data.map[data.player.y][data.player.x];
					// don't repeat a blocked move - no dry humping the walls
					if(dir && !((playerProperty & LevelData.BLOCKED) && (playerProperty & LevelData.UP_DOWN_LEFT_RIGHT) == dir)){
						// accelerate animation length
						if(animAccCount){
							if(animDelay > ANIM_FRAMES_MIN) animDelay--;
						}
						animAccCount = ANIM_ACC_DELAY;
						data.playerTurn(dir);
						initAnimate();
					} else {
						if(animAccCount){
							animAccCount--;
							if(animAccCount == 0) animDelay = ANIM_FRAMES_MAX;
						}
					}
				} else if(phase == ENEMY_PHASE){
					data.enemyTurn();
					initAnimate();
				}
			} else if(state == ANIMATE){
				animCount--;
				if(animCount == 0){
					state = IDLE;
					if(phase == PLAYER_PHASE && !(data.map[data.player.y][data.player.x] & LevelData.BLOCKED)){
						data.player.resolveCollision();
						if(data.ended){
							active = false;
							if(room.type == Room.PUZZLE) game.puzzleWin();
						} else {
							phase = ENEMY_PHASE;
							blinkCount = BLINK_DELAY_VISIBLE;
						}
					}
					else if(phase == ENEMY_PHASE){
						data.resolveEntityCollisions();
						if(!data.player.active){
							active = false;
							if(data.score > LevelData.bestScore){
								LevelData.bestScore = data.score;
								Game.newBest = true;
							}
							game.soundQueue.add("death");
							game.death();
						} else {
							canUndo = data.food > 1;
							//undoButton.visible = canUndo;
						}
						phase = PLAYER_PHASE;
					}
				}
			}
			blinkCount--;
			if(blinkCount <= 0) blinkCount = BLINK_DELAY;
			blink = blinkCount >= BLINK_DELAY_VISIBLE;
		}
		
		public function initAnimate():void{
			state = ANIMATE;
			animCount = animDelay;
		}
		
		public function undo():void{
			if(canUndo && state == Level.IDLE && !renderer.captureFadeBitmap){
				clearUndo();
				data.copyData(previousData);
				data.food--;
				foodClockGfx.setFood(data.food, LevelData.FOOD_MAX, data.player.x * SCALE, data.player.y * SCALE);
				renderer.captureFade(0.08);
				renderer.camera.setTarget(
					(data.player.x + 0.5) * SCALE,
					(data.player.y + 0.5) * SCALE
				);
				renderer.camera.skipPan();
			}
		}
		
		public function clearUndo():void{
			canUndo = false;
			undoButton.visible = false;
		}
		
		public function toggleCheckView():void{
			checkView = !checkView;
			checkButton.active = checkView;
		}
		
		public function openSettings():void{
			if(game.editing){
				clearUndo();
				game.modifiedLevel = true;
				game.level.data.loadData(game.currentLevelObj);
				//game.roomPainter.setActive(true);
			} else {
				uiManager.changeGroup(1);
			}
		}
		
		public function getInput():int{
			var dir:int = 0;
			
			if(Key.keysPressed > 1) return 0;
			
			var player:Entity = data.player;
			
			// check the air
			var canJump:int = data.canJump(player.x, player.y);
			
			if(player.jumping){
				if(Key.isDown(Keyboard.Q) || Key.isDown(Keyboard.U)){
					//if(!(data.getProperty(player.x, player.y, Room.UP) & Room.WALL)){
						dir |= Room.UP;
					//}
					if(!(data.getProperty(player.x, player.y, Room.LEFT) & Room.WALL) && !(data.getProperty(player.x, player.y, Room.UP) & Room.WALL)){
						dir |= Room.LEFT;
					}
				}
				if(Key.isDown(Keyboard.W) || Key.isDown(Keyboard.I)) dir |= Room.UP;
				if(Key.isDown(Keyboard.E) || Key.isDown(Keyboard.O)){
					//if(!(data.getProperty(player.x, player.y, Room.UP) & Room.WALL)){
						dir |= Room.UP;
					//}
					if(!(data.getProperty(player.x, player.y, Room.RIGHT) & Room.WALL) && !(data.getProperty(player.x, player.y, Room.UP) & Room.WALL)){
						dir |= Room.RIGHT;
					}
				}
				if(Key.isDown(Keyboard.S) || Key.isDown(Keyboard.K)) dir |= Room.DOWN;
				if(Key.isDown(Keyboard.A) || Key.isDown(Keyboard.J)){
					if(!(data.getProperty(player.x, player.y, Room.LEFT) & Room.WALL)){
						dir |= Room.LEFT;
					} else {
						dir |= Room.DOWN
					}
					if(!(data.getProperty(player.x, player.y, Room.DOWN | Room.LEFT) & Room.WALL)){
						dir |= Room.DOWN;
					}
				}
				if(Key.isDown(Keyboard.D) || Key.isDown(Keyboard.L)){
					if(!(data.getProperty(player.x, player.y, Room.RIGHT) & Room.WALL)){
						dir |= Room.RIGHT;
					} else {
						dir |= Room.DOWN
					}
					if(!(data.getProperty(player.x, player.y, Room.DOWN | Room.RIGHT) & Room.WALL)){
						dir |= Room.DOWN;
					}
				}
				if(dir){
					if(!(data.getProperty(player.x, player.y, dir) & Room.WALL)) player.jumpCount--;
					if(player.jumpCount == 0 || (dir & Room.DOWN) || !(dir & Room.UP)){
						player.falling = true;
						player.jumping = false;
					}
				}
			} else if(player.falling){
				if(Key.isDown(Keyboard.A) || Key.isDown(Keyboard.Q) || Key.isDown(Keyboard.U) || Key.isDown(Keyboard.J)){
					if(
						!(data.getProperty(player.x, player.y, Room.LEFT) & Room.WALL) &&
						(data.getProperty(player.x, player.y, Room.DOWN | Room.LEFT) & Room.WALL)
					){
						dir |= Room.LEFT;
					} else {
						dir |= Room.DOWN;
					}
					if(
						!(data.getProperty(player.x, player.y, Room.LEFT) & Room.WALL) &&
						!(data.getProperty(player.x, player.y, Room.DOWN | Room.LEFT) & Room.WALL)
					){
						dir |= Room.LEFT;
					}
				}
				if(Key.isDown(Keyboard.S) || Key.isDown(Keyboard.K)) dir |= LevelData.DOWN;
				if(Key.isDown(Keyboard.D) || Key.isDown(Keyboard.E) || Key.isDown(Keyboard.O) || Key.isDown(Keyboard.L)){
					if(
						!(data.getProperty(player.x, player.y, Room.RIGHT) & Room.WALL) &&
						(data.getProperty(player.x, player.y, Room.DOWN | Room.RIGHT) & Room.WALL)
					){
						dir |= Room.RIGHT;
					} else {
						dir |= Room.DOWN;
					}
					if(
						!(data.getProperty(player.x, player.y, Room.RIGHT) & Room.WALL) &&
						!(data.getProperty(player.x, player.y, Room.DOWN | Room.RIGHT) & Room.WALL)
					){
						dir |= Room.RIGHT;
					}
				}
			} else {
				if((Key.isDown(Keyboard.A) || Key.isDown(Keyboard.J)) && !(data.getProperty(player.x, player.y, Room.LEFT) & Room.WALL)) dir |= Room.LEFT;
				if((Key.isDown(Keyboard.D) || Key.isDown(Keyboard.L)) && !(data.getProperty(player.x, player.y, Room.RIGHT) & Room.WALL)) dir |= Room.RIGHT;
				if(Key.isDown(Keyboard.Q) || Key.isDown(Keyboard.U)){
					dir |= Room.UP;
					if(!(data.getProperty(player.x, player.y, Room.LEFT) & Room.WALL) && !(data.getProperty(player.x, player.y, Room.UP) & Room.WALL)){
						dir |= Room.LEFT;
					}
				}
				if(Key.isDown(Keyboard.W) || Key.isDown(Keyboard.I)) dir |= Room.UP;
				if(Key.isDown(Keyboard.E) || Key.isDown(Keyboard.O)){
					dir |= Room.UP;
					if(!(data.getProperty(player.x, player.y, Room.RIGHT) & Room.WALL) && !(data.getProperty(player.x, player.y, Room.UP) & Room.WALL)){
						dir |= Room.RIGHT;
					}
				}
				if(dir & Room.UP){
					player.jumpCount = Entity.JUMP_DELAY;
					player.jumping = true;
				}
			}
			
			
			//if(Key.isDown(Keyboard.LEFT) || Key.isDown(Key.H) || Key.customDown(Game.LEFT_KEY)) dir |= LevelData.LEFT;
			//if(Key.isDown(Keyboard.RIGHT) || Key.isDown(Key.L) || Key.customDown(Game.RIGHT_KEY)) dir |= LevelData.RIGHT;
			//if(Key.isDown(Keyboard.DOWN) || Key.isDown(Key.J) || Key.customDown(Game.DOWN_KEY)) dir |= LevelData.DOWN;
			//if(game.mousePressed){
				//if(game.mouseCorner & LevelData.UP) dir |= LevelData.UP;
				//else if(game.mouseCorner & LevelData.RIGHT) dir |= LevelData.RIGHT;
				//else if(game.mouseCorner & LevelData.DOWN) dir |= LevelData.DOWN;
				//else if(game.mouseCorner & LevelData.LEFT) dir |= LevelData.LEFT;
			//}
			// disregard any more than one direction pressed
			//if(
				//(dir & LevelData.UP && dir & ~(LevelData.UP)) ||
				//(dir & LevelData.RIGHT && dir & ~(LevelData.RIGHT)) ||
				//(dir & LevelData.DOWN && dir & ~(LevelData.DOWN)) ||
				//(dir & LevelData.LEFT && dir & ~(LevelData.LEFT))
			//) dir = 0;
			return dir;
		}
		
		public function kill(x:int, y:int, explosion:int = 0):void{
			var i:int;
			for(i = 0; i < 6; i++){
				renderer.addDebris((x + Math.random()) * Game.SCALE, (y + Math.random()) * Game.SCALE, renderer.wallDebrisBlit, -1 + Math.random() * 2, -2 - Math.random() * 2);
			}
			renderer.addScore(10, 4 + x * Game.SCALE, y * Game.SCALE);
			renderer.shake(0, 5, new Pixel(x, y));
			game.createDistSound(x, y, "kill");
			if(explosion){
				game.createDistSound(x, y, "blast");
				renderer.addFX((x + 0.5) * SCALE, (y + 0.5) * SCALE, renderer.blastBlit);
			}
			
			//if(explosion){
				//renderer.addFX(x * SCALE, y * SCALE, renderer.explosionBlit, null, explosion);
			//}
			//if(property){
				//var blit:BlitSprite = getPropertyBlit(property) as BlitSprite;
				//var dirs:int = (~Room.rotateBits(dir, 2, LevelData.UP_DOWN_LEFT_RIGHT, 4)) & LevelData.UP_DOWN_LEFT_RIGHT;
				//if(property & LevelData.ENDING) dirs = dir;
				//renderer.bitmapDebris(blit, x, y, dirs);
				//if(property & LevelData.GENERATOR) renderer.bitmapDebris(renderer.generatorBlit, x, y, dirs);
			//}
			//var shakeX:int = 0, shakeY:int = 0;
			//if(dir & LevelData.UP) shakeY = -2;
			//else if(dir & LevelData.RIGHT) shakeX = 2;
			//else if(dir & LevelData.DOWN) shakeY = 2;
			//else if(dir & LevelData.LEFT) shakeX = -2;
			//renderer.shake(shakeX, shakeY);
		}
		
		public function ending(x:int, y:int, dir:int):void{
			renderer.refresh = false;
			renderer.trackPlayer = false;
			var segueSpeed:Number = 2;
			if(dir & LevelData.UP){
				renderer.slideY = segueSpeed;
			} else if(dir & LevelData.RIGHT){
				renderer.slideX = -segueSpeed;
			} else if(dir & LevelData.DOWN){
				renderer.slideY = -segueSpeed;
			} else if(dir & LevelData.LEFT){
				renderer.slideX = segueSpeed;
			}
			renderer.bitmapDebris(renderer.playerBlit, x, y, dir | Room.rotateBits(dir, 2, LevelData.UP_DOWN_LEFT_RIGHT, 4));
		}
		
		public function displaceCamera(x:int, y:int, revealDir:int, eraseDir:int):void{
			renderer.displace(x * SCALE, y * SCALE);
			renderer.addFX(0, 0, renderer.mapFadeBlits[revealDir], null, 0, false, false, false, true);
			// create render old room contents
			var bitmap:Bitmap
			var bx:Number = 0, by:Number = 0;
			if(eraseDir == LevelData.NORTH){
				bitmap = new Bitmap(renderMapSection(0, 0, data.width, room.height - 1));
			} else if(eraseDir == LevelData.EAST){
				bitmap = new Bitmap(renderMapSection(room.width, 0, room.width - 1, data.height));
				bx = room.width * SCALE;
			} else if(eraseDir == LevelData.SOUTH){
				bitmap = new Bitmap(renderMapSection(0, room.height, data.width, room.height - 1));
				by = room.height * SCALE;
			} else if(eraseDir == LevelData.WEST){
				bitmap = new Bitmap(renderMapSection(0, 0, room.width - 1, data.height));
			}
			var blit:BlitClip = new BlitClip(bitmap, null, 15);
			renderer.addFX(bx + x * SCALE, by + y * SCALE, blit, null, 0, true, false, false, true);
		}
		
		public function renderMapSection(x:int, y:int, width:int, height:int):BitmapData{
			var bitmapData:BitmapData = new BitmapData(width * SCALE, height * SCALE, true, 0x0);
			//var background:Shape = new Shape();
			//var matrix:Matrix = new Matrix();
			//matrix.tx = -x * SCALE;
			//matrix.ty = -y * SCALE;
			//background.graphics.lineStyle(0, 0, 0);
			//background.graphics.beginBitmapFill(renderer.backgroundBitmapData, matrix);
			//background.graphics.drawRect(0, 0, width * SCALE + 1, height * SCALE + 1);
			//bitmapData.draw(background);
			//var fromX:int = x;
			//var fromY:int = y;
			//var toX:int = x + width;
			//var toY:int = y + height;
			//var r:int, c:int;
			//var renderMap:Array = data.map;
			//for(r = fromY; r < toY; r++){
				//for(c = fromX; c < toX; c++){
					//if(
						//(c >= 0 && r >= 0 && c < data.width && r < data.height)
					//){
						//if(renderMap[r][c]){
							//renderProperty((c - x) * SCALE, (r - y) * SCALE, renderMap[r][c], bitmapData);
						//}
					//}
				//}
			//}
			return bitmapData;
		}
		
		public function renderProperty(x:Number, y:Number, property:int, bitmapData:BitmapData, mx:int, my:int):void{
			var blit:BlitRect, displace:Boolean = false, frame:int;
			if(property & LevelData.WALL){
				if(property & LevelData.SPECIAL){
					blit = renderer.specialBlit;
					//frame = game.frameCount % renderer.specialBlit.totalFrames;
				} else  if(property & LevelData.BOMB){
					blit = renderer.bombBlit;
				} else if(property & LevelData.METAL){
					blit = renderer.metalBlit;
				} else {
					blit = renderer.wallBlit;
					if(my >= data.height - 2) frame = 0;
					else{
						if(data.getProperty(mx, my, Room.UP) & Room.WALL){
							frame = 1;
						} else {
							frame = 2;
						}
					}
				}
				displace = phase == PLAYER_PHASE && Boolean(property & Room.UP)
			} else if(property & LevelData.VOID){
				blit = renderer.voidBlit;
			} else if(property & LevelData.SPIKES){
				blit = renderer.goombaBlit;
			} else return;
			if(bitmapData == renderer.bitmapData){
				blit.x = renderer.canvasPoint.x + x;
				blit.y = renderer.canvasPoint.y + y;
			} else {
				blit.x = x;
				blit.y = y;
			}
			// to create a neat square without a shadow we copy straight to the shadow bitmap
			if(property & LevelData.VOID){
				if(bitmapData == renderer.bitmapData){
					blit.render(renderer.bitmapShadow.bitmapData);
				} else {
					blit.render(bitmapData);
				}
				return;
			}
			if(state == ANIMATE && displace){
				// displace towards previous postion or nudge towards attacked position 
				if(property & LevelData.UP){
					blit.y += ((property & (LevelData.ATTACK | LevelData.BLOCKED)) ? -restStep : moveStep) * animCount;
				}
				if(property & LevelData.RIGHT){
					blit.x -= ((property & (LevelData.ATTACK | LevelData.BLOCKED)) ? -restStep : moveStep) * animCount;
				}
				if(property & LevelData.DOWN){
					blit.y -= ((property & (LevelData.ATTACK | LevelData.BLOCKED)) ? -restStep : moveStep) * animCount;
				}
				if(property & LevelData.LEFT){
					blit.x += ((property & (LevelData.ATTACK | LevelData.BLOCKED)) ? -restStep : moveStep) * animCount;
				}
			}
			//if(blit is BlitClip) frame = (blit as BlitClip).frame;
			blit.render(bitmapData, frame);
			
		}
		
		public function renderAvailable():void{
			var player:Entity = data.player;
			renderer.availableBlit.x = renderer.canvasPoint.x + player.x * SCALE;
			renderer.availableBlit.y = renderer.canvasPoint.x + player.y * SCALE;
			if(player.jumping){
				// w
				renderer.availableBlit.y = renderer.canvasPoint.y + (player.y - 1) * SCALE;
				renderer.availableBlit.render(renderer.guiBitmapData);
				// q
				renderer.availableBlit.x = renderer.canvasPoint.x + (player.x - 1) * SCALE;
				if(
					!(data.getProperty(player.x, player.y, Room.LEFT) & Room.WALL) &&
					!(data.getProperty(player.x, player.y, Room.UP) & Room.WALL)
				){
					renderer.availableBlit.render(renderer.guiBitmapData);
				}
				// e
				renderer.availableBlit.x = renderer.canvasPoint.x + (player.x + 1) * SCALE;
				if(
					!(data.getProperty(player.x, player.y, Room.RIGHT) & Room.WALL) &&
					!(data.getProperty(player.x, player.y, Room.UP) & Room.WALL)
				){
					renderer.availableBlit.render(renderer.guiBitmapData);
				}
				// s
				renderer.availableBlit.x = renderer.canvasPoint.x + (player.x - 0) * SCALE;
				renderer.availableBlit.y = renderer.canvasPoint.y + (player.y + 1) * SCALE;
				if(!(data.getProperty(player.x, player.y, Room.DOWN) & Room.WALL)){
					renderer.availableBlit.render(renderer.guiBitmapData);
				}
				// a
				renderer.availableBlit.x = renderer.canvasPoint.x + (player.x - 1) * SCALE;
				renderer.availableBlit.y = renderer.canvasPoint.y + (player.y + 1) * SCALE;
				if(!(data.getProperty(player.x, player.y, Room.LEFT) & Room.WALL)){
					if(data.getProperty(player.x, player.y, Room.LEFT | Room.DOWN) & Room.WALL){
						renderer.availableBlit.y = renderer.canvasPoint.y + (player.y + 0) * SCALE;
					}
					renderer.availableBlit.render(renderer.guiBitmapData);
				}
				// d
				renderer.availableBlit.x = renderer.canvasPoint.x + (player.x + 1) * SCALE;
				renderer.availableBlit.y = renderer.canvasPoint.y + (player.y + 1) * SCALE;
				if(!(data.getProperty(player.x, player.y, Room.RIGHT) & Room.WALL)){
					if(data.getProperty(player.x, player.y, Room.RIGHT | Room.DOWN) & Room.WALL){
						renderer.availableBlit.y = renderer.canvasPoint.y + (player.y + 0) * SCALE;
					}
					renderer.availableBlit.render(renderer.guiBitmapData);
				}
			} else if(player.falling){
				// s
				renderer.availableBlit.y = renderer.canvasPoint.y + (player.y + 1) * SCALE;
				renderer.availableBlit.render(renderer.guiBitmapData);
				// a
				renderer.availableBlit.x = renderer.canvasPoint.x + (player.x - 1) * SCALE;
				if(
					!(data.getProperty(player.x, player.y, Room.LEFT) & Room.WALL) &&
					!(data.getProperty(player.x, player.y, Room.LEFT | Room.DOWN) & Room.WALL)
				){
					renderer.availableBlit.render(renderer.guiBitmapData);
				}
				// d
				renderer.availableBlit.x = renderer.canvasPoint.x + (player.x + 1) * SCALE;
				if(
					!(data.getProperty(player.x, player.y, Room.RIGHT) & Room.WALL) &&
					!(data.getProperty(player.x, player.y, Room.RIGHT | Room.DOWN) & Room.WALL)
				){
					renderer.availableBlit.render(renderer.guiBitmapData);
				}
			} else {
				// w
				renderer.availableBlit.y = renderer.canvasPoint.y + (player.y - 1) * SCALE;
				renderer.availableBlit.render(renderer.guiBitmapData);
				// q
				renderer.availableBlit.x = renderer.canvasPoint.x + (player.x - 1) * SCALE;
				if(!(data.getProperty(player.x, player.y, Room.UP | Room.LEFT) & Room.WALL)){
					renderer.availableBlit.render(renderer.guiBitmapData);
				}
				// e
				renderer.availableBlit.x = renderer.canvasPoint.x + (player.x + 1) * SCALE;
				if(!(data.getProperty(player.x, player.y, Room.UP | Room.RIGHT) & Room.WALL)){
					renderer.availableBlit.render(renderer.guiBitmapData);
				}
				// a
				renderer.availableBlit.y = renderer.canvasPoint.y + (player.y - 0) * SCALE;
				renderer.availableBlit.x = renderer.canvasPoint.x + (player.x - 1) * SCALE;
				if(!(data.getProperty(player.x, player.y, Room.LEFT) & Room.WALL)){
					renderer.availableBlit.render(renderer.guiBitmapData);
				}
				// d
				renderer.availableBlit.x = renderer.canvasPoint.x + (player.x + 1) * SCALE;
				if(!(data.getProperty(player.x, player.y, Room.RIGHT) & Room.WALL)){
					renderer.availableBlit.render(renderer.guiBitmapData);
				}
			}
		}
		
		public function render():void{
			moveStep = SCALE / animDelay;
			restStep = moveStep * 0.5;
			var fromX:int = -renderer.canvasPoint.x * Game.INV_SCALE;
			var fromY:int = -renderer.canvasPoint.y * Game.INV_SCALE;
			var toX:int = 1 + fromX + Game.WIDTH * Game.INV_SCALE;
			var toY:int = 1 + fromY + Game.HEIGHT * Game.INV_SCALE;
			var property:int, i:int, r:int, c:int;
			var player:Point, p:Point;
			//var entities:Array/*Point*/ = [];
			var renderMap:Array = data.map;
			
			for(r = fromY; r < toY; r++){
				for(c = fromX; c < toX; c++){
					if(
						(c >= 0 && r >= 0 && c < data.width && r < data.height)
					){
						if(blackOutMap && uiManager.active && blackOutMap[r][c] == 0){
							renderProperty(c * SCALE, r * SCALE, LevelData.VOID, renderer.bitmapData, c, r);
							
						} else if(renderMap[r][c]){
							property = renderMap[r][c];
							// always render the allies last
							if(property & LevelData.ALLY){
								//entities.unshift(new Point(c, r));
								continue;
							} else if(property & LevelData.ENEMY){
								//entities.push(new Point(c, r));
								continue;
							}
							renderProperty(c * SCALE, r * SCALE, property, renderer.bitmapData, c, r);
							
						} else if(checkView){
						}
					}
				}
			}
			
			renderer.renderScore();
			
			var entity:Entity;
			// render objects above the map so blocked movement goes over the walls
			for(i = data.entities.length - 1; i > -1 ; i--){
				entity = data.entities[i];
				entity.render(entity.x * SCALE, entity.y * SCALE, renderer.bitmapData);
			}
			entity = data.player;
			if(entity.active) entity.render(entity.x * SCALE, entity.y * SCALE, renderer.bitmapData);
			
			//renderPathMap();
			
			// gui render
			if(uiManager.active){
				//renderer.turnsBlit.x = renderer.turnsBlit.y = 2;
				//renderer.turnsBlit.render(renderer.guiBitmapData);
				//renderer.numberBlit.x = renderer.turnsBlit.x + 2;
				//renderer.numberBlit.y = renderer.turnsBlit.y + 2;
				//renderer.numberBlit.setTargetValue(data.food);
				//renderer.numberBlit.update();
				//renderer.numberBlit.renderNumbers(renderer.guiBitmapData);
				//uiManager.render(renderer.guiBitmapData);
			}
			
			// ui
			var str:String = "" + data.score;
			while(str.length < 6) str = "0" + str;
			textBox.text = "score\n" + str;
			renderer.guiBitmapData.copyPixels(textBox.bitmapData, new Rectangle(0, 0, 128, 16), new Point(16, 16), null, null, true);
			str = "" + data.food;
			while(str.length < 3) str = "0" + str;
			textBox.text = "time\n " + str;
			renderer.guiBitmapData.copyPixels(textBox.bitmapData, new Rectangle(0, 0, 128, 16), new Point(Game.WIDTH - 48, 16), null, null, true);

			str = "" + LevelData.bestScore;
			while(str.length < 6) str = "0" + str;
			textBox.text = " best\n" + str;
			renderer.guiBitmapData.copyPixels(textBox.bitmapData, new Rectangle(0, 0, 128, 16), new Point(Game.WIDTH * 0.5 - 24, 16), null, null, true);
			
			//renderAvailable();
		}
		
		public function renderPathMap():void{
			var r:int, c:int;
			var size:int = LevelData.pathMap.length;
			var rect:Rectangle = new Rectangle(0, 0, 3, 3);
			var fill:uint;
			for(r = 0; r < size; r++){
				for(c = 0; c < size; c++){
					//rect.x = -renderer.canvasPoint.x + ((data.player.x - LevelData.ENEMY_ACTIVE_RADIUS) * SCALE) + c * SCALE;
					//rect.y = -renderer.canvasPoint.y + ((data.player.y - LevelData.ENEMY_ACTIVE_RADIUS) * SCALE) + r * SCALE;
					//rect.width = LevelData.pathMap[r][c];
					//renderer.bitmapData.fillRect(rect, 0xFFFFFF00);
					Game.debug.beginFill(0x00FF00, (1 / LevelData.pathMap.length) * LevelData.pathMap[r][c]);
					Game.debug.drawRect(((data.player.x - LevelData.ENEMY_ACTIVE_RADIUS) * SCALE) + c * SCALE, ((data.player.y - LevelData.ENEMY_ACTIVE_RADIUS) * SCALE) + r * SCALE, SCALE, SCALE);
				}
			}
		}
		
		public static function getLevelBitmapData(map:Array, width:int, height:int):BitmapData{
			var r:int, c:int;
			var col:uint, property:int;
			var bitmapData:BitmapData = new BitmapData(width, height, true, 0xFF282828);
			for(r = 0; r < height; r++){
				for(c = 0; c < width; c++){
					property = map[r][c];
					if(property & Room.ENEMY){
						bitmapData.setPixel32(c, r, 0xFFFFFFFF);
					} else if(property & Room.WALL){
						bitmapData.setPixel32(c, r, Renderer.WALL_COL);
					} else if(property & Room.ALLY){
						bitmapData.setPixel32(c, r, Renderer.UI_COL);
					} else if(c + r * width & 1){
						bitmapData.setPixel32(c, r, 0xFF3A3A3A);
					}
				}
			}
			return bitmapData;
		}
		
	}

}