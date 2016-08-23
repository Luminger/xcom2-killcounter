//---------------------------------------------------------------------------------------
//  FILE:    X2AbilityTemplate.uc
//  AUTHOR:  Joshua Bouscher
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
class X2AbilityTemplate extends X2DataTemplate
	implements(UIQueryInterfaceAbility)
	dependson(X2Camera)
	native(Core);

enum EAbilityHostility
{
	eHostility_Offensive,
	eHostility_Defensive,
	eHostility_Neutral,
	eHostility_Movement,
};

enum EConcealmentRule           //  Checked after the ability is activated to determine if the unit can remain concealed.
{
	eConceal_NonOffensive,      //  Always retain Concealment if the Hostility != Offensive (default behavior)
	eConceal_Always,            //  Always retain Concealment, period
	eConceal_Never,             //  Never retain Concealment, period
	eConceal_KillShot,          //  Retain concealment when killing a single (primary) target
	eConceal_Miss,              //  Retain concealment when the ability misses
	eConceal_MissOrKillShot,    //  Retain concealment when the ability misses or when killing a single (primary) target
};

enum ECameraFramingType
{
	eCameraFraming_Never,
	eCameraFraming_Always,
	eCameraFraming_IfNotNeutral
};

struct native UIAbilityStatMarkup
{
	var() int StatModifier;
	var() bool bForceShow;					// If true, this markup will display even if the modifier is 0
	var() localized string StatLabel;		// The user-friendly label associated with this modifier
	var() ECharStatType StatType;			// The stat type of this markup (if applicable)
	var() delegate<X2StrategyGameRulesetDataStructures.SpecialRequirementsDelegate> ShouldStatDisplayFn;	// A function to check if the stat should be displayed or not
};

var X2AbilityCharges            AbilityCharges;                     //  Used for configuring the number of charges a unit gets for this ability at tactical start.
var array<X2AbilityCost>        AbilityCosts;
var X2AbilityCooldown           AbilityCooldown;
var X2AbilityToHitCalc          AbilityToHitCalc;
var X2AbilityToHitCalc          AbilityToHitOwnerOnMissCalc;		// If !none, a miss on the main target will apply this chance to hit on the target's owner.
var array<X2Condition>          AbilityShooterConditions;
var array<X2Condition>          AbilityTargetConditions;
var array<X2Condition>          AbilityMultiTargetConditions;       //  if conditions are set here, multi targets use these to filter instead of AbilityTargetConditions
var protectedwrite array<X2Effect> AbilityTargetEffects;            //  effects which apply to the main target only
var protectedwrite array<X2Effect> AbilityMultiTargetEffects;       //  effects which apply to the multi targets only
var protectedwrite array<X2Effect> AbilityShooterEffects;           //  effects which always apply to the shooter, regardless of targets
var X2AbilityTargetStyle        AbilityTargetStyle;
var X2AbilityMultiTargetStyle   AbilityMultiTargetStyle;
var X2AbilityPassiveAOEStyle	AbilityPassiveAOEStyle;
var array<X2AbilityTrigger>     AbilityTriggers;
var bool                        bAllowFreeFireWeaponUpgrade;        //  if true, this ability will process the free fire weapon upgrade to spare an action point cost
var bool                        bAllowAmmoEffects;                  //  if true, equipped ammo will apply its effects to the target
var bool                        bAllowBonusWeaponEffects;           //  if true, the ability's weapon's bonus effects will be added to the target (in TypicalAbility_BuildGameState)
var bool						bCommanderAbility;
var bool                        bUseThrownGrenadeEffects;
var bool                        bUseLaunchedGrenadeEffects;
var bool						bHideWeaponDuringFire;				//  identify ability as a thrown weapon that should be hidden since it's replaced by a projectile during the fire process
var bool						bHideAmmoWeaponDuringFire;			//
var bool						bIsASuppressionEffect;				//	used to identify suppression type abilities that should use the modified spread during unified projectile processing
var array<AbilityEventListener> AbilityEventListeners;
var EAbilityHostility           Hostility;
var bool                        bAllowedByDefault;                  //  if true, this ability will be enabled by default. Otherwise the ability will have to be enabled before it is usable
var array<name>                 OverrideAbilities;                  //  if set, will replace the first matched ability if it would otherwise be given to a unit
var bool						bOverrideAim;
var bool						bUseSourceLocationZToAim;			//  if set, the unit will aim the attack at the same height as the weapon instead at the target location, must set bOverrideAim to use.
var bool                        bUniqueSource;                      //  the ability may only be attached to a unit from one source (see GatherUnitAbilitiesForInit on how that works)
var bool                        bOverrideWeapon;                    //  if OverrideAbility is set, the weapon from that ability will be used unless this field is set true.
var array<name>                 AdditionalAbilities;                //  when a unit is granted this ability, it will be granted all of these abilities as well
var array<name>					PrerequisiteAbilities;				//  if this ability is a modifier on another ability, its listed here. purely informational, mainly for Psi Op ability training.
var bool                        bStationaryWeapon;                  //  if the ability uses a cosmetic attached weapon (e.g. gremlin), don't move it to the target when the ability activates
var array<name>                 PostActivationEvents;               //  trigger these events after AbilityActivated is triggered (only when not interrupted) EventData=ability state, EventSource=owner unit state
var bool                        bRecordValidTiles;                  //  TypicalAbility_BuildGameState will record the multi target GetValidTilesForLocation in the result context's RelevantEffectTiles
var array<name>					AssociatedPassives;					//  Set of PurePassive abilities that the unit could have that would modify the behavior of this ability when the unit has them
var bool						bIsPassive;							//  Flag to identify this as a PurePassive ability later on
var bool						bCrossClassEligible;				//  Flag for soldier abilities eligible for AWC talent or training roulette
var EConcealmentRule            ConcealmentRule;
var bool                        bSilentAbility;                     //  Don't trigger sound when this ability is activated, regardless of ammo/damage rules.
var bool                        bCannotTeleport;                    // For pathing abilities, prevents ability to use teleport traversals.
var bool						bPreventsTargetTeleport;			// If set, this ability prevents the target from teleporting away.

