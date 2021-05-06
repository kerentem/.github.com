package  {

	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
		
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;

	import flash.display.Bitmap;
	import flash.display.BitmapData;

	import flash.display.Shape;
	import flash.display.BlendMode;

	import flash.ui.Mouse;

	import flash.events.Event;
	import flash.events.MouseEvent;

	import flash.net.*;
	import flash.net.URLRequest;
	import flash.system.Security;

	import flash.external.ExternalInterface;
	
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	


	public class scratchcard extends MovieClip {
		private var parametersArray:String;
		private var card;
		private var ratio:Number;
		private var ratioF:Number;

		private var ratioCW:Number;
		private var ratioCH:Number;
		private var ratioSW:Number;
		private var ratioSH:Number;
		private var coinMarginL:Number = 0;
		private var coinMarginT:Number = 0;

		private var isMouseDown:Boolean = false;

		private var background:Loader = new Loader();
		private var foreground:Loader = new Loader();
		private var loadState:Number = 0;
		private var initObject;
		private var coinImage:Loader = new Loader();
		private var thickness:Number = 36;
		private var percentLimit:Number = 90;
		private var mousePointer:String;

		private var countFunction:String;
		private var callbackFunction:String;

		private var backgroundImage:Sprite = new Sprite();
		private var canvas:Sprite = new Sprite();
		private var fillColor:Number = 0x000000;

		//
		private var foregroundMaskData:BitmapData;
		private var foregroundMask:Bitmap;
		private var eraser:Sprite;
		private var maskData:BitmapData;
		private var maskBitmap:Bitmap;
		//
		private var percentBitmapData:BitmapData;
		private var percentBitmap:Bitmap;
		//
		private var jump:Number = 9; // odd number
		private var hasEnded:Boolean = false;


		public function scratchcard():void {
			addEventListener(Event.ADDED_TO_STAGE, preInit);
		}

		private function preInit(e:Event) {
			init();
		}

		private function init():void {
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.addEventListener(Event.RESIZE, resize);

			Security.allowDomain('*');

			if(stage.loaderInfo.parameters.backgroundImage != null) {
				var backgroundPath = stage.loaderInfo.parameters.backgroundImage;
				background.contentLoaderInfo.addEventListener(Event.COMPLETE, backgroundLoaded);
				background.load(new URLRequest(backgroundPath));
			}

			if(stage.loaderInfo.parameters.foregroundImage != null) {
				var foregroundPath = stage.loaderInfo.parameters.foregroundImage;
				foreground.contentLoaderInfo.addEventListener(Event.COMPLETE, foregroundLoaded);
				foreground.load(new URLRequest(foregroundPath));
			}

			if(stage.loaderInfo.parameters.init != null) {
				initObject = stage.loaderInfo.parameters.init;
			}

			if(stage.loaderInfo.parameters.coin != null) {
				// use image as cursor
				var coinPath = stage.loaderInfo.parameters.coin;
				coinImage.contentLoaderInfo.addEventListener(Event.COMPLETE, coinLoaded);
				coinImage.load(new URLRequest(coinPath));
				Mouse.hide();
			} else if(stage.loaderInfo.parameters.cursor != null) {
				// use specified cursor
				if(stage.loaderInfo.parameters.cursor == 'grab') {
					Mouse.cursor = 'hand';
				} else if(stage.loaderInfo.parameters.cursor == 'pointer') {
					Mouse.cursor = 'button';
				} else if(stage.loaderInfo.parameters.cursor == 'text') {
					Mouse.cursor = 'ibeam';
				}
			}

			if(stage.loaderInfo.parameters.thickness != null) {
				thickness = (stage.loaderInfo.parameters.thickness)*2;
			}

			if(stage.loaderInfo.parameters.percent != null) {
				percentLimit = (stage.loaderInfo.parameters.percent);
			}
			
			if(stage.loaderInfo.parameters.counter != null) {
				countFunction = (stage.loaderInfo.parameters.counter);
			}

			if(stage.loaderInfo.parameters.callback != null) {
				callbackFunction = (stage.loaderInfo.parameters.callback);
			}

			ExternalInterface.addCallback("lock", lock);
			ExternalInterface.addCallback("restart", restart);
			ExternalInterface.addCallback("clean", clean);
		}

		private function backgroundLoaded(e:Event):void {
			ratio = background.width / background.height;
			loadState++;
			setScene(e);
		}
		private function foregroundLoaded(e:Event):void {
			percentBitmapData = Bitmap(LoaderInfo(e.target).content).bitmapData;
			ratioF = foreground.width / foreground.height;
			loadState++;
			setScene(e);
		}
		
		private function setScene(e:Event) {
			if(loadState >= 2) {
				backgroundImage.addChild(background);
				addChild(backgroundImage);
				addChild(foreground);

				setCanvas();
				addChild(foregroundMask);

				foreground.cacheAsBitmap = true;
				foreground.mask = foregroundMask;


				coinImage.visible = false;
				coinImage.mouseEnabled = false;
				coinImage.mouseChildren = false;
				addChild(coinImage);

				ratioSW = stage.stageWidth;
				ratioSH = stage.stageHeight;
				resize(e);
			}
		}

		private function coinLoaded(e:Event):void {
			ratioCW = coinImage.width;
			ratioCH = coinImage.height;
		}

		private function setCanvas():void {
			eraser = new Sprite();
			eraser.graphics.lineStyle(thickness,0xff0000);
			eraser.graphics.moveTo(stage.mouseX,stage.mouseY);
			
			foregroundMaskData = new BitmapData(foreground.width, foreground.height, true, 0xFFFFFFFF);
			foregroundMask = new Bitmap(foregroundMaskData);
			
			maskData = new BitmapData(foreground.width, foreground.height, true, 0x00000000);
			maskBitmap = new Bitmap(maskData);

			foregroundMask.cacheAsBitmap = true;

			stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			stage.addEventListener(MouseEvent.MOUSE_UP, mouseUp);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, paint);

			stage.addEventListener(MouseEvent.MOUSE_OVER, mouseHover);
			stage.addEventListener(MouseEvent.MOUSE_OUT, mouseOut);
		}

		private function mouseDown(event:MouseEvent):void {
			isMouseDown = true;
			paint(event);
		}

		private function mouseUp(event:MouseEvent):void {
			isMouseDown = false;
		}

		private function paint(event:MouseEvent):void {
			coinImage.x = ((event.localX * coinMarginL) - (coinImage.width/2)) + backgroundImage.x;
			coinImage.y = ((event.localY * coinMarginT) - (coinImage.height/2)) + backgroundImage.y;
			
			if(isMouseDown) {
				eraser.graphics.moveTo(event.localX, event.localY);
				eraser.graphics.lineTo(event.localX+1, event.localY+1);
				maskData.fillRect(maskData.rect, 0x00000000);
				maskData.draw(eraser , new Matrix(), null, BlendMode.NORMAL);
				foregroundMaskData.fillRect(foregroundMaskData.rect, 0xFFFFFFFF);
				foregroundMaskData.draw(maskBitmap, new Matrix(), null, BlendMode.ERASE);

				covered();
				event.updateAfterEvent();
			}
		}

		private function mouseHover(event:MouseEvent):void {
			coinImage.visible = true;
		}
		private function mouseOut(event:MouseEvent):void {
			coinImage.visible = false;
		}

		private function covered():void {
			percentBitmap = new Bitmap(percentBitmapData);
			percentBitmap.width = foreground.width;
			percentBitmap.height = foreground.height;
			var m = 0;
			var n = 0;
			var x = 0;
			var y = 0;
			var u = 0; // uncovered pixel
			var t = 0; // transparent pixel
			for(var i = 0, j = foreground.width, k = foreground.height, l = ((foreground.width*foreground.height) - jump); i < l; i+=jump) {
				x = (i%j);
				y = ((i-(i%j))/j)*jump;
				m = (foregroundMaskData.getPixel32(x, y));
				n = (percentBitmapData.getPixel32(x, y));
				if(m == 0 && n != 0) {
					u++;
				}
				if(n != 0){
					t++;
				}
			}
			var count = Math.round((u/t)*10000)/100;
			percent(count);
			if(count >= percentLimit || percentLimit >= 100) {
				ended(true);
			}
		}

		private function percent(n):void {
			if(countFunction != null) {
				ExternalInterface.call('scratchJsFlashCallback', countFunction, initObject, n);	
			}
		}
		private function ended(t):void {
			stage.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
			stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUp);
			stage.removeEventListener(MouseEvent.MOUSE_MOVE, paint);
			stage.removeEventListener(MouseEvent.MOUSE_OVER, mouseHover);
			stage.removeEventListener(MouseEvent.MOUSE_OUT, mouseOut);
			coinImage.visible = false;
			Mouse.show();

			// clean the mask
			foregroundMaskData.fillRect(new Rectangle(0,0,foreground.width,foreground.height),0x00FFFFFF);

			if(callbackFunction != null && !hasEnded && t) {
				hasEnded = true;
				ExternalInterface.call('scratchJsFlashCallback', callbackFunction, initObject);	
			}
		}

		private function lock(l:Boolean):void {
			if(l) {
				stage.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
				stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUp);
				stage.removeEventListener(MouseEvent.MOUSE_MOVE, paint);
				stage.removeEventListener(MouseEvent.MOUSE_OVER, mouseHover);
				stage.removeEventListener(MouseEvent.MOUSE_OUT, mouseOut);
				coinImage.visible = false;
				Mouse.show();
			} else {
				stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
				stage.addEventListener(MouseEvent.MOUSE_UP, mouseUp);
				stage.addEventListener(MouseEvent.MOUSE_MOVE, paint);
				stage.addEventListener(MouseEvent.MOUSE_OVER, mouseHover);
				stage.addEventListener(MouseEvent.MOUSE_OUT, mouseOut);
				coinImage.visible = true;
				Mouse.hide();
			}
		}

		private function restart():void {
			hasEnded = false;
			init();
		}

		private function clean():void {
			ended(false);
		}


		private function resize(e:Event):void {

			if(!(stage.stageHeight * ratio > stage.stageWidth)) {
				backgroundImage.width = stage.stageHeight * ratio;
				backgroundImage.height = stage.stageHeight;
				background.width = stage.stageHeight * ratio;
				background.height = stage.stageHeight;
			} else {
				backgroundImage.width = stage.stageWidth;
				backgroundImage.height = stage.stageWidth / ratio;
				background.width = stage.stageWidth;
				background.height = stage.stageWidth / ratio;
			}
			backgroundImage.x = (stage.stageWidth / 2) - (backgroundImage.width / 2);
			backgroundImage.y = (stage.stageHeight / 2) - (backgroundImage.height / 2);

			if(!(stage.stageHeight * ratioF > stage.stageWidth)) {
				foreground.width = stage.stageHeight * ratioF;
				foreground.height = stage.stageHeight;
				foregroundMask.width = stage.stageHeight * ratioF;
				foregroundMask.height = stage.stageHeight;
			} else {
				foreground.width = stage.stageWidth;
				foreground.height = stage.stageWidth / ratioF;
				foregroundMask.width = stage.stageWidth;
				foregroundMask.height = stage.stageWidth / ratioF;
			}
			foreground.x = (stage.stageWidth / 2) - (foreground.width / 2);
			foreground.y = (stage.stageHeight / 2) - (foreground.height / 2);
			foregroundMask.x = (stage.stageWidth / 2) - (foregroundMask.width / 2);
			foregroundMask.y = (stage.stageHeight / 2) - (foregroundMask.height / 2);


			coinImage.width = ratioCW * (background.width / ratioSW);
			coinImage.height = ratioCH * (background.height / ratioSH);
			coinMarginL = (background.width / ratioSW);
			coinMarginT = (background.height / ratioSH);
		}
	}

}