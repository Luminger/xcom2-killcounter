class X2AbilityArmorHitRolls extends Object 
	native(Core)
	config(GameCore);

var config int HIGH_COVER_ARMOR_CHANCE;
var config int LOW_COVER_ARMOR_CHANCE;

//  Rolls all mitigation types specified in Armor and flags all successful rolls in Results.
static event RollArmorMitigation(const out ArmorMitigationResults Armor, out ArmorMitigationResults Results, XComGameState_Unit UnitState)
{
	local int RandRoll, Chance;
	local XComGameStateHistory History;
	local StateObjectReference EffectRef;
	local XComGameState_Effect EffectState;
	local X2Effect_BonusArmor ArmorEffect;

	`log("  " $ GetFuncName() $ "  ",,'XCom_HitRolls');

	//  Natural armor
	Chance = UnitState.GetCurrentStat(eStat_ArmorChance);
	if (Chance > 0)
	{
		Results.bNaturalArmor = DoRoll(Chance, RandRoll);
		`log("NaturalArmor chance was" @ Chance @ "rolled" @ RandRoll @ "SUCCESS!", Results.bNaturalArmor, 'XCom_HitRolls');
		`log("NaturalArmor chance was" @ Chance @ "rolled" @ RandRoll @ "Failed.", !Results.bNaturalArmor, 'XCom_HitRolls');
	}

	if (UnitState.AffectedByEffects.Length > 0)
	{
		History = `XCOMHISTORY;
		foreach UnitState.AffectedByEffects(EffectRef)
		{
			EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
			ArmorEffect = X2Effect_BonusArmor(EffectState.GetX2Effect());
			if (ArmorEffect != none)
			{
				Chance = ArmorEffect.GetArmorChance(EffectState, UnitState);
				if (DoRoll(Chance, RandRoll))
				{
					Results.BonusArmorEffects.AddItem(EffectRef);
					`log("BonusArmorEffect" @ ArmorEffect.GetArmorName(EffectState, UnitState) @ "chance was" @ Chance @ "rolled" @ RandRoll @ "SUCCESS!", true, 'XCom_HitRolls');
				}
				else
				{
					`log("BonusArmorEffect" @ ArmorEffect.GetArmorName(EffectState, UnitState) @ "chance was" @ Chance @ "rolled" @ RandRoll @ "Failed.", true, 'XCom_HitRolls');
				}
			}
		}
	}
}

static function bool DoRoll(int Chance, out int RandRoll)
{
	RandRoll = `SYNC_RAND_STATIC(100);
	return RandRoll <= Chance;
}