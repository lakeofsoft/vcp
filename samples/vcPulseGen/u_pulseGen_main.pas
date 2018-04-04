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

	  u_pulseGen_main.pas
	  Voice Communicator components version 2.5
	  VC Pulse Generator demo application - main form

	----------------------------------------------
	  Copyright (c) 2002-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 03 Aug 2002

	  modified by:
		Lake, Aug-Dec 2002
		Lake, Jan-May 2003
		Lake, Mar 2008

	----------------------------------------------
*)

{$I unaDef.inc}

unit
  u_pulseGen_main;

interface

uses
  Windows, unaTypes, Messages, Forms, Classes, Controls, StdCtrls, ActnList,
  unaClasses, unaMsAcmClasses, ExtCtrls, Dialogs, ComCtrls, unaDspControls,
  Menus;

type
  Tc_pg_main = class(TForm)
    c_actionList_main: TActionList;
    a_openDev: TAction;
    a_closeDev: TAction;
    a_about: TAction;
    a_exit: TAction;
    a_addPulse: TAction;
    c_paintBox_osc: TPaintBox;
    c_saveDialog_wave: TSaveDialog;
    c_timer_paint: TTimer;
    Label1: TLabel;
    c_comboBox_device: TComboBox;
    Button4: TButton;
    Button5: TButton;
    Button3: TButton;
    c_checkBox_saveWav: TCheckBox;
    c_edit_wav: TEdit;
    c_button_browse: TButton;
    Bevel1: TBevel;
    c_statusBar_main: TStatusBar;
    c_fft_main: TunadspFFTControl;
    c_mm_main: TMainMenu;
    File1: TMenuItem;
    Exit1: TMenuItem;
    Help1: TMenuItem;
    About1: TMenuItem;
    //
    procedure formCreate(sender: tObject);
    procedure formDestroy(sender: tObject);
    procedure formCloseQuery(sender: tObject; var canClose: boolean);
    procedure formShow(sender: tObject);
    //
    procedure a_openDevExecute(Sender: TObject);
    procedure a_closeDevExecute(Sender: TObject);
    procedure a_addPulseExecute(Sender: TObject);
    procedure c_paintBox_oscPaint(Sender: TObject);
    procedure c_button_browseClick(Sender: TObject);
    procedure c_checkBox_saveWavClick(sender: tObject);
    procedure c_edit_wavChange(sender: tObject);
    procedure c_timer_paintTimer(Sender: TObject);
    procedure Exit1Click(Sender: TObject);
    procedure About1Click(Sender: TObject);
  private
    { Private declarations }
    f_samples1: array[word] of SmallInt;
    f_samples2: array[word] of SmallInt;
    f_samplesCount: unsigned;
    f_saveToWav: bool;
    f_config: unaIniFile;
    f_paintBusy: bool;
    f_noMoreFeed: bool;
    //
    procedure myOnDA(sender: tObject; data: pointer; len: uint);
    procedure myOnACD(sender: tObject; data: pointer; len: uint);
  public
    { Public declarations }
    waveOut: unaWaveOutDevice;
    mixer: unaWaveMixerDevice;
    wavWrite: unaRiffStream;
    //
    pulses: unaObjectList;
  end;

var
  c_pg_main: Tc_pg_main;


implementation


{$R *.dfm}

uses
  MMSystem, unaUtils, sysUtils,
  u_vcPulse_main, Graphics, ShellAPI;

// --  --
procedure Tc_pg_main.formCreate(sender: tObject);
var
  i: int;
  devCaps: WAVEOUTCAPSW;
