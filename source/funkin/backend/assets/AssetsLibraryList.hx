package funkin.backend.assets;

#if TRANSLATIONS_SUPPORT
import funkin.backend.assets.TranslatedAssetLibrary;
#end
import funkin.backend.assets.ICustomAssetLibrary;
import funkin.backend.utils.AssetUtil;
import funkin.backend.system.Logs;
import lime.utils.AssetLibrary;
import haxe.ds.Map;

class AssetsLibraryList extends AssetLibrary
{
	public var libraries:Array<AssetLibrary> = [];

	@:allow(funkin.backend.system.Main)
	private var __defaultLibraries:Array<AssetLibrary> = [];

	public var base:AssetLibrary;

	#if TRANSLATIONS_SUPPORT
	public var transLib:TranslatedAssetLibrary;
	#end

	public function removeLibrary(lib:AssetLibrary)
	{
		if (lib != null)
		{
			libraries.remove(lib);
			#if TRANSLATIONS_SUPPORT
			for (l in libraries)
			{
				if (l == null)
					continue;
				if (l is TranslatedAssetLibrary)
				{
					var tlib = cast(l, TranslatedAssetLibrary);
					if (lib is ICustomAssetLibrary && tlib.forLibrary == cast(lib, ICustomAssetLibrary))
					{
						libraries.remove(tlib);
						break;
					}
				}
			}
			#end
		}
		return lib;
	}

	public function existsSpecific(id:String, type:String)
	{
		if (!id.startsWith("assets/") && existsSpecific('assets/$id', type))
			return true;
		for (k => l in libraries)
		{
			if (l.exists(id, type))
			{
				return true;
			}
		}
		return false;
	}

	public override inline function exists(id:String, type:String):Bool
		return existsSpecific(id, type);

	public function getSpecificPath(id:String)
	{
		for (k => e in libraries)
		{
			@:privateAccess
			if (e.exists(id, e.types.get(id)))
			{
				var path = e.getPath(id);
				if (path != null)
					return path;
			}
		}
		return null;
	}

	public override inline function getPath(id:String)
		return getSpecificPath(id);

	public function getFiles(folder:String):Array<String>
	{
		var content:Array<String> = [];
		for (k => l in libraries)
		{
			l = getCleanLibrary(l);

			// TODO: do base folder scanning
			if (l is ICustomAssetLibrary)
			{
				var lib = cast(l, ICustomAssetLibrary);
				for (e in lib.getFiles(folder))
					content.pushOnce(e);
			}
		}
		return content;
	}

	public function getFolders(folder:String):Array<String>
	{
		var content:Array<String> = [];
		for (k => l in libraries)
		{
			l = getCleanLibrary(l);

			// TODO: do base folder scanning
			if (l is ICustomAssetLibrary)
			{
				var lib = cast(l, ICustomAssetLibrary);
				for (e in lib.getFolders(folder))
					content.pushOnce(e);
			}
		}
		return content;
	}

	public function getSpecificAsset(id:String, type:String):Dynamic
	{
		try
		{
			if (!id.startsWith("assets/"))
			{
				var ass = getSpecificAsset('assets/$id', type);
				if (ass != null)
				{
					return ass;
				}
			}
			for (k => l in libraries)
			{
				@:privateAccess
				if (l.exists(id, l.types.get(id)))
				{
					var asset = l.getAsset(id, type);
					if (asset != null)
					{
						return asset;
					}
				}
			}
			return null;
		}
		catch (e)
		{
			Logs.error('Error in getSpecificAsset: $e');
			throw e;
		}
		return null;
	}

	public override inline function getAsset(id:String, type:String):Dynamic
		return getSpecificAsset(id, type);

	public override function list(type:String):Array<String> {
		// idk if there's a more efficient way tbh, correct if u find better
		var files:Map<String, Bool> = [];
		for(k=>l in libraries) {
			for(f in l.list(type))
				files.set(f, false);
		}
		return [for(k=>e in files) k];
	}

	public override function isLocal(id:String, type:String) {
		return true;
	}

	public function new(?base:AssetLibrary)
	{
		super();
		if (base == null)
			this.base = Assets.getLibrary("default");
		else
			this.base = base;
		__defaultLibraries.push(this.base);

		#if (sys && TEST_BUILD)
		Logs.infos("Used cne test / cne build. Switching into source assets.");

		__defaultLibraries.push(AssetUtil.loadLibraryFromFolder('assets', './${Main.pathBack}assets/'));
		#elseif USE_ADAPTED_ASSETS
		__defaultLibraries.push(AssetUtil.loadLibraryFromFolder('assets', './assets/'));
		#end
		for (d in __defaultLibraries)
			addLibrary(d);
	}

	public function unloadLibraries()
	{
		for (l in libraries)
			if (!__defaultLibraries.contains(l))
				l.unload();
	}

	public function reset()
	{
		unloadLibraries();

		libraries = [];

		// adds default libraries in again
		for (d in __defaultLibraries)
			addLibrary(d);
	}

	public function addLibrary(lib:AssetLibrary, ?addTransLib:Bool = true)
	{
		libraries.insert(0, lib);
		#if TRANSLATIONS_SUPPORT
		if (addTransLib)
		{
			var cleanLib = getCleanLibrary(lib);
			if (cleanLib != null && (cleanLib is ICustomAssetLibrary))
			{
				var transLib = new TranslatedAssetLibrary(cast(cleanLib, ICustomAssetLibrary));
				// transLib.tag = cleanLib.tag;
				libraries.insert(0, transLib);
			}
		}
		#end
		return lib;
	}

	public static function getCleanLibrary(e:AssetLibrary):AssetLibrary
	{
		var l = e;
		if (l is openfl.utils.AssetLibrary)
		{
			var al = cast(l, openfl.utils.AssetLibrary);
			@:privateAccess
			if (al.__proxy != null)
				l = al.__proxy;
		}
		return l;
	}
}
