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

	  u_unaConfRTPcln_main.pas
	  unaConfRTPcln demo application - main form source

	----------------------------------------------
	  Copyright (c) 2009-2011 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, Feb 2010

	  modified by:
		Lake, Feb-Dec 2010
		Lake, Jan-Aug 2012

	----------------------------------------------
*)

{$I unaDef.inc }

unit
  u_unaConfRTPcln_main;

interface

uses
  Windows, Forms,
  unaTypes, unaClasses, unaConfRTP, unaConfRTPclient, unaVC_wave,
  unaVCIDE, unaVC_pipe,
  Classes, ActnList, Menus, ExtCtrls, ComCtrls, StdCtrls, Controls;

type
  Tc_form_main = class(TForm)
    c_sb_main: TStatusBar;
    c_timer_update: TTimer;
    c_mm_main: TMainMenu;
    mi_file_root: TMenuItem;
    mi_file_exit: TMenuItem;
    mi_help_root: TMenuItem;
    mi_help_about: TMenuItem;
    c_edit_srvName: TEdit;
    c_label_srvName: TLabel;
    c_edit_srvPort: TEdit;
    c_label_srvPort: TLabel;
    c_edit_userName: TEdit;
    c_label_userID: TLabel;
    c_edit_roomName: TEdit;
    c_label_roomID: TLabel;
    c_label_roomKey: TLabel;
    c_button_connect: TButton;
    c_button_disconnect: TButton;
    c_ac_main: TActionList;
    a_cln_connect: TAction;
    a_cln_disconnect: TAction;
    mi_client: TMenuItem;
    Connect1: TMenuItem;
    Disconnect1: TMenuItem;
    c_edit_srvKey: TEdit;
    c_cb_micON: TCheckBox;
    c_cb_playbackON: TCheckBox;
    c_tb_micVol: TTrackBar;
    c_tb_playbackVol: TTrackBar;
    c_label_clientStatus: TLabel;
    waveIn: TunavclWaveInDevice;
    waveOut: TunavclWaveOutDevice;
    c_cb_source: TComboBox;
    c_cb_dest: TComboBox;
    c_pb_in: TProgressBar;
    c_pb_out: TProgressBar;
    cln: TunaConfRTPclient;
    c_cb_sps: TComboBox;
    Label5: TLabel;
    c_cb_codec: TComboBox;
    c_cb_vad: TCheckBox;
    c_cb_speexVAD: TCheckBox;
    c_cb_speexNS: TCheckBox;
    c_cb_speexAGC: TCheckBox;
    c_cb_speexAEC: TCheckBox;
    c_panel_bottom: TPanel;
    c_memo_log: TMemo;
    c_lv_streams: TListView;
    Splitter1: TSplitter;
    c_cb_rot: TCheckBox;
    Label1: TLabel;
    c_label_cln_RTP_info: TLabel;
    Button1: TButton;
    a_cln_roomJoin: TAction;
    waveFile: TunavclWaveRiff;
    Button2: TButton;
    a_cln_roomLeave: TAction;
    //
    procedure formCreate(sender: tObject);
    procedure formDestroy(sender: tObject);
    procedure formShow(sender: tObject);
    procedure formCloseQuery(sender: tObject; var canClose: boolean);
    //
    procedure c_timer_updateTimer(sender: tObject);
    //
    procedure mi_help_aboutClick(sender: tObject);
    procedure mi_file_exitClick(sender: tObject);
    //
    procedure a_cln_connectExecute(sender: tObject);
    procedure a_cln_disconnectExecute(sender: tObject);
    //
    procedure c_cb_micONClick(sender: tObject);
    procedure c_cb_playbackONClick(sender: tObject);
    procedure c_cb_vadClick(Sender: TObject);
    procedure c_cb_speexVADClick(Sender: TObject);
    procedure c_cb_speexNSClick(Sender: TObject);
    procedure c_cb_speexAGCClick(Sender: TObject);
    procedure c_cb_speexAECClick(Sender: TObject);
    //
    procedure c_cb_spsChange(Sender: TObject);
    procedure c_cb_codecChange(Sender: TObject);
    //
    procedure c_tb_micVolChange(sender: tObject);
    procedure c_tb_playbackVolChange(sender: tObject);
    //
    procedure clnConnect(sender: tObject; userID: integer);
    procedure clnDisconnect(sender: tObject; userID: integer);
    //
    procedure waveOutFeedDone(sender: unavclInOutPipe; data: pointer; len: Cardinal);
    procedure a_cln_roomJoinExecute(Sender: TObject);
    procedure c_edit_roomNameChange(Sender: TObject);
    procedure a_cln_roomLeaveExecute(Sender: TObject);
  private
    { Private declarations }
    f_config: unaIniFile;
    f_log: unaStringList;
    f_reconnectTM: uint64;
    f_lastError: int;
    f_lv_chReady: bool;
    //
    f_caption: string;
    //
    f_audioSrc: int; 	// 1 = file, 2 = waveIn
    //
    procedure updateStatus();
    procedure beforeClose();
    //
    procedure addLog(const item: string);
    procedure applyRateCodec(index: int = -1; isps: int = -1);
    //
  {$IFDEF __AFTER_DB__ }
    procedure c_lv_streamsItemChecked(sender: tObject; item: tListItem);
  {$ENDIF __AFTER_DB__ }
  public
    { Public declarations }
  end;

