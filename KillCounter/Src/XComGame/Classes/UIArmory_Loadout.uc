//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIArmory_Loadout
//  AUTHOR:  Sam Batista
//  PURPOSE: UI for viewing and modifying a Soldiers equipment
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIArmory_Loadout extends UIArmory;

struct TUILockerItem
{
	var bool CanBeEquipped;
	var string DisabledReason;
	var XComGameState_Item Item;
};

var UIList ActiveList;

var UIPanel EquippedListContainer;
var UIList EquippedList;

var UIPanel LockerListContainer;
var UIList LockerList;

var UIArmory_LoadoutItemTooltip InfoTooltip;

var localized string m_strInventoryTitle;
var localized string m_strLockerTitle;
var localized string m_strInventoryLabels[EInventorySlot.EnumCount]<BoundEnum=EInventorySlot>;
var localized string m_strNeedsSoldierClass;
var localized string m_strUnavailableToClass;
var localized string m_strAmmoIncompatible;
var localized string m_strCategoryRestricted;
var localized string m_strMissingAllowedClass;
var localized string m_strTooltipStripItems;
var localized string m_strTooltipStripItemsDisabled;
var localized string m_strTooltipStripGear;
var localized string m_strTooltipStripGearDisabled;

var XGParamTag LocTag; // optimization
var bool bGearStripped;
var bool bItemsStripped;
var array<StateObjectReference> StrippedUnits;
var bool bTutorialJumpOut;

simulated function InitArmory(StateObjectReference UnitRef, optional name DispEvent, optional name SoldSpawnEvent, optional name NavBackEvent, optional name HideEvent, optional name RemoveEvent, optional bool bInstant = false, optional XComGameState InitCheckGameState)
{
	super.InitArmory(UnitRef, DispEvent, SoldSpawnEvent, NavBackEvent, HideEvent, RemoveEvent, bInstant, InitCheckGameState);

	LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));

	InitializeTooltipData();
	InfoTooltip.SetPosition(1250, 430);

	MC.FunctionString("setLeftPanelTitle", m_strInventoryTitle);

	EquippedListContainer = Spawn(class'UIPanel', self);
	EquippedListContainer.bAnimateOnInit = false;
	EquippedListContainer.InitPanel('leftPanel');
	EquippedList = CreateList(EquippedListContainer);
	EquippedList.OnItemClicked = OnItemClicked;
	EquippedList.OnItemDoubleClicked = OnItemClicked;

	LockerListContainer = Spawn(class'UIPanel', self);
	LockerListContainer.bAnimateOnInit = false;
	LockerListContainer.InitPanel('rightPanel');
	LockerList = CreateList(LockerListContainer);
	LockerList.OnSelectionChanged = OnSelectionChanged;
	LockerList.OnItemClicked = OnItemClicked;
	LockerList.OnItemDoubleClicked = OnItemClicked;

	PopulateData();
}

simulated function PopulateData()
{
	CreateSoldierPawn();
	UpdateEquippedList();
	UpdateLockerList();
	ChangeActiveList(EquippedList, true);
}

simulated function UpdateNavHelp()
{
	super.UpdateNavHelp();
	if(bUseNavHelp && XComHQPresentationLayer(Movie.Pres) != none)
	{
		if(bItemsStripped)
		{
			NavHelp.AddRightHelp(class'UISquadSelect'.default.m_strStripItems, "", none, true, m_strTooltipStripItemsDisabled, class'UIUtilities'.const.ANCHOR_BOTTOM_CENTER);
		}
		else
		{
			NavHelp.AddRightHelp(class'UISquadSelect'.default.m_strStripItems, "", OnStripItems, false, m_strTooltipStripItems, class'UIUtilities'.const.ANCHOR_BOTTOM_CENTER);
		}

		if(bGearStripped)
		{
			NavHelp.AddRightHelp(class'UISquadSelect'.default.m_strStripGear, "", none, true, m_strTooltipStripGearDisabled, class'UIUtilities'.const.ANCHOR_BOTTOM_CENTER);
		}
		else
		{
			NavHelp.AddRightHelp(class'UISquadSelect'.default.m_strStripGear, "", OnStripGear, false, m_strTooltipStripGear, class'UIUtilities'.const.ANCHOR_BOTTOM_CENTER);
		}
	}
}

