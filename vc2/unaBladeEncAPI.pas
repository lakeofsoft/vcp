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

	  unaBladeAPI.pas
	  Voice Communicator components version 2.5
	  API for Blade and Lame MP3 encoders

	----------------------------------------------
	  Copyright (c) 2002-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 21 Oct 2002

	  modified by:
		Lake, Oct-Nov 2002
		Lake, Feb-May 2003
		Lake, Jun 2009
		Lake, Feb, Nov 2010

	----------------------------------------------
*)

{$I unaDef.inc }

{*
  BladeEnc.DLL and LameEnc.DLL wrapper.

  @Author Lake

 	2.5.2008.07 Still here
  
	2.5.2010.02 Added unaLameEncoder class
}

unit
  unaBladeEncAPI;

interface

uses
  Windows, unaTypes, unaClasses;

// ============= una specific =================
const
  UNA_ENCODER_ERR_BASE			   = $10000000;
  UNA_ENCODER_ERR_NO_DLL		   = UNA_ENCODER_ERR_BASE + 1;
  UNA_ENCODER_ERR_NO_PROCEDURE		   = UNA_ENCODER_ERR_BASE + 2;

// ============= Blade ========================

const
  //* encoding formats */
  BE_CONFIG_MP3 = 0;
  BE_CONFIG_AAC = BE_CONFIG_MP3 + 998;	// not supported, added by Lake


type
  //* type definitions */
  PHBE_STREAM 	= ^HBE_STREAM;
  HBE_STREAM	= DWORD;
  BE_ERR	= int32;


const
  //* error codes */
  BE_ERR_SUCCESSFUL		   =	$00000000;
  BE_ERR_INVALID_FORMAT		   =	$00000001;
  BE_ERR_INVALID_FORMAT_PARAMETERS =	$00000002;
  BE_ERR_NO_MORE_HANDLES	   =	$00000003;
  BE_ERR_INVALID_HANDLE		   =	$00000004;

  //* other constants */
  BE_MAX_HOMEPAGE		   =	256;

  //* format specific variables */
  BE_MP3_MODE_STEREO	  =	0;
  BE_MP3_MODE_DUALCHANNEL =	2;
  BE_MP3_MODE_MONO	  =	3;


type
  // --  --
  tBE_CONFIG_MP3 = packed record
    dwSampleRate: DWORD;	// 48000, 44100 and 32000 allowed
    byMode: BYTE;		// BE_MP3_MODE_STEREO, BE_MP3_MODE_DUALCHANNEL, BE_MP3_MODE_MONO
    wBitrate: WORD;		// 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256 and 320 allowed
    bPrivate: Windows.BOOL;
    bCRC: Windows.BOOL;
    bCopyright: Windows.BOOL;
    bOriginal: Windows.BOOL;
  end;

  // --  --
  tBE_CONFIG_AAC = packed record
    dwSampleRate: DWORD;
    raac_byMode: BYTE;
    wBitrate: WORD;
    byEncodingMethod: BYTE;
  end;

  // --  --
  PBE_CONFIG = ^BE_CONFIG;
  BE_CONFIG = packed record
    case dwConfig: DWORD of	// BE_CONFIG_XXXXX
				// Currently only BE_CONFIG_MP3 is supported
      BE_CONFIG_MP3: (
       r_mp3: tBE_CONFIG_MP3
      );

      BE_CONFIG_AAC: (
	r_aac: tBE_CONFIG_AAC;
      );
  end;

  // --  --
  PBE_VERSION = ^BE_VERSION;
  BE_VERSION = packed record
    // BladeEnc DLL Version number
    byDLLMajorVersion: BYTE;
    byDLLMinorVersion: BYTE;
    // BladeEnc Engine Version Number
    byMajorVersion: BYTE	;
    byMinorVersion: BYTE	;
    // DLL Release date
    byDay: BYTE;
    byMonth: BYTE	;
    wYear: WORD;
    // BladeEnc	Homepage URL
    zHomepage: array[0..BE_MAX_HOMEPAGE] of AnsiChar;
  end;


// ============= Lame ========================

const
  //* LAME encoding formats */
  BE_CONFIG_LAME	= 256;

  // supported by Lame only
  BE_MP3_MODE_JSTEREO	  =	1;

  //* LAME error codes */
  BE_ERR_BUFFER_TOO_SMALL	= $00000005;

  // ?
  MPEG1		= 1;
  MPEG2		= 0;

  CURRENT_STRUCT_VERSION = 1;
