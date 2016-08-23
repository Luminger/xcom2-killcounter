//---------------------------------------------------------------------------------------
//  FILE:    X2Action_PlayMatinee.uc
//  AUTHOR:  David Burchanowski  --  2/10/2014
//  PURPOSE: Plays a matinee in a gamestate safe manner
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2Action_PlayMatinee extends X2Action
	native(Core);

struct native UnitToMatineeGroupMapping
{
	var name GroupName; // matinee group that will control unit
	var XComGameState_Unit Unit; // a unit you want to show up in the matinee
	var bool WasUnitVisibile; // remember if the pawns we hid were visible or not before that
	var XComUnitPawnNativeBase CreatedPawn; // temporary pawn that will be used in the matinee 
	var Object ExistingMatineeObject; // object that was previously in the matinee map. Saved so we can put it back
};

struct native NonUnitToBaseMapping
{
	var Actor NonUnitActor;
	var Actor Base;
	var SkeletalMeshComponent SkelComp;
	var name AttachName;
};

// handle to the matinee we want to play
var SeqAct_Interp Matinee;

// units that will participate in this matinee, and the matinee groups that will control them
var private array<UnitToMatineeGroupMapping> UnitMappings;

// used when rebasing the matinee seqvars actors, so that they can be unrebased.
var private array<NonUnitToBaseMapping> NonUnitMappings;

// actor to use as the "base" of this matinee
var protected Actor MatineeBase;

// socket in the base actor to use, if any
var protected name MatineeBaseSocket;

// In tactical missions, we use the camera stack matinee camera to actually control the camera during playback,
// instead of the build in unreal camera takeover. This allows us to manipulate all of the other gameplay things
// that need to happen, such as cinematic mode and fow disabling, for free.
var private X2Camera_Matinee MatineeCamera;

// Whether or not we should set the base on non units
var private bool bRebaseNonUnitVariables;

var protected bool MatineeSkipped; // set to true if the matinee is skipped by the user

// wrappers to native since the matinee interfaces require native access
native private function StartMatinee();
native private function bool UpdateMatinee(float DeltaTime);
native private function ShutdownMatinee();

// creates (if needed) and sets variable links for each of the unit mappings. 
native private function LinkUnitVariablesToMatinee();

// if a matinee base is set, rebases all non-unit links to use it
native private function RebaseNonUnitVariables();

// this reverses the operations done by RebaseNonUnitVariables()
native private function UnrebaseNonUnitVariables();

// restore the previous object links
native private function UnLinkUnitVariablesFromMatinee();

function AddUnitToMatinee(name GroupName, XComGameState_Unit GameStateUnit)
{
	local UnitToMatineeGroupMapping NewMapping;

	NewMapping.GroupName = GroupName;
	NewMapping.Unit = GameStateUnit;
	UnitMappings.AddItem(NewMapping);
}

function SetMatineeLocation(Vector NewLocation, optional Rotator NewRotation)
{
	if( MatineeBase != None )
	{
		MatineeBase.SetLocation(NewLocation);
		MatineeBase.SetRotation(NewRotation);
	}
}

function SetMatineeBase(name MatineeBaseActorTag, optional name MatineeBaseSocketName = '')
{
	local SkeletalMeshActor PotentialBase;
	local Actor PotentialBaseNonSkel;

	if(MatineeBaseActorTag == '')
	{
		// no base specified, so just clear any previous one if there was one
		MatineeBase = none;
		return;
	}

	if(Matinee == none)
	{
		`Redscreen("Attempting to set Matinee Base but no Matinee has been set yet!");
		return;
	}

	if (MatineeBaseSocketName == '')
	{
		foreach AllActors(class'Actor', PotentialBaseNonSkel)
		{
			if (PotentialBaseNonSkel.Tag == MatineeBaseActorTag)
			{
				MatineeBase = PotentialBaseNonSkel;
				break;
			}
		}
	}
	else
	{
		foreach AllActors(class'SkeletalMeshActor', PotentialBase)
		{
			if (PotentialBase.Tag == MatineeBaseActorTag)
			{
				MatineeBase = PotentialBase;
				break;
			}
		}
	}

	if(MatineeBase == none)
	{
		`Redscreen("Could not find dropship intro base actor with tag: " $ string(MatineeBaseActorTag));
		return;
	}

	MatineeBaseSocket = MatineeBaseSocketName;
}

