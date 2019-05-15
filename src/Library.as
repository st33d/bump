package {
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.utils.ByteArray;
	
	/**
	 * Here's where I'm sticking all of the imported assets.
	 *
	 * All in one place as opposed to all over the fucking shop.
	 *
	 * @author steed
	 */
	public class Library {
		
		[Embed(source = "levels.json", mimeType = "application/octet-stream")] public static var LevelsData:Class;
		
		public static var levels:Array;
		public static var loadUserLevelsCallback:Function;
		public static var saveUserLevelsCallback:Function;
		
		public static var PERMANENT_LEVELS:Array;
		public static var USER_LEVELS:Array;
		
		public static const TOTAL_LEVELS:int = 100;
		
		public static function initLevels():void{
			var i:int;
			var byteArray:ByteArray = new LevelsData;
			PERMANENT_LEVELS = JSON.parse(byteArray.readUTFBytes(byteArray.length)) as Array;
			USER_LEVELS = [];
			for(i = 0; i < TOTAL_LEVELS; i++){
				if(!Boolean(PERMANENT_LEVELS[i])) PERMANENT_LEVELS[i] = null;
				USER_LEVELS[i] = null;
			}
			if(Boolean(loadUserLevelsCallback)) loadUserLevelsCallback();
			else {
				byteArray.position = 0;
				USER_LEVELS = JSON.parse(byteArray.readUTFBytes(byteArray.length)) as Array;
			}
		}
		
		public static function setLevels(permanent:Boolean = true):void{
			if(permanent){
				levels = PERMANENT_LEVELS;
			} else {
				levels = USER_LEVELS;
			}
		}
	}
}