//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_HeadquartersXCom.uc
//  AUTHOR:  Ryan McFall  --  02/18/2014
//  PURPOSE: This object represents the instance data for X-Com's HQ in the 
//           X-Com 2 strategy game
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class XComGameState_HeadquartersXCom extends XComGameState_Airship 
	native(Core) 
	config(GameData)
	DependsOn(XGMissionControlUI, XComGameState_ObjectivesList);

// Ship State Vars
var() StateObjectReference          StartingRegion;//Region in which the X-Com HQ started
var() StateObjectReference			CurrentLocation; // Geoscape entity where the Avenger is currently located or scanning
var() StateObjectReference			StartingHaven;
var() StateObjectReference			SavedLocation; // Used during UFO attacks to store where the Avenger was located

// Base Vars and Lists
var() array<StateObjectReference>   Rooms; //List of rooms within the X-Com HQ.
var() array<StateObjectReference>   Facilities; //Facilities in the HQ
var() privatewrite array<StateObjectReference> Crew;	//All Avenger crew members, including soldiers. Gameplay-important crew - ie. engineers, scientists, soldiers
var() privatewrite array<StateObjectReference> Clerks;	//Cosmetic crew members who are populated into rooms when the rooms are staffed.
var() array<StateObjectReference>   DeadCrew;   //The fallen. *gentle weeping*
var() array<StateObjectReference>   TechsResearched; // All Techs that have been researched by XCom
var() array<StateObjectReference>   Inventory; // XCom Item and Resource inventory
var() array<StateObjectReference>	LootRecovered;
var() array<StateObjectReference>   Projects; // All Headquarters projects (tech, item, facility, repair, etc.)
var() array<StateObjectReference>   Squad; // Which soldiers are selected to go an a mission
var() array<name>                   SoldierClassDeck;   //Soldier classes to randomly pick from when a soldier ranks up.
var() array<SoldierClassCount>		SoldierClassDistribution;
var() array<StateObjectReference>   MalfunctionFacilities;
var() protectedwrite array<name>    SoldierUnlockTemplates;  //  Purchased unlocks
var() protectedwrite array<name>	SavedSoldierUnlockTemplates; // The list of purchased unlocks which is saved if the GTS is deleted
var() StateObjectReference			SkyrangerRef; // The drop ship
var() array<name>					UnlockedItems; // Blocked items that are available for build now
var() int                           HighestSoldierRank;
var() array<HQOrder>				CurrentOrders; // Personnel on order to be delivered to HQ

var() array<Name>					EverAcquiredInventoryTypes; // list (and counts) of all inventory ever acquired by the hq
var() array<int>					EverAcquiredInventoryCounts; // list (and counts) of all inventory ever acquired by the hq

// Generic String to Int mapping used by kismet actions to store persistent data
var native Map_Mirror GenericKVP { TMap<FString, INT> };

struct native AmbientNarrativeInfo
{
	var string QualifiedName;
	var int PlayCount;
};

var() array<AmbientNarrativeInfo>    PlayedAmbientNarrativeMoments;  // used for track which ambient narrative moments we've played
var() array<AmbientNarrativeInfo>	 PlayedLootNarrativeMoments; // used for recovered items
var() array<AmbientNarrativeInfo>	 PlayedArmorIntroNarrativeMoments; // used for armor intros

var() array<string>	PlayedTacticalNarrativeMomentsCurrentMapOnly;

// The Geoscape Entity that the user has selected as their target.
var StateObjectReference			SelectedDestination;
var StateObjectReference			CrossContinentMission; // Store the mission if clicked on from different continent


// Mission Data
var() array<GeneratedMissionData>   arrGeneratedMissionData;    //  When a mission is selected in the UI, its generated data is stored here to live through squad selection etc.

var() array<Name>					TacticalGameplayTags;	// A list of Tags representing modifiers to the tactical game rules

// Power Vars
var() EPowerState                   PowerState; // Power state affects how some facilities function

// Healing Vars
var() int							HealingRate;

// Proving Ground Vars
var() int							ProvingGroundRate;

// Psi Chamber Vars
var() int							PsiTrainingRate;

// Construction Vars
var() int							ConstructionRate;

// Movie Flags
var() bool                          bDontShowSetupMovies;       // flag for setup phase movies
var() bool                          bHasVisitedEngineering; // flag for playing movie
var() bool                          bHasVisitedLabs;        // flag for playing movie
var() bool                          bJustWentOnFirstMission; // flag for playing movie
var() bool							bHasSeenFirstGrenadier;
var() bool							bHasSeenFirstPsiOperative;
var() bool							bHasSeenFirstRanger;
var() bool							bHasSeenFirstSharpshooter;
var() bool							bHasSeenFirstSpecialist;
var() bool							bHasSeenWelcomeResistance;
var() bool							bNeedsToSeeFinalMission;
var() array<name>					SeenCharacterTemplates;	//This list contains a list of character template groups that X-Com has seen during their campaign

var() bool							bTutorial;
var() bool							bHasPlayedAmbushTutorial;
var() bool							bHasPlayedMeleeTutorial;
var() bool							bHasPlayedNeutralizeTargetTutorial;
var() bool							bBlockObjectiveDisplay;

// UFO Chase
var() bool							bUFOChaseInProgress;
var() int							UFOChaseLocationsCompleted;
var() StateObjectReference			AttackingUFO;

// Popup flags
var() bool							bReturningFromMission;
var() bool							bHasSeenWeaponUpgradesPopup;
var() bool							bHasSeenCustomizationsPopup;
var() bool							bHasSeenPsiLabIntroPopup;
var() bool							bHasSeenPsiOperativeIntroPopup;
var() bool							bHasSeenLowIntelPopup;
var() bool							bHasSeenLowSuppliesPopup;
var() bool							bHasSeenLowScientistsPopup;
var() bool							bHasSeenLowEngineersPopup;
var() bool							bHasSeenSupplyDropReminder;
var() bool							bHasSeenPowerCoilShieldedPopup;

// Upgrade Vars
var() bool                          bSurgeProtection;
var() int                           SurgeProtectionReduction;
var() bool                          bModularWeapons;
var() bool							bPsiSoldiers;

// Region Bonus Flags
var() bool							bQuickStudy;
var() bool							bCrunchTime;
var() bool							bIntoTheShadows;
var() bool							bSpreadTheWord;
var() bool							bConfoundTheEnemy;
var() bool							bScavengers;

// To Do Widget Warnings
var() bool							bPlayedWarningNoResearch;
var() bool							bPlayedWarningUnstaffedEngineer;
var() bool							bPlayedWarningUnstaffedScientist;
var() bool							bPlayedWarningNoIncome;

// Modifiers
var int								ResearchEffectivenessPercentIncrease; // PursuitOfKnowledge Continent Bonus
var int								EngineeringEffectivenessPercentIncrease; // HigherLearning Continent Bonus
var int								ProvingGroundPercentDiscount;
var int								GTSPercentDiscount;
var int								PowerOutputBonus; // HiddenReserves Continent Bonus
var bool							bLabBonus; // PursuitOfKnowledge Continent Bonus
var bool							bInstantAutopsies; // Xenobiology Continent Bonus
var bool							bInstantArmors; // SuitUp Continent Bonus
var bool							bInstantRandomWeapons; // FireWhenReady Continent Bonus
var bool							bReducedContact; // From POI Reward
var float							ReducedContactModifier; // From POI Reward - Percentage cost decreased
var bool							bFreeContact; // SignalFlare Continent Bonus
var bool							bUsedFreeContact; // if false allows player to use free contact on signal flare deactivation->reactivation
var bool							bExtraEngineer; // HelpingHand Continent Bonus
var bool							bReuseUpgrades; // LockAndLoad Continent Bonus
var bool							bExtraWeaponUpgrade; // ArmedToTheTeeth ContinentBonus
var int								BonusScienceScore;
var int								BonusEngineeringScore;
var int								BonusPowerProduced;
var int								BonusCommCapacity;

// scanning modifier
var float							CurrentScanRate; // how fast the Avenger scans, with a default of 1.0
var TDateTime						ResetScanRateEndTime;

// Staff XP Timer
var TDateTime						StaffXPIntervalEndTime;
var TDateTime						LowScientistPopupTime;
var TDateTime						LowEngineerPopupTime;

// FLAG OF ULTIMATE VICTORY
var() bool							bXComFullGameVictory;

// Timed Loot Weight
var float							AdventLootWeight;
var float							AlienLootWeight;

// Reference to a new staff members that we are currently waiting for a photograph of
var private array<StateObjectReference>   NewStaffRefs;

// The region name of the next lead available to be acquired
var Name NextAvailableFacilityLeadRegion;

// Tutorial Soldier
var StateObjectReference TutorialSoldier;

var() StateObjectReference MissionRef;
var() bool bSimCombatVictory;

// Landing site map
var string LandingSiteMap;

// Localized strings
var localized string strETAInstant;
var localized string strETADay;
var localized string strETADays;
var localized string strErrInsufficientData;
var localized string strCostLabel;
var localized string strCostData;
var localized string strNoScientists;
var localized string strStaffArrived;

// Event Strings
var localized string ProjectPausedLabel;
var localized string ResearchEventLabel;
var localized string ItemEventLabel;
var localized string ProvingGroundEventLabel;
var localized string FacilityEventLabel;
var localized string UpgradeEventLabel;
var localized string PsiTrainingEventLabel;
var localized string SupplyDropEventLabel;
var localized string MissionBuildEventLabel;
var localized string ShadowEventLabel;
var localized string MakingContactEventLabel;
var localized string BuildingHavenEventLabel;
var localized string StaffOrderEventLabel;
var localized string TrainRookieEventLabel;
var localized string RespecSoldierEventLabel;

// Tutorial Strings
var localized string DeadTutorialSoldier1CauseOfDeath;
var localized string DeadTutorialSoldier1Epitaph;
var localized string DeadTutorialSoldier2CauseOfDeath;
var localized string DeadTutorialSoldier2Epitaph;


// Config Vars
var config ECharacterPoolSelectionMode InitialSoldiersCharacterPoolSelectionMode;
var config ECharacterPoolSelectionMode RewardUnitCharacterPoolSelectionMode;
var config int XComHeadquarters_NumToRemoveFromSoldierDeck;
var config int XComHeadquarters_NumRooms;
var config int XComHeadquarters_RoomRowLength;
var config int XComHeadquarters_MinGridIndex;
var config int XComHeadquarters_MaxGridIndex;
var config Vector XComHeadquarters_RoomUIOffset;

var config int NumClerks_ActOne;
var config int NumClerks_ActTwo;
var config int NumClerks_ActThree;

var config array<int> XComHeadquarters_StartingValueSupplies;
var config array<int> XComHeadquarters_StartingValueIntel;
var config array<int> XComHeadquarters_StartingValueAlienAlloys;
var config array<int> XComHeadquarters_StartingValueEleriumCrystals;

var config int XComHeadquarters_BaseHealRate; // Not difficulty adjusted, Wound times adjusted instead

var config array<int> XComHeadquarters_ShakenChance;
var config array<int> XComHeadquarters_ShakenRecoverMissionsRequired;
var config int XComHeadquarters_ShakenRecoverWillBonus;
var config int XComHeadquarters_ShakenRecoverWillRandBonus;

var config float XComHeadquarters_YellowPowerStatePercent;
var config int XComHeadquarters_SoldierWarningNumber;

var config int XComHeadquarters_DefaultConstructionWorkPerHour;
var config int XComHeadquarters_DefaultProvingGroundWorkPerHour;
var config int XComHeadquarters_DefaultPsiTrainingWorkPerHour;
var config array<int> XComHeadquarters_DefaultTrainRookieDays;
var config array<int> XComHeadquarters_DefaultRespecSoldierDays;
var config array<int> XComHeadquarters_PsiTrainingDays;
var config array<float> PsiTrainingRankScalar;

var config int XComHeadquarters_StartingScienceScore;
var config int XComHeadquarters_StartingEngineeringScore;
var config array<int> XComHeadquarters_StartingPowerProduced; // Changes based on difficulty might be better in powercore template
var config array<int> XComHeadquarters_StartingCommCapacity;
var config int XComHeadquarters_MinAWCTalentRank; // Min eligible rank for a hidden talent to be placed (not grabbed from)
var config int XComHeadquarters_MaxAWCTalentRank; // Max eligible rank for a hidden talent to be placed (not grabbed from)

var config int UFOChaseLocations;
var config int UFOChaseChanceToSwitchContinent;

var config array<int> ResearchProgressDays_Fast;
var config array<int> ResearchProgressDays_Normal;
var config array<int> ResearchProgressDays_Slow;

var config array<int> StartingRegionSupplyDrop;
var config int MaxSoldierClassDifference;

var config int TimedLootPerMission;
var config float StartingAdventLootWeight;
var config float StartingAlienLootWeight;
var config float LootWeightIncrease;

var config array<int> PowerRelayOnCoilBonus;

var config array<float> StartingScientistMinCap;
var config array<float> ScientistMinCapIncrease;
var config array<float> StartingScientistMaxCap;
var config array<float> ScientistMaxCapIncrease;
var config array<int> ScientistNeverWarnThreshold; // never warn the player if they have this many scientists

var config array<float> StartingEngineerMinCap;
var config array<float> EngineerMinCapIncrease;
var config array<float> StartingEngineerMaxCap;
var config array<float> EngineerMaxCapIncrease;
var config array<int> EngineerNeverWarnThreshold; // never warn the player if they have this many engineers

var config int LowScientistPopupDays;
var config int LowEngineerPopupDays;

// Cost Scalars
var config array<StrategyCostScalar> RoomSpecialFeatureCostScalars;
var config array<StrategyCostScalar> FacilityBuildCostScalars;
var config array<StrategyCostScalar> FacilityUpgradeCostScalars;
var config array<StrategyCostScalar> ResearchCostScalars;
var config array<StrategyCostScalar> ProvingGroundCostScalars;
var config array<StrategyCostScalar> ItemBuildCostScalars;
var config array<StrategyCostScalar> OTSUnlockScalars;
var config array<StrategyCostScalar> MissionOptionScalars;

var config string ShakenIcon;

var config array<name> PossibleStartingRegions; // List of all possible starting regions
var config array<name> ResourceItems; // List of items which are resources and should never be removed from the inventory

// Tutorial Stuff
// Jane Kelly
var config EGender TutorialSoldierGender;
var config name TutorialSoldierCountry;
var config TAppearance TutorialSoldierAppearance;
var config name TutorialSoldierEnglishVoice;
var config name TutorialSoldierFrenchVoice;
var config name TutorialSoldierGermanVoice;
var config name TutorialSoldierItalianVoice;
var config name TutorialSoldierSpanishVoice;

// Peter Osei
var config EGender DeadTutorialSoldier1Gender;
var config name DeadTutorialSoldier1Country;
var config TAppearance DeadTutorialSoldier1Appearance;
var config int DeadTutorialSoldier1NumKills;

// Ana Ramirez
var config EGender DeadTutorialSoldier2Gender;
var config name DeadTutorialSoldier2Country;
var config TAppearance DeadTutorialSoldier2Appearance;
var config int DeadTutorialSoldier2NumKills;

var config array<name> TutorialExcludeSpecialRoomFeatures;
var config Vector TutorialStartingLocation; // Ghat Mountains in India
var config int TutorialExcavateIndex;
var config name TutorialFinishedObjective;
var config array<name> TutorialStartingItems; // You pick up a scope in the tutorial

//#############################################################################################
//----------------   INITIALIZATION   ---------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
static function SetUpHeadquarters(XComGameState StartState, optional bool bTutorialEnabled = false)
{	
	local int Index, i;
	local XComGameState_HeadquartersXCom HeadquartersStateObject;
	local XComGameState_HeadquartersRoom RoomStateObject;
	local array<XComGameState_HeadquartersRoom> LocalRooms;
	local X2FacilityTemplate FacilityTemplate;
	local array<X2StrategyElementTemplate> AllFacilityTemplates;
	local XComGameState_FacilityXCom FacilityStateObject;
	local XComGameState_GameTime TimeState;
	local XComGameState_Skyranger SkyrangerState;
	local XComGameState_Continent ContinentState;
	local XComGameState_Haven HavenState;
	
	//HQ location selection
	local int RandomIndex;
	local XComGameState_WorldRegion IterateRegion;
	local array<XComGameState_WorldRegion> AllStartingRegions, BestStartingRegions;
	local XComGameState_WorldRegion BaseRegion;
	local Vector ResHQLoc;

	//Create the HQ state object
	HeadquartersStateObject = XComGameState_HeadquartersXCom(StartState.CreateStateObject(class'XComGameState_HeadquartersXCom'));

	//Add the HQ state object to the start state
	StartState.AddStateObject(HeadquartersStateObject);

	HeadquartersStateObject.bTutorial = bTutorialEnabled;
	if (!HeadquartersStateObject.bTutorial)
	{
		HeadquartersStateObject.bHasPlayedAmbushTutorial = true;
		HeadquartersStateObject.bHasPlayedMeleeTutorial = true;
		HeadquartersStateObject.bHasSeenPowerCoilShieldedPopup = true;
	}
	else
	{
		HeadquartersStateObject.bBlockObjectiveDisplay = true;
	}

	//Pick which region the HQ will start in
	foreach StartState.IterateByClassType(class'XComGameState_WorldRegion', IterateRegion)
	{
		if (default.PossibleStartingRegions.Find(IterateRegion.GetMyTemplateName()) != INDEX_NONE)
		{
			AllStartingRegions.AddItem(IterateRegion);
		}

		// Try to find an optimal starting region
		if(IterateRegion.CanBeStartingRegion(StartState))
		{
			BestStartingRegions.AddItem(IterateRegion);
		}
	}

	if(BestStartingRegions.Length > 0)
	{
		RandomIndex = `SYNC_RAND_STATIC(BestStartingRegions.Length);
		BaseRegion = BestStartingRegions[RandomIndex];
	}
	else
	{
		RandomIndex = `SYNC_RAND_STATIC(AllStartingRegions.Length);
		BaseRegion = AllStartingRegions[RandomIndex];
	}
	
	HeadquartersStateObject.StartingRegion = BaseRegion.GetReference();
	HeadquartersStateObject.Region = BaseRegion.GetReference();
	BaseRegion.SetResistanceLevel(StartState, eResLevel_Outpost);
	BaseRegion.BaseSupplyDrop = HeadquartersStateObject.GetStartingRegionSupplyDrop();

	ContinentState = XComGameState_Continent(StartState.GetGameStateForObjectID(BaseRegion.Continent.ObjectID));
	HeadquartersStateObject.Continent = ContinentState.GetReference();
	HeadquartersStateObject.TargetEntity = HeadquartersStateObject.Continent;

	//Fill out the rooms in the HQ
	for(Index = 0; Index < default.XComHeadquarters_NumRooms; Index++)
	{
		RoomStateObject = XComGameState_HeadquartersRoom(StartState.CreateStateObject(class'XComGameState_HeadquartersRoom'));		
		RoomStateObject.OnCreation(StartState);
		RoomStateObject.MapIndex = Index;

		if (Index >= default.XComHeadquarters_MinGridIndex && Index <= default.XComHeadquarters_MaxGridIndex)
		{
			RoomStateObject.GridRow = (Index - default.XComHeadquarters_MinGridIndex) / default.XComHeadquarters_RoomRowLength;
		}
		else
		{
			RoomStateObject.GridRow = -1;
		}

		RoomStateObject.Locked = true; // All rooms start locked and require excavation to gain access
		HeadquartersStateObject.Rooms.AddItem(RoomStateObject.GetReference());//Add the new room to the HQ's list of rooms
		StartState.AddStateObject(RoomStateObject);
		LocalRooms.AddItem(RoomStateObject);
	}

	// Set up room adjacencies
	for (Index = 0; Index < LocalRooms.Length; Index++)
	{
		for (i = 1; i < LocalRooms.Length; i++)
		{
			if (class'X2StrategyGameRulesetDataStructures'.static.AreRoomsAdjacent(LocalRooms[Index], LocalRooms[i]))
			{
				LocalRooms[Index].AdjacentRooms.AddItem(LocalRooms[i].GetReference());
			}
		}
	}

	foreach StartState.IterateByClassType(class'XComGameState_GameTime', TimeState)
	{
		break;
	}
	`assert(TimeState != none);

	//Create the core facilities
	AllFacilityTemplates = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().GetAllTemplatesOfClass(class'X2FacilityTemplate');

	for( Index = 0; Index < AllFacilityTemplates.Length; ++Index )
	{
		FacilityTemplate = X2FacilityTemplate(AllFacilityTemplates[Index]);

		if(FacilityTemplate.bIsCoreFacility)
		{
			//Create the state object
			FacilityStateObject = FacilityTemplate.CreateInstanceFromTemplate(StartState);
			
			//Assign it to a room
			for(i = 0; i < LocalRooms.Length; i++)
			{
				RoomStateObject = LocalRooms[i];
				if(RoomStateObject.MapIndex == FacilityTemplate.ForcedMapIndex)
				{
					break;
				}
			}
			FacilityStateObject.Room = RoomStateObject.GetReference();     //Let the facility know what room it is in
			RoomStateObject.Facility = FacilityStateObject.GetReference(); //Let the room know there is a facility assigned to it

			//Record the construction date
			FacilityStateObject.ConstructionDateTime = TimeState.CurrentTime;
	
			//Add the new facility to the HQ's list of facilities
			HeadquartersStateObject.Facilities.AddItem(FacilityStateObject.GetReference());

			//Add the core facilities to the start state
			StartState.AddStateObject(FacilityStateObject);
		}
	}
	HeadquartersStateObject.BuildSoldierClassForcedDeck();

	// Set the Healing Rate
	HeadquartersStateObject.HealingRate = default.XComHeadquarters_BaseHealRate;

	// Set the Proving Ground Rate
	HeadquartersStateObject.ProvingGroundRate = default.XComHeadquarters_DefaultProvingGroundWorkPerHour;

	// Set the Psi Chamber Rate
	HeadquartersStateObject.PsiTrainingRate = default.XComHeadquarters_DefaultPsiTrainingWorkPerHour;

	// Set the Construction Rate
	HeadquartersStateObject.ConstructionRate = default.XComHeadquarters_DefaultConstructionWorkPerHour;

	// Set Starting Loot Rates
	HeadquartersStateObject.AdventLootWeight = default.StartingAdventLootWeight;
	HeadquartersStateObject.AlienLootWeight = default.StartingAlienLootWeight;

	//Create the starting staff
	CreateStartingSoldiers(StartState, bTutorialEnabled);
	CreateStartingEngineer(StartState);
	CreateStartingScientist(StartState);
	CreateStartingBradford(StartState);
	CreateStartingClerks(StartState);

	//Create the starting resources
	CreateStartingResources(StartState, bTutorialEnabled);

	//Create the room special features
	CreateRoomSpecialFeatures(StartState, bTutorialEnabled);

	// Create the Skyranger
	SkyrangerState = XComGameState_Skyranger(StartState.CreateStateObject(class'XComGameState_Skyranger'));
	StartState.AddStateObject(SkyrangerState);
	
	// Get Starting Location and set the starting location of Resistance HQ to match the HQ
	foreach StartState.IterateByClassType(class'XComGameState_Haven', HavenState)
	{
		if (HavenState.Region.ObjectID == BaseRegion.ObjectID)
		{
			HeadquartersStateObject.StartingHaven = HavenState.GetReference();

			if (bTutorialEnabled)
			{
				HeadquartersStateObject.Location = default.TutorialStartingLocation;
				HavenState.Location = GetStartingLocation(BaseRegion, HavenState, ResHQLoc);
			}
			else
			{
				HeadquartersStateObject.Location = GetStartingLocation(BaseRegion, HavenState, ResHQLoc);
				HavenState.Location = ResHQLoc;
			}

			HeadquartersStateObject.CurrentLocation = HavenState.GetReference();
			break; // We have found the resistance HQ haven
		}
	}
	
	HeadquartersStateObject.SourceLocation.X = HeadquartersStateObject.Location.X;
	HeadquartersStateObject.SourceLocation.Y = HeadquartersStateObject.Location.Y;
	SkyrangerState.Location = HeadquartersStateObject.Location;
	SkyrangerState.SourceLocation.X = SkyrangerState.Location.X;
	SkyrangerState.SourceLocation.Y = SkyrangerState.Location.Y;
	SkyrangerState.SquadOnBoard = true;

	// Set starting landing site map
	HeadquartersStateObject.LandingSiteMap = class'XGBase'.static.GetBiomeTerrainMap(true);

	// Create the starting mission
	if(!bTutorialEnabled)
	{
		CreateStartingMission(StartState, SkyrangerState.Location);
	}
	
	// update the reference to the Skyranger
	HeadquartersStateObject.SkyrangerRef = SkyrangerState.GetReference();
}

function AddToCrew(XComGameState NewGameState, XComGameState_Unit NewUnit )
{
	Crew.AddItem(NewUnit.GetReference());
	OnCrewMemberAdded(NewGameState, NewUnit);
}

function RemoveFromCrew( StateObjectReference CrewRef )
{
	Crew.RemoveItem(CrewRef);
}

//---------------------------------------------------------------------------------------
function BuildSoldierClassForcedDeck()
{
	local X2SoldierClassTemplateManager SoldierClassTemplateMan;
	local X2SoldierClassTemplate SoldierClassTemplate;
	local X2DataTemplate Template;
	local SoldierClassCount ClassCount;
	local int i;

	SoldierClassTemplateMan = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();
	foreach SoldierClassTemplateMan.IterateTemplates(Template, none)
	{
		SoldierClassTemplate = X2SoldierClassTemplate(Template);

		if(!SoldierClassTemplate.bMultiplayerOnly)
		{
			for(i = 0; i < SoldierClassTemplate.NumInForcedDeck; ++i)
			{
				SoldierClassDeck.AddItem(SoldierClassTemplate.DataName);

				if(SoldierClassDistribution.Find('SoldierClassName', SoldierClassTemplate.DataName) == INDEX_NONE)
				{
					// Add to array to track class distribution
					ClassCount.SoldierClassName = SoldierClassTemplate.DataName;
					ClassCount.Count = 0;
					SoldierClassDistribution.AddItem(ClassCount);
				}
			}
		}
	}
}

//---------------------------------------------------------------------------------------
function BuildSoldierClassDeck()
{
	local X2SoldierClassTemplateManager SoldierClassTemplateMan;
	local X2SoldierClassTemplate SoldierClassTemplate;
	local X2DataTemplate Template;
	local SoldierClassCount ClassCount;
	local int i;

	if (SoldierClassDeck.Length != 0)
	{
		SoldierClassDeck.Length = 0;
	}

	SoldierClassTemplateMan = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();

	foreach SoldierClassTemplateMan.IterateTemplates(Template, none)
	{
		SoldierClassTemplate = X2SoldierClassTemplate(Template);
		if(!SoldierClassTemplate.bMultiplayerOnly)
		{
			for(i = 0; i < SoldierClassTemplate.NumInDeck; ++i)
			{
				SoldierClassDeck.AddItem(SoldierClassTemplate.DataName);

				if(SoldierClassDistribution.Find('SoldierClassName', SoldierClassTemplate.DataName) == INDEX_NONE)
				{
					// Add to array to track class distribution
					ClassCount.SoldierClassName = SoldierClassTemplate.DataName;
					ClassCount.Count = 0;
					SoldierClassDistribution.AddItem(ClassCount);
				}
			}
		}
	}
	if (XComHeadquarters_NumToRemoveFromSoldierDeck >= SoldierClassDeck.Length)
	{
		`RedScreen("Soldier class deck problem. No elements removed. @gameplay -mnauta");
		return;
	}
	for (i = 0; i < XComHeadquarters_NumToRemoveFromSoldierDeck; ++i)
	{
		SoldierClassDeck.Remove(`SYNC_RAND(SoldierClassDeck.Length), 1);
	}
}

//---------------------------------------------------------------------------------------
function name SelectNextSoldierClass(optional name ForcedClass)
{
	local name RetName;
	local array<name> ValidClasses;
	local int Index;

	if(SoldierClassDeck.Length == 0)
	{
		BuildSoldierClassDeck();
	}
	
	if(ForcedClass != '')
	{
		// Must be a valid class in the distribution list
		if(SoldierClassDistribution.Find('SoldierClassName', ForcedClass) != INDEX_NONE)
		{
			// If not in the class deck rebuild the class deck
			if(SoldierClassDeck.Find(ForcedClass) == INDEX_NONE)
			{
				BuildSoldierClassDeck();
			}

			ValidClasses.AddItem(ForcedClass);
		}
	}

	// Only do this if not forced
	if(ValidClasses.Length == 0)
	{
		ValidClasses = GetValidNextSoldierClasses();
	}
	
	// If not forced, and no valid, rebuild
	if(ValidClasses.Length == 0)
	{
		BuildSoldierClassDeck();
		ValidClasses = GetValidNextSoldierClasses();
	}

	if(SoldierClassDeck.Length == 0)
		`RedScreen("No elements found in SoldierClassDeck array. This might break class assignment, please inform sbatista and provide a save.");

	if(ValidClasses.Length == 0)
		`RedScreen("No elements found in ValidClasses array. This might break class assignment, please inform sbatista and provide a save.");
	
	RetName = ValidClasses[`SYNC_RAND(ValidClasses.Length)];
	SoldierClassDeck.Remove(SoldierClassDeck.Find(RetName), 1);
	Index = SoldierClassDistribution.Find('SoldierClassName', RetName);
	SoldierClassDistribution[Index].Count++;

	return RetName;
}

//---------------------------------------------------------------------------------------
function array<name> GetValidNextSoldierClasses()
{
	local array<name> ValidClasses;
	local int idx;

	for(idx = 0; idx < SoldierClassDeck.Length; idx++)
	{
		if(GetClassDistributionDifference(SoldierClassDeck[idx]) < default.MaxSoldierClassDifference)
		{
			ValidClasses.AddItem(SoldierClassDeck[idx]);
		}
	}

	return ValidClasses;
}

//---------------------------------------------------------------------------------------
private function int GetClassDistributionDifference(name SoldierClassName)
{
	local int LowestCount, ClassCount, idx;

	LowestCount = SoldierClassDistribution[0].Count;

	for(idx = 0; idx < SoldierClassDistribution.Length; idx++)
	{
		if(SoldierClassDistribution[idx].Count < LowestCount)
		{
			LowestCount = SoldierClassDistribution[idx].Count;
		}

		if(SoldierClassDistribution[idx].SoldierClassName == SoldierClassName)
		{
			ClassCount = SoldierClassDistribution[idx].Count;
		}
	}

	return (ClassCount - LowestCount);
}

