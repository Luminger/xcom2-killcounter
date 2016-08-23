class XComHumanPawn extends XComUnitPawn;

var protectedwrite TAppearance m_kAppearance;

var private repnotify TAppearance Replicated_kAppearance;
var bool bNeedsFallbackHair; // jboswell: mostly for level 3 armor
var privatewrite transient bool bShouldSpeak; // character customization only
var private	transient array<MorphTargetSet> OldMorphSets; //Keep around in memory as they may be used by the animation system in async operations

// Dynamic content
var privatewrite XComHeadContent HeadContent;
var privatewrite XComBodyContent BodyContent;
var privatewrite XComBodyPartContent CurrentHairContent;
var privatewrite XComArmsContent ArmsContent;
var privatewrite XComLegsContent LegsContent;
var privatewrite XComTorsoContent TorsoContent;
var privatewrite XComHelmetContent  HelmetContent;
var privatewrite XComDecoKitContent DecoKitContent;
var privatewrite array<XComPatternsContent> PatternsContent;
var privatewrite XComBodyPartContent EyeContent;
var privatewrite XComBodyPartContent TeethContent;
var privatewrite XComBodyPartContent BeardContent;
var privatewrite XComBodyPartContent UpperFacialContent;
var privatewrite XComBodyPartContent LowerFacialContent;
var privatewrite XComPatternsContent TattoosContent_LeftArm;
var privatewrite XComPatternsContent TattoosContent_RightArm;
var privatewrite XComPatternsContent ScarsContent;
var privatewrite XComPatternsContent FacePaintContent;
var() privatewrite XComCharacterVoice Voice;
var privatewrite XComLinearColorPaletteEntry BaseArmorTint;

var bool bShouldUseUnderlay; //True if this character should be wearing their underlay

//  STRATEGY ONLY VARIABLES
var private bool    m_bSetReadyForViewing;
var bool            bSkipGenderBlender;
var private bool m_bHasGeneMods;
var private int m_iArmor;
var bool bIgnoreFor3DCursorCollision;
var name CustomizationIdleAnim;
var int PreviousVoiceSound;

// END STRATEGY ONLY VARIABLES

const HELMET_HAIR_STANDIN_MALE = 18;
const HELMET_HAIR_STANDIN_FEMALE = 2;

struct PawnContentRequest
{
	var name ContentCategory;
	var name ArchetypeName;
	var name TemplateName;
	var Object kContent;
	var Delegate<OnBodyPartLoadedDelegate> BodyPartLoadedFn;
};

var private array<PawnContentRequest>   PawnContentRequests;
var private bool                        m_bSetArmorKit;
var private bool                        m_bSetAppearance;
var private int                         m_iRequestKit;
var private PawnContentRequest          m_kVoiceRequest;

// Character customization
enum ECCPawnAnim
{
	ePawnAnim_Idle,
	ePawnAnim_LookAtEquippedWeapon,
	ePawnAnim_LookAtArmor,
	ePawnAnim_CloseUpIdle,
};

struct ItemAttachment
{
	var EItemType ItemType;
	var name SocketName;
	//var string ArchetypeName;
	var MeshComponent Component;
	var Actor ItemActor;
};

//var transient array<ItemAttachment> PendingAttachments;
var transient array<ItemAttachment> ActiveAttachments;

var transient int NumPossibleArmorSkins;
var transient array<int> PossibleHeads;
var transient array<int> PossibleHairs;
var transient array<ECharacterVoice> PossibleVoices;
var transient int NumPossibleHairColors;
var transient int NumPossibleSkinColors;
var transient int NumPossibleArmorTints;
var transient array<int> PossibleArmorKits;

var transient TCharacter Character;

Delegate OnBodyPartLoadedDelegate(PawnContentRequest ContentRequest);

simulated event PostBeginPlay ()
{
	//Creation and assignment for the FaceFX audio component has been deferred to PostBeginPlay per discussion with Ryan Baker
	if( WorldInfo.NetMode == NM_Standalone )
	{
		FacialAudioComp = new class'AudioComponent';
		AttachComponent(FacialAudioComp);
	}

	super.PostBeginPlay();

	if (Voice != none && Voice.CurrentVoiceBank == none)
	{
		Voice.StreamNextVoiceBank();
	}
}

simulated event Destroyed()
{
	super.Destroyed();

	RemoveProps();
	RemoveAttachments();
}

simulated function RequestFullPawnContent()
{
	local PawnContentRequest kRequest;
	local XGUnit GameUnit;
	local XComGameState_Unit UnitState;	

	if(`HQGAME != none)
	{		
		UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ObjectID));
		if(UnitState != none)
		{
			bShouldUseUnderlay = XComHeadquartersGame(class'Engine'.static.GetCurrentWorldInfo().Game).GetGamecore().m_kGeoscape.m_kBase.m_kCrewMgr.ShouldUseUnderlay();
			bShouldUseUnderlay = bShouldUseUnderlay && !UnitState.GetMyTemplate().bForceAppearance && (UnitState.IsASoldier() || UnitState.IsAScientist() || UnitState.IsAnEngineer());
		}
	}

	GameUnit = XGUnit(GetGameUnit());
	`log(self @ GetFuncName() @ `showvar(GameUnit) @ `showvar(m_bSetAppearance) @ `showvar(m_bSetArmorKit),,'DevStreaming');	
	if (m_bSetAppearance)
	{
		PawnContentRequests.Length = 0;
		PatternsContent.Length = 0;

		//Order matters here, because certain pieces of content can affect other pieces of content. IE. a selected helmet can affect which mesh the hair uses, or disable upper or lower face props
		if( (!bShouldUseUnderlay && m_kAppearance.nmTorso != '') || (bShouldUseUnderlay && m_kAppearance.nmTorso_Underlay != '') )
		{
			kRequest.ContentCategory = 'Torso';
			kRequest.TemplateName = bShouldUseUnderlay ? m_kAppearance.nmTorso_Underlay : m_kAppearance.nmTorso;
			kRequest.BodyPartLoadedFn = OnTorsoLoaded;
			PawnContentRequests.AddItem(kRequest);
		}

		if (m_kAppearance.nmHead != '')
		{
			kRequest.ContentCategory = 'Head';
			kRequest.TemplateName = m_kAppearance.nmHead;
			kRequest.BodyPartLoadedFn = OnHeadLoaded;
			PawnContentRequests.AddItem(kRequest);
		}

		//Helmets can affect: beard, lower face prop, upper face prop, hair mesh
		if(m_kAppearance.nmHelmet != '') 
		{
			kRequest.ContentCategory = 'Helmets';
			kRequest.TemplateName = m_kAppearance.nmHelmet;
			kRequest.BodyPartLoadedFn = OnBodyPartLoaded;
			PawnContentRequests.AddItem(kRequest);
		}

		//Lower face props can affect: beard
		if(m_kAppearance.nmFacePropLower != '')
		{
			kRequest.ContentCategory = 'FacePropsLower';
			kRequest.TemplateName = m_kAppearance.nmFacePropLower;
			kRequest.BodyPartLoadedFn = OnBodyPartLoaded;
			PawnContentRequests.AddItem(kRequest);
		}

		if (m_kAppearance.nmHaircut != '')
		{
			kRequest.ContentCategory = 'Hair';
			kRequest.TemplateName = m_kAppearance.nmHaircut;
			kRequest.BodyPartLoadedFn = OnBodyPartLoaded;
			PawnContentRequests.AddItem(kRequest);
		}

		if( m_kAppearance.nmBeard != '' )
		{
			kRequest.ContentCategory = 'Beards';
			kRequest.TemplateName = m_kAppearance.nmBeard;
			kRequest.BodyPartLoadedFn = OnBodyPartLoaded;
			PawnContentRequests.AddItem(kRequest);
		}		

		if( m_kAppearance.nmFacePropUpper != '' )
		{
			kRequest.ContentCategory = 'FacePropsUpper';
			kRequest.TemplateName = m_kAppearance.nmFacePropUpper;
			kRequest.BodyPartLoadedFn = OnBodyPartLoaded;
			PawnContentRequests.AddItem(kRequest);
		}


		if( (UnitState == none || UnitState.GetMyTemplateName() != 'Clerk') &&
		   ((!bShouldUseUnderlay && m_kAppearance.nmArms != '') || (bShouldUseUnderlay && m_kAppearance.nmArms_Underlay != '')) )
		{
			kRequest.ContentCategory = 'Arms';
			kRequest.TemplateName = bShouldUseUnderlay ? m_kAppearance.nmArms_Underlay : m_kAppearance.nmArms;
			kRequest.BodyPartLoadedFn = OnArmsLoaded;
			PawnContentRequests.AddItem(kRequest);
		}

		if( (UnitState == none || UnitState.GetMyTemplateName() != 'Clerk') &&
		   ((!bShouldUseUnderlay && m_kAppearance.nmLegs != '') || (bShouldUseUnderlay && m_kAppearance.nmLegs_Underlay != '')) )
		{
			kRequest.ContentCategory = 'Legs';
			kRequest.TemplateName = bShouldUseUnderlay ? m_kAppearance.nmLegs_Underlay : m_kAppearance.nmLegs;
			kRequest.BodyPartLoadedFn = OnLegsLoaded;
			PawnContentRequests.AddItem(kRequest);
		}

		if (m_kAppearance.nmEye != '')
		{
			kRequest.ContentCategory = 'Eyes';
			kRequest.TemplateName = m_kAppearance.nmEye;
			kRequest.BodyPartLoadedFn = OnBodyPartLoaded;
			PawnContentRequests.AddItem(kRequest);
		}

		if (m_kAppearance.nmTeeth != '')
		{
			kRequest.ContentCategory = 'Teeth';
			kRequest.TemplateName = m_kAppearance.nmTeeth;
			kRequest.BodyPartLoadedFn = OnBodyPartLoaded;
			PawnContentRequests.AddItem(kRequest);
		}

		if (m_kAppearance.nmPatterns != '')
		{
			kRequest.ContentCategory = 'Patterns';
			kRequest.TemplateName = m_kAppearance.nmPatterns;
			kRequest.BodyPartLoadedFn = OnPatternsLoaded;
			PawnContentRequests.AddItem(kRequest);
		}

		if(m_kAppearance.nmWeaponPattern != '')
		{
			kRequest.ContentCategory = 'Patterns';
			kRequest.TemplateName = m_kAppearance.nmWeaponPattern;
			kRequest.BodyPartLoadedFn = OnPatternsLoaded;
			PawnContentRequests.AddItem(kRequest);
		}

		if(m_kAppearance.nmTattoo_LeftArm != '')
		{
			kRequest.ContentCategory = 'Tattoos';
			kRequest.TemplateName = m_kAppearance.nmTattoo_LeftArm;
			kRequest.BodyPartLoadedFn = OnTattoosLoaded_LeftArm;
			PawnContentRequests.AddItem(kRequest);
		}

		if(m_kAppearance.nmTattoo_RightArm != '')
		{
			kRequest.ContentCategory = 'Tattoos';
			kRequest.TemplateName = m_kAppearance.nmTattoo_RightArm;
			kRequest.BodyPartLoadedFn = OnTattoosLoaded_RightArm;
			PawnContentRequests.AddItem(kRequest);
		}

		if(m_kAppearance.nmScars != '')
		{
			kRequest.ContentCategory = 'Scars';
			kRequest.TemplateName = m_kAppearance.nmScars;
			kRequest.BodyPartLoadedFn = OnScarsLoaded;
			PawnContentRequests.AddItem(kRequest);
		}

		if(m_kAppearance.nmFacePaint != '')
		{
			kRequest.ContentCategory = 'Facepaint';
			kRequest.TemplateName = m_kAppearance.nmFacePaint;
			kRequest.BodyPartLoadedFn = OnFacePaintLoaded;
			PawnContentRequests.AddItem(kRequest);
		}

		if(m_kAppearance.nmVoice != '' && `TACTICALGRI != none) //Only load the voices for tactical. In strategy play them on demand
		{
			kRequest.ContentCategory = 'Voice';
			kRequest.TemplateName = m_kAppearance.nmVoice;
			kRequest.BodyPartLoadedFn = OnVoiceLoaded;
			PawnContentRequests.AddItem(kRequest);
		}

		//  Make the requests later. If they come back synchronously, their callbacks will also happen synchronously, and it can throw things out of whack
		MakeAllContentRequests();
	}
}

