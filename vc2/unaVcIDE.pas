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

	  unaVCIDE.pas - VC 2.5 Pro components to be used with VCL/IDE
	  Voice Communicator components version 2.5 Pro

	----------------------------------------------
	  Copyright (c) 2002-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 01 Jun 2002

	  modified by:
		Lake, Jun-Dec 2002
		Lake, Jan-Dec 2003
		Lake, Jan-May 2004
		Lake, May-Oct 2005
		Lake, Mar-Dec 2007
                Lake, Jan-Feb 2008

	----------------------------------------------
*)

{$I unaDef.inc }

{$IFDEF DEBUG }
  {$DEFINE LOG_UNAVCIDE_INFOS }	// log informational messages
  {$DEFINE LOG_UNAVCIDE_ERRORS }	// log critical errors
{$ENDIF DEBUG }

{$IFNDEF VC_LIC_PUBLIC }
  {$DEFINE UNAVCIDE_SCRIPT_COMPONENT }	// define to link scriptor component
{$ENDIF VC_LIC_PUBLIC }


{*
  @Author Lake

  Contains components and classes to be used in Delphi/C++Builder IDE.

  Wave components:
  @unorderedList(
    @itemSpacing Compact
    @item @link(unavclWaveInDevice WaveIn)
    @item @link(unavclWaveOutDevice WaveOut)
    @item @link(unavclWaveCodecDevice WaveCodec)
    @item @link(unavclWaveRiff WaveRiff)
    @item @link(unavclWaveMixer WaveMixer)
    @item @link(unavclWaveResampler WaveResampler)
  )

  IP components:
  @unorderedList(
    @itemSpacing Compact
    @item @link(unavclIPClient IPClient)
    @item @link(unavclIPServer IPServer)
    @item @link(unavclIPBroadcastServer IPBroadcastServer)
    @item @link(unavclIPBroadcastClient IPBroadcastClient)
  )

  Scripting:
  @unorderedList(
    @itemSpacing Compact
    @item @link(unavclScriptor Scriptor)
  )

  Version 2.5.2008.03 Split into _pipe, _wave, _socks, _script units
}

unit
  unaVCIDE;

interface

uses
  Windows, unaTypes,
  unaClasses, Classes, 
  unaVC_pipe, unaVC_wave, unaVC_socks
{$IFDEF UNAVCIDE_SCRIPT_COMPONENT }
  , unaVC_script
{$ENDIF UNAVCIDE_SCRIPT_COMPONENT }
  ;


type
  //
  // redifine general pipes here
  unavclInOutPipe = unaVC_pipe.unavclInOutPipe;
  unavclInOutWavePipe = unaVC_wave.unavclInOutWavePipe;
  unavclInOutIpPipe = unaVC_socks.unavclInOutIpPipe;


// --
// wave pipes
// --

  // WaveIn component.
  TunavclWaveInDevice 		= class(unavclWaveInDevice) end;
  // WaveOut component.
  TunavclWaveOutDevice		= class(unavclWaveOutDevice) end;
  // WaveCodec component.
  TunavclWaveCodecDevice	= class(unavclWaveCodecDevice) end;
  // WaveRIFF component.
  TunavclWaveRiff		= class(unavclWaveRiff) end;
  // WaveMixer component.
  TunavclWaveMixer		= class(unavclWaveMixer) end;
  // WaveResampler component.
  TunavclWaveResampler		= class(unavclWaveResampler) end;


// --
// IP pipes
// --

  // IPClient component.
  TunavclIPOutStream		= class(unavclIPClient) end;
  // IPServer component.
  TunavclIPInStream		= class(unavclIPServer) end;
  // BroadcastServer component.
  TunavclIPBroadcastServer	= class(unavclIPBroadcastServer) end;
  // BroadcastClient component.
  TunavclIPBroadcastClient	= class(unavclIPBroadcastClient) end;


{$IFDEF VC_LIC_PUBLIC }
{$ELSE }

// --
// STUN
// --

  // STUN Client component.
  TunavclSTUNClient		= class(unavclSTUNClient) end;
  // STUN Server component.
  TunavclSTUNServer		= class(unavclSTUNServer) end;

// --
// DNS
// --

  // DNS Client component.
  TunavclDNSClient		= class(unavclDNSClient) end;

{$ENDIF VC_LIC_PUBLIC }


{$IFDEF UNAVCIDE_SCRIPT_COMPONENT }

// --
// scripting
// --

  // Scriptor component.
  TunavclScriptor		= class(unavclScriptor) end;

{$ENDIF UNAVCIDE_SCRIPT_COMPONENT }


{*
  Registers VC components in Delphi IDE Tools Palette.
}
procedure Register();


implementation


uses
  unaUtils;

// -- resister pipes in IDE --
//
procedure Register();
begin
  RegisterComponents(c_VC_reg_core_section_name, [
    //
    TunavclWaveInDevice,
    TunavclWaveOutDevice,
    TunavclWaveCodecDevice,
    TunavclWaveRiff,
    TunavclWaveMixer,
    TunavclWaveResampler,
    //
    TunavclIPOutStream,
    TunavclIPInStream,
    TunavclIPBroadcastServer,
    TunavclIPBroadcastClient
    //
{$IFDEF UNAVCIDE_SCRIPT_COMPONENT }
    , TunavclScriptor
{$ENDIF UNAVCIDE_SCRIPT_COMPONENT }
  ]);
  //
  RegisterComponents(c_VC_reg_IP_section_name, [
    //
{$IFDEF VC_LIC_PUBLIC }
{$ELSE }

    //
    TunavclSTUNClient,
    TunavclSTUNServer,
    TunavclDNSClient
{$ENDIF VC_LIC_PUBLIC }

  ]);
end;


initialization

{$IFDEF LOG_UNAVCIDE_INFOS }
  logMessage('unaVCIDE - DEBUG is defined.');
{$ENDIF LOG_UNAVCIDE_INFOS }

end.