begin
  randomize();
  pulses := unaObjectList.create(false);
  f_config := unaIniFile.create();
  //
  // fill list of devices
  with (c_comboBox_device) do begin
    //
    clear();
    //
    for i := -1 to unaWaveOutDevice.getDeviceCount() - 1 do begin
      //
      unaWaveOutDevice.getCaps(uint(i), devCaps);
      c_comboBox_device.items.addObject(devCaps.szPname, pointer(i + 10));
    end;
    //
    if (0 < items.count) then
      itemIndex := 0
    else
      a_openDev.enabled := false;
  end;
  //
  // create devices
  mixer := unaWaveMixerDevice.create(true, false, 10);
  mixer.onDataAvailable := myOnDA;
  //
  waveOut := unaWaveOutDevice.create(WAVE_MAPPER, false, false, 5);
  waveOut.onAfterChunkDone := myOnACD;
  //
  mixer.addConsumer(waveOut);
  //
  waveOut.setSampling(44100, 16, 1);
  mixer.setSampling(44100, 16, 1);
  //
  f_samplesCount := 44100 div c_defChunksPerSecond shr 1;
end;

// --  --
procedure Tc_pg_main.formDestroy(sender: tObject);
begin
  freeAndNil(waveOut);
  freeAndNil(mixer);
  freeAndNil(f_config);
end;

// --  --
procedure Tc_pg_main.formCloseQuery(sender: tObject; var canClose: boolean);
begin
  a_closeDev.execute();
  //
  f_config.setValue('wav_write.file.name', c_edit_wav.text);
  f_config.setValue('wav_write.enabled', c_checkBox_saveWav.checked);
end;

// --  --
procedure Tc_pg_main.formShow(sender: tObject);
begin
  c_edit_wav.text := f_config.get('wav_write.file.name', '');
  c_checkBox_saveWav.checked := f_config.get('wav_write.enabled', false);
  c_edit_wavChange(sender);
  //
  c_fft_main.fft.fft.setFormat(waveOut.srcFormatExt.Format.nSamplesPerSec, waveOut.srcFormatExt.Format.wBitsPerSample, waveOut.srcFormatExt.Format.nChannels);
  c_fft_main.fallback := 0;	// instant
  //
  c_paintBox_osc.controlStyle := c_paintBox_osc.controlStyle + [csOpaque]; 
end;

// --  --
procedure Tc_pg_main.a_openDevExecute(Sender: TObject);
var
  res: MMRESULT;
