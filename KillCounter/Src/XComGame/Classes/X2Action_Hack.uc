//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_Hack extends X2Action;

//Cached info for the unit performing the action and the target object
//*************************************
var XGUnit                      SourceXGUnit;
var XComUnitPawn                SourceUnitPawn;

var XGUnit                      TargetXGUnit;
var XComUnitPawn                TargetUnitPawn;

var XComInteractiveLevelActor	InteractiveActor;
var CustomAnimParams            Params;

var XComGameStateContext_Ability AbilityContext;
var vector                      OriginalSourceHeading;
var vector                      OriginalTargetHeading;
var vector						OriginalSourceLocation;
var vector						OriginalTargetLocation;
var vector                      SourceToTarget;
var vector						SyncLocation;
var vector						FixupOffset;			//The offset that needs to be applied to the mesh due to the desired z location change.
var bool						ShouldFixup;

var XComGameState_Unit UnitState;
var XComGameState_Unit  TargetUnit;
var XComGameState_InteractiveObject ObjectState;
var XComGameState_TimerData MPTimer;

// 'Interactive Object'-specific vars
var XComInteractiveLockInfo CachedLockInfo;
//
var Actor HackedActor;


// In seconds, the amount of time to wait after the hacking UI finishes before putting away the hacking device
var float DelayAfterHackCompletes;

var StaticMeshComponent GremlinLCD;

// The state of the hacking mesh base prior to being forcibly shown during this action
var bool PreviouslyHidden;

var AnimNodeSequence StopTargetSequence;
var AnimNodeSequence StopUnitSequence;
var float TimeUntilRagdoll;
var int ScanNotify;
var AnimNotifyEvent NotifyEvent;

//*************************************

var Name ScreenSocketName;

var Name SourceBeginAnim;
var Name SourceLoopAnim;
var Name SourceEndAnim;

var Name TargetBeginAnim;
var Name TargetLoopAnim;
var Name TargetEndAnim;

//*************************************

var protected UIMovie_3D HackMovie;
var private bool HasFinishedUI;

var UIHackingScreen HackScreen;

var private bool bDoHackCaptainNarrative;

function Init(const out VisualizationTrack InTrack)
{
	local XComGameStateHistory History;	
	local XComGameState_BaseObject TargetState;

	super.Init(InTrack);
	
	History = `XCOMHISTORY;

	AbilityContext = XComGameStateContext_Ability(StateChangeContext);

	UnitState = XComGameState_Unit(InTrack.StateObject_NewState);
	`assert(UnitState != none);

	SourceXGUnit = XGUnit(UnitState.GetVisualizer());
	SourceUnitPawn = SourceXGUnit.GetPawn();

	CachedLockInfo = None;

	TargetState = History.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID);

	ObjectState = XComGameState_InteractiveObject(TargetState);
	if( ObjectState == None )
	{
		TargetUnit = XComGameState_Unit(TargetState);
		TargetXGUnit = XGUnit(TargetUnit.GetVisualizer());
		TargetUnitPawn = TargetXGUnit.GetPawn();

		SourceToTarget = TargetUnitPawn.Location - SourceUnitPawn.Location;
		OriginalTargetHeading = vector(TargetUnitPawn.Rotation);

		SyncLocation = VLerp(UnitPawn.Location, TargetUnitPawn.Location, 0.5f);
		SyncLocation.Z = Unit.GetDesiredZForLocation(SyncLocation); // Keep their Z on the floor
		OriginalTargetLocation = TargetUnitPawn.Location;
	}
	else
	{
		HackedActor = ObjectState.GetVisualizer();
		InteractiveActor = XComInteractiveLevelActor(HackedActor);
		CachedLockInfo = InteractiveActor.CachedLockInfo;
		SourceToTarget = HackedActor.Location - SourceUnitPawn.Location;
		SyncLocation = VLerp(UnitPawn.Location, HackedActor.Location, 0.5f);
		SyncLocation.Z = Unit.GetDesiredZForLocation(SyncLocation); // Keep their Z on the floor
		OriginalTargetLocation = HackedActor.Location;
	}
	FixupOffset = SyncLocation - OriginalTargetLocation;
	//The fixup only applies to the Z coordinate.
	FixupOffset.X = 0;
	FixupOffset.Y = 0;

	OriginalSourceHeading = vector(SourceUnitPawn.Rotation);
	OriginalSourceLocation = SourceUnitPawn.Location;

	SourceToTarget.Z = 0;
	SourceToTarget = Normal(SourceToTarget);

	if (`XENGINE.IsMultiplayerGame())
	{
		MPTimer = XComGameState_TimerData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_TimerData', true));
	}
}

function bool ShouldPlayAdventCaptainNarrative()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local X2CharacterTemplate CharacterTemplate;
	local XComGameState_Objective ObjState;

	CharacterTemplate = TargetUnit.GetMyTemplate();

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	// Advent captains are always SKULLJACKable only during the GP missions which requires it
	if (CharacterTemplate.CharacterGroupName == 'AdventCaptain')
	{
		ObjState = XComHQ.GetObjective('T1_M2_S3_SKULLJACKCaptain');
		ObjState = XComGameState_Objective(History.GetGameStateForObjectID(ObjState.ObjectID, , AbilityContext.AssociatedState.HistoryIndex));

		if (ObjState.GetStateOfObjective() == eObjectiveState_InProgress)
		{
			return true;
		}
	}

	return false;
}

function OnHackingUIComplete()
{
	HasFinishedUI = true;
}

function OnHackingRewardUnlocked(int iRewardIndex)
{
	// Play narrative once we've unlocked first reward
// 	if (bDoHackCaptainNarrative && iRewardIndex == 0)
// 	{
// 		`PRESBASE.UINarrative(XComNarrativeMoment'X2NarrativeMoments.TACTICAL.goldenpath.GP_FirstSuccessfulOfficerHack_Tygan');
// 	}
}

