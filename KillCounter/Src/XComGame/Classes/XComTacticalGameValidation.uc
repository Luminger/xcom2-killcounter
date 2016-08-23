//---------------------------------------------------------------------------
// Provides the correct ruleset to use for Challenge Mode verification
//---------------------------------------------------------------------------
class XComTacticalGameValidation extends XComTacticalGame;


simulated function class<X2GameRuleset> GetGameRulesetClass()
{
	return class'X2TacticalGameValidationRuleset';
}


//-----------------------------------------------------------
//-----------------------------------------------------------
defaultproperties
{

}
