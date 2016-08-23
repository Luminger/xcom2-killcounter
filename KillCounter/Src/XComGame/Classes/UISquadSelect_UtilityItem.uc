//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UISquadSelect_UtilityItem
//  AUTHOR:  Sam Batista -- 5/1/14
//  PURPOSE: Displays a Utility Item's image, or a locked icon if none is equipped.
//  NOTE:    Can be clicked on.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UISquadSelect_UtilityItem extends UIPanel;

var UIImage Image;
var UIButton Button;
var UIScrollingText SlotTypeText;

var int SlotIndex;
var EInventorySlot SlotType;

var localized string GrenadeSlot;
var localized string AmmoSlot;

simulated function UIPanel InitPanel(optional name InitName, optional name InitLibID)
{
	super.InitPanel(InitName, InitLibID);
	
	Button = Spawn(class'UIButton', self).InitButton(,, OnButtonClicked);
	Button.bAnimateOnInit = false;
	//Navigator.SetSelected(Button); 

	SlotTypeText = Spawn(class'UIScrollingText', self).InitScrollingText();
	SlotTypeText.SetAlpha(60);
	
	Image = Spawn(class'UIImage', self).InitImage();
	Image.bAnimateOnInit = false;
	Image.OriginCenter();

	return self;
}

simulated function UIPanel SetSize(float NewWidth, float NewHeight)
{
	if( Width != NewWidth || Height != NewHeight )
	{
		Width = NewWidth;
		Height = NewHeight;
		Button.SetSize(Width, Height);
		Image.SetPosition(Width / 2, Height / 2);
		SlotTypeText.SetPosition(0, (Height / 2) - 15).SetWidth(Width);
	}
	return self;
}

simulated function SetItemImage(XComGameState_Item Item, optional int NumSlots)
{
	if(Item != none)
	{
		Image.LoadImage(Item.GetMyTemplate().strImage);
		Image.SetScale(NumSlots > 2 ? 0.18 : 0.25);
		Image.Show();
	}
	else
	{
		Image.Hide();
	}
}

simulated function SetSlotType(EInventorySlot InventorySlot)
{
	switch(InventorySlot)
	{
	case eInvSlot_AmmoPocket:
		SlotTypeText.SetText(AmmoSlot);
		SlotTypeText.Show();
		break;
	case eInvSlot_GrenadePocket:
		SlotTypeText.SetText(GrenadeSlot);
		SlotTypeText.Show();
		break;
	default:
		SlotTypeText.Hide();
	}
}

simulated function SetAvailable(XComGameState_Item Item, EInventorySlot InventorySlot, optional int Index, optional int NumSlots )
{
	SlotIndex = Index;
	SlotType = InventorySlot;
	Button.EnableButton();

	SetItemImage(Item, NumSlots);

	if(Item != none)
		SlotTypeText.Hide();
	else
		SetSlotType(InventorySlot);
}

simulated function SetDisabled(XComGameState_Item Item, EInventorySlot InventorySlot, optional int Index, optional int NumSlots )
{
	SlotIndex = Index;
	SlotType = InventorySlot;
	Button.DisableButton();

	SetItemImage(Item, NumSlots);

	if(Item != none)
		SlotTypeText.Hide();
	else
		SetSlotType(InventorySlot);
}

simulated function SetLocked(optional string Tooltip)
{
	Button.DisableButton(Tooltip);
	Image.LoadImage(class'UIUtilities_Image'.const.SquadSelect_LockedUtilitySlot);
	Image.SetScale(0.3);
	Image.Show();
}

simulated function SetBlocked(optional string Tooltip)
{
	Button.DisableButton(Tooltip);
	Image.LoadImage(class'UIUtilities_Image'.const.SquadSelect_BlockedUtilitySlot);
	Image.SetScale(0.3);
	Image.Show();
}

function OnButtonClicked(UIButton ButtonClicked)
{
	if( !ButtonClicked.IsDisabled )
	{
		UISquadSelect(Screen).bDirty = true;
		UISquadSelect(Screen).SnapCamera();
		SetTimer(0.1f, false, nameof(GoToUtilityItem));
	}
}

simulated function GoToUtilityItem()
{
	`HQPRES.UIArmory_Loadout(UISquadSelect_ListItem(GetParent(class'UISquadSelect_ListItem')).GetUnitRef());
	UIArmory_Loadout(Movie.Stack.GetScreen(class'UIArmory_Loadout')).SelectItemSlot(SlotType, SlotIndex);
}

simulated function OnReceiveFocus()
{
	if(!bIsFocused)
	{
		super.OnReceiveFocus();
		GetParent(class'UISquadSelect_ListItem', true).OnReceiveFocus();
	}
}

simulated function OnLoseFocus()
{
	if(bIsFocused)
	{
		super.OnLoseFocus();
		GetParent(class'UISquadSelect_ListItem', true).OnLoseFocus();
	}
}

defaultproperties
{
	bIsNavigable = true;
}