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

	  DSP Lib header
	----------------------------------------------
	  Copyright (c) 2007-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  modified by:
		Lake, Mar 2007

	----------------------------------------------

*)

{$I unaDef.inc }

{*
  Interface for general purpose DSP library in native Delphi code.

  @Author Delphi conversion by Lake

  2.5.2008.07 Still here
}

unit
  unaDspLibH;

interface

uses
  Windows, unaTypes, unaClasses;


//-- dsplconf.h --

type
  dspl_id       = unsigned;	// class identtifier
  dspl_handle   = unsigned;  	// object handle (not a pointer)
  //
  dspl_float    = single;    	// 4 bytes
  pdspl_float	= ^dspl_float;
  //
  dspl_double   = double;	// 8 bytes
  pdspl_double  = ^dspl_double;	// 
  //
  dspl_int      = int;       	//
  //
  dspl_result   = bool;

  //
  pdspl_chunk = ^dspl_chunk;
  dspl_chunk = packed record
    //
    r_fp: pdspl_float;
    r_len: dspl_int;
  end;


const
  dspl_empty_chunk: dspl_chunk = (r_fp: nil; r_len: 0);

// --  dsplmath.h --

type
  //
  pdspl_biq_values = ^dspl_biq_values;
  dspl_biq_values = packed record
    //
    a0,a1,a2,b0,b1,b2: dspl_double;
  end;

  pdspl_biq_valuesArray = ^dspl_biq_valuesArray;
  dspl_biq_valuesArray = array[0..$2AAAAA9] of dspl_biq_values;


//-- dsplconst.h --

const
  DSPL_VERSION	= '1.01b';

  DSPL_DEFAULT_SAMPLE_FRQ = 44100;
  DSPL_INVALID_HANDLE       = dspl_handle(false);

  DSPL_FAILURE              = false;
  DSPL_SUCCESS              = true;


// class and parameters ids

// class ids
 //enum dspl_id_class
 //                {
	DSPL_OID = $00000;
	DSPL_PID = $10000;
 //               };

// param ids
// enum dspl_param_class
//                 {
	DSPL_P_IN        = $0100;
	DSPL_P_OUT       = $0200;
	DSPL_P_GAIN      = $0300;
	DSPL_P_FRQ       = $0400;
	DSPL_P_Q         = $0500;
	DSPL_P_TYPE      = $0600;
	DSPL_P_ATTACK    = $0700;
	DSPL_P_RELEASE   = $0800;
	DSPL_P_THRESHOLD = $0900;
	DSPL_P_RATIO     = $0A00;
	DSPL_P_NFRQ      = $0B00;
	DSPL_P_OTHER     = $FF00;
//                 };


// enum dspl_object_class
//				{
	DSPL_EQ2B 	= 1;	//
	DSPL_LD		= 2;	//
	DSPL_DYNPROC	= 3;    //
	DSPL_SPEECHPROC	= 4;	//
	DSPL_ND		= 5;	//
	DSPL_EQMB	= 6;	//
	DSPL_MBSP	= 7;	//
//				};

 // object's param id is constructed like this:
 // id = id_class | param_class | param_index
 //
 // for example:
 // define DSPL_EQ2B_FRQ2 DSPL_PID | DSPL_P_FRQ | 0x2


(*****************************************************************
				EQ2B
*)


	//enum dspl_biq_type
	//{
	DSPL_BIQ_PEAK	= 1;
	DSPL_BIQ_LP	= 2;
	DSPL_BIQ_HP	= 3;
	DSPL_BIQ_LS	= 4;
	DSPL_BIQ_HS	= 5;
	//};


	//enum dspl_eq2b_band_id   {
	DSPL_EQ2B_BOTH 	= 0;
	DSPL_EQ2B_BAND1	= 1;
	DSPL_EQ2B_BAND2	= 2;
	//};


	//enum dspl_eq2b_band_type {
	DSPL_EQ2B_OFF	= 0;
	DSPL_EQ2B_PEAK	= DSPL_BIQ_PEAK;
	DSPL_EQ2B_LP	= DSPL_BIQ_LP;
	DSPL_EQ2B_HP	= DSPL_BIQ_HP;
	DSPL_EQ2B_LS	= DSPL_BIQ_LS;
	DSPL_EQ2B_HS	= DSPL_BIQ_HS;
	//};

(*****************************************************************
				Level Detector
*)

	//enum dspl_ld_type   {
		DSPL_LD_RMS	= 0;
		DSPL_LD_PEAK	= 1;
	//};


