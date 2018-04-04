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

	  DSPDLib
	----------------------------------------------
	  Copyright (c) 2006-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		DSP Lib team, Jun-Aug 2006
		
	  modified by:
		Lake, Mar-Apr 2007

	----------------------------------------------

*)


{$i unaDef.inc }

{*
  General purpose DSP library in native Delphi code.

  @Author Delphi conversion by Lake

  2.5.2008.07 Still here
}

unit
  unaDSPDlib;

interface

uses
  Windows, unaTypes, unaDSPLibH, unaClasses;

const
  //
  DSPL_P_TYPE_I = $01000000;	// must not overlap with DSPL_PID and other parameter IDs !!
  DSPL_P_TYPE_F = $02000000;
  DSPL_P_TYPE_C = $03000000;

type
  //
  // --  --
  //
  punaDspDLibParam = ^unaDspDLibParam;
  unaDspDLibParam = packed record
    //
    r_id: dspl_id;
    //
    case int of

      0: (r0_int: dspl_int);
      1: (r1_float: dspl_float);
      2: (r2_chunk: dspl_chunk);

  end;

  // --  --
  unaDspDProcessor = class;

  {*
    This class contains general DSP Lib parameter.
  }
  unaDspDLibParams = class(unaIdList)
  private
    f_processor: unaDspDProcessor;
  protected
    procedure releaseItem(index: int; doFree: unsigned); override;
    function getId(item: pointer): int64; override;
  public
    constructor create(processor: unaDspDProcessor);
  end;


  {*
    This class implements a basic DSP Lib root. It uses methods of unaDspDProcessor class for implementation.
  }
  unaDspDLibRoot = class(unaDspLibAbstract)
  protected
    function dspl_create(object_id: dspl_id): dspl_handle; override;
    function dspl_destroy(handle: dspl_handle): dspl_result; override;
    function dspl_process(handle: dspl_handle; nSamples: dspl_int): dspl_result; override;
    function dspl_version(): pAnsiChar; override;
    //
    function dspl_setf(handle: dspl_handle; param_id: dspl_id; value: dspl_float): dspl_result; override;
    function dspl_seti(handle: dspl_handle; param_id: dspl_id; value: dspl_int): dspl_result; override;
    function dspl_setc(handle: dspl_handle; param_id: dspl_id; chunk: pdspl_float; length: dspl_int): dspl_result; override;
    //
    function dspl_geti(handle: dspl_handle; param: dspl_id): dspl_int; override;
    function dspl_getf(handle: dspl_handle; param: dspl_id): dspl_float; override;
    function dspl_getc(handle: dspl_handle; param: dspl_id): pdspl_chunk; override;
    //
    function dspl_getID(handle: dspl_handle): dspl_int; override;
    //
    function dspl_isseti(handle: dspl_handle; param: dspl_id): dspl_result; override;
    function dspl_issetf(handle: dspl_handle; param: dspl_id): dspl_result; override;
    function dspl_issetc(handle: dspl_handle; param: dspl_id): dspl_result; override;
  public
    constructor create();
  end;


  {*
    This is general purpose DSP Lib processor.
  }
  unaDspDProcessor = class (unaObject)
  private
    f_id: dspl_id;
    f_params: unaDspDLibParams;
  protected
    {$IFDEF DEBUG }
    f_nameFull: AnsiString;
    f_nameShort: AnsiString;
    {$ENDIF DEBUG }
    f_modified: bool;
    //
    function process(nSamples: dspl_int): dspl_result; virtual; abstract;
    function idIsINOUT(id: dspl_id): bool;
  public
    {*
      Creates a DSP Lib processor. ID could be one of the following:
      <UL>
	<LI>(DSPL_OID or DSPL_EQ2B): creates EQ Two Band processor.</LI>
	<LI>(DSPL_OID or DSPL_EQMB): creates EQ Multi-Band processor.</LI>
	<LI>(DSPL_OID or DSPL_LD): creates Level Detector processor.</LI>
	<LI>(DSPL_OID or DSPL_DYNPROC): creates Dynamic Processor.</LI>
	<LI>(DSPL_OID or DSPL_SPEECHPROC): creates Speech Processor.</LI>
	<LI>(DSPL_OID or DSPL_ND): creates Noise Detection processor.</LI>
	<LI>(DSPL_OID or DSPL_MBSP): creates Multi-band Splitter processor.</LI>
      </UL>
    }
    constructor create(id: dspl_id);
    procedure AfterConstruction(); override;
    procedure BeforeDestruction(); override;
    //
    {*
      Sets integer parameter. Parameter ID and value meaning depends on processor type.
    }
    function seti(param_id: dspl_id; value: dspl_int): dspl_result;
    {*
      Sets float parameter. Parameter ID and value meaning depends on processor type.
    }
    function setf(param_id: dspl_id; value: dspl_float): dspl_result;
    {*
      Sets array parameter. Parameter ID and value meaning depends on processor type.
    }
    function setc(param_id: dspl_id; chunk: pdspl_float; length: dspl_int): dspl_result;
    //
    {*
      Returns integer parameter. Parameter ID and value meaning depends on processor type.
    }
    function geti(param_id: dspl_id): dspl_int;
    {*
      Returns float parameter. Parameter ID and value meaning depends on processor type.
    }
    function getf(param_id: dspl_id): dspl_float;
    {*
      Returns array parameter. Parameter ID and value meaning depends on processor type.
    }
    function getc(param_id: dspl_id): pdspl_chunk;
    //
    {*
      Returns true if specified integer parameter is set.
    }
    function isseti(param_id: dspl_id): dspl_result;
    {*
      Returns true if specified float parameter is set.
    }
    function issetf(param_id: dspl_id): dspl_result;
    {*
      Returns true if specified array parameter is set.
    }
    function issetc(param_id: dspl_id): dspl_result;
    //
    {*
      Returns processor's ID.
    }
    property id: dspl_id read f_id;
    //
    {$IFDEF DEBUG }
    property nameFull: AnsiString read f_nameFull;
    property nameShort: AnsiString read f_nameShort;
    {$ENDIF DEBUG }
  end;


  {*
    Two Band Parametric Equalizer
  }
  unaDspDL_EQ2B = class(unaDspDProcessor)
  private
    f1in1, f1in2, f1out1, f1out2,
    f2in1, f2in2, f2out1, f2out2: dspl_float;
    //
    biq_f1: pdspl_biq_values;
    biq_f2: pdspl_biq_values;
    biq_f1_buff_size: dspl_int;
    biq_f2_buff_size: dspl_int;
    //
    function prepare_biq(band, len: dspl_int; var step: dspl_int; buf: pdspl_biq_values; var buff_size: dspl_int): pdspl_biq_values;
  protected
    function process(nSamples: dspl_int): dspl_result; override;
  public
    constructor create();
    procedure AfterConstruction(); override;
    procedure BeforeDestruction(); override;
  end;


  {*
    Multiband Equalizer/Filter
  }
  unaDspDL_EQMB = class(unaDspDProcessor)
  private
    //
    num_filtres: dspl_int;
    hpfs: pdspl_biq_valuesArray;
    acc,   bcc: pFloatArray;
    zin1,  zin2,
    zout1, zout2: pFloatArray;
    //
    buffer_length: dspl_int;
  protected
    function process(nSamples: dspl_int): dspl_result; override;
  public
    constructor create();
    procedure AfterConstruction(); override;
    procedure BeforeDestruction(); override;
  end;


  {*
    Level Detector
  }
  unaDspDL_LD = class(unaDspDProcessor)
  private
    peak_buffer: pDoubleArray;
    //
    peak_value,
    alpha,
    beta: dspl_double;
    //
    ld_out: dspl_double;
    peak_pos: dspl_int;
    pb_pos: dspl_int;
    pb_size: dspl_int;
    //
    ld_peak: bool;
  protected
    function process(nSamples: dspl_int): dspl_result; override;
  public
    constructor create();
    procedure AfterConstruction(); override;
    procedure BeforeDestruction(); override;
  end;


  {*
    Multiband Splitter
  }
  unaDspDL_MbSp = class(unaDspDProcessor)
  private
    num_bands: dspl_int;
    num_filtres: dspl_int;
    hi_order: dspl_int;
    hpfs: pdspl_biq_valuesArray;
    //
    mout: pFloatArrayPArray;
    acc: pFloatArray;
    bcc: pFloatArray;
    gain_ref: dspl_float;
    zin1,  zin2,  zout1,  zout2:  pFloatArray;
    z2in1, z2in2, z2out1, z2out2: pFloatArray;
    //
    buffer_length: dspl_int;
  protected
    function process(nSamples: dspl_int): dspl_result; override;
  public
    constructor create();
    procedure AfterConstruction(); override;
    procedure BeforeDestruction(); override;
  end;


  {*
    Noise Level Detector
  }
  unaDspDL_ND = class(unaDspDProcessor)
  private
    bp: unaDspDL_EQ2B;
    bl: unaDspDL_LD;
    sl: unaDspDL_LD;
    pl: unaDspDL_LD;
    //
    bl_buf: pdspl_float;
    sl_buf: pdspl_float;
    bp_buf: pdspl_float;
    pl_buf: pdspl_float;
    //
    lr: dspl_float;
    sensivity: dspl_float;
    noise_level: dspl_float;
    dr: dspl_float;
    smoothing: dspl_float;
    //
    buffer_length: dspl_int;
  protected
    function process(nSamples: dspl_int): dspl_result; override;
  public
    constructor create();
    procedure AfterConstruction(); override;
    procedure BeforeDestruction(); override;
  end;


  {*
    Dynamic Processor
  }
  unaDspDL_DynProc = class(unaDspDProcessor)
  private
    level_detector: unaDspDL_LD;
    //
    ld_buffer: pdspl_float;
    ld_buffer_size: dspl_int;
    //
    alpha, beta, th,
    aratio_inv, bratio_inv, ascale, bscale,
    gain_env, gr_env: dspl_double;
    //
    nsot: dspl_int;
  protected
    function process(nSamples: dspl_int): dspl_result; override;
  public
    constructor create();
    procedure AfterConstruction(); override;
    procedure BeforeDestruction(); override;
  end;


  {*
    Speech Processor
  }
  unaDspDL_SpeechProc = class(unaDspDProcessor)
  private
    hp: unaDspDL_EQ2B;
    enh: unaDspDL_EQ2B;
    //
    agc: unaDspDL_DynProc;
    comp: unaDspDL_DynProc;
    ng: unaDspDL_DynProc;
    lim: unaDspDL_DynProc;
    ds: unaDspDL_DynProc;
    //
    acca: pdspl_float;
    accb: pdspl_float;
    hp_out: pdspl_float;
    la_buf: pdspl_float;
    la_in: pdspl_float;
    //
    buffer_length: dspl_int;
    la_size: dspl_int;
    la_pos: dspl_int;
  protected
    function process(nSamples: dspl_int): dspl_result; override;
  public
    constructor create();
    procedure AfterConstruction(); override;
    procedure BeforeDestruction(); override;
  end;


implementation