//---------------------------------------------------------------------------------------
function array<name> GetNeededSoldierClasses()
{
	local XComGameStateHistory History;
	local array<SoldierClassCount> ClassCounts, ClassHighestRank;
	local SoldierClassCount SoldierClassStruct, EmptyStruct;
	local XComGameState_Unit UnitState;
	local array<name> NeededClasses;
	local int idx, Index, HighestClassCount;

	History = `XCOMHISTORY;

	// Grab reward classes
	for(idx = 0; idx < SoldierClassDistribution.Length; idx++)
	{
		SoldierClassStruct = EmptyStruct;
		SoldierClassStruct.SoldierClassName = SoldierClassDistribution[idx].SoldierClassName;
		SoldierClassStruct.Count = 0;
		ClassCounts.AddItem(SoldierClassStruct);
		ClassHighestRank.AddItem(SoldierClassStruct);
	}

	HighestClassCount = 0;

	// Grab current crew information
	for(idx = 0; idx < Crew.Length; idx++)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(Crew[idx].ObjectID));

		if(UnitState != none && UnitState.IsASoldier() && UnitState.GetRank() > 0)
		{
			Index = ClassCounts.Find('SoldierClassName', UnitState.GetSoldierClassTemplate().DataName);

			if(Index != INDEX_NONE)
			{
				// Add to class count
				ClassCounts[Index].Count++;
				if(ClassCounts[Index].Count > HighestClassCount)
				{
					HighestClassCount = ClassCounts[Index].Count;
				}

				// Update Highest class rank if applicable
				if(ClassHighestRank[Index].Count < UnitState.GetRank())
				{
					ClassHighestRank[Index].Count = UnitState.GetRank();
				}
			}
		}
	}

	// Parse the info to grab needed classes
	for(idx = 0; idx < ClassCounts.Length; idx++)
	{
		if((ClassCounts[idx].Count == 0) || ((HighestClassCount - ClassCounts[idx].Count) >= 2) || ((HighestSoldierRank - ClassHighestRank[idx].Count) >= 2))
		{
			NeededClasses.AddItem(ClassCounts[idx].SoldierClassName);
		}
	}

	// If no classes are needed, all classes are needed
	if(NeededClasses.Length == 0)
	{
		for(idx = 0; idx < ClassCounts.Length; idx++)
		{
			NeededClasses.AddItem(ClassCounts[idx].SoldierClassName);
		}
	}

	return NeededClasses;
}

//---------------------------------------------------------------------------------------
static function CreateRoomSpecialFeatures(XComGameState StartState, optional bool bTutorialEnabled = false)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersRoom Room;
	local array<XComGameState_HeadquartersRoom> ValidRooms;
	local array<SpecialRoomFeatureEntry> FeatureDeck, FillDeck, RowFeatureDeck, RowFillDeck;
	local X2SpecialRoomFeatureTemplate SpecialFeature;
	local int idx, FeatureIndex, RandIndex, CurrentRow, NumRows;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	assert(StartState != none);

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	// First fill the valid room array
	for(idx = 0; idx < XComHQ.Rooms.Length; idx++)
	{
		Room = XComGameState_HeadquartersRoom(StartState.GetGameStateForObjectID(XComHQ.Rooms[idx].ObjectID));

		if(Room != none)
		{
			if(!Room.HasFacility())
			{
				ValidRooms.AddItem(Room);
			}
		}
	}

	// Add special features to random rooms to meet minimum feature requirements
	CreateMinimumSpecialFeatureRequirements(StartState, ValidRooms, bTutorialEnabled);
	
	// Create source special feature and fill decks
	FeatureDeck = BuildSpecialFeatureDeck(bTutorialEnabled);
	FillDeck = BuildSpecialFillDeck(bTutorialEnabled);

	NumRows = ValidRooms.Length / default.XComHeadquarters_RoomRowLength;
	
	// For each row in the Avenger facility grid
	for (CurrentRow = 0; CurrentRow < NumRows; CurrentRow++)
	{
		// Build a row-specific feature and fill deck using the source decks
		RowFeatureDeck = BuildRowSpecialFeatureDeck(FeatureDeck, CurrentRow);
		RowFillDeck = BuildRowSpecialFillDeck(FillDeck, CurrentRow);

		// For each room in the row
		for (idx = 0; idx < default.XComHeadquarters_RoomRowLength; idx++)
		{
			Room = ValidRooms[CurrentRow * default.XComHeadquarters_RoomRowLength + idx];
			
			if (!Room.HasSpecialFeature()) // If the room did not have a feature or fill already set
			{
				RandIndex = `SYNC_RAND_STATIC(RowFeatureDeck.Length);
				SpecialFeature = RowFeatureDeck[RandIndex].FeatureTemplate;

				if (SpecialFeature != none)
				{
					// Find the related feature in the source deck, and check to see if the max quantity is surpassed
					for (FeatureIndex = 0; FeatureIndex < FeatureDeck.Length; FeatureIndex++)
					{
						if (FeatureDeck[FeatureIndex].FeatureTemplate == SpecialFeature)
						{
							FeatureDeck[FeatureIndex].Quantity++;

							if (FeatureDeck[FeatureIndex].Quantity >= SpecialFeature.MaxTotalAllowed)
							{
								// If so, remove it from the row deck
								RowFeatureDeck.Remove(RandIndex, 1);
							}
						}
					}
				}
				else // If the Feature was none, pick a random Fill instead
				{
					RandIndex = `SYNC_RAND_STATIC(RowFillDeck.Length);
					SpecialFeature = RowFillDeck[RandIndex].FeatureTemplate;
				}
				
				// Assign the feature to the chosen room
				if (SpecialFeature != none)
				{
					AssignSpecialFeatureToRoom(StartState, SpecialFeature, Room);
				}
			}
			else if (Room.SpecialFeature == 'SpecialRoomFeature_EmptyRoom')
			{
				// If the room was set as empty by the empty room template, erase that now so it will spawn as a true empty room
				Room.SpecialFeature = '';
				Room.Locked = false;
				UnlockAdjacentRooms(StartState, Room);
			}

			// Unlock tutorial excavate room
			if(bTutorialEnabled && Room.MapIndex == default.TutorialExcavateIndex)
			{
				Room.Locked = false;
			}
		}
	}
}

//---------------------------------------------------------------------------------------
private static function CreateMinimumSpecialFeatureRequirements(XComGameState StartState, array<XComGameState_HeadquartersRoom> ValidRooms, optional bool bTutorialEnabled = false)
{	
	local X2SpecialRoomFeatureTemplate SpecialFeature;
	local array<SpecialRoomFeatureEntry> FeatureDeck;
	local XComGameState_HeadquartersRoom Room, ExclusiveRoom;
	local array<XComGameState_HeadquartersRoom> ValidRoomsForFeature;
	local array<int> ExclusiveIndices;
	local int idx, RoomIndex, MinRoomIndex, MaxRoomIndex;
	local bool bExclusiveFeatureFound;

	FeatureDeck = BuildSpecialFeatureDeck(bTutorialEnabled);

	for (idx = 0; idx < FeatureDeck.Length; idx++)
	{
		SpecialFeature = FeatureDeck[idx].FeatureTemplate;
		
		//If the feature exists and has a minimum requirement, find the rooms where it can be applied
		if (SpecialFeature != None && SpecialFeature.MinTotalAllowed > 0)
		{
			// Set the min and max room indices based on the feature row requirements
			// Lowest/HighestRowAllowed start at 1, not 0, to allow for default values when they are not set in the templates
			if (SpecialFeature.LowestRowAllowed > 0)
				MinRoomIndex = (SpecialFeature.LowestRowAllowed - 1) * default.XComHeadquarters_RoomRowLength;
			else
				MinRoomIndex = 0;

			if (SpecialFeature.HighestRowAllowed > 0)
				MaxRoomIndex = (SpecialFeature.HighestRowAllowed) * default.XComHeadquarters_RoomRowLength;
			else
				MaxRoomIndex = ValidRooms.Length;

			ValidRoomsForFeature.Length = 0; // Reset the array of valid rooms
			for (RoomIndex = MinRoomIndex; RoomIndex < MaxRoomIndex; RoomIndex++)
			{
				if (!ValidRooms[RoomIndex].HasSpecialFeature()) // Don't pick a room which already has an assigned feature
				{
					ValidRoomsForFeature.AddItem(ValidRooms[RoomIndex]);
				}
			}

			// Then randomly choose rooms from the list and assign the feature to them until its minimum quantity is met
			while (FeatureDeck[idx].Quantity > 0)
			{
				bExclusiveFeatureFound = false;

				if (ValidRoomsForFeature.Length > 0)
				{
					Room = ValidRoomsForFeature[`SYNC_RAND_STATIC(ValidRoomsForFeature.Length)];

					// Get any exclusivity conditions for this special feature type
					ExclusiveIndices = FeatureDeck[idx].FeatureTemplate.ExclusiveRoomIndices;
					if (ExclusiveIndices.Length > 0)
					{
						if (ExclusiveIndices.Find(Room.MapIndex) != INDEX_NONE) // Is the selected room part of the exclusivity array for this feature
						{
							foreach ValidRooms(ExclusiveRoom) // Take all of the possible rooms
							{
								// Check if the checked room is in the exclusive list and if it already has the feature
								if (ExclusiveIndices.Find(ExclusiveRoom.MapIndex) != INDEX_NONE && ExclusiveRoom.GetSpecialFeature() == FeatureDeck[idx].FeatureTemplate)
								{
									bExclusiveFeatureFound = true; // Feature was found in an exclusive room, so cannot be placed here again
									break;
								}
							}
						}
					}
					
					// Otherwise its fine
					if (!bExclusiveFeatureFound)
					{
						AssignSpecialFeatureToRoom(StartState, FeatureDeck[idx].FeatureTemplate, Room);
					}

					ValidRoomsForFeature.RemoveItem(Room);
				}

				if (!bExclusiveFeatureFound)
					FeatureDeck[idx].Quantity--;
			}
		}
	}
}

//---------------------------------------------------------------------------------------
private static function array<SpecialRoomFeatureEntry> BuildSpecialFeatureDeck(optional bool bTutorialEnabled = false)
{
	local array<X2StrategyElementTemplate> AllSpecialFeatures;
	local X2SpecialRoomFeatureTemplate SpecialFeature;
	local SpecialRoomFeatureEntry FeatureEntry;
	local array<SpecialRoomFeatureEntry> FeatureDeck;
	local int idx;

	FeatureDeck.Length = 0;

	// First add a blank entry to the deck to give a random chance for no special feature
	FeatureDeck.AddItem(FeatureEntry);

	// Create special feature deck
	AllSpecialFeatures = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().GetAllTemplatesOfClass(class'X2SpecialRoomFeatureTemplate');

	for (idx = 0; idx < AllSpecialFeatures.Length; idx++)
	{
		SpecialFeature = X2SpecialRoomFeatureTemplate(AllSpecialFeatures[idx]);
		FeatureEntry.FeatureTemplate = SpecialFeature;

		if (!SpecialFeature.bFillAvenger && (!bTutorialEnabled || default.TutorialExcludeSpecialRoomFeatures.Find(SpecialFeature.DataName) == INDEX_NONE))
		{
			FeatureEntry.Quantity = SpecialFeature.MinTotalAllowed;
			FeatureDeck.AddItem(FeatureEntry);
		}
	}

	return FeatureDeck;
}

//---------------------------------------------------------------------------------------
private static function array<SpecialRoomFeatureEntry> BuildRowSpecialFeatureDeck(array<SpecialRoomFeatureEntry> SourceDeck, int Row)
{	
	local X2SpecialRoomFeatureTemplate SpecialFeature;
	local SpecialRoomFeatureEntry FeatureEntry;
	local array<SpecialRoomFeatureEntry> FeatureDeck;
	local int idx;

	FeatureDeck.Length = 0;

	// First add a blank entry to the deck to give a random chance for no special feature
	FeatureDeck.AddItem(FeatureEntry);

	for (idx = 0; idx < SourceDeck.Length; idx++)
	{
		SpecialFeature = SourceDeck[idx].FeatureTemplate;
		if (SpecialFeature == none)
			continue;

		// Then check to make sure the other features are still allowed to be generated before adding to the deck
		if (((SpecialFeature.LowestRowAllowed - 1) <= Row) &&
			(SpecialFeature.MaxTotalAllowed - SpecialFeature.MinTotalAllowed > 0) &&
			(SourceDeck[idx].Quantity < SpecialFeature.MaxTotalAllowed))
		{
			FeatureDeck.AddItem(SourceDeck[idx]);
		}
	}

	return FeatureDeck;
}

//---------------------------------------------------------------------------------------
private static function array<SpecialRoomFeatureEntry> BuildSpecialFillDeck(optional bool bTutorialEnabled = false)
{
	local array<X2StrategyElementTemplate> AllSpecialFeatures;
	local X2SpecialRoomFeatureTemplate SpecialFeature;
	local SpecialRoomFeatureEntry FeatureEntry;
	local array<SpecialRoomFeatureEntry> FillDeck;
	local int idx;

	FillDeck.Length = 0;
	
	// Create special feature deck
	AllSpecialFeatures = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().GetAllTemplatesOfClass(class'X2SpecialRoomFeatureTemplate');

	for (idx = 0; idx < AllSpecialFeatures.Length; idx++)
	{
		SpecialFeature = X2SpecialRoomFeatureTemplate(AllSpecialFeatures[idx]);
		FeatureEntry.FeatureTemplate = SpecialFeature;

		if(SpecialFeature.bFillAvenger && (!bTutorialEnabled || default.TutorialExcludeSpecialRoomFeatures.Find(SpecialFeature.DataName) == INDEX_NONE))
		{
			FillDeck.AddItem(FeatureEntry);
		}
	}

	return FillDeck;
}

//---------------------------------------------------------------------------------------
private static function array<SpecialRoomFeatureEntry> BuildRowSpecialFillDeck(array<SpecialRoomFeatureEntry> SourceDeck, int Row)
{
	local array<SpecialRoomFeatureEntry> FillDeck;
	local int idx;

	FillDeck.Length = 0;
	
	for (idx = 0; idx < SourceDeck.Length; idx++)
	{		
		if ((SourceDeck[idx].FeatureTemplate.LowestRowAllowed - 1) <= Row)
		{
			FillDeck.AddItem(SourceDeck[idx]);
		}
	}

	return FillDeck;
}

//---------------------------------------------------------------------------------------
private static function AssignSpecialFeatureToRoom(XComGameState StartState, X2SpecialRoomFeatureTemplate SpecialFeature, XComGameState_HeadquartersRoom Room)
{
	local X2LootTableManager LootManager;
	local int LootIndex, NumBuildSlotsToAdd, idx;
	
	Room.SpecialFeature = SpecialFeature.DataName;

	if(SpecialFeature.UnclearedMapNames.Length > 0)
	{
		Room.SpecialFeatureUnclearedMapName = SpecialFeature.UnclearedMapNames[`SYNC_RAND_STATIC(SpecialFeature.UnclearedMapNames.Length)];
	}

	if(SpecialFeature.ClearedMapNames.Length > 0)
	{
		Room.SpecialFeatureClearedMapName = SpecialFeature.ClearedMapNames[`SYNC_RAND_STATIC(SpecialFeature.ClearedMapNames.Length)];
	}
	

	if (SpecialFeature.bBlocksConstruction)
	{
		Room.ConstructionBlocked = true;
	}

	if (SpecialFeature.bHasLoot && SpecialFeature.GetDepthBasedLootTableNameFn != none)
	{
		LootManager = class'X2LootTableManager'.static.GetLootTableManager();
		LootIndex = LootManager.FindGlobalLootCarrier(SpecialFeature.GetDepthBasedLootTableNameFn(Room));
		if (LootIndex >= 0)
		{
			LootManager.RollForGlobalLootCarrier(LootIndex, Room.Loot);
		}
	}

	// Create the build slots associated with this special feature
	if (SpecialFeature.GetDepthBasedNumBuildSlotsFn != none)
	{
		NumBuildSlotsToAdd = SpecialFeature.GetDepthBasedNumBuildSlotsFn(Room);
		for (idx = 0; idx < NumBuildSlotsToAdd; idx++)
		{
			Room.AddBuildSlot(StartState);
		}
	}
}

//---------------------------------------------------------------------------------------
static function CreateStartingResources(XComGameState StartState, bool bTutorialEnabled)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local X2ItemTemplateManager ItemTemplateMgr;
	local XComGameState_Item NewItemState;
	local X2ItemTemplate ItemTemplate;
	local X2DataTemplate DataTemplate;
	local XComGameStateHistory History;
	local name ItemTemplateName;

	History = `XCOMHISTORY;

	assert(StartState != none);

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));

	ItemTemplateMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	// Create Supplies
	ItemTemplate = ItemTemplateMgr.FindItemTemplate('Supplies');
	NewItemState = ItemTemplate.CreateInstanceFromTemplate(StartState);
	NewItemState.Quantity = XComHQ.GetStartingSupplies();
	StartState.AddStateObject(NewItemState);
	XComHQ.AddItemToHQInventory(NewItemState);

	// Create Intel
	ItemTemplate = ItemTemplateMgr.FindItemTemplate('Intel');
	NewItemState = ItemTemplate.CreateInstanceFromTemplate(StartState);
	NewItemState.Quantity = XComHQ.GetStartingIntel();
	StartState.AddStateObject(NewItemState);
	XComHQ.AddItemToHQInventory(NewItemState);

	// Create Alien Alloys
	ItemTemplate = ItemTemplateMgr.FindItemTemplate('AlienAlloy');
	NewItemState = ItemTemplate.CreateInstanceFromTemplate(StartState);
	NewItemState.Quantity = XComHQ.GetStartingAlloys();
	StartState.AddStateObject(NewItemState);
	XComHQ.AddItemToHQInventory(NewItemState);

	// Create Elerium Crystals
	ItemTemplate = ItemTemplateMgr.FindItemTemplate('EleriumDust');
	NewItemState = ItemTemplate.CreateInstanceFromTemplate(StartState);
	NewItemState.Quantity = XComHQ.GetStartingElerium();
	StartState.AddStateObject(NewItemState);
	XComHQ.AddItemToHQInventory(NewItemState);


	// Create one of each starting item
	foreach ItemTemplateMgr.IterateTemplates(DataTemplate, none)
	{
		if( X2ItemTemplate(DataTemplate) != none && X2ItemTemplate(DataTemplate).StartingItem)
		{
			NewItemState = X2ItemTemplate(DataTemplate).CreateInstanceFromTemplate(StartState);
			StartState.AddStateObject(NewItemState);
			XComHQ.AddItemToHQInventory(NewItemState);
		}
	}

	if(bTutorialEnabled)
	{
		foreach default.TutorialStartingItems(ItemTemplateName)
		{
			ItemTemplate = ItemTemplateMgr.FindItemTemplate(ItemTemplateName);

			if(ItemTemplate != none)
			{
				NewItemState = ItemTemplate.CreateInstanceFromTemplate(StartState);
				StartState.AddStateObject(NewItemState);
				XComHQ.AddItemToHQInventory(NewItemState);
			}
		}
	}
}

// Helper function for GetStartingLocation - can't call the existing non-static one
static function float WrapFStatic(float Val, float Min, float Max)
{
	if (Val > Max)
		return WrapFStatic(Min + (Val - Max), Min, Max);
	if (Val < Min)
		return WrapFStatic(Max - (Min - Val), Min, Max);
	return Val;
}

static function int GetRandomTriangle(array<float> CumulativeTriangleArea)
{
	local int Tri;
	local int ArrLength;
	local float RandomArea;

	ArrLength = CumulativeTriangleArea.Length;
	if (ArrLength <= 0) return 0;

	RandomArea = class'Engine'.static.GetEngine().SyncFRand("GetRandomTriangle") * CumulativeTriangleArea[ArrLength - 1];
	for (Tri = 0; Tri < ArrLength - 1; ++Tri)
	{
		if (CumulativeTriangleArea[Tri] > RandomArea) break;
	}

	return Tri;
}

// HACK: The starting location needs to be set before region meshes are available.
//		 Load the starting region mesh one time here to be able to generate a 
//		 starting location from it.
static function Vector GetStartingLocation(XComGameState_WorldRegion LandingSite, XComGameState_Haven HavenSite, out Vector ResHQLoc)
{
	local array<XComGameState_GeoscapeEntity> OverlapEntities;
	local StaticMesh RegionMesh;
	local Texture2D RegionTexture;
	local Object TextureObject;
	local X2WorldRegionTemplate RegionTemplate;
	local StaticMeshComponent curRegion;
	local Vector RandomLocation, ResHQLocTransform, RegionCenter;
	local Matrix Transform;
	local Vector2D RandomLoc2D, ResHQLoc2D, RegionCenter2D;
	local int Iterations, idx;
	local int RandomTri;
	local array<float> CumulativeTriangleArea;
	local bool bFoundGoodResHQLoc;

	RandomLocation.X = -1.0; RandomLocation.Y = -1.0; RandomLocation.Z = -1.0;

	RegionTemplate = LandingSite.GetMyTemplate();

	TextureObject = `CONTENT.RequestGameArchetype(RegionTemplate.RegionTexturePath);
	if (TextureObject == none || !TextureObject.IsA('Texture2D'))
	{
		`RedScreen("Could not load region texture" @ RegionTemplate.RegionTexturePath);
		return RandomLocation;
	}

	RegionTexture = Texture2D(TextureObject);
	RegionMesh = class'Helpers'.static.ConstructRegionActor(RegionTexture);

	curRegion = new class'StaticMeshComponent';
	curRegion.SetAbsolute(true, true, true);
	curRegion.SetStaticMesh(RegionMesh);

	Transform.XPlane.X = RegionTemplate.RegionMeshScale;
	Transform.YPlane.Y = RegionTemplate.RegionMeshScale;
	Transform.ZPlane.Z = RegionTemplate.RegionMeshScale;

	Transform.WPlane.X = RegionTemplate.RegionMeshLocation.X * class'XComEarth'.default.Width + class'XComEarth'.default.XOffset;
	Transform.WPlane.Y = RegionTemplate.RegionMeshLocation.Y * class'XComEarth'.default.Height;
	Transform.WPlane.Z = 0.1f;
	Transform.WPlane.W = 1.0f;

	class'Helpers'.static.GenerateCumulativeTriangleAreaArray(curRegion, CumulativeTriangleArea);
	
	// Make sure Res HQ region has an updated center location, then add to overlap array to prevent pin overlaps
	RegionCenter = class'Helpers'.static.GetRegionCenterLocation(curRegion, false);
	RegionCenter = TransformVector(Transform, RegionCenter);
	RegionCenter2D = class'XComEarth'.static.ConvertWorldToEarth(RegionCenter);
	LandingSite.Location.X = RegionCenter2D.X;
	LandingSite.Location.Y = RegionCenter2D.Y;
	OverlapEntities.AddItem(LandingSite);
	
	do {
		// Get a random point in the region mesh for the Avenger
		RandomTri = GetRandomTriangle(CumulativeTriangleArea);
		RandomLocation = class'Helpers'.static.GetRandomPointInRegionMesh(curRegion, RandomTri, false);
		RandomLocation = TransformVector(Transform, RandomLocation);

		// Convert Avenger point to Earth coords
		RandomLoc2D = class'XComEarth'.static.ConvertWorldToEarth(RandomLocation);
		RandomLocation.X = RandomLoc2D.X;
		RandomLocation.Y = RandomLoc2D.Y;
		RandomLocation.Z = 0.0f;
		
		if (class'X2StrategyGameRulesetDataStructures'.static.IsOnLand(RandomLoc2D))
		{
			// We have found a point in the region and on land for the Avenger, now find one for Res HQ
			for (idx = 0; idx < 100; idx++)
			{
				// Get a point within the radius of the Avenger for Res HQ's starting location
				ResHQLoc2D = class'X2StrategyGameRulesetDataStructures'.static.AdjustLocationByRadius(RandomLoc2D, default.LandingRadius);
				ResHQLoc.X = ResHQLoc2D.X;
				ResHQLoc.Y = ResHQLoc2D.Y;

				// convert Res HQ point to world coordinates
				ResHQLocTransform = class'XComEarth'.static.ConvertEarthToWorld(ResHQLoc2D, true);
				ResHQLocTransform = InverseTransformVector(Transform, ResHQLocTransform);

				// Check if the Res HQ point is in the region and not overlapping with the region pin
				if (class'Helpers'.static.IsInRegion(curRegion, ResHQLocTransform, false)
					&& class'X2StrategyGameRulesetDataStructures'.static.AvoidOverlapWithTooltipBounds(ResHQLoc, OverlapEntities, HavenSite))
				{
					bFoundGoodResHQLoc = true;
					break; // We have found a successful point for this starting Res HQ location AND Avenger location
				}
			}
		}

		++Iterations;
	} 
	until(bFoundGoodResHQLoc || Iterations > 100);

	return RandomLocation;
}

//---------------------------------------------------------------------------------------
static function CreateStartingMission(XComGameState StartState, Vector StartingMissionLoc)
{
	local XComGameState_MissionSite Mission;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersResistance ResHQ;
	local array<XComGameState_Reward> MissionRewards;
	local XComGameState_Reward RewardState;
	local X2RewardTemplate RewardTemplate;
	local XComGameStateHistory History;
	local X2StrategyElementTemplateManager StratMgr;
	local X2MissionSourceTemplate MissionSource;
	local XComGameState_WorldRegion RegionState;
	local Vector2D v2Loc;

	History = `XCOMHISTORY;
	
	assert(StartState != none);

	XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

	RegionState = XComGameState_WorldRegion(StartState.GetGameStateForObjectID(XComHQ.StartingRegion.ObjectID));
	v2Loc.X = StartingMissionLoc.X;
	v2Loc.Y = StartingMissionLoc.Y;

	RewardTemplate = X2RewardTemplate(StratMgr.FindStrategyElementTemplate('Reward_None'));
	RewardState = RewardTemplate.CreateInstanceFromTemplate(StartState);
	StartState.AddStateObject(RewardState);
	MissionRewards.AddItem(RewardState);

	Mission = XComGameState_MissionSite(StartState.CreateStateObject(class'XComGameState_MissionSite'));
	MissionSource = X2MissionSourceTemplate(StratMgr.FindStrategyElementTemplate('MissionSource_Start'));
	Mission.BuildMission(MissionSource, v2Loc, RegionState.GetReference(), MissionRewards, true);

	foreach StartState.IterateByClassType(class'XComGameState_HeadquartersResistance', ResHQ)
	{
		break;
	}

	StartState.AddStateObject(Mission);
}

//---------------------------------------------------------------------------------------
static function CreateStartingSoldiers(XComGameState StartState, optional bool bTutorialEnabled = false)
{
	local XComGameState_Unit NewSoldierState;	
	local XComGameState_HeadquartersXCom XComHQ;
	local XGCharacterGenerator CharacterGenerator;
	local TSoldier TutSoldier;
	local int Index, i;
	local XComGameState_GameTime GameTime;
	local XComGameState_Analytics Analytics;
	local TAppearance TutSoldierAppearance;
	local TDateTime TutKIADate;
	local StateObjectReference EmptyRef;
	local X2MissionSourceTemplate MissionSource;

	assert(StartState != none);

	foreach StartState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
	{
		break;
	}

	foreach StartState.IterateByClassType(class'XComGameState_GameTime', GameTime)
	{
		break;
	}
	`assert( GameTime != none );

	foreach StartState.IterateByClassType( class'XComGameState_Analytics', Analytics )
	{
		break;
	}
	`assert( Analytics != none );

	CharacterGenerator = XComGameInfo(class'WorldInfo'.static.GetWorldInfo().Game).m_CharacterGen;

	// Starting soldiers
	for( Index = 0; Index < class'XGTacticalGameCore'.default.NUM_STARTING_SOLDIERS; ++Index )
	{
		NewSoldierState = `CHARACTERPOOLMGR.CreateCharacter(StartState, default.InitialSoldiersCharacterPoolSelectionMode);

		if(bTutorialEnabled && Index == 0)
		{
			TutSoldier = CharacterGenerator.CreateTSoldier('Soldier', default.TutorialSoldierGender, default.TutorialSoldierCountry);
			TutSoldierAppearance = default.TutorialSoldierAppearance;

			if(GetLanguage() == "FRA")
			{
				TutSoldierAppearance.nmVoice = default.TutorialSoldierFrenchVoice;
			}
			else if(GetLanguage() == "DEU")
			{
				TutSoldierAppearance.nmVoice = default.TutorialSoldierGermanVoice;
			}
			else if(GetLanguage() == "ITA")
			{
				TutSoldierAppearance.nmVoice = default.TutorialSoldierItalianVoice;
			}
			else if(GetLanguage() == "ESN")
			{
				TutSoldierAppearance.nmVoice = default.TutorialSoldierSpanishVoice;
			}
			else
			{
				TutSoldierAppearance.nmVoice = default.TutorialSoldierEnglishVoice;
			}

			NewSoldierState.SetTAppearance(TutSoldierAppearance);
			NewSoldierState.SetCharacterName(class'XLocalizedData'.default.TutorialSoldierFirstName, class'XLocalizedData'.default.TutorialSoldierLastName, TutSoldier.strNickName);
			NewSoldierState.SetCountry(TutSoldier.nmCountry);
			NewSoldierState.SetXPForRank(1);
			NewSoldierState.StartingRank = 1;
			NewSoldierState.iNumMissions = 1;
			XComHQ.TutorialSoldier = NewSoldierState.GetReference();
		}
		
		NewSoldierState.GiveRandomPersonality();
		NewSoldierState.RandomizeStats();
		NewSoldierState.ApplyInventoryLoadout(StartState);

		NewSoldierState.SetHQLocation(eSoldierLoc_Barracks);

		XComHQ.AddToCrew(StartState, NewSoldierState);
		NewSoldierState.m_RecruitDate = GameTime.CurrentTime; // AddToCrew does this, but during start state creation the StrategyRuleset hasn't been created yet

		if(XComHQ.Squad.Length < class'X2StrategyGameRulesetDataStructures'.static.GetMaxSoldiersAllowedOnMission())
		{
			XComHQ.Squad.AddItem(NewSoldierState.GetReference());
		}

		StartState.AddStateObject( NewSoldierState );
	}

	// Dead tutorial soldiers

	if(bTutorialEnabled)
	{
		class'X2StrategyGameRulesetDataStructures'.static.SetTime(TutKIADate, 0, 0, 0, class'X2StrategyGameRulesetDataStructures'.default.START_MONTH,
			class'X2StrategyGameRulesetDataStructures'.default.START_DAY, class'X2StrategyGameRulesetDataStructures'.default.START_YEAR);

		MissionSource = X2MissionSourceTemplate(class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindStrategyElementTemplate('MissionSource_Start'));

		// Osei
		NewSoldierState = `CHARACTERPOOLMGR.CreateCharacter(StartState, default.InitialSoldiersCharacterPoolSelectionMode);
		TutSoldier = CharacterGenerator.CreateTSoldier('Soldier', default.DeadTutorialSoldier1Gender, default.DeadTutorialSoldier1Country);
		NewSoldierState.SetTAppearance(default.DeadTutorialSoldier1Appearance);
		NewSoldierState.SetCharacterName(class'XLocalizedData'.default.DeadTutorialSoldier1FirstName, class'XLocalizedData'.default.DeadTutorialSoldier1LastName, TutSoldier.strNickName);
		NewSoldierState.SetCountry(TutSoldier.nmCountry);
		NewSoldierState.SetXPForRank(1);
		NewSoldierState.StartingRank = 1;
		NewSoldierState.iNumMissions = 1;
		NewSoldierState.RandomizeStats();
		NewSoldierState.ApplyInventoryLoadout(StartState);
		NewSoldierState.SetHQLocation(eSoldierLoc_Barracks);
		NewSoldierState.SetCurrentStat(eStat_HP, 0.0f);
		NewSoldierState.m_KIADate = TutKIADate;
		NewSoldierState.m_strKIAOp = MissionSource.BattleOpName;
		NewSoldierState.m_strCauseOfDeath = default.DeadTutorialSoldier1CauseOfDeath;
		NewSoldierState.m_strEpitaph = default.DeadTutorialSoldier1Epitaph;

		for(i = 0; i < default.DeadTutorialSoldier1NumKills; i++)
		{
			NewSoldierState.SimGetKill(EmptyRef);
		}

		StartState.AddStateObject(NewSoldierState);
		XComHQ.DeadCrew.AddItem(NewSoldierState.GetReference());

		Analytics.AddValue( class'XComGameState_Analytics'.const.ANALYTICS_UNIT_SERVICE_HOURS, 0, NewSoldierState.GetReference( ) );
		Analytics.AddValue( class'XComGameState_Analytics'.const.ANALYTICS_UNITS_HEALED_HOURS, 0, NewSoldierState.GetReference( ) );
		Analytics.AddValue( class'XComGameState_Analytics'.const.ANALYTICS_UNIT_ATTACKS, 0, NewSoldierState.GetReference( ) );
		Analytics.AddValue( class'XComGameState_Analytics'.const.ANALYTICS_UNIT_DEALT_DAMAGE, 0, NewSoldierState.GetReference( ) );
		Analytics.AddValue( class'XComGameState_Analytics'.const.ANALYTICS_UNIT_ABILITIES_RECIEVED, 0, NewSoldierState.GetReference( ) );

		// Ramirez
		NewSoldierState = `CHARACTERPOOLMGR.CreateCharacter(StartState, default.InitialSoldiersCharacterPoolSelectionMode);
		TutSoldier = CharacterGenerator.CreateTSoldier('Soldier', default.DeadTutorialSoldier2Gender, default.DeadTutorialSoldier2Country);
		NewSoldierState.SetTAppearance(default.DeadTutorialSoldier2Appearance);
		NewSoldierState.SetCharacterName(class'XLocalizedData'.default.DeadTutorialSoldier2FirstName, class'XLocalizedData'.default.DeadTutorialSoldier2LastName, TutSoldier.strNickName);
		NewSoldierState.SetCountry(TutSoldier.nmCountry);
		NewSoldierState.SetXPForRank(1);
		NewSoldierState.StartingRank = 1;
		NewSoldierState.iNumMissions = 1;
		NewSoldierState.RandomizeStats();
		NewSoldierState.ApplyInventoryLoadout(StartState);
		NewSoldierState.SetHQLocation(eSoldierLoc_Barracks);
		NewSoldierState.SetCurrentStat(eStat_HP, 0.0f);
		NewSoldierState.m_KIADate = TutKIADate;
		NewSoldierState.m_strKIAOp = MissionSource.BattleOpName;
		NewSoldierState.m_strCauseOfDeath = default.DeadTutorialSoldier2CauseOfDeath;
		NewSoldierState.m_strEpitaph = default.DeadTutorialSoldier2Epitaph;

		for(i = 0; i < default.DeadTutorialSoldier2NumKills; i++)
		{
			NewSoldierState.SimGetKill(EmptyRef);
		}

		StartState.AddStateObject(NewSoldierState);
		XComHQ.DeadCrew.AddItem(NewSoldierState.GetReference());

		// Ramirez Bar Memorial Data
		Analytics.AddValue( class'XComGameState_Analytics'.const.ANALYTICS_UNIT_SERVICE_HOURS, 0, NewSoldierState.GetReference( ) );
		Analytics.AddValue( class'XComGameState_Analytics'.const.ANALYTICS_UNITS_HEALED_HOURS, 0, NewSoldierState.GetReference( ) );
		Analytics.AddValue( class'XComGameState_Analytics'.const.ANALYTICS_UNIT_ATTACKS, 0, NewSoldierState.GetReference( ) );
		Analytics.AddValue( class'XComGameState_Analytics'.const.ANALYTICS_UNIT_DEALT_DAMAGE, 0, NewSoldierState.GetReference( ) );
		Analytics.AddValue( class'XComGameState_Analytics'.const.ANALYTICS_UNIT_ABILITIES_RECIEVED, 0, NewSoldierState.GetReference( ) );
	}
}

//---------------------------------------------------------------------------------------
static function CreateStartingEngineer(XComGameState StartState)
{
	local X2CharacterTemplateManager CharTemplateMgr;	
	local X2CharacterTemplate CharacterTemplate;
	local XComGameState_Unit ShenState;
	local TSoldier CharacterGeneratorResult;
	local XGCharacterGenerator CharacterGenerator;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom Facility;
	local StaffUnitInfo ShenInfo;
	local int idx;

	assert(StartState != none);

	foreach StartState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
	{
		break;
	}

	CharacterGenerator = XComGameInfo(class'WorldInfo'.static.GetWorldInfo().Game).m_CharacterGen;

	CharTemplateMgr = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
	`assert(CharTemplateMgr != none);

	CharacterTemplate = CharTemplateMgr.FindCharacterTemplate('HeadEngineer');

	ShenState = CharacterTemplate.CreateInstanceFromTemplate(StartState);
	ShenState.SetSkillLevel(2);
	// TODO: Localize this
	ShenState.SetCharacterName(class'XLocalizedData'.default.LilyShenFirstName, class'XLocalizedData'.default.LilyShenLastName, "");
	CharacterGeneratorResult = CharacterGenerator.CreateTSoldier(CharacterTemplate.DataName);
	ShenState.SetTAppearance(CharacterGeneratorResult.kAppearance);
		
	StartState.AddStateObject(ShenState);
	XComHQ.AddToCrew(StartState, ShenState);

	// Put Shen in default staffing slot in the Armory
	for(idx = 0; idx < XComHQ.Facilities.Length; idx++)
	{
		Facility = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.Facilities[idx].ObjectID));
	
		if(Facility.GetMyTemplateName() == 'Storage')
		{
			ShenInfo.UnitRef = ShenState.GetReference();
			Facility.GetStaffSlot(0).FillSlot(StartState, ShenInfo);
		}
	}
}

