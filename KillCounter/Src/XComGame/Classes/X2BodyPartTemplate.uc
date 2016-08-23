//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    X2BodyPartTemplate.uc
//  AUTHOR:  Timothy Talley  --  11/04/2013
//---------------------------------------------------------------------------------------
//  Copyright (c) 2013 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class X2BodyPartTemplate extends X2DataTemplate
	native(Core);

var() string PartType;

var () EGender Gender;
var () ECharacterRace Race;
var () string ArchetypeName;
var () bool SpecializedType;

// Body template
var () ECivilianType Type;

// Hair template
var () bool bCanUseOnCivilian;
var () bool bIsHelmet;

// Armor
var bool bVeteran;
var name ArmorTemplate;

// Character
var name CharacterTemplate; //If ArmorTemplate is specified, the current assumption is that CharacterTemplate is 'soldier'. Otherwise this is used

// Language - needed because "Voice" is a body part too, and voices are determined by language spoken.  mdomowicz 2015_06_09
var name Language;

// Required tech for this body part to be available
var name Tech;

// Localized text displayed in customization screen
var localized string DisplayName;