uses
  unaUtils, Math;


{ unaDspDLibParams }

// --  --
constructor unaDspDLibParams.create(processor: unaDspDProcessor);
begin
  f_processor := processor;
  //
  inherited create(uldt_ptr);
  autoFree := true;
end;

// --  --
function unaDspDLibParams.getId(item: pointer): int64;
begin
  if (nil <> item) then
    result := punaDspDLibParam(item).r_id
  else
    result := 0;
end;

// --  --
procedure unaDspDLibParams.releaseItem(index: int; doFree: unsigned);
var
  p: pointer;
  id: dspl_int;
begin
  if (mapDoFree(doFree)) then begin
    //
    p := get(index);
    if (p <> nil) then
      id := punaDspDLibParam(p).r_id
    else
      id := 0;
    //
    if (
	(nil <> p) and
	(nil <> punaDspDLibParam(p).r2_chunk.r_fp) and
	(DSPL_P_TYPE_C = ($0F000000 and id)) and
	(not f_processor.idIsINOUT(id))
       ) then begin
      // IN/OUT buffers are always assigned by value, so no additional memory is taken
      // other buffers are allocated by copy, so we need to release the memory
      //
      mrealloc(punaDspDLibParam(p).r2_chunk.r_fp);
    end;
    //
    mrealloc(p);
  end;
end;


// biquad coefficients calculation
//
procedure dspl_biq(btype: dspl_int; gain: dspl_float; w: dspl_float; q: dspl_float; var r: dspl_biq_values; norm: bool);
var
  A: dspl_double;
  w2pi: dspl_double;
  cosw: dspl_double;
  sinw: dspl_double;
  alpha: dspl_double;
  alpha_div_a: dspl_double;
  alpha2sqrtA: dspl_double;
  a0_1: dspl_double;
begin
  //const dspl_double pi=2.0*asin(1);
  try
    //
    A := pow(gain, 0.5);
    w2pi := 2 * pi * w;
    cosw := cos(w2pi);
    sinw := sin(w2pi);
    alpha := sinw / (2 * q);
    //
    case (btype) of

      //
      DSPL_BIQ_LP: begin
	//
	r.b1 := 1.0 - cosw;
	r.b0 := 0.5 * r.b1;
	r.b2 := r.b0;
	//
	r.a0 := 1.0 + alpha;
	r.a1 := -2.0 * cosw;
	r.a2 := 1.0 - alpha;
      end;

      //
      DSPL_BIQ_HP: begin
	//
	r.b1 := -cosw - 1.0;
	r.b0 := -0.5 * r.b1;
	r.b2 := r.b0;
	//
	r.a0 := 1.0 + alpha;
	r.a1 := -2.0 * cosw;
	r.a2 := 1.0 - alpha;
      end;

      //
      DSPL_BIQ_PEAK: begin
	//
	alpha_div_a := alpha / A;
	//
	r.b0 := 1.0 + alpha * A;
	r.b1 := -2.0 * cosw;
	r.b2 := 1.0 - alpha * A;
	//
	r.a0 := 1.0 + alpha_div_a;
	r.a1 := r.b1;
	r.a2 := 1.0 - alpha_div_a;
      end;

      //
      DSPL_BIQ_LS: begin
	//
	alpha2sqrtA := 2.0 * pow(A, 0.5) * alpha;
	//
	r.b0 :=       A * ((A + 1.0) - (A - 1.0) * cosw + alpha2sqrtA);
	r.b1 := 2.0 * A * ((A - 1.0) - (A + 1.0) * cosw);
	r.b2 :=       A * ((A + 1.0) - (A - 1.0) * cosw - alpha2sqrtA);
	//
	r.a0 :=            (A + 1.0) + (A - 1.0) * cosw + alpha2sqrtA;
	r.a1 :=    -2.0 * ((A - 1.0) + (A + 1.0) * cosw );
	r.a2 :=            (A + 1.0) + (A - 1.0) * cosw - alpha2sqrtA;
      end;

      DSPL_BIQ_HS: begin
	//
	alpha2sqrtA := 2.0 * pow(A, 0.5) * alpha;
	r.b0 :=        A * ((A + 1.0) + (A - 1.0) * cosw + alpha2sqrtA);
	r.b1 := -2.0 * A * ((A - 1.0) + (A + 1.0) * cosw);
	r.b2 :=        A * ((A + 1.0) + (A - 1.0) * cosw - alpha2sqrtA);
	r.a0 :=             (A + 1.0) - (A - 1.0) * cosw + alpha2sqrtA;
	r.a1 :=      2.0 * ((A - 1.0) - (A + 1.0) * cosw);
	r.a2 :=             (A + 1.0) - (A - 1.0) * cosw - alpha2sqrtA;
      end;

    end;	// case

    //
    if (norm) then begin
      //
      a0_1 := 1.0 / r.a0;
      //
      r.a0 := 1.0;
      r.b0 := r.b0 * a0_1;
      r.b1 := r.b1 * a0_1;
      r.b2 := r.b2 * a0_1;
      r.a1 := r.a1 * (-a0_1);
      r.a2 := r.a2 * (-a0_1);
    end;
    //
  except
    r.a0 := 1.0;
    r.b0 := 0.0;
    r.b1 := 0.0;
    r.a1 := 0.0;
    r.a2 := 0.0;
  end;
end;



{ unaDspDLibRoot }

// --  --
constructor unaDspDLibRoot.create();
begin
  f_libResult := DSPL_SUCCESS;	// "library" is always linked into code
  //
  inherited create();
end;

// --  --
function unaDspDLibRoot.dspl_create(object_id: dspl_id): dspl_handle;
begin
  case (object_id) of

    (DSPL_OID or DSPL_EQ2B):
      result := dspl_handle(unaDspDL_EQ2B.create());

    (DSPL_OID or DSPL_EQMB):
      result := dspl_handle(unaDspDL_EQMB.create());

    (DSPL_OID or DSPL_LD): begin
      result := dspl_handle(unaDspDL_LD.create());
    end;

    (DSPL_OID or DSPL_DYNPROC):
      result := dspl_handle(unaDspDL_DynProc.create());

    (DSPL_OID or DSPL_SPEECHPROC):
      result := dspl_handle(unaDspDL_SpeechProc.create());

    (DSPL_OID or DSPL_ND): begin
      result := dspl_handle(unaDspDL_ND.create());
    end;

    (DSPL_OID or DSPL_MBSP):
      result := dspl_handle(unaDspDL_MBSP.create());

    else
      result := DSPL_INVALID_HANDLE;

  end
end;

// --  --
function unaDspDLibRoot.dspl_destroy(handle: dspl_handle): dspl_result;
begin
  freeAndNil(handle);
  //
  result := DSPL_SUCCESS;
end;

// --  --
function unaDspDLibRoot.dspl_getc(handle: dspl_handle; param: dspl_id): pdspl_chunk;
begin
  assert(0 <> handle);
  result := unaDspDProcessor(handle).getc(param);
end;

// --  --
function unaDspDLibRoot.dspl_getf(handle: dspl_handle; param: dspl_id): dspl_float;
begin
  assert(0 <> handle);
  result := unaDspDProcessor(handle).getf(param);
end;

// --  --
function unaDspDLibRoot.dspl_geti(handle: dspl_handle; param: dspl_id): dspl_int;
begin
  assert(0 <> handle);
  result := unaDspDProcessor(handle).geti(param);
end;

// --  --
function unaDspDLibRoot.dspl_getID(handle: dspl_handle): dspl_int;
begin
  assert(0 <> handle);
  result := unaDspDProcessor(handle).id;
end;

// --  --
function unaDspDLibRoot.dspl_issetc(handle: dspl_handle; param: dspl_id): dspl_result;
begin
  assert(0 <> handle);
  result := unaDspDProcessor(handle).issetc(param);
end;

// --  --
function unaDspDLibRoot.dspl_issetf(handle: dspl_handle; param: dspl_id): dspl_result;
begin
  assert(0 <> handle);
  result := unaDspDProcessor(handle).issetf(param);
end;

// --  --
function unaDspDLibRoot.dspl_isseti(handle: dspl_handle; param: dspl_id): dspl_result;
begin
  assert(0 <> handle);
  result := unaDspDProcessor(handle).isseti(param);
end;

// --  --
function unaDspDLibRoot.dspl_process(handle: dspl_handle; nSamples: dspl_int): dspl_result;
begin
  assert(0 <> handle);
  result := unaDspDProcessor(handle).process(nSamples);
end;

// --  --
function unaDspDLibRoot.dspl_setc(handle: dspl_handle; param_id: dspl_id; chunk: pdspl_float; length: dspl_int): dspl_result;
begin
  assert(0 <> handle);
  result := unaDspDProcessor(handle).setc(param_id, chunk, length)
end;

// --  --
function unaDspDLibRoot.dspl_setf(handle: dspl_handle; param_id: dspl_id; value: dspl_float): dspl_result;
begin
  assert(0 <> handle);
  result := unaDspDProcessor(handle).setf(param_id, value)
end;

// --  --
function unaDspDLibRoot.dspl_seti(handle: dspl_handle; param_id: dspl_id; value: dspl_int): dspl_result;
begin
  assert(0 <> handle);
  result := unaDspDProcessor(handle).seti(param_id, value)
end;

// --  --
function unaDspDLibRoot.dspl_version(): pAnsiChar;
begin
  result := '1.D.02';
end;



{ unaDspDProcessor }

// --  --
procedure unaDspDProcessor.AfterConstruction();
begin
  f_modified := true;
  //
  inherited;
end;

// --  --
procedure unaDspDProcessor.BeforeDestruction;
begin
  inherited;
  //
  freeAndNil(f_params);
end;

// --  --
constructor unaDspDProcessor.create(id: dspl_id);
begin
  f_id := id;
  //
  f_params := unaDspDLibParams.create(self);
  //
  inherited create();
end;

// --  --
function unaDspDProcessor.getc(param_id: dspl_id): pdspl_chunk;
var
  p: punaDspDLibParam;
begin
  p := f_params.itemById(param_id or DSPL_P_TYPE_C);
  if (nil <> p) then
    result := @p.r2_chunk
  else
    result := nil;
end;

// --  --
function unaDspDProcessor.getf(param_id: dspl_id): dspl_float;
var
  p: punaDspDLibParam;
begin
  p := f_params.itemById(param_id or DSPL_P_TYPE_F);
  if (nil <> p) then
    result := p.r1_float
  else
    result := 0;
end;

// --  --
function unaDspDProcessor.geti(param_id: dspl_id): dspl_int;
var
  p: punaDspDLibParam;
begin
  p := f_params.itemById(param_id or DSPL_P_TYPE_I);
  if (nil <> p) then
    result := p.r0_int
  else
    result := 0;
end;

// --  --
function unaDspDProcessor.idIsINOUT(id: dspl_id): bool;
begin
  result :=
    (DSPL_P_TYPE_C = ($0F000000 and id))
    and
    (
      ( DSPL_PID or DSPL_P_IN   = (id and $F0F00) )
      or
      ( DSPL_PID or DSPL_P_OUT  = (id and $F0F00) )
    );
