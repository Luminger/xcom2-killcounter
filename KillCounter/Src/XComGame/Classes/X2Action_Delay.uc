//-----------------------------------------------------------
// Used by the visualizer system to control a Visualization Actor
//-----------------------------------------------------------
class X2Action_Delay extends X2Action;

var float Duration; // In seconds

event bool BlocksAbilityActivation()
{
	return false;
}

//------------------------------------------------------------------------------------------------
simulated state Executing
{
	simulated event Tick(float DeltaTime)
	{
		Duration -= DeltaTime;
	}

Begin:
	TimeoutSeconds = Duration + 1.0f;

	while(Duration > 0)
	{
		sleep(0.0);
	}

	CompleteAction();
}

defaultproperties
{

}

