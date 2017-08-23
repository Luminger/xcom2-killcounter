class KillCounter_UI extends UIPanel;

var localized string strKilled;
var localized string strActive;
var localized string strTotal;
var localized string strRemaining;

var KillCounter_Settings Settings;

var UIText Text;
var UITextStyleObject TextStyle;

var int LastKilled;
var int LastActive;
var int LastTotal;
var int LastIndex;

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

	UpdateSettings(new class'KillCounter_Settings');

	// Reset is needed here for a load from Tactical to Tactical as the
	// current instance doesn't get destroyed - but OnInit is called
	// again, so here's the correct place to wipe all of the state again.
	LastKilled = default.LastKilled;
	LastActive = default.LastActive;
	LastTotal = default.LastTotal;

	return self;
}

function UpdateSettings(KillCounter_Settings newSettings)
{
	Settings = newSettings;

	self.SetAnchor(settings.BoxAnchor);
	self.SetPosition(settings.OffsetX, settings.OffsetY);
	TextStyle.Alignment = Settings.textAlignment;
}

function Update(optional int historyIndex = LastIndex)
{
	local bool ShowTotal, ShowActive, SkipTurrets;
	local int killed, active, total;

	ShowTotal = Settings.ShouldDrawTotalCount();
	ShowActive = Settings.ShouldDrawActiveCount();
	SkipTurrets = Settings.ShouldSkipTurrets();

	killed = class'KillCounter_Utils'.static.GetKilledEnemies(historyIndex, SkipTurrets);
	active = ShowActive ? class'KillCounter_Utils'.static.GetActiveEnemies(historyIndex, SkipTurrets) : -1;
	total = ShowTotal ? class'KillCounter_Utils'.static.GetTotalEnemies(SkipTurrets) : -1;

	if (killed != LastKilled || active != LastActive || total != LastTotal)
	{
		self.UpdateText(killed, active, total, historyIndex);
		
		LastKilled = killed;
		LastActive = active;
		LastTotal = total;
	}

	UpdateText(killed, active, total);
}

function UpdateText(int killed, int active, int total, optional int historyIndex = LastIndex)
{
	local string Value;

	if(Text == none)
	{
		return;
	}

	LastIndex = historyIndex;

	Value = strKilled @ AddColor(killed, eUIState_Good);

	if(active != -1)
	{
		Value @= strActive @ AddColor(active, eUIState_Warning2);
	}

	if(total != -1)
	{
		if(settings.showRemainingInsteadOfTotal)
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

defaultproperties
{
	LastKilled = -1;
	LastActive = -1;
	LastTotal = -1;
	LastIndex = -1;
}