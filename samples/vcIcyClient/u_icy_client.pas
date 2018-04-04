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

	  u_icy_client.pas
	  Icy Streaming Client Demo application - main form

	----------------------------------------------
	  Copyright (c) 2003-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 19 May 2003

	  modified by:
		Lake, May-Dec 2003
		Lake, Mar 2004
		Lake, Oct 2005
		Lake, Feb 2006
                Lake, Jun 2009

	----------------------------------------------
*)

{$I unaDef.inc}
{$I unaBassDef.inc }

unit
  u_icy_client;

interface

uses
  Windows, unaTypes, unaUtils, Forms, unaClasses,
  unaMsAcmClasses, unaMpglibAPI, unaEncoderAPI, unaSocks_SHOUT,
  unaIcyStreamer,
  Controls, StdCtrls, ComCtrls, ExtCtrls, Classes, ActnList, Menus, unaVC_pipe, unaVC_wave, unaVCIDE;

type
  // --  --
  Tc_form_main = class(TForm)
    c_statusBar_main: TStatusBar;
    c_timer_main: TTimer;
    c_actionList_main: TActionList;
    a_str_start: TAction;
    a_str_stop: TAction;
    a_lst_start: TAction;
    a_lst_stop: TAction;
    a_str_push: TAction;
    c_pageControl_main: TPageControl;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    c_label_strStatus: TLabel;
    Label13: TLabel;
    c_label_encoderInfo: TLabel;
    c_button_strStart: TButton;
    c_button_strStop: TButton;
    c_edit_songTitle: TEdit;
    Button1: TButton;
    c_checkBox_autoPush: TCheckBox;
    c_label_lstStatus: TLabel;
    c_label_decoderInfo: TLabel;
    c_button_lstStart: TButton;
    c_button_lstStop: TButton;
    TabSheet4: TTabSheet;
    Bevel1: TBevel;
    Bevel2: TBevel;
    c_label_strInfo: TLabel;
    Button2: TButton;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    Button3: TButton;
    a_lst_config: TAction;
    a_str_config: TAction;
    Label2: TLabel;
    c_edit_songURL: TEdit;
    c_memo_streamInfo: TMemo;
    Bevel3: TBevel;
    Bevel5: TBevel;
    Bevel6: TBevel;
    c_mm_main: TMainMenu;
    File1: TMenuItem;
    Exit1: TMenuItem;
    Help1: TMenuItem;
    About1: TMenuItem;
    waveOut: TunavclWaveOutDevice;
    Label1: TLabel;
    Label7: TLabel;
    c_edit_listenerURL: TEdit;
    Label12: TLabel;
    c_edit_port: TEdit;
    Label11: TLabel;
    Label3: TLabel;
    c_edit_password: TEdit;
    c_edit_host: TEdit;
    Label14: TLabel;
    //
    procedure formCreate(sender: tObject);
    procedure formCloseQuery(sender: tObject; var canClose: boolean);
    procedure formShow(sender: tObject);
    //
    procedure c_timer_mainTimer(Sender: TObject);
    procedure c_checkBox_autoPushClick(Sender: TObject);
    //
    procedure a_str_configExecute(Sender: TObject);
    procedure a_lst_configExecute(Sender: TObject);
    procedure a_str_startExecute(Sender: TObject);
    procedure a_str_stopExecute(Sender: TObject);
    procedure a_str_pushExecute(Sender: TObject);
    procedure a_lst_startExecute(Sender: TObject);
    procedure a_lst_stopExecute(Sender: TObject);
    //
    procedure urlLabelClick(Sender: TObject);
    procedure Exit1Click(Sender: TObject);
    procedure About1Click(Sender: TObject);
    procedure waveOutFeedDone(sender: unavclInOutPipe; data: Pointer; len: Cardinal);
  private
    { Private declarations }
    f_config: unaIniFile;
    //
    f_provider: unaIcyStreamProvider;
    f_icyClient: unaSHOUTreceiver;
    //
    f_waveIn: unaWaveInDevice;
    f_aiutoPushCountdown: int;
    //
    f_lame: unaLameMp3Enc;
    f_lameError: int;
    //
    f_bass: unaBass;
    f_bassStream: unaBassStream;
    f_bassError: int;
    f_dataStream: unaMemoryStream;
    f_bassStreamThread: unaBassStreamDecoder;
    //
    f_mpgLib: unaLibmpg123Decoder;
    f_feedStream: unaMemoryStream;
    f_chunk: array[1..$20000] of byte;
    f_feedObj: unaAcquireType;
    //
    f_dataOutSize: int64;
    f_dataInSize: int64;
    //
    procedure updateStrConfigInfo();
    procedure updateLstConfigInfo();
    //
    procedure encoderDataAvail(sender: tObject; data: pointer; size: unsigned; var copyToStream: bool);
    procedure configLame(bitRate, samplingRate: unsigned; stereo: bool);
    procedure waveDataAvail(sender: tObject; data: pointer; size: uint);
    //
    procedure feedWaveOut();
  public
    { Public declarations }
    //
    strSource: int;
    strSourceIndex: int;
    strSourcePath: string;
    strEncoder: string;
    strBitrate: int;
    strStereo: bool;
    strTitle: string;
    strURL: string;
    strGenre: string;
    strAllowPublishing: bool;
    //
    lstDestFile: string;
    lstDecoder: string;
    //
    property config: unaIniFile read f_config;
  end;

