//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UITacticalQuickLaunch
//  AUTHOR:  Ryan McFall
//
//  PURPOSE: This screen provides the functionality for dynamically building a level from 
//           within a tactical battle, and restarting a battle after the level has been
//           built.
//
//---------------------------------------------------------------------------------------
//  Copyright (c) 2009-2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UITacticalQuickLaunch extends UIScreen 
	dependson(XComParcelManager, XComPlotCoverParcelManager)
	native(UI);

var XComPresentationLayer   Pres;
var XComTacticalController  TacticalController;
var bool                    bShouldInitCamera;
var bool                    bStoredMouseIsActive;
var bool                    bPathingNeedsRebuilt;

//Debug camera
var bool                    bDebugCameraActive;
var vector                  DefaultCameraPosition;
var vector                  DefaultCameraDirection;

//Map setup managers
var int ProcLevelSeed;   //Random seed to use when building levels
var XComEnvLightingManager      EnvLightingManager;
var XComTacticalMissionManager  TacticalMissionManager;
var XComParcelManager           ParcelManager;

//Game state objects
var XComGameStateHistory        History;
var XComGameState_BattleData    BattleDataState;

// stuff for ui interaction
var XComParcel HighlightedParcel;

var UIButton	Button_StartBattle;
var UIButton	Button_GenerateMap;
var UIButton    Button_RerollSpawnPoint;
var UIButton    Button_ChooseMapData;
var UIButton    Button_ChooseSquadLoadout;
var UIButton    Button_ToggleDebugCamera;
var UIButton    Button_ReturnToShell;

var UIPanel		InfoBoxContainer;
var UIBGBox		BGBox_InfoBox;
var UIText		Text_InfoBoxTitle;
var UIText		Text_InfoBoxText;

var UIList      ParcelDefinitionList;

enum ParcelSelectionEnum
{
	eParcelSelection_Random,	
	eParcelSelection_Specify
};

var ParcelSelectionEnum ParcelSelectionType;
var ParcelDefinition    SelectedParcel;

enum PlotCoverParcelSelectionEnum
{
	ePlotCoverParcelSelection_Random,	
	ePlotCoverParcelSelection_Specify
};

var PlotCoverParcelSelectionEnum    PlotCoverParcelSelectionType;
var PCPDefinition                   SelectedPlotCoverParcel;

//Set after hitting generate. Indicates that the map will need to be cleared before a new one can be generated
var bool bMapNeedsClear;
var bool MapGenerated;

//Set after hitting generate. Indicates that the map will need to be cleared before a new one can be generated
var bool bAutoStartBattleAfterGeneration;

//Variables to help display progress while building a level
var int LastPhase; 
var array<string> PhaseText;
var float PhaseTime;

//Variables to draw the parcel / plot data to the canvas
var int CanvasDrawScale;

// used to debug TacticalGameplayTags applied before mission begins
var array<Name> TacticalGameplayTags;

//----------------------------------------------------------------------------
// MEMBERS

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{	
	super.InitScreen(InitController, InitMovie, InitName);

	TacticalController = XComTacticalController(InitController);
	bStoredMouseIsActive = Movie.IsMouseActive();
	Movie.ActivateMouse();

	EnvLightingManager = `ENVLIGHTINGMGR;
	TacticalMissionManager = `TACTICALMISSIONMGR;
	ParcelManager = `PARCELMGR;

	//Set up the button elements
	BuildButton_StartBattle();
	BuildButton_GenerateMap();
	BuildButton_RerollSpawnPoint();
	BuildButton_ChooseMapData();
	BuildButton_ChooseSquadLoadout();
	BuildButton_ToggleDebugCamera();
	BuildButton_ReturnToShell();

	//Set up the info box element
	InfoBoxContainer = Spawn(class'UIPanel', self).InitPanel();
	InfoBoxContainer.AnchorTopRight().SetPosition(-550,50);
	BuildInfoBox();

	Pres = XComPresentationLayer(PC.Pres);

	InitHistory();

	AddHUDOverlayActor();

	InitializeCamera();

	`BATTLE.SetProfileSettings();

	Pres.Get2DMovie().Show();

	bMapNeedsClear = false;

	if(WorldInfo.IsPlayInEditor())
	{
		UpdatePIEMap();
	}

	`PARCELMGR.ResetIsFinishedGeneratingMap();
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();

	// make sure our battle data is the most recent version (it may be changed by child screens)
	BattleDataState = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
}

function InitHistory()
{
	local XComOnlineProfileSettings Profile;
	local XComGameState_GameTime TimeState;

	Profile = `XPROFILESETTINGS;

	History = `XCOMHISTORY;
	History.ResetHistory();

	// Grab the start state from the profile
	Pres.TacticalStartState = class'XComGameStateContext_TacticalGameRule'.static.CreateDefaultTacticalStartState_Singleplayer();	
	Profile.ReadTacticalGameStartState(Pres.TacticalStartState);

	foreach Pres.TacticalStartState.IterateByClassType(class'XComGameState_GameTime', TimeState)
	{
		break;
	}
	if (TimeState == none)
		class'XComGameState_GameTime'.static.CreateGameStartTime(Pres.TacticalStartState);
	History.AddGameStateToHistory(Pres.TacticalStartState);

	// Store off the battle data object in the start state
	BattleDataState = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
}

function UpdatePIEMap()
{
	local bool bFoundMatch;
	local string ForceLevel_PIE;	
	local int Index;

	ForceLevel_PIE = class'Engine'.static.GetEngine().ForceLevel_PIE;
	`log("ForceLevel_PIE is"@ForceLevel_PIE); 

	ParcelManager.ForceIncludeType = eForceInclude_None;

	`log("Searching plot definitions...");
	bFoundMatch = false;
	for( Index = 0; Index < ParcelManager.arrPlots.Length && !bFoundMatch; ++Index )
	{
		if( ForceLevel_PIE ~= ParcelManager.arrPlots[Index].MapName )
		{
			`log("Found matching plot definition...");

			ParcelManager.ForceIncludeType = eForceInclude_Plot;
			ParcelManager.ForceIncludePlot = ParcelManager.arrPlots[Index];

			BattleDataState.MapData.PlotMapName = ParcelManager.arrPlots[Index].MapName;
			BattleDataState.PlotSelectionType = ePlotSelection_Specify;

			bFoundMatch = true;
		}
	}

	`log("Searching parcel definitions...");
	for( Index = 0; Index < ParcelManager.arrAllParcelDefinitions.Length && !bFoundMatch; ++Index )
	{
		if( ForceLevel_PIE ~= ParcelManager.arrAllParcelDefinitions[Index].MapName )
		{
			`log("Found matching parcel definition...");

			ParcelManager.ForceIncludeType = eForceInclude_Parcel;
			ParcelManager.ForceIncludeParcel = ParcelManager.arrAllParcelDefinitions[Index];

			BattleDataState.PlotType = ParcelManager.arrAllParcelDefinitions[Index].arrPlotTypes[`SYNC_RAND(ParcelManager.arrAllParcelDefinitions[Index].arrPlotTypes.Length)].strPlotType;
			`log("Selecting plot type:"@BattleDataState.PlotType);
			BattleDataState.PlotSelectionType = ePlotSelection_Type;

			bFoundMatch = true;
		}
	}
}