//#define CURRENT_STRUCT_SIZE sizeof(BE_CONFIG)	// is currently 331 bytes

  // VBRMETHOD:
  VBR_METHOD_NONE	= -1;
  VBR_METHOD_DEFAULT	=  0;
  VBR_METHOD_OLD	=  1;
  VBR_METHOD_NEW	=  2;
  VBR_METHOD_MTRH	=  3;
  VBR_METHOD_ABR	=  4;

  // LAME_QUALTIY_PRESET:
  LQP_NOPRESET		= -1;

  // QUALITY PRESETS
  LQP_NORMAL_QUALITY	= 0;
  LQP_LOW_QUALITY	= 1;
  LQP_HIGH_QUALITY	= 2;
  LQP_VOICE_QUALITY	= 3;
  LQP_R3MIX		= 4;
  LQP_VERYHIGH_QUALITY	= 5;
  LQP_STANDARD		= 6;
  LQP_FAST_STANDARD	= 7;
  LQP_EXTREME		= 8;
  LQP_FAST_EXTREME	= 9;
  LQP_INSANE		= 10;
  LQP_ABR		= 11;
  LQP_CBR		= 12;

  // NEW PRESET VALUES
  LQP_PHONE	= 1000;
  LQP_SW	= 2000;
  LQP_AM	= 3000;
  LQP_FM	= 4000;
  LQP_VOICE	= 5000;
  LQP_RADIO	= 6000;
  LQP_TAPE	= 7000;
  LQP_HIFI	= 8000;
  LQP_CD	= 9000;
  LQP_STUDIO	= 10000;


type
  {$EXTERNALSYM LONG }
  LONG = longInt;

  // --  --
  tBE_CONFIG_LHV1 = packed record
    // STRUCTURE INFORMATION
    dwStructVersion: DWORD;
    dwStructSize: DWORD;

    // BASIC ENCODER SETTINGS
    dwSampleRate: DWORD;	// SAMPLERATE OF INPUT FILE (ALLOWED SAMPLERATE VALUES DEPENDS ON dwMPEGVersion)
    dwReSampleRate: DWORD;	// DOWNSAMPLERATE, 0=ENCODER DECIDES
    nMode: LONG;	  	// BE_MP3_MODE_XXX
    dwBitrate: DWORD;		// CBR bitrate, VBR min bitrate
    dwMaxBitrate: DWORD;	// CBR ignored, VBR Max bitrate
    nPreset: LONG;   		// LQP_XXX
    dwMpegVersion: DWORD;	// FUTURE USE, MPEG-1 OR MPEG-2
    dwPsyModel: DWORD;		// FUTURE USE, SET TO 0
    dwEmphasis: DWORD;		// FUTURE USE, SET TO 0

    // BIT STREAM SETTINGS
    bPrivate: Windows.BOOL;	// Set Private Bit (TRUE/FALSE)
    bCRC: Windows.BOOL;		// Insert CRC (TRUE/FALSE)
    bCopyright: Windows.BOOL;	// Set Copyright Bit (TRUE/FALSE)
    bOriginal: Windows.BOOL;	// Set Original Bit (TRUE/FALSE)

    // VBR STUFF
    bWriteVBRHeader: Windows.BOOL;	// WRITE XING VBR HEADER (TRUE/FALSE)
    bEnableVBR: Windows.BOOL;	// USE VBR ENCODING (TRUE/FALSE)
    nVBRQuality: LONG;		// VBR QUALITY 0..9
    //
    dwVbrAbr_bps: DWORD;	// Use ABR in stead of nVBRQuality
    nVbrMethod: LONG;		// VBR_XXX
    bNoRes: Windows.BOOL;	// Disable Bit resorvoir (TRUE/FALSE)
    bStrictIso: Windows.BOOL;	// Use strict ISO encoding rules (TRUE/FALSE)
    // stub
    btReserved: array[0..254 - 4 * sizeOf(DWORD)] of byte;	// FUTURE USE, SET TO 0
  end;

  // --  --
  PBE_CONFIG_FORMATLAME = ^BE_CONFIG_FORMATLAME;
  BE_CONFIG_FORMATLAME = packed record
    case dwConfig: DWORD of	// BE_CONFIG_XXX

      BE_CONFIG_MP3: (
       r_mp3: tBE_CONFIG_MP3;
      );

      BE_CONFIG_LAME: (
       r_lhv1: tBE_CONFIG_LHV1;
      );

      BE_CONFIG_AAC: (
	r_aac: tBE_CONFIG_AAC;
      );
  end;


// ============= Blade ========================
// stubs for BE API, added by Lake

