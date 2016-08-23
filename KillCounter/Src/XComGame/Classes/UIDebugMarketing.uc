//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIDebugMarketing
//  AUTHOR:  Ryan McFall
//
//  PURPOSE: Provides a user interface for manipulating marketing controls
//
//---------------------------------------------------------------------------------------
//  Copyright (c) 2009-2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIDebugMarketing extends UIScreen;

var XComOnlineProfileSettings	ProfileSettings;
var XComPresentationLayer		Pres;
var XComPlayerController		PlayerController;
var XComTacticalInput			TacticalInput;

var XComCheatManager				GeneralCheatManager;
var XComTacticalCheatManager		TacticalCheatManager;
var XComHeadquartersCheatManager	StrategyCheatManager;

//UI controls
var UIPanel		AllContainer;
var UIPanel     FrameInfoContainer;
var UIBGBox		InfoBG;
var UIText		InfoTitle;
var UIText		InfoText;

var UIButton	Button_AcceptChanges;
var UICheckbox  Checkbox_2DUI;
var UICheckbox  Checkbox_3DUI;
var UICheckbox  Checkbox_UnitFlags;
var UICheckbox  Checkbox_WorldMessages;
var UICheckbox  Checkbox_LootEffects;
var UICheckbox  Checkbox_Narrative;
var UICheckbox  Checkbox_FOW;
var UICheckbox  Checkbox_BuildingVisibility;
var UICheckbox  Checkbox_CutoutBox;
var UICheckbox  Checkbox_Pathing;
var UICheckbox  Checkbox_SoldierChatter;
var UICheckbox  Checkbox_DisableMusic;
var UICheckbox  Checkbox_DisableAmbience;
var UICheckbox  Checkbox_ConcealmentTiles;
var UICheckbox  Checkbox_DisableUnitShaders;
var UICheckbox  Checkbox_DisableTooltips;
var UICheckbox  Checkbox_DisableLookAtBack;

//----------------------------------------------------------------------------
// MEMBERS

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{	
	super.InitScreen(InitController, InitMovie, InitName);

	AllContainer         = Spawn(class'UIPanel', self);

	FrameInfoContainer = Spawn(class'UIPanel', self);
	InfoBG   = Spawn(class'UIBGBox', FrameInfoContainer);
	InfoTitle= Spawn(class'UIText', FrameInfoContainer);
	InfoText = Spawn(class'UIText', FrameInfoContainer);

	AllContainer.InitPanel('allContainer');
	AllContainer.SetPosition(50, 50);
	AllContainer.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);

	FrameInfoContainer.InitPanel('InfoContainer');
	FrameInfoContainer.SetPosition(50, 50);
	FrameInfoContainer.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);

	InfoBG.InitBG('infoBox', 0, 0, 500, 800);
	InfoTitle.InitText('infoBoxTitle', "<Empty>", true);
	InfoTitle.SetWidth(300);
	InfoTitle.SetX(10);
	InfoTitle.SetY(60);
	InfoText.InitText('infoBoxText', "<Empty>", true);
	InfoText.SetWidth(300);
	InfoText.SetX(10);
	InfoText.SetY(50);

	Button_AcceptChanges = Spawn(class'UIButton', FrameInfoContainer);
	Button_AcceptChanges.InitButton('applyChanges', "Apply Changes", ApplyChanges, eUIButtonStyle_HOTLINK_BUTTON);
	Button_AcceptChanges.SetAnchor(class'UIUtilities'.const.ANCHOR_TOP_LEFT);
	Button_AcceptChanges.SetX(100);
	Button_AcceptChanges.SetY(750);
	
	InitializeMarketingControls();

	SetTimer(0.1f, false, nameof(InitCheckboxes));

	PlayerController = InitController;
	TacticalInput = XComTacticalInput(PlayerController.PlayerInput);
	
	Pres = XComPresentationLayer(PC.Pres);

	TacticalCheatManager = XComTacticalCheatManager(PC.CheatManager);
	StrategyCheatManager = XComHeadquartersCheatManager(PC.CheatManager);
	GeneralCheatManager = XComCheatManager(PC.CheatManager);

	//Automatically disable redscreens when entering marketing mode
	`XENGINE.TemporarilyDisableRedscreens();

	ProfileSettings = `XPROFILESETTINGS;
}

