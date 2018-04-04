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


{
       =============================================================
       COPYRIGHT NOTE: This source code, and all of its derivations,
       is subject to the "ITU-T General Public License". Please have
       it  read  in    the  distribution  disk,   or  in  the  ITU-T
       Recommendation G.191 on "SOFTWARE TOOLS FOR SPEECH AND  AUDIO
       CODING STANDARDS".
       =============================================================
}

(*
	----------------------------------------------

	  unaG711.pas - VC 3.0 G711 algorithm
	  VC components version 3.0

	----------------------------------------------
          Delphi conversion of original ANSI-C code:

	  Copyright (c) 2010-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 09 Feb 2010

	  modified by:
		Lake, Feb 2010

	----------------------------------------------
*)

{$I unaDef.inc }

{$IFDEF DEBUG }
  //
  {$DEFINE LOG_G711_INFOS }	// log informational messages
  {$DEFINE LOG_G711_ERRORS }	// log critical errors
{$ENDIF DEBUG }

{*
  G711 implementation based on ITU source code

  @Author Lake

  1.0 First release
}

unit
  unaG711;

interface

uses
  Windows, unaTypes;

(*                                                 Version 3.01 - 31.Jan.2000

			  U    U   GGG    SSS  TTTTT
			  U    U  G      S       T
			  U    U  G  GG   SSS    T
			  U    U  G   G      S   T
			   UUUU    GGG    SSS    T

		   ========================================
		    ITU-T - USER'S GROUP ON SOFTWARE TOOLS
		   ========================================


       =============================================================
       COPYRIGHT NOTE: This source code, and all of its derivations,
       is subject to the "ITU-T General Public License". Please have
       it  read  in    the  distribution  disk,   or  in  the  ITU-T
       Recommendation G.191 on "SOFTWARE TOOLS FOR SPEECH AND  AUDIO
       CODING STANDARDS".
       =============================================================


MODULE:	G711.C, G.711 ENCODING/DECODING FUNCTIONS

ORIGINAL BY:

     Simao Ferraz de Campos Neto          Rudolf Hofmann
     CPqD/Telebras                        PHILIPS KOMMUNIKATIONS INDUSTRIE AG
     DDS/Pr.11                            Kommunikationssysteme
     Rd. Mogi Mirim-Campinas Km.118       Thurn-und-Taxis-Strasse 14
     13.085 - Campinas - SP (Brazil)      D-8500 Nuernberg 10 (Germany)

     Phone : +55-192-39-6396              Phone : +49 911 526-2603
     FAX   : +55-192-53-4754              FAX   : +49 911 526-3385
     EMail : tdsimao@venus.cpqd.ansp.br   EMail : HF@PKINBG.UUCP


FUNCTIONS:

alaw_compress: ... compands 1 vector of linear PCM samples to A-law;
                   uses 13 Most Sig.Bits (MSBs) from input and 8 Least
                   Sig. Bits (LSBs) on output.

alaw_expand: ..... expands 1 vector of A-law samples to linear PCM;
                   use 8 Least Sig. Bits (LSBs) from input and
                   13 Most Sig.Bits (MSBs) on output.

ulaw_compress: ... compands 1 vector of linear PCM samples to u-law;
                   uses 14 Most Sig.Bits (MSBs) from input and 8 Least
                   Sig. Bits (LSBs) on output.

ulaw_expand: ..... expands 1 vector of u-law samples to linear PCM
                   use 8 Least Sig. Bits (LSBs) from input and
                   14 Most Sig.Bits (MSBs) on output.

PROTOTYPES: in g711.h

HISTORY:
Apr/91       1.0   First version of the G711 module
10/Dec/1991  2.0   Break-up in individual functions for A,u law;
                   correction of bug in compression routines (use of 1
                   and 2 complement); Demo program inside module.
08/Feb/1992  3.0   Demo as separate file;
31/Jan/2000  3.01  Updated documentation text; no change in functions
                   <simao.campos@labs.comsat.com>
=============================================================================
*)


