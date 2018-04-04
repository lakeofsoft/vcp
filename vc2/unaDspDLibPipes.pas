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

	  unaDspDLibPipes.pas - DSP DLib pipe components
	  Voice Communicator components version 2.5 Pro

	----------------------------------------------
	  Copyright (c) 2007-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 15 Mar 2007

	  modified by:
		Lake, Mar 2007

	----------------------------------------------
*)

{$I unaDef.inc}

{*
  DSP Classes pipe wrappers.

  @Author Lake

  2.5.2008.07 Still here
}

unit
  unaDspDLibPipes;

interface

uses
  Windows, unaTypes, unaClasses, unaMsAcmApi,
  unaDspLibH, unaDspLibAutomation, unaVC_pipe, unaVC_wave,
  Classes;

type
  {*
    Abstract wave DSP DLib pipe.
  }
  unaDSPDLibWavePipe = class(unavclInOutWavePipe)
  private
    f_localBuf: pointer;
    f_localBufSize: int;
    //
    f_active: bool;	// this property simply stores current active state
    //
    f_automation: unaDSPLibAutomat;
    //
    f_processDataInPlace: boolean;
  protected
    {*
      Converts DSP DLib output float buffer(s) to PCM plain buffer, and returns its size in bytes.
    }
    function convertOutFloat2PCM(out buf: pointer): int; virtual;
    //
    {*
      Returns true if component was activated.
    }
    function isActive(): bool; override;
    {*
      "Activates" the component.
    }
    function doOpen(): bool; override;
    {*
      "Deactivates" the component.
    }
    procedure doClose(); override;
    {*
      Applies new format on DSP automation.
    }
    function applyDeviceFormat(format: PWAVEFORMATEXTENSIBLE; isSrc: bool = true): bool; override;
    {*
      Processes new chunk with DSP automation.
    }
    function doWrite(data: pointer; len: uint; provider: pointer = nil): uint; override;
    {*
      Reads last data processed by DSP automation.
      Not yet implemented.
    }
    function doRead(data: pointer; len: uint): uint; override;
  public
    constructor Create(owner: tComponent); override;
    procedure AfterConstruction(); override;
    procedure BeforeDestruction(); override;
    //
    {*
      DSPDLib automation.
    }
    property automation: unaDSPLibAutomat read f_automation;
    //
  published
    {*
      Specifies whether data should be processed by conponent "in place", changing the values in provider's buffer.
      When set to false data will be processed using local buffer (a bit slowly, but does not touch provider's data).
      Must be set to false if provider has more than one consumer.
    }
    property processDataInPlace: boolean read f_processDataInPlace write f_processDataInPlace default true;
    {*
      DSP components are usually a format providers -- so this property value was changed to be true by default.
    }
    property isFormatProvider default true;
    {*
      Specifies whether the component would perform any data processing.
    }
    property enableDataProcessing;
  end;


const
  //
  c_defNumBands	= 10;


type
  //
  unavcDSPDLib_freqAssignMode = (unafam_manual, unafam_powerOf2);

  //
  // --  --
  //
  unavclDSPDLibMultiBand = class(unaDSPDLibWavePipe)
  private
    f_numBands: unsigned;
    f_freqAssignMode: unavcDSPDLib_freqAssignMode;
    //
    procedure setNumBands(value: unsigned);
    function getFreq(band: unsigned): dspl_float;
    procedure setFreq(band: unsigned; const value: dspl_float);
    //
    function allocateNBuf(n: int): pFloatArray;
    procedure checkFreqMode();
  protected
    f_dsplObj: dspl_handle;
    //
    procedure doSetNumBands(value: unsigned); virtual;
    //
    {*
      Usually number of freq equals number of bands, but some classes may override this.
    }
    function getNumFreq(): int; virtual;
    {*
      In addition makes sure frequencises are correct.
    }
    function applyDeviceFormat(format: PWAVEFORMATEXTENSIBLE; isSrc: bool = true): bool; override;
  public
    procedure AfterConstruction(); override;
    //
    {*
      DSPDLib object.
    }
    property dsplObj: dspl_handle read f_dsplObj;
    {*
      Frequency value for a specific band.
    }
    property frequency[band: unsigned]: dspl_float read getFreq write setFreq;
  published
    {*
      Number of bands, 32 max.
    }
    property numBands: unsigned read f_numBands write setNumBands default c_defNumBands;
    {*
      Frequences assigment mode.
    }
    property freqAssignMode: unavcDSPDLib_freqAssignMode read f_freqAssignMode write f_freqAssignMode default unafam_powerOf2;
  end;


  {*
    EQ Pipe.
  }
  TunavclDSPDLibEQ = class(unavclDSPDLibMultiBand)
  private
    //
    function getGain(band: unsigned): dspl_float;
    procedure setGain(band: unsigned; const value: dspl_float);
  protected
    //
    procedure doSetNumBands(value: unsigned); override;
  public
    constructor Create(owner: tComponent); override;
    //
    {*
      Gain value for a specific band.
    }
    property gain[band: unsigned]: dspl_float read getGain write setGain;
  end;


  //
  // pointer to array of raw samples for up to 256 bands
  punaDspBandRawSamples = ^unaDspBandRawSamples;
  unaDspBandRawSamples = array[byte] of pFloatArray;

  //
  {*
    Fired when raw multi-band samples are ready.
  }
  unavclRawSamplesAvailable = procedure(sender: unavclInOutPipe; numSamples, numBands, channel: unsigned; samples: punaDspBandRawSamples) of object;


  {*
    Multi-band Splitter Pipe.
  }
  TunavclDSPDLibMBSP = class(unavclDSPDLibMultiBand)
  private
    f_bandPT: array[byte] of bool;	// up to 256 bands
    //
    f_localRaw: array[byte] of unaDspBandRawSamples;	// up to 256 channels
    f_localFBuf: array[byte] of pFloatArray;		// up to 256 channels
    f_localFBufSize: array[byte] of int;
    //
    f_onRawSamplesAvail: unavclRawSamplesAvailable;
    //
    function getPT(band: unsigned): bool;
    procedure setPT(band: unsigned; value: bool);
  protected
    {*
      Converts DSP DLib output float buffer(s) to PCM plain buffer, and returns its size in bytes.
    }
    function convertOutFloat2PCM(out buf: pointer): int; override;
    {*
      Num of freqs is one less than numBands in MBSP, so we override this function
    }
    function getNumFreq(): int; override;
  public
    constructor Create(owner: tComponent); override;
    procedure AfterConstruction(); override;
    procedure BeforeDestruction(); override;
    //
    {*
      Pass-through value for a specific band.
    }
    property passThrough[band: unsigned]: bool read getPT write setPT;
  published
    {*
      MBSP splits the audio into bands only when processDataInPlace is false, so we make it default.
    }
    property processDataInPlace default false;
    //
    {*
      Fired when raw multi-band samples are ready.
    }
    property onRawSamplesAvailable: unavclRawSamplesAvailable read f_onRawSamplesAvail write f_onRawSamplesAvail;
  end;


{*
  Registers VC DSP DLib components in Delphi IDE components palette.
}
procedure Register();


implementation


uses
  unaUtils, unaDspDLib;

var
  //
  // global root - Delphi implementation of DSP Lib
  g_root: unaDspLibAbstract;


{ unaDSPDLibWavePipe }

// --  --
procedure unaDSPDLibWavePipe.AfterConstruction();
begin
  inherited;	// creates PCM format 
  //
  processDataInPlace := true;
  isFormatProvider := true;	// by default
end;

// --  --
function unaDSPDLibWavePipe.applyDeviceFormat(format: PWAVEFORMATEXTENSIBLE; isSrc: bool): bool;
begin
  // there is no inheried implementation to call
  //
  result := SUCCEEDED(automation.setFormat(format.format.nSamplesPerSec, format.format.wBitsPerSample, format.format.nChannels));
end;

// --  --
procedure unaDSPDLibWavePipe.BeforeDestruction();
begin
  inherited;
  //
  freeAndNil(f_automation);
  //
  f_localBufSize := 0;
  mrealloc(f_localBuf);
end;

// --  --
function unaDSPDLibWavePipe.convertOutFloat2PCM(out buf: pointer): int;
var
  p, c: unsigned;
  s: unsigned;
  nSamples: unsigned;
  outBuf: pdspl_float;
  f: dspl_float;
  //
  pcmBits: unsigned;	// local copy of pcmFormat.wBitsPerSample
begin
  result := 0;
  //
  // convert float samples to integer values (if we have to)
  if (0 < pcmFormatExt.format.nChannels) then begin
    //
    pcmBits := pcmFormatExt.format.wBitsPerSample;
    for c := 0 to pcmFormatExt.format.nChannels - 1 do begin
      //
      automation.getOutData(c, outBuf, nSamples);
      //
      if (1 > nSamples) then
	continue;	// no out data in this channel?
      //
      result := nSamples * pcmFormatExt.format.nChannels * (1 + (pcmBits - 1) shr 3);
      if (f_localBufSize < result) then begin
	//
	mrealloc(f_localBuf, result);
	f_localBufSize := result;
      end;
      //
      p := c;
      for s := 0 to nSamples - 1 do begin
	//
	f := outBuf^;
	if (f > 1.0) then
	  f := 1.0;
	//
	if (f < -1.0) then
	  f := -1.0;
	//
	case (pcmBits) of

	   8: pArray(f_localBuf)[p] 	 := trunc(f * $FF + $80);

	  16: pInt16Array(f_localBuf)[p] := trunc(f * $7FFF);

	  24: pInt32Array(f_localBuf)[p] := trunc(f * $7FFFFF);

	  32: pFloatArray(f_localBuf)[p] := f;

	end;
	//
	inc(outBuf);
	inc(p, pcmFormatExt.format.nChannels);	// go to next sample in same channel
	//
      end;	// for all samples
    end;      // for all channels
    //
    buf := f_localBuf;
    //
  end;	// 0 < channels
end;

// --  --
constructor unaDSPDLibWavePipe.create(owner: tComponent);
begin
  f_automation := unaDSPLibAutomat.create(g_root);
  //
  inherited;
end;

// --  --
procedure unaDSPDLibWavePipe.doClose();
begin
  inherited;
  //
  f_active := false;
end;

// --  --
function unaDSPDLibWavePipe.doOpen(): bool;
begin
  inherited doOpen();	// it will return false since "device" is nil
  result := true;
  //
  f_active := result;
end;

// --  --
function unaDSPDLibWavePipe.doRead(data: pointer; len: uint): uint;
begin
  // not yet implemeted
  result := 0;
end;

// --  --
function unaDSPDLibWavePipe.doWrite(data: pointer; len: uint; provider: pointer): uint;
var
  res: HRESULT;
  buf: pointer;
begin
  result := 0;
  //
  if (enableDataProcessing) then begin
    //
    if (enter(false, 100)) then begin	// we must protect automation and local buffer from MT entering
      //
      try
	// process data, but do not write it into same buffer (if processDataInPlace is false)
	res := automation.processChunk(data, len, -1, -1, processDataInPlace);
	//
	if (SUCCEEDED(res)) then begin
	  //
	  // new data is available immediately, convert it to integers and notify
	  if (not processDataInPlace) then begin
	    //
	    result := convertOutFloat2PCM(buf);
	    onNewData(buf, result, self);
	  end
	  else begin
	    //
	    result := len;
	    onNewData(data, result, self);
	  end;
	end;
	//
      finally
	leaveWO();
      end;
    end;
  end
  else begin
    //
    // simply pass data through
    result := len;
    onNewData(data, result, self);
  end;
end;

// --  --
function unaDSPDLibWavePipe.isActive(): bool;
begin
  // inherited will return false, since "device" is nil
  //
  result := f_active;
end;


{ unavclDSPDLibMultiBand }

// --  --
procedure unavclDSPDLibMultiBand.AfterConstruction();
begin
  inherited;
  //
  freqAssignMode := unafam_powerOf2;
  numBands := c_defNumBands;
end;

// --  --
function unavclDSPDLibMultiBand.allocateNBuf(n: int): pFloatArray;
begin
  if (0 <= n) then
    result := malloc(n * sizeOf(dspl_float))
  else
    result := nil;
end;

// --  --
function unavclDSPDLibMultiBand.applyDeviceFormat(format: PWAVEFORMATEXTENSIBLE; isSrc: bool): bool;
begin
  // apply format on automation
  result := inherited applyDeviceFormat(format, isSrc);
  //
  if (result) then
    checkFreqMode();
end;

// --  --
procedure unavclDSPDLibMultiBand.checkFreqMode();
var
  i: int;
  frq:  pFloatArray;
  max: dspl_float;
  f: dspl_float;
  n: int;
begin
  case (f_freqAssignMode) of

    unafam_manual: begin
      // not much to care about
      //
      // just make sure we have freq buffer large enough to hold the bands,
      // and adjust the size of freq buffer as necessary
      if (0 < getNumFreq()) then
	frequency[getNumFreq() - 1] := frequency[getNumFreq() - 1];
    end;

    unafam_powerOf2: begin
      //
      n := getNumFreq();
      if ((0 < n) and (0 < pcmFormatExt.format.nSamplesPerSec)) then begin
	//
	max := pcmFormatExt.format.nSamplesPerSec / 2.75625;
	frq := allocateNBuf(n);
	try
	  for i := 1 to n do begin
	    //
	    f := max / (1 shl (int(n) - i));
	    frq[i - 1] := f / pcmFormatExt.format.nSamplesPerSec;
	  end;
	  //
	  automation.dspl_obj_setc(dsplObj, DSPL_PID or DSPL_P_FRQ, pdspl_float(frq), n);
	finally
	  mrealloc(frq);
	end;
	//
      end;	// 0 < n
    end;

  end;	// case
end;

// --  --
procedure unavclDSPDLibMultiBand.doSetNumBands(value: unsigned);
begin
  if (f_numBands <> value) then begin
    //
    f_numBands := value;
    //
    automation.dspl_obj_seti(dsplObj, DSPL_PID or DSPL_P_OTHER, numBands);           // set number of bands
    //
    checkFreqMode();
  end;
end;

// --  --
function unavclDSPDLibMultiBand.getFreq(band: unsigned): dspl_float;
var
  chunk: pdspl_chunk;
begin
  chunk := automation.root.getc(dsplObj, DSPL_PID or DSPL_P_FRQ);
  if ((nil <> chunk) and (int(band) < chunk.r_len)) then
    result := pFloatArray(chunk.r_fp)[band] * pcmFormatExt.format.nSamplesPerSec
  else
    result := 0.0;
end;

// --  --
function unavclDSPDLibMultiBand.getNumFreq(): int;
begin
  result := numBands;
end;

// --  --
procedure unavclDSPDLibMultiBand.setFreq(band: unsigned; const value: dspl_float);
var
  i: int;
  fbuf: pFloatArray;
  chunk: pdspl_chunk;
  n: int;
begin
  if (int(band) < getNumFreq()) then begin
    //
    chunk := automation.root.getc(dsplObj, DSPL_PID or DSPL_P_FRQ);
    if ((nil <> chunk) and (int(band) < chunk.r_len)) then begin
      //
      pFloatArray(chunk.r_fp)[band] := value / pcmFormatExt.format.nSamplesPerSec;
      //
      // assuming the chunk will not be re-allocated
      automation.dspl_obj_setc(dsplObj, DSPL_PID or DSPL_P_FRQ, chunk.r_fp, getNumFreq()); // we also make sure number of bands is properly specified
    end
    else begin
      //
      // must allocate a larger chunk
      n := getNumFreq();
      fbuf := allocateNBuf(n);
      if (0 < n) then begin
	//
	try
	  for i := 0 to n - 1 do begin
	    //
	    if (i = int(band)) then
	      fbuf[i] := value  / pcmFormatExt.format.nSamplesPerSec	//
	    else
	      if (i < chunk.r_len) then
		fbuf[i] := pFloatArray(chunk.r_fp)[i]	// take old values we have in the chunk
	      else
		fbuf[i] := 0.0;	// zero the rest
	    //
	  end;
	  //
	  automation.dspl_obj_setc(dsplObj, DSPL_PID or DSPL_P_FRQ, pdspl_float(fbuf), getNumFreq());
	finally
	  mrealloc(fbuf);
	end;
      end;
    end;
    //
  end;
end;

// --  --
procedure unavclDSPDLibMultiBand.setNumBands(value: unsigned);
begin
  doSetNumBands(value);
end;


{ TunavclDSPDLibEQ }

// --  --
constructor TunavclDSPDLibEQ.create(owner: tComponent);
begin
  inherited;	// creates automation
  //
  f_dsplObj := automation.dspl_objNew(DSPL_OID or DSPL_EQMB);
end;

// --  --
procedure TunavclDSPDLibEQ.doSetNumBands(value: unsigned);
begin
  inherited;
  //
  // just make sure we have gain buffer large enough to hold the numBands
  // and adjust the size of gain buffer if necessary
  gain[numBands - 1] := gain[numBands - 1];
end;

// --  --
function TunavclDSPDLibEQ.getGain(band: unsigned): dspl_float;
var
  chunk: pdspl_chunk;
begin
  chunk := automation.root.getc(dsplObj, DSPL_PID or DSPL_P_GAIN);
  if ((nil <> chunk) and (int(band) < chunk.r_len)) then
    result := v2db(pFloatArray(chunk.r_fp)[band])
  else
    result := 0.0;
end;

// --  --
procedure TunavclDSPDLibEQ.setGain(band: unsigned; const value: dspl_float);
var
  i: int;
  gbuf: pFloatArray;
  chunk: pdspl_chunk;
begin
  if (band < numBands) then begin
    //
    chunk := automation.root.getc(dsplObj, DSPL_PID or DSPL_P_GAIN);
    if ((nil <> chunk) and (int(band) < chunk.r_len)) then begin
      //
      pFloatArray(chunk.r_fp)[band] := db2v(value);
      //
      // assuming the chunk will not be re-allocated
      automation.dspl_obj_setc(dsplObj, DSPL_PID or DSPL_P_GAIN, chunk.r_fp, numBands);
    end
    else begin
      //
      // must allocate a larger chunk
      gbuf := allocateNBuf(numBands);
      if (0 < numBands) then begin
	try
	  for i := 0 to numBands - 1 do begin
	    //
	    if (i = int(band)) then
	      gbuf[i] := db2v(value)
	    else
	      if (i < chunk.r_len) then
		gbuf[i] := pFloatArray(chunk.r_fp)[i]	// take old values we have in the chunk
	      else
		gbuf[i] := db2v(0.0);	// zero the rest
	    //
	  end;
	  //
	  automation.dspl_obj_setc(dsplObj, DSPL_PID or DSPL_P_GAIN, pdspl_float(gbuf), numBands);
	finally
	  mrealloc(gbuf);
	end;
      end;
      //
    end;
  end;
end;


{ TunavclDSPDLibMBSP }

// --  --
procedure TunavclDSPDLibMBSP.AfterConstruction();
begin
  inherited;
  //
  processDataInPlace := false;	// assign default value
end;

// --  --
procedure TunavclDSPDLibMBSP.BeforeDestruction();
var
  c: unsigned;
begin
  inherited;
  //
  for c := low(f_localFBuf) to high(f_localFBuf) do begin
    //
    f_localFBufSize[c] := 0;
    mrealloc(f_localFBuf[c]);
  end;  
end;

// --  --
function TunavclDSPDLibMBSP.convertOutFloat2PCM(out buf: pointer): int;
var
  p, b, c: unsigned;
  s: unsigned;
  nSamples: unsigned;
  outBuf: pdspl_float;
  f: dspl_float;
  //
  pcmBits: unsigned;	// local copy of pcmFormat.wBitsPerSample
  pcmChannels: unsigned;
begin
  result := 0;
  //
  pcmBits := pcmFormatExt.format.wBitsPerSample;
  pcmChannels := pcmFormatExt.format.nChannels;
  //
  // convert float samples to integer values (if we have to)
  if ((0 < pcmBits) and (0 < pcmChannels) and (0 < numBands)) then begin
    //
    // 1. calculate the resulting samples, taking passThrough in account
    //
    for c := 0 to pcmChannels - 1 do begin
      //
      for b := 0 to numBands - 1 do begin
	//
	automation.getMultiOutData(c, b, outBuf, nSamples);
	f_localRaw[c][b] := pFloatArray(outBuf);
	//
	if (1 > nSamples) then
	  continue;	// no out data in this channel/band?
	//
	if (f_localFBufSize[c] <> int(nSamples) * sizeOf(dspl_float)) then begin
	  //
	  f_localFBufSize[c] := nSamples * sizeOf(dspl_float);
	  mrealloc(f_localFBuf[c], f_localFBufSize[c]);
	end;
	//
	// sum up samples in this channel with current band
	for s := 0 to nSamples - 1 do begin
	  //
	  if (f_bandPT[b]) then
	    f := outBuf^
	  else
	    f := 0.0;	// this band is not included in result
	  //
	  if (0 = b) then
	    f_localFBuf[c][s] := f	// take samples from first band as a result
	  else
	    f_localFBuf[c][s] := f_localFBuf[c][s] + f;
	  //
	  inc(outBuf);
	end;
	//
      end;	// for all bands
      //
      // notify we have some samples ready
      if (assigned(f_onRawSamplesAvail)) then
	f_onRawSamplesAvail(self, nSamples, numBands, c, @f_localRaw[c]);
      //
    end;      // for all channels
    //
    // 2. convert result to output buffer
    //
    for c := 0 to pcmChannels - 1 do begin
      //
      nSamples := f_localFBufSize[c] div sizeOf(dspl_float);
      //
      result := nSamples * pcmChannels * (1 + (pcmBits - 1) shr 3);
      if (f_localBufSize < result) then begin
	//
	mrealloc(f_localBuf, result);
	f_localBufSize := result;
      end;
      //
      p := c;
      for s := 0 to nSamples - 1 do begin
	//
	f := f_localFBuf[c][s];
	if (f > 1.0) then
	  f := 1.0;
	//
	if (f < -1.0) then
	  f := -1.0;
	//
	case (pcmBits) of

	   8: pArray(f_localBuf)[p] 	    := trunc(f * $FF + $80);
	  16: pInt16Array(f_localBuf)[p] := trunc(f * $7FFF);
	  24: pInt32Array(f_localBuf)[p]    := trunc(f * $7FFFFF);
	  32: pFloatArray(f_localBuf)[p]    := f;

	end;
	//
	inc(p, pcmChannels);	// go to next sample in same channel
	//
      end;	  // for all samples
    end;      // for all channels
    //
    buf := f_localBuf;
    //
  end;	// 0 < channels
end;

// --  --
constructor TunavclDSPDLibMBSP.create(owner: tComponent);
var
  i: int;
begin
  inherited;	// creates automation
  //
  f_dsplObj := automation.dspl_objNew(DSPL_OID or DSPL_MBSP);
  //
  for i := low(f_bandPT) to high(f_bandPT) do
    f_bandPT[i] := true;
end;

// --  --
function TunavclDSPDLibMBSP.getNumFreq(): int;
begin
  result := int(numBands) - 1
end;

// --  --
function TunavclDSPDLibMBSP.getPT(band: unsigned): bool;
begin
  result := f_bandPT[band];
end;

// --  --
procedure TunavclDSPDLibMBSP.setPT(band: unsigned; value: bool);
begin
  f_bandPT[band] := value;
end;


//
// -- IDE --
//
procedure Register();
begin
  RegisterComponents(c_VC_reg_DSP_section_name, [
    TunavclDSPDLibEQ,
    TunavclDSPDLibMBSP
  ]);
end;

// -- unit globals --

initialization
  g_root := unaDspDLibRoot.create();

finalization
  freeAndNil(g_root);
end.