var
  c_form_main: Tc_form_main;


implementation


{$R *.dfm}

uses
  SysUtils, MMSystem, ShellAPI,
  unaVCLUtils, unaBladeEncAPI, unaBassAPI,
  u_icy_clientStreamConfig, u_icy_clientListenConfig, u_common_audioConfig;

type
  //
  // -- localBassStreamDecoder --
  //
  localBassStreamDecoder = class(unaBassStreamDecoder)
  protected
    procedure applySampling(rate, bits, channels: unsigned); override;
    procedure dataAvailable(data: pointer; size: unsigned); override;
  public
    constructor create();
  end;

  //
  // -- myMpgLibDecoder --
  //
  myMpgLibDecoder = class(unaLibmpg123Decoder)
  protected
    //procedure notifyData(data: pointer; size: unsigned; var copyToStream: bool); override;
    //procedure notifySamplingChange(rate, bits, channels: unsigned); override;
    procedure formatChange(rate, channels, encoding: int); override;
  end;

  // --  --
  mySHOUTReceiver = class(unaSHOUTreceiver)
  private
    f_buf: array[0..16383] of byte;
    f_bufSize: unsigned;
  protected
    procedure onPayload(data: pointer; len: uint); override;
    procedure onMetadata(data: pointer; len: uint); override;
  public
    procedure AfterConstruction(); override;
  end;


{ localBassStreamDecoder }

// --  --
procedure localBassStreamDecoder.applySampling(rate, bits, channels: unsigned);
begin
  with (c_form_main.waveOut) do begin
    //
    close();
    //
    pcm_samplesPerSec := rate;
    pcm_bitsPerSample := bits;
    pcm_numChannels := channels;
    //
    open();
  end;
end;

// --  --
constructor localBassStreamDecoder.create();
begin
  inherited create(c_form_main.f_bassStream, c_form_main.f_dataStream, 20000);	// 20 sec timeout for TCP data should be enough
end;

// --  --
procedure localBassStreamDecoder.dataAvailable(data: pointer; size: unsigned);
begin
  c_form_main.f_feedStream.write(data, size);
  c_form_main.feedWaveOut();
end;


{ myMpgLibDecoder }

{

// --  --
procedure myMpgLibDecoder.notifyData(data: pointer; size: unsigned; var copyToStream: bool);
begin
  inherited;
  //
  with (c_form_main.waveOut) do begin
    //
    if (active) then
      write(data, size);
  end;
end;

}

