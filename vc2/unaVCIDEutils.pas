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

	  unaVcIDEutils.pas
	  Voice Communicator components version 2.5 Pro
	  VC Utility functions for VCL classes

	----------------------------------------------
	  Copyright (c) 2003-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 09 Feb 2003

	  modified by:
		Lake, Feb-May 2003
		Lake, Sep 2005
		Lake, Jun 2009
		Lake, Mar 2012

	----------------------------------------------
*)

{$I unaDef.inc }
{$I unaMSACMDef.inc }

{*
  Utility functions for VC and VCL classes.

  @Author Lake

  Version 2.5.2008.07 Still here

  Version 2.5.2012.03 +ASIO
}

unit
  unaVCIDEutils;

interface

uses
  Windows, unaTypes, unaMsAcmClasses
{$IFDEF UNA_VCACM_USE_ASIO }
  , unaASIOAPI
{$ENDIF UNA_VCACM_USE_ASIO }
{$IFDEF __BEFORE_D6__ }
  , StdCtrls
{$ELSE }
  , Controls
{$ENDIF __BEFORE_D6__ }
  ;

type
  proc_waveDeviceEnumCallback = procedure(obj: pointer; caps: pointer; isInput: bool; var name: wString; deviceId: unsigned; var okToAdd: bool); stdcall;

{*
	Enumerates waveIn or waveOut devices, and fills the supplied box.
	NOTE: sets high-order bit of list.tag if includeMapper = false
}
{$IFDEF __BEFORE_D6__ }
procedure enumWaveDevices(list: tListBox; enumWaveIn: bool = true; includeMapper: bool = true; callback: proc_waveDeviceEnumCallback = nil; engine: unavcWaveEngine = unavcwe_MME; obj: pointer = nil); overload;
procedure enumWaveDevices(list: tComboBox; enumWaveIn: bool = true; includeMapper: bool = true; callback: proc_waveDeviceEnumCallback = nil; engine: unavcWaveEngine = unavcwe_MME; obj: pointer = nil); overload;
{$ELSE }
procedure enumWaveDevices(list: tCustomListControl; enumWaveIn: bool = true; includeMapper: bool = true; callback: proc_waveDeviceEnumCallback = nil; engine: unavcWaveEngine = unavcwe_MME; obj: pointer = nil);
{$ENDIF __BEFORE_D6__ }

{*
	Returns wave deviceId which corresponds to selected itemIndex in the list.
}
{$IFDEF __BEFORE_D6__ }
function index2deviceId(list: tListBox): int; overload;
function index2deviceId(list: tComboBox): int; overload;
{$ELSE }
function index2deviceId(list: tCustomListControl): int; overload;
{$ENDIF __BEFORE_D6__ }
//
function index2deviceId(index: int; includesMapper: bool): int; overload;


{*
  Returns itemIndex which corresponds to specified deviceId
}
function deviceId2index(deviceId: int; includeMapper: bool = true): int;

{$IFDEF UNA_VCACM_USE_ASIO }

{*
	Displays ASIO control panel.
}
procedure ASIOControlPanel(driverIndex: int);

{$ENDIF UNA_VCACM_USE_ASIO }


implementation


uses
  unaUtils, MMSystem, Classes;

{$IFDEF __BEFORE_D6__ }

// --   --
function doEnum(tag: int; list: tStrings; enumWaveIn: bool; includeMapper: bool; callback: proc_waveDeviceEnumCallback; engine: unavcWaveEngine; obj: pointer): int;

  // --  --
  procedure newItem(itemId: unsigned; const defValue: AnsiString);
  var
    wname: wString;
    caps: pointer;
    ok: bool;
    capsIn: WAVEINCAPSW;
    capsOut: WAVEOUTCAPSW;
  begin
    case (engine) of

      unavcwe_MME: begin
	//
	if (enumWaveIn) then begin
	  //
	  ok := unaWaveInDevice.getCaps(itemId, capsIn);
	  caps := @capsIn;
	end
	else begin
	  ok := unaWaveOutDevice.getCaps(itemId, capsOut);
	  caps := @capsOut;
	end;
	//
	if (ok) then begin
	  //
	  if (enumWaveIn) then
	    wname := capsIn.szPname
	  else
	    wname := capsOut.szPname
	end
	else
	  wname := defValue;
      end;

      else begin
	//
	wname := defValue;
	caps := nil;
      end

    end;
    //
    ok := true;
    if (assigned(callback)) then
      callback(obj, caps, enumWaveIn, wname, itemId, ok);
    //
    if (ok and (nil <> list)) then
      list.add(wname);
  end;

