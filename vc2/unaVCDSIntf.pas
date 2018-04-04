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

	  unaVCDSIntf.pas - VC 2.5 Pro DS interface
	  Voice Communicator components version 2.5 Pro

	----------------------------------------------
	  Copyright (c) 2007-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 27 Sep 2007

	  modified by:
		Lake, Sep 2007

	----------------------------------------------
*)

{$I unaDef.inc}

{*
	DS interfaces
}

unit
  unaVCDSIntf;

interface

uses
  Windows, ActiveX, MMSystem,
  unaTypes, unaClasses;

const
  //
  c_directSoundDll = 'DSOUND.DLL';
  c_dmoDll         = 'MSDMO.DLL';

  //
  DSERR_BUFFERLOST = integer($88780096);

  //
  {$EXTERNALSYM DSBCAPS_PRIMARYBUFFER }
  DSBCAPS_PRIMARYBUFFER       = $00000001;
  {$EXTERNALSYM DSBCAPS_STATIC }
  DSBCAPS_STATIC              = $00000002;
  {$EXTERNALSYM DSBCAPS_LOCHARDWARE }
  DSBCAPS_LOCHARDWARE         = $00000004;
  {$EXTERNALSYM DSBCAPS_LOCSOFTWARE }
  DSBCAPS_LOCSOFTWARE         = $00000008;
  {$EXTERNALSYM DSBCAPS_CTRL3D }
  DSBCAPS_CTRL3D              = $00000010;
  {$EXTERNALSYM DSBCAPS_CTRLFREQUENCY }
  DSBCAPS_CTRLFREQUENCY       = $00000020;
  {$EXTERNALSYM DSBCAPS_CTRLPAN }
  DSBCAPS_CTRLPAN             = $00000040;
  {$EXTERNALSYM DSBCAPS_CTRLVOLUME }
  DSBCAPS_CTRLVOLUME          = $00000080;
  {$EXTERNALSYM DSBCAPS_CTRLPOSITIONNOTIFY }
  DSBCAPS_CTRLPOSITIONNOTIFY  = $00000100;
  {$EXTERNALSYM DSBCAPS_CTRLFX }
  DSBCAPS_CTRLFX              = $00000200;
  {$EXTERNALSYM DSBCAPS_STICKYFOCUS }
  DSBCAPS_STICKYFOCUS         = $00004000;
  {$EXTERNALSYM DSBCAPS_GLOBALFOCUS }
  DSBCAPS_GLOBALFOCUS         = $00008000;
  {$EXTERNALSYM DSBCAPS_GETCURRENTPOSITION2 }
  DSBCAPS_GETCURRENTPOSITION2 = $00010000;
  {$EXTERNALSYM DSBCAPS_MUTE3DATMAXDISTANCE }
  DSBCAPS_MUTE3DATMAXDISTANCE = $00020000;
  {$EXTERNALSYM DSBCAPS_LOCDEFER }
  DSBCAPS_LOCDEFER            = $00040000;

  // lock
  {$EXTERNALSYM DSCBLOCK_ENTIREBUFFER }
  DSCBLOCK_ENTIREBUFFER       = $00000001;
  // status
  {$EXTERNALSYM DSCBSTATUS_CAPTURING }
  DSCBSTATUS_CAPTURING        = $00000001;
  {$EXTERNALSYM DSCBSTATUS_LOOPING }
  DSCBSTATUS_LOOPING          = $00000002;
  // capture
  {$EXTERNALSYM DSCBSTART_LOOPING }
  DSCBSTART_LOOPING           = $00000001;
  // BPN
  {$EXTERNALSYM DSBPN_OFFSETSTOP }
  DSBPN_OFFSETSTOP            = $FFFFFFFF;
  // cert
  {$EXTERNALSYM DS_CERTIFIED }
  DS_CERTIFIED                = $00000000;
  {$EXTERNALSYM DS_UNCERTIFIED }
  DS_UNCERTIFIED              = $00000001;

  //
  {$EXTERNALSYM DSBPLAY_LOOPING }
  DSBPLAY_LOOPING             = $00000001;
  {$EXTERNALSYM DSBPLAY_LOCHARDWARE }
  DSBPLAY_LOCHARDWARE         = $00000002;
  {$EXTERNALSYM DSBPLAY_LOCSOFTWARE }
  DSBPLAY_LOCSOFTWARE         = $00000004;
  {$EXTERNALSYM DSBPLAY_TERMINATEBY_TIME }
  DSBPLAY_TERMINATEBY_TIME    = $00000008;
  {$EXTERNALSYM DSBPLAY_TERMINATEBY_DISTANCE }
  DSBPLAY_TERMINATEBY_DISTANCE    = $000000010;
  {$EXTERNALSYM DSBPLAY_TERMINATEBY_PRIORITY }
  DSBPLAY_TERMINATEBY_PRIORITY    = $000000020;

  //
  {$EXTERNALSYM DSCBCAPS_WAVEMAPPED }
  DSCBCAPS_WAVEMAPPED         = $80000000;
  {$EXTERNALSYM DSCBCAPS_CTRLFX }
  DSCBCAPS_CTRLFX             = $00000200;

  //
  {$EXTERNALSYM DSBLOCK_FROMWRITECURSOR }
  DSBLOCK_FROMWRITECURSOR     = $00000001;
  {$EXTERNALSYM DSBLOCK_ENTIREBUFFER }
  DSBLOCK_ENTIREBUFFER        = $00000002;

  {$EXTERNALSYM DSCFX_LOCHARDWARE }
  DSCFX_LOCHARDWARE   = $00000001;
  {$EXTERNALSYM DSCFX_LOCSOFTWARE }
  DSCFX_LOCSOFTWARE   = $00000002;
  {$EXTERNALSYM DSCFXR_LOCHARDWARE }
  DSCFXR_LOCHARDWARE  = $00000010;
  {$EXTERNALSYM DSCFXR_LOCSOFTWARE }
  DSCFXR_LOCSOFTWARE  = $00000020;

  //
  {$EXTERNALSYM DSSCL_NORMAL }
  DSSCL_NORMAL                = $00000001;
  {$EXTERNALSYM DSSCL_PRIORITY }
  DSSCL_PRIORITY              = $00000002;
  {$EXTERNALSYM DSSCL_EXCLUSIVE }
  DSSCL_EXCLUSIVE             = $00000003;
  {$EXTERNALSYM DSSCL_WRITEPRIMARY }
  DSSCL_WRITEPRIMARY          = $00000004;


  // These match the AEC_MODE_* constants in the DDK's ksmedia.h file
  {$EXTERNALSYM DSCFX_AEC_MODE_PASS_THROUGH }
  DSCFX_AEC_MODE_PASS_THROUGH                     = $0;
  {$EXTERNALSYM DSCFX_AEC_MODE_HALF_DUPLEX }
  DSCFX_AEC_MODE_HALF_DUPLEX                      = $1;
  {$EXTERNALSYM DSCFX_AEC_MODE_FULL_DUPLEX }
  DSCFX_AEC_MODE_FULL_DUPLEX                      = $2;

  // These match the AEC_STATUS_* constants in ksmedia.h
  {$EXTERNALSYM DSCFX_AEC_STATUS_HISTORY_UNINITIALIZED }
  DSCFX_AEC_STATUS_HISTORY_UNINITIALIZED          = $0;
  {$EXTERNALSYM DSCFX_AEC_STATUS_HISTORY_CONTINUOUSLY_CONVERGED }
  DSCFX_AEC_STATUS_HISTORY_CONTINUOUSLY_CONVERGED = $1;
  {$EXTERNALSYM DSCFX_AEC_STATUS_HISTORY_PREVIOUSLY_DIVERGED }
  DSCFX_AEC_STATUS_HISTORY_PREVIOUSLY_DIVERGED    = $2;
  {$EXTERNALSYM DSCFX_AEC_STATUS_CURRENTLY_CONVERGED }
  DSCFX_AEC_STATUS_CURRENTLY_CONVERGED            = $8;


  //
  // Acoustic Echo Canceller

  // Matches KSNODETYPE_ACOUSTIC_ECHO_CANCEL in ksmedia.h
  {$EXTERNALSYM GUID_DSCFX_CLASS_AEC }
  GUID_DSCFX_CLASS_AEC: TGUID = '{BF963D80-C559-11D0-8A2B-00A0C9255AC1}';

  // Microsoft AEC
  {$EXTERNALSYM GUID_DSCFX_MS_AEC }
  GUID_DSCFX_MS_AEC: TGUID = '{cdebb919-379a-488a-8765-f53cfd36de40}';

  // System AEC
  {$EXTERNALSYM GUID_DSCFX_SYSTEM_AEC }
  GUID_DSCFX_SYSTEM_AEC: TGUID = '{1c22c56d-9879-4f5b-a389-27996ddc2810}';

  //
  // Noise Supression

  // Matches KSNODETYPE_NOISE_SUPPRESS in post Windows ME DDK's ksmedia.h
  {$EXTERNALSYM GUID_DSCFX_CLASS_NS }
  GUID_DSCFX_CLASS_NS: TGUID = '{e07f903f-62fd-4e60-8cdd-dea7236665b5}';

  // Microsoft Noise Suppresion
  {$EXTERNALSYM GUID_DSCFX_MS_NS }
  GUID_DSCFX_MS_NS: TGUID = '{11c5c73b-66e9-4ba1-a0ba-e814c6eed92d}';

  // System Noise Suppresion
  {$EXTERNALSYM GUID_DSCFX_SYSTEM_NS }
  GUID_DSCFX_SYSTEM_NS: TGUID = '{5ab0882e-7274-4516-877d-4eee99ba4fd0}';


  //
  // DirectSound3D Algorithms
  //
  // Default DirectSound3D algorithm
  {$EXTERNALSYM DS3DALG_DEFAULT }
  DS3DALG_DEFAULT: TGUID = '{00000000-0000-0000-0000-000000000000}';

  // No virtualization (Pan3D)
  {$EXTERNALSYM DS3DALG_NO_VIRTUALIZATION }
  DS3DALG_NO_VIRTUALIZATION: TGUID = '{c241333f-1c1b-11d2-94f5-00c04fc28aca}';

  // High-quality HRTF algorithm
  {$EXTERNALSYM DS3DALG_HRTF_FULL }
  DS3DALG_HRTF_FULL: TGUID = '{c2413340-1c1b-11d2-94f5-00c04fc28aca}';

  // Lower-quality HRTF algorithm
  {$EXTERNALSYM DS3DALG_HRTF_LIGHT }
  DS3DALG_HRTF_LIGHT: TGUID = '{c2413342-1c1b-11d2-94f5-00c04fc28aca}';


  // DirectSound default device for voice capture
  {$EXTERNALSYM DSDEVID_DefaultVoiceCapture }
  DSDEVID_DefaultVoiceCapture: TGUID = '{def00003-9c6d-47ed-aaf1-4dda8f2b5c03}';
  //
  // DirectSound default device for voice playback
  {$EXTERNALSYM DSDEVID_DefaultVoicePlayback }
  DSDEVID_DefaultVoicePlayback: TGUID = '{def00002-9c6d-47ed-aaf1-4dda8f2b5c03}';


