//---------------------------------------------------------------------------------------
//  FILE:    X2ItemTemplateManager.uc
//  AUTHOR:  Joshua Bouscher
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2ItemTemplateManager extends X2DataTemplateManager
	native(Core) config(GameData);

var config array<name>       ItemCategories;
var config array<name>       UniqueEquipCategories;      //  should be a subset of ItemCategories
var config array<name>       WeaponCategories;
var config array<name>       WeaponTechCategories;
var config array<name>       ArmorTechCategories;

var config array<name>      BuildItemWeaponCategories;
var config array<name>      BuildItemArmorCategories;
var config array<name>      BuildItemMiscCategories;

var config int				MaxTechDistanceForValidDrop;  // number of techs "away" from being useable an item can be for it to be eligible to drop (schematics)

var protectedwrite config array<InventoryLoadout>  Loadouts;
var protectedwrite config array<StatBoostDefinition> StatBoostTable;
var protectedwrite config array<TX2MPSoldierItemDefinition> MPAvailableSoldierItems; // the list of items that are available for MP soldier to equip. -tsmith

var protectedwrite X2LootTableManager  LootTableManager;

native static function X2ItemTemplateManager GetItemTemplateManager();

cpptext
{
public:
	virtual void GetDynamicListValues(const FString& ListName, TArray<FString>& Values);
}

protected event ValidateTemplatesEvent()
{
	local int i;
	local X2ItemTemplate kItemTemplate;

	super.ValidateTemplatesEvent();
	
	LootTableManager = new class'X2LootTableManager';
	LootTableManager.InitLootTables();

	for(i = 0; i < MPAvailableSoldierItems.Length; i++)
	{
		kItemTemplate = FindItemTemplate(MPAvailableSoldierItems[i].ItemTemplateName);
		if(kItemTemplate != none)
		{
			kItemTemplate.MPCost = MPAvailableSoldierItems[i].ItemCost;
		}
	}
}

function bool AddItemTemplate(X2ItemTemplate Template, bool ReplaceDuplicate = false)
{
	return AddDataTemplate(Template, ReplaceDuplicate);
}

function X2DamageTypeTemplate FindDamageTypeTemplate(name DataName)
{
	local X2DataTemplate kTemplate;

	kTemplate = FindDataTemplate(DataName);
	if(kTemplate != none)
		return X2DamageTypeTemplate(kTemplate);
	return none;
}

function X2ItemTemplate FindItemTemplate(name DataName)
{
	local X2DataTemplate kTemplate;

	kTemplate = FindDataTemplate(DataName);
	if (kTemplate != none)
		return X2ItemTemplate(kTemplate);
	return none;
}

function TX2MPSoldierItemDefinition FindMPSoldierItemDefinition(name ItemTemplateName)
{
	local TX2MPSoldierItemDefinition ItemDef;
	local int i;

	for(i = 0; i < MPAvailableSoldierItems.Length; i++)
	{
		if(MPAvailableSoldierItems[i].ItemTemplateName == ItemTemplateName)
		{
			ItemDef = MPAvailableSoldierItems[i];
			break;
		}
	}

	return ItemDef;
}

function array<X2WeaponTemplate> GetAllWeaponTemplates()
{
	local array<X2WeaponTemplate> arrWeaponTemplates;
	local X2DataTemplate Template;
	local X2WeaponTemplate WeaponTemplate;

	foreach IterateTemplates(Template, none)
	{
		WeaponTemplate = X2WeaponTemplate(Template);

		if(WeaponTemplate != none)
		{
			arrWeaponTemplates.AddItem(WeaponTemplate);
		}
	}

	return arrWeaponTemplates;
}

function array<X2EquipmentTemplate> GetAllArmorTemplates()
{
	local array<X2EquipmentTemplate> arrArmorTemplates;
	local X2DataTemplate Template;
	local X2EquipmentTemplate ArmorTemplate;

	foreach IterateTemplates(Template, none)
	{
		ArmorTemplate = X2ArmorTemplate(Template);

		if(ArmorTemplate != none)
		{
			arrArmorTemplates.AddItem(ArmorTemplate);
		}
	}

	return arrArmorTemplates;
}

function array<X2WeaponUpgradeTemplate> GetAllUpgradeTemplates()
{
	local array<X2WeaponUpgradeTemplate> arrUpgradeTemplates;
	local X2DataTemplate Template;
	local X2WeaponUpgradeTemplate UpgradeTemplate;

	foreach IterateTemplates(Template, none)
	{
		UpgradeTemplate = X2WeaponUpgradeTemplate(Template);

		if(UpgradeTemplate != none)
		{
			arrUpgradeTemplates.AddItem(UpgradeTemplate);
		}
	}

	return arrUpgradeTemplates;
}

function array<X2SchematicTemplate> GetAllSchematicTemplates()
{
	local array<X2SchematicTemplate> arrSchematicTemplates;
	local X2DataTemplate Template;
	local X2SchematicTemplate SchematicTemplate;

	foreach IterateTemplates(Template, none)
	{
		SchematicTemplate = X2SchematicTemplate(Template);

		if(SchematicTemplate != none)
		{
			arrSchematicTemplates.AddItem(SchematicTemplate);
		}
	}

	return arrSchematicTemplates;
}

