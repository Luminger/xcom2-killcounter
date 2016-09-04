class KillCounter_UI extends UIPanel config(KillCounter);

var localized string strKilled;
var localized string strActive;
var localized string strTotal;
var localized string strRemaining;

var config bool noColor;
var config string textAlignment;
var config int BoxAnchor;
var config int OffsetX;
var config int OffsetY;

var UIText Text;
var UITextStyleObject TextStyle;

simulated function UIPanel InitPanel(optional name InitName, optional name InitLibID)
{
	super.InitPanel(InitName, InitLibID);
	self.SetAnchor(BoxAnchor);
	self.SetSize(350, 50);
	self.SetPosition(OffsetX, OffsetY); 

	Text = Spawn(class'UIText', self);
	Text.InitText('KillCounter_Text');
	Text.SetSize(Width, Height);

	class'KillCounter_Utils'.static.ShadowToTextField(Text);

	TextStyle = class'UIUtilities_Text'.static.GetStyle(eUITextStyle_Tooltip_H2);
	TextStyle.Alignment = textAlignment;
	TextStyle.bUseCaps = False;

	return self;
}

function UpdateText(int killed, int total, int active, bool showRemaining)
{
	local string Value;

	if(Text == none)
	{
		return;
	}

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

	Text.SetHtmlText(class'UIUtilities_Text'.static.ApplyStyle(Value, TextStyle));
}

function string AddColor(int value, int clr)
{
	if(noColor)
	{
		return string(value);
	}

	return class'UIUtilities_Text'.static.GetColoredText(string(value), clr);
}