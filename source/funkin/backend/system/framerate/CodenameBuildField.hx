package funkin.backend.system.framerate;

import openfl.text.TextField;

class CodenameBuildField extends TextField
{
	public function new()
	{
		super();
		defaultTextFormat = Framerate.textFormat;
		autoSize = LEFT;
		multiline = wordWrap = false;
		reload();
	}

	public function reload()
	{
		text = '${Flags.VERSION_MESSAGE}';
	}
}
