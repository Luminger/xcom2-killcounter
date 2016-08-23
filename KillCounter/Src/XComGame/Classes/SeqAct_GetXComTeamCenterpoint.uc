//---------------------------------------------------------------------------------------
//  FILE:    SeqAct_GetXComTeamCenterpoint.uc
//  AUTHOR:  David Burchanowski
//  PURPOSE: Returns the average location of all living XCom units
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class SeqAct_GetXComTeamCenterpoint extends SequenceAction;

var private vector Centerpoint;

event Activated()
{
	local XComGameStateHistory History;
	local XComWorldData WorldData;
	local XComGameState_Unit Unit;
	local int UnitCount;

	History = `XCOMHISTORY;
	WorldData = `XWORLD;

	Centerpoint = vect(0, 0, 0);

	foreach History.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if(Unit.GetTeam() == eTeam_XCom && Unit.IsAlive())
		{
			Centerpoint += WorldData.GetPositionFromTileCoordinates(Unit.TileLocation);
			UnitCount++;
		}
	}

	Centerpoint /= UnitCount;
}

defaultproperties
{
	ObjName="Get XCom Team Centerpoint"
	ObjCategory="Gameplay"

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true
	bAutoActivateOutputLinks=true

	VariableLinks.Empty
	VariableLinks(0)=(ExpectedType=class'SeqVar_Vector',LinkDesc="Centerpoint",PropertyName=Centerpoint,bWriteable=true)
}