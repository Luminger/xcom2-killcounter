class X2Effect_GenerateCover extends X2Effect_Persistent
	dependson(XComCoverInterface);

var ECoverForceFlag CoverType;

function RegisterForEvents(XComGameState_Effect EffectGameState)
{
	local X2EventManager EventMgr;
	local XComGameState_Unit UnitState;
	local Object EffectObj;

	EventMgr = `XEVENTMGR;
	EffectObj = EffectGameState;
	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(EffectGameState.ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	EventMgr.RegisterForEvent(EffectObj, 'ObjectMoved', EffectGameState.GenerateCover_ObjectMoved, ELD_OnStateSubmitted, , UnitState);
	EventMgr.RegisterForEvent(EffectObj, 'AbilityActivated', EffectGameState.GenerateCover_AbilityActivated, ELD_OnStateSubmitted, , UnitState);
}

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(kNewTargetState);
	if (UnitState != None)
	{
		UnitState.bGeneratesCover = true;
		UnitState.CoverForceFlag = CoverType;
	}
	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);
}

simulated function OnEffectRemoved(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed, XComGameState_Effect RemovedEffectState)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if (UnitState != None)
	{
		UnitState = XComGameState_Unit(NewGameState.CreateStateObject(UnitState.Class, UnitState.ObjectID));
		UnitState.bGeneratesCover = false;
		UnitState.CoverForceFlag = CoverForce_Default;
		NewGameState.AddStateObject(UnitState);
	}

	super.OnEffectRemoved(ApplyEffectParameters, NewGameState, bCleansed, RemovedEffectState);
}

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, name EffectApplyResult)
{
	super.AddX2ActionsForVisualization(VisualizeGameState, BuildTrack, EffectApplyResult);
	UpdateWorldCoverData(XComGameState_Unit(BuildTrack.StateObject_NewState), XComGameState_Unit(BuildTrack.StateObject_OldState));
}

simulated function AddX2ActionsForVisualization_Removed(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, const name EffectApplyResult, XComGameState_Effect RemovedEffect)
{
	super.AddX2ActionsForVisualization_Removed(VisualizeGameState, BuildTrack, EffectApplyResult, RemovedEffect);
	UpdateWorldCoverData(XComGameState_Unit(BuildTrack.StateObject_NewState), XComGameState_Unit(BuildTrack.StateObject_OldState));
}

protected function UpdateWorldCoverData(XComGameState_Unit NewUnitState, XComGameState_Unit OldUnitState)
{
	DoRebuildTile(NewUnitState.TileLocation);
	DoRebuildTile(OldUnitState.TileLocation);
}

protected function DoRebuildTile(const out TTile OriginalTile)
{
	local XComWorldData WorldData;
	local TTile RebuildTile;
	local array<TTile> ChangeTiles;
	local StateObjectReference UnitRef;
	local XGUnit Unit;
	local CachedCoverAndPeekData CachedData;

	WorldData = `XWORLD;

	RebuildTile = OriginalTile;
	RebuildTile.X -= 1;
	ChangeTiles.AddItem( RebuildTile );
	RebuildTile.X += 2;
	ChangeTiles.AddItem( RebuildTile );

	RebuildTile = OriginalTile;
	RebuildTile.Y -= 1;
	ChangeTiles.AddItem( RebuildTile );
	RebuildTile.Y += 2;
	ChangeTiles.AddItem( RebuildTile );

	foreach ChangeTiles(RebuildTile)
	{
		WorldData.DebugRebuildTileData( RebuildTile );

		UnitRef = WorldData.GetUnitOnTile( RebuildTile );
		if (UnitRef.ObjectID > 0)
		{
			Unit = XGUnit( `XCOMHISTORY.GetVisualizer( UnitRef.ObjectId ) );
			if (Unit != none)
			{
				WOrldData.CacheVisibilityDataForTile( RebuildTile, CachedData );
				Unit.IdleStateMachine.CheckForStanceUpdate();
			}
		}
	}
}

DefaultProperties
{
	CoverType = CoverForce_High
	EffectName = "GenerateCover"
	DuplicateResponse = eDupe_Ignore
}