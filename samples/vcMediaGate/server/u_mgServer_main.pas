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

	  u_mgServer_main.pas
	  MediaGate demo application - Server main form source

	----------------------------------------------
	  Copyright (c) 2003-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 04 Apr 2003

	  modified by:
		Lake, Apr-Oct 2003
		Lake, Apr 2007
		Lake, Feb 2008

	----------------------------------------------
*)

{$I unaDef.inc }

unit
  u_mgServer_main;

interface

uses
  Windows, unaTypes, unaClasses, Forms,
  ExtCtrls, unaVcIDE, Controls, StdCtrls, CheckLst, Classes, ActnList, ComCtrls,
  Menus, unaVC_pipe, unaVC_socks;

type
  Tc_form_main = class(TForm)
    c_edit_speakPort: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    c_edit_listenPort: TEdit;
    c_button_start: TButton;
    c_button_stop: TButton;
    c_clb_debug: TCheckListBox;
    speakServer: TunavclIPInStream;
    listenServer: TunavclIPInStream;
    c_timer_update: TTimer;
    c_actionList_main: TActionList;
    a_srv_start: TAction;
    a_srv_stop: TAction;
    Label3: TLabel;
    Bevel2: TBevel;
    Label4: TLabel;
    Bevel3: TBevel;
    c_statusBar_main: TStatusBar;
    c_label_listeners: TLabel;
    c_label_served: TLabel;
    c_label_received: TLabel;
    c_comboBox_speakProto: TComboBox;
    Label5: TLabel;
    c_comboBox_listenProto: TComboBox;
    Label6: TLabel;
    c_comboBox_listener: TComboBox;
    Label7: TLabel;
    c_checkBox_allowListen: TCheckBox;
    c_checkBox_acceptSpeaker: TCheckBox;
    a_accept_speaker: TAction;
    a_accept_listener: TAction;
    c_mm_main: TMainMenu;
    File1: TMenuItem;
    Exit1: TMenuItem;
    c_cb_activateOnStart: TCheckBox;
    c_cb_IOCP: TCheckBox;
    Help1: TMenuItem;
    About1: TMenuItem;
    //
    procedure formCreate(sender: tObject);
    procedure formDestroy(sender: tObject);
    procedure formCloseQuery(sender: tObject; var CanClose: Boolean);
    procedure formShow(sender: tObject);
    //
    procedure c_timer_updateTimer(sender: tObject);
    procedure c_comboBox_listenerChange(Sender: TObject);
    //
    procedure a_srv_startExecute(sender: tObject);
    procedure a_srv_stopExecute(sender: tObject);
    procedure a_accept_speakerExecute(Sender: TObject);
    procedure a_accept_listenerExecute(Sender: TObject);
    //
    procedure speakServerServerNewClient(sender: TObject; connectionId: Cardinal; connected: LongBool);
    procedure listenServerServerNewClient(sender: TObject; connectionId: Cardinal; connected: LongBool);
    procedure listenServerServerClientDisconnect(sender: TObject; connectionId: Cardinal; connected: LongBool);
    procedure Exit1Click(Sender: TObject);
    procedure c_cb_IOCPClick(Sender: TObject);
    procedure About1Click(Sender: TObject);
  private
    { Private declarations }
    f_ini: unaIniFile;
    f_needListenerRefresh: bool;
    f_needSpeakerRefresh: bool;
  public
    { Public declarations }
  end;

var
  c_form_main: Tc_form_main;


implementation


{$R *.dfm}

uses
  Messages, unaUtils, unaVCLUtils, unaWave, winSock, unaSockets,
  ShellAPI;

// --  --
procedure Tc_form_main.formCreate(sender: tObject);
begin
  f_ini := unaIniFile.create();
end;

// --  --
procedure Tc_form_main.formDestroy(sender: tObject);
begin
  freeAndNil(f_ini);
end;

// --  --
procedure Tc_form_main.formCloseQuery(sender: tObject; var canClose: boolean);
begin
  saveControlPosition(self, f_ini);
  //
  c_timer_update.enabled := false;
  //
  speakServer.close();
  //
  with (f_ini) do begin
    //
    setValue('speak.proto', c_comboBox_speakProto.itemIndex);
    setValue('listen.proto', c_comboBox_listenProto.itemIndex);
    //
    setValue('speak.port', c_edit_speakPort.text);
    setValue('listen.port', c_edit_listenPort.text);
    setValue('gui.autoStartServers', c_cb_activateOnStart.checked);
    //
    {$IFDEF VC25_IOCP }
    f_ini.setValue('socks.useIOCP', c_cb_IOCP.checked);
    {$ENDIF VC25_IOCP }
  end;