simulated function MakeAllContentRequests()
{	
	local X2BodyPartTemplate PartTemplate;
	local X2BodyPartTemplateManager PartManager;
	local Delegate<OnBodyPartLoadedDelegate> BodyPartLoadedFn;
	local int i;
	
	PartManager = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager();

	for(i = 0; i < PawnContentRequests.Length; ++i)
	{		
		PartTemplate = PartManager.FindUberTemplate(string(PawnContentRequests[i].ContentCategory), PawnContentRequests[i].TemplateName);
		if (PartTemplate != none) //If the part couldn't be found, then just ignore it. This could happen when loading a save that had DLC installed that we don't have
		{
			PawnContentRequests[i].ArchetypeName = name(PartTemplate.ArchetypeName);
			if(PawnContentRequests[i].ArchetypeName != '')
			{
				PawnContentRequests[i].kContent = `CONTENT.RequestGameArchetype(PartTemplate.ArchetypeName, self, none, false);
				if(PawnContentRequests[i].kContent == none)
				{
					`redscreen("Couldn't load body part content:"@PartTemplate.ArchetypeName@"! The entry for this archetype needs to be fixed in DefaultContent.ini. @csulzbach");
				}

				BodyPartLoadedFn = PawnContentRequests[i].BodyPartLoadedFn;
				if(BodyPartLoadedFn != none)
				{
					BodyPartLoadedFn(PawnContentRequests[i]);
				}				
			}
			else
			{
				`redscreen("An empty archetype was specified for body part template"@PawnContentRequests[i].TemplateName@"! This is an invalid setting - remove the entry from DefaultContent.ini @csulzbach");
			}
		}
	}

	PawnContentFullyLoaded();
}

simulated function PawnContentFullyLoaded()
{
	local XComLinearColorPalette Palette;

	`log(self @ GetFuncName() @ "......",,'DevStreaming');

	//  no hair content will show up, so make sure to make 'em bald
	if (m_kAppearance.nmHaircut == '')
		RemoveHair();

	NumPossibleArmorTints = 0;
	Palette = `CONTENT.GetColorPalette(ePalette_ArmorTint);
	NumPossibleArmorTints = Palette.Entries.Length;

	NumPossibleHairColors = 0;
	Palette = `CONTENT.GetColorPalette(ePalette_HairColor);
	NumPossibleHairColors = Palette.Entries.Length;	
	
	UpdateAllMeshMaterials();

	PawnContentRequests.Length = 0;	
}

simulated event bool RestoreAnimSetsToDefault()
{
	Mesh.AnimSets.Length = 0;

	AddRequiredAnimSets();

	return super.RestoreAnimSetsToDefault();
}

simulated event FinishAnimControl(InterpGroup InInterpGroup)
{
	if( !m_bRemainInAnimControlForDeath )
	{
		super.FinishAnimControl(InInterpGroup);

		UpdateAnimations();
	}
}

simulated exec function UpdateAnimations()
{
	local CustomAnimParams AnimParams;

	super.UpdateAnimations();

	if( TorsoContent.UnitPawnAnimSets.Length > 0 )
	{
		XComAddAnimSetsExternal(TorsoContent.UnitPawnAnimSets);
		if( GetAnimTreeController().CanPlayAnimation('ADD_SwordSocketOffset') )
		{
			AnimParams.AnimName = 'ADD_SwordSocketOffset';
			GetAnimTreeController().PlayAdditiveDynamicAnim(AnimParams);
		}
	}
}

simulated function AddRequiredAnimSets()
{
	local AnimSet PawnAnimSet;

	// Add default pawn anim sets
	foreach DefaultUnitPawnAnimsets(PawnAnimSet)
	{
		if(Mesh.AnimSets.Find(PawnAnimSet) == INDEX_NONE)
			Mesh.AnimSets.AddItem(PawnAnimSet);
	}

	// Add required base animsets (this only happens in HQ) -- jboswell
	foreach XComGameInfo(WorldInfo.Game).PawnAnimSets(PawnAnimSet)
	{
		if (Mesh.AnimSets.Find(PawnAnimSet) == INDEX_NONE)
			Mesh.AnimSets.AddItem(PawnAnimSet);
	}

	// Add the anim set for the head
	if (HeadContent != none)
	{
		if (HeadContent.AdditiveAnimSet != none &&
			Mesh.AnimSets.Find(HeadContent.AdditiveAnimSet) == INDEX_NONE)
		{
			Mesh.AnimSets.AddItem(HeadContent.AdditiveAnimSet);	
		}
	}
}

simulated event PostInitAnimTree(SkeletalMeshComponent SkelComp)
{	
	// Do not reset here, just make sure we have the animsets we need to not get monkey people
	// or freaked out flippy heads -- jboswell
	// If we reset, in tactical the units will lose their weapon-based animations
	AddRequiredAnimSets();

	super.PostInitAnimTree(SkelComp);

	if (bIsFemale && !bSkipGenderBlender)
	{
		GetAnimTreeController().SetGenderBlenderBlendTarget(1.0f, 0.0f);
	}

	InitLeftHandIK();

	OnPostInitAnimTree();
}

simulated function OnPostInitAnimTree()
{
	//Overridden depending on state
}

simulated function UpdateAllMeshMaterials()
{
	local int Idx;

	super.UpdateAllMeshMaterials();

	UpdateMeshAttachmentMaterials(Mesh); // Armor must always come first for the color tint saving code
	UpdateMeshMaterials(m_kHeadMeshComponent);
	UpdateMeshMaterials(m_kTorsoComponent);
	UpdateMeshMaterials(m_kArmsMC);
	UpdateMeshMaterials(m_kLegsMC);
	UpdateMeshMaterials(m_kHelmetMC);
	UpdateMeshMaterials(m_kDecoKitMC);
	UpdateMeshMaterials(m_kEyeMC);
	UpdateMeshMaterials(m_kTeethMC);	
	UpdateMeshMaterials(m_kBeardMC);
	UpdateMeshMaterials(m_kUpperFacialMC);
	UpdateMeshMaterials(m_kLowerFacialMC);
	UpdateMeshMaterials(m_kHairMC);

	for (Idx = 0; Idx < ActiveAttachments.Length; ++Idx)
	{
		UpdateMeshMaterials(ActiveAttachments[Idx].Component);
	}
}

simulated function UpdateMeshAttachmentMaterials(MeshComponent Attachment)
{
	local SkeletalMeshComponent SkelMeshComponent;
	local MeshComponent AttachedComponent;
	local int Idx;

	UpdateMeshMaterials(Attachment);

	SkelMeshComponent = SkeletalMeshComponent(Attachment);
	if( SkelMeshComponent != None )
	{
		for( Idx = 0; Idx < SkelMeshComponent.Attachments.Length; ++Idx )
		{
			AttachedComponent = MeshComponent(SkelMeshComponent.Attachments[Idx].Component);
			if( AttachedComponent != none )
			{
				UpdateMeshAttachmentMaterials(AttachedComponent);
			}
		}
	}
}

simulated function UpdateEyesMaterial(MaterialInstanceConstant MIC)
{
	local XComLinearColorPalette Palette;
	local LinearColor ParamColor;

	Palette = `CONTENT.GetColorPalette(ePalette_EyeColor);
	ParamColor = Palette.Entries[m_kAppearance.iEyeColor > -1 ? m_kAppearance.iEyeColor : 0].Primary;
	MIC.SetVectorParameterValue('EyeColor', ParamColor);
}

simulated function UpdateHairMaterial(MaterialInstanceConstant MIC)
{
	local XComLinearColorPalette Palette;
	local LinearColor ParamColor;

	Palette = `CONTENT.GetColorPalette(ePalette_HairColor);
	ParamColor = Palette.Entries[m_kAppearance.iHairColor].Primary;
	MIC.SetVectorParameterValue('HairColor', ParamColor);
	MIC.SetVectorParameterValue('Hair Color', ParamColor); //Beards
}

simulated function UpdateSkinMaterial(MaterialInstanceConstant MIC, bool bHasHair, bool bIsHead)
{
	local XComLinearColorPalette Palette;
	local LinearColor ParamColor;

	if (HeadContent != None)
	{
		Palette = `CONTENT.GetColorPalette(HeadContent.SkinPalette);
		
		// Pick a skin color if we need to -- jboswell
		if (m_kAppearance.iSkinColor == INDEX_NONE)
			m_kAppearance.iSkinColor = Rand(Palette.BaseOptions);

		// Skin Color
		ParamColor = Palette.Entries[m_kAppearance.iSkinColor].Primary;

		if (!bIsHead)
		{
			// modify the body tint color with the averaged head color
			ParamColor.R *= HeadContent.BodyTint.R;
			ParamColor.G *= HeadContent.BodyTint.G;
			ParamColor.B *= HeadContent.BodyTint.B;
			ParamColor.A *= HeadContent.BodyTint.A;
		}
		MIC.SetVectorParameterValue('SkinColor', ParamColor);		

		Palette = `CONTENT.GetColorPalette(ePalette_HairColor);
		ParamColor = Palette.Entries[m_kAppearance.iHairColor].Primary;
		MIC.SetVectorParameterValue('HairColor', ParamColor);
		MIC.SetVectorParameterValue('Hair Color', ParamColor); //Beards

		if(bIsHead)
		{
			if(m_kAppearance.nmScars != '' && ScarsContent.texture != none)
			{
				MIC.SetScalarParameterValue('ShowScars', 1);
				MIC.SetTextureParameterValue('ScarNormal', ScarsContent.texture);
			}
			else
			{
				MIC.SetScalarParameterValue('ShowScars', 0);
				MIC.SetTextureParameterValue('ScarNormal', none);
			}

			if(m_kAppearance.nmFacePaint != '' && FacePaintContent.texture != none)
			{
				MIC.SetScalarParameterValue('ShowFacePaint', 1);
				MIC.SetTextureParameterValue('FacePaintDiffuse', FacePaintContent.texture);
			}
			else
			{
				MIC.SetScalarParameterValue('ShowFacePaint', 0);
				MIC.SetTextureParameterValue('FacePaintDiffuse', none);
			}
		}
	}

	if(!bIsHead)
	{
		if(TattoosContent_LeftArm != none || TattoosContent_RightArm != none)
		{
			MIC.SetScalarParameterValue('HasTattoo', 1);			
		}
		else
		{
			MIC.SetScalarParameterValue('HasTattoo', 0);
		}

		Palette = `CONTENT.GetColorPalette(ePalette_ArmorTint); //Fetch from tattoo palette once one is created
		ParamColor = Palette.Entries[ Max(m_kAppearance.iTattooTint, 0) ].Primary;
		MIC.SetVectorParameterValue('TattooColor', ParamColor);

		MIC.SetTextureParameterValue('TattooLeft', TattoosContent_LeftArm != none ? TattoosContent_LeftArm.texture : none);
		MIC.SetTextureParameterValue('TattooRight', TattoosContent_RightArm != none ? TattoosContent_RightArm.texture : none);
	}
}

simulated function UpdateArmorMaterial(MeshComponent MeshComp, MaterialInstanceConstant MIC, int iPrimaryTint, int iSecondaryTint, XComPatternsContent Pattern )
{
	local XComLinearColorPalette Palette;
	local XComLinearColorPaletteEntry ArmorTint;
	local XComLinearColorPaletteEntry ArmorTintSecondary;
	local bool bHasStoredTint, bHasTintToApply;

	// jboswell: this is a shit check, but it's HIGHLY unlikely that sulzy is going to use black as the base armor color
	// we have to store the original tint values for the armor, because otherwise we have no way to go back to the default when
	// there is no tint applied (like when the player cycles through all of the options and back to the base tint)
	bHasStoredTint = ((BaseArmorTint.Primary.R + BaseArmorTint.Primary.G + BaseArmorTint.Primary.B) > 0.0f);
	bHasTintToApply = false;
	if(iPrimaryTint  == INDEX_NONE && bHasStoredTint)
	{
		ArmorTint = BaseArmorTint;
		bHasTintToApply = true;
	}
	else if(iPrimaryTint != INDEX_NONE)
	{
		Palette = `CONTENT.GetColorPalette(ePalette_ArmorTint);
		if (Palette != none)
		{
			ArmorTint = Palette.Entries[iPrimaryTint];
			if(iSecondaryTint != INDEX_NONE)
				ArmorTintSecondary = Palette.Entries[iSecondaryTint];

			bHasTintToApply = true;
		}
	}
	//Pattern Addition 2015-5-4 Chang You Wong
	if(Pattern != none && Pattern.texture != none)
	{		
		//For Optimization, we want to fix the SetStaticSwitchParameterValueAndReattachShader function
		//When that happens we need to change the relevant package back to using static switches
		//SoldierArmorCustomizable_TC  M_Master_PwrdArm_TC  WeaponCustomizable_TC
		//MIC.SetStaticSwitchParameterValueAndReattachShader('Use Pattern', true, MeshComp);
		MIC.SetScalarParameterValue('PatternUse', 1);		
		MIC.SetTextureParameterValue('Pattern', Pattern.texture);// .ReferencedObjects[0]));
	}
	else
	{
		//Same optimization as above
		//MIC.SetStaticSwitchParameterValueAndReattachShader('Use Pattern', false, MeshComp);
		MIC.SetScalarParameterValue('PatternUse', 0);
		MIC.SetTextureParameterValue('Pattern', none);
	}
	
	// Save old values in case we have to go back (only read the defaults from armor)
	if (!bHasStoredTint && MeshComp == Mesh)
	{
		MIC.GetVectorParameterValue('Primary Color', BaseArmorTint.Primary);
		MIC.GetVectorParameterValue('Secondary Color', BaseArmorTint.Secondary);
		bHasStoredTint = true;
	}

	if (bHasTintToApply)
	{
		MIC.SetVectorParameterValue('Primary Color', ArmorTint.Primary);
		MIC.SetVectorParameterValue('Secondary Color', ArmorTintSecondary.Secondary);
	}
}

simulated function UpdateMECMaterial(MeshComponent MeshComp, MaterialInstanceConstant MIC)
{

}

simulated function UpdateFlagMaterial(MaterialInstanceConstant MIC)
{
	local Object FlagArchetype;
	local XComContentManager ContentManager;
	local X2StrategyElementTemplateManager StratMgr;
	local X2CountryTemplate CountryTemplate;

	ContentManager = `CONTENT;
	if (m_kAppearance.nmFlag != '')
	{
		StratMgr = class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager();
		CountryTemplate = X2CountryTemplate(StratMgr.FindStrategyElementTemplate(m_kAppearance.nmFlag));
		FlagArchetype = ContentManager.RequestGameArchetype(CountryTemplate.FlagArchetype);
		if(FlagArchetype == none || !FlagArchetype.IsA('XComPatternsContent'))
		{
			`RedScreen("Could not load Flag texture" @ CountryTemplate.FlagArchetype);
			return;
		}
		MIC.SetTextureParameterValue('Flag_DIF', XComPatternsContent(FlagArchetype).texture);
	}
}