function InitializeMarketingControls()
{
	local int PositionX;
	local int PositionY;
	local int Spacing;

	PositionX = 10;
	PositionY = 10;
	Spacing = 30;

	Checkbox_2DUI = Spawn(class'UICheckbox', FrameInfoContainer);
	Checkbox_2DUI.InitCheckbox('Checkbox_UI2D', "Hide 2D UI", false, ToggleCheckbox);
	Checkbox_2DUI.SetTextStyle(class'UICheckbox'.const.STYLE_TEXT_ON_THE_RIGHT).SetPosition(PositionX, PositionY);	

	PositionY += Spacing;

	Checkbox_3DUI = Spawn(class'UICheckbox', FrameInfoContainer);
	Checkbox_3DUI.InitCheckbox('Checkbox_UI3D', "Hide 3D UI", false, ToggleCheckbox);
	Checkbox_3DUI.SetTextStyle(class'UICheckbox'.const.STYLE_TEXT_ON_THE_RIGHT).SetPosition(PositionX, PositionY);

	PositionY += Spacing;

	Checkbox_UnitFlags = Spawn(class'UICheckbox', FrameInfoContainer);
	Checkbox_UnitFlags.InitCheckbox('Checkbox_UnitFlags', "Hide Unit Flags", false, ToggleCheckbox);
	Checkbox_UnitFlags.SetTextStyle(class'UICheckbox'.const.STYLE_TEXT_ON_THE_RIGHT).SetPosition(PositionX, PositionY);

	PositionY += Spacing;

	Checkbox_WorldMessages = Spawn(class'UICheckbox', FrameInfoContainer);
	Checkbox_WorldMessages.InitCheckbox('Checkbox_WorldMessages', "Hide Flyovers", false, ToggleCheckbox);
	Checkbox_WorldMessages.SetTextStyle(class'UICheckbox'.const.STYLE_TEXT_ON_THE_RIGHT).SetPosition(PositionX, PositionY);

	PositionY += Spacing;

	Checkbox_LootEffects = Spawn(class'UICheckbox', FrameInfoContainer);
	Checkbox_LootEffects.InitCheckbox('Checkbox_LootEffects', "Hide Loot UI", false, ToggleCheckbox);
	Checkbox_LootEffects.SetTextStyle(class'UICheckbox'.const.STYLE_TEXT_ON_THE_RIGHT).SetPosition(PositionX, PositionY);

	PositionY += Spacing;

	Checkbox_Narrative = Spawn(class'UICheckbox', FrameInfoContainer);
	Checkbox_Narrative.InitCheckbox('Checkbox_HideNarrative', "Hide Narrative", false, ToggleCheckbox);
	Checkbox_Narrative.SetTextStyle(class'UICheckbox'.const.STYLE_TEXT_ON_THE_RIGHT).SetPosition(PositionX, PositionY);

	PositionY += Spacing;

	Checkbox_FOW = Spawn(class'UICheckbox', FrameInfoContainer);
	Checkbox_FOW.InitCheckbox('Checkbox_FOW', "Hide FOW", false, ToggleCheckbox);
	Checkbox_FOW.SetTextStyle(class'UICheckbox'.const.STYLE_TEXT_ON_THE_RIGHT).SetPosition(PositionX, PositionY);

	PositionY += Spacing;

	Checkbox_BuildingVisibility = Spawn(class'UICheckbox', FrameInfoContainer);
	Checkbox_BuildingVisibility.InitCheckbox('Checkbox_BuildingVisibility', "Building Visibility OFF", false, ToggleCheckbox);
	Checkbox_BuildingVisibility.SetTextStyle(class'UICheckbox'.const.STYLE_TEXT_ON_THE_RIGHT).SetPosition(PositionX, PositionY);

	PositionY += Spacing;

	Checkbox_CutoutBox = Spawn(class'UICheckbox', FrameInfoContainer);
	Checkbox_CutoutBox.InitCheckbox('Checkbox_CutoutBox', "Cutout Box OFF", false, ToggleCheckbox);
	Checkbox_CutoutBox.SetTextStyle(class'UICheckbox'.const.STYLE_TEXT_ON_THE_RIGHT).SetPosition(PositionX, PositionY);

	PositionY += Spacing;

	Checkbox_Pathing = Spawn(class'UICheckbox', FrameInfoContainer);
	Checkbox_Pathing.InitCheckbox('Checkbox_Pathing', "Pathing & Cover UI OFF", false, ToggleCheckbox);
	Checkbox_Pathing.SetTextStyle(class'UICheckbox'.const.STYLE_TEXT_ON_THE_RIGHT).SetPosition(PositionX, PositionY);

	PositionY += Spacing;

	Checkbox_SoldierChatter = Spawn(class'UICheckbox', FrameInfoContainer);
	Checkbox_SoldierChatter.InitCheckbox('Checkbox_SoldierChatter', "Soldier Chatter OFF", false, ToggleCheckbox);
	Checkbox_SoldierChatter.SetTextStyle(class'UICheckbox'.const.STYLE_TEXT_ON_THE_RIGHT).SetPosition(PositionX, PositionY);

	PositionY += Spacing;

	Checkbox_DisableMusic = Spawn(class'UICheckbox', FrameInfoContainer);
	Checkbox_DisableMusic.InitCheckbox('Checkbox_DisableMusic', "Music OFF", false, ToggleCheckbox);
	Checkbox_DisableMusic.SetTextStyle(class'UICheckbox'.const.STYLE_TEXT_ON_THE_RIGHT).SetPosition(PositionX, PositionY);

	PositionY += Spacing;

	Checkbox_DisableAmbience = Spawn(class'UICheckbox', FrameInfoContainer);
	Checkbox_DisableAmbience.InitCheckbox('Checkbox_DisableAmbience', "Ambience OFF", false, ToggleCheckbox);
	Checkbox_DisableAmbience.SetTextStyle(class'UICheckbox'.const.STYLE_TEXT_ON_THE_RIGHT).SetPosition(PositionX, PositionY);

	PositionY += Spacing;

	Checkbox_ConcealmentTiles = Spawn(class'UICheckbox', FrameInfoContainer);
	Checkbox_ConcealmentTiles.InitCheckbox('Checkbox_ConcealmentTiles', "Concealment Tiles OFF", false, ToggleCheckbox);
	Checkbox_ConcealmentTiles.SetTextStyle(class'UICheckbox'.const.STYLE_TEXT_ON_THE_RIGHT).SetPosition(PositionX, PositionY);

	PositionY += Spacing;

	Checkbox_DisableUnitShaders = Spawn(class'UICheckbox', FrameInfoContainer);
	Checkbox_DisableUnitShaders.InitCheckbox('Checkbox_DisableUnitShaders', "Unit Shaders (scanline/outline) OFF", false, ToggleCheckbox);
	Checkbox_DisableUnitShaders.SetTextStyle(class'UICheckbox'.const.STYLE_TEXT_ON_THE_RIGHT).SetPosition(PositionX, PositionY);

	PositionY += Spacing;

	Checkbox_DisableTooltips = Spawn(class'UICheckbox', FrameInfoContainer);
	Checkbox_DisableTooltips.InitCheckbox('Checkbox_DisableTooltips', "Tooltips OFF", false, ToggleCheckbox);
	Checkbox_DisableTooltips.SetTextStyle(class'UICheckbox'.const.STYLE_TEXT_ON_THE_RIGHT).SetPosition(PositionX, PositionY);

	PositionY += Spacing;

	Checkbox_DisableLookAtBack = Spawn(class'UICheckbox', FrameInfoContainer);
	Checkbox_DisableLookAtBack.InitCheckbox('Checkbox_DisableLookAtBack', "OTS LookAtBack Penalty OFF", false, ToggleCheckbox);
	Checkbox_DisableLookAtBack.SetTextStyle(class'UICheckbox'.const.STYLE_TEXT_ON_THE_RIGHT).SetPosition(PositionX, PositionY);
}

