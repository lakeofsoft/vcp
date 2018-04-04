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

	  u_vcMCendPoint_main.pas
	  vcMulticast End Point demo application - main form source

	----------------------------------------------
	  Copyright (c) 2005-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 01 Oct 2005

	  modified by:
		Lake, Oct 2005

	----------------------------------------------
*)

{$I unaDef.inc }

unit
  u_vcMCendPoint_main;

interface

uses
  Windows, unaTypes, unaClasses, unaSockets,
  Forms, Classes, Controls, ComCtrls, ExtCtrls, unaVCIDE, StdCtrls,
  unaDspControls, Menus, unaVC_wave, unaVC_pipe;

type
  Tc_form_main = class(TForm)
    c_statusBar_main: TStatusBar;
    c_label_mcsHost: TLabel;
    c_label_mcsPort: TLabel;
    c_label_mcsBindTo: TLabel;
    c_edit_group: TEdit;
    c_edit_port: TEdit;
    c_button_mcepStart: TButton;
    c_button_mcepStop: TButton;
    c_cb_mcepBindTo: TComboBox;
    codecOut: TunavclWaveCodecDevice;
    c_timer_update: TTimer;
    c_fft_main: TunadspFFTControl;
    Label1: TLabel;
    c_label_status: TLabel;
    waveOut: TunavclWaveOutDevice;
    c_mm_main: TMainMenu;
    File1: TMenuItem;
    Exit1: TMenuItem;
    Help1: TMenuItem;
    About1: TMenuItem;
    //
    procedure formCreate(sender: tObject);
    procedure formShow(sender: tObject);
    procedure formCloseQuery(sender: tObject; var canClose: boolean);
    procedure formDestroy(sender: tObject);
    //
    procedure c_timer_updateTimer(sender: tObject);
    procedure c_button_mcepStartClick(Sender: TObject);
    procedure c_button_mcepStopClick(Sender: TObject);
    procedure Exit1Click(Sender: TObject);
    procedure About1Click(Sender: TObject);
  private
    { Private declarations }
    f_config: unaIniFile;
    f_endPoint: unaMulticastSocket;
    f_recThread: unaThread;
    //
    f_received: int64;
    f_socketErr: int;
  public
    { Public declarations }
  end;

var
  c_form_main: Tc_form_main;


implementation


{$R *.dfm}

uses
  unaUtils, unaVCLUtils, unaVCIDEUtils,
  WinSock, ShellAPI;


type
  //
  // -- internal receiver thread --
  //
  receiverThread = class(unaThread)
  private
    f_socket: unaMulticastSocket;
    f_codec: TunavclWaveCodecDevice;
    f_cnt: pInt64;
  protected
    function execute(id: unsigned): int; override;
  public
    constructor create(socket: unaMulticastSocket; codec: TunavclWaveCodecDevice; cnt: pInt64);
  end;


{ receiverThread }

// --  --
constructor receiverThread.create(socket: unaMulticastSocket; codec: TunavclWaveCodecDevice; cnt: pInt64);
begin
  f_socket := socket;
  f_codec := codec;
  f_cnt := cnt;
  //
  inherited create();
end;

// --  --
function receiverThread.execute(id: unsigned): int;
var
  addr: sockaddr_in;
  buf: pointer;
  mtu, sz: unsigned;
begin
  mtu := f_socket.getMTU();
  buf := malloc(mtu);
  try
    while (not shouldStop) do begin
      //
      sz := unsigned(f_socket.recvfrom(addr, buf, mtu, false, 0, 1));
      if (0 < int(sz)) then begin
	//
	f_codec.write(buf, sz);
	//
	inc(f_cnt^, sz);
      end
      else
	sleep(10);
    end;
    //
  finally
    mrealloc(buf);
  end;
  //
  result := 0;
end;


{ Tc_form_main }

