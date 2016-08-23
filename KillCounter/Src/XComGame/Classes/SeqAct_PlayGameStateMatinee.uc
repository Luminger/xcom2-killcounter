//---------------------------------------------------------------------------------------
//  FILE:    SeqAct_PlayGameStateMatinee.uc
//  AUTHOR:  David Burchanowski  --  2/10/2014
//  PURPOSE: Plays a matinee in a gamestate safe manner
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class SeqAct_PlayGameStateMatinee extends SequenceAction
	implements(X2KismetSeqOpVisualizer)
	native;

cpptext
{
	virtual void PostEditChangeProperty(FPropertyChangedEvent& PropertyChangedEvent);

#if WITH_EDITOR
	virtual FString GetDisplayTitle() const;
#endif
}

// deprecated: hard link to the matinee we want to play. Does not work across maps. Temporarily here
// so that existing kismet functionality is not broken
var() editconst SeqAct_Interp Matinee;

// obj comment on the matinee we want to play
var() string MatineeComment;

// Allows the LDs to specify a world space location for this matinee to play at
var() string MatineeBaseActorTag;
var() string MatineeBaseActorSocket;

// finds the matinee with our tag in the loaded maps
native private function SeqAct_Interp FindMatinee();

function ModifyKismetGameState(out XComGameState GameState)
{
	// everything needs to wait for the matinee to complete
	GameState.GetContext().SetVisualizationFence(true, 40.0f);
}

function BuildVisualization(XComGameState GameState, out array<VisualizationTrack> VisualizationTracks)
{
	local XComGameStateHistory History;
	local X2Action_PlayMatinee MatineeAction;
	local XComGameState_Player PlayerObject;
	local VisualizationTrack Track;
	local XComGameState_Unit UnitState;
	local SeqVar_GameUnit UnitVar;
	local SeqVarLink VarLink;

	History = `XCOMHISTORY;

	// tracks want an object reference of some kind, even though the action doesn't need one.
	// so just grab anything
	foreach `XCOMHISTORY.IterateByClassType(class'XComGameState_Player', PlayerObject)
	{
		Track.StateObject_OldState = PlayerObject;
		Track.StateObject_NewState = PlayerObject;
		break;
	}

	MatineeAction = X2Action_PlayMatinee(class'X2Action_PlayMatinee'.static.AddToVisualizationTrack(Track, GameState.GetContext()));
	MatineeAction.Matinee = FindMatinee();
	MatineeAction.SetMatineeBase(name(MatineeBaseActorTag), name(MatineeBaseActorSocket));

	// add the unit mappings -> group name
	foreach VariableLinks(VarLink)
	{
		UnitVar = VarLink.LinkedVariables.Length > 0 ? SeqVar_GameUnit(VarLink.LinkedVariables[0]) : none;

		if(UnitVar != none && UnitVar.IntValue > 0)
		{
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitVar.IntValue));

			if(UnitState != none)
			{
				MatineeAction.AddUnitToMatinee(name(VarLink.LinkDesc), UnitState);
			}
		}
	}

	VisualizationTracks.AddItem(Track);
}

defaultproperties
{
	ObjName="Play Matinee (Game State)"
	ObjCategory="Kismet"
	bCallHandler=false
	bAutoActivateOutputLinks=true

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	VariableLinks.Empty;
}