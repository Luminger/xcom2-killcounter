//---------------------------------------------------------------------------------------
//  FILE:    X2TargetingMethod_Grenade.uc
//  AUTHOR:  David Burchanowski  --  8/04/2014
//  PURPOSE: Targeting method for throwing grenades and other such bouncy objects
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2TargetingMethod_Grenade extends X2TargetingMethod
	native(Core);

var protected XCom3DCursor Cursor;
var protected XComPrecomputedPath GrenadePath;
var protected transient XComEmitter ExplosionEmitter;
var protected bool bRestrictToSquadsightRange;
var protected XComGameState_Player AssociatedPlayerState;

var bool SnapToTile;

function Init(AvailableAction InAction)
{
	local XComGameStateHistory History;
	local XComGameState_Item WeaponItem;
	local XGWeapon WeaponVisualizer;
	local float TargetingRange;
	local X2WeaponTemplate WeaponTemplate;
	local X2AbilityTarget_Cursor CursorTarget;
	local X2AbilityTemplate AbilityTemplate;

	super.Init(InAction);

	History = `XCOMHISTORY;

	AssociatedPlayerState = XComGameState_Player(History.GetGameStateForObjectID(UnitState.ControllingPlayer.ObjectID));
	`assert(AssociatedPlayerState != none);

	// determine our targeting range
	AbilityTemplate = Ability.GetMyTemplate();
	WeaponItem = Ability.GetSourceWeapon();
	TargetingRange = Ability.GetAbilityCursorRangeMeters();

	// lock the cursor to that range
	Cursor = `Cursor;
	Cursor.m_fMaxChainedDistance = `METERSTOUNITS(TargetingRange);

	CursorTarget = X2AbilityTarget_Cursor(Ability.GetMyTemplate().AbilityTargetStyle);
	if (CursorTarget != none)
		bRestrictToSquadsightRange = CursorTarget.bRestrictToSquadsightRange;

	// show the grenade path
	WeaponTemplate = X2WeaponTemplate(WeaponItem.GetMyTemplate());
	WeaponVisualizer = XGWeapon(WeaponItem.GetVisualizer());

	// Tutorial Band-aid fix for missing visualizer due to cheat GiveItem
	if (WeaponVisualizer == none)
	{
		class'XGItem'.static.CreateVisualizer(WeaponItem);
		WeaponVisualizer = XGWeapon(WeaponItem.GetVisualizer());
		WeaponVisualizer.CreateEntity(WeaponItem);

		if (XComWeapon(WeaponVisualizer.m_kEntity) != none)
		{
			XComWeapon(WeaponVisualizer.m_kEntity).m_kPawn = FiringUnit.GetPawn();
		}
	}

	// Tutorial Band-aid #2 - Should look at a proper fix for this
	if (XComWeapon(WeaponVisualizer.m_kEntity).m_kPawn == none)
	{
		XComWeapon(WeaponVisualizer.m_kEntity).m_kPawn = FiringUnit.GetPawn();
	}

	if (UseGrenadePath())
	{
		GrenadePath = `PRECOMPUTEDPATH;
		GrenadePath.ClearOverrideTargetLocation(); // Clear this flag in case the grenade target location was locked.
		GrenadePath.ActivatePath(WeaponVisualizer.GetEntity(), FiringUnit.GetTeam(), WeaponTemplate.WeaponPrecomputedPathData);
		if( X2TargetingMethod_MECMicroMissile(self) != none )
		{
			//Explicit firing socket name for the Micro Missile, which is defaulted to gun_fire
			GrenadePath.SetFiringFromSocketPosition(name("gun_fire"));
		}
	}	

	if (!AbilityTemplate.SkipRenderOfTargetingTemplate)
	{
		// setup the blast emitter
		ExplosionEmitter = `BATTLE.spawn(class'XComEmitter');
		if(AbilityIsOffensive)
		{
			ExplosionEmitter.SetTemplate(ParticleSystem(DynamicLoadObject("UI_Range.Particles.BlastRadius_Shpere", class'ParticleSystem')));
		}
		else
		{
			ExplosionEmitter.SetTemplate(ParticleSystem(DynamicLoadObject("UI_Range.Particles.BlastRadius_Shpere_Neutral", class'ParticleSystem')));
		}
		
		ExplosionEmitter.LifeSpan = 60 * 60 * 24 * 7; // never die (or at least take a week to do so)
	}
}

