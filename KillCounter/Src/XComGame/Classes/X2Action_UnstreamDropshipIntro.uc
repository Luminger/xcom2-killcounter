//---------------------------------------------------------------------------------------
//  FILE:    X2Action_UnstreamDropshipIntro.uc
//  AUTHOR:  David Burchanowski  --  4/9/2015
//  PURPOSE: Unloads the map for the dropship intro. This exists in a separate action so that any cleanup nodes on the 
//           matinee's completed event have a chance to execute before we unstream the map.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2Action_UnstreamDropshipIntro extends X2Action_PlayMatinee config(GameData);

simulated state Executing
{
	function UnstreamIntroMap()
	{
		local XComTacticalMissionManager MissionManager;	

		MissionManager = `TACTICALMISSIONMGR;
		class'XComMapManager'.static.RemoveStreamingMapByName(MissionManager.GetActiveMissionIntroDefinition().MatineePackage, false);
	}

Begin:
	UnstreamIntroMap();

	CompleteAction();
}

DefaultProperties
{
}
