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

	  u_vcBroadcast_main.dpr
	  Voice Communicator components version 2.5
	  vcBroadcast demo - main form

	----------------------------------------------
	  Copyright (c) 2001-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 18 Jul 2001

	  modified by:
		Lake, Jul-Nov 2002
		Lake, Jan-May 2003
		Lake, Jan-May 2004
		Lake, Sep 2005
		Lake, Apr 2007
		lake, May 2009

	----------------------------------------------
*)

{$I unaDef.inc}

unit u_vcBroadcast_main;

interface

uses
  Windows, unaTypes, unaClasses,
  Forms, StdCtrls, Classes, ActnList, Controls, ComCtrls,
  unavcIDE, ExtCtrls, Dialogs, Menus, unaVC_wave, unaVC_socks, unaVC_pipe;

type
  Tc_form_vcBroadcast = class(TForm)
    c_pageControl_main: TPageControl;
    c_tabSheet_server: TTabSheet;
    c_tabSheet_client: TTabSheet;
    c_edit_serverPort: TEdit;
    c_label_serverPort: TLabel;
    c_button_serverStart: TButton;
    c_button_serverStop: TButton;
    c_actionList_main: TActionList;
    a_startServer: TAction;
    a_stopServer: TAction;
    c_label_clientPort: TLabel;
    c_edit_clientPort: TEdit;
    c_static_clientInfo: TStaticText;
    c_button_clientStart: TButton;
    c_button_clientStop: TButton;
    a_startClient: TAction;
    a_stopClient: TAction;
    waveIn_server: TunavclWaveInDevice;
    waveOut_client: TunavclWaveOutDevice;
    codecIn_server: TunavclWaveCodecDevice;
    c_statusBar_main: TStatusBar;
    c_timer_main: TTimer;
    codecOut_client: TunavclWaveCodecDevice;
    c_checkBox_serverAutoStart: TCheckBox;
    c_broadcastServer: TunavclIPBroadcastServer;
    c_broadcastClient: TunavclIPBroadcastClient;
    c_edit_saveWAVname: TEdit;
    c_button_saveWAV: TButton;
    c_checkBox_saveWAV: TCheckBox;
    wavWrite: TunavclWaveRiff;
    c_sd_saveWAV: TSaveDialog;
    c_button_ac: TButton;
    Bevel1: TBevel;
    Bevel3: TBevel;
    Bevel6: TBevel;
    Label1: TLabel;
    Label2: TLabel;
    c_cb_clientBindTo: TComboBox;
    Label3: TLabel;
    c_edit_broadAddress: TEdit;
    Label4: TLabel;
    Label5: TLabel;
    c_cb_bindToSrv: TComboBox;
    c_mm_main: TMainMenu;
    File1: TMenuItem;
    Exit1: TMenuItem;
    Control1: TMenuItem;
    Listen1: TMenuItem;
    Stop1: TMenuItem;
    N1: TMenuItem;
    Listen2: TMenuItem;
    StopClient1: TMenuItem;
    Help1: TMenuItem;
    About1: TMenuItem;
    //
    procedure formCreate(sender: tObject);
    procedure formDestroy(sender: tObject);
    procedure formClose(sender: tObject; var action: tCloseAction);
    procedure formShow(sender: tObject);
    procedure formCloseQuery(sender: tObject; var canClose: boolean);
    //
    procedure a_stopServerExecute(Sender: TObject);
    procedure a_startClientExecute(Sender: TObject);
    procedure a_startServerExecute(Sender: TObject);
    procedure a_stopClientExecute(Sender: TObject);
    //
    procedure c_timer_mainTimer(Sender: TObject);
    procedure c_label_urlClick(Sender: TObject);
    procedure c_button_saveWAVClick(Sender: TObject);
    procedure c_edit_saveWAVnameChange(Sender: TObject);
    procedure c_button_acClick(Sender: TObject);
    //
    procedure codecOut_clientDataAvailable(sender: unavclInOutPipe; data: Pointer; len: Cardinal);
    procedure Exit1Click(Sender: TObject);
    procedure About1Click(Sender: TObject);
  private
    { Private declarations }
    f_ini: unaIniFile;
  public
    { Public declarations }
  end;

var
  c_form_vcBroadcast: Tc_form_vcBroadcast;


implementation


{$R *.dfm}

uses
  unaUtils, unaVCLUtils, unaSockets, SysUtils,
  MMSystem, unaMsAcmAPI, ShellAPI, Graphics,
  u_common_audioConfig;

// --  --
procedure Tc_form_vcBroadcast.formCreate(sender: tObject);
var
  list: unaStringList;
