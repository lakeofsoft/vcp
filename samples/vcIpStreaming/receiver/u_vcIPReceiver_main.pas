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

	  u_vcIPReceiver_main.pas
	  vcIPReceiver demo application - main form source

	----------------------------------------------
	  Copyright (c) 2010-2012 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 08 Feb 2010

	  modified by:
		Lake, Feb-Nov 2010
		Lake, Jan-Aug 2011
		Lake, Nov-Dec 2012

	----------------------------------------------
*)

{$I unaDef.inc }

{*
  @Author Lake
  @Version 2.5.2010.10 [+] SSRC
		       [+] SDP dropdown
  @Version 2.5.2011.01 [*] Change of logic, receiver now pushes hole to access transmitter
  @Version 2.5.2012.11 [*] TCP added
}

unit
  u_vcIPReceiver_main;

interface

uses
  Windows, unaTypes, unaClasses, unaSockets,
  Forms, Menus, ExtCtrls, Classes, Controls, ComCtrls, unaVC_pipe,
  unaIPStreaming, unaMsAcmClasses, unaVC_wave, unaVCIDE, StdCtrls,
  unaDspControls;

type
  Tc_form_main = class(TForm)
    c_sb_main: TStatusBar;
    c_timer_update: TTimer;
    c_mm_main: TMainMenu;
    mi_file_root: TMenuItem;
    mi_file_exit: TMenuItem;
    mi_help_root: TMenuItem;
    mi_help_about: TMenuItem;
    rec: TunaIPReceiver;
    waveOut: TunavclWaveOutDevice;
    c_label_uri: TLabel;
    c_memo_sdp: TMemo;
    c_label_sdp: TLabel;
    c_button_sdp: TButton;
    c_label_format: TLabel;
    c_cb_uri: TComboBox;
    c_button_open: TButton;
    c_button_close: TButton;
    c_label_desc: TLabel;
    c_cb_payload: TComboBox;
    c_label_ssrc: TLabel;
    c_edit_ssrc: TEdit;
    c_cb_timeout: TCheckBox;
    c_label_bindIP: TLabel;
    c_edit_b2ip: TEdit;
    c_label_bindPort: TLabel;
    c_edit_b2port: TEdit;
    c_pb_vol: TProgressBar;
    c_cb_mute: TCheckBox;
    c_cb_device: TComboBox;
    c_cb_cpa: TCheckBox;
    mi_help_URI: TMenuItem;
    mi_help_SDP: TMenuItem;
    N1: TMenuItem;
    c_pb_buffer: TProgressBar;
    c_label_buffer: TLabel;
    c_tb_buffer: TTrackBar;
    c_label_maxBufSize: TLabel;
    c_label_bufSize: TLabel;
    c_tb_volume: TTrackBar;
    c_cb_stream: TComboBox;
    fft: TunadspFFTControl;
    SampleHomepage1: TMenuItem;
    Label1: TLabel;
    c_edit_stun: TEdit;
    est1: TMenuItem;
    mi_test_sendRTCPApp: TMenuItem;
    c_cb_reconnect: TCheckBox;
    c_cb_ignoreLocalIPs: TCheckBox;
    Label3: TLabel;
    c_cb_transport: TComboBox;
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
    //
    procedure c_button_sdpClick(Sender: TObject);
    procedure c_button_openClick(Sender: TObject);
    procedure c_button_closeClick(Sender: TObject);
    procedure c_cb_payloadChange(Sender: TObject);
    procedure c_cb_timeoutClick(Sender: TObject);
    procedure c_cb_muteClick(Sender: TObject);
    procedure c_cb_deviceChange(Sender: TObject);
    procedure mi_help_SDPClick(Sender: TObject);
    procedure mi_help_URIClick(Sender: TObject);
    procedure c_tb_bufferChange(Sender: TObject);
    procedure c_tb_volumeChange(Sender: TObject);
    procedure c_cb_streamDropDown(Sender: TObject);
    procedure c_cb_streamChange(Sender: TObject);
    procedure c_memo_sdpChange(Sender: TObject);
    //
    procedure dummyAcmReq(sender: TObject; req: Cardinal; var acm: unaMsAcm);
    procedure waveOutFeedDone(sender: unavclInOutPipe; data: Pointer; len: Cardinal);
    procedure waveOutFormatChangeAfter(sender, provider: unavclInOutPipe; newFormat: Pointer; len: Cardinal);
    procedure SampleHomepage1Click(Sender: TObject);
    procedure c_cb_uriChange(Sender: TObject);
    procedure mi_test_sendRTCPAppClick(Sender: TObject);
    //
    procedure recText(sender: unavclInOutPipe; const data: PWideChar);
    procedure recRTCPApp(sender: unavclInOutPipe; const params: unaIPStreamOnRTCPAppParams);
    procedure c_cb_transportChange(Sender: TObject);
  private
    { Private declarations }
    f_config: unaIniFile;
    f_logText: unaStringList;
    f_label_statusKeepText: int;
    //
    f_uri: unaURICrack;
    f_uriCracked: bool;
    //
    procedure enableGUI(doEnable: bool);
    procedure applySDP(index: int);
    //
    procedure updateStatus();
    procedure beforeClose();
    //
    function getUriHost(): string;
    function getUriPort(): int;
    procedure crackURI();
  public
    { Public declarations }
    property uriHost: string read getUriHost;
    property uriPort: int read getUriPort;
  end;