//---------------------------------------------------------------------------------------
static function CreateStartingScientist(XComGameState StartState)
{
	local X2CharacterTemplateManager CharTemplateMgr;	
	local X2CharacterTemplate CharacterTemplate;
	local XComGameState_Unit TyganState;
	local TSoldier CharacterGeneratorResult;
	local XGCharacterGenerator CharacterGenerator;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_FacilityXCom Facility;
	local StaffUnitInfo TyganInfo;
	local int idx;

	assert(StartState != none);

	foreach StartState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
	{
		break;
	}

	CharacterGenerator = XComGameInfo(class'WorldInfo'.static.GetWorldInfo().Game).m_CharacterGen;

	CharTemplateMgr = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
	`assert(CharTemplateMgr != none);

	CharacterTemplate = CharTemplateMgr.FindCharacterTemplate('HeadScientist');

	TyganState = CharacterTemplate.CreateInstanceFromTemplate(StartState);
	TyganState.SkillValue = TyganState.GetMyTemplate().SkillLevelThresholds[2];
	TyganState.SetCharacterName(class'XLocalizedData'.default.RichardTyganFirstName, class'XLocalizedData'.default.RichardTyganLastName, "");
	CharacterGeneratorResult = CharacterGenerator.CreateTSoldier(CharacterTemplate.DataName);
	TyganState.SetTAppearance(CharacterGeneratorResult.kAppearance);

	StartState.AddStateObject(TyganState);
	XComHQ.AddToCrew(StartState, TyganState);
	
	// Put Tygan in default staffing slot in the Power Core
	for(idx = 0; idx < XComHQ.Facilities.Length; idx++)
	{
		Facility = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(XComHQ.Facilities[idx].ObjectID));

		if(Facility.GetMyTemplateName() == 'PowerCore')
		{
			TyganInfo.UnitRef = TyganState.GetReference();
			Facility.GetStaffSlot(0).FillSlot(StartState, TyganInfo);
		}
	}
}

static function CreateStartingBradford(XComGameState StartState)
{
	local X2CharacterTemplateManager CharTemplateMgr;
	local X2CharacterTemplate CharacterTemplate;
	local XComGameState_Unit CentralState;
	local TSoldier CharacterGeneratorResult;
	local XGCharacterGenerator CharacterGenerator;
	local XComGameState_HeadquartersXCom XComHQ;	

	assert(StartState != none);

	foreach StartState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
	{
		break;
	}

	CharacterGenerator = XComGameInfo(class'WorldInfo'.static.GetWorldInfo().Game).m_CharacterGen;

	CharTemplateMgr = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
	`assert(CharTemplateMgr != none);

	CharacterTemplate = CharTemplateMgr.FindCharacterTemplate('StrategyCentral');

	CentralState = CharacterTemplate.CreateInstanceFromTemplate(StartState);	
	CentralState.SetCharacterName(class'XLocalizedData'.default.OfficerBradfordFirstName, class'XLocalizedData'.default.OfficerBradfordLastName, "");
	CharacterGeneratorResult = CharacterGenerator.CreateTSoldier(CharacterTemplate.DataName);
	CentralState.SetTAppearance(CharacterGeneratorResult.kAppearance);

	StartState.AddStateObject(CentralState);
	XComHQ.AddToCrew(StartState, CentralState);
}

static function CreateStartingClerks(XComGameState StartState)
{
	local X2CharacterTemplateManager CharTemplateMgr;
	local X2CharacterTemplate CharacterTemplate;
	local XComGameState_Unit ClerkState;
	local TSoldier CharacterGeneratorResult;
	local XGCharacterGenerator CharacterGenerator;
	local XComGameState_HeadquartersXCom XComHQ;	
	local int Idx;

	assert(StartState != none);

	foreach StartState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
	{
		break;
	}

	CharacterGenerator = XComGameInfo(class'WorldInfo'.static.GetWorldInfo().Game).m_CharacterGen;

	CharTemplateMgr = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
	`assert(CharTemplateMgr != none);

	CharacterTemplate = CharTemplateMgr.FindCharacterTemplate('Clerk');

	for(Idx = 0; Idx < default.NumClerks_ActOne; ++Idx)
	{
		ClerkState = CharacterTemplate.CreateInstanceFromTemplate(StartState);
		CharacterGeneratorResult = CharacterGenerator.CreateTSoldier(CharacterTemplate.DataName);
		ClerkState.SetTAppearance(CharacterGeneratorResult.kAppearance);
		StartState.AddStateObject(ClerkState);
		XComHQ.Clerks.AddItem(ClerkState.GetReference());
	}
}

function UpdateClerkCount(int ActNum, XComGameState UpdateGameState)
{
	local X2CharacterTemplateManager CharTemplateMgr;
	local X2CharacterTemplate CharacterTemplate;
	local XComGameState_Unit ClerkState;
	local TSoldier CharacterGeneratorResult;
	local XGCharacterGenerator CharacterGenerator;	
	local int MaxClerks;

	switch(ActNum)
	{
		case 1:
			MaxClerks = NumClerks_ActOne;
			break;
		case 2:
			MaxClerks = NumClerks_ActTwo;
			break;
		case 3:
			MaxClerks = NumClerks_ActThree;
			break;
	}

	CharacterGenerator = XComGameInfo(class'WorldInfo'.static.GetWorldInfo().Game).m_CharacterGen;
	CharTemplateMgr = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
	`assert(CharTemplateMgr != none);
	CharacterTemplate = CharTemplateMgr.FindCharacterTemplate('Clerk');

	while(Clerks.Length < MaxClerks)
	{
		ClerkState = CharacterTemplate.CreateInstanceFromTemplate(UpdateGameState);
		CharacterGeneratorResult = CharacterGenerator.CreateTSoldier(CharacterTemplate.DataName);
		ClerkState.SetTAppearance(CharacterGeneratorResult.kAppearance);
		UpdateGameState.AddStateObject(ClerkState);
		Clerks.AddItem(ClerkState.GetReference());
	}
}

//#############################################################################################
//----------------   UPDATE   -----------------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function bool Update(XComGameState NewGameState, out array<XComGameState_Unit> UnitsWhichLeveledUp)
{
	local bool bUpdated;
	local int idx;
	local X2StrategyGameRuleset StrategyRuleset;

	bUpdated = false;
	StrategyRuleset = `STRATEGYRULES;

	if( class'X2StrategyGameRulesetDataStructures'.static.LessThan(ResetScanRateEndTime, StrategyRuleset.GameTime) )
	{
		CurrentScanRate = 1.0;
		ResetScanRateEndTime.m_iYear = 9999;
		bUpdated = true;
	}

	for(idx = 0; idx < CurrentOrders.Length; idx++)
	{
		if( class'X2StrategyGameRulesetDataStructures'.static.LessThan(CurrentOrders[idx].OrderCompletionTime, StrategyRuleset.GameTime) )
		{
			OnStaffOrderComplete(NewGameState, CurrentOrders[idx]);
			bUpdated = true;
		}
	}

	return bUpdated;
}

//#############################################################################################
//----------------   PERSONNEL MANAGEMENT   ---------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function StateObjectReference GetShenReference()
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local StateObjectReference EmptyRef;
	local int idx;

	History = `XCOMHISTORY;

	for(idx = 0; idx < Crew.Length; idx++)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(Crew[idx].ObjectID));

		if(UnitState != none && UnitState.GetMyTemplateName() == 'HeadEngineer')
		{
			return UnitState.GetReference();
		}
	}

	`Redscreen("Shen Unit Reference not found.");
	return EmptyRef;
}

//---------------------------------------------------------------------------------------
function StateObjectReference GetTyganReference()
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local StateObjectReference EmptyRef;
	local int idx;

	History = `XCOMHISTORY;

	for(idx = 0; idx < Crew.Length; idx++)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(Crew[idx].ObjectID));

		if(UnitState != none && UnitState.GetMyTemplateName() == 'HeadScientist')
		{
			return UnitState.GetReference();
		}
	}

	`Redscreen("Tygan Unit Reference not found.");
	return EmptyRef;
}

//---------------------------------------------------------------------------------------
function int GetCrewQuantity()
{
	// Add one for central
	return (Crew.Length + 1);
}

//---------------------------------------------------------------------------------------
function int GetNumberOfDeployableSoldiers()
{
	local XComGameState_Unit Soldier;
	local int idx, iDeployable;

	iDeployable = 0;
	for(idx = 0; idx < Crew.Length; idx++)
	{
		Soldier = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Crew[idx].ObjectID));

		if(Soldier != none)
		{
			if(Soldier.IsSoldier() && (Soldier.GetStatus() == eStatus_Active || Soldier.GetStatus() == eStatus_PsiTraining))
			{
				iDeployable++;
			}
		}
	}

	return iDeployable;
}

//---------------------------------------------------------------------------------------
function int GetNumberOfInjuredSoldiers()
{
	local XComGameState_Unit Soldier;
	local int idx, iInjured;

	iInjured = 0;
	for (idx = 0; idx < Crew.Length; idx++)
	{
		Soldier = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Crew[idx].ObjectID));

		if (Soldier != none)
		{
			if (Soldier.IsSoldier() && Soldier.IsInjured())
			{
				iInjured++;
			}
		}
	}

	return iInjured;
}

//---------------------------------------------------------------------------------------
function array<XComGameState_Unit> GetSoldiers(optional bool bDontIncludeSquad = false)
{
	local XComGameState_Unit Soldier;
	local array<XComGameState_Unit> Soldiers;
	local int idx;

	for (idx = 0; idx < Crew.Length; idx++)
	{
		Soldier = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Crew[idx].ObjectID));

		if (Soldier != none)
		{
			if (Soldier.IsSoldier() && !Soldier.IsDead())
			{
				if(!bDontIncludeSquad || (bDontIncludeSquad && !IsUnitInSquad(Soldier.GetReference())))
				{
					Soldiers.AddItem(Soldier);
				}
			}
		}
	}

	return Soldiers;
}

//---------------------------------------------------------------------------------------
function array<XComGameState_Unit> GetDeployableSoldiers(optional bool bDontIncludeSquad=false, optional bool bAllowWoundedSoldiers=false)
{
	local XComGameState_Unit Soldier;
	local array<XComGameState_Unit> DeployableSoldiers;
	local int idx;

	for(idx = 0; idx < Crew.Length; idx++)
	{
		Soldier = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Crew[idx].ObjectID));

		if(Soldier != none)
		{
			if(Soldier.IsSoldier() && Soldier.IsAlive() && (Soldier.GetStatus() == eStatus_Active || Soldier.GetStatus() == eStatus_PsiTraining || (bAllowWoundedSoldiers && Soldier.IsInjured())))
			{
				if(!bDontIncludeSquad || (bDontIncludeSquad && !IsUnitInSquad(Soldier.GetReference())))
				{
					DeployableSoldiers.AddItem(Soldier);
				}
			}
		}
	}

	return DeployableSoldiers;
}

//---------------------------------------------------------------------------------------
function XComGameState_Unit GetBestDeployableSoldier(optional bool bDontIncludeSquad=false, optional bool bAllowWoundedSoldiers = false)
{
	local array<XComGameState_Unit> DeployableSoldiers;
	local int idx, HighestRank;

	DeployableSoldiers = GetDeployableSoldiers(bDontIncludeSquad, bAllowWoundedSoldiers);

	if(DeployableSoldiers.Length == 0)
	{
		return none;
	}

	HighestRank = 0;

	for(idx = 0; idx < DeployableSoldiers.Length; idx++)
	{
		if(DeployableSoldiers[idx].GetRank() > HighestRank)
		{
			HighestRank = DeployableSoldiers[idx].GetRank();
		}
	}

	for(idx = 0; idx < DeployableSoldiers.Length; idx++)
	{
		if(DeployableSoldiers[idx].GetRank() < HighestRank)
		{
			DeployableSoldiers.Remove(idx, 1);
			idx--;
		}
	}

	return (DeployableSoldiers[`SYNC_RAND(DeployableSoldiers.Length)]);
}

//---------------------------------------------------------------------------------------
function bool HasSoldiersToPromote()
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local int idx;

	History = `XCOMHISTORY;

	for (idx = 0; idx < Crew.Length; idx++)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(Crew[idx].ObjectID));

		if(UnitState != none)
		{
			if(UnitState.IsASoldier() && !UnitState.IsDead() &&
				UnitState.CanRankUpSoldier() || UnitState.HasAvailablePerksToAssign())
			{
				return true;
			}
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
function int GetNumberOfSoldiers()
{
	local XComGameState_Unit Soldier;
	local int idx, iSoldiers;

	iSoldiers = 0;
	for(idx = 0; idx < Crew.Length; idx++)
	{
		Soldier = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Crew[idx].ObjectID));

		if(Soldier != none)
		{
			if(Soldier.IsASoldier() && !Soldier.IsDead())
			{
				iSoldiers++;
			}
		}
	}

	return iSoldiers;
}

//---------------------------------------------------------------------------------------
function int GetNumberOfEngineers()
{
	local XComGameState_Unit Engineer;
	local int idx, iEngineers;

	iEngineers = -1; // Start at negative one to negate counting the head engineer
	for(idx = 0; idx < Crew.Length; idx++)
	{
		Engineer = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Crew[idx].ObjectID));

		if(Engineer != none)
		{
			if(Engineer.IsAnEngineer() && !Engineer.IsDead())
			{
				iEngineers++;
			}
		}
	}

	return iEngineers;
}

//---------------------------------------------------------------------------------------
function int GetNumberOfUnstaffedEngineers()
{
	local XComGameState_Unit Engineer;
	local int idx, iEngineers;

	iEngineers = 0;
	for (idx = 0; idx < Crew.Length; idx++)
	{
		Engineer = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Crew[idx].ObjectID));

		if (Engineer != none)
		{
			if (Engineer.IsAnEngineer() && !Engineer.IsDead() && Engineer.StaffingSlot.ObjectID == 0 && Engineer.CanBeStaffed())
			{
				iEngineers++;
			}
		}
	}

	return iEngineers;
}

//---------------------------------------------------------------------------------------
function array<StaffUnitInfo> GetUnstaffedEngineers()
{
	local XComGameState_Unit Engineer;
	local XComGameState_StaffSlot SlotState;
	local int idx, iGhostCount;
	local array<StaffUnitInfo> UnstaffedEngineers;
	local StaffUnitInfo UnitInfo;

	for( idx = 0; idx < Crew.Length; idx++ )
	{
		Engineer = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Crew[idx].ObjectID));

		if( Engineer != none )
		{
			if (Engineer.IsAnEngineer() && !Engineer.IsDead())
			{
				UnitInfo.UnitRef = Engineer.GetReference();
				if (Engineer.StaffingSlot.ObjectID == 0 && Engineer.CanBeStaffed())
				{
					UnitInfo.bGhostUnit = false;
					UnstaffedEngineers.AddItem(UnitInfo);
				}
				else if (Engineer.StaffingSlot.ObjectID != 0)
				{
					SlotState = Engineer.GetStaffSlot();
					iGhostCount = SlotState.AvailableGhostStaff;
					UnitInfo.bGhostUnit = true;
					
					// Checking for available ghosts and available adjacent staff slots
					if (iGhostCount > 0 && SlotState.HasOpenAdjacentStaffSlots(UnitInfo))
					{
						while (iGhostCount > 0)
						{
							UnstaffedEngineers.AddItem(UnitInfo);
							iGhostCount--;
						}
					}
				}
			}
		}
	}

	return UnstaffedEngineers;
}
//---------------------------------------------------------------------------------------
function int GetEngineeringScore(optional bool bAddWorkshopBonus = false)
{
	local XComGameState_Unit Engineer;
	local XComGameState_FacilityXCom FacilityState;
	local int idx, Score;

	Score = default.XComHeadquarters_StartingEngineeringScore;
	Score += BonusEngineeringScore;

	for(idx = 0; idx < Crew.Length; idx++)
	{
		Engineer = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Crew[idx].ObjectID));
		
		if (Engineer != none)
		{
			//First check that the unit is actually a engineer and alive
			if (Engineer.IsAnEngineer() && !Engineer.IsDead())
			{
				Score += Engineer.GetSkillLevel(bAddWorkshopBonus);
			}
		}
	}

	for (idx = 0; idx < Facilities.Length; idx++)
	{
		FacilityState = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(Facilities[idx].ObjectID));

		if (FacilityState != none)
		{
			Score += FacilityState.GetMyTemplate().EngineeringBonus;
		}
	}

	return Score;
}

//---------------------------------------------------------------------------------------
function int GetHeadEngineerRef()
{
	local XComGameState_Unit Engineer;
	local int idx;

	for( idx = 0; idx < Crew.Length; idx++ )
	{
		Engineer = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Crew[idx].ObjectID));

		if( Engineer != none && Engineer.GetMyTemplateName() == 'HeadEngineer' )
		{
			return Engineer.ObjectID;
		}
	}

	return 0; 
}

//---------------------------------------------------------------------------------------
function int GetHeadScientistRef()
{
	local XComGameState_Unit Scientist;
	local int idx;

	for( idx = 0; idx < Crew.Length; idx++ )
	{
		Scientist = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Crew[idx].ObjectID));

		if( Scientist != none && Scientist.GetMyTemplateName() == 'HeadScientist' )
		{
			return Scientist.ObjectID;
		}
	}

	return 0;
}

//---------------------------------------------------------------------------------------
function int GetNumberOfScientists()
{
	local XComGameState_Unit Scientist;
	local int idx, iScientists;

	iScientists = -1; // Start at negative one to negate counting the head scientist
	for(idx = 0; idx < Crew.Length; idx++)
	{
		Scientist = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Crew[idx].ObjectID));

		if(Scientist != none)
		{
			if(Scientist.IsAScientist() && !Scientist.IsDead())
			{
				iScientists++;
			}
		}
	}

	return iScientists;
}

//---------------------------------------------------------------------------------------
function int GetNumberOfUnstaffedScientists()
{
	local XComGameState_Unit Scientist;
	local int idx, iScientists;

	iScientists = 0;
	for (idx = 0; idx < Crew.Length; idx++)
	{
		Scientist = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Crew[idx].ObjectID));

		if (Scientist != none)
		{
			if (Scientist.IsAScientist() && !Scientist.IsDead() && Scientist.StaffingSlot.ObjectID == 0 && Scientist.CanBeStaffed())
			{
				iScientists++;
			}
		}
	}

	return iScientists;
}

//---------------------------------------------------------------------------------------
function array<StaffUnitInfo> GetUnstaffedScientists()
{
	local XComGameState_Unit Scientist;
	local int idx;
	local array<StaffUnitInfo> UnstaffedScientists;
	local StaffUnitInfo UnitInfo;

	for( idx = 0; idx < Crew.Length; idx++ )
	{
		Scientist = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Crew[idx].ObjectID));

		if( Scientist != none )
		{
			if(Scientist.IsAScientist() && !Scientist.IsDead() && Scientist.StaffingSlot.ObjectID == 0 && Scientist.CanBeStaffed())
			{
				UnitInfo.UnitRef = Scientist.GetReference();
				UnstaffedScientists.AddItem(UnitInfo);
			}
		}
	}

	return UnstaffedScientists;
}

//---------------------------------------------------------------------------------------
function int GetScienceScore(optional bool bAddLabBonus = false)
{
	local XComGameState_Unit Scientist;
	local XComGameState_FacilityXCom FacilityState;
	local int idx, Score;

	Score = default.XComHeadquarters_StartingScienceScore;
	Score += BonusScienceScore;

	for(idx = 0; idx < Crew.Length; idx++)
	{
		Scientist = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Crew[idx].ObjectID));
		
		if (Scientist != none)
		{
			//First check that the unit is actually a scientist and alive
			if (Scientist.IsAScientist() && !Scientist.IsDead())
			{
				Score += Scientist.GetSkillLevel(bAddLabBonus);
			}
		}
	}

	for (idx = 0; idx < Facilities.Length; idx++)
	{
		FacilityState = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(Facilities[idx].ObjectID));

		if (FacilityState != none)
		{
			Score += FacilityState.GetMyTemplate().ScienceBonus;
		}
	}

	return Score;
}

//---------------------------------------------------------------------------------------
simulated function bool IsUnitInSquad(StateObjectReference UnitRef)
{
	local int i;
	for(i = 0; i < Squad.Length; ++i)
	{
		if(Squad[i] == UnitRef)
			return true;
	}
	return false;
}

//---------------------------------------------------------------------------------------
simulated function bool NeedSoldierShakenPopup(optional out array<XComGameState_Unit> UnitStates)
{
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local int idx;
	local bool bNeedPopup;

	History = `XCOMHISTORY;
	bNeedPopup = false;

	for (idx = 0; idx < Crew.Length; idx++)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(Crew[idx].ObjectID));

		if (UnitState != none)
		{
			if ((UnitState.bIsShaken && !UnitState.bSeenShakenPopup) || UnitState.bNeedsShakenRecoveredPopup)
			{
				UnitStates.AddItem(UnitState);
				bNeedPopup = true;
			}
		}
	}

	return bNeedPopup;
}

//---------------------------------------------------------------------------------------
function bool InjuredSoldiersAndNoInfirmary()
{
	local XComGameState_Unit Soldier;
	local int idx, iInjured;

	iInjured = 0;
	for(idx = 0; idx < Crew.Length; idx++)
	{
		Soldier = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Crew[idx].ObjectID));

		if(Soldier != none)
		{
			if(Soldier.IsSoldier() && Soldier.GetStatus() == eStatus_Healing)
			{
				iInjured++;
			}
		}
	}

	if(iInjured > 0 && !HasFacilityByName('AdvancedWarfareCenter'))
	{
		return true;
	}

	return false;
}

//---------------------------------------------------------------------------------------
simulated function int GetSquadCohesionValue()
{
	local array<XComGameState_Unit> Units;
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;
	local int i;

	History = `XCOMHISTORY;
	for (i = 0; i < Squad.Length; ++i)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(Squad[i].ObjectID));
		if (UnitState != none)
			Units.AddItem(UnitState);
	}

	return class'X2ExperienceConfig'.static.GetSquadCohesionValue(Units);
}

//---------------------------------------------------------------------------------------
function HandlePowerOrStaffingChange(optional XComGameState NewGameState = none)
{
	local XComGameState_HeadquartersProject ProjectState;
	local int idx;
	local XComGameStateHistory History;
	local bool bSubmitGameState;

	History = `XCOMHISTORY;
	bSubmitGameState = false;

	if(NewGameState == none)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Handle PowerState/Staffing Change");
		bSubmitGameState = true;
	}

	for(idx = 0; idx < Projects.Length; idx++)
	{
		ProjectState = XComGameState_HeadquartersProject(NewGameState.GetGameStateForObjectID(Projects[idx].ObjectID));

		if(ProjectState != none)
		{
			ProjectState.OnPowerStateOrStaffingChange();
		}
		else
		{
			ProjectState = XComGameState_HeadquartersProject(History.GetGameStateForObjectID(Projects[idx].ObjectID));

			if(ProjectState != none)
			{
				ProjectState = XComGameState_HeadquartersProject(NewGameState.CreateStateObject(ProjectState.Class, ProjectState.ObjectID));

				if(ProjectState.OnPowerStateOrStaffingChange())
				{
					NewGameState.AddStateObject(ProjectState);
				}
				else
				{
					NewGameState.PurgeGameStateForObjectID(ProjectState.ObjectID);
				}
			}
		}
	}

	if(bSubmitGameState)
	{
		if(NewGameState.GetNumGameStateObjects() > 0)
		{
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		}
		else
		{
			History.CleanupPendingGameState(NewGameState);
		}
	}
}