// --  --
procedure myMpgLibDecoder.formatChange(rate, channels, encoding: int);
begin
  inherited;
  //
  with (c_form_main.waveOut) do begin
    //
    close();
    //
    pcm_samplesPerSec := rate;
    pcm_bitsPerSample := 16;
    pcm_numChannels := channels;
    //
    open();
  end;
end;


{ mySHOUTReceiver }

// --  --
procedure mySHOUTReceiver.AfterConstruction();
begin
  f_bufSize := sizeOf(f_buf);
  //
  inherited;
end;

// --  --
procedure mySHOUTReceiver.onMetadata(data: pointer; len: uint);
begin
  inherited;
  //
end;

// --  --
procedure mySHOUTReceiver.onPayload(data: pointer; len: uint);
var
  subZ: unsigned;
  ret: int;
begin
  inherited;
  //
  inc(c_form_main.f_dataInSize, len);
  //
  if (nil <> c_form_main.f_bass) then begin
    //
    c_form_main.f_dataStream.write(data, len);
    c_form_main.f_bassStreamThread.start();
  end;
  //
  if (nil <> c_form_main.f_mpgLib) then begin
    //
    c_form_main.f_mpgLib.feed(data, len);
    //
  {$IFDEF CPU64 }
                // seems like x64 compiler get a little bit smarter ;)
  {$ELSE }
    ret := 0;	// just to make compiler happy
  {$ENDIF CPU64 }
    //
    repeat
      //
      subZ := f_bufSize;
      if (nil <> c_form_main.f_mpgLib) then
        ret := c_form_main.f_mpgLib.read(@f_buf, subZ)
      else
        break;
      //
      if (MPG123_NEW_FORMAT = ret) then
        continue;
      //
      if ((MPG123_OK = ret) or (MPG123_NEED_MORE = ret)) then begin
        //
        if (0 < subZ) then begin
          //
          //waveOut.write(f_buf, subZ);
          c_form_main.f_feedStream.write(@f_buf, subZ);
          c_form_main.feedWaveOut();
        end
        else
          break;
      end
      else
        break;
      //
    until (MPG123_NEED_MORE = ret);
  end;
end;


{ Tc_form_main }

// --  --
procedure Tc_form_main.formCreate(sender: tObject);
begin
  f_config := unaIniFile.create();
  f_provider := unaIcyStreamProvider.create('', '');
  //
  f_waveIn := unaWaveInDevice.create(WAVE_MAPPER, false, false, 10);
  f_waveIn.onDataAvailable := waveDataAvail;
  //
  f_dataStream := unaMemoryStream.create();
  f_dataStream.maxCacheSize := 100;
  f_dataStream.maxSize := 4000000;	// should be enough
  //
  f_feedStream := unaMemoryStream.create(100);
  f_feedStream.maxSize := 4000000;	// should be enough
end;

// --  --
procedure Tc_form_main.formShow(sender: tObject);
begin
  loadControlPosition(self, f_config);
  //
  //c_comboBox_srvType.itemIndex := f_config.get('srv.type', unsigned(0));
  //c_edit_host.text := f_config.get('srv.address', '192.168.1.1');
  c_edit_port.text := f_config.get('srv.port', '8000');
  c_edit_password.text := f_config.get('srv.pass', 'hackme');
  c_edit_listenerURL.text := f_config.get('lst.url', '/');
  c_edit_songTitle.text := f_config.get('str.songTitle', 'Live recording');
  //
  strSource := f_config.get('str.source', unsigned(0));
  strSourceIndex := f_config.get('str.sourceIndex', unsigned(0));
  strSourcePath := f_config.get('str.sourcePath', '');
  strEncoder := f_config.get('str.encoder', 'Lame_Enc.Dll');
  strBitrate := f_config.get('str.bitrate', unsigned(128));
  strStereo := f_config.get('str.stereo', true);
  strTitle := 'VC 2.5 Streamer';
  //strTitle := f_config.get('str.title', 'VC 2.5 Streamer');
  strURL := f_config.get('str.URL', 'http://lakeofsoft.com/vc/');
  strGenre := f_config.get('str.genre', 'Rock');
  strAllowPublishing := f_config.get('str.allowPublishing', false);
  //
  lstDestFile := f_config.get('lst.destPath', '');
  lstDecoder := f_config.get('lst.decoder', 'Bass.Dll');
  //
{$IFDEF __AFTER_D4__ }
  c_pageControl_main.activePageIndex := f_config.get('gui.tabIndex', int(0));
{$ENDIF __AFTER_D4__ }
  //
  updateStrConfigInfo();
  updateLstConfigInfo();
  //
  c_form_common_audioConfig.doLoadConfig(nil, waveOut, nil, nil, config);
  //
  c_timer_main.enabled := true;
