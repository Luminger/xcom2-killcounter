class KillCounter_Settings extends UIScreenListener config(KillCounter);

`include(KillCounter/Src/ModConfigMenuAPI/MCM_API_Includes.uci)
`include(KillCounter/Src/ModConfigMenuAPI/MCM_API_CfgHelpers.uci)

var config bool neverShowEnemyTotal;
var config bool alwaysShowEnemyTotal;
var config bool alwaysShowActiveEnemyCount;
var config bool showRemainingInsteadOfTotal;
var config bool includeTurrets;

var config bool noColor;
var config string textAlignment;
var config int BoxAnchor;
var config int OffsetX;
var config int OffsetY;

var config int CONFIG_VERSION;

var KillCounter_Settings_Defaults defaultSettings;

var MCM_API_Checkbox neverShowEnemyTotal_Checkbox;
var MCM_API_Checkbox alwaysShowEnemyTotal_Checkbox;
var MCM_API_Checkbox alwaysShowActiveEnemyCount_Checkbox;
var MCM_API_Checkbox showRemainingInsteadOfTotal_Checkbox;
var MCM_API_Checkbox includeTurrets_Checkbox;

var MCM_API_Checkbox noColor_Checkbox;
var MCM_API_Dropdown textAlignment_Dropdown;
var MCM_API_Slider BoxAnchor_Slider;
var MCM_API_Slider OffsetX_Slider;
var MCM_API_Slider OffsetY_Slider;


