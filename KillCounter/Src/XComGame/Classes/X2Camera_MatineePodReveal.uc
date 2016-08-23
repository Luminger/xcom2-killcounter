//---------------------------------------------------------------------------------------
//  FILE:    X2Camera_MatineePodReveal.uc
//  AUTHOR:  David Burchanowski  --  2/10/2014
//  PURPOSE: Specialized Matinee camera that takes the reveal unit's motion into account and discards cameras that would
//           run them into a wall.
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2Camera_MatineePodReveal extends X2Camera_Matinee
	dependson(X2MatineeInfo);

protected function bool IsMatineeValid(SeqAct_Interp Matinee, Actor FocusActor, Rotator OldCameraLocation)
{
	local XComTacticalCheatManager CheatManager;
	local XComWorldData WorldData;
	local XGUnit MatineeUnit;
	local XComGameState_Unit MatineeUnitState;
	local XComPawn MatineePawn;
	local XComAnimTreeController TreeController;
	local Vector  SampleLocation;
	local Rotator SampleRotation;
	local Vector  PreviousSampleLocation;
	local Rotator PreviousSampleRotation;
	local Vector Extent;
	local float MinTraceLengthSquared;
	local float TraceLengthSquared;
	local float MatineeDuration;
	local float SampleHeight;
	local float Time;

	local Actor  HitActor;
	local Vector HitLocation;
	local Vector HitNormal;

	if(!super.IsMatineeValid(Matinee, FocusActor, OldCameraLocation))
	{
		return false;
	}

	CheatManager = `CHEATMGR;
	if(CheatManager.DisablePodRevealLeaderCollisionFail)
	{
		return true;
	}

	// The base class checks passed, so further check if the revealed pod leader's animation is going to animate him into
	// geometry

	WorldData = `XWORLD;

	MatineeUnit = XGUnit(FocusActor);
	`assert(MatineeUnit != none); // since this is canned for use with the pod reveals, we should assert, as anything else is very bad!
	MatineeUnitState = MatineeUnit.GetVisualizedGameState();
	if(MatineeUnitState.GetMyTemplate().bDisablePodRevealMovementChecks)
	{
		return true; // no need to do checks on units that cannot move during their reveals
	}

	MatineePawn = MatineeUnit.GetPawn();
	TreeController = MatineeUnit.GetPawn().AnimTreeController;

	// save off our extent, but shrink it a bit. A tiny bit of clipping is okay, better than not playing a matinee at all
	Extent.X = (MatineeUnitState.UnitSize * class'XComWorldData'.const.WORLD_HalfStepSize) * 0.5f;
	Extent.Y = Extent.X;
	Extent.Z = class'XComWorldData'.const.WORLD_HalfFloorHeight;
	SampleHeight = Extent.Z + class'XComPathingPawn'.default.PathHeightOffset;
	MinTraceLengthSquared = (class'XComWorldData'.const.WORLD_HalfStepSize * 0.5f) * (class'XComWorldData'.const.WORLD_HalfStepSize * 0.5f);

	// grab the initial sample location at the start of the animtion
	MatineeInfo.SampleRootMotionFromAnimationTrack('Char1', 0.0f, TreeController, PreviousSampleLocation, PreviousSampleRotation);
	PreviousSampleLocation.Z += SampleHeight;
	MatineeDuration = MatineeInfo.GetMatineeDuration();

	for(Time = 0.25; Time < MatineeDuration; Time += 0.25f) // sample along the actor's movement path in quarter second increments
	{
		// grab the next sample along the root motion track
		MatineeInfo.SampleRootMotionFromAnimationTrack('Char1', Time, TreeController, SampleLocation, SampleRotation);
		SampleLocation.Z += SampleHeight;

		// if this is the last sample we will take, make sure it goes all the way to the end
		if((Time + 0.25) >= MatineeDuration)
		{
			Time = MatineeDuration;
		}
		else
		{
			// don't do a bunch of small line checks, only check if we are moving an appreciable amount.
			TraceLengthSquared = VSizeSq(PreviousSampleLocation - SampleLocation);
			if(TraceLengthSquared < MinTraceLengthSquared)
			{
				continue;
			}
		}

		// check to make sure we have valid ground to stand on here
		// need to bump it back down to floor height and then back up again
		SampleLocation.Z -= SampleHeight;
		if(!WorldData.IsPositionOnFloor(SampleLocation))
		{
			return false; // no bueno to walk out on empty air
		}
		SampleLocation.Z += SampleHeight;

		// check for collision between previous and current
		foreach MatineeUnit.TraceActors(class'Actor', HitActor, HitLocation, HitNormal, PreviousSampleLocation, SampleLocation, Extent)
		{
			if(HitActor != MatineePawn && (XComPawn(HitActor) != None || XComLevelActor(HitActor) != none || XComFracLevelActor(HitActor) != none))
			{
// 				`Battle.DrawDebugBox(PreviousSampleLocation, Extent, 0, 255, 0, true);
// 				`Battle.DrawDebugBox(SampleLocation, Extent, 0, 0, 255, true);
// 				`Battle.DrawDebugBox(HitLocation, Extent, 255, 0, 0, true);
				// we hit a level actor or pawn of some kind, this is verboten!
				CheatManager.PodRevealDecisionRecord = CheatManager.PodRevealDecisionRecord@"Focus unit will walk through obstacle:"@HitActor@", CANCELLED";
				return false;
			}
		}

		PreviousSampleLocation = SampleLocation;
		PreviousSampleRotation = SampleRotation;
	}

	return true;
}