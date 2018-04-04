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

	  wav2mp3.dpr
	  Voice Communicator components version 2.5
	  WAV to MP3 stream encoder example

	----------------------------------------------
	  Copyright (c) 2002-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 24 Oct 2002

	  modified by:
		Lake, Oct 2002
		Lake, Nov 2002
		Lake, Jun 2003
		Lake, Oct 2005
		Lake, Jul 2008
                Lake, Jun 2009

	----------------------------------------------
*)

{$APPTYPE CONSOLE }
{$DEFINE CONSOLE  }

{$I unaDef.inc}

program
  wav2mp3;

uses
  Windows, unaTypes, unaUtils, unaClasses,
  unaMsAcmClasses, unaBladeEncAPI, unaEncoderAPI;


// -- globals --

var
  encoder: unaAbstractEncoder;			// encoder module
  acm: unaMsAcm;				// acm manager for WAVe reader
  waveReader: unaRiffStream;			// WAVe reader
  waveResampler: unaWaveResampler;		// resampler
  mp3File: wideString;				// name of target MP3 file
  feedBuffer: array[0..$1FFFF] of byte;		// lower size will give better end-user output, but reduce the performance

// --  --
procedure done();
begin
  infoMessage('* Terminating, please wait..');
  freeAndNil(encoder);
  freeAndNil(waveReader);
  freeAndNil(waveResampler);
  freeAndNil(acm);
  infoMessage('Have a nice OS.');
end;

// -- initialization --
function init(): bool;
var
  config: unaIniFile;
  encoderModel: unsigned;
  encoderModule: string;
  // encoder config
  bladeConfig: BE_CONFIG;
  lameConfig: BE_CONFIG_FORMATLAME;
  mp3Config: pointer;
  minBR, maxBR: unsigned;
  samplesRate: unsigned;
  stereoMode: int;
