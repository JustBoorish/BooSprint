import com.Utils.StringUtils;
import com.boosprint.Entry;
import com.boosprint.Group;
import com.boosprint.ChangeGroupDialog;
import com.boosprint.EditGroupDialog;
import com.boosprintcommon.Colours;
import com.boosprintcommon.DebugWindow;
import com.boosprintcommon.ITabPane;
import com.boosprintcommon.InfoWindow;
import com.boosprintcommon.OKDialog;
import com.boosprintcommon.PopupMenu;
import com.boosprintcommon.ScrollPane;
import com.boosprintcommon.TreePanel;
import com.boosprintcommon.YesNoDialog;
import mx.utils.Delegate;
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
class com.boosprint.EntryList implements ITabPane
{
	private var m_addonMC:MovieClip;
	private var m_parent:MovieClip;
	private var m_name:String;
	private var m_settings:Object;
	private var m_groups:Array;
	private var m_entries:Object;
	private var m_applySprint:Function;
	private var m_applyPet:Function;
	private var m_scrollPane:ScrollPane;
	private var m_buildTree:TreePanel;
	private var m_itemPopup:PopupMenu;
	private var m_groupPopup:PopupMenu;
	private var m_currentGroup:Group;
	private var m_currentEntry:Entry;
	private var m_yesNoDialog:YesNoDialog;
	private var m_okDialog:OKDialog;
	private var m_editGroupDialog:EditGroupDialog;
	private var m_changeGroupDialog:ChangeGroupDialog
	private var m_forceRedraw:Boolean;
	private var m_parentWidth:Number;
	private var m_parentHeight:Number;
	
	public function EntryList(name:String, groups:Array, entries:Object, settings:Object, applySprint:Function, applyPet:Function)
	{
		m_name = name;
		m_groups = groups;
		m_entries = entries;
		m_settings = settings;
		m_applySprint = applySprint;
		m_applyPet = applyPet;
		m_forceRedraw = false;
	}

	public function CreatePane(addonMC:MovieClip, parent:MovieClip, name:String, x:Number, y:Number, width:Number, height:Number):Void
	{
		m_parent = parent;
		m_name = name;
		m_addonMC = addonMC;
		m_parentWidth = parent._width;
		m_parentHeight = parent._height;
		m_scrollPane = new ScrollPane(m_parent, m_name + "Scroll", x, y, width, height, null, m_parentHeight * 0.1);
		
		m_itemPopup = new PopupMenu(m_addonMC, "ItemPopup", 6);
		m_itemPopup.AddItem("Use", Delegate.create(this, ApplyEntry));
		m_itemPopup.AddSeparator();
		m_itemPopup.AddItem("Change group", Delegate.create(this, ChangeGroup));
		m_itemPopup.AddItem("Move Up", Delegate.create(this, MoveEntryUp));
		m_itemPopup.AddItem("Move Down", Delegate.create(this, MoveEntryDown));
		m_itemPopup.Rebuild();
		m_itemPopup.SetCoords(Stage.width / 2, Stage.height / 2);
		
		m_groupPopup = new PopupMenu(m_addonMC, "GroupPopup", 6);
		m_groupPopup.AddItem("Edit", Delegate.create(this, EditGroup));
		m_groupPopup.AddSeparator();
		m_groupPopup.AddItem("Add new group above", Delegate.create(this, AddGroupAbove));
		m_groupPopup.AddItem("Add new group below", Delegate.create(this, AddGroupBelow));
		m_groupPopup.AddSeparator();
		m_groupPopup.AddItem("Delete", Delegate.create(this, DeleteGroup));
		m_groupPopup.Rebuild();
		m_groupPopup.SetCoords(Stage.width / 2, Stage.height / 2);
		
		DrawList();
	}
	
	public function SetVisible(visible:Boolean):Void
	{
		m_scrollPane.SetVisible(visible);
		if (visible == true && m_forceRedraw == true)
		{
			m_forceRedraw = false;
			DrawList();
		}
	}
	
