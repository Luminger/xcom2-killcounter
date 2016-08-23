//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIInventoryTactical.uc
//  AUTHOR:  Brit Steiner
//  PURPOSE: 
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UIInventoryTactical extends UIScreen;

//  UI
var UIPanel			m_kRContainer;
var UIList		m_kLootList;

var UIText		    m_kText;

//var UIButton		m_kButton_DumpAll;
//var UIButton		m_kButton_TakeAll;
var UIButton		m_kButton_OK;

var AkEvent                 LootingSound;

var localized string				m_strDumpAll;
var localized string				m_strTakeAll;
var localized string				m_strTitle;

//  GAME DATA
struct LootDisplay
{
	var Lootable                    LootTarget;
	var array<StateObjectReference> LootItems;
	var array<int>					HasBeenLooted;
};

var XComGameState               m_NewGameState;
var XComGameState_Unit          m_Looter;
var array<StateObjectReference> m_LooterItems;
var array<LootDisplay>          m_Loots;
var delegate<OnScreenClosed>            ClosedCallback;

delegate OnScreenClosed();

//----------------------------------------------------------------------------

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);

	//------------------------------------------------------------

	m_kRContainer = Spawn(class'UIPanel', self);
	m_kRContainer.InitPanel('RightContainer');

	MC.BeginFunctionOp("SetTitle");
	MC.QueueString( m_strTitle );
	MC.QueueString( m_Looter.GetName(eNameType_RankFull) );
	MC.EndOp();

	m_kLootList = Spawn(class'UIList', m_kRContainer);
	m_kLootList.InitList('ListB', 10, 135, 480, 290); // position list underneath title
	
	m_kButton_OK = Spawn(class'UIButton', m_kRContainer);
	m_kButton_OK.InitButton('BackButton', class'UIUtilities_Text'.default.m_strGenericOK, OnButtonClicked, eUIButtonStyle_HOTLINK_BUTTON);
	m_kButton_OK.SetPosition(180, 430); 
	
	UpdateData();
}

simulated function InitLoot(XComGameState_Unit Looter, Lootable LootableObject, delegate<OnScreenClosed> CallbackFn )
{
	local XComGameState_Item Item;
	local StateObjectReference Ref;
	local LootDisplay Display;
	local int HistoryIndex;
	local array<StateObjectReference> LootRefs;

	`assert(m_NewGameState == none);

	ClosedCallback = CallbackFn;
	m_NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Initialize Loot");
	HistoryIndex = Looter.GetParentGameState().HistoryIndex;
	m_Looter = XComGameState_Unit(m_NewGameState.CreateStateObject(class'XComGameState_Unit', Looter.ObjectID, HistoryIndex));;
	m_NewGameState.AddStateObject(m_Looter);
	//  create new versions of all backpack items
	foreach m_Looter.InventoryItems(Ref)
	{
		Item = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(Ref.ObjectID));
		if (Item.InventorySlot == eInvSlot_Backpack)
		{
			Item = XComGameState_Item(m_NewGameState.CreateStateObject(class'XComGameState_Item', Ref.ObjectID, HistoryIndex));
			m_NewGameState.AddStateObject(Item);
		}
	}
	//  turn all the loot targets into LootDisplays
	Display.LootTarget = LootableObject;
	m_Loots.AddItem(Display);

	LootRefs = LootableObject.GetAvailableLoot();

	foreach LootRefs(Ref)
	{
		Item = XComGameState_Item(m_NewGameState.CreateStateObject(class'XComGameState_Item', Ref.ObjectID, HistoryIndex));
		m_NewGameState.AddStateObject(Item);
	}
}

simulated function OnButtonClicked(UIButton button)
{
	local int i;

	switch( button )
	{
	case m_kButton_OK:
		for( i = 0; i < m_Loots.Length; ++i )
		{
			WorldInfo.PlayAkEvent(LootingSound);
			UpdateData();
		}

		`XCOMHISTORY.CleanupPendingGameState(m_NewGameState);

		CloseScreen();

		if (ClosedCallback != none)
			ClosedCallback();

		XComPresentationLayer(Movie.Pres).m_kInventoryTactical = none; 
		break;
	}
}