end;

// --  --
procedure Tc_form_main.feedWaveOut();
var
  sz: unsigned;
begin
  if (acquire32(f_feedObj, 100)) then try
    //
    while (waveOut.active and (waveOut.waveOutDevice.inProgress < waveOut.overNum) and (f_feedStream.getAvailableSize() >= int(waveOut.chunkSize))) do begin
      //
      sz := f_feedStream.read(@f_chunk, waveOut.chunkSize);
      if (0 < sz) then
	waveOut.write(@f_chunk, sz);
    end;
    //
  finally
    release32(f_feedObj);
  end;
end;

// --  --
procedure Tc_form_main.formCloseQuery(sender: tObject; var canClose: boolean);
begin
  c_timer_main.enabled := false;
  //
  a_str_stop.execute();
  a_lst_stop.execute();
  //
  saveControlPosition(self, f_config);
  //
  //f_config.setValue('srv.type', c_comboBox_srvType.itemIndex);
  //f_config.setValue('srv.address', c_edit_host.text);
  f_config.setValue('srv.port', c_edit_port.text);
  f_config.setValue('srv.pass', c_edit_password.text);
  f_config.setValue('lst.url', c_edit_listenerURL.text);
  //
  f_config.setValue('str.source', strSource);
  f_config.setValue('str.sourceIndex', strSourceIndex);
  f_config.setValue('str.sourcePath', strSourcePath);
  f_config.setValue('str.encoder', strEncoder);
  f_config.setValue('str.bitrate', strBitrate);
  f_config.setValue('str.stereo', strStereo);
  f_config.setValue('str.title', strTitle);
  f_config.setValue('str.URL', strURL);
  f_config.setValue('str.genre', strGenre);
  f_config.setValue('str.allowPublishing', strAllowPublishing);
  f_config.setValue('str.songTitle', c_edit_songTitle.text);
  //
  f_config.setValue('lst.destPath', lstDestFile);
  f_config.setValue('lst.decoder', lstDecoder);
  //
{$IFDEF __AFTER_D4__ }
  f_config.setValue('gui.tabIndex', c_pageControl_main.activePageIndex);
{$ENDIF __AFTER_D4__ }
  //
  freeAndNil(f_waveIn);
  freeAndNil(f_lame);
  //
  freeAndNil(f_bassStreamThread);
  freeAndNil(f_bassStream);
  freeAndNil(f_bass);
  //
  freeAndNil(f_mpgLib);
  //
  freeAndNil(f_provider);
  freeAndNil(f_icyClient);
  freeAndNil(f_config);
  //
  freeAndNil(f_dataStream);
  freeAndNil(f_feedStream);
end;

// --  --
procedure Tc_form_main.c_timer_mainTimer(Sender: TObject);
var
  subStrStr: string;
  subStrLst: string;
  streamInfo: string;