(*****************************************************************
			Dynamic Processor
*)


	//enum dspl_dynproc_input   {
		DSPL_DYNPROC_IN	= 0;
		DSPL_DYNPROC_SC	= 1;
	//};

	//enum dspl_dynproc_range   {
		DSPL_DYNPROC_ABOVE	= 0;
		DSPL_DYNPROC_BELOW	= 1;
	//};

(*****************************************************************
			Speech Processor
*)

	//enum dspl_speechproc_frq	{
		DSPL_SPEECHPROC_SAMPLE_RATE	= 0;
		DSPL_SPEECHPROC_ENHANCER	= 1;
		DSPL_SPEECHPROC_DEPOPPER	= 2;
		DSPL_SPEECHPROC_DEESSER		= 3;
		DSPL_SPEECHPROC_LOWCUT		= 4;
		DSPL_SPEECHPROC_CEIL		= 5;
	//};


	//enum dspl_nd	{
		DSPL_ND_SAMPLE_RATE	= 0;
		DSPL_ND_BAND_LP		= 1;
		DSPL_ND_BAND_HP		= 2;
	//};



(* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *)

//#define DSPL_INSTANCE(id,cname) case (DSPL_OID | id):return new cname((DSPL_OID | id));

//#define DSPL_INSTANCES \
//		DSPL_INSTANCE(DSPL_EQ2B,DSPLEQ2b)\
//		DSPL_INSTANCE(DSPL_LD,DSPLLD)\
//		DSPL_INSTANCE(DSPL_DYNPROC,DSPLDynProc)\
//		DSPL_INSTANCE(DSPL_SPEECHPROC,DSPLSpeechProc)\
//		DSPL_INSTANCE(DSPL_ND,DSPLND)\
//		DSPL_INSTANCE(DSPL_MBSP,DSPLMbSp)\
//		DSPL_INSTANCE(DSPL_EQMB,DSPLEQMb)


// -- dsplapi.h --


type
  // -- API --

	proc_dspl_create = function(object_id: dspl_id): dspl_handle; cdecl;
	proc_dspl_destroy = function(handle: dspl_handle): dspl_result; cdecl;

// Object's parameters setters
//      handle   - object handle
//      param_id - property id
//
// dspl_setf  -
// dspl_seti  -
// dspl_setc
//
	proc_dspl_setf = function(handle: dspl_handle; param_id: dspl_id; value: dspl_float): dspl_result; cdecl;
	proc_dspl_seti = function(handle: dspl_handle; param_id: dspl_id; value: dspl_int): dspl_result; cdecl;
	proc_dspl_setc = function(handle: dspl_handle; param_id: dspl_id; chunk: pdspl_float; length: dspl_int): dspl_result; cdecl;

// Object's parameters getters
//      handle   - object handle
//      param_id - property id
	//
	proc_dspl_geti = function(handle: dspl_handle; param_id: dspl_id; out value: dspl_int): dspl_result; cdecl;
	proc_dspl_getf = function(handle: dspl_handle; param_id: dspl_id; out value: dspl_float): dspl_result; cdecl;

// dspl_process -
	proc_dspl_process = function(handle: dspl_handle; nSamples: dspl_int): dspl_result; cdecl;

// Version
	proc_dspl_version = function(): pAnsiChar; cdecl;


// --- dsplprocessor.h --

//const
  //DSPL_CHUNK = cparams;
  //DSPL_FLOAT = fparams;
  //DSPL_INT   = iparams;

//#define DSPL_DECLARE_PARAM(param_type,param_class,id,default_value) \
//                param_type[(DSPL_PID |param_class | id)]=default_value;



// --  --
const

  // localize as necessary, order is important!
  c_DSPL_OBJNAMES_FULL: array[DSPL_EQ2B..DSPL_MBSP] of AnsiString =
    (
     '2 Band Parametric Equalizer', 	// DSPL_EQ2B
     'Level Detector',			// DSPL_LD
     'Dynamic Processor',		// DSPL_DYNPROC
     'Speech Processor',		// DSPL_SPEECHPROC
     'Noise Level Detector',		// DSPL_ND
     'Multiband Equalizer/Filter',	// DSPL_EQMB
     'Multiband Splitter'		// DSPL_MBSP
     );


  // localize as necessary, order is important!
  c_DSPL_OBJNAMES_SHORT: array[DSPL_EQ2B..DSPL_MBSP] of AnsiString =
    (
     'EQ2B', 		// DSPL_EQ2B
     'LD',		// DSPL_LD
     'DynProc',		// DSPL_DYNPROC
     'SpeechProc',	// DSPL_SPEECHPROC
     'LD',		// DSPL_ND
     'EQMB',		// DSPL_EQMB
     'MBSP'		// DSPL_MBSP
     );


