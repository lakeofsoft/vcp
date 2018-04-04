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

	  u_unaConfRTPsrv_srvConfig.pas
	  unaConfRTPsrv demo application - server configuration form

	----------------------------------------------
	  Copyright (c) 2009-2011 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, Feb 2010

	  modified by:
		Lake, Feb-Apr 2011

	----------------------------------------------
*)

{$I unaDef.inc }

unit
  u_unaConfRTPsrv_srvConfig;

interface

uses
  Windows, unaTypes, unaClasses,
  Forms, StdCtrls, Controls, Classes;

type
  Tc_form_params = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    c_edit_port: TEdit;
    c_edit_bind2ip: TEdit;
    c_button_OK: TButton;
    c_button_cancel: TButton;
    Label3: TLabel;
    c_edit_pw: TEdit;
    c_cb_ssa: TCheckBox;
    c_cb_acr: TCheckBox;
    c_cb_arr: TCheckBox;
    Label4: TLabel;
    c_edit_name: TEdit;
    c_cb_ustor: TCheckBox;
  private
    { Private declarations }
  public
    { Public declarations }
    function editParams(config: unaIniFile): bool;
  end;

var
  c_form_params: Tc_form_params;


implementation


{$R *.dfm}


{ Tc_form_params }

// --  --
function Tc_form_params.editParams(config: unaIniFile): bool;
begin
  c_edit_name.text 	:= config.get('srv.name', '<Untitled>');
  c_edit_port.text 	:= config.get('ip.port', '5004');
  c_edit_bind2ip.text 	:= config.get('ip.bind2ip', '0.0.0.0');
  c_edit_pw.text 	:= config.get('srv.masterpw', 'serverkey');
  //
  c_cb_ssa.checked := config.get('srv.autoStart', false);
  c_cb_acr.checked := config.get('srv.autoCreateRooms', true);
  c_cb_arr.checked := config.get('srv.autoRemoveRooms', true);
  c_cb_ustor.checked := config.get('srv.ustor', true);
  //
  result := (mrOK = showModal());
  if (result) then begin
    //
    config.setValue('ip.port', c_edit_port.text);
    config.setValue('ip.bind2ip', c_edit_bind2ip.text);
    config.setValue('srv.masterpw', c_edit_pw.text);
    //
    config.setValue('srv.autoStart', c_cb_ssa.checked);
    config.setValue('srv.autoCreateRooms', c_cb_acr.checked);
    config.setValue('srv.autoRemoveRooms', c_cb_arr.checked);
    config.setValue('srv.name', c_edit_name.text);
    config.setValue('srv.ustor', c_cb_ustor.checked);
  end;
end;


end.

