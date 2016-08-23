//---------------------------------------------------------------------------------------
//  FILE:    X2PointOfInterestTemplate.uc
//  AUTHOR:  Joe Weinhoffer
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2PointOfInterestTemplate extends X2StrategyElementTemplate
	config(GameBoard);

var() bool								bStaffPOI; // Does this POI reward staff (Sci or Eng)?

// Data
var() config array<name>				RewardTypes;
var() config array<float>				RewardScalar;
var() config array<int>					MinRewardInstanceAmount; // The minimum number of times ALL of the reward types will be given (does not modify RewardState amount)
var() config array<int>					MaxRewardInstanceAmount; // The maximum number of times ALL of the reward types will be given (does not modify RewardState amount)
var() config array<int>					IsNeededAmount; // The amount at which this POI will flag itself as needed, and double its chances to appear

var() config array<POIWeight>			Weights; // Structs controlling the POI weight and how it changes during the game. The last entry will be used until game end.
var() config string						CompleteNarrative; // Plays when scanning complete

// Text
var localized array<string>				DisplayNames;
var localized array<string>				CompletedSummaries;
var localized array<string>				POIImages;

var() Delegate<CanAppearDelegate>		CanAppearFn;
var() Delegate<IsRewardNeededDelegate>	IsRewardNeededFn; // allows logical augmentation of POI availability. Used to indicate if the player desperately needs this POI

delegate bool CanAppearDelegate(XComGameState_PointOfInterest POIState);
delegate bool IsRewardNeededDelegate(XComGameState_PointOfInterest POIState);

function XComGameState_PointOfInterest CreateInstanceFromTemplate(XComGameState NewGameState)
{
	local XComGameState_PointOfInterest PointState;

	PointState = XComGameState_PointOfInterest(NewGameState.CreateStateObject(class'XComGameState_PointOfInterest'));	 
	PointState.OnCreation(self);

	return PointState;
}