//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIOptionsPCScreen
//  AUTHOR:  Brit Steiner       -- 01/31/12
//           Tronster           -- 04/10/12
//  PURPOSE: Controls the game side of the Options screen. (No longer PC only, rename? - 2.6.12)
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 

class UIOptionsPCScreen extends UIScreen
	config(UI)
	native(UI)
	dependson(UIDialogueBox);

//Stores the video settings at the time the screen initializes, fo ruse when exiting without changes. 
struct native TUIOptionsInitVideoSettings
{
	var bool bMouseLock;
	var bool bFRSmoothing;
};

enum EFXSFXAAType
{
	FXSAA_Off<DisplayName = Off>,
	FXSAA_FXAA0<DisplayName = FXAA0>,	// NVIDIA 1 pass LQ PS3 and Xbox360 specific optimizations
	FXSAA_FXAA1<DisplayName = FXAA1>,	// NVIDIA 1 pass LQ
	FXSAA_FXAA2<DisplayName = FXAA2>,	// NVIDIA 1 pass LQ
	FXSAA_FXAA3<DisplayName = FXAA3>,	// NVIDIA 1 pass HQ
	FXSAA_FXAA4<DisplayName = FXAA4>,	// NVIDIA 1 pass HQ
	FXSAA_FXAA5<DisplayName = FXAA5>,	// NVIDIA 1 pass HQ
};

var UINavigationHelp NavHelp;

var TUIOptionsInitVideoSettings m_kInitVideoSettings; 

// Masks are defined in default properties
var array<byte> PerSettingMasks;

var localized string m_strTitle; 
var localized string m_strCreditsLink; 
var localized string m_strExitAndSaveSettings;
var localized string m_strResetAllSettings;
var localized string m_strIgnoreChangesDialogue;
var localized string m_strIgnoreChangesConfirm;
var localized string m_strIgnoreChangesCancel;
var localized string m_strWantToResetToDefaults; 
var localized string m_strSoldiersLanguageHint;

var localized string m_strTabVideo; 
var localized string m_strTabGraphics; 
var localized string m_strTabAudio; 
var localized string m_strTabGameplay; 
var localized string m_strTabInterface; 


var bool                bInputReceived;
var bool                m_bAllowCredits; 
var string              m_strHelp_MouseNav_Accept;
var string              m_strHelp_MouseNav_Cancel;

// Graphics settings - re-usable across various graphics options
// =========================================================
var localized string m_strGraphicsSetting_Minimal;
var localized string m_strGraphicsSetting_Low;
var localized string m_strGraphicsSetting_Medium;
var localized string m_strGraphicsSetting_High;
var localized string m_strGraphicsSetting_Maximum;
var localized string m_strGraphicsSetting_Custom;
var localized string m_strGraphicsSetting_Disabled;

var localized string m_strShadowSetting_DirectionalOnly;
var localized string m_strShadowSetting_StaticOnly;
var localized string m_strShadowSetting_AllShadows;
var localized string m_strGraphicSetting_Bilinear;
var localized string m_strGraphicSetting_Trilinear;
var localized string m_strGraphicSetting_Aniso2X;
var localized string m_strGraphicSetting_Aniso4X;
var localized string m_strGraphicSetting_Aniso8X;
var localized string m_strGraphicSetting_Aniso16X;
var localized string m_str_AASetting_FXAA;
var localized string m_str_AASetting_MSAA_2X;
var localized string m_str_AASetting_MSAA_4X;
var localized string m_str_AASetting_MSAA_8X;
var localized string m_str_AO_TiledAO;
var localized string m_str_AO_SSAO;
var localized string m_str_DecalSetting_SomeStatic;
var localized string m_str_DecalSetting_AllStatic;
var localized string m_str_DecalSetting_All;
var localized string m_str_DOFSetting_Simple;
var localized string m_str_DOFSetting_Bokeh;

var localized string m_strVideoKeepSettings_Title;
var localized string m_strVideoKeepSettings_Body;
var localized string m_strVideoKeepSettings_Confirm;

var int m_KeepResolutionCountdown;
var bool m_bPendingExit;

const GAMMA_HIGH = 2.7;
const GAMMA_LOW = 1.7;

var transient int ModeSpinnerVal;
var array<string> m_VideoMode_Labels;

var array<string> m_DefaultGraphicsSettingLabels;

var array<string> m_kGameResolutionStrings;
var array<int> m_kGameResolutionWidths;
var array<int> m_kGameResolutionHeights;
var int m_kCurrentSupportedResolutionIndex;

enum EUI_PCOptions_Graphics
{
	ePCGraphics_Preset,

	// Spinners
	ePCGraphics_AntiAliasing,
	ePCGraphics_AmbientOcclusion,
	ePCGraphics_Decals,
	ePCGraphics_Shadow,
	ePCGraphics_ShadowQuality,
	ePCGraphics_TextureDetail,
	ePCGraphics_TextureFiltering,
	ePCGraphics_DepthOfField,
	ePCGraphics_MaxDrawDistance,

	// CheckBoxes
	ePCGraphics_Effects,
	ePCGraphics_Bloom,	
	ePCGraphics_DirtyLens,	
	ePCGraphics_SubsurfaceScattering,
	ePCGraphics_ScreenSpaceReflections,
};

enum EUI_PCOptions_GraphicsSettings
{
	eGraphicsSetting_Disabled,
	eGraphicsSetting_Minimal,
	eGraphicsSetting_Low,
	eGraphicsSetting_Medium,
	eGraphicsSetting_High,
	eGraphicsSetting_Maximum,
	eGraphicsSetting_Custom,

	eGraphicsSetting_DirectionalOnly,
	eGraphicsSetting_StaticOnly,
	eGraphicsSetting_All,

	eGraphicsSetting_FXAA,
	eGraphicsSetting_MSAA_2X,
	eGraphicsSetting_MSAA_4X,
	eGraphicsSetting_MSAA_8X,

	eGraphicsSetting_TiledAO,
	eGraphicsSetting_SSAO,

	eGraphicsSetting_Bilinear,
	eGraphicsSetting_Trilinear,
	eGraphicsSetting_Aniso_2X,
	eGraphicsSetting_Aniso_4X,
	eGraphicsSetting_Aniso_8X,
	eGraphicsSetting_Aniso_16X,

	eGraphicsSetting_On,
	eGraphicsSetting_Off,

	eGraphicsSetting_SimpleDOF,
	eGraphicsSetting_BokehDOF
};

struct native TUIGraphicsOptionSettingConfig
{
	var string Label;
	var byte Order;

	var bool bSpinner;

	var array<EUI_PCOptions_GraphicsSettings> Values;
	var array<byte> Presets;

	var array<string> Labels;
};

const NumGraphicsOptions = 15;
const NUM_LISTITEMS = 16;
var TUIGraphicsOptionSettingConfig GraphicsOptions[NumGraphicsOptions];
var byte GraphicsVals[NumGraphicsOptions];

//Stores the video settings at the time the screen initializes, for use when exiting without changes. 
struct native TUIGraphicsOptionsInitSettings
{
	// standard settings
	var int iMode;
	var int iResolutionWidth;
	var int iResolutionHeight;
	var bool bVSync;
	var float fGamma;

	// advanced settings
	var int GraphicsVals[NumGraphicsOptions];
};

var TUIGraphicsOptionsInitSettings m_kInitGraphicsSettings;

// =========================================================

var localized string m_strVideoLabel_Mode;
var localized string m_strVideoLabel_Fullscreen;
var localized string m_strVideoLabel_Windowed;
var localized string m_strVideoLabel_BorderlessWindow;
var localized string m_strVideoLabel_Resolution;
var localized string m_strVideoLabel_Gamma;
var localized string m_strVideoLabel_GammaDirections;
var localized string m_strVideoLabel_VSyncToggle;
var localized string m_strVideolabel_MouseLock;
var localized string m_strVideoLabel_FRSmoothingToggle;

var localized string m_strGraphicsLabel_Preset;
var localized string m_strGraphicsLabel_Shadow;
var localized string m_strGraphicsLabel_ShadowQuality;
var localized string m_strGraphicsLabel_TextureFiltering;
var localized string m_strGraphicsLabel_TextureDetail;
var localized string m_strGraphicsLabel_AntiAliasing;
var localized string m_strGraphicsLabel_AmbientOcclusion;
var localized string m_strGraphicsLabel_Effects;
var localized string m_strGraphicsLabel_Bloom;
var localized string m_strGraphicsLabel_DepthOfField;
var localized string m_strGraphicsLabel_DirtyLens;
var localized string m_strGraphicsLabel_Decals;
var localized string m_strGraphicsLabel_SubsurfaceScattering;
var localized string m_strGraphicsLabel_ScreenSpaceReflections;
var localized string m_strGraphicsLabel_HighPrecisionGBuffers;
var localized string m_strGraphicsLabel_MaxDrawDistance;

var localized string m_strAudioLabel_MasterVolume;
var localized string m_strAudioLabel_SpeakerPreset;
var localized string m_strAudioLabel_VoiceVolume;
var localized string m_strAudioLabel_SoundEffectVolume;
var localized string m_strAudioLabel_VOIPVolume;
var localized string m_strAudioLabel_VOIPPushToTalk;
var localized string m_strAudioLabel_MusicVolume;
var localized string m_strAudioLabel_EnableSoldierSpeech;
var localized string m_strAudioLabel_ForeignLanguages;
var localized string m_strAudioLabel_AmbientVO;

var localized string m_strGameplayLabel_GlamCam;
var localized string m_strGameplayLabel_ThirdPersonCamera;
var localized string m_strGameplayLabel_StrategyAutosaveFrequency;
var localized string m_strGameplayLabel_TacticalAutosaveFrequency;
var localized string m_strGameplayLabel_AutosaveToggle;
var localized string m_strGameplayLabel_AutosaveOnReturnFromTactical;
var localized string m_strGameplayLabel_ShowEnemyHealth;
var localized string m_strGameplayLabel_UnitMoveSpeed;

var localized string m_strInterfaceLabel_DefaultCameraZoom;
var localized string m_strInterfaceLabel_ShowHealthBars;
var localized string m_strInterfaceLabel_ShowSubtitles;
var localized string m_strInterfaceLabel_EdgescrollSpeed;
var localized string m_strInterfaceLabel_InputDevice;
var localized string m_strInterfaceLabel_Controller;
var localized string m_strInterfaceLabel_Mouse;
var localized string m_strInterfaceLabel_KeyBindings;
var localized string m_strInterfaceLabel_BindingsButton;

var localized string m_strVideoLabel_Mode_Desc;
var localized string m_strVideoLabel_Fullscreen_Desc;
var localized string m_strVideoLabel_Windowed_Desc;
var localized string m_strVideoLabel_BorderlessWindow_Desc;
var localized string m_strVideoLabel_Resolution_Desc;
var localized string m_strVideoLabel_Gamma_Desc;
var localized string m_strVideoLabel_GammaDirections_Desc;
var localized string m_strVideoLabel_VSyncToggle_Desc;
var localized string m_strVideolabel_MouseLock_Desc;
var localized string m_strVideoLabel_FRSmoothingToggle_Desc;

var localized string m_strGraphicsLabel_Preset_Desc;
var localized string m_strGraphicsLabel_Shadow_Desc;
var localized string m_strGraphicsLabel_ShadowQuality_Desc;
var localized string m_strGraphicsLabel_TextureFiltering_Desc;
var localized string m_strGraphicsLabel_TextureDetail_Desc;
var localized string m_strGraphicsLabel_AntiAliasing_Desc;
var localized string m_strGraphicsLabel_AmbientOcclusion_Desc;
var localized string m_strGraphicsLabel_Effects_Desc;
var localized string m_strGraphicsLabel_Bloom_Desc;
var localized string m_strGraphicsLabel_DepthOfField_Desc;
var localized string m_strGraphicsLabel_DirtyLens_Desc;
var localized string m_strGraphicsLabel_Decals_Desc;
var localized string m_strGraphicsLabel_SubsurfaceScattering_Desc;
var localized string m_strGraphicsLabel_ScreenSpaceReflections_Desc;
var localized string m_strGraphicsLabel_HighPrecisionGBuffers_Desc;

