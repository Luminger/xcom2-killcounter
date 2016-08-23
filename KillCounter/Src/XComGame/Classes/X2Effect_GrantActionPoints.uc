class X2Effect_GrantActionPoints extends X2Effect;

var int NumActionPoints;
var name PointType;

simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit UnitState;
	local int i;

	UnitState = XComGameState_Unit(kNewTargetState);
	if (UnitState != none)
	{
		for (i = 0; i < NumActionPoints; ++i)
		{
			UnitState.ActionPoints.AddItem(PointType);
		}		
	}
}