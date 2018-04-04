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

	  unaMsMixerControls.pas
	  VCL controls for MS Mixer interface

	----------------------------------------------
	  Copyright (c) 2000-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 2000

	  modified by:
                Lake, Jan 2010

	----------------------------------------------
*)

{$I unaDef.inc }

{*
	VCL controls for MS Mixer interface
}

unit
  unaMsMixerControls;

interface

uses
  Windows, unaTypes, unaMsMixer, MMSystem,
  Classes, Controls, Contnrs, ComCtrls, Graphics, ExtCtrls;

type
  unaMixerLineControl  = class;
  unaMixerWinControl   = class;

  //
  // -- unaMixerControl --
  //
  unaMixerControl = class(tComponent)
  private
    fMaster : unaMixerLineControl;
    fControl: unaMsMixerControl;
    fPBList : tList;
    fTBList : tList;
    fMBList : tList;
    fCBList : tList;
    fClickMBTag: int;
    //
    procedure clearLists();
    procedure myOnTrackChange(sender: tObject);
    procedure myOnMuxButtonClick(sender: tObject);
    procedure myOnMixPMClick(sender: tObject);
    procedure myOnMuxPMClick(sender: tObject);
    procedure myOnCBClick(sender: tObject);
  protected
    procedure onChange(); virtual;
  public
    constructor createMixerControl(aMaster: unaMixerLineControl; aControl: unaMsMixerControl);
    destructor Destroy(); override;
    //
    procedure RecreateControl();
    //
    property control: unaMsMixerControl read fControl;
  end;

  //
  // -- unaMixerLineControl --
  //
  unaMixerLineControl = class(tWinControl)
  private
    fLine    : unaMsMixerLine;
    fLeftSide: int;
    fTopSide : int;
    fThread  : tThread;
    //
    function getMixer(): unaMixerWinControl;
    procedure addLeft(aDelta: int);
    procedure recreateControls();
  protected
    procedure onChange(fromThread: bool = false); virtual;
  public
    constructor createMixerLine(aMixer: unaMixerWinControl; aLine: unaMsMixerLine);
    destructor Destroy(); override;
    //
    property mixer: unaMixerWinControl read getMixer;
  end;


  // --  --
  tMMLineChangeEvent = record
    //
    Msg     : unsigned;
    rMixer  : hMixer;
    rLineID : unsigned;
    Result  : int;
  end;

  // --  --
  tMMControlChangeEvent = record
    //
    Msg       : unsigned;
    rMixer    : hMixer;
    rControlID: unsigned;
    Result    : int;
  end;

  // --  --
  tMixerLineDest = (ldPlayback, ldRecording, ldCustom, ldAll);

  //
  // -- unaMixerWinControl --
  //
  unaMixerWinControl = class(tWinControl)
  private
    fMixer     : unaMsMixerSystem;
    fActive    : boolean;
    fLinesDest : tMixerLineDest;
    fLineColor : tColor;
    fPMBias    : int;
    fPMScale   : int;
    fPMShift   : int;
    fLineWidth : int;
    fMixerIndex: int;
    fLineDest  : unsigned;
    fShowDL    : bool;
    //
    procedure setActive(value: boolean);
  protected
    procedure doOpen(); virtual;
    procedure doClose(); virtual;
    procedure doLineChange(aMixerID, aLineID: unsigned); virtual;
    procedure doControlChange(aMixerID, aControlID: unsigned); virtual;
    procedure MMLineChange(var msg: tMMLineChangeEvent); message MM_MIXM_LINE_CHANGE;
    procedure MMControlChange(var msg: tMMControlChangeEvent); message MM_MIXM_CONTROL_CHANGE;
  public
    constructor Create(owner: tComponent); override;
    destructor Destroy(); override;
    procedure open();
    procedure close();
    //
    property mixer: unaMsMixerSystem read fMixer write fMixer;
    property mixerIndex: int read fMixerIndex write fMixerIndex;
    //
  published
    property active: boolean read fActive write setActive default false;
    property linesDestMode : tMixerLineDest read fLinesDest write fLinesDest default ldPlayback;
    // LineDest is used only when LinesDestMode = ldCustom
    property lineDest      : unsigned read fLineDest write fLineDest;
    property showDisconnectedLines: bool read fShowDL write fShowDL;
    property lineColor     : tColor read fLineColor write fLineColor default clBtnFace;
    property peakMeterBias : int read fPMBias write fPMBias default 0;
    property peakMeterScale: int read fPMScale write fPMScale default 1;
    property peakMeterFalloffSpeed: int read fPMShift write fPMShift default 3;
    property lineWidth     : int read fLineWidth write fLineWidth default 70;
  end;


