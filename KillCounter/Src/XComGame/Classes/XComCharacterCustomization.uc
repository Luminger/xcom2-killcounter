//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    XComCharacterCustomization.uc
//  AUTHOR:  Brit Steiner 9/15/2014
//  PURPOSE: Container of static helper functions for customizing character screens 
//			 and visual updates. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class XComCharacterCustomization extends Object
	config(UI);

const FIRST_NAME_MAX_CHARS      = 11;
const NICKNAME_NAME_MAX_CHARS   = 11;
const LAST_NAME_MAX_CHARS       = 15;

var const config name StandingStillAnimName;
var const config float UIColorBrightnessAdjust;

enum EUICustomizeCategory
{
	eUICustomizeCat_FirstName,
	eUICustomizeCat_LastName,
	eUICustomizeCat_NickName,
	eUICustomizeCat_WeaponName,
	eUICustomizeCat_Torso,
	eUICustomizeCat_Arms,
	eUICustomizeCat_Legs,
	eUICustomizeCat_Skin,
	eUICustomizeCat_Face,
	eUICustomizeCat_EyeColor,
	eUICustomizeCat_Hairstyle,
	eUICustomizeCat_HairColor,
	eUICustomizeCat_FaceDecorationUpper,
	eUICustomizeCat_FaceDecorationLower,
	eUICustomizeCat_FacialHair,
	eUICustomizeCat_Personality,
	eUICustomizeCat_Country,
	eUICustomizeCat_Voice,
	eUICustomizeCat_Gender,
	eUICustomizeCat_Race,
	eUICustomizeCat_Helmet,
	eUICustomizeCat_PrimaryArmorColor,
	eUICustomizeCat_SecondaryArmorColor,
	eUICustomizeCat_WeaponColor,
	eUICustomizeCat_ArmorPatterns,
	eUICustomizeCat_WeaponPatterns,
	eUICustomizeCat_LeftArmTattoos,
	eUICustomizeCat_RightArmTattoos,
	eUICustomizeCat_TattooColor,
	eUICustomizeCat_Scars,
	eUICustomizeCat_Class,
	eUICustomizeCat_AllowTypeSoldier,
	eUICustomizeCat_AllowTypeVIP,
	eUICustomizeCat_AllowTypeDarkVIP,
	eUICustomizeCat_FacePaint,
	eUICustomizeCat_DEV1,
	eUICustomizeCat_DEV2,
};
enum ENameCustomizationOptions
{
	eCustomizeName_First,
	eCustomizeName_Last,
	eCustomizeName_Nick,
};

var name LastSetCameraTag; //Let the system avoid resetting the currently set tag
var protectedwrite Actor ActorPawn;
var protectedwrite name PawnLocationTag;
var protectedwrite name RegularCameraTag;
var protectedwrite name RegularDisplayTag;
var protectedwrite name HeadCameraTag;
var protectedwrite name HeadDisplayTag;
var protectedwrite name LegsCameraTag;
var protectedwrite name LegsDisplayTag;

var private XComGameStateHistory History;
var private XComGameState CheckGameState;
var private X2BodyPartTemplateManager PartManager;
var private	X2SimpleBodyPartFilter BodyPartFilter;

var privatewrite StateObjectReference UnitRef;
var privatewrite XComGameState_Unit Unit;
var privatewrite XComGameState_Unit UpdatedUnitState;
var privatewrite XComGameState_Item PrimaryWeapon;
var privatewrite XComGameState_Item SecondaryWeapon;
var privatewrite XComUnitPawn CosmeticUnit;

var privatewrite XGCharacterGenerator CharacterGenerator;

var privatewrite int m_iCustomizeNameType;

var localized string Gender_Male;
var localized string Gender_Female;
var localized string CustomizeFirstName;
var localized string CustomizeLastName;
var localized string CustomizeNickName;
var localized string CustomizeWeaponName;
var localized string RandomClass; 

