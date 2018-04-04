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

	  u_vcIPStreamPusher_main.pas
	  vcIPStreamPusher demo application - main form source

	----------------------------------------------
	  Copyright (c) 2011 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, Jan 2011

	  modified by:
		Lake, Jan 2011

	----------------------------------------------
*)

{$I unaDef.inc }

unit
  u_vcIPStreamPusher_main;

interface

uses
  Windows, unaTypes, unaClasses,
  Forms, unaIPStreaming, unaVC_pipe, unaVC_wave, unaVCIDE, Menus, ExtCtrls,
  StdCtrls, Controls, ComCtrls, Classes;

type
  Tc_form_main = class(TForm)
    c_sb_main: TStatusBar;
    c_timer_update: TTimer;
    c_mm_main: TMainMenu;
    mi_file_root: TMenuItem;
    mi_file_exit: TMenuItem;
    mi_help_root: TMenuItem;
    mi_help_about: TMenuItem;
    waveIn: TunavclWaveInDevice;
    trans: TunaIPTransmitter;
    c_lv_dest: TListView;
    c_edit_URI: TEdit;
    Label1: TLabel;
    c_button_add: TButton;
    c_button_start: TButton;
    c_button_stop: TButton;
    c_button_drop: TButton;
    //
    procedure formCreate(sender: tObject);
    procedure formDestroy(sender: tObject);
    procedure formShow(sender: tObject);
    procedure formCloseQuery(sender: tObject; var canClose: boolean);
    //
    procedure c_timer_updateTimer(Sender: TObject);
    //
    procedure mi_help_aboutClick(Sender: TObject);
    procedure mi_file_exitClick(Sender: TObject);
    //
    procedure c_button_addClick(Sender: TObject);
    procedure c_button_dropClick(Sender: TObject);
    procedure c_button_startClick(Sender: TObject);
    procedure c_button_stopClick(Sender: TObject);
    //
    procedure transFormatChangeBefore(sender, provider: unavclInOutPipe; newFormat: Pointer; len: Cardinal; out allowFormatChange: LongBool);
    procedure c_lv_destChange(Sender: TObject; Item: TListItem;
      Change: TItemChange);
  private
    { Private declarations }
    f_config: unaIniFile;
    //
    procedure updateStatus();
    procedure beforeClose();
    procedure addNewDest(const URI: string);
  public
    { Public declarations }
  end;

var
  c_form_main: Tc_form_main;


implementation


{$R *.dfm}

uses
  unaUtils, unaVCLUtils,
  unaSocks_RTP;


{ Tc_form_main }

// --  --
procedure Tc_form_main.addNewDest(const URI: string);
begin
  if ('' <> trimS(URI)) then begin
    //
    if (0 <= trans.destAdd(true, URI, true)) then begin
      //
      with c_lv_dest.items.add() do begin
	//
	caption := uri;
	subItems.add('');
	checked := true;
      end;
    end;
  end;
end;

// --  --
procedure Tc_form_main.beforeClose();
var
  i: int;
begin
  c_timer_update.enabled := false;
  //
  waveIn.close();
  //
  i := c_lv_dest.items.count;
  f_config.setValue('dest.count', i);
  while (0 < i) do begin
    //
    dec(i);
    f_config.setValue('dest.' + int2str(i) + '.uri', c_lv_dest.items[i].caption);
  end;
  //
  saveControlPosition(self, f_config);
end;

// --  --
procedure Tc_form_main.formCreate(sender: tObject);
begin
  f_config := unaIniFile.create();
  //
  c_lv_dest.items.clear();
  //
  // DVI/16000/mono
  trans.SDP := 'v=0'#13#10'm=audio 5004 RTP/AVP 6'#13#10'a=rtpmap:6 DVI4/16000/1';
  trans.URI := 'rtp://streampusher@0.0.0.0:0/';
  trans.rtcpTimeoutReports := 0;	// do not check timeouts
end;

// --  --
procedure Tc_form_main.formDestroy(sender: tObject);
begin
  freeAndNil(f_config);
end;

// --  --
procedure Tc_form_main.formShow(sender: tObject);
var
  c, i: int;
begin
  loadControlPosition(self, f_config);
  //
  c := f_config.get('dest.count', int(0));
  i := 0;
  while (i < c) do begin
    //
    addNewDest(f_config.get('dest.' + int2str(i) + '.uri', ''));
    inc(i);
  end;
  //
  c_timer_update.enabled := true;
end;

// --  --
procedure Tc_form_main.mi_file_exitClick(sender: tObject);
begin
  close();
end;

// --  --
procedure Tc_form_main.mi_help_aboutClick(sender: tObject);
begin
  guiMessageBox(handle, 'IP Stream Pusher 1.0'#13#10'Copyright (c) 2011 Lake of Soft', 'About');
end;

// --  --
procedure Tc_form_main.transFormatChangeBefore(sender, provider: unavclInOutPipe; newFormat: Pointer; len: Cardinal; out allowFormatChange: LongBool);
var
  wo: bool;
  mapping: punaRTPMap;
begin
  mapping := newFormat;
  if (nil <> mapping) then begin
    //
    wo := waveIn.active;
    try
      waveIn.close();
      //
      waveIn.pcm_samplesPerSec := mapping.r_samplingRate;
      waveIn.pcm_bitsPerSample := mapping.r_bitsPerSample;
      waveIn.pcm_numChannels := mapping.r_numChannels;
    finally
      waveIn.active := wo;
    end;
  end;
end;

// --  --
procedure Tc_form_main.formCloseQuery(sender: tObject; var canClose: boolean);
begin
  if (canClose) then
    beforeClose();
end;

// --  --
procedure Tc_form_main.updateStatus();
begin
  if (not (csDestroying in componentState)) then begin
    //
    {$IFDEF DEBUG }
    c_sb_main.panels[0].text := 'Mem: ' + int2str(ams() shr 10, 10, 3) + ' KiB';
    {$ENDIF DEBUG }
    //
    c_sb_main.panels[1].text := int2str(trans.outBandwidth shr 13, 10, 3) + ' KiB/s';
    //
    c_button_start.enabled := not trans.active;
    c_button_stop.enabled := trans.active;
  end;
end;

// --  --
procedure Tc_form_main.c_button_addClick(Sender: TObject);
begin
  addNewDest(c_edit_URI.text);
end;

// --  --
procedure Tc_form_main.c_button_dropClick(Sender: TObject);
begin
  if (nil <> c_lv_dest.selected) then begin
    //
    trans.destRemove(c_lv_dest.Selected.Caption);
    c_lv_dest.Items.delete(c_lv_dest.Selected.index);
  end;
end;

// --  --
procedure Tc_form_main.c_button_startClick(Sender: TObject);
begin
  waveIn.open();
end;

// --  --
procedure Tc_form_main.c_button_stopClick(Sender: TObject);
begin
  waveIn.close();
end;

// --  --
procedure Tc_form_main.c_lv_destChange(Sender: TObject; Item: TListItem; Change: TItemChange);
begin
  if (nil <> item) then begin
    //
    if (ctState = change) then
      trans.destEnable(item.caption, '', item.checked);
  end;
end;

// --  --
procedure Tc_form_main.c_timer_updateTimer(sender: tObject);
begin
  updateStatus();
end;


end.

