//---------------------------------------------------------------------------------------
//  FILE:    X2Camera_Cinescript.uc
//  AUTHOR:  David Burchanowski  --  6/26/2014
//  PURPOSE: Camera for giving the artists a simple markup based camera control system.
//              Cinescript is just the goofy (but canonical) name Andrew game it.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2Camera_Cinescript extends X2Camera
	config(Camera);

// Indicates the kind of camera we should cut to
enum CinescriptCameraType
{
	CinescriptCameraType_OverTheShoulder,    // X2Camera_OverTheShoulder
	CinescriptCameraType_Midpoint,           // X2Camera_Midpoint
	CinescriptCameraType_Matinee,            // X2Camera_Matinee
	CinescriptCameraType_Exit                // Ends this sequence and pops the camera.
};

// Indicates what the camera should frame.
enum CinescriptTargetType
{
	CinescriptTargetType_ShooterAndPrimaryTarget,   // Shooter and primary target of an ability
	CinescriptTargetType_AllTargets,                // All targets of an ability
	CinescriptTargetType_AllParticipants            // All targets and the shooter of an ability
};

// Allows you to specify different cameras if a unit dies
enum CinescriptTargetDiedType
{
	CinescriptTargetDiedType_Either,
	CinescriptTargetDiedType_Died,
	CinescriptTargetDiedType_Survived
};

enum CinescriptShooterTeam
{
	CinescriptShooterTeam_Either,
	CinescriptShooterTeam_XCom,
	CinescriptShooterTeam_Alien
};

enum CinescriptTargetTeam
{
	CinescriptTargetTeam_Any,
	CinescriptTargetTeam_XCom,
	CinescriptTargetTeam_Alien,
	CinescriptTargetTeam_Neutral
};

// Definition of a single camera cut in the ini file. Should be bundled up into an array with
// other cuts
struct CinescriptCut
{
	// Trigger parameters. Not all of these are used for every kind of cut,
	// but since this needs to be edited from a config file, we need to have
	// all of the datatypes defined
	var float CutDelay; // valid when CinescriptCutTrigger == DelayTrigger, seconds into the script to cut
	var string CutAnimNotify; // valid when CinescriptCutTrigger == AnimNotifyTrigger, cut when this anim notify is hit
	var bool CutAfterPrevious; // index of another cinescript camera to cut after this one is complete

	// 0.0-1.0, Chance we will do this cut.
	var float CutChance;

	// definition of the camera we will be cutting to
	var CinescriptCameraType NewCameraType;

	// For OTS and Matinee cams. All matinees with the given prefix in there comment will be considered for
	// use. For example, the prefix "CIN_OTS_1" will match "CIN_OTS_1_L" and "CIN_OTS_1_R", but not
	// "CIN_OTS_2_L" or "CIN_REVEAL_1_L". From the resulting pool, one of the best fitting matinees will
	// be selected at random.
	var string MatineeCommentPrefix;

	// By default, cuts use the shooter as the base (ots looks over shooter shoulder, matinee is centered on shooter, etc)
	// flipping this to true will use the primary target instead
	var bool FocusPrimaryTarget;

	// Matinee camera only. Focus the matinee on the shooters item unit (item units are things like gremlins
	var bool FocusShooterItemUnit;

	// For Midpoint Cameras. Specifies what the midpoint camera should frame.
	var CinescriptTargetType TargetType;

	// For MatineeCameras. Will automatically remove the camera when the matinee completes.
	// If false, will sit on the last frame of the matinee indefinitely.
	// Defaults to true;
	var bool PopWhenFinished;

	// Blends instead of doing a hard cut
	var bool DisableBlend;

	// If true the matinee camera will not care about blocking volumes or crosscutting and play the matinee regardless.
	var bool ShouldAlwaysShow;

	// If true, will not do stepout fixup/prediction logic and instead center the matinee on the unit. Only for matinee cuts
	var bool IgnoreStepoutFixups;