simulated function Init(XComGameState_Unit _Unit, optional Actor RequestedActorPawn = none, optional XComGameState gameState = none)
{
	History = `XCOMHISTORY;

	CheckGameState = gameState;

	Unit = _Unit;
	UpdatedUnitState = Unit;
	UnitRef = UpdatedUnitState.GetReference();
	
	PrimaryWeapon = XComGameState_Item(History.GetGameStateForObjectID(Unit.GetItemInSlot(eInvSlot_PrimaryWeapon).ObjectID));
	SecondaryWeapon = XComGameState_Item(History.GetGameStateForObjectID(Unit.GetItemInSlot(eInvSlot_SecondaryWeapon).ObjectID));

	PartManager = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager();

	CharacterGenerator = `XCOMGAME.spawn( class 'XGCharacterGenerator' );

	BodyPartFilter = `XCOMGAME.SharedBodyPartFilter;
	
	ReCreatePawnVisuals(RequestedActorPawn);

	if (PartManager.DisablePostProcessWhenCustomizing)
	{
		class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().ConsoleCommand("show postprocess");
	}
}

simulated function Refresh(XComGameState_Unit PreviousUnit, XComGameState_Unit NewUnit)
{
	local Rotator UseRotation;

	//Commit changes to the previous unit
	if(PreviousUnit == Unit)
	{
		CommitChanges();
	}

	Unit = NewUnit;
	UpdatedUnitState = Unit;
	UnitRef = UpdatedUnitState.GetReference(); 

	UpdateBodyPartFilterForNewUnit(Unit);	

	PrimaryWeapon = XComGameState_Item(History.GetGameStateForObjectID(Unit.GetItemInSlot(eInvSlot_PrimaryWeapon).ObjectID));

	if(ActorPawn != None)
	{
		UseRotation = ActorPawn.Rotation;
	}
	else
	{
		UseRotation.Yaw = -16384;
	}

	XComPresentationLayerBase(Outer).GetUIPawnMgr().ReleasePawn(XComPresentationLayerBase(Outer), PreviousUnit.ObjectID, true);
	CreatePawnVisuals(UseRotation);
}

simulated function bool InShell()
{
	return XComShellPresentationLayer(Outer) != none;
}

function UpdateBodyPartFilterForNewUnit(XComGameState_Unit NewUnit)
{
	BodyPartFilter.Set(EGender(Unit.kAppearance.iGender), ECharacterRace(Unit.kAppearance.iRace), Unit.kAppearance.nmTorso, !Unit.IsASoldier(), Unit.IsVeteran() || InShell());
}

function bool HasPartsForPartType(string PartType)
{
	local array<X2BodyPartTemplate> Templates;

	PartManager.GetFilteredUberTemplates(PartType, BodyPartFilter, BodyPartFilter.FilterAny, Templates);

	return Templates.Length > 0;
}

//==============================================================================
simulated function ReCreatePawnVisuals(optional Actor RequestedActorPawn, optional bool bForce)
{
	local Rotator UseRotation;

	if (RequestedActorPawn != none)
	{
		UseRotation = RequestedActorPawn.Rotation;
	}
	else if(ActorPawn != None)
	{
		UseRotation = ActorPawn.Rotation;
	}
	else
	{
		UseRotation.Yaw = -16384;
	}

	XComPresentationLayerBase(Outer).GetUIPawnMgr().ReleasePawn(XComPresentationLayerBase(Outer), UnitRef.ObjectID, bForce);
	CreatePawnVisuals(UseRotation);
}


simulated function CreatePawnVisuals(Rotator UseRotation)
{	
	local Vector SpawnPawnLocation;
	local name LocationName;
	local PointInSpace PlacementActor;
	local XComGameState_Item ItemState;
	local XComGameState TempGameState;
	local XComGameStateContext_ChangeContainer TempContainer;

	LocationName = 'UIPawnLocation_Armory';
	foreach XComPresentationLayerBase(Outer).WorldInfo.AllActors(class'PointInSpace', PlacementActor)
	{
		if (PlacementActor != none && PlacementActor.Tag == LocationName)
			break;
	}

	SpawnPawnLocation = PlacementActor.Location;

	ActorPawn = XComPresentationLayerBase(Outer).GetUIPawnMgr().RequestPawnByState(XComPresentationLayerBase(Outer), UpdatedUnitState, SpawnPawnLocation, UseRotation);
	ActorPawn.GotoState('CharacterCustomization');	

	ItemState = UpdatedUnitState.GetItemInSlot(eInvSlot_PrimaryWeapon, CheckGameState);
	if( ItemState == none )
	{	
		//This logic runs in the character pool - where the unit does not actually have a real load out. So we need to make one temporarily that the weapon visualization logic can use.
		TempContainer = class'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("Fake Loadout");
		TempGameState = History.CreateNewGameState(true, TempContainer);

		//Give the unit a loadout
		UpdatedUnitState.ApplyInventoryLoadout(TempGameState);

		//Add the state to the history so that the visualization functions can operate correctly
		History.AddGameStateToHistory(TempGameState);

		//Save off the weapon states so we can use them later
		PrimaryWeapon = UpdatedUnitState.GetItemInSlot(eInvSlot_PrimaryWeapon, TempGameState); 
		SecondaryWeapon = UpdatedUnitState.GetItemInSlot(eInvSlot_SecondaryWeapon, TempGameState); 

		//Create the visuals for the weapons, using the temp game state
		XComUnitPawn(ActorPawn).CreateVisualInventoryAttachments(XComPresentationLayerBase(Outer).GetUIPawnMgr(), UpdatedUnitState, TempGameState);

		//Manually set the secondary weapon to have the same appearance as the primary
		XGWeapon(SecondaryWeapon.GetVisualizer()).SetAppearance(PrimaryWeapon.WeaponAppearance);

		//Destroy the temporary game state change that granted the unit a load out
		History.ObliterateGameStatesFromHistory(1);

		//Now clear the items from the unit so we don't accidentally save them
		UpdatedUnitState.EmptyInventoryItems();
	}
	else
	{
		PrimaryWeapon = ItemState;
		XComUnitPawn(ActorPawn).CreateVisualInventoryAttachments(XComPresentationLayerBase(Outer).GetUIPawnMgr(), UpdatedUnitState, CheckGameState);
	}
}
//==============================================================================

simulated function EditText(int iType)
{
	local string NameToShow; 

	switch(iType)
	{
	case eUICustomizeCat_FirstName:
		NameToShow = UpdatedUnitState.GetFirstName(); 
		OpenNameInputBox(iType, CustomizeFirstName, NameToShow, FIRST_NAME_MAX_CHARS);
		break;
	case eUICustomizeCat_LastName:
		NameToShow = UpdatedUnitState.GetLastName(); 
		OpenNameInputBox(iType, CustomizeLastName, NameToShow, LAST_NAME_MAX_CHARS);
		break;
	case eUICustomizeCat_NickName:
		NameToShow = UpdatedUnitState.GetNickName(true); 
		OpenNameInputBox(iType, CustomizeNickName, NameToShow, NICKNAME_NAME_MAX_CHARS);
		break;
	case eUICustomizeCat_WeaponName:
		NameToShow = UpdatedUnitState.GetItemInSlot(eInvSlot_PrimaryWeapon, CheckGameState).Nickname; 
		OpenNameInputBox(iType, CustomizeWeaponName, NameToShow, NICKNAME_NAME_MAX_CHARS);
		break;
	}
}

simulated function OpenNameInputBox(int optionIndex, string title, string text, int maxCharacters)
{
	local TInputDialogData kData;

	m_iCustomizeNameType = optionIndex;

	kData.strTitle = title;
	kData.iMaxChars = maxCharacters;
	kData.strInputBoxText = text;
	kData.fnCallback = OnNameInputBoxClosed;

	XComPresentationLayerBase(Outer).UIInputDialog(kData);
}

// TEXT INPUT BOX (PC)
function OnNameInputBoxClosed(string text)
{
	local UICustomize CustomizeScreen;

	if(text != "")
	{
		switch(m_iCustomizeNameType)
		{
		case eCustomizeName_First:
			UpdatedUnitState.SetUnitName(text, UpdatedUnitState.GetLastName(), UpdatedUnitState.GetNickName(true));
			break;
		case eCustomizeName_Last:
			UpdatedUnitState.SetUnitName(UpdatedUnitState.GetFirstName(), text, UpdatedUnitState.GetNickName(true));
			break;
		case eCustomizeName_Nick:
			UpdatedUnitState.SetUnitName(UpdatedUnitState.GetFirstName(), UpdatedUnitState.GetLastName(), text);
			break;
		case eUICustomizeCat_WeaponName:
			// TODO: Implement functionality
			`RedScreen("Weapon naming functionality not yet implemented");
			break;
		}

		//If we are in the strategy game...
		if(`GAME != none)
		{
			`ONLINEEVENTMGR.EvalName(UpdatedUnitState);
		}
	}

	m_iCustomizeNameType = -1; 

	// Update the soldier header on the current screen - sbatista
	CustomizeScreen = UICustomize(`SCREENSTACK.GetFirstInstanceOf(class'UICustomize'));
	if(CustomizeScreen != none)
		CustomizeScreen.Header.PopulateData(UpdatedUnitState);
}
//==============================================================================

simulated function int DevNextIndex(int index, int direction, out array<X2BodyPartTemplate> ArmorParts)
{
	if (ArmorParts.Length == 0)
		return INDEX_NONE;

	return WrapIndex(index + direction, 0, ArmorParts.Length);
}

simulated function int DevPartIndex( name PartName, array<X2DataTemplate> Parts)
{
	local int PartIndex;

	for( PartIndex = 0; PartIndex < Parts.Length; ++PartIndex )
	{
		if( PartName == Parts[PartIndex].DataName )
		{
			break;
		}
	}

	return PartIndex;
}

//==============================================================================

function UpdateCategory( string BodyPartType, int direction, delegate<X2BodyPartFilter.FilterCallback> FilterFn, out name Part, optional int specificIndex = -1)
{
	local int categoryValue;
	local int newIndex;
	local array<X2BodyPartTemplate> BodyParts;

	PartManager.GetFilteredUberTemplates(BodyPartType, BodyPartFilter, FilterFn, BodyParts);

	if( specificIndex != -1 ) 
	{
		newIndex = WrapIndex(specificIndex, 0, BodyParts.Length);
	}
	else
	{
		categoryValue = DevPartIndex(Part, BodyParts);
		newIndex = DevNextIndex(categoryValue, direction, BodyParts);
	}
	Part = BodyParts[newIndex].DataName;

	XComHumanPawn(ActorPawn).SetAppearance(UpdatedUnitState.kAppearance);
	UpdatedUnitState.StoreAppearance();
}

function UpdateCategorySimple( string BodyPartType, int direction, delegate<X2BodyPartFilter.FilterCallback> FilterFn, out name Part, optional int specificIndex = -1)
{
	CyclePartSimple(BodyPartType, direction, FilterFn, Part, specificIndex);
	XComHumanPawn(ActorPawn).SetAppearance(UpdatedUnitState.kAppearance);
	UpdatedUnitState.StoreAppearance();
}

function CyclePartSimple( string BodyPartType, int direction, delegate<X2BodyPartFilter.FilterCallback> FilterFn, out name Part, optional int specificIndex = -1)
{
	local int categoryValue;
	local int newIndex;
	local array<X2BodyPartTemplate> BodyParts;

	PartManager.GetFilteredUberTemplates(BodyPartType, self, FilterFn, BodyParts);

	if( specificIndex != -1 ) 
	{
		newIndex = WrapIndex(specificIndex, 0, BodyParts.Length);
	}
	else
	{
		categoryValue = DevPartIndex(Part, BodyParts);
		newIndex = WrapIndex(categoryValue + direction, 0, BodyParts.Length);
	}
	Part = BodyParts[newIndex].DataName;
}

//==============================================================================

// direction will either be -1 (left arrow), or 1 (right arrow)xcom
simulated function OnCategoryValueChange(int categoryIndex, int direction, optional int specificIndex = -1)
{	
	local int categoryValue;	
	local TSoldier NewSoldier;
	local TWeaponAppearance WeaponAppearance;	
	local TAppearance Appearance;
	local name RequestTemplate;
	local array<XComGameState_Item> Items; //Used for setting the tint / pattern on items
	local int Index;
	local XComUnitPawn CosmeticUnitPawn;
		
	//Set the body part filter with latest data so that the filters can operate	
	BodyPartFilter.Set(EGender(UpdatedUnitState.kAppearance.iGender), ECharacterRace(UpdatedUnitState.kAppearance.iRace), UpdatedUnitState.kAppearance.nmTorso, !UpdatedUnitState.IsASoldier(), UpdatedUnitState.IsVeteran() || InShell());

	switch(categoryIndex)
	{
	case eUICustomizeCat_Torso:       
		UpdateCategory("Torso", direction, BodyPartFilter.FilterByTorsoAndArmorMatch, UpdatedUnitState.kAppearance.nmTorso, specificIndex);
		break;
	case eUICustomizeCat_Arms:
		UpdateCategory("Arms", direction, BodyPartFilter.FilterByTorsoAndArmorMatch, UpdatedUnitState.kAppearance.nmArms, specificIndex);
		break;
	case eUICustomizeCat_Legs:                  
		UpdateCategory("Legs", direction, BodyPartFilter.FilterByTorsoAndArmorMatch, UpdatedUnitState.kAppearance.nmLegs, specificIndex);
		break;
	case eUICustomizeCat_Skin:
		UpdatedUnitState.kAppearance.iSkinColor = WrapIndex(specificIndex, 0, XComHumanPawn(ActorPawn).NumPossibleSkinColors);		
		XComHumanPawn(ActorPawn).SetAppearance(UpdatedUnitState.kAppearance);
		UpdatedUnitState.StoreAppearance();
		break;
	case eUICustomizeCat_Face:		
		UpdateCategorySimple("Head", direction, BodyPartFilter.FilterByGenderAndRace, UpdatedUnitState.kAppearance.nmHead, specificIndex);
		break;
	case eUICustomizeCat_EyeColor:			
		UpdatedUnitState.kAppearance.iEyeColor = WrapIndex(specificIndex, 0, `CONTENT.GetColorPalette(ePalette_EyeColor).Entries.length);
		XComHumanPawn(ActorPawn).SetAppearance(UpdatedUnitState.kAppearance);
		UpdatedUnitState.StoreAppearance();
		break;
	case eUICustomizeCat_DEV1:				break; // TODO: update game data
	case eUICustomizeCat_DEV2:				break; // TODO: update game data
	case eUICustomizeCat_Hairstyle:	
		UpdateCategorySimple("Hair", direction, BodyPartFilter.FilterByGenderAndNonSpecialized, UpdatedUnitState.kAppearance.nmHaircut, specificIndex);
		break;
	case eUICustomizeCat_HairColor:	
		UpdatedUnitState.kAppearance.iHairColor = WrapIndex(specificIndex, 0, XComHumanPawn(ActorPawn).NumPossibleHairColors);	
		XComHumanPawn(ActorPawn).SetAppearance(UpdatedUnitState.kAppearance);
		UpdatedUnitState.StoreAppearance();
		break; 
	case eUICustomizeCat_FaceDecorationUpper:
		UpdateCategorySimple("FacePropsUpper", direction, BodyPartFilter.FilterByGenderAndNonSpecialized, UpdatedUnitState.kAppearance.nmFacePropUpper, specificIndex);
		break;
	case eUICustomizeCat_FaceDecorationLower:
		UpdateCategorySimple("FacePropsLower", direction, BodyPartFilter.FilterByGenderAndNonSpecialized, UpdatedUnitState.kAppearance.nmFacePropLower, specificIndex);
		break;
	case eUICustomizeCat_FacialHair:				 
		UpdateCategorySimple("Beards", direction, BodyPartFilter.FilterByGenderAndNonSpecialized, UpdatedUnitState.kAppearance.nmBeard, specificIndex);
		break;
	case eUICustomizeCat_Personality:				 
		if(specificIndex > -1)
		{
			UpdatedUnitState.kAppearance.iAttitude = specificIndex;
			UpdatedUnitState.UpdatePersonalityTemplate();
			XComHumanPawn(ActorPawn).PlayHQIdleAnim(, , true);
			UpdatedUnitState.StoreAppearance();
		}
		break;
	case eUICustomizeCat_Country:
		UpdateCountry(specificIndex);
		break;
	case eUICustomizeCat_Voice:
		UpdateCategorySimple("Voice", direction, BodyPartFilter.FilterByGenderAndNonSpecialized, UpdatedUnitState.kAppearance.nmVoice, specificIndex);
		XComHumanPawn(ActorPawn).SetVoice(UpdatedUnitState.kAppearance.nmVoice);
		UpdatedUnitState.StoreAppearance();
		break;
	case eUICustomizeCat_Gender:					 
		categoryValue = UpdatedUnitState.kAppearance.iGender;

		UpdatedUnitState.StoreAppearance();

		UpdatedUnitState.kAppearance.iGender = (EGender(specificIndex + 1) == eGender_Male )? eGender_Male : eGender_Female;

		// only update if the gender actually changed
		if (UpdatedUnitState.kAppearance.iGender != categoryValue)
		{
			//Weirdism of the CreateTSoldier interface: don't request a soldier template
			RequestTemplate = '';
			if( !UpdatedUnitState.IsSoldier() )
			{
				RequestTemplate = UpdatedUnitState.GetMyTemplateName();
			}

			//Gender re-assignment requires lots of changes...		
			NewSoldier = CharacterGenerator.CreateTSoldier(RequestTemplate, EGender(UpdatedUnitState.kAppearance.iGender), UpdatedUnitState.GetCountryTemplate().DataName, -1, UpdatedUnitState.GetItemInSlot(eInvSlot_Armor).GetMyTemplateName());
			if (UpdatedUnitState.HasStoredAppearance(UpdatedUnitState.kAppearance.iGender))
			{
				UpdatedUnitState.GetStoredAppearance(NewSoldier.kAppearance, UpdatedUnitState.kAppearance.iGender);
			}

			UpdatedUnitState.SetTAppearance(NewSoldier.kAppearance);
		
			//Gender changes everything, so re-get all the pieces
			ReCreatePawnVisuals(ActorPawn, true);
		}

		//TODO category.SetValue(string(UpdatedUnitState.kAppearance.iGender));
		break;
	case eUICustomizeCat_Race:					     
		categoryValue = UpdatedUnitState.kAppearance.iRace;

		if(specificIndex != -1)
			UpdatedUnitState.kAppearance.iRace = specificIndex;
		else
			UpdatedUnitState.kAppearance.iRace = WrapIndex(categoryValue + direction, 0, eRace_MAX);
		
		BodyPartFilter.Set(EGender(UpdatedUnitState.kAppearance.iGender), ECharacterRace(UpdatedUnitState.kAppearance.iRace), UpdatedUnitState.kAppearance.nmTorso);
		UpdateCategorySimple("Head", direction, BodyPartFilter.FilterByGenderAndRace, UpdatedUnitState.kAppearance.nmHead);

		XComHumanPawn(ActorPawn).SetAppearance(UpdatedUnitState.kAppearance);
		UpdatedUnitState.StoreAppearance();
		//TODO category.SetValue(string(UpdatedUnitState.kAppearance.iRace));
		break;
	case eUICustomizeCat_Helmet:  
		UpdateCategory("Helmets", direction, BodyPartFilter.FilterByGenderAndNonSpecializedAndTech, UpdatedUnitState.kAppearance.nmHelmet, specificIndex);
		break;
	case eUICustomizeCat_PrimaryArmorColor:		
		UpdatedUnitState.kAppearance.iArmorTint = WrapIndex(specificIndex, 0, XComHumanPawn(ActorPawn).NumPossibleArmorTints);	
		XComHumanPawn(ActorPawn).SetAppearance(UpdatedUnitState.kAppearance);
		UpdatedUnitState.StoreAppearance();
		break; 
	case eUICustomizeCat_SecondaryArmorColor:		
		UpdatedUnitState.kAppearance.iArmorTintSecondary = WrapIndex(specificIndex, 0, XComHumanPawn(ActorPawn).NumPossibleArmorTints);
		XComHumanPawn(ActorPawn).SetAppearance(UpdatedUnitState.kAppearance);
		UpdatedUnitState.StoreAppearance();
		break; 
	case eUICustomizeCat_WeaponColor:		
		WeaponAppearance = PrimaryWeapon.WeaponAppearance;
		WeaponAppearance.iWeaponTint = WrapIndex(specificIndex, 0, XComHumanPawn(ActorPawn).NumPossibleArmorTints);
		UpdatedUnitState.kAppearance.iWeaponTint = WeaponAppearance.iWeaponTint;
		PrimaryWeapon.WeaponAppearance = WeaponAppearance;

		Items = UpdatedUnitState.GetAllInventoryItems();
		if(Items.Length > 0)
		{
			for(Index = 0; Index < Items.Length; ++Index)
			{
				if(XGWeapon(Items[Index].GetVisualizer()) != none && 
				   (Items[Index].InventorySlot == eInvSlot_PrimaryWeapon || Items[Index].InventorySlot == eInvSlot_SecondaryWeapon))
				{
					XGWeapon(Items[Index].GetVisualizer()).SetAppearance(WeaponAppearance);
				}
			}
		}
		else
		{			
			XGWeapon(PrimaryWeapon.GetVisualizer()).SetAppearance(WeaponAppearance);
			XGWeapon(SecondaryWeapon.GetVisualizer()).SetAppearance(WeaponAppearance);
		}

		//Alter the appearance of an attached cosmetic unit pawn ( such as the gremlin )
		CosmeticUnitPawn = XComPresentationLayerBase(Outer).GetUIPawnMgr().GetCosmeticPawn(eInvSlot_SecondaryWeapon, UpdatedUnitState.ObjectID);
		if (CosmeticUnitPawn != none)
		{
			Appearance.nmPatterns = WeaponAppearance.nmWeaponPattern;
			Appearance.iArmorTint = WeaponAppearance.iWeaponTint;
			Appearance.iArmorTintSecondary = WeaponAppearance.iWeaponDeco;
			CosmeticUnitPawn.SetAppearance(Appearance, true);
		}

		break;
	case eUICustomizeCat_ArmorPatterns:
		UpdateCategorySimple("Patterns", direction, BodyPartFilter.FilterAny, UpdatedUnitState.kAppearance.nmPatterns, specificIndex);
		break;
	case eUICustomizeCat_WeaponPatterns:
		WeaponAppearance = PrimaryWeapon.WeaponAppearance;
		CyclePartSimple("Patterns", direction, BodyPartFilter.FilterAny, WeaponAppearance.nmWeaponPattern, specificIndex);
		UpdatedUnitState.kAppearance.nmWeaponPattern = WeaponAppearance.nmWeaponPattern;
		PrimaryWeapon.WeaponAppearance = WeaponAppearance;		
		
		Items = UpdatedUnitState.GetAllInventoryItems();
		if(Items.Length > 0)
		{
			for(Index = 0; Index < Items.Length; ++Index)
			{
				if(XGWeapon(Items[Index].GetVisualizer()) != none)
				{
					XGWeapon(Items[Index].GetVisualizer()).SetAppearance(WeaponAppearance);
				}
			}
		}
		else
		{
			XGWeapon(PrimaryWeapon.GetVisualizer()).SetAppearance(WeaponAppearance);
			XGWeapon(SecondaryWeapon.GetVisualizer()).SetAppearance(WeaponAppearance);
		}

		//Alter the appearance of an attached cosmetic unit pawn ( such as the gremlin )
		CosmeticUnitPawn = XComPresentationLayerBase(Outer).GetUIPawnMgr().GetCosmeticPawn(eInvSlot_SecondaryWeapon, UpdatedUnitState.ObjectID);
		if (CosmeticUnitPawn != none)
		{
			Appearance.nmPatterns = WeaponAppearance.nmWeaponPattern;
			Appearance.iArmorTint = WeaponAppearance.iWeaponTint;
			Appearance.iArmorTintSecondary = WeaponAppearance.iWeaponDeco;
			CosmeticUnitPawn.SetAppearance(Appearance, true);
		}

		break;
	case eUICustomizeCat_FacePaint:
		UpdateCategorySimple("Facepaint", direction, BodyPartFilter.FilterAny, UpdatedUnitState.kAppearance.nmFacePaint, specificIndex);
		break;
	case eUICustomizeCat_LeftArmTattoos:
		UpdateCategorySimple("Tattoos", direction, BodyPartFilter.FilterAny, UpdatedUnitState.kAppearance.nmTattoo_LeftArm, specificIndex);
		break;
	case eUICustomizeCat_RightArmTattoos:
		UpdateCategorySimple("Tattoos", direction, BodyPartFilter.FilterAny, UpdatedUnitState.kAppearance.nmTattoo_RightArm, specificIndex);
		break;
	case eUICustomizeCat_TattooColor:
		UpdatedUnitState.kAppearance.iTattooTint = WrapIndex(specificIndex, 0, XComHumanPawn(ActorPawn).NumPossibleArmorTints);
		XComHumanPawn(ActorPawn).SetAppearance(UpdatedUnitState.kAppearance);
		UpdatedUnitState.StoreAppearance();
		break;
	case eUICustomizeCat_Scars:
		UpdateCategorySimple("Scars", direction, BodyPartFilter.FilterAny, UpdatedUnitState.kAppearance.nmScars, specificIndex);
		break;
	case eUICustomizeCat_Class:
		UpdateClass(specificIndex);
		break; 
	case eUICustomizeCat_AllowTypeSoldier:
		UpdateAllowedTypeSoldier(specificIndex);
		break;
	case eUICustomizeCat_AllowTypeVIP:
		UpdateAllowedTypeVIP(specificIndex);
		break;
	case eUICustomizeCat_AllowTypeDarkVIP:
		UpdateAllowedTypeDarkVIP(specificIndex);
		break;

	}

	// Only update the camera when editing a unit, not when customizing weapons
	if(`SCREENSTACK.HasInstanceOf(class'UICustomize'))
		UpdateCamera(categoryIndex);
}

function UpdateCamera(optional int categoryIndex = -1)
{
	local name CameraTag;
	local name AnimName;
	local XComHQPresentationLayer HQPres;
	local XComShellPresentationLayer ShellPres;
	local XComBaseCamera HQCamera;
	local UIDisplay_LevelActor DisplayActor;
	local bool bCosmeticPawnOnscreen;
	local bool bExecuteCameraChange;

	switch(categoryIndex)
	{
	case eUICustomizeCat_Face:
	case eUICustomizeCat_EyeColor:
	case eUICustomizeCat_Hairstyle:
	case eUICustomizeCat_HairColor:
	case eUICustomizeCat_FaceDecorationUpper:
	case eUICustomizeCat_FaceDecorationLower:
	case eUICustomizeCat_FacialHair:
	case eUICustomizeCat_Helmet:
	case eUICustomizeCat_Scars:
	case eUICustomizeCat_FacePaint:
		CameraTag = HeadCameraTag;
		AnimName = StandingStillAnimName; // play by the book anim when looking at face
		bCosmeticPawnOnscreen = false;
		
		break;
	case eUICustomizeCat_Legs:
		CameraTag = LegsCameraTag;
		bCosmeticPawnOnscreen = true;		
		break;
	default:
		CameraTag = RegularCameraTag;
		bCosmeticPawnOnscreen = true;
	break;
	}

	HQPres = `HQPRES;
	ShellPres = XComShellPresentationLayer(`PRESBASE);
	if(HQPres != none)
	{
		HQCamera = HQPres.GetCamera();
	}
	else
	{		
		HQCamera = ShellPres.GetCamera();
	}
	
	// the locked display will follow with the camera, so that as the user switches between customizing
	// different things, the camera doesn't jump all over
	// find the current active ui display
	foreach HQCamera.AllActors(class'UIDisplay_LevelActor', DisplayActor)
	{
		if(DisplayActor.m_kMovie != none)
		{
			DisplayActor.SetLockedToCamera(true);
			break;
		}
	}
	
	
	//bHasOldCameraState means we are still blending from the previous camera
	if(HQCamera.bHasOldCameraState)
	{
		if(LastSetCameraTag != CameraTag)
		{
			bExecuteCameraChange = true;			
		}
	}
	else
	{
		bExecuteCameraChange = true;		
	}

	if(bExecuteCameraChange)
	{
		if(bCosmeticPawnOnscreen)
		{
			MoveCosmeticPawnOnscreen();
		}
		else
		{
			MoveCosmeticPawnOffscreen();
		}

		if(HQPres != none)
		{
			HQPres.CAMLookAtNamedLocation(string(CameraTag), `HQINTERPTIME);
		}
		else
		{
			ShellPres.CAMLookAtNamedLocation(string(CameraTag), `HQINTERPTIME);
		}

		XComHumanPawn(ActorPawn).PlayHQIdleAnim(AnimName, , true);
	}

	LastSetCameraTag = CameraTag;
}

function MoveCosmeticPawnOnscreen()
{
	local XComHumanPawn UnitPawn;
	local XComUnitPawn CosmeticPawn;
	local UIPawnMgr PawnMgr;

	PawnMgr = XComPresentationLayerBase(Outer).GetUIPawnMgr();

	UnitPawn = XComHumanPawn(ActorPawn);
	if (UnitPawn == none)
		return;

	CosmeticPawn = PawnMgr.GetCosmeticPawn(eInvSlot_SecondaryWeapon, UnitRef.ObjectID);
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

private function MoveCosmeticPawnOffscreen()
{
	local XComHumanPawn UnitPawn;
	local XComUnitPawn CosmeticPawn;
	local UIPawnMgr PawnMgr;

	PawnMgr = XComPresentationLayerBase(Outer).GetUIPawnMgr();

	UnitPawn = XComHumanPawn(ActorPawn);
	if (UnitPawn == none)
		return;

	CosmeticPawn = PawnMgr.GetCosmeticPawn(eInvSlot_SecondaryWeapon, UnitRef.ObjectID);
	if (CosmeticPawn == none)
		return;

	if (CosmeticPawn.IsInState('Offscreen'))
		return;

	CosmeticPawn.GotoState('MoveOffscreen');
}

function int GetCategoryValue( string BodyPart, name PartToMatch, delegate<X2BodyPartFilter.FilterCallback> FilterFn )
{
	local array<X2BodyPartTemplate> BodyParts;
	local int PartIndex;
	local int categoryValue;

	PartManager.GetFilteredUberTemplates(BodyPart, self, FilterFn, BodyParts);
	for( PartIndex = 0; PartIndex < BodyParts.Length; ++PartIndex )
	{
		if( PartToMatch == BodyParts[PartIndex].DataName )
		{
			categoryValue = PartIndex;
			break;
		}
	}

	return categoryValue;
}

function string GetCategoryDisplayName( string BodyPart, name PartToMatch, delegate<X2BodyPartFilter.FilterCallback> FilterFn )
{
	local int PartIndex;
	local name DefaultTemplateName;
	local array<X2BodyPartTemplate> BodyParts;

	PartManager.GetFilteredUberTemplates(BodyPart, self, FilterFn, BodyParts);
	for( PartIndex = 0; PartIndex < BodyParts.Length; ++PartIndex )
	{
		if( PartToMatch == BodyParts[PartIndex].DataName )
		{
			return BodyParts[PartIndex].DisplayName;
		}
	}

	switch(BodyPart)
	{
		case "Patterns": DefaultTemplateName = 'Pat_Nothing'; break;
		case "Helmets": DefaultTemplateName = 'Helmet_0_NoHelmet_M'; break;
		case "Scars": DefaultTemplateName = 'Scars_BLANK'; break;
	}

	return PartManager.FindUberTemplate(BodyPart, DefaultTemplateName).DisplayName;
}

simulated function string GetCategoryDisplay(int catType)
{
	local string Result;
	local X2SoldierPersonalityTemplate PersonalityTemplate;
	local array<X2StrategyElementTemplate> PersonalityTemplateList;

	switch(catType)
	{
	case eUICustomizeCat_FirstName:
		Result = UpdatedUnitState.GetFirstName();
		break;
	case eUICustomizeCat_LastName:
		Result = UpdatedUnitState.GetLastName(); 
		break;
	case eUICustomizeCat_NickName:
		Result = UpdatedUnitState.GetNickName();
		break;
	case eUICustomizeCat_WeaponName:
		Result = UpdatedUnitState.GetItemInSlot(eInvSlot_PrimaryWeapon, CheckGameState).Nickname;
		break;
	case eUICustomizeCat_Torso:  
		Result = string(GetCategoryValue("Torso", UpdatedUnitState.kAppearance.nmTorso, BodyPartFilter.FilterByTorsoAndArmorMatch));
		break;
	case eUICustomizeCat_Arms:              
		Result = string(GetCategoryValue("Arms", UpdatedUnitState.kAppearance.nmArms, BodyPartFilter.FilterByTorsoAndArmorMatch));
		break;
	case eUICustomizeCat_Legs:              
		Result = string(GetCategoryValue("Legs", UpdatedUnitState.kAppearance.nmLegs, BodyPartFilter.FilterByTorsoAndArmorMatch));
		break;
	case eUICustomizeCat_Skin:					 
		Result = string(UpdatedUnitState.kAppearance.iSkinColor);
		break;
	case eUICustomizeCat_Face:					 
		Result = GetCategoryDisplayName("Head", UpdatedUnitState.kAppearance.nmHead, BodyPartFilter.FilterByGenderAndRace);
		break;
	case eUICustomizeCat_EyeColor:				
		Result = string(UpdatedUnitState.kAppearance.iEyeColor);
		break;
	case eUICustomizeCat_Hairstyle:		
		Result = GetCategoryDisplayName("Hair", UpdatedUnitState.kAppearance.nmHaircut, BodyPartFilter.FilterByGenderAndNonSpecialized);
		break;
	case eUICustomizeCat_HairColor:				
		Result = string(UpdatedUnitState.kAppearance.iHairColor);
		break;
	case eUICustomizeCat_FaceDecorationUpper:
		Result = GetCategoryDisplayName("FacePropsUpper", UpdatedUnitState.kAppearance.nmFacePropUpper, BodyPartFilter.FilterByGenderAndNonSpecialized);
		break;
	case eUICustomizeCat_FaceDecorationLower:
		Result = GetCategoryDisplayName("FacePropsLower", UpdatedUnitState.kAppearance.nmFacePropLower, BodyPartFilter.FilterByGenderAndNonSpecialized);
		break;
	case eUICustomizeCat_FacialHair:			 
		Result = GetCategoryDisplayName("Beards", UpdatedUnitState.kAppearance.nmBeard, BodyPartFilter.FilterByGenderAndNonSpecialized);
		break;
	case eUICustomizeCat_Personality:			 
		PersonalityTemplateList = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().GetAllTemplatesOfClass(class'X2SoldierPersonalityTemplate');
		PersonalityTemplate = X2SoldierPersonalityTemplate(PersonalityTemplateList[UpdatedUnitState.kAppearance.iAttitude]);
		Result = PersonalityTemplate.FriendlyName;
		break;
	case eUICustomizeCat_Country:
		Result = UpdatedUnitState.GetCountryTemplate().DisplayName;
		break;
	case eUICustomizeCat_Voice:
		Result = GetCategoryDisplayName("Voice", UpdatedUnitState.kAppearance.nmVoice, BodyPartFilter.FilterByGenderAndNonSpecialized);
		break;
	case eUICustomizeCat_Gender:				 
		if( UpdatedUnitState.kAppearance.iGender == eGender_Male ) Result = Gender_Male;
		else if( UpdatedUnitState.kAppearance.iGender == eGender_Female ) Result = Gender_Female;
		break;
	case eUICustomizeCat_Race:
		Result = string(UpdatedUnitState.kAppearance.iRace);
		break;
	case eUICustomizeCat_Helmet:              
		Result = GetCategoryDisplayName("Helmets", UpdatedUnitState.kAppearance.nmHelmet, BodyPartFilter.FilterByGenderAndNonSpecializedAndTech);
		break;
	case eUICustomizeCat_PrimaryArmorColor:   
		Result = string(UpdatedUnitState.kAppearance.iArmorTint);
		break;
	case eUICustomizeCat_SecondaryArmorColor: 
		Result = string(UpdatedUnitState.kAppearance.iArmorTintSecondary);
		break;
	case eUICustomizeCat_WeaponColor:		
		Result = string(PrimaryWeapon.WeaponAppearance.iWeaponTint);
		break;
	case eUICustomizeCat_ArmorPatterns:       
		Result = GetCategoryDisplayName("Patterns", UpdatedUnitState.kAppearance.nmPatterns, BodyPartFilter.FilterAny);
		break;
	case eUICustomizeCat_WeaponPatterns:
		Result = GetCategoryDisplayName("Patterns", PrimaryWeapon.WeaponAppearance.nmWeaponPattern, BodyPartFilter.FilterAny);
		break;
	case eUICustomizeCat_FacePaint:
		Result = GetCategoryDisplayName("Facepaint", UpdatedUnitState.kAppearance.nmFacePaint, BodyPartFilter.FilterAny);
		break;
	case eUICustomizeCat_LeftArmTattoos:
		Result = GetCategoryDisplayName("Tattoos", UpdatedUnitState.kAppearance.nmTattoo_LeftArm, BodyPartFilter.FilterAny);
		break;
	case eUICustomizeCat_RightArmTattoos:
		Result = GetCategoryDisplayName("Tattoos", UpdatedUnitState.kAppearance.nmTattoo_RightArm, BodyPartFilter.FilterAny);
		break;
	case eUICustomizeCat_TattooColor:
		Result = string(UpdatedUnitState.kAppearance.iTattooTint);
		break;
	case eUICustomizeCat_Scars:
		Result = GetCategoryDisplayName("Scars", UpdatedUnitState.kAppearance.nmScars, BodyPartFilter.FilterAny);
		break;
	case eUICustomizeCat_Class:
		Result = UpdatedUnitState.GetSoldierClassTemplate().DisplayName;
		break;
	}

	return Result;
}

private function int GetCategoryValueGeneric( string BodyPart, name PartToMatch, delegate<X2BodyPartFilter.FilterCallback> FilterFn )
{
	local int PartIndex;
	local array<X2BodyPartTemplate> BodyParts;

	PartManager.GetFilteredUberTemplates(BodyPart, self, FilterFn, BodyParts);
	for( PartIndex = 0; PartIndex < BodyParts.Length; ++PartIndex )
	{
		if( PartToMatch == BodyParts[PartIndex].DataName )
		{
			return PartIndex;
		}
	}

	return -1;
}

simulated function string FormatCategoryDisplay(int catType, optional EUIState ColorState = eUIState_Normal, optional int FontSize = -1)
{
	return class'UIUtilities_Text'.static.GetColoredText(GetCategoryDisplay(catType), ColorState, FontSize);
}

//==============================================================================

reliable client function array<string> GetCategoryList( int categoryIndex )
{
	local int i;
	local array<string> Items;
	local array<name> TemplateNames;
	local X2StrategyElementTemplateManager StratMgr;
	local array<X2StrategyElementTemplate> CountryTemplates;
	local X2SoldierClassTemplateManager TemplateMan;
	local X2SoldierClassTemplate SoldierClassTemplate;
	local array<X2StrategyElementTemplate> PersonalityTemplateList;
	local X2SoldierPersonalityTemplate PersonalityTemplate;

	switch(categoryIndex)
	{
	case eUICustomizeCat_Face:
		GetGenericCategoryList(Items, "Head", BodyPartFilter.FilterByGenderAndRace, class'UICustomize_Menu'.default.m_strFace);
		return Items;
	case eUICustomizeCat_Hairstyle: 
		GetGenericCategoryList(Items, "Hair", BodyPartFilter.FilterByGenderAndNonSpecialized, class'UICustomize_Menu'.default.m_strHair);
		return Items;
	case eUICustomizeCat_FacialHair: 
		GetGenericCategoryList(Items, "Beards", BodyPartFilter.FilterByGenderAndNonSpecialized, class'UICustomize_Menu'.default.m_strFacialHair);
		return Items;
	case eUICustomizeCat_Race:
		for(i = 0; i < eRace_MAX; ++i)
		{
			Items.AddItem(class'UICustomize_Menu'.default.m_strRace @ string(i));
		}
		return Items;
	case eUICustomizeCat_Voice:
		GetGenericCategoryList(Items, "Voice", BodyPartFilter.FilterByGenderAndNonSpecialized, class'UICustomize_Menu'.default.m_strVoice);
		return Items;
	case eUICustomizeCat_Helmet:
		GetGenericCategoryList(Items, "Helmets", BodyPartFilter.FilterByGenderAndNonSpecializedAndTech, class'UICustomize_Props'.default.m_strHelmet);
		return Items;
	case eUICustomizeCat_ArmorPatterns:
		GetGenericCategoryList(Items, "Patterns", BodyPartFilter.FilterAny, class'UICustomize_Props'.default.m_strArmorPattern);
		return Items;
	case eUICustomizeCat_WeaponPatterns:
		GetGenericCategoryList(Items, "Patterns", BodyPartFilter.FilterAny, class'UICustomize_Props'.default.m_strWeaponPattern);
		return Items;
	case eUICustomizeCat_FacePaint:
		GetGenericCategoryList(Items, "Facepaint", BodyPartFilter.FilterAny, class'UICustomize_Props'.default.m_strFacePaint);		
		return Items;
	case eUICustomizeCat_LeftArmTattoos:
		GetGenericCategoryList(Items, "Tattoos", BodyPartFilter.FilterAny, class'UICustomize_Props'.default.m_strTattoosLeft);
		return Items;
	case eUICustomizeCat_RightArmTattoos:
		GetGenericCategoryList(Items, "Tattoos", BodyPartFilter.FilterAny, class'UICustomize_Props'.default.m_strTattoosRight);
		return Items;
	case eUICustomizeCat_Scars:
		GetGenericCategoryList(Items, "Scars", BodyPartFilter.FilterAny, class'UICustomize_Props'.default.m_strScars);
		return Items;
	case eUICustomizeCat_Arms:
		GetGenericCategoryList(Items, "Arms", BodyPartFilter.FilterByTorsoAndArmorMatch, class'UICustomize_Props'.default.m_strArms);
		return Items;
	case eUICustomizeCat_Torso:
		GetGenericCategoryList(Items, "Torso", BodyPartFilter.FilterByTorsoAndArmorMatch, class'UICustomize_Props'.default.m_strTorso);
		return Items;
	case eUICustomizeCat_Legs:
		GetGenericCategoryList(Items, "Legs", BodyPartFilter.FilterByTorsoAndArmorMatch, class'UICustomize_Props'.default.m_strLegs);
		return Items;
	case eUICustomizeCat_FaceDecorationUpper:
		GetGenericCategoryList(Items, "FacePropsUpper", BodyPartFilter.FilterByGenderAndNonSpecialized, class'UICustomize_Props'.default.m_strUpperFaceProps);
		return Items;
	case eUICustomizeCat_FaceDecorationLower:
		GetGenericCategoryList(Items, "FacePropsLower", BodyPartFilter.FilterByGenderAndNonSpecialized, class'UICustomize_Props'.default.m_strLowerFaceProps);
		return Items;
	case eUICustomizeCat_Personality:  
		PersonalityTemplateList = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().GetAllTemplatesOfClass(class'X2SoldierPersonalityTemplate');
		for(i = 0; i < PersonalityTemplateList.Length; i++)
		{
			PersonalityTemplate = X2SoldierPersonalityTemplate(PersonalityTemplateList[i]);
			Items.AddItem(PersonalityTemplate.FriendlyName);
		}
		return Items;

	case eUICustomizeCat_Gender:
		Items.AddItem(Gender_Male);
		Items.AddItem(Gender_Female);
		return Items;
	case eUICustomizeCat_Country: 
		StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
		CountryTemplates = StratMgr.GetAllTemplatesOfClass(class'X2CountryTemplate');
		CountryTemplates.Sort(SortCountryTemplates);
		for( i = 0; i < CountryTemplates.Length; i++ )
		{
			Items.AddItem( X2CountryTemplate(CountryTemplates[i]).DisplayName );
		}
		return Items; 
	case eUICustomizeCat_Class:
		TemplateMan = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();
		TemplateMan.GetTemplateNames(TemplateNames);

		for( i = 0; i < TemplateNames.Length; i++ )
		{
			SoldierClassTemplate = TemplateMan.FindSoldierClassTemplate(TemplateNames[i]);

			if(!SoldierClassTemplate.bMultiplayerOnly)
			{
				Items.AddItem(SoldierClassTemplate.DisplayName);
			}
			
		}

		Items.AddItem( RandomClass );
		return Items; 

	}
	//Else return empty:
	Items.Length = 0;
	return Items; 
}

private function GetGenericCategoryList(out array<string> Items,  string BodyPart, delegate<X2BodyPartFilter.FilterCallback> FilterFn, optional string PrefixLocText )
{
	local int i;
	local array<X2BodyPartTemplate> BodyParts;

	PartManager.GetFilteredUberTemplates(BodyPart, self, FilterFn, BodyParts);
	for( i = 0; i < BodyParts.Length; ++i )
	{
		if(BodyParts[i].DisplayName != "")
			Items.AddItem(BodyParts[i].DisplayName);
		else if(PrefixLocText != "")
			Items.AddItem(PrefixLocText @ i);
		else
			Items.AddItem(string(i));
	}
}

simulated function bool HasMultipleCustomizationOptions(int catType)
{
	local array<string> CustomizationOptions;
	CustomizationOptions = GetCategoryList(catType);
	return CustomizationOptions.Length > 1;
}

simulated function bool HasBeard()
{
	return UpdatedUnitState.kAppearance.nmBeard != 'MaleBeard_Blank' && UpdatedUnitState.kAppearance.nmBeard != 'Central_StratBeard';
}

simulated function int GetCategoryIndex(int catType)
{
	local int i, Result;
	local name UnitCountryTemplate;
	local X2StrategyElementTemplateManager StratMgr;
	local array<X2StrategyElementTemplate> CountryTemplates;

	Result = -1;

	switch(catType)
	{
	case eUICustomizeCat_Torso:  
		Result = GetCategoryValue("Torso", UpdatedUnitState.kAppearance.nmTorso, BodyPartFilter.FilterByTorsoAndArmorMatch);
		break;
	case eUICustomizeCat_Arms:              
		Result = GetCategoryValue("Arms", UpdatedUnitState.kAppearance.nmArms, BodyPartFilter.FilterByTorsoAndArmorMatch);
		break;
	case eUICustomizeCat_Legs:              
		Result = GetCategoryValue("Legs", UpdatedUnitState.kAppearance.nmLegs, BodyPartFilter.FilterByTorsoAndArmorMatch);
		break;
	case eUICustomizeCat_Skin:					 
		Result = UpdatedUnitState.kAppearance.iSkinColor;
		break;
	case eUICustomizeCat_Face:					 
		Result = GetCategoryValue("Head", UpdatedUnitState.kAppearance.nmHead, BodyPartFilter.FilterByGenderAndRace);
		break;
	case eUICustomizeCat_EyeColor:				
		Result = UpdatedUnitState.kAppearance.iEyeColor;
		break;
	case eUICustomizeCat_Hairstyle:		
		Result = GetCategoryValue("Hair", UpdatedUnitState.kAppearance.nmHaircut, BodyPartFilter.FilterByGenderAndNonSpecialized);
		break;
	case eUICustomizeCat_HairColor:				
		Result = UpdatedUnitState.kAppearance.iHairColor;
		break;
	case eUICustomizeCat_FaceDecorationUpper:
		Result = GetCategoryValue("FacePropsUpper", UpdatedUnitState.kAppearance.nmFacePropUpper, BodyPartFilter.FilterByGenderAndNonSpecialized);
		break;
	case eUICustomizeCat_FaceDecorationLower:
		Result = GetCategoryValue("FacePropsLower", UpdatedUnitState.kAppearance.nmFacePropLower, BodyPartFilter.FilterByGenderAndNonSpecialized);
		break;
	case eUICustomizeCat_FacialHair:			 
		Result = GetCategoryValue("Beards", UpdatedUnitState.kAppearance.nmBeard, BodyPartFilter.FilterByGenderAndNonSpecialized);
		break;
	case eUICustomizeCat_Personality:			 
		Result = UpdatedUnitState.kAppearance.iAttitude;
		break;
	case eUICustomizeCat_Voice:
		Result = GetCategoryValue("Voice", UpdatedUnitState.kAppearance.nmVoice, BodyPartFilter.FilterByGenderAndNonSpecialized);
		break;
	case eUICustomizeCat_Gender:				 
		Result = UpdatedUnitState.kAppearance.iGender;
		break;
	case eUICustomizeCat_Race:					 
		Result = UpdatedUnitState.kAppearance.iRace;
		break;
	case eUICustomizeCat_Helmet:              
		Result = GetCategoryValue("Helmets", UpdatedUnitState.kAppearance.nmHelmet, BodyPartFilter.FilterByGenderAndNonSpecializedAndTech);
		break;
	case eUICustomizeCat_PrimaryArmorColor:   
		Result = UpdatedUnitState.kAppearance.iArmorTint;
		break;
	case eUICustomizeCat_SecondaryArmorColor: 
		Result = UpdatedUnitState.kAppearance.iArmorTintSecondary;
		break;
	case eUICustomizeCat_WeaponColor:
		Result = XGWeapon(PrimaryWeapon.GetVisualizer()).m_kAppearance.iWeaponTint;
		break;
	case eUICustomizeCat_ArmorPatterns:       
		Result = GetCategoryValue("Patterns", UpdatedUnitState.kAppearance.nmPatterns, BodyPartFilter.FilterAny);
		break;
	case eUICustomizeCat_WeaponPatterns:
		Result = GetCategoryValue("Patterns", XGWeapon(PrimaryWeapon.GetVisualizer()).m_kAppearance.nmWeaponPattern, BodyPartFilter.FilterAny);
		break;
	case eUICustomizeCat_FacePaint:
		Result = GetCategoryValue("Facepaint", UpdatedUnitState.kAppearance.nmFacePaint, BodyPartFilter.FilterAny);
		break;
	case eUICustomizeCat_LeftArmTattoos:
		Result = GetCategoryValue("Tattoos", UpdatedUnitState.kAppearance.nmTattoo_LeftArm, BodyPartFilter.FilterAny);
		break;
	case eUICustomizeCat_RightArmTattoos:
		Result = GetCategoryValue("Tattoos", UpdatedUnitState.kAppearance.nmTattoo_RightArm, BodyPartFilter.FilterAny);
		break;
	case eUICustomizeCat_TattooColor:
		Result = UpdatedUnitState.kAppearance.iTattooTint;
		break;
	case eUICustomizeCat_Scars:
		Result = GetCategoryValue("Scars", UpdatedUnitState.kAppearance.nmScars, BodyPartFilter.FilterAny);
		break;
	case eUICustomizeCat_Country:
		StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
		CountryTemplates = StratMgr.GetAllTemplatesOfClass(class'X2CountryTemplate');
		CountryTemplates.Sort(SortCountryTemplates);
		UnitCountryTemplate = UpdatedUnitState.GetCountryTemplate().DataName;
		for(i = 0; i < CountryTemplates.Length; ++i)
		{
			if(UnitCountryTemplate == CountryTemplates[i].DataName)
			{
				Result = i;
				break;
			}
		}
		break;
	}

	return Result;
}

simulated function array<string> GetColorList( int catType )
{
	local XComLinearColorPalette Palette;
	local array<string> Colors; 
	local int i; 

	switch (catType)
	{
	case eUICustomizeCat_Skin:	
		Palette = `CONTENT.GetColorPalette(XComHumanPawn(ActorPawn).HeadContent.SkinPalette);
		for( i = 0; i < Palette.Entries.length; i++ )
		{
			Colors.AddItem( class'UIUtilities_Colors'.static.LinearColorToFlashHex( Palette.Entries[i].Primary, UIColorBrightnessAdjust ) );
		}
		break;
	case eUICustomizeCat_HairColor:	
		Palette = `CONTENT.GetColorPalette(ePalette_HairColor);
		for( i = 0; i < Palette.Entries.length; i++ )
		{
			Colors.AddItem( class'UIUtilities_Colors'.static.LinearColorToFlashHex( Palette.Entries[i].Primary, UIColorBrightnessAdjust ) );
		}
		break;
	case eUICustomizeCat_EyeColor:	
		Palette = `CONTENT.GetColorPalette(ePalette_EyeColor);
		for( i = 0; i < Palette.Entries.length; i++ )
		{
			Colors.AddItem( class'UIUtilities_Colors'.static.LinearColorToFlashHex( Palette.Entries[i].Primary, UIColorBrightnessAdjust ) );
		}
		break;
	case eUICustomizeCat_PrimaryArmorColor:	
		Palette = `CONTENT.GetColorPalette(ePalette_ArmorTint);
		for( i = 0; i < Palette.Entries.length; i++ )
		{
			Colors.AddItem( class'UIUtilities_Colors'.static.LinearColorToFlashHex( Palette.Entries[i].Primary, UIColorBrightnessAdjust ) );
		}
		break;
	case eUICustomizeCat_SecondaryArmorColor:	
		Palette = `CONTENT.GetColorPalette(ePalette_ArmorTint);
		for( i = 0; i < Palette.Entries.length; i++ )
		{
			Colors.AddItem( class'UIUtilities_Colors'.static.LinearColorToFlashHex( Palette.Entries[i].Secondary, UIColorBrightnessAdjust ) );
		}
		break;
	case eUICustomizeCat_WeaponColor:
		Palette = `CONTENT.GetColorPalette(ePalette_ArmorTint);
		for(i = 0; i < Palette.Entries.length; i++)
		{
			Colors.AddItem(class'UIUtilities_Colors'.static.LinearColorToFlashHex(Palette.Entries[i].Primary, UIColorBrightnessAdjust));
		}
		break;
	case eUICustomizeCat_TattooColor:
		Palette = `CONTENT.GetColorPalette(ePalette_ArmorTint);
		for(i = 0; i < Palette.Entries.length; i++)
		{
			Colors.AddItem(class'UIUtilities_Colors'.static.LinearColorToFlashHex(Palette.Entries[i].Primary, UIColorBrightnessAdjust));
		}
		break;
	default:
		break;
	}

	return Colors;
}