type
  //
  {$EXTERNALSYM INT_PTR }
  {$EXTERNALSYM UINT_PTR }
  {$EXTERNALSYM LONG_PTR }
  {$EXTERNALSYM ULONG_PTR }
  {$EXTERNALSYM DWORD_PTR }
  INT_PTR = integer;
  UINT_PTR = cardinal;
  LONG_PTR = Longint;
  ULONG_PTR = Longword;
  DWORD_PTR = ULONG_PTR;

  //
  {$EXTERNALSYM DSCAPS }
  DSCAPS = packed record
    dwSize                         : DWORD;
    dwFlags                        : DWORD;
    dwMinSecondarySampleRate       : DWORD;
    dwMaxSecondarySampleRate       : DWORD;
    dwPrimaryBuffers               : DWORD;
    dwMaxHwMixingAllBuffers        : DWORD;
    dwMaxHwMixingStaticBuffers     : DWORD;
    dwMaxHwMixingStreamingBuffers  : DWORD;
    dwFreeHwMixingAllBuffers       : DWORD;
    dwFreeHwMixingStaticBuffers    : DWORD;
    dwFreeHwMixingStreamingBuffers : DWORD;
    dwMaxHw3DAllBuffers            : DWORD;
    dwMaxHw3DStaticBuffers         : DWORD;
    dwMaxHw3DStreamingBuffers      : DWORD;
    dwFreeHw3DAllBuffers           : DWORD;
    dwFreeHw3DStaticBuffers        : DWORD;
    dwFreeHw3DStreamingBuffers     : DWORD;
    dwTotalHwMemBytes              : DWORD;
    dwFreeHwMemBytes               : DWORD;
    dwMaxContigFreeHwMemBytes      : DWORD;
    dwUnlockTransferRateHwBuffers  : DWORD;
    dwPlayCpuOverheadSwBuffers     : DWORD;
    dwReserved1                    : DWORD;
    dwReserved2                    : DWORD;
  end;
  TDSCaps = DSCAPS;
  PDSCaps = ^TDSCaps;

  //
  {$EXTERNALSYM DSBUFFERDESC }
  DSBUFFERDESC = packed record
    dwSize: DWORD;
    dwFlags: DWORD;
    dwBufferBytes: DWORD;
    dwReserved: DWORD;
    lpwfxFormat: PWaveFormatEx;
    guid3DAlgorithm: TGUID;
  end;
  TDSBufferDesc = DSBUFFERDESC;
  PDSBufferDesc = ^TDSBufferDesc;

  //
  {$EXTERNALSYM DSCEFFECTDESC }
  DSCEFFECTDESC = packed record
    dwSize: DWORD;
    dwFlags: DWORD;
    guidDSCFXClass: TGUID;
    guidDSCFXInstance: TGUID;
    dwReserved1: DWORD;
    dwReserved2: DWORD;
  end;
  TDSCEffectDesc = DSCEFFECTDESC;
  PDSCEffectDesc = ^TDSCEffectDesc;

  //
  {$EXTERNALSYM DSCBUFFERDESC }
  DSCBUFFERDESC = packed record
    dwSize: DWORD;
    dwFlags: DWORD;
    dwBufferBytes: DWORD;
    dwReserved: DWORD;
    lpwfxFormat: PWaveFormatEx;
    dwFXCount: DWORD;
    lpDSCFXDesc: PDSCEffectDesc;
  end;
  TDSCBufferDesc = DSCBUFFERDESC;
  PDSCBufferDesc = ^TDSCBufferDesc;

  //
  {$EXTERNALSYM DSBCAPS }
  DSBCAPS = packed record
    dwSize                : DWORD;
    dwFlags               : DWORD;
    dwBufferBytes         : DWORD;
    dwUnlockTransferRate  : DWORD;
    dwPlayCpuOverhead     : DWORD;
  end;
  TDSBcaps = DSBCAPS;
  PDSBcaps = ^TDSBcaps;

  //
  {$EXTERNALSYM DSCCAPS }
  DSCCAPS = packed record
    dwSize: DWORD;
    dwFlags: DWORD;
    dwFormats: DWORD;
    dwChannels: DWORD;
  end;
  TDSCcaps = DSCCAPS;
  PDSCcaps = ^TDSCcaps;

  //
  {$EXTERNALSYM DSCBCAPS }
  DSCBCAPS = packed record
    dwSize: DWORD;
    dwFlags: DWORD;
    dwBufferBytes: DWORD;
    dwReserved: DWORD;
  end;
  TDSCBCaps = DSCBCAPS;
  PDSCBCaps = ^TDSCBCaps;

  //
  {$EXTERNALSYM DSEFFECTDESC }
  DSEFFECTDESC = packed record
    dwSize        : DWORD;
    dwFlags       : DWORD;
    guidDSFXClass : TGUID;
    dwReserved1   : DWORD_PTR;
    dwReserved2   : DWORD_PTR;
  end;
  TDSEffectDesc = DSEFFECTDESC;
  PDSEffectDesc = ^TDSEffectDesc;

  //
  {$EXTERNALSYM DSBPOSITIONNOTIFY }
  DSBPOSITIONNOTIFY = packed record
    dwOffset: DWORD;
    hEventNotify: THandle;
  end;
  TDSBPositionNotify = DSBPOSITIONNOTIFY;
  PDSBPositionNotify = ^TDSBPositionNotify;

  //
  {$EXTERNALSYM DSCFXAec }
  DSCFXAec = packed record
    fEnable: BOOL;
    fNoiseFill: BOOL;
    dwMode: DWORD;
  end;
  TDSCFXAec = DSCFXAec;
  PDSCFXAec = ^TDSCFXAec;

  {$EXTERNALSYM AecQualityMetrics_Struct }
  pAecQualityMetrics_Struct = ^AecQualityMetrics_Struct;
  AecQualityMetrics_Struct = packed record
    //
    i64Timestamp: LONGLONG;
    ConvergenceFlag: byte;
    MicClippedFlag: byte;
    MicSilenceFlag: byte;
    PstvFeadbackFlag: byte;
    SpkClippedFlag: byte;
    SpkMuteFlag: byte;
    GlitchFlag: byte;
    DoubleTalkFlag: byte;
    uGlitchCount: ULONG;
    uMicClipCount: ULONG;
    fDuration: float;
    fTSVariance: float;
    fTSDriftRate: float;
    fVoiceLevel: float;
    fNoiseLevel: float;
    fERLE: float;
    fAvgERLE: float;
    dwReserved: DWORD;
  end;


  // -- -- -- interfaces -- -- --


  // forward reference
  IDirectSoundBuffer = interface;
  IDirectSoundCaptureBuffer = interface;


  //
  // IDirectSound
  //
  {$HPPEMIT 'DECLARE_DINTERFACE_TYPE(IDirectSound);' }
  {$EXTERNALSYM IDirectSound }
  IDirectSound = interface(IUnknown)
    ['{279AFA83-4981-11CE-A521-0020AF0BE560}']
    // IDirectSound methods
    function CreateSoundBuffer(const pcDSBufferDesc: TDSBufferDesc; out ppDSBuffer: IDirectSoundBuffer; pUnkOuter: IUnknown): HResult; stdcall;
    function GetCaps(out pDSCaps: TDSCaps): HResult; stdcall;
    function DuplicateSoundBuffer(pDSBufferOriginal: IDirectSoundBuffer; out ppDSBufferDuplicate: IDirectSoundBuffer): HResult; stdcall;
    function SetCooperativeLevel(hwnd: HWND; dwLevel: DWORD): HResult; stdcall;
    function Compact: HResult; stdcall;
    function GetSpeakerConfig(out pdwSpeakerConfig: DWORD): HResult; stdcall;
    function SetSpeakerConfig(dwSpeakerConfig: DWORD): HResult; stdcall;
    function Initialize(pcGuidDevice: PGUID): HResult; stdcall;
  end;
  {$EXTERNALSYM IID_IDirectSound}
  IID_IDirectSound = IDirectSound;

  {$HPPEMIT 'DECLARE_DINTERFACE_TYPE(IDirectSound8);' }
  {$EXTERNALSYM IDirectSound8 }
  IDirectSound8 = interface(IDirectSound)
    ['{C50A7E93-F395-4834-9EF6-7FA99DE50966}']
    // IDirectSound8 methods
    function VerifyCertification(pdwCertified: PDWORD): HResult; stdcall;
  end;
  {$EXTERNALSYM IID_IDirectSound8 }
  IID_IDirectSound8 = IDirectSound8;


  //
  // IDirectSoundCapture
  //
  {$HPPEMIT 'DECLARE_DINTERFACE_TYPE(IDirectSoundCapture);' }
  {$EXTERNALSYM IDirectSoundCapture }
  IDirectSoundCapture = interface(IUnknown)
    ['{b0210781-89cd-11d0-af08-00a0c925cd16}']
    // IDirectSoundCapture methods
    function CreateCaptureBuffer(const pcDSCBufferDesc: TDSCBufferDesc; out ppDSCBuffer: IDirectSoundCaptureBuffer; pUnkOuter: IUnknown): HResult; stdcall;
    function GetCaps(var pDSCCaps: TDSCcaps): HResult; stdcall;
    function Initialize(pcGuidDevice: PGUID): HResult; stdcall;
  end;
  {$EXTERNALSYM IID_IDirectSoundCapture }
  IID_IDirectSoundCapture = IDirectSoundCapture;


  {$IFDEF __BEFORE_D6__ }
  PPointer = ^pointer;
  {$ENDIF __BEFORE_D6__ }


  //
  // IDirectSoundBuffer
  //
  {$HPPEMIT 'DECLARE_DINTERFACE_TYPE(IDirectSoundBuffer);' }
  {$EXTERNALSYM IDirectSoundBuffer }
  IDirectSoundBuffer = interface(IUnknown)
    ['{279AFA85-4981-11CE-A521-0020AF0BE560}']
    // IDirectSoundBuffer methods
    function GetCaps(var pDSBufferCaps: TDSBcaps): HResult; stdcall;
    function GetCurrentPosition(pdwCurrentPlayCursor, pdwCurrentWriteCursor: PDWORD): HResult; stdcall;
    function GetFormat(pwfxFormat: PWaveFormatEx; dwSizeAllocated: DWORD; pdwSizeWritten: PDWORD): HResult; stdcall;
    function GetVolume(out plVolume: Longint): HResult; stdcall;
    function GetPan(out plPan: Longint): HResult; stdcall;
    function GetFrequency(out pdwFrequency: DWORD): HResult; stdcall;
    function GetStatus(out pdwStatus: DWORD): HResult; stdcall;
    function Initialize(pDirectSound: IDirectSound; const pcDSBufferDesc: TDSBufferDesc): HResult; stdcall;
    function Lock(dwOffset, dwBytes: DWORD; ppvAudioPtr1: PPointer; pdwAudioBytes1: PDWORD; ppvAudioPtr2: PPointer; pdwAudioBytes2: PDWORD; dwFlags: DWORD): HResult; stdcall;
    function Play(dwReserved1, dwPriority, dwFlags: DWORD): HResult; stdcall;
    function SetCurrentPosition(dwNewPosition: DWORD): HResult; stdcall;
    function SetFormat(pcfxFormat: PWaveFormatEx): HResult; stdcall;
    function SetVolume(lVolume: Longint): HResult; stdcall;
    function SetPan(lPan: Longint): HResult; stdcall;
    function SetFrequency(dwFrequency: DWORD): HResult; stdcall;
    function Stop: HResult; stdcall;
    function Unlock(pvAudioPtr1: Pointer; dwAudioBytes1: DWORD; pvAudioPtr2: Pointer; dwAudioBytes2: DWORD): HResult; stdcall;
    function Restore: HResult; stdcall;
  end;
  {$EXTERNALSYM IID_IDirectSoundBuffer }
  IID_IDirectSoundBuffer = IDirectSoundBuffer;


  //
  // IDirectSoundCaptureBuffer
  //
  {$HPPEMIT 'DECLARE_DINTERFACE_TYPE(IDirectSoundCaptureBuffer);' }
  {$EXTERNALSYM IDirectSoundCaptureBuffer }
  IDirectSoundCaptureBuffer = interface(IUnknown)
    ['{b0210782-89cd-11d0-af08-00a0c925cd16}']
    // IDirectSoundCaptureBuffer methods
    function GetCaps(var pDSCBCaps: TDSCBCaps): HResult; stdcall;
    function GetCurrentPosition(pdwCapturePosition, pdwReadPosition: PDWORD): HResult; stdcall;
    function GetFormat(pwfxFormat: PWaveFormatEx; dwSizeAllocated: DWORD; pdwSizeWritten: PDWORD): HResult; stdcall;
    function GetStatus(pdwStatus: PDWORD): HResult; stdcall;
    function Initialize(pDirectSoundCapture: IDirectSoundCapture; const pcDSCBufferDesc: TDSCBufferDesc): HResult; stdcall;
    function Lock(dwOffset, dwBytes: DWORD; ppvAudioPtr1: PPointer; pdwAudioBytes1: PDWORD; ppvAudioPtr2: PPointer; pdwAudioBytes2: PDWORD; dwFlags: DWORD): HResult; stdcall;
    function Start(dwFlags: DWORD): HResult; stdcall;
    function Stop: HResult; stdcall;
    function Unlock(pvAudioPtr1: Pointer; dwAudioBytes1: DWORD; pvAudioPtr2: Pointer; dwAudioBytes2: DWORD): HResult; stdcall;
  end;
  {$EXTERNALSYM IID_IDirectSoundCaptureBuffer }
  IID_IDirectSoundCaptureBuffer = IDirectSoundCaptureBuffer;


  //
  // IDirectSoundCaptureBuffer8
  //
  {$HPPEMIT 'DECLARE_DINTERFACE_TYPE(IDirectSoundCaptureBuffer8);' }
  {$EXTERNALSYM IDirectSoundCaptureBuffer8 }
  IDirectSoundCaptureBuffer8 = interface(IDirectSoundCaptureBuffer)
    ['{00990df4-0dbb-4872-833e-6d303e80aeb6}']
    // IDirectSoundCaptureBuffer8 methods
    function GetObjectInPath(const rguidObject: TGUID; dwIndex: DWORD; const rguidInterface: TGUID; out ppObject{IUnknown}): HResult; stdcall;
    function GetFXStatus(dwFXCount: DWORD; pdwFXStatus: PDWORD): HResult; stdcall;
  end;
  {$EXTERNALSYM IID_IDirectSoundCaptureBuffer8 }
  IID_IDirectSoundCaptureBuffer8 = IDirectSoundCaptureBuffer8;


  //
  // IDirectSoundBuffer8
  //
  {$HPPEMIT 'DECLARE_DINTERFACE_TYPE(IDirectSoundBuffer8);' }
  {$EXTERNALSYM IDirectSoundBuffer8 }
  IDirectSoundBuffer8 = interface(IDirectSoundBuffer)
    ['{6825a449-7524-4d82-920f-50e36ab3ab1e}']
    // IDirectSoundBuffer8 methods
    function SetFX(dwEffectsCount: DWORD; pDSFXDesc: PDSEffectDesc; pdwResultCodes: PDWORD): HResult; stdcall;
    function AcquireResources(dwFlags, dwEffectsCount: DWORD; pdwResultCodes: PDWORD): HResult; stdcall;
    function GetObjectInPath(const rguidObject: TGUID; dwIndex: DWORD; const rguidInterface: TGUID; out ppObject{IUnknown}): HResult; stdcall;
  end;
  {$EXTERNALSYM IID_IDirectSoundBuffer8 }
  IID_IDirectSoundBuffer8 = IDirectSoundBuffer8;


  //
  // IDirectSoundFullDuplex
  //
  {$HPPEMIT 'DECLARE_DINTERFACE_TYPE(IDirectSoundFullDuplex);' }
  {$EXTERNALSYM IDirectSoundFullDuplex }
  IDirectSoundFullDuplex = interface(IUnknown)
    ['{edcb4c7a-daab-4216-a42e-6c50596ddc1d}']
    // IDirectSoundFullDuplex methods
    function Initialize(pCaptureGuid, pRenderGuid: PGUID; const lpDscBufferDesc: TDSCBufferDesc; const lpDsBufferDesc: TDSBufferDesc; hWnd: HWND; dwLevel: DWORD; out lplpDirectSoundCaptureBuffer8: IDirectSoundCaptureBuffer8; out lplpDirectSoundBuffer8: IDirectSoundBuffer8): HResult; stdcall;
  end;
  {$EXTERNALSYM IID_IDirectSoundFullDuplex }
  IID_IDirectSoundFullDuplex	= IDirectSoundFullDuplex;
  {$EXTERNALSYM IDirectSoundFullDuplex8 }
  IDirectSoundFullDuplex8       = IDirectSoundFullDuplex;


  //
  // IDirectSoundNotify
  //
  {$HPPEMIT 'DECLARE_DINTERFACE_TYPE(IDirectSoundNotify);' }
  {$EXTERNALSYM IDirectSoundNotify }
  IDirectSoundNotify = interface(IUnknown)
    ['{b0210783-89cd-11d0-af08-00a0c925cd16}']
    // IDirectSoundNotify methods
    function SetNotificationPositions(dwPositionNotifies: DWORD; pcPositionNotifies: PDSBPositionNotify): HResult; stdcall;
  end;
  {$EXTERNALSYM IID_IDirectSoundNotify }
  IID_IDirectSoundNotify	= IDirectSoundNotify;
  {$EXTERNALSYM IID_IDirectSoundNotify8 }
  IID_IDirectSoundNotify8       = IID_IDirectSoundNotify;
  {$EXTERNALSYM IDirectSoundNotify8 }
  IDirectSoundNotify8           = IDirectSoundNotify;


  {$HPPEMIT 'DECLARE_DINTERFACE_TYPE(IDirectSoundCaptureFXAec);' }
  {$EXTERNALSYM IDirectSoundCaptureFXAec }
  IDirectSoundCaptureFXAec = interface(IUnknown)
    ['{ad74143d-903d-4ab7-8066-28d363036d65}']
    // IDirectSoundCaptureFXAec methods
    function SetAllParameters(const pDscFxAec: TDSCFXAec): HResult; stdcall;
    function GetAllParameters(out pDscFxAec: TDSCFXAec): HResult; stdcall;
    function GetStatus(out pdwStatus: DWORD): HResult; stdcall;
    function Reset: HResult; stdcall;
  end;
  {$EXTERNALSYM IID_IDirectSoundCaptureFXAec }
  IID_IDirectSoundCaptureFXAec	= IDirectSoundCaptureFXAec;
  {$EXTERNALSYM IID_IDirectSoundCaptureFXAec8 }
  IID_IDirectSoundCaptureFXAec8	= IID_IDirectSoundCaptureFXAec;
  {$EXTERNALSYM IDirectSoundCaptureFXAec8 }
  IDirectSoundCaptureFXAec8	= IDirectSoundCaptureFXAec;


