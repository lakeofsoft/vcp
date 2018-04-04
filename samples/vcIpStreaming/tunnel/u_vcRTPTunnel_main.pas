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

	  u_vcRTPTunnel_main.pas
	  vcRTPTunnel demo application - main form source

	----------------------------------------------
	  Copyright (c) 2010 Lake of Soft
	  All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, Jul 2010

	  modified by:
		Lake, Jul-Oct 2010

	----------------------------------------------
*)

{$I unaDef.inc }

unit
  u_vcRTPTunnel_main;

interface

uses
  Windows, unaTypes, unaClasses, unaRTPTunnel,
  Forms, StdCtrls, Controls, ComCtrls, Menus, ExtCtrls, Classes;

type
  Tc_form_main = class(TForm)
    c_sb_main: TStatusBar;
    c_timer_update: TTimer;
    c_mm_main: TMainMenu;
    mi_file_root: TMenuItem;
    mi_file_exit: TMenuItem;
    mi_help_root: TMenuItem;
    mi_help_about: TMenuItem;
    c_lv_tunnels: TListView;
    c_label_src: TLabel;
    c_edit_srcAddr: TEdit;
    c_label_dst: TLabel;
    c_edit_dstAddr: TEdit;
    c_label_lr: TLabel;
    c_button_add: TButton;
    c_button_remove: TButton;
    c_label_port: TLabel;
    c_label_b2ip: TLabel;
    c_edit_port: TEdit;
    c_edit_b2ip: TEdit;
    c_button_start: TButton;
    c_button_stop: TButton;
    c_label_info: TLabel;
    Label1: TLabel;
    Label2: TLabel;
    c_edit_srcSSRC: TEdit;
    c_edit_dstSSRC: TEdit;
    c_button_update: TButton;
    Label3: TLabel;
    c_rb_addr: TRadioButton;
    c_rb_ssrc: TRadioButton;
    c_memo_log: TMemo;
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
    procedure c_button_startClick(Sender: TObject);
    procedure c_button_stopClick(Sender: TObject);
    procedure c_button_addClick(Sender: TObject);
    procedure c_lv_tunnelsClick(Sender: TObject);
    procedure c_button_removeClick(Sender: TObject);
    procedure c_button_updateClick(Sender: TObject);
  private
    { Private declarations }
    f_config: unaIniFile;
    f_log: unaStringList;
    //
    f_tunnelSrv: unaRTPTunnelServer;
    f_tpIndex: int;
    //
    procedure copyTunnels();
    procedure saveTunnels();
    procedure loadTunnels();
    //
    procedure enableGUI(isActive: bool);
    //
    procedure updateStatus();
    procedure beforeClose();
    procedure onLog(sender: tObject; event, data: int);
  public
    { Public declarations }
  end;

var
  c_form_main: Tc_form_main;


implementation


{$R *.dfm}

uses
  WinSock,
  unaUtils, unaSockets, unaSocks_RTP, unaVCLUtils;


{ Tc_form_main }

// --  --
procedure Tc_form_main.beforeClose();
begin
  c_button_stopClick(self);
  saveTunnels();
  //
  f_config.setValue('srv.port', c_edit_port.text);
  f_config.setValue('srv.b2ip', c_edit_b2ip.text);
  f_config.setValue('src_addr', c_edit_srcAddr.text);
  f_config.setValue('dst_addr', c_edit_dstAddr.text);
  f_config.setValue('src_ssrc', c_edit_srcSSRC.text);
  f_config.setValue('dst_ssrc', c_edit_dstSSRC.text);
  //
  c_timer_update.enabled := false;
  //
  saveControlPosition(self, f_config);
end;

// --  --
procedure Tc_form_main.formCreate(sender: tObject);
begin
  f_config := unaIniFile.create();
  f_log := unaStringList.create();
end;

// --  --
procedure Tc_form_main.formDestroy(sender: tObject);
begin
  freeAndNil(f_config);
  freeAndNil(f_log);
end;