var
  c_form_main: Tc_form_main;


implementation


{$R *.dfm}

uses
  unaUtils, WinSock,
  ShellAPI,
  unaMpeg,
  unaVCLUtils, unaVCIDEutils,
  unaSocks_RTP, unaSocks_RTSP;


{ Tc_form_main }

// --  --
function index2role(index: int): c_peer_role;
begin
  case (index) of

    0: result := pr_none;	// UDP
    1: result := pr_active;	// TCP client
    2: result := pr_passive;	// TCP client
    else
       result := pr_holdconn;	// unknown

  end;
end;

// --  --
procedure Tc_form_main.applySDP(index: int);
var
  pt, sps, nch: int;
  sdp: string;
begin
  sdp := index2sdp(index, pt, sps, nch, -1, uriHost, 1, 0 <> c_cb_transport.itemIndex, index2role(c_cb_transport.itemIndex), uriPort);
  if ('' <> sdp) then begin
    //
    c_memo_SDP.text := sdp;
    c_button_SDPClick(self);
  end;
end;

// --  --
procedure Tc_form_main.beforeClose();
begin
  c_timer_update.enabled := false;
  //
  c_button_closeClick(self);
  //
  f_config.setValue('uri', c_cb_uri.text);
  f_config.setValue('SDP.index', c_cb_payload.itemIndex);
  f_config.setValue('SDP.role', c_cb_transport.itemIndex);
  //
  f_config.setValue('ssrc', c_edit_ssrc.text);
  f_config.setValue('rtcp.timeout', c_cb_timeout.checked);
  f_config.setValue('rtp.customPayloadsAware', c_cb_cpa.checked);
  f_config.setValue('rtp.reconnect', c_cb_reconnect.checked);
  f_config.setValue('rtp.ignoreLocalIPs', c_cb_ignoreLocalIPs.checked);
  //
  f_config.setValue('rtp.b2ip', c_edit_b2ip.text);
  //f_config.setValue('rtp.b2port', c_edit_b2port.text);
  f_config.setValue('rtp.stun', c_edit_stun.text);
  //
  f_config.setValue('audio.mute', c_cb_mute.checked);
  f_config.setValue('audio.devIndex', c_cb_device.itemIndex);
  //
  f_config.setValue('audio.bufSize', waveOut.overNum);
  f_config.setValue('audio.volume', c_tb_volume.position);
  //
  saveControlPosition(self, f_config);
end;

// --  --
procedure Tc_form_main.formCreate(sender: tObject);
begin
  f_config := unaIniFile.create();
  c_tb_buffer.Max := min(c_max_wave_headers, c_tb_buffer.Max);
  //
  f_logText := unaStringList.create();
  //
  c_memo_sdp.text := rec.SDP;
  //
  enumWaveDevices(c_cb_device, false);
  //
  c_cb_payload.items.text := getFormatsList();
  //
{$IFDEF __AFTER_D7__ }
  doubleBuffered := True;
{$ENDIF __AFTER_D7__ }
end;

