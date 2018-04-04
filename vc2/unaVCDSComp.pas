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

	  unaVCDSComp.pas - VC 2.5 Pro DS components
	  Voice Communicator components version 2.5 Pro

	----------------------------------------------
	  Copyright (c) 2007-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 27 Sep 2007

	  modified by:
		Lake, Sep-Dec 2007
		Lake, Jan 2008
		Lake, Apr 2010

	----------------------------------------------
*)

{$I unaDef.inc}

{*
  DirectSound wrapper components.

  @Author Lake

  Version 2.5.2008.07 Still here

  Version 2.5.2010.04 Added some sanity (notified buffers now should be exactly 20ms now)
		       Small memory leak fixed
		       Vista/Win7 AEC
}

{$IFDEF DEBUG }
  {x $DEFINE UNA_DSFD_LOWLEVELBUFFERLOG }		// log low-level buffer events
{$ENDIF DEBUG }

unit
  unaVCDSComp;

interface

uses
  Windows, unaTypes, unaClasses, unaVCDSIntf,
  unaVC_pipe, unaVC_wave,
  unaMsAcmAPI, unaMsAcmClasses;

const
  // chunks per second
  c_unaDSFD_cps	= 50;	// 20ms chunk

type
  {$EXTERNALSYM VARIANT_BOOL}
  VARIANT_BOOL = SHORT;

  {*
    DirectSound Full Duplex component.
  }
  TunavclDX_FullDuplex = class(unavclInOutWavePipe)
  private
    f_dsRes: HRESULT;
    //
    f_appHandle: tHandle;	// application handle
    //
    f_enAEC: boolean;		// enable AEC
    f_enVAD: boolean;
    f_enNS: boolean;
    f_enAGC: boolean;
    //
    f_devIdCap: int;
    f_devIdRen: int;
    //
    f_nvCap: array[0..c_unaDSFD_cps - 1] of tHandle;
    //
    f_mtCap: unaThread;
    f_mtRen: unaThread;
    //
    f_bytesPerCapChunk: DWORD;
    f_renOfs: int;
    f_maxRenOfs: int;
    //
    f_enumIndexCap, f_enumIndexRen: int;
    f_enumCap: bool;
    f_renGUIDS: array[0..31] of tGUID;
    f_capGUIDS: array[0..31] of tGUID;
    f_renDevName: array[0..31] of string;
    f_capDevName: array[0..31] of string;
    //
    f_capIsOK: bool;
    f_capEft: DSCEFFECTDESC;
    //
    f_idsfd: IDirectSoundFullDuplex8;
    f_idsCapBuf: IDirectSoundCaptureBuffer8;
    f_idsRenBuf: IDirectSoundBuffer8;
    //
    f_onFD: unavclPipeDataEvent;
    //
    f_DMO: IMediaObject;
    //f_OInP: IMediaObjectInPlace;
    f_PS: IPropertyStore;
    f_dmoFrameSize: int;
    f_idsren: IDirectSound8;
    f_idsrenbuffer: IDirectSoundBuffer;
    //
    f_outBuf: tMediaBuffer;
    f_outBuffers: DMO_OUTPUT_DATA_BUFFER;
    //
    function getDevGUID(isCap: bool): PGUID;
    function getDevName(index: int; cap: bool): string;
    function getDevNum(cap: bool): int;
    //
    procedure enumDevByFlow(cap: bool);
    //
    procedure initDS();
    procedure releaseDS();
  protected
    function doWrite(data: pointer; len: uint; provider: pointer = nil): uint; override;
    function getAvailableDataLen(index: integer): uint; override;
    function doOpen(): bool; override;
    procedure doClose(); override;
    function  isActive(): bool; override;
    //
    procedure createNewDevice(); override;
  public
    procedure AfterConstruction(); override;
    {*
        Enumerates DS devices. Called in AfterConstruction(). Use to refresh list of devices.
    }
    procedure enumDevices();
    {*
	Get current AEC status.
    }
    function getAECStatus(out status: DWORD): HRESULT;
    {*
	Get AEC parameters.
    }
    function getAECParams(out params: DSCFXAec): HRESULT;
    {*
	Result of last DS call.
    }
    property dsRes: HRESULT read f_dsRes;
    {*
	Application handle which should be passed to DS.
    }
    property appHandle: tHandle read f_appHandle write f_appHandle;
    {*
        Number of capture (recording) [true] or rendering (playback) [true] devices.
    }
    property deviceNum[cap: bool]: int read getDevNum;
    {*
        Name of capture (recording) [true] or rendering (playback) [true] device by index (index is from 0 to deviceNum[] - 1).
    }
    property deviceName[index: int; cap: bool]: string read getDevName;
  published
    {*
	Device ID for rendering (playback).
    }
    property deviceIdRender: int read f_devIdRen write f_devIdRen;
    {*
	Device ID for capture (recording).
    }
    property deviceIdCapture: int read f_devIdCap write f_devIdCap;
    {*
	True if AEC should be enabled.
    }
    property enableAEC: boolean read f_enAEC write f_enAEC default false;
    {*
	True if AGC should be enabled (Vista/Win7 only).
    }
    property enableAGC: boolean read f_enAGC write f_enAGC default true;
    {*
	True if NS should be enabled (Vista/Win7 only).
    }
    property enableNS: boolean read f_enNS write f_enNS default true;
    {*
	True if VAD should be enabled (Vista/Win7 only).
    }
    property enableVAD: boolean read f_enVAD write f_enVAD default false;
    {*
    	Another rendering chunk is done.
    }
    property onFeedDone: unavclPipeDataEvent read f_onFD write f_onFD;
  end;


