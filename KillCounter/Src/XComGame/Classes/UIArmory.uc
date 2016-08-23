//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIArmory
//  AUTHOR:  Sam Batista
//  PURPOSE: Base screen for Armory screens. 
//           It creates and manages the Soldier Pawn, and various UI controls
//			 that get reused on several UIArmory_ screens.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIArmory extends UIScreen
	config(UI);

var name DisplayTag;
var string CameraTag;
var bool bUseNavHelp;

var Actor ActorPawn;
var name PawnLocationTag;

var UISoldierHeader Header;
var UINavigationHelp NavHelp;
var StateObjectReference UnitReference;
var XComGameState CheckGameState;

var name DisplayEvent;
var name SoldierSpawnEvent;
var name NavigationBackEvent;
var name HideMenuEvent;
var name RemoveMenuEvent;

var config name EnableWeaponLightingEvent;
var config name DisableWeaponLightingEvent;

var localized string PrevSoldierKey;
var localized string NextSoldierKey;

delegate static bool IsSoldierEligible(XComGameState_Unit Soldier);

simulated function InitArmory(StateObjectReference UnitRef, optional name DispEvent, optional name SoldSpawnEvent, optional name NavBackEvent, optional name HideEvent, optional name RemoveEvent, optional bool bInstant = false, optional XComGameState InitCheckGameState)
{
	local float InterpTime;

	IsSoldierEligible = CanCycleTo;
	CheckGameState = InitCheckGameState;
	DisplayEvent = DispEvent;
	SoldierSpawnEvent = SoldSpawnEvent;
	HideMenuEvent = HideEvent;
	RemoveMenuEvent = RemoveEvent;
	NavigationBackEvent = NavBackEvent;

	if (SoldierSpawnEvent != '' || DisplayEvent != '')
	{
		WorldInfo.RemoteEventListeners.AddItem(self);
	}

	if (DisplayEvent == '')
	{
		InterpTime = `HQINTERPTIME;

		if(bInstant)
		{
			InterpTime = 0;
		}

		class'UIUtilities'.static.DisplayUI3D(DisplayTag, name(CameraTag), InterpTime);
	}
	else
	{
		if(bIsIn3D) UIMovie_3D(Movie).HideAllDisplays();
	}

	Header = Spawn(class'UISoldierHeader', self).InitSoldierHeader(UnitRef, CheckGameState);

	SetUnitReference(UnitRef);

	`XCOMGRI.DoRemoteEvent('CIN_HideArmoryStaff'); //Hide the staff in the armory so that they don't overlap with the soldiers

	if(bUseNavHelp)
	{
		if(XComHQPresentationLayer(Movie.Pres) != none)
			NavHelp = XComHQPresentationLayer(Movie.Pres).m_kAvengerHUD.NavHelp;
		else
			NavHelp = Movie.Pres.GetNavHelp();

		UpdateNavHelp();
	}
}

event OnRemoteEvent(name RemoteEventName)
{
	super.OnRemoteEvent(RemoteEventName);

	if (RemoteEventName == SoldierSpawnEvent)
	{
		CreateSoldierPawn();
	}
	else if (RemoteEventName == DisplayEvent)
	{
		class'UIUtilities'.static.DisplayUI3D(DisplayTag, name(CameraTag), 0);
	}
	else if (RemoteEventName == HideMenuEvent)
	{
		if(bIsIn3D) UIMovie_3D(Movie).HideDisplay(DisplayTag);
	}
	else if (RemoteEventName == RemoveMenuEvent)
	{
		Movie.Stack.PopFirstInstanceOfClass(class'UIArmory');		
	}
}

// override for custom behavior
simulated function PopulateData();

simulated function UpdateNavHelp()
{
	local int i;
	local string PrevKey, NextKey;
	local XGParamTag LocTag;

	if(bUseNavHelp)
	{
		NavHelp.ClearButtonHelp();
		NavHelp.AddBackButton(OnCancel);
		
		if(XComHQPresentationLayer(Movie.Pres) != none)
		{
			LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
			LocTag.StrValue0 = Movie.Pres.m_kKeybindingData.GetKeyStringForAction(PC.PlayerInput, eTBC_PrevUnit);
			PrevKey = `XEXPAND.ExpandString(PrevSoldierKey);
			LocTag.StrValue0 = Movie.Pres.m_kKeybindingData.GetKeyStringForAction(PC.PlayerInput, eTBC_NextUnit);
			NextKey = `XEXPAND.ExpandString(NextSoldierKey);

			// Don't allow jumping to the geoscape from the armory in the tutorial or when coming from squad select
			if (class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T0_M7_WelcomeToGeoscape') != eObjectiveState_InProgress &&
				RemoveMenuEvent == '' && NavigationBackEvent == '' && !`ScreenStack.IsInStack(class'UISquadSelect'))
			{
				NavHelp.AddGeoscapeButton();
			}

			if( Movie.IsMouseActive() && IsAllowedToCycleSoldiers() && class'UIUtilities_Strategy'.static.HasSoldiersToCycleThrough(UnitReference, CanCycleTo) )
			{
				NavHelp.SetButtonType("XComButtonIconPC");
				i = eButtonIconPC_Prev_Soldier;
				NavHelp.AddCenterHelp( string(i), "", PrevSoldier, false, PrevKey);
				i = eButtonIconPC_Next_Soldier; 
				NavHelp.AddCenterHelp( string(i), "", NextSoldier, false, NextKey);
				NavHelp.SetButtonType("");
			}
		}

		NavHelp.Show();
	}
}

// Override in child screens that need to disable soldier switching for some reason (ex: when promoting soldiers on top of avenger)
simulated function bool IsAllowedToCycleSoldiers()
{
	return true;
}

simulated function PrevSoldier()
{
	local StateObjectReference NewUnitRef;
	if( class'UIUtilities_Strategy'.static.CycleSoldiers(-1, UnitReference, CanCycleTo, NewUnitRef) )
		CycleToSoldier(NewUnitRef);
}

simulated function NextSoldier()
{
	local StateObjectReference NewUnitRef;
	if( class'UIUtilities_Strategy'.static.CycleSoldiers(1, UnitReference, CanCycleTo, NewUnitRef) )
		CycleToSoldier(NewUnitRef);
}

simulated static function bool CanCycleTo(XComGameState_Unit Unit)
{
	return Unit.IsASoldier() && !Unit.IsDead();
}

simulated static function CycleToSoldier(StateObjectReference NewRef)
{
	local int i;
	local UIArmory ArmoryScreen;
	local UIScreenStack ScreenStack;
	local Rotator CachedRotation, ZeroRotation;

	ScreenStack = `SCREENSTACK;

	for( i = ScreenStack.Screens.Length - 1; i >= 0; --i )
	{
		ArmoryScreen = UIArmory(ScreenStack.Screens[i]);
		if( ArmoryScreen != none )
		{
			CachedRotation = ArmoryScreen.ActorPawn != none ? ArmoryScreen.ActorPawn.Rotation : ZeroRotation;

			ArmoryScreen.ReleasePawn();

			ArmoryScreen.SetUnitReference(NewRef);
			ArmoryScreen.CreateSoldierPawn(CachedRotation);
			ArmoryScreen.PopulateData();

			ArmoryScreen.Header.UnitRef = NewRef;
			ArmoryScreen.Header.PopulateData(ArmoryScreen.GetUnit());

			// Signal focus change (even if focus didn't actually change) to ensure modders get notified of soldier switching
			ArmoryScreen.SignalOnReceiveFocus();
		}
	}

	// TTP[7879] - Immediately process queued commands to prevent 1 frame delay of customization menu options
	if( ArmoryScreen != none )
		ArmoryScreen.Movie.ProcessQueuedCommands();
}

simulated function StateObjectReference GetUnitRef()
{
	return UnitReference;
}

simulated function SetUnitReference(StateObjectReference NewUnitRef)
{
	UnitReference = NewUnitRef;
}

simulated function CreateSoldierPawn(optional Rotator DesiredRotation)
{
	local Rotator NoneRotation;

	// Don't do anything if we don't have a valid UnitReference
	if( UnitReference.ObjectID == 0 ) return;

	if( DesiredRotation == NoneRotation )
	{
		if( ActorPawn != none )
			DesiredRotation = ActorPawn.Rotation;
		else
			DesiredRotation.Yaw = -16384;
	}

	RequestPawn(DesiredRotation);
	LoadSoldierEquipment();

	// Prevent the pawn from obstructing mouse raycasts that are used to determine the position of the mouse cursor in 3D screens.
	XComHumanPawn(ActorPawn).bIgnoreFor3DCursorCollision = true;

	UIMouseGuard_RotatePawn(`SCREENSTACK.GetFirstInstanceOf(class'UIMouseGuard_RotatePawn')).SetActorPawn(ActorPawn);
}

// Override this function to provide custom pawn behavior
simulated function RequestPawn(optional Rotator DesiredRotation)
{
	ActorPawn = Movie.Pres.GetUIPawnMgr().RequestPawnByID(self, UnitReference.ObjectID, GetPlacementActor().Location, DesiredRotation);
	ActorPawn.GotoState('CharacterCustomization');
}

simulated function ReleasePawn(optional bool bForce)
{
	Movie.Pres.GetUIPawnMgr().ReleasePawn(self, UnitReference.ObjectID, bForce);
	ActorPawn = none;
}

// spawn weapons and other visible equipment - ovewritten in Loadout to provide custom behavior
simulated function LoadSoldierEquipment()
{	
	XComUnitPawn(ActorPawn).CreateVisualInventoryAttachments(Movie.Pres.GetUIPawnMgr(), GetUnit());
}

// Used in UIArmory_WeaponUpgrade & UIArmory_WeaponList
simulated function CreateWeaponPawn(XComGameState_Item Weapon, optional Rotator DesiredRotation)
{
	local Rotator NoneRotation;
	local XGWeapon WeaponVisualizer;
	
	// Make sure to clean up weapon actors left over from previous Armory screens.
	if(ActorPawn == none)
		ActorPawn = UIArmory(Movie.Stack.GetLastInstanceOf(class'UIArmory')).ActorPawn;

	// Clean up previous weapon actor
	if( ActorPawn != none )
		ActorPawn.Destroy();

	WeaponVisualizer = XGWeapon(Weapon.GetVisualizer());
	if( WeaponVisualizer != none )
	{
		WeaponVisualizer.Destroy();
	}

	class'XGItem'.static.CreateVisualizer(Weapon);
	WeaponVisualizer = XGWeapon(Weapon.GetVisualizer());
	ActorPawn = WeaponVisualizer.GetEntity();

	PawnLocationTag = X2WeaponTemplate(Weapon.GetMyTemplate()).UIArmoryCameraPointTag;

	if(DesiredRotation == NoneRotation)
		DesiredRotation = GetPlacementActor().Rotation;

	ActorPawn.SetLocation(GetPlacementActor().Location);
	ActorPawn.SetRotation(DesiredRotation);
	ActorPawn.SetHidden(false);
}

simulated function XComGameState_Unit GetUnit()
{
	if(CheckGameState != none)
		return XComGameState_Unit(CheckGameState.GetGameStateForObjectID(UnitReference.ObjectID));
	else
		return XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitReference.ObjectID));
}

simulated function PointInSpace GetPlacementActor()
{
	local Actor TmpActor;
	local array<Actor> Actors;
	local XComBlueprint Blueprint;
	local PointInSpace PlacementActor;

	foreach WorldInfo.AllActors(class'PointInSpace', PlacementActor)
	{
		if (PlacementActor != none && PlacementActor.Tag == PawnLocationTag)
			break;
	}

	if(PlacementActor == none)
	{
		foreach WorldInfo.AllActors(class'XComBlueprint', Blueprint)
		{
			if (Blueprint.Tag == PawnLocationTag)
			{
				Blueprint.GetLoadedLevelActors(Actors);
				foreach Actors(TmpActor)
				{
					PlacementActor = PointInSpace(TmpActor);
					if(PlacementActor != none)
					{
						break;
					}
				}
			}
		}
	}

	return PlacementActor;
}

//==============================================================================

// override for custom behavior
simulated function OnCancel()
{
	if (RemoveMenuEvent == '' || NavigationBackEvent == '')
	{
		Movie.Stack.PopFirstInstanceOfClass(class'UIArmory');
	}
	else
	{
		`XCOMGRI.DoRemoteEvent(NavigationBackEvent);
	}

	Movie.Pres.PlayUISound(eSUISound_MenuClose);
}

// override for custom behavior
simulated function OnAccept();

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	bHandled = true;

	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_MOUSE_5:
		case class'UIUtilities_Input'.const.FXS_KEY_TAB:
		case class'UIUtilities_Input'.const.FXS_BUTTON_RBUMPER:
			if(class'UIUtilities_Strategy'.static.GetXComHQ(true) != none)
			{
				if (class'UIUtilities_Strategy'.static.GetXComHQ().IsObjectiveCompleted('T0_M2_WelcomeToArmory'))
				{
					if (class'UIUtilities_Strategy'.static.HasSoldiersToCycleThrough(UnitReference, CanCycleTo))
						NextSoldier();
				}
				else
					Movie.Pres.PlayUISound(eSUISound_MenuClickNegative);
			}
			break;
		case class'UIUtilities_Input'.const.FXS_MOUSE_4:
		case class'UIUtilities_Input'.const.FXS_KEY_LEFT_SHIFT:
		case class'UIUtilities_Input'.const.FXS_BUTTON_LBUMPER:
			if(class'UIUtilities_Strategy'.static.GetXComHQ(true) != none)
			{
				if (class'UIUtilities_Strategy'.static.GetXComHQ().IsObjectiveCompleted('T0_M2_WelcomeToArmory'))
				{
					if (class'UIUtilities_Strategy'.static.HasSoldiersToCycleThrough(UnitReference, CanCycleTo))
						PrevSoldier();
				}
				else
					Movie.Pres.PlayUISound(eSUISound_MenuClickNegative);
			}
			break;
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
			OnCancel();
			break;
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
			OnAccept();
			break;
		default:
			bHandled = false;
			break;
	}

	return bHandled || super.OnUnrealCommand(cmd, arg);
}

function MoveCosmeticPawnOnscreen()
{
	local XComHumanPawn UnitPawn;
	local XComUnitPawn CosmeticPawn;

	UnitPawn = XComHumanPawn(ActorPawn);
	if (UnitPawn == none)
		return;

	CosmeticPawn = Movie.Pres.GetUIPawnMgr().GetCosmeticPawn(eInvSlot_SecondaryWeapon, UnitReference.ObjectID);
	if (CosmeticPawn == none)
		return;

	if (CosmeticPawn.IsInState('Onscreen'))
		return;

	if (CosmeticPawn.IsInState('Offscreen'))
	{
		CosmeticPawn.GotoState('StartOnscreenMove');
	}
	else
	{
		CosmeticPawn.GotoState('FinishOnscreenMove');
	}
}

simulated function Show()
{
	super.Show();
	NavHelp.Show();
}

simulated function Hide()
{
	super.Hide();
	NavHelp.Hide();
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	UpdateNavHelp();
	MoveCosmeticPawnOnscreen();
	class'UIUtilities'.static.DisplayUI3D(DisplayTag, name(CameraTag), `HQINTERPTIME);
}

simulated function OnLoseFocus()
{
	super.OnLoseFocus();
	// Immediately process commands to prevent 1 frame delay of screens hiding when navigating the armory
	Movie.ProcessQueuedCommands();
}

simulated function OnRemoved()
{
	super.OnRemoved();
	
	`XCOMGRI.DoRemoteEvent('CIN_UnhideArmoryStaff'); //Show the armory staff now that we are done

	// Only destroy the pawn when all UIArmory screens are closed
	if(ActorPawn != none)
	{
		if(bIsIn3D) Movie.Pres.Get3DMovie().HideDisplay(DisplayTag);
		ReleasePawn();
	}
}

//==============================================================================

defaultproperties
{
	Package         = "/ package/gfxArmory/Armory";
	InputState      = eInputState_Evaluate;
	PawnLocationTag = "UIPawnLocation_Armory";
	//UIDisplay       = "UIBlueprint_Customize"; // overridden in child screens
	//UIDisplayCam    = "UIBlueprint_Customize"; // overridden in child screens
	bUseNavHelp = true;
	bAnimateOnInit = true;

	bConsumeMouseEvents = true;
	MouseGuardClass = class'UIMouseGuard_RotatePawn';
}
