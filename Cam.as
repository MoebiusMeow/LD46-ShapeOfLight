package  
{
	import flash.display.*;
	public class Cam extends Sprite {
		var targetX:Number = 0, targetY:Number = 0;
		var targetScaleX:Number = 1, targetScaleY:Number = 1;
		public var itar_dist:Number = 1e9;
		public var bubble_on:int = 0;
		public var bubble_tar:Object = null;
		public var itar:Object = null;
		public var cameraState = "free_50";
		public function Cam() {
			hint.alpha = 0;
			bubble.alpha = 0;
		}
		public function ns(callBack:Function)
		{
			if(cut.currentFrame!=1) return;
			cut.callBack = callBack;
			cut.gotoAndPlay(2);
		}
		public function updUI(v:Number,dv:Number=0)
		{
			lightTxt.text = String(int(v))+"%";
			lightBar.inner.graphics.clear();
			lightBar.inner.graphics.beginFill(0xFFFFFF,1.0);
			lightBar.inner.graphics.drawRect(0,0,v*2,7);
			lightBar.inner.graphics.beginFill(dv>0?0x00FF00:0xFF0000,0.8);
			lightBar.inner.graphics.drawRect(v*2+Math.min(dv,0)*2,0,Math.abs(dv)*2,7);
			bubble.alpha = linearComb(bubble.alpha,bubble_on,0.8);
		}
		public function triggerBubble()
		{
			if(itar!=bubble_tar)
			{
				bubble_tar = itar;
				bubble_on = 0;
			}
			if(bubble_tar) bubble_on ^= 1;
			if(bubble_tar&&bubble_on)
			{
				if(bubble_tar is Pedestal) showBubble(ExtraConfig.texts["pedestal"+String(bubble_tar.currentFrame)]);
				else showBubble(ExtraConfig.texts[itar.name.search("instance")==-1?itar.name:"default"]);
			}
		}
		public function showHint(px:Number,py:Number)
		{
			hint.alpha = Math.max(0,Math.min(2-itar_dist/24,1));
			bubble.alpha = Math.min(bubble.alpha,hint.alpha);
			if(hint.alpha==0||itar!=bubble_tar) bubble_on = 0;
			hint.x = (px-x)/scaleX;
			hint.y = (py-y)/scaleY;
			if(bubble_tar!=null)
			{	
				bubble.x = (bubble_tar.x-x)/scaleX;
				bubble.y = (bubble_tar.y-y)/scaleY-50;
			}
		}
		public function showBubble(c:String)
		{
			if(c==null) return;
			bubble.x = hint.x;
			bubble.y = hint.y-50;
			bubble.txt.width = 1000;
			bubble.txt.text = c;
			bubble.txt.width = bubble.txt.textWidth+24;
			bubble.txt.x = -0.5*(bubble.txt.textWidth+24);
			bubble.txt.y = -bubble.txt.textHeight-12;
			bubble.graphics.clear();
			bubble.graphics.lineStyle(1,0xFFFFFF);
			bubble.graphics.beginFill(0,0.6);
			bubble.graphics.moveTo(-6,0);
			bubble.graphics.lineTo(0,10);
			bubble.graphics.lineTo(6,0);
			bubble.graphics.lineTo(0.5*(bubble.txt.textWidth+24),0);
			bubble.graphics.lineTo(0.5*(bubble.txt.textWidth+24),-bubble.txt.textHeight-24);
			bubble.graphics.lineTo(-0.5*(bubble.txt.textWidth+24),-bubble.txt.textHeight-24);
			bubble.graphics.lineTo(-0.5*(bubble.txt.textWidth+24),0);
			bubble.graphics.lineTo(-6,0);
		}
		public function focus(px:Number,py:Number,s:Number)
		{
			targetX = px-1024*s/2;
			targetY = py-720*s/2;
			targetScaleX = targetScaleY = s;
		}
		public function setto(t:CameraBox)
		{
			targetX = t.x;
			targetY = t.y;
			targetScaleX = targetScaleY = t.scaleX/8;
		}
		public function range()
		{
			x = Math.max(Math.min(1024-1024*scaleX,x),0);
			y = Math.max(Math.min(720-720*scaleY,y),0);
		}
		public function step()
		{
			x = linearComb(x,targetX,0.9);
			y = linearComb(y,targetY,0.9);
			scaleX = linearComb(scaleX,targetScaleX,0.9);
			scaleY = linearComb(scaleY,targetScaleY,0.9);
			range();
		}
		function linearComb(a:Number,b:Number,k:Number)
		{
			return a*k+b*(1-k);
		}
	}
}
