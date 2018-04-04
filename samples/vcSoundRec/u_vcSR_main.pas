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
	  Copyright (c) 2003-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 04 Jul 2003

	  modified by:
		Lake, Jul 2003
		Lake, Oct 2005

	----------------------------------------------
*)

{$I unaDef.inc}

unit
  u_vcSR_main;

interface

uses
  Windows, unaTypes, unaUtils, unaClasses, unaDspControls,
  Forms, Menus, Controls, Dialogs, Classes, ActnList, ExtCtrls, unaVCIDE,
  StdCtrls, ComCtrls, unaVC_wave, unaVC_pipe;

const
  //
  // -- max buffer size --
  //
  maxSize	= 16 * 1024 * 1024;	// 16 MB


type
  Tc_form_main = class(TForm)
    c_trackBar_pos: TTrackBar;
    c_btn_start: TButton;
    c_btn_stop: TButton;
    c_btn_play: TButton;
    c_btn_begin: TButton;
    c_btn_end: TButton;
    c_statusBar_main: TStatusBar;
    waveIn: TunavclWaveInDevice;
    wavReadWrite: TunavclWaveRiff;
    waveOut: TunavclWaveOutDevice;
    c_timer_main: TTimer;
    c_actionList_main: TActionList;
    a_wave_record: TAction;
    a_wave_play: TAction;
    a_wave_stop: TAction;
    Button1: TButton;
    a_wave_cut: TAction;
    c_progressBar_memLoad: TProgressBar;
    Button2: TButton;
    a_file_save: TAction;
    c_saveDialog_wave: TSaveDialog;
    a_file_load: TAction;
    Button3: TButton;
    c_openDialog_wave: TOpenDialog;
    a_wave_changeFormat: TAction;
    c_rb_ins: TRadioButton;
    c_rb_over: TRadioButton;
    c_fftBand_left: TunadspFFTControl;
    c_mainMenu_app: TMainMenu;
    File1: TMenuItem;
    Save1: TMenuItem;
    Load1: TMenuItem;
    Load2: TMenuItem;
    Exit1: TMenuItem;
    Control1: TMenuItem;
    Record1: TMenuItem;
    Stop1: TMenuItem;
    Playback1: TMenuItem;
    N1: TMenuItem;
    ChangeRecordingFormat1: TMenuItem;
    Help1: TMenuItem;
    About1: TMenuItem;
    a_file_new: TAction;
    New1: TMenuItem;
    c_fftBand_right: TunadspFFTControl;
    //
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    //
    procedure c_timer_mainTimer(Sender: TObject);
    procedure c_trackBar_posChange(Sender: TObject);
    procedure c_btn_beginClick(Sender: TObject);
    procedure c_btn_endClick(Sender: TObject);
    //
    procedure a_wave_recordExecute(Sender: TObject);
    procedure a_wave_playExecute(Sender: TObject);
    procedure a_wave_stopExecute(Sender: TObject);
    procedure a_wave_cutExecute(Sender: TObject);
    procedure a_wave_changeFormatExecute(Sender: TObject);
    //
    procedure a_file_saveExecute(Sender: TObject);
    procedure a_file_loadExecute(Sender: TObject);
    procedure a_file_newExecute(Sender: TObject);
    //
    procedure waveInDataAvailable(sender: unavclInOutPipe; data: Pointer; len: Cardinal);
    //
    procedure Exit1Click(Sender: TObject);
    procedure About1Click(Sender: TObject);
    //
    procedure waveOutFeedDone(sender: unavclInOutPipe; data: Pointer; len: Cardinal);
  private
    { Private declarations }
    f_memBlock: pArray;
    f_memBlockIns: unaMemoryStream;
    f_memOffs: unsigned;
    f_memUsed: unsigned;
    //
    f_wannaClose: bool;
    //
    f_tbpTimer: bool;
    f_caption: string;
    f_bytesPerSec: unsigned;
    f_doInsert: bool;
    f_insertPos: unsigned;
    f_buff: array[word] of byte;
    //
    procedure adjustFormat();
  public
    { Public declarations }
  end;

var
  c_form_main: Tc_form_main;


implementation


{$R *.dfm}

uses
  SysUtils, u_vcSR_format,
  ShellAPI;

// --  --
procedure Tc_form_main.FormCreate(Sender: TObject);
begin
  f_memBlock := malloc(maxSize);
  f_memBlockIns := unaMemoryStream.create();
  f_caption := caption;
  //
  {$IFDEF __AFTER_D7__ }
  doubleBuffered := True;
  {$ENDIF __AFTER_D7__ }
  //
  waveIn.addConsumer(c_fftBand_left.fft);
  waveIn.addConsumer(c_fftBand_right.fft);
  //
  a_file_new.execute();
end;

// --  --
procedure Tc_form_main.FormDestroy(Sender: TObject);
begin
  mrealloc(f_memBlock);
  freeAndNil(f_memBlockIns);