var
  i: unsigned;
  j: int32;
  max: int;
begin
  if (nil <> list) then
    list.clear();
  //
  result := tag;
  //
  case (engine) of

    unavcwe_ASIO: begin
      //
      includeMapper := false;
      //
  {$IFDEF UNA_VCACM_USE_ASIO }
      with (unaAsioDriverList.create()) do try
	//
	for j := 0 to asioGetNumDev() - 1 do
	  newItem(j, asioGetDriverName(asioGetDrvID(j)));
	//
      finally
	free();
      end;
  {$ELSE }
  {$ENDIF UNA_VCACM_USE_ASIO }
    end;

    unavcwe_MME: begin
      //
      if (includeMapper) then
	newItem(WAVE_MAPPER, 'Wave Mapper');
      //
      if (enumWaveIn) then
	max := unaWaveInDevice.getDeviceCount()
      else
	max := unaWaveOutDevice.getDeviceCount();
      //
      if (0 < max) then begin
	//
	for i := 0 to max - 1 do
	  newItem(i, 'Wave' + choice(enumWaveIn, 'In', 'Out') + ' Device #' + int2str(i));
      end;
    end;

  end;
  //
  if (not includeMapper) then
    result := int(unsigned(result) or $80000000);
end;

// --  --
procedure enumWaveDevices(list: tListBox; enumWaveIn: bool; includeMapper: bool; callback: proc_waveDeviceEnumCallback; engine: unavcWaveEngine; obj: pointer); overload;
var
  t: int;
  l: tStrings;
begin
  if (nil <> list) then begin
    //
    t := list.tag;
    l := list.items;
  end
  else begin
    //
    t := 0;
    l := nil;
  end;
  //
  t := doEnum(t, l, enumWaveIn, includeMapper, callback, engine, obj);
  //
  if (nil <> list) then
    list.tag := t;
end;

// --   --
procedure enumWaveDevices(list: tComboBox; enumWaveIn: bool; includeMapper: bool; callback: proc_waveDeviceEnumCallback; engine: unavcWaveEngine; obj: pointer); overload;
var
  t: int;
  l: tStrings;
begin
  if (nil <> list) then begin
    //
    t := list.tag;
    l := list.items;
  end
  else begin
    //
    t := 0;
    l := nil;
  end;
  //
  t := doEnum(t, l, enumWaveIn, includeMapper, callback, engine, obj);
  //
  if (nil <> list) then
    list.tag := t;
end;

{$ELSE }

// --   --
procedure enumWaveDevices(list: tCustomListControl; enumWaveIn: bool; includeMapper: bool; callback: proc_waveDeviceEnumCallback; engine: unavcWaveEngine; obj: pointer);

  // --  --
  procedure newItem(itemId: unsigned; const defValue: wString);
  var
    ok: bool;
    wname: wString;
    caps: pointer;
    capsIn: WAVEINCAPSW;
    capsOut: WAVEOUTCAPSW;
  begin
    case (engine) of

      unavcwe_MME: begin
	//
	if (enumWaveIn) then begin
	  //
	  ok := unaWaveInDevice.getCaps(itemId, capsIn);
	  caps := @capsIn;
	end
	else begin
	  //
	  ok := unaWaveOutDevice.getCaps(itemId, capsOut);
	  caps := @capsOut;
	end;
	//
	if (ok) then begin
	  //
	  if (enumWaveIn) then
	    wname := capsIn.szPname
	  else
	    wname := capsOut.szPname;
	end
	else
	  wname := defValue;
      end;

      else begin
	//
	wname := defValue;
	caps := nil;
      end;

    end;
    //
    ok := true;
    if (assigned(callback)) then
      callback(obj, caps, enumWaveIn, wname, itemId, ok);
    //
    if (ok and (nil <> list)) then
      list.addItem(wname, nil);
  end;

