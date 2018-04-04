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

	  u_common_audioConfig.pas
	  VC components 2.5 Pro - audio configuration form

	----------------------------------------------
	  Copyright (c) 2003-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 19 Feb 2003

	  modified by:
		Lake, Feb-Oct 2003
		Lake, May-Oct 2005
		Lake, Apr-Dec 2007
		Lake, Jun 2008
		Lake, Feb-May 2009
		Lake, Feb 2010

	----------------------------------------------
*)

{$I unaDef.inc }

{*
	Configures wave audio devices and audio codecs.

	@Author Lake
	@Version 2.5.2009.06-17
	 * Default is now to include wavemapper into enumeration

	@Version 2.5.2010.02
	 + support for 3GPP VAD added;
}

unit
  u_common_audioConfig;

interface

uses
  Windows, unaTypes, MMSystem, unaClasses, unaMsAcmAPI, unaMsAcmClasses, unaMsMixer,
  unaVC_wave,
  Forms, StdCtrls, Controls, ExtCtrls, Classes, Dialogs;


const
  //----
  //
  c_strDefSection	= 'waveAudio';


type
  //
  // --  --
  //
  pdriverDesc = ^tdriverDesc;
  tdriverDesc = packed record
    //
    r_valid: bool;
    r_mode: unaAcmCodecDriverMode;
    r_library: wideString;
    r_formatIndex: int32;
  end;

  //
  // --  --
  //
  pinOutDriverDesc = ^tinOutDriverDesc;
  tinOutDriverDesc = packed record
    //
    r_in: tdriverDesc;
    r_out: tdriverDesc;
  end;

  //
  // --  --
  //
  Tc_form_common_audioConfig = class(TForm)
    c_label_inDevice: TLabel;
    c_label_inTitle: TLabel;
    c_bevel_top: TBevel;
    c_comboBox_waveIn: TComboBox;
    c_label_inFormat: TLabel;
    c_label_outTitle: TLabel;
    c_bevel_middle: TBevel;
    c_button_OK: TButton;
    c_bevel_bottom: TBevel;
    c_button_cancel: TButton;
    c_edit_inFormat: TEdit;
    c_button_inFormatBrowse: TButton;
    c_label_outDevice: TLabel;
    c_comboBox_waveOut: TComboBox;
    c_label_outFormat: TLabel;
    c_edit_outFormat: TEdit;
    c_button_outFormatBrowse: TButton;
    c_button_configAudio: TButton;
    c_button_inVolControl: TButton;
    c_button_outVolControl: TButton;
    c_comboBox_inCodecMode: TComboBox;
    c_label_inDriverMode: TLabel;
    c_comboBox_outCodecMode: TComboBox;
    c_label_outDriverMode: TLabel;
    c_comboBox_inCodecTag: TComboBox;
    c_comboBox_outCodecTag: TComboBox;
    c_openDialog_lib: TOpenDialog;
    c_label_inCodecFT: TLabel;
    c_label_outCodecFT: TLabel;
    c_cb_vad: TComboBox;
    Label1: TLabel;
    //
    procedure formCreate(sender: tObject);
    procedure formDestroy(sender: tObject);
    //
    procedure c_button_inFormatBrowseClick(sender: tObject);
    procedure c_button_outFormatBrowseClick(sender: tObject);
    procedure c_button_configAudioClick(sender: tObject);
    procedure c_button_inVolControlClick(sender: tObject);
    procedure c_button_outVolControlClick(sender: tObject);
    procedure c_comboBox_inCodecModeChange(Sender: TObject);
    procedure c_comboBox_outCodecModeChange(Sender: TObject);
    procedure c_comboBox_waveInChange(Sender: TObject);
    procedure c_comboBox_waveOutChange(Sender: TObject);
    procedure c_comboBox_inCodecTagChange(Sender: TObject);
    procedure c_comboBox_outCodecTagChange(Sender: TObject);
    procedure c_cb_vadChange(Sender: TObject);
  private
    { Private declarations }
    f_config: unaIniAbstractStorage;
    f_section: string;
    f_enumComplete: bool;
    //
    f_includeMapper: bool;
    f_syncInOutFormat: bool;
    f_allowModeChange: bool;
    //
    f_waveInSDMode: unaWaveInSDMethods;
    f_waveInId: int;
    f_waveOutId: int;
    f_inOutDriver: tinOutDriverDesc;
    //
    f_formatInExt: PWAVEFORMATEXTENSIBLE;
    f_formatOutExt: PWAVEFORMATEXTENSIBLE;
    f_formatIn_nonPCMOK: bool;
    f_formatOut_nonPCMOK: bool;
    //
    f_maxFormatSize: unsigned;
    //
    f_mixer: unaMsMixerSystem;
    f_enumFlags: int;
    f_enumFormatExt: PWAVEFORMATEXTENSIBLE;
    //
    f_defFTIn: int;
    f_defFTOut: int;
    //
    f_hideShowGUIdone: bool;
    //
    function doLoadFormat(var format: PWAVEFORMATEXTENSIBLE; const key: string; defFormatTag: int): int;
    function doFormatChoose(var format: pWAVEFORMATEX; var title: wString): int;
    procedure loadConfig(doLoad: bool);
    procedure saveConfig();
    //
    function do_load_Config(doLoad: bool; waveIn: unavclWaveInDevice; waveOut: unavclWaveOutDevice; codecIn, codecOut: unavclWaveCodecDevice; config: unaIniAbstractStorage; const section: string; doShow: bool = true; doLoadInConfig: bool = true): HRESULT;
    function do_config(doShow: bool; var waveInId, waveOutId: int; var formatIn, formatOut: pWAVEFORMATEX; var inOutDriver: tinOutDriverDesc; config: unaIniAbstractStorage; const section: string; var sdMode: unaWaveInSDMethods): HRESULT; overload;
    function do_config(doShow: bool; doLoad: bool = true): HRESULT; overload;
    //
    function doConfig(config: unaIniAbstractStorage; const section: string; doShow: bool = true; doLoad: bool = true): HRESULT; overload;
    function doLoadConfig(config: unaIniAbstractStorage; const section: string): HRESULT; overload;
    //
    procedure enumWaveDevices();
    procedure hideShowGUI(waveIn, codecIn, waveOut, codecOut: bool);
    //
    procedure showCodecTags(inCodec: bool);
    procedure setEnumFormat(value: PWAVEFORMATEXTENSIBLE);
  public
    { Public declarations }
    //
    {*
      WARNING! If you allocate formatIn or formatOut manually, make sure they are large enough to store _any_ ACM format.
	       Assign nil otherwise.
    }
    function doConfig(var waveInId, waveOutId: int; var formatIn, formatOut: pWAVEFORMATEX; var inOutDriver: tinOutDriverDesc; var sdMode: unaWaveInSDMethods; config: unaIniAbstractStorage; const section: string = c_strDefSection): HRESULT; overload;
    function doConfig(waveIn: unavclWaveInDevice; waveOut: unavclWaveOutDevice; codecIn, codecOut: unavclWaveCodecDevice; config: unaIniAbstractStorage; const section: string = c_strDefSection; doShow: bool = true; doLoad: bool = true): HRESULT; overload;
    function doLoadConfig(var waveInId, waveOutId: int; var formatIn, formatOut: pWAVEFORMATEX; var inOutDriver: tinOutDriverDesc; var sdMode: unaWaveInSDMethods; config: unaIniAbstractStorage; const section: string = c_strDefSection): HRESULT; overload;
    function doLoadConfig(waveIn: unavclWaveInDevice; waveOut: unavclWaveOutDevice; codecIn, codecOut: unavclWaveCodecDevice; config: unaIniAbstractStorage; const section: string = c_strDefSection): HRESULT; overload;
    procedure doSaveConfig(waveIn: unavclWaveInDevice; waveOut: unavclWaveOutDevice; codecIn, codecOut: unavclWaveCodecDevice; config: unaIniAbstractStorage; const section: string = c_strDefSection);
    //
    procedure setupUI(syncInOutFormat: bool; includeMapper: bool = true; allowModeChange: bool = true);
    //
    {*
	NOTE: You must reallocate and initializate enumFormatExt properly if enumFlags <> 0.
    }
    property enumFlags: int read f_enumFlags write f_enumFlags;
    property enumFormatExt: PWAVEFORMATEXTENSIBLE read f_enumFormatExt write setEnumFormat;
  end;


