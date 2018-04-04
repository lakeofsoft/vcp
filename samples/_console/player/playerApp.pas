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

	  playerApp.pas
	  Voice Communicator components version 2.5
	  Audio Tools - simple PCM wave player application class

	----------------------------------------------
	  Copyright (c) 2001-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 01 Nov 2001

	  modified by:
		Lake, Jan-Jun 2002
		Lake, Jun 2003
		Lake, Oct 2005
                Lake, Jun 2009

	----------------------------------------------
*)

{$I unaDef.inc}

unit
  playerApp;

interface

uses
  Windows, MMSystem,
  unaTypes, unaUtils, unaClasses, unavcApp,
  unaMsAcmClasses;

type
  unaPlayerApp = class(unaVCApplication)
  private
    f_current: int64;
    f_total: int64;
  protected
    function init(): bool; override;
    procedure feedback(); override;
    function okToUpdate(): bool; override;
    function stop(): bool; override;
  end;

implementation


{ unaPlayerApp }

// --  --
procedure unaPlayerApp.feedBack();
var
  str: string;
begin
  inherited;
  //
  str := 'Played back so far: ' + int2Str(device.inBytes, 10, 3) + #13;
{$IFDEF CONSOLE}
  write(str);
{$ELSE}
  infoMessage(str);
{$ENDIF}
end;

// --  --
function unaPlayerApp.init(): bool;
var
  in_file: string;
begin
  result := inherited init();
  if (result) then begin
    ini.section := 'data';
    in_file := ini.get('in_file', 'rec_buf.dat');

    if ((1 > ParamCount()) or hasSwitch('h')) then
      infoMessage('Usage: [in_file] [rate [bits [nChannels]]] [/choose] [/h]'#13#10)
    else begin
      in_file := ParamStr(1);
      if (1 < ParamCount) then
	rate := str2IntUnsigned(ParamStr(2), 44100);
      if (2 < ParamCount) then
	bits := str2IntUnsigned(ParamStr(3), 16);
      if (3 < ParamCount) then
	nChannels := str2IntUnsigned(ParamStr(4), 2);
    end;

    device := unaWaveOutDevice.create(deviceId);
    assignFormat();
    if (not mmNoError(device.open())) then
      unaWaveDevice(device).direct := false
    else
      device.close();

    // assign input stream
    unaFileStream(device.assignStream(unaFileStream, true)).initStream(in_file, GENERIC_READ);

    infoMessage('--------------------------');
    infoMessage('Output device   : ' + unaWaveOutDevice(device).getOutCaps().szPname + choice(unaWaveDevice(device).direct, ' [direct]', ''));
    infoMessage(' ');
  {$IFDEF CONSOLE}
    infoMessage('Sampling rate       : ' + int2Str(rate));
    infoMessage('Bits per sample     : ' + int2Str(bits));
    infoMessage('Number of channels  : ' + int2Str(nChannels));
    assert(debugMessage('Chunk size          : ' + int2Str(device.chunkSize)));
    infoMessage(' ');
  {$ENDIF}
    infoMessage('Input file name : ' + in_file);
    infoMessage('--------------------------'#13#10);

    result := true;
  {$IFNDEF CONSOLE}
    if (0 < ParamCount) then
      doStart();
  {$ENDIF}
  end;
end;

// --  --
function unaPlayerApp.okToUpdate(): bool;
begin
  result := (f_current <> device.inBytes);
  f_current := device.inBytes
end;

// --  --
function unaPlayerApp.stop(): bool;
begin
  result := inherited stop();
  //
  if (result) then begin
    inc(f_total, device.inBytes);
    infoMessage('Total bytes played back: ' + int2Str(f_total, 10, 3));
  end;
end;


end.

