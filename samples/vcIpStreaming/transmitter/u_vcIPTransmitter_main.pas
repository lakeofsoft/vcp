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

	  u_vcIPTransmitter_main.pas
	  vcIPTransmitter demo application - main form source

	----------------------------------------------
	  Copyright (c) 2010-2012 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 08 Feb 2010

	  modified by:
		Lake, Feb-Dec 2010
		Lake, Nov-Dec 2012

	----------------------------------------------
*)

{*
  @Author Lake

  @Version 2.5.2012.11 [*] TCP added
}

{$I unaDef.inc }

unit
  u_vcIPTransmitter_main;

interface

uses
  Windows, unaTypes, unaClasses, unaSockets,
  Forms, Menus, ExtCtrls, Classes, Controls, ComCtrls, unaVC_pipe,
  unaIPStreaming, unaMsAcmClasses, unaVC_wave, unaVCIDE, StdCtrls, Dialogs,
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
    trans: TunaIPTransmitter;
    c_cb_uri: TComboBox;
    c_label_uri: TLabel;
    c_label_sdp: TLabel;
    c_button_sdp: TButton;
    c_button_open: TButton;
    c_button_close: TButton;
    c_memo_sdp: TMemo;
    waveIn: TunavclWaveInDevice;
    waveRiff: TunavclWaveRiff;
    c_edit_file: TEdit;
    c_button_browse: TButton;
    c_od_file: TOpenDialog;
    c_cb_file: TCheckBox;
    Label1: TLabel;
    c_edit_ssrc: TEdit;
    c_cb_payload: TComboBox;
    c_cb_VAD: TCheckBox;
    c_cb_timeout: TCheckBox;
    c_bevel_top: TBevel;
    c_pb_vol: TProgressBar;
    c_label_status: TLabel;
    c_cb_mute: TCheckBox;
    c_cb_device: TComboBox;
    Label2: TLabel;
    mi_help_URI: TMenuItem;
    mi_help_SDP: TMenuItem;
    N1: TMenuItem;
    fft: TunadspFFTControl;
    SampleHomepage1: TMenuItem;
    reRec: TunaIPReceiver;
    est1: TMenuItem;
    mi_test_sendText: TMenuItem;
    mi_test_sendRTCPApp: TMenuItem;
    c_memo_log: TMemo;
    c_cb_ignore_thisHostIPs: TCheckBox;
    c_label_recStatus: TLabel;
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
    procedure mi_help_URIClick(Sender: TObject);
    procedure mi_help_SDPClick(Sender: TObject);
    //
    procedure c_button_openClick(Sender: TObject);
    procedure c_button_closeClick(Sender: TObject);
    procedure c_button_sdpClick(Sender: TObject);
    procedure c_button_browseClick(Sender: TObject);
    //
    procedure c_cb_payloadChange(Sender: TObject);
    procedure c_cb_VADClick(Sender: TObject);
    //
    procedure c_cb_timeoutClick(Sender: TObject);
    procedure c_cb_muteClick(Sender: TObject);
    procedure c_cb_deviceChange(Sender: TObject);
    //
    procedure c_memo_sdpChange(Sender: TObject);
    //
    procedure dummyAcmReq(sender: TObject; req: Cardinal; var acm: unaMsAcm);
    procedure SampleHomepage1Click(Sender: TObject);
    procedure fftClick(Sender: TObject);
    procedure c_cb_uriChange(Sender: TObject);
    procedure mi_test_sendTextClick(Sender: TObject);
    procedure mi_test_sendRTCPAppClick(Sender: TObject);
    //
    procedure transFormatChangeBefore(sender, provider: unavclInOutPipe; newFormat: Pointer; len: Cardinal; out allowFormatChange: LongBool);
    procedure transRTCPApp(sender: unavclInOutPipe; const params: unaIPStreamOnRTCPAppParams);
    procedure c_cb_transportChange(Sender: TObject);
  private
    { Private declarations }
    //
    f_config: unaIniFile;
    f_logText: unaStringList;
    //
    f_srcIsReceiver: bool;
    f_noReceiversCount: int;
    f_label_statusKeepText: int;
    //
    f_uri: unaURICrack;
    f_uriCracked: bool;
    //
    function getUriHost(): string;
    function getUriPort(): int;
    procedure crackURI();
    //
    procedure enableGUI(doEnable: bool);
    procedure applySDP(index: int);
    //
    procedure updateStatus();
    procedure beforeClose();
  public
    { Public declarations }
    //
    property uriHost: string read getUriHost;
    property uriPort: int read getUriPort;
  end;