begin
  f_ini := unaIniFile.create();
  //
  f_ini.section := 'gui.server';
  //
  c_checkBox_serverAutoStart.Checked := f_ini.get('autoStartServer', true);
  c_edit_serverPort.Text := f_ini.get('portNumber', '17830');
{$IFDEF __AFTER_D5__}
  if (f_ini.get('tabActive', true)) then
    c_pageControl_main.tabIndex := 0
  else
    c_pageControl_main.tabIndex := 1;
{$ENDIF}
  c_edit_broadAddress.text := f_ini.get('broadAddr', '255.255.255.255');
  //
  //
  f_ini.section := 'gui.client';
  //
  c_edit_clientPort.text := f_ini.get('portNumber', '17830');
  c_edit_saveWAVname.text := f_ini.get('wavOutput', '');
  c_checkBox_saveWAV.checked := f_ini.get('wavOutputChecked', false);
  //
  list := unaStringList.create();
  try
    listAddresses('', list);
    c_cb_clientBindTo.items.clear();
    c_cb_clientBindTo.items.add('0.0.0.0');
    //
    while (c_cb_clientBindTo.items.count <= int(list.count)) do
      c_cb_clientBindTo.items.add(string(list.get(c_cb_clientBindTo.items.count - 1)));
    //
    c_cb_bindToSrv.Items.Assign(c_cb_clientBindTo.Items);
    //
  finally
    freeAndNil(list);
  end;
  //
  c_cb_clientBindTo.itemIndex := f_ini.get('socket.bindToIndex', int(0));
  if (0 > c_cb_clientBindTo.itemIndex) then
    c_cb_clientBindTo.itemIndex := 0;
  //
  c_cb_bindToSrv.itemIndex := f_ini.get('socket.bindToIndexSrv', int(0));
  if (0 > c_cb_bindToSrv.itemIndex) then
    c_cb_bindToSrv.itemIndex := 0;
  //
  c_timer_mainTimer(nil);
  c_timer_main.enabled := true;
end;

// --  --
procedure Tc_form_vcBroadcast.formShow(sender: tObject);
begin
  loadControlPosition(self, f_ini);
  //
  c_form_common_audioConfig.setupUI(true);
  c_form_common_audioConfig.doLoadConfig(waveIn_server, waveOut_client, codecIn_server, nil, f_ini);
  //
  if (c_checkBox_serverAutoStart.Checked and not c_broadcastServer.active) then
    a_startServer.execute();
end;

// --  --
procedure Tc_form_vcBroadcast.formCloseQuery(sender: tObject; var canClose: boolean);
begin
  c_timer_main.enabled := false;
  //
  a_stopServer.execute();
  a_stopClient.execute();
  //
  saveControlPosition(self, f_ini);
end;

// --  --
procedure Tc_form_vcBroadcast.formDestroy(sender: tObject);
begin
  freeAndNil(f_ini);
end;

// --  --
procedure Tc_form_vcBroadcast.formClose(sender: tObject; var action: tCloseAction);
begin
  f_ini.section := 'gui.Server';
  f_ini.setValue('autoStartServer', c_checkBox_serverAutoStart.checked);
  f_ini.setValue('portNumber', c_edit_serverPort.text);
{$IFDEF __AFTER_D5__}
  f_ini.setValue('tabActive', (0 = c_pageControl_main.tabIndex));
{$ENDIF}
  f_ini.setValue('broadAddr', c_edit_broadAddress.text);
  //
  f_ini.section := 'gui.client';
  f_ini.setValue('portNumber', c_edit_clientPort.text);
  f_ini.setValue('wavOutput', c_edit_saveWAVname.text);
  f_ini.setValue('wavOutputChecked',   c_checkBox_saveWAV.checked);
  f_ini.setValue('socket.bindToIndex', c_cb_clientBindTo.itemIndex);
  f_ini.setValue('socket.bindToIndexSrv', c_cb_bindToSrv.itemIndex);
end;

// --  --
procedure Tc_form_vcBroadcast.a_stopClientExecute(Sender: TObject);
begin
  c_broadcastClient.close();
end;

// --  --
procedure Tc_form_vcBroadcast.a_stopServerExecute(Sender: TObject);
begin
  waveIn_server.close();
end;

// --  --
procedure Tc_form_vcBroadcast.About1Click(Sender: TObject);
begin
  shellExecute(handle, 'open', 'http://lakeofsoft.com/vc/a_audiobroadcast.html', nil, nil, SW_SHOWNORMAL);
end;

// --  --
procedure Tc_form_vcBroadcast.a_startClientExecute(Sender: TObject);
begin
  if (c_checkBox_saveWAV.Checked) then begin
    //
    wavWrite.fileName := c_edit_saveWAVname.text;
    waveOut_client.consumer := wavWrite;
  end
  else
    waveOut_client.consumer := nil;
  //
  c_broadcastClient.port := c_edit_clientPort.text;
  c_broadcastClient.bindTo := c_cb_clientBindTo.text;
  //
  c_broadcastClient.open();
end;