implementation


uses
  StdCtrls, Menus;

type
  //
  // -- unaMixerWinControl --
  //
  tMixerLineMeterThread = class(tThread)
  private
    fMaster: unaMixerLineControl;
    //
    procedure doUpdate();
  protected
    procedure Execute(); override;
  public
    constructor Create(aMaster: unaMixerLineControl);
  end;


{ tMixerControlMeterThread }

// --  --
constructor tMixerLineMeterThread.Create(aMaster: unaMixerLineControl);
begin
  fMaster := aMaster;
  freeOnTerminate := false;
  //
  inherited Create(false);
end;

// --  --
procedure tMixerLineMeterThread.doUpdate();
begin
  fMaster.onChange(true);
end;

// --  --
procedure tMixerLineMeterThread.execute();
begin
  while (not terminated) do begin
    //
    synchronize(doUpdate);
    Sleep(100);	// 10 times per second
  end;
end;


{ unaMixerControl }

// --  --
procedure unaMixerControl.clearLists();
begin
  fPBList.clear();
  fTBList.clear();
  fMBList.clear();
  fCBList.clear();
end;

// --  --
constructor unaMixerControl.createMixerControl(aMaster: unaMixerLineControl; aControl: unaMsMixerControl);
begin
  inherited Create(aMaster);
  //
  fMaster  := aMaster;
  fControl := aControl;
  fPBList  := tList.Create();
  fTBList  := tList.Create();
  fMBList  := tList.Create();
  fCBList  := tList.Create();
end;

// --  --
destructor unaMixerControl.Destroy();
begin
  fPBList.free();
  fTBList.free();
  fMBList.free();
  fCBList.free();
  //
  inherited;
end;

// --  --
procedure unaMixerControl.myOnCBClick(sender: tObject);
begin
  with (sender as tCheckBox) do
    fControl.setValue(checked, tag, 0);
end;

// --  --
procedure unaMixerControl.myOnMixPMClick(sender: tObject);
begin
  with (sender as tMenuItem) do begin
    //
    checked := not checked;
    fControl.setValue(checked, fClickMBTag, 0);
  end;
end;

// --  --
procedure unaMixerControl.myOnMuxButtonClick(sender: tObject);
begin
  with (Sender as tButton) do begin
    //
    if (assigned(popupMenu)) then begin
      //
      popupMenu.popup(clientOrigin.x, clientOrigin.y + height);
      fClickMBTag := Tag;
    end;
  end;
end;

// --  --
procedure unaMixerControl.myOnMuxPMClick(sender: tObject);
var
  i: int;
begin
  with (sender as tMenuItem) do begin
    //
    fControl.beginUpdate();
    try
      for i := 0 to fControl.caps.cMultipleItems - 1 do
        fControl.setValue((i = Tag), fClickMBTag, i);
      //
    finally
      fControl.endUpdate();
    end;
  end;
end;

// --  --
procedure unaMixerControl.myOnTrackChange(sender: tObject);
begin
  with (sender as tTrackBar) do
    fControl.setValue($FFFF - position, tag);
end;

// --  --
procedure unaMixerControl.OnChange();
var
  i: int;
  c: int;
  M: int;
  D: int;
  H: string;
  pm: tPopupMenu;
