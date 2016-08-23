//----------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIButton.uc
//  AUTHOR:  Samuel Batista
//  PURPOSE: UIButton to interface with XComButton
//----------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//----------------------------------------------------------------------------

class UIButton extends UIPanel;

// Needs to match values in XComButton.as
enum EUIButtonStyle
{
	eUIButtonStyle_NONE,	                    // Don't Style the button
	eUIButtonStyle_HOTLINK_BUTTON,	            // Console & PC + Gamepad hotlink, PC regular button
	eUIButtonStyle_SELECTED_SHOWS_HOTLINK,	    // Console & PC + GamePad shows hot link when selected, PC regulard buttion
	eUIButtonStyle_HOTLINK_WHEN_SANS_MOUSE,	    // Console & PC + Gamepad hotlink, PC nothing
	eUIButtonStyle_BUTTON_WHEN_MOUSE,	        // Console & PC + Gamepad nothing, PC button
};

// Needs to match values in XComButton.as
const FONT_SIZE_2D = 20;
const FONT_SIZE_3D = 24;

var string           Text;               // supports HTML tags - use html tags to center Text, ex: <p align='CENTER'>Text</p>
var string           Icon;               // help Icon (used only with console button styles) - look in 'UIUtilities_Input' for valid values
var EUIButtonStyle   Style;
var int             FontSize;   
var bool            IsDisabled;
var bool			IsBad; 
var bool			IsWarning;
var bool			IsGood;
var bool            IsSelected;
var bool            ResizeToText;
var bool			SizeRealized;
var bool			bNeedsAttention;
var UIPanel         AttentionIcon; 

delegate OnSizeRealized();

// mouse callbacks
delegate OnClickedDelegate(UIButton Button);
delegate OnDoubleClickedDelegate(UIButton Button);

simulated function UIButton InitButton(optional name InitName, optional string InitLabel, optional delegate<OnClickedDelegate> InitOnClicked, optional EUIButtonStyle InitStyle = eUIButtonStyle_BUTTON_WHEN_MOUSE)
{
	InitPanel(InitName);
	SetStyle(InitStyle);
	SetText(InitLabel);
	NeedsAttention(bNeedsAttention);
	OnClickedDelegate = InitOnClicked;

	return self;
}

simulated function UIButton SetText(string newText)
{
	if(Text != newText)
	{
		Text = newText;
		SizeRealized = false;
		mc.FunctionString("setHTMLText", Text);
	}
	return self;
}

// Set alignment of text, valid strings: left, center, right, justify
simulated function UIButton SetTextAlign(string textAlign)
{
	MC.SetString("textAlign", textAlign);
	MC.FunctionVoid("realize");
	return self;
}

