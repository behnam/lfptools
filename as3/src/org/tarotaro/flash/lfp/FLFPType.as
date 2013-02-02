package org.tarotaro.flash.lfp {
	internal final class FLFPType
	{
		private var _type:String;
		
		public static const TYPE_JSON:FLFPType = new FLFPType("json");
		public static const TYPE_RAW_IMAGE:FLFPType = new FLFPType("raw_image");
		public static const TYPE_DEPTH_LUT:FLFPType = new FLFPType("lut");
		public static const TYPE_JPEG:FLFPType = new FLFPType("jpeg");
		public static const TYPE_UNKNOWN:FLFPType = new FLFPType("unknown");
		
		public function FLFPType(t:String){
			this._type = t;
		}
		
		public function get name():String
		{
			return _type;
		}

	}

}