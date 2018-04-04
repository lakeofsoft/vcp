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

	  u_vcNetTalk_main.pas
	  Voice Communicator components version 2.5 Pro
	  VC NetTalk demo application - main form

	----------------------------------------------
	  Copyright (c) 2002-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 01 Jun 2002

	  modified by:
		Lake, Jun-Dec 2002
		Lake, Jan-May 2003

	----------------------------------------------
*)

{$I unaDef.inc}

unit u_vcNetTalk_main;

interface

uses
  Windows, unaTypes, Classes,
  Controls, StdCtrls, ComCtrls, ExtCtrls, Forms, ActnList, Dialogs, CheckLst,
  unaClasses, unavcIDE, Menus, unaVC_socks, unaVC_wave, unaVC_pipe;

type
  Tc_form_vcNetTalkMain = class(TForm)
    c_statusBar_main: TStatusBar;
    c_timer_update: TTimer;
    waveIn_client: TunavclWaveInDevice;
    waveIn_server: TunavclWaveInDevice;
    c_actionList_main: TActionList;
    a_srvStart: TAction;
    a_srvStop: TAction;
    a_clientStart: TAction;
    a_clientStop: TAction;
    ipClient: TunavclIPOutStream;
    ipServer: TunavclIPInStream;
    waveOut_server: TunavclWaveOutDevice;
    waveOut_client: TunavclWaveOutDevice;
    codecIn_server: TunavclWaveCodecDevice;
    codecOut_client: TunavclWaveCodecDevice;
    codecOut_server: TunavclWaveCodecDevice;
    codecIn_client: TunavclWaveCodecDevice;
    mixer_server: TunavclWaveMixer;
    riff_server: TunavclWaveRiff;
    mixer_client: TunavclWaveMixer;
    riff_client: TunavclWaveRiff;
    c_panel_info: TPanel;
    c_openDialog_wave: TOpenDialog;
    resampler_client: TunavclWaveResampler;
    resampler_server: TunavclWaveResampler;
    c_pageControl_main: TPageControl;
    c_tabSheet_server: TTabSheet;
    c_tabSheet_client: TTabSheet;
    c_groupBox_server: TGroupBox;
    Label1: TLabel;
    Bevel1: TBevel;
    c_label_statusSrv: TLabel;
    c_edit_serverPort: TEdit;
    c_button_startServer: TButton;
    c_button_stopServer: TButton;
    c_checkListBox_server: TCheckListBox;
    c_edit_waveNameServer: TEdit;
    c_checkBox_mixWaveServer: TCheckBox;
    c_button_chooseWaveServer: TButton;
    c_groupBox_client: TGroupBox;
    Label2: TLabel;
    Label3: TLabel;
    Bevel2: TBevel;
    c_label_statusClient: TLabel;
    c_edit_clientSrvHost: TEdit;
    c_button_startClient: TButton;
    c_button_stopClient: TButton;
    c_edit_clientSrvPort: TEdit;
    c_checkListBox_client: TCheckListBox;
    c_checkBox_mixWaveClient: TCheckBox;
    c_edit_waveNameClient: TEdit;
    c_button_chooseWaveClient: TButton;
    Bevel3: TBevel;
    Bevel4: TBevel;
    c_checkBox_useWaveInClient: TCheckBox;
    c_checkBox_useWaveInServer: TCheckBox;
    c_button_formatChooseServer: TButton;
    c_static_formatInfoServer: TStaticText;
    c_static_formatInfoClient: TStaticText;
    c_button_formatChooseClient: TButton;
    Label4: TLabel;
    Label5: TLabel;
    c_staticText_deviceInfoClient: TStaticText;
    c_staticText_deviceInfoServer: TStaticText;
    c_checkBox_autoStartServer: TCheckBox;
    Label6: TLabel;
    c_comboBox_socketTypeServer: TComboBox;
    Label7: TLabel;
    c_comboBox_socketTypeClient: TComboBox;
    c_pb_volumeOutClient: TProgressBar;
    c_pb_volumeInClient: TProgressBar;
    c_pb_volumeOutServer: TProgressBar;
    c_pb_volumeInServer: TProgressBar;
    Bevel5: TBevel;
    Bevel6: TBevel;
    c_mm_main: TMainMenu;
    File1: TMenuItem;
    Exit1: TMenuItem;
    Help1: TMenuItem;
    About1: TMenuItem;
    //
    procedure formCreate(sender: tObject);
    procedure formClose(sender: tObject; var action: tCloseAction);
    procedure formShow(sender: tObject);
    procedure formCloseQuery(sender: tObject; var canClose: boolean);
    //
    procedure c_timer_updateTimer(Sender: TObject);
    procedure c_panel_infoClick(Sender: TObject);
    procedure c_button_chooseWaveServerClick(Sender: TObject);
    procedure c_button_chooseWaveClientClick(Sender: TObject);
    procedure c_button_formatChooseServerClick(Sender: TObject);
    procedure c_button_formatChooseClientClick(Sender: TObject);
    procedure c_comboBox_socketTypeServerChange(Sender: TObject);
    procedure c_comboBox_socketTypeClientChange(Sender: TObject);
    //
    procedure ipClientClientDisconnect(sender: TObject; connectionId: Cardinal; connected: LongBool);
    //
    procedure a_srvStartExecute(Sender: TObject);
    procedure a_srvStopExecute(Sender: TObject);
    procedure a_clientStartExecute(Sender: TObject);
    procedure a_clientStopExecute(Sender: TObject);
    procedure Exit1Click(Sender: TObject);
    procedure About1Click(Sender: TObject);
  private
    { Private declarations }
    f_hintColorCount: unsigned;
    f_hintTextCount: unsigned;
    f_ini: unaIniFile;
    //
    procedure reEnable(server: bool = true);
    procedure serverAction(doOpen: bool = true);
    procedure clientAction(doOpen: bool = true);
    procedure chooseFile(cb: tCheckBox; edit: tEdit);
    procedure updateFormat(isServer: bool = true);
    procedure updateFormatInfo(isServer: bool = true);
  public
    { Public declarations }
  end;