// DMOs

  {$EXTERNALSYM REFERENCE_TIME }
  REFERENCE_TIME = LONGLONG;

  {$EXTERNALSYM AM_MEDIA_TYPE }
  pAM_MEDIA_TYPE = ^AM_MEDIA_TYPE;
  AM_MEDIA_TYPE = packed record
    majortype            : TGUID;
    subtype              : TGUID;
    bFixedSizeSamples    : BOOL;
    bTemporalCompression : BOOL;
    lSampleSize          : ULONG;
    formattype           : TGUID;
    pUnk                 : IUnknown;
    cbFormat             : ULONG;
    pbFormat             : Pointer;
  end;

  {$EXTERNALSYM DMO_MEDIA_TYPE }
  pDMO_MEDIA_TYPE = ^DMO_MEDIA_TYPE;
  DMO_MEDIA_TYPE = AM_MEDIA_TYPE;

  {$HPPEMIT 'DECLARE_DINTERFACE_TYPE(IMediaBuffer);' }
  {$EXTERNALSYM IMediaBuffer }
  IMediaBuffer = interface(IUnknown)
    ['{59eff8b9-938c-4a26-82f2-95cb84cdc837}']
    (*** IMediaBuffer methods ***)
    function SetLength(cbLength: DWORD): HResult; stdcall;
    function GetMaxLength(out pcbMaxLength: DWORD): HResult; stdcall;
    function GetBufferAndLength(out ppBuffer: PByte; // not filled if NULL
                                out pcbLength: DWORD    // not filled if NULL
                                ): HResult; stdcall;
  end;
  {$EXTERNALSYM IMediaBuffer }
  IID_IMediaBuffer = IMediaBuffer;

  {$EXTERNALSYM DMO_OUTPUT_DATA_BUFFER }
  pDMO_OUTPUT_DATA_BUFFER = ^DMO_OUTPUT_DATA_BUFFER;
  DMO_OUTPUT_DATA_BUFFER = packed record
    pBuffer      : IMediaBuffer;    //
    dwStatus     : DWORD;           //
    rtTimestamp  : REFERENCE_TIME;  //
    rtTimelength : REFERENCE_TIME;  //
  end;


  {$HPPEMIT 'DECLARE_DINTERFACE_TYPE(IMediaObject);' }
  {$EXTERNALSYM IMediaObject }
  IMediaObject = interface(IUnknown)
    ['{d8ad0f58-5494-4102-97c5-ec798e59bcf4}']
    (*** IMediaObject methods ***)
    function GetStreamCount(out pcInputStreams, pcOutputStreams: DWORD): HResult; stdcall;
    function GetInputStreamInfo(dwInputStreamIndex: DWORD; out pdwFlags: DWORD): HResult; stdcall;
    function GetOutputStreamInfo(dwOutputStreamIndex: DWORD; out pdwFlags: DWORD): HResult; stdcall;
    function GetInputType(dwInputStreamIndex, dwTypeIndex: DWORD; out pmt: DMO_MEDIA_TYPE): HResult; stdcall;
    function GetOutputType(dwOutputStreamIndex, dwTypeIndex: DWORD; out pmt: DMO_MEDIA_TYPE): HResult; stdcall;
    function SetInputType(dwInputStreamIndex: DWORD; const pmt: DMO_MEDIA_TYPE; dwFlags: DWORD): HResult; stdcall;
    function SetOutputType(dwOutputStreamIndex: DWORD; const pmt: DMO_MEDIA_TYPE; dwFlags: DWORD): HResult; stdcall;
    function GetInputCurrentType(dwInputStreamIndex: DWORD; out pmt: DMO_MEDIA_TYPE): HResult; stdcall;
    function GetOutputCurrentType(dwOutputStreamIndex: DWORD; out pmt: DMO_MEDIA_TYPE): HResult; stdcall;
    function GetInputSizeInfo(dwInputStreamIndex: DWORD; out pcbSize, pcbMaxLookahead, pcbAlignment: DWORD): HResult; stdcall;
    function GetOutputSizeInfo(dwOutputStreamIndex: DWORD; out pcbSize, pcbAlignment: DWORD): HResult; stdcall;
    function GetInputMaxLatency(dwInputStreamIndex: DWORD; out prtMaxLatency: REFERENCE_TIME): HResult; stdcall;
    function SetInputMaxLatency(dwInputStreamIndex: DWORD; rtMaxLatency: REFERENCE_TIME): HResult; stdcall;
    function Flush: HResult; stdcall;
    function Discontinuity(dwInputStreamIndex: DWORD): HResult; stdcall;
    function AllocateStreamingResources: HResult; stdcall;
    function FreeStreamingResources: HResult; stdcall;
    function GetInputStatus(dwInputStreamIndex: DWORD; out dwFlags: DWORD): HResult; stdcall;
    function ProcessInput(dwInputStreamIndex: DWORD; pBuffer: IMediaBuffer; dwFlags: DWORD; rtTimestamp, rtTimelength: REFERENCE_TIME): HResult; stdcall;
    function ProcessOutput(dwFlags, cOutputBufferCount: DWORD; pOutputBuffers: pDMO_OUTPUT_DATA_BUFFER; out pdwStatus: DWORD): HResult; stdcall;
    function Lock(bLock: longint): HResult; stdcall;
  end;
  {$EXTERNALSYM IID_IMediaObject }
  IID_IMediaObject = IMediaObject;


  {$HPPEMIT 'DECLARE_DINTERFACE_TYPE(IMediaObjectInPlace);' }
  {$EXTERNALSYM IMediaObjectInPlace }
  IMediaObjectInPlace = interface(IUnknown)
    ['{651b9ad0-0fc7-4aa9-9538-d89931010741}']
    (*** IMediaObjectInPlace methods ***)
    function Process(ulSize: ULONG; {in/out} pData: Pointer; refTimeStart: REFERENCE_TIME; dwFlags: DWORD): HResult; stdcall;
    function Clone(out ppMediaObject: IMediaObjectInPlace): HResult; stdcall;
    function GetLatency(out pLatencyTime: REFERENCE_TIME): HResult; stdcall;
  end;
  {$EXTERNALSYM IID_IMediaObjectInPlace }
  IID_IMediaObjectInPlace = IMediaObjectInPlace;


  {$EXTERNALSYM PROPERTYKEY }
  {$EXTERNALSYM REFPROPERTYKEY }
  REFPROPERTYKEY = ^PROPERTYKEY;
  PROPERTYKEY = packed record
    //
    fmtid: tGUID;
    pid: DWORD;
  end;

  {$EXTERNALSYM REFPROPVARIANT }
  REFPROPVARIANT = ^PROPVARIANT;

  {$HPPEMIT 'DECLARE_DINTERFACE_TYPE(IPropertyStore);' }
  {$EXTERNALSYM IPropertyStore }
  IPropertyStore = interface(IUnknown)
    ['{886d8eeb-8cf2-4446-8d02-cdba1dbdcf99}']
    function GetCount({out} out cProps: DWORD): HRESULT; stdcall;
    function GetAt({in} iProp: DWORD; {out} out pkey: PROPERTYKEY): HRESULT; stdcall;
    function GetValue({in} const key: PROPERTYKEY;
                      {out} out pv: PROPVARIANT): HRESULT; stdcall;
    function SetValue({in} const key: PROPERTYKEY;
                      {in} var propvar: PROPVARIANT): HRESULT; stdcall;
    function Commit(): HRESULT; stdcall;

  end;
  IID_IPropertyStore = IPropertyStore;


  {$EXTERNALSYM REFIID }
  REFIID = PGUID;

  {$HPPEMIT 'DECLARE_DINTERFACE_TYPE(IMMDevice);' }
  {$EXTERNALSYM IMMDevice }
  IMMDevice = interface(IUnknown)
    ['{D666063F-1587-4E43-81F1-B948E807363F}']
    function Activate(
        //* [annotation][in] */
        iid: REFIID;
        //* [annotation][in] */
        dwClsCtx: DWORD;
        //* [annotation][unique][in] */
        pActivationParams: REFPROPVARIANT;
        //* [annotation][iid_is][out] */
        out ppInterface): HRESULT; stdcall;

    function OpenPropertyStore(
        //* [annotation][in] */
        stgmAccess: DWORD;
        //* [annotation][out] */
        out ppProperties: IPropertyStore): HRESULT; stdcall;

    function GetId(
        //* [annotation][out] */
        out ppstrId: LPWSTR): HRESULT; stdcall;

    function GetState(
        //* [annotation][out] */
        out pdwState: DWORD): HRESULT; stdcall;
  end;
  {$EXTERNALSYM IID_IMMDevice }
  IID_IMMDevice = IMMDevice;


  {$HPPEMIT 'DECLARE_DINTERFACE_TYPE(IMMDeviceCollection);' }
  {$EXTERNALSYM IMMDeviceCollection }
  IMMDeviceCollection = interface(IUnknown)
    ['{0BD7A1BE-7A1A-44DB-8397-CC5392387B5E}']
    function GetCount(
            //* [annotation][out] */
            out pcDevices: UINT): HRESULT; stdcall;

    function Item(
            //* [annotation][in] */
            nDevice: UINT;
            //* [annotation][out] */
            out ppDevice: IMMDevice): HRESULT; stdcall;
  end;
  {$EXTERNALSYM IID_IMMDeviceCollection }
  IID_IMMDeviceCollection = IMMDeviceCollection;


  {$EXTERNALSYM EDataFlow }
  EDataFlow = (eRender, eCapture, eAll);
  {$EXTERNALSYM ERole }
  ERole = (eConsole, eMultimedia, eCommunications);


  {$HPPEMIT 'DECLARE_DINTERFACE_TYPE(IMMNotificationClient);' }
  {$EXTERNALSYM IMMNotificationClient }
  IMMNotificationClient = interface(IUnknown)
    ['{7991EEC9-7E89-4D85-8390-6C703CEC60C0}']
    function OnDeviceStateChanged(
        //* [annotation][in] */
        pwstrDeviceId: LPCWSTR;
        //* [annotation][in] */
        dwNewState: DWORD): HRESULT; stdcall;

    function OnDeviceAdded(
        //* [annotation][in] */
        pwstrDeviceId: LPCWSTR): HRESULT; stdcall;

    function OnDeviceRemoved(
        //* [annotation][in] */
        pwstrDeviceId: LPCWSTR): HRESULT; stdcall;

    function OnDefaultDeviceChanged(
        //* [annotation][in] */
        flow: EDataFlow;
        //* [annotation][in] */
        role: ERole;
        //* [annotation][in] */
        pwstrDefaultDeviceId: LPCWSTR): HRESULT; stdcall;

    function OnPropertyValueChanged(
        //* [annotation][in] */
        pwstrDeviceId: LPCWSTR;
        //* [annotation][in] */
        key: PROPERTYKEY): HRESULT; stdcall;
  end;
  {$EXTERNALSYM IID_IMMNotificationClient }
  IID_IMMNotificationClient = IMMNotificationClient;


  {$HPPEMIT 'DECLARE_DINTERFACE_TYPE(IMMDeviceEnumerator);' }
  {$EXTERNALSYM IMMDeviceEnumerator }
  IMMDeviceEnumerator = interface(IUnknown)
    ['{A95664D2-9614-4F35-A746-DE8DB63617E6}']
    function EnumAudioEndpoints(
        //* [annotation][in] */
        dataFlow: EDataFlow;
        //* [annotation][in] */
        dwStateMask: DWORD;
        //* [annotation][out] */
        out ppDevices: IMMDeviceCollection): HRESULT; stdcall;

    function GetDefaultAudioEndpoint(
        //* [annotation][in] */
        dataFlow: EDataFlow;
        //* [annotation][in] */
        role: ERole;
        //* [annotation][out] */
        out  ppEndpoint: IMMDevice): HRESULT; stdcall;

    function GetDevice(
        //* [annotation][in] */
        pwstrId: LPCWSTR;
        //* [annotation][out] */
        out ppDevice: IMMDevice): HRESULT; stdcall;

    function RegisterEndpointNotificationCallback(
        //* [annotation][in] */
        pClient: IMMNotificationClient): HRESULT; stdcall;

    function UnregisterEndpointNotificationCallback(
        //* [annotation][in] */
        pClient: IMMNotificationClient): HRESULT; stdcall;
  end;
  {$EXTERNALSYM IID_IMMDeviceEnumerator }
  IID_IMMDeviceEnumerator = IMMDeviceEnumerator;



