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

	  unaLibCELT.pas
	  libcelt Delphi wrapper

	----------------------------------------------
	  Copyright (c) 2010-2011 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 29 Nov 2010

	  modified by:
                Lake, Nov 2010
                Lake, Mar 2011

	----------------------------------------------
*)

{$I unaDef.inc }

{*
  libcelt Delphi wrapper.

  @Author Lake

	1.0.2010.11
}

unit
  unaLibCELT;

interface

uses
  Windows, unaTypes, unaClasses;


(* Copyright (c) 2007-2008 CSIRO
   Copyright (c) 2007-2009 Xiph.Org Foundation
   Copyright (c) 2008 Gregory Maxwell
   Written by Jean-Marc Valin and Gregory Maxwell *)
(**
  celt.h
  Contains all the functions for encoding and decoding audio
 *)

(*
   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions
   are met:

   - Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.

   - Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.

   - Neither the name of the Xiph.org Foundation nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
   ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
   A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE FOUNDATION OR
   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
   EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
   PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
   LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
   NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*)

//#ifndef CELT_H
//#define CELT_H

//#include "celt_types.h"

//#ifdef __cplusplus
//extern "C" {
//#endif

const
  //* Error codes */
  //** No error */
  CELT_OK		= 0;
///** An (or more) invalid argument (e.g. out of range) */
  CELT_BAD_ARG		= -1;	
  CELT_INVALID_MODE	= -2;	///** The mode struct passed is invalid */
  CELT_INTERNAL_ERROR   = -3;	///** An internal error was detected */
  CELT_CORRUPTED_DATA   = -4;	///** The data passed (e.g. compressed data to decoder) is corrupted */
  CELT_UNIMPLEMENTED    = -5;	///** Invalid/unsupported request number */
  CELT_INVALID_STATE    = -6;	///** An encoder or decoder structure is invalid or already freed */
  CELT_ALLOC_FAIL       = -7;	///** Memory allocation has failed */

  ///* Requests */
  CELT_GET_MODE_REQUEST	= 1;		///** Get the CELTMode used by an encoder or decoder */
  CELT_SET_COMPLEXITY_REQUEST	= 2;	///** Controls the complexity from 0-10 (int) */
  {* Controls the use of interframe prediction.
    0=Independent frames
    1=Short term interframe prediction allowed
    2=Long term prediction allowed
  *}
  CELT_SET_PREDICTION_REQUEST	= 4;
  //#define CELT_SET_PREDICTION(x) CELT_SET_PREDICTION_REQUEST, _celt_check_int(x)

  CELT_SET_BITRATE_REQUEST    	= 6;	///** Set the target VBR rate in bits per second(int); 0=CBR (default) */
  CELT_RESET_STATE_REQUEST	= 8;	///** Reset the encoder/decoder memories to zero*/
  CELT_RESET_STATE		= CELT_RESET_STATE_REQUEST;
  //
  CELT_SET_VBR_CONSTRAINT_REQUEST	= 10;
  CELT_SET_VBR_REQUEST			= 12;
  CELT_SET_INPUT_CLIPPING_REQUEST	= 14;

  CELT_SET_START_BAND_REQUEST	= 10000;
  CELT_SET_END_BAND_REQUEST	= 10001;
  CELT_SET_CHANNELS_REQUEST	= 10002;

  CELT_GET_LOOKAHEAD	= 1001;		///** GET the lookahead used in the current mode */
  CELT_GET_SAMPLE_RATE	= 1003;		///** GET the sample rate used in the current mode */

  CELT_GET_BITSTREAM_VERSION = 2000;	///** GET the bit-stream version for compatibility check */


