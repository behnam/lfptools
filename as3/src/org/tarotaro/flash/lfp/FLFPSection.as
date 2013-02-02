package org.tarotaro.flash.lfp
{
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.FileReference;
	import flash.utils.ByteArray;

	public class FLFPSection
	{
		protected var _data:ByteArray;
		protected var _typeCode:String;
		protected var _sha1:String;
		protected var _type:FLFPType = FLFPType.TYPE_UNKNOWN;
		protected var _name:String;

		public function FLFPSection()
		{
			this._type = FLFPType.TYPE_RAW_IMAGE;
		}

		public function get name():String
		{
			return _name;
		}

		public function set name(value:String):void
		{
			_name = value;
		}

		public function get type():FLFPType
		{
			
			return _type == null ? FLFPType.TYPE_UNKNOWN : _type;
		}

		public function set type(value:FLFPType):void
		{
			_type = value;
		}

		public function get sha1():String
		{
			return _sha1;
		}

		public function set sha1(value:String):void
		{
			_sha1 = value;
		}

		public function get data():ByteArray
		{
			if (_data == null) {
				_data = new ByteArray();
			}
			return _data;
		}

		public function get typeCode():String
		{
			return _typeCode;
		}

		public function set typeCode(value:String):void
		{
			_typeCode = value;
		}
		
		public function get length():int
		{
			return this.data.length;
		}

		/**
		 * 指定されたパスに、指定されたファイル名で正しい形で保存
		 * @param path 保存フォルダ
		 * @param filename 保存ファイル名
		 */
		public function save(path:String, prefix:String):void
		{
			var curr:int = this.data.position;
			this.data.position = 0;
			trace(prefix + "_" + this.name, this.data.position , "-" , this.data.bytesAvailable);
			var postfix:String = this.name;
			var ext:String;
			var stream:FileStream = new FileStream();
			switch (this.type) {
				case FLFPType.TYPE_JSON:
					ext = ".json";
					stream.open(new File(path + "/" + prefix + "_" + postfix + ext), FileMode.WRITE);
					stream.writeUTFBytes(this.data.readUTFBytes(this.data.bytesAvailable));
					stream.close();
					break;
				case FLFPType.TYPE_DEPTH_LUT:
					ext = ".txt";
					stream.open(new File(path + "/" + prefix + "_" + postfix + ext), FileMode.WRITE);
					stream.writeUTFBytes(this.data.readUTFBytes(this.data.bytesAvailable));
					stream.close();
					break;
				case FLFPType.TYPE_RAW_IMAGE:
					ext = ".raw";
					stream.open(new File(path + "/" + prefix + "_" + postfix + ext),FileMode.WRITE);
					stream.writeBytes(this.data, this.data.position, this.data.bytesAvailable);
					stream.close();
					break;
				case FLFPType.TYPE_JPEG:
					ext = ".jpg";
					stream.open(new File(path + "/" + prefix + "_" + postfix + ext),FileMode.WRITE);
					stream.writeBytes(this.data, this.data.position, this.data.bytesAvailable);
					stream.close();
				case FLFPType.TYPE_UNKNOWN:
				default:
					return;
			}
			this.data.position = curr;
		}
	}
}