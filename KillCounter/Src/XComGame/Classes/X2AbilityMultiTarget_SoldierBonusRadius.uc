class X2AbilityMultiTarget_SoldierBonusRadius extends X2AbilityMultiTarget_Radius native(Core);

var name SoldierAbilityName;
var float BonusRadius;          //  flat bonus added to normal fTargetRadius

simulated native function float GetTargetRadius(const XComGameState_Ability Ability);