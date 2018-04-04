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

	  u_vcTalkNow_main.pas
	  vcTalkNow demo application - main form source

	----------------------------------------------
	  Copyright (c) 2002-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, Jun 2002

	  modified by:
		Lake, Jun-Dec 2002
		Lake, Jan-Nov 2003
		Lake, Jan-Dec 2004
		Lake, Aug 2005
		Lake, Apr 2007
		Lake, Feb 2009

	----------------------------------------------
*)

{$I unaDef.inc}

unit
  u_vcTalkNow_main;

interface

uses
  Windows, unaTypes, unaClasses, unaSockets, MMSystem,
  Messages, Forms, Classes, ActnList, unaVcIDE, unaGridMonitorVCL,
  Controls, StdCtrls, ComCtrls, ExtCtrls, Graphics, CheckLst, Menus,
  unaVC_wave, unaVC_socks, unaVC_pipe;

type
  Tc_form_main = class(TForm)
    //
    waveIn_client: TunavclWaveInDevice;
    waveIn_server: TunavclWaveInDevice;
    codecIn_client: TunavclWaveCodecDevice;
    codecOut_client: TunavclWaveCodecDevice;
    codecIn_server: TunavclWaveCodecDevice;
    codecOut_server: TunavclWaveCodecDevice;
    ipClient: TunavclIPOutStream;
    ipServer: TunavclIPInStream;
    waveOut_client: TunavclWaveOutDevice;
    waveOut_server: TunavclWaveOutDevice;
    //
    c_actionList_main: TActionList;
    a_server_start: TAction;
    a_server_stop: TAction;
    a_client_start: TAction;
    a_client_stop: TAction;
    //
    c_statusBar_main: TStatusBar;
    c_timer_update: TTimer;
    c_splitter_main: TSplitter;
    //
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    //
    MainMenu1: TMainMenu;
    mi_file_root: TMenuItem;
    mi_help_root: TMenuItem;
    mi_help_about: TMenuItem;
    mi_file_listen: TMenuItem;
    mi_file_stop: TMenuItem;
    N1: TMenuItem;
    mi_file_connect: TMenuItem;
    mi_file_disconnect: TMenuItem;
    N2: TMenuItem;
    mi_file_exit: TMenuItem;
    mi_options_root: TMenuItem;
    mi_options_autoActivateSrv: TMenuItem;
    mi_options_LLN: TMenuItem;
    N3: TMenuItem;
    mi_options_maxClients: TMenuItem;
    mi_options_maxClients_1: TMenuItem;
    mi_options_maxClients_2: TMenuItem;
    mi_options_maxClients_10: TMenuItem;
    N4: TMenuItem;
    mi_options_maxClients_unlimited: TMenuItem;
    //
    // server
    c_panel_server: TPanel;
    c_comboBox_socketTypeServer: TComboBox;
    c_edit_serverPort: TEdit;
    c_pb_serverIn: TProgressBar;
    c_button_serverStop: TButton;
    c_button_serverStart: TButton;
    c_label_serverStat: TLabel;
    c_button_configAudioSrv: TButton;
    c_clb_server: TCheckListBox;
    c_pb_serverOut: TProgressBar;
    c_panel_serverGraph: TPanel;
    c_cb_serverBindTo: TComboBox;
    c_label_srCodecInfo: TLabel;
    //
    // client
    c_panel_client: TPanel;
    c_pb_clientIn: TProgressBar;
    c_pb_clientOut: TProgressBar;
    c_button_clientStart: TButton;
    c_button_clientStop: TButton;
    c_button_configAudioCln: TButton;
    c_edit_clientHost: TEdit;
    c_edit_clientPort: TEdit;
    c_comboBox_socketTypeClient: TComboBox;
    c_clb_client: TCheckListBox;
    c_label_clientStat: TLabel;
    c_panel_clientGraph: TPanel;
    c_label_clCodecInfo: TLabel;
    c_cln_bindToIP: TComboBox;
    c_cln_bindToPort: TEdit;
    c_cb_serverIOCP: TCheckBox;
    c_cb_clientIOCP: TCheckBox;
    c_cb_monServerEnabled: TCheckBox;
    c_cb_monClientEnabled: TCheckBox;
    c_button_kick: TButton;
    mi_switch2RAW: TMenuItem;
    //
    procedure formCreate(sender: tObject);
    procedure formDestroy(sender: tObject);
    procedure formShow(sender: tObject);
    procedure formCloseQuery(sender: tObject; var canClose: boolean);
    //
    procedure a_server_startExecute(Sender: TObject);
    procedure a_server_stopExecute(Sender: TObject);
    procedure a_client_startExecute(Sender: TObject);
    procedure a_client_stopExecute(Sender: TObject);
    //
    procedure c_timer_updateTimer(Sender: TObject);
    procedure c_comboBox_socketTypeServerChange(Sender: TObject);
    procedure c_comboBox_socketTypeClientChange(Sender: TObject);
    procedure c_button_configAudioSrvClick(sender: tObject);
    procedure c_button_configAudioClnClick(sender: tObject);
    //
    procedure ipServerPacketEvent(sender: TObject; connId: Cardinal; cmd: Cardinal; data: Pointer; len: Cardinal);
    procedure ipServerSocketEvent(sender: tObject; connId: Cardinal; event: unaSocketEvent; data: Pointer; len: Cardinal);
    //
    procedure ipClientClientDisconnect(sender: TObject; connId: Cardinal; connected: LongBool);
    procedure ipClientSocketEvent(sender: tObject; connId: Cardinal; event: unaSocketEvent; data: Pointer; len: Cardinal);
    procedure ipClientPacketEvent(sender: TObject; connId: Cardinal; cmd: Cardinal; data: Pointer; len: Cardinal);
    //
    procedure mi_help_aboutClick(Sender: TObject);
    procedure mi_options_autoActivateSrvClick(Sender: TObject);
    procedure mi_options_LLNClick(Sender: TObject);
    procedure mi_file_exitClick(Sender: TObject);
    //
    procedure numClientsClick(Sender: TObject);
    procedure ipClientDataSent(sender: tObject; connId: Cardinal; data: Pointer; len: Cardinal);
    procedure ipServerDataSent(sender: tObject; connId: Cardinal; data: Pointer; len: Cardinal);
    procedure c_cb_monServerEnabledClick(Sender: TObject);
    procedure c_cb_monClientEnabledClick(Sender: TObject);
    procedure c_cb_serverIOCPClick(Sender: TObject);
    procedure c_cb_clientIOCPClick(Sender: TObject);
    procedure c_button_kickClick(Sender: TObject);
    procedure mi_switch2RAWClick(Sender: TObject);
    procedure waveIn_clientDataAvailable(sender: unavclInOutPipe; data: Pointer; len: Cardinal);
  private
    { Private declarations }
    f_config: unaIniFile;
    f_monitorServer: TunaGridMonitor;
    f_monitorClient: TunaGridMonitor;
    f_iocpChanging: bool;
  {$IFDEF DEBUG }
    //f_clientFlood: bool;
  {$ENDIF DEBUG }
    //
    f_waveIn_clientShouldBeClosed: bool;
    //
    procedure updateStatus();
    procedure adjustReceiveBuffers(enabled: bool);
    procedure adjustNumClients(maxNum: int);
  public
    { Public declarations }
  end;

