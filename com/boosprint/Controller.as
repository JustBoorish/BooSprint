//Imports
import com.GameInterface.DistributedValue;
import com.GameInterface.Game.BuffData;
import com.GameInterface.Game.Character;
import com.GameInterface.Input;
import com.Utils.Archive;
import com.Utils.StringUtils;
import com.boosprintcommon.Colours;
import com.boosprintcommon.DebugWindow;
import com.boosprintcommon.MountHelper;
import com.boosprintcommon.PetHelper;
import com.boosprintcommon.TabWindow;
import com.boosprint.BIcon;
import com.boosprint.Entry;
import com.boosprint.EntryList;
import com.boosprint.OptionsTab;
import com.boosprint.Controller;
import com.boosprint.Group;
import com.boosprint.Settings;
import com.boosprint.SprintSelector;
import mx.utils.Delegate;

class com.boosprint.Controller extends MovieClip
{
	private static var VERSION:String = "1.7.2";
	private static var MAX_GROUPS:Number = 50;
	private static var MAX_ENTRIES:Number = 350;

	private static var m_instance:Controller = null;
	
	private var m_debug:DebugWindow = null;
	private var m_icon:BIcon;
	private var m_mc:MovieClip;
	private var m_defaults:Object;
	private var m_settings:Object;
	private var m_entries:Object;
	private var m_groups:Array;
	private var m_settingsPrefix:String = "BooSprint";
	private var m_clientCharacter:Character;
	private var m_characterName:String;
	private var m_sprintID:Number;
	private var m_sprintDV:DistributedValue;
	private var m_petDV:DistributedValue;
	private var m_configWindow:TabWindow;
	private var m_sprintSelectorWindow:SprintSelector;
	private var m_oldPlayfield:Number;
	private var m_entryList:EntryList;
	private var m_optionsTab:OptionsTab;
	private var m_knownDebuffs:Object;
	
	//On Load
	function onLoad():Void
	{
		Settings.SetVersion(VERSION);
		
		m_mc = this;
		m_instance = this;
		
		m_clientCharacter = Character.GetClientCharacter();
		
		if (m_debug == null)
		{
			if (m_clientCharacter != null && (m_clientCharacter.GetName() == "Boorish" || m_clientCharacter.GetName() == "Boor" || m_clientCharacter.GetName() == "BoorGirl"))
			{
				m_debug = DebugWindow.GetInstance(m_mc, DebugWindow.Debug, "BooSprintDebug");
			}
		}
		DebugWindow.Log(DebugWindow.Info, "BooSprint Loaded");

		_root["boosprint\\boosprint"].OnModuleActivated = Delegate.create(this, OnModuleActivated);
		_root["boosprint\\boosprint"].OnModuleDeactivated = Delegate.create(this, OnModuleDeactivated);
		
		m_mc._x = 0;
		m_mc._y = 0;
		m_characterName = null;
		m_sprintID = -1;
		m_oldPlayfield = 0;
		SetKnownDebuffs();
		SetDefaults();
		
		m_sprintDV = DistributedValue.Create("BooSprint_Name");
		m_sprintDV.SetValue("");
		m_petDV = DistributedValue.Create("BooSprint_Pet");
		m_petDV.SetValue("");
	}
	
	function OnModuleActivated(config:Archive):Void
	{
		Settings.SetArchive(config);
		
		m_sprintDV.SignalChanged.Connect(SprintChanged, this);
		m_petDV.SignalChanged.Connect(PetChanged, this);

		if (Character.GetClientCharacter().GetName() != m_characterName)
		{
			m_clientCharacter = Character.GetClientCharacter();
			m_characterName = m_clientCharacter.GetName();
			DebugWindow.Log("BooSprint OnModuleActivated: connect " + m_characterName);
			m_settings = Settings.Load(m_settingsPrefix, m_defaults);
			LoadGroups();
			LoadEntries();
			SetDefaultEntries();
			
			m_icon = new BIcon(m_mc, _root["boosprint\\boosprint"].BooSprintIcon, VERSION, Delegate.create(this, ToggleSprintSelectorVisible), Delegate.create(this, ToggleConfigVisible), Delegate.create(this, ToggleSprintEnabled), Delegate.create(this, ToggleDebugVisible), m_settings[BIcon.ICON_X], m_settings[BIcon.ICON_Y], Delegate.create(this, IsSprintEnabled), Delegate.create(this, GetCurrentSprintName), Delegate.create(this, GetCurrentPetName));
		}
		
		SetUnknownEntries();
		
		StartAutoSprint();		
		OverwriteSprintKey(Settings.GetOverrideKey(m_settings));

		if (Settings.GetPetEnabled(m_settings) == true)
		{
			var playfield:Number = m_clientCharacter.GetPlayfieldID();
			if (playfield != m_oldPlayfield)
			{
				if (playfield != null)
				{
					m_oldPlayfield = playfield;
				}
				else
				{
					m_oldPlayfield = 0;
				}
				
				PetHelper.Summon(Settings.GetPetTag(m_settings));
			}
		}
	}
	
