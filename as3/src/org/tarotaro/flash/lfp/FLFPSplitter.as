package org.tarotaro.flash.lfp
{
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.FileFilter;
	import flash.utils.ByteArray;

	public class FLFPSplitter
	{
		
		private var lfp:FLFPData;
		public function FLFPSplitter()
		{
		}
		
		public function openFile():void{
			var file:File = new File();
			var lfpFilter:FileFilter = new FileFilter("Lytro", "*.lfp");
			
			file.addEventListener(Event.SELECT, fileOpenSelected);
			file.addEventListener(Event.CANCEL, fileOpenCanceled);
			file.browseForOpen("Open", new Array(lfpFilter));
		}
		
		protected function fileOpenCanceled(event:Event):void
		{
			// TODO Auto-generated method stub
			
		}
		
		protected function fileOpenSelected(event:Event):void
		{
			// TODO Auto-generated method stub
			var stream:FileStream = new FileStream();
			var data:ByteArray = new ByteArray();
			var file:File = event.target as File;
			stream.open(file,FileMode.READ);
			stream.readBytes(data, 0, 0);
			stream.close();
			this.lfp = new FLFPData(file.name.substring(0, file.name.length - 4), data);
			trace("sections:" , this.lfp.sections.length);
			for each (var section:FLFPSection in this.lfp.sections) {
				trace(section.typeCode, section.type.name, section.name, section.length, section.sha1);
			}
		}
		
		public function saveFile():void
		{
			var file:File = new File();
			var lfpFilter:FileFilter = new FileFilter("Lytro", "*.lfp");
			
			file.addEventListener(Event.SELECT, fileSaveSelected);
			file.addEventListener(Event.CANCEL, fileSaveCanceled);
			file.browseForDirectory("Save");
		}
		
		protected function fileSaveSelected(event:Event):void
		{
			var file:File = event.target as File;
			this.lfp.save(file.nativePath, this.lfp.name);
			
		}
		
		protected function fileSaveCanceled(event:Event):void
		{
			// TODO Auto-generated method stub
			
		}
	}
}