var
  c_form_main: Tc_form_main;


implementation


{$R *.dfm}

uses
  unaUtils, unaVCLUtils, unaWave, unaMsAcmClasses,
{$IFDEF VC25_IOCP }
  unaIOCP,
{$ENDIF VC25_IOCP }
  SysUtils, 
  u_common_audioConfig, u_vcTalkNow_about;


// --  --
procedure Tc_form_main.formCreate(Sender: TObject);
var
  list: unaStringList;
begin
  f_config := unaIniFile.create();
  loadControlPosition(self, f_config);
  //
  {$IFDEF __AFTER_D7__ }
  doubleBuffered := True;
  {$ENDIF __AFTER_D7__ }
  //
  f_monitorClient := TunaGridMonitor.create(self);
  f_monitorClient.parent := c_panel_clientGraph;
  f_monitorClient.top := 1;
  f_monitorClient.align := alClient;
  //
  f_monitorClient.graphCount := 2;
  f_monitorClient.setGraphColor(0, clRed);
  f_monitorClient.setGraphColor(1, clBlue);
  //
  f_monitorClient.hint := 'Red = bytes received'#13#10'Blue = bytes sent';
  f_monitorClient.showHint := true;
  //
  f_monitorServer := TunaGridMonitor.create(self);
  f_monitorServer.parent := c_panel_serverGraph;
  f_monitorServer.top := 1;
  f_monitorServer.align := alClient;
  //
  f_monitorServer.graphCount := 2;
  f_monitorServer.setGraphColor(0, clRed);
  f_monitorServer.setGraphColor(1, clBlue);
  //
  f_monitorServer.hint := 'Red = bytes received'#13#10'Blue = bytes sent';
  f_monitorServer.showHint := true;
  //
  list := unaStringList.create();
  try
    listAddresses('', list);
    c_cb_serverBindTo.items.clear();
    c_cb_serverBindTo.items.add('0.0.0.0');
    //
    while (c_cb_serverBindTo.items.count <= int(list.count)) do
      c_cb_serverBindTo.items.add(string(list.get(c_cb_serverBindTo.items.count - 1)));
    //
    c_cln_bindToIP.items.assign(c_cb_serverBindTo.items);
    //
  finally
    freeAndNil(list);
  end;
  //
  with (f_config) do begin
    //
    c_comboBox_socketTypeServer.itemIndex := get('server.socket.type', int(0));
    c_comboBox_socketTypeClient.itemIndex := get('client.socket.type', int(0));
    //
    c_edit_serverPort.text := get('server.socket.port', '17820');
    c_cb_serverBindTo.itemIndex := get('server.socket.bindToIndex', int(0));
    if (0 > c_cb_serverBindTo.itemIndex) then
      c_cb_serverBindTo.itemIndex := 0;
    //
    c_cln_bindToIP.itemIndex := get('client.socket.bindToIndex', int(0));
    if (0 > c_cln_bindToIP.itemIndex) then
      c_cln_bindToIP.itemIndex := 0;
    //
    c_edit_clientPort.text := get('client.socket.port', '17820');
    c_edit_clientHost.Text := get('client.socket.host', '192.168.1.1');
    adjustNumClients(get('server.maxClients', int(1)));
    //
    c_cln_bindToPort.text := get('client.socket.bindToPort', '0');
    //
    case (ipServer.maxClients) of

       1: mi_options_maxClients_1.checked := true;
       2: mi_options_maxClients_2.checked := true;
      10: mi_options_maxClients_10.checked := true;

      else
	  mi_options_maxClients_unlimited.checked := true;
    end;
    //
    mi_options_autoActivateSrv.checked := get('server.config.autoStart', true);
    mi_options_LLN.checked := get('network.longLatency', false);
    //
    c_comboBox_socketTypeServerChange(sender);
    c_comboBox_socketTypeClientChange(sender);
    //
    c_cb_monClientEnabled.checked := get('client.gui.monEnabled', true);
    c_cb_monServerEnabled.checked := get('server.gui.monEnabled', true);
    //
{$IFDEF VC25_IOCP }
    ipServer.useIOCPSocketsModel := get('server.socket.IOCP', true);
    ipClient.useIOCPSocketsModel := get('client.socket.IOCP', true);
{$ELSE }
    c_cb_serverIOCP.visible := false;
    c_cb_clientIOCP.visible := false;
{$ENDIF VC25_IOCP }
  end;
  //
{$IFDEF DEBUG }
  //c_cb_clientFlood.checked := f_config.get('client.flood.enabled', false);
{$ELSE }
  c_clb_server.visible := false;
  c_clb_client.visible := false;
  c_label_srCodecInfo.visible := false;
  c_label_clCodecInfo.visible := false;
  //
  c_cb_monClientEnabled.visible := false;
  c_cb_monServerEnabled.visible := false;
{$ENDIF DEBUG }
end;