var localized string m_strAudioLabel_MasterVolume_Desc;
var localized string m_strAudioLabel_SpeakerPreset_Desc;
var localized string m_strAudioLabel_VoiceVolume_Desc;
var localized string m_strAudioLabel_SoundEffectVolume_Desc;
var localized string m_strAudioLabel_VOIPVolume_Desc;
var localized string m_strAudioLabel_VOIPPushToTalk_Desc;
var localized string m_strAudioLabel_MusicVolume_Desc;
var localized string m_strAudioLabel_EnableSoldierSpeech_Desc;
var localized string m_strAudioLabel_ForeignLanguages_Desc;
var localized string m_strAudioLabel_AmbientVO_Desc;

var localized string m_strGameplayLabel_GlamCam_Desc;
var localized string m_strGameplayLabel_ThirdPersonCamera_Desc;
var localized string m_strGameplayLabel_StrategyAutosaveFrequency_Desc;
var localized string m_strGameplayLabel_TacticalAutosaveFrequency_Desc;
var localized string m_strGameplayLabel_AutosaveToggle_Desc;
var localized string m_strGameplayLabel_AutosaveOnReturnFromTactical_Desc;
var localized string m_strGameplayLabel_ShowEnemyHealth_Desc;
var localized string m_strGameplayLabel_UnitMoveSpeed_Desc;

var localized string m_strInterfaceLabel_DefaultCameraZoom_Desc;
var localized string m_strInterfaceLabel_ShowHealthBars_Desc;
var localized string m_strInterfaceLabel_ShowSubtitles_Desc;
var localized string m_strInterfaceLabel_EdgescrollSpeed_Desc;
var localized string m_strInterfaceLabel_InputDevice_Desc;
var localized string m_strInterfaceLabel_Controller_Desc;
var localized string m_strInterfaceLabel_Mouse_Desc;
var localized string m_strInterfaceLabel_KeyBindings_Desc;
var localized string m_strInterfaceLabel_BindingsButton_Desc;

var localized string m_strSavingOptionsFailed;
var localized string m_strSavingOptionsFailed360;

var localized string m_strGPUAutoDetect;
var localized string m_strSaveAndExit;
var localized string m_strRestoreSettings;

var UIList List;
var array<UIMechaListItem> m_arrMechaItems; 
var int m_iCurrentTab;

var bool m_bAnyValueChanged; // jboswell: Every option must set this to true if they want to be saved
var bool m_GEngineValueChanged;
var bool m_SystemSettingsChanged;
var bool m_bResolutionChanged;
var bool m_bGammaChanged;
var bool m_bSavingInProgress;
var bool m_bApplyingPreset;

var XComOnlineProfileSettings m_kProfileSettings;
var UIButton	GPUAutoDetectButton;
var UIButton	SaveAndExitButton;
var UIButton	ExitWitoutChangesButton;
var UIButton	CreditsButton;

enum EUI_PCOptions_Tabs
{
	ePCTab_Audio,
	ePCTab_Video,
	ePCTab_Graphics,
	ePCTab_Gameplay,
	ePCTab_Interface
};

enum EUI_PCOptions_Video
{
	ePCTabVideo_Mode,
	ePCTabVideo_Resolution,
	ePCTabVideo_Gamma,
	ePCTabVideo_MouseLock,
	ePCTabVideo_VSync,
	ePCTabVideo_FRSmoothing,
};

enum EUI_PCOptions_Audio
{
	ePCTabAudio_MasterVolume,
	ePCTabAudio_VoiceVolume,
	ePCTabAudio_SoundEffectsVolume,
	ePCTabAudio_MusicVolume,
	ePCTabAudio_VOIPVolume,
	ePCTabAudio_VOIPPushToTalk,
	ePCTabAudio_EnableSoldierSpeech,
	ePCTabAudio_ForeignLanguages,
	ePCTabAudio_EnableAmbientVO,
};
enum EUI_PCOptions_Gameplay
{
	ePCTabGameplay_GlamCam,
//	ePCTabGameplay_AutosaveFreqStrategy,
//	ePCTabGameplay_AutosaveFreqTactical,
	ePCTabGameplay_AutosaveMaster,
//  ePCTabGameplay_AutosaveOnReturnFromTactical,
	ePCTabGameplay_ShowEnemyHealth,
	ePCTabGameplay_UnitMoveSpeed,
};
enum EUI_PCOptions_Interface
{
	//ePCTabInterface_InputDevice,
	ePCTabInterface_KeyBindings,
	//ePCTabInterface_HealthBars,
	ePCTabInterface_Subtitles,
	ePCTabInterface_EdgeScroll,
};

simulated function TUIGraphicsOptionSettingConfig GetPresetConfig()
{
	local TUIGraphicsOptionSettingConfig Config;

	Config.Label = m_strGraphicsLabel_Preset;
	Config.Order = ePCGraphics_Preset;
	Config.bSpinner = true;

	Config.Values.AddItem(eGraphicsSetting_Minimal);
	Config.Values.AddItem(eGraphicsSetting_Low);
	Config.Values.AddItem(eGraphicsSetting_Medium);
	Config.Values.AddItem(eGraphicsSetting_High);
	Config.Values.AddItem(eGraphicsSetting_Maximum);

	Config.Presets.AddItem(0);
	Config.Presets.AddItem(1);
	Config.Presets.AddItem(2);
	Config.Presets.AddItem(3);
	Config.Presets.AddItem(4);

	Config.Labels.AddItem(m_strGraphicsSetting_Minimal);
	Config.Labels.AddItem(m_strGraphicsSetting_Low);
	Config.Labels.AddItem(m_strGraphicsSetting_Medium);
	Config.Labels.AddItem(m_strGraphicsSetting_High);
	Config.Labels.AddItem(m_strGraphicsSetting_Maximum);

	return Config;
}

simulated function TUIGraphicsOptionSettingConfig GetAmbientOcclusionConfig()
{
	local TUIGraphicsOptionSettingConfig Config;

	Config.Label = m_strGraphicsLabel_AmbientOcclusion;
	Config.Order = ePCGraphics_AmbientOcclusion;
	Config.bSpinner = true;

	Config.Values.AddItem(eGraphicsSetting_Disabled);
	Config.Values.AddItem(eGraphicsSetting_TiledAO);
	Config.Values.AddItem(eGraphicsSetting_SSAO);

	Config.Presets.AddItem(0);
	Config.Presets.AddItem(1);
	Config.Presets.AddItem(1);
	Config.Presets.AddItem(2);
	Config.Presets.AddItem(2);

	Config.Labels.AddItem(m_strGraphicsSetting_Disabled);
	Config.Labels.AddItem(m_str_AO_TiledAO);
	Config.Labels.AddItem(m_str_AO_SSAO);

	return Config;
}

simulated function TUIGraphicsOptionSettingConfig GetAntiAliasingConfig()
{
	local TUIGraphicsOptionSettingConfig Config;

	Config.Label = m_strGraphicsLabel_AntiAliasing;
	Config.Order = ePCGraphics_AntiAliasing;
	Config.bSpinner = true;

	Config.Values.AddItem(eGraphicsSetting_Disabled);
	Config.Values.AddItem(eGraphicsSetting_FXAA);
	Config.Values.AddItem(eGraphicsSetting_MSAA_2X);
	Config.Values.AddItem(eGraphicsSetting_MSAA_4X);
	Config.Values.AddItem(eGraphicsSetting_MSAA_8X);

	Config.Presets.AddItem(0);
	Config.Presets.AddItem(0);
	Config.Presets.AddItem(1);
	Config.Presets.AddItem(1);
	Config.Presets.AddItem(4);

	Config.Labels.AddItem(m_strGraphicsSetting_Disabled);
	Config.Labels.AddItem(m_str_AASetting_FXAA);
	Config.Labels.AddItem(m_str_AASetting_MSAA_2X);
	Config.Labels.AddItem(m_str_AASetting_MSAA_4X);
	Config.Labels.AddItem(m_str_AASetting_MSAA_8X);

	return Config;
}

simulated function TUIGraphicsOptionSettingConfig GetShadowConfig()
{
	local TUIGraphicsOptionSettingConfig Config;

	Config.Label = m_strGraphicsLabel_Shadow;
	Config.Order = ePCGraphics_Shadow;
	Config.bSpinner = true;

	Config.Values.AddItem(eGraphicsSetting_DirectionalOnly);
	Config.Values.AddItem(eGraphicsSetting_StaticOnly);
	Config.Values.AddItem(eGraphicsSetting_All);

	Config.Presets.AddItem(0);
	Config.Presets.AddItem(1);
	Config.Presets.AddItem(2);
	Config.Presets.AddItem(2);
	Config.Presets.AddItem(2);

	Config.Labels.AddItem(m_strShadowSetting_DirectionalOnly);
	Config.Labels.AddItem(m_strShadowSetting_StaticOnly);
	Config.Labels.AddItem(m_strShadowSetting_AllShadows);

	return Config;
}

simulated function TUIGraphicsOptionSettingConfig GetShadowQualityConfig()
{
	local TUIGraphicsOptionSettingConfig Config;

	Config.Label = m_strGraphicsLabel_ShadowQuality;
	Config.Order = ePCGraphics_ShadowQuality;
	Config.bSpinner = true;

	Config.Values.AddItem(eGraphicsSetting_Low);
	Config.Values.AddItem(eGraphicsSetting_Medium);
	Config.Values.AddItem(eGraphicsSetting_High);
	Config.Values.AddItem(eGraphicsSetting_Maximum);

	Config.Presets.AddItem(0);
	Config.Presets.AddItem(0);
	Config.Presets.AddItem(1);
	Config.Presets.AddItem(2);
	Config.Presets.AddItem(3);

	Config.Labels.AddItem(m_strGraphicsSetting_Low);
	Config.Labels.AddItem(m_strGraphicsSetting_Medium);
	Config.Labels.AddItem(m_strGraphicsSetting_High);
	Config.Labels.AddItem(m_strGraphicsSetting_Maximum);

	return Config;
}

simulated function TUIGraphicsOptionSettingConfig GetTextureDetailConfig()
{
	local TUIGraphicsOptionSettingConfig Config;

	Config.Label = m_strGraphicsLabel_TextureDetail;
	Config.Order = ePCGraphics_TextureDetail;
	Config.bSpinner = true;

	Config.Values.AddItem(eGraphicsSetting_Low);
	Config.Values.AddItem(eGraphicsSetting_Medium);
	Config.Values.AddItem(eGraphicsSetting_High);
	Config.Values.AddItem(eGraphicsSetting_Maximum);

	Config.Presets.AddItem(0);
	Config.Presets.AddItem(0);
	Config.Presets.AddItem(1);
	Config.Presets.AddItem(2);
	Config.Presets.AddItem(3);

	Config.Labels.AddItem(m_strGraphicsSetting_Low);
	Config.Labels.AddItem(m_strGraphicsSetting_Medium);
	Config.Labels.AddItem(m_strGraphicsSetting_High);
	Config.Labels.AddItem(m_strGraphicsSetting_Maximum);

	return Config;
}

