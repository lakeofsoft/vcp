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


// DSP Lib Automation GUI
// Copyright (c) 2006-2007 Lake of Soft

{$i unaDef.inc }

unit
  u_common_dsplFilterConfig;

interface

uses
  Windows, unaTypes,
  Forms, StdCtrls, Controls, Classes;

type
  Tc_form_dsplFilterConfig = class(TForm)
    c_cb_filter: TComboBox;
    c_label_filter: TLabel;
    c_button_cancel: TButton;
    c_button_ok: TButton;
    c_cb_filterType: TComboBox;
    c_label_filterType: TLabel;
    c_edit_1: TEdit;
    c_edit_2: TEdit;
    c_edit_3: TEdit;
    c_label_1: TLabel;
    c_label_2: TLabel;
    c_label_3: TLabel;
    c_label_4: TLabel;
    c_label_5: TLabel;
    Edit1: TEdit;
    Edit2: TEdit;
    c_label_6: TLabel;
    Edit3: TEdit;
    Label1: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure c_cb_filterChange(Sender: TObject);
  private
    { Private declarations }
    f_params: string;
  public
    { Public declarations }
    function selectFilter(var objId, filterType: int; var params: string): bool;
  end;

var
  c_form_dsplFilterConfig: Tc_form_dsplFilterConfig;


implementation


{$R *.dfm}

uses
  unaDspLibH, unaUtils;

// --  --
procedure Tc_form_dsplFilterConfig.FormCreate(Sender: TObject);
var
  i: int;
begin
  for i := DSPL_EQ2B to DSPL_MBSP do
    c_cb_filter.items.add(string(c_DSPL_OBJNAMES_FULL[i] + ' - ' + c_DSPL_OBJNAMES_SHORT[i]));
  //
  c_cb_filter.itemIndex := 0;
end;


