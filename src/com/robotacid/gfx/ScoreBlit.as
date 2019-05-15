package com.robotacid.gfx {
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.geom.ColorTransform;
	import flash.geom.Rectangle;
	
	/**
	 * ...
	 * @author Aaron Steed, robotacid.com
	 */
	public class ScoreBlit extends BlitSprite {
		
		public var spacing:int;
		
		
		public function ScoreBlit(mc:DisplayObject=null, colorTransform:ColorTransform=null) {
			super(mc, colorTransform);
			spacing = 4;
			rect = new Rectangle(0, 0, spacing, 8)
		}
		
		// fuck you myamoto
		public var hasGfx:Array = [true, true, true, false, true, true, false, false, true, false];
		public var digitPos:Array = [0, 3, 7, false, 11, 15, false, false, 19, false];
		
		public function renderValue(n:int, bitmapData:BitmapData):void{
			var str:String = n + "";
			var i:int, num:int;
			for(i = 0; i < str.length; i++){
				num = int(str.charAt(i));
				if(hasGfx[num]){
					rect.x = digitPos[num];
				} else {
					rect.x = 0;
				}
				render(bitmapData);
				x += spacing;
			}
		}
		
	}

}