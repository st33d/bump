package com.robotacid.gfx {
	import flash.display.BitmapData;
	import flash.display.MovieClip;
	import flash.geom.ColorTransform;
	import flash.geom.Rectangle;
	
	/**
	 * Renders a string of number from the current x,y position
	 * 
	 * Using setTargetValue and update rolls the numbers towards a target value
	 * 
	 * @author Aaron Steed, robotacid.com
	 */
	public class NumberBlit extends BlitClip {
		
		public var spacing:int;
		public var drums:Array;
		public var digits:int;
		public var value:Number;
		public var target:Number;
		public var step:Number;
		
		private var numHeight:int;
		
		// temps
		private var i:int;
		private var str:String;
		private var remainder:Number;
		private var digit:Number;
		private var valueI:int;
		
		public function NumberBlit(mc:MovieClip=null, colorTransform:ColorTransform=null, digits:int = 1, step:Number = 0.25) {
			super(mc, colorTransform);
			this.digits = digits;
			this.step = step;
			spacing = rect.width + 1;
			numHeight = height + 1
			data = new BitmapData(width, numHeight * (totalFrames + 1), true, 0x0);
			for(y = 0, i = 0; y < data.height; y += numHeight, i++){
				render(data, i % totalFrames);
			}
			frames[0] = data;
			drums = new Array(digits);
		}
		
		/* Rolls the number drums towards our target digits */
		public function update():void{
			if(value != target){
				if(value < target) value += step;
				if(value > target) value -= step;
				if(Math.abs(value - target) < step){
					setValue(target);
					return;
				}
				var valueI:int = value;
				remainder = value - valueI;
				str = valueI + "";
				if(digits){
					while(str.length < digits) str = "0" + str;
				}
				for(i = digits - 1; i > -1; i--){
					digit = int(str.charAt(i));
					drums[i] = digit + remainder;
					if(digit != 9) remainder = 0;
				}
			}
		}
		
		public function setTargetValue(n:int):void{
			target = n;
		}
		
		public function setValue(n:int):void{
			value = target = n;
			str = n + "";
			if(digits){
				while(str.length < digits) str = "0" + str;
			}
			for(i = 0; i < digits; i++){
				drums[i] = int(str.charAt(i));
			}
		}
		
		public function renderNumbers(bitmapData:BitmapData):void{
			var yTemp:Number = y;
			var rectTemp:Rectangle = rect.clone();
			for(i = 0; i < digits; i++){
				rect.y = drums[i] * numHeight;
				render(bitmapData);
				x += spacing;
			}
		}
		
	}

}