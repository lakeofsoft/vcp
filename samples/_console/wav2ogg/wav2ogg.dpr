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

	  wav2ogg.dpr
	  Voice Communicator components version 2.5
	  WAV to Vorbis/Ogg stream encoder example

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
		Lake, Jul 2008
		Lake, Jun 2009
		Lake, Dec 2010

	----------------------------------------------
*)

{$APPTYPE CONSOLE }
{$DEFINE CONSOLE }

{$I unaDef.inc}
{$I unaVorbisDef.inc }

{$IFDEF VC_LIBVORBIS_ONLY }
  This code requires full Vorbis API.
  Open the unaVorbisDef.inc file and make sure VC_OLD_VORBIS_API is defined.
{$ENDIF VC_LIBVORBIS_ONLY }

program
  wav2ogg;

uses
  Windows, unaTypes, unaUtils, unaClasses,
{$IFDEF VCX_DEMO }
  SysUtils,
{$ENDIF VCX_DEMO }
  unaMsAcmClasses, unaVorbisAPI, unaEncoderAPI;

var
  acm: unaMsAcm;				// acm manager for WAVe reader
  encoder: unaVorbisEnc;			// vorbis encoder
  waveReader: unaRiffStream;			// input riff file
  waveResampler: unaWaveResampler;		// resampler
  ogg: unaOggFile;				// ogg file

  oggFile: string;				// name of target OGG file
  feedBuffer: array[0..$1FFFF] of byte;		// lower size will give better end-user output, but reduce the performance

// --  --
procedure done();
begin
  infoMessage('* Terminating, please wait..');
  //
  freeAndNil(ogg);
  freeAndNil(encoder);
  freeAndNil(waveReader);
  freeAndNil(waveResampler);
  freeAndNil(acm);
  infoMessage('Have a nice OS.');
end;

// --  --
function init(): bool;
var
  config: unaIniFile;
  encodeQuality: unsigned;	// 0..19 -> -0.999 .. 1.0
  vorbisConfig: tVorbisSetup;
  inFile: string;