type
  //
  // -- unaDspLibAbstract --
  //
  unaDspLibAbstract = class(unaObject)
  protected
    f_libResult: dspl_result;
    //
    function dspl_create(object_id: dspl_id): dspl_handle; virtual; abstract;
    function dspl_destroy(handle: dspl_handle): dspl_result; virtual; abstract;
    function dspl_process(handle: dspl_handle; nSamples: dspl_int): dspl_result; virtual; abstract;
    function dspl_version(): pAnsiChar; virtual; abstract;
    //
    function dspl_seti(handle: dspl_handle; param: dspl_id; value: dspl_int): dspl_result; virtual; abstract;
    function dspl_setf(handle: dspl_handle; param: dspl_id; value: dspl_float): dspl_result; virtual; abstract;
    function dspl_setc(handle: dspl_handle; param: dspl_id; chunk: pdspl_float; length: dspl_int): dspl_result; virtual; abstract;
    //
    function dspl_geti(handle: dspl_handle; param: dspl_id): dspl_int; virtual; abstract;
    function dspl_getf(handle: dspl_handle; param: dspl_id): dspl_float; virtual; abstract;
    function dspl_getc(handle: dspl_handle; param: dspl_id): pdspl_chunk; virtual; abstract;
    //
    function dspl_getID(handle: dspl_handle): dspl_int; virtual; abstract;
    //
    function dspl_isseti(handle: dspl_handle; param: dspl_id): dspl_result; virtual; abstract;
    function dspl_issetf(handle: dspl_handle; param: dspl_id): dspl_result; virtual; abstract;
    function dspl_issetc(handle: dspl_handle; param: dspl_id): dspl_result; virtual; abstract;
  public
    function createObj(object_id: dspl_id): dspl_handle;
    function destroyObj(handle: dspl_handle): dspl_result;
    //
    function process(handle: dspl_handle; nSamples: dspl_int): dspl_result;
    //
    function seti(handle: dspl_handle; param: dspl_id; value: dspl_int): dspl_result;
    function setf(handle: dspl_handle; param: dspl_id; value: dspl_float): dspl_result;
    function setc(handle: dspl_handle; param: dspl_id; chunk: pdspl_float; length: dspl_int): dspl_result;
    //
    function geti(handle: dspl_handle; param: dspl_id): dspl_int;
    function getf(handle: dspl_handle; param: dspl_id): dspl_float;
    function getc(handle: dspl_handle; param: dspl_id): pdspl_chunk;
    //
    function getID(handle: dspl_handle): dspl_int;
    //
    function isseti(handle: dspl_handle; param: dspl_id): dspl_result;
    function issetf(handle: dspl_handle; param: dspl_id): dspl_result;
    function issetc(handle: dspl_handle; param: dspl_id): dspl_result;
    //
    function getVersion(): AnsiString;
    //
    property libResult: dspl_result read f_libResult;
  end;



// --  --
function isZeroE(z: extended): bool;
function ceil(const x: extended): int;
function floor(const x: extended): int;
//
function pow(const base, exponent: dspl_double): dspl_double;
function sinh(const x: extended): extended;

// --  --
function db2v(decibels: dspl_float): dspl_float;
function v2db(voltage: dspl_float): dspl_float;


implementation


uses
  unaUtils, Math;



{$IFDEF CPU64 }

{ Invariant: Y >= 0 & Result*X**Y = X**I.  Init Y = I and Result = 1. }
function IntPower(const base: Extended; const exponent: int): Extended;
var
  Y: Integer;
  X: Extended;
begin
  X := base;
  Y := Abs(exponent);
  Result := 1.0;
  while Y > 0 do begin
    //
    while not Odd(Y) do begin
      //
      Y := Y shr 1;
      X := X * X;
    end;
    //
    Dec(Y);
    result := result * base
  end;
  //
  if exponent < 0 then
    Result := 1.0 / Result
end;

{$ELSE }

// --  --
function intPower(const base: extended; const exponent: int): extended;
asm
	mov     ecx, eax
	cdq
	fld1                      { Result := 1 }
	xor     eax, edx
	sub     eax, edx          { eax := Abs(Exponent) }
	jz      @@3

	fld     Base
	jmp     @@2

@@1:    fmul    ST, ST            { X := Base * Base }

