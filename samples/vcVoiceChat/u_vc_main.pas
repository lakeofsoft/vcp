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

	  u_vc_main.pas
	  vcVoiceChat demo application - main form source

	----------------------------------------------
	  Copyright (c) 2003-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 25 Jan 2003

	  modified by:
		Lake, Jan 2003
		Lake, Oct 2005
		Lake, Jan-Apr 2007

	----------------------------------------------
*)

{$I unaDef.inc}

unit u_vc_main;

interface

uses
  Windows, unaTypes, unaClasses, unaSockets, unaVcIDE, 
  Forms, Messages, StdActns, Classes, ActnList, Menus, Controls,
  StdCtrls, ComCtrls, ExtCtrls, CheckLst, unaVC_wave, unaVC_socks,
  unaVC_pipe;

const
  WM_ADDOUTTEXT	= WM_USER + 1;

type
  Tc_form_main = class(TForm)
    c_memo_remote: TMemo;
    c_mainMenu: TMainMenu;
    c_actionList_main: TActionList;
    a_chat_beClient: TAction;
    a_chat_beServer: TAction;
    mi_file: TMenuItem;
    mi_chat_goClient: TMenuItem;
    mi_chat_goServer: TMenuItem;
    mi_file_exit: TMenuItem;
    c_splitter_main: TSplitter;
    c_memo_client: TMemo;
    c_statusBar_main: TStatusBar;
    c_timer_update: TTimer;
    waveIn: TunavclWaveInDevice;
    codecIn: TunavclWaveCodecDevice;
    ipClient: TunavclIPOutStream;
    ipServer: TunavclIPInStream;
    codecOut: TunavclWaveCodecDevice;
    waveOut: TunavclWaveOutDevice;
    a_chat_stop: TAction;
    mi_chat_stop: TMenuItem;
    c_file_exit: TAction;
    mi_edit: TMenuItem;
    mi_edit_audio: TMenuItem;
    mi_edit_clearRemote: TMenuItem;
    mi_editAudio_1: TMenuItem;
    mi_editAudio_2: TMenuItem;
    mi_editAudio_3: TMenuItem;
    mi_options_esd: TMenuItem;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    N4: TMenuItem;
    N5: TMenuItem;
    N6: TMenuItem;
    N7: TMenuItem;
    mi_sockets_udp: TMenuItem;
    mi_sockets_tcp: TMenuItem;
    mi_options_auth: TMenuItem;
    c_panel_info: TPanel;
    c_label_info: TLabel;
    Splitter1: TSplitter;
    mi_options_card: TMenuItem;
    c_clb_debug: TCheckListBox;
    mi_editAudio_4: TMenuItem;
    Help1: TMenuItem;
    About1: TMenuItem;
    //
    procedure formDestroy(sender: tObject);
    procedure formCreate(sender: tObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    //
    procedure c_timer_updateTimer(sender: tObject);
    //
    procedure a_chat_beServerExecute(sender: tObject);
    procedure a_chat_beClientExecute(sender: tObject);
    procedure a_chat_stopExecute(sender: tObject);
    //
    procedure ipServerServerNewClient(sender: tObject; connectionId: cardinal; connected: longBool);
    procedure ipServerTextData(sender: tObject; connectionId: Cardinal; const data: string);
    procedure ipServerSocketEvent(sender: TObject; connectionId: Cardinal; event: unaSocketEvent; data: Pointer; len: Cardinal);
    procedure ipServerAcceptClient(sender: TObject; connectionId: Cardinal; var accept: LongBool);
    procedure ipServerServerClientDisconnect(sender: TObject; connectionId: Cardinal; connected: LongBool);
    procedure ipServerDataSent(sender: TObject; connectionId: Cardinal; data: Pointer; len: Cardinal);
    //
    procedure ipClientClientConnect(sender: tObject; connectionId: cardinal; connected: longBool);
    procedure ipClientTextData(sender: tObject; connectionId: Cardinal; const data: string);
    procedure ipClientClientDisconnect(sender: TObject; connectionId: Cardinal; connected: LongBool);
    //
    procedure c_memo_clientKeyPress(sender: tObject; var key: char);
    procedure c_file_exitExecute(sender: tObject);
    //
    procedure mi_edit_clearRemoteClick(sender: tObject);
    procedure mi_editAudio_click(sender: tObject);
    procedure mi_options_esdClick(sender: tObject);
    procedure mi_sockets_udpClick(Sender: TObject);
    procedure mi_sockets_tcpClick(Sender: TObject);
    procedure mi_options_authClick(Sender: TObject);
    //
    procedure ipClientPacketEvent(sender: TObject; connId, cmd: Cardinal; data: Pointer; len: Cardinal);
    procedure ipServerPacketEvent(sender: TObject; connId, cmd: Cardinal; data: Pointer; len: Cardinal);
    procedure About1Click(Sender: TObject);
  private
    { Private declarations }
    f_host: string;
    f_config: unaIniFile;
    //
    f_needEnableClientMemo: bool;
    f_needDisableClientMemo: bool;
    //
    f_delayedStrings: tStringList;
    f_socketProto: tunavclProtoType;
    f_authPass: string;
    f_remotePass: string;
    f_authTakeCare: bool;
    f_authTM: uint64;
    //
    procedure loadConfig();
    //
    procedure serverAction(doStart: bool);
    procedure clientAction(doStart: bool);
    procedure silenceDetectionChanged(isEnabled: bool);
    //
    procedure checkServerClientOptions();
    //
    procedure onWMAddOutText(var msg: TMessage); message WM_ADDOUTTEXT;
  public
    { Public declarations }
  end;

var
  c_form_main: Tc_form_main;


implementation


{$R *.dfm}

uses
  unaUtils, unaVclUtils, unaMsAcmClasses,
  Dialogs, Graphics, ShellAPI;

var
  // must be global vars!
  msg1: string;
  msg2: string;
  msg3: string;
  msg4: string;
  msg5: string;


const
  pw_prefix = '$PW$:';

// --  --
procedure Tc_form_main.formDestroy(sender: TObject);
begin
  f_config.setValue('ip.client.remoteServer', f_host);
  f_config.setValue('ip.connection.proto', ord(f_socketProto));
  //
  saveControlPosition(self, f_config);
  freeAndnil(f_config);
  freeAndnil(f_delayedStrings);
end;

// --  --
procedure Tc_form_main.loadConfig();
begin
  loadControlPosition(self, f_config);
  //
  f_host := f_config.get('ip.client.remoteServer', '192.168.0.1');
  //
  f_needEnableClientMemo := false;
  f_needDisableClientMemo := true;
  //
  f_socketProto := tunavclProtoType(f_config.get('ip.connection.proto', ord(unapt_UDP)));
  if (unapt_UDP = f_socketProto) then
    mi_sockets_udp.checked := true
  else
    mi_sockets_tcp.checked := true;
  //
  waveIn.pcm_samplesPerSec := f_config.get('wave.samplesPerSec', unsigned(22050));
  case (waveIn.pcm_samplesPerSec) of

    8000:
      mi_editAudio_1.checked := true;

    11025:
      mi_editAudio_2.checked := true;

    else
      mi_editAudio_3.checked := true;

  end;
  //
  mi_options_esd.checked := f_config.get('wave.silenceDetectionEnabled', true);
  silenceDetectionChanged(mi_options_esd.checked);
  //
  f_authPass := f_config.get('auth.pw', '');
end;

// --  --
procedure Tc_form_main.formCreate(sender: TObject);
//var
  //i: int;
begin
  f_config := unaIniFile.create();
  f_delayedStrings := tStringList.create();
  //
  //for i := 0 to unaMsAcmClasses.
  //
  loadConfig();
  //
  c_clb_debug.items.text :=
'waveIn'#13#10 +
'codecIn'#13#10 +
'ipClient'#13#10 +
''#13#10 +
'ipServer'#13#10 +
'codecOut'#13#10 +
'waveOut'#13#10;
  //
  c_clb_debug.visible := {$IFDEF DEBUG}true{$ELSE}false{$ENDIF};
end;

// --  --
procedure Tc_form_main.c_file_exitExecute(Sender: TObject);
begin
  close();
end;

// --  --
procedure Tc_form_main.c_timer_updateTimer(Sender: TObject);
begin
  if (not (csDestroying in componentState)) then begin
    //
    {$IFDEF DEBUG }
    c_statusBar_main.panels[0].text := int2str(ams() shr 10, 10, 3) + ' KB';
    {$ENDIF }
    //
    a_chat_beServer.enabled := not ipServer.active;
    a_chat_beClient.enabled := not ipClient.active;
    //
    if (not a_chat_beServer.enabled and a_chat_beClient.enabled) then begin
      //
      c_statusBar_main.panels[1].text := 'Mode: Server';
      a_chat_stop.enabled := true;
      mi_edit_audio.enabled := false;
    end
    else
      if (a_chat_beServer.enabled and not a_chat_beClient.enabled) then begin
	//
	c_statusBar_main.panels[1].text := 'Mode: Client';
	a_chat_stop.enabled := true;
	mi_edit_audio.enabled := false;
      end
      else begin
	//
	c_statusBar_main.panels[1].text := 'Mode: none';
	a_chat_stop.enabled := false;
	mi_edit_audio.enabled := true;
	//
	waveIn.close();
      end;
    //
    {$IFDEF DEBUG }
    if (c_clb_debug.visible) then begin
      //
      c_clb_debug.checked[0] := waveIn.active;
      c_clb_debug.checked[1] := codecIn.active;
      c_clb_debug.checked[2] := ipClient.active;
      //
      c_clb_debug.checked[4] := ipServer.active;
      c_clb_debug.checked[5] := codecOut.active;
      c_clb_debug.checked[6] := waveOut.active;
    end;
    {$ENDIF }
    //
    c_label_info.caption :=
      'Client sent: '     + int2str(ipClient.inBytes[1],  10, 3) + ' bytes ' + #13#10 +
      'Client received: ' + int2str(ipClient.outBytes[1], 10, 3) + ' bytes ' + #13#10 +
      'Server sent: '     + int2str(ipServer.inBytes[1],  10, 3) + ' bytes ' + #13#10 +
      'Server received: ' + int2str(ipServer.outBytes[1], 10, 3) + ' bytes ' + #13#10 +
      ''
    ;
    //
    if (f_needDisableClientMemo) then begin
      //
      f_needDisableClientMemo := false;
      //
      c_memo_client.enabled := false;
      c_memo_client.color := clBtnFace;
    end;
    //
    if (f_needEnableClientMemo) then begin
      //
      f_needEnableClientMemo := false;
      //
      c_memo_client.enabled := true;
      c_memo_client.color := clWindow;
      //
      if (showing) then
	windows.setFocus(c_memo_client.handle);
      //
    end;
    //
    while (0 < f_delayedStrings.count) do begin
      //
      try
	if (f_authTakeCare) then
	  c_memo_remote.lines.add(#13#10 + 'Unauthorized (' + int2str( (10000 - timeElapsed64U(f_authTM)) div 1000) + ' seconds left) ' + string(f_delayedStrings[0]))
	else
	  c_memo_remote.lines.add(#13#10 + f_delayedStrings[0]);
	//
      finally
      end;
      //
      f_delayedStrings.delete(0);
    end;
    //
    if (f_authTakeCare) then begin
      //
      if (f_authPass = f_remotePass) then begin
	//
	f_authTakeCare := false;
	//
	ipServer.setClientOptions(0{hack, assuming we have only one client)}, c_unaIPServer_co_default{enable in/out data flow});
      end
      else begin
	//
	if (10000 < timeElapsed32U(f_authTM)) then
	  ipServer.sendPacket(ipServer.getClientConnId(0{hack, assuming we have only one client)}), cmd_inOutIPPacket_bye); // disconnect client
      end;
      //	  
    end;
  end;
end;

// --  --
procedure Tc_form_main.a_chat_beServerExecute(Sender: TObject);
begin
  serverAction(true);
end;

// --  --
procedure Tc_form_main.About1Click(Sender: TObject);
begin
  shellExecute(handle, 'open', 'http://lakeofsoft.com/vc/a_voicechat.html', nil, nil, SW_SHOWNORMAL);
end;

// --  --
procedure Tc_form_main.a_chat_beClientExecute(Sender: TObject);
begin
  clientAction(true);
end;

// --  --
procedure Tc_form_main.serverAction(doStart: bool);
begin
  if (doStart) then begin
    //
    clientAction(false);
    //
    ipServer.proto := f_socketProto;
    //
    codecIn.consumer := ipServer;
    ipServer.consumer := codecOut;
    //
    waveIn.open();
  end
  else begin
    //
    f_needDisableClientMemo := true;
    //
    waveIn.close();
    //
    //c_memo_remote.clear();
    //
    f_remotePass := '';	// make sure new connection will be authorized (if needed)
  end;
  //
  a_chat_beServer.enabled := not ipServer.active;
  a_chat_stop.enabled := not a_chat_beServer.enabled;
end;

// --  --
procedure Tc_form_main.clientAction(doStart: bool);
begin
  if (doStart) then begin
    //
    if (inputQuery('Enter Server address', 'Server IP address or DNS name', f_host)) then begin
      //
      serverAction(false);
      //
      ipClient.host := f_host;
      ipClient.proto := f_socketProto;
      //
      codecIn.consumer := ipClient;
      ipClient.consumer := codecOut;
      //
      f_authTakeCare := false;	// in server mode only!
      //
      waveIn.open();
    end;
  end
  else begin
    //
    f_needDisableClientMemo := true;
    //
    waveIn.close();
    //
    //c_memo_remote.clear();
  end;
  //
  a_chat_beClient.enabled := not ipClient.active;
  a_chat_stop.enabled := not a_chat_beClient.enabled;
end;

// --  --
procedure Tc_form_main.a_chat_stopExecute(Sender: TObject);
begin
  serverAction(false);
  clientAction(false);
end;

// --  --
procedure Tc_form_main.ipServerServerNewClient(sender: TObject; connectionId: Cardinal; connected: LongBool);
begin
  // should not access VCL here
  f_needEnableClientMemo := true;
  //
  msg4 := 'New client is connected';
  PostMessage(handle, WM_ADDOUTTEXT, 0, lparam(pChar(msg4)));
end;

// --  --
procedure Tc_form_main.ipClientClientConnect(sender: TObject; connectionId: Cardinal; connected: LongBool);
begin
  // do not access VCL here!
  f_needEnableClientMemo := true;
  //
  if ('' <> f_authPass) then
    ipClient.sendText(connectionId, aString(pw_prefix + f_authPass));
  //
  msg1 := choice(unapt_TCP = ipClient.proto, 'TCP', 'UDP') + ' client connected to ' + string(ipClient.host);
  PostMessage(handle, WM_ADDOUTTEXT, 0, lparam(pChar(msg1)));
end;

// --  --
procedure Tc_form_main.ipClientClientDisconnect(sender: TObject; connectionId: Cardinal; connected: LongBool);
begin
  // do not access VCL here!
  msg2 := choice(unapt_TCP = ipClient.proto, 'TCP', 'UDP') + ' client disconnected from ' + string(ipClient.host);
  PostMessage(handle, WM_ADDOUTTEXT, 0, lparam(pChar(msg2)));
  //
  f_needDisableClientMemo := true;
end;

// --  --
procedure Tc_form_main.c_memo_clientKeyPress(Sender: TObject; var Key: Char);
begin
  case (key) of

    #13: begin
      //
      if (ipServer.active) then begin
	//
	ipServer.sendText(ipServer.getClientConnId(0), aString(c_memo_client.text));
	c_memo_remote.lines.add(#13#10'server > ' + c_memo_client.text);
      end
      else
	if (ipClient.active) then begin
	  //
	  ipClient.sendText(ipClient.clientConnId, aString(c_memo_client.text));
	  c_memo_remote.lines.add(#13#10'client > ' + c_memo_client.text);
	end;
      //
      c_memo_client.clear();
      key := #0;
    end;

  end;
end;

// --  --
procedure Tc_form_main.ipClientTextData(sender: TObject; connectionId: Cardinal; const data: string);
begin
  // do not access VCL here!
  f_delayedStrings.add('server > ' + data);
end;

// --  --
procedure Tc_form_main.ipServerTextData(sender: tObject; connectionId: Cardinal; const data: string);
begin
  // do not access VCL here!
  if (1 = pos(pw_prefix, data)) then
    f_remotePass := copy(data, length(pw_prefix) + 1, maxInt)
  else
    f_delayedStrings.add('client > ' + data);
end;

// --  --
procedure Tc_form_main.mi_edit_clearRemoteClick(sender: tObject);
begin
  c_memo_remote.clear();
end;

// --  --
procedure Tc_form_main.mi_editAudio_click(sender: tObject);
begin
  if (sender is tMenuItem) then begin
    //
    with (sender as tMenuItem) do begin
      //
      waveIn.pcm_SamplesPerSec := tag;
      checked := true;
      //
      f_config.setValue('wave.samplesPerSec', tag);
      //
      checkServerClientOptions();
    end;
  end;
end;


// --  --
procedure Tc_form_main.mi_options_esdClick(sender: tObject);
begin
  mi_options_esd.checked := not mi_options_esd.checked;
  //
  f_config.setValue('wave.silenceDetectionEnabled', mi_options_esd.checked);
  //
  silenceDetectionChanged(mi_options_esd.checked);
end;

// --  --
procedure Tc_form_main.silenceDetectionChanged(isEnabled: bool);
begin
  // old school
  //waveIn.calcVolume := isEnabled;
  //
  // new school
  if (isEnabled) then
    waveIn.silenceDetectionMode := unasdm_DSP
  else
    waveIn.silenceDetectionMode := unasdm_none;
end;

// --  --
procedure Tc_form_main.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  a_chat_stopExecute(sender);
end;

// --  --
procedure Tc_form_main.mi_sockets_udpClick(Sender: TObject);
begin
  f_socketProto := unapt_UDP;
  mi_sockets_udp.checked := true;
  //
  checkServerClientOptions();
end;

// --  --
procedure Tc_form_main.mi_sockets_tcpClick(Sender: TObject);
begin
  f_socketProto := unapt_TCP;
  mi_sockets_tcp.checked := true;
  //
  checkServerClientOptions();
end;


// --  --
procedure Tc_form_main.ipServerSocketEvent(sender: TObject; connectionId: Cardinal; event: unaSocketEvent; data: Pointer; len: Cardinal);
begin
  // do not access VCL here
  //
  case (event) of

    unaseServerListen: begin
      //
      msg1 := choice(unapt_TCP = ipServer.proto, 'TCP', 'UDP') + ' server at port ' + string(ipServer.port) + ' started.';
      PostMessage(handle, WM_ADDOUTTEXT, 0, lparam(pChar(msg1)));
    end;

    unaseServerStop: begin
      //
      msg2 := choice(unapt_TCP = ipServer.proto, 'TCP', 'UDP') + ' server ' + string(ipServer.port) + ' stopped.';
      PostMessage(handle, WM_ADDOUTTEXT, 0, lparam(pChar(msg2)));
    end;

    unaseThreadStartupError: begin
      //
      msg3 := choice(unapt_TCP = ipServer.proto, 'TCP', 'UDP') + ' server ' + string(ipServer.port) + ' cannot be started.';
      PostMessage(handle, WM_ADDOUTTEXT, 0, lparam(pChar(msg3)));
    end;

  end;
end;

// --  --
procedure Tc_form_main.onWMAddOutText(var msg: TMessage);
begin
  case (msg.Msg) of

    WM_ADDOUTTEXT: begin
      //
      c_memo_remote.lines.add(pChar('SYS > ' + pChar(msg.lparam)));
    end;

  end;
end;

// --  --
procedure Tc_form_main.checkServerClientOptions();
var
  restartS: bool;
  restartC: bool;
begin
  restartS := (ipServer.active and (ipServer.proto <> f_socketProto));
  restartC := (ipClient.active and (ipClient.proto <> f_socketProto));
  //
  if (restartS or restartC) then begin
    //
    a_chat_stop.execute();
    //
    if (restartS) then
      a_chat_beServer.execute();
    //
    if (restartC) then
      a_chat_beClient.execute();
  end;
end;

// --  --
procedure Tc_form_main.mi_options_authClick(Sender: TObject);
var
  pass: string;
begin
  pass := string(f_authPass);
  if (inputQuery('Enter Server authorization string', 'Server password: ', pass)) then begin
    //
    if (string(f_authPass) <> trimS(pass)) then begin
      //
      f_authPass := trimS(pass);
      f_config.setValue('auth.pw', f_authPass);
      //
      if (ipServer.active) then begin
	//
	a_chat_stop.execute();
	a_chat_beServer.execute();
      end;
    end;
  end;
end;

// --  --
procedure Tc_form_main.ipServerAcceptClient(sender: TObject; connectionId: Cardinal; var accept: LongBool);
begin
  // check if we have to wait for proper auth from client
  f_authTakeCare := (('' <> f_authPass) and (f_authPass <> f_remotePass));
  //
  if (f_authTakeCare) then
    f_authTM := timeMarkU();
end;

// --  --
procedure Tc_form_main.ipServerDataSent(sender: TObject; connectionId: Cardinal; data: Pointer; len: Cardinal);
begin
  if (f_authTakeCare) then begin
    //
    ipServer.setClientOptions(0{hack, assuming we have only one client)}, 0{no in/out data allowed});
  end;
end;

// --  --
procedure Tc_form_main.ipServerServerClientDisconnect(sender: TObject; connectionId: Cardinal; connected: LongBool);
begin
  // assuming we have only one client
  f_needDisableClientMemo := true;
  //
  f_remotePass := '';	// next client will have to authorize properly
  //
  msg5 := 'Client is disconnected';
  PostMessage(handle, WM_ADDOUTTEXT, 0, lparam(pChar(msg5)));
end;

// --  --
procedure Tc_form_main.ipClientPacketEvent(sender: TObject; connId, cmd: Cardinal; data: Pointer; len: Cardinal);
begin
  //
end;

// --  --
procedure Tc_form_main.ipServerPacketEvent(sender: TObject; connId, cmd: Cardinal; data: Pointer; len: Cardinal);
begin
  //
end;


end.

