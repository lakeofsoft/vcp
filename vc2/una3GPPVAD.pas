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
	 3GPP © 2010
	 http://www.3gpp.org/Legal-Notice
	----------------------------------------------
	 Delphi conversion (c) 2010 Lake of Soft
	 All rights reserved

	 http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, ? Jan 2010

	  modified by:
		Lake, Feb 2010

	----------------------------------------------
*)

{$I unaDef.inc }

unit
  una3GPPVAD;

interface

uses
  Windows, unaTypes;

(*
********************************************************************************
**-------------------------------------------------------------------------**
**                                                                         **
**     GSM AMR-NB speech codec   R98   Version 7.6.0   December 12, 2001       **
**                               R99   Version 3.3.0                       **
**                               REL-4 Version 4.1.0                       **
**                                                                         **
**-------------------------------------------------------------------------**
********************************************************************************
*
*      File             : vad1.h
*      Purpose          : Voice Activity Detection (VAD) for AMR (option 1)
*
********************************************************************************
*)
//#ifndef vad1_h
//#define vad1_h "$Id $"

(*
********************************************************************************
*                         INCLUDE FILES
********************************************************************************
*)
//#include "typedef.h"

(*
********************************************************************************
*
*      GSM AMR-NB speech codec   R98   Version 7.6.0   December 12, 2001
*                                R99   Version 3.3.0
*                                REL-4 Version 4.1.0
*
********************************************************************************
*
*      File             : typedef.c
*      Purpose          : Basic types.
*
********************************************************************************

//

*      The following platform independent data types and corresponding
*      preprocessor (#define) constants are defined:
*
*        defined type  meaning           corresponding constants
*        ----------------------------------------------------------
*        Char          character         (none)
*        Bool          boolean           true, false
*        Word8         8-bit signed      minWord8,   maxWord8
*        UWord8        8-bit unsigned    minUWord8,  maxUWord8
*        Word16        16-bit signed     minWord16,  maxWord16
*        UWord16       16-bit unsigned   minUWord16, maxUWord16
*        Word32        32-bit signed     minWord32,  maxWord32
*        UWord32       32-bit unsigned   minUWord32, maxUWord32
*        Float         floating point    minFloat,   maxFloat

*)
type
  Word8 	= int8;
  UWord8	= uint8;
  Word16        = int16;
  UWord16       = uint16;
  Word32        = int32;
  UWord32       = uint32;
//
  pWord8 	= ^Word8;
  pUWord8	= ^UWord8;
  pWord16       = ^Word16;
  pUWord16      = ^UWord16;
  pWord32       = ^Word32;
  pUWord32      = ^UWord32;

  Word16array       = array[word] of Word16;
  pWord16array      = ^Word16array;

//#include "cnst_vad.h"
(*
********************************************************************************
**-------------------------------------------------------------------------**
**                                                                         **
**     GSM AMR-NB speech codec   R98   Version 7.6.0   December 12, 2001       **
**                               R99   Version 3.3.0                       **
**                               REL-4 Version 4.1.0                       **
**                                                                         **
**-------------------------------------------------------------------------**
********************************************************************************
*
*      File             : cnst_vad.h
*      Purpose          : Constants and definitions for VAD
*
********************************************************************************
*)
//#ifndef cnst_vad_h
//#define cnst_vad_h "$Id $"

const
  MAX_32	= Word32($7fffffff);
  MIN_32	= Word32($80000000);

  MAX_16 	= Word16($7fff);
  MIN_16 	= Word16($8000);

const
  FRAME_LEN	= 160;    ///* Length (samples) of the input frame          */
  COMPLEN	= 9;        ///* Number of sub-bands used by VAD              */
  INV_COMPLEN 	= 3641; ///* 1.0/COMPLEN*2^15                             */
  //LOOKAHEAD	= 40;     ///* length of the lookahead used by speech coder */

  UNITY		= 512;        ///* Scaling used with SNR calculation            */
  UNIRSHFT	= 6;       ///* = log2(MAX_16/UNITY)                         */

  TONE_THR 	= 0.65 * MAX_16; ///* Threshold for tone detection   */

  //* Constants for background spectrum update */
  ALPHA_UP1   	= (1.0 - 0.95) * MAX_16;  ///* Normal update, upwards:   */
  ALPHA_DOWN1 	= (1.0 - 0.936) * MAX_16; ///* Normal update, downwards  */
  ALPHA_UP2   	= (1.0 - 0.985) * MAX_16; ///* Forced update, upwards    */
  ALPHA_DOWN2 	= (1.0 - 0.943) * MAX_16; ///* Forced update, downwards  */
  ALPHA3      	= (1.0 - 0.95) * MAX_16;  ///* Update downwards          */
  ALPHA4      	= (1.0 - 0.9) * MAX_16;   ///* For stationary estimation */
  ALPHA5      	= (1.0 - 0.5) * MAX_16;   ///* For stationary estimation */

  //* Constants for VAD threshold */
  VAD_THR_HIGH	= 1260; ///* Highest threshold                 */
  VAD_THR_LOW	= 720;  ///* Lowest threshold                  */
  VAD_P1 	= 0;          ///* Noise level for highest threshold */
  VAD_P2 	= 6300;       ///* Noise level for lowest threshold  */
  VAD_SLOPE	= MAX_16 * (VAD_THR_LOW - VAD_THR_HIGH) / (VAD_P2 - VAD_P1);

  //* Parameters for background spectrum recovery function */
  STAT_COUNT	= 20;         ///* threshold of stationary detection counter         */
  STAT_COUNT_BY_2	= 10;    ///* threshold of stationary detection counter         */
  CAD_MIN_STAT_COUNT	= 5;  ///* threshold of stationary detection counter         */

  STAT_THR_LEVEL	= 184;    ///* Threshold level for stationarity detection        */
  STAT_THR 		= 1000;         ///* Threshold for stationarity detection              */

  //* Limits for background noise estimate */
  NOISE_MIN 		= 40;          ///* minimum */
  NOISE_MAX 		= 16000;       ///* maximum */
  NOISE_INIT 		= 150;        ///* initial */

  //* Constants for VAD hangover addition */
  HANG_NOISE_THR 	= 100;
  BURST_LEN_HIGH_NOISE  = 4;
  HANG_LEN_HIGH_NOISE 	= 7;
  BURST_LEN_LOW_NOISE 	= 5;
  HANG_LEN_LOW_NOISE 	= 4;

  //* Thresholds for signal power */
  VAD_POW_LOW		= 15000;     ///* If input power is lower, VAD is set to 0                         */
  POW_PITCH_THR 	= 343040;  ///* If input power is lower, pitch detection is ignored                    */
  POW_COMPLEX_THR 	= 15000; ///* If input power is lower, complex flags  value for previous frame  is un-set  */

  //* Constants for the filter bank */
  LEVEL_SHIFT 		= 0;      ///* scaling                                  */
  COEFF3   		= 13363;     ///* coefficient for the 3rd order filter     */
  COEFF5_1 		= 21955;     ///* 1st coefficient the for 5th order filter */
  COEFF5_2 		= 6390;      ///* 2nd coefficient the for 5th order filter */

  //* Constants for pitch detection */
  LTHRESH 	= 4;
  NTHRESH	= 4;

  //* Constants for complex signal VAD  */
  CVAD_THRESH_ADAPT_HIGH  	= 0.6 * MAX_16; ///* threshold for adapt stopping high    */
  CVAD_THRESH_ADAPT_LOW  	= 0.5 * MAX_16;  ///* threshold for adapt stopping low     */
  CVAD_THRESH_IN_NOISE  	= 0.65 * MAX_16;  ///* threshold going into speech on a short term basis                   */

  CVAD_THRESH_HANG  		= 0.70 * MAX_16;      ///* threshold                            */
  CVAD_HANG_LIMIT  		= 100;                 ///* 2 second estimation time             */
  CVAD_HANG_LENGTH  		= 250;                ///* 5 second hangover                    */

  CVAD_LOWPOW_RESET 		= 0.40 * MAX_16;     ///* init in low power segment            */
  CVAD_MIN_CORR 		= 0.40 * MAX_16;         ///* lowest adaptation value              */

  CVAD_BURST 			= 20;                                  ///* speech burst length for speech reset */
  CVAD_ADAPT_SLOW 		= (1.0 - 0.98) * MAX_16;        ///* threshold for slow adaption */
  CVAD_ADAPT_FAST 		= (1.0 - 0.92) * MAX_16;         ///* threshold for fast adaption */
  CVAD_ADAPT_REALLY_FAST 	= (1.0 - 0.80) * MAX_16;  ///* threshold for really fast adaption                    */

//#endif

(*
********************************************************************************
*                         DEFINITION OF DATA TYPES
********************************************************************************
*)

type
//* state variable */
  pvadState = ^vadState;
  vadState = packed record
    //
    bckr_est: array [0..COMPLEN-1] of Word16;    ///* background noise estimate                */
    ave_level: array [0..COMPLEN-1] of Word16;   ///* averaged input components for stationary estimation                            */
    //
    old_level: array[0..COMPLEN-1] of Word16;   ///* input levels of the previous frame       */
    sub_level: array[0..COMPLEN-1] of Word16;   ///* input levels calculated at the end of a frame (lookahead)                   */
    a_data5: array[0..3-1, 0..2-1] of Word16;        ///* memory for the filter bank               */
    a_data3: array[0..5-1] of Word16;           ///* memory for the filter bank               */

    burst_count: Word16;          ///* counts length of a speech burst          */
    hang_count: Word16;           ///* hangover counter                         */
    stat_count: Word16;           ///* stationary counter                       */

    //* Note that each of the following three variables (vadreg, pitch and tone)
    //  holds 15 flags. Each flag reserves 1 bit of the variable. The newest
    //  flag is in the bit 15 (assuming that LSB is bit 1 and MSB is bit 16). */
    vadreg: Word16;               ///* flags for intermediate VAD decisions     */
    pitch: Word16;                ///* flags for pitch detection                */
    tone: Word16;                 ///* flags for tone detection                 */
    //
    complex_high: Word16;         ///* flags for complex detection              */
    complex_low: Word16;          ///* flags for complex detection              */

    oldlag_count, oldlag: Word16; ///* variables for pitch detection            */

    complex_hang_count: Word16;   ///* complex hangover counter, used by VAD    */
    complex_hang_timer: Word16;   ///* hangover initiator, used by CAD          */

    best_corr_hp: Word16;         ///* FIP filtered value Q15                   */

    speech_vad_decision: Word16;  ///* final decision                           */
    complex_warning: Word16;      ///* complex background warning               */

    sp_burst_count: Word16;       ///* counts length of a speech burst incl HO addition                              */
    corr_hp_fast: Word16;         ///* filtered value                           */
  end;

(*
********************************************************************************
*                         DECLARATION OF PROTOTYPES
********************************************************************************
*)
(****************************************************************************
 *
 *     Function     : vad
 *     Purpose      : Main program for Voice Activity Detection (VAD) for AMR
 *     Return value : VAD Decision, true = speech, false = noise
 *
 ***************************************************************************)
function vad1(var st: vadState; in_buf: pWord16array): bool;


(**************************************************************************
*  Function:   vad_init
*  Purpose:    Allocates state memory and initializes state memory
*
***************************************************************************)
function vad1_init(var state: pvadState): int;


(*************************************************************************
*
*  Function:   vad_exit
*  Purpose:    The memory used for state memory is freed
*
***************************************************************************)
procedure vad1_exit(var state: pvadState);


implementation


uses
  unaUtils;


(*___________________________________________________________________________
 |                                                                           |
 | Basic arithmetic operators.                                               |
 |                                                                           |
 | $Id $
 |___________________________________________________________________________|
*)

// --  --
function extract_h (L_var1: Word32): Word16; {$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
begin
  result := (L_var1 shr 16);
end;

// --  --
function extract_l (L_var1: Word32): Word16; {$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
begin
  result := Word16(L_var1);
end;

// --  --
function saturate(L_var1: Word32): Word16;{$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
begin
  if (L_var1 > $00007fff) then begin
    //
    //Overflow := 1;
    result := MAX_16;
  end
  else
    if (L_var1 < int32($ffff8000)) then begin
      //
      //Overflow := 1;
      result := MIN_16;
    end
    else
      result := extract_l(L_var1);
end;

// --  --
function add(var1: Word16; var2: Word16): Word16; {$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
begin
  result := saturate(var1 + var2);
end;

// --  --
function sub (var1: Word16; var2: Word16): Word16; {$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
begin
  result := saturate(var1 - var2);
end;

// --  --
function abs_s (var1: Word16): Word16;{$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
begin
  if ($8000 = uint32(var1)) then
    result := MAX_16
  else
    if (var1 < 0) then
      result := -var1
    else
      result := var1;
end;

function _shl (var1: Word16; var2: Word16): Word16; forward;

// --  --
function _shr (var1: Word16; var2: Word16): Word16; {$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
begin
  if (var2 < 0) then begin
    //
    if (var2 < -16) then
      var2 := -16;
    //
    result := _shl(var1, -var2);
  end
  else begin
    //
    if (var2 >= 15) then begin
      //
      if (var1 < 0) then
	result := -1
      else
	result := 0;
    end
    else begin
      //
      if (var1 < 0) then
	result := not ((not var1) shr var2)
      else
	result := var1 shr var2;
    end;
  end;
end;

// --  --
function _shl (var1: Word16; var2: Word16): Word16;
var
  res: Word32;
begin
  if (var2 < 0) then begin
    //
    if (var2 < -16) then
      var2 := -16;
    //
    result := _shr(var1, -var2);
  end
  else begin
    //
    res := var1 * (1 shl var2);
    if ( ((var2 > 15) and (var1 <> 0)) or (res <>  Word32(Word16(res))) ) then begin
      //
      //Overflow := 1;
      if (var1 > 0) then
	result := MAX_16
      else
	result := MIN_16;
    end
    else
      result := extract_l(res);
  end;
end;

// --  --
function mult (var1: Word16; var2: Word16): Word16; {$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
var
  L_product: Word32;
begin
  L_product := ((var1 * var2) and $ffff8000) shr 15;
  if (0 <> (L_product and $00010000)) then
    L_product := Word32(uint32(L_product) or $ffff0000);
  //
  result := saturate(L_product);
end;

// --  --
function L_mult (var1: Word16; var2: Word16): Word32; {$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
begin
  result := var1 * var2;
  if (result <> $40000000) then
    result := result * 2
  else begin
    //
    //Overflow := 1;
    result := MAX_32;
  end;
end;

// --  --
function L_add (L_var1: Word32; L_var2: Word32): Word32;{$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
var
  res: int64;
begin
  res := int64(L_var1) + L_var2;
  if (((L_var1 xor L_var2) and MIN_32) = 0) then begin
    //
    if (0 <> (res xor L_var1) and MIN_32) then begin
      //
      if (L_var1 < 0) then
	res := MIN_32
      else
	res := MAX_32;
      //
      //Overflow := 1;
    end;
  end;
  //
  result := res;
end;

// --  --
function L_sub (L_var1: Word32; L_var2: Word32): Word32;{$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
var
  res: int64;
begin
  res := int64(L_var1) - L_var2;
  if (((L_var1 xor L_var2) and MIN_32) <> 0) then begin
    //
    if (0 <> (res xor L_var1) and MIN_32) then begin
      //
      if (L_var1 < 0) then
	res := MIN_32
      else
	res := MAX_32;
      //
      //Overflow := 1;
    end;
  end;
  //
  result := res;
end;

// --  --
function round (L_var1: Word32): Word16; {$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
begin
  result := extract_h(L_add(L_var1, $00008000));
end;

// --  --
function L_mac(L_var3: Word32; var1: Word16; var2: Word16): Word32;{$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
begin
  result := L_add(L_var3, L_mult(var1, var2));
end;

// --  --
function L_msu (L_var3: Word32; var1: Word16; var2: Word16): Word32; {$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
begin
  result := L_sub (L_var3, L_mult (var1, var2));
end;

// --  --
function mult_r (var1: Word16; var2: Word16): Word16; {$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
var
  L_product_arr: Word32;
begin
  L_product_arr := Word32(var1) * var2 + $00004000;      //* round */
  L_product_arr := Word32(uint32(L_product_arr) and $ffff8000);
  L_product_arr := L_product_arr shr 15;       //* shift */
  //
  if (0 <> (L_product_arr and $00010000)) then //* sign extend when necessary */
    L_product_arr := Word32(uint32(L_product_arr) or $ffff0000);
  //
  result := saturate(L_product_arr);
end;

function L_shl (L_var1: Word32; var2: Word16): Word32; forward;     ///* Long shift left, 2 */

// --  --
function L_shr (L_var1: Word32; var2: Word16): Word32;{$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
begin
  if (var2 < 0) then begin
    //
    if (var2 < -32) then
	var2 := -32;
    //
    result := L_shl(L_var1, -var2);
  end
  else begin
    //
    if (var2 >= 31) then begin
      //
      if (L_var1 < 0) then
	result := -1
      else
	result := 0;
    end
    else begin
      //
      if (L_var1 < 0) then
	result := not ((not L_var1) shr var2)
      else
	result := L_var1 shr var2;
    end;
  end;
end;

// --  --
function L_shl (L_var1: Word32; var2: Word16): Word32;
begin
  {$IFDEF CPU64 }
  {$ELSE}
  result := 0;
  {$ENDIF CPU64 }
  //
  if (var2 <= 0) then begin
    //
    if (var2 < -32) then
      var2 := -32;
    //
    result := L_shr(L_var1, -var2);
  end
  else begin
    //
    repeat
      //
      if (L_var1 > $3fffffff) then begin
	//
	//Overflow := 1;
	result := MAX_32;
	//
	break;
      end
      else begin
	//
	if (L_var1 < Word32($c0000000)) then begin
	  //
	  //Overflow := 1;
	  result := MIN_32;
	  //
	  break;
	end;
      end;
      //
      L_var1 := L_var1 * 2;
      result := L_var1;
      //
      dec(var2);
      //
    until (var2 <= 0);
  end;
end;

// --  --
function L_deposit_h(var1: Word16): Word32;{$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
begin
  result := Word32(var1) shl 16;
end;

// --  --
function L_deposit_l(var1: Word16): Word32;{$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
begin
  result := var1;
end;

// --  --
function norm_s(var1: Word16): Word16;{$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
begin
  if (0 = var1) then
    result := 0
  else begin
    //
    if (var1 = Word16($ffff)) then
      result := 15
    else begin
      //
      if (var1 < 0) then
	var1 := not var1;
      //
      result := 0;
      while (var1 < $4000) do begin
	//
	var1 := var1 shl 1;
	inc(result);
      end;
    end;
  end;
end;

// --  --
function div_s(var1: Word16; var2: Word16): Word16; ///* Short division,       18  */
var
  iteration: Word16;
  L_num    : Word32;
  L_denom  : Word32;
begin
  result := 0;
  //
  if ((var1 > var2) or (var1 < 0) or (var2 < 0)) then exit;
    {
        printf ("Division Error var1=%d  var2=%d\n", var1, var2);
        abort(); /* exit (0); */
    }
  if (var2 = 0) then exit;
    {
        printf ("Division by 0, Fatal error \n");
        abort(); /* exit (0); */
    }
  if (var1 = 0) then
    result := 0
  else begin
    //
    if (var1 = var2) then
      result := MAX_16
    else begin
      //
      L_num := L_deposit_l(var1);
      L_denom := L_deposit_l(var2);
      //
      for iteration := 0 to 15 - 1 do begin
        //
        result := Word16(int32(result) shl 1);
        L_num := L_num shl 1;
        //
        if (L_num >= L_denom) then begin
          //
          L_num := L_sub(L_num, L_denom);
          result := add(result, 1);
        end;
      end;
    end;
  end;
end;


(*
*****************************************************************************
**-------------------------------------------------------------------------**
**                                                                         **
**     GSM AMR-NB speech codec   R98   Version 7.6.0   December 12, 2001       **
**                               R99   Version 3.3.0                       **
**                               REL-4 Version 4.1.0                       **
**                                                                         **
**-------------------------------------------------------------------------**
*****************************************************************************
*
*      File             : vad1.c
*      Purpose          : Voice Activity Detection (VAD) for AMR (option 1)
*
*****************************************************************************
*)

(*
*****************************************************************************
*                         MODULE INCLUDE FILE AND VERSION ID
*****************************************************************************
*)
//#include "vad.h"

//const char vad1_id[] = "@(#)$Id $" vad_h;

(*
*****************************************************************************
*                         INCLUDE FILES
*****************************************************************************
*)
//#include <stdlib.h>
//#include <stdio.h>
//#include "typedef.h"
//#include "basic_op.h"
//#include "count.h"
//#include "oper_32b.h"
//#include "cnst_vad.h"

(****************************************************************************
 *
 *     Function     : first_filter_stage
 *     Purpose      : Scale input down by one bit. Calculate 5th order
 *                    half-band lowpass/highpass filter pair with
 *                    decimation.
 *
 ***************************************************************************)
procedure first_filter_stage(_in: pWord16array;  //* i   : input signal                  */
			     _out: pWord16array; //* o   : output values, every other    */
					     //*       output is low-pass part and   */
					     //*       other is high-pass part every */
			      data: pWord16array //* i/o : filter memory                 */
			       );
var
  temp0, temp1, temp2, temp3, i: Word16;
  data0, data1: Word16;
begin
  data0 := data[0];  					  // move16 ();
  data1 := data[1];					  // move16 ();
  //
  for i := 0 to FRAME_LEN div 4 - 1 do begin
    //
    temp0 := sub(_shr(_in[4 * i + 0], 2), mult(COEFF5_1, data0));
    temp1 := add(data0, mult(COEFF5_1, temp0));
    //
    temp3 := sub(_shr(_in[4 * i + 1], 2), mult(COEFF5_2, data1));
    temp2 := add(data1, mult(COEFF5_2, temp3));
    //
    _out[4*i+0] := add(temp1, temp2);                        //move16 ();
    _out[4*i+1] := sub(temp1, temp2);                        //move16 ();
    //
    data0 := sub(_shr(_in[4 * i + 2], 2), mult(COEFF5_1, temp0));
    temp1 := add(temp0, mult(COEFF5_1, data0));
    //
    data1 := sub(_shr(_in[4 * i + 3], 2), mult(COEFF5_2, temp3));
    temp2 := add(temp3, mult(COEFF5_2, data1));
    //
    _out[4 * i + 2] := add(temp1, temp2);                       //move16 ();
    _out[4 * i + 3] := sub(temp1, temp2);                       //move16 ();
  end;
  //
  data[0] := data0;                                         //move16 ();
  data[1] := data1;                                         //move16 ();
end;

(****************************************************************************
 *
 *     Function     : filter5
 *     Purpose      : Fifth-order half-band lowpass/highpass filter pair with
 *                    decimation.
 *
 ***************************************************************************)
procedure filter5(var in0: Word16;    //* i/o : input values; output low-pass part  */
		  var in1: Word16;    //* i/o : input values; output high-pass part */
		  data: pWord16array   //* i/o : updated filter memory               */
                 );
var
  temp0, temp1, temp2: Word16;
begin
  temp0 := sub(in0, mult(COEFF5_1, data[0]));
  temp1 := add(data[0], mult(COEFF5_1, temp0));
  data[0] := temp0;                                //move16 ();
  //
  temp0 := sub(in1, mult(COEFF5_2, data[1]));
  temp2 := add(data[1], mult(COEFF5_2, temp0));
  data[1] := temp0;                                //move16 ();
  //
  in0 := _shr(add(temp1, temp2), 1);               //move16 ();
  in1 := _shr(sub(temp1, temp2), 1);               //move16 ();
end;

(****************************************************************************
 *
 *     Function     : filter3
 *     Purpose      : Third-order half-band lowpass/highpass filter pair with
 *                    decimation.
 *     Return value :
 *
 ***************************************************************************)
procedure filter3(var in0: Word16;   //* i/o : input values; output low-pass part  */
                  var in1: Word16;   //* i/o : input values; output high-pass part */
                  var data: Word16   //* i/o : updated filter memory               */
                 );
var
  temp1, temp2: Word16;
begin
  temp1 := sub(in1, mult(COEFF3, data));
  temp2 := add(data, mult(COEFF3, temp1));
  data := temp1;                              //move16 ();
  //
  in1 := _shr(sub(in0, temp2), 1);            //move16 ();
  in0 := _shr(add(in0, temp2), 1);            //move16 ();
end;

(****************************************************************************
 *
 *     Function     : level_calculation
 *     Purpose      : Calculate signal level in a sub-band. Level is calculated
 *                    by summing absolute values of the input data.
 *     Return value : signal level
 *
 ***************************************************************************)
function level_calculation(
    data: pWord16array;     //* i   : signal buffer                                    */
    var sub_level: Word16; 	//* i   : level calculate at the end of the previous frame */
                       		//* o   : level of signal calculated from the last         */
                       		//*       (count2 - count1) samples                        */
    count1: Word16;     //* i   : number of samples to be counted                  */
    count2: Word16;     //* i   : number of samples to be counted                  */
    ind_m: Word16;      //* i   : step size for the index of the data buffer       */
    ind_a: Word16;      //* i   : starting index of the data buffer                */
    scale: Word16       //* i   : scaling for the level calculation                */
    ): Word16;
var
  l_temp1, l_temp2: Word32;
  i: Word16;
begin
  l_temp1 := 0;                                           //move32 ();
  for i := count1 to count2 - 1 do
    l_temp1 := L_mac(l_temp1, 1, abs_s(data[ind_m * i + ind_a]));
  //
  l_temp2 := L_add(l_temp1, L_shl(sub_level, sub(16, scale)));
  sub_level := extract_h(L_shl(l_temp1, scale));
  //
  for i := 0 to count1 - 1 do
    l_temp2 := L_mac(l_temp2, 1, abs_s(data[ind_m * i + ind_a]));
  //
  result := extract_h(L_shl(l_temp2, scale));
end;

(****************************************************************************
 *
 *     Function     : filter_bank
 *     Purpose      : Divides input signal into 9-bands and calculas level of
 *                    the signal in each band
 *
 ***************************************************************************)
procedure filter_bank(var st: vadState;  //* i/o : State struct               */
                      _in: pWord16array;   //* i   : input frame                */
                      level: pWord16array //* 0   : signal levels at each band */
                     );
var
  i: Word16;
  tmp_buf: array[0..FRAME_LEN-1] of Word16;
begin
  //* calculate the filter bank */
  first_filter_stage(_in, pWord16array(@tmp_buf), pWord16array(@st.a_data5[0]));
  //
  for i := 0 to FRAME_LEN div 4 - 1 do begin
    //
    filter5(tmp_buf[4 * i],     tmp_buf[4 * i + 2], pWord16array(@st.a_data5[1]));
    filter5(tmp_buf[4 * i + 1], tmp_buf[4 * i + 3], pWord16array(@st.a_data5[2]));
  end;
  //
  for i := 0 to FRAME_LEN div 8 - 1 do begin
    //
    filter3(tmp_buf[8 * i + 0], tmp_buf[8 * i + 4], st.a_data3[0]);
    filter3(tmp_buf[8 * i + 2], tmp_buf[8 * i + 6], st.a_data3[1]);
    filter3(tmp_buf[8 * i + 3], tmp_buf[8 * i + 7], st.a_data3[4]);
  end;
  //
  for i := 0 to FRAME_LEN div 16 - 1 do begin
    //
    filter3(tmp_buf[16 * i + 0], tmp_buf[16 * i + 8],  st.a_data3[2]);
    filter3(tmp_buf[16 * i + 4], tmp_buf[16 * i + 12], st.a_data3[3]);
  end;
  //
  //* calculate levels in each frequency band */
  //
  //* 3000 - 4000 Hz*/
  level[8] := level_calculation(pWord16array(@tmp_buf), st.sub_level[8], FRAME_LEN div 4 - 8, FRAME_LEN div 4, 4, 1, 15);
  //move16 ();
  //* 2500 - 3000 Hz*/
  level[7] := level_calculation(pWord16array(@tmp_buf), st.sub_level[7], FRAME_LEN div 8 - 4, FRAME_LEN div 8, 8, 7, 16);
  //move16 ();
  //* 2000 - 2500 Hz*/
  level[6] := level_calculation(pWord16array(@tmp_buf), st.sub_level[6], FRAME_LEN div 8 - 4, FRAME_LEN div 8, 8, 3, 16);
  //move16 ();
  //* 1500 - 2000 Hz*/
  level[5] := level_calculation(pWord16array(@tmp_buf), st.sub_level[5], FRAME_LEN div 8 - 4, FRAME_LEN div 8, 8, 2, 16);
  //move16 ();
  //* 1000 - 1500 Hz*/
  level[4] := level_calculation(pWord16array(@tmp_buf), st.sub_level[4], FRAME_LEN div 8 - 4, FRAME_LEN div 8, 8, 6, 16);
  //move16 ();
  //* 750 - 1000 Hz*/
  level[3] := level_calculation(pWord16array(@tmp_buf), st.sub_level[3], FRAME_LEN div 16 - 2, FRAME_LEN div 16, 16, 4, 16);
  //move16 ();
  //* 500 - 750 Hz*/
  level[2] := level_calculation(pWord16array(@tmp_buf), st.sub_level[2], FRAME_LEN div 16 - 2, FRAME_LEN div 16, 16, 12, 16);
  //move16 ();
  //* 250 - 500 Hz*/
  level[1] := level_calculation(pWord16array(@tmp_buf), st.sub_level[1], FRAME_LEN div 16 - 2, FRAME_LEN div 16, 16, 8, 16);
  //move16 ();
  //* 0 - 250 Hz*/
  level[0] := level_calculation(pWord16array(@tmp_buf), st.sub_level[0], FRAME_LEN div 16 - 2, FRAME_LEN div 16, 16, 0, 16);
  //move16 ();
end;

(****************************************************************************
 *
 *     Function   : update_cntrl
 *     Purpose    : Control update of the background noise estimate.
 *     Inputs     : pitch:      flags for pitch detection
 *                  stat_count: stationary counter
 *                  tone:       flags indicating presence of a tone
 *                  complex:      flags for complex  detection
 *                  vadreg:     intermediate VAD flags
 *     Output     : stat_count: stationary counter
 *
 ***************************************************************************)
procedure update_cntrl(var st: vadState;  //* i/o : State struct                       */
                       level: pWord16array //* i   : sub-band levels of the input frame */
                      );
var
  i, temp, stat_rat, exp: Word16;
  num, denom: Word16;
  ialpha: Word16;
  alpha: float;
begin
  //* handle highband complex signal input  separately       */
  //* if ther has been highband correlation for some time    */
  //* make sure that the VAD update speed is low for a while */
  //test ();
  if (0 <> st.complex_warning) then begin
    //
    //test ();
    if (sub(st.stat_count, CAD_MIN_STAT_COUNT) < 0) then
      st.stat_count := CAD_MIN_STAT_COUNT;              //move16 ();
  end;
  //
  //* NB stat_count is allowed to be decreased by one below again  */
  //* deadlock in speech is not possible unless the signal is very */
  //* complex and need a high rate                                 */
  //
  //* if fullband pitch or tone have been detected for a while, initialize stat_count */
  //logic16 (); test (); logic16 (); test ();
  //
  if ((sub((st.pitch and $6000), $6000) = 0) or
      (sub((st.tone and $7c00), $7c00) = 0)) then
    //
    st.stat_count := STAT_COUNT                          //move16 ();
  else begin
    //
    //* if 8 last vad-decisions have been "0", reinitialize stat_count */
    // logic16 (); test ();
    //
    if ((st.vadreg and $7f80) = 0) then
      st.stat_count := STAT_COUNT                       //move16 ();
    else begin
      //
      stat_rat := 0;                                      //move16 ();
      for i := 0 to COMPLEN - 1 do begin
        //
        // test ();
        if (sub(level[i], st.ave_level[i]) > 0) then begin
          //
          num := level[i];                              //move16 ();
          denom := st.ave_level[i];                    //move16 ();
        end
        else begin
          num := st.ave_level[i];                      //move16 ();
          denom := level[i];                            //move16 ();
        end;
        //
        //* Limit nimimum value of num and denom to STAT_THR_LEVEL */
        //test ();
        if (sub(num, STAT_THR_LEVEL) < 0) then
	  num := STAT_THR_LEVEL;                        //move16 ();

        // test ();
        if (sub(denom, STAT_THR_LEVEL) < 0) then
          denom := STAT_THR_LEVEL;                      //move16 ();
        //
        exp := norm_s(denom);
        denom := _shl(denom, exp);
        //
        //* stat_rat = num/denom * 64 */
        temp := div_s(_shr(num, 1), denom);
        stat_rat := add(stat_rat, _shr(temp, sub(8, exp)));
      end;

      //* compare stat_rat with a threshold and update stat_count */
      //test ();
      if (sub(stat_rat, STAT_THR) > 0) then
        st.stat_count := STAT_COUNT                    //move16 ();
      else begin
        //
        // logic16 ();test ();
        if ((st.vadreg and $4000) <> 0) then begin
          //
          //test ();
          if (0 <> st.stat_count) then
	    st.stat_count := sub(st.stat_count, 1);  //move16 ();
        end;
      end;
    end;
  end;

  //* Update average amplitude estimate for stationarity estimation */
  alpha := ALPHA4;                                          //move16 ();
  //test ();
  if (sub(st.stat_count, STAT_COUNT) = 0) then
     alpha := 32767                                        //move16 ();
  else
    if ((st.vadreg and $4000) = 0) then
      // logic16 (); test ();
      alpha := ALPHA5;                                       //move16 ();
  //
  ialpha := trunc(alpha);
  for i := 0 to COMPLEN - 1 do
    st.ave_level[i] := add(st.ave_level[i], mult_r(ialpha, sub(level[i], st.ave_level[i])));
    // move16 ();
end;

(****************************************************************************
 *
 *     Function     : hangover_addition
 *     Purpose      : Add hangover for complex signal or after speech bursts
 *     Inputs       : burst_count:  counter for the length of speech bursts
 *                    hang_count:   hangover counter
 *                    vadreg:       intermediate VAD decision
 *     Outputs      : burst_count:  counter for the length of speech bursts
 *                    hang_count:   hangover counter
 *     Return value : VAD_flag indicating final VAD decision
 *
 ***************************************************************************)
function hangover_addition(
              var st: vadState;       //* i/o : State struct                     */
              noise_level: Word16;  //* i   : average level of the noise estimates                        */
              low_power: Word16    //* i   : flag power of the input frame    */
              ): Word16;
var
  hang_len, burst_len: Word16;
begin
  result := 0;
  //
  (*
    Calculate burst_len and hang_len
    burst_len: number of consecutive intermediate vad flags with "1"-decision
               required for hangover addition
    hang_len:  length of the hangover
  *)
  //test ();
  if (sub(noise_level, HANG_NOISE_THR) > 0) then begin
    //
    burst_len := BURST_LEN_HIGH_NOISE;                           //move16 ();
    hang_len := HANG_LEN_HIGH_NOISE;                             //move16 ();
  end
  else begin
    //
    burst_len := BURST_LEN_LOW_NOISE;                            //move16 ();
    hang_len := HANG_LEN_LOW_NOISE;                              //move16 ();
  end;
  //
  //* if the input power (pow_sum) is lower than a threshold, clear
  //  counters and set VAD_flag to "0"  "fast exit"                 */
  //test ();
  if (low_power <> 0) then begin
    //
    st.burst_count := 0;                                        //move16 ();
    st.hang_count := 0;                                         //move16 ();
    st.complex_hang_count := 0;                                 //move16 ();
    st.complex_hang_timer := 0;                                 //move16 ();
    //return 0;
    exit;
  end;
  //
  //test ();
  if (sub(st.complex_hang_timer, CVAD_HANG_LIMIT) > 0) then begin
    //
    //test ();
    if (sub(st.complex_hang_count, CVAD_HANG_LENGTH) < 0) then
      st.complex_hang_count := CVAD_HANG_LENGTH;               //move16 ();
  end;
  //
  //* long time very complex signal override VAD output function */
  //test ();
  if (st.complex_hang_count <> 0) then begin
    //
    st.burst_count := BURST_LEN_HIGH_NOISE;                     //move16 ();
    st.complex_hang_count := sub(st.complex_hang_count, 1);    //move16 ();
    result := 1;
    //
    exit;
  end
  else begin
    //
    //* let hp_corr work in from a noise_period indicated by the VAD */
    //test (); test (); logic16 ();
    if (((st.vadreg and $3ff0) = 0) and
        (sub(st.corr_hp_fast, trunc(CVAD_THRESH_IN_NOISE)) > 0)) then begin
      //
      result := 1;
      //
      exit;
    end;
  end;
  //
  //* update the counters (hang_count, burst_count) */
  //logic16 (); test ();
  if ((st.vadreg and $4000) <> 0) then begin
    //
    st.burst_count := add(st.burst_count, 1);                  //move16 ();
    //test ();
    if (sub(st.burst_count, burst_len) >= 0) then
       st.hang_count := hang_len;                               //move16 ();
    //
    result := 1;
  end
  else begin
    //
    st.burst_count := 0;                                        //move16 ();
    //test ();
    if (st.hang_count > 0) then begin
      //
      st.hang_count := sub(st.hang_count, 1);                 //move16 ();
      //
      result := 1;
    end;
  end;
end;

(****************************************************************************
 *
 *     Function   : noise_estimate_update
 *     Purpose    : Update of background noise estimate
 *     Inputs     : bckr_est:   background noise estimate
 *                  pitch:      flags for pitch detection
 *                  stat_count: stationary counter
 *     Outputs    : bckr_est:   background noise estimate
 *
 ***************************************************************************)
procedure noise_estimate_update(
                  var st: vadState;    //* i/o : State struct                       */
                  level: pWord16array   //* i   : sub-band levels of the input frame */
                  );
var
  i, alpha_up, alpha_down, bckr_add, temp: Word16;
begin
  //* Control update of bckr_est[] */
  update_cntrl(st, level);
  //
  //* Choose update speed */
  bckr_add := 2;                                           //move16 ();
  //
  //logic16 (); test (); logic16 (); test (); test ();
  if ( (($7800 and st.vadreg) = 0) and
       ((st.pitch and $7800) = 0) and
       (st.complex_hang_count = 0) ) then begin
    //
    alpha_up := trunc(ALPHA_UP1);                                //move16 ();
    alpha_down := trunc(ALPHA_DOWN1);                            //move16 ();
  end
  else begin
    //
    //test (); test ();
    if ((st.stat_count = 0) and (st.complex_hang_count = 0)) then begin
      //
      alpha_up := trunc(ALPHA_UP2);                             //move16 ();
      alpha_down := trunc(ALPHA_DOWN2);                         //move16 ();
    end
    else begin
      //
      alpha_up := 0;                                     //move16 ();
      alpha_down := trunc(ALPHA3);                              //move16 ();
      bckr_add := 0;                                     //move16 ();
    end;
  end;
  //
  //* Update noise estimate (bckr_est) */
  for i := 0 to COMPLEN - 1 do begin
    //
    temp := sub(st.old_level[i], st.bckr_est[i]);
    if (temp < 0) then begin
      //
      //* update downwards*/
      st.bckr_est[i] := add(-2, add(st.bckr_est[i], mult_r(alpha_down, temp)));
      //
      ///* limit minimum value of the noise estimate to NOISE_MIN */
      if (sub(st.bckr_est[i], NOISE_MIN) < 0) then
        st.bckr_est[i] := NOISE_MIN;                  //move16 ();
    end
    else begin
      //
      //* update upwards */
      st.bckr_est[i] := add(bckr_add, add(st.bckr_est[i], mult_r(alpha_up, temp)));
      //
      //* limit maximum value of the noise estimate to NOISE_MAX */
      if (sub(st.bckr_est[i], NOISE_MAX) > 0) then
        st.bckr_est[i] := NOISE_MAX;                  //move16 ();
    end;
  end;
  //
  //* Update signal levels of the previous frame (old_level) */
  for i := 0 to COMPLEN - 1 do
    st.old_level[i] := level[i];                        //move16 ();
end;

(****************************************************************************
 *
 *     Function   : complex_estimate_adapt
 *     Purpose    : Update/adapt of complex signal estimate
 *     Inputs     : low_power:   low signal power flag
 *     Outputs    : st->corr_hp_fast:   long term complex signal estimate
 *
 ***************************************************************************)
procedure complex_estimate_adapt(
         var st: vadState;       //* i/o : VAD state struct                       */
         low_power: Word16    //* i   : very low level flag of the input frame */
         );
var
   alpha: Word16;            //* Q15 */
   L_tmp: Word32;            //* Q31 */
begin
  //* adapt speed on own state */
  //test ();
  if (sub(st.best_corr_hp, st.corr_hp_fast) < 0) then begin//* decrease */
    //
    if (sub(st.corr_hp_fast, trunc(CVAD_THRESH_ADAPT_HIGH)) < 0) then
      //* low state  */
      alpha := trunc(CVAD_ADAPT_FAST)
    else
      //* high state */
      alpha := trunc(CVAD_ADAPT_REALLY_FAST);
  end
  else begin  //* increase */
    //
    if (sub(st.corr_hp_fast, trunc(CVAD_THRESH_ADAPT_HIGH)) < 0) then
      alpha := trunc(CVAD_ADAPT_FAST)
    else
      alpha := trunc(CVAD_ADAPT_SLOW);
  end;
  //
  L_tmp := L_deposit_h(st.corr_hp_fast);
  L_tmp := L_msu(L_tmp, alpha, st.corr_hp_fast);
  L_tmp := L_mac(L_tmp, alpha, st.best_corr_hp);
  st.corr_hp_fast := round(L_tmp);           //* Q15 */    move16();
  //
  if (sub(st.corr_hp_fast, trunc(CVAD_MIN_CORR)) <  0) then
    st.corr_hp_fast := trunc(CVAD_MIN_CORR);
  //
  if (low_power <> 0) then
    st.corr_hp_fast := trunc(CVAD_MIN_CORR);
end;

(****************************************************************************
 *
 *     Function     : complex_vad
 *     Purpose      : complex background decision
 *     Return value : the complex background decision
 *
 ***************************************************************************)
function complex_vad(var st: vadState;    //* i/o : VAD state struct              */
			 low_power: Word16 //* i   : flag power of the input frame */
                    ): Word16;
begin
  st.complex_high := _shr(st.complex_high, 1);
  st.complex_low := _shr(st.complex_low, 1);
  //
  if (low_power = 0) then begin
    //
    if (sub(st.corr_hp_fast, trunc(CVAD_THRESH_ADAPT_HIGH)) > 0) then
      st.complex_high := st.complex_high or $4000;
    //
    if (sub(st.corr_hp_fast, trunc(CVAD_THRESH_ADAPT_LOW)) > 0) then
      st.complex_low := st.complex_low or $4000;
  end;
  //
  if (sub(st.corr_hp_fast, trunc(CVAD_THRESH_HANG)) > 0) then
    st.complex_hang_timer := add(st.complex_hang_timer, 1)
  else
    st.complex_hang_timer :=  0;
  //
  if ( (sub((st.complex_high and $7f80), $7f80) = 0) or
       (sub((st.complex_low  and $7fff), $7fff) = 0) ) then
    result := 1
  else
    result := 0;
end;

(****************************************************************************
 *
 *     Function     : vad_decision
 *     Purpose      : Calculates VAD_flag
 *     Inputs       : bckr_est:    background noise estimate
 *                    vadreg:      intermediate VAD flags
 *     Outputs      : noise_level: average level of the noise estimates
 *                    vadreg:      intermediate VAD flags
 *     Return value : VAD_flag
 *
 ***************************************************************************)
function vad_decision(
             var st: vadState;     //* i/o : State struct                       */
             level: pWord16array;  //* i   : sub-band levels of the input frame */
             pow_sum:Word32        //* i   : power of the input frame           */
             ): Word16;
var
   i: Word16;
   snr_sum: Word16;
   L_temp: Word32;
   vad_thr, temp, noise_level: Word16;
   low_power_flag: Word16;
   exp: Word16;
begin
  //*
  //   Calculate squared sum of the input levels (level)
  //   divided by the background noise components (bckr_est).
  //   */
  L_temp := 0;
  for i := 0 to COMPLEN - 1 do begin
    //
    exp := norm_s(st.bckr_est[i]);
    temp := _shl(st.bckr_est[i], exp);
    temp := div_s(_shr(level[i], 1), temp);
    temp := _shl(temp, sub(exp, UNIRSHFT - 1));
    L_temp := L_mac(L_temp, temp, temp);
  end;
  //
  snr_sum := extract_h(L_shl(L_temp, 6));
  snr_sum := mult(snr_sum, INV_COMPLEN);
  //
  //* Calculate average level of estimated background noise */
  L_temp := 0;
  for i := 0 to COMPLEN - 1 do
    L_temp := L_add(L_temp, st.bckr_est[i]);
  //
  noise_level := extract_h(L_shl(L_temp, 13));
  //
  //* Calculate VAD threshold */
  vad_thr := add(mult(trunc(VAD_SLOPE), sub(noise_level, VAD_P1)), VAD_THR_HIGH);
  //
  if (sub(vad_thr, VAD_THR_LOW) < 0) then
    vad_thr := VAD_THR_LOW;
  //
  //* Shift VAD decision register */
  st.vadreg := _shr(st.vadreg, 1);
  //
  //* Make intermediate VAD decision */
  if (sub(snr_sum, vad_thr) > 0) then
    st.vadreg := st.vadreg or $4000;
  //
  //* primary vad decsion made */
  //
  //* check if the input power (pow_sum) is lower than a threshold" */
  if (L_sub(pow_sum, VAD_POW_LOW) < 0) then
    low_power_flag := 1
  else
    low_power_flag := 0;
  //
  //* update complex signal estimate st->corr_hp_fast and hangover reset timer using */
  //* low_power_flag and corr_hp_fast  and various adaptation speeds                 */
  complex_estimate_adapt(st, low_power_flag);
  //
  //* check multiple thresholds of the st->corr_hp_fast value */
  st.complex_warning := complex_vad(st, low_power_flag);
  //
  //* Update speech subband vad background noise estimates */
  noise_estimate_update(st, level);
  //
  //*  Add speech and complex hangover and return speech VAD_flag */
  //*  long term complex hangover may be added */
  st.speech_vad_decision := hangover_addition(st, noise_level, low_power_flag);
  //
  result := st.speech_vad_decision;
end;

(*
*****************************************************************************
*                         PUBLIC PROGRAM CODE
*****************************************************************************
*)

(*************************************************************************
*
*  Function:   vad1_reset
*  Purpose:    Initializes state memory to zero
*
**************************************************************************
*)
function vad1_reset(state: pvadState): int;
var
  i: Word16;
begin
  if (nil <> state) then begin
    //
    //* Initialize pitch detection variables */
    fillchar(state^, sizeof(state^), #0);
    //
    //* initialize the rest of the memory */
    for i := 0 to COMPLEN - 1 do begin
      //
      state.bckr_est[i] := NOISE_INIT;
      state.old_level[i] := NOISE_INIT;
      state.ave_level[i] := NOISE_INIT;
      state.sub_level[i] := 0;
    end;
    //
    state.best_corr_hp := trunc(CVAD_LOWPOW_RESET);
    state.corr_hp_fast := trunc(CVAD_LOWPOW_RESET);
    //
    result := 0;
  end
  else
    result := -1;
end;

(*************************************************************************
*
*  Function:   vad_init
*  Purpose:    Allocates state memory and initializes state memory
*
**************************************************************************
*)
function vad1_init(var state: pvadState): int;
var
  s: pvadState;
begin
  result := -1;
  //
  if (nil = state) then begin
    //
    //* allocate memory */
    s := malloc(sizeof(s^));
    if (nil <> s) then begin
      //
      vad1_reset(s);
      state := s;
      //
      result := 0;
    end;
  end;
end;

(*************************************************************************
*
*  Function:   vad_exit
*  Purpose:    The memory used for state memory is freed
*
**************************************************************************
*)
procedure vad1_exit(var state: pvadState);
begin
  mrealloc(state);
end;

(****************************************************************************
 *
 *     Function     : vad_complex_detection_update
 *     Purpose      : update vad->bestCorr_hp  complex signal feature state
 *
 ***************************************************************************)
procedure vad_complex_detection_update (var st: vadState;       //* i/o : State struct */
				   best_corr_hp: Word16 //* i   : best Corr    */
                                   );
begin
  st.best_corr_hp := best_corr_hp;
end;

(****************************************************************************
 *
 *     Function     : vad_tone_detection
 *     Purpose      : Set tone flag if pitch gain is high. This is used to detect
 *                    signaling tones and other signals with high pitch gain.
 *     Inputs       : tone: flags indicating presence of a tone
 *     Outputs      : tone: flags indicating presence of a tone
 *
 ***************************************************************************)
procedure vad_tone_detection (var st: vadState;  //* i/o : State struct            */
                         t0: Word32;     //* i   : autocorrelation maxima  */
                         t1: Word32      //* i   : energy                  */
                         );
var
  temp: Word16;
begin
  (*
      if (t0 > TONE_THR * t1)
      set tone flag
      *)
  temp := round(t1);
  //
  if ((temp > 0) and (L_msu(t0, temp, trunc(TONE_THR)) > 0)) then
    st.tone := st.tone or $4000;
end;

(****************************************************************************
 *
 *     Function     : vad_tone_detection_update
 *     Purpose      : Update the tone flag register. Tone flags are shifted right
 *                    by one bit. This function should be called from the speech
 *                    encoder before call to Vad_tone_detection() function.
 *
 ***************************************************************************)
procedure vad_tone_detection_update (
                var st: vadState;              //* i/o : State struct              */
                one_lag_per_frame: Word16   //* i   : 1 if one open-loop lag is calculated per each frame, otherwise 0                     */
		);
begin
  //* Shift tone flags right by one bit */
  st.tone := _shr(st.tone, 1);
  //
  //* If open-loop lag is calculated only once in each frame, do extra update
  //   and assume that the other tone flag of the frame is one. */
  if (one_lag_per_frame <> 0) then begin
    //
    st.tone := _shr(st.tone, 1);
    st.tone := st.tone or $2000;
  end;
end;

(****************************************************************************
 *
 *     Function     : vad_pitch_detection
 *     Purpose      : Test whether signal contains pitch or other periodic
 *                    component.
 *     Return value : Boolean voiced / unvoiced decision in state variable
 *
 ***************************************************************************)
procedure vad_pitch_detection (var st: vadState;   //* i/o : State struct                  */
			  T_op: pWord16array  //* i   : speech encoder open loop lags */
			  );
var
  lagcount, i: Word16;
begin
  lagcount := 0;
  //
  for i := 0 to 2 - 1 do begin
    //
    if (sub(abs_s(sub(st.oldlag, T_op[i])), LTHRESH) < 0) then
      lagcount := add(lagcount, 1);
    //
    //* Save the current LTP lag */
    st.oldlag := T_op[i];
  end;
  //
  //* Make pitch decision.
  //  Save flag of the pitch detection to the variable pitch.
  //  */
  st.pitch := _shr(st.pitch, 1);
  //
  if (sub(add(st.oldlag_count, lagcount), NTHRESH) >= 0) then
    st.pitch := st.pitch or $4000;
  //
  //* Update oldlagcount */
  st.oldlag_count := lagcount;
end;

(****************************************************************************
 *
 *     Function     : vad
 *     Purpose      : Main program for Voice Activity Detection (VAD) for AMR
 *     Return value : VAD Decision, 1 = speech, 0 = noise
 *
 ***************************************************************************)
function vad1(var st: vadState;      //* i/o : State struct                 */
	   in_buf: pWord16array    //* i   : samples of the input frame   */
	   ): bool;
var
  level: array[0..COMPLEN-1] of Word16;
  pow_sum: Word32;
  i: Word16;
begin
  //* Calculate power of the input frame. */
  pow_sum := 0;
  //
  for i := 0 to FRAME_LEN - 1 do
    pow_sum := L_mac(pow_sum, in_buf[i{ - LOOKAHEAD}], in_buf[i{ - LOOKAHEAD}]);
  //
  //* If input power is very low, clear pitch flag of the current frame */
  if (L_sub(pow_sum, POW_PITCH_THR) < 0) then
    st.pitch := st.pitch and $3fff;
  //
  //* If input power is very low, clear complex flag of the "current" frame */
  if (L_sub(pow_sum, POW_COMPLEX_THR) < 0) then
    st.complex_low := st.complex_low and $3fff;
  //
  //* Run the filter bank which calculates signal levels at each band */
  filter_bank(st, in_buf, pWord16array(@level));
  //
  result := (0 <> vad_decision(st, pWord16array(@level), pow_sum));
end;


end.