const

// Vista/Win7 specific
  CLSID_CWMAudioAEC: TGUID        = '{745057c7-f353-4f2d-a7ee-58434477730e}';
  CLSID_MMDeviceEnumerator: TGUID = '{BCDE0395-E52F-467C-8E3D-C4579291692E}';

  // AEC_SYSTEM_MODE enum:
  SINGLE_CHANNEL_AEC	        = 0;
  ADAPTIVE_ARRAY_ONLY	        = 1;
  OPTIBEAM_ARRAY_ONLY	        = 2;
  ADAPTIVE_ARRAY_AND_AEC        = 3;
  OPTIBEAM_ARRAY_AND_AEC        = 4;
  SINGLE_CHANNEL_NSAGC	        = 5;
  MODE_NOT_SET	                = 6;

  // AEC_VAD_MODE
  AEC_VAD_DISABLED	                = 0;
  AEC_VAD_NORMAL	                = 1;
  AEC_VAD_FOR_AGC	                = 2;
  AEC_VAD_FOR_SILENCE_SUPPRESSION	= 3;

  //
  MFPKEY_WMAAECMA_SYSTEM_MODE           : PROPERTYKEY = ( fmtid: '{6f52c567-0360-4bd2-9617-ccbf1421c939}'; pid: PID_FIRST_USABLE + 00);
  MFPKEY_WMAAECMA_DMO_SOURCE_MODE       : PROPERTYKEY = ( fmtid: '{6f52c567-0360-4bd2-9617-ccbf1421c939}'; pid: PID_FIRST_USABLE + 01);
  MFPKEY_WMAAECMA_DEVICE_INDEXES        : PROPERTYKEY = ( fmtid: '{6f52c567-0360-4bd2-9617-ccbf1421c939}'; pid: PID_FIRST_USABLE + 02);
  MFPKEY_WMAAECMA_FEATURE_MODE          : PROPERTYKEY = ( fmtid: '{6f52c567-0360-4bd2-9617-ccbf1421c939}'; pid: PID_FIRST_USABLE + 03);
  MFPKEY_WMAAECMA_FEATR_FRAME_SIZE      : PROPERTYKEY = ( fmtid: '{6f52c567-0360-4bd2-9617-ccbf1421c939}'; pid: PID_FIRST_USABLE + 04);
  MFPKEY_WMAAECMA_FEATR_ECHO_LENGTH     : PROPERTYKEY = ( fmtid: '{6f52c567-0360-4bd2-9617-ccbf1421c939}'; pid: PID_FIRST_USABLE + 05);
  MFPKEY_WMAAECMA_FEATR_NS              : PROPERTYKEY = ( fmtid: '{6f52c567-0360-4bd2-9617-ccbf1421c939}'; pid: PID_FIRST_USABLE + 06);
  MFPKEY_WMAAECMA_FEATR_AGC             : PROPERTYKEY = ( fmtid: '{6f52c567-0360-4bd2-9617-ccbf1421c939}'; pid: PID_FIRST_USABLE + 07);
  MFPKEY_WMAAECMA_FEATR_AES             : PROPERTYKEY = ( fmtid: '{6f52c567-0360-4bd2-9617-ccbf1421c939}'; pid: PID_FIRST_USABLE + 08);
  MFPKEY_WMAAECMA_FEATR_VAD             : PROPERTYKEY = ( fmtid: '{6f52c567-0360-4bd2-9617-ccbf1421c939}'; pid: PID_FIRST_USABLE + 09);
  MFPKEY_WMAAECMA_FEATR_CENTER_CLIP     : PROPERTYKEY = ( fmtid: '{6f52c567-0360-4bd2-9617-ccbf1421c939}'; pid: PID_FIRST_USABLE + 10);
  MFPKEY_WMAAECMA_FEATR_NOISE_FILL      : PROPERTYKEY = ( fmtid: '{6f52c567-0360-4bd2-9617-ccbf1421c939}'; pid: PID_FIRST_USABLE + 11);
  MFPKEY_WMAAECMA_RETRIEVE_TS_STATS     : PROPERTYKEY = ( fmtid: '{6f52c567-0360-4bd2-9617-ccbf1421c939}'; pid: PID_FIRST_USABLE + 12);
  MFPKEY_WMAAECMA_QUALITY_METRICS       : PROPERTYKEY = ( fmtid: '{6f52c567-0360-4bd2-9617-ccbf1421c939}'; pid: PID_FIRST_USABLE + 13);
  MFPKEY_WMAAECMA_MICARRAY_DESCPTR      : PROPERTYKEY = ( fmtid: '{6f52c567-0360-4bd2-9617-ccbf1421c939}'; pid: PID_FIRST_USABLE + 14);
  MFPKEY_WMAAECMA_DEVICEPAIR_GUID       : PROPERTYKEY = ( fmtid: '{6f52c567-0360-4bd2-9617-ccbf1421c939}'; pid: PID_FIRST_USABLE + 15);
  MFPKEY_WMAAECMA_FEATR_MICARR_MODE     : PROPERTYKEY = ( fmtid: '{6f52c567-0360-4bd2-9617-ccbf1421c939}'; pid: PID_FIRST_USABLE + 16);
  MFPKEY_WMAAECMA_FEATR_MICARR_BEAM     : PROPERTYKEY = ( fmtid: '{6f52c567-0360-4bd2-9617-ccbf1421c939}'; pid: PID_FIRST_USABLE + 17);
  MFPKEY_WMAAECMA_FEATR_MICARR_PREPROC  : PROPERTYKEY = ( fmtid: '{6f52c567-0360-4bd2-9617-ccbf1421c939}'; pid: PID_FIRST_USABLE + 18);
  MFPKEY_WMAAECMA_MIC_GAIN_BOUNDER      : PROPERTYKEY = ( fmtid: '{6f52c567-0360-4bd2-9617-ccbf1421c939}'; pid: PID_FIRST_USABLE + 19);

  //
  PKEY_Device_FriendlyName              : PROPERTYKEY = ( fmtid: '{a45c254e-df1c-4efd-8020-67d146a850e0}'; pid: 14);    // DEVPROP_TYPE_STRING
  PKEY_AudioEndpoint_GUID               : PROPERTYKEY = ( fmtid: '{1da5d803-d492-4edd-8c23-e0c0ffee7f0e}'; pid: 04);


  //enum _DMO_INPUT_DATA_BUFFER_FLAGS
  DMO_INPUT_DATA_BUFFERF_SYNCPOINT	= $1;
  DMO_INPUT_DATA_BUFFERF_TIME	        = $2;
  DMO_INPUT_DATA_BUFFERF_TIMELENGTH	= $4;

  //enum _DMO_OUTPUT_DATA_BUFFER_FLAGS
  DMO_OUTPUT_DATA_BUFFERF_SYNCPOINT	= $1;
  DMO_OUTPUT_DATA_BUFFERF_TIME	        = $2;
  DMO_OUTPUT_DATA_BUFFERF_TIMELENGTH	= $4;
  DMO_OUTPUT_DATA_BUFFERF_INCOMPLETE	= $1000000;

  // enum _DMO_INPUT_STATUS_FLAGS
  DMO_INPUT_STATUSF_ACCEPT_DATA	        = $1;

  // enum _DMO_INPUT_STREAM_INFO_FLAGS
  DMO_INPUT_STREAMF_WHOLE_SAMPLES	        = $1;
  DMO_INPUT_STREAMF_SINGLE_SAMPLE_PER_BUFFER	= $2;
  DMO_INPUT_STREAMF_FIXED_SAMPLE_SIZE	        = $4;
  DMO_INPUT_STREAMF_HOLDS_BUFFERS	        = $8;

  // enum _DMO_OUTPUT_STREAM_INFO_FLAGS
  DMO_OUTPUT_STREAMF_WHOLE_SAMPLES	        = $1;
  DMO_OUTPUT_STREAMF_SINGLE_SAMPLE_PER_BUFFER	= $2;
  DMO_OUTPUT_STREAMF_FIXED_SAMPLE_SIZE	        = $4;
  DMO_OUTPUT_STREAMF_DISCARDABLE	        = $8;
  DMO_OUTPUT_STREAMF_OPTIONAL	                = $10;

  // enum _DMO_SET_TYPE_FLAGS
  DMO_SET_TYPEF_TEST_ONLY	= $1;
  DMO_SET_TYPEF_CLEAR	        = $2;

  // enum _DMO_PROCESS_OUTPUT_FLAGS
  DMO_PROCESS_OUTPUT_DISCARD_WHEN_NO_BUFFER	= $1;

  //
  DEVICE_STATE_ACTIVE      = $00000001;
  DEVICE_STATE_DISABLED    = $00000002;
  DEVICE_STATE_NOTPRESENT  = $00000004;
  DEVICE_STATE_UNPLUGGED   = $00000008;
  DEVICE_STATEMASK_ALL     = $0000000f;

  //
  MEDIATYPE_Audio       : TGUID = (D1:$73647561;D2:$0000;D3:$0010;D4:($80,$00,$00,$AA,$00,$38,$9B,$71));
  FORMAT_WaveFormatEx   : TGUID = (D1:$05589F81;D2:$C356;D3:$11CE;D4:($BF,$01,$00,$AA,$00,$55,$59,$5A));