// example of obtaining return values from function calls
simulated function float GetTextExtent()
{
	if(bIsInited)
		return Movie.ActionScriptFloat(MCPath $ ".getTextExtent");
	else
		`RedScreen("UI will fail for '" $ MCName $ "': attempting to 'GetTextExtent' of an uninitialized control.");
}

simulated function UIButton SetSelected(bool selected)
{
	if(IsSelected != selected)
	{
		IsSelected = selected;
		mc.FunctionVoid(IsSelected ? "select" : "deselect");
	}
	return self;
}

simulated function UIButton EnableButton()
{
	if(bHasTooltip) RemoveTooltip();
	return SetDisabled(false);
}

simulated function UIButton DisableButton(optional string TooltipText)
{
	return SetDisabled(true, TooltipText);
}

simulated function UIButton SetDisabled(bool disabled, optional string TooltipText )
{
	if(IsDisabled != disabled)
	{
		IsDisabled = disabled;
		mc.FunctionVoid(IsDisabled ? "disable" : "enable");
	}

	if( TooltipText != "" )
		SetTooltipText(TooltipText);
	else if( bHasTooltip )
		RemoveTooltip();

	return self;
}

simulated function UIButton ClearBadButton()
{
	if( bHasTooltip ) RemoveTooltip();
	return SetBad(false);
}

simulated function UIButton BadButton(optional string TooltipText)
{
	return SetBad(true, TooltipText);
}

simulated function UIButton SetBad(bool bIsBad, optional string TooltipText)
{
	if( IsBad != bIsBad )
	{
		IsBad = bIsBad;
		mc.FunctionVoid(IsBad ? "setBad" : "clearBad");
	}

	if( TooltipText != "" )
		SetTooltipText(TooltipText);
	else if( bHasTooltip )
		RemoveTooltip();

	return self;
}

simulated function UIButton SetWarning(bool bIsWarning, optional string TooltipText)
{
	if( IsWarning != bIsWarning)
	{
		IsWarning = bIsWarning;
		mc.FunctionVoid(IsWarning ? "setWarning" : "clearWarning");
	}

	if( TooltipText != "" )
		SetTooltipText(TooltipText);
	else if( bHasTooltip )
		RemoveTooltip();

	return self;
}

simulated function UIButton SetGood(bool bIsGood, optional string TooltipText)
{
	if( IsGood != bIsGood )
	{
		IsGood = bIsGood;
		mc.FunctionVoid(IsGood ? "setGood" : "clearGood");
	}

	if( TooltipText != "" )
		SetTooltipText(TooltipText);
	else if( bHasTooltip )
		RemoveTooltip();

	return self;
}

simulated function UIButton SetGamepadIcon(string newIcon)
{
	if(Icon != newIcon)
	{
		Icon = newIcon;
		mc.FunctionString("setIcon", Icon);
	}
	return self;
}

simulated function UIButton SetFontSize(int newFontSize)
{
	if(FontSize != newFontSize)
	{
		FontSize = newFontSize;
		SetStyle(Style, FontSize, ResizeToText);
	}
	return self;
}

simulated function UIButton SetResizeToText(bool newResizeToText)
{
	if(ResizeTotext != newResizeToText)
	{
		ResizeToText = newResizeToText;
		SetStyle(Style, FontSize, ResizeTotext);
	}
	return self;
}

// example of function with custom params
simulated function UIButton SetStyle(EUIButtonStyle newStyle, optional int newFontSize, optional bool newResizeToText)
{
	// update local vars
	Style = newStyle;
	if(newFontSize > 0) FontSize = newFontSize;
	ResizeToText = ResizeToText || newResizeToText;

	//This may be called before button is initialized and MC created. Upon creation, this will be called with whatever values are current, and pushed across the wire. 
	if( MC != none )
	{
		mc.BeginFunctionOp("setStyle");		// add function
		mc.QueueNumber(float(Style));		// add Style param
		mc.QueueNumber(float(FontSize));	// add FontSize param
		mc.QueueBoolean(ResizeTotext);	    // add ResizeTotext param
		mc.EndOp();                         // add delimiter and process command
	}
	return self;
}

simulated function NeedsAttention(bool bAttention, optional bool bForceOnStage = false)
{
	if( bNeedsAttention != bAttention )
	{
		bNeedsAttention = bAttention;
		MC.FunctionBool("needsAttention", bNeedsAttention);
	}

	if( AttentionIcon == none && ( bForceOnStage || bAttention) )
		CreateAttentionIcon();

	if( AttentionIcon != none )
		AttentionIcon.SetVisible(bNeedsAttention);
}

protected function CreateAttentionIcon()
{
	// We have a member that will either connect to what is on stage, or will 
	// spawn a clip in for us to use.  
	AttentionIcon = Spawn(class'UIPanel', self).InitPanel('attentionIconMC', class'UIUtilities_Controls'.const.MC_AttentionIcon);
	AttentionIcon.DisableNavigation();
	AttentionIcon.SetSize(70, 70); //the animated rings count as part of the size. 
	AttentionIcon.SetPosition(2, 4);
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	local bool bHandled;

	// send a clicked callback
	if( cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_UP )
		bHandled = Click();
	else if( cmd == class'UIUtilities_Input'.const.FXS_L_MOUSE_DOUBLE_UP )
		bHandled = DoubleClick();

	if(!bHandled)
		super.OnMouseEvent(cmd, args);
}

simulated function bool Click()
{
	if( OnClickedDelegate != none && !IsDisabled && bIsVisible )
	{
		OnClickedDelegate(self);
		return true;
	}
	return false;
}

simulated function bool DoubleClick()
{
	if( OnDoubleClickedDelegate != none && !IsDisabled && bIsVisible )
	{
		OnDoubleClickedDelegate(self);
		return true;
	}
	return false;
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	bHandled = true;

	switch( cmd )
	{
	case class'UIUtilities_Input'.const.FXS_BUTTON_A:
	case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
	case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
		Click();
		break;
	default:
		bHandled = false;
		break;
	}
	return bHandled || super.OnUnrealCommand(cmd, arg);
}

simulated function OnCommand(string cmd, string arg)
{
	local array<string> sizeData;
	if( cmd == "RealizeSize" )
	{
		sizeData = SplitString(arg, ",");
		Width = float(sizeData[0]);
		Height = float(sizeData[1]);
		SizeRealized = true;

		if( OnSizeRealized != none )
			OnSizeRealized();
	}
}

defaultproperties
{
	LibID = "XComButton";
	Style = EUIButtonStyle_NONE;
	FontSize = FONT_SIZE_2D;
	IsDisabled = false;
	IsBad = false;
	IsSelected = false;
	ResizeTotext = true;
	bProcessesMouseEvents = true;
	bIsNavigable = true;
	Height = 26;
}