procedure Tc_form_dsplFilterConfig.c_cb_filterChange(Sender: TObject);
begin
  case (c_cb_filter.itemIndex) of

    0: begin	// EQ2B
      //
      c_cb_filterType.items.clear();
      //
      c_cb_filterType.items.add('Off');
      c_cb_filterType.items.add('PEAK');
      c_cb_filterType.items.add('Low-Pass');
      c_cb_filterType.items.add('High Pass');
      c_cb_filterType.items.add('Low Shelf');
      c_cb_filterType.items.add('High Shelf');
      //
      c_cb_filterType.itemIndex := 1;
      c_cb_filterType.visible := true;
      //
      c_label_1.caption := 'F&requency (0 .. 1)';
      c_label_2.caption := '&Q factor (0.1 .. 10)';
      c_label_3.caption := '&Gain/Boost (dB)';
      //
      c_edit_1.visible := true;
      c_edit_2.visible := true;
      c_edit_3.visible := true;
      //
      c_edit_1.text := formatTemplate('%EQ2B.FRQ%', f_params, false);
      c_edit_2.text := formatTemplate('%EQ2B.Q%', f_params, false);
      c_edit_3.text := formatTemplate('%EQ2B.GAIN%', f_params, false);
    end;

    1: begin	// LD
      //
      c_cb_filterType.items.clear();
      //
      c_cb_filterType.items.add('PEAK');
      c_cb_filterType.items.add('RMS');
      //
      c_cb_filterType.itemIndex := 0;
      c_cb_filterType.visible := true;
      //
      c_label_1.caption := '&Attack (samples)';
      c_label_2.caption := '&Release (samples)';
      c_label_3.caption := '';
      //
      c_edit_1.visible := true;
      c_edit_2.visible := true;
      c_edit_3.visible := false;
      //
      c_edit_1.text := formatTemplate('%LD.ATT%', f_params, false);
      c_edit_2.text := formatTemplate('%LD.REL%', f_params, false);
    end;

    2: begin	// DYNPROC
      //
      c_cb_filterType.items.clear();
      //
      c_cb_filterType.items.add('LD - PEAK');
      c_cb_filterType.items.add('LD - RMS');
      //
      c_cb_filterType.itemIndex := 0;
      c_cb_filterType.visible := true;
      //
      c_label_1.caption := 'LD - &Attack (samples)';
      c_label_2.caption := 'LD - &Release (samples)';
      c_label_3.caption := '';
      //
      c_edit_1.visible := true;
      c_edit_2.visible := true;
      c_edit_3.visible := false;
      //
      c_edit_1.text := formatTemplate('%LD.ATT%', f_params, false);
      c_edit_2.text := formatTemplate('%LD.REL%', f_params, false);
    end;

    3: begin	// SPEECHPROC
      c_cb_filterType.items.clear();
      //
      c_cb_filterType.items.add('LD - PEAK');
      c_cb_filterType.items.add('LD - RMS');
      //
      c_cb_filterType.itemIndex := 0;
      c_cb_filterType.visible := true;
      //
      c_label_1.caption := 'LD - &Attack (samples)';
      c_label_2.caption := 'LD - &Release (samples)';
      c_label_3.caption := '&Threshold (dB)';
      //
      c_edit_1.visible := true;
      c_edit_2.visible := true;
      c_edit_3.visible := true;
      //
      c_edit_1.text := formatTemplate('%LD.ATT%', f_params, false);
      c_edit_2.text := formatTemplate('%LD.REL%', f_params, false);
      c_edit_3.text := formatTemplate('%SP.TRH%', f_params, false);
    end;

    4: begin	// ND
      c_cb_filterType.items.clear();
      c_cb_filterType.visible := false;
      //
      c_label_1.caption := '&Threshold';
      c_label_2.caption := '';
      c_label_3.caption := '';
      //
      c_edit_1.visible := true;
      c_edit_2.visible := false;
      c_edit_3.visible := false;
      //
      c_edit_1.text := formatTemplate('%ND.TRH%', f_params, false);
    end;

    5: begin	// EQMB
      c_cb_filterType.items.clear();
      c_cb_filterType.visible := false;
      //
      c_label_1.caption := 'Number of bands';
      c_label_2.caption := '';
      c_label_3.caption := '';
      //
      c_edit_1.visible := true;
      c_edit_2.visible := false;
      c_edit_3.visible := false;
      //
      c_edit_1.text := formatTemplate('%EQMB.NBA%', f_params, false);
    end;

    6: begin	// MBSP
      c_cb_filterType.items.clear();
      c_cb_filterType.visible := false;
      //
      c_label_1.caption := 'Number of bands';
      c_label_2.caption := '';
      c_label_3.caption := '';
      //
      c_edit_1.visible := true;
      c_edit_2.visible := false;
      c_edit_3.visible := false;
      //
      c_edit_1.text := formatTemplate('%MBSP.NBA%', f_params, false);
    end;

    else begin
      // uknown
      c_cb_filterType.items.clear();
      c_cb_filterType.visible := false;
      //
      c_label_1.caption := '';
      c_label_2.caption := '';
      c_label_3.caption := '';
      //
      c_edit_1.visible := false;
      c_edit_2.visible := false;
      c_edit_3.visible := false;
    end;

  end;
  //
  c_label_filterType.visible := c_cb_filterType.visible;
end;

// --  --
function Tc_form_dsplFilterConfig.selectFilter(var objId, filterType: int; var params: string): bool;
begin
  f_params := params;
  c_cb_filter.itemIndex := objId - 1;
  c_cb_filterChange(self);
  //
  c_cb_filterType.itemIndex := filterType;
  //
  result := mrOK = showModal();
  if (result) then begin
    //
    objId := c_cb_filter.itemIndex + 1;
    filterType := c_cb_filterType.itemIndex;
    //
    params := 'P1'#9 + c_edit_1.text + #10 +
	      'P2'#9 + c_edit_2.text + #10 +
	      'P3'#9 + c_edit_3.text + #10;
    //
  end;
end;


end.

