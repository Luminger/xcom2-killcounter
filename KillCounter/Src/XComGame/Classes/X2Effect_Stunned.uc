class X2Effect_Stunned extends X2Effect_Persistent;

var localized string StunnedText;
var localized string RoboticStunnedText;

var int StunLevel;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit UnitState;
	local X2EventManager EventManager;

	UnitState = XComGameState_Unit(kNewTargetState);
	if (UnitState != none)
	{
		if( UnitState.GetMyTemplateName() == class'X2Ability_Cyberus'.default.CyberusTemplateName )
		{
			// If the unit receiving the stun effect is a Cyberus, do not give her any stun points
			// A stun will either kill the unit or keep it from being able to superposition until
			// her next turn.
			if( ShouldCyberusBeKilledFromStun(UnitState, NewGameState) )
			{
				// This is not the last, unstunned cyberus so it should be killed
				EventManager = `XEVENTMGR;
				EventManager.TriggerEvent('CyberusUnitStunned', self, UnitState, NewGameState);
			}
		}
		else
		{
			UnitState.ReserveActionPoints.Length = 0;
			UnitState.StunnedActionPoints += StunLevel;
		}

		if( UnitState.IsTurret() ) // Stunned Turret.   Update turret state.
		{
			UnitState.UpdateTurretState(false);
		}

		//  If it's the unit's turn, consume action points immediately
		if (UnitState.ControllingPlayer == `TACTICALRULES.GetCachedUnitActionPlayerRef())
		{
			while (UnitState.StunnedActionPoints > 0 && UnitState.ActionPoints.Length >= UnitState.StunnedActionPoints)
			{
				UnitState.ActionPoints.Remove(0, 1);
				UnitState.StunnedActionPoints--;
				UnitState.StunnedThisTurn++;
			}
		}

		// Immobilize to prevent scamper or panic from enabling this unit to move again.
		UnitState.SetUnitFloatValue(class'X2Ability_DefaultAbilitySet'.default.ImmobilizedValueName, 1);
	}
}

simulated function OnEffectRemoved(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed, XComGameState_Effect RemovedEffectState)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if( (UnitState != none) && UnitState.IsTurret() )
	{
		UnitState = XComGameState_Unit(NewGameState.CreateStateObject(UnitState.Class, UnitState.ObjectID));
		UnitState.UpdateTurretState(false);
		UnitState.SetUnitFloatValue(class'X2Ability_DefaultAbilitySet'.default.ImmobilizedValueName, 0);
		NewGameState.AddStateObject(UnitState);
	}
}

function bool StunTicked(X2Effect_Persistent PersistentEffect, const out EffectAppliedData ApplyEffectParameters, XComGameState_Effect kNewEffectState, XComGameState NewGameState, bool FirstApplication)
{
	local XComGameState_Unit UnitState;

	UnitState = XComGameState_Unit(NewGameState.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));
	if (UnitState == none)
		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ApplyEffectParameters.TargetStateObjectRef.ObjectID));

	if (UnitState != none)
	{
		//The unit remains stunned if they still have more action points to spend being stunned.
		//The unit also remains "stunned" through one more turn, if the turn's action points have been consumed entirely by the stun.
		//In the latter case, the effect will be removed at the beginning of the next turn, just before the unit is able to act.
		//(This prevents one-turn stuns from looking like they "did nothing", when in fact they consumed exactly one turn of actions.)
		//-btopp 2015-09-21

		if (UnitState.StunnedActionPoints > 0) 
			return false;
		else if (UnitState.StunnedActionPoints == 0 && UnitState.NumAllActionPoints() == 0)
			return false; 
	}
	return true;
}

