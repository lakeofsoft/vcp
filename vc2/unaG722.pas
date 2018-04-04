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

	  unaG722.pas - G.722 codec implementation
	  VC components version 2.5

	----------------------------------------------
	  Delphi conversion of original C code:

	  Copyright (c) 2017 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, Jan 2017

	  modified by:
		Lake, Jan 2017

	----------------------------------------------
*)

{$I unaDef.inc }

{$IFDEF DEBUG }
    {$DEFINE LOG_G722_INFOS }	    // log informational messages
    {$DEFINE LOG_G722_ERRORS }	    // log critical errors
{$ENDIF DEBUG }

unit
    unaG722;

interface

uses
    unaTypes;

type
    p_enc   = pointer;
    p_dec   = pointer;

    p_pcm       = pInt16;
    p_data      = pByte;
    pp_wbenh    = ^pUint16;

    ppshort  = ^pshort;
    pshort  = ^short;
    pshortA  = ^shortA;
    short   = int16;
    shortA  = array [0..65535] of short;

    ppfloat  = ^pfloat;
    pfloatA  = ^floatA;
    floatA  = array [0..65535] of float;

//* ITU G.722 3rd Edition (2012-09) */

(*--------------------------------------------------------------------------
 ITU-T G.722 Annex C (ex G.722-SWB-Float) Source Code
 Software Release 1.01 (2012-07)
 (C) 2012 France Telecom, Huawei Technologies, VoiceAge Corp., NTT.
--------------------------------------------------------------------------*)

function  fl_g722_encode_const() : p_enc;
procedure fl_g722_encode_reset(e : p_enc);
procedure fl_g722_encode_dest(e : p_enc);
procedure g722_encode(mode : short; local_mode : short; const sig : p_pcm; code : p_data;
                 code_enh : pByte; mode_enh : short; //* mode_enh = 1 -> high-band enhancement layer */
                 e : p_enc; wbenh_flag : short; pBit_wbenh : pp_wbenh);

function  g722_decode_const() : p_dec;
procedure g722_decode_dest(d : p_dec);
procedure g722_decode_reset(d : p_dec);

procedure g722_decode(mode : short; const code : p_data;
                 const code_enh : p_data; mode_enh : short;
                 loss_flag : int; outcode : p_pcm;
                 d : p_dec; pBit_wbenh : pp_wbenh; wbenh_flag : short);

//* G722_H */

implementation

uses
    Math,
    unaUtils;


// Delphi utils
// --  --
procedure movef(count : int; var from; var _to);
begin
    move(from, _to, count * sizeof(float));
end;
// --  --
procedure moves(count : int; var from; var _to);
begin
    move(from, _to, count * sizeof(short));
end;
// --  --
procedure movesf(count : int; var from; var _to);
var
    i : int;
begin
    for i := 0 to count - 1 do
        pfloatA(@_to)[i] := pshortA(@from)[i];
end;
// --  --
function mallocf(count : int): pfloat;
begin
    exit(malloc(count * sizeof(float)));
