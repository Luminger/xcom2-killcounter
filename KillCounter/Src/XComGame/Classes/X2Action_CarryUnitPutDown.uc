//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_CarryUnitPutDown extends X2Action_CarryUnitPickUp;

simulated state Executing
{
Begin:
	UnitPawn.EnableRMA(true, true);
	UnitPawn.EnableRMAInteractPhysics(true);

	UnitPawn.CarryingUnit = None;
	UnitPawn.HideAllAttachments(false);

	Params.AnimName = 'ShutDownAdditive';
	Params.TargetWeight = 0.0f;
	UnitPawn.GetAnimTreeController().PlayAdditiveDynamicAnim(Params);

	Params = default.Params;
	AnimName = "HL_CarryBodyStop";
	Params.AnimName = AppendMaleFemaleToAnim(AnimName);
	FinishAnim(UnitPawn.GetAnimTreeController().PlayFullBodyDynamicAnim(Params));

	if( AbilityContext.InputContext.PrimaryTarget.ObjectID > 0 )
	{
		VisualizationMgr.SendInterTrackMessage(AbilityContext.InputContext.PrimaryTarget);
	}

	UnitPawn.UpdateAnimations();

	CompleteAction();
}

DefaultProperties
{
}