var
  c_form_common_audioConfig: Tc_form_common_audioConfig;


implementation


{$R *.dfm}

uses
  unaOpenH323PluginAPI, unaUtils, unaVCIDEutils;


// --  --
function driverMode2index(mode: unaAcmCodecDriverMode): int;
begin
  case (mode) of

     unacdm_acm:
       result := 0;

     unacdm_openH323plugin:
       result := 1;

     else
       result := -1;

  end;
end;

// --  --
function index2driverMode(index: int): unaAcmCodecDriverMode;
begin
  case (index) of

    0: result := unacdm_acm;

    1: result := unacdm_openH323plugin;

    else
      result := unacdm_internal;

  end;
end;


{ Tc_form_common_audioConfig }

// --  --
procedure Tc_form_common_audioConfig.formCreate(sender: tObject);
begin
  f_maxFormatSize := getMaxWaveFormatSize();
  //
  f_mixer := unaMsMixerSystem.create(false);
  //
  f_enumComplete := false;
  //
  enumFlags := 0;
  f_enumFormatExt := nil;
  f_includeMapper := true;
end;

// --  --
procedure Tc_form_common_audioConfig.formDestroy(sender: tObject);
begin
  mrealloc(f_enumFormatExt);
  mrealloc(f_formatInExt);
  mrealloc(f_formatOutExt);
  //
  freeAndNil(f_mixer);
end;

// --  --
function Tc_form_common_audioConfig.do_config(doShow, doLoad: bool): HRESULT;
var
  ok: bool;
begin
  if (0 = f_defFTIn) then begin
    //
    if (nil <> f_formatInExt) then
      f_defFTIn := getFormatTagExt(f_formatInExt)
    else
      f_defFTIn := WAVE_FORMAT_PCM;
  end;
  //
  if (0 = f_defFTOut) then begin
    //
    if (nil <> f_formatOutExt) then
      f_defFTOut := getFormatTagExt(f_formatOutExt)
    else
      f_defFTOut := WAVE_FORMAT_PCM;
  end;
  //
  if (doShow) then
    hideShowGUI(true, true, true, not f_syncInOutFormat);
  //
  loadConfig(doLoad);
  //
  if (doShow) then
    ok := (mrOK = showModal())
  else
    ok := true;
  //
  if (ok and doShow) then
    saveConfig();
  //
  if (ok) then
    result := S_OK
  else
    result := HRESULT(-1);
end;

// --  --
function Tc_form_common_audioConfig.do_config(doShow: bool; var waveInId, waveOutId: int; var formatIn, formatOut: pWAVEFORMATEX; var inOutDriver: tinOutDriverDesc; config: unaIniAbstractStorage; const section: string; var sdMode: unaWaveInSDMethods): HRESULT;
begin
  f_config := config;
  f_section := section;
  //
  f_waveInId  := waveInId;
  f_waveInSDMode := sdMode;
  f_waveOutId := waveOutId;
  fillFormatExt(f_formatInExt, formatIn);
  //
  if (doShow) then
    hideShowGUI(true, true, true, not f_syncInOutFormat);
  //
  if (not f_syncInOutFormat) then
    fillFormatExt(f_formatOutExt, formatOut);
  //
  f_inOutDriver := inOutDriver;
  //
  result := do_config(doShow);
  //
  if (Succeeded(result)) then begin
    //
    waveInId  := f_waveInId;
    waveOutId := f_waveOutId;
    sdMode := f_waveInSDMode;
    //
    //mrealloc(formatIn);
    waveExt2wave(f_formatInExt, formatIn);
    if (not f_syncInOutFormat) then begin
      //
      //mrealloc(formatOut);
      waveExt2wave(f_formatOutExt, formatOut);
    end;
    //
    inOutDriver := f_inOutDriver;
  end;
end;