//---------------------------------------------------------------------------------------
function bool IsUnitInCrew(StateObjectReference UnitRef)
{
	local int idx;

	for(idx = 0; idx < Crew.Length; idx++)
	{
		if(Crew[idx] == UnitRef)
		{
			return true;
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
function OrderStaff(StateObjectReference UnitRef, int OrderHours)
{
	local HQOrder StaffOrder;
	
	StaffOrder.OrderRef = UnitRef;
	StaffOrder.OrderCompletionTime = GetCurrentTime();
	class'X2StrategyGameRulesetDataStructures'.static.AddHours(StaffOrder.OrderCompletionTime, OrderHours);
	CurrentOrders.AddItem(StaffOrder);
}

//---------------------------------------------------------------------------------------
function OnStaffOrderComplete(XComGameState NewGameState, HQOrder StaffOrder)
{
	local XComGameState_Unit UnitState;
	local int OrderIndex;
	local string Notice;

	OrderIndex = CurrentOrders.Find('OrderRef', StaffOrder.OrderRef);

	if(OrderIndex != INDEX_NONE)
	{
		CurrentOrders.Remove(OrderIndex, 1);
	}

	UnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', StaffOrder.OrderRef.ObjectID));
	`assert(UnitState != none);

	NewGameState.AddStateObject(UnitState);
	AddToCrew(NewGameState, UnitState);

	Notice = default.strStaffArrived;
	Notice = Repl(Notice, "%STAFF", UnitState.GetFullName());
	`HQPRES.Notify(Notice, class'UIUtilities_Image'.const.EventQueue_Staff);
}

//---------------------------------------------------------------------------------------
function FireStaff(StateObjectReference UnitReference)
{
	local HeadquartersOrderInputContext OrderInput;

	OrderInput.OrderType = eHeadquartersOrderType_FireStaff;
	OrderInput.AcquireObjectReference = UnitReference;

	class'XComGameStateContext_HeadquartersOrder'.static.IssueHeadquartersOrder(OrderInput);
}

function ResetLowScientistsPopupTimer()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Reset Low Scientists Popup Timer");
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', ObjectID));
	NewGameState.AddStateObject(XComHQ);
	XComHQ.LowScientistPopupTime = GetCurrentTime();
	class'X2StrategyGameRulesetDataStructures'.static.AddDays(XComHQ.LowScientistPopupTime, default.LowScientistPopupDays);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

function ResetLowEngineersPopupTimer()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Reset Low Scientists Popup Timer");
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', ObjectID));
	NewGameState.AddStateObject(XComHQ);
	XComHQ.LowEngineerPopupTime = GetCurrentTime();
	class'X2StrategyGameRulesetDataStructures'.static.AddDays(XComHQ.LowEngineerPopupTime, default.LowEngineerPopupDays);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

//#############################################################################################
//----------------   FACILITY MANAGEMENT   ----------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function bool HasFacilityByName(name FacilityTemplateName)
{
	local X2FacilityTemplate FacilityTemplate;

	FacilityTemplate = X2FacilityTemplate(class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindStrategyElementTemplate(FacilityTemplateName));

	if(FacilityTemplate != none)
	{
		return HasFacility(FacilityTemplate);
	}

	return false;
}

//---------------------------------------------------------------------------------------
function bool HasFacilityUpgradeByName(name UpgradeName)
{
	local XComGameStateHistory History;
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_FacilityUpgrade UpgradeState;
	local int idx;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_FacilityXCom', FacilityState)
	{
		for(idx = 0; idx < FacilityState.Upgrades.Length; idx++)
		{
			UpgradeState = XComGameState_FacilityUpgrade(History.GetGameStateForObjectID(FacilityState.Upgrades[idx].ObjectID));

			if(UpgradeState != none && UpgradeState.GetMyTemplateName() == UpgradeName)
			{
				return true;
			}
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
function XComGameState_FacilityXCom GetFacilityByName(name FacilityTemplateName)
{
	local X2FacilityTemplate FacilityTemplate;

	FacilityTemplate = X2FacilityTemplate(class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindStrategyElementTemplate(FacilityTemplateName));

	if(FacilityTemplate != none)
	{
		return GetFacility(FacilityTemplate);
	}

	return none;
}

//---------------------------------------------------------------------------------------
function X2FacilityTemplate GetFacilityTemplate(name FacilityTemplateName)
{
	local X2FacilityTemplate FacilityTemplate;

	FacilityTemplate = X2FacilityTemplate(class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindStrategyElementTemplate(FacilityTemplateName));

	if (FacilityTemplate != none)
	{
		return FacilityTemplate;
	}

	return none;
}

//---------------------------------------------------------------------------------------
function bool HasFacility(X2FacilityTemplate FacilityTemplate)
{
	local XComGameState_FacilityXCom Facility;
	local int idx;

	for(idx = 0; idx < Facilities.Length; idx++)
	{
		Facility = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(Facilities[idx].ObjectID));

		if(Facility.GetMyTemplateName() == FacilityTemplate.DataName)
		{
			return true;
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
function XComGameState_FacilityXCom GetFacility(X2FacilityTemplate FacilityTemplate)
{
	local XComGameState_FacilityXCom Facility;
	local int idx;

	for(idx = 0; idx < Facilities.Length; idx++)
	{
		Facility = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(Facilities[idx].ObjectID));

		if(Facility.GetMyTemplateName() == FacilityTemplate.DataName)
		{
			return Facility;
		}
	}

	return none;
}

//---------------------------------------------------------------------------------------
function XComGameState_FacilityXCom GetFacilityWithOpenStaffSlots(X2FacilityTemplate FacilityTemplate)
{
	local XComGameState_FacilityXCom Facility;
	local int idx;

	for (idx = 0; idx < Facilities.Length; idx++)
	{
		Facility = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(Facilities[idx].ObjectID));

		if (Facility.GetMyTemplateName() == FacilityTemplate.DataName)
		{
			if (Facility.GetNumEmptyStaffSlots() > 0)
			{
				return Facility;
			}
		}
	}

	return none;
}

//---------------------------------------------------------------------------------------
function XComGameState_FacilityXCom GetFacilityByNameWithOpenStaffSlots(name FacilityTemplateName)
{
	local X2FacilityTemplate FacilityTemplate;

	FacilityTemplate = X2FacilityTemplate(class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindStrategyElementTemplate(FacilityTemplateName));

	if (FacilityTemplate != none)
	{
		return GetFacilityWithOpenStaffSlots(FacilityTemplate);
	}

	return none;
}

//---------------------------------------------------------------------------------------
function XComGameState_FacilityXCom GetFacilityWithAvailableStaffSlots(X2FacilityTemplate FacilityTemplate)
{
	local XComGameState_FacilityXCom Facility;
	local int idx;

	for (idx = 0; idx < Facilities.Length; idx++)
	{
		Facility = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(Facilities[idx].ObjectID));

		if (Facility.GetMyTemplateName() == FacilityTemplate.DataName)
		{
			if (Facility.GetNumLockedStaffSlots() > 0 || Facility.GetNumEmptyStaffSlots() > 0)
			{
				return Facility;
			}
		}
	}

	return none;
}

//---------------------------------------------------------------------------------------
function XComGameState_FacilityXCom GetFacilityByNameWithAvailableStaffSlots(name FacilityTemplateName)
{
	local X2FacilityTemplate FacilityTemplate;

	FacilityTemplate = X2FacilityTemplate(class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindStrategyElementTemplate(FacilityTemplateName));

	if (FacilityTemplate != none)
	{
		return GetFacilityWithAvailableStaffSlots(FacilityTemplate);
	}

	return none;
}

//---------------------------------------------------------------------------------------
function array<XComGameState_StaffSlot> GetAllEmptyStaffSlotsForUnit(XComGameState_Unit UnitState)
{
	local array<XComGameState_StaffSlot> arrStaffSlots;
	local XComGameState_StaffSlot StaffSlot;
	local XComGameState_HeadquartersRoom Room;
	local XComGameState_FacilityXCom Facility;
	local StaffUnitInfo UnitInfo;
	local int idx;
	local bool bExcavationSlotAdded;

	UnitInfo.UnitRef = UnitState.GetReference();

	for (idx = 0; idx < Rooms.Length; idx++)
	{
		Room = XComGameState_HeadquartersRoom(`XCOMHISTORY.GetGameStateForObjectID(Rooms[idx].ObjectID));

		if (!bExcavationSlotAdded && !Room.Locked && Room.HasSpecialFeature() && !Room.bSpecialRoomFeatureCleared && Room.GetNumEmptyBuildSlots() > 0)
		{
			StaffSlot = Room.GetBuildSlot(Room.GetEmptyBuildSlotIndex());
			if (StaffSlot.ValidUnitForSlot(UnitInfo))
			{
				arrStaffSlots.AddItem(StaffSlot);
				bExcavationSlotAdded = true; // only add one excavation slot per list
			}
		}
		else if (Room.UnderConstruction && Room.GetNumEmptyBuildSlots() > 0)
		{
			StaffSlot = Room.GetBuildSlot(Room.GetEmptyBuildSlotIndex());
			if (StaffSlot.ValidUnitForSlot(UnitInfo))
			{
				arrStaffSlots.AddItem(StaffSlot);
			}
		}
	}

	for (idx = 0; idx < Facilities.Length; idx++)
	{
		Facility = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(Facilities[idx].ObjectID));

		if (Facility.GetNumEmptyStaffSlots() > 0)
		{
			StaffSlot = Facility.GetStaffSlot(Facility.GetEmptyStaffSlotIndex());
			if (StaffSlot.ValidUnitForSlot(UnitInfo))
			{
				arrStaffSlots.AddItem(StaffSlot);
			}
		}
	}

	return arrStaffSlots;
}

//---------------------------------------------------------------------------------------
function bool IsBuildingFacility(X2FacilityTemplate FacilityTemplate)
{
	local XComGameState_FacilityXCom Facility;
	local XComGameState_HeadquartersProjectBuildFacility FacilityProject;
	local int idx;

	for(idx = 0; idx < Projects.Length; idx++)
	{
		FacilityProject = XComGameState_HeadquartersProjectBuildFacility(`XCOMHISTORY.GetGameStateForObjectID(Projects[idx].ObjectID));

		if(FacilityProject != none)
		{
			Facility = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(FacilityProject.ProjectFocus.ObjectID));

			if(Facility != none)
			{
				if(Facility.GetMyTemplateName() == FacilityTemplate.DataName)
				{
					return true;
				}
			}
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
function int GetNumberBuildingOfFacilitiesOfType(X2FacilityTemplate FacilityTemplate)
{
	local XComGameStateHistory History;
	local XComGameState_FacilityXCom Facility;
	local XComGameState_HeadquartersProjectBuildFacility FacilityProject;
	local int idx, Total;

	History = `XCOMHISTORY;
	Total = 0;

	for(idx = 0; idx < Projects.Length; idx++)
	{
		FacilityProject = XComGameState_HeadquartersProjectBuildFacility(History.GetGameStateForObjectID(Projects[idx].ObjectID));

		if(FacilityProject != none)
		{
			Facility = XComGameState_FacilityXCom(History.GetGameStateForObjectID(FacilityProject.ProjectFocus.ObjectID));

			if(Facility != none)
			{
				if(Facility.GetMyTemplateName() == FacilityTemplate.DataName)
				{
					Total++;
				}
			}
		}
	}

	return Total;
}

//---------------------------------------------------------------------------------------
function int GetNumberOfFacilitiesOfType(X2FacilityTemplate FacilityTemplate)
{
	local XComGameStateHistory History;
	local XComGameState_FacilityXCom Facility;
	local int idx, iTotal;

	History = `XCOMHISTORY;
	iTotal = 0;
	for(idx = 0; idx < Facilities.Length; idx++)
	{
		Facility = XComGameState_FacilityXCom(History.GetGameStateForObjectID(Facilities[idx].ObjectID));

		if(Facility.GetMyTemplateName() == FacilityTemplate.DataName)
		{
			iTotal++;
		}
	}

	return iTotal;
}

//---------------------------------------------------------------------------------------
function int GetFacilityUpkeepCost()
{
	local XComGameStateHistory History;
	local XComGameState_FacilityXCom Facility;
	local int idx, iUpkeep;

	History = `XCOMHISTORY;
	iUpkeep = 0;
	for (idx = 0; idx < Facilities.Length; idx++)
	{
		Facility = XComGameState_FacilityXCom(History.GetGameStateForObjectID(Facilities[idx].ObjectID));
		iUpkeep += Facility.UpkeepCost;
	}

	return iUpkeep;
}

//---------------------------------------------------------------------------------------
function bool HasEmptyRoom()
{
	local XComGameState_HeadquartersRoom RoomState;
	local int idx;

	for(idx = 0; idx < Rooms.Length; idx++)
	{
		RoomState = XComGameState_HeadquartersRoom(`XCOMHISTORY.GetGameStateForObjectID(Rooms[idx].ObjectID));

		if(RoomState != none)
		{
			if(!RoomState.HasFacility() && !RoomState.ConstructionBlocked)
			{
				return true;
			}
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
function bool HasShieldedPowerCoil()
{
	local XComGameState_HeadquartersRoom RoomState;
	local int idx;

	for (idx = 0; idx < Rooms.Length; idx++)
	{
		RoomState = XComGameState_HeadquartersRoom(`XCOMHISTORY.GetGameStateForObjectID(Rooms[idx].ObjectID));

		if (RoomState != none && RoomState.HasShieldedPowerCoil())
		{
			return true;
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
function XComGameState_HeadquartersRoom GetRoom(int Index)
{
	local int idx;
	local XComGameState_HeadquartersRoom Room;

	for(idx = 0; idx < Rooms.Length; idx++)
	{
		Room = XComGameState_HeadquartersRoom(`XCOMHISTORY.GetGameStateForObjectID(Rooms[idx].ObjectID));

		if(Room.MapIndex == Index)
		{
			return Room;
		}
	}

	return none;
}

//---------------------------------------------------------------------------------------
function XComGameState_HeadquartersRoom GetRoomFromFacility(StateObjectReference FacilityRef)
{
	local int idx;
	local XComGameState_HeadquartersRoom Room;

	for(idx = 0; idx < Rooms.Length; idx++)
	{
		Room = XComGameState_HeadquartersRoom(`XCOMHISTORY.GetGameStateForObjectID(Rooms[idx].ObjectID));
		if(Room.Facility == FacilityRef)
			return Room;
	}

	return none;
}

//---------------------------------------------------------------------------------------
static function UnlockAdjacentRooms(XComGameState NewGameState, XComGameState_HeadquartersRoom Room)
{
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersRoom RoomToUnlock;
	local int AdjustedMapIndex, GridStartIndex, GridEndIndex, NumRooms;

	GridStartIndex = 3;
	GridEndIndex = 14;
	AdjustedMapIndex = Room.MapIndex - GridStartIndex;
	NumRooms = GridEndIndex - GridStartIndex + 1;

	foreach NewGameState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
	{
		break;
	}

	if (AdjustedMapIndex % default.XComHeadquarters_RoomRowLength != 0) // not in the left hand column, so unlock the room to the left
	{
		RoomToUnlock = XComGameState_HeadquartersRoom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersRoom', XComHQ.Rooms[Room.MapIndex - 1].ObjectID));
		NewGameState.AddStateObject(RoomToUnlock);
		RoomToUnlock.Locked = false;
	}

	if (AdjustedMapIndex % default.XComHeadquarters_RoomRowLength != (default.XComHeadquarters_RoomRowLength - 1)) // not in the right hand column, so unlock the room to the right
	{
		RoomToUnlock = XComGameState_HeadquartersRoom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersRoom', XComHQ.Rooms[Room.MapIndex + 1].ObjectID));
		NewGameState.AddStateObject(RoomToUnlock);
		RoomToUnlock.Locked = false;
	}

	if (AdjustedMapIndex >= default.XComHeadquarters_RoomRowLength) // not in the top row, so unlock the room above
	{
		RoomToUnlock = XComGameState_HeadquartersRoom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersRoom', XComHQ.Rooms[Room.MapIndex - default.XComHeadquarters_RoomRowLength].ObjectID));
		NewGameState.AddStateObject(RoomToUnlock);
		RoomToUnlock.Locked = false;
	}

	if (AdjustedMapIndex <= (NumRooms - default.XComHeadquarters_RoomRowLength)) // not in the bottom row, so unlock the room below
	{
		RoomToUnlock = XComGameState_HeadquartersRoom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersRoom', XComHQ.Rooms[Room.MapIndex + default.XComHeadquarters_RoomRowLength].ObjectID));
		NewGameState.AddStateObject(RoomToUnlock);
		RoomToUnlock.Locked = false;
	}
}

//---------------------------------------------------------------------------------------
function AddFacilityProject(StateObjectReference RoomRef, X2FacilityTemplate FacilityTemplate)
{
	local XComGameState NewGameState;
	local XComGameState_FacilityXCom FacilityStateObject;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersRoom RoomState;
	local XComGameState_HeadquartersProjectBuildFacility BuildProject;
	local XComGameState_StaffSlot BuildSlotState;
	local XComNarrativeMoment BuildStartedNarrative;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Adding Facility Project");
	FacilityStateObject = FacilityTemplate.CreateInstanceFromTemplate(NewGameState);
	NewGameState.AddStateObject(FacilityStateObject);

	RoomState = XComGameState_HeadquartersRoom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersRoom', RoomRef.ObjectID));
	NewGameState.AddStateObject(RoomState);
	RoomState.UnderConstruction = true;
	RoomState.UpdateRoomMap = true;
		
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', self.ObjectID));
	NewGameState.AddStateObject(XComHQ);
	
	BuildProject = XComGameState_HeadquartersProjectBuildFacility(NewGameState.CreateStateObject(class'XComGameState_HeadquartersProjectBuildFacility'));
	NewGameState.AddStateObject(BuildProject);
	BuildProject.SetProjectFocus(FacilityStateObject.GetReference(), NewGameState, RoomRef);
	XComHQ.Projects.AddItem(BuildProject.GetReference());

	XComHQ.PayStrategyCost(NewGameState, FacilityTemplate.Cost, FacilityBuildCostScalars);
	
	`XSTRATEGYSOUNDMGR.PlaySoundEvent("StrategyUI_Facility_Build");

	`XEVENTMGR.TriggerEvent('ConstructionStarted', BuildProject, BuildProject, NewGameState);

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	if(FacilityTemplate.ConstructionStartedNarrative != "")
	{
		BuildStartedNarrative = XComNarrativeMoment(`CONTENT.RequestGameArchetype(FacilityTemplate.ConstructionStartedNarrative));
		if(BuildStartedNarrative != None)
		{
			`HQPRES.UINarrative(BuildStartedNarrative);
		}
	}
	
	class'X2StrategyGameRulesetDataStructures'.static.CheckForPowerStateChange();
	class'X2StrategyGameRulesetDataStructures'.static.ForceUpdateObjectivesUI();
	
	// If an unstaffed engineer exists, alert the player that they could help build this facility
	BuildSlotState = RoomState.GetBuildSlot(0);
	if (BuildSlotState.IsEngineerSlot() && (XComHQ.GetNumberOfUnstaffedEngineers() > 0 || BuildSlotState.HasAvailableAdjacentGhosts()))
	{
		`HQPRES.UIBuildSlotOpen(RoomState.GetReference());
	}

	// Refresh XComHQ and see if we need to display a power warning
	XComHQ = class'UIUtilities_Strategy'.static.GetXComHQ();
	if (XComHQ.PowerState == ePowerState_Red && FacilityStateObject.GetPowerOutput() < 0)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Event: Warning No Power");
		`XEVENTMGR.TriggerEvent('WarningNoPower', , , NewGameState);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
	
	// force avenger rooms to update
	`GAME.GetGeoscape().m_kBase.SetAvengerVisibility(true);
}

//---------------------------------------------------------------------------------------
function String GetFacilityBuildEstimateString(StateObjectReference RoomRef, X2FacilityTemplate FacilityTemplate)
{
	local int  iHours, iDaysLeft;
	local XGParamTag kTag;
	local XComGameState NewGameState;
	local XComGameState_FacilityXCom FacilityState;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersProjectBuildFacility BuildProject;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("SHOULD NOT BE SUBMITTED");

	FacilityState = FacilityTemplate.CreateInstanceFromTemplate(NewGameState);
	NewGameState.AddStateObject(FacilityState);

	BuildProject = XComGameState_HeadquartersProjectBuildFacility(NewGameState.CreateStateObject(class'XComGameState_HeadquartersProjectBuildFacility'));
	NewGameState.AddStateObject(BuildProject);
	BuildProject.SetProjectFocus(FacilityState.GetReference(), NewGameState, RoomRef);

	iHours = BuildProject.GetProjectedNumHoursRemaining();

	kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
	iDaysLeft = class'X2StrategyGameRulesetDataStructures'.static.HoursToDays(iHours);

	if(iDaysLeft < 0)
	{
		iDaysLeft = 1;
	}

	kTag.IntValue0 = iDaysLeft;

	NewGameState.PurgeGameStateForObjectID(BuildProject.ObjectID);
	NewGameState.PurgeGameStateForObjectID(FacilityState.ObjectID);
	History.CleanupPendingGameState(NewGameState);

	return `XEXPAND.ExpandString((iDaysLeft != 1) ? strETADays : strETADay);
}

//---------------------------------------------------------------------------------------
function String GetFacilityBuildEngineerEstimateString(StateObjectReference BuildSlotRef, StateObjectReference EngineerRef)
{
	local int  iHours, iDaysLeft;
	local XGParamTag kTag;
	local XComGameState NewGameState;
	local XComGameState_StaffSlot SlotState;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersProjectBuildFacility BuildProject;
	local bool bProjectFound;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("SHOULD NOT BE SUBMITTED");

	SlotState = XComGameState_StaffSlot(NewGameState.CreateStateObject(class'XComGameState_StaffSlot', BuildSlotRef.ObjectID));
	NewGameState.AddStateObject(SlotState);
	SlotState.AssignedStaff = EngineerRef;
	bProjectFound = false;

	foreach History.IterateByClassType(class'XComGameState_HeadquartersProjectBuildFacility', BuildProject)
	{
		if(BuildProject.AuxilaryReference == SlotState.Room)
		{
			BuildProject = XComGameState_HeadquartersProjectBuildFacility(NewGameState.CreateStateObject(class'XComGameState_HeadquartersProjectBuildFacility', BuildProject.ObjectID));
			NewGameState.AddStateObject(BuildProject);
			BuildProject.UpdateWorkPerHour(NewGameState);
			bProjectFound = true;
			break;
		}
	}
	
	if(bProjectFound)
	{
		iHours = BuildProject.GetProjectedNumHoursRemaining();

		kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
		iDaysLeft = class'X2StrategyGameRulesetDataStructures'.static.HoursToDays(iHours);

		if(iDaysLeft < 0)
		{
			iDaysLeft = 1;
		}

		kTag.IntValue0 = iDaysLeft;

		History.CleanupPendingGameState(NewGameState);

		return `XEXPAND.ExpandString((iDaysLeft != 1) ? strETADays : strETADay);
	}
	else
	{
		History.CleanupPendingGameState(NewGameState);
		return "ERROR BUILD PROJECT NOT FOUND";
	}
	
}

//---------------------------------------------------------------------------------------
function CancelFacilityProject(XComGameState_HeadquartersProjectBuildFacility FacilityProject)
{
	local HeadquartersOrderInputContext OrderInput;

	OrderInput.OrderType = eHeadquartersOrderType_CancelFacilityConstruction;
	OrderInput.AcquireObjectReference = FacilityProject.GetReference();

	class'XComGameStateContext_HeadquartersOrder'.static.IssueHeadquartersOrder(OrderInput);

	class'X2StrategyGameRulesetDataStructures'.static.ForceUpdateObjectivesUI();

	// force refresh of rooms
	`GAME.GetGeoscape().m_kBase.SetAvengerVisibility(true);
}

//---------------------------------------------------------------------------------------
function XComGameState_HeadquartersProjectBuildFacility GetFacilityProject(StateObjectReference RoomRef)
{
	local int iProject;
	local XComGameState_HeadquartersProjectBuildFacility FacilityProject;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	for(iProject = 0; iProject < Projects.Length; iProject++)
	{
		FacilityProject = XComGameState_HeadquartersProjectBuildFacility(History.GetGameStateForObjectID(Projects[iProject].ObjectID));

		if(FacilityProject != none)
		{
			if(RoomRef == FacilityProject.AuxilaryReference)
			{
				return FacilityProject;
			}
		}
	}

	return none;
}

//---------------------------------------------------------------------------------------
function CancelClearRoomProject(XComGameState_HeadquartersProjectClearRoom ClearRoomProject)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersRoom Room;
	local HeadquartersOrderInputContext OrderInput;
	local X2SpecialRoomFeatureTemplate SpecialRoomTemplate;
	local XComGameState_HeadquartersXCom XComHQ;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Refund Special Feature Project");
	Room = XComGameState_HeadquartersRoom(`XCOMHISTORY.GetGameStateForObjectID(ClearRoomProject.ProjectFocus.ObjectID));
	SpecialRoomTemplate = Room.GetSpecialFeature();
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', self.ObjectID));
	NewGameState.AddStateObject(XComHQ);
	XComHQ.RefundStrategyCost(NewGameState, SpecialRoomTemplate.GetDepthBasedCostFn(Room), RoomSpecialFeatureCostScalars);
	
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	OrderInput.OrderType = eHeadquartersOrderType_CancelClearRoom;
	OrderInput.AcquireObjectReference = ClearRoomProject.GetReference();

	class'XComGameStateContext_HeadquartersOrder'.static.IssueHeadquartersOrder(OrderInput);

	// force refresh of rooms
	`GAME.GetGeoscape().m_kBase.SetAvengerVisibility(true);
}

//---------------------------------------------------------------------------------------
function XComGameState_HeadquartersProjectClearRoom GetClearRoomProject(StateObjectReference RoomRef)
{
	local int idx;
	local XComGameState_HeadquartersProjectClearRoom ClearRoomProject;
		
	for (idx = 0; idx < Projects.Length; idx++)
	{
		ClearRoomProject = XComGameState_HeadquartersProjectClearRoom(`XCOMHISTORY.GetGameStateForObjectID(Projects[idx].ObjectID));

		if (ClearRoomProject != none)
		{
			if (RoomRef == ClearRoomProject.ProjectFocus)
			{
				return ClearRoomProject;
			}
		}
	}

	return none;
}

//---------------------------------------------------------------------------------------
function CancelUpgradeFacilityProject(XComGameState_HeadquartersProjectUpgradeFacility UpgradeProject)
{
	local XComGameState NewGameState;
	local XComGameState_FacilityUpgrade Upgrade;
	local X2FacilityUpgradeTemplate UpgradeTemplate;
	local HeadquartersOrderInputContext OrderInput;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Refund Facility Upgrade Project");
	Upgrade = XComGameState_FacilityUpgrade(`XCOMHISTORY.GetGameStateForObjectID(UpgradeProject.ProjectFocus.ObjectID));
	UpgradeTemplate = Upgrade.GetMyTemplate();
	RefundStrategyCost(NewGameState, UpgradeTemplate.Cost, FacilityUpgradeCostScalars);

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	OrderInput.OrderType = eHeadquartersOrderType_CancelUpgradeFacility;
	OrderInput.AcquireObjectReference = UpgradeProject.GetReference();

	class'XComGameStateContext_HeadquartersOrder'.static.IssueHeadquartersOrder(OrderInput);

	// force refresh of rooms
	`GAME.GetGeoscape().m_kBase.SetAvengerVisibility(true);
}

//---------------------------------------------------------------------------------------
function XComGameState_HeadquartersProjectUpgradeFacility GetUpgradeFacilityProject(StateObjectReference FacilityRef)
{
	local int idx;
	local XComGameState_HeadquartersProjectUpgradeFacility UpgradeFacilityProject;

	for (idx = 0; idx < Projects.Length; idx++)
	{
		UpgradeFacilityProject = XComGameState_HeadquartersProjectUpgradeFacility(`XCOMHISTORY.GetGameStateForObjectID(Projects[idx].ObjectID));

		if (UpgradeFacilityProject != none)
		{
			if (FacilityRef == UpgradeFacilityProject.AuxilaryReference)
			{
				return UpgradeFacilityProject;
			}
		}
	}

	return none;
}

//---------------------------------------------------------------------------------------
function XComGameState_HeadquartersProjectTrainRookie GetTrainRookieProject(StateObjectReference UnitRef)
{
	local int idx;
	local XComGameState_HeadquartersProjectTrainRookie TrainRookieProject;

	for (idx = 0; idx < Projects.Length; idx++)
	{
		TrainRookieProject = XComGameState_HeadquartersProjectTrainRookie(`XCOMHISTORY.GetGameStateForObjectID(Projects[idx].ObjectID));

		if (TrainRookieProject != none)
		{
			if (UnitRef == TrainRookieProject.ProjectFocus)
			{
				return TrainRookieProject;
			}
		}
	}

	return none;
}

//---------------------------------------------------------------------------------------
function XComGameState_HeadquartersProjectRespecSoldier GetRespecSoldierProject(StateObjectReference UnitRef)
{
	local int idx;
	local XComGameState_HeadquartersProjectRespecSoldier RespecSoldierProject;

	for (idx = 0; idx < Projects.Length; idx++)
	{
		RespecSoldierProject = XComGameState_HeadquartersProjectRespecSoldier(`XCOMHISTORY.GetGameStateForObjectID(Projects[idx].ObjectID));

		if (RespecSoldierProject != none)
		{
			if (UnitRef == RespecSoldierProject.ProjectFocus)
			{
				return RespecSoldierProject;
			}
		}
	}

	return none;
}

//---------------------------------------------------------------------------------------
function XComGameState_HeadquartersProjectPsiTraining GetPsiTrainingProject(StateObjectReference UnitRef)
{
	local int idx;
	local XComGameState_HeadquartersProjectPsiTraining PsiProject;

	for (idx = 0; idx < Projects.Length; idx++)
	{
		PsiProject = XComGameState_HeadquartersProjectPsiTraining(`XCOMHISTORY.GetGameStateForObjectID(Projects[idx].ObjectID));

		if (PsiProject != none)
		{
			if (UnitRef == PsiProject.ProjectFocus)
			{
				return PsiProject;
			}
		}
	}

	return none;
}

//---------------------------------------------------------------------------------------
function bool HasPausedPsiAbilityTrainingProject(StateObjectReference UnitRef, SoldierAbilityInfo AbilityInfo)
{
	local int idx;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersProjectPsiTraining PsiTrainingProject;

	History = `XCOMHISTORY;

	for (idx = 0; idx < Projects.Length; idx++)
	{
		PsiTrainingProject = XComGameState_HeadquartersProjectPsiTraining(History.GetGameStateForObjectID(Projects[idx].ObjectID));

		if (PsiTrainingProject != none && PsiTrainingProject.ProjectFocus == UnitRef &&
			PsiTrainingProject.iAbilityRank == AbilityInfo.iRank && PsiTrainingProject.iAbilityBranch == AbilityInfo.iBranch)
		{
			return true;
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
function XComGameState_HeadquartersProjectPsiTraining GetPausedPsiAbilityTrainingProject(StateObjectReference UnitRef, SoldierAbilityInfo AbilityInfo)
{
	local int idx;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersProjectPsiTraining PsiTrainingProject;

	History = `XCOMHISTORY;

	for (idx = 0; idx < Projects.Length; idx++)
	{
		PsiTrainingProject = XComGameState_HeadquartersProjectPsiTraining(History.GetGameStateForObjectID(Projects[idx].ObjectID));

		if (PsiTrainingProject != none && PsiTrainingProject.ProjectFocus == UnitRef &&
			PsiTrainingProject.iAbilityRank == AbilityInfo.iRank && PsiTrainingProject.iAbilityBranch == AbilityInfo.iBranch)
		{
			return PsiTrainingProject;
		}
	}

	return none;
}

//---------------------------------------------------------------------------------------
function bool HasActiveConstructionProject()
{
	local int idx;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersProjectClearRoom ClearRoomProject;
	local XComGameState_HeadquartersProjectBuildFacility BuildFacilityProject;

	History = `XCOMHISTORY;

	for (idx = 0; idx < Projects.Length; idx++)
	{
		ClearRoomProject = XComGameState_HeadquartersProjectClearRoom(History.GetGameStateForObjectID(Projects[idx].ObjectID));
		BuildFacilityProject = XComGameState_HeadquartersProjectBuildFacility(History.GetGameStateForObjectID(Projects[idx].ObjectID));

		if (ClearRoomProject != none || BuildFacilityProject != none)
		{
			return true;
		}
	}

	return false;
}

//#############################################################################################
//----------------   INVENTORY MANAGEMENT   ---------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function bool HasItem(X2ItemTemplate ItemTemplate, optional int Quantity = 1)
{
	local XComGameState_Item ItemState;
	local int idx;

	for(idx = 0; idx < Inventory.Length; idx++)
	{
		ItemState = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(Inventory[idx].ObjectID));

		if(ItemState != none)
		{
			if(ItemState.GetMyTemplateName() == ItemTemplate.DataName && ItemState.Quantity >= Quantity)
			{
				return true;
			}
		}
	}

	return false;
}
//---------------------------------------------------------------------------------------
function bool HasItemByName(name ItemTemplateName)
{
	local X2ItemTemplate ItemTemplate;

	ItemTemplate = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(ItemTemplateName);

	if( ItemTemplate != none )
	{
		return HasItem(ItemTemplate);
	}

	return false;
}

//---------------------------------------------------------------------------------------
function bool HasUnModifiedItem(XComGameState AddToGameState, X2ItemTemplate ItemTemplate, out XComGameState_Item ItemState, optional bool bLoot = false, optional XComGameState_Item CombatSimTest)
{
	local int idx;

	if(bLoot)
	{
		for(idx = 0; idx < LootRecovered.Length; idx++)
		{
			ItemState = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(LootRecovered[idx].ObjectID));

			if(ItemState == none)
			{
				ItemState = XComGameState_Item(AddToGameState.GetGameStateForObjectID(LootRecovered[idx].ObjectID));
			}

			if(ItemState != none)
			{
				if (ItemState.GetMyTemplateName() == ItemTemplate.DataName && (ItemState.Quantity > 0 || ItemState.GetMyTemplate().ItemCat == 'resource') && !ItemState.HasBeenModified())
				{
					if(ItemState.GetMyTemplate().ItemCat == 'combatsim')
					{
						if(ItemState.StatBoosts.Length > 0 && CombatSimTest.StatBoosts.Length > 0 && ItemState.StatBoosts[0].Boost == CombatSimTest.StatBoosts[0].Boost && ItemState.StatBoosts[0].StatType == CombatSimTest.StatBoosts[0].StatType)
						{
							return true;
						}
					}
					else
					{
						return true;
					}
				}
			}
		}
	}
	else
	{
		for(idx = 0; idx < Inventory.Length; idx++)
		{
			ItemState = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(Inventory[idx].ObjectID));

			if(ItemState == none)
			{
				ItemState = XComGameState_Item(AddToGameState.GetGameStateForObjectID(Inventory[idx].ObjectID));
			}

			if(ItemState != none)
			{
				if (ItemState.GetMyTemplateName() == ItemTemplate.DataName && (ItemState.Quantity > 0 || ItemState.GetMyTemplate().ItemCat == 'resource') && !ItemState.HasBeenModified())
				{
					if(ItemState.GetMyTemplate().ItemCat == 'combatsim')
					{
						if(ItemState.StatBoosts.Length > 0 && CombatSimTest.StatBoosts.Length > 0 && ItemState.StatBoosts[0].Boost == CombatSimTest.StatBoosts[0].Boost && ItemState.StatBoosts[0].StatType == CombatSimTest.StatBoosts[0].StatType)
						{
							return true;
						}
					}
					else
					{
						return true;
					}
				}
			}
		}
	}
	
	return false;
}

//---------------------------------------------------------------------------------------
// returns true if HQ has been modified (you need to update the gamestate)
function bool PutItemInInventory(XComGameState AddToGameState, XComGameState_Item ItemState, optional bool bLoot = false)
{
	local bool HQModified;
	local XComGameState_Item InventoryItemState, NewInventoryItemState;
	local X2ItemTemplate ItemTemplate;

	ItemTemplate = ItemState.GetMyTemplate();

	if( ItemState.HasBeenModified() || ItemTemplate.bAlwaysUnique )
	{
		HQModified = true;

		if(bLoot)
		{
			LootRecovered.AddItem(ItemState.GetReference());
		}
		else
		{
			AddItemToHQInventory(ItemState);
		}
	}
	else
	{
		if(!ItemState.IsStartingItem() && !ItemState.GetMyTemplate().bInfiniteItem)
		{
			if( HasUnModifiedItem(AddToGameState, ItemTemplate, InventoryItemState, bLoot, ItemState) )
			{
				HQModified = false;
				
				if(InventoryItemState.ObjectID != ItemState.ObjectID)
				{
					NewInventoryItemState = XComGameState_Item(AddToGameState.CreateStateObject(class'XComGameState_Item', InventoryItemState.ObjectID));
					NewInventoryItemState.Quantity += ItemState.Quantity;
					AddToGameState.AddStateObject(NewInventoryItemState);
					AddToGameState.RemoveStateObject(ItemState.ObjectID);
				}
			}
			else
			{
				HQModified = true;

				if(bLoot)
				{
					LootRecovered.AddItem(ItemState.GetReference());
				}
				else
				{
					AddItemToHQInventory(ItemState);
				}
			}
		}
		else
		{
			HQModified = false;
			AddToGameState.RemoveStateObject(ItemState.ObjectID);
		}
	}

	if( !bLoot && ItemTemplate.OnAcquiredFn != None )
	{
		HQModified = ItemTemplate.OnAcquiredFn(AddToGameState) || HQModified;
	}

	// this item awards other items when acquired
	if( !bLoot && ItemTemplate.ResourceTemplateName != '' && ItemTemplate.ResourceQuantity > 0 )
	{
		ItemTemplate = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(ItemTemplate.ResourceTemplateName);
		ItemState = ItemTemplate.CreateInstanceFromTemplate(AddToGameState);
		AddToGameState.AddStateObject(ItemState);
		ItemState.Quantity = ItemTemplate.ResourceQuantity;

		if( ItemState != none )
		{
			HQModified = PutItemInInventory(AddToGameState, ItemState) || HQModified;
		}
	}

	return HQModified;
}

function AddItemToHQInventory(XComGameState_Item ItemState)
{
	local Name ItemTemplateName;
	local int EverAcquireInventoryIndex;

	ItemTemplateName = ItemState.GetMyTemplateName();

	EverAcquireInventoryIndex = EverAcquiredInventoryTypes.Find(ItemTemplateName);
	if( EverAcquireInventoryIndex == INDEX_NONE )
	{
		EverAcquiredInventoryTypes.AddItem(ItemTemplateName);
		EverAcquiredInventoryCounts.AddItem(ItemState.Quantity);
	}
	else
	{
		EverAcquiredInventoryCounts[EverAcquireInventoryIndex] += ItemState.Quantity;
	}

	Inventory.AddItem(ItemState.GetReference());
}

function bool UnpackCacheItems(XComGameState NewGameState)
{
	local XComGameStateHistory History;
	local XComGameState_Item ItemState;
	local X2ItemTemplate ItemTemplate, UnpackedItemTemplate;
	local bool bXComHQModified;
	local int i;

	History = `XCOMHISTORY;

	// Open up any caches we received and add their contents to the loot list
	for (i = 0; i < LootRecovered.Length; i++)
	{
		ItemState = XComGameState_Item(History.GetGameStateForObjectID(LootRecovered[i].ObjectID));
		ItemTemplate = ItemState.GetMyTemplate();

		// this item awards other items when acquired
		if (ItemTemplate.ResourceTemplateName != '' && ItemTemplate.ResourceQuantity > 0)
		{
			UnpackedItemTemplate = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(ItemTemplate.ResourceTemplateName);
			ItemState = UnpackedItemTemplate.CreateInstanceFromTemplate(NewGameState);
			NewGameState.AddStateObject(ItemState);
			ItemState.Quantity = ItemTemplate.ResourceQuantity;

			if (ItemState != none)
			{
				// Remove the cache item which was opened
				LootRecovered.Remove(i, 1);
				i--;

				// Then add whatever it gave us
				LootRecovered.AddItem(ItemState.GetReference());
				bXComHQModified = true;
			}
		}
	}

	return bXComHQModified;
}

//---------------------------------------------------------------------------------------
// 
function XComGameState_Item GetItemByName(name ItemTemplateName)
{
	local XComGameStateHistory History;
	local XComGameState_Item InventoryItemState;
	local int i;

	History = `XCOMHISTORY;

	for( i = 0; i < Inventory.Length; i++ )
	{
		InventoryItemState = XComGameState_Item(History.GetGameStateForObjectID(Inventory[i].ObjectId));

		if( InventoryItemState != none && InventoryItemState.GetMyTemplateName() == ItemTemplateName )
		{
			return InventoryItemState;
		}
	}

	return none;
}

//---------------------------------------------------------------------------------------
function int GetNumItemInInventory(name ItemTemplateName)
{
	local XComGameState_Item ItemState;

	ItemState = GetItemByName(ItemTemplateName);
	if (ItemState != none)
	{
		return ItemState.Quantity;
	}

	return 0;
}

//---------------------------------------------------------------------------------------
// returns true if HQ has been modified (you need to update the gamestate)
// ItemRef is StateObjectReference of item in inventory, ItemState is the item you are getting
function bool GetItemFromInventory(XComGameState AddToGameState, StateObjectReference ItemRef, out XComGameState_Item ItemState)
{
	local XComGameState_Item InventoryItemState, NewInventoryItemState;
	local bool HQModified;

	InventoryItemState = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(ItemRef.ObjectID));

	if(InventoryItemState != none)
	{
		if((!InventoryItemState.IsStartingItem() && !InventoryItemState.GetMyTemplate().bInfiniteItem) || InventoryItemState.HasBeenModified())
		{
			if(InventoryItemState.Quantity > 1)
			{
				HQModified = false;
				NewInventoryItemState = XComGameState_Item(AddToGameState.CreateStateObject(class'XComGameState_Item', InventoryItemState.ObjectID));
				NewInventoryItemState.Quantity--;
				AddToGameState.AddStateObject(NewInventoryItemState);
				ItemState = XComGameState_Item(AddToGameState.CreateStateObject(class'XComGameState_Item'));
				ItemState.OnCreation(InventoryItemState.GetMyTemplate());
				ItemState.StatBoosts = NewInventoryItemState.StatBoosts; // Make sure the stat boosts are the same. Used for PCS.
				AddToGameState.AddStateObject(ItemState);
			}
			else
			{
				HQModified = true;
				Inventory.RemoveItem(ItemRef);
				ItemState = InventoryItemState;
			}
		}
		else
		{
			HQModified = false;
			ItemState = XComGameState_Item(AddToGameState.CreateStateObject(class'XComGameState_Item'));
			ItemState.OnCreation(InventoryItemState.GetMyTemplate());
			AddToGameState.AddStateObject(ItemState);
		}
	}

	return HQModified;
}

//---------------------------------------------------------------------------------------
// returns true if HQ has been modified (you need to update the gamestate)
// ItemRef is StateObjectReference of item in inventory, Quantity is how many to remove
function bool RemoveItemFromInventory(XComGameState AddToGameState, StateObjectReference ItemRef, int Quantity)
{
	local XComGameState_Item InventoryItemState, NewInventoryItemState;
	local bool HQModified;

	InventoryItemState = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(ItemRef.ObjectID));

	if(InventoryItemState != none)
	{
		if(!InventoryItemState.IsStartingItem() && !InventoryItemState.GetMyTemplate().bInfiniteItem)
		{
			if (ResourceItems.Find(InventoryItemState.GetMyTemplateName()) != INDEX_NONE) // If this item is a resource, use the AddResource method instead
			{
				AddResource(AddToGameState, InventoryItemState.GetMyTemplateName(), -1*Quantity);
			}
			else if(InventoryItemState.Quantity > Quantity)
			{
				HQModified = false;
				NewInventoryItemState = XComGameState_Item(AddToGameState.CreateStateObject(class'XComGameState_Item', InventoryItemState.ObjectID));
				NewInventoryItemState.Quantity -= Quantity;
				AddToGameState.AddStateObject(NewInventoryItemState);
			}
			else
			{
				HQModified = true;
				Inventory.RemoveItem(ItemRef);
			}
		}
		else
		{
			return false;
		}
	}

	return HQModified;
}

//---------------------------------------------------------------------------------------
function array<XComGameState_Item> GetAllCombatSimsInInventory()
{
	local XComGameState_Item ItemState;
	local array<XComGameState_Item> AllCombatSims;
	local int idx;

	for(idx = 0; idx < Inventory.Length; idx++)
	{
		ItemState = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(Inventory[idx].ObjectID));

		if(ItemState != none)
		{
			if(ItemState.GetMyTemplate().ItemCat == 'combatsim')
			{
				AllCombatSims.AddItem(ItemState);
			}
		}
	}

	return AllCombatSims;
}

function bool HasCombatSimsInInventory()
{
	local array<XComGameState_Item> AllCombatSims;
	AllCombatSims = GetAllCombatSimsInInventory();
	return AllCombatSims.Length > 0;
}

//---------------------------------------------------------------------------------------

function array<XComGameState_Item> GetAllWeaponUpgradesInInventory()
{
	local XComGameState_Item ItemState;
	local array<XComGameState_Item> AllWeaponUpgrades;
	local int idx;

	for(idx = 0; idx < Inventory.Length; idx++)
	{
		ItemState = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(Inventory[idx].ObjectID));

		if(ItemState != none)
		{
			if(ItemState.GetMyTemplate().ItemCat == 'upgrade')
			{
				AllWeaponUpgrades.AddItem(ItemState);
			}
		}
	}

	return AllWeaponUpgrades;
}

function bool HasWeaponUpgradesInInventory()
{
	local array<XComGameState_Item> AllWeaponUpgrades;
	AllWeaponUpgrades = GetAllWeaponUpgradesInInventory();
	return AllWeaponUpgrades.Length > 0;
}

//---------------------------------------------------------------------------------------
function array<StateObjectReference> GetTradingPostItems()
{
	local XComGameStateHistory History;
	local XComGameState_Item ItemState;
	local array<StateObjectReference> TradingPostItems;
	local int idx;

	History = `XCOMHISTORY;
	TradingPostItems.Length = 0;

	for(idx = 0; idx < Inventory.Length; idx++)
	{
		ItemState = XComGameState_Item(History.GetGameStateForObjectID(Inventory[idx].ObjectID));

		if(ItemState != none)
		{
			if(ItemState.GetMyTemplate().TradingPostValue > 0 && !ItemState.GetMyTemplate().StartingItem && 
			   !ItemState.GetMyTemplate().bInfiniteItem && !ItemState.IsNeededForGoldenPath())
			{
				TradingPostItems.AddItem(ItemState.GetReference());
			}
		}
	}

	return TradingPostItems;
}

//---------------------------------------------------------------------------------------
function array<XComGameState_Item> GetReverseEngineeringItems()
{
	local XComGameState_Item ItemState;
	local array<XComGameState_Item> ReverseEngineeringItems;
	local int idx;

	ReverseEngineeringItems.Length = 0;

	for(idx = 0; idx < Inventory.Length; idx++)
	{
		ItemState = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(Inventory[idx].ObjectID));

		if(ItemState != none)
		{
			if(ItemState.GetMyTemplate().ReverseEngineeringValue > 0)
			{
				ReverseEngineeringItems.AddItem(ItemState);
			}
		}
	}

	return ReverseEngineeringItems;
}

//---------------------------------------------------------------------------------------
function int GetItemBuildTime(X2ItemTemplate ItemTemplate, StateObjectReference FacilityRef)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_Item ItemState;
	local XComGameState_HeadquartersProjectBuildItem ItemProject;
	local int BuildHours;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("SHOULD NOT HAVE SUBMITTED");
	ItemState = ItemTemplate.CreateInstanceFromTemplate(NewGameState);
	NewGameState.AddStateObject(ItemState);

	ItemProject = XComGameState_HeadquartersProjectBuildItem(NewGameState.CreateStateObject(class'XComGameState_HeadquartersProjectBuildItem'));
	ItemProject.SetProjectFocus(ItemState.GetReference(), NewGameState, FacilityRef);

	if (!ItemProject.bInstant)
		BuildHours = ItemProject.GetProjectedNumHoursRemaining();
	else
		BuildHours = 0;

	NewGameState.PurgeGameStateForObjectID(ItemState.ObjectID);
	NewGameState.PurgeGameStateForObjectID(ItemProject.ObjectID);
	History.CleanupPendingGameState(NewGameState);

	return BuildHours;
}

//---------------------------------------------------------------------------------------
function int GetNumItemBeingBuilt(X2ItemTemplate ItemTemplate)
{
	local XComGameStateHistory History;
	local XComGameState_Item ItemState;
	local XComGameState_HeadquartersProjectBuildItem ItemProject;
	local int idx, iCount;

	History = `XCOMHISTORY;
	iCount = 0;

	for(idx = 0; idx < Projects.Length; idx++)
	{
		ItemProject = XComGameState_HeadquartersProjectBuildItem(History.GetGameStateForObjectID(Projects[idx].ObjectID));

		if(ItemProject != none)
		{
			ItemState = XComGameState_Item(History.GetGameStateForObjectID(ItemProject.ProjectFocus.ObjectID));

			if(ItemState != none)
			{
				if(ItemState.GetMyTemplateName() == ItemTemplate.DataName)
				{
					iCount++;
				}
			}
		}
	}

	return iCount;
}

//#############################################################################################
//----------------   RESOURCE MANAGEMENT   ----------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function AddResourceOrder(name ResourceTemplateName, int iQuantity)
{
	local HeadquartersOrderInputContext OrderInput;

	OrderInput.OrderType = eHeadquartersOrderType_AddResource;
	OrderInput.AquireObjectTemplateName = ResourceTemplateName;
	OrderInput.Quantity = iQuantity;

	class'XComGameStateContext_HeadquartersOrder'.static.IssueHeadquartersOrder(OrderInput);
}

function AddResource(XComGameState NewGameState, name ResourceTemplateName, int iQuantity)
{
	local XComGameState_Item ResourceItemState;
	local XComGameStateHistory History;
	local int idx, OldQuantity;
	local bool bFoundResource;

	if(iQuantity != 0)
	{
		History = `XCOMHISTORY;
		bFoundResource = false;

		for(idx = 0; idx < Inventory.Length; idx++)
		{
			ResourceItemState = XComGameState_Item(History.GetGameStateForObjectID(Inventory[idx].ObjectID));

			if(ResourceItemState != none)
			{
				if(ResourceItemState.GetMyTemplate().DataName == ResourceTemplateName)
				{
					bFoundResource = true;
					break;
				}
			}
		}

		if(bFoundResource)
		{
			OldQuantity = ResourceItemState.Quantity;
			ResourceItemState = XComGameState_Item(NewGameState.CreateStateObject(class'XComGameState_Item', ResourceItemState.ObjectID));
			ResourceItemState.Quantity += iQuantity;
			ResourceItemState.LastQuantityChange = iQuantity;

			if(ResourceItemState.Quantity < 0)
			{
				ResourceItemState.Quantity = 0;
				ResourceItemState.LastQuantityChange = -OldQuantity;
			}

			if(ResourceItemState.Quantity != OldQuantity)
			{
				NewGameState.AddStateObject(ResourceItemState);

				`XEVENTMGR.TriggerEvent( 'AddResource', ResourceItemState, , NewGameState );
			}
			else
			{
				NewGameState.PurgeGameStateForObjectID(ResourceItemState.ObjectID);
			}
		}
	}
}

//---------------------------------------------------------------------------------------
function int GetResourceAmount(name ResourceName)
{
	local XComGameStateHistory History;
	local XComGameState_Item ItemState;
	local int idx;

	History = `XCOMHISTORY;

	for(idx = 0; idx < Inventory.Length; idx++)
	{
		ItemState = XComGameState_Item(History.GetGameStateForObjectID(Inventory[idx].ObjectID));

		if(ItemState != none && ItemState.GetMyTemplateName() == ResourceName)
		{
			return ItemState.Quantity;
		}
	}

	return 0;
}

//---------------------------------------------------------------------------------------
function int GetSupplies()
{
	return GetResourceAmount('Supplies');
}

//---------------------------------------------------------------------------------------
function int GetIntel()
{
	return GetResourceAmount('Intel');
}

//---------------------------------------------------------------------------------------
function int GetAlienAlloys()
{
	return GetResourceAmount('AlienAlloy');
}

//---------------------------------------------------------------------------------------
function int GetEleriumDust()
{
	return GetResourceAmount('EleriumDust');
}

//---------------------------------------------------------------------------------------
function int GetEleriumCores()
{
	return GetResourceAmount('EleriumCore');
}

//#############################################################################################
//----------------   REQUIREMENT/COST CHECKING  -----------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
static function StrategyCost GetScaledStrategyCost(StrategyCost Cost, array<StrategyCostScalar> CostScalars, float DiscountPercent)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;
	local array<StrategyCostScalar> GlobalScalars;
	local StrategyCostScalar CostScalar;
	local StrategyCost NewCost;
	local ArtifactCost NewArtifactCost, NewResourceCost;
	local int idx, iDifficulty;
	
	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	GlobalScalars = class'X2StrategyGameRulesetDataStructures'.default.GlobalStrategyCostScalars;
	iDifficulty = `DIFFICULTYSETTING;

	// Add any cost scalars from AlienHQ which were triggered by Dark Events
	for(idx = 0; idx < AlienHQ.CostScalars.Length; idx++)
	{
		GlobalScalars.AddItem(AlienHQ.CostScalars[idx]);
	}

	for (idx = 0; idx < Cost.ArtifactCosts.Length; idx++)
	{
		NewArtifactCost.ItemTemplateName = Cost.ArtifactCosts[idx].ItemTemplateName;
		NewArtifactCost.Quantity = Round(Cost.ArtifactCosts[idx].Quantity * (1 - (DiscountPercent / 100.0)));

		foreach GlobalScalars(CostScalar)
		{
			if (Cost.ArtifactCosts[idx].ItemTemplateName == CostScalar.ItemTemplateName && iDifficulty == CostScalar.Difficulty)
			{
				NewArtifactCost.Quantity = Round(NewArtifactCost.Quantity * CostScalar.Scalar);
			}
		}

		foreach CostScalars(CostScalar)
		{
			if (Cost.ArtifactCosts[idx].ItemTemplateName == CostScalar.ItemTemplateName && iDifficulty == CostScalar.Difficulty)
			{
				NewArtifactCost.Quantity = Round(NewArtifactCost.Quantity * CostScalar.Scalar);
			}
		}

		NewCost.ArtifactCosts.AddItem(NewArtifactCost);
	}

	for (idx = 0; idx < Cost.ResourceCosts.Length; idx++)
	{
		NewResourceCost.ItemTemplateName = Cost.ResourceCosts[idx].ItemTemplateName;
		NewResourceCost.Quantity = Round(Cost.ResourceCosts[idx].Quantity * (1 - (DiscountPercent / 100.0)));

		foreach GlobalScalars(CostScalar)
		{
			if (Cost.ResourceCosts[idx].ItemTemplateName == CostScalar.ItemTemplateName && iDifficulty == CostScalar.Difficulty)
			{
				NewResourceCost.Quantity = Round(NewResourceCost.Quantity * CostScalar.Scalar);
			}
		}

		foreach CostScalars(CostScalar)
		{
			if (Cost.ResourceCosts[idx].ItemTemplateName == CostScalar.ItemTemplateName && iDifficulty == CostScalar.Difficulty)
			{
				NewResourceCost.Quantity = Round(NewResourceCost.Quantity * CostScalar.Scalar);
			}
		}

		NewCost.ResourceCosts.AddItem(NewResourceCost);
	}

	return NewCost;
}

//---------------------------------------------------------------------------------------
// Need to ensure that anytime this function is called the appropriate StrategyCostScalars are applied beforehand
function bool CanAffordResourceCost(name ResourceName, int Cost)
{
	return (GetResourceAmount(ResourceName) >= Cost);
}

//---------------------------------------------------------------------------------------
// Private function to ensure ArtifactCosts were modified by cost scalars
private function bool CanAffordArtifactCost(ArtifactCost ArtifactReq)
{
	return HasItem(class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(ArtifactReq.ItemTemplateName), ArtifactReq.Quantity);
}

//---------------------------------------------------------------------------------------
// Private function to ensure ArtifactCosts were modified by cost scalars
private function bool CanAffordAllArtifactCosts(array<ArtifactCost> ArtifactReqs)
{
	local bool CanAfford;
	local int idx;

	CanAfford = true;

	for(idx = 0; idx < ArtifactReqs.Length; idx++)
	{
		CanAfford = CanAffordArtifactCost(ArtifactReqs[idx]);

		if(!CanAfford)
			break;
	}

	return CanAfford;
}

//---------------------------------------------------------------------------------------
// Private function to ensure ArtifactCosts were modified by cost scalars
private function bool CanAffordAllResourceCosts(array<ArtifactCost> ResourceCosts)
{
	local bool CanAfford;
	local int idx;

	CanAfford = true;

	for(idx = 0; idx < ResourceCosts.Length; idx++)
	{
		CanAfford = CanAffordResourceCost(ResourceCosts[idx].ItemTemplateName, ResourceCosts[idx].Quantity);

		if(!CanAfford)
			break;
	}

	return CanAfford;
}

//---------------------------------------------------------------------------------------
function bool MeetsTechRequirements(array<name> RequiredTechs)
{
	local X2StrategyElementTemplateManager StratMgr;
	local X2TechTemplate TechTemplate;
	local int idx;
	
	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

	for(idx = 0; idx < RequiredTechs.Length; idx++)
	{
		TechTemplate = X2TechTemplate(StratMgr.FindStrategyElementTemplate(RequiredTechs[idx]));

		if(TechTemplate != none)
		{
			if(!TechTemplateIsResearched(TechTemplate))
			{
				return false;
			}
		}
		else
		{
			`Redscreen("Bad Tech Prereq name:" @ string(RequiredTechs[idx]));
		}
	}

	return true;
}

//---------------------------------------------------------------------------------------
function bool MeetsItemRequirements(array<name> RequiredItems, optional bool bFailOnEmpty = false)
{
	local X2ItemTemplateManager ItemMgr;
	local X2ItemTemplate ItemTemplate;
	local int idx;

	if(bFailOnEmpty && RequiredItems.Length == 0)
	{
		return false;
	}

	ItemMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

	for(idx = 0; idx < RequiredItems.Length; idx++)
	{
		ItemTemplate = ItemMgr.FindItemTemplate(RequiredItems[idx]);

		if(ItemTemplate != none)
		{
			if(!HasItem(ItemTemplate))
			{
				return false;
			}
		}
		else
		{
			`Redscreen("Bad Item Prereq name:" @ string(RequiredItems[idx]));
		}
	}

	return true;
}

//---------------------------------------------------------------------------------------
function bool MeetsItemQuantityRequirements(array<ArtifactCost> RequiredItemQuantities)
{
	local int idx;
		
	for (idx = 0; idx < RequiredItemQuantities.Length; idx++)
	{
		if (!CanAffordArtifactCost(RequiredItemQuantities[idx]))
		{
			return false;
		}
	}

	return true;
}

//---------------------------------------------------------------------------------------
function bool MeetsFacilityRequirements(array<name> RequiredFacilities)
{
	local X2StrategyElementTemplateManager StratMgr;
	local X2FacilityTemplate FacilityTemplate;
	local int idx;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

	for(idx = 0; idx < RequiredFacilities.Length; idx++)
	{
		FacilityTemplate = X2FacilityTemplate(StratMgr.FindStrategyElementTemplate(RequiredFacilities[idx]));

		if(FacilityTemplate != none)
		{
			if(!HasFacilityByName(FacilityTemplate.DataName))
			{
				return false;
			}
		}
		else
		{
			`Redscreen("Bad Facility Prereq name:" @ string(RequiredFacilities[idx]));
		}
	}

	return true;
}

//---------------------------------------------------------------------------------------
function bool MeetsUpgradeRequirements(array<name> RequiredUpgrades)
{
	local X2StrategyElementTemplateManager StratMgr;
	local X2FacilityUpgradeTemplate UpgradeTemplate;
	local int idx;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

	for(idx = 0; idx < RequiredUpgrades.Length; idx++)
	{
		UpgradeTemplate = X2FacilityUpgradeTemplate(StratMgr.FindStrategyElementTemplate(RequiredUpgrades[idx]));

		if(UpgradeTemplate != none)
		{
			if(!HasFacilityUpgradeByName(UpgradeTemplate.DataName))
			{
				return false;
			}
		}
		else
		{
			`Redscreen("Bad Upgrade Prereq name:" @ string(RequiredUpgrades[idx]));
		}
	}

	return true;
}

function bool MeetsObjectiveRequirements(array<Name> RequiredObjectives)
{
	local X2StrategyElementTemplateManager StratMgr;
	local X2ObjectiveTemplate ObjectiveTemplate;
	local int idx;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

	for( idx = 0; idx < RequiredObjectives.Length; idx++ )
	{
		ObjectiveTemplate = X2ObjectiveTemplate(StratMgr.FindStrategyElementTemplate(RequiredObjectives[idx]));

		if( ObjectiveTemplate != None )
		{
			if( !IsObjectiveCompleted(ObjectiveTemplate.DataName) )
			{
				return false;
			}
		}
		else
		{
			`Redscreen("Bad Objective Prereq name:" @ string(RequiredObjectives[idx]));
		}
	}

	return true;
}

//---------------------------------------------------------------------------------------
function bool MeetsScienceAndEngineeringGates(int RequiredScience, int RequiredEngineering)
{
	return MeetsScienceGates(RequiredScience) && MeetsEngineeringGates(RequiredEngineering);
}

//---------------------------------------------------------------------------------------
function bool MeetsScienceGates(int RequiredScience)
{
	// The "-5" accounts for Tygan starting at level 10
	return Max((GetScienceScore() - 5),0) >= RequiredScience;
}

//---------------------------------------------------------------------------------------
function bool MeetsEngineeringGates(int RequiredEngineering)
{
	return GetEngineeringScore() >= RequiredEngineering;
}

//---------------------------------------------------------------------------------------
function bool MeetsSoldierGates(int RequiredRank, Name RequiredClass, bool RequiredClassRankCombo)
{
	if (RequiredClassRankCombo)
	{
		return MeetsSoldierRankClassCombo(RequiredRank, RequiredClass);
	}
	else
	{
		return MeetsSoldierRankGates(RequiredRank) && MeetsSoldierClassGates(RequiredClass);
	}	
}

//---------------------------------------------------------------------------------------
function bool MeetsSoldierRankGates(int RequiredRank)
{
	local XComGameState_Unit Soldier;
	local int idx;

	if (RequiredRank == 0)
		return true;

	for (idx = 0; idx < Crew.Length; idx++)
	{
		Soldier = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Crew[idx].ObjectID));

		if (Soldier != none && Soldier.IsASoldier())
		{
			// Check if rank gate is met, and the soldier is not a Psi Op
			if (Soldier.GetRank() >= RequiredRank && Soldier.GetSoldierClassTemplateName() != 'PsiOperative')
			{
				return true;
			}
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
function bool MeetsSoldierClassGates(Name RequiredClass)
{
	local XComGameState_Unit Soldier;
	local int idx;

	if (RequiredClass == '')
		return true;

	for (idx = 0; idx < Crew.Length; idx++)
	{
		Soldier = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Crew[idx].ObjectID));

		if (Soldier != none)
		{
			if (Soldier.GetSoldierClassTemplate().DataName == RequiredClass)
			{
				return true;
			}
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
function bool MeetsSoldierRankClassCombo(int RequiredRank, Name RequiredClass)
{
	local XComGameState_Unit Soldier;
	local int idx;

	for (idx = 0; idx < Crew.Length; idx++)
	{
		Soldier = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(Crew[idx].ObjectID));

		if (Soldier != none && Soldier.IsASoldier())
		{
			if (Soldier.GetSoldierClassTemplate().DataName == RequiredClass && Soldier.GetRank() >= RequiredRank)
			{
				return true;
			}
		}
	}

	return false;
}
	
function bool MeetsSpecialRequirements(delegate<X2StrategyGameRulesetDataStructures.SpecialRequirementsDelegate> SpecialRequirementsFn)
{
	if( SpecialRequirementsFn != None )
	{
		return SpecialRequirementsFn();
	}

	return true;
}

//---------------------------------------------------------------------------------------
event bool MeetsAllStrategyRequirements(StrategyRequirement Requirement)
{
	return (MeetsSpecialRequirements(Requirement.SpecialRequirementsFn) &&
			MeetsTechRequirements(Requirement.RequiredTechs) && 
			(MeetsItemRequirements(Requirement.RequiredItems) || MeetsItemRequirements(Requirement.AlternateRequiredItems, true)) &&
			MeetsItemQuantityRequirements(Requirement.RequiredItemQuantities) &&
			MeetsFacilityRequirements(Requirement.RequiredFacilities) && 
			MeetsUpgradeRequirements(Requirement.RequiredUpgrades) && 
			MeetsObjectiveRequirements(Requirement.RequiredObjectives) &&
			MeetsScienceAndEngineeringGates(Requirement.RequiredScienceScore, Requirement.RequiredEngineeringScore) &&
			MeetsSoldierGates(Requirement.RequiredHighestSoldierRank, Requirement.RequiredSoldierClass, Requirement.RequiredSoldierRankClassCombo));
}

//---------------------------------------------------------------------------------------
function bool MeetsEnoughRequirementsToBeVisible(StrategyRequirement Requirement)
{
	return (MeetsSpecialRequirements(Requirement.SpecialRequirementsFn) && 
			(MeetsTechRequirements(Requirement.RequiredTechs) || Requirement.bVisibleIfTechsNotMet) &&
			((MeetsItemRequirements(Requirement.RequiredItems) || MeetsItemRequirements(Requirement.AlternateRequiredItems, true)) || Requirement.bVisibleIfItemsNotMet) &&
			(MeetsFacilityRequirements(Requirement.RequiredFacilities) || Requirement.bVisibleIfFacilitiesNotMet) &&
			(MeetsUpgradeRequirements(Requirement.RequiredUpgrades) || Requirement.bVisibleIfUpgradesNotMet) &&
			(MeetsObjectiveRequirements(Requirement.RequiredObjectives) || Requirement.bVisibleIfObjectivesNotMet) &&
			(MeetsScienceAndEngineeringGates(Requirement.RequiredScienceScore, Requirement.RequiredEngineeringScore) || Requirement.bVisibleIfPersonnelGatesNotMet) &&
			(MeetsSoldierGates(Requirement.RequiredHighestSoldierRank, Requirement.RequiredSoldierClass, Requirement.RequiredSoldierRankClassCombo) || Requirement.bVisibleIfSoldierRankGatesNotMet));
}

//---------------------------------------------------------------------------------------
function bool CanAffordAllStrategyCosts(StrategyCost Cost, array<StrategyCostScalar> CostScalars, optional float DiscountPercent)
{
	local StrategyCost ScaledCost;

	ScaledCost = GetScaledStrategyCost(Cost, CostScalars, DiscountPercent);

	return (CanAffordAllResourceCosts(ScaledCost.ResourceCosts) && CanAffordAllArtifactCosts(ScaledCost.ArtifactCosts));
}

//---------------------------------------------------------------------------------------
function bool MeetsRequirmentsAndCanAffordCost(StrategyRequirement Requirement, StrategyCost Cost, array<StrategyCostScalar> CostScalars, optional float DiscountPercent)
{
	return (MeetsAllStrategyRequirements(Requirement) && CanAffordAllStrategyCosts(Cost, CostScalars, DiscountPercent));
}

//---------------------------------------------------------------------------------------
function bool MeetsCommodityRequirements(Commodity CommodityObject)
{
	return MeetsAllStrategyRequirements(CommodityObject.Requirements);
}

//---------------------------------------------------------------------------------------
function bool CanAffordCommodity(Commodity CommodityObject)
{
	return CanAffordAllStrategyCosts(CommodityObject.Cost, CommodityObject.CostScalars, CommodityObject.DiscountPercent);
}

//---------------------------------------------------------------------------------------
function BuyCommodity(XComGameState NewGameState, Commodity CommodityObject, optional StateObjectReference AuxRef)
{
	ReceiveCommodityReward(NewGameState, CommodityObject, AuxRef);
	PayCommodityCost(NewGameState, CommodityObject);
}

//---------------------------------------------------------------------------------------
// Private function to ensure Commodity ArtifactCosts were modified by cost scalars
private function ReceiveCommodityReward(XComGameState NewGameState, Commodity CommodityObject, optional StateObjectReference AuxRef)
{
	local XComGameStateHistory History;
	local XComGameState_Reward RewardState;

	History = `XCOMHISTORY;

	RewardState = XComGameState_Reward(History.GetGameStateForObjectID(CommodityObject.RewardRef.ObjectID));
	RewardState.GiveReward(NewGameState, AuxRef);
	NewGameState.RemoveStateObject(RewardState.ObjectID);
}

//---------------------------------------------------------------------------------------
// Private function to ensure Commodity ArtifactCosts are modified by cost scalars
private function PayCommodityCost(XComGameState NewGameState, Commodity CommodityObject)
{
	local StrategyCost ScaledCost;

	ScaledCost = GetScaledStrategyCost(CommodityObject.Cost, CommodityObject.CostScalars, CommodityObject.DiscountPercent);

	PayResourceCosts(NewGameState, ScaledCost.ResourceCosts);
	PayArtifactCosts(NewGameState, ScaledCost.ArtifactCosts);
}

//---------------------------------------------------------------------------------------
function PayStrategyCost(XComGameState NewGameState, StrategyCost StratCost, array<StrategyCostScalar> CostScalars, optional float DiscountPercent)
{
	local StrategyCost ScaledCost;

	ScaledCost = GetScaledStrategyCost(StratCost, CostScalars, DiscountPercent);

	PayResourceCosts(NewGameState, ScaledCost.ResourceCosts);
	PayArtifactCosts(NewGameState, ScaledCost.ArtifactCosts);
}

//---------------------------------------------------------------------------------------
function RefundStrategyCost(XComGameState NewGameState, StrategyCost StratCost, array<StrategyCostScalar> CostScalars, optional float DiscountPercent)
{
	local StrategyCost ScaledCost;

	ScaledCost = GetScaledStrategyCost(StratCost, CostScalars, DiscountPercent);

	RefundResourceCosts(NewGameState, ScaledCost.ResourceCosts);
	RefundArtifactCosts(NewGameState, ScaledCost.ArtifactCosts);
}

//---------------------------------------------------------------------------------------
// Private function to ensure ResourceCosts were modified by cost scalars
private function PayResourceCosts(XComGameState NewGameState, array<ArtifactCost> ResourceCosts)
{
	local int idx;

	for(idx = 0; idx < ResourceCosts.Length; idx++)
	{
		AddResource(NewGameState, ResourceCosts[idx].ItemTemplateName, -ResourceCosts[idx].Quantity);
	}
}

//---------------------------------------------------------------------------------------
// Private function to ensure ResourceCosts were modified by cost scalars
private function RefundResourceCosts(XComGameState NewGameState, array<ArtifactCost> ResourceCosts)
{
	local int idx;

	for(idx = 0; idx < ResourceCosts.Length; idx++)
	{
		AddResource(NewGameState, ResourceCosts[idx].ItemTemplateName, ResourceCosts[idx].Quantity);
	}
}

//---------------------------------------------------------------------------------------
// Private function to ensure ArtifactCosts were modified by cost scalars
private function PayArtifactCosts(XComGameState NewGameState, array<ArtifactCost> ArtifactCosts)
{
	local XComGameStateHistory History;
	local XComGameState_Item ItemState;
	local int idx, i;

	History = `XCOMHISTORY;

	for(idx = 0; idx < ArtifactCosts.Length; idx++)
	{
		for(i = 0; i < Inventory.Length; i++)
		{
			ItemState = XComGameState_Item(History.GetGameStateForObjectID(Inventory[i].ObjectID));

			if(ItemState != none)
			{
				if(ItemState.GetMyTemplateName() == ArtifactCosts[idx].ItemTemplateName && ItemState.Quantity >= ArtifactCosts[idx].Quantity)
				{
					RemoveItemFromInventory(NewGameState, ItemState.GetReference(), ArtifactCosts[idx].Quantity);
				}
			}
		}
	}
}

//---------------------------------------------------------------------------------------
// Private function to ensure ArtifactCosts were modified by cost scalars
private function RefundArtifactCosts(XComGameState NewGameState, array<ArtifactCost> ArtifactCosts)
{
	local XComGameState_Item ItemState;
	local X2ItemTemplate ItemTemplate;
	local int idx;

	for(idx = 0; idx < ArtifactCosts.Length; idx++)
	{
		ItemTemplate = class'X2ItemTemplateManager'.static.GetItemTemplateManager().FindItemTemplate(ArtifactCosts[idx].ItemTemplateName);
		ItemState = ItemTemplate.CreateInstanceFromTemplate(NewGameState);
		NewGameState.AddStateObject(ItemState);
		ItemState.Quantity = ArtifactCosts[idx].Quantity;

		if(ItemState != none)
		{
			PutItemInInventory(NewGameState, ItemState);
		}
	}
}

//#############################################################################################
//----------------   OBJECTIVES   -------------------------------------------------------------
//#############################################################################################

static function bool IsObjectiveCompleted(Name ObjectiveName)
{
	if(GetObjective(ObjectiveName) == none)
	{
		return true;
	}

	return GetObjectiveStatus(ObjectiveName) == eObjectiveState_Completed;
}

static function EObjectiveState GetObjectiveStatus(Name ObjectiveName)
{
	local XComGameStateHistory History;
	local XComGameState_Objective ObjectiveState;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_Objective', ObjectiveState)
	{
		if( ObjectiveState.GetMyTemplateName() == ObjectiveName )
		{
			return ObjectiveState.GetStateOfObjective();
		}
	}

	// no objective by the specified name
	return eObjectiveState_NotStarted;
}

static function XComGameState_Objective GetObjective(Name ObjectiveName)
{
	local XComGameStateHistory History;
	local XComGameState_Objective ObjectiveState;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_Objective', ObjectiveState)
	{
		if (ObjectiveState.GetMyTemplateName() == ObjectiveName)
		{
			return ObjectiveState;
		}
	}

	// no objective by the specified name
	return None;
}

static function bool AnyTutorialObjectivesInProgress()
{
	return (!IsObjectiveCompleted(default.TutorialFinishedObjective));
}

event bool AnyTacticalObjectivesInProgress()
{
	local XComGameStateHistory History;
	local XComGameState_Objective ObjectiveState;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_Objective', ObjectiveState)
	{
		if( ObjectiveState.GetMyTemplate() != None && ObjectiveState.GetMyTemplate().TacticalCompletion && ObjectiveState.GetStateOfObjective() == eObjectiveState_InProgress )
		{
			return true;
		}
	}

	return false;
}

static function array<StateObjectReference> GetCompletedAndActiveStrategyObjectives()
{
	local XComGameStateHistory History;
	local XComGameState_Objective ObjectiveState;
	local array<StateObjectReference> Objectives; 

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_Objective', ObjectiveState)
	{
		if( ObjectiveState.GetStateOfObjective() == eObjectiveState_Completed || ObjectiveState.GetStateOfObjective() == eObjectiveState_InProgress )
		{
			if( !ObjectiveState.GetMyTemplate().bNeverShowObjective && ObjectiveState.bIsRevealed && ObjectiveState.IsMainObjective() )
				Objectives.AddItem( ObjectiveState.GetReference() );
		}
	}
	return Objectives;
}

static function bool NeedsToEquipMedikitTutorial()
{
	return static.GetObjectiveStatus('T0_M5_EquipMedikit') == eObjectiveState_InProgress;
}

//#############################################################################################
//----------------   RESEARCH   ---------------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
simulated function bool IsTechResearched(name TechName)
{
	local X2StrategyElementTemplateManager StratMgr;
	local X2TechTemplate TechTemplate;

	StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
	TechTemplate = X2TechTemplate(StratMgr.FindStrategyElementTemplate(TechName));

	return TechTemplate != none && TechTemplateIsResearched(TechTemplate);
}

//---------------------------------------------------------------------------------------
simulated function bool IsContactResearched()
{
	return IsTechResearched('ResistanceCommunications');
}

//---------------------------------------------------------------------------------------
simulated function bool IsOutpostResearched()
{
	return IsTechResearched('ResistanceRadio');
}

//---------------------------------------------------------------------------------------
native function bool TechTemplateIsResearched(X2TechTemplate TechTemplate);

//---------------------------------------------------------------------------------------
native function bool TechIsResearched(StateObjectReference TechRef);

//---------------------------------------------------------------------------------------
//----------------------------RESEARCH PROJECTS------------------------------------------
//---------------------------------------------------------------------------------------

function XComGameState_Tech GetCurrentResearchTech()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersProjectResearch ResearchProject;
	local int idx;

	History = `XCOMHISTORY;

	for(idx = 0; idx < Projects.Length; idx++)
	{
		ResearchProject = XComGameState_HeadquartersProjectResearch(History.GetGameStateForObjectID(Projects[idx].ObjectID));

		if(ResearchProject != none && !ResearchProject.bShadowProject && !ResearchProject.bProvingGroundProject && !ResearchProject.bForcePaused)
		{
			return XComGameState_Tech(History.GetGameStateForObjectID(ResearchProject.ProjectFocus.ObjectID));
		}
	}

	return none;
}

//---------------------------------------------------------------------------------------
function XComGameState_HeadquartersProjectResearch GetCurrentResearchProject()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersProjectResearch ResearchProject;
	local int idx;

	History = `XCOMHISTORY;

	for(idx = 0; idx < Projects.Length; idx++)
	{
		ResearchProject = XComGameState_HeadquartersProjectResearch(History.GetGameStateForObjectID(Projects[idx].ObjectID));

		if(ResearchProject != none && !ResearchProject.bShadowProject && !ResearchProject.bProvingGroundProject && !ResearchProject.bForcePaused)
		{
			return ResearchProject;
		}
	}

	return none;
}

//---------------------------------------------------------------------------------------
function array<StateObjectReference> GetCompletedResearchTechs()
{
	local XComGameStateHistory History;
	local XComGameState_Tech TechState;
	local array<StateObjectReference> CompletedTechs;
	local int idx;

	History = `XCOMHISTORY;
	for (idx = 0; idx < TechsResearched.length; idx++)
	{
		TechState = XComGameState_Tech(History.GetGameStateForObjectID(TechsResearched[idx].ObjectID));

		//Outdated savegames may contain completed techs that have since been removed. Don't bother enumerating them.
		if (TechState.GetMyTemplate() == None)
			continue;

		if (!TechState.GetMyTemplate().bProvingGround && !TechState.GetMyTemplate().bShadowProject)
			CompletedTechs.AddItem(TechState.GetReference());
	}

	return CompletedTechs;
}

//---------------------------------------------------------------------------------------
function bool HasCompletedResearchTechs()
{
	return (GetNumTechsResearched() > 0);
}

//---------------------------------------------------------------------------------------
function int GetNumTechsResearched()
{
	local array<StateObjectReference> CompletedTechs;

	CompletedTechs = GetCompletedResearchTechs();

	return CompletedTechs.Length;
}

//---------------------------------------------------------------------------------------
function bool HasResearchProject()
{
	return (GetCurrentResearchProject() != none);
}

//---------------------------------------------------------------------------------------
//------------------------------SHADOW PROJECTS------------------------------------------
//---------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------
function XComGameState_Tech GetCurrentShadowTech()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersProjectResearch ResearchProject;
	local int idx;

	History = `XCOMHISTORY;

	for (idx = 0; idx < Projects.Length; idx++)
	{
		ResearchProject = XComGameState_HeadquartersProjectResearch(History.GetGameStateForObjectID(Projects[idx].ObjectID));

		if (ResearchProject != none && ResearchProject.bShadowProject && !ResearchProject.bProvingGroundProject && !ResearchProject.bForcePaused)
		{
			return XComGameState_Tech(History.GetGameStateForObjectID(ResearchProject.ProjectFocus.ObjectID));
		}
	}

	return none;
}

//---------------------------------------------------------------------------------------
function XComGameState_HeadquartersProjectResearch GetCurrentShadowProject()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersProjectResearch ResearchProject;
	local int idx;

	History = `XCOMHISTORY;

	for (idx = 0; idx < Projects.Length; idx++)
	{
		ResearchProject = XComGameState_HeadquartersProjectResearch(History.GetGameStateForObjectID(Projects[idx].ObjectID));

		if (ResearchProject != none && ResearchProject.bShadowProject && !ResearchProject.bProvingGroundProject && !ResearchProject.bForcePaused)
		{
			return ResearchProject;
		}
	}

	return none;
}

//---------------------------------------------------------------------------------------
function array<StateObjectReference> GetCompletedShadowTechs()
{
	local XComGameStateHistory History;
	local XComGameState_Tech TechState;
	local array<StateObjectReference> CompletedTechs;
	local int idx;

	History = `XCOMHISTORY;
	for (idx = 0; idx < TechsResearched.length; idx++)
	{
		TechState = XComGameState_Tech(History.GetGameStateForObjectID(TechsResearched[idx].ObjectID));

		if (TechState.GetMyTemplate().bShadowProject)
			CompletedTechs.AddItem(TechState.GetReference());
	}

	return CompletedTechs;
}

//---------------------------------------------------------------------------------------
function bool HasCompletedShadowProjects()
{
	return (GetNumShadowProjectsCompleted() > 0);
}

//---------------------------------------------------------------------------------------
function int GetNumShadowProjectsCompleted()
{
	local array<StateObjectReference> CompletedProjects;

	CompletedProjects = GetCompletedShadowTechs();

	return CompletedProjects.Length;
}

//---------------------------------------------------------------------------------------
function bool HasShadowProject()
{
	return (GetCurrentShadowProject() != none);
}

//---------------------------------------------------------------------------------------
function bool HasActiveShadowProject()
{
	local XComGameState_HeadquartersProjectResearch ResearchProject;

	ResearchProject = GetCurrentShadowProject();

	return (ResearchProject != none && !ResearchProject.bForcePaused);
}

//---------------------------------------------------------------------------------------
//----------------------------PROVING GROUND PROJECTS------------------------------------
//---------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------
function XComGameState_Tech GetCurrentProvingGroundTech()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersProjectProvingGround ResearchProject;
	local int idx;

	History = `XCOMHISTORY;

	for(idx = 0; idx < Projects.Length; idx++)
	{
		ResearchProject = XComGameState_HeadquartersProjectProvingGround(History.GetGameStateForObjectID(Projects[idx].ObjectID));

		if(ResearchProject != none && ResearchProject.bProvingGroundProject && !ResearchProject.bShadowProject && !ResearchProject.bForcePaused && ResearchProject.FrontOfBuildQueue())
		{
			return XComGameState_Tech(History.GetGameStateForObjectID(ResearchProject.ProjectFocus.ObjectID));
		}
	}

	return none;
}

//---------------------------------------------------------------------------------------
function XComGameState_HeadquartersProjectProvingGround GetCurrentProvingGroundProject()
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersProjectProvingGround ResearchProject;
	local int idx;

	History = `XCOMHISTORY;

	for (idx = 0; idx < Projects.Length; idx++)
	{
		ResearchProject = XComGameState_HeadquartersProjectProvingGround(History.GetGameStateForObjectID(Projects[idx].ObjectID));

		if (ResearchProject != none && !ResearchProject.bShadowProject && ResearchProject.bProvingGroundProject && !ResearchProject.bForcePaused && ResearchProject.FrontOfBuildQueue())
		{
			return ResearchProject;
		}
	}

	return none;
}

//---------------------------------------------------------------------------------------
function array<StateObjectReference> GetCompletedProvingGroundTechs()
{
	local XComGameStateHistory History;
	local XComGameState_Tech TechState;
	local array<StateObjectReference> CompletedTechs;
	local int idx;

	History = `XCOMHISTORY;
	for (idx = 0; idx < TechsResearched.length; idx++)
	{
		TechState = XComGameState_Tech(History.GetGameStateForObjectID(TechsResearched[idx].ObjectID));

		if (TechState.GetMyTemplate().bProvingGround)
			CompletedTechs.AddItem(TechState.GetReference());
	}

	return CompletedTechs;
}


//---------------------------------------------------------------------------------------
function array<XComGameState_Tech> GetCompletedProvingGroundTechStates()
{
	local XComGameStateHistory History;
	local XComGameState_Tech TechState;
	local array<XComGameState_Tech> CompletedTechs;
	local int idx;

	History = `XCOMHISTORY;
	for (idx = 0; idx < TechsResearched.length; idx++)
	{
		TechState = XComGameState_Tech(History.GetGameStateForObjectID(TechsResearched[idx].ObjectID));

		if (TechState.GetMyTemplate().bProvingGround)
			CompletedTechs.AddItem(TechState);
	}

	return CompletedTechs;
}

//---------------------------------------------------------------------------------------
function bool HasCompletedProvingGroundProjects()
{
	return (GetNumProvingGroundProjectsCompleted() > 0);
}

//---------------------------------------------------------------------------------------
function int GetNumProvingGroundProjectsCompleted()
{
	local array<StateObjectReference> CompletedProjects;

	CompletedProjects = GetCompletedProvingGroundTechs();

	return CompletedProjects.Length;
}

//---------------------------------------------------------------------------------------
function bool HasProvingGroundProject()
{
	return (GetCurrentProvingGroundProject() != none);
}

//---------------------------------------------------------------------------------------
//-----------------------------------TECH HELPERS----------------------------------------
//---------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------
function bool IsTechAvailableForResearch(StateObjectReference TechRef, optional bool bShadowProject = false, optional bool bProvingGround = false)
{
	local XComGameStateHistory History;
	local XComGameState_Tech TechState;

	History = `XCOMHISTORY;
	TechState = XComGameState_Tech(History.GetGameStateForObjectID(TechRef.ObjectID));

	if(TechIsResearched( TechRef ) && !TechState.GetMyTemplate().bRepeatable)
	{
		return false;
	}

	if(TechState.bBlocked)
	{
		return false;
	}
	else if((bShadowProject && !TechState.GetMyTemplate().bShadowProject) ||
			(!bShadowProject && TechState.GetMyTemplate().bShadowProject) ||
			(bProvingGround && !TechState.GetMyTemplate().bProvingGround) ||
			(!bProvingGround && TechState.GetMyTemplate().bProvingGround))
	{
		return false;
	}
			
	if(!HasPausedProject(TechRef) && !MeetsEnoughRequirementsToBeVisible(TechState.GetMyTemplate().Requirements))
	{
		return false;
	}

	return true;
}

//---------------------------------------------------------------------------------------
function bool IsTechCurrentlyBeingResearched(XComGameState_Tech TechState)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersProjectResearch ResearchProject;
	local int idx;

	History = `XCOMHISTORY;

	for (idx = 0; idx < Projects.Length; idx++)
	{
		ResearchProject = XComGameState_HeadquartersProjectResearch(History.GetGameStateForObjectID(Projects[idx].ObjectID));

		if (ResearchProject != none && ResearchProject.ProjectFocus == TechState.GetReference())
		{
			return true;
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
function bool IsTechCurrentlyBeingResearchedByName(Name TechTemplateName)
{
	local XComGameStateHistory History;
	local XComGameState_Tech TechState;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_Tech', TechState)
	{
		if (TechState.GetMyTemplateName() == TechTemplateName)
		{
			break;
		}
	}

	return IsTechCurrentlyBeingResearched(TechState);
}

//---------------------------------------------------------------------------------------
function array<StateObjectReference> GetAvailableTechsForResearch(optional bool bShadowProject = false, optional bool bMeetsRequirements = false)
{
	local XComGameStateHistory History;
	local XComGameState_Tech TechState;
	local array<StateObjectReference> AvailableTechs;

	AvailableTechs.Length = 0;
	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_Tech', TechState)
	{
		if (TechState.GetMyTemplate() != none)
		{
			if (bShadowProject)
			{
				if ((!HasActiveShadowProject() || TechState.ObjectID != GetCurrentShadowTech().ObjectID) && IsTechAvailableForResearch(TechState.GetReference(), bShadowProject))
				{
					if (!bMeetsRequirements || MeetsRequirmentsAndCanAffordCost(TechState.GetMyTemplate().Requirements, TechState.GetMyTemplate().Cost, ResearchCostScalars))
					{
						AvailableTechs.AddItem(TechState.GetReference());
					}
				}
			}
			else
			{
				if ((!HasResearchProject() || TechState.ObjectID != GetCurrentResearchTech().ObjectID) && IsTechAvailableForResearch(TechState.GetReference(), bShadowProject))
				{
					if (!bMeetsRequirements || MeetsRequirmentsAndCanAffordCost(TechState.GetMyTemplate().Requirements, TechState.GetMyTemplate().Cost, ResearchCostScalars))
					{
						AvailableTechs.AddItem(TechState.GetReference());
					}
				}
			}
		}
	}

	return AvailableTechs;
}

//---------------------------------------------------------------------------------------
function bool HasTechsAvailableForResearch(optional bool bShadowProject = false)
{
	local array<StateObjectReference> AvailableTechs;

	AvailableTechs = GetAvailableTechsForResearch(bShadowProject);

	return (AvailableTechs.Length > 0);
}

//---------------------------------------------------------------------------------------
function bool HasTechsAvailableForResearchWithRequirementsMet(optional bool bShadowProject = false)
{
	local array<StateObjectReference> AvailableTechs;

	AvailableTechs = GetAvailableTechsForResearch(bShadowProject, true);

	return (AvailableTechs.Length > 0);
}

//---------------------------------------------------------------------------------------
function array<StateObjectReference> GetAvailableProvingGroundProjects()
{
	local XComGameStateHistory History;
	local XComGameState_Tech TechState;
	local array<StateObjectReference> AvailableProjects;

	AvailableProjects.Length = 0;
	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_Tech', TechState)
	{
		if ((TechState.GetMyTemplate().bRepeatable || !IsTechCurrentlyBeingResearched(TechState)) && IsTechAvailableForResearch(TechState.GetReference(), false, true))
		{
			AvailableProjects.AddItem(TechState.GetReference());
		}
	}

	return AvailableProjects;
}

//---------------------------------------------------------------------------------------
function int GetPercentSlowTechs()
{
	local XComGameStateHistory History;
	local array<StateObjectReference> AvailableTechs, ShadowTechs;
	local StateObjectReference TechRef;
	local X2TechTemplate TechTemplate;
	local float NumSlowTechs;
	local int PercentGated;

	History = `XCOMHISTORY;
	AvailableTechs = GetAvailableTechsForResearch(false);
	ShadowTechs = GetAvailableTechsForResearch(true);

	foreach AvailableTechs(TechRef)
	{
		TechTemplate = XComGameState_Tech(History.GetGameStateForObjectID(TechRef.ObjectID)).GetMyTemplate();
		if (!TechTemplate.bAutopsy && !TechTemplate.bRepeatable && GetResearchProgress(TechRef) < eResearchProgress_Normal)
		{
			NumSlowTechs += 1.0;
		}
	}
	foreach ShadowTechs(TechRef)
	{
		TechTemplate = XComGameState_Tech(History.GetGameStateForObjectID(TechRef.ObjectID)).GetMyTemplate();
		if (!TechTemplate.bAutopsy && !TechTemplate.bRepeatable && GetResearchProgress(TechRef) < eResearchProgress_Normal)
		{
			NumSlowTechs += 1.0;
		}
	}

	PercentGated = int((NumSlowTechs / (AvailableTechs.Length + ShadowTechs.Length)) * 100);
	return PercentGated;
}

//---------------------------------------------------------------------------------------
function bool HasGatedPriorityResearch()
{
	local XComGameStateHistory History;
	local array<StateObjectReference> AvailableTechs, ShadowTechs;
	local StateObjectReference TechRef;
	local X2TechTemplate TechTemplate;
	local XComGameState_Tech TechState;
	local int ScienceScore;

	History = `XCOMHISTORY;
	AvailableTechs = GetAvailableTechsForResearch(false);
	ShadowTechs = GetAvailableTechsForResearch(true);
	ScienceScore = GetScienceScore();

	foreach AvailableTechs(TechRef)
	{
		TechState = XComGameState_Tech(History.GetGameStateForObjectID(TechRef.ObjectID));
		TechTemplate = TechState.GetMyTemplate();
		if (TechState.IsPriority() && TechTemplate.Requirements.RequiredScienceScore > ScienceScore)
		{
			return true;
		}
	}
	foreach ShadowTechs(TechRef)
	{
		TechState = XComGameState_Tech(History.GetGameStateForObjectID(TechRef.ObjectID));
		TechTemplate = TechState.GetMyTemplate();
		if (TechState.IsPriority() && TechTemplate.Requirements.RequiredScienceScore > ScienceScore)
		{
			return true;
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
function bool HasGatedEngineeringItem()
{
	local X2ItemTemplate ItemTemplate;
	local X2ItemTemplateManager ItemTemplateManager;
	local array<X2ItemTemplate> BuildableItems;
	local int EngineeringScore;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	BuildableItems = ItemTemplateManager.GetBuildableItemTemplates();
	EngineeringScore = GetEngineeringScore();
	
	foreach BuildableItems(ItemTemplate)
	{
		if (ItemTemplateManager.BuildItemWeaponCategories.Find(ItemTemplate.ItemCat) != INDEX_NONE)
		{
			if (ItemTemplate.Requirements.RequiredEngineeringScore > EngineeringScore)
				return true;
		}
		else if (ItemTemplateManager.BuildItemArmorCategories.Find(ItemTemplate.ItemCat) != INDEX_NONE)
		{
			if (ItemTemplate.Requirements.RequiredEngineeringScore > EngineeringScore)
				return true;
		}		
	}

	return false;
}

//---------------------------------------------------------------------------------------
function SetNewResearchProject(StateObjectReference TechRef)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameStateHistory History;
	local XComGameState_Tech TechState;
	local XComGameState_HeadquartersProjectResearch ResearchProject;
	local XComNarrativeMoment TechStartedNarrative;
	local StrategyCost TechCost;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Adding Research Project");
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', self.ObjectID));
	NewGameState.AddStateObject(XComHQ);

	ResearchProject = GetPausedProject(TechRef);

	if(ResearchProject != none)
	{
		ResearchProject = XComGameState_HeadquartersProjectResearch(NewGameState.CreateStateObject(class'XComGameState_HeadquartersProjectResearch', ResearchProject.ObjectID));
		NewGameState.AddStateObject(ResearchProject);
		ResearchProject.bForcePaused = false;
	}
	else
	{
		ResearchProject = XComGameState_HeadquartersProjectResearch(NewGameState.CreateStateObject(class'XComGameState_HeadquartersProjectResearch'));
		NewGameState.AddStateObject(ResearchProject);
		ResearchProject.SetProjectFocus(TechRef);
		XComHQ.Projects.AddItem(ResearchProject.GetReference());

		TechState = XComGameState_Tech(History.GetGameStateForObjectID(TechRef.ObjectID));
		TechCost = TechState.GetMyTemplate().Cost;
		XComHQ.PayStrategyCost(NewGameState, TechCost, ResearchCostScalars);
	}

	if (ResearchProject.bShadowProject)
	{
		StaffShadowChamber(NewGameState);
	}

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	HandlePowerOrStaffingChange();

	if(ResearchProject.bInstant)
	{
		ResearchProject.OnProjectCompleted();
	}

	class'X2StrategyGameRulesetDataStructures'.static.ForceUpdateObjectivesUI();
	
	if (TechState != none && TechState.GetMyTemplate().TechStartedNarrative != "")
	{
		TechStartedNarrative = XComNarrativeMoment(`CONTENT.RequestGameArchetype(TechState.GetMyTemplate().TechStartedNarrative));
		if (TechStartedNarrative != None)
		{
			`HQPRES.UINarrative(TechStartedNarrative);
		}
	}
}

//---------------------------------------------------------------------------------------
function PauseResearchProject(XComGameState NewGameState)
{
	local XComGameState_HeadquartersProjectResearch ProjectState;

	ProjectState = GetCurrentResearchProject();

	if (ProjectState != none)
	{
		ProjectState = XComGameState_HeadquartersProjectResearch(NewGameState.CreateStateObject(class'XComGameState_HeadquartersProjectResearch', ProjectState.ObjectID));
		NewGameState.AddStateObject(ProjectState);
		ProjectState.bForcePaused = true;
	}
}

//---------------------------------------------------------------------------------------
function PauseShadowProject(XComGameState NewGameState)
{
	local XComGameState_HeadquartersProjectResearch ProjectState;

	ProjectState = GetCurrentShadowProject();

	if(ProjectState != none)
	{
		ProjectState = XComGameState_HeadquartersProjectResearch(NewGameState.CreateStateObject(class'XComGameState_HeadquartersProjectResearch', ProjectState.ObjectID));
		NewGameState.AddStateObject(ProjectState);
		ProjectState.bForcePaused = true;
		EmptyShadowChamber(NewGameState);
	}
}

//---------------------------------------------------------------------------------------
function bool HasPausedProject(StateObjectReference TechRef)
{
	local int idx;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersProjectResearch ResearchProject;

	History = `XCOMHISTORY;

	for (idx = 0; idx < Projects.Length; idx++)
	{
		ResearchProject = XComGameState_HeadquartersProjectResearch(History.GetGameStateForObjectID(Projects[idx].ObjectID));

		if (ResearchProject != none && ResearchProject.ProjectFocus == TechRef && ResearchProject.bForcePaused)
		{
			return true;
		}
	}

	return false;
}

//---------------------------------------------------------------------------------------
function XComGameState_HeadquartersProjectResearch GetPausedProject(StateObjectReference TechRef)
{
	local int idx;
	local XComGameStateHistory History;
	local XComGameState_HeadquartersProjectResearch ResearchProject;

	History = `XCOMHISTORY;

	for (idx = 0; idx < Projects.Length; idx++)
	{
		ResearchProject = XComGameState_HeadquartersProjectResearch(History.GetGameStateForObjectID(Projects[idx].ObjectID));

		if (ResearchProject != none && ResearchProject.ProjectFocus == TechRef && ResearchProject.bForcePaused)
		{
			return ResearchProject;
		}
	}

	return none;
}

//---------------------------------------------------------------------------------------
function int GetHoursLeftOnResearchProject()
{
	return GetCurrentResearchProject().GetCurrentNumHoursRemaining();
}

//---------------------------------------------------------------------------------------
function int GetHoursLeftOnShadowProject()
{
	return GetCurrentShadowProject().GetCurrentNumHoursRemaining();
}

//---------------------------------------------------------------------------------------
function String GetResearchEstimateString(StateObjectReference TechRef)
{
	local int iHours, iDaysLeft;
	local XGParamTag kTag;
	local XComGameState NewGameState;
	local XComGameStateHistory History;
	local XComGameState_Tech TechState;
	local XComGameState_HeadquartersProjectResearch ResearchProject;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("SHOULD NOT BE SUBMITTED");
	
	ResearchProject = GetPausedProject(TechRef);
	
	if (ResearchProject == none)
	{
		TechState = XComGameState_Tech(History.GetGameStateForObjectID(TechRef.ObjectID));
		if (TechState.GetMyTemplate().bProvingGround)
			ResearchProject = XComGameState_HeadquartersProjectProvingGround(NewGameState.CreateStateObject(class'XComGameState_HeadquartersProjectProvingGround'));
		else
			ResearchProject = XComGameState_HeadquartersProjectResearch(NewGameState.CreateStateObject(class'XComGameState_HeadquartersProjectResearch'));

		NewGameState.AddStateObject(ResearchProject);
		ResearchProject.SetProjectFocus(TechRef);
	}

	iHours = ResearchProject.GetProjectedNumHoursRemaining();

	if( ResearchProject.bInstant )
	{
		NewGameState.PurgeGameStateForObjectID(ResearchProject.ObjectID);
		History.CleanupPendingGameState(NewGameState);
		return strETAInstant;
	}
	else
	{
		kTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));
		iDaysLeft = class'X2StrategyGameRulesetDataStructures'.static.HoursToDays(iHours);

		if( iDaysLeft < 0 )
		{
			iDaysLeft = 1;
		}

		kTag.IntValue0 = iDaysLeft;

		NewGameState.PurgeGameStateForObjectID(ResearchProject.ObjectID);
		History.CleanupPendingGameState(NewGameState);
		return `XEXPAND.ExpandString((iDaysLeft != 1) ? strETADays : strETADay);
	}
}

//---------------------------------------------------------------------------------------
function int GetResearchHours(StateObjectReference TechRef)
{
	local int iHours;
	local XComGameState NewGameState;
	local XComGameStateHistory History;
	local XComGameState_Tech TechState;
	local XComGameState_HeadquartersProjectResearch ResearchProject;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("SHOULD NOT BE SUBMITTED");
	
	ResearchProject = GetPausedProject(TechRef);

	if (ResearchProject == none)
	{
		TechState = XComGameState_Tech(History.GetGameStateForObjectID(TechRef.ObjectID));
		if (TechState.GetMyTemplate().bProvingGround)
			ResearchProject = XComGameState_HeadquartersProjectProvingGround(NewGameState.CreateStateObject(class'XComGameState_HeadquartersProjectProvingGround'));
		else
			ResearchProject = XComGameState_HeadquartersProjectResearch(NewGameState.CreateStateObject(class'XComGameState_HeadquartersProjectResearch'));

		NewGameState.AddStateObject(ResearchProject);
		ResearchProject.SetProjectFocus(TechRef);
	}

	iHours = ResearchProject.GetProjectedNumHoursRemaining();

	if( ResearchProject.bInstant )
	{
		NewGameState.PurgeGameStateForObjectID(ResearchProject.ObjectID);
		History.CleanupPendingGameState(NewGameState);
		return 0;
	}
	else
	{
		NewGameState.PurgeGameStateForObjectID(ResearchProject.ObjectID);
		History.CleanupPendingGameState(NewGameState);
		return iHours;
	}
}

//---------------------------------------------------------------------------------------
function EResearchProgress GetResearchProgress(StateObjectReference TechRef)
{
	local int iHours, iDays;

	if(TechRef.ObjectID == 0)
	{
		return eResearchProgress_Normal;
	}

	iHours = GetResearchHours(TechRef);
	iDays = class'X2StrategyGameRulesetDataStructures'.static.HoursToDays(iHours);

	if( iDays <= ResearchProgressDays_Fast[`DIFFICULTYSETTING] )
		return eResearchProgress_Fast;
	else if( iDays <= ResearchProgressDays_Normal[`DIFFICULTYSETTING] )
		return eResearchProgress_Normal;
	else if( iDays <= ResearchProgressDays_Slow[`DIFFICULTYSETTING] )
		return eResearchProgress_Slow;
	else
		return eResearchProgress_VerySlow;
}

function StaffShadowChamber(XComGameState NewGameState)
{
	local XComGameState_FacilityXCom FacilityState;
	local StaffUnitInfo ShenInfo, TyganInfo;
	
	// First take Tygan out of Research
	FacilityState = GetFacilityByName('PowerCore');
	FacilityState.GetStaffSlot(0).EmptySlot(NewGameState);

	// And Shen out of Engineering
	FacilityState = GetFacilityByName('Storage');
	FacilityState.GetStaffSlot(0).EmptySlot(NewGameState);

	// Then add them to the Shadow Chamber
	ShenInfo.UnitRef = GetShenReference();
	TyganInfo.UnitRef = GetTyganReference();
	FacilityState = GetFacilityByName('ShadowChamber');
	FacilityState.GetStaffSlot(0).FillSlot(NewGameState, ShenInfo);
	FacilityState.GetStaffSlot(1).FillSlot(NewGameState, TyganInfo);
}

function EmptyShadowChamber(XComGameState NewGameState)
{
	local XComGameState_FacilityXCom FacilityState;
	local StaffUnitInfo ShenInfo, TyganInfo;

	// First empty the Shadow Chamber
	FacilityState = GetFacilityByName('ShadowChamber');
	FacilityState.GetStaffSlot(0).EmptySlot(NewGameState);
	FacilityState.GetStaffSlot(1).EmptySlot(NewGameState);

	// Then put Tygan back in Research
	TyganInfo.UnitRef = GetTyganReference();
	FacilityState = GetFacilityByName('PowerCore');
	FacilityState.GetStaffSlot(0).FillSlot(NewGameState, TyganInfo);

	// And Shen back in Engineering
	ShenInfo.UnitRef = GetShenReference();
	FacilityState = GetFacilityByName('Storage');
	FacilityState.GetStaffSlot(0).FillSlot(NewGameState, ShenInfo);
}

//#############################################################################################
//----------------   SCHEMATICS ---------------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
// Return list of schematics from the inventory. 
function array<X2SchematicTemplate> GetFoundSchematics()
{
	local array<X2SchematicTemplate> Schematics; 
	local X2SchematicTemplate SchematicTemplate; 
	local XComGameState_Item ItemState;
	local XComGameStateHistory History;
	local int idx;

	History = `XCOMHISTORY; 

	for(idx = 0; idx < Inventory.Length; idx++)
	{
		ItemState = XComGameState_Item(History.GetGameStateForObjectID(Inventory[idx].ObjectID));

		if(ItemState != none)
		{
			SchematicTemplate = X2SchematicTemplate(ItemState.GetMyTemplate());
			if( SchematicTemplate != none )
			{
				Schematics.AddItem(SchematicTemplate);
			}
		}
	}

	return Schematics; 
}

function bool HasFoundSchematics()
{
	local array<X2SchematicTemplate> Schematics;

	Schematics = GetFoundSchematics();

	return (Schematics.length > 0);
}

//#############################################################################################
//----------------   POWER   ------------------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function int GetPowerProduced()
{
	local XComGameState_FacilityXCom FacilityState;
	local int idx, iPowerProduced, iFacilityPower;

	iPowerProduced = GetStartingPowerProduced();
	iPowerProduced += BonusPowerProduced;
	iPowerProduced += PowerOutputBonus;

	for(idx = 0; idx < Facilities.Length; idx++)
	{
		FacilityState = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(Facilities[idx].ObjectID));

		if(FacilityState != none)
		{
			iFacilityPower = FacilityState.GetPowerOutput();

			if(iFacilityPower > 0)
			{
				iPowerProduced += iFacilityPower;
			}
		}
	}

	return iPowerProduced;
}

//---------------------------------------------------------------------------------------
function int GetPowerConsumed()
{
	local XComGameState_HeadquartersRoom RoomState;
	local XComGameState_FacilityXCom FacilityState;
	local XComGameState_HeadquartersProjectBuildFacility BuildFacilityState;
	local int idx, iPowerConsumed, iFacilityPower;

	iPowerConsumed = 0;

	for(idx = 0; idx < Rooms.Length; idx++)
	{
		RoomState = XComGameState_HeadquartersRoom(`XCOMHISTORY.GetGameStateForObjectID(Rooms[idx].ObjectID));
				
		// If the room has a facility, get its power output
		if (RoomState.HasFacility())
		{
			FacilityState = RoomState.GetFacility();

			iFacilityPower = FacilityState.GetPowerOutput();
			if(iFacilityPower < 0)
			{
				iPowerConsumed -= iFacilityPower;
			}
		}
		else // Otherwise check to see if a facility is being built, and then get the new facility's output
		{
			BuildFacilityState = RoomState.GetBuildFacilityProject();
			if (BuildFacilityState != None && !RoomState.HasShieldedPowerCoil())
			{
				FacilityState = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(BuildFacilityState.ProjectFocus.ObjectID));
				
				iFacilityPower = FacilityState.GetPowerOutput();
				if (iFacilityPower < 0)
				{
					iPowerConsumed -= iFacilityPower;
				}
			}
		}
	}

	return iPowerConsumed;
}

