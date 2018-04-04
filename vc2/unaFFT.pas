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
	  unaFFT.pas

	  Simple implementation of FFT
	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 29 Sep 2011

	  modified by:
		Lake, Sep-Oct 2011

	----------------------------------------------
*)

{$I unaDef.inc }

{*
	FFT implementation

}

unit
  unaFFT;

interface

uses
  unaTypes, unaClasses;

const
  c_max_steps		= 25;				// max windows size = 32MB ( 33554432 ) samples
  c_max_windowSize	= 1 shl c_max_steps;

type
  punaFFT_R	= ^unaFFT_R;
  punaFFT_ws 	= ^unaFFT_ws;
  unaFFT_R	= array[0..c_max_windowSize - 1] of int;
  unaFFT_ws	= array[0..c_max_windowSize shr 1 - 1] of tComplexFloat;

  {*
	Simple FFT.
  }
  unaFFTclass = class(unaObject)
  private
    f_r: punaFFT_R;
    f_ws: punaFFT_ws;
    //
    f_log2ws: int;
    f_windowSize: int;
    //
    procedure fFFT_float(samples: pComplexFloatArray; count: int; X: pComplexFloatArray; index: int; depth: int; inverse: bool);
    {*
	Convolution.
    }
    procedure fFFT_conv(X: pComplexFloatArray; offs, count, depth: int);
    //
    procedure setLog2ws(value: int);
    //
    function getR(index: int): int;
    function getWS(index: int): tComplexFloat;
  protected
    {*
	//
    }
    procedure fFFT_reduce(X: pComplexFloat; offs, count, maxDepth: int; depth: int = 0);
    //
    // this could be useful
    property r[index: int]: int read getR;
    property ws[index: int]: tComplexFloat read getWS;
    {*
	log2(windowSize)
    }
    property log2ws: int read f_log2ws write setLog2ws;
  public
    {*
	Creates and FFT objec and prepares internal variables for FFT.

	@param T windowsSize = 2**T
    }
    constructor create(T: int);
    //
    destructor Destroy(); override;
    {*
	Prepares internal variables for FFT.

	@param T windowsSize = 2**T
    }
    procedure setup(T: int);
    {*
	FFT, real input (single)
    }
    procedure fft(input: pFloat; output: pComplexFloat); overload;
    {*
	FFT, real input (single)
    }
    procedure fft(input: pFloatArray; output: pComplexFloatArray); overload;
    {*
	FFT, complex input (single)
    }
    procedure fft(input: pComplexFloat; output: pComplexFloat); overload;
    {*
	FFT, complex input (single)
    }
    procedure fft(input: pComplexFloatArray; output: pComplexFloatArray); overload;
    {*
	Inverse FFT on complex values (single)
    }
    procedure fftInverse(input: pComplexFloat; output: pComplexFloat); overload;
    {*
	Inverse FFT on complex values (single)
    }
    procedure fftInverse(input: pComplexFloatArray; output: pComplexFloatArray); overload;
    {*
    	Size of windows (in samples).
    }
    property windowSize: int read f_windowSize;
  end;

{*
	mirrors bits
}
function bitReverse(x, steps: unsigned): unsigned;


implementation

//
uses
  unaUtils;