type
  //
  {*
    Prototype for beInitStream() routine.
  }
  proc_beInitStream = function(pbeConfig: PBE_CONFIG; var dwSamples: DWORD; var dwBufferSize: DWORD; var phbeStream: HBE_STREAM): BE_ERR; cdecl;
  {*
    Prototype for beEncodeChunk() routine.
  }
  proc_beEncodeChunk = function(hbeStream: HBE_STREAM; nSamples: DWORD; pSamples: pointer; pOutput: pointer; var pdwOutput: DWORD): BE_ERR; cdecl;
  {*
    Prototype for beDeinitStream() routine.
  }
  proc_beDeinitStream = function(hbeStream: HBE_STREAM; pOutput: pointer; var pdwOutput: DWORD): BE_ERR; cdecl;
  {*
    Prototype for beCloseStream() routine.
  }
  proc_beCloseStream = function(hbeStream: HBE_STREAM): BE_ERR; cdecl;
  {*
    Prototype for beVersion() routine.
  }
  proc_beVersion = procedure(var pbeVersion: BE_VERSION); cdecl;


type
  //
  // -- tBladeLibrary_proc --
  //
  pBladeLibrary_proc = ^tBladeLibrary_proc;
  tBladeLibrary_proc = record
    r_be_module: hModule;
    r_be_moduleRefCount: int;
    //
    r_beInitStream  : proc_beInitStream;
    r_beEncodeChunk : proc_beEncodeChunk;
    r_beDeinitStream: proc_beDeinitStream;
    r_beCloseStream : proc_beCloseStream;
    r_beVersion     : proc_beVersion;
  end;


{*
  This function is the first to call before starting an encoding stream.
}
function beInitStream(const bladeProc: tBladeLibrary_proc; config: PBE_CONFIG; out nSamples: DWORD; out minOutputBufSize: DWORD; out stream: HBE_STREAM): BE_ERR;

{*
  Encodes a chunk of samples. Please note that if you have set the output to
  generate mono MP3 files you must feed beEncodeChunk() with mono samples!
}
function beEncodeChunk(const bladeProc: tBladeLibrary_proc; stream: HBE_STREAM; nSamples: DWORD; samplesBuf: pointer; outputBuf: pointer; out outputUsed: DWORD): BE_ERR;

{*
  This function should be called after encoding the last chunk in order to
  flush the encoder. It writes any encoded data that still might be left inside
  the encoder to the output buffer.

  This function should NOT be called unless you have encoded all of the chunks in your stream.
}
function beDeinitStream(const bladeProc: tBladeLibrary_proc; stream: HBE_STREAM; outputBuf: pointer; out outputUsed: DWORD): BE_ERR;

{*
  Last function to be called when finished encoding a stream.

  Should unlike beDeinitStream() also be called if the encoding is canceled.
}
function beCloseStream(const bladeProc: tBladeLibrary_proc; stream: HBE_STREAM): BE_ERR;

{*
  Returns information like version numbers (both of the DLL and encoding engine),
  release date and URL for BladeEnc's homepage. All this information should be made
  available to the user of your product through a dialog box or something similar.
}
function beVersion(const bladeProc: tBladeLibrary_proc; out version: BE_VERSION): bool;

// -- DLL specific --

const
  //
  c_bladeEncDLL	= 'BladeEnc.dll';


{*
  Loads Blade DLL.

  @return 0 if successuf, or Windows specific error code.
}
function blade_loadDLL(var bladeProc: tBladeLibrary_proc; const pathAndName: wString = c_bladeEncDLL): int;

{*
  Unloads Blade DLL.

  @returns 0 if successuf, or Windows specific error code.
}
function blade_unloadDLL(var bladeProc: tBladeLibrary_proc): int;


// ============= Lame ========================
// stubs for Lame API, added by Lake

type
  {*
    Prototype for lameWriteVBRHeader() routine.
  }
  proc_lameWriteVBRHeader = function(fileName: LPCSTR): BE_ERR; cdecl;


type
  //
  // -- tLameLibrary_proc --
  //
  pLameLibrary_proc = ^tLameLibrary_proc;
  tLameLibrary_proc = record
    //
    r_lame_module: hModule;
    r_lame_moduleRefCount: int;
    //
    r_lameInitStream  : proc_beInitStream; 	// same stubs as for Blade
    r_lameEncodeChunk : proc_beEncodeChunk;
    r_lameDeinitStream: proc_beDeinitStream;
    r_lameCloseStream : proc_beCloseStream;
    r_lameVersion     : proc_beVersion;
    r_lameWriteVBRHeader: proc_lameWriteVBRHeader;
  end;

{*
  This function is the first to call before starting an encoding stream.
}
function lameInitStream(const lameProc: tLameLibrary_proc; config: PBE_CONFIG_FORMATLAME; out nSamples: DWORD; out minOutputBufSize: DWORD; out stream: HBE_STREAM): BE_ERR;