simulated function TUIGraphicsOptionSettingConfig GetTextureFilteringConfig()
{
	local TUIGraphicsOptionSettingConfig Config;

	Config.Label = m_strGraphicsLabel_TextureFiltering;
	Config.Order = ePCGraphics_TextureFiltering;
	Config.bSpinner = true;

	Config.Values.AddItem(eGraphicsSetting_Bilinear);
	Config.Values.AddItem(eGraphicsSetting_Trilinear);
	Config.Values.AddItem(eGraphicsSetting_Aniso_2X);
	Config.Values.AddItem(eGraphicsSetting_Aniso_4X);
	Config.Values.AddItem(eGraphicsSetting_Aniso_8X);
	Config.Values.AddItem(eGraphicsSetting_Aniso_16X);

	Config.Presets.AddItem(0);
	Config.Presets.AddItem(1);
	Config.Presets.AddItem(2);
	Config.Presets.AddItem(4);
	Config.Presets.AddItem(5);

	Config.Labels.AddItem(m_strGraphicSetting_Bilinear);
	Config.Labels.AddItem(m_strGraphicSetting_Trilinear);
	Config.Labels.AddItem(m_strGraphicSetting_Aniso2X);
	Config.Labels.AddItem(m_strGraphicSetting_Aniso4X);
	Config.Labels.AddItem(m_strGraphicSetting_Aniso8X);
	Config.Labels.AddItem(m_strGraphicSetting_Aniso16X);

	return Config;
}

simulated function TUIGraphicsOptionSettingConfig GetDecalsConfig()
{
	local TUIGraphicsOptionSettingConfig Config;

	Config.Label = m_strGraphicsLabel_Decals;
	Config.Order = ePCGraphics_Decals;
	Config.bSpinner = true;

	Config.Values.AddItem(eGraphicsSetting_Low);
	Config.Values.AddItem(eGraphicsSetting_Medium);
	Config.Values.AddItem(eGraphicsSetting_High);

	Config.Presets.AddItem(0);
	Config.Presets.AddItem(1);
	Config.Presets.AddItem(2);
	Config.Presets.AddItem(2);
	Config.Presets.AddItem(2);

	Config.Labels.AddItem(m_str_DecalSetting_SomeStatic);
	Config.Labels.AddItem(m_str_DecalSetting_AllStatic);
	Config.Labels.AddItem(m_str_DecalSetting_All);

	return Config;
}

simulated function TUIGraphicsOptionSettingConfig GetEffectsConfig()
{
	local TUIGraphicsOptionSettingConfig Config;

	Config.Label = m_strGraphicsLabel_Effects;
	Config.Order = ePCGraphics_Effects;
	Config.bSpinner = false;
		
	Config.Values.AddItem(eGraphicsSetting_Off);
	Config.Values.AddItem(eGraphicsSetting_On);

	Config.Presets.AddItem(0);
	Config.Presets.AddItem(0);
	Config.Presets.AddItem(0);
	Config.Presets.AddItem(1);
	Config.Presets.AddItem(1);

	return Config;
}

simulated function TUIGraphicsOptionSettingConfig GetBloomConfig()
{
	local TUIGraphicsOptionSettingConfig Config;

	Config.Label = m_strGraphicsLabel_Bloom;
	Config.Order = ePCGraphics_Bloom;
	Config.bSpinner = false;
		
	Config.Values.AddItem(eGraphicsSetting_Off);
	Config.Values.AddItem(eGraphicsSetting_On);

	Config.Presets.AddItem(0);
	Config.Presets.AddItem(0);
	Config.Presets.AddItem(1);
	Config.Presets.AddItem(1);
	Config.Presets.AddItem(1);

	return Config;
}

simulated function TUIGraphicsOptionSettingConfig GetDirtyLensConfig()
{
	local TUIGraphicsOptionSettingConfig Config;

	Config.Label = m_strGraphicsLabel_DirtyLens;
	Config.Order = ePCGraphics_DirtyLens;
	Config.bSpinner = false;

	Config.Values.AddItem(eGraphicsSetting_Off);
	Config.Values.AddItem(eGraphicsSetting_On);

	Config.Presets.AddItem(0);
	Config.Presets.AddItem(0);
	Config.Presets.AddItem(1);
	Config.Presets.AddItem(1);
	Config.Presets.AddItem(1);

	return Config;
}

simulated function TUIGraphicsOptionSettingConfig GetDepthOfFieldConfig()
{
	local TUIGraphicsOptionSettingConfig Config;

	Config.Label = m_strGraphicsLabel_DepthOfField;
	Config.Order = ePCGraphics_DepthOfField;
	Config.bSpinner = true;

	Config.Values.AddItem(eGraphicsSetting_Disabled);
	Config.Values.AddItem(eGraphicsSetting_SimpleDOF);
	Config.Values.AddItem(eGraphicsSetting_BokehDOF);

	Config.Presets.AddItem(0);
	Config.Presets.AddItem(0);
	Config.Presets.AddItem(1);
	Config.Presets.AddItem(2);
	Config.Presets.AddItem(2);

	Config.Labels.AddItem(m_strGraphicsSetting_Disabled);
	Config.Labels.AddItem(m_str_DOFSetting_Simple);
	Config.Labels.AddItem(m_str_DOFSetting_Bokeh);

	return Config;
}

simulated function TUIGraphicsOptionSettingConfig GetSubsurfaceScatteringConfig()
{
	local TUIGraphicsOptionSettingConfig Config;

	Config.Label = m_strGraphicsLabel_SubsurfaceScattering;
	Config.Order = ePCGraphics_SubsurfaceScattering;
	Config.bSpinner = false;
		
	Config.Values.AddItem(eGraphicsSetting_Off);
	Config.Values.AddItem(eGraphicsSetting_On);

	Config.Presets.AddItem(0);
	Config.Presets.AddItem(0);
	Config.Presets.AddItem(0);
	Config.Presets.AddItem(1);
	Config.Presets.AddItem(1);

	return Config;
}

simulated function TUIGraphicsOptionSettingConfig GetScreenSpaceReflectionsConfig()
{
	local TUIGraphicsOptionSettingConfig Config;

	Config.Label = m_strGraphicsLabel_ScreenSpaceReflections;
	Config.Order = ePCGraphics_ScreenSpaceReflections;
	Config.bSpinner = false;

	Config.Values.AddItem(eGraphicsSetting_Off);
	Config.Values.AddItem(eGraphicsSetting_On);

	Config.Presets.AddItem(0);
	Config.Presets.AddItem(0);
	Config.Presets.AddItem(0);
	Config.Presets.AddItem(1);
	Config.Presets.AddItem(1);

	return Config;
}

simulated function TUIGraphicsOptionSettingConfig GetMaxDrawDistanceConfig()
{
	local TUIGraphicsOptionSettingConfig Config;

	Config.Label = m_strGraphicsLabel_MaxDrawDistance;
	Config.Order = ePCGraphics_MaxDrawDistance;
	Config.bSpinner = true;

	Config.Values.AddItem(eGraphicsSetting_Low);
	Config.Values.AddItem(eGraphicsSetting_Medium);
	Config.Values.AddItem(eGraphicsSetting_High);

	Config.Presets.AddItem(0);
	Config.Presets.AddItem(0);
	Config.Presets.AddItem(1);
	Config.Presets.AddItem(2);
	Config.Presets.AddItem(2);

	Config.Labels.AddItem(m_strGraphicsSetting_Low);
	Config.Labels.AddItem(m_strGraphicsSetting_Medium);
	Config.Labels.AddItem(m_strGraphicsSetting_High);

	return Config;
}

simulated native function bool GetIsBorderlessWindow();
simulated native function SetSupportedResolutionsNative(bool bBorderlessWindow);
simulated native function UpdateViewportNative(INT ScreenWidth, INT ScreenHeight, BOOL Fullscreen, INT BorderlessWindow);
simulated native function bool GetCurrentVSync();
simulated native function UpdateVSyncNative(bool bUseVSync);
simulated public native function float GetGammaPercentageNative();
simulated public native function UpdateGammaNative(float UpdateGamma);
simulated native function SaveGamma();
simulated native function SaveSystemSettings();
simulated native function InitNewSysSettings();
simulated native function ApplyNewSysSettings();

// Determine graphics quality settings from system settings
simulated native function EUI_PCOptions_GraphicsSettings GetCurrentShadowSetting();
simulated native function EUI_PCOptions_GraphicsSettings GetCurrentShadowQualitySetting();
simulated native function EUI_PCOptions_GraphicsSettings GetCurrentTextureFilteringSetting();
simulated native function EUI_PCOptions_GraphicsSettings GetCurrentTextureDetailSetting();
simulated native function EUI_PCOptions_GraphicsSettings GetCurrentAntiAliasingSetting();
simulated native function EUI_PCOptions_GraphicsSettings GetCurrentAmbientOcclusionSetting();
simulated native function EUI_PCOptions_GraphicsSettings GetCurrentMaxDrawDistanceSetting();

simulated native function EUI_PCOptions_GraphicsSettings GetCurrentEffectsSetting();
simulated native function EUI_PCOptions_GraphicsSettings GetCurrentBloomSetting();
simulated native function EUI_PCOptions_GraphicsSettings GetCurrentDepthOfFieldSetting();
simulated native function EUI_PCOptions_GraphicsSettings GetCurrentDirtyLensSetting();
simulated native function EUI_PCOptions_GraphicsSettings GetCurrentDecalsSetting();
simulated native function EUI_PCOptions_GraphicsSettings GetCurrentSubsurfaceScatteringSetting();
simulated native function EUI_PCOptions_GraphicsSettings GetCurrentScreenSpaceReflectionsSetting();

// Set system settings based on graphics quality settings
simulated native function SetShadowSysSetting(EUI_PCOptions_GraphicsSettings InSetting);
simulated native function SetShadowQualitySysSetting(EUI_PCOptions_GraphicsSettings InSetting);
simulated native function SetTextureFilteringSysSetting(EUI_PCOptions_GraphicsSettings InSetting);
simulated native function SetTextureDetailSysSetting(EUI_PCOptions_GraphicsSettings InSetting);
simulated native function SetAntiAliasingSysSetting(EUI_PCOptions_GraphicsSettings InSetting);
simulated native function SetAmbientOcclusionSysSetting(EUI_PCOptions_GraphicsSettings InSetting);
simulated native function SetMaxDrawDistanceSysSetting(EUI_PCOptions_GraphicsSettings InSetting);

simulated native function SetEffectsSysSetting(EUI_PCOptions_GraphicsSettings InSetting);
simulated native function SetBloomSysSetting(EUI_PCOptions_GraphicsSettings InSetting);
simulated native function SetDepthOfFieldSysSetting(EUI_PCOptions_GraphicsSettings InSetting);
simulated native function SetDirtyLensSysSetting(EUI_PCOptions_GraphicsSettings InSetting);
simulated native function SetDecalsSysSetting(EUI_PCOptions_GraphicsSettings InSetting);
simulated native function SetSubsurfaceScatteringSysSettings(EUI_PCOptions_GraphicsSettings InSetting);
simulated native function SetScreenSpaceReflectionsSysSetting(EUI_PCOptions_GraphicsSettings InSetting);


simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local TUIGraphicsOptionSettingConfig TempConfig;

	super.InitScreen(InitController, InitMovie, InitName);

	TempConfig = GetPresetConfig(); GraphicsOptions[TempConfig.Order] = TempConfig;
	TempConfig = GetAmbientOcclusionConfig(); GraphicsOptions[TempConfig.Order] = TempConfig;
	TempConfig = GetAntiAliasingConfig(); GraphicsOptions[TempConfig.Order] = TempConfig;
	TempConfig = GetShadowConfig(); GraphicsOptions[TempConfig.Order] = TempConfig;
	TempConfig = GetShadowQualityConfig(); GraphicsOptions[TempConfig.Order] = TempConfig;
	TempConfig = GetTextureDetailConfig(); GraphicsOptions[TempConfig.Order] = TempConfig;
	TempConfig = GetTextureFilteringConfig(); GraphicsOptions[TempConfig.Order] = TempConfig;
	TempConfig = GetEffectsConfig(); GraphicsOptions[TempConfig.Order] = TempConfig;
	TempConfig = GetBloomConfig(); GraphicsOptions[TempConfig.Order] = TempConfig;
	TempConfig = GetDirtyLensConfig(); GraphicsOptions[TempConfig.Order] = TempConfig;
	TempConfig = GetDepthOfFieldConfig(); GraphicsOptions[TempConfig.Order] = TempConfig;
	TempConfig = GetSubsurfaceScatteringConfig(); GraphicsOptions[TempConfig.Order] = TempConfig;
	TempConfig = GetScreenSpaceReflectionsConfig(); GraphicsOptions[TempConfig.Order] = TempConfig;
	TempConfig = GetDecalsConfig(); GraphicsOptions[TempConfig.Order] = TempConfig;
	TempConfig = GetMaxDrawDistanceConfig(); GraphicsOptions[TempConfig.Order] = TempConfig;

	// Populate the reusable arrays from localized strings
	m_DefaultGraphicsSettingLabels.AddItem(m_strGraphicsSetting_Disabled);
	m_DefaultGraphicsSettingLabels.AddItem(m_strGraphicsSetting_Low);
	m_DefaultGraphicsSettingLabels.AddItem(m_strGraphicsSetting_Medium);
	m_DefaultGraphicsSettingLabels.AddItem(m_strGraphicsSetting_High);
	m_DefaultGraphicsSettingLabels.AddItem(m_strGraphicsSetting_Custom);

	m_VideoMode_Labels.AddItem(m_strVideoLabel_Fullscreen);
	m_VideoMode_Labels.AddItem(m_strVideoLabel_BorderlessWindow);
	m_VideoMode_Labels.AddItem(m_strVideolabel_Windowed);

	m_bAllowCredits = WorldInfo.GRI.GameClass.name == 'XComShell';

	List = Spawn(class'UIList', self);
	List.InitList('listMC');

	RefreshHelp();
	Show();
}

//----------------------------------------------------------------------------
//	Set default values.
//
simulated function OnInit()
{
	local int i;
	local UIMechaListItem ListItem;
	bInputReceived = false;
	
	super.OnInit();		
		
	RefreshHelp();

	NavHelp = PC.Pres.GetNavHelp();
	if(NavHelp == none)
		NavHelp = Spawn(class'UINavigationHelp',self).InitNavHelp();
	NavHelp.ClearButtonHelp();
	NavHelp.AddBackButton(IgnoreChangesAndExit);

	// list needs to be created backwards for depth sorting
	for(i= NUM_LISTITEMS - 1; i >= 0; i--) 
	{
		ListItem = Spawn( class'UIMechaListItem', List.itemContainer );
		ListItem.bAnimateOnInit = false;
		ListItem.InitListItem();
		ListItem.SetY(i * class'UIMechaListItem'.default.Height);
		m_arrMechaItems.InsertItem(0, ListItem);
	}

	m_kProfileSettings = `XPROFILESETTINGS;

	// Save profile settings so they can be restored if the user cancels
	SavePreviousProfileSettingsToBuffer();

	m_bAnyValueChanged = false;
	m_GEngineValueChanged = false;
	m_bResolutionChanged = false;
	m_bGammaChanged = false;
	m_bPendingExit = false;

	RefreshData();
	SetSelectedTab(ePCTab_Audio); // audio tab on creation

	InitNewSysSettings();
	StoreInitGraphicsSettings();
	StoreInitVideoSettings();

	if( !bIsVisible && XComPresentationLayer(Movie.Pres).m_kPCOptions != none ) 
		Hide(); 
	else
		Show();

	SetTimer(0.1, true, 'WatchForChanges');
}

// This is a replacement for the Tick(), specifically because the Tick needs to pause and control the countdown timer 
// for resolution changes, and so stops all of this from happening. -bsteiner
function WatchForChanges()
{
	local OnlineSubSystem OnlineSub;

	Movie.SetResolutionAndSafeArea();

	// If on PC and using gamepad controls detect newly connected controllers if no gamepad is found
	if( !WorldInfo.IsConsoleBuild() && m_kProfileSettings != none && !m_kProfileSettings.Data.IsMouseActive() )
	{
		OnlineSub = Class'GameEngine'.static.GetOnlineSubsystem();
		if( OnlineSub != none && !OnlineSub.SystemInterface.IsControllerConnected(0) )
		{
			`ONLINEEVENTMGR.EnumGamepads_PC(); // Detect gamepads that have been connected since the game launched
		}
	}
}

simulated public function RefreshHelp()
{
	local string strGameClassName;
	local bool bInShell; 

	if( GPUAutoDetectButton == none )
	{
		GPUAutoDetectButton = Spawn(class'UIButton', self);
		GPUAutoDetectButton.InitButton(, m_strGPUAutoDetect, RunGPUAutoDetectFromOptions);
		GPUAutoDetectButton.SetPosition(100, 800);
	}

	strGameClassName = String(WorldInfo.GRI.GameClass.name);
	bInShell = (strGameClassName == "XComShell");
	if( CreditsButton == none  && bInShell )
	{
		CreditsButton = Spawn(class'UIButton', self);
		CreditsButton.InitButton(, m_strCreditsLink, ViewCredits);
		CreditsButton.SetPosition(100, 750); //Relative to this screen panel
	}
	if( SaveAndExitButton == none )
	{
		SaveAndExitButton = Spawn(class'UIButton', self);
		SaveAndExitButton.InitButton(, m_strSaveAndExit, SaveAndExit);
		SaveAndExitButton.SetPosition(690, 850); //Relative to this screen panel
	}
	if( ExitWitoutChangesButton == none )
	{
		ExitWitoutChangesButton = Spawn(class'UIButton', self);
		ExitWitoutChangesButton.InitButton(, m_strRestoreSettings, RestoreInitGraphicsSettings);
		ExitWitoutChangesButton.SetPosition(100, 850); //Relative to this screen panel
	}
}