type
  // media buffer implementation
  tMediaBuffer = class(unaObject, IMediaBuffer, IUnknown)
  private
    f_refC: int;
    f_size: DWORD;
    f_dataLen: DWORD;
    f_data: pointer;
  public
    constructor create(maxSize: unsigned);
    procedure BeforeDestruction(); override;
    // IUnknown
    function QueryInterface(const IID: TGUID; out Obj): HRESULT; stdcall;
    function _AddRef(): integer; stdcall;
    function _Release(): integer; stdcall;
    // IMediaBuffer methods
    function SetLength(len: DWORD): HRESULT; stdcall;
    function GetMaxLength(out maxLen: DWORD): HRESULT; stdcall;
    function GetBufferAndLength(out buf: PByte;       // not filled if NULL
                                out len: DWORD          // not filled if NULL
                                ): HRESULT; stdcall;
  end;

  // -- DS routines  --

  {$EXTERNALSYM LPDSENUMCALLBACKW }
  LPDSENUMCALLBACKW = function(p1: PGUID; p2: LPCWSTR; p3: LPCWSTR; p4: pointer): bool; stdcall;

  // --  --
  proc_DirectSoundCreate8 = function(pcGuidDevice: PGUID; out ppDS8: IDirectSound8; pUnkOuter: IUnknown): HResult; stdcall;

  // --  --
  proc_DirectSoundFullDuplexCreate8 = function(pcGuidCaptureDevice, pcGuidRenderDevice: PGUID; const pcDSCBufferDesc: TDSCBufferDesc; const pcDSBufferDesc: TDSBufferDesc; hWnd: hWnd; dwLevel: DWORD; out ppDSFD: IDirectSoundFullDuplex8; out ppDSCBuffer8: IDirectSoundCaptureBuffer8; out ppDSBuffer8: IDirectSoundBuffer8; pUnkOuter: IUnknown): HRESULT; stdcall;
  proc_DirectSoundEnumerateW = function (pDSEnumCallback: LPDSENUMCALLBACKW; pContext: pointer): HRESULT; stdcall;
  proc_DirectSoundCaptureEnumerateW = function(pDSEnumCallback: LPDSENUMCALLBACKW; pContext: pointer): HRESULT; stdcall;
  //
  proc_MoInitMediaType = function(var pmt: DMO_MEDIA_TYPE; cbFormat: DWORD): HRESULT; stdcall;
  proc_MoFreeMediaType = function(var pmt: DMO_MEDIA_TYPE): HRESULT; stdcall;