// --  --
procedure Tc_form_main.formDestroy(sender: tObject);
begin
  freeAndNil(f_config);
end;

// --  --
procedure Tc_form_main.formShow(sender: tObject);
begin
  c_form_common_audioConfig.setupUI(true);
  c_form_common_audioConfig.doLoadConfig(waveIn_server, waveOut_server, codecIn_server, nil, f_config, 'waveConfig.server');
  c_form_common_audioConfig.doLoadConfig(waveIn_client, waveOut_client, codecIn_client, nil, f_config, 'waveConfig.client');
  //
  adjustReceiveBuffers(mi_options_LLN.checked);
  //
  if (mi_options_autoActivateSrv.checked) then
    a_server_start.execute();
  //
  f_monitorClient.updateInterval := c_timer_update.interval;
  f_monitorServer.updateInterval := c_timer_update.interval;
  //
  f_monitorClient.active := c_cb_monClientEnabled.checked;
  f_monitorServer.active := c_cb_monServerEnabled.checked;
  //
{$IFDEF VC25_IOCP }
  if (iocpAvailable()) then begin
    //
    c_cb_serverIOCP.checked := ipServer.useIOCPSocketsModel;
    c_cb_clientIOCP.checked := ipClient.useIOCPSocketsModel;
  end
  else begin
    //
    c_cb_serverIOCP.visible := false;
    c_cb_clientIOCP.visible := false;
  end;
{$ENDIF VC25_IOCP }
{$IFDEF DEBUG }
  //c_cb_clientFlood.visible := true;
  mi_switch2RAW.visible := true;
{$ENDIF DEBUG }
end;