// --  --
procedure Tc_form_main.formShow(sender: tObject);
begin
  loadControlPosition(self, f_config);
  //
  loadTunnels();
  //
  c_edit_port.text := f_config.get('srv.port', c_edit_port.text);
  c_edit_b2ip.text := f_config.get('srv.b2ip', c_edit_b2ip.text);
  c_edit_srcAddr.text := f_config.get('src_addr', c_edit_srcAddr.text);
  c_edit_dstAddr.text := f_config.get('dst_addr', c_edit_dstAddr.text);
  c_edit_srcSSRC.text := f_config.get('src_ssrc', c_edit_srcSSRC.text);
  c_edit_dstSSRC.text := f_config.get('dst_ssrc', c_edit_dstSSRC.text);
  //
  c_rb_addr.checked := true;
  c_rb_ssrc.checked := false;
  //
  c_timer_update.enabled := true;
end;

// --  --
procedure Tc_form_main.loadTunnels();
var
  j, i: int;
  mt: int;
  t: string;
begin
  i := f_config.get('tunnel.count', int(0));
  j := 1;
  while (j <= i) do begin
    //
    t := 'tunnel#' + int2str(j - 1);
    mt := f_config.get(t + '.type', int(0));
    if (0 <> mt) then begin
      //
      with (c_lv_tunnels.items.add()) do begin
	//
	case (mt) of

	  C_MT_ADDR: caption := 'A';
	  C_MT_SSRC: caption := 'S';

	end;
	//
	subItems.add(f_config.get(t + '.src', ''));
	subItems.add('< -- >');
	subItems.add(f_config.get(t + '.dst', ''));
	subItems.add('');
      end;
    end;
    //
    inc(j);
  end;
end;

// --  --
procedure Tc_form_main.mi_file_exitClick(sender: tObject);
begin
  close();
end;

