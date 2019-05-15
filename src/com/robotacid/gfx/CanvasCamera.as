package com.robotacid.gfx {
	import com.robotacid.sound.SoundManager;
	import com.robotacid.ui.Key;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.ui.Keyboard;
	import flash.ui.Mouse;
	
	/**
	 * Controls the view of the canvas
	 *
	 * @author Aaron Steed, robotacid.com
	 */
	public class CanvasCamera {
		
		public var renderer:Renderer;
		
		public var dragScroll:Boolean;
		public var uiStopDrag:Boolean;
		public var canvas:Point;
		public var canvasX:Number, canvasY:Number;
		public var lastCanvasX:Number, lastCanvasY:Number;
		public var mapRect:Rectangle;
		public var targetPos:Point;
		public var vx:Number, vy:Number;
		public var count:int;
		public var delayedTargetPos:Point;
		public var interpolation:Number;
		
		private var viewWidth:Number;
		private var viewHeight:Number;
		
		public static const DEFAULT_INTERPOLATION:Number = 0.2;
		public static const DRAG_SCROLL_INTERPOLATION:Number = 0.9;
		
		public static const UP:int = 1;
		public static const RIGHT:int = 2;
		public static const DOWN:int = 4;
		public static const LEFT:int = 8;
		
		
		public function CanvasCamera(canvas:Point, renderer:Renderer) {
			this.canvas = canvas;
			this.renderer = renderer;
			targetPos = new Point();
			dragScroll = false;
			count = 0;
			vx = vy = 0;
			interpolation = DEFAULT_INTERPOLATION;
			viewWidth = Game.WIDTH;
			viewHeight = Game.HEIGHT;
			mapRect = new Rectangle(0, 0, 13 * 3 * Game.SCALE, 13 * Game.SCALE);
		}
		
		/* This sets where the screen will focus on - the coords are a point on the canvas you want centered on the map */
		public function setTarget(x:Number, y:Number):void{
			targetPos.x = -x;// int( -x + viewWidth * 0.5);
			//if(targetPos.x > -mapRect.x) targetPos.x = -mapRect.x;
			//else if(targetPos.x < viewWidth - (mapRect.x + mapRect.width)) targetPos.x = viewWidth - (mapRect.x + mapRect.width);
			
			targetPos.y = 0;
			//int( -y + viewHeight * 0.5);
			//if(targetPos.y > -mapRect.y) targetPos.y = INTERFACE_BORDER_TOP;
			//else if(targetPos.y < -((mapRect.y + mapRect.height - viewHeight) + INTERFACE_BORDER_BOTTOM)) targetPos.y = -((mapRect.y + mapRect.height - viewHeight) + INTERFACE_BORDER_BOTTOM);
		}
		
		/* This sets where the screen will focus on - the coords are a point on the canvas you want centered on the map */
		public function displace(x:Number, y:Number):void{
			targetPos.x -= x;
			targetPos.y -= y;
			canvas.x -= x;
			canvas.y -= y;
			canvasX -= x;
			canvasY -= y;
			lastCanvasX -= x;
			lastCanvasY -= y;
		}
		
		/* Set a target to scroll to after a given delay */
		public function setDelayedTarget(x:Number, y:Number, delay:int):void{
			delayedTargetPos = new Point(x, y);
			count = delay;
		}
		
		/* No interpolation - jump straight to the target */
		public function skipPan():void{
			canvas.x = int(targetPos.x);
			canvas.y = int(targetPos.y);
			canvasX = lastCanvasX = canvas.x;
			canvasY = lastCanvasY = canvas.y;
			//back.y = canvas.y;
		}
		
		/* Get a target position to feed back to the Camera later */
		public function getTarget():Point{
			return new Point( -targetPos.x + viewWidth * 0.5, -targetPos.y + viewHeight * 0.5);
		}
		
		public function main():void {
			
			lastCanvasX = canvasX;
			lastCanvasY = canvasY;
			
			if(count > 0){
				count--;
				if(count <= 0) setTarget(delayedTargetPos.x, delayedTargetPos.y);
			}
			
			// update the canvas position
			if(dragScroll){
				if(renderer.game.mousePressed){
					if(!uiStopDrag){
						vx = renderer.game.mouseVx;
						vy = renderer.game.mouseVy;
					}
				} else {
					vx *= interpolation;
					vy *= interpolation;
				}
				if(canvasX + vx > Game.WIDTH * 0.5){
					canvasX = Game.WIDTH * 0.5;
					vx = 0;
				}
				if(canvasY + vy > Game.HEIGHT * 0.5){
					canvasY = Game.HEIGHT * 0.5;
					vy = 0;
				}
				if(canvasX + vx < -(mapRect.x + mapRect.width - Game.WIDTH * 0.5)){
					canvasX = -(mapRect.x + mapRect.width - Game.WIDTH * 0.5);
					vx = 0;
				}
				if(canvasY + vy < -(mapRect.y + mapRect.height - Game.HEIGHT * 0.5)){
					canvasY = -(mapRect.y + mapRect.height - Game.HEIGHT * 0.5);
					vy = 0;
				}
				uiStopDrag = false;
			} else {
				vx = (targetPos.x - canvasX) * interpolation;
				vy = (targetPos.y - canvasY) * interpolation;
			}
			canvasX += vx;
			canvasY += vy;
			//back.move(vx, vy);
			
			canvas.x = Math.round(canvasX) - renderer.shakeOffset.x;
			canvas.y = Math.round(canvasY) - renderer.shakeOffset.y;
		}
		
		public function toggleDragScroll():void{
			dragScroll = !dragScroll;
			interpolation = dragScroll ? DRAG_SCROLL_INTERPOLATION : DEFAULT_INTERPOLATION;
			vx = vy = 0;
		}
	}
	
}