{*
  IDE registration
}
procedure Register();


implementation


uses
  unaUtils, Classes, ActiveX, MMSystem;

type
  //
  myCapNotifyThread = class(unaThread)
  private
    f_ds: TunavclDX_FullDuplex;
  protected
    function execute(threadID: unsigned): int; override;
  end;

  //
  myRenNotifyThread = class(unaThread)
  private
    f_ds: TunavclDX_FullDuplex;
    f_renEv: tHandle;
  protected
    function execute(threadID: unsigned): int; override;
  public
    procedure AfterConstruction(); override;
    procedure BeforeDestruction(); override;
  end;


{ myCapNotifyThread }

// --  --
function myCapNotifyThread.execute(threadID: unsigned): int;
var
  i: DWORD;
  res: HRESULT;
  ptr1, ptr2: pointer;
  size1, size2, ignore: DWORD;
  myBuf: pArray;
begin
  if (SUCCEEDED(CoInitializeEx(nil, COINIT_MULTITHREADED))) then try
    //
    myBuf := malloc(f_ds.f_bytesPerCapChunk);
    try
      while (not shouldStop) do begin
        //
        try
          if (assigned(f_ds.f_DMO)) then begin
            //
            f_ds.f_outBuffers.dwStatus := 0;
            repeat
              //
              res := f_ds.f_DMO.ProcessOutput(0, 1, @f_ds.f_outBuffers, ignore);
              if (SUCCEEDED(res)) then begin
                //
                res := f_ds.f_outBuffers.pBuffer.GetBufferAndLength(PByte(ptr1), size1);
                if (SUCCEEDED(res)) then begin
                  //
                  if (0 < size1) then begin
                    //
                    f_ds.onNewData(ptr1, size1, f_ds);
                    f_ds.f_outBuffers.pBuffer.SetLength(0);
                    //
                    f_ds.f_capIsOK := true;
                    //
                    // wakeup rendering notification
                    //
                    if (not shouldStop) then
                      SetEvent(myRenNotifyThread(f_ds.f_mtRen).f_renEv);
                  end
                  else
                    sleepThread(10);
                end
                else
                  sleepThread(10);
              end
              else
                sleepThread(10);
              //
            until (shouldStop or (0 <> (f_ds.f_outBuffers.dwStatus and DMO_OUTPUT_DATA_BUFFERF_INCOMPLETE)));
          end
          else begin
            //
            if (assigned(f_ds.f_idsCapBuf)) then begin
              // notify capture data
              i := WaitForMultipleObjects(c_unaDSFD_cps, pointer(@f_ds.f_nvCap), false, 20);
              if ((WAIT_TIMEOUT <> i) and (WAIT_FAILED <> i) and (i <= high(f_ds.f_nvCap))) then begin
                //
                res := f_ds.f_idsCapBuf.lock(i * f_ds.f_bytesPerCapChunk, f_ds.f_bytesPerCapChunk, @ptr1, @size1, @ptr2, @size2, 0);
                if (Succeeded(res) and not shouldStop) then try
                  //
                  // ptr2 should always be nil, as we request non-wrapping parts of buffer only
                  if (nil <> ptr2) then begin
                    //
                    // but if for some reason it is not nil, be prepared
                    //
                    if (nil <> ptr1) then
                      move(ptr1^, myBuf^, min(f_ds.f_bytesPerCapChunk, size1));
                    //
                    move(ptr2^, myBuf[size1], min(f_ds.f_bytesPerCapChunk - size1, size2));
                    //
                    f_ds.onNewData(myBuf, min(f_ds.f_bytesPerCapChunk, size1 + size2), f_ds);
                  end
                  else
                    //
                    // otherwise, simply notify ptr1
                    // (saves lots of karma)
                    //
                    f_ds.onNewData(ptr1, min(f_ds.f_bytesPerCapChunk, size1), f_ds);
                  //
                finally
                  f_ds.f_idsCapBuf.unlock(ptr1, size1, ptr2, size2);
                end;
                //
                // wakeup rendering notification
                //
                if (not shouldStop) then
                  SetEvent(myRenNotifyThread(f_ds.f_mtRen).f_renEv);
              end
              else
                sleepThread(20);
            end
            else
              sleepThread(20);
          end;
        except
        end;
      end;
      //
    finally
      mrealloc(myBuf);
    end;
    //
  finally
    CoUninitialize();
  end;
  //
  result := 0;
end;


{ myRenNotifyThread }

// --  --
procedure myRenNotifyThread.AfterConstruction();
begin
  f_renEv := CreateEvent(nil, false, false, nil);
  //
  inherited;
end;

// --  --
procedure myRenNotifyThread.BeforeDestruction();
begin
  inherited;
  //
  CloseHandle(f_renEv);