var class<X2Action_Fire>        ActionFireClass;

var name                        FinalizeAbilityName;                // certain abilities (such as hack) work as a two step process. Specify the finalizing ability here.
var name                        CancelAbilityName;					// certain abilities (such as hack) work as a two step process. Specify the cancellation ability here.

var bool                        bCheckCollision;                    //  Limit affected area because of coliision.
var bool                        bAffectNeighboringTiles;            //  If need to do calculation to figure out what tiles are secondary tile
var bool                        bFragileDamageOnly;                 //  Damage fragile only objects.

var bool                        bCausesCheckFirstSightingOfEnemyGroup;  // If true, this ability will cause a CheckFirstSightingOfEnemyGroup on the associated unit

// The strategy requirements that must be met in order for this ability to be used in a tactical mission
var StrategyRequirement			Requirements;

//HUD specific items
var localized string            LocFriendlyName;                    // The localized, UI facing name the ability will have
var localized string			LocHelpText;                        // The localized, UI facing description that shows up in the Shot HUD
var localized string			LocLongDescription;
var localized string			LocPromotionPopupText;
var localized string            LocFlyOverText;
var localized string            LocMissMessage;
var localized string            LocHitMessage;
var localized string            LocFriendlyNameWhenConcealed;       // used by the shot HUD when the ability owner is concealed
var localized string            LocLongDescriptionWhenConcealed;    // long description used when ability owner is concealed (ability tooltip)
var localized string			LocDefaultPrimaryWeapon;			// used in passive effects to indicate the primary weapon for AWC abilities
var EAbilityIconBehavior        eAbilityIconBehaviorHUD;            // when should this ability appear in the HUD?
var array<name>                 HideIfAvailable;                    // if icon behavior is eAbilityIconBehavior_HideIfOtherAvailable, these are the abilities that makes it hide
var array<name>                 HideErrors;                         // if icon behavior is eAbilityIconBehavior_HideSpecificErrors, these are the ones to hide
var bool                        DisplayTargetHitChance;             // Indicates this ability's hit chance should be used in the UI as the hit chance on enemies where appropriate.
var bool                        bUseAmmoAsChargesForHUD;            // The ability's weapon's ammo will be displayed as the number of charges available for the ability
var int                         iAmmoAsChargesDivisor;              // Divide the ammo amount by this number to come up with the correct number of charges to be displayed
var string                      IconImage;                          // This string identifies which icon the ability will use in the ability container. Can be empty if bAbilityVisibleInHUD is FALSE
var string                      AbilityIconColor;                   // background color override for the icon, specified in the RGB hex format "FFFFFF"
var bool                        bHideOnClassUnlock;                 // Prevents this ability from showing up in the popup that appears when a soldier gains a new class
var int 	                    ShotHUDPriority;                    // This number is used to sort the icons position in the Ability Container in Tactical HUD. 0 shows up leftmost. 
var bool						bNoConfirmationWithHotKey;			// True if activation via hotkey should skip the confirmation UI
var bool                        bLimitTargetIcons;                  // Will cause the UI to display only valid target icons when this ability is selected.
var bool                        bBypassAbilityConfirm;              // Will force the ability to trigger automatically without requiring the user to click the confirm button.
var Name			            AbilitySourceName;                  // Indicates the source of this ability (used to color the icon)
var string                      AbilityConfirmSound;                // Sound to play when choosing to activate the ability in the shot HUD (UI confirmation sound)
var bool						bDontDisplayInAbilitySummary;		// If true, this ability template will never be displayed as part of an ability summary