	structdefaultproperties
	{
		CutChance=1
		DisableBlend=true
		PopWhenFinished=true;
		ShouldAlwaysShow=false;
	}
};

// Defines a mapping from an ability to a series of camera cuts. For use in the ini file
struct AbilityCameraDefinition
{
	var string AbilityCameraType;
	var array<name> CharacterTemplates;             // This camera type is used by the Template named stored here
	var array<CinescriptCut> CameraCuts;            // Array of cuts to use with the generated Cinescript camera
	var CinescriptTargetDiedType TargetDiedType;    // Limits usage based on whether a camera dies or not
	var CinescriptShooterTeam ShooterTeam;          // Limits usage to a specific team
	var CinescriptTargetTeam TargetTeam;			// Limits usage to a specific target team
	var bool ShouldShowCursor;						// Will enable the cursor if true
	var float ExtraAbilityEndDelay;					// adds this many seconds of dead time to the end of an ability so the camera can hang out
	var bool StartBeforeStepout;					// If true the cinescript camera will begin executing before the stepout instead of after
	var bool GameplayRequired;                      // If true, will play this sequence even if action cams are turned off. 
};

// List of all cinescript camera definitions
var private const config array<AbilityCameraDefinition> AbilityCameras;

// ini entry being used by this camera
var privatewrite AbilityCameraDefinition CameraDefinition;

// To support CinescriptCut.CutAfterPrevious, keep track of the "next" camera we should cut to when the previous one completes
var private int PendingCutIndex;

// After pushing a new camera, should it complete for some reason (or fail to start), return to the previously active child camera
var private X2Camera FallbackCamera;

// The AbilityContext that this camera is being driven from
var private XComGameStateContext_Ability AbilityContext;

// This camera was built to work only with an ability's primary target.  But some abilities (eg Faceoff) want to use this camera
// with multi-targets.  This provides a way for a ability to manually set the camera's target at vis building time.
var int TargetObjectIdOverride;

// Time since we've started this camera.
var private float Time;

// Cached History. We'll need it for every cut so better to just hold on to it.
var private XComGameStateHistory History;

