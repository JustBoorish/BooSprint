import com.boosprint.MenuPanel;
import org.sitedaniel.utils.Proxy;
import mx.utils.Delegate;
import com.GameInterface.Game.Character;
import com.GameInterface.Lore;
import com.GameInterface.LoreBase;
import com.GameInterface.LoreNode;
import com.GameInterface.Utils;
import com.Utils.Colors;
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
	private var m_petsEnabled:Boolean;
	
	public function SprintSelector(parent:MovieClip, name:String, sprintCallback:Function, petCallback:Function, petsEnabled:Boolean) 
	{
		m_parent = parent;
		m_name = name;
		m_sprintCallback = sprintCallback;
		m_petCallback = petCallback;
		m_petsEnabled = petsEnabled;
		
		m_frame = parent.createEmptyMovieClip(name + "Frame", parent.getNextHighestDepth());
		BuildMenu();
	}
	
	public function Show(x:Number, y:Number):Void
	{
		var pt:Object = m_menu.GetDimensions(x, y, true, 0, 0, Stage.width, Stage.height);
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
		m_menu = new MenuPanel(m_frame, "MountsAndPets", 4);

		var parentMenu:MenuPanel = m_menu;
		if (m_petsEnabled == true)
		{
			parentMenu = new MenuPanel(m_frame, "Sprint", 4);
			m_menu.AddSubMenu("Sprint", parentMenu, Colors.e_ColorPassiveSpellHighlight, Colors.e_ColorPassiveSpellBackground);
		}
		
		var nodes:Array = GetSprintData();
		for (var indx:Number = 0; indx < nodes.length; ++indx)
		{
			var thisNode:LoreNode = nodes[indx];
			if (thisNode != null)
			{
				parentMenu.AddItem(thisNode.m_Name, Delegate.create(this, SprintCallback), Colors.e_ColorPassiveSpellHighlight, Colors.e_ColorPassiveSpellBackground);
			}
		}
		
		if (m_petsEnabled == true)
		{
			var petMenu:MenuPanel = new MenuPanel(m_frame, "Pet", 4);
			petMenu.AddItem("None", Delegate.create(this, PetCallback), Colors.e_ColorPassiveSpellHighlight, Colors.e_ColorPassiveSpellBackground);
			m_menu.AddSubMenu("Pet", petMenu, Colors.e_ColorPassiveSpellHighlight, Colors.e_ColorPassiveSpellBackground);
			
			var petNodes:Array = GetPetData();
			for (var indx:Number = 0; indx < petNodes.length; ++indx)
			{
				var thisNode:LoreNode = petNodes[indx];
				if (thisNode != null)
				{
					petMenu.AddItem(thisNode.m_Name, Delegate.create(this, PetCallback), Colors.e_ColorPassiveSpellHighlight, Colors.e_ColorPassiveSpellBackground);
				}
			}
		}
		
		m_menu.SetVisible(false);
	}
	
	private function SprintCallback(sprintName:String):Void
	{
		m_menu.SetVisible(false);

		var tag:Number = GetTagFromSprintName(sprintName);
		if (tag != null && m_sprintCallback != null)
		{
			m_sprintCallback(tag);
		}
	}
	
	private function PetCallback(petName:String):Void
	{
		m_menu.SetVisible(false);

		var tag:Number = GetTagFromPetName(petName);
		if (m_petCallback != null)
		{
			m_petCallback(tag);
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