var
  c_form_main: Tc_form_main;


implementation


{$R *.dfm}

uses
  ShellAPI, WinSock,
  unaUtils,
  unaVCLUtils, unaVCIDEUtils,
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
    c_button_SDPClick(self);	// apply SDP on transmitter
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
  f_config.setValue('SDP.text', urlEncodeW(c_memo_sdp.text));
  f_config.setValue('SDP.role', c_cb_transport.itemIndex);
  //
  f_config.setValue('audio.source.fileName', c_edit_file.text);
  f_config.setValue('audio.source.useFile', c_cb_file.checked);
  //
  f_config.setValue('ssrc', c_edit_ssrc.text);
  //
  f_config.setValue('audio.vad', c_cb_vad.checked);
  f_config.setValue('audio.mute', c_cb_mute.checked);
  //
  f_config.setValue('rtcp.timeout', c_cb_timeout.checked);
  //
  saveControlPosition(self, f_config);
end;

// --  --
procedure Tc_form_main.c_cb_deviceChange(Sender: TObject);
begin
  //
end;

// --  --
procedure Tc_form_main.formCreate(sender: tObject);
begin
  f_config := unaIniFile.create();
  f_logText := unaStringList.create();
  //
  c_cb_payload.items.text := getFormatsList();
  //
  waveIn.addConsumer(fft.fft);
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
  //
  enumWaveDevices(c_cb_device);
  c_cb_device.itemIndex := f_config.get('waveIn.deviceId', int(0));
  //
  c_cb_transport.itemIndex := f_config.get('SDP.role', int(0));
  //
  i := f_config.get('SDP.index', int(0));
  applySDP(i);
  c_cb_payload.itemIndex := i;
  //
  c_memo_sdp.text := URLDecode(f_config.get('SDP.text', URLEncode(trans.SDP)));
  //
  c_edit_file.text := f_config.get('audio.source.fileName', c_edit_file.text);
  c_cb_file.checked := f_config.get('audio.source.useFile', true) and (fileExists(c_edit_file.text) or (1 = pos('http', loCase(trimS(c_edit_file.text)))) or (1 = pos('rtp', loCase(trimS(c_edit_file.text)))) );
  //
  c_edit_ssrc.text := f_config.get('ssrc', c_edit_ssrc.text);
  //
  c_cb_vad.checked := f_config.get('audio.vad', true);
  c_cb_mute.checked := f_config.get('audio.mute', false);
  //
  c_cb_timeout.checked := f_config.get('rtcp.timeout', true);
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
  guiMessageBox(handle, 'IP Transmitter 2.0'#13#10'(c) 2012 Lake of Soft', 'About');
end;

// --  --
procedure Tc_form_main.mi_help_SDPClick(Sender: TObject);
begin
  shellExecute(handle, 'open', 'http://lakeofsoft.com/vc/a_ipstreamingsdpsamples.html', nil, nil, SW_SHOWNORMAL);
end;

// --  --
procedure Tc_form_main.mi_help_URIClick(Sender: TObject);
begin
  shellExecute(handle, 'open', 'http://lakeofsoft.com/vc/doc/VCDoc/unaIPStreaming/TunaIPTransmitter/URI.html', nil, nil, SW_SHOWNORMAL);
end;

// --  --
procedure Tc_form_main.SampleHomepage1Click(Sender: TObject);
begin
  shellExecute(handle, 'open', 'http://lakeofsoft.com/vc/a_rtptrans.html', nil, nil, SW_SHOWNORMAL);
end;

// --  --
procedure Tc_form_main.mi_test_sendRTCPAppClick(Sender: TObject);
var
  d: array[1..5] of byte;
begin
  trans.sendRTCPApp(0, 'RTST', @d, 0);	// 0
  //
  trans.sendRTCPApp(0, 'RTST', @d, 1, true);	// 4
  trans.sendRTCPApp(0, 'RTST', @d, 2);	// 4
  trans.sendRTCPApp(0, 'RTST', @d, 3);	// 4
  trans.sendRTCPApp(0, 'RTST', @d, 4, true);	// 4
  //
  trans.sendRTCPApp(0, 'RTST', @d, 5, true);	// 8
end;

// --  --
procedure Tc_form_main.mi_test_sendTextClick(Sender: TObject);
begin
  trans.sendText('Hi from Transmitter!');
end;

// --  --
procedure Tc_form_main.transFormatChangeBefore(sender, provider: unavclInOutPipe; newFormat: Pointer; len: Cardinal; out allowFormatChange: LongBool);
var
  wo: bool;
  mapping: punaRTPMap;
begin
  mapping := newFormat;
  if (nil <> mapping) then begin
    //
    wo := waveIn.active;
    try
      waveIn.close();
      //
      waveIn.pcm_samplesPerSec := mapping.r_samplingRate;
      waveIn.pcm_bitsPerSample := mapping.r_bitsPerSample;
      waveIn.pcm_numChannels := mapping.r_numChannels;
      //
      fft.fft.fft.setFormat(mapping.r_samplingRate, mapping.r_bitsPerSample, mapping.r_numChannels);
    finally
      waveIn.active := wo;
    end;
  end;
end;

// --  --
procedure Tc_form_main.transRTCPApp(sender: unavclInOutPipe; const params: unaIPStreamOnRTCPAppParams);
begin
  if (c_rtcp_appCmd_RTT <> params.r_cmd) then
    f_logText.add('Got RTCP APP [SSRC=' + int2str(params.r_SSRC) + '] from '+ ipH2str(params.r_fromIP4) + ':' + int2str(params.r_fromPort) + ' [cmd=' + string(params.r_cmd) + '; subtype=' + int2str(params.r_subtype) + '; datalen=' + int2str(params.r_len) + ']');
end;

// --  --
procedure Tc_form_main.fftClick(Sender: TObject);
begin
  fft.Enabled := not fft.Enabled;
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
  sinfo: string;
begin
  if (not (csDestroying in componentState)) then begin
    //
    {$IFDEF DEBUG }
    c_sb_main.panels[0].text := 'Mem: ' + int2str(ams() shr 10, 10, 3) + ' KB';
    {$ENDIF DEBUG }
    //
    if (nil <> trans.transRoot) then begin
      //
      if (0 = f_label_statusKeepText) then
	c_label_status.caption := '[' + int2str(trans.transRoot._SSRC) + ']'#13#10 +
	  'Number of receivers: ' + int2str(trans.transRoot.destGetCount());
      //
      if (f_srcIsReceiver) then begin
	//
	if (reRec.active) then begin
	  //
	  if (1 > trans.transRoot.destGetCount()) then begin
	    //
	    if (1 < f_noReceiversCount) then
	      dec(f_noReceiversCount)
	    else
	      reRec.close();	// close reRec in case of no receivers
	  end
	  else
	    f_noReceiversCount := 64; 	// reset countdown while we have some receivers
	end
	else begin
	  //
	  if (0 < trans.transRoot.destGetCount()) then begin
	    //
	    f_noReceiversCount := 64; 	// reset countdown
	    //
	    reRec.open();
	  end;
	end;
      end;
    end
    else
      if (0 = f_label_statusKeepText) then
	c_label_status.caption := '';
    //
    if (reRec.active) then
      c_label_recStatus.Caption := 'Receiver: ' + int2str(reRec.inBandwidth shr 10, 10, 3) + ' kbps'
    else
      c_label_recStatus.Caption := 'Receiver: not active';
    //
    if (0 = f_label_statusKeepText) then begin
      //
      c_label_status.caption := c_label_status.caption + #13#10 +
	int2str(trans.mapping.r_rtpEncoding) + '[' + mapRtpEncoding2mediaType(trans.mapping.r_rtpEncoding) + '] "' + string(trans.mapping.r_mediaType) + '"' +
	'  < ' + int2str(waveIn.pcm_samplesPerSec) + '/' + int2str(waveIn.pcm_numChannels) + '/' + int2str(waveIn.pcm_bitsPerSample) + ' >' +
	#13#10 +
	choice(trans.active, 'Active', 'Not active') + '  [' + trans.descriptionInfo + ' / ' + trans.descriptionError + ']';
    end
    else
      dec(f_label_statusKeepText);
    //
    c_sb_main.panels[1].text := int2str(trans.outBandwidth shr 10, 10, 3) + ' kbps';
    //
    if (not c_cb_file.checked) then
      c_pb_vol.position := waveIn.getLogVolume();
    //
    if (0 < f_logText.count) then begin
      //
      sinfo := f_logText.get(0);
      f_logText.removeFromEdge();
      //
      c_memo_log.lines.add( stDateTime2str( utc2local(nowUTC()) ) + ' - ' + sinfo);
    end;
    //
    mi_test_sendText.enabled := trans.active;
    mi_test_sendRTCPApp.enabled := trans.active;
  end;
end;

// --  --
procedure Tc_form_main.dummyAcmReq(sender: TObject; req: Cardinal; var acm: unaMsAcm);
begin
  // we don't need ACM here, so just do nothing
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
procedure Tc_form_main.c_button_browseClick(Sender: TObject);
begin
  if (c_od_file.Execute()) then begin
    //
    c_edit_file.text := c_od_file.fileName;
    c_cb_file.checked := true;
  end;
end;

// --  --
procedure Tc_form_main.c_button_sdpClick(Sender: TObject);
begin
  trans.sdp := c_memo_sdp.text;
  c_button_sdp.enabled := false;
end;

// --  --
procedure Tc_form_main.c_button_closeClick(Sender: TObject);
begin
  waveRiff.close();
  waveIn.close();
  reRec.close();
  //
  enableGUI(true);
end;

// --  --
procedure Tc_form_main.c_cb_muteClick(Sender: TObject);
begin
  waveIn.enableDataProcessing := not c_cb_mute.checked;
end;

// --  --
procedure Tc_form_main.c_cb_payloadChange(Sender: TObject);
begin
  applySDP(c_cb_payload.itemIndex);
end;

// --  --
procedure Tc_form_main.c_cb_timeoutClick(Sender: TObject);
begin
  if (c_cb_timeout.checked) then
    trans.rtcpTimeoutReports := 6
  else
    trans.rtcpTimeoutReports := 0;	// disable
end;

// --  --
procedure Tc_form_main.c_cb_transportChange(Sender: TObject);
begin
  applySDP(c_cb_payload.itemIndex);
end;

// --  --
procedure Tc_form_main.c_cb_uriChange(Sender: TObject);
var
  s: string;
begin
  f_uriCracked := false;
  //
  case (c_cb_uri.itemIndex) of

    //--- RAW streaming --
    1: s := 'RAW UDP "Server": waits for client packets on specified port';	//udp://0.0.0.0:7654
    2: s := 'RAW UDP "Pusher": sends RAW packets to specified destination';	//udp://192.168.1.174:7654
    3: s := 'RAW UDP "Pusher": sends RAW packets to specified multicast group';	//udp://224.0.1.2:7654

    //--- RTP streaming --
    6: s := 'RTP UDP "Server": waits for client packets on default port (5004)';	//rtp://lakeofsoft@0.0.0.0/
    7: s := 'RTP UDP "Server": waits for client packets on specified port';	//rtp://lakeofsoft@0.0.0.0:8000/
    8: s := 'RTP UDP "Pusher": sends RTP packets to specified destination';	//rtp://lakeofsoft@192.168.1.70:5004/
    9: s := 'RAW UDP "Pusher": sends RTP packets to specified multicast group (port 5004)';	//rtp://lakeofsoft@224.0.1.2/

    //--- RTSP streaming --
    12: s := 'RTSP Server: waits for client requests on default port (554)';	//rtsp://local_rtsp_trans@0.0.0.0/
    13: s := 'RTSP Server: waits for client requests on specified port';	//rtsp://local_rtsp_trans@0.0.0.0:8000/

    //--- SHOUTcast streaming --
    16: s := 'SHOUTcast source: sends TCP stream to remote *cast server';	//http://source:hackme@192.168.0.174:8000/stream_name

    else
	s := '';

  end;
  //
  c_label_status.caption := s + #13#10 +
    'Audio source could be live recording, local file or remote server';
  //
  f_label_statusKeepText := 40;	// keep this text for 40 timer ticks
  //
  applySDP(c_cb_payload.itemIndex);
end;

// --  --
procedure Tc_form_main.c_cb_VADClick(Sender: TObject);
begin
  if (c_cb_VAD.checked) then
    waveIn.silenceDetectionMode := unasdm_3GPPVAD1
  else
    waveIn.silenceDetectionMode := unasdm_none;
end;

// --  --
procedure Tc_form_main.c_memo_sdpChange(Sender: TObject);
begin
  c_button_sdp.enabled := true;
end;

// --  --
procedure Tc_form_main.c_button_openClick(Sender: TObject);
begin
  enableGUI(false);
  //
  // apply SDP text and URI
  trans.SDP := c_memo_SDP.text;
  trans.URI := c_cb_uri.text;
  trans.ignoreLocalIPs := c_cb_ignore_thisHostIPs.checked;
  //
  waveIn.enableDataProcessing := not c_cb_mute.checked;
  //
  waveRiff.fileName := c_edit_file.text;
  //
  if (c_cb_timeout.checked) then
    trans.rtcpTimeoutReports := 6
  else
    trans.rtcpTimeoutReports := 0;	// disable
  //
  f_srcIsReceiver := false;
  //
  if (c_cb_file.checked) then begin
    //
    c_cb_payload.itemIndex := 10;
    applySDP(10);
    //
    // quick fix for VLC:
    while (c_memo_sdp.Lines.Count > 2) do
      c_memo_sdp.Lines.Delete(c_memo_sdp.Lines.Count - 1);
    //
    trans.sdp := c_memo_sdp.text;
    //
    if (0 = waveRiff.waveStream.status) then begin
      //
      if (c_unaRiffFileType_mpeg = waveRiff.waveStream.fileType) then begin
	//
	// do not try to encode MPEG stream, as it will not be decoded by waveRiff component
	trans.doEncode := false;
	//
	// need this for RTP to work properly
	trans.frameSize := waveRiff.waveStream.mpegFrameSize;
      end
      else
	trans.doEncode := true;
      //
      waveRiff.open();
    end
    else begin
      //
      trans.doEncode := false;	//
      //
      trans.frameSize := 0;	// analyze mp3 if needed
      //
      reRec.URI := c_edit_file.text;
      reRec.SDP := c_memo_SDP.text;
      //
      f_noReceiversCount := 64;
      f_srcIsReceiver := true;
      //
      reRec.open();
      //
      trans.open();
    end;
  end
  else begin
    //
    c_cb_file.checked := false;
    //
    trans.doEncode := true;	// waveIn always produce PCM, so encode the stream using transmitter
    trans._SSRC := str2intInt(c_edit_ssrc.text, 0);
    //
    if (c_cb_VAD.checked) then
      waveIn.silenceDetectionMode := unasdm_3GPPVAD1
    else
      waveIn.silenceDetectionMode := unasdm_none;
    //
    waveIn.open();
  end;
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
  c_cb_payload.enabled := doEnable;
  c_cb_transport.enabled := doEnable;
  c_edit_ssrc.enabled := doEnable;
  c_edit_file.enabled := doEnable;
  c_button_browse.enabled := doEnable;
  //
  c_cb_file.enabled := doEnable;
end;


end.

