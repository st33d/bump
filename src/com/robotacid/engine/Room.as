package com.robotacid.engine {
	import flash.geom.Point;
	import flash.geom.Rectangle;
	/**
	 * Manipulates an array the size of a level's room
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class Room {
		
		public var type:int;
		public var width:int;
		public var height:int;
		public var startX:int;
		public var endX:int;
		public var startY:int;
		public var endY:int;
		public var map:Array/*Array*/;
		public var doors:Array/*Point*/;
		public var compassPos:int;
		public var roomTurns:int;
		public var vertHalfway:int;
		public var horizHalfway:int;
		public var enemyProperties:Array;
		public var enemyLocations:Array;
		public var addEntityCallback:Function;
		public var allyList:Array;
		public var upgradeList:Array;
		
		// property constants
		public static const EMPTY:int = LevelData.EMPTY;
		public static const UP:int = LevelData.UP;
		public static const RIGHT:int = LevelData.RIGHT;
		public static const DOWN:int = LevelData.DOWN;
		public static const LEFT:int = LevelData.LEFT;
		// direction memory states
		public static const M_UP:int = LevelData.M_UP;
		public static const M_RIGHT:int = LevelData.M_RIGHT;
		public static const M_DOWN:int = LevelData.M_DOWN;
		public static const M_LEFT:int = LevelData.M_LEFT;
		public static const ATTACK:int = LevelData.ATTACK;
		public static const BLOCKED:int = LevelData.BLOCKED;
		public static const WALL:int = LevelData.WALL;
		public static const PLAYER:int = LevelData.PLAYER;
		public static const ENEMY:int = LevelData.ENEMY;
		public static const SPECIAL:int = LevelData.SPECIAL;
		public static const METAL:int = LevelData.METAL;
		//public static const HORIZ_MOVER:int = LevelData.HORIZ_MOVER;
		//public static const VERT_MOVER:int = LevelData.VERT_MOVER;
		public static const SPIKES:int = LevelData.SPIKES;
		public static const PUSHED:int = LevelData.PUSHED;
		public static const TRAP:int = LevelData.TRAP;
		public static const SWAP:int = LevelData.SWAP;
		public static const GENERATOR:int = LevelData.GENERATOR;
		public static const TIMER_0:int = LevelData.TIMER_0;
		public static const TIMER_1:int = LevelData.TIMER_1;
		public static const TIMER_2:int = LevelData.TIMER_2;
		public static const TIMER_3:int = LevelData.TIMER_3;
		public static const ALLY:int = LevelData.ALLY;
		public static const VOID:int = LevelData.VOID;
		public static const BOMB:int = LevelData.BOMB;
		public static const INDESTRUCTIBLE:int = LevelData.INDESTRUCTIBLE;
		public static const VIRUS:int = LevelData.VIRUS;
		public static const DECREMENT:int = LevelData.DECREMENT;
		public static const INCREMENT:int = LevelData.INCREMENT;
		public static const ENDING:int = LevelData.ENDING;
		
		// elements for content recipes:
		
		// individual dishes
		public static const ENEMIES:Array = [
			ENEMY | TRAP,
			ENEMY | SPIKES,
			METAL | M_LEFT | M_RIGHT,
			ENEMY | METAL | M_UP | M_DOWN,
			ENEMY | METAL | M_LEFT | M_RIGHT | M_UP | M_DOWN
		];
		
		// add one or more to make a meal more spicy
		public static const UPGRADES:Array = [
			GENERATOR | TIMER_3,
			WALL,
			BOMB
		];
		
		// player friendly meals
		public static const ALLIES:Array = [
			ALLY | SWAP,
			WALL | SWAP
		];
		
		// types
		public static const PUZZLE:int = 0;
		public static const ADVENTURE:int = 1;
		
		public static const NORTH:int = LevelData.NORTH;
		public static const EAST:int = LevelData.EAST;
		public static const SOUTH:int = LevelData.SOUTH;
		public static const WEST:int = LevelData.WEST;
		
		public static const UP_DOWN_LEFT_RIGHT:int = 15;
		public static var M_UP_DOWN_LEFT_RIGHT:int;
		
		public static const ENEMY_DEFAULT_TOTAL:int = 12;
		
		public function Room(type:int, width:int, height:int) {
			this.type = type;
			this.width = width;
			this.height = height;
			map = create2DArray(width, height, EMPTY);
			startPosition();
		}
		
		/* Creates the initial template room */
		public function startPosition():void{
			clear();
			startX = 0;
			endX = width - 1;
			startY = endY = height - 3;
			doors = [];
				//new Point(startX, 0),
				//new Point(width - 1, startY),
				//new Point(startX, height - 1),
				//new Point(0, startY)
			//];
			horizHalfway = startX;
			vertHalfway = startY;
			compassPos = NORTH;
			roomTurns = 0;
			
		}
		
		public function init(x:int):void{
			//if(type == ADVENTURE){
				debugPit(x);
			//} else if(type == PUZZLE){
				//clear();
			//}
			//create(door, revealDir);
			//clear();
			roomTurns++;
		}
		
		private function create(door:Point = null, revealDir:int = -1):void{
			setPropertyLocations(1, 1, width - 2, height - 2, map, ENEMY, enemyLocations, enemyProperties, SPECIAL);
			clear();
			var doors:Array = getDoors(door, revealDir);
			scatterFill(1, 1, width - 2, height - 2, map, LevelData.WALL, (width + height) * 2);
			var p:Point, property:int;
			while(enemyProperties.length){
				property = enemyProperties.pop();
				p = enemyLocations.pop();
				map[p.y][p.x] = property;
			}
			// clear the start position
			if(revealDir == -1) fill(startX - 2, startY - 2, 5, 5, map, EMPTY);
			connectDoors(doors);
		}
		
		public function clear():void{
			fill(0, 0, width, height, map, EMPTY);
			fill(0, height - 2, width, 2, map, WALL);
		}
		
		public function moveMutate(dir:int):void{
			var p:Point;
			compassPos = (compassPos + 1) % 4;
			//p = doors[compassPos];
			// move one door per turn clockwise,
			// the next compass direction from dir determines the direction of the door movement (spiral)
			//if(dir == UP && (p.y == 0 || p.y == height - 1)){
				//p.x++;
				//if(p.x > width - 2) p.x = 1;
				//horizHalfway--;
				//if(horizHalfway < 1) horizHalfway = width - 2;
			//} else if(dir == RIGHT && (p.x == 0 || p.x == width - 1)){
				//p.y++;
				//if(p.y > height - 2) p.y = 1;
				//vertHalfway--;
				//if(vertHalfway < 1) vertHalfway = height - 2;
			//} else if(dir == DOWN && (p.y == 0 || p.y == height - 1)){
				//p.x--;
				//if(p.x < 1) p.x = width - 2;
				//horizHalfway++;
				//if(horizHalfway > width - 2) horizHalfway = 1;
			//} else if(dir == LEFT && (p.x == 0 || p.x == width - 1)){
				//p.y--;
				//if(p.y < 1) p.y = height - 2;
				//vertHalfway++;
				//if(vertHalfway > height - 2) vertHalfway = 1;
			//}
		}
		
		public function killMutate(x:int, y:int, dir:int, property:int):void{
			//if(property & TRAP){
				//property |= dir << LevelData.M_DIR_SHIFT;
			//} else if(property & ENEMY){
				//LevelData.ENEMY
			//}
			//enemyProperties.push(property);
			//enemyLocations.push(new Point(x, y));
			
			
		}
		
		public function prepEnemyList():void{
		}
		
		/* Get where the doors should be in a new room (accounting for a door destroyed as well) */
		public function getDoors(door:Point = null, revealDir:int = -1):Array{
			var skipDir:int = -1;
			var doors:Array = this.doors.slice();
			if(revealDir == NORTH) skipDir = SOUTH;
			else if(revealDir == EAST) skipDir = WEST;
			else if(revealDir == SOUTH) skipDir = NORTH;
			else if(revealDir == WEST) skipDir = EAST;
			var i:int, p:Point;
			// random for now
			for(i = 0; i < 4; i++){
				if(i == skipDir){
					doors[i] = door;
					continue;
				}
				p = doors[i];
				map[p.y][p.x] = SPECIAL | ENEMY;
			}
			return doors;
		}
		
		public function connectDoors(doors:Array):void{
			var p:Point;
			var r:int, c:int, x:int, y:int;
			// N S
			x = doors[NORTH].x;
			p = doors[SOUTH];
			for(r = 1; r < height - 1; r++){
				map[r][x] = EMPTY;
				if(r == vertHalfway){
					while(x != p.x){
						if(x < p.x) x++;
						if(x > p.x) x--;
						map[r][x] = EMPTY;
					}
				}
			}
			// W E
			y = doors[WEST].y;
			p = doors[EAST];
			for(c = 1; c < width - 1; c++){
				map[y][c] = EMPTY;
				if(c == horizHalfway){
					while(y != p.y){
						if(y < p.y) y++;
						if(y > p.y) y--;
						map[y][c] = EMPTY;
					}
				}
			}
		}
		
		public function copyTo(target:Array, tx:int, ty:int):void{
			var r:int, c:int;
			for(r = 0; r < height; r++){
				for(c = 0; c < width; c++){
					target[ty + r][tx + c] = map[r][c];
				}
			}
		}
		
		public static function copyRectTo(source:Array, rect:Rectangle, target:Array, tx:int, ty:int, buffer:Array):void{
			var r:int, c:int;
			// buffering to account for any overlap
			for(r = 0; r < rect.height; r++){
				for(c = 0; c < rect.width; c++){
					buffer[r][c] = source[rect.y + r][rect.x + c];
				}
			}
			for(r = 0; r < rect.height; r++){
				for(c = 0; c < rect.width; c++){
					target[ty + r][tx + c] = buffer[r][c];
				}
			}
		}
		
		/* Used to clear out a section of a grid or flood it with a particular tile type */
		public static function fill(x:int, y:int, width:int, height:int, target:Array, index:int):void{
			var r:int, c:int;
			for(r = y; r < y + height; r++){
				for(c = x; c < x + width; c++){
					target[r][c] = index;
				}
			}
		}
		
		/* Scatter some tiles with Math.random */
		public static function scatterFill(x:int, y:int, width:int, height:int, target:Array, index:int, total:int, xStrip:int = 0, yStrip:int = 0, add:int = 0, onFloor:Boolean = false):void{
			var r:int, c:int;
			var rot:int;
			var breaker:int = 0;
			var yRepeat:int, xRepeat:int;
			while(total--){
				xRepeat = xStrip;
				yRepeat = yStrip;
				c = x + Math.random() * width;
				r = y + Math.random() * height;
				if(add){
					if(target[r][c] == add) target[r][c] |= index;
					else{
						total++;
						if(breaker++ > 200) break;
						continue;
					}
				} else if(onFloor){
					if(r < target.length - 2 && (target[r + 1][c] & WALL)){
						target[r][c] |= index;
					} else {
						total++;
						if(breaker++ > 200) break;
						continue;
					}
				} else {
					while(true){
						target[r][c] = index;
						if(xRepeat){
							xRepeat--;
							if(c < width - 1) c++;
						} else if(yRepeat){
							yRepeat--;
							if(r < height - 1) r++;
						} else {
							break;
						}
					}
				}
			}
		}
		
		/* Scatter some tiles with Math.random */
		public static function scatterFillList(x:int, y:int, width:int, height:int, target:Array, list:Array):void{
			var i:int, r:int, c:int;
			var rot:int;
			var breaker:int = 0;
			for(i = 0; i < list.length; i++){
				c = x + Math.random() * width;
				r = y + Math.random() * height;
				target[r][c] = list[i];
			}
		}
		
		public static function create2DArray(width:int, height:int, base:* = null):Array {
			var r:int, c:int, a:Array = [];
			for(r = 0; r < height; r++){
				a[r] = [];
				for(c = 0; c < width; c++){
					a[r][c] = base;
				}
			}
			return a;
		}
		
		/* Cyclically shift bits within a given range  - use a minus value for amount to shift left */
		public static function rotateBits(n:int, amount:int, rangeMask:int, rangeMaskWidth:int):int{
			var nRangeMasked:int = n & ~(rangeMask);
			n &= rangeMask;
			if(amount){
				var absAmount:int = (amount > 0 ? amount : -amount) % rangeMaskWidth;
				if(amount < 0){
					n = (n << absAmount) | (n >> (rangeMaskWidth - absAmount));
				} else if(amount > 0){
					n = (n >> absAmount) | (n << (rangeMaskWidth - absAmount));
				}
			}
			return (n & rangeMask) | nRangeMasked;
		}
		
		public static function setPropertyLocations(x:int, y:int, width:int, height:int, map:Array, property:int, locations:Array, properties:Array = null, ignore:int = 0):Array{
			var list:Array = [];
			var h:int = map.length;
			var w:int = map[0].length;
			var toX:int = x + width;
			var toY:int = y + height;
			var r:int, c:int;
			for(r = y; r < toY; r++){
				for(c = x; c < toX; c++){
					if(c >= 0 && r >= 0 && c < w && r < h && (map[r][c] & property) && !(map[r][c] & ignore)){
						locations.push(new Point(c, r));
						if(properties) properties.push(map[r][c]);
					}
				}
			}
			return list;
		}
		/* Scatter some tiles with Math.random */
		public function scatterFillEntities(xOffset:int, x:int, y:int, width:int, height:int, index:int, total:int, xStrip:int = 0, yStrip:int = 0, onFloor:Boolean = true):void{
			var r:int, c:int;
			var rot:int;
			var breaker:int = 0;
			var yRepeat:int, xRepeat:int;
			while(total--){
				xRepeat = xStrip;
				yRepeat = yStrip;
				c = x + Math.random() * width;
				r = y + Math.random() * height;
				if(onFloor){
					if(y < height - 2 && map[r + 1][c] & WALL){
						map[r][c] = EMPTY;
						entityPositions.push({x:c + xOffset, y:r, type:index});
					} else {
						total++;
						if(breaker++ > 200) break;
						continue;
					}
				} else {
					while(true){
						map[r][c] = EMPTY;
						entityPositions.push({x:c + xOffset, y:r, type:index});
						if(xRepeat){
							xRepeat--;
							if(c < width - 1) c++;
						} else if(yRepeat){
							yRepeat--;
							if(r < height - 1) r++;
						} else {
							break;
						}
					}
				}
			}
		}
		
		/* Create a hacky test area for debugging */
		public function debugPit(x:int):void{
			clear();
			
			startY = endY;
			
			endY = startY + ( -LevelData.TOTAL_JUMP_TURNS + Math.random() * LevelData.TOTAL_JUMP_TURNS * 2);
			
			if(endY > height - 3) endY = height - 3;
			if(endY < height - 10) endY = height - 10;
			
			
			entityPositions = [];
			
			//var doors:Array = getDoors(door, revealDir);
			scatterFill(0, 0, width, height - 2, map, WALL, 10, 6, 6);
			
			// trace routes to end
			var yPos:int = startY; var c:int;
			horizHalfway = Math.random() * width;
			for(c = 0; c < width; c++){
				map[yPos][c] = EMPTY;
				if(c == horizHalfway){
					while(yPos != endY){
						if(yPos < endY) yPos++;
						if(yPos > endY) yPos--;
						map[yPos][c] = EMPTY;
					}
				}
			}
			
			scatterFill(0, 0, width, height - 4, map, SPECIAL, 8, 0, 0, WALL);
			if(roomTurns > 3) scatterFill(0, 0, width, height - 4, map, BOMB, 8, 0, 0, WALL);
			
			if(x > 0){
				scatterFillEntities(x, 0, 0, width, height - 2, Entity.COIN, 12, 4, 0, true);
			} else {
				scatterFillEntities(x, width * 0.5, 0, width * 0.5, height - 2, Entity.COIN, 6, 4, 0, true);
			}
			
			if(roomTurns > 1) scatterFillEntities(x, 0, 0, width, height - 2, Entity.GOOMBA, 8, 3, 0, true);
			
			// clear the start position
			//if(revealDir == -1) fill(startX - 2, startY - 2, 5, 5, map, EMPTY);
			//fill(1, 1, width - 2, width - 2, map, WALL);
			// clear a path to the doors
			//connectDoors(doors);
			//map[startY - 3][startX + 2] = WALL;
			//map[startY - 3][startX + 3] = WALL | SPECIAL;
			//map[startY - 3][startX + 4] = WALL;
			//map[startY - 3][startX + 1] = WALL;
			//map[startY - 3][startX + 0] = WALL;
			//map[0][0] = WALL | SPECIAL;
			//map[0][width - 1] = WALL | SPECIAL;
			
			
			// clear start position
			if(x == 0){
				fill(0, 0, 8, height - 2, map, EMPTY);
			}
			
			
			//entityPositions.push({x:x + startX + 4, y:startY + 0, type:Entity.GOOMBA});
			//entityPositions.push({x:x + startX + 4, y:startY - 4, type:Entity.COIN});
			//entityPositions.push({x:x + startX + 2, y:startY - 4, type:Entity.GOOMBA});
			//map[startY + 1][startX + 1] = ENEMY | VIRUS;
			//map[startY][startX + 3] = ENEMY | VIRUS;
			//map[startY + 1][startX + 3] = ALLY | SWAP;
			//map[startY + 3][startX] = ENEMY | WALL | VIRUS | GENERATOR | TIMER_3;
			//map[startY][startX + 2] = ENEMY | MOVER | BOMB;
			//map[startY][startX + 3] = ENEMY | MOVER | BOMB;
			//map[startY][startX] = WALL | SWAP;
			//map[startY][startX] = ENEMY | TURNER | UP | WALL | GENERATOR | TIMER_3;
			//map[startY][startX] = ENEMY | TURNER | RIGHT | WALL;
			//map[startY][startX] = ENEMY | TRAP | M_UP | M_DOWN | WALL;
		}
		
		public var entityPositions:Array;
		
	}
	
	

}