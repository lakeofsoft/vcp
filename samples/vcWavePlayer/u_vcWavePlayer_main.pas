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

	  u_vcWavePlayer_main.pas
	  Voice Communicator components version 2.5 Pro
	  VC Wave Player Demo application - main form

	----------------------------------------------
	  Copyright (c) 2002-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 23 Oct 2002

	  modified by:
		Lake, Oct 2002
		Lake, Feb-May 2003
		Lake, Oct 2005
		Lake, Apr 2007
		Lake, Jan 2011

	----------------------------------------------
*)

{$I unaDef.inc}

unit
  u_vcWavePlayer_main;

interface

uses
  Windows, unaTypes, unaClasses,
  Forms, Messages, ComCtrls, Classes, ActnList, Dialogs, StdCtrls,
  ExtCtrls, Controls, unavcIDE, Menus, unaVC_wave, unaVC_pipe;

type
  Tc_form_main = class(TForm)
    waveRiffSource: TunavclWaveRiff;
    waveResampler: TunavclWaveResampler;
    waveOut: TunavclWaveOutDevice;
    c_openDialog_main: TOpenDialog;
    c_statusBar_main: TStatusBar;
    c_timer_update: TTimer;
    c_panel_top: TPanel;
    c_edit_fileName: TEdit;
    Label1: TLabel;
    Bevel1: TBevel;
    c_label_caption: TLabel;
    c_button_browse: TButton;
    c_actionList_main: TActionList;
    a_file_open: TAction;
    a_playback_start: TAction;
    a_playback_stop: TAction;
    c_trackBar_pos: TTrackBar;
    c_button_start: TButton;
    c_button_stop: TButton;
    c_trackBar_tempo: TTrackBar;
    c_checkBox_autoRewind: TCheckBox;
    c_paintBox_wave: TPaintBox;
    c_label_tempo: TLabel;
    c_checkBox_enableGO: TCheckBox;
    c_go_update: TTimer;
    c_trackBar_volume: TTrackBar;
    c_label_vol: TLabel;
    c_progressBar_volumeLeft: TProgressBar;
    Bevel2: TBevel;
    c_progressBar_volumeRight: TProgressBar;
    Bevel3: TBevel;
    Label2: TLabel;
    c_button_pause: TButton;
    a_playback_pause: TAction;
    a_playback_resume: TAction;
    c_button_resume: TButton;
    c_mm_main: TMainMenu;
    File1: TMenuItem;
    Exit1: TMenuItem;
    N1: TMenuItem;
    N2: TMenuItem;
    Playback1: TMenuItem;
    Pause1: TMenuItem;
    Stop1: TMenuItem;
    N3: TMenuItem;
    Start1: TMenuItem;
    Resume1: TMenuItem;
    Help1: TMenuItem;
    About1: TMenuItem;
    c_cb_speexDSP: TCheckBox;
    //
    procedure formCreate(sender: tObject);
    procedure formDestroy(sender: tObject);
    procedure formShow(sender: tObject);
    procedure formCloseQuery(sender: tObject; var canClose: boolean);
    //
    procedure a_file_openExecute(Sender: TObject);
    procedure a_playback_startExecute(Sender: TObject);
    procedure a_playback_stopExecute(Sender: TObject);
    //
    procedure c_edit_fileNameChange(Sender: TObject);
    procedure c_timer_updateTimer(Sender: TObject);
    procedure c_checkBox_autoRewindClick(Sender: TObject);
    procedure c_trackBar_posChange(Sender: TObject);
    procedure c_paintBox_wavePaint(Sender: TObject);
    procedure c_trackBar_tempoChange(Sender: TObject);
    procedure c_label_captionClick(Sender: TObject);
    procedure c_go_updateTimer(Sender: TObject);
    procedure c_trackBar_volumeChange(Sender: TObject);
    procedure c_statusBar_mainClick(Sender: TObject);
    procedure c_cb_speexDSPClick(Sender: TObject);
    //
    procedure waveOutFeedDone(sender: unavclInOutPipe; data: Pointer; len: Cardinal);
    procedure waveRiffSourceStreamIsDone(sender: TObject);
    //
    procedure a_playback_pauseExecute(Sender: TObject);
    procedure a_playback_resumeExecute(Sender: TObject);
    //
    procedure Exit1Click(Sender: TObject);
    procedure About1Click(Sender: TObject);
  private
    { Private declarations }
    f_config: unaIniFile;
    f_autoSeekPos: bool;
    f_samples: array[word] of smallInt;
    f_samplesCount: unsigned;
    f_oldTempo: unsigned;
    f_invalidateIsDone: bool;
    f_inTimer: bool;
    f_inTimerGO: bool;
    f_wavReadIsDone: bool;
    f_posDisplayMode: int;
    //
    procedure reEnableControls(isOpen: bool);
  public
    { Public declarations }
  end;