var
  c_form_vcNetTalkMain: Tc_form_vcNetTalkMain;


implementation


{$R *.dfm}

uses
  unaUtils, unaVCLUtils, MMSystem, unaMsAcmAPI, unaWave, unaMsAcmClasses,
  shellAPI, Graphics, u_common_audioConfig;

const
  hintStrings: array[0..18] of string = (
    '',
    'Voice Communicator components 2.5 Pro',
    '',
    'Set of native Borland Delphi classes and VCL components',
    '',
    'Direct recording and playback functions',
    'PCM resampler, volume control and software PCM mixer',
    'Supports WAV files reading and writing',
    'Easy use of Microsoft ACM codecs',
    'Compatible with external MP3 and Ogg/Vorbis encoders',
    'Efficient and powerful streaming protocol',
    'Powerfull DSP library',
    'Best solution for building voice over IP applications',
    'Compatible with Delphi 4/RAD Studio XE2 (32/64) and C++Builder 5.0 and later',
    '',
    'http://lakeofsoft.com/vc/',
    '',
    'Click here for more information.',
    ''
  );
  hintColors : array[0..7] of tColor = (clBlack, clTeal, clNavy, clNavy, clOlive, clPurple, clTeal, clNavy);

// --  --
procedure Tc_form_vcNetTalkMain.formCreate(sender: tObject);
begin
  c_panel_info.color := tColor($F0FBFF);
  //
  f_ini := unaIniFile.create();
  // server
  f_ini.section := 'server';
  c_comboBox_socketTypeServer.itemIndex := f_ini.get('socketTypeIndex', unsigned(0));
  c_edit_serverPort.text := f_ini.get('port', '17810');
  c_checkBox_mixWaveServer.Checked := f_ini.get('mixWave', false);
  c_edit_waveNameServer.Text := f_ini.get('waveName', '');
  c_checkBox_useWaveInServer.Checked := f_ini.get('useWaveIn', true);
  c_checkBox_autoStartServer.Checked := f_ini.get('autoStart', true);
  //
  // client
  f_ini.section := 'client';
  c_comboBox_socketTypeClient.itemIndex := f_ini.get('socketTypeIndex', unsigned(0));
  c_edit_clientSrvHost.text := f_ini.get('serverHost', '192.168.1.1');
  c_edit_clientSrvPort.text := f_ini.get('serverPort', '17810');
  c_checkBox_mixWaveClient.checked := f_ini.get('mixWave', false);
  c_edit_waveNameClient.text := f_ini.get('waveName', '');
  c_checkBox_useWaveInClient.checked := f_ini.get('useWaveIn', true);
  //
  c_comboBox_socketTypeServerChange(nil);
  c_comboBox_socketTypeClientChange(nil);
