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

	  u_vcIPMultiTrans_main.pas
	  vcIPMultiTrans demo application - main form source

	----------------------------------------------
	  (c) 2012 Lake of Soft
          All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 15 Feb 2012

	  modified by:
		Lake, Feb 2012

	----------------------------------------------
*)

{$I unaDef.inc }

unit
  u_vcIPMultiTrans_main;

interface

uses
  Windows, unaTypes, unaClasses,
  Forms, Menus, ExtCtrls, Classes, Controls, ComCtrls, StdCtrls, unaVC_pipe,
  unaIPStreaming, unaVC_wave, unaVCIDE;


{$IFDEF DEBUG }
  {$DEFINE UNA_LOG_VCMT_MAIN_INFO }
{$ENDIF DEBUG }

type
  Tc_form_main = class(TForm)
    c_sb_main: TStatusBar;
    c_timer_update: TTimer;
    c_mm_main: TMainMenu;
    mi_file_root: TMenuItem;
    mi_file_exit: TMenuItem;
    mi_help_root: TMenuItem;
    mi_help_about: TMenuItem;
    c_edit_uri: TEdit;
    c_label_uri: TLabel;
    trans: TunaIPTransmitter;
    c_button_start: TButton;
    c_button_stop: TButton;
    c_edit_baseDir: TEdit;
    c_label_baseDir: TLabel;
    c_label_listTrans: TLabel;
    c_lv_trans: TListView;
    c_label_tip: TLabel;
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
    //
    procedure transExTransCmd(sender: unavclInOutPipe; udata: Cardinal; cmd: Integer; var data: string);
    procedure c_edit_baseDirChange(Sender: TObject);
    procedure c_button_stopClick(Sender: TObject);
  private
    { Private declarations }
    f_config: unaIniFile;
    //
    f_transmitters: unaIdList;
    f_baseDir: string;
    f_tlUpdateTM: uint64;
    f_killList: unaObjectList;
    //
    procedure updateStatus();
    procedure beforeClose();
    //
    procedure removeTrans(tr: TunaIPTransmitter);
    procedure updateTransList();
    //
    function transBySessionAcq(const session: string; ro: bool = true): TunaIPTransmitter;
    function transByPathAcq(const path: string; ro: bool = true): TunaIPTransmitter;
  public
    { Public declarations }
  end;

var
  c_form_main: Tc_form_main;


implementation


{$R *.dfm}

uses
  unaUtils, unaVCLUtils, unaHash, unaRE;

const
  C_CONTROL	 = 'm1';

type
  /// stream types
  unaTransStreamType = (utst_unknown, utst_file, utst_live, utst_cast);

  {*
	Local transmitters, one per path
  }
  unaTransLocal = class(TunaIPTransmitter)
  private
    f_id: int64;
    f_path: string;
    //
    f_ready: bool;
    f_notReadyTM: uint64;
    //
    f_stype: unaTransStreamType;
    //
    f_wave: TunavclWaveRiff;
    f_live: TunavclWaveInDevice;
    f_cast: TunaIPReceiver;
    //
  protected
    function doOpen(): bool; override;
    function ExTransCmd(cmd: int32; var data: string; udata: uint32 = 0): HRESULT; override;
  public
    constructor createTR(const path: string);
    //
    procedure AfterConstruction(); override;
    procedure BeforeDestruction(); override;
    //
    class function path2id(const path: string): int64;
    //
    property id: int64 read f_id;
    //
    property ready: bool read f_ready write f_ready;
  end;

  {*
	List of transmitters
  }
  unaTransList = class(unaIdList)
  protected
    function getId(item: pointer): int64; override;
  end;


{ unaTransLocal }

// --  --
procedure unaTransLocal.AfterConstruction();
var
  devID: int;