	function OnModuleDeactivated():Archive
	{		
		StopAutoSprint();
		SaveSettings();
		OverwriteSprintKey(false);
		m_sprintDV.SignalChanged.Disconnect(SprintChanged, this);
		m_petDV.SignalChanged.Disconnect(PetChanged, this);

		var ret:Archive = Settings.GetArchive();
		//DebugWindow.Log("BooSprint OnModuleDeactivated: " + ret.toString());
		return ret;
	}
	
	private function StartAutoSprint():Void
	{
		StopAutoSprint();
		if (Settings.GetSprintEnabled(m_settings) == true)
		{
			var sprintCheckTimeout:Number = Settings.GetSprintInterval(m_settings) * 1000;
			m_sprintID = setInterval(Delegate.create(this, SprintIfNeeded), sprintCheckTimeout);
		}
	}
	
	private function StopAutoSprint():Void
	{
		if (m_sprintID != -1)
		{
			clearInterval(m_sprintID);
			m_sprintID = -1;
		}
	}
	
	private function SetKnownDebuffs():Void
	{
		m_knownDebuffs = new Object();
		m_knownDebuffs[6460735] = 1; // Burning
		m_knownDebuffs[6542663] = 1; // Filth Exposure
		m_knownDebuffs[8429030] = 1; // Hellfire		
		m_knownDebuffs[8537482] = 1; // Filth		
		m_knownDebuffs[8655424] = 1; // Filth		
		m_knownDebuffs[6460881] = 1; // Infected		
		m_knownDebuffs[7853405] = 1; // Nasty Infections		
		m_knownDebuffs[5576863] = 1; // Bleeding		
		m_knownDebuffs[7087397] = 1; // Poison		
		m_knownDebuffs[9008143] = 1; // Insect Swarm		
		
		m_knownDebuffs["Accursed"] = 1;
		m_knownDebuffs["Filth"] = 1;
		m_knownDebuffs["Acid Rain"] = 1;
		m_knownDebuffs["Insect Swarm"] = 1;
	}
	
	private function SetDefaults():Void
	{
		m_defaults = new Object();
		m_defaults[Settings.X] = 650;
		m_defaults[Settings.Y] = 600;
		m_defaults[BIcon.ICON_X] = -1;
		m_defaults[BIcon.ICON_Y] = -1;
		Settings.SetSprintTag(m_defaults, 0);
		Settings.SetSprintInterval(m_defaults, 2);
		Settings.SetSprintEnabled(m_defaults, true);
		Settings.SetPetTag(m_defaults, 0);
		Settings.SetPetEnabled(m_defaults, true);
		Settings.SetOverrideKey(m_defaults, true);
		Settings.SetSmartSprint(m_defaults, true);
	}
	
	private function SaveSettings():Void
	{
		if (m_configWindow != null)
		{
			var pt:Object = m_configWindow.GetCoords()
			m_settings[Settings.X] = pt.x;
			m_settings[Settings.Y] = pt.y;
		}
		
		var pt:Object = m_icon.GetCoords();
		m_settings[BIcon.ICON_X] = pt.x;
		m_settings[BIcon.ICON_Y] = pt.y;

		Settings.Save(m_settingsPrefix, m_settings, m_defaults);
		SaveGroups();
		SaveEntries();
	}
	