var
  c_form_main: Tc_form_main;


implementation


{$R *.dfm}

uses
  Graphics, unaUtils, unaMsAcmClasses, unaSocks_RTP,
  unaVCLUtils, unaVCIDEUtils;


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
    logMessage(item);	// dublicate to log file
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
procedure Tc_form_main.a_cln_connectExecute(sender: tObject);
var
  p: int;
begin
  a_cln_connect.enabled := false;
// TODO: a_cln_roomLeave.enabled := true;
  //
  f_lastError := 1000;
  //
  waveFile.close();
  waveIn.close();
  //
  waveOut.deviceId := index2deviceId(c_cb_dest);
  //
  f_audioSrc := 0;	// none
  //
  p := pos('file://', loCase(c_cb_source.text));
  if (1 = p) then begin
    //
    waveFile.fileName := copy(c_cb_source.text, p + 7, maxInt);
    if (0 = waveFile.waveStream.status) then begin
      //
      applyRateCodec(2, 32000);	// assuming file is MP3 @ 32kHz
      //
      c_cb_codec.enabled := false;
      c_cb_sps.enabled := false;
      //
      cln.audioSrcIsPCM := false;
      cln.frameSize := waveFile.waveStream.mpegFrameSize;
      //
      f_audioSrc := 1;
    end;
  end;
  //
  if (0 = f_audioSrc) then begin
    //
    waveIn.deviceId := index2deviceId(c_cb_source);
    applyRateCodec();
    //
    cln.audioSrcIsPCM := true;
    //
    f_audioSrc := 2;
  end;
  //
  c_edit_userName.enabled := false;
  //
  cln.dsp_ns := c_cb_speexNS.checked;
  cln.dsp_agc := c_cb_speexAGC.checked;
  cln.dsp_vad := c_cb_speexVAD.checked;
  cln.dsp_aec := c_cb_speexAEC.checked;
  //
  cln.srvMasterkey := c_edit_srvKey.text;
  //
  // assign URI and open
  cln.connect(c_edit_userName.text, c_edit_roomName.text, c_edit_srvName.text, c_edit_srvPort.text);
  //
  a_cln_disconnect.enabled := true;
  //
  f_reconnectTM := timeMarkU();
end;

// --  --
procedure Tc_form_main.a_cln_disconnectExecute(sender: tObject);
begin
  f_reconnectTM := 0;
  //
  a_cln_disconnect.enabled := false;
  c_cb_codec.enabled := true;
  c_cb_sps.enabled := true;
  c_edit_userName.enabled := true;
  //
  cln.close();
  //
  a_cln_connect.enabled := true;
  a_cln_roomJoin.enabled := false;
  a_cln_roomLeave.enabled := false;
end;

// --  --
procedure Tc_form_main.a_cln_roomJoinExecute(Sender: TObject);
begin
  // join another room
  cln.roomJoin(c_edit_roomName.text);
end;

procedure Tc_form_main.a_cln_roomLeaveExecute(Sender: TObject);
begin
  // leave some room
  cln.roomLeave(c_edit_roomName.text);
end;

