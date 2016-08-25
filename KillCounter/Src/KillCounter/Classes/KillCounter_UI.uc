class KillCounter_UI extends UIPanel config(KillCounter);

var localized string strKilled;
var localized string strActive;
var localized string strTotal;
var localized string strRemaining;

var config bool neverShowActiveEnemyCount;
var config bool noColor;

var UIText Text;

simulated function UIPanel InitPanel(optional name InitName, optional name InitLibID)
{
	super.InitPanel(InitName, InitLibID);
	self.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_RIGHT);
	self.SetPosition(-360, 50);
	self.SetSize(350, 50);

	Text = Spawn(class'UIText', self);
	Text.InitText('KillCounter_Text');
	Text.SetSize(Width, Height);

	return self;
}

function UpdateText(int killed, int total, int active, bool showRemaining)
{
	local string Value;

	Value = strKilled @ AddColor(killed, eUIState_Good);

	if(active != -1)
	{
		Value @= strActive @ AddColor(active, eUIState_Warning2);
	}

	if(total != -1)
	{
		if(showRemaining)
		{
			Value @= strRemaining @ AddColor(total - killed, eUIState_Bad);
		}
		else
		{
			Value @= strTotal @ AddColor(total, eUIState_Bad);
		}
	}

	Value = class'UIUtilities_Text'.static.StyleText(Value, eUITextStyle_Tooltip_H2);
	Text.SetHtmlText(class'UIUtilities_Text'.static.AlignRight(Value));
}

function string AddColor(int value, int clr)
{
	if(noColor)
	{
		return string(value);
	}

	return class'UIUtilities_Text'.static.GetColoredText(string(value), clr);
}