// --  --
function Tc_form_common_audioConfig.do_load_Config(doLoad: bool; waveIn: unavclWaveInDevice; waveOut: unavclWaveOutDevice; codecIn, codecOut: unavclWaveCodecDevice; config: unaIniAbstractStorage; const section: string; doShow, doLoadInConfig: bool): HRESULT;
begin
  if (nil <> waveIn) then begin
    //
    f_waveInId := int(waveIn.deviceId);
    f_waveInSDMode := waveIn.silenceDetectionMode;
  end
  else begin
    //
    f_waveInId := -1;
    f_waveInSDMode := unasdm_none;
  end;
  //
  if (nil <> waveOut) then
    f_waveOutId := int(waveOut.deviceId)
  else
    f_waveOutId := -1;
  //
  if (0 = f_defFTIn) then begin
    //
    if (nil <> codecIn) then
      f_defFTIn := codecIn.formatTag
    else
      f_defFTIn := WAVE_FORMAT_PCM;
  end;
  //
  if (0 = f_defFTOut) then begin
    //
    if (nil <> codecOut) then
      f_defFTOut := codecOut.formatTag
    else
      f_defFTOut := WAVE_FORMAT_PCM;
  end;
  //
  f_formatInExt := nil;
  f_formatOutExt := nil;
  //
  if (nil <> codecIn) then begin
    //
    f_inOutDriver.r_in.r_mode := codecIn.driverMode;
    f_inOutDriver.r_in.r_library := codecIn.driverLibrary;
    f_inOutDriver.r_in.r_formatIndex := int(codecIn.formatTag);
    f_inOutDriver.r_in.r_valid := true;
  end
  else
    f_inOutDriver.r_in.r_valid := false;
  //
  if (nil <> codecOut) then begin
    //
    f_inOutDriver.r_out.r_mode := codecOut.driverMode;
    f_inOutDriver.r_out.r_library := codecOut.driverLibrary;
    f_inOutDriver.r_out.r_formatIndex := int(codecOut.formatTag);
    f_inOutDriver.r_out.r_valid := true;
  end
  else
    f_inOutDriver.r_out.r_valid := false;
  //
  hideShowGUI((nil <> waveIn), (nil <> codecIn), (nil <> waveOut), (nil <> codecOut));
  //
  if (doLoad) then
    result := doLoadConfig(config, section)
  else
    result := doConfig(config, section, doShow, doLoadInConfig);
  //
  if (Succeeded(result)) then begin
    //
    if (nil <> waveIn) then begin
      //
      waveIn.deviceId := f_waveInId;
      waveIn.silenceDetectionMode := f_waveInSDMode;
    end;
    //
    if (nil <> waveOut) then
      waveOut.deviceId := f_waveOutId;
    //
    if ((nil <> f_formatInExt) and f_inOutDriver.r_in.r_valid) then begin
      //
      case (f_inOutDriver.r_in.r_mode) of

	unacdm_acm: begin
	  //
	  codecIn.driverMode := f_inOutDriver.r_in.r_mode;
	  //
	  if (f_formatIn_nonPCMOK) then
	    codecIn.setNonPCMFormat(f_formatInExt)
	  else begin
	    //
	    // 11 APR 2007: bug, thanks to dayde for pointing it out
	    //
	    fillPCMFormatExt(f_formatInExt, f_formatInExt.Format.nSamplesPerSec, 0, f_formatInExt.format.wBitsPerSample, f_formatInExt.format.nChannels); 
	    //
	    codecIn.formatTag := WAVE_FORMAT_PCM;
	    codecIn.pcmFormatExt := f_formatInExt;
	  end;
	end;

	unacdm_openH323plugin: begin
	  //
          f_inOutDriver.r_in.r_formatIndex := c_comboBox_inCodecTag.itemIndex;
	  //
	  // in this order: 1) mode; 2) lib; 3) tag
	  codecIn.driverMode := f_inOutDriver.r_in.r_mode;
	  codecIn.driverLibrary := f_inOutDriver.r_in.r_library;
	  if (0 <= f_inOutDriver.r_in.r_formatIndex) then
	    codecIn.formatTag := f_inOutDriver.r_in.r_formatIndex;
	  //  
	end;

      end;	// case
      //
      if (nil <> waveIn) then
	waveIn.pcmFormatExt := codecIn.pcmFormatExt;
    end
    else
      if ((nil <> waveIn) and (nil <> f_formatInExt)) then
	waveIn.pcmFormatExt := f_formatInExt;
    //
    mrealloc(f_formatInExt);
    //
    if ((nil <> f_formatOutExt) and f_inOutDriver.r_out.r_valid) then begin
      //
      case (f_inOutDriver.r_out.r_mode) of

	unacdm_acm: begin
	  //
	  codecIn.driverMode := f_inOutDriver.r_out.r_mode;
	  //
	  if (f_formatOut_nonPCMOK) then
	    codecOut.setNonPCMFormat(f_formatOutExt)
	  else begin
	    //
	    codecOut.formatTag := getFormatTagExt(f_formatOutExt);
	    fillPCMFormatExt(f_formatOutExt, f_formatOutExt.format.nSamplesPerSec, 0, f_formatOutExt.format.wBitsPerSample, f_formatOutExt.format.nChannels);
	    codecOut.pcmFormatExt := f_formatOutExt;
	  end;
	end;

	unacdm_openH323plugin: begin
	  //
          f_inOutDriver.r_out.r_formatIndex := c_comboBox_outCodecTag.itemIndex;
          //
	  // in this order: 1) mode; 2) lib; 3) tag
	  codecOut.driverMode := f_inOutDriver.r_out.r_mode;
	  codecOut.driverLibrary := f_inOutDriver.r_out.r_library;
	  codecOut.formatTag := f_inOutDriver.r_out.r_formatIndex;
	end;

      end;	// case () ...
      //
      if (nil <> waveOut) then
	waveOut.pcmFormatExt := codecOut.pcmFormatExt;
    end
    else
      if ((nil <> waveOut) and (nil <> f_formatOutExt)) then
	waveOut.pcmFormatExt := f_formatOutExt;
    //
    mrealloc(f_formatOutExt);
  end;
end;