end;

// --  --
procedure Tc_form_vcNetTalkMain.formClose(sender: tObject; var action: tCloseAction);
begin
  clientAction(false);
  serverAction(false);
  //
  // server
  f_ini.section := 'server';
  f_ini.setValue('port', c_edit_serverPort.text);
  f_ini.setValue('socketTypeIndex', c_comboBox_socketTypeServer.itemIndex);
  f_ini.setValue('mixWave', c_checkBox_mixWaveServer.checked);
  f_ini.setValue('waveName', c_edit_waveNameServer.text);
  f_ini.setValue('useWaveIn', c_checkBox_useWaveInServer.checked);
  f_ini.setValue('autoStart', c_checkBox_autoStartServer.checked);
  // client
  f_ini.section := 'client';
  f_ini.setValue('serverHost', c_edit_clientSrvHost.text);
  f_ini.setValue('serverPort', c_edit_clientSrvPort.text);
  f_ini.setValue('socketTypeIndex', c_comboBox_socketTypeClient.itemIndex);
  f_ini.setValue('mixWave', c_checkBox_mixWaveClient.checked);
  f_ini.setValue('waveName', c_edit_waveNameClient.text);
  f_ini.setValue('useWaveIn', c_checkBox_useWaveInClient.checked);
end;

// --  --
procedure Tc_form_vcNetTalkMain.formShow(sender: tObject);
begin
  loadControlPosition(self, f_ini);
  //
  c_form_common_audioConfig.setupUI(true);
  // server
  c_form_common_audioConfig.doLoadConfig(waveIn_server, waveOut_server, codecIn_server, nil, f_ini, 'wave.format.server');
  updateFormat();
  // client
  c_form_common_audioConfig.doLoadConfig(waveIn_client, waveOut_client, codecIn_client, nil, f_ini, 'wave.format.client');
  updateFormat(false);
  //
  if (c_checkBox_autoStartServer.Checked) then
    serverAction(true);
  //
  c_timer_update.enabled := true;
end;

// --  --
procedure Tc_form_vcNetTalkMain.formCloseQuery(sender: tObject; var canClose: boolean);
begin
  c_timer_update.enabled := false;
  //
  saveControlPosition(self, f_ini);
end;

// --  --
procedure Tc_form_vcNetTalkMain.c_timer_updateTimer(Sender: TObject);

  // --  --
  function getIpStatus(ip: unavclInOutIpPipe; rec: TunavclWaveInDevice; wave: tunavclWaveRiff; play: TunavclwaveOutDevice): string;
  begin
    if (0 <> ip.getErrorCode()) then
      result := 'Error code: ' + int2str(ip.getErrorCode())
    else
      if (not ip.active) then
	result := 'Not active'
      else
	result := 'Packets: in ' + int2str(ip.inPacketsCount, 10, 3) + ', out ' + int2str(ip.outPacketsCount, 10, 3) +
		  ' / Rec: ' + int2str(rec.device.outBytes shr 10, 10, 3) + ' KB' +
		  ' / WAVe: ' + int2str(wave.device.outBytes shr 10, 10, 3) + ' KB' +
		  ' / Play: ' + int2str(play.device.inBytes shr 10, 10, 3) + ' KB';
  end;

  // --  --
  procedure deviceInfo(isServer: bool; index: unsigned; device: unavclInOutPipe);
  var
    lb: tCheckListBox;
    st: tStaticText;
  begin
    if (isServer) then begin
      lb := c_checkListBox_server;
      st := c_staticText_deviceInfoServer;
    end
    else begin
      lb := c_checkListBox_client;
      st := c_staticText_deviceInfoClient;
    end;
    //
    lb.Checked[index] := device.active;
    //
    if (int(index) = lb.ItemIndex) then
      if (device is unavclInOutWavePipe) then
	st.Caption := 'Src: ' + unavclInOutWavePipe(device).device.srcFormatInfo + #13#10 +
		      'Dst: ' + unavclInOutWavePipe(device).device.dstFormatInfo
      else
	if (device is unavclInOutIpPipe) then
	  st.Caption := 'Sent: ' + int2str(device.inBytes[1] shr 10, 10, 3) + ' KB'#13#10 +
			'Received: ' + int2str(device.outBytes[1] shr 10, 10, 3) + ' KB';
  end;