function Canceled()
{
	super.Canceled();

	// unlock the 3d cursor
	Cursor.m_fMaxChainedDistance = -1;

	// clean up the ui
	ExplosionEmitter.Destroy();
	if (UseGrenadePath())
	{
		GrenadePath.ClearPathGraphics();
	}	
	ClearTargetedActors();
}

function Committed()
{
	Canceled();
}

simulated protected function Vector GetSplashRadiusCenter()
{
	local vector Center;
	local TTile SnapTile;

	if (UseGrenadePath())
		Center = GrenadePath.GetEndPosition();
	else
		Center = Cursor.GetCursorFeetLocation();

	if (SnapToTile)
	{
		SnapTile = `XWORLD.GetTileCoordinatesFromPosition( Center );
		`XWORLD.GetFloorPositionForTile( SnapTile, Center );
	}

	return Center;
}

simulated protected function DrawSplashRadius()
{
	local Vector Center;
	local float Radius;
	local LinearColor CylinderColor;

	Center = GetSplashRadiusCenter();
	Radius = Ability.GetAbilityRadius();
	
	/*
	if (!bValid || (m_bTargetMustBeWithinCursorRange && (fTest >= fRestrictedRange) )) {
		CylinderColor = MakeLinearColor(1, 0.2, 0.2, 0.2);
	} else if (m_iSplashHitsFriendliesCache > 0 || m_iSplashHitsFriendlyDestructibleCache > 0) {
		CylinderColor = MakeLinearColor(1, 0.81, 0.22, 0.2);
	} else {
		CylinderColor = MakeLinearColor(0.2, 0.8, 1, 0.2);
	}
	*/

	if(ExplosionEmitter != none)
	{
		ExplosionEmitter.SetLocation(Center); // Set initial location of emitter
		ExplosionEmitter.SetDrawScale(Radius / 48.0f);
		ExplosionEmitter.SetRotation( rot(0,0,1) );

		if( !ExplosionEmitter.ParticleSystemComponent.bIsActive )
		{
			ExplosionEmitter.ParticleSystemComponent.ActivateSystem();			
		}

		ExplosionEmitter.ParticleSystemComponent.SetMICVectorParameter(0, Name("RadiusColor"), CylinderColor);
		ExplosionEmitter.ParticleSystemComponent.SetMICVectorParameter(1, Name("RadiusColor"), CylinderColor);
	}
}

function Update(float DeltaTime)
{
	local array<Actor> CurrentlyMarkedTargets;
	local vector NewTargetLocation;
	local array<TTile> Tiles;

	NewTargetLocation = GetSplashRadiusCenter();

	if(NewTargetLocation != CachedTargetLocation)
	{		
		GetTargetedActors(NewTargetLocation, CurrentlyMarkedTargets, Tiles);
		CheckForFriendlyUnit(CurrentlyMarkedTargets);	
		MarkTargetedActors(CurrentlyMarkedTargets, (!AbilityIsOffensive) ? FiringUnit.GetTeam() : eTeam_None );
		DrawSplashRadius();
		DrawAOETiles(Tiles);
	}

	super.Update(DeltaTime);
}

function GetTargetLocations(out array<Vector> TargetLocations)
{
	TargetLocations.Length = 0;
	TargetLocations.AddItem(GetSplashRadiusCenter());
}

function name ValidateTargetLocations(const array<Vector> TargetLocations)
{
	local TTile TestLoc;
	if (TargetLocations.Length == 1)
	{
		if (bRestrictToSquadsightRange)
		{
			TestLoc = `XWORLD.GetTileCoordinatesFromPosition(TargetLocations[0]);
			if (!class'X2TacticalVisibilityHelpers'.static.CanSquadSeeLocation(AssociatedPlayerState.ObjectID, TestLoc))
				return 'AA_NotVisible';
		}
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
	Ability.GatherAdditionalAbilityTargetsForLocation(GetSplashRadiusCenter(), AdditionalTargets);
	return true;
}

function bool GetCurrentTargetFocus(out Vector Focus)
{
	Focus = GetSplashRadiusCenter();
	return true;
}

static function bool UseGrenadePath() { return true; }

static function name GetProjectileTimingStyle()
{
	if( UseGrenadePath() )
	{
		return default.ProjectileTimingStyle;
	}

	return '';
}

static function name GetOrdnanceType()
{
	if( UseGrenadePath() )
	{
		return default.OrdnanceTypeName;
	}

	return '';
}

defaultproperties
{
	SnapToTile = true;
	ProjectileTimingStyle="Timing_Grenade"
	OrdnanceTypeName="Ordnance_Grenade"
}