{$EXTERNALSYM DirectSoundCreate8}
function DirectSoundCreate8(pcGuidDevice: PGUID; out ppDS8: IDirectSound8; pUnkOuter: IUnknown): HRESULT; stdcall;

{$EXTERNALSYM DirectSoundFullDuplexCreate8 }
function DirectSoundFullDuplexCreate8(pcGuidCaptureDevice, pcGuidRenderDevice: PGUID; const pcDSCBufferDesc: TDSCBufferDesc; const pcDSBufferDesc: TDSBufferDesc; hWnd: hWnd; dwLevel: DWORD; out ppDSFD: IDirectSoundFullDuplex8; out ppDSCBuffer8: IDirectSoundCaptureBuffer8; out ppDSBuffer8: IDirectSoundBuffer8; pUnkOuter: IUnknown): HRESULT; stdcall;

// --  --
function unadsFullDuplexCreate(pcGuidCaptureDevice, pcGuidRenderDevice: PGUID; const pcDSCBufferDesc: TDSCBufferDesc; const pcDSBufferDesc: TDSBufferDesc; hWnd: hWnd; dwLevel: DWORD; out ppDSFD: IDirectSoundFullDuplex8; out ppDSCBuffer8: IDirectSoundCaptureBuffer8; out ppDSBuffer8: IDirectSoundBuffer8): HRESULT;

