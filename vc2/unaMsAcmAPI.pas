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
	Microsoft Audio Compression Manager (ACM) interface

	Original Delphi conversion by Armin Sander,
		Digital SimpleX / armin@dsx.de

	Additional programming:

	  Copyright (c) 2002-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/

	----------------------------------------------
	  modified by:
		Lake, Jan-Dec 2002
		Lake, Feb 2003
	----------------------------------------------
*)

{$I unaDef.inc }

{*
  This unit contains Object Pascal version of MSAcm.h originally done by Armin Sander, Digital SimpleX
  Most of the functions in this unit are documented in Microsoft Platform SDK.

  @Author Additional modification by Lake

  2.5.2008.07 Still here
}

unit
  unaMsAcmAPI;

interface

uses
   Windows, unaTypes, MMSystem;

   // C++Builders stuff

{$HPPEMIT '#include "MMREG.H"' }
{$HPPEMIT '#include "msacm.h"' }

type
  {$EXTERNALSYM WAVEFORMATEX }
  WAVEFORMATEX = tWAVEFORMATEX;

// some MMREG.H and MMSYSTEM.H includes missed from MMSystem.pas

const
  {$EXTERNALSYM WAVE_FILTER_UNKNOWN }
  WAVE_FILTER_UNKNOWN        	= $0000;
  {$EXTERNALSYM WAVE_FILTER_DEVELOPMENT }
  WAVE_FILTER_DEVELOPMENT	= $FFFF;

  {$EXTERNALSYM WAVE_FORMAT_DIRECT}
  WAVE_FORMAT_DIRECT        	= $0008;

type
  pWAVEFILTER = ^WAVEFILTER;
  {$EXTERNALSYM WAVEFILTER}
  WAVEFILTER = record
    cbStruct   : DWORD;        // Size of the filter in bytes
    dwFilterTag: DWORD;        // filter type
    fdwFilter  : DWORD;        // Flags for the filter (Universal Dfns)
    dwReserved : array[0..5] of DWORD;      // Reserved for system use
  end;

const
  {$EXTERNALSYM DRV_MAPPER_PREFERRED_INPUT_GET }
  DRV_MAPPER_PREFERRED_INPUT_GET = (DRV_USER + 0);
  {$EXTERNALSYM DRV_MAPPER_PREFERRED_OUTPUT_GET }
  DRV_MAPPER_PREFERRED_OUTPUT_GET = (DRV_USER + 2);

  {$EXTERNALSYM DRVM_MAPPER_STATUS }
  DRVM_MAPPER_STATUS = $2000;

  {$EXTERNALSYM WIDM_MAPPER_STATUS }
  WIDM_MAPPER_STATUS = (DRVM_MAPPER_STATUS + 0);

  {$EXTERNALSYM WAVEIN_MAPPER_STATUS_DEVICE }
  WAVEIN_MAPPER_STATUS_DEVICE = 0;
  {$EXTERNALSYM WAVEIN_MAPPER_STATUS_MAPPED }
  WAVEIN_MAPPER_STATUS_MAPPED = 1;
  {$EXTERNALSYM WAVEIN_MAPPER_STATUS_FORMAT }
  WAVEIN_MAPPER_STATUS_FORMAT = 2;

  {$EXTERNALSYM WODM_MAPPER_STATUS }
  WODM_MAPPER_STATUS = (DRVM_MAPPER_STATUS + 0);

  {$EXTERNALSYM WAVEOUT_MAPPER_STATUS_DEVICE }
  WAVEOUT_MAPPER_STATUS_DEVICE = 0;
  {$EXTERNALSYM WAVEOUT_MAPPER_STATUS_MAPPED }
  WAVEOUT_MAPPER_STATUS_MAPPED = 1;
  {$EXTERNALSYM WAVEOUT_MAPPER_STATUS_FORMAT }
  WAVEOUT_MAPPER_STATUS_FORMAT = 2;

// MSACM.H

//--------------------------------------------------------------------------;
//
//  ACM General API's and Defines
//
//

type
  {
	there are four types of 'handles' used by the ACM. the first three
	are unique types that define specific objects:

	HACMDRIVERID: used to _identify_ an ACM driver. this identifier can be
	used to _open_ the driver for querying details, etc about the driver.
  }
  pHACMDRIVERID = ^HACMDRIVERID;
  {$EXTERNALSYM HACMDRIVERID }
  HACMDRIVERID  = tHandle;

  {
	HACMDRIVER: used to manage a driver (codec, filter, etc). this handle
	is much like a handle to other media drivers -- you use it to send
	messages to the converter, query for capabilities, etc.
  }
  pHACMDRIVER = ^HACMDRIVER;
  {$EXTERNALSYM HACMDRIVER }
  HACMDRIVER  = tHandle;

  {
	HACMSTREAM: used to manage a 'stream' (conversion channel) with the
	ACM. you use a stream handle to convert data from one format/type
	to another -- much like dealing with a file handle.
  }
  pHACMSTREAM = ^HACMSTREAM;
  {$EXTERNALSYM HACMSTREAM }
  HACMSTREAM  = tHandle;

  {
	the fourth handle type is a generic type used on ACM functions that
	can accept two or more of the above handle types (for example the
	acmMetrics and acmDriverID functions).

	HACMOBJ: used to identify ACM objects. this handle is used on functions
	that can accept two or more ACM handle types.
  }
  pHACMOBJ = ^HACMOBJ;
  {$EXTERNALSYM HACMOBJ }
  HACMOBJ  = tHandle;

const
  {
	ACM Error Codes

	Note that these error codes are specific errors that apply to the ACM
	directly--general errors are defined as MMSYSERR_*.
  }
  {$EXTERNALSYM ACMERR_BASE }
  ACMERR_BASE         	= 512;
  {$EXTERNALSYM ACMERR_NOTPOSSIBLE }
  ACMERR_NOTPOSSIBLE	= ACMERR_BASE + 0;
  {$EXTERNALSYM ACMERR_BUSY }
  ACMERR_BUSY         	= ACMERR_BASE + 1;
  {$EXTERNALSYM ACMERR_UNPREPARED }
  ACMERR_UNPREPARED   	= ACMERR_BASE + 2;
  {$EXTERNALSYM ACMERR_CANCELED }
  ACMERR_CANCELED     	= ACMERR_BASE + 3;

  {
	ACM Window Messages

	These window messages are sent by the ACM or ACM drivers to notify
	applications of events.

	Note that these window message numbers will also be defined in
	mmsystem.
  }
  {$EXTERNALSYM MM_ACM_OPEN }
  MM_ACM_OPEN        	= MM_STREAM_OPEN;  // conversion callback messages
  {$EXTERNALSYM MM_ACM_CLOSE }
  MM_ACM_CLOSE       	= MM_STREAM_CLOSE;
  {$EXTERNALSYM MM_ACM_DONE }
  MM_ACM_DONE		= MM_STREAM_DONE;

  {
	the ACM version is a 32 bit number that is broken into three parts as
	follows:

		bits 24 - 31:   8 bit _major_ version number
		bits 16 - 23:   8 bit _minor_ version number
		bits  0 - 15:   16 bit build number

	this is then displayed as follows:

		bMajor = (BYTE)(dwVersion >> 24)
		bMinor = (BYTE)(dwVersion >> 16) &
		wBuild = LOWORD(dwVersion)
  }
{$EXTERNALSYM acm_GetVersion}
function acm_getVersion: DWORD; stdcall;

{$EXTERNALSYM acm_Metrics }
function acm_metrics(hao: HACMOBJ; uMetric: UINT; var pMetric): MMRESULT; stdcall;

const
  {$EXTERNALSYM ACM_METRIC_COUNT_DRIVERS }
  ACM_METRIC_COUNT_DRIVERS            = 1;
  {$EXTERNALSYM ACM_METRIC_COUNT_CODECS }
  ACM_METRIC_COUNT_CODECS             = 2;
  {$EXTERNALSYM ACM_METRIC_COUNT_CONVERTERS }
  ACM_METRIC_COUNT_CONVERTERS         = 3;
  {$EXTERNALSYM ACM_METRIC_COUNT_FILTERS }
  ACM_METRIC_COUNT_FILTERS            = 4;
  {$EXTERNALSYM ACM_METRIC_COUNT_DISABLED }
  ACM_METRIC_COUNT_DISABLED           = 5;
  {$EXTERNALSYM ACM_METRIC_COUNT_HARDWARE }
  ACM_METRIC_COUNT_HARDWARE           = 6;
  {$EXTERNALSYM ACM_METRIC_COUNT_LOCAL_DRIVERS }
  ACM_METRIC_COUNT_LOCAL_DRIVERS      = 20;
  {$EXTERNALSYM ACM_METRIC_COUNT_LOCAL_CODECS }
  ACM_METRIC_COUNT_LOCAL_CODECS       = 21;
  {$EXTERNALSYM ACM_METRIC_COUNT_LOCAL_CONVERTERS }
  ACM_METRIC_COUNT_LOCAL_CONVERTERS   = 22;
  {$EXTERNALSYM ACM_METRIC_COUNT_LOCAL_FILTERS }
  ACM_METRIC_COUNT_LOCAL_FILTERS      = 23;
  {$EXTERNALSYM ACM_METRIC_COUNT_LOCAL_DISABLED }
  ACM_METRIC_COUNT_LOCAL_DISABLED     = 24;

  {$EXTERNALSYM ACM_METRIC_HARDWARE_WAVE_INPUT }
  ACM_METRIC_HARDWARE_WAVE_INPUT      = 30;
  {$EXTERNALSYM ACM_METRIC_HARDWARE_WAVE_OUTPUT }
  ACM_METRIC_HARDWARE_WAVE_OUTPUT     = 31;
  {$EXTERNALSYM ACM_METRIC_MAX_SIZE_FORMAT }
  ACM_METRIC_MAX_SIZE_FORMAT          = 50;
  {$EXTERNALSYM ACM_METRIC_MAX_SIZE_FILTER }
  ACM_METRIC_MAX_SIZE_FILTER          = 51;
  {$EXTERNALSYM ACM_METRIC_DRIVER_SUPPORT }
  ACM_METRIC_DRIVER_SUPPORT           = 100;
  {$EXTERNALSYM ACM_METRIC_DRIVER_PRIORITY }
  ACM_METRIC_DRIVER_PRIORITY          = 101;

//--------------------------------------------------------------------------
//
//  ACM Drivers
//

type
  {$EXTERNALSYM ACMDRIVERENUMCB }
  ACMDRIVERENUMCB = function(hadid: HACMDRIVERID; dwInstance: DWORD; fdwSupport: DWORD): Windows.BOOL; stdcall;

{$EXTERNALSYM acm_DriverEnum }
function acm_driverEnum(fnCallback: ACMDRIVERENUMCB; dwInstance: DWORD; fdwEnum: DWORD): MMRESULT; stdcall;

const
  {$EXTERNALSYM ACM_DRIVERENUMF_NOLOCAL }
  ACM_DRIVERENUMF_NOLOCAL  = $40000000;
  {$EXTERNALSYM ACM_DRIVERENUMF_DISABLED }
  ACM_DRIVERENUMF_DISABLED = $80000000;

{$EXTERNALSYM acm_DriverID }
function acm_driverID(hao: HACMOBJ; phadid: pHACMDRIVERID; fdwDriverID: DWORD): MMRESULT; stdcall;
{$EXTERNALSYM acm_DriverAddA }
function acm_driverAddA(phadid: pHACMDRIVERID; hinstModule: HINST; lParam: LPARAM; dwPriority: DWORD; fdwAdd: DWORD): MMRESULT; stdcall;
{$EXTERNALSYM acm_DriverAddW }
function acm_driverAddW(phadid: pHACMDRIVERID; hinstModule: HINST; lParam: LPARAM; dwPriority: DWORD; fdwAdd: DWORD): MMRESULT; stdcall;
{$EXTERNALSYM acm_DriverAdd }
function acm_driverAdd (phadid: pHACMDRIVERID; hinstModule: HINST; lParam: LPARAM; dwPriority: DWORD; fdwAdd: DWORD): MMRESULT; stdcall;

const
  {$EXTERNALSYM ACM_DRIVERADDF_FUNCTION }
  ACM_DRIVERADDF_FUNCTION   = $00000003;  // lParam is a procedure
  {$EXTERNALSYM ACM_DRIVERADDF_NOTIFYHWND }
  ACM_DRIVERADDF_NOTIFYHWND = $00000004;  // lParam is notify hwnd
  {$EXTERNALSYM ACM_DRIVERADDF_TYPEMASK }
  ACM_DRIVERADDF_TYPEMASK   = $00000007;  // driver type mask
  {$EXTERNALSYM ACM_DRIVERADDF_LOCAL }
  ACM_DRIVERADDF_LOCAL      = $00000000;  // is local to current task
  {$EXTERNALSYM ACM_DRIVERADDF_GLOBAL }
  ACM_DRIVERADDF_GLOBAL     = $00000008;  // is global

type
  {
	prototype for ACM driver procedures that are installed as _functions_
	or _notifations_ instead of as a standalone installable driver.
  }
  {$EXTERNALSYM ACMDRIVERPROC }
  ACMDRIVERPROC = function(a_0: DWORD; a_1: HACMDRIVERID; a_2: UINT; a_3: LPARAM; a_4: LPARAM): LRESULT; stdcall;
  {$EXTERNALSYM LPACMDRIVERPROC }
  LPACMDRIVERPROC = ^ACMDRIVERPROC;

{$EXTERNALSYM acm_DriverRemove }
function acm_driverRemove(hadid: HACMDRIVERID; fdwRemove: DWORD): MMRESULT; stdcall;
{$EXTERNALSYM acm_DriverOpen }
function acm_driverOpen(phad: pHACMDRIVER; hadid: HACMDRIVERID; fdwOpen: DWORD): MMRESULT; stdcall;
{$EXTERNALSYM acm_DriverClose }
function acm_driverClose(had: HACMDRIVER; fdwClose: DWORD): MMRESULT; stdcall;
{$EXTERNALSYM acm_DriverMessage }
function acm_driverMessage(had: HACMDRIVER; uMsg: UINT; lParam1: LPARAM; lParam2: LPARAM): LRESULT; stdcall;

const
  {$EXTERNALSYM ACMDM_USER }
  ACMDM_USER          = (DRV_USER + $0000);
  {$EXTERNALSYM ACMDM_RESERVED_LOW }
  ACMDM_RESERVED_LOW  = (DRV_USER + $2000);
  {$EXTERNALSYM ACMDM_RESERVED_HIGH }
  ACMDM_RESERVED_HIGH = (DRV_USER + $2FFF);
  {$EXTERNALSYM ACMDM_BASE }
  ACMDM_BASE          = ACMDM_RESERVED_LOW;
  {$EXTERNALSYM ACMDM_DRIVER_ABOUT }
  ACMDM_DRIVER_ABOUT  = (ACMDM_BASE + 11);

// -- MSACMDRV.H --

type
//
//
  ACMDRVSTREAMINSTANCE = record
    cbStruct  : DWORD;
    pwfxSrc   : PWAVEFORMATEX;
    pwfxDst   : PWAVEFORMATEX;
    pwfltr    : PWAVEFILTER;
    dwCallback: DWORD;
    dwInstance: DWORD;
    fdwOpen   : DWORD;
    fdwDriver : DWORD;
    dwDriver  : DWORD;
    has       : HACMSTREAM;
  end;

//
//  structure for ACMDM_STREAM_SIZE message
//
//
  ACMDRVSTREAMSIZE = record
    cbStruct:    DWORD;
    fdwSize:     DWORD;
    cbSrcLength: DWORD;
    cbDstLength: DWORD;
  end;


//
//  NOTE! this structure must match the ACMSTREAMHEADER in msacm.h but
//  defines more information for the driver writing convenience
//
  PACMDRVSTREAMHEADER = ^ACMDRVSTREAMHEADER;
  ACMDRVSTREAMHEADER = record
    cbStruct:        DWORD;
    fdwStatus:       DWORD;
    dwUser:          DWORD_PTR;
    pbSrc:           PBYTE;
    cbSrcLength:     DWORD;
    cbSrcLengthUsed: DWORD;
    dwSrcUser:       DWORD_PTR;
    pbDst:           PBYTE;
    cbDstLength:     DWORD;
    cbDstLengthUsed: DWORD;
    dwDstUser:       DWORD_PTR;

    fdwConvert:      DWORD;               // flags passed from convert func
    padshNext:       PACMDRVSTREAMHEADER; // for async driver queueing
    fdwDriver:       DWORD;               // driver instance flags
    dwDriver:        DWORD;               // driver instance data

    //
    //  all remaining fields are used by the ACM for bookkeeping purposes.
    //  an ACM driver should never use these fields (though than can be
    //  helpful for debugging)--note that the meaning of these fields
    //  may change, so do NOT rely on them in shipping code.
    //
    fdwPrepared:         DWORD;
    dwPrepared:          DWORD;
    pbPreparedSrc:       PBYTE;
    cbPreparedSrcLength: DWORD;
    pbPreparedDst:       PBYTE;
    cbPreparedDstLength: DWORD;
  end;



//
//  structure containing the information for the ACMDM_FORMAT_SUGGEST message
//
//
  ACMDRVFORMATSUGGEST = record
    cbStruct: DWORD;		// sizeof(ACMDRVFORMATSUGGEST)
    fdwSuggest: DWORD;		// Suggest flags
    pwfxSrc: PWAVEFORMATEX;	// Source Format
    cbwfxSrc: DWORD;		// Source Size
    pwfxDst: PWAVEFORMATEX;	// Dest format
    cbwfxDst: DWORD;		// Dest Size
  end;


const
//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - ;
//
//  ACM Driver Messages
//
//
//
//- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - ;

  ACMDM_DRIVER_NOTIFY             = (ACMDM_BASE + 1);
  ACMDM_DRIVER_DETAILS            = (ACMDM_BASE + 10);

  ACMDM_HARDWARE_WAVE_CAPS_INPUT  = (ACMDM_BASE + 20);
  ACMDM_HARDWARE_WAVE_CAPS_OUTPUT = (ACMDM_BASE + 21);

  ACMDM_FORMATTAG_DETAILS         = (ACMDM_BASE + 25);
  ACMDM_FORMAT_DETAILS            = (ACMDM_BASE + 26);
  ACMDM_FORMAT_SUGGEST            = (ACMDM_BASE + 27);

  ACMDM_FILTERTAG_DETAILS         = (ACMDM_BASE + 50);
  ACMDM_FILTER_DETAILS            = (ACMDM_BASE + 51);

  ACMDM_STREAM_OPEN               = (ACMDM_BASE + 76);
  ACMDM_STREAM_CLOSE              = (ACMDM_BASE + 77);
  ACMDM_STREAM_SIZE               = (ACMDM_BASE + 78);
  ACMDM_STREAM_CONVERT            = (ACMDM_BASE + 79);
  ACMDM_STREAM_RESET              = (ACMDM_BASE + 80);
  ACMDM_STREAM_PREPARE            = (ACMDM_BASE + 81);
  ACMDM_STREAM_UNPREPARE          = (ACMDM_BASE + 82);

  
{$EXTERNALSYM acm_DriverPriority }
function acm_driverPriority(hadid: HACMDRIVERID; dwPriority: DWORD; fdwPriority: DWORD): MMRESULT; stdcall;

const
  {$EXTERNALSYM ACM_DRIVERPRIORITYF_ENABLE }
  ACM_DRIVERPRIORITYF_ENABLE      = $00000001;
  {$EXTERNALSYM ACM_DRIVERPRIORITYF_DISABLE }
  ACM_DRIVERPRIORITYF_DISABLE     = $00000002;
  {$EXTERNALSYM ACM_DRIVERPRIORITYF_ABLEMASK }
  ACM_DRIVERPRIORITYF_ABLEMASK    = $00000003;
  {$EXTERNALSYM ACM_DRIVERPRIORITYF_BEGIN }
  ACM_DRIVERPRIORITYF_BEGIN       = $00010000;
  {$EXTERNALSYM ACM_DRIVERPRIORITYF_END }
  ACM_DRIVERPRIORITYF_END         = $00020000;
  {$EXTERNALSYM ACM_DRIVERPRIORITYF_DEFERMASK }
  ACM_DRIVERPRIORITYF_DEFERMASK   = $00030000;

  {
	ACMDRIVERDETAILS

	the ACMDRIVERDETAILS structure is used to get various capabilities from
	an ACM driver (codec, converter, filter).
  }
  {$EXTERNALSYM ACMDRIVERDETAILS_SHORTNAME_CHARS }
  ACMDRIVERDETAILS_SHORTNAME_CHARS    = 32;
  {$EXTERNALSYM ACMDRIVERDETAILS_LONGNAME_CHARS }
  ACMDRIVERDETAILS_LONGNAME_CHARS     = 128;
  {$EXTERNALSYM ACMDRIVERDETAILS_COPYRIGHT_CHARS }
  ACMDRIVERDETAILS_COPYRIGHT_CHARS    = 80;
  {$EXTERNALSYM ACMDRIVERDETAILS_LICENSING_CHARS }
  ACMDRIVERDETAILS_LICENSING_CHARS    = 128;
  {$EXTERNALSYM ACMDRIVERDETAILS_FEATURES_CHARS }
  ACMDRIVERDETAILS_FEATURES_CHARS     = 512;

type
  pACMDRIVERDETAILSA = ^ACMDRIVERDETAILSA;
  {$EXTERNALSYM ACMDRIVERDETAILSA }
  ACMDRIVERDETAILSA = record
    cbStruct      : DWORD;              // number of valid bytes in structure
    fccType       : FOURCC;             // compressor type 'audc'
    fccComp       : FOURCC;             // sub-type (not used; reserved)
    wMid          : WORD;               // manufacturer id
    wPid          : WORD;               // product id
    vdwACM        : DWORD;              // version of the ACM *compiled* for
    vdwDriver     : DWORD;              // version of the driver
    fdwSupport    : DWORD;              // misc. support flags
    cFormatTags   : DWORD;              // total unique format tags supported
    cFilterTags   : DWORD;              // total unique filter tags supported
    hicon         : HICON;              // handle to custom icon
    szShortName   : array[0..ACMDRIVERDETAILS_SHORTNAME_CHARS - 1] of aChar;
    szLongName    : array[0..ACMDRIVERDETAILS_LONGNAME_CHARS - 1] of aChar;
    szCopyright   : array[0..ACMDRIVERDETAILS_COPYRIGHT_CHARS - 1] of aChar;
    szLicensing   : array[0..ACMDRIVERDETAILS_LICENSING_CHARS - 1] of aChar;
    szFeatures    : array[0..ACMDRIVERDETAILS_FEATURES_CHARS - 1] of aChar;
  end;

  pACMDRIVERDETAILSW = ^ACMDRIVERDETAILSW;
  {$EXTERNALSYM ACMDRIVERDETAILSW }
  ACMDRIVERDETAILSW = record
    cbStruct      : DWORD;              // number of valid bytes in structure
    fccType       : FOURCC;             // compressor type 'audc'
    fccComp       : FOURCC;             // sub-type (not used; reserved)
    wMid          : WORD;               // manufacturer id
    wPid          : WORD;               // product id
    vdwACM        : DWORD;              // version of the ACM *compiled* for
    vdwDriver     : DWORD;              // version of the driver
    fdwSupport    : DWORD;              // misc. support flags
    cFormatTags   : DWORD;              // total unique format tags supported
    cFilterTags   : DWORD;              // total unique filter tags supported
    hicon         : HICON;              // handle to custom icon
    szShortName   : array[0..ACMDRIVERDETAILS_SHORTNAME_CHARS - 1] of wChar;
    szLongName    : array[0..ACMDRIVERDETAILS_LONGNAME_CHARS  - 1] of wChar;
    szCopyright   : array[0..ACMDRIVERDETAILS_COPYRIGHT_CHARS - 1] of wChar;
    szLicensing   : array[0..ACMDRIVERDETAILS_LICENSING_CHARS - 1] of wChar;
    szFeatures    : array[0..ACMDRIVERDETAILS_FEATURES_CHARS  - 1] of wChar;
  end;

  {$EXTERNALSYM ACMDRIVERDETAILS }
  ACMDRIVERDETAILS  = ACMDRIVERDETAILSA;
  pACMDRIVERDETAILS = pACMDRIVERDETAILSA;

//  ACMDRIVERDETAILS.fccType
//
//  ACMDRIVERDETAILS_FCCTYPE_AUDIOCODEC: the FOURCC used in the fccType
//  field of the ACMDRIVERDETAILS structure to specify that this is an ACM
//  codec designed for audio.
//  ACMDRIVERDETAILS_FCCTYPE_AUDIOCODEC = mmioFOURCC('a', 'u', 'd', 'c');
{$EXTERNALSYM ACMDRIVERDETAILS_FCCTYPE_AUDIOCODEC }
function ACMDRIVERDETAILS_FCCTYPE_AUDIOCODEC(): FOURCC;

const
//  ACMDRIVERDETAILS.fccComp
//
//  ACMDRIVERDETAILS_FCCCOMP_UNDEFINED: the FOURCC used in the fccComp
//  field of the ACMDRIVERDETAILS structure. this is currently an unused
//  field.
//
  {$EXTERNALSYM ACMDRIVERDETAILS_FCCCOMP_UNDEFINED }
  ACMDRIVERDETAILS_FCCCOMP_UNDEFINED = 0;

const
//
//  the following flags are used to specify the type of conversion(s) that
//  the converter/codec/filter supports. these are placed in the fdwSupport
//  field of the ACMDRIVERDETAILS structure. note that a converter can
//  support one or more of these flags in any combination.
//
//  ACMDRIVERDETAILS_SUPPORTF_CODEC: this flag is set if the driver supports
//  conversions from one format tag to another format tag. for example, if a
//  converter compresses WAVE_FORMAT_PCM to WAVE_FORMAT_ADPCM, then this bit
//  should be set.
//
  {$EXTERNALSYM ACMDRIVERDETAILS_SUPPORTF_CODEC }
  ACMDRIVERDETAILS_SUPPORTF_CODEC     = $00000001;

