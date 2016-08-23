
//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIResistanceReport
//  AUTHOR:  Brit Steiner 
//  PURPOSE: Shows end of month information summary.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 


class UIResistanceReport extends UIX2SimpleScreen;

var localized String m_strReportTitle;
var localized String m_strResistanceActivity;
var localized String m_strAlienActivity;
var localized String m_strSupplyTitle;
var localized String m_strSupplyLossTitle; 
var localized String m_strBonusSupply;
var localized String m_strResistanceReportGreeble;
var localized String m_strAvatarProgressLabel;
var localized String m_strStaffingHelp; 
var localized String m_strDarkEventPenalty; 
var localized String m_strStaffAvailable;

var UILargeButton ContinueButton;

var name DisplayTag;
var string CameraTag;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	super.InitScreen(InitController, InitMovie, InitName);
	UpdateNavHelp();
	BuildScreen();

	class'UIUtilities_Sound'.static.PlayOpenSound();
	
	//TODO: Leave geoscape? 

	class'UIUtilities'.static.DisplayUI3D(DisplayTag, name(CameraTag), `SCREENSTACK.IsInStack(class'UIStrategyMap') ? 0.0 : `HQINTERPTIME);
	
	if (class'UIUtilities_Strategy'.static.GetXComHQ().GetObjectiveStatus('T5_M1_AutopsyTheAvatar') != eObjectiveState_Completed)
	{
		`XCOMGRI.DoRemoteEvent('CIN_ShowCouncil');
		TriggerResistanceMoraleVO(); // Trigger the council spokesman's remarks
	}
	else
	{
		`XCOMGRI.DoRemoteEvent('CIN_ShowResistance');
	}

	`HQPRES.m_kAvengerHUD.FacilityHeader.Hide();
}

function TriggerResistanceMoraleVO()
{
	local XComGameState NewGameState;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Monthly Report Event");
	`XEVENTMGR.TriggerEvent(RESHQ().GetResistanceMoodEvent(), , , NewGameState);
	`GAMERULES.SubmitGameState(NewGameState);
}

//-------------- UI LAYOUT --------------------------------------------------------

simulated function BuildScreen()
{
	AS_UpdateCouncilReportCardInfo(m_strReportTitle, GetDateString(), m_strResistanceReportGreeble);

	UpdateCouncilReportCardRewards();
	UpdateResistanceActivity();
	UpdateCouncilReportCardStaff();
	UpdateAlienActivity();
	UpdateAvatarProgress();
	
	MC.FunctionVoid("AnimateIn");
}

simulated function UpdateCouncilReportCardRewards()
{
	local XComGameState_HeadquartersResistance ResistanceHQ;
	local bool bIsPositiveMonthly; 

	ResistanceHQ = RESHQ();
	bIsPositiveMonthly = (ResistanceHQ.GetSuppliesReward(true) > 0);

	MC.BeginFunctionOp("UpdateCouncilReportCardRewards");
	MC.QueueString(bIsPositiveMonthly ? m_strSupplyTitle : m_strSupplyLossTitle);
	MC.QueueString(GetSupplyRewardString());
	MC.QueueBoolean(bIsPositiveMonthly);

	// All In Bonus
	if( ResistanceHQ.SupplyDropPercentIncrease > 0 )
	{
		MC.QueueString(m_strBonusSupply);
		MC.QueueString("+" $ ResistanceHQ.SupplyDropPercentIncrease $ "%");
	}
	else
	{
		MC.QueueString("");
		MC.QueueString("");
	}

	// Rural Checkpoints Dark Event
	if( ResistanceHQ.SavedSupplyDropPercentDecrease > 0 )
	{
		MC.QueueString(m_strDarkEventPenalty);
		MC.QueueString("-" $ Round(ResistanceHQ.SavedSupplyDropPercentDecrease * 100.0) $ "%");
	}
	else
	{
		MC.QueueString("");
		MC.QueueString("");
	}

	MC.EndOp();
}

simulated function UpdateCouncilReportCardStaff()
{
	local XComGameStateHistory History;
	local array<StateObjectReference> PersonnelRewards;
	local XComGameState_Reward ResReward;
	local array<string> arrNewStaffNames;
	local string strStaffName;
	local int idx;

	History = `XCOMHISTORY;
	PersonnelRewards = RESHQ().PersonnelGoods;
	for (idx = 0; idx < 3; idx++)
	{
		ResReward = XComGameState_Reward(History.GetGameStateForObjectID(PersonnelRewards[idx].ObjectID));
		strStaffName = class'X2StrategyElement_DefaultRewards'.static.GetPersonnelName(ResReward);
		arrNewStaffNames.AddItem(strStaffName);
	}
	
	AS_UpdateCouncilReportCardStaff(m_strStaffAvailable, arrNewStaffNames[0], arrNewStaffNames[1], arrNewStaffNames[2], m_strStaffingHelp);
}

simulated function UpdateResistanceActivity()
{
	local array<TResistanceActivity> arrActions;
	local String strAction, strActivityList;
	local int iAction;

	arrActions = RESHQ().GetMonthlyActivity();
	
	for( iAction = 0; iAction < arrActions.Length; iAction++ )
	{
		strAction = class'UIUtilities_Text'.static.GetColoredText(arrActions[iAction].Title @ string(arrActions[iAction].Count), arrActions[iAction].Rating);
		strActivityList $= strAction;
		if (iAction < arrActions.Length - 1)
		{
			strActivityList $= ", ";
		}
	}

	AS_UpdateCouncilReportCardResistanceActivity(m_strResistanceActivity, strActivityList);
}

