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

	  ogg2wav.dpr
	  Voice Communicator components version 2.5
	  Vorbis/Ogg stream to PCM WAV decoder example

	----------------------------------------------
	  Copyright (c) 2002-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 02 Nov 2002

	  modified by:
		Lake, Nov 2002
		Lake, Jun 2003
		Lake, Oct 2005
		Lake, Mar 2007
                Lake, Jun 2009

	----------------------------------------------
*)

{$APPTYPE CONSOLE }

{$I unaDef.inc}

program
  ogg2wav;

uses
  Windows, unaTypes, unaUtils, unaClasses, unaMsAcmClasses,
{$IFDEF VCX_DEMO }
  SysUtils,	// some functions are not exported from pre-compiled unaUtils.dcu
{$ENDIF VCX_DEMO }
  unaVorbisAPI, unaEncoderAPI;

const
  convsize = 4096;

var
  decoder: unaVorbisDecoder;			// vorbis decoder
  waveWriter: unaRiffStream;			// output riff file
  waveResampler: unaWaveResampler;		// PCM resampler
  ogg: unaOggFile;				// ogg file
  //
  wavFile: string;				// name of target WAV file

// --  --
procedure done();
begin
  infoMessage('* Terminating, please wait..');
  //
  freeAndNil(ogg);
  freeAndNil(decoder);
  freeAndNil(waveWriter);
  infoMessage('Have a nice OS.');
end;

// --  --
function init(): bool;
type
  pCharArray = ^tCharArray;
  tCharArray = array[0.. maxInt div sizeOf(pChar) - 1] of pChar;
var
  config: unaIniFile;
  comments: pCharArray;
  i: int;