begin
  acm := unaMsAcm.create();
  acm.enumDrivers();
  //
  config := unaIniFile.create();
  //
  // check input file
  result := false;
  //
  if (aChar(paramStr(1)[1]) in ['/', '\']) then begin
    //
    if (1 < paramCount) then
      inFile := paramStr(2)
    else
      inFile := '';	// no input file specified
  end
  else
    inFile := paramStr(1);
  //
  infoMessage('* Checking input file: [' + inFile + '], please wait..');
  //
  if (fileExists(inFile)) then begin
    //
    waveReader := unaRiffStream.create(inFile, false, false, acm);
    case (waveReader.status) of

      0: begin
	//
	infoMessage('  WAV file correct, stream format is ' + waveFormatExt2str(waveReader.srcFormatExt));
	result := true;
      end;

      -1: infoMessage('  file is not a valid RIF file.');
      -2: infoMessage('  file is valid RIF file, but is not a valid WAVe file.');
      -3: infoMessage('  no Acm was specified (but it is required for conversion).');
      -4: infoMessage('  unknown driver for WAVe file (cannot locate MS ACM driver).');
      -5: infoMessage('  unknown WAVe format (for selected MS ACM driver).');

      else
	  infoMessage('  unknown error when reading input file.');

    end;
    //
    if (result) then begin
      //
      // create resampler device
      waveResampler := unaWaveResampler.create(false);
      // link wave to resampler
      waveReader.addConsumer(waveResampler);
      // do not care about input/output stream overloading
      waveResampler.overNumIn := 0;
      waveResampler.overNumOut := 0;
      // assign sampling params
      waveResampler.setSamplingExt(true, waveReader.dstFormatExt);
      waveResampler.setSampling(false,
	config.get('target.pcm.sps', unsigned(44100)),
	16,	// mp3 always has 16 bits
	config.get('target.pcm.numChannels', unsigned(2)));
      //
      infoMessage('  file has been successfully opened.');
    end;
  end
  else
    infoMessage('  file cannot be opened, terminating..');
  //
  if (result) then begin
    //
    // check output file
    if (1 < paramCount) then begin
      //
      if (aChar(paramStr(2)[1]) in ['/', '\']) then begin
	//
	if (2 < paramCount) then
	  oggFile := paramStr(3)
	else begin
	  //
	  if (aChar(paramStr(1)[1]) in ['/', '\']) then
	    oggFile := ''	// should not be here, looks like /O /O
	  else
	    oggFile := changeFileExt(paramStr(1), '.ogg');
	end;
      end
      else begin
	//
	if (aChar(paramStr(1)[1]) in ['/', '\']) then begin
	  //
	  if (2 < paramCount) then
	    oggFile := paramStr(3)
	  else
	    oggFile := changeFileExt(paramStr(2), '.ogg');
	end
	else
	  oggFile := paramStr(2);
	//
      end;
    end
    else
      oggFile := changeFileExt(paramStr(1), '.ogg');
    //
    if (fileExists(oggFile)) then begin
      //
      if (hasSwitch('O')) then
	infoMessage('* Output file [' + oggFile + '] already exists, it will be overwritten..')
      else begin
	//
	infoMessage('* Output file [' + oggFile + '] already exists, specify /O switch or remove the file. Terminating..');
	result := false;
      end;
    end
    else
      infoMessage('* Output file [' + oggFile + '] has been successfully initialized.');
    //
    if (result) then begin
      // craete Ogg file
      ogg := unaOggFile.create(oggFile, -1, GENERIC_WRITE);
      if (0 <> ogg.errorCode) then begin
	//
	infoMessage('Unable to load required OGG library. Error code: ' + int2str(ogg.errorCode));
	result := false;
      end;
    end;
  end;
  //
  if (result) then begin

    // check encoder
    encoder := unaVorbisEnc.create();
    if (0 = encoder.errorCode) then begin
      // configure encoder
      vorbisConfig.r_min_bitrate := config.get('stream.encode.bitrate.min', -1);
      vorbisConfig.r_normal_bitrate := config.get('stream.encode.bitrate.normal', int(128000));
      vorbisConfig.r_max_bitrate := config.get('stream.encode.bitrate.max', -1);
      //
      case (config.get('stream.encode.method', ord(vemVBR))) of

	ord(vemABR):
	  vorbisConfig.r_encodeMethod := vemABR;

	ord(vemVBR):
	  vorbisConfig.r_encodeMethod := vemVBR;

	else
	  vorbisConfig.r_encodeMethod := vemRateManage;

      end;
      encodeQuality := config.get('stream.encode.vbr.quality', unsigned(5));
      //
      vorbisConfig.r_samplingRate := config.get('target.pcm.sps', unsigned(44100));
      infoMessage(' - sampling rate: ' + int2str(vorbisConfig.r_samplingRate));
      vorbisConfig.r_numOfChannels := config.get('target.pcm.numChannels', unsigned(2));
      infoMessage(' - # of channels: ' + int2str(vorbisConfig.r_numOfChannels));
      //
      case (vorbisConfig.r_encodeMethod) of

	// --  --
	vemABR: begin
	  //
	  infoMessage(' - minimum bitrate: ' + int2str(vorbisConfig.r_min_bitrate));
	  infoMessage(' - normal bitrate: ' + int2str(vorbisConfig.r_normal_bitrate));
	  infoMessage(' - maximum bitrate: ' + int2str(vorbisConfig.r_max_bitrate));
	end;

	// --  --
	vemVBR: begin
	  //
	  vorbisConfig.r_quality := (encodeQuality - 0.999) / 10;	// 0..10
	  infoMessage(' - quality: ' + int2str(encodeQuality) + ' of 10.');
	end;

	// --  --
	vemRateManage: begin
	  vorbisConfig.r_manage_mode := OV_ECTL_RATEMANAGE_AVG;
	  //
	  infoMessage(' - minimum bitrate: ' + int2str(vorbisConfig.r_manage_minBitrate));
	  infoMessage(' - normal bitrate: ' + int2str(vorbisConfig.r_manage_normalBitrate));
	  infoMessage(' - maximum bitrate: ' + int2str(vorbisConfig.r_manage_maxBitrate));
	end;

      end;
      //
      result := false;
      //
      if (0 = encoder.setConfig(@vorbisConfig)) then begin
	//
	if (0 = encoder.open()) then begin
	  //
	  encoder.vorbis_addComment('encoder', 'wav2ogg');
	  encoder.vorbis_addComment('url', 'http://lakeofsoft.com/vc');
	  infoMessage('* Encoder has been initializated successfully.');
	  result := true;
	end
	else
	  infoMessage('* Encoder cannot be opened, error code: 0x' + int2str(encoder.errorCode, 16));
      end
      else
	infoMessage('* Encoder config fails, error code: 0x' + int2str(encoder.errorCode, 16));
      //
    end
    else begin
      infoMessage('* Encoder initialization error: ' + int2str(encoder.errorCode));
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
  hpCount: int = 3;
  finalFlush: bool = false;
  flushSize: unsigned = 0;

// --  --
function flush(): bool;
var
  op: tOgg_packet;
begin
  if (finalFlush or (sizeOf(feedBuffer) < encoder.availableOutputDataSize)) then begin
    //
    while (0 < hpCount) do begin
      //
      if (encoder.popPacket(op)) then begin
	//
	ogg.packetIn(op);
	dec(hpCount);
      end
      else
	break;
      //
      if (1 > hpCount) then begin
	// This ensures the actual audio data will start on a new page, as per spec
	ogg.flush();
      end;
    end;

    //
    if (1 > hpCount) then begin
      //
      if (encoder.popPacket(op)) then begin

	//* weld the packet into the bitstream */
	ogg.packetin(op);
	inc(flushSize, ogg.pageOut());
	//
	if (finalFlush) then
	  result := (flushSize > sizeOf(feedBuffer))
	else
	  result := true;
	//
	if (result) then
	  flushSize := 0;
      end
      else
	result := false;
    end
    else
      result := false;
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
  if (saneBufSize < encoder.availableLazyDataSize) then begin
    // give encoder a chance to make the conversion
    Windows.Sleep(300);
    //
    if (encoder.inputChunkSize > int(encoder.availableLazyDataSize)) then
      // we were sleeping too long - increase the sane buffer size
      inc(saneBufSize, saneBufSizeDelta);
  end;
  //
  size := waveResampler.read(@feedBuffer, sizeOf(feedBuffer));
  if (0 < size) then
    encoder.lazyWrite(@feedBuffer, size)
  else
    // we are reading too fast, let sleep a while
    Windows.Sleep(50);

  //
  result := flush();
end;

// --  --
procedure run();
var
  mark: uint64;
  h, m, s, ms: unsigned;
begin
  infoMessage('* Starting conversion..'#13#10);

  // 1. open devices
  waveResampler.open();
  waveReader.open();
  //
  mark := timeMarkU();
  //
  // 2. read the source wav, feeding the encoder
  encoder.priority := THREAD_PRIORITY_ABOVE_NORMAL;
  write(' [ ] Reading input file: 0% done.           '#13);
  while (not waveReader.streamIsDone) do begin
    //
    if (feed()) then
      write(' [ ] Reading input file: ' + int2str(percent(waveReader.streamPosition, waveReader.streamSize)) + '% done ..   '#13);
  end;
  infoMessage(' [x] Reading input file: 100% done.           '#13);
  waveReader.close();	// free reader resources
  infoMessage('');
  //
  // 3. feed the encoder with resampled data
  waveResampler.priority := THREAD_PRIORITY_ABOVE_NORMAL;
  write(' [ ] Feeding the encoder: ? bytes left.           '#13);
  while ((waveResampler.chunkSize < waveResampler.getDataAvailable(true)) or (0 < waveResampler.getDataAvailable(false))) do begin
    //
    if (feed()) then begin
      //
      write(' [ ] Feeding the encoder: ' + int2str(waveResampler.getDataAvailable(false), 10, 3, '`') + ' bytes left ..     '#13);
      if (waveResampler.isOpen() and (1 > waveResampler.getDataAvailable(false))) then begin
	//
	waveResampler.flush();
	encoder.priority := THREAD_PRIORITY_HIGHEST;	// boost encoder
	waveResampler.close();	// do not need to waste CPU cycles on empty resample thread
      end;
    end;
  end;
  infoMessage(' [x] Feeding the encoder: 0 bytes left.           '#13);
  waveResampler.close();	// free resampler resources
  infoMessage('');
  //
  // 4. wait for encoder to finish
  encoder.priority := THREAD_PRIORITY_HIGHEST;
  write(' [ ] Waiting for encoder to complete: ? bytes left.        '#13);
  //
  try
    while (encoder.inputChunkSize < int(encoder.availableLazyDataSize)) do begin
      //
      write(' [ ] Waiting for encoder to complete: ' + int2str(encoder.availableLazyDataSize, 10, 3, '`') + ' bytes left..      '#13);
      Windows.Sleep(500);
    end;
  except
  end;
  //
  // x. becasue closing Vorbis may sometime genereat FPU exception, we flush the file now
  finalFlush := true;
  while (0 < encoder.availableOutputDataSize) do begin
    //
    if (flush()) then
      ;
    //Windows.Sleep(100);
  end;
  try
    encoder.close();	// will flush the rest of not-encoded yet stream
  except
    // FPU expection from a DLL will not be caught here...
    // at least we flushed as much as we can..
  end;
  infoMessage(' [x] Waiting for encoder to complete: 0 bytes left.        '#13);
  infoMessage('');
  //
  // 5. flush the rest of stream into destination file
  finalFlush := true;
  write(' [ ] Flushing the output file: ? bytes left.            '#13);
  while (0 < encoder.availableOutputDataSize) do begin
    //
    if (flush()) then
      write(' [ ] Flushing the output file: ' + int2str(encoder.availableOutputDataSize, 10, 3, '`') + ' bytes left ..   '#13);
    //Windows.Sleep(100);
  end;
  infoMessage(' [x] Flushing the output file: 0 bytes left.            ');
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
  infoMessage('wav2ogg,  version 2.5.4  Copyright (c) 2002-2009 Lake of Soft');
  infoMessage('VC components version 2.5            http://lakeofsoft.com/vc'#13#10);
  //
  if (1 > paramCount) then
    infoMessage('  syntax: wav2ogg [wav_file [/o] [ogg_file]]'#13#10#13#10 +
		'Check the wav2ogg.ini file for encoder options.')
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