//Visualization parameters
var name                        CustomFireAnim;
var name						CustomFireKillAnim;
var name						CustomMovingFireAnim;
var name						CustomMovingFireKillAnim;
var name						CustomMovingTurnLeftFireAnim;
var name						CustomMovingTurnLeftFireKillAnim;
var name						CustomMovingTurnRightFireAnim;
var name						CustomMovingTurnRightFireKillAnim;
var name                        CustomSelfFireAnim;
var bool                        bShowActivation;                    // If true, ability will automatically show its name over the activating unit's head when used.
var bool                        bShowPostActivation;                // If true, ability will automatically show its name over the activating unit's head after the end of the actions and the camera has panned back.
var bool                        bSkipFireAction;                    // If true, ability will not exit cover/fire/enter cover when activated.
var bool						bSkipExitCoverWhenFiring;			// If true, ability will not exit cover when firing is activated.
var bool						bSkipPerkActivationActions;			// If true, ability will not automatically include perk actions when activated (but will still do the perk duration ending action).
var bool                        bSkipMoveStop;                      // If true, typical abilities with embedded moves will not play a stop anim before the fire anim. This should be used for custom moving attacks et cetera
var bool						bDisplayInUITooltip;				// Will only appear in UI info tooltips if this is true 
var bool						bDisplayInUITacticalText;			// Will only appear in UI tactical text tooltip if this is true 
var name                        ActivationSpeech;					//  TypicalAbility_BuildVisualization will automatically use these
var name                        SourceHitSpeech;				    //  TypicalAbility_BuildVisualization will automatically use these
var name                        TargetHitSpeech;					//  TypicalAbility_BuildVisualization will automatically use these
var name                        SourceMissSpeech;					//  TypicalAbility_BuildVisualization will automatically use these
var name                        TargetMissSpeech;					//  TypicalAbility_BuildVisualization will automatically use these

var class<X2TargetingMethod>    TargetingMethod;                    // UI interaction class. Specifies how the target is actually selected by the user
var bool						SkipRenderOfAOETargetingTiles;		// Modifier to UI interaction class
var bool						SkipRenderOfTargetingTemplate;		// Modifier to UI interaction class
var bool						bOverrideMeleeDeath;				// If true it will play a normal death instead of melee death (only effects melee weapons)
var bool                        bOverrideVisualResult;              // Use the below value if this is true
var EAbilityHitResult           OverrideVisualResult;               // Use this value when checking IsVisualHit instead of the context's actual result

var string                      MeleePuckMeshPath;                  // Path of the static mesh to use as the end of path puck when targeting this ability. Only applies to Melee

//Camera settings
var string                      CinescriptCameraType;               // Type of camera to play when this ability is visualized. See defaultcameras.ini
var ECameraPriority				CameraPriority;						// Override for the priority of the camera used to frame this ability

// note: don't check the following two things directly, you should normally check XComGameStateContext_Ability::ShouldFrameAbility()
var bool                        bUsesFiringCamera;                  // Used by the UI / targeting code to know whether the targeting camera should be popped from the camera stack, or left on for the firing camera to use
var ECameraFramingType          FrameAbilityCameraType;             // Indicates how this ability will use a frame ability camera to look at the source of the ability when it is used
var bool                        bFrameEvenWhenUnitIsHidden;         // Indicates whether this ability will use a frame ability camera to look at the source of the ability when it is used if the unit is not visible (i.e. in fog)

var name						TwoTurnAttackAbility;				// Name of attack ability if this is a two-turn attack - used for AI.

var int                         DefaultKeyBinding;                  // Number as found in UIUtilities_Input for the default keyboard binding

var array<UIAbilityStatMarkup>	UIStatMarkups;						//  Values to display in the UI to modify soldier stats

