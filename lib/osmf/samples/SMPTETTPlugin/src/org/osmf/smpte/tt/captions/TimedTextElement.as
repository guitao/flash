/***********************************************************
 * 
 * Copyright 2011 Adobe Systems Incorporated. All Rights Reserved.
 *
 * *********************************************************
 * The contents of this file are subject to the Berkeley Software Distribution (BSD) Licence
 * (the "License"); you may not use this file except in
 * compliance with the License. 
 *
 * Software distributed under the License is distributed on an "AS IS"
 * basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
 * License for the specific language governing rights and limitations
 * under the License.
 *
 *
 * The Initial Developer of the Original Code is Adobe Systems Incorporated.
 * Portions created by Adobe Systems Incorporated are Copyright (C) 2011 Adobe Systems
 * Incorporated. All Rights Reserved.
 **********************************************************/
package org.osmf.smpte.tt.captions
{
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	import org.osmf.metadata.TimelineMarker;
	import org.osmf.smpte.tt.events.PropertyChangedEvent;
	import org.osmf.smpte.tt.timing.TimeCode;
	import org.osmf.smpte.tt.timing.TimeSpan;
	import org.osmf.smpte.tt.utilities.VectorUtils;
	
	/**
	 * The base class for captioning elements.
	 */
	public class TimedTextElement extends TimelineMarker
	{	
		private var _id:String;
		private var _type:String;
		private var _end:Number;
		private var _content:*;
		private var _currentStyle:TimedTextStyle;
		private var _style:TimedTextStyle;
		private var _captionElementType:TimedTextElementType;
		private var _animations:Vector.<TimedTextAnimation>;
		private var _children:Vector.<TimedTextElement>;
		private var _siblings:Vector.<TimedTextElement>;
		
		/**
		 * Gets or sets a unique identifier for the marker.
		 * 
		 * <p>The id is used to determine which markers are new each time polling occurs.</p>
		 */
		public function get id():String
		{
			return _id;
		}

		public function set id(value:String):void
		{
			if(_id!=value){
				_id = value;
			}
		}

		
		/**
		 * Gets or sets the text associated with this marker.
		 */
		public function get content():*
		{
			return _content;
		}
		
		public function set content(value:*):void
		{
			if(_content!=value){
				var oldContent:* = _content;
				_content = value;
			}
		}
		
		/**
		 * Gets or sets the type to be applied to this element.
		 */
		public function get type():String
		{
			return _type;
		}
		public function set type(value:String):void
		{
			if(_type!=value){
				var oldValue:* = _type;
				_type = value;
			}
		}
		
		public function get children():Vector.<TimedTextElement>
		{
			return _children;
		}
		
		public function get siblings():Vector.<TimedTextElement>
		{
			return _siblings;
		}
		
		/**
		 * Gets or sets the Style to be applied to this element.
		 */
		public function get style():TimedTextStyle
		{
			return _style;
		}
		public function set style(value:TimedTextStyle):void
		{
			if(_style!=value){
				var oldValue:* = _style;
				_style = value;
				_currentStyle = value;
			}
		}
		
		/**
		 * Gets or sets the current style of this element.
		 */
		public function get currentStyle():TimedTextStyle
		{
			return _currentStyle;
		}
		protected function set currentStyle(value:TimedTextStyle):void
		{			
			if (_currentStyle != value)
			{
				var oldValue:* = _currentStyle;
				_currentStyle = value;
			}
		}
		
		/**
		 * Gets or sets the type of this caption element.
		 */
		public function get captionElementType():TimedTextElementType
		{
			return _captionElementType;
		}
		
		public function set captionElementType(value:TimedTextElementType):void
		{
			_captionElementType = value;
		}
		
		/**
		 * The start time in seconds.
		 *  
		 *  @langversion 3.0
		 *  @playerversion Flash 10
		 *  @playerversion AIR 1.5
		 *  @productversion OSMF 1.6
		 */
		public function get begin():Number
		{
			return time;
		}
		
		/**
		 * The end time in seconds.
		 *  
		 *  @langversion 3.0
		 *  @playerversion Flash 10
		 *  @playerversion AIR 1.5
		 *  @productversion OSMF 1.6
		 */
		public function get end():Number
		{
			return _end;
		}
		
		/**
		 * Gets or sets the list of animations to be applied to this element.
		 */
		public function get animations():Vector.<TimedTextAnimation>
		{
			return _animations;
		}
		
		public function TimedTextElement(start:Number, end:Number, id:String=null)
		{
			
			var duration:Number = end > 0 ? (end - start) : NaN;
			super(start, duration);
			
			_type = "captionelement";
			_style = new TimedTextStyle();
			_animations = new Vector.<TimedTextAnimation>();
			_children = new Vector.<TimedTextElement>();
			_siblings = new Vector.<TimedTextElement>();
			_end = end;
			_id = (id==null) ? flash.utils.getTimer().toString() : id;
		}
		
		public function get hasAnimations():Boolean
		{
			if(animations.length>0) return true;
			for each(var i:TimedTextElement in children){
				if(i.hasAnimations) return true; 
			}
			return false;
		}
		
		public function calculateCurrentStyle(position:Number):void
		{
			var func:Function;
			var activeAnimations:Vector.<TimedTextElement> = TimedTextElement.whereActiveAtPosition(animations as Vector.<TimedTextElement>,position);
			
			if (activeAnimations.length>0)
			{
				var animatedStyle:TimedTextStyle = style.clone();
				func = function(item:*, index:int, array:Array):void
				{
					if(item is TimedTextAnimation) (item as TimedTextAnimation).mergeStyle(this);
				}
				VectorUtils.toArray(activeAnimations).map(func, animatedStyle);
				_currentStyle = animatedStyle;
			}
			var i:Vector.<TimedTextElement> = TimedTextElement.whereActiveAtPosition(children,position);
			func = function(item:*, index:int, array:Array):void
			{
				TimedTextElement(item).calculateCurrentStyle(this);
			}
			VectorUtils.toArray(i).map(func,position);
		}
		
		
		public function isActiveAtPosition(position:Number, round:Boolean = false):Boolean
		{
			return TimedTextElement.IsActiveAtPosition(this,position,round);
		}
		
		public function isContainedByRange(rangeStart:Number, rangeEnd:Number):Boolean
		{
			return TimedTextElement.IsContainedByRange(this,rangeStart,rangeEnd);
		}
		
		public function isActiveInRange(rangeStart:Number, rangeEnd:Number):Boolean
		{
			return TimedTextElement.IsActiveInRange(this,rangeStart,rangeEnd);
		}
		
		public static function IsActiveAtPosition(tte:TimedTextElement, position:Number, round:Boolean = false):Boolean
		{

			if (round)
			{
				var bFloor:Number = Math.floor(tte.begin*100)/100;
				var pRound:Number = Math.round(position*100)/100;
				var eCeil:Number = Math.ceil(tte.end*100)/100;
				var beginRange:Number = Math.abs(position-tte.begin);
				var endRange:Number = Math.abs(tte.end-position);
				var closeEnough:Boolean = (bFloor <= pRound || beginRange <= 0.25) && (eCeil > pRound && endRange>0.1);
				/*
				var label:String = "";
				
				if (tte.content)
					label += tte.content;
				
				getContent(tte, label);
				
				function getContent(ce:TimedTextElement, label:String):void
				{
					if (ce.content)
					{
						label += ce.content;
					} 
					for each (var c:TimedTextElement in ce.children)
					{
						getContent(c, label);
					}
				}
				if(label.length)
					trace(closeEnough+" : \n\t" + label +"\n\t" + bFloor +" <= "+ pRound + " ("+beginRange+") && " + eCeil +" > "+ pRound+ " ("+endRange+")");
				*/
				return closeEnough;
			}
			return tte.begin <= position && position < tte.end;
		}
		
		public static function IsContainedByRange(tte:TimedTextElement, rangeStart:Number, rangeEnd:Number):Boolean
		{
			return tte.time > rangeStart
				&& tte.time < rangeEnd
				&& tte.end > rangeStart
				&& tte.end < rangeEnd;
		}
		
		public static function IsActiveInRange(tte:TimedTextElement, rangeStart:Number, rangeEnd:Number):Boolean
		{
			return tte.time < rangeEnd && tte.end > rangeStart;
		}
		
		public static function whereActiveAtPosition(vector:Vector.<TimedTextElement>, position:Number):Vector.<TimedTextElement>
		{
			var func:Function = function(item:*, index:int, vector:Array):Boolean
				{
					return (item as TimedTextElement).isActiveAtPosition(this);
				}
			return Vector.<TimedTextElement>( VectorUtils.toArray(vector).filter(func,position) );
		}
		
	}
}