// XCom does not already have the schematic and is close enough in tech
function array<X2SchematicTemplate> GetAllValidSchematicTemplates()
{
	local array<X2SchematicTemplate> arrSchematicTemplates;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersXCom XComHQ;
	local int idx;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	arrSchematicTemplates = GetAllSchematicTemplates();

	for(idx = 0; idx < arrSchematicTemplates.Length; idx++)
	{
		if(XComHQ.HasItem(arrSchematicTemplates[idx]) || !ItemValidGivenCurrentProgression(arrSchematicTemplates[idx]))
		{
			arrSchematicTemplates.Remove(idx, 1);
			idx--;
		}
	}

	return arrSchematicTemplates;
}

// Call when XCom would be given a schematic
function X2SchematicTemplate RollForValidSchematic()
{
	local array<X2SchematicTemplate> arrSchematicTemplates;

	arrSchematicTemplates = GetAllValidSchematicTemplates();

	if(arrSchematicTemplates.Length == 0)
	{
		return none;
	}

	return arrSchematicTemplates[`SYNC_RAND(arrSchematicTemplates.Length)];
}

// Is XCom close enough Tech-wise for this item to be a valid drop
function bool ItemValidGivenCurrentProgression(X2ItemTemplate CheckTemplate)
{
	local X2SchematicTemplate SchematicTemplate;
	local X2ItemTemplate ItemTemplate;
	local X2StrategyElementTemplateManager StratMgr;
	local X2TechTemplate TechTemplate;
	local int idx, TotalDistance;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	SchematicTemplate = X2SchematicTemplate(CheckTemplate);
	TotalDistance = 0;

	if(SchematicTemplate != none)
	{
		ItemTemplate = FindItemTemplate(SchematicTemplate.ItemsToUpgrade[0]);

		if(ItemTemplate != none)
		{
			for(idx = 0; idx < ItemTemplate.Requirements.RequiredTechs.Length; idx++)
			{
				TechTemplate = X2TechTemplate(StratMgr.FindStrategyElementTemplate(ItemTemplate.Requirements.RequiredTechs[idx]));

				if(TechTemplate != none)
				{
					TotalDistance += StratMgr.GetDistanceToTech(TechTemplate);
				}
			}
		}		
	}

	return (TotalDistance <= default.MaxTechDistanceForValidDrop);
}

function array<X2ItemTemplate> GetBuildableItemTemplates()
{
	local array<X2ItemTemplate> arrBuildTemplates;
	local X2DataTemplate Template;
	local X2ItemTemplate ItemTemplate;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;
	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	foreach IterateTemplates(Template, none)
	{
		ItemTemplate = X2ItemTemplate(Template);

		if(ItemTemplate != none)
		{
			if(ItemTemplate.CanBeBuilt && 
				(!ItemTemplate.bOneTimeBuild || (!XComHQ.HasItem(ItemTemplate) && XComHQ.GetNumItemBeingBuilt(ItemTemplate) == 0)) && 
				(!ItemTemplate.bBlocked || XComHQ.UnlockedItems.Find(ItemTemplate.DataName) != INDEX_NONE) &&
				XComHQ.MeetsEnoughRequirementsToBeVisible(ItemTemplate.Requirements) && 
				!XComHQ.IsTechResearched(ItemTemplate.HideIfResearched) && !XComHQ.HasItemByName(ItemTemplate.HideIfPurchased))
			{
				arrBuildTemplates.AddItem(ItemTemplate);
			}
		}
	}

	return arrBuildTemplates;
}

function bool GetItemStatBoost(int PowerLevel, ECharStatType StatType, out StatBoost ItemStatBoost)
{
	local int idx;

	for(idx = 0; idx < StatBoostTable.Length; idx++)
	{
		if(StatBoostTable[idx].PowerLevel == PowerLevel && StatBoostTable[idx].StatType == StatType)
		{
			ItemStatBoost.StatType = StatBoostTable[idx].StatType;
			ItemStatBoost.Boost = StatBoostTable[idx].MinBoost + 
				`SYNC_RAND(StatBoostTable[idx].MaxBoost - StatBoostTable[idx].MinBoost + 1);
			return true;
		}
	}

	return false;
}

function bool WeaponCategoryIsValid(const out name Category)
{
	return WeaponCategories.Find(Category) != INDEX_NONE;
}

function bool ItemCategoryIsValid(const out name Category)
{
	return ItemCategories.Find(Category) != INDEX_NONE;
}

function bool WeaponTechIsValid(const out name Tech)
{
	return  WeaponTechCategories.Find(Tech) != INDEX_NONE;
}

function bool ArmorTechIsValid(const out name Tech)
{
	return ArmorTechCategories.Find(Tech) != INDEX_NONE;
}

function bool ItemCategoryIsUniqueEquip(const out name Category)
{
	return UniqueEquipCategories.Find(Category) != INDEX_NONE;
}

function LoadAllContent()
{
	local X2DataTemplate Template;
	local X2EquipmentTemplate EquipmentTemplate;
	local XComContentManager ContentMgr;

	ContentMgr = `CONTENT;
	foreach IterateTemplates(Template, none)
	{
		EquipmentTemplate = X2EquipmentTemplate(Template);
		if(EquipmentTemplate != none)
		{
			if(EquipmentTemplate.GameArchetype != "")
			{
				ContentMgr.RequestGameArchetype(EquipmentTemplate.GameArchetype, none, none, true);
			}

			if(EquipmentTemplate.AltGameArchetype != "")
			{
				ContentMgr.RequestGameArchetype(EquipmentTemplate.AltGameArchetype, none, none, true);
			}

			if(EquipmentTemplate.CosmeticUnitTemplate != "")
			{
				ContentMgr.RequestGameArchetype(EquipmentTemplate.CosmeticUnitTemplate, none, none, true);
			}
		}
	}
}

DefaultProperties
{
	TemplateDefinitionClass=class'X2Item';
}