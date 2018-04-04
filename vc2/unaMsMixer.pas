(*

Copyright 2018 Alex Shamray

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

*)


(*
	----------------------------------------------

	  unaMsMixer.pas
	  MS Mixer interface

	----------------------------------------------
	  Copyright (c) 2002-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 04 Mar 2002

	  modified by:
		Lake, Mar-Dec 2002
		Lake, Jan-Nov 2003
		Lake, Jul 2008
                Lake, Jan 2010

	----------------------------------------------
*)

{$I unaDef.inc}

{$IFDEF DEBUG }
  {$DEFINE LOG_UNAMSMIXER_INFOS }	// log informational messages
  {$DEFINE LOG_UNAMSMIXER_ERRORS }	// log critical errors
{$ENDIF DEBUG }

{*
  Contains class wrappers for MS mixer interface API.
  Refer to MSDN documentation for more information about mixers.

  @Author Lake
  
	Version 2.5.2008.07 Still here
}

unit
  unaMsMixer;

interface

uses
  Windows, unaTypes, MMSystem,
  unaUtils, unaClasses;

type

  //
  // -- unaMsMixerObject --
  //

  {*

  }
  unaMsMixerObject = class(unaObject)
  private
    function checkError(errorCode: MMRESULT{$IFDEF DEBUG}; const method: string{$ENDIF}): bool;
  public
  end;


  //
  // -- unaMsMixerControl --
  //

  unaMsMixerDevice = class;
  unaMsMixerSystem = class;
  unaMsMixerLine = class;

  {*
    Mixer control. Every line has several controls connected to it.
  }
  unaMsMixerControl = class(unaMsMixerObject)
  private
    f_updateCount: int;
    f_controlType: unsigned;
    f_controlClass: unsigned;
    f_controlSubClass: unsigned;
    f_controlUnits: unsigned;
    f_multipleItems: unsigned;
    f_caps: pMixerControlW;
    f_details: pMixerControlDetails;
    //
    f_master: unaMsMixerLine;
    f_listItems: unaList;
    f_listItemsText: unaStringList;
    f_listItemsFilled: bool;
    //
    function getDetails(): pMixerControlDetails;
    procedure setDetails();
    function getIsControl(index: integer): bool;
    function getIsControlClass(index: integer): bool;
    function getControlID(): unsigned;
  public
    constructor create(master: unaMsMixerLine; caps: pMixerControlW);
    destructor Destroy(); override;
    //
    procedure beginUpdate();
    procedure endUpdate();
    //
    function getValue(def: bool; channel: unsigned = 0; index: unsigned = 0): bool; overload;
    function getValueInt(def: int; channel: unsigned = 0; index: unsigned = 0): int;
    function getValue(const def: string; channel: unsigned = 0; index: unsigned = 0): string; overload;
    function getValue(def: unsigned; channel: unsigned = 0; index: unsigned = 0): unsigned; overload;
    function getListItem(channel: unsigned = 0; index: unsigned = 0): pMixerControlDetailsListText;
    //
    procedure setValue(value: bool; channel: int = -1; index: unsigned = 0); overload;
    procedure setValueInt(value: int; channel: int = -1; index: unsigned = 0); 
    procedure setValue(value: unsigned; channel: int = -1; index: unsigned = 0); overload;
    //
    {*
      Returns control caps (should be used as read only).
    }
    property caps: pMixerControlW read f_caps;
    {*
      Specifies control ID.
    }
    property controlID: unsigned read getControlID;
    property details: pMixerControlDetails read f_details;
    {*
      If control is list - stores string items assotiated with list.
    }
    property listItemsText: unaStringList read f_listItemsText;
    //
    property isMultiple: bool index MIXERCONTROL_CONTROLF_MULTIPLE read getIsControl;
    property isUniform: bool index MIXERCONTROL_CONTROLF_UNIFORM read getIsControl;
    property isDisabled: bool index -1{MIXERCONTROL_CONTROLF_DISABLED} read getIsControl;
    //
    property isCustomClass: bool index MIXERCONTROL_CT_CLASS_CUSTOM read getIsControlClass;
    property isFaderClass: bool index MIXERCONTROL_CT_CLASS_FADER read getIsControlClass;
    property isListClass: bool index MIXERCONTROL_CT_CLASS_LIST read getIsControlClass;
    property isMeterClass: bool index MIXERCONTROL_CT_CLASS_METER read getIsControlClass;
    property isNumberClass: bool index MIXERCONTROL_CT_CLASS_NUMBER read getIsControlClass;
    property isSliderClass: bool index MIXERCONTROL_CT_CLASS_SLIDER read getIsControlClass;
    property isSwitchClass: bool index MIXERCONTROL_CT_CLASS_SWITCH read getIsControlClass;
    property isTimeClass: bool index MIXERCONTROL_CT_CLASS_TIME read getIsControlClass;
    //
    property controlType: unsigned read f_controlType;
    property controlClass: unsigned read f_controlClass;
    property controlSubClass: unsigned read f_controlSubClass;
    property controlUnits: unsigned read f_controlUnits;
    //
    property multipleItems: unsigned read f_multipleItems;
  end;


  //
  // -- unaMsMixerLine --
  //

  {*
    Mixer line. Every mixer has 0 or more lines connected to it.
  }
  unaMsMixerLine = class(unaMsMixerObject)
  private
    f_capsW: pMixerLineW;
    //
    f_master: unaMsMixerDevice;
    f_connections: unaObjectList;
    f_controls: unaObjectList;
    //
    procedure enumConnections();
    procedure enumControls();
    function getConnection(index: unsigned): unaMsMixerLine;
    function getControl(index: unsigned): unaMsMixerControl;
    function getCaps(isConnection: bool): pMixerLineW;
    function getIsLineType(index: integer): bool;
  public
    constructor create(master: unaMsMixerDevice; destIndex: unsigned; isConnection: bool = false; sourceIndex: unsigned = 0);
    destructor Destroy(); override;
    //
    function getConnectionCount(): int;
    function getControlCount(): int;
    function getID(): unsigned;
    function locateLine(componentType: unsigned): unaMsMixerLine;
    //
    property caps: pMixerLineW read f_capsW;
    property connection[index: unsigned]: unaMsMixerLine read getConnection;
    property control[index: unsigned]: unaMsMixerControl read getControl; default;
    //
    property isActive: bool index MIXERLINE_LINEF_ACTIVE read getIsLineType;
    property isDisconnected: bool index MIXERLINE_LINEF_DISCONNECTED read getIsLineType;
    property isSource: bool index -1{MIXERLINE_LINEF_SOURCE} read getIsLineType;
  end;


  //
  // -- unaMsMixerDevice --
  //

  {*
    Mixer device.
  }
  unaMsMixerDevice = class(unaMsMixerObject)
  private
    f_index: unsigned;
    f_handle: hMixer;
    f_winHandle: hWnd;
    f_caps: pMixerCapsW;
    //
    f_master: unaMsMixerSystem;
    f_lines: unaObjectList;
    //
    function  getActive(): bool;
    procedure setActive(value: bool);
    //
    function getCaps(): pMixerCapsW;
    function getLine(index: unsigned): unaMsMixerLine;
  protected
    procedure doOpen(); virtual;
    procedure doClose(); virtual;
  public
    constructor create(master: unaMsMixerSystem; index: unsigned);
    destructor Destroy(); override;
    //
    procedure open();
    procedure close();
    procedure enumLines();
    function getLineCount(): int;
    function getID(): UINT;
    function locateTargetLine(targetType: unsigned): unaMsMixerLine;
    function locateDestLine(destination: unsigned): unaMsMixerLine;
    function locateComponentLine(componentType: unsigned = MIXERLINE_COMPONENTTYPE_DST_WAVEIN): unaMsMixerLine;
    //
    property caps: pMixerCapsW read f_caps;
    property active: bool read getActive write setActive;
    property line[index: unsigned]: unaMsMixerLine read getLine; default;
    property winHandle: hWnd read f_winHandle write f_winHandle;
  end;


  //
  // -- unaMsMixerSystem --
  //

  {*
    Mixer system. Use to get access to all mixer devices installed on a system.
  }
  unaMsMixerSystem = class(unaObject)
  private
    f_enumOnCreate: bool;
    f_enumComplete: bool;
    //
    f_mixers: unaObjectList;
    f_selectedMixer: unaMsMixerDevice;
    //
    function getMixer(index: unsigned): unaMsMixerDevice;
    function getConnection(iline: unsigned; iconn: int): unaMsMixerLine;
    //
    function getConnectionControl(iline: unsigned; iconn: int; cclass, ctype: unsigned): unaMsMixerControl;
    function mapMixerIdWin9x(deviceId: unsigned; isInDevice: bool): unsigned;
  protected
    procedure enumMixers(); virtual;
  public
    constructor create(enumOnCreate: bool = true);
    destructor Destroy(); override;
    procedure AfterConstruction(); override;
    //
    procedure enumDevices();
    {*
      returns number of mixers installed on a system.
    }
    function getMixerCount(): int;
    function getMixerId(deviceId: unsigned; isInDevice: bool): int;
    function getMixerIndex(mixerId: unsigned): int;
    function getDeviceId(isInDevice: bool; alsoCheckMapper: bool = false): int;
    //
    {*
      selects and initializes specified mixer. All other methods works
      with selected mixer only. Valid mixer index is from 0 to number of mixers installed - 1.
      You can also specify handle of window to receive mixer-related messages.
    }
    function selectMixer(imixer: int; handle: unsigned = 0): bool; overload;
    function selectMixer(deviceId: unsigned; isInDevice: bool; handle: unsigned = 0): bool; overload;
    //
    {*
      returns name of selected mixer.
    }
    function getMixerName(): wString;
    //
    {*
      returns number of lines for selected mixer.
      Usually mixer has only two lines: recording and playback.
    }
    function getLineCount(): int;
    {*
      returns name of specified line. Name can be short of full.
    }
    function getLineName(iline: unsigned; shortName: bool = false): wString;
    {*
      returns index of output (playback) line when isOut is true,
      or input (recording) line when isOut is false. Returned value
      can be passed as iline parameter for other line-related methods.
      recLevel parameter is internal, do not change it.
    }
    function getLineIndex(isOut: bool = true; recLevel: int = 0): int;
    //
    {*
      returns number of connections for specified line.
    }
    function getLineConnectionCount(iline: unsigned): int;
    {*
      returns name of specified connection for specified line.
      Name can be short or full.
      Valid connection index is from 0 to number returned by
      getLineConnectionCount() - 1.
    }
    function getLineConnectionName(iline: unsigned; iconn: unsigned; shortName: bool = false): wString;
    {*
      returns type of specified connection for specified line, or
      type of line itself when iconn is -1.
    }
    function getLineConnectionType(iline: unsigned; iconn: int): unsigned;
    {*
      returns connection index for specified line with given type.
      If no connection with specified type exists, returns -1.
      Example: getLineConnectionByType(0, MIXERLINE_COMPONENTTYPE_DST_WAVEIN)
    }
    function getLineConnectionByType(iline: unsigned; itype: unsigned; checkControlsNum: bool = true): int;
    //
    {*
      returns ID of a control responsible for volume level for specified
      connection or line (when iconn = -1).
      This ID is useful in window messages handler only.
    }
    function getVolumeControlID(iline: unsigned; iconn: int): int;
    {*
      returns volume level for specified connection or line (when iconn = -1).
      Returned value ranges from 0 (lowest) to 100 (highest).
    }
    function getVolume(iline: unsigned; iconn: int): int;
    {*
      sets volume level for specified control or line (when iconn = -1).
      Valid values for level are from 0 (lowest) to 100 (highest).
    }
    function setVolume(iline: unsigned; iconn: int; value: int): bool;
    //
    {*
      returns control ID responsible for mute checkbox of specified
      connection or line (when iconn = -1).
      This ID is useful in window messages handler only.
    }
    function getMuteControlID(iline: unsigned; iconn: int): int;
    {*
      returns true if specified connection or line (when iconn = -1) is muted.
      Otherwise returns false.
    }
    function isMutedConnection(iline: unsigned; iconn: int): bool;
    {*
      mutes or unmutes specified connection or line (when iconn = -1).
      Returns true if operation was succesfull.
    }
    function muteConnection(iline: unsigned; iconn: int; doMute: bool): bool;
    //
    {*
      returns connection index selected as current recording source.
      If more than one connection can be selected, returns -1.
    }
    function getRecSource(): int;	// returns iconn or -1
    {*
      sets specified connection as current recording source and optionally
      ensures it is not muted if more than one connection can be selected.
    }
    function setRecSource(iconn: unsigned; ensureNotMuted: bool = true): bool;
    //
    property mixer[index: unsigned]: unaMsMixerDevice read getMixer; default;
    //
    property selectedMixer: unaMsMixerDevice read f_selectedMixer;
  end;


