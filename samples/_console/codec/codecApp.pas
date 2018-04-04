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

	  codecApp.pas
	  Voice Communicator components version 2.5
	  Audio Tools - MS ACM codec application

	----------------------------------------------
	  Copyright (c) 2001-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 01 Nov 2001

	  modified by:
		Lake, Mar-Jun 2002
		Lake, Jun 2003
		Lake, Oct 2005
                Lake, Jun 2009

	----------------------------------------------
*)

{$I unaDef.inc}

unit
  codecApp;

interface

uses
  Windows, MMSystem,
  unaTypes, unaUtils, unaClasses, unavcApp,
  unaMsAcmClasses;

type
  unaCodecApp = class(unaVCApplication)
  private
    f_acm: unaMsAcm;
  protected
    function init(): bool; override;
    procedure feedback(); override;
  public
    destructor Destroy(); override;
  end;

implementation


{ unaCodecApp }

// --  --
destructor unaCodecApp.destroy();
begin
  inherited;
  //
  f_acm.free();
end;

// --  --
procedure unaCodecApp.feedback();
var
  str: string;
begin
  str := 'Codec: [in ' + int2Str(device.inBytes, 10, 3) + ']  [out ' + int2Str(device.outBytes, 10, 3) + ']'#13;
{$IFDEF CONSOLE }
  write(str);
{$ELSE }
  infoMessage(str);
{$ENDIF CONSOLE }
end;

// --  --
function unaCodecApp.init(): bool;
var
  driver: unaMsAcmDriver;
  //
  mid: word;
  pid: word;
  in_tag: unsigned;
  in_index: unsigned;
  in_file: string;
  //
  out_tag: unsigned;
  out_index: unsigned;
  out_file: string;
  //
  back: bool;
  pc: unsigned;
begin
  result := inherited init();
  if (result) then begin
{$IFDEF CONSOLE}
{$ELSE}
    formatLabel.show(SW_HIDE);
    chooseButton.show(SW_HIDE);
{$ENDIF}
    //
    pc := 0;
    back := (hasSwitch('back') or hasSwitch('rev'));
    if (back) then
      infoMessage(' * reverse-encode mode is ON'#13#10);
    if (back) then
      inc(pc);
    //
    if (hasSwitch('enum')) then begin
      //
      infoMessage('Please use the acmEnum application to enum the ACM drivers and formats.'#13#10);
      result := false;
    end
    else begin
      //
      ini.section := 'driver';
      mid := ini.get('mid', unsigned(1));
      pid := ini.get('pid', unsigned(36));
      //
      if (back) then
	ini.section := 'out-format'
      else
	ini.section := 'in-format';
      //
      in_tag := ini.get('tag', choice(back, unsigned(49), 1));
      in_index := ini.get('index', choice(back, unsigned(3), 7));
      //
      if (back) then
	ini.section := 'in-format'
      else
	ini.section := 'out-format';
      //
      out_tag := ini.get('tag', choice(back, unsigned(1), unsigned(49)));
      out_index := ini.get('index', choice(back, unsigned(7), 3));
      //
      ini.section := 'data';
      if (back) then begin
	out_file := ini.get('in_file', 'rec_buf.dat');
	in_file := ini.get('out_file', 'out_buf.dat');
      end
      else begin
	in_file := ini.get('in_file', 'rec_buf.dat');
	out_file := ini.get('out_file', 'out_buf.dat');
      end;
      //
      if (int(pc) < paramCount) then begin
        //
	in_file := paramStr(pc + 1);
	if (1 < paramCount) then
	  out_file := paramStr(pc + 2);
      end
      else
	if (1 > pc) then
	  infoMessage('Syntax: codec [/rev | /back] [in_file [out_file]] [/enum]'#13#10);
      //
      f_acm := unaMsAcm.create();
      f_acm.enumDrivers();
      driver := f_acm.getDriver(mid, pid);
      if (nil <> driver) then begin
        //
	device := unaMsAcmCodec.create(driver, false);
	//
	unaMsAcmCodec(device).setFormatIndex(true, in_tag, in_index);
	unaMsAcmCodec(device).setFormatIndex(false, out_tag, out_index);
	//
	unaFileStream(device.assignStream(unaFileStream, true)).initStream(in_file, GENERIC_READ);
	with (unaFileStream(device.assignStream(unaFileStream, false))) do begin
	  //
	  initStream(out_file, GENERIC_WRITE);
	  clear();
	end;
	//
	infoMessage('----------------------------------------');
	infoMessage('driver     : ' + driver.getDetails().szShortName);
	infoMessage('in-format  : ' + device.srcFormatInfo);
	infoMessage('out-format : ' + device.dstFormatInfo);
	//
	{$IFDEF DEBUG }
	logMessage('chunk size : ' + int2Str(device.chunkSize));
	{$ENDIF DEBUG }
	//
	infoMessage('');
	infoMessage('in_file  : ' + in_file);
	infoMessage('out_file : ' + out_file);
	infoMessage('----------------------------------------'#13#10);
      end
      else begin
        //
	infoMessage('Unable to find the driver for mid=' + int2Str(mid) + ', pid=' + int2Str(pid) + '.');
	result := false;
      end;
    end;
  end;

{$IFNDEF CONSOLE}
  if (result and (0 < ParamCount)) then
    doStart();
{$ENDIF}
end;


end.