// --  --
function Tc_form_common_audioConfig.doConfig(config: unaIniAbstractStorage; const section: string; doShow, doLoad: bool): HRESULT;
begin
  // FT OK
  f_config := config;
  f_section := section;
  //
  result := do_config(doShow, doLoad);
  //
  f_defFTIn := 0;
  f_defFTOut := 0;
end;

// --  --
function Tc_form_common_audioConfig.doConfig(var waveInId, waveOutId: int; var formatIn, formatOut: pWAVEFORMATEX; var inOutDriver: tinOutDriverDesc; var sdMode: unaWaveInSDMethods; config: unaIniAbstractStorage; const section: string): HRESULT;
begin
  f_hideShowGUIdone := false;
  // FT OK
  result := do_config(true, waveInId, waveOutId, formatIn, formatOut, inOutDriver, config, section, sdMode);
  //
  f_defFTIn := 0;
  f_defFTOut := 0;
end;

// --  --
function Tc_form_common_audioConfig.doConfig(waveIn: unavclWaveInDevice; waveOut: unavclWaveOutDevice; codecIn, codecOut: unavclWaveCodecDevice; config: unaIniAbstractStorage; const section: string; doShow, doLoad: bool): HRESULT;
begin
  f_hideShowGUIdone := false;
  // FT OK
  result := do_load_Config(false, waveIn, waveOut, codecIn, codecOut, config, section, doShow, doLoad);
  //
  f_defFTIn := 0;
  f_defFTOut := 0;
end;

// --  --
function Tc_form_common_audioConfig.doLoadConfig(var waveInId, waveOutId: int; var formatIn, formatOut: pWAVEFORMATEX; var inOutDriver: tinOutDriverDesc; var sdMode: unaWaveInSDMethods; config: unaIniAbstractStorage; const section: string): HRESULT;
begin
  f_hideShowGUIdone := false;
  // FT OK
  result := do_config(false, waveInId, waveOutId, formatIn, formatOut, inOutDriver, config, section, sdMode);
  //
  f_defFTIn := 0;
  f_defFTOut := 0;
end;

// --  --
function Tc_form_common_audioConfig.doLoadConfig(waveIn: unavclWaveInDevice; waveOut: unavclWaveOutDevice; codecIn, codecOut: unavclWaveCodecDevice; config: unaIniAbstractStorage; const section: string): HRESULT;
begin
  f_hideShowGUIdone := false;
  // FT OK
  result := do_load_Config(true, waveIn, waveOut, codecIn, codecOut, config, section);
  //
  f_defFTIn := 0;
  f_defFTOut := 0;
end;

// --  --
function Tc_form_common_audioConfig.doLoadConfig(config: unaIniAbstractStorage; const section: string): HRESULT;
begin
  // FT OK
  f_config := config;
  f_section := section;
  //
  result := do_config(false);
  //
  f_defFTIn := 0;
  f_defFTOut := 0;
end;

// --  --
function Tc_form_common_audioConfig.doLoadFormat(var format: PWAVEFORMATEXTENSIBLE; const key: string; defFormatTag: int): int;
var
  formatStr: string;
  fmt: WAVEFORMATEX;
begin
  result := 1;
  //
  formatStr := trimS(f_config.get(f_section, key, ''));
  if ('' <> formatStr) then
    str2waveFormatExt(formatStr, format)
  else begin
    //
    if (nil = enumFormatExt) then begin
      //
      fillPCMFormat(fmt, c_defSamplingSamplesPerSec, c_defSamplingBitsPerSample, c_defSamplingNumChannels);
      fillFormatExt(format, @fmt);
    end
    else
      duplicateFormat(enumFormatExt, format);
    //
  end;
end;

// --  --
procedure Tc_form_common_audioConfig.doSaveConfig(waveIn: unavclWaveInDevice; waveOut: unavclWaveOutDevice; codecIn, codecOut: unavclWaveCodecDevice; config: unaIniAbstractStorage; const section: string);
begin
  do_load_Config(false, waveIn, waveOut, codecIn, codecOut, config, section, false, false);
  //
  saveConfig();
end;

// --  --
procedure Tc_form_common_audioConfig.loadConfig(doLoad: bool);
var
  sec: string;
  fmt: pWAVEFORMATEX;