implementation


{ unaMsMixerObject }

// --  --
function unaMsMixerObject.checkError(errorCode: MMRESULT{$IFDEF DEBUG }; const method: string{$ENDIF DEBUG }): bool;
begin
  if (MMSYSERR_NOERROR <> errorCode) then begin
    //
    {$IFDEF LOG_UNAMSMIXER_ERRORS }
    logMessage(self._classID + '.checkError(' + {$IFDEF DEBUG }method + {$ENDIF DEBUG }') - failure, errorCode=' + int2str(errorCode));
    {$ENDIF LOG_UNAMSMIXER_ERRORS }
    //
    result := false;
  end
  else
    result := true;
end;


{ unaMsMixerControl }

// --  --
procedure unaMsMixerControl.beginUpdate();
begin
  inc(f_updateCount);
end;

// --  --
constructor unaMsMixerControl.create(master: unaMsMixerLine; caps: pMixerControlW);
begin
  inherited create();
  //
  f_master := master;
  f_caps := malloc(sizeOf(f_caps^), caps);
  //
  f_controlType := caps.dwControlType;
  f_multipleItems := caps.cMultipleItems;
  f_controlClass := (f_controlType and MIXERCONTROL_CT_CLASS_MASK);
  f_controlSubClass := (f_controlType and MIXERCONTROL_CT_SUBCLASS_MASK);
  f_controlUnits := (f_controlType and MIXERCONTROL_CT_UNITS_MASK);
  //
  f_listItems := unaRecordList.create();
  f_listItemsText := unaStringList.create();
  //
  f_details := malloc(sizeOf(f_details^), true, 0);
  f_details.cbStruct := sizeOf(f_details^);
  f_details.dwControlID := controlID;
  f_details.cMultipleItems := choice(isMultiple, f_multipleItems, 0);
  //
  // set cChannels
  if (isCustomClass) then begin
    //
    f_details.cChannels := 0
  end
  else begin
    //
    if (isUniform) then
      f_details.cChannels := 1
    else
      // read all the channels
      f_details.cChannels := f_master.caps.cChannels;
  end;    
  //
  getDetails();
end;

// --  --
destructor unaMsMixerControl.destroy();
begin
  inherited;
  //
  freeAndNil(f_listItems);
  freeAndNil(f_listItemsText);
  //
  mrealloc(f_details.paDetails);
  mrealloc(f_details);
  mrealloc(f_caps);