end;

// --  --
function myRenNotifyThread.execute(threadID: unsigned): int;
var
  res: HRESULT;
  play, w,
  bpc, d, fs: DWORD;
  waitto: int;
begin
  if (SUCCEEDED(CoInitializeEx(nil, COINIT_MULTITHREADED))) then try
    //
    //fs := f_ds.pcmFormatExt.format.nAvgBytesPerSec;
    fs := f_ds.f_maxRenOfs;
    bpc := fs div c_defChunksPerSecond;
    waitto := 20;
    //
    while (not shouldStop) do begin
      //
      try
        // notify rendered data
        if (WAIT_OBJECT_0 = WaitForSingleObject(f_renEv, waitto)) then begin
          //
          if ((200 > waitto) and f_ds.f_capIsOK) then
            waitto := 200;
          //
          if (assigned(f_ds.f_idsrenbuffer)) then
            res := f_ds.f_idsrenbuffer.GetCurrentPosition(@play, @w)
          else
            res := f_ds.f_idsRenBuf.GetCurrentPosition(@play, @w);
          //
          if (SUCCEEDED(res)) then begin
            //
            if (unsigned(f_ds.f_renOfs) > play) then
              d := unsigned(f_ds.f_renOfs) - play
            else
              d := fs - play + unsigned(f_ds.f_renOfs);
            //
          {$IFDEF UNA_DSFD_LOWLEVELBUFFERLOG }
            logMessage('PLAY:' + int2str(play) + ' / ROFS:' + int2str(f_ds.f_renOfs) + ' / D:' + int2str(d));
          {$ENDIF UNA_DSFD_LOWLEVELBUFFERLOG }
            //
            // notify rendering
            //
            if (not shouldStop and assigned(f_ds.f_onFD)) then begin
              //
              if (d < bpc shl 4) then begin
                //
              {$IFDEF UNA_DSFD_LOWLEVELBUFFERLOG }
                logMessage('MIX1');
              {$ENDIF UNA_DSFD_LOWLEVELBUFFERLOG }
                f_ds.f_onFD(f_ds, nil, 0);
                //
                if (d < bpc shl 1)  then begin
                  //
                {$IFDEF UNA_DSFD_LOWLEVELBUFFERLOG }
                  logMessage('MIX2');
                {$ENDIF UNA_DSFD_LOWLEVELBUFFERLOG }
                  f_ds.f_onFD(f_ds, nil, 0);
                end;
              end;
            end;
          end;
          //
        end;
      except
      end;
    end;
    //
  finally
    CoUninitialize();
  end;
  //
  result := 0;
end;


// --  --
function DSEnumCallback(p1: PGUID; p2: LPCWSTR; p3: LPCWSTR; p4: pointer): bool; stdcall;
var
  ds: TunavclDX_FullDuplex;
begin
  result := false;	// assume there is no reason to continue enumeration
  //
  ds := p4;
  if (nil <> ds) then begin
    //
    if (ds.f_enumCap) then begin
      //
      if (ds.f_enumIndexCap < high(ds.f_renGUIDS)) then begin
        //
        if (nil <> p1) then
    	  ds.f_capGUIDS[ds.f_enumIndexCap] := p1^;
        //
        ds.f_capDevName[ds.f_enumIndexCap] := p2;
      end;
      //
      inc(ds.f_enumIndexCap);
      result := (ds.f_enumIndexCap < high(ds.f_renGUIDS));
    end
    else begin
      //
      if (ds.f_enumIndexRen < high(ds.f_renGUIDS)) then begin
        //
        if (nil <> p1) then
          ds.f_renGUIDS[ds.f_enumIndexRen] := p1^;
        //
        ds.f_renDevName[ds.f_enumIndexRen] := p2;
      end;
      //
      inc(ds.f_enumIndexRen);
      result := (ds.f_enumIndexRen < high(ds.f_renGUIDS));
    end;
  end;
end;


{ TunavclDX_FullDuplex }

// --  --
procedure TunavclDX_FullDuplex.AfterConstruction();
begin
  enableAEC := false;
  enableAGC := true;
  enableNS  := true;
  enableVAD := false;
  //
  f_mtCap := myCapNotifyThread.create();
  myCapNotifyThread(f_mtCap).f_ds := self;
  //
  f_mtRen := myRenNotifyThread.create();
  myRenNotifyThread(f_mtRen).f_ds := self;
  //
  enumDevices();
  //
  inherited;
end;

// --  --
function wndEnum(hwnd: HWND; lParam: LPARAM): bool; stdcall;
var
  buf: array[byte] of char;
begin
  if ((0 = GetParent(hwnd)) and (0 = GetWindow(hwnd, GW_OWNER))) then begin
    //
    GetWindowText(hwnd, buf, sizeOf(buf));
    if ('' = buf) then begin
      //
      pInt(lParam)^ := hwnd;
    end
  end;
  //
  result := true;
end;