// --  --
procedure Tc_form_main.beforeClose();
begin
  c_timer_update.enabled := false;
  //
  waveIn.close();
  waveIn.consumer := nil;
  //
  a_cln_disconnect.execute();
  //
  f_config.setValue('srv.name', c_edit_srvName.text);
  f_config.setValue('srv.port', c_edit_srvPort.text);
  f_config.setValue('srv.key', c_edit_srvKey.text);
  //
  f_config.setValue('user.ID', c_edit_userName.text);
  f_config.setValue('room.ID', c_edit_roomName.text);
  //
  f_config.setValue('cln.micON', c_cb_micON.checked);
  f_config.setValue('cln.playbackON', c_cb_playbackON.checked);
  //
  f_config.setValue('cln.micVol', c_tb_micVol.position);
  f_config.setValue('cln.playbackVol', c_tb_playbackVol.position);
  //
  if (0 > c_cb_source.itemIndex) then
    f_audioSrc := 1;	// assume file name is specified
  //
  f_config.setValue('wave.src', f_audioSrc);
  if (1 = f_audioSrc) then
    f_config.setValue('waveFile.name', c_cb_source.text)
  else
    f_config.setValue('waveIn.index', c_cb_source.itemIndex);
  //
  f_config.setValue('waveOut.index', c_cb_dest.itemIndex);
  //
  f_config.setValue('client.sps', c_cb_sps.itemIndex);
  f_config.setValue('client.codec', c_cb_codec.itemIndex);
  //
  f_config.setValue('wave.VAD', c_cb_vad.checked);
  //
  f_config.setValue('speexdsp.VAD', c_cb_speexVAD.checked);
  f_config.setValue('speexdsp.NS', c_cb_speexNS.checked);
  f_config.setValue('speexdsp.AGC', c_cb_speexAGC.checked);
  f_config.setValue('speexdsp.AEC', c_cb_speexAEC.checked);
  //
  saveControlPosition(self, f_config);
end;

// --  --
procedure Tc_form_main.applyRateCodec(index, isps: int);
var
  sps, enc: int;
begin
  if (0 > isps) then
    sps := str2intInt(c_cb_sps.text, c_confRTPcln_mixer_sps)
  else
    sps := isps;
  //
  if (0 > index) then
    index := c_cb_codec.itemIndex;
  //
  case (index) of

    0: enc := c_rtp_enc_CELT;
    1: enc := c_rtp_enc_speex;
    2: enc := c_rtp_enc_MPA;
    3: enc := c_rtp_enc_PCMA;
    4: enc := c_rtp_enc_PCMU;
    5: enc := c_rtp_enc_L16;
    6: enc := c_rtp_enc_G7221;
    else
       enc := c_rtp_enc_speex;

  end;
  //
  cln.setEncoding(enc, sps);
end;

// --  --
procedure Tc_form_main.c_cb_vadClick(Sender: TObject);
begin
  if ((2 = f_audioSrc) and c_cb_vad.checked) then
    waveIn.silenceDetectionMode := unasdm_3GPPVAD1
  else
    waveIn.silenceDetectionMode := unasdm_none;
end;

// --  --
procedure Tc_form_main.c_edit_roomNameChange(Sender: TObject);
begin
  a_cln_roomJoin.enabled := cln.connected;
end;


{$IFDEF __AFTER_DB__ }

// --  --
procedure Tc_form_main.c_lv_streamsItemChecked(sender: tObject; item: tListItem);
var
  chi: punaConfChannelInfo;
begin
  if (f_lv_chReady and (nil <> item)) then begin
    //
    chi := cln.channelInfo[item.index];
    if (nil <> chi) then
      chi.r_muted := not item.checked;
    //
  end;
end;

{$ENDIF __AFTER_DB__ }

// --  --
procedure Tc_form_main.formCreate(sender: tObject);
begin
  f_config := unaIniFile.create();
  {$IFDEF __AFTER_DB__ }
    c_lv_streams.onItemChecked := c_lv_streamsItemChecked;
  {$ENDIF __AFTER_DB__ }
  //
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
var
  i: int;