begin
  c_statusBar_main.panels[0].text := int2str(ams() shr 10, 10, 3) + ' KB';
  //
  subStrStr := '';
  subStrLst := '';
  case (f_provider.status) of

    iss_disconnected: begin
      //
      if (not a_str_start.enabled and a_str_stop.enabled) then
	a_str_stop.execute();
    end;

    iss_connected: begin
      //
      subStrStr := ', sent ' + int2str(f_dataOutSize, 10, 3) + ' bytes.';
      //
      if (c_checkBox_autoPush.checked) then begin
	//
	dec(f_aiutoPushCountdown);
	if (1 > f_aiutoPushCountdown) then begin
	  //
	  f_aiutoPushCountdown := 20;	// wait 20 * a_timer_main.interval ms before next push
	  c_edit_songTitle.text := 'Live, local time: ' + timeToStr(now);
	  a_str_push.execute();
	end
      end;
    end;

    else

  end;
  //
  if ((nil = f_icyClient) or (0 <> f_icyClient.errorCode)) then begin
    //
    if (not a_lst_start.enabled and a_lst_stop.enabled) then
      a_lst_stop.execute();
  end;
  //
  if ((nil <> f_icyClient) and (0 = f_icyClient.errorCode)) then begin
    //
    subStrLst := 'received/buffered ' + int2str(f_dataInSize shr 10, 10, 3) + '/' + int2str(f_feedStream.getAvailableSize() shr 10, 10, 3) + ' KBytes';
    //
    streamInfo := 'Format     : ' + f_icyClient.srv_bitrate + ' kbps; ' + waveOut.device.srcFormatInfo + #13#10 +
                  'Name       : ' + f_icyClient.srv_name + ' (' + f_icyClient.srv_genre + ')' + #13#10 +
                  'URL        : ' + f_icyClient.srv_url + #13#10 +
                  'Song Title : ' + f_icyClient.song_title + #13#10 +
                  'Song URL   : ' + f_icyClient.song_url + #13#10;
    //
    c_memo_streamInfo.text := string(streamInfo);
  end
  else
    subStrLst := 'stopped';
  //
  c_label_strStatus.caption := 'Status: ' + iss2str(f_provider.status) + subStrStr;
  c_label_lstStatus.caption := 'Status: ' + subStrLst;
end;

// --  --
procedure Tc_form_main.urlLabelClick(Sender: TObject);
begin
  if (sender is tLabel) then
    shellExecuteA(0, 'open', paChar(aString((sender as tLabel).hint)), nil, nil, SW_SHOWNORMAL);
end;

// --  --
procedure Tc_form_main.c_checkBox_autoPushClick(Sender: TObject);
begin
  c_edit_songTitle.enabled := not c_checkBox_autoPush.checked;
  if (c_checkBox_autoPush.checked) then
    f_aiutoPushCountdown := 1;	// push now
end;

// --  --
procedure Tc_form_main.a_str_configExecute(Sender: TObject);
begin
  if (mrOK = c_form_streamerConfig.showModal()) then
    updateStrConfigInfo();
end;

// --  --
procedure Tc_form_main.About1Click(Sender: TObject);
begin
  shellExecute(handle, 'open', 'http://lakeofsoft.com/vc/a_icyclient.html', nil, nil, SW_SHOWNORMAL);
end;

// --  --
procedure Tc_form_main.a_lst_configExecute(Sender: TObject);
begin
  if (c_form_lstConfig.configureListener(waveOut)) then
    updateLstConfigInfo();
end;

// --  --
procedure Tc_form_main.updateStrConfigInfo();
begin
  f_provider.title := strTitle;
  f_provider.URL := strURL;
  f_provider.genre := strGenre;
  f_provider.bitrate := strBitrate;
  f_provider.allowPublishing := strAllowPublishing;
  //
  c_label_strInfo.caption := strTitle + ' (' + strGenre + ') at ' + int2str(strBitrate) + ' kbps, ' + choice(strStereo, 'stereo', 'mono') + '.';
  //
  freeAndNil(f_lame);
  f_lame := unaLameMp3Enc.create(strEncoder, THREAD_PRIORITY_TIME_CRITICAL);
  f_lameError := f_lame.errorCode;
  //
  if (BE_ERR_SUCCESSFUL = f_lameError) then begin
    //
    c_label_encoderInfo.caption := 'Lame encoder, version ' + int2str(f_lame.version.byMajorVersion) + '.' + int2str(f_lame.version.byMinorVersion);
    f_lame.onDataAvailable := encoderDataAvail;
  end
  else begin
    //
    c_label_encoderInfo.caption := 'Lame encoder was not found.';
    //
    f_lameError := -1;
    freeAndNil(f_lame);
  end;
