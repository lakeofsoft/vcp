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

	  u_mgClient_main.pas
	  MediaGate demo application - Client main form source

	----------------------------------------------
	  Copyright (c) 2003-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 04 Apr 2003

	  modified by:
		Lake, Apr-Oct 2003

	----------------------------------------------
*)

{$I unaDef.inc }

unit
  u_mgClient_main;

interface

uses
  Windows, unaTypes, unaClasses, Forms,
  unaVcIDE, StdCtrls, Controls, Classes, ExtCtrls, CheckLst, ActnList,
  ComCtrls, Menus, unaVC_wave, unaVC_socks, unaVC_pipe;

type
  Tc_form_main = class(TForm)
    c_edit_host: TEdit;
    Label1: TLabel;
    c_edit_speakPort: TEdit;
    Label2: TLabel;
    c_rb_speak: TRadioButton;
    c_rb_listen: TRadioButton;
    c_button_go: TButton;
    waveIn: TunavclWaveInDevice;
    c_button_stop: TButton;
    codecIn: TunavclWaveCodecDevice;
    ipClient: TunavclIPOutStream;
    codecOut: TunavclWaveCodecDevice;
    waveOut: TunavclWaveOutDevice;
    c_clb_debug: TCheckListBox;
    c_timer_update: TTimer;
    c_edit_listenPort: TEdit;
    Label3: TLabel;
    Label4: TLabel;
    Bevel1: TBevel;
    Bevel2: TBevel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Bevel3: TBevel;
    c_statusBar_main: TStatusBar;
    c_actionList_main: TActionList;
    a_cln_start: TAction;
    a_cln_stop: TAction;
    c_label_stat: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    c_checkBox_random: TCheckBox;
    c_comboBox_speakProto: TComboBox;
    Label10: TLabel;
    c_comboBox_listenProto: TComboBox;
    Label11: TLabel;
    c_mm_main: TMainMenu;
    File1: TMenuItem;
    Exit1: TMenuItem;
    c_label_debugInfo: TLabel;
    Help1: TMenuItem;
    About1: TMenuItem;
    //
    procedure formCreate(sender: tObject);
    procedure formDestroy(sender: tObject);
    procedure formCloseQuery(sender: tObject; var canClose: boolean);
    procedure formShow(sender: tObject);
    //
    procedure c_timer_updateTimer(sender: tObject);
    //
    procedure a_cln_startExecute(sender: tObject);
    procedure a_cln_stopExecute(sender: tObject);
    procedure ipClientClientDisconnect(sender: TObject; connectionId: Cardinal; connected: LongBool);
    procedure Exit1Click(Sender: TObject);
    procedure About1Click(Sender: TObject);
  private
    { Private declarations }
    f_ini: unaIniFile;
  public
    { Public declarations }
  end;

var
  c_form_main: Tc_form_main;


implementation


{$R *.dfm}

uses
  unaUtils, unaVCLUtils, SysUtils,
  ShellAPI;

// --  --
procedure Tc_form_main.formCreate(sender: tObject);
begin
  f_ini := unaIniFile.create();
  //
  randomize();
  //
  c_edit_host.text := f_ini.get('server.addr', '192.168.1.1');
  //
  c_edit_speakPort.text := f_ini.get('server.speak.port', '17860');
  c_edit_listenPort.text := f_ini.get('server.listen.port', '17861');
  //
  c_comboBox_speakProto.itemIndex := f_ini.get('speak.proto', int(0));
  c_comboBox_listenProto.itemIndex := f_ini.get('listen.proto', int(0));
  //
  if (f_ini.get('client.mode.isSpeak', true)) then
    c_rb_speak.checked := true
  else
    c_rb_listen.checked := true;
end;

// --  --
procedure Tc_form_main.formDestroy(sender: tObject);
begin
  with (f_ini) do begin
    //
    setValue('server.addr', c_edit_host.text);
    //
    setValue('server.speak.port', c_edit_speakPort.text);
    setValue('server.listen.port', c_edit_listenPort.text);
    //
    setValue('speak.proto', c_comboBox_speakProto.itemIndex);
    setValue('listen.proto', c_comboBox_listenProto.itemIndex);
    //
    setValue('client.mode.isSpeak', c_rb_speak.checked);
  end;
  //
  freeAndNil(f_ini);
end;

// --  --
procedure Tc_form_main.formCloseQuery(sender: tObject; var canClose: boolean);
begin
  c_timer_update.enabled := false;
  a_cln_stop.execute();
  //
  saveControlPosition(self, f_ini);
end;

// --  --
procedure Tc_form_main.formShow(sender: tObject);
begin
  loadControlPosition(self, f_ini);
  //
	c_clb_debug.visible := {$IFDEF DEBUG }true{$ELSE }false{$ENDIF DEBUG };
  c_label_debugInfo.visible := {$IFDEF DEBUG }true{$ELSE }false{$ENDIF DEBUG };
  c_checkBox_random.visible := {$IFDEF DEBUG }true{$ELSE }false{$ENDIF DEBUG };
  //
  c_timer_update.enabled := true;
end;

// --  --
procedure Tc_form_main.c_timer_updateTimer(Sender: TObject);