/// <summary>
/// Scans the list of CinemaScript cameras in the ini file and if one is found that matches the ability 
/// in the provided context, it is created and added to the camera stack.
/// </summary>
static function X2Camera_Cinescript CreateCinescriptCameraForAbility(XComGameStateContext_Ability InContext)
{
	local X2Camera_CineScript CinescriptCamera;
	local X2AbilityTemplate AbilityTemplate;
	local AbilityCameraDefinition CameraDef;
	local AbilityCameraDefinition SavedCameraDef;
	local name AbilityTemplateName;
	local CinescriptTargetDiedType TargetDiedType;
	local CinescriptShooterTeam ShooterTeam;
	local CinescriptTargetTeam TargetTeam;
	local XComGameState_Unit AbilitySourceUnit;
	local XComGameStateHistory StaticHistory;
	local bool GlamCamsDisabled;

	// get the ability template name whose camera we want to use. 
	AbilityTemplateName = InContext.InputContext.AbilityTemplateName;

	AbilityTemplate = class'XComGameState_Ability'.static.GetMyTemplateManager().FindAbilityTemplate(AbilityTemplateName);
	if(AbilityTemplate.CinescriptCameraType == "")
	{
		// this ability does not request any camera type
		return none;
	}

	// determine if any of the targets died
	TargetDiedType = DidAnyTargetUnitDie(InContext) ? CinescriptTargetDiedType_Died : CinescriptTargetDiedType_Survived;

	// determine the shooter team
	ShooterTeam = GetShooterTeam(InContext);

	TargetTeam = GetTargetTeam(InContext);

	// Check if the camera has an override in the Character Template
	StaticHistory = `XCOMHISTORY;
	AbilitySourceUnit = XComGameState_Unit(StaticHistory.GetGameStateForObjectID(InContext.InputContext.SourceObject.ObjectID,, InContext.AssociatedState.HistoryIndex));
	
	GlamCamsDisabled = !`Battle.ProfileSettingsGlamCam();
	SavedCameraDef.AbilityCameraType = "";
	// find a camera script that matches the ability and parameters, if any
	foreach default.AbilityCameras(CameraDef)
	{
		// some sequences, such as hacking, are required to happen even if glam cams are disabled. Discard the others here.
		if(GlamCamsDisabled && !CameraDef.GameplayRequired)
		{
			continue;
		}

		if( CameraDef.AbilityCameraType == AbilityTemplate.CinescriptCameraType
			&& (CameraDef.TargetDiedType == CinescriptTargetDiedType_Either || CameraDef.TargetDiedType == TargetDiedType) // Does the target's death/not death status match?
			&& (CameraDef.ShooterTeam == CinescriptShooterTeam_Either || CameraDef.ShooterTeam == ShooterTeam)  // Is this the right team?
			&& (CameraDef.TargetTeam == CinescriptTargetTeam_Any || CameraDef.TargetTeam == TargetTeam)) // Is this the right team?
		{

			if( CameraDef.CharacterTemplates.Length == 0 )
			{
				// Default camera found but there may be an override
				SavedCameraDef = CameraDef;
			}
			else if( CameraDef.CharacterTemplates.Find(AbilitySourceUnit.GetMyTemplateName()) != INDEX_NONE )
			{
				// An override of the camera for the source's template was found
				// No need to keep looking, so break
				SavedCameraDef = CameraDef;
				break;
			}
		}
	}

	if( SavedCameraDef.AbilityCameraType != "" )
	{
		// There was supposed to be an override camera but one was not found, so return the ability's default camera if found
		CinescriptCamera = new class'X2Camera_CineScript';
		CinescriptCamera.AbilityContext = InContext;
		CinescriptCamera.CameraDefinition = SavedCameraDef;
		return CinescriptCamera;
	}

	return none;
}

/// <summary>
/// Helper function for CreateCinescriptCameraForAbility. Determines the shooter team
/// </summary>
private static function CinescriptShooterTeam GetShooterTeam(XComGameStateContext_Ability InContext)
{
	local XComGameStateHistory StaticHistory;
	local XComGameState_Unit Unit;

	StaticHistory = `XCOMHISTORY;

	Unit = XComGameState_Unit(StaticHistory.GetGameStateForObjectID(InContext.InputContext.SourceObject.ObjectID,, InContext.AssociatedState.HistoryIndex));

	if(Unit != none)
	{
		return (Unit.GetTeam() == eTeam_XCom) ? CinescriptShooterTeam_XCom : CinescriptShooterTeam_Alien;
	}
	else
	{
		return CinescriptShooterTeam_XCom; // should never hit this line, but just in case
	}
}

/// <summary>
/// Helper function for CreateCinescriptCameraForAbility. Determines the shooter team
/// </summary>
private static function CinescriptTargetTeam GetTargetTeam(XComGameStateContext_Ability InContext)
{
	local XComGameStateHistory StaticHistory;
	local XComGameState_Unit Unit;

	StaticHistory = `XCOMHISTORY;

		Unit = XComGameState_Unit(StaticHistory.GetGameStateForObjectID(InContext.InputContext.PrimaryTarget.ObjectID, , InContext.AssociatedState.HistoryIndex));

	if (Unit != none)
	{
		switch (Unit.GetTeam())
		{
		case eTeam_XCom:
		case eTeam_One:
			return CinescriptTargetTeam_XCom;
		case eTeam_Alien:
		case eTeam_Two:
			return CinescriptTargetTeam_Alien;
		default:
			return CinescriptTargetTeam_Neutral;
		}
	}
	else
	{
		return CinescriptTargetTeam_Alien; // should never hit this line, but just in case
	}
}