end;

// --  --
function unaDspDProcessor.issetc(param_id: dspl_id): dspl_result;
begin
  result := (nil <> f_params.itemById(param_id or DSPL_P_TYPE_C));
end;

// --  --
function unaDspDProcessor.issetf(param_id: dspl_id): dspl_result;
begin
  result := (nil <> f_params.itemById(param_id or DSPL_P_TYPE_F));
end;

// --  --
function unaDspDProcessor.isseti(param_id: dspl_id): dspl_result;
begin
  result := (nil <> f_params.itemById(param_id or DSPL_P_TYPE_I));
end;

// --  --
function unaDspDProcessor.setc(param_id: dspl_id; chunk: pdspl_float; length: dspl_int): dspl_result;
var
  p: punaDspDLibParam;
  sz: int;
begin
  p := f_params.itemById(param_id or DSPL_P_TYPE_C);
  if (nil = p) then begin
    //
    p := malloc(sizeOf(p^), true, 0);
    p.r_id := param_id or DSPL_P_TYPE_C;
    //
    f_params.add(p);
  end;
  //
  if (idIsINOUT(p.r_id)) then begin
    //
    // IN/OUT buffers are always assigned by value, and no new memory is allocated
    //
    p.r2_chunk.r_fp := chunk;
    p.r2_chunk.r_len := length;
  end
  else begin
    // other buffers are always assigned by copy, so new memory is allocated
    //
    sz := length * sizeOf(p.r2_chunk.r_fp^);
    if (length <= p.r2_chunk.r_len) then begin
      //
      // because new chunk may be assigned using "old" chunk pointer,
      // in case of buffer shrinking we need to copy old values first.
      // If "new" chunk pointer was passed, we copy the values anyway
      if ((0 < sz) and (nil <> chunk)) then
	move(chunk^, p.r2_chunk.r_fp^, sz);
    end;
    //
    // Existing data in the block is not affected by the reallocation
    mrealloc(p.r2_chunk.r_fp, sz);
    //
    if ((0 < sz) and (nil <> chunk) and (length > p.r2_chunk.r_len)) then begin
      //
      // since "old" chunk pointer cannot (should not) be used to address a
      // larger buffer we may safely copy the entire data here
      move(chunk^, p.r2_chunk.r_fp^, sz);
    end;
    //
    p.r2_chunk.r_len := length;
  end;
  //
  result := DSPL_SUCCESS;
  f_modified := true;
end;

// --  --
function unaDspDProcessor.setf(param_id: dspl_id; value: dspl_float): dspl_result;
var
  p: punaDspDLibParam;
begin
  p := f_params.itemById(param_id or DSPL_P_TYPE_F);
  if (nil = p) then begin
    //
    p := malloc(sizeOf(p^));
    p.r_id := param_id or DSPL_P_TYPE_F;
    //
    f_params.add(p);
  end;
  //
  p.r1_float := value;
  //
  result := DSPL_SUCCESS;
  f_modified := true;
end;

// --  --
function unaDspDProcessor.seti(param_id: dspl_id; value: dspl_int): dspl_result;
var
  p: punaDspDLibParam;
begin
  p := f_params.itemById(param_id or DSPL_P_TYPE_I);
  if (nil = p) then begin
    //
    p := malloc(sizeOf(p^));
    p.r_id := param_id or DSPL_P_TYPE_I;
    //
    f_params.add(p);
  end;
  //
  p.r0_int := value;
  //
  result := DSPL_SUCCESS;
  f_modified := true;
end;


{ unaDspDL_EQ2B }

// --  --
procedure unaDspDL_EQ2B.AfterConstruction();
begin
  inherited;
  //
//  seti(DSPL_PID or DSPL_P_NFRQ or DSPL_EQ2B_BOTH, DSPL_DEFAULT_SAMPLING_FRQ);
  //
  seti(DSPL_PID or DSPL_P_TYPE or DSPL_EQ2B_BAND1, DSPL_EQ2B_OFF);
  seti(DSPL_PID or DSPL_P_TYPE or DSPL_EQ2B_BAND2, DSPL_EQ2B_OFF);
  //
  setf(DSPL_PID or DSPL_P_FRQ or DSPL_EQ2B_BAND1, 500.0 / DSPL_DEFAULT_SAMPLE_FRQ);
  setf(DSPL_PID or DSPL_P_FRQ or DSPL_EQ2B_BAND2, 2000.0 / DSPL_DEFAULT_SAMPLE_FRQ);

  setc(DSPL_PID or DSPL_P_FRQ or DSPL_EQ2B_BAND1, nil, 0);
  setc(DSPL_PID or DSPL_P_FRQ or DSPL_EQ2B_BAND2, nil, 0);

  setf(DSPL_PID or DSPL_P_GAIN or DSPL_EQ2B_BAND1, db2v(0.0));
  setf(DSPL_PID or DSPL_P_GAIN or DSPL_EQ2B_BAND2, db2v(0.0));

  setc(DSPL_PID or DSPL_P_GAIN or DSPL_EQ2B_BAND1, nil, 0);
  setc(DSPL_PID or DSPL_P_GAIN or DSPL_EQ2B_BAND2, nil, 0);

  setf(DSPL_PID or DSPL_P_Q or DSPL_EQ2B_BAND1, 1.0);
  setf(DSPL_PID or DSPL_P_Q or DSPL_EQ2B_BAND2, 1.0);

  setc(DSPL_PID or DSPL_P_Q or DSPL_EQ2B_BAND1, nil, 0);
  setc(DSPL_PID or DSPL_P_Q or DSPL_EQ2B_BAND2, nil, 0);

  setc(DSPL_PID or DSPL_P_IN or DSPL_EQ2B_BOTH, nil, 0);
  setc(DSPL_PID or DSPL_P_OUT or DSPL_EQ2B_BOTH, nil, 0);
end;

// --  --
procedure unaDspDL_EQ2B.BeforeDestruction();
begin
  inherited;
  //
  biq_f1_buff_size := 0;
  biq_f2_buff_size := 0;
  //
  mrealloc(biq_f1);
  mrealloc(biq_f2);
end;

// --  --
function unaDspDL_EQ2B.process(nSamples: dspl_int): dspl_result;
var
  t: int;
  in0: pFloatArray;
  out0: pFloatArray;
  in0p: int;
  out0p: int;
  in_len: int;
  out_len: int;
  f1biq_step,
  f2biq_step: dspl_int;
  f1on: bool;
  f2on: bool;
  f1: pdspl_biq_values;
  f2: pdspl_biq_values;
  //
  f1in: dspl_double;
  f1out: dspl_double;
  f2out: dspl_double;
begin
  in0  := pFloatArray(getc(DSPL_PID or DSPL_P_IN or DSPL_EQ2B_BOTH).r_fp);
  out0 := pFloatArray(getc(DSPL_PID or DSPL_P_OUT or DSPL_EQ2B_BOTH).r_fp);
  //
  in_len  := getc(DSPL_PID or DSPL_P_IN  or DSPL_EQ2B_BOTH).r_len;
  out_len := getc(DSPL_PID or DSPL_P_OUT or DSPL_EQ2B_BOTH).r_len;
  //
  if ((nil = in0) or (nil = out0) or (1 > out_len) or (in_len <> out_len)) then
    result := DSPL_FAILURE
  else begin
    //
    if (out_len < nSamples) then
      nSamples := out_len;
    //
    f1biq_step :=0;
    f2biq_step :=0;
    //
    f1on := (DSPL_EQ2B_OFF <> geti(DSPL_PID or DSPL_P_TYPE or DSPL_EQ2B_BAND1));
    f2on := (DSPL_EQ2B_OFF <> geti(DSPL_PID or DSPL_P_TYPE or DSPL_EQ2B_BAND2));
    //
    f1 := nil;
    f2 := nil;
    //
    if (f1on) then begin
      //
      biq_f1 := prepare_biq(DSPL_EQ2B_BAND1, nSamples, f1biq_step, biq_f1, biq_f1_buff_size);
      f1 := biq_f1;
    end;
    //
    if (f2on) then begin
      //
      biq_f2 := prepare_biq(DSPL_EQ2B_BAND2, nSamples, f2biq_step, biq_f2, biq_f2_buff_size);
      f2 := biq_f2;
    end;
    //
    in0p := 0;
    out0p := 0;
    //
    for t := 0 to nSamples - 1 do begin
      //
      f1in := in0[in0p];
      if (f1on) then
	f1out := (f1.b0 * f1in   +
		  f1.b1 * f1in1  +
		  f1.b2 * f1in2  +
		  f1.a1 * f1out1 +
		  f1.a2 * f1out2
		 )
      else
	f1out := f1in;
      //
      f1in2 := f1in1;
      f1in1 := f1in;
      f1out2 := f1out1;
      f1out1 := f1out;
      //
      if (f2on) then
	f2out := (f2.b0 * f1out  +
		  f2.b1 * f2in1  +
		  f2.b2 * f2in2  +
		  f2.a1 * f2out1 +
		  f2.a2 * f2out2
		 )
      else
	f2out := f1out;
      //
      f2in2 := f2in1;
      f2in1 := f1out;
      f2out2 := f2out1;
      f2out1 := f2out;
      //
      out0[out0p] := f2out;
      //
      inc(in0p);
      inc(out0p);
      //
      inc(f1, f1biq_step);
      inc(f2, f2biq_step);
    end;
    //
    f_modified := false;
    //
    result := DSPL_SUCCESS;
  end;
end;

// --  --
function unaDspDL_EQ2B.prepare_biq(band: dspl_int; len: dspl_int; var step: dspl_int; buf: pdspl_biq_values; var buff_size: dspl_int): pdspl_biq_values;
var
  t: int;
  btype: dspl_int;
  gain_c, frq_c, q_c: dspl_float;
  gain_s, frq_s, q_s: dspl_int;
  gain, frq, q: pdspl_float;
  b: pdspl_biq_values;
