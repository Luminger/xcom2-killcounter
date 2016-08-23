class XComWeapon extends Weapon
	DependsOn(XComAnimNodeBlendDynamic)
	native(Weapon);

enum EWeaponAnimIdleState
{
	WS_UnEquipped,
	WS_Lowered,
	WS_Raised
};

enum EWeaponType
{
	WAP_Rifle,
	WAP_Pistol,
	WAP_Unarmed,
	WAP_Rocket,
	WAP_MiniGun,
	WAP_Grapple,
	WAP_Default,
	WAP_Turret,
	WAP_MecLeftArm,
	WAP_MecRightArm
};

/** sound to play when the weapon is fired */
var(Sounds)	array<SoundCue>	WeaponFireSnd;
var() ParticleSystemComponent WeaponFlashEffect;

var XGWeapon				m_kGameWeapon;		// reference to our GameCore data
var XComUnitPawnNativeBase  m_kPawn;       

// Tells the WeaponState nodes in the animtree where we want to be in our animation
//var protected EWeaponAnimIdleState		AnimIdleState;

// Active WeaponState nodes find this and inject the animation instantly before returning to idle state
//var	protected EAnimWeapon			PendingPlayAnim;

//var EFiringMode	eFireMode;

var() Name DefaultSocket<ToolTip="Socket the weapon should start in on the unit">;

var XComAnimNodeBlendDynamic DynamicNode;
var XComAnimNodeBlendDynamic AdditiveDynamicNode;
var AnimNodeAdditiveBlending AdditiveNode;
var AnimNodeAimOffset AimOffset;
var bool			  AimEnabled;

var() XComWeaponComponent WeaponComponent;

var() X2UnifiedProjectile DefaultProjectileTemplate<ToolTip="This unified projectile template will be used when this weapon fires regardless of attachments, ammo, etc">;

var() editinline array<AnimNotify_PlayParticleEffect> m_arrParticleEffects<ToolTip = "Particle Effects to play upon spawning">;

// Jan 7, 2010 MHU - Allows us to specify a custom animset for the unit pawn specific to this weapon.
var()	array<AnimSet> CustomUnitPawnAnimsets;
var()   array<AnimSet> CustomUnitPawnAnimsetsFemale;
var()   array<AnimSet> CustomUnitPawnFlightAnimsets;
var()	array<AnimSet> CustomTankPawnAnimsets;
var()   array<AnimSet> CustomTankPawnFlightAnimsets;

// March 5, 2010 MHU - Allows us to specify the correct weapon aim profile to use for this weapon.
var()	EWeaponType  WeaponAimProfileType;

/** This allows the weapon to set a custom fire animation on the unit firing it. */
var() name	        WeaponFireAnimSequenceName;
var() name			WeaponFireKillAnimSequenceName;
var() name			WeaponSuppressionFireAnimSequenceName;
var() name			WeaponMoveEndFireAnimSequenceName;
var() name			WeaponMoveEndFireKillAnimSequenceName;
var() name			WeaponMoveEndTurnLeftFireAnimSequenceName;
var() name			WeaponMoveEndTurnLeftFireKillAnimSequenceName;
var() name			WeaponMoveEndTurnRightFireAnimSequenceName;
var() name			WeaponMoveEndTurnRightFireKillAnimSequenceName;

var() bool			bOverrideMeleeDeath; // If true it will play a normal death instead of melee death (only effects melee weapons)

/** Collateral Damage Support - Specifies the anmimation to use when firing this weapon as part of a collateral damage ability */
var() name          CollateralDamageAnimSequenceName;
/** Collateral Damage Support - Specifies the collateral damage effect so use when this weapon is fired */
var() ParticleSystem CollateralDamageAreaFX;

//Weapon Sheath support - additional mesh that stays attached to the pawn even as the weapon animates
var() editinline MeshComponent SheathMesh < ToolTip = "Additional mesh, visible when the weapon is equipped" > ;
var() Name SheathSocket < ToolTip = "Socket to attach the sheath mesh" > ;

// If true, we're previewing the aiming of this weapon
var bool bPreviewAim;