//---------------------------------------------------------------------------------------
function float GetPowerPercent()
{
	return (float(GetPowerConsumed()) / float(GetPowerProduced())) * 100.0;
}

//---------------------------------------------------------------------------------------
function DeterminePowerState()
{
	local float PowerPercent;
	local int PowerProduced, PowerConsumed;

	PowerPercent = GetPowerPercent();
	PowerProduced = GetPowerProduced();
	PowerConsumed = GetPowerConsumed();

	if(PowerConsumed >= PowerProduced)
	{
		PowerState = ePowerState_Red;
	}
	else if(PowerPercent >= default.XComHeadquarters_YellowPowerStatePercent)
	{
		PowerState = ePowerState_Yellow;
	}
	else
	{
		PowerState = ePowerState_Green;
	}
}

//#############################################################################################
//----------------   RESISTANCE COMMS   ---------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function int GetPossibleResContacts()
{
	local int iPossibleContacts;

	local XComGameState_FacilityXCom Facility;
	local int idx;

	iPossibleContacts = GetStartingCommCapacity();
	iPossibleContacts += BonusCommCapacity;

	for( idx = 0; idx < Facilities.Length; idx++ )
	{
		Facility = XComGameState_FacilityXCom(`XCOMHISTORY.GetGameStateForObjectID(Facilities[idx].ObjectID));
		
		iPossibleContacts += Facility.CommCapacity;
	}

	return iPossibleContacts;
}

//---------------------------------------------------------------------------------------
function int GetCurrentResContacts(optional bool bExcludeInProgress = false)
{
	local XComGameState_WorldRegion RegionState;
	local XComGameStateHistory History;
	local int iContacts;

	History = `XCOMHISTORY;

	iContacts = 0;
	foreach History.IterateByClassType(class'XComGameState_WorldRegion', RegionState)
	{
		if( RegionState.HaveMadeContact() || (RegionState.bCanScanForContact && !bExcludeInProgress))
		{
			iContacts++;
		}
	}

	return iContacts;
}

//---------------------------------------------------------------------------------------
function int GetRemainingContactCapacity()
{
	return GetPossibleResContacts() - GetCurrentResContacts();
}

//---------------------------------------------------------------------------------------
function array<XComGameState_WorldRegion> GetContactRegions()
{
	local array<XComGameState_WorldRegion> arrContactRegions;
	local XComGameStateHistory History;
	local XComGameState_WorldRegion RegionState;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_WorldRegion', RegionState)
	{
		if (RegionState.ResistanceLevel == eResLevel_Unlocked)
		{
			arrContactRegions.AddItem(RegionState);
		}
	}

	return arrContactRegions;
}

//---------------------------------------------------------------------------------------
function bool HasRegionsAvailableForContact()
{
	local array<XComGameState_WorldRegion> arrContactRegions;

	arrContactRegions = GetContactRegions();

	return (arrContactRegions.Length > 0);
}

//#############################################################################################
//----------------   AVENGER STATUS   ---------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
// Helper for Hack Rewards to modify scan rate for a specified period of time
function SetScanRateForDuration(float NewScanRate, int DurationHours)
{
	CurrentScanRate = NewScanRate;

	ResetScanRateEndTime = GetCurrentTime();
	class'X2StrategyGameRulesetDataStructures'.static.AddHours(ResetScanRateEndTime, DurationHours);
}

//---------------------------------------------------------------------------------------
// Can the Avenger scan in its current region
function bool IsScanningAllowedAtCurrentLocation()
{
	local XComGameState_ScanningSite ScanSiteState;

	ScanSiteState = GetCurrentScanningSite();
	if (ScanSiteState != none)
		return ScanSiteState.CanBeScanned();

	return false;
}

function string GetScanSiteLabel()
{
	local XComGameState_ScanningSite ScanSiteState;

	ScanSiteState = GetCurrentScanningSite();
	if (ScanSiteState != none)
		return ScanSiteState.GetScanButtonLabel();

	return "";
}

function ToggleSiteScanning(bool bScanning)
{
	local XComGameState NewGameState;
	local XComGameState_ScanningSite ScanSiteState;
	local XComGameState_WorldRegion RegionState;
	
	ScanSiteState = GetCurrentScanningSite();
	if (ScanSiteState != none && ScanSiteState.CanBeScanned())
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Update Scanning Site");
		ScanSiteState = XComGameState_ScanningSite(NewGameState.CreateStateObject(class'XComGameState_ScanningSite', ScanSiteState.ObjectID));
		NewGameState.AddStateObject(ScanSiteState);

		if (bScanning)
		{
			`XEVENTMGR.TriggerEvent('ScanStarted', ScanSiteState, , NewGameState);

			ScanSiteState.StartScan();

			RegionState = XComGameState_WorldRegion(ScanSiteState);
			if (RegionState != none && RegionState.bCanScanForContact && !RegionState.bScanForContactEventTriggered)
			{
				RegionState.bScanForContactEventTriggered = true;

				`XEVENTMGR.TriggerEvent('StartScanForContact', , , NewGameState);
			}
		}
		else
			ScanSiteState.PauseScan();
		
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
}

function XComGameState_ScanningSite GetCurrentScanningSite()
{
	return XComGameState_ScanningSite(`XCOMHISTORY.GetGameStateForObjectID(CurrentLocation.ObjectID));
}

function array<XComGameState_ScanningSite> GetAvailableScanningSites()
{
	local array<XComGameState_ScanningSite> arrScanSites;
	local XComGameStateHistory History;
	local XComGameState_ScanningSite ScanSiteState;
	local XComGameState_BlackMarket BlackMarketState;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_ScanningSite', ScanSiteState)
	{
		BlackMarketState = XComGameState_BlackMarket(ScanSiteState);

		if (ScanSiteState.CanBeScanned() || (BlackMarketState != none && BlackMarketState.ShouldBeVisible()))
		{
			arrScanSites.AddItem(ScanSiteState);
		}
	}

	return arrScanSites;
}

//---------------------------------------------------------------------------------------
function bool IsSupplyDropAvailable()
{
	local XComGameStateHistory History;
	local XComGameState_ScanningSite ScanSiteState;
	local XComGameState_ResourceCache CacheState;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_ScanningSite', ScanSiteState)
	{
		CacheState = XComGameState_ResourceCache(ScanSiteState);

		if (CacheState != none && CacheState.CanBeScanned())
		{
			return true;
		}
	}

	return false;
}

//#############################################################################################
//----------------   MISSION HANDLING   -------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function GeneratedMissionData GetGeneratedMissionData(int MissionID)
{
	local int MissionDataIndex;
	local GeneratedMissionData GeneratedMission;
	local XComGameState_MissionSite MissionState;

	MissionDataIndex = arrGeneratedMissionData.Find('MissionID', MissionID);

	if(MissionDataIndex == INDEX_NONE)
	{
		MissionState = XComGameState_MissionSite(`XCOMHISTORY.GetGameStateForObjectID(MissionID));
		GeneratedMission = MissionState.GeneratedMission;
		if(GeneratedMission.BattleOpName == "")
		{
			GeneratedMission.BattleOpName = class'XGMission'.static.GenerateOpName(false);
		}
		arrGeneratedMissionData.AddItem(GeneratedMission);
	}
	else
	{
		GeneratedMission = arrGeneratedMissionData[MissionDataIndex];
	}
	return GeneratedMission;
}