// --  --
procedure Tc_form_main.formDestroy(sender: tObject);
begin
  freeAndNil(f_config);
  freeAndNil(f_logText);
end;

// --  --
procedure Tc_form_main.formShow(sender: tObject);
var
  i: int;
begin
  loadControlPosition(self, f_config);
  //
  c_cb_uri.text := f_config.get('uri', c_cb_uri.text);
  c_cb_uriChange(self);
  //
  c_cb_transport.itemIndex := f_config.get('SDP.role', int(0));
  //
  i := f_config.get('SDP.index', int(0));
  applySDP(i);
  c_cb_payload.itemIndex := i;
  //
  c_edit_ssrc.text := f_config.get('ssrc', c_edit_ssrc.text);
  c_cb_timeout.checked := f_config.get('rtcp.timeout', true);
  c_cb_cpa.checked := f_config.get('rtp.customPayloadsAware', true);
  c_cb_reconnect.checked := f_config.get('rtp.reconnect', true);
  c_cb_ignoreLocalIPs.checked := f_config.get('rtp.ignoreLocalIPs', false);
  //
  c_edit_b2ip.text := f_config.get('rtp.b2ip', c_edit_b2ip.text);
  c_edit_b2port.text := '0';//f_config.get('rtp.b2port', c_edit_b2port.text);
  c_edit_stun.text := f_config.get('rtp.stun', 'stun://avoxum.com');
  //
  c_cb_mute.checked := f_config.get('audio.mute', false);
  //
  c_cb_device.itemIndex := f_config.get('audio.devIndex', int(0));
  //
  waveOut.overNum := f_config.get('audio.bufSize', int(32));
  c_tb_buffer.Position := waveOut.overNum;
  i := f_config.get('audio.volume', int(0));
  waveOut.setVolume100(100 - i);
  c_tb_volume.Position := i;
  //
  c_timer_update.enabled := true;
end;

// --  --
function Tc_form_main.getUriHost(): string;
begin
  crackURI();
  //
  result := f_uri.r_hostName;
end;