begin
  if ((nil = getc(DSPL_PID or DSPL_P_GAIN or band).r_fp) and
      (nil = getc(DSPL_PID or DSPL_P_Q or band).r_fp) and
      (nil = getc(DSPL_PID or DSPL_P_FRQ or band).r_fp)
     ) then begin
    //
    // -- static biq --
    //
    if (f_modified) then begin
      //
      if (1 <> buff_size) then begin
	//
	mrealloc(buf, sizeOf(buf^));
	buff_size := 1;
      end;
      //
      dspl_biq(geti(DSPL_PID or DSPL_P_TYPE or band),
	       getf(DSPL_PID or DSPL_P_GAIN or band),
	       getf(DSPL_PID or DSPL_P_FRQ or band),
	       getf(DSPL_PID or DSPL_P_Q or band),
	       buf^,
	       true
	      );
      //
    end;
    //
    step := 0;
  end
  else begin
    //
    // -- dynamic biq --
    //
    if (buff_size < len) then begin
      //
      mrealloc(buf, sizeOf(buf^) * len);
      buff_size := len;
    end;
    //
    btype := geti(DSPL_PID or DSPL_P_TYPE or band);
    gain_s := 1;
    frq_s := 1;
    q_s := 1;
    //
    gain := getc(DSPL_PID or DSPL_P_GAIN or band).r_fp;
    frq := getc(DSPL_PID or DSPL_P_FRQ or band).r_fp;
    q := getc(DSPL_PID or DSPL_P_Q or band).r_fp;
    //
    if (nil = gain) then begin
      //
      gain_s := 0;
      gain_c := getf(DSPL_PID or DSPL_P_GAIN or band);
      gain := @gain_c;
    end;
    //
    if (nil = frq) then begin
      //
      frq_s := 0;
      frq_c := getf(DSPL_PID or DSPL_P_FRQ or band);
      frq := @frq_c;
    end;
    //
    if (nil = q) then begin
      //
      q_s := 0;
      q_c := getf(DSPL_PID or DSPL_P_Q or band);
      q := @q_c;
    end;
    //
    if (0 < len) then begin
      //
      b := buf;
      for t := 0 to len - 1 do begin
	//
	dspl_biq(btype, gain^, frq^, q^, b^, true);
	//
	inc(gain, gain_s);
	inc(frq, frq_s);
	inc(q, q_s);
	inc(b, t);
      end;
    end;
    //
    step := 1;
  end;
  //
  result := buf;
end;

// --  --
constructor unaDspDL_EQ2B.create();
begin
  {$IFDEF DEBUG }
  f_nameFull := c_DSPL_OBJNAMES_FULL[DSPL_EQ2B];
  f_nameShort := c_DSPL_OBJNAMES_SHORT[DSPL_EQ2B];
  {$ENDIF }
  //
  biq_f1 := nil;
  biq_f2 := nil;
  biq_f1_buff_size := 0;
  biq_f2_buff_size := 0;
  //
  f1in1 := 0;
  f1in2 := 0;
  f1out1 := 0;
  f1out2 := 0;
  f2in1 := 0;
  f2in2 := 0;
  f2out1 := 0;
  f2out2 := 0;
  //
  inherited create(DSPL_OID or DSPL_EQ2B);
end;


{ unaDspDL_EQMB }

// --  --
procedure unaDspDL_EQMB.AfterConstruction();
begin
  seti(DSPL_PID or DSPL_P_OTHER or 0, 0);
  //
  setc(DSPL_PID or DSPL_P_FRQ  or 0, nil, 0);
  setc(DSPL_PID or DSPL_P_GAIN or 0, nil, 0);
  //
  setc(DSPL_PID or DSPL_P_IN   or 0, nil, 0);
  setc(DSPL_PID or DSPL_P_OUT  or 0, nil, 0);
  //
  inherited;
end;

// --  --
procedure unaDspDL_EQMB.BeforeDestruction();
begin
  inherited;
  //
  mrealloc(hpfs);
  mrealloc(zin1);
  mrealloc(zin2);
  mrealloc(zout1);
  mrealloc(zout2);
  mrealloc(acc);
  mrealloc(bcc);
end;

// --  --
constructor unaDspDL_EQMB.create();
begin
  {$IFDEF DEBUG }
  f_nameFull := c_DSPL_OBJNAMES_FULL[DSPL_EQMB];
  f_nameShort := c_DSPL_OBJNAMES_SHORT[DSPL_EQMB];
  {$ENDIF }
  //
  num_filtres := 0;
  //
  hpfs := nil;
  zin1 := nil;
  zin2 := nil;
  //
  zout1 := nil;
  zout2 := nil;
  acc := nil;
  bcc := nil;
  //
  buffer_length := 0;
  //
  inherited create(DSPL_OID or DSPL_EQMB);
end;

// --  --
procedure dspl_eqmb_filter(var hpf: dspl_biq_values; fin: pFloatArray; fout: pFloatArray; var zin1: dspl_float; var zin2: dspl_float; var zout1: dspl_float; var zout2: dspl_float; length: dspl_int);
var
  fin1,
  fin2,
  fout1,
  fout2: dspl_float;
  i, j: int;
begin
  // save filter  state
  fin1 := zin1;
  fin2 := zin2;
  fout1 := zout1;
  fout2 := zout2;
  //
  i := 0;
  j := length;
  while (j > 0) do begin
    //
    dec(j);
    //
    fout[i] := hpf.b0 * fin[i] + hpf.b1 * fin1 + hpf.b2 * fin2 + hpf.a1 * fout1 + hpf.a2 * fout2;
    //
    fin2 := fin1;
    fin1 := fin[i];
    fout2 := fout1;
    fout1 := fout[i];
    //
    inc(i);
  end;
  //
  // restoring filter state
  zin1 := fin1;
  zin2 := fin2;
  zout1 := fout1;
  zout2 := fout2;
end;

// --  --
function unaDspDL_EQMB.process(nSamples: dspl_int): dspl_result;
var
  //max_slope: dspl_float;
  inf: pFloatArray;
  outf: pFloatArray;
  a, b: pFloatArray;
  in_len: int;
  i: int;
  frqs: pFloatArray;
  gain: pFloatArray;
  fl: dspl_float;
  w: dspl_float;
begin
  //  max_slope := pow(2.0, -0.5);
  //
  inf :=  pFloatArray(getc(DSPL_PID or DSPL_P_IN).r_fp);
  outf := pFloatArray(getc(DSPL_PID or DSPL_P_OUT).r_fp);
  //
  result := DSPL_SUCCESS;
  //
  in_len := getc(DSPL_PID or DSPL_P_IN).r_len;
  if (in_len < nSamples) then
    //
    result := DSPL_FAILURE
  else begin
    //
    if (f_modified) then begin
      //
      if (in_len <> getc(DSPL_PID or DSPL_P_OUT).r_len) then
	//
	result := DSPL_FAILURE
      else begin
	//
	if (num_filtres <> geti(DSPL_PID or DSPL_P_OTHER)) then begin
	  //
	  num_filtres := geti(DSPL_PID or DSPL_P_OTHER);
	  if ((num_filtres < 1) or (num_filtres > 32)) then
	    //
	    result := DSPL_FAILURE
	  else begin
	    //
	    mrealloc(hpfs,  sizeOf(hpfs[0]) * num_filtres);
	    //
	    mrealloc(zin1,  sizeOf(zin1[0])  * num_filtres);
	    mrealloc(zin2,  sizeOf(zin2[0])  * num_filtres);
	    mrealloc(zout1, sizeOf(zout1[0]) * num_filtres);
	    mrealloc(zout2, sizeOf(zout2[0]) * num_filtres);
	    //
	    for i := 0 to num_filtres - 1 do begin
	      //
	      zin1[i] := 0.0;
	      zin2[i] := 0.0;
	      zout1[i] := 0.0;
	      zout2[i] := 0.0;
	    end;
	    //
	  end;
	end;
	//
	if (DSPL_SUCCESS = result) then
	  if (getc(DSPL_PID or DSPL_P_FRQ).r_len < num_filtres) then
	    result := DSPL_FAILURE;
	//
	if (DSPL_SUCCESS = result) then
	  if (getc(DSPL_PID or DSPL_P_GAIN).r_len < num_filtres) then
	    result := DSPL_FAILURE;
	//
	if (DSPL_SUCCESS = result) then begin
	  // prepare filter coefs
	  frqs := pFloatArray(getc(DSPL_PID or DSPL_P_FRQ).r_fp);
	  gain := pFloatArray(getc(DSPL_PID or DSPL_P_GAIN).r_fp);
	  //
	  for i := 0 to num_filtres - 1 do begin
	    //
	    if ((frqs[i] < 1e-10) or (frqs[i] > 1.0)) then begin
	      //
	      result := DSPL_FAILURE;
	      break;
	    end;
	    //
	    if ((i > 0) and (i < num_filtres - 1)) then
	      //
	      fl := max(frqs[i] / frqs[i - 1], frqs[i + 1] / frqs[i])
	    else
	      if (i = 0) then
		fl := frqs[i + 1] / frqs[i]
	      else
		fl := frqs[i] / frqs[i - 1];
	    //
	    w := 2.0 * pi * frqs[i];
	    //
	    dspl_biq(DSPL_BIQ_PEAK, gain[i], frqs[i], 0.5 / (sinh(log2(fl) * 0.5 * w / sin(w))), hpfs[i], true);
	  end;
	  //
	  if (DSPL_SUCCESS = result) then begin
	    //
	    if (buffer_length <> in_len) then begin
	      //
	      buffer_length := in_len;
	      mrealloc(acc, sizeOf(acc[0]) * buffer_length);
	      //
	      mrealloc(bcc, sizeOf(bcc[0]) * buffer_length);
	    end;
	  end;
	  //
	end;
      end;	// if (in_len is OK)
    end;	// if (modified) then ...
    //
    if (DSPL_SUCCESS = result) then begin
      //
      for i := 0 to num_filtres - 1 do begin
	//
	if (0 = i) then
	  a := inf
	else
	  if (0 = (i and $01)) then
	    a := bcc
	  else
	    a := acc;
	//
	if (i = num_filtres - 1) then
	  b := outf
	else
	  if (0 = (i and $1)) then
	    b := acc
	  else
	    b := bcc;

	//
	dspl_eqmb_filter(hpfs[i], a, b, zin1[i], zin2[i], zout1[i], zout2[i], nSamples);
      end;
      //
      f_modified := false;
    end;
  end;
end;


{ unaDspDL_LD }

// --  --
procedure unaDspDL_LD.AfterConstruction();
begin
  setc(DSPL_PID or DSPL_P_IN,  nil, 0);
  setc(DSPL_PID or DSPL_P_OUT, nil, 0);
  //
  seti(DSPL_PID or DSPL_P_TYPE, DSPL_LD_RMS);
  //
  setf(DSPL_PID or DSPL_P_ATTACK,  44.1);
  setf(DSPL_PID or DSPL_P_RELEASE, 88.2);
  setf(DSPL_PID or DSPL_P_OTHER,   0.0);
  //
  inherited;
end;

// --  --
procedure unaDspDL_LD.BeforeDestruction();
begin
  inherited;
  //
  mrealloc(peak_buffer);
end;

// --  --
constructor unaDspDL_LD.create();
begin
  {$IFDEF DEBUG }
  f_nameFull := c_DSPL_OBJNAMES_FULL[DSPL_LD];
  f_nameShort := c_DSPL_OBJNAMES_SHORT[DSPL_LD];
  {$ENDIF }
  //
  peak_buffer := nil;
  pb_size := 0;
  ld_out := 0.0;
  //
  inherited create(DSPL_OID or DSPL_LD);
end;

// --  --
function unaDspDL_LD.process(nSamples: dspl_int): dspl_result;
var
  gain6db: dspl_float;
  in_chunk: pdspl_chunk;
  out_chunk: pdspl_chunk;
  ina: pdspl_float;
  outa: pdspl_float;
  out_len: dspl_int;
  attack_samples: dspl_float;
  release_samples: dspl_float;
  pb_samples: dspl_float;
  i, t: dspl_int;
  ld_in: dspl_double;
  theta: dspl_double;
