/*
By PEZ, blog.betterthantomorrow.com, Feb 2011.
Project home is: https://github.com/PEZ/FlexGauge
Clone away! And please show me your improvements via pull requests.
There's a demo here:
  http://dl.dropbox.com/u/3259215/gauge-demo/gaugetestflash.html

Based on Gauge component by Smith & Fox: http://www.smithfox.com/?e=48
in turn, based on the DegrafaGauge: Copyright (c) 2008, Thomas W. Gonzalez

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

package com.betterthantomorrow.components {
	import flash.display.CapsStyle;
	import flash.display.LineScaleMode;
	import flash.filters.DropShadowFilter;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	
	import mx.charts.chartClasses.GraphicsUtilities;
	import mx.controls.Image;
	import mx.controls.Label;
	import mx.core.FlexGlobals;
	import mx.core.UIComponent;
	import mx.effects.Rotate;
	import mx.effects.easing.Exponential;
	import mx.formatters.Formatter;
	import mx.graphics.SolidColorStroke;
	import mx.styles.CSSStyleDeclaration;	
	
	//Face Color
	[Style(name = "faceColor", type = "Number", format = "Color", inherit = "yes")]
	
	[Style(name = "faceShadowColor", type = "Number", format = "Color", inherit = "yes")]
	
	[Style(name = "bezelColor", type = "Number", format = "Color", inherit = "yes")]
	
	[Style(name = "centerColor", type = "Number", format = "Color", inherit = "yes")]
	
	[Style(name = "pointerColor", type = "Number", format = "Color", inherit = "yes")]
	
	[Style(name = "ticksColor", type = "Number", format = "Color", inherit = "yes")]
	
	[Style(name = "alertAlphas", type = "Array", format = "Color", inherit = "yes")]
	
	[Style(name = "alertColors", type = "Array", format = "Color", inherit = "yes")]
	
	[Style(name = "alertRatios", type = "Array", format = "Color", inherit = "yes")]
	
	[Style(name = "fontColor", type = "Number", format = "Color", inherit = "yes")]
	
	public class Gauge extends UIComponent {
		public function Gauge():void {
			super();
		}
		
		private var _pointerRotator:Rotate = new Rotate();
		
		//CHILDREN - You can use your own swf with the same symbol names to resking this gauge.
		[@Embed(source = 'gauge/skins/GaugeSkins_Skin1.swf', symbol = 'face')][Bindable]
		private var _faceSymbol:Class;
		private var _face:Image;
		private var _faceColorChanged:Boolean = true;
		
		[@Embed(source = 'gauge/skins/GaugeSkins_Skin1.swf', symbol = 'faceShadow')][Bindable]
		private var _faceShadowSymbol:Class;
		private var _faceShadow:Image;
		private var _faceShadowColorChanged:Boolean = true;
		
		private var _alerts:UIComponent;
		private var _ticks:UIComponent;
		
		[@Embed(source = 'gauge/skins/GaugeSkins_Skin1.swf', symbol = 'pointer')][Bindable]
		private var _pointerSymbol:Class;
		private var _pointer:Image;
		private var _pointerColorChanged:Boolean = true;
		
		[@Embed(source = 'gauge/skins/GaugeSkins_Skin1.swf', symbol = 'bezel')][Bindable]
		private var _bezelSymbol:Class;
		private var _bezel:Image;
		private var _bezelColorChanged:Boolean = false;
		
		[@Embed(source = 'gauge/skins/GaugeSkins_Skin1.swf', symbol = 'nub')][Bindable]
		private var _centerSymbol:Class;
		private var _center:Image;
		private var _centerColorChanged:Boolean = true;

		[@Embed(source = 'gauge/skins/GaugeSkins_Skin1.swf', symbol = 'reflection')][Bindable]
		private var _reflectionSymbol:Class;
		private var _reflection:Image;
		
		private var _valueLabel:Label = new Label();
		private var _minLabel:Label;
		private var _maxLabel:Label;
		private var _lastPointerRotation:Number = 0;
		
		[Bindable] private var _maxValue:Number = 10;
		[Bindable] private var _minValue:Number = 1;
		[Bindable] private var _value:Number = 8.5;
		[Bindable] private var _smallTicks:int = 45;
		[Bindable] private var _bigTicks:int = 9;
		
		private var _dropShadowFilter:DropShadowFilter;
		private var _diameter:Number;
		
		private static const POINTER_WIDTH:Number = 0.07;
		private static const POINTER_HEIGHT:Number = 1.25;
		private static const POINTER_ORIGIN_SCALE:Number = 0.68;
		private static const NUB_DIAMETER:Number = 0.1;
		private static const REFLECTION_WIDTH:Number = 1.0;
		private static const REFLECTION_HEIGHT:Number = 0.6;
		private static const REFLECTION_OFFSET:Number = 0.05;
		private static const TICK_THICKNESS:Number = 0.006;
		private static const TICK_LENGTH_SMALL:Number = 0.23;
		private static const TICK_LENGTH_BIG:Number = 0.28;
		private static const SCALE_DIAMETER:Number = 1/1.12;
		private static const VALUE_LABEL_SIZE:Number = 0.11;
		private static const VALUE_LABEL_Y_OFFSET:Number = 0.1;
		private static const MINMAX_LABEL_SIZE:Number = 0.07;
		
		[Bindable][Inspectable]
		public var valueFormatter:Formatter = null;
		
		/**
		 * Setters and Getters
		 */
		
		private var _showValue:Boolean = true;
		private var _showMinMax:Boolean = true;
		private var _glareAlpha:Number = 0.6;
		
		public function set glareAlpha(param:Number):void {
			_glareAlpha = param;
			invalidateDisplayList();
		}
		
		public function set showMinMax(param:Boolean):void {
			_showMinMax = param;
			invalidateDisplayList();
		}
		
		public function set showValue(param:Boolean):void {
			_showValue = param;
			invalidateDisplayList();
		}
		
		public function get showValue():Boolean { return _showValue; }
		
		public function set minValue(param:Number):void {
			if (_maxValue >= 0) {
				if (param<_maxValue) {
					_minValue = param;
				}
			}
			else {
				if (param>_maxValue) {
					_minValue = param;	
				}
			}
			setPointer();
		}
		
		public function set maxValue(param:Number):void {
			if (_maxValue >= 0) {
				if (param>_minValue) {
					_maxValue = param;
				}
			}
			else {
				if (param<_minValue) {
					_maxValue = param;
				}
			}
			setPointer();
		}
		
		public function set smallTicks(param:int):void {
			_smallTicks = param > 0 ? param : _smallTicks;
			invalidateDisplayList();
		}
		
		public function set bigTicks(param:int):void {
			_bigTicks = param > 0 ? param : _bigTicks;
			invalidateDisplayList();
		}
		
		[Bindable][Inspectable]
		public function get maxValue():Number { return _maxValue; }
		
		[Bindable][Inspectable]
		public function get minValue():Number { return _minValue; }		
		
		[Bindable][Inspectable]
		public function get smallTicks():int { return _smallTicks; }		
		
		[Bindable][Inspectable]
		public function get bigTicks():int { return _bigTicks; }		
		
		[Bindable][Inspectable]
		public function get value():Number { return _value; }
		
		
		public function set value(param:Number):void {
			_value = param;
			setValueLabel();
			setPointer();
		}
		
		private function setPointer():void {
			if (_pointer != null) {
				rotatePointer();
			}
		}
		
		override public function set height(value:Number):void {
			diameter = value;
		}
		
		override public function set width(value:Number):void {
			diameter = value;
		}
		
		public function set diameter(value:Number):void {
			super.width = value;
			super.height = value;
		}
		
		[Bindable]
		public function get diameter():Number {
			return width;
		}
		
		private static var classConstructed:Boolean = classConstruct();
		private static function classConstruct():Boolean {
			if (!FlexGlobals.topLevelApplication.styleManager.getStyleDeclaration("com.betterthantomorrow.components.Gauge")) {
				var myStyles:CSSStyleDeclaration = new CSSStyleDeclaration();
				myStyles.defaultFactory = function():void {
					this.faceColor = 0x1C1C1C;
					this.faceShadowColor = 0x000000;
					this.bezelColor = 0x999999;
					this.centerColor = 0x777777;
					this.pointerColor = 0xEE3344;
					this.ticksColor = 0xECECEC;
					this.alertRatios = [3, 6];
					this.alertColors = [0xFF0000, 0xFFFF00, 0x00BB11];
					this.alertAlphas = [.8, .8, .98];
					this.fontColor = 0xFFFFFF;
					this.fontSize = 18;
				}
				FlexGlobals.topLevelApplication.styleManager.setStyleDeclaration("com.betterthantomorrow.components.Gauge", myStyles, true);
			}
			return true;
		}
		
		override public function styleChanged(styleProp:String):void {
			super.styleChanged(styleProp);
			
			if (styleProp == "faceColor") {
				_faceColorChanged=true; 
			}
			else if (styleProp == "faceShadowColor") {
				_faceShadowColorChanged = true; 
			}
			else if (styleProp == "bezelColor") {
				_bezelColorChanged = true; 
			}
			else if (styleProp == "centerColor") {
				_centerColorChanged = true; 
			}
			else if (styleProp == "pointerColor") {
				_pointerColorChanged = true; 
			}
			else if (styleProp == "ticksColor") {
			}

			invalidateDisplayList();
		}
		
		override protected function createChildren():void {
			super.createChildren();
			_dropShadowFilter = new DropShadowFilter(2, 45, 0, .3, 2, 2, 1, 1);

			_alerts = new UIComponent();
			_ticks = new UIComponent();

			_face = new Image();
			_face.source = _faceSymbol;

			_faceShadow = new Image();
			_faceShadow.source = _faceShadowSymbol;

			_pointer = new Image();
			_pointer.source = _pointerSymbol;
			_pointer.filters = [_dropShadowFilter];

			_bezel = new Image();
			_bezel.source = _bezelSymbol;

			_center = new Image();
			_center.source = _centerSymbol;
			_center.filters = [_dropShadowFilter];

			_reflection = new Image();
			_reflection.source = _reflectionSymbol;

			_minLabel = new Label();
			_minLabel.setStyle("textAlign", "left");

			_maxLabel = new Label();
			_maxLabel.setStyle("textAlign", "right");

			_valueLabel.setStyle("textAlign", "center");
			
			_pointerRotator.easingFunction = Exponential.easeOut;
			_pointerRotator.duration = 500;
			_pointerRotator.target = _pointer;

			addChild(_face);
			addChild(_faceShadow);
			addChild(_alerts);
			addChild(_ticks);
			addChild(_pointer);
			addChild(_bezel);
			addChild(_center);
			addChild(_reflection);
			addChild(_valueLabel);
			addChild(_minLabel);
			addChild(_maxLabel);
		}
				
		override protected function measure():void {
			super.measure();
			if (_diameter != width) {
				_diameter = width;
				
				_face.width = _diameter;
				_face.height = _face.width;
				_face.x = (_diameter - _face.width)/2;
				_face.y = _face.x;
				
				_faceShadow.width = _face.width;
				_faceShadow.height = _face.height;
				_faceShadow.y = _face.y;
				_faceShadow.x = _face.x;
				
				_ticks.height = _diameter;
				_ticks.width = _ticks.height;
				_ticks.x = (_diameter - _ticks.width)/2;
				_ticks.y = _ticks.x;
				
				_pointer.height = _diameter / 2 * POINTER_HEIGHT;
				_pointer.width = _diameter * POINTER_WIDTH;
				var pointerCenter:Point = new Point(_pointer.width / 2, _pointer.height * POINTER_ORIGIN_SCALE);
				_lastPointerRotation = _pointer.rotation;
				_pointer.rotation = 0;
				_pointer.x = _diameter / 2 - pointerCenter.x;
				_pointer.y = _diameter / 2 - pointerCenter.y;
				_pointerRotator.originX = pointerCenter.x;
				_pointerRotator.originY = pointerCenter.y;
				
				setPointer();
								
				_bezel.width = _diameter;
				_bezel.height = _bezel.width;
				_bezel.x = (_diameter - _bezel.width) / 2;
				_bezel.y = _bezel.x;
				
				_center.width = _diameter * NUB_DIAMETER;
				_center.height = _center.width;
				_center.x = (_diameter - _center.width) / 2;
				_center.y = _center.x;
				
				_reflection.width = _diameter * REFLECTION_WIDTH;
				_reflection.height = _diameter * REFLECTION_HEIGHT;
				_reflection.x = _reflection.y = _diameter * REFLECTION_OFFSET;
				
				_dropShadowFilter.distance = 10;
				_dropShadowFilter.blurX = 10;
				_dropShadowFilter.blurY = 10;
				
				_center.filters = [_dropShadowFilter];
				_pointer.filters = [_dropShadowFilter];
				
				_valueLabel.width = _diameter;
				var fontSize:Number = Math.max(_diameter * VALUE_LABEL_SIZE, 10);
				_valueLabel.setStyle("fontSize", fontSize);
				_valueLabel.height = fontSize * 2;
				_valueLabel.y = _diameter - _diameter * VALUE_LABEL_Y_OFFSET - fontSize;
				
				var radius:Number = _ticks.width / 2;
				_minLabel.width = _maxLabel.width = _diameter;
				_minLabel.height = _maxLabel.height = _diameter * 0.1;
				_minLabel.setStyle("fontSize", _diameter * MINMAX_LABEL_SIZE);
				_maxLabel.setStyle("fontSize", _diameter * MINMAX_LABEL_SIZE);
				_minLabel.x = radius + radius * Math.sin(radiansForValue(minValue)) * (SCALE_DIAMETER - TICK_LENGTH_SMALL / 2);
				_minLabel.y = radius + radius * Math.cos(radiansForValue(minValue)) * (SCALE_DIAMETER - TICK_LENGTH_SMALL / 2);				
				_maxLabel.x = radius + radius * Math.sin(radiansForValue(maxValue)) * (SCALE_DIAMETER - TICK_LENGTH_SMALL / 2) - _maxLabel.width;
				_maxLabel.y = radius + radius * Math.cos(radiansForValue(maxValue)) * (SCALE_DIAMETER - TICK_LENGTH_SMALL / 2);
			}
		}
		
		private function setValueLabel():void {
			if (valueFormatter) {
				_valueLabel.text = valueFormatter.format(value);
			}
			else {
				_valueLabel.text = value.toString();
			}
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			_minLabel.text = minValue.toString();
			_maxLabel.text = maxValue.toString();
			
			var fontColor:Number = getStyle("fontColor");
			_valueLabel.setStyle("color", fontColor);
			_valueLabel.setStyle("fontFamily", getStyle("fontFamily"));
			_valueLabel.setStyle("fontStyle", getStyle("fontStyle")); 
			_valueLabel.setStyle("fontWeight", getStyle("fontWeight"));
			_valueLabel.setStyle("fontSharpness", getStyle("fontSharpness"));
			_valueLabel.setStyle("fontAntiAliasType", getStyle("fontAntiAliasType"));
			_valueLabel.visible = _showValue;
			
			_reflection.alpha = _glareAlpha;
			
			_minLabel.setStyle("color", fontColor);
			_maxLabel.setStyle("color", fontColor);
			_minLabel.visible = _maxLabel.visible = _showMinMax;
			
			measure();
			drawTicks();
			drawAlerts();
			setValueLabel();
			
			if (_faceColorChanged) {
				transformColor(_face, getStyle("faceColor"));
				_faceColorChanged = false;
			}
			if (_faceShadowColorChanged) {
				transformColor(_faceShadow, getStyle("faceShadowColor"));
				_faceShadowColorChanged = false;
			}
			if (_bezelColorChanged) {
				transformColor(_bezel, getStyle("bezelColor"));
				_bezelColorChanged = false;
			}
			if (_centerColorChanged) {
				transformColor(_center, getStyle("centerColor"));
				_centerColorChanged = false;
			}
			if (_pointerColorChanged) {
				transformColor(_pointer, getStyle("pointerColor"), 0.7);
				_pointerColorChanged = false;
			}
		}
		
		private function calculatePointerAngle():Number {
			return degreesForValue(_value);
		}
		
		private function degreesForValue(v:Number):Number {
			var delta:Number;
			var ratio:Number;
			if (_maxValue >= 0) {
				delta = _maxValue - _minValue;
			}
			else {
				delta = _minValue - _maxValue;
			}
			ratio = (v - _minValue) / delta;
			if (v > _maxValue) {
				ratio = 1;
			}
			if (v < _minValue) {
				ratio = 0;
			}
			return (240 * ratio) - 120;			
		}
		
		private function radiansForValue(v:Number):Number {
			return -Math.PI - degreesForValue(v) * Math.PI / 180;
		}
		
		private function transformColor(obj:Object, color:Number, alpha:Number = 1):void {
			if (obj != null) {
				var c:ColorTransform = new ColorTransform();
				c.color = color; 
				var ct:ColorTransform;
				ct = new ColorTransform(1, 1, 1, alpha, c.redOffset-127, c.greenOffset-127, c.blueOffset-127, 0);
				obj.transform.colorTransform = ct;
			}
		}
		
		private function drawTicks():void {  				
			_ticks.graphics.clear();
			if (_diameter > 50) {
				var radius:Number = (_ticks.width)/2;
				var tickColor:Number = getStyle("ticksColor"); 
				_ticks.graphics.lineStyle(_diameter * TICK_THICKNESS, tickColor, 1, false, LineScaleMode.NONE, CapsStyle.NONE);
				
				for(var i:int = 0; i <= _smallTicks; i++) {
					var value:Number = _minValue + i * (_maxValue - _minValue) / _smallTicks;
					var angle:Number = radiansForValue(value);
					var tick_x:Number = radius * Math.sin(angle);
					var tick_y:Number = radius * Math.cos(angle)
					_ticks.graphics.moveTo(radius + tick_x * SCALE_DIAMETER,
						radius + tick_y * SCALE_DIAMETER)
					if (i % (_smallTicks / _bigTicks) == 0) {
						_ticks.graphics.lineTo(radius + tick_x * (SCALE_DIAMETER - TICK_LENGTH_BIG),
							radius + tick_y * (SCALE_DIAMETER - TICK_LENGTH_BIG))
					}
					else {
						_ticks.graphics.lineTo(radius + tick_x * (SCALE_DIAMETER - TICK_LENGTH_SMALL),
							radius + tick_y * (SCALE_DIAMETER - TICK_LENGTH_SMALL))
					}
				}
			}
		}
		
		private function rotatePointer():void  {
			var angle:Number = calculatePointerAngle();			
			if (_pointerRotator.isPlaying) {
				_pointerRotator.stop();
			}
			_pointerRotator.angleFrom = _lastPointerRotation;
			_lastPointerRotation = angle;
			_pointerRotator.angleTo = angle;
			_pointerRotator.play();
		}
		
		private function drawAlertArc(startAngle:Number, endAngle:Number, color:Number, alpha:Number):void {
			var origin:Point = new Point(_diameter / 2, _diameter / 2);
			var radius:Number = (_diameter * (SCALE_DIAMETER - TICK_LENGTH_SMALL / 1.95)) / 2;
			var stroke:SolidColorStroke = new SolidColorStroke(color, _diameter * (TICK_LENGTH_SMALL / 1.95), alpha,
				false, LineScaleMode.NONE, CapsStyle.NONE);
			GraphicsUtilities.setLineStyle(_alerts.graphics, stroke);
			GraphicsUtilities.drawArc(_alerts.graphics, origin.x, origin.y, startAngle - Math.PI / 2, endAngle - startAngle, radius);
		}
		
		private function drawAlerts():void {
			var levels:Array = getStyle("alertRatios").concat();
			levels.unshift(_minValue);
			levels.push(_maxValue);
			var colors:Array = getStyle("alertColors");
			var alphas:Array = getStyle("alertAlphas");
			
			if (!(null in [levels, colors, alphas])) {;
				var delta:Number;
				var ratio:Number;
				
				if (_maxValue >= 0) {
					delta = _maxValue - _minValue;
				}
				else {
					delta = _minValue - _maxValue;
				}
				ratio = _value/_maxValue;
				
				_alerts.graphics.clear();
				for (var i:int = 0; i < levels.length -1; i++) {
					drawAlertArc(radiansForValue(levels[i]), radiansForValue(levels[i+1]), colors[i], alphas[i]);
				}
			}
		}
	}
}