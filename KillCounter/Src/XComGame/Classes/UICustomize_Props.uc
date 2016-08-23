//---------------------------------------------------------------------------------------
//  FILE:    UICustomize_Gear.uc
//  AUTHOR:  Brit Steiner --  8/29/2014
//  PURPOSE: Soldier gear options list. 
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class UICustomize_Props extends UICustomize;

//----------------------------------------------------------------------------
// MEMBERS

var string DEBUG_PrimaryColor; 
var string DEBUG_PrimaryColor_Label; 
var string DEBUG_SecondaryColor; 
var string DEBUG_SecondaryColor_Label; 

var localized string m_strTitle;
var localized string m_strUpperFaceProps;
var localized string m_strLowerFaceProps;
var localized string m_strHelmet;
var localized string m_strArms;
var localized string m_strTorso;
var localized string m_strLegs;
var localized string m_strArmorPattern;
var localized string m_strWeaponName;
var localized string m_strWeaponColor;
var localized string m_strWeaponPattern;
var localized string m_strTattoosLeft;
var localized string m_strTattoosRight;
var localized string m_strTattooColor;
var localized string m_strScars;
var localized string m_strClearButton;
var localized string m_strFacePaint;

//----------------------------------------------------------------------------
// FUNCTIONS

simulated function UpdateData()
{
	local int i;
	local bool bHasOptions, bIsObstructed;
	local EUIState ColorState;	
	local int currentSel;
	currentSel = List.SelectedIndex;
	
	super.UpdateData();

	ColorState = bIsSuperSoldier ? eUIState_Disabled : eUIState_Normal;

	// HELMET
	//-----------------------------------------------------------------------------------------
	GetListItem(i++)
		.UpdateDataValue(class'UIUtilities_Text'.static.GetColoredText(m_strHelmet, ColorState), CustomizeManager.FormatCategoryDisplay(eUICustomizeCat_Helmet, ColorState, FontSize),CustomizeHelmet)
		.SetDisabled(bIsSuperSoldier, m_strIsSuperSoldier);

	// ARMS
	//-----------------------------------------------------------------------------------------
	GetListItem(i++).UpdateDataValue(class'UIUtilities_Text'.static.GetColoredText(m_strArms, eUIState_Normal),
		CustomizeManager.FormatCategoryDisplay( eUICustomizeCat_Arms,, FontSize ), CustomizeArms);

	// LEGS
	//-----------------------------------------------------------------------------------------
	GetListItem(i++).UpdateDataValue(class'UIUtilities_Text'.static.GetColoredText(m_strLegs, eUIState_Normal),
		CustomizeManager.FormatCategoryDisplay( eUICustomizeCat_Legs,, FontSize ), CustomizeLegs);

	// TORSO
	//-----------------------------------------------------------------------------------------
	bHasOptions = CustomizeManager.HasMultipleCustomizationOptions(eUICustomizeCat_Torso);
	ColorState = bHasOptions ? eUIState_Normal : eUIState_Disabled;

	GetListItem(i++, !bHasOptions, m_strNoVariations).UpdateDataValue(class'UIUtilities_Text'.static.GetColoredText(m_strTorso, ColorState),
		CustomizeManager.FormatCategoryDisplay( eUICustomizeCat_Torso, ColorState, FontSize ), CustomizeTorso);
	
	// UPPER FACE PROPS
	//-----------------------------------------------------------------------------------------
	bIsObstructed = XComHumanPawn(CustomizeManager.ActorPawn).HelmetContent.bHideUpperFacialProps;
	ColorState = bIsObstructed ? eUIState_Disabled : eUIState_Normal;

	GetListItem(i++, bIsObstructed, m_strRemoveHelmet).UpdateDataValue(class'UIUtilities_Text'.static.GetColoredText(m_strUpperFaceProps, ColorState),
		CustomizeManager.FormatCategoryDisplay(eUICustomizeCat_FaceDecorationUpper, ColorState, FontSize), CustomizeUpperFaceProps);

	// LOWER FACE PROPS
	//-----------------------------------------------------------------------------------------
	bIsObstructed = XComHumanPawn(CustomizeManager.ActorPawn).HelmetContent.bHideLowerFacialProps;
	ColorState = bIsObstructed ? eUIState_Disabled : eUIState_Normal;

	GetListItem(i++, bIsObstructed, m_strRemoveHelmet).UpdateDataValue(class'UIUtilities_Text'.static.GetColoredText(m_strLowerFaceProps, ColorState),
		CustomizeManager.FormatCategoryDisplay(eUICustomizeCat_FaceDecorationLower, ColorState, FontSize), CustomizeLowerFaceProps);

	// DISABLE VETERAN OPTIONS
	ColorState = bDisableVeteranOptions ? eUIState_Disabled : eUIState_Normal;

	// ARMOR PATTERN (VETERAN ONLY)
	//-----------------------------------------------------------------------------------------
	GetListItem(i++, bDisableVeteranOptions).UpdateDataValue(class'UIUtilities_Text'.static.GetColoredText(m_strArmorPattern, ColorState),
		CustomizeManager.FormatCategoryDisplay(eUICustomizeCat_ArmorPatterns, ColorState, FontSize), CustomizeArmorPattern);

	// WEAPON PATTERN
	//-----------------------------------------------------------------------------------------
	GetListItem(i++).UpdateDataValue(class'UIUtilities_Text'.static.GetColoredText(m_strWeaponPattern, eUIState_Normal),
		CustomizeManager.FormatCategoryDisplay(eUICustomizeCat_WeaponPatterns, eUIState_Normal, FontSize), CustomizeWeaponPattern);

	// FACE PAINT
	//-----------------------------------------------------------------------------------------

	//Check whether any face paint is available...	
	if(CustomizeManager.HasPartsForPartType("Facepaint"))
	{
		GetListItem(i++).UpdateDataValue(class'UIUtilities_Text'.static.GetColoredText(m_strFacePaint, eUIState_Normal),
										 CustomizeManager.FormatCategoryDisplay(eUICustomizeCat_FacePaint, eUIState_Normal, FontSize), CustomizeFacePaint);
	}

	// TATOOS (VETERAN ONLY)
	//-----------------------------------------------------------------------------------------
	GetListItem(i++, bDisableVeteranOptions).UpdateDataValue(class'UIUtilities_Text'.static.GetColoredText(m_strTattoosLeft, ColorState),
		CustomizeManager.FormatCategoryDisplay(eUICustomizeCat_LeftArmTattoos, ColorState, FontSize), CustomizeLeftArmTattoos);

	GetListItem(i++, bDisableVeteranOptions).UpdateDataValue(class'UIUtilities_Text'.static.GetColoredText(m_strTattoosRight, ColorState),
		CustomizeManager.FormatCategoryDisplay(eUICustomizeCat_RightArmTattoos, ColorState, FontSize), CustomizeRightArmTattoos);

	// TATTOO COLOR (VETERAN ONLY)
	//-----------------------------------------------------------------------------------------
	GetListItem(i++, bDisableVeteranOptions).UpdateDataColorChip(class'UIUtilities_Text'.static.GetColoredText(m_strTattooColor, ColorState),										 
		CustomizeManager.GetCurrentDisplayColorHTML(eUICustomizeCat_TattooColor), TattooColorSelector);

	// SCARS (VETERAN ONLY)
	//-----------------------------------------------------------------------------------------
	GetListItem(i++, bDisableVeteranOptions).UpdateDataValue(class'UIUtilities_Text'.static.GetColoredText(m_strScars, ColorState),
		CustomizeManager.FormatCategoryDisplay(eUICustomizeCat_Scars, ColorState, FontSize), CustomizeScars);

	if (currentSel > -1 && currentSel < List.ItemCount)
	{
		List.Navigator.SetSelected(GetListItem(currentSel));
	}
	else
	{
		List.Navigator.SetSelected(GetListItem(0));
	}
}

