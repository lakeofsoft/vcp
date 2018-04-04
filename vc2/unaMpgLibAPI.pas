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

	  unaMpgLibAPI.pas
          Delphi wrapper for MpgLib.DLL and libmpg123-0.dll

	----------------------------------------------
	  Copyright (c) 2004-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 10 Feb 2004

	  modified by:
		Lake, Feb-Mar 2004
                Lake, Mar-Jun 2009

	----------------------------------------------
*)

{$I unaDef.inc}

{*
	Delphi wrapper for MpgLib.DLL and libmpg123-0.dll
}

unit
  unaMpgLibAPI;

interface

uses
  Windows, unaTypes, unaClasses;

// ------ common.c ------------

const
  tabsel_123: array[0..1, 0..2, 0..15] of unsigned = (
     (
       (0, 32, 64, 96, 128, 160, 192, 224, 256, 288, 320, 352, 384, 416, 448, 0),
       (0, 32, 48, 56,  64,  80,  96, 112, 128, 160, 192, 224, 256, 320, 384, 0),
       (0, 32, 40, 48,  56,  64,  80,  96, 112, 128, 160, 192, 224, 256, 320, 0)
     ),

     (
       (0, 32,48,56,64,80,96,112,128,144,160,176,192,224,256, 0),
       (0, 8, 16,24,32,40,48, 56, 64, 80, 96,112,128,144,160, 0),
       (0, 8, 16,24,32,40,48, 56, 64, 80, 96,112,128,144,160, 0)
     )
  );

  //
  freqs: array[0..8] of unsigned =
    (
      44100, 48000, 32000, 22050, 24000, 16000, 11025, 12000, 8000
    );


// -------------- mpg123.h --------------

const
  M_PI 		= 3.14159265358979323846;
  M_SQRT2 	= 1.41421356237309504880;

//* AUDIOBUFSIZE = n*64 with n=1,2,3 ...  */
  AUDIOBUFSIZE	= 16384;

  SBLIMIT	= 32;
  SSLIMIT       = 18;

  SCALE_BLOCK	= 12; //* Layer 2 */

  MPG_MD_STEREO           = 0;
  MPG_MD_JOINT_STEREO     = 1;
  MPG_MD_DUAL_CHANNEL     = 2;
  MPG_MD_MONO             = 3;

  MAXFRAMESIZE 		  = 1792;


type
  // --  --
  pfloat = ^double;


  // --  --
  pmpglib_frame = ^mpglib_frame;
  mpglib_frame  = packed record
    //
    stereo              : int;
    jsbound             : int;
    single              : int;
    lsf                 : int;
    mpeg25              : int;
    header_change       : int;
    lay                 : int;
    error_protection    : int;
    bitrate_index       : int;
    sampling_frequency	: int;
    padding             : int;
    extension           : int;
    mode                : int;
    mode_ext            : int;
    copyright           : int;
    original            : int;
    emphasis            : int;
    framesize  		: int;	//* computed framesize */

    //* AF: ADDED FOR LAYER1/LAYER2 */
    //#if defined(USE_LAYER_2) || defined(USE_LAYER_1)
    //
    II_sblimit:	int;
    //
    alloc: pointer;    // ^al_table2
    down_sample_sblimit: int;
    down_sample: int;
  end;


  // --  --
  pmpglib_gr_info_s = ^mpglib_gr_info_s;
  mpglib_gr_info_s = packed record
      //
      scfsi: int;
      part2_3_length:     unsigned;
      big_values:         unsigned;
      scalefac_compress:  unsigned;
      block_type:         unsigned;
      mixed_block_flag:   unsigned;
      table_select: array[0..2] of unsigned;
      subblock_gain: array[0..2] of unsigned;
      maxband: array[0..2] of unsigned;
      maxbandl:           unsigned;
      maxb:               unsigned;
      region1start:       unsigned;
      region2start:       unsigned;
      preflag:            unsigned;
      scalefac_scale:     unsigned;
      count1table_select: unsigned;
      //
      full_gain: array[0..2] of pfloat;
      pow2gain: pfloat;
  end;

  // --  --
  mpglib_gr_info_s2 = packed record
    gr: array[0..1] of mpglib_gr_info_s;
  end;

  // --  --
  pmpglib_III_sideinfo = ^mpglib_III_sideinfo;
  mpglib_III_sideinfo = packed record
    //
    main_data_begin: unsigned;
    private_bits: unsigned;

    //  struct {
    //    struct gr_info_s gr[2];
    //  } ch[2];
    //
    ch: array[0..1] of mpglib_gr_info_s2;
  end;



// --------- mpglib.h ---------------

