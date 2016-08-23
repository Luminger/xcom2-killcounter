class X2Effect_BonusArmor extends X2Effect_Persistent abstract;

function int GetArmorChance(XComGameState_Effect EffectState, XComGameState_Unit UnitState) { return 0; }
function int GetArmorMitigation(XComGameState_Effect EffectState, XComGameState_Unit UnitState) { return 0; }
function string GetArmorName(XComGameState_Effect EffectState, XComGameState_Unit UnitState) { return FriendlyName; }