var
  c_form_main: Tc_form_main;


implementation


{$R *.dfm}

uses
  unaUtils, unaVCLUtils, unaWave,
  Graphics, CommCtrl, ShellAPI;

// --  --
procedure Tc_form_main.formCreate(sender: tObject);
begin
  f_config := unaIniFile.create();
  //
  {$IFDEF __AFTER_D7__ }
  doubleBuffered := True;
  {$ENDIF __AFTER_D7__ }
end;

// --  --
procedure Tc_form_main.formDestroy(sender: tObject);
begin
  freeAndNil(f_config);
end;

// --  --
procedure Tc_form_main.formShow(sender: tObject);
begin
  loadControlPosition(self, f_config);
  //
  reEnableControls(false);
  c_edit_fileName.text := f_config.get('gui.file.name', '');
  c_checkBox_enableGO.checked := f_config.get('gui.go.checked', true);
  c_checkBox_autoRewind.checked := f_config.get('gui.ar.checked', false);
  c_cb_speexDSP.checked := f_config.get('gui.speexdsp.checked', false);
  //
  c_edit_fileNameChange(self);
  //
  c_paintBox_wave.ControlStyle := c_paintBox_wave.ControlStyle + [csOpaque];
  //
  f_invalidateIsDone := true;
end;

// --  --
procedure Tc_form_main.formCloseQuery(sender: tObject; var canClose: boolean);
begin
  c_timer_update.enabled := false;
  c_go_update.enabled := false;
  //
  a_playback_stop.execute();
  //
  saveControlPosition(self, f_config);
  //
  f_config.setValue('gui.file.name', c_edit_fileName.text);
  f_config.setValue('gui.go.checked', c_checkBox_enableGO.checked);
  f_config.setValue('gui.ar.checked', c_checkBox_autoRewind.checked);
  f_config.setValue('gui.speexdsp.checked', c_cb_speexDSP.checked);
end;

// --  --
procedure Tc_form_main.reEnableControls(isOpen: bool);
begin
  a_playback_start.enabled := not isOpen;
  a_playback_stop.enabled := isOpen;
  //
  c_edit_fileName.enabled := not isOpen;
  c_trackBar_pos.enabled := isOpen;
  //
  if (not c_trackBar_pos.enabled) then
    waveRiffSource.waveStream.streamPosition := 0;
  //
  c_trackBar_tempo.enabled := isOpen;
  //
  c_cb_speexDSP.enabled := not isOpen;
end;

// --  --
procedure Tc_form_main.About1Click(Sender: TObject);
begin
  shellExecute(handle, 'open', 'http://lakeofsoft.com/vc/a_waveplayer.html', nil, nil, SW_SHOWNORMAL);
end;

// --  --
procedure Tc_form_main.a_file_openExecute(Sender: TObject);
begin
  if (c_openDialog_main.execute()) then begin
    //
    c_edit_fileName.text := c_openDialog_main.fileName;
    if (not waveRiffSource.active) then begin
      //
      waveRiffSource.fileName := c_edit_fileName.text;
      c_statusBar_main.panels[1].text := waveRiffSource.waveStream.srcFormatInfo;
    end;
    //
    waveResampler.resampler.priority := THREAD_PRIORITY_TIME_CRITICAL; 	// die CPU stress!
  end;
end;

// --  --
procedure Tc_form_main.c_edit_fileNameChange(Sender: TObject);
begin
  a_playback_start.enabled := not waveRiffSource.active and (fileExists(trimS(c_edit_fileName.text)));
end;

// --  --
procedure Tc_form_main.c_timer_updateTimer(Sender: TObject);
var
  bytesPerSec: double;
  bytesRateRatio: double;
  codecRatio: double;
  msec: unsigned;
  msecTotal: unsigned;