end;
// --  --
procedure zeros(count : int; var data);
begin
    fillChar(data, count * sizeof(short), #0);
end;
// --  --
procedure zerof(count : int; var data);
begin
    fillChar(data, count * sizeof(float), #0);
end;

// some forwards

function  fl_noise_shaper(A : pfloatA; _in : float; mem : pfloat) : float; forward;


//g722_tables.c
//* ITU G.722 3rd Edition (2012-09) */

(*--------------------------------------------------------------------------
 ITU-T G.722 Annex C (ex G.722-SWB-Float) Source Code
 Software Release 1.01 (2012-07)
 (C) 2012 France Telecom, Huawei Technologies, VoiceAge Corp., NTT.
--------------------------------------------------------------------------*)

(*
*------------------------------------------------------------------------
*  File: table_lowband.c
*  Function: Tables for lower-band modules
*------------------------------------------------------------------------
*)

const
//* table to read IL frorm SIL and MIL: misil(sil(0,1),mil(1,31)) */
    misil5b : array[0..29] of short =
(
    $003E, $001E, $001C, $001A, $0018, $0016, $0014, $0012,
    $0010, $000E, $000C, $000A, $0008, $0006, $0004,
    $003C, $003A, $0038, $0036, $0034, $0032, $0030, $002E,
    $002C, $002A, $0028, $0026, $0024, $0022, $0020
);

//* 5 levels quantizer level od decision */
    q5b : array[0..14] of short =
(
    576, 1200, 1864, 2584, 3376, 4240, 5200, 6288,
    7520, 8968, 10712, 12896, 15840, 20456, 25600
);


    misih : array[0..1] of array[0..2] of short =
(
    (0, 1, 0),
    (0, 3, 2)
);
    q2 = 4512;

    qtab6 : array[0..63] of short =
(
    -136, -136, -136, -136, -24808, -21904, -19008, -16704,
    -14984, -13512, -12280, -11192, -10232, -9360, -8576, -7856,
    -7192, -6576, -6000, -5456, -4944, -4464, -4008, -3576,
    -3168, -2776, -2400, -2032, -1688, -1360, -1040, -728,
    24808, 21904, 19008, 16704, 14984, 13512, 12280, 11192,
    10232, 9360, 8576, 7856, 7192, 6576, 6000, 5456,
    4944, 4464, 4008, 3576, 3168, 2776, 2400, 2032,
    1688, 1360, 1040, 728, 432, 136, -432, -136
);

    qtab5 : array[0..31] of short =
(
    -280, -280, -23352, -17560, -14120, -11664, -9752, -8184,
    -6864, -5712, -4696, -3784, -2960, -2208, -1520, -880,
    23352, 17560, 14120, 11664, 9752, 8184, 6864, 5712,
    4696, 3784, 2960, 2208, 1520, 880, 280, -280
);

    qtab4 : array[0..15] of short =
(
    0, -20456, -12896, -8968, -6288, -4240, -2584, -1200,
    20456, 12896, 8968, 6288, 4240, 2584, 1200, 0
);

    qtab2 : array[0..3] of short =
(
    -7408, -1616, 7408, 1616
);

    whi : array[0..3] of short =
(
    798, -214, 798, -214
);

    wli : array[0..15] of short =
(
    -60, 3042, 1198, 538 ,334 ,172 ,58 ,-30, 3042, 1198, 538 ,334 ,172 ,58 ,-30, -60
);

    ila2 : array[0..352] of short =
(
    8, 8, 8, 8, 8, 8, 8, 8,
    8, 8, 8, 8, 8, 8, 8, 8,
    8, 8, 8, 12, 12, 12, 12, 12,
    12, 12, 12, 12, 12, 12, 12, 12,
    16, 16, 16, 16, 16, 16, 16, 16,
    16, 16, 16, 20, 20, 20, 20, 20,
    20, 20, 20, 24, 24, 24, 24, 24,
    24, 24, 28, 28, 28, 28, 28, 28,
    32, 32, 32, 32, 32, 32, 36, 36,
    36, 36, 36, 40, 40, 40, 40, 44,
    44, 44, 44, 48, 48, 48, 48, 52,
    52, 52, 56, 56, 56, 56, 60, 60,
    64, 64, 64, 68, 68, 68, 72, 72,
    76, 76, 76, 80, 80, 84, 84, 88,
    88, 92, 92, 96, 96, 100, 100, 104,
    104, 108, 112, 112, 116, 116, 120, 124,
    128, 128, 132, 136, 136, 140, 144, 148,
    152, 152, 156, 160, 164, 168, 172, 176,
    180, 184, 188, 192, 196, 200, 204, 208,
    212, 220, 224, 228, 232, 236, 244, 248,
    256, 260, 264, 272, 276, 284, 288, 296,
    304, 308, 316, 324, 332, 336, 344, 352,
    360, 368, 376, 384, 392, 400, 412, 420,
    428, 440, 448, 456, 468, 476, 488, 500,
    512, 520, 532, 544, 556, 568, 580, 592,
    608, 620, 632, 648, 664, 676, 692, 708,
    724, 740, 756, 772, 788, 804, 824, 840,
    860, 880, 896, 916, 936, 956, 980, 1000,
    1024, 1044, 1068, 1092, 1116, 1140, 1164, 1188,
    1216, 1244, 1268, 1296, 1328, 1356, 1384, 1416,
    1448, 1480, 1512, 1544, 1576, 1612, 1648, 1684,
    1720, 1760, 1796, 1836, 1876, 1916, 1960, 2004,
    2048, 2092, 2136, 2184, 2232, 2280, 2332, 2380,
    2432, 2488, 2540, 2596, 2656, 2712, 2772, 2832,
    2896, 2960, 3024, 3088, 3156, 3228, 3296, 3368,
    3444, 3520, 3596, 3676, 3756, 3836, 3920, 4008,
    4096, 4184, 4276, 4372, 4464, 4564, 4664, 4764,
    4868, 4976, 5084, 5196, 5312, 5428, 5548, 5668,
    5792, 5920, 6048, 6180, 6316, 6456, 6596, 6740,
    6888, 7040, 7192, 7352, 7512, 7676, 7844, 8016,
    8192, 8372, 8556, 8744, 8932, 9128, 9328, 9532,
    9740, 9956, 10172, 10396, 10624, 10856, 11096, 11336,
    11584, 11840, 12100, 12364, 12632, 12912, 13192, 13484,
    13776, 14080, 14388, 14704, 15024, 15352, 15688, 16032,
    16384
);

    coef_qmf : array[0..23] of short =
(
  3 * 2, -11 * 2, -11 * 2, 53 * 2, 12 * 2, -156 * 2,
  32 * 2, 362 * 2, -210 * 2, -805 * 2, 951 * 2, 3876 * 2,
  3876 * 2, 951 * 2, -805 * 2, -210 * 2, 362 * 2, 32 * 2,
  -156 * 2, 12 * 2, 53 * 2, -11 * 2, -11 * 2, 3 * 2
);

    fl_coef_qmf : array[0..23] of float =
(
    1.8310546875e-4, -6.7138671875e-4, -6.7138671875e-4, 3.2348632813e-3,
	7.3242187500e-4, -9.5214843750e-3, 1.9531250000e-3, 2.2094726563e-2,
	-1.2817382813e-2, -4.9133300781e-2, 5.8044433594e-2, 2.3657226563e-1,
	2.3657226563e-1, 5.8044433594e-2, -4.9133300781e-2, -1.2817382813e-2,
	2.2094726563e-2, 1.9531250000e-3, -9.5214843750e-3, 7.3242187500e-4,
	3.2348632813e-3, -6.7138671875e-4, -6.7138671875e-4, 1.8310546875e-4
);

//* Inverse quantize 2 and 4 bit tables for the decoder */
    oq4new      : array[0..15] of short = (-14552,-8768,-6832,-5256,-3776,-2512,-1416,-440,5256,6832,8768,14552,440,1416,2512,3776);
    oq3new      : array[0..7]  of short = (-9624,-5976,-3056,-872,5976,9624,872,3056);
    tresh_enh   : array[0..3] of short = (-392, -348, 392, 348);
    oq4_3new    : array[0..23] of short = (-14552,-8768,-6832,-5256,-3776,-2512,-1416,-440,5256,6832,8768,14552,440,1416,2512,3776,-9624,-5976,-3056,-872,5976,9624,872,3056);

    code_mask   : array [0..3] of short = ($00FF, $00FF, $00FE, $00FC);

    invqbl_tab      : array[0..3] of pointer = (0, @qtab6, @qtab5, @qtab4);
    invqbl_shift    : array[0..3] of short = (0, 0, 1, 2);
    invqbh_tab      : array[0..3] of pointer = (0, @oq4new, @oq3new, @qtab2);

//g722_tables.c


//* ITU G.722 3rd Edition (2012-09) */

(*--------------------------------------------------------------------------
 ITU-T G.722 Annex C (ex G.722-SWB-Float) Source Code
 Software Release 1.01 (2012-07)
 (C) 2012 France Telecom, Huawei Technologies, VoiceAge Corp., NTT.
--------------------------------------------------------------------------*)

//#include "floatutil.h"
//#include "g722.h"

//#include "funcg722.h"
//* ITU G.722 3rd Edition (2012-09) */

(*--------------------------------------------------------------------------
 ITU-T G.722 Annex C (ex G.722-SWB-Float) Source Code
 Software Release 1.01 (2012-07)
 (C) 2012 France Telecom, Huawei Technologies, VoiceAge Corp., NTT.
--------------------------------------------------------------------------*)
//#ifndef FUNCG722_H
//#define FUNCG722_H 200

//#include "floatutil.h"

//* FUNCG722_H */

type
//#if FUNCG722 == SW_FLT
//* Define type for G.722 state structure */
    pg722_state = ^g722_state;
    g722_state = packed record
        al      : array[0..2] of short;
        bl      : array[0..6] of short;
        detl    : short;
        dlt     : array[0..6] of short; //* dlt[0]=dlt */
        nbl     : short;
        plt     : array[0..2] of short;   //* plt[0]=plt */
        rlt     : array[0..2] of short;
        ah      : array[0..2] of short;
        bh      : array[0..6] of short;
        deth    : short;
        dh      : array[0..6] of short;
        ph      : array[0..2] of short; //* ph[0]=ph */
        rh      : array[0..2] of short;
        sl      : short;
        spl     : short;
        szl     : short;
        nbh     : short;
        sh      : short;
        sph     : short;
        szh     : short;
        qmf_tx_delayx   : array [0..23] of short;
        qmf_rx_delayx   : array [0..23] of short;
    end;

//function  hsbcod (xh : short; s : pg722_state) : short; forward;
//function  lsbdec (ilr : short; mode : short; s : pg722_state) : short; forward;
//function  hsbdec (ih : short; s : pg722_state) : short; forward;
function  quantl5b (el : short; detl : short) : short; forward;

//procedure hsbdec_reset (s : pg722_state); forward;
//function  quantl (el : short; detl : short) : short; forward;
function  quanth (eh : short; deth : short) : short; forward;
function  filtep (rlt : pshortA; al : pshortA) : short; forward;
function  filtez (dlt : pshortA; bl : pshortA) : short; forward;

//function  limit (rl : short) : short; forward;
function  logsch (ih : short; nbh : short) : short; forward;
function  logscl (il : short; nbl : short) : short; forward;
function  scalel (nbpl : short) : short; forward;
function  scaleh (nbph : short) : short; forward;
procedure uppol1 (al : pshortA; plt : pshortA); forward;
procedure uppol2 (al : pshortA; plt : pshortA); forward;
procedure upzero (dlt : pshortA; bl : pshortA); forward;
//procedure qmf_tx (xin0 : short; xin1 : short; xl : pshort; xh : pshort; s : pg722_state); forward;
//procedure qmf_tx_buf (xin : ppshort; xl : pshort; xh : pshort; delayx : ppshort); forward;
//procedure qmf_rx_buf (rl : short; rh : short; delayx : ppshort; _out : ppshort); forward;
//procedure fl_qmf_tx_buf (xin : ppshort; xl : pshort; xh : pshort; delayx : ppshort); forward;
procedure fl_qmf_rx_buf (rl : short; rh : short; delayx : ppshort; _out : ppshort); forward;


(*----------------------------------------------------------------
Function:
Bounds a 32-bit value between x_min and x_max (Short).
Return value
the short bounded value
----------------------------------------------------------------*)
function saturate2(
                x : long;     //* (i): input value   */
                x_min : short;    //* (i): lower limit   */
                x_max : short     //* (i): higher limit   */
                ) : short;
var
	xs : short;
begin
	if (x < x_min) then
		xs := x_min
	else
	begin
		if(x > x_max) then
			xs := x_max
		else
			xs := x;
	end;
	exit(xs);
end;

procedure adpcm_adapt_c(ind : short; a, b, d, p, r,
                        nb, det, sz, s : pshort);
var
    sp : short;
    tmp32 : long;
begin
    tmp32 := d^ + sz^;
    p^ := saturate2(tmp32, -32768, 32767);  	//* parrec */
    tmp32 := s^ + d^;
    r^ := saturate2(tmp32, -32768, 32767);   //* recons */

    upzero (pshortA(d), pshortA(b));
    uppol2 (pshortA(a), pshortA(p));
    uppol1 (pshortA(a), pshortA(p));
    sz^ := filtez (pshortA(d), pshortA(b));
    sp  := filtep (pshortA(r), pshortA(a));

    tmp32 := sp + sz^;
    s^ := saturate2(tmp32, -32768, 32767);     //* predic */
end;

procedure adpcm_adapt_h(ind : short; a, b, d, p, r, nb, det, sz, s : pshort);
begin
    d^ := ((det^ * qtab2[ind]) shr 15);
    nb^ := logsch(ind, nb^);
    det^ := scaleh(nb^);
    adpcm_adapt_c(ind, a, b, d, p, r, nb, det, sz, s);
end;


procedure adpcm_adapt_l(ind : short; a, b, d, p, r, nb, det, sz, s : pshort);
begin
    d^ := ((det^ * qtab4[ind shr 2]) shr 15);
    nb^ := logscl(ind, nb^);
    det^ := scalel(nb^);
    adpcm_adapt_c(ind, a, b, d, p, r, nb, det, sz, s);
end;


(*___________________________________________________________________________
Function Name : upzero
*)
procedure upzero (dlt, bl : pshortA);
var
    sg0, sgi, wd1, wd2, wd3 : short;
    i : short;
begin
    //* shift of the dlt line signal and update of bl */
    wd1 := 128;
    if (dlt[0] = 0) then
        wd1 := 0;

    sg0 := dlt[0] shr 15;

    for i := 6 downto 0 + 1 do
    begin
        sgi := dlt[i] shr 15;
        wd3 := ((bl[i] * 32640) shr 15);
        wd2 := wd3 - wd1;
        if ((sg0 - sgi) = 0) then
            wd2 := wd3+ wd1;

        bl[i] := wd2;
        dlt[i] := dlt[i - 1];
    end;
end;

(*___________________________________________________________________________
Function Name : logscl
*)
function logscl (il, nbl : short) : short;
var
    ril, nbpl : short;
begin
    ril := il shr 2;
    nbpl := ((nbl * 32512) shr 15) + wli[ril];
    if (nbpl >= 0) then
        nbpl := nbpl
    else
        nbpl := 0;

    if (nbpl <= 18432) then
        nbpl := nbpl
    else
        nbpl := 18432;

    exit(nbpl);
end;
//* ..................... End of logscl() ..................... */


(*___________________________________________________________________________
Function Name : logsch
*)
function  logsch (ih : short; nbh : short) : short;
var
	nbph : short;
begin
	nbph := ((nbh * 32512) shr 15) + whi[ih];

	if (nbph >= 0) then
		nbph := nbph
	else
		nbph := 0;

	if (nbph <= 22528) then
		nbph := nbph
	else
		nbph := 22528;

    exit(nbph);
end;
//* ..................... End of logsch() ..................... */

(*___________________________________________________________________________
Function Name : scalel
*)
function scalel (nbpl : short) : short;
var
    wd1, wd2 : short;
begin
    wd1 := (nbpl shr 6) and 511;
    wd2 := wd1 + 64;
    exit(ila2[wd2]);
end;
//* ..................... End of scalel() ..................... */

(*___________________________________________________________________________
Function Name : scaleh
*)
function scaleh (nbph : short) : short;
var
    wd : short;
begin
    wd := (nbph shr 6) and 511;
    exit(ila2[wd]);
end;
//* ..................... End of scaleh() ..................... */

(*___________________________________________________________________________
Function Name : uppol1
*)
procedure uppol1 (al, plt : pshortA);
var
    sg0, sg1, wd1, wd3, apl1 : short;
    tmp32 : long;
begin
    sg0 := plt[0] shr 15;
    sg1 := plt[1] shr 15;
    wd1 := -192;
    if ((sg0 - sg1) = 0) then
        wd1 := 192;

    tmp32 := (al[1] * 32640) shr 15;
    tmp32 := tmp32 + wd1;
    apl1 := saturate2(tmp32, -32768, 32767);
    wd3 := 15360 - al[2];
    if (apl1 >= -wd3) then
        apl1 := apl1
    else
        apl1 := -wd3;

    if (apl1 <= wd3) then
        apl1 := apl1
    else
        apl1 := wd3;

    //* Shift of the plt signals */
    plt[2] := plt[1];
    plt[1] := plt[0];
    al[1] := apl1;
end;

(*___________________________________________________________________________
Function Name : uppol2
*)
procedure uppol2 (al, plt : pshortA);
var
    sg0, sg1, sg2, wd1, wd2, wd3, wd4, wd5, apl2 : short;
    tmp32 : long;
begin
    sg0 := plt[0] shr 15;
    sg1 := plt[1] shr 15;
    sg2 := plt[2] shr 15;
    tmp32 := al[1] shl 2;
    wd1 := saturate2(tmp32, -32768, 32767);
    wd2 := wd1;
    if(sg0 = sg1) then
        wd2 := saturate2(-tmp32, -32768, 32767);

    wd2 := wd2 shr 7;
    wd3 := -128;
    if (sg0 = sg2) then
        wd3 := 128;

    wd4 := wd2 + wd3;
    wd5 := ((al[2] * 32512) shr 15);
    apl2 := wd4 + wd5;
    if (apl2 >= -12288) then
        apl2 := apl2
    else
        apl2 := -12288;

    if (apl2 <= 12288) then
        al[2] := apl2
    else
        al[2] := 12288;
end;

(*___________________________________________________________________________
Function Name : filtep
*)
function filtep (rlt, al : pshortA) : short;
var
    wd1, wd2, spl : short;
    tmp32 : long;
begin
    //* shift of rlt */
    rlt[2] := rlt[1];
    rlt[1] := rlt[0];

    tmp32 := rlt[1] ;
    tmp32 := (al[1] * tmp32 ) shr 14;
    wd1 := saturate2(tmp32, -32768, 32767);
    tmp32 := rlt[2] ;
    tmp32 := (al[2] * tmp32) shr 14;
    wd2 := saturate2(tmp32, -32768, 32767);
    spl := wd1 + wd2;

    exit(spl);
end;
//* ..................... End of filtep() ..................... */


(*___________________________________________________________________________
Function Name : filtez
*)
function filtez (dlt, bl : pshortA) : short;
var
    szl : short;
    i : short;
    tmp32 : long;
begin
    szl := 0;
    for i := 6 downto 1 do
    begin
        tmp32 := dlt[i];
        tmp32 := (tmp32 * bl[i]) shr 14;
        tmp32 := tmp32 + szl;
        szl := saturate2(tmp32, -32768, 32767);
    end;

    exit(szl);
end;
//* ..................... End of filtez() ..................... */

(*___________________________________________________________________________
Function Name : quantl5b
___________________________________________________________________________
*)
function quantl5b (el, detl : short) : short;
var
    sil, mil, val, wd : short;
begin
    sil := el shr 15;
    wd := 32767 - (el and 32767);
    if (0 = sil) then
        wd := el;

    val := ((6288 * detl) shr 15);
    mil := 3;
    if ( (wd - val) >= 0) then
        mil := 11;

    val := ((q5b[mil] * detl) shr 15);
    dec(mil, 2);
    if ((wd - val) >= 0) then
        inc(mil, 4);

    val := ((q5b[mil] * detl) shr 15);
    dec(mil);
    if ((wd-val) >= 0) then
        inc(mil, 2);

    val := ((q5b[mil] * detl) shr 15);

    if ((wd - val) >= 0) then
        inc(mil);

    if (mil > 14) then
        mil := 14;

    if (0 = sil) then
        inc(mil, 15);

    exit(misil5b[mil]);
end;
//* ..................... End of quantl5b() ..................... */

(*___________________________________________________________________________
Function Name quanth:
*)
function quanth (eh, deth : short) : short;
var
    sih, mih, wd : Short;
begin
    sih := eh shr 15;
    wd := 32767 - (eh and 32767);
    if (0 = sih) then
        wd := eh;

    mih := 1;
    if ( (wd - (( q2 * deth ) shr 15) ) >= 0) then
        mih := 2;

    inc(sih);

    exit(misih[sih][mih]);
end;
//* ..................... End of quanth() ..................... */

(*___________________________________________________________________________
Function Name : qmf_tx

Purpose :

G722 QMF analysis (encoder) filter. Uses coefficients in array
coef_qmf[] defined above.

Inputs :
xin0 - first sample for the QMF filter (read-only)
xin1 - secon sample for the QMF filter (read-only)
xl   - lower band portion of samples xin0 and xin1 (write-only)
xh   - higher band portion of samples xin0 and xin1 (write-only)
s    - pointer to state variable structure (read/write)

Return Value :
None.
___________________________________________________________________________
*)
procedure fl_qmf_tx_buf (xin : ppshort; xl : pshort; xh : pshort; delayx : ppshort);
var
    //* Local variables */
    i : int;
    accuma, accumb : float;
    pcoef : pfloat;
    pdelayx : pshort;
begin
    //* Saving past samples in delay line */
    dec(delayx^);
    delayx^^ := xin^^; inc(xin);
    dec(delayx^);
    delayx^^ := xin^^; inc(xin);

    //* QMF filtering */
    pcoef := pfloat(@fl_coef_qmf);
    pdelayx := delayx^;

    accuma := pcoef^ * pdelayx^; inc(pcoef); inc(pdelayx);
    accumb := pcoef^ * pdelayx^; inc(pcoef); inc(pdelayx);
    for i := 1 to 12 - 1 do
    begin
        accuma := accuma + pcoef^ * pdelayx^; inc(pcoef); inc(pdelayx);
        accumb := accumb + pcoef^ * pdelayx^; inc(pcoef); inc(pdelayx);
    end;

    xl^ := Round(accuma + accumb);
    xh^ := Round(accuma - accumb);
end;
//* ..................... End of qmf_tx_buf() ..................... */

(*___________________________________________________________________________
Function Name : qmf_rx_buf

G722 QMF synthesis (decoder) filter, whitout memory shift.
Uses coefficients in array coef_qmf[] defined above.

Inputs :
out      - out of the QMF filter (write-only)
rl       - lower band portion of a sample (read-only)
rh       - higher band portion of a sample (read-only)
*delayx  - pointer to delay line allocated outside

Return Value :
None.
___________________________________________________________________________
*)
procedure fl_qmf_rx_buf (rl, rh : short; delayx : ppshort; _out : ppshort);
var
    i : int;
    accuma, accumb : float;
    pcoef : pfloat;
    pdelayx : pshort;
begin
    //* compute sum and difference from lower-band (rl) and higher-band (rh) signals */
    //* update delay line */
    dec(delayx^);
    delayx^^ := rl + rh;
    dec(delayx^);
    delayx^^ := rl- rh;

    //* qmf_rx filtering */
    pcoef := pfloat(@fl_coef_qmf);
    pdelayx := delayx^;

    accuma := pcoef^ * pdelayx^; inc(pcoef); inc(pdelayx);
    accumb := pcoef^ * pdelayx^; inc(pcoef); inc(pdelayx);
    for i := 1 to 12 - 1 do
    begin
        accuma := accuma + pcoef^ * pdelayx^; inc(pcoef); inc(pdelayx);
        accumb := accumb + pcoef^ * pdelayx^; inc(pcoef); inc(pdelayx);
    end;

  	//* re-scale in the good range */
	accuma := accuma * 8.;
	accumb := accumb * 8.;

	//* computation of xout1 and xout2 */
	_out^^ :=  Round(Max(Min(accuma, 32767), -32768)); inc(_out^);
	_out^^ :=  Round(Max(Min(accumb, 32767), -32768)); inc(_out^);
end;
//* ..................... End of fl_qmf_rx_buf() ..................... */


//#endif /* FUNCG722_H */
//* ........................ End of file funcg722.h ......................... */

//#include "lsbcod_ns.h"

//pcmswb.h
//* ITU G.722 3rd Edition (2012-09) */

(*--------------------------------------------------------------------------
 ITU-T G.722 Annex C (ex G.722-SWB-Float) Source Code
 Software Release 1.01 (2012-07)
 (C) 2012 France Telecom, Huawei Technologies, VoiceAge Corp., NTT.
--------------------------------------------------------------------------*)

(*------------------------------------------------------------------------*
* Defines
*------------------------------------------------------------------------*)
const
    MODE_R00wm                  = 0; //* G.722        ,  WB,  48k */
    MODE_R0wm                   = 1; //* G.722        ,  WB,  56k */
    MODE_R1wm                   = 2; //* G.722        ,  WB,  64k */
    MODE_R1sm                   = 3; //* G.722        , SWB,  64k [R0wm+8k] */
    MODE_R2sm                   = 4; //* G.722        , SWB,  80k [R1wm+16k] */
    MODE_R3sm                   = 5; //* G.722, SWB,  96k [R1wm+16k*2,R2wm+16k] */

    NBITS_MODE_R00wm            = 240; //* G.722      , WB, 48k */
    NBITS_MODE_R0wm             = 280; //* G.722      , WB, 56k */
    NBITS_MODE_R1wm             = 320; //* G.722      , WB, 64k */
    NBITS_MODE_R1sm             = 320; //* G.722      ,SWB, 64k [R0wm+8k] */
    NBITS_MODE_R2sm             = 400; //* G.722      ,SWB, 80k [R1wm+16k] */
    NBITS_MODE_R3sm             = 480; //* G.722      ,SWB, 96k [R2wm+16k/R1wm+16k*2] */

    NSamplesPerFrame08k         = 40;   //* Number of samples a frame in 8kHz  */
    NSamplesPerFrame16k         = 80;   //* Number of samples a frame in 16kHz */
    NSamplesPerFrame32k         = 160;  //* Number of samples a frame in 32kHz */

    NBytesPerFrame_G722_48k     = 30;   //* G.722 48k mode */
    NBytesPerFrame_G722_56k     = 35;   //* G.722 56k mode */
    NBytesPerFrame_G722_64k     = 40;   //* G.722 64k mode */
    NBytesPerFrame_SWB_0        =  5;   //* SWB Subcodec 0 */
    NBytesPerFrame_SWB_1        = 10;   //* SWB Subcodec 1 */
    NBytesPerFrame_SWB_2        = 10;   //* SWB Subcodec 2 */

    NBitsPerFrame_G722_48k      = (NBytesPerFrame_G722_48k*8);
    NBitsPerFrame_G722_56k      = (NBytesPerFrame_G722_56k*8);
    NBitsPerFrame_G722_64k      = (NBytesPerFrame_G722_64k*8);
    NBitsPerFrame_SWB_0         = (NBytesPerFrame_SWB_0*8);
    NBitsPerFrame_SWB_1         = (NBytesPerFrame_SWB_1*8);
    NBitsPerFrame_SWB_2         = (NBytesPerFrame_SWB_2*8);

//    NBYTEPERFRAME_MAX           = NBytesPerFrame0 //* Max value of NBytesPerFrameX */

    MaxBytesPerFrame            = (NBytesPerFrame_G722_48k+NBytesPerFrame_G722_56k+NBytesPerFrame_G722_64k+NBytesPerFrame_SWB_1+NBytesPerFrame_SWB_2);
    MaxBitsPerFrame             = (MaxBytesPerFrame*8);

    L_DELAY_COMP_MAX            = 250; //* need to be considered */

    NBitsPerFrame_EL1           = 40;
    NBitsPerFrame_SWBL2         = 40;

    G722EL1_MODE                = 2; //*1: 16kbit/s, 2:8kbit/s*/

    NTAP_QMF_G722               = 24;
    QMF_DELAY_G722              = (NTAP_QMF_G722-2);
    QMF_DELAY_WB                = (QMF_DELAY_G722);

    NTAP_QMF_SWB                = 32;
    QMF_DELAY_SWB               = (NTAP_QMF_SWB-2);

(*------------------------------------------------------------------------*
* Prototypes
*------------------------------------------------------------------------*)
//void* pcmswbEncode_const(unsigned short sampf, int mode);
//void  pcmswbEncode_dest(void* p_work);
//int   pcmswbEncode_reset(void* p_work);
//int   pcmswbEncode( const short* inwave, unsigned char* bitstream, void* p_work );

//void* pcmswbDecode_const(int mode);
//void  pcmswbDecode_dest(void* p_work);
//int   pcmswbDecode_reset(void* p_work);
//int   pcmswbDecode( const unsigned char* bitstream, short* outwave, void* p_work, int ploss_status );
//int   pcmswbDecode_set(int  mode, void*  p_work);

//#endif  /* PCMSWB_H */


//pcmswb_common.h
//* ITU G.722 3rd Edition (2012-09) */

(*--------------------------------------------------------------------------
 ITU-T G.722 Annex C (ex G.722-SWB-Float) Source Code
 Software Release 1.01 (2012-07)
 (C) 2012 France Telecom, Huawei Technologies, VoiceAge Corp., NTT.
--------------------------------------------------------------------------*)

(*
 *------------------------------------------------------------------------
 *  Function: Common definitions for all module files
 *------------------------------------------------------------------------
 *)
const
    L_FRAME_NB      = NSamplesPerFrame08k;  //* Number of samples in  8 kHz */
    L_FRAME_WB      = NSamplesPerFrame16k;  //* Number of samples in 16 kHz */
    L_FRAME_SWB     = NSamplesPerFrame32k;  //* Number of samples in 32 kHz */

//#endif


//#include "g722_plc.h"
//* ITU G.722 3rd Edition (2012-09) */

(*--------------------------------------------------------------------------
 ITU-T G.722 Annex C (ex G.722-SWB-Float) Source Code
 Software Release 1.01 (2012-07)
 (C) 2012 France Telecom, Huawei Technologies, VoiceAge Corp., NTT.
--------------------------------------------------------------------------*)

//#include "funcg722.h"
const
//#define HP_FILTER_MODIF_FT

    (*********************
     * Constants for PLC *
     *********************)

    //* signal classes */
    G722PLC_TRANSIENT           = 3;
    G722PLC_UNVOICED            = 1;
    G722PLC_VUV_TRANSITION      = 7;
    G722PLC_WEAKLY_VOICED       = 5;
    G722PLC_VOICED              = 0;

    //* LPC windowing */
    ORD_LPC                     = 8;                //* LPC order */
    ORD_LPCP1                   = 9;                //* LPC order +1*/
    HAMWINDLEN                  = 80;                //* length of the assymetrical hamming window */

    //* open-loop pitch parameters */
    MAXPIT                      = 144;              //* maximal pitch lag (20ms @8kHz) => 50 Hz */
    MAXPIT2                     = (2*MAXPIT);

    //* 4:1 decimation constants */
    FACT                        = 4;                //* decimation factor for pitch analysis */
    FACTLOG2                    = 2;                //* log2(FACT) */
    FACT_M1                     = (FACT-1);
    FACT_S2                     = (FACT/2);
    FEC_L_FIR_FILTER_LTP        = 9;                //* length of decimation filter */
    FEC_L_FIR_FILTER_LTP_M1     = (FEC_L_FIR_FILTER_LTP-1); //* length of decimation filter - 1 */
    NOOFFSIG_LEN                = (MAXPIT2+FEC_L_FIR_FILTER_LTP_M1);
    MEMSPEECH_LEN               = (MAXPIT2+ORD_LPC+1);

    //* open-loop pitch parameters */
    END_LAST_PER                = (MAXPIT2-1);
    END_LAST_PER_1              = (END_LAST_PER-1);

    MAXPIT2P1                   = (MAXPIT2+1);
    MAXPIT_S2                   = (MAXPIT/2);
    MAXPIT_P2                   = (MAXPIT+2);
    MAXPIT_DS                   = (MAXPIT/FACT);
    MAXPIT_DSP1                 = (MAXPIT_DS+1);
    MAXPIT_DSM1                 = (MAXPIT_DS-1);
    MAXPIT2_DS                  = (MAXPIT2/FACT);
    MAXPIT2_DSM1                = (MAXPIT2_DS-1);
    MAXPIT_S2_DS                = (MAXPIT_S2/FACT);
    MINPIT                      = 16;               //* minimal pitch lag (2ms @8kHz) => 500 Hz */
    MINPIT_DS                   = (MINPIT/FACT);
    GAMMA                       = 30802;            //* 0.94 in Q15 */
    GAMMA2                      = 28954;            //* 0.94^2 */
    F_GAMMA                     = (0.94);            //* 0.94 in Q15 */
    F_GAMMA2                    = (0.8836);            //* 0.94^2 */
    F_GAMMA_AL2                 = (0.97);            //* 0.97 in Q15 */
    F_GAMMA2_AL2                = (0.9409);            //* 0.97^2 */
    F_GAMMA3_AL2                = (0.9127);            //* 0.97^3 */
    F_GAMMA4_AL2                = (0.8853);            //* 0.97^4 */
    F_GAMMA5_AL2                = (0.8587);            //* 0.97^5 */
    F_GAMMA6_AL2                = (0.8330);            //* 0.97^6 */
    GAMMA_AZ1                   = 32440;            //* 0.99 in Q15 */
    GAMMA_AZ2                   = 32116;            //* 0.99^2 in Q15 */
    GAMMA_AZ3                   = 31795;            //* 0.99^3 in Q15 */
    GAMMA_AZ4                   = 31477;            //* 0.99^4 in Q15 */
    GAMMA_AZ5                   = 31162;            //* 0.99^5 in Q15 */
    GAMMA_AZ6                   = 30850;            //* 0.99^6 in Q15 */
    GAMMA_AZ7                   = 30542;            //* 0.99^7 in Q15 */
    GAMMA_AZ8                   = 30236;            //* 0.99^8 in Q15 */

    //* cross-fading parameters */
    CROSSFADELEN                = 80;               //* length of crossfade (10 ms @8kHz) */
    CROSSFADELEN16              = 160;              //* length of crossfade (10 ms @16kHz) */

    //* adaptive muting parameters */
    END_1ST_PART                = 80;               //* attenuation range: 10ms @ 8kHz */
    END_2ND_PART                = 160;              //* attenuation range: 20ms @ 8kHz */
    END_3RD_PART                = 480;              //* attenuation range: 60ms @ 8kHz */
    FACT1_V                     = 10;
    FACT2_V                     = 20;
    FACT3_V                     = 95;  //*30367/320*/
    FACT2P_V                    = (FACT2_V-FACT1_V);
    FACT3P_V                    = (FACT3_V-FACT2_V);
    FACT1_UV                    = 10;
    FACT2_UV                    = 10;
    FACT3_UV                    = 200; //*31967/160*/
    FACT2P_UV                   = (FACT2_UV-FACT1_UV);
    FACT3P_UV                   = (FACT3_UV-FACT2_UV);
    FACT1_V_R                   = 409; //*correction 25/09/07 for step by 6, was 273 for step by 4, because problem attenuate_lin with 15 ms*/
    FACT2_V_R                   = 409; //*32768/80*/
    FACT3_V_R                   = 409;
    FACT2P_V_R                  = (FACT2_V_R-FACT1_V_R);
    FACT3P_V_R                  = (FACT3_V_R-FACT2_V_R);
    LIMIT_FOR_RESET             = 160; //*with 240 there are some accidents */

    F_FACT1_V                   = 3.0517578e-4;
    F_FACT2_V                   = 6.1035156e-4;
    F_FACT3_V                   = 2.8991699e-3;  //*30367/320*/
    F_FACT2P_V                  = (F_FACT2_V-F_FACT1_V);
    F_FACT3P_V                  = (F_FACT3_V-F_FACT2_V);
    F_FACT1_UV                  = 3.0517578e-4;
    F_FACT2_UV                  = 3.0517578e-4;
    F_FACT3_UV                  = 6.1035156e-3; //*31967/160*/
    F_FACT2P_UV                 = (F_FACT2_UV-F_FACT1_UV);
    F_FACT3P_UV                 = (F_FACT3_UV-F_FACT2_UV);
    F_FACT1_V_R                 = 0.0125; //*correction 25/09/07 for step by 6, was 273 for step by 4, because problem attenuate_lin with 15 ms*/
    F_FACT2_V_R                 = 0.0125; //*32768/80*/
    F_FACT3_V_R                 = 0.0125;
    F_FACT2P_V_R                = (F_FACT2_V_R-F_FACT1_V_R);
    F_FACT3P_V_R                = (F_FACT3_V_R-F_FACT2_V_R);

    //* size of higher-band signal buffer */
    LEN_HB_MEM                  = 160;
    LEN_HB_MEM_MLF              = (LEN_HB_MEM - L_FRAME_NB);

(**************
 * PLC states *
 **************)
type
    pG722PLC_STATE_FLT = ^G722PLC_STATE_FLT;
    G722PLC_STATE_FLT = packed record
        s_prev_bfi      : short; //* bad frame indicator of previous frame */

        //* signal buffers */
        f_mem_speech      : pfloatA;     //* lower-band speech buffer */
        f_mem_exc         : pfloat;        //* past LPC residual */
        f_mem_speech_hb   : pfloatA;  //* higher-band speech buffer */

        //* analysis results (signal class, LPC coefficients, pitch delay) */
        s_clas            : short;  //* unvoiced, weakly voiced, voiced */
        s_t0              : short;    //* pitch delay */
        s_t0p2            : short;     //* constant*/

        //* variables for crossfade */
        s_count_crossfade : short; //* counter for cross-fading (number of samples) */
        f_crossfade_buf   : array[0..CROSSFADELEN - 1] of float;

        //* variables for DC remove filter in higher band */
        f_mem_hpf_in      : float;
        f_mem_hpf_out     : float;

        //* variables for synthesis attenuation */
        s_count_att       : short;    //* counter for lower-band attenuation (number of samples) */
        s_count_att_hb    : short; //* counter for higher-band attenuation (number of samples) */
        s_inc_att         : short;      //* increment for counter update */
        f_fact1           : float;
        f_fact2p          : float;
        f_fact3p          : float;
        f_weight_lb       : float;
        f_weight_hb       : float;

        //* coefficient of ARMA predictive filter A(z)/B(z) of G.722 */
        f_a               : pfloatA;     //* LPC coefficients */
        f_mem_syn         : pfloat;        //* past synthesis */
    end;

// void*  G722PLC_init_flt(void);
// void G722PLC_conceal_flt(void * plc_state, Short* outcode, g722_state *decoder);
// Float G722PLC_hp_flt(Float *x1, Float* y1, Float signal, const Float *G722PLC_b_hp, const Float *G722PLC_a_hp);
// void   G722PLC_clear_flt(void * state);

//#endif


//#include "funcg722.h"
//#include "hsb_enh.h"
//#include "ns_common.h"
//#include "bwe.h"

//* ITU G.722 3rd Edition (2012-09) */

(*--------------------------------------------------------------------------
 ITU-T G.722 Annex C (ex G.722-SWB-Float) Source Code
 Software Release 1.01 (2012-07)
 (C) 2012 France Telecom, Huawei Technologies, VoiceAge Corp., NTT.
--------------------------------------------------------------------------*)

const
    L_WINDOW        = 80;       //* length of the LP analysis */
    ORD_M           = 4 ;       //* LP order (and # of "lags" in autocorr.c)  */
    GAMMA1          = 30147;    //* 0.92f in Q15 */
    GAMMA1S4        = 7536 ;    //* 0.92f/4 = 0.23 in Q15 */

    FL_GAMMA1       = 0.92;     //* 0.92f in Q15 */
    FL_GAMMA1S4     = 0.23;      //* 0.92f/4 = 0.23 in Q15 */
    MAX_NORM        = 16;       //* when to begin noise shaping deactivation  */
    //* use MAX_NORM = 32 to disable this feature */

type
    pfl_noiseshaping_state = ^fl_noiseshaping_state;
    fl_noiseshaping_state = packed record
        buffer      : array[0..39] of float;            //* buffer for past decoded signal */
        mem_wfilter : array[0..ORD_M - 1] of float;     //* buffer for the weighting filter */
        mem_t       : array[0..ORD_M - 1] of float;
        mem_el0     : array[0..ORD_M - 1] of float;
        gamma       : float;
    end;

const
    ORD_MP1         = 5;        //* LP order + 1  */
    ORD_MM1         = 3;        //* LP order - 1  */

//#endif

// table_lowband.c

//* ITU G.722 3rd Edition (2012-09) */
(*--------------------------------------------------------------------------
 ITU-T G.722 Annex C (ex G.722-SWB-Float) Source Code
 Software Release 1.01 (2012-07)
 (C) 2012 France Telecom, Huawei Technologies, VoiceAge Corp., NTT.
--------------------------------------------------------------------------*)
(*
 *------------------------------------------------------------------------
 *  File: table_lowband.c
 *  Function: Tables for lower-band modules
 *------------------------------------------------------------------------
 *)

const
(***********************************
   Tables used in autocorr_ns.c
 ***********************************)
    fl_NS_window : array[0..L_WINDOW - 1] of float = (
      0./32768.,    668./32768.,   1142./32768.,   1636./32768.,   2152./32768.,   2688./32768.,   3245.f/32768.f,   3820.f/32768.f,   4414.f/32768.f,   5026.f/32768.f,
   5654./32768.,   6299./32768.,   6959./32768.,   7634./32768.,   8321./32768.,   9020./32768.,   9731.f/32768.f,  10451.f/32768.f,  11181.f/32768.f,  11917.f/32768.f,
  12660./32768.,  13408./32768.,  14160./32768.,  14913./32768.,  15668./32768.,  16423./32768.,  17176.f/32768.f,  17925.f/32768.f,  18671.f/32768.f,  19410.f/32768.f,
  20142./32768.,  20866./32768.,  21579./32768.,  22282./32768.,  22971./32768.,  23646./32768.,  24306.f/32768.f,  24950.f/32768.f,  25575.f/32768.f,  26181.f/32768.f,
  26767./32768.,  27332./32768.,  27873./32768.,  28391./32768.,  28884./32768.,  29352./32768.,  29793.f/32768.f,  30206.f/32768.f,  30590.f/32768.f,  30946.f/32768.f,
  31271./32768.,  31566./32768.,  31830./32768.,  32061./32768.,  32261./32768.,  32428./32768.,  32562.f/32768.f,  32663.f/32768.f,  32730.f/32768.f,  32764.f/32768.f,
  32730./32768.,  32428./32768.,  31830./32768.,  30946./32768.,  29793./32768.,  28391./32768.,  26767.f/32768.f,  24950.f/32768.f,  22971.f/32768.f,  20866.f/32768.f,
  18671./32768.,  16423./32768.,  14160./32768.,  11917./32768.,   9731./32768.,   7634./32768.,   5654.f/32768.f,   3820.f/32768.f,   2152.f/32768.f,    668/32768.f);

/* Lag window for noise shaping */
/* Bandwidth expansion = 120Hz (fs = 8kHz) */
/* noise floor = 1.0001 (1/1.0001 on r[1]..r[M], r[0] not stored) */
/* for i=1:M-1, wdw(i)=32768/wnc*exp(-.5*(2*pi*bwe/fs*i)^2); end; */

/*floor(exp(-0.5*(2*pi*120*k/8000)^2)*.9999*32768) */
const Float fl_NS_lag[ORD_M] = {
 (Float)0.99546898, (Float)0.98229336, (Float)0.96072037, (Float)0.9313118};

// end of table_lowband.c


// autocorr_ns.c

//* ITU G.722 3rd Edition (2012-09) */

(*--------------------------------------------------------------------------
 ITU-T G.722 Annex C (ex G.722-SWB-Float) Source Code
 Software Release 1.01 (2012-07)
 (C) 2012 France Telecom, Huawei Technologies, VoiceAge Corp., NTT.
--------------------------------------------------------------------------*)

(*
*------------------------------------------------------------------------
*  File: autocorr_ns.c
*  Function: Compute autocorrelations of signal for noise shaping
*------------------------------------------------------------------------
*)

function fl_AutocorrNS(  //*  Return: R0 Normalization shift       */
                  x : pfloatA;      //* (i)    : Input signal (80 samples)    */
                  r : pfloatA       //* (o) : Autocorrelations */
                    ): short;
var
    i, j : int;
    alpha : float;
    y : array[0..L_WINDOW - 1] of float;
    sum, zcr : float;
    norm : short;
    zcross : short;
begin
    //* Approximate R(1)/R(0) (tilt or harmonicity) with a zero-crossing measure */
    zcross := L_WINDOW - 1;
    for i := 1 to L_WINDOW - 1 do
    begin
        if ((x[i-1] ) < 0.0) then
        begin
            if (x[i] >= 0.0) then dec(zcross);
        end
        else
        begin
            if (x[i] < 0.0) then dec(zcross);
        end
    end;

    zcr := 0.38275 + zcross * 0.007813; //* set the factor between .38 and 1.0 */

    //* Pre-emphesis and windowing */
    for i := 1 to L_WINDOW - 1 do
    begin
        //* Emphasize harmonic signals more than noise-like signals */
        y[i] := fl_NS_window[i] * (x[i] - zcr * x[i - 1]);
    end;

    /* Low level fixed noise shaping (when rms <= 100) */

    sum = (Float)10000.0; /* alpha* alpha */
    for (i = 1; i < L_WINDOW; i++) {
    sum += y[i]* y[i];
    }
    r[0] = sum;
    alpha = (Float)1.;

    /* Compute r[1] to r[m] */
    for (i = 1; i <= ORD_M; i++)
    {
      /* low level fix noise shaping */
      alpha *= (Float)0.95;       /* alpha *= 0.95 */
      sum = alpha * (Float)10000.0;
      for (j = 1; j < L_WINDOW-i; j++) {
          sum += y[j] * y[j+i];
      }
      r[i] = sum;
    }

    /* Lag windowing */
    fl_Lag_window(r, fl_NS_lag, ORD_M);

    norm = (Short)Fnorme32((Float)2.*r[0]);

    exit(norm);
end;

// end of autocorr_ns.c


// lpctool.c
//* ITU G.722 3rd Edition (2012-09) */

(*--------------------------------------------------------------------------
 ITU-T G.722 Annex C (ex G.722-SWB-Float) Source Code
 Software Release 1.01 (2012-07)
 (C) 2012 France Telecom, Huawei Technologies, VoiceAge Corp., NTT.
--------------------------------------------------------------------------*)

(*
*------------------------------------------------------------------------
*  File: lpctool.c
*  Function: Linear prediction tools
*------------------------------------------------------------------------
*)

(*-------------------------------------------------------------------------*
* Function Levinson                                                        *
*--------------------------------------------------------------------------*)
const
    MAXORD      = 6;

procedure fl_Levinson(
              R : pfloatA;     //* (i)     : R[M+1] Vector of autocorrelations  */
              rc : pfloatA;      //* (o)   : rc[M]   Reflection coefficients.         */
              stable : pshort;  //* (o)    : Stability flag                           */
              ord : short;       //* (i)   : LPC order                                */
              a : pfloatA        //* (o)   : LPC coefficients                         */
              );
var
    err, s, at : float;                     //* temporary variable */
    i, j, l : int;
begin
    stable^ := 0;

    //* K = A[1] = -R[1] / R[0] */
    rc[0] := (-R[1]) / R[0];
    a[0] := 1.0;
    a[1] := rc[0];
    err := R[0] + R[1] * rc[0];

    (*-------------------------------------- */
    /* ITERATIONS  I=2 to lpc_order          */
    /*-------------------------------------- *)
    for i := 2 to ord do
    begin
        s := 0.0;
        for j := 0 to i - 1 do
          s := s + R[i - j] * a[j];

        rc[i - 1] := (-s) / (err);
        //* Test for unstable filter. If unstable keep old A(z) */
        if (abs(rc[i-1]) > 0.99) then
        begin
            stable^ := 1;
            exit;
        end;

        for j := 1 to i div 2 do
        begin
            l := i - j;
            at := a[j] + rc[i - 1] * a[l];
            a[l] := a[l] + rc[i - 1] * a[j];
            a[j] := at;
        end;

        a[i] := rc[i - 1];
        err := err + rc[i - 1] * s;
        if (err <= 0.0) then
            err := 0.001;
    end;
end;



(*----------------------------------------------------------*
* Function Lag_window()                                    *
*                                                          *
* r[i] *= lag_wind[i]                                      *
*                                                          *
*    r[i] and lag_wind[i] are in special double precision. *
*    See "oper_32b.c" for the format                       *
*                                                          *
*----------------------------------------------------------*)
procedure fl_Lag_window(
                R : pfloatA;
                W : pfloatA;
                ord : short
                );
var
    i : int;
begin
  for i := 1 to ord do
	  R[i] := R[i] * W[i - 1];
end;


(*------------------------------------------------------------------------*
*                         WEIGHT_A.C                                     *
*------------------------------------------------------------------------*
*   Weighting of LPC coefficients                                        *
*   ap[i]  =  a[i] * (gamma ** i)                                        *
*                                                                        *
*------------------------------------------------------------------------*)
procedure fl_Weight_a(
              a : pfloatA;        //* (i)  : a[m+1]  LPC coefficients             */
              ap : pfloatA;       //* (o)  : Spectral expanded LPC coefficients   */
              gamma : float;      //* (i)  : Spectral expansion factor.           */
              m : short           //* (i)  : LPC order.                           */
              );
var
    i : int;
    fac : float;
begin
    ap[0] := a[0];
    fac := gamma;
    for i := 1 to m - 1 do
    begin
        ap[i] := fac * a[i];
        fac := fac * gamma;
    end;
    ap[m] := a[m] * fac;
end;



// bit_op.c
//* ITU G.722 3rd Edition (2012-09) */

(*--------------------------------------------------------------------------
 ITU-T G.722 Annex C (ex G.722-SWB-Float) Source Code
 Software Release 1.01 (2012-07)
 (C) 2012 France Telecom, Huawei Technologies, VoiceAge Corp., NTT.
--------------------------------------------------------------------------*)

(*-----------------------------------------------------------------*
*   Funtion  GetBit                                               *
*            ~~~~~~~~~~~~                                         *
*   Read indice from the bitstream.                               *
*-----------------------------------------------------------------*)
(*
* BIT PACKING/UNPACKING IS USUALLY NOT INSTRUMENTED
*)
function GetBit(
              pBit : pp_wbenh; //* i/o: pointer on address of next bit */
              nbits : short    //* i:   number of bits of code         */
              ) : short;
var
    i, code, temp16 : short;
begin
    code := 0;
    for i := 0 to nbits - 1 do
    begin
        code := code shl 1;

        temp16 := 1;
        if (pBit^^ = $007f) then
          temp16 := 0;

        code := code or temp16;

        inc(pBit^);
    end;

    exit(code);
end;

(*
* BIT PACKING/UNPACKING IS USUALLY NOT INSTRUMENTED
*)
function s_GetBitLong(
                  pBit : pp_wbenh;  //* i/o: pointer on address of next bit */
                  nbits : short     //* i:   number of bits of code         */
                  ) : int;
var
    i : short;
    code, temp16 : int;
begin
    code := 0;
    for i := 0 to nbits - 1 do
    begin
        code := code shl 1;
        temp16 := 1;
        if (pBit^^ = $007f) then
            temp16 := 0;

        code := code or temp16;

        inc(pBit^);
    end;

    exit( code );
end;


(*-----------------------------------------------------------------*
*   Funtion  PushBit                                              *
*            ~~~~~~~~~~~~                                         *
*   Write indice to the bitstream.                                *
*-----------------------------------------------------------------*)
(*
* BIT PACKING/UNPACKING IS USUALLY NOT INSTRUMENTED
*)
procedure s_PushBit(
             code : short;  //* i:   codeword                       */
             pBit : pp_wbenh; //* i/o: pointer on address of next bit */
             nbits : short   //* i:   number of bits of code         */
             );
var
    i, nbitm1, mask : short;
begin
    //* MSB -> LSB */
    nbitm1 := nbits - 1;

    for i := nbitm1 downto 0 do
    begin
        pBit^^ := $0081;
        mask := (code shr i) and $0001;

        if (mask = 0) then
              pBit^^ := $007f;

        inc(pBit^);
    end;
end;

(*
* BIT PACKING/UNPACKING IS USUALLY NOT INSTRUMENTED
*)
procedure s_PushBitLong(
             code : int;  //* i:   codeword                       */
             pBit : pp_wbenh; //* i/o: pointer on address of next bit */
             nbits : short   //* i:   number of bits of code         */
                 );
var
    i, nbitm1 : short;
    mask : int;
begin
    //* MSB -> LSB */
    nbitm1 := nbits - 1;
    for i := nbitm1 downto 0 do
    begin
        pBit^^ := $0081;
        mask := (code shr i) and $0001;

        if( mask = 0 ) then
            pBit^^ := $007f;

        inc(pBit^);
    end;
end;

// hsb_enh.c
//* ITU G.722 3rd Edition (2012-09) */

(*--------------------------------------------------------------------------
 ITU-T G.722 Annex C (ex G.722-SWB-Float) Source Code
 Software Release 1.01 (2012-07)
 (C) 2012 France Telecom, Huawei Technologies, VoiceAge Corp., NTT.
--------------------------------------------------------------------------*)

{#define AH   s->ah
#define BH   s->bh
#define DETH s->deth
#define DH  s->dh
#define NBH  s->nbh
#define PH  s->ph
#define RH  s->rh
#define SH   s->sh
#define SPH  s->sph
#define SZH  s->szh}
function hsbcod_ldec(xh : short; s : pg722_state; t : pshort; deth : pshort; sh : pshort) : short;
var
    eh, ih, yh : short;
begin
    eh := xh - s.sh;         //* subtra */
    ih := quanth(eh, s.deth);

    deth^ := s.deth;  //* save before update*/
    sh^ := s.sh;

    adpcm_adapt_h(ih, pshort(@s.ah), pshort(@s.bh), pshort(@s.dh), pshort(@s.ph), pshort(@s.rh), @s.nbh, @s.deth, @s.szh, @s.sh);
    yh := s.dh[0]+ sh^; //* output of the previous stage (2bit quantizer) */
    t^ := xh - yh;  //*error signal between the input signal and the output of the previous core stage */

    Exit(ih);
end;

{$IFDEF FALSE }

function fl_hsbcod_ldec_l0l1(
                        xh : short;
                        s : pg722_state;
                        i : short;
                        pBit_wbenh : pp_wbenh;
                        code0 : pshort;
                        code1 : pshort;
                        A : pfloatA;
                        mem1 : pfloatA;
                        mem2 : pfloatA;
                        enh_no : pshort;
                        sum : float;
                        wbenh_flag : short;
                        n_cand : short
                        ) : float;
var
    ih, stmp, w16tmp : short;
    dh_abs, t, tw, tmp, err0, err1 : float;
    ihr : short;

    dh23, ih23,
    deth, sh,
    tab_ind, yh : short;
    cand : array[0..2 - 1] of short;
begin
    if (i = 0) then
        sum := -1.0;  //*to force enhancement for the first sample*/

    ih := hsbcod_ldec(xh, s, @stmp, @deth, @sh); //*core coding*/
    t := stmp;
    code0^ := code0^ + (ih shl 6);

    tw := fl_noise_shaper(A, t, mem1); //*target value, determinated using the noise shaping filter A*/
    mem1[1] := t;  //*EL0 noise shaping memory update*/

    dh23 := s.dh[0];  //*default 2 bit quantizer*/
    ih23 := ih;
    tab_ind := 16;
    dh_abs := 0;

    if(wbenh_flag > 0) then
    begin
        if ((i+ enh_no^) = L_FRAME_NB ) then
              sum := -2.0;  //*to force enhancement for the first sample*/
        dh_abs := abs(s.dh[0]);

        if ((i * dh_abs) > sum) and (enh_no^ > 0) then
        begin
              //*minimisation of the error between the target value and the possible scalar quantization values*/
              //*ih23: index of the enhancement scalar codeword that minimise the error*/
              w16tmp := 0;

              if (tw > ((tresh_enh[ih] * deth) shr 15)) then //*comparison to the border value*/
                    w16tmp := 1;

              s_PushBit( w16tmp, pBit_wbenh, 1 );
              ih23 := ( ih shl 1 ) or w16tmp ;
              dh23 := (deth * oq3new[ih23]) shr 15; //*recontructed value (previous stage + enhancement)*/
              mem1[1] := t - (dh23 - s.dh[0]); //*update filter memory (with error signal of current stage)*/
              dec(enh_no^);
              tab_ind := 0;
        end;
    end;
    yh := dh23 + sh; //*2 or 3 bit quantizer*/

    if (n_cand > 0) then
    begin
        ihr := (ih23 shl 1) + tab_ind;
        cand[0] := ( ( deth * oq4_3new[ihr    ]) shr 15) - dh23;
        cand[1] := ( ( deth * oq4_3new[ihr + 1]) shr 15) - dh23;

        //* Encode enhancement */
        t := (xh - yh);
        tw := fl_noise_shaper(A, t, mem2);

        tmp := tw - cand[0];
        err0 := tmp * tmp;
        tmp := tw - cand[1];
        err1 := tmp * tmp;
        ihr := 0;
        if (err1 < err0) then
              ihr := 1;
        mem2[1] := (t - cand[ihr]);

        code1^ := ihr;
    end;

    exit(dh_abs); //* to update sum*/
end;


function fl_hsbdec_enh(ih, ih_enh, mode : short;
                  s : pg722_state;
                  i : short;
                  pBit_wbenh : pp_wbenh;
                  wbenh_flag : short;
                  enh_no : pshort;
                  sum_ma_dh_abs : pfloat) : short;
var
    dh, rh, yh : short;
    dh_abs : float;

    ih23, dh23, mode23, nshift : short;
    q3bit_flag, sh, deth : short;
begin
    sh := s.sh;
    deth := s.DETH;
    adpcm_adapt_h(ih, pshort(@s.ah), pshort(@s.bh), pshort(@s.dh), pshort(@s.ph), pshort(@s.rh), @s.nbh, @s.deth, @s.szh, @s.sh);

    dh23 := s.dh[0];  //*default 2 bit quantizer*/
    ih23 := ih;
    q3bit_flag := 0;
    if (wbenh_flag > 0) then
    begin
        dh_abs := abs(s.dh[0]);

        if ( (i = 0) or ( ((dh_abs * i) > sum_ma_dh_abs^) and (enh_no^ > 0)) or ((i + enh_no^) = L_FRAME_NB) ) then
        begin
            ih23 := ih shl 1;
            if (GetBit( pBit_wbenh, 1 ) > 0) then
                ih23 := (ih shl 1) or 1;

            q3bit_flag := 1;
            enh_no^ := enh_no^ - 1;  //*pointer*/
        end;
        sum_ma_dh_abs^ := sum_ma_dh_abs^ + dh_abs;
    end;

    nshift := 3 - mode; //*determinates number of shifts*/
    mode23 := mode - q3bit_flag; //*mode absolut, if enhancement in EL0, 1 extra bit, lower mode (=higher bitrate) quantizer*/
    ih_enh := (ih23 shl nshift) + (ih_enh and ($07 shr mode)); //*this line is enough without if, works well with mode = 3*/

    dh := (deth * pshortA(invqbh_tab[mode23])[ih_enh]) shr 15;
    rh := sh + dh;              //* recons */
    yh := limit( rh );

    exit(yh);
end;

{$ENDIF FALSE }

//* ........................ End of hsbdec() ........................ */


// bwe.h
//* ITU G.722 3rd Edition (2012-09) */

(*--------------------------------------------------------------------------
 ITU-T G.722 Annex C (ex G.722-SWB-Float) Source Code
 Software Release 1.01 (2012-07)
 (C) 2012 France Telecom, Huawei Technologies, VoiceAge Corp., NTT.
--------------------------------------------------------------------------*)

(*------------------------------------------------------------------------*
 * Defines
 *------------------------------------------------------------------------*)
const
    EPS                     = 1.0e-3;
    FAC_LOG2                = 3.321928095;
    //Fabs(x)  ((x)<0?-(x):(x))
    INV_TRANSI_FENV_EXPAND  = 0.2;

    SWB_NORMAL_FENV         = 8;
    SWB_TRANSI_FENV         = 4;
    SWB_TRANSI_FENV_WIDTH   = 16;
    SWB_TENV                = 4;
    SWB_F_WIDTH             = 64;
    ZERO_SWB                = 20;
    SWB_T_WIDTH             = 80;
    SWB_TENV_WIDTH          = 20;
    TRANSIENT               = 3;
    HARMONIC                = 2;
    NORMAL                  = 0;
    NUM_FRAME               = 3;
    TRANSI_FENV_EXPAND      = 5;
    VQ_FENV_SIZE            = 64;
    VQ_FENV_DIM             = 4;
    NUM_SHARP               = 10;
    SHARP_WIDTH             = 6;
    FENV_WIDTH              = (SWB_F_WIDTH / SWB_NORMAL_FENV);
    SWB_F_WIDTH_HALF        = (SWB_F_WIDTH/2);
    NBITS_MODE_R1SM_TOTLE   = 40;
    NBITS_MODE_R1SM_BWE     = 21;
    NBITS_MODE_R1SM_WBE     = (NBITS_MODE_R1SM_TOTLE - NBITS_MODE_R1SM_BWE);
    NBytesPerFrame_R1SM     = 5;
    NUM_FENV_VECT           = 2;
    NUM_FENV_CODEBOOK       = 2;
    SUB_SWB_T_WIDTH         = (SWB_T_WIDTH/4);
    HALF_SUB_SWB_T_WIDTH    = (SUB_SWB_T_WIDTH/2);
    HALF_SUB_SWB_T_WIDTH_1  = HALF_SUB_SWB_T_WIDTH-1;
    HALF_SUB_SWB_T_WIDTH_2  = HALF_SUB_SWB_T_WIDTH-2;
    HALF_SUB_SWB_T_WIDTH_3  = HALF_SUB_SWB_T_WIDTH-3;
    WB_POSTPROCESS_WIDTH    = 36;
    SWB_NORMAL_FENV_HALF    = (SWB_NORMAL_FENV/2);
    NUM_PRE_SWB_TENV        = ((NUM_FRAME-1)*SWB_TENV);
    NORMAL_FENV_HALVE       = (SWB_NORMAL_FENV/2);
    ENERGY_WB               = 45;

type
    BWE_state_enc = packed record
    {
        Short preMode;
        Float preGain;
        Float fIn[SWB_T_WIDTH];
        Float stEnvPre[(NUM_FRAME - 1) * SWB_TENV];
        Short modeCount;
        Float log_rms_fix_pre[NUM_PRE_SWB_TENV];
        Float enerEnvPre[NUM_FRAME - 1];
        Float pre_sy[SWB_T_WIDTH];
    }
    end;

    BWE_state_dec = packed record    //* used in decoder only */
    {
        Float pre_tEnv;
        Float fpre_wb[SWB_T_WIDTH];
        Float fPrev[L_FRAME_WB];
        Float fCurSave[L_FRAME_WB];
        Float fPrev_wb[L_FRAME_WB];
        Float fCurSave_wb[L_FRAME_WB];
        Float pre_fEnv[10];
        Float tPre[HALF_SUB_SWB_T_WIDTH];
        Short norm_pre;
        Short norm_pre_wb;
        Short pre_mode;
        Float attenu2;
        Float prev_enerL;
        Float spGain_sm[WB_POSTPROCESS_WIDTH];
        Short modeCount;
        Short Seed;
    }
    end;

(*------------------------------------------------------------------------*
 * Prototypes
 *------------------------------------------------------------------------*
Short bwe_encode_reset (void *work);
void*  bwe_encode_const (void);
void   bwe_encode_dest (void *work);
Short Icalc_tEnv(
					Float *sy,              /* (o)   current SWB high band signal    */
					Float * rms,            /* (o)    log2 of the temporal envelope  */
					Short * transient,
					int preMode,
					void* work
					);
Short bwe_enc(
					Float          fBufin[],           /* (i): Input super-higher-band signal */
					unsigned short **pBit,             /* (o): Output bitstream               */
					void           *work,        /* (i/o): Pointer to work space        */
					Float          *tEnv,              /* (i) */
					Short          transi,
					Short          *cod_Mode,
					Float          *f_Fenv_SWB,        /* (o) */
					Float          *fSpectrum,         /* (o) */
					Short          *index_g,
					Short          T_modify_flag,
					Float          fEnv_unq[]          /* (o) */
					);
Short bwe_dec_update( /*to maintain mid-band post-processing memories up to date in case of WB frame*/
					Float  	       *fy_low,    	       /* (i): Input lower-band WB signal */
					void           *work               /* (i/o): Pointer to work space        */
					);
Short bwe_decode_reset (void *work);
void*  bwe_decode_const (void);
void   bwe_decode_dest (void *work);
Short bwe_dec_freqcoef(
					unsigned short **pBit,             /* (i): Input bitstream                */
					Float  *fy_low,    	               /* (i): Input lower-band WB signal */
					void   *work,                      /* (i/o): Pointer to work space        */
					Short  *sig_Mode,
					Float  *f_sTenv_SWB,               /* (o) */
					Float  *f_scoef_SWB,
					Short  *index_g,
					Float  *f_sFenv_SVQ,               /* (o): decoded spectral envelope with no postprocess. */
					Short  ploss_status,
					Short  bit_switch_flag,
					Short  prev_bit_switch_flag
					);
Short bwe_dec_timepos(
					int sig_Mode,
					Float *Tenv_SWB,
					Float *coef_SWB,
					Float *fy_hi,       /* (o): Output higher-band signal */
					void  *work,        /* (i/o): Pointer to work space        */
					int erasure,
					int T_modify_flag
					);
*)
// end of bwe.h

procedure fl_hsbcod_buf_ns(
              sigin : pshortA;         //* (i): Input 5-ms signal                     */
              code0 : pshortA;        //* (o): Core-layer bitstream (multiplexed)    */
              code1 : pshortA;        //* (o): LB enh. layer bitstream (multiplexed) */
              g722_encoder : pg722_state;
              ptr : pointer;                     //* (i/o): Pointer to work space               */
              mode : short;
              wbenh_flag : short;
              pBit_wbenh : pp_wbenh
              );
begin
    // remove me
end;

{$IFDEF FALSE }

procedure fl_hsbcod_buf_ns(
              sigin : pshortA;         //* (i): Input 5-ms signal                     */
              code0 : pshortA;        //* (o): Core-layer bitstream (multiplexed)    */
              code1 : pshortA;        //* (o): LB enh. layer bitstream (multiplexed) */
              g722_encoder : pg722_state;
              ptr : pointer;                     //* (i/o): Pointer to work space               */
              mode : short;
              wbenh_flag : short;
              pBit_wbenh : pp_wbenh
              );
var
    work : pfl_noiseshaping_state absolute ptr;
    r : array[0..ORD_MP1 - 1] of float;             //* Autocorrelations of windowed signal  */
    A : array[0..ORD_MP1 - 1] of float;    //* A0(z) with bandwidth-expansion , not static  */
    alpha : float;
    buffer : array[0..L_WINDOW - 1] of float;      //* buffer for past decoded signal */
    rc : array[0..ORD_M - 1] of float;    //* A0(z) with bandwidth-expansion , not static  */
    i, norm, stable : short;
    enh_no : short;
    fac : float;
    sum_ma_dh_abs, dh_abs : float;

    mem_buf1 : array[0..L_FRAME_NB+ORD_M - 1] of float;
    mem_buf2 : array[0..L_FRAME_NB+ORD_M - 1] of float;
    memptr1, memptr2 : pfloat;
    n_cand : short;
    w16tmp : short;
begin
    movef (L_FRAME_NB, work.buffer, buffer);
    movesf(L_FRAME_NB, sigin^, buffer[L_FRAME_NB]);
    movef (L_FRAME_NB, buffer[L_FRAME_NB], work.buffer);

    //* LP analysis and filter weighting */
    norm := fl_AutocorrNS(pfloat(@buffer), pfloat(@r));
    fl_Levinson(pfloatA(@r), pfloatA(@rc), @stable, ORD_M, pfloatA(@A));

//#define NO_NS
//#ifdef NO_NS
//#pragma message("#####************* NO_NS HB !!!**********#####")
//  A[1] = A[2] = A[3] = A[4] = 0;
//#endif

    w16tmp := norm - MAX_NORM ;
    if (w16tmp>= 0) then
    begin
        w16tmp := w16tmp + 1;
        fac := 1.0 / (1 shl w16tmp);
        for i := 1 to ORD_M do
        begin
            A[i] := A[i] * fac;
            fac := fac * 0.5;
        end;
    end
    else
    begin
        alpha := -rc[0]; ;       //* rc[0] == -r[1]/r[0]   */
        if (alpha < -0.984375) then  //* r[1]/r[0] < -0.984375 */
        begin
            alpha := alpha + 1.75;    //* alpha=16*(r[1]/r[0]+1+0.75/16) */
            fl_Weight_a(pfloatA(@A), pfloatA(@A), FL_GAMMA1 * alpha, ORD_M);
        end
        else
            fl_Weight_a(pfloatA(@A), pfloatA(@A), FL_GAMMA1, ORD_M);
    end;

    //* Compute number of candidates */
    n_cand := (3-mode) shl 1; //*mode= 3 : 0; mode = 2 : 2*/
    movef(ORD_M, work.mem_el0, mem_buf1);
    memptr1 := @mem_buf1[3];

    enh_no := NBITS_MODE_R1SM_WBE;
    sum_ma_dh_abs := 0;
    movef(ORD_M, work.mem_t, mem_buf2);
    memptr2 := @mem_buf2[3];
    for i := 0 to L_FRAME_NB - 1 do
    begin
        (* Quantize the current sample
        Delete enhancement bits according to core_mode
        Extract candidates for enhancement *)
        dh_abs := fl_hsbcod_ldec_l0l1(sigin[i], g722_encoder,
            i, pBit_wbenh, @code0[i], @code1[i], pfloatA(@A),
            pfloatA(memptr1), pfloatA(memptr2), @enh_no, sum_ma_dh_abs, wbenh_flag, n_cand
        );
        inc(memptr1);
        inc(memptr2);
        sum_ma_dh_abs := sum_ma_dh_abs + dh_abs;
    end;
    movef(ORD_M, memptr2^, work.mem_t[ORD_MM1]);
    movef(ORD_M, memptr1^, work.mem_el0[ORD_MM1]);
end;

{$ENDIF FALSE }


// lsbcod_ns.c
//* ITU G.722 3rd Edition (2012-09) */

(*--------------------------------------------------------------------------
 ITU-T G.722 Annex C (ex G.722-SWB-Float) Source Code
 Software Release 1.01 (2012-07)
 (C) 2012 France Telecom, Huawei Technologies, VoiceAge Corp., NTT.
--------------------------------------------------------------------------*)

function lsbcod_ldec(xl : short; s : pg722_state; local_mode : short;
                   yl : pshort; detl : pshort; dl : pshort): short;
var
    el, il : short;
    mask : short;
begin
    mask := code_mask[local_mode];

    el := xl - s.sl;           //* subtra */
    il := quantl5b (el, s.detl);

    //* Generate candidates */
    il := il and mask;
    dl^ := ( DETL^ * pshortA(invqbl_tab[local_mode])[il shr invqbl_shift[local_mode]] ) shr 15;
    yl^ := s.sl + dl^;
    detl^ := DETL^;

    adpcm_adapt_l(il, @s.al, pshort(@s.bl), pshort(@s.dlt), pshort(@s.plt), pshort(@s.rlt), @s.nbl, @s.detl, @s.szl, @s.sl);

    //* Return encoded sample */
    exit (il);
end;

function  fl_noise_shaper(A : pfloatA; _in : float; mem : pfloat) : float;
var
    j : int;
    _out : float;
begin
    //* Calculation of the weighted error signal */
    _out := A[0] * _in;
    for j := 0 to ORD_M - 1 do
    begin
        dec(mem);
        _out := _out + A[j + 1] * mem^;
    end;

    _out := Floor(_out);
    exit(_out);
end;

function  fl_lsbcod_ns_core(
                      sigin : pshortA;               //* (i): Input 5-ms signal  */
                      A : pfloatA;                    //* (i): Noise shaping filter  */
                      adpcm_work : pg722_state;       //* (i/o): Pointer to G.722 work space  */
                      local_mode : short;             //* (i): G.722 core mode */
                      i : short;
                      sigdec_core : pshort;
                      detl : pshort;
                      dl : pshort;
                      memptr1 : ppfloat) : short;            //* (i): Noise shaping filter memory */
var
    idx : Short;
    tmp : Float;
begin
    //* Compute signal + noise feedback */
    tmp := fl_noise_shaper(A, sigin[i], memptr1^); //*target value, determinated using the noise shaping filter A*/
    inc(memptr1^);

    (* Quantize the current sample
    Delete enhancement bits according to local_mode
    Decode locally*)
    idx := lsbcod_ldec(Trunc(tmp), adpcm_work, local_mode, sigdec_core, detl, dl);

    //* Update the noise-shaping filter memory  */
    memptr1^^ := sigin[i]- sigdec_core^;  //* **memptr1 is also the target value for the enhancement stage*/

    exit(idx);
end;

procedure fl_lsbcod_buf_ns(
                   sigin : pshortA;             //* (i): Input 5-ms signal                   */
                   code0 : pshortA;             //* (o): G.722 core-layer bitstream (MUX'ed) */
                   adpcm_work : pg722_state;    //* (i/o): Pointer to G.722 work space  */
                   ns_work : pfl_noiseshaping_state;    //* (i/o): Pointer to NS work space */
                   mode : short;                    //* (i): G.722 mode */
                   local_mode : short);              //* (i): local decoding G.722 mode */
begin
    // remove me
end;

{$IFDEF FALSE }

procedure fl_lsbcod_buf_ns(
                   sigin : pshortA;             //* (i): Input 5-ms signal                   */
                   code0 : pshortA;             //* (o): G.722 core-layer bitstream (MUX'ed) */
                   adpcm_work : pg722_state;    //* (i/o): Pointer to G.722 work space  */
                   ns_work : pfl_noiseshaping_state;    //* (i/o): Pointer to NS work space */
                   mode : short;                    //* (i): G.722 mode */
                   local_mode : short);              //* (i): local decoding G.722 mode */
var
    r : array[0..ORD_MP1 - 1] of float;             //* Autocorrelations of windowed signal  */
    A : array[0..ORD_MP1 - 1] of float;    //* A0(z) with bandwidth-expansion , not static  */

    buffer : array[0..L_WINDOW - 1] of float;      //* buffer for past decoded signal */
    rc : array[0..ORD_M - 1] of float;    //* A0(z) with bandwidth-expansion , not static  */
    i, norm, stable : short;
    sigdec_core : short;
    idx, idx_enh : short;
    cand : array[0..2 - 1] of short;
    mem_buf1 : array[0..L_FRAME_NB+ORD_M - 1] of float;
    mem_buf2 : array[0..L_FRAME_NB+ORD_M - 1] of float;
    memptr1, memptr2 : pfloat;

    n_cand, detl, dl : short;
    tw, tmp       : float;
    err0, err1    : float;
    itmp, w16tmp  : short;
    fac           : float;
begin
    movef (L_FRAME_NB, ns_work.buffer, buffer);
    movesf(L_FRAME_NB, sigin^, buffer[L_FRAME_NB]);
    movef (L_FRAME_NB, buffer[L_FRAME_NB], ns_work.buffer);

    //* LP analysis and filter weighting */
    norm := fl_AutocorrNS(pfloat(@buffer), pfloat(@r));
    fl_Levinson(pfloatA(@r), pfloatA(@rc), @stable, ORD_M, pfloatA(@A));

{x $DEFINE NO_NS }
{$IFDEF NO_NS }
    //#pragma message("#####************* NO_NS LB !!!**********#####")
    //A[1] = A[2] = A[3] = A[4] = 0;
{$ENDIF NO_NS }

    itmp := norm-MAX_NORM;
    if (itmp >= 0) then
    begin
        fac := 1.0 / (1 shl (itmp+1));
        for i := 1 to ORD_M do
        begin
            A[i] := A[i] * fac;
            fac := fac * 0.5;
        end
    end
    else
    begin
        if (rc[1] > 0.95) then //* 0.95, detect sinusoids */
            ns_work.gamma := 0.0;

        fl_Weight_a(pfloatA(@A), pfloatA(@A), ns_work.gamma, ORD_M);
        ns_work.gamma := ns_work.gamma + FL_GAMMA1S4;
        if (ns_work.gamma > FL_GAMMA1) then
            ns_work.gamma := FL_GAMMA1;
    end;

{x $DEFINE LOAD_NS_FILTER }
{$IFDEF LOAD_NS_FILTER }
    //#pragma message("#####************* LOAD_NS_FILTER LB !!!**********#####")
    (*
      static FILE *fp=NULL;
      if(fp == NULL) {
          fp = fopen("c:\\temp\\save_ai_ns", "rb");
          printf("\n#####************* LOAD_NS_FILTER LB !!!**********#####\n");
      }
      fread(&A[1], sizeof(A[1]), 4, fp);
    *)
{$ENDIF LOAD_NS_FILTER }

    n_cand := 0;
    //* Compute number of candidates */
    itmp := local_mode-mode;
    if (itmp > 0) then
        n_cand := 1 shl itmp;

    movef(ORD_M, ns_work.mem_wfilter, mem_buf1);
    memptr1 := @mem_buf1[3];
    if (n_cand > 0) then //*n_cand = 2, mode = 1*/
    begin
        movef(ORD_M, ns_work.mem_t, mem_buf2);
        memptr2 := @mem_buf2[3];

        for i := 0 to L_FRAME_NB - 1 do
        begin
            idx := fl_lsbcod_ns_core(sigin, pfloatA(@A), adpcm_work, local_mode, i, @sigdec_core, @detl, @dl, @memptr1);
            code0[i] := idx;

            //*Extract candidates for enhancement */
            w16tmp := (detl * pshortA(invqbl_tab[mode])[idx shr invqbl_shift[mode]]) shr 15;
            cand[0] := w16tmp - dl;
            inc(idx);
            w16tmp :=  (detl * pshortA(invqbl_tab[mode])[idx shr invqbl_shift[mode]]) shr 15;
            cand[1] := w16tmp - dl;

            //* Encode enhancement */
            tw := fl_noise_shaper(pfloatA(@A), memptr1^, memptr2); //*target value, determinated using the noise shaping filter A*/
            inc(memptr2);

            tmp := tw - cand[0];
            err0 := tmp * tmp;
            tmp := tw - cand[1];
            err1 := tmp * tmp;
            idx_enh := 0;

            if (err1 < err0) then
                idx_enh := 1;

            memptr2^ := memptr1^ - cand[idx_enh];
            code0[i] := code0[i] + idx_enh;
        end;
        movef(ORD_M, memptr2^, ns_work.mem_t[ORD_MM1]);
    end
    else
    begin
        for i := 0 to L_FRAME_NB - 1 do
          code0[i] := fl_lsbcod_ns_core(sigin, pfloatA(@A), adpcm_work, local_mode, i, @sigdec_core, @detl, @dl, @memptr1);
    end;

    movef(ORD_M, memptr1^, ns_work.mem_wfilter[ORD_MM1]);
end;

{$ENDIF FALSE }

// end of lsbcod_ns.c


type
//* G.722 encoder state structure (only used for encoder) */
    pfl_g722enc_state = ^fl_g722enc_state;
    fl_g722enc_state = packed record
        g722work : g722_state;
        nswork : fl_noiseshaping_state;
        nswork_enh : fl_noiseshaping_state;
    end;

function fl_g722_encode_const() : p_enc;
begin
    result := malloc(sizeof(fl_g722enc_state));
    if (nil <> result) then
        fl_g722_encode_reset(result);
end;

//Floating_ver.
procedure fl_g722_encode_dest(e : p_enc);
begin
    if (nil <> e) then
        mrealloc(e);
end;

//* void g722_reset_encoder_ns(g722_state *encoder, noise_shaping_state* work) */
procedure fl_g722_encode_reset(e : p_enc);
var
    work   : pfl_g722enc_state absolute e;
    w16ptr : pshort;
    fl_ptr : pfloat;
begin
    if (nil <> work) then
    begin
        w16ptr := pshort(@work.g722work);
        fillChar(w16ptr^, sizeof(g722_state), #0);
        fl_ptr := pfloat(@work.nswork);
        fillChar(fl_ptr^, sizeof(fl_noiseshaping_state), #0);   //*210 : size of g722enc_state structure in Short (420 bytes)*/
        fl_ptr := pfloat(@work.nswork_enh);
        fillChar(fl_ptr^, sizeof(fl_noiseshaping_state), #0);   //*210 : size of g722enc_state structure in Short (420 bytes)*/
        work.g722work.detl := 32;
        work.g722work.deth := 8;
        work.nswork.gamma := FL_GAMMA1;
        work.nswork_enh.gamma := FL_GAMMA1;
    end;
end;
//* .................... end of g722_reset_encoder() ....................... */


{void g722_encode(Short mode, Short local_mode, const Short *sig, unsigned char *code,
                 unsigned char *code_enh, Short mode_enh, /* mode_enh = 1 -> high-band enhancement layer */
                 void *ptr, Short wbenh_flag, unsigned short **pBit_wbenh
                 )}
procedure g722_encode(mode : short; local_mode : short; const sig : p_pcm; code : p_data;
                 code_enh : pByte; mode_enh : short; //* mode_enh = 1 -> high-band enhancement layer */
                 e : p_enc; wbenh_flag : short; pBit_wbenh : pp_wbenh);
var
    work : pfl_g722enc_state absolute e;
    //* Encoder variables */
    //* Auxiliary variables */
    i : int;
    ih_enh : array[0..L_FRAME_NB-1] of short;
    ptr_enh : pshort;
    j : short;
    icore,
    xh,
    xl : array[0..L_FRAME_NB - 1] of short;
    filtmem : array[0..L_FRAME_WB + 22 - 1] of short;
    filtptr : pshort;
begin
    filtptr := @filtmem[L_FRAME_WB];
    moves(22, work.g722work.qmf_tx_delayx[2], filtptr^); //* load memory */

    //* Main loop - never reset */
    for i := 0 to L_FRAME_NB - 1 do
    begin
        //* Calculation of the synthesis QMF samples */
        fl_qmf_tx_buf(ppshort(@sig), @xl[i], @xh[i], ppshort(@filtptr));
    end;
    moves(22, filtmem, work.g722work.qmf_tx_delayx[2]); //*save memory*/

    //* lower band ADPCM encoding */
    fl_lsbcod_buf_ns(pshortA(@xl), pshortA(@icore), @work.g722work, @work.nswork, mode, local_mode);

    //* higher band ADPCM encoding */
    fl_hsbcod_buf_ns(pshortA(@xh), pshortA(@icore), pshortA(@ih_enh), @work.g722work, @work.nswork_enh, mode_enh, wbenh_flag, pBit_wbenh);


    (* Mount the output G722 codeword: bits 0 to 5 are the lower-band
      * portion of the encoding, and bits 6 and 7 are the upper-band
      * portion of the encoding *)
    for i := 0 to L_FRAME_NB - 1 do
        code[i] := (icore[i] and $FF);

    if ((mode_enh - 2) = 0) then
    begin
        //* set bytes in the enhancement layer (1 bits/sample -> frame length/8 bytes*/
        ptr_enh^ := ih_enh[0];

        for i := 0  to L_FRAME_NB shr 3 - 1 do
        begin
            //* initialize to zero */
            code_enh[i] := 0;

            //* multiplex */
            j := 0;
            while (j < 8) do
            begin
                code_enh[i] := code_enh[i] + (ptr_enh^ shl j);
                inc(ptr_enh);
                j := j + (3 - mode_enh);
            end;
        end;
    end;
end;
//* .................... end of g722_encode() .......................... */



// g722_plc_tables.c
//* ITU G.722 3rd Edition (2012-09) */

(*--------------------------------------------------------------------------
 ITU-T G.722 Annex C (ex G.722-SWB-Float) Source Code
 Software Release 1.01 (2012-07)
 (C) 2012 France Telecom, Huawei Technologies, VoiceAge Corp., NTT.
--------------------------------------------------------------------------*)

//#include "g722_plc.h"

(**************
* PLC TABLES *
**************)

(*-----------------------------------------------------*
| Table of lag_window for autocorrelation.            |
| noise floor = 1.0001   = (0.9999  on r[1] ..r[10])  |
| Bandwidth expansion = 60 Hz                         |
|                                                     |
| Special double precision format. See "oper_32b.c"   |
|                                                     |
| lag_wind[0] =  1.00000000    (not stored)           |
| lag_wind[1] =  0.99879038                           |
| lag_wind[2] =  0.99546897                           |
| lag_wind[3] =  0.98995781                           |
| lag_wind[4] =  0.98229337                           |
| lag_wind[5] =  0.97252619                           |
| lag_wind[6] =  0.96072036                           |
| lag_wind[7] =  0.94695264                           |
| lag_wind[8] =  0.93131179                           |
|                                                     |
| exp(-2*(pi*60*k/8000).^2)/1.0001                    |
-----------------------------------------------------*)
const
    G722PLC_lag_h : array [0..ORD_LPC - 1] of short = (
        32728,
        32619,
        32438,
        32187,
        31867,
        31480,
        31029,
        30517
    );

    G722PLC_lag_l : array [0..ORD_LPC - 1] of short = (
        11904,
        17280,
        30720,
        25856,
        24192,
        28992,
        24384,
        7360
    );

(* LPC analysis windows
l1 = 70;
l2 = 10;
for i = 1 : l1
n = i - 1;
w1(i) = 0.54 - 0.46 * cos(n * pi / (l1 - 1));
end
for i = (l1 + 1) : (l1 + l2)
w1(i) = 0.54 + 0.46 * cos((i - l1) * pi / (l2));
end
round_fx(w1*32767)
*)
    G722PLC_lpc_win_80 : array[0..80 - 1] of short = (
        2621,  2637,  2684,  2762,  2871,
        3010,  3180,  3380,  3610,  3869,
        4157,  4473,  4816,  5185,  5581,
        6002,  6447,  6915,  7406,  7918,
        8451,  9002,  9571, 10158, 10760,
        11376, 12005, 12647, 13298, 13959,
        14628, 15302, 15982, 16666, 17351,
        18037, 18723, 19406, 20086, 20761,
        21429, 22090, 22742, 23383, 24012,
        24629, 25231, 25817, 26386, 26938,
        27470, 27982, 28473, 28941, 29386,
        29807, 30203, 30573, 30916, 31231,
        31519, 31778, 32008, 32208, 32378,
        32518, 32627, 32705, 32751, 32767,
        32029, 29888, 26554, 22352, 17694,
        13036,  8835,  5500,  3359,  2621
    );

(* FIR decimation filter coefficients
8th order FIRLS 8000 400 900 3 19 *)
    G722PLC_fir_lp : array[0..FEC_L_FIR_FILTER_LTP - 1] of short = (
        3692,   6190, 8525, 10186,
        10787, 10186, 8525,  6190, 3692
    );

(* High-pass filter coefficients
y[i] =      x[i]   -         x[i-1]
+ 123/128*y[i-1]  *)

//*HP 100 Hz*/
    G722PLC_b_hp156 : array[0..2 - 1] of short = (31456, -31456); //*0.96, -0.96*/
    G722PLC_a_hp156 : array[0..2 - 1] of short = (32767,  28835); //*1, 0.88*/

//*HP 50 Hz*/
    G722PLC_b_hp : array[0..2 - 1] of short = (32767, -32767); //*1, -1*/
    G722PLC_a_hp : array[0..2 - 1] of short = (32767,  31488); //*1, 0.96*/

    G722PLC_gamma_az : array[0..9 - 1] of short = (32767, GAMMA_AZ1, GAMMA_AZ2, GAMMA_AZ3, GAMMA_AZ4,
                                    GAMMA_AZ5, GAMMA_AZ6, GAMMA_AZ7, GAMMA_AZ8); //*1, 0.99*/

    f_G722PLC_lag : array[0..ORD_LPC - 1] of float = (
        0.99879041, 0.99546898, 0.98995779, 0.98229336,
        0.97252621, 0.96072037, 0.94695265, 0.93131180
    );

    f_G722PLC_lpc_win_80 : array[0..80 - 1] of float = (
        0.08000000, 0.08047671, 0.08190585, 0.08428446,
        0.08760762, 0.09186842, 0.09705805, 0.10316574,
        0.11017883, 0.11808280, 0.12686126, 0.13649600,
        0.14696707, 0.15825277, 0.17032969, 0.18317281,
        0.19675550, 0.21104963, 0.22602555, 0.24165224,
        0.25789729, 0.27472705, 0.29210663, 0.31000000,
        0.32837008, 0.34717880, 0.36638717, 0.38595538,
        0.40584287, 0.42600842, 0.44641023, 0.46700603,
        0.48775311, 0.50860849, 0.52952893, 0.55047107,
        0.57139151, 0.59224689, 0.61299397, 0.63358977,
        0.65399158, 0.67415713, 0.69404462, 0.71361283,
        0.73282120, 0.75162992, 0.77000000, 0.78789337,
        0.80527295, 0.82210271, 0.83834776, 0.85397445,
        0.86895037, 0.88324450, 0.89682719, 0.90967031,
        0.92174723, 0.93303293, 0.94350400, 0.95313874,
        0.96191720, 0.96982117, 0.97683426, 0.98294195,
        0.98813158, 0.99239238, 0.99571554, 0.99809415,
        0.99952329, 1.00000000, 0.97748600, 0.91214782,
        0.81038122, 0.68214782, 0.54000000, 0.39785218,
        0.26961878, 0.16785218, 0.10251400, 0.08000000
    );

    f_G722PLC_fir_lp : array[0..FEC_L_FIR_FILTER_LTP - 1] of float = (
        0.05634018476418,   0.09445500104261,   0.13008546921365,
        0.15542763269087,   0.16460243764646,   0.15542763269087,
        0.13008546921365,   0.09445500104261,   0.05634018476418
    );

    f_G722PLC_b_hp156 : array[0..2 - 1] of float = (0.96, - 0.96);
    f_G722PLC_a_hp156 : array[0..2 - 1] of float = (1, 0.88);

    f_G722PLC_b_hp : array[0..2 - 1] of float = (1, -1);
    f_G722PLC_a_hp : array[0..2 - 1] of float = (1, 0.96);

    f_G722PLC_gamma_az : array[0..9 - 1] of float = (1, 0.99, 0.9801, 0.9703, 0.9606,
                                    0.951, 0.9415, 0.9321, 0.9227);

// end of g722_plc_tables.c


// g722_plc.c
//* ITU G.722 3rd Edition (2012-09) */

(*--------------------------------------------------------------------------
 ITU-T G.722 Annex C (ex G.722-SWB-Float) Source Code
 Software Release 1.01 (2012-07)
 (C) 2012 France Telecom, Huawei Technologies, VoiceAge Corp., NTT.
--------------------------------------------------------------------------*)

(**********************************
* declaration of PLC subroutines *
**********************************)

{$IFDEF FALSE }

procedure G722PLC_ana_flt(plc_state : pG722PLC_STATE_FLT; decoder : pg722_state); forward;
function G722PLC_syn_hb_flt(plc_state : pG722PLC_STATE_FLT) : pfloat; forward;
procedure G722PLC_syn_flt(plc_state : pG722PLC_STATE_FLT; syn : pfloat; NumSamples : short); forward;
procedure G722PLC_attenuate_lin_flt(plc_state : pG722PLC_STATE_FLT; fact : float; cur_sig, tabout : pfloat;
                                    NumSamples : short; ind : pshort; weight : pfloat); forward;
procedure G722PLC_attenuate_flt(plc_state : pG722PLC_STATE_FLT; cur_sig, tabout : pfloat;
                                    NumSamples : short; ind : pshort; weight : pfloat); forward;
procedure G722PLC_qmf_updstat_flt (outcode : pshort; decoder : pg722_state;
                                   lb_signal : pfloat; hb_signal : pfloat; plc_state : pointer); forward;

{$ENDIF FALSE }

//* lower-band analysis (main subroutine: G722PLC_ana) */
(*
static Short  G722PLC_pitch_ol_flt(Float * signal, Float *maxco);
static Short  G722PLC_classif_modif_flt(Float maxco, Short nbl, Short nbh, Float* mem_speech, int l_mem_speech,
                                     Float* mem_exc, Short* t0
                                     );
static void    G722PLC_autocorr_flt(Float * x, Float * R, Short ord, Short len);
static void    G722PLC_lpc_flt(G722PLC_STATE_FLT * plc_state, Float * mem_speech); /* interface modified for ONLY_LTP_DC_REMOVE */
static void    G722PLC_residu_flt(G722PLC_STATE_FLT * plc_state);


/* lower-band synthesis (main subroutine: G722PLC_syn) */
static Float  G722PLC_ltp_pred_1s_flt(Float* exc, Short t0, Short *jitter);
static void    G722PLC_ltp_syn_flt(G722PLC_STATE_FLT* plc_state, Float* cur_exc, Float* cur_syn, Short n, Short *jitter);
static void    G722PLC_syn_filt_flt(Short m, Float* a, Float* x, Float* y, Short n);
static void    G722PLC_calc_weight_flt(Short *ind_weight, Float fact1, Float fact2p, Float fact3p, Float * weight);
static void    G722PLC_update_mem_exc_flt(G722PLC_STATE_FLT * plc_state, Float * cur_sig, Short NumSamples);


/* higher-band synthesis */
*)

//*================should be moved to lpctool.c===========================*/

(*----------------------------------------------------------*
* Function Lag_window_flt()                                    *
*                                                          *
* r[i] *= lag_wind[i]                                      *
*                                                          *
*    r[i] and lag_wind[i] are in special double precision. *
*    See "oper_32b.c" for the format                       *
*                                                          *
*----------------------------------------------------------*)
(*
void Lag_window_flt(
                Float * R,
                const Float * W,
                int ord
                )
{
  int  i;

  for (i = 1; i <= ord; i++)
  {
    R[i] *= W[i - 1];
  }
  return;
}
*)

(*
void Levinson_flt(
              Float R[],     /* (i)     : R[M+1] Vector of autocorrelations  */
              Float rc[],      /* (o)   : rc[M]   Reflection coefficients.         */
              Short *stable,  /* (o)    : Stability flag                           */
              Short ord,       /* (i)   : LPC order                                */
              Float * a        /* (o)   : LPC coefficients                         */
              )
{
  Float  err, s, at ;                     /* temporary variable */
  int   i, j, l;

  *stable = 0;

  /* K = A[1] = -R[1] / R[0] */
  rc[0] = (-R[1]) / R[0];
  a[0] = 1;
  a[1] = rc[0];
  err = R[0] + R[1] * rc[0];

  /*-------------------------------------- */
  /* ITERATIONS  I=2 to lpc_order          */
  /*-------------------------------------- */
  for (i = 2; i <= ord; i++) {
	  s = 0;
	  for (j = 0; j < i; j++) {
		  s += R[i - j] * a[j];
	  }
	  rc[i - 1] = -s/err;
	  /* Test for unstable filter. If unstable keep old A(z) */
	  if(fabs(rc[i-1])> 0.99) {
		  *stable = 1;
		  return;
	  }

	  for (j = 1; j <= (i / 2); j++) {
		  l = i - j;
		  at = a[j] + rc[i - 1] * a[l];
		  a[l] += rc[i - 1] * a[j];
		  a[j] = at;
	  }
	  a[i] = rc[i - 1];
	  err += rc[i - 1] * s;
	  if (err <=  0) {
		  err = 0.001f;
	  }
  }
  return;
}
*)

//*================should be moved to lpctool.c END===========================*/
procedure set_att_flt(plc_state : pG722PLC_STATE_FLT; inc_att_v : short; fact1_v, fact2p_v, fact3p_v : float);
begin
    plc_state.s_inc_att := inc_att_v;
    plc_state.f_fact1 := fact1_v;
    plc_state.f_fact2p := fact2p_v;
    plc_state.f_fact3p := fact3p_v;
end;


(***********************************
* definition of main PLC routines *
***********************************)

(*----------------------------------------------------------------------
* G722PLC_init(l_frame)
* allocate memory and return PLC state variables
*
* l_frame (i) : frame length @ 8kHz
*---------------------------------------------------------------------- *)

function G722PLC_init_flt() : pointer;
var
    plc_state : pG722PLC_STATE_FLT;
begin
    //* allocate memory for PLC plc_state */
    plc_state := malloc(sizeof(G722PLC_STATE_FLT));
    if (nil = plc_state) then
        exit(nil);

    //* LPC, pitch, signal classification parameters */
    plc_state.f_a := pfloatA(mallocf(ORD_LPC + 1));
    plc_state.f_mem_syn := mallocf(ORD_LPC);

    zerof(ORD_LPC, plc_state.f_mem_syn^);
    zerof(ORD_LPCP1, plc_state.f_a^);
    plc_state.s_clas := G722PLC_WEAKLY_VOICED;

    //* signal buffers */
    plc_state.f_mem_speech := pfloatA(mallocf(MEMSPEECH_LEN));
    plc_state.f_mem_speech_hb := pfloatA(mallocf(LEN_HB_MEM)); //*MAXPIT is needed, for complexity reason; LEN_HB_MEM: framelength 20ms*/
    plc_state.f_mem_exc := mallocf(MAXPIT2P1);

    zerof(MEMSPEECH_LEN, plc_state.f_mem_speech^);
    zerof(LEN_HB_MEM, plc_state.f_mem_speech_hb^);
    zerof(MAXPIT2P1, plc_state.f_mem_exc^);

    //* cross-fading */
    plc_state.s_count_crossfade := CROSSFADELEN;

    //* higher-band hig-pass filtering */
    //* adaptive muting */
    plc_state.f_weight_lb := 1;
    plc_state.f_weight_hb := 1;
    plc_state.s_inc_att := 1;
    plc_state.f_fact1 := F_FACT1_V;
    plc_state.f_fact2p := F_FACT2P_V;
    plc_state.f_fact3p := F_FACT3P_V;

    plc_state.f_mem_hpf_in := 0;
    plc_state.f_mem_hpf_out := 0;
    zerof(CROSSFADELEN, plc_state.f_crossfade_buf);
    plc_state.s_count_att := 0;
    plc_state.s_count_att_hb := 0;
    plc_state.s_t0 := 0;
    plc_state.s_t0p2 := 0;
    plc_state.s_prev_bfi := 0;

    exit(plc_state);
end;

procedure G722PLC_conceal_flt(state : pointer; outcode : pshort; decoder : pg722_state);
begin
    // remove me
end;

{$IFDEF FALSE }

(*----------------------------------------------------------------------
* G722PLC_conceal_flt(plc_state, xl, xh, outcode, decoder)
* extrapolation of missing frame
*
* plc_state (i/o) : state variables of PLC
* xl  (o) : decoded lower-band
* xh  (o) : decoder higher-band
* outcode (o) : decoded synthesis
* decoder (i/o) : g722 states (QMF, ADPCM)
*---------------------------------------------------------------------- *)
procedure G722PLC_conceal_flt(state : pointer; outcode : pshort; decoder : pg722_state);
var
    plc_state : pG722PLC_STATE_FLT absolute state;
    i : int;
    xl, xh : pfloat;
    Temp : float;
begin
    (***********************
    * reset counter *
    ***********************)

    plc_state.s_count_crossfade := 0;  //* reset counter for cross-fading */

    (***********************
    * generate lower band *
    ***********************)

    (* check if first missing frame (i.e. if previous frame received)
    first missing frame -> analyze past buffer + PLC
    otherwise -> PLC
    *)
    xl := @plc_state.f_mem_speech[257]; //*257 : MEMSPEECH_LEN, L_FRAME_NB*/
    if (0 = plc_state.s_prev_bfi) then
    begin
        plc_state.s_count_att := 0;   //* reset counter for attenuation in lower band */
        plc_state.s_count_att_hb := 0;  //* reset counter for attenuation in higher band */
        plc_state.f_weight_lb := 1;
        plc_state.f_weight_hb := 1;

        (**********************************
        * analyze buffer of past samples *
        * - LPC analysis
        * - pitch estimation
        * - signal classification
        **********************************)

        G722PLC_ana_flt(plc_state, decoder);

        (******************************
        * synthesize missing samples *
        ******************************)

        //* set increment for attenuation */
        if (G722PLC_VUV_TRANSITION = plc_state.s_clas) then
        begin
            //* attenuation in 30 ms */
            set_att_flt(plc_state, 2, F_FACT1_UV, F_FACT2P_UV, F_FACT3P_UV);
            Temp := F_FACT3_UV;
        end
        else
        begin
            set_att_flt(plc_state, 1, F_FACT1_V, F_FACT2P_V, F_FACT3P_V);
            Temp := F_FACT2_V;
        end;

        if (G722PLC_TRANSIENT = plc_state.s_clas) then
        begin
            //* attenuation in 10 ms */
            set_att_flt(plc_state, 6, F_FACT1_V_R, F_FACT2P_V_R, F_FACT3P_V_R);
            Temp := 0;
        end;

        //* synthesize lost frame, high band */
        xh := G722PLC_syn_hb_flt(plc_state);

        //*shift low band*/
        movef(257, plc_state.f_mem_speech[L_FRAME_NB], plc_state.f_mem_speech^); //*shift low band*/

        //* synthesize lost frame, low band directly to plc_state->mem_speech*/
        G722PLC_syn_flt(plc_state, xl, L_FRAME_NB);
        for i := 1 to 8 do
            plc_state.f_a[i] := plc_state.f_a[i] * f_G722PLC_gamma_az[i];

        //* synthesize cross-fade buffer (part of future frame)*/
        G722PLC_syn_flt(plc_state, pfloat(@plc_state.f_crossfade_buf), CROSSFADELEN);

        //* attenuate outputs */
        G722PLC_attenuate_lin_flt(plc_state, plc_state.f_fact1, xl, xl, L_FRAME_NB, @plc_state.s_count_att, @plc_state.f_weight_lb);
        if (G722PLC_TRANSIENT = plc_state.s_clas) then
            plc_state.f_weight_lb := 0;

        //*5 ms frame, xfadebuff in 2 parts*/
        G722PLC_attenuate_lin_flt(plc_state, plc_state.f_fact1, pfloat(@plc_state.f_crossfade_buf), pfloat(@plc_state.f_crossfade_buf), CROSSFADELEN div 2, @plc_state.s_count_att, @plc_state.f_weight_lb);
        G722PLC_attenuate_lin_flt(plc_state, Temp, pfloat(@plc_state.f_crossfade_buf[L_FRAME_NB]), pfloat(@plc_state.f_crossfade_buf[L_FRAME_NB]), CROSSFADELEN div 2, @plc_state.s_count_att, @plc_state.f_weight_lb);
        G722PLC_attenuate_lin_flt(plc_state, plc_state.f_fact1, xh, xh, L_FRAME_NB, @plc_state.s_count_att_hb, @plc_state.f_weight_hb);
    end
    else
    begin
        movef(257, &plc_state.f_mem_speech[L_FRAME_NB], plc_state.f_mem_speech^); //*shift*/
        //* copy samples from cross-fading buffer (already generated in previous bad frame decoding)  */

        movef(L_FRAME_NB, plc_state.f_crossfade_buf, xl^);
        movef(L_FRAME_NB, plc_state.f_crossfade_buf[L_FRAME_NB], plc_state.f_crossfade_buf); //*shift*/

        //* synthesize 2nd part of cross-fade buffer (part of future frame) and attenuate output */
        G722PLC_syn_flt(plc_state, pfloat(@plc_state.f_crossfade_buf[L_FRAME_NB]), L_FRAME_NB);
        G722PLC_attenuate_flt(plc_state, pfloat(@plc_state.f_crossfade_buf[L_FRAME_NB]), pfloat(@plc_state.f_crossfade_buf[L_FRAME_NB]), L_FRAME_NB, @plc_state.s_count_att, @plc_state.f_weight_lb);
        xh := G722PLC_syn_hb_flt(plc_state);
        G722PLC_attenuate_flt(plc_state, xh, xh, L_FRAME_NB, @plc_state.s_count_att_hb, @plc_state.f_weight_hb);
    end;

    (*****************************************
    * QMF synthesis filter and plc_state update *
    *****************************************)

    G722PLC_qmf_updstat_flt(outcode, decoder, xl, xh, plc_state);
end;

{$ENDIF FALSE }


(*----------------------------------------------------------------------
* G722PLC_clear(plc_state)
* free memory and clear PLC plc_state variables
*
* plc_state (i) : PLC state variables
*---------------------------------------------------------------------- *)
procedure G722PLC_clear_flt(state : pointer);
var
    plc_state : pG722PLC_STATE_FLT absolute state;
begin
    mrealloc(plc_state.f_mem_speech);
    mrealloc(plc_state.f_mem_speech_hb);
    mrealloc(plc_state.f_mem_exc);
    mrealloc(plc_state.f_a);
    mrealloc(plc_state.f_mem_syn);
    mrealloc(plc_state);
end;


(*********************************
* definition of PLC subroutines *
*********************************)

(*----------------------------------------------------------------------
* G722PLC_hp_flt(x1, y1_lo, y2_hi, signal)
*  high-pass filter
*
* x1          (i/o) : filter memory
* y1_hi,y1_lo (i/o) : filter memory
* signal     (i)   : input sample
*----------------------------------------------------------------------*)
function  G722PLC_hp_flt(x1 : pfloat; y1 : pfloat; signal : float;
                        b_hp : pfloatA; a_hp : pfloatA) : float;
var
    ACC0 : float;
begin
    //*  y[i] =      x[i]   -         x[i-1]    */
    //*                     + 123/128*y[i-1]    */
    ACC0 := signal * b_hp[0] + x1^ * b_hp[1] + y1^ * a_hp[1];
    x1^ := signal;
    y1^ := ACC0;

    exit(ACC0);
end;



(*----------------------------------------------------------------------
* G722PLC_syn_hb_flt(plc_state, xh, n)
* reconstruct higher-band by pitch prediction
*
* plc_state (i/o) : plc_state variables of PLC
*---------------------------------------------------------------------- *)
(*
static Float* G722PLC_syn_hb_flt(G722PLC_STATE_FLT* plc_state)
{
  Float *ptr;
  Float *ptr2;
  Short loc_t0;
  Short   tmp;

  /* save pitch delay */
  loc_t0 = plc_state->s_t0;

  /* if signal is not voiced, cut harmonic structure by forcing a 10 ms pitch */
  if(plc_state->s_clas != G722PLC_VOICED) /*constant G722PLC_VOICED = 0*/
  {
    loc_t0 = 80;
  }

  if(plc_state->s_clas == G722PLC_UNVOICED)/*G722PLC_UNVOICED*/
  {
    Float mean;
    Short tmp1, i;

    mean = 0;

    tmp1 = LEN_HB_MEM - 80; /* tmp1 = start index of last 10 ms, last periode is smoothed */
    for(i = 0; i < 80; i++)
    {
      mean += (Float)fabs(plc_state->f_mem_speech_hb[tmp1 + i]);
    }
    mean /= 32;  /*80/32 = 2.5 mean amplitude*/

    tmp1 = LEN_HB_MEM - loc_t0; /* tmp1 = start index of last periode that is smoothed */
    for(i = 0; i < loc_t0; i++)
    {
      if(fabs(plc_state->f_mem_speech_hb[tmp1 + i]) > mean)
      {
        plc_state->f_mem_speech_hb[tmp1 + i] /= 4;
      }
    }
  }

  /* reconstruct higher band signal by pitch prediction */
  tmp = L_FRAME_NB - loc_t0;
  ptr = plc_state->f_mem_speech_hb + LEN_HB_MEM - loc_t0; /*beginning of copy zone*/
  ptr2 = plc_state->f_mem_speech_hb + LEN_HB_MEM_MLF; /*beginning of last frame in mem_speech_hb*/
  if(tmp <= 0) /* l_frame <= t0*/
  {
    /* temporary save of new frame in plc_state->mem_speech[0 ...L_FRAME_NB-1] of low_band!! that will be shifted after*/
    movF(L_FRAME_NB, ptr, plc_state->f_mem_speech);
    movF(LEN_HB_MEM_MLF, &plc_state->f_mem_speech_hb[L_FRAME_NB], plc_state->f_mem_speech_hb); /*shift 1 frame*/

    movF(L_FRAME_NB, plc_state->f_mem_speech, ptr2);
  }
  else /*t0 < L_FRAME_NB*/
  {
    movF(LEN_HB_MEM_MLF, &plc_state->f_mem_speech_hb[L_FRAME_NB], plc_state->f_mem_speech_hb); /*shift memory*/

    movF(loc_t0, ptr, ptr2); /*copy last period*/
    movF(tmp, ptr2, &ptr2[loc_t0]); /*repeate last period*/
  }
  return(ptr2);
}
*)


(*-------------------------------------------------------------------------*
* G722PLC_attenuate_flt(state, in, out, n, count, weight)
* linear muting with adaptive slope
*
* state (i/o) : PLC state variables
* in    (i)   : input signal
* out (o)   : output signal = attenuated input signal
* n   (i)   : number of samples
* count (i/o) : counter
* weight (i/o): muting factor
*--------------------------------------------------------------------------*)
(*
static void G722PLC_attenuate_flt(G722PLC_STATE_FLT* plc_state, Float* in, Float* out, Short n, Short *count, Float * weight)
{
  Short i;

  for (i = 0; i < n; i++)
  {
    /* calculate attenuation factor and multiply */
    G722PLC_calc_weight_flt(count, plc_state->f_fact1, plc_state->f_fact2p, plc_state->f_fact3p, weight);
    out[i] = *weight * in[i];

    *count += plc_state->s_inc_att;
  }
  return;
}
*)

(*-------------------------------------------------------------------------*
* G722PLC_attenuate_lin_flt(plc_state, fact, in, out, n, count, weight)
* linear muting with fixed slope
*
* plc_state (i/o) : PLC state variables
* fact  (i/o) : muting parameter
* in    (i)   : input signal
* out (o)   : output signal = attenuated input signal
* n   (i)   : number of samples
* count (i/o) : counter
* weight (i/o): muting factor
*--------------------------------------------------------------------------*)
(*
static void G722PLC_attenuate_lin_flt(G722PLC_STATE_FLT* plc_state, Float fact, Float* in, Float* out, Short n, Short *count, Float * weight)
{
  Short i;

  for (i = 0; i < n; i++) /*adaptation 5ms*/
  {
    /* calculate attenuation factor and multiply */
    *weight = *weight - fact;
    out[i] = *weight * in[i];
  }
  *count += plc_state->s_inc_att * n; /*adaptation 5ms*/

  return;
}
*)


(*-------------------------------------------------------------------------*
* G722PLC_calc_weight_flt(ind_weight, Ind1, Ind12, Ind123, Rlim1, Rlim2, fact1, fact2, fact3,
*                     tab_len, WeightEnerSynthMem)
* calculate attenuation factor
*--------------------------------------------------------------------------*)
(*
static void G722PLC_calc_weight_flt(Short *ind_weight, Float fact1, Float fact2p, Float fact3p, Float * weight)
{

  *weight -= fact1;
  if (*ind_weight >= END_1ST_PART)
  {
    *weight = *weight - fact2p;
  }
  if (*ind_weight >= END_2ND_PART)
  {
    *weight = *weight - fact3p;
  }
  if (*ind_weight >= END_3RD_PART)
  {
    *weight = 0;
  }
  if(*weight <= 0)
  {
    *ind_weight = END_3RD_PART;
  }
  return;
}
*)


(*-------------------------------------------------------------------------*
* Function G722PLC_update_mem_exc_flt                                          *
* Update of plc_state->mem_exc and shifts the memory                           *
* if plc_state->t0 > L_FRAME_NB                                            *
*--------------------------------------------------------------------------*)
(*
static void G722PLC_update_mem_exc_flt(G722PLC_STATE_FLT * plc_state, Float * exc, Short n)
{
  Float *ptr;
  Short temp;

  /* shift ResMem, if t0 > l_frame */
  temp = plc_state->s_t0p2 - n;

  ptr = plc_state->f_mem_exc + MAXPIT2P1 - plc_state->s_t0p2;
  if (temp > 0)
  {
    movF(temp, &ptr[n], ptr);
    movF(n, exc, &ptr[temp]);
  }
  else
  {
    /* copy last "pitch cycle" of residual */
    movF(plc_state->s_t0p2, &exc[n - plc_state->s_t0p2], ptr);
  }
  return;
}
*)


(*-------------------------------------------------------------------------*
* Function G722PLC_ana_flt(plc_state, decoder)                   *
* Main analysis routine
*
* plc_state   (i/o) : PLC state variables
* decoder (i)   : G.722 decoder state variables
*-------------------------------------------------------------------------*)
(*
static void G722PLC_ana_flt(G722PLC_STATE_FLT * plc_state, g722_state *decoder)
{
  Float maxco;
  Float nooffsig[MEMSPEECH_LEN];
  int i;

  Float x1, y1;

  /* DC-remove filter */
  x1 = y1 = 0;

  /* DC-remove filter */
  for(i = 0; i < MEMSPEECH_LEN; i++)
  {
    nooffsig[i] = G722PLC_hp_flt(&x1, &y1, plc_state->f_mem_speech[i],
      f_G722PLC_b_hp, f_G722PLC_a_hp);
  }

  /* perform LPC analysis and compute residual signal */
  G722PLC_lpc_flt(plc_state, nooffsig);
  G722PLC_residu_flt(plc_state);
  /* estimate (open-loop) pitch */
  /* attention, may shift noofsig, but only used after for zero crossing rate not influenced by this shift (except for very small values)*/
  plc_state->s_t0 = G722PLC_pitch_ol_flt(nooffsig + MEMSPEECH_LEN - MAXPIT2, &maxco);

  /* update memory for LPC
  during ereased period the plc_state->mem_syn contains the non weighted
  synthetised speech memory. For thefirst erased frame, it
  should contain the output speech.
  Saves the last ORD_LPC samples of the output signal in
  plc_state->mem_syn    */
  movF(ORD_LPC, &plc_state->f_mem_speech[MEMSPEECH_LEN - ORD_LPC],
    plc_state->f_mem_syn);

  /* determine signal classification and modify residual in case of transient */
  plc_state->s_clas = G722PLC_classif_modif_flt(maxco, decoder->nbl, decoder->nbh, nooffsig, MEMSPEECH_LEN,
    plc_state->f_mem_exc, &plc_state->s_t0);

  plc_state->s_t0p2 = plc_state->s_t0 + 2;

  return;
}
*)


(*-------------------------------------------------------------------------*
* Function G722PLC_autocorr_flt*
*--------------------------------------------------------------------------*)
(*
void G722PLC_autocorr_flt(Float x[],  /* (i)    : Input signal                      */
                      Float r[],/* (o)    : Autocorrelations  (msb)           */
                      Short ord,    /* (i)    : LPC order                         */
                      Short len /* (i)    : length of analysis                   */
                      )
{
  Float sum;
  Float *y = (Float * )calloc(len, sizeof(Float));
  int i, j;

  /* Windowing of signal */
  for(i = 0; i < len; i++)
  {
    y[i] = x[i] * f_G722PLC_lpc_win_80[HAMWINDLEN-len+i]; /* for length < 80, uses the end of the window */
  }
  /* Compute r[0] and test for overflow */

  for (i = 0; i <= ord; i++) {
    sum = 0;
    for (j = 0; j < len - i; j++) {
      sum += y[j] * y[j + i];
    }
    r[i] = sum;
  }
  free(y);

  return;
}
*)

(*
static void G722PLC_pitch_ol_refine_flt(Float * nooffsigptr, int il, Float ener1_f,
                                    int beg_last_per, int end_last_per,
                                    int *ind, Float *maxco)
{
  int i, j;
  Float corx_f, ener2_f;
  int start_ind, end_ind;
  Float em;

  start_ind = il - 2;
  if (start_ind < MINPIT) {
    start_ind = MINPIT;
  }
  end_ind = il + 2;
  j = end_last_per - start_ind;
  ener2_f = 1 + nooffsigptr[j] * nooffsigptr[j]; /*to avoid division by 0*/
  for(j = end_last_per - 1; j > beg_last_per; j--)
  {
    ener2_f += nooffsigptr[j-start_ind] * nooffsigptr[j-start_ind];
  }
  for(i = start_ind; i <= end_ind; i++)
  {
    corx_f = 0;

    ener2_f += nooffsigptr[beg_last_per-i] * nooffsigptr[beg_last_per-i]; /*update, part 2*/
    for(j = end_last_per; j >= beg_last_per; j--)
    {
      corx_f += nooffsigptr[j] * nooffsigptr[j-i];
    }
    if (ener1_f > ener2_f) {
      em = ener1_f;
    }
    else {
      em = ener2_f;
    }
    if (corx_f > 0) {
      corx_f /= em;
    }
    if (corx_f > *maxco) {
      *ind = i;
      *maxco = corx_f;
    }
    ener2_f -= nooffsigptr[end_last_per-i] - nooffsigptr[end_last_per-i]; /*update, part 1*/
  }
  return;
}
*)


(*----------------------------------------------------------------------
* G722PLC_pitch_ol_flt(signal, length, maxco)
* open-loop pitch estimation
*
* signal      (i) : pointer to signal buffer (including signal memory)
* length      (i) : length of signal memory
* maxco       (o) : maximal correlation
* overlf_shft (o) : number of shifts
*
*---------------------------------------------------------------------- *)
(*
static Short G722PLC_pitch_ol_flt(Float * signal, Float *maxco)
{
  int i, j, il, k;
  int ind, ind2;
  Short zcr, stable;
  int beg_last_per;
  int valid = 0; /*not valid for the first lobe */
  int previous_best;

  Float *w_ds_sig;
  Float corx_f, ener1_f, ener2_f;
  Float temp_f;
  Float em;
  Float *ptr1, *nooffsigptr;
  Float L_temp;

  Float ds_sig[MAXPIT2_DS];
  Float ai[3], cor[3], rc[3];
  Float *pt1, *pt2;
  Float *w_ds_sig_alloc;

  nooffsigptr = signal; /* 296 - 8; rest MAXPIT2 */

  /* downsample (filter and decimate) signal */
  ptr1 = ds_sig;
  for(i = FACT_M1; i < MAXPIT2; i += FACT)
  {
    temp_f = nooffsigptr[i] * f_G722PLC_fir_lp[0];
    pt2 = nooffsigptr+i;
    for (k = 1; k < FEC_L_FIR_FILTER_LTP; k++)
    {
      pt2--;
      temp_f += *pt2 * f_G722PLC_fir_lp[k];
    }
    *ptr1++ = temp_f;
  }

  G722PLC_autocorr_flt(ds_sig, cor, 2, MAXPIT2_DS);
  Lag_window_flt(cor, f_G722PLC_lag, 2);/* Lag windowing*/
  Levinson_flt(cor, rc, &stable, 2, ai);
  ai[1] *= F_GAMMA;
  ai[2] *= F_GAMMA2;

  /* filter */
  w_ds_sig_alloc = (Float * )calloc(MAXPIT2_DS-2, sizeof(Float));
  w_ds_sig = w_ds_sig_alloc-2;

  for (i = 2; i < MAXPIT2_DS; i++)
  {
    L_temp = ai[1] * ds_sig[i - 1] + ai[2] * ds_sig[i - 2];
    w_ds_sig[i] = ds_sig[i] + L_temp;
  }

  ind = MAXPIT_S2_DS;  /*default value, 18*/
  previous_best = 0;   /*default value*/
  ind2 = 1;

  /* compute energy of signal in range [len/fac-1,(len-MAX_PIT)/fac-1] */
  ener1_f = 1;
  for (j = MAXPIT2_DSM1; j >= MAXPIT_DSP1; j--) {
    ener1_f += w_ds_sig[j] * w_ds_sig[j];
  }

  /* compute maximal correlation (maxco) and pitch lag (ind) */
  *maxco = 0;
  ener2_f = ener1_f - w_ds_sig[MAXPIT2_DSM1] * w_ds_sig[MAXPIT2_DSM1]; /*update, part 1*/
  ener2_f += w_ds_sig[MAXPIT_DSP1-1] * w_ds_sig[MAXPIT_DSP1-1]; /*update, part 2*/
  ener2_f -= w_ds_sig[MAXPIT2_DSM1-1] * w_ds_sig[MAXPIT2_DSM1-1]; /*update, part 1*/
  pt1 = &w_ds_sig[MAXPIT2_DSM1];
  pt2 = pt1-1;
  zcr = 0;
  for(i = 2; i < MAXPIT_DS; i++) /* < to avoid out of range later*/
  {
    ind2 += 1;
    corx_f = 0;

    for(j = MAXPIT2_DSM1; j >= MAXPIT_DSP1; j--)
    {
      corx_f += w_ds_sig[j] * w_ds_sig[j-i];
    }
    ener2_f += w_ds_sig[MAXPIT_DSP1-i] * w_ds_sig[MAXPIT_DSP1-i]; /*update, part 2*/
    if (ener1_f > ener2_f) {
      em = ener1_f;
    }
    else {
      em = ener2_f;
    }
    ener2_f -= w_ds_sig[MAXPIT2_DSM1-i] * w_ds_sig[MAXPIT2_DSM1-i]; /*update, part 1*/
    if (corx_f > 0) {
      corx_f /= em;
    }

    if (corx_f < 0) {
      valid = 1;
      /* maximum correlation is only searched after the first positive lobe of autocorrelation function */
    }
    /* compute (update)zero-crossing  in last examined period */
    if (((int)*pt1 ^ (int)*pt2) < 0) {
      zcr++;
    }
    pt1--;
    pt2--;
    if(zcr == 0) /*no zero crossing*/
    {
      valid = 0;
    }

    if(valid > 0)
    {
      if ((ind2 == ind) || (ind2 == 2 * ind)) { /* double or triple of actual pitch */
        if (*maxco > 0.85) {  /* 0.85 : high correlation, small chance that double pitch is OK */
          *maxco = 1;         /* the already found pitch value is kept */
        }

        if(*maxco < 0.888855f)/*to avoid overflow*/
        {
          *maxco *= (Float) 1.125;
        }
      }

      if ((corx_f > *maxco) && (i >= MINPIT_DS)) {
        *maxco = corx_f;
        if(i != (ind+1))
        {
          previous_best = ind;
        }
        ind = i;                /*save the new candidate */
        ind2 = 1;               /* reset counter for multiple pitch */
      }
    }
  }
  free(w_ds_sig_alloc);

  /* convert pitch to non decimated domain */
  il = 4 * ind;
  ind = il;

  /* refine pitch in non-decimated (8 kHz) domain by step of 1
  -> maximize correlation around estimated pitch lag (ind) */
  beg_last_per = MAXPIT2 - il;
  ener1_f = 1 + nooffsigptr[END_LAST_PER] * nooffsigptr[END_LAST_PER]; /*to avoid division by 0*/
  for(j = END_LAST_PER_1; j >= beg_last_per; j--)
  {
    ener1_f += nooffsigptr[j] * nooffsigptr[j];
  }
  /* compute maximal correlation (maxco) and pitch lag (ind) */
  *maxco = 0;

  G722PLC_pitch_ol_refine_flt(nooffsigptr, il, ener1_f, beg_last_per, END_LAST_PER, &ind,  maxco);
  if(*maxco < 0.4) /*check 2nd candidate if maxco > 0.4*/
  {
    previous_best = 0;
  }
  if(previous_best != 0) /*check second candidate*/
  {
    il = 4 * previous_best;
    G722PLC_pitch_ol_refine_flt(nooffsigptr, il, ener1_f, beg_last_per, END_LAST_PER, &ind,  maxco);
  }

  if ((*maxco < 0.25) && (ind < 32))
  {
	  ind *= 2; /*2 times pitch for very small pitch, at least 2 times MINPIT */
  }

  if (*maxco > 1) {
    *maxco = 1;
  }

  return ind;
}
*)


(*----------------------------------------------------------------------
* G722PLC_classif_modif_flt(maxco, decoder)
* signal classification and conditional residual modification
*
* maxco       (i) : maximal correlation
* nbl         (i) : lower-band G722 scale factor
* nbh         (i) : higher-band G722 scale factor
* mem_speech  (i) : pointer to speech buffer
* l_mem_speech(i) : length of speech buffer
* mem_exc     (i) : pointer to excitation buffer
* t0          (i) : open-loop pitch
*---------------------------------------------------------------------- *)
(*
static Short G722PLC_classif_modif_flt(Float maxco, Short nbl, Short nbh, Float* mem_speech, int l_mem_speech,
                                    Float* mem_exc, Short* t0
                                    )
{
  Short clas, zcr;
  int Temp, tmp1, tmp2, tmp3, i, j;
  Float  maxres, absres;
  Float *pt1, *pt2, ftmp;

  /************************************************************************
  * select preliminary class => clas = UNVOICED, WEAKLY_VOICED or VOICED *
  * by default clas=WEAKLY_VOICED                         *
  * classification criterio:                                             *
  * -normalized correlation from open-loop pitch                         *
  * -ratio of lower/higher band energy (G722 scale factors)              *
  * -zero crossing rate                                                  *
  ************************************************************************/

  /* compute zero-crossing rate in last 10 ms */
  pt1 = &mem_speech[l_mem_speech - 80];
  pt2 = pt1-1;
  zcr = 0;

  for(i = 0; i< 80; i++)
  {
    if((*pt1 <= 0) && (*pt2 > 0))
    {
      zcr++;
    }
    pt1++;
    pt2++;
  }

  /* set default clas */
  clas = G722PLC_WEAKLY_VOICED;

  /* detect voiced clas (corr > 3/4 ener1 && corr > 3/4 ener2) */
  if(maxco > 0.7)
  {
    clas = G722PLC_VOICED;
  }

  /* change class to unvoiced if higher band has lots of energy
  (risk of "dzing" if clas is "very voiced") */
  if(nbh > nbl)
  {
    if(clas == G722PLC_VOICED)  /*if the class is VOICED (constant G722PLC_VOICED = 0)*/
    {
		clas = G722PLC_WEAKLY_VOICED;
    }
	else
	{
		clas = G722PLC_VUV_TRANSITION;
	}
  }

  /* change class to unvoiced if zcr is high */
  if (zcr >= 20)
  {
    clas = G722PLC_UNVOICED;

    /* change pitch if unvoiced class (to avoid short pitch lags) */
    if(*t0 < 32)
    {
      *t0 *= 2; /*2 times pitch for very small pitch, at least 2 times MINPIT */
    }
  }


  /**************************************************************************
  * detect transient => clas = TRANSIENT                                  *
  * + modify residual to limit amplitude for LTP                           *
  * (this is performed only if current class is not VOICED to avoid        *
  *  perturbation of the residual for LTP)                                 *
  **************************************************************************/

  /* detect transient and limit amplitude of residual */
  Temp = 0;
  if (clas > 4)/*G722PLC_WEAKLY_VOICED(5) or G722PLC_VUV_TRANSITION(7)*/
  {
    tmp1 = MAXPIT2P1 - *t0; /* tmp1 = start index of last "pitch cycle" */
    tmp2 = tmp1 - *t0;  /* tmp2 = start index of last but one "pitch cycle" */
    for(i = 0; i < *t0; i++)
    {
      tmp3 = tmp2 + i;
	  maxres = (Float)fabs(mem_exc[tmp3-2]);
	  for(j = -1; j <=2; j++)
	  {
		  ftmp = (Float)fabs(mem_exc[tmp3+j]);
		  if(ftmp > maxres)
		  {
			  maxres = ftmp;
		  }
	  }
      absres = (Float)fabs(mem_exc[tmp1 + i]);

      /* if magnitude in last cycle > magnitude in last but one cycle */
      if(absres > maxres)
      {
        /* detect transient (ratio = 1/8) */
        if(absres >= 8*maxres)
        {
          Temp++;
        }

        /* limit value (even if a transient is not detected...) */
        if(mem_exc[tmp1 + i] < 0)
        {
          mem_exc[tmp1 + i] = -maxres;
        }
		else
        {
          mem_exc[tmp1 + i] = maxres;
        }
      }
    }
  }
  if(clas == G722PLC_UNVOICED)/*G722PLC_UNVOICED*/
  {
    Float mean;

    mean = 0;

    /* 209 = MAXPIT2P1 - 80, start index of last 10 ms, last period is smoothed */
    for(i = 0; i < 80; i++)
    {
      mean += (Float)fabs(mem_exc[209 + i]);
    }
    mean /= 32;  /*80/32 = 2.5 mean amplitude*/

    tmp1 = MAXPIT2P1 - *t0; /* tmp1 = start index of last "pitch cycle" */

    for(i = 0; i < *t0; i++)
    {
      if(fabs(mem_exc[tmp1 + i]) > mean)
      {
        mem_exc[tmp1 + i] /= 4;
      }
    }
  }
  if (Temp>0)
  {
    clas = G722PLC_TRANSIENT;
	if(*t0 > 40)
	{
      *t0 = 40; /*max 5 ms pitch */
	}
  }

  /*******************************************************************************
  * pitch tuning by searching last glotal pulses                                *
  * checks if there is no 2 pulses in the last periode due to decreasing pitch  *
  *******************************************************************************/

  if(clas == 0)  /*if the class is VOICED (constant G722PLC_VOICED = 0)*/
  {
    Float maxpulse;
    int mincheck, pulseind=0;
    int end2nd;
    Float maxpulse2nd;
    Short pulseind2nd=0;
    Float absval;
    Float cumul, pulsecumul;
    Short signbit, signbit2nd;

    mincheck = *t0 - 5;
    maxpulse = -1;
    maxpulse2nd = -1;
    cumul = 0;
    pulsecumul = 0;

    pt1 = &mem_exc[MAXPIT2P1 - 1]; /*check the last period*/

    for(i = 0; i < *t0; i++) /*max pitch variation searched is +-5 */
    {
      absval = (Float)fabs(*pt1);
      if(absval > maxpulse)
      {
		maxpulse = absval;
        pulseind = i;
      }
      cumul += absval;
      pt1--;
    }
    pulsecumul = maxpulse * *t0;
    if(mem_exc[MAXPIT2P1 - pulseind - 1] < 0) /*check the sign*/
	{
		signbit = 1;
	}
	else
	{
		signbit = 0;
	}

    if(cumul < pulsecumul/4) /* if mean amplitude < max amplitude/4 --> real pulse*/
    {
      end2nd = pulseind - mincheck;
      pt1 = &mem_exc[MAXPIT2P1 - 1]; /*end of excitation*/

      for(i = 0; i < end2nd; i++) /*search 2nd pulse at the end of the periode*/
      {
        absval = (Float)fabs(*pt1);  /*abs_s added on 25/07/2007*/
        if(absval > maxpulse2nd)
        {
	      maxpulse2nd = absval;
          pulseind2nd = i;
        }
        pt1--;
      }
      end2nd = mincheck + pulseind;
      pt1 = &mem_exc[MAXPIT2P1 - 1 - end2nd]; /*end of excitation*/

      for(i = end2nd; i < *t0; i++) /*search 2nd pulse at the beggining of the periode*/
      {
        absval = (Float)fabs(*pt1);
        if(absval > maxpulse2nd)
        {
	      maxpulse2nd = absval;
          pulseind2nd = i;
        }
        pt1--;
      }
      if(maxpulse2nd > maxpulse/2)
      {
		if(mem_exc[MAXPIT2P1 - pulseind2nd - 1] < 0) /*check the sign*/
		{
			signbit2nd = 1;
		}
		else
		{
			signbit2nd = 0;
		}

        if(signbit == signbit2nd)
        {
          *t0 = (Short)fabs(pulseind - pulseind2nd);
        }
      }
    }
  }

  return clas;
}
*)


(*----------------------------------------------------------------------
* G722PLC_syn_filt_flt(m, a, x, y, n n)
* LPC synthesis filter
*
* m (i) : LPC order
* a (i) : LPC coefficients
* x (i) : input buffer
* y (o) : output buffer
* n (i) : number of samples
*---------------------------------------------------------------------- *)
(*
static void G722PLC_syn_filt_flt(Short m, Float* a, Float* x, Float* y, Short n)
{
  Short j;

  *y = a[0] * *x;
  for (j = 1; j <= m; j++)
  {
    *y -= a[j] * y[-j];
  }
  return;
}
*)


(*----------------------------------------------------------------------
* G722PLC_ltp_pred_1s_flt(cur_exc, t0, jitter)
* one-step LTP prediction and jitter update
*
* exc     (i)   : excitation buffer (exc[...-1] correspond to past)
* t0      (i)   : pitch lag
* jitter  (i/o) : pitch lag jitter
*---------------------------------------------------------------------- *)
(*
static Float G722PLC_ltp_pred_1s_flt(Float* exc, Short t0, Short *jitter)
{
  Short i;

  i = *jitter - t0;

  /* update jitter for next sample */
  *jitter = -*jitter;

  /* prediction =  exc[-t0+jitter] */
  return exc[i];
}
*)


(*----------------------------------------------------------------------
* G722PLC_ltp_syn_flt(plc_state, cur_exc, cur_syn, n, jitter)
* LTP prediction followed by LPC synthesis filter
*
* plc_state    (i/o) : PLC state variables
* cur_exc  (i)   : pointer to current excitation sample (cur_exc[...-1] correspond to past)
* cur_syn  (i/o) : pointer to current synthesis sample
* n     (i)      : number of samples
* jitter  (i/o)  : pitch lag jitter
*---------------------------------------------------------------------- *)
(*
static void G722PLC_ltp_syn_flt(G722PLC_STATE_FLT* plc_state, Float* cur_exc, Float* cur_syn, Short n, Short *jitter)
{
  Short i;

  for (i = 0; i < n; i++)
  {
    /* LTP prediction using exc[...-1] */
    *cur_exc = G722PLC_ltp_pred_1s_flt(cur_exc, plc_state->s_t0, jitter);

    /* LPC synthesis filter (generate one sample) */
    G722PLC_syn_filt_flt(ORD_LPC, plc_state->f_a, cur_exc, cur_syn, 1);

    cur_exc++;
    cur_syn++;
  }

  return;
}
*)


(*----------------------------------------------------------------------
* G722PLC_syn_flt(plc_state, syn, n)
* extrapolate missing lower-band signal (PLC)
*
* plc_state (i/o) : PLC state variables
* syn   (o)   : synthesis
* n     (i)   : number of samples
*---------------------------------------------------------------------- *)
(*
static void G722PLC_syn_flt(G722PLC_STATE_FLT * plc_state, Float * syn, Short n)
{
  Float *buffer_syn; /* synthesis buffer */
  Float *buffer_exc; /* excitation buffer */
  Float *cur_syn;    /* pointer to current sample of synthesis */
  Float *cur_exc;    /* pointer to current sample of excition */
  Float *exc;        /* pointer to beginning of excitation in current frame */
  Short temp;
  Short jitter, dim;

  dim = n + plc_state->s_t0p2;
  /* allocate temporary buffers and set pointers */
  buffer_exc = (Float * )calloc(dim, sizeof(Float));
  buffer_syn = (Float * )calloc(2*ORD_LPC, sizeof(Float)); /* minimal allocations of scratch RAM */

  cur_exc = &buffer_exc[plc_state->s_t0p2];	/* pointer ! */
  cur_syn = &buffer_syn[ORD_LPC]; /* pointer */

  exc = cur_exc;	/* pointer */

  /* copy memory
  - past samples of synthesis (LPC order)            -> buffer_syn[0]
  - last "pitch cycle" of excitation (t0+2) -> buffer_exc[0]
  */
  movF(ORD_LPC, plc_state->f_mem_syn, buffer_syn); /*  */

  movF(plc_state->s_t0p2, plc_state->f_mem_exc + MAXPIT2P1 - plc_state->s_t0p2, buffer_exc);

  /***************************************************
  * set pitch jitter according to clas information *
  ***************************************************/
  jitter = plc_state->s_clas & 1;
  plc_state->s_t0 = plc_state->s_t0 | jitter;    /* change even delay as jitter is more efficient for odd delays */

  /*****************************************************
  * generate signal by LTP prediction + LPC synthesis *
  *****************************************************/

  temp = n - ORD_LPC;
  /* first samples [0...ord-1] */
  G722PLC_ltp_syn_flt(plc_state, cur_exc, cur_syn, ORD_LPC, &jitter);
  movF(ORD_LPC, cur_syn, syn);

  /* remaining samples [ord...n-1] */
  G722PLC_ltp_syn_flt(plc_state, &cur_exc[ORD_LPC], &syn[ORD_LPC], temp, &jitter);

  /* update memory:
  - synthesis for next frame (last LPC-order samples)
  - excitation */
  movF(ORD_LPC, &syn[temp], plc_state->f_mem_syn);
  G722PLC_update_mem_exc_flt(plc_state, exc, n);

  /* free allocated memory */
  free(buffer_syn);
  free(buffer_exc);

  return;
}
*)


(*-------------------------------------------------------------------------*
* Function G722PLC_lpc_flt *
*--------------------------------------------------------------------------*)
(*
static void G722PLC_lpc_flt(G722PLC_STATE_FLT * plc_state, Float * mem_speech)
{
  Short tmp;

  Float cor[ORD_LPC + 1];
  Float rc[ORD_LPC + 1];

  G722PLC_autocorr_flt(&mem_speech[MEMSPEECH_LEN - HAMWINDLEN], cor, ORD_LPC, HAMWINDLEN);
  Lag_window_flt(cor, f_G722PLC_lag, ORD_LPC);/* Lag windowing*/
  Levinson_flt(cor, rc, &tmp, ORD_LPC, plc_state->f_a);

  return;
}
*)


(*-------------------------------------------------------------------------*
* Function G722PLC_residu_flt *
*--------------------------------------------------------------------------*)
(*
static void G722PLC_residu_flt(G722PLC_STATE_FLT * plc_state)
{
  Float L_temp;
  Float *ptr_sig, *ptr_res;
  int i, j;

  ptr_res = plc_state->f_mem_exc;
  ptr_sig = &plc_state->f_mem_speech[MEMSPEECH_LEN - MAXPIT2P1];

  for (i = 0; i < MAXPIT2P1; i++)
  {
    L_temp = ptr_sig[i] * plc_state->f_a[0];
    for (j = 1; j <= ORD_LPC; j++)
    {
      L_temp += plc_state->f_a[j] * ptr_sig[i - j];
    }
    ptr_res[i] = L_temp;
  }

  return;
}
*)

{
#define DLT  decoder->dlt
#define PLT  decoder->plt
#define RLT  decoder->rlt
#define SL   decoder->sl
#define SZL  decoder->szl
#define DETL decoder->detl
#define NBL  decoder->nbl
#define DETH decoder->deth
#define NBH  decoder->nbh
#define AL   decoder->al
#define BL   decoder->bl
}

(*
static void G722PLC_qmf_updstat_flt (outcode,decoder,lb_signal,hb_signal,state)
Short *outcode;
Float *lb_signal;
Float *hb_signal;
g722_state     *decoder;
void *state;

{
  Short  rh, rl;
  Short  i;
  G722PLC_STATE_FLT * plc_state = (G722PLC_STATE_FLT * ) state;
  Float *endLastOut;
  Float *firstFuture;
  Short *filtmem, *filtptr;

  filtmem = (Short * )calloc(102, sizeof(Short));

  movSS(22, &decoder->qmf_rx_delayx[2], &filtmem[L_FRAME_WB]); /*load memory*/
  filtptr = &filtmem[L_FRAME_WB];
  for (i = 0; i < L_FRAME_NB; i++)
  {
    /* filter higher-band */
    rh = (Short)G722PLC_hp_flt(&plc_state->f_mem_hpf_in, &plc_state->f_mem_hpf_out, *hb_signal,
      f_G722PLC_b_hp156, f_G722PLC_a_hp156);
	rl = (Short)*lb_signal;
    /* calculate output samples of QMF filter */
    fl_qmf_rx_buf (rl, rh, &filtptr, &outcode);

    lb_signal++;
    hb_signal++;
  }

  movSS(22, filtmem, &decoder->qmf_rx_delayx[2]); /*save memory*/
  free(filtmem);

  /* reset G.722 decoder */
  endLastOut = &(plc_state->f_mem_speech[MEMSPEECH_LEN - 1]);
  firstFuture = plc_state->f_crossfade_buf;

  zeroS(7, DLT);

  PLT[1] = (Short)(endLastOut[0]/2);
  PLT[2] = (Short)(endLastOut[-1]/2);

  RLT[1] = (Short)endLastOut[0];
  RLT[2] = (Short)endLastOut[-1];

  SL = (Short)firstFuture[0];
  SZL = (Short)(firstFuture[0]/2);

  /* change scale factors (to avoid overshoot) */
  NBH  = NBH >> 1;
  DETH = scaleh(NBH);

  /* reset G.722 decoder after muting */
  if( plc_state->s_count_att_hb > 160 )
  {
    DETL = 32;
    NBL = 0;
    DETH = 8;
    NBH = 0;
  }
  AL[1] = (Short)(AL[1] * F_GAMMA_AL2);
  AL[2] = (Short)(AL[2] * F_GAMMA2_AL2);
  BL[1] = (Short)(BL[1] * F_GAMMA_AL2);
  BL[2] = (Short)(BL[2] * F_GAMMA2_AL2);
  BL[3] = (Short)(BL[3] * F_GAMMA3_AL2);
  BL[4] = (Short)(BL[4] * F_GAMMA4_AL2);
  BL[5] = (Short)(BL[5] * F_GAMMA5_AL2);
  BL[6] = (Short)(BL[6] * F_GAMMA6_AL2);

}
*)
//* .................... end of G722PLC_qmf_updstat() .......................... */

// end of g722_plc.c

type
//* G.722 decoder state structure (only used for decoder) */
    pg722dec_state = ^g722dec_state;
    g722dec_state = packed record
        g722work : g722_state;
        plcwork : pointer;
    end;



function  g722_decode_const() : p_dec;
var
    work : pg722dec_state;
begin
    work := malloc(sizeof(g722dec_state));
    if (nil <> work) then
    begin
        g722_decode_reset(work);
        work.plcwork := G722PLC_init_flt();
    end;

    exit(work);
end;


procedure g722_decode_dest(d : p_dec);
var
    work : pg722dec_state absolute d;
begin
    if (nil <> work) then
    begin
        G722PLC_clear_flt(work.plcwork);
        mrealloc(work);
    end;
end;


procedure g722_decode_reset(d : p_dec);
var
    work : pg722dec_state absolute d;
    w16ptr : pshort;
begin
    if (nil <> work) then
    begin
        w16ptr := d;
        zeros(sizeof(g722dec_state) div 2, w16ptr^); //*106 : size of g722dec_state structure in Short (212 bytes)*/
        work.g722work.detl := 32;
        work.g722work.deth := 8;
    end;
end;
//* .................... end of g722_decode_reset() ....................... */


function fl_g722_decode1(   mode : short;
                            code : p_data;
                            code_enh : p_data;
                            mode_enh : short;
                            rl : pshort;
                            i : short;
                            d : p_dec;
                            pBit_wbenh : pp_wbenh;
                            wbenh_flag : short;
                            enh_no : pshort;
                            sum_ma_dh_abs : pfloat
                        ) : short;
begin
    // remove me
end;

{$IFDEF FALSE }

(*
Word32 G722PLC_decode(short *code, short *outcode, short mode, Short read1,
g722_state *decoder,void *plc_state)
*)
function fl_g722_decode1(   mode : short;
                            code : p_data;
                            code_enh : p_data;
                            mode_enh : short;
                            rl : pshort;
                            i : short;
                            d : p_dec;
                            pBit_wbenh : pp_wbenh;
                            wbenh_flag : short;
                            enh_no : pshort;
                            sum_ma_dh_abs : pfloat
                        ) : short;
var
    il, ih : short;
    rh, k, nb, ih_enh : short;
    work : pg722dec_state absolute d;
    decoder : pg722_state;
    plc_state_flt : pG722PLC_STATE_FLT;
begin
    decoder := @work.g722work;
    plc_state_flt := work.plcwork;
    (* Separate the input G722 codeword: bits 0 to 5 are the lower-band
    * portion of the encoding, and bits 6 and 7 are the upper-band
    * portion of the encoding *)
    il := code[i] and $3F; //* 6 bits of low SB */
    ih := code[i] shr 6; //* 2 bits of high SB */

    ih_enh := 0;
    if ((mode_enh - 2) = 0) then                                      //* i 0 1 2 3 4 5 6 7 8 9 a b c d e f */
    begin
        k := i shr 3;                                               //* k 0 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 mode2*/
        nb := i and 7;                                            //*nb 0 1 2 3 4 5 6 7 0 1 2 3 4 5 6 7 mode2*/
        ih_enh := (code_enh[k] shr nb) and 1;
    end;

    //* Call the upper and lower band ADPCM decoders */
    rl^ := lsbdec(il, mode, decoder);
    rh  := fl_hsbdec_enh(ih, ih_enh, mode_enh, decoder, i, pBit_wbenh, wbenh_flag, enh_no, sum_ma_dh_abs);

    //* remove-DC filter */
    rh := Round( G722PLC_hp_flt(@plc_state_flt.f_mem_hpf_in, @plc_state_flt.f_mem_hpf_out, rh, pfloatA(@f_G722PLC_b_hp156), pfloatA(@f_G722PLC_a_hp156)) + 0.5 );
    exit(rh);
end;

{$ENDIF FALSE }


procedure g722_decode(mode : short; const code : p_data;
                 const code_enh : p_data; mode_enh : short;
                 loss_flag : int; outcode : p_pcm;
                 d : p_dec; pBit_wbenh : pp_wbenh; wbenh_flag : short);
var
    work : pg722dec_state absolute d;
    decoder : pg722_state;
    plc_state_flt : pG722PLC_STATE_FLT;

    //* Decoder variables */
    rl, rh : short;

    //* Auxiliary variables */
    i, j : short;
    ptr_l, ptr_h : pfloat;
    filtmem : array[0..L_FRAME_WB + 22 - 1] of short;
    filtptr : pshort;
    weight : float;

    enh_no : short;
    sum_ma_dh_abs : float;
begin
    decoder := @work.g722work;
    plc_state_flt := work.plcwork;

    if (0 = loss_flag) then
    begin
        //*------ decode good frame ------*/
        filtptr := @filtmem[L_FRAME_WB];

        //* shift speech buffers */
        movef(257, plc_state_flt.f_mem_speech[L_FRAME_NB], plc_state_flt.f_mem_speech); //*shift 5 ms*/
        movef(120, plc_state_flt.f_mem_speech_hb[L_FRAME_NB], plc_state_flt.f_mem_speech_hb); //*shift 5 ms*/

        ptr_l := @plc_state_flt.f_mem_speech[257];
        ptr_h := @plc_state_flt.f_mem_speech_hb[120];

        //* Decode - reset is never applied here */
        i := 0;

        moves(22, decoder.qmf_rx_delayx[2], filtmem[L_FRAME_WB]); //* load memory */

        enh_no := NBITS_MODE_R1SM_WBE;
        sum_ma_dh_abs := 0.0;

        if (plc_state_flt.s_count_crossfade < CROSSFADELEN) then //* first good 10 ms, crossfade is needed*/
        begin
            i := plc_state_flt.s_count_crossfade;
            while (i < 20) do //*first 20 samples : flat part*/
            begin
                (* Separate the input G722 codeword: bits 0 to 5 are the lower-band
                * portion of the encoding, and bits 6 and 7 are the upper-band
                * portion of the encoding *)
                rh := fl_g722_decode1(mode, code, code_enh, mode_enh, @rl, i,
                  d, pBit_wbenh, wbenh_flag, @enh_no, @sum_ma_dh_abs);

                //* cross-fade samples with PLC synthesis (in lower band only) */
                rl := Round(plc_state_flt.f_crossfade_buf[i]);

                //* copy lower and higher band sample */
                ptr_l^ := rl;
                ptr_h^ := rh;
                inc(ptr_l);
                inc(ptr_h);

                //* Calculation of output samples from QMF filter */
                fl_qmf_rx_buf(rl, rh, @filtptr, ppshort(@outcode));

                inc(i);
            end;

            if (plc_state_flt.s_count_crossfade > 0) then    //* 2nd valid frame*/
                weight := 0.34991455 //*11466;  21*546*/
            else
                weight := 0.0166259765; //*546/32768*/  /*first valid frame, after flat part (sample 21)*/

            while (i < plc_state_flt.s_count_crossfade + L_FRAME_NB) do
            begin
                j :=  i - plc_state_flt.s_count_crossfade;

                (* Separate the input G722 codeword: bits 0 to 5 are the lower-band
                * portion of the encoding, and bits 6 and 7 are the upper-band
                * portion of the encoding *)
                rh := fl_g722_decode1(mode, code, code_enh, mode_enh, @rl, j,
                  d, pBit_wbenh, wbenh_flag, @enh_no, @sum_ma_dh_abs);

                //* cross-fade samples with PLC synthesis (in lower band only) */
                rl := Round(rl * weight  + plc_state_flt.f_crossfade_buf[i] * (1- weight));
                weight := weight + 0.0166259765; //*546/32768*/

                //* copy lower and higher band sample */
                ptr_l^ := rl;
                ptr_h^ := rh;
                inc(ptr_l);
                inc(ptr_h);

                //* Calculation of output samples from QMF filter */
                fl_qmf_rx_buf (rl, rh, @filtptr, ppshort(@outcode));

                inc(i);
            end;

            plc_state_flt.s_count_crossfade := plc_state_flt.s_count_crossfade + L_FRAME_NB;
        end;

        while (i < L_FRAME_NB) do
        begin
            (* Separate the input G722 codeword: bits 0 to 5 are the lower-band
            * portion of the encoding, and bits 6 and 7 are the upper-band
            * portion of the encoding *)
            rh := fl_g722_decode1(mode, code, code_enh, mode_enh, @rl, i,
                d, pBit_wbenh, wbenh_flag, @enh_no, @sum_ma_dh_abs);

            //* copy lower and higher band sample */
            ptr_l^ := rl;
            ptr_h^ := rh;
            inc(ptr_l);
            inc(ptr_h);

            //* Calculation of output samples from the reference QMF filter */
            fl_qmf_rx_buf (rl, rh, @filtptr, ppshort(@outcode));

            inc(i);
        end;

        moves(22, filtmem, decoder.qmf_rx_delayx[2]); //* save memory */

        //* set previous bfi to good frame */
        plc_state_flt.s_prev_bfi := 0;
    end
    else
    begin
        //* (loss_flag != 0) */
        //*------ decode bad frame ------*/
        G722PLC_conceal_flt(plc_state_flt, outcode, decoder);

        //* set previous bfi to good frame */
        plc_state_flt.s_prev_bfi := 1;
    end;
end;
//* .................... end of g722_decode() .......................... */



end.