begin
  enumWaveDevices();
  //
  if (f_config.enter(f_section, sec, 100)) then begin
    //
    try
      // load configuration
      c_comboBox_waveIn.itemIndex  := integer(choice(doLoad, f_config.get('wave.in.deviceIdIndex',  deviceId2index(f_waveInId, f_includeMapper)), deviceId2index(f_waveInId, f_includeMapper)));
      f_waveInId := index2deviceId(c_comboBox_waveIn);
      c_comboBox_waveOut.itemIndex := integer(choice(doLoad, f_config.get('wave.out.deviceIdIndex', deviceId2index(f_waveOutId, f_includeMapper)), deviceId2index(f_waveOutId, f_includeMapper)));
      f_waveOutId := index2deviceId(c_comboBox_waveOut);
      //
      c_comboBox_inCodecMode.itemIndex  := choice(doLoad, f_config.get('codec.in.driverModeIndex', driverMode2index(f_inOutDriver.r_in.r_mode)), driverMode2index(f_inOutDriver.r_in.r_mode));
      f_inOutDriver.r_in.r_mode := index2driverMode(c_comboBox_inCodecMode.itemIndex);
      //
      if (unacdm_openH323plugin = f_inOutDriver.r_in.r_mode) then
	f_inOutDriver.r_in.r_formatIndex := choice(doLoad, f_config.get('codec.in.formatIndex', f_inOutDriver.r_in.r_formatIndex), f_inOutDriver.r_in.r_formatIndex)
      else
	f_inOutDriver.r_in.r_formatIndex := choice(doLoad, f_config.get('codec.in.formatTag', f_inOutDriver.r_in.r_formatIndex), f_inOutDriver.r_in.r_formatIndex);
      //
      f_inOutDriver.r_in.r_library := choice(doLoad, f_config.get('codec.in.driverLib', f_inOutDriver.r_in.r_library), f_inOutDriver.r_in.r_library);
      //
      f_waveInSDMode := unaWaveInSDMethods( choice(doLoad, f_config.get('wave.in.sd.mode', ord(f_waveInSDMode)), ord(f_waveInSDMode)) );
      case (f_waveInSDMode) of

	unasdm_none: c_cb_vad.itemIndex := 0;
	unasdm_VC  : c_cb_vad.itemIndex := 1;
	unasdm_DSP : c_cb_vad.itemIndex := 2;
	unasdm_3GPPVAD1: c_cb_vad.itemIndex := 3;

      end;
      //c_cb_vadChange(self);
      //
      showCodecTags(true);
      //
      if (not f_syncInOutFormat) then begin
	//
	c_comboBox_outCodecMode.itemIndex := choice(doLoad, f_config.get('codec.out.driverModeIndex', driverMode2index(f_inOutDriver.r_out.r_mode)), driverMode2index(f_inOutDriver.r_out.r_mode));
	f_inOutDriver.r_out.r_mode := index2driverMode(c_comboBox_outCodecMode.itemIndex);
	//
	if (unacdm_openH323plugin = f_inOutDriver.r_out.r_mode) then
	  f_inOutDriver.r_out.r_formatIndex := choice(doLoad, f_config.get('codec.out.formatIndex', f_inOutDriver.r_out.r_formatIndex), f_inOutDriver.r_out.r_formatIndex)
	else
	  f_inOutDriver.r_out.r_formatIndex := choice(doLoad, f_config.get('codec.out.formatTag', f_inOutDriver.r_out.r_formatIndex), f_inOutDriver.r_out.r_formatIndex);
	//
	f_inOutDriver.r_out.r_library := choice(doLoad, f_config.get('codec.out.driverLib', f_inOutDriver.r_out.r_library), f_inOutDriver.r_out.r_library);
	//
	showCodecTags(false);
      end
      else
	c_comboBox_outCodecMode.itemIndex := c_comboBox_inCodecMode.itemIndex;
      //
    finally
      f_config.leave(sec);
    end;
  end;
  //
  fmt := nil;
  try
    f_formatIn_nonPCMOK := (1 = doLoadFormat(f_formatInExt, 'wave.in.formatExt', f_defFTIn));
    waveExt2wave(f_formatInExt, fmt);
    //
    if (unacdm_openH323plugin = f_inOutDriver.r_in.r_mode) then begin
      //
      c_edit_inFormat.text := f_inOutDriver.r_in.r_library;
    end
    else begin
      //
      if (nil <> fmt) then
	c_edit_inFormat.text := format2str(fmt^);
    end;
    //
    if (not f_syncInOutFormat) then begin
      //
      f_formatOut_nonPCMOK := (1 = doLoadFormat(f_formatOutExt, 'wave.out.formatExt', f_defFTOut));
      waveExt2wave(f_formatOutExt, fmt);
      if (unacdm_openH323plugin = f_inOutDriver.r_out.r_mode) then begin
	//
	c_edit_outFormat.text := f_inOutDriver.r_out.r_library;
      end
      else begin
	//
	if (nil <> fmt) then
	  c_edit_outFormat.text := format2str(fmt^);
      end;
    end
    else
      c_edit_outFormat.text := c_edit_inFormat.text;
    //
  finally
    mrealloc(fmt);
  end;
end;

// --  --
procedure Tc_form_common_audioConfig.saveConfig();
var
  sec: string;
begin
  enumWaveDevices();
  //
  if (f_config.enter(f_section, sec, 100)) then begin
    //
    try
      // save configuration
      f_config.setValue('wave.in.deviceIdIndex',  c_comboBox_waveIn.itemIndex);
      f_config.setValue('wave.out.deviceIdIndex', c_comboBox_waveOut.itemIndex);
      //
      if (f_inOutDriver.r_in.r_valid) then begin
        //
        f_config.setValue('codec.in.driverModeIndex',  driverMode2index(f_inOutDriver.r_in.r_mode));
        if (unacdm_openH323plugin = f_inOutDriver.r_in.r_mode) then
          f_config.setValue('codec.in.formatIndex',    f_inOutDriver.r_in.r_formatIndex)
        else
          f_config.setValue('codec.in.formatTag',      f_inOutDriver.r_in.r_formatIndex);
        //
        f_config.setValue('codec.in.driverLib',        f_inOutDriver.r_in.r_library);
        f_config.setValue('wave.in.sd.mode', ord(f_waveInSDMode));
      end;
      //
      if (f_inOutDriver.r_out.r_valid) then begin
	//
	f_config.setValue('codec.out.driverModeIndex', driverMode2index(f_inOutDriver.r_out.r_mode));
	if (unacdm_openH323plugin = f_inOutDriver.r_out.r_mode) then
	  f_config.setValue('codec.out.formatIndex',   f_inOutDriver.r_out.r_formatIndex)
	else
	  f_config.setValue('codec.out.formatTag',     f_inOutDriver.r_out.r_formatIndex);
	//
	f_config.setValue('codec.out.driverLib',       f_inOutDriver.r_out.r_library);
      end;
      //
      // assuming f_formatIn is allocated and valid
      if ((nil <> f_formatInExt) and f_formatIn_nonPCMOK) then
	f_config.setValue('wave.in.formatExt', waveFormatExt2str(f_formatInExt));
      //
      // assuming f_formatOut is allocated and valid
      if (not f_syncInOutFormat and (nil <> f_formatOutExt) and f_formatOut_nonPCMOK) then
	f_config.setValue('wave.out.formatExt', waveFormatExt2str(f_formatOutExt));
      //
    finally
      f_config.leave(sec);
    end
  end;
end;

// --  --
function Tc_form_common_audioConfig.doFormatChoose(var format: pWAVEFORMATEX; var title: wString): int;
var
  wave: pWAVEFORMATEX;
begin
  wave := nil;
  try
    if ((0 <> enumFlags) and (nil <> f_enumFormatExt)) then
      waveExt2wave(f_enumFormatExt, wave);
    //
    if (mmNoError(formatChooseAlloc(format, format.wFormatTag, c_defSamplingSamplesPerSec, title, ACMFORMATCHOOSE_STYLEF_INITTOWFXSTRUCT, enumFlags, wave, f_maxFormatSize, handle))) then begin
      //
      title := format2str(format^);
      result := S_OK;
    end
    else
      result := -1;
  finally
    mrealloc(wave);
  end;
