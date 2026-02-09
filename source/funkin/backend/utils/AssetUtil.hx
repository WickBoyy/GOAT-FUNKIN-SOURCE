package funkin.backend.utils;

import lime.text.Font;
import openfl.text.Font as OpenFLFont;
import openfl.utils.AssetLibrary;
import openfl.utils.AssetManifest;
import funkin.backend.assets.ICustomAssetLibrary;
import funkin.backend.assets.FolderAssetLibrary;

class AssetUtil
{
	public static var useLibFile:Bool = true;

	public static function prepareManifest(libName:String):AssetLibrary
	{
		var assets:AssetManifest = new AssetManifest();
		assets.name = libName;
		assets.version = 2;
		assets.libraryArgs = [];
		assets.assets = [];

		return AssetLibrary.fromManifest(assets);
	}

	public static function registerFont(font:Font)
	{
		var openflFont = new OpenFLFont();
		@:privateAccess
		openflFont.__fromLimeFont(font);
		OpenFLFont.registerFont(openflFont);
		return font;
	}

	public static function prepareLibrary(libName:String, lib:ICustomAssetLibrary)
	{
		var openLib = prepareManifest(libName);
		lib.prefix = 'assets/';
		@:privateAccess
		openLib.__proxy = cast(lib, lime.utils.AssetLibrary);
		return openLib;
	}

	public static function loadLibraryFromFolder(libName:String, folder:String)
		return prepareLibrary(libName, new FolderAssetLibrary(folder, libName));
}