// --------------------------------------------------------------------------
reliable client function TattooColorSelector()
{
	CustomizeManager.UpdateCamera(eUICustomizeCat_TattooColor);
	ColorSelector = GetColorSelector(CustomizeManager.GetColorList(eUICustomizeCat_TattooColor),
		PreviewTattooColor, SetTattooColor, int(CustomizeManager.GetCategoryDisplay(eUICustomizeCat_TattooColor)));
}
function PreviewTattooColor(int iColorIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_TattooColor, -1, iColorIndex);
}
function SetTattooColor(int iColorIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_TattooColor, -1, iColorIndex);
	UpdateData();
}
// --------------------------------------------------------------------------
reliable client function WeaponColorSelector()
{
	CustomizeManager.UpdateCamera(eUICustomizeCat_WeaponColor);
	ColorSelector = GetColorSelector(CustomizeManager.GetColorList(eUICustomizeCat_WeaponColor), PreviewWeaponColor, SetWeaponColor,
									int(CustomizeManager.GetCategoryDisplay(eUICustomizeCat_WeaponColor)));
}
function PreviewWeaponColor(int iColorIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_WeaponColor, -1, iColorIndex);
}
function SetWeaponColor(int iColorIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_WeaponColor, -1, iColorIndex);
	UpdateData();
}
// ------------------------------------------------------------------------
simulated function CustomizeHelmet()
{
	CustomizeManager.UpdateCamera();
	Movie.Pres.UICustomize_Trait(m_strHelmet, "", CustomizeManager.GetCategoryList(eUICustomizeCat_Helmet),
		ChangeHelmet, ChangeHelmet, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_Helmet));
}