begin
  if (not (csDestroying in ComponentState)) then begin
    //
    //fControl.NeedUpdateDetails := true;
    case fControl.caps.dwControlType of
      // custom
      MIXERCONTROL_CONTROLTYPE_CUSTOM: ;
      // fader
      {done}MIXERCONTROL_CONTROLTYPE_BASS,
      {done}MIXERCONTROL_CONTROLTYPE_TREBLE,
      {done}MIXERCONTROL_CONTROLTYPE_FADER,
      {done}MIXERCONTROL_CONTROLTYPE_VOLUME: begin
        //
        for i := 0 to fTBList.count - 1 do with tTrackBar(fTBList.items[i]) do
          position := ($FFFF - fControl.getValue(0, tag));
      end;

      MIXERCONTROL_CONTROLTYPE_EQUALIZER	: ;

      // list
      {done?}MIXERCONTROL_CONTROLTYPE_MIXER,
      {done?}MIXERCONTROL_CONTROLTYPE_MULTIPLESELECT,
      {done}MIXERCONTROL_CONTROLTYPE_SINGLESELECT,
      {done}MIXERCONTROL_CONTROLTYPE_MUX: begin
        //
        for i := 0 to fMBList.count - 1 do begin
          //
          H := fControl.caps.szName;
          pm := tButton(fMBList.items[i]).popupMenu;
          //
          for c := 2 to pm.items.count - 1 do begin
            //
            pm.items[c].checked := fControl.getValue(false, Tag, c - 2);
            if (pm.items[c].checked) then
              H := H + ' - ' + fControl.listItemsText.get(c - 2);
            //
          end;
          //
          tButton(fMBList.items[i]).hint := H;
        end;
      end;

      // meter
      {done}MIXERCONTROL_CONTROLTYPE_BOOLEANMETER,
      {done}MIXERCONTROL_CONTROLTYPE_UNSIGNEDMETER,
      {done}MIXERCONTROL_CONTROLTYPE_SIGNEDMETER,
      {done}MIXERCONTROL_CONTROLTYPE_PEAKMETER: with fPBList, fMaster do
        for i := 0 to Count - 1 do with tProgressBar(Items[i]) do begin
          M := (int(fControl.getValue(0, Tag)) + Mixer.fPMBias) * Mixer.fPMScale;
          if (M > Position) then D := M - Position { jump up faster }
                            else D := Abs(Position - M) shr Mixer.fPMShift;
          if (D > 0) then
            if (M > Position) then Position := Position + D
                              else Position := Position - D;
        end;

      // number
      MIXERCONTROL_CONTROLTYPE_DECIBELS	: ;
      MIXERCONTROL_CONTROLTYPE_PERCENT	: ;
      MIXERCONTROL_CONTROLTYPE_SIGNED	: ;
      MIXERCONTROL_CONTROLTYPE_UNSIGNED	: ;

      // slider
      MIXERCONTROL_CONTROLTYPE_PAN	: ;
      MIXERCONTROL_CONTROLTYPE_QSOUNDPAN	: ;
      MIXERCONTROL_CONTROLTYPE_SLIDER	: ;

      // switch
      {done}MIXERCONTROL_CONTROLTYPE_ONOFF,
      {done}MIXERCONTROL_CONTROLTYPE_STEREOENH,
      {done}MIXERCONTROL_CONTROLTYPE_BOOLEAN,
      {done}MIXERCONTROL_CONTROLTYPE_BUTTON,
      {done}MIXERCONTROL_CONTROLTYPE_LOUDNESS,
      {done}MIXERCONTROL_CONTROLTYPE_MONO,
      {done}MIXERCONTROL_CONTROLTYPE_MUTE	: with fCBList do
        for i := 0 to Count - 1 do with tCheckBox(Items[i]) do
          Checked := fControl.getValue(false, Tag);

      // time
      MIXERCONTROL_CONTROLTYPE_MICROTIME	: ;
      MIXERCONTROL_CONTROLTYPE_MILLITIME	: ;

      else ;
    end;
  end;
end;

// --  --
function notNull(const aStr1, aStr2: string): string;
begin
  if ('' = aStr1) then
    result := aStr2
  else
    result := aStr1;
end;