var delegate<BuildNewGameStateDelegate> BuildNewGameStateFn;            // This method converts an input context into a game state
var delegate<BuildInterruptGameStateDelegate> BuildInterruptGameStateFn;// Responsible for creating 'interrupted' and 'resumed' game states if an ability can be interrupted
var delegate<BuildVisualizationDelegate> BuildVisualizationFn;          // This method converts a game state into a set of visualization tracks
var delegate<BuildVisualizationSyncDelegate> BuildAppliedVisualizationSyncFn;		// This method converts a game load state into a set of visualization tracks
var delegate<BuildVisualizationSyncDelegate> BuildAffectedVisualizationSyncFn;		// This method converts a game load state into a set of visualization tracks
var delegate<OnSoldierAbilityPurchased> SoldierAbilityPurchasedFn;
var delegate<OnVisualizationTrackInserted> VisualizationTrackInsertedFn;			// This method allows a visualization track that has been brought forward to modify existing tracks after being inserted into the visualization array.
var delegate<ModifyActivatedAbilityContext> ModifyNewContextFn;
var delegate<DamagePreviewDelegate> DamagePreviewFn;

delegate XComGameState BuildNewGameStateDelegate(XComGameStateContext Context);
delegate XComGameState BuildInterruptGameStateDelegate(XComGameStateContext Context, int InterruptStep, EInterruptionStatus InterruptionStatus);
delegate BuildVisualizationDelegate(XComGameState VisualizeGameState, out array<VisualizationTrack> OutVisualizationTracks);
delegate BuildVisualizationSyncDelegate(name EffectName, XComGameState VisualizeGameState, out VisualizationTrack BuildTrack);
delegate OnSoldierAbilityPurchased(XComGameState NewGameState, XComGameState_Unit UnitState);
delegate OnVisualizationTrackInserted(out array<VisualizationTrack> VisualizationTracks, XComGameStateContext_Ability Context, int OuterIndex, int InnerIndex);
delegate ModifyActivatedAbilityContext(XComGameStateContext Context);
delegate bool DamagePreviewDelegate(XComGameState_Ability AbilityState, StateObjectReference TargetRef, out WeaponDamageValue MinDamagePreview, out WeaponDamageValue MaxDamagePreview, out int AllowsShield);

function InitAbilityForUnit(XComGameState_Ability AbilityState, XComGameState_Unit UnitState, XComGameState NewGameState)
{
	if (AbilityCharges != none)
		AbilityState.iCharges = AbilityCharges.GetInitialCharges(AbilityState, UnitState);
}

function XComGameState_Ability CreateInstanceFromTemplate(XComGameState NewGameState)
{
	local XComGameState_Ability Ability;	

	Ability = XComGameState_Ability(NewGameState.CreateStateObject(class'XComGameState_Ability'));
	Ability.OnCreation(self);

	return Ability;
}

function AddTargetEffect(X2Effect Effect)
{
	SetEffectName(Effect);
	AbilityTargetEffects.AddItem(Effect);
}

function AddMultiTargetEffect(X2Effect Effect)
{
	SetEffectName(Effect);
	AbilityMultiTargetEffects.AddItem(Effect);
}

function AddShooterEffect(X2Effect Effect)
{
	SetEffectName(Effect);
	AbilityShooterEffects.AddItem(Effect);
}

private function SetEffectName(X2Effect Effect)
{
	if (Effect.IsA('X2Effect_Persistent'))
	{
		if (X2Effect_Persistent(Effect).EffectName == '')
			X2Effect_Persistent(Effect).EffectName = DataName;
	}	
}

function AddAbilityEventListener(name EventID, delegate<X2TacticalGameRulesetDataStructures.AbilityEventDelegate> EventFn, optional EventListenerDeferral Deferral = ELD_Immediate, optional AbilityEventFilter Filter = eFilter_Unit)
{
	local AbilityEventListener Listener;

	Listener.EventID = EventID;
	Listener.EventFn = EventFn;
	Listener.Deferral = Deferral;
	Listener.Filter = Filter;
	AbilityEventListeners.AddItem(Listener);
}

simulated function AddShooterEffectExclusions(optional array<name> SkipExclusions)
{
	local X2Condition_UnitEffects UnitEffects;

	UnitEffects = GetShooterEffectExclusions(SkipExclusions);
	if (UnitEffects.ExcludeEffects.Length > 0)
		AbilityShooterConditions.AddItem(UnitEffects);
}