begin
  waveOut.deviceId := uint(int(c_comboBox_device.items.objects[c_comboBox_device.itemIndex]) - 10);
  //
  if (c_checkBox_saveWav.checked) then begin
    //
    wavWrite := unaRiffStream.createNew(c_edit_wav.text,
      fillPCMFormat(
	waveOut.srcFormatExt.Format.nSamplesPerSec,
	waveOut.srcFormatExt.Format.wBitsPerSample,
	waveOut.srcFormatExt.Format.nChannels
      )
    );
    res := wavWrite.open();
    //
    if (not mmNoError(res)) then
      raise exception.create('Error creating output WAVe file.');
  end
  else
    wavWrite := nil;
  //
  res := waveOut.open();
  if (mmNoError(res)) then begin
    //
    a_openDev.enabled := false;
    mixer.open();
    //
    c_fft_main.active := true;
  end
  else
    raise exception.create('Error while opening waveOut device: '#13#10 + waveOut.getErrorText(res));
  //
  a_closeDev.enabled := not a_openDev.enabled;
  a_addPulse.enabled := a_closeDev.enabled;
  c_button_browse.enabled := a_openDev.enabled;
  c_edit_wav.enabled := a_openDev.enabled;
  c_checkBox_saveWav.enabled := a_openDev.enabled;
  //
  f_noMoreFeed := false;
  //
  c_timer_paint.enabled := true;
end;

// --  --
procedure Tc_pg_main.a_closeDevExecute(Sender: TObject);
begin
  c_timer_paint.enabled := false;
  //
  f_noMoreFeed := true;
  //
  if (lockNonEmptyList_r(pulses, false, 500 {$IFDEF DEBUG }, '.a_closeDevExecute()'{$ENDIF DEBUG })) then
    try
      while (0 < pulses.count) do
	tObject(pulses[0]).free;
    finally
      unlockListWO(pulses);
    end;
  //
  mixer.close();
  waveOut.close();
  c_fft_main.active := false;
  //
  if (nil <> wavWrite) then
    wavWrite.close();
  //
  a_openDev.enabled := true;
  a_closeDev.enabled := not a_openDev.enabled;
  a_addPulse.enabled := a_closeDev.enabled;
  c_button_browse.enabled := a_openDev.enabled;
  c_edit_wav.enabled := a_openDev.enabled;
  c_checkBox_saveWav.enabled := a_openDev.enabled;
  //
  freeAndNil(wavWrite);
  //
  c_paintBox_osc.invalidate();
end;

// --  --
procedure Tc_pg_main.About1Click(Sender: TObject);
begin
  ShellExecute(handle, 'open', 'http://lakeofsoft.com/vc/a_tonegenerator.html', nil, nil, SW_SHOWNORMAL);
end;

// --  --
procedure Tc_pg_main.a_addPulseExecute(Sender: TObject);
begin
  with (Tc_form_pulse.Create(self)) do begin
    //
    left := Self.Left + int(pulses.count - 1) * 20;
    top  := Self.Top + Self.Height + int(pulses.count - 1) * 20;
    show();
  end;
end;

// --  --
procedure Tc_pg_main.myOnDA(sender: tObject; data: pointer; len: uint);
begin
  if (f_saveToWav and (nil <> wavWrite)) then
    wavWrite.write(data, len);
end;

// --  --
procedure Tc_pg_main.myOnACD(sender: tObject; data: pointer; len: uint);
var
  i: int;
begin
  c_fft_main.fft.write(data, len);
  //
  move(data^, f_samples1, len);
  //
  // notify pulses they have to add new chunk
  if (not f_noMoreFeed and lockNonEmptyList_r(pulses, true, 50 {$IFDEF DEBUG }, '.myOnACD()'{$ENDIF DEBUG })) then try
    //
    for i := 0 to pulses.count - 1 do
      Tc_form_pulse(pulses[i]).feedSine(self);
    //
  finally
    unlockListRO(pulses);
  end;
end;

// --  --
procedure Tc_pg_main.c_paintBox_oscPaint(sender: tObject);
var
  i: unsigned;
  stepH: double;
  stepV: double;
  offsetV: double;
  pos: double;
begin
  f_paintBusy := true;
  //
  try
    move(f_samples1, f_samples2, f_samplesCount shl 1);
    //
    with (c_paintBox_osc) do begin
      //
      canvas.brush.color := clBlack;
      canvas.fillRect(getClientRect());
      //
      if (0 < f_samplesCount) then begin
	//
	stepH := width / f_samplesCount;
	stepV := height / 65536;
	offsetV := height / 2;
	//
	pos := 0;
	//
	for i := 0 to f_samplesCount - 1 do begin
	  canvas.pixels[trunc(pos), trunc(offsetV - f_samples2[i] * stepV)] := clGreen;
	  pos := pos + stepH;
	end;
      end;
    end;
    //
  finally
    f_paintBusy := false;
  end;
end;

// --  --
procedure Tc_pg_main.c_button_browseClick(Sender: TObject);
var
  dir: string;
begin
  dir := trim(extractFilePath(c_edit_wav.text));
  if ('' <> dir) then
    c_saveDialog_wave.initialDir := dir;
  //
  if (c_saveDialog_wave.execute) then
    c_edit_wav.text := c_saveDialog_wave.fileName;
  //  
end;

// --  --
procedure Tc_pg_main.c_checkBox_saveWavClick(sender: tObject);
begin
  f_saveToWav := c_checkBox_saveWav.checked;
end;

// --  --
procedure Tc_pg_main.c_edit_wavChange(sender: tObject);
begin
  c_checkBox_saveWav.enabled := ('' <> trim(c_edit_wav.text));
end;

// --  --
procedure Tc_pg_main.c_timer_paintTimer(Sender: TObject);
begin
  c_paintBox_osc.invalidate();
  //
  {$IFDEF DEBUG }
  c_statusBar_main.panels[0].text := int2str(ams() shr 10, 10, 3) + ' KB';
  {$ENDIF }
end;

// --  --
procedure Tc_pg_main.Exit1Click(Sender: TObject);
begin
  close();
end;


end.

