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

	  u_vcIPCustomCodec_main.pas
	  vcIPCustomCodec demo application - main form source

	----------------------------------------------
	  Copyright (c) 2009-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, Jul 2010

	  modified by:
		Lake, Jul-Dec 2010

	----------------------------------------------
*)

{$I unaDef.inc }

unit
  u_vcIPCustomCodec_main;

interface

uses
  Windows, unaTypes, unaClasses,
  Forms, Menus, ExtCtrls, Classes, Controls, ComCtrls, unaVC_wave, unaVCIDE,
  unaIPStreaming, unaVC_pipe, StdCtrls;

type
  Tc_form_main = class(TForm)
    c_sb_main: TStatusBar;
    c_timer_update: TTimer;
    c_mm_main: TMainMenu;
    mi_file_root: TMenuItem;
    mi_file_exit: TMenuItem;
    mi_help_root: TMenuItem;
    mi_help_about: TMenuItem;
    Label1: TLabel;
    c_edit_URI: TEdit;
    c_rb_tx: TRadioButton;
    c_rb_rx: TRadioButton;
    c_button_start: TButton;
    c_button_stop: TButton;
    TX: TunaIPTransmitter;
    RX: TunaIPReceiver;
    codec: TunavclWaveCodecDevice;
    decodec: TunavclWaveCodecDevice;
    waveIn: TunavclWaveInDevice;
    waveOut: TunavclWaveOutDevice;
    c_button_setup: TButton;
    c_label_info: TLabel;
    c_lb_info: TListBox;
    c_cb_timeout: TCheckBox;
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
    procedure c_button_setupClick(Sender: TObject);
    procedure c_button_startClick(Sender: TObject);
    procedure c_button_stopClick(Sender: TObject);
  private
    { Private declarations }
    f_config: unaIniFile;
    //
    procedure updateGUI(active: bool);
    procedure updateSDP();
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
  unaUtils, unaVCLUtils, unaMsACMAPI, MMSystem,
  u_common_audioConfig;


{ Tc_form_main }

// --  --
procedure Tc_form_main.beforeClose();
begin
  c_timer_update.enabled := false;
  //
  c_button_stopClick(self);
  //
  f_config.setValue('TX', c_rb_tx.checked);
  f_config.setValue('URI', c_edit_URI.text);
  f_config.setValue('timeout', c_cb_timeout.checked);
  //
  saveControlPosition(self, f_config);
end;

