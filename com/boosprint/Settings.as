import com.Utils.Archive;
import com.boosprintcommon.DebugWindow;
/**
 * ...
 * @author ...
 */
class com.boosprint.Settings
{
	private static var SPRINT_TAG:String = "SPRINT_TAG";
	private static var SPRINT_ENABLED:String = "SPRINT_ENABLED";
	private static var SPRINT_INTERVAL:String = "SPRINT_INTERVAL";
	private static var PET_TAG:String = "PET_TAG";
	private static var PET_ENABLED:String = "PET_ENABLED";
	private static var OVERRIDE_KEY:String = "OVERRIDE_KEY";
	private static var SMART_SPRINT:String = "SMART_SPRINT";
	
	public static var Separator:String = "|";
	public static var Enabled:String = "enabled";
	public static var X:String = "x";
	public static var Y:String = "y";
	public static var Width:String = "width";
	public static var Height:String = "height";
	public static var Alpha:String = "alpha";
	public static var Text:String = "text";
	public static var Font:String = "font";
	public static var Size:String = "size";
	public static var Colour:String = "colour";
	public static var Colour2:String = "colour2";
	public static var Delay:String = "delay";
	public static var TimeAdjustment:String = "timeadjust";

	public static var SizeSmall:String = "small";
	public static var SizeMedium:String = "medium";
	public static var SizeLarge:String = "large";
	
	public static var General:String = "General";
	
	private static var Version:String = "VERSION";

	private static var m_version:String = null;
	private static var m_archive:Archive = null;
	private static var m_fontArray:Array = null;

	public static function SetVersion(version:String):Void
	{
		m_version = version;
	}
	
	public static function SetArchive(archive:Archive):Void
	{
		m_archive = archive;
		
		if (m_archive != null)
		{
			m_archive.DeleteEntry(Version);
			m_archive.AddEntry(Version, m_version);
		}
	}
	
	public static function GetArchive():Archive
	{
		if (m_archive == null)
		{
			return new Archive();
		}
		
		return m_archive;
	}
	
	public static function Trim(inStr:String):String
	{
		if (inStr == null)
		{
			return "";
		}
		
		var ret:String = inStr;
		while (ret.charAt(ret.length - 1) == " ")
		{
			ret = ret.substr(0, ret.length - 1);
		}
		
		return ret;
	}
	
	public static function SizeToFontSize(inSize:String):Number
	{
		if (inSize == SizeSmall)
		{
			return 12;
		}
		else if (inSize == SizeMedium)
		{
			return 16;
		}
		else if (inSize = SizeLarge)
		{
			return 24;
		}
		
		return 12;
	}
	
	public static function GetArrayFromString(inArrayString:String):Array
	{
		if (inArrayString.indexOf("|") == -1)
		{
			var ret:Array = new Array();
			ret.push(inArrayString);
			return ret;
		}
		else
		{
			return inArrayString.split("|");
		}
	}
	
	public static function GetArrayString(inArray:Array):String
	{
		var arrayString:String = "";
		for (var i:Number = 0; i < inArray.length; i++)
		{
			if (i > 0)
			{
				arrayString = arrayString + "|";
			}
			
			arrayString = arrayString + inArray[i];
		}
		
		return arrayString;
	}

	public static function Save(prefix:String, settings:Object, defaults:Object):Void
	{
		if (m_archive == null)
		{
			DebugWindow.Log(DebugWindow.Error, "Settings.Save archive was null");
			return;
		}
		
		for (var prop in settings)
		{
			if (prop != undefined && settings[prop] != undefined && settings[prop] != defaults[prop])
			{
				var entryName:String = GetFullName(prefix, prop);
				m_archive.DeleteEntry(entryName);
				m_archive.AddEntry(entryName, settings[prop]);
				//DebugWindow.Log(DebugWindow.Debug, "Settings.Save Set " + entryName + "=" + settings[prop] + " default=" + defaults[prop]);
			}
			else
			{
				m_archive.DeleteEntry(GetFullName(prefix, prop));
				//DebugWindow.Log(DebugWindow.Debug, "Settings.Save Delete " + GetFullName(prefix, prop));
			}
		}
	}
	
