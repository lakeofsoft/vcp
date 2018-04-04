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

	  unaVorbisAPI.pas
	  API for Vorbis and Ogg libraries

	----------------------------------------------
	  Delphi API wrapper:

	  Copyright (c) 2002-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 02 Nov 2002

	  modified by:
		Lake, Nov 2002
		Lake, Dec 2010

	----------------------------------------------
*)

{$I unaDef.inc }

{$I unaVorbisDef.inc }

{*
  OGG/Vorbis wrapper.

  @Author Lake
  
	Version 2.5.2008.07 Still here

 	Version 2.5.2008.12 libvorbis.dll stuff
}

unit
  unaVorbisAPI;

interface

uses
  Windows, unaTypes, unaClasses;

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

 function: toplevel libogg include
 last mod: $Id: ogg.h,v 1.18 2002/07/13 10:28:33 giles Exp $

 ********************************************************************)

//#include <ogg/os_types.h>
type
  pogg_int64_t = ^ogg_int64_t;
  ogg_int64_t = int64;
  //
  ogg_int32_t = longInt;
  ogg_uint32_t = longWord;
  ogg_int16_t = smallInt;

  // --  --
  pOggpack_buffer = ^tOggpack_buffer;
  tOggpack_buffer = packed record
    {+00}endbyte: ogg_int32_t;
    {+04}endbit: ogg_int32_t;
    //
    {+08}buffer: pointer;
    {+0C}ptr: pointer;
    {+10}storage: ogg_int32_t;
    {+14}
  end;

  // --  --
  pOgg_packet = ^tOgg_packet;
  tOgg_packet = packed record
    packet: pointer;
    bytes: ogg_int32_t;
    b_o_s: ogg_int32_t;
    e_o_s: ogg_int32_t;
    //
    granulepos: ogg_int64_t;

    packetno: ogg_int64_t;     ///* sequence number for decode; the framing
			       // knows where there's a hole in the data,
			       // but we need coupling so that the codec
			       // (which is in a seperate abstraction
			       // layer) also knows about the gap */
    {+20}
  end;


{$IFNDEF VC_LIBVORBIS_ONLY }

//* ogg_page is used to encapsulate the data in one Ogg bitstream page *****/

  // --  --
  pOgg_page = ^tOgg_page;
  tOgg_page = packed record
    {+00}header: pointer;
    {+04}header_len: ogg_int32_t;
    {+08}body: pointer;
    {+0C}body_len: ogg_int32_t;
    {+10}
  end;

//* ogg_stream_state contains the current encode/decode state of a logical
//   Ogg bitstream **********************************************************/

  // --  --
  pOgg_stream_state = ^tOgg_stream_state;
  tOgg_stream_state = packed record
    {+00}body_data: pointer;    //* bytes from packet bodies */
    {+04}body_storage: ogg_int32_t;    //* storage elements allocated */
    {+08}body_fill: ogg_int32_t;       //* elements stored; fill mark */
    {+0C}body_returned: ogg_int32_t;   //* elements of fill returned */

    {+10}lacing_vals: ^ogg_int32_t;      //* The values that will go to the segment table */
    {+14}granule_vals: pogg_int64_t;	//* granulepos values for headers. Not compact
				//  this way, but it is simple coupled to the
				//  lacing fifo */
    {+18}lacing_storage: ogg_int32_t;
    {+1C}lacing_fill: ogg_int32_t;
    {+20}lacing_packet: ogg_int32_t;
    {+24}lacing_returned: ogg_int32_t;

    {+28}header: array [0..284 - 1] of byte;      //* working space for header encode */
    {+144}header_fill: ogg_int32_t;

    {+148}e_o_s: ogg_int32_t;          //* set when we have buffered the last packet in the
			 //      logical bitstream */
    {+14C}b_o_s: ogg_int32_t;          //* set after we've written the initial page
			 //      of a logical bitstream */
    {+150}serialno: ogg_int32_t;
    {+154}pageno: ogg_int32_t;
    {+158}packetno: ogg_int64_t;     //* sequence number for decode; the framing
			       //knows where there's a hole in the data,
			       //but we need coupling so that the codec
			       //(which is in a seperate abstraction
			       //layer) also knows about the gap */
    {+160}granulepos: ogg_int64_t;
    {+168}
  end;

//* ogg_packet is used to encapsulate the data and metadata belonging
//   to a single raw Ogg/Vorbis packet *************************************/

  // --  --
  pOgg_sync_state = ^tOgg_sync_state;
  tOgg_sync_state = packed record
    data: pointer;
    storage: ogg_int32_t;
    fill: ogg_int32_t;
    returned: ogg_int32_t;
    //
    unsynced: ogg_int32_t;
    headerbytes: ogg_int32_t;
    bodybytes: ogg_int32_t;
  end;

//* Ogg BITSTREAM PRIMITIVES: bitstream ************************/

//extern void  oggpack_writeinit(oggpack_buffer *b);
  toggpack_writeinit = procedure(const b: tOggpack_buffer); cdecl;

//extern void  oggpack_writetrunc(oggpack_buffer *b,ogg_int32_t bits);
  toggpack_writetrunc = procedure(const b: tOggpack_buffer; bits: ogg_int32_t); cdecl;

//extern void  oggpack_writealign(oggpack_buffer *b);
  toggpack_writealign = procedure(const b: tOggpack_buffer); cdecl;

//extern void  oggpack_writecopy(oggpack_buffer *b,void *source,ogg_int32_t bits);
  toggpack_writecopy = procedure(const b: tOggpack_buffer; source: pointer; bits: ogg_int32_t); cdecl;

//extern void  oggpack_reset(oggpack_buffer *b);
  toggpack_reset = procedure(const b: tOggpack_buffer); cdecl;

//extern void  oggpack_writeclear(oggpack_buffer *b);
  toggpack_writeclear = procedure(const b: tOggpack_buffer); cdecl;

//extern void  oggpack_readinit(oggpack_buffer *b,unsigned char *buf,ogg_int32_t bytes);
  toggpack_readinit = procedure(const b: tOggpack_buffer; buf: pointer; bytes: ogg_int32_t); cdecl;

//extern void  oggpack_write(oggpack_buffer *b,unsigned ogg_int32_t value,ogg_int32_t bits);
  toggpack_write = procedure(const b: tOggpack_buffer; value: ogg_uint32_t; bits: ogg_int32_t); cdecl;

//extern ogg_int32_t  oggpack_look(oggpack_buffer *b,ogg_int32_t bits);
  toggpack_look = function(const b: tOggpack_buffer; bits: ogg_int32_t): ogg_int32_t; cdecl;

//extern ogg_int32_t  oggpack_look1(oggpack_buffer *b);
  toggpack_look1 = function(const b: tOggpack_buffer; bits: ogg_int32_t): ogg_int32_t; cdecl;

//extern void  oggpack_adv(oggpack_buffer *b,ogg_int32_t bits);
  toggpack_adv = procedure(const b: tOggpack_buffer; bits: ogg_int32_t); cdecl;

//extern void  oggpack_adv1(oggpack_buffer *b);
  toggpack_adv1 = procedure(const b: tOggpack_buffer); cdecl;

//extern ogg_int32_t  oggpack_read(oggpack_buffer *b,ogg_int32_t bits);
  toggpack_read = function(const b: tOggpack_buffer; bits: ogg_int32_t): ogg_int32_t; cdecl;

//extern ogg_int32_t  oggpack_read1(oggpack_buffer *b);
  toggpack_read1 = function(const b: tOggpack_buffer): ogg_int32_t; cdecl;

//extern ogg_int32_t  oggpack_bytes(oggpack_buffer *b);
  toggpack_bytes = function(const b: tOggpack_buffer): ogg_int32_t; cdecl;

//extern ogg_int32_t  oggpack_bits(oggpack_buffer *b);
  toggpack_bits = function(const b: tOggpack_buffer): ogg_int32_t; cdecl;

//extern unsigned char *oggpack_get_buffer(oggpack_buffer *b);
  toggpack_get_buffer = function(const b: tOggpack_buffer): pointer; cdecl;

///* Ogg BITSTREAM PRIMITIVES: encoding **************************/

//extern ogg_int32_t      ogg_stream_packetin(ogg_stream_state *os, ogg_packet *op);
  togg_stream_packetin = function(const os: tOgg_stream_state; const op: tOgg_packet): ogg_int32_t; cdecl;

//extern ogg_int32_t      ogg_stream_pageout(ogg_stream_state *os, ogg_page *og);
  togg_stream_pageout = function(const os: tOgg_stream_state; const og: tOgg_page): ogg_int32_t; cdecl;

//extern ogg_int32_t      ogg_stream_flush(ogg_stream_state *os, ogg_page *og);
  togg_stream_flush = function(const os: tOgg_stream_state; const og: tOgg_page): ogg_int32_t; cdecl;

///* Ogg BITSTREAM PRIMITIVES: decoding **************************/

//extern ogg_int32_t    ogg_sync_init(ogg_sync_state *oy);
  togg_sync_init = function(var oy: tOgg_sync_state): ogg_int32_t; cdecl;

//extern ogg_int32_t    ogg_sync_clear(ogg_sync_state *oy);
  togg_sync_clear = function(const oy: tOgg_sync_state): ogg_int32_t; cdecl;

//extern ogg_int32_t    ogg_sync_reset(ogg_sync_state *oy);
  togg_sync_reset = function(const oy: tOgg_sync_state): ogg_int32_t; cdecl;

//extern ogg_int32_t	ogg_sync_destroy(ogg_sync_state *oy);
  togg_sync_destroy = function(var oy: tOgg_sync_state): ogg_int32_t; cdecl;

//extern char    *ogg_sync_buffer(ogg_sync_state *oy, ogg_int32_t size);
  togg_sync_buffer = function(const oy: tOgg_sync_state; size: ogg_int32_t): pAnsiChar; cdecl;

//extern ogg_int32_t      ogg_sync_wrote(ogg_sync_state *oy, ogg_int32_t bytes);
  togg_sync_wrote = function(const oy: tOgg_sync_state; bytes: ogg_int32_t): ogg_int32_t; cdecl;

//extern ogg_int32_t     ogg_sync_pageseek(ogg_sync_state *oy,ogg_page *og);
  togg_sync_pageseek = function(const oy: tOgg_sync_state; const og: tOgg_page): ogg_int32_t; cdecl;

//extern ogg_int32_t      ogg_sync_pageout(ogg_sync_state *oy, ogg_page *og);
  togg_sync_pageout = function(const oy: tOgg_sync_state; const og: tOgg_page): ogg_int32_t; cdecl;

//extern ogg_int32_t      ogg_stream_pagein(ogg_stream_state *os, ogg_page *og);
  togg_stream_pagein = function(const os: tOgg_stream_state; const og: tOgg_page): ogg_int32_t; cdecl;

//extern ogg_int32_t      ogg_stream_packetout(ogg_stream_state *os,ogg_packet *op);
  togg_stream_packetout = function(const os: tOgg_stream_state; const op: tOgg_packet): ogg_int32_t; cdecl;

//extern ogg_int32_t      ogg_stream_packetpeek(ogg_stream_state *os,ogg_packet *op);
  togg_stream_packetpeek = function(const os: tOgg_stream_state; const op: tOgg_packet): ogg_int32_t; cdecl;

//* Ogg BITSTREAM PRIMITIVES: general ***************************/

//extern ogg_int32_t      ogg_stream_init(ogg_stream_state *os,ogg_int32_t serialno);
  togg_stream_init = function(var os: tOgg_stream_state; serialno: ogg_int32_t): ogg_int32_t; cdecl;

//extern ogg_int32_t      ogg_stream_clear(ogg_stream_state *os);
  togg_stream_clear = function(const os: tOgg_stream_state): ogg_int32_t; cdecl;

//extern ogg_int32_t      ogg_stream_reset(ogg_stream_state *os);
  togg_stream_reset = function(const os: tOgg_stream_state): ogg_int32_t; cdecl;

//extern ogg_int32_t      ogg_stream_reset_serialno(ogg_stream_state *os,ogg_int32_t serialno);
  togg_stream_reset_serialno = function(const os: tOgg_stream_state; serialno: ogg_int32_t): ogg_int32_t; cdecl;

//extern ogg_int32_t      ogg_stream_destroy(ogg_stream_state *os);
  togg_stream_destroy = function(const os: tOgg_stream_state): ogg_int32_t; cdecl;

//extern ogg_int32_t      ogg_stream_eos(ogg_stream_state *os);
  togg_stream_eos = function(const os: tOgg_stream_state): ogg_int32_t; cdecl;

//extern void     ogg_page_checksum_set(ogg_page *og);
  togg_page_checksum_set = procedure(const og: tOgg_page); cdecl;

//extern ogg_int32_t      ogg_page_version(ogg_page *og);
  togg_page_version = function(const og: tOgg_page): ogg_int32_t; cdecl;

//extern ogg_int32_t      ogg_page_continued(ogg_page *og);
  togg_page_continued = function(const og: tOgg_page): ogg_int32_t; cdecl;

//extern ogg_int32_t      ogg_page_bos(ogg_page *og);
  togg_page_bos = function(const og: tOgg_page): ogg_int32_t; cdecl;

//extern ogg_int32_t      ogg_page_eos(ogg_page *og);
  togg_page_eos = function(const og: tOgg_page): ogg_int32_t; cdecl;

//extern ogg_int64_t  ogg_page_granulepos(ogg_page *og);
  togg_page_granulepos = function(const og: tOgg_page): ogg_int64_t; cdecl;

//extern ogg_int32_t      ogg_page_serialno(ogg_page *og);
  togg_page_serialno = function(const og: tOgg_page): ogg_int32_t; cdecl;

//extern ogg_int32_t     ogg_page_pageno(ogg_page *og);
  togg_page_pageno = function(const og: tOgg_page): ogg_int32_t; cdecl;

//extern ogg_int32_t      ogg_page_packets(ogg_page *og);
  togg_page_packets = function(const og: tOgg_page): ogg_int32_t; cdecl;

//extern void     ogg_packet_clear(ogg_packet *op);
  togg_packet_clear = procedure(const op: tOgg_packet); cdecl;

//-----------------------------------------

procedure oggpack_writeinit(const b: tOggpack_buffer);
procedure oggpack_writetrunc(const b: tOggpack_buffer; bits: ogg_int32_t);
procedure oggpack_writealign(const b: tOggpack_buffer);
procedure oggpack_writecopy(const b: tOggpack_buffer; source: pointer; bits: ogg_int32_t);
procedure oggpack_reset(const b: tOggpack_buffer);
procedure oggpack_writeclear(const b: tOggpack_buffer);
procedure oggpack_readinit(const b: tOggpack_buffer; buf: pointer; bytes: ogg_int32_t);
procedure oggpack_write(const b: tOggpack_buffer; value: ogg_uint32_t; bits: ogg_int32_t);
function oggpack_look(const b: tOggpack_buffer; bits: ogg_int32_t): ogg_int32_t;
function oggpack_look1(const b: tOggpack_buffer; bits: ogg_int32_t): ogg_int32_t;
procedure oggpack_adv(const b: tOggpack_buffer; bits: ogg_int32_t);
procedure oggpack_adv1(const b: tOggpack_buffer);
function oggpack_read(const b: tOggpack_buffer; bits: ogg_int32_t): ogg_int32_t;
function oggpack_read1(const b: tOggpack_buffer): ogg_int32_t;
function oggpack_bytes(const b: tOggpack_buffer): ogg_int32_t;
function oggpack_bits(const b: tOggpack_buffer): ogg_int32_t;
function oggpack_get_buffer(const b: tOggpack_buffer): pointer;
function ogg_stream_packetin(const os: tOgg_stream_state; const op: tOgg_packet): ogg_int32_t;
function ogg_stream_pageout(const os: tOgg_stream_state; const og: tOgg_page): ogg_int32_t;
function ogg_stream_flush(const os: tOgg_stream_state; const og: tOgg_page): ogg_int32_t;
function ogg_sync_init(var oy: tOgg_sync_state): ogg_int32_t;
function ogg_sync_clear(const oy: tOgg_sync_state): ogg_int32_t;
function ogg_sync_reset(const oy: tOgg_sync_state): ogg_int32_t;
function ogg_sync_destroy(var oy: tOgg_sync_state): ogg_int32_t;
function ogg_sync_buffer(const oy: tOgg_sync_state; size: ogg_int32_t): pAnsiChar;
function ogg_sync_wrote(const oy: tOgg_sync_state; bytes: ogg_int32_t): ogg_int32_t;
function ogg_sync_pageseek(const oy: tOgg_sync_state; const og: tOgg_page): ogg_int32_t;
function ogg_sync_pageout(const oy: tOgg_sync_state; const og: tOgg_page): ogg_int32_t;
function ogg_stream_pagein(const os: tOgg_stream_state; const og: tOgg_page): ogg_int32_t;
function ogg_stream_packetout(const os: tOgg_stream_state; const op: tOgg_packet): ogg_int32_t;
function ogg_stream_packetpeek(const os: tOgg_stream_state; const op: tOgg_packet): ogg_int32_t;
function ogg_stream_init(var os: tOgg_stream_state; serialno: ogg_int32_t): ogg_int32_t;
function ogg_stream_clear(const os: tOgg_stream_state): ogg_int32_t;
function ogg_stream_reset(const os: tOgg_stream_state): ogg_int32_t;
function ogg_stream_reset_serialno(const os: tOgg_stream_state; serialno: ogg_int32_t): ogg_int32_t;
function ogg_stream_destroy(const os: tOgg_stream_state): ogg_int32_t;
function ogg_stream_eos(const os: tOgg_stream_state): ogg_int32_t;
procedure ogg_page_checksum_set(const og: tOgg_page);
function ogg_page_version(const og: tOgg_page): ogg_int32_t;
function ogg_page_continued(const og: tOgg_page): ogg_int32_t;
function ogg_page_bos(const og: tOgg_page): ogg_int32_t;
function ogg_page_eos(const og: tOgg_page): ogg_int32_t;
function ogg_page_granulepos(const og: tOgg_page): ogg_int64_t;
function ogg_page_serialno(const og: tOgg_page): ogg_int32_t;
function ogg_page_pageno(const og: tOgg_page): ogg_int32_t;
function ogg_page_packets(const og: tOgg_page): ogg_int32_t;
procedure ogg_packet_clear(const op: tOgg_packet);