/// <summary>
/// Helper function for CreateCinescriptCameraForAbility. Returns true if any of the targets in the
/// given context game state died
/// </summary>
private static function bool DidAnyTargetUnitDie(XComGameStateContext_Ability InContext)
{
	local XComGameStateHistory StaticHistory;
	local StateObjectReference TargetRef;
	local XComGameState_BaseObject TargetBaseObject;
	local XComGameState_BaseObject PreviousTargetBaseObject;
	local XComGameState_Unit TargetUnit;
	local XComGameState_Unit PreviousTargetUnit;

	// named static history because this function is static and it needs to not collide with the classspace History.
	// Unreal's scoping is annoying at times
	StaticHistory = `XCOMHISTORY;

	// first check the primary target
	if(InContext.InputContext.PrimaryTarget.ObjectID > 0)
	{
		TargetRef = InContext.InputContext.PrimaryTarget;
		StaticHistory.GetCurrentAndPreviousGameStatesForObjectID(InContext.InputContext.PrimaryTarget.ObjectID, 
																	PreviousTargetBaseObject, 
																	TargetBaseObject,,
																	InContext.AssociatedState.HistoryIndex);

		TargetUnit = XComGameState_Unit(TargetBaseObject);
		PreviousTargetUnit = XComGameState_Unit(PreviousTargetBaseObject);

		if(TargetUnit != none 
			&& PreviousTargetUnit != none 
			&& TargetUnit.IsDead() 
			&& !PreviousTargetUnit.IsDead())
		{
			return true;
		}
	}

	// and then the general targets
	foreach InContext.InputContext.MultiTargets(TargetRef)
	{
		StaticHistory.GetCurrentAndPreviousGameStatesForObjectID(InContext.InputContext.PrimaryTarget.ObjectID, 
																PreviousTargetBaseObject, 
																TargetBaseObject,,
																InContext.AssociatedState.HistoryIndex);

		TargetUnit = XComGameState_Unit(TargetBaseObject);
		PreviousTargetUnit = XComGameState_Unit(PreviousTargetBaseObject);

		if(TargetUnit != none 
			&& PreviousTargetUnit != none 
			&& TargetUnit.IsDead() 
			&& !PreviousTargetUnit.IsDead())
		{
			return true;
		}
	}

	// nobody died
	return false;
}

function Added()
{
	super.Added();
	
	// Cache the history, since we'll be inspecting it quite a bit
	History = `XCOMHISTORY;

	// do a very small delta update to check for immediate camera cuts
	UpdateCamera(0.001f);
}

function PushCamera(X2Camera CameraToPush)
{
	FallbackCamera = ChildCamera;
	super.PushCamera(CameraToPush);
}

function PopCamera()
{
	local X2Camera OldChild;

	OldChild = ChildCamera;
	super.PopCamera();

	if(PendingCutIndex > 0 && OldChild != none && !OldChild.FailedActivation)
	{
		DoCameraCut(CameraDefinition.CameraCuts[PendingCutIndex]);
	}
	else if(FallbackCamera != OldChild)
	{
		PushCamera(FallbackCamera);
	}

	// make sure we don't have any stale pending cuts floating around
	PendingCutIndex = -1;
}

function Deactivated()
{
	super.Deactivated();
}

function UpdateCamera(float DeltaTime)
{
	local CinescriptCut Cut;
	local float NewTime;

	super.UpdateCamera(DeltaTime);

	NewTime = Time + DeltaTime;

	// Check to see if we have tripped any of the delay based camera cuts
	foreach CameraDefinition.CameraCuts(Cut)
	{
		if(Cut.CutAnimNotify == ""
			&& !Cut.CutAfterPrevious
			&& Time <= Cut.CutDelay
			&& Cut.CutDelay < NewTime)
		{
			DoCameraCut(Cut);
		}
	}

	Time = NewTime;
}

