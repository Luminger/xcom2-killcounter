class KillCounter_Utils extends Object;

static function bool IsShadowChamberBuild()
{
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	return XComHQ.GetFacilityByName('ShadowChamber') != none;
}

static function int GetTotalEnemies(bool skipTurrets)
{
	local int iTotal, iPrevSeen, iPrevKilled;
	local array<XComGameState_Unit> arrUnits;

	GetOpponentUnits(arrUnits, skipTurrets);
	iTotal = arrUnits.Length;

	if(GetTransferMissionStats(iPrevSeen, iPrevKilled))
	{
		iTotal += iPrevSeen;
	}

	return iTotal;
}

static function int GetKilledEnemies(int historyIndex, bool skipTurrets)
{
	local int iKilled, iPrevSeen, iPrevKilled;
	local array<XComGameState_Unit> arrUnits;
	local XComGameState_Unit arrUnit, currentUnit;

	GetOpponentUnits(arrUnits, skipTurrets);
	ForEach arrUnits(arrUnit) 
	{
		currentUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(arrUnit.ObjectID, eReturnType_Reference, historyIndex));
		if(currentUnit == none)
		{
			continue;
		}

		if(currentUnit.IsDead()) 
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

static function int GetActiveEnemies(int historyIndex, bool skipTurrets)
{
	local int iActive, AlertLevel, DataID;
	local array<XComGameState_Unit> arrUnits;
	local XComGameState_Unit arrUnit, currentUnit;
	local XComGameState_AIUnitData AIData;
	local StateObjectReference KnowledgeRef;

	GetOpponentUnits(arrUnits, skipTurrets);
	ForEach arrUnits(arrUnit) 
	{
		currentUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(arrUnit.ObjectID, eReturnType_Reference, historyIndex));
		if(currentUnit == none)
		{
			continue;
		}

		// Code originates from XComGameState_AIGroup::IsEngaged()
		if(!currentUnit.IsAlive())
		{
			continue;
		}

		AlertLevel = currentUnit.GetCurrentStat(eStat_AlertLevel);
		if(AlertLevel == `ALERT_LEVEL_RED)
		{
			iActive++;
		}
		else if (AlertLevel == `ALERT_LEVEL_YELLOW)
		{
			DataID = currentUnit.GetAIUnitDataID();
			if( DataID > 0 )
			{
				AIData = XComGameState_AIUnitData(`XCOMHISTORY.GetGameStateForObjectID(DataID, eReturnType_Reference, historyIndex));
				if( AIData != none && AIData.HasAbsoluteKnowledge(KnowledgeRef) )  
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
	local XComGameState_BattleData BattleData;
	BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	if(BattleData.DirectTransferInfo.IsDirectMissionTransfer)
	{
		seen = BattleData.DirectTransferInfo.AliensSeen;
		killed = BattleData.DirectTransferInfo.AliensKilled;
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

static function bool IsGameStateInterrupted(int index)
{
	local XComGameState gameState;
	local XComGameStateContext context;

	gameState = `XCOMHISTORY.GetGameStateFromHistory(index);
	if(gameState == none)
	{
		return true;
	}

	context = gameState.GetContext();
	if(context == none)
	{
		return true;
	}

	// There are certain frames which are flagged as an Interrupt but at the
	// same time those don't have a ResumeHistoryIndex set. This causes them
	// to get handed to us even though they were interrupted. To fix this
	// possible missmatch we do not count those frame as 'interrupted' as 
	// this would mean that we do not expect to ever see them.
	return context.InterruptionStatus == eInterruptionStatus_Interrupt && context.ResumeHistoryIndex != -1;
}

static function KillCounter_UI GetUI()
{
	local UIScreen hud;
	local KillCounter_UI ui;

	hud = `PRES.GetTacticalHUD();
	if (hud == none)
	{
		return none;
	}

	ui = KillCounter_UI(hud.GetChild('KillCounter_UI'));

	if(ui == none)
	{
		ui = hud.Spawn(class'KillCounter_UI', hud);
		ui.InitPanel('KillCounter_UI');
	}

	return ui;
}

static function bool ShouldDrawTotalCount()
{
	local KillCounter_Settings settings;

	settings = new class'KillCounter_Settings';

	if(settings.alwaysShowEnemyTotal)
	{
		return true;
	}
	else if(settings.neverShowEnemyTotal) 
	{
		return false;
	} 

	return class'KillCounter_Utils'.static.IsShadowChamberBuild();
}

static function bool ShouldDrawActiveCount()
{
	local KillCounter_Settings settings;

	settings = new class'KillCounter_Settings';

	return settings.alwaysShowActiveEnemyCount;
}

static function bool ShouldSkipTurrets()
{
	local KillCounter_Settings settings;

	settings = new class'KillCounter_Settings';

	return !settings.includeTurrets;
}