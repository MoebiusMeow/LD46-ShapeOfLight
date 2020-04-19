package 
{
	import flash.display.*;
	public class Player extends MovieClip
	{
		public var vx:Number = 0,vy:Number = 0;
		public var scaleH:Number = 1.0;
		public var faceRight:int = 1;
		public var state:String = "none";
		public function Player()
		{
		}
		public function setState(t:String)
		{
			if(state==t) return;
			state = t;
			gotoAndPlay(t);
		}
	}
}