simulated function InitCheckboxes()
{
	if(!GeneralCheatManager.bLoadedMarketingPresets)
	{
		GeneralCheatManager.bLoadedMarketingPresets = true;
				
		Checkbox_2DUI.SetChecked(ProfileSettings.Data.MarketingPresets.CheckboxSettings.Find('Checkbox_2DUI') != INDEX_NONE);
		Checkbox_3DUI.SetChecked(ProfileSettings.Data.MarketingPresets.CheckboxSettings.Find('Checkbox_3DUI') != INDEX_NONE);

		if(TacticalCheatManager != none)
		{
			Checkbox_UnitFlags.SetChecked(ProfileSettings.Data.MarketingPresets.CheckboxSettings.Find('Checkbox_UnitFlags') != INDEX_NONE);
			Checkbox_WorldMessages.SetChecked(ProfileSettings.Data.MarketingPresets.CheckboxSettings.Find('Checkbox_WorldMessages') != INDEX_NONE);
			Checkbox_LootEffects.SetChecked(ProfileSettings.Data.MarketingPresets.CheckboxSettings.Find('Checkbox_LootEffects') != INDEX_NONE);
			Checkbox_FOW.SetChecked(ProfileSettings.Data.MarketingPresets.CheckboxSettings.Find('Checkbox_FOW') != INDEX_NONE);
			Checkbox_BuildingVisibility.SetChecked(ProfileSettings.Data.MarketingPresets.CheckboxSettings.Find('Checkbox_BuildingVisibility') != INDEX_NONE);
			Checkbox_CutoutBox.SetChecked(ProfileSettings.Data.MarketingPresets.CheckboxSettings.Find('Checkbox_CutoutBox') != INDEX_NONE);			
			Checkbox_Pathing.SetChecked(ProfileSettings.Data.MarketingPresets.CheckboxSettings.Find('Checkbox_Pathing') != INDEX_NONE);
			Checkbox_SoldierChatter.SetChecked(ProfileSettings.Data.MarketingPresets.CheckboxSettings.Find('Checkbox_SoldierChatter') != INDEX_NONE);
			Checkbox_DisableAmbience.SetChecked(ProfileSettings.Data.MarketingPresets.CheckboxSettings.Find('Checkbox_DisableAmbience') != INDEX_NONE);
			Checkbox_ConcealmentTiles.SetChecked(ProfileSettings.Data.MarketingPresets.CheckboxSettings.Find('Checkbox_ConcealmentTiles') != INDEX_NONE);
			Checkbox_DisableUnitShaders.SetChecked(ProfileSettings.Data.MarketingPresets.CheckboxSettings.Find('Checkbox_DisableUnitShaders') != INDEX_NONE);
			Checkbox_DisableLookAtBack.SetChecked(ProfileSettings.Data.MarketingPresets.CheckboxSettings.Find('Checkbox_DisableLookAtBack') != INDEX_NONE);
		}

		if(GeneralCheatManager != none)
		{
			Checkbox_Narrative.SetChecked(ProfileSettings.Data.MarketingPresets.CheckboxSettings.Find('Checkbox_Narrative') != INDEX_NONE);
			Checkbox_DisableMusic.SetChecked(ProfileSettings.Data.MarketingPresets.CheckboxSettings.Find('Checkbox_DisableMusic') != INDEX_NONE);
			Checkbox_DisableTooltips.SetChecked(ProfileSettings.Data.MarketingPresets.CheckboxSettings.Find('Checkbox_DisableTooltips') != INDEX_NONE);
		}
	}
	else
	{
		Checkbox_2DUI.SetChecked(!Pres.Get2DMovie().bIsVisible);
		Checkbox_3DUI.SetChecked(!Pres.Get3DMovie().bIsVisible);

		if(TacticalCheatManager != none)
		{
			Checkbox_UnitFlags.SetChecked(!TacticalCheatManager.bShowUnitFlags);
			Checkbox_WorldMessages.SetChecked(TacticalCheatManager.bDisableWorldMessages);
			Checkbox_LootEffects.SetChecked(class'XComGameState_Cheats'.static.GetCheatsObject().DisableLooting);
			Checkbox_FOW.SetChecked(!`XWORLD.bEnableFOW);
			Checkbox_BuildingVisibility.SetChecked(!TacticalCheatManager.m_bEnableBuildingVisibility_Cheat);
			Checkbox_CutoutBox.SetChecked(!TacticalCheatManager.m_bEnableCutoutBox_Cheat);			
			Checkbox_Pathing.SetChecked(TacticalCheatManager.bHidePathingPawn);
			Checkbox_SoldierChatter.SetChecked(!`XPROFILESETTINGS.Data.m_bEnableSoldierSpeech);
			Checkbox_DisableAmbience.SetChecked(GeneralCheatManager.bAmbienceDisabled);
			Checkbox_ConcealmentTiles.SetChecked(GeneralCheatManager.bConcealmentTilesHidden);
			Checkbox_DisableUnitShaders.SetChecked(TacticalCheatManager.bDisableTargetingOutline);
			Checkbox_DisableLookAtBack.SetChecked(TacticalCheatManager.bDisableLookAtBackPenalty);
		}

		if(GeneralCheatManager != none)
		{
			Checkbox_Narrative.SetChecked(GeneralCheatManager.bNarrativeDisabled);
			Checkbox_DisableMusic.SetChecked(GeneralCheatManager.bMusicDisabled);
			Checkbox_DisableTooltips.SetChecked(PlayerController.Pres.m_kTooltipMgr.bEnableTooltips);
		}
	}
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_BUTTON_Y:
		case class'UIUtilities_Input'.const.FXS_BUTTON_X:
		case class'UIUtilities_input'.const.FXS_BUTTON_L3:
			return true;
	}

	return super.OnUnrealCommand(cmd, arg);
}

