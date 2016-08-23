class XComAnimNodeBlendDynamic extends AnimNodeBlendBase
	native(Animation);

struct native PlayingChild
{
	var BoneAtom    InitialStartingAtom;
	var BoneAtom    DesiredStartingAtom;
	var int			Index;
	var float		DesiredWeight;
	var float		TargetWeight;
	var float		CurrentBlendTime;
	var float		TotalBlendTime;
	var float		StartingWeight;
	var bool		HasFixup;
	var float       FixupBeginTime;
	var float       FixupEndTime;
};

struct native CustomAnimParams
{
	var Name        AnimName;
	var BoneAtom    DesiredEndingAtom;
	var float       TargetWeight;
	var float       BlendTime;
	var float       PlayRate;
	var bool        Looping;
	var bool        HasDesiredEndingAtom;
	var bool		HasPoseOverride;
	var init Array<BoneAtom> Pose;
	var float       StartOffsetTime;
	var bool		IsAdditive;
	var float		PoseOverrideDuration; //Allow the caller to specify a duration for pose override anims

	structdefaultproperties
	{
		AnimName = "None";
		DesiredEndingAtom = (Rotation=(X=0,Y=0,Z=0,W=1), Translation=(X=0,Y=0,Z=0), Scale=1);
		TargetWeight = 1.0f;
		BlendTime = 0.1f;
		PlayRate = 1.0f;
		Looping = false;
		HasDesiredEndingAtom = false;
		HasPoseOverride = false;
		StartOffsetTime = 0.0f;
		IsAdditive = false;
		PoseOverrideDuration = 0.0f;
	}

	structcpptext
	{
		FCustomAnimParams()
		{
			AnimName = FName(TEXT("None"));
			DesiredEndingAtom.SetIdentity();
			TargetWeight = 1.0f;
			BlendTime = 0.1f;
			PlayRate = 1.0f;
			Looping = false;
			HasDesiredEndingAtom = false;
			HasPoseOverride = false;
			StartOffsetTime = 0.0f;
			IsAdditive = false;
			PoseOverrideDuration = 0.0f;
		}
		FCustomAnimParams(EEventParm)
		{
			appMemzero(this, sizeof(FCustomAnimParams));
		}
	}
};

var init Array<PlayingChild> ChildrenPlaying;
var bool ComputedFixupRootMotion;
var BoneAtom FixedUpRootMotionDelta;
var BoneAtom EstimatedCurrentAtom;

native function AnimNodeSequence PlayDynamicAnim(const out CustomAnimParams Params);
native function AnimNodeSequence GetTerminalSequence();

cpptext
{
	virtual void InitAnim(USkeletalMeshComponent* meshComp, UAnimNodeBlendBase* Parent);
	virtual	void TickAnim(FLOAT DeltaSeconds);
	virtual void GetBoneAtoms(FBoneAtomArray& Atoms, const TArray<BYTE>& DesiredBones, FBoneAtom& RootMotionDelta, INT& bHasRootMotion, FCurveKeyArray& CurveKeys);
	virtual void RootMotionProcessed();
	virtual UAnimNodeSequence* GetAnimNodeSequence();
	void CalculateWeights();
	FBoneAtom CalculateDesiredAtom(const UAnimNodeSequence* AnimNodeSeq, const FBoneAtom& StartLocation);
	FBoneAtom CalculateDesiredStartingAtom(const UAnimNodeSequence* AnimNodeSeq, const FBoneAtom& DesiredEndingAtom);
	// Editor Functions
	virtual void OnAddChild(INT ChildNum);
}

defaultproperties
{
	bFixNumChildren = TRUE;
	CategoryDesc = "Firaxis"
}