simulated function AddX2ActionsForVisualization(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, name EffectApplyResult)
{
	local X2Action_PlaySoundAndFlyOver SoundAndFlyOver;
	local X2Action_PlayAnimation PlayAnimation;
	local bool bRobotic;
	local XGUnit Unit;
	local XComUnitPawn UnitPawn;

	if (EffectApplyResult == 'AA_Success' && BuildTrack.StateObject_NewState.IsA('XComGameState_Unit'))
	{
		bRobotic = XComGameState_Unit(BuildTrack.StateObject_NewState).IsRobotic();

		SoundAndFlyOver = X2Action_PlaySoundAndFlyOver(class'X2Action_PlaySoundAndFlyOver'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
		SoundAndFlyOver.SetSoundAndFlyOverParameters(None, (bRobotic ? RoboticStunnedText : StunnedText) @ StunLevel, '', eColor_Bad, class'UIUtilities_Image'.const.UnitStatus_Stunned);

		if( XComGameState_Unit(BuildTrack.StateObject_NewState).IsTurret() )
		{
			class'X2Action_UpdateTurretAnim'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext());
		}
		else
		{
			// Not a turret

			Unit = XGUnit(BuildTrack.TrackActor);
			if( Unit != None )
			{
				UnitPawn = Unit.GetPawn();

				// The unit may already be locked down (i.e. Viper bind), if so, do not play the stun start anim
				if( (UnitPawn != none) && (UnitPawn.GetAnimTreeController().CanPlayAnimation('HL_StunnedStart')) )
				{
					// Play the start stun animation
					PlayAnimation = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
					PlayAnimation.Params.AnimName = 'HL_StunnedStart';
					PlayAnimation.bResetWeaponsToDefaultSockets = true;
				}
			}
		}

		super.AddX2ActionsForVisualization(VisualizeGameState, BuildTrack, EffectApplyResult);
	}
}

simulated function AddX2ActionsForVisualization_Sync(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack)
{
	//We assume 'AA_Success', because otherwise the effect wouldn't be here (on load) to get sync'd
	AddX2ActionsForVisualization(VisualizeGameState, BuildTrack, 'AA_Success');
}

simulated function AddX2ActionsForVisualization_Removed(XComGameState VisualizeGameState, out VisualizationTrack BuildTrack, const name EffectApplyResult, XComGameState_Effect RemovedEffect)
{
	local X2Action_PlayAnimation PlayAnimation;
	local XComGameState_Unit StunnedUnit;

	super.AddX2ActionsForVisualization_Removed(VisualizeGameState, BuildTrack, EffectApplyResult, RemovedEffect);

	StunnedUnit = XComGameState_Unit(BuildTrack.StateObject_NewState);

	if( StunnedUnit.IsTurret() )
	{
		class'X2Action_UpdateTurretAnim'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext());
	}
	else if (StunnedUnit.IsAlive() && !StunnedUnit.IsIncapacitated()) //Don't play the animation if the unit is going straight from stunned to killed
	{
		// The unit is not a turret and is not dead/unconscious/bleeding-out
		PlayAnimation = X2Action_PlayAnimation(class'X2Action_PlayAnimation'.static.AddToVisualizationTrack(BuildTrack, VisualizeGameState.GetContext()));
		PlayAnimation.Params.AnimName = 'HL_StunnedStop';
	}
}

// This function checks if the Cyberus should be killed by a stun. There is a special case that
// keeps her from becoming killed by a stun. If the Cyberus is to be stunned AND the last Cyberus alive, then
// do not kill her.
private function bool ShouldCyberusBeKilledFromStun(const XComGameState_Unit TargetCyberus, const XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_Unit CurrentUnit, TestUnit;
	local bool bStunCyberus;

	bStunCyberus = false;

	// If the Cyberus is not alive, then no need to kill her. We only care if she is alive
	// AND not the last living, unstunned Cyberus.
	if( TargetCyberus.IsAlive() )
	{
		History = `XCOMHISTORY;

		// Kill this target if there is at least one other Unit that is
		// Not the Target
		// AND
		// Is a Cyberus
		// AND
		// Alive AND Unstunned
		// AND
		// Friendly to the Target
		foreach History.IterateByClassType( class'XComGameState_Unit', CurrentUnit )
		{
			TestUnit = XComGameState_Unit(NewGameState.GetGameStateForObjectID(CurrentUnit.ObjectID));
			if( TestUnit != none )
			{
				// Check units in the unsubmitted GameState if possible
				CurrentUnit = TestUnit;
			}

			if( (CurrentUnit.ObjectID != TargetCyberus.ObjectID) &&
				(CurrentUnit.GetMyTemplateName() == TargetCyberus.GetMyTemplateName()) &&
				CurrentUnit.IsAlive() &&
				!CurrentUnit.IsStunned() &&
				CurrentUnit.IsFriendlyUnit(TargetCyberus) )
			{
				bStunCyberus = true;
				break;
			}
		}
	}
	
	return bStunCyberus;
}

defaultproperties
{
	bIsImpairing=true
	DamageTypes(0) = "stun"
	DamageTypes(1) = "Mental"
	EffectTickedFn=StunTicked
	CustomIdleOverrideAnim="HL_StunnedIdle"
}