// --  --
procedure Tc_form_main.formCloseQuery(sender: tObject; var canClose: boolean);
begin
  c_timer_update.enabled := false;
  //
  f_monitorClient.active := false;
  f_monitorServer.active := false;
  //
  a_server_stop.execute();
  a_client_stop.execute();
  //
  with (f_config) do begin
    //
    setValue('server.socket.type', c_comboBox_socketTypeServer.ItemIndex);
    setValue('server.socket.port', c_edit_serverPort.Text);
    setValue('server.socket.bindToIndex', c_cb_serverBindTo.itemIndex);
    setValue('server.maxClients', ipServer.maxClients);
    //
    setValue('client.socket.type', c_comboBox_socketTypeClient.ItemIndex);
    setValue('client.socket.port', c_edit_clientPort.Text);
    setValue('client.socket.host', c_edit_clientHost.Text);
    setValue('client.socket.bindToIndex', c_cln_bindToIP.itemIndex);
    setValue('client.socket.bindToPort', c_cln_bindToPort.text);
    //
    setValue('server.config.autoStart', mi_options_autoActivateSrv.checked);
    setValue('network.longLatency', mi_options_LLN.checked);
    //
    setValue('client.gui.monEnabled', c_cb_monClientEnabled.checked);
    setValue('server.gui.monEnabled', c_cb_monServerEnabled.checked);
    //
{$IFDEF VC25_IOCP }
    if (c_cb_serverIOCP.visible) then
      setValue('server.socket.IOCP', ipServer.useIOCPSocketsModel);
    if (c_cb_clientIOCP.visible) then
      setValue('client.socket.IOCP', ipClient.useIOCPSocketsModel);
{$ENDIF VC25_IOCP }
    //
{$IFDEF DEBUG }
    //setValue('client.flood.enabled', c_cb_clientFlood.checked);
{$ENDIF DEUBG}
  end;
  //
  saveControlPosition(self, f_config);
end;

// --  --
procedure Tc_form_main.updateStatus();

  // --  --
  function bytes2str(value: int64; inKB: bool = false): string;
  begin
    if (inKB) then
      result := int2str(value shr 10, 10, 3)
    else
      result := adjust(int2str(value, 10, 3, ','), 10, ' ');
  end;

{$IFDEF DEBUG }

  // --  --
  function deviceInfo(device: unavclInOutWavePipe): string;
  begin
    result := 'Src=' + device.device.srcFormatInfo + ';  Dst=' + device.device.dstFormatInfo;
  end;

  // --  --
  function codecInfo(device: TunavclWaveCodecDevice): string;
  begin
    case (device.driverMode) of

      unacdm_acm: begin
	//
	result := 'ACM:  Src=' + device.codec.srcFormatInfo + '; Dst= ' + device.codec.dstFormatInfo;
      end;

      unacdm_openH323plugin: begin
	//
	result := 'H323P: ' + device.driverLibrary + ',  formatIndex=' + int2str(device.formatTag);
      end;

    end;
  end;

{$ENDIF DEBUG }

var
  serverIsOn: bool;
  clientIsOn: bool;
