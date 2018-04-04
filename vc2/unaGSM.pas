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

	  unaGSM.pas - GSM6.10 codec implementation
	  VC components version 2.5

	----------------------------------------------
	  Delphi conversion of original C code:

	  Copyright (c) 2011 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 02 Nov 2011

	  modified by:
		Lake, Nov 2011

	----------------------------------------------
*)

{

Copyright 1992, 1993, 1994 by Jutta Degener and Carsten Bormann,
Technische Universitaet Berlin

Any use of this software is permitted provided that this notice is not
removed and that neither the authors nor the Technische Universitaet Berlin
are deemed to have made any representations as to the suitability of this
software for any purpose nor are held responsible for any defects of
this software.  THERE IS ABSOLUTELY NO WARRANTY FOR THIS SOFTWARE.

As a matter of courtesy, the authors request to be informed about uses
this software has found, about bugs in this software, and about any
improvements that may be of general interest.

Berlin, 28.11.1994
Jutta Degener
Carsten Bormann

                                 oOo

Since the original terms of 15 years ago maybe do not make our
intentions completely clear given today's refined usage of the legal
terms, we append this additional permission:

      Permission to use, copy, modify, and distribute this software
      for any purpose with or without fee is hereby granted,
      provided that this notice is not removed and that neither
      the authors nor the Technische Universitaet Berlin are
      deemed to have made any representations as to the suitability
      of this software for any purpose nor are held responsible
      for any defects of this software.  THERE IS ABSOLUTELY NO
      WARRANTY FOR THIS SOFTWARE.

Berkeley/Bremen, 05.04.2009
Jutta Degener
Carsten Bormann

}

{$I unaDef.inc }

{$IFDEF DEBUG }
  //
  {$DEFINE LOG_GSM_INFOS }	// log informational messages
  {$DEFINE LOG_GSM_ERRORS }	// log critical errors
{$ENDIF DEBUG }


{$DEFINE SASR }         // Define SASR if >> is a signed arithmetic shift (-1 >> 1 == -1)
                        // Must be defined for compatibility with spec

{xx $DEFINE USE_FLOAT_MUL }      // Define if float mul is faster than integer on target hardware
                                 // NOTE: this mode was not tested yet!

{$DEFINE WAV49 }        // define to be able to handle WAV-49 encoding

{*
  GSM6.10 codec. Delphi implementation based on C-source code by Jutta Degener and Carsten Bormann

  @Author Lake
  @Version 1.0 First release
}

unit
  unaGSM;

interface

uses
  unaTypes, unaUtils, unaClasses;

{

  GSM 06.10 compresses frames of 160 13-bit samples (8 kHz sampling
  rate, i.e. a frame rate of 50 Hz) into 260 bits; for compatibility
  with typical UNIX applications, our implementation turns frames of 160
  16-bit linear samples into 33-byte frames (1650 Bytes/s).
  The quality of the algorithm is good enough for reliable speaker
  recognition; even music often survives transcoding in recognizable
  form (given the bandwidth limitations of 8 kHz sampling rate).

}

	{*	variable	size

		GSM_MAGIC	4

		LARc[0]		6
		LARc[1]		6
		LARc[2]		5
		LARc[3]		5
		LARc[4]		4
		LARc[5]		4
		LARc[6]		3
		LARc[7]		3

		Nc[0]		7
		bc[0]		2
		Mc[0]		2
		xmaxc[0]	6
		xmc[0]		3
		xmc[1]		3
		xmc[2]		3
		xmc[3]		3
		xmc[4]		3
		xmc[5]		3
		xmc[6]		3
		xmc[7]		3
		xmc[8]		3
		xmc[9]		3
		xmc[10]		3
		xmc[11]		3
		xmc[12]		3

		Nc[1]		7
		bc[1]		2
		Mc[1]		2
		xmaxc[1]	6
		xmc[13]		3
		xmc[14]		3
		xmc[15]		3
		xmc[16]		3
		xmc[17]		3
		xmc[18]		3
		xmc[19]		3
		xmc[20]		3
		xmc[21]		3
		xmc[22]		3
		xmc[23]		3
		xmc[24]		3
		xmc[25]		3

		Nc[2]		7
		bc[2]		2
		Mc[2]		2
		xmaxc[2]	6
		xmc[26]		3
		xmc[27]		3
		xmc[28]		3
		xmc[29]		3
		xmc[30]		3
		xmc[31]		3
		xmc[32]		3
		xmc[33]		3
		xmc[34]		3
		xmc[35]		3
		xmc[36]		3
		xmc[37]		3
		xmc[38]		3

		Nc[3]		7
		bc[3]		2
		Mc[3]		2
		xmaxc[3]	6
		xmc[39]		3
		xmc[40]		3
		xmc[41]		3
		xmc[42]		3
		xmc[43]		3
		xmc[44]		3
		xmc[45]		3
		xmc[46]		3
		xmc[47]		3
		xmc[48]		3
		xmc[49]		3
		xmc[50]		3
		xmc[51]		3
	*}

{Lake:

        The whole WAV49 mess started because 260 bits are 4 bit too much for a 32 bytes block,
        and 4 bit too short for a 33 bytes block.

        This implementation prefixes those 260 bit with a 4 bit "magic" value, making each frame exactly 33 bytes.

        MS combine two 260 bit frames into one 520 bit block, making it exactly 65 bytes long.

        In addition, MS store values in LSB order, while this implementation prefers MSB

}

(*
 * Copyright 1992 by Jutta Degener and Carsten Bormann, Technische
 * Universitaet Berlin.  See the accompanying file "COPYRIGHT" for
 * details.  THERE IS ABSOLUTELY NO WARRANTY FOR THIS SOFTWARE.
 *)

//*$Header: /tmp_amd/presto/export/kbs/jutta/src/gsm/RCS/private.h,v 1.6 1996/07/02 10:15:26 jutta Exp $*/

//#ifndef	PRIVATE_H
//#define	PRIVATE_H

type
  _pword        = ^_word;
  _word         = int16;
  _pwordArray   = ^_wordArray;
  _wordArray    = array[word] of _word;
  //
  _plongword    = ^_longword;
  _longword     = int32;

  //
  uword           = uint16;
  ulongword       = uint32;

  pgsm_state = ^gsm_state;
  gsm_state = record
    //
    dp0: array [0..280 - 1] of _word;
    e  : array [0.. 50 - 1] of _word;           //* code.c 			*/
    //
    z1  : _word;                                //* preprocessing.c, Offset_com. */
    L_z2: _longword;                            //*                  Offset_com. */
    mp  : int32;                                //*                  Preemphasis	*/
    //
    u   : array[0..8 - 1] of _word;             //* short_term_aly_filter.c	*/
    LARpp: array[0..2 - 1, 0..8 - 1] of _word;  //*                              */
    j   : _word;                                //*                              */
    //
    //ltp_cut: _word;                             //* long_term.c, LTP crosscorr. */
    nrp : _word;                                //* long_term.c, synthesis	*/
    v   : array[0..9 - 1] of _word;             //* short_term.c, synthesis	*/
    msr : _word;                                //* decoder.c,	Postprocessing	*/
    //
    verbose: byte;                             //* only used if !NDEBUG		*/
    //fast   : byte;                             //* only used if FAST		*/
    //
    wav_fmt: byte;                             //* only used if WAV49 defined	*/
    frame_index: byte;                          //*            odd/even chaining	*/
    frame_chain: byte;	                        //*   half-byte to carry forward	*/
  end;

const
  MIN_WORD      = (-32767 - 1);
  MAX_WORD      = 32767;

  MIN_LONGWORD  = (-2147483647 - 1);
  MAX_LONGWORD  = 2147483647;

//#include "proto.h"

{*
 *	Prototypes from add.c
 *}