begin
  if (not (csDestroying in componentState)) then begin
    //
    c_statusBar_main.panels[0].text := 'Mem: ' + int2str(ams() shr 10, 10, 3) + ' KB';
    //
    c_label_statusSrv.caption := getIpStatus(ipServer, waveIn_server, riff_server, waveOut_server);
    c_label_statusClient.caption := getIpStatus(ipClient, waveIn_client, riff_client, waveOut_client);
    //
    c_pb_volumeInClient.position := waveGetLogVolume(mixer_client.mixer.getVolume());
    c_pb_volumeInServer.position := waveGetLogVolume(mixer_server.mixer.getVolume());
    c_pb_volumeOutClient.position := waveGetLogVolume(waveOut_client.waveOutDevice.getVolume());
    c_pb_volumeOutServer.position := waveGetLogVolume(waveOut_server.waveOutDevice.getVolume());

    //
    deviceInfo(true, 0, waveIn_server);
    deviceInfo(true, 1, riff_server);
    deviceInfo(true, 2, resampler_server);
    deviceInfo(true, 3, mixer_server);
    deviceInfo(true, 4, codecIn_server);
    deviceInfo(true, 5, ipServer);
    deviceInfo(true, 6, codecOut_server);
    deviceInfo(true, 7, waveOut_server);

    //
    deviceInfo(false, 0, waveIn_client);
    deviceInfo(false, 1, riff_client);
    deviceInfo(false, 2, resampler_client);
    deviceInfo(false, 3, mixer_client);
    deviceInfo(false, 4, codecIn_client);
    deviceInfo(false, 5, ipClient);
    deviceInfo(false, 6, codecOut_client);
    deviceInfo(false, 7, waveOut_client);

    // bottom info panel
    inc(f_hintColorCount);
    inc(f_hintTextCount, 3);
    c_panel_info.Font.Color := hintColors[(f_hintColorCount shr 3) and $07];
    c_panel_info.Caption := hintStrings[(f_hintTextCount shr 5) and $0F];

    //
    reEnable();
    reEnable(false);
  end;
end;

// --  --
procedure Tc_form_vcNetTalkMain.reEnable(server: bool);
var
  isActive: bool;
begin
  if not (csDestroying in componentState) then begin
    //
    if (server) then begin
      isActive := ipServer.active;
      a_srvStart.enabled := not isActive;
      a_srvStop.enabled := isActive;
      c_button_formatChooseServer.enabled := not isActive;
    end
    else begin
      isActive := ipClient.active;
      a_clientStart.enabled := not isActive;
      a_clientStop.enabled := isActive;
      c_button_formatChooseClient.enabled := not isActive;
    end;
  end;
end;

// --  --
procedure Tc_form_vcNetTalkMain.clientAction(doOpen: bool);
begin
  if (doOpen) then begin
    //
    ipClient.port := c_edit_clientSrvPort.text;
    ipClient.host := c_edit_clientSrvHost.text;
    //
    riff_client.fileName := c_edit_waveNameClient.Text;
  end;
  //
  waveIn_client.active := doOpen and c_checkBox_useWaveInClient.checked;
  riff_client.active := doOpen and c_checkBox_mixWaveClient.checked;
  //
  mixer_client.active := doOpen;
  ipClient.active := doOpen;
end;

// --  --
procedure Tc_form_vcNetTalkMain.serverAction(doOpen: bool);
begin
  if (doOpen) then begin
    //
    ipServer.port := c_edit_serverPort.text;
    //
    riff_server.fileName := c_edit_waveNameServer.text;
  end;
  //
  waveIn_server.active := doOpen and c_checkBox_useWaveInServer.checked;
  riff_server.active := doOpen and c_checkBox_mixWaveServer.checked;
  //
  mixer_server.active := doOpen;
  ipServer.active := doOpen;
end;