{*
  Encodes a chunk of samples. Please note that if you have set the output to
  generate mono MP3 files you must feed beEncodeChunk() with mono samples!
}
function lameEncodeChunk(const lameProc: tLameLibrary_proc; stream: HBE_STREAM; nSamples: DWORD; samplesBuf: pointer; outputBuf: pointer; out outputUsed: DWORD): BE_ERR;

{*
  This function should be called after encoding the last chunk in order to
  flush the encoder. It writes any encoded data that still might be left inside
  the encoder to the output buffer. This function should NOT be called unless you
  have encoded all of the chunks in your stream.
}
function lameDeinitStream(const lameProc: tLameLibrary_proc; stream: HBE_STREAM; outputBuf: pointer; out outputUsed: DWORD): BE_ERR;

{*
  Last function to be called when finished encoding a stream.
  Should unlike beDeinitStream() also be called if the encoding is canceled.
}
function lameCloseStream(const lameProc: tLameLibrary_proc; stream: HBE_STREAM): BE_ERR;

{*
  Returns information like version numbers (both of the DLL and encoding engine),
  release date and URL for BladeEnc's homepage. All this information should be made
  available to the user of your product through a dialog box or something similar.
}
function lameVersion(const lameProc: tLameLibrary_proc; out version: BE_VERSION): bool;

{*
  Writes a Xing Header in front of the MP3 file. Make sure that the MP3 file is
  closed, and the the beConfig.format.LHV1.bWriteVBRHeader has been set to TRUE.
  In addition, it is always safe to call beWriteVBRHeader after the encoding has
  been finished, even when the beConfig.format.LHV1.bWriteVBRHeader is not set to TRUE.
}
function lameWriteVBRHeader(const lameProc: tLameLibrary_proc; const fileName: aString): BE_ERR;


// NOT SUPPORTED:
// added for floating point audio  -- DSPguru, jd
//__declspec(dllexport) BE_ERR	beEncodeChunkFloatS16NI(HBE_STREAM hbeStream, DWORD nSamples, PFLOAT buffer_l, PFLOAT buffer_r, PBYTE pOutput, PDWORD pdwOutput);
//__declspec(dllexport) BE_ERR	beFlushNoGap(HBE_STREAM hbeStream, PBYTE pOutput, PDWORD pdwOutput);


// -- DLL specific --

const
  c_lameEncDLL = 'lame_enc.dll';


type
  unaLameEncoder = class (unaObject)
  private
    f_proc: tLameLibrary_proc;
    f_stream: HBE_STREAM;
    //
    f_nSamplesPerChunk: DWORD;
    //
    f_minOutBufSize: DWORD;
    f_buf: pointer;
    f_frameSize: unsigned;
    //
    f_bCopy: bool;
    f_bOriginal: bool;
    f_bPrivate: bool;
    //
    f_mpeg: unsigned;
    //
    f_nCh: unsigned;
    f_nSps: unsigned;
    f_active: bool;
    f_gotAnyData: bool;
    f_libOK: bool;
    //
    function calcFrameSize(rate: int): int;
  protected
    procedure onEncodedData(sampleDelta: uint; data: pointer; len: uint); virtual;
  public
    constructor create(const libName: string = c_lameEncDLL);
    procedure BeforeDestruction(); override;
    //
    procedure getVer(var ver: BE_VERSION);
    //
    {*
	Initializates and open the encoder for CBR or ABR.

	@param bitrate Desired bitrate.
	@param cbr True for CBR, False for ABR, default is True
	@param resample Resample input stream to specified rate (default is -1, means no resample).
	@param preset One of LQP_XXX presets. Default is LQP_NOPRESET.

	@return BE_ERR_SUCCESSFUL in case encoder was successully initialized
    }
    function open(bitrate: int = 128; cbr: bool = true; resample: int = -1; preset: int = LQP_NOPRESET): int;
    {*
	Initializates and open the encoder for VBR.

	@param minBitrate Desired minimal bitrate.
	@param maxBitrate Desired maximum bitrate.
	@param quality Desired quality from 0 to 10.
	@param resample Resample input stream to specified sampling rate (default is -1, means no resample).
	@param preset One of LQP_XXX presets. Default is LQP_NOPRESET.

	@return BE_ERR_SUCCESSFUL in case encoder was successully initialized
    }
    function openVBR(minBitrate: int = 96; maxBitrate: int = 256; quality: int = 8; resample: int = -1; preset: int = LQP_NOPRESET): int;
    {*
    }
    function encode(data: pointer; len: int): int;
    {*
    }
    function flush(locked: bool = true): int;
    {*
    }
    procedure close();
    //
    // -- properties --
    //
    property nSamplesPerSecond: unsigned read f_nSps write f_nSps;
    property nNumChannels: unsigned read f_nCh write f_nCh;
    //
    property bCopyright: bool read f_bCopy write f_bCopy;
    property bPrivate: bool read f_bPrivate write f_bPrivate;
    property bOriginal: bool read f_bOriginal write f_bOriginal;
    //
    property nMPEG: unsigned read f_mpeg write f_mpeg;
    //
    property active: bool read f_active;
    {*
    }
    property libOK: bool read f_libOK;
  end;

