import com.GameInterface.Lore;
import com.GameInterface.LoreBase;
import com.GameInterface.LoreNode;
import com.Utils.Archive;
import com.Utils.StringUtils;
import com.boosprint.Entry;
import com.boosprint.Group;
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
class com.boosprint.Entry
{
	public static var ENTRY_PREFIX:String = "ENTRY";
	public static var GROUP_PREFIX:String = "Group";
	public static var TAG_PREFIX:String = "Tag";
	public static var NAME_PREFIX:String = "Name";
	public static var SPRINT_PREFIX:String = "IsSprint";
	public static var ORDER_PREFIX:String = "Order";
	
	private var m_name:String;
	private var m_tag:Number;
	private var m_isSprint:Boolean;
	private var m_group:String;
	private var m_order:Number;
	
	public function Entry(name:String, tag:Number, isSprint:Boolean, group:String, order:Number) 
	{
		m_name = name;
		m_tag = tag;
		m_isSprint = isSprint;
		m_group = group;
		m_order = order;
	}
		
	public function GetTag():Number
	{
		return m_tag;
	}
	
	public function IsSprint():Boolean
	{
		return m_isSprint;
	}
	
	public function GetGroup():String
	{
		return m_group;
	}
	
	public function SetGroup(newGroup:String):Void
	{
		m_group = newGroup;
	}
	
	public function GetOrder():Number
	{
		return m_order;
	}
	