// --  --
procedure Tc_form_main.mi_help_aboutClick(sender: tObject);
begin
  guiMessageBox(handle, 'RTP Tunnel sample 1.0'#13#10'Copyright (c) 2010 Lake of Soft', 'About');
end;

// --  --
function map2str(map: punaTunnelMap): string;
begin
  if (nil <> map) then begin
    //
    case (map.r_mapType) of

      C_MT_ADDR : result := 'ADDR: ' + addr2str(@map.r_src_addr) + ' <-> ' + addr2str(@map.r_dst_addr);
      C_MT_SSRC : result := 'SSRC: ' + int2str(swap32u(map.r_src_ssrc)) + ' <-> ' + int2str(swap32u(map.r_dst_ssrc));

    end;
  end
  else
    result := '<null>';
end;

// --  --
procedure Tc_form_main.onLog(sender: tObject; event, data: int);
var
  log: string;
  map: punaTunnelMap;
begin
  if ((nil <> f_tunnelSrv) and (data >= 0) and (data < f_tunnelSrv.tunnelCount)) then
    map := f_tunnelSrv.tunnel[data]
  else
    map := nil;
  //
  log := '';
  //
  case (event) of

    C_EV_S_STARTED	: log := 'Server was started on port ' + int2str(data);
    C_EV_S_STOPPED	: log := 'Server was stopped.';
    C_EV_T_RESOLVED_SRC	: if (nil <> map) then log := 'Address of source ' + int2str(swap32u(map.r_src_ssrc)) + ' was resolved to ' + addr2str(@map.r_known_src_addr);
    C_EV_T_RESOLVED_DST	: if (nil <> map) then log := 'Address of dest '   + int2str(swap32u(map.r_dst_ssrc)) + ' was resolved to ' + addr2str(@map.r_known_dst_addr);
    C_EV_T_ADDED	: log := 'New tunnel was added, ' + map2str(map);
    C_EV_T_UPDATED	: log := 'Tunnel #' + int2str(data) + ' was updated: ' + map2str(map);
    C_EV_T_REMOVED	: log := 'Tunnel #' + int2str(data) + ' was removed.';
    else
			  log := '<Unknown event (' + int2str(event) + ')>';
  end;
  //
  f_log.add(log);
end;

// --  --
procedure Tc_form_main.saveTunnels();
var
  i: int;
  t: string;
begin
  f_config.setValue('tunnel.count', c_lv_tunnels.items.count);
  for i := 0 to c_lv_tunnels.items.count - 1 do begin
    //
    t := 'tunnel#' + int2str(i);
    f_config.setValue(t + '.type', choice('A' = c_lv_tunnels.items[i].caption, int(C_MT_ADDR), C_MT_SSRC));
    //
    f_config.setValue(t + '.src', c_lv_tunnels.items[i].subItems[0]);
    f_config.setValue(t + '.dst', c_lv_tunnels.items[i].subItems[2]);
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
var
  tm: punaTunnelMap;
begin
  if (not (csDestroying in componentState)) then begin
    //
    {$IFDEF DEBUG }
    c_sb_main.panels[0].text := 'Mem: ' + int2str(ams() shr 10, 10, 3) + ' KiB';
    {$ENDIF DEBUG }
    //
    if (nil = f_tunnelSrv) then
      c_label_info.caption := '<no server>'
    else begin
      //
      c_label_info.caption := int2str(f_tunnelSrv.tunnelCount) + ' tunnel' + choice(1 <> f_tunnelSrv.tunnelCount, 's', '') + ' / ' +
			      'Packets received: ' + int2str(f_tunnelSrv.packetsReceived, 10, 3);
      //
      inc(f_tpIndex);
      if (f_tpIndex >= f_tunnelSrv.tunnelCount) then
	f_tpIndex := 0;
      //
      tm := f_tunnelSrv.tunnel[f_tpIndex];
      if (nil <> tm) then
	c_lv_tunnels.items[f_tpIndex].subItems[3] :=
	  int2str(tm.r_num_packets_src) + '/' +
	  int2str(tm.r_num_packets_dst) + '/' +
	  int2str(tm.r_num_packets_sent);
      //
    end;
    //
    if (0 < f_log.count) then begin
      //
      c_memo_log.lines.add(f_log.get(0));
      f_log.removeFromEdge();
    end;
  end;
end;

// --  --
procedure Tc_form_main.copyTunnels();
var
  i: int;
begin
  for i  := 0 to c_lv_tunnels.items.count - 1 do begin
    //
    if ('A' = c_lv_tunnels.items[i].caption) then
      f_tunnelSrv.addTunnel(c_lv_tunnels.items[i].subItems[0], c_lv_tunnels.items[i].subItems[2])
    else
      f_tunnelSrv.addTunnel(str2intUnsigned(c_lv_tunnels.items[i].subItems[0], 0), str2intUnsigned(c_lv_tunnels.items[i].subItems[2], 0))
  end;
end;

// --  --
procedure Tc_form_main.c_button_addClick(Sender: TObject);
var
  mt: int;
begin
  with (c_lv_tunnels.items.add()) do begin
    //
    mt := choice(c_rb_addr.checked, C_MT_ADDR, int(C_MT_SSRC));
    //
    case (mt) of

      C_MT_ADDR: begin
	//
	caption := 'A';
	subItems.add(c_edit_srcAddr.text);
	subItems.add('< -- >');
	subItems.add(c_edit_dstAddr.text);
      end;

      C_MT_SSRC: begin
	//
	caption := 'S';
	subItems.add(c_edit_srcSSRC.text);
	subItems.add('< -- >');
	subItems.add(c_edit_dstSSRC.text);
      end;

    end;
    subItems.add('');
    //
    if (nil <> f_tunnelSrv) then begin
      //
      if (C_MT_ADDR = mt) then
	f_tunnelSrv.addTunnel(c_edit_srcAddr.text, c_edit_dstAddr.text)
      else
	f_tunnelSrv.addTunnel(str2intUnsigned(c_edit_srcSSRC.text, 0), str2intUnsigned(c_edit_dstSSRC.text, 0))
    end;
  end;
end;

// --  --
procedure Tc_form_main.c_button_removeClick(Sender: TObject);
var
  i: int;
begin
  if (nil <> c_lv_tunnels.selected) then
    i := c_lv_tunnels.selected.index
  else
    i := -1;
  //
  if (0 <= i) then begin
    //
    c_lv_tunnels.items.delete(i);
    if (nil <> f_tunnelSrv) then
      f_tunnelSrv.removeTunnel(i);
    //
    if (i < c_lv_tunnels.items.count) then begin
      //
{$IFDEF _AFTER_D4_}
      c_lv_tunnels.itemIndex := i;
{$ENDIF _AFTER_D4_}
      c_lv_tunnelsClick(self);
    end
    else begin
      //
      c_button_remove.enabled := false;
      c_button_update.enabled := false;
    end;
  end;
end;

// --  --
procedure Tc_form_main.c_button_startClick(Sender: TObject);
var
  addr: TSockAddrIn;
begin
  makeAddr(c_edit_b2ip.text, c_edit_port.text, addr);
  f_tunnelSrv := unaRTPTunnelServer.create(addr, 0, false, false);
  // assuming UNA_RTPTUNNEL_ENABLE_LOG is defined
  f_tunnelSrv.onLogEvent := onLog;
  //
  copyTunnels();
  //
  f_tunnelSrv.open();
  //
  enableGUI(true);
end;

// --  --
procedure Tc_form_main.c_button_stopClick(Sender: TObject);
begin
  freeAndNil(f_tunnelSrv);
  //
  enableGUI(false);
end;

// --  --
procedure Tc_form_main.c_button_updateClick(Sender: TObject);
var
  mt: int;
begin
  if (nil <> c_lv_tunnels.selected) then begin
    //
    mt := choice(c_rb_addr.checked, C_MT_ADDR, int(C_MT_SSRC));
    case (mt) of

      C_MT_ADDR: begin
	//
	c_lv_tunnels.selected.caption := 'A';
	c_lv_tunnels.selected.subItems[0] := c_edit_srcAddr.text;
	c_lv_tunnels.selected.subItems[2] := c_edit_dstAddr.text;
      end;

      C_MT_SSRC: begin
	//
	c_lv_tunnels.selected.caption := 'S';
	c_lv_tunnels.selected.subItems[0] := c_edit_srcSSRC.text;
	c_lv_tunnels.selected.subItems[2] := c_edit_dstSSRC.text;
      end;

    end;
    //
    if (nil <> f_tunnelSrv) then begin
      //
      if (C_MT_ADDR = mt) then
	f_tunnelSrv.updateTunnel(c_lv_tunnels.selected.index, c_edit_srcAddr.text, c_edit_dstAddr.text)
      else
	f_tunnelSrv.updateTunnel(c_lv_tunnels.selected.index, str2intUnsigned(c_edit_srcSSRC.text, 0), str2intUnsigned(c_edit_dstSSRC.text, 0))
    end;
    //
  end;
end;

// --  --
procedure Tc_form_main.c_lv_tunnelsClick(Sender: TObject);
var
  sel: bool;
  mt: int;
begin
  sel := (nil <> c_lv_tunnels.selected);
  c_button_remove.enabled := sel;
  c_button_update.enabled := sel;
  //
  if (sel) then begin
    //
    mt := choice('A' = c_lv_tunnels.selected.caption, C_MT_ADDR, int(C_MT_SSRC));
    case (mt) of

      C_MT_ADDR: begin
	//
	c_edit_srcAddr.text := c_lv_tunnels.selected.subItems[0];
	c_edit_dstAddr.text := c_lv_tunnels.selected.subItems[2];
	c_rb_addr.checked := true;
      end;

      C_MT_SSRC: begin
	//
	c_edit_srcSSRC.text := c_lv_tunnels.selected.subItems[0];
	c_edit_dstSSRC.text := c_lv_tunnels.selected.subItems[2];
	c_rb_ssrc.checked := true;
      end;

    end;
  end;
end;

// --  --
procedure Tc_form_main.c_timer_updateTimer(sender: tObject);
begin
  updateStatus();
end;

// --  --
procedure Tc_form_main.enableGUI(isActive: bool);
begin
  c_button_stop.enabled := isActive;
  c_button_start.enabled := not isActive;
  //
  c_edit_port.enabled := not isActive;
  c_edit_b2ip.enabled := not isActive;
end;


end.