begin
  if (not (csDestroying in componentState)) then begin
    //
    serverIsOn := ipServer.active;
    //
    a_server_start.enabled := not serverIsOn;
    a_server_stop.enabled := serverIsOn;
    //
    c_comboBox_socketTypeServer.enabled := not serverIsOn;
    c_edit_serverPort.enabled := not serverIsOn;
    c_cb_serverBindTo.enabled := not serverIsOn;
    c_button_configAudioSrv.enabled := not serverIsOn;
    //
    clientIsOn := ipClient.active;
    //
    a_client_start.enabled := not clientIsOn;
    a_client_stop.enabled := clientIsOn and ipClient.isConnected;
    //
    c_comboBox_socketTypeClient.enabled := not clientIsOn;
    c_edit_clientPort.enabled := not clientIsOn;
    c_edit_clientHost.enabled := not clientIsOn;
    c_button_configAudioCln.enabled := not clientIsOn;
    //
    c_cln_bindToIP.enabled := not clientIsOn;
    c_cln_bindToPort.enabled := not clientIsOn;
    //
    mi_options_LLN.enabled := not serverIsOn and not clientIsOn;
    mi_options_maxClients.enabled := not serverIsOn;
    //
    c_label_serverStat.caption := ' Server (' + int2str(ipServer.socksId) + '/' + choice({$IFDEF VC25_IOCP }ipServer.useIOCPSocketsModel{$ELSE }false{$ENDIF VC25_IOCP }, 'IOCP', 'Select') + ')  [in/out: ' + wideString(bytes2str(ipServer.bytesReceived, true)) + '/' + bytes2str(ipServer.bytesSent, true) + ' KB]   [Lost: ' + int2str(ipServer.inPacketsOutOfSeq) + ' packets] [Clients: ' + int2str(ipServer.clientCount) + '/' + int2str(ipServer.maxClients) + ']';
    c_label_clientStat.caption := ' Client (' + int2str(ipClient.socksId) + '/' + choice({$IFDEF VC25_IOCP }ipClient.useIOCPSocketsModel{$ELSE }false{$ENDIF VC25_IOCP }, 'IOCP', 'Select') + '/' + int2str(ipCLient.clientConnId) + ')   [in/out: ' + wideString(bytes2str(ipClient.bytesReceived, true)) + '/' + bytes2str(ipClient.bytesSent, true) + ' KB]   [Lost: ' + int2str(ipClient.inPacketsOutOfSeq) + ' packets]';
    //
    c_statusBar_main.panels[0].text := 'Mem: ' + bytes2str(ams(), true) + ' KB';
    //
    c_cb_serverIOCP.enabled := not serverIsOn;
    c_cb_clientIOCP.enabled := not clientIsOn;
    //
    c_button_kick.enabled := (0 < ipServer.clientCount);
    //
{$IFDEF DEBUG }
    c_clb_server.visible := true;
    c_clb_client.visible := true;
    c_label_srCodecInfo.visible := true;
    c_label_clCodecInfo.visible := true;
    //
    c_clb_server.checked[0] := waveIn_server.active;
    c_clb_server.checked[1] := codecIn_server.active;
    c_clb_server.checked[2] := ipServer.active;
    c_clb_server.checked[3] := codecOut_server.active;
    c_clb_server.checked[4] := waveOut_server.active;
    //
    c_clb_server.items[0] := 'waveIn   - I/O: ' + bytes2str(waveIn_server.inBytes)   + '/' + bytes2str(waveIn_server.outBytes)   + ' | ' + bytes2str(waveIn_server.device.getDataAvailable(true))   + '/' + bytes2str(waveIn_server.device.getDataAvailable(false));
    c_clb_server.items[1] := 'codecIn  - I/O: ' + bytes2str(codecIn_server.inBytes)  + '/' + bytes2str(codecIn_server.outBytes)  + ' | ' + bytes2str(codecIn_server.device.getDataAvailable(true))  + '/' + bytes2str(codecIn_server.device.getDataAvailable(false));
    c_clb_server.items[2] := 'ipServer - I/O: ' + bytes2str(ipServer.inBytes)        + '/' + bytes2str(ipServer.outBytes)        + ' | ';
    c_clb_server.items[3] := 'codecOut - I/O: ' + bytes2str(codecOut_server.inBytes) + '/' + bytes2str(codecOut_server.outBytes) + ' | ' + bytes2str(codecOut_server.device.getDataAvailable(true)) + '/' + bytes2str(codecOut_server.device.getDataAvailable(false));
    c_clb_server.items[4] := 'waveOut  - I/O: ' + bytes2str(waveOut_server.inBytes)  + '/' + bytes2str(waveOut_server.outBytes)  + ' | ' + bytes2str(waveOut_server.device.getDataAvailable(true))  + '/' + bytes2str(waveOut_server.device.getDataAvailable(false));
    //
    case (c_clb_server.itemIndex) of

      0: c_label_srCodecInfo.caption := deviceInfo(waveIn_server);
      1: c_label_srCodecInfo.caption := codecInfo(codecIn_server);
      3: c_label_srCodecInfo.caption := codecInfo(codecOut_server);
      4: c_label_srCodecInfo.caption := deviceInfo(waveOut_server);

      else
	 c_label_srCodecInfo.caption := '';
    end;
    //
    //
    c_clb_client.checked[0] := waveIn_client.active;
    c_clb_client.checked[1] := codecIn_client.active;
    c_clb_client.checked[2] := ipClient.active;
    c_clb_client.checked[3] := codecOut_client.active;
    c_clb_client.checked[4] := waveOut_client.active;
    //
    c_clb_client.items[0] := 'waveIn   - I/O: ' + bytes2str(waveIn_client.inBytes)   + '/' + bytes2str(waveIn_client.outBytes)   + ' | ' + bytes2str(waveIn_client.device.getDataAvailable(true))   + '/' + bytes2str(waveIn_client.device.getDataAvailable(false));
    c_clb_client.items[1] := 'codecIn  - I/O: ' + bytes2str(codecIn_client.inBytes)  + '/' + bytes2str(codecIn_client.outBytes)  + ' | ' + bytes2str(codecIn_client.device.getDataAvailable(true))  + '/' + bytes2str(codecIn_client.device.getDataAvailable(false));
    c_clb_client.items[2] := 'ipClient - I/O: ' + bytes2str(ipClient.inBytes)        + '/' + bytes2str(ipClient.outBytes)        + ' | ';
    c_clb_client.items[3] := 'codecOut - I/O: ' + bytes2str(codecOut_client.inBytes) + '/' + bytes2str(codecOut_client.outBytes) + ' | ' + bytes2str(codecOut_client.device.getDataAvailable(true)) + '/' + bytes2str(codecOut_client.device.getDataAvailable(false));
    c_clb_client.items[4] := 'waveOut  - I/O: ' + bytes2str(waveOut_client.inBytes)  + '/' + bytes2str(waveOut_client.outBytes)  + ' | ' + bytes2str(waveOut_client.device.getDataAvailable(true))  + '/' + bytes2str(waveOut_client.device.getDataAvailable(false));
    //
    case (c_clb_client.itemIndex) of

      0: c_label_clCodecInfo.caption := deviceInfo(waveIn_client);
      1: c_label_clCodecInfo.caption := codecInfo(codecIn_client);
      3: c_label_clCodecInfo.caption := codecInfo(codecOut_client);
      4: c_label_clCodecInfo.caption := deviceInfo(waveOut_client);

      else
	 c_label_clCodecInfo.caption := '';
    end;
{$ELSE}
    //
{$ENDIF}
  end;