end;

// --  --
procedure Tc_form_main.FormShow(Sender: TObject);
begin
  adjustFormat();
  //
  c_timer_main.enabled := true;
end;

// --  --
procedure Tc_form_main.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  c_timer_main.enabled := false;
  //
  a_wave_stop.execute();
end;

// --  --
procedure Tc_form_main.c_timer_mainTimer(Sender: TObject);
begin
  c_statusBar_main.panels[0].text := 'Mem: '  + int2str(ams() shr 10, 10, 3) + ' KB';
  c_statusBar_main.panels[1].text := 'Used: ' + int2str(percent(f_memUsed, maxSize)) + '%  ' +
				     'Pos: '  + FloatToStrF(f_memOffs / f_bytesPerSec, ffFixed, 4, 2) + ' s / ' + int2str(f_memUsed div f_bytesPerSec, 10, 3) + ' s';
  //
  caption := f_caption + ' \ ' + waveIn.waveInDevice.dstFormatInfo;
  //
  c_progressBar_memLoad.position := f_memUsed shr 17;
  //
  if (wavReadWrite.active) then
    caption := 'Loading... ';
  //
  f_tbpTimer := true;
  try
    c_trackBar_pos.position := f_memOffs shr 17;
  finally
    f_tbpTimer := false;
  end;
  //
  if (f_wannaClose) then begin
    //
    f_wannaClose := false;
    a_wave_stop.execute();
  end;
end;

// --  --
procedure Tc_form_main.waveInDataAvailable(sender: unavclInOutPipe; data: Pointer; len: Cardinal);
var
  sz: unsigned;
begin
  if (f_doInsert) then
    sz := min(maxSize - f_memUsed, len)
  else
    sz := min(maxSize - f_memOffs, len);
  //
  if (0 < sz) then
    if (f_doInsert) then
      // simply put data into temp. memory stream
      f_memBlockIns.write(data, len)
    else
      // overwrite
      move(data^, f_memBlock[f_memOffs], sz);
  //
  // adjust offsets
  inc(f_memOffs, sz);
  //
  if (f_doInsert) then
    inc(f_memUsed, sz)
  else
    if (f_memUsed < f_memOffs) then
      f_memUsed := f_memOffs;
  //
  if (0 >= sz) then begin
    // stop recording/loading
    a_wave_stop.execute();
    // close file
    wavReadWrite.close();
  end;
end;

// --  --
procedure Tc_form_main.a_wave_recordExecute(Sender: TObject);
begin
  waveOut.close();
  //
  f_doInsert := c_rb_ins.checked;
  if (f_doInsert) then
    f_insertPos := f_memOffs;
  //
  waveIn.open();
  if (not waveIn.active) then
    //
    guiMessageBox(handle, waveIn.waveErrorAsString, 'Unable to open recording device', MB_OK or MB_ICONERROR)
  else begin
    //
    c_trackBar_pos.enabled := false;
    //
    a_wave_stop.enabled := true;
    a_wave_play.enabled := false;
    a_wave_record.enabled := false;
    a_wave_cut.enabled := false;
    a_wave_changeFormat.enabled := false;
    a_file_new.enabled := false;
    //
    c_rb_ins.enabled := false;
    c_rb_over.enabled := false;
  end;
end;

// --  --
procedure Tc_form_main.a_wave_playExecute(Sender: TObject);
begin
  waveIn.close();
  //
  c_fftBand_left.fft.open();
  c_fftBand_right.fft.open();
  //
  waveOut.open();
  if (not waveOut.active) then
    //
    guiMessageBox(handle, waveOut.waveErrorAsString, 'Unable to open playback device', MB_OK or MB_ICONERROR)
  else begin
    //c_trackBar_pos.enabled := false;
    a_wave_stop.enabled := true;
    a_wave_play.enabled := false;
    a_file_new.enabled := false;
    // start self-feeding cycle
    waveOut.waveOutDevice.flush();
  end;
end;

// --  --
procedure Tc_form_main.a_wave_stopExecute(Sender: TObject);
var
  sz, sb: unsigned;
begin
  waveIn.close();
  waveOut.close();
  c_fftBand_left.fft.close();
  c_fftBand_right.fft.close();
  f_wannaClose := false;
  //
  if (f_doInsert) then begin

    // 1. move block
    sz := f_memUsed - f_memOffs;
    if (0 < sz) then
      move(f_memBlock[f_insertPos], f_memBlock[f_memOffs], sz);

    // 2. insert data
    sz := min(maxSize - int(f_insertPos), f_memBlockIns.getAvailableSize());
    while (0 < sz) do begin
      //
      sb := min(sizeOf(f_buff), sz);
      sb := f_memBlockIns.read(@f_buff, sb);
      //
      if (0 < sb) then begin
	//
	move(f_buff, f_memBlock[f_insertPos], sb);
	inc(f_insertPos, sb);
	dec(sz, sb);
      end;
    end;
    //
    f_doInsert := false;
  end;
  //
  c_trackBar_pos.enabled := true;
  //
  a_wave_stop.enabled := false;
  a_wave_play.enabled := true;
  a_wave_record.enabled := true;
  a_wave_cut.enabled := true;
  a_wave_changeFormat.enabled := true;
  a_file_new.enabled := true;
  //
  c_rb_ins.enabled := true;
  c_rb_over.enabled := true;