//  ACMDRIVERDETAILS_SUPPORTF_CONVERTER: this flags is set if the driver
//  supports conversions on the same format tag. as an example, the PCM
//  converter that is built into the ACM sets this bit (and only this bit)
//  because it converts only PCM formats (bits, sample rate).
  {$EXTERNALSYM ACMDRIVERDETAILS_SUPPORTF_CONVERTER }
  ACMDRIVERDETAILS_SUPPORTF_CONVERTER = $00000002;

//  ACMDRIVERDETAILS_SUPPORTF_FILTER: this flag is set if the driver supports
//  transformations on a single format. for example, a converter that changed
//  the 'volume' of PCM data would set this bit. 'echo' and 'reverb' are
//  also filter types.
  {$EXTERNALSYM ACMDRIVERDETAILS_SUPPORTF_FILTER }
  ACMDRIVERDETAILS_SUPPORTF_FILTER    = $00000004;

//  ACMDRIVERDETAILS_SUPPORTF_HARDWARE: this flag is set if the driver supports
//  hardware input and/or output through a waveform device.
  {$EXTERNALSYM ACMDRIVERDETAILS_SUPPORTF_HARDWARE }
  ACMDRIVERDETAILS_SUPPORTF_HARDWARE  = $00000008;

//  ACMDRIVERDETAILS_SUPPORTF_ASYNC: this flag is set if the driver supports
//  async conversions.
  {$EXTERNALSYM ACMDRIVERDETAILS_SUPPORTF_ASYNC }
  ACMDRIVERDETAILS_SUPPORTF_ASYNC     = $00000010;

//
//  ACMDRIVERDETAILS_SUPPORTF_LOCAL: this flag is set _by the ACM_ if a
//  driver has been installed local to the current task. this flag is also
//  set in the fdwSupport argument to the enumeration callback function
//  for drivers.
  {$EXTERNALSYM ACMDRIVERDETAILS_SUPPORTF_LOCAL }
  ACMDRIVERDETAILS_SUPPORTF_LOCAL     = $40000000;

//  ACMDRIVERDETAILS_SUPPORTF_DISABLED: this flag is set _by the ACM_ if a
//  driver has been disabled. this flag is also passed set in the fdwSupport
//  argument to the enumeration callback function for drivers.
  {$EXTERNALSYM ACMDRIVERDETAILS_SUPPORTF_DISABLED }
  ACMDRIVERDETAILS_SUPPORTF_DISABLED  = $80000000;

{$EXTERNALSYM acm_DriverDetailsA }
function acm_driverDetailsA(hadid: hACMDRIVERID; padd: pACMDRIVERDETAILSA; fdwDetails: DWORD): MMRESULT; stdcall;
{$EXTERNALSYM acm_DriverDetailsW }
function acm_driverDetailsW(hadid: hACMDRIVERID; padd: pACMDRIVERDETAILSW; fdwDetails: DWORD): MMRESULT; stdcall;
{$EXTERNALSYM acm_DriverDetails }
function acm_driverDetails (hadid: hACMDRIVERID; padd: pACMDRIVERDETAILS; fdwDetails: DWORD): MMRESULT; stdcall;

//--------------------------------------------------------------------------
//
//  ACM Format Tags
//
const
  {$EXTERNALSYM ACMFORMATTAGDETAILS_FORMATTAG_CHARS }
  ACMFORMATTAGDETAILS_FORMATTAG_CHARS = 48;

type
  pACMFORMATTAGDETAILSA = ^ACMFORMATTAGDETAILSA;
  {$EXTERNALSYM ACMFORMATTAGDETAILSA }
  ACMFORMATTAGDETAILSA = record
    cbStruct         : DWORD;
    dwFormatTagIndex : DWORD;
    dwFormatTag      : DWORD;
    cbFormatSize     : DWORD;
    fdwSupport       : DWORD;
    cStandardFormats : DWORD;
    szFormatTag      : array[0..ACMFORMATTAGDETAILS_FORMATTAG_CHARS - 1] of aChar;
  end;

  pACMFORMATTAGDETAILSW = ^ACMFORMATTAGDETAILSW;
  {$EXTERNALSYM ACMFORMATTAGDETAILSW }
  ACMFORMATTAGDETAILSW = record
    cbStruct         : DWORD;
    dwFormatTagIndex : DWORD;
    dwFormatTag      : DWORD;
    cbFormatSize     : DWORD;
    fdwSupport       : DWORD;
    cStandardFormats : DWORD;
    szFormatTag      : array[0..ACMFORMATTAGDETAILS_FORMATTAG_CHARS - 1] of wChar;
  end;

  {$EXTERNALSYM ACMFORMATTAGDETAILS }
  ACMFORMATTAGDETAILS = ACMFORMATTAGDETAILSA;
  pACMFORMATTAGDETAILS = pACMFORMATTAGDETAILSA;

{$EXTERNALSYM acm_FormatTagDetailsA }
function acm_formatTagDetailsA(had: HACMDRIVER; paftd: pACMFORMATTAGDETAILSA; fdwDetails: DWORD): MMRESULT; stdcall;
{$EXTERNALSYM acm_FormatTagDetailsW }
function acm_formatTagDetailsW(had: HACMDRIVER; paftd: pACMFORMATTAGDETAILSW; fdwDetails: DWORD): MMRESULT; stdcall;
{$EXTERNALSYM acm_FormatTagDetails }
function acm_formatTagDetails (had: HACMDRIVER; paftd: pACMFORMATTAGDETAILS; fdwDetails: DWORD): MMRESULT; stdcall;

const
  {$EXTERNALSYM ACM_FORMATTAGDETAILSF_INDEX }
  ACM_FORMATTAGDETAILSF_INDEX         = $00000000;
  {$EXTERNALSYM ACM_FORMATTAGDETAILSF_FORMATTAG }
  ACM_FORMATTAGDETAILSF_FORMATTAG     = $00000001;
  {$EXTERNALSYM ACM_FORMATTAGDETAILSF_LARGESTSIZE }
  ACM_FORMATTAGDETAILSF_LARGESTSIZE   = $00000002;
  {$EXTERNALSYM ACM_FORMATTAGDETAILSF_QUERYMASK }
  ACM_FORMATTAGDETAILSF_QUERYMASK     = $0000000F;

type
  {$EXTERNALSYM ACMFORMATTAGENUMCBA }
  ACMFORMATTAGENUMCBA = function(hadid: HACMDRIVERID; paftd: pACMFORMATTAGDETAILSA; dwInstance: DWORD; fdwSupport: DWORD): Windows.BOOL; stdcall;
  {$EXTERNALSYM ACMFORMATTAGENUMCBW }
  ACMFORMATTAGENUMCBW = function(hadid: HACMDRIVERID; paftd: pACMFORMATTAGDETAILSW; dwInstance: DWORD; fdwSupport: DWORD): Windows.BOOL; stdcall;
  {$EXTERNALSYM ACMFORMATTAGENUMCB }
  ACMFORMATTAGENUMCB = ACMFORMATTAGENUMCBA;

{$EXTERNALSYM acm_FormatTagEnumA }
function acm_formatTagEnumA(had: HACMDRIVER; paftd: pACMFORMATTAGDETAILSA; fnCallback: ACMFORMATTAGENUMCBA; dwInstance: DWORD; fdwEnum: DWORD): MMRESULT; stdcall;
{$EXTERNALSYM acm_FormatTagEnumW }
function acm_formatTagEnumW(had: HACMDRIVER; paftd: pACMFORMATTAGDETAILSW; fnCallback: ACMFORMATTAGENUMCBW; dwInstance: DWORD; fdwEnum: DWORD): MMRESULT; stdcall;
{$EXTERNALSYM acm_FormatTagEnum }
function acm_formatTagEnum (had: HACMDRIVER; paftd: pACMFORMATTAGDETAILS;  fnCallback: ACMFORMATTAGENUMCB; dwInstance: DWORD; fdwEnum: DWORD): MMRESULT; stdcall;

//--------------------------------------------------------------------------;
//
//  ACM Formats
//
const
  {$EXTERNALSYM ACMFORMATDETAILS_FORMAT_CHARS }
  ACMFORMATDETAILS_FORMAT_CHARS   = 128;

type
  pACMFORMATDETAILSA = ^ACMFORMATDETAILSA;
  {$EXTERNALSYM ACMFORMATDETAILSA }
  ACMFORMATDETAILSA = record
    cbStruct      : DWORD;
    dwFormatIndex : DWORD;
    dwFormatTag   : DWORD;
    fdwSupport    : DWORD;
    pwfx          : PWAVEFORMATEX;
    cbwfx         : DWORD;
    szFormat      : array[0..ACMFORMATDETAILS_FORMAT_CHARS - 1] of aChar;
  end;

  pACMFORMATDETAILSW = ^ACMFORMATDETAILSW;
  {$EXTERNALSYM ACMFORMATDETAILSW }
  ACMFORMATDETAILSW = record
    cbStruct      : DWORD;
    dwFormatIndex : DWORD;
    dwFormatTag   : DWORD;
    fdwSupport    : DWORD;
    pwfx          : PWAVEFORMATEX;
    cbwfx         : DWORD;
    szFormat      : array[0..ACMFORMATDETAILS_FORMAT_CHARS - 1] of wChar;
  end;

type
  pACMFORMATDETAILS = pACMFORMATDETAILSA;
  {$EXTERNALSYM ACMFORMATDETAILS }
  ACMFORMATDETAILS = ACMFORMATDETAILSA;

{$EXTERNALSYM acm_FormatDetailsA }
function acm_formatDetailsA(had: HACMDRIVER; pafd: pACMFORMATDETAILSA; fdwDetails: DWORD): MMRESULT; stdcall;
{$EXTERNALSYM acm_FormatDetailsW }
function acm_formatDetailsW(had: HACMDRIVER; pafd: pACMFORMATDETAILSW; fdwDetails: DWORD): MMRESULT; stdcall;
{$EXTERNALSYM acm_FormatDetails }
function acm_formatDetails (had: HACMDRIVER; pafd: pACMFORMATDETAILS; fdwDetails: DWORD): MMRESULT; stdcall;

const
  {$EXTERNALSYM ACM_FORMATDETAILSF_INDEX }
  ACM_FORMATDETAILSF_INDEX        = $00000000;
  {$EXTERNALSYM ACM_FORMATDETAILSF_FORMAT }
  ACM_FORMATDETAILSF_FORMAT       = $00000001;
  {$EXTERNALSYM ACM_FORMATDETAILSF_QUERYMASK }
  ACM_FORMATDETAILSF_QUERYMASK    = $0000000F;

type
  {$EXTERNALSYM ACMFORMATENUMCBA }
  ACMFORMATENUMCBA = function(hadid: HACMDRIVERID; pafd: pACMFORMATDETAILSA; dwInstance: DWORD; fdwSupport: DWORD): Windows.BOOL; stdcall;
  {$EXTERNALSYM ACMFORMATENUMCBW }
  ACMFORMATENUMCBW = function(hadid: HACMDRIVERID; pafd: pACMFORMATDETAILSW; dwInstance: DWORD; fdwSupport: DWORD): Windows.BOOL; stdcall;
  {$EXTERNALSYM ACMFORMATENUMCB }
  ACMFORMATENUMCB = ACMFORMATENUMCBA;

{$EXTERNALSYM acm_FormatEnumA }
function acm_formatEnumA(had: HACMDRIVER; pafd: pACMFORMATDETAILSA; fnCallback: ACMFORMATENUMCBA; dwInstance: DWORD; fdwEnum: DWORD): MMRESULT; stdcall;
{$EXTERNALSYM acm_FormatEnumW }
function acm_formatEnumW(had: HACMDRIVER; pafd: pACMFORMATDETAILSW; fnCallback: ACMFORMATENUMCBW; dwInstance: DWORD; fdwEnum: DWORD): MMRESULT; stdcall;
{$EXTERNALSYM acm_FormatEnum }
function acm_formatEnum (had: HACMDRIVER; pafd: pACMFORMATDETAILS;  fnCallback: ACMFORMATENUMCB; dwInstance: DWORD; fdwEnum: DWORD): MMRESULT; stdcall;

const
  {$EXTERNALSYM ACM_FORMATENUMF_WFORMATTAG }
  ACM_FORMATENUMF_WFORMATTAG       = $00010000;
  {$EXTERNALSYM ACM_FORMATENUMF_NCHANNELS }
  ACM_FORMATENUMF_NCHANNELS        = $00020000;
  {$EXTERNALSYM ACM_FORMATENUMF_NSAMPLESPERSEC }
  ACM_FORMATENUMF_NSAMPLESPERSEC   = $00040000;
  {$EXTERNALSYM ACM_FORMATENUMF_WBITSPERSAMPLE }
  ACM_FORMATENUMF_WBITSPERSAMPLE   = $00080000;
  {$EXTERNALSYM ACM_FORMATENUMF_CONVERT }
  ACM_FORMATENUMF_CONVERT          = $00100000;
  {$EXTERNALSYM ACM_FORMATENUMF_SUGGEST }
  ACM_FORMATENUMF_SUGGEST          = $00200000;
  {$EXTERNALSYM ACM_FORMATENUMF_HARDWARE }
  ACM_FORMATENUMF_HARDWARE         = $00400000;
  {$EXTERNALSYM ACM_FORMATENUMF_INPUT }
  ACM_FORMATENUMF_INPUT            = $00800000;
  {$EXTERNALSYM ACM_FORMATENUMF_OUTPUT }
  ACM_FORMATENUMF_OUTPUT           = $01000000;

{$EXTERNALSYM acm_FormatSuggest }
function acm_formatSuggest(had: HACMDRIVER; pwfxSrc: pWAVEFORMATEX; pwfxDst: pWAVEFORMATEX; cbwfxDst: DWORD; fdwSuggest: DWORD): MMRESULT; stdcall;

const
  {$EXTERNALSYM ACM_FORMATSUGGESTF_WFORMATTAG }
  ACM_FORMATSUGGESTF_WFORMATTAG       = $00010000;
  {$EXTERNALSYM ACM_FORMATSUGGESTF_NCHANNELS }
  ACM_FORMATSUGGESTF_NCHANNELS        = $00020000;
  {$EXTERNALSYM ACM_FORMATSUGGESTF_NSAMPLESPERSEC }
  ACM_FORMATSUGGESTF_NSAMPLESPERSEC   = $00040000;
  {$EXTERNALSYM ACM_FORMATSUGGESTF_WBITSPERSAMPLE }
  ACM_FORMATSUGGESTF_WBITSPERSAMPLE   = $00080000;

  {$EXTERNALSYM ACM_FORMATSUGGESTF_TYPEMASK }
  ACM_FORMATSUGGESTF_TYPEMASK         = $00FF0000;

  {$EXTERNALSYM ACMHELPMSGSTRINGA }
  ACMHELPMSGSTRINGA       = 'acmchoose_help';
  {$EXTERNALSYM ACMHELPMSGSTRINGW }
  ACMHELPMSGSTRINGW       = 'acmchoose_help';
  {$EXTERNALSYM ACMHELPMSGCONTEXTMENUA }
  ACMHELPMSGCONTEXTMENUA  = 'acmchoose_contextmenu';
  {$EXTERNALSYM ACMHELPMSGCONTEXTMENUW }
  ACMHELPMSGCONTEXTMENUW  = 'acmchoose_contextmenu';
  {$EXTERNALSYM ACMHELPMSGCONTEXTHELPA }
  ACMHELPMSGCONTEXTHELPA  = 'acmchoose_contexthelp';
  {$EXTERNALSYM ACMHELPMSGCONTEXTHELPW }
  ACMHELPMSGCONTEXTHELPW  = 'acmchoose_contexthelp';

  {$EXTERNALSYM ACMHELPMSGSTRING }
  ACMHELPMSGSTRING        = ACMHELPMSGSTRINGA;
  {$EXTERNALSYM ACMHELPMSGCONTEXTMENU }
  ACMHELPMSGCONTEXTMENU   = ACMHELPMSGCONTEXTMENUA;
  {$EXTERNALSYM ACMHELPMSGCONTEXTHELP }
  ACMHELPMSGCONTEXTHELP   = ACMHELPMSGCONTEXTHELPA;

  {$EXTERNALSYM MM_ACM_FORMATCHOOSE }
  MM_ACM_FORMATCHOOSE             = ($8000);

  {$EXTERNALSYM FORMATCHOOSE_MESSAGE }
  FORMATCHOOSE_MESSAGE            = 0;
  {$EXTERNALSYM FORMATCHOOSE_FORMATTAG_VERIFY }
  FORMATCHOOSE_FORMATTAG_VERIFY   = (FORMATCHOOSE_MESSAGE + 0);
  {$EXTERNALSYM FORMATCHOOSE_FORMAT_VERIFY }
  FORMATCHOOSE_FORMAT_VERIFY      = (FORMATCHOOSE_MESSAGE + 1);
  {$EXTERNALSYM FORMATCHOOSE_CUSTOM_VERIFY }
  FORMATCHOOSE_CUSTOM_VERIFY      = (FORMATCHOOSE_MESSAGE + 2);

type
  {$EXTERNALSYM ACMFORMATCHOOSEHOOKPROCA }
  ACMFORMATCHOOSEHOOKPROCA = function(hwnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): UINT; stdcall;
  {$EXTERNALSYM ACMFORMATCHOOSEHOOKPROCW }
  ACMFORMATCHOOSEHOOKPROCW = function(hwnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): UINT; stdcall;
  {$EXTERNALSYM ACMFORMATCHOOSEHOOKPROC }
  ACMFORMATCHOOSEHOOKPROC  = ACMFORMATCHOOSEHOOKPROCA;

  pACMFORMATCHOOSEA = ^ACMFORMATCHOOSEA;
  {$EXTERNALSYM ACMFORMATCHOOSEA }
  ACMFORMATCHOOSEA = record
    cbStruct        : DWORD;            	// sizeof(ACMFORMATCHOOSE)
    fdwStyle        : DWORD;            	// chooser style flags
    hwndOwner       : hWND;            		// caller's window handle
    pwfx            : pWAVEFORMATEX;            // ptr to wfx buf to receive choice
    cbwfx           : DWORD;            	// size of mem buf for pwfx
    pszTitle        : LPCSTR;            	// dialog box title bar
    szFormatTag     : array[0..ACMFORMATTAGDETAILS_FORMATTAG_CHARS-1] of aChar;
    szFormat        : array[0..ACMFORMATDETAILS_FORMAT_CHARS-1] of aChar;
    pszName         : LPSTR;            	// custom name selection
    cchName         : DWORD;            	// size in chars of mem buf for pszName
    fdwEnum         : DWORD;            	// format enumeration restrictions
    pwfxEnum        : pWAVEFORMATEX;            // format describing restrictions
    hInstance       : tHandle;            	// app instance containing dlg template
    pszTemplateName : LPCSTR;            	// custom template name
    lCustData       : LPARAM;            	// data passed to hook fn.
    pfnHook         : ACMFORMATCHOOSEHOOKPROCA;	// ptr to hook function
  end;

  pACMFORMATCHOOSEW = ^ACMFORMATCHOOSEW;
  {$EXTERNALSYM ACMFORMATCHOOSEW }
  ACMFORMATCHOOSEW = record
    cbStruct        : DWORD;            	// sizeof(ACMFORMATCHOOSE)
    fdwStyle        : DWORD;            	// chooser style flags
    hwndOwner       : hWND;            		// caller's window handle
    pwfx            : pWAVEFORMATEX;            // ptr to wfx buf to receive choice
    cbwfx           : DWORD;            	// size of mem buf for pwfx
    pszTitle        : LPCWSTR;          	// dialog box title bar
    szFormatTag     : array[0..ACMFORMATTAGDETAILS_FORMATTAG_CHARS-1] of wChar;
    szFormat        : array[0..ACMFORMATDETAILS_FORMAT_CHARS-1] of wChar;
    pszName         : LPWSTR;            	// custom name selection
    cchName         : DWORD;            	// size in chars of mem buf for pszName
    fdwEnum         : DWORD;            	// format enumeration restrictions
    pwfxEnum        : PWAVEFORMATEX;            // format describing restrictions
    hInstance       : tHandle;            	// app instance containing dlg template
    pszTemplateName : LPCWSTR;            	// custom template name
    lCustData       : LPARAM;            	// data passed to hook fn.
    pfnHook         : ACMFORMATCHOOSEHOOKPROCW;	// ptr to hook function
  end;

  {$EXTERNALSYM ACMFORMATCHOOSE }
  ACMFORMATCHOOSE = ACMFORMATCHOOSEA;
  pACMFORMATCHOOSE = pACMFORMATCHOOSEA;

const
  {$EXTERNALSYM ACMFORMATCHOOSE_STYLEF_SHOWHELP }
  ACMFORMATCHOOSE_STYLEF_SHOWHELP              = $00000004;
  {$EXTERNALSYM ACMFORMATCHOOSE_STYLEF_ENABLEHOOK }
  ACMFORMATCHOOSE_STYLEF_ENABLEHOOK            = $00000008;
  {$EXTERNALSYM ACMFORMATCHOOSE_STYLEF_ENABLETEMPLATE }
  ACMFORMATCHOOSE_STYLEF_ENABLETEMPLATE        = $00000010;
  {$EXTERNALSYM ACMFORMATCHOOSE_STYLEF_ENABLETEMPLATEHANDLE }
  ACMFORMATCHOOSE_STYLEF_ENABLETEMPLATEHANDLE  = $00000020;
  {$EXTERNALSYM ACMFORMATCHOOSE_STYLEF_INITTOWFXSTRUCT }
  ACMFORMATCHOOSE_STYLEF_INITTOWFXSTRUCT       = $00000040;
  {$EXTERNALSYM ACMFORMATCHOOSE_STYLEF_CONTEXTHELP }
  ACMFORMATCHOOSE_STYLEF_CONTEXTHELP           = $00000080;

{$EXTERNALSYM acm_FormatChooseA }
function acm_formatChooseA(pafmtc: pACMFORMATCHOOSEA): MMRESULT; stdcall;
{$EXTERNALSYM acm_FormatChooseW }
function acm_formatChooseW(pafmtc: pACMFORMATCHOOSEW): MMRESULT; stdcall;
{$EXTERNALSYM acm_FormatChoose }
function acm_formatChoose (pafmtc: pACMFORMATCHOOSE ): MMRESULT; stdcall;

//--------------------------------------------------------------------------;
//
//  ACM Filter Tags
//
const
  {$EXTERNALSYM ACMFILTERTAGDETAILS_FILTERTAG_CHARS }
  ACMFILTERTAGDETAILS_FILTERTAG_CHARS = 48;

type
  pACMFILTERTAGDETAILSA = ^ACMFILTERTAGDETAILSA;
  {$EXTERNALSYM ACMFILTERTAGDETAILSA }
  ACMFILTERTAGDETAILSA = record
    cbStruct         : DWORD;
    dwFilterTagIndex : DWORD;
    dwFilterTag      : DWORD;
    cbFilterSize     : DWORD;
    fdwSupport       : DWORD;
    cStandardFilters : DWORD;
    szFilterTag      : array[0..ACMFILTERTAGDETAILS_FILTERTAG_CHARS - 1] of aChar;
  end;

  pACMFILTERTAGDETAILSW = ^ACMFILTERTAGDETAILSW;
  {$EXTERNALSYM ACMFILTERTAGDETAILSW }
  ACMFILTERTAGDETAILSW = record
    cbStruct         : DWORD;
    dwFilterTagIndex : DWORD;
    dwFilterTag      : DWORD;
    cbFilterSize     : DWORD;
    fdwSupport       : DWORD;
    cStandardFilters : DWORD;
    szFilterTag      : array[0..ACMFILTERTAGDETAILS_FILTERTAG_CHARS - 1] of wChar;
  end;

  {$EXTERNALSYM ACMFILTERTAGDETAILS }
  ACMFILTERTAGDETAILS = ACMFILTERTAGDETAILSA;
  pACMFILTERTAGDETAILS = pACMFILTERTAGDETAILSA;

{$EXTERNALSYM acm_FilterTagDetailsA }
function acm_filterTagDetailsA(had: HACMDRIVER; paftd: pACMFILTERTAGDETAILSA; fdwDetails: DWORD): MMRESULT; stdcall;
{$EXTERNALSYM acm_FilterTagDetailsW }
function acm_filterTagDetailsW(had: HACMDRIVER; paftd: pACMFILTERTAGDETAILSW; fdwDetails: DWORD): MMRESULT; stdcall;
{$EXTERNALSYM acm_FilterTagDetails }
function acm_filterTagDetails (had: HACMDRIVER; paftd: pACMFILTERTAGDETAILS;  fdwDetails: DWORD): MMRESULT; stdcall;

const
  {$EXTERNALSYM ACM_FILTERTAGDETAILSF_INDEX }
  ACM_FILTERTAGDETAILSF_INDEX         = $00000000;
  {$EXTERNALSYM ACM_FILTERTAGDETAILSF_FILTERTAG }
  ACM_FILTERTAGDETAILSF_FILTERTAG     = $00000001;
  {$EXTERNALSYM ACM_FILTERTAGDETAILSF_LARGESTSIZE }
  ACM_FILTERTAGDETAILSF_LARGESTSIZE   = $00000002;
  {$EXTERNALSYM ACM_FILTERTAGDETAILSF_QUERYMASK }
  ACM_FILTERTAGDETAILSF_QUERYMASK     = $0000000F;

type
  {$EXTERNALSYM ACMFILTERTAGENUMCBA }
  ACMFILTERTAGENUMCBA = function(hadid: HACMDRIVERID; paftd: pACMFILTERTAGDETAILSA; dwInstance: DWORD; fdwSupport: DWORD): Windows.BOOL; stdcall;
  {$EXTERNALSYM ACMFILTERTAGENUMCBW }
  ACMFILTERTAGENUMCBW = function(hadid: HACMDRIVERID; paftd: pACMFILTERTAGDETAILSW; dwInstance: DWORD; fdwSupport: DWORD): Windows.BOOL; stdcall;
  {$EXTERNALSYM ACMFILTERTAGENUMCB }
  ACMFILTERTAGENUMCB  = ACMFILTERTAGENUMCBA;

