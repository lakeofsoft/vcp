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

	  u_icy_clientStreamConfig.pas
	  Icy Streaming Client Demo application - streaming config form

	----------------------------------------------
	  Copyright (c) 2003-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 19 May 2003

	  modified by:
		Lake, May 2003
		Lake, Oct 2005
		Lake, Feb 2006
                Lake, Jun 2009

	----------------------------------------------
*)

{$I unaDef.inc}

unit
  u_icy_clientStreamConfig;

interface

uses
  Windows, unaTypes, Forms, StdCtrls, ExtCtrls, Controls, Classes, Dialogs;

type
  Tc_form_streamerConfig = class(TForm)
    Label5: TLabel;
    Label9: TLabel;
    Label10: TLabel;
    c_comboBox_bitRate: TComboBox;
    c_checkBox_allowPub: TCheckBox;
    c_edit_streamTitle: TEdit;
    c_edit_streamGenre: TEdit;
    c_checkBox_stereo: TCheckBox;
    Label12: TLabel;
    c_comboBox_source: TComboBox;
    Bevel1: TBevel;
    Button1: TButton;
    Button2: TButton;
    Label1: TLabel;
    c_edit_streamURL: TEdit;
    Bevel2: TBevel;
    Label2: TLabel;
    Label3: TLabel;
    c_edit_encoder: TEdit;
    Button3: TButton;
    Button4: TButton;
    c_openDialog_dll: TOpenDialog;
    procedure FormShow(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  c_form_streamerConfig: Tc_form_streamerConfig;


implementation


{$R *.dfm}

uses
  unaUtils,
  u_icy_client;

// --  --
procedure Tc_form_streamerConfig.FormShow(Sender: TObject);
begin
  c_comboBox_source.itemIndex := c_form_main.strSource;
  //c_form_main.strSourceIndex;
  //c_form_main.strSourceName;
  c_edit_encoder.text := c_form_main.strEncoder;
  c_comboBox_bitRate.text := int2str(c_form_main.strBitrate);
  c_checkBox_stereo.checked := c_form_main.strStereo;
  c_edit_streamTitle.text := c_form_main.strTitle;
  c_edit_streamURL.text := c_form_main.strURL;
  c_edit_streamGenre.text := c_form_main.strGenre;
  c_checkBox_allowPub.checked := c_form_main.strAllowPublishing;
end;

// --  --
procedure Tc_form_streamerConfig.Button2Click(Sender: TObject);
begin
  c_form_main.strSource := c_comboBox_source.itemIndex;
  //c_form_main.strSourceIndex;
  //c_form_main.strSourceName;
  c_form_main.strEncoder := c_edit_encoder.text;
  c_form_main.strBitrate := str2intInt(c_comboBox_bitRate.text, c_form_main.strBitrate);
  c_form_main.strStereo := c_checkBox_stereo.checked;
  c_form_main.strTitle := c_edit_streamTitle.text;
  c_form_main.strURL := c_edit_streamURL.text;
  c_form_main.strGenre := c_edit_streamGenre.text;
  c_form_main.strAllowPublishing := c_checkBox_allowPub.checked;
end;

// --  --
procedure Tc_form_streamerConfig.Button3Click(Sender: TObject);
begin
  if (c_openDialog_dll.execute()) then
    c_edit_encoder.text := c_openDialog_dll.fileName;
end;


end.