simulated function UpdateCivilianBodyMaterial(MaterialInstanceConstant MIC)
{
}

simulated function UpdateMeshMaterials(MeshComponent MeshComp)
{
	local MaterialInterface Mat, ParentMat;
	local MaterialInstanceConstant MIC, ParentMIC, NewMIC;
	local int Idx;
	local name ParentName;
	
	if (MeshComp != none)
	{
		for (Idx = 0; Idx < MeshComp.GetNumElements(); ++Idx)
		{
			Mat = MeshComp.GetMaterial(Idx);
			MIC = MaterialInstanceConstant(Mat);

			// It is possible for there to be MITVs in these slots, so check
			if (MIC != none)
			{
				// If this is not a child MIC, make it one. This is done so that the material updates below don't stomp
				// on each other between units.
				if (InStr(MIC.Name, "MaterialInstanceConstant") == INDEX_NONE)
				{
					NewMIC = new (self) class'MaterialInstanceConstant';
					NewMIC.SetParent(MIC);
					MeshComp.SetMaterial(Idx, NewMIC);
					MIC = NewMIC;
				}
				
				ParentMat = MIC.Parent;
				while (!ParentMat.IsA('Material'))
				{
					ParentMIC = MaterialInstanceConstant(ParentMat);
					if (ParentMIC != none)
						ParentMat = ParentMIC.Parent;
					else
						break;
				}
				ParentName = ParentMat.Name;

				switch (ParentName)
				{
					case 'M_HairCustomizable':
					case 'F_HairCustomizable':
					case 'M_HairCustomizable_Trans':
					case 'F_HairCustomizable_Trans':
					case 'HairSimple_TC':
						UpdateHairMaterial(MIC);
						break;
					case 'HeadCustomizable_TC':						
					case 'SkinCustomizable_TC':
						UpdateSkinMaterial(MIC, true, MeshComp == m_kHeadMeshComponent);
						break;
					case 'SoldierArmorCustomizable_TC':		
					case 'M_Master_PwrdArm_TC':
					case 'Props_OpcMask_TC':
					case 'CivilianCustomizable_TC':
						UpdateArmorMaterial(MeshComp, MIC, m_kAppearance.iArmorTint, m_kAppearance.iArmorTintSecondary, PatternsContent[0]);
						break;
					case 'WeaponCustomizable_TC':
						// Weapon customization data is now stored in XComGameState_Item.WeaponAppearance, and applied in XGWeapon.UpdateWeaponMaterial
						/*
						if(PatternsContent.Length > 1)
						{
							UpdateArmorMaterial(MeshComp, MIC, m_kAppearance.iWeaponTint, m_kAppearance.iArmorTintSecondary, PatternsContent[1]);
						}
						*/
						break;
					case 'EyesCustomizable_TC':
						UpdateEyesMaterial(MIC);
						break;
					case 'TC_Flags':
						UpdateFlagMaterial(MIC);
						break;
					default:
						//`log("UpdateMeshMaterials: Unknown material" @ ParentName @ "found on" @ self @ MeshComp);
						break;
				}
			}
		}
	}	
}