	public function GetVisible():Boolean
	{
		return m_scrollPane.GetVisible();
	}
	
	public function Save():Void
	{
		
	}
	
	public function StartDrag():Void
	{
		m_itemPopup.SetVisible(false);
		m_groupPopup.SetVisible(false);
	}
	
	public function StopDrag():Void
	{	
	}

	public function ForceRedraw():Void
	{
		m_forceRedraw = true;
	}

	public function DrawList():Void
	{
		var openSubMenus:Object = new Object();
		if (m_buildTree != null)
		{
			for (var indx:Number = 0; indx < m_buildTree.GetNumSubMenus(); ++indx)
			{
				if (m_buildTree.IsSubMenuOpen(indx))
				{
					openSubMenus[m_buildTree.GetSubMenuName(indx)] = true;
				}
			}
			
			m_buildTree.Unload();
		}
		
		var margin:Number = 3;
		var callback:Function = Delegate.create(this, function(a:TreePanel) { this.m_scrollPane.Resize(a.GetHeight()); } );
		m_buildTree = new TreePanel(m_scrollPane.GetMovieClip(), m_name + "Tree", margin, null, null, callback, Delegate.create(this, ContextMenu));
		for (var indx:Number = 0; indx < m_groups.length; ++indx)
		{
			var thisGroup:Group = m_groups[indx];
			if (thisGroup != null)
			{
				//DebugWindow.Log(DebugWindow.Info, "Adding group " + thisGroup.GetName());
				var colours:Array = Colours.GetColourArray(thisGroup.GetColourName());
				var subTree:TreePanel = new TreePanel(m_buildTree.GetMovieClip(), "subTree" + thisGroup.GetName(), margin, colours[0], colours[1], callback, Delegate.create(this, ContextMenu));
				EntrySubMenu(subTree, thisGroup.GetID());
				m_buildTree.AddSubMenu(thisGroup.GetName(), thisGroup.GetID(), subTree, colours[0], colours[1]);
				//DebugWindow.Log(DebugWindow.Info, "Added group " + thisGroup.GetName());
			}
		}
		
		m_buildTree.Rebuild();
		m_buildTree.SetCoords(0, 0);
		
		m_scrollPane.SetContent(m_buildTree.GetMovieClip(), m_buildTree.GetHeight());
		
		for (var indx:Number = 0; indx < m_buildTree.GetNumSubMenus(); ++indx)
		{
			if (openSubMenus[m_buildTree.GetSubMenuName(indx)] == true)
			{
				m_buildTree.ToggleSubMenu(indx);
			}
		}
		
		m_buildTree.Layout();
		m_scrollPane.SetVisible(true);		
	}
	
	public function EntrySubMenu(subTree:TreePanel, groupID:String):Void
	{
		var sortedEntrys:Array = Entry.GetOrderedEntries(groupID, m_entries);
		for (var indx:Number = 0; indx < sortedEntrys.length; ++indx)
		{
			var thisEntry:Entry = sortedEntrys[indx];
			if (thisEntry != null && thisEntry.GetGroup() == groupID)
			{
				subTree.AddItem(thisEntry.GetName(), Delegate.create(this, ApplyEntry), String(thisEntry.GetTag()));
			}
		}
	}
	
	private function ContextMenu(id:String, isGroup:Boolean):Void
	{
		if (isGroup != true)
		{
			if (m_groupPopup != null)
			{
				m_groupPopup.SetVisible(false);
			}
			
			if (m_itemPopup != null)
			{
				UnloadDialogs();
				m_itemPopup.SetUserData(id);
				m_itemPopup.SetCoords(_root._xmouse, _root._ymouse);
				m_itemPopup.SetVisible(true);
			}
		}
		else
		{
			if (m_itemPopup != null)
			{
				m_itemPopup.SetVisible(false);
			}

			if (m_groupPopup != null)
			{
				UnloadDialogs();
				m_groupPopup.SetUserData(id);
				m_groupPopup.SetCoords(_root._xmouse, _root._ymouse);
				m_groupPopup.SetVisible(true);
			}
		}
	}