simulated function SavePreviousProfileSettingsToBuffer()
{
	// Serialize the current settings to the settings buffer.
	// This way they can be read back if the user cancels their changes.
	`ONLINEEVENTMGR.WriteProfileSettingsToBuffer();
}

simulated function RestorePreviousProfileSettings()
{
	if( m_kProfileSettings != none )
	{
		// Create a new data blob with default settings.
		m_kProfileSettings.Data = new(m_kProfileSettings) class'XComOnlineProfileSettingsDataBlob'; 
		m_kProfileSettings.Data.m_bIsConsoleBuild = `GAMECORE.WorldInfo.IsConsoleBuild();

		// Restore the previous settings by reading them back out of the buffer.
		`ONLINEEVENTMGR.ReadProfileSettingsFromBuffer();

		// Apply the previous settings
		m_kProfileSettings.ApplyOptionsSettings();
		
		// Video options are system-level and not in the profile.
		ResetInitVideoSettings();
	}
}

simulated function AS_SetHelp(int index, string text, string buttonIcon)
{ Movie.ActionScriptVoid( screen.MCPath $ ".SetHelp"); }

// Still play sounds, even when paused.
simulated event ModifyHearSoundComponent(AudioComponent AC)
{
	AC.bIsUISound = true;
}

simulated function bool OnUnrealCommand(int cmd, int ActionMask)
{
	if( !bIsInited || m_bSavingInProgress ) return true; 

	bInputReceived = true;
	// Ignore releases, only pay attention to presses.
	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, ActionMask) )
		return true; // Consume All Input!

	switch(cmd)
	{
		case class'UIUtilities_Input'.const.FXS_BUTTON_X:
			SaveAndExit(none);
			break;
		
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
			IgnoreChangesAndExit();
			break;

		case class'UIUtilities_Input'.const.FXS_BUTTON_Y:
			ResetToDefaults();
			break; 		

		case class'UIUtilities_Input'.const.FXS_BUTTON_RTRIGGER:	
			if( m_bAllowCredits )
				Movie.Pres.UICredits( false );
			break;

		case class'UIUtilities_Input'.const.FXS_DPAD_UP:
		case class'UIUtilities_Input'.const.FXS_ARROW_UP:
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_UP:
			OnUDPadUp();
			break;

		case class'UIUtilities_Input'.const.FXS_DPAD_DOWN:
		case class'UIUtilities_Input'.const.FXS_ARROW_DOWN:
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DOWN:
			OnUDPadDown();
			break;

		case class'UIUtilities_Input'.const.FXS_KEY_PAGEUP:
		case class'UIUtilities_Input'.const.FXS_BUTTON_LBUMPER:
			SetSelectedTab( m_iCurrentTab - 1);
			break;

		case class'UIUtilities_Input'.const.FXS_KEY_PAGEDN:
		case class'UIUtilities_Input'.const.FXS_BUTTON_RBUMPER:
			if ((m_iCurrentTab + 1) < ePCTab_MAX)
			{
				SetSelectedTab( m_iCurrentTab + 1 ); 
			}
			else
			{
				Navigator.SetSelected(SaveAndExitButton);
			}
			break;

		default:
			// Do not reset handled, consume input since this
			// is the options menu which stops any other systems.
			break;			
	}

	// Assume input is handled unless told otherwise (unlikely
	// because this is the options menu; it handles alllllllll.)
	return super.OnUnrealCommand(cmd, ActionMask);
}

simulated native function bool GetCurrentMouseLock();
simulated native function bool GetCurrentFRSmoothingToggle();

//----------------------------------------------------
simulated function RefreshData()
{
	local bool                  bIsConsole; //Used to hide some options if only PC or only console
	local string                strGraphics;
	//local string                strGameClassName;
	//local bool                  bInShell; 

	bIsConsole = WorldInfo.IsConsoleBuild(); 

	strGraphics = bIsConsole ? "" : m_strTabGraphics;

	AS_SetTitle(m_strTitle);	
	
	AS_SetTabData(m_strTabAudio, m_strTabVideo, strGraphics, m_strTabGameplay, m_strTabInterface);

	m_SystemSettingsChanged = false;

	Show();
}

function SetVideoTabSelected()
{
	ResetMechaListItems();

	// NOTE: Keeping the actual widgets of removed settings so that the remaining
	//		 ones are still operational - KD
	// Mode: --------------------------------------------
	m_arrMechaItems[ePCTabVideo_Mode].UpdateDataSpinner(m_strVideoLabel_Mode, m_VideoMode_Labels[ModeSpinnerVal], UpdateMode_OnChanged);
	m_arrMechaItems[ePCTabVideo_Mode].BG.SetTooltipText(m_strVideoLabel_Mode_Desc, , , 10, , , , 0.0f);

	// Mouse lock to window: --------------------------------------------
	m_arrMechaItems[ePCTabVideo_MouseLock].UpdateDataCheckbox(m_strVideolabel_MouseLock, "", GetCurrentMouseLock(), UpdateMouseLock);
	m_arrMechaItems[ePCTabVideo_MouseLock].BG.SetTooltipText(m_strVideolabel_MouseLock_Desc, , , 10, , , , 0.0f);

	// Resolution: --------------------------------------------
	SetSupportedResolutionsNative(ModeSpinnerVal == 1);

	m_arrMechaItems[ePCTabVideo_Resolution].UpdateDataDropdown(m_strVideoLabel_Resolution, m_kGameResolutionStrings, m_kCurrentSupportedResolutionIndex, UpdateResolution);
	m_arrMechaItems[ePCTabVideo_Resolution].BG.SetTooltipText(m_strVideoLabel_Resolution_Desc, , , 10, , , , 0.0f);
	SetResolutionDropdown();

	// Gamma: --------------------------------------------
	m_arrMechaItems[ePCTabVideo_Gamma].UpdateDataSlider(m_strVideoLabel_Gamma, "", , , UpdateGamma);
	m_arrMechaItems[ePCTabVideo_Gamma].BG.SetTooltipText(m_strVideoLabel_Gamma_Desc, , , 10, , , , 0.0f);
	m_arrMechaItems[ePCTabVideo_Gamma].Slider.SetPercent(GetGammaPercentage());

	// V-Sync toggle: --------------------------------------------
	m_arrMechaItems[ePCTabVideo_VSync].UpdateDataCheckbox(m_strVideoLabel_VSyncToggle, "", m_kInitGraphicsSettings.bVSync, UpdateVSync);
	m_arrMechaItems[ePCTabVideo_VSync].BG.SetTooltipText(m_strVideoLabel_VSyncToggle_Desc, , , 10, , , , 0.0f);

	// Frame Rate Smoothing toggle: --------------------------------
	m_arrMechaItems[ePCTabVideo_FRSmoothing].UpdateDataCheckbox(m_strVideoLabel_FRSmoothingToggle, "", GetCurrentFRSmoothingToggle(), UpdateFRSmoothing);
	m_arrMechaItems[ePCTabVideo_FRSmoothing].BG.SetTooltipText(m_strVideoLabel_FRSmoothingToggle_Desc, , , 10, , , , 0.0f);
	
	RenableMechaListItems(ePCTabVideo_Max);
}

public function SpinnerUpdated(UIListItemSpinner spinnerControl, int direction)
{
	local int i;

	for (i = 0; i < NumGraphicsOptions; i++)
	{
		if (spinnerControl == m_arrMechaItems[i].Spinner)
		{
			if (m_bApplyingPreset == false)
				Movie.Pres.PlayUISound(eSUISound_MenuSelect);

			GraphicsVals[i] = max(min(GraphicsVals[i] + direction, GraphicsOptions[i].Values.length - 1), 0);

			switch (i)
			{
			case ePCGraphics_Preset:
				ApplyPresetState(false);
				break;
			case ePCGraphics_Shadow:
				SetShadowSysSetting(GraphicsOptions[i].Values[GraphicsVals[i]]);
				break;
			case ePCGraphics_ShadowQuality:
				SetShadowQualitySysSetting(GraphicsOptions[i].Values[GraphicsVals[i]]);
				break;
			case ePCGraphics_TextureFiltering:
				SetTextureFilteringSysSetting(GraphicsOptions[i].Values[GraphicsVals[i]]);
				break;
			case ePCGraphics_TextureDetail:
				SetTextureDetailSysSetting(GraphicsOptions[i].Values[GraphicsVals[i]]);
				break;
			case ePCGraphics_AntiAliasing:
				SetAntiAliasingSysSetting(GraphicsOptions[i].Values[GraphicsVals[i]]);
				break;
			case ePCGraphics_AmbientOcclusion:
				SetAmbientOcclusionSysSetting(GraphicsOptions[i].Values[GraphicsVals[i]]);
				break;
			case ePCGraphics_Decals:
				SetDecalsSysSetting(GraphicsOptions[i].Values[GraphicsVals[i]]);
				break;
			case ePCGraphics_DepthOfField:
				SetDepthOfFieldSysSetting(GraphicsOptions[i].Values[GraphicsVals[i]]);
				break;
			case ePCGraphics_MaxDrawDistance:
				SetMaxDrawDistanceSysSetting(GraphicsOptions[i].Values[GraphicsVals[i]]);
				break;
			default:
			}

			spinnerControl.SetValue(GraphicsOptions[i].Labels[GraphicsVals[i]]);

			if (m_bApplyingPreset == false)
				UpdateGraphicsWidgetCommon();

			break;
		}
	}	
}

public function CheckboxUpdated(UICheckbox checkboxControl)
{
	local int i;

	for (i = 0; i < NumGraphicsOptions; i++)
	{
		if (checkboxControl == m_arrMechaItems[i].Checkbox)
		{
			if (m_bApplyingPreset == false)
				Movie.Pres.PlayUISound(eSUISound_MenuSelect);
			GraphicsVals[i] = checkboxControl.bChecked ? 1 : 0;

			switch (i)
			{
			case ePCGraphics_Effects:
				SetEffectsSysSetting(GraphicsOptions[i].Values[GraphicsVals[i]]);
				break;
			case ePCGraphics_Bloom:
				SetBloomSysSetting(GraphicsOptions[i].Values[GraphicsVals[i]]);				
				if (GraphicsVals[i] == 0)
				{
					m_bApplyingPreset = true;
					m_arrMechaItems[ePCGraphics_DirtyLens].Checkbox.SetChecked(false);
					CheckboxUpdated(m_arrMechaItems[ePCGraphics_DirtyLens].Checkbox);
					m_bApplyingPreset = false;
				}
				m_arrMechaItems[ePCGraphics_DirtyLens].Checkbox.SetReadOnly(GraphicsVals[i] == 0);
				break;
			case ePCGraphics_DirtyLens:
				SetDirtyLensSysSetting(GraphicsOptions[i].Values[GraphicsVals[i]]);
				break;
			case ePCGraphics_SubsurfaceScattering:
				SetSubsurfaceScatteringSysSettings(GraphicsOptions[i].Values[GraphicsVals[i]]);
				break;
			case ePCGraphics_ScreenSpaceReflections:
				SetScreenSpaceReflectionsSysSetting(GraphicsOptions[i].Values[GraphicsVals[i]]);
				break;
			default:
			}

			if (m_bApplyingPreset == false)
				UpdateGraphicsWidgetCommon();
		}
	}
}

function SetGraphicsTabSelected()
{
	local int i;
	m_bApplyingPreset = true;

	ResetMechaListItems();

	for (i = 0; i < NumGraphicsOptions; i++)
	{
		if (GraphicsOptions[i].bSpinner)
		{
			m_arrMechaItems[GraphicsOptions[i].Order].UpdateDataSpinner(GraphicsOptions[i].Label, GraphicsOptions[i].Labels[GraphicsVals[i]], SpinnerUpdated);
		}
		else
		{
			m_arrMechaItems[GraphicsOptions[i].Order].UpdateDataCheckbox(GraphicsOptions[i].Label, "", bool(GraphicsVals[i]), CheckboxUpdated);
		}
	}

	SetPresetState();
	ApplyPresetState(true);

	RenableMechaListItems(ePCGraphics_Max);
}

function SetAudioTabSelected()
{
	ResetMechaListItems();

	// Master Volume: --------------------------------------------
	m_arrMechaItems[ePCTabAudio_MasterVolume].UpdateDataSlider(m_strAudioLabel_MasterVolume, "", m_kProfileSettings.Data.m_iMasterVolume, , UpdateMasterVolume);
	m_arrMechaItems[ePCTabAudio_MasterVolume].BG.SetTooltipText(m_strAudioLabel_MasterVolume_Desc, , , 10, , , , 0.0f);

	// Voice Volume: --------------------------------------------
	m_arrMechaItems[ePCTabAudio_VoiceVolume].UpdateDataSlider(m_strAudioLabel_VoiceVolume, "", m_kProfileSettings.Data.m_iVoiceVolume, , UpdateVoiceVolume);
	m_arrMechaItems[ePCTabAudio_VoiceVolume].BG.SetTooltipText(m_strAudioLabel_VoiceVolume_Desc, , , 10, , , , 0.0f);

	// Sound Effects Volume: --------------------------------------------
	m_arrMechaItems[ePCTabAudio_SoundEffectsVolume].UpdateDataSlider(m_strAudioLabel_SoundEffectVolume, "", m_kProfileSettings.Data.m_iFXVolume, , UpdateSoundEffectsVolume);
	m_arrMechaItems[ePCTabAudio_SoundEffectsVolume].BG.SetTooltipText(m_strAudioLabel_SoundEffectVolume_Desc, , , 10, , , , 0.0f);

	// Sound Effects Volume: --------------------------------------------
	m_arrMechaItems[ePCTabAudio_VOIPVolume].UpdateDataSlider(m_strAudioLabel_VOIPVolume, "", m_kProfileSettings.Data.m_iVOIPVolume, , UpdateVOIPVolume);
	m_arrMechaItems[ePCTabAudio_VOIPVolume].BG.SetTooltipText(m_strAudioLabel_VOIPVolume_Desc, , , 10, , , , 0.0f);
	
	// Music Volume: --------------------------------------------
	m_arrMechaItems[ePCTabAudio_MusicVolume].UpdateDataSlider(m_strAudioLabel_MusicVolume, "", m_kProfileSettings.Data.m_iMusicVolume, , UpdateMusicVolume);
	m_arrMechaItems[ePCTabAudio_MusicVolume].BG.SetTooltipText(m_strAudioLabel_MusicVolume_Desc, , , 10, , , , 0.0f);
	

	// Sound Effects Volume: --------------------------------------------
	m_arrMechaItems[ePCTabAudio_VOIPPushToTalk].UpdateDataCheckbox(m_strAudioLabel_VOIPPushToTalk, "", m_kProfileSettings.Data.m_bPushToTalk, UpdatePushToTalk);
	m_arrMechaItems[ePCTabAudio_VOIPPushToTalk].BG.SetTooltipText(m_strAudioLabel_VOIPPushToTalk_Desc, , , 10, , , , 0.0f);

	// Enable Soldier Speech: --------------------------------------------
	m_arrMechaItems[ePCTabAudio_EnableSoldierSpeech].UpdateDataCheckbox(m_strAudioLabel_EnableSoldierSpeech, "", m_kProfileSettings.Data.m_bEnableSoldierSpeech, UpdateEnableSoldierSpeech);
	m_arrMechaItems[ePCTabAudio_EnableSoldierSpeech].BG.SetTooltipText(m_strAudioLabel_EnableSoldierSpeech_Desc, , , 10, , , , 0.0f);

	// Enable Foreign Languages: --------------------------------------------
	m_arrMechaItems[ePCTabAudio_ForeignLanguages].UpdateDataCheckbox( m_strAudioLabel_ForeignLanguages, "", m_kProfileSettings.Data.m_bForeignLanguages, UpdateForeignLanguages);
	m_arrMechaItems[ePCTabAudio_ForeignLanguages].BG.SetTooltipText(m_strAudioLabel_ForeignLanguages_Desc, , , 10, , , , 0.0f);

	// Enable Ambient VO in the Avenger
	m_arrMechaItems[ePCTabAudio_EnableAmbientVO].UpdateDataCheckbox(m_strAudioLabel_AmbientVO, "", m_kProfileSettings.Data.m_bAmbientVO, UpdateAmbientVO);
	m_arrMechaItems[ePCTabAudio_EnableAmbientVO].BG.SetTooltipText(m_strAudioLabel_AmbientVO_Desc, , , 10, , , , 0.0f);
	
	RenableMechaListItems(ePCTabAudio_Max);
}

function SetGameplayTabSelected()
{
	local int numOptions;
	
	ResetMechaListItems();

	// Glam Cam: --------------------------------------------
	m_arrMechaItems[ePCTabGameplay_GlamCam].UpdateDataCheckbox(m_strGameplayLabel_GlamCam,"",  m_kProfileSettings.Data.m_bGlamCam, UpdateGlamCam);

	// Autosave toggle: --------------------------------------------
	m_arrMechaItems[ePCTabGameplay_AutosaveMaster].UpdateDataCheckbox( m_strGameplayLabel_AutosaveToggle,"", m_kProfileSettings.Data.m_bAutoSave, UpdateAutosave);
	m_arrMechaItems[ePCTabGameplay_AutosaveMaster].SetDisabled(!`ONLINEEVENTMGR.HasValidLoginAndStorage());

	// Show enemy health: --------------------------------------------
	m_arrMechaItems[ePCTabGameplay_ShowEnemyHealth].UpdateDataCheckbox(m_strGameplayLabel_ShowEnemyHealth, "", m_kProfileSettings.Data.m_bShowEnemyHealth, UpdateShowEnemyHealth);

	if(class'X2Action_MoveDirect'.default.bUseRunRateOption)
	{
		numOptions = ePCTabGameplay_Max;
		// Adjust how fast units move around
		m_arrMechaItems[ePCTabGameplay_UnitMoveSpeed].UpdateDataSlider(m_strGameplayLabel_UnitMoveSpeed, "", m_kProfileSettings.Data.UnitMovementSpeed * 100.0f, , UpdateMovementSpeed);
	}
	else
	{
		numOptions = ePCTabGameplay_Max -1;
	}

	RenableMechaListItems(numOptions);
}

