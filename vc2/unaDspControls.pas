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

	  unaDspControls.pas - DSP components and controls
	  Voice Communicator components version 2.5 DSP

	----------------------------------------------
	  Copyright (c) 2003-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 03 Nov 2003

	  modified by:
		Lake, Nov 2003
		Lake, Oct 2011

	----------------------------------------------
*)

{$I unaDef.inc }

{*
  FFT and DTMF VCL components.

  @Author Lake

  2.5.2008.07 Still here

  2.5.2011.10 +drawStyle, +fallback, +grid
}

unit
  unaDspControls;

interface

uses
  Windows, unaTypes, unaClasses, unaMsAcmAPI, unaMsAcmClasses,
  unaWave, unaVC_pipe, unaVC_wave, unaDSP,
{$IFDEF FMX }
  System.Types, System.UITypes, FMX.Types,
{$ELSE }
  {$IFDEF __AFTER_DE__ }
  Vcl.Graphics, Vcl.Controls, Vcl.ExtCtrls,
  {$ELSE }
  Graphics, Controls, ExtCtrls,
  {$ENDIF __AFTER_DE__ }
{$ENDIF FMX }
  Classes;


type
  //
  punaMBSPBands = ^unaMBSPBands;
  unaMBSPBands = array[byte] of pFloatArray;	// up to 256 bands

  //
  {*
	FFT Pipe
  }
  TunadspFFTPipe = class(unavclInOutPipe)
  private
    f_fft: unadspFFT;
    //
    f_timer: unaMMTimer;
    f_dataProxy: array[word] of byte;
    f_channel: unsigned;	// for one channel only
    //
    f_localFormat: pointer;
    f_localFormatSize: unsigned;
    f_onFFTDone: tNotifyEvent;
    //
    function getInterval(): unsigned;
    procedure setInterval(value: unsigned);
    //
    procedure onTimer(sender: tObject);
  protected
    {*
      Opens the pipe.
    }
    function doOpen(): bool; override;
    {*
      Closes the pipe.
    }
    procedure doClose(); override;
    {*
      Writes data into the pipe.
    }
    function doWrite(data: pointer; len: uint; provider: pointer = nil): uint; override;
    {*
      Reads data from the pipe.
    }
    function doRead(data: pointer; len: uint): uint; override;
    {*
      Returns available data size in the pipe.
    }
    function getAvailableDataLen(index: integer): uint; override;
    {*
        Returns active state of the pipe.
    }
    function isActive(): bool; override;
    {*
        Applies new format of the stream to the pipe.
    }
    function applyFormat(data: pointer; len: uint; provider: unavclInOutPipe = nil; restoreActiveState: bool = false): bool; override;
    {*
      Fills the format of the pipe stream.
    }
    function getFormatExchangeData(out data: pointer): uint; override;
  public
    procedure AfterConstruction(); override;
    procedure BeforeDestruction(); override;
    //
    property updateInterval: unsigned read getInterval write setInterval;
    //
    property fft: unadspFFT read f_fft;
    //
    property channel: unsigned read f_channel write f_channel;
    //
    property onFFTDone: tNotifyEvent read f_onFFTDone write f_onFFTDone;
  end;


const
  cldef_BandLow		= $00808080;
  cldef_BandMed		= $00A0A0A0;
  cldef_BandTop		= $00C0C0C0;
  cldef_BandGrid	= $00FFFFFF;

