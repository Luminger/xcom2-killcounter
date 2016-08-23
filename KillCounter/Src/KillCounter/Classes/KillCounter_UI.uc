class KillCounter_UI extends UIPanel config(KillCounter);

// Borrowed from: UIMissionSummary.uc (strings can be found in XComGame.[LANG]
var localized string m_strEnemiesKilledLabel;

var UIText Text;

simulated function UIPanel InitPanel(optional name InitName, optional name InitLibID)
{
	super.InitPanel(InitName, InitLibID);
	self.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_RIGHT);
	self.SetPosition(-250, 55);
	self.SetSize(250, 55);

	Text = Spawn(class'UIText', self);
	Text.InitText('KillCounter_Text');

	return self;
}

function UpdateText(int killed, int total)
{
	local string Value;
	Value = m_strEnemiesKilledLabel;
	Value @= string(killed);

	if(total != -1)
	{
		Value $= "/" $ string(total);
	}

	Value = class'UIUtilities_Text'.static.StyleText(Value, eUITextStyle_Body);
	Text.SetCenteredText(Value, self);
}