{$ENDIF VC_LIBVORBIS_ONLY }


(********************************************************************
 *                                                                  *
 * THIS FILE IS PART OF THE OggVorbis SOFTWARE CODEC SOURCE CODE.   *
 * USE, DISTRIBUTION AND REPRODUCTION OF THIS LIBRARY SOURCE IS     *
 * GOVERNED BY A BSD-STYLE SOURCE LICENSE INCLUDED WITH THIS SOURCE *
 * IN 'COPYING'. PLEASE READ THESE TERMS BEFORE DISTRIBUTING.       *
 *                                                                  *
 * THE OggVorbis SOURCE CODE IS (C) COPYRIGHT 1994-2001             *
 * by the XIPHOPHORUS Company http://www.xiph.org/                  *

 ********************************************************************

 function: libvorbis codec headers
 last mod: $Id: codec.h,v 1.40 2002/02/28 04:12:47 xiphmont Exp $

 ********************************************************************)

type
  // --  --
  pVorbis_info = ^tVorbis_info;
  tVorbis_info = packed record
    //
    version: ogg_int32_t;
    channels: ogg_int32_t;
    rate: ogg_int32_t;
    //
    //* The below bitrate declarations are *hints*.
    //   Combinations of the three values carry the following implications:

    //   all three set to the same value:
    //	   implies a fixed rate bitstream
    //   only nominal set:
    //	   implies a VBR stream that averages the nominal bitrate.  No hard upper/lower limit
    //   upper and or lower set:
    //	   implies a VBR bitstream that obeys the bitrate limits. nominal may also be set to give a nominal rate.
    //   none set:
    //	   the coder does not care to speculate.
    //*/
    bitrate_upper: ogg_int32_t;
    bitrate_nominal: ogg_int32_t;
    bitrate_lower: ogg_int32_t;
    bitrate_window: ogg_int32_t;
    //
    codec_setup: pointer;
    {+20}
  end;


type
  // --  --
  pSingleSamples = ^tSingleSamples;
  tSingleSamples = array[byte] of pSingleArray;		// array of channels with samples

//  pSingleSamplesArray = ^tSingleSamplesArray;
//  tSingleSamplesArray = array[0..maxInt div sizeOf(pointer) - 1] of pSingleSamples;	// array of several PCM streams (?)


//* vorbis_dsp_state buffers the current vorbis audio
//   analysis/synthesis state.  The DSP state belongs to a specific
//   logical bitstream ****************************************************/

  pVorbis_dsp_state = ^tVorbis_dsp_state;
  tVorbis_dsp_state = packed record
    {+00}analysisp: ogg_int32_t;
    {+04}vi: pVorbis_info;
    //
    {+08}pcm: pSingleSamples;	// float **
    {+0C}pcmret: pSingleSamples;	// float **
    //
    {+10}pcm_storage: ogg_int32_t;
    {+14}pcm_current: ogg_int32_t;
    {+18}pcm_returned: ogg_int32_t;

    {+1C}preextrapolate: ogg_int32_t;
    {+20}eofflag: ogg_int32_t;

    {+24}lW: ogg_int32_t;
    {+28}W: ogg_int32_t;
    {+2C}nW: ogg_int32_t;
    {+30}centerW: ogg_int32_t;
    {+34}__align: ogg_int32_t;	// for some reason next field must be aligned to $10 boundary (?)

    {+38}granulepos: ogg_int64_t;
    {+40}sequence: ogg_int64_t;

    {+48}glue_bits: ogg_int64_t;
    {+50}time_bits: ogg_int64_t;
    {+58}floor_bits: ogg_int64_t;
    {+60}res_bits: ogg_int64_t;

    {+68}backend_state: pointer;
    {+6C}_align2: ogg_int32_t;
    {+70}
  end;

//* vorbis_block is a single block of data to be processed as part of
//the analysis/synthesis stream; it belongs to a specific logical
//bitstream, but is independant from other vorbis_blocks belonging to
//that logical bitstream. *************************************************/

  pAlloc_chain = ^tAlloc_chain;
  tAlloc_chain = packed record
    //
    ptr: pointer;
    next: pAlloc_chain;
  end;


  // --  --
  pVorbis_block = ^tVorbis_block;
  tVorbis_block = packed record
    //* necessary stream state for linking to the framing abstraction */
    {+00}pcm: pointer;	//float  **       /* this is a pointer into local storage */
    {+04}opb: tOggpack_buffer;
    //
    {+18}lW: ogg_int32_t;
    {+1C}W: ogg_int32_t;
    {+20}nW: ogg_int32_t;
    {+24}pcmend: ogg_int32_t;
    {+28}mode: ogg_int32_t;
    //
    {+2A}eofflag: ogg_int32_t;
    {+30}granulepos: ogg_int64_t;
    {+38}sequence: ogg_int64_t;
    {+40}vd: pVorbis_dsp_state; //* For read-only access of configuration */

    //* local storage to avoid remallocing; it's up to the mapping to
    //   structure it */
    {+44}localstore: pointer;
    {+48}localtop: ogg_int32_t;
    {+4C}localalloc: ogg_int32_t;
    {+50}totaluse: ogg_int32_t;
    {+54}reap: pAlloc_chain;

    //* bitmetrics for the frame */
    {+58}glue_bits: ogg_int32_t;
    {+5C}time_bits: ogg_int32_t;
    {+60}floor_bits: ogg_int32_t;
    {+64}res_bits: ogg_int32_t;

    {+68}internal: pointer;
    {+6C}_align: ogg_int32_t;
    {+70}
  end;

//* vorbis_info contains all the setup information specific to the
//   specific compression/decompression mode in progress (eg,
//   psychoacoustic settings, channel setup, options, codebook
//   etc). vorbis_info and substructures are in backends.h.
//*********************************************************************/

//* the comments are not part of vorbis_info so that vorbis_info can be
//   static storage */

  pVorbis_comment = ^tVorbis_comment;
  tVorbis_comment = packed record
    //* unlimited user comment fields.  libvorbis writes 'libvorbis'
    //   whatever vendor is set to in encode */
    user_comments: pointer;	// char **
    comment_lengths: ^ogg_int32_t;
    comments: ogg_int32_t;
    vendor: pAnsiChar;
    {+10}
  end;


(* libvorbis encodes in two abstraction layers; first we perform DSP
   and produce a packet (see docs/analysis.txt).  The packet is then
   coded into a framed OggSquish bitstream by the second layer (see
   docs/framing.txt).  Decode is the reverse process; we sync/frame
   the bitstream and extract individual packets, then decode the
   packet back into PCM audio.

   The extra framing/packetizing is used in streaming formats, such as
   files.  Over the net (such as with UDP), the framing and
   packetization aren't necessary as they're provided by the transport
   and the streaming layer is not used *)

//* Vorbis PRIMITIVES: general ***************************************/

//extern void     vorbis_info_init(vorbis_info *vi);
  tvorbis_info_init = procedure(var vi: tVorbis_info); cdecl;

//extern void     vorbis_info_clear(vorbis_info *vi);
  tvorbis_info_clear = procedure(const vi: tVorbis_info); cdecl;

//extern ogg_int32_t      vorbis_info_blocksize(vorbis_info *vi,ogg_int32_t zo);
  tvorbis_info_blocksize = function(const vi: tVorbis_info; zo: ogg_int32_t): ogg_int32_t; cdecl;

//extern void     vorbis_comment_init(vorbis_comment *vc);
  tvorbis_comment_init = procedure(const vc: tVorbis_comment); cdecl;

//extern void     vorbis_comment_add(vorbis_comment *vc, AnsiChar *comment);
  tvorbis_comment_add = procedure(const vc: tVorbis_comment; comment: pAnsiChar); cdecl;

//extern void     vorbis_comment_add_tag(vorbis_comment *vc, AnsiChar *tag, AnsiChar *contents);
  tvorbis_comment_add_tag = procedure(var vc: tVorbis_comment; tag: pAnsiChar; contents: pAnsiChar); cdecl;

//extern AnsiChar    *vorbis_comment_query(vorbis_comment *vc, AnsiChar *tag, ogg_int32_t count);
  tvorbis_comment_query = function(const vc: tVorbis_comment; tag: pAnsiChar; count: ogg_int32_t): pAnsiChar; cdecl;

//extern ogg_int32_t      vorbis_comment_query_count(vorbis_comment *vc, AnsiChar *tag);
  tvorbis_comment_query_count = function(const vc: tVorbis_comment; tag: pAnsiChar): ogg_int32_t; cdecl;

//extern void     vorbis_comment_clear(vorbis_comment *vc);
  tvorbis_comment_clear = procedure(const vc: tVorbis_comment); cdecl;


//extern ogg_int32_t      vorbis_block_init(vorbis_dsp_state *v, vorbis_block *vb);
  tvorbis_block_init = function(const v: tVorbis_dsp_state; var vb: tVorbis_block): ogg_int32_t; cdecl;

//extern ogg_int32_t      vorbis_block_clear(vorbis_block *vb);
  tvorbis_block_clear = function(const vb: tVorbis_block): ogg_int32_t; cdecl;

//extern void     vorbis_dsp_clear(vorbis_dsp_state *v);
  tvorbis_dsp_clear = procedure(const v: tVorbis_dsp_state); cdecl;

//* Vorbis PRIMITIVES: analysis/DSP layer ****************************/

//extern ogg_int32_t      vorbis_analysis_init(vorbis_dsp_state *v,vorbis_info *vi);
  tvorbis_analysis_init = function(var v: tVorbis_dsp_state; const vi: tVorbis_info): ogg_int32_t; cdecl;

//extern ogg_int32_t      vorbis_commentheader_out(vorbis_comment *vc, ogg_packet *op);
  tvorbis_commentheader_out = function(const vc: tVorbis_comment; const op: tOgg_packet): ogg_int32_t; cdecl;

//extern ogg_int32_t      vorbis_analysis_headerout(vorbis_dsp_state *v, vorbis_comment *vc, ogg_packet *op, ogg_packet *op_comm, ogg_packet *op_code);
  tvorbis_analysis_headerout = function(const v: tVorbis_dsp_state; const vc: tVorbis_comment; const op: tOgg_packet; const op_comm: tOgg_packet; const op_code: tOgg_packet): ogg_int32_t; cdecl;

//extern float  **vorbis_analysis_buffer(vorbis_dsp_state *v,ogg_int32_t vals);
  tvorbis_analysis_buffer = function(const v: tVorbis_dsp_state; vals: ogg_int32_t): pSingleSamples; cdecl;	// float **

//extern ogg_int32_t      vorbis_analysis_wrote(vorbis_dsp_state *v,ogg_int32_t vals);
  tvorbis_analysis_wrote = function(const v: tVorbis_dsp_state; vals: ogg_int32_t): ogg_int32_t; cdecl;

//extern ogg_int32_t      vorbis_analysis_blockout(vorbis_dsp_state *v,vorbis_block *vb);
  tvorbis_analysis_blockout = function(const v: tVorbis_dsp_state; const vb: tVorbis_block): ogg_int32_t; cdecl;

//extern ogg_int32_t      vorbis_analysis(vorbis_block *vb,ogg_packet *op);
  tvorbis_analysis = function(const vb: tVorbis_block; op: pOgg_packet): ogg_int32_t; cdecl;

//extern ogg_int32_t      vorbis_bitrate_addblock(vorbis_block *vb);
  tvorbis_bitrate_addblock = function(const vb: tVorbis_block): ogg_int32_t; cdecl;

//extern ogg_int32_t      vorbis_bitrate_flushpacket = function(vorbis_dsp_state *vd, ogg_packet *op);
  tvorbis_bitrate_flushpacket = function(const vd: tVorbis_dsp_state; const op: tOgg_packet): ogg_int32_t; cdecl;

//* Vorbis PRIMITIVES: synthesis layer *******************************/
//extern ogg_int32_t      vorbis_synthesis_headerin(vorbis_info *vi,vorbis_comment *vc, ogg_packet *op);
  tvorbis_synthesis_headerin = function(const vi: tVorbis_info; const vc: tVorbis_comment; const op: tOgg_packet): ogg_int32_t; cdecl;

//extern ogg_int32_t      vorbis_synthesis_init(vorbis_dsp_state *v,vorbis_info *vi);
  tvorbis_synthesis_init = function(const v: tVorbis_dsp_state; const vi: tVorbis_info): ogg_int32_t; cdecl;

//extern ogg_int32_t      vorbis_synthesis(vorbis_block *vb,ogg_packet *op);
  tvorbis_synthesis = function(const vb: tVorbis_block; const op: tOgg_packet): ogg_int32_t; cdecl;

//extern ogg_int32_t      vorbis_synthesis_trackonly(vorbis_block *vb,ogg_packet *op);
  tvorbis_synthesis_trackonly = function(const vb: tVorbis_block; const op: tOgg_packet): ogg_int32_t; cdecl;

//extern ogg_int32_t      vorbis_synthesis_blockin(vorbis_dsp_state *v,vorbis_block *vb);
  tvorbis_synthesis_blockin = function(const v: tVorbis_dsp_state; const vb: tVorbis_block): ogg_int32_t; cdecl;

//extern ogg_int32_t      vorbis_synthesis_pcmout(vorbis_dsp_state *v,float ***pcm);
  tvorbis_synthesis_pcmout = function(const v: tVorbis_dsp_state; var pcm: pSingleSamples {float **}): ogg_int32_t; cdecl;

//extern ogg_int32_t      vorbis_synthesis_read(vorbis_dsp_state *v,ogg_int32_t samples);
  tvorbis_synthesis_read = function(const v: tVorbis_dsp_state; const samples: ogg_int32_t): ogg_int32_t; cdecl;

//extern ogg_int32_t     vorbis_packet_blocksize(vorbis_info *vi,ogg_packet *op);
  tvorbis_packet_blocksize = function(const vi: tVorbis_info; const op: tOgg_packet): ogg_int32_t; cdecl;

//* Vorbis ERRORS and return codes ***********************************/