/// <summary>
/// Callback notify to allow the animation system to hook the camera and alert it
/// of cut notifies
/// </summary>
function OnAnimNotify(string EventLabel)
{
	local CinescriptCut Cut;

	foreach CameraDefinition.CameraCuts(Cut)
	{
		if(Cut.CutAnimNotify != "" && Cut.CutAnimNotify == EventLabel)
		{
			DoCameraCut(Cut);
			break;
		}
	}
}

/// <summary>
/// Common entry point for doing a cut. Call this instead of the specific cut functions.
/// </summary>
private function DoCameraCut(CinescriptCut CameraCut)
{
	local int Index;

	if(`SYNC_FRAND() <= CameraCut.CutChance || class'XComGameState_Cheats'.static.GetVisualizedCheatsObject().AlwaysDoCinescriptCut)
	{
		switch(CameraCut.NewCameraType)
		{
		case CinescriptCameraType_OverTheShoulder:
			DoOverTheShoulderCut(CameraCut);
			break;
		case CinescriptCameraType_Midpoint:
			DoMidpointCut(CameraCut);
			break;
		case CinescriptCameraType_Matinee:
			DoMatineeCut(CameraCut);
			break;
		case CinescriptCameraType_Exit:
			RemoveSelfFromCameraStack();
			break;
		};

		// check to see if we should do another cut when this one completes
		PendingCutIndex = 0;
		for(Index = 1; Index < CameraDefinition.CameraCuts.Length; Index++)
		{
			// this compare is slow (struct vs struct), but it happens so infrequently that it isn't worth making
			// the rest of the class messier to avoid it
			if(CameraDefinition.CameraCuts[Index].CutAfterPrevious && CameraDefinition.CameraCuts[Index - 1] == CameraCut)
			{
				PendingCutIndex = Index;
				break;
			}
		}
	}
}

function bool YieldIfActive()
{
	return ChildCamera == none;
}

private function DoOverTheShoulderCut(CinescriptCut CameraCut)
{
	local X2Camera_OverTheShoulder OTSCamera;
	local XGUnit FiringUnit;
	local Actor TargetActor;

	// get the shooter and primary target
	if(CameraCut.FocusPrimaryTarget)
	{
		FiringUnit = XGUnit(GetPrimaryTargetActor());
		TargetActor = XGUnit(GetShooterPawn().GetGameUnit());

		if(XGUnit(TargetActor) == none)
		{
			`Redscreen("Attempting to use primary target " $ TargetActor $ " as the over the shoulder actor, but it is not a pawn!");
			return;
		}
	}
	else
	{
		FiringUnit = XGUnit(GetShooterPawn().GetGameUnit());
		TargetActor = GetPrimaryTargetActor();
	}

	if(FiringUnit == none || TargetActor == none)
	{
		return;
	}

	// create and fill out the camera parameters
	OTSCamera = new class'X2Camera_OverTheShoulder';
	OTSCamera.CandidateMatineeCommentPrefix = CameraCut.MatineeCommentPrefix;
	OTSCamera.FiringUnit = FiringUnit;
	OTSCamera.SetTarget(TargetActor);
	OTSCamera.DOFFocusShooter = CameraCut.FocusPrimaryTarget;
	OTSCamera.ShouldBlend = !CameraCut.DisableBlend;
	OTSCamera.ShouldAlwaysShow = CameraCut.ShouldAlwaysShow;

	PushCamera(OTSCamera);
}