//#############################################################################################
//----------------   EVENTS   -----------------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function GetEvents(out array<HQEvent> arrEvents)
{
	GetOrderEvents(arrEvents);
	GetSoldierEvents(arrEvents);
	GetResearchEvents(arrEvents);
	GetProvingGroundEvents(arrEvents);
	GetItemEvents(arrEvents);
	GetFacilityEvents(arrEvents);
	GetClearRoomEvents(arrEvents);
	GetFacilityUpgradeEvents(arrEvents);
	GetPsiTrainingEvents(arrEvents);
	GetResistanceEvents(arrEvents);
}

//---------------------------------------------------------------------------------------
function AddEventToEventList(out array<HQEvent> arrEvents, HQEvent kEvent)
{
	local int iEvent;

	if(kEvent.Hours >= 0)
	{
		for(iEvent = 0; iEvent < arrEvents.Length; iEvent++)
		{
			if(arrEvents[iEvent].Hours < 0 || arrEvents[iEvent].Hours > kEvent.Hours)
			{
				arrEvents.InsertItem(iEvent, kEvent);
				return;
			}
		}
	}

	arrEvents.AddItem(kEvent);
}

//---------------------------------------------------------------------------------------
function GetOrderEvents(out array<HQEvent> arrEvents)
{
	local HQEvent kEvent;
	local XComGameStateHistory History;
	local XComGameState_Unit UnitState;
	local int idx;

	History = `XCOMHISTORY;

	for(idx = 0; idx < CurrentOrders.Length; idx++)
	{
		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(CurrentOrders[idx].OrderRef.ObjectID));

		if(UnitState != none)
		{
			kEvent.Data = default.StaffOrderEventLabel @ UnitState.GetFullName();
			kEvent.Hours = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInHours(CurrentOrders[idx].OrderCompletionTime, GetCurrentTime());
			kEvent.ImagePath = class'UIUtilities_Image'.const.EventQueue_Staff;
			AddEventToEventList(arrEvents, kEvent);
		}
	}
}

//---------------------------------------------------------------------------------------
function GetSoldierEvents(out array<HQEvent> arrEvents)
{
	local int iProject;
	local HQEvent kEvent;
	local XComGameState_HeadquartersProjectTrainRookie TrainProject;
	local XComGameState_HeadquartersProjectRespecSoldier RespecProject;
	local XComGameState_Unit UnitState;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	for (iProject = 0; iProject < Projects.Length; iProject++)
	{
		TrainProject = XComGameState_HeadquartersProjectTrainRookie(History.GetGameStateForObjectID(Projects[iProject].ObjectID));
		RespecProject = XComGameState_HeadquartersProjectRespecSoldier(History.GetGameStateForObjectID(Projects[iProject].ObjectID));

		if (TrainProject != none)
		{			
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(TrainProject.ProjectFocus.ObjectID));
			kEvent.Data = Caps(TrainProject.GetTrainingClassTemplate().DisplayName) @ TrainRookieEventLabel @ UnitState.GetName(eNameType_RankFull);
			kEvent.Hours = TrainProject.GetCurrentNumHoursRemaining();
			kEvent.ImagePath = class'UIUtilities_Image'.const.EventQueue_Staff;
			
			if (kEvent.Hours < 0)
			{
				kEvent.Data = ProjectPausedLabel @ kEvent.Data;
			}

			AddEventToEventList(arrEvents, kEvent);
		}

		if (RespecProject != none)
		{
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(RespecProject.ProjectFocus.ObjectID));
			kEvent.Data = Caps(UnitState.GetSoldierClassTemplate().DisplayName) @ RespecSoldierEventLabel @ UnitState.GetName(eNameType_RankFull);
			kEvent.Hours = RespecProject.GetCurrentNumHoursRemaining();
			kEvent.ImagePath = class'UIUtilities_Image'.const.EventQueue_Staff;
			
			if (kEvent.Hours < 0)
			{
				kEvent.Data = ProjectPausedLabel @ kEvent.Data;
			}

			AddEventToEventList(arrEvents, kEvent);
		}
	}
}

//---------------------------------------------------------------------------------------
function GetResearchEvents(out array<HQEvent> arrEvents)
{
	local HQEvent kEvent;

	if(HasResearchProject())
	{
		kEvent.Data = ResearchEventLabel @ GetCurrentResearchTech().GetDisplayName();
		kEvent.Hours = GetHoursLeftOnResearchProject();
		kEvent.ImagePath = class'UIUtilities_Image'.const.EventQueue_Science;

		if(kEvent.Hours < 0)
		{
			kEvent.Data = ProjectPausedLabel @ kEvent.Data;
		}

		AddEventToEventList(arrEvents, kEvent);
	}

	if(HasActiveShadowProject())
	{
		kEvent.Data = ShadowEventLabel @ GetCurrentShadowTech().GetDisplayName();
		kEvent.Hours = GetHoursLeftOnShadowProject();
		kEvent.ImagePath = class'UIUtilities_Image'.const.EventQueue_Science;

		if(kEvent.Hours < 0)
		{
			kEvent.Data = ProjectPausedLabel @ kEvent.Data;
		}

		AddEventToEventList(arrEvents, kEvent);
	}
}

//---------------------------------------------------------------------------------------
function GetClearRoomEvents(out array<HQEvent> arrEvents)
{
	local int iClearRoomProject;
	local HQEvent kEvent;
	local XComGameState_HeadquartersProjectClearRoom ClearRoomProject;
	local XComGameState_HeadquartersRoom Room;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	for(iClearRoomProject = 0; iClearRoomProject < Projects.Length; iClearRoomProject++)
	{
		ClearRoomProject = XComGameState_HeadquartersProjectClearRoom(History.GetGameStateForObjectID(Projects[iClearRoomProject].ObjectID));

		if(ClearRoomProject != none)
		{
			Room = XComGameState_HeadquartersRoom(History.GetGameStateForObjectID(ClearRoomProject.ProjectFocus.ObjectID));

			if(Room != none)
			{
				kEvent.Data = Room.GetSpecialFeature().ClearText;
				kEvent.Hours = ClearRoomProject.GetCurrentNumHoursRemaining();
				kEvent.ImagePath = class'UIUtilities_Image'.const.EventQueue_Construction;

				if(kEvent.Hours < 0)
				{
					kEvent.Data = ProjectPausedLabel @ kEvent.Data;
				}

				AddEventToEventList(arrEvents, kEvent);
			}
		}
	}
}

//---------------------------------------------------------------------------------------
function GetProvingGroundEvents(out array<HQEvent> arrEvents)
{
	local int idx, CumulativeHours, iProject;
	local HQEvent kEvent;
	local XComGameState_HeadquartersProjectProvingGround ProvingGroundProject;
	local XComGameState_HeadquartersProjectBuildItem ItemProject;
	local XComGameState_Tech ProjectState;
	local XComGameStateHistory History;
	local XComGameState_FacilityXCom FacilityState;

	History = `XCOMHISTORY;

	for (idx = 0; idx < Facilities.Length; idx++)
	{
		FacilityState = XComGameState_FacilityXCom(History.GetGameStateForObjectID(Facilities[idx].ObjectID));

		if (FacilityState != none && FacilityState.BuildQueue.Length > 0)
		{
			for (iProject = 0; iProject < FacilityState.BuildQueue.Length; iProject++)
			{
				ProvingGroundProject = XComGameState_HeadquartersProjectProvingGround(History.GetGameStateForObjectID(FacilityState.BuildQueue[iProject].ObjectID));
				
				// Need to account for other item projects that might be taking up time
				ItemProject = XComGameState_HeadquartersProjectBuildItem(History.GetGameStateForObjectID(FacilityState.BuildQueue[iProject].ObjectID));
				if (ItemProject != none)
				{
					if (iProject == 0)
						CumulativeHours = ItemProject.GetCurrentNumHoursRemaining();
					else
						CumulativeHours += ItemProject.GetProjectedNumHoursRemaining();
				}

				if (ProvingGroundProject != none)
				{
					if (iProject == 0)
					{
						ProjectState = XComGameState_Tech(History.GetGameStateForObjectID(ProvingGroundProject.ProjectFocus.ObjectID));
						kEvent.Data = ProvingGroundEventLabel @ ProjectState.GetMyTemplate().DisplayName;
						CumulativeHours = ProvingGroundProject.GetCurrentNumHoursRemaining();
						kEvent.Hours = CumulativeHours;
					}
					else
					{
						ProjectState = XComGameState_Tech(History.GetGameStateForObjectID(ProvingGroundProject.ProjectFocus.ObjectID));
						kEvent.Data = ProvingGroundEventLabel @ ProjectState.GetMyTemplate().DisplayName;
						CumulativeHours += ProvingGroundProject.GetProjectedNumHoursRemaining();
						kEvent.Hours = CumulativeHours;
					}

					kEvent.ImagePath = class'UIUtilities_Image'.const.EventQueue_Engineer;
					if (kEvent.Hours < 0)
					{
						kEvent.Data = ProjectPausedLabel @ kEvent.Data;
					}

					AddEventToEventList(arrEvents, kEvent);
				}
			}
		}
	}
}