(*
  ============================================================================
   File: G711.H
  ============================================================================

			    UGST/ITU-T G711 MODULE

			  GLOBAL FUNCTION PROTOTYPES

   History:
   10.Dec.91	v1.0	First version <hf@pkinbg.uucp>
   08.Feb.92	v1.1	Non-ANSI prototypes added <tdsimao@venus.cpqd.ansp.br>
   11.Jan.96    v1.2    Fixed misleading prototype parameter names in
			alaw_expand() and ulaw_compress(); changed to
			smart prototypes <simao@ctd.comsat.com>,
			and <Volker.Springer@eedn.ericsson.se>
   31.Jan.2000  v3.01   [version no.aligned with g711.c] Updated list of
			compilers for smart prototypes
  ============================================================================
*)

(*
  ==========================================================================

   FUNCTION NAME: alaw_compress

   DESCRIPTION: ALaw encoding rule according ITU-T Rec. G.711.

   PROTOTYPE: void alaw_compress(long lseg, short *linbuf, short *logbuf)

   PARAMETERS:
     lseg:	(In)  number of samples
     linbuf:	(In)  buffer with linear samples (only 12 MSBits are taken
		      into account)
     logbuf:	(Out) buffer with compressed samples (8 bit right justified,
		      without sign extension)

   RETURN VALUE: none.

   HISTORY:
   10.Dec.91	1.0	Separated A-law compression function

  ==========================================================================
*)
procedure alaw_compress(lseg: long; linbuf: pInt16Array; logbuf: pointer);

(*
  ==========================================================================

   FUNCTION NAME: alaw_expand

   DESCRIPTION: ALaw decoding rule according ITU-T Rec. G.711.

   PROTOTYPE: void alaw_expand(long lseg, short *logbuf, short *linbuf)

   PARAMETERS:
     lseg:	(In)  number of samples
     logbuf:	(In)  buffer with compressed samples (8 bit right justified,
		      without sign extension)
     linbuf:	(Out) buffer with linear samples (13 bits left justified)

   RETURN VALUE: none.

   HISTORY:
   10.Dec.91	1.0	Separated A-law expansion function

  ============================================================================
*)
procedure alaw_expand(lseg: long; logbuf: pointer; linbuf: pInt16Array);

(*
  ==========================================================================

   FUNCTION NAME: ulaw_compress

   DESCRIPTION: Mu law encoding rule according ITU-T Rec. G.711.

   PROTOTYPE: void ulaw_compress(long lseg, short *linbuf, short *logbuf)

   PARAMETERS:
     lseg:	(In)  number of samples
     linbuf:	(In)  buffer with linear samples (only 12 MSBits are taken
		      into account)
     logbuf:	(Out) buffer with compressed samples (8 bit right justified,
		      without sign extension)

   RETURN VALUE: none.

   HISTORY:
   10.Dec.91	1.0	Separated mu-law compression function

  ==========================================================================
*)
procedure ulaw_compress(lseg: long; linbuf: pInt16Array; logbuf: pointer);

(*
  ==========================================================================

   FUNCTION NAME: ulaw_expand

   DESCRIPTION: Mu law decoding rule according ITU-T Rec. G.711.

   PROTOTYPE: void ulaw_expand(long lseg, short *logbuf, short *linbuf)

   PARAMETERS:
     lseg:	(In)  number of samples
     logbuf:	(In)  buffer with compressed samples (8 bit right justified,
		      without sign extension)
     linbuf:	(Out) buffer with linear samples (14 bits left justified)

   RETURN VALUE: none.

   HISTORY:
   10.Dec.91	1.0	Separated mu law expansion function

  ============================================================================
*)
procedure ulaw_expand(lseg: long; logbuf: pointer; linbuf: pInt16Array);


implementation


// --  --
procedure alaw_compress(lseg: long; linbuf: pInt16Array; logbuf: pointer);
var
  n, ix, iexp: int;
begin
  for n := 0 to lseg - 1 do begin
    //
    if (linbuf[n] < 0) then		//* 0 <= ix < 2048 */
      ix := (not linbuf[n]) shr 4	//* 1's complement for negative values */
    else
      ix := linbuf[n] shr 4;
    //
    //* Do more, if exponent > 0 */
    if (ix > 15) then begin		//* exponent=0 for ix <= 15 */
      //
      iexp := 1;			//* first step: */
      while (ix > 16 + 15) do begin	        //* find mantissa and exponent */
	//
	ix := ix shr 1;
	inc(iexp);
      end;
      ix := ix - 16;			//* second step: remove leading '1' */
      //
      ix := ix + iexp shl 4;		//* now compute encoded value */
    end;
    //
    if (linbuf[n] >= 0) then
      ix := ix or $0080;		//* add sign bit */
    //
    pArray(logbuf)[n] := ix xor $0055;		//* toggle even bits */
  end;