begin
  gain6db := db2v(+6.0);
  //
  in_chunk  := getc(DSPL_PID or DSPL_P_IN);
  out_chunk := getc(DSPL_PID or DSPL_P_OUT);
  //
  if (in_chunk.r_len <> out_chunk.r_len) then
    result := DSPL_FAILURE
  else begin
    //
    result := DSPL_SUCCESS;
    //
    ina  := in_chunk.r_fp;
    outa := out_chunk.r_fp;
    //
    if (not assigned(ina) or not assigned(outa)) then
      result := DSPL_FAILURE
    else begin
      //
      out_len := out_chunk.r_len;
      if ((out_len <> in_chunk.r_len) or (out_len < nSamples)) then
	result := DSPL_FAILURE
      else begin
	//
	if (f_modified) then begin
	  //
	  attack_samples  := 0.5 * getf(DSPL_PID or DSPL_P_ATTACK);
	  release_samples := 0.5 * getf(DSPL_PID or DSPL_P_RELEASE);
	  //
	  alpha := attack_samples / (attack_samples + 2.0);
	  beta  := release_samples / (release_samples + 2.0);
	  //
	  ld_peak := (DSPL_LD_PEAK = geti(DSPL_PID or DSPL_P_TYPE));
	  if (ld_peak) then begin
	    //
	    pb_samples := attack_samples;
	    if (issetf(DSPL_PID or DSPL_P_OTHER) and (0 < getf(DSPL_PID or DSPL_P_OTHER))) then
	      pb_samples := 0.5 * getf(DSPL_PID or DSPL_P_OTHER);
	    //
	    if (ceil(pb_samples) <> pb_size) then begin
	      //
	      pb_size := ceil(pb_samples);
	      mrealloc(peak_buffer, sizeOf(peak_buffer[0]) * pb_size);
	      //
	      pb_pos := 0;
	      peak_pos := -1;
	    end;
	  end;
	  //
	end;	// if (modified) ...
	//
	for t := 0 to nSamples - 1 do begin
	  //
	  if (ld_peak) then begin
	    //
	    ld_in := Abs(ina^);
	    //
	    peak_buffer[pb_pos] := ld_in;
	    if (pb_pos = peak_pos) then begin
	      //
	      i := pb_size - 1;
	      //
	      peak_pos := i;
	      peak_value := peak_buffer[i];
	      //
	      while (i > 0) do begin
		//
		dec(i);
		//
		if (peak_value < peak_buffer[i]) then begin
		  //
		  peak_pos := i;
		  peak_value := peak_buffer[i];
		end;
	      end;
	    end
	    else
	      if (ld_in > peak_value) then begin
		//
		peak_value := ld_in;
		peak_pos := pb_pos;
	      end;
	    //
	    inc(pb_pos);
	    if (pb_pos = pb_size) then
	      pb_pos := 0;
	    //
	    ld_in := peak_value;
	  end
	  else
	    ld_in := gain6db * ina^ * ina^;
	  //
	  if (ld_in > ld_out) then
	    theta := alpha
	  else
	    theta := beta;
          //
	  ld_out := ld_out * theta;
	  ld_out := ld_out + ld_in * (1.0 - theta);
	  //
	  if (ld_peak) then
	    outa^ := ld_out
	  else
	    outa^ := pow(ld_out, 0.5);
	  //
	  inc(ina);
	  inc(outa);
	end;	// for ...
	//
	f_modified := false;
	//
      end;
    end;
  end;
end;


{ unaDspDL_MbSp }

// --  --
procedure unaDspDL_MbSp.AfterConstruction();
var
  i: int;
begin
  seti(DSPL_PID or DSPL_P_OTHER, 0);
  setc(DSPL_PID or DSPL_P_FRQ, nil, 0);
  setf(DSPL_PID or DSPL_P_Q, pow(2.0, -0.5));
  //
  setc(DSPL_PID or DSPL_P_IN, nil, 0);
  //
  for i := 0 to 255 - 1 do
    setc(DSPL_PID or DSPL_P_OUT or i, nil, 0);
  //
  inherited;
end;

// --  --
procedure unaDspDL_MbSp.BeforeDestruction();
begin
  inherited;
  //
  mrealloc(hpfs);
  mrealloc(mout);
  mrealloc(zin1);
  mrealloc(zin2);
  mrealloc(zout1);
  mrealloc(zout2);
  mrealloc(z2in1);
  mrealloc(z2in2);
  mrealloc(z2out1);
  mrealloc(z2out2);
  mrealloc(acc);
  mrealloc(bcc);
end;

// --  --
constructor unaDspDL_MbSp.create();
begin
  {$IFDEF DEBUG }
  f_nameFull := c_DSPL_OBJNAMES_FULL[DSPL_MBSP];
  f_nameShort := c_DSPL_OBJNAMES_SHORT[DSPL_MBSP];
  {$ENDIF }
  //
  num_filtres := 0;
  hpfs := nil;
  mout := nil;
  zin1 := nil;
  zin2 := nil;
  zout1 := nil;
  zout2 := nil;
  z2in1 := nil;
  z2in2 := nil;
  z2out1 := nil;
  z2out2 := nil;
  acc := nil;
  bcc := nil;
  //
  buffer_length := 0;
  hi_order := 0;
  //
  inherited create(DSPL_OID or DSPL_MBSP);
end;

// --  --
function unaDspDL_MbSp.process(nSamples: dspl_int): dspl_result;
var
  max_slope: dspl_float;
  ina: pFloatArray;
  in_len: dspl_int;
  frqs: pFloatArray;
  q: dspl_float;
  i: int;
  pfa: pFloatArray;
  fin: pdspl_float;
  fout: pdspl_float;
  lin: pdspl_float;
  j: dspl_int;
  lpout: dspl_float;
begin
  max_slope := pow(2.0, -0.5);
  //
  ina := pFloatArray(getc(DSPL_PID or DSPL_P_IN).r_fp);
  in_len := getc(DSPL_PID or DSPL_P_IN).r_len;
  //
  if (in_len < nSamples) then
    result := DSPL_FAILURE
  else begin
    //
    result := DSPL_SUCCESS;
    //
    if (f_modified) then begin
      //
      num_bands := geti(DSPL_PID or DSPL_P_OTHER);
      if ((2 > num_bands) or (255 < num_bands)) then
	result := DSPL_FAILURE
      else begin
	//
	if (num_filtres <> num_bands - 1) then begin
	  //
	  num_filtres := num_bands - 1;
	  //
	  mrealloc(hpfs,  sizeOf(hpfs[0]) * num_filtres);
	  //
	  mrealloc(zin1,  sizeOf(zin1[0])  * num_filtres);
	  mrealloc(zin2,  sizeOf(zin2[0])  * num_filtres);
	  mrealloc(zout1, sizeOf(zout1[0]) * num_filtres);
	  mrealloc(zout2, sizeOf(zout2[0]) * num_filtres);
	  //
	  mrealloc(z2in1,  sizeOf(z2in1[0])  * num_filtres);
	  mrealloc(z2in2,  sizeOf(z2in2[0])  * num_filtres);
	  mrealloc(z2out1, sizeOf(z2out1[0]) * num_filtres);
	  mrealloc(z2out2, sizeOf(z2out2[0]) * num_filtres);
	  //
	  for i := 0 to num_filtres - 1 do begin
	    //
	    zin1[i] := 0.0;
	    zin2[i] := 0.0;
	    zout1[i] := 0.0;
	    zout2[i] := 0.0;
	    //
	    z2in1[i] := 0.0;
	    z2in2[i] := 0.0;
	    z2out1[i] := 0.0;
	    z2out2[i] := 0.0;
	  end;
	end;
	//
	if (getc(DSPL_PID or DSPL_P_FRQ).r_len <> num_filtres) then
	  result := DSPL_FAILURE
	else begin
	  //
	  // prepare filter coefs
	  frqs := pFloatArray(getc(DSPL_PID or DSPL_P_FRQ).r_fp);
	  q := getf(DSPL_PID or DSPL_P_Q);
	  //
	  gain_ref := 1.0;
	  //
	  if (q > max_slope) then begin
	    //
	    q := q / 2.0;
	    hi_order := 1;
	    gain_ref := 0.5;
	  end;
	  //
	  for i := 0 to num_filtres - 1 do
	    dspl_biq(DSPL_BIQ_LP, 1.0, frqs[i], q, hpfs[i], true);
          //
	  // prepare, depending on selected mode
	  mrealloc(mout, sizeOf(mout[0]) * num_bands);
	  for i := 0 to num_bands - 1 do begin
	    //
	    mout[i] := pFloatArray(getc(DSPL_PID or DSPL_P_OUT or i).r_fp);
	    //
	    if (getc(DSPL_PID or DSPL_P_OUT or i).r_len <> in_len) then begin
	      //
	      result := DSPL_FAILURE;
	      break;
	    end;
	  end;
	  //
	  if (DSPL_SUCCESS = result) then begin
	    //
	    if (buffer_length <> in_len) then begin
	      //
	      buffer_length := in_len;
	      mrealloc(acc, sizeOf(acc[0]) * buffer_length);
	      mrealloc(bcc, sizeOf(bcc[0]) * buffer_length);
	    end;
	    //
	    if (nil = mout) then
	      result := DSPL_FAILURE;
	  end;
	end;
      end;
    end;	// if (modified) ...
    //
    if (DSPL_SUCCESS = result) then begin
      //
      for i := 0 to num_filtres - 1 do begin
	//
	if (0 <> hi_order) then
	  dspl_eqmb_filter(hpfs[i], ina, bcc, z2in1[i], z2in2[i], z2out1[i], z2out2[i], nSamples);
	//
	if (0 <> hi_order) then
	  pfa := bcc
	else
	  pfa := ina;
	//
	dspl_eqmb_filter(hpfs[i], pfa, mout[i], zin1[i], zin2[i], zout1[i], zout2[i], nSamples);
	//
	// output
	fin := pdspl_float(acc);
	fout := pdspl_float(mout[i]);
	j := nSamples;
	//
	if (i > 0) then
	  //
	  while (j > 0) do begin
	    //
	    dec(j);
	    //
	    lpout := fout^;
	    fout^ := fout^ - fin^;
	    fin^ := lpout;
	    //
	    inc(fout);
	    inc(fin);
	  end
	else
	  //
	  while (j > 0) do begin
	    //
	    dec(j);
	    //
	    fin^ := fout^;
	    //
	    inc(fout);
	    inc(fin);
	  end;
	//
      end; // for filters..
      //
      fin := pdspl_float(acc);
      fout := pdspl_float(mout[num_filtres]);
      lin := pdspl_float(ina);
      //
      j := nSamples;
      while (j > 0) do begin
	//
	dec(j);
	//
	fout^ := lin^ - fin^;
	//
	inc(fout);
	inc(fin);
	inc(lin);
      end;
      //
      f_modified := false;
    end;
  end;
end;


{ unaDspDL_ND }

