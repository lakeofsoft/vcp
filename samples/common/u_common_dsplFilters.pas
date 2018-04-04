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
  u_common_dsplFilters;

interface

uses
  Windows, unaTypes, unaClasses,
  unaDspLibH, unaDSPLibAutomation,
  Forms, ComCtrls, Classes, Controls, StdCtrls, Dialogs, ActnList, Menus;

type
  //
  Tc_from_dspFilters = class(TForm)
    c_button_add: TButton;
    c_button_drop: TButton;
    c_button_OK: TButton;
    c_tv_filters: TTreeView;
    c_button_load: TButton;
    c_button_save: TButton;
    c_od_filetrs: TOpenDialog;
    c_sd_filters: TSaveDialog;
    c_button_config: TButton;
    c_pm_filter: TPopupMenu;
    c_al_filter: TActionList;
    a_filter_add: TAction;
    a_filter_drop: TAction;
    a_filter_configure: TAction;
    a_config_load: TAction;
    a_config_saveAs: TAction;
    c_pmi_add: TMenuItem;
    c_pmi_drop: TMenuItem;
    c_pmi_config: TMenuItem;
    Label1: TLabel;
    //
    procedure formDestroy(sender: tObject);
    procedure formCloseQuery(sender: tObject; var canClose: boolean);
    //
    procedure a_filter_addExecute(sender: tObject);
    procedure a_filter_dropExecute(sender: tObject);
    procedure a_filter_configureExecute(sender: tObject);
    procedure a_config_loadExecute(sender: tObject);
    procedure a_config_saveAsExecute(sender: tObject);
    //
    procedure c_tv_filtersChange(sender: tObject; node: tTreeNode);
  private
    { Private declarations }
    f_automat: unaDSPLibAutomat;
    f_modified: bool;
    //
    function obj2params(obj: dspl_handle): string;
    procedure configToGUI(const config: string);
    function GUIToConfig(): string;
    procedure setObjParams(obj: dspl_handle; filterType: int; const filterParams: string);
  public
    { Public declarations }
    function configureFilters(root: unaDspLibAbstract; var config: string; allowLoadSave: bool = true): bool;
  end;

var
  c_from_dspFilters: Tc_from_dspFilters;


implementation


{$R *.dfm}

uses
  SysUtils, unaUtils, u_common_dsplFilterConfig;

{ Tc_from_dspFilters }

// --  --
function Tc_from_dspFilters.configureFilters(root: unaDspLibAbstract; var config: string; allowLoadSave: bool): bool;
begin
  c_button_load.visible := allowLoadSave;
  c_button_save.visible := allowLoadSave;
  //
  f_automat := unaDSPLibAutomat.create(root);
  try
    configToGUI(config);
    f_modified := false;
    //
    result := (mrOK = showModal());
    if (result) then
      config := GUIToConfig();
    //
  finally
    freeAndNil(f_automat);
  end;
end;

// --  --
procedure Tc_from_dspFilters.configToGUI(const config: string);
var
  i: int;
  obj: dspl_handle;
  objID: int;
begin
  if (nil <> f_automat) then begin
    //
    f_automat.automatLoad(config);
    //
    c_tv_filters.items.clear();
    //
    for i := 0 to f_automat.dspl_objCount - 1 do begin
      //
      obj := f_automat.dspl_objGet(i);
      if (DSPL_INVALID_HANDLE <> obj) then begin
	//
	objID := f_automat.root.getID(obj);
	if (0 < objID) then begin
	  //
	  c_tv_filters.items.addChild(c_tv_filters.items.addChildObject(nil, string(c_DSPL_OBJNAMES_FULL[objID]), pointer(obj)), string(obj2params(obj)));
	end
	else
	  c_tv_filters.items.addChild(nil, 'Unknown object type')
	//
      end;
    end;
  end;
end;

// --  --
function Tc_from_dspFilters.GUIToConfig(): string;
begin
  if (nil <> f_automat) then
    f_automat.automatSave(result)
  else
    result := '';
end;

// --  --
procedure Tc_from_dspFilters.formDestroy(sender: tObject);
begin
  freeAndNil(f_automat);
end;

// --  --
procedure Tc_from_dspFilters.formCloseQuery(sender: tObject; var canClose: boolean);
var
  res: int;
begin
  if (f_modified and (mrOK <> modalResult)) then begin
    //
    res := guiMessageBox(handle, 'Save changes you made to filter''s configuration?', 'Configuration was changed', MB_YESNOCANCEL or MB_ICONQUESTION);
    //
    if (ID_YES = res) then
      modalResult := mrOK;
    //
    canClose := (res in [ID_NO, ID_YES]);
  end;
end;