var
  i: unsigned;
{$IFDEF UNA_VCACM_USE_ASIO }
  j: int32;
{$ENDIF UNA_VCACM_USE_ASIO }
  max: int;
begin
  if (nil <> list) then
    list.clear();
  //
  case (engine) of

    unavcwe_ASIO: begin
      //
      includeMapper := false;
      //
  {$IFDEF UNA_VCACM_USE_ASIO }
      with (unaAsioDriverList.create()) do try
	//
	for j := 0 to asioGetNumDev() - 1 do
	  newItem(j, wString(asioGetDriverName(asioGetDrvID(j))));
	//
      finally
	free();
      end;
  {$ELSE }
  {$ENDIF UNA_VCACM_USE_ASIO }
    end;

    unavcwe_MME: begin
      //
      if (includeMapper) then
	newItem(WAVE_MAPPER, 'Wave Mapper');
      //
      if (enumWaveIn) then
	max := unaWaveInDevice.getDeviceCount()
      else
	max := unaWaveOutDevice.getDeviceCount();
      //
      if (0 < max) then begin
	//
	for i := 0 to max - 1 do
	  newItem(i, 'Wave' + choice(enumWaveIn, 'In', 'Out') + ' Device #' + int2str(i));
      end;
    end;

  end;
  //
  if (not includeMapper and (nil <> list)) then
    list.tag := int(unsigned(list.tag) or $80000000);
end;

{$ENDIF __BEFORE_D6__ }

// --  --
function doGetindex(tag, itemIndex: int): int;
begin
  if (0 <> (tag and $80000000)) then
    // mapper was not included in the list
    result := itemIndex
  else
    if (0 = itemIndex) then
      result := int(WAVE_MAPPER)
    else
      result := itemIndex - 1;
end;


{$IFDEF __BEFORE_D6__ }

// --  --
function index2deviceId(list: tListBox): int;
begin
  result := doGetindex(list.tag, list.itemIndex);
end;

// --  --
function index2deviceId(list: tComboBox): int;
begin
  result := doGetindex(list.tag, list.itemIndex);
end;

{$ELSE }

// --  --
function index2deviceId(list: tCustomListControl): int;
begin
  result := doGetindex(list.tag, list.itemIndex);
end;

{$ENDIF __BEFORE_D6__ }

// --  --
function index2deviceId(index: int; includesMapper: bool): int;
begin
  if (not includesMapper) then
    // mapper was not included in the list
    result := index
  else
    if (0 = index) then
      result := int(WAVE_MAPPER)
    else
      result := index - 1;
end;


// --  --
function deviceId2index(deviceId: int; includeMapper: bool): int;
begin
  if (-1 = deviceId) then begin
    //
    if (includeMapper) then
      result := 0	// mapper is the first
    else
      result := -1;	// no mapper in the list
  end
  else
    if (includeMapper) then
      result := deviceId + 1	// adjust itemIndex
    else
      result := deviceId	// as is
end;


{$IFDEF UNA_VCACM_USE_ASIO }

// --  --
procedure ASIOControlPanel(driverIndex: int);
var
  drv: unaAsioDriver;
begin
  with (unaAsioDriverList.create()) do try
    //
    if (ASE_OK = asioOpenDriver(asioGetDrvID(driverIndex), drv)) then begin
      //
      if (ASE_OK =  drv.init(0, false)) then
	drv.controlPanel()
      else
	;//guiMessageBox('Driver init fail', 'Error', MB_OK, handle);
      //
      asioCloseDriver(asioGetDrvID(driverIndex));
    end
    else
      ;//guiMessageBox('No driver', 'Error', MB_OK, handle);
    //
  finally
    free();
  end;
end;

{$ENDIF UNA_VCACM_USE_ASIO }

end.