// --  --
procedure unaMixerControl.recreateControl();
var
  i: int;
  c: int;
  lTB : tTrackBar;
  lPB : tProgressBar;
  lC  : int;
  lBtn: tButton;
  lPM : tPopupMenu;
  lMI : tMenuItem;
  lCB : tCheckBox;
  lS  : string;
begin
  clearLists();
  //
  if ((fControl.caps.fdwControl and MIXERCONTROL_CONTROLF_MULTIPLE) <> 0) then
    lC := 0
  else
    lC := fControl.details.cChannels - 1;
  //
  case fControl.caps.dwControlType of
    // custom
    {done}MIXERCONTROL_CONTROLTYPE_CUSTOM: ;//fControl.OwnerHandle := fMaster.Handle;
    // fader
    {done}MIXERCONTROL_CONTROLTYPE_BASS,
    {done}MIXERCONTROL_CONTROLTYPE_TREBLE,
    {done}MIXERCONTROL_CONTROLTYPE_FADER,
    {done}MIXERCONTROL_CONTROLTYPE_VOLUME: begin
      for i := 0 to lC do begin
	lTB := TTrackBar.Create(fMaster);
	with lTB do begin
	  Orientation := trVertical;
	  TickStyle   := tsNone;
	  TickMarks   := tmBoth;
	  {$IFDEF VER110 }
	  {$ELSE}
	  ThumbLength := 12;
	  {$ENDIF VER110 }
	  Top         := 16;
	  Left        := fMaster.fLeftSide;
	  Width       := 16;
	  Height      := 110;
	  LineSize    := 1024;
	  PageSize    := 4096;
	  Min         := fControl.caps.Bounds.dwMinimum;
	  Max         := fControl.caps.Bounds.dwMaximum;
	  OnChange    := MyOnTrackChange;
	  Tag         := i;
	  ShowHint    := true;
	  Hint        := fControl.caps.szName;
	  fMaster.AddLeft(Width + 1);
	end;
	fMaster.InsertControl(lTB);
	fTBList.Add(lTB);
      end;
    end;
    MIXERCONTROL_CONTROLTYPE_EQUALIZER	: ;

    // list
    {done}MIXERCONTROL_CONTROLTYPE_MIXER,
    {done}MIXERCONTROL_CONTROLTYPE_MULTIPLESELECT,
    {done}MIXERCONTROL_CONTROLTYPE_MUX,
    {done}MIXERCONTROL_CONTROLTYPE_SINGLESELECT: begin
      for i := 0 to lC do begin
	lBtn := tButton.Create(fMaster);
	with lBtn do begin
	  Top      := fMaster.fTopSide;
	  Left     := 2;
	  Height   := 16;
	  Width    := fMaster.Width - 4;
	  Tag      := i;
	  Caption  := fControl.caps.szShortName;
	  //lBtn.Caption := fControl.ControlCaps.szShortName;
	  ShowHint := true;
	  Hint     := fControl.caps.szName;
	  OnClick  := MyOnMuxButtonCLick;
	end;
	fMaster.InsertControl(lBtn);
	lPM := tPopupMenu.Create(fMaster);
	if Assigned(fControl.details.paDetails) then ;
	// add long description
	lMI := tMenuItem.Create(lPM);
	lMI.Caption := fControl.caps.szName;
	lMI.Enabled := False;
	lPM.Items.Add(lMI);
	// and separator
	lMI := tMenuItem.Create(lPM);
	lMI.Caption := '-';
	lPM.Items.Add(lMI);
	// and valid items
	for c := 0 to fControl.listItemsText.count - 1 do begin
	  lMI := tMenuItem.Create(lPM);
	  with lMI do begin
	    Caption := fControl.listItemsText.get(c);
	    case fControl.caps.dwControlType of
	      MIXERCONTROL_CONTROLTYPE_MIXER,
	      MIXERCONTROL_CONTROLTYPE_MULTIPLESELECT: OnClick := MyOnMixPMClick;
	      MIXERCONTROL_CONTROLTYPE_MUX,
	      MIXERCONTROL_CONTROLTYPE_SINGLESELECT  : OnClick := MyOnMuxPMClick;
	    end;
	    Tag := c;
	  end;
	  lPM.Items.Add(lMI);
	end;
	lBtn.PopupMenu := lPM;
	fMBList.Add(lBtn);
	Inc(fMaster.fTopSide, lBtn.Height + 2);
      end;
    end;

    // meter
    {done?}MIXERCONTROL_CONTROLTYPE_BOOLEANMETER,
    {done}MIXERCONTROL_CONTROLTYPE_SIGNEDMETER,
    {done}MIXERCONTROL_CONTROLTYPE_UNSIGNEDMETER,
    {done}MIXERCONTROL_CONTROLTYPE_PEAKMETER	: begin
      for i := 0 to lC do begin
	lPB := tProgressBar.Create(fMaster);
	with lPB do begin
	  {$IFDEF VER110}
	  {$ELSE}
	  Orientation := pbVertical;
	  {$ENDIF}
	  Width  := 10;
	  Height := 100;
	  Left   := fMaster.fLeftSide;
	  Top    := 21;
	  Tag    := i;
	  ShowHint    := true;
	  Hint        := fControl.caps.szName;
	  //Smooth := true;
	  case fControl.caps.dwControlType of
	    MIXERCONTROL_CONTROLTYPE_PEAKMETER,
	    MIXERCONTROL_CONTROLTYPE_SIGNEDMETER: begin
	      Min := fControl.caps.Bounds.lMinimum;
	      Max := fControl.caps.Bounds.lMaximum;
	    end;
	    MIXERCONTROL_CONTROLTYPE_BOOLEANMETER,
	    MIXERCONTROL_CONTROLTYPE_UNSIGNEDMETER: begin
	      Min := fControl.caps.Bounds.dwMinimum;
	      Max := fControl.caps.Bounds.dwMaximum;
	    end;
	  end;
	  fMaster.AddLeft(Width + 2);
	end;
	fMaster.InsertControl(lPB);
	fPBList.Add(lPB);
      end;
      //fMaster.fThread.Resume;
    end;

    // number
    MIXERCONTROL_CONTROLTYPE_DECIBELS	: ;
    MIXERCONTROL_CONTROLTYPE_PERCENT	: ;
    MIXERCONTROL_CONTROLTYPE_SIGNED	: ;
    MIXERCONTROL_CONTROLTYPE_UNSIGNED	: ;

    // slider
    MIXERCONTROL_CONTROLTYPE_PAN	: ;
    MIXERCONTROL_CONTROLTYPE_QSOUNDPAN	: ;
    MIXERCONTROL_CONTROLTYPE_SLIDER	: ;

    // switch
    {done}MIXERCONTROL_CONTROLTYPE_STEREOENH,
    {done}MIXERCONTROL_CONTROLTYPE_ONOFF,
    {done}MIXERCONTROL_CONTROLTYPE_BOOLEAN,
    {done}MIXERCONTROL_CONTROLTYPE_BUTTON,
    {done}MIXERCONTROL_CONTROLTYPE_LOUDNESS,
    {done}MIXERCONTROL_CONTROLTYPE_MONO,
    {done}MIXERCONTROL_CONTROLTYPE_MUTE	: begin
      //for i := 0 to lC do begin
	lCB := tCheckBox.Create(fMaster);
	with lCB do begin
	  lS  := fControl.caps.szShortName;
	  case fControl.caps.dwControlType of
	    MIXERCONTROL_CONTROLTYPE_STEREOENH	: lS := notNull(lS, 'Stereo Enh.');
	    MIXERCONTROL_CONTROLTYPE_ONOFF	: lS := notNull(lS, 'On/Off');
	    MIXERCONTROL_CONTROLTYPE_BOOLEAN	: lS := notNull(lS, 'True/False');
	    MIXERCONTROL_CONTROLTYPE_BUTTON	: lS := notNull(lS, 'Button');
	    MIXERCONTROL_CONTROLTYPE_LOUDNESS	: lS := notNull(lS, 'Loudness');
	    MIXERCONTROL_CONTROLTYPE_MONO	: lS := notNull(lS, 'Mono');
	    MIXERCONTROL_CONTROLTYPE_MUTE  	: lS := 'Mute';
	    else lS := 'On/Off';
	  end;
	  lCB.Caption := lS;
	  Top     := fMaster.fTopSide;
	  Left    := 1;
	  Width   := fMaster.Width - 2;
	  OnClick := MyOnCBClick;
	  ShowHint    := true;
	  Hint        := fControl.caps.szName;
	  Inc(fMaster.fTopSide, Height);
	end;
	fMaster.InsertControl(lCB);
	fCBList.Add(lCB);
      //end;
    end;

    // time
    MIXERCONTROL_CONTROLTYPE_MICROTIME: ;
    MIXERCONTROL_CONTROLTYPE_MILLITIME: ;
    else ;
  end;
  OnChange;