{$EXTERNALSYM acm_FilterTagEnumA }
function acm_filterTagEnumA(had: HACMDRIVER; paftd: pACMFILTERTAGDETAILSA; fnCallback: ACMFILTERTAGENUMCBA; dwInstance: DWORD; fdwEnum: DWORD): MMRESULT; stdcall;
{$EXTERNALSYM acm_FilterTagEnumW }
function acm_filterTagEnumW(had: HACMDRIVER; paftd: pACMFILTERTAGDETAILSW; fnCallback: ACMFILTERTAGENUMCBW; dwInstance: DWORD; fdwEnum: DWORD): MMRESULT; stdcall;
{$EXTERNALSYM acm_FilterTagEnum }
function acm_filterTagEnum (had: HACMDRIVER; paftd: pACMFILTERTAGDETAILS;  fnCallback: ACMFILTERTAGENUMCB;  dwInstance: DWORD; fdwEnum: DWORD): MMRESULT; stdcall;

//--------------------------------------------------------------------------;
//
//  ACM Filters
//
const
  {$EXTERNALSYM ACMFILTERDETAILS_FILTER_CHARS }
  ACMFILTERDETAILS_FILTER_CHARS   = 128;

type
  pACMFILTERDETAILSA = ^ACMFILTERDETAILSA;
  {$EXTERNALSYM ACMFILTERDETAILSA }
  ACMFILTERDETAILSA = record
    cbStruct      : DWORD;
    dwFilterIndex : DWORD;
    dwFilterTag   : DWORD;
    fdwSupport    : DWORD;
    pwfltr        : pWAVEFILTER;
    cbwfltr       : DWORD;
    szFilter      : array[0..ACMFILTERDETAILS_FILTER_CHARS - 1] of aChar;
  end;

  pACMFILTERDETAILSW = ^ACMFILTERDETAILSW;
  {$EXTERNALSYM ACMFILTERDETAILSW }
  ACMFILTERDETAILSW = record
    cbStruct      : DWORD;
    dwFilterIndex : DWORD;
    dwFilterTag   : DWORD;
    fdwSupport    : DWORD;
    pwfltr        : pWAVEFILTER;
    cbwfltr       : DWORD;
    szFilter      : array[0..ACMFILTERDETAILS_FILTER_CHARS - 1] of wChar;
  end;

  {$EXTERNALSYM ACMFILTERDETAILS }
  ACMFILTERDETAILS = ACMFILTERDETAILSA;
  pACMFILTERDETAILS = pACMFILTERDETAILSA;

{$EXTERNALSYM acm_FilterDetailsA }
function acm_filterDetailsA(had: HACMDRIVER; pafd: pACMFILTERDETAILSA; fdwDetails: DWORD): MMRESULT; stdcall;
{$EXTERNALSYM acm_FilterDetailsW }
function acm_filterDetailsW(had: HACMDRIVER; pafd: pACMFILTERDETAILSW; fdwDetails: DWORD): MMRESULT; stdcall;
{$EXTERNALSYM acm_FilterDetails }
function acm_filterDetails (had: HACMDRIVER; pafd: pACMFILTERDETAILS;  fdwDetails: DWORD): MMRESULT; stdcall;

const
  {$EXTERNALSYM ACM_FILTERDETAILSF_INDEX }
  ACM_FILTERDETAILSF_INDEX        = $00000000;
  {$EXTERNALSYM ACM_FILTERDETAILSF_FILTER }
  ACM_FILTERDETAILSF_FILTER       = $00000001;
  {$EXTERNALSYM ACM_FILTERDETAILSF_QUERYMASK }
  ACM_FILTERDETAILSF_QUERYMASK    = $0000000F;

type
  {$EXTERNALSYM ACMFILTERENUMCBA }
  ACMFILTERENUMCBA = function(hadid: hACMDRIVERID; pafd: pACMFILTERDETAILSA; dwInstance: DWORD; fdwSupport: DWORD): Windows.BOOL; stdcall;
  {$EXTERNALSYM ACMFILTERENUMCBW }
  ACMFILTERENUMCBW = function(hadid: hACMDRIVERID; pafd: pACMFILTERDETAILSW; dwInstance: DWORD; fdwSupport: DWORD): Windows.BOOL; stdcall;
  {$EXTERNALSYM ACMFILTERENUMCB }
  ACMFILTERENUMCB = ACMFILTERENUMCBA;

{$EXTERNALSYM acm_FilterEnumA }
function acm_filterEnumA(had: HACMDRIVER; pafd: pACMFILTERDETAILSA; fnCallback: ACMFILTERENUMCBA; dwInstance: DWORD; fdwEnum: DWORD): MMRESULT; stdcall;
{$EXTERNALSYM acm_FilterEnumW }
function acm_filterEnumW(had: HACMDRIVER; pafd: pACMFILTERDETAILSW; fnCallback: ACMFILTERENUMCBW; dwInstance: DWORD; fdwEnum: DWORD): MMRESULT; stdcall;
{$EXTERNALSYM acm_FilterEnum }
function acm_filterEnum (had: HACMDRIVER; pafd: pACMFILTERDETAILS;  fnCallback: ACMFILTERENUMCB;  dwInstance: DWORD; fdwEnum: DWORD): MMRESULT; stdcall;

const
  {$EXTERNALSYM ACM_FILTERENUMF_DWFILTERTAG }
  ACM_FILTERENUMF_DWFILTERTAG	= $00010000;

//
//  MM_ACM_FILTERCHOOSE is sent to hook callbacks by the Filter Chooser
//  Dialog...
//
  {$EXTERNALSYM MM_ACM_FILTERCHOOSE }
  MM_ACM_FILTERCHOOSE          	= ($8000);

  {$EXTERNALSYM FILTERCHOOSE_MESSAGE }
  FILTERCHOOSE_MESSAGE			= 0;
  {$EXTERNALSYM FILTERCHOOSE_FILTERTAG_VERIFY }
  FILTERCHOOSE_FILTERTAG_VERIFY   	= (FILTERCHOOSE_MESSAGE+0);
  {$EXTERNALSYM FILTERCHOOSE_FILTER_VERIFY }
  FILTERCHOOSE_FILTER_VERIFY      	= (FILTERCHOOSE_MESSAGE+1);
  {$EXTERNALSYM FILTERCHOOSE_CUSTOM_VERIFY }
  FILTERCHOOSE_CUSTOM_VERIFY      	= (FILTERCHOOSE_MESSAGE+2);

type
  {$EXTERNALSYM ACMFILTERCHOOSEHOOKPROCA }
  ACMFILTERCHOOSEHOOKPROCA = function(hwnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): UINT; stdcall;
  {$EXTERNALSYM ACMFILTERCHOOSEHOOKPROCW }
  ACMFILTERCHOOSEHOOKPROCW = function(hwnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): UINT; stdcall;
  {$EXTERNALSYM ACMFILTERCHOOSEHOOKPROC }
  ACMFILTERCHOOSEHOOKPROC  = ACMFILTERCHOOSEHOOKPROCA;

  pACMFILTERCHOOSEA = ^ACMFILTERCHOOSEA;
  {$EXTERNALSYM ACMFILTERCHOOSEA }
  ACMFILTERCHOOSEA = record
    cbStruct        : DWORD;            	// sizeof(ACMFILTERCHOOSE)
    fdwStyle        : DWORD;            	// chooser style flags
    hwndOwner       : hWND;            		// caller's window handle
    pwfltr          : pWAVEFILTER;            	// ptr to wfltr buf to receive choice
    cbwfltr         : DWORD;            	// size of mem buf for pwfltr
    pszTitle        : LPCSTR;
    szFilterTag     : array[0..ACMFILTERTAGDETAILS_FILTERTAG_CHARS - 1] of aChar;
    szFilter        : array[0..ACMFILTERDETAILS_FILTER_CHARS - 1] of aChar;
    pszName         : LPSTR;            	// custom name selection
    cchName         : DWORD;            	// size in chars of mem buf for pszName
    fdwEnum         : DWORD;            	// filter enumeration restrictions
    pwfltrEnum      : pWAVEFILTER;            	// filter describing restrictions
    hInstance       : tHandle;            	// app instance containing dlg template
    pszTemplateName : LPCSTR;            	// custom template name
    lCustData       : LPARAM;            	// data passed to hook fn.
    pfnHook         : ACMFILTERCHOOSEHOOKPROCA;	// ptr to hook function
  end;

  pACMFILTERCHOOSEW = ^ACMFILTERCHOOSEW;
  {$EXTERNALSYM ACMFILTERCHOOSEW }
  ACMFILTERCHOOSEW = record
    cbStruct        : DWORD;            	// sizeof(ACMFILTERCHOOSE)
    fdwStyle        : DWORD;            	// chooser style flags
    hwndOwner       : hWND;            		// caller's window handle
    pwfltr          : pWAVEFILTER;            	// ptr to wfltr buf to receive choice
    cbwfltr         : DWORD;            	// size of mem buf for pwfltr
    pszTitle        : LPCWSTR;
    szFilterTag     : array[0..ACMFILTERTAGDETAILS_FILTERTAG_CHARS - 1] of wChar;
    szFilter        : array[0..ACMFILTERDETAILS_FILTER_CHARS - 1] of wChar;
    pszName         : LPWSTR;            	// custom name selection
    cchName         : DWORD;            	// size in chars of mem buf for pszName
    fdwEnum         : DWORD;            	// filter enumeration restrictions
    pwfltrEnum      : pWAVEFILTER;            	// filter describing restrictions
    hInstance       : tHandle;            	// app instance containing dlg template
    pszTemplateName : LPCWSTR;            	// custom template name
    lCustData       : LPARAM;            	// data passed to hook fn.
    pfnHook         : ACMFILTERCHOOSEHOOKPROCW;	// ptr to hook function
  end;

  {$EXTERNALSYM ACMFILTERCHOOSE }
  ACMFILTERCHOOSE = ACMFILTERCHOOSEA;
  pACMFILTERCHOOSE = pACMFILTERCHOOSEA;

const
//  ACMFILTERCHOOSE.fdwStyle
  {$EXTERNALSYM ACMFILTERCHOOSE_STYLEF_SHOWHELP }
  ACMFILTERCHOOSE_STYLEF_SHOWHELP              = $00000004;
  {$EXTERNALSYM ACMFILTERCHOOSE_STYLEF_ENABLEHOOK }
  ACMFILTERCHOOSE_STYLEF_ENABLEHOOK            = $00000008;
  {$EXTERNALSYM ACMFILTERCHOOSE_STYLEF_ENABLETEMPLATE }
  ACMFILTERCHOOSE_STYLEF_ENABLETEMPLATE        = $00000010;
  {$EXTERNALSYM ACMFILTERCHOOSE_STYLEF_ENABLETEMPLATEHANDLE }
  ACMFILTERCHOOSE_STYLEF_ENABLETEMPLATEHANDLE  = $00000020;
  {$EXTERNALSYM ACMFILTERCHOOSE_STYLEF_INITTOFILTERSTRUCT }
  ACMFILTERCHOOSE_STYLEF_INITTOFILTERSTRUCT    = $00000040;
  {$EXTERNALSYM ACMFILTERCHOOSE_STYLEF_CONTEXTHELP }
  ACMFILTERCHOOSE_STYLEF_CONTEXTHELP           = $00000080;

{$EXTERNALSYM acm_FilterChooseA }
function acm_filterChooseA(pafltrc: pACMFILTERCHOOSEA): MMRESULT; stdcall;
{$EXTERNALSYM acm_FilterChooseW }
function acm_filterChooseW(pafltrc: pACMFILTERCHOOSEW): MMRESULT; stdcall;
{$EXTERNALSYM acm_FilterChoose }
function acm_filterChoose (pafltrc: pACMFILTERCHOOSE): MMRESULT; stdcall;

//--------------------------------------------------------------------------;
//
//  ACM Stream API's

const
  //#ifdef  _WIN64
  {$IFDEF CPU64 }
    //#define _DRVRESERVED    15
    _DRVRESERVED = 15;
  //#else
  {$ELSE }
    //#define _DRVRESERVED    10
    _DRVRESERVED = 10;
  //#endif  // _WIN64
  {$ENDIF CPU64 }

type
  pACMSTREAMHEADER = ^ACMSTREAMHEADER;
  {$EXTERNALSYM ACMSTREAMHEADER }

  ACMSTREAMHEADER = record
    cbStruct         : DWORD;              	// sizeof(ACMSTREAMHEADER)
    fdwStatus        : DWORD;              	// ACMSTREAMHEADER_STATUSF_*
    dwUser           : DWORD_PTR;              	// user instance data for hdr
    pbSrc            : PBYTE;
    cbSrcLength      : DWORD;
    cbSrcLengthUsed  : DWORD;
    dwSrcUser        : DWORD_PTR;             	// user instance data for src
    pbDst            : PBYTE;
    cbDstLength      : DWORD;
    cbDstLengthUsed  : DWORD;
    dwDstUser        : DWORD_PTR;              	// user instance data for dst
    dwReservedDriver : array [0.._DRVRESERVED - 1] of DWORD;	// driver reserved work space
  end;

const
//  ACMSTREAMHEADER.fdwStatus
//
//  ACMSTREAMHEADER_STATUSF_DONE: done bit for async conversions.
  {$EXTERNALSYM ACMSTREAMHEADER_STATUSF_DONE }
  ACMSTREAMHEADER_STATUSF_DONE     = $00010000;
  {$EXTERNALSYM ACMSTREAMHEADER_STATUSF_PREPARED }
  ACMSTREAMHEADER_STATUSF_PREPARED = $00020000;
  {$EXTERNALSYM ACMSTREAMHEADER_STATUSF_INQUEUE }
  ACMSTREAMHEADER_STATUSF_INQUEUE  = $00100000;

  {$EXTERNALSYM ACM_STREAMOPENF_QUERY }
  ACM_STREAMOPENF_QUERY           = $00000001;
  {$EXTERNALSYM ACM_STREAMOPENF_ASYNC }
  ACM_STREAMOPENF_ASYNC           = $00000002;
  {$EXTERNALSYM ACM_STREAMOPENF_NONREALTIME }
  ACM_STREAMOPENF_NONREALTIME     = $00000004;

  {$EXTERNALSYM ACM_STREAMSIZEF_SOURCE }
  ACM_STREAMSIZEF_SOURCE          = $00000000;
  {$EXTERNALSYM ACM_STREAMSIZEF_DESTINATION }
  ACM_STREAMSIZEF_DESTINATION     = $00000001;
  {$EXTERNALSYM ACM_STREAMSIZEF_QUERYMASK }
  ACM_STREAMSIZEF_QUERYMASK       = $0000000F;

  {$EXTERNALSYM ACM_STREAMCONVERTF_BLOCKALIGN }
  ACM_STREAMCONVERTF_BLOCKALIGN   = $00000004;
  {$EXTERNALSYM ACM_STREAMCONVERTF_START }
  ACM_STREAMCONVERTF_START        = $00000010;
  {$EXTERNALSYM ACM_STREAMCONVERTF_END }
  ACM_STREAMCONVERTF_END          = $00000020;

{$EXTERNALSYM acm_StreamOpen }
function acm_streamOpen(phas: pHACMSTREAM; had: HACMDRIVER; pwfxSrc: pWAVEFORMATEX; pwfxdst: pWAVEFORMATEX; pwfltr: pWAVEFILTER; dwCallback: DWORD; dwInstance: DWORD; fdwOpen: DWORD): MMRESULT; stdcall;
{$EXTERNALSYM acm_StreamClose }
function acm_streamClose(has: HACMSTREAM; fdwClose: DWORD): MMRESULT; stdcall;
{$EXTERNALSYM acm_StreamSize }
function acm_streamSize(has: HACMSTREAM; cbInput: DWORD; var pdwOutputByte: DWORD; fdwSize: DWORD): MMRESULT; stdcall;
{$EXTERNALSYM acm_StreamReset }
function acm_streamReset(has: HACMSTREAM; fdwReset: DWORD): MMRESULT; stdcall;
{$EXTERNALSYM acm_StreamMessage }
function acm_streamMessage(has: HACMSTREAM; uMsg: UINT; lParam1: LPARAM; lParam2: LPARAM): MMRESULT; stdcall;
{$EXTERNALSYM acm_StreamConvert }
function acm_streamConvert(has: HACMSTREAM; pash: pACMSTREAMHEADER; fdwConvert: DWORD): MMRESULT; stdcall;
{$EXTERNALSYM acm_StreamPrepareHeader }
function acm_streamPrepareHeader(has: HACMSTREAM; pash: pACMSTREAMHEADER; fdwPrepare: DWORD): MMRESULT; stdcall;
{$EXTERNALSYM acm_StreamUnprepareHeader }
function acm_streamUnprepareHeader(has: HACMSTREAM; pash: pACMSTREAMHEADER; fdwUnprepare: DWORD): MMRESULT; stdcall;

// back to  MMREG.H

const
{$EXTERNALSYM MM_MICROSOFT				}
{$EXTERNALSYM MM_CREATIVE                               }
{$EXTERNALSYM MM_MEDIAVISION                            }
{$EXTERNALSYM MM_FUJITSU                                }
{$EXTERNALSYM MM_PRAGMATRAX                             }
{$EXTERNALSYM MM_CYRIX                                  }
{$EXTERNALSYM MM_PHILIPS_SPEECH_PROCESSING              }
{$EXTERNALSYM MM_NETXL                                  }
{$EXTERNALSYM MM_ZYXEL                                  }
{$EXTERNALSYM MM_BECUBED                                }
{$EXTERNALSYM MM_AARDVARK                               }
{$EXTERNALSYM MM_BINTEC                                 }
{$EXTERNALSYM MM_HEWLETT_PACKARD                        }
{$EXTERNALSYM MM_ACULAB                                 }
{$EXTERNALSYM MM_FAITH                                  }
{$EXTERNALSYM MM_MITEL                                  }
{$EXTERNALSYM MM_QUANTUM3D                              }
{$EXTERNALSYM MM_SNI                                    }
{$EXTERNALSYM MM_EMU                                    }
{$EXTERNALSYM MM_ARTISOFT                               }
{$EXTERNALSYM MM_TURTLE_BEACH                           }
{$EXTERNALSYM MM_IBM                                    }
{$EXTERNALSYM MM_VOCALTEC                               }
{$EXTERNALSYM MM_ROLAND                                 }
{$EXTERNALSYM MM_DSP_SOLUTIONS                          }
{$EXTERNALSYM MM_NEC                                    }
{$EXTERNALSYM MM_ATI                                    }
{$EXTERNALSYM MM_WANGLABS                               }
{$EXTERNALSYM MM_TANDY                                  }
{$EXTERNALSYM MM_VOYETRA                                }
{$EXTERNALSYM MM_ANTEX                                  }
{$EXTERNALSYM MM_ICL_PS                                 }
{$EXTERNALSYM MM_INTEL                                  }
{$EXTERNALSYM MM_GRAVIS                                 }
{$EXTERNALSYM MM_VAL                                    }
{$EXTERNALSYM MM_INTERACTIVE                            }
{$EXTERNALSYM MM_YAMAHA                                 }
{$EXTERNALSYM MM_EVEREX                                 }
{$EXTERNALSYM MM_ECHO                                   }
{$EXTERNALSYM MM_SIERRA                                 }
{$EXTERNALSYM MM_CAT                                    }
{$EXTERNALSYM MM_APPS                                   }
{$EXTERNALSYM MM_DSP_GROUP                              }
{$EXTERNALSYM MM_MELABS                                 }
{$EXTERNALSYM MM_COMPUTER_FRIENDS                       }
{$EXTERNALSYM MM_ESS                                    }
{$EXTERNALSYM MM_AUDIOFILE                              }
{$EXTERNALSYM MM_MOTOROLA                               }
{$EXTERNALSYM MM_CANOPUS                                }
{$EXTERNALSYM MM_EPSON                                  }
{$EXTERNALSYM MM_TRUEVISION                             }
{$EXTERNALSYM MM_AZTECH                                 }
{$EXTERNALSYM MM_VIDEOLOGIC                             }
{$EXTERNALSYM MM_SCALACS                                }
{$EXTERNALSYM MM_KORG                                   }
{$EXTERNALSYM MM_APT                                    }
{$EXTERNALSYM MM_ICS                                    }
{$EXTERNALSYM MM_ITERATEDSYS                            }
{$EXTERNALSYM MM_METHEUS                                }
{$EXTERNALSYM MM_LOGITECH                               }
{$EXTERNALSYM MM_WINNOV                                 }
{$EXTERNALSYM MM_NCR                                    }
{$EXTERNALSYM MM_EXAN                                   }
{$EXTERNALSYM MM_AST                                    }
{$EXTERNALSYM MM_WILLOWPOND                             }
{$EXTERNALSYM MM_SONICFOUNDRY                           }
{$EXTERNALSYM MM_VITEC                                  }
{$EXTERNALSYM MM_MOSCOM                                 }
{$EXTERNALSYM MM_SILICONSOFT                            }
{$EXTERNALSYM MM_TERRATEC                               }
{$EXTERNALSYM MM_MEDIASONIC                             }
{$EXTERNALSYM MM_SANYO                                  }
{$EXTERNALSYM MM_SUPERMAC                               }
{$EXTERNALSYM MM_AUDIOPT                                }
{$EXTERNALSYM MM_NOGATECH                               }
{$EXTERNALSYM MM_SPEECHCOMP                             }
{$EXTERNALSYM MM_AHEAD                                  }
{$EXTERNALSYM MM_DOLBY                                  }
{$EXTERNALSYM MM_OKI                                    }
{$EXTERNALSYM MM_AURAVISION                             }
{$EXTERNALSYM MM_OLIVETTI                               }
{$EXTERNALSYM MM_IOMAGIC                                }
{$EXTERNALSYM MM_MATSUSHITA                             }
{$EXTERNALSYM MM_CONTROLRES                             }
{$EXTERNALSYM MM_XEBEC                                  }
{$EXTERNALSYM MM_NEWMEDIA                               }
{$EXTERNALSYM MM_NMS                                    }
{$EXTERNALSYM MM_LYRRUS                                 }
{$EXTERNALSYM MM_COMPUSIC                               }
{$EXTERNALSYM MM_OPTI                                   }
{$EXTERNALSYM MM_ADLACC                                 }
{$EXTERNALSYM MM_COMPAQ                                 }
{$EXTERNALSYM MM_DIALOGIC                               }
{$EXTERNALSYM MM_INSOFT                                 }
{$EXTERNALSYM MM_MPTUS                                  }
{$EXTERNALSYM MM_WEITEK                                 }
{$EXTERNALSYM MM_LERNOUT_AND_HAUSPIE                    }
{$EXTERNALSYM MM_QCIAR                                  }
{$EXTERNALSYM MM_APPLE                                  }
{$EXTERNALSYM MM_DIGITAL                                }
{$EXTERNALSYM MM_MOTU                                   }
{$EXTERNALSYM MM_WORKBIT                                }
{$EXTERNALSYM MM_OSITECH                                }
{$EXTERNALSYM MM_MIRO                                   }
{$EXTERNALSYM MM_CIRRUSLOGIC                            }
{$EXTERNALSYM MM_ISOLUTION                              }
{$EXTERNALSYM MM_HORIZONS                               }
{$EXTERNALSYM MM_CONCEPTS                               }
{$EXTERNALSYM MM_VTG                                    }
{$EXTERNALSYM MM_RADIUS                                 }
{$EXTERNALSYM MM_ROCKWELL                               }
{$EXTERNALSYM MM_XYZ                                    }
{$EXTERNALSYM MM_OPCODE                                 }
{$EXTERNALSYM MM_VOXWARE                                }
{$EXTERNALSYM MM_NORTHERN_TELECOM                       }
{$EXTERNALSYM MM_APICOM                                 }
{$EXTERNALSYM MM_GRANDE                                 }
{$EXTERNALSYM MM_ADDX                                   }
{$EXTERNALSYM MM_WILDCAT                                }
{$EXTERNALSYM MM_RHETOREX                               }
{$EXTERNALSYM MM_BROOKTREE                              }
{$EXTERNALSYM MM_ENSONIQ                                }
{$EXTERNALSYM MM_FAST                                   }
{$EXTERNALSYM MM_NVIDIA                                 }
{$EXTERNALSYM MM_OKSORI                                 }
{$EXTERNALSYM MM_DIACOUSTICS                            }
{$EXTERNALSYM MM_GULBRANSEN                             }
{$EXTERNALSYM MM_KAY_ELEMETRICS                         }
{$EXTERNALSYM MM_CRYSTAL                                }
{$EXTERNALSYM MM_SPLASH_STUDIOS                         }
{$EXTERNALSYM MM_QUARTERDECK                            }
{$EXTERNALSYM MM_TDK                                    }
{$EXTERNALSYM MM_DIGITAL_AUDIO_LABS                     }
{$EXTERNALSYM MM_SEERSYS                                }
{$EXTERNALSYM MM_PICTURETEL                             }
{$EXTERNALSYM MM_ATT_MICROELECTRONICS                   }
{$EXTERNALSYM MM_OSPREY                                 }
{$EXTERNALSYM MM_MEDIATRIX                              }
{$EXTERNALSYM MM_SOUNDESIGNS                            }
{$EXTERNALSYM MM_ALDIGITAL                              }
{$EXTERNALSYM MM_SPECTRUM_SIGNAL_PROCESSING             }
{$EXTERNALSYM MM_ECS                                    }
{$EXTERNALSYM MM_AMD                                    }
{$EXTERNALSYM MM_COREDYNAMICS                           }
{$EXTERNALSYM MM_CANAM                                  }
{$EXTERNALSYM MM_SOFTSOUND                              }
{$EXTERNALSYM MM_NORRIS                                 }
{$EXTERNALSYM MM_DDD                                    }
{$EXTERNALSYM MM_EUPHONICS                              }
{$EXTERNALSYM MM_PRECEPT                                }
{$EXTERNALSYM MM_CRYSTAL_NET                            }
{$EXTERNALSYM MM_CHROMATIC                              }
{$EXTERNALSYM MM_VOICEINFO                              }
{$EXTERNALSYM MM_VIENNASYS                              }
{$EXTERNALSYM MM_CONNECTIX                              }
{$EXTERNALSYM MM_GADGETLABS                             }
{$EXTERNALSYM MM_FRONTIER                               }
{$EXTERNALSYM MM_VIONA                                  }
{$EXTERNALSYM MM_CASIO                                  }
{$EXTERNALSYM MM_DIAMONDMM                              }
{$EXTERNALSYM MM_S3                                     }
{$EXTERNALSYM MM_DVISION                                }
{$EXTERNALSYM MM_NETSCAPE                               }
{$EXTERNALSYM MM_SOUNDSPACE                             }
{$EXTERNALSYM MM_VANKOEVERING                           }
{$EXTERNALSYM MM_QTEAM                                  }
{$EXTERNALSYM MM_ZEFIRO                                 }
{$EXTERNALSYM MM_STUDER                                 }
{$EXTERNALSYM MM_FRAUNHOFER_IIS                         }
{$EXTERNALSYM MM_QUICKNET                               }
{$EXTERNALSYM MM_ALARIS                                 }
{$EXTERNALSYM MM_SICRESOURCE                            }
{$EXTERNALSYM MM_NEOMAGIC                               }
{$EXTERNALSYM MM_MERGING_TECHNOLOGIES                   }
{$EXTERNALSYM MM_XIRLINK                                }
{$EXTERNALSYM MM_COLORGRAPH                             }
{$EXTERNALSYM MM_OTI                                    }
{$EXTERNALSYM MM_AUREAL                                 }
{$EXTERNALSYM MM_VIVO                                   }
{$EXTERNALSYM MM_SHARP                                  }
{$EXTERNALSYM MM_LUCENT                                 }
{$EXTERNALSYM MM_ATT                                    }
{$EXTERNALSYM MM_SUNCOM                                 }
{$EXTERNALSYM MM_SORVIS                                 }
{$EXTERNALSYM MM_INVISION                               }
{$EXTERNALSYM MM_BERKOM                                 }
{$EXTERNALSYM MM_MARIAN                                 }
{$EXTERNALSYM MM_DPSINC                                 }
{$EXTERNALSYM MM_BCB                                    }
{$EXTERNALSYM MM_MOTIONPIXELS                           }
{$EXTERNALSYM MM_QDESIGN                                }
{$EXTERNALSYM MM_NMP                                    }
{$EXTERNALSYM MM_DATAFUSION                             }
{$EXTERNALSYM MM_DUCK                                   }
{$EXTERNALSYM MM_FTR                                    }
{$EXTERNALSYM MM_BERCOS                                 }
{$EXTERNALSYM MM_ONLIVE                                 }
{$EXTERNALSYM MM_SIEMENS_SBC                            }
{$EXTERNALSYM MM_TERALOGIC                              }
{$EXTERNALSYM MM_PHONET                                 }
{$EXTERNALSYM MM_WINBOND                                }
{$EXTERNALSYM MM_VIRTUALMUSIC                           }
{$EXTERNALSYM MM_ENET                                   }
{$EXTERNALSYM MM_GUILLEMOT                              }
{$EXTERNALSYM MM_EMAGIC                                 }
{$EXTERNALSYM MM_MWM                                    }
{$EXTERNALSYM MM_PACIFICRESEARCH                        }
{$EXTERNALSYM MM_SIPROLAB                               }
{$EXTERNALSYM MM_LYNX                                   }
{$EXTERNALSYM MM_SPECTRUM_PRODUCTIONS                   }
{$EXTERNALSYM MM_DICTAPHONE                             }
{$EXTERNALSYM MM_QUALCOMM                               }
{$EXTERNALSYM MM_RZS                                    }
{$EXTERNALSYM MM_AUDIOSCIENCE                           }
{$EXTERNALSYM MM_PINNACLE                               }
{$EXTERNALSYM MM_EES                                    }
{$EXTERNALSYM MM_HAFTMANN                               }
{$EXTERNALSYM MM_LUCID                                  }
{$EXTERNALSYM MM_HEADSPACE                              }
{$EXTERNALSYM MM_UNISYS                                 }
{$EXTERNALSYM MM_LUMINOSITI                             }
{$EXTERNALSYM MM_ACTIVEVOICE                            }
{$EXTERNALSYM MM_DTS                                    }
{$EXTERNALSYM MM_DIGIGRAM                               }
{$EXTERNALSYM MM_SOFTLAB_NSK                            }
{$EXTERNALSYM MM_FORTEMEDIA                             }
{$EXTERNALSYM MM_SONORUS                                }
{$EXTERNALSYM MM_ARRAY                                  }
{$EXTERNALSYM MM_DATARAN                                }
{$EXTERNALSYM MM_I_LINK                                 }
{$EXTERNALSYM MM_SELSIUS_SYSTEMS                        }
{$EXTERNALSYM MM_ADMOS                                  }
{$EXTERNALSYM MM_LEXICON                                }
{$EXTERNALSYM MM_SGI                                    }
{$EXTERNALSYM MM_IPI                                    }
{$EXTERNALSYM MM_ICE                                    }
{$EXTERNALSYM MM_VQST                                   }
{$EXTERNALSYM MM_ETEK                                   }
{$EXTERNALSYM MM_CS                                     }
{$EXTERNALSYM MM_ALESIS                                 }
{$EXTERNALSYM MM_INTERNET                               }
{$EXTERNALSYM MM_SONY                                   }
{$EXTERNALSYM MM_HYPERACTIVE                            }
{$EXTERNALSYM MM_UHER_INFORMATIC                        }
{$EXTERNALSYM MM_SYDEC_NV                               }
{$EXTERNALSYM MM_FLEXION                                }
{$EXTERNALSYM MM_VIA                                    }
{$EXTERNALSYM MM_MICRONAS                               }
{$EXTERNALSYM MM_ANALOGDEVICES                          }
{$EXTERNALSYM MM_HP                                     }
{$EXTERNALSYM MM_MATROX_DIV                             }
{$EXTERNALSYM MM_QUICKAUDIO                             }
{$EXTERNALSYM MM_YOUCOM                                 }
{$EXTERNALSYM MM_RICHMOND                               }
{$EXTERNALSYM MM_IODD                                   }
{$EXTERNALSYM MM_ICCC                                   }
{$EXTERNALSYM MM_3COM                                   }
{$EXTERNALSYM MM_MALDEN                                 }

