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

	  u_vcMCsource_main.pas
	  vcMulticast Source demo application - main form source

	----------------------------------------------
	  Copyright (c) 2005-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 01 Oct 2005

	  modified by:
		Lake, Oct 2005

	----------------------------------------------
*)

{$I unaDef.inc }

unit
  u_vcMCsource_main;

interface

uses
  Windows, unaTypes, unaClasses, unaSockets,
  Forms, Classes, Controls, ComCtrls, ExtCtrls, unaVCIDE, StdCtrls,
  unaDspControls, Menus, unaVC_wave, unaVC_pipe;

type
  Tc_form_main = class(TForm)
    c_statusBar_main: TStatusBar;
    c_label_mcsHost: TLabel;
    c_label_mcsTTL: TLabel;
    c_label_mcsPort: TLabel;
    c_label_mcsBindTo: TLabel;
    c_edit_group: TEdit;
    c_cb_mcsTTL: TComboBox;
    c_edit_port: TEdit;
    c_button_mcsStart: TButton;
    c_button_mcsStop: TButton;
    c_checkBox_mcsEnableLoopback: TCheckBox;
    c_cb_mcsBindTo: TComboBox;
    waveIn: TunavclWaveInDevice;
    codecIn: TunavclWaveCodecDevice;
    c_timer_update: TTimer;
    c_fft_main: TunadspFFTControl;
    c_label_status: TLabel;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    Exit1: TMenuItem;
    Help1: TMenuItem;
    About1: TMenuItem;
    //
    procedure formCreate(sender: tObject);
    procedure formShow(sender: tObject);
    procedure formCloseQuery(sender: tObject; var canClose: boolean);
    procedure formDestroy(sender: tObject);
    //
    procedure c_timer_updateTimer(sender: tObject);
    procedure c_button_mcsStartClick(Sender: TObject);
    procedure c_button_mcsStopClick(Sender: TObject);
    //
    procedure codecInDataAvailable(sender: unavclInOutPipe; data: pointer; len: cardinal);
    procedure Exit1Click(Sender: TObject);
    procedure About1Click(Sender: TObject);
  private
    { Private declarations }
    f_config: unaIniFile;
    f_source: unaMulticastSocket;
    f_sent: int64;
    f_socketErr: int;
  public
    { Public declarations }
  end;

var
  c_form_main: Tc_form_main;


implementation


{$R *.dfm}

uses
  unaUtils, unaVCLUtils, unaVCIDEUtils,
  ShellAPI;


{ Tc_form_main }

// --  --
procedure Tc_form_main.formCreate(sender: tObject);
begin
  f_config := unaIniFile.create();
  f_source := unaMulticastSocket.create();
  //
  {$IFDEF __AFTER_D7__ }
  doubleBuffered := True;
  {$ENDIF __AFTER_D7__ }
  //
  waveIn.addConsumer(c_fft_main.fft);
end;

// --  --
procedure Tc_form_main.formShow(sender: tObject);
var
  i: int;
  ip: string;
begin
  loadControlPosition(self, f_config);
  //
  f_config.section := 'mc';
  c_edit_group.text := f_config.get('groupIP', '224.0.1.2');
  c_edit_port.text := f_config.get('port', '18000');
  c_cb_mcsTTL.text := f_config.get('ttl', '0');
  c_checkBox_mcsEnableLoopback.checked := f_config.get('enableLoopback', false);
  //
  c_cb_mcsBindTo.clear();
  c_cb_mcsBindTo.items.add('0.0.0.0');
  //
  with (unaStringList.create()) do try
    //
    lookupHost('', ip, (_this as unaStringList));
    //
    if (0 < count) then begin
      //
      for i := 0 to count - 1 do
	c_cb_mcsBindTo.items.add(string(get(i)));
      //
    end;
    //
    c_cb_mcsBindTo.itemIndex := f_config.get('bindToIndex', int(0));
  finally
    free();
  end;
  //
  codecIn.device.assignStream(false, nil);
  //
  c_timer_update.enabled := true;
end;

// --  --
procedure Tc_form_main.formCloseQuery(sender: tObject; var canClose: boolean);
begin
  c_timer_update.enabled := false;
  //
  waveIn.close();
  f_source.close();
  //
  f_config.section := 'mc';
  f_config.setValue('groupIP', c_edit_group.text);
  f_config.setValue('port', c_edit_port.text);
  f_config.setValue('ttl', c_cb_mcsTTL.text);
  f_config.setValue('enableLoopback', c_checkBox_mcsEnableLoopback.checked);
  //
  f_config.setValue('bindToIndex', c_cb_mcsBindTo.itemIndex);
  //
  saveControlPosition(self, f_config);
end;

// --  --
procedure Tc_form_main.formDestroy(sender: tObject);
begin
  freeAndNil(f_source);
  freeAndNil(f_config);
end;

// --  --
procedure Tc_form_main.c_timer_updateTimer(Sender: TObject);
begin
  if (not (csDestroying in componentState)) then begin
    //
    {$IFDEF DEBUG }
    c_statusBar_main.panels[0].text := int2str(ams() shr 10, 10, 3) + ' KB';
    {$ENDIF DEBUG }
    //
    c_button_mcsStart.enabled := not f_source.isConnected(1);
    c_button_mcsStop.enabled := not c_button_mcsStart.enabled;
    //
    c_label_status.caption := 'Status: ' + choice(f_source.isConnected(0), 'sent ' + int2str(f_sent shr 10, 10, 3) + ' KB',
      choice(0 = f_socketErr, ' inactive.', 'socket error = ' + int2str(f_socketErr)));
  end;
end;

// --  --
procedure Tc_form_main.c_button_mcsStartClick(Sender: TObject);
begin
  // start streaming
  f_sent := 0;
  f_source.setPort(c_edit_port.text);
  f_source.bindToIP := c_cb_mcsBindTo.text;
  //
  f_socketErr := f_source.mjoin(c_edit_group.text, c_unaMC_send, str2intInt(c_cb_mcsTTL.text, -1), not c_checkBox_mcsEnableLoopback.checked);
  //
  if (0 = f_socketErr) then
    waveIn.open();
end;

// --  --
procedure Tc_form_main.c_button_mcsStopClick(Sender: TObject);
begin
  // stop streaming
  waveIn.close();
  f_source.close();
end;

// --  --
procedure Tc_form_main.About1Click(Sender: TObject);
begin
  shellExecute(handle, 'open', 'http://lakeofsoft.com/vc/a_audiomulticast.html', nil, nil, SW_SHOWNORMAL);
end;

// --  --
procedure Tc_form_main.codecInDataAvailable(sender: unavclInOutPipe; data: pointer; len: cardinal);
begin
  if (f_source.isConnected(1)) then begin
    //
    if (0 = f_source.sendData(data, len)) then
      inc(f_sent, len);
    //
  end;
end;

// --  --
procedure Tc_form_main.Exit1Click(Sender: TObject);
begin
  close();
end;


end.

