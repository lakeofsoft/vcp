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

	  u_vcTalkNow_about.pas
	  vcTalkNow demo application - about form source

	----------------------------------------------
	  Copyright (c) 2002-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 22 Mar 2002

	  modified by:
		Lake, Mar 2003
		
	----------------------------------------------
*)

{$I unaDef.inc}

unit
  u_vcTalkNow_about;

interface

uses
  Windows, unaTypes, Forms, Graphics, Controls, ExtCtrls, Classes, StdCtrls;

type
  Tc_form_about = class(TForm)
    c_panel_logo: TPanel;
    c_image_about: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Button1: TButton;
    Bevel1: TBevel;
    Label5: TLabel;
    c_staticText_url: TStaticText;
    //
    procedure formCreate(sender: tObject);
    procedure c_staticText_urlClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure showAbout();
  end;

var
  c_form_about: Tc_form_about;


implementation


{$R *.dfm}

uses
  ShellApi;

{ Tc_form_about }

// --  --
procedure Tc_form_about.formCreate(sender: tObject);
begin
end;

// --  --
procedure Tc_form_about.showAbout();
begin
  showModal();
end;

// --  --
procedure Tc_form_about.c_staticText_urlClick(Sender: TObject);
begin
  shellExecute(0, 'open', 'http://lakeofsoft.com/vc/a_talknow.html', nil, nil, SW_SHOWNORMAL);
end;


end.