	private function SaveGroups():Void
	{
		var archive:Archive = Settings.GetArchive();
		var groupNumber:Number = 1;
		for (var indx:Number = 0; indx < m_groups.length; ++indx)
		{
			var thisGroup:Group = m_groups[indx];
			if (thisGroup != null)
			{
				thisGroup.Save(Group.GROUP_PREFIX, archive, groupNumber);
				++groupNumber;
			}
		}
		
		for (var indx:Number = groupNumber; indx <= MAX_GROUPS; ++indx)
		{
			Group.ClearArchive(Group.GROUP_PREFIX, archive, indx);
		}
	}
	
	private function LoadGroups():Void
	{
		m_groups = new Array();
		var archive:Archive = Settings.GetArchive();
		for (var indx:Number = 0; indx < MAX_GROUPS; ++indx)
		{
			var thisGroup:Group = Group.FromArchive(Group.GROUP_PREFIX, archive, indx + 1);
			if (thisGroup != null)
			{
				m_groups.push(thisGroup);
			}
		}
	}
	
	private function SetDefaultEntries():Void
	{		
		if (m_groups.length == 0)
		{
			m_groups = new Array();
			m_entries = new Object();
			m_groups.push(new Group(Group.GetNextID(m_groups), "Sprints", Colours.GREEN, false));
			m_groups.push(new Group(Group.GetNextID(m_groups), "Pets", Colours.ORANGE, false));
			
			Entry.SetUnkownSprints(m_groups[0].GetID(), m_entries);
			
			var noPet:Entry = new Entry("No pet", 0, false, m_groups[1].GetID(), Entry.GetNextOrder(m_groups[1].GetID(), m_entries));
			m_entries[noPet.GetTag()] = noPet;
			Entry.SetUnkownPets(m_groups[1].GetID(), m_entries);
		}
	}
	
	private function SetUnknownEntries():Void
	{
		var newGroup:Group = null;
		for (var indx:Number = 0; indx < m_groups.length; ++indx)
		{
			var thisGroup:Group = m_groups[indx];
			if (thisGroup != null && thisGroup.GetName() == "New")
			{
				newGroup = thisGroup;
				break;
			}
		}
		
		var addNewGroup:Boolean = false;
		if (newGroup == null)
		{
			addNewGroup = true;
			newGroup = new Group(Group.GetNextID(m_groups), "New", Colours.GetDefaultColourName(), false);
		}
		
		Entry.SetUnkownSprints(newGroup.GetID(), m_entries);
		Entry.SetUnkownPets(newGroup.GetID(), m_entries);
		
		if (addNewGroup == true)
		{
			if (Entry.IsGroupEmpty(newGroup.GetID(), m_entries) != true)
			{
				m_groups.push(newGroup);
			}
		}
	}
	
	private function SaveEntries():Void
	{
		var archive:Archive = Settings.GetArchive();
		var entryNumber:Number = 1;
		for (var indx:String in m_entries)
		{
			var thisEntry:Entry = m_entries[indx];
			if (thisEntry != null)
			{
				thisEntry.Save(archive, entryNumber);
				++entryNumber;
			}
		}
		
		for (var indx:Number = entryNumber; indx <= MAX_ENTRIES; ++indx)
		{
			Entry.ClearArchive(archive, indx);
		}
	}
	
	private function LoadEntries():Void
	{
		m_entries = new Object();
		var archive:Archive = Settings.GetArchive();
		for (var indx:Number = 0; indx < MAX_ENTRIES; ++indx)
		{
			var thisEntry:Entry = Entry.FromArchive(indx + 1, archive);
			if (thisEntry != null)
			{
				if (Group.FindGroupWithID(m_groups, thisEntry.GetGroup()) != null)
				{
					m_entries[thisEntry.GetTag()] = thisEntry;
				}
				else
				{
					Entry.ClearArchive(archive, indx + 1);
				}
			}
		}
	}
	
