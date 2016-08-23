class X2AbilityMultiTarget_Cone extends X2AbilityMultiTarget_Radius native(Core);

var float ConeEndDiameter;
var float ConeLength;
var bool bUseWeaponRangeForLength;

native function float GetConeLength(const XComGameState_Ability Ability);
simulated native function GetValidTilesForLocation(const XComGameState_Ability Ability, const vector Location, out array<TTile> ValidTiles);

//Return the Valid Uncollided tiles into ValidTiles and everything else into InValidTiles
simulated native function GetCollisionValidTilesForLocation(const XComGameState_Ability Ability, const vector Location, out array<TTile> ValidTiles, out array<TTile> InValidTiles);