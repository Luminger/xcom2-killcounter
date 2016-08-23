class X2Action_MindControlled extends X2Action;

var XGUnit          ControlledUnit;
var XComUnitPawn    ControlledPawn;
var name            MindControlledAnim;
var CustomAnimParams            Params;

function Init(const out VisualizationTrack InTrack)
{
	local XComGameStateHistory History;
	local XComGameStateContext_Ability AbilityContext;
	local XComGameState_Unit UnitState;

	super.Init(InTrack);

	History = `XCOMHISTORY;
	AbilityContext = XComGameStateContext_Ability(StateChangeContext);
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.PrimaryTarget.ObjectID));
	ControlledUnit = XGUnit(UnitState.GetVisualizer());
	ControlledPawn = ControlledUnit.GetPawn();
}

function ResetUnitFlag(int ObjectID)
{
	local StateObjectReference kRef;
	kRef.ObjectID = ObjectID;
	`PRES.ResetUnitFlag(kRef);
}

simulated state Executing
{
Begin:
	if(!ControlledUnit.IsTurret())
	{
		while(ControlledUnit.IdleStateMachine.IsEvaluatingStance())
		{
			Sleep(0.0f);
		}
		Params.AnimName = MindControlledAnim;
		FinishAnim(ControlledPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params));
	}

	ResetUnitFlag(ControlledUnit.ObjectID);
	CompleteAction();
}

DefaultProperties
{
	MindControlledAnim="HL_Psi_MindControlled"
}