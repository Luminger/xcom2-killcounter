class KillCounter extends UIScreenListener config(KillCounter);

var config bool neverShowEnemyTotal;
var config bool neverShowActiveEnemyCount;
var config bool alwaysShowEnemyTotal;
var config bool showRemainingInsteadOfTotal;

var bool ShowTotal;
var bool ShowActive;
var bool ShowRemaining;

event OnInit(UIScreen Screen)
{
	ShowTotal = ShouldDrawTotalCount();
	ShowActive = ShouldDrawActiveCount();
	ShowRemaining = ShouldDrawRemainingCount();

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

	EventManager.RegisterForEvent(ThisObj, 'OnSpawnReinforcementsComplete', OnReEvaluationEvent, ELD_OnVisualizationBlockStarted);
	EventManager.RegisterForEvent(ThisObj, 'ScamperBegin', OnReEvaluationEvent, ELD_OnVisualizationBlockStarted);
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
	local int killed, total, active;
	local KillCounter_UI ui;
	
	ui = GetUI(); 

	killed = class'KillCounter_Utils'.static.GetKilledEnemies();
	active = ShowActive ? class'KillCounter_Utils'.static.GetActiveEnemies() : -1;
	total = ShowTotal ? class'KillCounter_Utils'.static.GetTotalEnemies() : -1;

	ui.UpdateText(killed, total, active, ShowRemaining);
}

function bool ShouldDrawTotalCount()
{
	if(alwaysShowEnemyTotal)
	{
		return true;
	}
	else if(neverShowEnemyTotal) 
	{
		return false;
	} 

	return class'KillCounter_Utils'.static.IsShadowChamberBuild();
}

function bool ShouldDrawActiveCount()
{
	return !neverShowActiveEnemyCount;
}

function bool ShouldDrawRemainingCount()
{
	return showRemainingInsteadOfTotal;
}

defaultproperties
{
	ScreenClass = class'UITacticalHUD';
	ShowTotal = false;
	ShowActive = true;
	ShowRemaining = true;
}