// Effects specifically for the 'flush' ability - this ability doesn't rely on projectiles or any other existing 
// system to do its effects.
var() editinline EffectCue FlushAttachEffect<ToolTip="Attaches this effect if the weapon is used to 'flush' enemies">;
var() array<ELocation> FlushAttachSockets<ToolTip="The flush effect will be attached to these sockets">;

var() array<Texture2D> UITextures<Tooltip="Any required UI textures, this makes a reference so the cooker will bring them in">;

var() const array<Object> AdditionalResources<ToolTip="Additional resources that need to be loaded for this weapon.">;

var bool bCalcWeaponFireMiss;

var bool bFakeProjectileTarget;
var vector vFakeProjectileTarget;

//  jbouscher: mostly copied from Weapon.uc
simulated function ImpactInfo CalcWeaponFire(vector StartTrace, vector EndTrace, optional out array<ImpactInfo> ImpactList, optional vector Extent)
{
	local vector			HitLocation, HitNormal;
	local Actor				HitActor;
	local TraceHitInfo		HitInfo;
	local ImpactInfo		CurrentImpact;
	local bool				bOldBlockActors, bOldCollideActors;

	if (!bCalcWeaponFireMiss)
	{
		return super.CalcWeaponFire(StartTrace, EndTrace, ImpactList, Extent);
	}
	
	// Perform trace to retrieve hit info
	HitActor = `XTRACEMGR.XTrace(eXTrace_NoPawns, HitLocation, HitNormal, EndTrace, StartTrace, Extent, HitInfo);
		//GetTraceOwner().Trace(HitLocation, HitNormal, EndTrace, StartTrace, TRUE, Extent, HitInfo, TRACEFLAG_Bullet);

	// If we didn't hit anything, then set the HitLocation as being the EndTrace location
	if( HitActor == None )
	{
		HitLocation	= EndTrace;
	}

	// Convert Trace Information to ImpactInfo type.
	CurrentImpact.HitActor		= HitActor;
	CurrentImpact.HitLocation	= HitLocation;
	CurrentImpact.HitNormal		= HitNormal;
	CurrentImpact.RayDir		= Normal(EndTrace-StartTrace);
	CurrentImpact.StartTrace	= StartTrace;
	CurrentImpact.HitInfo		= HitInfo;

	// Add this hit to the ImpactList
	ImpactList[ImpactList.Length] = CurrentImpact;

	// check to see if we've hit a trigger.
	// In this case, we want to add this actor to the list so we can give it damage, and then continue tracing through.
	if( HitActor != None )
	{
		if (PassThroughDamage(HitActor))
		{
			// disable collision temporarily for the actor we can pass-through
			HitActor.bProjTarget = false;
			bOldCollideActors = HitActor.bCollideActors;
			bOldBlockActors = HitActor.bBlockActors;
			if (HitActor.IsA('Pawn'))
			{
				// For pawns, we need to disable bCollideActors as well
				HitActor.SetCollision(false, false);

				// recurse another trace
				CalcWeaponFire(HitLocation, EndTrace, ImpactList, Extent);
			}
			else
			{
				if( bOldBlockActors )
				{
					HitActor.SetCollision(bOldCollideActors, false);
				}
				// recurse another trace and override CurrentImpact
				CurrentImpact = CalcWeaponFire(HitLocation, EndTrace, ImpactList, Extent);
			}

			// and reenable collision for the trigger
			HitActor.bProjTarget = true;
			HitActor.SetCollision(bOldCollideActors, bOldBlockActors);
		}
	}

	return CurrentImpact;
}

simulated event SetVisible(bool bVisible)
{
	super.SetVisible(bVisible);
}

simulated event vector GetMuzzleLoc()
{
	return WeaponComponent.GetMuzzleLoc(bPreviewAim);
}

native function SetAimOffsetProfile(Name ProfileName);
native function SetAiming(bool Enable);
native function UpdateAiming(Vector2D DesiredAimOffset);

simulated event PostBeginPlay( )
{
	local AnimNotify_PlayParticleEffect ParticleNotify;
	local SkeletalMeshComponent SkelMesh;

	super.PostBeginPlay( );

	SkelMesh = SkeletalMeshComponent( Mesh );
	if (SkelMesh != none)
	{
		foreach m_arrParticleEffects( ParticleNotify )
		{
			if (ParticleNotify.SocketName == '' ||
				SkelMesh.GetSocketByName( ParticleNotify.SocketName ) != none) //RAM - don't permit particle effects to spawn and then fail to attach
			{
				ParticleNotify.TriggerNotify( SkelMesh );
			}
		}
	}
	else if (m_arrParticleEffects.Length > 0)
	{
		`redscreen( "Particle effects configured for weapon of archetype "@ObjectArchetype.Name@" which does not use a skeletal mesh. ~RussellA" );
	}
}

