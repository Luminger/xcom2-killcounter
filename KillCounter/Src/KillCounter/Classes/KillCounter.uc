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

var int LastKilled;
var int LastActive;
var int LastTotal;

var int LastRealizedIndex;
var array<int> MissingGameStates;
var int HighestMissingIndex;
var int HighestSeenIndex;

event OnInit(UIScreen Screen)
{
	//local XComGameState gameState;

	ShowTotal = ShouldDrawTotalCount();
	ShowActive = ShouldDrawActiveCount();
	ShowRemaining = ShouldDrawRemainingCount();
	SkipTurrets = ShouldSkipTurrets();
	//LastRealizedIndex = `XCOMHISTORY.GetCurrentHistoryIndex();
	//HighestSeenGameState = LastRealizedIndex;

	RegisterEvents();
	//gameState = `XCOMHISTORY.GetGameStateFromHistory(LastRealizedIndex, eReturnType_Copy, false);
	//UpdateUI(gameState);
}

event OnRemoved(UIScreen Screen)
{
	UnregisterEvents();
	DestroyUI();
}

event OnVisualizationBlockComplete(XComGameState AssociatedGameState)
{
	local XComGameState usedGameState;
	local int logIndex;
	local bool useIndex;

	useIndex = ShouldGivenGameStateBeUsed(AssociatedGameState.HistoryIndex);

	`log("GivenIndex: " @ string(AssociatedGameState.HistoryIndex));
	`log("Result: " @ string(useIndex));
	`log("LastRealizedIndex: " @ string(LastRealizedIndex));
	`log("MissingGameStates: ");
	ForEach MissingGameStates(logIndex)
	{
		`log(" => " @ string(logIndex));
	}
	`log("HighestSeenIndex: " @ string(HighestSeenIndex));
	`log("HighestMissingIndex: " @ string(HighestMissingIndex));

	if(!useIndex)
	{
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

function bool ShouldGivenGameStateBeUsed(int index)
{
	local int missing;
	local int pos;

	if(index == 0)
	{
		return false;
	}

	pos = MissingGameStates.Find(index);
	if(pos != INDEX_NONE)
	{
		MissingGameStates.Remove(pos, 1);
	}

	if(index == LastRealizedIndex + 1 || LastRealizedIndex == -1)
	{
		LastRealizedIndex = index;
		HighestSeenIndex = index;
		return true;
	}

	if(index > HighestSeenIndex)
	{
		HighestSeenIndex = index;
	}

	if(index > HighestMissingIndex)
	{
		if(HighestMissingIndex == -1)
		{
			HighestMissingIndex = LastRealizedIndex;
		}

		for(missing = HighestMissingIndex + 1; missing < index; missing++)
		{
			if(!IsGameStateInterrupted(missing))
			{
				MissingGameStates.AddItem(missing);
			}
		}

		HighestMissingIndex = index;
	}

	if(MissingGameStates.Length == 0)
	{
		return true;
	}

	return false;
}

function bool IsGameStateInterrupted(int index)
{
	local XComGameState gameState;
	local XComGameStateContext context;

	gameState = `XCOMHISTORY.GetGameStateFromHistory(index);
	if(gameState == none)
	{
		return true;
	}

	context = gameState.GetContext();
	if(context == none)
	{
		return true;
	}

	`log("Index: " @ string(index) @ " State: " @ string(context.InterruptionStatus));
	`log("Index: " @ string(index) @ " is a '" @ string(context.Class) @ "'");
	`log("Index: " @ string(index) @ " => " @ context.SummaryString());
	`log("Index: " @ string(index) @ " => " @ context.VerboseDebugString());
	return context.InterruptionStatus == eInterruptionStatus_Interrupt;
}

event OnVisualizationIdle()
{
	local XComGameState gameState;
	local int index;
	local bool ret;

	ForEach MissingGameStates(index)
	{
		ret = IsGameStateInterrupted(index);
	}
	return;

	LastRealizedIndex = -1;
	HighestMissingIndex = -1;
	HighestSeenIndex = -1;
	MissingGameStates.Length = 0;

	index = `XCOMHISTORY.GetCurrentHistoryIndex();
	if (LastRealizedIndex != index)
	{
		gameState = `XCOMHISTORY.GetGameStateFromHistory(index, eReturnType_Copy, false);
		UpdateUI(gameState);
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
	LastKilled = -1;
	LastActive = -1;
	LastTotal = -1;
	LastRealizedIndex = -1;
	HighestMissingIndex = -1;
	HighestSeenIndex = -1;
}