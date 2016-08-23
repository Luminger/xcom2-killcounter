class X2TargetingMethod_Line extends X2TargetingMethod;

var protected XCom3DCursor Cursor;
var protected vector NewTargetLocation, FiringLocation;
var protected XComWorldData WorldData;
var protected bool bGoodTarget;
var protected TTile FiringTile;

var protected X2Actor_LineTarget LineActor;

function Init(AvailableAction InAction)
{
	local X2AbilityTemplate AbilityTemplate;
	local float TileLength;
	
	super.Init(InAction);
	WorldData = `XWORLD;

	AbilityTemplate = Ability.GetMyTemplate( );

	FiringTile = UnitState.TileLocation;
	FiringLocation = WorldData.GetPositionFromTileCoordinates(UnitState.TileLocation);
	FiringLocation.Z += class'XComWorldData'.const.WORLD_HalfFloorHeight;

	Cursor = `Cursor;

	if (!AbilityTemplate.SkipRenderOfTargetingTemplate)
	{
		// setup the targeting mesh
		LineActor = `BATTLE.Spawn( class'X2Actor_LineTarget' );
		TileLength = UnitState.GetCurrentStat( eStat_SightRadius ) * class'XComWorldData'.const.WORLD_METERS_TO_UNITS_MULTIPLIER / class'XComWorldData'.const.WORLD_StepSize;
		if(AbilityIsOffensive)
		{
			LineActor.MeshLocation = "UI_3D.Targeting.ConeRange";
		}
		LineActor.InitLineMesh( TileLength  );
		LineActor.SetLocation( FiringLocation );
	}
}

function Canceled()
{
	super.Canceled();
	// unlock the 3d cursor
	Cursor.m_fMaxChainedDistance = -1;

	// clean up the ui
	LineActor.Destroy();
	ClearTargetedActors();
}

function Committed()
{
	Canceled();
}

function Update(float DeltaTime)
{
	local array<Actor> CurrentlyMarkedTargets;
	local vector ShooterToTarget;
	local TTile TargetTile;
	local array<TTile> Tiles;
	local Rotator LineRotator;

	NewTargetLocation = Cursor.GetCursorFeetLocation();
	TargetTile = WorldData.GetTileCoordinatesFromPosition(NewTargetLocation);
	//NewTargetLocation = WorldData.GetPositionFromTileCoordinates(TargetTile);
	NewTargetLocation.Z = WorldData.GetFloorZForPosition(NewTargetLocation, true) + class'XComWorldData'.const.WORLD_HalfFloorHeight;

	if (TargetTile == FiringTile)
	{
		bGoodTarget = false;
		return;
	}
	bGoodTarget = true;

	if (NewTargetLocation != CachedTargetLocation)
	{
		GetTargetedActors(NewTargetLocation, CurrentlyMarkedTargets, Tiles);
		CheckForFriendlyUnit(CurrentlyMarkedTargets);	
		MarkTargetedActors(CurrentlyMarkedTargets, (!AbilityIsOffensive) ? FiringUnit.GetTeam() : eTeam_None );

		DrawAOETiles(Tiles);

		if (LineActor != none)
		{
			ShooterToTarget = NewTargetLocation - FiringLocation;
			LineRotator = rotator( ShooterToTarget );
			LineActor.SetRotation( LineRotator );
		}
	}

	super.Update(DeltaTime);
}

function GetTargetLocations(out array<Vector> TargetLocations)
{
	TargetLocations.Length = 0;
	TargetLocations.AddItem(NewTargetLocation);
}

function name ValidateTargetLocations(const array<Vector> TargetLocations)
{
	if (TargetLocations.Length == 1 && bGoodTarget)
	{
		return 'AA_Success';
	}
	return 'AA_NoTargets';
}

function int GetTargetIndex()
{
	return 0;
}

function bool GetAdditionalTargets(out AvailableTarget AdditionalTargets)
{
	Ability.GatherAdditionalAbilityTargetsForLocation(NewTargetLocation, AdditionalTargets);
	return true;
}

function bool GetCurrentTargetFocus(out Vector Focus)
{
	Focus = NewTargetLocation;
	return true;
}