end;


{ unaMixerLineControl }

// --  --
procedure unaMixerLineControl.addLeft(aDelta: int);
begin
  inc(fLeftSide, aDelta);
  //
  if (width < fLeftSide) then
    width := fLeftSide;
end;

// --  --
function isPeakMeterControl(control: unaMsMixerControl): bool;
begin
  result := (control.caps.dwControlType = MIXERCONTROL_CONTROLTYPE_BOOLEANMETER) or
	    (control.caps.dwControlType = MIXERCONTROL_CONTROLTYPE_SIGNEDMETER) or
	    (control.caps.dwControlType = MIXERCONTROL_CONTROLTYPE_UNSIGNEDMETER) or
	    (control.caps.dwControlType = MIXERCONTROL_CONTROLTYPE_PEAKMETER);
end;

// --  --
constructor unaMixerLineControl.createMixerLine(aMixer: unaMixerWinControl; aLine: unaMsMixerLine);
var
  i: int;
  lNTC: bool;
begin
  inherited Create(aMixer);
  Width  := Mixer.LineWidth;
  Height := 100;
  Color  := (Owner as unaMixerWinControl).LineColor;
  fLine  := aLine;
  lNTC   := False;
  fLeftSide := 1;
  fTopSide  := 124;
  with fLine do begin
    //EnumControls;
    for i := 0 to getControlCount() - 1 do begin
      unaMixerControl.CreateMixerControl(Self, control[i]);
      if isPeakMeterControl(control[i]) then lNTC := true;
    end;
  end;
  if lNTC then begin
    fThread := tMixerLineMeterThread.Create(Self);
    //fThread.Resume;
  end;