end;

// --  --
procedure Tc_form_main.updateLstConfigInfo();
begin
  freeAndNil(f_bassStreamThread);
  freeAndNil(f_bassStream);
  freeAndNil(f_bass);
  freeAndNil(f_mpgLib);
  //
  if (0 < pos('bass', lowerCase(lstDecoder))) then begin
    //
    f_bass := unaBass.create(lstDecoder, {$IFDEF BASS_AFTER_18 }0{$ELSE }-1{$ENDIF }, 44100, 32, handle);
    //
    f_bassError := f_bass.get_errorCode();
    if (BASS_OK = f_bassError) then begin
      //
      f_bassStream := unaBassStream.create(f_bass);
      f_bassStreamThread := localBassStreamDecoder.create();
      //
      c_label_decoderInfo.caption := 'BASS decoder, version ' + f_bass.get_versionStr();
    end
    else begin
      //
      f_bassError := -1;
      freeAndNil(f_bass);
    end;
  end
  else
    f_bassError := -1;
  //
  if (BASS_OK <> f_bassError) then begin
    //
    // try mpg123 instead
    try
      //
      f_mpgLib := myMpgLibDecoder.create(lstDecoder);
      c_label_decoderInfo.caption := 'mpg123 decoder, no version info';
    except
      //
      c_label_decoderInfo.caption := 'Unknown decoder module';
      freeAndNil(f_mpgLib);
    end;
  end;
  //
  //c_label_lstInfo.caption := 'Live playback';
end;

// --  --
procedure Tc_form_main.configLame(bitRate, samplingRate: unsigned; stereo: bool);
var
  lameConfig: BE_CONFIG_FORMATLAME;
begin
  f_lameError := -1;
  if (nil <> f_lame) then begin
    //
    fillChar(lameConfig, sizeOf(lameConfig), 0);
    lameConfig.dwConfig := BE_CONFIG_LAME;
    //
    with lameConfig.r_lhv1 do begin
      //
      dwStructVersion := CURRENT_STRUCT_VERSION;
      dwStructSize := sizeOf(lameConfig);
      dwSampleRate := samplingRate;
      dwReSampleRate := dwSampleRate;
      //
      if (stereo) then
	nMode := BE_MP3_MODE_STEREO
      else
	nMode := BE_MP3_MODE_MONO;
      //
      dwBitrate := bitRate;
      dwMaxBitrate := bitRate;
      //
      nPreset := LQP_NOPRESET;
      dwMpegVersion := MPEG2;
      //
      bPrivate := true;
      bCRC := false;
      bCopyright := true;
      bOriginal := true;
      //
      bWriteVBRHeader := false;
      bEnableVBR := false;
      nVbrMethod := VBR_METHOD_NONE;
      //
      bNoRes := true;
      bStrictIso := false;
    end;
    //
    f_lameError := f_lame.setConfig(@lameConfig);
    if (BE_ERR_SUCCESSFUL = f_lameError) then
      f_lameError := f_lame.open();
    //
    if (BE_ERR_SUCCESSFUL <> f_lameError) then
      c_label_encoderInfo.caption := 'Lame error: ' + int2str(f_lameError);
  end;
end;

// --  --
procedure Tc_form_main.encoderDataAvail(sender: tObject; data: pointer; size: unsigned; var copyToStream: bool);
begin
  if ((iss_connected = f_provider.status) and (0 = f_provider.sendData(data, size))) then
    inc(f_dataOutSize, size);
  //
  // no need to save the data locally
  copyToStream := false;
end;

// --  --
procedure Tc_form_main.a_str_startExecute(Sender: TObject);
var
  samplingRate: int;
  err: int;
