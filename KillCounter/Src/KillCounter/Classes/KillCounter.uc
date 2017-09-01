class KillCounter extends UIScreenListener implements(X2VisualizationMgrObserverInterface);

var int LastRealizedIndex;

event OnInit(UIScreen Screen)
{	
	// For some unknown reason LastRealizedIndex can't be just set to
	// `defaults.LastRealizedIndex`; I assume the default value got somehow
	// overwritten during the reinit of screens. Having -1 hardcoded solves
	// any "the UI doesn't update" issues I have seen so far.
	LastRealizedIndex = -1;

	RegisterEvents();

	// A call to GetUI will initialize the UI if it isn't already. This
	// fixes a bug where the UI isn't shown after a savegame load in tactical.
	class'KillCounter_Utils'.static.GetUI();
}

event OnRemoved(UIScreen Screen)
{
	UnregisterEvents();
	DestroyUI();
}

event OnVisualizationBlockComplete(XComGameState AssociatedGameState)
{
	local int index;
	index = `XCOMVISUALIZATIONMGR.LastStateHistoryVisualized;

	if(index > LastRealizedIndex) {
		UpdateUI(index);
		LastRealizedIndex = index;
	}
}

event OnVisualizationIdle();

event OnActiveUnitChanged(XComGameState_Unit NewActiveUnit);

function RegisterEvents()
{
	`XCOMVISUALIZATIONMGR.RegisterObserver(self);
}

function UnregisterEvents()
{
	`XCOMVISUALIZATIONMGR.RemoveObserver(self);
}

function DestroyUI()
{
	local KillCounter_UI ui;
	ui = class'KillCounter_Utils'.static.GetUI();
	if(ui == none)
	{
		return;
	}

	ui.Remove();
}

function UpdateUI(int historyIndex)
{
	local KillCounter_UI ui;
	ui = class'KillCounter_Utils'.static.GetUI(); 
	if(ui == none)
	{
		return;
	}

	ui.Update(historyIndex);
}

defaultproperties
{
	ScreenClass = class'UITacticalHUD';
	LastRealizedIndex = -1;
}