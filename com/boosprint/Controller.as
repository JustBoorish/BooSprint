//Imports
import com.boosprint.BIcon;
import com.boosprint.ConfigWindow;
import com.boosprint.Controller;
import com.boosprint.DebugWindow;
import com.boosprint.IntervalCounter;
import com.boosprint.MountHelper;
import com.boosprint.PetHelper;
import com.boosprint.PetSelector;
import com.boosprint.Settings;
import com.boosprint.SprintSelector;
import com.GameInterface.Game.Character;
import com.GameInterface.DistributedValue;
import com.GameInterface.Input;
import com.Utils.Archive;
import com.Utils.StringUtils;
import mx.utils.Delegate;

class com.boosprint.Controller extends MovieClip
{
	private static var VERSION:String = "1.2";

	private static var m_instance:Controller = null;
	
	private var m_debug:DebugWindow = null;
	private var m_icon:BIcon;
	private var m_mc:MovieClip;
	private var m_defaults:Object;
	private var m_settings:Object;
	private var m_settingsPrefix:String = "BooSprint";
	private var m_clientCharacter:Character;
	private var m_characterName:String;
	private var m_sprintID:Number;
	private var m_sprintDV:DistributedValue;
	private var m_petDV:DistributedValue;
	private var m_configWindow:ConfigWindow;
	private var m_sprintSelectorWindow:SprintSelector;
	private var m_oldPlayfield:Number;
	
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
				m_debug = new DebugWindow(m_mc, DebugWindow.Debug);
			}
			else
			{
				m_debug = new DebugWindow(m_mc, DebugWindow.Info);
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
		SetDefaults();
		
		m_sprintDV = DistributedValue.Create("BooSprint_Name");
		m_sprintDV.SetValue("");
		m_petDV = DistributedValue.Create("BooSprint_Pet");
		m_petDV.SetValue("");
	}
	
	function OnModuleActivated(config:Archive):Void
	{
		Settings.SetArchive(config);
		DebugWindow.Log("BooSprint OnModuleActivated: " + config.toString());
		
		m_sprintDV.SignalChanged.Connect(SprintChanged, this);
		m_petDV.SignalChanged.Connect(PetChanged, this);

		if (Character.GetClientCharacter().GetName() != m_characterName)
		{
			m_clientCharacter = Character.GetClientCharacter();
			m_characterName = m_clientCharacter.GetName();
			DebugWindow.Log("BooSprint OnModuleActivated: connect " + m_characterName);
			m_settings = Settings.Load(m_settingsPrefix, m_defaults);
			
			m_icon = new BIcon(m_mc, _root["boosprint\\boosprint"].BooSprintIcon, VERSION, Delegate.create(this, ToggleSprintSelectorVisible), Delegate.create(this, ToggleConfigVisible), Delegate.create(this, ToggleSprintEnabled), Delegate.create(this, ToggleDebugVisible), m_settings[BIcon.ICON_X], m_settings[BIcon.ICON_Y], Delegate.create(this, IsSprintEnabled), Delegate.create(this, GetCurrentSprintName), Delegate.create(this, GetCurrentPetName));
		}
		
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
	
	private function SetDefaults():Void
	{
		m_defaults = new Object();
		m_defaults[Settings.X] = 650;
		m_defaults[Settings.Y] = 600;
		m_defaults[BIcon.ICON_X] = -1;
		m_defaults[BIcon.ICON_Y] = -1;
		Settings.SetSprintTag(m_defaults, 0);
		Settings.SetSprintInterval(m_defaults, 4);
		Settings.SetSprintEnabled(m_defaults, true);
		Settings.SetPetTag(m_defaults, 0);
		Settings.SetPetEnabled(m_defaults, true);
		Settings.SetOverrideKey(m_defaults, true);
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
			m_sprintSelectorWindow = new SprintSelector(m_mc, "Sprint Selector", Delegate.create(this, SprintSelected), Delegate.create(this, PetSelected), Settings.GetPetEnabled(m_settings));
			var icon:MovieClip = m_icon.GetIcon();
			if (_root._xmouse >= icon._x && _root._xmouse <= icon._x + icon._width &&
				_root._ymouse >= icon._y && _root._ymouse <= icon._y + icon._height)
			{
				m_sprintSelectorWindow.Show(icon._x + icon._width / 2, icon._y + icon._height);
			}
			else
			{
				m_sprintSelectorWindow.Show(_root._xmouse + 5, _root._ymouse + 5);
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
			m_configWindow = new ConfigWindow(m_mc, "BooSprint", m_settings[Settings.X], m_settings[Settings.Y], 300, Delegate.create(this, ConfigClosed), "BooSprintHelp", m_settings);
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

		var newTag:Number = SprintSelector.GetTagFromPetName(petName);
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

		var newTag:Number = SprintSelector.GetTagFromSprintName(sprintName);
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
					Mount();
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
		return SprintSelector.GetSprintFromTag(Settings.GetSprintTag(m_settings));
	}
	
	private function GetCurrentPetName():String
	{
		if (Settings.GetPetEnabled(m_settings) == true)
		{
			return SprintSelector.GetPetFromTag(Settings.GetPetTag(m_settings));
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
			m_instance.ToggleSprint();
		}
	}	
}