function _gsm_mult 	(a  : _word     ;    b     :_word     ): _word;{$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
//function gsm_L_mult 	(a  : _word     ;    b     :_word     ): _longword;{$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
//function gsm_mult_r	(a  : _word     ;    b     :_word     ): _word;{$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
function _gsm_div  	(num: _word     ;    denum :_word     ): _word;{$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
function _gsm_add 	(a  : _word     ;    b     :_word     ): _word;{$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
//function gsm_L_add 	(a  : _longword ;    b     :_longword ): _longword;{$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
function _gsm_sub 	(a  : _word     ;    b     :_word     ): _word;{$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
function gsm_L_sub 	(a  : _longword ;    b     :_longword ): _longword;{$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
//function gsm_abs 	(a  : _word                           ): _word;{$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
function _gsm_norm 	(a  : _longword                       ): _word;
function _gsm_L_asl  	(a  : _longword ;    n     :int32     ): _longword;{$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
function _gsm_asl 	(a  : _word     ;    n     :int32     ): _word;{$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
function _gsm_L_asr  	(a  : _longword ;    n     :int32     ): _longword;{$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
function _gsm_asr  	(a  : _word     ;    n     :int32     ): _word;{$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }

procedure Gsm_Coder(
		S: pgsm_state;
		_s: _pword;	//* [0..159] samples		IN	*/
{*
 * The RPE-LTD coder works on a frame by frame basis.  The length of
 * the frame is equal to 160 samples.  Some computations are done
 * once per frame to produce at the output of the coder the
 * LARc[1..8] parameters which are the coded LAR coefficients and
 * also to realize the inverse filtering operation for the entire
 * frame (160 samples of signal d[0..159]).  These parts produce at
 * the output of the coder:
 *}
		LARc: _pword;	//* [0..7] LAR coefficients	OUT	*/

{*
 * Procedure 4.2.11 to 4.2.18 are to be executed four times per
 * frame.  That means once for each sub-segment RPE-LTP analysis of
 * 40 samples.  These parts produce at the output of the coder:
 *}
		Nc: _pword;	//* [0..3] LTP lag		OUT 	*/
		bc: _pword;	//* [0..3] coded LTP gain	OUT 	*/
		Mc: _pword;	//* [0..3] RPE grid selection	OUT     */
		xmaxc: _pword;//* [0..3] Coded maximum amplitude OUT	*/
		xMc: _pword	//* [13*4] normalized RPE samples OUT	*/
                );


procedure Gsm_Long_Term_Predictor(		//* 4x for 160 samples */
		S: pgsm_state;
		d: _pword;	//* [0..39]   residual signal	IN	*/
		dp: _pword;	//* [-120..-1] d'		IN	*/
		e: _pword;	//* [0..40] 			OUT	*/
		dpp: _pword;	//* [0..40] 			OUT	*/
		Nc: _pword;	//* correlation lag		OUT	*/
		bc: _pword	//* gain factor			OUT	*/)
                );

procedure Gsm_LPC_Analysis(
		S: pgsm_state;  // not used
		_s: _pword;	 //* 0..159 signals	IN/OUT	*/
	        LARc: _pword   //* 0..7   LARc's	OUT	*/
                );

procedure Gsm_Preprocess(
		S: pgsm_state;
		_s: _pword;
                _so: _pword
                );

{
procedure Gsm_Encoding(
		S: pgsm_state;
		e: _pword;
		ep: _pword;
		xmaxc: _pword;
		Mc: _pword;
		xMc: _pword
                );
}

procedure Gsm_Short_Term_Analysis_Filter(
		S: pgsm_state;
		LARc: _pword;	//* coded log area ratio [0..7]  IN	*/
		_s: _pword	//* st res. signal [0..159]	IN/OUT	*/)
                );

procedure Gsm_Decoder(
		S: pgsm_state;
		LARcr: _pword;          //* [0..7]		IN	*/
		Ncr: _pword;		//* [0..3] 		IN 	*/
		bcr: _pword;		//* [0..3]		IN	*/
		Mcr: _pword;		//* [0..3] 		IN 	*/
		xmaxcr: _pword;	        //* [0..3]		IN 	*/
		xMcr: _pword;		//* [0..13*4]		IN	*/
		_s: _pword		//* [0..159]		OUT 	*/
                );

{
procedure Gsm_Decoding(
		S: pgsm_state;
		xmaxcr: _word;
		Mcr: _word;
		xMcr: _pword;  	        //* [0..12]		IN	*/
		erp: _pword     	//* [0..39]		OUT 	*/
                );}

procedure Gsm_Long_Term_Synthesis_Filtering(
		S: pgsm_state;
		Ncr: _word;
		bcr: _word;
		erp: _pword;            //* [0..39]		  IN 	*/
		drp: _pword 	        //* [-120..-1] IN, [0..40] OUT 	*/
                );

procedure Gsm_RPE_Decoding(
	        S: pgsm_state;
		xmaxcr: _word;
		Mcr: _word;
		xMcr: _pword;           //* [0..12], 3 bits             IN      */
		erp: _pword             //* [0..39]                     OUT     */
                );

procedure Gsm_RPE_Encoding(
		S: pgsm_state;
		e: _pword;              //* -5..-1][0..39][40..44     IN/OUT  */
		xmaxc: _pword;          //*                              OUT */
		Mc: _pword;             //*                              OUT */
		xMc: _pword             //* [0..12]                      OUT */
                );

procedure Gsm_Short_Term_Synthesis_Filter(
		S: pgsm_state;
		LARcr: _pword; 	        //* log area ratios [0..7]  IN	*/
		wt: _pword;		//* received d [0...39]	   IN	*/
		_s: _pword		//* signal   s [0..159]	  OUT	*/
                );

//* Has been inlined in code.c */
{
procedure Gsm_Update_of_reconstructed_short_time_residual_signal(
		dpp: _pword;	        //* [0...39]	IN	*/
		ep: _pword;		//* [0...39]	IN	*/
		dp: _pword		//* [-120...-1]  IN/OUT 	*/
                );
}

{*
 *  Tables from table.c
 *}
//#ifndef	GSM_TABLE_C

const
//*  Table 4.1  Quantization of the Log.-Area Ratios
//* i 		                             1      2      3        4      5      6        7       8 */
  gsm_A: array[0..8 - 1] of _word =     (20480, 20480, 20480,  20480,  13964,  15360,   8534,  9036);
  gsm_B: array[0..8 - 1] of _word =     (    0,     0,  2048,  -2560,     94,  -1792,   -341, -1144);
  gsm_MIC: array[0..8 - 1] of _word =   (  -32,   -32,   -16,    -16,     -8,     -8,     -4,    -4 );
  gsm_MAC: array[0..8 - 1] of _word =   (   31,    31,    15,     15,      7,      7,      3,     3 );

//*  Table 4.2  Tabulation  of 1/A[1..8]
  gsm_INVA: array[0..8 - 1] of _word =   ( 13107, 13107,  13107, 13107,  19223, 17476,  31454, 29708);

//*   Table 4.3a  Decision level of the LTP gain quantizer
//*  bc		      0	        1	  2	     3			*/
  gsm_DLB: array[0..4 - 1] of _word =   (  6554,    16384,	26214,	   32767	);

//*   Table 4.3b   Quantization levels of the LTP gain quantizer
//* bc		      0          1        2          3			*/
  gsm_QLB: array[0..4 - 1] of _word =   (  3277,    11469,	21299,	   32767	);

//*   Table 4.4	 Coefficients of the weighting filter
//* i		    0      1   2    3   4      5      6     7   8   9    10  */
  gsm_H: array[0..11 - 1] of _word =    (-134, -374, 0, 2054, 5741, 8192, 5741, 2054, 0, -374, -134);

//*   Table 4.5 	 Normalized inverse mantissa used to compute xM/xmax
//* i		 	0        1    2      3      4      5     6      7   */
  gsm_NRFAC: array[0..8 - 1] of _word = ( 29128, 26215, 23832, 21846, 20165, 18725, 17476, 16384);

//*   Table 4.6	 Normalized direct mantissa used to compute xM/xmax
//* i                  0      1       2      3      4      5      6      7   */
  gsm_FAC: array[0..8 - 1] of _word =   ( 18431, 20479, 22527, 24575, 26623, 28671, 30719, 32767);

//#endif	/* GSM_TABLE_C */


//#endif	/* PRIVATE_H */



(*
 * Copyright 1992 by Jutta Degener and Carsten Bormann, Technische
 * Universitaet Berlin.  See the accompanying file "COPYRIGHT" for
 * details.  THERE IS ABSOLUTELY NO WARRANTY FOR THIS SOFTWARE.
 *)

//*$Header: /home/kbs/jutta/src/gsm/gsm-1.0/inc/RCS/gsm.h,v 1.11 1996/07/05 18:02:56 jutta Exp $*/

//#ifndef	GSM_H
//#define	GSM_H

{
#ifdef __cplusplus
#	define	NeedFunctionPrototypes	1
#endif

#if __STDC__
#	define	NeedFunctionPrototypes	1
#endif

#ifdef _NO_PROTO
#	undef	NeedFunctionPrototypes
#endif

#ifdef NeedFunctionPrototypes
#   include	<stdio.h>		/* for FILE * 	*/
#endif

#undef GSM_P
#if NeedFunctionPrototypes
#	define	GSM_P( protos )	protos
#else
#	define  GSM_P( protos )	( /* protos */ )
#endif
}

//*
// *	Interface
// */

type
  gsm           = pgsm_state;
  //
  pgsm_signal   = ^gsm_signal;
  gsm_signal    = int16;
  //
  pgsm_byte     = ^gsm_byte;
  gsm_byte      = byte;
  //
  gsm_frame     = array[0..33 - 1] of gsm_byte; //* 33 * 8 bits	 */

const
  GSM_MAGIC		= $D;		  	//* 13 kbit/s RPE-LTP */  1101

  GSM_PATCHLEVEL	= 10;
  GSM_MINOR		= 0;
  GSM_MAJOR		= 1;

  GSM_OPT_VERBOSE	= 1;
  GSM_OPT_FAST		= 2;    // not supported
  GSM_OPT_LTP_CUT	= 3;    // not supported
  GSM_OPT_WAV49		= 4;
  GSM_OPT_FRAME_INDEX	= 5;
  GSM_OPT_FRAME_CHAIN	= 6;

function gsm_create(): gsm;
procedure gsm_destroy(g: gsm);

//function gsm_print   (FILE *, gsm, gsm_byte  *): int32;
function gsm_option  (g: gsm; opt: int32; val: pInt32): int32;

procedure gsm_encode  (s: gsm; source: pgsm_signal; c: pgsm_byte);
function  gsm_decode  (s: gsm; c: pgsm_byte; target: pgsm_signal): int32;

//function  gsm_explode (gsm, gsm_byte   *, gsm_signal *): int32;
//procedure gsm_implode (gsm, gsm_signal *, gsm_byte   *);

//#endif	/* GSM_H */


function SASR(v: _word; c: int): _word; overload; {$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
function SASR(v: _longword; c: int): _longword; overload; {$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
//
function GSM_MULT_R(a, b: _word): _word;{$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
function GSM_MULT(a, b: _word): _word;{$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
function GSM_L_MULT(a, b: _longword): _longword;{$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
function GSM_L_ADD(a, b: _longword): _longword;{$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
function GSM_ADD(a, b: _word): _word;{$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
function GSM_SUB(a, b: _word): _word;{$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
function GSM_ABS(a: _word): _word;{$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }



// -- LoS specific --

type
  {*
  }
  unaGSMcoder = class(unaObject)
  private
    f_gsm: pgsm_state;
    f_frameSizeIn: int;
    f_frameSizeOut: int;
    //
    f_stream: unaMemoryStream;
    f_buf: pointer;
    f_bufSize: int;
    //
    function getOpt(opt: int32): int32;
    procedure setOpt(opt: int32; value: int32);
    //
    function lockBuf(size: int): pointer;
    procedure unlockBuf(buf: pointer);
  protected
    {*
        There is stuff we must know for sure, like frame sizes.
    }
    procedure initCoder(); virtual; abstract;
    {*
        Each processing is specific and thus must be overrided.

        @param len is guaranted to be at least one frame, or more integer number of frames
    }
    procedure processFrames(data: pointer; len: int); virtual; abstract;
    //
    {*
        Override to be notified of new data from coder.
    }
    procedure onNewData(sender: unaObject; data: pointer; len: int); virtual;
  public
    constructor create(isWav49: bool = false);
    destructor Destroy(); override;
    //
    {*
        Pass new portion of data to encoder/decoder.
        Output frames will be notified via onNewData() mehtod

        @return number of bytes processed in this write
    }
    function write(data: pointer; len: int): int;
    //
    {*
        Size of input frame in bytes.

        For encoder it should be 160*2 = 320 bytes
        For WAV49 encoder it should be 160*2*2 = 640 bytes
        //
        For decoder it should be 33
        For WAV49 encoder it should be 65
    }
    property frameSizeIn: int read f_frameSizeIn;
    {*
        Size of output frame in bytes.

        For encoder it should be 33
        For WAV49 encoder it should be 65
        //
        For decoder it should be 160*2 = 320 bytes
        For WAV49 encoder it should be 160*2*2 = 640 bytes
    }
    property frameSizeOut: int read f_frameSizeOut;
    {*
        GSM options, see GSM_OPT_XXX for index values
    }
    property gsmOpt[opt: int32]: int32 read getOpt write setOpt;
  end;


  {*
        GSM Encoder
  }
  unaGSMEncoder = class(unaGSMcoder)
  protected
    procedure initCoder(); override;
    procedure processFrames(data: pointer; len: int); override;
  end;

  {*
        GSM Decoder
  }
  unaGSMDecoder = class(unaGSMcoder)
  protected
    procedure initCoder(); override;
    procedure processFrames(data: pointer; len: int); override;
  end;


implementation


{$IFDEF SASR }	//* flag: >> is a signed arithmetic shift right */

// --  --
function SASR(v: _word; c: int): _word;
begin
  result := sshr(v, c);
end;

// --  --
function SASR(v: _longword; c: int): _longword;
begin
  result := sshr(v, c);
end;

{$ELSE }

// --  --
function SASR(v: _word; c: int): _word;
begin
  result := v shr c;
end;

// --  --
function SASR(v: _longword; c: int): _longword;
begin
  result := v shr c;
end;

{$ENDIF SASR }	//* flag: >> is a signed arithmetic shift right */



{*
 *  Inlined functions from add.h
 *}

//* word a, word b, !(a == b == MIN_WORD) */	\
function GSM_MULT_R(a, b: _word): _word;
begin
  result := _word(SASR( _longword(a) * _longword(b) + 16384, 15));
end;

//* word a, word b, !(a == b == MIN_WORD) */	\
function GSM_MULT(a, b: _word): _word;
begin
  result := _word(SASR( _longword(a) * _longword(b), 15));
end;

//* word a, word b */	\
function GSM_L_MULT(a, b: _longword): _longword;
begin
  result := sshl(a * b, 1);
end;

// --  --
function GSM_L_ADD(a, b: _longword): _longword;
{
# define GSM_L_ADD(a, b)	\
	( (a) <  0 ? ( (b) >= 0 ? (a) + (b)	\
		 : (utmp = (ulongword)-((a) + 1) + (ulongword)-((b) + 1)) \
		   >= MAX_LONGWORD ? MIN_LONGWORD : -(longword)utmp-2 )   \
	: ((b) <= 0 ? (a) + (b)   \
	          : (utmp = (ulongword)(a) + (ulongword)(b)) >= MAX_LONGWORD \
		    ? MAX_LONGWORD : utmp))
}
var
  utmp: ulongword;
begin
  if (a <  0) then begin
    //
    if (b >= 0) then
      result := a + b
    else begin
      //
      utmp := ulongword(-(a + 1)) + ulongword(-(b + 1));
      if (utmp >= MAX_LONGWORD) then
        result := MIN_LONGWORD
      else
        result := -_longword(utmp) - 2;
    end;
  end
  else begin
    //
    if (b <= 0) then
      result := a + b
    else begin
      //
      utmp := ulongword(a) + ulongword(b);
      if (utmp >= MAX_LONGWORD) then
        result := MAX_LONGWORD
      else
        result := _longword(utmp);
    end;
  end;
end;

// --  --
function GSM_ADD(a, b: _word): _word;
var
  ltmp: _longword;
begin
//	((ulongword)((ltmp = (longword)(a) + (longword)(b)) - MIN_WORD) > MAX_WORD - MIN_WORD ? (ltmp > 0 ? MAX_WORD : MIN_WORD) : ltmp)
  ltmp := _longword(a) + _longword(b);
  if (ltmp < MIN_WORD) then
    result := MIN_WORD
  else
    if (ltmp > MAX_WORD) then
      result := MAX_WORD
    else
      result := _word(ltmp);
end;

// --  --
function GSM_SUB(a, b: _word): _word;
var
  ltmp: _longword;
begin
  ltmp := _longword(a) - _longword(b);
  if (ltmp >= MAX_WORD) then
    result := MAX_WORD
  else begin
    //
    if (ltmp <= MIN_WORD) then
      result := MIN_WORD
    else
      result := _word(ltmp);
  end;
end;

// --  --
function GSM_ABS(a: _word): _word;
begin
  if (a < 0) then begin
    //
    if (MIN_WORD = a) then
      result := MAX_WORD
    else
      result := -a;
  end
  else
    result := a;
end;

// --  --
function _gsm_mult 	(a  : _word     ;    b     :_word     ): _word;
begin
  if ((MIN_WORD = a) and (MIN_WORD = b)) then
    result := MAX_WORD
  else
    result := SASR( _longword(a) * _longword(b), 15 );
end;

// --  --
function _gsm_div(num: _word; denum :_word): _word;
var
  L_num: _longword;
  L_denum: _longword;
  _div: _word;
  k: int;
begin
  L_num := num;
  L_denum := denum;
  _div 	:= 0;
  k 	:= 15;
  //
  {* The parameter num sometimes becomes zero.
   * Although this is explicitly guarded against in 4.2.5,
   * we assume that the result should then be zero as well.
  *}
  //
  //* assert(num != 0); */
  //
  assert((num >= 0) and (denum >= num));
  //
  if (0 = num) then
    result := 0
  else begin
    //
    while (0 < k) do begin
      //
      dec(k);
      _div := sshl(_div, 1);
      L_num := sshl (L_num, 1);
      //
      if (L_num >= L_denum) then begin
        //
	dec(L_num, L_denum);
	inc(_div);
      end;
    end;
    //
    result := _div;
  end;
end;

// --  --
function _gsm_add(a, b: _word): _word;
var
  sum: _longword;
begin
  sum := _longword(a) + _longword(b);
  if sum < MIN_WORD then
    sum := MIN_WORD
  else
    if (sum > MAX_WORD) then
      sum := MAX_WORD;
  //
  result := sum;
end;

// --  --
function _gsm_sub 	(a  : _word     ;    b     :_word     ): _word;
var
  diff: _longword;
begin
  diff := _longword(a) - _longword(b);
  if diff < MIN_WORD then
    diff := MIN_WORD
  else
    if (diff > MAX_WORD) then
      diff := MAX_WORD;
  //
  result := diff;
end;

// --  --
function gsm_L_sub 	(a  : _longword ;    b     :_longword ): _longword;
var
  _A: ulongword;
begin
  if (a >= 0) then begin
    //
    if (b >= 0) then
      result := a - b
    else begin
      //* a>=0, b<0 */
      _A := ulongword(a) + ulongword(-(b + 1));
      if (_A >= MAX_LONGWORD) then
        result := MAX_LONGWORD
      else
        result := _A + 1;
    end
  end
  else begin
    //
    if (b <= 0) then
      result := a - b
    else begin
      //* a<0, b>0 */
      //
      _A := ulongword(-(a + 1)) + ulongword(b);
      if (_A >= MAX_LONGWORD) then
        result := MIN_LONGWORD
      else
        result := -1 - _longword(_A);
    end;
  end;
end;

const
  bitoff:array[0..256 - 1] of byte = (
	 8, 7, 6, 6, 5, 5, 5, 5, 4, 4, 4, 4, 4, 4, 4, 4,
	 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3,
	 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
	 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2,
	 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
	 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
	 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
	 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
	 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  );


// --  --
function _gsm_norm 	(a  : _longword                       ): _word;
{*
 * the number of left shifts needed to normalize the 32 bit
 * variable L_var1 for positive values on the interval
 *
 * with minimum of
 * minimum of 1073741824  (01000000000000000000000000000000) and
 * maximum of 2147483647  (01111111111111111111111111111111)
 *
 *
 * and for negative values on the interval with
 * minimum of -2147483648 (-10000000000000000000000000000000) and
 * maximum of -1073741824 ( -1000000000000000000000000000000).
 *
 * in order to normalize the result, the following
 * operation must be done: L_norm_var1 = L_var1 << norm( L_var1 );
 *
 * (That's 'ffs', only from the left, not the right..)
 *}
begin
  assert(a <> 0);
  //
  if (a < 0) then begin
    //
    if (a <= -1073741824) then begin
      //
      result := 0;
      exit;
    end;
    //
    a := not a;
  end;
  //
  if (0 <> a and $ffff0000) then begin
    //
    if (0 <> a and $ff000000) then
      result := -1 + _word(bitoff[ $FF and sshr(a, 24) ])
    else
      result :=  7 + _word(bitoff[ $FF and sshr(a, 16) ]);
  end
  else begin
    //
    if (0 <> a and $ff00) then
      result := 15 + bitoff[ $FF and sshr(a, 8) ]
    else
      result := 23 + bitoff[ $FF and a ];
  end;
end;

// --  --
function _gsm_L_asl  	(a  : _longword ;    n     :int32     ): _longword;
begin
  if (n >= 32) then result := 0
  else
    if (n <= -32) then
      if (a < 0) then
        result := -1
      else
        result := 0
    else
      if (n < 0) then result := _gsm_L_asr(a, -n)
      else
        result := sshl(a, n);
end;

// --  --
function _gsm_asl 	(a  : _word     ;    n     :int32     ): _word;
begin
  if (n >= 16) then result := 0
  else
    if (n <= -16) then
      if (a < 0) then
        result := -1
      else
        result := 0
    else
      if (n < 0) then result := _gsm_asr(a, -n)
      else
        result := sshl(a, n);
end;

// --  --
function _gsm_L_asr  	(a  : _longword ;    n     :int32     ): _longword;
begin
  if (n >= 32) then
    if (a < 0) then
      result := -1
    else
      result := 0
  else
    if (n <= -32) then result := 0
    else
      if (n < 0) then result := sshl(a, -n)
      else
      {$IFDEF	SASR }
        result := sshr(a, n);
      {$ELSE }
        if (a >= 0) then result := sshl(a, n)
        else
          result := -_longword( sshl(-ulongword(a), n) );
      {$ENDIF SASR }
end;

// --  --
function _gsm_asr(a  : _word     ;    n     :int32     ): _word;
begin
  if (n >= 16) then
    if (a < 0) then
      result := -1
    else
      result := 0
  else
    if (n <= -16) then result := 0
    else
      if (n < 0) then result := sshl(a, -n)
      else
      {$IFDEF	SASR }
	result := _word(sshr(a, n));
      {$ELSE }
	if (a >= 0) then result := sshr(a, n)
	else
          result :=  -_word( sshr(-uword(a), n) );
      {$ENDIF SASR }
end;


// --  --
function Wp(pw: _pword; index: int32): _pword;{$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
begin
  inc(pw, index);
  result := pw;
end;

// --  --
function Wi(pw: _pword; index: int32): _word;{$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
begin
  inc(pw, index);
  result := pw^;
end;

// --  --
function Lp(pl: _plongword; index: int32): _plongword;{$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
begin
  inc(pl, index);
  result := pl;
end;

// --  --
function Li(pl: _plongword; index: int32): _longword;{$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
begin
  inc(pl, index);
  result := pl^;
end;


{*
 *  4.2 FIXED POINT IMPLEMENTATION OF THE RPE-LTP CODER
 *}
procedure Gsm_Coder(
		S: pgsm_state;
		_s: _pword;	//* [0..159] samples		IN	*/
		LARc: _pword;	//* [0..7] LAR coefficients	OUT	*/
		Nc: _pword;	//* [0..3] LTP lag		OUT 	*/
		bc: _pword;	//* [0..3] coded LTP gain	OUT 	*/
		Mc: _pword;	//* [0..3] RPE grid selection	OUT     */
		xmaxc: _pword;//* [0..3] Coded maximum amplitude OUT	*/
		xMc: _pword	//* [13*4] normalized RPE samples OUT	*/
                );
var
  i, k: int32;
  dp: _pword;   //* [ -120...-1 ] */
  dpp: _pword;  //* [ 0...39 ]	 */
  so: array[0..160 - 1] of _word;
begin
  dp  := @S.dp0[120];	//* [ -120...-1 ] */
  dpp := dp;		//* [ 0...39 ]	 */
  //
  Gsm_Preprocess		(S, _s, _pword(@so));
  Gsm_LPC_Analysis		(S, _pword(@so), LARc);
  Gsm_Short_Term_Analysis_Filter(S, LARc, _pword(@so));
  //
  for k := 0 to 3 do begin
    //
    Gsm_Long_Term_Predictor	( S,
				  @so[k * 40],  //* d      [0..39] IN	*/
				  dp,	                //* dp  [-120..-1] IN	*/
				  @S.e[5],             //* e      [0..39] OUT	*/
				  dpp,	                //* dpp    [0..39] OUT */
				  Nc,
				  bc);
    inc(Nc);
    inc(bc);
    //
    Gsm_RPE_Encoding	( S,
			  @S.e[5],      //* e	  ][0..39][ IN/OUT */
			  xmaxc, Mc, xMc );
    inc(xmaxc);
    inc(Mc);
    //
    {*
     * Gsm_Update_of_reconstructed_short_time_residual_signal
     *			( dpp, S->e + 5, dp );
     *}
    for i := 0 to 39 do
      Wp(dp, i)^ := GSM_ADD( S.e[5 + i], Wi(dpp, i) );
    //
    inc(dp, 40);
    inc(dpp, 40);
    inc(xMc, 13);
  end;
  //
  //(void)memcpy( (char *)S->dp0, (char *)(S->dp0 + 160), 120 * sizeof( *S->dp0) );
  move(S.dp0[160], S.dp0[0], 120 * sizeof(S.dp0[0]));
end;

{*
 *  4.2.11 .. 4.2.12 LONG TERM PREDICTOR (LTP) SECTION
 *}

{*
 * This module computes the LTP gain (bc) and the LTP lag (Nc)
 * for the long term analysis filter.   This is done by calculating a
 * maximum of the cross-correlation function between the current
 * sub-segment short term residual signal d[0..39] (output of
 * the short term analysis filter; for simplification the index
 * of this array begins at 0 and ends at 39 for each sub-segment of the
 * RPE-LTP analysis) and the previous reconstructed short term
 * residual signal dp[ -120 .. -1 ].  A dynamic scaling must be
 * performed to avoid overflow.
 *}

{* The next procedure exists in six versions.  First two integer
  * version (if USE_FLOAT_MUL is not defined); then four floating
  * point versions, twice with proper scaling (USE_FLOAT_MUL defined),
  * once without (USE_FLOAT_MUL and FAST defined, and fast run-time
  * option used).  Every pair has first a Cut version (see the -C
  * option to toast or the LTP_CUT option to gsm_option()), then the
  * uncut one.  (For a detailed explanation of why this is altogether
  * a bad idea, see Henry Spencer and Geoff Collyer, ``#ifdef Considered
  * Harmful''.)
  *}

// Lake: FAST and CUT versions was cut off (and that was really fast!)

{$IFNDEF USE_FLOAT_MUL }

// integer
procedure Calculation_of_the_LTP_parameters(
	d: _pword;	//* [0..39]	IN	*/
	dp: _pword;	//* [-120..-1]	IN	*/
	bc_out: _pword;	//* 		OUT	*/
	Nc_out: _pword	//* 		OUT	*/
);
var
  lambda: int32;
  wt: array[0..40 - 1] of _word;

  {
  function STEP(k: int32): _longword;
  begin
    result := _longword(wt[k]) * Wi(dp, k - lambda);
  end;
  }

  //
var
  k: int32;
  Nc, bc: _word;
  L_max, L_power: _longword;
  R, S, dmax, scal: _word;
  temp: _word;
  L_result: _longword;
  L_temp: _longword;
begin
  //*  Search of the optimum scaling of d[0..39]. */
  dmax := 0;
  //
  for k := 0 to 39 do begin
    //
    temp := GSM_ABS( Wi(d, k) );
    if (temp > dmax) then
      dmax := temp;
  end;
  //
  temp := 0;
  if (0 = dmax) then //scal := 0
  else begin
    //
    assert(dmax > 0);
    temp := _gsm_norm( sshl(dmax, 16) );
  end;
  //
  if (temp > 6) then scal := 0
  else
    scal := 6 - temp;
  //
  assert(scal >= 0);
  //
  //*  Initialization of a working array wt */
  for k := 0 to 39 do wt[k] := SASR( Wi(d, k), scal );
  //
  //* Search for the maximum cross-correlation and coding of the LTP lag */
  L_max := 0;
  Nc    := 40;	//* index for the maximum cross-correlation */
  //
  for lambda := 40 to 120 do begin
    //
    L_result   := _longword(wt[0]) * Wi(dp, 0 - lambda);
    for k := 1 to 39 do
      inc(L_result, _longword(wt[k]) * Wi(dp, k - lambda));
{
     inc(L_result, STEP( 1));
    inc(L_result, STEP( 2)); inc(L_result, STEP( 3));
    inc(L_result, STEP( 4)); inc(L_result, STEP( 5));
    inc(L_result, STEP( 6)); inc(L_result, STEP( 7));
    inc(L_result, STEP( 8)); inc(L_result, STEP( 9));
    inc(L_result, STEP(10)); inc(L_result, STEP(11));
    inc(L_result, STEP(12)); inc(L_result, STEP(13));
    inc(L_result, STEP(14)); inc(L_result, STEP(15));
    inc(L_result, STEP(16)); inc(L_result, STEP(17));
    inc(L_result, STEP(18)); inc(L_result, STEP(19));
    inc(L_result, STEP(20)); inc(L_result, STEP(21));
    inc(L_result, STEP(22)); inc(L_result, STEP(23));
    inc(L_result, STEP(24)); inc(L_result, STEP(25));
    inc(L_result, STEP(26)); inc(L_result, STEP(27));
    inc(L_result, STEP(28)); inc(L_result, STEP(29));
    inc(L_result, STEP(30)); inc(L_result, STEP(31));
    inc(L_result, STEP(32)); inc(L_result, STEP(33));
    inc(L_result, STEP(34)); inc(L_result, STEP(35));
    inc(L_result, STEP(36)); inc(L_result, STEP(37));
    inc(L_result, STEP(38)); inc(L_result, STEP(39));
}
    //
    if (L_result > L_max) then begin
      //
      Nc    := lambda;
      L_max := L_result;
    end;
  end;
  //
  Nc_out^ := Nc;
  //
  L_max := sshl(L_max, 1);
  //
  //*  Rescaling of L_max  */
  assert((scal <= 100) and (scal >=  -100));
  L_max := sshr(L_max, (6 - scal));	//* sub(6, scal) */
  assert( (Nc <= 120) and (Nc >= 40) );
  //
  //*   Compute the power of the reconstructed short term residual signal dp[..] */
  L_power := 0;
  for k := 0 to 39 do begin
    //
    L_temp := SASR( Wi(dp, k - Nc), 3 );
    inc(L_power, L_temp * L_temp);
  end;
  L_power := sshl(L_power, 1);	//* from L_MULT */
  //
  //*  Normalization of L_max and L_power */
  //
  if (L_max <= 0)  then
    bc_out^ := 0
  else
    if (L_max >= L_power) then
      bc_out^ := 3
    else begin
      //
      temp := _gsm_norm( L_power );
      //
      R := SASR( sshl(L_max, temp), 16 );
      S := SASR( sshl(L_power, temp), 16 );
      //
      //*  Coding of the LTP gain */
      {*  Table 4.3a must be used to obtain the level DLB[i] for the
       *  quantization of the LTP gain b to get the coded version bc.
       *}
      for bc := 0 to 2 do
        if (R <= _gsm_mult(S, gsm_DLB[bc])) then
          break;
      //
      bc_out^ := bc;
    end;
end;

{$ELSE }

// --  --
function Fp(pf: pFloat; index: int32): pFloat;{$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
begin
  inc(pf, index);
  result := pf;
end;

// --  --
function Fi(pf: pFloat; index: int32): float;{$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
begin
  inc(pf, index);
  result := pf^;
end;

// Lake: If for some strange reason your hardware loves floats, use this one instead:
type
  stepargs = record
    lp: pFloat;
    wt_float: array[0..40 - 1] of float;
    W: float;
    E: float;
    S0, S1, S2, S3, S4, S5, S6, S7, S8: float;
  end;

// --  --
procedure STEP(K: int32; var a: float; b, c, d, e, f, g, h: float; var arg: stepargs);{$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
begin
  arg.W := Fi(pFloat(@arg.wt_float), K);
  arg.E := arg.W * a;   arg.S8 := arg.S8 + arg.E;
  arg.E := arg.W * b;   arg.S7 := arg.S7 + arg.E;
  arg.E := arg.W * c;   arg.S6 := arg.S6 + arg.E;
  arg.E := arg.W * d;   arg.S5 := arg.S5 + arg.E;
  arg.E := arg.W * e;   arg.S4 := arg.S4 + arg.E;
  arg.E := arg.W * f;   arg.S3 := arg.S3 + arg.E;
  arg.E := arg.W * g;   arg.S2 := arg.S2 + arg.E;
  arg.E := arg.W * h;   arg.S1 := arg.S1 + arg.E;
  a := Fi(arg.lp, K);
  arg.E := arg.W * a;   arg.S0 := arg.S0 + arg.E;
end;

// --  --
procedure STEP_A(K: int32; var a: float; b, c, d, e, f, g, h: float; var arg: stepargs);{$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
begin
  STEP(K, a, b, c, d, e, f, g, h, arg);
end;
procedure STEP_B(K: int32; var a: float; b, c, d, e, f, g, h: float; var arg: stepargs);{$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
begin
  STEP(K, b, c, d, e, f, g, h, a, arg);
end;
procedure STEP_C(K: int32; var a: float; b, c, d, e, f, g, h: float; var arg: stepargs);{$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
begin
  STEP(K, c, d, e, f, g, h, a, b, arg);
end;
procedure STEP_D(K: int32; var a: float; b, c, d, e, f, g, h: float; var arg: stepargs);{$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
begin
  STEP(K, d, e, f, g, h, a, b, c, arg);
end;
procedure STEP_E(K: int32; var a: float; b, c, d, e, f, g, h: float; var arg: stepargs);{$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
begin
  STEP(K, e, f, g, h, a, b, c, d, arg);
end;
procedure STEP_F(K: int32; var a: float; b, c, d, e, f, g, h: float; var arg: stepargs);{$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
begin
  STEP(K, f, g, h, a, b, c, d, e, arg);
end;
procedure STEP_G(K: int32; var a: float; b, c, d, e, f, g, h: float; var arg: stepargs);{$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
begin
  STEP(K, g, h, a, b, c, d, e, f, arg);
end;
procedure STEP_H(K: int32; var a: float; b, c, d, e, f, g, h: float; var arg: stepargs);{$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
begin
  STEP(K, h, a, b, c, d, e, f, g, arg);
end;

procedure Calculation_of_the_LTP_parameters(
	d: _pword;	//* [0..39]	IN	*/
	dp: _pword;	//* [-120..-1]	IN	*/
	bc_out: _pword;	//* 		OUT	*/
	Nc_out: _pword	//* 		OUT	*/
);
var
  k, lambda: int32;
  Nc, bc: _word;
  //
  dp_float_base: array[0..120 - 1] of float;
  dp_float: pFloat;
  //
  L_max, L_power: _longword;
  R, S, dmax, scal: _word;
  temp: _word;
  //
  a, b, c, __d, e, f, g, h: float;
  sv: stepargs;
  //
  L_temp: _longword;
begin
  dp_float := @dp_float_base[120 - 1];
  inc(dp_float);
  //
  //*  Search of the optimum scaling of d[0..39]. */
  dmax := 0;
  //
  for k := 0 to 39 do begin
    //
    temp := Wi(d, k);
    temp := GSM_ABS(temp);
    if (temp > dmax) then
      dmax := temp;
  end;
  //
  temp := 0;
  if (0 = dmax) then //scal := 0
  else begin
    //
    assert(dmax > 0);
    temp := _gsm_norm( _longword(sshl(dmax, 16)) );
  end;
  //
  if (temp > 6) then scal := 0
  else
    scal := 6 - temp;
  //
  assert(scal >= 0);
  //
  //*  Initialization of a working array wt */
  for k :=    0 to 40 - 1 do sv.wt_float[k] := SASR( Wi(d, k), scal );
  for k := -120 to  0 - 1 do Fp(dp_float, k)^ := Wi(dp, k);
  //
  //* Search for the maximum cross-correlation and coding of the LTP lag */
  L_max := 0;
  Nc    := 40;	//* index for the maximum cross-correlation */
  //
  lambda := 40;
  while (lambda <= 120) do begin
    //
    //*  Calculate L_result for l = lambda .. lambda + 9.  */
    sv.lp := Fp(dp_float, -lambda);
    //
    a := Fi(sv.lp, -8);
    b := Fi(sv.lp, -7);
    c := Fi(sv.lp, -6);
  __d := Fi(sv.lp, -5);
    e := Fi(sv.lp, -4);
    f := Fi(sv.lp, -3);
    g := Fi(sv.lp, -2);
    h := Fi(sv.lp, -1);
    //
    sv.S0 := 0; sv.S1 := 0; sv.S2 := 0; sv.S3 := 0; sv.S4 := 0;
    sv.S5 := 0; sv.S6 := 0; sv.S7 := 0; sv.S8 := 0;
    //
    STEP_A( 0, a, b, c, __d, e, f, g, h, sv); STEP_B( 1, a, b, c, __d, e, f, g, h, sv); STEP_C( 2, a, b, c, __d, e, f, g, h, sv); STEP_D( 3, a, b, c, __d, e, f, g, h, sv);
    STEP_E( 4, a, b, c, __d, e, f, g, h, sv); STEP_F( 5, a, b, c, __d, e, f, g, h, sv); STEP_G( 6, a, b, c, __d, e, f, g, h, sv); STEP_H( 7, a, b, c, __d, e, f, g, h, sv);
    //
    STEP_A( 8, a, b, c, __d, e, f, g, h, sv); STEP_B( 9, a, b, c, __d, e, f, g, h, sv); STEP_C(10, a, b, c, __d, e, f, g, h, sv); STEP_D(11, a, b, c, __d, e, f, g, h, sv);
    STEP_E(12, a, b, c, __d, e, f, g, h, sv); STEP_F(13, a, b, c, __d, e, f, g, h, sv); STEP_G(14, a, b, c, __d, e, f, g, h, sv); STEP_H(15, a, b, c, __d, e, f, g, h, sv);
    //
    STEP_A(16, a, b, c, __d, e, f, g, h, sv); STEP_B(17, a, b, c, __d, e, f, g, h, sv); STEP_C(18, a, b, c, __d, e, f, g, h, sv); STEP_D(19, a, b, c, __d, e, f, g, h, sv);
    STEP_E(20, a, b, c, __d, e, f, g, h, sv); STEP_F(21, a, b, c, __d, e, f, g, h, sv); STEP_G(22, a, b, c, __d, e, f, g, h, sv); STEP_H(23, a, b, c, __d, e, f, g, h, sv);
    //
    STEP_A(24, a, b, c, __d, e, f, g, h, sv); STEP_B(25, a, b, c, __d, e, f, g, h, sv); STEP_C(26, a, b, c, __d, e, f, g, h, sv); STEP_D(27, a, b, c, __d, e, f, g, h, sv);
    STEP_E(28, a, b, c, __d, e, f, g, h, sv); STEP_F(29, a, b, c, __d, e, f, g, h, sv); STEP_G(30, a, b, c, __d, e, f, g, h, sv); STEP_H(31, a, b, c, __d, e, f, g, h, sv);
    //
    STEP_A(32, a, b, c, __d, e, f, g, h, sv); STEP_B(33, a, b, c, __d, e, f, g, h, sv); STEP_C(34, a, b, c, __d, e, f, g, h, sv); STEP_D(35, a, b, c, __d, e, f, g, h, sv);
    STEP_E(36, a, b, c, __d, e, f, g, h, sv); STEP_F(37, a, b, c, __d, e, f, g, h, sv); STEP_G(38, a, b, c, __d, e, f, g, h, sv); STEP_H(39, a, b, c, __d, e, f, g, h, sv);
    //
    if (sv.S0 > L_max) then begin L_max := trunc(sv.S0); Nc := lambda;     end;
    if (sv.S1 > L_max) then begin L_max := trunc(sv.S1); Nc := lambda + 1; end;
    if (sv.S2 > L_max) then begin L_max := trunc(sv.S2); Nc := lambda + 2; end;
    if (sv.S3 > L_max) then begin L_max := trunc(sv.S3); Nc := lambda + 3; end;
    if (sv.S4 > L_max) then begin L_max := trunc(sv.S4); Nc := lambda + 4; end;
    if (sv.S5 > L_max) then begin L_max := trunc(sv.S5); Nc := lambda + 5; end;
    if (sv.S6 > L_max) then begin L_max := trunc(sv.S6); Nc := lambda + 6; end;
    if (sv.S7 > L_max) then begin L_max := trunc(sv.S7); Nc := lambda + 7; end;
    if (sv.S8 > L_max) then begin L_max := trunc(sv.S8); Nc := lambda + 8; end;
    //
    inc(lambda, 9);
  end;
  //
  Nc_out^ := Nc;
  //
  L_max := sshl(L_max, 1);
  //
  //*  Rescaling of L_max  */
  assert((scal <= 100) and (scal >=  -100));
  L_max := sshl(L_max, (6 - scal));	//* sub(6, scal) */
  //
  assert((Nc <= 120) and (Nc >= 40));
  //
  //*   Compute the power of the reconstructed short term residual signal dp[..]  */
  L_power := 0;
  for k := 0 to 39 do begin
    //
    L_temp  := SASR( Wi(dp, k - Nc), 3 );
    L_power := L_power + L_temp * L_temp;
  end;
  //
  L_power := sshl(L_power, 1);	//* from L_MULT */
  //
  //*  Normalization of L_max and L_power */
  //
  if (L_max <= 0) then
          bc_out^ := 0
  else
    if (L_max >= L_power) then
      bc_out^ := 3
    else begin
      //
      temp := _gsm_norm( L_power );
      //
      R := SASR(sshl(L_max, temp),   16);
      S := SASR(sshl(L_power, temp), 16);
      //
      //*  Coding of the LTP gain */
      //
      {*  Table 4.3a must be used to obtain the level DLB[i] for the
       *  quantization of the LTP gain b to get the coded version bc.
       *}
      for bc := 0 to 2 do
        if (R <= _gsm_mult(S, gsm_DLB[bc])) then
          break;
      //
      bc_out^ := bc;
    end;
end;

{$ENDIF USE_FLOAT_MUL }


//* 4.2.12 */

// --  --
procedure Long_term_analysis_filtering(
	bc: _word;	//* 					IN  */
	Nc: _word;      //* 					IN  */
	dp: _pword;	//* previous d	[-120..-1]		IN  */
	d: _pword;	//* d		[0..39]			IN  */
	dpp: _pword;	//* estimate	[0..39]			OUT */
	e: _pword	//* long term res. signal [0..39]	OUT */
);
{*
 *  In this part, we have to decode the bc parameter to compute
 *  the samples of the estimate dpp[0..39].  The decoding of bc needs the
 *  use of table 4.3b.  The long term residual signal e[0..39]
 *  is then calculated to be fed to the RPE encoding section.
 *}

  procedure STEP(BP: int32);
  var
    k: int32;
  begin
    for k := 0 to 39 do begin
      //
      Wp(dpp, k)^ := GSM_MULT_R( BP,       Wi(dp, k - Nc) );
      Wp(e, k)^   := GSM_SUB   ( Wi(d, k), Wi(dpp, k)     );
    end;
  end;

begin
  case (bc) of
    0: STEP(  3277 );
    1: STEP( 11469 );
    2: STEP( 21299 );
    3: STEP( 32767 );
  end;
end;

// --  --
procedure Gsm_Long_Term_Predictor(      //* 4x for 160 samples */
		S: pgsm_state;
		d: _pword;	//* [0..39]   residual signal	IN	*/
		dp: _pword;	//* [-120..-1] d'		IN	*/
		e: _pword;	//* [0..40] 			OUT	*/
		dpp: _pword;	//* [0..40] 			OUT	*/
		Nc: _pword;	//* correlation lag		OUT	*/
		bc: _pword	//* gain factor			OUT	*/)
);
begin
  assert(nil <> d  ); assert(nil <> dp); assert(nil <> e );
  assert(nil <> dpp); assert(nil <> Nc); assert(nil <> bc);
  //
  Calculation_of_the_LTP_parameters(d, dp, bc, Nc);
  Long_term_analysis_filtering( bc^, Nc^, dp, d, dpp, e );
end;


//* 4.3.2 */
procedure Gsm_Long_Term_Synthesis_Filtering(
		S: pgsm_state;
		Ncr: _word;
		bcr: _word;
		erp: _pword;            //* [0..39]		  IN 	*/
		drp: _pword 	        //* [-120..-1] IN, [0..40] OUT 	*/
);
{*
 *  This procedure uses the bcr and Ncr parameter to realize the
 *  long term synthesis filtering.  The decoding of bcr needs
 *  table 4.3b.
 *}
var
//  ltmp: _longword;	//* for ADD */
  k: int32;
  brp, drpp, Nr: _word;
begin
  //*  Check the limits of Nr. */
  if ( (Ncr < 40) or (Ncr > 120) ) then
    Nr := S.nrp
  else
    Nr := Ncr;
  //
  S.nrp := Nr;
  assert( (Nr >= 40) and (Nr <= 120) );

  //*  Decoding of the LTP gain bcr */
  brp := gsm_QLB[ bcr ];

  //*  Computation of the reconstructed short term residual signal drp[0..39]  */
  assert(brp <> MIN_WORD);
  for k := 0 to 39 do begin
    //
    drpp        := GSM_MULT_R( brp, Wi(drp, k - Nr) );
    Wp(drp, k)^ := GSM_ADD( Wi(erp, k), drpp );
  end;
  {*
   *  Update of the reconstructed short term residual signal
   *  drp[ -1..-120 ]
   *}
  for k := 0 to 119 do
    Wp(drp, -120 + k)^ := Wi(drp, -80 + k);
end;





{*
 *  4.2.4 .. 4.2.7 LPC ANALYSIS SECTION
 *}

//* 4.2.4 */
procedure Autocorrelation(
	s: _pword;		//* [0..159]	IN/OUT  */
 	L_ACF: _plongword	//* [0..8]	OUT     */
        );
{*
 *  The goal is to compute the array L_ACF[k].  The signal s[i] must
 *  be scaled in order to avoid an overflow situation.
 *}
var
  k, i: int32;
  temp, smax, scalauto: _word;
  //
  sp: _pword;
  sl: _word;

  procedure STEP(k: int32);
  begin
    Lp(L_ACF, k)^ := Li(L_ACF, k) + (_longword(sl) * Wi(sp, -k));
  end;

begin
  //*  Dynamic scaling of the array  s[0..159]  */
  //
  //*  Search for the maximum. */
  smax := 0;
  for k := 0 to 159 do begin
    //
    temp := GSM_ABS( Wi(s, k) );
    if (temp > smax) then
      smax := temp;
  end;
  //
  //*  Computation of the scaling factor. */
  if (0 = smax) then scalauto := 0
  else begin
    //
    assert(smax > 0);
    scalauto := 4 - _gsm_norm( sshl(_longword(smax), 16) ); //* sub(4,..) */
  end;
  //
  //*  Scaling of the array s[0...159] */
  if (scalauto > 0) then begin
    //
    for k := 0 to 159 do
      Wp(s, k)^ := GSM_MULT_R( Wi(s, k), 16384 shr (scalauto-1) );
  end;
  //
  //*  Compute the L_ACF[..]. */
  sp := s;
  sl := sp^;
  //
  for k := 8 downto 0 do
    Lp(L_ACF, k)^ := 0;
  //
  STEP (0);
  inc(sp); sl := sp^;
  STEP(0); STEP(1);
  inc(sp); sl := sp^;
  STEP(0); STEP(1); STEP(2);
  inc(sp); sl := sp^;
  STEP(0); STEP(1); STEP(2); STEP(3);
  inc(sp); sl := sp^;
  STEP(0); STEP(1); STEP(2); STEP(3); STEP(4);
  inc(sp); sl := sp^;
  STEP(0); STEP(1); STEP(2); STEP(3); STEP(4); STEP(5);
  inc(sp); sl := sp^;
  STEP(0); STEP(1); STEP(2); STEP(3); STEP(4); STEP(5); STEP(6);
  inc(sp); sl := sp^;
  STEP(0); STEP(1); STEP(2); STEP(3); STEP(4); STEP(5); STEP(6); STEP(7);
  //
  for i := 8 to 159 do begin
    //
    inc(sp); sl := sp^;

    STEP(0);
    STEP(1); STEP(2); STEP(3); STEP(4);
    STEP(5); STEP(6); STEP(7); STEP(8);
  end;
  //
  for k := 8 downto 0 do
    Lp(L_ACF, k)^ := sshl(Li(L_ACF, k), 1) ;

  //*   Rescaling of the array s[0..159] */
  if (scalauto > 0) then begin
    //
    assert(scalauto <= 4);
    for k := 159 downto 0 do begin
      //
      s^ := sshl(s^, scalauto);
      inc(s);
    end;
  end;
end;

//* 4.2.5 */
procedure Reflection_coefficients(
  L_ACF: _plongword;    //* 0...8	IN	*/
  r: _pword            //* 0...7	OUT 	*/
);
var
  i, m, n: int32;
  temp: _word;
//  ltmp: _longword;
  ACF: array[0..9 - 1] of _word;	//* 0..8 */
  P: array[0..9 - 1] of _word;	        //* 0..8 */
  K: array[0..9 - 1] of _word;          //* 2..8 */
begin
  //*  Schur recursion with 16 bits arithmetic. */
  if (0 = L_ACF^) then begin
    //
    for i := 7 downto 0 do begin
      //
      r^ := 0;
      inc(r);
    end;
  end
  else begin
    //
    assert( 0 <> L_ACF^ );
    temp := _gsm_norm( L_ACF^ );
    assert( (temp >= 0) and (temp < 32) );
    //
    //* ? overflow ? */
    for i := 0 to 8 do
      ACF[i] := SASR( sshl(Li(L_ACF, i), temp), 16 );
    //
    //*   Initialize array P[..] and K[..] for the recursion.  */
    //
    for i := 1 to 7 do K[i] := ACF[i];
    for i := 0 to 8 do P[i] := ACF[i];
    //
    //*   Compute reflection coefficients */
    for n := 1 to 8 do begin
      //
      temp := GSM_ABS(P[1]);
      if (P[0] < temp) then begin
        //
        for i := n to 8 do begin
          //
          r^ := 0;
          inc(r);
        end;
        //
        exit;
      end;
      //
      r^ := _gsm_div( temp, P[0]);
      //
      assert( r^ >= 0);
      if (P[1] > 0) then
        r^ := -r^;		//* r[n] = sub(0, r[n]) */
      //
      assert (MIN_WORD <> r^);
      if (8 = n) then exit;
      //
      //*  Schur recursion */
      temp := GSM_MULT_R( P[1], r^ );
      P[0] := GSM_ADD( P[0], temp );
      //
      for m := 1 to 8 - n do begin
        //
        temp := GSM_MULT_R( K[ m   ],    r^ );
        P[m] := GSM_ADD(    P[ m+1 ],  temp );

        temp := GSM_MULT_R( P[ m+1 ],    r^ );
        K[m] := GSM_ADD(    K[ m   ],  temp );
      end;
      //
      inc(r);
    end;
  end;
end;

//* 4.2.6 */
procedure Transformation_to_Log_Area_Ratios(
	r: _pword      //* 0..7	   IN/OUT */
);
{*
 *  The following scaling for r[..] and LAR[..] has been used:
 *
 *  r[..]   = integer( real_r[..]*32768. ); -1 <= real_r < 1.
 *  LAR[..] = integer( real_LAR[..] * 16384 );
 *  with -1.625 <= real_LAR <= 1.625
 *}
var
  temp: _word;
  i: int32;
begin
  //* Computation of the LAR[0..7] from the r[0..7] */
  for i := 1 to 8 do begin
    //
    temp := GSM_ABS(r^);
    assert(temp >= 0);
    //
    if (temp < 22118) then temp := sshr(temp, 1)
    else
      if (temp < 31130) then begin
        //
        assert( temp >= 11059 );
        temp := temp - 11059;
      end
      else begin
        //
        assert( temp >= 26112 );
        temp := temp - 26112;
        temp := sshl(temp, 2);
      end;
    //
    if (r^ < 0) then r^ := -temp
    else
      r^ := temp;
    assert( MIN_WORD <> r^ );
    //
    inc(r);
  end;
end;

//* 4.2.7 */
procedure Quantization_and_coding(
	LAR: _pword    //* [0..7]	IN/OUT	*/
);

  procedure STEP( A, B, MAC, MIC: _word );
  var
    temp: _word;
  begin
    temp := GSM_MULT( A,   LAR^ );
    temp := GSM_ADD(  temp,   B );
    temp := GSM_ADD(  temp, 256 );
    temp := SASR(     temp,   9 );
    //
    if (temp > MAC) then
      LAR^  := MAC - MIC
    else
      if (temp < MIC) then
        LAR^ := 0
      else
        LAR^ := temp - MIC;
    //
    inc(LAR);
  end;

begin
  {*  This procedure needs four tables; the following equations
	 *  give the optimum scaling for the constants:
	 *
	 *  A[0..7] = integer( real_A[0..7] * 1024 )
	 *  B[0..7] = integer( real_B[0..7] *  512 )
	 *  MAC[0..7] = maximum of the LARc[0..7]
	 *  MIC[0..7] = minimum of the LARc[0..7]
  *}
  STEP(  20480,     0,  31, -32 );
  STEP(  20480,     0,  31, -32 );
  STEP(  20480,  2048,  15, -16 );
  STEP(  20480, -2560,  15, -16 );

  STEP(  13964,    94,   7,  -8 );
  STEP(  15360, -1792,   7,  -8 );
  STEP(   8534,  -341,   3,  -4 );
  STEP(   9036, -1144,   3,  -4 );
end;

// --  --
procedure Gsm_LPC_Analysis(
		S: pgsm_state;
		_s: _pword;	 //* 0..159 signals	IN/OUT	*/
	        LARc: _pword   //* 0..7   LARc's	OUT	*/
);
var
  L_ACF: array[0..9 - 1] of _longword;
begin
  Autocorrelation(_s, _plongword(@L_ACF));
  Reflection_coefficients(_plongword(@L_ACF), LARc);
  Transformation_to_Log_Area_Ratios(LARc);
  Quantization_and_coding(LARc);
end;



{*	4.2.0 .. 4.2.3	PREPROCESSING SECTION
 *
 *  	After A-law to linear conversion (or directly from the
 *   	Ato D converter) the following scaling is assumed for
 * 	input to the RPE-LTP algorithm:
 *
 *      in:  0.1.....................12
 *	     S.v.v.v.v.v.v.v.v.v.v.v.v.*.*.*
 *
 *	Where S is the sign bit, v a valid bit, and * a "don't care" bit.
 * 	The original signal is called sop[..]
 *
 *      out:   0.1................... 12
 *	     S.S.v.v.v.v.v.v.v.v.v.v.v.v.0.0
 *}
procedure Gsm_Preprocess(
		S: pgsm_state;
		_s: _pword;
                _so: _pword              //* [0..159] 	IN/OUT	*/
);
var
  z1: _word;
  L_z2: _longword;
  mp: _word;
  //
  s1: _word;
  L_s2: _longword;
  L_temp: _longword;
  msp, lsp: _word;
  SO: _word;
  //
//  ltmp: _longword;		//* for   ADD */
//  utmp: ulongword;		//* for L_ADD */
  k: int32;
begin
  z1 := S.z1;
  L_z2 := S.L_z2;
  mp := S.mp;
  //
  k := 160;
  while (0 < k) do begin
    //
    dec(k);
    //
    //*  4.2.1   Downscaling of the input signal */
    SO := sshl(SASR(_s^, 3 ), 2);
    inc(_s);
    //
    assert (SO >= -$4000);	//* downscaled by     */
    assert (SO <=  $3FFC);	//* previous routine. */
    //
    {*  4.2.2   Offset compensation
     *
     *  This part implements a high-pass filter and requires extended
     *  arithmetic precision for the recursive part of this filter.
     *  The input of this procedure is the array so[0...159] and the
     *  output the array sof[ 0...159 ].
     *}
    //*   Compute the non-recursive part  */
    //
    s1 := SO - z1;			//* s1 = gsm_sub( *so, z1 ); */
    z1 := SO;
    //
    assert(MIN_WORD <> s1);

    //*   Compute the recursive part */
    L_s2 := sshl(s1, 15);
    //
    //*   Execution of a 31 bv 16 bits multiplication */
    //
    msp := SASR( L_z2, 15 );
    lsp := L_z2 - (sshl(_longword(msp), 15)); //* gsm_L_sub(L_z2,(msp<<15)); */
    //
    L_s2  := L_s2 + GSM_MULT_R( lsp, 32735 );
    L_temp := _longword(msp) * 32735; //* GSM_L_MULT(msp,32735) >> 1;*/
    L_z2  := GSM_L_ADD( L_temp, L_s2 );

    //*    Compute sof[k] with rounding */
    L_temp := GSM_L_ADD( L_z2, 16384 );

    //*   4.2.3  Preemphasis */
    msp   := GSM_MULT_R( mp, -28180 );
    mp    := SASR( L_temp, 15 );
    _so^ := GSM_ADD( mp, msp );
    inc(_so);
  end;
  //
  S.z1   := z1;
  S.L_z2 := L_z2;
  S.mp   := mp;
end;


{*
 *  SHORT TERM ANALYSIS FILTERING SECTION
 *}

//* 4.2.8 */

procedure Decoding_of_the_coded_Log_Area_Ratios(
	LARc: _pword;           //* coded log area ratio	[0..7] 	IN	*/
	LARpp: _pword	        //* out: decoded ..			*/
);

  procedure STEP( B, MIC, INVA: _word );
  var
    temp1: _word;
  begin
    temp1    := _word(sshl(GSM_ADD( LARc^, MIC ), 10));
    inc(LARc);
    temp1    := GSM_SUB( temp1, sshl(B, 1) );
    temp1    := GSM_MULT_R( INVA, temp1 );
    LARpp^   := GSM_ADD( temp1, temp1 );
    inc(LARpp);
  end;

begin
  {*  This procedure requires for efficient implementation
   *  two tables.
   *
   *  INVA[1..8] = integer( (32768 * 8) / real_A[1..8])
   *  MIC[1..8]  = minimum value of the LARc[1..8]
   *}
  //*  Compute the LARpp[1..8] */
  STEP(      0,  -32,  13107 );
  STEP(      0,  -32,  13107 );
  STEP(   2048,  -16,  13107 );
  STEP(  -2560,  -16,  13107 );
  //
  STEP(     94,   -8,  19223 );
  STEP(  -1792,   -8,  17476 );
  STEP(   -341,   -4,  31454 );
  STEP(  -1144,   -4,  29708 );
  //
  //* NOTE: the addition of *MIC is used to restore the sign of *LARc. */
end;

//* 4.2.9 */
//* Computation of the quantized reflection coefficients */

//* 4.2.9.1  Interpolation of the LARpp[1..8] to get the LARp[1..8] */

{*
 *  Within each frame of 160 analyzed speech samples the short term
 *  analysis and synthesis filters operate with four different sets of
 *  coefficients, derived from the previous set of decoded LARs(LARpp(j-1))
 *  and the actual set of decoded LARs (LARpp(j))
 *
 * (Initial value: LARpp(j-1)[1..8] = 0.)
 *}
procedure Coefficients_0_12(
	LARpp_j_1: _pword;
	LARpp_j: _pword;
	LARp: _pword);
var
  i: int32;
begin
  for i := 1 to 8 do begin
    //
    LARp^ := GSM_ADD( SASR( LARpp_j_1^, 2 ), SASR( LARpp_j^, 2 ));
    LARp^ := GSM_ADD( LARp^,  SASR( LARpp_j_1^, 1));
    //
    inc(LARp); inc(LARpp_j_1); inc(LARpp_j);
  end;
end;

// --  --
procedure Coefficients_13_26(
	LARpp_j_1: _pword;
	LARpp_j: _pword;
	LARp: _pword);
var
  i: int32;
begin
  for i := 1 to 8 do begin
    //
    LARp^ := GSM_ADD( SASR( LARpp_j_1^, 1), SASR( LARpp_j^, 1 ));
    inc(LARpp_j_1); inc(LARpp_j); inc(LARp);
  end;
end;

// --  --
procedure Coefficients_27_39(
	LARpp_j_1: _pword;
	LARpp_j: _pword;
	LARp: _pword);
var
  i: int32;
begin
  for i := 1 to 8 do begin
    //
    LARp^ := GSM_ADD( SASR( LARpp_j_1^, 2 ), SASR( LARpp_j^, 2 ));
    LARp^ := GSM_ADD( LARp^, SASR( LARpp_j^, 1 ));
    inc(LARpp_j_1); inc(LARpp_j); inc(LARp);
  end;
end;

// --  --
procedure Coefficients_40_159(
	LARpp_j: _pword;
	LARp: _pword);
var
  i: int32;
begin
  for i := 1 to 8 do begin
    //
    LARp^ := LARpp_j^;
    inc(LARpp_j); inc(LARp);
  end;
end;

//* 4.2.9.2 */
procedure LARp_to_rp(
	LARp: _pword	//* [0..7] IN/OUT  */
);
{*
 *  The input of this procedure is the interpolated LARp[0..7] array.
 *  The reflection coefficients, rp[i], are used in the analysis
 *  filter and in the synthesis filter.
 *}
var
  i: int32;
  temp: _word;
begin
  for i := 1 to 8 do begin
    //
    if (LARp^ < 0) then begin
      //
      if (MIN_WORD = LARp^) then
        temp := MAX_WORD
      else
        temp := -LARp^;
      //
      if (temp < 11059) then LARp^ := sshl(temp, 1)
      else
        if (temp < 20070) then LARp^ := temp + 11059
        else
          LARp^ := GSM_ADD( _word(sshr(temp, 2)), 26112);
      //
      LARp^ := -LARp^;
    end
    else begin
      //
      temp  := LARp^;
      if (temp < 11059) then LARp^ := sshl(temp, 1)
      else
        if (temp < 20070) then LARp^ := temp + 11059
        else
          LARp^ := GSM_ADD( _word(sshr(temp, 2)), 26112 );
    end;
    //
    inc(LARp);
  end;
end;


//* 4.2.10 */
procedure Short_term_analysis_filtering(
	S: pgsm_state;
	rp: _pword;     //* [0..7]	IN	*/
	k_n: int32; 	//*   k_end - k_start	*/
	_s: _pword	//* [0..n-1]	IN/OUT	*/
);
{*
 *  This procedure computes the short term residual signal d[..] to be fed
 *  to the RPE-LTP loop from the s[..] signal and from the local rp[..]
 *  array (quantized reflection coefficients).  As the call of this
 *  procedure can be done in many ways (see the interpolation of the LAR
 *  coefficient), it is assumed that the computation begins with index
 *  k_start (for arrays d[..] and s[..]) and stops with index k_end
 *  (k_start and k_end are defined in 4.2.9.1).  This procedure also
 *  needs to keep the array u[0..7] in memory for each call.
 *}
var
 u: _pword;
 i: int32;
 di, zzz, ui, sav, rpi: _word;
begin
  u := _pword(@S.u);
  while (0 < k_n) do begin
    //
    dec(k_n);
    //
    sav := _s^;
    di := sav;
    //
    for i := 0 to 7 do begin		//* YYY */
      //
      ui    := Wi(u, i);
      rpi   := Wi(rp, i);
      Wp(u, i)^  := sav;
      //
      zzz   := GSM_MULT_R(rpi, di);
      sav   := GSM_ADD(   ui,  zzz);
      //
      zzz   := GSM_MULT_R(rpi, ui);
      di    := GSM_ADD(   di,  zzz );
    end;
    //
    _s^ := di;
    inc(_s);
  end;
end;

// --  --
procedure Short_term_synthesis_filtering(
	S: pgsm_state;
	rrp: _pword;     //* [0..7]	IN	*/
	k: int32; 	//*   k_end - k_start	*/
	wt: _pword;	//* [0..k-1]	IN	*/
	sr: _pword	//* [0..k-1]	OUT	*/
);
var
  v: _pword;
  i: int32;
  sri, tmp1, tmp2: _word;
begin
  v := _pword(@S.v);
  while (0 < k) do begin
    //
    dec(k);
    sri := wt^;
    inc(wt);
    //
    for i := 7 downto 0 do begin
      //
      //* sri = GSM_SUB( sri, gsm_mult_r( rrp[i], v[i] ) );  */
      tmp1 := Wi(rrp, i);
      tmp2 := Wi(v, i);
      //
      if ((MIN_WORD = tmp1) and (MIN_WORD = tmp2)) then tmp2 := MAX_WORD
      else
        tmp2 := _word( $0FFFF and ( sshr( _longword(tmp1) * _longword(tmp2) + 16384, 15)) );
      //
      sri := GSM_SUB( sri, tmp2 );
      //
      //* v[i+1] = GSM_ADD( v[i], gsm_mult_r( rrp[i], sri ) ); */
      //
      if ((MIN_WORD = tmp1) and (MIN_WORD = sri)) then tmp1 := MAX_WORD
      else
        tmp1 := _word( $0FFFF and ( sshr(_longword(tmp1) * _longword(sri) + 16384, 15)) );
      //
      Wp(v, i + 1)^ := GSM_ADD( Wi(v, i), tmp1);
    end;
    //
    v^ := sri;
    sr^ := sri;
    //
    inc(sr);
  end;
end;

// --  --
procedure Gsm_Short_Term_Analysis_Filter(
	S: pgsm_state;
	LARc: _pword;		//* coded log area ratio [0..7]  IN	*/
	_s: _pword		//* signal [0..159]		IN/OUT	*/
);
var
  LARpp_j: _pword;
  LARpp_j_1: _pword;
  LARp: array[0..8 - 1] of _word;
begin
  LARpp_j	:= _pword(@S.LARpp[S.j]);
  S.j := S.j xor 1;
  LARpp_j_1	:= _pword(@S.LARpp[S.j]);
  //
  Decoding_of_the_coded_Log_Area_Ratios( LARc, LARpp_j );

  Coefficients_0_12(  LARpp_j_1, LARpp_j, _pword(@LARp) );
  LARp_to_rp( _pword(@LARp) );
  Short_term_analysis_filtering( S, _pword(@LARp), 13, _s);

  Coefficients_13_26( LARpp_j_1, LARpp_j, _pword(@LARp));
  LARp_to_rp( _pword(@LARp) );
  Short_term_analysis_filtering( S, _pword(@LARp), 14, Wp(_s, 13) );

  Coefficients_27_39( LARpp_j_1, LARpp_j, _pword(@LARp));
  LARp_to_rp( _pword(@LARp) );
  Short_term_analysis_filtering( S, _pword(@LARp), 13, Wp(_s, 27) );

  Coefficients_40_159( LARpp_j, _pword(@LARp) );
  LARp_to_rp( _pword(@LARp) );
  Short_term_analysis_filtering( S, _pword(@LARp), 120, Wp(_s, 40) );
end;

procedure Gsm_Short_Term_Synthesis_Filter(
		S: pgsm_state;
		LARcr: _pword; 	        //* log area ratios [0..7]  IN	*/
		wt: _pword;		//* received d [0...39]	   IN	*/
		_s: _pword		//* signal   s [0..159]	  OUT	*/

);
var
  LARpp_j: _pword;
  LARpp_j_1: _pword;
  LARp: array[0..8 - 1] of _word;
begin
  LARpp_j	:= _pword(@S.LARpp[S.j]);
  S.j := S.j xor 1;
  LARpp_j_1	:= _pword(@S.LARpp[S.j]);
  //
  Decoding_of_the_coded_Log_Area_Ratios( LARcr, LARpp_j );

  Coefficients_0_12( LARpp_j_1, LARpp_j, _pword(@LARp) );
  LARp_to_rp( _pword(@LARp) );
  Short_term_synthesis_filtering( S, _pword(@LARp), 13, wt, _s );

  Coefficients_13_26( LARpp_j_1, LARpp_j, _pword(@LARp));
  LARp_to_rp( _pword(@LARp) );
  Short_term_synthesis_filtering( S, _pword(@LARp), 14, Wp(wt, 13), Wp(_s, 13) );

  Coefficients_27_39( LARpp_j_1, LARpp_j, _pword(@LARp) );
  LARp_to_rp( _pword(@LARp) );
  Short_term_synthesis_filtering( S, _pword(@LARp), 13, Wp(wt, 27), Wp(_s, 27) );

  Coefficients_40_159( LARpp_j, _pword(@LARp) );
  LARp_to_rp( _pword(@LARp) );
  Short_term_synthesis_filtering(S, _pword(@LARp), 120, Wp(wt, 40), Wp(_s, 40) );
end;


//*  4.3 FIXED POINT IMPLEMENTATION OF THE RPE-LTP DECODER */
procedure Postprocessing(
	S: pgsm_state;
	_s: _pword
);
var
  k: int32;
  msr: _word;
  tmp: _word;
begin
  msr := S.msr;
  for k := 159 downto 0 do begin
    //
    tmp := GSM_MULT_R( msr, 28180 );
    msr := GSM_ADD( _s^, tmp);  	   //* Deemphasis 	     */
    _s^ := _word(GSM_ADD(msr, msr) and $FFF8);  //* Truncation & Upscaling */
    //
    inc(_s);
  end;
  //
  S.msr := msr;
end;

procedure Gsm_Decoder(
		S: pgsm_state;
		LARcr: _pword;          //* [0..7]		IN	*/
		Ncr: _pword;		//* [0..3] 		IN 	*/
		bcr: _pword;		//* [0..3]		IN	*/
		Mcr: _pword;		//* [0..3] 		IN 	*/
		xmaxcr: _pword;	        //* [0..3]		IN 	*/
		xMcr: _pword;		//* [0..13*4]		IN	*/
		_s: _pword		//* [0..159]		OUT 	*/
);
var
  j, k: int32;
  erp: array[0..40  - 1] of _word;
   wt: array[0..160 - 1] of _word;
  drp: _pword;
begin
  drp := _pword(@S.dp0[120]);
  for j := 0 to 3 do begin
    //
    Gsm_RPE_Decoding( S, xmaxcr^, Mcr^, xMcr, _pword(@erp));
    Gsm_Long_Term_Synthesis_Filtering( S, Ncr^, bcr^, _pword(@erp), drp );
    //
    for k := 0 to 39 do
      wt[j * 40 + k] := Wi(drp, k);
    //
    inc(xmaxcr); inc(bcr); inc(Ncr); inc(Mcr); inc(xMcr, 13);
  end;
  //
  Gsm_Short_Term_Synthesis_Filter( S, LARcr, _pword(@wt), _s );
  Postprocessing(S, _s);
end;


//*  4.2.13 .. 4.2.17  RPE ENCODING SECTION */

//* 4.2.13 */
procedure Weighting_filter(
	e: _pword;      //* signal [-5..0.39.44]	IN  */
	x: _pword       //* signal [0..39]	OUT */
);
{*
 *  The coefficients of the weighting filter are stored in a table
 *  (see table 4.4).  The following scaling is used:
 *
 *	H[0..10] = integer( real_H[ 0..10] * 8192 );
 *}
var
  k: int32;

  function STEP(i, H: _word): _longword;
  begin
    result := (Wi(e, k + i) * _longword(H));
  end;

var
  L_result: _longword;
begin
  //*  Initialization of a temporary working array wt[0...49] */
  //
  dec(e, 5);

  //*  Compute the signal x[0..39] */
  for k := 0 to 39 do begin
    //
    L_result := 8192 shr 1;
    //
    L_result := L_result +
      STEP(	0, 	-134 )
    + STEP(	1, 	-374 )
    + STEP(	3, 	2054 )
    + STEP(	4, 	5741 )
    + STEP(	5, 	8192 )
    + STEP(	6, 	5741 )
    + STEP(	7, 	2054 )
    + STEP(	9, 	-374 )
    + STEP(10, 	-134 )
    ;

    L_result := SASR( L_result, 13 );
    if (L_result < MIN_WORD) then Wp(x, k)^ := MIN_WORD
    else
      if (L_result > MAX_WORD) then Wp(x, k)^ := MAX_WORD
      else
        Wp(x, k)^ := L_result;
  end;
end;

//* 4.2.14 */
procedure RPE_grid_selection(
	x: _pword;		//* [0..39]		IN  */
	xM: _pword;		//* [0..12]		OUT */
	Mc_out: _pword         //*			OUT */
);
{*
 *  The signal x[0..39] is used to select the RPE grid which is
 *  represented by Mc.
 *}
var
  L_result: _longword;

  procedure STEP( m, i: _word );
  var
    L_temp: _longword;
  begin
    L_temp := SASR( Wi(x, m + 3 * i), 2 );
    L_result := L_result + L_temp * L_temp;
  end;

var
  i: int32;
  EM: _longword;	//* xxx should be L_EM? */
  Mc: _word;
  L_common_0_3: _longword;
begin
  //EM := 0;
  Mc := 0;
  //
  //* common part of 0 and 3 */
  L_result := 0;
  STEP( 0, 1 ); STEP( 0, 2 ); STEP( 0, 3 ); STEP( 0, 4 );
  STEP( 0, 5 ); STEP( 0, 6 ); STEP( 0, 7 ); STEP( 0, 8 );
  STEP( 0, 9 ); STEP( 0, 10); STEP( 0, 11); STEP( 0, 12);
  L_common_0_3 := L_result;
  //
  STEP( 0, 0 );
  L_result := sshl(L_result, 1);       //* implicit in L_MULT */
  EM := L_result;
  //
  L_result := 0;
  STEP( 1, 0 );
  STEP( 1, 1 ); STEP( 1, 2 ); STEP( 1, 3 ); STEP( 1, 4 );
  STEP( 1, 5 ); STEP( 1, 6 ); STEP( 1, 7 ); STEP( 1, 8 );
  STEP( 1, 9 ); STEP( 1, 10); STEP( 1, 11); STEP( 1, 12);
  L_result := sshl(L_result, 1);
  if (L_result > EM) then begin
    //
    Mc := 1;
    EM := L_result;
  end;
  //
  L_result := 0;
  STEP( 2, 0 );
  STEP( 2, 1 ); STEP( 2, 2 ); STEP( 2, 3 ); STEP( 2, 4 );
  STEP( 2, 5 ); STEP( 2, 6 ); STEP( 2, 7 ); STEP( 2, 8 );
  STEP( 2, 9 ); STEP( 2, 10); STEP( 2, 11); STEP( 2, 12);
  L_result := sshl(L_result, 1);
  if (L_result > EM) then begin
    //
    Mc := 2;
    EM := L_result;
  end;
  //
  L_result := L_common_0_3;
  STEP( 3, 12 );
  L_result := sshl(L_result, 1);
  if (L_result > EM) then begin
    //
    Mc := 3;
    //EM := L_result;
  end;
  //
  //*  Down-sampling by a factor 3 to get the selected xM[0..12] RPE sequence. */
  for i := 0 to 12 do
    Wp(xM, i)^ := Wi(x, Mc + 3 * i);
  //
  Mc_out^ := Mc;
end;

//* 4.12.15 */
procedure APCM_quantization_xmaxc_to_exp_mant(
	xmaxc: _word;           //* IN 	*/
	exp_out: _pword;        //* OUT	*/
	mant_out: _pword	//* OUT  */
);
var
  exp, mant: _word;
begin
  //* Compute exponent and mantissa of the decoded version of xmaxc */
  exp := 0;
  if (xmaxc > 15) then exp := SASR(xmaxc, 3) - 1;
  mant := xmaxc - sshl(exp, 3);
  //
  if (0 = mant) then begin
    //
    exp  := -4;
    mant := 7;
  end
  else begin
    //
    while (mant <= 7) do begin
      //
      mant := _word(sshl(mant, 1) or 1);
      dec(exp);
    end;
    //
    dec(mant, 8);
  end;
  //
  assert( (exp  >= -4) and (exp  <= 6) );
  assert( (mant >=  0) and (mant <= 7) );
  //
  exp_out^  := exp;
  mant_out^ := mant;
end;

// --  --
procedure APCM_quantization(
	xM: _pword;     //* [0..12]		IN	*/
	xMc: _pword;    //* [0..12]		OUT	*/
	mant_out: _pword;       //* 			OUT	*/
	exp_out: _pword;        //*			OUT	*/
	xmaxc_out: _pword	//*			OUT	*/
);
var
  i, itest: int32;
  xmax, xmaxc, temp, temp1, temp2: _word;
  exp, mant: _word;
begin
  //*  Find the maximum absolute value xmax of xM[0..12]. */
  xmax := 0;
  for i := 0 to 12 do begin
    //
    temp := GSM_ABS(Wi(xM, i));
    if (temp > xmax) then
      xmax := temp;
  end;
  //
  //*  Qantizing and coding of xmax to get xmaxc. */
  //
  exp   := 0;
  temp  := SASR( xmax, 9 );
  itest := 0;
  //
  for i := 0 to 5 do begin
    //
    if (temp <= 0) then
      itest := itest or 1;
    //
    temp := SASR( temp, 1 );
    //
    assert(exp <= 5);
    //
    if (0 = itest) then
      inc(exp);		//* exp = add (exp, 1) */
  end;
  //
  assert((exp <= 6) and (exp >= 0));
  temp := exp + 5;
  //
  assert((temp <= 11) and (temp >= 0));
  xmaxc := _gsm_add( SASR(xmax, temp), sshl(exp, 3) );
  //
  {*   Quantizing and coding of the xM[0..12] RPE sequence
   *   to get the xMc[0..12]
   *}
  //
  APCM_quantization_xmaxc_to_exp_mant( xmaxc, @exp, @mant );
  //
  {*  This computation uses the fact that the decoded version of xmaxc
   *  can be calculated by using the exponent and the mantissa part of
   *  xmaxc (logarithmic table).
   *  So, this method avoids any division and uses only a scaling
   *  of the RPE samples by a function of the exponent.  A direct
   *  multiplication by the inverse of the mantissa (NRFAC[0..7]
   *  found in table 4.5) gives the 3 bit coded version xMc[0..12]
   *  of the RPE samples.
   *}
  //* Direct computation of xMc[0..12] using table 4.5 */
  //
  assert( (exp <= 4096) and (exp >= -4096) );
  assert( (mant >= 0) and (mant <= 7) );
  //
  temp1 := 6 - exp;		//* normalization by the exponent */
  temp2 := gsm_NRFAC[ mant ];  	//* inverse mantissa 		 */
  //
  for i := 0 to 12 do begin
    //
    assert((temp1 >= 0) and (temp1 < 16));
    //
    temp := _word(sshl(Wi(xM, i), temp1));
    temp := GSM_MULT( temp, temp2 );
    temp := SASR(temp, 12);
    Wp(xMc, i)^ := temp + 4;		//* see note below */
  end;

  //*  NOTE: This equation is used to make all the xMc[i] positive. */
  mant_out^  := mant;
  exp_out^   := exp;
  xmaxc_out^ := xmaxc;
end;

//* 4.2.16 */
procedure APCM_inverse_quantization(
	xMc: _pword;    //* [0..12]			IN 	*/
	mant: _word;
	exp: _word;
	xMp: _pword     //* [0..12]			OUT 	*/
);
{*
 *  This part is for decoding the RPE sequence of coded xMc[0..12]
 *  samples to obtain the xMp[0..12] array.  Table 4.6 is used to get
 *  the mantissa of xmaxc (FAC[0..7]).
 *}
var
  i: int32;
  temp, temp1, temp2, temp3: _word;
begin
  assert( (mant >= 0) and (mant <= 7) );
  //
  temp1 := gsm_FAC[ mant ];	//* see 4.2-15 for mant */
  temp2 := _gsm_sub( 6, exp );	//* see 4.2-15 for exp  */
  temp3 := _gsm_asl( 1, _gsm_sub( temp2, 1 ));
  //
  for i := 12 downto 0 do begin
    //
    assert( (xMc^ <= 7) and (xMc^ >= 0) ); 	//* 3 bit unsigned */
    //
    temp := sshl(xMc^, 1) - 7;	        //* restore sign   */
    inc(xMc);
    assert( (temp <= 7) and (temp >= -7) ); 	//* 4 bit signed   */
    //
    temp := sshl(temp, 12);				//* 16 bit signed  */
    temp := GSM_MULT_R( temp1, temp );
    temp := GSM_ADD( temp, temp3 );
    //
    xMp^ := _gsm_asr( temp, temp2 );
    inc(xMp);
  end;
end;

//* 4.2.17 */
procedure RPE_grid_positioning(
	Mc: _word;      //* grid position	IN	*/
	xMp: _pword;		//* [0..12]		IN	*/
	ep: _pword		//* [0..39]		OUT	*/
);
{*
 *  This procedure computes the reconstructed long term residual signal
 *  ep[0..39] for the LTP analysis filter.  The inputs are the Mc
 *  which is the grid position selection and the xMp[0..12] decoded
 *  RPE samples which are upsampled by a factor of 3 by inserting zero
 *  values.
 *}
var
  i: int32;
  m: int32;
begin
  i := 13;
  assert( (0 <= Mc) and (Mc <= 3) );
  //
(*
  BEWARE: EVIL C CODE DETECTED. Print, put in a frame and hang on a wall.

        switch (Mc) {
                case 3: *ep++ = 0;
                case 2:  do {
                                *ep++ = 0;
                case 1:         *ep++ = 0;
                case 0:         *ep++ = *xMp++;
                         } while (--i);
        }
*)
  // --- my poor Delphi equalent follows ---
  if (3 = Mc) then begin
    //
    ep^ := 0;
    inc(ep);
    m := 2;
  end
  else
    m := Mc;
  //
  repeat
    //
    if (2 = m) then begin
      //
      ep^ := 0;
      inc(ep);
      m := 1;
    end;
    //
    if (1 = m) then begin
      //
      ep^ := 0;
      inc(ep);
    end;
    //
    ep^ := xMp^;
    inc(ep);
    inc(xMp);
    //
    m := 2;
    dec(i);
  until (1 > i);
  // ---- end of evil code ----
  //
  while (Mc < 3) do begin
    //
    inc(Mc);
    ep^ := 0;
    //
    inc(ep);
  end;
end;

//* 4.2.18 */
{*  This procedure adds the reconstructed long term residual signal
 *  ep[0..39] to the estimated signal dpp[0..39] from the long term
 *  analysis filter to compute the reconstructed short term residual
 *  signal dp[-40..-1]; also the reconstructed short term residual
 *  array dp[-120..-41] is updated.
 *}

//* Has been inlined in code.c */
(*
void Gsm_Update_of_reconstructed_short_time_residual_signal P3((dpp, ep, dp),
	word	* dpp,		/* [0...39]	IN	*/
	word	* ep,		/* [0...39]	IN	*/
	word	* dp)		/* [-120...-1]  IN/OUT 	*/
{
	int 		k;

	for (k = 0; k <= 79; k++)
		dp[ -120 + k ] = dp[ -80 + k ];

	for (k = 0; k <= 39; k++)
		dp[ -40 + k ] = gsm_add( ep[k], dpp[k] );
}
#endif	/* Has been inlined in code.c */
*)

// --  --
procedure Gsm_RPE_Encoding(
		S: pgsm_state;
		e: _pword;              //* -5..-1][0..39][40..44     IN/OUT  */
		xmaxc: _pword;          //*                              OUT */
		Mc: _pword;             //*                              OUT */
		xMc: _pword             //* [0..12]                      OUT */
);
var
  x: array[0..40 - 1] of _word;
  xM: array[0..13 - 1] of _word;
  xMp: array[0..13 - 1] of _word;
  mant, exp: _word;
begin
  Weighting_filter(e, _pword(@x));
  RPE_grid_selection(_pword(@x), _pword(@xM), Mc);
  //
  APCM_quantization(_pword(@xM), xMc, @mant, @exp, xmaxc);
  APCM_inverse_quantization(xMc, mant, exp, _pword(@xMp));
  //
  RPE_grid_positioning(Mc^, _pword(@xMp), e);
end;

// --  --
procedure Gsm_RPE_Decoding(
	        S: pgsm_state;
		xmaxcr: _word;
		Mcr: _word;
		xMcr: _pword;           //* [0..12], 3 bits             IN      */
		erp: _pword             //* [0..39]                     OUT     */
);
var
  exp, mant: _word;
  xMp: array[0..13 - 1] of _word;
begin
  APCM_quantization_xmaxc_to_exp_mant( xmaxcr, @exp, @mant );
  APCM_inverse_quantization( xMcr, mant, exp, _pword(@xMp) );
  RPE_grid_positioning( Mcr, _pword(@xMp), erp );
end;

// --  --
function gsm_create(): gsm;
begin
  result := malloc(sizeof(gsm_state), true, 0);
  if (nil <> result) then
    result.nrp := 40;
end;

// --  --
procedure gsm_destroy(g: gsm);
begin
  mrealloc(g);
end;

// --  --
function gsm_option(g: gsm; opt: int32; val: pInt32): int32;
begin
  result := -1;
  case (opt)  of

    GSM_OPT_LTP_CUT: ;  // lake: CUT code was stripped

    GSM_OPT_VERBOSE: begin
    {$IFDEF DEBUG }
      result := g.verbose;
      if (nil <> val) then g.verbose := val^;
    {$ENDIF DEBUG }
    end;

    GSM_OPT_FAST: ;     // Lake: FAST code was stripped

{$IFDEF WAV49 }

    GSM_OPT_FRAME_CHAIN: begin
      //
      result := g.frame_chain;
      if (nil <> val) then g.frame_chain := val^;
    end;

    GSM_OPT_FRAME_INDEX: begin
      //
      result := g.frame_index;
      if (nil <> val) then g.frame_index := val^;
    end;

    GSM_OPT_WAV49: begin
      //
      result := g.wav_fmt;
      if (nil <> val) then g.wav_fmt := not (not val^);
    end;

{$ENDIF WAV49 }

  end;
end;

// --  --
procedure gsm_encode(s: gsm; source: pgsm_signal; c: pgsm_byte);
var
  LARc: array[0..8 - 1] of _word;
  Nc: array[0..4 - 1] of _word;
  Mc: array[0..4 - 1] of _word;
  bc: array[0..4 - 1] of _word;
  xmaxc: array[0..4 - 1] of _word;
  xmc: array[0..13*4 - 1] of _word;
  //
{$IFDEF WAV49 }
  sr: uword;
{$ENDIF WAV49 }
  //
  d: pArray absolute c;
begin
  Gsm_Coder(s, _pword(source), _pword(@LARc), _pword(@Nc), _pword(@bc), _pword(@Mc), _pword(@xmaxc), _pword(@xmc) );
  //
{$IFDEF WAV49 }
  if (0 <> s.wav_fmt) then begin
    //
    s.frame_index := not s.frame_index;
    if (0 <> s.frame_index) then begin
      //
      sr := 0;
      sr := (sr shr 6) or (LARc[0]  shl 10);
      sr := (sr shr 6) or (LARc[1]  shl 10);     d[ 0] := byte(sr shr 4);
      sr := (sr shr 5) or (LARc[2]  shl 11);     d[ 1] := byte(sr shr 7);
      sr := (sr shr 5) or (LARc[3]  shl 11);
      sr := (sr shr 4) or (LARc[4]  shl 12);     d[ 2] := byte(sr shr 6);
      sr := (sr shr 4) or (LARc[5]  shl 12);
      sr := (sr shr 3) or (LARc[6]  shl 13);     d[ 3] := byte(sr shr 7);
      sr := (sr shr 3) or (LARc[7]  shl 13);
      sr := (sr shr 7) or (Nc[0]    shl 9 );     d[ 4] := byte(sr shr 5);
      sr := (sr shr 2) or (bc[0]    shl 14);
      sr := (sr shr 2) or (Mc[0]    shl 14);
      sr := (sr shr 6) or (xmaxc[0] shl 10);     d[ 5] := byte(sr shr 3);
      sr := (sr shr 3) or (xmc[0]   shl 13);     d[ 6] := byte(sr shr 8);
      sr := (sr shr 3) or (xmc[1]   shl 13);
      sr := (sr shr 3) or (xmc[2]   shl 13);
      sr := (sr shr 3) or (xmc[3]   shl 13);     d[ 7] := byte(sr shr 7);
      sr := (sr shr 3) or (xmc[4]   shl 13);
      sr := (sr shr 3) or (xmc[5]   shl 13);
      sr := (sr shr 3) or (xmc[6]   shl 13);     d[ 8] := byte(sr shr 6);
      sr := (sr shr 3) or (xmc[7]   shl 13);
      sr := (sr shr 3) or (xmc[8]   shl 13);     d[ 9] := byte(sr shr 8);
      sr := (sr shr 3) or (xmc[9]   shl 13);
      sr := (sr shr 3) or (xmc[10]  shl 13);
      sr := (sr shr 3) or (xmc[11]  shl 13);     d[10] := byte(sr shr 7);
      sr := (sr shr 3) or (xmc[12]  shl 13);
      sr := (sr shr 7) or (Nc[1]    shl 9 );     d[11] := byte(sr shr 5);
      sr := (sr shr 2) or (bc[1]    shl 14);
      sr := (sr shr 2) or (Mc[1]    shl 14);
      sr := (sr shr 6) or (xmaxc[1] shl 10);     d[12] := byte(sr shr 3);
      sr := (sr shr 3) or (xmc[13]  shl 13);     d[13] := byte(sr shr 8);
      sr := (sr shr 3) or (xmc[14]  shl 13);
      sr := (sr shr 3) or (xmc[15]  shl 13);
      sr := (sr shr 3) or (xmc[16]  shl 13);     d[14] := byte(sr shr 7);
      sr := (sr shr 3) or (xmc[17]  shl 13);
      sr := (sr shr 3) or (xmc[18]  shl 13);
      sr := (sr shr 3) or (xmc[19]  shl 13);     d[15] := byte(sr shr 6);
      sr := (sr shr 3) or (xmc[20]  shl 13);
      sr := (sr shr 3) or (xmc[21]  shl 13);     d[16] := byte(sr shr 8);
      sr := (sr shr 3) or (xmc[22]  shl 13);
      sr := (sr shr 3) or (xmc[23]  shl 13);
      sr := (sr shr 3) or (xmc[24]  shl 13);     d[17] := byte(sr shr 7);
      sr := (sr shr 3) or (xmc[25]  shl 13);
      sr := (sr shr 7) or (Nc[2]    shl 9 );     d[18] := byte(sr shr 5);
      sr := (sr shr 2) or (bc[2]    shl 14);
      sr := (sr shr 2) or (Mc[2]    shl 14);
      sr := (sr shr 6) or (xmaxc[2] shl 10);     d[19] := byte(sr shr 3);
      sr := (sr shr 3) or (xmc[26]  shl 13);     d[20] := byte(sr shr 8);
      sr := (sr shr 3) or (xmc[27]  shl 13);
      sr := (sr shr 3) or (xmc[28]  shl 13);
      sr := (sr shr 3) or (xmc[29]  shl 13);     d[21] := byte(sr shr 7);
      sr := (sr shr 3) or (xmc[30]  shl 13);
      sr := (sr shr 3) or (xmc[31]  shl 13);
      sr := (sr shr 3) or (xmc[32]  shl 13);     d[22] := byte(sr shr 6);
      sr := (sr shr 3) or (xmc[33]  shl 13);
      sr := (sr shr 3) or (xmc[34]  shl 13);     d[23] := byte(sr shr 8);
      sr := (sr shr 3) or (xmc[35]  shl 13);
      sr := (sr shr 3) or (xmc[36]  shl 13);
      sr := (sr shr 3) or (xmc[37]  shl 13);     d[24] := byte(sr shr 7);
      sr := (sr shr 3) or (xmc[38]  shl 13);
      sr := (sr shr 7) or (Nc[3]    shl 9 );     d[25] := byte(sr shr 5);
      sr := (sr shr 2) or (bc[3]    shl 14);
      sr := (sr shr 2) or (Mc[3]    shl 14);
      sr := (sr shr 6) or (xmaxc[3] shl 10);     d[26] := byte(sr shr 3);
      sr := (sr shr 3) or (xmc[39]  shl 13);     d[27] := byte(sr shr 8);
      sr := (sr shr 3) or (xmc[40]  shl 13);
      sr := (sr shr 3) or (xmc[41]  shl 13);
      sr := (sr shr 3) or (xmc[42]  shl 13);     d[28] := byte(sr shr 7);
      sr := (sr shr 3) or (xmc[43]  shl 13);
      sr := (sr shr 3) or (xmc[44]  shl 13);
      sr := (sr shr 3) or (xmc[45]  shl 13);     d[29] := byte(sr shr 6);
      sr := (sr shr 3) or (xmc[46]  shl 13);
      sr := (sr shr 3) or (xmc[47]  shl 13);     d[30] := byte(sr shr 8);
      sr := (sr shr 3) or (xmc[48]  shl 13);
      sr := (sr shr 3) or (xmc[49]  shl 13);
      sr := (sr shr 3) or (xmc[50]  shl 13);     d[31] := byte(sr shr 7);
      sr := (sr shr 3) or (xmc[51]  shl 13);
      sr := (sr shr 4);                          d[32] := byte(sr shr 8);     // need to store only 4 bits in last byte, since that is not possible,
      s.frame_chain := d[32];                                           // take over the whole byte to next frame. You can assume #0 frames are 32 bytes long
    end
    else begin
      //
      sr := 0;
      sr := (sr shr 4) or (s.frame_chain shl 12);
      sr := (sr shr 6) or (LARc[0]  shl 10);      d[ 0] := byte(sr shr 6);    // this actually must be byte #33 in a 65 bytes block
      sr := (sr shr 6) or (LARc[1]  shl 10);      d[ 1] := byte(sr shr 8);
      sr := (sr shr 5) or (LARc[2]  shl 11);
      sr := (sr shr 5) or (LARc[3]  shl 11);      d[ 2] := byte(sr shr 6);
      sr := (sr shr 4) or (LARc[4]  shl 12);
      sr := (sr shr 4) or (LARc[5]  shl 12);      d[ 3] := byte(sr shr 6);
      sr := (sr shr 3) or (LARc[6]  shl 13);
      sr := (sr shr 3) or (LARc[7]  shl 13);      d[ 4] := byte(sr shr 8);
      sr := (sr shr 7) or (Nc[0]    shl 9 );
      sr := (sr shr 2) or (bc[0]    shl 14);      d[ 5] := byte(sr shr 7);
      sr := (sr shr 2) or (Mc[0]    shl 14);
      sr := (sr shr 6) or (xmaxc[0] shl 10);      d[ 6] := byte(sr shr 7);
      sr := (sr shr 3) or (xmc[0]   shl 13);
      sr := (sr shr 3) or (xmc[1]   shl 13);
      sr := (sr shr 3) or (xmc[2]   shl 13);      d[ 7] := byte(sr shr 6);
      sr := (sr shr 3) or (xmc[3]   shl 13);
      sr := (sr shr 3) or (xmc[4]   shl 13);      d[ 8] := byte(sr shr 8);
      sr := (sr shr 3) or (xmc[5]   shl 13);
      sr := (sr shr 3) or (xmc[6]   shl 13);
      sr := (sr shr 3) or (xmc[7]   shl 13);      d[ 9] := byte(sr shr 7);
      sr := (sr shr 3) or (xmc[8]   shl 13);
      sr := (sr shr 3) or (xmc[9]   shl 13);
      sr := (sr shr 3) or (xmc[10]  shl 13);      d[10] := byte(sr shr 6);
      sr := (sr shr 3) or (xmc[11]  shl 13);
      sr := (sr shr 3) or (xmc[12]  shl 13);      d[11] := byte(sr shr 8);
      sr := (sr shr 7) or (Nc[1]    shl 9 );
      sr := (sr shr 2) or (bc[1]    shl 14);      d[12] := byte(sr shr 7);
      sr := (sr shr 2) or (Mc[1]    shl 14);
      sr := (sr shr 6) or (xmaxc[1] shl 10);      d[13] := byte(sr shr 7);
      sr := (sr shr 3) or (xmc[13]  shl 13);
      sr := (sr shr 3) or (xmc[14]  shl 13);
      sr := (sr shr 3) or (xmc[15]  shl 13);      d[14] := byte(sr shr 6);
      sr := (sr shr 3) or (xmc[16]  shl 13);
      sr := (sr shr 3) or (xmc[17]  shl 13);      d[15] := byte(sr shr 8);
      sr := (sr shr 3) or (xmc[18]  shl 13);
      sr := (sr shr 3) or (xmc[19]  shl 13);
      sr := (sr shr 3) or (xmc[20]  shl 13);      d[16] := byte(sr shr 7);
      sr := (sr shr 3) or (xmc[21]  shl 13);
      sr := (sr shr 3) or (xmc[22]  shl 13);
      sr := (sr shr 3) or (xmc[23]  shl 13);      d[17] := byte(sr shr 6);
      sr := (sr shr 3) or (xmc[24]  shl 13);
      sr := (sr shr 3) or (xmc[25]  shl 13);      d[18] := byte(sr shr 8);
      sr := (sr shr 7) or (Nc[2]    shl 9 );
      sr := (sr shr 2) or (bc[2]    shl 14);      d[19] := byte(sr shr 7);
      sr := (sr shr 2) or (Mc[2]    shl 14);
      sr := (sr shr 6) or (xmaxc[2] shl 10);      d[20] := byte(sr shr 7);
      sr := (sr shr 3) or (xmc[26]  shl 13);
      sr := (sr shr 3) or (xmc[27]  shl 13);
      sr := (sr shr 3) or (xmc[28]  shl 13);      d[21] := byte(sr shr 6);
      sr := (sr shr 3) or (xmc[29]  shl 13);
      sr := (sr shr 3) or (xmc[30]  shl 13);      d[22] := byte(sr shr 8);
      sr := (sr shr 3) or (xmc[31]  shl 13);
      sr := (sr shr 3) or (xmc[32]  shl 13);
      sr := (sr shr 3) or (xmc[33]  shl 13);      d[23] := byte(sr shr 7);
      sr := (sr shr 3) or (xmc[34]  shl 13);
      sr := (sr shr 3) or (xmc[35]  shl 13);
      sr := (sr shr 3) or (xmc[36]  shl 13);      d[24] := byte(sr shr 6);
      sr := (sr shr 3) or (xmc[37]  shl 13);
      sr := (sr shr 3) or (xmc[38]  shl 13);      d[25] := byte(sr shr 8);
      sr := (sr shr 7) or (Nc[3]    shl 9 );
      sr := (sr shr 2) or (bc[3]    shl 14);      d[26] := byte(sr shr 7);
      sr := (sr shr 2) or (Mc[3]    shl 14);
      sr := (sr shr 6) or (xmaxc[3] shl 10);      d[27] := byte(sr shr 7);
      sr := (sr shr 3) or (xmc[39]  shl 13);
      sr := (sr shr 3) or (xmc[40]  shl 13);
      sr := (sr shr 3) or (xmc[41]  shl 13);      d[28] := byte(sr shr 6);
      sr := (sr shr 3) or (xmc[42]  shl 13);
      sr := (sr shr 3) or (xmc[43]  shl 13);      d[29] := byte(sr shr 8);
      sr := (sr shr 3) or (xmc[44]  shl 13);
      sr := (sr shr 3) or (xmc[45]  shl 13);
      sr := (sr shr 3) or (xmc[46]  shl 13);      d[30] := byte(sr shr 7);
      sr := (sr shr 3) or (xmc[47]  shl 13);
      sr := (sr shr 3) or (xmc[48]  shl 13);
      sr := (sr shr 3) or (xmc[49]  shl 13);      d[31] := byte(sr shr 6);
      sr := (sr shr 3) or (xmc[50]  shl 13);
      sr := (sr shr 3) or (xmc[51]  shl 13);      d[32] := byte(sr shr 8);            // byte #65
    end;  // frame index
  end// wave49 format
  else begin
    //
{$ENDIF WAV49 }
    d[ 0] :=   ((GSM_MAGIC and $F)  shl 4)  or ((LARc[0] shr 2) and $F);   //* 1 */                       Nc, Mc and bc are a bit wrong!
    d[ 1] :=   ((LARc[0]   and $3)  shl 6)  or (LARc[1]         and $3F);
    d[ 2] :=   ((LARc[2]   and $1F) shl 3)  or ((LARc[3] shr 2) and $7);
    d[ 3] :=   ((LARc[3]   and $3)  shl 6)  or ((LARc[4]        and $F) shl 2)  or ((LARc[5]  shr 2) and $3);
    d[ 4] :=   ((LARc[5]   and $3)  shl 6)  or ((LARc[6]        and $7) shl 3)  or (LARc[7]          and $7);
    //
    d[ 5] :=   ((Nc[0]     and $7F) shl 1)  or ((bc[0]   shr 1) and $1);
    d[ 6] :=   ((bc[0]     and $1)  shl 7)  or ((Mc[0]          and $3) shl 5)  or ((xmaxc[0] shr 1) and $1F);
    d[ 7] :=   ((xmaxc[0]  and $1)  shl 7)  or ((xmc[0]         and $7) shl 4)  or ((xmc[1]          and $7) shl 1)      or ((xmc[2]  shr 2) and $1);
    d[ 8] :=   ((xmc[2]    and $3)  shl 6)  or ((xmc[3]         and $7) shl 3)  or (xmc[4]           and $7);
    //
    d[ 9] :=   ((xmc[5]    and $7)  shl 5)  or ((xmc[6]         and $7) shl 2)	or ((xmc[7]   shr 1) and $3);	//* 10 */
    d[10] :=   ((xmc[7]    and $1)  shl 7)  or ((xmc[8]         and $7) shl 4)  or ((xmc[9]          and $7) shl 1)      or ((xmc[10] shr 2) and $1);
    d[11] :=   ((xmc[10]   and $3)  shl 6)  or ((xmc[11]        and $7) shl 3)  or (xmc[12]          and $7);
    //
    d[12] :=   ((Nc[1]     and $7F) shl 1)  or ((bc[1]   shr 1) and $1);
    d[13] :=   ((bc[1]     and $1)  shl 7)  or ((Mc[1]          and $3) shl 5)  or ((xmaxc[1] shr 1) and $1F);
    d[14] :=   ((xmaxc[1]  and $1)  shl 7)  or ((xmc[13]        and $7) shl 4)  or ((xmc[14]         and $7) shl 1)      or ((xmc[15] shr 2) and $1);
    d[15] :=   ((xmc[15]   and $3)  shl 6)  or ((xmc[16]        and $7) shl 3)  or (xmc[17]          and $7);
    d[16] :=   ((xmc[18]   and $7)  shl 5)  or ((xmc[19]        and $7) shl 2)  or ((xmc[20]  shr 1) and $3);
    d[17] :=   ((xmc[20]   and $1)  shl 7)  or ((xmc[21]        and $7) shl 4)  or ((xmc[22]         and $7) shl 1)      or ((xmc[23] shr 2) and $1);
    d[18] :=   ((xmc[23]   and $3)  shl 6)  or ((xmc[24]        and $7) shl 3)  or (xmc[25]          and $7);
    //
    d[19] :=   ((Nc[2]     and $7F) shl 1)  or ((bc[2]   shr 1) and $1);              //* 20 */
    d[20] :=   ((bc[2]     and $1)  shl 7)  or ((Mc[2]          and $3) shl 5)  or ((xmaxc[2] shr 1) and $1F);
    d[21] :=   ((xmaxc[2]  and $1)  shl 7)  or ((xmc[26]        and $7) shl 4)  or ((xmc[27]         and $7) shl 1)      or ((xmc[28] shr 2) and $1);
    d[22] :=   ((xmc[28]   and $3)  shl 6)  or ((xmc[29]        and $7) shl 3)  or (xmc[30]          and $7);
    d[23] :=   ((xmc[31]   and $7)  shl 5)  or ((xmc[32]        and $7) shl 2)  or ((xmc[33]  shr 1) and $3);
    d[24] :=   ((xmc[33]   and $1)  shl 7)  or ((xmc[34]        and $7) shl 4)  or ((xmc[35]         and $7) shl 1)      or ((xmc[36] shr 2) and $1);
    d[25] :=   ((xmc[36]   and $3)  shl 6)  or ((xmc[37]        and $7) shl 3)  or (xmc[38]          and $7);
    //
    d[26] :=   ((Nc[3]     and $7F) shl 1)  or ((bc[3]   shr 1) and $1);
    d[27] :=   ((bc[3]     and $1)  shl 7)  or ((Mc[3]          and $3) shl 5)  or ((xmaxc[3] shr 1) and $1F);
    d[28] :=   ((xmaxc[3]  and $1)  shl 7)  or ((xmc[39]        and $7) shl 4)  or ((xmc[40]         and $7) shl 1)      or ((xmc[41] shr 2) and $1);
    d[29] :=   ((xmc[41]   and $3)  shl 6)  or ((xmc[42]        and $7) shl 3)  or (xmc[43]          and $7);	//* 30 */
    d[30] :=   ((xmc[44]   and $7)  shl 5)  or ((xmc[45]        and $7) shl 2)  or ((xmc[46]  shr 1) and $3);
    d[31] :=   ((xmc[46]   and $1)  shl 7)  or ((xmc[47]        and $7) shl 4)  or ((xmc[48]         and $7) shl 1)      or ((xmc[49] shr 2) and $1);
    d[32] :=   ((xmc[49]   and $3)  shl 6)  or ((xmc[50]        and $7) shl 3)  or (xmc[51]          and $7);
{$IFDEF WAV49 }
  end;
{$ENDIF WAV49 }
end;

// --  --
function gsm_decode(s: gsm; c: pgsm_byte; target: pgsm_signal): int32;
var
  LARc: array[0..8 - 1] of _word;
  Nc: array[0..4 - 1] of _word;
  Mc: array[0..4 - 1] of _word;
  bc: array[0..4 - 1] of _word;
  xmaxc: array[0..4 - 1] of _word;
  xmc: array[0..13*4 - 1] of _word;
  //
{$IFDEF WAV49 }
  sr: uword;
{$ENDIF WAV49 }
  //
  d: pArray absolute c;
begin
{$IFDEF WAV49 }
  if (0 <> s.wav_fmt) then begin
    //
    //sr := 0;
    s.frame_index := not s.frame_index;
    if (0 <> s.frame_index) then begin
      //
      sr := d[00];                              LARc[0]  := sr and $3f;  sr := sr shr 6;
      sr := sr or uword(d[01]) shl 2;           LARc[1]  := sr and $3f;  sr := sr shr 6;
      sr := sr or uword(d[02]) shl 4;           LARc[2]  := sr and $1f;  sr := sr shr 5;
                                                LARc[3]  := sr and $1f;  sr := sr shr 5;
      sr := sr or uword(d[03]) shl 2;           LARc[4]  := sr and $f ;  sr := sr shr 4;
                                                LARc[5]  := sr and $f ;  sr := sr shr 4;
      sr := sr or uword(d[04]) shl 2;	        LARc[6]  := sr and $7 ;  sr := sr shr 3;          //* 5 */
                                                LARc[7]  := sr and $7 ;  sr := sr shr 3;
      sr := sr or uword(d[05]) shl 4;           Nc[0]    := sr and $7f;  sr := sr shr 7;
                                                bc[0]    := sr and $3 ;  sr := sr shr 2;
                                                Mc[0]    := sr and $3 ;  sr := sr shr 2;
      sr := sr or uword(d[06]) shl 1;           xmaxc[0] := sr and $3f;  sr := sr shr 6;
                                                xmc[0]   := sr and $7 ;  //sr := sr shr 3;
      sr             := d[07];                  xmc[1]   := sr and $7 ;  sr := sr shr 3;
                                                xmc[2]   := sr and $7 ;  sr := sr shr 3;
      sr := sr or uword(d[08]) shl 2;           xmc[3]   := sr and $7 ;  sr := sr shr 3;
                                                xmc[4]   := sr and $7 ;  sr := sr shr 3;
                                                xmc[5]   := sr and $7 ;  sr := sr shr 3;
      sr := sr or uword(d[09]) shl 1;		xmc[6]   := sr and $7 ;  sr := sr shr 3;	        //* 10 */
                                                xmc[7]   := sr and $7 ;  sr := sr shr 3;
                                                xmc[8]   := sr and $7 ;  //sr := sr shr 3;
      sr             := d[10];                  xmc[9]   := sr and $7 ;  sr := sr shr 3;
                                                xmc[10]  := sr and $7 ;  sr := sr shr 3;
      sr := sr or uword(d[11]) shl 2;           xmc[11]  := sr and $7 ;  sr := sr shr 3;
                                                xmc[12]  := sr and $7 ;  sr := sr shr 3;
      sr := sr or uword(d[12]) shl 4;           Nc[1]    := sr and $7f;  sr := sr shr 7;
                                                bc[1]    := sr and $3 ;  sr := sr shr 2;
                                                Mc[1]    := sr and $3 ;  sr := sr shr 2;
      sr := sr or uword(d[13]) shl 1;           xmaxc[1] := sr and $3f;  sr := sr shr 6;
                                                xmc[13]  := sr and $7 ;  //sr := sr shr 3;
      sr             := d[14];	                xmc[14]  := sr and $7 ;  sr := sr shr 3;  	//* 15 */
                                                xmc[15]  := sr and $7 ;  sr := sr shr 3;
      sr := sr or uword(d[15]) shl 2;           xmc[16]  := sr and $7 ;  sr := sr shr 3;
                                                xmc[17]  := sr and $7 ;  sr := sr shr 3;
                                                xmc[18]  := sr and $7 ;  sr := sr shr 3;
      sr := sr or uword(d[16]) shl 1;           xmc[19]  := sr and $7 ;  sr := sr shr 3;
                                                xmc[20]  := sr and $7 ;  sr := sr shr 3;
                                                xmc[21]  := sr and $7 ;  //sr := sr shr 3;
      sr             := d[17];                  xmc[22]  := sr and $7 ;  sr := sr shr 3;
                                                xmc[23]  := sr and $7 ;  sr := sr shr 3;
      sr := sr or uword(d[18]) shl 2;           xmc[24]  := sr and $7 ;  sr := sr shr 3;
                                                xmc[25]  := sr and $7 ;  sr := sr shr 3;
      sr := sr or uword(d[19]) shl 4;           Nc[2]    := sr and $7f;  sr := sr shr 7;   	//* 20 */
                                                bc[2]    := sr and $3 ;  sr := sr shr 2;
                                                Mc[2]    := sr and $3 ;  sr := sr shr 2;
      sr := sr or uword(d[20]) shl 1;           xmaxc[2] := sr and $3f;  sr := sr shr 6;
                                                xmc[26]  := sr and $7 ;  //sr := sr shr 3;
      sr             := d[21];                  xmc[27]  := sr and $7 ;  sr := sr shr 3;
                                                xmc[28]  := sr and $7 ;  sr := sr shr 3;
      sr := sr or uword(d[22]) shl 2;           xmc[29]  := sr and $7 ;  sr := sr shr 3;
                                                xmc[30]  := sr and $7 ;  sr := sr shr 3;
                                                xmc[31]  := sr and $7 ;  sr := sr shr 3;
      sr := sr or uword(d[23]) shl 1;           xmc[32]  := sr and $7 ;  sr := sr shr 3;
                                                xmc[33]  := sr and $7 ;  sr := sr shr 3;
                                                xmc[34]  := sr and $7 ;  //sr := sr shr 3;
      sr             := d[24];	                xmc[35]  := sr and $7 ;  sr := sr shr 3;	        //* 25 */
                                                xmc[36]  := sr and $7 ;  sr := sr shr 3;
      sr := sr or uword(d[25]) shl 2;           xmc[37]  := sr and $7 ;  sr := sr shr 3;
                                                xmc[38]  := sr and $7 ;  sr := sr shr 3;
      sr := sr or uword(d[26]) shl 4;           Nc[3]    := sr and $7f;  sr := sr shr 7;
                                                bc[3]    := sr and $3 ;  sr := sr shr 2;
                                                Mc[3]    := sr and $3 ;  sr := sr shr 2;
      sr := sr or uword(d[27]) shl 1;           xmaxc[3] := sr and $3f;  sr := sr shr 6;
                                                xmc[39]  := sr and $7 ;  //sr := sr shr 3;
      sr             := d[28];                  xmc[40]  := sr and $7 ;  sr := sr shr 3;
                                                xmc[41]  := sr and $7 ;  sr := sr shr 3;
      sr := sr or uword(d[29]) shl 2;		xmc[42]  := sr and $7 ;  sr := sr shr 3;	        //* 30 */
                                                xmc[43]  := sr and $7 ;  sr := sr shr 3;
                                                xmc[44]  := sr and $7 ;  sr := sr shr 3;
      sr := sr or uword(d[30]) shl 1;           xmc[45]  := sr and $7 ;  sr := sr shr 3;
                                                xmc[46]  := sr and $7 ;  sr := sr shr 3;
                                                xmc[47]  := sr and $7 ;  //sr := sr shr 3;
                                                //
      sr             := d[31];                  xmc[48]  := sr and $7 ;  sr := sr shr 3;
                                                xmc[49]  := sr and $7 ;  sr := sr shr 3;
      sr := sr or uword(d[32]) shl 2;           xmc[50]  := sr and $7 ;  sr := sr shr 3;
                                                xmc[51]  := sr and $7 ;  sr := sr shr 3;
      s.frame_chain := sr and $f;       // we read 264 bits, so remember last 4 bits, as they belong to next 260-bitframe
    end
    else begin
      sr := s.frame_chain;
      sr := sr or uword(d[00]) shl 4;	        LARc[0]  := sr and $3f;  sr := sr shr 6;		//* 1 */  <-- Technically, it is #33 (Lake)
                                                LARc[1]  := sr and $3f;  //sr := sr shr 6;
      sr             :=(d[01]);                 LARc[2]  := sr and $1f;  sr := sr shr 5;
      sr := sr or uword(d[02]) shl 3;           LARc[3]  := sr and $1f;  sr := sr shr 5;
                                                LARc[4]  := sr and $f;   sr := sr shr 4;
      sr := sr or uword(d[03]) shl 2;           LARc[5]  := sr and $f;   sr := sr shr 4;
                                                LARc[6]  := sr and $7;   sr := sr shr 3;
                                                LARc[7]  := sr and $7;   //sr := sr shr 3;
      //
      sr             :=(d[04]);	        	Nc[0]    := sr and $7f;  sr := sr shr 7;           //* 5 */
      sr := sr or uword(d[05]) shl 1;           bc[0]    := sr and $3;   sr := sr shr 2;
                                                Mc[0]    := sr and $3;   sr := sr shr 2;
      sr := sr or uword(d[06]) shl 5;           xmaxc[0] := sr and $3f;  sr := sr shr 6;
                                                xmc[0]   := sr and $7;   sr := sr shr 3;
                                                xmc[1]   := sr and $7;   sr := sr shr 3;
      sr := sr or uword(d[07]) shl 1;           xmc[2]   := sr and $7;   sr := sr shr 3;
                                                xmc[3]   := sr and $7;   sr := sr shr 3;
                                                xmc[4]   := sr and $7;   //sr := sr shr 3;
      sr             :=(d[08]);                 xmc[5]   := sr and $7;   sr := sr shr 3;
                                                xmc[6]   := sr and $7;   sr := sr shr 3;
      sr := sr or uword(d[09]) shl 2;		xmc[7]   := sr and $7;   sr := sr shr 3;           //* 10 */
                                                xmc[8]   := sr and $7;   sr := sr shr 3;
                                                xmc[9]   := sr and $7;   sr := sr shr 3;
      sr := sr or uword(d[10]) shl 1;           xmc[10]  := sr and $7;   sr := sr shr 3;
                                                xmc[11]  := sr and $7;   sr := sr shr 3;
                                                xmc[12]  := sr and $7;   //sr := sr shr 3;
      //
      sr             :=(d[11]);                 Nc[1]    := sr and $7f;  sr := sr shr 7;
      sr := sr or uword(d[12]) shl 1;           bc[1]    := sr and $3;   sr := sr shr 2;
                                                Mc[1]    := sr and $3;   sr := sr shr 2;
      sr := sr or uword(d[13]) shl 5;           xmaxc[1] := sr and $3f;  sr := sr shr 6;
                                                xmc[13]  := sr and $7;   sr := sr shr 3;
                                                xmc[14]  := sr and $7;   sr := sr shr 3;
      sr := sr or uword(d[14]) shl 1;		xmc[15]  := sr and $7;   sr := sr shr 3;          //* 15 */
                                                xmc[16]  := sr and $7;   sr := sr shr 3;
                                                xmc[17]  := sr and $7;   //sr := sr shr 3;
      sr             :=(d[15]);                 xmc[18]  := sr and $7;   sr := sr shr 3;
                                                xmc[19]  := sr and $7;   sr := sr shr 3;
      sr := sr or uword(d[16]) shl 2;           xmc[20]  := sr and $7;   sr := sr shr 3;
                                                xmc[21]  := sr and $7;   sr := sr shr 3;
                                                xmc[22]  := sr and $7;   sr := sr shr 3;
      sr := sr or uword(d[17]) shl 1;           xmc[23]  := sr and $7;   sr := sr shr 3;
                                                xmc[24]  := sr and $7;   sr := sr shr 3;
                                                xmc[25]  := sr and $7;   //sr := sr shr 3;
      //
      sr             :=(d[18]);                 Nc[2]    := sr and $7f;  sr := sr shr 7;
      sr := sr or uword(d[19]) shl 1;		bc[2]    := sr and $3;   sr := sr shr 2;            //* 20 */
                                                Mc[2]    := sr and $3;   sr := sr shr 2;
      sr := sr or uword(d[20]) shl 5;           xmaxc[2] := sr and $3f;  sr := sr shr 6;
                                                xmc[26]  := sr and $7;   sr := sr shr 3;
                                                xmc[27]  := sr and $7;   sr := sr shr 3;
      sr := sr or uword(d[21]) shl 1;           xmc[28]  := sr and $7;   sr := sr shr 3;
                                                xmc[29]  := sr and $7;   sr := sr shr 3;
                                                xmc[30]  := sr and $7;   //sr := sr shr 3;
      sr             :=(d[22]);                 xmc[31]  := sr and $7;   sr := sr shr 3;
                                                xmc[32]  := sr and $7;   sr := sr shr 3;
      sr := sr or uword(d[23]) shl 2;           xmc[33]  := sr and $7;   sr := sr shr 3;
                                                xmc[34]  := sr and $7;   sr := sr shr 3;
                                                xmc[35]  := sr and $7;   sr := sr shr 3;
      sr := sr or uword(d[24]) shl 1;		xmc[36]  := sr and $7;   sr := sr shr 3;          //* 25 */
                                                xmc[37]  := sr and $7;   sr := sr shr 3;
                                                xmc[38]  := sr and $7;   //sr := sr shr 3;
      //
      sr             :=(d[25]);                 Nc[3]    := sr and $7f;  sr := sr shr 7;
      sr := sr or uword(d[26]) shl 1;           bc[3]    := sr and $3;   sr := sr shr 2;
                                                Mc[3]    := sr and $3;   sr := sr shr 2;
      sr := sr or uword(d[27]) shl 5;           xmaxc[3] := sr and $3f;  sr := sr shr 6;
                                                xmc[39]  := sr and $7;   sr := sr shr 3;
                                                xmc[40]  := sr and $7;   sr := sr shr 3;
      sr := sr or uword(d[28]) shl 1;           xmc[41]  := sr and $7;   sr := sr shr 3;
                                                xmc[42]  := sr and $7;   sr := sr shr 3;
                                                xmc[43]  := sr and $7;   //sr := sr shr 3;
      sr             :=(d[29]);                 xmc[44]  := sr and $7;   sr := sr shr 3;          //* 30 */
                                                xmc[45]  := sr and $7;   sr := sr shr 3;
      sr := sr or uword(d[30]) shl 2;           xmc[46]  := sr and $7;   sr := sr shr 3;
                                                xmc[47]  := sr and $7;   sr := sr shr 3;
                                                xmc[48]  := sr and $7;   sr := sr shr 3;
      sr := sr or uword(d[31]) shl 1;           xmc[49]  := sr and $7;   sr := sr shr 3;        // <-- Behold the magic, only 32 bytes in #1 frames
                                                xmc[50]  := sr and $7;   sr := sr shr 3;        // (That is OK, since the whole block is 65 bytes long)
                                                xmc[51]  := sr and $7;   //sr := sr shr 3;
    end;
  end
  else begin
{$ENDIF WAV49 }
    //* GSM_MAGIC  = (*c >> 4) & 0xF; */
    if (GSM_MAGIC <> (( d[00] shr 4) and $0F)) then begin result := -1; exit; end;
    //
    LARc[0]  := ( d[00]        and $F)  shl 2;		        LARc[0] := LARc[0]   or (d[01] shr 6) and $3;          //* 1 */
    LARc[1]  :=   d[01]        and $3F;
    LARc[2]  := ( d[02] shr 3) and $1F;
    LARc[3]  := ( d[02]        and $7)  shl 2;                   LARc[3] := LARc[3]   or (d[03] shr 6) and $3;
    LARc[4]  := ( d[03] shr 2) and $F;
    LARc[5]  := ( d[03]        and $3)  shl 2;                   LARc[5] := LARc[5]   or (d[04] shr 6) and $3;
    LARc[6]  := ( d[04] shr 3) and $7;
    LARc[7]  :=   d[04]        and $7;
    Nc[0]    := ( d[05] shr 1) and $7F;
    bc[0]    := ( d[05]        and $1)  shl 1;                   bc[0] := bc[0]       or (d[06] shr 7) and $1;
    Mc[0]    := ( d[06] shr 5) and $3;
    xmaxc[0] := ( d[06]        and $1F) shl 1;                   xmaxc[0] := xmaxc[0] or (d[07] shr 7) and $1;
    xmc[0]   := ( d[07] shr 4) and $7;
    xmc[1]   := ( d[07] shr 1) and $7;
    xmc[2]   := ( d[07]        and $1)  shl 2;                   xmc[2] := xmc[2]     or (d[08] shr 6) and $3;
    xmc[3]   := ( d[08] shr 3) and $7;
    xmc[4]   :=   d[08]        and $7;
    xmc[5]   := ( d[09] shr 5) and $7;
    xmc[6]   := ( d[09] shr 2) and $7;
    xmc[7]   := ( d[09]        and $3)  shl 1;                   xmc[7] := xmc[7]     or (d[10] shr 7) and $1;            //* 10 */
    xmc[8]   := ( d[10] shr 4) and $7;
    xmc[9]   := ( d[10] shr 1) and $7;
    xmc[10]  := ( d[10]        and $1)  shl 2;                   xmc[10] := xmc[10]   or (d[11] shr 6) and $3;
    xmc[11]  := ( d[11] shr 3) and $7;
    xmc[12]  :=   d[11]        and $7;
    Nc[1]    := ( d[12] shr 1) and $7F;
    bc[1]    := ( d[12]        and $1)  shl 1;                   bc[1] := bc[1]       or (d[13] shr 7) and $1;
    Mc[1]    := ( d[13] shr 5) and $3;
    xmaxc[1] := ( d[13]        and $1F) shl 1;                   xmaxc[1] := xmaxc[1] or (d[14] shr 7) and $1;
    xmc[13]  := ( d[14] shr 4) and $7;
    xmc[14]  := ( d[14] shr 1) and $7;
    xmc[15]  := ( d[14]        and $1)  shl 2;                   xmc[15] := xmc[15]   or (d[15] shr 6) and $3;
    xmc[16]  := ( d[15] shr 3) and $7;
    xmc[17]  :=   d[15]        and $7;
    xmc[18]  := ( d[16] shr 5) and $7;
    xmc[19]  := ( d[16] shr 2) and $7;
    xmc[20]  := ( d[16]        and $3)  shl 1;                   xmc[20] := xmc[20]   or (d[17] shr 7) and $1;
    xmc[21]  := ( d[17] shr 4) and $7;
    xmc[22]  := ( d[17] shr 1) and $7;
    xmc[23]  := ( d[17]        and $1)  shl 2;                   xmc[23] := xmc[23]   or (d[18] shr 6) and $3;
    xmc[24]  := ( d[18] shr 3) and $7;
    xmc[25]  :=   d[18]        and $7;
    Nc[2]    := ( d[19] shr 1) and $7F;
    bc[2]    := ( d[19]        and $1)  shl 1;                   bc[2] := bc[2]       or (d[20] shr 7) and $1;              //* 20 */
    Mc[2]    := ( d[20] shr 5) and $3;
    xmaxc[2] := ( d[20]        and $1F) shl 1;                   xmaxc[2] := xmaxc[2] or (d[21] shr 7) and $1;
    xmc[26]  := ( d[21] shr 4) and $7;
    xmc[27]  := ( d[21] shr 1) and $7;
    xmc[28]  := ( d[21]        and $1)  shl 2;                   xmc[28] := xmc[28]   or (d[22] shr 6) and $3;
    xmc[29]  := ( d[22] shr 3) and $7;
    xmc[30]  :=   d[22]        and $7;
    xmc[31]  := ( d[23] shr 5) and $7;
    xmc[32]  := ( d[23] shr 2) and $7;
    xmc[33]  := ( d[23]        and $3)  shl 1;                   xmc[33] := xmc[33]   or (d[24] shr 7) and $1;
    xmc[34]  := ( d[24] shr 4) and $7;
    xmc[35]  := ( d[24] shr 1) and $7;
    xmc[36]  := ( d[24]        and $1)  shl 2;                   xmc[36] := xmc[36]   or (d[25] shr 6) and $3;
    xmc[37]  := ( d[25] shr 3) and $7;
    xmc[38]  :=   d[25]        and $7;
    Nc[3]    := ( d[26] shr 1) and $7F;
    bc[3]    := ( d[26]        and $1)  shl 1;                   bc[3] := bc[3]       or (d[27] shr 7) and $1;
    Mc[3]    := ( d[27] shr 5) and $3;
    xmaxc[3] := ( d[27]        and $1F) shl 1;                   xmaxc[3] := xmaxc[3] or (d[28] shr 7) and $1;
    xmc[39]  := ( d[28] shr 4) and $7;
    xmc[40]  := ( d[28] shr 1) and $7;
    xmc[41]  := ( d[28]        and $1)  shl 2;                   xmc[41] := xmc[41]   or (d[29] shr 6) and $3;
    xmc[42]  := ( d[29] shr 3) and $7;
    xmc[43]  :=   d[29]        and $7;  		                                                                // 30  */
    xmc[44]  := ( d[30] shr 5) and $7;
    xmc[45]  := ( d[30] shr 2) and $7;
    xmc[46]  := ( d[30]        and $3)  shl 1;                   xmc[46] := xmc[46]   or (d[31] shr 7) and $1;
    xmc[47]  := ( d[31] shr 4) and $7;
    xmc[48]  := ( d[31] shr 1) and $7;
    xmc[49]  := ( d[31]        and $1)  shl 2;                   xmc[49] := xmc[49]   or (d[32] shr 6) and $3;
    xmc[50]  := ( d[32] shr 3) and $7;
    xmc[51]  :=   d[32]        and $7;			                                                        //* 33 */
{$IFDEF WAV49 }
  end;
{$ENDIF WAV49 }
  //
  Gsm_Decoder(s, _pword(@LARc), _pword(@Nc), _pword(@bc), _pword(@Mc), _pword(@xmaxc), _pword(@xmc), _pword(target));

  result := 0;
end;


// -- LoS specific --


{ unaGSMcoder }

// --  --
constructor unaGSMcoder.create(isWav49: bool);
begin
  f_gsm := gsm_create();
  //
  if (isWav49) then
    gsmOpt[GSM_OPT_WAV49] := 1
  else
    gsmOpt[GSM_OPT_WAV49] := 0;
  //
  f_stream := unaMemoryStream.create();
  //
  initCoder();
  //
  inherited create();
end;

// --  --
destructor unaGSMcoder.Destroy();
begin
  gsm_destroy(f_gsm);
  //
  freeAndNil(f_stream);
  //
  f_bufSize := 0;
  mrealloc(f_buf);
  //
  inherited;
end;

// --  --
function unaGSMcoder.getOpt(opt: int32): int32;
begin
  result := gsm_option(f_gsm, opt, nil);
end;

// --  --
function unaGSMcoder.lockBuf(size: int): pointer;
begin
  // TODO: make it per-buffer lock
  if (acquire(false, 100)) then begin
    //
    if (f_bufSize < size) then begin
      //
      mrealloc(f_buf, size);
      f_bufSize := size;
    end;
    //
    result := f_buf;
  end
  else
    result := nil;
end;

// --  --
procedure unaGSMcoder.onNewData(sender: unaObject; data: pointer; len: int);
begin
  // override to receive data
end;

// --  --
procedure unaGSMcoder.setOpt(opt: int32; value: int32);
begin
  gsm_option(f_gsm, opt, @value);
  //
  initCoder();  // recalculate internal stuff
end;

// --  --
procedure unaGSMcoder.unlockBuf(buf: pointer);
begin
  // TODO: make it per-buffer lock
  releaseWO();
end;

// --  --
function unaGSMcoder.write(data: pointer; len: int): int;
var
  buf: array[0..640 - 1] of byte;
  sz, szStream: int;
begin
  result := 0;
  //
  // do we have not full frame left from previous writes?
  szStream := min(frameSizeIn, f_stream.getAvailableSize());
  if ((0 < szStream) and (szStream < frameSizeIn)) then begin
    //
    // can we make a full frame?
    if (szStream + len >= frameSizeIn) then begin
      //
      if (sizeof(buf) >= frameSizeIn) then begin
        //
        sz := frameSizeIn - szStream;
        f_stream.read(@buf[0], szStream);
        if (0 < sz) then begin
          //
          move(data^, buf[szStream], sz);
          dec(len, sz);
          inc(pByte(data), sz);
        end
        else ;  // its rather strange, but anyways
        //
        processFrames(@buf, frameSizeIn);
        inc(result, frameSizeIn);
      end
      else
        // kinda strange frame size, process it via stream buf
    end;
  end;
  //
  // no more data in stream? try direct feed
  if ((1 > f_stream.getAvailableSize()) and (frameSizeIn <= len)) then begin
    //
    sz := (len div frameSizeIn) * frameSizeIn;
    if (0 < sz) then begin
      //
      processFrames(data, sz);
      inc(result, sz);
      //
      dec(len, sz);
      inc(pByte(data), sz);
    end;
  end;
  //
  // leftovers?
  if (0 < len) then
    f_stream.write(data, len);
  //
  // stream has full frame(s)?
  szStream := min(frameSizeIn, f_stream.getAvailableSize());
  if ((0 < szStream) and (szStream >= frameSizeIn)) then begin
    //
    if (f_stream.enter(false)) then try
      //
      sz := (f_stream.compressChunks() div frameSizeIn) * frameSizeIn;
      if (0 < sz) then begin
        //
        processFrames(f_stream.firstChunk().data, sz);
        inc(result, sz);
        //
        f_stream.remove(sz);
      end;
    finally
      f_stream.leaveWO();
    end;
  end;
end;


{ unaGSMEncoder }

// --  --
procedure unaGSMEncoder.initCoder();
begin
  if (0 <> gsmOpt[GSM_OPT_WAV49]) then begin
    //
    f_frameSizeIn := 640;	// bytes
    f_frameSizeOut := 65;	// bytes
  end
  else begin
    //
    f_frameSizeIn := 320;	// bytes
    f_frameSizeOut := 33;	// bytes
  end;
end;

// --  --
procedure unaGSMEncoder.processFrames(data: pointer; len: int);
var
  sz: int;
  buf: pointer;
begin
  sz := frameSizeIn;
  while (len >= sz) do begin
    //
    buf := lockBuf(frameSizeOut);
    if (nil <> buf) then try
      //
      if (0 <> gsmOpt[GSM_OPT_WAV49]) then begin
        //
        // read 320 bytes and pack them into 33 bytes (last byte has only half byte filled, next call to encode will fill the rest of it)
        gsm_encode(f_gsm, data, buf);
        //
        // read another 320 bytes and pack them into more 33 bytes (adding half byte from previous encoding)
        gsm_encode(f_gsm, pgsm_signal(@pArray(data)[sz shr 1]), @pArray(buf)[32]);
      end
      else
        gsm_encode(f_gsm, data, buf);
      //
      onNewData(self, buf, frameSizeOut);
      //
    finally
      unlockBuf(buf);
    end;
    //
    inc(pByte(data), sz);
    dec(len, sz);
  end;
end;


{ unaGSMDecoder }

// --  --
procedure unaGSMDecoder.initCoder();
begin
  if (0 <> gsmOpt[GSM_OPT_WAV49]) then begin
    //
    f_frameSizeIn := 65;
    f_frameSizeOut := 640;
  end
  else begin
    //
    f_frameSizeIn := 33;
    f_frameSizeOut := 320;
  end;
end;

// --  --
procedure unaGSMDecoder.processFrames(data: pointer; len: int);
var
  sz: int;
  buf, buf2: pointer;
  half: int;
begin
  sz := frameSizeIn;
  while (len >= sz) do begin
    //
    buf := lockBuf(frameSizeOut);
    if (nil <> buf) then try
      //
      if (0 <> gsmOpt[GSM_OPT_WAV49]) then begin
        //
        half := frameSizeOut shr 1;
        //
        // read 33 bytes (+ carry over half byte from #33 to next frame), decode them into 320 bytes
        gsm_decode(f_gsm, data, buf);
        onNewData(self, buf, half);
        //
        // read another 33 bytes (first byte is made from 4 bit carried over from previous frame and half first of byte), decode to another 320 bytes
        buf2 := pgsm_signal(@pArray(buf)[half]);
        gsm_decode(f_gsm, @pArray(data)[33], buf2);
        onNewData(self, buf2, half);
      end
      else begin
        //
        gsm_decode(f_gsm, data, buf);
        //
        onNewData(self, buf, frameSizeOut);
      end;
      //
    finally
      unlockBuf(buf);
    end;
    //
    inc(pByte(data), sz);
    dec(len, sz);
  end;
end;


end.