simulated function ChangeHelmet(UIList _list, int itemIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_Helmet, 0, itemIndex); 
}
// ------------------------------------------------------------------------
simulated function CustomizeArmorPattern()
{
	CustomizeManager.UpdateCamera();
	Movie.Pres.UICustomize_Trait(m_strArmorPattern, "", CustomizeManager.GetCategoryList(eUICustomizeCat_ArmorPatterns),
		ChangeArmorPattern, ChangeArmorPattern, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_ArmorPatterns));
}
simulated function ChangeArmorPattern(UIList _list, int itemIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_ArmorPatterns, 0, itemIndex); 
}
// ------------------------------------------------------------------------
simulated function CustomizeWeaponPattern()
{
	CustomizeManager.UpdateCamera();
	Movie.Pres.UICustomize_Trait(m_strWeaponPattern, "", CustomizeManager.GetCategoryList(eUICustomizeCat_WeaponPatterns),
		ChangeWeaponPattern, ChangeWeaponPattern, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_WeaponPatterns));
}
simulated function ChangeWeaponPattern(UIList _list, int itemIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_WeaponPatterns, 0, itemIndex);
}
// ------------------------------------------------------------------------
simulated function CustomizeFacePaint()
{
	CustomizeManager.UpdateCamera();
	Movie.Pres.UICustomize_Trait(m_strFacePaint, "", CustomizeManager.GetCategoryList(eUICustomizeCat_FacePaint),
								 ChangeFacePaint, ChangeFacePaint, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_FacePaint));
}
simulated function ChangeFacePaint(UIList _list, int itemIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_FacePaint, 0, itemIndex);
}
// ------------------------------------------------------------------------
simulated function CustomizeLeftArmTattoos()
{
	CustomizeManager.UpdateCamera();
	Movie.Pres.UICustomize_Trait(m_strTattoosLeft, "", CustomizeManager.GetCategoryList(eUICustomizeCat_LeftArmTattoos),
		ChangeTattoosLeftArm, ChangeTattoosLeftArm, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_LeftArmTattoos));
}
simulated function ChangeTattoosLeftArm(UIList _list, int itemIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_LeftArmTattoos, 0, itemIndex);
}
// ------------------------------------------------------------------------
simulated function CustomizeRightArmTattoos()
{
	CustomizeManager.UpdateCamera();
	Movie.Pres.UICustomize_Trait(m_strTattoosRight, "", CustomizeManager.GetCategoryList(eUICustomizeCat_RightArmTattoos),
		ChangeTattoosRightArm, ChangeTattoosRightArm, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_RightArmTattoos));
}
simulated function ChangeTattoosRightArm(UIList _list, int itemIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_RightArmTattoos, 0, itemIndex);
}
// ------------------------------------------------------------------------
simulated function CustomizeScars()
{
	CustomizeManager.UpdateCamera();
	Movie.Pres.UICustomize_Trait(m_strScars, "", CustomizeManager.GetCategoryList(eUICustomizeCat_Scars),
		ChangeScars, ChangeScars, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_Scars));
}
simulated function ChangeScars(UIList _list, int itemIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_Scars, 0, itemIndex);
}
// --------------------------------------------------------------------------
simulated function CustomizeArms()
{
	CustomizeManager.UpdateCamera();
	Movie.Pres.UICustomize_Trait(m_strArms, "", CustomizeManager.GetCategoryList(eUICustomizeCat_Arms),
		ChangeArms, ChangeArms, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_Arms));
}
simulated function ChangeArms(UIList _list, int itemIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_Arms, 0, itemIndex);
}
// --------------------------------------------------------------------------
simulated function CustomizeTorso()
{
	CustomizeManager.UpdateCamera();
	Movie.Pres.UICustomize_Trait(m_strTorso, "", CustomizeManager.GetCategoryList(eUICustomizeCat_Torso),
		ChangeTorso, ChangeTorso, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_Torso));
}
simulated function ChangeTorso(UIList _list, int itemIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_Torso, 0, itemIndex);
}
// --------------------------------------------------------------------------
simulated function CustomizeLegs()
{
	CustomizeManager.UpdateCamera();
	Movie.Pres.UICustomize_Trait(m_strLegs, "", CustomizeManager.GetCategoryList(eUICustomizeCat_Legs),
		ChangeLegs, ChangeLegs, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_Legs)); 
}
simulated function ChangeLegs(UIList _list, int itemIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_Legs, 0, itemIndex);
}
// --------------------------------------------------------------------------
simulated function CustomizeUpperFaceProps()
{
	CustomizeManager.UpdateCamera();
	Movie.Pres.UICustomize_Trait(m_strUpperFaceProps, "", CustomizeManager.GetCategoryList(eUICustomizeCat_FaceDecorationUpper),
		ChangeFaceUpperProps, ChangeFaceUpperProps, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_FaceDecorationUpper));
}
simulated function ChangeFaceUpperProps(UIList _list, int itemIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_FaceDecorationUpper, 0, itemIndex);
}
// --------------------------------------------------------------------------
simulated function CustomizeLowerFaceProps()
{
	CustomizeManager.UpdateCamera();
	Movie.Pres.UICustomize_Trait(m_strLowerFaceProps, "", CustomizeManager.GetCategoryList(eUICustomizeCat_FaceDecorationLower),
		ChangeFaceLowerProps, ChangeFaceLowerProps, CanCycleTo, CustomizeManager.GetCategoryIndex(eUICustomizeCat_FaceDecorationLower));
}
simulated function ChangeFaceLowerProps(UIList _list, int itemIndex)
{
	CustomizeManager.OnCategoryValueChange(eUICustomizeCat_FaceDecorationLower, 0, itemIndex);
}
//==============================================================================