// --  --
procedure Tc_form_vcBroadcast.a_startServerExecute(Sender: TObject);
begin
  a_startServer.enabled := false;
  //
  c_broadcastServer.port := c_edit_serverPort.text;
  c_broadcastServer.bindTo := c_cb_bindToSrv.text;
  c_broadcastServer.setBroadcastAddr(str2ipH(c_edit_broadAddress.text));
  //
  waveIn_server.open();
  //
  if (not waveIn_server.active) then begin
    //
    waveIn_server.close();
    raise exception.create('Unable to open waveIn device, error text: '#13#10 + waveIn_server.waveErrorAsString);
  end;
end;

// --  --
procedure Tc_form_vcBroadcast.c_timer_mainTimer(Sender: TObject);
var
  serverActive: bool;
  clientActive: bool;
  details: string;
begin
  if (not (csDestroying in ComponentState)) then begin
    //
    {$IFDEF DEBUG }
    c_statusBar_main.simpleText := 'Mem: ' + int2str(ams() shr 10, 10, 3) + ' KB - ';
    {$ELSE }
    c_statusBar_main.simpleText := '';
    {$ENDIF }
    //
    serverActive := c_broadcastServer.active;
    a_startServer.enabled := not serverActive;
    a_stopServer.enabled := serverActive;
    c_edit_serverPort.enabled := not serverActive;
    c_button_ac.enabled := not serverActive;
    c_edit_broadAddress.enabled := not serverActive;
    c_cb_bindToSrv.enabled := not serverActive;
    //
    clientActive := c_broadcastClient.active;
    a_startClient.enabled := not clientActive;
    a_stopClient.enabled := clientActive;
    c_checkBox_saveWAV.enabled := not clientActive;
    c_button_saveWAV.enabled := not clientActive;
    c_edit_clientPort.enabled := not clientActive;
    c_cb_clientBindTo.enabled := not clientActive;
    //
    c_edit_saveWAVnameChange(nil);
    //
    if (codecOut_client.active) then begin
      //
      with (codecOut_client.codec) do begin
	//
        if (nil <> driver) then
          details := driver.getDetails().szShortName
        else
          details := '';
        //
	c_static_clientInfo.caption :=
	  'Codec: ' + details + #13#10 +
	  'Input: ' + srcFormatInfo + ' / data: ' + int2str(getDataAvailable(true)) + #13#10 +
	  'Output: ' + dstFormatInfo + #13#10 +
	  //'waveOut: ' + waveOut_client.waveOutDevice.srcFormatInfo + #13#10 +
	  'Packets Lost: '+ int2str(c_broadcastClient.packetsLost, 10, 3) + #13#10 +
	  'Remote Host: ' + wideString(ipH2str(c_broadcastClient.remoteHost)) + ':' + int2str(c_broadcastClient.remotePort)
	//
      end;
    end
    else
      c_static_clientInfo.caption := 'Not active.';
    //
{$IFDEF __AFTER_D4__ }
    if (0 = c_pageControl_main.activePageIndex) then
      c_statusBar_main.simpleText := c_statusBar_main.simpleText + 'Sent: ' + int2str(c_broadcastServer.packetsSent, 10, 3) + ' packets; ' + int2str(c_broadcastServer.outBytes[1] shr 10, 10, 3) + ' KB'
    else
      c_statusBar_main.simpleText := c_statusBar_main.simpleText + 'Received: ' + int2str(c_broadcastClient.packetsReceived, 10, 3) + ' packets; ' + int2str(c_broadcastClient.outBytes[1] shr 10, 10, 3) + ' KB'
{$ENDIF }
  end;
end;

// --  --
procedure Tc_form_vcBroadcast.c_label_urlClick(Sender: TObject);
begin
  ShellExecute(0, 'open', 'http://lakeofsoft.com/vc/', nil, nil, SW_SHOWNORMAL);
end;

// --  --
procedure Tc_form_vcBroadcast.c_button_saveWAVClick(Sender: TObject);
begin
  if (c_sd_saveWAV.Execute) then begin
    //
    c_edit_saveWAVname.Text := trim(c_sd_saveWAV.FileName);
    c_checkBox_saveWAV.Checked := not ('' = c_edit_saveWAVname.Text);
  end;
end;

// --  --
procedure Tc_form_vcBroadcast.c_edit_saveWAVnameChange(Sender: TObject);
begin
  c_checkBox_saveWAV.enabled := c_checkBox_saveWAV.enabled and ('' <> c_edit_saveWAVname.text);
  c_checkBox_saveWAV.checked := c_checkBox_saveWAV.checked and ('' <> c_edit_saveWAVname.text);
end;

// --  --
procedure Tc_form_vcBroadcast.codecOut_clientDataAvailable(sender: unavclInOutPipe; data: Pointer; len: Cardinal);
begin
  if (wavWrite.active) then
    // pass data to wave file writer
    wavWrite.write(data, len);
end;

// --  --
procedure Tc_form_vcBroadcast.c_button_acClick(Sender: TObject);
begin
  c_form_common_audioConfig.doConfig(waveIn_server, waveOut_client, codecIn_server, nil, f_ini);
end;

// --  --
procedure Tc_form_vcBroadcast.Exit1Click(Sender: TObject);
begin
  close();
end;


end.

