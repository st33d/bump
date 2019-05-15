package com.robotacid.engine {
	import com.robotacid.gfx.DebrisFX;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	/**
	 * Data structure for the level and its contents
	 * 
	 * The data is designed so that all possible game states are bitwise flags on a 2D array.
	 * This keeps the scope small and portable. No good puzzle ever needed clutter.
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class LevelData {
		
		public var room:Room;
		public var active:Boolean;
		public var player:Entity;
		public var playerDir:int;
		public var oldPlayerX:int;
		public var oldPlayerY:int;
		public var width:int;
		public var height:int;
		public var map:Array/*Array*/;
		public var copyBuffer:Array/*Array*/;
		public var killCallback:Function;
		public var displaceCallback:Function;
		public var endingCallback:Function;
		public var ratchetCallback:Function;
		public var playerPush:Point;
		public var doorOpened:Point;
		public var food:int;
		public var score:int;
		public static var bestScore:int;
		public var ended:Boolean;
		public var initialised:Boolean = false;
		
		public var ratchetX:int;
		public var jumpTurns:int;
		public var entities:Array/*Entity*/;
		
		public static const TOTAL_JUMP_TURNS:int = 1;
		public static const RATCHET_DIST:int = 6;
		
		public static var pathMap:Array;
		public static var initialised:Boolean;
		
		// property constants
		public static const EMPTY:int = 0;
		public static const UP:int = 1 << 0;
		public static const RIGHT:int = 1 << 1;
		public static const DOWN:int = 1 << 2;
		public static const LEFT:int = 1 << 3;
		// direction memory states
		public static const M_UP:int = 1 << 4;
		public static const M_RIGHT:int = 1 << 5;
		public static const M_DOWN:int = 1 << 6;
		public static const M_LEFT:int = 1 << 7;
		public static const ATTACK:int = 1 << 8;
		public static const BLOCKED:int = 1 << 9;
		public static const PUSHED:int = 1 << 18;
		public static const GENERATOR:int = 1 << 21;
		public static const BOMB:int = 1 << 28;
		public static const SWAP:int = 1 << 20;
		public static const VOID:int = 1 << 27;
		public static const WALL:int = 1 << 10;
		public static const INDESTRUCTIBLE:int = 1 << 29;
		public static const TIMER_0:int = 1 << 22;
		public static const TIMER_1:int = 1 << 23;
		public static const TIMER_2:int = 1 << 24;
		public static const TIMER_3:int = 1 << 25;
		public static const ENEMY:int = 1 << 12;
		public static const ALLY:int = 1 << 26;
		public static const PLAYER:int = 1 << 11;
		public static const SPECIAL:int = 1 << 13;
		public static const VIRUS:int = 1 << 30;
		public static const TRAP:int = 1 << 19;
		public static const SPIKES:int = 1 << 17;
		public static const METAL:int = 1 << 14;
		public static const DECREMENT:int = 1 << 15;
		public static const INCREMENT:int = 1 << 16;
		public static const ENDING:int = 1 << 31;
		
		public static const UP_DOWN_LEFT_RIGHT:int = 15;
		public static var M_UP_DOWN_LEFT_RIGHT:int;
		public static var TIMER_MASK:int;
		public static const M_DIR_SHIFT:int = 4;
		
		public static function oppositeDirection(dir:int):int{
			if(dir & UP) return DOWN;
			else if(dir & RIGHT) return LEFT;
			else if(dir & DOWN) return UP;
			else if(dir & LEFT) return RIGHT;
			return 0;
		}
		
		public static const compass:Array = [UP, RIGHT, DOWN, LEFT];
		public static const NORTH:int = 0;
		public static const EAST:int = 1;
		public static const SOUTH:int = 2;
		public static const WEST:int = 3;
		public static const compassPoints:Array/*Point*/ = [new Point(0, -1), new Point(1, 0), new Point(0, 1), new Point( -1, 0)];
		
		public var inputsAvailable:int;
		
		// input keys
		public static const INPUT_UP_LEFT:int = 1 >> 0;
		public static const INPUT_UP:int = 1 >> 1;
		public static const INPUT_UP_RIGHT:int = 1 >> 2;
		public static const INPUT_DOWN_LEFT:int = 1 >> 3;
		public static const INPUT_DOWN:int = 1 >> 4;
		public static const INPUT_DOWN_RIGHT:int = 1 >> 5;
		
		public static const ENEMY_ACTIVE_RADIUS:int = 5;
		public static const PATH_MAP_SIZE:int = 1 + ENEMY_ACTIVE_RADIUS * 2;
		public static const PATH_WALL:int = int.MAX_VALUE;
		public static const FOOD_MAX:int = 400;
		public static const FOOD_KILL:int = 8;
		
		// temp
		private var p:Point;
		
		public function LevelData(room:Room, width:int, height:int) {
			this.room = room;
			player = new Entity(Entity.MARIO, 3, room.startY, this);
			this.width = width;
			this.height = height;
			food = FOOD_MAX;
			active = true;
			entities = [];
			jumpTurns = TOTAL_JUMP_TURNS;
			map = Room.create2DArray(width, height, VOID);
			copyBuffer = Room.create2DArray(width, height, VOID);
			room.addEntityCallback = createEntity;
			room.init(0);
			room.copyTo(map, 0, 0);
			addRoomEntities();
			room.init(room.width);
			room.copyTo(map, room.width, 0);
			addRoomEntities();
			room.init(room.width * 2);
			room.copyTo(map, room.width * 2, 0);
			addRoomEntities();
			//map[player.y][player.x] = PLAYER | ALLY;
			initialised = true;
		}
		
		public function addScore(n:int):void{
			score += n;
		}
		
		public function addRoomEntities():void{
			var obj:Object;
			for(var i:int = 0; i < room.entityPositions.length; i++){
				obj = room.entityPositions[i];
				createEntity(obj.x, obj.y, obj.type);
			}
			// remove floaters
			var entity:Entity;
			for(i = entities.length - 1; i > -1; i--){
				entity = entities[i];
				if(!entity.initialised){
					entity.initialised = true;
					if(!(getProperty(entity.x, entity.y, DOWN) & WALL)){
						entities.splice(i, 1);
					}
				}
			}
		}
		
		public static function init():void{
			initialised = true;
			M_UP_DOWN_LEFT_RIGHT = (LevelData.M_UP | LevelData.M_DOWN | LevelData.M_LEFT | LevelData.M_RIGHT);
			TIMER_MASK = TIMER_0 | TIMER_1 | TIMER_2 | TIMER_3;
			Room.M_UP_DOWN_LEFT_RIGHT = M_UP_DOWN_LEFT_RIGHT;
			pathMap = Room.create2DArray(1 + ENEMY_ACTIVE_RADIUS * 2, 1 + ENEMY_ACTIVE_RADIUS * 2, PATH_WALL);
		}
		
		public function canJump(x:int, y:int):int{
			var dir:int = 0;
			if(y > 0){
				if(!(map[y - 1][x] & WALL)) dir |= UP;
				if(x > 0 && !(map[y - 1][x - 1] & WALL)) dir |= LEFT;
				if(x < width - 1 && !(map[y - 1][x + 1] & WALL)) dir |= RIGHT;
			}
			return dir;
		}
		
		public function playerTurn(dir:int):void{
			playerDir = dir;
			// mutate the room
			room.moveMutate(dir);
			entityMove(player.x, player.y, playerDir, player);
			if(!player.blocked){
				
				// add new content
				if(ratchetX > room.width){
					ratchetCreate();
				}
				
				
				food--;
				
			}
		}
		
		public function createEntity(x:int, y:int, type:int):void{
			var entity:Entity = new Entity(type, x, y, this);
			entities.push(entity);
		}
		
		public function ratchetCreate():void{
			for(var i:int = 0; i < entities.length; i++){
				entities[i].x -= room.width;
			}
			Room.copyRectTo(map, new Rectangle(room.width, 0, room.width * 2, room.height), map, 0, 0, copyBuffer);
			room.init(room.width * 2);
			room.copyTo(map, room.width * 2, 0);
			ratchetX -= room.width;
			player.x -= room.width;
			addRoomEntities();
			if(Boolean(ratchetCallback)) ratchetCallback();
		}
		
		public function enemyTurn():void{
			// optimisation
			//moveEntities(entities);
			var entity:Entity;
			
			for(var i:int = entities.length - 1; i > -1; i--){
				entity = entities[i];
				if(!entity.flipped) entity.checkNudge();
				if(entity.active && entity.x >= ratchetX){
					if(!entity.stomped){
						if(entity.type == Entity.GOOMBA){
							if(!entity.flipped && (getProperty(entity.x, entity.y, DOWN) & WALL)){
								if(
									(getProperty(entity.x, entity.y, entity.looking) & WALL) ||
									!(getProperty(entity.x, entity.y, entity.looking | DOWN) & WALL)
								){
									if(entity.looking == RIGHT) entity.looking = LEFT;
									else entity.looking = RIGHT;
									if(
										(getProperty(entity.x, entity.y, entity.looking) & WALL) ||
										!(getProperty(entity.x, entity.y, entity.looking | DOWN) & WALL)
									){
										entity.moveDir = 0;
									} else	{
										entity.moveDir = entity.looking;
									}
								} else {
									entity.moveDir = entity.looking;
								}
							} else {
								entity.moveDir = DOWN;
							}
							entityMove(entity.x, entity.y, entity.moveDir, entity);
							
						} else if(entity.type == Entity.COIN){
							if(entity.flipped){
								entity.moveDir = DOWN;
								entityMove(entity.x, entity.y, entity.moveDir, entity);
							}
						}
					} else {
						entity.active = false;
					}
				} else {
					entities.splice(i, 1);
				}
			}
		}
		
		public function kill(x:int, y:int, explosion:int = 0):void{
			var property:int = map[y][x];
			map[y][x] = EMPTY;
			if(property & BOMB){
				explosion = 1;
				explode(x, y, explosion);
			}
			addScore(10);
			if(property != 0 && Boolean(killCallback)) killCallback(x, y, explosion);
		}
		
		public function resolveEntityCollisions():void{
			for(var i:int = entities.length - 1; i > -1; i--){
				entities[i].resolveCollision();
				if(entities[i].type == Entity.COIN && !entities[i].active) entities.splice(i, 1);
			}
			flushStatus(player.x, player.y, room.height);
			// the player dies when out of food
			if(player.active && food == 0) player.kill();
		}
		
		public function fullTurn(dir:int):void{
			playerTurn(dir);
			if(!(map[player.y][player.x] & BLOCKED)){
				enemyTurn();
			}
		}
		
		public function copy():LevelData{
			var level:LevelData = new LevelData(room, width, height);
			level.copyData(this);
			return level;
		}
		
		/* Deep copy */
		public function copyData(source:LevelData):void{
			var r:int, c:int;
			for(r = 0; r < height; r++){
				for(c = 0; c < width; c++){
					map[r][c] = source.map[r][c];
				}
			}
			playerDir = source.playerDir;
			player.x = source.player.x;
			player.y = source.player.y;
		}
		
		public function saveData():Object{
			var obj:Object = saveObject(width, height);
			obj.player.x = player.x;
			obj.player.y = player.y;
			var r:int, c:int;
			for(r = 0; r < height; r++){
				for(c = 0; c < width; c++){
					obj.map[r][c] = map[r][c];
				}
			}
			return obj;
		}
		
		public static function saveObject(width:int, height:int):Object{
			var obj:Object = {
				map:[],
				playerDir:UP,
				player:{x:(width * 0.5) >> 0, y:(height * 0.5) >> 0}
			}
			var r:int, c:int;
			for(r = 0; r < height; r++){
				obj.map[r] = [];
				for(c = 0; c < width; c++){
					obj.map[r][c] = VOID;
				}
			}
			return obj;
		}
		
		public static function writeToObject(source:Object, target:Object, width:int, height:int):void{
			target.player.x = source.player.x;
			target.player.y = source.player.y;
			var r:int, c:int;
			for(r = 0; r < height; r++){
				for(c = 0; c < width; c++){
					target.map[r][c] = source.map[r][c];
				}
			}
		}
		
		public function loadData(obj:Object):void{
			if(obj){
				var r:int, c:int;
				for(r = 0; r < height; r++){
					for(c = 0; c < width; c++){
						map[r][c] = obj.map[r][c];
					}
				}
				playerDir = obj.playerDir;
				player.x = obj.player.x;
				player.y = obj.player.y;
			} else {
				room.clear();
				room.copyTo(map, 0, 0);
				player.x = room.startX;
				player.y = room.startY;
			}
			map[player.y][player.x] = PLAYER | ALLY;
			food = FOOD_MAX;
		}
		
		/* Is a given move blocked? */
		public function empty(x:int, y:int, dir:int):Boolean{
			if(dir == UP){
				return y > 0 && map[y - 1][x] == EMPTY;
			} else if(dir == RIGHT){
				return x < width - 1 && map[y][x + 1] == EMPTY;
			} else if(dir == DOWN){
				return y < height - 1 && map[y + 1][x] == EMPTY;
			} else if(dir == LEFT){
				return x > 0 && map[y][x - 1] == EMPTY;
			}
			return false;
		}
		
		public function playerInAir():Boolean{
			return player.y < height - 1 && !(map[player.y + 1][player.x] & WALL);
		}
		
		public function getProperty(x:int, y:int, dir:int):int{
			if(y > 0 && dir == UP){
				return map[y - 1][x];
			}
			if(x < width - 1 && dir == RIGHT){
				return map[y][x + 1];
			}
			if(y < height - 1 && dir == DOWN){
				return map[y + 1][x];
			}
			if(x > ratchetX && dir == LEFT){
				return map[y][x - 1];
			}
			if(y > 0 && x > ratchetX && dir == (UP | LEFT)){
				return map[y - 1][x - 1];
			}
			if(y > 0 && x < width - 1 && dir == (UP | RIGHT)){
				return map[y - 1][x + 1];
			}
			if(y < height - 1 && x < width - 1 && dir == (DOWN | RIGHT)){
				return map[y + 1][x + 1];
			}
			if(y < height - 1 && x > ratchetX && dir == (DOWN | LEFT)){
				return map[y + 1][x - 1];
			}
			return WALL;
		}
		
		public function explode(x:int, y:int, explosion:int):void{
			if(y > 0){
				kill(x, y - 1, explosion + 1);
			}
			if(x < width - 1){
				kill(x + 1, y, explosion + 1);
			}
			if(y < height - 1){
				kill(x, y + 1, explosion + 1);
			}
			if(x > ratchetX){
				kill(x - 1, y, explosion + 1);
			}
		}
		
		public function getEntities(x:int, y:int):Array{
			var i:int;
			var list:Array = [];
			var entity:Entity;
			for(i = 0; i < entities.length; i++){
				entity = entities[i];
				list.push(entity);
			}
			return list;
		}
		
		public function nudge(x:int, y:int):void{
			map[y][x] |= UP | BLOCKED;
			var property:int = map[y][x];
			if(property & SPECIAL){
				property &= ~SPECIAL;
				property |= METAL;
				addScore(500);
				Game.renderer.addScore(500, 2 + x * Game.SCALE, y * Game.SCALE);
				Game.game.soundQueue.add("special");
				//var fx:DebrisFX = Game.renderer.addDebris(x * Game.SCALE, y * Game.SCALE, Game.renderer.coinCollectBlit, 0, -8);
				//fx.killY = y * Game.SCALE;
				map[y][x] = property;
			} else if(property & BOMB){
				kill(x, y);
			}
			if(y > 0 && (map[y][x] & WALL)){
				nudge(x, y - 1);
			}
			Game.renderer.shake(0, -3);
		}
		
		public function entityMove(x:int, y:int, dir:int, entity:Entity):void{
			// store without a direction and set direction
			//var property:int = map[y][x];
			//property |= dir;
			//map[y][x] = property;
			var target:int;
			var blocked:Boolean = true;
			//map[y][x] |= BLOCKED;
			// if the way is clear, load the space with property unblocked or mark as attacking
			if(dir == (UP | RIGHT)){
				if(y > 0 && x < width - 1){
					target = map[y - 1][x + 1];
					if(target & WALL){
						// blocked
						if(entity == player){
							// nudge
							nudge(x + 1, y - 1);
							player.jumping = false;
							Game.game.soundQueue.add("nudge");
						}
					} else {
						
						//map[y - 1][x + 1] = property;
						//map[y][x] = EMPTY;
						y--;
						x++;
						blocked = false;
						if(entity == player){
							if(x > ratchetX + RATCHET_DIST){
								ratchetX++;
							}
							Game.game.soundQueue.add("jump");
						}
					}
				}
			} else if(dir == (UP | LEFT)){
				if(y > 0 && x > 0){
					target = map[y - 1][x - 1];
					if(target & WALL){
						// blocked
						if(entity == player){
							// nudge
							nudge(x - 1, y - 1);
							player.jumping = false;
							Game.game.soundQueue.add("nudge");
						}
					} else {
						//map[y - 1][x - 1] = property;
						//map[y][x] = EMPTY;
						y--;
						x--;
						blocked = false;
						if(entity == player){
							Game.game.soundQueue.add("jump");
						}
					}
				}
			} else if(dir == (DOWN | RIGHT)){
				if(y < height - 1 && x < width - 1){
					target = map[y + 1][x + 1];
					if(target & WALL){
						// blocked
					} else {
						//map[y + 1][x + 1] = property;
						//map[y][x] = EMPTY;
						blocked = false;
						y++;
						x++;
						if(entity == player){
							if(x > ratchetX + RATCHET_DIST){
								ratchetX++;
							}
							Game.game.soundQueue.add("fall");
						}
					}
				}
			} else if(dir == (DOWN | LEFT)){
				if(y < height - 1 && x > 0){
					target = map[y + 1][x - 1];
					if(target & WALL){
						// blocked
					} else {
						//map[y + 1][x - 1] = property;
						//map[y][x] = EMPTY;
						y++;
						x--;
						blocked = false;
						if(entity == player){
							Game.game.soundQueue.add("fall");
						}
					}
				}
			} else if(dir == UP){
				if(y > 0){
					target = map[y - 1][x];
					if(target & WALL){
						// blocked
						if(entity == player){
							// nudge
							nudge(x, y - 1);
							player.jumping = false;
							Game.game.soundQueue.add("nudge");
						}
					} else {
						//map[y - 1][x] = property;
						//map[y][x] = EMPTY;
						blocked = false;
						y--;
						if(entity == player){
							Game.game.soundQueue.add("jump");
						}
					}
				}
			} else if(dir == RIGHT){
				if(x < width - 1){
					target = map[y][x + 1]
					if(target & WALL){
						// blocked
					} else {
						//map[y][x + 1] = property;
						//map[y][x] = EMPTY;
						blocked = false;
						x++;
						if(entity == player){
							Game.game.soundQueue.add("step");
							if(x > ratchetX + RATCHET_DIST){
								ratchetX++;
							}
						}
					}
				}
			} else if(dir == DOWN){
				if(y < height - 1){
					target = map[y + 1][x];
					if(target & WALL){
						// blocked
						if(entity.flipped){
							kill(x, y + 1);
							y++;
						}
					} else {
						//map[y + 1][x] = property;
						//map[y][x] = EMPTY;
						blocked = false;
						y++;
						if(entity == player){
							Game.game.soundQueue.add("fall");
						}
					}
				}
			} else if(dir == LEFT){
				if(x > 0){
					target = map[y][x - 1];
					if(target & WALL){
						// blocked
					} else {
						//map[y][x - 1] = property;
						//map[y][x] = EMPTY;
						blocked = false;
						x--;
						if(entity == player){
							Game.game.soundQueue.add("step");
						}
					}
				}
			}
			entity.x = x;
			entity.y = y;
			entity.blocked = blocked;
			entity.moveDir = dir;
			entity.falling = y < height - 1 && map[y + 1][x] == EMPTY;
		}
		
		
		/*public function getTypes(x:int, y:int, radius:int, type:int, ignore:int = 0):Array{
			var list:Array = [];
			var fromX:int = x - radius;
			var fromY:int = y - radius;
			var length:int = 1 + radius * 2;
			var toX:int = fromX + length;
			var toY:int = fromY + length;
			var r:int, c:int;
			for(r = fromY; r < toY; r++){
				for(c = fromX; c < toX; c++){
					if(c >= 0 && r >= 0 && c < width && r < height && (map[r][c] & type) && !(map[r][c] & ignore)){
						list.push(new Point(c, r));
					}
				}
			}
			return list;
		}*/
		
		/* Clear action data in an area */
		public function flushStatus(x:int, y:int, radius:int):Array{
			var list:Array = [];
			var fromX:int = x - radius;
			var fromY:int = y - radius;
			var length:int = 1 + radius * 2;
			var toX:int = fromX + length;
			var toY:int = fromY + length;
			var r:int, c:int, property:int;
			for(r = fromY; r < toY; r++){
				for(c = fromX; c < toX; c++){
					if(c >= 0 && r >= 0 && c < width && r < height){
						property = map[r][c];
						property &= ~(UP_DOWN_LEFT_RIGHT);
						property &= ~(ATTACK | BLOCKED | PUSHED);
						map[r][c] = property;
					}
				}
			}
			return list;
		}
		
		
	}

}