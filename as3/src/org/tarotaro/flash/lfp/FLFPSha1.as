package org.tarotaro.flash.lfp
{
	internal class FLFPSha1 {
		private var _name:String;
		private var _sha1:String;
		
		public function FLFPSha1(n:String, s:String)
		{
			this._name = n;
			this._sha1 = s;
		}

		public function get sha1():String
		{
			return _sha1;
		}

		public function get name():String
		{
			return _name;
		}

	}
}