{$IFDEF DEBUG }

  //
  function pipeInfo(pipe: unavclInOutPipe): string;
  begin
    if (nil <> pipe) then begin
      //
      result := 'In/Out: ' + int2str(pipe.inBytes[0], 10, 3) + '/' + int2str(pipe.outBytes[0], 10, 3) + ' bytes';
      //
      if (pipe is unavclInOutIpPipe) then
	result := result + ';   Network In/Out: ' + int2str(pipe.inBytes[1], 10, 3) + '/' + int2str(pipe.outBytes[1], 10, 3) + ' bytes;  lost: ' + int2str((pipe as unavclInOutIpPipe).inPacketsOutOfSeq) + ' packets'
    end
    else
      result := '<nil>';
  end;

{$ENDIF DEBUG }

var
  sampleSize: unsigned;
{$IFDEF DEBUG }
  pipe: unavclInOutPipe;
{$ENDIF DEBUG }
begin
  if (not (csDestroying in componentState)) then begin
    //
{$IFDEF DEBUG }
    c_clb_debug.checked[0] := waveIn.active;
    c_clb_debug.checked[1] := codecIn.active;
    c_clb_debug.checked[2] := ipClient.active;
    c_clb_debug.checked[3] := codecOut.active;
    c_clb_debug.checked[4] := waveOut.active;
    //
    c_statusBar_main.panels[0].text := 'Mem: ' + int2str(ams() shr 10, 10, 3) + ' KB';
    //
    case (c_clb_debug.itemIndex) of

      0: pipe := waveIn;
      1: pipe := codecIn;
      2: pipe := ipClient;
      3: pipe := codecOut;
      4: pipe := waveOut;
      else
	 pipe := nil;

    end;
    //
    c_label_debugInfo.caption := pipeInfo(pipe);
    //
{$ENDIF DEBUG }
    //
    if (c_rb_speak.checked) then begin
      //
      sampleSize := codecIn.pcm_bitsPerSample shr 3 * codecIn.pcm_numChannels;
      if (1 < sampleSize) then
	c_label_stat.caption := 'Sent: ' + int2str(waveIn.outBytes[0] div sampleSize, 10, 3) + ' samples / ' + int2str((waveIn.outBytes[0] div sampleSize) div codecIn.pcm_samplesPerSec) + ' seconds.';
    end
    else begin
      //
      sampleSize := codecOut.pcm_bitsPerSample shr 3 * codecOut.pcm_numChannels;
      if (1 < sampleSize) then
	c_label_stat.caption := 'Received: ' + int2str(waveOut.inBytes[0] div sampleSize, 10, 3) + ' samples / ' + int2str((waveOut.inBytes[0] div sampleSize) div codecOut.pcm_samplesPerSec) + ' seconds.';
      //
    end;
    //
    a_cln_start.enabled := not ipClient.active;
    a_cln_stop.enabled := not a_cln_start.enabled;
    c_rb_speak.enabled := a_cln_start.enabled;
    c_rb_listen.enabled := c_rb_speak.enabled;
    //
    {$IFDEF DEBUG }
    //
    if (c_checkBox_random.checked) then begin
      //
      if (25 = random(30)) then begin
	//
	if (a_cln_start.enabled) then
	  a_cln_start.execute()
	else
	  a_cln_stop.execute()
      end;
    end;
    {$ENDIF DEBUG }
  end;
end;

// --  --
procedure Tc_form_main.About1Click(Sender: TObject);
begin
  shellExecute(handle, 'open', 'http://lakeofsoft.com/vc/a_onetomanystreaming.html', nil, nil, SW_SHOWNORMAL);
end;

// --  --
procedure Tc_form_main.a_cln_startExecute(Sender: TObject);
begin
  a_cln_start.enabled := false;
  //
  ipClient.host := c_edit_host.text;
  //
  if (c_rb_speak.checked) then begin
    //
    // speaker
    ipClient.proto := tunavclProtoType(choice(0 = c_comboBox_speakProto.ItemIndex, ord(unapt_UDP), ord(unapt_TCP)));
    ipClient.port := c_edit_speakPort.text;
    ipClient.consumer := nil;	// no need to playback
    //
    if (not waveIn.open()) then begin
      //
      waveIn.close();
      //
      raise exception.create('Unable to open waveIn device, error text: '#13#10 + waveIn.waveErrorAsString);
    end;
    //
  end
  else begin
    //
    // listener
    //
    ipClient.proto := tunavclProtoType(choice(0 = c_comboBox_listenProto.ItemIndex, ord(unapt_UDP), ord(unapt_TCP)));
    ipClient.port := c_edit_listenPort.text;
    ipClient.consumer := codecOut;	// restore playback chain
    //
    if (unapt_TCP = ipClient.proto) then begin
      //
      // since listener does not send data back to server, server may pack up to 200 ms
      // of audio data into output buffer (because of ACK is not received after each send)
      // and so we need to increase the input buffers for codecOut and waveOut
      codecOut.overNum := defOverNumValue shl 2;
      waveOut.overNum := defOverNumValue shl 2;
    end
    else begin
      //
      // for UDP it does not apply, so reduce the buffers to default value
      codecOut.overNum := defOverNumValue;
      waveOut.overNum := defOverNumValue;
    end;
    //
    ipClient.open();
  end;
end;

// --  --
procedure Tc_form_main.a_cln_stopExecute(sender: tObject);
begin
  a_cln_stop.enabled := false;
  // stop everything
  waveIn.close();
end;

// --  --
procedure Tc_form_main.ipClientClientDisconnect(sender: tObject; connectionId: cardinal; connected: LongBool);
begin
  // stop everything
  waveIn.close();
end;

// --  --
procedure Tc_form_main.Exit1Click(Sender: TObject);
begin
  close();
end;


end.