//---------------------------------------------------------------------------------------
function GetItemEvents(out array<HQEvent> arrEvents)
{
	local int idx, CumulativeHours, iItemProject;
	local HQEvent kEvent;
	local XComGameState_HeadquartersProjectBuildItem ItemProject;
	local XComGameState_HeadquartersProjectProvingGround ProvingGroundProject;
	local XComGameState_Item ItemState;
	local XComGameStateHistory History;
	local XComGameState_FacilityXCom FacilityState;

	History = `XCOMHISTORY;

	for(idx = 0; idx < Facilities.Length; idx++)
	{
		FacilityState = XComGameState_FacilityXCom(History.GetGameStateForObjectID(Facilities[idx].ObjectID));

		if(FacilityState != none && FacilityState.BuildQueue.Length > 0)
		{
			for(iItemProject = 0; iItemProject < FacilityState.BuildQueue.Length; iItemProject++)
			{
				ItemProject = XComGameState_HeadquartersProjectBuildItem(History.GetGameStateForObjectID(FacilityState.BuildQueue[iItemProject].ObjectID));
								
				// Need to account for other proving ground projects that might be taking up time
				ProvingGroundProject = XComGameState_HeadquartersProjectProvingGround(History.GetGameStateForObjectID(FacilityState.BuildQueue[iItemProject].ObjectID));
				if (ProvingGroundProject != none)
				{
					if (iItemProject == 0)
						CumulativeHours = ProvingGroundProject.GetCurrentNumHoursRemaining();
					else
						CumulativeHours += ProvingGroundProject.GetProjectedNumHoursRemaining();
				}

				if(ItemProject != none)
				{
					if(iItemProject == 0)
					{
						ItemState = XComGameState_Item(History.GetGameStateForObjectID(ItemProject.ProjectFocus.ObjectID));
						kEvent.Data = ItemEventLabel @ ItemState.GetMyTemplate().GetItemFriendlyName();
						CumulativeHours = ItemProject.GetCurrentNumHoursRemaining();
						kEvent.Hours = CumulativeHours;
					}
					else
					{
						ItemState = XComGameState_Item(History.GetGameStateForObjectID(ItemProject.ProjectFocus.ObjectID));
						kEvent.Data = ItemEventLabel @ ItemState.GetMyTemplate().GetItemFriendlyName();
						CumulativeHours += ItemProject.GetProjectedNumHoursRemaining();
						kEvent.Hours = CumulativeHours;
					}

					kEvent.ImagePath = class'UIUtilities_Image'.const.EventQueue_Engineer;
					if(kEvent.Hours < 0)
					{
						kEvent.Data = ProjectPausedLabel @ kEvent.Data;
					}

					AddEventToEventList(arrEvents, kEvent);
				}
			}
		}
	}
}

//---------------------------------------------------------------------------------------
function GetFacilityEvents(out array<HQEvent> arrEvents)
{
	local int iFacilityProject;
	local HQEvent kEvent;
	local XComGameState_HeadquartersProjectBuildFacility FacilityProject;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	for(iFacilityProject = 0; iFacilityProject < Projects.Length; iFacilityProject++)
	{
		FacilityProject = XComGameState_HeadquartersProjectBuildFacility(History.GetGameStateForObjectID(Projects[iFacilityProject].ObjectID));

		if(FacilityProject != none)
		{
			kEvent.Data = FacilityEventLabel @ XComGameState_FacilityXCom(History.GetGameStateForObjectID(FacilityProject.ProjectFocus.ObjectID)).GetMyTemplate().DisplayName;
			kEvent.Hours = FacilityProject.GetCurrentNumHoursRemaining();
			kEvent.ImagePath = class'UIUtilities_Image'.const.EventQueue_Engineer;

			if(kEvent.Hours < 0)
			{
				kEvent.Data = ProjectPausedLabel @ kEvent.Data;
			}

			AddEventToEventList(arrEvents, kEvent);
		}
	}
}

//---------------------------------------------------------------------------------------
function GetFacilityUpgradeEvents(out array<HQEvent> arrEvents)
{
	local int iUpgradeProject;
	local HQEvent kEvent;
	local XComGameState_HeadquartersProjectUpgradeFacility UpgradeProject;
	local XComGameStateHistory History;

	History = `XCOMHISTORY;

	for(iUpgradeProject = 0; iUpgradeProject < Projects.Length; iUpgradeProject++)
	{
		UpgradeProject = XComGameState_HeadquartersProjectUpgradeFacility(History.GetGameStateForObjectID(Projects[iUpgradeProject].ObjectID));

		if(UpgradeProject != none)
		{
			kEvent.Data = UpgradeEventLabel @ XComGameState_FacilityUpgrade(History.GetGameStateForObjectID(UpgradeProject.ProjectFocus.ObjectID)).GetMyTemplate().DisplayName;
			kEvent.Hours = UpgradeProject.GetCurrentNumHoursRemaining();
			kEvent.ImagePath = class'UIUtilities_Image'.const.EventQueue_Construction;

			if(kEvent.Hours < 0)
			{
				kEvent.Data = ProjectPausedLabel @ kEvent.Data;
			}

			AddEventToEventList(arrEvents, kEvent);
		}
	}
}