{*
 * Mpeg Layer-3 audio decoder
 * --------------------------
 * copyright (c) 1995,1996,1997 by Michael Hipp.
 * All rights reserved. See also 'README'

  mpglib.dll (Win32) with source (LGPL)
  Version 0.92, November 2001
  Adapted from mpglib by Martin Pesch
  (http://www.rz.uni-frankfurt.de/~pesch)

  @Author Lake

  Version 2.5.2008.06 Delphi wrapper
}


//#include "lame-analysis.h"

//#ifndef NOANALYSIS
//extern plotting_data *mpg123_pinfo;
//#endif

type
  // -- buf --
  pmpglib_buf = ^mpglib_buf;
  mpglib_buf = packed record
    //
    pnt: pChar;
    size: int;
    pos: long;
    next: pmpglib_buf;
    prev: pmpglib_buf;
  end;


  // -- framebuf --
  pmpglib_framebuf = ^mpglib_framebuf;
  mpglib_framebuf = packed record
    //
    buf: pmpglib_buf;
    pos: int;
    next: pmpglib_frame;
    prev: pmpglib_frame;
  end;

  // --  --
  PMPSTR = ^MPSTR;
  MPSTR = packed record
    //
    head: pmpglib_buf;
    tail: pmpglib_buf;
    //
    //vbr_header: int;               //* 1 if valid Xing vbr header detected */
    //num_frames: int;               //* set if vbr header present */
    //enc_delay: int;                //* set if vbr header present */
    //enc_padding: int;              //* set if vbr header present */
    //header_parsed: int;
    //side_parsed: int;
    //data_parsed: int;
    //free_format: int;              //* 1 = free format frame */
    //old_free_format: int;          //* 1 = last frame was free format */
    bsize: int;
    framesize: int;
    //ssize: int;
    //dsize: int;
    fsizeold: int;
    //fsizeold_nopadding: int;
    fr: mpglib_frame;
    //
    //-- unsigned char bsspace[2][MAXFRAMESIZE+512]; //* MAXFRAMESIZE */
    bsspace: array[0..1, 0..MAXFRAMESIZE + 511] of byte;
    //
    //-- real hybrid_block[2][2][SBLIMIT*SSLIMIT];
    hybrid_block: array[0..1, 0..1, 0..SBLIMIT * SSLIMIT - 1] of double;
    //
    hybrid_blc: array[0..1] of int;
    header: unsigned;
    bsnum: int;
    //-- real synth_buffs[2][2][0x110];
    synth_buffs: array[0..1, 0..1, 0..$110-1] of double;
    //
    synth_bo: int;
    //sync_bitstream: int;
  end;


const
  // error codes

  MP3_OK	= 0;
  MP3_NEED_MORE	= 1;
  MP3_ERR	= -1;

  // additional

  mpglib_error_OK	= MP3_OK;
  mpglib_error_more	= MP3_NEED_MORE;
  mpglib_error_general	= MP3_ERR;
  //
  mpglib_error_noLib	= -10;
  mpglib_error_noProc	= -11;
  mpglib_error_initFail	= -12;



//    ------------
// -- mpg123.h.in --
//    ------------

{* \defgroup mpg123_init mpg123 library and handle setup
 *
 * Functions to initialise and shutdown the mpg123 library and handles.
 * The parameters of handles have workable defaults, you only have to tune them when you want to tune something;-)
 * Tip: Use a RVA setting...
 *
 * @{
*}

type
  intp		= int32;	// signed integer parameter
  uintp		= uint32;	// unsigned integer parameter
  offp		= intp;		// offset parameter or result code
  floatp	= double;	// float parameter
  ptrp		= pointer;	// pointer to buffer parameter
  iresult	= int32;	// signed integer result
  charp		= paChar;	// pointer to array of chars
  //
  pintp		= ^intp;	// pointer to signed integer parameter (which could be NULL)

{* Opaque structure for the libmpg123 decoder handle.
 *  Most functions take a pointer to a mpg123_handle as first argument and operate on its data in an object-oriented manner.
 *}
  pmpg123_handle = ^mpg123_handle;
  mpg123_handle = packed record end;

// -- prototypes --

{* Function to initialise the mpg123 library.
 *	This function is not thread-safe. Call it exactly once per process, before any other (possibly threaded) work with the library.
 *
 *	\return MPG123_OK if successful, otherwise an error number.
 *}
  proc_mpg123_init = function(): iresult; cdecl;

{* Function to close down the mpg123 library.
 *	This function is not thread-safe. Call it exactly once per process, before any other (possibly threaded) work with the library. *}
  proc_mpg123_exit = procedure(); cdecl;

{* Create a handle with optional choice of decoder (named by a string, see mpg123_decoders() or mpg123_supported_decoders()).
 *  and optional retrieval of an error code to feed to mpg123_plain_strerror().
 *  Optional means: Any of or both the parameters may be NULL.
 *
 *  \return Non-NULL pointer when successful.
 *}
  proc_mpg123_new = function(decoder: charp; error: pintp): pmpg123_handle; cdecl;

{* Delete handle, mh is either a valid mpg123 handle or NULL. *}
  proc_mpg123_delete = procedure(mh: pmpg123_handle); cdecl;


type
{* Enumeration of the parameters types that it is possible to set/get. *}
  mpg123_parms = intp;
const
  MPG123_VERBOSE 	= 0;    ///**< set verbosity value for enabling messages to stderr, >= 0 makes sense (integer) */
  MPG123_FLAGS		= 1;    ///**< set all flags, p.ex val = MPG123_GAPLESS|MPG123_MONO_MIX (integer) */
  MPG123_ADD_FLAGS	= 2;    ///**< add some flags (integer) */
  MPG123_FORCE_RATE	= 3;    ///**< when value > 0, force output rate to that value (integer) */
  MPG123_DOWN_SAMPLE	= 4;	///**< 0=native rate, 1=half rate, 2=quarter rate (integer) */
  MPG123_RVA		= 5;    ///**< one of the RVA choices above (integer) */
  MPG123_DOWNSPEED	= 6;    ///**< play a frame N times (integer) */
  MPG123_UPSPEED	= 7;    ///**< play every Nth frame (integer) */
  MPG123_START_FRAME	= 8;    ///**< start with this frame (skip frames before that, integer) */
  MPG123_DECODE_FRAMES	= 9;    ///**< decode only this number of frames (integer) */
  MPG123_ICY_INTERVAL	= 10;   ///**< stream contains ICY metadata with this interval (integer) */
  MPG123_OUTSCALE	= 11;   ///**< the scale for output samples (amplitude - integer or float according to mpg123 output format, normally integer) */
  MPG123_TIMEOUT	= 12;   ///**< timeout for reading from a stream (not supported on win32, integer) */
  MPG123_REMOVE_FLAGS	= 13;   ///**< remove some flags (inverse of MPG123_ADD_FLAGS, integer) */
  MPG123_RESYNC_LIMIT	= 14;   ///**< Try resync on frame parsing for that many bytes or until end of stream (<0 ... integer). */
  MPG123_INDEX_SIZE	= 15;   ///**< Set the frame index size (if supported). Values <0 mean that the index is allowed to grow dynamically in these steps (in positive direction, of course) -- Use this when you really want a full index with every individual frame. */


type
{* Flag bits for MPG123_FLAGS, use the usual binary or to combine. *}
  mpg123_param_flags = intp;
const
  MPG123_FORCE_MONO   = $7;  	///**<     0111 Force some mono mode: This is a test bitmask for seeing if any mono forcing is active. */
  MPG123_MONO_LEFT    = $1;  	///**<     0001 Force playback of left channel only.  */
  MPG123_MONO_RIGHT   = $2;  	///**<     0010 Force playback of right channel only. */
  MPG123_MONO_MIX     = $4;  	///**<     0100 Force playback of mixed mono.         */
  MPG123_FORCE_STEREO = $8;  	///**<     1000 Force stereo output.                  */
  MPG123_FORCE_8BIT   = $10; 	///**< 00010000 Force 8bit formats.                   */
  MPG123_QUIET        = $20; 	///**< 00100000 Suppress any printouts (overrules verbose).                    */
  MPG123_GAPLESS      = $40; 	///**< 01000000 Enable gapless decoding (default on if libmpg123 has support). */
  MPG123_NO_RESYNC    = $80; 	///**< 10000000 Disable resync stream after error.                             */
  MPG123_SEEKBUFFER   = $100; 	///**< 000100000000 Enable small buffer on non-seekable streams to allow some peek-ahead (for better MPEG sync). */
  MPG123_FUZZY        = $200; 	///**< 001000000000 Enable fuzzy seeks (guessing byte offsets or using approximate seek points from Xing TOC) */


type
{* choices for MPG123_RVA *}
  mpg123_param_rva	= intp;
const
  MPG123_RVA_OFF   = 0; 		///**< RVA disabled (default).   */
  MPG123_RVA_MIX   = 1; 		///**< Use mix/track/radio gain. */
  MPG123_RVA_ALBUM = 2; 		///**< Use album/audiophile gain */
  MPG123_RVA_MAX   = MPG123_RVA_ALBUM;	///**< The maximum RVA code, may increase in future. */

{* TODO: Assess the possibilities and troubles of changing parameters during playback. *}

type
{* Set a specific parameter, for a specific mpg123_handle, using a parameter
 *  type key chosen from the mpg123_parms enumeration, to the specified value. */}
  proc_mpg123_param = function(mh: pmpg123_handle; _type: mpg123_parms; value: intp; fvalue: floatp): iresult; cdecl;

{* Get a specific parameter, for a specific mpg123_handle.
 *  See the mpg123_parms enumeration for a list of available parameters. *}
  proc_mpg123_getparam = function(mh: pmpg123_handle; _type: mpg123_parms; var val: intp; var fval: floatp): iresult; cdecl;



{* \defgroup mpg123_error mpg123 error handling
 *
 * Functions to get text version of the error numbers and an enumeration
 * of the error codes returned by libmpg123.
 *
 * Most functions operating on a mpg123_handle simply return MPG123_OK on success and MPG123_ERR on failure (setting the internal error variable of the handle to the specific error code).
 * Decoding/seek functions may also return message codes MPG123_DONE, MPG123_NEW_FORMAT and MPG123_NEED_MORE.
 * The positive range of return values is used for "useful" values when appropriate.
 *
 * @{
 *}

{* Enumeration of the message and error codes and returned by libmpg123 functions. *}
  mpg123_errors = intp;
const
  MPG123_DONE			= -12;	///**< Message: Track ended. */
  MPG123_NEW_FORMAT		= -11;	///**< Message: Output format will be different on next call. */
  MPG123_NEED_MORE		= -10;	///**< Message: For feed reader: "Feed me more!" */
  MPG123_ERR			= -1;	///**< Generic Error */
  MPG123_OK			= 0;	///**< Success */
  MPG123_BAD_OUTFORMAT		= 1;	///**< Unable to set up output format! */
  MPG123_BAD_CHANNEL		= 2;    ///**< Invalid channel number specified. */
  MPG123_BAD_RATE		= 3;	///**< Invalid sample rate specified.  */
  MPG123_ERR_16TO8TABLE		= 4;	///**< Unable to allocate memory for 16 to 8 converter table! */
  MPG123_BAD_PARAM		= 5;	///**< Bad parameter id! */
  MPG123_BAD_BUFFER		= 6;	///**< Bad buffer given -- invalid pointer or too small size. */
  MPG123_OUT_OF_MEM		= 7;	///**< Out of memory -- some malloc() failed. */
  MPG123_NOT_INITIALIZED	= 8;	///**< You didn't initialize the library! */
  MPG123_BAD_DECODER		= 9;	///**< Invalid decoder choice. */
  MPG123_BAD_HANDLE		= 10;	///**< Invalid mpg123 handle. */
  MPG123_NO_BUFFERS		= 11;	///**< Unable to initialize frame buffers (out of memory?). */
  MPG123_BAD_RVA		= 12;	///**< Invalid RVA mode. */
  MPG123_NO_GAPLESS		= 13;	///**< This build doesn't support gapless decoding. */
  MPG123_NO_SPACE		= 14;	///**< Not enough buffer space. */
  MPG123_BAD_TYPES		= 15;	///**< Incompatible numeric data types. */
  MPG123_BAD_BAND		= 16;	///**< Bad equalizer band. */
  MPG123_ERR_NULL		= 17;	///**< Null pointer given where valid storage address needed. */
  MPG123_ERR_READER		= 18;	///**< Error reading the stream. */
  MPG123_NO_SEEK_FROM_END	= 19;	///**< Cannot seek from end (end is not known). */
  MPG123_BAD_WHENCE		= 20;	///**< Invalid 'whence' for seek function.*/
  MPG123_NO_TIMEOUT		= 21;	///**< Build does not support stream timeouts. */
  MPG123_BAD_FILE		= 22;	///**< File access error. */
  MPG123_NO_SEEK		= 23;	///**< Seek not supported by stream. */
  MPG123_NO_READER		= 24;	///**< No stream opened. */
  MPG123_BAD_PARS		= 25;	///**< Bad parameter handle. */
  MPG123_BAD_INDEX_PAR		= 26;	///**< Bad parameters to mpg123_index() */
  MPG123_OUT_OF_SYNC		= 27;	///**< Lost track in bytestream and did not try to resync. */
  MPG123_RESYNC_FAIL		= 28;	///**< Resync failed to find valid MPEG data. */
  MPG123_NO_8BIT		= 29;	///**< No 8bit encoding possible. */
  MPG123_BAD_ALIGN		= 30;	///**< Stack aligmnent error */
  MPG123_NULL_BUFFER		= 31;	///**< NULL input buffer with non-zero size... */
  MPG123_NO_RELSEEK		= 32;	///**< Relative seek not possible (screwed up file offset) */
  MPG123_NULL_POINTER		= 33;	///**< You gave a null pointer somewhere where you shouldn't have. */
  MPG123_BAD_KEY		= 34;	///**< Bad key value given. */
  MPG123_NO_INDEX		= 35;	///**< No frame index in this build. */
  MPG123_INDEX_FAIL		= 36;	///**< Something with frame index went wrong. */

type
{* Return a string describing that error errcode means. *}
  proc_mpg123_plain_strerror = function(errcode: intp): charp; cdecl;

{* Give string describing what error has occured in the context of handle mh.
 *  When a function operating on an mpg123 handle returns MPG123_ERR, you should check for the actual reason via
 *  char *errmsg = mpg123_strerror(mh)
 *  This function will catch mh == NULL and return the message for MPG123_BAD_HANDLE. *}
  proc_mpg123_strerror = function(mh: pmpg123_handle): charp; cdecl;

{* Return the plain errcode intead of a string. *}
  proc_mpg123_errcode = function(mh: pmpg123_handle): iresult; cdecl;



type
{* \defgroup mpg123_decoder mpg123 decoder selection
 *
 * Functions to list and select the available decoders.
 * Perhaps the most prominent feature of mpg123: You have several (optimized) decoders to choose from (on x86 and PPC (MacOS) systems, that is).
 *
 * @{
 *}
  charpp = ^charp;

{* Return a NULL-terminated array of generally available decoder names (plain 8bit ASCII). *}
  proc_mpg123_decoders = function(): charpp; cdecl;

{* Return a NULL-terminated array of the decoders supported by the CPU (plain 8bit ASCII). *}
  proc_mpg123_supported_decoders = function(): charpp; cdecl;

{* Set the chosen decoder to 'decoder_name' *}
  proc_mpg123_decoder = function(mh: pmpg123_handle; decoder_name: charp): iresult; cdecl;



{* \defgroup mpg123_output mpg123 output audio format
 *
 * Functions to get and select the format of the decoded audio.
 *
 * @{
 *}

type
{* 16 or 8 bits, signed or unsigned... all flags fit into 15 bits and are designed to have meaningful binary AND/OR.
 * Adding float and 32bit int definitions for experimental fun. Only 32bit (and possibly 64bit) float is
 * somewhat there with a dedicated library build. *}
  mpg123_enc_enum = intp;
const
  MPG123_ENC_8      		= $00f;  ///**< 0000 0000 1111 Some 8 bit  integer encoding. */
  MPG123_ENC_16     		= $040;  ///**< 0000 0100 0000 Some 16 bit integer encoding. */
  MPG123_ENC_32     		= $100;  ///**< 0001 0000 0000 Some 32 bit integer encoding. */
  MPG123_ENC_SIGNED 		= $080;  ///**< 0000 1000 0000 Some signed integer encoding. */
  MPG123_ENC_FLOAT  		= $800;  ///**< 1110 0000 0000 Some float encoding. */
  //
  MPG123_ENC_SIGNED_16   	= MPG123_ENC_16 or MPG123_ENC_SIGNED or $10; 	///**< 0000 1101 0000 signed 16 bit */
  MPG123_ENC_UNSIGNED_16	= MPG123_ENC_16 or $20;                   	///**< 0000 0110 0000 unsigned 16 bit*/
  MPG123_ENC_UNSIGNED_8  	= $01;                                   	///**< 0000 0000 0001 unsigned 8 bit*/
  MPG123_ENC_SIGNED_8    	= MPG123_ENC_SIGNED or $02;               	///**< 0000 1000 0010 signed 8 bit*/
  MPG123_ENC_ULAW_8      	= $04;                                   	///**< 0000 0000 0100 ulaw 8 bit*/
  MPG123_ENC_ALAW_8      	= $08;                                   	///**< 0000 0000 1000 alaw 8 bit */
  MPG123_ENC_SIGNED_32   	= MPG123_ENC_32 or MPG123_ENC_SIGNED or $10;   	///**< 0001 1001 0000 signed 32 bit */
  MPG123_ENC_UNSIGNED_32 	= MPG123_ENC_32 or $20;                     	///**< 0001 0010 0000 unsigned 32 bit */
  MPG123_ENC_FLOAT_32    	= $200;                                  	///**< 0010 0000 0000 32bit float */
  MPG123_ENC_FLOAT_64    	= $400;                                  	///**< 0100 0000 0000 64bit float */
  MPG123_ENC_ANY 		=  MPG123_ENC_SIGNED_16  or MPG123_ENC_UNSIGNED_16 or MPG123_ENC_UNSIGNED_8
				or MPG123_ENC_SIGNED_8   or MPG123_ENC_ULAW_8      or MPG123_ENC_ALAW_8
				or MPG123_ENC_FLOAT_32   or MPG123_ENC_FLOAT_64;	///**< any encoding */


type
{* They can be combined into one number (3) to indicate mono and stereo... *}
  mpg123_channelcount = intp;
const
  MPG123_MONO   = 1;
  MPG123_STEREO = 2;


type
{* An array of supported standard sample rates
 *  These are possible native sample rates of MPEG audio files.
 *  You can still force mpg123 to resample to a different one, but by default you will only get audio in one of these samplings.
 *  \param list Store a pointer to the sample rates array there.
 *  \param number Store the number of sample rates there. *}
  proc_mpg123_rates = procedure(var list: pInt32; var number: uintp); cdecl;

{* An array of supported audio encodings.
 *  An audio encoding is one of the fully qualified members of mpg123_enc_enum (MPG123_ENC_SIGNED_16, not MPG123_SIGNED).
 *  \param list Store a pointer to the encodings array there.
 *  \param number Store the number of encodings there. *}
  proc_mpg123_encodings = procedure(var list: pInt32; var number: uintp); cdecl;

{* Configure a mpg123 handle to accept no output format at all,
 *  use before specifying supported formats with mpg123_format *}
  proc_mpg123_format_none = function(mh: pmpg123_handle): iresult; cdecl;

{* Configure mpg123 handle to accept all formats
 *  (also any custom rate you may set) -- this is default. *}
  proc_mpg123_format_all = function(mh: pmpg123_handle): iresult; cdecl;

{* Set the audio format support of a mpg123_handle in detail:
 *  \param mh audio decoder handle
 *  \param rate The sample rate value (in Hertz).
 *  \param channels A combination of MPG123_STEREO and MPG123_MONO.
 *  \param encodings A combination of accepted encodings for rate and channels, p.ex MPG123_ENC_SIGNED16 | MPG123_ENC_ULAW_8 (or 0 for no support). Please note that some encodings may not be supported in the library build and thus will be ignored here.
 *  \return MPG123_OK on success, MPG123_ERR if there was an error. *}
  proc_mpg123_format = function(mh: pmpg123_handle; rate: intp; channels: intp; encodings: intp): iresult; cdecl;

{* Check to see if a specific format at a specific rate is supported
 *  by mpg123_handle.
 *  \return 0 for no support (that includes invalid parameters), MPG123_STEREO,
 *          MPG123_MONO or MPG123_STEREO|MPG123_MONO. *}
  proc_mpg123_format_support = function(mh: pmpg123_handle; rate: intp; encoding: intp): iresult; cdecl;

{* Get the current output format written to the addresses givenr. *}
  proc_mpg123_getformat = function(mh: pmpg123_handle; var rate: intp; var channels: intp; var encoding: intp): iresult; cdecl;



{* \defgroup mpg123_input mpg123 file input and decoding
 *
 * Functions for input bitstream and decoding operations.
 *
 * @{
 *}

{* reading samples / triggering decoding, possible return values: *}
{* Enumeration of the error codes returned by libmpg123 functions. *}

{* Open and prepare to decode the specified file by filesystem path.
 *  This does not open HTTP urls; libmpg123 contains no networking code.
 *  If you want to decode internet streams, use mpg123_open_fd() or mpg123_open_feed().
 *}
  proc_mpg123_open = function(mh: pmpg123_handle; path: charp): iresult; cdecl;

{* Use an already opened file descriptor as the bitstream input
 *  mpg123_close() will _not_ close the file descriptor.
 *}
  proc_mpg123_open_fd = function(mh: pmpg123_handle; fd: intp): iresult; cdecl;

{* Open a new bitstream and prepare for direct feeding
 *  This works together with mpg123_decode(); you are responsible for reading and feeding the input bitstream.
 *}
  proc_mpg123_open_feed = function(mh: pmpg123_handle): iresult; cdecl;

{* Closes the source, if libmpg123 opened it. *}
  proc_mpg123_close = function(mh: pmpg123_handle): iresult; cdecl;

{* Read from stream and decode up to outmemsize bytes.
 *  \param outmemory address of output buffer to write to
 *  \param outmemsize maximum number of bytes to write
 *  \param done address to store the number of actually decoded bytes to
 *  \return error/message code (watch out for MPG123_DONE and friends!) *}
  proc_mpg123_read = function(mh: pmpg123_handle; outmemory: ptrp; outmemsize: uintp; var done: uintp): iresult; cdecl;

{* Feed data for a stream that has been opened with mpg123_open_feed().
 *  It's give and take: You provide the bytestream, mpg123 gives you the decoded samples.
 *  \param in input buffer
 *  \param size number of input bytes
 *  \return error/message code. *}
  proc_mpg123_feed = function(mh: pmpg123_handle; _in: ptrp; size: uintp): iresult; cdecl;

{* Decode MPEG Audio from inmemory to outmemory.
 *  This is very close to a drop-in replacement for old mpglib.
 *  When you give zero-sized output buffer the input will be parsed until
 *  decoded data is available. This enables you to get MPG123_NEW_FORMAT (and query it)
 *  without taking decoded data.
 *  Think of this function being the union of mpg123_read() and mpg123_feed() (which it actually is, sort of;-).
 *  You can actually always decide if you want those specialized functions in separate steps or one call this one here.
 *  \param inmemory input buffer
 *  \param inmemsize number of input bytes
 *  \param outmemory output buffer
 *  \param outmemsize maximum number of output bytes
 *  \param done address to store the number of actually decoded bytes to
 *  \return error/message code (watch out especially for MPG123_NEED_MORE)
 *}
  proc_mpg123_decode = function(mh: pmpg123_handle; inmemory: ptrp; inmemsize: uintp;
			 outmemory: ptrp; outmemsize: uintp; var done: uintp): iresult; cdecl;

{* Decode next MPEG frame to internal buffer
 *  or read a frame and return after setting a new format.
 *  \param num current frame offset gets stored there
 *  \param audio This pointer is set to the internal buffer to read the decoded audio from.
 *  \param bytes number of output bytes ready in the buffer
 *}
  proc_mpg123_decode_frame = function(mh: pmpg123_handle; var num: offp; var audio: ptrp; var bytes: uintp): iresult; cdecl;


{* \defgroup mpg123_seek mpg123 position and seeking
 *
 * Functions querying and manipulating position in the decoded audio bitstream.
 * The position is measured in decoded audio samples, or MPEG frame offset for the specific functions.
 * If gapless code is in effect, the positions are adjusted to compensate the skipped padding/delay - meaning, you should not care about that at all and just use the position defined for the samples you get out of the decoder;-)
 * The general usage is modelled after stdlib's ftell() and fseek().
 * Especially, the whence parameter for the seek functions has the same meaning as the one for fseek() and needs the same constants from stdlib.h:
 * - SEEK_SET: set position to (or near to) specified offset
 * - SEEK_CUR: change position by offset from now
 * - SEEK_END: set position to offset from end
 *
 * Note that sample-accurate seek only works when gapless support has been enabled at compile time; seek is frame-accurate otherwise.
 * Also, seeking is not guaranteed to work for all streams (underlying stream may not support it).
 *
 * @{
 *}

{* Returns the current position in samples.
 *  On the next read, you'd get that sample. *}
  proc_mpg123_tell = function(mh: pmpg123_handle): uintp; cdecl;

{* Returns the frame number that the next read will give you data from. *}
  proc_mpg123_tellframe = function(mh: pmpg123_handle): uintp; cdecl;

{* Returns the current byte offset in the input stream. *}
  proc_mpg123_tell_stream = function(mh: pmpg123_handle): offp; cdecl;

{* Seek to a desired sample offset.
 *  Set whence to SEEK_SET, SEEK_CUR or SEEK_END.
 *  \return The resulting offset >= 0 or error/message code *}
  proc_mpg123_seek = function(mh: pmpg123_handle; sampleoff: offp; whence: intp): offp; cdecl;

{* Seek to a desired sample offset in data feeding mode.
 *  This just prepares things to be right only if you ensure that the next chunk of input data will be from input_offset byte position.
 *  \param input_offset The position it expects to be at the
 *                      next time data is fed to mpg123_decode().
 *  \return The resulting offset >= 0 or error/message code *}
  proc_mpg123_feedseek = function(mh: pmpg123_handle; sampleoff: offp; whence: intp; var input_offset: offp): offp; cdecl;

{* Seek to a desired MPEG frame index.
 *  Set whence to SEEK_SET, SEEK_CUR or SEEK_END.
 *  \return The resulting offset >= 0 or error/message code *}
  proc_mpg123_seek_frame = function(mh: pmpg123_handle; frameoff: offp; whence: intp): offp; cdecl;

{* Return a MPEG frame offset corresponding to an offset in seconds.
 *  This assumes that the samples per frame do not change in the file/stream, which is a good assumption for any sane file/stream only.
 *  \return frame offset >= 0 or error/message code *}
  proc_mpg123_timeframe = function(mh: pmpg123_handle; sec: floatp): offp; cdecl;

  // pointer to array of offsets
  poffp = ^offp;

{* Give access to the frame index table that is managed for seeking.
 *  You are asked not to modify the values... unless you are really aware of what you are doing.
 *  \param offsets pointer to the index array
 *  \param step    one index byte offset advances this many MPEG frames
 *  \param fill    number of recorded index offsets; size of the array *}
  proc_mpg123_index = function(mh: pmpg123_handle; var offsets: poffp; var step: offp; var fill: uintp): iresult; cdecl;

{* Get information about current and remaining frames/seconds.
 *  WARNING: This function is there because of special usage by standalone mpg123 and may be removed in the final version of libmpg123!
 *  You provide an offset (in frames) from now and a number of output bytes
 *  served by libmpg123 but not yet played. You get the projected current frame
 *  and seconds, as well as the remaining frames/seconds. This does _not_ care
 *  about skipped samples due to gapless playback. *}
  proc_mpg123_position = function(mh: pmpg123_handle; frame_offset: offp;
			    buffered_bytes: offp; var current_frame: offp;
			    var frames_left: offp; var current_seconds: floatp;
			    var seconds_left: floatp): iresult; cdecl;


//** \defgroup mpg123_voleq mpg123 volume and equalizer

type
  mpg123_channels	= intp;
const
  MPG123_LEFT	=$1;	///**< The Left Channel. */
  MPG123_RIGHT	=$2;	///**< The Right Channel. */
  MPG123_LR	=$3;	///**< Both left and right channel; same as MPG123_LEFT|MPG123_RIGHT */

type
{* Set the 32 Band Audio Equalizer settings.
 *  \param channel Can be MPG123_LEFT, MPG123_RIGHT or MPG123_LEFT|MPG123_RIGHT for both.
 *  \param band The equaliser band to change (from 0 to 31)
 *  \param val The (linear) adjustment factor. *}
  proc_mpg123_eq = function(mh: pmpg123_handle; channel: mpg123_channels; band: intp; val: floatp): iresult; cdecl;

{* Get the 32 Band Audio Equalizer settings.
 *  \param channel Can be MPG123_LEFT, MPG123_RIGHT or MPG123_LEFT|MPG123_RIGHT for (arithmetic mean of) both.
 *  \param band The equaliser band to change (from 0 to 31)
 *  \return The (linear) adjustment factor. *}
  proc_mpg123_geteq = function(mh: pmpg123_handle; channel: mpg123_channels; band: intp): floatp; cdecl;

{* Reset the 32 Band Audio Equalizer settings to flat *}
  proc_mpg123_reset_eq = function(mh: pmpg123_handle): iresult; cdecl;

{* Set the absolute output volume including the RVA setting,
 *  vol<0 just applies (a possibly changed) RVA setting. *}
  proc_mpg123_volume = function(mh: pmpg123_handle; vol: floatp): iresult; cdecl;

{* Adjust output volume including the RVA setting by chosen amount *}
  proc_mpg123_volume_change = function(mh: pmpg123_handle; change: floatp): iresult; cdecl;

{* Return current volume setting, the actual value due to RVA, and the RVA
 *  adjustment itself. It's all as double float value to abstract the sample
 *  format. The volume values are linear factors / amplitudes (not percent)
 *  and the RVA value is in decibels. *}
  proc_mpg123_getvolume = function(mh: pmpg123_handle; var base: floatp; really: floatp; var rva_db: floatp): iresult; cdecl;

//* TODO: Set some preamp in addition / to replace internal RVA handling? */



//** \defgroup mpg123_status mpg123 status and information

type
{* Enumeration of the mode types of Variable Bitrate *}
  mpg123_vbr_t = intp;
const
  MPG123_CBR = 0;	///**< Constant Bitrate Mode (default) */
  MPG123_VBR = 1;	///**< Variable Bitrate Mode */
  MPG123_ABR = 2;	///**< Average Bitrate Mode */

type
{* Enumeration of the MPEG Versions *}
  mpg123_version = intp;
const
  MPG123_1_0	= 0;	///**< MPEG Version 1.0 */
  MPG123_2_0	= 1;	///**< MPEG Version 2.0 */
  MPG123_2_5	= 2;	///**< MPEG Version 2.5 */


type
{* Enumeration of the MPEG Audio mode.
 *  Only the mono mode has 1 channel, the others have 2 channels. *}
  mpg123_mode = intp;
const
  MPG123_M_STEREO	= 0;	///**< Standard Stereo. */
  MPG123_M_JOINT	= 1;	///**< Joint Stereo. */
  MPG123_M_DUAL		= 2;	///**< Dual Channel. */
  MPG123_M_MONO		= 3;	///**< Single Channel. */


type
 {* Enumeration of the MPEG Audio flag bits *}
  mpg123_flags_t = intp;
const
  MPG123_CRC		= $1;	///**< The bitstream is error protected using 16-bit CRC. */
  MPG123_COPYRIGHT	= $2;	///**< The bitstream is copyrighted. */
  MPG123_PRIVATE	= $4;	///**< The private bit has been set. */
  MPG123_ORIGINAL	= $8;	///**< The bitstream is an original, not a copy. */

type
{* Data structure for storing information about a frame of MPEG Audio *}
  pmpg123_frameinfo = ^mpg123_frameinfo;
  mpg123_frameinfo = packed record
    //
    r_version: mpg123_version;	///**< The MPEG version (1.0/2.0/2.5). */
    r_layer: intp;		///**< The MPEG Audio Layer (MP1/MP2/MP3). */
    r_rate: intp;		///**< The sampling rate in Hz. */
    r_mode: mpg123_mode;	///**< The audio mode (Mono, Stereo, Joint-stero, Dual Channel). */
    r_mode_ext: intp;		///**< The mode extension bit flag. */
    r_framesize: intp;		///**< The size of the frame (in bytes). */
    r_flags: mpg123_flags_t;	///**< MPEG Audio flag bits. */
    r_emphasis: intp;		///**< The emphasis type. */
    r_bitrate: intp;		///**< Bitrate of the frame (kbps). */
    r_abr_rate: intp;		///**< The target average bitrate. */
    r_vbr: mpg123_vbr_t;	///**< The VBR mode. */
  end;

{* Get frame information about the MPEG audio bitstream and store it in a mpg123_frameinfo structure. *}
  proc_mpg123_info = function(mh: pmpg123_handle; var mi: mpg123_frameinfo): iresult; cdecl;

{* Get the safe output buffer size for all cases (when you want to replace the internal buffer) *}
  proc_mpg123_safe_buffer = function(): uintp; cdecl;

{* Make a full parsing scan of each frame in the file. ID3 tags are found. An accurate length
 *  value is stored. Seek index will be filled. A seek back to current position
 *  is performed. At all, this function refuses work when stream is
 *  not seekable.
 *  \return MPG123_OK or MPG123_ERR.
 *}
  proc_mpg123_scan = function(mh: pmpg123_handle): iresult; cdecl;

{* Return, if possible, the full (expected) length of current track in samples.
  * \return length >= 0 or MPG123_ERR if there is no length guess possible. *}
  proc_mpg123_length = function(mh: pmpg123_handle): offp; cdecl;

{* Override the value for file size in bytes.
  * Useful for getting sensible track length values in feed mode or for HTTP streams.
  * \return MPG123_OK or MPG123_ERR *}
  proc_mpg123_set_filesize = function(mh: pmpg123_handle; size: offp): iresult; cdecl;

{* Returns the time (seconds) per frame; <0 is error. *}
  proc_mpg123_tpf = function(mh: pmpg123_handle): floatp; cdecl;

{* Get and reset the clip count. *}
  proc_mpg123_clip = function(mh: pmpg123_handle): iresult; cdecl;


type
{* The key values for state information from mpg123_getstate(). *}
  mpg123_state = intp;
const
  MPG123_ACCURATE = 1;	///**< Query if positons are currently accurate (integer value, 0 if false, 1 if true) */

type
{* Get various current decoder/stream state information.
 *  \param key the key to identify the information to give.
 *  \param val the address to return (long) integer values to
 *  \param fval the address to return floating point values to
 *  \return MPG123_OK or MPG123_ERR for success
 *}
  proc_mpg123_getstate = function(mh: pmpg123_handle; key: mpg123_state; var val: intp; var fval: floatp): iresult; cdecl;



{* \defgroup mpg123_metadata mpg123 metadata handling
 *
 * Functions to retrieve the metadata from MPEG Audio files and streams.
 * Also includes string handling functions.
 *
 * @{
 *}

{* Data structure for storing strings in a safer way than a standard C-String.
 *  Can also hold a number of null-terminated strings. *}
  pmpg123_string = ^mpg123_string;
  mpg123_string = packed record
    //
    r_p: charp;		///**< pointer to the string data */
    r_size: uintp; 	///**< raw number of bytes allocated */
    r_fill: uintp; 	///**< number of used bytes (including closing zero byte) */
  end;

{* Create and allocate memory for a new mpg123_string *}
  proc_mpg123_init_string = procedure(sb: pmpg123_string); cdecl;

{* Free-up mempory for an existing mpg123_string *}
  proc_mpg123_free_string = procedure(sb: pmpg123_string); cdecl;

{* Change the size of a mpg123_string
 *  \return 0 on error, 1 on success *}
  proc_mpg123_resize_string = function(sb: pmpg123_string; news: uintp): iresult; cdecl;

{* Increase size of a mpg123_string if necessary (it may stay larger).
 *  Note that the functions for adding and setting in current libmpg123 use this instead of mpg123_resize_string().
 *  That way, you can preallocate memory and safely work afterwards with pieces.
 *  \return 0 on error, 1 on success *}
  proc_mpg123_grow_string = function(sb: pmpg123_string; news: uintp): iresult; cdecl;

{* Copy the contents of one mpg123_string string to another.
 *  \return 0 on error, 1 on success *}
  proc_mpg123_copy_string = function(from: pmpg123_string; _to: pmpg123_string): iresult; cdecl;

{* Append a C-String to an mpg123_string
 *  \return 0 on error, 1 on success *}
  proc_mpg123_add_string = function(sb: pmpg123_string; stuff: charp): iresult; cdecl;

{* Append a C-substring to an mpg123 string
 *  \return 0 on error, 1 on success
 *  \param from offset to copy from
 *  \param count number of characters to copy (a null-byte is always appended) *}
  proc_mpg123_add_substring = function(sb: pmpg123_string; stuff: charp; from, count: uintp): iresult; cdecl;

{* Set the conents of a mpg123_string to a C-string
 *  \return 0 on error, 1 on success *}
  proc_mpg123_set_string = function(sb: pmpg123_string; stuff: charp): iresult; cdecl;

{* Set the contents of a mpg123_string to a C-substring
 *  \return 0 on error, 1 on success
 *  \param from offset to copy from
 *  \param count number of characters to copy (a null-byte is always appended) *}
  proc_mpg123_set_substring = function(sb: pmpg123_string; stuff: charp; from, count: uintp): iresult; cdecl;


{* Sub data structure for ID3v2, for storing various text fields (including comments).
 *  This is for ID3v2 COMM, TXXX and all the other text fields.
 *  Only COMM and TXXX have a description, only COMM has a language.
 *  You should consult the ID3v2 specification for the use of the various text fields ("frames" in ID3v2 documentation, I use "fields" here to separate from MPEG frames). *}
  pmpg123_text = ^mpg123_text;
  mpg123_text = packed record
    //
    r_lang: array[0..3 - 1] of aChar;	///**< Three-letter language code (not terminated). */
    r_id: array[0..4 - 1] of aChar;	///**< The ID3v2 text field id, like TALB, TPE2, ... (4 characters, no string termination). */
    r_description: mpg123_string;	///**< Empty for the generic comment... */
    r_text: mpg123_string;		///**< ... */
  end;

{* Data structure for storing IDV3v2 tags.
 *  This structure is not a direct binary mapping with the file contents.
 *  The ID3v2 text frames are allowed to contain multiple strings.
 *  So check for null bytes until you reach the mpg123_string fill.
 *  All text is encoded in UTF-8. *}
  pmpg123_id3v2 = ^mpg123_id3v2;
  mpg123_id3v2 = packed record
    r_version: uint8;		///**< 3 or 4 for ID3v2.3 or ID3v2.4. */
    r_title: pmpg123_string;   	///**< Title string (pointer into text_list). */
    r_artist: pmpg123_string;  	///**< Artist string (pointer into text_list). */
    r_album: pmpg123_string;   	///**< Album string (pointer into text_list). */
    r_year: pmpg123_string;    	///**< The year as a string (pointer into text_list). */
    r_genre: pmpg123_string;   	///**< Genre String (pointer into text_list). The genre string(s) may very well need postprocessing, esp. for ID3v2.3. */
    r_comment: pmpg123_string; 	///**< Pointer to last encountered comment text with empty description. */
    ///* Encountered ID3v2 fields are appended to these lists.
    ///   There can be multiple occurences, the pointers above always point to the last encountered data. */
    r_comment_list: pmpg123_text; 	///**< Array of comments. */
    r_comments: uintp;     		///**< Number of comments. */
    r_text: pmpg123_text;         	///**< Array of ID3v2 text fields */
    r_texts: uintp;        		///**< Numer of text fields. */
    r_extra: pmpg123_text;        	///**< The array of extra (TXXX) fields. */
    r_extras: uintp;       		///**< Number of extra text (TXXX) fields. */
  end;

{* Data structure for ID3v1 tags (the last 128 bytes of a file).
 *  Don't take anything for granted (like string termination)!
 *  Also note the change ID3v1.1 did: comment[28] = 0; comment[19] = track_number
 *  It is your task to support ID3v1 only or ID3v1.1 ...*}
  pmpg123_id3v1 = ^mpg123_id3v1;
  mpg123_id3v1 = packed record
    r_tag: array[0..3 - 1] of aChar;         ///**< Always the string "TAG", the classic intro. */
    r_title: array[0..30 - 1] of aChar;      ///**< Title string.  */
    r_artist: array[0..30 - 1] of aChar;     ///**< Artist string. */
    r_album: array[0..30 - 1] of aChar;      ///**< Album string. */
    r_year: array[0..4 - 1] of aChar;        ///**< Year string. */
    r_comment: array[0..30 - 1] of aChar;    ///**< Comment string. */
    r_genre: uint8;			     ///**< Genre index. */
  end;

const
  MPG123_ID3     = $3;	///**< 0011 There is some ID3 info. Also matches 0010 or NEW_ID3. */
  MPG123_NEW_ID3 = $1; 	///**< 0001 There is ID3 info that changed since last call to mpg123_id3. */
  MPG123_ICY     = $c;	///**< 1100 There is some ICY info. Also matches 0100 or NEW_ICY.*/
  MPG123_NEW_ICY = $4; 	///**< 0100 There is ICY info that changed since last call to mpg123_icy. */

type
{* Query if there is (new) meta info, be it ID3 or ICY (or something new in future).
   The check function returns a combination of flags. *}
  proc_mpg123_meta_check = function(mh: pmpg123_handle): iresult; cdecl; ///* On error (no valid handle) just 0 is returned. */

{* Point v1 and v2 to existing data structures wich may change on any next read/decode function call.
 *  v1 and/or v2 can be set to NULL when there is no corresponding data.
 *  \return Return value is MPG123_OK or MPG123_ERR,  *}
  proc_mpg123_id3 = function(mh: pmpg123_handle; var v1: pmpg123_id3v1; var v2: mpg123_id3v2): iresult; cdecl;

{* Point icy_meta to existing data structure wich may change on any next read/decode function call.
 *  \return Return value is MPG123_OK or MPG123_ERR,  *}
  proc_mpg123_icy = function(mh: pmpg123_handle; var icy_meta: charp): iresult; cdecl; ///* same for ICY meta string */

{* Decode from windows-1252 (the encoding ICY metainfo used) to UTF-8.
 *  \param icy_text The input data in ICY encoding
 *  \return pointer to newly allocated buffer with UTF-8 data (You free() it!) *}
  proc_mpg123_icy2utf8 = function(icy_text: charp): charp; cdecl;


type
{* \defgroup mpg123_advpar mpg123 advanced parameter API
 *
 *  Direct access to a parameter set without full handle around it.
 *	Possible uses:
 *    - Influence behaviour of library _during_ initialization of handle (MPG123_VERBOSE).
 *    - Use one set of parameters for multiple handles.
 *
 *	The functions for handling mpg123_pars (mpg123_par() and mpg123_fmt()
 *  family) directly return a fully qualified mpg123 error code, the ones
 *  operating on full handles normally MPG123_OK or MPG123_ERR, storing the
 *  specific error code itseld inside the handle.
 *
 *}

{* Opaque structure for the libmpg123 decoder parameters. *}
  pmpg123_pars = ^mpg123_pars;
  mpg123_pars = packed record end;

{* Create a handle with preset parameters. *}
  proc_mpg123_parnew = function(mp: pmpg123_pars; decoder: charp; var error: intp): pmpg123_handle; cdecl;

{* Allocate memory for and return a pointer to a new mpg123_pars *}
  proc_mpg123_new_pars = function(var error: intp): pmpg123_pars; cdecl;

{* Delete and free up memory used by a mpg123_pars data structure *}
  proc_mpg123_delete_pars = procedure(mp: pmpg123_pars); cdecl;

{* Configure mpg123 parameters to accept no output format at all,
 * use before specifying supported formats with mpg123_format *}
  proc_mpg123_fmt_none = function(mp: pmpg123_pars): iresult; cdecl;

{* Configure mpg123 parameters to accept all formats
 *  (also any custom rate you may set) -- this is default. *}
  proc_mpg123_fmt_all = function(mp: pmpg123_pars): iresult; cdecl;

{* Set the audio format support of a mpg123_pars in detail:
	\param rate The sample rate value (in Hertz).
	\param channels A combination of MPG123_STEREO and MPG123_MONO.
	\param encodings A combination of accepted encodings for rate and channels, p.ex MPG123_ENC_SIGNED16|MPG123_ENC_ULAW_8 (or 0 for no support).
	\return 0 on success, -1 if there was an error. /
*}
  proc_mpg123_fmt = function(mp: pmpg123_pars; rate, channels, encodings: intp): iresult; cdecl; ///* 0 is good, -1 is error */

{* Check to see if a specific format at a specific rate is supported
 *  by mpg123_pars.
 *  \return 0 for no support (that includes invalid parameters), MPG123_STEREO,
 *          MPG123_MONO or MPG123_STEREO|MPG123_MONO. *}
  proc_mpg123_fmt_support = function(mp: pmpg123_pars; rate, encoding: intp): iresult; cdecl;

{* Set a specific parameter, for a specific mpg123_pars, using a parameter
 *  type key chosen from the mpg123_parms enumeration, to the specified value. *}
  proc_mpg123_par = function(mp: pmpg123_pars; _type: mpg123_parms; value: intp; fvalue: floatp): iresult; cdecl;

{* Get a specific parameter, for a specific mpg123_pars.
 *  See the mpg123_parms enumeration for a list of available parameters. *}
  proc_mpg123_getpar = function(mp: pmpg123_pars; _type: mpg123_parms; var val: intp; var fval: floatp): iresult; cdecl;



{* \defgroup mpg123_lowio mpg123 low level I/O
  * You may want to do tricky stuff with I/O that does not work with mpg123's default file access or you want to make it decode into your own pocket...
  *
  * @{ *}

{* Replace default internal buffer with user-supplied buffer.
  * Instead of working on it's own private buffer, mpg123 will directly use the one you provide for storing decoded audio. *}
  proc_mpg123_replace_buffer = function(mh: pmpg123_handle; data: ptrp; size: uintp): iresult; cdecl;

{* The max size of one frame's decoded output with current settings.
 *  Use that to determine an appropriate minimum buffer size for decoding one frame. *}
  proc_mpg123_outblock = function(mh: pmpg123_handle): uintp; cdecl;

  proc_POSIX_read = function (handle: intp; buf: pointer; size: uintp): intp; cdecl;
  proc_POSIX_seek = function (handle: intp; offs: offp; some: intp): offp; cdecl;

{* Replace low-level stream access functions; read and lseek as known in POSIX.
 *  You can use this to make any fancy file opening/closing yourself,
 *  using open_fd to set the file descriptor for your read/lseek (doesn't need to be a "real" file descriptor...).
 *  Setting a function to NULL means that the default internal read is
 *  used (active from next mpg123_open call on). *}
  proc_mpg123_replace_reader = function(mh: pmpg123_handle;
                             		read_proc: proc_POSIX_read;
                                  	seek_proc: proc_POSIX_seek): iresult; cdecl;



type
  {*
    mpglib prototype
  }
  mpglib_proto = record
    //
    r_libName: wString;
    r_refCount: int;
    r_module: hModule;
    //
    r_initMP3: function(mp: PMPSTR): bool; cdecl;
    r_decodeMP3: function(mp: PMPSTR; inmemory: pointer; inmemsize: unsigned; outmemory: pointer; outmemsize: int; var done: int): int; cdecl;
    r_exitMP3: procedure(mp: PMPSTR); cdecl;
  end;


  {*
    libmpg123 prototype --
  }
  plibmpg123_proto = ^libmpg123_proto;
  libmpg123_proto = record
    //
    r_libName: wString;
    r_refCount: int;
    r_module: hModule;
    //
    r_mpg123_init		: proc_mpg123_init;
    r_mpg123_exit               : proc_mpg123_exit;
    r_mpg123_new                : proc_mpg123_new;
    r_mpg123_delete             : proc_mpg123_delete;
    r_mpg123_param              : proc_mpg123_param;
    r_mpg123_getparam           : proc_mpg123_getparam;
    r_mpg123_plain_strerror     : proc_mpg123_plain_strerror;
    r_mpg123_strerror           : proc_mpg123_strerror;
    r_mpg123_errcode            : proc_mpg123_errcode;
    r_mpg123_decoders           : proc_mpg123_decoders;
    r_mpg123_supported_decoders : proc_mpg123_supported_decoders;
    r_mpg123_decoder            : proc_mpg123_decoder;
    r_mpg123_rates              : proc_mpg123_rates;
    r_mpg123_encodings          : proc_mpg123_encodings;
    r_mpg123_format_none        : proc_mpg123_format_none;
    r_mpg123_format_all         : proc_mpg123_format_all;
    r_mpg123_format             : proc_mpg123_format;
    r_mpg123_format_support     : proc_mpg123_format_support;
    r_mpg123_getformat          : proc_mpg123_getformat;
    r_mpg123_open_feed          : proc_mpg123_open_feed;
    r_mpg123_close              : proc_mpg123_close;
    r_mpg123_read               : proc_mpg123_read;
    r_mpg123_feed               : proc_mpg123_feed;
    r_mpg123_decode             : proc_mpg123_decode;
    r_mpg123_eq                 : proc_mpg123_eq;
    r_mpg123_geteq              : proc_mpg123_geteq;
    r_mpg123_reset_eq           : proc_mpg123_reset_eq;
    r_mpg123_volume             : proc_mpg123_volume;
    r_mpg123_volume_change      : proc_mpg123_volume_change;
    r_mpg123_getvolume          : proc_mpg123_getvolume;
    r_mpg123_info               : proc_mpg123_info;
    r_mpg123_safe_buffer        : proc_mpg123_safe_buffer;
    r_mpg123_scan               : proc_mpg123_scan;
    r_mpg123_tpf                : proc_mpg123_tpf;
    r_mpg123_clip               : proc_mpg123_clip;
    r_mpg123_getstate           : proc_mpg123_getstate;
    r_mpg123_init_string        : proc_mpg123_init_string;
    r_mpg123_free_string        : proc_mpg123_free_string;
    r_mpg123_resize_string      : proc_mpg123_resize_string;
    r_mpg123_grow_string        : proc_mpg123_grow_string;
    r_mpg123_copy_string        : proc_mpg123_copy_string;
    r_mpg123_add_string         : proc_mpg123_add_string;
    r_mpg123_add_substring      : proc_mpg123_add_substring;
    r_mpg123_set_string         : proc_mpg123_set_string;
    r_mpg123_set_substring      : proc_mpg123_set_substring;
    r_mpg123_meta_check         : proc_mpg123_meta_check;
    r_mpg123_id3                : proc_mpg123_id3;
    r_mpg123_icy                : proc_mpg123_icy;
    r_mpg123_icy2utf8           : proc_mpg123_icy2utf8;
    r_mpg123_parnew             : proc_mpg123_parnew;
    r_mpg123_new_pars           : proc_mpg123_new_pars;
    r_mpg123_delete_pars        : proc_mpg123_delete_pars;
    r_mpg123_fmt_none           : proc_mpg123_fmt_none;
    r_mpg123_fmt_all            : proc_mpg123_fmt_all;
    r_mpg123_fmt                : proc_mpg123_fmt;
    r_mpg123_fmt_support        : proc_mpg123_fmt_support;
    r_mpg123_par                : proc_mpg123_par;
    r_mpg123_getpar             : proc_mpg123_getpar;
    r_mpg123_replace_buffer     : proc_mpg123_replace_buffer;
    r_mpg123_outblock           : proc_mpg123_outblock;
    r_mpg123_replace_reader     : proc_mpg123_replace_reader;
    r_mpg123_open               : proc_mpg123_open;
    r_mpg123_open_fd            : proc_mpg123_open_fd;
    r_mpg123_decode_frame       : proc_mpg123_decode_frame;
    r_mpg123_tell               : proc_mpg123_tell;
    r_mpg123_tellframe          : proc_mpg123_tellframe;
    r_mpg123_tell_stream        : proc_mpg123_tell_stream;
    r_mpg123_seek               : proc_mpg123_seek;
    r_mpg123_feedseek           : proc_mpg123_feedseek;
    r_mpg123_seek_frame         : proc_mpg123_seek_frame;
    r_mpg123_timeframe          : proc_mpg123_timeframe;
    r_mpg123_index              : proc_mpg123_index;
    r_mpg123_position           : proc_mpg123_position;
    r_mpg123_length             : proc_mpg123_length;
    r_mpg123_set_filesize       : proc_mpg123_set_filesize;
  end;


  // --  --
  mpglibDataAvailEvent = procedure(sender: tObject; data: pointer; size: unsigned; var copyToStream: bool) of object;	// copyToStream is not used
  mpglibApplySamplingEvent = procedure(sender: tObject; rate, bits, channels: unsigned) of object;


  {*
	MPGLIB decoder wrapper.
        (Old one, do not use)
  }
  unaMpgLibDecoder = class(unaThread)
  private
    f_proto: mpglib_proto;
    f_errorCode: int;
    f_MPSTR: PMPSTR;
    f_inStream: unaMemoryStream;
    f_oldPCM_rate: unsigned;
    f_oldPCM_channels: unsigned;
    f_enterFails: unsigned;
    f_ensureLayer: int;
    //
    f_onDataAvail: mpgLibDataAvailEvent;
    f_onApplySampling: mpglibApplySamplingEvent;
    //
    function getInDataSize(): unsigned;
  protected
    function execute(threadIndex: unsigned): int; override;
    procedure startIn(); override;
    procedure startOut(); override;
    procedure doWrite(data: pointer; len: unsigned); virtual;
    //
    procedure notifyData(data: pointer; size: unsigned; var copyToStream: bool); virtual;
    procedure notifySamplingChange(rate, bits, channels: unsigned); virtual;
  public
    constructor create(const libName: wString = '');
    procedure AfterConstruction(); override;
    procedure BeforeDestruction(); override;
    //
    function open(): int;
    procedure close();
    procedure write(data: pointer; len: unsigned);
    //
    procedure unloadLibrary();
    procedure loadLibrary(const libName: wString = '');
    //
    property errorCode: int read f_errorCode;	// 0 for OK
    property MPSTR: PMPSTR read f_MPSTR;
    property ensureLayer: int read f_ensureLayer write f_ensureLayer default -1;	// set to 1, 2, or 3 to better protection against broken MP3 files
    property inDataSize: unsigned read getInDataSize;
    //
    property onDataAvail: mpgLibDataAvailEvent read f_onDataAvail write f_onDataAvail;
    property onApplySampling: mpglibApplySamplingEvent read f_onApplySampling write f_onApplySampling;
  end;


  {*
	OnFormatChange prototype

	@param sender Sender of event.
	@param rate Sampling rate (44100, etc)
	@param numChannels Number of channels (1 - mono, 2 - stereo)
	@param numBits Number of bits (8, 16, 24, etc)
	@param encoding Refer to MPG123_ENC_XXX constants.
  }
  unaLibmpg123_onFormatChange = procedure(sender: tObject; rate, numChannels, numBits, encoding: int) of object;

  {*
	libmpg123 decoder wrapper.
  }
  unaLibmpg123Decoder = class(unaObject)
  private
    f_proto: libmpg123_proto;
    f_mh: pmpg123_handle;
    f_onFC: unaLibmpg123_onFormatChange;
    f_noFC: bool;
    f_autoResynch: bool;
    f_libOK: bool;
    //
    function getProto(): plibmpg123_proto;
    function getDecoder(): string;
    procedure setDecoder(const value: string);
    procedure doOnFC(forced: bool);
    function getBitrate: int;
  protected
    {*
	Called when new format was detected in read().

	@param rate The sample rate value (in Hertz).
	@param channels A combination of MPG123_STEREO and MPG123_MONO.
	@param encoding Refer to MPG123_ENC_XXX constants.
    }
    procedure formatChange(rate, channels, encoding: int); virtual;
  public
    {*
	Creates new instance of libmpg123 decoder.

	@param libname DLL file name. Default is '' which means that default library name will be used.
    }
    constructor create(const libname: string = '');
    {*
	Cleans up the instance before destruction.
    }
    procedure BeforeDestruction(); override;
    {*
	Lists available decoder names.

	@param supportedOnly Lists supported decoders only. Default is True.
	@param list Optional string list to be filled with available decoder names. Default is nil.

	@return Return a NULL-terminated array of generally available (supportedOnly = False) or supported by the CPU (supportedOnly = True)
		decoder names (plain 8bit ASCII).
    }
    function getDecoderNames(supportedOnly: bool = true; list: unaStringList = nil): charpp;
    {*
	Opens library for direct mp3 file reading.
	Use read() to read uncompressed audio data.
	Use close() to release library handle.

	@param filename Name of mp3 file to read ddta from.

	@return MPG123_OK or error code.
    }
    function open(const filename: string): iresult; overload;
    {*
	Opens library for direct mp3 data feeding.
	Use feed() to feed library with new portion of mp3 data.
	Use read() to read available uncompressed audio data.
	Use close() to release library handle.

	@return MPG123_OK or error code.
    }
    function open(): iresult; overload;
    {*
	Feeds library with new portion of mp3 data.
	Library must be opened for feeding with open().
	Use read() method to read available uncompressed audio data.

	@param data Pointer to buffer with mp3 data.
	@param size Size of buffer in bytes.

	@return MPG123_OK or error code.
    }
    function feed(data: pointer; size: unsigned): iresult;
    {*
	Reads up to outsize uncompressed audio bytes (if available).
	Library must be opened for feeding or reading with open().
	If library was open for feeding, use feed() method to feed library with new portion of mp3 data.

	@param outdata Pointer to buffer to write decompressed audio into.
	@param outsize Specifies size of buffer in bytes.
		       Library will try to fill the whole buffer if there is enough input data.
		       Actual number of bytes written into buffer is returned via this variable.
		       Also check the result for reason of other possible errors or warnings.

	@return MPG123_NEW_FORMAT in case a new audio format is detected. Returned at least once. No data is returned in this case.
		MPG123_NEED_MORE library needs more data to fill the whole buffer. Actual number of bytes is returned via outsize parameter.
		MPG123_OK the buffer was filled, call feed() again to read more data.
		MPG123_DONE Means track had a fixed VBR header with total track size information. According to this header no more mp3 data is available.
		Or some error code.
    }
    function read(outdata: pointer; var outsize: unsigned): iresult;
    {*
	Closes any handles opened by library after open().
    }
    procedure close();
    //
    // -- properties --
    //
    {*
	Direct access to library prototypes.
    }
    property proto: plibmpg123_proto read getProto;
    {*
	Direct access to internal handle.
    }
    property handle: pmpg123_handle read f_mh;
    {*
	Returns current decoder or assigns a new one (use getDecoderNames() to list available decoders).
	NOTE: Current decoder is alwyas '' due to limitation of library.
    }
    property decoder: string read getDecoder write setDecoder;
    //
    // -- events --
    //
    {*
	Fired when new format is detected during read().
    }
    property onFormatChange: unaLibmpg123_onFormatChange read f_onFC write f_onFC;
    {*
    }
    property autoResynch: bool read f_autoResynch write f_autoResynch;
    {*
    }
    property libOK: bool read f_libOK;
    {*
        Current bitrate. May change from frame to frame.
    }
    property bitrate: int read getBitrate;
  end;



{*
	Loads mpglib.
}
function loadLib(var proto: mpglib_proto; const libName: wString = ''): int;
{*
	Unloads mpglib.
}
function unloadLib(var proto: mpglib_proto): int;


{*
	Loads libmpg123 library.

	@param proto Routines prototypes.
	@param libName Name for library. Default '' means default name will be used.

	@return MPG123_OK if library was loaded OK, or MPG123_ERR if library cannot be loaded.
	@return MPG123_BAD_PARAM if some or all of exports could not be found.
}
function loadLibmpg123(var proto: libmpg123_proto; const libName: wString = ''): int;
{*
	Unloads libmpg123.

        @param proto Routines prototypes.
}
function unloadLibmpg123(var proto: libmpg123_proto): int;


implementation


uses
  unaUtils;

{ utility }

const
  c_def_libName		= 'mpglib.dll';
  c_def_libmpg123Name	= 'libmpg123-0.dll';


// --  --
function loadLib(var proto: mpglib_proto; const libName: wString = ''): int;
begin
  if (1 > proto.r_refCount) then begin
    //
    proto.r_libName := choice('' = trimS(libName), c_def_libName, libName);
{$IFDEF NO_ANSI_SUPPORT }
{$ELSE }
    if (g_wideApiSupported) then begin
{$ENDIF NO_ANSI_SUPPORT }
      proto.r_module := LoadLibraryW(pwChar(proto.r_libName));
{$IFNDEF NO_ANSI_SUPPORT }
    end
    else
      proto.r_module := LoadLibraryA(paChar(aString(proto.r_libName)));
{$ENDIF NO_ANSI_SUPPORT }
    //
    if (0 <> proto.r_module) then begin
      //
      proto.r_initMP3 := GetProcAddress(proto.r_module, '_InitMP3');
      proto.r_decodeMP3 := GetProcAddress(proto.r_module, '_decodeMP3');
      proto.r_exitMP3 := GetProcAddress(proto.r_module, '_ExitMP3');
      //
      if (
	   not assigned(proto.r_initMP3) or
	   not assigned(proto.r_decodeMP3) or
	   not assigned(proto.r_exitMP3)
	 ) then begin
	//
	FreeLibrary(proto.r_module);
        proto.r_module := 0;
	result := mpglib_error_noProc;
      end
      else begin
	//
	result := mpglib_error_OK;
        proto.r_refCount := 1;
      end;
    end
    else
      result := mpglib_error_noLib;
    //
  end
  else begin
    //
    if (0 <> proto.r_module) then begin
      //
      inc(proto.r_refCount);
      result := mpglib_error_OK;
    end
    else
      result := mpglib_error_noLib;
  end;
end;

// --  --
function unloadLib(var proto: mpglib_proto): int;
begin
  if (1 = proto.r_refCount) then begin
    //
    FreeLibrary(proto.r_module);
    //
    proto.r_libName := '';
    fillChar(proto.r_refCount, sizeOf(proto) - 8, #0);
  end
  else begin
    //
    if (0 < proto.r_refCount) then
      dec(proto.r_refCount);
  end;
  //
  result := mpglib_error_OK;
end;


// --  --
function loadLibmpg123(var proto: libmpg123_proto; const libName: wString = ''): int;
begin
  if (1 > proto.r_refCount) then begin
    //
    proto.r_libName := choice('' = trimS(libName), c_def_libmpg123Name, libName);
{$IFNDEF NO_ANSI_SUPPORT }
    if (g_wideApiSupported) then begin
{$ENDIF NO_ANSI_SUPPORT }
      proto.r_module := LoadLibraryW(pwChar(proto.r_libName));
{$IFNDEF NO_ANSI_SUPPORT }
    end
    else
      proto.r_module := LoadLibraryA(paChar(aString(proto.r_libName)));
{$ENDIF NO_ANSI_SUPPORT }
    //
    if (0 <> proto.r_module) then begin
      //
      proto.r_mpg123_init               := GetProcAddress(proto.r_module, 'mpg123_init');
      proto.r_mpg123_exit               := GetProcAddress(proto.r_module, 'mpg123_exit');
      proto.r_mpg123_new                := GetProcAddress(proto.r_module, 'mpg123_new');
      proto.r_mpg123_delete             := GetProcAddress(proto.r_module, 'mpg123_delete');
      proto.r_mpg123_param              := GetProcAddress(proto.r_module, 'mpg123_param');
      proto.r_mpg123_getparam           := GetProcAddress(proto.r_module, 'mpg123_getparam');
      proto.r_mpg123_plain_strerror     := GetProcAddress(proto.r_module, 'mpg123_plain_strerror');
      proto.r_mpg123_strerror           := GetProcAddress(proto.r_module, 'mpg123_strerror');
      proto.r_mpg123_errcode            := GetProcAddress(proto.r_module, 'mpg123_errcode');
      proto.r_mpg123_decoders           := GetProcAddress(proto.r_module, 'mpg123_decoders');
      proto.r_mpg123_supported_decoders := GetProcAddress(proto.r_module, 'mpg123_supported_decoders');
      proto.r_mpg123_decoder            := GetProcAddress(proto.r_module, 'mpg123_decoder');
      proto.r_mpg123_rates              := GetProcAddress(proto.r_module, 'mpg123_rates');
      proto.r_mpg123_encodings          := GetProcAddress(proto.r_module, 'mpg123_encodings');
      proto.r_mpg123_format_none        := GetProcAddress(proto.r_module, 'mpg123_format_none');
      proto.r_mpg123_format_all         := GetProcAddress(proto.r_module, 'mpg123_format_all');
      proto.r_mpg123_format             := GetProcAddress(proto.r_module, 'mpg123_format');
      proto.r_mpg123_format_support     := GetProcAddress(proto.r_module, 'mpg123_format_support');
      proto.r_mpg123_getformat          := GetProcAddress(proto.r_module, 'mpg123_getformat');
      proto.r_mpg123_open_feed          := GetProcAddress(proto.r_module, 'mpg123_open_feed');
      proto.r_mpg123_close              := GetProcAddress(proto.r_module, 'mpg123_close');
      proto.r_mpg123_read               := GetProcAddress(proto.r_module, 'mpg123_read');
      proto.r_mpg123_feed               := GetProcAddress(proto.r_module, 'mpg123_feed');
      proto.r_mpg123_decode             := GetProcAddress(proto.r_module, 'mpg123_decode');
      proto.r_mpg123_eq                 := GetProcAddress(proto.r_module, 'mpg123_eq');
      proto.r_mpg123_geteq              := GetProcAddress(proto.r_module, 'mpg123_geteq');
      proto.r_mpg123_reset_eq           := GetProcAddress(proto.r_module, 'mpg123_reset_eq');
      proto.r_mpg123_volume             := GetProcAddress(proto.r_module, 'mpg123_volume');
      proto.r_mpg123_volume_change      := GetProcAddress(proto.r_module, 'mpg123_volume_change');
      proto.r_mpg123_getvolume          := GetProcAddress(proto.r_module, 'mpg123_getvolume');
      proto.r_mpg123_info               := GetProcAddress(proto.r_module, 'mpg123_info');
      proto.r_mpg123_safe_buffer        := GetProcAddress(proto.r_module, 'mpg123_safe_buffer');
      proto.r_mpg123_scan               := GetProcAddress(proto.r_module, 'mpg123_scan');
      proto.r_mpg123_tpf                := GetProcAddress(proto.r_module, 'mpg123_tpf');
      proto.r_mpg123_clip               := GetProcAddress(proto.r_module, 'mpg123_clip');
      proto.r_mpg123_getstate           := GetProcAddress(proto.r_module, 'mpg123_getstate');
      proto.r_mpg123_init_string        := GetProcAddress(proto.r_module, 'mpg123_init_string');
      proto.r_mpg123_free_string        := GetProcAddress(proto.r_module, 'mpg123_free_string');
      proto.r_mpg123_resize_string      := GetProcAddress(proto.r_module, 'mpg123_resize_string');
      proto.r_mpg123_grow_string        := GetProcAddress(proto.r_module, 'mpg123_grow_string');
      proto.r_mpg123_copy_string        := GetProcAddress(proto.r_module, 'mpg123_copy_string');
      proto.r_mpg123_add_string         := GetProcAddress(proto.r_module, 'mpg123_add_string');
      proto.r_mpg123_add_substring      := GetProcAddress(proto.r_module, 'mpg123_add_substring');
      proto.r_mpg123_set_string         := GetProcAddress(proto.r_module, 'mpg123_set_string');
      proto.r_mpg123_set_substring      := GetProcAddress(proto.r_module, 'mpg123_set_substring');
      proto.r_mpg123_meta_check         := GetProcAddress(proto.r_module, 'mpg123_meta_check');
      proto.r_mpg123_id3                := GetProcAddress(proto.r_module, 'mpg123_id3');
      proto.r_mpg123_icy                := GetProcAddress(proto.r_module, 'mpg123_icy');
      proto.r_mpg123_icy2utf8           := GetProcAddress(proto.r_module, 'mpg123_icy2utf8');
      proto.r_mpg123_parnew             := GetProcAddress(proto.r_module, 'mpg123_parnew');
      proto.r_mpg123_new_pars           := GetProcAddress(proto.r_module, 'mpg123_new_pars');
      proto.r_mpg123_delete_pars        := GetProcAddress(proto.r_module, 'mpg123_delete_pars');
      proto.r_mpg123_fmt_none           := GetProcAddress(proto.r_module, 'mpg123_fmt_none');
      proto.r_mpg123_fmt_all            := GetProcAddress(proto.r_module, 'mpg123_fmt_all');
      proto.r_mpg123_fmt                := GetProcAddress(proto.r_module, 'mpg123_fmt');
      proto.r_mpg123_fmt_support        := GetProcAddress(proto.r_module, 'mpg123_fmt_support');
      proto.r_mpg123_par                := GetProcAddress(proto.r_module, 'mpg123_par');
      proto.r_mpg123_getpar             := GetProcAddress(proto.r_module, 'mpg123_getpar');
      proto.r_mpg123_replace_buffer     := GetProcAddress(proto.r_module, 'mpg123_replace_buffer');
      proto.r_mpg123_outblock           := GetProcAddress(proto.r_module, 'mpg123_outblock');
      proto.r_mpg123_replace_reader     := GetProcAddress(proto.r_module, 'mpg123_replace_reader');
      proto.r_mpg123_open               := GetProcAddress(proto.r_module, 'mpg123_open');
      proto.r_mpg123_open_fd            := GetProcAddress(proto.r_module, 'mpg123_open_fd');
      proto.r_mpg123_decode_frame       := GetProcAddress(proto.r_module, 'mpg123_decode_frame');
      proto.r_mpg123_tell               := GetProcAddress(proto.r_module, 'mpg123_tell');
      proto.r_mpg123_tellframe          := GetProcAddress(proto.r_module, 'mpg123_tellframe');
      proto.r_mpg123_tell_stream        := GetProcAddress(proto.r_module, 'mpg123_tell_stream');
      proto.r_mpg123_seek               := GetProcAddress(proto.r_module, 'mpg123_seek');
      proto.r_mpg123_feedseek           := GetProcAddress(proto.r_module, 'mpg123_feedseek');
      proto.r_mpg123_seek_frame         := GetProcAddress(proto.r_module, 'mpg123_seek_frame');
      proto.r_mpg123_timeframe          := GetProcAddress(proto.r_module, 'mpg123_timeframe');
      proto.r_mpg123_index              := GetProcAddress(proto.r_module, 'mpg123_index');
      proto.r_mpg123_position           := GetProcAddress(proto.r_module, 'mpg123_position');
      proto.r_mpg123_length             := GetProcAddress(proto.r_module, 'mpg123_length');
      proto.r_mpg123_set_filesize       := GetProcAddress(proto.r_module, 'mpg123_set_filesize');
      //
      if (
	    not assigned(proto.r_mpg123_init) or
            not assigned(proto.r_mpg123_exit) or
            not assigned(proto.r_mpg123_new) or
            not assigned(proto.r_mpg123_delete) or
            not assigned(proto.r_mpg123_param) or
            not assigned(proto.r_mpg123_getparam) or
	    not assigned(proto.r_mpg123_plain_strerror) or
            not assigned(proto.r_mpg123_strerror) or
            not assigned(proto.r_mpg123_errcode) or
            not assigned(proto.r_mpg123_decoders) or
            not assigned(proto.r_mpg123_supported_decoders) or
            not assigned(proto.r_mpg123_decoder) or
            not assigned(proto.r_mpg123_rates) or
            not assigned(proto.r_mpg123_encodings) or
            not assigned(proto.r_mpg123_format_none) or
            not assigned(proto.r_mpg123_format_all) or
            not assigned(proto.r_mpg123_format) or
            not assigned(proto.r_mpg123_format_support) or
            not assigned(proto.r_mpg123_getformat) or
            not assigned(proto.r_mpg123_open_feed) or
            not assigned(proto.r_mpg123_close) or
            not assigned(proto.r_mpg123_read) or
            not assigned(proto.r_mpg123_feed) or
            not assigned(proto.r_mpg123_decode) or
            not assigned(proto.r_mpg123_eq) or
            not assigned(proto.r_mpg123_geteq) or
            not assigned(proto.r_mpg123_reset_eq) or
            not assigned(proto.r_mpg123_volume) or
            not assigned(proto.r_mpg123_volume_change) or
	    not assigned(proto.r_mpg123_getvolume) or
            not assigned(proto.r_mpg123_info) or
            not assigned(proto.r_mpg123_safe_buffer) or
            not assigned(proto.r_mpg123_scan) or
            not assigned(proto.r_mpg123_tpf) or
            not assigned(proto.r_mpg123_clip) or
            not assigned(proto.r_mpg123_getstate) or
            not assigned(proto.r_mpg123_init_string) or
            not assigned(proto.r_mpg123_free_string) or
	    not assigned(proto.r_mpg123_resize_string) or
            not assigned(proto.r_mpg123_grow_string) or
            not assigned(proto.r_mpg123_copy_string) or
            not assigned(proto.r_mpg123_add_string) or
            not assigned(proto.r_mpg123_add_substring) or
            not assigned(proto.r_mpg123_set_string) or
            not assigned(proto.r_mpg123_set_substring) or
            not assigned(proto.r_mpg123_meta_check) or
            not assigned(proto.r_mpg123_id3) or
            not assigned(proto.r_mpg123_icy) or
            not assigned(proto.r_mpg123_icy2utf8) or
            not assigned(proto.r_mpg123_parnew) or
            not assigned(proto.r_mpg123_new_pars) or
            not assigned(proto.r_mpg123_delete_pars) or
            not assigned(proto.r_mpg123_fmt_none) or
            not assigned(proto.r_mpg123_fmt_all) or
            not assigned(proto.r_mpg123_fmt) or
            not assigned(proto.r_mpg123_fmt_support) or
            not assigned(proto.r_mpg123_par) or
            not assigned(proto.r_mpg123_getpar) or
            not assigned(proto.r_mpg123_replace_buffer) or
            not assigned(proto.r_mpg123_outblock) or
            not assigned(proto.r_mpg123_replace_reader) or
	    not assigned(proto.r_mpg123_open) or
            not assigned(proto.r_mpg123_open_fd) or
            not assigned(proto.r_mpg123_decode_frame) or
            not assigned(proto.r_mpg123_tell) or
            not assigned(proto.r_mpg123_tellframe) or
            not assigned(proto.r_mpg123_tell_stream) or
            not assigned(proto.r_mpg123_seek) or
            not assigned(proto.r_mpg123_feedseek) or
            not assigned(proto.r_mpg123_seek_frame) or
	    not assigned(proto.r_mpg123_timeframe) or
            not assigned(proto.r_mpg123_index) or
            not assigned(proto.r_mpg123_position) or
            not assigned(proto.r_mpg123_length) or
            not assigned(proto.r_mpg123_set_filesize)

	 ) then begin
	//
	FreeLibrary(proto.r_module);
        proto.r_module := 0;
	result := MPG123_BAD_PARAM;
      end
      else begin
        //
	result := MPG123_OK;
        proto.r_refCount := 1;
      end;
    end
    else
      result := MPG123_ERR;
    //
  end
  else begin
    //
    if (0 <> proto.r_module) then begin
      //
      inc(proto.r_refCount);
      result := mpglib_error_OK;
    end
    else
      result := mpglib_error_noLib;
  end;
end;

// --  --
function unloadLibmpg123(var proto: libmpg123_proto): int;
begin
  if (1 = proto.r_refCount) then begin
    //
    FreeLibrary(proto.r_module);
    //
    proto.r_libName := '';
    fillChar(proto.r_refCount, sizeOf(proto) - 8, #0);
  end
  else begin
    //
    if (0 < proto.r_refCount) then
      dec(proto.r_refCount);
  end;
  //
  result := mpglib_error_OK;
end;


{ unaMpgLibDecoder }

// --  --
procedure unaMpgLibDecoder.afterConstruction();
begin
  inherited;
  //
  f_inStream := unaMemoryStream.create();
  f_inStream.maxCacheSize := 128;
  //
  f_MPSTR := malloc(32*1024);	// 32 K
  loadLibrary(f_proto.r_libName);
end;

// --  --
procedure unaMpgLibDecoder.beforeDestruction();
begin
  inherited;
  //
  unloadLibrary();
  mrealloc(f_MPSTR);
  freeAndNil(f_inStream);
end;

// --  --
procedure unaMpgLibDecoder.close();
begin
  stop();
end;

// --  --
constructor unaMpgLibDecoder.create(const libName: wString);
begin
  inherited create();
  //
  f_proto.r_libName := libName;
end;

// --  --
procedure unaMpgLibDecoder.doWrite(data: pointer; len: unsigned);
begin
  f_inStream.write(data, len);
  //
  wakeUp();
end;

// --  --
function unaMpgLibDecoder.execute(threadIndex: unsigned): int;
var
  size: unsigned;
  chunk: pArray;
  chunkSize: unsigned;
  outChunk: array[word] of byte;
  res: int;
  done: int;
  i: unsigned;
  entered: bool;
  nothing: bool;
  giveUp: unsigned;
  offset: unsigned;
  mpegVer: int;
  layer: int;
  notUsed: bool;
begin
  chunkSize := MAXFRAMESIZE;
  chunk := malloc(chunkSize);
  res := 0;
  mpegVer := -1;
  layer := -1;
  //
  try
    while (not shouldStop) do begin
      //
      f_inStream.waitForData(100);
      //
      if (0 = f_errorCode) then begin
	//
	while (not shouldStop and (0 < f_inStream.firstChunkSize())) do begin
	  //
	  size := f_inStream.read(chunk, int(chunkSize));
	  offset := 0;
	  //
	  while (0 < size) do begin
	    //
	    if (0 = res) then begin
	      // try to locate FF
	      i := offset;
	      repeat
		//
		while (not shouldStop and
			  (i < size - 2) and
			     (
			       ($FF <> chunk[i]) or
			       ($F0 <> (chunk[i + 1] and $F0)) or
			       ($00  = (chunk[i + 1] and $06)) or
			       ($F0  = (chunk[i + 2] and $F0)) or
			       ($0C  = (chunk[i + 2] and $0C)) or
			       ((0 <= mpegVer) and (mpegVer <> ((chunk[i + 1] and $08) shr 3))) or
			       ((0 <  layer)   and (layer   <> ((chunk[i + 1] and $06) shr 1)))
			     )
		      ) do
		  inc(i);
		//
		if (i < size - 2) then begin
		  //
		  dec(size, i);
		  move(chunk[i], chunk[0], size);
		  i := 1;
		  //
		  if (0 > mpegVer) then
		    mpegVer := (chunk[1] and $08) shr 3;
		  //
		  if (1 > layer) then
		    layer := (chunk[1] and $06) shr 1;
		  //
		  if (0 < f_ensureLayer) then begin
		    //
		    case (f_ensureLayer) of

		       1: if (3 <> layer) then begin
			 mpegVer := -1;
			 layer := -1;
		       end;

		       2: if (2 <> layer) then begin
			 mpegVer := -1;
			 layer := -1;
		       end;

		       3: if (1 <> layer) then begin
			 mpegVer := -1;
			 layer := -1;
		       end;

		    end;
		    //
		  end;
		end
		else
		  size := 0;	// skip over to next block of data
		//
	      until (shouldStop or (1 > size) or ((0 < layer) and (0 <= mpegVer)));
	    end;
	    //
	    giveUp := 100;
	    entered := false;
	    repeat
	      //
	      if (acquire(false, 100)) then begin
		//
		try
		  if (0 < size) then begin
		    //
		    try
		      res := f_proto.r_decodeMP3(f_MPSTR, chunk, size, @outChunk, sizeOf(outChunk), done)
		    except
		      // ignore all soft errors
		      res := MP3_ERR;
		      done := 0;
		      layer := -1;
		      mpegVer := -1;
		    end;
		    //
		  end
		  else
		    done := 0;
		  //
		finally
		  releaseWO();
		end;
		//
		entered := true;
	      end
	      else
		dec(giveUp);
	      //
	    until (entered or shouldStop or (1 > giveUp));
	    //
	    if (1 > giveUp) then
	      inc(f_enterFails);
	    //
	    nothing := (1 > done) and (0 = res);
	    //
	    while (not shouldStop and entered and (0 = res) and (0 < done)) do begin
	      //
	      notUsed := true;	// compatibility with older code
	      notifyData(@outChunk, done, notUsed);
	      //
	      //
	      giveUp := 100;
	      entered := false;
	      repeat
		//
		if (acquire(false, 100)) then begin
		  //
		  try
		    //
		    try
		      res := f_proto.r_decodeMP3(f_MPSTR, nil, 0, @outChunk, sizeOf(outChunk), done);
		    except
		      // ignore all soft errors
		      res := MP3_ERR;
		      done := 0;
		      layer := -1;
		      mpegVer := -1;
		    end;
		    //
		  finally
		    releaseWO();
		  end;
		  //
		  entered := true;
		end
		else
		  dec(giveUp);
		//
	      until (entered or shouldStop or (1 > giveUp));
	      //
	      if (1 > giveUp) then
		inc(f_enterFails);
	    end;
	    //
	    if (not shouldStop and (nothing or (MP3_ERR = res))) then begin
	      // broken stream, re-init MP3
	      f_proto.r_exitMP3(f_MPSTR);
	      f_errorCode := choice(f_proto.r_initMP3(f_MPSTR), 0, mpglib_error_initFail);
	      res := 0;
	    end;
	    //
	    if (MP3_NEED_MORE = res) then
	      size := 0;
	    //
	    if (nothing or (0 = res)) then begin
	      //
	      inc(offset, 16);
	    end;
	  end;
	end;
	//
      end;
    end;
    //
  finally
    //
    //chunkSize := 0;
    mrealloc(chunk);
  end;
  //
  result := 0;
end;

// --  --
function unaMpgLibDecoder.getInDataSize(): unsigned;
begin
  result := f_inStream.getSize();
end;

// --  --
procedure unaMpgLibDecoder.loadLibrary(const libName: wString);
begin
  unloadLibrary();
  //
  f_errorCode := loadLib(f_proto, libName);
end;

// --  --
procedure unaMpgLibDecoder.notifyData(data: pointer; size: unsigned; var copyToStream: bool);
var
  new_rate: unsigned;
  new_channels: unsigned;
begin
  new_rate := MPSTR.fr.sampling_frequency;
  new_channels:= MPSTR.fr.stereo;
  //
  if ((f_oldPCM_rate <> new_rate) or (f_oldPCM_channels <> new_channels)) then begin
    //
    notifySamplingChange(freqs[new_rate], 16, new_channels);
    //
    f_oldPCM_rate := new_rate;
    f_oldPCM_channels := new_channels;
  end;
  //
  if (assigned(f_onDataAvail)) then
    f_onDataAvail(self, data, size, copyToStream);
end;

// --  --
procedure unaMpgLibDecoder.notifySamplingChange(rate, bits, channels: unsigned);
begin
  if (assigned(f_onApplySampling)) then
    f_onApplySampling(self, rate, bits, channels);
end;

// --  --
function unaMpgLibDecoder.open(): int;
begin
  start();
  //
  result := 0;
end;

// --  --
procedure unaMpgLibDecoder.startIn();
begin
  inherited;
  //
  f_oldPCM_rate := 0;
  f_oldPCM_channels := 0;
  f_ensureLayer := -1;
  //
  if (0 = f_errorCode) then
    f_errorCode := choice(f_proto.r_initMP3(f_MPSTR), 0, mpglib_error_initFail);
end;

// --  --
procedure unaMpgLibDecoder.startOut();
begin
  inherited;
  //
  if (0 = f_errorCode) then
    f_proto.r_exitMP3(f_MPSTR);
end;

// --  --
procedure unaMpgLibDecoder.unloadLibrary();
begin
  unloadLib(f_proto);
end;

// --  --
procedure unaMpgLibDecoder.write(data: pointer; len: unsigned);
begin
  doWrite(data, len);
end;


{ unaLibmpg123Decoder }

// --  --
procedure unaLibmpg123Decoder.BeforeDestruction();
begin
  inherited;
  //
  close();
  //
  if (libOK) then begin
    //
    f_proto.r_mpg123_exit();
    unloadLibmpg123(f_proto);
  end;
end;

// --  --
procedure unaLibmpg123Decoder.close();
begin
  if (libOK and (nil <> f_mh)) then begin
    //
    f_proto.r_mpg123_close(f_mh);
    //
    f_proto.r_mpg123_delete(f_mh);
    f_mh := nil;
  end;
  //
  f_noFC := true;	// mark that no FC was called after open
end;

// --  --
constructor unaLibmpg123Decoder.create(const libname: string);
begin
  f_libOK := (MPG123_OK = loadLibmpg123(f_proto, libname));
  //
  f_libOK := f_libOK and (MPG123_OK = f_proto.r_mpg123_init());
  if (not f_libOK) then
    unloadLibmpg123(f_proto);
  //
  inherited create();
end;

// --  --
procedure unaLibmpg123Decoder.doOnFC(forced: bool);
var
  rate, channels, bits, encoding: intp;
begin
  if (libOK) then begin
    //
    if (MPG123_OK <> f_proto.r_mpg123_getformat(f_mh, rate, channels, encoding)) then begin
      //
      rate := 44100;
      channels := MPG123_STEREO;
      encoding := MPG123_ENC_SIGNED_16;
    end;
    //
    if ((0 < rate) and (0 < channels)) then begin
      //
      formatChange(rate, channels, encoding);
      //
      if (assigned(f_onFC)) then begin
        //
        if (MPG123_STEREO = channels) then
          channels := 2
        else
          channels := 1;
        //
        case (encoding) of

          MPG123_ENC_SIGNED_16,
          MPG123_ENC_UNSIGNED_16: 	bits := 16;
          //
          MPG123_ENC_UNSIGNED_8,
          MPG123_ENC_SIGNED_8,
          MPG123_ENC_ULAW_8,
          MPG123_ENC_ALAW_8:	bits := 8;
          //
          MPG123_ENC_SIGNED_32,
          MPG123_ENC_UNSIGNED_32,
          MPG123_ENC_FLOAT_32:	bits := 32;
          //
          MPG123_ENC_FLOAT_64:	bits := 64;

          else
            bits := 16;	// default

        end;
        //
        f_onFC(self, rate, channels, bits, encoding);
      end;
    end;
  end;
end;

// --  --
function unaLibmpg123Decoder.feed(data: pointer; size: unsigned): iresult;
begin
  if (libOK) then
    result := f_proto.r_mpg123_feed(f_mh, data, size)
  else
    result := -1;
end;

// --  --
procedure unaLibmpg123Decoder.formatChange(rate, channels, encoding: int);
begin
  // not much here, just a placeholder for ovewrites
end;

// --  --
function unaLibmpg123Decoder.getBitrate(): int;
var
  fi: mpg123_frameinfo;
begin
  if (MPG123_OK = proto.r_mpg123_info(f_mh, fi)) then
    result := fi.r_bitrate
  else
    result := 0;
end;

// --  --
function unaLibmpg123Decoder.getDecoder(): string;
begin
  result := ''; //string(f_proto.r_mpg123_current_decoder());
end;

// --  --
function unaLibmpg123Decoder.getDecoderNames(supportedOnly: bool; list: unaStringList): charpp;
var
  p: paChar;
begin
  if (libOK) then begin
    //
    if (supportedOnly) then
      result := f_proto.r_mpg123_supported_decoders()
    else
      result := f_proto.r_mpg123_decoders();
  end
  else
    result := nil;
  //
  if ((nil <> list) and (nil <> result)) then begin
    //
    list.clear();
    p := result^;
    while (p^ <> #0) do begin
      //
      list.add(string(p));
      inc(p, length(p) + 1);
    end;
  end;
end;

// --  --
function unaLibmpg123Decoder.getProto(): plibmpg123_proto;
begin
  result := @f_proto;
end;

// --  --
function unaLibmpg123Decoder.open(): iresult;
var
  err: intp;
begin
  close();	// just in case
  //
  if (libOK) then begin
    //
    // assign default decoder
    f_mh := f_proto.r_mpg123_new(nil, @err);
    //
    // create stream feeding
    result := f_proto.r_mpg123_open_feed(f_mh);
  end
  else
    result := -1;
end;

// --  --
function unaLibmpg123Decoder.open(const filename: string): iresult;
var
  err: intp;
begin
  close();	// just in case
  //
  // assign default decoder
  f_mh := f_proto.r_mpg123_new(nil, @err);
  //
  // create file feeding
  result := f_proto.r_mpg123_open(f_mh, paChar(aString(filename)));
end;

// --  --
function unaLibmpg123Decoder.read(outdata: pointer; var outsize: unsigned): iresult;
var
  done: uintp;
begin
  if (libOK) then begin
    //
    result := f_proto.r_mpg123_read(f_mh, outdata, outsize, done);
    outsize := done;
    //
    if ((MPG123_NEW_FORMAT = result) or f_noFC) then begin
      //
      f_noFC := false;
      doOnFC(f_noFC);
    end;
  end
  else
    result := -1;
end;

// --  --
procedure unaLibmpg123Decoder.setDecoder(const value: string);
begin
  if (f_libOK) then
    f_proto.r_mpg123_decoder(f_mh, paChar(aString(value)));
end;


end.