// --  --
procedure unaDspDL_ND.AfterConstruction();
begin
  setc(DSPL_PID or DSPL_P_IN, nil, 0);
  setc(DSPL_PID or DSPL_P_OUT, nil, 0);
  //
  setf(DSPL_PID or DSPL_P_NFRQ or DSPL_ND_SAMPLE_RATE, DSPL_DEFAULT_SAMPLE_FRQ);
  setf(DSPL_PID or DSPL_P_NFRQ or DSPL_ND_BAND_HP, 300.0);
  setf(DSPL_PID or DSPL_P_NFRQ or DSPL_ND_BAND_LP, 3000.0);
  //
  setf(DSPL_PID or DSPL_P_THRESHOLD or 0, 0.7);
  //
  setf(DSPL_PID or DSPL_P_OTHER or 0, 1.0);
  //
  inherited;
end;

// --  --
procedure unaDspDL_ND.BeforeDestruction();
begin
  inherited;
  //
  mrealloc(bl_buf);
  mrealloc(bp_buf);
  mrealloc(sl_buf);
  mrealloc(pl_buf);
  //
  freeAndNil(bp);
  freeAndNil(bl);
  freeAndNil(sl);
  freeAndNil(pl);
end;

// --  --
constructor unaDspDL_ND.create();
begin
  {$IFDEF DEBUG }
  f_nameFull := c_DSPL_OBJNAMES_FULL[DSPL_ND];
  f_nameShort := c_DSPL_OBJNAMES_SHORT[DSPL_ND];
  {$ENDIF DEBUG }
  //
  bp := unaDspDL_EQ2B.create();
  bl := unaDspDL_LD.create();
  sl := unaDspDL_LD.create();
  pl := unaDspDL_LD.create();
  //
  bl_buf := nil;
  pl_buf := nil;
  sl_buf := nil;
  bp_buf := nil;
  //
  lr := 1;
  dr := 0;
  //
  inherited create(DSPL_OID or DSPL_ND);
end;

// --  --
function unaDspDL_ND.process(nSamples: dspl_int): dspl_result;
var
  in_chunk: dspl_chunk;
  out_chunk: dspl_chunk;
  outa: pdspl_float;
  ina: pdspl_float;
  out_len: dspl_int;
  slope: dspl_double;
  sample_rate: dspl_float;
  i: dspl_int;
  acc: pdspl_float;
  sll: pdspl_float;
  bll: pdspl_float;
  pll: pdspl_float;
begin
  in_chunk := getc(DSPL_PID or DSPL_P_IN)^;
  out_chunk := getc(DSPL_PID or DSPL_P_OUT)^;
  //
  outa := nil;
  if (nil <> out_chunk.r_fp) then
    outa := out_chunk.r_fp;
  //
  ina := in_chunk.r_fp;
  //
  out_len := nSamples;
  if (out_len > in_chunk.r_len) then
    //
    result := DSPL_FAILURE
  else begin
    //
    result := DSPL_SUCCESS;
    if (f_modified) then begin
      //
      noise_level := db2v(-25.0);
      //
      if (buffer_length < out_len) then begin
	//
	buffer_length := out_len;
	//
	mrealloc(sl_buf, sizeOf(sl_buf^) * buffer_length);
	mrealloc(bp_buf, sizeOf(bp_buf^) * buffer_length);
	mrealloc(bl_buf, sizeOf(bl_buf^) * buffer_length);
	mrealloc(pl_buf, sizeOf(pl_buf^) * buffer_length);
      end;
      //
      slope := pow(2.0, -0.5);
      //
      sample_rate := getf(DSPL_PID or DSPL_P_NFRQ or DSPL_ND_SAMPLE_RATE);
      //
      bp.seti(DSPL_PID or DSPL_P_TYPE or DSPL_EQ2B_BAND1, DSPL_EQ2B_HP);
      bp.setf(DSPL_PID or DSPL_P_FRQ  or DSPL_EQ2B_BAND1, getf(DSPL_PID or DSPL_P_NFRQ or DSPL_ND_BAND_HP) / sample_rate);
      bp.setf(DSPL_PID or DSPL_P_Q    or DSPL_EQ2B_BAND1, slope);
      //
      bp.seti(DSPL_PID or DSPL_P_TYPE or DSPL_EQ2B_BAND2, DSPL_EQ2B_LP);
      bp.setf(DSPL_PID or DSPL_P_FRQ  or DSPL_EQ2B_BAND2, getf(DSPL_PID or DSPL_P_NFRQ or DSPL_ND_BAND_LP) / sample_rate);
      bp.setf(DSPL_PID or DSPL_P_Q    or DSPL_EQ2B_BAND2, slope);
      //
      bl.seti(DSPL_PID or DSPL_P_TYPE,    DSPL_LD_RMS);
      bl.setf(DSPL_PID or DSPL_P_ATTACK,  0.050 * sample_rate);
      bl.setf(DSPL_PID or DSPL_P_RELEASE, 0.050 * sample_rate);
      //
      sl.seti(DSPL_PID or DSPL_P_TYPE,    DSPL_LD_RMS);
      sl.setf(DSPL_PID or DSPL_P_ATTACK,  0.050 * sample_rate);
      sl.setf(DSPL_PID or DSPL_P_RELEASE, 0.050 * sample_rate);
      //
      pl.seti(DSPL_PID or DSPL_P_TYPE,    DSPL_LD_RMS);
      pl.setf(DSPL_PID or DSPL_P_ATTACK,  0.010 * sample_rate);
      pl.setf(DSPL_PID or DSPL_P_RELEASE, 0.010 * sample_rate);
      pl.setf(DSPL_PID or DSPL_P_OTHER,   0.010 * sample_rate);
      //
      pl.setc(DSPL_PID or DSPL_P_OUT, pl_buf, out_len);
      sl.setc(DSPL_PID or DSPL_P_OUT, sl_buf, out_len);
      bp.setc(DSPL_PID or DSPL_P_OUT, bp_buf, out_len);
      //
      bl.setc(DSPL_PID or DSPL_P_IN,  bp_buf, out_len);
      bl.setc(DSPL_PID or DSPL_P_OUT, bl_buf, out_len);
      //
      sensivity := getf(DSPL_PID or DSPL_P_THRESHOLD);
      smoothing := (getf(DSPL_PID or DSPL_P_OTHER) * sample_rate - 1) / (getf(DSPL_PID or DSPL_P_OTHER) * sample_rate + 1);
      //
    end;	// if (modified) ...
    //
    // ina may change, even if modified = false
    pl.setc(DSPL_PID or DSPL_P_IN, ina, out_len);
    sl.setc(DSPL_PID or DSPL_P_IN, ina, out_len);
    bp.setc(DSPL_PID or DSPL_P_IN, ina, out_len);
    //
    bp.process(nSamples);
    bl.process(nSamples);
    sl.process(nSamples);
    pl.process(nSamples);
    //
    i := nSamples;
    acc := outa;
    sll := sl_buf;
    bll := bl_buf;
    pll := pl_buf;
    //
    while (i > 0) do begin
      //
      dec(i);
      //
      if (bll^ / sll^ > sensivity) then
	noise_level := db2v(-3.0) * pll^ * (1 - smoothing) + smoothing * noise_level;
      //
      if (nil <> outa) then begin
	//
	acc^ := noise_level;
	inc(acc);
      end;
      //
      inc(sll);
      inc(bll);
      inc(pll);
    end;	// while ...
    //
    setf(DSPL_PID or DSPL_P_OUT, noise_level);
    //
    f_modified := false;
  end;
end;


{ unaDspDL_DynProc }

// --  --
procedure unaDspDL_DynProc.AfterConstruction();
begin
  setc(DSPL_PID or DSPL_P_IN or DSPL_DYNPROC_IN, nil, 0);
  setc(DSPL_PID or DSPL_P_IN or DSPL_DYNPROC_SC, nil, 0);
  setc(DSPL_PID or DSPL_P_OUT or 0, nil, 0);
  //
  // Level detector
  seti(DSPL_PID or DSPL_P_TYPE or DSPL_LD, DSPL_LD_RMS);
  setf(DSPL_PID or DSPL_P_ATTACK or DSPL_LD,  44.0);
  setf(DSPL_PID or DSPL_P_RELEASE or DSPL_LD, 44.0);
  setf(DSPL_PID or DSPL_P_OTHER or DSPL_LD,    0.0);
  //
  // Gain Processor
  setf(DSPL_PID or DSPL_P_ATTACK or 0,  220.5);
  setf(DSPL_PID or DSPL_P_RELEASE or 0, 2205.0);
  //
  setf(DSPL_PID or DSPL_P_THRESHOLD or 0, db2v(-12.0));
  //
  setf(DSPL_PID or DSPL_P_RATIO or DSPL_DYNPROC_ABOVE, 4.0);
  setf(DSPL_PID or DSPL_P_RATIO or DSPL_DYNPROC_BELOW, 1.0);
  //
  setf(DSPL_PID or DSPL_P_GAIN or DSPL_DYNPROC_ABOVE, db2v(0.0));
  setf(DSPL_PID or DSPL_P_GAIN or DSPL_DYNPROC_BELOW, db2v(0.0));
  //
  // number of samples over threshold
  seti(DSPL_PID or DSPL_P_OTHER or 0, 0);
  //
  inherited;
end;

// --  --
procedure unaDspDL_DynProc.BeforeDestruction();
begin
  inherited;
  //
  mrealloc(ld_buffer);
  freeAndNil(level_detector);
end;

// --  --
constructor unaDspDL_DynProc.create();
begin
  {$IFDEF DEBUG }
  f_nameFull := c_DSPL_OBJNAMES_FULL[DSPL_DYNPROC];
  f_nameShort := c_DSPL_OBJNAMES_SHORT[DSPL_DYNPROC];
  {$ENDIF }
  //
  level_detector := unaDspDL_LD.create();
  //
  ld_buffer := nil;
  ld_buffer_size := 0;
  gain_env := 0;
  gr_env := 1;
  nsot := 0;
  //
  inherited create(DSPL_OID or DSPL_DYNPROC);
end;

// --  --
function unaDspDL_DynProc.process(nSamples: dspl_int): dspl_result;
var
  in_chunk: pdspl_chunk;
  out_chunk: pdspl_chunk;
  sc_chunk: pdspl_chunk;
  ina: pdspl_float;
  //sc: pdspl_float;
  outa: pdspl_float;
  out_len: dspl_int;
  valid: dspl_result;
  attack_samples: dspl_float;
  release_samples: dspl_float;
  aratio: dspl_float;
  bratio: dspl_float;
  ld: pdspl_float;
  theta: dspl_double;
  oth: bool;
  gain: dspl_double;
  gr: dspl_double;
  t: int;