event OnInit(UIScreen Screen)
{
	if (MCM_API(Screen) != none)
	{
		`MCM_API_Register(Screen, ClientModCallback);
	} else if(CONFIG_VERSION == 0) 
	{
		LoadSavedSettings();
		SaveButtonClicked(none);
	}
}

simulated function ClientModCallback(MCM_API_Instance ConfigAPI, int GameMode)
{
    local MCM_API_SettingsPage Page;
    local MCM_API_SettingsGroup Group;

	local array<string> textAlignmentOptions;
    
	textAlignmentOptions.addItem("LEFT");
	textAlignmentOptions.addItem("CENTER");
	textAlignmentOptions.addItem("RIGHT");
	
    LoadSavedSettings();
    
    Page = ConfigAPI.NewSettingsPage("KillCounter");
    Page.SetPageTitle("KillCounter");
    Page.SetSaveHandler(SaveButtonClicked);
	Page.EnableResetButton(ResetButtonClicked);
    
		// ---------------------------- General Settings ----------------------------- //

    Group = Page.AddGroup('Group1', "General Settings");
    
	neverShowEnemyTotal_Checkbox = Group.AddCheckbox('neverShowEnemyTotal', 
		"NeverShowEnemyTotal", 
		"The exact oposit from above - set it to true and you'll get the enemies total always even though you havn't build the ShadowChamber yet. Please note that this outrules the setting from above - this one takes precendence, always.",
		neverShowEnemyTotal,
		neverShowEnemyTotalSaveHandler);

	alwaysShowEnemyTotal_Checkbox = Group.AddCheckbox('alwaysShowEnemyTotal', 
		"AlwaysShowEnemyTotal", 
		"Setting this to true will never show you the total number of enemies in a mission, even when you have access to the ShadowChamber so you already know it.",
		alwaysShowEnemyTotal,
		alwaysShowEnemyTotalSaveHandler);

	alwaysShowActiveEnemyCount_Checkbox = Group.AddCheckbox('alwaysShowActiveEnemyCount', 
		"AlwaysShowActiveEnemyCount", 
		"If set to false, the total active enemy count is never shown.",
		alwaysShowActiveEnemyCount,
		alwaysShowActiveEnemyCountSaveHandler);

	showRemainingInsteadOfTotal_Checkbox = Group.AddCheckbox('showRemainingInsteadOfTotal', 
		"ShowRemainingInsteadOfTotal", 
		"Some people like it this way, some the other. Set it to false and you'll get the total count of enemies, set it to true and you'll get the remaining count.",
		showRemainingInsteadOfTotal,
		showRemainingInsteadOfTotalSaveHandler);

	includeTurrets_Checkbox = Group.AddCheckbox('includeTurrets', 
		"IncludeTurrets", 
		"As turrets don't count into the 'total enemies killed' at the end of the mission, we don't include them here as well by default. If you like, you can enable counting them.",
		includeTurrets,
		includeTurretsSaveHandler);

		// ---------------------------- UI Settings ----------------------------- //

	Group = Page.AddGroup('Group2', "UI Settings");
    
	noColor_Checkbox = Group.AddCheckbox('noColor', 
		"NoColor", 
		"Disable coloring of all numbers.",
		noColor,
		noColorSaveHandler);

	textAlignment_Dropdown = Group.AddDropdown('textAlignment', 
		"TextAlignment", 
		"How the text is aligned witin the 'box'.",
		textAlignmentOptions,
		textAlignment,
		textAlignmentSaveHandler);

	BoxAnchor_Slider = Group.AddSlider('BoxAnchor', 
		"BoxAnchor", 
		"Where the 'box' (which holds the text) is anchored on the screen (the whole screen).\nPossible values (straight from the UIUtilities class):\n0 (ANCHOR_NONE)\n1 (ANCHOR_TOP_LEFT)\n2 (ANCHOR_TOP_CENTER)\n3 (ANCHOR_TOP_RIGHT)\n4 (ANCHOR_MIDDLE_LEFT)\n5 (ANCHOR_MIDDLE_CENTER)\n6 (ANCHOR_MIDDLE_RIGHT)\n7 (ANCHOR_BOTTOM_LEFT)\n8 (ANCHOR_BOTTOM_CENTER)\n9 (ANCHOR_BOTTOM_RIGHT)",
		0,	// Min
		9,	// Max
		1,	// Step
		BoxAnchor,
		BoxAnchorSaveHandler);

	OffsetX_Slider = Group.AddSlider('OffsetX', 
		"OffsetX", 
		"By how much the 'box' should be offset from its anchor on the X axis",
		-1000,
		1000,
		1,
		OffsetX,
		OffsetXSaveHandler);

	OffsetY_Slider = Group.AddSlider('OffsetY', 
		"OffsetY", 
		"By how much the 'box' should be offset from its anchor on the Y axis",
		-1000,
		1000,
		1,
		OffsetY,
		OffsetYSaveHandler);
    
    Page.ShowSettings();
}

`MCM_CH_VersionChecker(class'KillCounter_Settings_Defaults'.default.CONFIG_VERSION,CONFIG_VERSION)

simulated function LoadSavedSettings()
{
    neverShowEnemyTotal = `MCM_CH_GetValue(class'KillCounter_Settings_Defaults'.default.neverShowEnemyTotal, neverShowEnemyTotal);
	alwaysShowEnemyTotal = `MCM_CH_GetValue(class'KillCounter_Settings_Defaults'.default.alwaysShowEnemyTotal, alwaysShowEnemyTotal);
	alwaysShowActiveEnemyCount = `MCM_CH_GetValue(class'KillCounter_Settings_Defaults'.default.alwaysShowActiveEnemyCount, alwaysShowActiveEnemyCount);
	showRemainingInsteadOfTotal = `MCM_CH_GetValue(class'KillCounter_Settings_Defaults'.default.showRemainingInsteadOfTotal, showRemainingInsteadOfTotal);
	includeTurrets = `MCM_CH_GetValue(class'KillCounter_Settings_Defaults'.default.includeTurrets, includeTurrets);

	noColor = `MCM_CH_GetValue(class'KillCounter_Settings_Defaults'.default.noColor, noColor);
	textAlignment = `MCM_CH_GetValue(class'KillCounter_Settings_Defaults'.default.textAlignment, textAlignment);
	BoxAnchor = `MCM_CH_GetValue(class'KillCounter_Settings_Defaults'.default.BoxAnchor, BoxAnchor);
	OffsetX = `MCM_CH_GetValue(class'KillCounter_Settings_Defaults'.default.OffsetX, OffsetX);
	OffsetY = `MCM_CH_GetValue(class'KillCounter_Settings_Defaults'.default.OffsetY, OffsetY);
}

`MCM_API_BasicCheckboxSaveHandler(neverShowEnemyTotalSaveHandler, neverShowEnemyTotal)
`MCM_API_BasicCheckboxSaveHandler(alwaysShowEnemyTotalSaveHandler, alwaysShowEnemyTotal)
`MCM_API_BasicCheckboxSaveHandler(alwaysShowActiveEnemyCountSaveHandler, alwaysShowActiveEnemyCount)
`MCM_API_BasicCheckboxSaveHandler(showRemainingInsteadOfTotalSaveHandler, showRemainingInsteadOfTotal)
`MCM_API_BasicCheckboxSaveHandler(includeTurretsSaveHandler, includeTurrets)

`MCM_API_BasicCheckboxSaveHandler(noColorSaveHandler, noColor)
`MCM_API_BasicDropDownSaveHandler(textAlignmentSaveHandler, textAlignment)
`MCM_API_BasicSliderSaveHandler(BoxAnchorSaveHandler, BoxAnchor)
`MCM_API_BasicSliderSaveHandler(OffsetXSaveHandler, OffsetX)
`MCM_API_BasicSliderSaveHandler(OffsetYSaveHandler, OffsetY)

simulated function SaveButtonClicked(MCM_API_SettingsPage Page)
{
    self.CONFIG_VERSION = `MCM_CH_GetCompositeVersion();
    self.SaveConfig();
}

simulated function ResetButtonClicked(MCM_API_SettingsPage Page)
{
	defaultSettings = new class'KillCounter_Settings_Defaults';

	neverShowEnemyTotal_Checkbox.SetValue(defaultSettings.neverShowEnemyTotal, true);
	alwaysShowEnemyTotal_Checkbox.SetValue(defaultSettings.alwaysShowEnemyTotal, true);
	alwaysShowActiveEnemyCount_Checkbox.SetValue(defaultSettings.alwaysShowActiveEnemyCount, true);
	showRemainingInsteadOfTotal_Checkbox.SetValue(defaultSettings.showRemainingInsteadOfTotal, true);
	includeTurrets_Checkbox.SetValue(defaultSettings.includeTurrets, true);

	noColor_Checkbox.SetValue(defaultSettings.noColor, true);
	textAlignment_Dropdown.SetValue(defaultSettings.textAlignment, true);
	BoxAnchor_Slider.SetValue(defaultSettings.BoxAnchor, true);
	OffsetX_Slider.SetValue(defaultSettings.OffsetX, true);
	OffsetY_Slider.SetValue(defaultSettings.OffsetY, true);
}

defaultproperties
{
    ScreenClass = none;
}