//---------------------------------------------------------------------------------------
function GetPsiTrainingEvents(out array<HQEvent> arrEvents)
{
	local XComGameStateHistory History;
	local HQEvent kEvent;
	local XComGameState_HeadquartersProjectPsiTraining PsiProject;
	local XComGameState_Unit UnitState;
	local X2AbilityTemplate AbilityTemplate;
	local name AbilityName;
	local string PsiTrainingStr;
	local int iPsiProject;

	History = `XCOMHISTORY;

	for( iPsiProject = 0; iPsiProject < Projects.Length; iPsiProject++ )
	{
		PsiProject = XComGameState_HeadquartersProjectPsiTraining(History.GetGameStateForObjectID(Projects[iPsiProject].ObjectID));

		if(PsiProject != none)
		{
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(PsiProject.ProjectFocus.ObjectID));

			if (UnitState.GetSoldierClassTemplateName() == 'PsiOperative')
			{
				AbilityName = UnitState.GetSoldierClassTemplate().GetAbilityName(PsiProject.iAbilityRank, PsiProject.iAbilityBranch);
				AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(AbilityName);
				PsiTrainingStr = Caps(AbilityTemplate.LocFriendlyName) @ TrainRookieEventLabel;
			}
			else
			{
				PsiTrainingStr = PsiTrainingEventLabel;
			}

			kEvent.Data = PsiTrainingStr @ UnitState.GetName(eNameType_RankFull);
			kEvent.Hours = PsiProject.GetCurrentNumHoursRemaining();
			kEvent.ImagePath = class'UIUtilities_Image'.const.EventQueue_Psi;

			if(kEvent.Hours < 0)
			{
				kEvent.Data = ProjectPausedLabel @ kEvent.Data;
			}

			AddEventToEventList(arrEvents, kEvent);
		}
	}
}

//---------------------------------------------------------------------------------------
function GetResistanceEvents(out array<HQEvent> arrEvents)
{
	local HQEvent kEvent;
	local XComGameState_HeadquartersResistance ResistanceHQ;;
	local XComGameStateHistory History;
	local XComGameState_MissionSite MissionState;

	History = `XCOMHISTORY;
		ResistanceHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));

	// Monthly supply drop
	if(!ResistanceHQ.bInactive)
	{
		kEvent.Data = SupplyDropEventLabel;
		kEvent.Hours = class'X2StrategyGameRulesetDataStructures'.static.DifferenceInHours(ResistanceHQ.MonthIntervalEndTime, `STRATEGYRULES.GameTime);
		kEvent.ImagePath = class'UIUtilities_Image'.const.EventQueue_Resistance;
		AddEventToEventList(arrEvents, kEvent);
	}

	foreach History.IterateByClassType(class'XComGameState_MissionSite', MissionState)
	{
		if(MissionState.bBuilding)
		{
			kEvent.Data = MissionBuildEventLabel;
			kEvent.Hours = MissionState.GetBuildHoursRemaining();
			kEvent.ImagePath = class'UIUtilities_Image'.const.EventQueue_Resistance;
			AddEventToEventList(arrEvents, kEvent);
		}
	}
}

function bool HasSoldierUnlockTemplate(name UnlockName)
{
	return SoldierUnlockTemplates.Find(UnlockName) != INDEX_NONE;
}

function bool AddSoldierUnlockTemplate(XComGameState NewGameState, X2SoldierUnlockTemplate UnlockTemplate)
{
	local XComGameState_HeadquartersXCom XComHQ;

	`assert(NewGameState != none);
	if (!HasSoldierUnlockTemplate(UnlockTemplate.DataName))
	{
		if (MeetsRequirmentsAndCanAffordCost(UnlockTemplate.Requirements, UnlockTemplate.Cost, OTSUnlockScalars, GTSPercentDiscount))
		{
			PayStrategyCost(NewGameState, UnlockTemplate.Cost, OTSUnlockScalars, GTSPercentDiscount);
			
			XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', ObjectID));
			XComHQ.SoldierUnlockTemplates.AddItem(UnlockTemplate.DataName);
			NewGameState.AddStateObject(XComHQ);
			UnlockTemplate.OnSoldierUnlockPurchased(NewGameState);
			return true;
		}
	}
	return false;
}

function array<X2SoldierUnlockTemplate> GetActivatedSoldierUnlockTemplates()
{
	local X2StrategyElementTemplateManager TemplateMan;
	local array<X2SoldierUnlockTemplate> ActivatedUnlocks;
	local name UnlockName;

	TemplateMan = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();

	ActivatedUnlocks.Length = 0;

	foreach SoldierUnlockTemplates(UnlockName)
	{
		ActivatedUnlocks.AddItem(X2SoldierUnlockTemplate(TemplateMan.FindStrategyElementTemplate(UnlockName)));
	}

	return ActivatedUnlocks;
}

function ClearSoldierUnlockTemplates()
{
	// Saved the list in case the GTS is rebuilt, then clear it
	SavedSoldierUnlockTemplates = SoldierUnlockTemplates;
	SoldierUnlockTemplates.Length = 0;
}

function RestoreSoldierUnlockTemplates()
{
	SoldierUnlockTemplates = SavedSoldierUnlockTemplates;
}

function OnCrewMemberAdded(XComGameState NewGameState, XComGameState_Unit NewUnitState)
{
	local X2StrategyElementTemplateManager TemplateMan;
	local X2SoldierUnlockTemplate UnlockTemplate;
	local name UnlockName;
	local StateObjectReference NewUnitRef;
	local XComHeadquartersGame HQGame;
	local XComPhotographer_Strategy Photographer;
	local XComGameState_HeadquartersProjectHealSoldier ProjectState;

	HQGame = XComHeadquartersGame(class'WorldInfo'.static.GetWorldInfo().Game);
	if (HQGame != none)
	{
		Photographer = HQGame.GetGamecore().StrategyPhotographer;
	}

	NewUnitRef = NewUnitState.GetReference( );
	if (`STRATEGYRULES == none)
		class'X2StrategyGameRulesetDataStructures'.static.SetTime(NewUnitState.m_RecruitDate, 0, 0, 0, class'X2StrategyGameRulesetDataStructures'.default.START_MONTH, class'X2StrategyGameRulesetDataStructures'.default.START_DAY, class'X2StrategyGameRulesetDataStructures'.default.START_YEAR );	
	else
		NewUnitState.m_RecruitDate = `STRATEGYRULES.GameTime;

	//  note we expect Crew has already had the reference added to it.
	if (NewUnitState.IsSoldier())
	{
		NewUnitState.ValidateLoadout(NewGameState);

		TemplateMan = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
		foreach SoldierUnlockTemplates(UnlockName)
		{
			UnlockTemplate = X2SoldierUnlockTemplate(TemplateMan.FindStrategyElementTemplate(UnlockName));
			if (UnlockTemplate != none)
			{
				UnlockTemplate.OnSoldierAddedToCrew(NewUnitState);
			}
		}

		if(NewUnitState.GetRank() >= 1 && HasFacilityByName('AdvancedWarfareCenter'))
		{
			NewUnitState.RollForAWCAbility();
		}

		if(NewUnitState.IsInjured() && NewUnitState.GetStatus() != eStatus_Healing)
		{
			ProjectState = XComGameState_HeadquartersProjectHealSoldier(NewGameState.CreateStateObject(class'XComGameState_HeadquartersProjectHealSoldier'));
			NewGameState.AddStateObject(ProjectState);

			ProjectState.SetProjectFocus(NewUnitState.GetReference(), NewGameState);

			NewUnitState.SetStatus(eStatus_Healing);
			Projects.AddItem(ProjectState.GetReference());
		}
	}

	if (Photographer != none)
	{
		Photographer.AddHeadshotRequest(NewUnitRef, 'UIPawnLocation_ArmoryPhoto', 'SoldierPicture_Passport_Armory', 128, 128, OnSoldierHeadCaptureFinishedSmall, class'X2StrategyElement_DefaultSoldierPersonalities'.static.Personality_ByTheBook());
		NewStaffRefs.AddItem(NewUnitRef);

		Photographer.AddHeadshotRequest(NewUnitRef, 'UIPawnLocation_ArmoryPhoto', 'SoldierPicture_Head_Armory', 512, 512, OnSoldierHeadCaptureFinishedLarge, class'X2StrategyElement_DefaultSoldierPersonalities'.static.Personality_ByTheBook());
		NewStaffRefs.AddItem(NewUnitRef);
	}

	`XEVENTMGR.TriggerEvent('NewCrewNotification', NewUnitState, self, XComGameState(NewUnitState.Outer) );
}

private function OnSoldierHeadCaptureFinishedSmall(const out HeadshotRequestInfo ReqInfo, TextureRenderTarget2D RenderTarget)
{
	StoreStaffImage("UnitPictureSmall"$ReqInfo.UnitRef.ObjectID, ReqInfo, RenderTarget);
}

private function OnSoldierHeadCaptureFinishedLarge(const out HeadshotRequestInfo ReqInfo, TextureRenderTarget2D RenderTarget)
{
	StoreStaffImage("UnitPicture"$ReqInfo.UnitRef.ObjectID, ReqInfo, RenderTarget);
}

private function StoreStaffImage(string TextureName, const out HeadshotRequestInfo ReqInfo, TextureRenderTarget2D RenderTarget)
{
	local Texture2D StaffPicture;
	local int ReqIdx;

	ReqIdx = NewStaffRefs.Find('ObjectID', ReqInfo.UnitRef.ObjectID);
	if (ReqIdx == -1)
	{
		`Redscreen("Staff photograph handled is not the one requested!");
		return;
	}

	StaffPicture = RenderTarget.ConstructTexture2DScript(X2ImageCaptureManager(`XENGINE.GetImageCaptureManager()), TextureName, false, false, false);
	X2ImageCaptureManager(`XENGINE.GetImageCaptureManager()).StoreImage(ReqInfo.UnitRef, StaffPicture, name(TextureName));
	NewStaffRefs.Remove(ReqIdx, 1);
}

// Assumes a new game state has already been created
function ResetToDoWidgetWarnings()
{
	bPlayedWarningNoResearch = false;
	bPlayedWarningUnstaffedEngineer = false;
	bPlayedWarningUnstaffedScientist = false;
	bPlayedWarningNoIncome = false;
	bHasSeenSupplyDropReminder = false;
}


// =======================================================================================================
// ======================= Strategy Refactor =============================================================
// =======================================================================================================

function ReturnToResistanceHQ(optional bool bOpenResHQGoods, optional bool bAlertResHQGoods)
{
	local XComGameState NewGameState;
	local XComGameState_Haven ResHQ;
		
	ResHQ = XComGameState_Haven(`XCOMHISTORY.GetGameStateForObjectID(StartingHaven.ObjectID));

	if (bOpenResHQGoods || bAlertResHQGoods)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Set ResHQ Haven on Arrival Flags");
		ResHQ = XComGameState_Haven(NewGameState.CreateStateObject(class'XComGameState_Haven', ResHQ.ObjectID));
		NewGameState.AddStateObject(ResHQ);
		ResHQ.bOpenOnXCOMArrival = bOpenResHQGoods;
		ResHQ.bAlertOnXCOMArrival = bAlertResHQGoods;
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}

	SetPendingPointOfTravel(ResHQ);
}

function bool IsAtResistanceHQ()
{	
	return (CurrentLocation.ObjectID == StartingHaven.ObjectID);
}

function ReturnToSavedLocation()
{
	local XComGameState_GeoscapeEntity ReturnSite;

	ReturnSite = XComGameState_GeoscapeEntity(`XCOMHISTORY.GetGameStateForObjectID(SavedLocation.ObjectID));
	SetPendingPointOfTravel(ReturnSite);
}

function StartUFOChase(StateObjectReference UFORef)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_UFO UFOState;
	local XComGameState_MissionSiteAvengerDefense AvengerDefense;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Start UFO Chase");
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', ObjectID));

	XComHQ.SavedLocation = CurrentLocation;
	XComHQ.bUFOChaseInProgress = true;
	XComHQ.AttackingUFO = UFORef;

	NewGameState.AddStateObject(XComHQ);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		
	// If there is only one or none UFO chase locations, spawn and fly to Avg Def immediately
	UFOState = XComGameState_UFO(`XCOMHISTORY.GetGameStateForObjectID(UFORef.ObjectID));
	if (UFOState.bDoesInterceptionSucceed && default.UFOChaseLocations <= 1)
	{
		AvengerDefense = UFOState.CreateAvengerDefenseMission(GetContinent().GetRandomRegionInContinent(Region).GetReference());
		AvengerDefense.ConfirmSelection(); // Set XComHQ to fly to the Avenger Defense mission site
	}
	else // Otherwise pick a random region on the continent for the Avenger to flee towards
	{
		GetContinent().GetRandomRegionInContinent(Region).ConfirmSelection();
	}

	UFOState.FlyTo(self); // Tell the UFO to follow the Avenger
}

final function SetPendingPointOfTravel(const out XComGameState_GeoscapeEntity GeoscapeEntity, optional bool bInstantCamInterp = false)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Set Pending Point Of Travel");
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', ObjectID));

	XComHQ.SelectedDestination.ObjectID = GeoscapeEntity.ObjectID;

	NewGameState.AddStateObject(XComHQ);
	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

	// Trigger an update of flight status for the Skyanger/Avenger
	XComHQ.UpdateFlightStatus(bInstantCamInterp);
}

// Hook to update the flight data of the Skyranger/Avenger.
final function UpdateFlightStatus(optional bool bInstantCamInterp = false)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_GeoscapeEntity SelectedDestinationEntity;
	local XComGameState_Skyranger Skyranger;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_ScanningSite ScanSiteState;

	History = `XCOMHISTORY;
	XComHQ = self;
	Skyranger = XComGameState_Skyranger(History.GetGameStateForObjectID(SkyrangerRef.ObjectID));
	SelectedDestinationEntity = XComGameState_GeoscapeEntity(History.GetGameStateForObjectID(SelectedDestination.ObjectID));

	if( SelectedDestinationEntity == None )
	{
		// Skyranger RTB
		Skyranger.FlyTo(XComHQ, bInstantCamInterp);
	}
	else if( SelectedDestinationEntity.RequiresAvenger() )
	{
		// update avenger flight

		if( IsSkyrangerDocked() )
		{
			// cleanup the current continent before flying to the new one
			ScanSiteState = XComGameState_ScanningSite(History.GetGameStateForObjectID(XComHQ.CurrentLocation.ObjectID));
			ScanSiteState.OnXComLeaveSite();
			
			if (bUFOChaseInProgress && CurrentlyInFlight)
			{
				FlyToUFOChase(SelectedDestinationEntity);
			}
			else
			{
				// zoom zoom
				`XSTRATEGYSOUNDMGR.PlaySoundEvent("Geoscape_AvengerLiftOff");

				if (SelectedDestinationEntity.ObjectID != CurrentLocation.ObjectID)
				{
					NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Trigger Avenger Flight Event");
					if (SelectedDestinationEntity.Region.ObjectID != 0)
					{
						`XEVENTMGR.TriggerEvent('OnAvengerTakeOff', SelectedDestinationEntity.GetWorldRegion(), SelectedDestinationEntity.GetWorldRegion(), NewGameState);
					}
					else
					{
						`XEVENTMGR.TriggerEvent('OnAvengerTakeOffGeneric', , , NewGameState);
					}

					`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
				}

				// avenger fly to SelectedDestinationEntity
				FlyTo(SelectedDestinationEntity, bInstantCamInterp);
			}
		}
		else
		{
			// zoom zoom
			`XSTRATEGYSOUNDMGR.PlaySoundEvent("Geoscape_SkyrangerStart");

			// skyranger RTB
			Skyranger.FlyTo(XComHQ, bInstantCamInterp);
		}
	}
	else
	{
		// update skyranger flight

		// zoom zoom
		`XSTRATEGYSOUNDMGR.PlaySoundEvent("Geoscape_SkyrangerStart");

		if( SelectedDestinationEntity.RequiresSquad() )
		{
			if( Skyranger.SquadOnBoard )
			{
				// Skyranger fly to SelectedDestinationEntity
				`HQPRES.UINarrative(XComNarrativeMoment'X2NarrativeMoments.Strategy.Avenger_Skyranger_Deployed');
				Skyranger.FlyTo(SelectedDestinationEntity, bInstantCamInterp);
			}
			else
			{
				// Skyranger RTB (to pick up squad)
				Skyranger.FlyTo(XComHQ, bInstantCamInterp);
			}
		}
		else
		{
			if( Skyranger.SquadOnBoard )
			{
				// Skyranger RTB (to drop off squad)
				Skyranger.FlyTo(XComHQ, bInstantCamInterp);
			}
			else
			{
				// Skyranger fly to SelectedDestinationEntity
				Skyranger.FlyTo(SelectedDestinationEntity, bInstantCamInterp);
			}
		}
	}
}

function FlyToUFOChase(XComGameState_GeoscapeEntity InTargetEntity)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom NewXComHQ;

	`assert(InTargetEntity.ObjectID > 0);

	if (TargetEntity.ObjectID != InTargetEntity.ObjectID)
	{
		// set new target location - course change!
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("UFO Chase: XComHQ Course Change");
		NewXComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(Class, ObjectID));
		
		NewXComHQ.TargetEntity.ObjectID = InTargetEntity.ObjectID;
		NewXComHQ.SourceLocation = Get2DLocation();
		NewXComHQ.FlightDirection = GetFlightDirection(NewXComHQ.SourceLocation, InTargetEntity.Get2DLocation());
		NewXComHQ.TotalFlightDistance = GetDistance(NewXComHQ.SourceLocation, InTargetEntity.Get2DLocation());
		NewXComHQ.Velocity = vect(0.0, 0.0, 0.0);
		NewXComHQ.CurrentlyInFlight = true;
		NewXComHQ.Flying = true;
		
		NewGameState.AddStateObject(NewXComHQ);
		`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
	}
}

function UpdateMovement(float fDeltaT)
{
	if (CurrentlyInFlight && TargetEntity.ObjectID > 0)
	{
		OldDeltaT = fDeltaT;
		OldVelocity = Velocity;

		if (Flying)
		{
			`GAME.GetGeoscape().m_fTimeScale = InFlightTimeScale; // Speed up the time scale
			UpdateMovementFly(fDeltaT);
		}
	}
}

function TransitionFlightToLand()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_UFO UFOState;
	local XComGameState_MissionSiteAvengerDefense AvengerDefense;
	local XComGameState_GeoscapeEntity NewDestination, SelectedDestinationEntity;
	
	if (bUFOChaseInProgress)
	{
		SelectedDestinationEntity = XComGameState_GeoscapeEntity(`XCOMHISTORY.GetGameStateForObjectID(SelectedDestination.ObjectID));
		AvengerDefense = XComGameState_MissionSiteAvengerDefense(SelectedDestinationEntity);

		if (UFOChaseLocationsCompleted < default.UFOChaseLocations && AvengerDefense == none)
		{
			// Save the updated location and chase count to the history
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("UFO Chase: Update XComHQ Location");
			XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(Class, ObjectID));
			XComHQ.UFOChaseLocationsCompleted++;
			NewGameState.AddStateObject(XComHQ);
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

			// Pick the next location
			if (class'X2StrategyGameRulesetDataStructures'.static.Roll(UFOChaseChanceToSwitchContinent)) // If random roll success, pick a random continent
			{
				NewDestination = class'UIUtilities_Strategy'.static.GetRandomContinent(SelectedDestinationEntity.Continent).GetRandomRegionInContinent();
			}
			else //	Pick a random region on the current continent, excluding the current one
			{
				NewDestination = SelectedDestinationEntity.GetContinent().GetRandomRegionInContinent(SelectedDestinationEntity.Region);
			}

			NewDestination.ConfirmSelection();
						
			if (UFOChaseLocationsCompleted == (default.UFOChaseLocations - 1))
			{
				UFOState = XComGameState_UFO(`XCOMHISTORY.GetGameStateForObjectID(AttackingUFO.ObjectID));
				if (!UFOState.bDoesInterceptionSucceed) // If interception does not succeed, have the UFO fly away from the Avenger right before the chase ends
				{
					NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("UFO Chase: Evade UFO");
					UFOState = XComGameState_UFO(NewGameState.CreateStateObject(class'XComGameState_UFO', UFOState.ObjectID));
					UFOState.bChasingAvenger = false;
					NewGameState.AddStateObject(UFOState);
					`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

					UFOState.FlyTo(class'UIUtilities_Strategy'.static.GetRandomContinent(SelectedDestinationEntity.Continent).GetRandomRegionInContinent());
				}
			}
		}
		else // If XComHQ is being chased and the number of chase locations HAS been reached
		{
			UFOState = XComGameState_UFO(`XCOMHISTORY.GetGameStateForObjectID(AttackingUFO.ObjectID));
			if (UFOState.bDoesInterceptionSucceed)
			{
				if (AvengerDefense != none) // If Avg Def is created, insta-land to begin the mission
				{
					if (UFOState.GetDistanceToAvenger() < 150) // But only if the UFO is close enough...
					{
						// Reset the UFO chase sequence variables
						ResetUFOChaseSequence(false);
						ProcessFlightComplete();

						`XSTRATEGYSOUNDMGR.PlaySoundEvent("Geoscape_UFO_Fly_Stop");
					}
				}
				else // Otherwise, create the Avg Def mission in a random region on the current continent
				{
					UFOState = XComGameState_UFO(`XCOMHISTORY.GetGameStateForObjectID(AttackingUFO.ObjectID));
					AvengerDefense = UFOState.CreateAvengerDefenseMission(SelectedDestinationEntity.GetContinent().GetRandomRegionInContinent(SelectedDestinationEntity.Region).GetReference());
					AvengerDefense.ConfirmSelection(); // Set XComHQ to fly to the Avenger Defense mission site
				}
			}
			else // If interception fails, land normally
			{
				super.TransitionFlightToLand();
			}
		}
	}
	else
	{
		super.TransitionFlightToLand();
	}
}

function ResetUFOChaseSequence(bool bRemoveUFO)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_UFO UFOState;

	// Reset the UFO chase sequence variables
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("UFO Chase Sequence Completed");
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(Class, ObjectID));
	NewGameState.AddStateObject(XComHQ);
	XComHQ.bUFOChaseInProgress = false;
	XComHQ.UFOChaseLocationsCompleted = 0;
	XComHQ.AttackingUFO.ObjectID = 0;
	XComHQ.Location.Z = 0.0;

	if (bRemoveUFO)
	{
		UFOState = XComGameState_UFO(`XCOMHISTORY.GetGameStateForObjectID(AttackingUFO.ObjectID));
		UFOState.RemoveEntity(NewGameState);
	}

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

function OnTakeOff(optional bool bInstantCamInterp = false)
{
	local XComHQPresentationLayer PresLayer;

	PresLayer = `HQPRES;

	// Update landing site map
	UpdateLandingSite(true);

	// Pause all HQ projects for flight
	PauseProjectsForFlight();

	// Hide map UI elements while flying
	PresLayer.StrategyMap2D.SetUIState(eSMS_Flight);

	if(bInstantCamInterp)
	{
		PresLayer.UIFocusOnEntity(self, 0.66f, 0.0f); //focus the camera on the airship
	}
	else
	{
		PresLayer.UIFocusOnEntity(self, 0.66f); //focus the camera on the airship
	}
}

function OnLanded()
{
	local XComHQPresentationLayer PresLayer;

	PresLayer = `HQPRES;

	// Update landing site map
	UpdateLandingSite(false);

	if (!bReturningFromMission)
	{
		`GAME.GetGeoscape().m_fTimeScale = `GAME.GetGeoscape().ONE_MINUTE;
	};
	
	// Show map UI elements which were hidden while flying
	PresLayer.StrategyMap2D.SetUIState(eSMS_Default);

	OnFlightCompleted(TargetEntity, true);
}

function UpdateLandingSite(bool bTakeOff)
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Update Landing Site");
	XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', self.ObjectID));
	NewGameState.AddStateObject(XComHQ);

	if(bTakeOff)
	{
		XComHQ.LandingSiteMap = "";
	}
	else
	{
		XComHQ.LandingSiteMap = class'XGBase'.static.GetBiomeTerrainMap(true);
	}

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

final function OnFlightCompleted(StateObjectReference ArrivedAtEntity, optional bool bIsAvenger = false)
{
	local XComGameStateHistory History;
	local XComGameState_GeoscapeEntity SelectedDestinationEntity;
	local XComGameState_Skyranger SkyrangerState;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom XComHQ;

	History = `XCOMHISTORY;
	SelectedDestinationEntity = XComGameState_GeoscapeEntity(History.GetGameStateForObjectID(SelectedDestination.ObjectID));

	if( ArrivedAtEntity == SelectedDestination )
	{
		// if HQ resume projects
		if(!bIsAvenger)
		{
			`XSTRATEGYSOUNDMGR.PlaySoundEvent("Geoscape_SkyrangerStop");
		}
		else
		{
			//Update the skyranger location to match the avenger after it moves between continents
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Update Skyranger location");
			SkyrangerState = XComGameState_Skyranger(NewGameState.CreateStateObject(class'XComGameState_Skyranger', SkyrangerRef.ObjectID));
			SkyrangerState.Location = GetLocation();
			NewGameState.AddStateObject(SkyrangerState);
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

			//Zoom in on the avenger after it lands
			`HQPRES.UIFocusOnEntity(`XCOMHQ);
		}
		
		// Resume all HQ Projects
		ResumeProjectsPostFlight();

		// handle arrival at target destination
		SelectedDestinationEntity.DestinationReached();

		// If XComHQ lands while a chase is in progress and it is not at Avg Def, the UFO was successfully evaded
		if (bUFOChaseInProgress && XComGameState_MissionSiteAvengerDefense(SelectedDestinationEntity) == none)
		{
			ResetUFOChaseSequence(true);
			`HQPRES.UIUFOEvadedAlert();
		}
	}
	
	if( ArrivedAtEntity.ObjectID == ObjectID )
	{
		// Skyranger has completed RTB
		`XSTRATEGYSOUNDMGR.PlaySoundEvent("Geoscape_SkyrangerStop");

		if( SelectedDestinationEntity.RequiresSquad() )
		{
			// squad select
			SelectedDestinationEntity.SelectSquad();
		}
		else
		{
			// Unload squad
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Unload Squad from Skyranger");
			SkyrangerState = XComGameState_Skyranger(NewGameState.CreateStateObject(class'XComGameState_Skyranger', SkyrangerRef.ObjectID));
			SkyrangerState.SquadOnBoard = false;
			NewGameState.AddStateObject(SkyrangerState);
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);

			// continue on to selected destination immediately
			if( ArrivedAtEntity != SelectedDestination )
				UpdateFlightStatus();

			if(`SCREENSTACK.IsInStack(class'UIStrategyMap'))
				UIStrategyMap(`SCREENSTACK.GetScreen(class'UIStrategyMap')).UpdateButtonHelp();

			// launch after action report on return to base after mission
			if (bReturningFromMission)
			{
				NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Complete return from mission");
				XComHQ = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', self.ObjectID));
				XComHQ.bReturningFromMission = false;
				NewGameState.AddStateObject(XComHQ);
				`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);				
			}
		}
	}
}

function bool IsSkyrangerDocked()
{
	local XComGameStateHistory History;
	local XComGameState_Airship Skyranger;

	History = `XCOMHISTORY;

	Skyranger = XComGameState_Airship(History.GetGameStateForObjectID(SkyrangerRef.ObjectID));

	return ( Skyranger.TargetEntity.ObjectID == ObjectID && Skyranger.IsFlightComplete() );
}

function XComGameState_Skyranger GetSkyranger()
{
	local XComGameState_Skyranger Skyranger;

	Skyranger = XComGameState_Skyranger(`XCOMHISTORY.GetGameStateForObjectID(SkyrangerRef.ObjectID));

	return Skyranger;
}

function PauseProjectsForFlight()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersProject ProjectState;
	local XComGameState_HeadquartersProjectHealSoldier HealProject;
	local int idx;
	
	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Pause All Projects");

	for (idx = 0; idx < Projects.Length; idx++)
	{
		ProjectState = XComGameState_HeadquartersProject(History.GetGameStateForObjectID(Projects[idx].ObjectID));
		HealProject = XComGameState_HeadquartersProjectHealSoldier(History.GetGameStateForObjectID(Projects[idx].ObjectID));

		// Pause all projects EXCEPT soldiers healing
		if (ProjectState != none && HealProject == none)
		{
			ProjectState = XComGameState_HeadquartersProject(NewGameState.CreateStateObject(ProjectState.Class, ProjectState.ObjectID));
			ProjectState.PauseProject();
			NewGameState.AddStateObject(ProjectState);
		}
	}

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

function ResumeProjectsPostFlight()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_HeadquartersProject ProjectState;
	local XComGameState_HeadquartersProjectHealSoldier HealProject;
	local int idx;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Resume All Projects");

	for (idx = 0; idx < Projects.Length; idx++)
	{
		ProjectState = XComGameState_HeadquartersProject(History.GetGameStateForObjectID(Projects[idx].ObjectID));
		HealProject = XComGameState_HeadquartersProjectHealSoldier(History.GetGameStateForObjectID(Projects[idx].ObjectID));

		if(ProjectState != none && HealProject == none)
		{
			ProjectState = XComGameState_HeadquartersProject(NewGameState.CreateStateObject(ProjectState.Class, ProjectState.ObjectID));
			ProjectState.ResumeProject();
			NewGameState.AddStateObject(ProjectState);
		}
	}

	`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
}

//#############################################################################################
//----------------   Geoscape Entity Implementation   -----------------------------------------
//#############################################################################################

function class<UIStrategyMapItem> GetUIClass()
{
	return class'UIStrategyMapItem_Avenger';
}

function class<UIStrategyMapItemAnim3D> GetMapItemAnim3DClass()
{
	return class'UIStrategyMapItemAnim3D_Airship';
}

function string GetUIWidgetFlashLibraryName()
{
	return string(class'UIPanel'.default.LibID);
}

function string GetUIPinImagePath()
{
	return "";
}

// The skeletal mesh for this entity's 3D UI
function SkeletalMesh GetSkeletalMesh()
{
	return SkeletalMesh'AvengerIcon_ANIM.Meshes.SM_AvengerIcon';
}

function AnimSet GetAnimSet()
{
	return AnimSet'AvengerIcon_ANIM.Anims.AS_AvengerIcon';
}

function AnimTree GetAnimTree()
{
	return AnimTree'AnimatedUI_ANIMTREE.AircraftIcon_ANIMTREE';
}

// Scale adjustment for the 3D UI static mesh
function vector GetMeshScale()
{
	local vector ScaleVector;

	ScaleVector.X = 1.15;
	ScaleVector.Y = 1.15;
	ScaleVector.Z = 1.15;

	return ScaleVector;
}

// Rotation adjustment for the 3D UI static mesh
function Rotator GetMeshRotator()
{
	local Rotator MeshRotation;

	MeshRotation.Roll = 0;
	MeshRotation.Pitch = 0;
	MeshRotation.Yaw = 180 * DegToUnrRot; //Rotate by 180 degrees so the ship is facing the correct way when flying

	return MeshRotation;
}

protected function bool CanInteract()
{
	return false;
}


function UpdateGameBoard()
{
	local XComGameState NewGameState;
	local XComGameState_HeadquartersXCom NewXComHQState;
	local XComGameStateHistory History;
	local int idx;
	local XComGameState_HeadquartersProject ProjectState;
	local XComHQPresentationLayer Pres;
	local array<XComGameState_Unit> UnitsWhichLeveledUp;
	local XComGameState_Objective ObjectiveState, NewObjectiveState;

	Pres = `HQPRES;
	History = `XCOMHISTORY;
	
	// Don't let any HQ updates complete while the Avenger or Skyranger are flying, or if another popup is already being presented
	if (Pres.StrategyMap2D != none && Pres.StrategyMap2D.m_eUIState != eSMS_Flight && !Pres.ScreenStack.HasInstanceOf(class'UIAlert'))
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Update XCom Headquarters");
		NewXComHQState = XComGameState_HeadquartersXCom(NewGameState.CreateStateObject(class'XComGameState_HeadquartersXCom', ObjectID));
		NewGameState.AddStateObject(NewXComHQState);

		if (!NewXComHQState.Update(NewGameState, UnitsWhichLeveledUp))
		{
			NewGameState.PurgeGameStateForObjectID(NewXComHQState.ObjectID);
		}

		// Check objectives for nags
		foreach History.IterateByClassType(class'XComGameState_Objective', ObjectiveState)
		{
			if (ObjectiveState.CheckNagTimer())
			{
				NewObjectiveState = XComGameState_Objective(NewGameState.CreateStateObject(class'XComGameState_Objective', ObjectiveState.ObjectID));
				NewGameState.AddStateObject(NewObjectiveState);
				
				NewObjectiveState.BeginNagging(NewXComHQState);
			}
		}

		if (NewGameState.GetNumGameStateObjects() > 0)
		{
			`XCOMGAME.GameRuleset.SubmitGameState(NewGameState);
		}
		else
		{
			History.CleanupPendingGameState(NewGameState);
		}

		// Check projects for completion
		for (idx = 0; idx < Projects.Length; idx++)
		{
			ProjectState = XComGameState_HeadquartersProject(History.GetGameStateForObjectID(Projects[idx].ObjectID));

			if (ProjectState != none)
			{
				if (!ProjectState.bIncremental)
				{
					if (class'X2StrategyGameRulesetDataStructures'.static.LessThan(ProjectState.CompletionDateTime, GetCurrentTime()))
					{
						ProjectState.OnProjectCompleted();
						XGMissionControlUI(Pres.GetMgr(class'XGMissionControlUI')).UpdateView();
						HandlePowerOrStaffingChange();
						break;
					}
				}
				else
				{
					if (ProjectState.BlocksRemaining <= 0)
					{
						ProjectState.OnProjectCompleted();
						XGMissionControlUI(Pres.GetMgr(class'XGMissionControlUI')).UpdateView();
						HandlePowerOrStaffingChange();
						break;
					}
					if (class'X2StrategyGameRulesetDataStructures'.static.LessThan(ProjectState.BlockCompletionDateTime, GetCurrentTime()))
					{
						ProjectState.OnBlockCompleted();
					}
				}
			}
		}
	}

	super.UpdateGameBoard();
}

function AddSeenCharacterTemplate(X2CharacterTemplate CharacterTemplate)
{
	SeenCharacterTemplates.AddItem(CharacterTemplate.CharacterGroupName);
}

function bool HasSeenCharacterTemplate(X2CharacterTemplate CharacterTemplate)
{
	return (SeenCharacterTemplates.Find(CharacterTemplate.CharacterGroupName) != INDEX_NONE);
}

function XComGameState_WorldRegion GetRegionByName(Name RegionTemplateName)
{
	local XComGameStateHistory History;
	local XComGameState_WorldRegion WorldRegion;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_WorldRegion', WorldRegion)
	{
		if( WorldRegion.GetMyTemplateName() == RegionTemplateName )
		{
			return WorldRegion;
		}
	}

	return None;
}

//#############################################################################################
//----------------   NARRATIVE   --------------------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function bool CanPlayLootNarrativeMoment(XComNarrativeMoment Moment)
{
	local int NarrativeInfoIdx;
	local string QualifiedName;

	QualifiedName = PathName(Moment);

	NarrativeInfoIdx = PlayedLootNarrativeMoments.Find('QualifiedName', QualifiedName);

	if(NarrativeInfoIdx == INDEX_NONE || /*!Moment.bFirstTimeAtIndexZero ||*/ (PlayedLootNarrativeMoments[NarrativeInfoIdx].PlayCount < 1))
	{
		return true;
	}

	return false;
}

//---------------------------------------------------------------------------------------
function UpdatePlayedLootNarrativeMoments(XComNarrativeMoment Moment)
{
	local int NarrativeInfoIdx;
	local string QualifiedName;
	local AmbientNarrativeInfo NarrativeInfo;

	QualifiedName = PathName(Moment);

	NarrativeInfoIdx = PlayedLootNarrativeMoments.Find('QualifiedName', QualifiedName);

	if(NarrativeInfoIdx != INDEX_NONE)
	{
		NarrativeInfo = PlayedLootNarrativeMoments[NarrativeInfoIdx];
		`assert(NarrativeInfo.QualifiedName == QualifiedName);
		NarrativeInfo.PlayCount++;
		PlayedLootNarrativeMoments[NarrativeInfoIdx] = NarrativeInfo;
	}
	else
	{
		NarrativeInfo.QualifiedName = QualifiedName;
		NarrativeInfo.PlayCount = 1;
		PlayedLootNarrativeMoments.AddItem(NarrativeInfo);
	}
}

//---------------------------------------------------------------------------------------
function bool CanPlayArmorIntroNarrativeMoment(XComNarrativeMoment Moment)
{
	local int NarrativeInfoIdx;
	local string QualifiedName;

	QualifiedName = PathName(Moment);

	NarrativeInfoIdx = PlayedArmorIntroNarrativeMoments.Find('QualifiedName', QualifiedName);

	if(NarrativeInfoIdx == INDEX_NONE || /*!Moment.bFirstTimeAtIndexZero ||*/ (PlayedArmorIntroNarrativeMoments[NarrativeInfoIdx].PlayCount < 1))
	{
		return true;
	}

	return false;
}

//---------------------------------------------------------------------------------------
function UpdatePlayedArmorIntroNarrativeMoments(XComNarrativeMoment Moment)
{
	local int NarrativeInfoIdx;
	local string QualifiedName;
	local AmbientNarrativeInfo NarrativeInfo;

	QualifiedName = PathName(Moment);

	NarrativeInfoIdx = PlayedArmorIntroNarrativeMoments.Find('QualifiedName', QualifiedName);

	if(NarrativeInfoIdx != INDEX_NONE)
	{
		NarrativeInfo = PlayedArmorIntroNarrativeMoments[NarrativeInfoIdx];
		`assert(NarrativeInfo.QualifiedName == QualifiedName);
		NarrativeInfo.PlayCount++;
		PlayedArmorIntroNarrativeMoments[NarrativeInfoIdx] = NarrativeInfo;
	}
	else
	{
		NarrativeInfo.QualifiedName = QualifiedName;
		NarrativeInfo.PlayCount = 1;
		PlayedArmorIntroNarrativeMoments.AddItem(NarrativeInfo);
	}
}

//#############################################################################################
//----------------   DIFFICULTY HELPERS   -----------------------------------------------------
//#############################################################################################

//---------------------------------------------------------------------------------------
function int GetStartingSupplies()
{
	return default.XComHeadquarters_StartingValueSupplies[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
function int GetStartingIntel()
{
	return default.XComHeadquarters_StartingValueIntel[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
function int GetStartingAlloys()
{
	return default.XComHeadquarters_StartingValueAlienAlloys[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
function int GetStartingElerium()
{
	return default.XComHeadquarters_StartingValueEleriumCrystals[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
function int GetStartingCommCapacity()
{
	return default.XComHeadquarters_StartingCommCapacity[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
function int GetStartingPowerProduced()
{
	return default.XComHeadquarters_StartingPowerProduced[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
function int GetTrainRookieDays()
{
	return default.XComHeadquarters_DefaultTrainRookieDays[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
function int GetPsiTrainingDays()
{
	return default.XComHeadquarters_PsiTrainingDays[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
function float GetPsiTrainingScalar()
{
	return default.PsiTrainingRankScalar[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
function int GetStartingRegionSupplyDrop()
{
	return default.StartingRegionSupplyDrop[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
function int GetRespecSoldierDays()
{
	return default.XComHeadquarters_DefaultRespecSoldierDays[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
function int GetShakenChance()
{
	return default.XComHeadquarters_ShakenChance[`DifficultySetting];
}

//---------------------------------------------------------------------------------------
function int GetShakenRecoveryMissions()
{
	return default.XComHeadquarters_ShakenRecoverMissionsRequired[`DifficultySetting];
}

simulated native function int GetGenericKeyValue(string key);
simulated native function SetGenericKeyValue(string key, INT Value);

/////////////////////////////////////////////////////////////////////////////////////////
// cpptext

cpptext
{
public:
	void Serialize(FArchive& Ar);
};

DefaultProperties
{
	CurrentScanRate=1.0
}