begin
  in_chunk := getc(DSPL_PID or DSPL_P_IN or DSPL_DYNPROC_IN);
  out_chunk := getc(DSPL_PID or DSPL_P_OUT);
  sc_chunk := getc(DSPL_PID or DSPL_P_IN or DSPL_DYNPROC_SC);
  //
  result := DSPL_SUCCESS;
  //
  if (nil = sc_chunk.r_fp) then
    sc_chunk := in_chunk
  else
    if (in_chunk.r_len <> sc_chunk.r_len) then
      result := DSPL_FAILURE;
  //
  if (DSPL_SUCCESS = result) then begin
    //
    ina := in_chunk.r_fp;
    //sc := sc_chunk.r_fp;
    outa := out_chunk.r_fp;
    //
    out_len := out_chunk.r_len;
    if ((out_len <> in_chunk.r_len) or (out_len < nSamples)) then
      result := DSPL_FAILURE
    else begin
      //
      if (f_modified) then begin
	//
	if (ld_buffer_size < out_len) then begin
	  //
	  ld_buffer_size := out_len;
	  mrealloc(ld_buffer, sizeOf(ld_buffer^) * ld_buffer_size);
	end;
	//
	valid := true;
	//
	valid := valid and level_detector.setf(DSPL_PID or DSPL_P_ATTACK,  getf(DSPL_PID or DSPL_P_ATTACK  or DSPL_LD));
	valid := valid and level_detector.setf(DSPL_PID or DSPL_P_RELEASE, getf(DSPL_PID or DSPL_P_RELEASE or DSPL_LD));
	valid := valid and level_detector.setf(DSPL_PID or DSPL_P_OTHER,   getf(DSPL_PID or DSPL_P_OTHER   or DSPL_LD));
	//
	valid := valid and level_detector.seti(DSPL_PID or DSPL_P_TYPE, geti(DSPL_PID or DSPL_P_TYPE or DSPL_LD));
	valid := valid and level_detector.setc(DSPL_PID or DSPL_P_IN,   sc_chunk.r_fp, sc_chunk.r_len);
	valid := valid and level_detector.setc(DSPL_PID or DSPL_P_OUT,  ld_buffer, out_len);
	//
	if (not valid) then
	  result := DSPL_FAILURE
	else begin
	  //
	  attack_samples := 0.5 * getf(DSPL_PID or DSPL_P_ATTACK);
	  release_samples := 0.5 * getf(DSPL_PID or DSPL_P_RELEASE);
	  //
	  if ((attack_samples < 0) or (release_samples < 0)) then
	    result := DSPL_FAILURE
	  else begin
	    //
	    alpha := attack_samples / (attack_samples + 2.0);
	    beta := exp(-1.0 / (release_samples + 1.0));
	    //
	    aratio := getf(DSPL_PID or DSPL_P_RATIO or DSPL_DYNPROC_ABOVE);
	    bratio := getf(DSPL_PID or DSPL_P_RATIO or DSPL_DYNPROC_BELOW);
	    //
	    if ((aratio < 0.02) or (bratio < 0.02)) then
	      result := DSPL_FAILURE
	    else begin
	      //
	      aratio_inv := 1.0 / aratio;
	      bratio_inv := 1.0 / bratio;
	      //
	      if (aratio_inv < 1e-3) then aratio_inv := 0.0;
	      if (bratio_inv < 1e-3) then bratio_inv := 0.0;
	      //
	      th := getf(DSPL_PID or DSPL_P_THRESHOLD);
	      try
		ascale := getf(DSPL_PID or DSPL_P_GAIN or DSPL_DYNPROC_ABOVE) * pow(th, 1.0 - aratio_inv);
	      except
		ascale := db2v(60.0);
	      end;
	      //
	      try
		bscale := getf(DSPL_PID or DSPL_P_GAIN or DSPL_DYNPROC_BELOW) * pow(th, 1.0 - bratio_inv);
	      except
		bscale := db2v(60.0);
	      end;
	      //
	    end;
	  end;
	end;  
      end;	// if (modified) ...
      //
      if (DSPL_SUCCESS = result) then begin
	//
	level_detector.process(nSamples);
	//
	ld := ld_buffer;
	nsot := 0;
	//
	for t := 0 to nSamples -1 do begin
	  //
	  oth := (ld^ >= th);
	  //
	  if (oth) then
	    gain := ascale * pow(ld^, aratio_inv)
	  else
	    gain := bscale * pow(ld^, bratio_inv);
	  //
	  if (oth) then
	    gr := ascale * pow(ld^, aratio_inv - 1)
	  else
	    gr := bscale * pow(ld^, bratio_inv - 1);
	  //
	  if (gr < db2v(-127.0)) then gr := 0;
	  if (gr > db2v(127.0))  then gr := db2v(120.0);
	  //
	  if (gain > gain_env) then
	    theta := alpha
	  else
	    theta := beta;
	  //  
	  if (gain_env > th) then
	    inc(nsot);
	  //
	  gain_env := gain_env * theta;
	  gain_env := gain_env + gain * (1.0 - theta);
	  //
	  gr_env := gr_env * theta;
	  gr_env := gr_env + gr * (1.0 - theta);
	  //
	  outa^ := gr_env * ina^;
	  //
	  inc(ina);
	  inc(outa);
	  inc(ld);
	end;
	//
	seti(DSPL_PID or DSPL_P_OTHER, nsot);
	//
	f_modified := false;
      end;
    end;
  end;
end;


{ unaDspDL_SpeechProc }

// --  --
procedure unaDspDL_SpeechProc.AfterConstruction();
begin
  setc(DSPL_PID or DSPL_P_IN or 0, nil, 0);
  setc(DSPL_PID or DSPL_P_OUT or 0, nil, 0);
  //
  setf(DSPL_PID or DSPL_P_THRESHOLD or 0, db2v(-36.0));
  setc(DSPL_PID or DSPL_P_THRESHOLD or 0, nil, 0);
  //
  setf(DSPL_PID or DSPL_P_NFRQ or DSPL_SPEECHPROC_SAMPLE_RATE, DSPL_DEFAULT_SAMPLE_FRQ);
  //
  setf(DSPL_PID or DSPL_P_NFRQ or DSPL_SPEECHPROC_DEESSER,  2000.0);
  setf(DSPL_PID or DSPL_P_NFRQ or DSPL_SPEECHPROC_ENHANCER, 5000.0);
  setf(DSPL_PID or DSPL_P_Q    or DSPL_SPEECHPROC_ENHANCER, 0.4);
  setf(DSPL_PID or DSPL_P_NFRQ or DSPL_SPEECHPROC_LOWCUT,   300.0);
  //
  setf(DSPL_PID or DSPL_P_GAIN or 0,                         db2v(+6.0));
  setf(DSPL_PID or DSPL_P_GAIN or DSPL_SPEECHPROC_CEIL or 0, db2v(-0.5));
  //
  // number of samples over threshold
  seti(DSPL_PID or DSPL_P_OTHER or 0, 0);
  //
  inherited;
end;

// --  --
procedure unaDspDL_SpeechProc.BeforeDestruction();
begin
  inherited;
  //
  mrealloc(acca);
  mrealloc(accb);
  mrealloc(la_in);
  mrealloc(la_buf);
  mrealloc(hp_out);
  //
  freeAndNil(hp);
  freeAndNil(enh);
  //
  freeAndNil(agc);
  freeAndNil(comp);
  freeAndNil(ng);
  freeAndNil(lim);
  freeAndNil(ds);
end;

// --  --
constructor unaDspDL_SpeechProc.create();
begin
  {$IFDEF DEBUG }
  f_nameFull := c_DSPL_OBJNAMES_FULL[DSPL_SPEECHPROC];
  f_nameShort := c_DSPL_OBJNAMES_SHORT[DSPL_SPEECHPROC];
  {$ENDIF }
  //
  hp := unaDspDL_EQ2B.create();
  enh := unaDspDL_EQ2B.create();
  //
  agc := unaDspDL_DynProc.create();
  comp := unaDspDL_DynProc.create();
  ng := unaDspDL_DynProc.create();
  lim := unaDspDL_DynProc.create();
  ds := unaDspDL_DynProc.create();
  //
  acca := nil;
  accb := nil;
  hp_out := nil;
  la_buf := nil;
  la_in := nil;
  //
  la_size := 0;
  la_pos := 0;
  //
  inherited create(DSPL_OID or DSPL_SPEECHPROC);
end;

// --  --
function unaDspDL_SpeechProc.process(nSamples: dspl_int): dspl_result;
const
  look_ahead: dspl_float = 0.005;
  att_ratio: dspl_double = 0.125;
var
  in_chunk: pdspl_chunk;
  out_chunk: pdspl_chunk;
  th_chunk: pdspl_chunk;
  //
  ina: pdspl_float;
  outa: pdspl_float;
  la: pdspl_float;
  ill: pdspl_float;
  acc: pdspl_float;
  hpp: pdspl_float;
  //
  out_len: dspl_int;
  sample_rate: dspl_float;
  noise_level: dspl_float;
  gap: dspl_double;
  agc_th: dspl_float;
  agc_gain: dspl_float;
  //
  i: int;
  s: dspl_float;
  slope: dspl_double;