	public function UnloadDialogs():Void
	{
		if (m_yesNoDialog != null)
		{
			m_yesNoDialog.Unload();
			m_yesNoDialog = null;
		}
		
		if (m_okDialog != null)
		{
			m_okDialog.Unload();
			m_okDialog = null;
		}
		
		if (m_editGroupDialog != null)
		{
			m_editGroupDialog.Unload();
			m_editGroupDialog = null;
		}
		
		if (m_changeGroupDialog != null)
		{
			m_changeGroupDialog.Unload();
			m_changeGroupDialog = null;
		}
	}
	
	private function ApplyEntry(buildID:String):Void
	{
		var thisEntry:Entry = m_entries[buildID];
		if (thisEntry != null)
		{
			if (thisEntry.IsSprint() == true)
			{
				if (m_applySprint != null)
				{
					m_applySprint(thisEntry.GetTag());
				}
			}
			else
			{
				if (m_applyPet != null)
				{
					m_applyPet(thisEntry.GetTag());
				}
			}
		}
	}
	
	private function MoveEntryUp(buildID:String):Void
	{
		var thisEntry:Entry = m_entries[buildID];
		if (thisEntry != null)
		{
			var swapEntry:Entry = Entry.FindOrderBelow(thisEntry.GetOrder(), thisEntry.GetGroup(), m_entries);
			if (swapEntry != null)
			{
				Entry.SwapOrders(thisEntry, swapEntry);
				DrawList();
			}
			else
			{
				InfoWindow.LogError("Cannot move the top build in a group upwards");				
			}
		}
	}
	
	private function MoveEntryDown(buildID:String):Void
	{
		var thisEntry:Entry = m_entries[buildID];
		if (thisEntry != null)
		{
			var swapEntry:Entry = Entry.FindOrderAbove(thisEntry.GetOrder(), thisEntry.GetGroup(), m_entries);
			if (swapEntry != null)
			{
				Entry.SwapOrders(thisEntry, swapEntry);
				DrawList();
			}
			else
			{
				InfoWindow.LogError("Cannot move the top build in a group upwards");				
			}
		}
	}
	
	private function ChangeGroup(outfitID:String):Void
	{
		m_currentEntry = m_entries[outfitID];
		if (m_currentEntry != null)
		{
			m_currentGroup = FindGroupByID(m_currentEntry.GetGroup());
			if (m_currentGroup != null)
			{
				UnloadDialogs();
				
				m_changeGroupDialog = new ChangeGroupDialog("ChangeGroup", m_parent, m_addonMC, m_parentWidth, m_parentHeight, m_currentGroup.GetName(), m_groups);
				m_changeGroupDialog.Show(Delegate.create(this, ChangeGroupCB));
			}
		}
	}
	
	private function ChangeGroupCB(newName:String):Void
	{
		if (newName != null)
		{
			var nameValid:Boolean = IsValidName(newName, "group");
			if (nameValid == true && newName != "" && m_currentEntry != null && m_currentGroup != null && newName != m_currentGroup.GetName())
			{
				var newGroup:Group = null;
				for (var indx:Number = 0; indx < m_groups.length; ++indx)
				{
					if (m_groups[indx] != null && m_groups[indx].GetName() == newName)
					{
						newGroup = m_groups[indx];
						break;
					}
				}
				
				if (newGroup == null)
				{
					InfoWindow.LogError("Failed to find group " + newName);
				}
				else
				{
					var duplicateFound:Boolean = false;
					for (var indx:String in m_entries)
					{
						var thisEntry:Entry = m_entries[indx];
						if (thisEntry != null && thisEntry.GetName() == m_currentEntry.GetName() && newGroup.GetID() == thisEntry.GetGroup())
						{
							duplicateFound = true;
						}
					}
					
					if (duplicateFound == false)
					{
						m_currentEntry.SetOrder(Entry.GetNextOrder(newGroup.GetID(), m_entries));
						m_currentEntry.SetGroup(newGroup.GetID());
						DrawList();
					}
					else
					{
						InfoWindow.LogError("Update outfit group failed.  Name already exists");				
					}
				}
			}
		}
		
		m_currentGroup = null;
		m_currentEntry = null;
	}
	