simulated function string GetCurrentDisplayColorHTML( int catType )
{	
	local XComLinearColorPalette Palette;
	local XComGameState_Item WeaponItem;

	switch (catType)
	{
	case eUICustomizeCat_Skin:	
		Palette = `CONTENT.GetColorPalette(XComHumanPawn(ActorPawn).HeadContent.SkinPalette);
		return class'UIUtilities_Colors'.static.LinearColorToFlashHex( Palette.Entries[UpdatedUnitState.kAppearance.iSkinColor].Primary, UIColorBrightnessAdjust );
	case eUICustomizeCat_HairColor:	
		Palette = `CONTENT.GetColorPalette(ePalette_HairColor);
		return class'UIUtilities_Colors'.static.LinearColorToFlashHex( Palette.Entries[UpdatedUnitState.kAppearance.iHairColor].Primary, UIColorBrightnessAdjust );
	case eUICustomizeCat_EyeColor:	
		Palette = `CONTENT.GetColorPalette(ePalette_EyeColor);
		return class'UIUtilities_Colors'.static.LinearColorToFlashHex( Palette.Entries[UpdatedUnitState.kAppearance.iEyeColor].Primary, UIColorBrightnessAdjust );
	case eUICustomizeCat_PrimaryArmorColor:	
		Palette = `CONTENT.GetColorPalette(ePalette_ArmorTint);
		return class'UIUtilities_Colors'.static.LinearColorToFlashHex( Palette.Entries[UpdatedUnitState.kAppearance.iArmorTint].Primary, UIColorBrightnessAdjust );
	case eUICustomizeCat_SecondaryArmorColor:	
		Palette = `CONTENT.GetColorPalette(ePalette_ArmorTint);
		return class'UIUtilities_Colors'.static.LinearColorToFlashHex( Palette.Entries[UpdatedUnitState.kAppearance.iArmorTintSecondary].Secondary, UIColorBrightnessAdjust );
	case eUICustomizeCat_WeaponColor:
		Palette = `CONTENT.GetColorPalette(ePalette_ArmorTint);
		WeaponItem = PrimaryWeapon;
		return class'UIUtilities_Colors'.static.LinearColorToFlashHex(Palette.Entries[WeaponItem.WeaponAppearance.iWeaponTint].Primary, UIColorBrightnessAdjust);
	case eUICustomizeCat_TattooColor:
		Palette = `CONTENT.GetColorPalette(ePalette_ArmorTint);
		return class'UIUtilities_Colors'.static.LinearColorToFlashHex(Palette.Entries[UpdatedUnitState.kAppearance.iTattooTint].Primary, UIColorBrightnessAdjust);
	default:
		break;
	}

	return "";
}

simulated function string GetCurrentSoldierFullDisplayName()
{
	local string soldierName; 
	if( Unit.GetNickName() != "" )
		soldierName = Unit.GetFirstName() @ Unit.GetNickName() @ Unit.GetLastName();
	else
		soldierName = Unit.GetFirstName() @ Unit.GetLastName();

	return soldierName; 
}

function bool ShowMaleOnlyOptions()
{
	return (UpdatedUnitState.kAppearance.iGender == eGender_Male);
}

function bool IsFacialHairDisabled()
{
	local XComHumanPawn HumanPawn;

	HumanPawn = XComHumanPawn(ActorPawn);

	return HumanPawn.HelmetContent.bHideFacialHair || HumanPawn.LowerFacialContent.bHideFacialHair; 
}

simulated function bool IsArmorPatternSelected()
{
	return (0 != GetCategoryValue("Patterns", UpdatedUnitState.kAppearance.nmPatterns, BodyPartFilter.FilterByGenderAndNonSpecialized));
}

simulated function UpdateClass( int iSpecificIndex )
{
	local X2SoldierClassTemplateManager TemplateMan;
	local X2SoldierClassTemplate SoldierClassTemplate;
	local array<name> TemplateNames;
	local name TemplateName; 
	local int iRandomIndex, idx;
	local Rotator CachedRotation;

	TemplateMan = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();
	TemplateMan.GetTemplateNames(TemplateNames);

	for(idx = 0; idx < TemplateNames.Length; idx++)
	{
		SoldierClassTemplate = TemplateMan.FindSoldierClassTemplate(TemplateNames[idx]);

		if(SoldierClassTemplate.bMultiplayerOnly)
		{
			TemplateNames.Remove(idx, 1);
			idx--;
		}
	}

	if( iSpecificIndex < TemplateNames.Length && iSpecificIndex > -1 )
	{
		TemplateName = TemplateNames[iSpecificIndex];
	}
	else
	{
		iRandomIndex = `SYNC_RAND(TemplateNames.Length);
		TemplateName = TemplateNames[iRandomIndex];
	}

	UpdatedUnitState.SetSoldierClassTemplate( TemplateName );
	
	if( ActorPawn != none )
	{
		CachedRotation = ActorPawn.Rotation;
		XComPresentationLayerBase(Outer).GetUIPawnMgr().ReleasePawn(XComPresentationLayerBase(Outer), UnitRef.ObjectID);
	}

	CreatePawnVisuals(CachedRotation);
}