end;

// --  --
procedure Tc_form_main.waveOutFeedDone(sender: unavclInOutPipe; data: Pointer; len: Cardinal);
var
  sz: unsigned;
begin
  sz := min(f_memUsed - f_memOffs, len);
  if (0 < sz) then begin
    //
    waveOut.write(@f_memBlock[f_memOffs], sz);
    inc(f_memOffs, sz);
    //
    c_fftBand_left.fft.write(@f_memBlock[f_memOffs], sz);
    c_fftBand_right.fft.write(@f_memBlock[f_memOffs], sz);
  end
  else begin
    // stop playback
    //a_wave_stop.execute();	// cannot close WaveOut right here due to WimMM re-entace limitations
    f_wannaClose := true;
  end;
end;

// --  --
procedure Tc_form_main.c_trackBar_posChange(Sender: TObject);
begin
  if (not f_tbpTimer) then begin
    //
    f_memOffs := (c_trackBar_pos.position shl 17) and $FFFFFFFC;	// sample align
    //
    if (f_memOffs > f_memUsed) then
      f_memOffs := f_memUsed;
  end;
end;

// --  --
procedure Tc_form_main.c_btn_beginClick(Sender: TObject);
begin
  if (a_wave_record.enabled) then
    f_memOffs := 0;
end;

// --  --
procedure Tc_form_main.c_btn_endClick(Sender: TObject);
begin
  if (a_wave_record.enabled) then
    f_memOffs := f_memUsed;
end;

// --  --
procedure Tc_form_main.a_wave_cutExecute(Sender: TObject);
begin
  f_memUsed := f_memOffs;
end;

// --  --
procedure Tc_form_main.a_file_saveExecute(Sender: TObject);
begin
  // stop wave processing (if any)
  a_wave_stop.execute();
  //
  // save the memory content
  if (0 < f_memUsed) then begin
    //
    if (c_saveDialog_wave.execute()) then begin
      //
      wavReadWrite.fileName := c_saveDialog_wave.fileName;
      wavReadWrite.pcmFormatExt := waveIn.pcmFormatExt;
      wavReadWrite.saveToFile(c_saveDialog_wave.fileName, f_memBlock, f_memUsed);
    end;
  end
  else
    showMessage('Nothing to save!');
end;

// --  --
procedure Tc_form_main.a_file_loadExecute(Sender: TObject);
begin
  // stop wave processing (if any)
  a_wave_stop.execute();
  //
  // load new file content
  if (c_openDialog_wave.execute()) then begin
    //
    wavReadWrite.fileName := c_openDialog_wave.fileName;
    wavReadWrite.isInput := true;
    //
    f_memOffs := 0;
    f_memUsed := 0;
    wavReadWrite.open();
    //
    waveIn.pcmFormatExt := wavReadWrite.waveStream.dstFormatExt;
    waveOut.pcmFormatExt := waveIn.pcmFormatExt;
    adjustFormat();
  end;
end;

// --  --
procedure Tc_form_main.adjustFormat();
begin
  f_bytesPerSec := waveIn.pcm_samplesPerSec * (waveIn.pcm_bitsPerSample shr 3) * waveIn.pcm_numChannels;
end;

// --  --
procedure Tc_form_main.a_wave_changeFormatExecute(Sender: TObject);
var
  sampling, bits, channels: int;
begin
  sampling := waveIn.pcm_samplesPerSec;
  bits := waveIn.pcm_bitsPerSample;
  channels := waveIn.pcm_numChannels;
  //
  if (c_form_format.changeFormat(sampling, bits, channels)) then begin
    //
    a_file_new.execute();
    //
    waveIn.pcm_samplesPerSec := sampling;
    waveIn.pcm_bitsPerSample := bits;
    waveIn.pcm_numChannels := channels;
    waveOut.pcmFormatExt := waveIn.pcmFormatExt;
    //
    adjustFormat();
  end;
end;

// --  --
procedure Tc_form_main.Exit1Click(Sender: TObject);
begin
  close();
end;

// --  --
procedure Tc_form_main.About1Click(Sender: TObject);
begin
  shellExecute(handle, 'open', 'http://lakeofsoft.com/vc/a_taperecorder.html', nil, nil, SW_SHOWNORMAL);
end;

// --  --
procedure Tc_form_main.a_file_newExecute(Sender: TObject);
begin
  f_memOffs := 0;
  f_memUsed := 0;
end;


end.