const
  OV_FALSE      = -1;
  OV_EOF        = -2;
  OV_HOLE       = -3;

  OV_EREAD      = -128;
  OV_EFAULT     = -129;
  OV_EIMPL      = -130;
  OV_EINVAL     = -131;
  OV_ENOTVORBIS = -132;
  OV_EBADHEADER = -133;
  OV_EVERSION   = -134;
  OV_ENOTAUDIO  = -135;
  OV_EBADPACKET = -136;
  OV_EBADLINK   = -137;
  OV_ENOSEEK    = -138;


{$IFNDEF VC_LIBVORBIS_ONLY }

//------------------------------------------

procedure vorbis_info_init(var vi: tVorbis_info);
procedure vorbis_info_clear(const vi: tVorbis_info);
function vorbis_info_blocksize(const vi: tVorbis_info; zo: ogg_int32_t): ogg_int32_t;
procedure vorbis_comment_init(const vc: tVorbis_comment);
procedure vorbis_comment_add(const vc: tVorbis_comment; comment: pAnsiChar);
procedure vorbis_comment_add_tag(var vc: tVorbis_comment; tag: pAnsiChar; contents: pAnsiChar);
function vorbis_comment_query(const vc: tVorbis_comment; tag: pAnsiChar; count: ogg_int32_t): pAnsiChar;
function vorbis_comment_query_count(const vc: tVorbis_comment; tag: pAnsiChar): ogg_int32_t;
procedure vorbis_comment_clear(const vc: tVorbis_comment);
function vorbis_block_init(const v: tVorbis_dsp_state; var vb: tVorbis_block): ogg_int32_t;
function vorbis_block_clear(const vb: tVorbis_block): ogg_int32_t;
procedure vorbis_dsp_clear(const v: tVorbis_dsp_state);
function vorbis_analysis_init(var v: tVorbis_dsp_state; const vi: tVorbis_info): ogg_int32_t;
function vorbis_commentheader_out(const vc: tVorbis_comment; const op: tOgg_packet): ogg_int32_t;
function vorbis_analysis_headerout(const v: tVorbis_dsp_state; const vc: tVorbis_comment; const op: tOgg_packet; const op_comm: tOgg_packet; const op_code: tOgg_packet): ogg_int32_t;
function vorbis_analysis_buffer(const v: tVorbis_dsp_state; vals: ogg_int32_t): pSingleSamples; // float **
function vorbis_analysis_wrote(const v: tVorbis_dsp_state; vals: ogg_int32_t): ogg_int32_t;
function vorbis_analysis_blockout(const v: tVorbis_dsp_state; const vb: tVorbis_block): ogg_int32_t;
function vorbis_analysis(const vb: tVorbis_block; op: pOgg_packet): ogg_int32_t;
function vorbis_bitrate_addblock(const vb: tVorbis_block): ogg_int32_t;
function vorbis_bitrate_flushpacket(const vd: tVorbis_dsp_state; const op: tOgg_packet): ogg_int32_t;
function vorbis_synthesis_headerin(const vi: tVorbis_info; const vc: tVorbis_comment; const op: tOgg_packet): ogg_int32_t;
function vorbis_synthesis_init(const v: tVorbis_dsp_state; const vi: tVorbis_info): ogg_int32_t;
function vorbis_synthesis(const vb: tVorbis_block; const op: tOgg_packet): ogg_int32_t;
function vorbis_synthesis_trackonly(const vb: tVorbis_block; const op: tOgg_packet): ogg_int32_t;
function vorbis_synthesis_blockin(const v: tVorbis_dsp_state; const vb: tVorbis_block): ogg_int32_t;
function vorbis_synthesis_pcmout(const v: tVorbis_dsp_state; var pcm: pSingleSamples {float **}): ogg_int32_t;
function vorbis_synthesis_read(const v: tVorbis_dsp_state; const samples: ogg_int32_t): ogg_int32_t;
function vorbis_packet_blocksize(const vi: tVorbis_info; const op: tOgg_packet): ogg_int32_t;


(********************************************************************
 *                                                                  *
 * THIS FILE IS PART OF THE OggVorbis SOFTWARE CODEC SOURCE CODE.   *
 * USE, DISTRIBUTION AND REPRODUCTION OF THIS LIBRARY SOURCE IS     *
 * GOVERNED BY A BSD-STYLE SOURCE LICENSE INCLUDED WITH THIS SOURCE *
 * IN 'COPYING'. PLEASE READ THESE TERMS BEFORE DISTRIBUTING.       *
 *                                                                  *
 * THE OggVorbis SOURCE CODE IS (C) COPYRIGHT 1994-2001             *
 * by the XIPHOPHORUS Company http://www.xiph.org/                  *
 *                                                                  *
 ********************************************************************

 function: vorbis encode-engine setup
 last mod: $Id: vorbisenc.h,v 1.10 2002/07/01 11:20:10 xiphmont Exp $

 ********************************************************************)

type

//extern ogg_int32_t vorbis_encode_init(vorbis_info *vi, ogg_int32_t channels, ogg_int32_t rate, ogg_int32_t max_bitrate, ogg_int32_t nominal_bitrate, ogg_int32_t min_bitrate);
  tvorbis_encode_init = function(const vi: tVorbis_info; channels, rate, max_bitrate, nominal_bitrate, min_bitrate: ogg_int32_t): ogg_int32_t; cdecl;

//extern ogg_int32_t vorbis_encode_setup_managed(vorbis_info *vi, ogg_int32_t channels, ogg_int32_t rate, ogg_int32_t max_bitrate, ogg_int32_t nominal_bitrate, ogg_int32_t min_bitrate);
  tvorbis_encode_setup_managed = function(const vi: tVorbis_info; channels, rate, max_bitrate, nominal_bitrate, min_bitrate: ogg_int32_t): ogg_int32_t; cdecl;

//extern ogg_int32_t vorbis_encode_setup_vbr(vorbis_info *vi, ogg_int32_t channels, ogg_int32_t rate, float /* quality level from 0. (lo) to 1. (hi) */ );
  tvorbis_encode_setup_vbr = function(const vi: tVorbis_info; channels, rate: ogg_int32_t; quality: single { quality level from 0. (lo) to 1. (hi) }): ogg_int32_t; cdecl;

//extern ogg_int32_t vorbis_encode_init_vbr(vorbis_info *vi, ogg_int32_t channels, ogg_int32_t rate, float base_quality /* quality level from 0. (lo) to 1. (hi) */ );
  tvorbis_encode_init_vbr = function(var vi: tVorbis_info; channels, rate: ogg_int32_t; base_quality: single { quality level from 0. (lo) to 1. (hi) }): ogg_int32_t; cdecl;

//extern ogg_int32_t vorbis_encode_setup_init(vorbis_info *vi);
  tvorbis_encode_setup_init = function(const vi: tVorbis_info): ogg_int32_t; cdecl;

//extern ogg_int32_t vorbis_encode_ctl(vorbis_info *vi,ogg_int32_t number,void *arg);
  tvorbis_encode_ctl = function(const vi: tVorbis_info; number: ogg_int32_t; arg: pointer): ogg_int32_t; cdecl;

const
  // --  --
  OV_ECTL_RATEMANAGE_GET	= $10;
  OV_ECTL_RATEMANAGE_SET	= $11;
  OV_ECTL_RATEMANAGE_AVG	= $12;
  OV_ECTL_RATEMANAGE_HARD	= $13;

  OV_ECTL_LOWPASS_GET		= $20;
  OV_ECTL_LOWPASS_SET		= $21;

  OV_ECTL_IBLOCK_GET		= $30;
  OV_ECTL_IBLOCK_SET		= $31;


type
  // --  --
  pOvectl_ratemanage_arg = ^tOvectl_ratemanage_arg;
  tOvectl_ratemanage_arg = packed record
    management_active: ogg_int32_t;
    //
    bitrate_hard_min: ogg_int32_t;
    bitrate_hard_max: ogg_int32_t;
    bitrate_hard_window: double;
    //
    bitrate_av_lo: ogg_int32_t;
    bitrate_av_hi: ogg_int32_t;
    bitrate_av_window: double;
    bitrate_av_window_center: double;
  end;


// ---------------------------------------------

function vorbis_encode_init(const vi: tVorbis_info; channels, rate, max_bitrate, nominal_bitrate, min_bitrate: ogg_int32_t): ogg_int32_t;
function vorbis_encode_setup_managed(const vi: tVorbis_info; channels, rate, max_bitrate, nominal_bitrate, min_bitrate: ogg_int32_t): ogg_int32_t;
function vorbis_encode_setup_vbr(const vi: tVorbis_info; channels, rate: ogg_int32_t; quality: single { quality level from 0. (lo) to 1. (hi) }): ogg_int32_t;
function vorbis_encode_init_vbr(var vi: tVorbis_info; channels, rate: ogg_int32_t; base_quality: single { quality level from 0. (lo) to 1. (hi) }): ogg_int32_t;
function vorbis_encode_setup_init(const vi: tVorbis_info): ogg_int32_t;
function vorbis_encode_ctl(const vi: tVorbis_info; number: ogg_int32_t; arg: pointer): ogg_int32_t;

(********************************************************************
 *                                                                  *
 * THIS FILE IS PART OF THE OggVorbis SOFTWARE CODEC SOURCE CODE.   *
 * USE, DISTRIBUTION AND REPRODUCTION OF THIS LIBRARY SOURCE IS     *
 * GOVERNED BY A BSD-STYLE SOURCE LICENSE INCLUDED WITH THIS SOURCE *
 * IN 'COPYING'. PLEASE READ THESE TERMS BEFORE DISTRIBUTING.       *
 *                                                                  *
 * THE OggVorbis SOURCE CODE IS (C) COPYRIGHT 1994-2001             *
 * by the XIPHOPHORUS Company http://www.xiph.org/                  *
 *                                                                  *
 ********************************************************************

 function: stdio-based convenience library for opening/seeking/decoding
 last mod: $Id: vorbisfile.h,v 1.17 2002/03/07 03:41:03 xiphmont Exp $

 ********************************************************************)

type

(* The function prototypes for the callbacks are basically the same as for
 * the stdio functions fread, fseek, fclose, ftell.
 * The one difference is that the FILE * arguments have been replaced with
 * a void * - this is to be used as a pointer to whatever internal data these
 * functions might need. In the stdio case, it's just a FILE * cast to a void *
 *
 * If you use other functions, check the docs for these functions and return
 * the right values. For seek_func(), you *MUST* return -1 if the stream is
 * unseekable
 *)


//  size_t (*read_func)  (void *ptr, size_t size, size_t nmemb, void *datasource);
  tvorbiscb_read_func = function(ptr: pointer; size: ogg_int32_t; nmemb: ogg_int32_t; datasource: pointer): ogg_int32_t; cdecl;

//  ogg_int32_t    (*seek_func)  (void *datasource, ogg_int64_t offset, ogg_int32_t whence);
  tvorbiscb_seek_func = function(datasource: pointer; offset: ogg_int64_t; whence: ogg_int32_t): ogg_int32_t; cdecl;

//  ogg_int32_t    (*close_func) (void *datasource);
  tvorbiscb_close_func = function(datasource: pointer): ogg_int32_t; cdecl;

//  ogg_int32_t   (*tell_func)  (void *datasource);
  tvorbiscb_tell_func = function(datasource: pointer): ogg_int32_t; cdecl;


  // --  --
  pOv_callbacks = ^tOv_callbacks;
  tOv_callbacks = packed record
    read_func: tvorbiscb_read_func;
    seek_func: tvorbiscb_seek_func;
    close_func: tvorbiscb_close_func;
    tell_func: tvorbiscb_tell_func;
  end;

const
  NOTOPEN   = 0;
  PARTOPEN  = 1;
  OPENED    = 2;
  STREAMSET = 3;
  INITSET   = 4;


type
  // --  --
  pOggVorbis_File = ^tOggVorbis_File;
  tOggVorbis_File = packed record
    datasource: pointer; //* Pointer to a FILE *, etc. */
    seekable: ogg_int32_t;
    offset: ogg_int64_t;
    _end: ogg_int64_t;
    oy: tOgg_sync_state;

    //* If the FILE handle isn't seekable (eg, a pipe), only the current
    //   stream appears */
    links: ogg_int32_t;
    offsets: ^ogg_int64_t;
    dataoffsets: ogg_int64_t;
    serialnos: ^ogg_int32_t;
    pcmlengths: ^ogg_int64_t; //* overloaded to maintain binary
			      //	    compatability; x2 size, stores both
			      //	    beginning and end values */
    vi: pVorbis_info;
    vc: pVorbis_comment;

    //* Decoding working state local storage */
    pcm_offset: ogg_int64_t;
    ready_state: ogg_int32_t;
    current_serialno: ogg_int32_t;
    current_link: ogg_int32_t;
    //
    bittrack: double;
    samptrack: double;

    os: tOgg_stream_state; //* take physical pages, weld into a logical stream of packets */
    vd: tVorbis_dsp_state; //* central working state for the packet->PCM decoder */
    vb: tVorbis_block; //* local working space for packet->PCM decode */

    callbacks: tOv_callbacks;
  end;

  _FILE = ogg_int32_t;

//extern ogg_int32_t ov_clear(OggVorbis_File *vf);
  tov_clear = function(const vf: tOggVorbis_File): ogg_int32_t; cdecl;

//extern ogg_int32_t ov_open(FILE *f,OggVorbis_File *vf,AnsiChar *initial,ogg_int32_t ibytes);
  tov_open = function(const f: _FILE; const vf: tOggVorbis_File; initial: pAnsiChar; ibytes: ogg_int32_t): ogg_int32_t; cdecl;

//extern ogg_int32_t ov_open_callbacks(void *datasource, OggVorbis_File *vf, AnsiChar *initial, ogg_int32_t ibytes, ov_callbacks callbacks);
  tov_open_callbacks = function(datasource: pointer; const vf: tOggVorbis_File; initial: pAnsiChar; ibytes: ogg_int32_t; callbacks: tOv_callbacks): ogg_int32_t; cdecl;

// --  --

//extern ogg_int32_t ov_test(FILE *f,OggVorbis_File *vf,AnsiChar *initial,ogg_int32_t ibytes);
  tov_test = function(const f: _FILE; const vf: tOggVorbis_File; initial: pAnsiChar; ibytes: ogg_int32_t): ogg_int32_t; cdecl;

//extern ogg_int32_t ov_test_callbacks(void *datasource, OggVorbis_File *vf, AnsiChar *initial, ogg_int32_t ibytes, ov_callbacks callbacks);
  tov_test_callbacks = function(datasource: pointer; const vf: tOggVorbis_File; initial: pAnsiChar; ibytes: ogg_int32_t; callbacks: tOv_callbacks): ogg_int32_t; cdecl;

//extern ogg_int32_t ov_test_open(OggVorbis_File *vf);
  tov_test_open = function(const vf: tOggVorbis_File): ogg_int32_t; cdecl;

// --  --

//extern ogg_int32_t ov_bitrate(OggVorbis_File *vf,ogg_int32_t i);
  tov_bitrate = function(const vf: tOggVorbis_File; i: ogg_int32_t): ogg_int32_t; cdecl;

//extern ogg_int32_t ov_bitrate_instant(OggVorbis_File *vf);
  tov_bitrate_instant = function(const vf: tOggVorbis_File): ogg_int32_t; cdecl;

//extern ogg_int32_t ov_streams(OggVorbis_File *vf);
  tov_streams = function(const vf: tOggVorbis_File): ogg_int32_t; cdecl;

//extern ogg_int32_t ov_seekable(OggVorbis_File *vf);
  tov_seekable = function(const vf: tOggVorbis_File): ogg_int32_t; cdecl;

//extern ogg_int32_t ov_serialnumber(OggVorbis_File *vf,ogg_int32_t i);
  tov_serialnumber = function(const vf: tOggVorbis_File; i: ogg_int32_t): ogg_int32_t; cdecl;

// --  --

//extern ogg_int64_t ov_raw_total(OggVorbis_File *vf,ogg_int32_t i);
  tov_raw_total = function(const vf: tOggVorbis_File; i: ogg_int32_t): ogg_int64_t; cdecl;

//extern ogg_int64_t ov_pcm_total(OggVorbis_File *vf,ogg_int32_t i);
  tov_pcm_total = function(const vf: tOggVorbis_File; i: ogg_int32_t): ogg_int64_t; cdecl;

//extern double ov_time_total(OggVorbis_File *vf,ogg_int32_t i);
  tov_time_total = function(const vf: tOggVorbis_File; i: ogg_int32_t): double; cdecl;

