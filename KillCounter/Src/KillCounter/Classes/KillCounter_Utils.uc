class KillCounter_Utils extends Object;

static function bool IsShadowChamberBuild()
{
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	return XComHQ.GetFacilityByName('ShadowChamber') != none;
}

static function int GetTotalEnemies()
{
	local int iTotal, iPrevSeen, iPrevKilled;
	local array<XComGameState_Unit> arrUnits;

	GetOpponentUnits(arrUnits, true);
	iTotal = arrUnits.Length;

	if(GetTransferMissionStats(iPrevSeen, iPrevKilled))
	{
		iTotal += iPrevSeen;
	}

	return iTotal;
}

static function int GetKilledEnemies()
{
	local int iKilled, iPrevSeen, iPrevKilled;
	local array<XComGameState_Unit> arrUnits;
	local XComGameState_Unit arrUnit;

	GetOpponentUnits(arrUnits, true);
	ForEach arrUnits(arrUnit) 
	{
		if(arrUnit.IsDead()) 
		{
			iKilled++;
		}
	}

	if(GetTransferMissionStats(iPrevSeen, iPrevKilled))
	{
		iKilled += iPrevKilled;
	}

	return iKilled;
}

static function int GetActiveEnemies()
{
	local int iActive, AlertLevel;
	local array<XComGameState_Unit> arrUnits;
	local XComGameState_Unit arrUnit;

	GetOpponentUnits(arrUnits, false);
	ForEach arrUnits(arrUnit) 
	{
		// Code originates from XComGameState_AIGroup::IsEngaged()
		if(arrUnit.IsAlive())
		{
			AlertLevel = arrUnit.GetCurrentStat(eStat_AlertLevel);
			if (AlertLevel >= `ALERT_LEVEL_YELLOW)
			{
				iActive++;
			}
		}
	}

	return iActive;
}

static function bool GetTransferMissionStats(out int seen, out int killed)
{
	local XComGameState_BattleData StaticBattleData;
	StaticBattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	if(StaticBattleData.DirectTransferInfo.IsDirectMissionTransfer)
	{
		seen = StaticBattleData.DirectTransferInfo.AliensSeen;
		killed = StaticBattleData.DirectTransferInfo.AliensKilled;
		return true;
	}
	
	seen = 0;
	killed = 0;
	return false;
}

static function GetOpponentUnits(out array<XComGameState_Unit> arrUnits, bool skipTurrets = false)
{
	local XComGameState_BattleData StaticBattleData;
	local XGBattle_SP Battle;

	Battle = XGBattle_SP(`BATTLE);

	StaticBattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	if(StaticBattleData.IsMultiplayer())
	{
		Battle.GetEnemyPlayer(XComTacticalController(Battle.GetALocalPlayerController()).m_XGPlayer).GetOriginalUnits(arrUnits, skipTurrets);
	}
	else
	{
		Battle.GetAIPlayer().GetOriginalUnits(arrUnits, skipTurrets);
	}
}