// --  --
function unaDirectSoundCreate(pcGuidDevice: PGUID; out ppDS8: IDirectSound8): HRESULT;

// --  --
function DirectSoundEnumerate(cap: bool; cb: LPDSENUMCALLBACKW; context: pointer): HRESULT;

// --  --
procedure propVariantInit(v: PROPVARIANT);

// --  --
{$EXTERNALSYM MoInitMediaType }
{$EXTERNALSYM MoFreeMediaType }
function MoInitMediaType(var pmt: DMO_MEDIA_TYPE; cbFormat: DWORD): HRESULT;
function MoFreeMediaType(var pmt: DMO_MEDIA_TYPE): HRESULT;


implementation


uses
  unaUtils;

var
  // --  --
  g_DSLib: hModule = INVALID_HANDLE_VALUE;
  g_dsc: proc_DirectSoundCreate8;
  g_DSFD_create: proc_DirectSoundFullDuplexCreate8;
  g_DS_EnumW: proc_DirectSoundEnumerateW;
  g_DS_CaptureEnumW: proc_DirectSoundCaptureEnumerateW;
  //
  g_dmoLib: hModule = INVALID_HANDLE_VALUE;
  g_MoInitMediaType: proc_MoInitMediaType;
  g_MoFreeMediaType: proc_MoFreeMediaType;


