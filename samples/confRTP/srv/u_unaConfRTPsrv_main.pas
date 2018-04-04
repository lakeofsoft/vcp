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

	  u_unaConfRTPsrv_main.pas
	  unaConfRTPsrv demo application - main form source

	----------------------------------------------
	  Copyright (c) 2009-2011 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, Feb 2010

	  modified by:
		Lake, Feb-Dec 2010
		Lake, Jan-Apr 2011

	----------------------------------------------
*)

{$I unaDef.inc }

unit
  u_unaConfRTPsrv_main;

interface

uses
  Windows, unaTypes, unaClasses, unaConfRTP, unaConfRTPserver,
  Forms, Classes, ActnList, Menus, ExtCtrls, Controls, ComCtrls, StdCtrls,
  unaVC_pipe;

type
  Tc_form_main = class(TForm)
    c_sb_main: TStatusBar;
    c_timer_update: TTimer;
    c_mm_main: TMainMenu;
    mi_file_root: TMenuItem;
    mi_file_exit: TMenuItem;
    mi_help_root: TMenuItem;
    mi_help_about: TMenuItem;
    mi_edit: TMenuItem;
    c_al_main: TActionList;
    c_button_stop: TButton;
    c_button_start: TButton;
    a_srv_start: TAction;
    a_srv_stop: TAction;
    c_panel_bottom: TPanel;
    c_lv_rooms: TListView;
    c_splitter_right: TSplitter;
    c_panel_bright: TPanel;
    c_lv_cln: TListView;
    c_cb_okIN: TCheckBox;
    c_cb_okOUT: TCheckBox;
    c_button_kick: TButton;
    a_cln_kick: TAction;
    a_cln_toggleIN: TAction;
    a_cln_toggleOut: TAction;
    c_label_clnInfo: TLabel;
    c_memo_log: TMemo;
    c_splitter_bottom: TSplitter;
    c_label_srvStatus: TLabel;
    c_pm_rooms: TPopupMenu;
    a_room_shutdown: TAction;
    a_room_startup: TAction;
    Startup1: TMenuItem;
    Shutdown1: TMenuItem;
    a_srv_params: TAction;
    EditServerParameters1: TMenuItem;
    srv: TunaConfRTPserver;
    N1: TMenuItem;
    Announce1: TMenuItem;
    a_room_announce: TAction;
    Button1: TButton;
    //
    procedure formCreate(sender: tObject);
    procedure formDestroy(sender: tObject);
    procedure formShow(sender: tObject);
    procedure formCloseQuery(sender: tObject; var canClose: boolean);
    //
    procedure c_timer_updateTimer(sender: tObject);
    //
    procedure c_lv_clnChange(sender: tObject; item: tListItem; change: tItemChange);
    procedure c_lv_roomsChange(sender: tObject; item: tListItem; change: tItemChange);
    //
    procedure mi_help_aboutClick(sender: tObject);
    procedure mi_file_exitClick(sender: tObject);
    //
    procedure a_room_shutdownExecute(sender: tObject);
    procedure a_room_startupExecute(sender: tObject);
    procedure a_room_announceExecute(Sender: TObject);
    //
    procedure a_srv_startExecute(sender: tObject);
    procedure a_srv_stopExecute(sender: tObject);
    procedure a_srv_paramsExecute(sender: tObject);
    //
    procedure a_cln_kickExecute(sender: tObject);
    procedure a_cln_toggleINExecute(sender: tObject);
    procedure a_cln_toggleOutExecute(sender: tObject);
    //
    procedure srvUserVerify(sender: tObject; userID, roomID: integer; const IP, port: string; var accept: longBool);
    procedure srvUserConnect(sender: tObject; userID, roomID: integer; const IP, port: string; isConnected: longBool);
    procedure srvRoomAddRemove(sender: tObject; roomID: integer; doAdd: longBool);
  private
    { Private declarations }
    f_config: unaIniFile;
    //
    f_lastRoomIndex: int;
    f_log: unaStringList;
    f_addRooms: unaList;
    f_removeRooms: unaList;
    f_selfCheck: bool;
    //
    procedure addLog(const item: string);
    //
    function addRoom(roomID: int): bool;
    function removeRoom(roomID: int): bool;
    //
    procedure udpateSrvParams();
    procedure updateStatus();
    procedure beforeClose();
    //
    procedure updateRooms(var bwIn, bwOut: int);
    procedure updateRoomClients();
  public
    { Public declarations }
  end;