type
  TunadspFFTDrawStype = (unaFFTDraw_Solid, unaFFTDraw_Line, unaFFTDraw_Dots);


  {*
	FFT Control
  }
{$IFDEF FMX }
  TunadspFFTControl = class(TControl)
{$ELSE }
  TunadspFFTControl = class(tGraphicControl)
{$ENDIF FMX }
  private
    f_pipe: TunadspFFTPipe;
    f_bandWidth: unsigned;
    f_bandGap: unsigned;
    f_fallback: int;
    f_fallbackf: double;
    f_dstyle: TunadspFFTDrawStype;
    f_drawGrid: boolean;
    //
    f_dbUpdate: int;
    f_dbPeak: double;
    //
    f_penColor: array[0..3] of tColor;
  {$IFDEF FMX }
    f_backColor: TColor;
  {$ELSE }
    f_pen: array[0..3] of hPen;
  {$ENDIF FMX }
    //
    f_fftCache: pComplexFloatArray;
    f_amp: pFloatArray;
    f_ampMax: double;
    //
    function getSteps(): unsigned;
    procedure setSteps(value: unsigned);
    function getInterval: unsigned;
    procedure setInterval(value: unsigned);
    function getChannel(): unsigned;
    procedure setChannel(value: unsigned);
    procedure setColorBack(value: tColor);
    function getColorBack(): tColor;
    function getActive(): boolean;
    procedure setActive(value: boolean);
    //
    function getBandColor(index: integer): tColor;
    procedure setBandColor(index: integer; value: tColor);
    procedure setFallback(const Value: int);
  protected
    procedure Paint(); override;
    //
    procedure paintOnDC({$IFDEF FMX }Canv: TCanvas{$ELSE }dc: hDC{$ENDIF FMX }); virtual;
    //
    procedure onFFTDone(sender: tObject); virtual;
  public
    procedure AfterConstruction(); override;
    procedure BeforeDestruction(); override;
    //
    function displayMBSPBands(numBands: unsigned; values: punaMBSPBands; nSamples: unsigned): bool;
    {*
	Internal data pipe.
    }
    property fft: TunadspFFTPipe read f_pipe;
  published
    {*
	Width of each bar/band in pixels.
    }
    property bandWidth: unsigned read f_bandWidth write f_bandWidth default 1;
    {*
	Gap between bars/bands in pixels.
    }
    property bandGap: unsigned read f_bandGap write f_bandGap default 0;
    {*
	FFT steps = log2(windowSize).
    }
    property steps: unsigned read getSteps write setSteps default 8;
    {*
	Update interval (milliseconds).
    }
    property interval: unsigned read getInterval write setInterval default 100;
    {*
	Channle number to display spectrum for.
    }
    property channel: unsigned read getChannel write setChannel default 0;
    {*
	Background color.
    }
    property color: tColor read getColorBack write setColorBack default {$IFDEF FMX }TColorRec.Black{$ELSE } clBlack{$ENDIF FMX };
    {*
	Color of low portion of a bar.
    }
    property bandColorLow: tColor index 0 read getBandColor write setBandColor default cldef_BandLow;
    {*
	Color of medium portion of a bar.
    }
    property bandColorMed: tColor index 1 read getBandColor write setBandColor default cldef_BandMed;
    {*
	Color of top portion of a bar.
    }
    property bandColorTop: tColor index 2 read getBandColor write setBandColor default cldef_BandTop;
    {*
	Color of grid.
    }
    property bandColorGrid: tColor index 3 read getBandColor write setBandColor default cldef_BandGrid;
    {*
	Draw grid.
    }
    property drawGrid: boolean read f_drawGrid write f_drawGrid default true;
    {*
	Draw style.
    }
    property drawStyle: TunadspFFTDrawStype read f_dstyle write f_dstyle default unaFFTDraw_Solid;
    {*
	Fallback speed, 0 (instant) or from 1 (quite slow) to 99 (quite fast).
    }
    property fallback: int read f_fallback write setFallback default 80;
    {*
	Specifies whether this control is active and should display bars.
    }
    property active: boolean read getActive write setActive default false;
    //
    property Anchors;
    property Align;
{$IFDEF FMX }
{$ELSE }
    property Font;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
{$ENDIF FMX }
    property PopupMenu;
    property Visible;
    //
    property OnClick;
{$IFDEF __BEFORE_D6__ }
{$ELSE }
  {$IFDEF FMX }
  {$ELSE }
    property OnContextPopup;
    property OnMouseWheelDown;
    property OnMouseWheelUp;
  {$ENDIF FMX }
    property OnMouseWheel;
{$ENDIF __BEFORE_D6__ }
    property OnDblClick;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
  end;


  {*
	DTMF Control
  }
  TunavclDTMFDecoder = class(unavclInOutWavePipe)
  private
    f_isActive: bool;
    f_decoder: unaDspDTMFDecoder;
    //
    function getThreshold(): int;
    procedure setThreshold(value: int);
    function getOnCodeDE(): tDTMFCodeDetectedEvent;
    procedure setOnCodeDE(value: tDTMFCodeDetectedEvent);
  protected
    function applyDeviceFormat(format: PWAVEFORMATEXTENSIBLE; isSrc: bool = true): bool; override;
    //
    function doWrite(data: pointer; len: uint; provider: pointer = nil): uint; override;
    function getAvailableDataLen(index: integer): uint; override;
    function doOpen(): bool; override;
    procedure doClose(); override;
    function  isActive(): bool; override;
  public
    procedure AfterConstruction(); override;
    procedure BeforeDestruction(); override;
    //
  published
    property threshold: int read getThreshold write setThreshold default c_def_dtmfd_LVS;
    //
    {*
	Fires when new DTMF code is detected.
    }
    property onDTMFCodeDetected: tDTMFCodeDetectedEvent read getOnCodeDE write setOnCodeDE;
  end;


