package com.robotacid.engine {
	import com.robotacid.gfx.BlitRect;
	import com.robotacid.gfx.DebrisFX;
	import com.robotacid.gfx.Renderer;
	import flash.display.BitmapData;
	import flash.geom.Point;
	/**
	 * ...
	 * @author Aaron Steed, robotacid.com
	 */
	public class Entity extends Point{
		
		public static var game:Game;
		public static var renderer:Renderer;
		
		public var active:Boolean;
		public var type:int;
		public var data:LevelData;
		public var jumping:Boolean;
		public var jumpCount:int;
		public var falling:Boolean;
		public var moveDir:int;
		public var blocked:Boolean;
		public var stomped:Boolean;
		public var flipped:Boolean;
		public var initialised:Boolean;
		public var looking:int;
		
		public static const JUMP_DELAY:int = 3;
		
		public static const MARIO:int = 0;
		public static const GOOMBA:int = 1;
		public static const COIN:int = 2;
		
		public function Entity(type:int, x:int, y:int, data:LevelData) {
			super(x, y);
			active = true;
			this.type = type;
			this.data = data;
			jumpCount = JUMP_DELAY;
			jumping = false;
			falling = false;
			stomped = false;
			if(type == GOOMBA){
				looking = Room.LEFT;
				//moveDir = Room.LEFT;
			}
		}
		
		public function resolveCollision():void{
			var i:int, entity:Entity;
			if(type == MARIO){
				for(i = 0; i < data.entities.length; i++){
					entity = data.entities[i];
					if(entity.x == x && entity.y == y && !entity.stomped){
						if(entity.type == GOOMBA){
							//if(moveDir & Room.DOWN){
								//entity.stomped = true;
								//moveDir = Room.UP;
								//if(!(data.getProperty(x, y, Room.UP) & Room.WALL)){
									//jumpCount = 0;
									//jumping = false;
									//falling = true;
									//y--;
								//} else {
									//blocked = true;
								//}
								//renderer.addScore(100, 2 + x * Game.SCALE, y * Game.SCALE);
								//data.addScore(100);
							//} else {
								kill();
								//trace("player move kill");
							//}
							break;
						} else if(entity.type == COIN){
							if(!flipped){
								if(moveDir & Room.DOWN){
									kill();
									//trace("player move kill");
								}
							} else {
								if(moveDir & Room.UP){
									kill();
									//trace("player move kill");
								}
							}
							//data.addScore(200);
							//renderer.addScore(200, 2 + x * Game.SCALE, y * Game.SCALE);
							//entity.kill();
						}
					}
				}
				if(active){
					if((data.map[y][x] & Room.SPIKES) && (moveDir & Room.DOWN)){
						kill();
					}
				}
			} else {
				entity = data.player;
				if(entity.x == x && entity.y == y){
					if(type == GOOMBA){
						entity.kill();
						
								//trace("enemy move kill");
					} else if(type == COIN){
						if(moveDir & Room.DOWN){
							entity.kill();
						}
					}
				} else {
				}
			}
			if(active && y >= data.height - 1){
				kill();
			}
		}
		
		public function flip():void{
			var score:int;
			if(type == COIN){
				score = 100;
			} else if(type == GOOMBA){
				score = 200;
			}
			data.addScore(score);
			renderer.addScore(score, 2 + x * Game.SCALE, y * Game.SCALE);
					flipped = true;
					moveDir = Room.DOWN;
		}
		
		public function checkNudge():void{
			var property:int = data.getProperty(x, y, Room.DOWN);
			if(property == 0 || (data.getProperty(x, y, Room.DOWN) & Room.BLOCKED)){
				if(type == COIN){
					flip();
					//active = false;
					//data.addScore(200);
					//renderer.addScore(200, 2 + x * Game.SCALE, y * Game.SCALE, 30);
					//var fx:DebrisFX = renderer.addDebris(x * Game.SCALE, y * Game.SCALE, renderer.coinCollectBlit, 0, -8);
					//fx.killY = y * Game.SCALE;
					//kill();
				} else if(type == GOOMBA){
					//active = false;
					//data.addScore(200);
					//renderer.addScore(200, 2 + x * Game.SCALE, y * Game.SCALE, 30);
					//renderer.addDebris(x * Game.SCALE, y * Game.SCALE, renderer.goombaFlippedBlit, 4, -8);
					flip();
				}
			}
		}
		
		public function kill():void{
			if(!active) return;
			active = false;
			if(type == MARIO){
				renderer.addDebris(x * Game.SCALE, y * Game.SCALE, renderer.playerDeathBlit, 0, -8);
			} else if(type == COIN){
			} else if(type == GOOMBA){
			}
		}
		
		public function render(x:int, y:int, bitmapData:BitmapData):void{
			var displace:Boolean;
			var blit:BlitRect;
			var frame:int;
			if(type == MARIO){
				displace = game.level.phase == Level.PLAYER_PHASE;
				
				if(jumping || falling){
					blit = renderer.playerBlit;
					if(jumping) frame = 1;
					else frame = 0;
				} else {
					blit = renderer.playerRunBlit;
					if(displace) frame = game.level.animCount;
					else {
						blit = renderer.playerBlit;
					}
				}
			} else if(type == GOOMBA){
				if(flipped){
					blit = renderer.goombaFlippedBlit;
				} else if(!stomped){
					displace = game.level.phase == Level.ENEMY_PHASE;
					blit = renderer.goombaBlit;
					//if(displace) frame = game.level.animCount % renderer.goombaBlit.totalFrames;
				} else {
					blit = renderer.goombaStompedBlit;
				}
			} else if(type == COIN){
				if(flipped){
					blit = renderer.coinCollectBlit;
					frame = game.frameCount % renderer.coinCollectBlit.totalFrames;
				} else {
					blit = renderer.coinBlit;
					frame = game.frameCount % renderer.coinBlit.totalFrames;
				}
			}
			blit.x = renderer.canvasPoint.x + x;
			blit.y = renderer.canvasPoint.y + y;
			if(game.level.state == Level.ANIMATE && displace){
				// displace towards previous postion or nudge towards attacked position 
				if(moveDir & LevelData.UP){
					blit.y += (blocked ? -game.level.restStep : game.level.moveStep) * game.level.animCount;
				}
				if(moveDir & LevelData.RIGHT){
					blit.x -= (blocked ? -game.level.restStep : game.level.moveStep) * game.level.animCount;
				}
				if(moveDir & LevelData.DOWN){
					blit.y -= (blocked ? -game.level.restStep : game.level.moveStep) * game.level.animCount;
				}
				if(moveDir & LevelData.LEFT){
					blit.x += (blocked ? -game.level.restStep : game.level.moveStep) * game.level.animCount;
				}
			}
			blit.render(bitmapData, frame);
		}
		
	}

}