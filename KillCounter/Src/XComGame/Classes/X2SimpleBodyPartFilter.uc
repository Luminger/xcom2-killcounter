//---------------------------------------------------------------------------------------
//  FILE:    X2BodyPartFilter.uc
//  AUTHOR:  Ned Way
//  PURPOSE: Unified way to sort body parts for all the systems that need that functionality
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2SimpleBodyPartFilter extends X2BodyPartFilter;

var private EGender Gender;
var private ECharacterRace Race;
var private X2BodyPartTemplate TorsoTemplate;
var private name ArmorName;
var private bool bCivilian;
var private bool bVeteran;

//Used for initial torso selection
var private name MatchCharacterTemplateForTorso;
var private name MatchArmorTemplateForTorso;

function Set(EGender inGender, ECharacterRace inRace, name inTorsoTemplateName, bool bIsCivilian = false, bool bIsVeteran = false)
{
	Gender = inGender;
	Race = inRace;
	bCivilian = bIsCivilian;
	bVeteran = bIsVeteran;

	if (inTorsoTemplateName != '')
	{
		TorsoTemplate = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager().FindUberTemplate("Torso", inTorsoTemplateName);
		ArmorName = TorsoTemplate.ArmorTemplate;
	}
	else
	{
		ArmorName = '';
	}
}

function SetTorsoSelection(name InMatchCharacterTemplateForTorso, name InMatchArmorTemplateForTorso)
{
	MatchCharacterTemplateForTorso = InMatchCharacterTemplateForTorso;
	MatchArmorTemplateForTorso = InMatchArmorTemplateForTorso;
}

function bool FilterAny( X2BodyPartTemplate Template )
{
	return true;
}

// Specialized filter method for building a character from scratch
function bool FilterTorso(X2BodyPartTemplate Template)
{
	return	FilterByGenderAndNonSpecialized(Template) &&
		    (Template.ArmorTemplate == MatchArmorTemplateForTorso || Template.CharacterTemplate == MatchCharacterTemplateForTorso);
}

function bool FilterByGender(X2BodyPartTemplate Template)
{
	return Template.Gender == eGender_None || Template.Gender == Gender;
}

function bool FilterByRace(X2BodyPartTemplate Template)
{
	return Template.Race == ECharacterRace(Race);
}

function bool FilterByNonSpecialized(X2BodyPartTemplate Template)
{
	return Template.SpecializedType == false && (!Template.bVeteran || bVeteran);
}

function bool FilterByCivilian(X2BodyPartTemplate Template)
{
	return !bCivilian || Template.bCanUseOnCivilian;
}

function bool FilterByTech(X2BodyPartTemplate Template)
{
	local X2TechTemplate TechTemplate;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local X2StrategyElementTemplateManager StratMgr;	
	
	//Automatically pass if no tech is specified
	if (Template.Tech != '')
	{
		//Fetch the tech required
		StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
		TechTemplate = X2TechTemplate(StratMgr.FindStrategyElementTemplate(Template.Tech));
		if (TechTemplate != none)
		{
			//See if it has been researched
			History = `XCOMHISTORY;
			XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom', true));
			if (XComHQ != none)
			{
				if (XComHQ.IsTechResearched(TechTemplate.DataName))
				{
					return true;
				}
				else
				{
					return false;
				}
			}
			else
			{
				return false; //No HQ, no tech and no body part allowed
			}
		}
	}
	
	return true;
}

function bool FilterByGenderAndRace(X2BodyPartTemplate Template)
{
	return	FilterByGender(Template) && FilterByRace(Template) && FilterByNonSpecialized(Template);
}

function bool FilterByGenderAndNonSpecialized(X2BodyPartTemplate Template)
{
	return FilterByGender(Template) && FilterByNonSpecialized(Template);
}

function bool FilterByGenderAndNonSpecializedCivilian(X2BodyPartTemplate Template)
{
	return FilterByGender(Template) && FilterByNonSpecialized(Template) && FilterByCivilian(Template);
}

function bool FilterByGenderAndNonSpecializedAndTech(X2BodyPartTemplate Template)
{
	return FilterByGender(Template) && FilterByNonSpecialized(Template) && FilterByTech(Template);
}

function bool FilterByTorsoAndArmorMatch(X2BodyPartTemplate Template)
{
	if (Template == None || TorsoTemplate == None)
		return false;

	return	FilterByGenderAndNonSpecialized(Template) &&
		(TorsoTemplate.bVeteran == Template.bVeteran) &&
		(TorsoTemplate.ArmorTemplate == Template.ArmorTemplate) &&
		(TorsoTemplate.CharacterTemplate == Template.CharacterTemplate);
}

function bool FilterByGenderAndArmor( X2BodyPartTemplate Template )
{
	//  Note: TorsoTemplate will always be none here, this is when we are SELECTING a torso
	//  As the function  name states, we only want to check gender and armor.

	if (Template == None || ArmorName == '')
		return false;

	return  (Template.Gender == Gender) &&
			(Template.ArmorTemplate == ArmorName);
}

function string DebugString_X2SimpleBodyPartFilter()
{
	return `ShowEnum(EGender, Gender, Gender) @ `ShowEnum(ECharacterRace, Race, Race) @ ((TorsoTemplate != None) ? `ShowVar(TorsoTemplate.ArchetypeName) : "TorsoTemplate == None") @ `ShowVar(ArmorName);
}