function SetInterfaceTabSelected()
{
	ResetMechaListItems();

	// Input Device: --------------------------------------------
	//m_arrMechaItems[ePCTabInterface_InputDevice].UpdateDataSpinner(m_strInterfaceLabel_InputDevice,"",  UpdateInputDevice_ToggleMouse);
	//m_arrMechaItems[].BG.SetTooltipText(_Desc, , , 10, , , , 0.0f);

	// Key Bindings screen
	m_arrMechaItems[ePCTabInterface_KeyBindings].UpdateDataButton(m_strInterfaceLabel_KeyBindings, m_strInterfaceLabel_BindingsButton, OpenKeyBindingsScreen);
	m_arrMechaItems[ePCTabInterface_KeyBindings].BG.SetTooltipText(m_strInterfaceLabel_KeyBindings_Desc, , , 10, , , , 0.0f);
	m_arrMechaItems[ePCTabInterface_KeyBindings].SetDisabled(!m_kProfileSettings.Data.IsMouseActive());

	// Subtitles: -------------------------------------------
	m_arrMechaItems[ePCTabInterface_Subtitles].UpdateDataCheckbox(m_strInterfaceLabel_ShowSubtitles, "", m_kProfileSettings.Data.m_bSubtitles, UpdateSubtitles);
	m_arrMechaItems[ePCTabInterface_Subtitles].BG.SetTooltipText(m_strInterfaceLabel_ShowSubtitles_Desc, , , 10, , , , 0.0f);
	
	// Edge scrolling: -------------------------------------
	m_arrMechaItems[ePCTabInterface_EdgeScroll].UpdateDataSlider(m_strInterfaceLabel_EdgescrollSpeed, "", m_kProfileSettings.Data.m_fScrollSpeed, , UpdateEdgeScroll);
	m_arrMechaItems[ePCTabInterface_EdgeScroll].BG.SetTooltipText(m_strInterfaceLabel_EdgescrollSpeed_Desc, , , 10, , , , 0.0f);
	m_arrMechaItems[ePCTabInterface_EdgeScroll].SetDisabled(WorldInfo.IsConsoleBuild());

	//-------------------------------------------------------

	RenableMechaListItems(ePCTabInterface_Max);
}
//-------------------------------------------------------

// ========================================================
// DATA HOOKS - VIDEO - TAB 0 
// ========================================================
public function UpdateMode_OnChanged(UIListItemSpinner SpinnerControl, int Direction)
{
	ModeSpinnerVal += direction;

	if (ModeSpinnerVal < 0)
		ModeSpinnerVal = 2;
	else if (ModeSpinnerVal > 2)
		ModeSpinnerVal = 0;

	SetSupportedResolutions();

	SpinnerControl.SetValue(m_VideoMode_Labels[ModeSpinnerVal]);

	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	m_bAnyValueChanged = true;
	m_bResolutionChanged = m_kInitGraphicsSettings.iMode != ModeSpinnerVal;
}

public function UpdateResolution(UIDropdown DropdownControl)
{
	local int tmpWidth, tmpHeight;
	
	m_kCurrentSupportedResolutionIndex = DropdownControl.SelectedItem;

	tmpWidth = m_kGameResolutionWidths[m_kCurrentSupportedResolutionIndex];
	tmpHeight = m_kGameResolutionHeights[m_kCurrentSupportedResolutionIndex];
	

	m_bResolutionChanged = tmpWidth != m_kInitGraphicsSettings.iResolutionWidth || tmpHeight != m_kInitGraphicsSettings.iResolutionHeight;
	m_bAnyValueChanged = m_bAnyValueChanged || m_bResolutionChanged;

	Movie.Pres.PlayUISound(eSUISound_MenuSelect);
}

native function UpdateMouseLockNative(bool bNewMouseLock);

public function UpdateMouseLock(UICheckbox CheckboxControl)
{
	UpdateMouseLockNative(CheckboxControl.bChecked);
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);
	m_bAnyValueChanged = true;
	m_SystemSettingsChanged = true;
}

native function UpdateFRSmoothingNative(bool bUseFRSmoothing);

public function UpdateFRSmoothing(UICheckbox CheckboxControl)
{
	UpdateFRSmoothingNative(CheckboxControl.bChecked);
	m_GEngineValueChanged = true;
	m_bAnyValueChanged = true;

	Movie.Pres.PlayUISound(eSUISound_MenuSelect);
}

public function UpdateVSync(UICheckbox checkboxControl)
{
	UpdateVSyncNative(checkboxControl.bChecked);

	m_bAnyValueChanged = true;
	m_SystemSettingsChanged = true;

	Movie.Pres.PlayUISound(eSUISound_MenuSelect);
}

public function float GetGammaPercentage()
{
	return (GetGammaPercentageNative() - GAMMA_LOW) / (GAMMA_HIGH - GAMMA_LOW) * 100.0;
}

public function UpdateGamma(UISlider sliderControl)
{
	UpdateGammaNative((sliderControl.percent * 0.01) * (GAMMA_HIGH - GAMMA_LOW) + GAMMA_LOW);

	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	m_bAnyValueChanged = true;
	m_bGammaChanged = true;
}

function UpdateViewportCheck()
{
	if (m_bResolutionChanged)
	{
		UpdateViewport();

		m_bPendingExit = true;
		m_bResolutionChanged = false;
	}
}

function UpdateViewport()
{
	local int tmpWidth, tmpHeight;
	local TDialogueBoxData kDialogData;

	tmpWidth = m_kGameResolutionWidths[m_kCurrentSupportedResolutionIndex];
	tmpHeight = m_kGameResolutionHeights[m_kCurrentSupportedResolutionIndex];

	UpdateViewportNative(tmpWidth, tmpHeight, ModeSpinnerVal == 0, ModeSpinnerVal == 1 ? 1 : 0);

	m_KeepResolutionCountdown = 15;
	SetTimer(1, true, 'KeepResolutionCountdown');

	// show dialog
	kDialogData.eType       = eDialog_Warning;
	kDialogData.strTitle    = m_strVideoKeepSettings_Title;
	kDialogData.strText     = Repl(m_strVideoKeepSettings_Body, "%VALUE", m_KeepResolutionCountdown);
	kDialogData.strAccept   = m_strVideoKeepSettings_Confirm;
	kDialogData.strCancel   = class'UIDialogueBox'.default.m_strDefaultCancelLabel;	
	kDialogData.fnCallback  = KeepResolutionCallback;

	Movie.Pres.UIRaiseDialog( kDialogData );
}

simulated public function KeepResolutionCountdown()
{
	local string NewText; 

	m_KeepResolutionCountdown--;
	if (m_KeepResolutionCountdown <= 0)
	{
		// cancel the dialog
		Movie.Pres.Get2DMovie().DialogBox.ClearDialogs();
		// and revert changes
		KeepResolutionCallback(eUIAction_Cancel);
	}
	else
	{
		NewText = Repl(m_strVideoKeepSettings_Body, "%VALUE", m_KeepResolutionCountdown);
		Movie.Pres.Get2DMovie().DialogBox.UpdateDialogText(NewText);
	}
}

simulated public function KeepResolutionCallback(eUIAction eAction)
{
	ClearTimer('KeepResolutionCountdown');

	m_bPendingExit = false;

	if (eAction == eUIAction_Accept)
	{
		SaveAndExitFinal();
	}
	else
	{
		// revert to old settings
		UpdateViewportNative(m_kInitGraphicsSettings.iResolutionWidth, 
							 m_kInitGraphicsSettings.iResolutionHeight, 
							 m_kInitGraphicsSettings.iMode == 0, 
							 m_kInitGraphicsSettings.iMode == 1 ? 1 : 0);

		ModeSpinnerVal = m_kInitGraphicsSettings.iMode;
		m_arrMechaItems[ePCTabVideo_Mode].Spinner.SetValue(m_VideoMode_Labels[ModeSpinnerVal]);
		m_arrMechaItems[ePCTabVideo_Mode].BG.SetTooltipText(m_strVideoLabel_Mode_Desc, , , 10, , , , 0.0f);
		m_arrMechaItems[ePCTabVideo_VSync].Checkbox.SetChecked(m_kInitGraphicsSettings.bVSync);

		SetSupportedResolutions();
		NavHelp.ClearButtonHelp();
		NavHelp.AddBackButton(IgnoreChangesAndExit);
	}
}

// ========================================================
// DATA HOOKS - GRAPHICS - TAB 1 
// ========================================================
function UpdateGraphicsWidgetCommon()
{
	if (m_bApplyingPreset == false)
		SetPresetState();

	m_bAnyValueChanged = true;
	m_SystemSettingsChanged= true;
}

// ========================================================
// DATA HOOKS - AUDIO - TAB 2 
// ========================================================


public function UpdateMasterVolume(UISlider SliderControl)
{
	m_kProfileSettings.Data.m_iMasterVolume = SliderControl.percent;
	m_kProfileSettings.ApplyAudioOptions();
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);
	m_bAnyValueChanged = true;
}

public function UpdateVoiceVolume(UISlider SliderControl)
{
	m_kProfileSettings.Data.m_iVoiceVolume = SliderControl.percent;
	m_kProfileSettings.ApplyAudioOptions();

	PlayAkEvent(AkEvent'SoundGlobalUI.Play_VolumeSlider_Voice');
	
	m_bAnyValueChanged = true;
}

public function UpdateSoundEffectsVolume(UISlider SliderControl)
{
	m_kProfileSettings.Data.m_iFXVolume = SliderControl.percent;
	m_kProfileSettings.ApplyAudioOptions();
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);
	m_bAnyValueChanged = true;
}

public function UpdateVOIPVolume(UISlider SliderControl)
{
	m_kProfileSettings.Data.m_iVOIPVolume = SliderControl.percent;
	m_kProfileSettings.ApplyAudioOptions();
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);
	m_bAnyValueChanged = true;
}
public function UpdateMusicVolume(UISlider SliderControl)
{
	m_kProfileSettings.Data.m_iMusicVolume = SliderControl.percent;
	m_kProfileSettings.ApplyAudioOptions();
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);
	m_bAnyValueChanged = true;
}

public function UpdatePushToTalk(UICheckbox CheckboxControl)
{
	m_kProfileSettings.Data.m_bPushToTalk = CheckboxControl.bChecked; 
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);
	m_bAnyValueChanged = true;
}

public function UpdateEnableSoldierSpeech(UICheckbox CheckboxControl)
{
	m_kProfileSettings.Data.m_bEnableSoldierSpeech = CheckboxControl.bChecked; 
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);
	m_bAnyValueChanged = true;
}

public function UpdateForeignLanguages(UICheckbox CheckboxControl)
{
	m_kProfileSettings.Data.m_bForeignLanguages = CheckboxControl.bChecked;
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);
	m_bAnyValueChanged = true;
}

public function UpdateAmbientVO(UICheckbox CheckboxControl)
{
	m_kProfileSettings.Data.m_bAmbientVO = CheckboxControl.bChecked;
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);
	m_bAnyValueChanged = true;
}


// ========================================================
// DATA HOOKS - GAMEPLAY - TAB 3
// ========================================================


