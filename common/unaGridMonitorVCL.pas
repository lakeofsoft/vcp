
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

{$I unaDef.inc}

unit
  unaGridMonitorVCL;

interface

uses
  Windows, unaTypes, unaClasses,
  Classes, Graphics, Controls;

const
  //
  cldef_gridColor = clGreen;

type
  {DP:CLASS
  }
  TunaCustomGridMonitor = class(tGraphicControl)
  private
    f_pen: array[byte] of hPen;
    f_historyData: array[byte] of unaList;
    //
    f_graphCount: int;	// must not exceed 256
    //
    f_updateInterval: int;
    //
    f_active: bool;
    f_colorBack: tColor;
    f_colorGrid: tColor;
    f_gridVNum: integer;
    f_gridHNum: integer;
    //
    f_timer: unaThreadTimer;
    f_onND: tNotifyEvent;
    f_historyLenght: int;
    //
    procedure setColorBack(value: tColor);
    procedure setColorGrid(value: tColor);
    //
    procedure setActive(value: bool);
    procedure setGridHNum(value: integer);
    procedure setGridVNum(value: integer);
    procedure setUpdateInterval(value: int);
    procedure setGraphCount(value: int);
    procedure setHistoryLenght(value: int);
    //
    procedure onTimer(sender: tObject);
  protected
    procedure Paint(); override;
    //
    procedure paintOnDC(dc: hDC); virtual;
    // --  --
    property gridHorizNum: integer read f_gridHNum write setGridHNum default 10;
    property gridVertNum: integer read f_gridVNum write setGridVNum default 10;
    //
    property color: tColor read f_colorBack write setColorBack default clBlack;
    //
    property colorGrid: tColor read f_colorGrid write setColorGrid default cldef_gridColor;
    //
    property active: bool read f_active write setActive default false;
    //
    property updateInterval: int read f_updateInterval write setUpdateInterval default 500;
    //
    property graphCount: int read f_graphCount write setGraphCount default 1;
    //
    property historyLenght: int read f_historyLenght write setHistoryLenght default 2000;
    //
    property onNeedData: tNotifyEvent read f_onND write f_onND;
  public
    procedure AfterConstruction(); override;
    procedure BeforeDestruction(); override;
    //
    procedure setGraphColor(index: int; value: tColor);
    procedure setValue(index: int; value: int);
    procedure clear();
  end;


  {DP:CLASS
  }
  TunaGridMonitor = class(TunaCustomGridMonitor)
  published
    property gridHorizNum;
    property gridVertNum;
    property color;
    property colorGrid;
    property active;
    property updateInterval;
    property graphCount;
    property historyLenght;
    //
    property Anchors;
    property Align;
    property Font;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    //
    property onNeedData;
    //
    property OnClick;
{$IFDEF __BEFORE_D5__ }
{$ELSE }
    property OnContextPopup;
{$IFDEF __BEFORE_D6__ }
{$ELSE }
    property OnMouseWheel;
    property OnMouseWheelDown;
    property OnMouseWheelUp;
{$ENDIF}
{$ENDIF }
    property OnDblClick;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnResize;
  end;


implementation


uses
  unaUtils;

{ TunaCustomGridMonitor }

// --  --
procedure TunaCustomGridMonitor.afterConstruction();
begin
  inherited;
  //
  f_colorBack := clBlack;
  colorGrid := cldef_gridColor;	// also creates f_pen[0]
  canvas.brush.color := clBlack;
  //
  f_gridVNum := 10;
  f_gridHNum := 10;
  f_updateInterval := 500;
  //
  graphCount := 1;		// also creates f_pen[1]
  historyLenght := 2000;	// keep up to 2000 values in history lists by default
  //
  f_timer := unaThreadTimer.create(f_updateInterval);
  f_timer.onTimer := onTimer;
  //
  controlStyle := controlStyle + [csOpaque];
end;

// --  --
procedure TunaCustomGridMonitor.beforeDestruction();
begin
  freeAndNil(f_timer);
  //
  graphCount := 0;	// also removes all pens
  DeleteObject(f_pen[0]);	// dont forget to remove the 0th pen
  //
  inherited;
end;

// --  --
procedure TunaCustomGridMonitor.clear();
begin
  //
end;

// --  --
procedure TunaCustomGridMonitor.onTimer(sender: tObject);
var
  i: int;
begin
  invalidate();
  //
  for i := 0 to f_graphCount - 1 do begin
    //
    if (lockList_r(f_historyData[i], false, 100 {$IFDEF DEBUG }, '.onTimer()'{$ENDIF DEBUG })) then try
      //
      f_historyData[i].add(0);
      //
      while (f_historyLenght < int(f_historyData[i].count)) do
	f_historyData[i].removeFromEdge(true);	// remove older values first
      //
    finally
      unlockListWO(f_historyData[i]);
    end;
  end;
  //
  if (f_active and assigned(f_onND)) then
    f_onND(self);
end;

// --  --
procedure TunaCustomGridMonitor.paint();
begin
  with (canvas) do begin
    //
    lock();
    try
      inherited;
      //
      paintOnDC(handle);
    finally
      unlock();
    end;
  end;
end;

// --  --
procedure TunaCustomGridMonitor.paintOnDC(dc: hDC);
var
  i: int;
  step: int;
  h, w, t, g: int;
  v, mmin, mmax: int;
