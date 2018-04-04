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

	  unaAudioFeedback.pas
	  Voice Communicator components version 2.5
	  Audio Feedabck routines

	----------------------------------------------
	  Copyright (c) 2005-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 11 Aug 2005

	  modified by:
		Lake, Aug 2005
		Lake, Nov 2005

	----------------------------------------------
*)

{$I unaDef.inc}
{$I unaMSACMDef.inc }

{*
  Simple audio feedback class.

  @Author Lake
  
  2.5.2008.07 Still here
}

unit
  unaAudioFeedback;

interface

uses
  Windows, unaTypes, unaClasses, MMSystem, unaMsAcmAPI, unaMsAcmClasses;


const
  // feedback class status
  c_stat_afStopped	 = 0;	// feedback was stopped or not started
  c_stat_afActive	 = 1;	// feedback is running OK
  c_stat_afErrorIn	 = 2;	// some error occured with waveIn device, see errorCode for delails
  c_stat_afErrorOut	 = 3;	// some error occured with waveOut device, see errorCode for delails

  //
  c_recordWaveCmd_start	= 1;	// starts recording into a file
  c_recordWaveCmd_stop	= 2;	// stops recording


type
  unaAudioFeedbackClass = class;

  // --  --
  myWaveOutDevice = class(unaWaveOutDevice)
  private
    f_master: unaAudioFeedbackClass;
  protected
    function onHeaderDone(header: unaWaveHeader; wakeUpByHeaderDone: bool): bool; override;
  end;

{$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }

  // --  --
  myWaveHeader = unaWaveHeader;

{$ELSE }

  // --  --
  myWaveHeader = class(unaWaveHeader)
    // this class is only needed to get access to protected methods of unaWaveHeader class
  end;

{$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }

  //
  // --  audio feedback class --
  //
  unaAudioFeedbackClass = class(unaThread)
  private
    f_errorCode: int;
    f_status: int;
    f_delay: unsigned;
    f_delayAsCount: int;
    //
    f_waveFile: unaRiffStream;
    //
    f_waveIn: unaWaveInDevice;
    f_waveOut: myWaveOutDevice;
    //
    f_waveOutHeaders: array[byte] of myWaveHeader;
    f_silence: pointer;
    //
    f_waveChunksThrownAway: int64;
    f_waveOutLastHeaderIndex: int;
    //
    f_onDA: unaWaveDataEvent;
    f_onCD: unaWaveDataEvent;
    //
    procedure setDelay(delay: unsigned);
    function getWaveFormat(): PWAVEFORMATEXTENSIBLE;
    function getWaveOut(): unaWaveOutDevice;
    //
    procedure onWaveDataAvailable(sender: tObject; data: pointer; len: cardinal);
  protected
    procedure startIn(); override;
    procedure startOut(); override;
    function execute(threadId: unsigned): int; override;
  public
    procedure AfterConstruction(); override;
    procedure BeforeDestruction(); override;
    //
    function setup(delay: unsigned = 40; inDeviceId: int = int(WAVE_MAPPER); outDeviceId: int = int(WAVE_MAPPER); format: pWAVEFORMATEX = nil): HRESULT;
    function recordWaveCmd(cmd: int; const fileName: wideString = ''): HRESULT;
    //
    property status: int read f_status;
    property errorCode: int read f_errorCode;
    property delay: unsigned read f_delay write setDelay;
    //
    property waveFormat: PWAVEFORMATEXTENSIBLE read getWaveFormat;
    //
    property waveIn: unaWaveInDevice read f_waveIn;
    property waveOut: unaWaveOutDevice read getWaveOut; // stupid Delphi compiler canot directly cast f_waveOut as unaWaveOutDevice.
    //
    property onDataAvailable: unaWaveDataEvent read f_onDA write f_onDA;
    property onChunkDone: unaWaveDataEvent read f_onCD write f_onCD;
  end;


implementation


uses
  unaUtils;


  { myWaveOutDevice }

// -- --
function myWaveOutDevice.onHeaderDone(header: unaWaveHeader; wakeUpByHeaderDone: bool): bool;
begin
  if (wakeUpByHeaderDone and Assigned(f_master.f_onCD)) then
    f_master.f_onCD(f_master, header.lpData, header.dwBufferLength);
  //
  result := true;
end;


  { unaAudioFeedbackClass }

// --  --
procedure unaAudioFeedbackClass.afterConstruction();
begin
  f_status := c_stat_afStopped;
  f_errorCode := 0;
  //
  f_waveIn := unaWaveInDevice.create();
  f_waveOut := myWaveOutDevice.create();
  f_waveOut.f_master := self;
  f_waveOut.jitterRepeat := false;
  f_waveOut.smoothStartup := false;
  //
  f_waveIn.assignStream(false, nil);	// remove outgoing stream
  //
  waveIn.onDataAvailable := onWaveDataAvailable;
  //
  inherited;
  //
  setup();	// assign default values
end;

// --  --
procedure unaAudioFeedbackClass.beforeDestruction();
begin
  inherited;	// should stop thread and close devices
  //
  freeAndNil(f_waveIn);
  freeAndNil(f_waveOut);
end;

// --  --
function unaAudioFeedbackClass.execute(threadId: unsigned): int;
begin
  if (0 = f_errorCode) then
    f_status := c_stat_afActive;
    //
  while (not sleepThread(100)) do ;
  //
  result := 0;
end;

// --  --
function unaAudioFeedbackClass.getWaveFormat(): PWAVEFORMATEXTENSIBLE;
begin
  result := waveIn.dstFormatExt;
end;

// --  --
function unaAudioFeedbackClass.getWaveOut(): unaWaveOutDevice;
begin
  result := f_waveOut;
