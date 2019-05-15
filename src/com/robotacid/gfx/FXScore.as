package com.robotacid.gfx {
	import com.robotacid.util.misc.onScreen;
	import flash.display.BitmapData;
	import flash.geom.Point;
	
	/**
	 * ...
	 * @author Aaron Steed, robotacid.com
	 */
	public class FXScore extends FX {
		
		public var riseCount:int;
		public var holdCount:int;
		public var score:int;
		
		public function FXScore(score:int, x:Number, y:Number, blit:ScoreBlit, bitmapData:BitmapData, canvasPoint:Point, delay:int) {
			super(x, y, blit, bitmapData, canvasPoint, new Point(0, -2), delay, true, true);
			riseCount = 16;
			holdCount = 8;
			this.score = score;
		}
		
		override public function main():void {
			if(frame < 0){
				frame++;
				return;
			}
			blit.x = (canvasPoint.x) + x;
			blit.y = (canvasPoint.y) + y;
			// just trying to ease the collosal rendering requirements going on
			if(
				blit.x + blit.dx + blit.width >= 0 &&
				blit.y + blit.dy + blit.height >= 0 &&
				blit.x + blit.dx <= Game.WIDTH &&
				blit.y + blit.dy <= Game.HEIGHT
			){
				(blit as ScoreBlit).renderValue(score, bitmapData);
			}
			if(dir){
				x += dir.x;
				y += dir.y;
			}
			if(riseCount){
				riseCount--;
				if(riseCount == 0){
					dir = null;
				}
			} else if(holdCount){
				holdCount--;
				if(holdCount == 0){
					active = false;
				}
			}
			if(!onScreen(x, y, renderer, 5) && killOffScreen) active = false;
		}
		
	}

}