@@2:    shr     eax,1
	jnc     @@1

	fmul    ST(1),ST          { Result := Result * X }
	jnz     @@1

	fstp    st                { pop X from FPU stack }
	cmp     ecx, 0
	jge     @@3

	fld1
	fdivrp                    { Result := 1 / Result }
@@3:
	fwait
end;

{$ENDIF CPU64 }

const
  // --  --
  FuzzFactor = 1000;
  ExtendedResolution = 1E-19 * FuzzFactor;
  DoubleResolution   = 1E-15 * FuzzFactor;
  SingleResolution   = 1E-7 * FuzzFactor;

// --  --
function isZeroE(z: extended): bool; overload;
begin
  result := (abs(z) <= extendedResolution);
end;

// --  --
function ceil(const x: extended): int;
begin
  result := int(trunc(x));
  if (0 < frac(x)) then
    inc(result);
end;

// --  --
function floor(const x: extended): int;
begin
  result := int(trunc(x));
  if (0 > frac(x)) then
    dec(result);
end;

// --  --
function isZeroD(z: dspl_double): bool;
begin
  result := (abs(z) <= doubleResolution);
end;

// --  --
function isZeroF(z: dspl_float): bool;
begin
  result := (abs(z) <= singleResolution);
end;

// --  --
function pow(const base, exponent: dspl_double): dspl_double;
begin
  if (isZeroD(exponent)) then
    result := 1.0               { n**0 = 1 }
  else
    if (isZeroD(base) and (exponent > 0.0)) then
      result := 0.0               { 0**n = 0, n > 0 }
    else
      if (isZeroD(frac(exponent)) and (abs(exponent) <= maxInt)) then
	result := intPower(base, int32(trunc(exponent)))
      else
	result := exp(exponent * ln(base));
  //
end;

// --  --
function sinh(const x: extended): extended;
begin
  if (isZeroE(x)) then
    result := 0
  else
    result := (exp(x) - exp(-x)) / 2;
end;

// --  --
function db2v(decibels: dspl_float): dspl_float;
begin
  result := pow(10, decibels / 20);
end;

// --  --
function v2db(voltage: dspl_float): dspl_float;
begin
  result := 10 * Log10(voltage * voltage);
end;


{ unaDspLibAbstract }

// --  --
function unaDspLibAbstract.createObj(object_id: dspl_id): dspl_handle;
begin
  result := dspl_create(object_id);
end;

// --  --
function unaDspLibAbstract.destroyObj(handle: dspl_handle): dspl_result;
begin
  result := dspl_destroy(handle);
end;

// --  --
function unaDspLibAbstract.getc(handle: dspl_handle; param: dspl_id): pdspl_chunk;
begin
  result := dspl_getc(handle, param);
end;

// --  --
function unaDspLibAbstract.getf(handle: dspl_handle; param: dspl_id): dspl_float;
begin
  result := dspl_getf(handle, param);
end;

// --  --
function unaDspLibAbstract.geti(handle: dspl_handle; param: dspl_id): dspl_int;
begin
  result := dspl_geti(handle, param);
end;

// --  --
function unaDspLibAbstract.getID(handle: dspl_handle): dspl_int;
begin
  result := dspl_getID(handle);
end;

// --  --
function unaDspLibAbstract.getVersion(): AnsiString;
begin
  result := dspl_version();
end;

// --  --
function unaDspLibAbstract.issetc(handle: dspl_handle; param: dspl_id): dspl_result;
begin
  result := dspl_issetc(handle, param);
end;

// --  --
function unaDspLibAbstract.issetf(handle: dspl_handle; param: dspl_id): dspl_result;
begin
  result := dspl_issetf(handle, param);
end;

// --  --
function unaDspLibAbstract.isseti(handle: dspl_handle; param: dspl_id): dspl_result;
begin
  result := dspl_isseti(handle, param);
end;

// --  --
function unaDspLibAbstract.process(handle: dspl_handle; nSamples: dspl_int): dspl_result;
begin
  result := dspl_process(handle, nSamples);
end;

// --  --
function unaDspLibAbstract.setc(handle: dspl_handle; param: dspl_id; chunk: pdspl_float; length: dspl_int): dspl_result;
begin
  result := dspl_setc(handle, param, chunk, length);
end;

// --  --
function unaDspLibAbstract.setf(handle: dspl_handle; param: dspl_id; value: dspl_float): dspl_result;
begin
  result := dspl_setf(handle, param, value);
end;

// --  --
function unaDspLibAbstract.seti(handle: dspl_handle; param: dspl_id; value: dspl_int): dspl_result;
begin
  result := dspl_seti(handle, param, value);
end;


end.

