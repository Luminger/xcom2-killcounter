class X2Effect_VolatileMix extends X2Effect_Persistent;

var int BonusDamage;

function int GetAttackingDamageModifier(XComGameState_Effect EffectState, XComGameState_Unit Attacker, Damageable TargetDamageable, XComGameState_Ability AbilityState, const out EffectAppliedData AppliedData, const int CurrentDamage)
{
	local XComGameState_Item SourceWeapon;
	local X2ItemTemplate SourceWeaponAmmoTemplate;

	SourceWeapon = AbilityState.GetSourceWeapon();

	if (SourceWeapon != none)
	{
		if (SourceWeapon.GetWeaponCategory() == 'grenade')
			return BonusDamage;

		SourceWeaponAmmoTemplate = SourceWeapon.GetLoadedAmmoTemplate(AbilityState);
		if (SourceWeaponAmmoTemplate != none && X2WeaponTemplate(SourceWeaponAmmoTemplate) != none)
		{
			if (X2WeaponTemplate(SourceWeaponAmmoTemplate).WeaponCat == 'grenade')
			{
				return BonusDamage;
			}
		}
	}
	return 0;
}

DefaultProperties
{
	DuplicateResponse = eDupe_Ignore
}