// --  --

//extern ogg_int32_t ov_raw_seek(OggVorbis_File *vf,ogg_int64_t pos);
  tov_raw_seek = function(const vf: tOggVorbis_File; pos: ogg_int64_t): ogg_int32_t; cdecl;

//extern ogg_int32_t ov_pcm_seek(OggVorbis_File *vf,ogg_int64_t pos);
  tov_pcm_seek = function(const vf: tOggVorbis_File; pos: ogg_int64_t): ogg_int32_t; cdecl;

//extern ogg_int32_t ov_pcm_seek_page(OggVorbis_File *vf,ogg_int64_t pos);
  tov_pcm_seek_page = function(const vf: tOggVorbis_File; pos: ogg_int64_t): ogg_int32_t; cdecl;

//extern ogg_int32_t ov_time_seek(OggVorbis_File *vf,double pos);
  tov_time_seek = function(const vf: tOggVorbis_File; pos: double): ogg_int32_t; cdecl;

//extern ogg_int32_t ov_time_seek_page(OggVorbis_File *vf,double pos);
  tov_time_seek_page = function(const vf: tOggVorbis_File; pos: double): ogg_int32_t; cdecl;

// --  --

//extern ogg_int64_t ov_raw_tell(OggVorbis_File *vf);
  tov_raw_tell = function(const vf: tOggVorbis_File): ogg_int64_t; cdecl;

//extern ogg_int64_t ov_pcm_tell(OggVorbis_File *vf);
  tov_pcm_tell = function(const vf: tOggVorbis_File): ogg_int64_t; cdecl;

//extern double ov_time_tell(OggVorbis_File *vf);
  tov_time_tell = function(const vf: tOggVorbis_File): double; cdecl;

// --  --

//extern vorbis_info *ov_info(OggVorbis_File *vf,ogg_int32_t link);
  tov_info = function(const vf: tOggVorbis_File; link: ogg_int32_t): pVorbis_info; cdecl;

//extern vorbis_comment *ov_comment(OggVorbis_File *vf,ogg_int32_t link);
  tov_comment = function(const vf: tOggVorbis_File; link: ogg_int32_t): pVorbis_comment; cdecl;

// --  --

//extern ogg_int32_t ov_read_float(OggVorbis_File *vf,float ***pcm_channels,ogg_int32_t samples, ogg_int32_t *bitstream);
  tov_read_float = function(const vf: tOggVorbis_File; var pcm_channels: pSingleSamples{float **}; samples: ogg_int32_t; var bitstream: ogg_int32_t): ogg_int32_t; cdecl;

//extern ogg_int32_t ov_read(OggVorbis_File *vf,AnsiChar *buffer,ogg_int32_t length, ogg_int32_t bigendianp,ogg_int32_t word,ogg_int32_t sgned,ogg_int32_t *bitstream);
  tov_read = function(const vf: tOggVorbis_File; buffer: pAnsiChar; length, bigendianp, _word, sgned: ogg_int32_t; var bitstream: ogg_int32_t): ogg_int32_t; cdecl;


// ---------------------------------------------------

function ov_clear(const vf: tOggVorbis_File): ogg_int32_t;
function ov_open(const f: _FILE; const vf: tOggVorbis_File; initial: pAnsiChar; ibytes: ogg_int32_t): ogg_int32_t;
function ov_open_callbacks(datasource: pointer; const vf: tOggVorbis_File; initial: pAnsiChar; ibytes: ogg_int32_t; callbacks: tOv_callbacks): ogg_int32_t;
function ov_test(const f: _FILE; const vf: tOggVorbis_File; initial: pAnsiChar; ibytes: ogg_int32_t): ogg_int32_t;
function ov_test_callbacks(datasource: pointer; const vf: tOggVorbis_File; initial: pAnsiChar; ibytes: ogg_int32_t; callbacks: tOv_callbacks): ogg_int32_t;
function ov_test_open(const vf: tOggVorbis_File): ogg_int32_t;
function ov_bitrate(const vf: tOggVorbis_File; i: ogg_int32_t): ogg_int32_t;
function ov_bitrate_instant(const vf: tOggVorbis_File): ogg_int32_t;
function ov_streams(const vf: tOggVorbis_File): ogg_int32_t;
function ov_seekable(const vf: tOggVorbis_File): ogg_int32_t;
function ov_serialnumber(const vf: tOggVorbis_File; i: ogg_int32_t): ogg_int32_t;
function ov_raw_total(const vf: tOggVorbis_File; i: ogg_int32_t): ogg_int64_t;
function ov_pcm_total(const vf: tOggVorbis_File; i: ogg_int32_t): ogg_int64_t;
function ov_time_total(const vf: tOggVorbis_File; i: ogg_int32_t): double;
function ov_raw_seek(const vf: tOggVorbis_File; pos: ogg_int64_t): ogg_int32_t;
function ov_pcm_seek(const vf: tOggVorbis_File; pos: ogg_int64_t): ogg_int32_t;
function ov_pcm_seek_page(const vf: tOggVorbis_File; pos: ogg_int64_t): ogg_int32_t;
function ov_time_seek(const vf: tOggVorbis_File; pos: double): ogg_int32_t;
function ov_time_seek_page(const vf: tOggVorbis_File; pos: double): ogg_int32_t;
function ov_raw_tell(const vf: tOggVorbis_File): ogg_int64_t;
function ov_pcm_tell(const vf: tOggVorbis_File): ogg_int64_t;
function ov_time_tell(const vf: tOggVorbis_File): double;
function ov_info(const vf: tOggVorbis_File; link: ogg_int32_t): pVorbis_info;
function ov_comment(const vf: tOggVorbis_File; link: ogg_int32_t): pVorbis_comment;
function ov_read_float(const vf: tOggVorbis_File; var pcm_channels: pSingleSamples{float **}; samples: ogg_int32_t; var bitstream: ogg_int32_t): ogg_int32_t;
function ov_read(const vf: tOggVorbis_File; buffer: pAnsiChar; length, bigendianp, _word, sgned: ogg_int32_t; var bitstream: ogg_int32_t): ogg_int32_t;

// ---------------------------------------

const
  c_dllName_ogg		= 'ogg.dll';
  c_dllName_vorbis	= 'vorbis.dll';
  c_dllName_vorbisenc	= 'vorbisenc.dll';
  c_dllName_vorbisfile	= 'vorbisfile.dll';

//
  OV_ERR_NO_DLL_LOADED  = -4001;
  OV_ERR_NOT_SUPPORED	= -4002;

  cunav_dll_ogg		= 1;
  cunav_dll_vorbis    	= 2;
  cunav_dll_vorbisenc 	= 3;
  cunav_dll_vorbisfile	= 4;

{*
  Loads one of Vorbis libraries.

  @paran libraryToLoad see cunav_dll_XXX
}
function vorbis_load_library(libraryToLoad: int; const libraryName: wideString = ''): boolean;
{*
  Unloads one of Vorbis libraries.

  @paran libraryToUnload see cunav_dll_XXX
}
procedure vorbis_unload_library(libraryToUnload: int);

{$ENDIF VC_LIBVORBIS_ONLY }


// -- libvorbis.dll --

type
  // new since 2002:
  tvorbis_granule_time = function(v: pVorbis_dsp_state; granulepos: ogg_int64_t): double; cdecl;
  tvorbis_version_string = function(): paChar; cdecl;
  //
  tvorbis_synthesis_halfrate = function(v: pvorbis_info; flag: int32): ogg_int32_t; cdecl;
  tvorbis_synthesis_halfrate_p = function(v: pvorbis_info): ogg_int32_t; cdecl;
  tvorbis_synthesis_idheader = function(op: pogg_packet): ogg_int32_t; cdecl;
  tvorbis_synthesis_lapout = function(v: pvorbis_dsp_state; var pcm: pSingleSamples): ogg_int32_t; cdecl;
  tvorbis_synthesis_restart = function(v: pvorbis_dsp_state): ogg_int32_t; cdecl;


  //
  pLibvorbisAPI = ^tLibvorbisAPI;
  tLibvorbisAPI = packed record
    //
    r_refCount: int;
    r_module: hModule;
    //
    // Functions used by both decode and encode
    r_vorbis_block_clear	: tvorbis_block_clear;
    r_vorbis_block_init		: tvorbis_block_init;
    r_vorbis_dsp_clear		: tvorbis_dsp_clear;
    r_vorbis_granule_time	: tvorbis_granule_time;
    r_vorbis_info_blocksize	: tvorbis_info_blocksize;
    r_vorbis_info_clear		: tvorbis_info_clear;
    r_vorbis_info_init		: tvorbis_info_init;
//    r_vorbis_version_string	: tvorbis_version_string;	// not exported by libvorbis.dll as of 1.3.2
    // Decoding
    r_vorbis_packet_blocksize	: tvorbis_packet_blocksize;
    r_vorbis_synthesis            : tvorbis_synthesis;
    r_vorbis_synthesis_blockin    : tvorbis_synthesis_blockin;
    r_vorbis_synthesis_halfrate   : tvorbis_synthesis_halfrate;
    r_vorbis_synthesis_halfrate_p : tvorbis_synthesis_halfrate_p;
    r_vorbis_synthesis_headerin   : tvorbis_synthesis_headerin;
//    r_vorbis_synthesis_idheader   : tvorbis_synthesis_idheader; // not exported by libvorbis.dll as of 1.3.2
    r_vorbis_synthesis_init       : tvorbis_synthesis_init;
    r_vorbis_synthesis_lapout     : tvorbis_synthesis_lapout;
    r_vorbis_synthesis_pcmout     : tvorbis_synthesis_pcmout;
    r_vorbis_synthesis_read       : tvorbis_synthesis_read;
    r_vorbis_synthesis_restart    : tvorbis_synthesis_restart;
    r_vorbis_synthesis_trackonly  : tvorbis_synthesis_trackonly;
    // Encoding
    r_vorbis_analysis             : tvorbis_analysis;
    r_vorbis_analysis_blockout    : tvorbis_analysis_blockout;
    r_vorbis_analysis_buffer      : tvorbis_analysis_buffer;
    r_vorbis_analysis_headerout   : tvorbis_analysis_headerout;
    r_vorbis_analysis_init        : tvorbis_analysis_init;
    r_vorbis_analysis_wrote       : tvorbis_analysis_wrote;
    r_vorbis_bitrate_addblock     : tvorbis_bitrate_addblock;
    r_vorbis_bitrate_flushpacket  : tvorbis_bitrate_flushpacket;
    // Metadata
    r_vorbis_comment_add          : tvorbis_comment_add;
    r_vorbis_comment_add_tag      : tvorbis_comment_add_tag;
    r_vorbis_comment_clear        : tvorbis_comment_clear;
    r_vorbis_comment_init         : tvorbis_comment_init;
    r_vorbis_comment_query        : tvorbis_comment_query;
    r_vorbis_comment_query_count  : tvorbis_comment_query_count;
    r_vorbis_commentheader_out    : tvorbis_commentheader_out;
  end;


  {*
  }
  unaLibvorbisCoder = class(unaObject)
  private
    f_api: tLibvorbisAPI;
    f_lastError: int;
    f_active: bool;
    f_libOK: bool;
  protected
    function doOpen(): int; virtual; abstract;
    procedure doClose(); virtual; abstract;
  public
    constructor create(const libname: wString = '');
    procedure BeforeDestruction(); override;
    //
    {*
    }
    function open(): int;
    {*
    }
    procedure close();
    //
    {*
    }
    property lastError: int read f_lastError;
    {*
    }
    property active: bool read f_active;
    {*
    }
    property libOK: bool read f_libOK;
  end;


const
  //
  c_libvorbis_name = 'libvorbis.dll';

{*
}
function loadLibvorbis(var api: tLibvorbisAPI; const libname: wString = ''): int;

{*
}
procedure unloadLibvorbis(var api: tLibvorbisAPI);


implementation


uses
  unaUtils;

{$IFNDEF VC_LIBVORBIS_ONLY }

var
  proc_ogg_packet_clear               : togg_packet_clear;
  proc_ogg_page_bos                   : togg_page_bos;
  proc_ogg_page_continued             : togg_page_continued;
  proc_ogg_page_eos                   : togg_page_eos;
  proc_ogg_page_granulepos            : togg_page_granulepos;
  proc_ogg_page_packets               : togg_page_packets;
  proc_ogg_page_pageno                : togg_page_pageno;
  proc_ogg_page_serialno              : togg_page_serialno;
  proc_ogg_page_version               : togg_page_version;
  proc_ogg_stream_clear               : togg_stream_clear;
  proc_ogg_stream_destroy             : togg_stream_destroy;
  proc_ogg_stream_eos                 : togg_stream_eos;
  proc_ogg_stream_flush               : togg_stream_flush;
  proc_ogg_stream_init                : togg_stream_init;
  proc_ogg_stream_packetin            : togg_stream_packetin;
  proc_ogg_stream_packetout           : togg_stream_packetout;
  proc_ogg_stream_packetpeek          : togg_stream_packetpeek;
  proc_ogg_stream_pagein              : togg_stream_pagein;
  proc_ogg_stream_pageout             : togg_stream_pageout;
  proc_ogg_stream_reset               : togg_stream_reset;
  proc_ogg_stream_reset_serialno      : togg_stream_reset_serialno;
  proc_ogg_sync_buffer                : togg_sync_buffer;
  proc_ogg_sync_clear                 : togg_sync_clear;
  proc_ogg_sync_destroy               : togg_sync_destroy;
  proc_ogg_sync_init                  : togg_sync_init;
  proc_ogg_sync_pageout               : togg_sync_pageout;
  proc_ogg_sync_pageseek              : togg_sync_pageseek;
  proc_ogg_sync_reset                 : togg_sync_reset;
  proc_ogg_sync_wrote                 : togg_sync_wrote;
  proc_oggpack_adv                    : toggpack_adv;
  proc_oggpack_adv1                   : toggpack_adv1;
  proc_oggpack_bits                   : toggpack_bits;
  proc_oggpack_bytes                  : toggpack_bytes;
  proc_oggpack_get_buffer             : toggpack_get_buffer;
  proc_oggpack_look                   : toggpack_look;
  proc_oggpack_look1                  : toggpack_look1;
  proc_oggpack_read                   : toggpack_read;
  proc_oggpack_read1                  : toggpack_read1;
  proc_oggpack_readinit               : toggpack_readinit;
  proc_oggpack_reset                  : toggpack_reset;
  proc_oggpack_write                  : toggpack_write;
  proc_oggpack_writealign             : toggpack_writealign;
  proc_oggpack_writeclear             : toggpack_writeclear;
  proc_oggpack_writeinit              : toggpack_writeinit;
  proc_oggpack_writetrunc             : toggpack_writetrunc;
  proc_oggpack_writecopy              : toggpack_writecopy;
  proc_ogg_page_checksum_set          : togg_page_checksum_set;
  //------------------           //------------------
  proc_vorbis_analysis                : tvorbis_analysis;
  proc_vorbis_analysis_blockout       : tvorbis_analysis_blockout;
  proc_vorbis_analysis_buffer         : tvorbis_analysis_buffer;
  proc_vorbis_analysis_headerout      : tvorbis_analysis_headerout;
  proc_vorbis_analysis_init           : tvorbis_analysis_init;
  proc_vorbis_analysis_wrote          : tvorbis_analysis_wrote;
  proc_vorbis_bitrate_addblock        : tvorbis_bitrate_addblock;
  proc_vorbis_bitrate_flushpacket     : tvorbis_bitrate_flushpacket;
  proc_vorbis_block_clear             : tvorbis_block_clear;
  proc_vorbis_block_init              : tvorbis_block_init;
  proc_vorbis_comment_add             : tvorbis_comment_add;
  proc_vorbis_comment_add_tag         : tvorbis_comment_add_tag;
  proc_vorbis_comment_clear           : tvorbis_comment_clear;
  proc_vorbis_comment_init            : tvorbis_comment_init;
  proc_vorbis_comment_query           : tvorbis_comment_query;
  proc_vorbis_comment_query_count     : tvorbis_comment_query_count;
  proc_vorbis_commentheader_out       : tvorbis_commentheader_out;
  proc_vorbis_dsp_clear               : tvorbis_dsp_clear;
  proc_vorbis_encode_setup_init       : tvorbis_encode_setup_init;
  proc_vorbis_encode_setup_managed    : tvorbis_encode_setup_managed;
  proc_vorbis_encode_setup_vbr        : tvorbis_encode_setup_vbr;
  proc_vorbis_info_blocksize          : tvorbis_info_blocksize;
  proc_vorbis_info_clear              : tvorbis_info_clear;
  proc_vorbis_info_init               : tvorbis_info_init;
  proc_vorbis_packet_blocksize        : tvorbis_packet_blocksize;
  proc_vorbis_synthesis               : tvorbis_synthesis;
  proc_vorbis_synthesis_blockin       : tvorbis_synthesis_blockin;
  proc_vorbis_synthesis_headerin      : tvorbis_synthesis_headerin;
  proc_vorbis_synthesis_init          : tvorbis_synthesis_init;
  proc_vorbis_synthesis_pcmout        : tvorbis_synthesis_pcmout;
  proc_vorbis_synthesis_read          : tvorbis_synthesis_read;
  proc_vorbis_synthesis_trackonly     : tvorbis_synthesis_trackonly;
  //-----------------------------//---------------------------------
  proc_vorbis_encode_init             : tvorbis_encode_init;
  proc_vorbis_encode_init_vbr         : tvorbis_encode_init_vbr;
  proc_vorbis_encode_ctl              : tvorbis_encode_ctl;
  //-----------------------------//-----------------------------------
  proc_ov_bitrate                     : tov_bitrate;
  proc_ov_bitrate_instant             : tov_bitrate_instant;
  proc_ov_clear                       : tov_clear;
  proc_ov_comment                     : tov_comment;
  proc_ov_info                        : tov_info;
  proc_ov_open                        : tov_open;
  proc_ov_open_callbacks              : tov_open_callbacks;
  proc_ov_pcm_seek                    : tov_pcm_seek;
  proc_ov_pcm_seek_page               : tov_pcm_seek_page;
  proc_ov_pcm_tell                    : tov_pcm_tell;
  proc_ov_pcm_total                   : tov_pcm_total;
  proc_ov_raw_seek                    : tov_raw_seek;
  proc_ov_raw_tell                    : tov_raw_tell;
  proc_ov_raw_total                   : tov_raw_total;
  proc_ov_read                        : tov_read;
  proc_ov_seekable                    : tov_seekable;
  proc_ov_serialnumber                : tov_serialnumber;
  proc_ov_streams                     : tov_streams;
  proc_ov_test                        : tov_test;
  proc_ov_test_callbacks              : tov_test_callbacks;
  proc_ov_test_open                   : tov_test_open;
  proc_ov_time_seek                   : tov_time_seek;
  proc_ov_time_seek_page              : tov_time_seek_page;
  proc_ov_time_tell                   : tov_time_tell;
  proc_ov_time_total                  : tov_time_total;
  proc_ov_read_float                  : tov_read_float;