	private function ToggleSprintSelectorVisible():Void
	{
		if (m_configWindow != null && m_configWindow.GetVisible() == true)
		{
			ToggleConfigVisible();
		}
		
		var show:Boolean = true;
		if (m_sprintSelectorWindow != null)
		{
			if (m_sprintSelectorWindow.GetVisible() == true)
			{
				show = false;
			}
			
			m_sprintSelectorWindow.Unload();
			m_sprintSelectorWindow = null;
		}
		
		if (show == true)
		{
			m_sprintSelectorWindow = new SprintSelector(m_mc, "Sprint Selector", m_groups, m_entries, Delegate.create(this, SprintSelected), Delegate.create(this, PetSelected));
			var icon:MovieClip = m_icon.GetIcon();
			if (_root._xmouse >= icon._x && _root._xmouse <= icon._x + icon._width &&
				_root._ymouse >= icon._y && _root._ymouse <= icon._y + icon._height)
			{
				m_sprintSelectorWindow.Show(icon._x + icon._width / 2, icon._y + icon._height, icon._y);
			}
			else
			{
				m_sprintSelectorWindow.Show(_root._xmouse + 5, _root._ymouse + 5, _root._ymouse - 5);
			}
		}
	}
	
	private function SprintSelected(newTag:Number):Void
	{
		if (newTag != null and newTag > 0)
		{
			StopAutoSprint();
			Settings.SetSprintTag(m_settings, newTag);
			SaveSettings();
			MountHelper.Dismount(Delegate.create(this, SprintAfterDismount));
		}
	}
	
	private function SprintAfterDismount():Void
	{
		var stop:Boolean = false;
		if (MountHelper.IsSprinting() != true)
		{
			SprintIfNeeded();
		}
		
		StartAutoSprint();
	}
	
	private function DismoutError():Void
	{
		DebugWindow.Log(DebugWindow.Error, "Failed to dismount");
	}
	
	private function PetSelected(newTag:Number):Void
	{
		var oldTag:Number = Settings.GetPetTag(m_settings);
		if (newTag != null and newTag > 0)
		{
			Settings.SetPetTag(m_settings, newTag);
			SaveSettings();
			if (oldTag != newTag)
			{
				PetHelper.Summon(newTag);
			}
		}
		else
		{
			Settings.SetPetTag(m_settings, 0);
			SaveSettings();
			if (oldTag > 0)
			{
				PetHelper.Dismiss(oldTag);
			}
		}
	}
	
	private function ToggleConfigVisible():Void
	{
		if (m_sprintSelectorWindow != null && m_sprintSelectorWindow.GetVisible() == true)
		{
			ToggleSprintSelectorVisible();
		}
		
		if (m_configWindow == null)
		{
			m_entryList = new EntryList("EntryList", m_groups, m_entries, m_settings, Delegate.create(this, SprintSelected), Delegate.create(this, PetSelected));
			m_optionsTab = new OptionsTab("Options", m_settings);
			m_configWindow = new TabWindow(m_mc, "BooSprint", m_settings[Settings.X], m_settings[Settings.Y], 300, 400, Delegate.create(this, ConfigClosed), "BooSprintHelp", "https://tswact.wordpress.com/boosprint/");
			m_configWindow.AddTab("Entries", m_entryList);
			m_configWindow.AddTab("Options", m_optionsTab);
		}
		
		m_configWindow.ToggleVisible();
	}
	
	private function ToggleDebugVisible():Void
	{
		DebugWindow.ToggleVisible();
	}
	
	private function ConfigClosed():Void
	{
		var petTag:Number = Settings.GetPetTag(m_settings);
		if (Settings.GetPetEnabled(m_settings) != true && petTag > 0)
		{
			Settings.SetPetTag(m_settings, 0);
			PetHelper.Dismiss(petTag);
		}
		
		SaveSettings();
		m_configWindow.Unload();
		m_configWindow = null;

		OverwriteSprintKey(Settings.GetOverrideKey(m_settings));
		StartAutoSprint();
	}
	
	private function PetChanged():Void
	{
		var petName:String = m_petDV.GetValue();
		if (petName != null)
		{
			petName = StringUtils.Strip(petName);
		}
		
		if (petName == null || petName == "")
		{
			return;
		}

		var newTag:Number = Entry.GetTagFromPetName(petName);
		PetSelected(newTag);
	}
	