simulated function ApplyChanges(UIButton button)
{
	local XComWorldData WorldData;
	local XGUnit Unit;	

	if(Checkbox_2DUI.bChecked)
	{
		ProfileSettings.Data.MarketingPresets.CheckboxSettings.AddItem('Checkbox_2DUI');
		if(Pres.Get2DMovie().bIsVisible)
		{
			Pres.Get2DMovie().Hide();
		}
	}
	else
	{
		ProfileSettings.Data.MarketingPresets.CheckboxSettings.RemoveItem('Checkbox_2DUI');
		if(!Pres.Get2DMovie().bIsVisible)
		{
			Pres.Get2DMovie().Show();
		}
	}

	if(Checkbox_3DUI.bChecked)
	{
		ProfileSettings.Data.MarketingPresets.CheckboxSettings.AddItem('Checkbox_3DUI');
		if(Pres.Get3DMovie().bIsVisible)
		{
			Pres.Get3DMovie().Hide();
		}
	}
	else
	{
		ProfileSettings.Data.MarketingPresets.CheckboxSettings.RemoveItem('Checkbox_3DUI');
		if(!Pres.Get3DMovie().bIsVisible)
		{
			Pres.Get3DMovie().Show();
		}
	}
	
	if(TacticalCheatManager != none)
	{
		if(Checkbox_UnitFlags.bChecked)
		{
			ProfileSettings.Data.MarketingPresets.CheckboxSettings.AddItem('Checkbox_UnitFlags');
			TacticalCheatManager.bShowUnitFlags = false;
		}
		else
		{
			ProfileSettings.Data.MarketingPresets.CheckboxSettings.RemoveItem('Checkbox_UnitFlags');
			TacticalCheatManager.bShowUnitFlags = true;
		}

		if(Checkbox_WorldMessages.bChecked)
		{
			ProfileSettings.Data.MarketingPresets.CheckboxSettings.AddItem('Checkbox_WorldMessages');
			TacticalCheatManager.bDisableWorldMessages = true;
		}
		else
		{
			ProfileSettings.Data.MarketingPresets.CheckboxSettings.RemoveItem('Checkbox_WorldMessages');
			TacticalCheatManager.bDisableWorldMessages = false;
		}

		if(Checkbox_LootEffects.bChecked)
		{
			ProfileSettings.Data.MarketingPresets.CheckboxSettings.AddItem('Checkbox_LootEffects');
			TacticalCheatManager.SetLootDisabled(true);
		}
		else
		{
			ProfileSettings.Data.MarketingPresets.CheckboxSettings.RemoveItem('Checkbox_LootEffects');
			TacticalCheatManager.SetLootDisabled(false);
		}

		if(Checkbox_FOW.bChecked)
		{
			ProfileSettings.Data.MarketingPresets.CheckboxSettings.AddItem('Checkbox_FOW');
			if(`XWORLD.bEnableFOW)
			{
				TacticalCheatManager.ToggleFOW();
			}
			
		}
		else
		{
			ProfileSettings.Data.MarketingPresets.CheckboxSettings.RemoveItem('Checkbox_FOW');
			if(!`XWORLD.bEnableFOW)
			{
				TacticalCheatManager.ToggleFOW();
			}
		}

		if(Checkbox_BuildingVisibility.bChecked)
		{
			ProfileSettings.Data.MarketingPresets.CheckboxSettings.AddItem('Checkbox_BuildingVisibility');
			TacticalCheatManager.BuildingVisEnable(false);
		}
		else
		{
			ProfileSettings.Data.MarketingPresets.CheckboxSettings.RemoveItem('Checkbox_BuildingVisibility');
			TacticalCheatManager.BuildingVisEnable(true);
		}

		if(Checkbox_CutoutBox.bChecked)
		{
			ProfileSettings.Data.MarketingPresets.CheckboxSettings.AddItem('Checkbox_CutoutBox');
			TacticalCheatManager.CutoutBoxEnable(false);
		}
		else
		{
			ProfileSettings.Data.MarketingPresets.CheckboxSettings.RemoveItem('Checkbox_CutoutBox');
			TacticalCheatManager.CutoutBoxEnable(true);
		}

		if(Checkbox_Pathing.bChecked)
		{
			ProfileSettings.Data.MarketingPresets.CheckboxSettings.AddItem('Checkbox_Pathing');

			TacticalCheatManager.bHidePathingPawn = true;
			TacticalCheatManager.m_bAllowTether = false;

			WorldData = class'XComWorldData'.static.GetWorldData();
			if(WorldData != none && WorldData.Volume != none)
			{
				class'XComWorldData'.static.GetWorldData().Volume.BorderComponent.SetCinematicHidden(!TacticalCheatManager.m_bAllowTether);
				class'XComWorldData'.static.GetWorldData().Volume.BorderComponentDashing.SetCinematicHidden(!TacticalCheatManager.m_bAllowTether);
			}
						
			TacticalCheatManager.UISetDiscState(false);
			foreach AllActors(class'XGUnit', Unit)
			{
				Unit.RefreshUnitDisc();
			}
		}
		else
		{
			ProfileSettings.Data.MarketingPresets.CheckboxSettings.RemoveItem('Checkbox_Pathing');

			TacticalCheatManager.bHidePathingPawn = false;
			TacticalCheatManager.m_bAllowTether = true;

			WorldData = class'XComWorldData'.static.GetWorldData();
			if(WorldData != none && WorldData.Volume != none)
			{
				class'XComWorldData'.static.GetWorldData().Volume.BorderComponent.SetCinematicHidden(!TacticalCheatManager.m_bAllowTether);
				class'XComWorldData'.static.GetWorldData().Volume.BorderComponentDashing.SetCinematicHidden(!TacticalCheatManager.m_bAllowTether);
			}

			TacticalCheatManager.UISetDiscState(true);

			foreach AllActors(class'XGUnit', Unit)
			{
				Unit.RefreshUnitDisc();
			}
		}

		if(Checkbox_SoldierChatter.bChecked)
		{
			ProfileSettings.Data.MarketingPresets.CheckboxSettings.AddItem('Checkbox_SoldierChatter');
			`XPROFILESETTINGS.Data.m_bEnableSoldierSpeech = false;
		}
		else
		{
			ProfileSettings.Data.MarketingPresets.CheckboxSettings.RemoveItem('Checkbox_SoldierChatter');
			`XPROFILESETTINGS.Data.m_bEnableSoldierSpeech = true;
		}

		if(Checkbox_DisableAmbience.bChecked)
		{
			ProfileSettings.Data.MarketingPresets.CheckboxSettings.AddItem('Checkbox_DisableAmbience');
			GeneralCheatManager.bAmbienceDisabled = true;
			`XTACTICALSOUNDMGR.StopAllAmbience();
		}
		else
		{
			ProfileSettings.Data.MarketingPresets.CheckboxSettings.RemoveItem('Checkbox_DisableAmbience');
			GeneralCheatManager.bAmbienceDisabled = false;
			`XTACTICALSOUNDMGR.StartAllAmbience();
		}

		if(Checkbox_ConcealmentTiles.bChecked)
		{
			ProfileSettings.Data.MarketingPresets.CheckboxSettings.AddItem('Checkbox_ConcealmentTiles');
			GeneralCheatManager.bConcealmentTilesHidden = true;
			XComTacticalController(PlayerController).m_kPathingPawn.UpdateConcealmentTilesVisibility(true);
		}
		else
		{
			ProfileSettings.Data.MarketingPresets.CheckboxSettings.RemoveItem('Checkbox_ConcealmentTiles');
			GeneralCheatManager.bConcealmentTilesHidden = false;
			XComTacticalController(PlayerController).m_kPathingPawn.UpdateConcealmentTilesVisibility(false);
		}

		if(Checkbox_DisableUnitShaders.bChecked)
		{
			ProfileSettings.Data.MarketingPresets.CheckboxSettings.AddItem('Checkbox_DisableUnitShaders');
			TacticalCheatManager.bDisableTargetingOutline = true;
		}
		else
		{
			ProfileSettings.Data.MarketingPresets.CheckboxSettings.RemoveItem('Checkbox_DisableUnitShaders');
			TacticalCheatManager.bDisableTargetingOutline = false;
		}

		if(Checkbox_DisableLookAtBack.bChecked)
		{
			ProfileSettings.Data.MarketingPresets.CheckboxSettings.AddItem('Checkbox_DisableLookAtBack');
			TacticalCheatManager.bDisableLookAtBackPenalty = true;
		}
		else
		{
			ProfileSettings.Data.MarketingPresets.CheckboxSettings.RemoveItem('Checkbox_DisableLookAtBack');
			TacticalCheatManager.bDisableLookAtBackPenalty = false;
		}
	}
	
	if(GeneralCheatManager != none)
	{
		if(Checkbox_Narrative.bChecked)
		{
			ProfileSettings.Data.MarketingPresets.CheckboxSettings.AddItem('Checkbox_Narrative');
			GeneralCheatManager.bNarrativeDisabled = true;
		}
		else
		{
			ProfileSettings.Data.MarketingPresets.CheckboxSettings.RemoveItem('Checkbox_Narrative');
			GeneralCheatManager.bNarrativeDisabled = false;
		}

		if(Checkbox_DisableMusic.bChecked)
		{
			ProfileSettings.Data.MarketingPresets.CheckboxSettings.AddItem('Checkbox_DisableMusic');
			GeneralCheatManager.bMusicDisabled = true;
			PlayerController.SetAudioGroupVolume('Music', 0.0f);
		}
		else
		{
			ProfileSettings.Data.MarketingPresets.CheckboxSettings.RemoveItem('Checkbox_DisableMusic');
			GeneralCheatManager.bMusicDisabled = false;
			PlayerController.SetAudioGroupVolume('Music', 0.0f);
		}

		if(Checkbox_DisableTooltips.bChecked)
		{
			ProfileSettings.Data.MarketingPresets.CheckboxSettings.AddItem('Checkbox_DisableTooltips');
			GeneralCheatManager.UIDisableTooltips();
		}
		else
		{
			ProfileSettings.Data.MarketingPresets.CheckboxSettings.RemoveItem('Checkbox_DisableTooltips');
			GeneralCheatManager.UIEnableTooltips();
		}		
	}

	`ONLINEEVENTMGR.SaveProfileSettings();

	Movie.Stack.Pop(self);
}

simulated function ToggleCheckbox(UICheckbox checkboxControl)
{
	
}

simulated function OnRemoved()
{
	super.OnRemoved();
}

//==============================================================================
//		DEFAULTS:
//==============================================================================

simulated function OnReceiveFocus()
{
	Show();
}

simulated function OnLoseFocus()
{
	Hide();
}

defaultproperties
{
}