// --  --
function float2str(const f: dspl_float): string;
begin
  result := floatToStrF(f, ffGeneral, 7, 15);
end;

// --  --
function Tc_from_dspFilters.obj2params(obj: dspl_handle): string;
var
  objID: int;
  f: dspl_float;
  i: dspl_int;
begin
  result := '';
  objID := f_automat.root.getID(obj);
  if (0 < objID) then begin
    //
    case (objID) of

      DSPL_EQ2B: begin
	//
	f := f_automat.root.getf(obj, DSPL_PID or DSPL_P_FRQ or DSPL_EQ2B_BAND1);
	result := result + 'FRQ=' + float2str(f);
	//
	f := f_automat.root.getf(obj, DSPL_PID or DSPL_P_Q or DSPL_EQ2B_BAND1);
	result := result + '; Q=' + float2str(f);
	//
	f := v2db(f_automat.root.getf(obj, DSPL_PID or DSPL_P_GAIN or DSPL_EQ2B_BAND1));
	result := result + '; GAIN=' + float2str(f);
      end;

      DSPL_LD: begin
	//
	f := f_automat.root.getf(obj, DSPL_PID or DSPL_P_ATTACK);
	result := result + 'Attack=' + float2str(f);
	//
	f := f_automat.root.getf(obj, DSPL_PID or DSPL_P_RELEASE);
	result := result + '; Release=' + float2str(f);
      end;

      DSPL_DYNPROC: begin
	//
	f := f_automat.root.getf(obj, DSPL_PID or DSPL_P_ATTACK or DSPL_LD);
	result := result + 'Attack.LD=' + float2str(f);
	//
	f := f_automat.root.getf(obj, DSPL_PID or DSPL_P_RELEASE or DSPL_LD);
	result := result + '; Release.LD=' + float2str(f);
	//
	f := f_automat.root.getf(obj, DSPL_PID or DSPL_P_ATTACK);
	result := result + 'Attack=' + float2str(f);
	//
	f := f_automat.root.getf(obj, DSPL_PID or DSPL_P_RELEASE);
	result := result + '; Release=' + float2str(f);
      end;

      DSPL_SPEECHPROC: begin
	//
	f := f_automat.root.getf(obj, DSPL_PID or DSPL_P_THRESHOLD);
	result := result + 'Threshold=' + float2str(f);
      end;

      DSPL_ND: begin
	//
	f := f_automat.root.getf(obj, DSPL_PID or DSPL_P_THRESHOLD);
	result := result + 'Threshold=' + float2str(f);
      end;

      DSPL_EQMB: begin
	//
	i := f_automat.root.geti(obj, DSPL_PID or DSPL_P_OTHER);
	result := result + 'Number of bands=' + int2str(i);
      end;

      DSPL_MBSP: begin
	//
	i := f_automat.root.geti(obj, DSPL_PID or DSPL_P_OTHER);
	result := result + 'Number of bands=' + int2str(i);
      end;

    end;
  end;
end;

// --  --
procedure Tc_from_dspFilters.setObjParams(obj: dspl_handle; filterType: int; const filterParams: string);
var
  f: dspl_float;
  i: int;
