class X2Effect_GetOverHere extends X2Effect;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit SourceUnitState, TargetUnitState;
	local XComGameStateHistory History;
	local XComWorldData World;
	local TTIle TeleportToTile;
	local Vector PrefferedDirection;
	local X2EventManager EventManager;

	History = `XCOMHISTORY;
	World = `XWORLD;

	SourceUnitState = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParameters.SourceStateObjectRef.ObjectID));
	`assert(SourceUnitState != none);
	TargetUnitState = XComGameState_Unit(kNewTargetState);
	`assert(TargetUnitState != none);

	PrefferedDirection = Normal(World.GetPositionFromTileCoordinates(TargetUnitState.TileLocation) - World.GetPositionFromTileCoordinates(SourceUnitState.TileLocation));

	if (SourceUnitState.FindAvailableNeighborTileWeighted(PrefferedDirection, TeleportToTile))
	{
		EventManager = `XEVENTMGR;

		// Move the target to this space
		TargetUnitState.SetVisibilityLocation(TeleportToTile);

		EventManager.TriggerEvent('ObjectMoved', TargetUnitState, TargetUnitState, NewGameState);
		EventManager.TriggerEvent('UnitMoveFinished', TargetUnitState, TargetUnitState, NewGameState);
	}
}

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, name EffectApplyResult)
{
	local XComGameState_Unit TargetUnitState;
	local vector NewUnitLoc;
	local X2Action_ViperGetOverHereTarget GetOverHereTarget;
	local X2Action_ApplyWeaponDamageToUnit UnitAction;

	TargetUnitState = XComGameState_Unit(BuildTrack.StateObject_NewState);
	`assert(TargetUnitState != none);
	
	// Move the target to this space
	if( EffectApplyResult == 'AA_Success' )
	{
		GetOverHereTarget = X2Action_ViperGetOverHereTarget(class'X2Action_ViperGetOverHereTarget'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
		NewUnitLoc = `XWORLD.GetPositionFromTileCoordinates(TargetUnitState.TileLocation);
		GetOverHereTarget.SetDesiredLocation(NewUnitLoc, XGUnit(BuildTrack.TrackActor));
	}
	else
	{
		UnitAction = X2Action_ApplyWeaponDamageToUnit(class'X2Action_ApplyWeaponDamageToUnit'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
		UnitAction.OriginatingEffect = self;
	}
} 