simulated function OnStripItems()
{
	local TDialogueBoxData DialogData;
	DialogData.eType = eDialog_Normal;
	DialogData.strTitle = class'UISquadSelect'.default.m_strStripItemsConfirm;
	DialogData.strText = class'UISquadSelect'.default.m_strStripItemsConfirmDesc;
	DialogData.fnCallback = OnStripItemsDialogCallback;
	DialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;
	DialogData.strCancel = class'UIDialogueBox'.default.m_strDefaultCancelLabel;
	Movie.Pres.UIRaiseDialog(DialogData);
}
simulated function OnStripItemsDialogCallback(eUIAction eAction)
{
	local XComGameState_Unit UnitState;
	local array<EInventorySlot> RelevantSlots;
	local array<XComGameState_Unit> Soldiers;
	local XComGameState NewGameState;
	local int idx;

	if(eAction == eUIAction_Accept)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Strip Gear");
		Soldiers = GetSoldiersToStrip();

		RelevantSlots.AddItem(eInvSlot_Utility);
		RelevantSlots.AddItem(eInvSlot_GrenadePocket);
		RelevantSlots.AddItem(eInvSlot_AmmoPocket);

		for(idx = 0; idx < Soldiers.Length; idx++)
		{
			UnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', Soldiers[idx].ObjectID));
			NewGameState.AddStateObject(UnitState);
			UnitState.MakeItemsAvailable(NewGameState, true, RelevantSlots);
			
			if(StrippedUnits.Find('ObjectID', UnitState.ObjectID) == INDEX_NONE)
			{
				StrippedUnits.AddItem(UnitState.GetReference());
			}
		}

		`GAMERULES.SubmitGameState(NewGameState);

		bItemsStripped = true;
		UpdateNavHelp();
		UpdateLockerList();
	}
}

simulated function OnStripGear()
{
	local TDialogueBoxData DialogData;
	DialogData.eType = eDialog_Normal;
	DialogData.strTitle = class'UISquadSelect'.default.m_strStripGearConfirm;
	DialogData.strText = class'UISquadSelect'.default.m_strStripGearConfirmDesc;
	DialogData.fnCallback = OnStripGearDialogCallback;
	DialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;
	DialogData.strCancel = class'UIDialogueBox'.default.m_strDefaultCancelLabel;
	Movie.Pres.UIRaiseDialog(DialogData);
}
simulated function OnStripGearDialogCallback(eUIAction eAction)
{
	local XComGameState_Unit UnitState;
	local array<EInventorySlot> RelevantSlots;
	local array<XComGameState_Unit> Soldiers;
	local XComGameState NewGameState;
	local int idx;

	if(eAction == eUIAction_Accept)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Strip Gear");
		Soldiers = GetSoldiersToStrip();

		RelevantSlots.AddItem(eInvSlot_Armor);
		RelevantSlots.AddItem(eInvSlot_HeavyWeapon);

		for(idx = 0; idx < Soldiers.Length; idx++)
		{
			UnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', Soldiers[idx].ObjectID));
			NewGameState.AddStateObject(UnitState);
			UnitState.MakeItemsAvailable(NewGameState, true, RelevantSlots);

			if(StrippedUnits.Find('ObjectID', UnitState.ObjectID) == INDEX_NONE)
			{
				StrippedUnits.AddItem(UnitState.GetReference());
			}
		}

		`GAMERULES.SubmitGameState(NewGameState);

		bGearStripped = true;
		UpdateNavHelp();
		UpdateLockerList();
	}
}

simulated function ResetAvailableEquipment()
{
	local XComGameState_Unit UnitState;
	local XComGameState NewGameState;
	local int idx;

	bGearStripped = false;
	bItemsStripped = false;

	if(StrippedUnits.Length > 0)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Reset Available Equipment");

		for(idx = 0; idx < StrippedUnits.Length; idx++)
		{
			UnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', StrippedUnits[idx].ObjectID));
			NewGameState.AddStateObject(UnitState);
			UnitState.EquipOldItems(NewGameState);
		}

		`GAMERULES.SubmitGameState(NewGameState);
	}

	StrippedUnits.Length = 0;
	UpdateNavHelp();
	UpdateLockerList();
}

simulated static function CycleToSoldier(StateObjectReference NewRef)
{
	local UIArmory_Loadout LoadoutScreen;
	local UIScreenStack ScreenStack;

	ScreenStack = `SCREENSTACK;
	LoadoutScreen = UIArmory_Loadout(ScreenStack.GetScreen(class'UIArmory_Loadout'));

	if(LoadoutScreen != none)
	{
		LoadoutScreen.ResetAvailableEquipment();
	}
	
	super.CycleToSoldier(NewRef);
}