public function UpdateGlamCam(UICheckbox CheckboxControl)
{	
	m_kProfileSettings.Data.m_bGlamCam = CheckboxControl.bChecked; 
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);
	m_bAnyValueChanged = true;
}

public function UpdateAutosave(UICheckbox CheckboxControl)
{
	m_kProfileSettings.Data.m_bAutoSave = CheckboxControl.bChecked; 
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);
	m_bAnyValueChanged = true;
}

public function UpdateShowEnemyHealth(UICheckbox CheckboxControl)
{
	m_kProfileSettings.Data.m_bShowEnemyHealth = CheckboxControl.bChecked; 
	if( XComPresentationLayer(Movie.Pres) != none )
	{
		XComPresentationLayer(Movie.Pres).m_kUnitFlagManager.RefreshAllHealth();
	}

	Movie.Pres.PlayUISound(eSUISound_MenuSelect);
	m_bAnyValueChanged = true;
}

public function UpdateMovementSpeed(UISlider SliderControl)
{
	m_kProfileSettings.Data.UnitMovementSpeed = SliderControl.percent / 100.0f;
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);
	m_bAnyValueChanged = true;
}

// ========================================================
// DATA HOOKS - INTERFACE - TAB 4
// ========================================================

public function OpenKeyBindingsScreen(UIButton ButtonSource)
{
	Movie.Pres.UIKeybindingsPCScreen();
}

public function UpdateSubtitles(UICheckbox CheckboxControl)
{
	m_kProfileSettings.Data.m_bSubtitles = CheckboxControl.bChecked;
	m_kProfileSettings.ApplyUIOptions();
	Movie.Pres.GetUIComm().RefreshSubtitleVisibility();

	Movie.Pres.PlayUISound(eSUISound_MenuSelect);
	m_bAnyValueChanged = true;
}
public function UpdateEdgeScroll(UISlider SliderControl)
{
	m_kProfileSettings.Data.m_fScrollSpeed = SliderControl.percent;
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);
	m_bAnyValueChanged = true;
}

function UpdateInputDevice_ToggleMouse(UIListItemSpinner SpinnerControl, int Direction)
{
	XComInputBase(PC.PlayerInput).ClearAllRepeatTimers();

	if( m_kProfileSettings.Data.IsMouseActive() )
	{
		m_kProfileSettings.Data.ActivateMouse(false);
		`ONLINEEVENTMGR.EnumGamepads_PC(); // Detect gamepads that have been connected since the game launched
	}
	else
	{
		m_kProfileSettings.Data.ActivateMouse(true);
	}
	
	RefreshInputDevice();
	RefreshHelp();

	Movie.Pres.PlayUISound(eSUISound_MenuSelect);
	m_bAnyValueChanged = true;
}
function RefreshInputDevice()
{
	OnInputDeviceChange();
	if(m_iCurrentTab == ePCTab_Interface)
	{
		m_arrMechaItems[ePCTabInterface_KeyBindings].SetDisabled(!m_kProfileSettings.Data.IsMouseActive());
	}

	if ( m_kProfileSettings.Data.IsMouseActive() )
		Movie.ActivateMouse();
	else
		Movie.DeactivateMouse();
}
//-------------------------------------------------------
// Added by Scott B. I need a way to identify this change and clear the movement borders.
function OnInputDeviceChange()
{
	local XComWorldData WorldData;

	WorldData = class'XComWorldData'.static.GetWorldData();
	if( WorldData != none )
	{
		WorldData.Volume.BorderComponent.ClearMovementGridScript();
		WorldData.Volume.BorderComponentDashing.ClearMovementGridScript();
	}
}

simulated function SetResolutionDropdown()
{
	local int i;

	if (m_arrMechaItems[ePCTabVideo_Resolution].Dropdown != none)
	{
		m_arrMechaItems[ePCTabVideo_Resolution].Dropdown.Clear();

		if (ModeSpinnerVal == 1)
		{
			m_arrMechaItems[ePCTabVideo_Resolution].Dropdown.AddItem(m_strGraphicsSetting_Disabled);
		}
		else
		{
			for (i = 0; i < m_kGameResolutionStrings.length; ++i)
			{
				m_arrMechaItems[ePCTabVideo_Resolution].Dropdown.AddItem(m_kGameResolutionStrings[i]);
			}
		}
		m_arrMechaItems[ePCTabVideo_Resolution].Dropdown.SetSelected(m_kCurrentSupportedResolutionIndex);
	}
}

simulated function SetSupportedResolutions()
{
	SetSupportedResolutionsNative(ModeSpinnerVal == 1);

	SetResolutionDropdown();
}


function ResetToDefaults()
{
	local TDialogueBoxData kDialogData;
	kDialogData.strText = m_strWantToResetToDefaults;
	kDialogData.fnCallback = ConfirmUserWantsToResetToDefault; 
	kDialogData.strCancel = class'UIDialogueBox'.default.m_strDefaultCancelLabel;
	kDialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;

	XComPresentationLayerBase(Owner).UIRaiseDialog(kDialogData);
}
public function ConfirmUserWantsToResetToDefault(eUIAction eAction)
{
	if( eAction == eUIAction_Accept )
	{
		ResetProfileSettings();
	}
}

simulated function ResetProfileSettings()
{
	local bool bInShell;
	local string strGameClassName; 

	if( m_kProfileSettings != none )
	{		
		// Create a new data blob with default settings.
		//m_kProfileSettings.Data = new(m_kProfileSettings) class'XComOnlineProfileSettingsDataBlob'; 
		strGameClassName = String(WorldInfo.GRI.GameClass.name);
		bInShell = (strGameClassName == "XComShell"); 
		m_kProfileSettings.Options_ResetToDefaults(bInShell);
		
		UpdateMouseLockNative(true);
		UpdateFRSmoothingNative(true);

		m_bAnyValueChanged = true;

		//Rest of settings 
		m_kProfileSettings.ApplyOptionsSettings();
		RefreshData();
		RefreshInputDevice();
		RefreshHelp();
	}
}

simulated function StoreInitVideoSettings()
{
	m_kInitVideoSettings.bMouseLock = GetCurrentMouseLock();
	m_kInitVideoSettings.bFRSmoothing = GetCurrentFRSmoothingToggle();
}
simulated function ResetInitVideoSettings()
{
	UpdateMouseLockNative(m_kInitVideoSettings.bMouseLock);
	UpdateFRSmoothingNative(m_kInitVideoSettings.bFRSmoothing);
}

simulated function int DetermineIndexFromSetting(EUI_PCOptions_Graphics Option, EUI_PCOptions_GraphicsSettings Value)
{
	local int i;
	for (i = 0; i < GraphicsOptions[Option].Values.length; i++)
	{
		if (Value == GraphicsOptions[Option].Values[i])
			return i;
	}

	return 0;
}

simulated function SetGraphicsValsFromCurrentSettings()
{
	GraphicsVals[ePCGraphics_Preset] = 0;
	GraphicsVals[ePCGraphics_Shadow] = DetermineIndexFromSetting(ePCGraphics_Shadow, GetCurrentShadowSetting());
	GraphicsVals[ePCGraphics_ShadowQuality] = DetermineIndexFromSetting(ePCGraphics_ShadowQuality, GetCurrentShadowQualitySetting());
	GraphicsVals[ePCGraphics_TextureFiltering] = DetermineIndexFromSetting(ePCGraphics_TextureFiltering, GetCurrentTextureFilteringSetting());
	GraphicsVals[ePCGraphics_TextureDetail] = DetermineIndexFromSetting(ePCGraphics_TextureDetail, GetCurrentTextureDetailSetting());
	GraphicsVals[ePCGraphics_AntiAliasing] = DetermineIndexFromSetting(ePCGraphics_AntiAliasing, GetCurrentAntiAliasingSetting());
	GraphicsVals[ePCGraphics_AmbientOcclusion] = DetermineIndexFromSetting(ePCGraphics_AmbientOcclusion, GetCurrentAmbientOcclusionSetting());
	GraphicsVals[ePCGraphics_Effects] = DetermineIndexFromSetting(ePCGraphics_Effects, GetCurrentEffectsSetting());
	GraphicsVals[ePCGraphics_Bloom] = DetermineIndexFromSetting(ePCGraphics_Bloom, GetCurrentBloomSetting());
	GraphicsVals[ePCGraphics_DepthOfField] = DetermineIndexFromSetting(ePCGraphics_DepthOfField, GetCurrentDepthOfFieldSetting());
	GraphicsVals[ePCGraphics_DirtyLens] = DetermineIndexFromSetting(ePCGraphics_DirtyLens, GetCurrentDirtyLensSetting());
	GraphicsVals[ePCGraphics_Decals] = DetermineIndexFromSetting(ePCGraphics_Decals, GetCurrentDecalsSetting());
	GraphicsVals[ePCGraphics_SubsurfaceScattering] = DetermineIndexFromSetting(ePCGraphics_SubsurfaceScattering, GetCurrentSubsurfaceScatteringSetting());
	GraphicsVals[ePCGraphics_ScreenSpaceReflections] = DetermineIndexFromSetting(ePCGraphics_ScreenSpaceReflections, GetCurrentScreenSpaceReflectionsSetting());
	GraphicsVals[ePCGraphics_MaxDrawDistance] = DetermineIndexFromSetting(ePCGraphics_MaxDrawDistance, GetCurrentMaxDrawDistanceSetting());
}

simulated function StoreInitGraphicsSettings()
{
	local int i;
	local vector2d ViewportSize;
	local Engine Engine;

	Engine = class'Engine'.static.GetEngine();

	if (Engine.GameViewport.IsFullScreenViewport())
		ModeSpinnerVal = 0;
	else if (GetIsBorderlessWindow())
		ModeSpinnerVal = 1;
	else
		ModeSpinnerVal = 2;

	InitNewSysSettings();

	SetGraphicsValsFromCurrentSettings();
	
	Engine.GameViewport.GetViewportSize(ViewportSize);

	m_kInitGraphicsSettings.iMode = ModeSpinnerVal;
	m_kInitGraphicsSettings.iResolutionWidth = ViewportSize.X;
	m_kInitGraphicsSettings.iResolutionHeight = ViewportSize.Y;

	m_kInitGraphicsSettings.fGamma = GetGammaPercentage();
	m_kInitGraphicsSettings.bVSync = GetCurrentVSync();

	for (i = 0; i < NumGraphicsOptions; ++i)
	{
		m_kInitGraphicsSettings.GraphicsVals[i] = GraphicsVals[i];
	}	
}
simulated function RestoreInitGraphicsSettings(UIButton Button)
{
	local int i;

	if (!m_bAnyValueChanged) return;

	// Update the UI
	ModeSpinnerVal = m_kInitGraphicsSettings.iMode;
	SetSupportedResolutions();

	for (i = 0; i < NumGraphicsOptions; ++i)
	{
		GraphicsVals[i] = m_kInitGraphicsSettings.GraphicsVals[i];
	}

	// Update the UI per tab
	if(m_iCurrentTab == ePCTab_Video)
	{
		m_arrMechaItems[ePCTabVideo_Mode].Spinner.SetValue(m_VideoMode_Labels[ModeSpinnerVal]);
		m_arrMechaItems[ePCTabVideo_VSync].Checkbox.SetChecked(m_kInitGraphicsSettings.bVSync);
		m_arrMechaItems[ePCTabVideo_Gamma].Slider.SetPercent(m_kInitGraphicsSettings.fGamma);
		m_arrMechaItems[ePCTabVideo_MouseLock].Checkbox.SetChecked(m_kInitVideoSettings.bMouseLock);
		m_arrMechaItems[ePCTabVideo_FRSmoothing].Checkbox.SetChecked(m_kInitVideoSettings.bFRSmoothing);
	}
	else if (m_iCurrentTab == ePCTab_Graphics)
	{
		ApplyPresetState(true);
		SetPresetState();
	}

	// Update the actual system settings
	UpdateViewportNative(m_kInitGraphicsSettings.iResolutionWidth, m_kInitGraphicsSettings.iResolutionHeight, ModeSpinnerVal == 0, ModeSpinnerVal == 1 ? 1 : 0);
	UpdateVSyncNative(m_kInitGraphicsSettings.bVSync);
	UpdateGammaNative((m_kInitGraphicsSettings.fGamma * 0.01) * (GAMMA_HIGH - GAMMA_LOW) + GAMMA_LOW);
	ResetInitVideoSettings();

	// Reset any tracked change flags
	m_bAnyValueChanged = false;
	m_bResolutionChanged = false;
	m_GEngineValueChanged = false;
	m_SystemSettingsChanged = false;
	m_bGammaChanged = false;
}

simulated function SetPresetState()
{
	local int i;
	local int PresetIndex;
	local bool bPresetMatches;
	
	for (PresetIndex = 0; PresetIndex < GraphicsOptions[ePCGraphics_Preset].Values.length; PresetIndex++)
	{
		bPresetMatches = true;

		for (i = 0; i < NumGraphicsOptions; i++)
		{
			if (i != ePCGraphics_Preset)
			{
				if (GraphicsVals[i] != GraphicsOptions[i].Presets[PresetIndex])
				{
					bPresetMatches = false;
					break;
				}
			}
		}

		if (bPresetMatches)
		{
			break;
		}
	}

	if (!bPresetMatches)
	{
		m_arrMechaItems[ePCGraphics_Preset].Spinner.SetValue(m_strGraphicsSetting_Custom);
	}
	else
	{
		GraphicsVals[ePCGraphics_Preset] = PresetIndex;
		m_arrMechaItems[ePCGraphics_Preset].Spinner.SetValue(GraphicsOptions[ePCGraphics_Preset].Labels[PresetIndex]);
	}
}

simulated function ApplyPresetState(bool bCustom)
{
	local int kNewSetting;
	local int PresetIndex;	
	local int i;

	m_bApplyingPreset = true;

	PresetIndex = GraphicsVals[ePCGraphics_Preset];

	for (i = 0; i < NumGraphicsOptions; i++)
	{
		if (i != ePCGraphics_Preset)
		{
			kNewSetting = bCustom ? GraphicsVals[i] : GraphicsOptions[i].Presets[PresetIndex];
			if (GraphicsOptions[i].bSpinner)
			{
				SpinnerUpdated(m_arrMechaItems[i].Spinner, kNewSetting - GraphicsVals[i]);
			}
			else
			{
				m_arrMechaItems[i].Checkbox.SetChecked(kNewSetting > 0 ? true : false);
				CheckboxUpdated(m_arrMechaItems[i].Checkbox);
			}
		}
	}

	m_bApplyingPreset = false;
}

//=======================================================
//=======================================================
public function ResetMouseDevice()
{
	
}

simulated function OnReceiveFocus() 
{
	//reshow the gamma logo in case we're coming back from the credits
	//if( m_iCurrentTab == ePCTab_Video )
		//XComHUD(WorldInfo.GetALocalPlayerController().myHUD).SetGammaLogoDrawing(true);

	Show(); 
	
	NavHelp.ClearButtonHelp();
	NavHelp.AddBackButton(IgnoreChangesAndExit);
}	
simulated function OnLoseFocus()    
{
	//hide gamma logo so it does not overlap the credits
	//if( m_iCurrentTab == ePCTab_Video )
		//XComHUD(WorldInfo.GetALocalPlayerController().myHUD).SetGammaLogoDrawing(false);

	Hide(); 
	NavHelp.ClearButtonHelp();
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local string button;
	if( bShouldPlayGenericUIAudioEvents )
	{
		switch( cmd )
		{
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP:
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_DOUBLE_UP:
			`SOUNDMGR.PlaySoundEvent("Generic_Mouse_Click");
			break;
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_OVER:
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OVER:
			`SOUNDMGR.PlaySoundEvent("Play_Mouseover");
			break;
		}
	}

	if(cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP)
	{
		button = args[args.Length - 1];
		if(InStr(button, "Tab") != -1)
		{
			SetSelectedTab(int(Right(button, 1)));
		}
	}
}

simulated native function SaveGEngineConfig();

simulated function IgnoreChangesAndExit()
{	
	local TDialogueBoxData kDialogData;

	if (m_bAnyValueChanged && `XENGINE.IsGPUAutoDetectRunning() == false)
	{
		kDialogData.strText = m_strIgnoreChangesDialogue;
		kDialogData.fnCallback = ConfirmUserWantsToIgnoreChanges; 
		kDialogData.strCancel = m_strIgnoreChangesCancel;
		kDialogData.strAccept = m_strIgnoreChangesConfirm;	

		XComPresentationLayerBase(Owner).UIRaiseDialog(kDialogData);
	}
	else
	{
		ExitScreen();
	}
}
simulated function ConfirmUserWantsToIgnoreChanges( EUIAction eAction )
{
	if( eAction == eUIAction_Accept )
	{
		RestorePreviousProfileSettings();
		ExitScreen();
	}

	// Else, do nothing and leave the player sitting here on the Options Screen 
}
simulated public function RunGPUAutoDetectFromOptions(UIButton Button)
{
	// Force a change to the graphics tab
	if (m_iCurrentTab != ePCTab_Graphics) 
		SetSelectedTab(ePCTab_Graphics);

	Hide();
	`XENGINE.RunGPUAutoDetect(true, GPUAutoDetectFinished);
}
simulated public function GPUAutoDetectFinished()
{
	SetGraphicsValsFromCurrentSettings();
	ApplyPresetState(true);
	SetPresetState();
	m_bAnyValueChanged = false;
	Show();
}

simulated public function SaveAndExit(UIButton Button)
{
	if (m_bResolutionChanged)
	{
		UpdateViewportCheck();
		return;
	}

	SaveAndExitFinal();
}

simulated public function ViewCredits(UIButton Button)
{
	Hide();
	Movie.Pres.UICredits(false);
}

simulated public function SaveAndExitFinal()
{
	if (m_bAnyValueChanged)
	{
		`ONLINEEVENTMGR.SaveProfileSettings(true); // Fire off and exit -ttalley

		m_bSavingInProgress = true;
		//Hide(); //Hide the screen so we don't overlap the save icon
		ExitScreen();
	}
	else
	{
		// If we didn't save, we still need to call the callback to get out of here
		SaveComplete(true);
	}

	if( m_GEngineValueChanged )
		SaveGEngineConfig();

	if( m_SystemSettingsChanged )
	{
		ApplyNewSysSettings();
	}

	if( m_bGammaChanged )
	{
		SaveGamma();
	}
	
	XComHUD(WorldInfo.GetALocalPlayerController().myHUD).SetGammaLogoDrawing(false);
}
simulated public function SaveComplete(bool bWasSuccessful)
{
	m_bSavingInProgress = false;

	if( !bWasSuccessful )
	{
		SaveProfileFailedDialog();
	}

	m_bAnyValueChanged = false;
	`ONLINEEVENTMGR.ClearSaveProfileSettingsCompleteDelegate( SaveComplete );
	ExitScreen();
}
simulated function ExitScreen()
{	
	`XENGINE.ForceEndGPUAutoDetect();

	NavHelp.ClearButtonHelp();

	if( m_iCurrentTab == ePCTab_Video )
		XComHUD(WorldInfo.GetALocalPlayerController().myHUD).SetGammaLogoDrawing(false);
	m_kProfileSettings = none; 
	Movie.Stack.Pop(self);
	Movie.Pres.PlayUISound(eSUISound_MenuClose); 
}
simulated public function SaveProfileFailedDialog()
{
	local TDialogueBoxData kDialogData;

	kDialogData.strText = (WorldInfo.IsConsoleBuild(CONSOLE_Xbox360))? m_strSavingOptionsFailed360 : m_strSavingOptionsFailed;
	kDialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;

	XComPresentationLayerBase(Owner).UIRaiseDialog(kDialogData);
}

