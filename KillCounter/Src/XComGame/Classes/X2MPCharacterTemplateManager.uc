//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    X2MPCharacterTemplateManager.uc
//  AUTHOR:  Todd Smith  --  10/13/2015
//  PURPOSE: Manager for character templates for multiplayer units
//---------------------------------------------------------------------------------------
//  Copyright (c) 2015 Firaxis Games Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class X2MPCharacterTemplateManager extends X2DataTemplateManager
	native(MP) 
	config(MPCharacterData);

native static function X2MPCharacterTemplateManager GetMPCharacterTemplateManager();

protected event ValidateTemplatesEvent()
{
	super.ValidateTemplatesEvent();
}

function X2MPCharacterTemplate FindMPCharacterTemplate(name DataName)
{
	local X2DataTemplate kTemplate;

	kTemplate = FindDataTemplate(DataName);
	if (kTemplate != none)
		return X2MPCharacterTemplate(kTemplate);
	return none;
}

defaultproperties
{
	TemplateDefinitionClass=class'X2MPCharacter';
}