private function PrepareUnitsForMatinee()
{
	local XGUnit UnitVisualizer;
	local XComUnitPawn TacticalPawn;
	local XComUnitPawn MatineePawn;
	local int Index;
		
	for(Index = 0; Index < UnitMappings.Length; Index++)
	{
		if(UnitMappings[Index].Unit != none)
		{
			UnitVisualizer = XGUnit(UnitMappings[Index].Unit.GetVisualizer());
			`assert(UnitVisualizer != none);

			TacticalPawn = UnitVisualizer.GetPawn();
			`assert(TacticalPawn != none);

			TacticalPawn.m_bHiddenForMatinee = true;
			UnitMappings[Index].WasUnitVisibile = TacticalPawn.IsVisible();
			TacticalPawn.SetVisible(false);

			// create a temporary pawn for the matinee
			MatineePawn = UnitMappings[Index].Unit.CreatePawn(self, TacticalPawn.Location, TacticalPawn.Rotation);
			MatineePawn.CreateVisualInventoryAttachments(none, UnitMappings[Index].Unit, none, false);
			MatineePawn.ObjectID = -1;
			MatineePawn.SetupForMatinee(none, true, false);
			MatineePawn.StopTurning();
			MatineePawn.SetVisible(FALSE);

			UnitMappings[Index].CreatedPawn = MatineePawn;
		}
		else
		{
			UnitMappings[Index].CreatedPawn = none;
		}
	}
}

private function RemoveUnitsFromMatinee()
{
	local XGUnit UnitVisualizer;
	local int Index;

	for(Index = 0; Index < UnitMappings.Length; Index++)
	{
		// re-sync the unit visualizer to the location and state it should be in
		if(UnitMappings[Index].Unit != none)
		{
			UnitMappings[Index].Unit.SyncVisualizer();
			UnitVisualizer = XGUnit(UnitMappings[Index].Unit.GetVisualizer());
			UnitVisualizer.GetPawn().m_bHiddenForMatinee = false;
			UnitVisualizer.SetVisible(UnitMappings[Index].WasUnitVisibile);

			// destroy the temporary pawn we created
			UnitMappings[Index].CreatedPawn.Destroy();
			UnitMappings[Index].CreatedPawn = none;
		}
	}
}

protected function PlayMatinee()
{
	local X2MatineeInfo MatineeInfo;

	// make sure we have a matinee to play
	if(Matinee == none)
	{
		`Redscreen("No matinee specified in X2Action_PlayMatinee!");
		return;
	}

	// update the timeout so that we can see the entire matinee
	MatineeInfo = new class'X2MatineeInfo';
	MatineeInfo.InitFromMatinee(Matinee);
	TimeoutSeconds = ExecutingTime + MatineeInfo.GetMatineeDuration() + 5.0f; // timeout 5 seconds after the point where we think we should be finished

	// don't do any visibilty updates during the matinee, or it can mess with pawn visibility
	`XWORLD.bDisableVisibilityUpdates = true;

	// assign all units to the matinee
	PrepareUnitsForMatinee();
	
	LinkUnitVariablesToMatinee();

	// some matinee groups will have non-unit actors attached, rebase those too if needed
	if (bRebaseNonUnitVariables)
	{
		RebaseNonUnitVariables();
	}

	// put ourselves in cinematic mode, so the matinee can hook the camera and such at the unreal level
	XComTacticalController(GetALocalPlayerController()).SetCinematicMode(true, true, true, true, true, true);

	// create a camera on the camera stack to do the actual camera logic
	if( !bNewUnitSelected )
	{
		MatineeCamera = new class'X2Camera_Matinee';
		MatineeCamera.SetMatinee(Matinee, MatineeBase);
		MatineeCamera.PopWhenFinished = false;
		`CAMERASTACK.AddCamera(MatineeCamera);
	}


	// fixes bug where skipped matinee won't replay (because it thinks it's still playing).  mdomowicz 2015_11_13
	Matinee.Stop();

	// and play the matinee
	StartMatinee();
}

simulated protected function EndMatinee()
{
	if(MatineeCamera != none)
	{
		RemoveUnitsFromMatinee();
		`CAMERASTACK.RemoveCamera(MatineeCamera);
		`XWORLD.bDisableVisibilityUpdates = false;

		MatineeCamera = none;
	}
}

simulated state Executing
{
	event Tick(float DeltaTime)
	{
		super.Tick(DeltaTime);

		// keep updating the matinee until it is finished. Use the camera as a sentinel to
		// indicate that the matinee has actually started playback, as sub classes might not start
		// the matinee immediately
		if(MatineeCamera != none)
		{
			UpdateMatinee(DeltaTime);
		}
	}

Begin:
	PlayMatinee();

	// just wait for the matinee to complete playback
	while(Matinee != none) // the matinee will be set to none when it is finished/cancelled
	{
		Sleep(0.0f);
	}
	
	CompleteAction();
}

function CompleteAction()
{
	super.CompleteAction();

	EndMatinee();

	XComTacticalController(GetALocalPlayerController()).SetCinematicMode(false, true, true, true, true, true);
}

event bool BlocksAbilityActivation()
{
	return true; // matinees should never permit interruption
}

event HandleNewUnitSelection()
{
	if( MatineeCamera != None )
	{
		`CAMERASTACK.RemoveCamera(MatineeCamera);
		MatineeCamera = None;
	}
}

DefaultProperties
{
	bRebaseNonUnitVariables=true
}