// --  --
function Tc_form_main.getUriPort(): int;
begin
  crackURI();
  //
  result := f_uri.r_port;
  //
  if (0 > result) then begin
    //
    if (sameString(f_uri.r_scheme, 'rtp', false)) then
      result := c_RTP_PORT_Default
    else
      if (sameString(f_uri.r_scheme, 'rtsp', false)) then
	result := c_RTSP_PORT_Default
      else
	result := 0;
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
  guiMessageBox(handle, 'IP Receiver 1.2'#13#10'Copyright (c) 2012 Lake of Soft'#13#10#13#10'http://lakeofsoft.com/vc/', 'About');
end;

// --  --
procedure Tc_form_main.mi_help_SDPClick(Sender: TObject);
begin
  shellExecute(handle, 'open', 'http://lakeofsoft.com/vc/a_ipstreamingsdpsamples.html', nil, nil, SW_SHOWNORMAL);
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
  ssrc: u_int32;
  info: rtp_site_info;
  sinfo: string;
  bs: uint;
begin
  if (not (csDestroying in componentState)) then begin
    //
    {$IFDEF DEBUG }
    c_sb_main.panels[0].text := 'Mem: ' + int2str(ams() shr 10, 10, 3) + ' KB';
    {$ENDIF DEBUG }
    c_sb_main.panels[1].text := int2str(rec.inBandwidth shr 10, 10, 3) + ' kbps';
    //
    sinfo := '';
    if (rec.active and (nil <> rec.rtcp) and rec.rtcp.memberSSRCbyIndex(0, ssrc) and rec.rtcp.copyMember(ssrc, info)) then
      sinfo := 'STAT { rec: ' + int2str(info.r_stat_received, 10, 3) + '  lost: ' + int2str(info.r_stat_lost, 10, 3) + ' (' + int2str(info.r_stat_lostPercent) + '%)' +  ' / jitter: ' + int2str(info.r_jitter) + ' / RTT: ' + int2str(info.r_rtt) + ' ms }';
    //
    c_label_format.caption :=
      int2str(rec.mapping.r_rtpEncoding) + '-[' + mapRtpEncoding2mediaType(rec.mapping.r_rtpEncoding) + ']' +
      ' <' + int2str(rec.mapping.r_samplingRate) + '/' + int2str(rec.mapping.r_numChannels) + '/' + int2str(rec.mapping.r_bitsPerSample) + '> ' + sinfo;
    //
    if (nil <> rec.rec) then
      sinfo := '[' + int2str(rec.rec._SSRC) + ']'#13#10
    else
      sinfo := '';
    //
    if (waveOut.active) then begin
      //
      c_label_desc.caption := WaveOut.device.srcFormatInfo + #13#10 +
	sinfo +
	rec.descriptionInfo;
      //
      if ('' <> rec.descriptionError) then
	c_label_desc.caption := c_label_desc.caption + ' / ' + rec.descriptionError;
    end
    else begin
      //
      if (0 = f_label_statusKeepText) then
	c_label_desc.caption := 'Not active'
      else
        dec(f_label_statusKeepText);
    end;
    //
    if (rec.mpegTS_enabled) then begin
      //
      c_label_desc.caption := 'MPEG TS, PID=' + int2str(rec.mpegTS_PID) + #13#10 + c_label_desc.caption;
      c_cb_stream.enabled := true;
    end;
    //
    c_pb_vol.position := waveOut.getLogVolume();
    //
    bs := waveOut.device.inProgress;
    c_pb_buffer.Position := percent(bs, waveOut.overNum);
    //
    c_label_bufSize.caption := int2str(bs * 1000 div c_defChunksPerSecond) + ' ms';
    c_label_maxBufSize.caption := int2str(waveOut.overNum  * 1000 div c_defChunksPerSecond) + ' ms';
    //
    c_edit_b2port.text := rec.bind2port;
    //
    if (0 < f_logText.count) then begin
      //
      sinfo := f_logText.get(0);
      f_logText.removeFromEdge();
      guiMessageBox(handle, sinfo, 'Info');
    end;
    //
    mi_test_sendRTCPApp.enabled := rec.active;
  end;
end;

// --  --
procedure Tc_form_main.waveOutFeedDone(sender: unavclInOutPipe; data: Pointer; len: Cardinal);
begin
  fft.fft.write(data, len, sender);
end;

// --  --
procedure Tc_form_main.waveOutFormatChangeAfter(sender, provider: unavclInOutPipe; newFormat: Pointer; len: Cardinal);
begin
  fft.fft.fft.setFormat(waveOut.pcm_samplesPerSec, waveOut.pcm_bitsPerSample, waveOut.pcm_numChannels);
end;

// --  --
procedure Tc_form_main.dummyAcmReq(sender: TObject; req: Cardinal; var acm: unaMsAcm);
begin
  // we don't need ACM here, so just do nothing
end;

// --  --
procedure Tc_form_main.mi_help_URIClick(Sender: TObject);
begin
  shellExecute(handle, 'open', 'http://lakeofsoft.com/vc/doc/VCDoc/unaIPStreaming/TunaIPReceiver/URI.html', nil, nil, SW_SHOWNORMAL);
end;

// --  --
procedure Tc_form_main.recRTCPApp(sender: unavclInOutPipe; const params: unaIPStreamOnRTCPAppParams);
begin
  if (c_rtcp_appCmd_RTT <> params.r_cmd) then
    f_logText.add('Got RTCP APP [SSRC=' + int2str(params.r_ssrc) + '] from ' + ipH2str(params.r_fromIP4) + ':' + int2str(params.r_fromPort) + ' [cmd=' + string(params.r_cmd) + '; subtype=' + int2str(params.r_subtype) + '; datalen=' + int2str(params.r_len) + ']');
end;

// --  --
procedure Tc_form_main.recText(sender: unavclInOutPipe; const data: PWideChar);
begin
  f_logText.add('Got some text: <' + string(data) + '>');
end;

// --  --
procedure Tc_form_main.SampleHomepage1Click(Sender: TObject);
begin
  shellExecute(handle, 'open', 'http://lakeofsoft.com/vc/a_rtprec.html', nil, nil, SW_SHOWNORMAL);
end;

// --  --
procedure Tc_form_main.mi_test_sendRTCPAppClick(Sender: TObject);
begin
  rec.sendRTCPApp(0, 'RTST');
end;

// --  --
procedure Tc_form_main.c_tb_volumeChange(Sender: TObject);
begin
  waveOut.setVolume100(100 - c_tb_volume.Position);
end;

// --  --
procedure Tc_form_main.c_button_sdpClick(Sender: TObject);
begin
  rec.sdp := c_memo_sdp.text;
  c_button_sdp.enabled := false;
end;

// --  --
procedure Tc_form_main.c_cb_deviceChange(Sender: TObject);
var
  wa: bool;
begin
  wa := waveOut.active;
  try
    waveOut.deviceId := index2deviceId(c_cb_device);
  finally
    waveOut.active := wa;
  end;
end;

// --  --
procedure Tc_form_main.c_cb_muteClick(Sender: TObject);
begin
  waveOut.enableDataProcessing := not c_cb_mute.checked;
end;

// --  --
procedure Tc_form_main.c_cb_payloadChange(Sender: TObject);
begin
  applySDP(c_cb_payload.itemIndex);
end;

// --  --
function streamType2str(stype: int): string;
begin
  case (stype) of

    // PMT stream types
    c_PMTST_reserved			: result := 'Reserved';
    c_PMTST_MPEG1_video			: result := 'MPEG1 Video';
    c_PMTST_MPEG2_video			: result := 'MPEG2 Video';
    c_PMTST_MPEG1_audio			: result := 'MPEG1 Audio';
    c_PMTST_MPEG2_audio			: result := 'MPEG2 Audio';
    c_PMTST_MPEG2_private		: result := 'MPEG2 Private';
    c_PMTST_MPEG2_PESprivate		: result := 'MPEG2 PESPriv';
    c_PMTST_MHEG			: result := 'MHEG';
    c_PMTST_MPEG2_DSM_CC		: result := 'MPEG2 DSM_CC';
    c_PMTST_H222_1			: result := 'H222.1';
    c_PMTST_MPEG2_6_typeA		: result := 'MPEG2-6 TypeA';
    c_PMTST_MPEG2_6_typeB		: result := 'MPEG2-6 TypeB';
    c_PMTST_MPEG2_6_typeC		: result := 'MPEG2-6 TypeC';
    c_PMTST_MPEG2_6_typeD		: result := 'MPEG2-6 TypeD';
    c_PMTST_MPEG2_aux			: result := 'MPEG2 Aux';
    c_PMTST_MPEG2_ADTS		        : result := 'MPEG2 ADTS';
    c_PMTST_AVC_visual			: result := 'AVC Visual';
    c_PMTST_AVC_audio			: result := 'AVC Audio';
    c_PMTST_AVC_1_pack_PES		: result := 'AVC pack PES';
    c_PMTST_AVC_1_pack			: result := 'AVC pack';
    c_PMTST_MPEG2_SDP			: result := 'MPEG2 SDP';
    c_PMTST_meta_PES    		: result := 'meta PES';
    c_PMTST_meta_meta    		: result := 'meta meta';
    c_PMTST_meta_DC    			: result := 'meta DC';
    c_PMTST_meta_object			: result := 'meta obj';
    c_PMTST_meta_SDP		    	: result := 'meta SDP';
    c_PMTST_MPEG2_IPMP		    	: result := 'MPEG2 IPMP';
    c_PMTST_AVC_H264_video	    	: result := 'AVC H.264';
    c_PMTST_MPEG2_reserved_start..
    c_PMTST_MPEG2_reserved_end		: result := 'MPEG2 res';
    c_PMTST_IPMP			: result := 'IPMP';
    c_PMTST_user_private_start..
    c_PMTST_user_private_end		: result := 'private (' + int2str(stype) + ')';
    else
					  result := 'unknown (' + int2str(stype) + ')';
  end;
end;

// --  --
procedure Tc_form_main.c_cb_streamChange(Sender: TObject);
var
  s: string;
  pc, PID: int;
begin
  // see if we should switch to other PID
  if (rec.mpegTS_enabled) then begin
    //
    s := c_cb_stream.text;
    pc := pos('ES[', s);
    if ((0 <= pc) and (1 < pos('udio', s))) then begin
      //
      PID := str2intInt(copy(s, pc + 3, pos(']', s) - pc - 3), 0);
      if (0 <> PID) then
	rec.mpegTS_PID := PID;
    end;
  end;
end;

// --  --
procedure Tc_form_main.c_cb_streamDropDown(Sender: TObject);
var
  pc, sc, ec: int;
  P: unaMpegTSProgram;
  ES: unaMpegES;
  SRV: unaMpegTSService;
  ok: bool;
  //
  list: string;
begin
  // build mpeg-ts tree (if awailable)
  if (rec.mpegTS_enabled) then begin
    //
    list := '';
    //
    ok := false;
    // have any programs?
    pc := rec.mpegTS_demuxer.programs.count;
    if (0 < pc) then begin
      //
      while (0 < pc) do begin
	//
	dec(pc);
	P := rec.mpegTS_demuxer.programs[pc];
	if (nil <> P) then begin
	  //
	  list := list + 'P[' + int2str(P.ID) + '] ';
	  //
	  // service maybe?
	  SRV := rec.mpegTS_demuxer.services.itemByID(P.ID);
	  if (nil <> SRV) then
	    list := list + SRV.desc.dvalue[c_descTagDVB_service] + ' ';
	  //
	  list := list + #13#10;
	  //
	  // navigate all streams
	  for sc := 0 to P.streams.count - 1 do begin
	    //
	    ES := rec.mpegTS_demuxer.estreams.itemByID( TPID(P.streams[sc]) ) ;
	    if (nil <> ES) then begin
	      //
	      list := list + '   ES[' + int2str(ES.ID) + '] ' + streamType2str(ES.streamType) + ' [' + ES.desc.dvalue[c_descTag_ISO_639_lang] + ']'#13#10;
	      ok := true;
	    end;
	  end;
	end;
      end;
    end;
    //
    if (not ok) then begin
      //
      // ok, try plain ES listing
      for ec := 0 to rec.mpegTS_demuxer.estreams.count - 1 do begin
	//
	ES := rec.mpegTS_demuxer.estreams[ec];
	if (nil <> ES) then
	  list := list + 'ES[' + int2str(ES.ID) + '] ' + streamType2str(ES.streamType) + ' ' + ES.desc.dvalue[c_descTag_ISO_639_lang] + #13#10;
      end;
    end;
    //
    if (('' <> list) and (c_cb_stream.items.text <> list)) then
      c_cb_stream.items.text := list;
  end;
end;

// --  --
procedure Tc_form_main.c_cb_timeoutClick(Sender: TObject);
begin
  if (c_cb_timeout.checked) then
    rec.rtcpTimeoutReports := 6
  else
    rec.rtcpTimeoutReports := 0;	// disable
end;

// --  --
procedure Tc_form_main.c_cb_transportChange(Sender: TObject);
begin
  applySDP(c_cb_payload.itemIndex);
end;

// --  --
procedure Tc_form_main.c_memo_sdpChange(Sender: TObject);
begin
  c_button_sdp.enabled := true;
end;

// --  --
procedure Tc_form_main.crackURI();
begin
  if (not f_uriCracked) then begin
    //
    f_uriCracked := unaSockets.crackURI(c_cb_uri.text, f_uri);
  end;
end;

// --  --
procedure Tc_form_main.c_button_closeClick(Sender: TObject);
begin
  rec.close();
  fft.active := false;
  //
  enableGUI(true);
end;

// --  --
procedure Tc_form_main.c_button_openClick(Sender: TObject);
begin
  enableGUI(false);
  //
  rec.bind2ip := c_edit_b2ip.text;
  //rec.bind2port := c_edit_b2port.text;
  rec.customPayloadAware := c_cb_cpa.checked;
  rec.mpegTS_PID := 0;	// do not play any stream until selected
  rec.STUNserver := c_edit_stun.text;
  //
  rec.ignoreLocalIPs := c_cb_ignoreLocalIPs.checked;
  rec.reconnectIfNoData := c_cb_reconnect.checked;
  //
  c_cb_stream.clear();
  c_cb_stream.items.add('Default program - click to select other stream');
  c_cb_stream.itemIndex := 0;
  c_cb_stream.enabled := false;
  //
  waveOut.enableDataProcessing := not c_cb_mute.checked;
  waveOut.deviceId := index2deviceId(c_cb_device);
  //
  if (c_cb_timeout.checked) then
    rec.rtcpTimeoutReports := 6
  else
    rec.rtcpTimeoutReports := 0;	// disable
  //
  rec._SSRC := str2intInt(c_edit_ssrc.text, 0);
  rec.uri := c_cb_uri.text;
  //
  c_tb_volumeChange(self);
  //
  fft.active := true;
  rec.open();
end;

// --  --
procedure Tc_form_main.c_tb_bufferChange(Sender: TObject);
begin
  waveOut.overNum := c_tb_buffer.Position;
end;

// --  --
procedure Tc_form_main.c_timer_updateTimer(sender: tObject);
begin
  updateStatus();
end;

// --  --
procedure Tc_form_main.enableGUI(doEnable: bool);
begin
  c_label_uri.enabled := doEnable;
  c_memo_sdp.enabled := doEnable;
  c_label_sdp.enabled := doEnable;
  c_button_sdp.enabled := doEnable;
  c_cb_uri.enabled := doEnable;
  c_button_open.enabled := doEnable;
  c_button_close.enabled := not doEnable;
  c_edit_b2ip.enabled := doEnable;
  c_cb_transport.enabled := doEnable;
  //c_edit_b2port.enabled := doEnable;
  c_cb_ignoreLocalIPs.enabled := doEnable;
  c_cb_reconnect.enabled := doEnable;
  c_cb_cpa.enabled := doEnable;
  //
  c_cb_payload.enabled := doEnable;
  c_edit_ssrc.enabled := doEnable;
end;

// --  --
procedure Tc_form_main.c_cb_uriChange(Sender: TObject);
var
  s: string;
begin
  case (c_cb_uri.itemIndex) of

    //-- RAW streaming ---
    1: s:= 'RAW UDP Receiver: bind to this IP:port to receive RAW packets'; // udp://192.168.0.174:7654
    2: s:= 'RAW UDP Receiver: join this multicast group at specified port'; // udp://@238.0.0.56:1234

    //-- RTP streaming --
    5: s:= 'RTP UDP Receiver: bind to this IP (at default port 5004) and wait for RTP packets';  // rtp://0.0.0.0
    6: s:= 'RTP UDP Receiver: send RTP packet to this host at specified port to make a "hole" and start receiving data';  // rtp://avoxum.com:15006
    7: s:= 'RTP UDP Receiver: send RTP packet to this host at specified port to make a "hole" and start receiving data';  // rtp://lakeofsoft.dyndns-server.com:5006
    8: s:= 'RTP UDP Receiver: join this multicast group at specified port to receive RTP packets';  // rtp://224.0.1.2:5004

    //-- RTSP streaming --
    11: s:= 'RTSP Receiver: query remote RTSP server for a file';  // rtsp://avoxum.com:1500/file/song.mp3
    12: s:= 'RTSP Receiver: query remote RTSP server for a file';  // rtsp://avoxum.com:1500/file/song2.mp3
    13: s:= 'RTSP Receiver: query remote RTSP server for a live re-broadcast';  // rtsp://avoxum.com:1500/cast/stream.kissfm.ua:8000/kiss
    14: s:= 'RTSP Receiver: query remote RTSP server for a live re-broadcast';  // rtsp://avoxum.com:1500/cast/85.21.79.93:8040

    // -- SHOUTcast streaming ---
    17: s:= 'SHOUTcast Receiver: query remote SHOUTcast/IceCast server for a live TCP stream';  // http://scfire-dtc-aa02.stream.aol.com:80/stream/1003

  end;
  //
  c_label_desc.caption := s;
  //
  f_label_statusKeepText := 40;	// keep this text for 40 timer ticks
end;


end.

