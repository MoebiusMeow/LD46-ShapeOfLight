package  
{
	
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.filters.*;
	import flash.media.*;
	
	public class Main extends Sprite 
	{
		var shadowRes:Number = 2;
		var shadowBMD:BitmapData = new BitmapData(1024/shadowRes,720/shadowRes,true,0xFFFF0000);
		var shadowBMD_S:BitmapData = new BitmapData(1024/shadowRes,720/shadowRes,true,0xFFFF0000);
		var shadowBM:Bitmap = new Bitmap(shadowBMD);
		var levels:Levels = new Levels();
		var boxes:Vector.<HitBox> = new Vector.<HitBox>();
		var oboxes:Vector.<OpaqueBox> = new Vector.<OpaqueBox>();
		var lboxes:Vector.<LightBox> = new Vector.<LightBox>();
		var lboxes2:Vector.<LightBox> = new Vector.<LightBox>();
		var cboxes:Vector.<CameraBox> = new Vector.<CameraBox>();
		var iboxes:Vector.<IInter> = new Vector.<IInter>();
		var pedestals:Vector.<Pedestal>;
		var endBox:EndPoint;
		var itar:Object = null;
		var player:Player = new Player();
		var keyboardBinding:Object = {"left":65, "right":68, "down":83, "jump":32, "lantern":87, "interact":69};
		var keyIsDown:Object = {"left":0, "right":0, "down":0, "jump":0, "lantern":0, "interact":0};
		var keyTriggered:Object = {"left":0, "right":0, "down":0, "jump":0, "lantern":0, "interact":0};
		var globalG:Number = 0.4;
		var onGround:int = 0;
		var lanternState = 0;
		var mainCam:Cam = new Cam();
		var curLight:Number = 50;
		var deltaLight:Number = 0;
		var lightLevel:Number = 1;
		var curLevel:int = 1;
		var gameEnd:int = 0;
		var levelFs:int = 0;
		var levelCom:int = 0;
		var bgmSC:SoundChannel = null;
		var ending:Ending = new Ending();

		public function Main() 
		{
			addChild(mainCam);
			mainCam.scaleX = mainCam.scaleY = 0.5;
			this.addEventListener(Event.ADDED_TO_STAGE,onAts);
		}

		function onAts(e:Event)
		{
			player.lantern.gotoAndStop(2);
			loadLevel(curLevel);
			addChild(levels);

			shadowBM.scaleX = shadowBM.scaleY = shadowRes;
			//shadowBM.filters = [new BlurFilter(20,20,1)];
			updStaticShadow();
			updShadow();
			addChild(shadowBM);

			//Fps.setup(this,0,100,0.5);
			//Fps.visible = true;

			stage.addEventListener(Event.ENTER_FRAME,onEnt);
			stage.addEventListener(KeyboardEvent.KEY_DOWN,onKd);
			stage.addEventListener(KeyboardEvent.KEY_UP,onKu);
		}

		function onEnt(e:Event)
		{
			if(!gameEnd)
			{
				addChild(mainCam);
				updPhysic();
				updInteract();
				updCam();
				updShadow();
				if(endBox&&endBox.hitTestPoint(player.x,player.y-28))
				{
					levelCom = 1;
					mainCam.ns(levelFinish);
				}
			}
			else
			{
				ending.y -= 0.5;
				if(ending.y<-ending.height+720)
					ending.y = -ending.height+720;
			}
		}

		function onKd(e:KeyboardEvent)
		{
			//trace(e.keyCode);
			for(var s:String in keyboardBinding) if(keyboardBinding[s]==e.keyCode)
				keyIsDown[s] = 1;
		}

		function onKu(e:KeyboardEvent)
		{
			for(var s:String in keyboardBinding) if(keyboardBinding[s]==e.keyCode)
				keyIsDown[s] = keyTriggered[s] = 0;
		}

		function bgmLoop(e:Event)
		{
			(bgmSC = (new BGM()).play()).addEventListener(Event.SOUND_COMPLETE,bgmLoop);
		}

		function updCam()
		{
			for each(var o:CameraBox in cboxes)
			{
				if(o.hitTestPoint(player.x,player.y-28)&&o.name.charAt(0)=='t')
					mainCam.cameraState = o.name.split("_")[1]+"_"+o.name.split("_")[2];
			}
			var state:Array = mainCam.cameraState.split("_");
			if(!levelCom)
			{
				if(state[0]=='free')
				{
					mainCam.focus(player.x,player.y-28,int(state[1])/100);
				}
				else
				{
					if(levelFs==0)
					{
						levelFs = 1;
						(bgmSC = (new BGM()).play()).addEventListener(Event.SOUND_COMPLETE,bgmLoop);
					}
					mainCam.setto(levels.getChildByName("cam_"+state[1]) as CameraBox);
				}
			}
			else
				mainCam.targetY -= 0.5;
			mainCam.step();
			mainCam.updUI(curLight,deltaLight*10);
			if(itar) mainCam.showHint(itar.x,itar.y);
			this.x = -mainCam.x/mainCam.scaleX;
			this.y = -mainCam.y/mainCam.scaleY;
			this.scaleX = 1.0/mainCam.scaleX;
			this.scaleY = 1.0/mainCam.scaleY;
		}

		function updInteract()
		{
			itar = null;
			var m:Number = 1e9;
			for each(var o:IInter in iboxes)
			{
				var v:Number = Math.pow((o as Object).x-player.x,2)+Math.pow((o as Object).y-(player.y-28),2);
				if(v<m) m = v, itar = o;
			}
			mainCam.itar_dist = Math.sqrt(m);
			mainCam.itar = itar;
			if(keyIsDown["lantern"]&&keyTriggered["lantern"]==0)
			{
				lanternState = (lanternState+1)%2;
				player.lantern.gotoAndStop(2-lanternState);
				(new Se4()).play();
				keyTriggered["lantern"] = 1;
			}
			if(keyIsDown["interact"]&&keyTriggered["interact"]==0)
			{
				if(itar is IBub) mainCam.triggerBubble();
				if(mainCam.itar_dist<48)
				{
					(new Se4()).play();
				}
				if(itar&&itar is Pedestal2&&mainCam.itar_dist<48)
				{
					itar.callBack = levelToEnd;
					itar.play();
					circleLight(shadowBMD_S,new Point(itar.x,itar.y),720,720);
					levelCom = 1;
					//levelEnd();
					iboxes.splice(iboxes.indexOf(itar),1);
					itar = null;
					mainCam.itar_dist = 1e9;
					mainCam.itar = null;
				}
				if(itar&&itar is Door&&mainCam.itar_dist<48)
				{
					if(itar.currentFrame==1)
					{
						itar.HitBox.disabled = 1;
						itar.OpaqueBox.disabled = 1;
						updStaticShadow();
						itar.gotoAndStop(2);
					}
					else
					{
						itar.HitBox.disabled = 0;
						itar.OpaqueBox.disabled = 0;
						updStaticShadow();
						itar.gotoAndStop(1);
					}
				}
				keyTriggered["interact"] = 1;
			}
		}

		function updPhysic()
		{
			var eps:Number = 0.1;
			player.vy += globalG;
			player.x += player.vx;
			player.y += player.vy;
			//trace(player.x,player.vx)
			onGround -= 1;
			var o:HitBox;
			var slopeFix:Number = 0;
			for each(o in boxes) if((o as Object).disabled!=1) if(o is SlopeHitBox||o is HitBoxP)
			{
				if(keyIsDown["down"]) continue;
				if(player.x+6<=o.x||player.x-6>=o.x+o.width) continue;
				var limy:Number;
				if(o is SlopeHitBoxL) limy = o.y+o.scaleY/o.scaleX*(player.x-6-o.x);
				else if(o is SlopeHitBoxR) limy = o.y+o.scaleY/o.scaleX*(o.x+o.width-(player.x+6));
				else limy = o.y;
				limy = Math.max(o.y,limy);
				//trace(player.y,limy)
				if(player.y-player.vy<=limy+3&&player.y+2>limy)
				{
					if(player.y<limy) slopeFix = limy-player.y+1;
					player.scaleH = Math.max((player.vy-globalG)*0.05+1,player.scaleH);
					if(player.state=='jump') player.setState("stand");
					player.y = limy, player.vy = 0, onGround = 5;
					break;
				}
			}
			for each(o in boxes) if((o as Object).disabled!=1) if(!(o is SlopeHitBox||o is HitBoxP))
			{
				if(player.x+16<=o.x||player.x-16>=o.x+o.width) continue;
				if(player.y<=o.y||player.y-56>=o.y+o.height) continue;
				//trace(player.y-(player.vy+5+eps)-o.y)
				if(player.y-(player.vy+slopeFix+eps)<=o.y||player.y-(player.vy-eps)-56>=o.y+o.height)
				{
					if(player.vy>=0)
					{
						player.scaleH = Math.max((player.vy-globalG)*0.05+1,player.scaleH);
						if(player.vy-globalG>0) player.setState("stand");
						player.y = o.y, player.vy = 0, onGround = 5;
					}
					if(player.vy<0) player.y = o.y+o.height+56, player.vy *= -0.5;
				}
				if(player.x+16<=o.x||player.x-16>=o.x+o.width) continue;
				if(player.y<=o.y||player.y-56>=o.y+o.height) continue;
				if(player.x-(player.vx+eps)+16<=o.x||player.x-(player.vx-eps)-16>=o.x+o.width)
				{
					if(player.vx>0) player.x = o.x-16;
					if(player.vx<0) player.x = o.x+o.width+16;
					player.vx = 0;
				}
			}
			player.vx *= onGround>0?0.7:0.99;
			if(Math.abs(player.vx)<1e-3) player.vx = 0;
			if(onGround>0&&keyTriggered["jump"]==0&&keyIsDown["jump"])
			{
				player.vy -= 7.5;
				keyTriggered["jump"] = 1;
				player.setState("jump");
			}
			if(keyIsDown["left"])
			{
				player.vx -= onGround>0?0.5:0.05;
				player.faceRight = -1;
				if(onGround&&player.vy==0) player.setState("run");
			}
			if(keyIsDown["right"])
			{
				player.vx += onGround>0?0.5:0.05;
				player.faceRight = 1;
				if(onGround&&player.vy==0) player.setState("run");
			}
			if(player.state=="run"&&!keyIsDown["left"]&&!keyIsDown["right"]&&onGround&&player.vy==0)
			{
				player.setState("stand");
			}
			player.scaleY = Math.exp(player.vy*0.03);
			player.scaleX = player.scaleH*player.faceRight;
			player.scaleH = player.scaleH*0.8+1.0*0.2;
		}

		function updStaticShadow()
		{
			shadowBMD_S.fillRect(shadowBMD_S.rect,0xFF000000);
			for each(var o:LightBox in lboxes)
			{
				circleLight(shadowBMD_S,new Point(o.x,o.y),o.width/2,o.height/2,uint((1-o.alpha)*0xFF)*0x1000000);
			}
			for each(var q:Pedestal in pedestals) if(q.currentFrame==2)
				circleLight(shadowBMD_S,new Point(q.x,q.y),180,120);
		}

		function updShadow()
		{
			//shadowBMD.fillRect(new Rectangle(mouseX/shadowRes,mouseY/shadowRes,30,30),0);
			//shadowBMD.fillRect(new Rectangle(mouseX/shadowRes,mouseY/shadowRes-10,10,30),0);
			//circleLight(shadowBMD,new Point(mouseX,mouseY),70,70);

			for each(var o:Pedestal in pedestals)
			{
				deltaLight = lightSense(o.x,o.y);
				if(deltaLight>=0.8&&o.currentFrame==1)
				{
					circleLight(shadowBMD_S,new Point(o.x,o.y),180,120);
					o.gotoAndStop(2);
				}
			}
			shadowBMD.copyPixels(shadowBMD_S,shadowBMD.rect,new Point(0,0));
			for each(var u:LightBox in lboxes2)
			{
				var v:Object = levels.getChildByName("Line_"+u.name.split("_")[1]);
				if(!v) continue;
				circleLight(shadowBMD,new Point(v.x+v.scaleX*v.tar.x,v.y+v.scaleY*v.tar.y),u.width/2,u.height/2,uint((1-u.alpha)*0xFF)*0x1000000);
			}

			deltaLight = lightSense(player.x+player.scaleX*player.lantern.x,player.y+player.lantern.y);
			//trace(deltaLight)
			if(deltaLight>lightLevel) lightLevel = deltaLight;
			else lightLevel = lightLevel*0.95+deltaLight*0.05;
			deltaLight = (lightLevel-0.5);
			curLight += deltaLight;
			if(curLight>100) curLight = 100;
			if(curLight<0)
			{
				curLight = 0;
				levelCom = 1;
				mainCam.ns(levelFailed);
			}

			var auraSize:Number = lanternState;
			auraSize *= Math.max(0.2,curLight/100);
			circleLight(shadowBMD,new Point(player.x+player.scaleX*player.lantern.x,player.y+player.lantern.y),150*auraSize,120*auraSize);
			shadowBMD.applyFilter(shadowBMD,shadowBMD.rect,new Point(0,0),new BlurFilter(7,7,3));
		}

		function platCompare(a:HitBox,b:HitBox)
		{
			return (a is SlopeHitBox?a.y:a is HitBoxP?a.y-2:1e9)-(b is SlopeHitBox?b.y:b is HitBoxP?b.y-2:1e9);
		}

		function lightCompare(a:LightBox,b:LightBox)
		{
			return a.alpha-b.alpha;
		}

		function sigmentCompare(a:Point,b:Point)
		{
			if(a.x<b.x) return -1;
			if(a.x>b.x) return 1;
			return a.y-b.y;
		}

		function circleLight(bmd:BitmapData,center:Point,rx:Number,ry:Number,color:uint=0,steps:int=40,y_res:Number=1)
		{
			var x_y:Number = rx/ry;
			var half:int = Math.ceil(ry/shadowRes/y_res);
			var breaks:Vector.<Vector.<Point>> = new Vector.<Vector.<Point>>(half*2+1,true);
			var y:int, i:int;
			for(y=-half;y<=half;y++) breaks[y+half] = new Vector.<Point>();
			for(i=0;i<oboxes.length;i++) if((oboxes[i] as Object).disabled!=1)
			{
				var o:OpaqueBox = oboxes[i];
				if(center.y-ry>o.y+o.height||center.y+ry<o.y) continue;
				if(center.x-rx>o.x+o.width||center.x+rx<o.x) continue;
				//for(var u:int=0;u<2;u++)
				if(center.y<o.y||center.y>o.y+o.height)
				{
					var k:Number = (o.y>center.y?o.y:o.y+o.height);
					var step_k:Number = (k>center.y?y_res:-y_res)*shadowRes;
					var range_l:Number = (o.x);
					var range_r:Number = (o.x+o.width);
					var step_l:Number = (range_l-center.x)/(k-center.y)*step_k;
					var step_r:Number = (range_r-center.x)/(k-center.y)*step_k;
					while(k>center.y-ry&&k<center.y+ry)
					{
						breaks[int((k-center.y)/shadowRes/y_res)+half].push(new Point(Math.floor(range_l),Math.ceil(range_r)));
						range_l += step_l;
						range_r += step_r;
						k += step_k;
					}
				}
				var bounds_l:Vector.<int> = new Vector.<int>();
				var bounds_r:Vector.<int> = new Vector.<int>();
				var bounds_x:Vector.<Number> = new Vector.<Number>(4,true);
				bounds_l.push(2);
				bounds_r.push(3);
				if(center.x<o.x-1||center.x>o.x+o.width+1)
				{
					var v:Number = center.x<o.x?o.x:o.x+o.width;
					bounds_x[2] = center.x<o.x?o.x:-1e9;
					bounds_x[3] = center.x<o.x?1e9:o.x+o.width;
					((center.y<=Math.floor(o.y))==(center.x<o.x)?bounds_r:bounds_l).push(0);
					((center.y>Math.floor(o.y)+o.height)==(center.x<o.x)?bounds_r:bounds_l).push(1);
					for(y=-half;y<=half;y++)
					{
						bounds_x[0] = center.x+(v-center.x)/no0(Math.floor(o.y)-center.y)*(y*y_res*shadowRes);
						bounds_x[1] = center.x+(v-center.x)/no0(Math.floor(o.y)+o.height-center.y)*(y*y_res*shadowRes);
						var p:Point = new Point(-1e9,1e9);
						var t:int;
						for each(t in bounds_l) p.x = Math.max(p.x,bounds_x[t]);
						for each(t in bounds_r) p.y = Math.min(p.y,bounds_x[t]);
						if(p.x<p.y) breaks[y+half].push(p);
					}
				}
			}
			for(y=-half;y<=half;y++)
			{
				var w:Number = rx*Math.sqrt(1-Math.pow(y/half,2));
				var l:Number = center.x-w;
				var lis:Vector.<Point> = breaks[y+half];
				lis.sort(sigmentCompare);
				lis.push(new Point(center.x+w+1,center.x+w+1));
				//if(y==30) trace(1),trace(lis);
				for(i=0;i<lis.length;i++)
				{
					if(lis[i].x>center.x+w+1) lis[i].x = center.x+w+1;
					if(l<lis[i].x) bmd.fillRect(new Rectangle(l/shadowRes,center.y/shadowRes+y*y_res,(lis[i].x-l-1)/shadowRes,y_res),color);

					l = Math.max(l,lis[i].y+1);
				}
				//bmd.fillRect(new Rectangle(center.x/shadowRes-w,center.y/shadowRes+y*y_res,w*2,y_res),0);
			}
			/*
			for(var i:Number=0.5;i<steps;i++)
			{
				var w:Number = rx*Math.cos(Math.PI/2*i/steps);
				var h:Number = ry*Math.sin(Math.PI/2*i/steps);
				bmd.fillRect(new Rectangle(center.x/shadowRes-w,center.y/shadowRes-h,2*w,2*h),0);
			}*/
		}

		function levelFinish()
		{
			curLevel += 1;
			curLight = Math.max(curLight,70);
			lightLevel = 0.5;
			loadLevel(curLevel);
		}

		function levelFailed()
		{
			curLight = Math.max(curLight,70);
			lightLevel = 0.5;
			loadLevel(curLevel);
		}

		function levelToEnd()
		{
			mainCam.ns(levelEnd);
		}

		function levelEnd()
		{
			this.x = this.y = 0;
			this.scaleX = this.scaleY = 1;
			gameEnd = 1;
			removeChild(levels);
			addChild(ending);
			addChild(mainCam.cut);
			if(bgmSC)
			{
				bgmSC.stop();
			}
			(bgmSC = (new BGM()).play()).addEventListener(Event.SOUND_COMPLETE,bgmLoop);
		}

		function loadLevel(x:int)
		{
			levelCom = 0;
			if(x==5)
			{
				if(bgmSC)
				{
					bgmSC.stop();
				}
			}
			levels.gotoAndStop(levels.totalFrames);
			levels.gotoAndStop(x);
			levels.addChild(player);
			boxes = new Vector.<HitBox>();
			oboxes = new Vector.<OpaqueBox>();
			lboxes = new Vector.<LightBox>();
			lboxes2 = new Vector.<LightBox>();
			cboxes = new Vector.<CameraBox>();
			iboxes = new Vector.<IInter>();
			pedestals = new Vector.<Pedestal>();
			for(var i:int=0;i<levels.numChildren;i++)
			{
				var o:DisplayObject = levels.getChildAt(i);
				o.visible = false;
				if(o is HitBox)
				{
					//trace(o);
					boxes.push(o);
				}
				else if(o is OpaqueBox)
				{
					oboxes.push(o);
				}
				else if(o is LightBox)
				{
					if(o.name.search("LB")!=-1)
					{
						lboxes2.push(o);
					}
					else
						lboxes.push(o);
				}
				else if(o is CameraBox)
				{
					cboxes.push(o);
				}
				else if(o is StartPoint)
				{
					player.x = o.x;
					player.y = o.y;
				}
				else if(o is EndPoint)
				{
					endBox = o as EndPoint;
				}
				else
				{
					if(o is IInter)
					{
						iboxes.push(o);
					}
					if(o is Pedestal)
					{
						(o as Object).gotoAndStop(1);
						pedestals.push(o);
					}
					if(o is Door)
					{
						(o as Object).HitBox = new HitBox();
						(o as Object).OpaqueBox = new OpaqueBox();
						(o as Object).HitBox.x = (o as Object).OpaqueBox.x = (o as Object).x;
						(o as Object).HitBox.y = (o as Object).OpaqueBox.y = (o as Object).y-0.5*(o as Object).height;
						(o as Object).HitBox.width = (o as Object).OpaqueBox.width = 0;
						(o as Object).HitBox.height = (o as Object).OpaqueBox.height = (o as Object).height;
						boxes.push((o as Object).HitBox);
						oboxes.push((o as Object).OpaqueBox);
					}
					o.visible = true;
				}
			}
			lboxes.sort(lightCompare);
			boxes.sort(platCompare);
			shadowBMD.fillRect(shadowBMD.rect,0xFF000000);
			updStaticShadow();
		}

		function no0(v:Number)
		{
			return v==0?0.001:v;
		}

		function lightSense(x:Number,y:Number)
		{
			return 1-int(shadowBMD.getPixel32(x/shadowRes,y/shadowRes)/0x1000000)/0xFF;
		}

	}
	
}
