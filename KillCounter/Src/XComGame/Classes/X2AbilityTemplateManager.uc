//---------------------------------------------------------------------------------------
//  FILE:    X2AbilityTemplateManager.uc
//  AUTHOR:  Joshua Bouscher
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2AbilityTemplateManager extends X2DataTemplateManager
	native(Core) config(GameData);

var const config array<name> AbilityAvailabilityCodes;          //  values passed in code to determine why something is failing.
var localized array<string>  AbilityAvailabilityStrings;        //  user facing strings to describe the above codes. assumes the arrays line up exactly.
var const config array<name> EffectUpdatesOnMove;               //  names of effects to be updated on each tile change while a unit is moving.

var protected array<name> StandardMoveAbilityActionTypes;

//  Names for various abilities & effects that need to be accessed in native code.
var name BeingCarriedEffectName;
var name ConfusedName;
var name DisorientedName;
var name BoundName;
var name PanickedName;
var name StunnedName;
var name BurrowedName;

native static function X2AbilityTemplateManager GetAbilityTemplateManager();

static function string GetDisplayStringForAvailabilityCode(const name Code)
{
	local int Idx;

	Idx = default.AbilityAvailabilityCodes.Find(Code);
	if (Idx != INDEX_NONE)
	{
		if (Idx < default.AbilityAvailabilityStrings.Length)
			return default.AbilityAvailabilityStrings[Idx];

		`RedScreenOnce("AbilityAvailabilityCode" @ Code @ "is out of bounds for the list of corresponding display strings. -jbouscher @gameplay");
	}
	else
	{
		`RedScreenOnce("AbilityAvailabilityCode" @ Code @ "was not found to be valid! -jbouscher @gameplay");
	}

	return "";
}

function array<name> GetStandardMoveAbilityActionTypes()
{
	local X2AbilityTemplate MoveTemplate;
	local X2AbilityCost Cost;
	
	if (StandardMoveAbilityActionTypes.Length == 0)
	{
		MoveTemplate = FindAbilityTemplate('StandardMove');
		`assert(MoveTemplate != none);
		foreach MoveTemplate.AbilityCosts(Cost)
		{
			if (Cost.IsA('X2AbilityCost_ActionPoints'))
			{
				StandardMoveAbilityActionTypes = X2AbilityCost_ActionPoints(Cost).AllowedTypes;
				break;
			}
		}
	}
	return StandardMoveAbilityActionTypes;
}

function bool AddAbilityTemplate(X2AbilityTemplate Template, bool ReplaceDuplicate = false)
{
	return AddDataTemplate(Template, ReplaceDuplicate);
}

function X2AbilityTemplate FindAbilityTemplate(name DataName)
{
	local X2DataTemplate kTemplate;

	kTemplate = FindDataTemplate(DataName);
	if (kTemplate != none)
		return X2AbilityTemplate(kTemplate);
	return none;
}

DefaultProperties
{
	TemplateDefinitionClass=class'X2Ability';
	
	BeingCarriedEffectName="BeingCarried"
	ConfusedName="Confused"
	DisorientedName="Disoriented"
	BoundName="Bind"    // Changed this because animation had already named theirs as Bind
	PanickedName = "Panicked"
	StunnedName="Stunned"
	BurrowedName="Burrowed"
}