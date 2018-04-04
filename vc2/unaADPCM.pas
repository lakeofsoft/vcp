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

	  unaADPCM.pas - ADPCM encoder and decoder
	  VC components version 3.0

	----------------------------------------------
	  Copyright (c) 2010-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 18 Nov 2010

	  modified by:
		Lake, Nov 2010

	----------------------------------------------
*)

{$I unaDef.inc }

{*
	ADPCM encoder and decoder
}

unit
  unaADPCM;

{*
  ADPCM encoder and decoder

  @Author Lake

  Version 1.0 First release
}

interface

uses
  Windows, unaTypes, unaClasses;

{


4.5.1 DVI4

   DVI4 uses an adaptive delta pulse code modulation (ADPCM) encoding
   scheme that was specified by the Interactive Multimedia Association
   (IMA) as the "IMA ADPCM wave type".  However, the encoding defined
   here as DVI4 differs in three respects from the IMA specification:

   o  The RTP DVI4 header contains the predicted value rather than the
      first sample value contained the IMA ADPCM block header.

   o  IMA ADPCM blocks contain an odd number of samples, since the first
      sample of a block is contained just in the header (uncompressed),
      followed by an even number of compressed samples.  DVI4 has an
      even number of compressed samples only, using the `predict' word
      from the header to decode the first sample.

   o  For DVI4, the 4-bit samples are packed with the first sample in
      the four most significant bits and the second sample in the four
      least significant bits.  In the IMA ADPCM codec, the samples are
      packed in the opposite order.

   Each packet contains a single DVI block.  This profile only defines
   the 4-bit-per-sample version, while IMA also specified a 3-bit-per-
   sample encoding.

   The "header" word for each channel has the following structure:

      int16  predict;  /* predicted value of first sample
			  from the previous block (L16 format) */
      u_int8 index;    /* current index into stepsize table */
      u_int8 reserved; /* set to zero by sender, ignored by receiver */

   Each octet following the header contains two 4-bit samples, thus the
   number of samples per packet MUST be even because there is no means
   to indicate a partially filled last octet.

   Packing of samples for multiple channels is for further study.

   The IMA ADPCM algorithm was described in the document IMA Recommended
   Practices for Enhancing Digital Audio Compatibility in Multimedia
   Systems (version 3.0).  However, the Interactive Multimedia
   Association ceased operations in 1997.  Resources for an archived
   copy of that document and a software implementation of the RTP DVI4
   encoding are listed in Section 13.


4.5.17 VDVI

   VDVI is a variable-rate version of DVI4, yielding speech bit rates of
   between 10 and 25 kb/s.  It is specified for single-channel operation
   only.  Samples are packed into octets starting at the most-
   significant bit.  The last octet is padded with 1 bits if the last
   sample does not fill the last octet.  This padding is distinct from
   the valid codewords.  The receiver needs to detect the padding
   because there is no explicit count of samples in the packet.

   It uses the following encoding:

	    DVI4 codeword  VDVI bit pattern
	    _______________________________
			0  00
			1  010
			2  1100
			3  11100
			4  111100
			5  1111100
			6  11111100
			7  11111110
			8  10
			9  011
		       10  1101
		       11  11101
		       12  111101
		       13  1111101
		       14  11111101
		       15  11111111

}

type
  {*
  }
  una_ADPCM_type = (adpcm_IMA4, adpcm_DVI4, adpcm_VDVI);

  {*
  }
  puna_ADPCM_state = ^una_ADPCM_state;
  una_ADPCM_state = record
    //
    r_variant: una_ADPCM_type;
    r_last: int16;
    r_step_index: int;
    r_ima_byte: uint16;
    r_bits: int;
  end;

  {*
  }
  unaADPCM_coder = class(unaObject)
  private
    f_state: una_ADPCM_state;
    f_buf: pointer;
  public
    constructor create(variant: una_ADPCM_type);
    procedure BeforeDestruction(); override;
  end;

  {*
  }
  unaADPCM_encoder = class(unaADPCM_coder)
  public
    function encode(data: pointer; num_samples: int; out buf: pointer): int;
  end;

  {*
  }
  unaADPCM_decoder = class(unaADPCM_coder)
  public
    function decode(buf: pointer; size: int; out samples: pointer): int;
  end;



{*
}
procedure adpcm_init(var state: una_ADPCM_state; variant: una_ADPCM_type);
{*
}
function adpcm_allocbuf_encode(var state: una_ADPCM_state; var ima_data: pointer; num_samples: int): int;
{*
}
function adpcm_allocbuf_decode(var state: una_ADPCM_state; var amp: pInt16Array; ima_bytes: int): int;
{*
}
function adpcm_encode(var state: una_ADPCM_state; ima_data: pointer; amp: pInt16Array; num_samples: int): int;
{*
}
function adpcm_decode(var state: una_ADPCM_state; amp: pInt16Array; ima_data: pointer; ima_bytes: int): int;


implementation


uses
  unaUtils;

type
  {*
  }
  unaVDVI_encode = packed record
    code: uint8;
    bits: uint8;
  end;

  {*
  }
  unaVDVI_decode = packed record
    code: uint16;
    mask: uint16;
    bits: uint8;
  end;


const
  c_max_step	= 88;	//

  {*
  }
  c_step_size: array[0 .. c_max_step] of int = (
	7,     8,     9,    10,    11,    12,    13,    14,
       16,    17,    19,    21,    23,    25,    28,    31,
       34,    37,    41,    45,    50,    55,    60,    66,
       73,    80,    88,    97,   107,   118,   130,   143,
      157,   173,   190,   209,   230,   253,   279,   307,
      337,   371,   408,   449,   494,   544,   598,   658,
      724,   796,   876,   963,  1060,  1166,  1282,  1411,
      552,  1707,  1878,  2066,  2272,  2499,  2749,  3024,
     3327,  3660,  4026,  4428,  4871,  5358,  5894,  6484,
     7132,  7845,  8630,  9493, 10442, 11487, 12635, 13899,
    15289, 16818, 18500, 20350, 22385, 24623, 27086, 29794, 32767
  );

  {*
  }
  c_step_adjustment: array[0..7] of int = (-1, -1, -1, -1, 2, 4, 6, 8);

  {*
  }
  c_vdvi_encode: array[0..15] of unaVDVI_encode = (
    (code: $00; bits: 2),
    (code: $02; bits: 3),
    (code: $0C; bits: 4),
    (code: $1C; bits: 5),
    (code: $3C; bits: 6),
    (code: $7C; bits: 7),
    (code: $FC; bits: 8),
    (code: $FE; bits: 8),
    (code: $02; bits: 2),
    (code: $03; bits: 3),
    (code: $0D; bits: 4),
    (code: $1D; bits: 5),
    (code: $3D; bits: 6),
    (code: $7D; bits: 7),
    (code: $FD; bits: 8),
    (code: $FF; bits: 8)
  );

  {*
  }
  c_vdvi_decode: array[0..15] of unaVDVI_decode = (
    (code: $0000; mask: $C000; bits: 2),
    (code: $4000; mask: $E000; bits: 3),
    (code: $C000; mask: $F000; bits: 4),
    (code: $E000; mask: $F800; bits: 5),
    (code: $F000; mask: $FC00; bits: 6),
    (code: $F800; mask: $FE00; bits: 7),
    (code: $FC00; mask: $FF00; bits: 8),
    (code: $FE00; mask: $FF00; bits: 8),
    (code: $8000; mask: $C000; bits: 2),
    (code: $6000; mask: $E000; bits: 3),
    (code: $D000; mask: $F000; bits: 4),
    (code: $E800; mask: $F800; bits: 5),
    (code: $F400; mask: $FC00; bits: 6),
    (code: $FA00; mask: $FE00; bits: 7),
    (code: $FD00; mask: $FF00; bits: 8),
    (code: $FF00; mask: $FF00; bits: 8)
  );


// --  --
function clip(value: int): int16; {$IFDEF UNA_OK_INLINE }{$IFDEF DEBUG }{$ELSE }inline;{$ENDIF DEBUG }{$ENDIF UNA_OK_INLINE }
begin
  if (value > $7FFF) then
    result := $7FFF
  else
    if (value < -32768) then
      result := -32768
    else
      result := value;
end;

// --  --
function decode_sample(var state: una_ADPCM_state; v: uint8): int16;
var
  e, ss: int;
begin
  //* e = (v + 0.5) * step / 4 */
  if ((0 <= state.r_step_index) and (c_max_step >= state.r_step_index)) then begin
    //
    ss := c_step_size[state.r_step_index];
    e := ss shr 3;
    //
    if (0 <> (v and $01)) then
      inc(e, (ss shr 2));
    //
    if (0 <> (v and $02)) then
      inc(e, (ss shr 1));
    //
    if (0 <> (v and $04)) then
      inc(e, ss);
    //
    if (0 <> (v and $08)) then
      e := -e;
    //
    result := clip(state.r_last + e);
    state.r_last := result;
    //
    state.r_step_index := state.r_step_index + c_step_adjustment[v and $07];
    if (state.r_step_index < 0) then
      state.r_step_index := 0
    else
      if (state.r_step_index > c_max_step) then
	state.r_step_index := c_max_step;
    //
  end
  else
    result := 0;
end;

// --  --
function encode_sample(var state: una_ADPCM_state; sample: int16): uint8;
var
  e, ss, diff, initial_e: int;
  adpcm: uint8;
begin
  ss := c_step_size[state.r_step_index];
  e := sample - state.r_last;
  initial_e := e;
  //
  diff := ss shr 3;
  adpcm := $00;
  //
  if (e < 0) then begin
    //
    adpcm := $08;
    e := -e;
  end;
  //
  if (e >= ss) then begin
    //
    adpcm := adpcm or $04;
    dec(e, ss);
  end;
  //
  ss := ss shr 1;
  if (e >= ss) then begin
    //
    adpcm := adpcm or $02;
    dec(e, ss);
  end;
  //
  ss := ss shr 1;
  if (e >= ss) then begin
    //
    adpcm := adpcm or $01;
    dec(e, ss);
  end;
  //
  if (initial_e < 0) then
    diff := -(diff - initial_e - e)
  else
    diff :=   diff + initial_e - e;
  //
  state.r_last := clip(diff + state.r_last);
  state.r_step_index := state.r_step_index + c_step_adjustment[adpcm and $07];
  if (state.r_step_index < 0) then
    state.r_step_index := 0
  else
    if (state.r_step_index > c_max_step) then
      state.r_step_index := c_max_step;
  //
  result := adpcm;
end;


// -- main code --

// --  --
procedure adpcm_init(var state: una_ADPCM_state; variant: una_ADPCM_type);
begin
  fillChar(state, sizeof(una_ADPCM_state), #0);
  state.r_variant := variant;
end;

// --  --
function adpcm_allocbuf_encode(var state: una_ADPCM_state; var ima_data: pointer; num_samples: int): int;
begin
  case (state.r_variant) of

    adpcm_IMA4: result := 4 + (num_samples - 1) shr 1;
    adpcm_DVI4: result := 4 +  num_samples      shr 1;
    adpcm_VDVI: result := 4 +  num_samples           ;  // assume worse case
    else
		result := 0;
  end;
  //
  mrealloc(ima_data, result);  //
end;

// --  --
function adpcm_allocbuf_decode(var state: una_ADPCM_state; var amp: pInt16Array; ima_bytes: int): int;
begin
  case (state.r_variant) of

    adpcm_IMA4: result := (ima_bytes - 4) shl 2 + 2;
    adpcm_DVI4: result := (ima_bytes - 4) shl 2;
    adpcm_VDVI: result := (ima_bytes - 4) shl 3 ;  // assume worse case
    else
		result := 0;
  end;
  //
  if (0 < result) then
    mrealloc(amp, result);  //
end;

// --  --
function adpcm_encode(var state: una_ADPCM_state; ima_data: pointer; amp: pInt16Array; num_samples: int): int;
var
  i: int;
  code: uint8;
begin
  result := 0;
  if ((nil <> ima_data) and (nil <> amp) and (1 < num_samples)) then begin
    //
    state.r_bits := 0;
    //
    case (state.r_variant) of

      adpcm_IMA4: begin
	//
	if (1 <> (num_samples and 1)) then
	  dec(num_samples);	// must have odd number of samples
	//
	pArray(ima_data)[result + 0] := uint8(amp[0] and $FF);
	pArray(ima_data)[result + 1] := uint8(amp[0] shr 8);
	pArray(ima_data)[result + 2] := state.r_step_index;
	pArray(ima_data)[result + 3] := 0;
	inc(result, 4);
	//
	state.r_last := amp[0];
	//
	i := 1;
	while (i < num_samples) do begin
	  //
	  state.r_ima_byte := uint16((state.r_ima_byte shr 4) or (encode_sample(state, amp[i]) shl 4));
	  if (0 <> (state.r_bits and 1)) then begin
	    //
	    pArray(ima_data)[result] := uint8(state.r_ima_byte);
	    inc(result);
	  end;
	  //
	  inc(state.r_bits);
	  inc(i);
	end;
      end;

      adpcm_DVI4: begin
	//
	if (0 <> (num_samples and 1)) then
	  dec(num_samples);	// must have even number of samples
	//
	pArray(ima_data)[result + 0] := uint8(state.r_last shr 8);
	pArray(ima_data)[result + 1] := uint8(state.r_last and $FF);
	pArray(ima_data)[result + 2] := state.r_step_index;
	pArray(ima_data)[result + 3] := 0;
	inc(result, 4);
	//
	for i := 0 to num_samples - 1 do begin
	  //
	  state.r_ima_byte := uint16((state.r_ima_byte shl 4) or encode_sample(state, amp[i]));
	  if (0 <> (state.r_bits and 1)) then begin
	    //
	    pArray(ima_data)[result] := uint8(state.r_ima_byte);
	    inc(result);
	  end;
	  //
	  inc(state.r_bits);
	end;
      end;

      adpcm_VDVI: begin
	//
	if (0 <> (num_samples and 1)) then
	  dec(num_samples);	// must have even number of samples
	//
	pArray(ima_data)[result + 0] := uint8(state.r_last shr 8);
	pArray(ima_data)[result + 1] := uint8(state.r_last and $FF);
	pArray(ima_data)[result + 2] := state.r_step_index;
	pArray(ima_data)[result + 3] := 0;
	inc(result, 4);
	//
	for i := 0 to num_samples - 1 do begin
	  //
	  code := encode_sample(state, amp[i]);
	  state.r_ima_byte := uint16((state.r_ima_byte shl c_vdvi_encode[code].bits) or c_vdvi_encode[code].code);
	  state.r_bits := state.r_bits + c_vdvi_encode[code].bits;
	  if (8 <= state.r_bits) then begin
	    //
	    dec(state.r_bits, 8);
	    pArray(ima_data)[result] := uint8(state.r_ima_byte shr state.r_bits);
	    inc(result);
	  end;
	end;
	//
	if (0 <> state.r_bits) then begin
	  //
	  pArray(ima_data)[result] := uint8(((state.r_ima_byte shl 8) or $FF) shr state.r_bits);
	  inc(result);
	end;
      end;

    end;
  end;
end;

// --  --
function adpcm_decode(var state: una_ADPCM_state; amp: pInt16Array; ima_data: pointer; ima_bytes: int): int;
var
  i: int;
  j: uint8;
  code: uint16;
begin
  result := 0;
  if ((nil <> ima_data) and (nil <> amp) and (4 < ima_bytes)) then begin
    //
    case (state.r_variant) of

      adpcm_IMA4: begin
	//
	amp[0] := int16((pArray(ima_data)[1] shl 8) or pArray(ima_data)[0]);
	state.r_step_index := pArray(ima_data)[2];
	state.r_last := amp[0];
	inc(result);
	//
	for i := 4 to ima_bytes - 1 do begin
	  //
	  amp[result + 0] := decode_sample(state,  pArray(ima_data)[i]        and $F);
	  amp[result + 1] := decode_sample(state, (pArray(ima_data)[i] shr 4) and $F);
	  inc(result, 2);
	end;
      end;

      adpcm_DVI4: begin
	//
	state.r_last := int16((pArray(ima_data)[0] shl 8) or pArray(ima_data)[1]);
	state.r_step_index := pArray(ima_data)[2];
	//
	for i := 4 to ima_bytes - 1 do begin
	  //
	  amp[result + 0] := decode_sample(state, (pArray(ima_data)[i] shr 4) and $F);
	  amp[result + 1] := decode_sample(state,  pArray(ima_data)[i]        and $F);
	  inc(result, 2);
	end;
      end;

      adpcm_VDVI: begin
	//
	state.r_last := int16((pArray(ima_data)[0] shl 8) or pArray(ima_data)[1]);
	state.r_step_index := pArray(ima_data)[2];
	//
	i := 4;
	code := 0;
	state.r_bits := 0;
	while (true) do begin
	  //
	  if (8 >= state.r_bits) then begin
	    //
	    if (i >= ima_bytes) then
	      break;
	    //
	    code := code or ( pArray(ima_data)[i] shl (8 - state.r_bits) );
	    inc(i);
	    inc(state.r_bits, 8);
	  end;
	  //
	  j := 0;
	  while (j < 8) do begin
	    //
	    if ((c_vdvi_decode[j + 0].mask and code) = c_vdvi_decode[j + 0].code) then
	      break;
	    //
	    if ((c_vdvi_decode[j + 8].mask and code) = c_vdvi_decode[j + 8].code) then begin
	      //
	      inc(j, 8);
	      break;
	    end;
	    //
	    inc(j);
	  end;
	  //
	  amp[result] := decode_sample(state, j);
	  inc(result);
	  code := uint16(code shl c_vdvi_decode[j].bits);
	  dec(state.r_bits, c_vdvi_decode[j].bits);
	end;
	//
	while (state.r_bits > 0) do begin
	  //
	  j := 0;
	  while (j < 8) do begin
	    //
	    if ((c_vdvi_decode[j + 0].mask and code) = c_vdvi_decode[j + 0].code) then
	      break;
	    //
	    if ((c_vdvi_decode[j + 8].mask and code) = c_vdvi_decode[j + 8].code) then begin
	      //
	      inc(j, 8);
	      break;
	    end;
	    //
	    inc(j);
	  end;
	  //
	  if (c_vdvi_decode[j].bits > state.r_bits) then
	    break;
	  //
	  amp[result] := decode_sample(state, j);
	  inc(result);
	  code := uint16(code shl c_vdvi_decode[j].bits);
	  dec(state.r_bits, c_vdvi_decode[j].bits);
	end;
      end;

    end;
  end;
end;


{ unaADPCM_coder }

// --  --
procedure unaADPCM_coder.BeforeDestruction();
begin
  inherited;
  //
  mrealloc(f_buf);
end;

// --  --
constructor unaADPCM_coder.create(variant: una_ADPCM_type);
begin
  adpcm_init(f_state, variant);
  //
  inherited create();
end;


{ unaADPCM_encoder }

// --  --
function unaADPCM_encoder.encode(data: pointer; num_samples: int; out buf: pointer): int;
begin
  adpcm_allocbuf_encode(f_state, f_buf, num_samples);
  result := adpcm_encode(f_state, f_buf, data, num_samples);
  buf := f_buf;
end;


{ unaADPCM_decoder }

// --  --
function unaADPCM_decoder.decode(buf: pointer; size: int; out samples: pointer): int;
begin
  adpcm_allocbuf_decode(f_state, pInt16Array(f_buf), size);
  result := adpcm_decode(f_state, f_buf, buf, size) shl 1;
  samples := f_buf;
end;


end.