end;

// --  --
procedure unaMixerLineControl.recreateControls();
var
  i: int;
  lCap: tLabel;
begin
  for i := 0 to ComponentCount - 1 do
    if (Components[i] is unaMixerControl) then
      with (Components[i] as unaMixerControl) do RecreateControl;
  //
  lCap := tLabel.Create(Self);
  with lCap do begin
    //
    lCap.Caption := fLine.caps.szShortName;
    Left := 4;
    Top  := 2;
  end;
  //
  insertControl(lCap);
end;

// --  --
destructor unaMixerLineControl.Destroy();
begin
  if Assigned(fThread) then with fThread do begin
    //
    terminate();
    //if suspended then
      //resume();
    //
    waitFor();
    free();
  end;
  //
  inherited;
end;

// --  --
function unaMixerLineControl.getMixer(): unaMixerWinControl;
begin
  result := (owner as unaMixerWinControl);
end;

// --  --
procedure unaMixerLineControl.onChange(fromThread: bool);
var
  i: int;
begin
  if fromThread then begin
    //
    for i := 0 to ComponentCount - 1 do begin
      //
      if (components[i] is unaMixerControl) then begin
        //
        with (Components[i] as unaMixerControl) do begin
          //
	  if isPeakMeterControl(fControl) then
            onChange();
        end;
      end;
    end;
  end;
end;


{ unaMixerWinControl }

// --  --
procedure unaMixerWinControl.close();
begin
  active := false;
end;