var
  c_form_main: Tc_form_main;


implementation


{$R *.dfm}

uses
  unaUtils, unaVCLUtils, unaSockets, unaSocks_RTP,
  u_unaConfRTPsrv_srvConfig;


{ Tc_form_main }

// --  --
procedure Tc_form_main.addLog(const item: string);
var
  time: SYSTEMTIME;
begin
  time := utc2local(nowUTC());
  c_memo_log.lines.add(sysTime2str(@time) + ': ' + item);
  //
  {$IFDEF DEBUG }
  logMessage(item);	// dublicate to debug log file
  {$ENDIF DEBUG }
  //
  if (100 < c_memo_log.lines.count) then begin
    //
    c_memo_log.lines.delete(0);
    c_memo_log.SelStart := length(c_memo_log.text);
    c_memo_log.SelLength := 0;
  end;
end;

// --  --
function bps2str(value: int): string;
begin
  if (value shr 3 < 1024) then
    result := adjust(int2str(value shr  3, 10, 3), 5) + ' B/s'
  else
    result := adjust(int2str(value shr 13, 10, 3), 5) + ' KiB/s';
end;

// --  --
function Tc_form_main.addRoom(roomID: int): bool;
var
  i: int;
  item: tListItem;
begin
  result := true;
  //
  // check if we already have room with same ID
  //
  for i := 0 to c_lv_rooms.items.count - 1 do begin
    //
    if (roomID = int32(c_lv_rooms.items[i].data)) then begin
      //
      result := false;
      //
      //guiMessageBox('Room with same ID <' + int2str(roomID) + '> already exists.', 'Error', MB_OK or MB_ICONERROR);
      break;
    end;
  end;
  //
  if (result) then begin
    //
    item := c_lv_rooms.items.add();
    item.data := pointer(roomID);
    item.caption := int2str(roomID);
    item.subItems.add(srv.roomGetName(roomID));	// #0 name
    item.subItems.add('0');			// #1 num clients
    item.subItems.add(bps2str(0));		// #2 bandwidth in
    item.subItems.add(bps2str(0));		// #3 bandwidth out
    //
    if (f_config.get('room(' + int2str(roomID) + ').closed', false)) then
      srv.roomShutdown(roomID);
  end;
end;

// -- kick client --
procedure Tc_form_main.a_cln_kickExecute(sender: tObject);
begin
  if (nil <> c_lv_cln.selected) then
    srv.userDrop(unsigned(c_lv_cln.selected.data));	// drop by userID
end;

// -- toggle client IN --
procedure Tc_form_main.a_cln_toggleINExecute(sender: tObject);
var
  user: unaConfRTProomUser;
begin
  if (not f_selfCheck and (nil <> c_lv_cln.selected)) then begin
    //
    user := srv.userByIDAcquire(u_int32(c_lv_cln.selected.data));
    if (nil <> user) then try
      //
      user.allowIN := c_cb_okIN.checked;
    finally
      user.releaseRO();
    end;
  end;
end;

// -- toggle client OUT --
procedure Tc_form_main.a_cln_toggleOutExecute(sender: tObject);
var
  user: unaConfRTProomUser;
begin
  if (not f_selfCheck and (nil <> c_lv_cln.selected)) then begin
    //
    user := srv.userByIDAcquire(u_int32(c_lv_cln.selected.data));
    if (nil <> user) then try
      //
      user.allowOUT := c_cb_okOUT.checked;
    finally
      user.releaseRO();
    end;
  end;
end;

// --  --
procedure Tc_form_main.a_room_announceExecute(Sender: TObject);
var
  roomID: int;
  room: unaConfRTProom;
