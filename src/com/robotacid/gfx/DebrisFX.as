package com.robotacid.gfx {
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.geom.Point;
	
	/**
	* An FX object that falls off screen
	*
	* @author Aaron Steed, robotacid.com
	*/
	public class DebrisFX extends FX{
		
		public var dx:Number, dy:Number;
		public var px:Number;
		public var py:Number;
		public var killY:Number;
		
		// temp vars
		private static var tempX:Number;
		private static var tempY:Number;
		
		public static var IGNORE_PROPERTIES:int;// this is set in Game to Collider.CHARACTER | Collider.LEDGE | Collider.LADDER | Collider.HEAD | Collider.CORPSE
		// you can't set a constant using math with other constants
		
		public function DebrisFX(x:Number, y:Number, blit:BlitRect, bitmapData:BitmapData, canvasPoint:Point, delay:int = 0, looped:Boolean = false){
			super(x, y, blit, bitmapData, canvasPoint, null, delay, looped, true);
			px = x;
			py = y;
			killY = 512;
		}
		
		override public function main():void{
			// inlined verlet routine
			tempX = x;
			tempY = y;
			x += (x-px)*0.95;
			y += (y-py)+0.5;
			px = tempX;
			py = tempY;
			
			// render
			super.main();
			if(y > killY) active = false;
		}
		/* Calculate the normalised vector this particle is travelling on */
		public function getVector():void{
			var length:Number = Math.sqrt((x - px) * (x - px) + (y - py) * (y - py));
			if(length > 0){
				dx = (x - px) / length;
				dy = (y - py) / length;
			} else {
				dx = dy = 0;
			}
		}
		public function kill():void{
			if(!active) return;
			active = false;
		}
		
		public function addVelocity(x:Number, y:Number):void{
			px -= x;
			py -= y;
		}
		
		
	}
	
}