type
  //
  celt_int32 = int32;

  {*
	Contains the state of an encoder. One encoder state is needed
	for each stream. It is initialised once at the beginning of the
	stream. Do *not* re-initialise the state for every frame.

	Encoder state
  }
  pCELTEncoder = ^_CELTEncoder;
  _CELTEncoder = packed record end;

  {*
	State of the decoder. One decoder state is needed for each stream.
	It is initialised once at the beginning of the stream. Do *not*
	re-initialise the state for every frame

  }
  pCELTDecoder = ^_CELTDecoder;
  _CELTDecoder = packed record end;

  {*
	The mode contains all the information necessary to create an
	encoder. Both the encoder and decoder need to be initialised
	with exactly the same mode, otherwise the quality will be very bad
  }
  pCELTMode = ^_CELTMode;
  _CELTMode = packed record end;


  //** \defgroup codec Encoding and decoding */

  //* Mode calls */

  {*
	Creates a new mode struct. This will be passed to an encoder or
	decoder. The mode MUST NOT BE DESTROYED until the encoders and
	decoders that use it are destroyed as well.

	@param Fs Sampling rate (32000 to 96000 Hz)
	@param frame_size Number of samples (per channel) to encode in each packet (even values; 64 - 512)
	@param error Returned error code (if NULL, no error will be returned)
	@return A newly created mode
  }
  proc_celt_mode_create = function (Fs: celt_int32; frame_size: int; var error: int): pCELTMode; cdecl;
  {*
	Destroys a mode struct. Only call this after all encoders and
	decoders using this mode are destroyed as well.

	@param mode Mode to be destroyed
  }
  proc_celt_mode_destroy = procedure (mode: pCELTMode); cdecl;
  {*
	Query information from a mode
  }
  proc_celt_mode_info = function (mode: pCELTMode; request: int; value: celt_int32): int; cdecl;


