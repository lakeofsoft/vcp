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

	  mixerApp.pas
	  Voice Communicator components version 2.5
	  Audio Tools - software mixer application class

	----------------------------------------------
	  Copyright (c) 2001-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, Sep 2001

	  modified by:
		Lake, Jan-Jun 2002
		Lake, Jun 2003
		Lake, Oct 2005
		Lake, Jun 2009

	----------------------------------------------
*)

{$I unaDef.inc}

unit
  mixerApp;

interface

uses
  Windows, MMSystem,
  unaTypes, unaUtils, unaClasses, unavcApp,
  unaMsAcmClasses;

type
  unaMixerApp = class(unaVCApplication)
  private
    f_max_in_size: unsigned;
    //
    f_in_streams: unaObjectList;
    f_playback: unaWaveOutDevice;
    f_lastDisplay: int64;
  protected
    function init(): bool; override;
    procedure feedback(); override;
    function start(): bool; override;
    function stop(): bool; override;
  public
    destructor Destroy(); override;
  end;


implementation


{ unaMixerApp }

// --  --
destructor unaMixerApp.destroy();
begin
  inherited;
  //
  f_in_streams.free();
  f_playback.free();
end;

// --  --
procedure unaMixerApp.feedback();
begin
  inherited;
  //
  if (f_lastDisplay <> device.outBytes) then begin
{$IFDEF CONSOLE}
    write('Mixed so far: ' + int2Str(device.outBytes, 10, 3) + ' bytes'#13);
{$ELSE}
    infoMessage('Mixed so far: ' + int2Str(device.outBytes, 10, 3) + ' bytes'#13);
{$ENDIF}
    f_lastDisplay := device.outBytes;
  end;
end;

// --  --
function unaMixerApp.init(): bool;
var
  i: int;
  s: int;
  pc: int;
  stream: unaAbstractStream;
  //
  outFile: string;
begin
  result := inherited init();
  //
  if (result) then begin
    f_in_streams := unaObjectList.create();
    f_in_streams.autoFree := false;
    //
    device := unaWaveMixerDevice.create(false, false);
    //
    pc := ParamCount();
    if (hasSwitch('p')) then begin
      f_playback := unaWaveOutDevice.create();
      f_playback.setSampling(rate, bits, nChannels);
      if (not mmNoError(f_playback.open())) then begin
	infoMessage('Unable to initializate output device..');
	f_playback.free();
	f_playback := nil;
      end
      else
        f_playback.close();

      //	
      dec(pc);
    end
    else
      f_playback := nil;

    //
    if ((pc < 2) or hasswitch('?')) then begin
      infoMessage('Usage: [-p] [out_file in_file_1 [in_file_2...]]'#13#10);
      infoMessage('	-p 		forces stream playback right after mixing');
      infoMessage('	out_file	this file will be used to write mixed stream');
      infoMessage('	in_file_x 	any number of input files (input streams)'#13#10);
      //
      infoMessage('WARNING: all input files must have same number of bits per sample'#13#10);

      infoMessage('--------- mixer ------------------'#13#10);

      // add first stream
      stream := unaWaveMixerDevice(device).addStream();
      stream.readFrom('rec_buf1.dat');
      f_in_streams.add(stream);
      infoMessage('input file      : rec_buf1.dat');
      f_max_in_size := stream.getSize();

      // add second stream
      stream := unaWaveMixerDevice(device).addStream();
      stream.readFrom('rec_buf2.dat');
      f_in_streams.add(stream);
      infoMessage('input file      : rec_buf2.dat');
      if (stream.getSize() < int(f_max_in_size)) then
	f_max_in_size := stream.getSize();

      // set output file
      outFile := 'mix_buf.dat';
    end
    else begin
      infoMessage('--------- mixer ------------------'#13#10);

      outFile := '';
      if (nil <> f_playback) then begin
	s := 2;
	if (pc >= 2) then
	  f_max_in_size := high(unsigned);
      end
      else begin
	s := 1;
	if (pc > 1) then
	  f_max_in_size := high(unsigned);
      end;
      for i := s to ParamCount() do
	if (s = i) then
	  outFile := ParamStr(i)
	else begin
	  stream := unaWaveMixerDevice(device).addStream();
	  stream.readFrom(ParamStr(i));
	  f_in_streams.add(stream);
	  infoMessage('input file      : ' + ParamStr(i));
	  if (stream.getSize() < int(f_max_in_size)) then
	    f_max_in_size := stream.getSize();
	end;
    end;

    //
    unaFileStream(device.assignStream(unaFileStream, false)).initStream(outFile, GENERIC_WRITE);

    //
    infoMessage('Max. input size : ' + int2Str(f_max_in_size, 10, 3));
    infoMessage('Output file     : ' + outFile);

    if (nil <> f_playback) then
      infoMessage('Playback status : active')
    else
      infoMessage('Playback status : not used');

    assignFormat();
    infoMessage('Bits per sample : ' + int2Str(bits));
    //
    if (nil <> f_playback) then begin
      f_playback.setSampling(rate, bits, nChannels);
      //
      device.addConsumer(f_playback, false);
      //
      infoMessage(' ');
      infoMessage('Sampling rate      : ' + int2Str(rate));
      infoMessage('Number of channels : ' + int2Str(nChannels));
    end;  

    infoMessage('--------- ----- ------------------'#13#10);

    result := true;
{$IFDEF CONSOLE}
{$ELSE}
    if (0 < ParamCount) then
      doStart();
{$ENDIF}
  end;
end;

// --  --
function unaMixerApp.start(): bool;
begin
  result := inherited start();
  if (result) then
    if (nil <> f_playback) then
      f_playback.open();
end;

// --  --
function unaMixerApp.stop(): bool;
begin
  result := inherited stop();
  if (result) then
    if (nil <> f_playback) then
      f_playback.close();
end;


end.