{*
  Loads a Lame DLL.
  Returns 0 if successuf, or Windows specific error code.
}
function lame_loadDLL(var lameProc: tLameLibrary_proc; const pathAndName: wString = c_lameEncDLL): int;

{*
  Unloads Lame DLL.
  Returns 0 if successuf, or Windows specific error code.
}
function lame_unloadDLL(var lameProc: tLameLibrary_proc): int;


implementation


uses
  unaUtils, unaWave;


// ============= Blade ========================

// --  --
function blade_loadDLL(var bladeProc: tBladeLibrary_proc; const pathAndName: wString): int;
var
  libFile: wString;
begin
  with bladeProc do begin
    //
    if (0 = r_be_module) then begin
      //
      r_be_module := 1;	// not zero
      //
      libFile := trimS(pathAndName);
      if ('' = libFile) then
	libFile := c_bladeEncDLL;
      //
{$IFNDEF NO_ANSI_SUPPORT }
      if (g_wideApiSupported) then
{$ENDIF NO_ANSI_SUPPORT }
        result := LoadLibraryW(pwChar(libFile))
{$IFNDEF NO_ANSI_SUPPORT }
      else
        result := LoadLibraryA(paChar(aString(libFile)));
{$ENDIF NO_ANSI_SUPPORT }
      ;
      if (0 = result) then begin
        //
	result := GetLastError();
	r_be_module := 0;
      end
      else begin
        //
	r_be_module := result;
	//
	@r_beInitStream   := Windows.GetProcAddress(r_be_module, 'beInitStream');
	@r_beEncodeChunk  := Windows.GetProcAddress(r_be_module, 'beEncodeChunk');
	@r_beDeinitStream := Windows.GetProcAddress(r_be_module, 'beDeinitStream');
	@r_beCloseStream  := Windows.GetProcAddress(r_be_module, 'beCloseStream');
	@r_beVersion      := Windows.GetProcAddress(r_be_module, 'beVersion');
	//
	r_be_moduleRefCount := 1;	// also, makes it not zero
					// (see below for mscand)
	//
	if (nil <> mscanp(@bladeProc, nil, sizeOf(bladeProc))) then begin
          //
	  // something is missing, close the library
	  FreeLibrary(r_be_module);
	  r_be_module := 0;
	  result := -1;
	end
	else
	  result := 0;
      end;
    end
    else begin
      //
      if (0 < r_be_moduleRefCount) then
	inc(r_be_moduleRefCount);
      //
      result := 0;
    end;
  end;
end;

//
function blade_unloadDLL(var bladeProc: tBladeLibrary_proc): int;
begin
  result := 0;
  //
  with bladeProc do begin
    //
    if (0 <> r_be_module) then begin
      //
      if (0 < r_be_moduleRefCount) then
	dec(r_be_moduleRefCount);
      //
      if (1 > r_be_moduleRefCount) then begin
	//
	if (Windows.freeLibrary(r_be_module)) then
	  fillChar(bladeProc, sizeOf(bladeProc), 0)
	else
	  result := Windows.getLastError();
      end;
    end;
  end;  
end;

// --  --
function checkBladeDllProc(const bladeProc: tBladeLibrary_proc): BE_ERR;
begin
  if (0 = bladeProc.r_be_module) then
    result := UNA_ENCODER_ERR_NO_DLL
  else
    result := BE_ERR_SUCCESSFUL;
end;

// --  --
function beInitStream(const bladeProc: tBladeLibrary_proc; config: PBE_CONFIG; out nSamples: DWORD; out minOutputBufSize: DWORD; out stream: HBE_STREAM): BE_ERR;
begin
  result := checkBladeDllProc(bladeProc);
  //
  if (BE_ERR_SUCCESSFUL = result) then
    result := bladeProc.r_beInitStream(config, nSamples, minOutputBufSize, stream);
end;

// --  --
function beEncodeChunk(const bladeProc: tBladeLibrary_proc; stream: HBE_STREAM; nSamples: DWORD; samplesBuf: pointer; outputBuf: pointer; out outputUsed: DWORD): BE_ERR;
begin
  result := checkBladeDllProc(bladeProc);
  //
  if (BE_ERR_SUCCESSFUL = result) then
    result := bladeProc.r_beEncodeChunk(stream, nSamples, samplesBuf, outputBuf, outputUsed);
end;

