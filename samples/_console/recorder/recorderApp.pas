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

	  recorderApp.pas
	  Voice Communicator components version 2.5
	  Audio Tools - simple wave recorder application class

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

{$I unaDef.inc }

unit
  recorderApp;

interface

uses
  Windows, MMSystem,
  unaTypes, unaUtils, unaClasses, unavcApp,
  unaMsAcmClasses;

type
  unaRecorderApp = class (unaVCApplication)
  private
    f_total: int64;
  protected
    function init(): bool; override;
    procedure feedback(); override;
    function stop(): bool; override;
  public
  end;


implementation


{ unaRecorderApp }

// --  --
procedure unaRecorderApp.feedback();
var
  str: string;
begin
  inherited;
  //
  str := 'Recorder so far: ' + int2Str(device.outBytes, 10, 3) + #13;
{$IFDEF CONSOLE }
  write(str);
{$ELSE }
  infoMessage(str);
{$ENDIF CONSOLE }
end;

// --  --
function unaRecorderApp.init(): bool;
var
  out_file: string;
  append: bool;
begin
  result := inherited init();
  //
  if (result) then begin
    //
    ini.section := 'data';
    out_file := ini.get('out_file', 'rec_buf.dat');
    append := ini.get('append', true);
    //
    if ((1 > ParamCount()) or hasSwitch('h')) then
      infoMessage('Usage: [out_file] [rate [bits [nChannels]]] [/choose] [/h]'#13#10)
    else begin
      out_file := ParamStr(1);
      if (1 < ParamCount) then
	rate := str2IntUnsigned(ParamStr(2), 44100);
      if (2 < ParamCount) then
	bits := str2IntUnsigned(ParamStr(3), 16);
      if (3 < ParamCount) then
	nChannels := str2IntUnsigned(ParamStr(4), 2);
    end;
    //
    device := unaWaveInDevice.create(deviceId);
    assignFormat();
    if (not mmNoError(device.open())) then
      unaWaveDevice(device).direct := false
    else
      device.close();
    //
    // assign output stream
    with (unaFileStream(device.assignStream(unaFileStream, false))) do begin
      //
      initStream(out_file, GENERIC_WRITE);
      if (append) then
	seek(0, false)
      else
	clear();
      //
    end;
    //
    assignVolumeParams();
    //
    infoMessage('--------------------------');
    infoMessage('Input device     : ' + unaWaveInDevice(device).getInCaps().szPname + choice(unaWaveDevice(device).direct, ' [direct]', ''));
    infoMessage(' ');
{$IFDEF CONSOLE }
    infoMessage('Sampling rate       : ' + int2Str(rate));
    infoMessage('Bits per sample     : ' + int2Str(bits));
    infoMessage('Number of channels  : ' + int2Str(nChannels));
    assert(debugMessage('Chunk size          : ' + int2Str(device.chunkSize)));
    infoMessage(' ');
{$ENDIF CONSOLE }
    //
    infoMessage('Silence detection level : ' + choice(0 < unaWaveInDevice(device).minVolumeLevel, int2Str(unaWaveInDevice(device).minVolumeLevel), 'disabled'));
    infoMessage('Output file name : ' + out_file);
    infoMessage('Create new file  : ' + choice(not append, 'Yes', 'No'));
    infoMessage('--------------------------'#13#10);
    //
{$IFNDEF CONSOLE }
    if (0 < ParamCount) then
      doStart();
{$ENDIF CONSOLE }
    //
  end;
end;

// --  --
function unaRecorderApp.stop(): bool;
begin
  result := inherited stop();
  if (result) then begin
    //
    inc(f_total, device.outBytes);
    infoMessage('Total bytes recorded: ' + int2Str(f_total, 10, 3));
  end;
end;


end.