begin
  if (not (csDestroying in componentState) and not f_inTimer) then begin
    //
    f_inTimer := true;
    try
      c_statusBar_main.panels[0].text := int2str(ams() shr 10, 10, 3) + ' KB';
      //
      with (waveRiffSource) do begin
	//
	f_autoSeekPos := true;
	try
	  c_trackBar_pos.position := percent(waveStream.streamPosition, waveStream.streamSize);
	finally
	  f_autoSeekPos := false;
	end;
	//
	case (f_posDisplayMode) of

	  0: // bytes
	    c_statusBar_main.panels[2].text := int2str(waveStream.streamPosition, 10, 3, '`') + ' / ' + int2str(waveStream.streamSize, 10, 3, '`');

	  1: begin // time
	    //
	    if (nil <> waveStream.codec) then
	      codecRatio := waveStream.codec.dstChunkSize / waveStream.codec.chunkSize
	    else
	      codecRatio := 1;
	    //
	    bytesPerSec := (waveResampler.pcm_SamplesPerSec *
			    waveResampler.pcm_BitsPerSample *
			    waveResampler.pcm_NumChannels) shr 3;
	    //		    
	    bytesRateRatio := ((waveResampler.resampler.dstFormatExt.Format.nSamplesPerSec *
				waveResampler.resampler.dstFormatExt.Format.wBitsPerSample *
				waveResampler.resampler.dstFormatExt.Format.nChannels) shr 3)
				/
			       ((waveOut.pcm_SamplesPerSec *
				 waveOut.pcm_BitsPerSample *
				 waveOut.pcm_NumChannels) shr 3);
	    //
	    bytesPerSec := bytesPerSec / (codecRatio * bytesRateRatio);
	    //
	    if (0 < bytesPerSec) then begin
	      //
	      msec := trunc(waveStream.streamPosition / bytesPerSec * 1000);
	      msecTotal := trunc(waveStream.streamSize / bytesPerSec * 1000);
	    end
	    else begin
	      //
	      msec := 0;
	      msecTotal := 0;
	    end;
	    //
	    c_statusBar_main.panels[2].text := int2str(msec, 10, 3) + ' / ' + int2str(msecTotal, 10, 3);
	  end;

	  else
	    c_statusBar_main.panels[2].text := 'Unknown display mode';

	end;
      end;
      //
      if (f_wavReadIsDone and (waveResampler.resampler.chunkSize > waveResampler.availableDataLenIn)) then
	a_playback_stop.execute();
      //
    finally
      f_inTimer := false;
    end;
  end;
end;

// --  --
procedure Tc_form_main.a_playback_startExecute(Sender: TObject);
begin
  waveResampler.useSpeexDSP := c_cb_speexDSP.checked;
  waveRiffSource.fileName := c_edit_fileName.Text;
  //
  c_statusBar_main.panels[1].text := waveRiffSource.waveStream.srcFormatInfo;
  c_statusBar_main.hint := waveRiffSource.waveStream.srcFormatInfo;
  //
  f_wavReadIsDone := false;
  waveRiffSource.open();
  //
  reEnableControls(true);
end;

// --  --
procedure Tc_form_main.a_playback_stopExecute(Sender: TObject);
begin
  waveRiffSource.close();
  //
  reEnableControls(false);
  //
  c_trackBar_tempo.position := 10;
  c_trackBar_volume.position := 10;
end;

// --  --
procedure Tc_form_main.c_cb_speexDSPClick(Sender: TObject);
begin
  waveResampler.useSpeexDSP := c_cb_speexDSP.checked;
end;

// --  --
procedure Tc_form_main.c_checkBox_autoRewindClick(Sender: TObject);
begin
  waveRiffSource.loop := c_checkBox_autoRewind.checked;
end;

// --  --
procedure Tc_form_main.c_trackBar_posChange(Sender: TObject);
var
  pos: unsigned;
begin
  if (not f_autoSeekPos) then begin
    //
    pos := (waveRiffSource.waveStream.streamSize div 100) * unsigned(c_trackBar_pos.position);
    waveRiffSource.waveStream.streamPosition := pos;
  end;
end;

// --  --
procedure Tc_form_main.c_paintBox_wavePaint(Sender: TObject);
var
  stepV: double;
  offsetV: double;

  procedure renderDisplay(startOffset: unsigned);
  var
    i: unsigned;
    pos: unsigned;
  begin
    if (1 < f_samplesCount) then begin
      //
      with (c_paintBox_wave) do begin
        //
	pos := 0;
	canvas.moveTo(0, trunc(offsetV - f_samples[startOffset] * stepV));
	//
	i := startOffset + 1;
	while (i < f_samplesCount - 1) do begin
	  //
	  canvas.lineTo(pos, trunc(offsetV - f_samples[i] * stepV));
	  //
	  inc(pos);
	  inc(i, 2);
	end;
      end;
    end;
  end;