// --  --
procedure Tc_form_vcNetTalkMain.About1Click(Sender: TObject);
begin
  ShellExecute(0, 'open', 'http://lakeofsoft.com/vc/a_nettalk.html', nil, nil, SW_SHOWNORMAL);
end;

// --  --
procedure Tc_form_vcNetTalkMain.a_clientStartExecute(Sender: TObject);
begin
  clientAction();
end;

// --  --
procedure Tc_form_vcNetTalkMain.a_clientStopExecute(Sender: TObject);
begin
  clientAction(false);
end;

// --  --
procedure Tc_form_vcNetTalkMain.a_srvStartExecute(Sender: TObject);
begin
  serverAction();
end;

// --  --
procedure Tc_form_vcNetTalkMain.a_srvStopExecute(Sender: TObject);
begin
  serverAction(false);
end;

// --  --
procedure Tc_form_vcNetTalkMain.c_panel_infoClick(Sender: TObject);
begin
  About1Click(sender);
end;

// --  --
procedure Tc_form_vcNetTalkMain.c_button_chooseWaveServerClick(Sender: TObject);
begin
  chooseFile(c_checkBox_mixWaveServer, c_edit_waveNameServer);
end;

// --  --
procedure Tc_form_vcNetTalkMain.c_button_chooseWaveClientClick(Sender: TObject);
begin
  chooseFile(c_checkBox_mixWaveClient, c_edit_waveNameClient);
end;

// --  --
procedure Tc_form_vcNetTalkMain.chooseFile(cb: tCheckBox; edit: tEdit);
begin
  if (c_openDialog_wave.execute()) then begin
    cb.checked := true;
    edit.Text := c_openDialog_wave.fileName;
  end;
end;

// --  --
procedure Tc_form_vcNetTalkMain.c_button_formatChooseClientClick(Sender: TObject);
begin
  if (S_OK = c_form_common_audioConfig.doConfig(waveIn_client, waveOut_client, codecIn_client, nil, f_ini, 'wave.format.client')) then
    updateFormat(false);
end;

// --  --
procedure Tc_form_vcNetTalkMain.c_button_formatChooseServerClick(Sender: TObject);
begin
  if (S_OK = c_form_common_audioConfig.doConfig(waveIn_server, waveOut_server, codecIn_server, nil, f_ini, 'wave.format.server')) then
    updateFormat();
end;

// --  --
procedure Tc_form_vcNetTalkMain.updateFormatInfo(isServer: bool);
begin
  if (isServer) then
    c_static_formatInfoServer.caption := codecIn_server.device.dstFormatInfo
  else
    c_static_formatInfoClient.caption := codecIn_client.device.dstFormatInfo;
end;

// --  --
procedure Tc_form_vcNetTalkMain.updateFormat(isServer: bool);
begin
  if (isServer) then begin
    //
    mixer_server.pcmFormatExt := codecIn_server.pcmFormatExt;
    waveIn_server.pcmFormatExt := codecIn_server.pcmFormatExt;
    resampler_server.dstFormatExt := codecIn_server.pcmFormatExt;
  end
  else begin
    //
    mixer_client.pcmFormatExt := codecIn_client.pcmFormatExt;
    waveIn_client.pcmFormatExt := codecIn_client.pcmFormatExt;
    resampler_client.dstFormatExt := codecIn_client.pcmFormatExt;
  end;
  //
  updateFormatInfo(isServer);
end;

// --  --
procedure Tc_form_vcNetTalkMain.c_comboBox_socketTypeClientChange(Sender: TObject);
begin
  if (0 = c_comboBox_socketTypeClient.ItemIndex) then
    ipClient.proto := unapt_UDP
  else
    ipClient.proto := unapt_TCP;
end;

// --  --
procedure Tc_form_vcNetTalkMain.c_comboBox_socketTypeServerChange(Sender: TObject);
begin
  if (0 = c_comboBox_socketTypeServer.ItemIndex) then
    ipServer.proto := unapt_UDP
  else
    ipServer.proto := unapt_TCP;
end;

// --  --
procedure Tc_form_vcNetTalkMain.ipClientClientDisconnect(sender: TObject; connectionId: Cardinal; connected: LongBool);
begin
  clientAction(false);
end;

// --  --
procedure Tc_form_vcNetTalkMain.Exit1Click(Sender: TObject);
begin
  close();
end;


end.