// --  --
procedure Register();


implementation


uses
  unaUtils,
{$IFDEF __AFTER_DE__ }
  UITypes,
{$ENDIF __AFTER_DE__ }
  Math;

{ TunadspFFTPipe }

// --  --
procedure TunadspFFTPipe.afterConstruction();
begin
  f_timer := unaMMTimer.create(100);
  f_timer.onTimer := onTimer;
  //
  f_fft := unadspFFT.create(1 shl 1);
  //
  f_localFormat := nil;
  //
  inherited;
end;

// --  --
function TunadspFFTPipe.applyFormat(data: pointer; len: uint; provider: unavclInOutPipe; restoreActiveState: bool): bool;
begin
  if (enter(false, 100)) then
    try
      mrealloc(f_localFormat, len);
      f_localFormatSize := len;
      //
      if (0 < len) then
	move(data^, f_localFormat^, len);
      //
      with (punavclWavePipeFormatExchange(data).r_formatM) do
	fft.setFormat(formatOriginal.pcmSamplesPerSecond, formatOriginal.pcmBitsPerSample, formatOriginal.pcmNumChannels);
      //
    finally
      leaveWO();
    end;
  //
  result := inherited applyFormat(data, len, provider, restoreActiveState);
end;

// --  --
procedure TunadspFFTPipe.beforeDestruction();
begin
  inherited;
  //
  freeAndNil(f_fft);
  freeAndNil(f_timer);
  mrealloc(f_localFormat);
end;

// --  --
procedure TunadspFFTPipe.doClose();
begin
  f_timer.stop();
  //
  inherited;
end;

// --  --
function TunadspFFTPipe.doOpen(): bool;
begin
  result := inherited doOpen();
  //
  if (result) then
    f_timer.start();
end;

// --  --
function TunadspFFTPipe.doRead(data: pointer; len: uint): uint;
begin
  result := 0;
end;

// --  --
function TunadspFFTPipe.doWrite(data: pointer; len: uint; provider: pointer): uint;
begin
  // copy new data locally
  if (0 < len) then begin
    //
    if (active and enter(false, 100)) then try
      //
      move(data^, f_dataProxy, unaUtils.min(sizeof(f_dataProxy), len));
    finally
      leaveWO();
    end;
  end;
  //
  // pass data to consumers
  onNewData(data, len, self);
  //
  result := len;
end;

// --  --
function TunadspFFTPipe.getAvailableDataLen(index: integer): uint;
begin
  result := 0;
end;