// Use this to hook up references to the anim tree nodes you need. -- Dave@Psyonix
simulated event PostInitAnimTree(SkeletalMeshComponent SkelComp)
{
	if (SkelComp == SkeletalMeshComponent(Mesh))
	{
		DynamicNode = XComAnimNodeBlendDynamic(SkelComp.Animations.FindAnimNode('BlendDynamic'));
		AdditiveDynamicNode = XComAnimNodeBlendDynamic(SkelComp.Animations.FindAnimNode('AdditiveBlendDynamic'));
		AdditiveNode = AnimNodeAdditiveBlending(SkelComp.Animations.FindAnimNode('AdditiveBlend'));
		AimOffset = AnimNodeAimOffset(SkelComp.Animations.FindAnimNode('AimOffset'));

		if( AimOffset != None )
		{
			AimOffset.Aim.X = 0.0f;
			AimOffset.Aim.Y = 0.0f;
		}
	}
}

simulated function GivenTo(Pawn ThisPawn, optional bool bDoNotActivate)
{
//	Super.GivenTo(ThisPawn, bDoNotActivate);

	//`log("XComWeapon::GivenTo - " @bDoNotActivate);

	Mesh.SetLightEnvironment(ThisPawn.Mesh.LightEnvironment);
	Mesh.SetShadowParent(ThisPawn.Mesh);
}

/**
 * Tells the weapon to play a firing sound (uses CurrentFireMode)
 */
simulated function PlayFiringSound()
{
	// We want these played by the animation, right? - Casey

/*	if (CurrentFireMode < WeaponFireSnd.Length)
	{
		// play weapon fire sound
		if ( WeaponFireSnd[CurrentFireMode] != None )
		{
			MakeNoise(1.0);
			WeaponPlaySound( WeaponFireSnd[CurrentFireMode] );
		}
	}*/
}

/*
 * Plays the weapon related muzzle flash effects
 */
simulated function PlayFireEffects( byte FireModeNum, optional vector HitLocation )
{
	// We want these played by the animation, right? - Casey
	//WeaponFlashEffect.ActivateSystem();
}


simulated function StopFireEffects(byte FireModeNum)
{
	//WeaponFlashEffect.DeActivateSystem();
}

function SetGameData( XGWeapon kWeapon )
{
	m_kGameWeapon = kWeapon;
}

// projectile system is already hacked to shit so need to add hack flag to let the systems know its a mind merge death so we correctly replicate. -tsmith 
simulated function CustomFire(optional bool bCanDoDamage = true, optional bool HACK_bMindMergeDeathProjectile = false)
{
	
	//`log("FireWeapon AimOffset:"@XComUnitPawnNativeBase(Owner).AimOffset.x @XComUnitPawnNativeBase(Owner).AimOffset.y);

	if (WeaponComponent != none)
	{
		WeaponComponent.CustomFire(bCanDoDamage, HACK_bMindMergeDeathProjectile);
	}
}

native function bool IsTemplateValidDoDamage(int TemplateIndex);