private function DoMidpointCut(CinescriptCut CameraCut)
{
	local X2Camera_Midpoint MidpointCamera;
	local StateObjectReference ObjectRef;
	local Vector TargetLocation;
	local XComGameState_BaseObject GameObject;

	MidpointCamera = new class'X2Camera_Midpoint';

	// Add the shooter location if needed
	if(CameraCut.TargetType == CinescriptTargetType_ShooterAndPrimaryTarget
		|| CameraCut.TargetType == CinescriptTargetType_AllParticipants)
	{
		ObjectRef = AbilityContext.InputContext.SourceObject;
		GameObject = History.GetGameStateForObjectID(ObjectRef.ObjectID,, AbilityContext.AssociatedState.HistoryIndex);
		MidpointCamera.AddFocusPoint(GameObject.GetVisualizer().Location);
	}

	// Add the primary target location if needed.
	if(CameraCut.TargetType == CinescriptTargetType_ShooterAndPrimaryTarget)
	{
		ObjectRef = AbilityContext.InputContext.PrimaryTarget;
		GameObject = History.GetGameStateForObjectID(ObjectRef.ObjectID,, AbilityContext.AssociatedState.HistoryIndex);
		if (GameObject != none)
		{
			MidpointCamera.AddFocusActor(GameObject.GetVisualizer());
		}
		else
		{
			// If there was no primary target actor, add the target locations in. (Abilities such as Acid Blob)
			foreach AbilityContext.InputContext.TargetLocations(TargetLocation)
			{
				MidpointCamera.AddFocusPoint(TargetLocation);
			}
		}
	}

	// Add all the target locations if needed
	if(CameraCut.TargetType == CinescriptTargetType_AllTargets || CameraCut.TargetType == CinescriptTargetType_AllParticipants)
	{
		foreach AbilityContext.InputContext.MultiTargets(ObjectRef)
		{
			GameObject = History.GetGameStateForObjectID(ObjectRef.ObjectID,, AbilityContext.AssociatedState.HistoryIndex);
			MidpointCamera.AddFocusActor(GameObject.GetVisualizer());
		}

		foreach AbilityContext.InputContext.TargetLocations(TargetLocation)
		{
			MidpointCamera.AddFocusPoint(TargetLocation);
		}
	}

	PushCamera(MidpointCamera);
}