// --  --
function TunadspFFTPipe.getFormatExchangeData(out data: pointer): uint;
begin
  if (enter(true, 100)) then begin
    try
      result := f_localFormatSize;
      //
      if (0 < result) then begin
        //
	data := malloc(result);
	move(f_localFormat^, data^, result);
      end
      else
	data := nil;
      //
    finally
      leaveRO();
    end;
  end
  else begin
    //
    data := nil;
    result := 0;
  end;
end;

// --  --
function TunadspFFTPipe.getInterval(): unsigned;
begin
  result := f_timer.interval;
end;

// --  --
function TunadspFFTPipe.isActive(): bool;
begin
  result := f_timer.isRunning();
end;

// --  --
procedure TunadspFFTPipe.onTimer(sender: tObject);
begin
  if (active and enter(true, 100)) then
    try
      fft.fft_complex_forward(@f_dataProxy, f_channel);
    finally
      leaveRO();
    end;
  //
  if (assigned(f_onFFTDone)) then
    f_onFFTDone(self);
end;

// --  --
procedure TunadspFFTPipe.setInterval(value: unsigned);
begin
  f_timer.interval := value;
end;


{ TunadspFFTControl }

// --  --
procedure TunadspFFTControl.afterConstruction();
begin
  f_pipe := TunadspFFTPipe.create(nil);
  f_pipe.onFFTDone := onFFTDone;
  //
  f_bandWidth := 1;
  //
{$IFDEF FMX }
{$ELSE }
  canvas.brush.color := clBlack;
{$ENDIF FMX }
  //
  bandColorLow  := cldef_BandLow;
  bandColorMed  := cldef_BandMed;
  bandColorTop  := cldef_BandTop;
  bandColorGrid := cldef_BandGrid;
  //
  drawStyle := unaFFTDraw_Solid;
  drawGrid := true;
  //
  fallback := 80;
  //
  width := 100;
  height := 200;
  //
{$IFDEF FMX }
{$ELSE }
  controlStyle := controlStyle + [csOpaque];
{$ENDIF FMX }
  //
  inherited;
  //
  steps := 8;
end;

// --  --
procedure TunadspFFTControl.beforeDestruction();
begin
  inherited;
  //
  freeAndNil(f_pipe);
  mrealloc(f_amp);
  mrealloc(f_fftCache);
end;

{$IFDEF FMX }

// --  --
function color2alpha(const c: TColor; A: byte = $FF): TAlphaColor;
begin
  result := TAlphaColor(A shl 24) or (TColorRec(c).R shl 16) or (TColorRec(c).G shl 8) or TColorRec(c).B;
end;

{$ENDIF FMX }


