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

	  u_vcIPText_main.pas
	  vcIPText demo application - main form source

	----------------------------------------------
	  Copyright (c) 2009-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 10 Jul 2010

	  modified by:
		Lake, Jul 2010

	----------------------------------------------
*)

{$I unaDef.inc }

unit
  u_vcIPText_main;

interface

uses
  Windows, unaTypes, unaClasses,
  Forms, Menus, ExtCtrls, Classes, Controls, ComCtrls, StdCtrls, unaIPStreaming,
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
    Label1: TLabel;
    c_edit_URI: TEdit;
    c_button_start: TButton;
    c_button_stop: TButton;
    c_rb_TX: TRadioButton;
    c_rb_RX: TRadioButton;
    Label2: TLabel;
    c_memo_text: TMemo;
    RX: TunaIPReceiver;
    TX: TunaIPTransmitter;
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
    //
    procedure c_memo_textKeyPress(Sender: TObject; var Key: Char);
    procedure c_memo_textKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure RXText(sender: unavclInOutPipe; const data: PWideChar);
  private
    { Private declarations }
    f_config: unaIniFile;
    //
    procedure enableGUI(isActive: bool);
    //
    procedure updateStatus();
    procedure beforeClose();
  public
    { Public declarations }
  end;

var
  c_form_main: Tc_form_main;


implementation


{$R *.dfm}

uses
  unaSockets, Messages,
  unaUtils, unaVCLUtils;


{ Tc_form_main }

// --  --
procedure Tc_form_main.beforeClose();
begin
  c_timer_update.enabled := false;
  //
  f_config.setValue('TX', c_rb_TX.checked);
  f_config.setValue('URI', c_edit_URI.text);
  //
  saveControlPosition(self, f_config);
end;

// --  --
procedure Tc_form_main.formCreate(sender: tObject);
begin
  f_config := unaIniFile.create();
end;

// --  --
procedure Tc_form_main.formDestroy(sender: tObject);
begin
  freeAndNil(f_config);
end;

// --  --
procedure Tc_form_main.formShow(sender: tObject);
begin
  loadControlPosition(self, f_config);
  //
  // ======================================================================================
  // Assuming TX and RX are customPayloadAware, otherwise set SDP for both of them like:
  //
  //  TX.SDP := 'v=0'#13#10 +
  //	    'm=text 0 RTP/AVP 98'#13#10 +
  //	    'a=rtpmap:98 t140/1000'#13#10;
  //  RX.SDP := TX.SDP;
  //
  // ======================================================================================
  //
  c_rb_TX.checked := f_config.get('TX', true);
  c_rb_RX.checked := not c_rb_TX.checked;
  //
  c_edit_URI.text := f_config.get('URI', 'rtp://192.168.0.170:5006');
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
  guiMessageBox(handle, 'IP Text 1.0'#13#10'Copyright (c) 2010 Lake of Soft', 'About');
end;

// --  --
procedure Tc_form_main.RXText(sender: unavclInOutPipe; const data: PWideChar);
var
  i: int;
begin
  i := 0;
  while (i < length(data)) do begin

    case (data[i]) of

      // Actual encoding may be different, this one is used in this demo only
      //
      #$7F: begin
	//
	if (i + 1 < length(data)) then begin
	  //
	  case (data[i + 1]) of

	    #10: PostMessage(c_memo_text.handle, WM_KEYDOWN, VK_DELETE, 0);
	    #11: PostMessage(c_memo_text.handle, WM_KEYDOWN, VK_LEFT, 0);
	    #12: PostMessage(c_memo_text.handle, WM_KEYDOWN, VK_RIGHT, 0);
	    #13: PostMessage(c_memo_text.handle, WM_KEYDOWN, VK_DOWN, 0);
	    #14: PostMessage(c_memo_text.handle, WM_KEYDOWN, VK_UP, 0);
	    #15: PostMessage(c_memo_text.handle, WM_KEYDOWN, VK_INSERT, 0);
	    #16: PostMessage(c_memo_text.handle, WM_KEYDOWN, VK_END, 0);
	    #17: PostMessage(c_memo_text.handle, WM_KEYDOWN, VK_HOME, 0);
	    #18: PostMessage(c_memo_text.handle, WM_KEYDOWN, VK_PRIOR, 0);
	    #19: PostMessage(c_memo_text.handle, WM_KEYDOWN, VK_NEXT, 0);

	  end;
	  //
	  inc(i);
	end;
      end

      else
	PostMessage(c_memo_text.handle, WM_CHAR, int(aChar(data[i])), 0);

    end;
    //
    inc(i);
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
    enableGUI(TX.active or RX.active);
    //
    {$IFDEF DEBUG }
    c_sb_main.panels[0].text := 'Mem: ' + int2str(ams() shr 10, 10, 3) + ' KiB';
    {$ENDIF DEBUG }
  end;
end;

// --  --
procedure Tc_form_main.c_button_startClick(Sender: TObject);
begin
  c_button_start.enabled := false;
  c_memo_text.text := '';
  //
  if (c_rb_TX.checked) then begin
    //
    TX.URI := c_edit_URI.text;
    //
    TX.open();
  end;
  //
  if (c_rb_RX.checked) then begin
    //
    RX.URI := c_edit_URI.text;
    //
    RX.open();
  end;
end;

// --  --
procedure Tc_form_main.c_button_stopClick(Sender: TObject);
begin
  TX.close();
  RX.close();
end;

// --  --
procedure Tc_form_main.c_memo_textKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  case (Key) of

    // Actual encoding may be different, this one is used in this demo only
    //
    VK_DELETE	: TX.sendText(#$7F#10);
    VK_LEFT	: TX.sendText(#$7F#11);
    VK_RIGHT	: TX.sendText(#$7F#12);
    VK_DOWN	: TX.sendText(#$7F#13);
    VK_UP	: TX.sendText(#$7F#14);
    VK_INSERT	: TX.sendText(#$7F#15);
    VK_END	: TX.sendText(#$7F#16);
    VK_HOME	: TX.sendText(#$7F#17);
    VK_PRIOR	: TX.sendText(#$7F#18);
    VK_NEXT	: TX.sendText(#$7F#19);

  end;
end;

// --  --
procedure Tc_form_main.c_memo_textKeyPress(Sender: TObject; var Key: Char);
begin
  TX.sendText(key);
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
  c_rb_TX.enabled := not isActive;
  c_rb_RX.enabled := not isActive;
  c_edit_URI.enabled := not isActive;
  //
  c_memo_text.enabled := (c_rb_TX.checked and TX.active);
end;


end.

