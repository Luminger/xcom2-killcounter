/**
 * Retrieves information about the number of members on a team
 */
class SeqAct_GetUnitCounts extends SequenceAction;

var int Total;
var int RemainingPlayable;
var int Alive;
var int Dead;
var int OnMap;
var int Incapacitated;
var int Confused;
var() string CharacterTemplateFilter;
var() bool bSkipTurrets; // Turrets are not counted by default.
var() string VolumeTag;

event Activated()
{
	local XGPlayer RequestedPlayer;
	local array<XComGameState_Unit> Units;
	local int RemovedFromPlay;

	Total = 0;
	RemainingPlayable = 0;
	Alive = 0;
	Dead = 0;
	OnMap = 0;
	Incapacitated = 0;
	Confused = 0;

	RequestedPlayer = GetRequestedPlayer();
	if (RequestedPlayer != none)
	{
		RequestedPlayer.GetUnits(Units, bSkipTurrets,, true);
		Total = GetFilteredUnitCount(Units);

		Units.Length = 0; // clear the array, since these functions do not
		RequestedPlayer.GetAliveUnits(Units, bSkipTurrets, true);
		Alive = GetFilteredUnitCount(Units);

		Units.Length = 0;
		RequestedPlayer.GetDeadUnits(Units, bSkipTurrets, true);
		Dead = GetFilteredUnitCount(Units);

		Units.Length = 0;
		RequestedPlayer.GetUnitsOnMap(Units, bSkipTurrets, true);
		OnMap = GetFilteredUnitCount(Units);

		Units.Length = 0;
		RequestedPlayer.GetIncapacitatedUnits(Units, bSkipTurrets);
		Incapacitated = GetFilteredUnitCount(Units);

		Units.Length = 0;
		RequestedPlayer.GetConfusedUnits(Units, bSkipTurrets);
		Confused = GetFilteredUnitCount(Units);

		// derive remaining playable. This criteria should be kept in sync with KismetGameRulesetEventObserver::DidPlayerRunOutOfPlayableUnits
		RemovedFromPlay = Total - OnMap;
		RemainingPlayable = Alive - Incapacitated - RemovedFromPlay;
	}
}

function protected int GetFilteredUnitCount(out array<XComGameState_Unit> Units)
{
	local XComGameState_Unit UnitState;
	local XComWorldData WorldData;
	local Volume TestVolume;
	local int FilteredCount;
	local name TemplateName;
	local XComGameState_Effect TestEffect;
	local XComGameState_Unit Carrier;
	local TTile UnitLocation;

	TestVolume = FindVolume();
	if(CharacterTemplateFilter == "" && TestVolume == none)
	{
		return Units.Length;
	}
	else
	{
		WorldData = `XWORLD;
		TemplateName = name(CharacterTemplateFilter);
		FilteredCount = 0;

		foreach Units(UnitState)
		{
			UnitLocation = UnitState.TileLocation;

			if (TestVolume != none)
			{
				TestEffect = UnitState.GetUnitAffectedByEffectState( class'X2AbilityTemplateManager'.default.BeingCarriedEffectName );
				if (TestEffect != None)
				{
					Carrier = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID( TestEffect.ApplyEffectParameters.SourceStateObjectRef.ObjectID ));
					UnitLocation = Carrier.TileLocation;
				}
			}

			// check if the template filter passes
			if(TemplateName == '' || UnitState.GetMyTemplateName() == TemplateName)
			{
				// check if the volume filter passes
				if(TestVolume == None || TestVolume.EncompassesPoint(WorldData.GetPositionFromTileCoordinates(UnitLocation)))
				{
					// all filters are okay, so add this to the filtered count
					FilteredCount++;
				}
			}
		}

		return FilteredCount;
	}
}

private function Volume FindVolume()
{
	local Volume CheckVolume;
	local name VolumeTagName;

	if(VolumeTag != "")
	{
		VolumeTagName = name(VolumeTag);
		foreach class'WorldInfo'.static.GetWorldInfo().AllActors(class'Volume', CheckVolume)
		{
			if(CheckVolume.Tag == VolumeTagName)
			{
				return CheckVolume;
			}
		}
	}

	return none;
}


function protected XGPlayer GetRequestedPlayer()
{
	local XComTacticalGRI TacticalGRI;
	local XGBattle_SP Battle;
	local XGPlayer RequestedPlayer;

	TacticalGRI = `TACTICALGRI;
	Battle = (TacticalGRI != none)? XGBattle_SP(TacticalGRI.m_kBattle) : none;
	if(Battle != none)
	{
		if(InputLinks[0].bHasImpulse)
		{
			RequestedPlayer = Battle.GetHumanPlayer();
		}
		else if(InputLinks[1].bHasImpulse)
		{
			RequestedPlayer = Battle.GetAIPlayer();
		}
		else
		{
			RequestedPlayer = Battle.GetCivilianPlayer();
		}
	}

	return RequestedPlayer;
}

defaultproperties
{
	ObjName="Get Unit Count"
	ObjCategory="Unit"
	bCallHandler=false;

	bConvertedForReplaySystem=true
	bCanBeUsedForGameplaySequence=true

	InputLinks.Empty;
	InputLinks(0)=(LinkDesc="Human")
	InputLinks(1)=(LinkDesc="Alien")
	InputLinks(2)=(LinkDesc="Civilian")

	VariableLinks.Empty;
	VariableLinks(0)=(ExpectedType=class'SeqVar_Int', LinkDesc="Total", PropertyName=Total, bWriteable=TRUE)
	VariableLinks(1)=(ExpectedType=class'SeqVar_Int', LinkDesc="Alive", PropertyName=Alive, bWriteable=TRUE)
	VariableLinks(2)=(ExpectedType=class'SeqVar_Int', LinkDesc="Dead",  PropertyName=Dead,  bWriteable=TRUE)
	VariableLinks(3)=(ExpectedType=class'SeqVar_Int', LinkDesc="OnMap", PropertyName=OnMap, bWriteable=TRUE)
	VariableLinks(4)=(ExpectedType=class'SeqVar_Int', LinkDesc="Incapacitated",  PropertyName=Incapacitated,  bWriteable=TRUE)
	VariableLinks(5)=(ExpectedType=class'SeqVar_Int', LinkDesc="Confused",  PropertyName=Confused,  bWriteable=TRUE)

	bSkipTurrets=true; 
}
