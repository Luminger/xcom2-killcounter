class KillCounter_UI extends UIPanel;

var localized string strKilled;
var localized string strActive;
var localized string strTotal;
var localized string strRemaining;

var KillCounter_Settings Settings;

var UIText Text;
var UITextStyleObject TextStyle;

var int LastKilled;
var int LastKilledLost;
var int LastActive;
var int LastTotal;
var int LastIndex;

// Stolen from UiUtilities_Colors::THELOST_HTML_COLOR as we can't reference that color
// otherwise to stay backward compatible
const TheLostColor = "acd373";

simulated function UIPanel InitPanel(optional name InitName, optional name InitLibID)
{
	super.InitPanel(InitName, InitLibID);
	self.SetSize(350, 50);

	Text = Spawn(class'UIText', self);
	Text.InitText('KillCounter_Text');
	Text.SetSize(Width, Height);

	class'KillCounter_Utils'.static.ShadowToTextField(Text);

	TextStyle = class'UIUtilities_Text'.static.GetStyle(eUITextStyle_Tooltip_H2);
	TextStyle.bUseCaps = False;

	// Reset is needed here for a load from Tactical to Tactical as the
	// current instance doesn't get destroyed - but OnInit is called
	// again, so here's the correct place to wipe all of the state again.
	LastKilled = -1;
	LastKilledLost = -1;
	LastActive = -1;
	LastTotal = -1;
	LastIndex = -1;

	UpdateSettings(new class'KillCounter_Settings');
	return self;
}

function UpdateSettings(KillCounter_Settings newSettings)
{
	Settings = newSettings;

	self.SetAnchor(settings.BoxAnchor);
	self.SetPosition(settings.OffsetX, settings.OffsetY);
	TextStyle.Alignment = Settings.textAlignment;

	self.Update();
}

function Update(optional int historyIndex = LastIndex)
{
	local bool SkipTurrets;
	local int killed, killedLost, active, total;

	SkipTurrets = Settings.ShouldSkipTurrets();
	class'KillCounter_Utils'.static.GetCounters(historyIndex, SkipTurrets, killed, killedLost, active, total);

	if (killed != LastKilled || killedLost != LastKilledLost || active != LastActive || total != LastTotal || LastIndex == -1)
	{
		self.UpdateText(killed, killedLost, active, total);
		
		LastKilled = killed;
		LastKilledLost = killedLost;
		LastActive = active;
		LastTotal = total;
		LastIndex = historyIndex;
	}
}

function UpdateText(int killed, int killedLost, int active, int total)
{
	local string Value;

	if(Text == none)
	{
		return;
	}

	Value = strKilled @ AddColor(killed, eUIState_Good);

	if(killedLost != -1)
	{
		Value @= "(" $ AddStrColor(killedLost, TheLostColor) $ ")";
	}

	if(Settings.ShouldDrawActiveCount())
	{
		Value @= strActive @ AddColor(active, eUIState_Warning2);
	}

	if(Settings.ShouldDrawTotalCount())
	{
		if(Settings.ShouldShowRemainingInsteadOfTotal())
		{
			Value @= strRemaining @ AddColor(total - killed, eUIState_Bad);
		}
		else
		{
			Value @= strTotal @ AddColor(total, eUIState_Bad);
		}
	}

	Text.SetHtmlText(class'UIUtilities_Text'.static.ApplyStyle(Value, TextStyle));
}

function string AddColor(int value, int clr)
{
	if(settings.noColor)
	{
		return string(value);
	}

	return class'UIUtilities_Text'.static.GetColoredText(string(value), clr);
}

function string AddStrColor(int value, string clr)
{
	if(settings.noColor)
	{
		return string(value);
	}

	return "<font color='#" $ clr $ "'>" $ string(value) $ "</font>";
}

defaultproperties
{
	LastKilled = -1;
	LastKilledLost = -1;
	LastActive = -1;
	LastTotal = -1;
	LastIndex = -1;
}