simulated function array<XComGameState_Unit> GetSoldiersToStrip()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local array<XComGameState_Unit> Soldiers;
	local XComGameState_Unit UnitState;
	local int idx;

	History = `XCOMHISTORY;

	if(StrippedUnits.Length > 0)
	{
		for(idx = 0; idx < StrippedUnits.Length; idx++)
		{
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(StrippedUnits[idx].ObjectID));
			Soldiers.AddItem(UnitState);
		}
	}
	else
	{
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		Soldiers = XComHQ.GetSoldiers();

		for(idx = 0; idx < Soldiers.Length; idx++)
		{
			if(Soldiers[idx].ObjectID == GetUnitRef().ObjectID)
			{
				Soldiers.Remove(idx, 1);
				break;
			}
		}
	}

	return Soldiers;
}

simulated function LoadSoldierEquipment()
{
	XComUnitPawn(ActorPawn).CreateVisualInventoryAttachments(Movie.Pres.GetUIPawnMgr(), GetUnit(), CheckGameState);	
}

// also gets used by UIWeaponList, and UIArmory_WeaponUpgrade
simulated static function UIList CreateList(UIPanel Container)
{
	local UIBGBox BG;
	local UIList ReturnList;

	BG = Container.Spawn(class'UIBGBox', Container).InitBG('BG');

	ReturnList = Container.Spawn(class'UIList', Container);
	ReturnList.bStickyHighlight = false;
	ReturnList.bAutosizeItems = false;
	ReturnList.bAnimateOnInit = false;
	ReturnList.bSelectFirstAvailable = false;
	ReturnList.ItemPadding = 5;
	ReturnList.InitList('loadoutList');

	// this allows us to send mouse scroll events to the list
	BG.ProcessMouseEvents(ReturnList.OnChildMouseEvent);
	return ReturnList;
}

simulated function UpdateEquippedList()
{
	local int i, numUtilityItems;
	local UIArmory_LoadoutItem Item;
	local array<XComGameState_Item> UtilityItems;
	local XComGameState_Unit UpdatedUnit;

	UpdatedUnit = GetUnit();
	EquippedList.ClearItems();

	// Clear out tooltips from removed list items
	Movie.Pres.m_kTooltipMgr.RemoveTooltipsByPartialPath(string(EquippedList.MCPath));

	// units can only have one item equipped in the slots bellow
	Item = UIArmory_LoadoutItem(EquippedList.CreateItem(class'UIArmory_LoadoutItem'));
	Item.InitLoadoutItem(GetEquippedItem(eInvSlot_Armor), eInvSlot_Armor, true);

	Item = UIArmory_LoadoutItem(EquippedList.CreateItem(class'UIArmory_LoadoutItem'));
	Item.InitLoadoutItem(GetEquippedItem(eInvSlot_PrimaryWeapon), eInvSlot_PrimaryWeapon, true);

	// don't show secondary weapon slot on rookies
	if(UpdatedUnit.GetRank() > 0)
	{
		Item = UIArmory_LoadoutItem(EquippedList.CreateItem(class'UIArmory_LoadoutItem'));
		Item.InitLoadoutItem(GetEquippedItem(eInvSlot_SecondaryWeapon), eInvSlot_SecondaryWeapon, true);
	}
	if (UpdatedUnit.HasHeavyWeapon(CheckGameState))
	{
		Item = UIArmory_LoadoutItem(EquippedList.CreateItem(class'UIArmory_LoadoutItem'));
		Item.InitLoadoutItem(GetEquippedItem(eInvSlot_HeavyWeapon), eInvSlot_HeavyWeapon, true);
	}

	// units can have multiple utility items
	numUtilityItems = GetNumAllowedUtilityItems();
	UtilityItems = class'UIUtilities_Strategy'.static.GetEquippedUtilityItems(UpdatedUnit, CheckGameState);
	
	for(i = 0; i < numUtilityItems; ++i)
	{
		Item = UIArmory_LoadoutItem(EquippedList.CreateItem(class'UIArmory_LoadoutItem'));

		if(UtilityItems.Length >= (i + 1))
		{
			Item.InitLoadoutItem(UtilityItems[i], eInvSlot_Utility, true);
		}
		else
		{
			Item.InitLoadoutItem(none, eInvSlot_Utility, true);
		}
	}

	if (UpdatedUnit.HasGrenadePocket())
	{
		Item = UIArmory_LoadoutItem(EquippedList.CreateItem(class'UIArmory_LoadoutItem'));
		Item.InitLoadoutItem(GetEquippedItem(eInvSlot_GrenadePocket), eInvSlot_GrenadePocket, true);
	}
	if (UpdatedUnit.HasAmmoPocket())
	{
		Item = UIArmory_LoadoutItem(EquippedList.CreateItem(class'UIArmory_LoadoutItem'));
		Item.InitLoadoutItem(GetEquippedItem(eInvSlot_AmmoPocket), eInvSlot_AmmoPocket, true);
	}
}

function int GetNumAllowedUtilityItems()
{
	// units can have multiple utility items
	return GetUnit().GetCurrentStat(eStat_UtilityItems);
}

simulated function UpdateLockerList()
{
	local XComGameState_Item Item;
	local StateObjectReference ItemRef;
	local EInventorySlot SelectedSlot;
	local array<TUILockerItem> LockerItems;
	local TUILockerItem LockerItem;
	local array<StateObjectReference> Inventory;

	SelectedSlot = GetSelectedSlot();

	// set title according to selected slot
	LocTag.StrValue0 = m_strInventoryLabels[SelectedSlot];
	MC.FunctionString("setRightPanelTitle", `XEXPAND.ExpandString(m_strLockerTitle));

	GetInventory(Inventory);
	foreach Inventory(ItemRef)
	{
		Item = GetItemFromHistory(ItemRef.ObjectID);
		if(ShowInLockerList(Item, SelectedSlot))
		{
			LockerItem.Item = Item;
			LockerItem.DisabledReason = GetDisabledReason(Item, SelectedSlot);
			LockerItem.CanBeEquipped = LockerItem.DisabledReason == ""; // sorting optimization
			LockerItems.AddItem(LockerItem);
		}
	}

	LockerList.ClearItems();

	LockerItems.Sort(SortLockerListByUpgrades);
	LockerItems.Sort(SortLockerListByTier);
	LockerItems.Sort(SortLockerListByEquip);

	foreach LockerItems(LockerItem)
	{
		UIArmory_LoadoutItem(LockerList.CreateItem(class'UIArmory_LoadoutItem')).InitLoadoutItem(LockerItem.Item, SelectedSlot, false, LockerItem.DisabledReason);
	}
}