// --  --
function TunadspFFTControl.displayMBSPBands(numBands: unsigned; values: punaMBSPBands; nSamples: unsigned): bool;
var
  dc: hDC;
  b, j, k: int32;
  h, w, x, t: int;
  p: float;
  lh: float;
{$IFDEF FMX }
  P1, P2: TPointF;
{$ELSE }
  rect: tRect;
{$ENDIF FMX }
begin
{$IFDEF FMX }
  Canvas.BeginScene();
{$ELSE }
  canvas.lock();
{$ENDIF FMX }
  try
    //
  {$IFDEF FMX }
    dc := 1;
  {$ELSE }
    dc := canvas.handle;
  {$ENDIF FMX }
    if ((0 <> dc) and (0 < nSamples)) then begin
      //
      // clear background
      //fillRect(dc, clientRect, canvas.brush.handle);
      //
    {$IFDEF FMX }
      h := Canvas.Height;
      w := Canvas.Width;
    {$ELSE }
      h := clientRect.bottom - clientRect.top;
      w := clientRect.right - clientRect.left;
    {$ENDIF FMX }
      //
      if (0 < h) then begin
	//
	// draw bands
	x := f_bandGap;
	lh := log2(h);
	for b := 0 to numBands - 1 do begin
	  //
	  p := 0;
	  for k := 1 to nSamples - 1 do
	    p := p + abs(values[b][k] - values[b][k - 1]);
	  //
	  t := trunc( log2(1 + p * numBands * h / nSamples) / lh * h );
	  if (t < 1) then
	    t := 1;
	  if (t > h) then
	    t := h;
	  //
	  for j := 0 to f_bandWidth - 1 do begin
	    //
	    if (int(x + j) < w) then begin
	      //
	      for k := 0 to 2 do begin
		//
              {$IFDEF FMX }
                Canvas.Stroke.Color := color2alpha(f_penColor[k]);
                //
                P1 := PointF(x + j, h - (t / 3) * (k + 0));
                P2 := PointF(x + j, h - (t / 3) * (k + 1));
                Canvas.DrawLine(P1, P2, 1.0);
              {$ELSE }
		SelectObject(dc, f_pen[k]);
		moveToEx(dc, x + j, h - (t div 3) * (k + 0), nil);
		lineTo  (dc, x + j, h - (t div 3) * (k + 1));
              {$ENDIF FMX }
	      end;
	    end;
	  end;
	  //
	  // clear rest of band
          //
        {$IFDEF FMX }
	  Canvas.FillRect(TRectF.Create(x, x + int(f_bandWidth), 0, h - t), 0, 0, [], 1);
        {$ELSE }
	  rect.left   := x;
	  rect.right  := x + int(f_bandWidth);
	  rect.top    := 0;
	  rect.bottom := h - t;
	  fillRect(dc, rect, canvas.brush.handle);
        {$ENDIF FMX }
	  //
	  inc(x, f_bandWidth);
	  inc(x, f_bandGap);
	end;
      end;
    end;
  finally
{$IFDEF FMX }
    Canvas.EndScene();
{$ELSE }
    canvas.unlock();
{$ENDIF FMX }
  end;
  //
  result := true;
end;

// --  --
function TunadspFFTControl.getActive(): boolean;
begin
  result := fft.active;
end;

// --  --
function TunadspFFTControl.getBandColor(index: integer): tColor;
begin
  result := f_penColor[index];
end;

// --  --
function TunadspFFTControl.getChannel(): unsigned;
begin
  result := f_pipe.channel;
end;

// --  --
function TunadspFFTControl.getColorBack(): tColor;
begin
{$IFDEF FMX }
  result := f_backColor;
{$ELSE }
  result := canvas.brush.color;
{$ENDIF FMX }
end;

// --  --
function TunadspFFTControl.getInterval(): unsigned;
begin
  result := f_pipe.updateInterval;
end;

// --  --
function TunadspFFTControl.getSteps(): unsigned;
begin
  result := f_pipe.fft.steps;
end;

// --  --
procedure TunadspFFTControl.onFFTDone(sender: tObject);
begin
{$IFDEF FMX }
  InvalidateRect(TRectF.Create(0, 0, Width, Height));
{$ELSE }
  invalidate();
{$ENDIF FMX }
end;

// --  --
procedure TunadspFFTControl.paint();
begin
{$IFDEF FMX }
  paintOnDC(Canvas);
{$ELSE }
  with (canvas) do begin
    lock();
    //
    try
      paintOnDC(handle);
    finally
      unlock();
    end;
  end;
{$ENDIF FMX }
end;