// --------------------

var
  g_dllLoad_ogg_refCount	: integer	= 0;
  g_dllLoad_vorbis_refCount	: integer	= 0;
  g_dllLoad_vorbisenc_refCount	: integer	= 0;
  g_dllLoad_vorbisfile_refCount	: integer	= 0;
  //
  g_dllLoad_ogg	: hModule;
  g_dllLoad_vorbis: hModule;
  g_dllLoad_vorbisenc: hModule;
  g_dllLoad_vorbisfile: hModule;

// --------------------

procedure ogg_packet_clear(const op: tOgg_packet);	// ogg.dll #1
begin
  if (0 < g_dllLoad_ogg_refCount) then
    proc_ogg_packet_clear(op);
end;

function ogg_page_bos(const og: tOgg_page): ogg_int32_t;	// ogg.dll #2
begin
  if (0 < g_dllLoad_ogg_refCount) then
    result := proc_ogg_page_bos(og)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function ogg_page_continued(const og: tOgg_page): ogg_int32_t;	// ogg.dll #3
begin
  if (0 < g_dllLoad_ogg_refCount) then
    result := proc_ogg_page_continued(og)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function ogg_page_eos(const og: tOgg_page): ogg_int32_t;	// ogg.dll #4
begin
  if (0 < g_dllLoad_ogg_refCount) then
    result := proc_ogg_page_eos(og)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function ogg_page_granulepos(const og: tOgg_page): ogg_int64_t;	// ogg.dll #5
begin
  if (0 < g_dllLoad_ogg_refCount) then
    result := proc_ogg_page_granulepos(og)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function ogg_page_packets(const og: tOgg_page): ogg_int32_t;	// ogg.dll #6
begin
  if (0 < g_dllLoad_ogg_refCount) then
    result := proc_ogg_page_packets(og)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function ogg_page_pageno(const og: tOgg_page): ogg_int32_t;	// ogg.dll #7
begin
  if (0 < g_dllLoad_ogg_refCount) then
    result := proc_ogg_page_pageno(og)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function ogg_page_serialno(const og: tOgg_page): ogg_int32_t;	// ogg.dll #8
begin
  if (0 < g_dllLoad_ogg_refCount) then
    result := proc_ogg_page_serialno(og)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function ogg_page_version(const og: tOgg_page): ogg_int32_t;	// ogg.dll #9
begin
  if (0 < g_dllLoad_ogg_refCount) then
    result := proc_ogg_page_version(og)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function ogg_stream_clear(const os: tOgg_stream_state): ogg_int32_t;	// ogg.dll #10
begin
  if (0 < g_dllLoad_ogg_refCount) then
    result := proc_ogg_stream_clear(os)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function ogg_stream_destroy(const os: tOgg_stream_state): ogg_int32_t;	// ogg.dll #11
begin
  if (0 < g_dllLoad_ogg_refCount) then
    result := proc_ogg_stream_destroy(os)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function ogg_stream_eos(const os: tOgg_stream_state): ogg_int32_t;	// ogg.dll #12
begin
  if (0 < g_dllLoad_ogg_refCount) then
    result := proc_ogg_stream_eos(os)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function ogg_stream_flush(const os: tOgg_stream_state; const og: tOgg_page): ogg_int32_t;	// ogg.dll #13
begin
  if (0 < g_dllLoad_ogg_refCount) then
    result := proc_ogg_stream_flush(os, og)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function ogg_stream_init(var os: tOgg_stream_state; serialno: ogg_int32_t): ogg_int32_t;		// ogg.dll #14
begin
  if (0 < g_dllLoad_ogg_refCount) then
    result := proc_ogg_stream_init(os, serialno)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function ogg_stream_packetin(const os: tOgg_stream_state; const op: tOgg_packet): ogg_int32_t;	// ogg.dll #15
begin
  if (0 < g_dllLoad_ogg_refCount) then
    result := proc_ogg_stream_packetin(os, op)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function ogg_stream_packetout(const os: tOgg_stream_state; const op: tOgg_packet): ogg_int32_t;	// ogg.dll #16
begin
  if (0 < g_dllLoad_ogg_refCount) then
    result := proc_ogg_stream_packetout(os, op)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function ogg_stream_packetpeek(const os: tOgg_stream_state; const op: tOgg_packet): ogg_int32_t;	// ogg.dll #17
begin
  if (0 < g_dllLoad_ogg_refCount) then
    result := proc_ogg_stream_packetpeek(os, op)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function ogg_stream_pagein(const os: tOgg_stream_state; const og: tOgg_page): ogg_int32_t;	// ogg.dll #18
begin
  if (0 < g_dllLoad_ogg_refCount) then
    result := proc_ogg_stream_pagein(os, og)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function ogg_stream_pageout(const os: tOgg_stream_state; const og: tOgg_page): ogg_int32_t;	// ogg.dll #19
begin
  if (0 < g_dllLoad_ogg_refCount) then
    result := proc_ogg_stream_pageout(os, og)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function ogg_stream_reset(const os: tOgg_stream_state): ogg_int32_t;	// ogg.dll #20
begin
  if (0 < g_dllLoad_ogg_refCount) then
    result := proc_ogg_stream_reset(os)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function ogg_stream_reset_serialno(const os: tOgg_stream_state; serialno: ogg_int32_t): ogg_int32_t;	// ogg.dll #21
begin
  if (0 < g_dllLoad_ogg_refCount) then
    result := proc_ogg_stream_reset_serialno(os, serialno)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function ogg_sync_buffer(const oy: tOgg_sync_state; size: ogg_int32_t): pAnsiChar;	// ogg.dll #22
begin
  if (0 < g_dllLoad_ogg_refCount) then
    result := proc_ogg_sync_buffer(oy, size)
  else
    result := nil;
end;

function ogg_sync_clear(const oy: tOgg_sync_state): ogg_int32_t;	// ogg.dll #23
begin
  if (0 < g_dllLoad_ogg_refCount) then
    result := proc_ogg_sync_clear(oy)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function ogg_sync_destroy(var oy: tOgg_sync_state): ogg_int32_t;	// ogg.dll #24
begin
  if (0 < g_dllLoad_ogg_refCount) then
    result := proc_ogg_sync_destroy(oy)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function ogg_sync_init(var oy: tOgg_sync_state): ogg_int32_t;	// ogg.dll #25
begin
  if (0 < g_dllLoad_ogg_refCount) then
    result := proc_ogg_sync_init(oy)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function ogg_sync_pageout(const oy: tOgg_sync_state; const og: tOgg_page): ogg_int32_t;		// ogg.dll #26
begin
  if (0 < g_dllLoad_ogg_refCount) then
    result := proc_ogg_sync_pageout(oy, og)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function ogg_sync_pageseek(const oy: tOgg_sync_state; const og: tOgg_page): ogg_int32_t;	// ogg.dll #27
begin
  if (0 < g_dllLoad_ogg_refCount) then
    result := proc_ogg_sync_pageseek(oy, og)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function ogg_sync_reset(const oy: tOgg_sync_state): ogg_int32_t;	// ogg.dll #28
begin
  if (0 < g_dllLoad_ogg_refCount) then
    result := proc_ogg_sync_reset(oy)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function ogg_sync_wrote(const oy: tOgg_sync_state; bytes: ogg_int32_t): ogg_int32_t;	// ogg.dll #29
begin
  if (0 < g_dllLoad_ogg_refCount) then
    result := proc_ogg_sync_wrote(oy, bytes)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

procedure oggpack_adv(const b: tOggpack_buffer; bits: ogg_int32_t);	// ogg.dll #30
begin
  if (0 < g_dllLoad_ogg_refCount) then
    proc_oggpack_adv(b, bits);
end;

procedure oggpack_adv1(const b: tOggpack_buffer);		// ogg.dll #31
begin
  if (0 < g_dllLoad_ogg_refCount) then
    proc_oggpack_adv1(b);
end;

function oggpack_bits(const b: tOggpack_buffer): ogg_int32_t;		// ogg.dll #32
begin
  if (0 < g_dllLoad_ogg_refCount) then
    result := proc_oggpack_bits(b)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function oggpack_bytes(const b: tOggpack_buffer): ogg_int32_t;		// ogg.dll #33
begin
  if (0 < g_dllLoad_ogg_refCount) then
    result := proc_oggpack_bytes(b)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function oggpack_get_buffer(const b: tOggpack_buffer): pointer;	// ogg.dll #34
begin
  if (0 < g_dllLoad_ogg_refCount) then
    result := proc_oggpack_get_buffer(b)
  else
    result := nil;
end;

function oggpack_look(const b: tOggpack_buffer; bits: ogg_int32_t): ogg_int32_t;	// ogg.dll #35
begin
  if (0 < g_dllLoad_ogg_refCount) then
    result := proc_oggpack_look(b, bits)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function oggpack_look1(const b: tOggpack_buffer; bits: ogg_int32_t): ogg_int32_t;	// ogg.dll #36
begin
  if (0 < g_dllLoad_ogg_refCount) then
    result := proc_oggpack_look1(b, bits)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function oggpack_read(const b: tOggpack_buffer; bits: ogg_int32_t): ogg_int32_t;	// ogg.dll #37
begin
  if (0 < g_dllLoad_ogg_refCount) then
    result := proc_oggpack_read(b, bits)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function oggpack_read1(const b: tOggpack_buffer): ogg_int32_t;		// ogg.dll #38
begin
  if (0 < g_dllLoad_ogg_refCount) then
    result := proc_oggpack_read1(b)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

procedure oggpack_readinit(const b: tOggpack_buffer; buf: pointer; bytes: ogg_int32_t);	// ogg.dll #39
begin
  if (0 < g_dllLoad_ogg_refCount) then
    proc_oggpack_readinit(b, buf, bytes);
end;

procedure oggpack_reset(const b: tOggpack_buffer);		// ogg.dll #40
begin
  if (0 < g_dllLoad_ogg_refCount) then
    proc_oggpack_reset(b);
end;

procedure oggpack_write(const b: tOggpack_buffer; value: ogg_uint32_t; bits: ogg_int32_t);	// ogg.dll #41
begin
  if (0 < g_dllLoad_ogg_refCount) then
    proc_oggpack_write(b, value, bits);
end;

procedure oggpack_writealign(const b: tOggpack_buffer);		// ogg.dll #42
begin
  if (0 < g_dllLoad_ogg_refCount) then
    proc_oggpack_writealign(b);
end;

procedure oggpack_writeclear(const b: tOggpack_buffer);		// ogg.dll #43
begin
  if (0 < g_dllLoad_ogg_refCount) then
    proc_oggpack_writeclear(b);
end;

procedure oggpack_writeinit(const b: tOggpack_buffer);		// ogg.dll #44
begin
  if (0 < g_dllLoad_ogg_refCount) then
    proc_oggpack_writeinit(b);
end;

procedure oggpack_writetrunc(const b: tOggpack_buffer; bits: ogg_int32_t);	// ??
begin
//  result := OV_ERR_NOT_SUPPORED;
//
//  if (0 <> g_dllLoad_ogg_refCount) then
//    proc_oggpack_writetrunc(b, bits);
end;

procedure oggpack_writecopy(const b: tOggpack_buffer; source: pointer; bits: ogg_int32_t);	// ??
begin
//  result := OV_ERR_NOT_SUPPORED;
//
//  if (0 <> g_dllLoad_ogg_refCount) then
//    proc_oggpack_writecopy(b, source, bits);
end;

procedure ogg_page_checksum_set(const og: tOgg_page);	// ??
begin
//  result := OV_ERR_NOT_SUPPORED;
//
//  if (0 <> g_dllLoad_ogg_refCount) then
//    proc_ogg_page_checksum_set(og);
end;

// ------------------------

function vorbis_analysis(const vb: tVorbis_block; op: pOgg_packet): ogg_int32_t;	// vorbis.dll #4
begin
  if (0 < g_dllLoad_vorbis_refCount) then
    try
      result := proc_vorbis_analysis(vb, op)
    except
      result := OV_ERR_NO_DLL_LOADED;
    end
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function vorbis_analysis_blockout(const v: tVorbis_dsp_state; const vb: tVorbis_block): ogg_int32_t;	// vorbis.dll #5
begin
  if (0 < g_dllLoad_vorbis_refCount) then
    result := proc_vorbis_analysis_blockout(v, vb)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function vorbis_analysis_buffer(const v: tVorbis_dsp_state; vals: ogg_int32_t): pSingleSamples; // float **	// vorbis.dll #6
begin
  if (0 < g_dllLoad_vorbis_refCount) then
    result := proc_vorbis_analysis_buffer(v, vals)
  else
    result := nil;
end;

function vorbis_analysis_headerout(const v: tVorbis_dsp_state; const vc: tVorbis_comment; const op: tOgg_packet; const op_comm: tOgg_packet; const op_code: tOgg_packet): ogg_int32_t;	// vorbis.dll #7
begin
  if (0 < g_dllLoad_vorbis_refCount) then
    result := proc_vorbis_analysis_headerout(v, vc, op, op_comm, op_code)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function vorbis_analysis_init(var v: tVorbis_dsp_state; const vi: tVorbis_info): ogg_int32_t;	// vorbis.dll #8
begin
  if (0 < g_dllLoad_vorbis_refCount) then
    result := proc_vorbis_analysis_init(v, vi)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function vorbis_analysis_wrote(const v: tVorbis_dsp_state; vals: ogg_int32_t): ogg_int32_t;	// vorbis.dll #9