function GetInventory(out array<StateObjectReference> Inventory)
{
	Inventory = class'UIUtilities_Strategy'.static.GetXComHQ().Inventory;
}

simulated function bool ShowInLockerList(XComGameState_Item Item, EInventorySlot SelectedSlot)
{
	local X2ItemTemplate ItemTemplate;
	local X2GrenadeTemplate GrenadeTemplate;
	local X2EquipmentTemplate EquipmentTemplate;

	ItemTemplate = Item.GetMyTemplate();
	
	if(MeetsAllStrategyRequirements(ItemTemplate.ArmoryDisplayRequirements) && MeetsDisplayRequirement(ItemTemplate))
	{
		switch(SelectedSlot)
		{
		case eInvSlot_GrenadePocket:
			GrenadeTemplate = X2GrenadeTemplate(ItemTemplate);
			return GrenadeTemplate != none;
		case eInvSlot_AmmoPocket:
			return ItemTemplate.ItemCat == 'ammo';
		default:
			EquipmentTemplate = X2EquipmentTemplate(ItemTemplate);
			// xpad is only item with size 0, that is always equipped
			return (EquipmentTemplate != none && EquipmentTemplate.iItemSize > 0 && EquipmentTemplate.InventorySlot == SelectedSlot);
		}
	}

	return false;
}

// overriden in MP specific classes -tsmith
function bool MeetsAllStrategyRequirements(StrategyRequirement Requirement)
{
	return (class'UIUtilities_Strategy'.static.GetXComHQ().MeetsAllStrategyRequirements(Requirement));
}

// overriden in MP specific classes
function bool MeetsDisplayRequirement(X2ItemTemplate ItemTemplate)
{
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();

	return (!XComHQ.IsTechResearched(ItemTemplate.HideIfResearched));
}