simulated function UpdateAllowedTypeSoldier(int iSpecificIndex)
{
	UpdatedUnitState.bAllowedTypeSoldier = (iSpecificIndex != 0 ? true : false);
}
simulated function UpdateAllowedTypeVIP(int iSpecificIndex)
{
	UpdatedUnitState.bAllowedTypeVIP = (iSpecificIndex != 0 ? true : false);
}
simulated function UpdateAllowedTypeDarkVIP(int iSpecificIndex)
{
	UpdatedUnitState.bAllowedTypeDarkVIP = (iSpecificIndex != 0 ? true : false);
}

simulated function UpdateCountry(int iSpecificIndex)
{
	local X2StrategyElementTemplateManager StratMgr;
	local array<X2StrategyElementTemplate> CountryTemplates;
	local name TemplateName;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	CountryTemplates = StratMgr.GetAllTemplatesOfClass(class'X2CountryTemplate');
	CountryTemplates.Sort(SortCountryTemplates);

	if(iSpecificIndex < CountryTemplates.Length && iSpecificIndex > -1)
	{
		TemplateName = CountryTemplates[iSpecificIndex].DataName;
	}
	else
	{
		//TODO: @nway or @gameplay: how do we store a real random/any country for the pool to load in? 
		TemplateName = CountryTemplates[0].DataName;
	}

	UpdatedUnitState.SetCountry(TemplateName);

	//Country changes the flag on the unit, so remake the unit
	XComHumanPawn(ActorPawn).SetAppearance(UpdatedUnitState.kAppearance);
}