end;

type
  pBoolArray = ^boolArray;
  boolArray = array[byte] of MIXERCONTROLDETAILS_BOOLEAN;

  pSignedArray = ^signedArray;
  signedArray = array[byte] of MIXERCONTROLDETAILS_SIGNED;

  pUnsignedArray = ^unsignedArray;
  unsignedArray = array[byte] of MIXERCONTROLDETAILS_UNSIGNED;

// --  --
procedure unaMsMixerControl.endUpdate();
begin
  dec(f_updateCount);
  //
  if (f_updateCount < 0) then
    f_updateCount := 0;
  //
  if (1 > f_updateCount) then
    setDetails();
end;

// --  --
function unaMsMixerControl.getControlID(): unsigned;
begin
  result := f_caps.dwControlID;
end;

// --  --
function unaMsMixerControl.getDetails(): pMixerControlDetails;
var
  Z: unsigned;
  i: int;
  offs: unsigned;
  listItem: pMixerControlDetailsListTextW;
begin
  if (
      ((MIXERCONTROL_CT_CLASS_LIST = controlClass) or
       (MIXERCONTROL_CONTROLTYPE_EQUALIZER = controlType) or
       (MIXERCONTROL_CONTROLTYPE_MUX = controlType) or
       (MIXERCONTROL_CONTROLTYPE_MIXER = controlType) or
       (MIXERCONTROL_CONTROLTYPE_MULTIPLESELECT = controlType) or
       (MIXERCONTROL_CONTROLTYPE_SINGLESELECT = controlType))
       and not f_listItemsFilled
     ) then begin
    //
    // fill list items (once)
    //
    f_details.cbDetails := sizeOf(MIXERCONTROLDETAILS_LISTTEXT);
    if (isMultiple) then
      Z := f_details.cChannels * f_details.cMultipleItems * f_details.cbDetails
    else
      Z := f_details.cChannels * f_details.cbDetails;
    //
    mrealloc(f_details.paDetails, Z);
    f_listItems.clear();
    f_listItemsText.clear();
    //
    if (checkError(mixerGetControlDetailsW(f_master.f_master.f_index, f_details, MIXER_GETCONTROLDETAILSF_LISTTEXT + MIXER_OBJECTF_MIXER){$IFDEF DEBUG}, 'getDetails.[1]mixerGetControlDetails'{$ENDIF})) then begin
      //
      offs := 0;
      if (isMultiple) then
	Z := f_details.cChannels * f_details.cMultipleItems
      else
	Z := f_details.cChannels;
      //
      if (0 < Z) then begin
	//
	for i := 0 to Z - 1 do begin
	  //
	  listItem := malloc(sizeOf(listItem^), pMIXERCONTROLDETAILSLISTTEXT(@paChar(f_details.paDetails)[offs]));
	  f_listItems.add(listItem);
	  f_listItemsText.add(string(listItem.szName));
	  inc(offs, f_details.cbDetails);
	end;
      end;
      //
      f_listItemsFilled := true;
    end;
  end;
  //
  case (controlUnits) of

    // custom
    MIXERCONTROL_CT_UNITS_CUSTOM:
      f_details.cbDetails := f_caps.metrics.cbCustomData;

    // bool
    MIXERCONTROL_CT_UNITS_BOOLEAN:
      f_details.cbDetails := sizeOf(MIXERCONTROLDETAILS_BOOLEAN);

    // signed
    MIXERCONTROL_CT_UNITS_SIGNED,
    MIXERCONTROL_CT_UNITS_DECIBELS:
      f_details.cbDetails := sizeOf(MIXERCONTROLDETAILS_SIGNED);

    // unsigned
    MIXERCONTROL_CT_UNITS_UNSIGNED,
    MIXERCONTROL_CT_UNITS_PERCENT:
      f_details.cbDetails := sizeOf(MIXERCONTROLDETAILS_UNSIGNED);

    else
      f_details.cbDetails := 0;

  end;
  //
  // allocate memory for details
  if (0 < f_details.cbDetails) then begin
    //
    Z := f_details.cChannels * f_details.cbDetails * choice(isMultiple, f_details.cMultipleItems, 1);
    mrealloc(f_details.paDetails, Z);
    fillChar(f_details.paDetails^, Z, #0);
    //
    checkError(mixerGetControlDetailsW(f_master.f_master.f_index, f_details, MIXER_GETCONTROLDETAILSF_VALUE + MIXER_OBJECTF_MIXER){$IFDEF DEBUG}, 'getDetails.[2]mixerGetControlDetails'{$ENDIF});
  end;
  //
  result := f_details;
end;

// --  --
function unaMsMixerControl.getIsControl(index: integer): bool;
begin
  if (-1 = index) then
    index := integer(MIXERCONTROL_CONTROLF_DISABLED);
  //
  result := (0 <> (f_caps.fdwControl and index));
  //
  if (MIXERCONTROL_CONTROLF_MULTIPLE = index) then
    // some controls does not have this flag set, while in fact they are multiple
    result := result or (0 < f_multipleItems);
end;

// --  --
function unaMsMixerControl.getIsControlClass(index: integer): bool;
begin
  result := (unsigned(index) = f_controlClass);
end;

// --  --
function unaMsMixerControl.getListItem(channel: unsigned; index: unsigned): pMixerControlDetailsListText;
begin
  if (isUniform) then
    channel := 0;
  //
  if (isMultiple) then
    result := f_listItems[channel * f_multipleItems + index]
  else
    result := f_listItems[channel];
end;

// --  --
function unaMsMixerControl.getValue(def: bool; channel: unsigned; index: unsigned): bool;
begin
  getDetails();
  //
  if (isUniform) then
    channel := 0;
  //
  if (isMultiple) then
    result := (pBoolArray(f_details.paDetails)[channel * f_multipleItems + index].fValue <> 0)
  else
    result := (pBoolArray(f_details.paDetails)[channel].fValue <> 0);
end;

// --  --
function unaMsMixerControl.getvalueInt(def: int; channel: unsigned; index: unsigned): int;
begin
  getDetails();
  //
  if (isUniform) then
    channel := 0;

  if (isMultiple) then
    result := pSignedArray(f_details.paDetails)[channel * f_multipleItems + index].lValue
  else
    result := pSignedArray(f_details.paDetails)[channel].lValue;
end;

// --  --
function unaMsMixerControl.getValue(const def: string; channel: unsigned; index: unsigned): string;
begin
  getDetails();
  //
  if (isUniform) then
    channel := 0;
  //
  if (isMultiple) then
    result := f_listItemsText.get(channel * f_multipleItems + index)
  else
    result := f_listItemsText.get(channel);
end;

// --  --
function unaMsMixerControl.getValue(def: unsigned; channel: unsigned; index: unsigned): unsigned;
begin
  getDetails();
  //
  if (isUniform) then
    channel := 0;

  if (isMultiple) then
    result := pUnsignedArray(f_details.paDetails)[channel * f_multipleItems + index].dwValue
  else
    result := pUnsignedArray(f_details.paDetails)[channel].dwValue;
end;

// --  --
procedure unaMsMixerControl.setDetails();
begin
  checkError(mixerSetControlDetails(f_master.f_master.f_index, f_details, MIXER_SETCONTROLDETAILSF_VALUE + MIXER_OBJECTF_MIXER){$IFDEF DEBUG}, 'setDetails.mixerSetControlDetails'{$ENDIF});
end;

// --  --
procedure unaMsMixerControl.setValue(value: bool; channel: int; index: unsigned);
var
  i: int;
  ch: unsigned;
begin
  beginUpdate();
  try
    if (isUniform) then
      channel := 0;
    //
    ch := choice(0 > channel, 0, channel);
    repeat
      //
      if (isMultiple) then begin
	//
	if (MIXERCONTROL_CONTROLTYPE_MUX = controlType) then begin
	  //
	  if (not value) then
	    // do nothing
	  else begin
	    //
	    if (0 < f_multipleItems) then begin
	      //
	      for i := 0 to f_multipleItems - 1 do
		pBoolArray(f_details.paDetails)[ch * f_multipleItems + unsigned(i)].fValue := choice(unsigned(i) = index, unsigned(1), 0)
	      //
	    end;
	  end
	end
	else
	  pBoolArray(f_details.paDetails)[ch * f_multipleItems + index].fValue := choice(value, unsigned(1), 0)
      end
      else
	pBoolArray(f_details.paDetails)[ch].fValue := choice(value, unsigned(1), 0);
      //
      inc(ch);
      //
    until ((0 <= channel) or (ch >= f_details.cChannels));
    //
  finally
    endUpdate();
  end;
end;

// --  --
procedure unaMsMixerControl.setValueInt(value: int; channel: int; index: unsigned);
var
  ch: unsigned;
begin
  beginUpdate();
  try
    if (isUniform) then
      channel := 0;
    //
    ch := choice(0 > channel, 0, channel);
    repeat
      //
      if (isMultiple) then
	pSignedArray(f_details.paDetails)[ch * f_multipleItems + index].lValue := value
      else
	pSignedArray(f_details.paDetails)[ch].lValue := value;
      //
      inc(ch);
      //
    until ((0 <= channel) or (ch >= f_details.cChannels));
    //
  finally
    endUpdate();
  end;
end;

// --  --
procedure unaMsMixerControl.setValue(value: unsigned; channel: int; index: unsigned);
var
  ch: unsigned;
begin
  beginUpdate();
  try
    if (isUniform) then
      channel := 0;
    //
    ch := choice(0 > channel, 0, channel);
    repeat
      //
      if (isMultiple) then
	pUnsignedArray(f_details.paDetails)[ch * f_multipleItems + index].dwValue := value
      else
	pUnsignedArray(f_details.paDetails)[ch].dwValue := value;
      //
      inc(ch);
      //
    until ((0 <= channel) or (ch >= f_details.cChannels));
    //
  finally
    endUpdate();
  end;
end;


{ unaMsMixerLine }

// --  --
constructor unaMsMixerLine.create(master: unaMsMixerDevice; destIndex: unsigned; isConnection: bool; sourceIndex: unsigned);
begin
  inherited create();
  //
  f_master := master;
  //
  f_controls := unaObjectList.create();
  f_capsW := malloc(sizeOf(f_capsW^), true, 0);
  f_capsW.cbStruct := sizeOf(f_capsW^);
  f_capsW.dwDestination := destIndex;
  f_capsW.dwSource := sourceIndex;
  //
  getCaps(isConnection);
  //
  if (not isConnection) then begin
    f_connections := unaObjectList.create();
    enumConnections();
  end;
  //
  enumControls();
end;

// --  --
destructor unaMsMixerLine.destroy();
begin
  inherited;
  //
  freeAndNil(f_connections);
  freeAndNil(f_controls);
  mrealloc(f_capsW);
end;

// --  --
procedure unaMsMixerLine.enumConnections();
var
  C: unsigned;
begin
  f_connections.clear();
  C := min(128, caps.cConnections);	// sanity check
  while (C > 0) do begin
    //
    dec(C);
    f_connections.add(unaMsMixerLine.create(f_master, f_capsW.dwDestination, true, C));
  end;
end;

// --  --
procedure unaMsMixerLine.enumControls();
var
  i: unsigned;
{$IFNDEF NO_ANSI_SUPPORT }
  detailsA: MixerLineControlsA;
  controlA: pMixerControlA;
  controlW: MixerControlW;
{$ENDIF NO_ANSI_SUPPORT }
  detailsW: MixerLineControlsW;
  offs: unsigned;
  size: unsigned;
  //
  ok: bool;
begin
  f_controls.clear();
  //
  if (0 < caps.cControls) then begin
    //
{$IFNDEF NO_ANSI_SUPPORT }
    if (not g_wideApiSupported) then begin
      //
      fillChar(detailsA, sizeOf(detailsA), #0);
      with detailsA do begin
	cbStruct := sizeOf(detailsA);
	dwLineID := caps.dwLineID;
	cControls := caps.cControls;
	//
	size := sizeOf(detailsA.pamxctrl^);
	cbmxctrl := size;
	mrealloc(pointer(pamxctrl), size * caps.cControls);
      end;
    end
    else begin
      // care about wide only if it is supported
{$ENDIF NO_ANSI_SUPPORT }
      //
      fillChar(detailsW, sizeOf(detailsW), #0);
      with detailsW do begin
	cbStruct := sizeOf(detailsW);
	dwLineID := caps.dwLineID;
	cControls := caps.cControls;
	//
	size := sizeOf(detailsW.pamxctrl^);
	cbmxctrl := size;
	mrealloc(pointer(pamxctrl), size * caps.cControls);
      end;
      //
{$IFNDEF NO_ANSI_SUPPORT }
    end;
{$ENDIF NO_ANSI_SUPPORT }
    //
    try
{$IFNDEF NO_ANSI_SUPPORT }
      if (not g_wideApiSupported) then
	ok := checkError(mixerGetLineControlsA(f_master.f_index, @detailsA, MIXER_GETLINECONTROLSF_ALL + MIXER_OBJECTF_MIXER){$IFDEF DEBUG}, 'enumControls.mixerGetLineControlsA'{$ENDIF})
      else
{$ENDIF NO_ANSI_SUPPORT }
	ok := checkError(mixerGetLineControlsW(f_master.f_index, @detailsW, MIXER_GETLINECONTROLSF_ALL + MIXER_OBJECTF_MIXER){$IFDEF DEBUG}, 'enumControls.mixerGetLineControlsW'{$ENDIF});
      //
      if (ok) then begin
	//
	offs := 0;
	if (0 < caps.cControls) then
	  //
	  for i := 0 to caps.cControls - 1 do begin
{$IFNDEF NO_ANSI_SUPPORT }
	    if (not g_wideApiSupported) then begin
	      //
	      controlA := pMixerControlA(@pArray(detailsA.pamxctrl)[offs]);
	      with controlW do begin
		//
		cbStruct := sizeOf(controlW);
		dwControlID := controlA.dwControlID;
		dwControlType := controlA.dwControlType;
		fdwControl := controlA.fdwControl;
		cMultipleItems := controlA.cMultipleItems;
		//
                {$IFDEF __BEFORE_D6__ }
		str2arrayW(wString(controlA.szShortName),  szShortName);
		str2arrayW(wString(controlA.szName), szName);
                {$ELSE }
		str2arrayW(wString(controlA.szShortName),  szShortName);
		str2arrayW(wString(controlA.szName), szName);
                {$ENDIF __BEFORE_D6__ }
		//
		move(controlA.Bounds,  Bounds, sizeOf(Bounds));
		move(controlA.Metrics, Metrics, sizeOf(Metrics));
	      end;
	      f_controls.add(unaMsMixerControl.create(self, @controlW));
	    end
	    else
{$ENDIF NO_ANSI_SUPPORT }
	      f_controls.add(unaMsMixerControl.create(self, pMixerControlW(@pArray(detailsW.pamxctrl)[offs])));
	    //
	    inc(offs, size);
	  end;
      end;
    finally
{$IFNDEF NO_ANSI_SUPPORT }
      if (not g_wideApiSupported) then
	mrealloc(pointer(detailsA.pamxctrl))
      else
{$ENDIF NO_ANSI_SUPPORT  }
	mrealloc(pointer(detailsW.pamxctrl));
    end;
  end;
end;

// --  --
function unaMsMixerLine.getCaps(isConnection: bool): pMixerLineW;
var
  ok: bool;
{$IFNDEF NO_ANSI_SUPPORT }
  capsA: MIXERLINEA;
{$ENDIF NO_ANSI_SUPPORT }
begin
{$IFNDEF NO_ANSI_SUPPORT }
  if (not g_wideApiSupported) then begin
    //
    fillChar(capsA, sizeOf(capsA), #0);
    with capsA do begin
      //
      capsA.cbStruct := sizeOf(capsA);
      capsA.dwDestination := f_capsW.dwDestination;
      capsA.dwSource := f_capsW.dwSource;
    end;
    //
    ok := checkError(mixerGetLineInfoA(f_master.f_index, @capsA, choice(isConnection, unsigned(MIXER_GETLINEINFOF_SOURCE), MIXER_GETLINEINFOF_DESTINATION) + MIXER_OBJECTF_MIXER){$IFDEF DEBUG}, 'getCaps.mixerGetLineInfoA'{$ENDIF});
    if (ok) then begin
      //
      with f_capsW^ do begin
	//
	dwLineID := capsA.dwLineID;
	fdwLine := capsA.fdwLine;
	dwUser := capsA.dwUser;
	dwComponentType := capsA.dwComponentType;
	cChannels := capsA.cChannels;
	cConnections := capsA.cConnections;
	cControls := capsA.cControls;
        {$IFDEF __BEFORE_D6__ }
	str2arrayW(wString(wString(capsA.szShortName)), szShortName);
	str2arrayW(wString(wString(capsA.szName)), szName);
        {$ELSE }
	str2arrayW(wString(wString(capsA.szShortName)), szShortName);
	str2arrayW(wString(wString(capsA.szName)), szName);
        {$ENDIF __BEFORE_D6__ }
	//
	with Target do begin
	  //
	  dwType := capsA.Target.dwType;
	  dwDeviceID := capsA.Target.dwDeviceID;
	  wMid := capsA.Target.wMid;
	  wPid := capsA.Target.wPid;
	  vDriverVersion := capsA.Target.vDriverVersion;
          {$IFDEF __BEFORE_D6__ }
	  str2arrayW(wString(capsA.Target.szPname), szPname);
          {$ELSE }
	  str2arrayW(wString(capsA.Target.szPname), szPname);
          {$ENDIF __BEFORE_D6__ }
	end;
      end;
    end;
  end
  else
{$ENDIF NO_ANSI_SUPPORT }
    ok := checkError(mixerGetLineInfoW(f_master.f_index, f_capsW, choice(isConnection, unsigned(MIXER_GETLINEINFOF_SOURCE), MIXER_GETLINEINFOF_DESTINATION) + MIXER_OBJECTF_MIXER){$IFDEF DEBUG}, 'getCaps.mixerGetLineInfoW'{$ENDIF});
  //
  if (ok) then
    result := f_capsW
  else
    result := nil;
end;

// --  --
function unaMsMixerLine.getConnection(index: unsigned): unaMsMixerLine;
begin
  if (nil <> f_connections) then
    result := f_connections[index]
  else
    result := nil;
end;

// --  --
function unaMsMixerLine.getConnectionCount(): int;
begin
  if (nil <> f_connections) then
    result := f_connections.count
  else
    result := 0;
end;

// --  --
function unaMsMixerLine.getControl(index: unsigned): unaMsMixerControl;
begin
  result := f_controls[index];
end;

// --  --
function unaMsMixerLine.getControlCount(): int;
begin
  Result := f_controls.count;
end;

// --  --
function unaMsMixerLine.getID(): unsigned;
begin
  result := caps.dwLineID;
end;

// --  --
function unaMsMixerLine.getIsLineType(index: integer): bool;
begin
  if (-1 = index) then
    index := integer(MIXERLINE_LINEF_SOURCE);
  //
  result := (0 <> (caps.fdwLine and index));
end;

// --  --
function unaMsMixerLine.locateLine(componentType: unsigned): unaMsMixerLine;
var
  i: int;
begin
  result := nil;
  i := 0;
  while (i < getConnectionCount()) do begin
    //
    result := connection[i];
    if (componentType = result.caps.dwComponentType) then
      // got it
      break
    else
      result := nil;
    //
    inc(i);
  end;
end;


{ unaMsMixerDevice }

// --  --
procedure unaMsMixerDevice.close();
begin
  active := false;
end;

// --  --
constructor unaMsMixerDevice.create(master: unaMsMixerSystem; index: unsigned);
begin
  inherited create();
  //
  f_master := master;
  f_lines := unaObjectList.create();
  f_index := index;
  f_caps := malloc(sizeOf(f_caps^), true, 0);
  getCaps();
  //
  enumLines();
end;

// --  --
destructor unaMsMixerDevice.destroy();
begin
  inherited;
  //
  close();
  freeAndNil(f_lines);
end;

// --  --
procedure unaMsMixerDevice.doClose();
begin
  if (active) then begin
    //
    if (checkError(mixerClose(f_handle){$IFDEF DEBUG }, 'doClose.mixerClose'{$ENDIF DEBUG })) then
      f_handle := 0;
  end;
end;

// --  --
procedure unaMsMixerDevice.doOpen();
var
  flags: unsigned;
begin
  if (not active) then begin
    //
    if (f_winHandle = 0) then
      flags := 0
    else
      flags := CALLBACK_WINDOW;
    //
    checkError(mixerOpen(@f_handle, f_index, f_winHandle, unsigned(self), flags + MIXER_OBJECTF_MIXER){$IFDEF DEBUG }, 'doOpen.mixerOpen'{$ENDIF DEBUG });
  end;
end;

// --  --
procedure unaMsMixerDevice.enumLines();
var
  i: unsigned;
begin
  f_lines.clear();
  //
  if (0 < caps.cDestinations) then begin
    //
    for i := 0 to caps.cDestinations - 1 do
      f_lines.add(unaMsMixerLine.create(self, i));
  end;
end;

// --  --
function unaMsMixerDevice.getActive(): bool;
begin
  result := (f_handle <> 0);
end;

// --  --
function unaMsMixerDevice.getCaps(): pMixerCapsW;
var
  ok: bool;
{$IFNDEF NO_ANSI_SUPPORT }
  capsA: MIXERCAPSA;
{$ENDIF NO_ANSI_SUPPORT }
begin
{$IFNDEF NO_ANSI_SUPPORT }
  if (not g_wideApiSupported) then begin
    //
    ok := checkError(mixerGetDevCapsA(f_index, @capsA, sizeOf(capsA)){$IFDEF DEBUG}, 'getCaps.mixerGetDevCapsA'{$ENDIF});
    //
    if (ok) then begin
      //
      with f_caps^ do begin
	//
	wMid := capsA.wMid;
	wPid := capsA.wPid;
	vDriverVersion := capsA.vDriverVersion;
        {$IFDEF __BEFORE_D6__ }
	str2arrayW(wString(capsA.szPname), szPname);
        {$ELSE }
	str2arrayW(wString(capsA.szPname), szPname);
        {$ENDIF __BEFORE_D6__ }
	fdwSupport := capsA.fdwSupport;
	cDestinations := capsA.cDestinations;
      end;
    end;
  end
  else
{$ENDIF NO_ANSI_SUPPORT }
    ok := checkError(mixerGetDevCapsW(f_index, f_caps, sizeOf(f_caps^)){$IFDEF DEBUG }, 'getCaps.mixerGetDevCapsW'{$ENDIF DEBUG });
  //
  if (ok) then
    result := f_caps
  else
    result := nil;
end;

// --  --
function unaMsMixerDevice.getID(): UINT;
begin
  checkError(mixerGetID(f_index, result, MIXER_OBJECTF_MIXER){$IFDEF DEBUG }, 'getID.mixerGetID'{$ENDIF DEBUG });
end;

// --  --
function unaMsMixerDevice.getLine(index: unsigned): unaMsMixerLine;
begin
  result := f_lines[index]
end;

// --  --
function unaMsMixerDevice.getLineCount(): int;
begin
  result := f_lines.count;
end;

// --  --
function unaMsMixerDevice.locateComponentLine(componentType: unsigned): unaMsMixerLine;
var
  i: int;
begin
  result := nil;
  //
  i := 0;
  while (i < getLineCount()) do begin
    //
    if (componentType = line[i].caps.dwComponentType) then begin
      // got it
      result := line[i];
      break;
    end;
    //
    inc(i);
  end;
end;

// --  --
function unaMsMixerDevice.locateDestLine(destination: unsigned): unaMsMixerLine;
var
  i: int;
begin
  result := nil;
  //
  i := 0;
  while (i < getLineCount()) do begin
    //
    if (destination = line[i].caps.dwDestination) then begin
      // got it
      result := line[i];
      break;
    end;
    //
    inc(i);
  end;
end;

// --  --
function unaMsMixerDevice.locateTargetLine(targetType: unsigned): unaMsMixerLine;
var
  i: int;
begin
  result := nil;
  i := 0;
  while (i < getLineCount()) do begin
    //
    if (targetType = line[i].caps.Target.dwType) then begin
      // got it
      result := line[i];
      break;
    end;
    //
    inc(i);
  end;
end;

// --  --
procedure unaMsMixerDevice.open();
begin
  active := true;
end;

// --  --
procedure unaMsMixerDevice.setActive(value: bool);
begin
  if (active <> value) then begin
    //
    if value then
      doOpen()
    else
      doClose();
  end;
end;


{ unaMsMixerSystem }

// --  --
procedure unaMsMixerSystem.AfterConstruction();
begin
  inherited;
  //
  if (f_enumOnCreate) then
    enumDevices();
end;

// --  --
constructor unaMsMixerSystem.create(enumOnCreate: bool);
begin
  inherited create();
  //
  f_mixers := unaObjectList.create();
  //
  f_enumOnCreate := enumOnCreate;
end;

// --  --
destructor unaMsMixerSystem.destroy();
begin
  inherited;
  //
  selectMixer(-1);	// ensure we close the selected mixer (if any)
  //
  freeAndNil(f_mixers);
end;

// --  --
procedure unaMsMixerSystem.enumDevices();
begin
  if (not f_enumComplete) then begin
    //
    f_enumComplete := true;
    enumMixers();
  end;
end;

// --  --
procedure unaMsMixerSystem.enumMixers();
var
  i: unsigned;
  C: unsigned;
begin
  f_mixers.clear();
  //
  C := MMSystem.mixerGetNumDevs();
  i := 0;
  while (i < C) do begin
    //
    f_mixers.add(unaMsMixerDevice.create(self, i));
    inc(i);
  end;
end;

// --  --
function unaMsMixerSystem.getConnection(iline: unsigned; iconn: int): unaMsMixerLine;
begin
  result := nil;
  //
  if ((nil <> f_selectedMixer) and (nil <> f_selectedMixer.line[iline])) then begin
    //
    if (0 <= iconn) then
      result := f_selectedMixer.line[iline].connection[iconn]
    else
      result := f_selectedMixer.line[iline];
  end;
end;

// --  --
function unaMsMixerSystem.getConnectionControl(iline: unsigned; iconn: int; cclass, ctype: unsigned): unaMsMixerControl;
var
  i: int;
  conn: unaMsMixerLine;
  control: unaMsMixerControl;
begin
  result := nil;
  //
  conn := getConnection(iline, iconn);
  if (nil <> conn) then begin
    //
    i := 0;
    while (i < conn.getControlCount()) do begin
      //
      control := conn.getControl(i);
      if ((control.f_controlClass = cclass) and (control.f_controlType = ctype)) then begin
        //
	result := control;
	break;
      end;
      //
      inc(i);
    end;
  end;
end;

// --  --
function unaMsMixerSystem.getDeviceId(isInDevice: bool; alsoCheckMapper: bool): int;
var
  count: unsigned;
  i: unsigned;
begin
  if (nil <> selectedMixer) then begin
    //
    if (isInDevice) then
      count := waveInGetNumDevs()
    else
      count := waveOutGetNumDevs();
    //
    result := -3;	// no device for this mixer
    if (0 < count) then begin
      //
      for i := 0 to count - 1 do begin
        //
	if (getMixerId(i, isInDevice) = int(selectedMixer.getID())) then begin
          //
	  result := i;
	  break;
	end;
      end;
    end;
    //
    if (alsoCheckMapper and (0 <= result)) then begin
      //
      if (getMixerId(WAVE_MAPPER, isInDevice) = int(selectedMixer.getID())) then
	result := int(WAVE_MAPPER);
    end;
    //
  end
  else
    result := -2;	// no mixer was selected
end;

// --  --
function unaMsMixerSystem.getLineConnectionByType(iline, itype: unsigned; checkControlsNum: bool): int;
var
  i: int;
  line: unaMsMixerLine;
  //
  maxControls: int;
  preResult: int;
begin
  result := -1;
  preResult := -1;
  //
  if ((nil <> f_selectedMixer) and (nil <> f_selectedMixer.line[iline])) then begin
    //
    line := f_selectedMixer.line[iline];
    //
    maxControls := -1;
    i := 0;
    while (i < line.getConnectionCount()) do begin
      //
      if (itype = line.connection[i].caps.dwComponentType) then begin
	//
	if (checkControlsNum) then begin
	  //
	  if (maxControls < int(line.connection[i].caps.cControls)) then begin
	    //
	    preResult := i;
	    maxControls := line.connection[i].caps.cControls;
	  end;
	end
	else begin
	  //
	  result := i;
	  break;
	end;
      end;
      //
      inc(i);
    end;
  end;
  //
  if (checkControlsNum) then
    result := preResult;
end;

// --  --
function unaMsMixerSystem.getLineConnectionCount(iline: unsigned): int;
begin
  if ((nil <> f_selectedMixer) and (nil <> f_selectedMixer.line[iline])) then
    result := f_selectedMixer.line[iline].getConnectionCount()
  else
    result := 0;
end;

// --  --
function unaMsMixerSystem.getLineConnectionName(iline, iconn: unsigned; shortName: bool): wString;
var
  conn: unaMsMixerLine;
begin
  result := '';
  //
  conn := getConnection(iline, iconn);
  if (nil <> conn) then begin
    //
    if (shortName) then
      result := conn.caps.szShortName
    else
      result := conn.caps.szName;
  end;
end;

// --  --
function unaMsMixerSystem.getLineConnectionType(iline: unsigned; iconn: int): unsigned;
var
  conn: unaMsMixerLine;
begin
  conn := getConnection(iline, iconn);
  //
  if (nil <> conn) then
    result := conn.caps.dwComponentType
  else
    result := 0;
end;

// --  --
function unaMsMixerSystem.getLineCount(): int;
begin
  if (nil <> f_selectedMixer) then
    result := f_selectedMixer.getLineCount()
  else
    result := 0;
end;

// --  --
function unaMsMixerSystem.getLineIndex(isOut: bool; recLevel: int): int;
var
  line: unaMsMixerLine;
begin
  result := -1;
  //
  if (nil <> f_selectedMixer) then begin
    //
    line := f_selectedMixer.locateComponentLine(choice(isOut, MIXERLINE_COMPONENTTYPE_DST_SPEAKERS, unsigned(MIXERLINE_COMPONENTTYPE_DST_WAVEIN)));
    //
    if (nil = line) then
      // try other DST
      line := f_selectedMixer.locateComponentLine(choice(isOut, MIXERLINE_COMPONENTTYPE_DST_HEADPHONES, unsigned(MIXERLINE_COMPONENTTYPE_DST_LINE)));
    //
    if (nil = line) then
      // try selecting by target
      line := f_selectedMixer.locateTargetLine(choice(isOut, MIXERLINE_TARGETTYPE_WAVEOUT, unsigned(MIXERLINE_TARGETTYPE_WAVEIN)));
    //
    if ((nil = line) and (1 > recLevel)) then begin
      // try to locate other type and then return opposite index
      result := getLineIndex(not isOut, 1);
      //
      if (0 < result) then
	result := 0
      else
	if (0 = result) then begin
	  //
	  result := min(1, getLineCount() - 1);
	  if (0 = result) then
	    result := -1;	// no such line
	end
	else
	  if (isOut) then begin
	    //
	    if (0 < getLineCount()) then
	      result := 0	// finally assume 0 is OUT
	    else
	      result := -1
	  end
	  else begin
	    //
	    if (0 < getLineCount()) then
	      result := 1	// finally assume 1 is IN
	    else
	      result := -1
	  end;
    end
    else
      result := f_selectedMixer.f_lines.indexof(line);
  end;
end;

// --  --
function unaMsMixerSystem.getLineName(iline: unsigned; shortName: bool): wString;
begin
  if ((nil <> f_selectedMixer) and (nil <> f_selectedMixer.line[iline])) then begin
    //
    if (shortName) then
      result := f_selectedMixer.line[iline].caps.szShortName
    else
      result := f_selectedMixer.line[iline].caps.szName
  end
  else
    result := '';
end;

// --  --
function unaMsMixerSystem.getMixer(index: unsigned): unaMsMixerDevice;
begin
  result := f_mixers[index];
end;

// --  --
function unaMsMixerSystem.getMixerCount(): int;
begin
  result := f_mixers.count;
end;

const
  // message base for driver specific messages.
  //
  DRVM_MAPPER		= $2000;
  DRVM_USER             = $4000;
  DRVM_MAPPER_STATUS           	= (DRVM_MAPPER+0);
  DRVM_MAPPER_RECONFIGURE	= (DRVM_MAPPER+1);
  DRVM_MAPPER_PREFERRED_GET	= (DRVM_MAPPER+21);
  DRV_QUERYMODULE               = (DRV_RESERVED + 9);
  DRV_PNPINSTALL                = (DRV_RESERVED + 11);

  // MS loves to hide things
  DRV_QUERYDRVENTRY     = (DRV_RESERVED + 1);
  DRV_QUERYDEVNODE      = (DRV_RESERVED + 2);
  DRV_QUERYNAME         = (DRV_RESERVED + 3);
  DRV_QUERYDRIVERIDS	= (DRV_RESERVED + 4);
  DRV_QUERYMAPPABLE     = (DRV_RESERVED + 5);

//
// DRVM_MAPPER_PREFERRED_GET flags
//
  DRVM_MAPPER_PREFERRED_FLAGS_PREFERREDONLY   = $000000001;


// --  --
function unaMsMixerSystem.getMixerId(deviceId: unsigned; isInDevice: bool): int;
var
  mixId: UINT;
  flags: unsigned;
begin
  if (WAVE_MAPPER = deviceId) then begin
    //
    flags := 0;  //
    case (g_osVersion.dwPlatformId) of

      VER_PLATFORM_WIN32s,
      VER_PLATFORM_WIN32_WINDOWS: begin
	// Win95/Me stuff
	deviceId := mapMixerIdWin9x(deviceId, isInDevice);
      end;

      VER_PLATFORM_WIN32_NT: begin
	// NT stuff
	if (isInDevice) then
	  waveInMessage(int(WAVE_MAPPER), DRVM_MAPPER_PREFERRED_GET, UIntPtr(@deviceId), UIntPtr(@flags))
	else
	  waveOutMessage(int(WAVE_MAPPER), DRVM_MAPPER_PREFERRED_GET, UIntPtr(@deviceId), UIntPtr(@flags));
      end;

    end;
  end;
  //
  if (MMSYSERR_NOERROR = mixerGetID(int(deviceId), mixId, choice(isInDevice, MIXER_OBJECTF_WAVEIN, unsigned(MIXER_OBJECTF_WAVEOUT)))) then
    result := mixId
  else
    result := -1;
end;

// --  --
function unaMsMixerSystem.getMixerIndex(mixerId: unsigned): int;
var
  i: int;
  curId: UINT;
begin
  result := -1;
  // locate mixer with this ID
  i := 0;
  while (i < getMixerCount()) do begin
    //
    if (MMSYSERR_NOERROR = mixerGetID(i, curId, MIXER_OBJECTF_MIXER)) then
      //
      if (curId = mixerId) then begin
	//
	result := i;
	break;
      end;
    //
    inc(i);
  end;
end;

// --  --
function unaMsMixerSystem.getMixerName(): wString;
begin
  if (nil <> f_selectedMixer) then
    result := f_selectedMixer.caps.szPname
  else
    result := '';
end;

// --  --
function unaMsMixerSystem.getMuteControlID(iline: unsigned; iconn: int): int;
var
  control: unaMsMixerControl;
begin
  control := getConnectionControl(iline, iconn, MIXERCONTROL_CT_CLASS_SWITCH, MIXERCONTROL_CONTROLTYPE_MUTE);
  //
  if (nil <> control) then
    result := control.caps.dwControlID
  else
    result := -1;
end;

// --  --
function unaMsMixerSystem.getRecSource(): int;
var
  i: int;
  j: unsigned;
  k: int;
  recIndex: int;
  line: unaMsMixerLine;
  conn: unaMsMixerLine;
  control: unaMsMixerControl;
begin
  result := -1;
  //
  if (nil <> f_selectedMixer) then begin
    //
    recIndex := getLineIndex(false);
    if (0 <= recIndex) then
      line := f_selectedMixer.line[recIndex]
    else
      line := nil;
    //
    if (nil <> line) then begin
      //
      //
      // locate list control(s) for this line
      //
      i := 0;
      while (i < line.getControlCount()) do begin
	//
	control := line[i];
	if (control.isListClass) then begin
	  // locate this line in items list
	  j := 0;
	  while (j < control.caps.cMultipleItems) do begin
	    //
	    if (control.getValue(false, 0, j)) then begin
	      //
	      // now locate this line in connections
	      //
	      k := 0;
	      while (k < line.getConnectionCount()) do begin
		//
		conn := line.connection[k];
		if ((nil <> control.getListItem(0, j)) and (conn.caps.dwLineId = control.getListItem(0, j).dwParam1)) then begin
		  // found
		  result := k;
		  break;
		end;
		//
		inc(k);
	      end;
	      //
	      if (0 <= result) then
		break;
	    end;
	    //
	    inc(j);
	  end;
	end;
	//
	if (0 <= result) then
	  break;
	//
	inc(i);
      end;
    end;
  end;
end;

// --  --
function unaMsMixerSystem.getVolume(iline: unsigned; iconn: int): int;
var
  control: unaMsMixerControl;
  imax: int;
begin
  control := getConnectionControl(iline, iconn, MIXERCONTROL_CT_CLASS_FADER, MIXERCONTROL_CONTROLTYPE_VOLUME);
  //
  if (nil <> control) then begin
    //
    imax := max(control.caps.bounds.lMinimum, control.caps.bounds.lMaximum) - control.caps.bounds.lMinimum;
    //
    result := (control.getValue(unsigned(0), 0) + control.getValue(unsigned(0), 1)) shr 1;
    result := percent(result, imax);
  end
  else
    result := -1;
end;

// --  --
function unaMsMixerSystem.getVolumeControlID(iline: unsigned; iconn: int): int;
var
  control: unaMsMixerControl;
begin
  control := getConnectionControl(iline, iconn, MIXERCONTROL_CT_CLASS_FADER, MIXERCONTROL_CONTROLTYPE_VOLUME);
  //
  if (nil <> control) then
    result := control.caps.dwControlID
  else
    result := -1;
end;

// --  --
function unaMsMixerSystem.isMutedConnection(iline: unsigned; iconn: int): bool;
var
  control: unaMsMixerControl;
begin
  control := getConnectionControl(iline, iconn, MIXERCONTROL_CT_CLASS_SWITCH, MIXERCONTROL_CONTROLTYPE_MUTE);
  //
  if (nil <> control) then
    result := control.getValue(true)
  else
    result := true;
end;

// --  --
function unaMsMixerSystem.mapMixerIdWin9x(deviceId: unsigned; isInDevice: bool): unsigned;
var
  key: HKEY;
  buf: array[0..511] of AnsiChar;
  lpType: DWORD;
  lpSize: DWORD;
  devCapsIn: WAVEINCAPSA;
  devCapsOut: WAVEOUTCAPSA;
  count: unsigned;
  i: unsigned;
  name: aString;
  ok: bool;
begin
  result := deviceId;
  if (WAVE_MAPPER <> result) then
    exit;
  //
  // 1. first try to read mapped device name from registry
  if (ERROR_SUCCESS = regOpenKeyEx(HKEY_CURRENT_USER, 'Software\Microsoft\Multimedia\Sound Mapper', 0, KEY_READ, key)) then try
    //
    lpType := REG_SZ;
    lpSize := sizeof(buf);
    RegQueryValueExA(key, paChar(aString(choice(isInDevice, 'Record', 'Playback'))), nil, @lpType, pByte(@buf), @lpSize);
  finally
    regCloseKey(key);
  end;
  //
  // 2. now, for all devices, try to compare the name (say thanks to MS)
  if (isInDevice) then
    count := waveInGetNumDevs()
  else
    count := waveOutGetNumDevs();
  //
  i := 0;
  while (i < count) do begin
    //
    name := '';
    if (isInDevice) then begin
      //
      if (MMSYSERR_NOERROR = waveInGetDevCapsA(i, @devCapsIn, sizeof(devCapsIn))) then
	name := devCapsIn.szPname;
    end
    else begin
      //
      if (MMSYSERR_NOERROR = waveOutGetDevCapsA(i, @devCapsOut, sizeof(devCapsOut))) then
	name := devCapsOut.szPname;
    end;
    //
    if (sameString(name, buf)) then begin
      //
      result := i;
      break;
    end;
    //
    inc(i);
  end;
  //
  // 3. if still no success, try DRV_QUERYMAPPABLE
  if (WAVE_MAPPER = result) then begin
    //
    i := 0;
    while (i < count) do begin
      //
      if (isInDevice) then
	ok := (MMSYSERR_NOERROR = waveInMessage(i, DRV_QUERYMAPPABLE, 0, 0))
      else
	ok := (MMSYSERR_NOERROR = waveOutMessage(i, DRV_QUERYMAPPABLE, 0, 0));
      //
      if (ok) then begin
        //
	result := i;
	break;
      end;
      //
      inc(i);
    end;
  end;
end;

// --  --
function unaMsMixerSystem.muteConnection(iline: unsigned; iconn: int; doMute: bool): bool;
var
  control: unaMsMixerControl;
begin
  control := getConnectionControl(iline, iconn, MIXERCONTROL_CT_CLASS_SWITCH, MIXERCONTROL_CONTROLTYPE_MUTE);
  //
  if (nil <> control) then begin
    //
    control.setValue(doMute);
    result := true;
  end
  else
    result := false;
end;

// --  --
function unaMsMixerSystem.selectMixer(imixer: int; handle: unsigned): bool;
begin
  if (nil <> f_selectedMixer) then
    f_selectedMixer.close();
  //
  f_selectedMixer := nil;
  //
  if ((0 <= imixer) and (imixer < getMixerCount())) then
    f_selectedMixer := mixer[imixer];
  //
  result := (nil <> f_selectedMixer);
  if (result) then begin
    //
    f_selectedMixer.winHandle := handle;
    f_selectedMixer.open();
  end;
end;

// --  --
function unaMsMixerSystem.selectMixer(deviceId: unsigned; isInDevice: bool; handle: unsigned): bool;
var
  mixId: int;
  i: int;
begin
  mixId := getMixerId(deviceId, isInDevice);
  //
  if (0 <= mixId) then
    // locate mixer with this ID
    i := getMixerIndex(mixId)
  else
    i := -1;	// no mixer for this device
  //
  if (0 <= i) then
    result := selectMixer(i, handle)
  else
    result := selectMixer(-1, handle)	// select nil
end;

// --  --
function unaMsMixerSystem.setRecSource(iconn: unsigned; ensureNotMuted: bool): bool;
var
  i: int;
  j: unsigned;
  recIndex: int;
  line: unaMsMixerLine;
  conn: unaMsMixerLine;
  control: unaMsMixerControl;
begin
  result := false;
  //
  if (nil <> f_selectedMixer) then begin
    //
    recIndex := getLineIndex(false);
    if (0 <= recIndex) then
      line := f_selectedMixer.line[recIndex]
    else
      line := nil;
    //
    if (nil <> line) then begin
      //
      conn := line.connection[iconn];
      if (nil <> conn) then begin
	//
	// locate list control(s) for this line
	//
	i := 0;
	while (i < line.getControlCount()) do begin
	  //
	  control := line[i];
	  if (control.isListClass) then begin
	    // locate this line in items list
	    j := 0;
	    while (j < control.caps.cMultipleItems) do begin
	      //
	      if ((nil <> control.getListItem(0, j)) and (control.getListItem(0, j).dwParam1 = conn.caps.dwLineId)) then begin
		//
		control.setValue(true, 0, j);
		result := true;
		break;
	      end;
	      //
	      inc(j);
	    end;
	    //
	    if (result) then
	      break;
	  end;
	  //
	  inc(i);
	end;
	//
	if (not result and ensureNotMuted) then
	  // at least make sure this line is not muted
	  muteConnection(recIndex, iconn, false);
      end;
    end;
  end;
end;

// --  --
function unaMsMixerSystem.setVolume(iline: unsigned; iconn, value: int): bool;
var
  control: unaMsMixerControl;
  imax: int;
  ivalue: int;
begin
  control := getConnectionControl(iline, iconn, MIXERCONTROL_CT_CLASS_FADER, MIXERCONTROL_CONTROLTYPE_VOLUME);
  if (nil <> control) then begin
    //
    imax := max(control.caps.bounds.lMinimum, control.caps.bounds.lMaximum) - control.caps.bounds.lMinimum;
    ivalue := (imax div 100) * value + control.caps.bounds.lMinimum;
    //
    control.setValueInt(ivalue, 0);
    control.setValueInt(ivalue, 1);
    //
    result := true;
  end
  else
    result := false;
end;


end.



