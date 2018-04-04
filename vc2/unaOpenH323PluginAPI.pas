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

	  unaOpenH323PluginAPI.pas
	  Voice Communicator components version 2.5
	  Open H.323 codec plugins API wrappers

	----------------------------------------------
	  Copyright (c) 2005-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 20 Feb 2005

	  modified by:
		Lake, Mar 2005

	----------------------------------------------
*)

{$I unaDef.inc}

{*
  OpenH323 Plugin API wrapper.

  @Author Lake

	Version 2.5.2008.07 Still here
}

unit
  unaOpenH323PluginAPI;

interface

uses
  Windows, unaTypes;

const
  //
  PWLIB_PLUGIN_API_VERSION 		= 0;
  PLUGIN_CODEC_VERSION		 	= 1;

  //
  pluginCodec_Licence_None                           = 0;
  pluginCodec_License_GPL                            = 1;
  pluginCodec_License_MPL                            = 2;
  pluginCodec_License_Freeware                       = 3;
  pluginCodec_License_ResearchAndDevelopmentUseOnly  = 4;
  pluginCodec_License_BSD                            = 5;
  //
  pluginCodec_License_NoRoyalties                    = $7f;
  //
  // any license codes above here require royalty payments
  pluginCodec_License_RoyaltiesRequired              = $80;


type
  ppluginCodec_information = ^pluginCodec_information;
  pluginCodec_information = packed record
    //
    // start of version 1 fields
    timestamp: int32;                // codec creation time and date - obtain with command: date -u "+%c = %s"
    //
    sourceAuthor: paChar;            // source code author
    sourceVersion: paChar;           // source code version
    sourceEmail: paChar;             // source code email contact information
    sourceURL: paChar;               // source code web site
    sourceCopyright: paChar;         // source code copyright
    sourceLicense: paChar;           // source code license
    sourceLicenseCode: uint32;	     // source code license
    //
    codecDescription: paChar;        // codec description
    codecAuthor: paChar;             // codec author
    codecVersion: paChar;            // codec version
    codecEmail: paChar;              // codec email contact information
    codecURL: paChar;                // codec web site
    codecCopyright: paChar;          // codec copyright information
    codecLicense: paChar;            // codec license
    codecLicenseCode: uint32;        // codec license code
    // end of version 1 fields
  end;

const
  //
  pluginCodec_MediaTypeMask          = $000f;
  pluginCodec_MediaTypeAudio         = $0000;
  pluginCodec_MediaTypeVideo         = $0001;
  pluginCodec_MediaTypeAudioStreamed = $0002;
  //
  pluginCodec_InputTypeMask          = $0010;
  pluginCodec_InputTypeRaw           = $0000;
  pluginCodec_InputTypeRTP           = $0010;
  //
  pluginCodec_OutputTypeMask         = $0020;
  pluginCodec_OutputTypeRaw          = $0000;
  pluginCodec_OutputTypeRTP          = $0020;
  //
  pluginCodec_RTPTypeMask            = $0040;
  pluginCodec_RTPTypeDynamic         = $0000;
  pluginCodec_RTPTypeExplicit        = $0040;
  //
  pluginCodec_BitsPerSamplePos       = 12;
  pluginCodec_BitsPerSampleMask      = $f000;


