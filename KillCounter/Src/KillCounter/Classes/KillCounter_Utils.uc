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
	local int iActive, AlertLevel, DataID;
	local array<XComGameState_Unit> arrUnits;
	local XComGameState_Unit arrUnit;
	local XComGameStateHistory History;
	local XComGameState_AIUnitData AIData;
	local StateObjectReference KnowledgeRef;

	History = `XCOMHISTORY;
	GetOpponentUnits(arrUnits, false);

	ForEach arrUnits(arrUnit) 
	{
		// Code originates from XComGameState_AIGroup::IsEngaged()
		if(!arrUnit.IsAlive())
		{
			continue;
		}

		AlertLevel = arrUnit.GetCurrentStat(eStat_AlertLevel);
		if(AlertLevel == `ALERT_LEVEL_RED)
		{
			iActive++;
		}
		else if (AlertLevel == `ALERT_LEVEL_YELLOW)
		{
			DataID = arrUnit.GetAIUnitDataID();
			if( DataID > 0 )
			{
				AIData = XComGameState_AIUnitData(History.GetGameStateForObjectID(DataID));
				if( AIData.HasAbsoluteKnowledge(KnowledgeRef) )  
				{
					iActive++;
				}
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

// This is a UnrealScript translation from the original ActionScript function.
// You can find it in the Components.SwfMoview within 'scripts/__Packages/Utilities'
// which is located in the gfxComponents.upk.
//
// Usage: Call this with your UIText element AFTER you've called InitText() on it!
static function ShadowToTextField(UIText panel)
{
	local string path;
	local UIMovie mov;
	path = string(panel.MCPath) $ ".text";
	mov = panel.Movie;

	mov.SetVariableString(path $ ".shadowStyle", "s{0,0}{0,0){0,0}t{0,0}");
	mov.SetVariableNumber(path $ ".shadowColor", 0);
	mov.SetVariableNumber(path $ ".shadowBlurX", 3);
	mov.SetVariableNumber(path $ ".shadowBlurY", 3);
	mov.SetVariableNumber(path $ ".shadowStrength", 15);
	mov.SetVariableNumber(path $ ".shadowAngle", 0);
	mov.SetVariableNumber(path $ ".shadowAlpha", 0.25);
	mov.SetVariableNumber(path $ ".shadowDistance", 0);
}

// This is a UnrealScript translation from the original ActionScript function.
// You can find it in the Components.SwfMoview within 'scripts/__Packages/Utilities'
// which is located in the gfxComponents.upk.
//
// Usage: Call this with your UIText element AFTER you've called InitText() on it!
static function OutlineTextField(UIText panel, int thickness)
{
	local string path;
	local UIMovie mov;
	path = string(panel.MCPath) $ ".text";
	mov = panel.Movie;

	mov.SetVariableString(path $ ".shadowStyle", "s{" $ thickness $ ",0}{0," $ 
		thickness $ "}{" $ thickness $ "," $ thickness $ "}{" $ -1 * thickness $
		",0}{0," $ -1 * thickness $ "}{" $ -1 * thickness $ "," $ -1 * thickness $
		"}{" $ thickness $ "," $ -1 * thickness $ "}{" $ -1 * thickness $ ","
		$ thickness $ "}t{0,0}");
	mov.SetVariableNumber(path $ ".shadowColor", 3552822);
	mov.SetVariableNumber(path $ ".shadowBlurX", 1);
	mov.SetVariableNumber(path $ ".shadowBlurY", 1);
	mov.SetVariableNumber(path $ ".shadowStrength", thickness);
	mov.SetVariableNumber(path $ ".shadowAngle", 0);
	mov.SetVariableNumber(path $ ".shadowAlpha", 0.5);
	mov.SetVariableNumber(path $ ".shadowDistance", 0);
}

// Used to find the above values. Kind of a mess, but does the job...
static function TestValueOnPanel(UIPanel panel, string prop)
{
	local ASValue val;
	local string fullpath;

	fullpath = string(panel.MCPath) $ "." $ prop;
	val = panel.Movie.GetVariable(fullpath);

	`Log("Path:" @ fullpath);
	if(val.Type == AS_Undefined)
	{
		`Log("Type:" @ val.Type);
	}
	else if (val.Type == AS_Null)
	{
		`Log("Type:" @ val.Type);
	}
	else if (val.Type == AS_Boolean)
	{
		`Log("Type:" @ val.Type @ "Value:" @ val.b);
	}
	else if (val.Type == AS_Number)
	{
		`Log("Type:" @ val.Type @ "Value:" @ val.n);
	}
	else if (val.Type == AS_String)
	{
		`Log("Type:" @ val.Type @ "Value:" @ val.s);
	}
}