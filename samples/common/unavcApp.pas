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

	  unavcApp.pas
	  Voice Communicator components version 2.5
	  VC application class

	----------------------------------------------
	  Copyright (c) 2002-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 29 Mar 2002

	  modified by:
		Lake, Mar-Dec 2002
		Lake, May-Dec 2003
		Lake, Mar-Jul 2004
                Lake, Jun 2009

	----------------------------------------------
*)

{$I unaDef.inc}

{*
	VC Application class
}

unit
  unaVCApp;

interface

uses
  Windows, MMSystem,
  unaTypes, unaUtils, unaClasses,
{$IFDEF CONSOLE}
{$ELSE}
  unaWinClasses,
{$ENDIF CONSOLE }
  unaMsAcmClasses, unaApp;

type

  {*
  	unaVCApplication
  }
  unaVCApplication = class(unaApplication)
  private
    f_rate: unsigned;
    f_bits: unsigned;
    f_nChannels: unsigned;
    f_doChoose: bool;
    f_showVCInfo: bool;
    f_deviceID: unsigned;
    //
    f_hasDevice: bool;
    f_device: unaMsAcmStreamDevice;
{$IFDEF CONSOLE}
{$ELSE}
    f_formatLabel: unaWinEdit;
    f_chooseButton: unaWinButton;
{$ENDIF CONSOLE }
  protected
    function init(): bool; override;
    function start(): bool; override;
    function stop(): bool; override;
    //
    function onCommand(cmd: int): bool; override;
    function okToUpdate(): bool; override;
  public
    constructor create(hasGUI: bool = true; hasDevice: bool = true; const title: wString = ''; const copy: wString = ''; height: unsigned = 32; showVCInfo: bool = true; const url: aString = 'http://lakeofsoft.com/');
    destructor Destroy(); override;
    //
    function assignFormat(forceChoose: bool = false): bool; virtual;
    function assignVolumeParams(): bool;
    //
    property hasDevice: bool read f_hasDevice;
    property device: unaMsAcmStreamDevice read f_device write f_device;
    property deviceID: unsigned read f_deviceID write f_deviceID;
    property rate: unsigned read f_rate write f_rate;
    property bits: unsigned read f_bits write f_bits;
    property nChannels: unsigned read f_nChannels write f_nChannels;
{$IFDEF CONSOLE}
{$ELSE}
    property formatLabel: unaWinEdit read f_formatLabel;
    property chooseButton: unaWinButton read f_chooseButton;
{$ENDIF CONSOLE }
  end;


implementation


{ unaVCApplication }

// --  --
function unaVCApplication.assignFormat(forceChoose: bool): bool;
var
  frm: pWAVEFORMATEX;
begin
  if (nil = device) then begin
    //
    result := false;
    exit;
  end;
  //
  if (forceChoose or hasSwitch('choose') or f_doChoose) then begin
    //
    getMem(frm, sizeOf(frm^));
    try
      fillPCMFormat(frm^, rate, bits, nChannels);
      //
{$IFDEF CONSOLE}
{$ELSE }
      if (app.hasGUI) then begin
	//
	if (mmNoError(device.formatChooseDef(frm))) then begin
	  //
	  rate := frm.nSamplesPerSec;
	  bits := frm.wBitsPerSample;
	  nChannels := frm.nChannels;
	end;
      end;
{$ENDIF CONSOLE }
      //
    finally
      mrealloc(pointer(frm));
    end;
  end;
  //
  if (device is unaWaveDevice) then
    unaWaveDevice(device).setSampling(rate, bits, nChannels);
  //
{$IFDEF CONSOLE }
{$ELSE }
  if (app.hasGUI) then begin
    //
    if (device.getMasterIsSrc()) then
      f_formatLabel.setText(device.srcFormatInfo)
    else
      f_formatLabel.setText(device.dstFormatInfo);
    //
  end;
{$ENDIF CONSOLE }
  result := true;
