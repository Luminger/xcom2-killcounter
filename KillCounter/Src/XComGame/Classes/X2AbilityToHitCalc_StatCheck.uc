class X2AbilityToHitCalc_StatCheck extends X2AbilityToHitCalc abstract;

var int BaseValue;

function int GetAttackValue(XComGameState_Ability kAbility, StateObjectReference TargetRef) { return -1; }
function int GetDefendValue(XComGameState_Ability kAbility, StateObjectReference TargetRef) { return -1; }

protected function int GetHitChance(XComGameState_Ability kAbility, AvailableTarget kTarget, optional bool bDebugLog=false)
{
	local int AttackVal, DefendVal, TargetRoll;
	local ShotBreakdown EmptyShotBreakdown;

	//reset shot breakdown
	m_ShotBreakdown = EmptyShotBreakdown;

	AttackVal = GetAttackValue(kAbility, kTarget.PrimaryTarget);
	DefendVal = GetDefendValue(kAbility, kTarget.PrimaryTarget);
	TargetRoll = BaseValue + AttackVal - DefendVal;
	AddModifier(BaseValue, GetBaseString());
	AddModifier(AttackVal, GetAttackString());
	AddModifier(-DefendVal, GetDefendString());
	m_ShotBreakdown.FinalHitChance = TargetRoll;
	return TargetRoll;
}

function string GetBaseString() { return class'XLocalizedData'.default.BaseChance; }
function string GetAttackString() { return class'XLocalizedData'.default.OffenseStat; }
function string GetDefendString() { return class'XLocalizedData'.default.DefenseStat; }

function RollForAbilityHit(XComGameState_Ability kAbility, AvailableTarget kTarget, out AbilityResultContext ResultContext)
{
	local int MultiTargetIndex, AttackVal, DefendVal, TargetRoll, RandRoll;

	`log("===RollForAbilityHit===",,'XCom_HitRolls');
	`log("Ability:" @ kAbility.GetMyTemplateName() @ "Target:" @ kTarget.PrimaryTarget.ObjectID,,'XCom_HitRolls');

	if (kTarget.PrimaryTarget.ObjectID > 0)
	{
		AttackVal = GetAttackValue(kAbility, kTarget.PrimaryTarget);
		DefendVal = GetDefendValue(kAbility, kTarget.PrimaryTarget);
		TargetRoll = BaseValue + AttackVal - DefendVal;
		`log("Attack Value:" @ AttackVal @ "Defend Value:" @ DefendVal @ "Target Roll:" @ TargetRoll,,'XCom_HitRolls');
		if (TargetRoll < 100)
		{
			RandRoll = `SYNC_RAND(100);
			`log("Random roll:" @ RandRoll,,'XCom_HitRolls');
			if (RandRoll < TargetRoll)
				ResultContext.HitResult = eHit_Success;
			else
				ResultContext.HitResult = eHit_Miss;
		}
		else
		{
			ResultContext.HitResult = eHit_Success;
		}
		`log("Result:" @ ResultContext.HitResult,,'XCom_HitRolls');
		if (class'XComGameStateContext_Ability'.static.IsHitResultHit(ResultContext.HitResult))
		{
			ResultContext.StatContestResult = RollForEffectTier(kAbility, kTarget.PrimaryTarget, false);
		}
	}
	else
	{
		ResultContext.HitResult = eHit_Success;         //  mark success for the ability to go off
	}

	if( `CHEATMGR != None && `CHEATMGR.bDeadEyeStats )
	{
		`log("DeadEyeStats cheat forcing a hit.", true, 'XCom_HitRolls');
		ResultContext.HitResult = eHit_Success;
	}
	else if( `CHEATMGR != None && `CHEATMGR.bNoLuckStats )
	{
		`log("NoLuckStats cheat forcing a miss.", true, 'XCom_HitRolls');
		ResultContext.HitResult = eHit_Miss;
	}
	if( `CHEATMGR != None && `CHEATMGR.bForceAttackRollValue )
	{
		ResultContext.HitResult = eHit_Success;
		ResultContext.StatContestResult = `CHEATMGR.iForcedRollValue;
	}

	for (MultiTargetIndex = 0; MultiTargetIndex < kTarget.AdditionalTargets.Length; ++MultiTargetIndex)
	{
		`log("Roll against multi target" @ kTarget.AdditionalTargets[MultiTargetIndex].ObjectID,,'XCom_HitRolls');
		AttackVal = GetAttackValue(kAbility, kTarget.AdditionalTargets[MultiTargetIndex]);
		DefendVal = GetDefendValue(kAbility, kTarget.AdditionalTargets[MultiTargetIndex]);
		TargetRoll = BaseValue + AttackVal - DefendVal;
		`log("Attack Value:" @ AttackVal @ "Defend Value:" @ DefendVal @ "Target Roll:" @ TargetRoll,,'XCom_HitRolls');
		if (TargetRoll < 100)
		{
			RandRoll = `SYNC_RAND(100);
			`log("Random roll:" @ RandRoll,,'XCom_HitRolls');
			if (RandRoll < TargetRoll)
				ResultContext.MultiTargetHitResults.AddItem(eHit_Success);
			else
				ResultContext.MultiTargetHitResults.AddItem(eHit_Miss);
		}
		else
		{
			ResultContext.MultiTargetHitResults.AddItem(eHit_Success);
		}
		`log("Result:" @ ResultContext.HitResult,,'XCom_HitRolls');
		if (class'XComGameStateContext_Ability'.static.IsHitResultHit(ResultContext.HitResult))
		{
			ResultContext.MultiTargetStatContestResult.AddItem(RollForEffectTier(kAbility, kTarget.AdditionalTargets[MultiTargetIndex], true));
		}
		else
		{
			ResultContext.MultiTargetStatContestResult.AddItem(0);
		}
	}
}

