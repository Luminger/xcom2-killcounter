class KillCounter_UI extends UIPanel;

var localized string strKilled;
var localized string strActive;
var localized string strTotal;
var localized string strRemaining;

var KillCounter_Settings settings;

var UIText Text;
var UITextStyleObject TextStyle;

var int LastIndex;

simulated function UIPanel InitPanel(optional name InitName, optional name InitLibID)
{
	settings = new class'KillCounter_Settings';

	super.InitPanel(InitName, InitLibID);
	self.SetAnchor(settings.BoxAnchor);
	self.SetSize(350, 50);
	self.SetPosition(settings.OffsetX, settings.OffsetY); 

	Text = Spawn(class'UIText', self);
	Text.InitText('KillCounter_Text');
	Text.SetSize(Width, Height);

	class'KillCounter_Utils'.static.ShadowToTextField(Text);

	TextStyle = class'UIUtilities_Text'.static.GetStyle(eUITextStyle_Tooltip_H2);
	TextStyle.Alignment = settings.textAlignment;
	TextStyle.bUseCaps = False;

	return self;
}

function Update(KillCounter_Settings newSettings)
{
	local bool ShowTotal, ShowActive, SkipTurrets;
	local int killed, active, total;

	settings = newSettings;

	self.SetAnchor(settings.BoxAnchor);
	self.SetPosition(settings.OffsetX, settings.OffsetY); 

	ShowTotal = class'KillCounter_Utils'.static.ShouldDrawTotalCount();
	ShowActive = class'KillCounter_Utils'.static.ShouldDrawActiveCount();
	SkipTurrets = class'KillCounter_Utils'.static.ShouldSkipTurrets();

	killed = class'KillCounter_Utils'.static.GetKilledEnemies(LastIndex, SkipTurrets);
	active = ShowActive ? class'KillCounter_Utils'.static.GetActiveEnemies(LastIndex, SkipTurrets) : -1;
	total = ShowTotal ? class'KillCounter_Utils'.static.GetTotalEnemies(SkipTurrets) : -1;

	TextStyle.Alignment = settings.textAlignment;

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
	LastIndex = -1;
}