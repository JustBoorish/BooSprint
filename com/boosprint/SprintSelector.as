import com.Utils.Colors;
import com.boocommon.MenuPanel;
import com.boosprint.Group;
import com.boosprint.Entry;
import mx.utils.Delegate;
import org.sitedaniel.utils.Proxy;
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
class com.boosprint.SprintSelector
{
	private var m_parent:MovieClip;
	private var m_frame:MovieClip;
	private var m_name:String;
	private var m_menu:MenuPanel;
	private var m_sprintCallback:Function;
	private var m_petCallback:Function;
	private var m_groups:Array;
	private var m_entries:Object;
	
	public function SprintSelector(parent:MovieClip, name:String, groups:Array, entries:Object, sprintCallback:Function, petCallback:Function) 
	{
		m_parent = parent;
		m_name = name;
		m_sprintCallback = sprintCallback;
		m_petCallback = petCallback;
		m_groups = groups;
		m_entries = entries;
		
		m_frame = parent.createEmptyMovieClip(name + "Frame", parent.getNextHighestDepth());
		BuildMenu();
	}
	
	public function Show(x:Number, bottomY:Number, topY:Number):Void
	{
		var pt:Object = m_menu.GetDimensions(x, bottomY, true, 0, 0, Stage.width, Stage.height);
		if (pt.maxY > Stage.height)
		{
			m_menu.GetDimensions(x, topY - (pt.maxY - pt.y) - 1, true, 0, 0, Stage.width, Stage.height);
		}
		m_menu.Rebuild();
		m_menu.RebuildSubmenus();
		m_menu.SetVisible(true);
	}
	
	public function GetVisible():Boolean
	{
		return m_menu.GetVisible();
	}
	
	public function Unload()
	{
		m_frame._visible = false;
		m_frame.removeMovieClip();
	}
	
	private function BuildMenu():Void
	{
		m_menu = new MenuPanel(m_frame, "SprintsAndPets", 4);
		var singleGroup:Boolean = IsSingleGroup();

		for (var indx:Number = 0; indx < m_groups.length; ++indx)
		{
			var thisGroup:Group = m_groups[indx];
			if (thisGroup != null && thisGroup.IsHidden() != true)
			{
				var colours:Array = Group.GetColourArray(thisGroup.GetColourName());
				if (singleGroup == true)
				{
					BuildSingleMenu(thisGroup.GetID(), colours, m_menu);
				}
				else
				{
					var subMenu:MenuPanel = BuildSubMenu(thisGroup.GetID(), colours);
					if (subMenu != null)
					{
						m_menu.AddSubMenu(thisGroup.GetName(), subMenu, colours[0], colours[1]);
					}
				}
			}
		}
		
		m_menu.SetVisible(false);
	}
	
	private function BuildSubMenu(groupID:String, colours:Array):MenuPanel
	{
		var subMenu:MenuPanel = null;
		var sortedEntrys:Array = Entry.GetOrderedEntries(groupID, m_entries);
		
		if (sortedEntrys.length > 0)
		{
			subMenu = new MenuPanel(m_frame, m_name + groupID, 4);
			for (var indx:Number = 0; indx < sortedEntrys.length; ++indx)
			{
				var thisEntry:Entry = sortedEntrys[indx];
				if (thisEntry != null && thisEntry.GetGroup() == groupID)
				{
					subMenu.AddItem(thisEntry.GetName(), Proxy.create(this, EntryCallback, thisEntry.GetTag(), thisEntry.IsSprint()), colours[0], colours[1]);
				}
			}
		}
		
		return subMenu;
	}
	
	private function BuildSingleMenu(groupID:String, colours:Array, menu:MenuPanel):Void
	{
		var sortedEntrys:Array = Entry.GetOrderedEntries(groupID, m_entries);
		
		if (sortedEntrys.length > 0)
		{
			for (var indx:Number = 0; indx < sortedEntrys.length; ++indx)
			{
				var thisEntry:Entry = sortedEntrys[indx];
				if (thisEntry != null && thisEntry.GetGroup() == groupID)
				{
					menu.AddItem(thisEntry.GetName(), Proxy.create(this, EntryCallback, thisEntry.GetTag(), thisEntry.IsSprint()), colours[0], colours[1]);
				}
			}
		}
	}
	
	private function IsSingleGroup():Boolean
	{
		var groups:Object = new Object();
		for (var indx:String in m_entries)
		{
			var thisEntry:Entry = m_entries[indx];
			groups[thisEntry.GetGroup()] = 1;
		}

		var groupCount:Number = 0;
		for (var indx:Number = 0; indx < m_groups.length; ++indx)
		{
			var thisGroup:Group = m_groups[indx];
			if (thisGroup != null && groups[thisGroup.GetID()] != null && thisGroup.IsHidden() != true)
			{
				++groupCount;
			}
		}
		
		return groupCount < 2;
	}
	
	private function EntryCallback(tag:Number, isSprint:Boolean):Void
	{
		m_menu.SetVisible(false);
		if (tag != null)
		{
			if (isSprint == true)
			{
				if (m_sprintCallback != null)
				{
					m_sprintCallback(tag);
				}
			}
			else
			{
				if (m_petCallback != null)
				{
					m_petCallback(tag);
				}
			}
		}
	}	
}