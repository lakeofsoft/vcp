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

	  u_vcIPDuplexSream_main.pas
	  vcIPDuplexSream demo application - main form source

	----------------------------------------------
	  Copyright (c) 2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, Sep 2010

	  modified by:
		Lake, Sep-Oct 2010

	----------------------------------------------
*)

{$I unaDef.inc }

unit
  u_vcIPDuplexSream_main;

interface

uses
  Windows, unaTypes, unaClasses,
  unaIPStreaming, unaVC_wave, unaVCIDE, unaVC_pipe,
  Forms, Menus, ExtCtrls, Classes, Controls, ComCtrls, StdCtrls;

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
    waveOut: TunavclWaveOutDevice;
    duplex: TunaIPDuplex;
    c_edit_URI: TEdit;
    Label1: TLabel;
    c_button_open: TButton;
    c_button_close: TButton;
    c_memo_SDP: TMemo;
    c_button_SDP: TButton;
    Label2: TLabel;
    c_edit_b2p: TEdit;
    c_cb_SDP: TComboBox;
    c_label_infoIN: TLabel;
    Label3: TLabel;
    c_edit_ssrc: TEdit;
    c_pb_INvolume: TProgressBar;
    c_pb_OUTvolume: TProgressBar;
    c_label_infoOUT: TLabel;
    c_label_format: TLabel;
    Label4: TLabel;
    c_edit_b2ip: TEdit;
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
    procedure c_button_openClick(Sender: TObject);
    procedure c_button_closeClick(Sender: TObject);
    procedure c_cb_SDPChange(Sender: TObject);
    procedure c_button_SDPClick(Sender: TObject);
  private
    { Private declarations }
    f_config: unaIniFile;
    //
    procedure applySDP(index: int);
    procedure enableGUI(doEnable: bool);
    //
    procedure updateStatus();
    procedure beforeClose();
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
procedure Tc_form_main.applySDP(index: int);
var
  pt: int;
  sps: int;
  nch: int;
  sdp: string;
begin
  sdp := index2sdp(index, pt, sps, nch);
  if ('' <> sdp) then begin
    //
    c_memo_SDP.text := sdp;
    c_button_SDPClick(self);
  end;
end;

// --  --
procedure Tc_form_main.beforeClose();
begin
  c_timer_update.enabled := false;
  //
  waveIn.close();
  //
  f_config.setValue('URI', c_edit_URI.text);
  f_config.setValue('b2p', c_edit_b2p.text);
  f_config.setValue('SDP.index', c_cb_SDP.itemIndex);
  //
  f_config.setValue('ssrc', c_edit_ssrc.text);
  //
  saveControlPosition(self, f_config);
end;

// --  --
procedure Tc_form_main.formCreate(sender: tObject);
begin
  f_config := unaIniFile.create();
  //
  c_memo_sdp.text := duplex.SDP;
  //
  c_cb_sdp.items.text := getFormatsList();
end;

// --  --
procedure Tc_form_main.formDestroy(sender: tObject);
begin
  freeAndNil(f_config);
end;

// --  --
procedure Tc_form_main.formShow(sender: tObject);
var
  i: int;
begin
  loadControlPosition(self, f_config);
  //
  c_edit_URI.text := f_config.get('URI', c_edit_URI.text);
  c_edit_b2p.text := f_config.get('b2p', c_edit_b2p.text);
  //
  i := f_config.get('SDP.index', int(0));
  applySDP(i);
  c_cb_SDP.itemIndex := i;
  //
  c_edit_ssrc.text := f_config.get('ssrc', c_edit_ssrc.text);
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
  guiMessageBox(handle, 'IP Duplex Stream sample 1.0'#13#10'Copyright (c) 2010-2011 Lake of Soft', 'About');
end;

// --  --
procedure Tc_form_main.formCloseQuery(sender: tObject; var canClose: boolean);
begin
  if (canClose) then
    beforeClose();
end;

// --  --
function mapInfo(mapping: punaRTPMap): string;
begin
  result := int2str(mapping.r_rtpEncoding) + '[' + mapRtpEncoding2mediaType(mapping.r_rtpEncoding) + '] "' + string(mapping.r_mediaType) + '"' +
    '  [' + int2str(mapping.r_samplingRate) + '/' + int2str(mapping.r_numChannels) + '/' + int2str(mapping.r_bitsPerSample) + ']';
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
    c_label_infoIN.caption  := 'IN: ' + int2str(duplex.inBandwidth  shr 13, 10, 3) + ' KiB/s';
    c_label_infoOUT.caption := 'OUT: '+ int2str(duplex.outBandwidth shr 13, 10, 3) + ' KiB/s';
    c_pb_INvolume.position := waveOut.getLogVolume();
    c_pb_OUTvolume.position := waveIn.getLogVolume();
    //
    c_label_format.caption := 'Transmitter: ' + waveIn.device.dstFormatInfo + ' -> ' + mapInfo(duplex.mapping) + duplex.descriptionError +
			      #13#10 +
			      'Receiver: ' + mapInfo(duplex.receiver.mapping) + ' -> ' + waveOut.device.srcFormatInfo + duplex.receiver.descriptionError;
    //
    c_button_close.enabled := duplex.active;
  end;
end;

// --  --
procedure Tc_form_main.c_button_closeClick(Sender: TObject);
begin
  waveIn.close();
  //
  enableGUI(true);
end;

// --  --
procedure Tc_form_main.c_button_openClick(Sender: TObject);
begin
  c_button_open.enabled := false;
  //
  duplex.URI := c_edit_URI.text;
  //duplex.bind2port := c_edit_b2p.text;
  //duplex.bind2ip := c_edit_b2ip.text;
  //
  duplex._SSRC := str2intUnsigned(c_edit_ssrc.text, 0);
  //
  waveIn.open();
  //
  enableGUI(not duplex.active);
end;

// --  --
procedure Tc_form_main.c_button_SDPClick(Sender: TObject);
begin
  duplex.SDP := c_memo_sdp.text;
  //
  waveIn.pcm_samplesPerSec := duplex.mapping.r_samplingRate;
  waveIn.pcm_numChannels := duplex.mapping.r_numChannels;
end;

// --  --
procedure Tc_form_main.c_cb_SDPChange(Sender: TObject);
begin
  applySDP(c_cb_SDP.itemIndex);
end;

// --  --
procedure Tc_form_main.c_timer_updateTimer(sender: tObject);
begin
  updateStatus();
end;

// --  --
procedure Tc_form_main.enableGUI(doEnable: bool);
begin
  c_button_open.enabled := doEnable;
  c_button_close.enabled := not doEnable;
  //
  c_memo_sdp.enabled := doEnable;
  c_cb_sdp.enabled := doEnable;
  c_edit_b2p.enabled := doEnable;
  c_edit_ssrc.enabled := doEnable;
  c_button_sdp.enabled := doEnable;
end;


end.

