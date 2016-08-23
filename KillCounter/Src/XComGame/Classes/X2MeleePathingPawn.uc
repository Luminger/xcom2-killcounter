//---------------------------------------------------------------------------------------
//  FILE:    X2MeleePathingPath.uc
//  AUTHOR:  David Burchanowski  --  2/10/2014
//  PURPOSE: Specialized pathing pawn for activated melee pathing. Draws tiles around every unit the 
//           currently selected ability can melee from, and allows the user to select one to move there.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2MeleePathingPawn extends XComPathingPawn
	native(Unit);

var private XComGameState_Unit UnitState; // The unit we are currently using
var private XComGameState_Ability AbilityState; // The ability we are currently using

function Init(XComGameState_Unit InUnitState, XComGameState_Ability InAbilityState)
{
	super.SetActive(XGUnitNativeBase(InUnitState.GetVisualizer()));

	UnitState = InUnitState;
	AbilityState = InAbilityState;
}

simulated function SetActive(XGUnitNativeBase kActiveXGUnit, optional bool bCanDash, optional bool bObeyMaxCost)
{
	`assert(false); // call Init() instead
}

// disable the built in pathing melee targeting.
simulated protected function bool CanUnitMeleeFromMove(XComGameState_BaseObject TargetObject, out XComGameState_Ability MeleeAbility)
{
	return false;
}

function GetTargetMeleePath(out array<TTile> OutPathTiles)
{
	OutPathTiles = PathTiles;
}

// overridden to always just show the slash UI, regardless of cursor location or other considerations
simulated protected function UpdatePuckVisuals(XComGameState_Unit ActiveUnitState, 
												const out TTile PathDestination, 
												Actor TargetActor,
												X2AbilityTemplate MeleeAbilityTemplate)
{
	local XComWorldData WorldData;
	local vector MeshTranslation;
	local Rotator MeshRotation;	
	local vector MeshScale;
	local vector FromTargetTile;

	WorldData = `XWORLD;

	MeshTranslation = TargetActor.Location + TargetActor.WorldSpaceOffset;
	MeshTranslation.Z = WorldData.GetFloorZForPosition(MeshTranslation) + PathHeightOffset;

	// when slashing, we will technically be out of range. 
	// hide the out of range mesh, show melee mesh
	OutOfRangeMeshComponent.SetHidden(true);
	SlashingMeshComponent.SetHidden(false);
	SlashingMeshComponent.SetTranslation(MeshTranslation);

	// rotate the mesh to face the thing we are slashing
	FromTargetTile = WorldData.GetPositionFromTileCoordinates(PathDestination) - MeshTranslation; 
	MeshRotation.Yaw = atan2(FromTargetTile.Y, FromTargetTile.X) * RadToUnrRot;
		
	// snap rotation to 45 degree increments
	MeshRotation.Yaw -= MeshRotation.Yaw % (45 * DegToUnrRot);
	SlashingMeshComponent.SetRotation(MeshRotation);

	// the normal puck is always visible, and located wherever the unit
	// will actually move to when he executes the move
	PuckMeshComponent.SetHidden(false);
	PuckMeshComponent.SetStaticMeshes(GetMeleePuckMeshForAbility(MeleeAbilityTemplate), PuckMeshConfirmed);
	if (IsDashing() || ActiveUnitState.NumActionPointsForMoving() == 1)
	{
		RenderablePath.SetMaterial(PathMaterialDashing);
	}
		
	MeshTranslation = VisualPath.GetEndPoint(); // make sure we line up perfectly with the end of the path ribbon
	MeshTranslation.Z = WorldData.GetFloorZForPosition(MeshTranslation) + PathHeightOffset;
	PuckMeshComponent.SetTranslation(MeshTranslation);

	MeshScale.X = ActiveUnitState.UnitSize;
	MeshScale.Y = ActiveUnitState.UnitSize;
	MeshScale.Z = 1.0f;
	PuckMeshComponent.SetScale3D(MeshScale);
}

simulated function UpdateMeleeTarget(XComGameState_BaseObject Target)
{
	local X2AbilityTemplate AbilityTemplate;
	local array<TTile> DestinationTiles;

	if(Target == none)
	{
		`Redscreen("X2MeleePathingPawn::UpdateMeleeTarget: Target is none!");
		return;
	}

	AbilityTemplate = AbilityState.GetMyTemplate();
	if(class'X2AbilityTarget_MovingMelee'.static.SelectAttackTile(UnitState, Target, AbilityTemplate, DestinationTiles))
	{
		RebuildPathingInformation(DestinationTiles[0], Target.GetVisualizer(), AbilityTemplate);
	}
}

simulated event Tick(float DeltaTime)
{
	// we don't need to tick, we'll update the pathing stuff manually with UpdateMeleeTarget when the target changes
}

// don't update objective tiles
function UpdateObjectiveTiles(XComGameState_Unit InActiveUnitState);

defaultproperties
{
}