	public static function Load(prefix:String, defaults:Object):Object
	{
		var settings:Object = new Object();
		
		for (var prop in defaults)
		{
			if (prop != undefined)
			{
				if (m_archive != null)
				{
					settings[prop] = m_archive.FindEntry(GetFullName(prefix, prop));
				}
			}
			
			if (settings[prop] == undefined)
			{
				settings[prop] = defaults[prop];
				//DebugWindow.Log(DebugWindow.Debug, "Settings.Load Default " + GetFullName(prefix, prop) + "=" + settings[prop]);
			}
			else if (settings[prop] == defaults[prop])
			{
				if (m_archive != null)
				{
					m_archive.DeleteEntry(GetFullName(prefix, prop));
					//DebugWindow.Log(DebugWindow.Debug, "Settings.Load Delete " + GetFullName(prefix, prop));
				}
			}
			else
			{
				//DebugWindow.Log(DebugWindow.Debug, "Settings.Load Get " + GetFullName(prefix, prop) + "=" + settings[prop]);
			}
		}
		
		return settings;
	}
	
	private static function GetFullName(prefix:String, name:String):String
	{
		return prefix + Separator + name;
	}
	
	public static function GetSprintTag(settings:Object):Number
	{
		if (settings != null)
		{
			return settings[SPRINT_TAG];
		}
		
		return null;
	}
	
	public static function SetSprintTag(settings:Object, newTag:Number):Void
	{
		if (settings != null && newTag != null && newTag >= 0)
		{
			settings[SPRINT_TAG] = newTag;
		}
	}
	
	public static function GetSprintEnabled(settings:Object):Boolean
	{
		if (settings != null)
		{
			if (settings[SPRINT_ENABLED] == 1)
			{
				return true;
			}
			else
			{
				return false;
			}
		}
		
		return false;
	}
	
	public static function SetSprintEnabled(settings:Object, newEnabled:Boolean):Void
	{
		if (settings != null)
		{
			if (newEnabled == true)
			{
				settings[SPRINT_ENABLED] = 1;
			}
			else
			{
				settings[SPRINT_ENABLED] = 0;
			}
		}
	}
	
	public static function GetPetTag(settings:Object):Number
	{
		if (settings != null)
		{
			return settings[PET_TAG];
		}
		
		return null;
	}
	
	public static function SetPetTag(settings:Object, newTag:Number):Void
	{
		if (settings != null && newTag != null && newTag >= 0)
		{
			settings[PET_TAG] = newTag;
		}
	}
	
	public static function GetPetEnabled(settings:Object):Boolean
	{
		if (settings != null)
		{
			if (settings[PET_ENABLED] == 1)
			{
				return true;
			}
			else
			{
				return false;
			}
		}
		
		return false;
	}
	
	public static function SetPetEnabled(settings:Object, newEnabled:Boolean):Void
	{
		if (settings != null)
		{
			if (newEnabled == true)
			{
				settings[PET_ENABLED] = 1;
			}
			else
			{
				settings[PET_ENABLED] = 0;
			}
		}
	}
	
	public static function GetOverrideKey(settings:Object):Boolean
	{
		if (settings != null)
		{
			if (settings[OVERRIDE_KEY] == 1)
			{
				return true;
			}
			else
			{
				return false;
			}
		}
		
		return false;
	}
	
	public static function SetOverrideKey(settings:Object, newValue:Boolean):Void
	{
		if (settings != null)
		{
			if (newValue == true)
			{
				settings[OVERRIDE_KEY] = 1;
			}
			else
			{
				settings[OVERRIDE_KEY] = 0;
			}
		}
	}
	
	public static function GetSmartSprint(settings:Object):Boolean
	{
		if (settings != null)
		{
			if (settings[SMART_SPRINT] == 1)
			{
				return true;
			}
			else
			{
				return false;
			}
		}
		
		return false;
	}
	
	public static function SetSmartSprint(settings:Object, newValue:Boolean):Void
	{
		if (settings != null)
		{
			if (newValue == true)
			{
				settings[SMART_SPRINT] = 1;
			}
			else
			{
				settings[SMART_SPRINT] = 0;
			}
		}
	}
	
	public static function GetSprintInterval(settings:Object):Number
	{
		if (settings != null)
		{
			return settings[SPRINT_INTERVAL];
		}
		
		return 4;
	}
	
	public static function SetSprintInterval(settings:Object, newInterval:Number):Void
	{
		if (settings != null && newInterval != null && isNaN(newInterval) == false && newInterval >= 1 && newInterval <= 3600)
		{
			settings[SPRINT_INTERVAL] = newInterval;
		}
	}
}