end;

// --  --
procedure Tc_form_common_audioConfig.c_button_inFormatBrowseClick(sender: tObject);
var
  title: wString;
  fmt: pWAVEFORMATEX;
begin
  fmt := nil;
  try
    case (index2driverMode(c_comboBox_inCodecMode.itemIndex)) of

      unacdm_acm: begin
	//
	title := 'Select recording format';
	if (waveExt2wave(f_formatInExt, fmt, true, f_maxFormatSize) and Succeeded(doFormatChoose(fmt, title))) then begin
	  //
	  fillFormatExt(f_formatInExt, fmt);
	  c_edit_inFormat.text := title;
	  if (f_syncInOutFormat) then
	    c_edit_outFormat.text := c_edit_inFormat.text;
	  //
	  f_formatIn_nonPCMOK := true;
	end;
      end;

      unacdm_openH323plugin: begin
	//
	if (c_openDialog_lib.execute()) then begin
	  //
	  f_inOutDriver.r_in.r_library := extractFileName(c_openDialog_lib.fileName);
	  c_edit_inFormat.text := f_inOutDriver.r_in.r_library;
	  if (f_syncInOutFormat) then
	    c_edit_outFormat.text := c_edit_inFormat.text;
	  //
	  showCodecTags(true);
	end;
      end;

    end;
  finally
    mrealloc(fmt);
  end;
end;

// --  --
procedure Tc_form_common_audioConfig.c_button_outFormatBrowseClick(sender: tObject);
var
  title: wString;
  fmt: pWAVEFORMATEX;
begin
  fmt := nil;
  try
    case (index2driverMode(c_comboBox_outCodecMode.itemIndex)) of

      unacdm_acm: begin
	//
	if (not f_syncInOutFormat) then begin
	  //
	  title := 'Select playback format';
	  if (waveExt2wave(f_formatOutExt, fmt) and Succeeded(doFormatChoose(fmt, title))) then begin
	    //
	    fillFormatExt(f_formatOutExt, fmt);
	    c_edit_outFormat.text := title;
	    //
	    f_formatOut_nonPCMOK := true;
	  end;
	end;
      end;

      unacdm_openH323plugin: begin
	//
	if (c_openDialog_lib.execute()) then begin
	  //
	  f_inOutDriver.r_out.r_library := extractFileName(c_openDialog_lib.fileName);
	  c_edit_outFormat.text := f_inOutDriver.r_out.r_library;
	  //
	  showCodecTags(false);
	end;
      end;

    end;
    //
  finally
    mrealloc(fmt);
  end;
end;

type
  //
  CPL_proc = function (cplhwnd: hWnd; msg: UINT; lparam1: LONG; lparam2: LONG): long; stdcall;
  SAPS_proc = procedure (param: DWORD); stdcall;

  //* The data structure CPlApplet() must fill in. */
  LPCPLINFO = ^CPLINFO;
  CPLINFO = packed record
    idIcon: int;     //* icon resource id, provided by CPlApplet() */
    idName: int;     //* name string res. id, provided by CPlApplet() */
    idInfo: int;     //* info string res. id, provided by CPlApplet() */
    lData: LONG;     //* user defined data */
  end;

  //
  LPNEWCPLINFOA = ^NEWCPLINFOA;
  NEWCPLINFOA = packed record
    dwSize: DWORD;         //* similar to the commdlg */
    dwFlags: DWORD;
    dwHelpContext: DWORD;  //* help context to use */
    lData: LONG;          //* user defined data */
    hIcon: HICON;          //* icon to use, this is owned by CONTROL.EXE (may be deleted) */
    szName: array[0..31] of AnsiChar;     //* short name */
    szInfo: array[0..63] of AnsiChar;     //* long name (status line) */
    szHelpFile: array[0..127] of AnsiChar;//* path to help file to use */
  end;

  //
  LPNEWCPLINFOW = ^NEWCPLINFOW;
  NEWCPLINFOW = packed record
    dwSize: DWORD;         //* similar to the commdlg */
    dwFlags: DWORD;
    dwHelpContext: DWORD;  //* help context to use */
    lData: LONG;          //* user defined data */
    hIcon: HICON;          //* icon to use, this is owned by CONTROL.EXE (may be deleted) */
    szName: array[0..31] of WIDECHAR;     //* short name */
    szInfo: array[0..63] of WIDECHAR;     //* long name (status line) */
    szHelpFile: array[0..127] of WIDECHAR;//* path to help file to use */
  end;


const
  CPL_INIT       = 1;
  CPL_GETCOUNT   = 2;
  CPL_INQUIRE    = 3;
  CPL_DBLCLK     = 5;
  CPL_NEWINQUIRE = 8;
  CPL_EXIT       = 7;
  CPL_STARTWPARMSA = 9;
  CPL_STARTWPARMSW = 10;
  //
  CPL_DYNAMIC_RES       = 0;

// --  --
procedure Tc_form_common_audioConfig.c_button_configAudioClick(sender: tObject);
var
  lib: hModule;
  proc: CPL_proc;
  SAPS: SAPS_proc;
  info: CPLINFO;
{$IFNDEF NO_ANSI_SUPPORT }
  newInfoA: NEWCPLINFOA;
{$ENDIF NO_ANSI_SUPPORT }
  newInfoW: NEWCPLINFOW;
  lData: int;
  shown: bool;