begin
  if (nil <> c_lv_rooms.selected) then begin
    //
    roomID := int(c_lv_rooms.selected.data);
    room := srv.roomByIDAcquire(roomID);
    if (nil <> room) then try
      // send some important announce to all clients in this room
      room.announce('Hi from server, getting bored...');
    finally
      room.releaseRO();
    end;
  end;
end;

// --  --
procedure Tc_form_main.a_room_shutdownExecute(sender: tObject);
var
  roomID: int;
begin
  if (nil <> c_lv_rooms.selected) then begin
    //
    roomID := int(c_lv_rooms.selected.data);
    if (SUCCEEDED(srv.roomShutdown(roomID))) then
      // remember room's state
      f_config.setValue('room(' + int2str(roomID) + ').closed', true);
  end;
end;

// --  --
procedure Tc_form_main.a_room_startupExecute(sender: tObject);
var
  roomID: int;
begin
  if (nil <> c_lv_rooms.selected) then begin
    //
    roomID := int(c_lv_rooms.selected.data);
    if (SUCCEEDED(srv.roomStartup(roomID))) then
      // remember room's state
      f_config.setValue('room(' + int2str(roomID) + ').closed', false);
  end;
end;

//
// -- edit server params --
//
procedure Tc_form_main.a_srv_paramsExecute(Sender: TObject);
begin
  if (c_form_params.editParams(f_config)) then
    udpateSrvParams();
end;

//
// -- start the server --
//
procedure Tc_form_main.a_srv_startExecute(sender: tObject);
begin
  a_srv_start.enabled := false;
  //
  c_lv_clnChange(self, nil, ctState);
  //
  // assign port number
  srv.port := f_config.get('ip.port', '5004');
  srv.bind2ip := f_config.get('ip.bind2ip', '0.0.0.0');
  srv.serverName := f_config.get('srv.name', '<Untitled>');
  //
  // open the server
  if (srv.open()) then begin
    //
    a_srv_stop.enabled := true;
    //
    addLog('Server started on port ' + srv.port + ' SSRC=' + int2str(srv.SSRC));
  end
  else begin
    //
    a_srv_start.enabled := true;
    //
    addLog('Server failed to start on port ' + srv.port + '; error code=' + int2str(srv.errorCode));
  end;
  //
  a_srv_params.enabled := a_srv_start.enabled;
end;

//
// -- stop the server --
//
procedure Tc_form_main.a_srv_stopExecute(sender: tObject);
begin
  a_srv_stop.enabled := false;
  //
  srv.close();
  //
  a_srv_start.enabled := true;
  a_srv_params.enabled := true;
  //
  addLog('Server stopped.');
end;

// --  --
procedure Tc_form_main.beforeClose();
begin
  c_timer_update.enabled := false;
  //
  a_srv_stop.execute();
  //
  saveControlPosition(self, f_config);
end;

// --  --
procedure Tc_form_main.formCreate(sender: tObject);
begin
  f_config := unaIniFile.create();
  f_log := unaStringList.create();
  f_addRooms := unaList.create();
  f_removeRooms := unaList.create();
end;

// --  --
procedure Tc_form_main.formDestroy(sender: tObject);
begin
  freeAndNil(f_config);
  freeAndNil(f_log);
  freeAndNil(f_addRooms);
  freeAndNil(f_removeRooms);
end;