private function DoMatineeCut(CinescriptCut CameraCut)
{
	local X2Camera_Matinee MatineeCamera;
	local XComUnitPawn ShooterPawn;
	local XGUnit ShooterUnit;
	local int MovementIndex;
	local Actor MatineeFocusActor;
	local Actor AdditionalParticipant;
	local XGUnit AdditionalUnit;
	local vector ShooterStepoutLocation;
	local Rotator ShooterStepoutFacing;
	local bool UseStepoutLocation;

	// determine if we want to look at the shooter or primary target
	if(CameraCut.FocusPrimaryTarget) // "reverse" matinee cam. Looks at the target instead of the shooter
	{
		MatineeFocusActor = GetPrimaryTargetActor();
		AdditionalParticipant = GetShooterPawn();
	}
	else if (CameraCut.FocusShooterItemUnit) // matinee should focus on the shooter's familiar
	{
		MatineeFocusActor = GetShooterItemUnitPawn();
		AdditionalParticipant = GetShooterPawn();
	}
	else // normal matinee centered on the shooting unit 
	{
		MatineeFocusActor = GetShooterPawn();
		AdditionalParticipant = GetPrimaryTargetActor();

		if(!CameraCut.IgnoreStepoutFixups)
		{
			// since units will often step out/change their facing direction mid ability, we enforce a solid line of focus 
			// toward the target so that the artists have a reference direction to shoot the cameras from. We also shift
			// the matinee to center on the stepout location, instead of their actual location. It's better they step into
			// frame instead of out of it

			UseStepoutLocation = true; // using specific matinee location instead of automatic actor centering
			ShooterStepoutLocation = GetShooterStepOutLocation();

			if(AdditionalParticipant != none)
			{
				// we are targeting another actor or unit
				AdditionalUnit = XGUnit(AdditionalParticipant);
				if(AdditionalUnit != none)
				{
					AdditionalParticipant = AdditionalUnit.GetPawn();
					ShooterStepoutFacing = Rotator(AdditionalUnit.GetLocation() - ShooterStepoutLocation);
				}
				else
				{
					ShooterStepoutFacing = Rotator(AdditionalParticipant.Location - ShooterStepoutLocation);
				}
			}
			else if(AbilityContext.InputContext.TargetLocations.Length > 0)
			{
				// we are targeting a free aim location
				AdditionalParticipant = AdditionalUnit.GetPawn();
				ShooterStepoutFacing = Rotator(AbilityContext.InputContext.TargetLocations[0] - ShooterStepoutLocation);
			}
			else if(AbilityContext.InputContext.MovementPaths.Length > 0)
			{
				// no target, so align the camera along the unit's movement path. This keeps the framing consistent even if the camera
				// starts while he is employing a rotational fixup
				ShooterPawn = XComUnitPawn(MatineeFocusActor);
				ShooterUnit = XGUnit(ShooterPawn.GetGameUnit());
				MovementIndex = ShooterUnit.VisualizerUsePath.GetPathIndexFromPathDistance(ShooterPawn.m_fDistanceMovedAlongPath);
				ShooterStepoutFacing = Rotator(ShooterUnit.VisualizerUsePath.GetPoint(MovementIndex + 1) - ShooterUnit.VisualizerUsePath.GetPoint(MovementIndex));
			}
			else
			{
				// we have no target, just use our current facing. We still want to center on the stepout location
				ShooterStepoutFacing = GetShooterPawn().Rotation;
			}
		}
	}

	// nothing to look at, bail
	if(MatineeFocusActor == none) return;

	MatineeCamera = new class'X2Camera_Matinee';
	MatineeCamera.ShouldBlend = !CameraCut.DisableBlend;
	MatineeCamera.ShouldShowCursor = CameraDefinition.ShouldShowCursor;
	MatineeCamera.PopWhenFinished = CameraCut.PopWhenFinished;
	MatineeCamera.ShouldAlwaysShow = CameraCut.ShouldAlwaysShow;

	if(UseStepoutLocation)
	{
		ShooterStepoutFacing.Roll = 0;
		ShooterStepoutFacing.Pitch = 0;
		MatineeCamera.SetExplicitMatineeLocation(ShooterStepoutLocation, ShooterStepoutFacing);
	}

	MatineeCamera.SetMatineeByComment(CameraCut.MatineeCommentPrefix, MatineeFocusActor);
	if (AdditionalParticipant != none)
	{
		MatineeCamera.ActorsToIgnoreForBlockingDetermination.AddItem(AdditionalParticipant);
	}
	
	PushCamera(MatineeCamera);
}

private function vector GetShooterStepOutLocation()
{
	local XComUnitPawn ShooterPawn;
	local X2Action ShooterAction;
	local X2Action_ExitCover ExitCoverAction;
	local XGUnit ShooterUnit;
	local Vector ShooterFeetLocation;
	local Vector StepoutLocation;

	// get the shooter and target actors (if any)
	ShooterPawn = GetShooterPawn();
	ShooterUnit = XGUnit(ShooterPawn.GetGameUnit());
	ShooterFeetLocation = ShooterPawn.GetFeetLocation();
	StepoutLocation = ShooterFeetLocation; // use the current feet location as a default

	// determine our stepout location, based on target type (unit or target location)
	// only do the fixups if the stepout action has not yet completed
	ShooterAction = `XCOMVISUALIZATIONMGR.GetCurrentTrackActionForVisualizer(ShooterUnit);
	if(ShooterAction != none && `XCOMVISUALIZATIONMGR.TrackHasActionOfType(ShooterAction.Track, class'X2Action_ExitCover', ShooterAction))
	{
		ExitCoverAction = X2Action_ExitCover(ShooterAction);
		if (ExitCoverAction != none && !ExitCoverAction.bCompleted && ExitCoverAction.AnimParams.HasDesiredEndingAtom)
		{
			StepoutLocation = ExitCoverAction.AnimParams.DesiredEndingAtom.Translation;

			// snap the location down to the shooter's foot level. That animation will sit at their waist, but the cameras
			// are shot from their feet.
			StepoutLocation.Z = ShooterFeetLocation.Z;
		}
	}

	return StepoutLocation;
}

