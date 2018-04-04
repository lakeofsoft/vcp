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

	  unaDSPWinControls.pas - WinControls for DSP classes
	  Voice Communicator components version 2.5 DSP

	----------------------------------------------
	  This source code cannot be used without
	  proper permission granted to you as a private
	  person or an entity by the Lake of Soft, Ltd

	  Visit http://lakeofsoft.com/ for details.

	  Copyright (c) 2003 Lake of Soft, Ltd
		     All rights reserved
	----------------------------------------------

	  created by:
		Lake, 06 Nov 2003

	  modified by:
		Lake, Nov 2003

	----------------------------------------------
*)

{$I unaDef.inc}

{*
	GUI DSP controls
}

unit
  unaDspWinControls;

interface

uses
  Windows, unaTypes, unaDspControls,
  Graphics, Classes, Controls;

type
  {DP:CLASS

  }
  TunadspFFTWinControl = class(TCustomControl)
  private
    f_control: TunadspFFTControl;
    //
    function getActive(): boolean;
    function getBandColor(index: int32): tColor;
    function getBandGap(): unsigned;
    function getBandWidth(): unsigned;
    function getChannel(): unsigned;
    function getColor(): tColor;
    function getInterval(): unsigned;
    function getSteps(): unsigned;
    //
    procedure setActive(value: boolean);
    procedure setBandColor(index: int32; value: tColor);
    procedure setBandGap(value: unsigned);
    procedure setBandWidth(value: unsigned);
    procedure setChannel(value: unsigned);
    procedure setColor(value: tColor);
    procedure setInterval(value: unsigned);
    procedure setSteps(value: unsigned);
  protected
    procedure Loaded(); override;
  public
    procedure AfterConstruction(); override;
    procedure BeforeDestruction(); override;
  published
    property control: TunadspFFTControl read f_control;
    //
    // from TunadspFFTControl
    //
    property bandWidth: unsigned read getBandWidth write setBandWidth default 1;
    //
    property bandGap: unsigned read getBandGap write setBandGap default 0;
    //
    property steps: unsigned read getSteps write setSteps default 8;
    //
    property interval: unsigned read getInterval write setInterval default 1000;
    //
    property channel: unsigned read getChannel write setChannel default 0;
    //
    property color: tColor read getColor write setColor default clBtnFace;
    //
    property bandColorLow: tColor index 0 read getBandColor write setBandColor default cldef_BandLow;
    //
    property bandColorMed: tColor index 1 read getBandColor write setBandColor default cldef_BandMed;
    //
    property bandColorTop: tColor index 2 read getBandColor write setBandColor default cldef_BandTop;
    //
    property active: boolean read getActive write setActive;
    //
    // from TControl
    //
    property Align;
    property PopupMenu;
    //
    property OnClick;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnMouseWheel;
    property OnMouseWheelDown;
    property OnMouseWheelUp;
    property OnResize;
    //
    // from TWinControl
    //
    property BevelEdges;
    property BevelInner;
    property BevelOuter;
    property BevelKind;
    property BevelWidth;
    property BorderWidth;
    //
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
  end;


implementation


{ TunadspFFTWinControl }

// --  --
procedure TunadspFFTWinControl.afterConstruction();
begin
  f_control := TunadspFFTControl.create(self);
  control.parent := self;
  control.align := alClient;
  //
  doubleBuffered := true;
  //
  inherited;
  //
  color := clBtnFace;
end;

// --  --
procedure TunadspFFTWinControl.beforeDestruction();
begin
  inherited;
end;

// --  --
function TunadspFFTWinControl.getActive(): boolean;
begin
  result := control.active;
end;

// --  --
function TunadspFFTWinControl.getBandColor(index: int32): tColor;
begin
  case (index) of

    1:
      result := control.bandColorMed;

    2:
      result := control.bandColorTop;

    else
      result := control.bandColorLow;

  end;
end;

// --  --
function TunadspFFTWinControl.getBandGap(): unsigned;
begin
  result := control.bandGap;
end;

// --  --
function TunadspFFTWinControl.getBandWidth(): unsigned;
begin
  result := control.bandWidth;
end;

// --  --
function TunadspFFTWinControl.getChannel(): unsigned;
begin
  result := control.channel;
end;

// --  --
function TunadspFFTWinControl.getColor(): tColor;
begin
  result := inherited color;
end;

// --  --
function TunadspFFTWinControl.getInterval(): unsigned;
begin
  result := control.interval;
end;

// --  --
function TunadspFFTWinControl.getSteps(): unsigned;
begin
  result := control.steps;
end;

// --  --
procedure TunadspFFTWinControl.loaded();
begin
  inherited;
  //
  control.color := inherited color;
end;

// --  --
procedure TunadspFFTWinControl.setActive(value: boolean);
begin
  control.active := value;
end;

// --  --
procedure TunadspFFTWinControl.setBandColor(index: int32; value: tColor);
begin
  case (index) of

    1:
      control.bandColorMed := value;

    2:
      control.bandColorTop := value;

    else
      control.bandColorLow := value;

  end;
end;

// --  --
procedure TunadspFFTWinControl.setBandGap(value: unsigned);
begin
  control.bandGap := value;
end;

// --  --
procedure TunadspFFTWinControl.setBandWidth(value: unsigned);
begin
  control.bandWidth := value;
end;

// --  --
procedure TunadspFFTWinControl.setChannel(value: unsigned);
begin
  control.channel := value;
end;

// --  --
procedure TunadspFFTWinControl.setColor(value: tColor);
begin
  inherited color := value;
  //
  control.color := value;
end;

// --  --
procedure TunadspFFTWinControl.setInterval(value: unsigned);
begin
  control.interval := value;
end;

// --  --
procedure TunadspFFTWinControl.setSteps(value: unsigned);
begin
  control.steps := value;
end;


end.