// --  --
procedure Tc_form_main.formShow(sender: tObject);
begin
  loadControlPosition(self, f_config);
  //
  udpateSrvParams();	// load server properties from ini storage (especially, masterkey)
  //
  a_srv_stop.enabled := false;
  a_room_shutdown.enabled := false;
  a_room_startup.enabled := false;
  a_room_announce.enabled := false;
  //
  if (f_config.get('srv.autostart', false)) then
    a_srv_start.execute();
  //
  c_lv_clnChange(self, nil, ctState);
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
  guiMessageBox(handle, 'RTP Conference Server sample'#13#10'(c) 2010-2011 Lake of Soft', 'About');
end;

// --  --
function Tc_form_main.removeRoom(roomID: int): bool;
var
  i: int;
begin
  result := false;
  //
  i := 0;
  while (i < c_lv_rooms.items.count) do begin
    //
    if (int(c_lv_rooms.items[i].data) = roomID) then begin
      //
      c_lv_rooms.items.delete(i);
      result := true;
      //
      break;
    end;
    //
    inc(i);
  end;
end;

// --  --
procedure Tc_form_main.srvRoomAddRemove(sender: TObject; roomID: Integer; doAdd: LongBool);
var
  s: string;
  room: unaConfRTProom;
begin
  room := srv.roomByIDAcquire(roomID);
  if (nil <> room) then try
    s := int2str(roomID) + '/' + room.roomName
  finally
    room.releaseRO();
  end
  else
    s := int2str(roomID);
  //
  s := 'Room [' + s + '] was ' + choice(doAdd, 'added', 'removed');
  f_log.add(s);
  //
  if (doAdd) then
    f_addRooms.add(roomID)
  else
    f_removeRooms.add(roomID);
end;

// --  --
procedure Tc_form_main.srvUserConnect(sender: tObject; userID, roomID: integer; const IP, port: string; isConnected: longBool);
var
  s: string;
  cname: wString;
begin
  if (not srv.userGetName(u_int32(userID), cname)) then
    cname := '<noname>';
  //
  s := 'Client [' + int2str(u_int32(userID)) + '/' + string(cname) + '] from ' + IP + ':' + port + ' was ' + choice(isConnected, 'connected to', 'disconnected from') + ' room ' + int2str(roomID);
  f_log.add(s);
end;

// -- verify the user --
procedure Tc_form_main.srvUserVerify(sender: tObject; userID, roomID: integer; const IP, port: string; var accept: longBool);
begin
  accept := true;	// allow any user to enter any room
			// modify for custom access
  {$IFDEF DEBUG }
  logMessage('srvUserVerify(): userID=' + int2str(userID) + '; roomID=' + int2str(roomID) + '; IP:port=' + IP + ':' + port + '. Result=' + bool2strStr(accept));
  {$ENDIF DEBUG }
end;

// --  --
procedure Tc_form_main.formCloseQuery(sender: tObject; var canClose: boolean);
begin
  if (canClose) then
    beforeClose();
end;

// --  --
procedure Tc_form_main.udpateSrvParams();
begin
  srv.masterkey := f_config.get('srv.masterpw', 'serverkey');
  srv.autoCreateRooms := f_config.get('srv.autoCreateRooms', true);
  srv.autoRemoveRooms := f_config.get('srv.autoRemoveRooms', true);
  srv.userStrictlyInOneRoom := f_config.get('srv.ustor', true);
end;

// --  --
procedure Tc_form_main.updateRoomClients();
var
  i, c, index: int;
  nv: string;
  cname: wString;
  room: unaConfRTProom;
  cln: unaConfRTProomUser;
  info: rtp_site_info;
  userID: unsigned;
  found: bool;
  sel: bool;
begin
  // 2) update client list for selected room
  if (nil <> c_lv_rooms.selected) then begin
    //
    if (nil = c_lv_cln.selected) then
      c_label_clnInfo.caption := '';
    //
    room := srv.roomByIDAcquire(int(c_lv_rooms.selected.data));
    if (nil <> room) then try
      //
      // 1) update client list
      c_lv_cln.items.beginUpdate();
      try
	// remove all non-existen clients
	i := 0;
	while (i < c_lv_cln.items.count) do begin
	  //
	  if (room.hasUser(u_int32(c_lv_cln.items[i].data))) then
	    inc(i)
	  else
	    c_lv_cln.items.delete(i);
	end;
	//
	// add all clients not in list yet
	//
	for i := 0 to room.userCount - 1 do begin
	  //
	  userID := 0;
	  found := true;
	  //
	  cln := room.userByIndexAcquire(i);
	  if (nil <> cln) then try
	    //
	    userID := cln.userID;
	    found := false;
	    index := -1;
	    //
	    if (not cln.verified) then
	      nv := 'N/V! '
	    else
	      nv := '';
	    //
	    for c := 0 to c_lv_cln.items.count - 1 do begin
	      //
	      if (unsigned(c_lv_cln.items[c].data) = userID) then begin
		//
		c_lv_cln.items[c].subItems[0] := bps2str(cln.bwIn);
		c_lv_cln.items[c].subItems[1] := bps2str(cln.bwOut);
		c_lv_cln.items[c].subItems[4] := pt2str(cln.lastAudioCodec) + '@' + int2str(pt2sps(cln.lastAudioCodec));
		index := c;
		//
		found := true;
		break;
	      end;
	    end;
	    //
	    if (found) then begin
	      //
	      if srv.userGetName(userID, cname) then
		c_lv_cln.items[index].caption := cname
	      else
		c_lv_cln.items[index].caption := '';
	    end;
	    //
	    sel := (nil <> c_lv_cln.selected) and (userID = unsigned(c_lv_cln.selected.data));
	    if (cln.copyRTCPInfo(info)) then begin
	      //
	      if (found) then begin
		//
		c_lv_cln.items[index].subItems[2] := int2str(info.r_stat_received, 10, 3);
		c_lv_cln.items[index].subItems[3] := int2str(info.r_stat_lost);
		c_lv_cln.items[index].subItems[5] := int2str(info.r_rtt) + ' ms';
	      end;
	      //
	      if (found and sel) then begin
		//
		c_label_clnInfo.caption := nv + '[' + int2str(cln.userID) + ']  ' +  int2str(timeElapsed32U(info.r_lastRRreceivedTM) div 1000) + ' s / RTP [' + addr2str(@info.r_remoteAddrRTP) + ']  /  RTCP [' + addr2str(@info.r_remoteAddrRTCP) + ']';
		//
		f_selfCheck := true;
		try
		  c_cb_okIN.checked := cln.allowIN;
		  c_cb_okOUT.checked := cln.allowOUT;
		finally
		  f_selfCheck := false;
		end;
	      end
	    end
	    else begin
	      //
	      if (sel) then
		c_label_clnInfo.caption := nv + 'No info, SSRC=' + int2str(cln.userID);
	    end;
	    //
	  finally
	    cln.releaseRO();
	  end;
	  //
	  // client not found? add to it list
	  if (not found) then begin
	    //
	    with c_lv_cln.items.add() do begin
	      //
	      if (srv.userGetName(userID, cname)) then
		caption := cname;
	      //
	      data := pointer(userID);
	      //
	      subItems.add(bps2str(0)); // #0 bw in
	      subItems.add(bps2str(0)); // #1 bw out
	      subItems.add('0'); 	// #2 pkt received
	      subItems.add('0'); 	// #3 pkt lost
	      subItems.add(''); 	// #4 codec
	      subItems.add(''); 	// #5 RTT
	    end;
	  end;
	  //
	end;
	//
      finally
	c_lv_cln.items.endUpdate();
      end;
    finally
      room.releaseRO();
    end
    else
      if (0 < c_lv_cln.Items.Count) then
        c_lv_cln.items.clear();	// no room -- no clients
  end
  else
    if (0 < c_lv_cln.Items.Count) then
      c_lv_cln.items.clear();
end;

// --  --
procedure Tc_form_main.updateRooms(var bwIn, bwOut: int);
var
  i: int;
  room: unaConfRTProom;
  tm: uint64;
  roomID: int;
begin
  tm := timeMarkU();
  //
  bwIn  := 0;
  bwOut := 0;
  //
  // 1) update room list
  c_lv_rooms.items.beginUpdate();
  try
    i := f_lastRoomIndex;
    while (i < c_lv_rooms.items.count) do begin
      //
      if (c_timer_update.interval shr 2 < timeElapsed64U(tm)) then
	break;
      //
      roomID := int(c_lv_rooms.items[i].data);
      room := srv.roomByIDAcquire(roomID);
      if (nil <> room) then try
	//
	if (room.closed) then begin
	  //
	  c_lv_rooms.items[i].subItems[1] := 'Room is closed.';
	  c_lv_rooms.items[i].subItems[2] := '';
	  c_lv_rooms.items[i].subItems[3] := '';
	end
	else begin
	  //
	  c_lv_rooms.items[i].subItems[1] := int2str(room.userCount);
	  c_lv_rooms.items[i].subItems[2] := bps2str(room.bwIn);
	  c_lv_rooms.items[i].subItems[3] := bps2str(room.bwOut);
	  //
	  inc(bwIn, room.bwIn);
	  inc(bwOut, room.bwOut);
	end;
      finally
	room.releaseRO();
      end
      else begin
	//
	c_lv_rooms.items[i].subItems[1] := 'Room does not exist or is locked.';
	c_lv_rooms.items[i].subItems[2] := '';
	c_lv_rooms.items[i].subItems[3] := '';
      end;
      //
      inc(i);
    end;
    //
    f_lastRoomIndex := i;
    if (c_lv_rooms.items.count <= f_lastRoomIndex) then
      f_lastRoomIndex := 0;
    //
  finally
    c_lv_rooms.items.endUpdate();
  end;
end;

// --  --
procedure Tc_form_main.updateStatus();
var
  st: SYSTEMTIME;
  time: string;
  bwIn, bwOut: int;
begin
  if (not (csDestroying in componentState)) then begin
    //
    while (0 < f_addRooms.count) do begin
      //
      addRoom(int(f_addRooms[0]));
      f_addRooms.removeFromEdge();
    end;
    //
    while (0 < f_removeRooms.count) do begin
      //
      removeRoom(int(f_removeRooms[0]));
      f_removeRooms.removeFromEdge();
    end;
    //
    {$IFDEF DEBUG }
    c_sb_main.panels[0].text := 'Mem: ' + int2str(ams() shr 10, 10, 3) + ' KiB';
    {$ENDIF DEBUG }
    //
    updateRooms(bwIn, bwOut);
    updateRoomClients();
    c_sb_main.panels[1].text := 'IN: '  + bps2str(bwIn);
    c_sb_main.panels[2].text := 'OUT: ' + bps2str(bwOut);
    //
    while (0 < f_log.count) do begin
      //
      addLog(f_log.get(0));
      f_log.removeFromEdge();
    end;
    //
    if ( (nil <> srv.rtcp) and srv.rtcp.timeNTPnow(st) ) then
      time := '< ' + sysTime2str(@st, 'HH:mm:ss', 1024, 0) + ' UTC >'
    else
      time := '';
    //
    c_label_srvStatus.caption := time + ' [' + int2str(srv.ssrc) + '] Port: ' + srv.port + '; Rooms: ' + int2str(srv.roomCount) +  ' / Clients: ' + int2str(srv.userCount) + ' / Trans lost: ' + int2str(srv.lostTrans);
  end;
end;

// --  --
procedure Tc_form_main.c_lv_clnChange(sender: tObject; item: tListItem; change: tItemChange);
var
  ok: bool;
  user: unaConfRTProomUser;
begin
  ok := (nil <> c_lv_cln.selected);
  //
  a_cln_kick.enabled := ok;
  a_cln_toggleIN.enabled := ok;
  a_cln_toggleOUT.enabled := ok;
  //
  if (ok) then begin
    //
    if (nil <> c_lv_rooms.selected) then
      user := srv.userByIDAcquire(u_int32(c_lv_cln.selected.data))
    else
      user := nil;
    //
    if (nil <> user) then try
      //
      a_cln_toggleIN.checked := user.allowIN;
      a_cln_toggleOUT.checked := user.allowOUT;
    finally
      user.releaseRO();
    end
    else
      c_label_clnInfo.caption := '';
  end
  else
    c_label_clnInfo.caption := '';
end;

// --  --
procedure Tc_form_main.c_lv_roomsChange(sender: tObject; item: tListItem; change: tItemChange);
var
  ok: bool;
begin
  ok := (nil <> c_lv_rooms.selected);
  //
  a_room_shutdown.enabled := ok;
  a_room_startup.enabled := ok;
  a_room_announce.enabled := ok;
  //
  if (not ok) then begin
    //
    c_lv_cln.items.clear();
    c_lv_clnChange(self, nil, ctState);
  end;
end;

// --  --
procedure Tc_form_main.c_timer_updateTimer(sender: tObject);
begin
  updateStatus();
end;


end.