// --  --
function loadDSLib(): bool;
begin
  if (INVALID_HANDLE_VALUE = g_DSLib) then begin
    //
{$IFNDEF NO_ANSI_SUPPORT }
    if (g_wideApiSupported) then begin
{$ENDIF NO_ANSI_SUPPORT }
      g_DSLib := LoadLibraryW(c_directSoundDll);
{$IFNDEF NO_ANSI_SUPPORT }
    end
    else
      g_DSLib := LoadLibraryA(c_directSoundDll);
{$ENDIF NO_ANSI_SUPPORT }
    //
    if (INVALID_HANDLE_VALUE = g_DSLib) then
      g_DSLib := 0;
    //
    result := (0 <> g_DSLib);
  end
  else
    result := true;
end;

// --  --
function loadDMOLib(): bool;
begin
  if (INVALID_HANDLE_VALUE = g_dmoLib) then begin
    //
{$IFNDEF NO_ANSI_SUPPORT }
    if (g_wideApiSupported) then begin
{$ENDIF NO_ANSI_SUPPORT }
      g_dmoLib := LoadLibraryW(c_dmoDll);
{$IFNDEF NO_ANSI_SUPPORT }
    end
    else
      g_dmoLib := LoadLibraryA(c_dmoDll);
{$ENDIF NO_ANSI_SUPPORT }
    //
    if (INVALID_HANDLE_VALUE = g_dmoLib) then
      g_dmoLib := 0;
    //
    result := (0 <> g_dmoLib);
  end
  else
    result := true;
end;

// --  --
function DirectSoundCreate8(pcGuidDevice: PGUID; out ppDS8: IDirectSound8; pUnkOuter: IUnknown): HRESULT;
begin
  if (not assigned(g_dsc) and loadDSLib()) then
    @g_dsc := GetProcAddress(g_DSLib, 'DirectSoundCreate');
  //
  if (assigned(g_dsc)) then
    result := g_dsc(pcGuidDevice, ppDS8, pUnkOuter)
  else
    result := E_NOTIMPL;
end;

// --  --
function DirectSoundFullDuplexCreate8(pcGuidCaptureDevice, pcGuidRenderDevice: PGUID; const pcDSCBufferDesc: TDSCBufferDesc; const pcDSBufferDesc: TDSBufferDesc; hWnd: hWnd; dwLevel: DWORD; out ppDSFD: IDirectSoundFullDuplex8; out ppDSCBuffer8: IDirectSoundCaptureBuffer8; out ppDSBuffer8: IDirectSoundBuffer8; pUnkOuter: IUnknown): HRESULT;
begin
  if (not assigned(g_DSFD_create) and loadDSLib()) then
    @g_DSFD_create := GetProcAddress(g_DSLib, 'DirectSoundFullDuplexCreate');
  //
  if (assigned(g_DSFD_create)) then
    result := g_DSFD_create(pcGuidCaptureDevice, pcGuidRenderDevice, pcDSCBufferDesc, pcDSBufferDesc, hWnd, dwLevel, ppDSFD, ppDSCBuffer8, ppDSBuffer8, pUnkOuter)
  else
    result := E_NOTIMPL;
end;

// --  --
function unadsFullDuplexCreate(pcGuidCaptureDevice, pcGuidRenderDevice: PGUID; const pcDSCBufferDesc: TDSCBufferDesc; const pcDSBufferDesc: TDSBufferDesc; hWnd: hWnd; dwLevel: DWORD; out ppDSFD: IDirectSoundFullDuplex8; out ppDSCBuffer8: IDirectSoundCaptureBuffer8; out ppDSBuffer8: IDirectSoundBuffer8): HRESULT;
begin
  result := DirectSoundFullDuplexCreate8(pcGuidCaptureDevice, pcGuidRenderDevice, pcDSCBufferDesc, pcDSBufferDesc, hWnd, dwLevel, ppDSFD, ppDSCBuffer8, ppDSBuffer8, nil);
end;

// --  --
function unaDirectSoundCreate(pcGuidDevice: PGUID; out ppDS8: IDirectSound8): HRESULT;
begin
  result := DirectSoundCreate8(pcGuidDevice, ppDS8, nil);
end;

// --  --
function DirectSoundEnumerate(cap: bool; cb: LPDSENUMCALLBACKW; context: pointer): HRESULT;
begin
  if (not assigned(g_DS_EnumW) and loadDSLib()) then
    @g_DS_EnumW := GetProcAddress(g_DSLib, 'DirectSoundEnumerateW');
  //
  if (not assigned(g_DS_CaptureEnumW) and loadDSLib()) then
    @g_DS_CaptureEnumW := GetProcAddress(g_DSLib, 'DirectSoundCaptureEnumerateW');
  //
  if (not cap and assigned(g_DS_EnumW)) then
    result := g_DS_EnumW(cb, context)
  else
    if (cap and assigned(g_DS_CaptureEnumW)) then
      result := g_DS_CaptureEnumW(cb, context)
    else
      result := E_FAIL;
end;

// --  --
procedure propVariantInit(v: PROPVARIANT);
begin
  fillChar(v, sizeof(PROPVARIANT), #0);
end;

// --  --
function MoInitMediaType(var pmt: DMO_MEDIA_TYPE; cbFormat: DWORD): HRESULT;
begin
  if (not assigned(g_MoInitMediaType) and loadDMOLib()) then
    g_MoInitMediaType := GetProcAddress(g_dmoLib, 'MoInitMediaType');
  //
  if (assigned(g_MoInitMediaType)) then
    result := g_MoInitMediaType(pmt, cbFormat)
  else
    result := E_FAIL;
end;

// --  --
function MoFreeMediaType(var pmt: DMO_MEDIA_TYPE): HRESULT;
begin
  if (not assigned(g_MoFreeMediaType) and loadDMOLib()) then
    g_MoFreeMediaType := GetProcAddress(g_dmoLib, 'MoFreeMediaType');
  //
  if (assigned(g_MoFreeMediaType)) then
    result := g_MoFreeMediaType(pmt)
  else
    result := E_FAIL;
end;


{ tMediaBuffer }

// --  --
procedure tMediaBuffer.BeforeDestruction();
begin
  inherited;
  //
  SetLength(0);
end;

// --  --
constructor tMediaBuffer.create(maxSize: unsigned);
begin
  _AddRef();
  //
  SetLength(maxSize);
  f_dataLen := 0;
  //
  inherited create();
end;

// --  --
function tMediaBuffer.GetBufferAndLength(out buf: PByte; out len: DWORD): HRESULT;
begin
  if (assigned(@buf) or assigned(@len)) then begin
    //
    if (assigned(@buf)) then
      buf := f_data;
    if (assigned(@len)) then
      len := f_dataLen;
    //
    result := S_OK;
  end
  else
    result := E_POINTER;
end;

// --  --
function tMediaBuffer.GetMaxLength(out maxLen: DWORD): HRESULT;
begin
  maxLen := f_size;
  result := S_OK;
end;

// --  --
function tMediaBuffer.QueryInterface(const IID: TGUID; out Obj): HRESULT;
begin
  if (not assigned(@Obj)) then
    result := E_POINTER
  else begin
    //
    if ((IsEqualGUID(IID, IID_IMediaBuffer) or IsEqualGUID(IID, IUnknown)) and (GetInterface(IID, Obj))) then
      result := S_OK
    else begin
      //
      pointer(Obj) := nil;
      result := E_NOINTERFACE;
    end;
  end;
end;

// --  --
function tMediaBuffer.SetLength(len: DWORD): HRESULT;
begin
  if (len > f_size) then begin
    //
    mrealloc(f_data, len);
    f_size := len;
  end;
  //
  f_dataLen := len;
  result := S_OK;
end;

// --  --
function tMediaBuffer._AddRef(): integer;
begin
  result := InterlockedIncrement(f_refC);
end;

// --  --
function tMediaBuffer._Release(): integer;
begin
  result := InterlockedDecrement(f_refC);
  if (0 = result) then
    free();
end;


initialization

finalization
  //
  if ((0 <> g_DSLib) and (INVALID_HANDLE_VALUE <> g_DSLib)) then begin
    //
    g_DSFD_create := nil;
    //
    FreeLibrary(g_DSLib);
  end;
  //
  if ((0 <> g_dmoLib) and (INVALID_HANDLE_VALUE <> g_dmoLib)) then begin
    //
    g_MoInitMediaType := nil;
    g_MoFreeMediaType := nil;
    //
    FreeLibrary(g_dmoLib);
  end;
end.