// --  --
procedure Tc_form_main.formCreate(sender: tObject);
begin
  f_config := unaIniFile.create();
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
  c_rb_tx.checked := f_config.get('TX', true);
  c_rb_rx.checked := not c_rb_tx.checked;
  //
  c_edit_URI.text := f_config.get('URI', c_edit_URI.text);
  c_cb_timeout.checked := f_config.get('timeout', c_cb_timeout.checked);
  //
  c_form_common_audioConfig.setupUI(true);
  c_form_common_audioConfig.doLoadConfig(waveIn, waveOut, codec, decodec, f_config);
  //
  updateSDP();
  //
  c_lb_info.items.add('wavein');
  c_lb_info.items.add('codec');
  c_lb_info.items.add('TX');
  c_lb_info.items.add('--------');
  c_lb_info.items.add('RX');
  c_lb_info.items.add('decoded');
  c_lb_info.items.add('waveout');
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
  guiMessageBox(handle, 'IP Custom Codec 1.0'#13#10'Copyright (c) 2009-2010 Lake of Soft', 'About');
end;

// --  --
procedure Tc_form_main.formCloseQuery(sender: tObject; var canClose: boolean);
begin
  if (canClose) then
    beforeClose();
end;

// --  --
procedure Tc_form_main.updateGUI(active: bool);
begin
  c_button_stop.enabled := active;
  c_button_start.enabled := not active;
  c_edit_URI.enabled := not active;
  c_rb_TX.enabled := not active;
  c_rb_RX.enabled := not active;
end;

// --  --
function tag2str(tag: int): string;
begin
  case (tag) of

    WAVE_FORMAT_PCM 		: result := 'L16';
    WAVE_FORMAT_MPEG		: result := 'mpa';
    WAVE_FORMAT_MPEGLAYER3	: result := 'mpa';
    WAVE_FORMAT_ALAW		: result := 'PCMA';
    WAVE_FORMAT_MULAW		: result := 'PCMU';

    else
	result := 'custom';

  end;
end;

// --  --
procedure Tc_form_main.updateSDP();
begin
  decodec.formatTag := codec.formatTag;
  decodec.pcmFormatExt := codec.pcmFormatExt;
  //
  TX.doEncode := false;
  RX.doEncode := false;
  //
  TX.SDP := 'v=0'#13#10 +
	    'm=audio 0 RTP/AVP 97'#13#10 +
	    'a=rtpmap:97 ' + tag2str(codec.formatTag) + '/' + int2str(codec.pcm_samplesPerSec) + '/' + int2str(codec.pcm_numChannels);
  RX.SDP := TX.SDP;
end;

// --  --
function devInfo(dev: unavclInOutPipe): string;
var
  i: int;
begin
  result := choice(dev.active, 'Active', 'N/A') + ': ';
  //
  if (dev is unavclInOutWavePipe) then
    result := result + '[' + (dev as unavclInOutWavePipe).device.srcFormatInfo + '] -> [' + (dev as unavclInOutWavePipe).device.dstFormatInfo + ']';
  //
  if (dev is unavclInOutIpPipe) then
    i := 1
  else
    i := 0;
  //
  result := result + '  ' + (int2str(dev.inBytes[i])) + '/' + (int2str(dev.outBytes[i]));
end;

// --  --
procedure Tc_form_main.updateStatus();
begin
  if (not (csDestroying in componentState)) then begin
    //
    updateGUI(TX.active or RX.active);
    //
    {$IFDEF DEBUG }
    c_sb_main.panels[0].text := 'Mem: ' + int2str(ams() shr 10, 10, 3) + ' KiB';
    {$ENDIF DEBUG }
    //
    c_label_info.caption := codec.codec.dstFormatInfo;
    //
    c_lb_info.items[0] := 'waveIn'#9 + devInfo(waveIn);
    c_lb_info.items[1] := 'codec'#9 + devInfo(codec);
    c_lb_info.items[2] := 'TX'#9#9 + devInfo(TX);
    c_lb_info.items[4] := 'RX'#9#9 + devInfo(RX);
    c_lb_info.items[5] := 'decodec'#9 + devInfo(decodec);
    c_lb_info.items[6] := 'waveOut'#9 + devInfo(waveOut);
  end;
end;

// --  --
procedure Tc_form_main.c_button_setupClick(Sender: TObject);
begin
  if (SUCCEEDED(c_form_common_audioConfig.doConfig(waveIn, waveOut, codec, decodec, f_config))) then
    updateSDP();
end;

// --  --
procedure Tc_form_main.c_button_startClick(Sender: TObject);
begin
  if (c_rb_TX.checked) then begin
    //
    TX.URI := c_edit_URI.text;
    if (c_cb_timeout.checked) then
      TX.rtcpTimeoutReports := 6
    else
      TX.rtcpTimeoutReports := 0;
    //
    waveIn.open()
  end
  else begin
    //
    RX.URI := c_edit_URI.text;
    if (c_cb_timeout.checked) then
      RX.rtcpTimeoutReports := 6
    else
      RX.rtcpTimeoutReports := 0;
    //
    RX.open();
  end;
end;

// --  --
procedure Tc_form_main.c_button_stopClick(Sender: TObject);
begin
  waveIn.close();
  RX.close();
end;

// --  --
procedure Tc_form_main.c_timer_updateTimer(sender: tObject);
begin
  updateStatus();
end;


end.

