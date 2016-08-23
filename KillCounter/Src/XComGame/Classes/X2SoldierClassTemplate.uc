//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    X2SoldierClassTemplate.uc
//  AUTHOR:  Timothy Talley  --  01/18/2014
//---------------------------------------------------------------------------------------
//  Copyright (c) 2014 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class X2SoldierClassTemplate extends X2DataTemplate
	dependson(X2TacticalGameRulesetDataStructures)
	config(ClassData)
	native(Core);

var config protected array<SoldierClassRank> SoldierRanks;
var config array<SoldierClassWeaponType>    AllowedWeapons;
var config name					SquaddieLoadout;
var config string				IconImage;
var config int					NumInForcedDeck;
var config int					NumInDeck;
var config int					ClassPoints;    // Number of "points" associated with using this class type, i.e. Multiplayer or Daily Challenge
var config int                  KillAssistsPerKill;     //  Number of kill assists that count as a kill for ranking up
var config int                  PsiCreditsPerKill;      //  Number of psi credits that count as a kill for ranking up
var config protectedwrite bool  bMultiplayerOnly; 

var localized string			DisplayName;
var localized string			ClassSummary;
var localized string			LeftAbilityTreeTitle;
var localized string			RightAbilityTreeTitle;
var localized array<String>     RandomNickNames;        //  Selected randomly when the soldier hits a certain rank, if the player has not set one already.
var localized array<String>     RandomNickNames_Female; //  Female only nicknames.
var localized array<String>     RandomNickNames_Male;   //  Male only nicknames.

function name GetAbilityName(int iRank, int iBranch)
{
	if (iRank < 0 && iRank >= SoldierRanks.Length)
		return '';

	if (iBranch < 0 && iBranch >= SoldierRanks[iRank].aAbilityTree.Length)
		return '';

	return SoldierRanks[iRank].aAbilityTree[iBranch].AbilityName;
}

function int GetMaxConfiguredRank()
{
	return SoldierRanks.Length;
}

function array<SoldierClassAbilityType> GetAbilityTree(int Rank)
{
	if (Rank < 0 || Rank > SoldierRanks.Length)
	{
		`RedScreen(string(GetFuncName()) @ "called with invalid Rank" @ Rank @ "for template" @ DataName @ DisplayName);
		return SoldierRanks[0].aAbilityTree;
	}
	return SoldierRanks[Rank].aAbilityTree;
}

function array<SoldierClassStatType> GetStatProgression(int Rank)
{
	if (Rank < 0 || Rank > SoldierRanks.Length)
	{
		`RedScreen(string(GetFuncName()) @ "called with invalid Rank" @ Rank @ "for template" @ DataName @ DisplayName);
		return SoldierRanks[0].aStatProgression;
	}
	return SoldierRanks[Rank].aStatProgression;
}

function SCATProgression GetSCATProgressionForAbility(name AbilityName)
{
	local SCATProgression Progression;
	local int rankIdx, branchIdx;

	for (rankIdx = 0; rankIdx < SoldierRanks.Length; ++rankIdx)
	{
		for (branchIdx = 0; branchIdx < SoldierRanks[rankIdx].aAbilityTree.Length; ++branchIdx)
		{
			if (SoldierRanks[rankIdx].aAbilityTree[branchIdx].AbilityName == AbilityName)
			{
				Progression.iRank = rankIdx;
				Progression.iBranch = branchIdx;
				return Progression;
			}
		}
	}

	return Progression;
}

function bool IsWeaponAllowedByClass(X2WeaponTemplate WeaponTemplate)
{
	local int i;

	switch(WeaponTemplate.InventorySlot)
	{
	case eInvSlot_PrimaryWeapon: break;
	case eInvSlot_SecondaryWeapon: break;
	default:
		return true;
	}

	for (i = 0; i < AllowedWeapons.Length; ++i)
	{
		if (WeaponTemplate.InventorySlot == AllowedWeapons[i].SlotType &&
			WeaponTemplate.WeaponCat == AllowedWeapons[i].WeaponType)
			return true;
	}
	return false;
}

function string X2SoldierClassTemplate_ToString()
{
	local string str;
	local int rankIdx, subIdx;

	str = " X2SoldierClassTemplate:" @ `ShowVar(DataName) @ `ShowVar(SoldierRanks.Length, 'Num Ranks') @ `ShowVar(SquaddieLoadout) @ `ShowVar(AllowedWeapons.Length, 'Weapons') $ "\n";
	for(subIdx = 0; subIdx < AllowedWeapons.Length; ++subIdx)
	{
		str $= "        Weapon Type(" $ subIdx $ ") - " $ `ShowVar(AllowedWeapons[subIdx].WeaponType, 'Weapon Type') @ `ShowVar(AllowedWeapons[subIdx].SlotType, 'Slot Type') $ "\n";
	}
	for(rankIdx = 0; rankIdx < SoldierRanks.Length; ++rankIdx)
	{
		str $= "    Rank(" $ rankIdx $ ") - " $ `ShowVar(SoldierRanks[rankIdx].aAbilityTree.Length, 'Abilities') @ `ShowVar(SoldierRanks[rankIdx].aStatProgression.Length, 'StatProgressions') $ "\n";
		for(subIdx = 0; subIdx < SoldierRanks[rankIdx].aAbilityTree.Length; ++subIdx)
		{
			str $= "        Ability(" $ subIdx $ ") - " $ `ShowVar(SoldierRanks[rankIdx].aAbilityTree[subIdx].AbilityName, 'Ability Name') $ "\n";
		}
		for(subIdx = 0; subIdx < SoldierRanks[rankIdx].aStatProgression.Length; ++subIdx)
		{
			str $= "        Stat Progression(" $ subIdx $ ") - " $ `ShowVar(SoldierRanks[rankIdx].aStatProgression[subIdx].StatType, 'Stat Type') @ `ShowVar(SoldierRanks[rankIdx].aStatProgression[subIdx].StatAmount, 'Stat Amount') $ "\n";
		}
	}
	return str;
}

function int GetPointValue()
{
	return ClassPoints;
}

defaultproperties
{
	bShouldCreateDifficultyVariants = true
}