begin
  acm := unaMsAcm.create();
  acm.enumDrivers();
  //
  config := unaIniFile.create();
  //
  // check input file
  result := false;
  infoMessage('* Checking input file: ' + paramStr(1) + ', please wait..');
  if (fileExists(paramStr(1))) then begin
    //
    waveReader := unaRiffStream.create(paramStr(1), false, false, acm);
    case (waveReader.status) of

      0: begin
	 infoMessage('  WAV file correct, stream format is ' + waveFormatExt2str(waveReader.srcFormatExt));
	 result := true;
      end;

      -1: infoMessage('  File is not a valid RIF file.');
      -2: infoMessage('  File is valid RIF file, but is not a valid WAVe file.');
      -3: infoMessage('  No Acm was specified (but it is required for conversion).');
      -4: infoMessage('  Unknown driver for WAVe file (cannot locate MS ACM driver).');
      -5: infoMessage('  Unknown WAVe format (for selected MS ACM driver).');

      else
	  infoMessage('  Unknown error when reading input file.');
    end;
    //
    if (result) then begin
      //
      // create resampler device
      waveResampler := unaWaveResampler.create(false);
      // link wave to resampler
      waveReader.addConsumer(waveResampler);
      // do not care about input/output stream overloading
      with (waveResampler) do begin
	//
	overNumIn := 0;
	overNumOut := 0;
	// assign sampling params
	setSamplingExt(true, waveReader.dstFormatExt);
	setSampling(false,
	  config.get('target.pcm.sps', unsigned(44100)),
	  16,	// mp3 always has 16 bits
	  choice(1 = config.get('target.pcm.stereo', unsigned(1)), unsigned(2), 1));
      end;
      //
      infoMessage('  File has been successfully opened.');
    end;
  end
  else
    infoMessage('  File cannot be opened, terminating..');
  //
  // check output file
  if (result) then begin
    //
    if (1 < paramCount) then
      mp3File := paramStrW(2)
    else
      mp3File := changeFileExt(paramStrW(1), '.mp3');
    //
    if (fileExists(mp3File)) then begin
      //
      infoMessage('* Output file [' + mp3file + '] already exists, terminating..');
      result := false;
    end
    else
      infoMessage('* Output file [' + mp3file + '] has been successfully initialized.');
  end;
  //
  // check encoder
  if (result) then begin
    //
    encoderModel := config.get('encoder.model', unsigned(2));
    encoderModule := config.get('encoder.module', '');
    case (encoderModel) of
      1: begin
	infoMessage('* Using Blade encoder');
	encoder := unaBladeMp3Enc.create(encoderModule);
      end;
      2: begin
	infoMessage('* Using Lame encoder');
	encoder := unaLameMp3Enc.create(encoderModule);
      end
      else
	encoder := nil;
    end;
    //
    if ((nil <> encoder) and (BE_ERR_SUCCESSFUL = encoder.errorCode)) then begin
      // configure encoder
      minBR := config.get('stream.bitrate', unsigned(128));
	infoMessage(' - Stream bitrate: ' + int2str(minBR));
      maxBR := config.get('stream.maxBitrate', unsigned(192));
	infoMessage(' - Stream maximum bitrate: ' + int2str(maxBR));
      samplesRate := config.get('target.pcm.sps', unsigned(44100));
	infoMessage(' - Sampling rate: ' + int2str(samplesRate));
      stereoMode := choice(1 = config.get('target.pcm.stereo', unsigned(1)), unsigned(BE_MP3_MODE_STEREO), BE_MP3_MODE_MONO);
	infoMessage(' - Stereo mode: ' + choice(BE_MP3_MODE_STEREO = stereoMode, 'STEREO', 'MONO'));
      //
      mp3Config := nil;
      case (encoderModel) of

	//
	1: begin	// Blade
	  //
	  fillChar(bladeConfig, sizeOf(bladeConfig), #0);
	  bladeConfig.dwConfig := BE_CONFIG_MP3;
	  with bladeConfig.r_mp3 do begin
	    //
	    dwSampleRate := samplesRate;
	    byMode := stereoMode;
	    wBitrate := minBR;
	    // change as you need
	    bPrivate := false;
	    bCRC :=  false;
	    bCopyright :=  false;
	    bOriginal :=  false;
	  end;
	  mp3Config := @bladeConfig;
	end;

	//
	2: begin	// Lame
	  //
	  fillChar(lameConfig, sizeOf(lameConfig), #0);
	  lameConfig.dwConfig := BE_CONFIG_LAME;
	  with lameConfig.r_lhv1 do begin
	    //
	    dwStructVersion := CURRENT_STRUCT_VERSION;
	    dwStructSize := sizeOf(lameConfig);
	    dwSampleRate := samplesRate;
	    //dwReSampleRate := 0;
	    nMode := stereoMode;
	    dwBitrate := minBR;
	    dwMaxBitrate := maxBR;
	    nPreset := LQP_NOPRESET;
	    dwMpegVersion := MPEG2;
	    //dwPsyModel := 0;
	    //dwEmphasis := 0;
	    // change as you need
	    bPrivate := false;
	    bCRC :=  false;
	    bCopyright := false;
	    bOriginal := false;
	    //
	    bWriteVBRHeader := config.get('stream.vbr.header.write', false);
	      infoMessage(' - Write VBR header: ' + bool2strStr(bWriteVBRHeader));
	    bEnableVBR := config.get('stream.vbr.enabled', false);
	      infoMessage(' - VBR enabled: ' + bool2strStr(bEnableVBR));
	    nVBRQuality := config.get('stream.vbr.quality', unsigned(0));
	      infoMessage(' - VBR quality: ' + int2str(nVBRQuality));
	    //
	    if (bEnableVBR) then
	      // chaneg as required
	      nVbrMethod := VBR_METHOD_NEW
	    else
	      nVbrMethod := VBR_METHOD_NONE;
	    //
	    bNoRes := true;
	    bStrictIso := false;
	  end;
	  mp3Config := @lameConfig;
	end;
      end;

      //
      if (nil <> mp3Config) then begin
	//
	result := false;
	//
	if (BE_ERR_SUCCESSFUL = encoder.setConfig(mp3Config)) then begin
	  //
	  if (BE_ERR_SUCCESSFUL = encoder.open()) then begin
	    infoMessage('* Encoder has been initializated successfully.');
	    result := true;
	  end
	  else
	    infoMessage('* Encoder cannot be opened, error code: 0x' + int2str(encoder.errorCode, 16));
	end
	else
	  infoMessage('* Encoder config fails, error code: 0x' + int2str(encoder.errorCode, 16));
      end;
    end
    else begin
      //
      if (nil = encoder) then
	infoMessage('* No encoder model specified, terminating..')
      else
	infoMessage('* Encoder model #' + int2str(encoderModel) + ' cannot be found.'#13#10'  Please check if required encoder DLL is present on your system.');
      //
      result := false;
    end;
  end;
  //
  if (not result) then
    done();
  //
  freeAndNil(config);
end;

var
  finalFlush: bool = false;

// --  --
function flush(): bool;
var
  size: unsigned;
begin
  if (finalFlush or (sizeOf(feedBuffer) < encoder.availableOutputDataSize)) then begin
    //
    size := encoder.read(@feedBuffer, sizeOf(feedBuffer));
    result := (0 < size);
    if (result) then
      writeToFile(mp3File, @feedBuffer, size);
  end
  else
    result := false;
end;

var
  saneBufSize: unsigned = $100000;	// do not feed the encoder over this size

const
  saneBufSizeDelta = $10000;		// increase delta for saneBufSize

// --  --
function feed(): bool;
var
  size: unsigned;
begin
  result := true;
  //
  if (saneBufSize < encoder.availableLazyDataSize) then begin
    // give encoder a chance to make the conversion
    result := false;
    Sleep(50);
    //
    if (encoder.inputChunkSize > int(encoder.availableLazyDataSize)) then
      // we were sleeping too long - increase the sane buffer size
      inc(saneBufSize, saneBufSizeDelta);
  end;
  //
  size := waveResampler.read(@feedBuffer, sizeOf(feedBuffer));
  //
  //logMessage(#13#10'Got ' + int2str(size) + ' bytes out from resampler ' + int2str(waveResampler.getDataAvailable(true)) + '/' + int2str(waveResampler.getDataAvailable(false)));
  //
  if (0 < size) then
    encoder.lazyWrite(@feedBuffer, size)
  else begin
    // we are reading too fast, let sleep a while
    result := false;
    Sleep(10);
  end;
  //
  result := flush() and result;
end;

// --  --
procedure run();
var
  mark, m2: uint64;
  h, m, s, ms: unsigned;
  f: bool;
begin
  infoMessage('* Starting conversion..'#13#10);
  //
  // 1. open devices
  waveResampler.open();
  waveReader.open();
  //
  mark := timeMarkU();
  m2 := timeMarkU();
  //
  // 2. read the source wav, feeding the encoder
  encoder.priority := THREAD_PRIORITY_ABOVE_NORMAL;
  while (not waveReader.streamIsDone) do begin
    //
    f := feed();
    if ( f or (1000 < timeElapsed64U(m2)) ) then begin
      //
      write(' [ ] Reading input file: ' + int2str(percent(waveReader.streamPosition, waveReader.streamSize)) + '% done ..   '#13);
      m2 := timeMarkU();
    end;
  end;
  infoMessage(' [x] Reading input file: done, ' + int2str(waveReader.outBytes) + ' bytes read.              '#13);
  waveReader.close();	// free reader resources
  //
  // 3. feed the encoder with resampled data
  waveResampler.priority := THREAD_PRIORITY_ABOVE_NORMAL;
  while ((waveResampler.chunkSize < waveResampler.getDataAvailable(true)) or (0 < waveResampler.getDataAvailable(false))) do begin
    //
    f := feed();
    if ( f or (1000 < timeElapsed64U(m2)) ) then begin
      //
      write(' [ ] Feeding the encoder: ' + int2str(waveResampler.getDataAvailable(false), 10, 3) + ' bytes left ..     '#13);
      //
      if (f and waveResampler.isOpen() and (1 > waveResampler.getDataAvailable(false))) then begin
	//
	encoder.priority := THREAD_PRIORITY_HIGHEST;	// boost encoder
	waveResampler.close();	// do not need to waste CPU cycles on empty resample thread
      end;
      //
      m2 := timeMarkU();
    end;
  end;
  //
  waveResampler.close();	// free resampler resources
  infoMessage(' [x] Feeding the encoder: done (' + int2str(waveResampler.getDataAvailable(true)) + '/' + int2str(waveResampler.getDataAvailable(false)) + ').                      ');
  //
  // 4. wait for encoder to finish
  encoder.priority := THREAD_PRIORITY_HIGHEST;
  while (encoder.inputChunkSize < int(encoder.availableLazyDataSize)) do begin
    //
    write(' [ ] Waiting for encoder to complete: ' + int2str(encoder.availableLazyDataSize, 10, 3) + ' bytes left..      '#13);
    Sleep(300);
  end;
  encoder.close();	// will flush the rest of not-encoded yet stream
  infoMessage(' [x] Waiting for encoder to complete: done.                   '#13);
  //
  // 5. flush the rest of stream into destination file
  finalFlush := true;
  while (0 < encoder.availableOutputDataSize) do begin
    //
    if (flush()) then
      write(' [ ] Flushing the output file: ' + int2str(encoder.availableOutputDataSize, 10, 3) + ' bytes left ..   '#13);
    //
    Sleep(50);
  end;
  infoMessage(' [x] Flushing the output file: done.                       '#13);
  //
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
  infoMessage('wav2mp3,  version 2.5.4  Copyright (c) 2002-2009 Lake of Soft');
  infoMessage('VC components version 2.5            http://lakeofsoft.com/vc'#13#10);
  //
  if (paramCount < 1) then begin
    infoMessage('  syntax: wav2mp3 [wav_file [mp3_file]]'#13#10#13#10 +
		'Check the wav2mp3.ini file for encoder options.');
  end
  else begin
    //
    if (init()) then
      try
	run();
      finally
	done();
      end;
  end;
end.

