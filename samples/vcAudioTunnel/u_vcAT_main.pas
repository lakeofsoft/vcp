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

	  u_vcAT_main.pas
	  Voice Communicator components version 2.5 Pro
	  VC Audio Tunnel application - main form

	----------------------------------------------
	  Copyright (c) 2003-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 18 Dec 2003

	  modified by:
		Lake, Jan-Mar 2004
		Lake, May 2009

	----------------------------------------------
*)

{$I unaDef.inc }

unit
  u_vcAT_main;

interface

uses
  Windows, unaTypes, unaClasses, Forms, unaVC_socks,
  ExtCtrls, unaVcIDE, ComCtrls, StdCtrls, Controls, Classes, Menus,
  unaVC_pipe;

type
  {
    //
  }
  Tc_form_main = class(TForm)
    c_edit_remotePort: TEdit;
    Label1: TLabel;
    Bevel1: TBevel;
    Label2: TLabel;
    c_edit_listenPort: TEdit;
    c_edit_remoteHost: TEdit;
    c_button_start: TButton;
    c_button_stop: TButton;
    c_statusBar_main: TStatusBar;
    ipServer: TunavclIPInStream;
    ipClient: TunavclIPOutStream;
    c_timer_update: TTimer;
    c_label_srvInfo: TLabel;
    Bevel2: TBevel;
    c_label_clnInfo: TLabel;
    c_comboBox_socketTypeServer: TComboBox;
    c_comboBox_socketTypeClient: TComboBox;
    Label3: TLabel;
    c_mm_main: TMainMenu;
    File1: TMenuItem;
    Exit1: TMenuItem;
    c_cb_iocp: TCheckBox;
    //
    procedure formCreate(sender: tObject);
    procedure formDestroy(sender: tObject);
    procedure formShow(sender: tObject);
    procedure formCloseQuery(sender: tObject; var canClose: boolean);
    //
    procedure c_timer_updateTimer(Sender: TObject);
    procedure c_button_startClick(Sender: TObject);
    procedure c_button_stopClick(Sender: TObject);
    //
    procedure ipServerServerClientDisconnect(sender: TObject; connectionId: Cardinal; connected: LongBool);
    procedure ipServerAcceptClient(sender: TObject; connectionId: Cardinal; var accept: LongBool);
    procedure Exit1Click(Sender: TObject);
  private
    { Private declarations }
    //
    f_config: unaIniFile;
    //
    f_remoteHost: string;
    f_remotePort: string;
    f_remotePortProto: tunavclProtoType;
    //
    f_connId: unsigned;
    //
    procedure closeTunnel();
  public
    { Public declarations }
  end;

var
  c_form_main: Tc_form_main;


implementation


{$R *.dfm}

uses
  WinSock, unaUtils, unaVCLUtils;

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
procedure Tc_form_main.formShow(Sender: TObject);
begin
  loadControlPosition(self, f_config);
  //
  c_edit_listenPort.text := f_config.get('ip.server.port', '17820');
  c_comboBox_socketTypeServer.itemIndex := f_config.get('ip.server.proto', int(0));
  //
  c_edit_remoteHost.text := f_config.get('ip.client.host', '192.168.1.2');
  c_edit_remotePort.text := f_config.get('ip.client.port', '17820');
  c_comboBox_socketTypeClient.itemIndex := f_config.get('ip.client.proto', int(0));
  //
  //c_cb_iocp.checked := f_config.get('ip.client.proto', );
  //
  c_timer_update.enabled := true;
end;

// --  --
procedure Tc_form_main.formCloseQuery(sender: tObject; var canClose: boolean);
begin
  c_timer_update.enabled := false;
  // stop tunnel
  closeTunnel();
  //
  f_config.setValue('ip.server.port', c_edit_listenPort.text);
  f_config.setValue('ip.server.proto', c_comboBox_socketTypeServer.itemIndex);
  //
  f_config.setValue('ip.client.host', c_edit_remoteHost.text);
  f_config.setValue('ip.client.port', c_edit_remotePort.text);
  f_config.setValue('ip.client.proto', c_comboBox_socketTypeClient.itemIndex);
  //
  saveControlPosition(self, f_config);
end;

// --  --
procedure Tc_form_main.c_timer_updateTimer(Sender: TObject);
var
  active: bool;
begin
  c_statusBar_main.panels[0].text := 'SRV in/out: ' + int2str(ipServer.inBytes[1], 10, 3) + '/' + int2str(ipServer.outBytes[1], 10, 3);
  c_statusBar_main.panels[1].text := 'CLN in/out: ' + int2str(ipClient.inBytes[1], 10, 3) + '/' + int2str(ipClient.outBytes[1], 10, 3);
  //
  c_label_srvInfo.caption := 'Server is ' + choice(ipServer.active, 'active', 'closed') + ', ' + choice(0 < ipServer.clientCount, 'one peer is connected', 'no peer is connected');
  c_label_clnInfo.caption := 'Client is ' + choice(ipClient.active, 'connected', 'not connected');
  //
  active := ipServer.active;
  c_button_start.enabled := not active;
  c_button_stop.enabled := not c_button_start.enabled;
  //
  c_edit_listenPort.enabled := not active;
  c_comboBox_socketTypeServer.enabled := not active;
  c_edit_remoteHost.enabled := not active;
  c_edit_remotePort.enabled := not active;
  c_comboBox_socketTypeClient.enabled := not active;
end;

// --  --
procedure Tc_form_main.ipServerAcceptClient(sender: TObject; connectionId: Cardinal; var accept: LongBool);
begin
  if (accept and (1 > ipServer.clientCount)) then begin
    // got new client - re-activate ipClient
    ipClient.close();
    //
    // VCL should not be used here, that is why we use private strings
    // to store host/port/proto values
    ipClient.host := f_remoteHost;
    ipClient.port := f_remotePort;
    ipClient.proto := f_remotePortProto;
    //
    f_connId := connectionId;
    //
    ipClient.open();
  end;
end;

// --  --
procedure Tc_form_main.ipServerServerClientDisconnect(sender: TObject; connectionId: Cardinal; connected: LongBool);
begin
  if (not connected and ((0 = f_connId) or (connectionId = f_connId))) then begin
    //
    // simply close client connection
    ipClient.close();
    //
    f_connId := 0;
  end;
end;

// --  --
procedure Tc_form_main.c_button_startClick(Sender: TObject);
begin
  // remember them locally
  f_remoteHost := c_edit_remoteHost.text;
  f_remotePort := c_edit_remotePort.text;
  if (0 = c_comboBox_socketTypeClient.itemIndex) then
    f_remotePortProto := unapt_UDP
  else
    f_remotePortProto := unapt_TCP;
  //
  ipServer.close();	// just in case
  //
  // start server, our ipClient will be activated when first client will be connected to server
  ipServer.port := c_edit_listenPort.text;
  if (0 = c_comboBox_socketTypeServer.itemIndex) then
    ipServer.proto := unapt_UDP
  else
    ipServer.proto := unapt_TCP;
  //
  ipServer.open();
end;

// --  --
procedure Tc_form_main.c_button_stopClick(Sender: TObject);
begin
  closeTunnel();
end;

// --  --
procedure Tc_form_main.closeTunnel();
begin
  // close both
  ipClient.close();
  ipServer.close();
  //
  f_connId := 0;
end;

// --  --
procedure Tc_form_main.Exit1Click(Sender: TObject);
begin
  close();
end;


end.