{$EXTERNALSYM MM_UNMAPPED                               }
{$EXTERNALSYM MM_PID_UNMAPPED                           }

{$EXTERNALSYM WAVE_FORMAT_UNKNOWN                       }
{$EXTERNALSYM WAVE_FORMAT_ADPCM                         }
{$EXTERNALSYM WAVE_FORMAT_IEEE_FLOAT                    }
{$EXTERNALSYM WAVE_FORMAT_VSELP                         }
{$EXTERNALSYM WAVE_FORMAT_IBM_CVSD                      }
{$EXTERNALSYM WAVE_FORMAT_ALAW                          }
{$EXTERNALSYM WAVE_FORMAT_MULAW                         }
{$EXTERNALSYM WAVE_FORMAT_DTS                           }
{$EXTERNALSYM WAVE_FORMAT_OKI_ADPCM                     }
{$EXTERNALSYM WAVE_FORMAT_DVI_ADPCM                     }
{$EXTERNALSYM WAVE_FORMAT_IMA_ADPCM                     }
{$EXTERNALSYM WAVE_FORMAT_MEDIASPACE_ADPCM              }
{$EXTERNALSYM WAVE_FORMAT_SIERRA_ADPCM                  }
{$EXTERNALSYM WAVE_FORMAT_G723_ADPCM                    }
{$EXTERNALSYM WAVE_FORMAT_DIGISTD                       }
{$EXTERNALSYM WAVE_FORMAT_DIGIFIX                       }
{$EXTERNALSYM WAVE_FORMAT_DIALOGIC_OKI_ADPCM            }
{$EXTERNALSYM WAVE_FORMAT_MEDIAVISION_ADPCM             }
{$EXTERNALSYM WAVE_FORMAT_CU_CODEC                      }
{$EXTERNALSYM WAVE_FORMAT_YAMAHA_ADPCM                  }
{$EXTERNALSYM WAVE_FORMAT_SONARC                        }
{$EXTERNALSYM WAVE_FORMAT_DSPGROUP_TRUESPEECH           }
{$EXTERNALSYM WAVE_FORMAT_ECHOSC1                       }
{$EXTERNALSYM WAVE_FORMAT_AUDIOFILE_AF36                }
{$EXTERNALSYM WAVE_FORMAT_APTX                          }
{$EXTERNALSYM WAVE_FORMAT_AUDIOFILE_AF10                }
{$EXTERNALSYM WAVE_FORMAT_PROSODY_1612                  }
{$EXTERNALSYM WAVE_FORMAT_LRC                           }
{$EXTERNALSYM WAVE_FORMAT_DOLBY_AC2                     }
{$EXTERNALSYM WAVE_FORMAT_GSM610                        }
{$EXTERNALSYM WAVE_FORMAT_MSNAUDIO                      }
{$EXTERNALSYM WAVE_FORMAT_ANTEX_ADPCME                  }
{$EXTERNALSYM WAVE_FORMAT_CONTROL_RES_VQLPC             }
{$EXTERNALSYM WAVE_FORMAT_DIGIREAL                      }
{$EXTERNALSYM WAVE_FORMAT_DIGIADPCM                     }
{$EXTERNALSYM WAVE_FORMAT_CONTROL_RES_CR10              }
{$EXTERNALSYM WAVE_FORMAT_NMS_VBXADPCM                  }
{$EXTERNALSYM WAVE_FORMAT_CS_IMAADPCM                   }
{$EXTERNALSYM WAVE_FORMAT_ECHOSC3                       }
{$EXTERNALSYM WAVE_FORMAT_ROCKWELL_ADPCM                }
{$EXTERNALSYM WAVE_FORMAT_ROCKWELL_DIGITALK             }
{$EXTERNALSYM WAVE_FORMAT_XEBEC                         }
{$EXTERNALSYM WAVE_FORMAT_G721_ADPCM                    }
{$EXTERNALSYM WAVE_FORMAT_G728_CELP                     }
{$EXTERNALSYM WAVE_FORMAT_MSG723                        }
{$EXTERNALSYM WAVE_FORMAT_MPEG                          }
{$EXTERNALSYM WAVE_FORMAT_RT24                          }
{$EXTERNALSYM WAVE_FORMAT_PAC                           }
{$EXTERNALSYM WAVE_FORMAT_MPEGLAYER3                    }
{$EXTERNALSYM WAVE_FORMAT_LUCENT_G723                   }
{$EXTERNALSYM WAVE_FORMAT_CIRRUS                        }
{$EXTERNALSYM WAVE_FORMAT_ESPCM                         }
{$EXTERNALSYM WAVE_FORMAT_VOXWARE                       }
{$EXTERNALSYM WAVE_FORMAT_CANOPUS_ATRAC                 }
{$EXTERNALSYM WAVE_FORMAT_G726_ADPCM                    }
{$EXTERNALSYM WAVE_FORMAT_G722_ADPCM                    }
{$EXTERNALSYM WAVE_FORMAT_DSAT_DISPLAY                  }
{$EXTERNALSYM WAVE_FORMAT_VOXWARE_BYTE_ALIGNED          }
{$EXTERNALSYM WAVE_FORMAT_VOXWARE_AC8                   }
{$EXTERNALSYM WAVE_FORMAT_VOXWARE_AC10                  }
{$EXTERNALSYM WAVE_FORMAT_VOXWARE_AC16                  }
{$EXTERNALSYM WAVE_FORMAT_VOXWARE_AC20                  }
{$EXTERNALSYM WAVE_FORMAT_VOXWARE_RT24                  }
{$EXTERNALSYM WAVE_FORMAT_VOXWARE_RT29                  }
{$EXTERNALSYM WAVE_FORMAT_VOXWARE_RT29HW                }
{$EXTERNALSYM WAVE_FORMAT_VOXWARE_VR12                  }
{$EXTERNALSYM WAVE_FORMAT_VOXWARE_VR18                  }
{$EXTERNALSYM WAVE_FORMAT_VOXWARE_TQ40                  }
{$EXTERNALSYM WAVE_FORMAT_SOFTSOUND                     }
{$EXTERNALSYM WAVE_FORMAT_VOXWARE_TQ60                  }
{$EXTERNALSYM WAVE_FORMAT_MSRT24                        }
{$EXTERNALSYM WAVE_FORMAT_G729A                         }
{$EXTERNALSYM WAVE_FORMAT_MVI_MVI2                      }
{$EXTERNALSYM WAVE_FORMAT_DF_G726                       }
{$EXTERNALSYM WAVE_FORMAT_DF_GSM610                     }
{$EXTERNALSYM WAVE_FORMAT_ISIAUDIO                      }
{$EXTERNALSYM WAVE_FORMAT_ONLIVE                        }
{$EXTERNALSYM WAVE_FORMAT_SBC24                         }
{$EXTERNALSYM WAVE_FORMAT_DOLBY_AC3_SPDIF               }
{$EXTERNALSYM WAVE_FORMAT_MEDIASONIC_G723               }
{$EXTERNALSYM WAVE_FORMAT_PROSODY_8KBPS                 }
{$EXTERNALSYM WAVE_FORMAT_ZYXEL_ADPCM                   }
{$EXTERNALSYM WAVE_FORMAT_PHILIPS_LPCBB                 }
{$EXTERNALSYM WAVE_FORMAT_PACKED                        }
{$EXTERNALSYM WAVE_FORMAT_MALDEN_PHONYTALK              }
{$EXTERNALSYM WAVE_FORMAT_RHETOREX_ADPCM                }
{$EXTERNALSYM WAVE_FORMAT_IRAT                          }
{$EXTERNALSYM WAVE_FORMAT_VIVO_G723                     }
{$EXTERNALSYM WAVE_FORMAT_VIVO_SIREN                    }
{$EXTERNALSYM WAVE_FORMAT_DIGITAL_G723                  }
{$EXTERNALSYM WAVE_FORMAT_SANYO_LD_ADPCM                }
{$EXTERNALSYM WAVE_FORMAT_SIPROLAB_ACEPLNET             }
{$EXTERNALSYM WAVE_FORMAT_SIPROLAB_ACELP4800            }
{$EXTERNALSYM WAVE_FORMAT_SIPROLAB_ACELP8V3             }
{$EXTERNALSYM WAVE_FORMAT_SIPROLAB_G729                 }
{$EXTERNALSYM WAVE_FORMAT_SIPROLAB_G729A                }
{$EXTERNALSYM WAVE_FORMAT_SIPROLAB_KELVIN               }
{$EXTERNALSYM WAVE_FORMAT_G726ADPCM                     }
{$EXTERNALSYM WAVE_FORMAT_QUALCOMM_PUREVOICE            }
{$EXTERNALSYM WAVE_FORMAT_QUALCOMM_HALFRATE             }
{$EXTERNALSYM WAVE_FORMAT_TUBGSM                        }
{$EXTERNALSYM WAVE_FORMAT_MSAUDIO1                      }
{$EXTERNALSYM WAVE_FORMAT_CREATIVE_ADPCM                }
{$EXTERNALSYM WAVE_FORMAT_CREATIVE_FASTSPEECH8          }
{$EXTERNALSYM WAVE_FORMAT_CREATIVE_FASTSPEECH10         }
{$EXTERNALSYM WAVE_FORMAT_UHER_ADPCM                    }
{$EXTERNALSYM WAVE_FORMAT_QUARTERDECK                   }
{$EXTERNALSYM WAVE_FORMAT_ILINK_VC                      }
{$EXTERNALSYM WAVE_FORMAT_RAW_SPORT                     }
{$EXTERNALSYM WAVE_FORMAT_IPI_HSX                       }
{$EXTERNALSYM WAVE_FORMAT_IPI_RPELP                     }
{$EXTERNALSYM WAVE_FORMAT_CS2                           }
{$EXTERNALSYM WAVE_FORMAT_SONY_SCX                      }
{$EXTERNALSYM WAVE_FORMAT_FM_TOWNS_SND                  }
{$EXTERNALSYM WAVE_FORMAT_BTV_DIGITAL                   }
{$EXTERNALSYM WAVE_FORMAT_QDESIGN_MUSIC                 }
{$EXTERNALSYM WAVE_FORMAT_VME_VMPCM                     }
{$EXTERNALSYM WAVE_FORMAT_TPC                           }
{$EXTERNALSYM WAVE_FORMAT_OLIGSM                        }
{$EXTERNALSYM WAVE_FORMAT_OLIADPCM                      }
{$EXTERNALSYM WAVE_FORMAT_OLICELP                       }
{$EXTERNALSYM WAVE_FORMAT_OLISBC                        }
{$EXTERNALSYM WAVE_FORMAT_OLIOPR                        }
{$EXTERNALSYM WAVE_FORMAT_LH_CODEC                      }
{$EXTERNALSYM WAVE_FORMAT_NORRIS                        }
{$EXTERNALSYM WAVE_FORMAT_SOUNDSPACE_MUSICOMPRESS	}
{$EXTERNALSYM WAVE_FORMAT_DVM                           }

