import caurina.transitions.Tweener;
import com.GameInterface.DistributedValue;
import com.Utils.Text;
import com.boosprintcommon.Checkbox;
import com.boosprintcommon.Graphics;
import com.boosprintcommon.ITabPane;
import com.boosprint.Settings;
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
class com.boosprint.OptionsTab implements ITabPane
{
	private var m_parent:MovieClip;
	private var m_frame:MovieClip;
	private var m_name:String;
	private var m_textFormat:TextFormat;
	private var m_margin:Number;
	private var m_helpIcon:MovieClip;
	private var m_settings:Object;
	private var m_enabledCheck:Checkbox;
	private var m_keyCheck:Checkbox;
	private var m_smartCheck:Checkbox;
	private var m_petCheck:Checkbox;
	private var m_interval:TextField;
	
	public function OptionsTab(title:String, settings:Object) 
	{
		m_name = title;
		m_settings = settings;
		m_margin = 6;
		
		m_textFormat = Graphics.GetTextFormat();
	}
	
	public function Unload():Void
	{
		m_frame._visible = false;
		m_frame.removeMovieClip();
	}
	
	public function ToggleVisible():Void
	{
		SetVisible(!GetVisible());
	}
	
	public function CreatePane(addonMC:MovieClip, parent:MovieClip, name:String, xIn:Number, yIn:Number, width:Number, height:Number):Void
	{
		m_parent = parent;
		m_frame = parent.createEmptyMovieClip(m_name + "OptionsTab", parent.getNextHighestDepth());
		m_frame._visible = false;
		m_frame._x = xIn;
		m_frame._y = yIn;
		
		var y:Number = 20;
		var checkSize:Number = 10;
		var enabledText:String = "Auto sprint enabled";
		var enabledExtents:Object = Text.GetTextExtent(enabledText, m_textFormat, m_frame);
		m_enabledCheck = new Checkbox("EnabledCheck", m_frame, 20, y + enabledExtents.height / 2 - checkSize / 2, checkSize, null, true);
		Graphics.DrawText("EnabledLabel", m_frame, enabledText, m_textFormat, 30 + checkSize, y, enabledExtents.width, enabledExtents.height);
		
		y += 10 + enabledExtents.height;
		var intervalText:String = "Auto sprint interval (seconds)";
		var intervalExtents:Object = Text.GetTextExtent(intervalText, m_textFormat, m_frame);
		Graphics.DrawText("IntervalLabel", m_frame, intervalText, m_textFormat, 20, y, intervalExtents.width, intervalExtents.height);

		var intervalValueExtents:Object = Text.GetTextExtent("36000", m_textFormat, m_frame);
		m_interval = m_frame.createTextField("IntervalText", m_frame.getNextHighestDepth(), 30 + intervalExtents.width, y, intervalValueExtents.width, intervalValueExtents.height);
		m_interval.type = "input";
		m_interval.setNewTextFormat(m_textFormat);
		m_interval.setTextFormat(m_textFormat);
		m_interval.embedFonts = true;
		m_interval.selectable = true;
		m_interval.antiAliasType = "advanced";
		m_interval.autoSize = false;
		m_interval.border = true;
		m_interval.background = true;
		m_interval.textColor = 0xFFFFFF;
		m_interval.backgroundColor = 0x2E2E2E;
		
		y = 10 + m_interval._y + m_interval._height;
		var keyText:String = "Override sprint key";
		var keyExtents:Object = Text.GetTextExtent(keyText, m_textFormat, m_frame);
		m_keyCheck = new Checkbox("KeyCheck", m_frame, 20, y + keyExtents.height / 2 - checkSize / 2, checkSize, null, true);
		Graphics.DrawText("KeyLabel", m_frame, keyText, m_textFormat, 30 + checkSize, y, keyExtents.width, keyExtents.height);		
		
		y += 10 + keyExtents.height;
		var smartText:String = "Smart sprint for sprint key";
		var smartExtents:Object = Text.GetTextExtent(smartText, m_textFormat, m_frame);
		m_smartCheck = new Checkbox("SmartCheck", m_frame, 20, y + smartExtents.height / 2 - checkSize / 2, checkSize, null, true);
		Graphics.DrawText("SmartLabel", m_frame, smartText, m_textFormat, 30 + checkSize, y, smartExtents.width, smartExtents.height);		
		
		y += 10 + smartExtents.height;
		var petText:String = "Enable pet handling";
		var petExtents:Object = Text.GetTextExtent(petText, m_textFormat, m_frame);
		m_petCheck = new Checkbox("PetCheck", m_frame, 20, y + petExtents.height / 2 - checkSize / 2, checkSize, null, true);
		Graphics.DrawText("PetLabel", m_frame, petText, m_textFormat, 30 + checkSize, y, petExtents.width, petExtents.height);
		
		SetOptions();
	}
	
	public function Save():Void
	{
		ApplySettings();
	}
	
	public function StartDrag():Void
	{
		
	}
	
	public function StopDrag():Void
	{
		
	}
	
	public function SetVisible(visible:Boolean):Void
	{
		if (visible == true)
		{
			SetOptions();
		}
		
		m_frame._visible = visible;
	}
	
	public function GetVisible():Boolean
	{
		return m_frame._visible;
	}
	
	public function GetCoords():Object
	{
		var pt:Object = new Object();
		pt.x = m_frame._x;
		pt.y = m_frame._y;
		return pt;
	}
	
	private function ApplySettings():Void
	{
		Settings.SetSprintEnabled(m_settings, m_enabledCheck.IsChecked());
		Settings.SetSprintInterval(m_settings, Number(m_interval.text));
		Settings.SetOverrideKey(m_settings, m_keyCheck.IsChecked());
		Settings.SetSmartSprint(m_settings, m_smartCheck.IsChecked());
		Settings.SetPetEnabled(m_settings, m_petCheck.IsChecked());
	}
	
	private function SetOptions():Void
	{
		m_enabledCheck.SetChecked(Settings.GetSprintEnabled(m_settings));
		m_interval.text = String(Settings.GetSprintInterval(m_settings));
		m_keyCheck.SetChecked(Settings.GetOverrideKey(m_settings));
		m_smartCheck.SetChecked(Settings.GetSmartSprint(m_settings));
		m_petCheck.SetChecked(Settings.GetPetEnabled(m_settings));
	}
}