﻿package com.robotacid.gfx {	import com.robotacid.engine.Entity;	import com.robotacid.engine.Level;	import com.robotacid.engine.LevelData;	import com.robotacid.geom.Pixel;	//import com.robotacid.ui.editor.RoomPainter;	//import com.robotacid.ui.editor.RoomPalette;	import com.robotacid.ui.Key;	import com.robotacid.ui.TextBox;	import com.robotacid.ui.ProgressBar;	import com.robotacid.ui.TitleMenu;	import flash.display.Bitmap;	import flash.display.BitmapData;	import flash.display.BlendMode;	import flash.display.Graphics;	import flash.display.MovieClip;	import flash.display.Shape;	import flash.display.Sprite;	import flash.display.Stage;	import flash.events.Event;	import flash.filters.ColorMatrixFilter;	import flash.geom.ColorTransform;	import flash.geom.Matrix;	import flash.geom.Point;	import flash.geom.Rectangle;	import flash.utils.getDefinitionByName;		/**	 * Manages all graphics rendering	 *	 * @author Aaron Steed, robotacid.com	 */	public class Renderer{				public var game:Game;		public var camera:CanvasCamera;				// gfx holders		public var canvas:Sprite;		public var canvasPoint:Point;		public var mouseScroll:Boolean;		public var bitmapData:BitmapData;		public var bitmapDataShadow:BitmapData;		public var guiBitmapData:BitmapData;		public var bitmap:Bitmap;		public var guiBitmap:Bitmap;		public var bitmapShadow:Bitmap;		public var backgroundShape:Shape;		public var backgroundBitmapData:BitmapData;		public var captureFadeBitmap:Bitmap;				// blits		public var sparkBlit:BlitRect;		public var wallBlit:BlitClip;		public var indestructibleWallBlit:BlitSprite;		public var playerBlit:BlitClip;		public var playerRunBlit:BlitClip;		public var playerDeathBlit:BlitSprite;		public var playerBuffer:BlitSprite;		public var allyBlit:BlitSprite;		public var moverBlit:BlitSprite;		public var horizMoverBlit:BlitSprite;		public var vertMoverBlit:BlitSprite;		public var turnerBlit:BlitClip;		public var virusBlit:BlitSprite;		public var debrisBlit:BlitRect;		public var enemyWallBlit:BlitSprite;		public var trapBlit:BlitClip;		public var errorBlit:BlitRect;		public var swapBlit:BlitRect;		public var generatorBlit:BlitSprite;		public var generatorWarningBlit:BlitRect;		public var turnsBlit:BlitSprite;		public var numberBlit:NumberBlit;		public var completedBlit:BlitRect;		public var timerCountBlit:BlitClip;		public var checkMarkBlit:BlitSprite;		public var propertySelectedBlit:BlitSprite;		public var roomPaletteBlit:BlitSprite;		public var parityBlit:BlitSprite;		public var voidBlit:BlitRect;		public var doorBlit:BlitClip;		public var bombBlit:BlitSprite;		public var explosionBlit:BlitClip;		public var mapFadeBlits:Array/*FadingBlitRect*/;		public var paintBlit:BlitClip;		public var lockedBlit:BlitSprite;		public var slideFade:BlitSprite;		public var availableBlit:BlitRect;		public var goombaBlit:BlitClip;		public var goombaStompedBlit:BlitSprite;		public var coinBlit:BlitClip;		public var coinCollectBlit:BlitClip;		public var scoreNumsBlit:ScoreBlit;		public var specialBlit:BlitClip;		public var metalBlit:BlitSprite;		public var goombaFlippedBlit:BlitSprite;				public var checkButtonBlit:BlitClip;		public var undoButtonBlit:BlitClip;		public var settingsButtonBlit:BlitClip;		public var playButtonBlit:BlitClip;		public var scrollButtonBlit:BlitClip;		public var propertyButtonBlit:BlitClip;		public var loadButtonBlit:BlitClip;		public var saveButtonBlit:BlitClip;		public var backButtonBlit:BlitClip;		public var quitButtonBlit:BlitClip;		public var confirmButtonBlit:BlitClip;		public var editButtonBlit:BlitClip;		public var numberButtonBlit:BlitClip;		public var leftButtonBlit:BlitClip;		public var rightButtonBlit:BlitClip;		public var menuButtonBlit:BlitClip;		public var confirmPanelBlit:BlitSprite;		public var levelMovePanelBlit:BlitSprite;		public var levelPreviewPanelBlit:BlitSprite;		public var swapButtonBlit:BlitClip;		public var insertBeforeButtonBlit:BlitClip;		public var insertAfterButtonBlit:BlitClip;				public var wallDebrisBlit:BlitSprite;		public var blastBlit:BlitClip;						// self maintaining animations		public var fx:Vector.<FX>;		public var scoreFx:Vector.<FX>;		public var roomFx:Vector.<FX>;		public var fxSpawn:Vector.<FX>; // fx generated during the filter callback must be added to a waiting list		public var fxFilterCallBack:Function;				// states		public var shakeOffset:Point;		public var shakeDirX:int;		public var shakeDirY:int;		public var captureFadeRate:Number;		public var trackPlayer:Boolean;		public var refresh:Boolean;		public var slideX:Number;		public var slideY:Number;				// temp variables		private var i:int;				public static var point:Point = new Point();		public static var matrix:Matrix = new Matrix();				// measurements from Game.as		public static const SCALE:Number = Game.SCALE;		public static const INV_SCALE:Number = Game.INV_SCALE;		public static const WIDTH:Number = Game.WIDTH;		public static const HEIGHT:Number = Game.HEIGHT;				public static const SHAKE_DIST_MAX:int = 12;		public static const INV_SHAKE_DIST_MAX:Number = 1.0 / SHAKE_DIST_MAX;		public static const WALL_COL_TRANSFORM:ColorTransform = new ColorTransform(1, 1, 1, 1, -100, -100, -100);		public static const WHITE_COL_TRANSFORM:ColorTransform = new ColorTransform(1, 1, 1, 1, 255, 255, 255);		public static const WALL_COL:uint = 0xff9b9b9b;		public static const UI_COL_TRANSFORM:ColorTransform = new ColorTransform(1, 1, 1, 1, -255 + 214, -255 + 232);		public static const UI_COL_BORDER_TRANSFORM:ColorTransform = new ColorTransform(1, 1, 1, 1, -255 + 166, -255 + 198, -255 + 239);		public static const UI_COL_BACK_TRANSFORM:ColorTransform = new ColorTransform(1, 1, 1, 1, -255 + 49, -255 + 59, -255 + 73);		public static const UI_COL:uint = 0xffd6e8ff;		public static const UI_COL_BORDER:uint = 0xffa6c6ef;		public static const UI_COL_BACK:uint = 0xff313b49;		public static const DEBRIS_SPEEDS:Array = [0.5, 1, 1.5, 2, 3, 2.5, 2, 1.5, 1];				public function Renderer(game:Game){			this.game = game;			trackPlayer = true;		}				/* Initialisation is separated from the constructor to allow reference paths to be complete before all		 * of the graphics are generated - an object is null until its constructor has been exited */		public function init():void{						FX.renderer = this;			FoodClockFX.renderer = this;			Level.renderer = this;			TitleMenu.renderer = this;			//RoomPainter.renderer = this;			//RoomPalette.renderer = this;			Entity.renderer = this;						sparkBlit = new BlitRect(0, 0, 1, 1, 0xffffffff);			debrisBlit = new BlitRect(0, 0, 1, 1, 0xffffffff);			wallBlit = new BlitClip(new WallMC);			indestructibleWallBlit = new BlitSprite(new IndestructibleMC);			enemyWallBlit = new BlitSprite(new EnemyWallMC);			trapBlit = new BlitClip(new TrapMC);			generatorBlit = new BlitSprite(new GeneratorMC);			generatorWarningBlit = new BlitRect(0, 0, 7, 7, 0xFFFFFFFF);			playerBlit = new BlitClip(new PlayerMC);			playerDeathBlit = new BlitSprite(new PlayerDeathMC);			playerRunBlit = new BlitClip(new PlayerRunMC);			playerBuffer = new BlitSprite(new PlayerMC);			allyBlit = new BlitSprite(new AllyMC);			moverBlit = new BlitSprite(new MoverMC);			horizMoverBlit = new BlitSprite(new HorizMoverMC);			vertMoverBlit = new BlitSprite(new VertMoverMC);			turnerBlit = new BlitClip(new TurnerMC);			virusBlit = new BlitSprite(new WallMC, WHITE_COL_TRANSFORM);			errorBlit = new BlitRect(3, 3, 3, 3, 0xFFFF0000);			swapBlit = new BlitSprite(new PlayerMC, WALL_COL_TRANSFORM);			numberBlit = new NumberBlit(new NumberMC, null, 2, 0.25);			completedBlit = new BlitRect(1, 1, 13, 7, 0xFF000000);			timerCountBlit = new BlitClip(new NumberMC);			timerCountBlit.rect = TextBox.characters[0].rect;			turnsBlit = new BlitSprite(new TurnsMC);			checkMarkBlit = new BlitSprite(new CheckMarkMC);			propertySelectedBlit = new BlitClip(new PropertySelectedMC);			roomPaletteBlit = new BlitSprite(new RoomPaletteMC);			parityBlit = new BlitClip(new ParityMC);			voidBlit = new BlitRect(0, 0, SCALE, SCALE, 0xFF000000);			doorBlit = new BlitClip(new DoorMC);			bombBlit = new BlitSprite(new BombMC);			explosionBlit = new BlitClip(new ExplosionMC);			errorBlit = new BlitRect(1, 1, 5, 5, 0xFFFF0000);						checkButtonBlit = new BlitClip(new CheckButton);			undoButtonBlit = new BlitClip(new UndoButton);			settingsButtonBlit = new BlitClip(new SettingsButton);			playButtonBlit = new BlitClip(new PlayButton);			propertyButtonBlit = new BlitClip(new PropertyButton);			scrollButtonBlit = new BlitClip(new ScrollButton);			settingsButtonBlit = new BlitClip(new SettingsButton);			loadButtonBlit = new BlitClip(new LoadButton);			saveButtonBlit = new BlitClip(new SaveButton);			backButtonBlit = new BlitClip(new BackButton);			quitButtonBlit = new BlitClip(new QuitButton);			confirmButtonBlit = new BlitClip(new ConfirmButton);			editButtonBlit = new BlitClip(new EditButton);			numberButtonBlit = new BlitClip(new NumberButton);			leftButtonBlit = new BlitClip(new LeftButton);			rightButtonBlit = new BlitClip(new RightButton);			menuButtonBlit = new BlitClip(new MenuButton);			swapButtonBlit = new BlitClip(new SwapButton);			insertBeforeButtonBlit = new BlitClip(new InsertBeforeButton);			insertAfterButtonBlit = new BlitClip(new InsertAfterButton);			confirmPanelBlit = new BlitSprite(new ConfirmPanelMC);			levelMovePanelBlit = new BlitSprite(new LevelMovePanelMC);			levelPreviewPanelBlit = new BlitSprite(new LevelPreviewPanelMC);			goombaStompedBlit = new BlitSprite(new GoombaStompedMC);			coinBlit = new BlitClip(new CoinMC);			coinCollectBlit = new BlitClip(new CoinCollectMC);			scoreNumsBlit = new ScoreBlit(new ScoreNumsMC);			specialBlit = new BlitClip(new SpecialMC);			metalBlit = new BlitSprite(new MetalMC);			wallDebrisBlit = new BlitSprite(new WallDebrisMC);			blastBlit = new BlitClip(new BlastMC);						availableBlit = new BlitRect(1, 1, 2, 2, 0xFF00FF00);			goombaBlit = new BlitClip(new GoombaMC);			goombaFlippedBlit = new BlitSprite(new GoombaFlippedMC);						var fade_delay:int = 10;			mapFadeBlits = [				new FadingBlitRect(0, 0, Level.MAP_WIDTH * SCALE, (Level.ROOM_HEIGHT - 1) * SCALE, fade_delay),				new FadingBlitRect(Level.ROOM_WIDTH * SCALE, 0, (Level.ROOM_WIDTH - 1) * SCALE, Level.MAP_HEIGHT * SCALE, fade_delay),				new FadingBlitRect(0, Level.ROOM_HEIGHT * SCALE, Level.MAP_WIDTH * SCALE, (Level.ROOM_HEIGHT - 1) * SCALE, fade_delay),				new FadingBlitRect(0, 0, (Level.ROOM_WIDTH - 1) * SCALE, Level.MAP_HEIGHT * SCALE, fade_delay),			];			paintBlit = new BlitClip(new PaintMC);			lockedBlit = new BlitSprite(new LockedMC);						slideFade = new BlitSprite();			slideFade.rect = new Rectangle(0, 0, Game.WIDTH, Game.HEIGHT);			slideFade.data = new BitmapData(Game.WIDTH, Game.HEIGHT, true, 0x08000000);						fxFilterCallBack = function(item:FX, index:int, list:Vector.<FX>):Boolean{				item.main();				return item.active;			};		}				/* Prepares sprites and bitmaps for a game session */		public function createRenderLayers(holder:Sprite = null):void{						if(!holder) holder = game;						canvasPoint = new Point();			canvas = new Sprite();			holder.addChild(canvas);						backgroundShape = new Shape();			backgroundBitmapData = new BackgroundFillBD(1, 1);						bitmapData = new BitmapData(WIDTH, HEIGHT, true, 0x0);			bitmap = new Bitmap(bitmapData);			bitmapDataShadow = bitmapData.clone();			bitmapShadow = new Bitmap(bitmapDataShadow);			guiBitmapData = new BitmapData(WIDTH, HEIGHT, true, 0x0);			guiBitmap = new Bitmap(guiBitmapData);						Game.debugShape = new Shape();			Game.debug = Game.debugShape.graphics;			Game.debugStayShape = new Shape();			Game.debugStay = Game.debugStayShape.graphics;			Game.debugStay.lineStyle(2, 0xFF0000);						canvas.addChild(backgroundShape);			canvas.addChild(bitmapShadow);			canvas.addChild(bitmap);			canvas.addChild(Game.debugShape);			canvas.addChild(Game.debugStayShape);			game.addChild(guiBitmap);						fx = new Vector.<FX>();			scoreFx = new Vector.<FX>();			roomFx = new Vector.<FX>();			fxSpawn = new Vector.<FX>();						camera = new CanvasCamera(canvasPoint, this);						shakeOffset = new Point();			shakeDirX = 0;			shakeDirY = 0;			slideX = 0;			slideY = 0;			refresh = true;		}				/* Destroy all objects */		public function clearAll():void{			while(canvas.numChildren > 0){				canvas.removeChildAt(0);			}			bitmap = null;			bitmapShadow = null;			bitmapData.dispose();			bitmapData = null;			fx = null;			game = null;		}				/* Clean graphics and reset camera - no object destruction/creation */		public function reset():void{			bitmapData.fillRect(bitmapData.rect, 0x0);			bitmapDataShadow.fillRect(bitmapData.rect, 0x0);			guiBitmapData.fillRect(bitmapData.rect, 0x0);			backgroundShape.graphics.clear();			var data:LevelData = game.level.data;			camera.mapRect = new Rectangle(0, 0, data.width * SCALE, data.height * SCALE);			camera.setTarget((data.ratchetX) * SCALE, 0);			camera.skipPan();			fx.length = 0;			scoreFx.length = 0;			slideX = slideY = 0;			refresh = true;			trackPlayer = true;		}				/* ================================================================================================		 * MAIN		 * Updates all of the rendering 		 * ================================================================================================		 */		public function main():void {						// clear bitmapDatas - refresh can be set to false for glitchy trails			if(refresh) bitmapData.fillRect(bitmapData.rect, 0x0);			bitmapDataShadow.fillRect(bitmapDataShadow.rect, 0x0);			guiBitmapData.fillRect(guiBitmapData.rect, 0x0);						if(game.state == Game.MENU){				game.titleMenu.render();				canvasPoint.x -= 0.5;								updateCheckers();							} else if(game.state == Game.GAME){				updateShaker();								var level:Level;				level = game.level;								if(trackPlayer){					camera.setTarget(						(level.data.ratchetX) * SCALE,						(level.data.player.y + 0.5) * SCALE					);				} else if(slideX || slideY){					camera.targetPos.x += slideX;					camera.targetPos.y += slideY;					slideFade.render(bitmapData);				}								camera.main();								updateCheckers();								// black border around small levels				if(canvasPoint.x > camera.mapRect.x){					bitmapDataShadow.fillRect(new Rectangle(0, 0, canvasPoint.x, Game.HEIGHT), 0xFF000000);				}				if(canvasPoint.x + camera.mapRect.x + camera.mapRect.width < Game.WIDTH){					bitmapDataShadow.fillRect(new Rectangle(canvasPoint.x + camera.mapRect.x + camera.mapRect.width, 0, Game.WIDTH - (canvasPoint.x + camera.mapRect.x + camera.mapRect.width), Game.HEIGHT), 0xFF000000);				}				if(canvasPoint.y > 0){					bitmapDataShadow.fillRect(new Rectangle(0, 0, Game.WIDTH, canvasPoint.y), 0xFF000000);				}				if(canvasPoint.y + camera.mapRect.height < Game.HEIGHT){					bitmapDataShadow.fillRect(new Rectangle(0, canvasPoint.y + camera.mapRect.height, Game.WIDTH, Game.HEIGHT - (canvasPoint.y + camera.mapRect.height)), 0xFF000000);				}								//if(game.roomPainter.active) game.roomPainter.render();				level.render();								if(fxSpawn.length){					fx = fx.concat(fxSpawn);					fxSpawn.length = 0;				}				if(fx.length) fx = fx.filter(fxFilterCallBack);								//bitmapDataShadow.copyPixels(bitmapData, bitmapData.rect, new Point(1, 1), null, null, true);				//bitmapDataShadow.colorTransform(bitmapDataShadow.rect, new ColorTransform(0, 0, 0));								if(roomFx.length) roomFx = roomFx.filter(fxFilterCallBack);								if(captureFadeBitmap){					captureFadeBitmap.alpha -= captureFadeRate;					if(captureFadeBitmap.alpha <= 0){						captureFadeBitmap.parent.removeChild(captureFadeBitmap);						captureFadeBitmap = null;					}				}			}					}				public function renderScore():void{								if(scoreFx.length) scoreFx = scoreFx.filter(fxFilterCallBack);					}				private function updateCheckers():void{			// checker background			backgroundShape.graphics.clear();			matrix.identity();			matrix.tx = canvasPoint.x;			matrix.ty = canvasPoint.y;			backgroundShape.graphics.lineStyle(0, 0, 0);			backgroundShape.graphics.beginBitmapFill(backgroundBitmapData, matrix);			backgroundShape.graphics.drawRect(0, 0, Game.WIDTH, Game.HEIGHT);			backgroundShape.graphics.endFill();		}				public function displace(x:Number, y:Number):void{			var i:int, item:FX;			for(i = 0; i < fx.length; i++){				item = fx[i];				item.x += x;				item.y += y;			}			for(i = 0; i < scoreFx.length; i++){				item = scoreFx[i];				item.x += x;				item.y += y;			}			camera.displace(x, y);		}				public function captureFade(rate:Number):void{			captureFadeRate = rate;			captureFadeBitmap = new Bitmap(new BitmapData(Game.WIDTH, Game.HEIGHT, true, 0xFFFF0000));			captureFadeBitmap.bitmapData.draw(canvas, new Matrix(), UI_COL_TRANSFORM);			canvas.addChild(captureFadeBitmap);			//captureFadeBitmap.x = bitmap.x;			//captureFadeBitmap.y = bitmap.y;		}				/* Shake the screen in any direction */		public function shake(x:int, y:int, shakeSource:Pixel = null):void {			if(!refresh) return;			// sourced shakes drop off in intensity by distance			// it stops the player feeling like they're in a cocktail shaker			if(shakeSource){				var dist:Number = Math.abs(game.level.data.player.x - shakeSource.x) + Math.abs(game.level.data.player.x - shakeSource.y);				if(dist >= SHAKE_DIST_MAX) return;				x = x * (SHAKE_DIST_MAX - dist) * INV_SHAKE_DIST_MAX;				y = y * (SHAKE_DIST_MAX - dist) * INV_SHAKE_DIST_MAX;				if(x == 0 && y == 0) return;			}			// ignore lesser shakes			if(Math.abs(x) < Math.abs(shakeOffset.x)) return;			if(Math.abs(y) < Math.abs(shakeOffset.y)) return;			shakeOffset.x = x;			shakeOffset.y = y;			shakeDirX = x > 0 ? 1 : -1;			shakeDirY = y > 0 ? 1 : -1;		}				/* resolve the shake */		private function updateShaker():void {			// shake first			if(shakeOffset.y != 0){				shakeOffset.y = -shakeOffset.y;				if(shakeDirY == 1 && shakeOffset.y > 0) shakeOffset.y--;				if(shakeDirY == -1 && shakeOffset.y < 0) shakeOffset.y++;			}			if(shakeOffset.x != 0){				shakeOffset.x = -shakeOffset.x;				if(shakeDirX == 1 && shakeOffset.x > 0) shakeOffset.x--;				if(shakeDirX == -1 && shakeOffset.x < 0) shakeOffset.x++;			}		}				/* Add to list */		public function addFX(x:Number, y:Number, blit:BlitRect, dir:Point = null, delay:int = 0, push:Boolean = true, looped:Boolean = false, killOffScreen:Boolean = true, room:Boolean = false):FX{			var item:FX = new FX(x, y, blit, bitmapData, canvasPoint, dir, delay, looped, killOffScreen);			if(room){				if(push) roomFx.push(item);				else roomFx.unshift(item);			} else {				if(push) fx.push(item);				else fx.unshift(item);			}			return item;		}				/* Add to list */		public function addDebris(x:Number, y:Number, blit:BlitRect, vx:Number = 0, vy:Number = 0, delay:int = 0, looped:Boolean = true):DebrisFX{			var item:DebrisFX;			item = new DebrisFX(x, y, blit, bitmapData, canvasPoint, delay, looped);			item.addVelocity(vx, vy);			fx.push(item);			return item;		}				public function addScore(score:int, x:Number, y:Number, delay:int = 0):FXScore{			var item:FXScore;			item = new FXScore(score, x, y, scoreNumsBlit, bitmapData, canvasPoint, delay);			scoreFx.push(item);			return item;		}				/* Cyclically throw off pixel debris from where white pixels used to be on the blit		 * use dir to specify bitwise flags for directions able to throw debris in */		public function bitmapDebris(blit:BlitSprite, x:int, y:int, dir:int = 15):void{			var r:int, c:int;			var blitClip:BlitClip = blit as BlitClip;			var bitmapData:BitmapData = blitClip ? blitClip.frames[blitClip.frame] : blit.data;			var compassIndex:int = 0, speedIndex:int = 0;			var compassPoint:Point, p:Point = new Point();			var debrisSpeed:Number, u:uint;			for(r = 0; r < blit.rect.height; r++){				for(c = 0; c < blit.rect.width; c++){					u = bitmapData.getPixel32(c, r);					if(u == 0xFFFFFFFF || u == WALL_COL){						compassPoint = LevelData.compassPoints[compassIndex];						debrisSpeed = DEBRIS_SPEEDS[speedIndex];						p.x = compassPoint.x * debrisSpeed;						p.y = compassPoint.y * debrisSpeed;						if(LevelData.compass[compassIndex] & dir) addFX(x * SCALE + c + blit.dx, y * SCALE + r + blit.dy, u == 0xFFFFFFFF ? debrisBlit : wallDebrisBlit, p.clone(), 0, true, true);						speedIndex++;						compassIndex++;						if(compassIndex >= LevelData.compassPoints.length) compassIndex = 0;						if(speedIndex >= DEBRIS_SPEEDS.length) speedIndex = 0;					}				}			}		}				/* The DebrisRect method I should have written		public function createDebrisRectDir(rect:Rectangle, vx:Number, vy:Number, quantity:int, type:int):void{			var x:Number, y:Number, blit:BlitRect, print:BlitRect;			for(var i:int = 0; i < quantity; i++){				x = rect.x + game.random.range(rect.width);				y = rect.y + game.random.range(rect.height);				if(game.random.coinFlip()){					blit = smallDebrisBlits[type];					print = smallFadeBlits[type];				} else {					blit = bigDebrisBlits[type];					print = bigFadeBlits[type];				}				addDebris(x, y, blit, vx + game.random.range(vx) , vy + game.random.range(vy), print, true);			}		} */			}}