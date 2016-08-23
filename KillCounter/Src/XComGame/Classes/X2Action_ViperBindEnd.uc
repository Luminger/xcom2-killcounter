//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_ViperBindEnd extends X2Action;

var StateObjectReference                    PartnerUnitRef;

//Cached info for performing the action
//*************************************
var private CustomAnimParams				Params;//, PartnerParams;
var private XComGameState_Unit				UnitState, PartnerUnitState;
var private Vector							DesiredLocation;
var private Actor				            PartnerVisualizer;
var private XComUnitPawn		            PartnerUnitPawn;
var private bool                            bUnitIsAlive, bPartnerIsAlive;
var private AnimNodeSequence	            UnitAnimSeq, PartnerAnimSeq;
//*************************************

function Init(const out VisualizationTrack InTrack)
{
	local XComGameStateHistory History;

	super.Init(InTrack);

	History = `XCOMHISTORY;

	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(Unit.ObjectID));

	`assert(PartnerUnitRef.ObjectID != 0);

	PartnerUnitState = XComGameState_Unit(History.GetGameStateForObjectID(PartnerUnitRef.ObjectID));
	PartnerVisualizer = PartnerUnitState.GetVisualizer();
	PartnerUnitPawn = XGUnit(PartnerVisualizer).GetPawn();

	bUnitIsAlive = UnitState.IsAlive();
	bPartnerIsAlive = PartnerUnitState.IsAlive();
}

simulated state Executing
{
	function AnimNodeSequence EndBind(XComGameState_Unit PlayOnGameStateUnit, XGUnit PlayOnUnit, XComUnitPawn PlayOnPawn)
	{
		PlayOnPawn.EnableRMA(true,true);
		PlayOnPawn.EnableRMAInteractPhysics(true);

		Params.AnimName = 'NO_BindStop';
		Params.HasDesiredEndingAtom = true;
		DesiredLocation = `XWORLD.GetPositionFromTileCoordinates(PlayOnGameStateUnit.TileLocation);
	
		// Set Z so our feet are on the ground
		DesiredLocation.Z = PlayOnUnit.GetDesiredZForLocation(DesiredLocation);
		Params.DesiredEndingAtom.Translation = DesiredLocation;
		Params.DesiredEndingAtom.Rotation = QuatFromRotator(PlayOnPawn.Rotation);
		Params.DesiredEndingAtom.Scale = 1.0f;

		PlayOnUnit.IdleStateMachine.PersistentEffectIdleName = '';
		PlayOnPawn.GetAnimTreeController().SetAllowNewAnimations(true);
		return PlayOnPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params);
	}

Begin:

	if( bUnitIsAlive )
	{
		UnitAnimSeq = EndBind(UnitState, Unit, UnitPawn);
	}

	if( bPartnerIsAlive )
	{
		PartnerAnimSeq = EndBind(PartnerUnitState, XGUnit(PartnerVisualizer), PartnerUnitPawn);
	}

	FinishAnim(UnitAnimSeq);
	FinishAnim(PartnerAnimSeq);
	
	UnitPawn.bSkipIK = false;
	PartnerUnitPawn.bSkipIK = false;

	if( PartnerUnitRef.ObjectID != 0 )
	{
		VisualizationMgr.SendInterTrackMessage(PartnerUnitRef);
	}

	CompleteAction();
}