{$EXTERNALSYM WAVE_FORMAT_EXTENSIBLE                   	}
{$EXTERNALSYM WAVE_FORMAT_DEVELOPMENT                  	}


  MM_MICROSOFT			= 1  ;      //   /* Microsoft Corporation */
  MM_CREATIVE                   = 2  ;      //   /* Creative Labs, Inc. */
  MM_MEDIAVISION                = 3  ;      //   /* Media Vision, Inc. */
  MM_FUJITSU                    = 4  ;      //   /* Fujitsu Corp. */
  MM_PRAGMATRAX                 = 5  ;      //   /* PRAGMATRAX Software */
  MM_CYRIX                      = 6  ;      //   /* Cyrix Corporation */
  MM_PHILIPS_SPEECH_PROCESSING  = 7  ;      //   /* Philips Speech Processing */
  MM_NETXL                      = 8  ;      //   /* NetXL, Inc. */
  MM_ZYXEL                      = 9  ;      //   /* ZyXEL Communications, Inc. */
  MM_BECUBED                    = 10 ;      //   /* BeCubed Software Inc. */
  MM_AARDVARK                   = 11 ;      //   /* Aardvark Computer Systems, Inc. */
  MM_BINTEC                     = 12 ;      //   /* Bin Tec Communications GmbH */
  MM_HEWLETT_PACKARD            = 13 ;      //   /* Hewlett-Packard Company */
  MM_ACULAB                     = 14 ;      //   /* Aculab plc */
  MM_FAITH                      = 15 ;      //   /* Faith,Inc. */
  MM_MITEL                      = 16 ;      //   /* Mitel Corporation */
  MM_QUANTUM3D                  = 17 ;      //   /* Quantum3D, Inc. */
  MM_SNI                        = 18 ;      //   /* Siemens-Nixdorf */
  MM_EMU                        = 19 ;      //   /* E-mu Systems, Inc. */
  MM_ARTISOFT                   = 20 ;      //   /* Artisoft, Inc. */
  MM_TURTLE_BEACH               = 21 ;      //   /* Turtle Beach, Inc. */
  MM_IBM                        = 22 ;      //   /* IBM Corporation */
  MM_VOCALTEC                   = 23 ;      //   /* Vocaltec Ltd. */
  MM_ROLAND                     = 24 ;      //   /* Roland */
  MM_DSP_SOLUTIONS              = 25 ;      //   /* DSP Solutions, Inc. */
  MM_NEC                        = 26 ;      //   /* NEC */
  MM_ATI                        = 27 ;      //   /* ATI Technologies Inc. */
  MM_WANGLABS                   = 28 ;      //   /* Wang Laboratories, Inc. */
  MM_TANDY                      = 29 ;      //   /* Tandy Corporation */
  MM_VOYETRA                    = 30 ;      //   /* Voyetra */
  MM_ANTEX                      = 31 ;      //   /* Antex Electronics Corporation */
  MM_ICL_PS                     = 32 ;      //   /* ICL Personal Systems */
  MM_INTEL                      = 33 ;      //   /* Intel Corporation */
  MM_GRAVIS                     = 34 ;      //   /* Advanced Gravis */
  MM_VAL                        = 35 ;      //   /* Video Associates Labs, Inc. */
  MM_INTERACTIVE                = 36 ;      //   /* InterActive Inc. */
  MM_YAMAHA                     = 37 ;      //   /* Yamaha Corporation of America */
  MM_EVEREX                     = 38 ;      //   /* Everex Systems, Inc. */
  MM_ECHO                       = 39 ;      //   /* Echo Speech Corporation */
  MM_SIERRA                     = 40 ;      //   /* Sierra Semiconductor Corp */
  MM_CAT                        = 41 ;      //   /* Computer Aided Technologies */
  MM_APPS                       = 42 ;      //   /* APPS Software International */
  MM_DSP_GROUP                  = 43 ;      //   /* DSP Group, Inc. */
  MM_MELABS                     = 44 ;      //   /* microEngineering Labs */
  MM_COMPUTER_FRIENDS           = 45 ;      //   /* Computer Friends, Inc. */
  MM_ESS                        = 46 ;      //   /* ESS Technology */
  MM_AUDIOFILE                  = 47 ;      //   /* Audio, Inc. */
  MM_MOTOROLA                   = 48 ;      //   /* Motorola, Inc. */
  MM_CANOPUS                    = 49 ;      //   /* Canopus, co., Ltd. */
  MM_EPSON                      = 50 ;      //   /* Seiko Epson Corporation */
  MM_TRUEVISION                 = 51 ;      //   /* Truevision */
  MM_AZTECH                     = 52 ;      //   /* Aztech Labs, Inc. */
  MM_VIDEOLOGIC                 = 53 ;      //   /* Videologic */
  MM_SCALACS                    = 54 ;      //   /* SCALACS */
  MM_KORG                       = 55 ;      //   /* Korg Inc. */
  MM_APT                        = 56 ;      //   /* Audio Processing Technology */
  MM_ICS                        = 57 ;      //   /* Integrated Circuit Systems, Inc. */
  MM_ITERATEDSYS                = 58 ;      //   /* Iterated Systems, Inc. */
  MM_METHEUS                    = 59 ;      //   /* Metheus */
  MM_LOGITECH                   = 60 ;      //   /* Logitech, Inc. */
  MM_WINNOV                     = 61 ;      //   /* Winnov, Inc. */
  MM_NCR                        = 62 ;      //   /* NCR Corporation */
  MM_EXAN                       = 63 ;      //   /* EXAN */
  MM_AST                        = 64 ;      //   /* AST Research Inc. */
  MM_WILLOWPOND                 = 65 ;      //   /* Willow Pond Corporation */
  MM_SONICFOUNDRY               = 66 ;      //   /* Sonic Foundry */
  MM_VITEC                      = 67 ;      //   /* Vitec Multimedia */
  MM_MOSCOM                     = 68 ;      //   /* MOSCOM Corporation */
  MM_SILICONSOFT                = 69 ;      //   /* Silicon Soft, Inc. */
  MM_TERRATEC                   = 70 ;      //   /* TerraTec Electronic GmbH */
  MM_MEDIASONIC                 = 71 ;      //   /* MediaSonic Ltd. */
  MM_SANYO                      = 72 ;      //   /* SANYO Electric Co., Ltd. */
  MM_SUPERMAC                   = 73 ;      //   /* Supermac */
  MM_AUDIOPT                    = 74 ;      //   /* Audio Processing Technology */
  MM_NOGATECH                   = 75 ;      //   /* NOGATECH Ltd. */
  MM_SPEECHCOMP                 = 76 ;      //   /* Speech Compression */
  MM_AHEAD                      = 77 ;      //   /* Ahead, Inc. */
  MM_DOLBY                      = 78 ;      //   /* Dolby Laboratories */
  MM_OKI                        = 79 ;      //   /* OKI */
  MM_AURAVISION                 = 80 ;      //   /* AuraVision Corporation */
  MM_OLIVETTI                   = 81 ;      //   /* Ing C. Olivetti & C., S.p.A. */
  MM_IOMAGIC                    = 82 ;      //   /* I/O Magic Corporation */
  MM_MATSUSHITA                 = 83 ;      //   /* Matsushita Electric Industrial Co., Ltd. */
  MM_CONTROLRES                 = 84 ;      //   /* Control Resources Limited */
  MM_XEBEC                      = 85 ;      //   /* Xebec Multimedia Solutions Limited */
  MM_NEWMEDIA                   = 86 ;      //   /* New Media Corporation */
  MM_NMS                        = 87 ;      //   /* Natural MicroSystems */
  MM_LYRRUS                     = 88 ;      //   /* Lyrrus Inc. */
  MM_COMPUSIC                   = 89 ;      //   /* Compusic */
  MM_OPTI                       = 90 ;      //   /* OPTi Computers Inc. */
  MM_ADLACC                     = 91 ;      //   /* Adlib Accessories Inc. */
  MM_COMPAQ                     = 92 ;      //   /* Compaq Computer Corp. */
  MM_DIALOGIC                   = 93 ;      //   /* Dialogic Corporation */
  MM_INSOFT                     = 94 ;      //   /* InSoft, Inc. */
  MM_MPTUS                      = 95 ;      //   /* M.P. Technologies, Inc. */
  MM_WEITEK                     = 96 ;      //   /* Weitek */
  MM_LERNOUT_AND_HAUSPIE        = 97 ;      //   /* Lernout & Hauspie */
  MM_QCIAR                      = 98 ;      //   /* Quanta Computer Inc. */
  MM_APPLE                      = 99 ;      //   /* Apple Computer, Inc. */
  MM_DIGITAL                    = 100;      //   /* Digital Equipment Corporation */
  MM_MOTU                       = 101;      //   /* Mark of the Unicorn */
  MM_WORKBIT                    = 102;      //   /* Workbit Corporation */
  MM_OSITECH                    = 103;      //   /* Ositech Communications Inc. */
  MM_MIRO                       = 104;      //   /* miro Computer Products AG */
  MM_CIRRUSLOGIC                = 105;      //   /* Cirrus Logic */
  MM_ISOLUTION                  = 106;      //   /* ISOLUTION  B.V. */
  MM_HORIZONS                   = 107;      //   /* Horizons Technology, Inc. */
  MM_CONCEPTS                   = 108;      //   /* Computer Concepts Ltd. */
  MM_VTG                        = 109;      //   /* Voice Technologies Group, Inc. */
  MM_RADIUS                     = 110;      //   /* Radius */
  MM_ROCKWELL                   = 111;      //   /* Rockwell International */
  MM_XYZ                        = 112;      //   /* Co. XYZ for testing */
  MM_OPCODE                     = 113;      //   /* Opcode Systems */
  MM_VOXWARE                    = 114;      //   /* Voxware Inc. */
  MM_NORTHERN_TELECOM           = 115;      //   /* Northern Telecom Limited */
  MM_APICOM                     = 116;      //   /* APICOM */
  MM_GRANDE                     = 117;      //   /* Grande Software */
  MM_ADDX                       = 118;      //   /* ADDX */
  MM_WILDCAT                    = 119;      //   /* Wildcat Canyon Software */
  MM_RHETOREX                   = 120;      //   /* Rhetorex Inc. */
  MM_BROOKTREE                  = 121;      //   /* Brooktree Corporation */
  MM_ENSONIQ                    = 125;      //   /* ENSONIQ Corporation */
  MM_FAST                       = 126;      //   /* FAST Multimedia AG */
  MM_NVIDIA                     = 127;      //   /* NVidia Corporation */
  MM_OKSORI                     = 128;      //   /* OKSORI Co., Ltd. */
  MM_DIACOUSTICS                = 129;      //   /* DiAcoustics, Inc. */
  MM_GULBRANSEN                 = 130;      //   /* Gulbransen, Inc. */
  MM_KAY_ELEMETRICS             = 131;      //   /* Kay Elemetrics, Inc. */
  MM_CRYSTAL                    = 132;      //   /* Crystal Semiconductor Corporation */
  MM_SPLASH_STUDIOS             = 133;      //   /* Splash Studios */
  MM_QUARTERDECK                = 134;      //   /* Quarterdeck Corporation */
  MM_TDK                        = 135;      //   /* TDK Corporation */
  MM_DIGITAL_AUDIO_LABS         = 136;      //   /* Digital Audio Labs, Inc. */
  MM_SEERSYS                    = 137;      //   /* Seer Systems, Inc. */
  MM_PICTURETEL                 = 138;      //   /* PictureTel Corporation */
  MM_ATT_MICROELECTRONICS       = 139;      //   /* AT&T Microelectronics */
  MM_OSPREY                     = 140;      //   /* Osprey Technologies, Inc. */
  MM_MEDIATRIX                  = 141;      //   /* Mediatrix Peripherals */
  MM_SOUNDESIGNS                = 142;      //   /* SounDesignS M.C.S. Ltd. */
  MM_ALDIGITAL                  = 143;      //   /* A.L. Digital Ltd. */
  MM_SPECTRUM_SIGNAL_PROCESSING = 144;      //   /* Spectrum Signal Processing, Inc. */
  MM_ECS                        = 145;      //   /* Electronic Courseware Systems, Inc. */
  MM_AMD                        = 146;      //   /* AMD */
  MM_COREDYNAMICS               = 147;      //   /* Core Dynamics */
  MM_CANAM                      = 148;      //   /* CANAM Computers */
  MM_SOFTSOUND                  = 149;      //   /* Softsound, Ltd. */
  MM_NORRIS                     = 150;      //   /* Norris Communications, Inc. */
  MM_DDD                        = 151;      //   /* Danka Data Devices */
  MM_EUPHONICS                  = 152;      //   /* EuPhonics */
  MM_PRECEPT                    = 153;      //   /* Precept Software, Inc. */
  MM_CRYSTAL_NET                = 154;      //   /* Crystal Net Corporation */
  MM_CHROMATIC                  = 155;      //   /* Chromatic Research, Inc. */
  MM_VOICEINFO                  = 156;      //   /* Voice Information Systems, Inc. */
  MM_VIENNASYS                  = 157;      //   /* Vienna Systems */
  MM_CONNECTIX                  = 158;      //   /* Connectix Corporation */
  MM_GADGETLABS                 = 159;      //   /* Gadget Labs LLC */
  MM_FRONTIER                   = 160;      //   /* Frontier Design Group LLC */
  MM_VIONA                      = 161;      //   /* Viona Development GmbH */
  MM_CASIO                      = 162;      //   /* Casio Computer Co., LTD */
  MM_DIAMONDMM                  = 163;      //   /* Diamond Multimedia */
  MM_S3                         = 164;      //   /* S3 */
  MM_DVISION                    = 165;      //   /* D-Vision Systems, Inc. */
  MM_NETSCAPE                   = 166;      //   /* Netscape Communications */
  MM_SOUNDSPACE                 = 167;      //   /* Soundspace Audio */
  MM_VANKOEVERING               = 168;      //   /* VanKoevering Company */
  MM_QTEAM                      = 169;      //   /* Q-Team */
  MM_ZEFIRO                     = 170;      //   /* Zefiro Acoustics */
  MM_STUDER                     = 171;      //   /* Studer Professional Audio AG */
  MM_FRAUNHOFER_IIS             = 172;      //   /* Fraunhofer IIS */
  MM_QUICKNET                   = 173;      //   /* Quicknet Technologies */
  MM_ALARIS                     = 174;      //   /* Alaris, Inc. */
  MM_SICRESOURCE                = 175;      //   /* SIC Resource Inc. */
  MM_NEOMAGIC                   = 176;      //   /* NeoMagic Corporation */
  MM_MERGING_TECHNOLOGIES       = 177;      //   /* Merging Technologies S.A. */
  MM_XIRLINK                    = 178;      //   /* Xirlink, Inc. */
  MM_COLORGRAPH                 = 179;      //   /* Colorgraph (UK) Ltd */
  MM_OTI                        = 180;      //   /* Oak Technology, Inc. */
  MM_AUREAL                     = 181;      //   /* Aureal Semiconductor */
  MM_VIVO                       = 182;      //   /* Vivo Software */
  MM_SHARP                      = 183;      //   /* Sharp */
  MM_LUCENT                     = 184;      //   /* Lucent Technologies */
  MM_ATT                        = 185;      //   /* AT&T Labs, Inc. */
  MM_SUNCOM                     = 186;      //   /* Sun Communications, Inc. */
  MM_SORVIS                     = 187;      //   /* Sorenson Vision */
  MM_INVISION                   = 188;      //   /* InVision Interactive */
  MM_BERKOM                     = 189;      //   /* Deutsche Telekom Berkom GmbH */
  MM_MARIAN                     = 190;      //   /* Marian GbR Leipzig */
  MM_DPSINC                     = 191;      //   /* Digital Processing Systems, Inc. */
  MM_BCB                        = 192;      //   /* BCB Holdings Inc. */
  MM_MOTIONPIXELS               = 193;      //   /* Motion Pixels */
  MM_QDESIGN                    = 194;      //   /* QDesign Corporation */
  MM_NMP                        = 195;      //   /* Nokia Mobile Phones */
  MM_DATAFUSION                 = 196;      //   /* DataFusion Systems (Pty) (Ltd) */
  MM_DUCK                       = 197;      //   /* The Duck Corporation */
  MM_FTR                        = 198;      //   /* Future Technology Resources Pty Ltd */
  MM_BERCOS                     = 199;      //   /* BERCOS GmbH */
  MM_ONLIVE                     = 200;      //   /* OnLive! Technologies, Inc. */
  MM_SIEMENS_SBC                = 201;      //   /* Siemens Business Communications Systems */
  MM_TERALOGIC                  = 202;      //   /* TeraLogic, Inc. */
  MM_PHONET                     = 203;      //   /* PhoNet Communications Ltd. */
  MM_WINBOND                    = 204;      //   /* Winbond Electronics Corp */
  MM_VIRTUALMUSIC               = 205;      //   /* Virtual Music, Inc. */
  MM_ENET                       = 206;      //   /* e-Net, Inc. */
  MM_GUILLEMOT                  = 207;      //   /* Guillemot International */
  MM_EMAGIC                     = 208;      //   /* Emagic Soft- und Hardware GmbH */
  MM_MWM                        = 209;      //   /* MWM Acoustics LLC */
  MM_PACIFICRESEARCH            = 210;      //   /* Pacific Research and Engineering Corporation */
  MM_SIPROLAB                   = 211;      //   /* Sipro Lab Telecom Inc. */
  MM_LYNX                       = 212;      //   /* Lynx Studio Technology, Inc. */
  MM_SPECTRUM_PRODUCTIONS       = 213;      //   /* Spectrum Productions */
  MM_DICTAPHONE                 = 214;      //   /* Dictaphone Corporation */
  MM_QUALCOMM                   = 215;      //   /* QUALCOMM, Inc. */
  MM_RZS                        = 216;      //   /* Ring Zero Systems, Inc */
  MM_AUDIOSCIENCE               = 217;      //   /* AudioScience Inc. */
  MM_PINNACLE                   = 218;      //   /* Pinnacle Systems, Inc. */
  MM_EES                        = 219;      //   /* EES Technik fur Musik GmbH */
  MM_HAFTMANN                   = 220;      //   /* haftmann#software */
  MM_LUCID                      = 221;      //   /* Lucid Technology, Symetrix Inc. */
  MM_HEADSPACE                  = 222;      //   /* Headspace, Inc */
  MM_UNISYS                     = 223;      //   /* UNISYS CORPORATION */
  MM_LUMINOSITI                 = 224;      //   /* Luminositi, Inc. */
  MM_ACTIVEVOICE                = 225;      //   /* ACTIVE VOICE CORPORATION */
  MM_DTS                        = 226;      //   /* Digital Theater Systems, Inc. */
  MM_DIGIGRAM                   = 227;      //   /* DIGIGRAM */
  MM_SOFTLAB_NSK                = 228;      //   /* Softlab-Nsk */
  MM_FORTEMEDIA                 = 229;      //   /* ForteMedia, Inc */
  MM_SONORUS                    = 230;      //   /* Sonorus, Inc. */
  MM_ARRAY                      = 231;      //   /* Array Microsystems, Inc. */
  MM_DATARAN                    = 232;      //   /* Data Translation, Inc. */
  MM_I_LINK                     = 233;      //   /* I-link Worldwide */
  MM_SELSIUS_SYSTEMS            = 234;      //   /* Selsius Systems Inc. */
  MM_ADMOS                      = 235;      //   /* AdMOS Technology, Inc. */
  MM_LEXICON                    = 236;      //   /* Lexicon Inc. */
  MM_SGI                        = 237;      //   /* Silicon Graphics Inc. */
  MM_IPI                        = 238;      //   /* Interactive Product Inc. */
  MM_ICE                        = 239;      //   /* IC Ensemble, Inc. */
  MM_VQST                       = 240;      //   /* ViewQuest Technologies Inc. */
  MM_ETEK                       = 241;      //   /* eTEK Labs Inc. */
  MM_CS                         = 242;      //   /* Consistent Software */
  MM_ALESIS                     = 243;      //   /* Alesis Studio Electronics */
  MM_INTERNET                   = 244;      //   /* INTERNET Corporation */
  MM_SONY                       = 245;      //   /* Sony Corporation */
  MM_HYPERACTIVE                = 246;      //   /* Hyperactive Audio Systems, Inc. */
  MM_UHER_INFORMATIC            = 247;      //   /* UHER informatic GmbH */
  MM_SYDEC_NV                   = 248;      //   /* Sydec NV */
  MM_FLEXION                    = 249;      //   /* Flexion Systems Ltd. */
  MM_VIA                        = 250;      //   /* Via Technologies, Inc. */
  MM_MICRONAS                   = 251;      //   /* Micronas Semiconductors, Inc. */
  MM_ANALOGDEVICES              = 252;      //   /* Analog Devices, Inc. */
  MM_HP                         = 253;      //   /* Hewlett Packard Company */
  MM_MATROX_DIV                 = 254;      //   /* Matrox */
  MM_QUICKAUDIO                 = 255;      //   /* Quick Audio, GbR */
  MM_YOUCOM                     = 256;      //   /* You/Com Audiocommunicatie BV */
  MM_RICHMOND                   = 257;      //   /* Richmond Sound Design Ltd. */
  MM_IODD                       = 258;      //   /* I-O Data Device, Inc. */
  MM_ICCC                       = 259;      //   /* ICCC A/S */
  MM_3COM                       = 260;      //   /* 3COM Corporation */
  MM_MALDEN                     = 261;      //   /* Malden Electronics Ltd. */

  MM_UNMAPPED                   = $ffff;     	//* extensible MID mapping */
  MM_PID_UNMAPPED               = MM_UNMAPPED; 	//* extensible PID mapping */



// some of MS pids

{$EXTERNALSYM MM_MSFT_WSS_WAVEIN }
{$EXTERNALSYM MM_MSFT_WSS_WAVEOUT }
{$EXTERNALSYM MM_MSFT_WSS_FMSYNTH_STEREO }
{$EXTERNALSYM MM_MSFT_WSS_MIXER }
{$EXTERNALSYM MM_MSFT_WSS_OEM_WAVEIN }
{$EXTERNALSYM MM_MSFT_WSS_OEM_WAVEOUT }
{$EXTERNALSYM MM_MSFT_WSS_OEM_FMSYNTH_STEREO }
{$EXTERNALSYM MM_MSFT_WSS_AUX }
{$EXTERNALSYM MM_MSFT_WSS_OEM_AUX }
{$EXTERNALSYM MM_MSFT_GENERIC_WAVEIN }
{$EXTERNALSYM MM_MSFT_GENERIC_WAVEOUT }
{$EXTERNALSYM MM_MSFT_GENERIC_MIDIIN }
{$EXTERNALSYM MM_MSFT_GENERIC_MIDIOUT }
{$EXTERNALSYM MM_MSFT_GENERIC_MIDISYNTH }
{$EXTERNALSYM MM_MSFT_GENERIC_AUX_LINE }
{$EXTERNALSYM MM_MSFT_GENERIC_AUX_MIC }
{$EXTERNALSYM MM_MSFT_GENERIC_AUX_CD }
{$EXTERNALSYM MM_MSFT_WSS_OEM_MIXER }
{$EXTERNALSYM MM_MSFT_MSACM }
{$EXTERNALSYM MM_MSFT_ACM_MSADPCM }
{$EXTERNALSYM MM_MSFT_ACM_IMAADPCM }
{$EXTERNALSYM MM_MSFT_ACM_MSFILTER }
{$EXTERNALSYM MM_MSFT_ACM_GSM610 }
{$EXTERNALSYM MM_MSFT_ACM_G711 }
{$EXTERNALSYM MM_MSFT_ACM_PCM }

  MM_MSFT_WSS_WAVEIN                 = 14;	//*  MS Audio Board waveform input  */
  MM_MSFT_WSS_WAVEOUT                = 15;      //*  MS Audio Board waveform output  */
  MM_MSFT_WSS_FMSYNTH_STEREO         = 16;      //*  MS Audio Board  Stereo FM synth  */
  MM_MSFT_WSS_MIXER                  = 17;      //*  MS Audio Board Mixer Driver  */
  MM_MSFT_WSS_OEM_WAVEIN             = 18;      //*  MS OEM Audio Board waveform input  */
  MM_MSFT_WSS_OEM_WAVEOUT            = 19;      //*  MS OEM Audio Board waveform output  */
  MM_MSFT_WSS_OEM_FMSYNTH_STEREO     = 20;      //*  MS OEM Audio Board Stereo FM Synth  */
  MM_MSFT_WSS_AUX                    = 21;      //*  MS Audio Board Aux. Port  */
  MM_MSFT_WSS_OEM_AUX                = 22;      //*  MS OEM Audio Aux Port  */
  MM_MSFT_GENERIC_WAVEIN             = 23;      //*  MS Vanilla driver waveform input  */
  MM_MSFT_GENERIC_WAVEOUT            = 24;      //*  MS Vanilla driver wavefrom output  */
  MM_MSFT_GENERIC_MIDIIN             = 25;      //*  MS Vanilla driver MIDI in  */
  MM_MSFT_GENERIC_MIDIOUT            = 26;      //*  MS Vanilla driver MIDI  external out  */
  MM_MSFT_GENERIC_MIDISYNTH          = 27;      //*  MS Vanilla driver MIDI synthesizer  */
  MM_MSFT_GENERIC_AUX_LINE           = 28;      //*  MS Vanilla driver aux (line in)  */
  MM_MSFT_GENERIC_AUX_MIC            = 29;      //*  MS Vanilla driver aux (mic)  */
  MM_MSFT_GENERIC_AUX_CD             = 30;      //*  MS Vanilla driver aux (CD)  */
  MM_MSFT_WSS_OEM_MIXER              = 31;      //*  MS OEM Audio Board Mixer Driver  */
  MM_MSFT_MSACM                      = 32;      //*  MS Audio Compression Manager  */
  MM_MSFT_ACM_MSADPCM                = 33;      //*  MS ADPCM Codec  */
  MM_MSFT_ACM_IMAADPCM               = 34;      //*  IMA ADPCM Codec  */
  MM_MSFT_ACM_MSFILTER               = 35;      //*  MS Filter  */
  MM_MSFT_ACM_GSM610                 = 36;      //*  GSM 610 codec  */
  MM_MSFT_ACM_G711                   = 37;      //*  G.711 codec  */
  MM_MSFT_ACM_PCM                    = 38;      //*  PCM converter  */


//* WAVE form wFormatTag IDs */
  WAVE_FORMAT_UNKNOWN                 =   $00000; //* Microsoft Corporation */
  WAVE_FORMAT_ADPCM                   =   $00002; //* Microsoft Corporation */
  WAVE_FORMAT_IEEE_FLOAT              =   $00003; //* Microsoft Corporation */
  WAVE_FORMAT_VSELP                   =   $00004; //* Compaq Computer Corp. */
  WAVE_FORMAT_IBM_CVSD                =   $00005; //* IBM Corporation */
  WAVE_FORMAT_ALAW                    =   $00006; //* Microsoft Corporation */
  WAVE_FORMAT_MULAW                   =   $00007; //* Microsoft Corporation */
  WAVE_FORMAT_DTS                     =   $00008; //* Microsoft Corporation */
  WAVE_FORMAT_OKI_ADPCM               =   $00010; //* OKI */
  WAVE_FORMAT_DVI_ADPCM               =   $00011; //* Intel Corporation */
  WAVE_FORMAT_IMA_ADPCM               =   WAVE_FORMAT_DVI_ADPCM;	//*  Intel Corporation */
  WAVE_FORMAT_MEDIASPACE_ADPCM        =   $00012; //* Videologic */
  WAVE_FORMAT_SIERRA_ADPCM            =   $00013; //* Sierra Semiconductor Corp */
  WAVE_FORMAT_G723_ADPCM              =   $00014; //* Antex Electronics Corporation */
  WAVE_FORMAT_DIGISTD                 =   $00015; //* DSP Solutions, Inc. */
  WAVE_FORMAT_DIGIFIX                 =   $00016; //* DSP Solutions, Inc. */
  WAVE_FORMAT_DIALOGIC_OKI_ADPCM      =   $00017; //* Dialogic Corporation */
  WAVE_FORMAT_MEDIAVISION_ADPCM       =   $00018; //* Media Vision, Inc. */
  WAVE_FORMAT_CU_CODEC                =   $00019; //* Hewlett-Packard Company */
  WAVE_FORMAT_YAMAHA_ADPCM            =   $00020; //* Yamaha Corporation of America */
  WAVE_FORMAT_SONARC                  =   $00021; //* Speech Compression */
  WAVE_FORMAT_DSPGROUP_TRUESPEECH     =   $00022; //* DSP Group, Inc */
  WAVE_FORMAT_ECHOSC1                 =   $00023; //* Echo Speech Corporation */
  WAVE_FORMAT_AUDIOFILE_AF36          =   $00024; //* Virtual Music, Inc. */
  WAVE_FORMAT_APTX                    =   $00025; //* Audio Processing Technology */
  WAVE_FORMAT_AUDIOFILE_AF10          =   $00026; //* Virtual Music, Inc. */
  WAVE_FORMAT_PROSODY_1612            =   $00027; //* Aculab plc */
  WAVE_FORMAT_LRC                     =   $00028; //* Merging Technologies S.A. */
  WAVE_FORMAT_DOLBY_AC2               =   $00030; //* Dolby Laboratories */
  WAVE_FORMAT_GSM610                  =   $00031; //* Microsoft Corporation */
  WAVE_FORMAT_MSNAUDIO                =   $00032; //* Microsoft Corporation */
  WAVE_FORMAT_ANTEX_ADPCME            =   $00033; //* Antex Electronics Corporation */
  WAVE_FORMAT_CONTROL_RES_VQLPC       =   $00034; //* Control Resources Limited */
  WAVE_FORMAT_DIGIREAL                =   $00035; //* DSP Solutions, Inc. */
  WAVE_FORMAT_DIGIADPCM               =   $00036; //* DSP Solutions, Inc. */
  WAVE_FORMAT_CONTROL_RES_CR10        =   $00037; //* Control Resources Limited */
  WAVE_FORMAT_NMS_VBXADPCM            =   $00038; //* Natural MicroSystems */
  WAVE_FORMAT_CS_IMAADPCM             =   $00039; //* Crystal Semiconductor IMA ADPCM */
  WAVE_FORMAT_ECHOSC3                 =   $0003A; //* Echo Speech Corporation */
  WAVE_FORMAT_ROCKWELL_ADPCM          =   $0003B; //* Rockwell International */
  WAVE_FORMAT_ROCKWELL_DIGITALK       =   $0003C; //* Rockwell International */
  WAVE_FORMAT_XEBEC                   =   $0003D; //* Xebec Multimedia Solutions Limited */
  WAVE_FORMAT_G721_ADPCM              =   $00040; //* Antex Electronics Corporation */
  WAVE_FORMAT_G728_CELP               =   $00041; //* Antex Electronics Corporation */
  WAVE_FORMAT_MSG723                  =   $00042; //* Microsoft Corporation */
  WAVE_FORMAT_MPEG                    =   $00050; //* Microsoft Corporation */
  WAVE_FORMAT_RT24                    =   $00052; //* InSoft, Inc. */
  WAVE_FORMAT_PAC                     =   $00053; //* InSoft, Inc. */
  WAVE_FORMAT_MPEGLAYER3              =   $00055; //* ISO/MPEG Layer3 Format Tag */
  WAVE_FORMAT_LUCENT_G723             =   $00059; //* Lucent Technologies */
  WAVE_FORMAT_CIRRUS                  =   $00060; //* Cirrus Logic */
  WAVE_FORMAT_ESPCM                   =   $00061; //* ESS Technology */
  WAVE_FORMAT_VOXWARE                 =   $00062; //* Voxware Inc */
  WAVE_FORMAT_CANOPUS_ATRAC           =   $00063; //* Canopus, co., Ltd. */
  WAVE_FORMAT_G726_ADPCM              =   $00064; //* APICOM */
  WAVE_FORMAT_G722_ADPCM              =   $00065; //* APICOM */
  WAVE_FORMAT_DSAT_DISPLAY            =   $00067; //* Microsoft Corporation */
  WAVE_FORMAT_VOXWARE_BYTE_ALIGNED    =   $00069; //* Voxware Inc */
  WAVE_FORMAT_VOXWARE_AC8             =   $00070; //* Voxware Inc */
  WAVE_FORMAT_VOXWARE_AC10            =   $00071; //* Voxware Inc */
  WAVE_FORMAT_VOXWARE_AC16            =   $00072; //* Voxware Inc */
  WAVE_FORMAT_VOXWARE_AC20            =   $00073; //* Voxware Inc */
  WAVE_FORMAT_VOXWARE_RT24            =   $00074; //* Voxware Inc */
  WAVE_FORMAT_VOXWARE_RT29            =   $00075; //* Voxware Inc */
  WAVE_FORMAT_VOXWARE_RT29HW          =   $00076; //* Voxware Inc */
  WAVE_FORMAT_VOXWARE_VR12            =   $00077; //* Voxware Inc */
  WAVE_FORMAT_VOXWARE_VR18            =   $00078; //* Voxware Inc */
  WAVE_FORMAT_VOXWARE_TQ40            =   $00079; //* Voxware Inc */
  WAVE_FORMAT_SOFTSOUND               =   $00080; //* Softsound, Ltd. */
  WAVE_FORMAT_VOXWARE_TQ60            =   $00081; //* Voxware Inc */
  WAVE_FORMAT_MSRT24                  =   $00082; //* Microsoft Corporation */
  WAVE_FORMAT_G729A                   =   $00083; //* AT&T Labs, Inc. */
  WAVE_FORMAT_MVI_MVI2                =   $00084; //* Motion Pixels */
  WAVE_FORMAT_DF_G726                 =   $00085; //* DataFusion Systems (Pty) (Ltd) */
  WAVE_FORMAT_DF_GSM610               =   $00086; //* DataFusion Systems (Pty) (Ltd) */
  WAVE_FORMAT_ISIAUDIO                =   $00088; //* Iterated Systems, Inc. */
  WAVE_FORMAT_ONLIVE                  =   $00089; //* OnLive! Technologies, Inc. */
  WAVE_FORMAT_SBC24                   =   $00091; //* Siemens Business Communications Sys */
  WAVE_FORMAT_DOLBY_AC3_SPDIF         =   $00092; //* Sonic Foundry */
  WAVE_FORMAT_MEDIASONIC_G723         =   $00093; //* MediaSonic */
  WAVE_FORMAT_PROSODY_8KBPS           =   $00094; //* Aculab plc */
  WAVE_FORMAT_ZYXEL_ADPCM             =   $00097; //* ZyXEL Communications, Inc. */
  WAVE_FORMAT_PHILIPS_LPCBB           =   $00098; //* Philips Speech Processing */
  WAVE_FORMAT_PACKED                  =   $00099; //* Studer Professional Audio AG */
  WAVE_FORMAT_MALDEN_PHONYTALK        =   $000A0; //* Malden Electronics Ltd. */
  WAVE_FORMAT_RHETOREX_ADPCM          =   $00100; //* Rhetorex Inc. */
  WAVE_FORMAT_IRAT                    =   $00101; //* BeCubed Software Inc. */
  WAVE_FORMAT_VIVO_G723               =   $00111; //* Vivo Software */
  WAVE_FORMAT_VIVO_SIREN              =   $00112; //* Vivo Software */
  WAVE_FORMAT_DIGITAL_G723            =   $00123; //* Digital Equipment Corporation */
  WAVE_FORMAT_SANYO_LD_ADPCM          =   $00125; //* Sanyo Electric Co., Ltd. */
  WAVE_FORMAT_SIPROLAB_ACEPLNET       =   $00130; //* Sipro Lab Telecom Inc. */
  WAVE_FORMAT_SIPROLAB_ACELP4800      =   $00131; //* Sipro Lab Telecom Inc. */
  WAVE_FORMAT_SIPROLAB_ACELP8V3       =   $00132; //* Sipro Lab Telecom Inc. */
  WAVE_FORMAT_SIPROLAB_G729           =   $00133; //* Sipro Lab Telecom Inc. */
  WAVE_FORMAT_SIPROLAB_G729A          =   $00134; //* Sipro Lab Telecom Inc. */
  WAVE_FORMAT_SIPROLAB_KELVIN         =   $00135; //* Sipro Lab Telecom Inc. */
  WAVE_FORMAT_G726ADPCM               =   $00140; //* Dictaphone Corporation */
  WAVE_FORMAT_QUALCOMM_PUREVOICE      =   $00150; //* Qualcomm, Inc. */
  WAVE_FORMAT_QUALCOMM_HALFRATE       =   $00151; //* Qualcomm, Inc. */
  WAVE_FORMAT_TUBGSM                  =   $00155; //* Ring Zero Systems, Inc. */
  WAVE_FORMAT_MSAUDIO1                =   $00160; //* Microsoft Corporation */
  WAVE_FORMAT_CREATIVE_ADPCM          =   $00200; //* Creative Labs, Inc */
  WAVE_FORMAT_CREATIVE_FASTSPEECH8    =   $00202; //* Creative Labs, Inc */
  WAVE_FORMAT_CREATIVE_FASTSPEECH10   =   $00203; //* Creative Labs, Inc */
  WAVE_FORMAT_UHER_ADPCM              =   $00210; //* UHER informatic GmbH */
  WAVE_FORMAT_QUARTERDECK             =   $00220; //* Quarterdeck Corporation */
  WAVE_FORMAT_ILINK_VC                =   $00230; //* I-link Worldwide */
  WAVE_FORMAT_RAW_SPORT               =   $00240; //* Aureal Semiconductor */
  WAVE_FORMAT_IPI_HSX                 =   $00250; //* Interactive Products, Inc. */
  WAVE_FORMAT_IPI_RPELP               =   $00251; //* Interactive Products, Inc. */
  WAVE_FORMAT_CS2                     =   $00260; //* Consistent Software */
  WAVE_FORMAT_SONY_SCX                =   $00270; //* Sony Corp. */
  WAVE_FORMAT_FM_TOWNS_SND            =   $00300; //* Fujitsu Corp. */
  WAVE_FORMAT_BTV_DIGITAL             =   $00400; //* Brooktree Corporation */
  WAVE_FORMAT_QDESIGN_MUSIC           =   $00450; //* QDesign Corporation */
  WAVE_FORMAT_VME_VMPCM               =   $00680; //* AT&T Labs, Inc. */
  WAVE_FORMAT_TPC                     =   $00681; //* AT&T Labs, Inc. */
  WAVE_FORMAT_OLIGSM                  =   $01000; //* Ing C. Olivetti & C., S.p.A. */
  WAVE_FORMAT_OLIADPCM                =   $01001; //* Ing C. Olivetti & C., S.p.A. */
  WAVE_FORMAT_OLICELP                 =   $01002; //* Ing C. Olivetti & C., S.p.A. */
  WAVE_FORMAT_OLISBC                  =   $01003; //* Ing C. Olivetti & C., S.p.A. */
  WAVE_FORMAT_OLIOPR                  =   $01004; //* Ing C. Olivetti & C., S.p.A. */
  WAVE_FORMAT_LH_CODEC                =   $01100; //* Lernout & Hauspie */
  WAVE_FORMAT_NORRIS                  =   $01400; //* Norris Communications, Inc. */
  WAVE_FORMAT_SOUNDSPACE_MUSICOMPRESS =   $01500; //* AT&T Labs, Inc. */
  WAVE_FORMAT_DVM                     =   $02000; //* FAST Multimedia AG */

  //
  WAVE_FORMAT_EXTENSIBLE              =   $0FFFE; //* Microsoft */