//* Encoder stuff */

  {*
	@return size of mode struct with custom data?
  }
  proc_celt_encoder_get_size = function (channels: int): int; cdecl;
  {*
	@return size of mode struct with custom data?
  }
  proc_celt_encoder_get_size_custom = function (mode: pCELTMode; channels: int): int; cdecl;
  {*
	Creates a new encoder state. Each stream needs its own encoder
	state (can't be shared across simultaneous streams).

	@param sampling_rate Sampling rate
	@param channels Number of channels
	@param error Returns an error code
	@return Newly created encoder state.
  }
  proc_celt_encoder_create = function (sampling_rate: int; channels: int; out error: int): pCELTEncoder; cdecl;
  {*
	Creates a new encoder state. Each stream needs its own encoder
	state (can't be shared across simultaneous streams).

	@param mode Contains all the information about the characteristics of
	 *  the stream (must be the same characteristics as used for the
	 *  decoder)
	@param channels Number of channels
	@param error Returns an error code
	@return Newly created encoder state.
  }
  proc_celt_encoder_create_custom = function (mode: pCELTMode; channels: int; out error: int): pCELTEncoder; cdecl;
  {*
	Re-initializes the encoder?
  }
  proc_celt_encoder_init = function (st: pCELTEncoder; sampling_rate: int; channels: int; out error: int): pCELTEncoder; cdecl;
  {*
	Re-initializes the encoder?
  }
  proc_celt_encoder_init_custom = function (st: pCELTEncoder; mode: pCELTMode; channels: int; out error: int): pCELTEncoder; cdecl;
  {*
	Destroys a an encoder state.

	@param st Encoder state to be destroyed
  }
  proc_celt_encoder_destroy = procedure (st: pCELTEncoder); cdecl;
  {*
	Encodes a frame of audio.

	@param st Encoder state
	@param pcm PCM audio in float format, with a normal range of ±1.0.
	 *          Samples with a range beyond ±1.0 are supported but will
	 *          be clipped by decoders using the integer API and should
	 *          only be used if it is known that the far end supports
	 *          extended dynmaic range. There must be exactly
	 *          frame_size samples per channel.
	@param compressed The compressed data is written here. This may not alias pcm or
	 *                 optional_synthesis.
	@param maxCompressedBytes Maximum number of bytes to use for compressing the frame
	 *          (can change from one frame to another)
	@return Number of bytes written to "compressed". Will be the same as
	 *       "maxCompressedBytes" unless the stream is VBR and will never be larger.
	 *       If negative, an error has occurred (see error codes). It is IMPORTANT that
	 *       the length returned be somehow transmitted to the decoder. Otherwise, no
	 *       decoding is possible.
  }
  proc_celt_encode_float = function (st: pCELTEncoder; pcm: pfloat; frame_size: int; compressed: pointer; maxCompressedBytes: int): int; cdecl;
  {*
	Encodes a frame of audio.

	@param st Encoder state
	@param pcm PCM audio in signed 16-bit format (native endian). There must be
	 *          exactly frame_size samples per channel.
	@param compressed The compressed data is written here. This may not alias pcm or
	 *                         optional_synthesis.
	@param nbCompressedBytes Maximum number of bytes to use for compressing the frame
	 *                        (can change from one frame to another)
	@return Number of bytes written to "compressed". Will be the same as
	 *       "maxCompressedBytes" unless the stream is VBR and will never be larger.
	 *       If negative, an error has occurred (see error codes). It is IMPORTANT that
	 *       the length returned be somehow transmitted to the decoder. Otherwise, no
	 *       decoding is possible.
  }
  proc_celt_encode = function (st: pCELTEncoder; pcm: pInt16array; frame_size: int; compressed: pointer; maxCompressedBytes: int): int; cdecl;
  {
	Query and set encoder parameters

	@param st Encoder state
	@param request Parameter to change or query
	@param value Pointer to a 32-bit int value
	@return Error code
  }
  proc_celt_encoder_ctl = function (st: pCELTEncoder; request: int; value: pInt32): int; cdecl;


  //* Decoder stuff */

  {*
  }
  proc_celt_decoder_get_size = function (channels: int): int; cdecl;
  {*
  }
  proc_celt_decoder_get_size_custom = function (mode: pCELTMode; channels: int): int; cdecl;
  {*
	Creates a new decoder state. Each stream needs its own decoder state (can't
	be shared across simultaneous streams).

	@param sampling_rate Sampling rate
	@param channels Number of channels
	@param error Returns an error code
	@return Newly created decoder state.
  }
  proc_celt_decoder_create = function (sampling_rate: int; channels: int; out error: int): pCELTDecoder; cdecl;
  {*
	Creates a new decoder state. Each stream needs its own decoder state (can't
	be shared across simultaneous streams).

	@param mode Contains all the information about the characteristics of the
	     stream (must be the same characteristics as used for the encoder)
	@param channels Number of channels
	@param error Returns an error code
	@return Newly created decoder state.
  }
  proc_celt_decoder_create_custom = function (mode: pCELTMode; channels: int; out error: int): pCELTDecoder; cdecl;
  {*
	Re-initializes decoder?
  }
  proc_celt_decoder_init = function (st: pCELTDecoder; sampling_rate: int; channels: int; out error: int): pCELTDecoder; cdecl;
  {*
	Re-initializes decoder?
  }
  proc_celt_decoder_init_custom = function (st: pCELTDecoder; mode: pCELTMode; channels: int; out error: int): pCELTDecoder; cdecl;
  {*
	Destroys a a decoder state.

	@param st Decoder state to be destroyed
  }
  proc_celt_decoder_destroy = procedure (st: pCELTDecoder); cdecl;
  {*
	Decodes a frame of audio.

	@param st Decoder state
	@param data Compressed data produced by an encoder
	@param len Number of bytes to read from "data". This MUST be exactly the number
	    of bytes returned by the encoder. Using a larger value WILL NOT WORK.
	@param pcm One frame (frame_size samples per channel) of decoded PCM will be
	    returned here in float format.
	@return Error code.
  }
  proc_celt_decode_float = function (st: pCELTDecoder; data: pointer; len: int; pcm: pFloat; frame_size: int): int; cdecl;
  {*
	Decodes a frame of audio.

	@param st Decoder state
	@param data Compressed data produced by an encoder
	@param len Number of bytes to read from "data". This MUST be exactly the number
	    of bytes returned by the encoder. Using a larger value WILL NOT WORK.
	@param pcm One frame (frame_size samples per channel) of decoded PCM will be
	    returned here in 16-bit PCM format (native endian).
	@return Error code.
  }
  proc_celt_decode = function (st: pCELTDecoder; data: pointer; len: int; pcm: pInt16array; frame_size: int): int; cdecl;
  {*
	Query and set decoder parameters

	@param st Decoder state
	@param request Parameter to change or query
	@param value Pointer to a 32-bit int value
	@return Error code
  }
  proc_celt_decoder_ctl = function (st: pCELTDecoder; request: int; value: pInt32): int; cdecl;


  {*
	Returns the English string that corresponds to an error code

	@param error Error code (negative for an error, 0 for success
	@return Constant string (must NOT be freed)
  }
  proc_celt_strerror = function (error: int): paChar; cdecl;


// #endif /*CELT_H */


type
  punaLibCELTAPI = ^unaLibCELTAPI;
  unaLibCELTAPI = record
    //
    r_module: hModule;
    r_moduleRefCount: int;
    //
    r_celt_mode_create:           	proc_celt_mode_create;
    r_celt_mode_destroy:          	proc_celt_mode_destroy;
    //r_celt_mode_info:             	proc_celt_mode_info;
    //
    r_celt_encoder_get_size:      	proc_celt_encoder_get_size;
    r_celt_encoder_create:        	proc_celt_encoder_create;
    r_celt_encoder_init:          	proc_celt_encoder_init;
    r_celt_encoder_destroy:       	proc_celt_encoder_destroy;
    r_celt_encode_float:          	proc_celt_encode_float;
    r_celt_encode:                	proc_celt_encode;
    r_celt_encoder_ctl:           	proc_celt_encoder_ctl;
    r_celt_encoder_get_size_custom:	proc_celt_encoder_get_size_custom;
    r_celt_encoder_create_custom: 	proc_celt_encoder_create_custom;
    r_celt_encoder_init_custom:	  	proc_celt_encoder_init_custom;
    //
    r_celt_decoder_get_size:      	proc_celt_decoder_get_size;
    r_celt_decoder_create:        	proc_celt_decoder_create;
    r_celt_decoder_init:          	proc_celt_decoder_init;
    r_celt_decoder_destroy:       	proc_celt_decoder_destroy;
    r_celt_decode_float:          	proc_celt_decode_float;
    r_celt_decode:                	proc_celt_decode;
    r_celt_decoder_ctl:           	proc_celt_decoder_ctl;
    r_celt_decoder_get_size_custom:	proc_celt_decoder_get_size_custom;
    r_celt_decoder_create_custom: 	proc_celt_decoder_create_custom;
    r_celt_decoder_init_custom:	  	proc_celt_decoder_init_custom;
    //
    r_celt_strerror:              	proc_celt_strerror;
  end;


  {*
	Data avail event.
  }
  unaLibCELTcoderDataAvail = procedure(sender: unaObject; data: pointer; len: int) of object;


  {*
	Base abstract libcelt coder.
  }
  unaLibCELTcoder = class(unaObject)
  private
    //f_mode: pCELTMode;
    //
    f_rate: int;
    f_frameSize2: int;
    f_channels: int;
    //
    f_libOK: bool;
    //
    f_lastError: int;
    f_onDataAvail: unaLibCELTcoderDataAvail;
    //
    f_active: bool;
    //
    function getProc(): punaLibCELTAPI;
    procedure setFrameSize(value: int);
  protected
    //
    f_proc: unaLibCELTAPI;
    f_frameSizeBytes: int;
    //
    {*
	Opens the coder.
    }
    function doOpen(): int; virtual; abstract;
    {*
	Closes the coder.
    }
    procedure doClose(); virtual; abstract;
    {*
	IOCTL the coder.
    }
    function doIOCTL(req: int; var value: int32): int; virtual; abstract;
    {*
	Called when encoder or decoder is ready with new portion of data.
    }
    procedure doDataAvail(data: pointer; size: int); virtual;
    {*
	DLL Re-entrance lock.
    }
    function lock(timeout: tTimeout = 100): bool;
    {*
	DLL Re-entrance unlock.
    }
    procedure unlock();
  public
    {*
	Loads library and initializes the coder with specified parameters.
	Aborts with exception if library was not loaded.

	@param rate Sampling rate, from 8000 to 96000.
	@param frame_size Frame size is samples (per channel), must be even (and should divide on 80?)
	@param channels Number of channels, 1 for mono, 2 for stereo
	@param libname Library file name
    }
    constructor create(rate: int = 24000; frame_size: int = 480; channels: int = 1; const libname: string = '');
    {*
    }
    procedure BeforeDestruction(); override;
    {*
	Initializes the coder with parameters specified upon creation or previois open().

	@return 0 if succeeded, negative value otherwise (see CELT_ error codes).
    }
    function open(): int; overload;
    {*
	Initializes the coder with specified parameters.

	@param rate Sampling rate, from 32000 to 96000.
	@param frame_size Frame size is samples (per channel), must be even (and should divide on 80?)
	@param channels Number of channels, 1 for mono, 2 for stereo
	@param libname Library file name

	@return 0 if succeeded, negative value otherwise (see CELT_ error codes).
    }
    function open(rate: int; frame_size: int = 480; channels: int = 1): int; overload;
    {*
	Releases the coder resources.
    }
    procedure close();
    {*
	Query and set coder parameters.

	@param req Parameter to change or query
	@param value In/Out value

	@return Error code
    }
    function IOCTL(req: int; var value: int32): int;
    {*
	libcelt API
    }
    property proc: punaLibCELTAPI read getProc;
    {*
	sampling rate
    }
    property pcm_rate: int read f_rate;
    {*
	number of channels
    }
    property pcm_channels: int read f_channels;
    {*
	frame size in samples (per channel)
    }
    property frameSize: int read f_frameSize2 write setFrameSize;
    {*
	True if liblary was loaded
    }
    property libOK: bool read f_libOK;
    {*
	Last error (shared for all threads!)
    }
    property lastError: int read f_lastError;	/// Result of last operation.
    {*
	True if coder is opened
    }
    property active: bool read f_active;	/// True when coder was successfully open.
    {*
	Fired for each new chunk of audio
    }
    property onDataAvail: unaLibCELTcoderDataAvail read f_onDataAvail write f_onDataAvail;
  end;


  {*
	libcelt encoder.
  }
  unaLibCELTencoder = class(unaLibCELTcoder)
  private
    f_subBufPCM: pointer;
    f_subBufPCMPos: int;
    //
    f_subBufCompressed: pointer;
    f_subBufCompressedSize: int;
    //
    f_enc: pCELTEncoder;
    //
    f_bitrate: int;
    f_bitrateAuto: bool;
    //
    procedure updateBPF();
    //
    procedure setBitrate(value: int);
  protected
    {*
    }
    function doOpen(): int; override;
    {*
    }
    procedure doClose(); override;
    {*
    }
    function doIOCTL(req: int; var value: int32): int; override;
    {*
	Fills sub-buffer with data.

	@return number of bytes consumed by encoder on this call.
    }
    function write(data: pointer; len: int): int;
  public
    {*
	Encodes a frame of audio. Data will be notified via doDataAvail()/onDataAvail.

	@param pcm PCM audio in signed 16-bit format (native endian).
	@param len Number of bytes in pcm.

	@return Error code.
    }
    function encode(pcm: pointer; len: int): int;
    {*
	Desired bitrate, in kbps (24-120 for mono, 40-160 for stereo).
    }
    property bitrate: int read f_bitrate write setBitrate;
  end;


  {*
	libcelt decoder.
  }
  unaLibCELTdecoder = class(unaLibCELTcoder)
  private
    f_bufPCM: pointer;
    f_dec: pCELTdecoder;
  protected
    {*
    }
    function doOpen(): int; override;
    {*
    }
    procedure doClose(); override;
    {*
    }
    function doIOCTL(req: int; var value: int32): int; override;
  public
    {*
	Decodes a frame of audio. Data will be notified via doDataAvail()/onDataAvail.

	@param data Compressed data produced by an encoder
	@param len Number of bytes to read from "data". This MUST be exactly the number of bytes returned by the encoder. Using a larger value WILL NOT WORK.

	@return Error code.
    *}
    function decode(data: pointer; len: int): int;
  end;


const
  //
  c_libceltDLL	= 'libcelt.dll';

{*
  Loads the CELT DLL.

  @return 0 if successuf, -1 is some API is missing or Windows specific error code.
}
function celt_loadDLL(var proc: unaLibCELTAPI; const pathAndName: wString = c_libceltDLL): int;

{*
  Unloads the CELT DLL.

  @return 0 if successuf, or Windows specific error code.
}
function celt_unloadDLL(var proc: unaLibCELTAPI): int;


implementation


uses
  unaUtils;

var
  g_libCeltReentryLock: unaObject;

// --  --
function celt_loadDLL(var proc: unaLibCELTAPI; const pathAndName: wString = c_libceltDLL): int;
var
  libFile: wString;
begin
  with proc do begin
    //
    if (0 = r_module) then begin
      //
      r_module := 1;	// not zero
      //
      libFile := trimS(pathAndName);
      if ('' = libFile) then
	libFile := c_libceltDLL;
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
	r_module := 0;
      end
      else begin
	//
	r_module := result;
	//
	// map DLL entries
	r_celt_mode_create	:= GetProcAddress(r_module, 'celt_mode_create');
	r_celt_mode_destroy	:= GetProcAddress(r_module, 'celt_mode_destroy');
	//r_celt_mode_info	:= GetProcAddress(r_module, 'celt_mode_info');
	//
	r_celt_encoder_get_size	:= GetProcAddress(r_module, 'celt_encoder_get_size');
	r_celt_encoder_create	:= GetProcAddress(r_module, 'celt_encoder_create');
	r_celt_encoder_init	:= GetProcAddress(r_module, 'celt_encoder_init');
	r_celt_encoder_destroy	:= GetProcAddress(r_module, 'celt_encoder_destroy');
	r_celt_encode_float	:= GetProcAddress(r_module, 'celt_encode_float');
	r_celt_encode		:= GetProcAddress(r_module, 'celt_encode');
	r_celt_encoder_ctl	:= GetProcAddress(r_module, 'celt_encoder_ctl');
	r_celt_encoder_get_size_custom	:= GetProcAddress(r_module, 'celt_encoder_get_size_custom');
	r_celt_encoder_create_custom	:= GetProcAddress(r_module, 'celt_encoder_create_custom');
	r_celt_encoder_init_custom	:= GetProcAddress(r_module, 'celt_encoder_init_custom');
	//
	r_celt_decoder_get_size	:= GetProcAddress(r_module, 'celt_decoder_get_size');
	r_celt_decoder_create	:= GetProcAddress(r_module, 'celt_decoder_create');
	r_celt_decoder_init	:= GetProcAddress(r_module, 'celt_decoder_init');
	r_celt_decoder_destroy	:= GetProcAddress(r_module, 'celt_decoder_destroy');
	r_celt_decode_float	:= GetProcAddress(r_module, 'celt_decode_float');
	r_celt_decode		:= GetProcAddress(r_module, 'celt_decode');
	r_celt_decoder_ctl	:= GetProcAddress(r_module, 'celt_decoder_ctl');
	r_celt_decoder_get_size_custom	:= GetProcAddress(r_module, 'celt_decoder_get_size_custom');
	r_celt_decoder_create_custom	:= GetProcAddress(r_module, 'celt_decoder_create_custom');
	r_celt_decoder_init_custom	:= GetProcAddress(r_module, 'celt_decoder_init_custom');
	//
	r_celt_strerror		:= GetProcAddress(r_module, 'celt_strerror');
	//
	r_moduleRefCount := 1;	// also, makes it non-zero (see below mscand)
	if (nil <> mscanp(@proc, nil, sizeof(unaLibCELTAPI))) then begin
	  //
	  // something is missing, close the library
	  FreeLibrary(r_module);
	  r_module := 0;
	  result := -1;
	end
	else
	  result := 0;
      end;
    end
    else begin
      //
      if (0 < r_moduleRefCount) then
	inc(r_moduleRefCount);
      //
      result := 0;
    end;
  end;
end;

// --  --
function celt_unloadDLL(var proc: unaLibCELTAPI): int;
begin
  result := 0;
  with proc do begin
    //
    if (0 <> r_module) then begin
      //
      if (0 < r_moduleRefCount) then
	dec(r_moduleRefCount);
      //
      if (1 > r_moduleRefCount) then begin
	//
	if (FreeLibrary(r_module)) then
	  fillChar(proc, sizeof(unaLibCELTAPI), 0)
	else
	  result := GetLastError();
	//
      end;
    end;
  end;
end;


{ unaLibCELTcoder }

// --  --
procedure unaLibCELTcoder.BeforeDestruction();
begin
  inherited;
  //
  close();
  //
  if (libOK) then
    celt_unloadDLL(f_proc);
end;

// --  --
procedure unaLibCELTcoder.close();
begin
  if (libOK and lock(1000)) then try
    //
    if (active) then begin
      //
      f_active := false;
      doClose();
    end;
    //
    {
    if (nil <> f_mode) then begin
      //
      f_proc.r_celt_mode_destroy(f_mode);
      f_mode := nil;
    end;
    }
    //
  finally
    unlock();
  end;
end;

// --  --
constructor unaLibCELTcoder.create(rate, frame_size, channels: int; const libname: string);
begin
  f_libOK := (0 = celt_loadDLL(f_proc, libname));
  //
  inherited create();
  //
  if (f_libOK) then
    open(rate, frame_size, channels);
end;

// --  --
procedure unaLibCELTcoder.doDataAvail(data: pointer; size: int);
begin
  if (assigned(f_onDataAvail)) then
    f_onDataAvail(self, data, size);
end;

// --  --
function unaLibCELTcoder.getProc(): punaLibCELTAPI;
begin
  result := @f_proc;
end;

// --  --
function unaLibCELTcoder.IOCTL(req: int; var value: int32): int;
begin
  result := doIOCTL(req, value);
  f_lastError := result;
end;

// --  --
function unaLibCELTcoder.lock(timeout: tTimeout): bool;
begin
  result := g_libCeltReentryLock.acquire(false, timeout, false {$IFDEF DEBUG }, '.lock()' {$ENDIF DEBUG });
end;

// --  --
function unaLibCELTcoder.open(): int;
begin
  if (libOK and lock(1000)) then try
    //
    if (not active) then begin
      //
      if (frameSize <> 320 * (frameSize div 320)) then begin
	//
	if (1024 < frameSize) then
	  frameSize := 1024;
      end;
      //
      //f_mode := f_proc.r_celt_mode_create(pcm_rate, pcm_frameSize, f_lastError);
      if (CELT_OK = f_lastError) then
	result := doOpen()
      else
	result := f_lastError;
    end
    else
      result := CELT_OK;	// already open
    //
    f_lastError := result;
    //
    f_active := (CELT_OK = f_lastError);
    //
  finally
    unlock();
  end
  else
    result := CELT_INVALID_MODE;
end;

// --  --
function unaLibCELTcoder.open(rate, frame_size, channels: int): int;
begin
  if (libOK and lock(1000)) then try
    //
    if (active) then
      close();
    //
    f_rate := rate;
    f_channels := channels;
    //
    frameSize := frame_size;
    //
    result := open();
  finally
    unlock();
  end
  else
    result := CELT_INVALID_MODE;
end;

// --  --
procedure unaLibCELTcoder.setFrameSize(value: int);
begin
  f_frameSize2 := value;
  f_frameSizeBytes := frameSize shl 1 * pcm_channels;
end;

// --  --
procedure unaLibCELTcoder.unlock();
begin
  g_libCeltReentryLock.releaseWO();
end;


{ unaLibCELTencoder }

// --  --
procedure unaLibCELTencoder.doClose();
begin
  if (libOK and lock()) then try
    //
    f_proc.r_celt_encoder_destroy(f_enc);
    f_enc := nil;
    //
    mrealloc(f_subBufPCM);
    mrealloc(f_subBufCompressed);
    //
    if (f_bitrateAuto) then begin
      //
      f_bitrate := 0;
      f_bitrateAuto := false;
    end;
    //
  finally
    unlock();
  end;
end;

// --  --
function unaLibCELTencoder.doIOCTL(req: int; var value: int32): int;
begin
  if ((nil <> f_enc) and libOK and lock()) then try
    result := f_proc.r_celt_encoder_ctl(f_enc, req, @value)
  finally
    unlock();
  end
  else
    result := CELT_INTERNAL_ERROR;
end;

// --  --
function unaLibCELTencoder.doOpen(): int;
begin
  result := CELT_ALLOC_FAIL;
  //
  if (libOK and lock()) then try
    //
    f_subBufPCMPos := 0;
    mrealloc(f_subBufPCM, f_frameSizeBytes);
    //
    //f_enc := f_proc.r_celt_encoder_create_custom(f_mode, pcm_channels, result);
    f_enc := f_proc.r_celt_encoder_create(pcm_rate, pcm_channels, result);
    //
    if ((0 = bitrate) and (CELT_OK = result)) then begin
      //
      f_bitrate := (pcm_rate * pcm_channels shl 1) shr 10;	// in kbps
      f_bitrateAuto := true;
      //
      updateBPF();
    end;
    //
  finally
    unlock();
  end;
end;

// --  --
function unaLibCELTencoder.encode(pcm: pointer; len: int): int;
begin
  result := 0;
  if (libOK and lock()) then try
    //
    if (active and (nil <> pcm) and (0 < len)) then
      result := write(pcm, len)
  finally
    unlock();
  end;
end;

// --  --
procedure unaLibCELTencoder.setBitrate(value: int);
begin
  if (1 = pcm_channels) then begin
    //
    if (6 > value) then
      value := 6
    else
      if (512 < value) then
	value := 512;
  end
  else begin
    //
    if (12 > value) then
      value := 12
    else
      if (1024 < value) then
	value := 1024;
  end;
  //
  if (f_bitrate <> value) then begin
    //
    f_bitrate := value;
    f_bitrateAuto := false;
  end;
  //
  if (0 <> bitrate) then
    updateBPF();	// must be called to re-allocate buffers
end;

// --  --
procedure unaLibCELTencoder.updateBPF();
begin
  if (libOK) then begin
    //
    f_subBufCompressedSize := trunc((f_bitrate shl 7) / (pcm_rate / frameSize)) and not 1;
    //
    mrealloc(f_subBufCompressed, f_subBufCompressedSize);
  end;
end;

// --  --
function unaLibCELTencoder.write(data: pointer; len: int): int;
var
  delta, clen: int;
begin
  result := 0;
  if ((nil <> f_enc) and libOK and active and lock()) then try
    //
    // have full frame?
    if (f_frameSizeBytes <= f_subBufPCMPos + len) then begin
      //
      // buffer is empty and len is large enough?
      if ((1 > f_subBufPCMPos) and (f_frameSizeBytes <= len)) then begin
	//
	// take full frame
	delta := f_frameSizeBytes;
	//
	// do not move anything to sub-buffer, encode from data
	clen := f_proc.r_celt_encode(f_enc, data, frameSize, f_subBufCompressed, f_subBufCompressedSize);
      end
      else begin
	//
	// how much bytes are we short?
	delta := f_frameSizeBytes - f_subBufPCMPos;	// len will be >= delta, see "have full frame?" check above
	if (0 < delta) then
	  // take them from data
	  move(data^, pArray(f_subBufPCM)[f_subBufPCMPos], delta);
	//
	// encode full frame from sub-buff
	clen := f_proc.r_celt_encode(f_enc, f_subBufPCM, frameSize, f_subBufCompressed, f_subBufCompressedSize);
	//
	// reset sub-buf
	f_subBufPCMPos := 0;
      end;
      //
      if (0 < clen) then
	doDataAvail(f_subBufCompressed, clen);
      //
      inc(result, delta);
      //
      // some data left unprocessed?
      if (0 < len - delta) then
	// write the rest of data
	inc(result, write(@pArray(data)[delta], len - delta));
    end
    else begin
      // save what we have so far
      move(data^, pArray(f_subBufPCM)[f_subBufPCMPos], len);
      inc(f_subBufPCMPos, len);
    end;
    //
  finally
    unlock();
  end;
end;


{ unaLibCELTdecoder }

// --  --
function unaLibCELTdecoder.decode(data: pointer; len: int): int;
begin
  result := 0;
  //
  if ((nil <> f_dec) and libOK and lock()) then try
    //
    result := f_proc.r_celt_decode(f_dec, data, len, f_bufPCM, frameSize);
    if (CELT_OK = result) or (result = frameSize) then
      doDataAvail(f_bufPCM, f_frameSizeBytes);
    //
  finally
    unlock();
  end;
end;

// --  --
procedure unaLibCELTdecoder.doClose();
begin
  if ((nil <> f_dec) and libOK and lock()) then try
    //
    f_proc.r_celt_decoder_destroy(f_dec);
    f_dec := nil;
  finally
    unlock();
  end;
  //
  mrealloc(f_bufPCM);
end;

// --  --
function unaLibCELTdecoder.doIOCTL(req: int; var value: int32): int;
begin
  if ((nil <> f_dec) and libOK and lock()) then try
    result := f_proc.r_celt_decoder_ctl(f_dec, req, @value)
  finally
    unlock();
  end
  else
    result := CELT_INTERNAL_ERROR;
end;

// --  --
function unaLibCELTdecoder.doOpen(): int;
begin
  result := CELT_ALLOC_FAIL;
  //
  if (libOK and lock()) then try
    //
    mrealloc(f_bufPCM, f_frameSizeBytes);
    //
    //f_dec := f_proc.r_celt_decoder_create_custom(f_mode, pcm_channels, result);
    f_dec := f_proc.r_celt_decoder_create(pcm_rate, pcm_channels, result);
  finally
    unlock();
  end;
end;


initialization
  g_libCeltReentryLock := unaObject.create();

finalization
  freeAndNil(g_libCeltReentryLock);

end.

