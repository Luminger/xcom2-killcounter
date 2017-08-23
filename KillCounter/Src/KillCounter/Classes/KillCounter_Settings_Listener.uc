class KillCounter_Settings_Listener extends UIScreenListener;

event OnInit(UIScreen Screen)
{
    local KillCounter_Settings settings;

    if (MCM_API(Screen) != none || UIShell(Screen) != none)
    {
        settings = new class'KillCounter_Settings';
        settings.OnInit(Screen);
    }
}

defaultproperties
{
    ScreenClass = none;
}