//
//  New wave format development should be based on the
//  WAVEFORMATEXTENSIBLE structure. WAVEFORMATEXTENSIBLE allows you to
//  avoid having to register a new format tag with Microsoft. However, if
//  you must still define a new format tag, the WAVE_FORMAT_DEVELOPMENT
//  format tag can be used during the development phase of a new wave
//  format.  Before shipping, you MUST acquire an official format tag from
//  Microsoft.
//
  WAVE_FORMAT_DEVELOPMENT             =   $0FFFF; // you

//
//  New wave format development should be based on the
//  WAVEFORMATEXTENSIBLE structure. WAVEFORMATEXTENSIBLE allows you to
//  avoid having to register a new format tag with Microsoft. Simply
//  define a new GUID value for the WAVEFORMATEXTENSIBLE.SubFormat field
//  and use WAVE_FORMAT_EXTENSIBLE in the
//  WAVEFORMATEXTENSIBLE.Format.wFormatTag field.
//
type
  WAVEFORMATEXTENSIBLE_SAMPLES = record
    //
    case int of
      0: (wValidBitsPerSample: WORD);       //* bits of precision  */
      1: (wSamplesPerBlock: WORD);          //* valid if wBitsPerSample==0 */
      2: (wReserved: WORD);                 //* If neither applies, set to zero. */
  end;

  {$EXTERNALSYM PWAVEFORMATEXTENSIBLE }
  {$EXTERNALSYM WAVEFORMATEXTENSIBLE }
  PWAVEFORMATEXTENSIBLE = ^WAVEFORMATEXTENSIBLE;
  WAVEFORMATEXTENSIBLE = record
    //
    Format: WAVEFORMATEX;
    Samples: WAVEFORMATEXTENSIBLE_SAMPLES;
    dwChannelMask: DWORD;	//* which channels are present in stream  */
    SubFormat: tGUID;
  end;

//
//  Extended PCM waveform format structure based on WAVEFORMATEXTENSIBLE.
//  Use this for multiple channel and hi-resolution PCM data
//
  {$EXTERNALSYM WAVEFORMATPCMEX }
  {$EXTERNALSYM PWAVEFORMATPCMEX }
  {$EXTERNALSYM NPWAVEFORMATPCMEX }
  {$EXTERNALSYM LPWAVEFORMATPCMEX }
  WAVEFORMATPCMEX   = WAVEFORMATEXTENSIBLE; //* Format.cbSize = 22 */
  PWAVEFORMATPCMEX  = ^WAVEFORMATPCMEX;
  NPWAVEFORMATPCMEX = ^WAVEFORMATPCMEX;
  LPWAVEFORMATPCMEX = ^WAVEFORMATPCMEX;

//
//  Extended format structure using IEEE Float data and based
//  on WAVEFORMATEXTENSIBLE.  Use this for multiple channel
//  and hi-resolution PCM data in IEEE floating point format.
//
  {$EXTERNALSYM WAVEFORMATIEEEFLOATEX }
  {$EXTERNALSYM PWAVEFORMATIEEEFLOATEX }
  {$EXTERNALSYM NPWAVEFORMATIEEEFLOATEX }
  {$EXTERNALSYM LPWAVEFORMATIEEEFLOATEX }
  WAVEFORMATIEEEFLOATEX   = WAVEFORMATEXTENSIBLE; //* Format.cbSize = 22 */
  PWAVEFORMATIEEEFLOATEX  = ^WAVEFORMATIEEEFLOATEX;
  NPWAVEFORMATIEEEFLOATEX = ^WAVEFORMATIEEEFLOATEX;
  LPWAVEFORMATIEEEFLOATEX = ^WAVEFORMATIEEEFLOATEX;


const
  {$EXTERNALSYM SPEAKER_FRONT_LEFT }
  {$EXTERNALSYM SPEAKER_FRONT_RIGHT }
  {$EXTERNALSYM SPEAKER_FRONT_CENTER }
  {$EXTERNALSYM SPEAKER_LOW_FREQUENCY }
  {$EXTERNALSYM SPEAKER_BACK_LEFT }
  {$EXTERNALSYM SPEAKER_BACK_RIGHT }
  {$EXTERNALSYM SPEAKER_FRONT_LEFT_OF_CENTER }
  {$EXTERNALSYM SPEAKER_FRONT_RIGHT_OF_CENTER }
  {$EXTERNALSYM SPEAKER_BACK_CENTER }
  {$EXTERNALSYM SPEAKER_SIDE_LEFT }
  {$EXTERNALSYM SPEAKER_SIDE_RIGHT }
  {$EXTERNALSYM SPEAKER_TOP_CENTER }
  {$EXTERNALSYM SPEAKER_TOP_FRONT_LEFT }
  {$EXTERNALSYM SPEAKER_TOP_FRONT_CENTER }
  {$EXTERNALSYM SPEAKER_TOP_FRONT_RIGHT }
  {$EXTERNALSYM SPEAKER_TOP_BACK_LEFT }
  {$EXTERNALSYM SPEAKER_TOP_BACK_CENTER }
  {$EXTERNALSYM SPEAKER_TOP_BACK_RIGHT }
  //
  {$EXTERNALSYM SPEAKER_RESERVED }
  {$EXTERNALSYM SPEAKER_ALL }

// Speaker Positions for dwChannelMask in WAVEFORMATEXTENSIBLE:
  SPEAKER_FRONT_LEFT            =     $1;
  SPEAKER_FRONT_RIGHT           =     $2;
  SPEAKER_FRONT_CENTER          =     $4;
  SPEAKER_LOW_FREQUENCY         =     $8;
  SPEAKER_BACK_LEFT             =    $10;
  SPEAKER_BACK_RIGHT            =    $20;
  SPEAKER_FRONT_LEFT_OF_CENTER  =    $40;
  SPEAKER_FRONT_RIGHT_OF_CENTER =    $80;
  SPEAKER_BACK_CENTER           =   $100;
  SPEAKER_SIDE_LEFT             =   $200;
  SPEAKER_SIDE_RIGHT            =   $400;
  SPEAKER_TOP_CENTER            =   $800;
  SPEAKER_TOP_FRONT_LEFT        =  $1000;
  SPEAKER_TOP_FRONT_CENTER      =  $2000;
  SPEAKER_TOP_FRONT_RIGHT       =  $4000;
  SPEAKER_TOP_BACK_LEFT         =  $8000;
  SPEAKER_TOP_BACK_CENTER       = $10000;
  SPEAKER_TOP_BACK_RIGHT        = $20000;

  // Bit mask locations reserved for future use
  SPEAKER_RESERVED		= $7FFC0000;

  // Used to specify that any possible permutation of speaker configurations
  SPEAKER_ALL                   = $80000000;

  // specific to Lake of Soft, do not use
  SPEAKER_DEFAULT		= $A0000000;


  {$EXTERNALSYM KSAUDIO_SPEAKER_DIRECTOUT }
  {$EXTERNALSYM KSAUDIO_SPEAKER_MONO }
  {$EXTERNALSYM KSAUDIO_SPEAKER_STEREO }
  {$EXTERNALSYM KSAUDIO_SPEAKER_QUAD }
  {$EXTERNALSYM KSAUDIO_SPEAKER_SURROUND }
  {$EXTERNALSYM KSAUDIO_SPEAKER_5POINT1 }
  {$EXTERNALSYM KSAUDIO_SPEAKER_7POINT1 }
  {$EXTERNALSYM KSAUDIO_SPEAKER_5POINT1_SURROUND }
  {$EXTERNALSYM KSAUDIO_SPEAKER_7POINT1_SURROUND }
  {$EXTERNALSYM KSAUDIO_SPEAKER_5POINT1_BACK }
  {$EXTERNALSYM KSAUDIO_SPEAKER_7POINT1_WIDE }
  //
  // DVD Speaker Positions
  {$EXTERNALSYM KSAUDIO_SPEAKER_GROUND_FRONT_LEFT }
  {$EXTERNALSYM KSAUDIO_SPEAKER_GROUND_FRONT_CENTER }
  {$EXTERNALSYM KSAUDIO_SPEAKER_GROUND_FRONT_RIGHT }
  {$EXTERNALSYM KSAUDIO_SPEAKER_GROUND_REAR_LEFT }
  {$EXTERNALSYM KSAUDIO_SPEAKER_GROUND_REAR_RIGHT }
  {$EXTERNALSYM KSAUDIO_SPEAKER_TOP_MIDDLE }
  {$EXTERNALSYM KSAUDIO_SPEAKER_SUPER_WOOFER }
  //
  {$EXTERNALSYM KSDATAFORMAT_SUBTYPE_ANALOG }
  {$EXTERNALSYM KSDATAFORMAT_SUBTYPE_PCM }
  {$EXTERNALSYM KSDATAFORMAT_SUBTYPE_ADPCM }
  {$EXTERNALSYM KSDATAFORMAT_SUBTYPE_IEEE_FLOAT }
  {$EXTERNALSYM KSDATAFORMAT_SUBTYPE_ALAW }
  {$EXTERNALSYM KSDATAFORMAT_SUBTYPE_MULAW }
  {$EXTERNALSYM KSDATAFORMAT_SUBTYPE_DRM }
  {$EXTERNALSYM KSDATAFORMAT_SUBTYPE_MPEG }
  //
  {$EXTERNALSYM MEDIASUBTYPE_PCM }
  {$EXTERNALSYM MEDIASUBTYPE_WAVE }
  {$EXTERNALSYM MEDIASUBTYPE_AU }
  {$EXTERNALSYM MEDIASUBTYPE_AIFF }
  //
  {$EXTERNALSYM MEDIASUBTYPE_DRM_Audio }
  {$EXTERNALSYM MEDIASUBTYPE_IEEE_FLOAT }
  {$EXTERNALSYM MEDIASUBTYPE_DOLBY_AC3_SPDIF }
  {$EXTERNALSYM MEDIASUBTYPE_RAW_SPORT }
  {$EXTERNALSYM MEDIASUBTYPE_SPDIF_TAG_241h }


  // DirectSound Speaker Config
  KSAUDIO_SPEAKER_DIRECTOUT	= 0;
  KSAUDIO_SPEAKER_MONO		= SPEAKER_FRONT_CENTER;
  KSAUDIO_SPEAKER_STEREO	= SPEAKER_FRONT_LEFT or SPEAKER_FRONT_RIGHT;
  KSAUDIO_SPEAKER_QUAD		= SPEAKER_FRONT_LEFT or SPEAKER_FRONT_RIGHT or
				  SPEAKER_BACK_LEFT  or SPEAKER_BACK_RIGHT;
				  //
  KSAUDIO_SPEAKER_SURROUND	= SPEAKER_FRONT_LEFT or SPEAKER_FRONT_RIGHT or
				  SPEAKER_FRONT_CENTER or SPEAKER_BACK_CENTER;
				  //
  KSAUDIO_SPEAKER_5POINT1	= SPEAKER_FRONT_LEFT or SPEAKER_FRONT_RIGHT or
				  SPEAKER_FRONT_CENTER or SPEAKER_LOW_FREQUENCY or
				  SPEAKER_BACK_LEFT or SPEAKER_BACK_RIGHT;
				  //
  KSAUDIO_SPEAKER_7POINT1       = SPEAKER_FRONT_LEFT or SPEAKER_FRONT_RIGHT or
				  SPEAKER_FRONT_CENTER or SPEAKER_LOW_FREQUENCY or
				  SPEAKER_BACK_LEFT or SPEAKER_BACK_RIGHT or
				  SPEAKER_FRONT_LEFT_OF_CENTER or SPEAKER_FRONT_RIGHT_OF_CENTER;
				  //
  KSAUDIO_SPEAKER_5POINT1_SURROUND	= SPEAKER_FRONT_LEFT   or SPEAKER_FRONT_RIGHT or
					  SPEAKER_FRONT_CENTER or SPEAKER_LOW_FREQUENCY or
					  SPEAKER_SIDE_LEFT    or SPEAKER_SIDE_RIGHT;
				   //
  KSAUDIO_SPEAKER_7POINT1_SURROUND	= SPEAKER_FRONT_LEFT or SPEAKER_FRONT_RIGHT or
					  SPEAKER_FRONT_CENTER or SPEAKER_LOW_FREQUENCY or
					  SPEAKER_BACK_LEFT or SPEAKER_BACK_RIGHT or
					  SPEAKER_SIDE_LEFT or SPEAKER_SIDE_RIGHT;
				    //
  // The following are obsolete 5.1 and 7.1 settings (they lack side speakers).  Note this means
  // that the default 5.1 and 7.1 settings (KSAUDIO_SPEAKER_5POINT1 and KSAUDIO_SPEAKER_7POINT1 are
  // similarly obsolete but are unchanged for compatibility reasons).
  KSAUDIO_SPEAKER_5POINT1_BACK	= KSAUDIO_SPEAKER_5POINT1;
  KSAUDIO_SPEAKER_7POINT1_WIDE  = KSAUDIO_SPEAKER_7POINT1;

  // DVD Speaker Positions
  KSAUDIO_SPEAKER_GROUND_FRONT_LEFT   	= SPEAKER_FRONT_LEFT;
  KSAUDIO_SPEAKER_GROUND_FRONT_CENTER	= SPEAKER_FRONT_CENTER;
  KSAUDIO_SPEAKER_GROUND_FRONT_RIGHT  	= SPEAKER_FRONT_RIGHT;
  KSAUDIO_SPEAKER_GROUND_REAR_LEFT    	= SPEAKER_BACK_LEFT;
  KSAUDIO_SPEAKER_GROUND_REAR_RIGHT   	= SPEAKER_BACK_RIGHT;
  KSAUDIO_SPEAKER_TOP_MIDDLE          	= SPEAKER_TOP_CENTER;
  KSAUDIO_SPEAKER_SUPER_WOOFER        	= SPEAKER_LOW_FREQUENCY;

const
  // format guids
  KSDATAFORMAT_SUBTYPE_ANALOG	 : tGuid = '{6dba3190-67bd-11cf-a0f7-0020afd156e4}';
				     
  KSDATAFORMAT_SUBTYPE_PCM	 : tGuid = '{00000001-0000-0010-8000-00aa00389b71}';
  KSDATAFORMAT_SUBTYPE_ADPCM	 : tGuid = '{00000002-0000-0010-8000-00aa00389b71}';
  KSDATAFORMAT_SUBTYPE_IEEE_FLOAT: tGuid = '{00000003-0000-0010-8000-00aa00389b71}';
  KSDATAFORMAT_SUBTYPE_ALAW	 : tGuid = '{00000006-0000-0010-8000-00aa00389b71}';
  KSDATAFORMAT_SUBTYPE_MULAW	 : tGuid = '{00000007-0000-0010-8000-00aa00389b71}';
  KSDATAFORMAT_SUBTYPE_DRM	 : tGuid = '{00000009-0000-0010-8000-00aa00389b71}';
  KSDATAFORMAT_SUBTYPE_MPEG	 : tGuid = '{00000050-0000-0010-8000-00aa00389b71}';

  // MEDIASUBTYPE_PCM
  MEDIASUBTYPE_PCM		: tGuid = '{00000001-0000-0010-8000-00AA00389B71}';
  // MEDIASUBTYPE_WAVE
  MEDIASUBTYPE_WAVE		: tGuid = '{e436eb8b-524f-11ce-9f53-0020af0ba770}';
  // MEDIASUBTYPE_AU
  MEDIASUBTYPE_AU		: tGuid = '{e436eb8c-524f-11ce-9f53-0020af0ba770}';
  // MEDIASUBTYPE_AIFF
  MEDIASUBTYPE_AIFF		: tGuid = '{e436eb8d-524f-11ce-9f53-0020af0ba770}';

  // derived from WAVE_FORMAT_DRM
  MEDIASUBTYPE_DRM_Audio	: tGuid = '{00000009-0000-0010-8000-00aa00389b71}';
  // derived from WAVE_FORMAT_IEEE_FLOAT
  MEDIASUBTYPE_IEEE_FLOAT	: tGuid = '{00000003-0000-0010-8000-00aa00389b71}';
  // derived from WAVE_FORMAT_DOLBY_AC3_SPDIF
  MEDIASUBTYPE_DOLBY_AC3_SPDIF	: tGuid = '{00000092-0000-0010-8000-00aa00389b71}';
  // derived from WAVE_FORMAT_RAW_SPORT
  MEDIASUBTYPE_RAW_SPORT	: tGuid = '{00000240-0000-0010-8000-00aa00389b71}';
  // derived from wave format tag 0x241, call it SPDIF_TAG_241h for now
  MEDIASUBTYPE_SPDIF_TAG_241h	: tGuid = '{00000241-0000-0010-8000-00aa00389b71}';


type
//* Define data for MS ADPCM */

  //
  {$EXTERNALSYM PADPCMCOEFSET }
  {$EXTERNALSYM ADPCMCOEFSET }
  {$EXTERNALSYM NPADPCMCOEFSET }
  {$EXTERNALSYM LPADPCMCOEFSET }
  PADPCMCOEFSET = ^ADPCMCOEFSET;
  ADPCMCOEFSET = record
    //
    iCoef1: shortInt;
    iCoef2: shortInt;
  end;
  NPADPCMCOEFSET = ^ADPCMCOEFSET;
  LPADPCMCOEFSET = ^ADPCMCOEFSET;

  //
  {$EXTERNALSYM PADPCMWAVEFORMAT }
  {$EXTERNALSYM ADPCMWAVEFORMAT }
  {$EXTERNALSYM NPADPCMWAVEFORMAT }
  {$EXTERNALSYM LPADPCMWAVEFORMAT }
  PADPCMWAVEFORMAT = ^ADPCMWAVEFORMAT;
  ADPCMWAVEFORMAT = record
    //
    wfx: WAVEFORMATEX;
    wSamplesPerBlock: WORD;
    wNumCoef: WORD;
    aCoef: array[0..0] of ADPCMCOEFSET;
  end;
  NPADPCMWAVEFORMAT = ^ADPCMWAVEFORMAT;
  LPADPCMWAVEFORMAT = ^ADPCMWAVEFORMAT;

