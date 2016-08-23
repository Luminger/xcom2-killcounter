class X2SchematicTemplate extends X2ItemTemplate;

var(X2SchematicTemplate) array<name>	ItemsToUpgrade; // Which items should be upgraded when this schematic is built
var(X2SchematicTemplate) name			ReferenceItemTemplate; // Item which should be referenced for text & loc information

function string GetItemFriendlyName(optional int ItemID = 0)
{
	local X2ItemTemplateManager ItemTemplateManager;
	local X2ItemTemplate ReferenceTemplate;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();	
	ReferenceTemplate = ItemTemplateManager.FindItemTemplate(ReferenceItemTemplate);

	FriendlyName = ReferenceTemplate.FriendlyName;

	return super.GetItemFriendlyName(ItemID);
}

function string GetItemBriefSummary(optional int ItemID = 0)
{
	local X2ItemTemplateManager ItemTemplateManager;
	local X2ItemTemplate ReferenceTemplate;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	ReferenceTemplate = ItemTemplateManager.FindItemTemplate(ReferenceItemTemplate);

	BriefSummary = ReferenceTemplate.BriefSummary;

	return super.GetItemBriefSummary(ItemID);
}

DefaultProperties
{
	ItemCat="schematic"
	bShouldCreateDifficultyVariants=true
}