// MHU - Aim Profile Helper Function
//       We're doing this string conversion so that animation doesn't have to enter
//       aim profiles in any specific sort order. This is by request.
simulated function string GetWeaponAimProfileString()
{
	local string data;

	switch (WeaponAimProfileType)
	{
		case WAP_Unarmed:
			data = "Unarmed";
			break;
		case WAP_Pistol:
			data = "Pistol";
			break;
		case WAP_Rocket:
			data = "Rocket";
			break;
		case WAP_MiniGun:
			data = "Minigun";
			break;
		case WAP_Grapple:
			data = "Grapple";
			break;
		case WAP_Default:
			data = "Default";
			break;
		case WAP_Turret:
			data = "Turret";
			break;
		case WAP_MecLeftArm:
			data = "MEC_LeftArm";
			break;
		case WAP_MecRightArm:
			data = "MEC_RightArm";
			break;
		default:
			data = "SoldierRifle";
			break;
	}

	return data;
}

//////////////////////////////////////////////////////////////////////////////////////////////
// BEGIN taken from Weapon to override and prevent destroying/none'ing of Inventory. 
//       This was causing Weapons to disappear when a pawn died. -tsmith 
//////////////////////////////////////////////////////////////////////////////////////////////
/**
 * A notification call when this weapon is removed from the Inventory of a pawn
 * @see Inventory::ItemRemovedFromInvManager
 */
function ItemRemovedFromInvManager()
{

}

/**
 * Drop this weapon out in to the world
 *
 * @param	StartLocation 		- The World Location to drop this item from
 * @param	StartVelocity		- The initial velocity for the item when dropped
 */
function DropFrom(vector StartLocation, vector StartVelocity)
{

}

/**
 * This function is called when the client needs to discard the weapon
 */
reliable client function ClientWeaponThrown()
{

}

//////////////////////////////////////////////////////////////////////////////////////////////
// END taken from Weapon to override and prevent destroying/none'ing of Inventory. 
//     This was causing Weapons to disappear when a pawn died. -tsmith 
//////////////////////////////////////////////////////////////////////////////////////////////

replication
{
	if( Role == ROLE_Authority )
		m_kGameWeapon;
}

defaultproperties
{
	// Base Template for weapon mesh
	Begin Object Class=SkeletalMeshComponent Name=GunAttachMeshComponent
		bOwnerNoSee=FALSE
		bUpdateSkelWhenNotRendered=FALSE
		CollideActors=true
		BlockActors=true
		BlockZeroExtent=true
		BlockNonZeroExtent=false
		BlockRigidBody=true
		bHasPhysicsAssetInstance=true
		bUpdateKinematicBonesFromAnimation=false
		//PhysicsWeight=1.0
		RBChannel=RBCC_GameplayPhysics
		RBCollideWithChannels=(Default=TRUE,BlockingVolume=TRUE,GameplayPhysics=TRUE,EffectPhysics=TRUE)
	End Object
	Mesh=GunAttachMeshComponent
	Components.Add(GunAttachMeshComponent)

	WeaponFireTypes.Add(EWFT_Custom)
	FiringStatesArray.Add("WeaponFiring")

	WeaponFireAnimSequenceName = FF_Fire
	WeaponFireKillAnimSequenceName = FF_FireKill
	WeaponSuppressionFireAnimSequenceName = FF_FireSuppress
	WeaponMoveEndFireAnimSequenceName = MV_Melee
	WeaponMoveEndFireKillAnimSequenceName = MV_MeleeKill
	WeaponMoveEndTurnLeftFireAnimSequenceName = MV_RunTurn90LeftMelee
	WeaponMoveEndTurnLeftFireKillAnimSequenceName = MV_RunTurn90LeftMeleeKill
	WeaponMoveEndTurnRightFireAnimSequenceName = MV_RunTurn90RightMelee
	WeaponMoveEndTurnRightFireKillAnimSequenceName = MV_RunTurn90RightMeleeKill

 	Spread(0)=0.0f
    FireInterval(0)=0.01f
	EquipTime = 0.0f;
	PutDownTime = 0.0f;

	bPreviewAim=false

//	eFireMode=eMode_Aimed;

 	//bAlwaysRelevant=true
 	//RemoteRole=ROLE_SimulatedProxy
 	bAlwaysRelevant=false
	RemoteRole=ROLE_None
}