end;

// --  --
function unaVCApplication.assignVolumeParams(): bool;
begin
  if ((nil <> device) and (device is unaWaveInDevice)) then begin
    //
    with (device as unaWaveInDevice) do begin
      //
      ini.section := 'device';
      minVolumeLevel := ini.get('minVolumeLevel', unsigned(0));
      minActiveTime := ini.get('minActiveTime', unsigned(1000));;
    end;
  end;
  //
  result := true;
end;

// --  --
constructor unaVCApplication.create(hasGUI, hasDevice: bool; const title, copy: wString; height: unsigned; showVCInfo: bool; const url: aString);
begin
  f_device := nil;
  f_showVCInfo := showVCInfo;
  //
  f_hasDevice := hasDevice;
  //
  inherited create(hasGUI, title, copy, true, true, height, url);
end;

// --  --
destructor unaVCApplication.destroy();
begin
  inherited;
  //
  freeAndNil(f_device);
end;

// --  --
function unaVCApplication.init(): bool;
begin
  if (hasDevice) then begin
    //
    ini.section := 'device';
    deviceID := unsigned(ini.get('deviceID', int(WAVE_MAPPER)));
    rate := ini.get('rate', unsigned(44100));
    bits := ini.get('bits', unsigned(16));
    nChannels := ini.get('nChannels', unsigned(2));
    f_doChoose := ini.get('chooseFormat', true);
  end;
  //
  if (f_showVCInfo) then begin
    //
    logMessage('Built with VC components, version 2.5', c_logModeFlags_normal);
    logMessage('http://lakeofsoft.com/vc'#13#10, c_logModeFlags_normal);
  end;
  //
{$IFDEF CONSOLE }
{$ELSE }
  if (app.hasGUI) then begin
    //
    f_formatLabel := unaWInEdit(unaWInEdit.create('', app, 208, 5, 92 + 20).setFont(unaWinFont.create('', 16, 5))).setReadOnly();
    f_chooseButton := unaWinButton.create('&Choose ..', app, 11, 324, 2, 70);
  end;
{$ENDIF CONSOLE }
  //
  result := inherited init();
end;

// --  --
function unaVCApplication.okToUpdate(): bool;
begin
  if (nil <> device) then
    result := inherited okToUpdate() and (device.waitForData(true, 1) or device.waitForData(false, 1))
  else
    result := inherited okToUpdate();
end;

// --  --
function unaVCApplication.onCommand(cmd: int): bool;
begin
  result := inherited onCommand(cmd);
  case (cmd) of
    11:
      assignFormat(true);
  end;
end;

// --  --
function unaVCApplication.start(): bool;
begin
  if (nil <> f_device) then
    result := mmNoError(f_device.open())
  else
    result := true;
  //
  if (result) then begin
    //
    if (hasDevice) then begin
      //
      ini.section := 'device';
      ini.setValue('rate', rate);
      ini.setValue('bits', bits);
      ini.setValue('nChannels', nChannels);
    end;
    //
    result := inherited start();
    //
    if (hasDevice) then begin
      //
      if (not result) then begin
	//
	if (nil <> f_device) then
	  f_device.close();
      end;
    end;
    //
{$IFDEF CONSOLE }
{$ELSE }
    if (app.hasGUI) then begin
      //
      if (result and (nil <> f_chooseButton)) then
	f_chooseButton.enable(false);
      //
    end;
{$ENDIF CONSOLE }
  end;
end;

// --  --
function unaVCApplication.stop(): bool;
begin
  if (nil <> f_device) then
    result := mmNoError(f_device.close())
  else
    result := true;
  //
  if (result) then
    result := inherited stop();
{$IFDEF CONSOLE }
{$ELSE }
  if (result and app.hasGUI) then
    if (nil <> f_chooseButton) then
      f_chooseButton.enable(true);
{$ENDIF CONSOLE }
end;


end.