simulated function string GetDisabledReason(XComGameState_Item Item, EInventorySlot SelectedSlot)
{
	local int EquippedObjectID;
	local string DisabledReason;
	local X2ItemTemplate ItemTemplate;
	local X2AmmoTemplate AmmoTemplate;
	local X2WeaponTemplate WeaponTemplate;
	local X2SoldierClassTemplate SoldierClassTemplate, AllowedSoldierClassTemplate;
	local XComGameState_Unit UpdatedUnit;

	ItemTemplate = Item.GetMyTemplate();
	UpdatedUnit = GetUnit();

	// Disable the weapon cannot be equipped by the current soldier class
	WeaponTemplate = X2WeaponTemplate(ItemTemplate);
	if(WeaponTemplate != none)
	{
		SoldierClassTemplate = UpdatedUnit.GetSoldierClassTemplate();
		if(SoldierClassTemplate != none && !SoldierClassTemplate.IsWeaponAllowedByClass(WeaponTemplate))
		{
			AllowedSoldierClassTemplate = class'UIUtilities_Strategy'.static.GetAllowedClassForWeapon(WeaponTemplate);
			if(AllowedSoldierClassTemplate == none)
			{
				DisabledReason = m_strMissingAllowedClass;
			}
			else if(AllowedSoldierClassTemplate.DataName == class'X2SoldierClassTemplateManager'.default.DefaultSoldierClass)
			{
				LocTag.StrValue0 = SoldierClassTemplate.DisplayName;
				DisabledReason = class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(`XEXPAND.ExpandString(m_strUnavailableToClass));
			}
			else
			{
				LocTag.StrValue0 = AllowedSoldierClassTemplate.DisplayName;
				DisabledReason = class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(`XEXPAND.ExpandString(m_strNeedsSoldierClass));
			}
		}
	}

	// Disable if the ammo is incompatible with the current primary weapon
	AmmoTemplate = X2AmmoTemplate(ItemTemplate);
	if(AmmoTemplate != none)
	{
		WeaponTemplate = X2WeaponTemplate(UpdatedUnit.GetItemInSlot(eInvSlot_PrimaryWeapon, CheckGameState).GetMyTemplate());
		if (WeaponTemplate != none && !X2AmmoTemplate(ItemTemplate).IsWeaponValidForAmmo(WeaponTemplate))
		{
			LocTag.StrValue0 = UpdatedUnit.GetPrimaryWeapon().GetMyTemplate().GetItemFriendlyName();
			DisabledReason = class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(`XEXPAND.ExpandString(m_strAmmoIncompatible));
		}
	}

	// If this is a utility item, and cannot be equipped, it must be disabled because of one item per category restriction
	if(DisabledReason == "" && SelectedSlot == eInvSlot_Utility)
	{
		EquippedObjectID = UIArmory_LoadoutItem(EquippedList.GetSelectedItem()).ItemRef.ObjectID;
		if(!UpdatedUnit.RespectsUniqueRule(ItemTemplate, SelectedSlot, , EquippedObjectID))
		{
			LocTag.StrValue0 = ItemTemplate.GetLocalizedCategory();
			DisabledReason = class'UIUtilities_Text'.static.CapsCheckForGermanScharfesS(`XEXPAND.ExpandString(m_strCategoryRestricted));
		}
	}
	
	return DisabledReason;
}

simulated function int SortLockerListByEquip(TUILockerItem A, TUILockerItem B)
{
	if(A.CanBeEquipped && !B.CanBeEquipped) return 1;
	else if(!A.CanBeEquipped && B.CanBeEquipped) return -1;
	else return 0;
}

simulated function int SortLockerListByTier(TUILockerItem A, TUILockerItem B)
{
	local int TierA, TierB;

	TierA = A.Item.GetMyTemplate().Tier;
	TierB = B.Item.GetMyTemplate().Tier;

	if (TierA > TierB) return 1;
	else if (TierA < TierB) return -1;
	else return 0;
}

simulated function int SortLockerListByUpgrades(TUILockerItem A, TUILockerItem B)
{
	local int UpgradesA, UpgradesB;

	UpgradesA = A.Item.GetMyWeaponUpgradeTemplates().Length;
	UpgradesB = B.Item.GetMyWeaponUpgradeTemplates().Length;

	if (UpgradesA > UpgradesB)
	{
		return 1;
	}
	else if (UpgradesA < UpgradesB)
	{
		return -1;
	}
	else
	{
		return 0;
	}
}