// --  --
procedure Tc_form_main.formCreate(sender: tObject);
begin
  f_config := unaIniFile.create();
  f_endPoint := unaMulticastSocket.create();
  //
  {$IFDEF __AFTER_D7__ }
  doubleBuffered := True;
  {$ENDIF __AFTER_D7__ }
  //
  codecOut.addConsumer(c_fft_main.fft);
end;

// --  --
procedure Tc_form_main.formShow(sender: tObject);
var
  i: int;
  ip: string;
begin
  loadControlPosition(self, f_config);
  //
  f_config.section := 'mc';
  c_edit_group.text := f_config.get('groupIP', '224.0.1.2');
  c_edit_port.text := f_config.get('port', '18000');
  //
  c_cb_mcepBindTo.clear();
  c_cb_mcepBindTo.items.add('0.0.0.0');
  //
  with (unaStringList.create()) do try
    //
    lookupHost('', ip, (_this as unaStringList));
    //
    if (0 < count) then begin
      //
      for i := 0 to count - 1 do
	c_cb_mcepBindTo.items.add(string(get(i)));
      //
    end;
    //
    c_cb_mcepBindTo.itemIndex := f_config.get('bindToIndex', int(0));
  finally
    free();
  end;
  //
  c_timer_update.enabled := true;
end;

// --  --
procedure Tc_form_main.formCloseQuery(sender: tObject; var canClose: boolean);
begin
  c_timer_update.enabled := false;
  //
  freeAndNil(f_recThread);
  f_endPoint.close();
  codecOut.close();
  //
  f_config.section := 'mc';
  f_config.setValue('groupIP', c_edit_group.text);
  f_config.setValue('port', c_edit_port.text);
  //
  f_config.setValue('bindToIndex', c_cb_mcepBindTo.itemIndex);
  //
  saveControlPosition(self, f_config);
end;

// --  --
procedure Tc_form_main.formDestroy(sender: tObject);
begin
  freeAndNil(f_endPoint);
  freeAndNil(f_config);
end;


procedure Tc_form_main.c_timer_updateTimer(Sender: TObject);
begin
  if (not (csDestroying in componentState)) then begin
    //
    {$IFDEF DEBUG }
    c_statusBar_main.panels[0].text := int2str(ams() shr 10, 10, 3) + ' KB';
    {$ENDIF DEBUG }
    //
    c_button_mcepStart.enabled := not f_endPoint.isConnected(1);
    c_button_mcepStop.enabled := not c_button_mcepStart.enabled;
    //
    c_label_status.caption := 'Status: ' + choice(f_endPoint.isConnected(0), 'received ' + int2str(f_received shr 10, 10, 3) + ' KB',
      choice(0 = f_socketErr, ' inactive.', 'socket error = ' + int2str(f_socketErr)));
    //
  end;
end;

// --  --
procedure Tc_form_main.About1Click(Sender: TObject);
begin
  shellExecute(handle, 'open', 'http://lakeofsoft.com/vc/a_audiomulticast.html', nil, nil, SW_SHOWNORMAL);
end;

// --  --
procedure Tc_form_main.c_button_mcepStartClick(Sender: TObject);
begin
  // start receiving
  f_received := 0;
  //
  f_endPoint.bindToIP := c_cb_mcepBindTo.text;
  f_endPoint.bindToPort := c_edit_port.text;
  //
  f_socketErr := f_endPoint.mjoin(c_edit_group.text, c_unaMC_receive);	// receive-only
  //
  if (0 = f_socketErr) then begin
    //
    codecOut.open();
    //
    f_recThread := receiverThread.create(f_endPoint, codecOut, @f_received);
    f_recThread.start();
  end;
end;

// --  --
procedure Tc_form_main.c_button_mcepStopClick(Sender: TObject);
begin
  // stop receiving
  freeAndNil(f_recThread);
  f_endPoint.close();
  codecOut.close();
end;

// --  --
procedure Tc_form_main.Exit1Click(Sender: TObject);
begin
  close();
end;


end.

