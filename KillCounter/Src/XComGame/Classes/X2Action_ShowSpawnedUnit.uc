//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_ShowSpawnedUnit extends X2Action;

var bool bUseOverride;
var vector OverrideVisualizationLocation;
var Rotator OverrideFacingRot;
var bool bWaitToShow, bReceivedShowMessage;

var protected TTile		CurrentTile;

function Init(const out VisualizationTrack InTrack)
{
	local XComGameState_Unit UnitState;

	super.Init(InTrack);

	// if our visualizer hasn't been created yet, make sure it is created here.
	if (Unit == none)
	{
		UnitState = XComGameState_Unit(InTrack.StateObject_NewState);
		`assert(UnitState != none);

		UnitState.SyncVisualizer(StateChangeContext.AssociatedState);
		Unit = XGUnit(UnitState.GetVisualizer());
		`assert(Unit != none);
	}
}

function HandleTrackMessage()
{
	bReceivedShowMessage = true;
}

function bool CheckInterrupted()
{
	return false;
}

function ChangeTimeoutLength( float newTimeout )
{
	TimeoutSeconds = newTimeout;
}

simulated state Executing
{
Begin:
	// Now update the visibility
	if( bUseOverride )
	{
		OverrideVisualizationLocation.Z = Unit.GetDesiredZForLocation(OverrideVisualizationLocation);

		Unit.GetPawn().SetLocation(OverrideVisualizationLocation);
		Unit.GetPawn().SetRotation(OverrideFacingRot);
	}

	CurrentTile = `XWORLD.GetTileCoordinatesFromPosition(Unit.Location);

	UnitPawn.GetAnimTreeController().SetAllowNewAnimations(true);
	UnitPawn.RestoreAnimSetsToDefault();
	UnitPawn.UpdateAnimations();

	Unit.IdleStateMachine.PlayIdleAnim();

	while( bWaitToShow && !bReceivedShowMessage )
	{
		Sleep(0.0f);
	}

	Unit.m_bForceHidden = false;
	`TACTICALRULES.VisibilityMgr.ActorVisibilityMgr.VisualizerUpdateVisibility(Unit, CurrentTile);

	CompleteAction();
}

DefaultProperties
{
	bUseOverride=false
	bWaitToShow=false
}