	private function DeleteGroup(groupID:String):Void
	{
		m_currentGroup = FindGroupByID(groupID);
		if (m_currentGroup != null)
		{
			UnloadDialogs();
			if (m_groups.length > 1)
			{
				if (IsGroupEmpty(m_currentGroup) == true)
				{
					var thisGroup:Group = null;
					var toDelete:Number = -1;
					for (var indx:Number = 0; indx < m_groups.length; ++indx)
					{
						thisGroup = m_groups[indx];
						if (thisGroup != null && thisGroup.GetID() == m_currentGroup.GetID())
						{
							toDelete = indx;
							break;
						}
					}
					
					if (toDelete != -1)
					{
						m_groups.splice(toDelete, 1);
						DrawList();
					}
				}
				else
				{
					m_okDialog = new OKDialog("DeleteGroup", m_parent, m_parentWidth, m_parentHeight, "You cannot delete a", "group with entries", "");
					m_okDialog.Show();
				}
			}
			else
			{
				m_okDialog = new OKDialog("DeleteGroup", m_parent, m_parentWidth, m_parentHeight, "You cannot delete the", "final group", "");
				m_okDialog.Show();
			}
		}
		
		m_currentGroup = null;
	}
	
	private function IsGroupEmpty(thisGroup:Group):Boolean
	{
		for (var indx in m_entries)
		{
			var thisEntry:Entry = m_entries[indx];
			if (thisEntry != null && thisEntry.GetGroup() == thisGroup.GetID())
			{
				return false;
			}
		}
		
		return true;
	}
	
	private function EditGroup(groupID:String):Void
	{
		m_currentGroup = FindGroupByID(groupID);
		if (m_currentGroup != null)
		{
			UnloadDialogs();
			m_editGroupDialog = new EditGroupDialog("EditGroup", m_parent, m_parentWidth, m_parentHeight, m_currentGroup.GetName(), m_currentGroup.GetColourName(), m_currentGroup.IsHidden());
			m_editGroupDialog.Show(Delegate.create(this, EditGroupCB));
		}
	}
	
	private function EditGroupCB(newName:String, newColour:String, isHidden:Boolean):Void
	{
		if (newName != null)
		{
			var nameValid:Boolean = IsValidName(newName, "group");
			if (nameValid == true && m_currentGroup != null && newColour != null)
			{
				var duplicateFound:Boolean = false;
				for (var indx:Number = 0; indx < m_groups.length; ++indx)
				{
					var tempGroup:Group = m_groups[indx];
					if (tempGroup != null && tempGroup.GetID() != m_currentGroup.GetID() && tempGroup.GetName() == newName)
					{
						duplicateFound = true;
						break;
					}
				}

				if (duplicateFound == false)
				{
					m_currentGroup.SetName(newName);
					m_currentGroup.SetColourName(newColour);
					m_currentGroup.SetHidden(isHidden);
					DrawList();
				}
				else
				{
					InfoWindow.LogError("Edit group failed.  Name already exists");				
				}
			}
		}
		
		m_currentGroup = null;
	}
	
	private function AddGroupAbove(groupID:String):Void
	{
		m_currentGroup = FindGroupByID(groupID);
		if (m_currentGroup != null)
		{
			UnloadDialogs();
			m_editGroupDialog = new EditGroupDialog("AddGroupAbove", m_parent, m_parentWidth, m_parentHeight, "", Colours.GetDefaultColourName());
			m_editGroupDialog.Show(Delegate.create(this, AddGroupAboveCB));
		}
	}
	