// --  --
procedure TunavclDX_FullDuplex.createNewDevice();
begin
  inherited;
  //
  f_appHandle := FindWindow('TApplication', nil);
  if (0 = f_appHandle) then
    f_appHandle := FindWindow('TPUtilWindow', nil);
  //
  if (0 = f_appHandle) then
    EnumThreadWindows(GetCurrentThreadId(), @wndEnum, int(@f_appHandle));
  //
  if (0 = f_appHandle) then
    f_appHandle := GetForegroundWindow();
  //
  {$IFDEF CONSOLE }
    {$IFNDEF NO_ANSI_SUPPORT }
    //
    {$ELSE }
      if (0 = f_appHandle) then
	f_appHandle := GetConsoleWindow();
    {$ENDIF NO_ANSI_SUPPORT }
  {$ENDIF CONSOLE }
  //
  if (0 = f_appHandle) then
    f_appHandle := GetDesktopWindow();
end;

// --  --
procedure TunavclDX_FullDuplex.doClose();
begin
  // stop DS capture/rendering
  releaseDS();
  //
  inherited;
end;

// --  --
function TunavclDX_FullDuplex.doOpen(): bool;
begin
  inherited doOpen();
  //
  // start DS capture/rendering
  initDS();
  //
  result := isActive;
end;

// --  --
function TunavclDX_FullDuplex.doWrite(data: pointer; len: uint; provider: pointer): uint;
var
  res: int;
  //
  ptr1: pointer;
  ptr2: pointer;
  size1: DWORD;
  size2: DWORD;
  //
  szMax1: DWORD;
  szMax2: DWORD;
  //
{$IFDEF UNA_DSFD_LOWLEVELBUFFERLOG }
  play, write: DWORD;
{$ENDIF UNA_DSFD_LOWLEVELBUFFERLOG }
begin
  result := 0;
  //
  if ( (nil <> data) and (0 < len) and (assigned(f_idsRenBuf) or assigned(f_idsrenbuffer)) ) then begin
    //
    // feed DS renderer with some data
    //
    // try locking render buffer and filling it with captured data
    //
    //res := f_idsRenBuf.lock(0, len, @ptr1, @size1, @ptr2, @size2, DSBLOCK_FROMWRITECURSOR);
    if (assigned(f_idsrenbuffer)) then
      res := f_idsrenbuffer.lock(f_renOfs, len, @ptr1, @size1, @ptr2, @size2, 0)
    else
      res := f_idsRenBuf.lock(f_renOfs, len, @ptr1, @size1, @ptr2, @size2, 0);
    //
    if (DSERR_BUFFERLOST = res) then begin
      //
      if (assigned(f_idsrenbuffer)) then begin
        //
        f_idsrenbuffer.Restore();
        res := f_idsrenbuffer.lock(f_renOfs, len, @ptr1, @size1, @ptr2, @size2, 0);
      end
      else begin
        //
        f_idsRenBuf.Restore();
        res := f_idsRenBuf.lock(f_renOfs, len, @ptr1, @size1, @ptr2, @size2, 0);
      end;
    end;
    //
    if (Succeeded(res)) then begin
      //
      try
	// move data to render buffer
	//
	//
	szMax1 := min(len, size1);
	if (0 < szMax1) then
	  move(data^, ptr1^, szMax1);
	//
	if (szMax1 < len) then begin
	  //
	  szMax2 := min(len - szMax1, size2);
	  if (0 < szMax2) then
	    move(pArray(data)[szMax1], ptr2^, szMax2);
	end
	else
	  szMax2 := 0;
	//
	result := szMax1 + szMax2;
      finally
        if (assigned(f_idsrenbuffer)) then
	  f_idsrenbuffer.unlock(ptr1, size1, ptr2, size2)
        else
	  f_idsRenBuf.unlock(ptr1, size1, ptr2, size2)
      end;
      //
    {$IFDEF UNA_DSFD_LOWLEVELBUFFERLOG }
      if (assigned(f_idsrenbuffer)) then
        f_idsrenbuffer.GetCurrentPosition(@play, @write)
      else
        f_idsRenBuf.GetCurrentPosition(@play, @write);
      //
      logMessage('Put ' + int2str(result) + ' bytes @ ' + int2str(f_renOfs) + ' PLAY:' + int2str(play) + ' / WRITE:' + int2str(write));
    {$ENDIF UNA_DSFD_LOWLEVELBUFFERLOG }
      //
      inc(f_renOfs, result);
      if (f_renOfs >= f_maxRenOfs) then
	dec(f_renOfs, f_maxRenOfs);
      //
    end;
  end;
end;

// --  --
procedure TunavclDX_FullDuplex.enumDevByFlow(cap: bool);
var
  i: int;
  num: UINT;
  flow: EDataFlow;
  enum: IMMDeviceEnumerator;
  coll: IMMDeviceCollection;
  ep: IMMDevice;
  props: IPropertyStore;
  pv: PROPVARIANT;
