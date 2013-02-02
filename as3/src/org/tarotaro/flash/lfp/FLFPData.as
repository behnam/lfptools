package org.tarotaro.flash.lfp
{
	import flash.utils.ByteArray;

	public class FLFPData
	{
		public static const LFP_MAGIC_HEADER_BYTES:Array = 
			new Array(0x89, 0x4C, 0x46, 0x50, 
				0x0D, 0x0A, 0x1A, 0x0A,
				0x00, 0x00, 0x00, 0x01,
				0x00, 0x00, 0x00, 0x00);
		public static const LFC_MAGIC_HEADER_BYTES:Array =
			new Array(0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x00);
		public static const LFP_HEADER_START_POSITION:uint = 0;
		public static const LFP_HEADER_LENGTH:uint = 12;
		public static const LFP_HEADER_AND_PADDING_LENGTH:uint = 16;
		public static const TYPE_CODE_LENGTH:uint = 4;
		public static const SHA1_LENGTH:uint = 45;
		public static const SHA1_PADDING_LENGTH:uint = 35;

		private var data:ByteArray;

		private var _tableOfContents:FLFPToC;
		private var _sections:Vector.<FLFPSection>;
		private var _name:String;
		
		public function FLFPData(n:String, d:ByteArray)
		{
			this._sections = new Vector.<FLFPSection>();
			this.data = d;
			this.name = n;
			this.parse(data);
		}
		
		public function get name():String
		{
			return _name;
		}

		public function set name(value:String):void
		{
			_name = value;
		}

		public function get sections():Vector.<FLFPSection>
		{
			return _sections;
		}

		public function get tableOfContents():FLFPToC
		{
			return _tableOfContents;
		}

		public function set tableOfContents(value:FLFPToC):void
		{
			_tableOfContents = value;
		}
		
		public function save(path:String, prefix:String):void
		{
			if (this.tableOfContents) {
				this.tableOfContents.save(path, prefix + "_001");
			}
			
			var i:int = 2;
			for each (var s:FLFPSection in this.sections) {
				s.save(path, prefix + "_" + ("000" + i++.toString()).substr(-3));
			}
		}

		public function parse(data:ByteArray):void
		{
			//先頭のMagic 12byte Headerを読み込み
			this.checkLFPMagicHeader();
			
			//最初のSectionは、lfpファイルの中身を表すJSONテーブルになっている
			var firstSection:FLFPSection = this.parseSection(this.data);
			firstSection.type = FLFPType.TYPE_JSON;
			firstSection.name = "table";
			
			//Table of Contentsを作成し、登録
			var toc:FLFPToC = new FLFPToC(firstSection);
			this.tableOfContents = toc;
			
			//残りのデータを読み込み
			while ((data.position + LFP_HEADER_LENGTH) < data.length) {
				//Sectionのパースを実行
				var section:FLFPSection = this.parseSection(this.data);
				//Sectionのtypeを決定
				this.identifySection(section);
				//Sectionを追加
				this.addSection(section);
			}
			
			
		}

		private function identifySection(section:FLFPSection):void
		{
			var jpeg:Array = new Array(0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46);
			var sha1:FLFPSha1 = this.tableOfContents.getNameBySha1(section.sha1);
			if (sha1 != null) {
				section.name = sha1.name;
			}
			if (section.length == 1600) {
				section.type = FLFPType.TYPE_DEPTH_LUT;
				section.name = "depth";
			}
			if (section.length > jpeg.length) {
				var curr:uint = section.data.position;
				var isJPG:Boolean = true;
				for (var i:uint = 0; isJPG && i < jpeg.length;i++) {
					isJPG = (jpeg[i] == section.data.readUnsignedByte());
				}
				if (isJPG) {
					section.type = FLFPType.TYPE_JPEG;
					section.name = "image";
				}
				section.data.position = curr;
			}
			if (section.name != "imageRef") {
				section.type = FLFPType.TYPE_JSON;
			}
		}
		
		private function addSection(s:FLFPSection):void
		{
			this._sections.push(s);
		}
			
		private function parseSection(data:ByteArray):FLFPSection
		{
			//最初4バイトがtype（LFM, LFC）
			//その次8バイトがヘッダ部分（0D 0A 1A 0A 00 00 00 00）
			//その次4バイトが長さ(ビッグエンディアン)
			//次の45バイトがsha1
			//次の35バイトがNULL PADDING
			var section:FLFPSection = new FLFPSection();
			
			//type読み込み
			section.typeCode = data.readUTFBytes(TYPE_CODE_LENGTH);
			
			//ヘッダ読み込み
			for (var i:uint = 0;i < LFC_MAGIC_HEADER_BYTES.length;i++) {
				if (LFC_MAGIC_HEADER_BYTES[i] != data.readUnsignedByte()) {
					throw new FLFPParseError("invalid lfc/lfm magic header bytes.");
				}
			}
			
			//長さ読み込み
			var length:uint = data.readUnsignedInt();
			
			//SHA1読み込み
			section.sha1 = data.readUTFBytes(SHA1_LENGTH);
			data.position += SHA1_PADDING_LENGTH;
			
			//データ読み込み
			data.readBytes(section.data, 0, length);
			section.data.position = 0;
			
			//最後のNULL PADDINGを読み進める
			while (data.position < data.length && !data.readBoolean());
			data.position--;
			return section;
		}
		
		private function checkLFPMagicHeader():void
		{
			var isLFP:Boolean = true;
			for(var i:int = LFP_HEADER_START_POSITION;
				isLFP && i < LFP_MAGIC_HEADER_BYTES.length;
				i++) {
				if (LFP_MAGIC_HEADER_BYTES[i] != data.readUnsignedByte()) {
					throw new FLFPParseError("invalid lfp magic header bytes.");
				}
			}
		}
		

	}
}