private function SkeletalMeshComponent GetHackMeshBase()
{
	local Actor ItemVisualizer;

	if( AbilityContext.InputContext.ItemObject.ObjectID > 0 )
	{
		ItemVisualizer = `XCOMHISTORY.GetVisualizer(AbilityContext.InputContext.ItemObject.ObjectID);
		if( ItemVisualizer != None && XGWeapon(ItemVisualizer).m_kMeshComponent != None )
		{
			return SkeletalMeshComponent(XGWeapon(ItemVisualizer).m_kMeshComponent);
		}

		// an item other than a weapon is the hacking source, use the pawn's mesh as the base
		return SourceUnitPawn.Mesh;
	}
	return None;
}

private function SetupHackingScreen()
{
	// spawn the hacking ui screen
	HackScreen = Spawn(class'UIHackingScreen', self);
	HackScreen.OriginalContext = AbilityContext;

	HackScreen.OnHackingComplete = OnHackingUIComplete;
	HackScreen.OnHackingRewardUnlocked = OnHackingRewardUnlocked;
	`Pres.ScreenStack.Push(HackScreen, HackMovie);

	SetupScreenMaterial();
}

simulated function SetupScreenMaterial()
{
	local MaterialInstanceConstant ScreenMaterial;

	// set the movie to render to the hack screen
	ScreenMaterial = MaterialInstanceConstant(GremlinLCD.GetMaterial(0));

	if( ScreenMaterial != None )
	{
		ScreenMaterial.SetTextureParameterValue('Diffuse', HackMovie.RenderTexture);
	}
}

function bool IsTimedOut()
{
	return false;
}

//------------------------------------------------------------------------------------------------
simulated state Executing
{
	simulated function XComPresentationLayer GetPresentationLayer()
	{
		return  `PRES();
	}

	simulated function SetHackingDeviceHidden(bool bHide)
	{
		local SkeletalMeshComponent HackMeshBase;

		HackMeshBase = GetHackMeshBase();

		if( HackMeshBase != None )
		{
		    if(!bHide)
		    {
				HackMeshBase.AttachComponentToSocket(GremlinLCD, ScreenSocketName);

				PreviouslyHidden = HackMeshBase.HiddenGame;

				HackMeshBase.SetHidden(false);
		    }
		    else
		    {
				HackMeshBase.DetachComponent(GremlinLCD);

				HackMeshBase.SetHidden(PreviouslyHidden);
		    }
			GremlinLCD.SetHidden(bHide);
		}
	}

	simulated function Update2DCursorLocation()
	{
		local XComTacticalHUD TacticalHUD;

		TacticalHUD = XComTacticalHUD(GetALocalPlayerController().myHUD);
		
		HackMovie.SetMouseLocation(class'Helpers'.static.GetUVCoords(GremlinLCD, TacticalHUD.CachedMouseWorldOrigin, TacticalHUD.CachedMouseWorldDirection));
	}

	simulated function Tick(float dt)
	{
		if( ShouldFixup )
		{
			TargetUnitPawn.Mesh.SetTranslation(SourceUnitPawn.Mesh.Translation + FixupOffset);
		}
	}

Begin:

	bDoHackCaptainNarrative = ShouldPlayAdventCaptainNarrative();

	// turn the unit(s) to face each other
	if( ShouldFixup )
	{
		SourceUnitPawn.EnableRMA(true, true);
		SourceUnitPawn.EnableRMAInteractPhysics(true);
		SourceUnitPawn.bSkipIK = true;
		TargetUnitPawn.EnableRMA(true, true);
		TargetUnitPawn.EnableRMAInteractPhysics(true);
		TargetUnitPawn.bSkipIK = true;

		TargetUnitPawn.Mesh.SetTranslation(SourceUnitPawn.Mesh.Translation + FixupOffset);
		TargetXGUnit.IdleStateMachine.GoDormant(SourceUnitPawn);
	}
	else
	{
		if( TargetXGUnit != None )
		{
			TargetXGUnit.IdleStateMachine.ForceHeading(-SourceToTarget);
		}
		SourceXGUnit.IdleStateMachine.ForceHeading(SourceToTarget);

		while( SourceXGUnit.IdleStateMachine.IsEvaluatingStance() ||
			  (TargetXGUnit != None && TargetXGUnit.IdleStateMachine.IsEvaluatingStance()) )
		{
			Sleep(0.0f);
		}
	}

	// setup the UI movie container. We create this when we need it as it uses a fair bit of video memory
	HackMovie = `PRES.Get3DMovie();

	while(!HackMovie.bIsInited)
	{
		Sleep(0.1);
	}

	SetHackingDeviceHidden(false);
	// show the hacking screen and wait for it to finish
	SetupHackingScreen();

	// Start hacking anims
	if( TargetUnitPawn != None && TargetBeginAnim != '' )
	{
		Params = default.Params;
		Params.AnimName = TargetBeginAnim;
		Params.Looping = false;
		Params.HasDesiredEndingAtom = ShouldFixup;
		Params.DesiredEndingAtom.Translation = SyncLocation;
		Params.DesiredEndingAtom.Translation.Z = TargetUnitPawn.GetDesiredZForLocation(SyncLocation);
		Params.DesiredEndingAtom.Rotation = QuatFromRotator(Rotator(-SourceToTarget));
		Params.DesiredEndingAtom.Scale = 1.0f;
		TargetUnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params);
		TargetUnitPawn.GetAnimTreeController().SetAllowNewAnimations(false);
	}

	Params = default.Params;
	Params.AnimName = SourceBeginAnim;
	Params.Looping = false;
	Params.HasDesiredEndingAtom = ShouldFixup;
	Params.DesiredEndingAtom.Translation = SyncLocation;
	Params.DesiredEndingAtom.Rotation = QuatFromRotator(Rotator(SourceToTarget));
	Params.DesiredEndingAtom.Scale = 1.0f;
	FinishAnim(SourceUnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params));

	if (bDoHackCaptainNarrative)
	{
		`PRESBASE.UINarrative(XComNarrativeMoment'X2NarrativeMoments.TACTICAL.goldenpath.GP_FirstSuccessfulOfficerHack_Tygan');
	}

	// Loop while the UI is displayed
	if( TargetUnitPawn != None && TargetLoopAnim != '' )
	{
		Params = default.Params;
		Params.AnimName = TargetLoopAnim;
		Params.Looping = true;
		TargetUnitPawn.GetAnimTreeController().SetAllowNewAnimations(true);
		TargetUnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params);
		TargetUnitPawn.GetAnimTreeController().SetAllowNewAnimations(false);
	}

	Params = default.Params;
	Params.AnimName = SourceLoopAnim;
	Params.Looping = true;
	SourceUnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params);

	// process the UI
	HasFinishedUI = false;

	while(!HasFinishedUI)
	{
		if (MPTimer != none && MPTimer.HasTimeExpired())
		{
			// The MP Turn timer has expired. Trigger this action to complete and allow the turn switch to execute.
			HackScreen.OnCancel();
		}
		Update2DCursorLocation();
		Sleep(0.1);
	}

	// sleep a few more moments so they can see the results on screen before he puts the pad away.
	Sleep(DelayAfterHackCompletes);

	// if this was a successful hack and we are a key, update the pathing around the doors we unlocked
	if(AbilityContext.IsResultContextHit()
		&& CachedLockInfo != none 
		&& CachedLockInfo.arrKeys.Find(InteractiveActor) >= 0
		&& !CachedLockInfo.IsSystemLocked())
	{
		CachedLockInfo.UpdateDoorPathing();
	}


	// Stop hacking anim
	TimeUntilRagdoll = -1.0f;
	if( TargetUnitPawn != None && TargetEndAnim != '' )
	{
		Params = default.Params;
		Params.AnimName = TargetEndAnim;
		Params.Looping = false;
		Params.HasDesiredEndingAtom = ShouldFixup;
		Params.DesiredEndingAtom.Translation = OriginalTargetLocation;
		Params.DesiredEndingAtom.Rotation = QuatFromRotator(Rotator(OriginalTargetHeading));
		Params.DesiredEndingAtom.Scale = 1.0f;
		TargetUnitPawn.GetAnimTreeController().SetAllowNewAnimations(true);
		StopTargetSequence = TargetUnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params);
		if( StopTargetSequence != None && StopTargetSequence.AnimSeq != None )
		{
			for( ScanNotify = 0; ScanNotify < StopTargetSequence.AnimSeq.Notifies.Length; ++ScanNotify )
			{
				NotifyEvent = StopTargetSequence.AnimSeq.Notifies[ScanNotify];
				if( XComAnimNotify_Ragdoll(NotifyEvent.Notify) != None )
				{
					TimeUntilRagdoll = NotifyEvent.Time;
				}
			}
		}
		
	}
	
	//// remove the hacking movie
	HackScreen.CloseScreen();

	Params = default.Params;
	Params.AnimName = SourceEndAnim;
	Params.Looping = false;
	Params.HasDesiredEndingAtom = ShouldFixup;
	Params.DesiredEndingAtom.Translation = OriginalSourceLocation;
	Params.DesiredEndingAtom.Rotation = QuatFromRotator(Rotator(OriginalSourceHeading));
	Params.DesiredEndingAtom.Scale = 1.0f;
	StopUnitSequence = SourceUnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params);

	if( ShouldFixup && TimeUntilRagdoll != -1.0f )
	{
		Sleep(TimeUntilRagdoll);
		TargetUnitPawn.StartRagDoll();
	}

	FinishAnim(StopUnitSequence);

	SetHackingDeviceHidden(true);

	// return to previous facing
	if( ShouldFixup )
	{
		SourceUnitPawn.EnableRMA(false, false);
		SourceUnitPawn.EnableRMAInteractPhysics(false);
		SourceUnitPawn.bSkipIK = false;
		TargetUnitPawn.EnableRMA(false, false);
		TargetUnitPawn.EnableRMAInteractPhysics(false);
		TargetUnitPawn.bSkipIK = false;
	}
	else
	{
		if( TargetXGUnit != None )
		{
			TargetXGUnit.IdleStateMachine.ForceHeading(OriginalTargetHeading);
		}
		SourceXGUnit.IdleStateMachine.ForceHeading(OriginalSourceHeading);
		while( SourceXGUnit.IdleStateMachine.IsEvaluatingStance() )
		{
			Sleep(0.0f);
		}
	}

	CompleteAction();
}

event bool BlocksAbilityActivation()
{
	return true;
}

defaultproperties
{
	DelayAfterHackCompletes=0.5

	Begin Object Class=StaticMeshComponent Name=MeshComp
		StaticMesh=StaticMesh'ConvGremlin.Meshes.LCD_Panel';
	end object
	GremlinLCD=MeshComp

	SourceBeginAnim = "HL_HackStartA"
	SourceLoopAnim = "HL_HackLoopA"
	SourceEndAnim = "HL_HackStopA"

	TargetBeginAnim = ""
	TargetLoopAnim = ""
	TargetEndAnim = ""

	ShouldFixup = false;

	ScreenSocketName = "Screen"
}