begin
  if (cap) then begin
    //
    f_enumIndexCap := 0;
    flow := eCapture;
  end
  else begin
    //
    f_enumIndexRen := 0;
    flow := eRender;
  end;
  //
  if (SUCCEEDED(CoCreateInstance(CLSID_MMDeviceEnumerator, nil, CLSCTX_INPROC_SERVER, IID_IMMDeviceEnumerator, enum))) then begin
    //
    // enum using Vista code
    //
    if (SUCCEEDED(enum.EnumAudioEndpoints(flow, DEVICE_STATE_ACTIVE, coll))) then try
      //
      coll.GetCount(UINT(num));
      //
      if (SUCCEEDED(enum.GetDefaultAudioEndpoint(flow, eCommunications, ep))) then try
        //
        if (SUCCEEDED(ep.OpenPropertyStore(STGM_READ, props))) then try
          //
          PropVariantInit(pv);
          if (SUCCEEDED(props.GetValue(PKEY_Device_FriendlyName, pv))) then try
            //
            if (cap) then begin
              //
              f_capDevName[f_enumIndexCap] := 'Default -> ' + pv.pwszVal;
              inc(f_enumIndexCap);
            end
            else begin
              //
              f_renDevName[f_enumIndexRen] := 'Default -> ' + pv.pwszVal;
              inc(f_enumIndexRen);
            end;
          finally
            CoTaskMemFree(pv.pwszVal);
          end;
          //
          PropVariantInit(pv);
        finally
          props := nil;
        end;
      finally
        ep := nil;
      end;
      //
      for i := 1 to num do begin
        //
        if (SUCCEEDED(coll.Item(i - 1, ep))) then try
          //
          if (SUCCEEDED(ep.OpenPropertyStore(STGM_READ, props))) then try
            //
            PropVariantInit(pv);
            if (SUCCEEDED(props.GetValue(PKEY_Device_FriendlyName, pv))) then try
              //
              if (cap) then begin
                //
                f_capDevName[f_enumIndexCap] := pv.pwszVal;
                inc(f_enumIndexCap);
              end
              else begin
                //
                f_renDevName[f_enumIndexRen] := pv.pwszVal;
                inc(f_enumIndexRen);
              end;
              //
            finally
              CoTaskMemFree(pv.pwszVal);
            end;
            //
            PropVariantInit(pv);
            if (SUCCEEDED(props.GetValue(PKEY_AudioEndpoint_GUID, pv))) then try
              //
              if (cap) then
                CLSIDFromString(pv.pwszVal, f_capGUIDS[f_enumIndexCap - 1])
              else
                CLSIDFromString(pv.pwszVal, f_renGUIDS[f_enumIndexRen - 1]);
              //
            finally
              CoTaskMemFree(pv.pwszVal);
            end;
          finally
            props := nil;
          end;
          //
        finally
          ep := nil;
        end;
      end;
    finally
      coll := nil;
    end;
  end
  else begin
    //
    // enum using old DS code
    f_enumCap := cap;
    DirectSoundEnumerate(cap, DSEnumCallback, self);
  end;
end;

// --  --
procedure TunavclDX_FullDuplex.enumDevices();
begin
  if (SUCCEEDED(CoInitializeEx(nil, COINIT_MULTITHREADED))) then try
    //
    enumDevByFlow(true);
    enumDevByFlow(false);
  finally
    CoUninitialize();
  end;
end;

// --  --
function TunavclDX_FullDuplex.getAECParams(out params: DSCFXAec): HRESULT;
var
  aec: IDirectSoundCaptureFXAec8;
begin
  if (assigned(f_idsCapBuf)) then begin
    //
    result := f_idsCapBuf.GetObjectInPath(GUID_DSCFX_CLASS_AEC, 0, IID_IDirectSoundCaptureFXAec8, aec);
    if (Succeeded(result)) then
      //
      result := aec.getAllParameters(params);
    //
    aec := nil;
  end
  else
    result := E_NOINTERFACE;
end;

// --  --
function TunavclDX_FullDuplex.getAECStatus(out status: DWORD): HRESULT;
var
  aec: IDirectSoundCaptureFXAec8;
  pv: PROPVARIANT;
  aecm: pAecQualityMetrics_Struct;
begin
  if (assigned(f_PS)) then begin
    //
    status := DSCFX_AEC_STATUS_HISTORY_CONTINUOUSLY_CONVERGED;
    //
    pv.vt := VT_BLOB;
    pv.blob.cbSize := sizeof(AecQualityMetrics_Struct);
    //pv.blob.pBlobData := malloc(pv.blob.cbSize, true, 0);
    try
      result := f_PS.GetValue(MFPKEY_WMAAECMA_QUALITY_METRICS, pv);
      if (Succeeded(result) and (0 < pv.blob.cbSize)) then begin
        //
        aecm := pv.blob.pBlobData;
        if (0 <> aecm.ConvergenceFlag) then
          status := status or DSCFX_AEC_STATUS_CURRENTLY_CONVERGED;
        //
        if (0 <> aecm.SpkMuteFlag) then
          status := status or DSCFX_AEC_STATUS_HISTORY_PREVIOUSLY_DIVERGED;
      end;
    finally
      //mrealloc(pv.blob.pBlobData);
    end;
    //
    aec := nil;
  end
  else
    if (assigned(f_idsCapBuf)) then begin
      //
      result := f_idsCapBuf.GetObjectInPath(GUID_DSCFX_CLASS_AEC, 0, IID_IDirectSoundCaptureFXAec8, aec);
      if (Succeeded(result)) then
        result := aec.getStatus(status);
      //
      aec := nil;
    end
    else
      result := E_NOINTERFACE;
end;

