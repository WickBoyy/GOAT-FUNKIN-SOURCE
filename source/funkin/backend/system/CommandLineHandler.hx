package funkin.backend.system;

#if sys
import sys.FileSystem;

final class CommandLineHandler
{
	public static function parseCommandLine(cmd:Array<String>)
	{
		var i:Int = 0;
		while (i < cmd.length)
		{
			switch (cmd[i])
			{
				case null:
					break;
				case "-h" | "-help" | "help":
					Sys.println("-- Codename Engine Command Line help --");
					Sys.println("-help                | Show this help");

					Sys.println("-nocolor             | Disables colors in the terminal");
					Sys.println("-nogpubitmap         | Forces GPU only bitmaps off");
					Sys.println("-nocwdfix            | Turns off automatic working directory fix");
					Sys.exit(0);

				case "-nocolor":
					Main.noTerminalColor = true;
				case "-nogpubitmap":
					Main.forceGPUOnlyBitmapsOff = true;
				case "-nocwdfix":
					Main.noCwdFix = true;
				case "-livereload":
					// do nothing
					Main.verbose = true;
				default:
					Sys.println("Unknown command");
			}
			i++;
		}
	}
}
#end