begin
  inherited;
  //
  autoAddDestFromHolePacket := false;	// do not add destination(s) from "hole" packets
  //
  case (f_stype) of

    utst_file: begin
      //
      // MP3 files only for now
      //
      f_wave := TunavclWaveRiff.Create(nil);
      //
      URI := 'rtp://localmp3_' + urlencode(f_path) + '@' + c_form_main.trans.bind2ip + '/';
      //
      // assign mp3 payload
      SDP := 'v=0'#13#10 +
	     'm=audio 0 RTP/AVP 14'#13#10 +
	     'a=rtpmap:14 mpa/' + int2str(f_wave.pcmFormatExt.Format.nSamplesPerSec);
      //
      f_wave.consumer := self;
      f_wave.fileName := addBackSlash(c_form_main.f_baseDir) + f_path;
      f_wave.isFormatProvider := true;
      f_wave.loop := true;
      f_wave.realTime := true;
      //
      doEncode := false;
      frameSize := f_wave.waveStream.mpegFrameSize;
    end;

    utst_live: begin
      //
      // G.722.1 / 48kbps / 32kHz
      //
      devID := str2intInt(rematch(1, f_path, '[0-9]*'), -1);
      URI := 'rtp://locallive_' + int2str(devID) + '@' + c_form_main.trans.bind2ip + '/';
      //
      SDP := 'v=0'#13#10 +
	     'm=audio 0 RTP/AVP 121'#13#10 +
	     'a=rtpmap:121 G7221/32000/1'#13#10 +
	     'a=fmtp:121; bitrate=48';
      //
      f_live := TunavclWaveInDevice.Create(nil);
      f_live.pcm_samplesPerSec := 32000;
      f_live.pcm_numChannels := 1;
      f_live.isFormatProvider := false;
      //
      f_live.deviceId := devID;
      //
      f_live.consumer := self;
      //
      doEncode := true;
    end;

    utst_cast: begin
      //
      // assuming MP3 stream
      //
      URI := 'rtp://castmp3_' + urlencode(f_path) + '@' + c_form_main.trans.bind2ip + '/';
      //
      // assign mp3 payload
      SDP := 'v=0'#13#10 +
	     'm=audio 0 RTP/AVP 14'#13#10 +
	     'a=rtpmap:14 mpa/44100';
      //
      f_cast := TunaIPReceiver.Create(nil);
      //
      f_cast.URI := 'http://' + f_path;
      f_cast.doEncode := false;
      f_cast.consumer := self;
      //
      doEncode := false;
      frameSize := 0;	// analyze
    end;

  end;
  //
  //bind2port := '0';	// bind to first available port
  //
  f_notReadyTM := timeMarkU();
  //
  c_form_main.f_transmitters.add(self);
end;

// --  --
procedure unaTransLocal.BeforeDestruction();
begin
  if (nil <> f_wave) then
    f_wave.close();
  //
  if (nil <> f_live) then
    f_live.close();
  //
  if (nil <> f_cast) then
    f_cast.close();
  //
  inherited;
  //
  freeAndNil(f_wave);
  freeAndNil(f_live);
  freeAndNil(f_cast);
end;