function ResetMaterials(MeshComponent ResetMeshComp)
{
	local SkeletalMeshComponent MeshComp;
	local int Index;

	MeshComp = SkeletalMeshComponent(ResetMeshComp);
	if(MeshComp != none && MeshComp.SkeletalMesh != none)
	{		
		for(Index = 0; Index < MeshComp.SkeletalMesh.Materials.Length; ++Index)
		{
			MeshComp.SetMaterial(Index, MeshComp.SkeletalMesh.Materials[Index]);
		}
	}
}

simulated function SetHeadAnim(AnimNodeBlendList HeadNode, Name AnimName)
{
	local AnimNodeSequence SeqNode;

	SeqNode = AnimNodeSequence(HeadNode.Children[0].Anim);	

	if( SeqNode != None )
	{
		SeqNode.SetAnim(AnimName);
		SeqNode.ReplayAnim();
	}
}

simulated function SetHead(int HeadId)
{
	/* jbouscher - refactoring appearance to use templates
	m_kAppearance.iHead = HeadId;
	SetAppearance(m_kAppearance);
	*/
}

simulated function SetHair(int HairId)
{
	/* jbouscher - refactoring appearance to use templates
	m_kAppearance.iHaircut = HairId;
	SetAppearance(m_kAppearance);
	*/
}

simulated function SetHairColor(int ColorIdx)
{
	m_kAppearance.iHairColor = ColorIdx;
}

// Note: only sets head, because you would never use this on a civilian (strategy only) -- jboswell
simulated function SetSkinColor(int ColorIdx)
{
	m_kAppearance.iSkinColor = ColorIdx;
}

simulated function SetArmorDeco(int DecoIdx)
{
	m_kAppearance.iArmorDeco = DecoIdx;

	if (IsA('XComMecPawn'))
		UpdateAllMeshMaterials();
	
	m_iRequestKit = DecoIdx;
	SetTimer(0.1f, false, nameof(RequestKitPostArmor));
}

simulated function SetArmorTint(int TintIdx)
{
	m_kAppearance.iArmorTint = TintIdx;
	UpdateAllMeshMaterials();               
}

simulated event bool IsFemale()
{
	return super.IsFemale() || bIsFemale;
}

simulated function bool IsMale()
{
	return m_kAppearance.iGender == eGender_Male;
}

simulated function SetFacialHair(int PresetIdx)
{
	if (m_kAppearance.iGender == eGender_Male)
	{
		m_kAppearance.iFacialHair = PresetIdx;
	}
}