simulated function UpdateAlienActivity()
{
	local array<TResistanceActivity> arrActions;
	local String strAction, strActivityList;
	local int iAction;

	arrActions = RESHQ().GetMonthlyActivity(true);

	for (iAction = 0; iAction < arrActions.Length; iAction++)
	{
		strAction = class'UIUtilities_Text'.static.GetColoredText(arrActions[iAction].Title @ string(arrActions[iAction].Count), arrActions[iAction].Rating);
		
		strActivityList $= strAction;
		if (iAction < arrActions.Length - 1)
		{
			strActivityList $= ", ";
		}
	}

	AS_UpdateCouncilReportCardAlienActivity(m_strAlienActivity, strActivityList);
}
simulated function UpdateAvatarProgress()
{
	if (!ALIENHQ().bHasSeenDoomMeter)
	{
		AS_UpdateCouncilReportCardAvatarProgress("", -1);
	}
	else
	{
		AS_UpdateCouncilReportCardAvatarProgress(m_strAvatarProgressLabel, ALIENHQ().GetCurrentDoom());
	}
}

//-------------- EVENT HANDLING ----------------------------------------------------------
simulated function OnContinue()
{
	CloseScreen();
}

simulated function UpdateNavHelp()
{
	if( HQPRES() != none )
	{
		HQPRES().m_kAvengerHUD.NavHelp.ClearButtonHelp();
		HQPRES().m_kAvengerHUD.NavHelp.AddContinueButton(OnContinue);
	}
}

simulated function CloseScreen()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersResistance ResistanceHQ;

	// Reset the monthly resistance activities
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Reset Monthly Resistance Activities");
	ResistanceHQ = XComGameState_HeadquartersResistance(NewGameState.CreateStateObject(class'XComGameState_HeadquartersResistance', RESHQ().ObjectID));
	NewGameState.AddStateObject(ResistanceHQ);
	ResistanceHQ.ResetActivities();
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	`XANALYTICS.SendCampaign();
	HQPRES().m_kAvengerHUD.NavHelp.ClearButtonHelp();
	super.CloseScreen();
	
	HQPRES().UIAdventOperations(true);
}

simulated function Remove()
{
	super.Remove();
	`XCOMGRI.DoRemoteEvent('CIN_HideCouncil');
	`XCOMGRI.DoRemoteEvent('CIN_HideResistance');
}

//-------------- GAME DATA HOOKUP --------------------------------------------------------

simulated function String GetDateString()
{
	return class'X2StrategyGameRulesetDataStructures'.static.GetDateString(`GAME.GetGeoscape().m_kDateTime);
}

simulated function String GetSupplyRewardString()
{
	local int SuppliesReward;
	local string Prefix;

	SuppliesReward = RESHQ().GetSuppliesReward(true);
	
	if(SuppliesReward < 0)
	{
		SuppliesReward = 0;
	}

	Prefix = (SuppliesReward < 0) ? "-" : "+";
	return Prefix $ class'UIUtilities_Strategy'.default.m_strCreditsPrefix $ String(int(Abs(SuppliesReward)));
}

//-------------- FLASH DIRECT ACCESS --------------------------------------------------

simulated function AS_UpdateCouncilReportCardInfo(string strTitle, string strSubtitle, string strGreeble)
{
	MC.BeginFunctionOp("UpdateCouncilReportCardInfo");
	MC.QueueString(strTitle);
	MC.QueueString(strSubtitle);
	MC.QueueString(strGreeble);
	MC.EndOp();
}

simulated function AS_UpdateCouncilReportCardAlienActivity(string strTitle, string strDescription)
{
	MC.BeginFunctionOp("UpdateCouncilReportCardAlienActivity");
	MC.QueueString(strTitle);
	MC.QueueString(strDescription);
	MC.EndOp();
}

simulated function AS_UpdateCouncilReportCardResistanceActivity(string strTitle, string strDescription)
{
	MC.BeginFunctionOp("UpdateCouncilReportCardResistanceActivity");
	MC.QueueString(strTitle);
	MC.QueueString(strDescription);
	MC.EndOp();
}

simulated function AS_UpdateCouncilReportCardStaff(string strTitle, string strStaff0, string strStaff1, string strStaff2, string strHelpText)
{
	MC.BeginFunctionOp("UpdateCouncilReportCardStaff");
	MC.QueueString(strTitle);
	MC.QueueString(strStaff0);
	MC.QueueString(strStaff1);
	MC.QueueString(strStaff2);
	MC.QueueString(strHelpText);
	MC.EndOp();
}
simulated function AS_UpdateCouncilReportCardAvatarProgress(string strAvatarLabel, int numPips)
{
	MC.BeginFunctionOp("UpdateCouncilReportCardAvatarProgress");
	MC.QueueString(strAvatarLabel);
	MC.QueueNumber(numPips);
	MC.EndOp();
}

//------------------------------------------------------

defaultproperties
{
	Package = "/ package/gfxCouncilScreen/CouncilScreen";
	LibID = "CouncilScreenReportCard";
	DisplayTag = "UIDisplay_Council"
	CameraTag = "UIDisplayCam_ResistanceScreen"
}