begin
  if (0 < g_dllLoad_vorbis_refCount) then
    result := proc_vorbis_analysis_wrote(v, vals)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function vorbis_bitrate_addblock(const vb: tVorbis_block): ogg_int32_t;	// vorbis.dll #10
begin
  if (0 < g_dllLoad_vorbis_refCount) then
    result := proc_vorbis_bitrate_addblock(vb)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function vorbis_bitrate_flushpacket(const vd: tVorbis_dsp_state; const op: tOgg_packet): ogg_int32_t;	// vorbis.dll #11
begin
  if (0 < g_dllLoad_vorbis_refCount) then
    result := proc_vorbis_bitrate_flushpacket(vd, op)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function vorbis_block_clear(const vb: tVorbis_block): ogg_int32_t;	// vorbis.dll #12
begin
  if (0 < g_dllLoad_vorbis_refCount) then
    result := proc_vorbis_block_clear(vb)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function vorbis_block_init(const v: tVorbis_dsp_state; var vb: tVorbis_block): ogg_int32_t;	// vorbis.dll #13
begin
  if (0 < g_dllLoad_vorbis_refCount) then
    result := proc_vorbis_block_init(v, vb)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

procedure vorbis_comment_add(const vc: tVorbis_comment; comment: pAnsiChar);	// vorbis.dll #14
begin
  if (0 < g_dllLoad_vorbis_refCount) then
    proc_vorbis_comment_add(vc, comment);
end;

procedure vorbis_comment_add_tag(var vc: tVorbis_comment; tag: pAnsiChar; contents: pAnsiChar);	// vorbis.dll #15
begin
  if (0 < g_dllLoad_vorbis_refCount) then
    proc_vorbis_comment_add_tag(vc, tag, contents);
end;

procedure vorbis_comment_clear(const vc: tVorbis_comment);	// vorbis.dll #16
begin
  if (0 < g_dllLoad_vorbis_refCount) then
    proc_vorbis_comment_clear(vc);
end;

procedure vorbis_comment_init(const vc: tVorbis_comment);	// vorbis.dll #17
begin
  if (0 < g_dllLoad_vorbis_refCount) then
    proc_vorbis_comment_init(vc);
end;

function vorbis_comment_query(const vc: tVorbis_comment; tag: pAnsiChar; count: ogg_int32_t): pAnsiChar;	// vorbis.dll #18
begin
  if (0 < g_dllLoad_vorbis_refCount) then
    result := proc_vorbis_comment_query(vc, tag, count)
  else
    result := nil;
end;

function vorbis_comment_query_count(const vc: tVorbis_comment; tag: pAnsiChar): ogg_int32_t;	// vorbis.dll #19
begin
  if (0 < g_dllLoad_vorbis_refCount) then
    result := proc_vorbis_comment_query_count(vc, tag)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function vorbis_commentheader_out(const vc: tVorbis_comment; const op: tOgg_packet): ogg_int32_t;	// vorbis.dll #20
begin
  if (0 < g_dllLoad_vorbis_refCount) then
    result := proc_vorbis_commentheader_out(vc, op)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

procedure vorbis_dsp_clear(const v: tVorbis_dsp_state);	// vorbis.dll #21
begin
  if (0 < g_dllLoad_vorbis_refCount) then
    proc_vorbis_dsp_clear(v);
end;

function vorbis_encode_setup_init(const vi: tVorbis_info): ogg_int32_t;	// vorbis.dll #22
begin
  if (0 < g_dllLoad_vorbis_refCount) then
    result := proc_vorbis_encode_setup_init(vi)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function vorbis_encode_setup_managed(const vi: tVorbis_info; channels, rate, max_bitrate, nominal_bitrate, min_bitrate: ogg_int32_t): ogg_int32_t;	// vorbis.dll #23
begin
  if (0 < g_dllLoad_vorbis_refCount) then
    result := proc_vorbis_encode_setup_managed(vi, channels, rate, max_bitrate, nominal_bitrate, min_bitrate)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function vorbis_encode_setup_vbr(const vi: tVorbis_info; channels, rate: ogg_int32_t; quality: single { quality level from 0. (lo) to 1. (hi) }): ogg_int32_t;	// vorbis.dll #24
begin
  if (0 < g_dllLoad_vorbis_refCount) then
    result := proc_vorbis_encode_setup_vbr(vi, channels, rate, quality)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function vorbis_info_blocksize(const vi: tVorbis_info; zo: ogg_int32_t): ogg_int32_t;	// vorbis.dll #25
begin
  if (0 < g_dllLoad_vorbis_refCount) then
    result := proc_vorbis_info_blocksize(vi, zo)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

procedure vorbis_info_clear(const vi: tVorbis_info);	// vorbis.dll #26
begin
  if (0 < g_dllLoad_vorbis_refCount) then
    proc_vorbis_info_clear(vi);
end;

procedure vorbis_info_init(var vi: tVorbis_info);	// vorbis.dll #27
begin
  if (0 < g_dllLoad_vorbis_refCount) then
    proc_vorbis_info_init(vi);
end;

function vorbis_packet_blocksize(const vi: tVorbis_info; const op: tOgg_packet): ogg_int32_t;	// vorbis.dll #28
begin
  if (0 < g_dllLoad_vorbis_refCount) then
    result := proc_vorbis_packet_blocksize(vi, op)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function vorbis_synthesis(const vb: tVorbis_block; const op: tOgg_packet): ogg_int32_t;	// vorbis.dll #29
begin
  if (0 < g_dllLoad_vorbis_refCount) then
    result := proc_vorbis_synthesis(vb, op)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function vorbis_synthesis_blockin(const v: tVorbis_dsp_state; const vb: tVorbis_block): ogg_int32_t;	// vorbis.dll #30
begin
  if (0 < g_dllLoad_vorbis_refCount) then
    result := proc_vorbis_synthesis_blockin(v, vb)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function vorbis_synthesis_headerin(const vi: tVorbis_info; const vc: tVorbis_comment; const op: tOgg_packet): ogg_int32_t;	// vorbis.dll #31
begin
  if (0 < g_dllLoad_vorbis_refCount) then
    result := proc_vorbis_synthesis_headerin(vi, vc, op)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function vorbis_synthesis_init(const v: tVorbis_dsp_state; const vi: tVorbis_info): ogg_int32_t;	// vorbis.dll #32
begin
  if (0 < g_dllLoad_vorbis_refCount) then
    result := proc_vorbis_synthesis_init(v, vi)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function vorbis_synthesis_pcmout(const v: tVorbis_dsp_state; var pcm: pSingleSamples {float **}): ogg_int32_t;	// vorbis.dll #33
begin
  if (0 < g_dllLoad_vorbis_refCount) then
    result := proc_vorbis_synthesis_pcmout(v, pcm)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function vorbis_synthesis_read(const v: tVorbis_dsp_state; const samples: ogg_int32_t): ogg_int32_t;	// vorbis.dll #34
begin
  if (0 < g_dllLoad_vorbis_refCount) then
    result := proc_vorbis_synthesis_read(v, samples)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function vorbis_synthesis_trackonly(const vb: tVorbis_block; const op: tOgg_packet): ogg_int32_t;	// vorbis.dll #35
begin
  if (0 < g_dllLoad_vorbis_refCount) then
    result := proc_vorbis_synthesis_trackonly(vb, op)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

// --------------------------------------

function vorbis_encode_init(const vi: tVorbis_info; channels, rate, max_bitrate, nominal_bitrate, min_bitrate: ogg_int32_t): ogg_int32_t;	// vorbisenc.dll #2
begin
  if (0 < g_dllLoad_vorbisenc_refCount) then
    result := proc_vorbis_encode_init(vi, channels, rate, max_bitrate, nominal_bitrate, min_bitrate)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function vorbis_encode_init_vbr(var vi: tVorbis_info; channels, rate: ogg_int32_t; base_quality: single { quality level from 0. (lo) to 1. (hi) }): ogg_int32_t;	// vorbisenc.dll #3
begin
  if (0 < g_dllLoad_vorbisenc_refCount) then
    result := proc_vorbis_encode_init_vbr(vi, channels, rate, base_quality)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function vorbis_encode_ctl(const vi: tVorbis_info; number: ogg_int32_t; arg: pointer): ogg_int32_t;	// vorbisenc.dll #1
begin
  if (0 < g_dllLoad_vorbisenc_refCount) then
    result := proc_vorbis_encode_ctl(vi, number, arg)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

// ----------------------------------------

function ov_bitrate(const vf: tOggVorbis_File; i: ogg_int32_t): ogg_int32_t;	// vorbisfile.dll #1
begin
  if (0 < g_dllLoad_vorbisfile_refCount) then
    result := proc_ov_bitrate(vf, i)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function ov_bitrate_instant(const vf: tOggVorbis_File): ogg_int32_t;	// vorbisfile.dll #2
begin
  if (0 < g_dllLoad_vorbisfile_refCount) then
    result := proc_ov_bitrate_instant(vf)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function ov_clear(const vf: tOggVorbis_File): ogg_int32_t;	// vorbisfile.dll #3
begin
  if (0 < g_dllLoad_vorbisfile_refCount) then
    result := proc_ov_clear(vf)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function ov_comment(const vf: tOggVorbis_File; link: ogg_int32_t): pVorbis_comment;	// vorbisfile.dll #4
begin
  if (0 < g_dllLoad_vorbisfile_refCount) then
    result := proc_ov_comment(vf, link)
  else
    result := nil;
end;

function ov_info(const vf: tOggVorbis_File; link: ogg_int32_t): pVorbis_info;	// vorbisfile.dll #5
begin
  if (0 < g_dllLoad_vorbisfile_refCount) then
    result := proc_ov_info(vf, link)
  else
    result := nil;
end;

function ov_open(const f: _FILE; const vf: tOggVorbis_File; initial: pAnsiChar; ibytes: ogg_int32_t): ogg_int32_t;	// vorbisfile.dll #6
begin
  if (0 < g_dllLoad_vorbisfile_refCount) then
    result := proc_ov_open(f, vf, initial, ibytes)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function ov_open_callbacks(datasource: pointer; const vf: tOggVorbis_File; initial: pAnsiChar; ibytes: ogg_int32_t; callbacks: tOv_callbacks): ogg_int32_t;	// vorbisfile.dll #7
begin
  if (0 < g_dllLoad_vorbisfile_refCount) then
    result := proc_ov_open_callbacks(datasource, vf, initial, ibytes, callbacks)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function ov_pcm_seek(const vf: tOggVorbis_File; pos: ogg_int64_t): ogg_int32_t;	// vorbisfile.dll #8
begin
  if (0 < g_dllLoad_vorbisfile_refCount) then
    result := proc_ov_pcm_seek(vf, pos)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function ov_pcm_seek_page(const vf: tOggVorbis_File; pos: ogg_int64_t): ogg_int32_t;	// vorbisfile.dll #9
begin
  if (0 < g_dllLoad_vorbisfile_refCount) then
    result := proc_ov_pcm_seek_page(vf, pos)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function ov_pcm_tell(const vf: tOggVorbis_File): ogg_int64_t;	// vorbisfile.dll #10
begin
  if (0 < g_dllLoad_vorbisfile_refCount) then
    result := proc_ov_pcm_tell(vf)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function ov_pcm_total(const vf: tOggVorbis_File; i: ogg_int32_t): ogg_int64_t;	// vorbisfile.dll #11
begin
  if (0 < g_dllLoad_vorbisfile_refCount) then
    result := proc_ov_pcm_total(vf, i)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function ov_raw_seek(const vf: tOggVorbis_File; pos: ogg_int64_t): ogg_int32_t;	// vorbisfile.dll #12
begin
  if (0 < g_dllLoad_vorbisfile_refCount) then
    result := proc_ov_raw_seek(vf, pos)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function ov_raw_tell(const vf: tOggVorbis_File): ogg_int64_t;	// vorbisfile.dll #13
begin
  if (0 < g_dllLoad_vorbisfile_refCount) then
    result := proc_ov_raw_tell(vf)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function ov_raw_total(const vf: tOggVorbis_File; i: ogg_int32_t): ogg_int64_t;	// vorbisfile.dll #14
begin
  if (0 < g_dllLoad_vorbisfile_refCount) then
    result := proc_ov_raw_total(vf, i)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function ov_read(const vf: tOggVorbis_File; buffer: pAnsiChar; length, bigendianp, _word, sgned: ogg_int32_t; var bitstream: ogg_int32_t): ogg_int32_t;	// vorbisfile.dll #15
begin
  if (0 < g_dllLoad_vorbisfile_refCount) then
    result := proc_ov_read(vf, buffer, length, bigendianp, _word, sgned, bitstream)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function ov_seekable(const vf: tOggVorbis_File): ogg_int32_t;	// vorbisfile.dll #16
begin
  if (0 < g_dllLoad_vorbisfile_refCount) then
    result := proc_ov_seekable(vf)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function ov_serialnumber(const vf: tOggVorbis_File; i: ogg_int32_t): ogg_int32_t;	// vorbisfile.dll #17
begin
  if (0 < g_dllLoad_vorbisfile_refCount) then
    result := proc_ov_serialnumber(vf, i)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function ov_streams(const vf: tOggVorbis_File): ogg_int32_t;	// vorbisfile.dll #18
begin
  if (0 < g_dllLoad_vorbisfile_refCount) then
    result := proc_ov_streams(vf)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function ov_test(const f: _FILE; const vf: tOggVorbis_File; initial: pAnsiChar; ibytes: ogg_int32_t): ogg_int32_t;	// vorbisfile.dll #19
begin
  if (0 < g_dllLoad_vorbisfile_refCount) then
    result := proc_ov_test(f, vf, initial, ibytes)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function ov_test_callbacks(datasource: pointer; const vf: tOggVorbis_File; initial: pAnsiChar; ibytes: ogg_int32_t; callbacks: tOv_callbacks): ogg_int32_t;	// vorbisfile.dll #20
begin
  if (0 < g_dllLoad_vorbisfile_refCount) then
    result := proc_ov_test_callbacks(datasource, vf, initial, ibytes, callbacks)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function ov_test_open(const vf: tOggVorbis_File): ogg_int32_t;	// vorbisfile.dll #21
begin
  if (0 < g_dllLoad_vorbisfile_refCount) then
    result := proc_ov_test_open(vf)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function ov_time_seek(const vf: tOggVorbis_File; pos: double): ogg_int32_t;	// vorbisfile.dll #22
begin
  if (0 < g_dllLoad_vorbisfile_refCount) then
    result := proc_ov_time_seek(vf, pos)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function ov_time_seek_page(const vf: tOggVorbis_File; pos: double): ogg_int32_t;	// vorbisfile.dll #23
begin
  if (0 < g_dllLoad_vorbisfile_refCount) then
    result := proc_ov_time_seek_page(vf, pos)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function ov_time_tell(const vf: tOggVorbis_File): double;	// vorbisfile.dll #24
begin
  if (0 < g_dllLoad_vorbisfile_refCount) then
    result := proc_ov_time_tell(vf)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function ov_time_total(const vf: tOggVorbis_File; i: ogg_int32_t): double;	// vorbisfile.dll #25
begin
  if (0 < g_dllLoad_vorbisfile_refCount) then
    result := proc_ov_time_total(vf, i)
  else
    result := OV_ERR_NO_DLL_LOADED;
end;

function ov_read_float(const vf: tOggVorbis_File; var pcm_channels: pSingleSamples{float **}; samples: ogg_int32_t; var bitstream: ogg_int32_t): ogg_int32_t;	// ??
begin
  result := OV_ERR_NOT_SUPPORED;
  //
  {if (0 < g_dllLoad_vorbisfile_refCount) then
    result := proc_ov_read_float(vf, pcm_channels, samples, bitstream)
  else
    result := OV_ERR_NO_DLL_LOADED;}
end;


// --  --

