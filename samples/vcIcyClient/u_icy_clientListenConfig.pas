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

	  u_icy_clientListenConfig.pas
	  Icy Streaming Client Demo application - listener config form

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

unit
  u_icy_clientListenConfig;

interface

uses
  Windows, unaTypes, Forms, unaVC_wave,
  ExtCtrls, StdCtrls, Controls, Classes, Dialogs;

type
  Tc_form_lstConfig = class(TForm)
    c_button_cancel: TButton;
    c_button_OK: TButton;
    c_button_audioCfg: TButton;
    c_edit_decoder: TEdit;
    c_button_browse: TButton;
    c_openDialog_dll: TOpenDialog;
    Label1: TLabel;
    //
    procedure formShow(sender: tObject);
    procedure c_button_OKClick(Sender: TObject);
    procedure c_button_browseClick(Sender: TObject);
    procedure c_button_audioCfgClick(Sender: TObject);
  private
    { Private declarations }
    f_waveOut: unavclWaveOutDevice;
  public
    { Public declarations }
    function configureListener(waveOut: unavclWaveOutDevice): bool;
  end;

var
  c_form_lstConfig: Tc_form_lstConfig;


implementation


{$R *.dfm}

uses
  u_icy_client, u_common_audioConfig;

// --  --
procedure Tc_form_lstConfig.formShow(sender: tObject);
begin
  c_edit_decoder.text := c_form_main.lstDecoder;
end;

// --  --
procedure Tc_form_lstConfig.c_button_OKClick(Sender: TObject);
begin
  c_form_main.lstDecoder := c_edit_decoder.text;
end;

// --  --
procedure Tc_form_lstConfig.c_button_audioCfgClick(Sender: TObject);
begin
  c_form_common_audioConfig.doConfig(nil, f_waveOut, nil, nil, c_form_main.config);
end;

// --  --
function Tc_form_lstConfig.configureListener(waveOut: unavclWaveOutDevice): bool;
begin
  f_waveOut := waveOut;
  result := (mrOK = showModal());
  f_waveOut := nil;
end;

// --  --
procedure Tc_form_lstConfig.c_button_browseClick(Sender: TObject);
begin
  if (c_openDialog_dll.execute()) then
    c_edit_decoder.text := c_openDialog_dll.fileName;
end;


end.