private function XComUnitPawn GetShooterPawn()
{
	local int UnitObjectID;
	local XComGameState_Unit Unit;
	local XGUnit UnitVisualizer;
	local XComUnitPawn UnitPawn;

	UnitObjectID = AbilityContext.InputContext.SourceObject.ObjectID;
	Unit = XComGameState_Unit(History.GetGameStateForObjectID(UnitObjectID,, AbilityContext.AssociatedState.HistoryIndex));
	
	if(Unit == none)
	{
		`Redscreen("No shooter unit for Cinemascript to use!");
		return none;
	}

	UnitVisualizer = XGUnit(Unit.GetVisualizer());
	if(UnitVisualizer == none)
	{
		`Redscreen("No shooter unit visualizer for Cinemascript to use!");
		return none;
	}

	UnitPawn = UnitVisualizer.GetPawn();
	if(UnitPawn == none)
	{
		`Redscreen("No shooter unit pawn for Cinemascript to use!");
		return none;
	}

	return UnitPawn;
}

private function Actor GetPrimaryTargetActor()
{
	local int TargetObjectID;
	local XComGameState_BaseObject TargetObject;
	local Actor TargetVisualizer;

	TargetObjectID = AbilityContext.InputContext.PrimaryTarget.ObjectID;

	if ( TargetObjectIdOverride != 0 )
		TargetObjectID = TargetObjectIdOverride;

	TargetObject = History.GetGameStateForObjectID(TargetObjectID,, AbilityContext.AssociatedState.HistoryIndex);
	
	if(TargetObject == none)
	{
		// there used to be a redscreen here, but not every ability has a target actor (such as grenade throws)
		return none;
	}

	TargetVisualizer = TargetObject.GetVisualizer();
	if(TargetVisualizer == none)
	{
		`Redscreen("No primary target visualizer for Cinemascript to use!");
		return none;
	}

	return TargetVisualizer;
}

private function Actor GetShooterItemUnitPawn()
{
	local int ObjectID;
	local XComGameState_Unit Unit;
	local XComGameState_Item ItemUnit;
	local XGUnit UnitVisualizer;
	local XComUnitPawn UnitPawn;

	ObjectID = AbilityContext.InputContext.ItemObject.ObjectID;
	Unit = XComGameState_Unit(History.GetGameStateForObjectID(ObjectID,, AbilityContext.AssociatedState.HistoryIndex));

	// if not directly a unit, check if it's an item and grab the cosmetic unit ref if so
	if(Unit == none)
	{
		ItemUnit = XComGameState_Item(History.GetGameStateForObjectID(ObjectID,, AbilityContext.AssociatedState.HistoryIndex));
		if(ItemUnit != none)
		{
			Unit = XComGameState_Unit(History.GetGameStateForObjectID(ItemUnit.CosmeticUnitRef.ObjectID,, AbilityContext.AssociatedState.HistoryIndex));
		}
	}
	
	if(Unit == none)
	{
		`Redscreen("No shooter item unit for Cinemascript to use!");
		return none;
	}

	UnitVisualizer = XGUnit(Unit.GetVisualizer());
	if(UnitVisualizer == none)
	{
		`Redscreen("No shooter item unit visualizer for Cinemascript to use!");
		return none;
	}

	UnitPawn = UnitVisualizer.GetPawn();
	if(UnitPawn == none)
	{
		`Redscreen("No shooter item unit pawn for Cinemascript to use!");
		return none;
	}

	return UnitPawn;
}

function string GetDebugDescription()
{
	return super.GetDebugDescription() $ " - " $ CameraDefinition.AbilityCameraType;
}

defaultproperties
{
	Priority=eCameraPriority_Cinematic
	UpdateWhenInactive=true
	TargetObjectIdOverride = 0;
}