function int RollForEffectTier(XComGameState_Ability kAbility, StateObjectReference TargetRef, bool bMultiTarget)
{
	local X2AbilityTemplate AbilityTemplate;
	local int MaxTier, MiddleTier, Idx, AttackVal, DefendVal;
	local array<float> TierValues;
	local float TierValue, LowTierValue, HighTierValue, TierValueSum, RandRoll;

	AbilityTemplate = kAbility.GetMyTemplate();
	if (TargetRef.ObjectID > 0)
	{
		`log("=RollForEffectTier=");
		AttackVal = GetAttackValue(kAbility, TargetRef);
		DefendVal = GetDefendValue(kAbility, TargetRef);
		if (bMultiTarget)
			MaxTier = GetHighestTierPossible(AbilityTemplate.AbilityMultiTargetEffects);
		else
			MaxTier = GetHighestTierPossible(AbilityTemplate.AbilityTargetEffects);
		`log("Attack Value:" @ AttackVal @ "Defend Value:" @ DefendVal @ "Max Tier:" @ MaxTier,,'XCom_HitRolls');

		//  It's possible the ability only cares about success or failure and has no specified ladder of results
		if (MaxTier < 0)
		{
			return 0;
		}

		MiddleTier = MaxTier / 2 + MaxTier % 2;		
		TierValue = 100.0f / float(MaxTier);
		LowTierValue = TierValue * (float(DefendVal) / float(AttackVal));
		HighTierValue = TierValue * (float(AttackVal) / float(DefendVal));
		for (Idx = 1; Idx <= MaxTier; ++Idx)
		{			
			if (Idx < MiddleTier)
			{
				TierValues.AddItem(LowTierValue);
			}
			else if (Idx == MiddleTier)
			{
				TierValues.AddItem(TierValue);
			}
			else
			{
				TierValues.AddItem(HighTierValue);
			}			
			TierValueSum += TierValues[TierValues.Length - 1];
			`log("Tier" @ Idx $ ":" @ TierValues[TierValues.Length - 1],,'XCom_HitRolls');
		}
		//  Normalize the tier values
		for (Idx = 0; Idx < TierValues.Length; ++Idx)
		{
			TierValues[Idx] = TierValues[Idx] / TierValueSum;
			if (Idx > 0)
				TierValues[Idx] += TierValues[Idx - 1];

			`log("Normalized Tier" @ Idx $ ":" @ TierValues[Idx],,'XCom_HitRolls');
		}
		RandRoll = `SYNC_FRAND;
		`log("Random roll:" @ RandRoll,,'XCom_HitRolls');
		for (Idx = 0; Idx < TierValues.Length; ++Idx)
		{
			if (RandRoll < TierValues[Idx])
			{
				`log("Matched tier" @ Idx,,'XCom_HitRolls');
				return Idx + 1;     //  the lowest possible tier is 1, not 0
			}
		}
		`log("Matched highest tier",,'XCom_HitRolls');
		return TierValues.Length;
	}
	return 0;
}

protected function int GetHighestTierPossible(const array<X2Effect> TargetEffects)
{
	local int Highest, Idx;

	Highest = -1;
	for (Idx = 0; Idx < TargetEffects.Length; ++Idx)
	{
		//  ignore a minimum of 0 as the effect should always be applied
		if (TargetEffects[Idx].MinStatContestResult > 0 && TargetEffects[Idx].MinStatContestResult > Highest)
			Highest = TargetEffects[Idx].MinStatContestResult;

		//  ignore a maximum of 0 as the effect should always be applied (assuming min is also 0, but if it isn't, then that was already checked above)
		if (TargetEffects[Idx].MaxStatContestResult > 0 && TargetEffects[Idx].MaxStatContestResult > Highest)
			Highest = TargetEffects[Idx].MaxStatContestResult;
	}
	return Highest;
}

DefaultProperties
{
	BaseValue = 50
}