begin
  in_chunk := getc(DSPL_PID or DSPL_P_IN);
  out_chunk := getc(DSPL_PID or DSPL_P_OUT);
  //
  th_chunk := getc(DSPL_PID or DSPL_P_THRESHOLD);
  //
  ina := in_chunk.r_fp;
  outa := out_chunk.r_fp;
  out_len := out_chunk.r_len;
  //
  result := DSPL_SUCCESS;
  if ((out_len <> in_chunk.r_len) or (out_len < nSamples)) then
    result := DSPL_FAILURE
  else begin
    //
    if (f_modified) then begin
      //
      if (buffer_length < out_len) then begin
	//
	buffer_length := out_len;
	//
	mrealloc(acca, sizeOf(acca^) * buffer_length);
	mrealloc(accb, sizeOf(accb^) * buffer_length);
	mrealloc(la_in, sizeOf(la_in^) * buffer_length);
	mrealloc(hp_out, sizeOf(hp_out^) * buffer_length);
      end;
      //
      // lookahead
      sample_rate := getf(DSPL_PID or DSPL_P_NFRQ or DSPL_SPEECHPROC_SAMPLE_RATE);
      if (la_size < floor(sample_rate * look_ahead)) then begin
	//
	la_size := floor(sample_rate * look_ahead);
	la_pos := 0;
	mrealloc(la_buf, sizeOf(la_buf^) * la_size);
	//
	for i := 0 to la_size - 1 do
	  pFloatArray(la_buf)[i] := 0.0;
      end;
      //
      // AGC Setup
      agc.seti(DSPL_PID or DSPL_P_TYPE    or DSPL_LD, DSPL_LD_PEAK);
      agc.setf(DSPL_PID or DSPL_P_ATTACK  or DSPL_LD, 0.001 * sample_rate);
      agc.setf(DSPL_PID or DSPL_P_RELEASE or DSPL_LD, 1.0 * sample_rate);
      agc.setf(DSPL_PID or DSPL_P_OTHER   or DSPL_LD, 0.5 * sample_rate);
      //
      agc.setf(DSPL_PID or DSPL_P_ATTACK , 0.01 * sample_rate);
      agc.setf(DSPL_PID or DSPL_P_RELEASE, 0.05 * sample_rate);
      //
      enh.seti(DSPL_PID or DSPL_P_TYPE or DSPL_EQ2B_BAND1, DSPL_BIQ_PEAK);
      enh.setf(DSPL_PID or DSPL_P_GAIN or DSPL_EQ2B_BAND1, db2v(+6.0));
      enh.setf(DSPL_PID or DSPL_P_FRQ  or DSPL_EQ2B_BAND1, getf(DSPL_PID or DSPL_P_NFRQ or DSPL_SPEECHPROC_ENHANCER) / sample_rate);
      enh.setf(DSPL_PID or DSPL_P_Q    or DSPL_EQ2B_BAND1, getf(DSPL_PID or DSPL_P_Q    or DSPL_SPEECHPROC_ENHANCER));
      //
      slope := pow(2.0, -0.5);
      //
      enh.seti(DSPL_PID or DSPL_P_TYPE or DSPL_EQ2B_BAND2, DSPL_BIQ_HP);
      enh.setf(DSPL_PID or DSPL_P_FRQ  or DSPL_EQ2B_BAND2, getf(DSPL_PID or DSPL_P_NFRQ or DSPL_SPEECHPROC_LOWCUT) / sample_rate);
      enh.setf(DSPL_PID or DSPL_P_Q    or DSPL_EQ2B_BAND2, slope);
      //
      hp.seti(DSPL_PID or DSPL_P_TYPE or DSPL_EQ2B_BAND2, DSPL_BIQ_HP);
      hp.setf(DSPL_PID or DSPL_P_FRQ  or DSPL_EQ2B_BAND2, getf(DSPL_PID or DSPL_P_NFRQ or DSPL_SPEECHPROC_DEESSER) / sample_rate);
      hp.setf(DSPL_PID or DSPL_P_Q    or DSPL_EQ2B_BAND2, slope / 2.0);
      //
      ds.seti(DSPL_PID or DSPL_P_TYPE    or DSPL_LD, DSPL_LD_RMS);
      ds.setf(DSPL_PID or DSPL_P_ATTACK  or DSPL_LD, 0.001 * sample_rate);
      ds.setf(DSPL_PID or DSPL_P_RELEASE or DSPL_LD, 0.001 * sample_rate);
      //
      ds.setf(DSPL_PID or DSPL_P_ATTACK , 0.005 * sample_rate);
      ds.setf(DSPL_PID or DSPL_P_RELEASE, 0.050 * sample_rate);
      //
      ds.setf(DSPL_PID or DSPL_P_THRESHOLD, db2v(-20.0));
      ds.setf(DSPL_PID or DSPL_P_RATIO or DSPL_DYNPROC_ABOVE, 100.0);
      ds.setf(DSPL_PID or DSPL_P_RATIO or DSPL_DYNPROC_BELOW, 1.0);
      ds.setf(DSPL_PID or DSPL_P_GAIN  or DSPL_DYNPROC_ABOVE, db2v(3.0));
      ds.setf(DSPL_PID or DSPL_P_GAIN  or DSPL_DYNPROC_BELOW, db2v(3.0));
      //
      comp.seti(DSPL_PID or DSPL_P_TYPE    or DSPL_LD, DSPL_LD_RMS);
      comp.setf(DSPL_PID or DSPL_P_ATTACK  or DSPL_LD, 0.001 * sample_rate);
      comp.setf(DSPL_PID or DSPL_P_RELEASE or DSPL_LD, 0.005 * sample_rate);
      //
      comp.setf(DSPL_PID or DSPL_P_ATTACK , 0.005 * sample_rate);
      comp.setf(DSPL_PID or DSPL_P_RELEASE, 0.050 * sample_rate);
      //
      comp.setf(DSPL_PID or DSPL_P_THRESHOLD, db2v(-12.0));
      comp.setf(DSPL_PID or DSPL_P_RATIO or DSPL_DYNPROC_ABOVE, 4.0);
      comp.setf(DSPL_PID or DSPL_P_RATIO or DSPL_DYNPROC_BELOW, 1.0);
      comp.setf(DSPL_PID or DSPL_P_GAIN  or DSPL_DYNPROC_ABOVE, getf(DSPL_PID or DSPL_P_GAIN));
      comp.setf(DSPL_PID or DSPL_P_GAIN  or DSPL_DYNPROC_BELOW, getf(DSPL_PID or DSPL_P_GAIN));
      //
      ng.seti(DSPL_PID or DSPL_P_TYPE    or DSPL_LD, DSPL_LD_PEAK);
      ng.setf(DSPL_PID or DSPL_P_ATTACK  or DSPL_LD, 0.001 * sample_rate);
      ng.setf(DSPL_PID or DSPL_P_RELEASE or DSPL_LD, 0.001 * sample_rate);
      ng.setf(DSPL_PID or DSPL_P_OTHER   or DSPL_LD, 0.001 * sample_rate);
      //
      ng.setf(DSPL_PID or DSPL_P_ATTACK , 0.005 * sample_rate);
      ng.setf(DSPL_PID or DSPL_P_RELEASE, 0.300 * sample_rate);
      //
      ng.setf(DSPL_PID or DSPL_P_RATIO or DSPL_DYNPROC_ABOVE, 1.0);
      ng.setf(DSPL_PID or DSPL_P_RATIO or DSPL_DYNPROC_BELOW, 0.05);
      ng.setf(DSPL_PID or DSPL_P_GAIN  or DSPL_DYNPROC_ABOVE, db2v(0.0));
      ng.setf(DSPL_PID or DSPL_P_GAIN  or DSPL_DYNPROC_BELOW, db2v(0.0));
      //
      lim.seti(DSPL_PID or DSPL_P_TYPE    or DSPL_LD, DSPL_LD_PEAK);
      lim.setf(DSPL_PID or DSPL_P_ATTACK  or DSPL_LD, 0.000 * sample_rate);
      lim.setf(DSPL_PID or DSPL_P_RELEASE or DSPL_LD, 0.001 * sample_rate);
      lim.setf(DSPL_PID or DSPL_P_OTHER   or DSPL_LD, 0.005 * sample_rate);
      //
      lim.setf(DSPL_PID or DSPL_P_ATTACK , 0.000 * sample_rate);
      lim.setf(DSPL_PID or DSPL_P_RELEASE, 0.050 * sample_rate);
      //
      lim.setf(DSPL_PID or DSPL_P_THRESHOLD, getf(DSPL_PID or DSPL_P_GAIN or DSPL_SPEECHPROC_CEIL));
      lim.setf(DSPL_PID or DSPL_P_RATIO or DSPL_DYNPROC_ABOVE, 100.0);
      lim.setf(DSPL_PID or DSPL_P_RATIO or DSPL_DYNPROC_BELOW, 1.0);
      lim.setf(DSPL_PID or DSPL_P_GAIN  or DSPL_DYNPROC_ABOVE, db2v(0.0));
      lim.setf(DSPL_PID or DSPL_P_GAIN  or DSPL_DYNPROC_BELOW, db2v(0.0));
      //
      agc.setc(DSPL_PID or DSPL_P_IN,  la_in, out_len);
      agc.setc(DSPL_PID or DSPL_P_OUT, acca , out_len);
      //
      enh.setc(DSPL_PID or DSPL_P_IN,  acca, out_len);
      enh.setc(DSPL_PID or DSPL_P_OUT, accb, out_len);
      //
      hp.setc(DSPL_PID or DSPL_P_IN,  accb  , out_len);
      hp.setc(DSPL_PID or DSPL_P_OUT, hp_out, out_len);
      //
      ds.setc(DSPL_PID or DSPL_P_IN,  hp_out, out_len);
      ds.setc(DSPL_PID or DSPL_P_OUT, accb  , out_len);
      //
      ng.setc(DSPL_PID or DSPL_P_IN,  acca, out_len);
      ng.setc(DSPL_PID or DSPL_P_OUT, accb, out_len);
      ng.setc(DSPL_PID or DSPL_P_IN or DSPL_DYNPROC_SC, ina, out_len);
      //
      comp.setc(DSPL_PID or DSPL_P_IN,  accb, out_len);
      comp.setc(DSPL_PID or DSPL_P_OUT, acca, out_len);
      //
      lim.setc(DSPL_PID or DSPL_P_IN,  acca, out_len);
      lim.setc(DSPL_PID or DSPL_P_OUT, outa, out_len);
      //
    end;	// if (modified) ...
    //
    if ((nil <> th_chunk.r_fp) or f_modified) then begin
      //
      if (nil <> th_chunk.r_fp) then
	noise_level := th_chunk.r_fp^
      else
	noise_level := getf(DSPL_PID or DSPL_P_THRESHOLD);
      //
      if (noise_level > db2v(-18.0)) then
	noise_level := db2v(-18.0)
      else
	if (noise_level < db2v(-127.0)) then
	  noise_level := db2v(-127.0);
      //
      gap := pow(db2v(-12.0) / noise_level, att_ratio);
      //
      agc_th := noise_level * gap;
      agc_gain := db2v(-12.0) / agc_th;
      //
      agc.setf(DSPL_PID or DSPL_P_THRESHOLD, agc_th);
      agc.setf(DSPL_PID or DSPL_P_RATIO or DSPL_DYNPROC_ABOVE, 8.0);
      agc.setf(DSPL_PID or DSPL_P_RATIO or DSPL_DYNPROC_BELOW, att_ratio);
      agc.setf(DSPL_PID or DSPL_P_GAIN  or DSPL_DYNPROC_ABOVE, agc_gain);
      agc.setf(DSPL_PID or DSPL_P_GAIN  or DSPL_DYNPROC_BELOW, agc_gain);
      //
      ng.setf(DSPL_PID or DSPL_P_THRESHOLD, noise_level);
      //
    end;	// if (chunk or modified) ...
    //
    la := la_in;
    ill := ina;
    //
    i := nSamples;
    while (i > 0) do begin
      //
      dec(i);
      //
      s := pFloatArray(la_buf)[la_pos];
      pFloatArray(la_buf)[la_pos] := ill^;
      inc(la_pos);
      //
      if (la_pos >= la_size) then
	la_pos := 0;
      //
      la^ := s;
      //
      inc(la);
      inc(ill);
    end;
    //
    agc.process(nSamples);
    enh.process(nSamples);
    hp.process(nSamples);
    //
    acc := acca;
    hpp := hp_out;
    //
    i := nSamples;
    while (i > 0) do begin
      //
      dec(i);
      //
      acc^ := acc^ - hpp^;
      inc(acc);
      inc(hpp);
    end;
    //
    ds.process(nSamples);
    //
    acc := acca;
    hpp := accb;
    //
    i := nSamples;
    while (i > 0) do begin
      //
      dec(i);
      //
      acc^ := acc^ + hpp^;
      //
      inc(acc);
      inc(hpp);
    end;
    //
    ng.process(nSamples);
    comp.process(nSamples);
    lim.process(nSamples);
    //
    seti(DSPL_PID or DSPL_P_OTHER, ng.geti(DSPL_PID or DSPL_P_OTHER));
    //
    f_modified := false;
  end;
end;


end.