end;


procedure Tc_form_main.waveIn_clientDataAvailable(sender: unavclInOutPipe; data: Pointer; len: Cardinal);
begin
{$IFDEF DEBUG }
{$ENDIF DEBUG }
end;

// --  --
procedure Tc_form_main.a_server_startExecute(Sender: TObject);
begin
  a_server_start.enabled := false;
  //
  ipServer.port := c_edit_serverPort.text;
  ipServer.bindTo := c_cb_serverBindTo.text;
  //
  // activate server
  waveIn_server.open();
  //
  if (not waveIn_server.active) then begin
    //
    waveIn_server.close();
    raise exception.create('Unable to open waveIn device, error text: '#13#10 + waveIn_server.waveErrorAsString);
  end;
end;

// --  --
procedure Tc_form_main.a_server_stopExecute(Sender: TObject);
begin
  a_server_stop.enabled := false;
  // stop server
  waveIn_server.close();
end;

// --  --
procedure Tc_form_main.a_client_startExecute(Sender: TObject);
begin
  a_client_start.enabled := false;
  f_waveIn_clientShouldBeClosed := false;
  //
  ipClient.port := c_edit_clientPort.text;
  ipClient.host := c_edit_clientHost.text;
  ipClient.bindTo := c_cln_bindToIP.text;
  ipClient.bindToPort := c_cln_bindToPort.text;
  //
{$IFDEF DEBUG }
  //f_clientFlood := c_cb_clientFlood.checked;
{$ENDIF DEBUG }
  // activate wave components
  waveIn_client.open();
  if (not waveIn_client.active) then begin
    //
    waveIn_client.close();
    //
    raise exception.create('Unable to open waveIn device, error text: '#13#10 + waveIn_client.waveErrorAsString);
  end;
end;

// --  --
procedure Tc_form_main.a_client_stopExecute(Sender: TObject);
begin
  a_client_stop.enabled := false;
  // stop client
  waveIn_client.close();
end;

// --  --

// --  --
procedure Tc_form_main.c_timer_updateTimer(Sender: TObject);
begin
  if (not (csDestroying in componentState)) then begin
    //
    updateStatus();
    //
    c_pb_clientIn.position := waveGetLogVolume(waveIn_client.device.getVolume());
    c_pb_clientOut.position := waveGetLogVolume(waveOut_client.device.getVolume());
    //
    c_pb_serverIn.position := waveGetLogVolume(waveIn_server.device.getVolume());
    c_pb_serverOut.position := waveGetLogVolume(waveOut_server.device.getVolume());
    //
    if (f_waveIn_clientShouldBeClosed) then begin
      //
      waveIn_client.close();
      f_waveIn_clientShouldBeClosed := false;
    end;
  end;
end;

// --  --
procedure Tc_form_main.c_comboBox_socketTypeServerChange(Sender: TObject);
begin
  if (0 = c_comboBox_socketTypeServer.itemIndex) then
    ipServer.proto := unapt_UDP
  else
    ipServer.proto := unapt_TCP;
end;

// --  --
procedure Tc_form_main.c_comboBox_socketTypeClientChange(Sender: TObject);
begin
  if (0 = c_comboBox_socketTypeClient.itemIndex) then
    ipClient.proto := unapt_UDP
  else
    ipClient.proto := unapt_TCP;
end;

// --  --
procedure Tc_form_main.ipServerPacketEvent(sender: TObject; connId: tConID; cmd: uint; data: pointer; len: uint);
begin
  if (not (csDestroying in ComponentState)) then begin
    //
    case (cmd) of
      //
      cmd_inOutIPPacket_audio:
	f_monitorServer.setValue(0, len);

    end;
  end;
end;

// --  --
procedure Tc_form_main.ipClientPacketEvent(sender: TObject; connId: tConID; cmd: uint; data: pointer; len: uint);
begin
  if (not (csDestroying in componentState)) then begin
    //
    case (cmd) of
      //
      cmd_inOutIPPacket_audio:
	f_monitorClient.setValue(0, len);

      cmd_inOutIPPacket_outOfSeats: begin
	//
	if (c_timer_update.enabled) then begin
	  //
	  // server is out of seats for us :(
	  guiMessageBox(handle, 'Server is out of seats.', 'Unable to connect', MB_OK);
	end;
      end;

    end;
  end;  
end;

// --  --
procedure Tc_form_main.c_button_configAudioSrvClick(sender: tObject);
begin
  c_form_common_audioConfig.doConfig(waveIn_server, waveOut_server, codecIn_server, nil, f_config, 'waveConfig.server');
end;

// --  --
procedure Tc_form_main.c_button_configAudioClnClick(Sender: TObject);
begin
  c_form_common_audioConfig.doConfig(waveIn_client, waveOut_client, codecIn_client, nil, f_config, 'waveConfig.client');
end;

// --  --
procedure Tc_form_main.mi_help_aboutClick(sender: tObject);
begin
  c_form_about.showAbout();
end;

// --  --
procedure Tc_form_main.mi_options_autoActivateSrvClick(Sender: TObject);
begin
  mi_options_autoActivateSrv.checked := not mi_options_autoActivateSrv.checked;
end;

// --  --
procedure Tc_form_main.mi_options_LLNClick(Sender: TObject);
begin
  mi_options_LLN.checked := not mi_options_LLN.checked;
  //
  adjustReceiveBuffers(mi_options_LLN.checked);
end;

// --  --
procedure Tc_form_main.adjustReceiveBuffers(enabled: bool);
var
  size: unsigned;
begin
  size := choice(enabled, 40, unsigned(defOverNumValue));
  //
  // adjust size of receive buffers
  codecOut_server.overNum := size;
  waveOut_server.overNum := size;
  codecIn_server.overNum := size;
  waveIn_server.overNum := size;
end;

// --  --
procedure Tc_form_main.mi_file_exitClick(Sender: TObject);
begin
  close();
end;

// --  --
procedure Tc_form_main.numClientsClick(Sender: TObject);
begin
  if (sender is tMenuItem) then begin
    //
    adjustNumClients((sender as tMenuItem).tag);
    (sender as tMenuItem).checked := true;
  end;
end;

// --  --
procedure Tc_form_main.mi_switch2RAWClick(Sender: TObject);
begin
  {$IFDEF DEBUG }
  if (mi_switch2RAW.checked) then
    ipServer.streamingMode := unasm_VC
  else
    ipServer.streamingMode := unasm_RAW;
  //
  ipClient.streamingMode := ipServer.streamingMode;
  mi_switch2RAW.checked := not mi_switch2RAW.checked;
  {$ENDIF DEBUG }
end;

// --  --
procedure Tc_form_main.adjustNumClients(maxNum: int);
begin
  // make sure server is stopped
  a_server_stop.execute();
  //
  if (1 <> maxNum) then
    ipServer.consumer := nil	// no sence to feed output with more than one client
  else
    ipServer.consumer := codecOut_server;	// feed output with one client
  //
  ipServer.maxClients := maxNum;
end;

// --  --
procedure Tc_form_main.ipServerSocketEvent(sender: TObject; connId: tConID; event: unaSocketEvent; data: Pointer; len: uint);
begin
  case (event) of

    unaseThreadStartupError: begin
      //
      if (c_timer_update.enabled) then begin
	//
	guiMessageBox(handle, 'Server cannot startup.'#13#10'Check if server port is not used by other applications, and address to bind to is correct.', 'Server Soket Error', MB_OK);
	waveIn_server.close();
      end;	
    end;

  end;
end;

// --  --
procedure Tc_form_main.ipClientSocketEvent(sender: TObject;  connId: Cardinal; event: unaSocketEvent; data: Pointer; len: Cardinal);
begin
  case (event) of

    unaseThreadStartupError: begin
      //
      if (c_timer_update.enabled) then begin
	//
	guiMessageBox(handle, 'Client cannot connect.'#13#10'Check if server is up and running and both server address and port are correct.', 'Client Soket Error', MB_OK);
	waveIn_client.close();
      end;
    end;

  end;
end;

// --  --
procedure Tc_form_main.ipClientClientDisconnect(sender: TObject; connId: Cardinal; connected: LongBool);
begin
  // since client may be disconnected explicitly, we need to care about closing other devices
  if (c_timer_update.enabled) then begin
    //
    // this may not work, because it may happen _before_ waveIn get active = true
    //
    //waveIn_client.close(100);	// do not hammer client components with long timeouts..
    //
    f_waveIn_clientShouldBeClosed := true;
  end;
end;

procedure Tc_form_main.ipClientDataSent(sender: TObject; connId: tConID; data: Pointer; len: uint);
begin
  if (not (csDestroying in componentState)) then
    f_monitorClient.setValue(1, len);
end;

// --  --
procedure Tc_form_main.ipServerDataSent(sender: TObject; connId: tConID; data: Pointer; len: uint);
begin
  if (not (csDestroying in componentState)) then
    f_monitorServer.setValue(1, len);
end;

// --  --
procedure Tc_form_main.c_cb_monServerEnabledClick(Sender: TObject);
begin
  f_monitorServer.active := c_cb_monServerEnabled.Checked;
end;

// --  --
procedure Tc_form_main.c_cb_monClientEnabledClick(Sender: TObject);
begin
  f_monitorClient.active := c_cb_monClientEnabled.Checked;
end;

// --  --
procedure Tc_form_main.c_cb_serverIOCPClick(Sender: TObject);
begin
  if (not f_iocpChanging) then try
    //
{$IFDEF VC25_IOCP }
    f_iocpChanging := true;
    ipServer.useIOCPSocketsModel := c_cb_serverIOCP.checked;
    // server and client share same socks object
    ipClient.useIOCPSocketsModel := ipServer.useIOCPSocketsModel;
    //
    c_cb_clientIOCP.checked := c_cb_serverIOCP.checked;
{$ENDIF VC25_IOCP }
  finally
    f_iocpChanging := false;
  end;
end;

// --  --
procedure Tc_form_main.c_cb_clientIOCPClick(Sender: TObject);
begin
  if (not f_iocpChanging) then try
    //
    f_iocpChanging := true;
{$IFDEF VC25_IOCP }
    ipClient.useIOCPSocketsModel := c_cb_clientIOCP.checked;
    // client and server share same socks object
    ipServer.useIOCPSocketsModel := ipClient.useIOCPSocketsModel;
    //
    c_cb_serverIOCP.checked := c_cb_clientIOCP.checked;
{$ENDIF VC25_IOCP }
  finally
    f_iocpChanging := false;
  end;
end;

// --  --
procedure Tc_form_main.c_button_kickClick(Sender: TObject);
var
  connId: unsigned;
begin
  // disconnect client with index 0
  //
  connId := ipServer.getClientConnId(0);
  if (0 < connId) then begin
    //
{$IFDEF DEBUG }
    logMessage('About to kick client with connId=' + int2str(connId));
{$ENDIF DEBUG }
    //
    // tell client to disconnect politely
    ipServer.sendPacket(connId, cmd_inOutIPPacket_bye);
    //
    // give packet a chance to get to remote size
    Sleep(300);
    //
{$IFDEF DEBUG }
    logMessage('About to remove connId=' + int2str(connId));
{$ENDIF DEBUG }
    // and now force unpolitely to remove the connection (if any)
    ipServer.socks.removeConnection(ipServer.socksId, connId);
    //
{$IFDEF DEBUG }
    logMessage('Kick done.');
{$ENDIF DEBUG }
  end;
end;


end.