(*
//
//  Microsoft's DRM structure definitions
//
typedef struct drmwaveformat_tag {
	WAVEFORMATEX    wfx;
	WORD            wReserved;
	ULONG           ulContentId;
	WAVEFORMATEX    wfxSecure;
} DRMWAVEFORMAT;
typedef DRMWAVEFORMAT       *PDRMWAVEFORMAT;
typedef DRMWAVEFORMAT NEAR *NPDRMWAVEFORMAT;
typedef DRMWAVEFORMAT FAR  *LPDRMWAVEFORMAT;


//
//  Intel's DVI ADPCM structure definitions
//
//      for WAVE_FORMAT_DVI_ADPCM   (0x0011)
//
//

typedef struct dvi_adpcmwaveformat_tag {
        WAVEFORMATEX    wfx;
        WORD            wSamplesPerBlock;
} DVIADPCMWAVEFORMAT;
typedef DVIADPCMWAVEFORMAT       *PDVIADPCMWAVEFORMAT;
typedef DVIADPCMWAVEFORMAT NEAR *NPDVIADPCMWAVEFORMAT;
typedef DVIADPCMWAVEFORMAT FAR  *LPDVIADPCMWAVEFORMAT;

//
//  IMA endorsed ADPCM structure definitions--note that this is exactly
//  the same format as Intel's DVI ADPCM.
//
//      for WAVE_FORMAT_IMA_ADPCM   (0x0011)
//
//

typedef struct ima_adpcmwaveformat_tag {
        WAVEFORMATEX    wfx;
        WORD            wSamplesPerBlock;
} IMAADPCMWAVEFORMAT;
typedef IMAADPCMWAVEFORMAT       *PIMAADPCMWAVEFORMAT;
typedef IMAADPCMWAVEFORMAT NEAR *NPIMAADPCMWAVEFORMAT;
typedef IMAADPCMWAVEFORMAT FAR  *LPIMAADPCMWAVEFORMAT;

/*
//VideoLogic's Media Space ADPCM Structure definitions
// for  WAVE_FORMAT_MEDIASPACE_ADPCM    (0x0012)
//
//
*/
typedef struct mediaspace_adpcmwaveformat_tag {
        WAVEFORMATEX    wfx;
        WORD    wRevision;
} MEDIASPACEADPCMWAVEFORMAT;
typedef MEDIASPACEADPCMWAVEFORMAT           *PMEDIASPACEADPCMWAVEFORMAT;
typedef MEDIASPACEADPCMWAVEFORMAT NEAR     *NPMEDIASPACEADPCMWAVEFORMAT;
typedef MEDIASPACEADPCMWAVEFORMAT FAR      *LPMEDIASPACEADPCMWAVEFORMAT;

//
//  Sierra Semiconductor
//
//      for WAVE_FORMAT_SIERRA_ADPCM   (0x0013)
//
//

typedef struct sierra_adpcmwaveformat_tag {
        WAVEFORMATEX    wfx;
	WORD            wRevision;
} SIERRAADPCMWAVEFORMAT;
typedef SIERRAADPCMWAVEFORMAT   *PSIERRAADPCMWAVEFORMAT;
typedef SIERRAADPCMWAVEFORMAT NEAR      *NPSIERRAADPCMWAVEFORMAT;
typedef SIERRAADPCMWAVEFORMAT FAR       *LPSIERRAADPCMWAVEFORMAT;

//
//  Antex Electronics  structure definitions
//
//      for WAVE_FORMAT_G723_ADPCM   (0x0014)
//
//

typedef struct g723_adpcmwaveformat_tag {
        WAVEFORMATEX    wfx;
	WORD            cbExtraSize;
        WORD            nAuxBlockSize;
} G723_ADPCMWAVEFORMAT;
typedef G723_ADPCMWAVEFORMAT *PG723_ADPCMWAVEFORMAT;
typedef G723_ADPCMWAVEFORMAT NEAR *NPG723_ADPCMWAVEFORMAT;
typedef G723_ADPCMWAVEFORMAT FAR  *LPG723_ADPCMWAVEFORMAT;

//
//  DSP Solutions (formerly DIGISPEECH) structure definitions
//
//      for WAVE_FORMAT_DIGISTD   (0x0015)
//
//

typedef struct digistdwaveformat_tag {
        WAVEFORMATEX    wfx;
} DIGISTDWAVEFORMAT;
typedef DIGISTDWAVEFORMAT       *PDIGISTDWAVEFORMAT;
typedef DIGISTDWAVEFORMAT NEAR *NPDIGISTDWAVEFORMAT;
typedef DIGISTDWAVEFORMAT FAR  *LPDIGISTDWAVEFORMAT;

//
//  DSP Solutions (formerly DIGISPEECH) structure definitions
//
//      for WAVE_FORMAT_DIGIFIX   (0x0016)
//
//

typedef struct digifixwaveformat_tag {
        WAVEFORMATEX    wfx;
} DIGIFIXWAVEFORMAT;
typedef DIGIFIXWAVEFORMAT       *PDIGIFIXWAVEFORMAT;
typedef DIGIFIXWAVEFORMAT NEAR *NPDIGIFIXWAVEFORMAT;
typedef DIGIFIXWAVEFORMAT FAR  *LPDIGIFIXWAVEFORMAT;

//
//   Dialogic Corporation
// WAVEFORMAT_DIALOGIC_OKI_ADPCM   (0x0017)
//
typedef struct creative_fastspeechformat_tag{
        WAVEFORMATEX    ewf;
}DIALOGICOKIADPCMWAVEFORMAT;
typedef DIALOGICOKIADPCMWAVEFORMAT       *PDIALOGICOKIADPCMWAVEFORMAT;
typedef DIALOGICOKIADPCMWAVEFORMAT NEAR *NPDIALOGICOKIADPCMWAVEFORMAT;
typedef DIALOGICOKIADPCMWAVEFORMAT FAR  *LPDIALOGICOKIADPCMWAVEFORMAT;

//
//  Yamaha Compression's ADPCM structure definitions
//
//      for WAVE_FORMAT_YAMAHA_ADPCM   (0x0020)
//
//

typedef struct yamaha_adpmcwaveformat_tag {
        WAVEFORMATEX    wfx;

} YAMAHA_ADPCMWAVEFORMAT;
typedef YAMAHA_ADPCMWAVEFORMAT *PYAMAHA_ADPCMWAVEFORMAT;
typedef YAMAHA_ADPCMWAVEFORMAT NEAR *NPYAMAHA_ADPCMWAVEFORMAT;
typedef YAMAHA_ADPCMWAVEFORMAT FAR  *LPYAMAHA_ADPCMWAVEFORMAT;

//
//  Speech Compression's Sonarc structure definitions
//
//      for WAVE_FORMAT_SONARC   (0x0021)
//
//

typedef struct sonarcwaveformat_tag {
        WAVEFORMATEX    wfx;
        WORD            wCompType;
} SONARCWAVEFORMAT;
typedef SONARCWAVEFORMAT       *PSONARCWAVEFORMAT;
typedef SONARCWAVEFORMAT NEAR *NPSONARCWAVEFORMAT;
typedef SONARCWAVEFORMAT FAR  *LPSONARCWAVEFORMAT;

//
//  DSP Groups's TRUESPEECH structure definitions
//
//      for WAVE_FORMAT_DSPGROUP_TRUESPEECH   (0x0022)
//
//

typedef struct truespeechwaveformat_tag {
	WAVEFORMATEX    wfx;
        WORD            wRevision;
        WORD            nSamplesPerBlock;
        BYTE            abReserved[28];
} TRUESPEECHWAVEFORMAT;
typedef TRUESPEECHWAVEFORMAT       *PTRUESPEECHWAVEFORMAT;
typedef TRUESPEECHWAVEFORMAT NEAR *NPTRUESPEECHWAVEFORMAT;
typedef TRUESPEECHWAVEFORMAT FAR  *LPTRUESPEECHWAVEFORMAT;

//
//  Echo Speech Corp structure definitions
//
//      for WAVE_FORMAT_ECHOSC1   (0x0023)
//
//

typedef struct echosc1waveformat_tag {
        WAVEFORMATEX    wfx;
} ECHOSC1WAVEFORMAT;
typedef ECHOSC1WAVEFORMAT       *PECHOSC1WAVEFORMAT;
typedef ECHOSC1WAVEFORMAT NEAR *NPECHOSC1WAVEFORMAT;
typedef ECHOSC1WAVEFORMAT FAR  *LPECHOSC1WAVEFORMAT;

//
//  Audiofile Inc.structure definitions
//
//      for WAVE_FORMAT_AUDIOFILE_AF36   (0x0024)
//
//

typedef struct audiofile_af36waveformat_tag {
        WAVEFORMATEX    wfx;
} AUDIOFILE_AF36WAVEFORMAT;
typedef AUDIOFILE_AF36WAVEFORMAT       *PAUDIOFILE_AF36WAVEFORMAT;
typedef AUDIOFILE_AF36WAVEFORMAT NEAR *NPAUDIOFILE_AF36WAVEFORMAT;
typedef AUDIOFILE_AF36WAVEFORMAT FAR  *LPAUDIOFILE_AF36WAVEFORMAT;

//
//  Audio Processing Technology structure definitions
//
//      for WAVE_FORMAT_APTX   (0x0025)
//
//
typedef struct aptxwaveformat_tag {
        WAVEFORMATEX    wfx;
} APTXWAVEFORMAT;
typedef APTXWAVEFORMAT       *PAPTXWAVEFORMAT;
typedef APTXWAVEFORMAT NEAR *NPAPTXWAVEFORMAT;
typedef APTXWAVEFORMAT FAR  *LPAPTXWAVEFORMAT;

//
//  Audiofile Inc.structure definitions
//
//      for WAVE_FORMAT_AUDIOFILE_AF10   (0x0026)
//
//

typedef struct audiofile_af10waveformat_tag {
	WAVEFORMATEX    wfx;
} AUDIOFILE_AF10WAVEFORMAT;
typedef AUDIOFILE_AF10WAVEFORMAT       *PAUDIOFILE_AF10WAVEFORMAT;
typedef AUDIOFILE_AF10WAVEFORMAT NEAR *NPAUDIOFILE_AF10WAVEFORMAT;
typedef AUDIOFILE_AF10WAVEFORMAT FAR  *LPAUDIOFILE_AF10WAVEFORMAT;

//
/* Dolby's AC-2 wave format structure definition
           WAVE_FORMAT_DOLBY_AC2    (0x0030)*/
//
typedef struct dolbyac2waveformat_tag {
        WAVEFORMATEX    wfx;
        WORD            nAuxBitsCode;
} DOLBYAC2WAVEFORMAT;

/*Microsoft's */
// WAVE_FORMAT_GSM 610           0x0031
//
typedef struct gsm610waveformat_tag {
WAVEFORMATEX    wfx;
WORD                    wSamplesPerBlock;
} GSM610WAVEFORMAT;
typedef GSM610WAVEFORMAT *PGSM610WAVEFORMAT;
typedef GSM610WAVEFORMAT NEAR    *NPGSM610WAVEFORMAT;
typedef GSM610WAVEFORMAT FAR     *LPGSM610WAVEFORMAT;

//
//      Antex Electronics Corp
//
//      for WAVE_FORMAT_ADPCME                  (0x0033)
//
//

typedef struct adpcmewaveformat_tag {
        WAVEFORMATEX    wfx;
        WORD            wSamplesPerBlock;
} ADPCMEWAVEFORMAT;
typedef ADPCMEWAVEFORMAT                *PADPCMEWAVEFORMAT;
typedef ADPCMEWAVEFORMAT NEAR   *NPADPCMEWAVEFORMAT;
typedef ADPCMEWAVEFORMAT FAR    *LPADPCMEWAVEFORMAT;

/*       Control Resources Limited */
// WAVE_FORMAT_CONTROL_RES_VQLPC                 0x0034
//
typedef struct contres_vqlpcwaveformat_tag {
WAVEFORMATEX    wfx;
WORD                    wSamplesPerBlock;
} CONTRESVQLPCWAVEFORMAT;
typedef CONTRESVQLPCWAVEFORMAT *PCONTRESVQLPCWAVEFORMAT;
typedef CONTRESVQLPCWAVEFORMAT NEAR      *NPCONTRESVQLPCWAVEFORMAT;
typedef CONTRESVQLPCWAVEFORMAT FAR       *LPCONTRESVQLPCWAVEFORMAT;

//
//
//
//      for WAVE_FORMAT_DIGIREAL                   (0x0035)
//
//

typedef struct digirealwaveformat_tag {
        WAVEFORMATEX    wfx;
        WORD            wSamplesPerBlock;
} DIGIREALWAVEFORMAT;
typedef DIGIREALWAVEFORMAT *PDIGIREALWAVEFORMAT;
typedef DIGIREALWAVEFORMAT NEAR *NPDIGIREALWAVEFORMAT;
typedef DIGIREALWAVEFORMAT FAR *LPDIGIREALWAVEFORMAT;

//
//  DSP Solutions
//
//      for WAVE_FORMAT_DIGIADPCM   (0x0036)
//
//

typedef struct digiadpcmmwaveformat_tag {
	WAVEFORMATEX    wfx;
	WORD            wSamplesPerBlock;
} DIGIADPCMWAVEFORMAT;
typedef DIGIADPCMWAVEFORMAT       *PDIGIADPCMWAVEFORMAT;
typedef DIGIADPCMWAVEFORMAT NEAR *NPDIGIADPCMWAVEFORMAT;
typedef DIGIADPCMWAVEFORMAT FAR  *LPDIGIADPCMWAVEFORMAT;

/*       Control Resources Limited */
// WAVE_FORMAT_CONTROL_RES_CR10          0x0037
//
typedef struct contres_cr10waveformat_tag {
WAVEFORMATEX    wfx;
WORD                    wSamplesPerBlock;
} CONTRESCR10WAVEFORMAT;
typedef CONTRESCR10WAVEFORMAT *PCONTRESCR10WAVEFORMAT;
typedef CONTRESCR10WAVEFORMAT NEAR       *NPCONTRESCR10WAVEFORMAT;
typedef CONTRESCR10WAVEFORMAT FAR        *LPCONTRESCR10WAVEFORMAT;

//
//  Natural Microsystems
//
//      for WAVE_FORMAT_NMS_VBXADPCM   (0x0038)
//
//

typedef struct nms_vbxadpcmmwaveformat_tag {
	WAVEFORMATEX    wfx;
        WORD            wSamplesPerBlock;
} NMS_VBXADPCMWAVEFORMAT;
typedef NMS_VBXADPCMWAVEFORMAT       *PNMS_VBXADPCMWAVEFORMAT;
typedef NMS_VBXADPCMWAVEFORMAT NEAR *NPNMS_VBXADPCMWAVEFORMAT;
typedef NMS_VBXADPCMWAVEFORMAT FAR  *LPNMS_VBXADPCMWAVEFORMAT;

//
//  Antex Electronics  structure definitions
//
//      for WAVE_FORMAT_G721_ADPCM   (0x0040)
//
//

typedef struct g721_adpcmwaveformat_tag {
        WAVEFORMATEX    wfx;
        WORD            nAuxBlockSize;
} G721_ADPCMWAVEFORMAT;
typedef G721_ADPCMWAVEFORMAT *PG721_ADPCMWAVEFORMAT;
typedef G721_ADPCMWAVEFORMAT NEAR *NPG721_ADPCMWAVEFORMAT;
typedef G721_ADPCMWAVEFORMAT FAR  *LPG721_ADPCMWAVEFORMAT;

//
//
// Microsoft MPEG audio WAV definition
//
/*  MPEG-1 audio wave format (audio layer only).   (0x0050)   */
typedef struct mpeg1waveformat_tag {
    WAVEFORMATEX    wfx;
    WORD            fwHeadLayer;
    DWORD           dwHeadBitrate;
    WORD            fwHeadMode;
    WORD            fwHeadModeExt;
    WORD            wHeadEmphasis;
    WORD            fwHeadFlags;
    DWORD           dwPTSLow;
    DWORD           dwPTSHigh;
} MPEG1WAVEFORMAT;
typedef MPEG1WAVEFORMAT                 *PMPEG1WAVEFORMAT;
typedef MPEG1WAVEFORMAT NEAR           *NPMPEG1WAVEFORMAT;
typedef MPEG1WAVEFORMAT FAR            *LPMPEG1WAVEFORMAT;

#define ACM_MPEG_LAYER1             (0x0001)
#define ACM_MPEG_LAYER2             (0x0002)
#define ACM_MPEG_LAYER3             (0x0004)
#define ACM_MPEG_STEREO             (0x0001)
#define ACM_MPEG_JOINTSTEREO        (0x0002)
#define ACM_MPEG_DUALCHANNEL        (0x0004)
#define ACM_MPEG_SINGLECHANNEL      (0x0008)
#define ACM_MPEG_PRIVATEBIT         (0x0001)
#define ACM_MPEG_COPYRIGHT          (0x0002)
#define ACM_MPEG_ORIGINALHOME       (0x0004)
#define ACM_MPEG_PROTECTIONBIT      (0x0008)
#define ACM_MPEG_ID_MPEG1           (0x0010)

//
// MPEG Layer3 WAVEFORMATEX structure
// for WAVE_FORMAT_MPEGLAYER3 (0x0055)
//
#define MPEGLAYER3_WFX_EXTRA_BYTES   12

// WAVE_FORMAT_MPEGLAYER3 format sructure
//
typedef struct mpeglayer3waveformat_tag {
  WAVEFORMATEX  wfx;
  WORD          wID;
  DWORD         fdwFlags;
  WORD          nBlockSize;
  WORD          nFramesPerBlock;
  WORD          nCodecDelay;
} MPEGLAYER3WAVEFORMAT;

typedef MPEGLAYER3WAVEFORMAT          *PMPEGLAYER3WAVEFORMAT;
typedef MPEGLAYER3WAVEFORMAT NEAR    *NPMPEGLAYER3WAVEFORMAT;
typedef MPEGLAYER3WAVEFORMAT FAR     *LPMPEGLAYER3WAVEFORMAT;

//==========================================================================;

#define MPEGLAYER3_ID_UNKNOWN            0
#define MPEGLAYER3_ID_MPEG               1
#define MPEGLAYER3_ID_CONSTANTFRAMESIZE  2

#define MPEGLAYER3_FLAG_PADDING_ISO      0x00000000
#define MPEGLAYER3_FLAG_PADDING_ON       0x00000001
#define MPEGLAYER3_FLAG_PADDING_OFF      0x00000002

//
//  Creative's ADPCM structure definitions
//
//      for WAVE_FORMAT_CREATIVE_ADPCM   (0x0200)
//
//

typedef struct creative_adpcmwaveformat_tag {
        WAVEFORMATEX    wfx;
        WORD            wRevision;
} CREATIVEADPCMWAVEFORMAT;
typedef CREATIVEADPCMWAVEFORMAT       *PCREATIVEADPCMWAVEFORMAT;
typedef CREATIVEADPCMWAVEFORMAT NEAR *NPCREATIVEADPCMWAVEFORMAT;
typedef CREATIVEADPCMWAVEFORMAT FAR  *LPCREATIVEADPCMWAVEFORMAT;

//
//    Creative FASTSPEECH
// WAVEFORMAT_CREATIVE_FASTSPEECH8   (0x0202)
//
typedef struct creative_fastspeech8format_tag {
        WAVEFORMATEX    wfx;
        WORD wRevision;
} CREATIVEFASTSPEECH8WAVEFORMAT;
typedef CREATIVEFASTSPEECH8WAVEFORMAT       *PCREATIVEFASTSPEECH8WAVEFORMAT;
typedef CREATIVEFASTSPEECH8WAVEFORMAT NEAR *NPCREATIVEFASTSPEECH8WAVEFORMAT;
typedef CREATIVEFASTSPEECH8WAVEFORMAT FAR  *LPCREATIVEFASTSPEECH8WAVEFORMAT;
//
//    Creative FASTSPEECH
// WAVEFORMAT_CREATIVE_FASTSPEECH10   (0x0203)
//
typedef struct creative_fastspeech10format_tag {
	WAVEFORMATEX    wfx;
        WORD wRevision;
} CREATIVEFASTSPEECH10WAVEFORMAT;
typedef CREATIVEFASTSPEECH10WAVEFORMAT       *PCREATIVEFASTSPEECH10WAVEFORMAT;
typedef CREATIVEFASTSPEECH10WAVEFORMAT NEAR *NPCREATIVEFASTSPEECH10WAVEFORMAT;
typedef CREATIVEFASTSPEECH10WAVEFORMAT FAR  *LPCREATIVEFASTSPEECH10WAVEFORMAT;

//
//  Fujitsu FM Towns 'SND' structure
//
//      for WAVE_FORMAT_FMMTOWNS_SND   (0x0300)
//
//

typedef struct fmtowns_snd_waveformat_tag {
        WAVEFORMATEX    wfx;
        WORD            wRevision;
} FMTOWNS_SND_WAVEFORMAT;
typedef FMTOWNS_SND_WAVEFORMAT       *PFMTOWNS_SND_WAVEFORMAT;
typedef FMTOWNS_SND_WAVEFORMAT NEAR *NPFMTOWNS_SND_WAVEFORMAT;
typedef FMTOWNS_SND_WAVEFORMAT FAR  *LPFMTOWNS_SND_WAVEFORMAT;

//
//  Olivetti structure
//
//      for WAVE_FORMAT_OLIGSM   (0x1000)
//
//

typedef struct oligsmwaveformat_tag {
        WAVEFORMATEX    wfx;
} OLIGSMWAVEFORMAT;
typedef OLIGSMWAVEFORMAT     *POLIGSMWAVEFORMAT;
typedef OLIGSMWAVEFORMAT NEAR *NPOLIGSMWAVEFORMAT;
typedef OLIGSMWAVEFORMAT  FAR  *LPOLIGSMWAVEFORMAT;

//
//  Olivetti structure
//
//      for WAVE_FORMAT_OLIADPCM   (0x1001)
//
//

typedef struct oliadpcmwaveformat_tag {
        WAVEFORMATEX    wfx;
} OLIADPCMWAVEFORMAT;
typedef OLIADPCMWAVEFORMAT     *POLIADPCMWAVEFORMAT;
typedef OLIADPCMWAVEFORMAT NEAR *NPOLIADPCMWAVEFORMAT ;
typedef OLIADPCMWAVEFORMAT  FAR  *LPOLIADPCMWAVEFORMAT;

//
//  Olivetti structure
//
//      for WAVE_FORMAT_OLICELP   (0x1002)
//
//

typedef struct olicelpwaveformat_tag {
	WAVEFORMATEX    wfx;
} OLICELPWAVEFORMAT;
typedef OLICELPWAVEFORMAT     *POLICELPWAVEFORMAT;
typedef OLICELPWAVEFORMAT NEAR *NPOLICELPWAVEFORMAT ;
typedef OLICELPWAVEFORMAT  FAR  *LPOLICELPWAVEFORMAT;

//
//  Olivetti structure
//
//      for WAVE_FORMAT_OLISBC   (0x1003)
//
//

typedef struct olisbcwaveformat_tag {
        WAVEFORMATEX    wfx;
} OLISBCWAVEFORMAT;
typedef OLISBCWAVEFORMAT     *POLISBCWAVEFORMAT;
typedef OLISBCWAVEFORMAT NEAR *NPOLISBCWAVEFORMAT ;
typedef OLISBCWAVEFORMAT  FAR  *LPOLISBCWAVEFORMAT;

//
//  Olivetti structure
//
//      for WAVE_FORMAT_OLIOPR   (0x1004)
//
//

typedef struct olioprwaveformat_tag {
        WAVEFORMATEX    wfx;
} OLIOPRWAVEFORMAT;
typedef OLIOPRWAVEFORMAT     *POLIOPRWAVEFORMAT;
typedef OLIOPRWAVEFORMAT NEAR *NPOLIOPRWAVEFORMAT ;
typedef OLIOPRWAVEFORMAT  FAR  *LPOLIOPRWAVEFORMAT;

//
//  Crystal Semiconductor IMA ADPCM format
//
//      for WAVE_FORMAT_CS_IMAADPCM   (0x0039)
//
//

typedef struct csimaadpcmwaveformat_tag {
	WAVEFORMATEX    wfx;
} CSIMAADPCMWAVEFORMAT;
typedef CSIMAADPCMWAVEFORMAT     *PCSIMAADPCMWAVEFORMAT;
typedef CSIMAADPCMWAVEFORMAT NEAR *NPCSIMAADPCMWAVEFORMAT ;
typedef CSIMAADPCMWAVEFORMAT  FAR  *LPCSIMAADPCMWAVEFORMAT;

*)


{*
  Returns ACM version and true if ACM is retail (Build = 0)
}
function getAcmVersion(var major, minor: byte; var build: Word): bool;

{*
  Converts mid value to string representation.
}
function mid2str(mid: unsigned): string;
{*
  Converts format value to string representation (using base64 encoding).
}
function waveFormat2str(const format: WAVEFORMATEX): aString;

{*
  	Converts string representation of WAVEFORMATEX structure (encoded using base64) to format value.
  
	If size is too small to hold the structure, this function returns false and size parameter will be set to required size of structure.
	Otherwise it fills the format and returns true.
}
function str2waveFormat(const str: aString; var format: WAVEFORMATEX; var size: unsigned): bool; overload;
{*
  Converts string representation of WAVEFORMATEX structure (encoded using base64) to format value.
  
Allocates necessary amount of memory for format parameter.
}
function str2waveFormat(const str: aString; var format: pWAVEFORMATEX; var size: unsigned): bool; overload;
function str2waveFormat(const str: aString; var format: pWAVEFORMATEX): bool; overload;
{*
  Returns description of given wave format.

	@Returns defStr if format is not supported by driver(s).
}
function getFormatDescription(const format: WAVEFORMATEX; driver: HACMDRIVER = 0; defStr: string = ''): string;
//
{*
  Allocates wave format with maximum possible size for specified driver.

	@Returns number of bytes allocated.
}
function allocateWaveFormat(out format: pWAVEFORMATEX; driver: HACMOBJ = 0): unsigned; overload;
{*
  Allocates wave format equal to specified source format.
	
	@Returns number of bytes allocated.
}
function allocateWaveFormat(const srcFormat: WAVEFORMATEX; out format: pWAVEFORMATEX): unsigned; overload;
{*
  Deallocates memory used by format.
}
function deleteWaveFormat(format: pWAVEFORMATEX): bool;
//
{*
  Returns maximum possible size of wave format for specified driver.

  If driver = 0 function queries all installed drivers.
}
function getMaxWaveFormatSize(driver: HACMOBJ = 0): unsigned;
{*
  Returns maximum possible size of wave filter for specified driver.

  If driver = 0 function queries all installed drivers.
}
function getMaxWaveFilterSize(driver: HACMOBJ = 0): unsigned;


implementation


uses
  unaUtils;

const
  msacm32 = 'msacm32.dll';

// acm
function acm_getVersion; external msacm32 name 'acmGetVersion';
function acm_metrics; external msacm32 name 'acmMetrics';

// acmDriver
function acm_driverEnum; external msacm32 name 'acmDriverEnum';
function acm_driverID; external msacm32 name 'acmDriverID';

function acm_driverAddA; external msacm32 name 'acmDriverAddA';
function acm_driverAddW; external msacm32 name 'acmDriverAddW';
function acm_driverAdd; external msacm32 name 'acmDriverAddA';

function acm_driverRemove; external msacm32 name 'acmDriverRemove';
function acm_driverOpen; external msacm32 name 'acmDriverOpen';
function acm_driverClose; external msacm32 name 'acmDriverClose';
function acm_driverMessage; external msacm32 name 'acmDriverMessage';
function acm_driverPriority; external msacm32 name 'acmDriverPriority';

function ACMDRIVERDETAILS_FCCTYPE_AUDIOCODEC(): FOURCC;
begin
  Result := mmioStringToFOURCC('audc', 0);
end;

function acm_driverDetailsA; external msacm32 name 'acmDriverDetailsA';
function acm_driverDetailsW; external msacm32 name 'acmDriverDetailsW';
function acm_driverDetails; external msacm32 name 'acmDriverDetailsA';

// acmFormat

function acm_formatTagDetailsA; external msacm32 name 'acmFormatTagDetailsA';
function acm_formatTagDetailsW; external msacm32 name 'acmFormatTagDetailsW';
function acm_formatTagDetails; external msacm32 name 'acmFormatTagDetailsA';

function acm_formatTagEnumA; external msacm32 name 'acmFormatTagEnumA';
function acm_formatTagEnumW; external msacm32 name 'acmFormatTagEnumW';
function acm_formatTagEnum; external msacm32 name 'acmFormatTagEnumA';

function acm_formatDetailsA; external msacm32 name 'acmFormatDetailsA';
function acm_formatDetailsW; external msacm32 name 'acmFormatDetailsW';
function acm_formatDetails; external msacm32 name 'acmFormatDetailsA';

function acm_formatEnumA; external msacm32 name 'acmFormatEnumA';
function acm_formatEnumW; external msacm32 name 'acmFormatEnumW';
function acm_formatEnum; external msacm32 name 'acmFormatEnumA';

function acm_formatSuggest; external msacm32 name 'acmFormatSuggest';

function acm_formatChooseA; external msacm32 name 'acmFormatChooseA';
function acm_formatChooseW; external msacm32 name 'acmFormatChooseW';
function acm_formatChoose; external msacm32 name 'acmFormatChooseA';

// acmFilter

function acm_filterTagDetailsA; external msacm32 name 'acmFilterTagDetailsA';
function acm_filterTagDetailsW; external msacm32 name 'acmFilterTagDetailsW';
function acm_filterTagDetails; external msacm32 name 'acmFilterTagDetailsA';

