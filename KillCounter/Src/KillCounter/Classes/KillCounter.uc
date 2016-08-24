class KillCounter extends UIScreenListener config(KillCounter);

var config bool neverShowEnemyTotal;
var bool ShowTotal;

event OnInit(UIScreen Screen)
{
	ShowTotal = ShouldDrawShadowInfo();
	RegisterEvents();
	UpdateUI();
}

event OnReceiveFocus(UIScreen Screen)
{
	UpdateUI();
}

event OnRemoved(UIScreen Screen)
{
	UnregisterEvents();
	DestroyUI();
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

function KillCounter_UI GetUI()
{
	local UIScreen hud;
	local KillCounter_UI ui;

	hud = `PRES.GetTacticalHUD();
	ui = KillCounter_UI(hud.GetChild('KillCounter_UI'));

	if(ui == none)
	{
		ui = hud.Spawn(class'KillCounter_UI', hud);
		ui.InitPanel('KillCounter_UI');
	}

	return ui;
}

function DestroyUI()
{
	local KillCounter_UI ui;
	ui = GetUI();
	ui.Remove();
}

function UpdateUI()
{
	local int killed, total;
	local KillCounter_UI ui;
	
	ui = GetUI(); 

	killed = GetKilledEnemies();

	if(ShowTotal)
	{
		total = GetTotalEnemies();
	}
	else
	{
		total = -1;
	}

	ui.UpdateText(killed, total);
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