package org.tarotaro.flash.lfp
{
	import flash.utils.ByteArray;

	public class FLFPToC extends FLFPSection
	{
		private var _asString:String;
		private var _asObject:Object;
		
		private var _section:FLFPSection;
		private var _sha1Map:Object;
		
		override public function get data():ByteArray
		{
			return this._section.data;
		}
		
		override public function get length():int
		{
			return this._section.length;
		}
		
		override public function get name():String
		{
			return this._section.name;
		}
		
		override public function set name(value:String):void
		{
			this._section.name = value;
		}
		
		override public function get sha1():String
		{
			return this._section.sha1;
		}
		
		override public function set sha1(value:String):void
		{
			this._section.sha1 = value;
		}
		
		override public function get type():FLFPType
		{
			return this._section.type;
		}
		
		override public function set type(value:FLFPType):void
		{
			this._section.type = value;
		}
		
		override public function get typeCode():String
		{
			return this._section.typeCode;
		}
		
		override public function set typeCode(value:String):void
		{
			this._section.typeCode = value;
		}
		
		
		public function FLFPToC(section:FLFPSection)
		{
			this._sha1Map = new Object();
			if (section.name != "table" || section.type != FLFPType.TYPE_JSON) {
				throw new ArgumentError("section.name must be \"table\" and " +
										"section.type must be \"json\". " +
										"your section.name is \"" + section.name + 
										"\" and section.type is \"" +section.type.name + "\".");
			}			
			this._section = section;
			this._asString = section.data.readUTFBytes(section.data.bytesAvailable);
			this._asObject = JSON.parse(this._asString);
			
			//sha1のデータを抜き出しておく
			var sha1Reg:RegExp = /\s*"(.*)?"\s*:\s*\[?\s*"(sha1-.*)?"/g;
			var result:Array = sha1Reg.exec(this.asString);
			while (result != null) {
				var sha1:FLFPSha1 = new FLFPSha1(result[1], result[2]);
				this._sha1Map[sha1.sha1] = sha1;
				result = sha1Reg.exec(this.asString);
			}
		}
		
		public function getNameBySha1(shaData:String)
		{
			return this._sha1Map[shaData];
		}

		public function get asObject():Object
		{
			return _asObject;
		}

		public function get asString():String
		{
			return _asString;
		}
	}
}