begin
  // clear background
  FillRect(dc, clientRect, canvas.brush.handle);
  //
  h := clientRect.bottom - clientRect.top;
  w := clientRect.right - clientRect.left;

  // draw H grid
  if (0 < f_gridHNum) then begin
    //
    SelectObject(dc, f_pen[0]);
    //
    step := h div (1 + f_gridHNum);
    if (0 < step) then begin
      //
      i := step;
      while (i < h) do begin
	//
	MoveToEx(dc, 0, i, nil);
	LineTo(dc, w, i);
	//
	inc(i, step);
      end;
    end;
  end;

  // draw V grid
  if (0 < f_gridVNum) then begin
    //
    SelectObject(dc, f_pen[0]);
    //
    step := w div (1 + f_gridVNum);
    if (0 < step) then begin
      //
      i := step;
      while (i < w) do begin
	//
	MoveToEx(dc, i, 0, nil);
	LineTo(dc, i, h);
	//
	inc(i, step);
      end;
    end;
  end;

  //
  if (active) then begin
    //
    // draw the history graphs
    if ((0 < w) and (0 < f_graphCount)) then begin
      //
      // - calc min/max for all graphs
      mmin := high(int);
      mmax := low(int);
      for g := 0 to f_graphCount - 1 do begin
	//
	t := int(f_historyData[g].count) - 1;
	while (0 <= t) do begin
	  //
	  v := int(f_historyData[g][t]);
	  if (v > mmax) then
	    mmax := v;
	  //
	  if (v < mmin) then
	    mmin := v;
	  //
	  dec(t);
	end;
      end;
      //
      inc(mmax, 2);
      dec(mmin, 2);
      //
      for g := 0 to f_graphCount - 1 do begin
	//
	SelectObject(dc, f_pen[g + 1]);
	//
	t := int(f_historyData[g].count) - 1;
	i := w;
	if (0 <= t) then begin
	  //
	  v := int(f_historyData[g][t]) - mmin;
	  MoveToEx(dc, w, h - trunc(v / (1 + mmax - mmin) * h), nil);
	  //
	  while (i > 0) do begin
	    //
	    dec(i);
	    if (0 = t) then
	      break
	    else
	      dec(t);
	    //
	    v := int(f_historyData[g][t]) - mmin;
	    LineTo(dc, i, h - trunc(v / (1 + mmax - mmin) * h));
	  end;
	end;  
	//
      end;
    end;
  end;
  //
end;

// --  --
procedure TunaCustomGridMonitor.setActive(value: bool);
begin
  if (f_active <> value) then begin
    //
    f_active := value;
    //
    if (value) then
      f_timer.start()
    else
      f_timer.stop();
  end;
end;

// --  --
procedure TunaCustomGridMonitor.setColorBack(value: tColor);
begin
  if (f_colorBack <> value) then begin
    //
    f_colorBack := value;
    canvas.brush.color := value;
    //
    refresh();
  end;
end;

// --  --
procedure TunaCustomGridMonitor.setColorGrid(value: tColor);
begin
  if (f_colorGrid <> value) then begin
    //
    f_colorGrid := value;
    //
    DeleteObject(f_pen[0]);
    f_pen[0] := CreatePen(PS_SOLID, 1, value);
    //
    refresh();
  end;
end;

// --  --
procedure TunaCustomGridMonitor.setGraphColor(index: int; value: tColor);
begin
  if ((0 <= index) and (index < f_graphCount)) then begin
    //
    DeleteObject(f_pen[index + 1]);
    f_pen[index + 1] := CreatePen(PS_SOLID, 1, value);
  end;
end;

// --  --
procedure TunaCustomGridMonitor.setGraphCount(value: int);
begin
  value := min(high(f_pen), max(0, value));
  //
  if (f_graphCount <> value) then begin
    //
    if (f_graphCount < value) then begin
      //
      while (f_graphCount < value) do begin
	//
	f_historyData[f_graphCount] := unaList.create();
	//
	inc(f_graphCount);
	//
	f_pen[f_graphCount] := CreatePen(PS_SOLID, 1, clRed);
      end;
    end
    else begin
      //
      while (f_graphCount > value) do begin
	//
	DeleteObject(f_pen[f_graphCount]);
	//
	dec(f_graphCount);
	//
	freeAndNil(f_historyData[f_graphCount]);
      end;
    end;
  end;
end;

// --  --
procedure TunaCustomGridMonitor.setGridHNum(value: integer);
begin
  if (f_gridHNum <> value) then begin
    //
    f_gridHNum := value;
  end;
end;

// --  --
procedure TunaCustomGridMonitor.setGridVNum(value: integer);
begin
  if (f_gridVNum <> value) then begin
    //
    f_gridVNum := value;
  end;
end;

// --  --
procedure TunaCustomGridMonitor.setHistoryLenght(value: int);
var
  i: int;
begin
  if (f_historyLenght <> value) then begin
    //
    f_historyLenght := value;
    //
    for i := 0 to f_graphCount - 1 do
      while (f_historyLenght < int(f_historyData[i].count)) do
	f_historyData[i].removeFromEdge(true);	// remove older values first
    //
  end;
end;

// --  --
procedure TunaCustomGridMonitor.setUpdateInterval(value: int);
begin
  if (f_updateInterval <> value) then begin
    //
    f_updateInterval := value;
    f_timer.interval := value;
  end;
end;

// --  --
procedure TunaCustomGridMonitor.setValue(index: int; value: int);
begin
  if (active and (0 <= index) and (index < f_graphCount)) then begin
    //
    if (lockNonEmptyList_r(f_historyData[index], false, 100  {$IFDEF DEBUG }, '.setValue()'{$ENDIF DEBUG })) then try
      //
      with (f_historyData[index]) do
	setItem(count - 1, int(get(count - 1)) + value)
      //
    finally
      unlockListWO(f_historyData[index]);
    end
    else
      f_historyData[index].add(value)
  end;
end;


end.