begin
  shown := false;
  //
  lib := LoadLibrary('MMSYS.CPL');
  if (0 <> lib) then begin
    //
    try
      @proc := GetProcAddress(lib, 'CPlApplet');
      if (assigned(proc)) then begin
        //
        if (0 <> proc(handle, CPL_INIT, 0, 0)) then begin
          //
          // first check if we can call SAPS
          @SAPS := GetProcAddress(lib, 'ShowAudioPropertySheet');
          if (assigned(SAPS)) then begin
            //
            SAPS(handle);
            shown := true;      // assume shown
          end
          else begin
            //
            // Got Vista? Try the old way.
            if (0 < proc(handle, CPL_GETCOUNT, 0, 0)) then begin
              //
              // inquire
              lData := -1;
              // there seems to be a bug in MSDN doc, CPL_INQUIRE and CPL_NEWINQUIRE returns number of dialogs
              if (0 <> proc(handle, CPL_INQUIRE, 0, LONG(@info))) then begin
                //
	      {$IFNDEF NO_ANSI_SUPPORT }
		if (g_wideApiSupported) then begin
	      {$ENDIF NO_ANSI_SUPPORT }
		  //
		  if (0 <> proc(handle, CPL_NEWINQUIRE, 0, LONG(@newinfoW))) then
		    lData := newInfoW.lData;
	      {$IFNDEF NO_ANSI_SUPPORT }
		end
		else begin
		  //
		  if (0 <> proc(handle, CPL_NEWINQUIRE, 0, LONG(@newinfoA))) then
		    lData := newInfoA.lData;
		end;
	      {$ENDIF NO_ANSI_SUPPORT }
	      end
              else
                lData := info.lData;
              //
              if (-1 <> lData) then begin
                //
                // bring up the dialog #0
                proc(handle, CPL_DBLCLK, 0, lData); // Vista returns non-zero if cancel was clicked
                shown := true;
              end;
            end;
          end;
        end;
        //
        proc(handle, CPL_EXIT, 0, 0);
      end;
    finally
      FreeLibrary(lib);
    end;
  end;
  //
  if (not shown) then begin
    //
    // try last resort
    execApp('RUNDLL32.EXE', 'MMSYS.CPL,ShowAudioPropertySheet', false);
  end;
end;

// --  --
procedure Tc_form_common_audioConfig.c_button_inVolControlClick(sender: tObject);
var
  mxId: int;
  a: wString;
begin
  if (0 <= f_waveInId) then begin
    //
    f_mixer.enumDevices();
    mxId := f_mixer.getMixerId(uint(f_waveInId), true{IN});
  end
  else
    mxId := 0;
  //
  if (0 > mxId) then
    guiMessageBox(handle, 'This device has no mixer.', 'Information', MB_OK or MB_ICONEXCLAMATION)
  else begin
    //
    if (g_OSVersion.dwMajorVersion >= 6) then
      a := ''
    else
      a := '32';
    //
    execApp('sndvol' + a + '.exe', '/r /d' + int2str(mxId), false, SW_SHOW, true);
  end;
end;

// --  --
procedure Tc_form_common_audioConfig.c_button_outVolControlClick(sender: tObject);
var
  mxId: int;
  a: wString;
begin
  if (0 <= f_waveOutId) then begin
    //
    f_mixer.enumDevices();
    mxId := f_mixer.getMixerId(f_waveOutId, false{OUT});
  end
  else
    mxId := 0;
  //
  if (0 > mxId) then
    guiMessageBox(handle, 'This device has no mixer.', 'Information', MB_OK or MB_ICONEXCLAMATION)
  else begin
    //
    if (g_OSVersion.dwMajorVersion >= 6) then
      a := ''
    else
      a := '32';
    //
    execApp('sndvol' + a + '.exe', '/p /d' + int2str(mxId), false, SW_SHOW, true);
  end;
end;

// --  --
procedure Tc_form_common_audioConfig.setupUI(syncInOutFormat, includeMapper, allowModeChange: bool);
begin
  f_syncInOutFormat := syncInOutFormat;
  f_includeMapper := includeMapper;
  f_allowModeChange := allowModeChange;
  //
  c_button_outFormatBrowse.visible := not f_syncInOutFormat;
  c_edit_outFormat.visible := not f_syncInOutFormat;
  c_comboBox_outCodecTag.visible := not f_syncInOutFormat;
  c_label_outCodecFT.visible := not f_syncInOutFormat;
  c_label_outFormat.visible := not f_syncInOutFormat;
  //
  c_label_inDriverMode.visible := allowModeChange;
  c_comboBox_inCodecMode.visible := allowModeChange;
  c_label_outDriverMode.visible := allowModeChange and not f_syncInOutFormat;
  c_comboBox_outCodecMode.enabled := allowModeChange and not f_syncInOutFormat;
  //
  if (f_syncInOutFormat) then
    c_edit_outFormat.text := c_edit_inFormat.text;
end;

// --  --
procedure Tc_form_common_audioConfig.enumWaveDevices();
begin
  if (not f_enumComplete) then begin
    //
    f_enumComplete := true;
    //
    unaVcIDEUtils.enumWaveDevices(c_comboBox_waveIn, true, f_includeMapper);
    unaVcIDEUtils.enumWaveDevices(c_comboBox_waveOut, false, f_includeMapper);
  end;
end;

// --  --
procedure Tc_form_common_audioConfig.c_comboBox_inCodecModeChange(sender: tObject);
begin
  f_inOutDriver.r_in.r_mode := index2driverMode(c_comboBox_inCodecMode.itemIndex);
  //
  showCodecTags(true);
  //
  c_comboBox_inCodecTag.visible := (unacdm_openH323plugin = f_inOutDriver.r_in.r_mode);
  c_label_inCodecFT.visible := c_comboBox_inCodecTag.visible;
  //
  if (f_syncInOutFormat) then
    c_comboBox_outCodecMode.itemIndex := c_comboBox_inCodecMode.itemIndex;
end;

// --  --
procedure Tc_form_common_audioConfig.c_comboBox_outCodecModeChange(sender: tObject);
begin
  f_inOutDriver.r_out.r_mode := index2driverMode(c_comboBox_outCodecMode.itemIndex);
  //
  showCodecTags(false);
  //
  c_comboBox_outCodecTag.visible := (unacdm_openH323plugin = f_inOutDriver.r_out.r_mode);
  c_label_outCodecFT.visible := c_comboBox_outCodecTag.visible;
end;

// --  --
procedure Tc_form_common_audioConfig.showCodecTags(inCodec: bool);

type
  //
  popenH323pluginCodecs = ^openH323pluginCodecs;
  openH323pluginCodecs = array[word] of pluginCodec_definition;