begin
  with (c_paintBox_wave) do begin
    //
    canvas.brush.color := clBtnFace;
    canvas.fillRect(getClientRect);
    //
    if (0 < f_samplesCount) then begin
      //
      stepV := height / $10000;
      offsetV := height / 1.99;
      // left
      canvas.pen.color := clBlue;
      renderDisplay(0);
      // right
      canvas.pen.color := clRed;
      renderDisplay(1);
    end;
    //
    f_invalidateIsDone := true;
  end;
end;

// --  --
procedure Tc_form_main.c_trackBar_tempoChange(Sender: TObject);
var
  pos: unsigned;
  rate: unsigned;
begin
  if (f_oldTempo <> unsigned(c_trackBar_tempo.Position)) then begin
    //
    f_oldTempo := c_trackBar_tempo.position;
    //
    // 08 Apr, 2004: Lake
    // more correct tempo change calculations
    // thanks to Tim Mahler for pointing on this problem
    //
    pos := (c_trackBar_tempo.max - c_trackBar_tempo.position) * 10;	// 0% .. 100% .. 200%
    if (1 > pos) then
      pos := 10;	// 10% instead of 0%
    //
    rate := (44100 * 100) div pos;
    waveResampler.resampler.setSampling(false, rate, 16, 2);
    waveRiffSource.waveStream.realTimer.interval := ((1000 div waveRiffSource.waveStream.chunkPerSecond) * 100) div pos;
    //
    c_label_tempo.caption := int2str(pos) + '%';
  end;
end;

// --  --
procedure Tc_form_main.c_label_captionClick(Sender: TObject);
begin
  About1Click(sender);
end;

// --  --
procedure Tc_form_main.c_go_updateTimer(Sender: TObject);
begin
  if (not (csDestroying in componentState)) then begin
    //
    if (not f_inTimerGO) then begin
      //
      f_inTimerGO := true;
      try
	if (not f_invalidateIsDone) then begin
	  //
	  if (c_checkBox_enableGO.checked) then
	    c_paintBox_wave.invalidate();
	end;    
	//
	c_progressBar_volumeLeft.position := waveGetLogVolume(waveResampler.resampler.getVolume(0));
	c_progressBar_volumeRight.position := waveGetLogVolume(waveResampler.resampler.getVolume(1));
      finally
	f_inTimerGO := false;
      end;
    end;
  end;
end;

// --  --
procedure Tc_form_main.c_trackBar_volumeChange(Sender: TObject);
var
  pos: int;
begin
  pos := c_trackBar_volume.max - c_trackBar_volume.position;
  waveResampler.resampler.setVolume100(-1, pos * 10);
  c_label_vol.caption := int2str(pos * 10) + '%';
end;

// --  --
procedure Tc_form_main.waveOutFeedDone(sender: unavclInOutPipe; data: Pointer; len: Cardinal);
begin
  if (not (csDestroying in componentState)) then begin
    //
    if (f_invalidateIsDone) then begin
      //
      move(data^, f_samples, len);
      f_samplesCount := len shr 2;	{ 16 bits; 2 channels }
      f_invalidateIsDone := false;
    end;
  end;
end;

// --  --
procedure Tc_form_main.waveRiffSourceStreamIsDone(sender: TObject);
begin
  f_wavReadIsDone := true;
end;

// --  --
procedure Tc_form_main.a_playback_pauseExecute(Sender: TObject);
begin
  waveRiffSource.waveStream.realTimer.stop();
  waveRiffSource.waveStream.pause();
end;

// --  --
procedure Tc_form_main.a_playback_resumeExecute(Sender: TObject);
begin
  waveRiffSource.waveStream.resume();
  waveRiffSource.waveStream.realTimer.start();
end;

// --  --
procedure Tc_form_main.c_statusBar_mainClick(Sender: TObject);
begin
  // toggle time/pos display
  inc(f_posDisplayMode);
  //
  if (1 < f_posDisplayMode) then
    f_posDisplayMode := 0;
end;

// --  --
procedure Tc_form_main.Exit1Click(Sender: TObject);
begin
  close();
end;


end.