// --  --
procedure addComplex(const a, b: tComplexFloat; var r: tComplexFloat);{$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
begin
  r.re := a.re + b.re;
  r.im := a.im + b.im;
end;

// --  --
procedure subComplex(const a, b: tComplexFloat; var r: tComplexFloat);{$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
begin
  r.re := a.re - b.re;
  r.im := a.im - b.im;
end;

// --  --
procedure mulComplex(const a, b: tComplexFloat; var r: tComplexFloat);{$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
begin
  r.re := a.re * b.re - a.im * b.im;
  r.im := a.re * b.im + a.im * b.re;
end;

// --  --
function bitReverse(x, steps: unsigned): unsigned;
asm
{$IFDEF CPU64 }
{
	IN RCX = x
	IN RDX = steps

	OUT RAX = result
}
        mov     rax, x		// RAX = RCX
	mov	rcx, steps	// RCX = RDX
        //
	and	rcx, $3F	// 0..63
        or      rcx, rcx
	jz	@done
	//
	mov     r8, rcx
  @loop:
	ror	rax, 1
	rcl	rdx, 1
	loop	@loop
	//
	mov     rcx, r8
	//
	neg	rcx
	add	rcx, 64
	shl	rdx, cl		// clear high cl bits
	shr	rdx, cl
        //
	mov	rax, rdx
  @done:
{$ELSE }
{
	IN EAX = x
	IN EDX = steps

	OUT EAX = result
}
	mov	ecx, edx
	and	ecx, $1F	// 0..31
	jecxz	@done
	//
	push	ecx
  @loop:
	ror	eax, 1
	rcl	edx, 1
	loop	@loop
	//
	pop	ecx
	//
	neg	ecx
	add	ecx, 32
	shl	edx, cl		// clear high cl bits
	shr	edx, cl
	//
	mov	eax, edx
  @done:
{$ENDIF CPU64 }
end;


{ unaFFTclass }

// --  --
constructor unaFFTclass.create(T: int);
begin
  setup(T);
  //
  inherited create();
end;

// --  --
destructor unaFFTclass.Destroy;
begin
  inherited;
  //
  mrealloc(f_ws);
  mrealloc(f_r);
end;

// --  --
procedure unaFFTclass.fFFT_float(samples: pComplexFloatArray; count: int; X: pComplexFloatArray; index, depth: int; inverse: bool);
var
  k: int;
  tcWXo, invW: tComplexFloat;
  s, i, half: int;
  sameBuf: bool;
begin
  if (0 = depth) then begin
    //
    sameBuf := pointer(samples) = pointer(X);
    //
    // one time bit-reverse samples reordering
    for s := 0 to windowSize - 1 do begin
      //
      if (sameBuf) then begin
	//
	if (s < f_r[s]) then begin
	  //
	  // need this since samples and X are pointing to the same buffer
	  invW := samples[s];
	  X[    s ] := samples[f_r[s]];
	  X[f_r[s]] := invW;
	end;
	//
      end
      else begin
	//
	// read input and do the first FFT step on it
	if (0 = (1 and s)) then begin
	  //
	  addComplex(samples[f_r[s]], samples[f_r[s + 1]], X[s    ]);
	  subComplex(samples[f_r[s]], samples[f_r[s + 1]], X[s + 1]);
	end;
      end;
    end;
    //
    if (sameBuf) then begin
      //
      // now (and only now) we can also do first FFT step on input array
      for s := 0 to windowSize shr 1 - 1 do begin
	//
	i := s shl 1;
	addComplex(X[i], X[i + 1], invW);
	subComplex(X[i], X[i + 1], X[i + 1]);
	X[i] := invW;
      end;
    end;
  end;
  //
  if (depth < log2ws - 1) then begin
    //
    half := count shr 1;
    //
    fFFT_float(samples, half, X, index + 0   , depth + 1, inverse);	// even
    fFFT_float(samples, half, X, index + half, depth + 1, inverse);	// odd
    //
    for k := 0 to half - 1 do begin
      //
      // X[k       ] := X[k] + WT**k * X[k + half];  // even
      // X[k + half] := X[k] - WT**k * X[k + half];  // odd
      //
      if (inverse) then begin
	//
	invW := f_ws[k shl depth];
	invW.im := -invW.im;
	mulComplex(X[index + half + k], invW, tcWXo);
      end
      else
	mulComplex(X[index + half + k], f_ws[k shl depth], tcWXo);
      //
      subComplex(X[index +        k], tcWXo, X[index + half + k]);
      addComplex(X[index +        k], tcWXo, X[index + 0    + k]);
    end;
  end;
end;

// --  --
procedure unaFFTclass.fFFT_reduce(X: pComplexFloat; offs, count, maxDepth, depth: int);
var
  half: int;
begin
  if (depth < maxDepth) then begin
    //
    half := count shr 1;
    //
    fFFT_reduce(X, offs + 0   , half, maxDepth, depth + 1);		// even
    fFFT_reduce(X, offs + half, half, maxDepth, depth + 1);		// odd
  end;
  //
  fFFT_conv(pComplexFloatArray(X), offs, count, depth);
end;

// --  --
procedure unaFFTclass.fft(input: pFloat; output: pComplexFloat);
begin
  fft(pFloatArray(input), pComplexFloatArray(output));
end;

// --  --
procedure unaFFTclass.fft(input, output: pComplexFloat);
begin
  fFFT_float(pComplexFloatArray(input), windowSize, pComplexFloatArray(output), 0, 0, false);
end;

// --  --
procedure unaFFTclass.fft(input: pFloatArray; output: pComplexFloatArray);
var
  s: int;
begin
  // use output to store input complex samples
  for s := 0 to windowSize - 1 do begin
    //
    output[s].re := input[s];
    output[s].im := 0.0;
  end;
  //
  fFFT_float(output, windowSize, output, 0, 0, false);
end;

// --  --
procedure unaFFTclass.fft(input, output: pComplexFloatArray);
begin
  fFFT_float(input, windowSize, output, 0, 0, false);
end;

// --  --
procedure unaFFTclass.fftInverse(input, output: pComplexFloatArray);
var
  s: int;
begin
  fFFT_float(input, windowSize, output, 0, 0, true);
  //
  // scale output values back to original
  for s := 0 to windowSize - 1 do begin
    //
    output[s].re := output[s].re / windowSize;
    output[s].im := output[s].im / windowSize;
  end;
end;

// --  --
procedure unaFFTclass.fftInverse(input, output: pComplexFloat);
begin
  fftInverse(pComplexFloatArray(input), pComplexFloatArray(output));
end;

// --  --
procedure unaFFTclass.fFFT_conv(X: pComplexFloatArray; offs, count, depth: int);
var
  k: int;
  tcWXo: tComplexFloat;
  half: int;
begin
  half := count shr 1;
  //
  for k := 0 to half - 1 do begin
    //
    // X[k] := Xe[k] + WN**k * Xo[k];
    mulComplex(X[offs + half + k], f_ws[k shl depth], tcWXo);
    //
    // X[count shr 1 + k] := Xe[k] - WN**k * Xo[k];
    subComplex(X[offs +        k], tcWXo, X[offs + half + k]);
    //
    addComplex(X[offs +        k], tcWXo, X[offs + 0    + k]);
  end;
end;

// --  --
function unaFFTclass.getR(index: int): int;
begin
  result := f_r[index];
end;

// --  --
function unaFFTclass.getWS(index: int): tComplexFloat;
begin
  result := f_ws[index];
end;

// --  --
procedure unaFFTclass.setLog2ws(value: int);
begin
  setup(value);
end;

// --  --
procedure unaFFTclass.setup(T: int);
var
  k: int;
begin
  if (T > c_max_steps) then
    T := c_max_steps;
  //
  if (T < 1) then
    T := 1;
  //
  if (log2ws <> T) then begin
    //
    f_log2ws := T;
    //
    f_windowSize := 1 shl log2ws;
    //
    mrealloc(f_ws, (windowSize shr 1) * sizeof(f_ws[0]));
    mrealloc(f_r ,         windowSize * sizeof(f_r[0]));
    //
    f_ws[0].re :=  1.0;	//  cos(0)
    f_ws[0].im := -0.0;	// -sin(0)
    for k := 1 to windowSize shr 1 - 1 do begin
      //
      f_ws[k].re :=   cos(2 * Pi * k / windowSize);
      f_ws[k].im :=  -sin(2 * Pi * k / windowSize);
    end;
    //
    for k := 0 to windowSize - 1 do
      f_r[k] := bitReverse(k, log2ws);	//
  end;
end;


end.

