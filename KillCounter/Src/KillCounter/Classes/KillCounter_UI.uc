class KillCounter_UI extends UIPanel;

var localized string strKilled;
var localized string strActive;
var localized string strTotal;
var localized string strRemaining;

var KillCounter_Settings settings;

var UIText Text;
var UITextStyleObject TextStyle;

var int LastKilled;
var int LastTotal;
var int LastActive;
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
	settings = newSettings;

	self.SetAnchor(settings.BoxAnchor);
	self.SetPosition(settings.OffsetX, settings.OffsetY); 

	UpdateText();
}

function UpdateText(optional int killed = LastKilled, optional int total = LastTotal, optional int active = LastActive, optional int historyIndex = LastIndex)
{
	local string Value;
	local bool ShowTotal, ShowActive, SkipTurrets;

	if(Text == none)
	{
		return;
	}

	if(total == LastTotal || active == LastActive || killed == LastKilled || TextStyle.Alignment != settings.textAlignment)
	{
		ShowTotal = class'KillCounter_Utils'.static.ShouldDrawTotalCount();
		ShowActive = class'KillCounter_Utils'.static.ShouldDrawActiveCount();
		SkipTurrets = class'KillCounter_Utils'.static.ShouldSkipTurrets();

		killed = class'KillCounter_Utils'.static.GetKilledEnemies(historyIndex, SkipTurrets);
		active = ShowActive ? class'KillCounter_Utils'.static.GetActiveEnemies(historyIndex, SkipTurrets) : -1;
		total = ShowTotal ? class'KillCounter_Utils'.static.GetTotalEnemies(SkipTurrets) : -1;

		TextStyle.Alignment = settings.textAlignment;
	}

	LastKilled = killed;
	LastTotal = total;
	LastActive = active;
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
	LastTotal = -1;
	LastActive = -1;
	LastIndex = -1;
}