	public function SetOrder(newOrder:Number):Void
	{
		m_order = newOrder;
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
	
	private static function SetArchiveEntry(prefix:String, archive:Archive, key:String, value:String):Void
	{
		var keyName:String = prefix + "_" + key;
		archive.DeleteEntry(keyName);
		if (value != null && value != "null")
		{
			archive.AddEntry(keyName, value);
		}
	}
	
	private static function DeleteArchiveEntry(prefix:String, archive:Archive, key:String):Void
	{
		var keyName:String = prefix + "_" + key;
		archive.DeleteEntry(keyName);
	}
	
	public function Save(archive:Archive, entryNumber:Number):Void
	{
		var key:String = ENTRY_PREFIX + entryNumber;
		SetArchiveEntry(key, archive, TAG_PREFIX, String(m_tag));
		SetArchiveEntry(key, archive, NAME_PREFIX, m_name);		
		SetArchiveEntry(key, archive, GROUP_PREFIX, m_group);
		SetArchiveEntry(key, archive, ORDER_PREFIX, String(m_order));
		
		var sprint:String = "0";
		if (m_isSprint == true)
		{
			sprint = "1";
		}
		
		SetArchiveEntry(key, archive, SPRINT_PREFIX, sprint);
	}
	
	public static function ClearArchive(archive:Archive, entryNumber:Number):Void
	{
		var key:String = ENTRY_PREFIX + entryNumber;
		DeleteArchiveEntry(key, archive, TAG_PREFIX);
		DeleteArchiveEntry(key, archive, NAME_PREFIX);
		DeleteArchiveEntry(key, archive, GROUP_PREFIX);
		DeleteArchiveEntry(key, archive, SPRINT_PREFIX);
		DeleteArchiveEntry(key, archive, ORDER_PREFIX);
	}
	
	private static function GetArchiveEntry(prefix:String, archive:Archive, key:String, defaultValue:String):String
	{
		var keyName:String = prefix + "_" + key;
		return archive.FindEntry(keyName, defaultValue);
	}
	
	public static function FromArchive(entryNumber:Number, archive:Archive):Entry
	{
		var ret:Entry = null;
		var key:String = ENTRY_PREFIX + entryNumber;
		var tag:String = GetArchiveEntry(key, archive, TAG_PREFIX, null);
		if (tag != null)
		{
			var name:String = GetArchiveEntry(key, archive, NAME_PREFIX, null);
			var group:String = GetArchiveEntry(key, archive, GROUP_PREFIX, null);
			var order:String = GetArchiveEntry(key, archive, ORDER_PREFIX, "-1");
			var sprint:String = GetArchiveEntry(key, archive, SPRINT_PREFIX, "0");
			var isSprint:Boolean = false;
			if (sprint == "1")
			{
				isSprint = true;
			}
			
			ret = new Entry(name, Number(tag), isSprint, group, Number(order));
		}
		
		return ret;
	}

	public static function GetNextOrder(groupID:String, entries:Object):Number
	{
		var lastCount:Number = 0;
		for (var indx:String in entries)
		{
			var thisEntry:Entry = entries[indx];
			if (thisEntry != null && thisEntry.GetGroup() == groupID)
			{
				var thisCount:Number = thisEntry.GetOrder();
				if (thisCount > lastCount)
				{
					lastCount = thisCount;
				}
			}
		}
		
		lastCount = lastCount + 1;
		return lastCount;
	}
	
	public static function ReorderEntries(groupID:String, entries:Object):Void
	{
		var ordered:Array = GetOrderedEntries(groupID, entries);
		if (ordered != null)
		{
			for (var indx:Number = 0; indx < ordered.length; ++indx)
			{
				var thisEntry:Entry = ordered[indx];
				thisEntry.SetOrder(indx + 1);
			}
		}
	}
	
	public static function GetOrderedEntries(groupID:String, entries:Object):Array
	{
		var tempEntries:Array = new Array();
		for (var indx:String in entries)
		{
			var thisEntry:Entry = entries[indx];
			if (thisEntry != null && thisEntry.GetGroup() == groupID)
			{
				var tempObj:Object = new Object();
				tempObj["order"] = thisEntry.GetOrder();
				tempObj["entry"] = thisEntry;
				tempEntries.push(tempObj);
			}
		}
		
		tempEntries.sortOn("order", Array.NUMERIC);
		
		var ret:Array = new Array();
		for (var indx:Number = 0; indx < tempEntries.length; ++indx)
		{
			ret.push(tempEntries[indx]["entry"]);
		}
		
		return ret;
	}
	
	public static function FindOrderBelow(order:Number, groupID:String, entries:Object):Entry
	{
		var ret:Entry = null;
		var lastCount:Number = 0;
		for (var indx:String in entries)
		{
			var thisEntry:Entry = entries[indx];
			if (thisEntry != null && thisEntry.GetGroup() == groupID)
			{
				var thisCount:Number = thisEntry.GetOrder();
				if (thisCount > lastCount && thisCount < order)
				{
					lastCount = thisCount;
					ret = thisEntry;
				}
			}
		}
		
		return ret;
	}
	
	public static function FindOrderAbove(order:Number, groupID:String, entries:Object):Entry
	{
		var ret:Entry = null;
		var lastCount:Number = 999999;
		for (var indx:String in entries)
		{
			var thisEntry:Entry = entries[indx];
			if (thisEntry != null && thisEntry.GetGroup() == groupID)
			{
				var thisCount:Number = thisEntry.GetOrder();
				if (thisCount < lastCount && thisCount > order)
				{
					lastCount = thisCount;
					ret = thisEntry;
				}
			}
		}
		
		return ret;
	}
	
	public static function SwapOrders(entry1:Entry, entry2:Entry):Void
	{
		if (entry1 != null && entry2 != null && entry1.GetGroup() == entry2.GetGroup())
		{
			var temp:Number = entry1.GetOrder();
			entry1.SetOrder(entry2.GetOrder());
			entry2.SetOrder(temp);
		}
	}

	public static function SetUnkownSprints(group:String, entries:Object):Void
	{
		var nodes:Array = GetSprintData();
		for (var indx:Number = 0; indx < nodes.length; ++indx)
		{
			var node:LoreNode = LoreNode(nodes[indx]);
			if (node != null && entries[node.m_Id] == null)
			{
				var newEntry:Entry = new Entry(node.m_Name, node.m_Id, true, group, Entry.GetNextOrder(group, entries));
				entries[node.m_Id] = newEntry;
			}
		}
	}
	
	public static function IsGroupEmpty(group:String, entries:Object):Boolean
	{
		for (var indx in entries)
		{
			var thisEntry:Entry = entries[indx];
			if (thisEntry != null && thisEntry.GetGroup() == group)
			{
				return false;
			}
		}
		
		return true;
	}
	
	public static function SetUnkownPets(group:String, entries:Object):Void
	{
		var nodes:Array = GetPetData();
		for (var indx:Number = 0; indx < nodes.length; ++indx)
		{
			var node:LoreNode = LoreNode(nodes[indx]);
			if (node != null && entries[node.m_Id] == null)
			{
				var newEntry:Entry = new Entry(node.m_Name, node.m_Id, false, group, Entry.GetNextOrder(group, entries));
				entries[node.m_Id] = newEntry;
			}
		}
	}
	
	public static function GetSprintFromTag(sprintTag:Number):String
	{
		var ret:String = "None";
		
		if (sprintTag != null)
		{
			var nodes:Array = GetSprintData();
			for (var indx:Number = 0; indx < nodes.length; ++indx)
			{
				var node:LoreNode = LoreNode(nodes[indx]);
				if (node != null && node.m_Id == sprintTag)
				{
					ret = node.m_Name;
					break;
				}
			}
		}
		
		return ret;
	}
	
	public static function GetTagFromSprintName(sprintName:String):Number
	{
		var ret:Number = null;
		if (sprintName != null)
		{
			var nodes:Array = GetSprintData();
			for (var indx:Number = 0; indx < nodes.length; ++indx)
			{
				var node:LoreNode = LoreNode(nodes[indx]);
				if (node != null && node.m_Name == sprintName)
				{
					ret = node.m_Id;
					break;
				}
			}
		}
		
		return ret;
	}
	
	private static function GetSprintData():Array
	{
		var allNodes:Array = Lore.GetMountTree().m_Children;
		allNodes.sortOn("m_Name");
		var ownedNodes:Array = new Array();
		for (var i = 0; i < allNodes.length; i++)
		{
			//if (Utils.GetGameTweak("HideMount_" + allNodes[i].m_Id) == 0)
			//{
				if (!LoreBase.IsLocked(allNodes[i].m_Id))
				{
					ownedNodes.push(allNodes[i]);
				}
			//}
		}
		
		return ownedNodes;
	}
	
	public static function GetPetFromTag(sprintTag:Number):String
	{
		var ret:String = "None";
		
		if (sprintTag != null)
		{
			var nodes:Array = GetPetData();
			for (var indx:Number = 0; indx < nodes.length; ++indx)
			{
				var node:LoreNode = LoreNode(nodes[indx]);
				if (node != null && node.m_Id == sprintTag)
				{
					ret = node.m_Name;
					break;
				}
			}
		}
		
		return ret;
	}
	
	public static function GetTagFromPetName(sprintName:String):Number
	{
		var ret:Number = null;
		if (sprintName != null)
		{
			var nodes:Array = GetPetData();
			for (var indx:Number = 0; indx < nodes.length; ++indx)
			{
				var node:LoreNode = LoreNode(nodes[indx]);
				if (node != null && node.m_Name == sprintName)
				{
					ret = node.m_Id;
					break;
				}
			}
		}
		
		return ret;
	}
	
	private static function GetPetData():Array
	{
		var allNodes:Array = Lore.GetPetTree().m_Children;
		allNodes.sortOn("m_Name");
		var ownedNodes:Array = new Array();
		for (var i = 0; i < allNodes.length; i++)
		{
			if (!LoreBase.IsLocked(allNodes[i].m_Id))
			{
				ownedNodes.push(allNodes[i]);
			}
		}
		
		return ownedNodes;
	}
}