begin
  config := unaIniFile.create();
  //
  // check input file
  result := false;
  infoMessage('* Checking input file: ' + paramStr(1) + ', please wait..');
  if (fileExists(paramStr(1))) then begin
    //
    // create ogg reader
    ogg := unaOggFile.create(paramStr(1), -1, GENERIC_READ);
    if (0 <> ogg.errorCode) then begin
      infoMessage('  unable to load required OGG library. Error code: ' + int2str(ogg.errorCode));
      //result := false;
    end
    else begin
      // create decoder as well
      decoder := unaVorbisDecoder.create();
      //
      ogg.sync_init();	// init ogg reader and vorbis decoder
      if (0 = ogg.vorbis_decode_int(decoder)) then begin
	//* Throw the comments plus a few lines about the bitstream we're decoding */
	comments := decoder.vc.user_comments;
	//
	i := 0;
	while (nil <> comments[i]) do begin
	  writeLn('  ', comments[i]);
	  inc(i);
	end;
	//
	writeLn('  bitstream is ', decoder.vi.channels, ' channel, ', decoder.vi.rate, ' Hz');
	writeLn('  encoded by: ', decoder.vc.vendor, #13#10);
	result := true;
      end
      else begin
	infoMessage('  file does not appear to be a valid OGG file.');
	//result := false;
      end;
    end;
  end
  else
    infoMessage('  file cannot be opened, terminating..');
  //
  if (result) then begin
    // check output file
    if (1 < paramCount) then
      wavFile := paramStr(2)
    else
      wavFile := changeFileExt(paramStr(1), '.wav');
    //
    infoMessage('* Checking output file [' + wavFile + '] ..');
    //
    if (fileExists(wavFile)) then begin
      infoMessage('  file already exists, terminating.');
      result := false;
    end;
    //
    if (result) then begin
      // create resampler
      waveResampler := unaWaveResampler.create(false);
      // do not care about input/output stream overloading
      waveResampler.overNumIn := 0;
      waveResampler.overNumOut := 0;

      // assign input PCM params
      waveResampler.setSampling(true, decoder.vi.rate, 16, decoder.vi.channels);

      // assign output PCM params
      waveResampler.setSampling(false,
	config.get('target.pcm.sps', unsigned(44100)),
	config.get('target.pcm.bits', unsigned(16)),
	config.get('target.pcm.channels', unsigned(2)));
      //
      infoMessage('  target sampling rate: ' + int2str(waveResampler.dstFormatExt.Format.nSamplesPerSec));
      infoMessage('  target # of channels: ' + int2str(waveResampler.dstFormatExt.Format.nChannels));
      infoMessage('  target # of bits: ' + int2str(waveResampler.dstFormatExt.Format.wBitsPerSample));

      // create WAV file
      result := false;
      waveWriter := unaRiffStream.createNewExt(wavFile, waveResampler.dstFormatExt);
      //
      case (waveWriter.status) of
	4: infoMessage('  cannot locate codec format (not supported yet)');
	3: infoMessage('  cannot locate codec (not supported yet)');
	2: infoMessage('  cannot create output stream');
	1: begin
	  infoMessage('  file has been successfully initialized.');
	  result := true;
	end
	else
	  infoMessage('  unknown error when creating output WAV file.');
      end;

      //
      if (result) then
	// link resampler to WAVe writer
	waveResampler.addConsumer(waveWriter);
    end;
  end;

  if (result) then begin
    // check decoder
    if (0 = decoder.errorCode) then begin
    end
    else begin
      infoMessage('* Decoder initialization error: ' + int2str(decoder.errorCode));
      result := false;
    end;
  end;
end;

// --  --
procedure run();
var
  mark: uint64;
  h, m, s, ms: unsigned;
  eos, res: int;
  og: tOgg_page;
  op: tOgg_packet;
  clipping: bool;
  subBuf: array[word] of byte;
  readSize: unsigned;
begin
  infoMessage('* Starting conversion..'#13#10);
  //
  // 1. open devices
  waveWriter.open();
  waveResampler.open();
  //
  mark := timeMarkU();
  //
  // 2. read and decode source ogg, feeding the resampler
  decoder.priority := THREAD_PRIORITY_HIGHEST;
  //
  eos := 0;
  decoder.decode_initBuffer(convsize);
  //
  //* The rest is just a straight decode loop until end of stream */
  while (0 = eos) do begin
    //
    while (0 = eos) do begin
      //
      res := ogg.sync_pageout(og);
      if (0 = res) then
	break; //* need more data */

      if (0 > res) then //* missing or corrupt data at this page position */
	infoMessage('  corrupt or missing data in bitstream; continuing...')
      else begin
	ogg.stream_pagein(og); //* can safely ignore errors at this point */

	while (true) do begin
	  //
	  res := ogg.stream_packetout(op);
	  if (0 = res) then
	    break; //* need more data */
	  //
	  if (0 > res) then //* missing or corrupt data at this page position */
	    //* no reason to complain; already complained above */
	  else begin
	    //* we have a packet. decode it */
	    res := decoder.decode_packet(op, clipping);
	    //
	    if (0 < res) then begin
	      repeat
		readSize := decoder.read(@subBuf, sizeOf(subBuf));
		//
		if (0 < readSize) then
		  waveResampler.write(@subBuf, readSize)
		else
		  break;
	      until (false);
	    end;

	  end;
	end;
	//
	if (0 <> ogg_page_eos(og)) then
	  eos := 1;
      end;
    end;
    //
    if (0 = eos) then begin
      write('  [ ] decoding vorbis stream, page #' + int2str(ogg.os.pageno) + '     '#13);
      if (0 = ogg.sync_blockRead(convsize)) then
	eos := 1;
    end;
  end;
  infoMessage('  [x] decoding vorbis stream, page #' + int2str(ogg.os.pageno) + '      '#13);
  //
  // 3. wait for resample to finish
  while (waveResampler.chunkSize < waveResampler.getDataAvailable(true)) do
    Windows.Sleep(500);
  //
  // --  --
  waveResampler.flushBeforeClose := True;	// flush any awaiting data
  waveResampler.close();
  waveWriter.flushBeforeClose := True;
  waveWriter.close();

  // calculate the time used
  mark := timeElapsed64U(mark);
  h := mark div (3600000);
  m := mark div (60000) - h * 60;
  s := mark div (1000) - m * 60 - h * 60 * 60;
  ms := mark mod (1000);
  infoMessage(#13#10#13#10'* Conversion is done, ' + adjust(int2str(h), 2, '0') + ':' + adjust(int2str(m), 2, '0') + ':' + adjust(int2str(s), 2, '0') + '.' + adjust(int2str(ms), 3, '0') + ' elapsed.');
end;


// -- main --

begin
  infoMessage('ogg2wav,  version 2.5.4  Copyright (c) 2002-2009 Lake of Soft');
  infoMessage('VC Components version 2.5            http://lakeofsoft.com/vc'#13#10);
  //
  if (1 > paramCount) then
    infoMessage('  syntax: ogg2wav [ogg_file [wav_file]]'#13#10#13#10 +
		'Check the ogg2wav.ini file for decoder options.')
  else begin
    if (init()) then
      try
	run();
      finally
	done();
      end;
  end;
end.