simulated function ChangeActiveList(UIList kActiveList, optional bool bSkipAnimation)
{
	ActiveList = kActiveList;
	
	if(kActiveList == EquippedList)
	{
		if(!bSkipAnimation)
			MC.FunctionVoid("closeList");

		// unlock selected item
		UIArmory_LoadoutItem(EquippedList.GetSelectedItem()).SetLocked(false);
		// disable list item selection on LockerList, enable it on EquippedList
		LockerListContainer.DisableMouseHit();
		EquippedListContainer.EnableMouseHit();

		Header.PopulateData(GetUnit());
		Navigator.RemoveControl(LockerListContainer);
		Navigator.AddControl(EquippedListContainer);
	}
	else
	{
		if(!bSkipAnimation)
			MC.FunctionVoid("openList");
		
		// lock selected item
		UIArmory_LoadoutItem(EquippedList.GetSelectedItem()).SetLocked(true);
		// disable list item selection on LockerList, enable it on EquippedList
		LockerListContainer.EnableMouseHit();
		EquippedListContainer.DisableMouseHit();

		LockerList.SetSelectedIndex(0, true);
		Navigator.RemoveControl(EquippedListContainer);
		Navigator.AddControl(LockerListContainer);
	}
}

simulated function OnSelectionChanged(UIList ContainerList, int ItemIndex)
{
	local StateObjectReference ItemRef;
	local XComGameState_Item Item; 

	ItemRef = UIArmory_LoadoutItem(ContainerList.GetSelectedItem()).ItemRef;
	Item = GetItemFromHistory(ItemRef.ObjectID);

	if(!UIArmory_LoadoutItem(ContainerList.GetItem(ItemIndex)).IsDisabled)
		Header.PopulateData(GetUnit(), Item.GetReference(), UIArmory_LoadoutItem(EquippedList.GetSelectedItem()).ItemRef);
}

simulated function OnAccept()
{
	if (ActiveList.SelectedIndex == -1)
		return;

	OnItemClicked(ActiveList, ActiveList.SelectedIndex);
}

simulated function OnItemClicked(UIList ContainerList, int ItemIndex)
{
	if(ContainerList != ActiveList) return;

	if(UIArmory_LoadoutItem(ContainerList.GetItem(ItemIndex)).IsDisabled)
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClickNegative);
		return;
	}

	if(ContainerList == EquippedList)
	{
		UpdateLockerList();
		ChangeActiveList(LockerList);
	}
	else
	{
		ChangeActiveList(EquippedList);

		if(EquipItem(UIArmory_LoadoutItem(LockerList.GetSelectedItem())))
		{
			// Release soldier pawn to force it to be re-created when armor changes
			UpdateData(GetSelectedSlot() == eInvSlot_Armor);

			if(bTutorialJumpOut && Movie.Pres.ScreenStack.HasInstanceOf(class'UISquadSelect'))
			{
				OnCancel();
			}
		}
	}
}

simulated function UpdateData(optional bool bRefreshPawn)
{
	local Rotator CachedSoldierRotation;

	CachedSoldierRotation = ActorPawn.Rotation;

	// Release soldier pawn to force it to be re-created when armor changes
	if(bRefreshPawn)
		ReleasePawn(true);

	UpdateLockerList();
	UpdateEquippedList();
	CreateSoldierPawn(CachedSoldierRotation);
	Header.PopulateData(GetUnit());
}

// Override function to RequestPawnByState instead of RequestPawnByID
simulated function RequestPawn(optional Rotator DesiredRotation)
{
	ActorPawn = Movie.Pres.GetUIPawnMgr().RequestPawnByState(self, GetUnit(), GetPlacementActor().Location, DesiredRotation);
	ActorPawn.GotoState('CharacterCustomization');
}

