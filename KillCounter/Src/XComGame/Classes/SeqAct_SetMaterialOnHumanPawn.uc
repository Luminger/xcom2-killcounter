/**
 * Copyright 1998-2011 Epic Games, Inc. All Rights Reserved.
 */
class SeqAct_SetMaterialOnHumanPawn extends SequenceAction;

/** Material to apply to target when action is activated. */
var()	MaterialInterface	NewMaterial;

/** Index in the Materials array to replace with NewMaterial when this action is activated. */
var()	INT					MaterialIndex;

enum MeshEnum
{
	eMeshEnum_Body,
	eMeshEnum_Head,
	eMeshEnum_Hair
};

var()   MeshEnum            MeshToSet;

var()   bool                bSetCustomizationParameters;

event Activated()
{
	local XComHumanPawn PawnToSet;
	local SeqVar_Object TargetObj;
	local MeshComponent MeshComp;
	local MaterialInstanceConstant MIC;

	foreach LinkedVariables(class'SeqVar_Object', TargetObj, "TargetPawns")
	{
		PawnToSet = XComHumanPawn(TargetObj.GetObjectValue());

		if( PawnToSet != none )
		{
			MIC = MaterialInstanceConstant(NewMaterial);
			switch(MeshToSet)
			{
			case eMeshEnum_Head:
				MeshComp = PawnToSet.m_kHeadMeshComponent;				
				if( bSetCustomizationParameters && MIC != none )
					PawnToSet.UpdateSkinMaterial(MIC, true, true);
				break;
			case eMeshEnum_Hair:
				MeshComp = PawnToSet.HairComponent;
				if( bSetCustomizationParameters && MIC != none )
					PawnToSet.UpdateHairMaterial(MIC);
				break;
			case eMeshEnum_Body:			
				MeshComp = PawnToSet.Mesh;
				if( bSetCustomizationParameters && MIC != none )
					PawnToSet.UpdateSkinMaterial(MIC, true, false);
				break;
			default:
				break;
			};

			MeshComp.SetMaterial(MaterialIndex, NewMaterial);
		}
	}
}

defaultproperties
{
	ObjName="Set Material On Human Pawn"
	ObjCategory="Unit"
	VariableLinks[0]=(ExpectedType=class'SeqVar_Object',LinkDesc="TargetPawns",bModifiesLinkedObject=true)

	bSetCustomizationParameters=false
}