// --  --
constructor unaTransLocal.createTR(const path: string);
begin
{$IFDEF UNA_LOG_VCMT_MAIN_INFO }
  logMessage(className + '.createTR() - Path[' + path + ']');
{$ENDIF UNA_LOG_VCMT_MAIN_INFO }
  //
  f_path := trimS(path);
  while ( (1 = pos('/', f_path)) or (1 = pos('\', f_path)) ) do
    delete(f_path, 1, 1);
  //
  f_id := path2id(path);
  //
  if (1 = pos('file/', loCase(f_path))) then
    f_stype := utst_file
  else
    if (1 = pos('live/', loCase(f_path))) then
      f_stype := utst_live
    else
      if (1 = pos('cast/', loCase(f_path))) then
	f_stype := utst_cast
      else
	f_stype := utst_unknown;
  //
  f_path := copy(f_path, 6, maxInt);
  if (utst_file = f_stype) then begin
    //
    // remove any leading ../..\../..
    while ( (1 = pos('/', f_path)) or (1 = pos('\', f_path)) or (1 = pos('.', f_path)) ) do
      delete(f_path, 1, 1);
  end;
  //
  inherited create(nil);
end;

// --  --
function unaTransLocal.doOpen(): bool;
begin
  result := inherited doOpen();
  //
  if (result) then begin
    //
    case (f_stype) of

      utst_file: f_wave.open();
      utst_live: f_live.open();
      utst_cast: f_cast.open();

    end;
  end;
end;

// --  --
function unaTransLocal.ExTransCmd(cmd: int32; var data: string; udata: uint32): HRESULT;
begin
  result := inherited ExTransCmd(cmd, data, udata);
  //
  case (cmd) of

    C_UNA_TRANS_DEST_REMOVE: begin
      //
    {$IFDEF UNA_LOG_VCMT_MAIN_INFO }
      logMessage(className + '.ExTransCmd(C_UNA_TRANS_DEST_REMOVE) - will call master...');
    {$ENDIF UNA_LOG_VCMT_MAIN_INFO }
      //
      c_form_main.transExTransCmd(self, C_UNA_TRANS_DEST_REMOVE, cmd, data);
    end;

  end;
end;

// --  --
class function unaTransLocal.path2id(const path: string): int64;
var
  i: int32;
  d: unaMD5digest;
  patho: string;
begin
  patho := replace(path, '(.*)(/' + C_CONTROL + ')', '\1');
{$IFDEF UNA_LOG_VCMT_MAIN_INFO }
  logMessage(className + '.path2id() - Path[' + path + '] => ' + 'PathO[' + patho + ']');
{$ENDIF UNA_LOG_VCMT_MAIN_INFO }
  //
  md5(aString(loCase(trimS(patho))), d);
  for i := 8 to 15 do
    d[i - 8] := d[i - 8] xor d[i];
  //
  move(d, result, sizeof(result));	// fill ID (8 bytes) with half-xored hash (16 bytes)
end;


{ unaTransList }

// --  --
function unaTransList.getId(item: pointer): int64;
begin
  if (nil <> item) then
    result := unaTransLocal(item).id
  else
    result := -1;
end;


{ Tc_form_main }

// --  --
procedure Tc_form_main.beforeClose();
begin
  trans.close();
  //
  c_timer_update.enabled := false;
  //
  f_config.setValue('rtsp.uri', c_edit_uri.text);
  f_config.setValue('file.base.dir', c_edit_baseDir.text);
  //
  while (0 < f_transmitters.count) do
    removeTrans(f_transmitters[0]);
  //
  f_killList.clear();
  //
  saveControlPosition(self, f_config);
end;

// --  --
procedure Tc_form_main.formCreate(sender: tObject);
begin
  f_config := unaIniFile.create();
  f_transmitters := unaTransList.create(uldt_ptr);
  f_killList := unaObjectList.create();
end;

// --  --
procedure Tc_form_main.formDestroy(sender: tObject);
begin
  freeAndNil(f_config);
  freeAndNil(f_transmitters);
  freeAndNil(f_killList);
end;

// --  --
procedure Tc_form_main.formShow(sender: tObject);
begin
  loadControlPosition(self, f_config);
  //
  c_edit_uri.text := f_config.get('rtsp.uri', c_edit_uri.text);
  c_edit_baseDir.text := f_config.get('file.base.dir', c_edit_baseDir.text);
  //
  f_tlUpdateTM := timeMarkU();
  //
  c_label_tip.caption := c_label_tip.caption + #13#10#13#10 +
    '  rtsp://server/file/file_name.mp3       '#9'=> stream an .mp3 file from base directory'#13#10 +
    '  rtsp://server/live/N                   '#9#9'=> live recording from device N (-1 for default)'#13#10 +
    '  rtsp://server/cast/server[:port]/name  '#9'=> re-stream SHOUTcast/IceCast stream from remote server';
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
  guiMessageBox(handle, 'VC IPMultiTrans Sample 1.0'#13#10'(c) 2012 Lake of Soft', 'About');
end;

// --  --
procedure Tc_form_main.removeTrans(tr: TunaIPTransmitter);
begin
{$IFDEF UNA_LOG_VCMT_MAIN_INFO }
  logMessage(className + '.removeTrans() - ');
{$ENDIF UNA_LOG_VCMT_MAIN_INFO }
  //
  f_transmitters.removeItem(tr);
  //
  if (f_killList.acquire(false, 102)) then try
    //
    if (0 > f_killList.indexOf(tr)) then
      f_killList.add(tr);
  finally
    f_killList.releaseWO();
  end;
end;

// --  --
function Tc_form_main.transBySessionAcq(const session: string; ro: bool): TunaIPTransmitter;
var
  trans: unaTransLocal;
  i: int32;
begin
  result := nil;
  if (lockNonEmptyList_r(f_transmitters, true, 69)) then try
    //
    for i := 0 to f_transmitters.count - 1 do begin
      //
      trans := f_transmitters.get(i);
      if (trans.hasSession(session) and trans.enter(ro)) then begin
	//
	result := trans;
	break;
      end;
    end;
  finally
    unlockListRO(f_transmitters);
  end;
end;

// --  --
function Tc_form_main.transByPathAcq(const path: string; ro: bool): TunaIPTransmitter;
var
  id: int64;
begin
  id := unaTransLocal.path2id(path);
  result := f_transmitters.itemById(id);
  if ((nil <> result) and (not result.enter(ro))) then
    result := nil;
end;

// --  --
procedure Tc_form_main.transExTransCmd(sender: unavclInOutPipe; udata: Cardinal; cmd: Integer; var data: string);
var
  tr: TunaIPTransmitter;
  session, path, destURL: string;
  okRemove: bool;
begin
  case (cmd) of

    C_UNA_TRANS_PREPARE: begin	/// prepare & open transmitter
				///   udata 		= c_ips_socket_UDP_unicast/c_ips_socket_UDP_multicast
				///   data 	IN 	= local_resource_path
				///		OUT	= local_RTP_port + '-' + local_RTCP_port
      //
    {$IFDEF UNA_LOG_VCMT_MAIN_INFO }
      logMessage(className + '.ExTransCmd(C_UNA_TRANS_PREPARE) - path=<' + data + '>');
    {$ENDIF UNA_LOG_VCMT_MAIN_INFO }
      //
      // see if we already has trans for this url
      tr := transByPathAcq(data);
      if (nil = tr) then begin
	//
	tr := unaTransLocal.createTR(data);
	tr.enter(true);
      end;
      //
      try
	if (not unaTransLocal(tr).ready) then begin
	  //
	  tr.open();
	  unaTransLocal(tr).ready := true;
	  unaTransLocal(tr).f_notReadyTM := timeMarkU();
	end;
	//
	if ((nil <> tr.transRoot) and (nil <> tr.transRoot.receiver) and (nil <> tr.transRoot.receiver.rtcp)) then
	  data := tr.transRoot.receiver.portLocal + '-' + tr.transRoot.receiver.rtcp.bind2port
	else
	  data := '5004-5005';	// fallback to defaul ports
	//
      finally
	tr.leaveRO();
      end;
    end;

    {
    C_UNA_TRANS_REMOVE: begin	/// destroy transmitter
				///   data 	IN 	= <not used>
				///		OUT	= <not used>
      //
      id := -1;
      tr := transByUrlAcq(url);
      if (nil <> tr) then try
	//
	id := unaTransLocal(tr).id;
	unaTransLocal(tr).ready := false;
      finally
	tr.leaveRO();
      end;
      //
      if (0 <= id) then
	f_transmitters.removeById(id);
    end;
    }

    C_UNA_TRANS_GET_SDP: begin	/// get SDP from transmitter
				///   data 	IN 	= local_resource_path
				///		OUT	= SDP for transmitter assigned to local path
      //
    {$IFDEF UNA_LOG_VCMT_MAIN_INFO }
      logMessage(className + '.ExTransCmd(C_UNA_TRANS_GET_SDP) - path=<' + data + '>');
    {$ENDIF UNA_LOG_VCMT_MAIN_INFO }
      //
      if (0 > f_transmitters.indexOfId( unaTransLocal.path2id(data) )) then
	unaTransLocal.createTR(data);
      //
      tr := transByPathAcq(data);
      if (nil <> tr) then try
	//
	data := tr.SDP + #13#10 +
	'a=control:' + C_CONTROL;
      finally
	tr.leaveRO();
      end
      else
	data := trans.SDP;	// fallback to "main" transmitter's SDP
    end;

    C_UNA_TRANS_DEST_ADD: begin	/// add destination for transmitter
				///   udata	 	= recSSRC
				///   data 	IN 	= '*' + local_resource_path + '*' + session + '*' + destURI
				///		OUT	= <not used>
      //
      path := replace(data, C_RE_URL_SESSION_DEST, '\1');
      session := replace(data, C_RE_URL_SESSION_DEST, '\2');
      //
    {$IFDEF UNA_LOG_VCMT_MAIN_INFO }
      logMessage(className + '.ExTransCmd(C_UNA_TRANS_DEST_ADD) - path=<' + path + '>; session=<' + session + '>; dest=<' + replace(data, C_RE_URL_SESSION_DEST, '\3') + '>');
    {$ENDIF UNA_LOG_VCMT_MAIN_INFO }
      //
      tr := transByPathAcq(path);
      if (nil <> tr) then try
	//
	destURL := replace(data, C_RE_URL_SESSION_DEST, '\3');
	tr.destAdd(false, destURL, false, session, udata);
      finally
	tr.leaveRO();
      end;
    end;

    C_UNA_TRANS_DEST_REMOVE: begin	/// remove destination from transmitter
					///   data 	IN 	= session
					///		OUT	= <not used>
      //
    {$IFDEF UNA_LOG_VCMT_MAIN_INFO }
      logMessage(className + '.ExTransCmd(C_UNA_TRANS_DEST_REMOVE) - session=<' + data + '>');
    {$ENDIF UNA_LOG_VCMT_MAIN_INFO }
      //
      okRemove := false;
      tr := transBySessionAcq(data);
      if (nil <> tr) then try
	//
	tr.destRemove('', data);
	okRemove := (0 > tr.destCount);
	unaTransLocal(tr).ready := not okRemove;
      finally
	tr.leaveRO();
      end;
      //
      // remove transmitter when no more sessions/destinations
      if (okRemove) then
	removeTrans(tr);
    end;

    C_UNA_TRANS_DEST_PAUSE,
    C_UNA_TRANS_DEST_PLAY: begin    /// pauses streaming to dest
				     ///   data 	IN 	= session
				     ///		OUT	= <not used>
      //
    {$IFDEF UNA_LOG_VCMT_MAIN_INFO }
      logMessage(className + '.ExTransCmd(C_UNA_TRANS_DEST_PAUSE/PLAY) - session=<' + data + '>');
    {$ENDIF UNA_LOG_VCMT_MAIN_INFO }
      //
      tr := transBySessionAcq(data);
      if (nil <> tr) then try
	tr.destEnable('', data, C_UNA_TRANS_DEST_PLAY = cmd);
      finally
	tr.leaveRO();
      end;
    end;

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
begin
  if (not (csDestroying in componentState)) then begin
    //
    {$IFDEF DEBUG }
    c_sb_main.panels[0].text := 'Mem: ' + int2str(ams() shr 10, 10, 3) + ' KB';
    {$ENDIF DEBUG }
    //
    c_button_start.enabled := not trans.active;
    c_button_stop.enabled := not c_button_start.enabled;
    //
    updateTransList();
  end;
end;

// --  --
function stype2str(stype: unaTransStreamType): string;
begin
  case (stype) of

    utst_file	: result := 'file';
    utst_live	: result := 'live';
    utst_cast	: result := 'cast';
    utst_unknown: result := 'unknown';
    else
		  result := 'unrecognized';
  end;
end;

// --  --
procedure Tc_form_main.updateTransList();
var
  trans: unaTransLocal;
  sess: unaIPTransRTSPSession;
  i, d: int32;
  item: TListItem;
  vs: string;
  bw: int;
  badTrans: TunaIPTransmitter;
begin
  bw := 0;
  if (1100 < timeElapsedU(f_tlUpdateTM)) then begin
    //
    f_killList.clear();
    //
    badTrans := nil;
    if (lockNonEmptyList_r(f_transmitters, true, 19)) then try
      //
      for i := 0 to f_transmitters.count - 1 do begin
	//
	trans := f_transmitters.get(i);
	if ((nil <> trans) and trans.ready and trans.enter(true)) then try
	  //
	  if (c_lv_trans.items.count <= i) then begin
	    //
	    item := c_lv_trans.items.Add();
	    item.subItems.Add('');
	    item.subItems.Add('');
	    item.subItems.Add('');
	    item.subItems.Add('');
	  end
	  else
	    item := c_lv_trans.items[i];
	  //
	  vs := '';
	  for d := 0 to trans.destCount - 1 do begin
	    //
	    sess := trans.sessionAcqByIndex(d);
	    if (nil <> sess) then try
	      //
	      vs := vs + sess.session + '<' + sess.destURI + '> ';
	      if (d < trans.destCount - 1) then
		vs := vs + '; ';
	      //
	    finally
	      sess.releaseRO();
	    end;
	  end;
	  //
	  item.caption := trans.URIUserName;
	  item.subItems[2] := int2str(trans.outBandwidth shr 10, 10, 3) + ' kbps';
	  item.subItems[1] := stype2str(trans.f_stype);
	  if (trans.active and (nil <> trans.transRoot) and (0 < trans.destCount) and trans.transRoot.active) then begin
	    //
	    item.subItems[0] := int2str(trans.transRoot._SSRC);
	    item.subItems[3] := '#' + int2str(trans.transRoot.destGetCount()) + ': ' + vs;
	    //
	    trans.f_notReadyTM := timeMarkU();
	  end
	  else begin
	    //
	    item.subItems[3] := '#' + int2str(0) + ': ' + vs;
	    //
	    // ready, but no destinations for too long?
	    if (20000 < timeElapsed64U(trans.f_notReadyTM)) then
	      badTrans := trans;
	  end;
	  //
	  inc(bw, trans.outBandwidth);
	finally
	  trans.leaveRO();
	end
	else
	  // not ready for too long?
	  if ((nil <> trans) and (20000 < timeElapsed64U(trans.f_notReadyTM))) then
	    badTrans := trans;
      end;
      //
      while ((0 < f_transmitters.count) and (c_lv_trans.items.count > f_transmitters.count)) do
	c_lv_trans.items.delete(c_lv_trans.items.count - 1);
      //
    finally
      unlockListRO(f_transmitters);
    end
    else
      if ((1 > f_transmitters.count) and (0 < c_lv_trans.items.Count)) then
	c_lv_trans.items.clear();
    //
    if (nil <> badTrans) then
      removeTrans(badTrans);
  end;
  //
  c_sb_main.panels[1].text := int2str(bw shr 10, 10, 3) + ' kbps';
end;

// --  --
procedure Tc_form_main.c_button_startClick(Sender: TObject);
begin
  trans.URI := c_edit_uri.Text;
  //
  trans.open();
end;

// --  --
procedure Tc_form_main.c_button_stopClick(Sender: TObject);
begin
  trans.close();
  //
  while (0 < f_transmitters.count) do
    removeTrans(f_transmitters[0]);
end;

// --  --
procedure Tc_form_main.c_edit_baseDirChange(Sender: TObject);
begin
  f_baseDir := c_edit_baseDir.text;
end;

// --  --
procedure Tc_form_main.c_timer_updateTimer(sender: tObject);
begin
  updateStatus();
end;


end.

