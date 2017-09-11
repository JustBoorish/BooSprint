import com.Utils.Archive;
import com.Utils.Colors;
import com.Utils.StringUtils;
import com.boosprint.Group;
import com.boosprintcommon.Colours;
/**
 * There is no copyright on this code
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
 * associated documentation files (the "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is furnished to do so.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
 * LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
 * NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 * 
 * Author: Boorish
 */
class com.boosprint.Group
{
	public static var GROUP_PREFIX:String = "Group";
	public static var ID_PREFIX:String = "ID";
	public static var NAME_PREFIX:String = "Name";
	public static var COLOUR_PREFIX:String = "Colour";
	public static var HIDDEN_PREFIX:String = "Hidden";
	
	private var m_id:String;
	private var m_name:String;
	private var m_colourName:String;
	private var m_hidden:Boolean;

	public function Group(id:String, name:String, colourName:String, hidden:Boolean)
	{
		m_id = id;
		m_colourName = colourName;
		m_hidden = hidden;
		SetName(name);
	}
	
	public static function FindGroupWithID(groups:Array, id:String):Group
	{
		if (groups != null)
		{
			for (var indx:Number = 0; indx < groups.length; ++indx)
			{
				var thisGroup:Group = groups[indx];
				if (thisGroup != null && thisGroup.GetID() == id)
				{
					return thisGroup;
				}
			}
		}
		
		return null;
	}

	public static function GetNextID(groups:Array):String
	{
		var lastCount:Number = 0;
		for (var indx:Number = 0; indx < groups.length; ++indx)
		{
			var thisGroup:Group = groups[indx];
			if (thisGroup != null)
			{
				var thisID:String = thisGroup.GetID();
				var thisCount:Number = Number(thisID.substring(1, thisID.length));
				if (thisCount > lastCount)
				{
					lastCount = thisCount;
				}
			}
		}
		
		lastCount = lastCount + 1;
		return "#" + lastCount;
	}
	
	public function GetID():String
	{
		return m_id;
	}
	
	public function IsHidden():Boolean
	{
		return m_hidden;
	}
	
	public function SetHidden(isHidden:Boolean):Void
	{
		m_hidden = isHidden;
	}
	
	public function GetName():String
	{
		return m_name;
	}
	
	public function SetName(newName:String):Void
	{
		if (newName == null)
		{
			m_name = "";
		}
		else
		{
			m_name = StringUtils.Strip(newName);
		}
	}
	
	public function GetColourName():String
	{
		return m_colourName;
	}
	
	public function SetColourName(newName:String):Void
	{
		m_colourName = newName;
	}
	
	public function Save(groupPrefix:String, archive:Archive, groupNumber:Number):Void
	{
		var prefix:String = groupPrefix + groupNumber;
		SetArchiveEntry(prefix, archive, Group.ID_PREFIX, m_id);
		SetArchiveEntry(prefix, archive, Group.NAME_PREFIX, m_name);
		SetArchiveEntry(prefix, archive, Group.COLOUR_PREFIX, m_colourName);
		
		var hidden:String = "0";
		if (m_hidden == true)
		{
			hidden = "1";
		}
		
		SetArchiveEntry(prefix, archive, Group.HIDDEN_PREFIX, hidden);
	}
	
	public static function FromArchive(groupPrefix:String, archive:Archive, groupNumber:Number):Group
	{
		var ret:Group = null;
		var prefix:String = groupPrefix + groupNumber;
		var id:String = GetArchiveEntry(prefix, archive, Group.ID_PREFIX, null);
		if (id != null)
		{
			var name:String = GetArchiveEntry(prefix, archive, Group.NAME_PREFIX, null);
			var colourName:String = GetArchiveEntry(prefix, archive, Group.COLOUR_PREFIX, null);
			if (colourName == "Gray") colourName = Colours.GREY;
			var hidden:String = GetArchiveEntry(prefix, archive, Group.HIDDEN_PREFIX, "0");
			ret = new Group(id, name, colourName, hidden == "1");
		}
		
		return ret;
	}

	public static function ClearArchive(groupPrefix:String, archive:Archive, groupNumber:Number):Void
	{
		var prefix:String = groupPrefix + groupNumber;
		DeleteArchiveEntry(prefix, archive, Group.ID_PREFIX);
		DeleteArchiveEntry(prefix, archive, Group.NAME_PREFIX);
		DeleteArchiveEntry(prefix, archive, Group.COLOUR_PREFIX);
		DeleteArchiveEntry(prefix, archive, Group.HIDDEN_PREFIX);
	}

	private static function DeleteArchiveEntry(prefix:String, archive:Archive, key:String):Void
	{
		var keyName:String = prefix + "_" + key;
		archive.DeleteEntry(keyName);
	}
	
	private static function SetArchiveEntry(prefix:String, archive:Archive, key:String, value:String):Void
	{
		var keyName:String = prefix + "_" + key;
		archive.DeleteEntry(keyName);
		if (value != null && value != "null")
		{
			archive.AddEntry(keyName, value);
		}
	}
	
	private static function GetArchiveEntry(prefix:String, archive:Archive, key:String, defaultValue:String):String
	{
		var keyName:String = prefix + "_" + key;
		return archive.FindEntry(keyName, defaultValue);
	}
}