end;

// --  --
procedure Tc_form_main.formShow(sender: tObject);
begin
  loadControlPosition(self, f_ini);
  //
  c_edit_speakPort.text := f_ini.get('speak.port', '17860');
  c_edit_listenPort.text := f_ini.get('listen.port', '17861');
  //
  c_comboBox_speakProto.itemIndex := f_ini.get('speak.proto', int(0));
  c_comboBox_listenProto.itemIndex := f_ini.get('listen.proto', int(0));
  //
  c_clb_debug.visible := {$IFDEF DEBUG}true{$ELSE}false{$ENDIF};
  c_cb_activateOnStart.checked := f_ini.get('gui.autoStartServers', false);
  //
  {$IFDEF VC25_IOCP }
  c_cb_IOCP.checked := f_ini.get('socks.useIOCP', true);	// use IOCP by default
  //
  listenServer.useIOCPSocketsModel := c_cb_IOCP.checked;
  {$ELSE }
  c_cb_IOCP.visible := false;
  {$ENDIF VC25_IOCP }
  //
  if (c_cb_activateOnStart.checked) then
    a_srv_start.execute();
  //
  c_timer_update.enabled := true;
end;

// --  --
procedure Tc_form_main.c_timer_updateTimer(sender: tObject);
var
  running: bool;
  index: int;
  i: unsigned;
  count: int;
  ip, port: string;
begin
  if (not (csDestroying in componentState)) then begin
    //
{$IFDEF DEBUG }
    c_clb_debug.checked[0] := speakServer.active;
    c_clb_debug.checked[1] := listenServer.active;
    //
    c_statusBar_main.panels[0].text := 'Mem: ' + int2str(ams() shr 10, 10, 3) + ' KB';
{$ENDIF DEBUG }
    //
    if (0 < speakServer.clientCount) then
      c_label_received.caption := 'Received  : ' + int2str(speakServer.inPacketsCount, 10, 3) + ' packets.'
    else
      if (speakServer.active) then
	c_label_received.caption := 'Waiting for data stream..'
      else
	c_label_received.caption := 'Speaker server is off.';
    //
    if (listenServer.active) then
      c_label_listeners.caption := 'Listeners : ' + int2str(listenServer.clientCount) + '/' + int2str(listenServer.maxClients)
    else
      c_label_listeners.caption := 'Listeners server is off.';
    //
    c_label_served.caption    := 'Served    : ' + int2str(listenServer.inBytes[0], 10, 3) + ' bytes.';
    //
    running := speakServer.active;
    a_srv_start.enabled := not running;
    c_edit_speakPort.enabled := not running;
    c_comboBox_speakProto.enabled := not running;
    c_cb_IOCP.enabled := not running;
    //
    if (running) then
      a_accept_speaker.enabled := (0 < speakServer.clientCount)
    else
      a_accept_speaker.enabled := false;
    //
    a_srv_stop.enabled := running and listenServer.active;
    running := listenServer.active;
    c_edit_listenPort.enabled := not running;
    c_comboBox_listenProto.enabled := not running;
    //
    c_comboBox_listener.enabled := running;
    if (running) then
      a_accept_listener.enabled := (0 <= c_comboBox_listener.itemIndex)
    else
      a_accept_listener.enabled := false;

    //
    if (f_needSpeakerRefresh) then begin
      //
      f_needSpeakerRefresh := false;
      //
      a_accept_speaker.checked := (0 <> (speakServer.clientOptions[0] and c_unaIPServer_co_inbound));
    end;
    //
    if (f_needListenerRefresh) then begin
      //
      f_needListenerRefresh := false;
      //
      index := c_comboBox_listener.itemIndex;
      c_comboBox_listener.clear();
      if (0 < listenServer.clientCount) then begin
	//
	for i := 0 to listenServer.clientCount - 1 do begin
	  //
	  // get client IP/port
	  if (listenServer.getHostInfo(ip, port, listenServer.getClientConnId(i))) then
	    //
	    c_comboBox_listener.items.Add('Listener #' + int2str(i) + ' / ' + string(ip) + ':' + string(port))
	  else
	    c_comboBox_listener.items.Add('Listener #' + int2str(i) + ' / Unknown IP');
	end;
      end;
      //
      count := c_comboBox_listener.items.count;
      if (index >= count) then
	c_comboBox_listener.itemIndex := count - 1
      else begin
	//
	if (0 > index) then begin
	  //
	  if (1 > count) then
	    c_comboBox_listener.itemIndex := -1
	  else
	    c_comboBox_listener.itemIndex := 0
	end
	else
	  c_comboBox_listener.itemIndex := index;
      end;
      //
      c_comboBox_listenerChange(sender);
    end;
  end;