	private function AddGroupAboveCB(newName:String, newColour:String):Void
	{
		if (newName != null)
		{
			var nameValid:Boolean = IsValidName(newName, "group");
			if (nameValid == true && m_currentGroup != null)
			{
				var duplicateFound:Boolean = false;
				for (var indx:Number = 0; indx < m_groups.length; ++indx)
				{
					var tempGroup:Group = m_groups[indx];
					if (tempGroup != null && tempGroup.GetName() == newName)
					{
						duplicateFound = true;
						break;
					}
				}

				if (duplicateFound == false)
				{
					var newID:String = Group.GetNextID(m_groups);
					var newGroup:Group = new Group(newID, newName, newColour);
					var indx:Number = FindGroupIndex(m_currentGroup.GetID());
					m_groups.splice(indx, 0, newGroup);
					DrawList();
				}
				else
				{
					InfoWindow.LogError("Add group failed.  Name already exists");				
				}
			}
		}
		
		m_currentGroup = null;
	}
	
	private function AddGroupBelow(groupID:String):Void
	{
		m_currentGroup = FindGroupByID(groupID);
		if (m_currentGroup != null)
		{
			UnloadDialogs();
			m_editGroupDialog = new EditGroupDialog("AddGroupAbove", m_parent, m_parentWidth, m_parentHeight, "", Colours.GetDefaultColourName());
			m_editGroupDialog.Show(Delegate.create(this, AddGroupBelowCB));
		}
	}
	
	private function AddGroupBelowCB(newName:String, newColour:String):Void
	{
		if (newName != null)
		{
			var nameValid:Boolean = IsValidName(newName, "group");
			if (nameValid == true && m_currentGroup != null)
			{
				var duplicateFound:Boolean = false;
				for (var indx:Number = 0; indx < m_groups.length; ++indx)
				{
					var tempGroup:Group = m_groups[indx];
					if (tempGroup != null && tempGroup.GetName() == newName)
					{
						duplicateFound = true;
						break;
					}
				}

				if (duplicateFound == false)
				{
					var newID:String = Group.GetNextID(m_groups);
					var newGroup:Group = new Group(newID, newName, newColour);
					var indx:Number = FindGroupIndex(m_currentGroup.GetID());
					m_groups.splice(indx + 1, 0, newGroup);
					DrawList();
				}
				else
				{
					InfoWindow.LogError("Add group failed.  Name already exists");				
				}
			}
		}
		
		m_currentGroup = null;
	}
	
	private function FindGroupByID(groupID:String):Group
	{
		var indx:Number = FindGroupIndex(groupID);
		if (indx > -1)
		{
			return m_groups[indx];
		}
		
		return null;
	}
	
	private function FindGroupIndex(groupID:String):Number
	{
		for (var indx:Number = 0; indx < m_groups.length; ++indx)
		{
			var thisGroup:Group = m_groups[indx];
			if (thisGroup != null && thisGroup.GetID() == groupID)
			{
				return indx;
			}
		}
		
		return -1;
	}
	
	private function IsValidName(newName:String, nameType:String):Boolean
	{
		var valid:Boolean = true;
		
		if (newName == null || StringUtils.Strip(newName) == "")
		{
			InfoWindow.LogError("Cannot have a blank " + nameType + " name");
			return false;
		}
		
		if (IsNameGotChar(newName, nameType, "%") == true)
		{
			valid = false;
		}
		if (IsNameGotChar(newName, nameType, "~") == true)
		{
			valid = false;
		}
		if (IsNameGotChar(newName, nameType, "|") == true)
		{
			valid = false;
		}
		
		return valid;
	}
	
	private function IsNameGotChar(newName:String, nameType:String, charType:String):Boolean
	{
		if (newName.indexOf(charType) != -1)
		{
			InfoWindow.LogError("Cannot have character " + charType + " in " + nameType + " names");
			return true;
		}
		
		return false;
	}
}