package com.robotacid.util.misc {
	import com.robotacid.gfx.Renderer;
	
	/* A check to see if (x,y) is on screen plus a border */
	public function onScreen(x:Number, y:Number, renderer:Renderer, border:Number):Boolean{
		return x + border >= -renderer.canvasPoint.x && y + border >= -renderer.canvasPoint.y && x - border < -renderer.canvasPoint.x + Game.WIDTH && y - border < -renderer.canvasPoint.y + Game.HEIGHT;
	}

}