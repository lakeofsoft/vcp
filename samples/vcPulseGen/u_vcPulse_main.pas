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

	  u_pulseGen_main.pas
	  Voice Communicator components version 2.5
	  VC Pulse Generator demo application - pulse form

	----------------------------------------------
	  Copyright (c) 2002-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 03 Aug 2002

	  modified by:
		Lake, Aug-Dec 2002
		Lake, Jan-May 2003

	----------------------------------------------
*)

{$I unaDef.inc}

unit
  u_vcPulse_main;

interface

uses
  Windows, unaTypes, unaClasses, unaMsAcmClasses,
  Forms, Controls, StdCtrls, ComCtrls, Classes, ExtCtrls, Buttons;

type
  Tc_form_pulse = class(TForm)
    GroupBox1: TGroupBox;
    c_trackBar_volume: TTrackBar;
    c_label_volume: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    c_trackBar_period: TTrackBar;
    c_label_period: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    SpeedButton2: TSpeedButton;
    SpeedButton1: TSpeedButton;
    c_edit_phase: TEdit;
    UpDown1: TUpDown;
    Label1: TLabel;
    Label4: TLabel;
    c_checkBox_random: TCheckBox;
    c_rb_sine: TRadioButton;
    c_rb_tr: TRadioButton;
    c_rb_sq: TRadioButton;
    RadioButton1: TRadioButton;
    c_checkBox_distort: TCheckBox;
    c_checkBox_vibrate: TCheckBox;
    //
    procedure formCreate(sender: tObject);
    procedure formDestroy(sender: tObject);
    procedure formClose(sender: tObject; var action: tCloseAction);
    //
    procedure c_trackBar_periodChange(Sender: TObject);
    procedure c_trackBar_volumeChange(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure c_edit_phaseChange(Sender: TObject);
    procedure c_checkBox_randomClick(Sender: TObject);
    procedure pulseTypeChange(Sender: TObject);
    procedure c_checkBox_distortClick(Sender: TObject);
    procedure c_checkBox_vibrateClick(Sender: TObject);
  private
    { Private declarations }
    f_buf: array[word] of smallInt;	// samples for one chunk
    f_chunkSize: unsigned;
    f_isRandom: bool;
    f_randomCountDown: int;
    //
    f_pulseType: int;
    //
    f_period: double;
    f_step: double;
    f_stepOriginal: double;
    f_phase: double;
    f_volume: int;
    f_newVolume: int;
    //
    f_doDistort: bool;
    f_dtCount: int;
    f_ddelta: double;
    //
    f_doVibrate: bool;
    f_sdelta: double;
    f_sdCount: int;
    f_spCount: int;
  public
    { Public declarations }
    stream: unaAbstractStream;
    //
    procedure feedSine(sender: tObject);
  end;


implementation


{$R *.dfm}

uses
  unaUtils, 
  u_pulseGen_main;

// --  --
procedure Tc_form_pulse.formCreate(Sender: TObject);
begin
  c_pg_main.pulses.add(self);
  //
  stream := c_pg_main.mixer.addStream();
  //
  f_chunkSize := c_pg_main.waveOut.chunkSize;	// should not be lalger than 65535
  //
  f_period := 0.0;	// start from beginning of period
  f_pulseType := 1;
  f_volume := 0;
  f_sdCount := 0;
  f_spCount := 0;
  //
  c_trackBar_periodChange(nil);
  c_trackBar_volumeChange(nil);
  c_edit_PhaseChange(nil);
  //
  {$IFDEF __AFTER_D7__ }
  doubleBuffered := True;
  {$ENDIF __AFTER_D7__ }
  //
  label4.caption := #176;	// looks like Dlephi 4 and 5 does not support such strings in DFM files..
end;

// --  --
procedure Tc_form_pulse.formDestroy(Sender: TObject);
begin
  c_pg_main.mixer.removeStream(stream);
  c_pg_main.pulses.removeItem(self);
end;

// --  --
procedure Tc_form_pulse.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  f_newVolume := 0;
  sleep(300);
  //
  action := caFree;
end;

// --  --
procedure Tc_form_pulse.c_trackBar_periodChange(sender: tObject);
begin
  f_stepOriginal := 0.1 * c_trackBar_period.position;
  f_step := f_stepOriginal;
  f_sdelta := f_stepOriginal / 90;
  f_ddelta := f_stepOriginal / 3;
  c_label_period.caption := '&Pulse period = ' + int2str(trunc((c_pg_main.waveOut.srcFormatExt.Format.nSamplesPerSec * f_step) / 360)) + ' Hz';
end;

// --  --
procedure Tc_form_pulse.c_trackBar_volumeChange(Sender: TObject);
begin
  f_newVolume := (32000 * c_trackBar_volume.position) div c_trackBar_volume.max;
  c_label_volume.caption := '&Amplitude = ' + int2str(percent(c_trackBar_volume.position, c_trackBar_volume.max)) + '%';
end;

// --  --
procedure Tc_form_pulse.SpeedButton2Click(Sender: TObject);
begin
  c_trackBar_period.position := c_trackBar_period.position - 1;
end;

// --  --
procedure Tc_form_pulse.SpeedButton1Click(Sender: TObject);
begin
  c_trackBar_period.position := c_trackBar_period.position + 1;
end;

// --  --
procedure Tc_form_pulse.c_edit_phaseChange(Sender: TObject);
begin
  f_phase := str2intInt(c_edit_phase.text, 0);
end;

// --  --
procedure Tc_form_pulse.feedSine(sender: tObject);
var
  i: unsigned;
  period: double;
  phase: double;
  step: double;
  value: double;
  volume: int;
  //
  newPos: int;
begin
  // fill the buffer with new chunk of sine
  period := f_period;
  phase := f_phase;
  step := f_step;
  volume := f_volume;
  //
  for i := 0 to (f_chunkSize - 1) div 2 do begin
    //
    if (volume > f_newVolume) then
      dec(volume)
    else
      if (volume < f_newVolume) then
	inc(volume);
    //
    value := phase + period;
    if (360 <= value) then
      value := value - 360;
    //
    case (f_pulseType) of

      1: // sine
	f_buf[i] := trunc(volume * sin(value / 180 * Pi));

      2: // triangular
	if (value <= 90) then
	  f_buf[i] := trunc(volume * value / 90)
	else
	if (value <= 270) then
	  f_buf[i] := trunc(volume * (180 - value) / 90)
	else
	  f_buf[i] := trunc(volume * (value - 360) / 90);

      3: // square
	f_buf[i] := volume * choice(value < 180, -1, +1);

      4: // random
	f_buf[i] := trunc(volume * (random(10000) - 5000) / 5000);

    end;
    //
    period := period + step;
    //
    if (f_doDistort) then begin
      //
      inc(f_dtCount);
      if (step < f_dtCount) then begin
	//
	f_dtCount := 0;
	//
	period := period + f_ddelta;
	if (random(10) > 3) then
	  f_ddelta := -f_ddelta;
      end;
    end
    else
      f_dtCount := 0;
    //
    if (360 <= period) then begin
      //
      period := period - 360;
      inc(f_spCount);
      //
      if (f_doVibrate and (10 < f_spCount)) then begin
	//
	f_spCount := 0;
	//
	step := step + f_sdelta;
	inc(f_sdCount);
	//
	if (f_sdCount > 9) then begin
	  //
	  f_sdelta := -f_sdelta;
	  f_sdCount := 0;
	end;
      end;
      //
    end;
  end;
  //
  f_period := period;
  f_volume := volume;
  f_step := step;
  //
  // feed the stream
  if (stream.getSize() < int(f_chunkSize) * 5) then
    stream.write(@f_buf, f_chunkSize);
  //
  if (f_isRandom and (1 > f_randomCountDown)) then begin
    //
    newPos := c_trackBar_period.position;
    newPos := min(c_trackBar_period.max, max(c_trackBar_period.min, newPos + 30 - random(60)));
    c_trackBar_period.position := newPos;
    //
    f_randomCountDown := 2;
  end
  else
    dec(f_randomCountDown);
end;

// --  --
procedure Tc_form_pulse.c_checkBox_randomClick(Sender: TObject);
begin
  f_isRandom := c_checkBox_random.checked;
  f_randomCountDown := 0;
end;

// --  --
procedure Tc_form_pulse.pulseTypeChange(Sender: TObject);
begin
  f_pulseType := (sender as tRadioButton).tag;
end;

// --  --
procedure Tc_form_pulse.c_checkBox_distortClick(Sender: TObject);
begin
  f_doDistort := c_checkBox_distort.checked;
end;

// --  --
procedure Tc_form_pulse.c_checkBox_vibrateClick(Sender: TObject);
begin
  if (c_checkBox_vibrate.checked) then begin
    //
    f_step := f_stepOriginal - f_sdelta * 5;
    f_doVibrate := c_checkBox_vibrate.checked;
  end
  else begin
    //
    f_step := f_stepOriginal;
    f_doVibrate := false;
    f_sdCount := 0;
    f_spCount := 0;
  end;
end;

end.