simulated function X2Condition_UnitEffects GetShooterEffectExclusions(optional array<name> SkipExclusions)
{
	local X2Condition_UnitEffects UnitEffects;

	UnitEffects = new class'X2Condition_UnitEffects';
	
	if (SkipExclusions.Length == 0 || SkipExclusions.Find(class'X2AbilityTemplateManager'.default.DisorientedName) == INDEX_NONE)
		UnitEffects.AddExcludeEffect(class'X2AbilityTemplateManager'.default.DisorientedName, 'AA_UnitIsDisoriented');
	
	if (SkipExclusions.Length == 0 || SkipExclusions.Find(class'X2StatusEffects'.default.BurningName) == INDEX_NONE)
		UnitEffects.AddExcludeEffect(class'X2StatusEffects'.default.BurningName, 'AA_UnitIsBurning');
	
	if (SkipExclusions.Length == 0 || SkipExclusions.Find(class'X2Ability_CarryUnit'.default.CarryUnitEffectName) == INDEX_NONE)
		UnitEffects.AddExcludeEffect(class'X2Ability_CarryUnit'.default.CarryUnitEffectName, 'AA_CarryingUnit');

	if (SkipExclusions.Length == 0 || SkipExclusions.Find(class'X2AbilityTemplateManager'.default.BoundName) == INDEX_NONE)
		UnitEffects.AddExcludeEffect(class'X2AbilityTemplateManager'.default.BoundName, 'AA_UnitIsBound');

	if (SkipExclusions.Length == 0 || SkipExclusions.Find(class'X2AbilityTemplateManager'.default.ConfusedName) == INDEX_NONE)
		UnitEffects.AddExcludeEffect(class'X2AbilityTemplateManager'.default.ConfusedName, 'AA_UnitIsConfused');

	//Typically, stunned units cannot act because the stun removes their action points. That doesn't handle free actions, though.
	if (SkipExclusions.Length == 0 || SkipExclusions.Find(class'X2AbilityTemplateManager'.default.StunnedName) == INDEX_NONE)
		UnitEffects.AddExcludeEffect(class'X2AbilityTemplateManager'.default.StunnedName, 'AA_UnitIsStunned');

	return UnitEffects;
}

simulated function name CanAfford(XComGameState_Ability kAbility, optional XComGameState_Unit ActivatingUnit)
{
	local X2AbilityCost Cost;
	local name AvailableCode;

	if (ActivatingUnit == None)
		ActivatingUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kAbility.OwnerStateObject.ObjectID));

	foreach AbilityCosts(Cost)
	{
		AvailableCode = Cost.CanAfford(kAbility, ActivatingUnit);
		if (AvailableCode != 'AA_Success')
			return AvailableCode;
	}
	return 'AA_Success';
}

simulated function bool IsFreeCost(XComGameState_Ability kAbility)
{
	local X2AbilityCost Cost;

	foreach AbilityCosts(Cost)
	{
		if(!Cost.bFreeCost)
		{
			return false;
		}
	}

	return true;
}

simulated function bool WillEndTurn(XComGameState_Ability kAbility, XComGameState_Unit kShooter)
{
	local X2AbilityCost Cost;
	local X2AbilityCost_ActionPoints ActionPointCost;
	local int TotalPointCost;

	TotalPointCost = 0;

	foreach AbilityCosts(Cost)
	{
		ActionPointCost = X2AbilityCost_ActionPoints(Cost);
		if( ActionPointCost != None )
		{
			if( ActionPointCost.ConsumeAllPoints(kAbility, kShooter) )
			{
				return true;
			}
			else
			{
				TotalPointCost += ActionPointCost.GetPointCost(kAbility, kShooter);
			}
		}
	}

	return TotalPointCost >= kShooter.NumAllActionPoints() + kShooter.NumAllReserveActionPoints();
}

// The Revalidation flag is set to true when conditions are being rechecked after an ability has been activated, but interrupted. This
// allows conditions that do not require revalidation to be skipped
simulated native function name CheckShooterConditions(XComGameState_Ability kAbility, XComGameState_Unit kShooter, optional bool Revalidation);
simulated native function name CheckTargetConditions(XComGameState_Ability kAbility, XComGameState_Unit kShooter, XComGameState_BaseObject kTarget, optional bool Revalidation);
simulated native function name CheckMultiTargetConditions(XComGameState_Ability kAbility, XComGameState_Unit kShooter, XComGameState_BaseObject kTarget);