simulated function OnCancel()
{
	if(ActiveList == EquippedList)
	{
		// If we are in the tutorial and came from squad select when the medikit objective is active, don't allow backing out
		if (!Movie.Pres.ScreenStack.HasInstanceOf(class'UISquadSelect') || class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T0_M5_EquipMedikit') != eObjectiveState_InProgress)
		{
			super.OnCancel(); // exits screen
		}
	}	
	else
	{
		ChangeActiveList(EquippedList);
	}
}

simulated function OnRemoved()
{
	ResetAvailableEquipment();
	super.OnRemoved();
}

simulated function SetUnitReference(StateObjectReference NewUnit)
{
	super.SetUnitReference(NewUnit);
	MC.FunctionVoid("animateIn");
}

//==============================================================================

simulated function bool EquipItem(UIArmory_LoadoutItem Item)
{
	local StateObjectReference PrevItemRef, NewItemRef;
	local XComGameState_Item PrevItem, NewItem;
	local bool CanEquip, EquipSucceeded, AddToFront;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComNarrativeMoment EquipNarrativeMoment;
	local XGWeapon Weapon;
	local array<XComGameState_Item> PrevUtilityItems;
	local XComGameState_Unit UpdatedUnit;
	local XComGameState UpdatedState;

	UpdatedState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Equip Item");
	UpdatedUnit = XComGameState_Unit(UpdatedState.CreateStateObject(class'XComGameState_Unit', GetUnit().ObjectID));
	UpdatedState.AddStateObject(UpdatedUnit);
	
	PrevUtilityItems = class'UIUtilities_Strategy'.static.GetEquippedUtilityItems(UpdatedUnit, UpdatedState);

	NewItemRef = Item.ItemRef;
	PrevItemRef = UIArmory_LoadoutItem(EquippedList.GetSelectedItem()).ItemRef;
	PrevItem = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(PrevItemRef.ObjectID));

	if(PrevItem != none)
	{
		PrevItem = XComGameState_Item(UpdatedState.CreateStateObject(class'XComGameState_Item', PrevItem.ObjectID));
		UpdatedState.AddStateObject(PrevItem);
	}

	foreach UpdatedState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
	{
		break;
	}

	if(XComHQ == none)
	{
		XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		XComHQ = XComGameState_HeadquartersXCom(UpdatedState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
		UpdatedState.AddStateObject(XComHQ);
	}

	// Attempt to remove previously equipped primary or secondary weapons - NOT WORKING, TODO FIX ME
	if( PrevItem != none && 
		X2WeaponTemplate(PrevItem.GetMyTemplate()) != none && 
		X2WeaponTemplate(PrevItem.GetMyTemplate()).InventorySlot == eInvSlot_PrimaryWeapon || 
		X2WeaponTemplate(PrevItem.GetMyTemplate()).InventorySlot == eInvSlot_SecondaryWeapon)
	{
		Weapon = XGWeapon(PrevItem.GetVisualizer());
		// Weapon must be graphically detach, otherwise destroying it leaves a NULL component attached at that socket
		XComUnitPawn(ActorPawn).DetachItem(Weapon.GetEntity().Mesh);

		Weapon.Destroy();
	}

	CanEquip = ((PrevItem == none || UpdatedUnit.RemoveItemFromInventory(PrevItem, UpdatedState)) && UpdatedUnit.CanAddItemToInventory(Item.ItemTemplate, GetSelectedSlot(), UpdatedState));

	if(CanEquip)
	{
		GetItemFromInventory(UpdatedState, NewItemRef, NewItem);
		NewItem = XComGameState_Item(UpdatedState.CreateStateObject(class'XComGameState_Item', NewItem.ObjectID));
		UpdatedState.AddStateObject(NewItem);

		// Fix for TTP 473, preserve the order of Utility items
		if(PrevUtilityItems.Length > 0)
		{
			AddToFront = PrevItemRef.ObjectID == PrevUtilityItems[0].ObjectID;
		}
		
		EquipSucceeded = UpdatedUnit.AddItemToInventory(NewItem, GetSelectedSlot(), UpdatedState, AddToFront);

		if( EquipSucceeded )
		{
			if( PrevItem != none )
			{
				XComHQ.PutItemInInventory(UpdatedState, PrevItem);
			}

			if(class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T0_M5_EquipMedikit') == eObjectiveState_InProgress &&
			   NewItem.GetMyTemplateName() == class'UIInventory_BuildItems'.default.TutorialBuildItem)
			{
				`XEVENTMGR.TriggerEvent('TutorialItemEquipped', , , UpdatedState);
				bTutorialJumpOut = true;
			}
		}
		else
		{
			if(PrevItem != none)
			{
				UpdatedUnit.AddItemToInventory(PrevItem, GetSelectedSlot(), UpdatedState);
			}

			XComHQ.PutItemInInventory(UpdatedState, NewItem);
		}
	}

	UpdatedUnit.ValidateLoadout(UpdatedState);
	`XCOMGAME.GameRuleset.SubmitGameState(UpdatedState);

	if( EquipSucceeded && X2EquipmentTemplate(Item.ItemTemplate) != none)
	{
		if(X2EquipmentTemplate(Item.ItemTemplate).EquipSound != "")
		{
			`XSTRATEGYSOUNDMGR.PlaySoundEvent(X2EquipmentTemplate(Item.ItemTemplate).EquipSound);
		}

		if(X2EquipmentTemplate(Item.ItemTemplate).EquipNarrative != "")
		{
			EquipNarrativeMoment = XComNarrativeMoment(`CONTENT.RequestGameArchetype(X2EquipmentTemplate(Item.ItemTemplate).EquipNarrative));
			XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
			if(EquipNarrativeMoment != None && XComHQ.CanPlayArmorIntroNarrativeMoment(EquipNarrativeMoment))
			{
				UpdatedState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Update Played Armor Intro List");
				XComHQ = XComGameState_HeadquartersXCom(UpdatedState.CreateStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
				UpdatedState.AddStateObject(XComHQ);
				XComHQ.UpdatePlayedArmorIntroNarrativeMoments(EquipNarrativeMoment);
				`XCOMGAME.GameRuleset.SubmitGameState(UpdatedState);

				`HQPRES.UIArmorIntroCinematic(EquipNarrativeMoment.nmRemoteEvent, 'CIN_ArmorIntro_Done', UnitReference);
			}
		}	
	}

	return EquipSucceeded;
}

simulated function XComGameState_Item GetEquippedItem(EInventorySlot eSlot)
{
	return GetUnit().GetItemInSlot(eSlot, CheckGameState);
}

simulated function EInventorySlot GetSelectedSlot()
{
	return UIArmory_LoadoutItem(EquippedList.GetSelectedItem()).EquipmentSlot;
}

// Used when selecting utility items directly from Squad Select
simulated function SelectItemSlot(EInventorySlot ItemSlot, int ItemIndex)
{
	local int i;
	local UIArmory_LoadoutItem Item;

	for(i = 0; i < EquippedList.ItemCount; ++i)
	{
		Item = UIArmory_LoadoutItem(EquippedList.GetItem(i));

		// We treat grenade pocket slot like a utility slot in this case
		if(Item.EquipmentSlot == ItemSlot)
		{
			EquippedList.SetSelectedIndex(i + ItemIndex);
			break;
		}
	}
	
	ChangeActiveList(LockerList);
	UpdateLockerList();
}

simulated function SelectWeapon(EInventorySlot WeaponSlot)
{
	local int i;

	for(i = 0; i < EquippedList.ItemCount; ++i)
	{
		if(UIArmory_LoadoutItem(EquippedList.GetItem(i)).EquipmentSlot == WeaponSlot)
		{
			EquippedList.SetSelectedIndex(i);
			break;
		}
	}

	ChangeActiveList(LockerList);
	UpdateLockerList();
}

simulated function InitializeTooltipData()
{
	InfoTooltip = Spawn(class'UIArmory_LoadoutItemTooltip', self); 
	InfoTooltip.InitLoadoutItemTooltip('UITooltipInventoryItemInfo');

	InfoTooltip.bUsePartialPath = true;
	InfoTooltip.targetPath = string(MCPath); 
	InfoTooltip.RequestItem = TooltipRequestItemFromPath; 

	InfoTooltip.ID = Movie.Pres.m_kTooltipMgr.AddPreformedTooltip( InfoTooltip );
	InfoTooltip.tDelay = 0; // instant tooltips!
}

simulated function XComGameState_Item TooltipRequestItemFromPath( string currentPath )
{
	local string ItemName, TargetList;
	local array<string> Path;
	local UIArmory_LoadoutItem Item;

	Path = SplitString( currentPath, "." );	

	foreach Path(TargetList)
	{
		//Search the path for the target list matchup
		if( TargetList == string(ActiveList.MCName) )
		{
			ItemName = Path[Path.length-1];
			
			// if we've highlighted the DropItemButton, account for it in the path name
			if(ItemName == "bg")
				ItemName = Path[Path.length-3];

			Item =  UIArmory_LoadoutItem(ActiveList.GetItemNamed(Name(ItemName)));
			if(Item != none)
				return GetItemFromHistory(Item.ItemRef.ObjectID); 
		}
	}
	
	//Else we never found a target list + item
	`log("Problem in UIArmory_Loadout for the UITooltip_InventoryInfo: couldn't match the active list at position -4 in this path: " $currentPath,,'uixcom');
	return none;
}

function bool GetItemFromInventory(XComGameState AddToGameState, StateObjectReference ItemRef, out XComGameState_Item ItemState)
{
	return class'UIUtilities_Strategy'.static.GetXComHQ().GetItemFromInventory(AddToGameState, ItemRef, ItemState);
}

function XComGameState_Item GetItemFromHistory(int ObjectID)
{
	return XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(ObjectID));
}

function XComGameState_Unit GetUnitFromHistory(int ObjectID)
{
	return XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ObjectID));
}

//==============================================================================

defaultproperties
{
	LibID = "LoadoutScreenMC";
	DisplayTag = "UIBlueprint_Loadout";
	CameraTag = "UIBlueprint_Loadout";
	bAutoSelectFirstNavigable = false;
}