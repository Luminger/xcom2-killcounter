class KillCounter extends UIScreenListener implements(X2VisualizationMgrObserverInterface) config(KillCounter);

var config bool neverShowEnemyTotal;
var config bool neverShowActiveEnemyCount;
var config bool alwaysShowEnemyTotal;
var config bool showRemainingInsteadOfTotal;
var config bool includeTurrets;

var bool ShowTotal;
var bool ShowActive;
var bool ShowRemaining;
var bool SkipTurrets;

var int LastRealizedIndex;
var int LastKilled;
var int LastActive;
var int LastTotal;

event OnInit(UIScreen Screen)
{
	local XComGameState gameState;

	ShowTotal = ShouldDrawTotalCount();
	ShowActive = ShouldDrawActiveCount();
	ShowRemaining = ShouldDrawRemainingCount();
	SkipTurrets = ShouldSkipTurrets();
	LastRealizedIndex = `XCOMHISTORY.GetCurrentHistoryIndex();

	RegisterEvents();
	gameState = `XCOMHISTORY.GetGameStateFromHistory(LastRealizedIndex, eReturnType_Copy, false);
	UpdateUI(gameState);
}

event OnRemoved(UIScreen Screen)
{
	UnregisterEvents();
	DestroyUI();
}

event OnVisualizationBlockComplete(XComGameState AssociatedGameState)
{
	local XComGameState usedGameState;

	return;

	`log("Given Index: " @ string(AssociatedGameState.HistoryIndex) @ " Last seen: " @ string(LastRealizedIndex));
	// We need a little 'wiggle' room here
	if(AssociatedGameState.HistoryIndex > LastRealizedIndex + 3)
	{
		`log("We would spoiler, don't do that!");
		return;
	}

	usedGameState = AssociatedGameState;
	if(AssociatedGameState.bIsDelta)
	{
		usedGameState = `XCOMHISTORY.GetGameStateFromHistory(AssociatedGameState.HistoryIndex, eReturnType_Copy, false);
		if (usedGameState == none)
		{
			return;
		}
	}

	`log("Updating UI...");
	UpdateUI(usedGameState);
	LastRealizedIndex = AssociatedGameState.HistoryIndex;
}

event OnVisualizationIdle()
{
	local XComGameState gameState;
	local int index;

	index = `XCOMHISTORY.GetCurrentHistoryIndex();

	if (LastRealizedIndex != index)
	{
		`log("We have to fix the shown numbers, do it!");
		gameState = `XCOMHISTORY.GetGameStateFromHistory(index, eReturnType_Copy, false);
		UpdateUI(gameState);
		LastRealizedIndex = index;
	}
}

event OnActiveUnitChanged(XComGameState_Unit NewActiveUnit);

function RegisterEvents()
{
	`XCOMVISUALIZATIONMGR.RegisterObserver(self);
}

function UnregisterEvents()
{
	`XCOMVISUALIZATIONMGR.RemoveObserver(self);
}

function KillCounter_UI GetUI()
{
	local UIScreen hud;
	local KillCounter_UI ui;

	hud = `PRES.GetTacticalHUD();
	if (hud == none)
	{
		return none;
	}

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
	if(ui == none)
	{
		return;
	}

	ui.Remove();
}

function UpdateUI(XComGameState gameState)
{
	local int killed, total, active;
	local KillCounter_UI ui;
	
	ui = GetUI(); 
	if(ui == none)
	{
		return;
	}

	killed = class'KillCounter_Utils'.static.GetKilledEnemies(gameState, SkipTurrets);
	active = ShowActive ? class'KillCounter_Utils'.static.GetActiveEnemies(gameState, SkipTurrets) : -1;
	total = ShowTotal ? class'KillCounter_Utils'.static.GetTotalEnemies(SkipTurrets) : -1;

	if (killed != LastKilled || active != LastActive || total != LastTotal)
	{
		ui.UpdateText(killed, total, active, ShowRemaining);
		
		LastKilled = killed;
		LastActive = active;
		LastTotal = total;
	}
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

function bool ShouldSkipTurrets()
{
	return !includeTurrets;
}

defaultproperties
{
	ScreenClass = class'UITacticalHUD';
	ShowTotal = false;
	ShowActive = true;
	ShowRemaining = true;
	SkipTurrets = true;
	LastRealizedIndex = -1;
	LastKilled = -1;
	LastActive = -1;
	LastTotal = -1;
}