function InitializeCamera()
{
	TacticalController.ClientSetCameraFade(false);
	TacticalController.SetInputState('Multiplayer_Inactive');
}

simulated private function BuildButton_StartBattle()
{
	Button_StartBattle = Spawn(class'UIButton', self);
	Button_StartBattle.InitButton('Button_StartBattle', "Start Battle", OnButtonStartBattleClicked, eUIButtonStyle_HOTLINK_BUTTON);
	Button_StartBattle.SetGamepadIcon(class'UIUtilities_Input'.const.ICON_A_X);
	Button_StartBattle.SetPosition(50, 50);
}

simulated private function OnButtonStartBattleClicked(UIButton button)
{
	if( IsIdle() && MapGenerated )
	{
		Movie.Pres.PlayUISound(eSUISound_MenuSelect);
		GotoState('GoingToBattle');
	}
	else if(IsIdle() && !bMapNeedsClear)
	{
		bAutoStartBattleAfterGeneration = true;
		GotoState('GeneratingMap');
	}
	else
	{
		PlaySound( SoundCue'SoundUI.NegativeSelection2Cue', true );
	}
}

simulated private function BuildButton_GenerateMap()
{
	Button_GenerateMap = Spawn(class'UIButton', self);
	Button_GenerateMap.InitButton('Button_GenerateMap', "Generate Map", OnButtonGenerateMapClicked, eUIButtonStyle_HOTLINK_BUTTON);		
	Button_GenerateMap.SetGamepadIcon(class'UIUtilities_Input'.const.ICON_B_CIRCLE);
	Button_GenerateMap.SetPosition(200, 50);
}

