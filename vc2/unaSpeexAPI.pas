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
	  unaSpeexAPI.pas
	----------------------------------------------
	  Speex

	  Copyright (C) 2002-2006 Jean-Marc Valin
	  http://www.speex.org/
	----------------------------------------------
	  Delphi API wrapper for Speex:

	  Copyright (c) 2010-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------
          Delphi code

	  created by:
		Lake, 27 Jan 2010

	  modified by:
		Lake, Jan-Apr 2010

	----------------------------------------------
*)

{$I unaDef.inc }

{*
  libspeex.dll wrapper.

  @Author Lake
  
Version 2.5.2010.01 Initial release

}

unit
  unaSpeexAPI;

interface

uses
  Windows, unaTypes, unaClasses;


//* Copyright (C) 2002-2006 Jean-Marc Valin*/
(**
  @file speex.h
  @brief Describes the different modes of the codec
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

//#ifndef SPEEX_H
//#define SPEEX_H
(** @defgroup Codec Speex encoder and decoder
 *  This is the Speex codec itself.
 *  @{
 *)

//#include "speex/speex_bits.h"

//* Copyright (C) 2002 Jean-Marc Valin */
(**
   @file speex_bits.h
   @brief Handles bit packing/unpacking
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

//#ifndef BITS_H
//#define BITS_H
(** @defgroup SpeexBits SpeexBits: Bit-stream manipulations
 *  This is the structure that holds the bit-stream when encoding or decoding
 * with Speex. It allows some manipulations as well.
 *  @{
 *)

type

//** Bit-packing data structure representing (part of) a bit-stream. */
  pSpeexBits = ^SpeexBits;
  SpeexBits = packed record
    chars: paChar;   //**< "raw" data */
    nbBits: int32;  //**< Total number of bits stored in the stream*/
    charPtr: int32; //**< Position of the byte "cursor" */
    bitPtr: int32;  //**< Position of the bit "cursor" within the current char */
    owner: int32;   //**< Does the struct "own" the "raw" buffer (member "chars") */
    overflow: int32;//**< Set to one if we try to read past the valid data */
    buf_size: int32;//**< Allocated size for buffer */
    reserved1: int32; //**< Reserved for future use */
    reserved2: uint32; //**< Reserved for future use */
  end;


//** Initializes and allocates resources for a SpeexBits struct */
  speex_bits_init = procedure(bits: pSpeexBits); cdecl;

//** Initializes SpeexBits struct using a pre-allocated buffer*/
  speex_bits_init_buffer = procedure(bits: pSpeexBits; buff: pointer; buf_size: int); cdecl;

//** Sets the bits in a SpeexBits struct to use data from an existing buffer (for decoding without copying data) */
  speex_bits_set_bit_buffer = procedure(bits: SpeexBits; buff: pointer; buf_size: int); cdecl;

//** Frees all resources associated to a SpeexBits struct. Right now this does nothing since no resources are allocated, but this could change in the future.*/
  speex_bits_destroy = procedure(bits: pSpeexBits); cdecl;

//** Resets bits to initial value (just after initialization, erasing content)*/
  speex_bits_reset = procedure(bits: pSpeexBits); cdecl;

//** Rewind the bit-stream to the beginning (ready for read) without erasing the content */
  speex_bits_rewind = procedure(bits: pSpeexBits); cdecl;

//** Initializes the bit-stream from the data in an area of memory */
  speex_bits_read_from = procedure(bits: pSpeexBits; buff: pointer; buf_size: int); cdecl;

(** Append bytes to the bit-stream
 *
 * @param bits Bit-stream to operate on
 * @param bytes pointer to the bytes what will be appended
 * @param len Number of bytes of append
 *)
  speex_bits_read_whole_bytes = procedure(bits: pSpeexBits; buff: pointer; buf_size: int); cdecl;

(** Write the content of a bit-stream to an area of memory
 *
 * @param bits Bit-stream to operate on
 * @param bytes Memory location where to write the bits
 * @param max_len Maximum number of bytes to write (i.e. size of the "bytes" buffer)
 * @return Number of bytes written to the "bytes" buffer
*)
  speex_bits_write = function(bits: pSpeexBits; buff: pointer; max_size: int): int; cdecl;

//** Like speex_bits_write, but writes only the complete bytes in the stream. Also removes the written bytes from the stream */
  speex_bits_write_whole_bytes = function(bits: pSpeexBits; buff: pointer; max_size: int): int; cdecl;

(** Append bits to the bit-stream
 * @param bits Bit-stream to operate on
 * @param data Value to append as integer
 * @param nbBits number of bits to consider in "data"
 *)
  speex_bits_pack = procedure(bits: pSpeexBits; data: int; nbBits: int); cdecl;

(** Interpret the next bits in the bit-stream as a signed integer
 *
 * @param bits Bit-stream to operate on
 * @param nbBits Number of bits to interpret
 * @return A signed integer represented by the bits read
 *)
  speex_bits_unpack_signed = function(bits: pSpeexBits; nbBits: int): int; cdecl;

(** Interpret the next bits in the bit-stream as an unsigned integer
 *
 * @param bits Bit-stream to operate on
 * @param nbBits Number of bits to interpret
 * @return An unsigned integer represented by the bits read
 *)
  speex_bits_unpack_unsigned = function(bits: pSpeexBits; nbBits: int): unsigned; cdecl;

(** Returns the number of bytes in the bit-stream, including the last one even if it is not "full"
 *
 * @param bits Bit-stream to operate on
 * @return Number of bytes in the stream
 *)
  speex_bits_nbytes = function(bits: pSpeexBits): int; cdecl;

(** Same as speex_bits_unpack_unsigned, but without modifying the cursor position
 *
 * @param bits Bit-stream to operate on
 * @param nbBits Number of bits to look for
 * @return Value of the bits peeked, interpreted as unsigned
 *)
  speex_bits_peek_unsigned = function(bits: pSpeexBits; nbBits: int): unsigned; cdecl;

(** Get the value of the next bit in the stream, without modifying the
 * "cursor" position
 *
 * @param bits Bit-stream to operate on
 * @return Value of the bit peeked (one bit only)
 *)
  speex_bits_peek = function(bits: pSpeexBits): int; cdecl;

(** Advances the position of the "bit cursor" in the stream
 *
 * @param bits Bit-stream to operate on
 * @param n Number of bits to advance
 *)
  speex_bits_advance = procedure(bits: pSpeexBits; n: int); cdecl;

(** Returns the number of bits remaining to be read in a stream
 *
 * @param bits Bit-stream to operate on
 * @return Number of bits that can still be read from the stream
 *)
  speex_bits_remaining = function(bits: pSpeexBits): int; cdecl;

(** Insert a terminator so that the data can be sent as a packet while auto-detecting
 * the number of frames in each packet
 *
 * @param bits Bit-stream to operate on
 *)
  speex_bits_insert_terminator = procedure(bits: pSpeexBits); cdecl;

//#endif


//#include "speex/speex_types.h"

//* speex_types.h taken from libogg */
(********************************************************************
 *                                                                  *
 * THIS FILE IS PART OF THE OggVorbis SOFTWARE CODEC SOURCE CODE.   *
 * USE, DISTRIBUTION AND REPRODUCTION OF THIS LIBRARY SOURCE IS     *
 * GOVERNED BY A BSD-STYLE SOURCE LICENSE INCLUDED WITH THIS SOURCE *
 * IN 'COPYING'. PLEASE READ THESE TERMS BEFORE DISTRIBUTING.       *
 *                                                                  *
 * THE OggVorbis SOURCE CODE IS (C) COPYRIGHT 1994-2002             *
 * by the Xiph.Org Foundation http://www.xiph.org/                  *
 *                                                                  *
 ********************************************************************

 function: #ifdef jail to whip a few platforms into the UNIX ideal.
 last mod: $Id: os_types.h 7524 2004-08-11 04:20:36Z conrad $

 ********************************************************************)
(**
   @file speex_types.h
   @brief Speex types
*)
//#ifndef _SPEEX_TYPES_H
//#define _SPEEX_TYPES_H

//#if defined(_WIN32)

type
  spx_int16_t = int16;
  pspx_int16_t = ^spx_int16_t;

  spx_uint32_t = uint32;
  spx_int32_t = int32;

(*
#  if defined(__CYGWIN__)
#    include <_G_config.h>
     typedef _G_int32_t spx_int32_t;
     typedef _G_uint32_t spx_uint32_t;
     typedef _G_int16_t spx_int16_t;
     typedef _G_uint16_t spx_uint16_t;
#  elif defined(__MINGW32__)
     typedef short spx_int16_t;
     typedef unsigned short spx_uint16_t;
     typedef int spx_int32_t;
     typedef unsigned int spx_uint32_t;
#  elif defined(__MWERKS__)
     typedef int spx_int32_t;
     typedef unsigned int spx_uint32_t;
     typedef short spx_int16_t;
     typedef unsigned short spx_uint16_t;
#  else
     /* MSVC/Borland */
     typedef __int32 spx_int32_t;
     typedef unsigned __int32 spx_uint32_t;
     typedef __int16 spx_int16_t;
     typedef unsigned __int16 spx_uint16_t;
#  endif

#elif defined(__MACOS__)

#  include <sys/types.h>
   typedef SInt16 spx_int16_t;
   typedef UInt16 spx_uint16_t;
   typedef SInt32 spx_int32_t;
   typedef UInt32 spx_uint32_t;

#elif (defined(__APPLE__) && defined(__MACH__)) /* MacOS X Framework build */

#  include <sys/types.h>
   typedef int16_t spx_int16_t;
   typedef u_int16_t spx_uint16_t;
   typedef int32_t spx_int32_t;
   typedef u_int32_t spx_uint32_t;

#elif defined(__BEOS__)

   /* Be */
#  include <inttypes.h>
   typedef int16_t spx_int16_t;
   typedef u_int16_t spx_uint16_t;
   typedef int32_t spx_int32_t;
   typedef u_int32_t spx_uint32_t;

#elif defined (__EMX__)

   /* OS/2 GCC */
   typedef short spx_int16_t;
   typedef unsigned short spx_uint16_t;
   typedef int spx_int32_t;
   typedef unsigned int spx_uint32_t;

#elif defined (DJGPP)

   /* DJGPP */
   typedef short spx_int16_t;
   typedef int spx_int32_t;
   typedef unsigned int spx_uint32_t;

#elif defined(R5900)

   /* PS2 EE */
   typedef int spx_int32_t;
   typedef unsigned spx_uint32_t;
   typedef short spx_int16_t;

#elif defined(__SYMBIAN32__)

   /* Symbian GCC */
   typedef signed short spx_int16_t;
   typedef unsigned short spx_uint16_t;
   typedef signed int spx_int32_t;
   typedef unsigned int spx_uint32_t;

#elif defined(CONFIG_TI_C54X) || defined (CONFIG_TI_C55X)

   typedef short spx_int16_t;
   typedef unsigned short spx_uint16_t;
   typedef long spx_int32_t;
   typedef unsigned long spx_uint32_t;

#elif defined(CONFIG_TI_C6X)

   typedef short spx_int16_t;
   typedef unsigned short spx_uint16_t;
   typedef int spx_int32_t;
   typedef unsigned int spx_uint32_t;

#else

#  include <speex/speex_config_types.h>

#endif

*)

//#endif  /* _SPEEX_TYPES_H */


const
//* Values allowed for *ctl() requests */

//** Set enhancement on/off (decoder only) */
  SPEEX_SET_ENH = 0;
 //** Get enhancement state (decoder only) */
  SPEEX_GET_ENH = 1;

//*Would be SPEEX_SET_FRAME_SIZE, but it's (currently) invalid*/
//** Obtain frame size used by encoder/decoder */
  SPEEX_GET_FRAME_SIZE = 3;

//** Set quality value */
  SPEEX_SET_QUALITY = 4;
//** Get current quality setting */
//  SPEEX_GET_QUALITY = 5; // -- Doesn't make much sense, does it? */

//** Set sub-mode to use */
  SPEEX_SET_MODE = 6;
//** Get current sub-mode in use */
  SPEEX_GET_MODE = 7;

//** Set low-band sub-mode to use (wideband only)*/
  SPEEX_SET_LOW_MODE = 8;
//** Get current low-band mode in use (wideband only)*/
  SPEEX_GET_LOW_MODE = 9;

//** Set high-band sub-mode to use (wideband only)*/
  SPEEX_SET_HIGH_MODE = 10;
//** Get current high-band mode in use (wideband only)*/
  SPEEX_GET_HIGH_MODE = 11;

//** Set VBR on (1) or off (0) */
  SPEEX_SET_VBR = 12;
//** Get VBR status (1 for on, 0 for off) */
  SPEEX_GET_VBR = 13;

//** Set quality value for VBR encoding (0-10) */
  SPEEX_SET_VBR_QUALITY = 14;
//** Get current quality value for VBR encoding (0-10) */
  SPEEX_GET_VBR_QUALITY = 15;

//** Set complexity of the encoder (0-10) */
  SPEEX_SET_COMPLEXITY = 16;
//** Get current complexity of the encoder (0-10) */
  SPEEX_GET_COMPLEXITY = 17;

//** Set bit-rate used by the encoder (or lower) */
  SPEEX_SET_BITRATE = 18;
//** Get current bit-rate used by the encoder or decoder */
  SPEEX_GET_BITRATE = 19;

//** Define a handler function for in-band Speex request*/
  SPEEX_SET_HANDLER = 20;

//** Define a handler function for in-band user-defined request*/
  SPEEX_SET_USER_HANDLER = 22;

//** Set sampling rate used in bit-rate computation */
  SPEEX_SET_SAMPLING_RATE = 24;
//** Get sampling rate used in bit-rate computation */
  SPEEX_GET_SAMPLING_RATE = 25;

//** Reset the encoder/decoder memories to zero*/
  SPEEX_RESET_STATE = 26;

//** Get VBR info (mostly used internally) */
  SPEEX_GET_RELATIVE_QUALITY = 29;

//** Set VAD status (1 for on, 0 for off) */
  SPEEX_SET_VAD = 30;
//** Get VAD status (1 for on, 0 for off) */
  SPEEX_GET_VAD = 31;

//** Set Average Bit-Rate (ABR) to n bits per seconds */
  SPEEX_SET_ABR = 32;
//** Get Average Bit-Rate (ABR) setting (in bps) */
  SPEEX_GET_ABR = 33;

//** Set DTX status (1 for on, 0 for off) */
  SPEEX_SET_DTX = 34;
//** Get DTX status (1 for on, 0 for off) */
  SPEEX_GET_DTX = 35;

//** Set submode encoding in each frame (1 for yes, 0 for no, setting to no breaks the standard) */
  SPEEX_SET_SUBMODE_ENCODING = 36;
//** Get submode encoding in each frame */
  SPEEX_GET_SUBMODE_ENCODING = 37;

//*#define SPEEX_SET_LOOKAHEAD 38*/
//** Returns the lookahead used by Speex */
  SPEEX_GET_LOOKAHEAD = 39;

//** Sets tuning for packet-loss concealment (expected loss rate) */
  SPEEX_SET_PLC_TUNING = 40;
//** Gets tuning for PLC */
  SPEEX_GET_PLC_TUNING = 41;

//** Sets the max bit-rate allowed in VBR mode */
  SPEEX_SET_VBR_MAX_BITRATE = 42;
//** Gets the max bit-rate allowed in VBR mode */
  SPEEX_GET_VBR_MAX_BITRATE = 43;

//** Turn on/off input/output high-pass filtering */
  SPEEX_SET_HIGHPASS = 44;
//** Get status of input/output high-pass filtering */
  SPEEX_GET_HIGHPASS = 45;

//** Get "activity level" of the last decoded frame, i.e.
//    how much damage we cause if we remove the frame */
  SPEEX_GET_ACTIVITY = 47;


//* Preserving compatibility:*/
//** Equivalent to SPEEX_SET_ENH */
  SPEEX_SET_PF = 0;
//** Equivalent to SPEEX_GET_ENH */
  SPEEX_GET_PF = 1;


//* Values allowed for mode queries */

//** Query the frame size of a mode */
  SPEEX_MODE_FRAME_SIZE = 0;

//** Query the size of an encoded frame for a particular sub-mode */
  SPEEX_SUBMODE_BITS_PER_FRAME = 1;



//** Get major Speex version */
  SPEEX_LIB_GET_MAJOR_VERSION = 1;
//** Get minor Speex version */
  SPEEX_LIB_GET_MINOR_VERSION = 3;
//** Get micro Speex version */
  SPEEX_LIB_GET_MICRO_VERSION = 5;
//** Get extra Speex version */
  SPEEX_LIB_GET_EXTRA_VERSION = 7;
//** Get Speex version string */
  SPEEX_LIB_GET_VERSION_STRING = 9;

(*#define SPEEX_LIB_SET_ALLOC_FUNC 10
#define SPEEX_LIB_GET_ALLOC_FUNC 11
#define SPEEX_LIB_SET_FREE_FUNC 12
#define SPEEX_LIB_GET_FREE_FUNC 13

#define SPEEX_LIB_SET_WARNING_FUNC 14
#define SPEEX_LIB_GET_WARNING_FUNC 15
#define SPEEX_LIB_SET_ERROR_FUNC 16
#define SPEEX_LIB_GET_ERROR_FUNC 17
*)

//** Number of defined modes in Speex */
  SPEEX_NB_MODES = 3;
//** modeID for the defined narrowband mode */
  SPEEX_MODEID_NB = 0;
//** modeID for the defined wideband mode */
  SPEEX_MODEID_WB = 1;
//** modeID for the defined ultra-wideband mode */
  SPEEX_MODEID_UWB = 2;

type
  pSpeexMode = ^SpeexMode;
  SpeexMode = record
    //
    mode: pointer;
    query: pointer;
    modeName: paChar;
    modeID: int32;
    bitstream_version: int32;
    enc_init: pointer;
    enc_destroy: pointer;
    enc: pointer;
    dec_init: pointer;
    dec_destroy: pointer;
    dec: pointer;
    enc_ctl: pointer;
    dec_ctl: pointer;
  end;

(**
 * Returns a handle to a newly created Speex encoder state structure. For now,
 * the "mode" argument can be &nb_mode or &wb_mode . In the future, more modes
 * may be added. Note that for now if you have more than one channels to
 * encode, you need one state per channel.
 *
 * @param mode The mode to use (either speex_nb_mode or speex_wb.mode)
 * @return A newly created encoder state or NULL if state allocation fails
 *)
  speex_encoder_init = function(mode: pSpeexMode): pointer; cdecl;

(** Frees all resources associated to an existing Speex encoder state.
 * @param state Encoder state to be destroyed *)
  speex_encoder_destroy = procedure(state: pointer); cdecl;

(** Uses an existing encoder state to encode one frame of speech pointed to by
    "in". The encoded bit-stream is saved in "bits".
 @param state Encoder state
 @param in Frame that will be encoded with a +-2^15 range. This data MAY be
	overwritten by the encoder and should be considered uninitialised
	after the call.
 @param bits Bit-stream where the data will be written
 @return 0 if frame needs not be transmitted (DTX only), 1 otherwise
 *)
  speex_encode = function(state: pointer; _in: pFloat; bits: pSpeexBits): int; cdecl;

(** Uses an existing encoder state to encode one frame of speech pointed to by
    "in". The encoded bit-stream is saved in "bits".
 @param state Encoder state
 @param in Frame that will be encoded with a +-2^15 range
 @param bits Bit-stream where the data will be written
 @return 0 if frame needs not be transmitted (DTX only), 1 otherwise
 *)
  speex_encode_int = function(state: pointer; _in: pspx_int16_t; bits: pSpeexBits): int; cdecl;

(** Used like the ioctl function to control the encoder parameters
 *
 * @param state Encoder state
 * @param request ioctl-type request (one of the SPEEX_* macros)
 * @param ptr Data exchanged to-from function
 * @return 0 if no error, -1 if request in unknown, -2 for invalid parameter
 *)
  speex_encoder_ctl = function(state: pointer; request: int; ptr: pointer): int; cdecl;


(** Returns a handle to a newly created decoder state structure. For now,
 * the mode argument can be &nb_mode or &wb_mode . In the future, more modes
 * may be added.  Note that for now if you have more than one channels to
 * decode, you need one state per channel.
 *
 * @param mode Speex mode (one of speex_nb_mode or speex_wb_mode)
 * @return A newly created decoder state or NULL if state allocation fails
 *)
  speex_decoder_init = function(mode: pSpeexMode): pointer; cdecl;

(** Frees all resources associated to an existing decoder state.
 *
 * @param state State to be destroyed
 *)
  speex_decoder_destroy = procedure(state: pointer); cdecl;

(** Uses an existing decoder state to decode one frame of speech from
 * bit-stream bits. The output speech is saved written to out.
 *
 * @param state Decoder state
 * @param bits Bit-stream from which to decode the frame (NULL if the packet was lost)
 * @param out Where to write the decoded frame
 * @return return status (0 for no error, -1 for end of stream, -2 corrupt stream)
 *)
  speex_decode = function(state: pointer; bits: pSpeexBits; _out: pFloat): int; cdecl;

(** Uses an existing decoder state to decode one frame of speech from
 * bit-stream bits. The output speech is saved written to out.
 *
 * @param state Decoder state
 * @param bits Bit-stream from which to decode the frame (NULL if the packet was lost)
 * @param out Where to write the decoded frame
 * @return return status (0 for no error, -1 for end of stream, -2 corrupt stream)
 *)
  speex_decode_int = function(state: pointer; bits: pSpeexBits; _out: pspx_int16_t): int; cdecl;

(** Used like the ioctl function to control the encoder parameters
 *
 * @param state Decoder state
 * @param request ioctl-type request (one of the SPEEX_* macros)
 * @param ptr Data exchanged to-from function
 * @return 0 if no error, -1 if request in unknown, -2 for invalid parameter
 *)
  speex_decoder_ctl = function(state: pointer; request: int; ptr: pointer): int; cdecl;


(** Query function for mode information
 *
 * @param mode Speex mode
 * @param request ioctl-type request (one of the SPEEX_* macros)
 * @param ptr Data exchanged to-from function
 * @return 0 if no error, -1 if request in unknown, -2 for invalid parameter
 *)
  speex_mode_query = function(mode: pSpeexMode; request: int; ptr: pointer): int; cdecl;

(** Functions for controlling the behavior of libspeex
 * @param request ioctl-type request (one of the SPEEX_LIB_* macros)
 * @param ptr Data exchanged to-from function
 * @return 0 if no error, -1 if request in unknown, -2 for invalid parameter
 *)
  speex_lib_ctl = function(request: int; ptr: pointer): int; cdecl;

//** Default narrowband mode */
//extern const SpeexMode speex_nb_mode;

//** Default wideband mode */
//extern const SpeexMode speex_wb_mode;

//** Default "ultra-wideband" mode */
//extern const SpeexMode speex_uwb_mode;

//** List of all modes available */
//extern const SpeexMode * const speex_mode_list[SPEEX_NB_MODES];

//** Obtain one of the modes available */
  speex_lib_get_mode = function(mode: int): pSpeexMode; cdecl;


//#endif


(* Copyright (C) 2003 Epic Games
   Written by Jean-Marc Valin *)
(**
 *  @file speex_preprocess.h
 *  @brief Speex preprocessor. The preprocess can do noise suppression,
 * residual echo suppression (after using the echo canceller), automatic
 * gain control (AGC) and voice activity detection (VAD).
*)

(*
   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions are
   met:

   1. Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer.

   2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.

   3. The name of the author may not be used to endorse or promote products
   derived from this software without specific prior written permission.

   THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
   IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
   OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
   DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
   INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
   (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
   SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
   HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
   STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
   ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
   POSSIBILITY OF SUCH DAMAGE.
*)

//#ifndef SPEEX_PREPROCESS_H
//#define SPEEX_PREPROCESS_H
(** @defgroup SpeexPreprocessState SpeexPreprocessState: The Speex preprocessor
 *  This is the Speex preprocessor. The preprocess can do noise suppression,
 * residual echo suppression (after using the echo canceller), automatic
 * gain control (AGC) and voice activity detection (VAD).
 *  @{
 *)

//#include "speex/speex_types.h"

type

//** State of the preprocessor (one per channel). Should never be accessed directly. */
  //SpeexPreprocessState_ = pointer;

//** State of the preprocessor (one per channel). Should never be accessed directly. */
  SpeexPreprocessState = pointer;


(** Creates a new preprocessing state. You MUST create one state per channel processed.
 * @param frame_size Number of samples to process at one time (should correspond to 10-20 ms). Must be
 * the same value as that used for the echo canceller for residual echo cancellation to work.
 * @param sampling_rate Sampling rate used for the input.
 * @return Newly created preprocessor state
*)
  speex_preprocess_state_init = function (frame_size: int; sampling_rate: int): SpeexPreprocessState; cdecl;

(** Destroys a preprocessor state
 * @param st Preprocessor state to destroy
*)
  speex_preprocess_state_destroy = procedure (st: SpeexPreprocessState); cdecl;

(** Preprocess a frame
 * @param st Preprocessor state
 * @param x Audio sample vector (in and out). Must be same size as specified in speex_preprocess_state_init().
 * @return Bool value for voice activity (1 for speech, 0 for noise/silence), ONLY if VAD turned on.
*)
  speex_preprocess_run = function (st: SpeexPreprocessState; x: pspx_int16_t): int; cdecl;

(** Preprocess a frame (deprecated, use speex_preprocess_run() instead)*)
//int speex_preprocess(SpeexPreprocessState *st, spx_int16_t *x, spx_int32_t *echo); cdecl;

(** Update preprocessor state, but do not compute the output
 * @param st Preprocessor state
 * @param x Audio sample vector (in only). Must be same size as specified in speex_preprocess_state_init().
*)
  speex_preprocess_estimate_update = procedure(st: SpeexPreprocessState; x: pspx_int16_t); cdecl;

(** Used like the ioctl function to control the preprocessor parameters
 * @param st Preprocessor state
 * @param request ioctl-type request (one of the SPEEX_PREPROCESS_* macros)
 * @param ptr Data exchanged to-from function
 * @return 0 if no error, -1 if request in unknown
*)
  speex_preprocess_ctl = function(st: SpeexPreprocessState; request: int; ptr: pointer): int; cdecl;


const

  //** Set preprocessor denoiser state */
  SPEEX_PREPROCESS_SET_DENOISE = 0;
  //** Get preprocessor denoiser state */
  SPEEX_PREPROCESS_GET_DENOISE = 1;

  //** Set preprocessor Automatic Gain Control state */
  SPEEX_PREPROCESS_SET_AGC = 2;
  //** Get preprocessor Automatic Gain Control state */
  SPEEX_PREPROCESS_GET_AGC = 3;

  //** Set preprocessor Voice Activity Detection state */
  SPEEX_PREPROCESS_SET_VAD = 4;
  //** Get preprocessor Voice Activity Detection state */
  SPEEX_PREPROCESS_GET_VAD = 5;

  //** Set preprocessor Automatic Gain Control level */
  SPEEX_PREPROCESS_SET_AGC_LEVEL = 6;
  //** Get preprocessor Automatic Gain Control level */
  SPEEX_PREPROCESS_GET_AGC_LEVEL = 7;

  //** Set preprocessor dereverb state */
  SPEEX_PREPROCESS_SET_DEREVERB = 8;
  //** Get preprocessor dereverb state */
  SPEEX_PREPROCESS_GET_DEREVERB = 9;

  //** Set preprocessor dereverb level */
  SPEEX_PREPROCESS_SET_DEREVERB_LEVEL = 10;
  //** Get preprocessor dereverb level */
  SPEEX_PREPROCESS_GET_DEREVERB_LEVEL = 11;

  //** Set preprocessor dereverb decay */
  SPEEX_PREPROCESS_SET_DEREVERB_DECAY = 12;
  //** Get preprocessor dereverb decay */
  SPEEX_PREPROCESS_GET_DEREVERB_DECAY = 13;

  //** Set probability required for the VAD to go from silence to voice */
  SPEEX_PREPROCESS_SET_PROB_START = 14;
  //** Get probability required for the VAD to go from silence to voice */
  SPEEX_PREPROCESS_GET_PROB_START = 15;

  //** Set probability required for the VAD to stay in the voice state (integer percent) */
  SPEEX_PREPROCESS_SET_PROB_CONTINUE = 16;
  //** Get probability required for the VAD to stay in the voice state (integer percent) */
  SPEEX_PREPROCESS_GET_PROB_CONTINUE = 17;

  //** Set maximum attenuation of the noise in dB (negative number) */
  SPEEX_PREPROCESS_SET_NOISE_SUPPRESS = 18;
  //** Get maximum attenuation of the noise in dB (negative number) */
  SPEEX_PREPROCESS_GET_NOISE_SUPPRESS = 19;

  //** Set maximum attenuation of the residual echo in dB (negative number) */
  SPEEX_PREPROCESS_SET_ECHO_SUPPRESS = 20;
  //** Get maximum attenuation of the residual echo in dB (negative number) */
  SPEEX_PREPROCESS_GET_ECHO_SUPPRESS = 21;

  //** Set maximum attenuation of the residual echo in dB when near end is active (negative number) */
  SPEEX_PREPROCESS_SET_ECHO_SUPPRESS_ACTIVE = 22;
  //** Get maximum attenuation of the residual echo in dB when near end is active (negative number) */
  SPEEX_PREPROCESS_GET_ECHO_SUPPRESS_ACTIVE = 23;

  //** Set the corresponding echo canceller state so that residual echo suppression can be performed (NULL for no residual echo suppression) */
  SPEEX_PREPROCESS_SET_ECHO_STATE = 24;
  //** Get the corresponding echo canceller state */
  SPEEX_PREPROCESS_GET_ECHO_STATE = 25;

  //** Set maximal gain increase in dB/second (int32) */
  SPEEX_PREPROCESS_SET_AGC_INCREMENT = 26;
  //** Get maximal gain increase in dB/second (int32) */
  SPEEX_PREPROCESS_GET_AGC_INCREMENT = 27;

  //** Set maximal gain decrease in dB/second (int32) */
  SPEEX_PREPROCESS_SET_AGC_DECREMENT = 28;
  //** Get maximal gain decrease in dB/second (int32) */
  SPEEX_PREPROCESS_GET_AGC_DECREMENT = 29;

  //** Set maximal gain in dB (int32) */
  SPEEX_PREPROCESS_SET_AGC_MAX_GAIN = 30;
  //** Get maximal gain in dB (int32) */
  SPEEX_PREPROCESS_GET_AGC_MAX_GAIN = 31;

  //*  Can't set loudness */
  //** Get loudness */
  SPEEX_PREPROCESS_GET_AGC_LOUDNESS = 33;

//#endif


//* Copyright (C) Jean-Marc Valin */
(**
   @file speex_echo.h
   @brief Echo cancellation
*)
(*
   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions are
   met:

   1. Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer.

   2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.

   3. The name of the author may not be used to endorse or promote products
   derived from this software without specific prior written permission.

   THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
   IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
   OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
   DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
   INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
   (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
   SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
   HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
   STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
   ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
   POSSIBILITY OF SUCH DAMAGE.
*)

//#ifndef SPEEX_ECHO_H
//#define SPEEX_ECHO_H
(** @defgroup SpeexEchoState SpeexEchoState: Acoustic echo canceller
 *  This is the acoustic echo canceller module.
 *  @{
 *)
//#include "speex/speex_types.h"

const
  //** Obtain frame size used by the AEC */
  SPEEX_ECHO_GET_FRAME_SIZE = 3;

  //** Set sampling rate */
  SPEEX_ECHO_SET_SAMPLING_RATE = 24;
  //** Get sampling rate */
  SPEEX_ECHO_GET_SAMPLING_RATE = 25;

type
//** Internal echo canceller state. Should never be accessed directly. */
  SpeexEchoState = pointer;

(** Creates a new echo canceller state
 * @param frame_size Number of samples to process at one time (should correspond to 10-20 ms)
 * @param filter_length Number of samples of echo to cancel (should generally correspond to 100-500 ms)
 * @return Newly-created echo canceller state
 *)
  speex_echo_state_init = function(frame_size: int; filter_length: int): SpeexEchoState; cdecl;

(** Destroys an echo canceller state
 * @param st Echo canceller state
*)
  speex_echo_state_destroy = procedure(st: SpeexEchoState); cdecl;

(** Performs echo cancellation a frame, based on the audio sent to the speaker (no delay is added
 * to playback in this form)
 *
 * @param st Echo canceller state
 * @param rec Signal from the microphone (near end + far end echo)
 * @param play Signal played to the speaker (received from far end)
 * @param out Returns near-end signal with echo removed
 *)
 speex_echo_cancellation = procedure(st: SpeexEchoState; rec: pspx_int16_t; play: pspx_int16_t; out_: pspx_int16_t); cdecl;

//** Performs echo cancellation a frame (deprecated) */
//void speex_echo_cancel(SpeexEchoState *st, const spx_int16_t *rec, const spx_int16_t *play, spx_int16_t *out, spx_int32_t *Yout);

(** Perform echo cancellation using internal playback buffer, which is delayed by two frames
 * to account for the delay introduced by most soundcards (but it could be off!)
 * @param st Echo canceller state
 * @param rec Signal from the microphone (near end + far end echo)
 * @param out Returns near-end signal with echo removed
*)
  speex_echo_capture = procedure(st: SpeexEchoState; rec: pspx_int16_t; out_: pspx_int16_t); cdecl;

(** Let the echo canceller know that a frame was just queued to the soundcard
 * @param st Echo canceller state
 * @param play Signal played to the speaker (received from far end)
*)
  speex_echo_playback = procedure(st: SpeexEchoState; play: pspx_int16_t); cdecl;

(** Reset the echo canceller to its original state
 * @param st Echo canceller state
 *)
  speex_echo_state_reset = procedure(st: SpeexEchoState); cdecl;

(** Used like the ioctl function to control the echo canceller parameters
 *
 * @param st Echo canceller state
 * @param request ioctl-type request (one of the SPEEX_ECHO_* macros)
 * @param ptr Data exchanged to-from function
 * @return 0 if no error, -1 if request in unknown
 *)
  speex_echo_ctl = function(st: SpeexEchoState; request: int; ptr: pointer): int; cdecl;

//#endif



(* Copyright (C) 2007 Jean-Marc Valin

   File: speex_resampler.h
   Resampling code

   The design goals of this code are:
      - Very fast algorithm
      - Low memory requirement
      - Good *perceptual* quality (and not best SNR)

   Redistribution and use in source and binary forms, with or without
   modification, are permitted provided that the following conditions are
   met:

   1. Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer.

   2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.

   3. The name of the author may not be used to endorse or promote products
   derived from this software without specific prior written permission.

   THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
   IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
   OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
   DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
   INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
   (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
   SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
   HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
   STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
   ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
   POSSIBILITY OF SUCH DAMAGE.
*)

//#ifndef SPEEX_RESAMPLER_H
//#define SPEEX_RESAMPLER_H

const
  SPEEX_RESAMPLER_QUALITY_MAX		= 10;
  SPEEX_RESAMPLER_QUALITY_MIN		= 0;
  SPEEX_RESAMPLER_QUALITY_DEFAULT	= 4;
  SPEEX_RESAMPLER_QUALITY_VOIP 		= 3;
  SPEEX_RESAMPLER_QUALITY_DESKTOP 	= 5;

  RESAMPLER_ERR_SUCCESS         	= 0;
  RESAMPLER_ERR_ALLOC_FAILED    	= 1;
  RESAMPLER_ERR_BAD_STATE       	= 2;
  RESAMPLER_ERR_INVALID_ARG     	= 3;
  RESAMPLER_ERR_PTR_OVERLAP     	= 4;
  RESAMPLER_ERR_MAX_ERROR 		= RESAMPLER_ERR_PTR_OVERLAP;

type
  SpeexResamplerState = pointer;

(** Create a new resampler with integer input and output rates.
 * @param nb_channels Number of channels to be processed
 * @param in_rate Input sampling rate (integer number of Hz).
 * @param out_rate Output sampling rate (integer number of Hz).
 * @param quality Resampling quality between 0 and 10, where 0 has poor quality
 * and 10 has very high quality.
 * @return Newly created resampler state
 * @return NULL Error: not enough memory
 *)
  speex_resampler_init = function(nb_channels: spx_uint32_t;
				  in_rate: spx_uint32_t;
				  out_rate: spx_uint32_t;
				  quality: int;
				  var err: int): SpeexResamplerState; cdecl;

(** Create a new resampler with fractional input/output rates. The sampling
 * rate ratio is an arbitrary rational number with both the numerator and
 * denominator being 32-bit integers.
 * @param nb_channels Number of channels to be processed
 * @param ratio_num Numerator of the sampling rate ratio
 * @param ratio_den Denominator of the sampling rate ratio
 * @param in_rate Input sampling rate rounded to the nearest integer (in Hz).
 * @param out_rate Output sampling rate rounded to the nearest integer (in Hz).
 * @param quality Resampling quality between 0 and 10, where 0 has poor quality
 * and 10 has very high quality.
 * @return Newly created resampler state
 * @return NULL Error: not enough memory
 *)
  speex_resampler_init_frac = function(nb_channels: spx_uint32_t;
				       ratio_num: spx_uint32_t;
				       ratio_den: spx_uint32_t;
				       in_rate: spx_uint32_t;
				       out_rate: spx_uint32_t;
				       quality: int;
				       var err: int): SpeexResamplerState; cdecl;

(** Destroy a resampler state.
 * @param st Resampler state
 *)
  speex_resampler_destroy = procedure(st: SpeexResamplerState); cdecl;

(** Resample a float array. The input and output buffers must *not* overlap.
 * @param st Resampler state
 * @param channel_index Index of the channel to process for the multi-channel
 * base (0 otherwise)
 * @param in Input buffer
 * @param in_len Number of input samples in the input buffer. Returns the
 * number of samples processed
 * @param out Output buffer
 * @param out_len Size of the output buffer. Returns the number of samples written
 *)
  speex_resampler_process_float = function(st: SpeexResamplerState;
					   channel_index: spx_uint32_t;
					   in_: pFloat;
					   var in_len: spx_uint32_t;
					   out_: pFloat;
					   var out_len: spx_uint32_t): int; cdecl;

(** Resample an int array. The input and output buffers must *not* overlap.
 * @param st Resampler state
 * @param channel_index Index of the channel to process for the multi-channel
 * base (0 otherwise)
 * @param in Input buffer
 * @param in_len Number of input samples in the input buffer. Returns the number
 * of samples processed
 * @param out Output buffer
 * @param out_len Size of the output buffer. Returns the number of samples written
 *)
  speex_resampler_process_int = function(st: SpeexResamplerState;
					 channel_index: spx_uint32_t;
					 in_: pspx_int16_t;
					 var in_len: spx_uint32_t;
					 out_: pspx_int16_t;
					 var out_len: spx_uint32_t): int; cdecl;

(** Resample an interleaved float array. The input and output buffers must *not* overlap.
 * @param st Resampler state
 * @param in Input buffer
 * @param in_len Number of input samples in the input buffer. Returns the number
 * of samples processed. This is all per-channel.
 * @param out Output buffer
 * @param out_len Size of the output buffer. Returns the number of samples written.
 * This is all per-channel.
 *)
{int speex_resampler_process_interleaved_float(SpeexResamplerState *st,
					       const float *in,
					       spx_uint32_t *in_len,
					       float *out,
					       spx_uint32_t *out_len); cdecl;
}

(** Resample an interleaved int array. The input and output buffers must *not* overlap.
 * @param st Resampler state
 * @param in Input buffer
 * @param in_len Number of input samples in the input buffer. Returns the number
 * of samples processed. This is all per-channel.
 * @param out Output buffer
 * @param out_len Size of the output buffer. Returns the number of samples written.
 * This is all per-channel.
 *)
{int speex_resampler_process_interleaved_int(SpeexResamplerState *st,
					     const spx_int16_t *in,
					     spx_uint32_t *in_len,
					     spx_int16_t *out,
					     spx_uint32_t *out_len); cdecl;
}

(** Set (change) the input/output sampling rates (integer value).
 * @param st Resampler state
 * @param in_rate Input sampling rate (integer number of Hz).
 * @param out_rate Output sampling rate (integer number of Hz).
 *)
{int speex_resampler_set_rate(SpeexResamplerState *st,
			      spx_uint32_t in_rate,
			      spx_uint32_t out_rate); cdecl;
}

(** Get the current input/output sampling rates (integer value).
 * @param st Resampler state
 * @param in_rate Input sampling rate (integer number of Hz) copied.
 * @param out_rate Output sampling rate (integer number of Hz) copied.
 *)
{void speex_resampler_get_rate(SpeexResamplerState *st,
			      spx_uint32_t *in_rate,
			      spx_uint32_t *out_rate); cdecl;
}

(** Set (change) the input/output sampling rates and resampling ratio
 * (fractional values in Hz supported).
 * @param st Resampler state
 * @param ratio_num Numerator of the sampling rate ratio
 * @param ratio_den Denominator of the sampling rate ratio
 * @param in_rate Input sampling rate rounded to the nearest integer (in Hz).
 * @param out_rate Output sampling rate rounded to the nearest integer (in Hz).
 *)
{int speex_resampler_set_rate_frac(SpeexResamplerState *st,
				   spx_uint32_t ratio_num,
				   spx_uint32_t ratio_den,
				   spx_uint32_t in_rate,
				   spx_uint32_t out_rate); cdecl;
}

(** Get the current resampling ratio. This will be reduced to the least
 * common denominator.
 * @param st Resampler state
 * @param ratio_num Numerator of the sampling rate ratio copied
 * @param ratio_den Denominator of the sampling rate ratio copied
 *)
{void speex_resampler_get_ratio(SpeexResamplerState *st,
			       spx_uint32_t *ratio_num,
			       spx_uint32_t *ratio_den); cdecl;
}

(** Set (change) the conversion quality.
 * @param st Resampler state
 * @param quality Resampling quality between 0 and 10, where 0 has poor
 * quality and 10 has very high quality.
 *)
  speex_resampler_set_quality = function(st: SpeexResamplerState; quality: int): int; cdecl;

(** Get the conversion quality.
 * @param st Resampler state
 * @param quality Resampling quality between 0 and 10, where 0 has poor
 * quality and 10 has very high quality.
 *)
  speex_resampler_get_quality = procedure(st: SpeexResamplerState; var quality: int); cdecl;

(** Set (change) the input stride.
 * @param st Resampler state
 * @param stride Input stride
 *)
//void speex_resampler_set_input_stride(SpeexResamplerState *st, spx_uint32_t stride); cdecl;

(** Get the input stride.
 * @param st Resampler state
 * @param stride Input stride copied
 *)
//void speex_resampler_get_input_stride(SpeexResamplerState *st, spx_uint32_t *stride); cdecl;

(** Set (change) the output stride.
 * @param st Resampler state
 * @param stride Output stride
 *)
//void speex_resampler_set_output_stride(SpeexResamplerState *st, spx_uint32_t stride); cdecl;

(** Get the output stride.
 * @param st Resampler state copied
 * @param stride Output stride
 *)
//void speex_resampler_get_output_stride(SpeexResamplerState *st, spx_uint32_t *stride); cdecl;

(** Get the latency in input samples introduced by the resampler.
 * @param st Resampler state
 *)
//int speex_resampler_get_input_latency(SpeexResamplerState *st); cdecl;

(** Get the latency in output samples introduced by the resampler.
 * @param st Resampler state
 *)
//int speex_resampler_get_output_latency(SpeexResamplerState *st); cdecl;

(** Make sure that the first samples to go out of the resamplers don't have
 * leading zeros. This is only useful before starting to use a newly created
 * resampler. It is recommended to use that when resampling an audio file, as
 * it will generate a file with the same length. For real-time processing,
 * it is probably easier not to use this call (so that the output duration
 * is the same for the first frame).
 * @param st Resampler state
 *)
  speex_resampler_skip_zeros = function(st: SpeexResamplerState): int; cdecl;

(** Reset a resampler so a new (unrelated) stream can be processed.
 * @param st Resampler state
 *)
  speex_resampler_reset_mem = function(st: SpeexResamplerState): int; cdecl;

(** Returns the English meaning for an error code
 * @param err Error code
 * @return English string
 *)
  speex_resampler_strerror = function(err: int): paChar; cdecl;


//#endif





////////////////////////////////////////////////////
///  Delphi code starts below                    ///
////////////////////////////////////////////////////

var
  c_opt4RTP_numframes: int	= 5;	// pack up to 5 frames (100 ms) when optimizing for RTP
  c_opt4RTP_numbytes: int	= 1100;	// pack no more than 1100 bytes when optimizing for RTP

type
  {*
	Holds Speex library proc entries.
  }
  pSpeexLibrary_proc = ^tSpeexLibrary_proc;
  tSpeexLibrary_proc = record
    //
    r_module: hModule;
    r_moduleRefCount: int;
    //
    r_bits_init               : speex_bits_init             ;
    r_bits_init_buffer        : speex_bits_init_buffer      ;
    r_bits_set_bit_buffer     : speex_bits_set_bit_buffer   ;
    r_bits_destroy            : speex_bits_destroy          ;
    r_bits_reset              : speex_bits_reset            ;
    r_bits_rewind             : speex_bits_rewind           ;
    r_bits_read_from          : speex_bits_read_from        ;
    r_bits_read_whole_bytes   : speex_bits_read_whole_bytes ;
    r_bits_write              : speex_bits_write            ;
    r_bits_write_whole_bytes  : speex_bits_write_whole_bytes;
    r_bits_pack               : speex_bits_pack             ;
    r_bits_unpack_signed      : speex_bits_unpack_signed    ;
    r_bits_unpack_unsigned    : speex_bits_unpack_unsigned  ;
    r_bits_nbytes             : speex_bits_nbytes           ;
    r_bits_peek_unsigned      : speex_bits_peek_unsigned    ;
    r_bits_peek               : speex_bits_peek             ;
    r_bits_advance            : speex_bits_advance          ;
    r_bits_remaining          : speex_bits_remaining        ;
    r_bits_insert_terminator  : speex_bits_insert_terminator;
    //
    r_encoder_init    : speex_encoder_init;
    r_encoder_destroy : speex_encoder_destroy;
    r_encode          : speex_encode;
    r_encode_int      : speex_encode_int;
    r_encoder_ctl     : speex_encoder_ctl;
    //
    r_decoder_init    : speex_decoder_init;
    r_decoder_destroy : speex_decoder_destroy;
    r_decode          : speex_decode;
    r_decode_int      : speex_decode_int;
    r_decoder_ctl     : speex_decoder_ctl;
    //
    r_lib_get_mode    : speex_lib_get_mode;
    r_mode_query      : speex_mode_query;
    //
    r_lib_ctl         : speex_lib_ctl;
  end;

  {*
	Holds Speex DSP library proc entries.
  }
  pSpeexDSPLibrary_proc = ^tSpeexDSPLibrary_proc;
  tSpeexDSPLibrary_proc = record
    //
    r_module: hModule;
    r_moduleRefCount: int;
    //
    r_speex_preprocess_state_init     :	speex_preprocess_state_init;
    r_speex_preprocess_state_destroy  :	speex_preprocess_state_destroy;
    r_speex_preprocess_run	      :	speex_preprocess_run;
    r_speex_preprocess_estimate_update:	speex_preprocess_estimate_update;
    r_speex_preprocess_ctl	      :	speex_preprocess_ctl;
    //
    r_speex_echo_state_init	      :	speex_echo_state_init;
    r_speex_echo_state_destroy	      :	speex_echo_state_destroy;
    r_speex_echo_cancellation	      :	speex_echo_cancellation;
    r_speex_echo_capture	      :	speex_echo_capture;
    r_speex_echo_playback	      :	speex_echo_playback;
    r_speex_echo_state_reset	      :	speex_echo_state_reset;
    r_speex_echo_ctl		      :	speex_echo_ctl;
    //
    r_speex_resampler_init	      :	speex_resampler_init;
    r_speex_resampler_init_frac	      :	speex_resampler_init_frac;
    r_speex_resampler_destroy	      :	speex_resampler_destroy;
    r_speex_resampler_process_float   :	speex_resampler_process_float;
    r_speex_resampler_process_int     :	speex_resampler_process_int;
    r_speex_resampler_set_quality     :	speex_resampler_set_quality;
    r_speex_resampler_get_quality     :	speex_resampler_get_quality;
    r_speex_resampler_skip_zeros      :	speex_resampler_skip_zeros;
    r_speex_resampler_reset_mem	      :	speex_resampler_reset_mem;
    r_speex_resampler_strerror	      :	speex_resampler_strerror;
  end;


// -------- wrapper classes ----------------

  {*
	Loads Speex DLL into process memory.
  }
  unaSpeexLib = class(unaObject)
  private
    f_lib: tSpeexLibrary_proc;
    f_lastError: int;
    f_libOK: bool;
    //
    function getLib(): pSpeexLibrary_proc;
  public
    constructor create(const libPath: wString = '');
    procedure BeforeDestruction(); override;
    //
    property lastError: int read f_lastError;
    //
    property api: pSpeexLibrary_proc read getLib;
    {*
    }
    property libOK: bool read f_libOK;
  end;


  {*
	Speex DSP
  }
  unaSpeexDSP = class(unaObject)
  private
    f_lib: tSpeexDSPLibrary_proc;
    //f_lock: unaInProcessGate;
    //
    f_error: int;
    f_frameSize: int;
    f_samplingRate: int;
    f_active: bool;
    f_lfv: bool;
    //
    f_libOK: bool;
    //
    f_sps: int;
    //
    f_lastResampleDst,
    f_lastResampleSrc: int;
    //
    f_dsp_params: array[0..3] of bool;
    f_dsp_paramsValid: array[0..3] of bool;
    //
    f_st_dsp: SpeexPreprocessState;
    f_st_aec: SpeexEchoState;
    f_st_resampler: SpeexResamplerState;
    //
    function getLib(): pSpeexDSPLibrary_proc;
    function dsp_getBool(index: integer): bool;
    procedure dsp_setBool(index: integer; value: bool);
    //
    function getAcgLvl(): float;
    function getAcgLdn(): float;
  protected
    function lock(timeout: tTimeout = 1000): bool;
    procedure unlock();
  public
    {*
	Creates Speex DSP instance.
    }
    constructor create(const libName: wString = '');
    {*
	Destroys Speex DSP instance.
    }
    destructor Destroy(); override;
    //
    {*
	Open DSP instance.

	@param frameSize size of one frame in samples
	@param samplingRate sampling rate
	@param aec enable AEC module

	@return 0 or errorCode
    }
    function open(frameSize, samplingRate: int; aec: bool = false): int;
    {*
	Close DSP instance.
    }
    procedure close();
    {*
	Preprocesses a frame.

	@param frame audio samples (must be 16 bit/mono)
	@return True for voice, false for silence/noise (only if VAD is enabled)
    }
    function preprocess(frame: pspx_int16_t): bool;
    {*
	Resamples a frame.

	@param srcFrame audio samples (must be 16 bit/mono) to be resampled
	@param srcSamples number of samples in srcFrame
	@param srcSamplingRate source sampling rate
	@param outBuf destination buffer
	@param outBufUsed number of samples written into outBuf
	@return number of samples read from srcFrame
    }
    function resampleSrc(srcFrame: pspx_int16_t; var srcSamples: spx_uint32_t; srcSamplingRate: int; outBuf: pspx_int16_t; var outBufUsed: spx_uint32_t): uint;
    function resampleDst(srcFrame: pspx_int16_t; var srcSamples: spx_uint32_t; outBuf: pspx_int16_t; outSamplingRate: int; var outBufUsed: spx_uint32_t): uint;
    {*
    }
    procedure echo_playback(frame: pspx_int16_t);
    {*
    }
    procedure echo_capture(inFrame: pspx_int16_t; outFrame: pspx_int16_t);
    //
    // --  --
    {*
	Speex proc.
    }
    property api: pSpeexDSPLibrary_proc read getLib;
    {*
	Last error.
    }
    property error: int read f_error;
    {*
    }
    property active: bool read f_active;
    //
    // DSP properties
    //
    {*
    }
    property libOK: bool read f_libOK;
    {*
	True for voice, false for silence/noise (only if VAD is enabled).
    }
    property lastFrameVAD: bool read f_lfv;
    {*
	Sampling rate the DSP was initialized with
    }
    property samplingRate: int read f_sps;
    {*
	Frame size (in samples) the DSP was initialized with
    }
    property frameSize: int read f_frameSize;
    {*
	SPEEX_PREPROCESS_GET_DENOISE/SPEEX_PREPROCESS_GET_DENOISE
    }
    property dsp_denoise: bool index 0 read dsp_getBool write dsp_setBool;
    {*
	SPEEX_PREPROCESS_GET_AGC/SPEEX_PREPROCESS_SET_AGC
    }
    property dsp_AGC: bool index 1 read dsp_getBool write dsp_setBool;
    {*
	SPEEX_PREPROCESS_GET_VAD/SPEEX_PREPROCESS_SET_VAD
    }
    property dsp_VAD: bool index 2 read dsp_getBool write dsp_setBool;
    {*
	SPEEX_PREPROCESS_GET_VAD/SPEEX_PREPROCESS_SET_VAD
    }
    property dsp_dereverb: bool index 3 read dsp_getBool write dsp_setBool;
    {*
	SPEEX_PREPROCESS_GET_AGC_LEVEL/SPEEX_PREPROCESS_SET_AGC_LEVEL
    }
    property dsp_AGC_level: float read getAcgLvl;
    {*
	SPEEX_PREPROCESS_GET_AGC_LOUDNESS /SPEEX_PREPROCESS_SET_AGC_LOUDNESS
    }
    property dsp_AGC_loudness: float read getAcgLdn;
  end;


  {*
	Base class fro Speex encoder and decoder.
  }
  unaSpeexCoder = class(unaObject)
  private
    f_lib: unaSpeexLib;
    //f_lock: unaInProcessGate;
    //
    f_mode: int;
    f_state: pointer;
    f_bits: SpeexBits;
    //
    f_frameSize: int;
    //
    f_outBuf: pointer;
    f_outBufSize: int;
    //
    function getModeInfo(): pSpeexMode;
    function getActive(): bool;
    function getBits(): pSpeexBits;
    function getFrameSize(): int;
    function getSamplingRate(): int;
    //
    procedure setMode(value: int);
    procedure setActive(value: bool);
    //
    function getIntValue(index: Integer): int32; virtual; abstract;
    procedure setIntValue(index: Integer; value: int32); virtual; abstract;
  protected
    function enter(timeout: tTimeout = 3000): bool;
    procedure leave();
    //
    procedure afterOpen(); virtual;
    procedure beforeClose(); virtual;
    //
    function doInit(): pointer; virtual; abstract;
    procedure doOpen(); virtual; abstract;
    procedure doClose(); virtual; abstract;
    function doGetFrameSize(): int; virtual; abstract;
    function doGetSamplingRate(): int; virtual; abstract;
  public
    {*
      Mode could be SPEEX_MODEID_NB, SPEEX_MODEID_WB or SPEEX_MODEID_UWB.
    }
    constructor create(lib: unaSpeexLib; mode: int = SPEEX_MODEID_NB);
    {*
    }
    procedure BeforeDestruction(); override;
    {*
	Releases resources used by processor.
    }
    procedure close();
    {*
	Initializes processor.

	Return True if encoder was initialized normally (or already was activated).
    }
    function open(): bool;
    //
    // -- properties --
    //
    {*
    }
    property lib: unaSpeexLib read f_lib;
    {*
    }
    property state: pointer read f_state;
    {*
	Mode could be SPEEX_MODEID_NB, SPEEX_MODEID_WB or SPEEX_MODEID_UWB.
    }
    property mode: int read f_mode write setMode;
    {*
    }
    property modeInfo: pSpeexMode read getModeInfo;
    {*
	Size of frame in samples.
    }
    property frameSize: int read getFrameSize;
    {*
	Sampling rate expected by encoder.
    }
    property samplingRate: int read getSamplingRate;
    {*
	Internal structure for bitstream.
    }
    property bits: pSpeexBits read getBits;
    {*
	True when initialized.
    }
    property active: bool read getActive write setActive;
    {*
    }
    property PLC_TUNING: int32 index SPEEX_SET_PLC_TUNING read getIntValue write setIntValue;
  end;

  {*
	Speex Encoder.
  }
  unaSpeexEncoder = class(unaSpeexCoder)
  private
    f_bitrate: int;
    f_abr: int;
    //
    f_sampleDelta: unsigned;
    //
    f_complexity: int;
    f_quality: int;
    f_vbr: bool;
    f_vbrQuality: float;
    //
    f_vad_prev: bool;
    f_vad_cooldown: int;
    //
    f_op4RTP: bool;
    f_op4RTP_framesCollected: int;	// 0 = just started
    //
    f_subBuf: pArray;
    f_subBufPos: int;
    //
    f_dsp: unaSpeexDSP;
    f_aec: bool;
    //
    function getVbr(): bool;
    function getVbrQ(): float;
    function getBitrate(): int;
    function getQuality(): int;
    function getComplexity(): int;
    function getABR(): int;
    //
    procedure setVbr(value: bool);
    procedure setVbrQ(const value: float);
    procedure setBitrate(value: int);
    procedure setQuality(value: int);
    procedure setComplexity(value: int);
    procedure setABR(value: int);
    {*
	Reads encoded bytes from speex and notifies via encoder_write().
    }
    procedure notify_data();
    //
    function getIntValue(index: Integer): int32; override;
    procedure setIntValue(index: Integer; value: int32); override;
  protected
    function doInit(): pointer; override;
    procedure doOpen(); override;
    procedure doClose(); override;
    function doGetFrameSize(): int; override;
    function doGetSamplingRate(): int; override;
    {*
	Adds new frame to encoder.
	samples is pointing to exactly 1 frame of audio (20 ms).
	Samples are 16 bits integer values from -32768 to +32767, mono.
    }
    procedure add_frame_int(samples: pointer; vad: bool); virtual;
    {*
	Called when new block of encoded data is available.
	numFrames is number of frames encoded in buffer.
    }
    procedure encoder_write(sampleDelta: uint; data: pointer; size: uint; numFrames: uint); virtual;
  public
    procedure AfterConstruction(); override;
    {*
	Writes full frames from samples buffer. Rest will be stored internally.
	Size is in bytes.
	Samples are 16 bits integer values from -32768 to +32767, mono.

	Return number of bytes consumed by encoder or -1 in case of some error.
    }
    function encode_int(samples: pointer; size: int): int;
    //
    {*
	Makes encoder aware (or unaware if nil is passed) of DSP.
    }
    procedure assignDSP(dsp: unaSpeexDSP; aec: bool = false);
    //
    // set below properties to adjust output bitrate (and quality)
    property quality: int read getQuality write setQuality;
    property bitrate: int read getBitrate write setBitrate;
    property abr: int read getABR write setABR;
    property vbr: bool read getVbr write setVbr;
    property vbrQuality: float read getVbrQ write setVbrQ;
    property complexity: int read getComplexity write setComplexity;
    {*
	Assigned DSP (if any)
    }
    property dsp: unaSpeexDSP read f_dsp;
    {*
	Enable/disable aec (only when dsp is assigned)
    }
    property aec: bool read f_aec write f_aec;
    {*
	When True, up to c_opt4RTP_numframes frames but no more than c_opt4RTP_numbytes bytes
	will be packed before output encoded buffer will be notified.
    }
    property optimizeForRTP: bool read f_op4RTP write f_op4RTP;
  end;

  {*
	Speex Decoder
  }
  unaSpeexDecoder = class(unaSpeexCoder)
  private
    function getIntValue(index: Integer): int32; override;
    procedure setIntValue(index: Integer; value: int32); override;
  protected
    function doInit(): pointer; override;
    procedure doOpen(); override;
    procedure doClose(); override;
    function doGetFrameSize(): int; override;
    function doGetSamplingRate(): int; override;
    {*
	Called when new block of decoded data is available.
    }
    procedure decoder_write_int(samples: pointer; size: int); virtual;
  public
    {*
	Sends full encoded frame(s) to decoder.

	Return number of bytes consumed by decoder or -1 in case of some error.
    }
    function decode(bitstream: pointer; size: int): int;
  end;


const
  //
  c_speexDLL	= 'libspeex.dll';
  c_speexDSPDLL	= 'libspeexdsp.dll';

{*
  Loads the Speex DLL.

  @return 0 if successuf, -1 is some API is missing or Windows specific error code.
}
function speex_loadDLL(var speexProc: tSpeexLibrary_proc; const pathAndName: wString = c_speexDLL): int;

{*
  Unloads the Speex DLL.

  @return 0 if successuf, or Windows specific error code.
}
function speex_unloadDLL(var speexProc: tSpeexLibrary_proc): int;


{*
  Loads the Speex DSP DLL.

  @return 0 if successuf, -1 is some API is missing or Windows specific error code.
}
function speex_loadDSPDLL(var speexDSPProc: tSpeexDSPLibrary_proc; const pathAndName: wString = c_speexDSPDLL): int;

{*
  Unloads the Speex DSP DLL.

  @return 0 if successuf, or Windows specific error code.
}
function speex_unloadDSPDLL(var speexDSPProc: tSpeexDSPLibrary_proc): int;


implementation


uses
  unaUtils;

// --  --
function speex_loadDLL(var speexProc: tSpeexLibrary_proc; const pathAndName: wString): int;
var
  libFile: wString;
begin
  with speexProc do begin
    //
    if (0 = r_module) then begin
      //
      r_module := 1;	// not zero
      //
      libFile := trimS(pathAndName);
      if ('' = libFile) then
	libFile := c_speexDLL;
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
	r_bits_init               := GetProcAddress(r_module, 'speex_bits_init');
	r_bits_init_buffer        := GetProcAddress(r_module, 'speex_bits_init_buffer');
	r_bits_set_bit_buffer     := GetProcAddress(r_module, 'speex_bits_set_bit_buffer');
	r_bits_destroy            := GetProcAddress(r_module, 'speex_bits_destroy');
	r_bits_reset              := GetProcAddress(r_module, 'speex_bits_reset');
	r_bits_rewind             := GetProcAddress(r_module, 'speex_bits_rewind');
	r_bits_read_from          := GetProcAddress(r_module, 'speex_bits_read_from');
	r_bits_read_whole_bytes   := GetProcAddress(r_module, 'speex_bits_read_whole_bytes');
	r_bits_write              := GetProcAddress(r_module, 'speex_bits_write');
	r_bits_write_whole_bytes  := GetProcAddress(r_module, 'speex_bits_write_whole_bytes');
	r_bits_pack               := GetProcAddress(r_module, 'speex_bits_pack');
	r_bits_unpack_signed      := GetProcAddress(r_module, 'speex_bits_unpack_signed');
	r_bits_unpack_unsigned    := GetProcAddress(r_module, 'speex_bits_unpack_unsigned');
	r_bits_nbytes             := GetProcAddress(r_module, 'speex_bits_nbytes');
	r_bits_peek_unsigned      := GetProcAddress(r_module, 'speex_bits_peek_unsigned');
	r_bits_peek               := GetProcAddress(r_module, 'speex_bits_peek');
	r_bits_advance            := GetProcAddress(r_module, 'speex_bits_advance');
	r_bits_remaining          := GetProcAddress(r_module, 'speex_bits_remaining');
	r_bits_insert_terminator  := GetProcAddress(r_module, 'speex_bits_insert_terminator');
	//
	r_encoder_init    := GetProcAddress(r_module, 'speex_encoder_init');
	r_encoder_destroy := GetProcAddress(r_module, 'speex_encoder_destroy');
	r_encode          := GetProcAddress(r_module, 'speex_encode');
	r_encode_int      := GetProcAddress(r_module, 'speex_encode_int');
	r_encoder_ctl     := GetProcAddress(r_module, 'speex_encoder_ctl');
	//
	r_decoder_init    := GetProcAddress(r_module, 'speex_decoder_init');
	r_decoder_destroy := GetProcAddress(r_module, 'speex_decoder_destroy');
	r_decode          := GetProcAddress(r_module, 'speex_decode');
	r_decode_int      := GetProcAddress(r_module, 'speex_decode_int');
	r_decoder_ctl     := GetProcAddress(r_module, 'speex_decoder_ctl');
	//
	r_mode_query      := GetProcAddress(r_module, 'speex_mode_query');
	r_lib_get_mode    := GetProcAddress(r_module, 'speex_lib_get_mode');
	//
	r_lib_ctl         := GetProcAddress(r_module, 'speex_lib_ctl');
	//
	r_moduleRefCount := 1;	// also, makes it non-zero (see below mscand)
	if (nil <> mscanp(@speexProc, nil, sizeof(speexProc))) then begin
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

//
function speex_unloadDLL(var speexProc: tSpeexLibrary_proc): int;
begin
  result := 0;
  //
  with speexProc do begin
    //
    if (0 <> r_module) then begin
      //
      if (0 < r_moduleRefCount) then
	dec(r_moduleRefCount);
      //
      if (1 > r_moduleRefCount) then begin
	//
	if (FreeLibrary(r_module)) then
	  fillChar(speexProc, sizeof(speexProc), 0)
	else
	  result := GetLastError();
      end;
    end;
  end;
end;

// --  --
function speex_loadDSPDLL(var speexDSPProc: tSpeexDSPLibrary_proc; const pathAndName: wString = c_speexDSPDLL): int;
var
  libFile: wString;
begin
  with speexDSPProc do begin
    //
    if (0 = r_module) then begin
      //
      r_module := 1;	// not zero
      //
      libFile := trimS(pathAndName);
      if ('' = libFile) then
	libFile := c_speexDSPDLL;
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
	r_speex_preprocess_state_init     	:= GetProcAddress(r_module, 'speex_preprocess_state_init');
	r_speex_preprocess_state_destroy  	:= GetProcAddress(r_module, 'speex_preprocess_state_destroy');
	r_speex_preprocess_run	          	:= GetProcAddress(r_module, 'speex_preprocess_run');
	r_speex_preprocess_estimate_update	:= GetProcAddress(r_module, 'speex_preprocess_estimate_update');
	r_speex_preprocess_ctl	      	  	:= GetProcAddress(r_module, 'speex_preprocess_ctl');
	//
	r_speex_echo_state_init	      		:= GetProcAddress(r_module, 'speex_echo_state_init');
	r_speex_echo_state_destroy	      	:= GetProcAddress(r_module, 'speex_echo_state_destroy');
	r_speex_echo_cancellation	      	:= GetProcAddress(r_module, 'speex_echo_cancellation');
	r_speex_echo_capture	      		:= GetProcAddress(r_module, 'speex_echo_capture');
	r_speex_echo_playback	      		:= GetProcAddress(r_module, 'speex_echo_playback');
	r_speex_echo_state_reset	      	:= GetProcAddress(r_module, 'speex_echo_state_reset');
	r_speex_echo_ctl		      	:= GetProcAddress(r_module, 'speex_echo_ctl');
	//
	r_speex_resampler_init	      		:= GetProcAddress(r_module, 'speex_resampler_init');
	r_speex_resampler_init_frac	      	:= GetProcAddress(r_module, 'speex_resampler_init_frac');
	r_speex_resampler_destroy	      	:= GetProcAddress(r_module, 'speex_resampler_destroy');
	r_speex_resampler_process_float   	:= GetProcAddress(r_module, 'speex_resampler_process_float');
	r_speex_resampler_process_int     	:= GetProcAddress(r_module, 'speex_resampler_process_int');
	r_speex_resampler_set_quality     	:= GetProcAddress(r_module, 'speex_resampler_set_quality');
	r_speex_resampler_get_quality     	:= GetProcAddress(r_module, 'speex_resampler_get_quality');
	r_speex_resampler_skip_zeros      	:= GetProcAddress(r_module, 'speex_resampler_skip_zeros');
	r_speex_resampler_reset_mem	      	:= GetProcAddress(r_module, 'speex_resampler_reset_mem');
	r_speex_resampler_strerror	      	:= GetProcAddress(r_module, 'speex_resampler_strerror');
	//
	r_moduleRefCount := 1;	// also, makes it non-zero (see below mscand)
	if (nil <> mscanp(@speexDSPProc, nil, sizeof(speexDSPProc))) then begin
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
function speex_unloadDSPDLL(var speexDSPProc: tSpeexDSPLibrary_proc): int;
begin
  result := 0;
  //
  with speexDSPProc do begin
    //
    if (0 <> r_module) then begin
      //
      if (0 < r_moduleRefCount) then
	dec(r_moduleRefCount);
      //
      if (1 > r_moduleRefCount) then begin
	//
	if (FreeLibrary(r_module)) then
	  fillChar(speexDSPProc, sizeof(speexDSPProc), 0)
	else
	  result := GetLastError();
      end;
    end;
  end;
end;


{ unaSpeexLib }

// --  --
procedure unaSpeexLib.BeforeDestruction();
begin
  speex_unloadDLL(f_lib);
  //
  inherited;
end;

// --  --
constructor unaSpeexLib.create(const libPath: wString);
begin
  inherited create();
  //
  f_lastError := speex_loadDLL(f_lib, libPath);
  f_libOK := (0 = f_lastError);
end;

// --  --
function unaSpeexLib.getLib(): pSpeexLibrary_proc;
begin
  result := @f_lib;
end;


{ unaSpeexCoder }

// --  --
procedure unaSpeexCoder.afterOpen();
begin
  //
end;

// --  --
procedure unaSpeexCoder.beforeClose();
begin
  //
end;

// --  --
procedure unaSpeexCoder.BeforeDestruction();
begin
  close();
  //
  inherited;
end;

// --  --
procedure unaSpeexCoder.close();
begin
  if (enter()) then try
    //
    if (active) then begin
      //
      beforeClose();
      //
      lib.api.r_bits_destroy(bits);
      //
      doClose();
      //
      f_frameSize := 0;
      f_state := nil;
      //
      mrealloc(f_outBuf);
      f_outBufSize := 0;
    end;
  finally
    leave();
  end;
end;

// --  --
constructor unaSpeexCoder.create(lib: unaSpeexLib; mode: int);
begin
  f_lib := lib;
  self.mode := mode;
  //
  inherited create();
end;

// --  --
function unaSpeexCoder.enter(timeout: tTimeout): bool;
begin
  result := lib.libOK and acquire(false, timeout, false {$IFDEF DEBUG }, '.enter()' {$ENDIF DEBUG });
end;

// --  --
function unaSpeexCoder.getActive(): bool;
begin
  result := (nil <> f_state);
end;

// --  --
function unaSpeexCoder.getBits(): pSpeexBits;
begin
  result := @f_bits;
end;

// --  --
function unaSpeexCoder.getFrameSize(): int;
begin
  result := 0;
  //
  if (enter(2000)) then try
    //
    if (active) then begin
      //
      if (0 < f_frameSize) then
	result := f_frameSize	// do not access frameSize property here (unless you wanna debug stack overflow)
      else begin
	//
	result := doGetFrameSize();
	f_frameSize := result;
      end;
    end;
  finally
    leave();
  end;
end;

// --  --
function unaSpeexCoder.getModeInfo(): pSpeexMode;
begin
  result := lib.api.r_lib_get_mode(mode);
end;

// --  --
function unaSpeexCoder.getSamplingRate(): int;
begin
  result := 0;
  //
  if (enter(2000)) then try
    //
    if (active) then
      result := doGetSamplingRate();
  finally
    leave();
  end;
end;

// --  --
procedure unaSpeexCoder.leave();
begin
  releaseWO();
end;

// --  --
function unaSpeexCoder.open(): bool;
begin
  if (enter(5000)) then try
    //
    if (not active) then begin
      //
      f_state := doInit();
      result := active;
      //
      if (active) then begin
	//
	lib.api.r_bits_init(bits);
	//
	doOpen();
      end;
      //
      afterOpen();
    end
    else
      result := true;
    //
  finally
    leave();
  end
  else
    result := active;
end;

// --  --
procedure unaSpeexCoder.setActive(value: bool);
begin
  if (value) then
    open()
  else
    close();
end;

// --  --
procedure unaSpeexCoder.setMode(value: int);
begin
  if (enter(5000)) then try
    //
    if (f_mode <> value) then
      close();
    //
    f_mode := value;
  finally
    leave();
  end;
end;


{ unaSpeexEncoder }

// --  --
procedure unaSpeexEncoder.add_frame_int(samples: pointer; vad: bool);
begin
  //
  // assuming encoder is active and in "enter()" state
  //
  if (f_vad_prev and not vad) then begin
    //
    if (0 = f_vad_cooldown) then begin
      //
      f_vad_cooldown := 21;	// 20 * 20ms = 200ms
      vad := true;	// override vad
    end
    else begin
      //
      if (1 < f_vad_cooldown) then begin
	//
	dec(f_vad_cooldown);
	vad := true;	// override vad
      end
      else begin
	//
	f_vad_prev := false;
      end;
    end;
  end
  else begin
    //
    f_vad_prev := vad;
    //
    if (vad) then
      f_vad_cooldown := 0;
  end;
  //
  if (vad or vbr) then begin
    //
    if (f_op4RTP) then begin
      //
      if (0 = f_op4RTP_framesCollected) then
	lib.api.r_bits_reset(bits);
      //
      lib.api.r_encode_int(state, samples, bits);
      //
      inc(f_op4RTP_framesCollected);
      if ((c_opt4RTP_numframes - 1 < f_op4RTP_framesCollected) or (c_opt4RTP_numbytes < lib.api.r_bits_nbytes(bits))) then begin
	//
	notify_data();
	f_op4RTP_framesCollected := 0;
      end;
    end
    else begin
      //
      lib.api.r_bits_reset(bits);
      lib.api.r_encode_int(state, samples, bits);
      notify_data();
    end;
  end;
end;

// --  --
procedure unaSpeexEncoder.AfterConstruction();
begin
  f_quality := 7;
  f_vbr := false;
  f_vbrQuality := 5;
  //
  inherited;
end;

// --  --
procedure unaSpeexEncoder.assignDSP(dsp: unaSpeexDSP; aec: bool);
begin
  if (enter()) then try
    //
    f_dsp := dsp;
    f_aec := aec;
    //
    if (active and (nil <> dsp)) then
      dsp.open(frameSize, samplingRate, aec);
  finally
    leave();
  end;
end;

// --  --
procedure unaSpeexEncoder.doClose();
begin
  if (enter()) then try
    //
    lib.api.r_encoder_destroy(state);
    //
    mrealloc(f_subBuf);
    //
    if (nil <> dsp) then
      dsp.close();
  finally
    leave();
  end;
end;

// --  --
function unaSpeexEncoder.doGetFrameSize(): int;
begin
  lib.api.r_encoder_ctl(state, SPEEX_GET_FRAME_SIZE, @result);
end;

// --  --
function unaSpeexEncoder.doGetSamplingRate(): int;
begin
  lib.api.r_encoder_ctl(state, SPEEX_GET_SAMPLING_RATE, @result);
end;

// --  --
function unaSpeexEncoder.doInit(): pointer;
begin
  result := lib.api.r_encoder_init(modeInfo);
end;

// --  --
procedure unaSpeexEncoder.doOpen();
begin
  if (enter()) then try
    //
    quality := f_quality;
    //
    vbr := f_vbr;
    vbrQuality := f_vbrQuality;
    //
    if (0 < f_bitrate) then
      bitrate := f_bitrate;
    //
    if (0 < f_abr) then
      abr := f_abr;
    //
    mrealloc(f_subBuf, frameSize shl 1);
    f_subBufPos := 0;
    //
    if (nil <> dsp) then
      dsp.open(frameSize, samplingRate, aec);
    //
  finally
    leave();
  end;
end;

// --  --
procedure unaSpeexEncoder.encoder_write(sampleDelta: uint; data: pointer; size: uint; numFrames: uint);
begin
  // override this method to get notified of new data
end;

// --  --
function unaSpeexEncoder.encode_int(samples: pointer; size: int): int;
var
  sz: int;
  fs2: int;
  vad: bool;
begin
  result := 0;
  //
  if (active and (nil <> samples) and (0 < size)) then begin
    //
    if (enter(1000)) then try
      //
      inc(f_sampleDelta, size shr 1);
      //
      fs2 := frameSize shl 1;
      //
      // 1) do we have some bytes left from previous call?
      //
      if (0 < f_subBufPos) then begin
	//
	// 1.1) do we have enough bytes for a frame?
	//
	if (fs2 <= f_subBufPos + size) then begin
	  //
	  // 1.1.1) if we combine previous and "new" bytes, it will be a full frame
	  //
	  sz := fs2 - f_subBufPos;	// numbers of bytes to add to sub-buffer
	  move(samples^, f_subBuf[f_subBufPos], sz);
	  //
	  vad := true;
	  if (nil <> f_dsp) then begin
	    //
	    f_dsp.preprocess(pointer(f_subBuf));
	    if (f_dsp.dsp_VAD) then
	      vad := f_dsp.lastFrameVAD
	  end;
	  add_frame_int(f_subBuf, vad);	// write full frame
	  //
	  f_subBufPos := 0;	// no more data in sub-frame
	  //
	  dec(size, sz);	// decrease the size of buffer
	  samples := @pArray(samples)[sz];	// and move the pointer
	end
	else begin
	  //
	  // 1.1.2) not enough bytes to make a frame, just add what we got to sub-buffer
	  //
	  sz := size;
	  move(samples^, f_subBuf[f_subBufPos], sz);
	  //
	  inc(f_subBufPos, sz);
	  //
	  dec(size, sz);	// size will be 0
	end;
	//
	inc(result, sz);
      end;
      //
      // 2) write full frames (if any)
      while (fs2 <= size) do begin
	//
	vad := true;
	if (nil <> f_dsp) then begin
	  //
	  f_dsp.preprocess(samples);
	  if (f_dsp.dsp_VAD) then
	    vad := f_dsp.lastFrameVAD
	end;
	add_frame_int(samples, vad);	// write full frame
	//
	dec(size, fs2);	// decrease the size of buffer
	samples := @pArray(samples)[fs2];	// and move the pointer
	//
	inc(result, fs2);
      end;
      //
      // 3) some samples left?
      if (0 < size) then begin
	//
	// 3.1) store them in sub-buffer, so they will be used in next call
	//
	move(samples^, f_subBuf^, size);
	f_subBufPos := size;
	//
	inc(result, size);
      end;
    finally
      leave();
    end
    else
      result := -1;
  end;
end;

// --  --
function unaSpeexEncoder.getABR(): int;
begin
  result := 0;
  //
  if (enter(2000)) then try
    //
    if (active) then
      lib.api.r_encoder_ctl(state, SPEEX_GET_ABR, @result);
  finally
    leave();
  end;
end;

// --  --
function unaSpeexEncoder.getBitrate(): int;
begin
  result := 0;
  //
  if (enter(2000)) then try
    //
    if (active) then
      lib.api.r_encoder_ctl(state, SPEEX_GET_BITRATE, @result);
  finally
    leave();
  end;
end;

// --  --
function unaSpeexEncoder.getComplexity(): int;
begin
  result := 0;
  //
  if (enter(2000)) then try
    //
    if (active) then
      lib.api.r_encoder_ctl(state, SPEEX_GET_COMPLEXITY, @result);
  finally
    leave();
  end;
end;

// --  --
function unaSpeexEncoder.getIntValue(index: Integer): int32;
begin
  lib.api.r_encoder_ctl(state, index + 1, @result);	// "index + 1" in extremely dirty hack, but seem to be OK for now
end;

// --  --
function unaSpeexEncoder.getQuality(): int;
begin
  result := f_quality;
end;

// --  --
function unaSpeexEncoder.getVbr(): bool;
var
  res: int32;
begin
  if (enter(2000)) then try
    //
    if (active) then begin
      //
      res := 0;
      lib.api.r_encoder_ctl(state, SPEEX_GET_VBR, @res);
      result := (0 <> res);
    end
    else
      result := f_vbr;
  finally
    leave();
  end
  else
    result := f_vbr;
end;

// --  --
function unaSpeexEncoder.getVbrQ(): float;
begin
  result := f_vbrQuality;
  //
  if (enter(2000)) then try
    //
    if (active) then
      lib.api.r_encoder_ctl(state, SPEEX_GET_VBR_QUALITY, @result);
  finally
    leave();
  end;
end;

// --  --
procedure unaSpeexEncoder.notify_data();
var
  nbBytes: int;
begin
  // assuming encoder is active and in "enter()" state
  //
  nbBytes := lib.api.r_bits_nbytes(bits);
  if (nbBytes > f_outBufSize) then begin
    //
    mrealloc(f_outBuf, nbBytes);
    f_outBufSize := nbBytes;
  end;
  //
  nbBytes := lib.api.r_bits_write(bits, f_outBuf, f_outBufSize);
  //
  encoder_write(f_sampleDelta, f_outBuf, nbBytes, choice(optimizeForRTP, f_op4RTP_framesCollected, 1));
  f_sampleDelta := 0;
end;

// --  --
procedure unaSpeexEncoder.setABR(value: int);
begin
  if (enter(2000)) then try
    //
    if (active) then
      lib.api.r_encoder_ctl(state, SPEEX_SET_ABR, @value);
    //
    f_abr := value;
  finally
    leave();
  end;
end;

// --  --
procedure unaSpeexEncoder.setBitrate(value: int);
begin
  if (enter(2000)) then try
    //
    if (active) then
      lib.api.r_encoder_ctl(state, SPEEX_SET_BITRATE, @value);
    //
    f_bitrate := value;
  finally
    leave();
  end;
end;

// --  --
procedure unaSpeexEncoder.setComplexity(value: int);
begin
  if (enter(2000)) then try
    //
    if (active) then
      lib.api.r_encoder_ctl(state, SPEEX_SET_COMPLEXITY, @value);
    //
    f_complexity := value;
  finally
    leave();
  end;
end;

// --  --
procedure unaSpeexEncoder.setIntValue(index: Integer; value: int32);
begin
  // credits: Ozz Nixon
  lib.api.r_encoder_ctl(state, index, @value);
end;

// --  --
procedure unaSpeexEncoder.setQuality(value: int);
begin
  if (enter(2000)) then try
    //
    if (active) then
      lib.api.r_encoder_ctl(state, SPEEX_SET_QUALITY, @value);
    //
    f_quality := value;
  finally
    leave();
  end;
end;

// --  --
procedure unaSpeexEncoder.setVbr(value: bool);
var
  data: int32;
begin
  if (enter()) then try
    //
    if (active) then begin
      //
      data := choice(value, 1, int32(0));
      lib.api.r_encoder_ctl(state, SPEEX_SET_VBR, @data);
      //
      vbrQuality := f_vbrQuality;
    end;
    //
    f_vbr := value;
  finally
    leave();
  end;
end;

// --  --
procedure unaSpeexEncoder.setVbrQ(const value: float);
begin
  if (enter(2000)) then try
    //
    if (active) then
      lib.api.r_encoder_ctl(state, SPEEX_SET_VBR_QUALITY, @value);
    //
    f_vbrQuality := value;
  finally
    leave();
  end;
end;


{ unaSpeexDecoder }

// --  --
procedure unaSpeexDecoder.decoder_write_int(samples: pointer; size: int);
begin
  // override this method to get notified of new data
end;

// --  --
function unaSpeexDecoder.decode(bitstream: pointer; size: int): int;
begin
  result := 0;
  //
  if (active and (nil <> bitstream) and (0 < size)) then begin
    //
    if (enter(1000)) then try
      //
      lib.api.r_bits_read_from(bits, bitstream, size);
      result := lib.api.r_bits_remaining(bits) shr 3;
      //
      if (1 > f_outBufSize) then begin
	//
	// one frame at a time
	f_outBufSize := frameSize shl 2;
	mrealloc(f_outBuf, f_outBufSize);
      end;
      //
      while (7 < lib.api.r_bits_remaining(bits)) do begin
	//
	if (0 = lib.api.r_decode_int(state, bits, f_outBuf)) then
	  decoder_write_int(f_outBuf, frameSize shl 1)
	else
	  break;
      end;
      //
    finally
      leave();
    end
    else
      result := -1;
  end;
end;

// --  --
procedure unaSpeexDecoder.doClose();
begin
  lib.api.r_decoder_destroy(state);
end;

// --  --
function unaSpeexDecoder.doGetFrameSize(): int;
begin
  lib.api.r_decoder_ctl(state, SPEEX_GET_FRAME_SIZE, @result);
end;

// --  --
function unaSpeexDecoder.doGetSamplingRate(): int;
begin
  lib.api.r_decoder_ctl(state, SPEEX_GET_SAMPLING_RATE, @result);
end;

// --  --
function unaSpeexDecoder.doInit(): pointer;
begin
  result := lib.api.r_decoder_init(modeInfo);
end;

// --  --
procedure unaSpeexDecoder.doOpen();
begin
  // nothing to do here so far
end;

// --  --
function unaSpeexDecoder.getIntValue(index: Integer): int32;
begin
  lib.api.r_decoder_ctl(state, index + 1, @result);	// "index + 1" in extremely dirty hack, but seem to be OK for now
end;

// --  --
procedure unaSpeexDecoder.setIntValue(index: Integer; value: int32);
begin
  // credits: Ozz Nixon
  lib.api.r_decoder_ctl(state, index, @value);
end;


{ unaSpeexDSP }

// --  --
procedure unaSpeexDSP.close();
begin
  if (lock()) then try
    //
    f_active := false;
    //
    if (nil <> f_st_dsp) then
      api.r_speex_preprocess_state_destroy(f_st_dsp);
    f_st_dsp := nil;
    //
    if (nil <> f_st_aec) then
      api.r_speex_echo_state_destroy(f_st_aec);
    f_st_aec := nil;
    //
    if (nil <> f_st_resampler) then
      api.r_speex_resampler_destroy(f_st_resampler);
    f_st_resampler := nil;
    //
  finally
    unlock();
  end;
end;

// --  --
constructor unaSpeexDSP.create(const libName: wString);
begin
  f_error := speex_loadDSPDLL(f_lib, libName);
  f_libOK := (0 = error);
  //
  inherited create();
end;

// --  --
destructor unaSpeexDSP.Destroy();
begin
  close();
  //
  inherited;
end;

// --  --
function unaSpeexDSP.dsp_getBool(index: integer): bool;
var
  r: spx_int32_t;
begin
  if (not active) then begin
    //
    if (f_dsp_paramsValid[index]) then
      result := f_dsp_params[index]
    else
      result := false;
  end
  else begin
    //
    case (index) of

      0: begin
	//
	api.r_speex_preprocess_ctl(f_st_dsp, SPEEX_PREPROCESS_GET_DENOISE, @r);
	result := (0 <> r);
      end;

      1: begin
	//
	api.r_speex_preprocess_ctl(f_st_dsp, SPEEX_PREPROCESS_GET_AGC, @r);
	result := (0 <> r);
      end;

      2: begin
	//
	api.r_speex_preprocess_ctl(f_st_dsp, SPEEX_PREPROCESS_GET_VAD, @r);
	result := (0 <> r);
      end;

      3: begin
	//
	api.r_speex_preprocess_ctl(f_st_dsp, SPEEX_PREPROCESS_GET_DEREVERB, @r);
	result := (0 <> r);
      end;

      else
	result := false;

    end;
  end;
end;

// --  --
procedure unaSpeexDSP.dsp_setBool(index: integer; value: bool);
var
  r: spx_int32_t;
begin
  f_dsp_params[index] := value;
  f_dsp_paramsValid[index] := true;
  //
  if (active) then begin
    //
    r := choice(value, 1, int(0));
    case (index) of
      0: api.r_speex_preprocess_ctl(f_st_dsp, SPEEX_PREPROCESS_SET_DENOISE, @r);
      1: api.r_speex_preprocess_ctl(f_st_dsp, SPEEX_PREPROCESS_SET_AGC, @r);
      2: api.r_speex_preprocess_ctl(f_st_dsp, SPEEX_PREPROCESS_SET_VAD, @r);
      3: api.r_speex_preprocess_ctl(f_st_dsp, SPEEX_PREPROCESS_SET_DEREVERB, @r);
    end;
  end;
end;

// --  --
procedure unaSpeexDSP.echo_capture(inFrame, outFrame: pspx_int16_t);
begin
  if (active and (nil <> f_st_aec)) then
    api.r_speex_echo_capture(f_st_aec, inFrame, outFrame);
end;

// --  --
procedure unaSpeexDSP.echo_playback(frame: pspx_int16_t);
begin
  if (active and (nil <> f_st_aec)) then
    api.r_speex_echo_playback(f_st_aec, frame);
end;

// --  --
function unaSpeexDSP.getAcgLdn(): float;
begin
  if (active) then
    api.r_speex_preprocess_ctl(f_st_dsp, SPEEX_PREPROCESS_GET_AGC_LOUDNESS, @result)
  else
    result := 0;
end;

// --  --
function unaSpeexDSP.getAcgLvl(): float;
begin
  if (active) then
    api.r_speex_preprocess_ctl(f_st_dsp, SPEEX_PREPROCESS_GET_AGC_LEVEL, @result)
  else
    result := 0;
end;

// --  --
function unaSpeexDSP.getLib(): pSpeexDSPLibrary_proc;
begin
  result := @f_lib;
end;

// --  --
function unaSpeexDSP.lock(timeout: tTimeout): bool;
begin
  result := acquire(false, timeout, false {$IFDEF DEBUG }, '.lock()' {$ENDIF DEBUG });
end;

// --  --
function unaSpeexDSP.open(frameSize, samplingRate: int; aec: bool): int;
var
  i: int;
begin
  result := -2;
  //
  if (lock()) then try
    //
    close();
    //
    f_frameSize := frameSize;
    f_samplingRate := samplingRate;
    //
    f_st_dsp := api.r_speex_preprocess_state_init(frameSize, samplingRate);
    //
    if (aec) then
      f_st_aec := api.r_speex_echo_state_init(frameSize, samplingRate div 10);
    //
    if ( (nil <> f_st_dsp) and (not aec or (aec and (nil <> f_st_aec))) ) then
      f_error := 0
    else
      f_error := -1;
    //
    if (0 = error) then begin
      //
      for i  := low(f_dsp_params) to high(f_dsp_params) do begin
	//
	if (f_dsp_paramsValid[i]) then
	  dsp_setBool(i, f_dsp_params[i]);
      end;
    end;
    //
    if ((0 = error) and aec) then
      api.r_speex_preprocess_ctl(f_st_dsp, SPEEX_PREPROCESS_SET_ECHO_STATE, f_st_aec);
    //
    result := error;
    //
    f_active := (0 = result);
    //
    if (active) then
      f_sps := samplingRate;
    //
  finally
    unlock();
  end;
end;

// --  --
function unaSpeexDSP.preprocess(frame: pspx_int16_t): bool;
begin
  if (nil <> f_st_dsp) then
    result := (0 <> api.r_speex_preprocess_run(f_st_dsp, frame))
  else
    result := false;
  //
  f_lfv := result;
end;

// --  --
function unaSpeexDSP.resampleDst(srcFrame: pspx_int16_t; var srcSamples: spx_uint32_t; outBuf: pspx_int16_t; outSamplingRate: int; var outBufUsed: spx_uint32_t): uint;
var
  err: int;
begin
  result := 0;
  //
  if ((nil <> f_st_resampler) and (f_lastResampleDst <> outSamplingRate)) then begin
    //
    // close old resampler opened for different rate
    api.r_speex_resampler_destroy(f_st_resampler);
    f_st_resampler := nil;
    //
    f_lastResampleDst := 0;
    f_lastResampleSrc := 0;
  end;
  //
  if (nil = f_st_resampler) then begin
    //
    f_st_resampler := api.r_speex_resampler_init(1, samplingRate, outSamplingRate, 6, err);
    if (0 = err) then begin
      //
      f_lastResampleDst := outSamplingRate;
      f_lastResampleSrc := samplingRate;
    end;
  end;
  //
  if ((nil <> f_st_resampler) and (f_lastResampleDst = outSamplingRate)) then begin
    //
    err := api.r_speex_resampler_process_int(f_st_resampler, 0, srcFrame, srcSamples, outBuf, outBufUsed);
    if (0 = err) then
      result := srcSamples;	// return number of samples read from srcFrame
  end;
end;

// --  --
function unaSpeexDSP.resampleSrc(srcFrame: pspx_int16_t; var srcSamples: spx_uint32_t; srcSamplingRate: int; outBuf: pspx_int16_t; var outBufUsed: spx_uint32_t): uint;
var
  err: int;
begin
  result := 0;
  //
  if ((nil <> f_st_resampler) and (f_lastResampleSrc <> srcSamplingRate)) then begin
    //
    // close old resampler opened for different rate
    api.r_speex_resampler_destroy(f_st_resampler);
    f_st_resampler := nil;
    //
    f_lastResampleSrc := 0;
    f_lastResampleDst := 0;
  end;
  //
  if (nil = f_st_resampler) then begin
    //
    f_st_resampler := api.r_speex_resampler_init(1, srcSamplingRate, samplingRate, 6, err);
    if (0 = err) then begin
      //
      f_lastResampleSrc := srcSamplingRate;
      f_lastResampleDst := samplingRate;
    end;
  end;
  //
  if ((nil <> f_st_resampler) and (f_lastResampleSrc = srcSamplingRate)) then begin
    //
    err := api.r_speex_resampler_process_int(f_st_resampler, 0, srcFrame, srcSamples, outBuf, outBufUsed);
    if (0 = err) then
      result := srcSamples;	// return number of samples read from srcFrame
  end;
end;

// --  --
procedure unaSpeexDSP.unlock();
begin
  releaseWO();
end;


end.