// --  --
procedure TunadspFFTControl.paintOnDC({$IFDEF FMX }Canv: TCanvas{$ELSE }dc: hDC{$ENDIF FMX });
var
  j, k, i: integer;
  x: int;
  r, f, fMax, fpeak, fdbStep: double;
  //
  nmaxH: int;	// max number of harmonics
  limit, abs2, abs2min: double;
  s: string;
{$IFDEF FMX }
  State: TCanvasSaveState;
  h, w, w2: float;
{$ELSE }
  h, w, w2: int;
{$ENDIF FMX }
begin
  // clear background
{$IFDEF FMX }
  State := Canv.SaveState;
  try
    h := Height;
    w := Width;
    Canv.Fill.Kind := TBrushKind.bkSolid;
    Canv.Fill.Color := color2alpha(color);
    Canv.FillRect(LocalRect, 0, 0, [], 1);
    Canv.SetClipRects([ClipRect]);
{$ELSE }
    fillRect(dc, clientRect, canvas.brush.handle);
    //
    h := clientRect.bottom - clientRect.top;
    w := clientRect.right - clientRect.left;
{$ENDIF FMX }
    //
    nmaxH := 0;
    //
    if (f_pipe.fft.acquire(true, 10)) then try
      //
      if ((0 < h) and (0 < f_bandWidth) and (nil <> f_amp) and f_pipe.fft.fftReady) then begin
        //
        nmaxH := f_pipe.fft.windowSize shr 1;
        for i := 1 to nmaxH - 1 do
          f_fftCache[i] := f_pipe.fft.dataC[i];
      end;
      //
    finally
      f_pipe.fft.releaseRO();
    end;
    //
    if (0 < nmaxH) then begin
      //
      if (drawGrid) then begin
        //
        // draw grid
        fMax := f_pipe.fft.sampleRate shr 1;
        r := fMax / 2000;
        w2 := int(bandWidth + bandGap) * nmaxH;
        //
      {$IFDEF FMX }
        Canv.Stroke.Kind := TBrushKind.bkSolid;
        Canv.Stroke.Color := color2alpha(f_penColor[3]);
      {$ELSE }
        windows.selectObject(dc, f_pen[3]);
        SetTextColor(dc, bandColorGrid);
      {$ENDIF FMX }
        //
        f := 0;
        i := 0;
        while (f < fMax) do begin
          //
        {$IFDEF FMX }
          Canv.DrawLine(TPointF.Create(i * w2/r, 0), TPointF.Create(i * w2/r, h), 1);
        {$ELSE }
          moveToEx(dc, trunc(i * w2/r), 0, nil);
          lineTo  (dc, trunc(i * w2/r), h);
        {$ENDIF FMX }
          //
          if (0 = i) then
            s := 'kHz'
          else
            s := int2str(trunc(f/1000));
          //
        {$IFDEF FMX }
          Canv.Fill.Color := $FFFFFFFF;
          Canv.FillText(TRectF.Create(TPointF.Create(i * w2/r + 4, 4), Canv.TextWidth(s), Canv.TextHeight(s)), s, false, 1, [], TTextAlign.taLeading);
        {$ELSE }
          TextOut(dc, trunc(i * w2/r) + 4, 4, pchar(s), length(s));
        {$ENDIF FMX }
          //
          f := f + 2000;
          inc(i);
        end;
        //
        i := 0;
        r := h / 10;
        while (i < 10) do begin
          //
        {$IFDEF FMX }
          Canv.DrawLine(TPointF.Create(0, i * r), TPointF.Create(w, i * r), 1);
        {$ELSE }
          moveToEx(dc, 0, trunc(i * r), nil);
          lineTo  (dc, w, trunc(i * r));
        {$ENDIF FMX }
          //
          inc(i);
        end;
      end;
      //
      // draw FFT bands
      //
      limit := 0.00001; // f_fftCache[0].re / 10000;
      abs2min := limit * limit * f_pipe.fft.windowSize * f_pipe.fft.windowSize;
      //
      x := 0;
      r := h / 3.01;
      f_ampMax := f_ampMax * 0.97;
      fpeak := 0;
      //
      for i := 1 to nmaxH - 1 do begin
        //
        abs2 := (f_fftCache[i].re * f_fftCache[i].re) + (f_fftCache[i].im * f_fftCache[i].im);
        f := (2.0 * sqrt(abs2) / f_pipe.fft.windowSize);
        if (fpeak < f) then
          fpeak := f;
        //
        if (abs2min < abs2) then begin
          //
          f_amp[i] := log2(2 + f * 4) - 1;
          if (f_ampMax < f_amp[i] * 1.2) then
            f_ampMax := f_amp[i] * 1.2;
        end
        else begin
          //
          if (1 < f_fallbackf) then
            f_amp[i] := f_amp[i] / f_fallbackf * f_ampMax
          else
            f_amp[i] := 0;
        end;
      end;
      //
      //f_ampMax := log2(2 + fpeak * 4) - 1;
      //
      if (f_ampMax < limit) then
        f_ampMax := limit;
      //
      for i := 1 to nmaxH - 1 do
        f_amp[i] := f_amp[i] / f_ampMax;
      //
      case (drawStyle) of

        unaFFTDraw_Solid: begin
          //
          for i := 1 to nmaxH - 1 do begin
            for j := 0 to f_bandWidth - 1 do begin
              for k := 0 to 2 do begin
                //
              {$IFDEF FMX }
                Canv.Stroke.Color := color2alpha(f_penColor[k]);
                Canv.DrawLine(TPointF.Create(x + j, h - r * f_amp[i] * (k + 0)), TPointF.Create(x + j, h - r * f_amp[i] * (k + 1)), 1);
              {$ELSE }
                windows.selectObject(dc, f_pen[k]);
                moveToEx(dc, x + j, trunc(h - r * f_amp[i] * (k + 0)), nil);
                lineTo  (dc, x + j, trunc(h - r * f_amp[i] * (k + 1)));
              {$ENDIF FMX }
              end;
            end;
            //
            inc(x, bandWidth);
            inc(x, bandGap);
          end;
        end;

        unaFFTDraw_Line: begin
          //
        {$IFDEF FMX }
        {$ELSE }
          windows.selectObject(dc, f_pen[2]);
          moveToEx(dc, 0, h, nil);
        {$ENDIF FMX }
          for i := 1 to nmaxH - 1 do begin
            for j := 0 to f_bandWidth - 1 do begin
              //
            {$IFDEF FMX }
            {$ELSE }
              lineTo  (dc, x + j, trunc(h - r * f_amp[i] * (2 + 1)));
            {$ENDIF FMX }
            end;
            //
            inc(x, bandWidth);
            inc(x, bandGap);
          end;
        end;

        unaFFTDraw_Dots: begin
          //
          for i := 1 to nmaxH - 1 do begin
            for j := 0 to f_bandWidth - 1 do begin
              //
            {$IFDEF FMX }
            {$ELSE }
              setPixel(dc, x + j, trunc(h - r * f_amp[i] * (0 + 1)), bandColorLow);
              setPixel(dc, x + j, trunc(h - r * f_amp[i] * (1 + 1)), bandColorMed);
              setPixel(dc, x + j, trunc(h - r * f_amp[i] * (2 + 1)), bandColorTop);
            {$ENDIF FMX }
            end;
            //
            inc(x, bandWidth);
            inc(x, bandGap);
          end;
        end;

      end; // case
      //
      if (drawGrid) then begin
        //
        inc(f_dbUpdate);
        if (6 < f_dbUpdate) then begin
          //
          if (0 < fpeak) then
            fpeak := 0 - 10 * log10(1 / fpeak)
          else
            fpeak := -60;
          //
          f_dbPeak := f_dbPeak + (fpeak - f_dbPeak) / 3;
          //
          f_dbUpdate := 0;
        end;
        //
        fdbStep := (60 + f_dbPeak) / 10;
        //
      {$IFDEF FMX }
      {$ELSE }
        SetTextColor(dc, bandColorGrid);
      {$ENDIF FMX }
        for i := 1 to 9 do begin
          //
          s := '   ' + int2str(trunc(f_dbPeak - i * fdbStep)) + ' dB   ';
        {$IFDEF FMX }
        {$ELSE }
          TextOut(dc, w - 70, i * h div 10 - 8, pchar(s), length(s));
        {$ENDIF FMX }
        end;
      end;
    end;
{$IFDEF FMX }
  finally
    Canv.RestoreState(State);
  end;
{$ENDIF FMX }
end;