end;

// --  --
procedure alaw_expand(lseg: long; logbuf: pointer; linbuf: pInt16Array);
var
  n, ix, mant, iexp: int;
begin
  for n := 0 to lseg - 1 do begin
    //
    ix := pArray(logbuf)[n] xor $0055;	//* re-toggle toggled bits */
    //
    ix := ix and $007F;		//* remove sign bit */
    iexp := ix shr 4;		//* extract exponent */
    mant := ix and $000F;	//* now get mantissa */
    if (iexp > 0) then
      mant := mant + 16;	//* add leading '1', if exponent > 0 */
    //
    mant := (mant shl 4) + $0008;	//* now mantissa left justified and */
					//* 1/2 quantization step added */
    if (iexp > 1) then		//* now left shift according exponent */
      mant := mant shl (iexp - 1);
    //
    if (pArray(logbuf)[n] > 127) then	//* invert, if negative sample */
      linbuf[n] := mant
    else
      linbuf[n] := -mant;
  end;
end;

// --  --
procedure ulaw_compress(lseg: long; linbuf: pInt16Array; logbuf: pointer);
var
  n,            //* samples's count */
  i,		//* aux.var. */
  absno,		//* absolute value of linear (input) sample */
  segno,		//* segment (Table 2/G711, column 1) */
  low_nibble,		//* low  nibble of log companded sample */
  high_nibble: int;	//* high nibble of log companded sample */
begin
  for n := 0 to lseg - 1 do begin
    //
    //* -------------------------------------------------------------------- */
    //* Change from 14 bit left justified to 14 bit right justified */
    //* Compute absolute value; adjust for easy processing */
    //* -------------------------------------------------------------------- */
    if (linbuf[n] < 0) then	//* compute 1's complement in case of  */
      absno := (not linbuf[n]) shr 2 + 33
    else
      absno := (linbuf[n]) shr 2 + 33; //* NB: 33 is the difference value */
    //
    //* between the thresholds for */
    //* A-law and u-law. */
    if (absno > $1FFF) then	//* limitation to "absno" < 8192 */
      absno := $1FFF;
    //
    //* Determination of sample's segment */
    i := absno shr 6;
    segno := 1;
    while (i <> 0) do begin
      //
      inc(segno);
      i := i shr 1;
    end;
    //
    //* Mounting the high-nibble of the log-PCM sample */
    high_nibble := $0008 - segno;
    //
    //* Mounting the low-nibble of the log PCM sample */
    low_nibble := (absno shr segno)	//* right shift of mantissa and */
      and $000F;		//* masking away leading '1' */
    low_nibble := $000F - low_nibble;
    //
    //* Joining the high-nibble and the low-nibble of the log PCM sample */
    pArray(logbuf)[n] := (high_nibble shl 4) or low_nibble;
    //
    //* Add sign bit */
    if (linbuf[n] >= 0) then
      pArray(logbuf)[n] := pArray(logbuf)[n] or $0080;
  end;
end;

// --  --
procedure ulaw_expand(lseg: long; logbuf: pointer; linbuf: pInt16Array);
var
  n,		//* aux.var. */
  segment,	//* segment (Table 2/G711, column 1) */
  mantissa,	//* low  nibble of log companded sample */
  exponent,	//* high nibble of log companded sample */
  step: int;
begin
  for n := 0 to lseg - 1 do begin
    //
    mantissa := not pArray(logbuf)[n];	//* 1's complement of input value */
    exponent := (mantissa shr 4) and $0007;	//* extract exponent */
    segment := exponent + 1;	//* compute segment number */
    mantissa := mantissa and $000F;	//* extract mantissa */
    //
    //* Compute Quantized Sample (14 bit left justified!) */
    step := 4 shl segment;	//* position of the LSB */
    //* = 1 quantization step) */
    linbuf[n] := //sign *		//* sign */
      ($0080 shl exponent)	//* '1', preceding the mantissa */
       + step * mantissa	//* left shift of mantissa */
       + step shr 1		//* 1/2 quantization step */
       - 4 * 33;
    //
    if (pArray(logbuf)[n] < $0080) then	//* sign-bit = 1 for positiv values */
      linbuf[n] := -linbuf[n];
  end;
end;


end.