begin
  loadControlPosition(self, f_config);
  //
  a_cln_disconnect.enabled := false;
  a_cln_roomLeave.enabled := false;
  //
  f_caption := caption;
  //
  c_edit_srvName.text := f_config.get('srv.name', '192.168.0.174');
  c_edit_srvPort.text := f_config.get('srv.port', '5004');
  c_edit_srvKey.text := f_config.get('srv.key', '***');
  //
  c_edit_userName.text := f_config.get('user.ID', 'testuser');
  c_edit_roomName.text := f_config.get('room.ID', 'testroom');
  //
  c_cb_micON.checked := f_config.get('cln.micon', false);
  c_cb_micONClick(self);
  c_cb_playbackON.checked := f_config.get('cln.playbackON', true);
  c_cb_playbackONClick(self);
  //
  c_tb_micVol.position := f_config.get('cln.micVol', int(0));
  c_tb_micVolChange(self);
  c_tb_playbackVol.position := f_config.get('cln.playbackVol', int(0));
  c_tb_playbackVolChange(self);
  //
  enumWaveDevices(c_cb_source);
  enumWaveDevices(c_cb_dest, false);
  //
  c_cb_source.itemIndex := f_config.get('waveIn.index', int(0));
  if ((0 > c_cb_source.itemIndex) or (1 = f_config.get('wave.src', int(2)))) then
    c_cb_source.text := f_config.get('waveFile.name', 'file://');
  //
  c_cb_dest.itemIndex := f_config.get('waveOut.index', int(0));
  //
  c_cb_sps.itemIndex := f_config.get('client.sps', int(1));
  c_cb_codec.itemIndex := f_config.get('client.codec', int(0));
  //
  c_cb_vad.checked := f_config.get('wave.VAD', true);
  c_cb_vadClick(self);
  //
  c_cb_speexVAD.checked := f_config.get('speexdsp.VAD', false);
  c_cb_speexNS.checked := f_config.get('speexdsp.NS', true);
  c_cb_speexAGC.checked := f_config.get('speexdsp.AGC', true);
  c_cb_speexAEC.checked := false;  //f_config.get('speexdsp.AEC', true);
  //
  waveOut.pcm_samplesPerSec := c_confRTPcln_mixer_sps;
  //
  case (int(cln.error)) of

    -12: addLog('Speex encoder was not found. Make sure libspeex.dll is installed on your system.');
    -13: addLog('MPEG decoder was not found. Make sure libmpg123-0.dll is installed on your system.');
    -14: begin
      //
      addLog('Speex DSP library was not found. Make sure libspeexdsp.dll is installed on your system.');
      //
      c_cb_speexVAD.enabled := false;
      c_cb_speexNS.enabled := false;
      c_cb_speexAGC.enabled := false;
      c_cb_speexAEC.enabled := false;
    end;
    -15: addLog('MPEG encoder was not found. Make sure lame_enc.dll is installed on your system.');
    -16: addLog('CELT encoder/decoder was not found. Make sure libcelt.dll is installed on your system.');
    -17: addLog('G.722.1 encoder/decoder initializion fail.');

  end;
  //
  for i := 0 to c_max_audioStreams_per_room - 1 do begin
    //
    with c_lv_streams.items.add() do begin
      //
      caption := '';
      subItems.add('');	// buf
      subItems.add('');	// vol
      subItems.add('');	// codec
      subItems.add('');	// rtt
    end;
  end;
  //
  f_lv_chReady := true;
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
  guiMessageBox(handle, 'VC 2.5 RTP Conference Client sample'#13#10'(c) 2012 Lake of Soft', 'About');
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
  s: string;
  stat: unaConfClientConnStat;
  i, cs: int;
  si: rtp_site_info;
  chi: punaConfChannelInfo;
  hasCname: bool;
  cname: wString;
begin
  if (not (csDestroying in componentState)) then begin
    //
    {$IFDEF DEBUG }
      c_sb_main.panels[0].text := 'Mem: ' + int2str(ams() shr 10, 10, 3) + ' KiB';
    {$ENDIF DEBUG }
    //
    if (cln.connected) then begin
      //
      case (cln.getConnectStatus(stat)) of

	3: begin
	  //
	  s := int2str(cln.srvSSRC) + ': ' + cln.srvCNAME + ' /  timeout=' + int2str(stat.r_timeLeft div 1000) + ' / RTT=' + int2str(stat.r_serverRTT) + ' ms';
	  //
	  if (stat.r_announceFresh^) then begin
	    //
	    stat.r_announceFresh^ := false;
	    addLog(stat.r_announce);
	  end;
	  //
	  if ((nil <> c_lv_streams.selected) and (nil <> cln.trans.rtcp)) then begin
	    //
	    if (cln.trans.rtcp.copyMember(cln.getInStreamSSRC(c_lv_streams.selected.index), si)) then begin
	      //
	      c_label_cln_RTP_info.caption :=
		'SSRC: '    + int2str(si.r_ssrc) + '; ' +
		'# max/cycl/base: '  + int2str(si.r_max_seq) +
		'/' + int2str(si.r_cycles) +
		'/' + int2str(si.r_base_seq) + '; ' +
		//'bad_sq: '  + int2str(si.r_bad_seq) + '; ' +
		//'rec: '     + int2str(si.r_received) + '; ' +
		//'transit: ' + int2str(si.r_transit) + '; ' +
		//'jit: '     + int2str(si.r_jitter) + '; ' +
		'rec: ' + int2str(si.r_stat_received) + '; ' +
		'lost: ' + int2str(si.r_stat_lost) + ' (' + int2str(si.r_stat_lostPercent) + '%); ' +
		'RTT: '     + int2str(si.r_rtt) + ' ms' +
		'';
	    end
	    else
	      c_label_cln_RTP_info.caption := '';
	  end
	  else
	    c_label_cln_RTP_info.caption := '';
	end;

      end;
      //
      c_lv_streams.items.beginUpdate();
      try
	//
	for i := 0 to c_max_audioStreams_per_room - 1 do begin
	  //
	  hasCname := cln.getRemoteName(cln.getInStreamSSRC(i), cname);
	  if (hasCname) then begin
	    //
	    c_lv_streams.items[i].caption := cname;
	    c_lv_streams.items[i].subItems[1] := int2str(cln.mixer.streamVolume[i]);
	    c_lv_streams.items[i].subItems[0] := adjust(int2str(cln.mixer.getStream(i).getAvailableSize()), 5, '0') + '/' + int2str(cln.mixer.oob[i]);
	    //
	    chi := cln.channelInfo[i];
	    if (nil <> chi) then begin
	      //
	      f_lv_chReady := false; try
		c_lv_streams.items[i].checked := not chi.r_muted;
	      finally f_lv_chReady := true end;
	      //
	      c_lv_streams.items[i].subItems[2] := pt2str(chi.r_payload) + '@' + int2str(pt2sps(chi.r_payload));
	    end;
	    //
	    c_lv_streams.items[i].subItems[3] := int2str(chi.r_rtt) + ' ms';
	  end
	  else begin
	    //
	    f_lv_chReady := false; try
	      c_lv_streams.items[i].checked := false;
	    finally f_lv_chReady := true end;
	    //
	    c_lv_streams.items[i].caption := '';
	    c_lv_streams.items[i].subItems[0] := '';
	    c_lv_streams.items[i].subItems[1] := '';
	    c_lv_streams.items[i].subItems[2] := '';
	    c_lv_streams.items[i].subItems[3] := '';
	  end;
	end;
      finally
	c_lv_streams.items.endUpdate();
      end;
      //
      c_pb_in.position := cln.getMicVolume();
      c_pb_out.position := cln.getPlaybackVolume();
      //
      caption := f_caption + ' :'  + int2str(cln.SSRC);
    end
    else begin
      //
      c_pb_in.position := 0;
      c_pb_out.position := 0;
      //
      cs := cln.getConnectStatus(stat);
      case (cs) of

	0: s := 'Disconnected';
	1,
	4: s := 'Contacting server, timeout in ' + int2str(stat.r_timeLeft div 1000) + ' sec';
	2: s := 'Server found, joining the room..';
	3: s := 'Joined the room';

	-2: begin
	  //
	  s := 'Server does not allow to join the room, reason: ';
	  case (int(cln.error)) of

	    c_confSrvError_accessDenied    	: s := s + 'access denied';
	    c_confSrvError_roomClosed      	: s := s + 'room is closed';
	    c_confSrvError_userKicked      	: s := s + 'kicked from server';
	    c_confSrvError_outOfSeats      	: s := s + 'room is out of seats';
	    c_confSrvError_roomDoesNotExist	: s := s + 'room does not exist';
	    c_confSrvError_pleaseTryAgain	: s := s + 'server seems to be busy now, please try again in a few seconds';
	    c_confSrvError_noSuchUserID	   	: s := s + 'no such user [' + cln.userName + '/' + int2str(unsigned(cln.errorDataInt)) + ']';
	    c_confSrvError_malformedData   	: s := s + 'malformed request (old client version?)';
	    c_confSrvError_invalidPassword 	: s := s + 'invalid password';
	    c_confSrvError_suchUserFromWrongAddr: s := s + 'same client from different address exists';
	    c_confSrvError_userObjLocked	: s := s + 'user object is locket, please try again later';
	    else
						  s := s + 'Unknown (' + int2str(cln.error) + ')';

	  end;
	end;

	-4: s := 'Server timeout';
	-5: s := 'Disconnected by server request';
	-6: s := 'Disconnected by user request';
	-7: s := 'Server data format error';
	-8: s := 'Internal socket error';
	-9: s := 'Server is down or unreachable';

	else
	   s := 'Unknown (' + int2str(cs) + ')';

      end;
      //
      if (0 > cs) then
	caption := f_caption;
      //
      if ((0 > cs) and (f_lastError <> cs)) then begin
	//
	f_lastError := cs;
	addLog(s);
      end;
      //
      if ((0 > cs) and a_cln_disconnect.enabled) then begin
	//
	a_cln_connect.enabled := true;
	a_cln_disconnect.enabled := false;
	a_cln_roomLeave.enabled := false;
	//
	c_cb_codec.enabled := true;
	c_cb_sps.enabled := true;
	c_edit_userName.enabled := true;
	//
	f_reconnectTM := timeMarkU();
      end;
      //
      if (not a_cln_disconnect.enabled and c_cb_rot.checked and (0 <> f_reconnectTM)) then begin
	//
	if (18000 < timeElapsed64U(f_reconnectTM)) then
	  a_cln_connect.execute()
	else
	  s := 'Reconnect in ' + int2str((18000 - timeElapsed64U(f_reconnectTM)) div 1000) + ' sec';
      end;
    end;
    //
    if (0 < f_log.count) then begin
      //
      addLog(f_log.get(0));
      f_log.removeFromEdge();
    end;
    //
    c_label_clientStatus.caption := s;
    //
    c_sb_main.Panels[1].Text := 'IN: ' + int2str(cln.bw_in shr 3, 10, 3) + ' B/s  OUT: ' + int2str(cln.bw_out shr 3, 10, 3) + ' B/s';
    c_sb_main.Panels[2].Text := 'WO: ' + int2str(waveOut.device.inOverloadTotal shr 10, 10, 3) + ' KiB';
  end;
end;

// --  --
procedure Tc_form_main.waveOutFeedDone(sender: unavclInOutPipe; data: pointer; len: Cardinal);
begin
{$IFDEF DEBUG }
  try
{$ENDIF DEBUG }
    cln.feedOut(data, len, waveOut.device.inProgress * waveOut.chunkSize);
{$IFDEF DEBUG }
  except
  end;
{$ENDIF DEBUG }
end;

// --  --
procedure Tc_form_main.clnConnect(sender: tObject; userID: integer);
begin
  if (not (csDestroying in componentState)) then begin
    //
    // time to start streaming
    case (f_audioSrc) of

      1: begin
	//
	waveFile.consumer := cln;
	waveFile.open();
      end;

      2: begin
        //
	waveIn.consumer := cln;
	waveIn.open();
      end;

    end;
    //
    f_log.add('Connected to server');
  end;
end;

// --  --
procedure Tc_form_main.clnDisconnect(sender: tObject; userID: integer);
begin
  if (not (csDestroying in componentState)) then begin
    //
    waveIn.close();
    waveIn.consumer := nil;
    //
    waveFile.close();
    waveFile.consumer := nil;
    //
    f_log.add('Disconnected from server');
  end;
end;

// --  --
procedure Tc_form_main.c_cb_codecChange(Sender: TObject);
begin
  applyRateCodec();
end;

// --  --
procedure Tc_form_main.c_cb_micONClick(sender: tObject);
begin
  cln.recordingEnabled := c_cb_micON.checked;
end;

// --  --
procedure Tc_form_main.c_cb_playbackONClick(sender: tObject);
begin
  cln.playbackEnabled := c_cb_playbackON.checked;
end;

// --  --
procedure Tc_form_main.c_cb_speexAECClick(Sender: TObject);
begin
  cln.dsp_aec := c_cb_speexAEC.checked;
end;

// --  --
procedure Tc_form_main.c_cb_speexAGCClick(Sender: TObject);
begin
  cln.dsp_agc := c_cb_speexAGC.checked;
end;

// --  --
procedure Tc_form_main.c_cb_speexNSClick(Sender: TObject);
begin
  cln.dsp_ns := c_cb_speexNS.checked;
end;

// --  --
procedure Tc_form_main.c_cb_speexVADClick(Sender: TObject);
begin
  cln.dsp_vad := c_cb_speexVAD.checked;
end;

// --  --
procedure Tc_form_main.c_cb_spsChange(Sender: TObject);
begin
  applyRateCodec();
end;

// --  --
procedure Tc_form_main.c_tb_micVolChange(sender: tObject);
begin
  cln.recordingLevel := c_tb_micVol.max - c_tb_micVol.position;
end;

// --  --
procedure Tc_form_main.c_tb_playbackVolChange(sender: tObject);
begin
  cln.playbackLevel := c_tb_playbackVol.max - c_tb_playbackVol.position;
end;

// --  --
procedure Tc_form_main.c_timer_updateTimer(sender: tObject);
begin
  updateStatus();
end;


end.