// --  --
function beDeinitStream(const bladeProc: tBladeLibrary_proc; stream: HBE_STREAM; outputBuf: pointer; out outputUsed: DWORD): BE_ERR;
begin
  result := checkBladeDllProc(bladeProc);
  //
  if (BE_ERR_SUCCESSFUL = result) then
    result := bladeProc.r_beDeinitStream(stream, outputBuf, outputUsed);
end;

// --  --
function beCloseStream(const bladeProc: tBladeLibrary_proc; stream: HBE_STREAM): BE_ERR;
begin
  result := checkBladeDllProc(bladeProc);
  //
  if (BE_ERR_SUCCESSFUL = result) then
    result := bladeProc.r_beCloseStream(stream);
end;

// --  --
function beVersion(const bladeProc: tBladeLibrary_proc; out version: BE_VERSION): bool;
begin
  if (BE_ERR_SUCCESSFUL = checkBladeDllProc(bladeProc)) then begin
    bladeProc.r_beVersion(version);
    result := true;
  end
  else
    result := false;
end;


// ============= Lame ========================

// --  --
function lame_loadDLL(var lameProc: tLameLibrary_proc; const pathAndName: wString): int;
var
  libFile: wString;
begin
  with lameProc do begin
    //
    if (0 = r_lame_module) then begin
      //
      r_lame_module := 1;
      //
      libFile := trimS(pathAndName);
      if ('' = libFile) then
	libFile := c_lameEncDLL;
      //
{$IFNDEF NO_ANSI_SUPPORT }
      if (g_wideApiSupported) then
{$ENDIF NO_ANSI_SUPPORT }
        result := Windows.loadLibraryW(pwChar(libFile))
{$IFNDEF NO_ANSI_SUPPORT }
      else
	result := Windows.loadLibraryA(paChar(aString(libFile)));
{$ENDIF NO_ANSI_SUPPORT }
      ;
      if (0 = result) then begin
	result := Windows.GetLastError();
	r_lame_module := 0;
      end
      else begin
	r_lame_module := result;
	//
	r_lameInitStream  := Windows.GetProcAddress(r_lame_module, 'beInitStream');
	r_lameEncodeChunk := Windows.GetProcAddress(r_lame_module, 'beEncodeChunk');
	r_lameDeinitStream:= Windows.GetProcAddress(r_lame_module, 'beDeinitStream');
	r_lameCloseStream := Windows.GetProcAddress(r_lame_module, 'beCloseStream');
	r_lameVersion     := Windows.GetProcAddress(r_lame_module, 'beVersion');
	r_lameWriteVBRHeader := Windows.GetProcAddress(r_lame_module, 'beWriteVBRHeader');
	//

	r_lame_moduleRefCount := 1;	// also, makes it not zero
					// (see below for mscand)
	//
	if (nil <> mscanp(@lameProc, nil, sizeOf(lameProc))) then begin
	  // something is missing, close the library
	  Windows.freeLibrary(r_lame_module);
	  r_lame_module := 0;
	  result := -1;
	end
	else
	  result := 0;
      end;
    end
    else begin
      if (0 < r_lame_moduleRefCount) then
	inc(r_lame_moduleRefCount);
      //
      result := 0;
    end;
  end;
end;

//
function lame_unloadDLL(var lameProc: tLameLibrary_proc): int;
begin
  result := 0;
  //
  with lameProc do begin
    //
    if (0 <> r_lame_module) then begin
      //
      if (0 < r_lame_moduleRefCount) then
	dec(r_lame_moduleRefCount);
      //
      if (1 > r_lame_moduleRefCount) then begin
	//
	if (Windows.freeLibrary(r_lame_module)) then
	  fillChar(lameProc, sizeOf(lameProc), 0)
	else
	  result := Windows.getLastError();
      end;
    end;
  end;
end;

// --  --
function checkLameDllProc(const lameProc: tLameLibrary_proc): BE_ERR;
begin
  if (0 = lameProc.r_lame_module) then
    result := UNA_ENCODER_ERR_NO_DLL
  else
    result := BE_ERR_SUCCESSFUL;
end;

// --  --
function lameInitStream(const lameProc: tLameLibrary_proc; config: PBE_CONFIG_FORMATLAME; out nSamples: DWORD; out minOutputBufSize: DWORD; out stream: HBE_STREAM): BE_ERR;
begin
  result := checkLameDllProc(lameProc);
  //
  if (BE_ERR_SUCCESSFUL = result) then
    result := lameProc.r_lameInitStream(PBE_CONFIG(config), nSamples, minOutputBufSize, stream);
end;

