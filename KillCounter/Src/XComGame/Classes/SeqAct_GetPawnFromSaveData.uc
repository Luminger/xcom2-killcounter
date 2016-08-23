//---------------------------------------------------------------------------------------
//  FILE:    SeqAct_GetPawnFromSaveData.uc
//  AUTHOR:  Ryan McFall  --  8/24/2015
//  PURPOSE: Retrieves a unit from the player's most recent saved game to show on the main
//			 menu. In the absence of an appropriate unit, auto-generates one.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class SeqAct_GetPawnFromSaveData extends SequenceAction native(Level);

var() name SoldierVariableName;

event Activated()
{
	local XComGameState SearchState;
	local array<XComGameState_Unit> UnitStates;
	local XComGameState_Unit UnitState;
	local int MaxRand;
	local int RandomSelection;
	local Vector Location;
	local Rotator Rotation;
	local XComUnitPawn UnitPawn;

	local X2CharacterTemplateManager CharTemplateMgr;
	local X2CharacterTemplate CharacterTemplate;
	local XComGameState_Unit NewUnitState;
	local XComGameState_Item BuildItem;
	local XGCharacterGenerator CharGen;
	local TSoldier CharacterGeneratorResult;
	local X2EquipmentTemplate EquipmentTemplate;
	local X2ItemTemplateManager ItemTemplateManager;	
	local XComGameStateHistory History;
	local XComGameState AddToGameState;

	local array<SequenceVariable> OutVariables;
	local SequenceVariable SeqVar;
	local SeqVar_Object SeqVarPawn;
	local XComGameStateHistory TempHistory;

	local XComGameState_HeadquartersXCom XComHQ;
	local int CrewIndex;

	//See if there is a game state from the saved data we can use.
	SearchState = `XENGINE.LatestSaveState(TempHistory);
	if(SearchState != none)
	{
		foreach TempHistory.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
		{
			break;
		}
		
		if(XComHQ != none)
		{
			for(CrewIndex = 0; CrewIndex < XComHQ.Crew.Length; ++CrewIndex)
			{
				UnitState = XComGameState_Unit(TempHistory.GetGameStateForObjectID(XComHQ.Crew[CrewIndex].ObjectID));
				if(UnitState.IsASoldier() && UnitState.IsAlive()) //Only soldiers... that are alive
				{
					//We can only instance characters who's weapons are in SearchState. If the most recent saved game is from a tactical battle then
					//that will limit the list of units to the units in the battle.
					BuildItem = UnitState.GetItemInSlot(eInvSlot_PrimaryWeapon, SearchState);
					if(BuildItem != none)
					{
						UnitStates.AddItem(UnitState);
					}
				}
			}
		}
		else
		{
			foreach SearchState.IterateByClassType(class'XComGameState_Unit', UnitState)
			{
				if(UnitState.IsASoldier() && UnitState.IsAlive()) //Only soldiers... that are alive
				{
					UnitStates.AddItem(UnitState);
				}
			}
		}
	}
	
	if(UnitStates.Length > 1)
	{
		UnitStates.Sort(SortByKills);
		MaxRand = Min(UnitStates.Length, 4); //Pick randomly from the top 4
		RandomSelection = `SYNC_RAND(MaxRand);
		UnitState = UnitStates[RandomSelection];
		UnitPawn = UnitState.CreatePawn(none, Location, Rotation);
		UnitPawn.CreateVisualInventoryAttachments(none, UnitState, SearchState, true);
	}
	else
	{
		History = `XCOMHISTORY;

		AddToGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("TempGameState");

		CharTemplateMgr = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
		`assert(CharTemplateMgr != none);
		CharacterTemplate = CharTemplateMgr.FindCharacterTemplate('Soldier');
		`assert(CharacterTemplate != none);

		//Make the unit from a template
		//*************************
		NewUnitState = CharacterTemplate.CreateInstanceFromTemplate(AddToGameState);

		//Fill in the unit's stats and appearance
		NewUnitState.RandomizeStats();
		CharGen = XComGameInfo(class'Engine'.static.GetCurrentWorldInfo().Game).m_CharacterGen;
		CharacterGeneratorResult = CharGen.CreateTSoldier('Soldier');
		NewUnitState.SetTAppearance(CharacterGeneratorResult.kAppearance);
		NewUnitState.SetCharacterName(CharacterGeneratorResult.strFirstName, CharacterGeneratorResult.strLastName, CharacterGeneratorResult.strNickName);
		NewUnitState.SetCountry(CharacterGeneratorResult.nmCountry);

		AddToGameState.AddStateObject(NewUnitState);
		//*************************

		//If we added a soldier, give the soldier default items. Eventually we will want to be pulling items from the armory...
		//***************		
		ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

		EquipmentTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate('KevlarArmor'));
		BuildItem = EquipmentTemplate.CreateInstanceFromTemplate(AddToGameState);
		BuildItem.ItemLocation = eSlot_None;
		NewUnitState.AddItemToInventory(BuildItem, eInvSlot_Armor, AddToGameState);
		AddToGameState.AddStateObject(BuildItem);

		EquipmentTemplate = X2EquipmentTemplate(ItemTemplateManager.FindItemTemplate('AssaultRifle_CV'));
		BuildItem = EquipmentTemplate.CreateInstanceFromTemplate(AddToGameState);
		BuildItem.ItemLocation = eSlot_RightHand;
		NewUnitState.AddItemToInventory(BuildItem, eInvSlot_PrimaryWeapon, AddToGameState);
		AddToGameState.AddStateObject(BuildItem);	

		UnitPawn = NewUnitState.CreatePawn(none, Location, Rotation);
		UnitState = NewUnitState;

		UnitPawn.CreateVisualInventoryAttachments(none, UnitState, AddToGameState, true);

		History.CleanupPendingGameState(AddToGameState);
		//***************
	}

	if(UnitPawn != none)
	{		
		UnitPawn.ObjectID = -1;
		UnitPawn.SetVisible(true);
		UnitPawn.SetupForMatinee(none, true, false);
		UnitPawn.StopTurning();
		UnitPawn.UpdateAnimations();

		UnitPawn.WorldInfo.MyKismetVariableMgr.RebuildVariableMap();
		UnitPawn.WorldInfo.MyKismetVariableMgr.GetVariable(SoldierVariableName, OutVariables);
		foreach OutVariables(SeqVar)
		{
			SeqVarPawn = SeqVar_Object(SeqVar);
			if(SeqVarPawn != none)
			{
				SeqVarPawn.SetObjectValue(None);
				SeqVarPawn.SetObjectValue(UnitPawn);
			}
		}
	}
}

private static function int SortByKills(XComGameState_Unit UnitA, XComGameState_Unit UnitB)
{
	if(UnitA.GetNumKills() > UnitB.GetNumKills())
	{
		return 1;
	}
	else if(UnitA.GetNumKills() < UnitB.GetNumKills())
	{
		return -1;
	}
	return 0;
}

defaultproperties
{
	ObjName="Get Pawn From Save Data"
	ObjCategory="Kismet"
	bCallHandler=false
}
