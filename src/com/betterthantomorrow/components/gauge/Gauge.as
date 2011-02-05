/*
By PEZ, blog.betterthantomorrow.com, Feb 2011. 
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

package com.betterthantomorrow.components.gauge {
	import flash.display.CapsStyle;
	import flash.display.LineScaleMode;
	import flash.events.Event;
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
	[Style(name="faceColor",type="Number",format="Color",inherit="yes")]
	
	[Style(name="faceShadowColor",type="Number",format="Color",inherit="yes")]
	
	[Style(name="bezelColor",type="Number",format="Color",inherit="yes")]
	
	[Style(name="centerColor",type="Number",format="Color",inherit="yes")]
	
	[Style(name="pointerColor",type="Number",format="Color",inherit="yes")]
	
	[Style(name="ticksColor",type="Number",format="Color",inherit="yes")]
	
	[Style(name="alertAlphas",type="Array",format="Color",inherit="yes")]
	
	[Style(name="alertColors",type="Array",format="Color",inherit="yes")]
	
	[Style(name="alertRatios",type="Array",format="Color",inherit="yes")]
	
	[Style(name="fontColor",type="Number",format="Color",inherit="yes")]
	
	public class Gauge extends UIComponent {
		public function Gauge():void {
			super();
			//this.setStyle("borderColor",null);
			//this.clipContent=false; 
			
		}
		
		private var r:Rotate = new Rotate();
		
		//CHILDREN - You can use your own swf with the same symbol names to resking this gauge.
		[@Embed(source='skins/GaugeSkins_Skin1.swf', symbol='face')][Bindable]
		private var _faceSymbol:Class;
		private var _face:Image;
		private var _faceColorChanged:Boolean=true;
		
		[@Embed(source='skins/GaugeSkins_Skin1.swf', symbol='faceShadow')][Bindable]
		private var _faceShadowSymbol:Class;
		private var _faceShadow:Image;
		private var _faceShadowColorChanged:Boolean=true;
		
		private var _alerts:UIComponent;
		private var _ticks:UIComponent;
		
		[@Embed(source='skins/GaugeSkins_Skin1.swf', symbol='pointer')][Bindable]
		private var _pointerSymbol:Class;
		private var _pointer:Image;
		private var _pointerColorChanged:Boolean=true;
		
		[@Embed(source='skins/GaugeSkins_Skin1.swf', symbol='bezel')][Bindable]
		private var _bezelSymbol:Class;
		private var _bezel:Image;
		private var _bezelColorChanged:Boolean=false;
		
		[@Embed(source='skins/GaugeSkins_Skin1.swf', symbol='nub')][Bindable]
		private var _centerSymbol:Class;
		private var _center:Image;
		private var _centerColorChanged:Boolean=true;
		
		[@Embed(source='skins/GaugeSkins_Skin1.swf', symbol='reflection')][Bindable]
		private var _reflectionSymbol:Class;
		private var _reflection:Image;
		
		private var _valueLabel:Label;
		private var _minLabel:Label;
		private var _maxLabel:Label;
		
		//Privates
		[Bindable] private var _maxValue:Number=10;
		[Bindable] private var _minValue:Number=1;
		[Bindable] private var _value:Number=5;
		[Bindable] private var _smallTicks:int=45;
		[Bindable] private var _bigTicks:int=9;
		
		private var _dropShadowFilter:DropShadowFilter;
		private var _diameter:Number;
		
		//If you swap out the asset .swf you will need to update these constants as appropriate so the gauge can measure correctly.
		public static const POINTER_WIDTH:Number=0.07;
		public static const POINTER_HEIGHT:Number=1.25;
		public static const POINTER_ORIGIN_SCALE:Number=0.68;
		public static const NUB_DIAMETER:Number=0.1;
		public static const REFLECTION_WIDTH:Number=1.0;
		public static const REFLECTION_HEIGHT:Number=0.6;
		public static const REFLECTION_OFFSET:Number=0.05;
		public static const TICK_THICKNESS:Number=0.005;
		public static const TICK_LENGTH:Number=0.17;
		public static const SCALE_DIAMETER:Number=1/1.1;
		
		
		[Bindable][Inspectable]
		public var valueFormatter:Formatter=null;
		
		[Bindable][Inspectable]
		public var positiveMaxValue:Boolean=true;
		
		/**
		 * Setters and Getters
		 */
		
		private var _showValue:Boolean=true;
		private var _showMinMax:Boolean=true;
		private var _glareAlpha:Number=0.6;
		
		public function set glareAlpha(param:Number):void {
			_glareAlpha=param;
			this.invalidateDisplayList();
		}
		
		public function set showMinMax(param:Boolean):void {
			_showMinMax=param;
			this.invalidateDisplayList();
		}
		
		public function set showValue(param:Boolean):void {
			_showValue=param;
			this.invalidateDisplayList();
		}
		
		public function get showValue():Boolean { return _showValue; }
		
		public function set minValue(param:Number):void {
			if(positiveMaxValue) {
				if (param<_maxValue) {
					_minValue=param;
				}
				else if (param>_maxValue) {
					_minValue=param;	
				}
			}
			setPointer();
		}
		
		public function set maxValue(param:Number):void {
			if(positiveMaxValue)
				if (param>_minValue) {
					_maxValue=param;
				}
				else if (param<_minValue) {
					_maxValue=param;
				}
			setPointer();
		}
		
		public function set smallTicks(param:int):void {
			_smallTicks = param > 0 ? param : _smallTicks;
			this.invalidateDisplayList();
		}
		
		public function set bigTicks(param:int):void {
			_bigTicks = param > 0 ? param : _bigTicks;
			this.invalidateDisplayList();
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
		public function get value():Number { return this._value; }
		
		
		public function set value(param:Number):void
		{
			this._value=param;
			setValueLabel();
			setPointer();
		}
		
		private function setPointer():void 
		{
			if (this._pointer != null) {
				rotatePointer();
			}
			this.dispatchEvent(new Event("change"));
		}
		
		override public function set height(value:Number):void {
			diameter=value;
		}
		
		override public function set width(value:Number):void {
			diameter=value;
		}
		
		public function set diameter(value:Number):void {
			super.width=value;
			super.height=value;
			if (_bezel != null)
				trace(_bezel.width, value);
		}
		
		[Bindable]
		public function get diameter():Number {
			return this.width;
		}
		
		private static var classConstructed:Boolean = classConstruct();
		private static function classConstruct():Boolean {
			if (!FlexGlobals.topLevelApplication.styleManager.getStyleDeclaration("com.betterthantomorrow.components.gauge.Gauge"))
			{
				var myStyles:CSSStyleDeclaration = new CSSStyleDeclaration();
				myStyles.defaultFactory = function():void
				{
					this.faceColor = 0x1C1C1C;
					this.faceShadowColor = 0x000000;
					this.bezelColor = 0x999999;
					this.centerColor = 0x777777;
					this.pointerColor = 0xEE3344;
					this.ticksColor = 0xECECEC;
					this.alertRatios = [3,6];
					this.alertColors = [0xFF0000,0xFFFF00,0x00FF00];
					this.alertAlphas = [.8,.7,.8];
					this.fontColor = 0xFFFFFF;
					this.fontSize = 18;
				}
				FlexGlobals.topLevelApplication.styleManager.setStyleDeclaration("com.betterthantomorrow.components.gauge.Gauge", myStyles, true);
				
			}
			return true;
		}
		
		// Override styleChanged() to detect changes in your new style.
		override public function styleChanged(styleProp:String):void {
			
			super.styleChanged(styleProp);
			
			// Check to see if style changed. 
			if (styleProp=="faceColor") 
			{
				_faceColorChanged=true; 
				return;
			}
			else if (styleProp=="faceShadowColor"){
				_faceShadowColorChanged=true; 
				return;
			}
			else if (styleProp=="bezelColor"){
				_bezelColorChanged=true; 
				return;
			}
			else if (styleProp=="centerColor"){
				_centerColorChanged=true; 
				return;
			}
			else if (styleProp=="pointerColor"){
				_pointerColorChanged=true; 
				return;
			}
			else if (styleProp=="ticksColor"){
				return;
			}
			
			invalidateDisplayList();
		}
		
		
		override protected function createChildren():void {
			super.createChildren();
			
			_dropShadowFilter = new DropShadowFilter(2,45,0,.3,2,2,1,1);
			
			_face = new Image();
			_face.source=_faceSymbol;
			
			_faceShadow = new Image();
			_faceShadow.source=_faceShadowSymbol;
			
			_alerts=new UIComponent();
			
			_ticks=new UIComponent();
			
			_pointer=new Image();
			_pointer.source=_pointerSymbol;
			_pointer.filters=[_dropShadowFilter];
			
			_bezel=new Image();
			_bezel.source=_bezelSymbol;
			
			_center=new Image();
			_center.source=_centerSymbol;
			_center.filters=[_dropShadowFilter];
			
			_reflection=new Image();
			_reflection.source=_reflectionSymbol;
			
			_minLabel=new Label();
			_minLabel.setStyle("textAlign","left");
			_minLabel.visible = _showMinMax;
			
			_maxLabel=new Label();
			_maxLabel.setStyle("textAlign","right");
			_maxLabel.visible = _showMinMax;
			
			
			_valueLabel=new Label();    
			_valueLabel.setStyle("textAlign","center");		
			
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
		
		// Implement the commitProperties() method. 
		override protected function commitProperties():void {
			super.commitProperties();
		}
		
		override protected function measure():void {
			super.measure();
			
			if ( _diameter == this.width ) return;
			
			_diameter = this.width;
			
			//this is where we need to figure out appropriate heights of components
			_face.width=_diameter;//Gauge.FACE_DIAMETER * scale;
			_face.height=_face.width;
			_face.x=(_diameter-_face.width)/2;
			_face.y=_face.x;
			
			_faceShadow.width=_face.width;
			_faceShadow.height=_face.height;
			_faceShadow.y=_face.y;
			_faceShadow.x=_face.x;
			
			_ticks.height=_diameter;//Gauge.TICKS_DIAMETER*scale;
			_ticks.width=_ticks.height;
			_ticks.x=(_diameter - _ticks.width)/2;
			_ticks.y=_ticks.x;
			
			var oldrt:Number = _pointer.rotation;
			_pointer.rotation=0;
			_pointer.height = _diameter / 2 * POINTER_HEIGHT;
			_pointer.width = _diameter * POINTER_WIDTH;
			_pointer.x=(_diameter-_pointer.width)/2;
			_pointer.y = (_diameter / 2) - (_pointer.height * Gauge.POINTER_ORIGIN_SCALE);
			
			r.easingFunction = Exponential.easeOut;
			r.duration = 500;
			var originX:Number=_pointer.width/2;
			var originY:Number = _pointer.height * Gauge.POINTER_ORIGIN_SCALE;
			r.originX = originX;
			r.originY = originY;
			r.target = _pointer;
			
			_bezel.width=_diameter;//Gauge.BEZEL_DIAMETER*scale;
			_bezel.height=_bezel.width;
			_bezel.x=(_diameter-_bezel.width)/2;
			_bezel.y=_bezel.x;
			
			_center.width = _diameter * NUB_DIAMETER;
			_center.height=_center.width;
			_center.x=(_diameter-_center.width)/2;
			_center.y=_center.x;
			
			_reflection.width = _diameter * REFLECTION_WIDTH;
			_reflection.height = _diameter * REFLECTION_HEIGHT;
			_reflection.x = _reflection.y = _diameter * REFLECTION_OFFSET;
			
			_dropShadowFilter.distance=10;
			_dropShadowFilter.blurX=10;
			_dropShadowFilter.blurY=10;
			
			_center.filters=[_dropShadowFilter];
			_pointer.filters=[_dropShadowFilter];
			
			_valueLabel.y = _diameter * 0.8;
			_valueLabel.width=_diameter;
			_valueLabel.height=_diameter * 0.15;
			_valueLabel.setStyle("fontSize",_diameter * 0.11);
			
			var radius:Number = _ticks.width / 2;
			_minLabel.width=_diameter;
			_minLabel.height=_diameter * 0.1;
			_minLabel.setStyle("fontSize",_diameter * 0.05);
			_minLabel.x = radius + radius * Math.sin(radiansForValue(minValue)) * (SCALE_DIAMETER - TICK_LENGTH / 2);
			_minLabel.y = radius + radius * Math.cos(radiansForValue(minValue)) * (SCALE_DIAMETER - TICK_LENGTH / 2);
			
			_maxLabel.width=_diameter;
			_maxLabel.height=_diameter * 0.1;
			_maxLabel.setStyle("fontSize",_diameter * 0.05);
			_maxLabel.x = radius + radius * Math.sin(radiansForValue(maxValue)) * (SCALE_DIAMETER - TICK_LENGTH / 2) - _maxLabel.width;
			_maxLabel.y = radius + radius * Math.cos(radiansForValue(maxValue)) * (SCALE_DIAMETER - TICK_LENGTH / 2);
			
		}
		
		private function setValueLabel():void {
			if(valueFormatter) {
				_valueLabel.text=valueFormatter.format(value);
			}
			else {
				_valueLabel.text=value.toString();
			}
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void {
			
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			setValueLabel();
			_minLabel.text=minValue.toString();
			_maxLabel.text=maxValue.toString();
			
			var fontColor:Number = getStyle("fontColor");
			
			//_valueLabel.setStyle("fontSize",getStyle("fontSize"));
			_valueLabel.setStyle("color",fontColor);
			_valueLabel.setStyle("fontFamily",getStyle("fontFamily"));
			_valueLabel.setStyle("fontStyle",getStyle("fontStyle")); 
			_valueLabel.setStyle("fontWeight",getStyle("fontWeight"));
			_valueLabel.setStyle("fontSharpness",getStyle("fontSharpness"));
			_valueLabel.setStyle("fontAntiAliasType",getStyle("fontAntiAliasType"));
			_valueLabel.visible=this._showValue;
			
			_reflection.alpha=_glareAlpha;
			
			_minLabel.setStyle("color",fontColor);
			_maxLabel.setStyle("color",fontColor);
			
			measure();
			//this.clipContent=false;
			drawTicks();
			drawAlerts();
			
			// Check to see if style changed. 
			if (_faceColorChanged==true) 
			{
				transformColor(_face,getStyle("faceColor"));
				_faceColorChanged=false;
			}
			
			if (_faceShadowColorChanged==true) 
			{
				transformColor(_faceShadow,getStyle("faceShadowColor"));
				_faceShadowColorChanged=false;
			}
			if (_bezelColorChanged==true) 
			{
				transformColor(_bezel,getStyle("bezelColor"));
				_bezelColorChanged=false;
			}
			if (_centerColorChanged==true) 
			{
				transformColor(_center,getStyle("centerColor"));
				_centerColorChanged=false;
			}
			if (_pointerColorChanged==true) 
			{
				transformColor(_pointer,getStyle("pointerColor"));
				_pointerColorChanged=false;
			}
		}
		
		private function calculatePointerAngle():Number {
			//rotate appropriate angle
			return degreesForValue(_value);
		}
		
		private function degreesForValue(v:Number):Number {
			var delta:Number;
			var ratio:Number;
			var angle:Number;
			if (this.positiveMaxValue)
				delta=this._maxValue-this._minValue;
			else
				delta=this._minValue-this._maxValue;
			
			ratio=(v-_minValue)/delta;
			//Check to see if we exceed boundary conditions
			if (v > this._maxValue) ratio=1;
			if (v < this._minValue) ratio=0;
			angle=(240*ratio)-120
			
			return angle;			
		}
		
		private function radiansForValue(v:Number):Number {
			return -Math.PI - degreesForValue(v) * Math.PI / 180;
		}
		
		private function transformColor(obj:Object,color:Number):void {
			if (obj==null) return;
			var c:ColorTransform=new ColorTransform();
			c.color=color; 
			
			var ct:ColorTransform;
			
			ct=new ColorTransform(1,1,1,1,c.redOffset-127,c.greenOffset-127,c.blueOffset-127,0);
			obj.transform.colorTransform=ct;
			
		}
		
		/**
		 * This function draws the tick marks around the gauge
		 */
		private function drawTicks():void {  	
			var fCenterX:Number=(_ticks.width)/2;
			var fCenterY:Number=fCenterX;
			var fRadius:Number=fCenterX;
			
			var tickColor:Number=getStyle("ticksColor"); 
			
			_ticks.graphics.clear();
			_ticks.graphics.lineStyle(_diameter * TICK_THICKNESS,tickColor,1,false,LineScaleMode.NONE,CapsStyle.NONE);
			
			for(var i:int = 0; i <= _smallTicks; i++) {
				var value:Number = _minValue + i * (_maxValue - _minValue) / _smallTicks;
				var angle:Number = radiansForValue(value);
				var tick_x:Number = fRadius * Math.sin(angle);
				var tick_y:Number = fRadius * Math.cos(angle)
				_ticks.graphics.moveTo(fCenterX + tick_x * SCALE_DIAMETER,
					fCenterY + tick_y * SCALE_DIAMETER)
				if (i % (_smallTicks/_bigTicks) == 0) {
					_ticks.graphics.lineTo(fCenterX + tick_x * (SCALE_DIAMETER - TICK_LENGTH * 1.35),
						fCenterY + tick_y * (SCALE_DIAMETER - TICK_LENGTH * 1.35))
				}
				else {
					_ticks.graphics.lineTo(fCenterX + tick_x * (SCALE_DIAMETER - TICK_LENGTH),
						fCenterY + tick_y * (SCALE_DIAMETER - TICK_LENGTH))
				}
			}   	
		}
		
		private function rotatePointer(useEffect:Boolean = true):void  {
			var angle:Number = this.calculatePointerAngle();			
			if ( r.isPlaying ) {
				r.stop();
			}
			r.angleFrom = _pointer.rotation;
			r.angleTo = angle;
			r.play();
		}
		
		private function drawAlertArc(startAngle:Number, endAngle:Number, color:Number, alpha:Number):void {
			var origin:Point = new Point(_diameter / 2, _diameter / 2);
			var radius:Number = (_diameter * (SCALE_DIAMETER - TICK_LENGTH / 2)) / 2;
			var stroke:SolidColorStroke = new SolidColorStroke(color, _diameter * (TICK_LENGTH / 2), alpha,
				false, LineScaleMode.NONE, CapsStyle.NONE);
			GraphicsUtilities.setLineStyle(_alerts.graphics, stroke);
			GraphicsUtilities.drawArc(_alerts.graphics, origin.x, origin.y,
				startAngle - Math.PI / 2, endAngle - startAngle, radius);
		}
		
		private function drawAlerts():void {
			var levels:Array=getStyle("alertRatios").concat();
			levels.unshift(_minValue);
			levels.push(_maxValue);
			var colors:Array=getStyle("alertColors");
			var alphas:Array=getStyle("alertAlphas");
			
			if (!(null in [levels, colors, alphas])) {;
				var delta:Number;
				var ratio:Number;
				
				if (this.positiveMaxValue) {
					delta = this._maxValue - this._minValue;
				}
				else {
					delta = this._minValue - this._maxValue;
				}
				ratio=_value/_maxValue;
				
				this._alerts.graphics.clear();
				for (var i:int = 0; i < levels.length -1; i++) {
					drawAlertArc(radiansForValue(levels[i]), radiansForValue(levels[i+1]), colors[i], alphas[i]);
				}
			}
		}
	}
}