simulated function SetVoice(name NewVoice)
{	
	local X2BodyPartTemplate PartTemplate;
	local X2BodyPartTemplateManager PartManager;
	
	if(m_kAppearance.nmVoice != '')
	{
		PartManager = class'X2BodyPartTemplateManager'.static.GetBodyPartTemplateManager();
		PartTemplate = PartManager.FindUberTemplate("Voice", NewVoice);
		if(PartTemplate != none)
		{
			bShouldSpeak = true;
			`CONTENT.RequestGameArchetype(PartTemplate.ArchetypeName, self, OnVoiceLoadedUI, true);
			
		}
	}
}

function OnVoiceLoadedUI(Object LoadedArchetype)
{
	Voice = XComCharacterVoice(LoadedArchetype);
	if(Voice != none)
	{
		if(Voice.akBankId != 0)
		{
			if(PreviousVoiceSound != INDEX_NONE)
			{
				StopAkSound(PreviousVoiceSound);
			}

			PreviousVoiceSound = PlayAkSound(Voice.AkCustomizationEventName);
		}
		else
		{
			//This path is taken for sound-cue based mod voices
			Voice.PlaySoundForEvent('Dashing', self);
		}

		//Allow the voice to be unloaded
		`CONTENT.UnCacheObject(PathName(Voice));
	}
}

simulated function SetVoiceSilently(name NewVoice)
{
	m_kAppearance.nmVoice = NewVoice;
}

simulated function SetLanguage(Name NewLanguage)
{
	bShouldSpeak = true;
	m_kAppearance.nmLanguage = NewLanguage;
	SetAppearance(m_kAppearance);
}

simulated function RemoveProps()
{
	local int iProp;

	for (iProp=0; iProp<m_aPhysicsProps.Length; iProp++)
	{
		if (m_aPhysicsProps[iProp] != none)
		{
			DetachComponent(m_aPhysicsProps[iProp].SkeletalMeshComponent);
			Mesh.DetachComponent(m_aPhysicsProps[iProp].SkeletalMeshComponent);
			Detach(m_aPhysicsProps[iProp]);
			m_aPhysicsProps[iProp].Destroy();
		}
	}
	m_aPhysicsProps.Length = 0;
}

simulated function RemoveProp(MeshComponent PropComponent)
{
	local int PropIdx;

	DetachComponent(PropComponent);
	Mesh.DetachComponent(PropComponent);
	
	for (PropIdx = 0; PropIdx < m_aPhysicsProps.Length; ++PropIdx)
	{
		if (m_aPhysicsProps[PropIdx] != none && m_aPhysicsProps[PropIdx].SkeletalMeshComponent == PropComponent)
		{
			//m_aPhysicsProps[PropIdx].SetBase(none);
			m_aPhysicsProps[PropIdx].Destroy();
			m_aPhysicsProps.Remove(PropIdx, 1);
			break;
		}
	}  
}

simulated function RemoveAttachments()
{
	local ItemAttachment AttachedItem;

	foreach ActiveAttachments(AttachedItem)
	{
		Mesh.DetachComponent(AttachedItem.Component);
		AttachedItem.Component = none;
		AttachedItem.ItemActor.Destroy();
	}
	ActiveAttachments.Length = 0;
}

simulated function GetSeamlessTravelActorList(bool bToTransitionMap, out array<Actor> ActorList)
{
	local XComPawnPhysicsProp Prop;

	ActorList[ActorList.Length] = self;
	
	foreach m_aPhysicsProps(Prop)
	{
		ActorList[ActorList.Length] = Prop;
	}
}

simulated function SetupForMatinee(optional Actor MatineeBase, optional bool bDisableFootIK, optional bool bDisableGenderBlender, optional bool bHardAttachToMatineeBase)
{
	PrepForMatinee();

	if (bDisableGenderBlender && bIsFemale && !bSkipGenderBlender)
	{
		GetAnimTreeController().SetGenderBlenderBlendTarget(0.0f, 0.0f);
	}

	super.SetupForMatinee(MatineeBase, bDisableFootIK, bDisableGenderBlender, bHardAttachToMatineeBase);
}

simulated function ReturnFromMatinee()
{
	// Restore the gender blender, should be a no-op if it wasn't disabled -- jboswell
	if (bIsFemale && !bSkipGenderBlender)
	{
		GetAnimTreeController().SetGenderBlenderBlendTarget(1.0f, 0.0f);
	}

	super.ReturnFromMatinee();
}

simulated function FreezeHair()
{
	
}

simulated function WakeHair()
{
	
}

simulated function PrepForMatinee()
{
	if (Mesh != none)
	{
		if (IsInStrategy())
		{
			//  These need to all be true to prevent a frame of T-posing when the pawn appears
			Mesh.bAllowSetAnimPositionWhenNotRendered = true;
			Mesh.bTickAnimNodesWhenNotRendered = true;
			SetUpdateSkelWhenNotRendered(true);
		}
		else
		{
			Mesh.bForceUpdateAttachmentsInTick = true;
			SetUpdateSkelWhenNotRendered(true);
		}
	}

	// Because the matinee is likely to move the character, we need to wait until
	// next frame to do all the physics stuff, or we'll warping rigid bodies, which
	// leads to things like stretchy hair -- jboswell
	SetTimer(0.01, false, 'WakeHair');

	SetAuxParameters(true, false, false);
}

simulated function RemoveFromMatinee(); // only for HQ

// jboswell: Reminder: Heads turn inside out if you have started animating the body
// before attaching the head. Always activate anim tree nodes AFTER attaching the head
simulated function OnHeadLoaded(PawnContentRequest ContentRequest)
{
	local MaterialInterface SkinMaterial;

	if(HeadContent == XComHeadContent(ContentRequest.kContent))
		return;

	HeadContent = XComHeadContent(ContentRequest.kContent);
	m_kHeadMeshComponent = Mesh; //The base mesh is the head for pawns that load head content
	
	// Head materials: 0 = skin, 1= eyelashes/eyebrows
	// Add a new MIC so we can change parameters for just this character
	SkinMaterial = HeadContent.HeadMaterial;
	if (SkinMaterial != none)
	{
		m_kHeadMeshComponent.SetMaterial(0, SkinMaterial);
	}

	//Play the additive anim that will morph the head shape from the ref head
	if( HeadContent.AdditiveAnimSet != none && HeadContent.AdditiveAnim != '' )
	{		
		AnimTreeController.SetHeadAnim(HeadContent.AdditiveAnim);		
	}

	MarkAuxParametersAsDirty(m_bAuxParamNeedsPrimary, m_bAuxParamNeedsSecondary, m_bAuxParamUse3POutline);
}

simulated function OnArmsLoaded(PawnContentRequest ContentRequest)
{
	if(ArmsContent == XComArmsContent(ContentRequest.kContent))
		return;

	ArmsContent = XComArmsContent(ContentRequest.kContent);
	m_kArmsMC.SetSkeletalMesh(ArmsContent.SkeletalMesh);
	ResetMaterials(m_kArmsMC);
	if(ArmsContent.OverrideMaterial != none)
	{
		m_kArmsMC.SetMaterial(0, ArmsContent.OverrideMaterial);
	}
	m_kArmsMC.SetParentAnimComponent(Mesh);
	
	Mesh.AppendSockets(m_kArmsMC.Sockets, true);
	MarkAuxParametersAsDirty(m_bAuxParamNeedsPrimary, m_bAuxParamNeedsSecondary, m_bAuxParamUse3POutline);
}

simulated function OnLegsLoaded(PawnContentRequest ContentRequest)
{
	if(LegsContent == XComLegsContent(ContentRequest.kContent))
		return;

	LegsContent = XComLegsContent(ContentRequest.kContent);
	m_kLegsMC.SetSkeletalMesh(LegsContent.SkeletalMesh);
	ResetMaterials(m_kLegsMC);
	if(LegsContent.OverrideMaterial != none)
	{
		m_kLegsMC.SetMaterial(0, LegsContent.OverrideMaterial);
	}
	m_kLegsMC.SetParentAnimComponent(Mesh);
	
	Mesh.AppendSockets(m_kLegsMC.Sockets, true);
	MarkAuxParametersAsDirty(m_bAuxParamNeedsPrimary, m_bAuxParamNeedsSecondary, m_bAuxParamUse3POutline);
}


simulated function OnPatternsLoaded(PawnContentRequest ContentRequest)
{
	PatternsContent.AddItem(XComPatternsContent(ContentRequest.kContent));
}

simulated function OnTattoosLoaded_LeftArm(PawnContentRequest ContentRequest)
{
	TattoosContent_LeftArm = XComPatternsContent(ContentRequest.kContent);
}

simulated function OnTattoosLoaded_RightArm(PawnContentRequest ContentRequest)
{
	TattoosContent_RightArm = XComPatternsContent(ContentRequest.kContent);
}

simulated function OnScarsLoaded(PawnContentRequest ContentRequest)
{
	ScarsContent = XComPatternsContent(ContentRequest.kContent);
}

simulated function OnFacePaintLoaded(PawnContentRequest ContentRequest)
{
	FacePaintContent = XComPatternsContent(ContentRequest.kContent);
}

simulated function OnBodyPartLoaded(PawnContentRequest ContentRequest)
{
	local XComBodyPartContent BodyPartContent;
	local SkeletalMeshComponent UseMeshComponent;
	local XComPawnPhysicsProp PhysicsProp;
	local SkeletalMesh UseSkeletalMesh;
	local PhysicsAsset UsePhysicsAsset;
	local MorphTargetSet UseMorph;
	local bool bSkipAttachment;
	local bool bHideForUnderlay;

	if(ContentRequest.kContent == none)
	{
		return;
	}

	BodyPartContent = XComBodyPartContent(ContentRequest.kContent);
	if (BodyPartContent == none)
		return;

	UseSkeletalMesh = BodyPartContent.SkeletalMesh;
	UsePhysicsAsset = BodyPartContent.UsePhysicsAsset;
	UseMorph = BodyPartContent.UseMorphTargetSet;

	bHideForUnderlay = BodyPartContent.bHideWithUnderlay && bShouldUseUnderlay;
	
	switch(ContentRequest.ContentCategory)
	{
	case 'Eyes':
		if( EyeContent == BodyPartContent )
		{
			return;
		}
		EyeContent = BodyPartContent;
		UseMeshComponent = m_kEyeMC;
		break;
	case 'Teeth':
		if( TeethContent == BodyPartContent )
		{
			return;
		}
		TeethContent = BodyPartContent;
		UseMeshComponent = m_kTeethMC;
		break;
	case 'Hair':
		UseMeshComponent = m_kHairMC;
		if(HelmetContent != none && HelmetContent.ObjectArchetype != none && m_kHelmetMC.SkeletalMesh != none)
		{
			if(HelmetContent.FallbackHairIndex > -1 &&
			   HelmetContent.FallbackHairIndex < BodyPartContent.FallbackSkeletalMeshes.Length &&
			   HelmetContent.FallbackHairIndex < BodyPartContent.FallbackPhysicsAssets.Length)
			{
				UseSkeletalMesh = BodyPartContent.FallbackSkeletalMeshes[HelmetContent.FallbackHairIndex];
				UsePhysicsAsset = BodyPartContent.FallbackPhysicsAssets[HelmetContent.FallbackHairIndex];
			}
			else
			{
				UseSkeletalMesh = none;				
				bSkipAttachment = true;
			}
		}

		if(UseMeshComponent.SkeletalMesh == UseSkeletalMesh && CurrentHairContent != none &&
		   ((!BodyPartContent.ShouldUseOverrideMaterial() && !CurrentHairContent.ShouldUseOverrideMaterial()) || CurrentHairContent.OverrideMaterial == BodyPartContent.OverrideMaterial))
		{
			return;
		}

		if(UseSkeletalMesh == none)
		{
			UseMeshComponent.SetSkeletalMesh(none);
		}
		else
		{
			CurrentHairContent = BodyPartContent;
		}
		break;

	case 'Beards':
		UseMeshComponent = m_kBeardMC;
		if( (HelmetContent != none && HelmetContent.bHideFacialHair) ||
		    (LowerFacialContent != none && LowerFacialContent.bHideFacialHair) )
		{
			UseSkeletalMesh = none;
			bSkipAttachment = true;
		}

		if(UseMeshComponent.SkeletalMesh == UseSkeletalMesh && BeardContent != none &&
		   ((!BodyPartContent.ShouldUseOverrideMaterial() && !BeardContent.ShouldUseOverrideMaterial()) || BeardContent.OverrideMaterial == BodyPartContent.OverrideMaterial))
		{
			return;
		}

		if(UseSkeletalMesh == none)
		{
			UseMeshComponent.SetSkeletalMesh(none);
		}		

		BeardContent = BodyPartContent;		
		break;

	case 'FacePropsUpper':
		UseMeshComponent = m_kUpperFacialMC;
		if(HelmetContent != none && (HelmetContent.bHideUpperFacialProps || bHideForUnderlay))
		{
			UseSkeletalMesh = none;
			bSkipAttachment = true;
		}

		if(UseMeshComponent.SkeletalMesh == UseSkeletalMesh && UpperFacialContent != none &&
		   ((!BodyPartContent.ShouldUseOverrideMaterial() && !UpperFacialContent.ShouldUseOverrideMaterial()) || UpperFacialContent.OverrideMaterial == BodyPartContent.OverrideMaterial))
		{
			return;
		}

		if(UseSkeletalMesh == none)
		{
			UseMeshComponent.SetSkeletalMesh(none);
		}

		UpperFacialContent = BodyPartContent;
		break;

	case 'FacePropsLower':
		UseMeshComponent = m_kLowerFacialMC;
		if(HelmetContent != none && (HelmetContent.bHideLowerFacialProps || bHideForUnderlay))
		{
			UseSkeletalMesh = none;
			bSkipAttachment = true;
		}

		if(UseMeshComponent.SkeletalMesh == UseSkeletalMesh && LowerFacialContent != none && 
		   ((!BodyPartContent.ShouldUseOverrideMaterial() && !LowerFacialContent.ShouldUseOverrideMaterial()) || LowerFacialContent.OverrideMaterial == BodyPartContent.OverrideMaterial))
		{
			return;
		}

		if(UseSkeletalMesh == none)
		{
			UseMeshComponent.SetSkeletalMesh(none);
		}

		LowerFacialContent = BodyPartContent;
		break;

	case 'Helmets':
		if( HelmetContent == BodyPartContent )
		{
			return;
		}
		HelmetContent = XComHelmetContent(ContentRequest.kContent);
		UseMeshComponent = m_kHelmetMC;
		if(HelmetContent != none && bHideForUnderlay)
		{
			UseMeshComponent.SetSkeletalMesh(none);
			bSkipAttachment = true;
		}
		break;
	}

	if(!bSkipAttachment || UseSkeletalMesh == none)
	{
		//Detach the old component
		// Remove old hairs/props
		RemoveProp(UseMeshComponent);		

		if(Mesh.GetSocketByName(BodyPartContent.SocketName) != none && UsePhysicsAsset != none)
		{
			`log("XComHumanPawn.OnBodyPartLoaded: Attaching" @ UseSkeletalMesh $"/"$ UsePhysicsAsset @ "to socket" @ BodyPartContent.SocketName @ "on" @ self, , 'DevStreaming');


			// See notes on this in XComPawnPhysicsProp.
			// Most of the following is very order dependent for attaching a rigid body SkeletalMesh
			// onto a socket of the pawn's SkeletalMeshComponent ("Mesh")
			PhysicsProp = Spawn(class'XComPawnPhysicsProp', self);
			PhysicsProp.CollisionComponent = PhysicsProp.SkeletalMeshComponent;
			m_aPhysicsProps.AddItem(PhysicsProp);
			PhysicsProp.SetBase(self);
			PhysicsProp.SetTickGroup(TG_PostUpdateWork);
			Mesh.bForceUpdateAttachmentsInTick = true;
			UseMeshComponent = PhysicsProp.SkeletalMeshComponent;
			UpdateMorphs(UseMeshComponent, UseMorph);
			UseMeshComponent.SetSkeletalMesh(UseSkeletalMesh);
			ResetMaterials(UseMeshComponent);
			if (BodyPartContent.ShouldUseOverrideMaterial())
			{
				UseMeshComponent.SetMaterial(0, BodyPartContent.OverrideMaterial);
			}
						
			switch(ContentRequest.ContentCategory)
			{
				case 'Hair':
					m_kHairMC = UseMeshComponent;
					break;
				case 'Beards':
					m_kBeardMC = UseMeshComponent;
					break;
				case 'FacePropsUpper':
					m_kUpperFacialMC = UseMeshComponent;
					break;
				case 'FacePropsLower':
					m_kLowerFacialMC = UseMeshComponent;
					break;
				case 'Helmets':
					m_kHelmetMC = UseMeshComponent;
					break;
			}

			//Regardless of physics setup, attach the mesh to the right socket
			Mesh.AttachComponentToSocket(UseMeshComponent, BodyPartContent.SocketName, BodyPartContent.SocketName);

			//Part 2 of physics setup
			UseMeshComponent.SetPhysicsAsset(UsePhysicsAsset, true);
			UseMeshComponent.SetHasPhysicsAssetInstance(true);
			UseMeshComponent.WakeRigidBody();			

			UseMeshComponent.SetAcceptsDynamicDecals(FALSE); // Fix for blood puddles appearing on the hair.
			UseMeshComponent.SetAcceptsStaticDecals(FALSE);
		}
		else
		{
			//Make a new one and set it up
			UseMeshComponent = new(self) class'SkeletalMeshComponent';
			switch(ContentRequest.ContentCategory)
			{
				case 'Eyes':
					m_kEyeMC = UseMeshComponent;					
					break;
				case 'Teeth':
					m_kTeethMC = UseMeshComponent;					
					break;
				case 'Hair':
					m_kHairMC = UseMeshComponent;
					break;
				case 'Beards':
					m_kBeardMC = UseMeshComponent;
					break;
				case 'FacePropsUpper':
					m_kUpperFacialMC = UseMeshComponent;
					break;
				case 'FacePropsLower':
					m_kLowerFacialMC = UseMeshComponent;
					break;
				case 'Helmets':
					m_kHelmetMC = UseMeshComponent;
					break;
			}
						
			UseMeshComponent.LastRenderTime = WorldInfo.TimeSeconds;
			UpdateMorphs(UseMeshComponent, UseMorph);
			UseMeshComponent.SetSkeletalMesh(UseSkeletalMesh);
			ResetMaterials(UseMeshComponent);
			if (BodyPartContent.ShouldUseOverrideMaterial())
			{
				UseMeshComponent.SetMaterial(0, BodyPartContent.OverrideMaterial);
			}
			if(UseMeshComponent.SkeletalMesh != none)
			{
				UseMeshComponent.SetParentAnimComponent(Mesh);
				UseMeshComponent.bUpdateMorphWhenParentAnimComponentExists = true;
				Mesh.AppendSockets(UseMeshComponent.Sockets, true);
			}

			UpdateMeshMaterials(UseMeshComponent);
			AttachComponent(UseMeshComponent); //Attach the new component
		}

		MarkAuxParametersAsDirty(m_bAuxParamNeedsPrimary, m_bAuxParamNeedsSecondary, m_bAuxParamUse3POutline);
	}
}

function UpdateMorphs(SkeletalMeshComponent CheckMeshComponent, MorphTargetSet UseMorph)
{
	//Cache the old one
	if(CheckMeshComponent.MorphSets.Length > 0)
	{
		if(OldMorphSets.Find(CheckMeshComponent.MorphSets[0]) == INDEX_NONE)
		{
			OldMorphSets.AddItem(CheckMeshComponent.MorphSets[0]);
		}
	}
	

	CheckMeshComponent.MorphSets.Length = 0;
	if(UseMorph != none)
	{
		CheckMeshComponent.MorphSets.AddItem(UseMorph);
	}
}

simulated function OnTorsoLoaded(PawnContentRequest ContentRequest)
{
	TorsoContent = XComTorsoContent(ContentRequest.kContent);
	m_kTorsoComponent.SetSkeletalMesh(TorsoContent.SkeletalMesh);
	ResetMaterials(m_kTorsoComponent);	
	if(TorsoContent.OverrideMaterial != none)
	{
		m_kTorsoComponent.SetMaterial(0, TorsoContent.OverrideMaterial);
	}
	m_kTorsoComponent.SetParentAnimComponent(Mesh);
	
	Mesh.AppendSockets(m_kTorsoComponent.Sockets, true);
	MarkAuxParametersAsDirty(m_bAuxParamNeedsPrimary, m_bAuxParamNeedsSecondary, m_bAuxParamUse3POutline);
}

simulated function RemoveHair()
{
	if (HairComponent != none)
	{
		Mesh.DetachComponent(HairComponent);
		HairComponent = none;
	}
}

simulated function AttachAuxMesh(SkeletalMesh SkelMesh, out SkeletalMeshComponent SkelMeshComp)
{
	DetachAuxMesh(SkelMeshComp);

	SkelMeshComp = new(self) class'SkeletalMeshComponent';
	SkelMeshComp.SetSkeletalMesh(SkelMesh);
	ResetMaterials(SkelMeshComp);
	SkelMeshComp.SetParentAnimComponent(Mesh);
	SkelMeshComp.SetLightEnvironment(LightEnvironment);
	SkelMeshComp.SetShadowParent(Mesh);
	SkelMeshComp.PrestreamTextures(10.0f, true);
	AttachComponent(SkelMeshComp);

	MarkAuxParametersAsDirty(m_bAuxParamNeedsPrimary, m_bAuxParamNeedsSecondary, m_bAuxParamUse3POutline);
}

simulated function DetachAuxMesh(out SkeletalMeshComponent SkelMeshComp)
{
	if (SkelMeshComp != none)
	{
		DetachComponent(SkelMeshComp);
		SkelMeshComp = none;
	}
}

simulated function OnVoiceLoaded(PawnContentRequest ContentRequest)
{
	if(Voice == XComCharacterVoice(ContentRequest.kContent))
		return;

	Voice = XComCharacterVoice(ContentRequest.kContent);
	`log("Voice loaded:" @ Voice.Name @ "for" @ Name,,'XCom_Content');
	
	// If we're in tactical, we need to stream in a bank for the voice to use -- jboswell
	if (Voice != none && Voice.CurrentVoiceBank == none)
		Voice.StreamNextVoiceBank();
}

simulated function SetAppearance( const out TAppearance kAppearance, optional bool bRequestContent=true )
{
	m_kAppearance = kAppearance;
	
	// jboswell: detect level 3 armor

	Replicated_kAppearance = m_kAppearance;

	bIsFemale = (m_kAppearance.iGender == eGender_Female);

	m_bSetAppearance = true;

	if (bRequestContent)
	{
		RequestFullPawnContent();
	}
}

// apply non-empty appearance values to existing appearance. 
simulated function UpdateAppearance( const out TAppearance kAppearance, optional bool bRequestContent=true )
{
	if (!m_bSetAppearance)
	{
		SetAppearance(kAppearance, bRequestContent);
		return;
	}

	if (kAppearance.nmArms != '')
	{
		m_kAppearance.nmArms = kAppearance.nmArms;
	}
	if (kAppearance.nmBeard != '')
	{
		m_kAppearance.nmBeard = kAppearance.nmBeard;
	}
	if (kAppearance.nmEye != '')
	{
		m_kAppearance.nmEye = kAppearance.nmEye;
	}
	if (kAppearance.nmFacePropLower != '')
	{
		m_kAppearance.nmFacePropLower = kAppearance.nmFacePropLower;
	}
	if (kAppearance.nmFacePropUpper != '')
	{
		m_kAppearance.nmFacePropUpper = kAppearance.nmFacePropUpper;
	}
	if (kAppearance.nmFlag != '')
	{
		m_kAppearance.nmFlag = kAppearance.nmFlag;
	}
	if (kAppearance.nmHaircut != '')
	{
		m_kAppearance.nmHaircut = kAppearance.nmHaircut;
	}
	if (kAppearance.nmHead != '')
	{
		m_kAppearance.nmHead = kAppearance.nmHead;
	}
	if (kAppearance.nmHelmet != '')
	{
		m_kAppearance.nmHelmet = kAppearance.nmHelmet;
	}
	if (kAppearance.nmLanguage != '')
	{
		m_kAppearance.nmLanguage = kAppearance.nmLanguage;
	}
	if (kAppearance.nmLegs != '')
	{
		m_kAppearance.nmLegs = kAppearance.nmLegs;
	}
	if (kAppearance.nmPatterns != '')
	{
		m_kAppearance.nmPatterns = kAppearance.nmPatterns;
	}
	if (kAppearance.nmPawn != '')
	{
		m_kAppearance.nmPawn = kAppearance.nmPawn;
	}
	if (kAppearance.nmTeeth != '')
	{
		m_kAppearance.nmTeeth = kAppearance.nmTeeth;
	}
	if (kAppearance.nmTorso != '')
	{
		m_kAppearance.nmTorso = kAppearance.nmTorso;
	}
	if (kAppearance.nmVoice != '')
	{
		m_kAppearance.nmVoice = kAppearance.nmVoice;
	}
	
	Replicated_kAppearance = m_kAppearance;

	bIsFemale = (m_kAppearance.iGender == eGender_Female);

	if (bRequestContent)
	{
		RequestFullPawnContent();
	}
}


// Only used in CharacterCustomization
function Init( const out TCharacter InCharacter, const out TInventory Inv, const out TAppearance Appearance );
simulated function SetRace(ECharacterRace Race);
simulated function SetInventory(const out TCharacter InCharacter, const out TInventory Inv, const out TAppearance Appearance);
simulated function RotateInPlace(int Dir);
simulated function RequestKitPostArmor();

reliable client function UnitSpeak( Name nEvent )
{
	if (Voice != none)
	{
		`log(self.Name$".UnitSpeak: Playing sound for" @ nEvent, , 'DevSound');
		Voice.PlaySoundForEvent(nEvent, self);
	}
	else
	{
		`log(self.Name$".UnitSpeak: Missing voice on" @ self.Name,, 'DevSound');
	}
}

simulated event OutsideWorldBounds()
{
	`log("OutsideWorldBounds:" @ Name);
}

simulated event FellOutOfWorld(class<DamageType> DmgType)
{
	`log("FellOutOfWorld:" @ Name);
}

simulated function bool IsPawnReadyForViewing()
{
	if (!bHidden)       //  already shown so don't do further checks
		return true;

	if (fHiddenTime > MAX_HIDDEN_TIME)
	{
		`log(self @ "HiddenTime exceeded max time of" @ MAX_HIDDEN_TIME,,'DevStreaming');
		return true;
	}
	return IsUnitFullyComposed();
}

simulated function ReadyForViewing()
{	
	//  Force LastRenderTime to prevent anim craziness
	m_kHeadMeshComponent.LastRenderTime = WorldInfo.TimeSeconds;
	Mesh.LastRenderTime = WorldInfo.TimeSeconds;
	InitLeftHandIK();
	
	SetHidden(false);
	ForceUpdateComponents( false, false );
}

simulated function InitLeftHandIK()
{
	local name IKSocketName;
	local Name WeaponSocketName;
	local SkeletalMeshComponent PrimaryWeaponMeshComp;
	local Vector vLeftHandIKLoc;
	local Rotator rRot;

	IKSocketName = GetLeftHandIKSocketName();
	WeaponSocketName = GetLeftHandIKWeaponSocketName();
	foreach Mesh.AttachedComponentsOnBone(class'SkeletalMeshComponent', PrimaryWeaponMeshComp, WeaponSocketName)
	{
		// Just do the first one
		break;
	}
	if( LeftHandIK != None && PrimaryWeaponMeshComp != None)
	{
		if( PrimaryWeaponMeshComp != none && PrimaryWeaponMeshComp.GetSocketWorldLocationAndRotation(IKSocketName, vLeftHandIKLoc, rRot) )
		{
			if ( ( (m_bLeftHandIKAnimOverrideEnabled && m_bLeftHandIKAnimOverrideOn) || (!m_bLeftHandIKAnimOverrideEnabled && m_bLeftHandIKEnabled) ) && LeftHandIK.ControlStrength < 1.0f )
			{
				LeftHandIK.ControlStrength = 1.0f;
			}
			else if ( ( (m_bLeftHandIKAnimOverrideEnabled && !m_bLeftHandIKAnimOverrideOn) || (!m_bLeftHandIKAnimOverrideEnabled && !m_bLeftHandIKEnabled) ) && LeftHandIK.ControlStrength > 0.0f )
			{
				LeftHandIK.ControlStrength = 0.0f;
			}			
		}
		else
		{
			// if no IK socket, turn IK off
			LeftHandIK.ControlStrength = 0.0f;
		}
	}
}

function OnArmorLoaded(object ArmorArchetype, int ContentID, int SubID);        //  for strategy

function PlayHQIdleAnim(optional name OverrideAnimName, optional bool bIsCapture = false, optional bool bIgnoreInjuredAnim = false)
{
	local XComGameState_Unit UnitState;
	local X2SoldierPersonalityTemplate PersonalityData;
	local CustomAnimParams PlayAnimParams;
	local int HealTimeHours;

	if(OverrideAnimName != '')
	{
		PlayAnimParams.AnimName = OverrideAnimName;
	}
	else
	{
		if(UnitState_Menu == none)
			UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ObjectID));
		else
			UnitState = UnitState_Menu;

		if(UnitState != None)
		{
			if(bIsCapture) //This refers to photo capture, and not game play capturing of VIPs
			{
				PlayAnimParams.AnimName = X2SoldierPersonalityTemplate(class'X2StrategyElementTemplateManager'.static.GetStrategyElementTemplateManager().FindStrategyElementTemplate('Personality_ByTheBook')).IdleAnimName;
			}
			else
			{
				PersonalityData = UnitState.GetPersonalityTemplate();
				if( PersonalityData != none )
				{
					if (!UnitState.IsInjured() || bIgnoreInjuredAnim)
					{
						PlayAnimParams.AnimName = PersonalityData.IdleAnimName;
					}
					else
					{
						UnitState.GetWoundState(HealTimeHours);
						if (UnitState.IsGravelyInjured(HealTimeHours))
						{
							PlayAnimParams.AnimName = PersonalityData.IdleGravelyInjuredAnimName;
						}
						else
						{
							PlayAnimParams.AnimName = PersonalityData.IdleInjuredAnimName;
						}
					}
				}
			}
		}
		
		if(!AnimTreeController.CanPlayAnimation(PlayAnimParams.AnimName))
		{
			PlayAnimParams.AnimName = DefaultIdleAnimation != '' ? DefaultIdleAnimation : 'HL_Idle'; //Fall back to combat idle if we can't play our anim
		}
	}


	if(AnimTreeController.CanPlayAnimation(PlayAnimParams.AnimName))
	{
		PlayAnimParams.BlendTime = 0.5f;
		PlayAnimParams.Looping = true;
		PlayAnimParams.PlayRate = class'XComIdleAnimationStateMachine'.static.GetNextIdleRate();
		AnimTreeController.PlayFullBodyDynamicAnim(PlayAnimParams);
	}
}

state InHQ
{
	simulated event BeginState(name PreviousStateName)
	{
		super.BeginState(PreviousStateName);

		m_bSetReadyForViewing = false;

		SetHidden(true);
		bCanFly=true; // Allows the unit to use PHYS_Flying, so as not to fall through the ground when he's floating
		bCollideWorld=false; // In strategy, all character placement is faked, no collision
		SetPhysics(PHYS_None);
		ForceUpdateComponents( false, false );
	}

	simulated event EndState(name NextStateName)
	{
		super.EndState(NextStateName);

		// Clean up all Character Customization junk -- jboswell
		bCollideWorld = default.bCollideWorld;
	}

	simulated function Tick(float DT)
	{
		super.Tick(DT);

		if (!m_bSetReadyForViewing && bHidden)
		{
			fHiddenTime += DT;
			if (IsPawnReadyForViewing())
			{
				m_bSetReadyForViewing = true;

				if( CurrentHairContent != none )
					SetTimer(0.02f, false, 'WakeHair');

				SetTimer(0.03f, false, 'ReadyForViewing');							
			}
		}
	}

	simulated function RemoveFromMatinee()
	{
		FreezeHair();

		if( Mesh != none )
		{
			Mesh.bAllowSetAnimPositionWhenNotRendered = false;
			Mesh.bTickAnimNodesWhenNotRendered = false;
			SetUpdateSkelWhenNotRendered(true);
			Mesh.bForceUpdateAttachmentsInTick = false;
		}
	}

	function Init( const out TCharacter InCharacter, const out TInventory Inv, const out TAppearance Appearance )
	{
		Character = InCharacter;
		bIsFemale = (Appearance.iGender == eGender_Female); // Must be set first, other functions have dependencies
		m_kAppearance = Appearance; // jboswell: we need values from this as part of armor loading :\

		SetAppearance(Appearance, false);
		SetInventory(Character, Inv, Appearance);		
		SetPhysics(PHYS_None);
		SetAuxParameters(true, false, false);
	}

	simulated function SetAppearance(const out TAppearance Appearance, optional bool bRequestContent=true)
	{
`if(`notdefined(FINAL_RELEASE))
		if (bDebug)
			GetALocalPlayerController().RemoveAllDebugStrings();
`endif

		super.SetAppearance(Appearance, bRequestContent);
	}

	simulated function SetRace(ECharacterRace Race)
	{
		/* jbouscher - refactoring appearance to use templates
		m_kAppearance.iRace = Race;
		FindPossibleCustomParts(Character);
		m_kAppearance.iHead = PossibleHeads[Rand(PossibleHeads.Length)];
		//m_kAppearance.iHaircut = PossibleHairs[Rand(PossibleHairs.Length)];       //  no need to change hair as it is now universal
		m_kAppearance.iSkinColor = 0; // must re-do this, each race has a different palette -- jboswell
		SetAppearance(m_kAppearance);
		*/
	}

	simulated function SetInventory(const out TCharacter InCharacter, const out TInventory Inv, const out TAppearance Appearance)
	{		
		// Clear existing attachments, kits, and jetpacks
		RemoveAttachments();

		BaseArmorTint.Primary.R = 0;
		BaseArmorTint.Primary.G = 0;
		BaseArmorTint.Primary.B = 0;
		BaseArmorTint.Secondary.R = 0;
		BaseArmorTint.Secondary.G = 0;
		BaseArmorTint.Secondary.B = 0;

		m_iArmor = Inv.iArmor;
		m_kAppearance = Appearance;
		m_bHasGeneMods = false;
		m_bSetArmorKit = true;	      
		RequestFullPawnContent();
	}

	// Async load callbacks
	simulated function OnHeadLoaded(PawnContentRequest ContentRequest)
	{
		local XComLinearColorPalette Palette;

		super.OnHeadLoaded(ContentRequest);

		// cache the number of possible skin colors
		NumPossibleSkinColors = 0;
		if (HeadContent != none)
		{
			Palette = `CONTENT.GetColorPalette(HeadContent.SkinPalette);
			NumPossibleSkinColors = Palette.Entries.Length;
		}

		SetLightingChannelsForUnit();

`if(`notdefined(FINAL_RELEASE))
		if (bDebug)
			DrawDebugString(vect(0,0,48), HeadContent.SkeletalMesh.Name, self, MakeColor(255, 0, 0, 255), -1.0f);
`endif
	}

	simulated function RequestKitPostArmor()
	{
		local EArmorKit ArmorDeco;
		// Cannot call AttachKit(), it has tactical dependencies
		if (!IsA('XComMECPawn'))
		{
			if (m_kAppearance.iArmorDeco != INDEX_NONE)
			{
				ArmorDeco = EArmorKit(m_kAppearance.iArmorDeco);
				m_iRequestKit = ArmorDeco;
			}
			else
			{
				//  gene mod only has deco, don't fall back to old kits
				if (m_bHasGeneMods)
				{
					m_iRequestKit = INDEX_NONE;
				}
				else
				{
					m_iRequestKit = INDEX_NONE;
				}
			}
		}
		
	}

	function OnWeaponLoaded(object WeaponArchetype)
	{
		local int AttachIdx;
		local SkeletalMeshActor NewWeapon;
		local MeshComponent FoundMeshComponent;

		if (ActiveAttachments.Length > 0)
		{
			NewWeapon = Spawn( class'SkeletalMeshActorSpawnable', self,,,,, true);
			NewWeapon.SkeletalMeshComponent.SetSkeletalMesh(SkeletalMesh(WeaponArchetype));
			NewWeapon.SkeletalMeshComponent.SetLightEnvironment(LightEnvironment);

			AttachIdx = ActiveAttachments.Length-1; // last attachment
			ActiveAttachments[AttachIdx].Component = NewWeapon.SkeletalMeshComponent;
			ActiveAttachments[AttachIdx].ItemActor = NewWeapon;
			AttachItem(NewWeapon, ActiveAttachments[AttachIdx].SocketName, false, FoundMeshComponent);
		}

		SetLightingChannelsForUnit();
	}

	function SetLightingChannelsForUnit()
	{
		local ItemAttachment Item;

		if (Mesh != none)
		{
			Mesh.bCastDynamicShadow = true;
		}

		if (HairComponent != none)
		{
			HairComponent.bCastDynamicShadow = true;
			HairComponent.SetShadowParent(Mesh);
		}

		if (m_kHeadMeshComponent != none)
		{
			m_kHeadMeshComponent.bCastDynamicShadow = true;
			m_kHeadMeshComponent.SetShadowParent(Mesh);
		}

		foreach ActiveAttachments(Item)
		{
			if( Item.Component != none)
			{
				Item.Component.bCastDynamicShadow = true;
				Item.Component.SetShadowParent(Mesh);
			}
		}
	}
}

state CharacterCustomization extends InHQ
{
	simulated event BeginState(name PreviousStateName)
	{
		super.BeginState(PreviousStateName);
		SetUpdateSkelWhenNotRendered(true);
	}

	simulated function OnPostInitAnimTree()
	{	
		SetTimer(0.03f, false, nameof(PlayHQIdleAnim));
	}

	simulated function RotateInPlace(int Dir)
	{
		local rotator SoldierRot;
		SoldierRot = Rotation;
		SoldierRot.Pitch = 0;
		SoldierRot.Roll = 0;
		SoldierRot.Yaw += 45.0f * class'Object'.const.DegToUnrRot * 0.33f * Dir;
		SetDesiredRotation(SoldierRot);
	}
begin:
	PlayHQIdleAnim(CustomizationIdleAnim);
}

state PortraitCapture extends InHQ
{
	simulated event BeginState(name PreviousStateName)
	{
		super.BeginState(PreviousStateName);
				
		SetUpdateSkelWhenNotRendered(true);
	}
		
	simulated function PlayPortraitIdleAnim()
	{
		PlayHQIdleAnim(,true);
	}

	simulated function OnPostInitAnimTree()
	{
		SetTimer(0.03f, false, nameof(PlayPortraitIdleAnim));
	}

	simulated function RotateInPlace(int Dir)
	{
		local rotator SoldierRot;
		SoldierRot = Rotation;
		SoldierRot.Pitch = 0;
		SoldierRot.Roll = 0;
		SoldierRot.Yaw += 45.0f * class'Object'.const.DegToUnrRot * 0.33f * Dir;
		SetDesiredRotation(SoldierRot);
	}
begin:
	PlayHQIdleAnim(,true);
}

state SquadLineup_Walkup extends CharacterCustomization
{
	//Plays the character's walk up
	function AnimNodeSequence PlayWalkUpAnim()
	{		
		local AnimNodeSequence PlayAnim;
		local XComGameState_Unit UnitState;
		local XComGameStateHistory History;
		local X2SoldierPersonalityTemplate PersonalityData;
		local int HealTimeHours;

		History = `XCOMHISTORY;

		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(ObjectID));
		if(UnitState != None)
		{
			PersonalityData = UnitState.GetPersonalityTemplate();
			if (!UnitState.IsInjured())
			{
				PlayAnim = PlayFullBodyAnimOnPawn(PersonalityData.PostMissionWalkUpAnimName, false);
			}
			else
			{
				UnitState.GetWoundState(HealTimeHours);
				if (UnitState.IsGravelyInjured(HealTimeHours))
				{
					PlayAnim = PlayFullBodyAnimOnPawn(PersonalityData.PostMissionGravelyInjuredWalkUpAnimName, false);
				}
				else
				{
					PlayAnim = PlayFullBodyAnimOnPawn(PersonalityData.PostMissionInjuredWalkUpAnimName, false);
				}
			}
		}

		return PlayAnim;
	}
	
begin:
	FinishAnim(PlayWalkUpAnim());
	PlayHQIdleAnim();
}

state SquadLineup_Walkaway extends CharacterCustomization
{
	//Plays the character's walk up
	function AnimNodeSequence PlayWalkAwayAnim()
	{
		local AnimNodeSequence PlayAnim;
		local XComGameState_Unit UnitState;
		local XComGameStateHistory History;
		local X2SoldierPersonalityTemplate PersonalityData;

		History = `XCOMHISTORY;

		UnitState = XComGameState_Unit(History.GetGameStateForObjectID(ObjectID));
		if(UnitState != None)
		{
			PersonalityData = UnitState.GetPersonalityTemplate();
			PlayAnim = PlayFullBodyAnimOnPawn(PersonalityData.PostMissionWalkBackAnimName, false);
		}

		return PlayAnim;
	}

begin:
	FinishAnim(PlayWalkAwayAnim());
	PlayHQIdleAnim();
}

state OffDuty extends InHQ
{
	simulated event BeginState(name PreviousStateName)
	{
		super.BeginState(PreviousStateName);

		SetAppearance(m_kAppearance);
	}

	simulated event EndState(name NextStateName)
	{
		super.EndState(NextStateName);

		SetBase(none);
		SetAppearance(m_kAppearance);
	}

	// No Weapons or Armor Kits
	simulated function OnArmorKitLoaded(Object KitArchetype)
	{
	}

	simulated function OnWeaponLoaded(Object WeaponArchetype)
	{
		ActiveAttachments.Length = 0; // No attachments
	}

	simulated function OnHeadLoaded(PawnContentRequest ContentRequest)
	{
		super.OnHeadLoaded(ContentRequest);

		UpdateMeshMaterials(m_kHeadMeshComponent);
		UpdateMeshMaterials(Mesh);
	}

	simulated function OnArmorLoaded(Object ArmorArchetype, int ContentID, int SubID)
	{
		super.OnArmorLoaded(ArmorArchetype, ContentID, SubID);

		UpdateMeshMaterials(Mesh);
	}

	simulated function bool AreHelmetsAllowed()
	{
		return false;
	}
}

simulated function bool IsUnitFullyComposed(optional bool bBoostTextures=true)
{
	return super.IsUnitFullyComposed(bBoostTextures);
}

defaultproperties
{
	m_iRequestKit=INDEX_NONE
	PreviousVoiceSound=INDEX_NONE
}
