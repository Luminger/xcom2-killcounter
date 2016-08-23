class UISaveLoadGameListItem extends UIPanel;

var UIButton AcceptButton;
var UIButton DeleteButton;
var UIButton RenameButton;

var OnlineSaveGame SaveGame;

var int               Index;
var bool              bIsSaving;
var UIPanel ButtonBG;
var name ButtonBGLibID;
var string DateTimeString;
var bool bIsDifferentLanguage;

var UIList List;

var localized string m_sNewSaveLabel;
var localized string m_sSaveLabel;
var localized string m_sLoadLabel;
var localized string m_sDeleteLabel;
var localized string m_sRenameLabel;

var delegate<OnMouseInDelegate> OnMouseIn;

// mouse callbacks
delegate OnClickedDelegate(UIButton Button);
delegate OnMouseInDelegate(int ListIndex);
simulated function UIPanel InitPanel(optional name InitName, optional name InitLibID)
{
	super.InitPanel(InitName, InitLibID);

	List = UIList(GetParent(class'UIList')); // list items must be owned by UIList.ItemContainer
	if(List == none)
	{
		ScriptTrace();
		`warn("UI list items must be owned by UIList.ItemContainer");
	}

	return self;
}

simulated function UISaveLoadGameListItem InitSaveLoadItem(int listIndex, OnlineSaveGame save, bool bSaving, optional delegate<OnClickedDelegate> AcceptClickedDelegate, optional delegate<OnClickedDelegate> DeleteClickedDelegate, optional delegate<OnClickedDelegate> RenameClickedDelegate, optional delegate<OnMouseInDelegate> MouseInDelegate)
{
	local int ID;
	local string acceptLabel;
	local XComOnlineEventMgr OnlineEventMgr;

	OnlineEventMgr = `ONLINEEVENTMGR;

	ID = OnlineEventMgr.SaveNameToID(save.Filename);
	InitPanel();
	Index = listIndex;

	SaveGame = save;
	bIsSaving = bSaving;
	
	SetWidth(List.width);

	SetY(135 * listIndex);
	ButtonBG = Spawn(class'UIPanel', self);
	ButtonBG.bIsNavigable = false;
	ButtonBG.bCascadeFocus = false;
	ButtonBG.InitPanel(ButtonBGLibID);

	if(bIsSaving)
	{
		if(ID == -1)
		{
			acceptLabel = m_sNewSaveLabel;
		}
		else
		{
			acceptLabel = m_sSaveLabel;
		}
	}
	else
	{
		acceptLabel = m_sLoadLabel;
	}

	//Navigator.HorizontalNavigation = true;
	
	AcceptButton = Spawn(class'UIButton', ButtonBG);
	AcceptButton.InitButton('Button0', acceptLabel, ID == -1? RenameClickedDelegate : AcceptClickedDelegate);
	AcceptButton.OnMouseEventDelegate = OnChildMouseEvent;

	DeleteButton = Spawn(class'UIButton', ButtonBG);
	DeleteButton.InitButton('Button1', m_sDeleteLabel, DeleteClickedDelegate);
	DeleteButton.OnMouseEventDelegate = OnChildMouseEvent;

	Navigator.RemoveControl(AcceptButton);
	Navigator.RemoveControl(DeleteButton);

	Navigator.AddNavTargetLeft(AcceptButton);
	Navigator.AddNavTargetRight(DeleteButton);

	if(bIsSaving && ID == -1)
	{
		DeleteButton.Hide();
	}
	
	RenameButton = Spawn(class'UIButton', ButtonBG);
	RenameButton.bIsNavigable = false;
	RenameButton.InitButton('Button2', m_sRenameLabel, RenameClickedDelegate);
	RenameButton.Hide(); //No longer used, hidden permanantly. 
	RenameButton.OnMouseEventDelegate = OnChildMouseEvent;

	OnMouseIn = MouseInDelegate;

	return self;
}

simulated function OnInit()
{
	super.OnInit();

	UpdateData(SaveGame);
}

simulated function OnChildMouseEvent(UIPanel control, int cmd)
{
	if( OnMouseIn != none )
		OnMouseIn(Index);
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	if( bShouldPlayGenericUIAudioEvents )
	{
		switch( cmd )
		{
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:
			`SOUNDMGR.PlaySoundEvent("Play_Mouseover");
			break;
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_DOUBLE_UP:
			if(AcceptButton != none)
				AcceptButton.Click();
			break;
		}
	}

	if(OnMouseIn != none)
		OnMouseIn(Index);

	if( OnMouseEventDelegate != none )
		OnMouseEventDelegate(self, cmd);
}

simulated function ShowHighlight()
{
	MC.FunctionVoid("mouseIn");
	DeleteButton.OnLoseFocus();
	AcceptButton.OnReceiveFocus();
}

simulated function HideHighlight()
{
	MC.FunctionVoid("mouseOut");
	AcceptButton.OnLoseFocus();
	DeleteButton.OnLoseFocus();
}

simulated function UpdateData(OnlineSaveGame save)
{
	local ASValue myValue;
	local Array<ASValue> myArray;
	local XComOnlineEventMgr OnlineEventMgr;
	local string FriendlyName, mapPath, strDate, strName, strMission, strTime;
	local bool bNewSave;
	local array<string> Descriptions;	
	local SaveGameHeader Header;

	OnlineEventMgr = `ONLINEEVENTMGR;	
	if(save.Filename == "")
	{		
		bNewSave = true;
		OnlineEventMgr.FillInHeaderForSave(Header, FriendlyName);
	}
	else
	{
		Header = save.SaveGames[0].SaveGameHeader;
	}

	MC.FunctionBool("SetAutosave", Header.bIsAutosave);

	bIsDifferentLanguage = (Header.Language != GetLanguage());

	//Parse the description with "\n" as a separator
	// [0] = date [1] = time [2] = save type / player desc [3] = game type [4] = game type detail
	Descriptions = SplitString(Header.Description, "\n");

	//For old save files that used "-"
	if( Descriptions.length < 2 )
		Descriptions = SplitString(Header.Description, "-");

	if(Descriptions.Length < 4)
	{
		strDate = Repl(Header.Time, "\n", " - ") @ Header.Description;
	
		//Handle "custom" description such as what the error reports use
		MC.FunctionBool("SetErrorReport", true);
	}
	else
	{
		strTime = FormatTime(Header.Time);
		strDate = strTime @ (Descriptions.Length >= 3 ? Descriptions[2] : "");

		strName = Descriptions.Length >= 4 ? Descriptions[3] : "";		// A description of the save produced by the game type.
		strMission = Descriptions.Length >= 5 ? Descriptions[4] : "";	// More detail from the game type
		strMission $= Descriptions.Length >= 6 ? " - " $ Descriptions[5] : "";	// More detail from the game type
	}
	
	mapPath = Header.MapImage;

	if(mapPath == "")
	{
		// temp until we get the real screen shots to display
		mapPath = "img:///UILibrary_Common.Xcom_default";
	}
	else
	{
		mapPath = "img:///"$mapPath;
	}

	//Image
	myValue.Type = AS_String;
	myValue.s = mapPath;
	myArray.AddItem(myValue);

	//Date
	myValue.s = strDate;
	myArray.AddItem(myValue);

	//Name
	myValue.s = strName;
	myArray.AddItem(myValue);

	//Mission
	myValue.s = strMission;
	myArray.AddItem(myValue);

	//accept Label
	if(bIsSaving)
	{
		myValue.s = bNewSave ? m_sNewSaveLabel : m_sSaveLabel;
	}
	else
	{
		myValue.s = m_sLoadLabel;
	}
	AcceptButton.SetText(myValue.s);
	myArray.AddItem(myValue);

	//delete label
	myValue.s = m_sDeleteLabel;
	myArray.AddItem(myValue);

	//rename label
	myValue.s = bIsSaving? m_sRenameLabel: " ";
	myArray.AddItem(myValue);

	Invoke("updateData", myArray);
}

simulated function string FormatTime( string HeaderTime )
{
	local string FormattedTime;

	FormattedTime = HeaderTime; 
	if( GetLanguage() == "INT" )
	{
		FormattedTime = `ONLINEEVENTMGR.FormatTimeStampFor12HourClock(FormattedTime);
	}

	FormattedTime = Repl(FormattedTime, "\n", " - ");

	return FormattedTime;
}

simulated function UpdateSaveName(string saveName)
{
	MC.FunctionString("SetDate", DateTimeString @ saveName);
}

simulated function ClearImage()
{
	MC.FunctionVoid("ClearImage");
}


simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local UIButton CurrentButton;
	if( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;

	switch( cmd )
	{
	case class'UIUtilities_Input'.const.FXS_BUTTON_A:
	case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
	case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:

		CurrentButton = DeleteButton.bIsFocused ? DeleteButton : AcceptButton;

		if( CurrentButton.bIsVisible && !CurrentButton.IsDisabled )
		{
			CurrentButton.Click();

			return true;
		}
		//If you don't have a current button, fall down and hit the Navigation system. 
		break;

	case class'UIUtilities_Input'.const.FXS_KEY_DELETE:
		DeleteButton.Click();
		break; 
	}

	return super.OnUnrealCommand(cmd, arg);
}


defaultproperties
{
	LibID = "SaveLoadListItem";
	ButtonBGLibID = "ButtonGroup"
	height = 135;
	bIsDifferentLanguage = false
}