// --  --
function lameEncodeChunk(const lameProc: tLameLibrary_proc; stream: HBE_STREAM; nSamples: DWORD; samplesBuf: pointer; outputBuf: pointer; out outputUsed: DWORD): BE_ERR;
begin
  result := checkLameDllProc(lameProc);
  //
  if (BE_ERR_SUCCESSFUL = result) then
    result := lameProc.r_lameEncodeChunk(stream, nSamples, samplesBuf, outputBuf, outputUsed);
end;

// --  --
function lameDeinitStream(const lameProc: tLameLibrary_proc; stream: HBE_STREAM; outputBuf: pointer; out outputUsed: DWORD): BE_ERR;
begin
  result := checkLameDllProc(lameProc);
  //
  if (BE_ERR_SUCCESSFUL = result) then
    result := lameProc.r_lameDeinitStream(stream, outputBuf, outputUsed);
end;

// --  --
function lameCloseStream(const lameProc: tLameLibrary_proc; stream: HBE_STREAM): BE_ERR;
begin
  result := checkLameDllProc(lameProc);
  //
  if (BE_ERR_SUCCESSFUL = result) then
    result := lameProc.r_lameCloseStream(stream);
end;

// --  --
function lameVersion(const lameProc: tLameLibrary_proc; out version: BE_VERSION): bool;
begin
  if (BE_ERR_SUCCESSFUL = checkLameDllProc(lameProc)) then begin
    lameProc.r_lameVersion(version);
    result := true;
  end
  else
    result := false;
end;

// --  --
function lameWriteVBRHeader(const lameProc: tLameLibrary_proc; const fileName: aString): BE_ERR;
begin
  result := checkLameDllProc(lameProc);
  //
  if (BE_ERR_SUCCESSFUL = result) then
    result := lameProc.r_lameWriteVBRHeader(paChar(fileName));
end;


{ unaLameEncoder }

// --  --
procedure unaLameEncoder.BeforeDestruction();
begin
  close();
  //
  inherited;
  //
  mrealloc(f_buf);
end;

// --  --
function unaLameEncoder.calcFrameSize(rate: int): int;
begin
  case (rate) of

    44100,
    48000,
    32000: result := 1152;

    else
	   result := 576;
  end;
end;

// --  --
procedure unaLameEncoder.close();
begin
  if (acquire(false, 100, false {$IFDEF DEBUG }, '.close()' {$ENDIF DEBUG } )) then try
    //
    if (0 <> f_stream) then begin
      //
      flush();
      //
      f_proc.r_lameCloseStream(f_stream);
      f_stream := 0;
    end;
    //
    mrealloc(f_buf);
  finally
    releaseWO();
  end;
end;

// --  --
constructor unaLameEncoder.create(const libName: string);
begin
  f_libOK := (0 = lame_loadDLL(f_proc, libName));
  //
  bCopyright := false;
  bPrivate := false;
  bOriginal := false;
  //
  nMPEG := MPEG1;
  //
  nSamplesPerSecond := 44100;
  nNumChannels := 2;
  //
  inherited create();
end;

// --  --
function unaLameEncoder.encode(data: pointer; len: int): int;
var
  samples, ns: DWORD;
  nOutBufUsed: DWORD;
begin
  result := BE_ERR_INVALID_HANDLE;
  if (active and acquire(false, 100)) then try
    //
    if (1 < len) then begin
      //
      samples := len shr 1;
      //
      result := BE_ERR_SUCCESSFUL;
      while (0 < samples) do begin
	//
	ns := min(samples, f_nSamplesPerChunk);
	nOutBufUsed := 0;
	//
	result := f_proc.r_lameEncodeChunk(f_stream, ns, data, f_buf, nOutBufUsed);
	if (BE_ERR_SUCCESSFUL = result) then begin
	  //
	  f_gotAnyData := true;
	  if (0 < nOutBufUsed) then
	    onEncodedData(f_frameSize, f_buf, nOutBufUsed);
	end
	else
	  break;
	//
	dec(samples, ns);
	data := @pArray(data)[ns shl 1];
      end;
    end
    else
      result := BE_ERR_BUFFER_TOO_SMALL;
    //
  finally
    releaseWO();
  end;
end;

// --  --
function unaLameEncoder.flush(locked: bool): int;
var
  nOutBufUsed: DWORD;
begin
  result := BE_ERR_INVALID_HANDLE;
  if (locked or acquire(false, 100)) then try
    //
    if (active and f_gotAnyData) then begin
      //
      result := f_proc.r_lameDeinitStream(f_stream, f_buf, nOutBufUsed);
      if ((BE_ERR_SUCCESSFUL = result) and (0 < nOutBufUsed)) then
	onEncodedData(f_frameSize, f_buf, nOutBufUsed);
    end
    else
      result := BE_ERR_SUCCESSFUL;
    //
  finally
    if (not locked) then
      releaseWO();
  end;
end;