end;

// --  --
procedure unaAudioFeedbackClass.onWaveDataAvailable(sender: tObject; data: pointer; len: cardinal);
var
  header: myWaveHeader;
begin
  // check if we can feed outbuffer now
  if (int(f_waveOut.inProgress) - 1 <= f_delayAsCount) then begin
    //
    // locate unused header
    inc(f_waveOutLastHeaderIndex);
    if (f_waveOutLastHeaderIndex > high(f_waveOutHeaders)) then
      f_waveOutLastHeaderIndex := low(f_waveOutHeaders);	// dirty hack, assuming we will never run out of headers
    //
    header := f_waveOutHeaders[f_waveOutLastHeaderIndex];
    //
    // send audio chunk to waveOut device
    {$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
    len := min(len, header.dwBufferLength);
    if (0 < len) then
      move(data^, header.lpData^, len);
    {$ELSE }
    header.rePrepare();
    header.setData(data, len);
    {$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
    //
    f_waveOut.addHeader(header);
  end
  else
    inc(f_waveChunksThrownAway);
  //
  // check if we need to increase the delay
  while (not shouldStop and (int(f_waveOut.inProgress) < f_delayAsCount - 2)) do begin
    //
    // send silence to waveOut
    onWaveDataAvailable(sender, f_silence, waveIn.chunkSize);
  end;
  //
  if (acquire(true, 20)) then try
    //
    if (nil <> f_waveFile) then
      f_waveFile.write(data, len);
    //
  finally
    releaseRO();
  end;
  //
  if assigned(f_onDA) then
    f_onDA(self, data, len);
end;

// --  --
function unaAudioFeedbackClass.recordWaveCmd(cmd: int; const fileName: wideString): HRESULT;
var
  wave: pWAVEFORMATEX;
begin
  result := HRESULT(-2);
  //
  if (acquire(true, 100)) then try
    //
    case (cmd) of

      c_recordWaveCmd_start: begin
        //
        if ((nil <> f_waveFile) and sameString(f_waveFile.fileName, fileName)) then begin
          //
          result := S_OK;	// already recording into this file
        end
        else begin
          //
          freeAndNil(f_waveFile);
          wave := nil;
          try
            if (waveExt2wave(waveIn.dstFormatExt, wave)) then
              f_waveFile := unaRiffStream.createNew(fileName, wave^);
          finally
            mrealloc(wave);
          end;
          //
          f_waveFile.open();
          //
          result := S_OK;
        end;
      end;

      c_recordWaveCmd_stop: begin
	//
	freeAndNil(f_waveFile);
	//
	result := S_OK;
      end;

      else
	result := HRESULT(-1);

    end;
    //
  finally
    releaseRO();
  end;
end;

// --  --
procedure unaAudioFeedbackClass.setDelay(delay: unsigned);
begin
  f_delay := delay;
  f_delayAsCount := delay div (1000 div c_defChunksPerSecond);
end;

// --  --
function unaAudioFeedbackClass.setup(delay: unsigned; inDeviceId, outDeviceId: int; format: pWAVEFORMATEX): HRESULT;
begin
  stop();	 // just in case
  //
  self.delay := delay;
  waveIn.deviceId := unsigned(inDeviceId);
  waveOut.deviceId := unsigned(outDeviceId);
  //
  if (nil <> format) then
    waveIn.setSampling(format)
  else
    waveIn.setSampling(22050, 16, 1);
  //
  waveOut.setSamplingExt(false, waveIn.dstFormatExt);
  //
  result := 0;
end;

// --  --
procedure unaAudioFeedbackClass.startIn();
var
  i: int;
  res: MMRESULT;
begin
  // try opening waveIn/Out devices
  res := waveOut.open();
  if (mmNoError(res)) then begin
    //
    // create waveOut headers (need to do that _before_ activating the waveIn
    for i := low(f_waveOutHeaders) to high(f_waveOutHeaders) do begin
      //
      {$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
      f_waveOutHeaders[i] := newWaveHdr(waveOut, waveOut.chunkSize);
      {$ELSE }
      f_waveOutHeaders[i] := myWaveHeader.create(waveOut, waveOut.chunkSize);
      f_waveOutHeaders[i].prepare();
      {$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
    end;
    //
    f_silence := malloc(waveIn.chunkSize, true, choice(8 = waveIn.dstFormatExt.format.wBitsPerSample, $80, int(0)));
    //
    f_waveChunksThrownAway := 0;
    //
    res := waveIn.open();
    if (mmNoError(res)) then begin
      //
      // looks like all devices were activated normally
      f_errorCode := 0;
    end
    else begin
      //
      f_status := c_stat_afErrorIn;
      f_errorCode := res;
    end;
  end
  else begin
    //
    f_status := c_stat_afErrorOut;
    f_errorCode := res;
  end;
  //
  inherited;
end;

// --  --
procedure unaAudioFeedbackClass.startOut();
var
  i: int;
begin
  // close all devices
  waveIn.close();
  //
  // release waveOut headers (need to do that _before_ activating the waveIn
  for i := low(f_waveOutHeaders) to high(f_waveOutHeaders) do begin
    //
    {$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
    removeWaveHdr(f_waveOutHeaders[i], waveOut);
    {$ELSE }
    f_waveOutHeaders[i].unprepare();
    freeAndNil(f_waveOutHeaders[i]);
    {$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
  end;
  //
  waveOut.close();
  //
  mrealloc(f_silence);
  //
  f_status := c_stat_afStopped;
  //
  recordWaveCmd(c_recordWaveCmd_stop);
  //
  inherited;
end;


end.

