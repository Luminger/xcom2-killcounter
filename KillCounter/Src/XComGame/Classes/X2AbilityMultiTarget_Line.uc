//---------------------------------------------------------------------------------------
//  FILE:    X2AbilityMultiTarget_Line.uc
//  AUTHOR:  Joshua Bouscher
//  DATE:    17-Jul-2015
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2AbilityMultiTarget_Line extends X2AbilityMultiTargetStyle native(Core);

var int TileWidthExtension; // Extend the width of the line by this many tiles.
var bool bSightRangeLimited;

simulated native function GetMultiTargetOptions(const XComGameState_Ability Ability, out array<AvailableTarget> Targets);
simulated native function GetMultiTargetsForLocation(const XComGameState_Ability Ability, const vector Location, out AvailableTarget Target);
simulated native function GetValidTilesForLocation(const XComGameState_Ability Ability, const vector Location, out array<TTile> ValidTiles);

defaultproperties
{
	bSightRangeLimited = true
}