end;

// --  --
procedure Tc_form_main.a_srv_startExecute(sender: tObject);
begin
  a_srv_start.enabled := false;
  //
  speakServer.proto := tunavclProtoType(choice(0 = c_comboBox_speakProto.ItemIndex, ord(unapt_UDP), ord(unapt_TCP)));
  listenServer.proto := tunavclProtoType(choice(0 = c_comboBox_listenProto.ItemIndex, ord(unapt_UDP), ord(unapt_TCP)));
  //
  speakServer.port := c_edit_speakPort.text;
  listenServer.port := c_edit_listenPort.text;
  //
  speakServer.open();
end;

// --  --
procedure Tc_form_main.a_srv_stopExecute(sender: tObject);
begin
  a_srv_stop.enabled := false;
  //
  speakServer.close();
  //
  f_needListenerRefresh := true;
end;

// --  --
procedure Tc_form_main.a_accept_speakerExecute(Sender: TObject);
var
  options: unsigned;
begin
  // toggle accept speaker stream
  options := speakServer.clientOptions[0];
  if (0 <> (options and c_unaIPServer_co_inbound)) then
    options := options and (not c_unaIPServer_co_inbound)
  else
    options := options or c_unaIPServer_co_inbound;
  //
  speakServer.clientOptions[0] := options;
  //
  a_accept_speaker.checked := (0 <> (options and c_unaIPServer_co_inbound));
end;

// --  --
procedure Tc_form_main.About1Click(Sender: TObject);
begin
  shellExecute(handle, 'open', 'http://lakeofsoft.com/vc/a_onetomanystreaming.html', nil, nil, SW_SHOWNORMAL);
end;

// --  --
procedure Tc_form_main.a_accept_listenerExecute(Sender: TObject);
var
  index: int;
  options: unsigned;
begin
  index := c_comboBox_listener.itemIndex;
  //
  if (0 <= index) then begin
    //
    // toggle allow listener stream
    options := listenServer.clientOptions[index];
    if (0 <> (options and c_unaIPServer_co_outbound)) then
      options := options and (not c_unaIPServer_co_outbound)
    else
      options := options or c_unaIPServer_co_outbound;
    //
    listenServer.clientOptions[index] := options;
    //
    a_accept_listener.checked := (0 <> (options and c_unaIPServer_co_outbound));
  end;
end;

// --  --
procedure Tc_form_main.speakServerServerNewClient(sender: TObject; connectionId: Cardinal; connected: LongBool);
begin
  f_needSpeakerRefresh := true;
end;

// --   --
procedure Tc_form_main.listenServerServerNewClient(sender: TObject; connectionId: Cardinal; connected: LongBool);
begin
  f_needListenerRefresh := true;
end;

// --   --
procedure Tc_form_main.listenServerServerClientDisconnect(sender: TObject; connectionId: Cardinal; connected: LongBool);
begin
  f_needListenerRefresh := true;
end;

// --  --
procedure Tc_form_main.c_comboBox_listenerChange(Sender: TObject);
begin
  if (0 <= c_comboBox_listener.itemIndex) then
    a_accept_listener.checked := (0 <> (listenServer.clientOptions[c_comboBox_listener.itemIndex] and c_unaIPServer_co_outbound))
  else
    a_accept_listener.checked := false;
end;

// --  --
procedure Tc_form_main.Exit1Click(Sender: TObject);
begin
  close();
end;

// --  --
procedure Tc_form_main.c_cb_IOCPClick(Sender: TObject);
begin
{$IFDEF VC25_IOCP }
  listenServer.useIOCPSocketsModel := c_cb_IOCP.checked;
{$ENDIF VC25_IOCP }
end;


end.