simulated private function OnButtonGenerateMapClicked(UIButton button)
{
	if( IsIdle() )
	{
		Movie.Pres.PlayUISound(eSUISound_MenuSelect);
		if(bMapNeedsClear)
		{
			`PARCELMGR.ResetIsFinishedGeneratingMap();
			ConsoleCommand("open TacticalQuickLaunch");
		}
		else
		{
			GotoState('GeneratingMap');
		}
	}
	else
	{
		PlaySound( SoundCue'SoundUI.NegativeSelection2Cue', true );
	}
}

simulated private function BuildButton_RerollSpawnPoint()
{
	Button_RerollSpawnPoint = Spawn(class'UIButton', self);
	Button_RerollSpawnPoint.InitButton('Button_RerollSpawnPoint', "Reroll SpawnPoint", OnButtonRerollSpawnPointClicked, eUIButtonStyle_HOTLINK_BUTTON);		
	Button_RerollSpawnPoint.SetGamepadIcon(class'UIUtilities_Input'.const.ICON_B_CIRCLE);
	Button_RerollSpawnPoint.SetPosition(200, 150);
	Button_RerollSpawnPoint.SetDisabled(true);
}

simulated private function OnButtonRerollSpawnPointClicked(UIButton button)
{
	if(IsIdle())
	{
		ParcelManager.BattleDataState = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

		ParcelManager.ChooseSoldierSpawn();
	}
}

simulated private function BuildButton_ChooseMapData()
{
	Button_ChooseMapData = Spawn(class'UIButton', self);
	Button_ChooseMapData.InitButton('Button_ChooseMapData', "Choose Map Data", OnButtonChooseMapDataClicked, eUIButtonStyle_HOTLINK_BUTTON);		
	Button_ChooseMapData.SetGamepadIcon(class'UIUtilities_Input'.const.ICON_Y_TRIANGLE);
	Button_ChooseMapData.SetPosition(350, 50);
}

simulated private function OnButtonChooseMapDataClicked(UIButton button)
{
	if( IsIdle() )
	{
		Movie.Pres.PlayUISound(eSUISound_MenuSelect);
		Movie.Stack.Push(Spawn(class'UITacticalQuickLaunch_MapData', Pres));
	}
	else
	{
		PlaySound( SoundCue'SoundUI.NegativeSelection2Cue', true );
	}
}

simulated private function BuildButton_ChooseSquadLoadout()
{
	Button_ChooseSquadLoadout = Spawn(class'UIButton', self);
	Button_ChooseSquadLoadout.InitButton('BuildButton_ChooseSquadLoadout', "Choose Squad", OnButtonChooseSquadLoadoutClicked, eUIButtonStyle_HOTLINK_BUTTON);		
	Button_ChooseSquadLoadout.SetGamepadIcon(class'UIUtilities_Input'.const.ICON_X_SQUARE);
	Button_ChooseSquadLoadout.SetPosition(50, 100);
}

simulated private function OnButtonChooseSquadLoadoutClicked(UIButton button)
{
	if( IsIdle() )
	{
		Movie.Pres.PlayUISound(eSUISound_MenuSelect);
		Movie.Stack.Push(Spawn(class'UITacticalQuickLaunch_SquadLoadout', Pres));
	}
	else
	{
		PlaySound( SoundCue'SoundUI.NegativeSelection2Cue', true );
	}
}

simulated private function BuildButton_ToggleDebugCamera()
{
	Button_ToggleDebugCamera = Spawn(class'UIButton', self);
	Button_ToggleDebugCamera.InitButton('BuildButton_ToggleDebugCamera', "Turn On Debug Camera", OnButton_ToggleDebugCameraClicked, eUIButtonStyle_HOTLINK_BUTTON);		
	Button_ToggleDebugCamera.SetGamepadIcon(class'UIUtilities_Input'.const.ICON_LSCLICK_L3);
	Button_ToggleDebugCamera.SetPosition(200, 100);
}

simulated function BuildButton_ReturnToShell()
{
	Button_ReturnToShell = Spawn(class'UIButton', self);
	Button_ReturnToShell.InitButton('Button_ReturnToShell', "Return To Shell", OnButtonReturnToShellClicked, eUIButtonStyle_HOTLINK_BUTTON);
	Button_ReturnToShell.SetGamepadIcon(class'UIUtilities_Input'.const.ICON_A_X);
	Button_ReturnToShell.SetPosition(50, 150);
}

simulated private function OnButtonReturnToShellClicked(UIButton button)
{
	OnUCancel();
}

simulated private function OnButton_ToggleDebugCameraClicked(UIButton button)
{
	local rotator DefaultCameraRotation;

	TacticalController.ToggleDebugCamera();	

	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	if( !bDebugCameraActive )
	{
		bDebugCameraActive = true;
		Button_ToggleDebugCamera.SetText("Turn OFF Debug Camera");
		//Movie.DeactivateMouse();		
	}
	else
	{
		bDebugCameraActive = false;
		Button_ToggleDebugCamera.SetText("Turn ON Debug Camera");
		//Movie.ActivateMouse();
	}

	if( bShouldInitCamera )
	{
		DefaultCameraRotation = rotator(DefaultCameraDirection);
		TacticalController.PlayerCamera.CameraCache.POV.Location = DefaultCameraPosition;
		TacticalController.PlayerCamera.CameraCache.POV.Rotation.Yaw = DefaultCameraRotation.Yaw;
		TacticalController.PlayerCamera.CameraCache.POV.Rotation.Pitch = DefaultCameraRotation.Pitch;
		bShouldInitCamera = false;
	}
}

simulated private function BuildInfoBox()
{
	BGBox_InfoBox = Spawn(class'UIBGBox', InfoBoxContainer);
	BGBox_InfoBox.InitBG('infoBox', 0, 0, 500, 175);

	Text_InfoBoxTitle = Spawn(class'UIText', InfoBoxContainer);
	Text_InfoBoxTitle.InitText('infoBoxTitle', "<Empty>", true);
	Text_InfoBoxTitle.SetWidth(480);
	Text_InfoBoxTitle.SetY(5);
	Text_InfoBoxTitle.SetText("Instructions:");

	Text_InfoBoxText = Spawn(class'UIText', InfoBoxContainer);	
	Text_InfoBoxText.InitText('infoBoxText', "<Empty>", true);
	Text_InfoBoxText.SetWidth(480);
	Text_InfoBoxText.SetY(45);
	Text_InfoBoxText.SetText("1. Choose Map Data\n2. Generate Map\n3. Wait for map generation to complete\n4. Start Battle or Clear Map");
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	bHandled = true;

	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_KEY_TAB:
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
			OnButtonStartBattleClicked(Button_StartBattle);
			break;
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
			OnButtonGenerateMapClicked(Button_GenerateMap);
			break;
		case class'UIUtilities_Input'.const.FXS_BUTTON_Y:
			OnButtonChooseMapDataClicked(Button_ChooseMapData);
			break;
		case class'UIUtilities_Input'.const.FXS_BUTTON_X:
			OnButtonChooseSquadLoadoutClicked(Button_ChooseSquadLoadout);
			break;
		case class'UIUtilities_input'.const.FXS_BUTTON_L3:
			OnButton_ToggleDebugCameraClicked(Button_ToggleDebugCamera);
			break;
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_DOWN:
			OnLMouseDown();
			break;		
		default:
			bHandled = false;
			break;
	}

	return bHandled || super.OnUnrealCommand(cmd, arg);
}

simulated public function OnUCancel()
{
	Movie.Pres.PlayUISound(eSUISound_MenuClose);
	`XCOMHISTORY.ResetHistory(); //Don't leave any of our battle data behind (causes problems for obstacle course launching)
	ConsoleCommand("disconnect");
}

simulated public function OnLMouseDown()
{
	if(HighlightedParcel != none)
	{
		// we've clicked the highlighted parcel, bring up a list of parcel definitions that can be placed on it
		// so the user can custom select one
		ShowSelectParcelDefinitionList(HighlightedParcel);
	}
}

simulated private function array<ParcelDefinition> GetParcelDefsThatFit(XComParcel Parcel, bool ObjectiveParcels)
{
	local array<ParcelDefinition> ParcelDefinitions;
	local ParcelDefinition ParcelDef;
	local int Index;
	local Rotator Rot;

	if(ObjectiveParcels)
	{
		ParcelManager.GetValidParcelDefinitionsForObjective(ParcelManager.arrAllParcelDefinitions, ParcelDefinitions);
	}
	else
	{
		ParcelDefinitions = ParcelManager.arrAllParcelDefinitions;
	}

	// remove any parcels that don't fit
	for (Index = 0; Index < ParcelDefinitions.Length; Index++)
	{
		ParcelDef = ParcelDefinitions[Index];
		if(ParcelDef.eSize != Parcel.GetSizeType() 
			|| !ParcelManager.MeetsFacingAndEntranceRequirements(ParcelDef, Parcel, Rot)
			|| ParcelDef.arrPlotTypes.Find('strPlotType', ParcelManager.PlotType.strType) == INDEX_NONE)
		{
			ParcelDefinitions.Remove(Index, 1);
			Index--;
		}
	}

	return ParcelDefinitions;
}

simulated private function ShowSelectParcelDefinitionList(XComParcel Parcel)
{
	local array<ParcelDefinition> ParcelDefinitions;
	local ParcelDefinition ParcelDef;
	local UITacticalQuickLaunch_ListItem ListItem;

	if(Parcel != none && ParcelDefinitionList == none)
	{
		ParcelDefinitionList = Spawn(class'UIList', self);
		ParcelDefinitionList.InitList(, 200, 200, 800, 700, false, true);
		ParcelDefinitionList.OnItemClicked = OnParcelDefinitionItemClicked;

		// add a list item for "keep current". Effectively the cancel button
		ListItem = Spawn(class'UITacticalQuickLaunch_ListItem', ParcelDefinitionList.itemContainer);
		ListItem.InitListItem("(Keep Current)");
		ListItem.metadataString = "Cancel";

		// add non-objective options
		ParcelDefinitions = GetParcelDefsThatFit(Parcel, false);
		foreach ParcelDefinitions(ParcelDef)
		{
			ListItem = Spawn(class'UITacticalQuickLaunch_ListItem', ParcelDefinitionList.itemContainer);
			ListItem.InitListItem(ParcelDef.MapName);
			ListItem.metadataString = "Nonobjective";
			ListItem.ParcelDef = ParcelDef;
		}

		// add the objective parcel options
		if(Parcel.CanBeObjectiveParcel)
		{
			ParcelDefinitions = GetParcelDefsThatFit(Parcel, true);
			foreach ParcelDefinitions(ParcelDef)
			{
				ListItem = Spawn(class'UITacticalQuickLaunch_ListItem', ParcelDefinitionList.itemContainer);
				ListItem.InitListItem("(Objective) " $ ParcelDef.MapName);
				ListItem.metadataString = "Objective";
				ListItem.ParcelDef = ParcelDef;
			}
		}
	}

	if(ParcelDefinitionList.scrollbar != none) 
	{
		ParcelDefinitionList.scrollbar.Reset();
	}
}

// After changing out a parcel, we need to remove any states for interactive objects
// that were created for actors in the old parcel. Otherwise, there will be phantom states
// with no associated actors flying around and confusing the game.
private native function PurgeLostObjectStates(Vector LevelOffset);

function OnParcelDefinitionItemClicked(UIList listControl, int itemIndex)
{
	local UITacticalQuickLaunch_ListItem SelectedItem;
	local Rotator Rot;
	local int Index;
	
	assert(HighlightedParcel != none);
	if(HighlightedParcel != none)
	{
		SelectedItem = UITacticalQuickLaunch_ListItem(listControl.GetItem(itemIndex));

		if(SelectedItem.metadataString != "Cancel" && ParcelManager.MeetsFacingAndEntranceRequirements(SelectedItem.ParcelDef, HighlightedParcel, Rot))
		{
			PurgeLostObjectStates(HighlightedParcel.Location);
			HighlightedParcel.CleanupSpawnedEntrances();

			// remove the old parcel data from the save data store
			for (Index = 0; Index < BattleDataState.MapData.ParcelData.Length; ++Index)
			{
				if (BattleDataState.MapData.ParcelData[ Index ].MapName == HighlightedParcel.ParcelDef.MapName)
				{
					BattleDataState.MapData.ParcelData.Remove( Index, 1 );
					break;
				}
			}
			`assert( BattleDataState.MapData.ParcelData.Length == (ParcelManager.arrParcels.Length - 1) );

			`MAPS.RemoveStreamingMapByNameAndLocation(HighlightedParcel.ParcelDef.MapName, HighlightedParcel.Location);
			ParcelManager.ClearLinksFromParcelPatrolPathsToPlotPaths();
			ParcelManager.InitParcelWithDef(HighlightedParcel, SelectedItem.ParcelDef, Rot, true);
			bPathingNeedsRebuilt = true;

			// if they selected one of the "objective" parcel types, i.e. they want to change the
			// map *and* make this the new objective parcel, then set the new objective parcel and
			// clear the previous one
			if(SelectedItem.metadataString == "Objective")
			{
				ParcelManager.ObjectiveParcel = HighlightedParcel;
				Button_StartBattle.SetDisabled(false);
			}
			else if(HighlightedParcel == ParcelManager.ObjectiveParcel)
			{
				ParcelManager.ObjectiveParcel = none;

				// plots with only a single parcel are test plots. Allow those to start without a valid objective parcel
				Button_StartBattle.SetDisabled(BattleDataState.MapData.ParcelData.Length > 1);
			}
		}
	}

	`assert(ParcelDefinitionList == listControl);
	ParcelDefinitionList.Remove();
	ParcelDefinitionList = none;
	HighlightedParcel = none;
}

function bool IsIdle()
{
	return IsInState('Idle');
}

simulated private function GetPlotRenderBounds(out Vector2D UpperLeft, optional out Vector2D Dimension)
{
	local Vector2D ViewportSize;

	if (`XWORLD == none)
		return;

	Dimension.X = `XWORLD.NumX * CanvasDrawScale;
	Dimension.Y = `XWORLD.NumY * CanvasDrawScale;

	class'Engine'.static.GetEngine().GameViewport.GetViewportSize(ViewportSize);

	UpperLeft.X = ViewportSize.X - Dimension.X - 60;
	UpperLeft.Y = BGBox_InfoBox.Y + 250;
}

simulated private function GetParcelRenderBounds(XComParcel Parcel, out Vector2D UpperLeft, optional out Vector2D Dimension)
{
	local Vector2D PlotCorner;
	local IntPoint OutParcelBoundsMin;
	local IntPoint OutParcelBoundsMax;

	GetPlotRenderBounds(PlotCorner);
	Parcel.GetTileBounds(OutParcelBoundsMin, OutParcelBoundsMax);

	UpperLeft.X = (float(OutParcelBoundsMin.X) * CanvasDrawScale) + PlotCorner.X;
	UpperLeft.Y = (float(OutParcelBoundsMin.Y) * CanvasDrawScale) + PlotCorner.Y;

	Dimension.X = (OutParcelBoundsMax.X - OutParcelBoundsMin.X)  * CanvasDrawScale;
	Dimension.Y = (OutParcelBoundsMax.Y - OutParcelBoundsMin.Y) * CanvasDrawScale;
}

simulated private function Vector2D GetSpawnRenderLocation(XComGroupSpawn Spawn)
{
	local Vector2D PlotCorner;
	local TTile TileLoc;
	local Vector2D Result;

	if (`XWORLD != none && Spawn != none)
	{
		GetPlotRenderBounds(PlotCorner);
		TileLoc = `XWORLD.GetTileCoordinatesFromPosition(Spawn.Location);

		Result.X = (float(TileLoc.X) * CanvasDrawScale) + PlotCorner.X;
		Result.Y = (float(TileLoc.Y) * CanvasDrawScale) + PlotCorner.Y;
	}

	return Result;
}

simulated private function bool GetObjectiveRenderLocation(out Vector2D Result)
{
	local Vector2D PlotCorner;
	local Vector ObjectivesCenter;
	local TTile TileLoc;
	GetPlotRenderBounds(PlotCorner);
	if(TacticalMissionManager.GetObjectivesCenterpoint(ObjectivesCenter))
	{
		TileLoc = `XWORLD.GetTileCoordinatesFromPosition(ObjectivesCenter);

		Result.X = (float(TileLoc.X) * CanvasDrawScale) + PlotCorner.X;
		Result.Y = (float(TileLoc.Y) * CanvasDrawScale) + PlotCorner.Y;
		
		return true;
	}
	else
	{
		return false;
	}
}

simulated event PostRenderFor(PlayerController kPC, Canvas kCanvas, vector vCameraPosition, vector vCameraDir)
{
	local int Index;
	local XComParcel IterateParcel;	

	local Vector2D ScreenLocation_PlotCorner;
	local Vector2D PlotSize;

	local Vector2D ParcelUpperLeft;
	local Vector2D ParcelDimension;
	local float Highlight;

	//Soldier spawn handling
	local Vector2D ScreenLocation_Spawn;
	local XGBattle Battle;
	local XComGroupSpawn GroupSpawn;

	//Objective parcel handling
	local Vector2D ScreenLocation_ObjectivesCenter;

	if( bDebugCameraActive && !ParcelManager.IsGeneratingMap())
	{
		Text_InfoBoxTitle.SetText("Debug Camera");
		Text_InfoBoxText.SetText("Camera Position:"@vCameraPosition@"\nDirection:"@vCameraDir);
	}

	if( bMapNeedsClear && kCanvas != none )
	{
		GetPlotRenderBounds(ScreenLocation_PlotCorner, PlotSize);

		//Draw rectangles for the parcels
		for( Index = 0; Index < ParcelManager.arrParcels.Length; ++Index )
		{
			IterateParcel = ParcelManager.arrParcels[Index];
			GetParcelRenderBounds(IterateParcel, ParcelUpperLeft, ParcelDimension);

			kCanvas.SetPos(ParcelUpperLeft.X, ParcelUpperLeft.Y);

			Highlight = IterateParcel == HighlightedParcel ? 1.0 : 1.5;

			if( IterateParcel == ParcelManager.ObjectiveParcel )
			{
				kCanvas.SetDrawColor(205 * Highlight, 50 * Highlight, 50 * Highlight, 200);
			}
			else
			{
				kCanvas.SetDrawColor(50 * Highlight, 50 * Highlight, 205 * Highlight, 200);				
			}	

			if( `MAPS.IsLevelLoaded(name(IterateParcel.ParcelDef.MapName), true) )
			{
				kCanvas.DrawRect( ParcelDimension.X, ParcelDimension.Y);
			}
			else
			{
				kCanvas.DrawBox( ParcelDimension.X, ParcelDimension.Y);
			}
		}

		//Draw text for the parcels
		for( Index = 0; Index < ParcelManager.arrParcels.Length; ++Index )
		{
			IterateParcel = ParcelManager.arrParcels[Index];
			GetParcelRenderBounds(IterateParcel, ParcelUpperLeft, ParcelDimension);

			kCanvas.SetPos(ParcelUpperLeft.X, ParcelUpperLeft.Y);
			kCanvas.SetDrawColor(255, 255, 255);
			kCanvas.DrawText(IterateParcel.ParcelDef.MapName@(IterateParcel == ParcelManager.ObjectiveParcel ? "\n(Objective:"@TacticalMissionManager.ActiveMission.MissionName@")" : "" ));
		}

		//If the map has finished generating, show objective / spawn information if it is available
		if( !ParcelManager.IsGeneratingMap() )
		{
			Battle = `BATTLE;
			foreach Battle.AllActors(class'XComGroupSpawn', GroupSpawn)
			{
				ScreenLocation_Spawn = GetSpawnRenderLocation(GroupSpawn);

				kCanvas.SetPos(ScreenLocation_Spawn.X, ScreenLocation_Spawn.Y);

				if( GroupSpawn == ParcelManager.SoldierSpawn )
				{
					kCanvas.SetDrawColor(255, 255, 255);
					kCanvas.DrawText("Spawn (" $ ParcelManager.SoldierSpawn.Score $ ")");

					if( GetObjectiveRenderLocation(ScreenLocation_ObjectivesCenter) )
					{
						kCanvas.SetDrawColor(0, 255, 0);
						kCanvas.Draw2DLine(ScreenLocation_Spawn.X, ScreenLocation_Spawn.Y,
										   ScreenLocation_ObjectivesCenter.X, ScreenLocation_ObjectivesCenter.Y,
										   kCanvas.DrawColor);
					}
				}
				else
				{
					kCanvas.SetDrawColor(50, 50, 50);
					kCanvas.DrawText("(" $ GroupSpawn.Score $ ")");
				}

				kCanvas.DrawRect(CanvasDrawScale * 3, CanvasDrawScale * 3); // 3x3 tile spawn
			}
		}		

		//Draw the plot rect last so that its text is not overwritten by parcel / exit rectangles
		kCanvas.SetPos(ScreenLocation_PlotCorner.X, ScreenLocation_PlotCorner.Y);
		kCanvas.SetDrawColor(50, 180, 50, 80);
		kCanvas.DrawRect(PlotSize.X, PlotSize.Y);

		kCanvas.SetPos(ScreenLocation_PlotCorner.X, ScreenLocation_PlotCorner.Y);
		kCanvas.SetDrawColor(255, 255, 255);
		kCanvas.DrawText(BattleDataState.MapData.PlotMapName);
	}
}

event Tick(float DeltaTime)
{
	local XComParcel Parcel;
	local Vector2D UpperLeft;
	local Vector2D Dimensions;
	local Vector2D MousePos;

	super.Tick(DeltaTime);

	if(ParcelManager != none && ParcelDefinitionList == none)
	{
		HighlightedParcel = none;
		MousePos = class'Engine'.static.GetEngine().GameViewport.GetMousePosition();
		foreach ParcelManager.arrParcels(Parcel)
		{
			GetParcelRenderBounds(Parcel, UpperLeft, Dimensions);
			if(MousePos.X > UpperLeft.X 
				&& MousePos.Y > UpperLeft.Y
				&& MousePos.X < (UpperLeft.X + Dimensions.X)
				&& MousePos.Y < (UpperLeft.Y + Dimensions.Y))
			{
				HighlightedParcel = Parcel;
				break;
			}
		}
	}
}

simulated function CleanupMaps()
{
	`MAPS.RemoveAllStreamingMaps();	
	ParcelManager.CleanupLevelReferences();
}

auto state Idle
{
	simulated event BeginState(name PreviousStateName)
	{	
	}
}

state GoingToBattle
{
	function StartBattle()
	{
		local XComGameState TacticalStartState;
		local XComGameState_BattleData LatestBattleDataState;
		local XComGameState_HeadquartersXCom XComHQ;
		local array<int> RemoveUnits;
		local XComGameState_Unit ExamineUnit;
		local int Index;
		local Name GameplayTag;

		// this needs to be a separate function or else unreal will bail on the latent function as soon as we pop
		// ourself, instead of finishing and initing the battle		
		Movie.Stack.Pop(self);

		//Mark that we are tactical quick launch
		TacticalStartState = History.GetStartState();
		LatestBattleDataState = XComGameState_BattleData(TacticalStartState.GetGameStateForObjectID(BattleDataState.ObjectID));
		LatestBattleDataState.bIsTacticalQuickLaunch = true;

		//Since we are a tactical quick launch game, remove any units that are not in this battle
		//***
		foreach TacticalStartState.IterateByClassType(class'XComGameState_Unit', ExamineUnit)
		{
			if (ExamineUnit.ControllingPlayer.ObjectID == 0)
			{
				RemoveUnits.AddItem(ExamineUnit.ObjectID);
			}
		}

		for (Index = 0; Index < RemoveUnits.Length; ++Index)
		{
			TacticalStartState.PurgeGameStateForObjectID(RemoveUnits[Index]);
		}
		//***

		// update the headquarters squad to contain our TQL soldiers
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		XComHQ = XComGameState_HeadquartersXCom(TacticalStartState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		TacticalStartState.AddStateObject(XComHQ);

		foreach TacticalGameplayTags(GameplayTag)
		{
			if( XComHQ.TacticalGameplayTags.Find(GameplayTag) == INDEX_NONE )
			{
				XComHQ.TacticalGameplayTags.AddItem(GameplayTag);
			}
		}

		XComHQ.Squad.Length = 0;
		foreach TacticalStartState.IterateByClassType(class'XComGameState_Unit', ExamineUnit)
		{
			if (ExamineUnit.GetTeam() == eTeam_XCom)
			{
				XComHQ.Squad.AddItem(ExamineUnit.GetReference());
			}
		}

		`TACTICALGRI.InitBattle();
	}

	function UpdatePlotSwaps()
	{
		local string PlotType;

		PlotType = ParcelManager.GetPlotDefinition(BattleDataState.MapData.PlotMapName).strType;
		class'XComPlotSwapData'.static.AdjustParcelsForBiomeType(BattleDataState.MapData.Biome, PlotType);
		class'XComBrandManager'.static.SwapBrandsForParcels(BattleDataState.MapData);
	}

Begin:
	// make sure we aren't still loading anything
	while(!`MAPS.IsStreamingComplete())
	{
		Sleep(0);
	}

	if(bPathingNeedsRebuilt)
	{
		ParcelManager.RebuildWorldData();
		UpdatePlotSwaps();
		bPathingNeedsRebuilt = false;
	}

	if( !bStoredMouseIsActive )
	{
		Movie.DeactivateMouse();
	}

	RemoveHUDOverlayActor();

	//Make sure the debug camera is off
	if( bDebugCameraActive )
	{
		OnButton_ToggleDebugCameraClicked(Button_ToggleDebugCamera);
	}

	StartBattle();
}

state ClearingMap
{
Begin:
	while( `MAPS.NumStreamingMaps() > 0 )
	{
		CleanupMaps();
		Sleep(0.1f);
	}

	PopState();
}

state GeneratingMap
{
	simulated event BeginState(name PreviousStateName)
	{	
		local XComOnlineProfileSettings Profile;
		local XComGameState StartState;

		StartState = History.GetStartState();

		Profile = `XPROFILESETTINGS;
		Profile.WriteTacticalGameStartState(StartState);
		`ONLINEEVENTMGR.SaveProfileSettings();

		// add the strategy game start info to the tactical start state
		class'XComGameStateContext_StrategyGameRule'.static.CreateStrategyGameStart(StartState, , , `DifficultySetting);

		if( !bDebugCameraActive )
		{
			OnButton_ToggleDebugCameraClicked(Button_ToggleDebugCamera);
		}
			
		Button_StartBattle.SetDisabled(true);
		Button_GenerateMap.SetDisabled(true);
		Button_ChooseMapData.SetDisabled(true);
		Button_ChooseSquadLoadout.SetDisabled(true);

		MapGenerated = false;
	}

	simulated event EndState(name NextStateName)
	{
		WorldInfo.MyLightClippingManager.BuildFromScript();
		`XWORLDINFO.MyLocalEnvMapManager.SetEnableCaptures(TRUE);
	}

	function LoadPlot()
	{
		//General locals
		local MissionDefinition Mission;
		local XComParcelManager ParcelMgr;
		local array<PlotDefinition> CandidatePlots;
		local PlotDefinition SelectedPlotDef;
		local int Index;
		local Vector ZeroVector;
		local Rotator ZeroRotator;
		local LevelStreaming PlotLevel;

		ParcelMgr = `PARCELMGR;

		// get the pool of possible plots
		switch(BattleDataState.PlotSelectionType)
		{
		case ePlotSelection_Random:
			// any plot will do
			CandidatePlots = ParcelMgr.arrPlots;
			break;

		case ePlotSelection_Type:
			// all plots of the desired type
			ParcelMgr.GetPlotDefinitionsForPlotType(BattleDataState.PlotType, BattleDataState.MapData.Biome, CandidatePlots);
			break;

		case ePlotSelection_Specify:
			// the specified plot map
			if( BattleDataState.MapData.PlotMapName != "" )
			{
				CandidatePlots.AddItem(ParcelManager.GetPlotDefinition(BattleDataState.MapData.PlotMapName, BattleDataState.MapData.Biome));
			}
			break;
		}

		// Now filter the candidate list by mission type (some plots only support certain mission types)
		if(BattleDataState.m_iMissionType >= 0)
		{
			Mission = `TACTICALMISSIONMGR.arrMissions[BattleDataState.m_iMissionType];
			ParcelMgr.RemovePlotDefinitionsThatAreInvalidForMission(CandidatePlots, Mission);
			if( CandidatePlots.Length == 0 )
			{
				// none of the candidates were valid for the mission, so fall back to using any plot
				CandidatePlots = ParcelMgr.arrPlots;
				ParcelMgr.RemovePlotDefinitionsThatAreInvalidForMission(CandidatePlots, Mission);
				`Redscreen("Selected parcel or parcel type does not support the selected mission, falling back to to using any valid plot.");
			}
		}

		// if we aren't in specifying an exact map, remove all maps that are marked as exclude from strategy
		if(BattleDataState.PlotSelectionType != ePlotSelection_Specify)
		{
			for(Index = CandidatePlots.Length - 1; Index >= 0; Index--)
			{
				if(CandidatePlots[Index].ExcludeFromStrategy)
				{
					CandidatePlots.Remove(Index, 1);
				}
			}
		}

		// and pick one
		Index = `SYNC_RAND_TYPED(CandidatePlots.Length);
		SelectedPlotDef = CandidatePlots[Index];

		// notify the deck manager that we have used this plot
		class'X2CardManager'.static.GetCardManager().MarkCardUsed('Plots', SelectedPlotDef.MapName);

		// need to add the plot type to make sure it's in the deck
		class'X2CardManager'.static.GetCardManager().AddCardToDeck('PlotTypes', ParcelManager.GetPlotDefinition(SelectedPlotDef.MapName).strType);
		class'X2CardManager'.static.GetCardManager().MarkCardUsed('PlotTypes', ParcelManager.GetPlotDefinition(SelectedPlotDef.MapName).strType);

		// load the selected plot
		BattleDataState.MapData.PlotMapName = SelectedPlotDef.MapName;
		PlotLevel = `MAPS.AddStreamingMap(BattleDataState.MapData.PlotMapName, ZeroVector, ZeroRotator, false, true);
		PlotLevel.bForceNoDupe = true;

		// make sure our biome is sane for the plot we selected
		if(BattleDataState.MapData.Biome == "" 
			|| (SelectedPlotDef.ValidBiomes.Length > 0 && SelectedPlotDef.ValidBiomes.Find(BattleDataState.MapData.Biome) == INDEX_NONE))
		{
			if(SelectedPlotDef.ValidBiomes.Length > 0)
			{
				Index = `SYNC_RAND(SelectedPlotDef.ValidBiomes.Length);
				BattleDataState.MapData.Biome = SelectedPlotDef.ValidBiomes[Index];
			}
			else
			{
				BattleDataState.MapData.Biome = "";
			}
		}
	}

	simulated event Tick( float fDeltaT )
	{
		local int Phase;
		if( ParcelManager.IsGeneratingMap() )
		{
			Phase = ParcelManager.GetGenerateMapPhase();
			if( Phase != LastPhase )
			{
				LastPhase = Phase;
				PhaseTime = 0.0f;
			}
		}

		PhaseTime += fDeltaT;
	}

	simulated function UpdatePhaseText(int Phase)
	{
		local int Index;
		local string TextAccumulator;

		//PhaseText will grow as new indices are assigned
		PhaseText[Phase] = ParcelManager.GetGenerateMapPhaseText()@":"@PhaseTime@" sec";

		for( Index = 1; Index < PhaseText.Length; ++Index )
		{
			TextAccumulator = TextAccumulator @ PhaseText[Index] @ "\n";
		}

		Text_InfoBoxText.SetText(TextAccumulator);
	}

Begin:
	
	PushState('ClearingMap');

	LoadPlot();

	bMapNeedsClear = true;

	//Wait for the plot to load
	while (!`MAPS.IsStreamingComplete())
	{
		Sleep(0.0f);
	}

	ProcLevelSeed = class'Engine'.static.GetEngine().GetARandomSeed();
	BattleDataState.iLevelSeed = ProcLevelSeed;
	ParcelManager.bBlockingLoadParcels = false; //Set the ParcelManager to operate in async mode
	ParcelManager.GenerateMap(ProcLevelSeed);
	
	Text_InfoBoxTitle.SetText("Generating Map");
	LastPhase = ParcelManager.GetGenerateMapPhase();
	PhaseTime = 0.0f;
	PhaseText.Length = 0;

	//Wait while the parcel mgr builds the map for us
	while( ParcelManager.IsGeneratingMap() )
	{
		UpdatePhaseText(ParcelManager.GetGenerateMapPhase());
		Sleep(0.1f);
	}

	// resave the profile so that the plot and parcel cards we've used will be saved to the bottom of the deck
	`ONLINEEVENTMGR.SaveProfileSettings();

	MapGenerated = true;

	Button_GenerateMap.SetText("Clear Map");
	Button_StartBattle.SetDisabled(false);
	Button_ChooseSquadLoadout.SetDisabled(false);
	Button_RerollSpawnPoint.SetDisabled(false);
	
	if( !WorldInfo.IsPlayInEditor() )
	{
		//PIE cannot reload the quick launch map, so cannot be cleared
		Button_GenerateMap.SetDisabled(false);
		Button_ChooseMapData.SetDisabled(false);		
	}
	
	if(bAutoStartBattleAfterGeneration)
	{
		GotoState('GoingToBattle');
	}
	else
	{
		GotoState('Idle');
	}
}

//==============================================================================
//		DEFAULTS:
//==============================================================================

defaultproperties
{
	bShouldInitCamera = true
	DefaultCameraPosition = (X=2968.12, Y=5473.12, Z=3072.99)
	DefaultCameraDirection = (X=-0.51, Y=-0.68, Z=-0.53)

	CanvasDrawScale = 4
}
