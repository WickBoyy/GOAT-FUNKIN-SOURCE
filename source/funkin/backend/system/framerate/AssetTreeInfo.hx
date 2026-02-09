package funkin.backend.system.framerate;

#if TRANSLATIONS_SUPPORT
import funkin.backend.assets.TranslatedAssetLibrary;
#end
import funkin.backend.assets.AssetsLibraryList;
import funkin.backend.assets.ICustomAssetLibrary;

class AssetTreeInfo extends FramerateCategory
{
	private var lastUpdateTime:Float = 1;

	public function new()
	{
		super("Asset Libraries Tree Info");
	}

	public override function __enterFrame(t:Int)
	{
		if (alpha <= 0.05)
			return;

		if ((lastUpdateTime += FlxG.rawElapsed) < 1)
			return;

		lastUpdateTime = 0;

		var text = 'Not initialized yet\n';
		if (Paths.assetsTree != null)
		{
			text = "";
			for (l in Paths.assetsTree.libraries)
			{
				var l = AssetsLibraryList.getCleanLibrary(l);

				var className = Type.getClassName(Type.getClass(l));
				className = className.substr(className.lastIndexOf(".") + 1);

				#if TRANSLATIONS_SUPPORT
				if (l is TranslatedAssetLibrary)
					text += '${className} - ${cast (l, TranslatedAssetLibrary).langFolder} for (${cast (l, TranslatedAssetLibrary).forLibrary.libName})\n';
				else
				#end
				if (l is ICustomAssetLibrary)
					text += '${className} - ${cast (l, ICustomAssetLibrary).libName} (${cast (l, ICustomAssetLibrary).prefix})\n';
				else
					text += Std.string(l) + '\n';
			}
		}
		if (text != "")
			text = text.substr(0, text.length - 1);

		this.text.text = text;
		super.__enterFrame(t);
	}
}