function acm_filterTagEnumA; external msacm32 name 'acmFilterTagEnumA';
function acm_filterTagEnumW; external msacm32 name 'acmFilterTagEnumW';
function acm_filterTagEnum; external msacm32 name 'acmFilterTagEnumA';

function acm_filterDetailsA; external msacm32 name 'acmFilterDetailsA';
function acm_filterDetailsW; external msacm32 name 'acmFilterDetailsW';
function acm_filterDetails; external msacm32 name 'acmFilterDetailsA';

function acm_filterEnumA; external msacm32 name 'acmFilterEnumA';
function acm_filterEnumW; external msacm32 name 'acmFilterEnumW';
function acm_filterEnum; external msacm32 name 'acmFilterEnumA';

function acm_filterChooseA; external msacm32 name 'acmFilterChooseA';
function acm_filterChooseW; external msacm32 name 'acmFilterChooseW';
function acm_filterChoose; external msacm32 name 'acmFilterChooseA';

// acmStream

function acm_streamOpen; external msacm32 name 'acmStreamOpen';
function acm_streamClose; external msacm32 name 'acmStreamClose';
function acm_streamSize; external msacm32 name 'acmStreamSize';
function acm_streamReset; external msacm32 name 'acmStreamReset';
function acm_streamMessage; external msacm32 name 'acmStreamMessage';
function acm_streamConvert; external msacm32 name 'acmStreamConvert';
function acm_streamPrepareHeader; external msacm32 name 'acmStreamPrepareHeader';
function acm_streamUnprepareHeader; external msacm32 name 'acmStreamUnprepareHeader';

// -- --
function mid2str(mid: unsigned): string;
begin
  case (mid) of
    //
    MM_MICROSOFT                  : Result := 'Microsoft Corporation';
    MM_CREATIVE                   : Result := 'Creative Labs, Inc.';
    MM_MEDIAVISION                : Result := 'Media Vision, Inc.';
    MM_FUJITSU                    : Result := 'Fujitsu Corp.';
    MM_PRAGMATRAX                 : Result := 'PRAGMATRAX Software';
    MM_CYRIX                      : Result := 'Cyrix Corporation';
    MM_PHILIPS_SPEECH_PROCESSING  : Result := 'Philips Speech Processing';
    MM_NETXL                      : Result := 'NetXL, Inc.';
    MM_ZYXEL                      : Result := 'ZyXEL Communications, Inc.';
    MM_BECUBED                    : Result := 'BeCubed Software Inc.';
    MM_AARDVARK                   : Result := 'Aardvark Computer Systems, Inc.';
    MM_BINTEC                     : Result := 'Bin Tec Communications GmbH';
    MM_HEWLETT_PACKARD            : Result := 'Hewlett-Packard Company';
    MM_ACULAB                     : Result := 'Aculab plc';
    MM_FAITH                      : Result := 'Faith,Inc.';
    MM_MITEL                      : Result := 'Mitel Corporation';
    MM_QUANTUM3D                  : Result := 'Quantum3D, Inc.';
    MM_SNI                        : Result := 'Siemens-Nixdorf';
    MM_EMU                        : Result := 'E-mu Systems, Inc.';
    MM_ARTISOFT                   : Result := 'Artisoft, Inc.';
    MM_TURTLE_BEACH               : Result := 'Turtle Beach, Inc.';
    MM_IBM                        : Result := 'IBM Corporation';
    MM_VOCALTEC                   : Result := 'Vocaltec Ltd.';
    MM_ROLAND                     : Result := 'Roland';
    MM_DSP_SOLUTIONS              : Result := 'DSP Solutions, Inc.';
    MM_NEC                        : Result := 'NEC';
    MM_ATI                        : Result := 'ATI Technologies Inc.';
    MM_WANGLABS                   : Result := 'Wang Laboratories, Inc.';
    MM_TANDY                      : Result := 'Tandy Corporation';
    MM_VOYETRA                    : Result := 'Voyetra';
    MM_ANTEX                      : Result := 'Antex Electronics Corporation';
    MM_ICL_PS                     : Result := 'ICL Personal Systems';
    MM_INTEL                      : Result := 'Intel Corporation';
    MM_GRAVIS                     : Result := 'Advanced Gravis';
    MM_VAL                        : Result := 'Video Associates Labs, Inc.';
    MM_INTERACTIVE                : Result := 'InterActive Inc.';
    MM_YAMAHA                     : Result := 'Yamaha Corporation of America';
    MM_EVEREX                     : Result := 'Everex Systems, Inc.';
    MM_ECHO                       : Result := 'Echo Speech Corporation';
    MM_SIERRA                     : Result := 'Sierra Semiconductor Corp';
    MM_CAT                        : Result := 'Computer Aided Technologies';
    MM_APPS                       : Result := 'APPS Software International';
    MM_DSP_GROUP                  : Result := 'DSP Group, Inc.';
    MM_MELABS                     : Result := 'microEngineering Labs';
    MM_COMPUTER_FRIENDS           : Result := 'Computer Friends, Inc.';
    MM_ESS                        : Result := 'ESS Technology';
    MM_AUDIOFILE                  : Result := 'Audio, Inc.';
    MM_MOTOROLA                   : Result := 'Motorola, Inc.';
    MM_CANOPUS                    : Result := 'Canopus, co., Ltd.';
    MM_EPSON                      : Result := 'Seiko Epson Corporation';
    MM_TRUEVISION                 : Result := 'Truevision';
    MM_AZTECH                     : Result := 'Aztech Labs, Inc.';
    MM_VIDEOLOGIC                 : Result := 'Videologic';
    MM_SCALACS                    : Result := 'SCALACS';
    MM_KORG                       : Result := 'Korg Inc.';
    MM_APT                        : Result := 'Audio Processing Technology';
    MM_ICS                        : Result := 'Integrated Circuit Systems, Inc.';
    MM_ITERATEDSYS                : Result := 'Iterated Systems, Inc.';
    MM_METHEUS                    : Result := 'Metheus';
    MM_LOGITECH                   : Result := 'Logitech, Inc.';
    MM_WINNOV                     : Result := 'Winnov, Inc.';
    MM_NCR                        : Result := 'NCR Corporation';
    MM_EXAN                       : Result := 'EXAN';
    MM_AST                        : Result := 'AST Research Inc.';
    MM_WILLOWPOND                 : Result := 'Willow Pond Corporation';
    MM_SONICFOUNDRY               : Result := 'Sonic Foundry';
    MM_VITEC                      : Result := 'Vitec Multimedia';
    MM_MOSCOM                     : Result := 'MOSCOM Corporation';
    MM_SILICONSOFT                : Result := 'Silicon Soft, Inc.';
    MM_TERRATEC                   : Result := 'TerraTec Electronic GmbH';
    MM_MEDIASONIC                 : Result := 'MediaSonic Ltd.';
    MM_SANYO                      : Result := 'SANYO Electric Co., Ltd.';
    MM_SUPERMAC                   : Result := 'Supermac';
    MM_AUDIOPT                    : Result := 'Audio Processing Technology';
    MM_NOGATECH                   : Result := 'NOGATECH Ltd.';
    MM_SPEECHCOMP                 : Result := 'Speech Compression';
    MM_AHEAD                      : Result := 'Ahead, Inc.';
    MM_DOLBY                      : Result := 'Dolby Laboratories';
    MM_OKI                        : Result := 'OKI';
    MM_AURAVISION                 : Result := 'AuraVision Corporation';
    MM_OLIVETTI                   : Result := 'Ing C. Olivetti & C., S.p.A.';
    MM_IOMAGIC                    : Result := 'I/O Magic Corporation';
    MM_MATSUSHITA                 : Result := 'Matsushita Electric Industrial Co., Ltd.';
    MM_CONTROLRES                 : Result := 'Control Resources Limited';
    MM_XEBEC                      : Result := 'Xebec Multimedia Solutions Limited';
    MM_NEWMEDIA                   : Result := 'New Media Corporation';
    MM_NMS                        : Result := 'Natural MicroSystems';
    MM_LYRRUS                     : Result := 'Lyrrus Inc.';
    MM_COMPUSIC                   : Result := 'Compusic';
    MM_OPTI                       : Result := 'OPTi Computers Inc.';
    MM_ADLACC                     : Result := 'Adlib Accessories Inc.';
    MM_COMPAQ                     : Result := 'Compaq Computer Corp.';
    MM_DIALOGIC                   : Result := 'Dialogic Corporation';
    MM_INSOFT                     : Result := 'InSoft, Inc.';
    MM_MPTUS                      : Result := 'M.P. Technologies, Inc.';
    MM_WEITEK                     : Result := 'Weitek';
    MM_LERNOUT_AND_HAUSPIE        : Result := 'Lernout & Hauspie';
    MM_QCIAR                      : Result := 'Quanta Computer Inc.';
    MM_APPLE                      : Result := 'Apple Computer, Inc.';
    MM_DIGITAL                    : Result := 'Digital Equipment Corporation';
    MM_MOTU                       : Result := 'Mark of the Unicorn';
    MM_WORKBIT                    : Result := 'Workbit Corporation';
    MM_OSITECH                    : Result := 'Ositech Communications Inc.';
    MM_MIRO                       : Result := 'miro Computer Products AG';
    MM_CIRRUSLOGIC                : Result := 'Cirrus Logic';
    MM_ISOLUTION                  : Result := 'ISOLUTION  B.V.';
    MM_HORIZONS                   : Result := 'Horizons Technology, Inc.';
    MM_CONCEPTS                   : Result := 'Computer Concepts Ltd.';
    MM_VTG                        : Result := 'Voice Technologies Group, Inc.';
    MM_RADIUS                     : Result := 'Radius';
    MM_ROCKWELL                   : Result := 'Rockwell International';
    MM_XYZ                        : Result := 'Co. XYZ for testing';
    MM_OPCODE                     : Result := 'Opcode Systems';
    MM_VOXWARE                    : Result := 'Voxware Inc.';
    MM_NORTHERN_TELECOM           : Result := 'Northern Telecom Limited';
    MM_APICOM                     : Result := 'APICOM';
    MM_GRANDE                     : Result := 'Grande Software';
    MM_ADDX                       : Result := 'ADDX';
    MM_WILDCAT                    : Result := 'Wildcat Canyon Software';
    MM_RHETOREX                   : Result := 'Rhetorex Inc.';
    MM_BROOKTREE                  : Result := 'Brooktree Corporation';
    MM_ENSONIQ                    : Result := 'ENSONIQ Corporation';
    MM_FAST                       : Result := 'FAST Multimedia AG';
    MM_NVIDIA                     : Result := 'NVidia Corporation';
    MM_OKSORI                     : Result := 'OKSORI Co., Ltd.';
    MM_DIACOUSTICS                : Result := 'DiAcoustics, Inc.';
    MM_GULBRANSEN                 : Result := 'Gulbransen, Inc.';
    MM_KAY_ELEMETRICS             : Result := 'Kay Elemetrics, Inc.';
    MM_CRYSTAL                    : Result := 'Crystal Semiconductor Corporation';
    MM_SPLASH_STUDIOS             : Result := 'Splash Studios';
    MM_QUARTERDECK                : Result := 'Quarterdeck Corporation';
    MM_TDK                        : Result := 'TDK Corporation';
    MM_DIGITAL_AUDIO_LABS         : Result := 'Digital Audio Labs, Inc.';
    MM_SEERSYS                    : Result := 'Seer Systems, Inc.';
    MM_PICTURETEL                 : Result := 'PictureTel Corporation';
    MM_ATT_MICROELECTRONICS       : Result := 'AT&T Microelectronics';
    MM_OSPREY                     : Result := 'Osprey Technologies, Inc.';
    MM_MEDIATRIX                  : Result := 'Mediatrix Peripherals';
    MM_SOUNDESIGNS                : Result := 'SounDesignS M.C.S. Ltd.';
    MM_ALDIGITAL                  : Result := 'A.L. Digital Ltd.';
    MM_SPECTRUM_SIGNAL_PROCESSING : Result := 'Spectrum Signal Processing, Inc.';
    MM_ECS                        : Result := 'Electronic Courseware Systems, Inc.';
    MM_AMD                        : Result := 'AMD';
    MM_COREDYNAMICS               : Result := 'Core Dynamics';
    MM_CANAM                      : Result := 'CANAM Computers';
    MM_SOFTSOUND                  : Result := 'Softsound, Ltd.';
    MM_NORRIS                     : Result := 'Norris Communications, Inc.';
    MM_DDD                        : Result := 'Danka Data Devices';
    MM_EUPHONICS                  : Result := 'EuPhonics';
    MM_PRECEPT                    : Result := 'Precept Software, Inc.';
    MM_CRYSTAL_NET                : Result := 'Crystal Net Corporation';
    MM_CHROMATIC                  : Result := 'Chromatic Research, Inc.';
    MM_VOICEINFO                  : Result := 'Voice Information Systems, Inc.';
    MM_VIENNASYS                  : Result := 'Vienna Systems';
    MM_CONNECTIX                  : Result := 'Connectix Corporation';
    MM_GADGETLABS                 : Result := 'Gadget Labs LLC';
    MM_FRONTIER                   : Result := 'Frontier Design Group LLC';
    MM_VIONA                      : Result := 'Viona Development GmbH';
    MM_CASIO                      : Result := 'Casio Computer Co., LTD';
    MM_DIAMONDMM                  : Result := 'Diamond Multimedia';
    MM_S3                         : Result := 'S3';
    MM_DVISION                    : Result := 'D-Vision Systems, Inc.';
    MM_NETSCAPE                   : Result := 'Netscape Communications';
    MM_SOUNDSPACE                 : Result := 'Soundspace Audio';
    MM_VANKOEVERING               : Result := 'VanKoevering Company';
    MM_QTEAM                      : Result := 'Q-Team';
    MM_ZEFIRO                     : Result := 'Zefiro Acoustics';
    MM_STUDER                     : Result := 'Studer Professional Audio AG';
    MM_FRAUNHOFER_IIS             : Result := 'Fraunhofer IIS';
    MM_QUICKNET                   : Result := 'Quicknet Technologies';
    MM_ALARIS                     : Result := 'Alaris, Inc.';
    MM_SICRESOURCE                : Result := 'SIC Resource Inc.';
    MM_NEOMAGIC                   : Result := 'NeoMagic Corporation';
    MM_MERGING_TECHNOLOGIES       : Result := 'Merging Technologies S.A.';
    MM_XIRLINK                    : Result := 'Xirlink, Inc.';
    MM_COLORGRAPH                 : Result := 'Colorgraph (UK) Ltd';
    MM_OTI                        : Result := 'Oak Technology, Inc.';
    MM_AUREAL                     : Result := 'Aureal Semiconductor';
    MM_VIVO                       : Result := 'Vivo Software';
    MM_SHARP                      : Result := 'Sharp';
    MM_LUCENT                     : Result := 'Lucent Technologies';
    MM_ATT                        : Result := 'AT&T Labs, Inc.';
    MM_SUNCOM                     : Result := 'Sun Communications, Inc.';
    MM_SORVIS                     : Result := 'Sorenson Vision';
    MM_INVISION                   : Result := 'InVision Interactive';
    MM_BERKOM                     : Result := 'Deutsche Telekom Berkom GmbH';
    MM_MARIAN                     : Result := 'Marian GbR Leipzig';
    MM_DPSINC                     : Result := 'Digital Processing Systems, Inc.';
    MM_BCB                        : Result := 'BCB Holdings Inc.';
    MM_MOTIONPIXELS               : Result := 'Motion Pixels';
    MM_QDESIGN                    : Result := 'QDesign Corporation';
    MM_NMP                        : Result := 'Nokia Mobile Phones';
    MM_DATAFUSION                 : Result := 'DataFusion Systems (Pty) (Ltd)';
    MM_DUCK                       : Result := 'The Duck Corporation';
    MM_FTR                        : Result := 'Future Technology Resources Pty Ltd';
    MM_BERCOS                     : Result := 'BERCOS GmbH';
    MM_ONLIVE                     : Result := 'OnLive! Technologies, Inc.';
    MM_SIEMENS_SBC                : Result := 'Siemens Business Communications Systems';
    MM_TERALOGIC                  : Result := 'TeraLogic, Inc.';
    MM_PHONET                     : Result := 'PhoNet Communications Ltd.';
    MM_WINBOND                    : Result := 'Winbond Electronics Corp';
    MM_VIRTUALMUSIC               : Result := 'Virtual Music, Inc.';
    MM_ENET                       : Result := 'e-Net, Inc.';
    MM_GUILLEMOT                  : Result := 'Guillemot International';
    MM_EMAGIC                     : Result := 'Emagic Soft- und Hardware GmbH';
    MM_MWM                        : Result := 'MWM Acoustics LLC';
    MM_PACIFICRESEARCH            : Result := 'Pacific Research and Engineering Corporation';
    MM_SIPROLAB                   : Result := 'Sipro Lab Telecom Inc.';
    MM_LYNX                       : Result := 'Lynx Studio Technology, Inc.';
    MM_SPECTRUM_PRODUCTIONS       : Result := 'Spectrum Productions';
    MM_DICTAPHONE                 : Result := 'Dictaphone Corporation';
    MM_QUALCOMM                   : Result := 'QUALCOMM, Inc.';
    MM_RZS                        : Result := 'Ring Zero Systems, Inc.';
    MM_AUDIOSCIENCE               : Result := 'AudioScience Inc.';
    MM_PINNACLE                   : Result := 'Pinnacle Systems, Inc.';
    MM_EES                        : Result := 'EES Technik f¹r Musik GmbH';
    MM_HAFTMANN                   : Result := 'haftmann#software';
    MM_LUCID                      : Result := 'Lucid Technology, Symetrix Inc.';
    MM_HEADSPACE                  : Result := 'Headspace, Inc';
    MM_UNISYS                     : Result := 'UNISYS CORPORATION';
    MM_LUMINOSITI                 : Result := 'Luminositi, Inc.';
    MM_ACTIVEVOICE                : Result := 'ACTIVE VOICE CORPORATION';
    MM_DTS                        : Result := 'Digital Theater Systems, Inc.';
    MM_DIGIGRAM                   : Result := 'DIGIGRAM';
    MM_SOFTLAB_NSK                : Result := 'Softlab-Nsk';
    MM_FORTEMEDIA                 : Result := 'ForteMedia, Inc.';
    MM_SONORUS                    : Result := 'Sonorus, Inc.';
    MM_ARRAY                      : Result := 'Array Microsystems, Inc.';
    MM_DATARAN                    : Result := 'Data Translation, Inc.';
    MM_I_LINK                     : Result := 'I-link Worldwide';
    MM_SELSIUS_SYSTEMS            : Result := 'Selsius Systems Inc.';
    MM_ADMOS                      : Result := 'AdMOS Technology, Inc.';
    MM_LEXICON                    : Result := 'Lexicon Inc.';
    MM_SGI                        : Result := 'Silicon Graphics Inc.';
    MM_IPI                        : Result := 'Interactive Product Inc.';
    MM_ICE                        : Result := 'IC Ensemble, Inc.';
    MM_VQST                       : Result := 'ViewQuest Technologies Inc.';
    MM_ETEK                       : Result := 'eTEK Labs Inc.';
    MM_CS                         : Result := 'Consistent Software';
    MM_ALESIS                     : Result := 'Alesis Studio Electronics';
    MM_INTERNET                   : Result := 'INTERNET Corporation';
    MM_SONY                       : Result := 'Sony Corporation';
    MM_HYPERACTIVE                : Result := 'Hyperactive Audio Systems, Inc.';
    MM_UHER_INFORMATIC            : Result := 'UHER informatic GmbH';
    MM_SYDEC_NV                   : Result := 'Sydec NV';
    MM_FLEXION                    : Result := 'Flexion Systems Ltd.';
    MM_VIA                        : Result := 'Via Technologies, Inc.';
    MM_MICRONAS                   : Result := 'Micronas Semiconductors, Inc.';
    MM_ANALOGDEVICES              : Result := 'Analog Devices, Inc.';
    MM_HP                         : Result := 'Hewlett Packard Company';
    MM_MATROX_DIV                 : Result := 'Matrox';
    MM_QUICKAUDIO                 : Result := 'Quick Audio, GbR';
    MM_YOUCOM                     : Result := 'You/Com Audiocommunicatie BV';
    MM_RICHMOND                   : Result := 'Richmond Sound Design Ltd.';
    MM_IODD                       : Result := 'I-O Data Device, Inc.';
    MM_ICCC                       : Result := 'ICCC A/S';
    MM_3COM                       : Result := '3COM Corporation';
    MM_MALDEN                     : Result := 'Malden Electronics Ltd.';
    else 			    Result := 'Unknown manufacturer';

  end;
end;

// -- --
function waveFormat2str(const format: WAVEFORMATEX): aString;
begin
  result := base64encode(@format, sizeof(format) + choice(WAVE_FORMAT_PCM = format.wFormatTag, -2, format.cbSize));
end;

// -- --
function str2waveFormat(const str: aString; var format: WAVEFORMATEX; var size: unsigned): bool;
var
  data: aString;
begin
  data := base64decode(str);
  if (unsigned(length(data)) <= size) then begin
    //
    size := unsigned(length(data));
    if (0 < size) then
      move(data[1], format, size);
    //
    result := true;
  end
  else begin
    //
    size := unsigned(length(data));
    result := false;
  end;
end;

// -- --
function str2waveFormat(const str: aString; var format: pWAVEFORMATEX; var size: unsigned): bool;
var
  fmt: WAVEFORMATEX;
begin
  result := false;
  if ((nil = format) or not str2waveFormat(str, format^, size)) then begin
    //
    if ((nil = format) or ((0 < size) and ($1000 > size)){sanity check}) then begin
      //
      // need to allocate format, or need more space for it
      if (deleteWaveFormat(format)) then begin
	//
	if (1 > size) then
	  // format is not allocated yet, need to know the required size
	  str2waveFormat(str, fmt, size);
	//
	if (0 < size) then begin
	  //
	  format := malloc(size);
	  str2waveFormat(str, format^, size);
	  result := true;
	end;
      end;
    end;
  end;
end;

// -- --
function str2waveFormat(const str: aString; var format: pWAVEFORMATEX): bool; overload;
var
  size: unsigned;
begin
  size := 0;
  result := str2waveFormat(str, format, size);
end;


// -- --
function getFormatDescription(const format: WAVEFORMATEX; driver: HACMDRIVER; defStr: string): string;
var
{$IFNDEF NO_ANSI_SUPPORT }
  detailsA: ACMFORMATDETAILSA;
{$ENDIF NO_ANSI_SUPPORT }
  detailsW: ACMFORMATDETAILSW;
begin
{$IFNDEF NO_ANSI_SUPPORT }
  if (g_wideApiSupported) then begin
{$ENDIF NO_ANSI_SUPPORT }
    //
    fillChar(detailsW, sizeOf(detailsW), 0);
    //
    detailsW.cbStruct := sizeOf(detailsW);
    detailsW.dwFormatTag := format.wFormatTag;
    detailsW.pwfx := @format;
    detailsW.cbwfx := sizeOf(format) + choice(WAVE_FORMAT_PCM = format.wFormatTag, -2, format.cbSize);
    //
    if (MMSYSERR_NOERROR = acm_formatDetailsW(driver, @detailsW, ACM_FORMATDETAILSF_FORMAT)) then
      result := detailsW.szFormat
    else
      result := defStr;
{$IFNDEF NO_ANSI_SUPPORT }
  end
  else begin
    //
    fillChar(detailsA, sizeOf(detailsA), 0);
    //
    detailsA.cbStruct := sizeOf(detailsA);
    detailsA.dwFormatTag := format.wFormatTag;
    detailsA.pwfx := @format;
    detailsA.cbwfx := sizeOf(format) + choice(WAVE_FORMAT_PCM = format.wFormatTag, -2, format.cbSize);
    //
    if (MMSYSERR_NOERROR = acm_formatDetailsA(driver, @detailsA, ACM_FORMATDETAILSF_FORMAT)) then
      result := string(detailsA.szFormat)
    else
      result := defStr;
  end;
{$ENDIF NO_ANSI_SUPPORT }
end;

// -- --
function getAcmVersion(var major, minor: byte; var build: word): bool;
var
  V: unsigned;
begin
  V := acm_getVersion();
  major  := V shr 24;
  minor  := (V shr 16) and $FF;
  build  := (V and $FFFF);
  result := (build = 0);
end;

// -- --
function allocateWaveFormat(out format: pWAVEFORMATEX; driver: HACMOBJ): unsigned;
begin
  result := getMaxWaveFormatSize(driver);
  if (1 > result) then
    result := sizeof(format^);
  //
  format := malloc(result);
  //
  if (result >= sizeOf(format^)) then
    format.cbSize := result - sizeof(format^);
end;

// --  --
function allocateWaveFormat(const srcFormat: WAVEFORMATEX; out format: pWAVEFORMATEX): unsigned;
var
  additionalSize: int;
begin
  additionalSize := choice(WAVE_FORMAT_PCM = srcFormat.wFormatTag, -2, srcFormat.cbSize);
  //
  result := sizeOf(srcFormat) + additionalSize;
  //
  format := malloc(result);
  if (result >= sizeOf(format^)) then
    format.cbSize := additionalSize;
  //
  if (0 < result) then
    move(srcFormat, format^, result);
end;

// -- --
function deleteWaveFormat(format: pWaveFormatEx): bool;
begin
  if (nil <> format) then
    mrealloc(format);
  //  
  result := true;
end;

// -- --
function getMaxWaveFormatSize(driver: HACMOBJ): unsigned;
begin
  if (MMSYSERR_NOERROR <> acm_metrics(driver, ACM_METRIC_MAX_SIZE_FORMAT, result)) then
    result := 0;
end;

// -- --
function getMaxWaveFilterSize(driver: HACMOBJ): unsigned;
begin
  if (MMSYSERR_NOERROR <> acm_metrics(driver, ACM_METRIC_MAX_SIZE_FILTER, result)) then
    result := 0;
end;


end.