simulated function int SortCountryTemplates(X2StrategyElementTemplate A, X2StrategyElementTemplate B)
{
	local X2CountryTemplate CountryA, CountryB;
	CountryA = X2CountryTemplate(A);
	CountryB = X2CountryTemplate(B);
	if (CountryA.DisplayName < CountryB.DisplayName)
		return 1;
	else if (CountryA.DisplayName > CountryB.DisplayName)
		return -1;
	return 0;
}

//==============================================================================

function CommitChanges()
{
	local CharacterPoolManager cpm;

	if(Unit != none)
	{
		Unit.SetSoldierClassTemplate(Unit.GetSoldierClassTemplate().DataName);
		Unit.SetTAppearance(UpdatedUnitState.kAppearance);
		Unit.SetCharacterName(UpdatedUnitState.SafeGetCharacterFirstName(), UpdatedUnitState.SafeGetCharacterLastName(), UpdatedUnitState.SafeGetCharacterNickName());
		Unit.SetCountry(UpdatedUnitState.GetCountry());

		cpm = CharacterPoolManager(`XENGINE.GetCharacterPoolManager());
		cpm.SaveCharacterPool();

		if(`GAME != none)
		{
			`GAME.GetGeoscape().m_kBase.m_kCrewMgr.TakeCrewPhotobgraph(Unit.GetReference(), true);
		}		
	}

	if(PrimaryWeapon != None &&
	   UpdatedUnitState.GetPrimaryWeapon() == PrimaryWeapon) //Only do this if we are in the avenger, and not the character pool
	{
		SubmitWeaponCustomizationChanges();
	}
		
}

simulated function OnDeactivate( bool bAcceptChanges )
{
	if( bAcceptChanges )
	{
		CommitChanges();
	}

	if( ActorPawn != none )
	{
		XComPresentationLayerBase(Outer).GetUIPawnMgr().ReleasePawn(XComPresentationLayerBase(Outer), UnitRef.ObjectID);
	}

	if( CharacterGenerator != None )
	{
		CharacterGenerator.Destroy();
	}

	if (PartManager.DisablePostProcessWhenCustomizing)
	{
		class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().ConsoleCommand("show postprocess");
	}
}

simulated function SubmitWeaponCustomizationChanges()
{
	local XComGameState WeaponCustomizationState;
	local XComGameState_Item UpdatedWeapon;
	local XComGameStateContext_ChangeContainer ChangeContainer;

	if(HasWeaponAppearanceChanged()) 
	{
		ChangeContainer = class'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("Weapon Customize");
		WeaponCustomizationState = History.CreateNewGameState(true, ChangeContainer);
		UpdatedWeapon = XComGameState_Item(WeaponCustomizationState.CreateStateObject(class'XComGameState_Item', PrimaryWeapon.ObjectID));
		UpdatedWeapon.WeaponAppearance = XGWeapon(PrimaryWeapon.GetVisualizer()).m_kAppearance;
		WeaponCustomizationState.AddStateObject(UpdatedWeapon);
		`GAMERULES.SubmitGameState(WeaponCustomizationState);
	}
}

simulated function bool HasWeaponAppearanceChanged()
{
	local XComGameState_Item PrevState;
	PrevState = XComGameState_Item(History.GetGameStateForObjectID(PrimaryWeapon.ObjectID));
	return PrevState.WeaponAppearance != XGWeapon(PrimaryWeapon.GetVisualizer()).m_kAppearance;
}


//==============================================================================

defaultproperties
{
	RegularCameraTag="UIBlueprint_CustomizeMenu"
	RegularDisplayTag="UIBlueprint_CustomizeMenu"
	HeadCameraTag="UIBlueprint_CustomizeHead"
	HeadDisplayTag="UIBlueprint_CustomizeHead"
	LegsCameraTag="UIBlueprint_CustomizeLegs"
	LegsDisplayTag="UIBlueprint_CustomizeLegs"
}