// --  --
constructor unaMixerWinControl.create(owner: tComponent);
begin
  inherited Create(owner);
  //
  fLineColor := clBtnFace;
  fPMScale   := 1;
  fPMShift   := 3;
  fLineWidth := 70;
end;

// --  --
destructor unaMixerWinControl.Destroy();
begin
  close();
  //
  inherited;
end;

// --  --
procedure unaMixerWinControl.doClose();
begin
end;

// --  --
procedure unaMixerWinControl.DoControlChange(aMixerID, aControlID: unsigned);
var
  i: int;
  j: int;
begin
  for i := 0 to ControlCount - 1 do begin
    //
    if (controls[i] is unaMixerLineControl) then begin
      //
      with (controls[i] as unaMixerLineControl) do begin
        //
        for j := 0 to componentCount - 1 do begin
          //
          if (components[j] is unaMixerControl) then begin
            //
            with (components[j] as unaMixerControl) do
              if (fControl.caps.dwControlID = aControlID) then
                onChange();
          end;
        end;
      end;
    end;
  end;
end;

// --  --
procedure unaMixerWinControl.doLineChange(aMixerID, aLineID: unsigned);
var
  i: int;
begin
  for i := 0 to ControlCount - 1 do begin
    //
    if (controls[i] is unaMixerLineControl) then begin
      //
      with (controls[i] as unaMixerLineControl) do
        if (fLine.caps.dwLineID = aLineID) then
          onChange(false);
    end;
  end;
end;

// --  --
procedure unaMixerWinControl.doOpen();

  // --  --
  procedure insertBevel();
  var
    lB: tBevel;
  begin
    lB := tBevel.Create(Self);
    with lB do begin
      Width := 2;
      Align := alLeft;
      Left  := 1001;
    end;
    //
    insertControl(lB);
  end;

  // --  --
  procedure insertLine(aLine: unaMsMixerLine);
  var
    lC : unaMixerLineControl;
  begin
    if fShowDL or ((aLine.caps.fdwLine and MIXERLINE_LINEF_DISCONNECTED) = 0) then begin
      //
      lC := unaMixerLineControl.CreateMixerLine(Self, aLine);
      with lC do begin
	Align := alLeft;
	Left  := 1000;
      end;
      //
      insertControl(lC);
      lC.recreateControls();
      //
      insertBevel();
    end;
  end;

var
  i: int;
  l: int;
  k: int;
  lD : unsigned;
  lOK: bool;
begin
  destroyComponents();
  //
  i := MixerIndex;
  if (i < 0) then
    i := 0;
  //
  if (i >= int(fMixer.getMixerCount())) then
    i := fMixer.getMixerCount() - 1;
  //
  with fMixer[i] do begin
    //
    winHandle := Handle;
    open();
    //
    if (active) then begin
      //
      for l := 0 to getLineCount() - 1 do with fMixer[i][l] do begin
        //
	lOK := False;
	lD  := 0;
	case LinesDestMode of
	  ldPlayback : lD := 0;
	  ldRecording: lD := 1;
	  ldCustom   : lD := fLineDest;
	  else         lOK := true;
	end;
        //
	if (not lOK) then
          lOK := (lD = caps.dwDestination);
        //
	if (lOK) then begin
          //
	  insertLine(fMixer[i][l]);
	  for k := getConnectionCount() - 1 downto 0 do
            insertLine(fMixer[i][l].connection[k]);
          //
	end;
      end;
    end;
  end;
end;

// --  --
procedure unaMixerWinControl.MMControlChange(var msg: tMMControlChangeEvent);
begin
  doControlChange(msg.rMixer, msg.rControlID);
end;

// --  --
procedure unaMixerWinControl.MMLineChange(var msg: tMMLineChangeEvent);
begin
  doLineChange(msg.rMixer, msg.rLineID);
end;

// --  --
procedure unaMixerWinControl.open();
begin
  active := true;
end;

// --  --
procedure unaMixerWinControl.setActive(value: boolean);
begin
  if (fActive <> value) then begin
    //
    if (value) then
      doOpen()
    else
      doClose();
    //
    fActive := value;
  end;
end;


end.

