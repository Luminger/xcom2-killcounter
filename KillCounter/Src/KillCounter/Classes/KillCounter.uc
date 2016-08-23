class KillCounter extends UIScreenListener config(KillCounter);

var config bool neverShowEnemyTotal;

var KillCounter_UI UI;
var bool ShowTotal;

event OnInit(UIScreen Screen)
{
	Initialize(Screen);
}

event OnReceiveFocus(UIScreen Screen)
{
	Initialize(Screen);
}

event OnRemoved(UIScreen Screen)
{
	UnregisterEvents();
}

function Initialize(UIScreen Screen) {
	if(UI != none)
	{
		return;
	}

	ShowTotal = ShouldDrawShadowInfo();
	CreateUI(Screen);
	RegisterEvents();
	UpdateUI();
}

function EventListenerReturn OnReEvaluationEvent(Object EventData, Object EventSource, XComGameState GameState, Name EventID)
{
	UpdateUI();

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
		EventManager.RegisterForEvent(ThisObj, 'UnitSpawned', OnReEvaluationEvent, ELD_OnVisualizationBlockStarted);
	}

	EventManager.RegisterForEvent(ThisObj, 'UnitDied', OnReEvaluationEvent, ELD_OnVisualizationBlockStarted);
}

function UnregisterEvents()
{
	local X2EventManager EventManager;
	local Object ThisObj;

	EventManager = `XEVENTMGR;
	ThisObj = self;

	EventManager.UnRegisterFromAllEvents(ThisObj);
}

function CreateUI(UIScreen Screen)
{
	UI = Screen.Spawn(class'KillCounter_UI', Screen);
	UI.InitPanel('KillCounter_UI');
}

function UpdateUI()
{
	local int killed, total;

	if(UI == none)
	{
		return;
	}

	killed = GetKilledEnemies();

	if(ShowTotal)
	{
		total = GetTotalEnemies();
	}
	else
	{
		total = -1;
	}

	UI.UpdateText(killed, total);
}

function bool ShouldDrawShadowInfo()
{
	local XComGameState_HeadquartersXCom XComHQ;

	// Don't even look after the ShadowChamber, we just don't show it
	if(neverShowEnemyTotal) 
	{
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
	ForEach arrUnits(arrUnit) 
	{
		if(arrUnit.IsDead()) 
		{
			iKilled++;
		}
	}

	return iKilled;
}

defaultproperties
{
	ScreenClass = class'UITacticalHUD';
	ShowTotal = false;
}