// --  --
procedure TunadspFFTControl.setActive(value: boolean);
begin
  fft.active := value;
end;

// --  --
procedure TunadspFFTControl.setBandColor(index: integer; value: tColor);
begin
  f_penColor[index] := value;
  //
{$IFDEF FMX }
  Repaint();
{$ELSE }
  //
  windows.deleteObject(f_pen[index]);
  f_pen[index] := windows.createPen(PS_SOLID, 1, value);
  //
  refresh();
{$ENDIF FMX }
end;

// --  --
procedure TunadspFFTControl.setChannel(value: unsigned);
begin
  f_pipe.channel := value;
end;

// --  --
procedure TunadspFFTControl.setColorBack(value: tColor);
begin
{$IFDEF FMX }
  f_backColor := value;
  Repaint();
{$ELSE }
  canvas.brush.color := value;
  refresh();
{$ENDIF FMX }
end;

// --  --
procedure TunadspFFTControl.setFallback(const Value: int);
begin
  if ((0 <= value) and (value < 100)) then begin
    //
    f_fallback := value;
    if (0 = value) then
      f_fallbackf := 0
    else
      f_fallbackf := 1 + value / 100;
  end;
end;

// --  --
procedure TunadspFFTControl.setInterval(value: unsigned);
begin
  f_pipe.updateInterval := value;