// --  --
function TunavclDX_FullDuplex.getAvailableDataLen(index: integer): uint;
begin
  result := 0;
end;

// --  --
function TunavclDX_FullDuplex.getDevGUID(isCap: bool): PGUID;
begin
  if (isCap) then begin
    //
    if ((WAVE_MAPPER = UINT(f_devIdCap)) or (0 > f_devIdCap)) then
      result := @DSDEVID_DefaultVoiceCapture
    else
      result := @f_capGUIDS[f_devIdCap + 1];
  end
  else begin
    //
    if ((WAVE_MAPPER = UINT(f_devIdRen)) or (0 > f_devIdRen)) then
      result := @DSDEVID_DefaultVoicePlayback
    else
      result := @f_renGUIDS[f_devIdRen + 1];
  end;
end;

// --  --
function TunavclDX_FullDuplex.getDevName(index: int; cap: bool): string;
begin
  if (cap) then
    result := f_capDevName[index]
  else
    result := f_renDevName[index];
end;

// --  --
function TunavclDX_FullDuplex.getDevNum(cap: bool): int;
begin
  if (cap) then
    result := f_enumIndexCap
  else
    result := f_enumIndexRen;
end;

// --  --
procedure TunavclDX_FullDuplex.initDS();
var
  capBuf: DSCBUFFERDESC;
  renBuf: DSBUFFERDESC;
  lpDsNotify: IDIRECTSOUNDNOTIFY8;
  i: integer;
  ofs: int;
  rgdsbpn: array[0..c_unaDSFD_cps - 1] of DSBPOSITIONNOTIFY;
  //
  play, write: DWORD;
  pv: PROPVARIANT;
  mt: DMO_MEDIA_TYPE;
  caps: DSBCAPS;