begin
  a_str_start.enabled := false;
  a_str_config.enabled := false;
  //
  try
    f_dataOutSize := 0;
    //
    case (strBitrate) of

      000..016: samplingRate := 8000;
      017..032: samplingRate := 11025;
      033..064: samplingRate := 22050;
      065..096: samplingRate := 32000;

      else      samplingRate := 44100;

    end;
    //
    configLame(strBitrate, samplingRate, strStereo);
    if (BE_ERR_SUCCESSFUL = f_lameError) then begin
      //
      //f_waveIn.deviceId := deviceId;
      //
      f_waveIn.setSampling(samplingRate, 16, choice(strStereo, 2, unsigned(1)));
      err := f_waveIn.open();
      //
      if (f_waveIn.isOpen) then begin
	// start provider
	f_provider.password := AnsiString(c_edit_password.text);
	//f_provider.host := c_edit_host.text;
	f_provider.port := c_edit_port.text;
	//
	f_provider.start();
      end
      else begin
	//
	raise exception.create('Unable to open recording device, error text: '#13#10 + f_waveIn.getErrorText(err));
      end;
      //
      a_str_stop.enabled := true;
      a_str_push.enabled := true;
    end
    else
      raise exception.create('Unable to configure encoder, error code: ' + int2str(f_lameError));
    //
  except
    a_str_start.enabled := true;
    a_str_config.enabled := true;
    //
    raise;
  end;
end;

// --  --
procedure Tc_form_main.a_str_stopExecute(Sender: TObject);
begin
  a_str_stop.enabled := false;
  //
  try
    f_waveIn.close();
    f_lame.close();
    f_provider.stop();
  except
  end;
  //
  a_str_start.enabled := true;
  a_str_push.enabled := false;
  a_str_config.enabled := true;
end;

// --  --
procedure Tc_form_main.a_str_pushExecute(Sender: TObject);
begin
  f_provider.pushSongTitle(c_edit_songTitle.text, c_edit_songURL.text);
end;

// --  --
procedure Tc_form_main.waveDataAvail(sender: tObject; data: pointer; size: uint);
begin
  if ((nil <> f_lame) and (BE_ERR_SUCCESSFUL = f_lameError)) then
    // use lazy thread to return to waveIn ASAP
    f_lame.lazyWrite(data, size);
end;

// --  --
procedure Tc_form_main.waveOutFeedDone(sender: unavclInOutPipe; data: Pointer; len: Cardinal);
begin
  feedWaveOut();
end;

// --  --
procedure Tc_form_main.a_lst_startExecute(Sender: TObject);
begin
  a_lst_start.enabled := false;
  a_lst_config.enabled := false;
  //
  try
    if (((nil <> f_bass) and (BASS_OK = f_bassError)) or (nil <> f_mpgLib)) then begin
      // start consumer
      f_dataInSize := 0;
      f_dataStream.clear();
      f_feedStream.clear();
      //
      //f_consumer.host := c_edit_host.text;
      //f_consumer.port := c_edit_port.text;
      //f_consumer.URL := c_edit_listenerURL.text;
      f_icyClient := mySHOUTReceiver.create(c_edit_listenerURL.text);
      //
      a_lst_stop.enabled := true;
      //
      if (nil <> f_mpgLib) then
	f_mpgLib.open();
      //
      f_icyClient.start();
    end
    else
      raise exception.create('Decoder was not found.');
    //
  except
    a_lst_start.enabled := true;
    a_lst_config.enabled := true;
    //
    raise;
  end;
end;

// --  --
procedure Tc_form_main.a_lst_stopExecute(sender: tObject);
begin
  a_lst_stop.enabled := false;
  //
  try
    if (nil <> f_icyClient) then
      f_icyClient.stop();
    //
    f_dataStream.clear();
    f_feedStream.clear();
    //
    if (nil <> f_bass) then
      f_bassStreamThread.stop();
    //
    if (nil <> f_mpgLib) then
      f_mpgLib.close();
    //
    //waveOut.flush(false);
    waveOut.close();
  except
  end;
  //
  a_lst_start.enabled := true;
  a_lst_config.enabled := true;
end;

// --  --
procedure Tc_form_main.Exit1Click(Sender: TObject);
begin
  close();
end;


end.