simulated function bool OnCancel(optional string arg = "")
{
	if (ClosedCallback != none)
		ClosedCallback();

	XComPresentationLayer(Movie.Pres).m_kInventoryTactical = none; 
	return true;
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	switch( cmd )
	{
	case class'UIUtilities_Input'.const.FXS_BUTTON_A:
	case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
	case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
	case class'UIUtilities_Input'.const.FXS_BUTTON_B:
	case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
	case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
		OnButtonClicked(m_kButton_OK);
	}

	return true;
}

simulated function UpdateData()
{
	local int i, j;
	local StateObjectReference Loot;
	local XComGameState_Item Item;
	local X2ItemTemplate ItemTemplate;
	local UIInventoryTactical_LootingItem UIItem;
	local string ItemName, Tooltip;

	m_LooterItems.Length = 0;
	for (i = 0; i < m_Loots.Length; ++i)
		m_Loots[i].LootItems.Length = 0;

	if (m_NewGameState != none)
	{
		foreach m_Looter.InventoryItems(Loot)
		{
			Item = XComGameState_Item(m_NewGameState.GetGameStateForObjectID(Loot.ObjectID));
			if (Item != none && Item.InventorySlot == eInvSlot_Backpack)
			{
				m_LooterItems.AddItem(Loot);
			}
		}

		for (i = 0; i < m_Loots.Length; ++i)
		{
			m_Loots[i].LootItems = m_Loots[i].LootTarget.GetAvailableLoot();
			m_Loots[i].HasBeenLooted.Length = m_Loots[i].LootItems.Length;
		}
	}

	// Update Loot List
	ClearTooltips(m_kLootList);
	m_kLootList.ClearItems();
	for (i = 0; i < m_Loots.Length; ++i)
	{
		MC.FunctionString( "SetHeader", m_Loots[i].LootTarget.GetLootingName() );

		for (j = 0; j < m_Loots[i].LootItems.Length; ++j)
		{
			if (m_Loots[i].HasBeenLooted[j] == 0)
			{
				Item = XComGameState_Item(m_NewGameState.GetGameStateForObjectID(m_Loots[i].LootItems[j].ObjectID));
				ItemTemplate = Item.GetMyTemplate();

				UIItem = Spawn(class'UIInventoryTactical_LootingItem', m_kLootList.itemContainer).InitLootItem(true);
				ItemName = ItemTemplate.GetItemFriendlyName();
				if (Item.Quantity > 1)
					ItemName @= "x" $ string(Item.Quantity);

				Tooltip = ItemTemplate.GetItemLootTooltip();
				if( Tooltip != "" )
					UIItem.SetText(ItemName, Tooltip);
				else
					UIItem.SetText(ItemName, ItemTemplate.GetItemBriefSummary(Item.ObjectID));

				UIItem.GameStateObjectID = Item.ObjectID;

				if (m_Looter.CanAddItemToInventory(Item.GetMyTemplate(), eInvSlot_Backpack, m_NewGameState))
					UIItem.SetDisabled(false);
				else
					UIItem.SetDisabled(true);
			}
		}
	}
}

function ClearTooltips( UIList list )
{
	local int i;
	local UIInventoryTactical_LootingItem UIItem;
	for (i = 0; i < list.itemCount; ++i)
	{
		UIItem = UIInventoryTactical_LootingItem(list.GetItem(i));
		if (UIItem != none)
			Movie.Pres.m_kTooltipMgr.RemoveTooltipsByPartialPath(string(UIItem.MCPath));
	}
}

function bool IsLoot(UIInventoryTactical_LootingItem item)
{
	return m_kLootList.GetItemIndex(item) != -1;
}

//==============================================================================

defaultproperties
{
	Package = "/ package/gfxLootingUI/LootingUI";
	InputState = eInputState_Consume;
	LootingSound = AkEvent'SoundTacticalUI.TacticalUI_Looting'
	bConsumeMouseEvents = true;
	bShowDuringCinematic = true; // hacking animation is considered a cinematic, so make sure not to hide this during cinematics
}