	private function SprintChanged():Void
	{
		var sprintName:String = m_sprintDV.GetValue();
		if (sprintName != null)
		{
			sprintName = StringUtils.Strip(sprintName);
		}
		
		if (sprintName == null || sprintName == "")
		{
			return;
		}

		var newTag:Number = Entry.GetTagFromSprintName(sprintName);
		SprintSelected(newTag);
	}
	
	private function SprintIfNeeded():Void
	{
		if (m_clientCharacter == null)
		{
			m_clientCharacter = Character.GetClientCharacter();
		}
		
		if (m_clientCharacter != null)
		{
			if (m_clientCharacter.IsInCombat() != true && m_clientCharacter.IsInCinematic() != true && m_clientCharacter.IsInCharacterCreation() != true && m_clientCharacter.IsGhosting() != true && MountHelper.IsSprinting() != true)
			{
				var progress:Number = m_clientCharacter.GetCommandProgress();
				if (progress == null || progress == 0)
				{
					if (IsKnownDebuffActive() != true)
					{
						Mount();
					}
				}
			}
		}
	}
	
	private function Mount():Void
	{
		var sprintTag:Number = Settings.GetSprintTag(m_settings);
		MountHelper.Mount(sprintTag);
	}
	
	private function IsSprintEnabled():Boolean
	{
		return Settings.GetSprintEnabled(m_settings);
	}
	
	private function ToggleSprintEnabled():Void
	{
		Settings.SetSprintEnabled(m_settings, !Settings.GetSprintEnabled(m_settings));
		StartAutoSprint();
	}
	
	private function GetCurrentSprintName():String
	{
		return Entry.GetSprintFromTag(Settings.GetSprintTag(m_settings));
	}
	
	private function GetCurrentPetName():String
	{
		if (Settings.GetPetEnabled(m_settings) == true)
		{
			return Entry.GetPetFromTag(Settings.GetPetTag(m_settings));
		}
		else
		{
			return null;
		}
	}
	
	private function OverwriteSprintKey(enabled:Boolean):Void
	{
		var func:String;
		if (enabled == true)
		{
			func = "com.boosprint.Controller.SprintKeyHandler";
		}
		else
		{
			func = "";
		}
		
		Input.RegisterHotkey(_global.Enums.InputCommand.e_InputCommand_Movement_SprintToggle, func, _global.Enums.Hotkey.eHotkeyDown, 0);
	}
	
	private function SmartToggleSprint():Void
	{
		if (m_clientCharacter != null)
		{
			if (MountHelper.IsSprinting() == true)
			{
				MountHelper.Dismount();
				if (IsSprintEnabled() == true)
				{
					ToggleSprintEnabled();
				}
			}
			else
			{
				Mount();
				if (IsSprintEnabled() != true)
				{
					ToggleSprintEnabled();
				}
			}
		}
	}
	
	private function ToggleSprint():Void
	{
		if (m_clientCharacter != null)
		{
			if (MountHelper.IsSprinting() == true)
			{
				MountHelper.Dismount();
			}
			else
			{
				Mount();
			}
		}
	}
	
	private static function SprintKeyHandler(keyCode:Number):Void
	{
		if (m_instance != null)
		{
			if (Settings.GetSmartSprint(m_instance.m_settings) == true)
			{
				m_instance.SmartToggleSprint();
			}
			else
			{
				m_instance.ToggleSprint();
			}
		}
	}
	
	private function IsKnownDebuffActive():Boolean
	{
		var ret:Boolean = false;
		if (m_clientCharacter != null && m_clientCharacter.m_BuffList != null)
		{
			for (var indx in m_clientCharacter.m_BuffList)
			{
				var buffData:BuffData = m_clientCharacter.m_BuffList[indx];
				if (buffData != null && buffData.m_BuffId != null && m_knownDebuffs[buffData.m_BuffId] == 1)
				{
					ret = true;
					break;
				}
				else if (buffData != null && buffData.m_Name != null && m_knownDebuffs[buffData.m_Name] == 1)
				{
					DebugWindow.Log(DebugWindow.Debug, "Buff2 " + buffData.m_Name + " ID " + buffData.m_BuffId);
					ret = true;
					break;
				}
			}
		}
		
		return ret;
		
	}
}