begin
  case (f_automat.root.getId(obj)) of

    DSPL_EQ2B: begin
      //
      f_automat.dspl_obj_seti(obj, DSPL_PID or DSPL_P_TYPE or DSPL_EQ2B_BAND1, filterType);
      //
      f := strToFloat(formatTemplate('%P1%', filterParams, false));	// FRQ
      f_automat.dspl_obj_setf(obj, DSPL_PID or DSPL_P_FRQ or DSPL_EQ2B_BAND1, f);
      //
      f := strToFloat(formatTemplate('%P2%', filterParams, false));	// Q
      f_automat.dspl_obj_setf(obj, DSPL_PID or DSPL_P_Q or DSPL_EQ2B_BAND1, f);
      //
      f := strToFloat(formatTemplate('%P3%', filterParams, false));	// GAIN
      f_automat.dspl_obj_setf(obj, DSPL_PID or DSPL_P_GAIN or DSPL_EQ2B_BAND1, db2v(f));
    end;

    DSPL_LD: begin
      //
      f := strToFloat(formatTemplate('%P1%', filterParams, false));	// Attack
      f_automat.dspl_obj_setf(obj, DSPL_PID or DSPL_P_ATTACK,  f);
      //
      f := strToFloat(formatTemplate('%P2%', filterParams, false));	// Release
      f_automat.dspl_obj_setf(obj, DSPL_PID or DSPL_P_RELEASE, f);
    end;

    DSPL_DYNPROC: begin
      //
      f := strToFloat(formatTemplate('%P1%', filterParams, false));	// Attack LD
      f_automat.dspl_obj_setf(obj, DSPL_PID or DSPL_P_ATTACK or DSPL_LD,  f);
      //
      f := strToFloat(formatTemplate('%P2%', filterParams, false));	// Release LD
      f_automat.dspl_obj_setf(obj, DSPL_PID or DSPL_P_RELEASE or DSPL_LD, f);
      //
      f := strToFloat(formatTemplate('%P4%', filterParams, false));	// Attack
      f_automat.dspl_obj_setf(obj, DSPL_PID or DSPL_P_ATTACK,  f);
      //
      f := strToFloat(formatTemplate('%P5%', filterParams, false));	// Release
      f_automat.dspl_obj_setf(obj, DSPL_PID or DSPL_P_RELEASE, f);
    end;

    DSPL_SPEECHPROC: begin
      //
      f := strToFloat(formatTemplate('%P1%', filterParams, false));	// Threshold
      f_automat.dspl_obj_setf(obj, DSPL_PID or DSPL_P_THRESHOLD, db2v(f));
    end;

    DSPL_ND: begin
      //
      f := strToFloat(formatTemplate('%P1%', filterParams, false));	// Threshold
      f_automat.dspl_obj_setf(obj, DSPL_PID or DSPL_P_THRESHOLD, db2v(f));
    end;

    DSPL_EQMB: begin
      //
      i := str2intInt(formatTemplate('%P1%', filterParams, false), 1);	// Num. bands
      f_automat.dspl_obj_seti(obj, DSPL_PID or DSPL_P_OTHER, i);
    end;

    DSPL_MBSP: begin
      //
      i := str2intInt(formatTemplate('%P1%', filterParams, false), 1);	// Num. bands
      f_automat.dspl_obj_seti(obj, DSPL_PID or DSPL_P_OTHER, i);
    end;

  end;
end;

// --  --
procedure Tc_from_dspFilters.a_filter_addExecute(sender: tObject);
var
  obj: dspl_handle;
  objId: int;
  filterType: int;
  filterParams: string;
begin
  // add filter
  objId := DSPL_EQ2B;
  filterType := DSPL_EQ2B_PEAK;
  filterParams := 'EQ2B.FRQ'#9 + float2str(0.5) + #10 +
		  'EQ2B.Q'#9 + float2str(0.7) + #10 +
		  'EQ2B.GAIN'#9 + float2str(-6.0) + #10 +
		  'LD.ATT'#9 + int2str(20) + #10 +
		  'LD.REL'#9 + int2str(200) + #10 +
		  'SP.TRH'#9 + float2str(-30.0) + #10 +
		  'ND.TRH'#9 + float2str(-30.0) + #10 +
		  'EQMB.NBA'#9 + int2str(10) + #10 +
		  'MBSP.NBA'#9 + int2str(10);
  //
  if (c_form_dsplFilterConfig.selectFilter(objId, filterType, filterParams)) then begin
    //
    case (objId) of

      DSPL_EQ2B		: obj := f_automat.dspl_objNew(objId);
      DSPL_LD  		: obj := f_automat.dspl_objNew(objId);
      DSPL_DYNPROC	: obj := f_automat.dspl_objNew(objId);
      DSPL_SPEECHPROC	: obj := f_automat.dspl_objNew(objId);
      DSPL_ND		: obj := f_automat.dspl_objNew(objId);
      DSPL_EQMB		: obj := f_automat.dspl_objNew(objId);
      DSPL_MBSP		: obj := f_automat.dspl_objNew(objId);

      else		  obj := DSPL_INVALID_HANDLE;

    end;
    //
    if (DSPL_INVALID_HANDLE <> obj) then begin
      //
      setObjParams(obj, filterType, filterParams);
      //
      c_tv_filters.items.addChild(c_tv_filters.items.addChildObject(nil, string(c_DSPL_OBJNAMES_FULL[objId]), pointer(obj)), string(obj2params(obj)));
      //
      f_modified := true;
    end;
  end;
  //
end;

// --  --
procedure Tc_from_dspFilters.a_filter_dropExecute(sender: tObject);
var
  obj: dspl_handle;
begin
  // drop filter..
  if ((nil <> c_tv_filters.selected) and (nil = c_tv_filters.selected.parent)) then begin
    //
    if (ID_YES = guiMessageBox(handle, 'Really drop selected filter?', 'Confirm Filter Removal', MB_YESNOCANCEL or MB_ICONQUESTION)) then begin
      //
      obj := dspl_handle(c_tv_filters.selected.data);
      if ((DSPL_INVALID_HANDLE <> obj) and (0 <= f_automat.dspl_objIndex(obj))) then begin
	//
	f_automat.dspl_objDrop(f_automat.dspl_objIndex(obj));
	c_tv_filters.items.delete(c_tv_filters.selected);
	//
	f_modified := true;
      end;
    end;
  end;
