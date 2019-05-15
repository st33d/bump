package com.robotacid.ui {
	import com.robotacid.gfx.BlitClip;
	import com.robotacid.gfx.BlitRect;
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	/**
	 * ...
	 * @author Aaron Steed, robotacid.com
	 */
	public class UIManager {
		
		public var active:Boolean;
		public var buttons:Array/*BlitButton*/;
		public var buttonGroups:Array/*Array*/;
		public var currentGroup:int;
		public var clicked:Boolean;
		public var mouseLock:Boolean;
		public var mouseOver:Boolean;
		public var lastButton:BlitButton;
		public var buttonsOver:Array/*BlitButton*/;
		public var ignore:Boolean;
		
		public static var dialog:UIManager;
		public static var mousePressedCallback:Function;
		
		private var i:int, button:BlitButton;
		
		public function UIManager(active:Boolean = true) {
			this.active = active;
			buttons = [];
			buttonsOver = [];
			buttonGroups = [buttons];
			currentGroup = 0;
		}
		
		public static function openDialog(buttonPoints:Array, buttonBlits:Array, buttonCallbacks:Array):UIManager{
			dialog = new UIManager();
			var i:int, point:Point, blit:BlitRect, f:Function;
			for(i = 0; i < buttonPoints.length; i++){
				point = buttonPoints[i];
				blit = buttonBlits[i];
				f = buttonCallbacks[i];
				dialog.addButton(point.x, point.y, blit, f, null, Boolean(f));
			}
			
			return dialog;
		}
		
		public static function confirmDialog(x:Number, y:Number, panel:BlitRect, okayCallback:Function, okayBlit:BlitRect, cancelBlit:BlitRect, cancelCallback:Function = null):UIManager{
			dialog = new UIManager();
			cancelCallback = cancelCallback || closeDialog;
			var i:int, point:Point, blit:BlitRect, f:Function;
			var buttonPoints:Array = [new Point(x, y), new Point(x + 3, y + 3), new Point(x + okayBlit.width + 4, y + 3)];
			var buttonBlits:Array = [panel, okayBlit, cancelBlit];
			var buttonCallbacks:Array = [null, okayCallback, cancelCallback];
			for(i = 0; i < buttonPoints.length; i++){
				point = buttonPoints[i];
				blit = buttonBlits[i];
				f = buttonCallbacks[i];
				dialog.addButton(point.x, point.y, blit, f, null, Boolean(f));
			}
			return dialog;
		}
		
		public static function closeDialog():void{
			dialog = null;
		}
		
		public function addButton(x:Number, y:Number, blit:BlitRect, callback:Function = null, area:Rectangle = null, states:Boolean = true):BlitButton{
			var button:BlitButton = new BlitButton(x, y, blit, callback, area, states);
			buttons.push(button);
			return button;
		}
		
		public function addGroup():void{
			buttonGroups.push([]);
		}
		
		public function changeGroup(n:int):void{
			currentGroup = n;
			buttons = buttonGroups[currentGroup];
			mouseLock = true;
		}
		
		public function update(mouseX:Number, mouseY:Number, mousePressed:Boolean, mouseClick:Boolean, mouseReleased:Boolean = false):void{
			buttonsOver.length = 0;
			if(!mousePressed){
				mouseLock = false;
				ignore = false;
			} else {
				if(ignore) return;
			}
			mouseOver = false;
			for(i = buttons.length - 1; i > -1; i--){
				button = buttons[i];
				if(
					mouseX >= button.x + button.area.x &&
					mouseY >= button.y + button.area.y &&
					mouseX < button.x + button.area.x + button.area.width &&
					mouseY < button.y + button.area.y + button.area.height
				){
					button.over = Game.MOBILE ? (mousePressed || mouseReleased) : true;
					if(button.over){
						mouseOver = true;
						if(button == lastButton) buttonsOver.unshift(button);
						else buttonsOver.push(button);
					}
					if(mouseClick){
						lastButton = button;
						if(Boolean(button.callback)){
							if(button.feedCallbackToEvent){
								mousePressedCallback = button.callback;
							} else {
								button.callback();
							}
						}
						mouseLock = true;
						button.heldCount = BlitButton.HELD_DELAY;
						break;
					} else if(mousePressed){
						if(button == lastButton){
							if(button.heldCount) button.heldCount--;
							else {
								button.held = true;
								if(Boolean(button.heldCallback)){
									button.heldCount = BlitButton.HELD_DELAY;
									button.heldCallback();
								}
							}
						} else {
							if(!button.focusLock){
								lastButton = button;
								if(Boolean(button.callback)) button.callback();
							}
						}
					}
				} else {
					if(button.over){
						button.over = false;
						button.held = false;
					}
				}
				
			}
			if(mouseReleased){
				if(lastButton && lastButton.over && Boolean(lastButton.releaseCallback)){
					lastButton.releaseCallback();
					lastButton.over = false;
				}
			}
			if(mouseClick && !mouseOver) ignore = true;
		}
		
		public function setActive(value:Boolean):void{
			active = value;
			mouseLock = !active;
		}
		
		public function render(bitmapData:BitmapData):void{
			for(i = 0; i < buttons.length; i++){
				button = buttons[i];
				if(button.visible) button.render(bitmapData);
			}
		}
		
	}

}