function vorbis_load_library(libraryToLoad: int; const libraryName: wideString = ''): boolean;
begin
  case (libraryToLoad) of

    cunav_dll_ogg: begin
      //
      if (0 = g_dllLoad_ogg_refCount) then begin
	g_dllLoad_ogg_refCount := -1;
	//
	if ('' <> libraryName) then begin
          //
{$IFNDEF NO_ANSI_SUPPORT }
          if (g_wideApiSupported) then
{$ENDIF NO_ANSI_SUPPORT }
            g_dllLoad_ogg := LoadLibraryW(pWideChar(libraryName))
{$IFNDEF NO_ANSI_SUPPORT }
	  else
            g_dllLoad_ogg := LoadLibraryA(pAnsiChar(AnsiString(libraryName)))
{$ENDIF NO_ANSI_SUPPORT }
          ;
        end
	else begin
          //
{$IFNDEF NO_ANSI_SUPPORT }
          if (g_wideApiSupported) then
{$ENDIF NO_ANSI_SUPPORT }
   	    g_dllLoad_ogg := LoadLibraryW(pWideChar(wideString(c_dllName_ogg)))
{$IFNDEF NO_ANSI_SUPPORT }
          else
   	    g_dllLoad_ogg := LoadLibraryA(pAnsiChar(AnsiString(c_dllName_ogg)));
{$ENDIF NO_ANSI_SUPPORT }
          ;
        end;
	//
	if (0 <> g_dllLoad_ogg) then begin
	  //
	  proc_ogg_packet_clear               := Windows.GetProcAddress(g_dllLoad_ogg, 'ogg_packet_clear');
	  proc_ogg_page_bos                   := Windows.GetProcAddress(g_dllLoad_ogg, 'ogg_page_bos');
	  proc_ogg_page_continued             := Windows.GetProcAddress(g_dllLoad_ogg, 'ogg_page_continued');
	  proc_ogg_page_eos                   := Windows.GetProcAddress(g_dllLoad_ogg, 'ogg_page_eos');
	  proc_ogg_page_granulepos            := Windows.GetProcAddress(g_dllLoad_ogg, 'ogg_page_granulepos');
	  proc_ogg_page_packets               := Windows.GetProcAddress(g_dllLoad_ogg, 'ogg_page_packets');
	  proc_ogg_page_pageno                := Windows.GetProcAddress(g_dllLoad_ogg, 'ogg_page_pageno');
	  proc_ogg_page_serialno              := Windows.GetProcAddress(g_dllLoad_ogg, 'ogg_page_serialno');
	  proc_ogg_page_version               := Windows.GetProcAddress(g_dllLoad_ogg, 'ogg_page_version');
	  proc_ogg_stream_clear               := Windows.GetProcAddress(g_dllLoad_ogg, 'ogg_stream_clear');
	  proc_ogg_stream_destroy             := Windows.GetProcAddress(g_dllLoad_ogg, 'ogg_stream_destroy');
	  proc_ogg_stream_eos                 := Windows.GetProcAddress(g_dllLoad_ogg, 'ogg_stream_eos');
	  proc_ogg_stream_flush               := Windows.GetProcAddress(g_dllLoad_ogg, 'ogg_stream_flush');
	  proc_ogg_stream_init                := Windows.GetProcAddress(g_dllLoad_ogg, 'ogg_stream_init');
	  proc_ogg_stream_packetin            := Windows.GetProcAddress(g_dllLoad_ogg, 'ogg_stream_packetin');
	  proc_ogg_stream_packetout           := Windows.GetProcAddress(g_dllLoad_ogg, 'ogg_stream_packetout');
	  proc_ogg_stream_packetpeek          := Windows.GetProcAddress(g_dllLoad_ogg, 'ogg_stream_packetpeek');
	  proc_ogg_stream_pagein              := Windows.GetProcAddress(g_dllLoad_ogg, 'ogg_stream_pagein');
	  proc_ogg_stream_pageout             := Windows.GetProcAddress(g_dllLoad_ogg, 'ogg_stream_pageout');
	  proc_ogg_stream_reset               := Windows.GetProcAddress(g_dllLoad_ogg, 'ogg_stream_reset');
	  proc_ogg_stream_reset_serialno      := Windows.GetProcAddress(g_dllLoad_ogg, 'ogg_stream_reset_serialno');
	  proc_ogg_sync_buffer                := Windows.GetProcAddress(g_dllLoad_ogg, 'ogg_sync_buffer');
	  proc_ogg_sync_clear                 := Windows.GetProcAddress(g_dllLoad_ogg, 'ogg_sync_clear');
	  proc_ogg_sync_destroy               := Windows.GetProcAddress(g_dllLoad_ogg, 'ogg_sync_destroy');
	  proc_ogg_sync_init                  := Windows.GetProcAddress(g_dllLoad_ogg, 'ogg_sync_init');
	  proc_ogg_sync_pageout               := Windows.GetProcAddress(g_dllLoad_ogg, 'ogg_sync_pageout');
	  proc_ogg_sync_pageseek              := Windows.GetProcAddress(g_dllLoad_ogg, 'ogg_sync_pageseek');
	  proc_ogg_sync_reset                 := Windows.GetProcAddress(g_dllLoad_ogg, 'ogg_sync_reset');
	  proc_ogg_sync_wrote                 := Windows.GetProcAddress(g_dllLoad_ogg, 'ogg_sync_wrote');
	  proc_oggpack_adv                    := Windows.GetProcAddress(g_dllLoad_ogg, 'oggpack_adv');
	  proc_oggpack_adv1                   := Windows.GetProcAddress(g_dllLoad_ogg, 'oggpack_adv1');
	  proc_oggpack_bits                   := Windows.GetProcAddress(g_dllLoad_ogg, 'oggpack_bits');
	  proc_oggpack_bytes                  := Windows.GetProcAddress(g_dllLoad_ogg, 'oggpack_bytes');
	  proc_oggpack_get_buffer             := Windows.GetProcAddress(g_dllLoad_ogg, 'oggpack_get_buffer');
	  proc_oggpack_look                   := Windows.GetProcAddress(g_dllLoad_ogg, 'oggpack_look');
	  proc_oggpack_look1                  := Windows.GetProcAddress(g_dllLoad_ogg, 'oggpack_look1');
	  proc_oggpack_read                   := Windows.GetProcAddress(g_dllLoad_ogg, 'oggpack_read');
	  proc_oggpack_read1                  := Windows.GetProcAddress(g_dllLoad_ogg, 'oggpack_read1');
	  proc_oggpack_readinit               := Windows.GetProcAddress(g_dllLoad_ogg, 'oggpack_readinit');
	  proc_oggpack_reset                  := Windows.GetProcAddress(g_dllLoad_ogg, 'oggpack_reset');
	  proc_oggpack_write                  := Windows.GetProcAddress(g_dllLoad_ogg, 'oggpack_write');
	  proc_oggpack_writealign             := Windows.GetProcAddress(g_dllLoad_ogg, 'oggpack_writealign');
	  proc_oggpack_writeclear             := Windows.GetProcAddress(g_dllLoad_ogg, 'oggpack_writeclear');
	  proc_oggpack_writeinit              := Windows.GetProcAddress(g_dllLoad_ogg, 'oggpack_writeinit');
	  proc_oggpack_writetrunc             := Windows.GetProcAddress(g_dllLoad_ogg, 'oggpack_writetrunc');
	  proc_oggpack_writecopy              := Windows.GetProcAddress(g_dllLoad_ogg, 'oggpack_writecopy');
	  proc_ogg_page_checksum_set          := Windows.GetProcAddress(g_dllLoad_ogg, 'ogg_page_checksum_set');
	  //
	  if (assigned(proc_ogg_packet_clear) and
	      assigned(proc_ogg_page_bos) and
	      assigned(proc_ogg_page_continued) and
	      assigned(proc_ogg_page_eos) and
	      assigned(proc_ogg_page_granulepos) and
	      assigned(proc_ogg_page_packets) and
	      assigned(proc_ogg_page_pageno) and
	      assigned(proc_ogg_page_serialno) and
	      assigned(proc_ogg_page_version) and
	      assigned(proc_ogg_stream_clear) and
	      assigned(proc_ogg_stream_destroy) and
	      assigned(proc_ogg_stream_eos) and
	      assigned(proc_ogg_stream_flush) and
	      assigned(proc_ogg_stream_init) and
	      assigned(proc_ogg_stream_packetin) and
	      assigned(proc_ogg_stream_packetout) and
	      assigned(proc_ogg_stream_packetpeek) and
	      assigned(proc_ogg_stream_pagein) and
	      assigned(proc_ogg_stream_pageout) and
	      assigned(proc_ogg_stream_reset) and
	      assigned(proc_ogg_stream_reset_serialno) and
	      assigned(proc_ogg_sync_buffer) and
	      assigned(proc_ogg_sync_clear) and
	      assigned(proc_ogg_sync_destroy) and
	      assigned(proc_ogg_sync_init) and
	      assigned(proc_ogg_sync_pageout) and
	      assigned(proc_ogg_sync_pageseek) and
	      assigned(proc_ogg_sync_reset) and
	      assigned(proc_ogg_sync_wrote) and
	      assigned(proc_oggpack_adv) and
	      assigned(proc_oggpack_adv1) and
	      assigned(proc_oggpack_bits) and
	      assigned(proc_oggpack_bytes) and
	      assigned(proc_oggpack_get_buffer) and
	      assigned(proc_oggpack_look) and
	      assigned(proc_oggpack_look1) and
	      assigned(proc_oggpack_read) and
	      assigned(proc_oggpack_read1) and
	      assigned(proc_oggpack_readinit) and
	      assigned(proc_oggpack_reset) and
	      assigned(proc_oggpack_write) and
	      assigned(proc_oggpack_writealign) and
	      assigned(proc_oggpack_writeclear) and
	      assigned(proc_oggpack_writeinit) and
	      true{assigned(proc_oggpack_writetrunc)} and
	      true{assigned(proc_oggpack_writecopy)} and
	      true{assigned(proc_ogg_page_checksum_set)}
	     ) then
	    g_dllLoad_ogg_refCount := 1
	  else begin
	    Windows.FreeLibrary(g_dllLoad_ogg);
	    g_dllLoad_ogg_refCount := 0;
	  end;
	end
	else
	  g_dllLoad_ogg_refCount := 0;
      end
      else
	if (0 < g_dllLoad_ogg_refCount) then
	  inc(g_dllLoad_ogg_refCount);
      //
      result := (0 < g_dllLoad_ogg_refCount);
    end;

    cunav_dll_vorbis: begin
      //------------------           //------------------
      if (0 = g_dllLoad_vorbis_refCount) then begin
	g_dllLoad_vorbis_refCount := -1;
	//
	if ('' <> libraryName) then
	  g_dllLoad_vorbis := Windows.LoadLibraryA(pAnsiChar(AnsiString(libraryName)))
	else
	  g_dllLoad_vorbis := Windows.LoadLibraryA(c_dllName_vorbis);
	//
	if (0 <> g_dllLoad_vorbis) then begin
	  //
	  proc_vorbis_analysis                := Windows.GetProcAddress(g_dllLoad_vorbis, 'vorbis_analysis');
	  proc_vorbis_analysis_blockout       := Windows.GetProcAddress(g_dllLoad_vorbis, 'vorbis_analysis_blockout');
	  proc_vorbis_analysis_buffer         := Windows.GetProcAddress(g_dllLoad_vorbis, 'vorbis_analysis_buffer');
	  proc_vorbis_analysis_headerout      := Windows.GetProcAddress(g_dllLoad_vorbis, 'vorbis_analysis_headerout');
	  proc_vorbis_analysis_init           := Windows.GetProcAddress(g_dllLoad_vorbis, 'vorbis_analysis_init');
	  proc_vorbis_analysis_wrote          := Windows.GetProcAddress(g_dllLoad_vorbis, 'vorbis_analysis_wrote');
	  proc_vorbis_bitrate_addblock        := Windows.GetProcAddress(g_dllLoad_vorbis, 'vorbis_bitrate_addblock');
	  proc_vorbis_bitrate_flushpacket     := Windows.GetProcAddress(g_dllLoad_vorbis, 'vorbis_bitrate_flushpacket');
	  proc_vorbis_block_clear             := Windows.GetProcAddress(g_dllLoad_vorbis, 'vorbis_block_clear');
	  proc_vorbis_block_init              := Windows.GetProcAddress(g_dllLoad_vorbis, 'vorbis_block_init');
	  proc_vorbis_comment_add             := Windows.GetProcAddress(g_dllLoad_vorbis, 'vorbis_comment_add');
	  proc_vorbis_comment_add_tag         := Windows.GetProcAddress(g_dllLoad_vorbis, 'vorbis_comment_add_tag');
	  proc_vorbis_comment_clear           := Windows.GetProcAddress(g_dllLoad_vorbis, 'vorbis_comment_clear');
	  proc_vorbis_comment_init            := Windows.GetProcAddress(g_dllLoad_vorbis, 'vorbis_comment_init');
	  proc_vorbis_comment_query           := Windows.GetProcAddress(g_dllLoad_vorbis, 'vorbis_comment_query');
	  proc_vorbis_comment_query_count     := Windows.GetProcAddress(g_dllLoad_vorbis, 'vorbis_comment_query_count');
	  proc_vorbis_commentheader_out       := Windows.GetProcAddress(g_dllLoad_vorbis, 'vorbis_commentheader_out');
	  proc_vorbis_dsp_clear               := Windows.GetProcAddress(g_dllLoad_vorbis, 'vorbis_dsp_clear');
	  proc_vorbis_encode_setup_init       := Windows.GetProcAddress(g_dllLoad_vorbis, 'vorbis_encode_setup_init');
	  proc_vorbis_encode_setup_managed    := Windows.GetProcAddress(g_dllLoad_vorbis, 'vorbis_encode_setup_managed');
	  proc_vorbis_encode_setup_vbr        := Windows.GetProcAddress(g_dllLoad_vorbis, 'vorbis_encode_setup_vbr');
	  proc_vorbis_info_blocksize          := Windows.GetProcAddress(g_dllLoad_vorbis, 'vorbis_info_blocksize');
	  proc_vorbis_info_clear              := Windows.GetProcAddress(g_dllLoad_vorbis, 'vorbis_info_clear');
	  proc_vorbis_info_init               := Windows.GetProcAddress(g_dllLoad_vorbis, 'vorbis_info_init');
	  proc_vorbis_packet_blocksize        := Windows.GetProcAddress(g_dllLoad_vorbis, 'vorbis_packet_blocksize');
	  proc_vorbis_synthesis               := Windows.GetProcAddress(g_dllLoad_vorbis, 'vorbis_synthesis');
	  proc_vorbis_synthesis_blockin       := Windows.GetProcAddress(g_dllLoad_vorbis, 'vorbis_synthesis_blockin');
	  proc_vorbis_synthesis_headerin      := Windows.GetProcAddress(g_dllLoad_vorbis, 'vorbis_synthesis_headerin');
	  proc_vorbis_synthesis_init          := Windows.GetProcAddress(g_dllLoad_vorbis, 'vorbis_synthesis_init');
	  proc_vorbis_synthesis_pcmout        := Windows.GetProcAddress(g_dllLoad_vorbis, 'vorbis_synthesis_pcmout');
	  proc_vorbis_synthesis_read          := Windows.GetProcAddress(g_dllLoad_vorbis, 'vorbis_synthesis_read');
	  proc_vorbis_synthesis_trackonly     := Windows.GetProcAddress(g_dllLoad_vorbis, 'vorbis_synthesis_trackonly');
	  //
	  if (assigned(proc_vorbis_analysis) and
	      assigned(proc_vorbis_analysis) and
	      assigned(proc_vorbis_analysis_blockout) and
	      assigned(proc_vorbis_analysis_buffer) and
	      assigned(proc_vorbis_analysis_headerout) and
	      assigned(proc_vorbis_analysis_init) and
	      assigned(proc_vorbis_analysis_wrote) and
	      assigned(proc_vorbis_bitrate_addblock) and
	      assigned(proc_vorbis_bitrate_flushpacket) and
	      assigned(proc_vorbis_block_clear) and
	      assigned(proc_vorbis_block_init) and
	      assigned(proc_vorbis_comment_add) and
	      assigned(proc_vorbis_comment_add_tag) and
	      assigned(proc_vorbis_comment_clear) and
	      assigned(proc_vorbis_comment_init) and
	      assigned(proc_vorbis_comment_query) and
	      assigned(proc_vorbis_comment_query_count) and
	      assigned(proc_vorbis_commentheader_out) and
	      assigned(proc_vorbis_dsp_clear) and
	      assigned(proc_vorbis_encode_setup_init) and
	      assigned(proc_vorbis_encode_setup_managed) and
	      assigned(proc_vorbis_encode_setup_vbr) and
	      assigned(proc_vorbis_info_blocksize) and
	      assigned(proc_vorbis_info_clear) and
	      assigned(proc_vorbis_info_init) and
	      assigned(proc_vorbis_packet_blocksize) and
	      assigned(proc_vorbis_synthesis) and
	      assigned(proc_vorbis_synthesis_blockin) and
	      assigned(proc_vorbis_synthesis_headerin) and
	      assigned(proc_vorbis_synthesis_init) and
	      assigned(proc_vorbis_synthesis_pcmout) and
	      assigned(proc_vorbis_synthesis_read) and
	      assigned(proc_vorbis_synthesis_trackonly)
	     ) then
	    g_dllLoad_vorbis_refCount := 1
	  else begin
	    Windows.FreeLibrary(g_dllLoad_vorbis);
	    g_dllLoad_vorbis_refCount := 0;
	  end
	end
	else
	  g_dllLoad_vorbis_refCount := 0;
      end
      else
	if (0 < g_dllLoad_vorbis_refCount) then
	  inc(g_dllLoad_vorbis_refCount);
      //
      result := (0 < g_dllLoad_vorbis_refCount);
    end;

    cunav_dll_vorbisenc: begin

      //-----------------------------//---------------------------------
      if (0 = g_dllLoad_vorbisenc_refCount) then begin
	g_dllLoad_vorbisenc_refCount := -1;
	//
	if ('' <> libraryName) then
	  g_dllLoad_vorbisenc := Windows.LoadLibraryA(pAnsiChar(AnsiString(libraryName)))
	else
	  g_dllLoad_vorbisenc := Windows.LoadLibraryA(c_dllName_vorbisenc);
	//
	if (0 <> g_dllLoad_vorbisenc) then begin
	  //
	  proc_vorbis_encode_init             := Windows.GetProcAddress(g_dllLoad_vorbisenc, 'vorbis_encode_init');
	  proc_vorbis_encode_init_vbr         := Windows.GetProcAddress(g_dllLoad_vorbisenc, 'vorbis_encode_init_vbr');
	  proc_vorbis_encode_ctl              := Windows.GetProcAddress(g_dllLoad_vorbisenc, 'vorbis_encode_ctl');
	  if (assigned(proc_vorbis_encode_init) and
	      assigned(proc_vorbis_encode_init_vbr) and
	      assigned(proc_vorbis_encode_ctl)
	     ) then
	    g_dllLoad_vorbisenc_refCount := 1
	  else begin
	    Windows.FreeLibrary(g_dllLoad_vorbisenc);
	    g_dllLoad_vorbisenc_refCount := 0;
	  end
	end
	else
	  g_dllLoad_vorbisenc_refCount := 0;
      end
      else
	if (0 < g_dllLoad_vorbisenc_refCount) then
	  inc(g_dllLoad_vorbisenc_refCount);
      //
      result := (0 < g_dllLoad_vorbisenc_refCount);
    end;

    cunav_dll_vorbisfile: begin
      //-----------------------------//-----------------------------------
      if (0 = g_dllLoad_vorbisfile_refCount) then begin
	g_dllLoad_vorbisfile_refCount := -1;
	//
	if ('' <> libraryName) then
	  g_dllLoad_vorbisfile := Windows.LoadLibraryA(pAnsiChar(AnsiString(libraryName)))
	else
	  g_dllLoad_vorbisfile := Windows.LoadLibraryA(c_dllName_vorbisfile);
	//
	if (0 <> g_dllLoad_vorbisfile) then begin
	  //
	  proc_ov_bitrate                     := Windows.GetProcAddress(g_dllLoad_vorbisfile, 'ov_bitrate');
	  proc_ov_bitrate_instant             := Windows.GetProcAddress(g_dllLoad_vorbisfile, 'ov_bitrate_instant');
	  proc_ov_clear                       := Windows.GetProcAddress(g_dllLoad_vorbisfile, 'ov_clear');
	  proc_ov_comment                     := Windows.GetProcAddress(g_dllLoad_vorbisfile, 'ov_comment');
	  proc_ov_info                        := Windows.GetProcAddress(g_dllLoad_vorbisfile, 'ov_info');
	  proc_ov_open                        := Windows.GetProcAddress(g_dllLoad_vorbisfile, 'ov_open');
	  proc_ov_open_callbacks              := Windows.GetProcAddress(g_dllLoad_vorbisfile, 'ov_open_callbacks');
	  proc_ov_pcm_seek                    := Windows.GetProcAddress(g_dllLoad_vorbisfile, 'ov_pcm_seek');
	  proc_ov_pcm_seek_page               := Windows.GetProcAddress(g_dllLoad_vorbisfile, 'ov_pcm_seek_page');
	  proc_ov_pcm_tell                    := Windows.GetProcAddress(g_dllLoad_vorbisfile, 'ov_pcm_tell');
	  proc_ov_pcm_total                   := Windows.GetProcAddress(g_dllLoad_vorbisfile, 'ov_pcm_total');
	  proc_ov_raw_seek                    := Windows.GetProcAddress(g_dllLoad_vorbisfile, 'ov_raw_seek');
	  proc_ov_raw_tell                    := Windows.GetProcAddress(g_dllLoad_vorbisfile, 'ov_raw_tell');
	  proc_ov_raw_total                   := Windows.GetProcAddress(g_dllLoad_vorbisfile, 'ov_raw_total');
	  proc_ov_read                        := Windows.GetProcAddress(g_dllLoad_vorbisfile, 'ov_read');
	  proc_ov_seekable                    := Windows.GetProcAddress(g_dllLoad_vorbisfile, 'ov_seekable');
	  proc_ov_serialnumber                := Windows.GetProcAddress(g_dllLoad_vorbisfile, 'ov_serialnumber');
	  proc_ov_streams                     := Windows.GetProcAddress(g_dllLoad_vorbisfile, 'ov_streams');
	  proc_ov_test                        := Windows.GetProcAddress(g_dllLoad_vorbisfile, 'ov_test');
	  proc_ov_test_callbacks              := Windows.GetProcAddress(g_dllLoad_vorbisfile, 'ov_test_callbacks');
	  proc_ov_test_open                   := Windows.GetProcAddress(g_dllLoad_vorbisfile, 'ov_test_open');
	  proc_ov_time_seek                   := Windows.GetProcAddress(g_dllLoad_vorbisfile, 'ov_time_seek');
	  proc_ov_time_seek_page              := Windows.GetProcAddress(g_dllLoad_vorbisfile, 'ov_time_seek_page');
	  proc_ov_time_tell                   := Windows.GetProcAddress(g_dllLoad_vorbisfile, 'ov_time_tell');
	  proc_ov_time_total                  := Windows.GetProcAddress(g_dllLoad_vorbisfile, 'ov_time_total');
	  proc_ov_read_float                  := Windows.GetProcAddress(g_dllLoad_vorbisfile, 'ov_read_float');
	  //
	  if (assigned(proc_ov_bitrate) and
	      assigned(proc_ov_bitrate_instant) and
	      assigned(proc_ov_clear) and
	      assigned(proc_ov_comment) and
	      assigned(proc_ov_info) and
	      assigned(proc_ov_open) and
	      assigned(proc_ov_open_callbacks) and
	      assigned(proc_ov_pcm_seek) and
	      assigned(proc_ov_pcm_seek_page) and
	      assigned(proc_ov_pcm_tell) and
	      assigned(proc_ov_pcm_total) and
	      assigned(proc_ov_raw_seek) and
	      assigned(proc_ov_raw_tell) and
	      assigned(proc_ov_raw_total) and
	      assigned(proc_ov_read) and
	      assigned(proc_ov_seekable) and
	      assigned(proc_ov_serialnumber) and
	      assigned(proc_ov_streams) and
	      assigned(proc_ov_test) and
	      assigned(proc_ov_test_callbacks) and
	      assigned(proc_ov_test_open) and
	      assigned(proc_ov_time_seek) and
	      assigned(proc_ov_time_seek_page) and
	      assigned(proc_ov_time_tell) and
	      assigned(proc_ov_time_total) and
	      true{assigned(proc_ov_read_float)}
	     ) then
	    g_dllLoad_vorbisfile_refCount := 1
	  else begin
	    Windows.FreeLibrary(g_dllLoad_vorbisfile);
	    g_dllLoad_vorbisfile_refCount := 0;
	  end
	end
	else
	  //
	  g_dllLoad_vorbisfile_refCount := 0;
      end
      else
	if (0 < g_dllLoad_vorbisfile_refCount) then
	  inc(g_dllLoad_vorbisfile_refCount);
      //
      result := (0 < g_dllLoad_vorbisfile_refCount);
    end;

    else
      result := false;

  end;