// --  --
procedure unaLameEncoder.getVer(var ver: BE_VERSION);
begin
  f_proc.r_lameVersion(ver);
end;

// --  --
procedure unaLameEncoder.onEncodedData(sampleDelta: uint; data: pointer; len: uint);
begin
  // override to receive the data
end;

// --  --
function unaLameEncoder.open(bitrate: int; cbr: bool; resample, preset: int): int;
var
  cfg: BE_CONFIG_FORMATLAME;
begin
  close();
  //
  result := BE_ERR_INVALID_HANDLE;
  if (acquire(false, 100, false {$IFDEF DEBUG }, '.open()' {$ENDIF DEBUG })) then try
    //
    fillChar(cfg, sizeof(tBE_CONFIG_LHV1), #0);
    cfg.dwConfig := BE_CONFIG_LAME;
    with cfg.r_lhv1 do begin
      //
      dwStructVersion := CURRENT_STRUCT_VERSION;
      dwStructSize := sizeof(BE_CONFIG_FORMATLAME);
      dwSampleRate := nSamplesPerSecond;
      if (0 > resample) then
	dwReSampleRate := nSamplesPerSecond
      else
	dwReSampleRate := resample;
      //
      if (1 < nNumChannels) then
	nMode := BE_MP3_MODE_STEREO
      else
	nMode := BE_MP3_MODE_MONO;
      //
      dwBitrate := bitrate;
      dwMaxBitrate := bitrate;
      //
      if (LQP_NOPRESET = preset) then
	preset := choice(cbr, LQP_CBR, int(LQP_ABR));
      //
      nPreset := preset;
      dwMpegVersion := nMPEG;
      //
      bPrivate := self.bPrivate;
      bCRC := false;
      bCopyright := self.bCopyright;
      bOriginal := self.bOriginal;
      //
      bWriteVBRHeader := false;
      bEnableVBR := false;
      nVbrMethod := choice(cbr, VBR_METHOD_NONE, VBR_METHOD_ABR);
      //
      if (cbr) then
      else
	dwVbrAbr_bps := bitrate;
      //
      bNoRes := true;
      bStrictIso := false;
    end;
    //
    result := f_proc.r_lameInitStream(PBE_CONFIG(@cfg), f_nSamplesPerChunk, f_minOutBufSize, f_stream);
    f_active := (BE_ERR_SUCCESSFUL = result);
    if (active) then begin
      //
      f_gotAnyData := false;
      mrealloc(f_buf, f_minOutBufSize);
      f_frameSize := calcFrameSize(cfg.r_lhv1.dwReSampleRate);
    end
    else
      close();
  finally
    releaseWO();
  end;
end;

// --  --
function unaLameEncoder.openVBR(minBitrate, maxBitrate, quality, resample, preset: int): int;
var
  cfg: BE_CONFIG_FORMATLAME;
begin
  close();
  //
  result := BE_ERR_INVALID_HANDLE;
  if (acquire(false, 100)) then try
    //
    fillChar(cfg, sizeof(tBE_CONFIG_LHV1), #0);
    cfg.dwConfig := BE_CONFIG_LAME;
    with cfg.r_lhv1 do begin
      //
      dwStructVersion := CURRENT_STRUCT_VERSION;
      dwStructSize := sizeof(BE_CONFIG_FORMATLAME);
      dwSampleRate := nSamplesPerSecond;
      if (0 > resample) then
	dwReSampleRate := nSamplesPerSecond
      else
	dwReSampleRate := resample;
      //
      if (1 < nNumChannels) then
	nMode := BE_MP3_MODE_STEREO
      else
	nMode := BE_MP3_MODE_MONO;
      //
      dwBitrate := minBitrate;
      dwMaxBitrate := maxBitrate;
      //
      nPreset := preset;
      //dwMpegVersion := MPEG1;
      //
      bPrivate := self.bPrivate;
      bCRC := false;
      bCopyright := self.bCopyright;
      bOriginal := self.bOriginal;
      //
      bWriteVBRHeader := false;
      bEnableVBR := true;
      nVBRQuality := quality;
      nVbrMethod := VBR_METHOD_NEW;
      //
      bNoRes := true;
      bStrictIso := false;
    end;
    //
    result := f_proc.r_lameInitStream(PBE_CONFIG(@cfg), f_nSamplesPerChunk, f_minOutBufSize, f_stream);
    f_active := (BE_ERR_SUCCESSFUL = result);
    if (active) then begin
      //
      f_gotAnyData := false;
      mrealloc(f_buf, f_minOutBufSize);
      f_frameSize := calcFrameSize(cfg.r_lhv1.dwReSampleRate);
    end
    else
      close();
    //
  finally
    releaseWO();
  end;
end;


end.

