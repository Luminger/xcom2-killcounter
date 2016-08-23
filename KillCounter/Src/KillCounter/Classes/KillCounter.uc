class KillCounter extends UIScreenListener config(KillCounter);

var config bool neverShowEnemyTotal;

// Borrowed from: UIMissionSummary.uc (strings can be found in XComGame.[LANG]
var localized string m_strEnemiesKilledLabel;

var UIText Text;
var UIPanel Panel;
var bool ShowTotal;

event OnInit(UIScreen Screen)
{
	ShowTotal = ShouldDrawShadowInfo();

	RegisterEvents();
	CreateUI(Screen);
	UpdateText();
}


event OnReceiveFocus(UIScreen Screen)
{
	UpdateText();
}

function EventListenerReturn OnReEvaluationEvent(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	UpdateText();

	return ELR_NoInterrupt;
}

function RegisterEvents()
{
	local X2EventManager EventManager;
	local Object ThisObj;

	EventManager = `XEVENTMGR;
	ThisObj = self;

	// If there's no ShadowChamber then there's no need to trigger as we won't show the value anyway
	if(ShowTotal)
	{
		// Rerendering on 'ScamperBegin' should allow us to update the total in case it got updated (reinforcements, etc.)
		EventManager.RegisterForEvent(ThisObj, 'UnitSpawned', OnReEvaluationEvent, ELD_OnVisualizationBlockStarted);
	}

	EventManager.RegisterForEvent(ThisObj, 'UnitDied', OnReEvaluationEvent, ELD_OnVisualizationBlockStarted);
}

function CreateUI(UIScreen Screen)
{
	Panel = Screen.Spawn(class'UIPanel', Screen);
	Panel.InitPanel('KillCounter_UIPanel');
	Panel.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_RIGHT);
	Panel.SetPosition(-250, 55);
	Panel.SetSize(250, 55);

	Text = Panel.Spawn(class'UIText', Panel);
	Text.InitText('KillCounter_Text');

	UpdateText();
}

function UpdateText()
{
	local string Value;
	Value = m_strEnemiesKilledLabel;
	//Value @= class'UIUtilities_Text'.static.GetColoredText(string(GetKilledEnemies()), eUIState_Warning2);
	Value @= string(GetKilledEnemies());

	if(ShowTotal)
	{
		Value $= "/";
		//Value $= class'UIUtilities_Text'.static.GetColoredText(string(GetTotalEnemies()), eUIState_Warning2);
		Value $= string(GetTotalEnemies());
	}

	Value = class'UIUtilities_Text'.static.StyleText(Value, eUITextStyle_Body);

	Text.SetCenteredText(Value, Panel);
	//Text.SetHtmlText(Value);
}

function bool ShouldDrawShadowInfo()
{
	local XComGameState_HeadquartersXCom XComHQ;

	// Don't even look after the ShadowChamber, we just don't show it
	if(neverShowEnemyTotal) {
		return false;
	}

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	return XComHQ.GetFacilityByName('ShadowChamber') != none;
}

function int GetTotalEnemies()
{
	local array<XComGameState_Unit> arrUnits;
	local XGBattle_SP Battle;

	Battle = XGBattle_SP(`BATTLE);
	Battle.GetAIPlayer().GetOriginalUnits(arrUnits, true);

	return arrUnits.Length;
}

function int GetKilledEnemies()
{
	local int iKilled;
	local array<XComGameState_Unit> arrUnits;
	local XComGameState_Unit arrUnit;
	local XGBattle_SP Battle;

	Battle = XGBattle_SP(`BATTLE);
	Battle.GetAIPlayer().GetOriginalUnits(arrUnits, true);

	ForEach arrUnits(arrUnit) {
		if(arrUnit.IsDead()) {
			iKilled++;
		}
	}

	return iKilled;
}

defaultproperties
{
	ScreenClass = class'UITacticalHUD';
}