begin
  releaseDS();
  //
  CoInitializeEx(nil, COINIT_MULTITHREADED);
  //
  capBuf.lpwfxFormat := nil;
  renBuf.lpwfxFormat := nil;
  //
  f_dsRes := CoCreateInstance(CLSID_CWMAudioAEC, nil, CLSCTX_INPROC_SERVER, IID_IMediaObject, f_DMO);
  if (SUCCEEDED(dsRes)) then begin
    //
    f_dsRes := f_DMO.QueryInterface(IID_IPropertyStore, f_PS);
    if (SUCCEEDED(dsRes)) then begin
      //
      // looks like we have Win7/Vista, let use DMO AEC
      //
      // set working mode (AEC/no AEC)
      PropVariantInit(pv);
      pv.vt := VT_I4;
      if (enableAEC) then
        pv.lVal := SINGLE_CHANNEL_AEC
      else
        pv.lVal := SINGLE_CHANNEL_NSAGC;
      //
      f_dsRes := f_PS.SetValue(MFPKEY_WMAAECMA_SYSTEM_MODE, pv);
      if (SUCCEEDED(dsRes)) then begin
        //
        // now set capture/rendering devices
        pv.lVal := int(unsigned(deviceIdRender shl 16) or unsigned($0000ffff and deviceIdCapture));
        f_dsRes := f_PS.SetValue(MFPKEY_WMAAECMA_DEVICE_INDEXES, pv);
        if (SUCCEEDED(dsRes)) then begin
          //
          // now set features
          pv.vt := VT_BOOL;
          pv.boolVal := TOleBool(VARIANT_BOOL(-1));
          f_PS.SetValue(MFPKEY_WMAAECMA_FEATURE_MODE, pv);
          //
          // NS
          pv.vt := VT_I4;
          pv.lVal := choice(enableNS, 1, int(0));
          f_PS.SetValue(MFPKEY_WMAAECMA_FEATR_NS, pv);
          f_PS.GetValue(MFPKEY_WMAAECMA_FEATR_NS, pv);
          enableNS := (1 = pv.lVal);
          //
          // AGC
          pv.vt := VT_BOOL;
          if (enableAGC) then
            pv.boolVal := TOleBool(VARIANT_BOOL(-1))
          else
            pv.boolVal := TOleBool(VARIANT_BOOL(0));
          //
          f_PS.SetValue(MFPKEY_WMAAECMA_FEATR_AGC, pv);
          f_PS.GetValue(MFPKEY_WMAAECMA_FEATR_AGC, pv);
          enableAGC := pv.boolVal;
          //
          // VAD
          pv.vt := VT_I4;
          pv.lVal := choice(enableVAD, choice(enableAGC, AEC_VAD_FOR_AGC, int(AEC_VAD_NORMAL)), int(AEC_VAD_DISABLED));
          f_PS.SetValue(MFPKEY_WMAAECMA_FEATR_VAD, pv);
          f_PS.GetValue(MFPKEY_WMAAECMA_FEATR_VAD, pv);
          enableVAD := (AEC_VAD_DISABLED <> pv.lVal);
          //
          f_dsRes := MoInitMediaType(mt, sizeof(WAVEFORMATEX));
          try
            mt.majortype := MEDIATYPE_Audio;
            mt.subtype := MEDIASUBTYPE_PCM;
            mt.lSampleSize := pcmFormatExt.format.nChannels * pcmFormatExt.format.wBitsPerSample shr 3;
            mt.bFixedSizeSamples := TRUE;
            mt.bTemporalCompression := FALSE;
            mt.formattype := FORMAT_WaveFormatEx;
            waveExt2wave(pcmFormatExt, capBuf.lpwfxFormat);
            try
              move(capBuf.lpwfxFormat^, mt.pbFormat^, sizeof(WAVEFORMATEX));
            finally
              mrealloc(capBuf.lpwfxFormat);
            end;
            //
            f_dsRes := f_DMO.SetOutputType(0, mt, 0);
          finally
            MoFreeMediaType(mt);
          end;
          //
          if (SUCCEEDED(f_dsRes)) then begin
            //
            // allocate resources
            f_dsRes := f_DMO.AllocateStreamingResources();
            //
            // get frame size
            f_dsRes := f_PS.GetValue(MFPKEY_WMAAECMA_FEATR_FRAME_SIZE, pv);
            f_dmoFrameSize := pv.lVal;
            //
            // we still need rendering device, so let create one
            f_dsRes := unaDirectSoundCreate(getDevGUID(false), f_idsren);
            if (SUCCEEDED(f_dsRes)) then begin
              //
              f_dsRes := f_idsren.SetCooperativeLevel(f_appHandle, DSSCL_EXCLUSIVE);
              //
              // describe rendering buffer
              fillChar(renBuf, sizeOf(renBuf), #0);
              renBuf.dwSize := sizeOf(renBuf);
              renBuf.dwFlags := DSBCAPS_GLOBALFOCUS;//DSBCAPS_PRIMARYBUFFER;
              renBuf.dwBufferBytes := pcmFormatExt.format.nAvgBytesPerSec;        // must be 0 for primary buffer
              waveExt2wave(pcmFormatExt, renBuf.lpwfxFormat); // renBuf.lpwfxFormat must be NULL for primary buf
              try
                renBuf.guid3DAlgorithm := DS3DALG_DEFAULT;
                //
                f_dsRes := f_idsren.CreateSoundBuffer(renBuf, f_idsrenbuffer, nil);
                if (SUCCEEDED(f_dsRes)) then begin
                  //
                  // f_dsRes := f_dsrenbuf.QueryInterface(IDirectSoundBuffer8, f_idsRenBuf);    // does not work :(
                  //
                  fillchar(caps, sizeof(DSBCAPS), #0);
                  caps.dwSize := sizeof(DSBCAPS);
                  //
                  f_dsRes := f_idsrenbuffer.GetCaps(caps);
                  if (SUCCEEDED(f_dsRes)) then
                    f_maxRenOfs := caps.dwBufferBytes
                  else
                    f_maxRenOfs := renBuf.dwBufferBytes;
                  //
                end;
              finally
                mrealloc(renBuf.lpwfxFormat);
              end;
            end;
            //
            // allocate buffers
            f_outBuf := tMediaBuffer.create(pcmFormatExt.format.nAvgBytesPerSec);
            //
            f_outBuffers.pBuffer := f_outBuf;
            f_outBuffers.dwStatus := 0;
            //
            //f_dsRes := f_DMO.QueryInterface(IID_IMediaObjectInPlace, f_OInP);   // this will not work
            //
            if (SUCCEEDED(f_idsrenbuffer.GetCurrentPosition(@play, @write))) then
              f_renOfs := write;
            //
            f_dsRes := f_idsrenbuffer.play(0, 0, DSBPLAY_LOOPING);
            if (HRESULT(DSERR_BUFFERLOST) = f_dsRes) then
              f_dsRes := 0;	// will restore later
            //
            f_mtRen.start();      // start rendering thread
            f_mtCap.start();      // start capture thread
          end;
        end;
      end;
    end;
  end;
  //
  if (not SUCCEEDED(dsRes)) then begin
    //
    f_DMO := nil;
    f_PS := nil;
    //
    if (enableAEC) then begin
      //
      fillChar(f_capEft, sizeOf(f_capEft), #0);
      f_capEft.dwSize := sizeOf(f_capEft);
      f_capEft.dwFlags := DSCFX_LOCSOFTWARE;
      f_capEft.guidDSCFXClass := GUID_DSCFX_CLASS_AEC;
      f_capEft.guidDSCFXInstance := GUID_DSCFX_MS_AEC;
    end;
    //
    // describe capture buffer
    fillChar(capBuf, sizeof(capBuf), #0);
    capBuf.dwSize := sizeof(capBuf);
    capBuf.dwBufferBytes := pcmFormatExt.format.nAvgBytesPerSec;	// 1 second buffer
    f_bytesPerCapChunk := capBuf.dwBufferBytes div c_unaDSFD_cps;
    //
    waveExt2wave(pcmFormatExt, capBuf.lpwfxFormat);
    try
      //
      if (enableAEC) then begin
        //
        capBuf.dwFlags := DSCBCAPS_CTRLFX;
        capBuf.dwFXCount := 1;
        capBuf.lpDSCFXDesc := @f_capEft;
      end
      else begin
        //
        capBuf.dwFlags := 0;
        capBuf.dwFXCount := 0;
        capBuf.lpDSCFXDesc := nil;
      end;
      //
      // describe rendering buffer
      fillChar(renBuf, sizeOf(renBuf), #0);
      renBuf.dwSize := sizeOf(renBuf);
      renBuf.dwFlags := DSBCAPS_CTRLFX or DSBCAPS_GLOBALFOCUS;
      renBuf.dwBufferBytes := pcmFormatExt.format.nAvgBytesPerSec; // 1 second buffer
      f_maxRenOfs := renBuf.dwBufferBytes;
      //
      waveExt2wave(pcmFormatExt, renBuf.lpwfxFormat);
      try
        renBuf.guid3DAlgorithm := DS3DALG_DEFAULT;
        //
        f_dsRes := unadsFullDuplexCreate(
          getDevGUID(true),	// capture device
          getDevGUID(false),	// render device
          capBuf,			// capture buffer
          renBuf,			// render buffer
          f_appHandle,		// app handle
          DSSCL_EXCLUSIVE,		// cooperative level
          f_idsfd,
          f_idsCapBuf,
          f_idsRenBuf
        );
      finally
        mrealloc(renBuf.lpwfxFormat);
      end;
      //
      if (Succeeded(dsRes)) then begin
        //
        // init notifications array
        ofs := 0;
        for i := 0 to c_unaDSFD_cps - 1 do begin
          //
          inc(ofs, f_bytesPerCapChunk);
          //
          f_nvCap[i] := CreateEvent(nil, false, false, nil);	// for capture buffer
          //f_nvRen[i] := CreateEvent(nil, false, false, nil);	// for rendering buffer
          //
          rgdsbpn[i].dwOffset := ofs - 1;
        end;
        //
        // obtain notification inetrface on capture buffer
        f_dsRes := f_idsCapBuf.QueryInterface(IID_IDirectSoundNotify8, lpDsNotify);
        try
          if (Succeeded(dsRes)) then begin
            //
            for i := 0 to c_unaDSFD_cps - 1 do
              rgdsbpn[i].hEventNotify := f_nvCap[i];
            //
            // and set notifications
            f_dsRes := lpDsNotify.setNotificationPositions(c_unaDSFD_cps, pointer(@rgdsbpn));
          end;
        finally
          lpDsNotify := nil;
        end;
        //
        // obtain notification inetrface on render buffer
        // NOTE: ren buffer not always support notifications, so we need some other way
        //
        {
        f_dsRes := f_idsRenBuf.QueryInterface(IID_IDirectSoundNotify, lpDsNotify);
        try
          if (Succeeded(dsRes)) then begin
            //
            for i := 0 to c_unaDSFD_cps - 1 do
              rgdsbpn[i].hEventNotify := f_nvRen[i];
            //
            // and set notifications
            f_dsRes := lpDsNotify.setNotificationPositions(c_unaDSFD_cps, pointer(@rgdsbpn));
          end;
        finally
          lpDsNotify := nil;
        end;
        }
        //
        if (Succeeded(dsRes)) then begin
          //
          f_dsRes := f_idsCapBuf.start(DSCBSTART_LOOPING);
          if (Succeeded(dsRes)) then begin
            //
            f_dsRes := f_idsRenBuf.play(0, 0, DSBPLAY_LOOPING);
            if (HRESULT(DSERR_BUFFERLOST) = f_dsRes) then
              f_dsRes := 0;	// will restore later
          end;
        end;
        //
        if (Succeeded(dsRes)) then begin
          //
          if (SUCCEEDED(f_idsRenBuf.GetCurrentPosition(@play, @write))) then
            f_renOfs := write;
          //
          f_mtRen.start();      // start rendering thread
          f_mtCap.start();      // start capture thread
        end
        else
          releaseDS();	// fail out
      end;
      //
    finally
      mrealloc(capBuf.lpwfxFormat);
    end;
  end;
end;

// --  --
function TunavclDX_FullDuplex.isActive(): bool;
begin
  result := (unatsRunning = f_mtCap.status) or assigned(f_DMO);
end;

// --  --
procedure TunavclDX_FullDuplex.releaseDS();
var
  i: int;
begin
  f_mtCap.stop();
  f_mtRen.stop();
  //
  if (assigned(f_DMO)) then begin
    //
    f_idsrenbuffer.stop();
    //
    f_idsrenbuffer := nil;
    f_idsren := nil;
    f_PS := nil;
    f_DMO := nil;
    //
    f_outBuffers.pBuffer := nil;
    f_outBuf._Release();
    f_outBuf := nil;
    //
    CoUninitialize();
  end;
  //
  if (assigned(f_idsfd)) then begin
    //
    f_idsCapBuf.stop();
    f_idsRenBuf.stop();
    //
    for i := 0 to c_unaDSFD_cps - 1 do begin
      //
      CloseHandle(f_nvCap[i]);
      //CloseHandle(f_nvRen[i]);
    end;
    //
    f_idsCapBuf := nil;
    f_idsRenBuf := nil;
    f_idsfd := nil;
    //
    CoUninitialize();
  end;
  //
  f_capIsOK := false;
end;

//
// -- IDE --
//
procedure Register();
begin
  RegisterComponents(c_VC_reg_DSP_section_name, [
    TunavclDX_FullDuplex
  ]);
end;


end.