var
  i: int;
  combo: tComboBox;
  edit: tEdit;
  lib: wString;
  pproc: plugin_proc;
  codecDefRoot: popenH323pluginCodecs;
  cnt: uint32;
  label1, label2: tLabel;
  doShow: bool;
begin
  if (inCodec) then begin
    //
    combo := c_comboBox_inCodecTag;
    edit := c_edit_inFormat;
    label1 := c_label_inCodecFT;
    label2 := c_label_inFormat;
    //
    lib := f_inOutDriver.r_in.r_library;
    //
    doShow := (unacdm_openH323plugin = f_inOutDriver.r_in.r_mode);
  end
  else begin
    //
    combo := c_comboBox_outCodecTag;
    edit := c_edit_outFormat;
    label1 := c_label_outCodecFT;
    label2 := c_label_outFormat;
    //
    lib := f_inOutDriver.r_out.r_library;
    //
    doShow := (unacdm_openH323plugin = f_inOutDriver.r_out.r_mode);
  end;
  //
  if (doShow) then begin
    //
    combo.items.clear();
    //
    if ('' = lib) then begin
      //
      if (c_openDialog_lib.execute()) then begin
	//
	lib := extractFileName(c_openDialog_lib.fileName);
	//
	if (inCodec) then
	  f_inOutDriver.r_in.r_library := lib
	else
	  f_inOutDriver.r_out.r_library := lib;
      end;
    end;
    //
    edit.text := lib;
    //
    fillChar(pproc, sizeOf(pproc), 0);
    if (0 = plugin_loadDLL(pproc, lib)) then begin
      //
      try
	//
	pointer(codecDefRoot) := pproc.rproc_getCodecFunction(cnt, PLUGIN_CODEC_VERSION);
	//
	if ((nil <> codecDefRoot) and (0 < cnt)) then begin
	  //
	  for i := 0 to cnt - 1 do begin
	    //
	    if ('L16' = trimS(codecDefRoot[i].sourceFormat)) then
	      combo.items.add(string(codecDefRoot[i].descr));
	    //
	  end;
	end;
	//
      finally
	plugin_unloadDLL(pproc);
      end;
    end;
    //
    if (0 < combo.items.count) then begin
      //
      if (inCodec) then
	combo.itemIndex := min(combo.items.count - 1, f_inOutDriver.r_in.r_formatIndex)
      else
	combo.itemIndex := min(combo.items.count - 1, f_inOutDriver.r_out.r_formatIndex);
      //
    end;
    //
    label2.caption := '&Library';
  end
  else begin
    //
    if (inCodec) then begin
      //
      if (nil <> f_formatInExt) then
	edit.text := waveExt2str(f_formatInExt);
    end
    else begin
      //
      if (nil <> f_formatOutExt) then
	edit.text := waveExt2str(f_formatOutExt);
    end;
    //
    if (f_syncInOutFormat) then
      c_edit_outFormat.text := c_edit_inFormat.text;
    //
    label2.caption := label1.caption;
  end;
end;

// --  --
procedure Tc_form_common_audioConfig.c_comboBox_waveInChange(sender: TObject);
begin
  f_waveInId := index2deviceId(c_comboBox_waveIn);
end;

// --  --
procedure Tc_form_common_audioConfig.c_comboBox_waveOutChange(sender: TObject);
begin
  f_waveOutId := index2deviceId(c_comboBox_waveOut);
end;

// --  --
procedure Tc_form_common_audioConfig.c_comboBox_inCodecTagChange(sender: TObject);
begin
  f_inOutDriver.r_in.r_formatIndex := c_comboBox_inCodecTag.itemIndex;
end;

// --  --
procedure Tc_form_common_audioConfig.c_comboBox_outCodecTagChange(sender: TObject);
begin
  f_inOutDriver.r_out.r_formatIndex := c_comboBox_outCodecTag.itemIndex;
end;

// --  --
procedure Tc_form_common_audioConfig.c_cb_vadChange(Sender: TObject);
begin
  case (c_cb_vad.itemIndex) of

    1: f_waveInSDMode := unasdm_VC;
    2: f_waveInSDMode := unasdm_DSP;
    3: f_waveInSDMode := unasdm_3GPPVAD1;
    else
       f_waveInSDMode := unasdm_none;

  end;
end;

// --  --
procedure Tc_form_common_audioConfig.hideShowGUI(waveIn, codecIn, waveOut, codecOut: bool);
begin
  if (not f_hideShowGUIdone) then begin
    //
    f_hideShowGUIdone := true;
    //
    c_comboBox_waveIn.visible := waveIn;
    c_cb_vad.visible := waveIn;
    c_label_inDevice.visible := waveIn;
    c_button_inVolControl.visible := waveIn;
    //
    c_label_inDriverMode.visible := codecIn;
    c_comboBox_inCodecMode.visible := codecIn;
    c_label_inCodecFT.visible := codecIn and (unacdm_openH323plugin = f_inOutDriver.r_in.r_mode);
    c_comboBox_inCodecTag.visible := c_label_inCodecFT.visible;
    c_label_inFormat.visible := codecIn;
    c_edit_inFormat.visible := codecIn;
    c_button_inFormatBrowse.visible := codecIn;
    //
    c_comboBox_waveOut.visible := waveOut;
    c_label_outDevice.visible := waveOut;
    c_button_outVolControl.visible := waveOut;
    //
    c_label_outDriverMode.visible := codecOut;
    c_comboBox_outCodecMode.enabled := codecOut and not f_syncInOutFormat;
    c_label_outCodecFT.visible := codecOut and (unacdm_openH323plugin = f_inOutDriver.r_out.r_mode);
    c_comboBox_outCodecTag.visible := c_label_outCodecFT.visible;
    c_label_outFormat.visible := codecOut;
    c_edit_outFormat.visible := codecOut;
    c_button_outFormatBrowse.visible := codecOut and not f_syncInOutFormat;
  end;
end;

// --  --
procedure Tc_form_common_audioConfig.setEnumFormat(value: PWAVEFORMATEXTENSIBLE);
begin
  duplicateFormat(value, f_enumFormatExt);
end;


end.

