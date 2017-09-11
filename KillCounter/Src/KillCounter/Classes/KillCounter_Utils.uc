class KillCounter_Utils extends Object;

// As we want to be backward compatible, we can't use eTeam_TheLost directly.
// The value is defined in the Object.uc, with the value 32. This shouldn't ever
// change (*cough* famous last words)
const TeamTheLost = 32;

static function bool IsShadowChamberBuild()
{
	local XComGameState_HeadquartersXCom XComHQ;

	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	return XComHQ.GetFacilityByName('ShadowChamber') != none;
}

static function GetCounters(int historyIndex, bool skipTurrets, out int killed, out int killedLost, out int active, out int total)
{
	local XGBattle battle;
	local XGPlayer localPlayer, otherPlayer;
	local array <XComGameState_Unit> arrUnits;
	local int i, iPrevSeen, iPrevKilled;

	battle = `BATTLE;
	localPlayer = battle.GetLocalPlayer();

	// Initialized to -1 as it's used as an draw indicator in the UI; if it stays
	// -1 than there's no point in drawing the lost counter as it will never show
	// anything (as it won't in XCOM2 Classic or in WotC missions where TheLost
	// aren't present).
	killedLost = -1;

	for(i = 0; i < battle.m_iNumPlayers; i++)
	{
		otherPlayer = battle.m_arrPlayers[i];
		if(!localPlayer.IsEnemy(otherPlayer)) {
			continue;
		}

		arrUnits.Length = 0;
		otherPlayer.GetOriginalUnits(arrUnits, skipTurrets);

		if(otherPlayer.m_ETeam == TeamTheLost)
		{
			killedLost += GetKilledTeamUnits(historyIndex, arrUnits);
			continue;
		}

		total += arrUnits.Length;
		killed += GetKilledTeamUnits(historyIndex, arrUnits);
		Active += GetActiveTeamUnits(historyIndex, arrUnits);
	}

	if(GetTransferMissionStats(iPrevSeen, iPrevKilled))
	{
		total += iPrevSeen;
		killed += iPrevKilled;
	}
}

static function int GetKilledTeamUnits(int historyIndex, array<XComGameState_Unit> arrUnits)
{
	local int iKilled;
	local XComGameState_Unit arrUnit, currentUnit;

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

	return iKilled;
}

static function int GetActiveTeamUnits(int historyIndex, array<XComGameState_Unit> arrUnits)
{
	local int iActive, AlertLevel, DataID;
	local XComGameState_Unit arrUnit, currentUnit;
	local XComGameState_AIUnitData AIData;
	local StateObjectReference KnowledgeRef;
	
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