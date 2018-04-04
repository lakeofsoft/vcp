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
	  Copyright (c) 2003-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 04 Jul 2003

	  modified by:
		Lake, Jul 2003

	----------------------------------------------
*)

{$I unaDef.inc}

unit
  u_vcSR_format;

interface

uses
  Windows, unaTypes, Forms,
  StdCtrls, Controls, Classes;

type
  Tc_form_format = class(TForm)
    c_comboBox_sampling: TComboBox;
    Label1: TLabel;
    c_checkBox_16bits: TCheckBox;
    c_checkBox_stereo: TCheckBox;
    Button1: TButton;
    Button2: TButton;
    Label2: TLabel;
  private
    { Private declarations }
  public
    { Public declarations }
    function changeFormat(var sampling, bits, channels: int): bool;
  end;

var
  c_form_format: Tc_form_format;


implementation


{$R *.dfm}

uses
  unaUtils;

{ Tc_form_format }

// --  --
function Tc_form_format.changeFormat(var sampling, bits, channels: int): bool;
begin
  c_comboBox_sampling.text := int2str(sampling);
  c_checkBox_16bits.checked := (16 = bits);
  c_checkBox_stereo.checked := (1 < channels);
  //
  if (mrOK = showModal()) then begin
    //
    sampling := max(1000, min(96000, str2intInt(c_comboBox_sampling.text, 8000)));
    bits := choice(c_checkBox_16bits.checked, 16, unsigned(8));
    channels := choice(c_checkBox_stereo.checked, 2, unsigned(1));
    //
    result := true;
  end
  else
    result := false;
end;


end.