end;

// --  --
procedure vorbis_unload_library(libraryToUnload: int);
begin
  case (libraryToUnload) of

    cunav_dll_ogg: begin
      // --  --
      if (0 < g_dllLoad_ogg_refCount) then begin
	//
	dec(g_dllLoad_ogg_refCount);
	if (1 > g_dllLoad_ogg_refCount) then begin
	  //
	  g_dllLoad_ogg_refCount := -2;
	  FreeLibrary(g_dllLoad_ogg);
	  g_dllLoad_ogg_refCount := 0;
	end;
      end;
    end;

    cunav_dll_vorbis: begin
      // --  --
      if (0 < g_dllLoad_vorbis_refCount) then begin
	//
	dec(g_dllLoad_vorbis_refCount);
	if (1 > g_dllLoad_vorbis_refCount) then begin
	  //
	  g_dllLoad_vorbis_refCount := -2;
	  FreeLibrary(g_dllLoad_vorbis);
	  g_dllLoad_vorbis_refCount := 0;
	end;
      end;
    end;

    cunav_dll_vorbisenc: begin
      // --  --
      if (0 < g_dllLoad_vorbisenc_refCount) then begin
	//
	dec(g_dllLoad_vorbisenc_refCount);
	if (1 > g_dllLoad_vorbisenc_refCount) then begin
	  //
	  g_dllLoad_vorbisenc_refCount := -2;
	  FreeLibrary(g_dllLoad_vorbisenc);
	  g_dllLoad_vorbisenc_refCount := 0;
	end;
      end;
    end;

    cunav_dll_vorbisfile: begin
      // --  --
      if (0 < g_dllLoad_vorbisfile_refCount) then begin
	//
	dec(g_dllLoad_vorbisfile_refCount);
	if (1 > g_dllLoad_vorbisfile_refCount) then begin
	  //
	  g_dllLoad_vorbisfile_refCount := -2;
	  FreeLibrary(g_dllLoad_vorbisfile);
	  g_dllLoad_vorbisfile_refCount := 0;
	end;
      end;
    end;
  end;
end;

{$ENDIF VC_LIBVORBIS_ONLY }


// -- libvorbis.dll --

// --  --
function loadLibvorbis(var api: tLibvorbisAPI; const libname: wString): int;
var
  libFile: wString;
begin
  with api do begin
    //
    if (0 = r_module) then begin
      //
      r_module := 1;	// not zero
      //
      libFile := trimS(libname);
      if ('' = libFile) then
	libFile := c_libvorbis_name;
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
	r_vorbis_block_clear	:= GetProcAddress(r_module, 'vorbis_block_clear');
	r_vorbis_block_init	:= GetProcAddress(r_module, 'vorbis_block_init');
	r_vorbis_dsp_clear	:= GetProcAddress(r_module, 'vorbis_dsp_clear');
	r_vorbis_granule_time	:= GetProcAddress(r_module, 'vorbis_granule_time');
	r_vorbis_info_blocksize	:= GetProcAddress(r_module, 'vorbis_info_blocksize');
	r_vorbis_info_clear	:= GetProcAddress(r_module, 'vorbis_info_clear');
	r_vorbis_info_init	:= GetProcAddress(r_module, 'vorbis_info_init');
	//r_vorbis_version_string	:= GetProcAddress(r_module, 'vorbis_version_string');
	// Decoding
	r_vorbis_packet_blocksize     := GetProcAddress(r_module, 'vorbis_packet_blocksize');
	r_vorbis_synthesis            := GetProcAddress(r_module, 'vorbis_synthesis');
	r_vorbis_synthesis_blockin    := GetProcAddress(r_module, 'vorbis_synthesis_blockin');
	r_vorbis_synthesis_halfrate   := GetProcAddress(r_module, 'vorbis_synthesis_halfrate');
	r_vorbis_synthesis_halfrate_p := GetProcAddress(r_module, 'vorbis_synthesis_halfrate_p');
	r_vorbis_synthesis_headerin   := GetProcAddress(r_module, 'vorbis_synthesis_headerin');
	//r_vorbis_synthesis_idheader   := GetProcAddress(r_module, 'vorbis_synthesis_idheader');
	r_vorbis_synthesis_init       := GetProcAddress(r_module, 'vorbis_synthesis_init');
	r_vorbis_synthesis_lapout     := GetProcAddress(r_module, 'vorbis_synthesis_lapout');
	r_vorbis_synthesis_pcmout     := GetProcAddress(r_module, 'vorbis_synthesis_pcmout');
	r_vorbis_synthesis_read       := GetProcAddress(r_module, 'vorbis_synthesis_read');
	r_vorbis_synthesis_restart    := GetProcAddress(r_module, 'vorbis_synthesis_restart');
	r_vorbis_synthesis_trackonly  := GetProcAddress(r_module, 'vorbis_synthesis_trackonly');
	// Encoding
	r_vorbis_analysis             := GetProcAddress(r_module, 'vorbis_analysis');
	r_vorbis_analysis_blockout    := GetProcAddress(r_module, 'vorbis_analysis_blockout');
	r_vorbis_analysis_buffer      := GetProcAddress(r_module, 'vorbis_analysis_buffer');
	r_vorbis_analysis_headerout   := GetProcAddress(r_module, 'vorbis_analysis_headerout');
	r_vorbis_analysis_init        := GetProcAddress(r_module, 'vorbis_analysis_init');
	r_vorbis_analysis_wrote       := GetProcAddress(r_module, 'vorbis_analysis_wrote');
	r_vorbis_bitrate_addblock     := GetProcAddress(r_module, 'vorbis_bitrate_addblock');
	r_vorbis_bitrate_flushpacket  := GetProcAddress(r_module, 'vorbis_bitrate_flushpacket');
	// Metadata
	r_vorbis_comment_add          := GetProcAddress(r_module, 'vorbis_comment_add');
	r_vorbis_comment_add_tag      := GetProcAddress(r_module, 'vorbis_comment_add_tag');
	r_vorbis_comment_clear        := GetProcAddress(r_module, 'vorbis_comment_clear');
	r_vorbis_comment_init         := GetProcAddress(r_module, 'vorbis_comment_init');
	r_vorbis_comment_query        := GetProcAddress(r_module, 'vorbis_comment_query');
	r_vorbis_comment_query_count  := GetProcAddress(r_module, 'vorbis_comment_query_count');
	r_vorbis_commentheader_out    := GetProcAddress(r_module, 'vorbis_commentheader_out');
	//
	r_refCount := 1;	// also, makes it non-zero (see below mscand)
	if (nil <> mscanp(@api, nil, sizeof(tLibvorbisAPI))) then begin
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
      if (0 < r_refCount) then
	inc(r_refCount);
      //
      result := 0;
    end;
  end;
end;

// --  --
procedure unloadLibvorbis(var api: tLibvorbisAPI);
begin
  with api do begin
    //
    if (0 <> r_module) then begin
      //
      if (0 < r_refCount) then
	dec(r_refCount);
      //
      if (1 > r_refCount) then begin
	//
	FreeLibrary(r_module);
	fillChar(api, sizeof(tLibvorbisAPI), 0)
      end;
    end;
  end;
end;


{ unaLibvorbisCodec }

// --  --
procedure unaLibvorbisCoder.BeforeDestruction();
begin
  inherited;
  //
  unloadLibvorbis(f_api);
end;

// --  --
procedure unaLibvorbisCoder.close();
begin

end;

// --  --
constructor unaLibvorbisCoder.create(const libname: wString);
begin
  f_libOK := (0 = loadLibvorbis(f_api, libname));
  //
  inherited create();
end;

// --  --
function unaLibvorbisCoder.open(): int;
begin
  if (active) then
    result := f_lastError
  else
    result := doOpen();
end;


end.
