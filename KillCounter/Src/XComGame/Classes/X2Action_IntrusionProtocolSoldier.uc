//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_IntrusionProtocolSoldier extends X2Action;

//Cached info for the unit performing the action
//*************************************
var XComGameState_Item            GremlinWeapon;

var XComGameStateContext_Ability AbilityContext;
var XComGameState_Unit TargetUnit;
var XComGameState_InteractiveObject ObjectState;
var Actor TargetActor;

var vector                      ToTarget;

var	public	CustomAnimParams	Params;
//*************************************

function Init(const out VisualizationTrack InTrack)
{
	local XComGameStateHistory History;	
	local XComGameState_BaseObject TargetState;
	
	History = `XCOMHISTORY;

	AbilityContext = XComGameStateContext_Ability(StateChangeContext);

	TargetState = History.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID);
	ObjectState = XComGameState_InteractiveObject(TargetState);
	if (ObjectState == none)
	{
		TargetUnit = XComGameState_Unit(TargetState);
		TargetActor = TargetUnit.GetVisualizer();
	}
	else
	{
		TargetActor = ObjectState.GetVisualizer();
	}

	super.Init(InTrack);

	GremlinWeapon = XComGameState_Item(History.GetGameStateForObjectID(AbilityContext.InputContext.ItemObject.ObjectID));

	ToTarget = TargetActor.Location - UnitPawn.Location;
	ToTarget.Z = 0;
	ToTarget = Normal(ToTarget);
}

function bool CheckInterrupted()
{
	return false;
}

simulated state Executing
{
Begin:

	Unit.IdleStateMachine.ForceHeading(ToTarget);
	while(Unit.IdleStateMachine.IsEvaluatingStance())
	{
		Sleep(0.0f);
	}

	Params.AnimName = 'HL_SendGremlin';
	FinishAnim(UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params));

	UnitPawn.m_kGameUnit.IdleStateMachine.PlayIdleAnim();

	VisualizationMgr.SendInterTrackMessage(GremlinWeapon.CosmeticUnitRef);

	CompleteAction();
}

event bool BlocksAbilityActivation()
{
	return false;
}

DefaultProperties
{
}