end;

// --  --
procedure TunadspFFTControl.setSteps(value: unsigned);
begin
  f_pipe.fft.steps := value;
  //
  mrealloc(f_amp, sizeof(f_amp[0]) * (1 shl value));
  fillChar(f_amp^, sizeof(f_amp[0]) * (1 shl value), #0);
  //
  mrealloc(f_fftCache, sizeof(f_fftCache[0]) * (1 shl value));
  //
  f_ampMax := 0;
end;


{ TunavclDTMFDecoder }

// --  --
procedure TunavclDTMFDecoder.AfterConstruction();
begin
  f_decoder := unaDspDTMFDecoder.create();
  //
  inherited;
end;

// --  --
function TunavclDTMFDecoder.applyDeviceFormat(format: PWAVEFORMATEXTENSIBLE; isSrc: bool): bool;
begin
  if (nil <> f_decoder) then
    result := SUCCEEDED(f_decoder.setFormat(format.format.nSamplesPerSec, format.format.wBitsPerSample, format.format.nChannels))
  else
    result := false;  
end;

// --  --
procedure TunavclDTMFDecoder.BeforeDestruction();
begin
  inherited;
  //
  freeAndNil(f_decoder);
end;

// --  --
procedure TunavclDTMFDecoder.doClose();
begin
  inherited;
  //
  f_isActive := false;
  //
  f_decoder.clearState();
end;

// --  --
function TunavclDTMFDecoder.doOpen(): bool;
begin
  result := inherited doOpen();
  //
  f_isActive := result;
end;

// --  --
function TunavclDTMFDecoder.doWrite(data: pointer; len: uint; provider: pointer): uint;
begin
  if (SUCCEEDED(f_decoder.write(data, len))) then
    result := len
  else
    result := 0;
end;

// --  --
function TunavclDTMFDecoder.getAvailableDataLen(index: integer): uint;
begin
  result := 0;
end;

// --  --
function TunavclDTMFDecoder.getOnCodeDE(): tDTMFCodeDetectedEvent;
begin
  result := f_decoder.onDTMFCodeDetected;
end;

// --  --
function TunavclDTMFDecoder.getThreshold(): int;
begin
  result := f_decoder.threshold;
end;

// --  --
function TunavclDTMFDecoder.isActive(): bool;
begin
  result := f_isActive;
end;

// --  --
procedure TunavclDTMFDecoder.setOnCodeDE(value: tDTMFCodeDetectedEvent);
begin
  f_decoder.onDTMFCodeDetected := value;
end;

// --  --
procedure TunavclDTMFDecoder.setThreshold(value: int);
begin
  f_decoder.threshold := value;
end;



// --------

// --  --
procedure Register();
begin
{$IFDEF FMX }
  RegisterFmxClasses([
{$ELSE }
  RegisterComponents(c_VC_reg_DSP_section_name, [
{$ENDIF FMX }
    TunadspFFTPipe,
    TunadspFFTControl,
    TunavclDTMFDecoder
  ]);
end;


end.