end;

// --  --
procedure Tc_from_dspFilters.a_filter_configureExecute(sender: tObject);
var
  obj: dspl_handle;
  objID: int;
  filterType: int;
  filterParams: string;
  child: tTreeNode;
begin
  // configure filter..
  if ((nil <> c_tv_filters.selected) and (nil = c_tv_filters.selected.parent)) then begin
    //
    obj := dspl_handle(c_tv_filters.selected.data);
    if ((DSPL_INVALID_HANDLE <> obj) and (0 <= f_automat.dspl_objIndex(obj))) then begin
      //
      objID := f_automat.root.getID(obj);
      filterType := 0;
      filterParams := '';
      //
      case (objId) of

	DSPL_EQ2B: begin
	  //
	  filterType := f_automat.root.geti(obj, DSPL_PID or DSPL_P_TYPE or DSPL_EQ2B_BAND1);
	  //
	  filterParams := 'EQ2B.FRQ'#9 + float2str(f_automat.root.getf(obj, DSPL_PID or DSPL_P_FRQ or DSPL_EQ2B_BAND1)) + #10 +
			  'EQ2B.Q'#9 + float2str(f_automat.root.getf(obj, DSPL_PID or DSPL_P_Q or DSPL_EQ2B_BAND1)) + #10 +
			  'EQ2B.GAIN'#9 + float2str(v2db(f_automat.root.getf(obj, DSPL_PID or DSPL_P_GAIN or DSPL_EQ2B_BAND1)));
	  //
	end;

	DSPL_LD: begin
	  //
	  filterParams := 'LD.ATT'#9 + float2str(f_automat.root.getf(obj, DSPL_PID or DSPL_P_ATTACK)) + #10 +
			  'LD.REL'#9 + float2str(f_automat.root.getf(obj, DSPL_PID or DSPL_P_RELEASE));
	end;

	DSPL_DYNPROC: begin
	  //
	  filterParams := 'LD.ATT'#9 + float2str(f_automat.root.getf(obj, DSPL_PID or DSPL_P_ATTACK or DSPL_LD)) + #10 +
			  'LD.REL'#9 + float2str(f_automat.root.getf(obj, DSPL_PID or DSPL_P_RELEASE or DSPL_LD));
	end;

	DSPL_SPEECHPROC: begin
	  //
	  filterParams := 'SP.TRH'#9 + float2str(v2db(f_automat.root.getf(obj, DSPL_PID or DSPL_P_THRESHOLD)));
	end;

	DSPL_ND: begin
	  //
	  filterParams := 'ND.TRH'#9 + float2str(v2db(f_automat.root.getf(obj, DSPL_PID or DSPL_P_THRESHOLD)));
	end;

	DSPL_EQMB: begin
	  //
	  filterParams := 'EQMB.NBA'#9 + int2str(f_automat.root.geti(obj, DSPL_PID or DSPL_P_OTHER));
	end;

	DSPL_MBSP: begin
	  //
	  filterParams := 'MBSP.NBA'#9 + int2str(f_automat.root.geti(obj, DSPL_PID or DSPL_P_OTHER));
	end;

      end;
      //
      if (c_form_dsplFilterConfig.selectFilter(objID, filterType, filterParams)) then begin
	//
	setObjParams(obj, filterType, filterParams);
	//
	child := c_tv_filters.selected.getFirstChild();
	if (nil <> child) then
	  child.text := string(obj2params(obj));
	//
	f_modified := true;
      end;
      //
    end;
  end;
end;

// --  --
procedure Tc_from_dspFilters.a_config_loadExecute(sender: tObject);
var
  s: string;
begin
  // config -- load
  if (c_od_filetrs.Execute()) then begin
    //
     s := string(readFromFile(c_od_filetrs.fileName));
     if ('' <> s) then
       configToGUI(s);
     //
     f_modified := true;
  end;
end;

// --  --
procedure Tc_from_dspFilters.a_config_saveAsExecute(sender: tObject);
var
  config: string;
begin
  // config -- save as
  if (c_sd_filters.Execute()) then begin
    //
    config := GUIToConfig();
    //
    fileDelete(c_sd_filters.fileName);
    //
    writeToFile(c_sd_filters.fileName, aString(config));
  end;
end;

// --  --
procedure Tc_from_dspFilters.c_tv_filtersChange(sender: tObject; node: tTreeNode);
begin
  a_filter_configure.enabled := (nil <> node) and (nil = node.parent);
  a_filter_drop.enabled := a_filter_configure.enabled;
end;


end.