simulated public function OnUDPadUp()
{
	PlaySound( SoundCue'SoundUI.MenuScrollCue', true );
}


simulated public function OnUDPadDown()
{
	PlaySound( SoundCue'SoundUI.MenuScrollCue', true );
}

// -----------------------------------------------------------------
simulated function SetSelectedTab( int iSelect )
{
	// hack no graphics on PC
	if ( WorldInfo.IsConsoleBuild() )
	{
		if ( iSelect == 1 && m_iCurrentTab == 0 )
			iSelect = 2;
		else if ( iSelect == 1 && m_iCurrentTab == 2 )
			iSelect = 0;
	}

	//dont go to the same tab youve already selected
	if(m_iCurrentTab == iSelect)
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClickNegative);
		return;
	}

	m_iCurrentTab = iSelect; 

	// Wrap the ends
	if( m_iCurrentTab < 0 ) m_iCurrentTab = ePCTab_MAX - 1;
	if( m_iCurrentTab > ePCTab_MAX - 1 ) m_iCurrentTab = 0;

	/*
	if( m_iCurrentTab != ePCTab_Video )
	{
		XComHUD(WorldInfo.GetALocalPlayerController().myHUD).SetGammaLogoDrawing(false);
	}
	else
	{
		XComHUD(WorldInfo.GetALocalPlayerController().myHUD).SetGammaLogoDrawing(true);
	}
	*/

	GPUAutoDetectButton.Hide();
	switch(m_iCurrentTab)
	{
	case ePCTab_Video:
		SetVideoTabSelected();
		break;
	case ePCTab_Graphics:
		SetGraphicsTabSelected();
		GPUAutoDetectButton.Show();
		break;
	case ePCTab_Audio:
		SetAudioTabSelected();
		break;
	case ePCTab_Gameplay:
		SetGameplayTabSelected();
		break;
	case ePCTab_Interface:
		SetInterfaceTabSelected();
		break;
	}

	List.Navigator.SetSelected(m_arrMechaItems[0]);

	MC.FunctionNum("SetSelectedTab", m_iCurrentTab);

	if( bInputReceived == true )
	{
		Movie.Pres.PlayUISound(eSUISound_MenuSelect);
	}
}

// -----------------------------------------------------------------

simulated function AS_SetTitle( string title )
{
	Movie.ActionScriptVoid(MCPath$".SetTitle");
}

simulated function AS_SetTabData( string title0, string title1, string title2, string title3, string title4 )
{
	Movie.ActionScriptVoid(MCPath$".SetTabData");
}

function ResetMechaListItems()
{
	local int i;
	for( i = 0; i < NUM_LISTITEMS; i++ )
	{
		m_arrMechaItems[i].OnLoseFocus();
		m_arrMechaItems[i].Hide();
		m_arrMechaItems[i].BG.RemoveTooltip();
		m_arrMechaItems[i].DisableNavigation();
	}
}

function RenableMechaListItems(int maxItems)
{
	local int i;
	for( i = 0; i < maxItems; i++)
	{
		m_arrMechaItems[i].Show();
		m_arrMechaItems[i].EnableNavigation();
	}
}

//==============================================================================
//		CLEANUP:
//==============================================================================
simulated function OnRemoved()
{
	super.OnRemoved();
}

event Destroyed()
{
	ClearTimer('WatchForChanges');
	super.Destroyed();
	`ONLINEEVENTMGR.ClearSaveProfileSettingsCompleteDelegate( SaveComplete );
}


DefaultProperties
{
	m_iCurrentTab = -1;

	Package   = "/ package/gfxOptionsScreen/OptionsScreen";
	MCName      = "theScreen";
	LibID       = "OptionsScreen"

	InputState= eInputState_Evaluate;

	bAlwaysTick = true
	m_bSavingInProgress = false
	bConsumeMouseEvents=true
}