type

  // declare ahead
  ppluginCodec_definition = ^pluginCodec_Definition;

  // control def function
  proc_codecControl = function(codec: ppluginCodec_definition; context: pointer; name: paChar; parm: pointer; var parmLen: uint32): int32; cdecl;

  //
  ppluginCodec_controlDefn = ^pluginCodec_ControlDefn;
  pluginCodec_controlDefn = packed record
    //
    name: paChar;
    control: proc_codecControl;
  end;


  //
  proc_createCodec = function(codec: ppluginCodec_definition): pointer; cdecl;
  //
  proc_destroyCodec = procedure(codec: ppluginCodec_definition; context: pointer); cdecl;
  //
  proc_codecFunction = function(codec: ppluginCodec_definition; context: pointer; from: pointer; var fromLen: uint32; _to: pointer; var toLen: uint32; var flag: uint32): int32; cdecl;

  //
  pluginCodec_Definition = packed record
    //
    version: uint32;			// codec structure version
    //
    // start of version 1 fields
    info: ppluginCodec_information;	// license information
    //
    flags: uint32;                      // b0-3: 0 = audio,       1 = video
					// b4:   0 = raw input,   1 = RTP input
					// b5:   0 = raw output,  1 = RTP output
					// b6:   0 = dynamic RTP, 1 = explicit RTP
    //
    descr: paChar;    		        // text decription
    //
    sourceFormat: paChar;               	// source format
    destFormat: paChar;                 	// destination format
    //
    userData: pointer;                  // user data value
    //
    sampleRate: uint32;                 // samples per second
    bitsPerSec: uint32;     		// raw bits per second
    nsPerFrame: uint32;                 // nanoseconds per frame
    samplesPerFrame: uint32;	        // samples per frame
    bytesPerFrame: uint32;              // max bytes per frame
    recommendedFramesPerPacket: uint32;	// recommended number of frames per packet
    maxFramesPerPacket: uint32;         // maximum number of frames per packet
    //
    rtpPayload: uint32;    		// IANA RTP payload code (if defined)
    //
    sdpFormat: paChar;                  	// SDP format string (or NULL, if no SDP format)
    //
    createCodec: proc_createCodec;
    destroyCodec: proc_destroyCodec;
    codecFunction: proc_codecFunction;
    //
    codecControls: ppluginCodec_controlDefn;
    //
    // H323 specific fields
    h323CapabilityType: uint32;
    h323CapabilityData: pointer;
    //
    // end of version 1 fields
  end;


  //
  proc_pluginCodec_getCodecFunction = function(var p1: uint32; p2: uint32): ppluginCodec_definition; cdecl;
  proc_pluginCodec_getAPIVersionFunction = function(): unsigned; cdecl;


//////////////////////////////////////////////////
// VC 2.5 specific
//////////////////////////////////////////////////

type
  //
  // -- plugin entry points --
  //
  pplugin_proc = ^plugin_proc;
  plugin_proc = packed record
    //
    r_module: hModule;
    r_moduleRefCount: integer;
    //
    plugin: pluginCodec_definition;
    //
    rproc_getCodecFunction: proc_pluginCodec_getCodecFunction;
    rproc_getAPIVersionFunction: proc_pluginCodec_getAPIVersionFunction;
  end;


{*
  Loads plugin DLL. NOT MT-SAFE!

  @return 0 if successuf, or Windows specific error code.
}
function plugin_loadDLL(var pproc: plugin_proc; const pathAndName: wString): int;

{*
  Unloads plugin DLL. NOT MT-SAFE!

  @return 0 if successuf, or Windows specific error code.
}
function plugin_unloadDLL(var pproc: plugin_proc): int;


implementation


uses
  unaUtils;

// --  --
function plugin_loadDLL(var pproc: plugin_proc; const pathAndName: wString): int;
var
  libFile: wString;
begin
  with pproc do begin
    //
    if (0 = r_module) then begin
      //
      r_module := 1;	// not zero
      //
      libFile := trimS(pathAndName);
      //
{$IFNDEF NO_ANSI_SUPPORT }
      if (g_wideApiSupported) then
{$ENDIF NO_ANSI_SUPPORT }
	result := Windows.LoadLibraryW(pwChar(libFile))
{$IFNDEF NO_ANSI_SUPPORT }
      else
	result := Windows.LoadLibraryA(paChar(aString(libFile)));
{$ENDIF NO_ANSI_SUPPORT }
      ;
      //
      if (0 = result) then begin
	//
	result := GetLastError();
	r_module := 0;
      end
      else begin
	//
	r_module := result;
	//
	@rproc_getCodecFunction := GetProcAddress(r_module, 'OpalCodecPlugin_GetCodecs');
	@rproc_getAPIVersionFunction := GetProcAddress(r_module, 'PWLibPlugin_GetAPIVersion');
	//
	r_moduleRefCount := 1;	// also, makes it not zero
	//
	if (not assigned(rproc_getCodecFunction) or
	    not assigned(rproc_getAPIVersionFunction)
	   ) then begin
	  //
	  // something is missing, close the library
	  FreeLibrary(r_module);
	  r_module := 0;
	  result := -1;
	end
	else
	  result := 0;
      end;
    end
    else begin
      //
      if (0 < r_moduleRefCount) then
	inc(r_moduleRefCount);
      //
      result := 0;
    end;
  end;
end;

// --  --
function plugin_unloadDLL(var pproc: plugin_proc): int;
begin
  with pproc do begin
    //
    if (1 = r_moduleRefCount) then begin
      //
      rproc_getCodecFunction := nil;
      rproc_getAPIVersionFunction := nil;
      //
      FreeLibrary(r_module);
      //
      r_module := 0;
      r_moduleRefCount := 0;
    end
    else
      if (1 < r_moduleRefCount) then
        dec(r_moduleRefCount);
    //
    result := 0;  
  end;
end;


end.