// For now NewGameState is used only to add extra GameStates outside of the passed parameters, which get added to the NewGameState higher up.
simulated function ApplyCost(XComGameStateContext_Ability AbilityContext, XComGameState_Ability kAbility, XComGameState_BaseObject AffectState, XComGameState_Item AffectWeapon, XComGameState NewGameState)
{
	local X2AbilityCost Cost;	
	local XComGameState_Unit UnitState;
	local array<X2WeaponUpgradeTemplate> WeaponUpgrades;
	local bool bFreeFire;
	local int i;
	local bool bHadActionPoints, bHadAbilityCharges;
	local XComGameState_Effect EffectState;
	local StateObjectReference EffectRef;
	local XComGameStateHistory History;

	local array<name> PreviousActionPoints, PreviousReservePoints;

	History = `XCOMHISTORY;
	UnitState = XComGameState_Unit(History.GetGameStateForObjectID(AbilityContext.InputContext.SourceObject.ObjectID));

	if (`CHEATMGR != none && `CHEATMGR.bUnlimitedAmmo && UnitState.GetTeam() == eTeam_XCom)
	{
		return;
	}

	bHadAbilityCharges = kAbility.GetCharges() > 0;

	UnitState = XComGameState_Unit(AffectState);
	if (UnitState != none)
	{		
		PreviousActionPoints = UnitState.ActionPoints;
		bHadActionPoints = PreviousActionPoints.Length > 0;
		PreviousReservePoints = UnitState.ReserveActionPoints;
	}
	if (AffectWeapon != none)
	{		
		if (!UnitState.bGotFreeFireAction)
		{
			WeaponUpgrades = AffectWeapon.GetMyWeaponUpgradeTemplates();
			for (i = 0; i < WeaponUpgrades.Length; ++i)
			{
				if (WeaponUpgrades[i].FreeFireCostFn != none && WeaponUpgrades[i].FreeFireCostFn(WeaponUpgrades[i], kAbility))
				{
					bFreeFire = true;
					break;
				}
			}
		}
	}
	foreach AbilityCosts(Cost)
	{		
		if (bFreeFire)
		{
			if (Cost.IsA('X2AbilityCost_ActionPoints') && !X2AbilityCost_ActionPoints(Cost).bFreeCost)
			{
				UnitState.bGotFreeFireAction = true;
				continue;
			}
			if (Cost.IsA('X2AbilityCost_ReserveActionPoints') && !X2AbilityCost_ReserveActionPoints(Cost).bFreeCost)
			{
				UnitState.bGotFreeFireAction = true;
				continue;
			}
		}
		Cost.ApplyCost(AbilityContext, kAbility, AffectState, AffectWeapon, NewGameState);
	}

	if (bFreeFire && UnitState.bGotFreeFireAction) //If we just got a free-fire action, show it after the visualization
		AbilityContext.PostBuildVisualizationFn.AddItem(kAbility.FreeFire_PostBuildVisualization);

	if (AbilityCooldown != none)
	{
		if (`CHEATMGR == none || !`CHEATMGR.Outer.bGodMode)
		{
			AbilityCooldown.ApplyCooldown(kAbility, AffectState, AffectWeapon, NewGameState);
		}
	}

	foreach UnitState.AffectedByEffects(EffectRef)
	{
		EffectState = XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID));
		if (EffectState != none)
		{
			if (EffectState.GetX2Effect().PostAbilityCostPaid(EffectState, AbilityContext, kAbility, UnitState, AffectWeapon, NewGameState, PreviousActionPoints, PreviousReservePoints))
				break;
		}
	}

	if (bHadActionPoints && UnitState.NumAllActionPoints() == 0)
	{
		`XEVENTMGR.TriggerEvent('ExhaustedActionPoints', UnitState, UnitState, NewGameState);
	}

	if (bHadAbilityCharges && kAbility.GetCharges() <= 0)
	{
		`XEVENTMGR.TriggerEvent('ExhaustedAbilityCharges', kAbility, UnitState, NewGameState);
	}
}

function bool TargetEffectsDealDamage( XComGameState_Item SourceWeapon, XComGameState_Ability Ability )
{
	local X2Effect Effect;
	local X2GrenadeTemplate GrenadeTemplate;
	local array<X2Effect> MultiTargetEffects;

	foreach AbilityTargetEffects( Effect )
	{
		if (Effect.bAppliesDamage)
		{
			return true;
		}
	}

	if (bUseLaunchedGrenadeEffects)
	{
		GrenadeTemplate = X2GrenadeTemplate( SourceWeapon.GetLoadedAmmoTemplate( Ability ) );
		MultiTargetEffects = GrenadeTemplate.LaunchedGrenadeEffects;
	}
	else if (bUseThrownGrenadeEffects)
	{
		GrenadeTemplate = X2GrenadeTemplate( SourceWeapon.GetMyTemplate( ) );
		MultiTargetEffects = GrenadeTemplate.ThrownGrenadeEffects;
	}
	else
	{
		MultiTargetEffects = AbilityMultiTargetEffects;
	}

	foreach MultiTargetEffects( Effect )
	{
		if (Effect.bAppliesDamage)
		{
			return true;
		}
	}

	return false;
}

function bool HasTrigger(name TriggerClass)
{
	local int i;

	for (i = 0; i < AbilityTriggers.Length; ++i)
	{
		if (AbilityTriggers[i].IsA(TriggerClass))
		{
			return true;
		}
	}

	return false;
}

function bool ValidateTemplate(out string strError)
{
	local int i;
	local X2AbilityTemplateManager Manager;

	if (AbilityTargetStyle == none)
	{
		strError = "missing Target Style";
		return false;
	}
	if (AbilityTriggers.Length == 0)
	{
		strError = "no Triggers";
		return false;
	}
	for (i = 0; i < AbilityTriggers.Length; ++i)
	{
		if (AbilityTriggers[i].IsA('X2AbilityTrigger_PlayerInput'))
		{
			if (BuildVisualizationFn == none)
			{
				strError = "player triggered ability has no visualization";
				return false;
			}
		}
	}
	if (BuildNewGameStateFn == none)
	{
		strError = "missing BuildNewGameStateFn";
		return false;
	}
	if (OverrideAbilities.Length > 0)
	{
		Manager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
		for (i = 0; i < OverrideAbilities.Length; ++i)
		{
			if (Manager.FindAbilityTemplate(OverrideAbilities[i]) == none)
			{
				strError = "specified OverrideAbilities[" $ i $ "]" @ OverrideAbilities[i] @ "does not exist";
				return false;
			}
		}
	}
	if (AdditionalAbilities.Length > 0)
	{
		if (Manager == none)
			Manager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();
		for (i = 0; i < AdditionalAbilities.Length; ++i)
		{
			if (Manager.FindAbilityTemplate(AdditionalAbilities[i]) == none)
			{
				strError = "specified AdditionalAbility" @ AdditionalAbilities[i] @ "does not exist";
				return false;
			}
		}
	}
	
	if (!ValidateEffectList(AbilityShooterEffects, strError)) return false;
	if (!ValidateEffectList(AbilityTargetEffects, strError)) return false;
	if (!ValidateEffectList(AbilityMultiTargetEffects, strError)) return false;

	return true;
}

function bool ValidateEffectList(const out array<X2Effect> Effects, out string strError)
{
	local X2Effect EffectIter;
	local name DamageType;
	local X2DamageTypeTemplate DamageTypeTemplate;
	local X2ItemTemplateManager ItemTemplateManager;

	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	foreach Effects(EffectIter)
	{
		foreach EffectIter.DamageTypes(DamageType)
		{
			DamageTypeTemplate = ItemTemplateManager.FindDamageTypeTemplate(DamageType);
			if (DamageTypeTemplate == none)
			{
				strError = "Effect" @ EffectIter @ "has unknown damage type" @ DamageType;
				return false;
			}
		}
	}

	return true;
}

simulated function string GetExpandedDescription(XComGameState_Ability AbilityState, XComGameState_Unit StrategyUnitState, bool bUseLongDescription, XComGameState CheckGameState)
{
	local X2AbilityTag AbilityTag;
	local string RetStr, ExpandStr;
	local XComGameState_Unit UnitState;

	if (bUseLongDescription)
		ExpandStr = LocLongDescription;
	else
		ExpandStr = LocHelpText;

	if (AbilityState != none)
	{		
		if (LocLongDescriptionWhenConcealed != "")
		{
			UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AbilityState.OwnerStateObject.ObjectID));
			if (UnitState != none && UnitState.IsConcealed())
				ExpandStr = LocLongDescriptionWhenConcealed;
		}
	}
	AbilityTag = X2AbilityTag(`XEXPANDCONTEXT.FindTag("Ability"));
	AbilityTag.ParseObj = AbilityState == None ? self : AbilityState;
	AbilityTag.StrategyParseObj = StrategyUnitState;
	AbilityTag.GameState = CheckGameState;
	RetStr = `XEXPAND.ExpandString(ExpandStr);
	AbilityTag.ParseObj = none;
	AbilityTag.StrategyParseObj = none;
	return RetStr;
}

simulated function string GetMyHelpText(optional XComGameState_Ability AbilityState, optional XComGameState_Unit UnitState, optional XComGameState CheckGameState)
{
	return GetExpandedDescription(AbilityState, UnitState, false, CheckGameState);
}

simulated function string GetMyLongDescription(optional XComGameState_Ability AbilityState, optional XComGameState_Unit UnitState, optional XComGameState CheckGameState)
{
	return GetExpandedDescription(AbilityState, UnitState, true, CheckGameState);
}

simulated function bool HasLongDescription()
{
	return LocLongDescription != "";
}

simulated function string GetExpandedPromotionPopupText()
{
	local X2AbilityTag AbilityTag;
	local string RetStr;

	AbilityTag = X2AbilityTag(`XEXPANDCONTEXT.FindTag("Ability"));
	AbilityTag.ParseObj = self;
	RetStr = `XEXPAND.ExpandString(LocPromotionPopupText);
	AbilityTag.ParseObj = none;
	return RetStr;
}

simulated function UISummary_Ability GetUISummary_Ability(optional XComGameState_Unit UnitState)
{
	local UISummary_Ability Data; 

	Data.Name = LocFriendlyName; 
	if( Data.Name == "" ) Data.Name = "MISSING NAME:" @ string(Name); // Use the instance name, for debugging. 
	
	if( HasLongDescription() )
		Data.Description = GetMyLongDescription(, UnitState);
	else
		Data.Description = GetMyHelpText(, UnitState);
	
	if( Data.Description == "" )
		Data.Description = "MISSING BOTH LONG DESCRIPTION AND HELP TEXT.";

	Data.Icon = IconImage; 

	return Data; 
}

simulated function int GetUISummary_HackingBreakdown(out UIHackingBreakdown kBreakdown, int TargetID)
{
	return -1;
}

simulated function bool IsMelee()
{
	local X2AbilityToHitCalc_StandardAim StandardAimHitCalc;
	local bool bIsMelee;

	bIsMelee = false;
	StandardAimHitCalc = X2AbilityToHitCalc_StandardAim(AbilityToHitCalc);
	if( StandardAimHitCalc != None )
	{
		bIsMelee = StandardAimHitCalc.bMeleeAttack;
	}

	return bIsMelee;
}

simulated function bool ShouldPlayMeleeDeath()
{
	return IsMelee() && bOverrideMeleeDeath == false;
}

function SetUIStatMarkup(String InLabel,
	optional ECharStatType InStatType = eStat_Invalid,
	optional int Amount = 0,
	optional bool ForceShow = false,
	optional delegate<X2StrategyGameRulesetDataStructures.SpecialRequirementsDelegate> ShowUIStatFn)
{
	local UIAbilityStatMarkup StatMarkup; 
	local int Index;

	// Check to see if a modification for this stat already exists in UIStatMarkups
	Index = UIStatMarkups.Find('StatType', InStatType);
	if (Index != INDEX_NONE)
	{
		UIStatMarkups.Remove(Index, 1); // Remove the old stat markup
	}

	StatMarkup.StatLabel = InLabel;
	StatMarkup.StatModifier = Amount;
	StatMarkup.StatType = InStatType;
	StatMarkup.bForceShow = ForceShow;
	StatMarkup.ShouldStatDisplayFn = ShowUIStatFn;

	UIStatMarkups.AddItem(StatMarkup);
}

function int GetUIStatMarkup(ECharStatType Stat)
{
	local delegate<X2StrategyGameRulesetDataStructures.SpecialRequirementsDelegate> ShouldStatDisplayFn;
	local int Index;

	for (Index = 0; Index < UIStatMarkups.Length; ++Index)
	{
		ShouldStatDisplayFn = UIStatMarkups[Index].ShouldStatDisplayFn;
		if (ShouldStatDisplayFn != None && !ShouldStatDisplayFn())
		{
			continue;
		}

		if (UIStatMarkups[Index].StatType == Stat)
		{
			return UIStatMarkups[Index].StatModifier;
		}
	}

	return 0;
}

DefaultProperties
{
	ShotHUDPriority = -1;	
	bNoConfirmationWithHotKey = false;
	iAmmoAsChargesDivisor = 1
	Hostility = eHostility_Offensive
	CameraPriority = eCameraPriority_CharacterMovementAndFraming //Default to movement type priority

	TargetingMethod = class'X2TargetingMethod_TopDown'
	bDisplayInUITooltip = true
	bDisplayInUITacticalText = true
	FrameAbilityCameraType=eCameraFraming_IfNotNeutral
	bFrameEvenWhenUnitIsHidden=false
	DefaultKeyBinding = -1;

	bAllowedByDefault = true

	ActionFireClass=class'X2Action_Fire'
	bCausesCheckFirstSightingOfEnemyGroup=false
}
