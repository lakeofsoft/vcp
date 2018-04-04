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

	  riffDump.pas
	  Voice Communicator components version 2.5
	  RIFF dump demo application

	----------------------------------------------
	  Copyright (c) 2002-2011 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 21 Apr 2002

	  modified by:
		Lake, Apr-Nov 2002
		Lake, Jun 2003
		Lake, Oct 2005
                Lake, May-Jun 2009

	----------------------------------------------
*)

{$APPTYPE CONSOLE }
{$DEFINE CONSOLE }

{$I unaDef.inc}

program
  riffDump;

uses
  Windows, unaTypes, MMSystem,
  unaUtils, unaClasses, unaMsAcmAPI, unaRIFF;

// from AviFmt.h

(*
   Main AVI File Header
*)

const

// flags for use in <dwFlags> in AVIFileHdr
  AVIF_HASINDEX        = $00000010;
  AVIF_MUSTUSEINDEX    = $00000020;
  AVIF_ISINTERLEAVED   = $00000100;
  AVIF_TRUSTCKTYPE     = $00000800;
  AVIF_WASCAPTUREFILE  = $00010000;
  AVIF_COPYRIGHTED     = $00020000;

(* The AVI File Header LIST chunk should be padded to this size *)
  AVI_HEADERSIZE       = 2048;                    // size of AVI header list

type
  // avih / size = $38
  PMainAVIHeader = ^MainAVIHeader;
  MainAVIHeader = packed record
    dwMicroSecPerFrame:    DWORD;	// frame display rate (or 0L)
    dwMaxBytesPerSec:      DWORD;	// max. transfer rate
    dwPaddingGranularity:  DWORD;	// pad to multiples of this size; normally 2K.
    dwFlags:		   DWORD;	// the ever-present flags
    dwTotalFrames:	   DWORD;	// # frames in file
    dwInitialFrames:       DWORD;
    dwStreams:             DWORD;
    dwSuggestedBufferSize: DWORD;
    dwWidth:               DWORD;
    dwHeight:              DWORD;
    dwReserved: array[0..3] of DWORD;
  end;

//    #define streamtypeVIDEO FCC('vids')
//    #define streamtypeAUDIO FCC('auds')
//    #define streamtypeMIDI  FCC('mids')
//    #define streamtypeTEXT  FCC('txts')

// for avistreamheader.dwFlags
//    #define AVISF_DISABLED          0x00000001
//    #define AVISF_VIDEO_PALCHANGES  0x00010000

  pavistreamheader = ^avistreamheader;
  avistreamheader = packed record
    fccType: fourCC;      // stream type codes
    fccHandler: fourCC;
    dwFlags: DWORD;
    wPriority: WORD;
    wLanguage: WORD;
    dwInitialFrames: DWORD;
    dwScale: DWORD;
    dwRate: DWORD;  // dwRatedwScale is stream tick rate in ticks/sec
    dwStart: DWORD;
    dwLength: DWORD;
    dwSuggestedBufferSize: DWORD;
    dwQuality: DWORD;
    dwSampleSize: DWORD;
    //struct {
    left: shortInt;
    top: shortInt;
    right: shortInt;
    bottom: shortInt;
    //}   rcFrame;
  end;

  t_timeRec = record
    case integer of
      1: (r_time: unsigned);
      2: (r_ms: byte;
	  r_sec: byte;
	  r_min: word;
	 )
  end;

  pCDDA_header = ^tCDDA_header;
  tCDDA_header = record
    r_formatTag: word;
    r_trackNum: word;
    r_serial: unsigned;
    r_startPos_sec: unsigned;
    r_length_sec: unsigned;
    r_startPos_time: t_timeRec;
    r_length_time: t_timeRec;
  end;


var
  numBytes: unsigned;
  rootSign: aString;
  skipMovi: bool;

// --  --
function int2Hex(value: unsigned; size: unsigned = 8): string;
begin
  result := adjust(int2str(value, 16), size, '0');
end;

function time2str(const time: t_timeRec): string;
begin
  result := adjust(int2str(time.r_min, 10), 3, '0') + ':' +
	    adjust(int2str(time.r_sec, 10), 2, '0') + ':' +
	    adjust(int2str(time.r_ms,  10), 2, '0');
end;

// --  --
function fourCC2str(cc: DWORD): string; overload;
begin
  result := char((cc shr 0) and $FF) + char((cc shr 8) and $FF) + char((cc shr 16) and $FF) + char(cc shr 24) + ' = 0x' + int2str(cc, 16);
end;

// --  --
function fourCC2str(const fcc: fourCC): string; overload;
begin
  result := fourCC2str(pDword(@fcc)^);
end;

var
  g_lastStrhFCC: string;

const
  //
  BI_JPEG	= 4;
  BI_PNG        = 5;

// --  --
function biComp2str(comp: DWORD): string;
begin
  case (comp) of

    BI_RGB:	  result := 'RGB';
    BI_RLE8:	  result := 'RLE8';
    BI_RLE4:	  result := 'RLE4';
    BI_BITFIELDS: result := 'BITFIELDS';
    BI_JPEG:	  result := 'JPEG';
    BI_PNG:       result := 'PNG';
    //
    10..$00FFFFFF: result := '<Unknown: 0x' + int2str(comp, 16) + '>';
    //
    else	  result := fourcc2str(comp);

  end;
end;

// --  --
function getFormatTagDetailsStr(tag: unsigned): string;
var
  waveTagDetails: ACMFORMATTAGDETAILS;
begin
  fillChar(waveTagDetails, sizeOf(waveTagDetails), #0);
  waveTagDetails.cbStruct := sizeOf(waveTagDetails);
  waveTagDetails.dwFormatTag := tag;
  //
  if (WAVE_FORMAT_PCM = waveTagDetails.dwFormatTag) then
    result := ' (PCM)'
  else begin
    //
    if (0 = acm_FormatTagDetails(0, @waveTagDetails, ACM_FORMATTAGDETAILSF_FORMATTAG)) then
      result := ' (' + waveTagDetails.szFormatTag + ')'
    else
      result := ' (Unknown format tag)';
  end;
end;

// --  --
procedure displayChunkHeader(const pad: string; chunk: unaRIFFChunk);
var
  cddaHdr: pCDDA_header;
  waveHdr: PWAVEFORMATEX;
  bmpHdr: PBitmapInfoHeader;
  aviMainHdr: PMainAVIHeader;
  aviStreamHdr: pavistreamheader;
begin
  // WAVE format header
  if (chunk.isID('fmt ') and ($10 <= chunk.header.r_size)) then begin
    //
    if ('CDDA' = rootSign) then begin
      //
      if (nil <> chunk.loadDataBuf(sizeOf(cddaHdr^))) then try
	//
	cddaHdr := pointer(chunk.dataBuf);
	//
	logMessage(pad + '  Format tag    : ' + int2str(cddaHdr.r_formatTag) + getFormatTagDetailsStr(cddaHdr.r_formatTag));
	logMessage(pad + '  Track #       : ' + int2str(cddaHdr.r_trackNum));
	logMessage(pad + '  Serial (?)    : 0x' + int2str(cddaHdr.r_serial, 16));
	logMessage(pad + '  Starting pos  : ' + int2str(cddaHdr.r_startPos_sec));
	logMessage(pad + '  Length        : ' + int2str(cddaHdr.r_length_sec));
	logMessage(pad + '  Starting time : ' + time2Str(cddaHdr.r_startPos_time));
	logMessage(pad + '  Length        : ' + time2Str(cddaHdr.r_length_time));
      finally
	chunk.releaseDataBuf();
      end;
    end
    else
      if ('WAVE' = rootSign) then begin
	//
	if (nil <> chunk.loadDataBuf(sizeOf(waveHdr^))) then try
	  //
	  waveHdr := pointer(chunk.dataBuf);
	  //
	  logMessage(pad + '  Format tag         : ' + int2str(waveHdr.wFormatTag) + getFormatTagDetailsStr(waveHdr.wFormatTag));
	  logMessage(pad + '  Number of channels : ' + int2str(waveHdr.nChannels));
	  logMessage(pad + '  Samples per second : ' + int2str(waveHdr.nSamplesPerSec));
	  logMessage(pad + '  Bits per sample    : ' + int2str(waveHdr.wBitsPerSample));
	  logMessage(pad + '  Av. bytes per sec. : ' + int2str(waveHdr.nAvgBytesPerSec));
	  logMessage(pad + '  Block align        : ' + int2str(waveHdr.nBlockAlign));
	  if ((sizeOf(waveHdr^) <= chunk.header.r_size) and (WAVE_FORMAT_PCM <> waveHdr.wFormatTag)) then
	    logMessage(pad + '  Extra data size    : ' + int2str(waveHdr.cbSize));
          //
	finally
	  chunk.releaseDataBuf();
	end;
      end;
  end;
  //
  // WAVE uncompressed size header
  if (chunk.isID('fact') and (4 <= chunk.header.r_size)) then begin
    //
    if (nil <> chunk.loadDataBuf(sizeOf(unsigned))) then try
      logMessage(pad + '  Uncompressed stream size : 0x' + int2Hex(pUnsigned(chunk.dataBuf)^));
    finally
      chunk.releaseDataBuf();
    end;
  end;
  //
  // AVI main header
  if (chunk.isID('avih') and (sizeOf(aviMainHdr^) <= chunk.header.r_size)) then begin
    //
    if (nil <> chunk.loadDataBuf(sizeOf(aviMainHdr^))) then try
      //
      aviMainHdr := pointer(chunk.dataBuf);
      logMessage(pad + '  Number of microsec. between frames  : ' + int2str(aviMainHdr.dwMicroSecPerFrame));
      logMessage(pad + '  Approximate maximum data rate       : ' + int2str(aviMainHdr.dwMaxBytesPerSec));
      logMessage(pad + '  Pad to multiples of this size       : ' + int2str(aviMainHdr.dwPaddingGranularity));
      logMessage(pad + '  The ever-present flags              : ' + int2Hex(aviMainHdr.dwFlags));
      logMessage(pad + '  Total number of frames of data      : ' + int2str(aviMainHdr.dwTotalFrames));
      logMessage(pad + '  Initial frame for interleaved files : ' + int2str(aviMainHdr.dwInitialFrames));
      logMessage(pad + '  Number of streams in the file       : ' + int2str(aviMainHdr.dwStreams));
      logMessage(pad + '  Suggested buffer size for reading   : ' + int2str(aviMainHdr.dwSuggestedBufferSize));
      logMessage(pad + '  Width of the AVI file in pixels     : ' + int2str(aviMainHdr.dwWidth));
      logMessage(pad + '  Height of the AVI file in pixels    : ' + int2str(aviMainHdr.dwHeight));
    finally
      chunk.releaseDataBuf();
    end;
  end;
  //
  // AVI video stream format?
  if (chunk.isID('strf') and (g_lastStrhFCC = 'vids')) then begin
    //
    // show video format
    if (nil <> chunk.loadDataBuf(sizeOf(bmpHdr^))) then try
      //
      bmpHdr := pointer(chunk.dataBuf);
      if (bmpHdr.biSize >= sizeOf(bmpHdr)) then begin
	//
	logMessage(pad + 'BITMAP HEADER');
	logMessage(pad + '  Width  : ' + int2str(bmpHdr.biWidth));
	logMessage(pad + '  Height : ' + int2str(bmpHdr.biHeight));
	logMessage(pad + '  Bits   : ' + int2str(bmpHdr.biBitCount));
	logMessage(pad + '  Format : ' + biComp2str(bmpHdr.biCompression));
      end;
      //
    finally
      chunk.releaseDataBuf();
    end;
  end;
  //
  // AVI audio stream format?
  if (chunk.isID('strf') and (g_lastStrhFCC = 'auds')) then begin
    //
    // show audio format
    if (nil <> chunk.loadDataBuf(sizeOf(waveHdr^))) then try
      //
      waveHdr := pointer(chunk.dataBuf);
      //
      logMessage(pad + 'WAVE HEADER');
      logMessage(pad + '  Format tag         : ' + int2str(waveHdr.wFormatTag) + getFormatTagDetailsStr(waveHdr.wFormatTag));
      logMessage(pad + '  Number of channels : ' + int2str(waveHdr.nChannels));
      logMessage(pad + '  Samples per second : ' + int2str(waveHdr.nSamplesPerSec));
      logMessage(pad + '  Bits per sample    : ' + int2str(waveHdr.wBitsPerSample));
      logMessage(pad + '  Av. bytes per sec. : ' + int2str(waveHdr.nAvgBytesPerSec));
      logMessage(pad + '  Block align        : ' + int2str(waveHdr.nBlockAlign));
      if ((sizeOf(waveHdr^) <= chunk.header.r_size) and (WAVE_FORMAT_PCM <> waveHdr.wFormatTag)) then
	logMessage(pad + '  Extra data size    : ' + int2str(waveHdr.cbSize));
    finally
      chunk.releaseDataBuf();
    end;
  end;
  //
  // AVI stream header
  g_lastStrhFCC := '';
  if (chunk.isID('strh') and (sizeOf(aviStreamHdr^) <= chunk.header.r_size)) then begin
    //
    if (nil <> chunk.loadDataBuf(sizeOf(aviStreamHdr^))) then try
      //
      aviStreamHdr := pointer(chunk.dataBuf);
      //
      g_lastStrhFCC := string(aviStreamHdr.fccType);
      logMessage(pad + '  Type of the data in the stream : ' + string(aviStreamHdr.fccType));
      logMessage(pad + '  Specific stream data handler   : ' + string(aviStreamHdr.fccHandler) + ' (' + fourCC2str(aviStreamHdr.fccHandler) + ')');
      logMessage(pad + '  Flags for the data stream      : ' + int2hex(aviStreamHdr.dwFlags));
      logMessage(pad + '  Priority of a stream type      : ' + int2str(aviStreamHdr.wPriority));
      logMessage(pad + '  Language of a stream           : ' + int2str(aviStreamHdr.wLanguage));
      logMessage(pad + '  Audio data is skewed ahead by  : ' + int2str(aviStreamHdr.dwInitialFrames));
      logMessage(pad + '  Time scale for this stream     : ' + int2str(aviStreamHdr.dwScale));
      logMessage(pad + '  Stream tick rate in ticks/sec  : ' + int2str(aviStreamHdr.dwRate));
      logMessage(pad + '  Starting time of the AVI file  : ' + int2str(aviStreamHdr.dwStart));
      logMessage(pad + '  Length of this stream (frames) : ' + int2str(aviStreamHdr.dwLength));
      logMessage(pad + '  Suggested buffer size for reading : ' + int2str(aviStreamHdr.dwSuggestedBufferSize));
      logMessage(pad + '  Quality of the data in the stream : ' + choice(unsigned(-1) = aviStreamHdr.dwQuality, 'default', int2str(aviStreamHdr.dwQuality)));
      logMessage(pad + '  Size of a single sample of data   : ' + int2str(aviStreamHdr.dwSampleSize));
      logMessage(pad + '  Destination rectangle for stream  : ' +
	'(Left='  + int2str(aviStreamHdr.left) +  '; Top='    + int2str(aviStreamHdr.top) + ') - ' +
	'(Right=' + int2str(aviStreamHdr.right) + '; Bottom=' + int2str(aviStreamHdr.bottom) + ')');
    finally
      chunk.releaseDataBuf();
    end;
  end;
end;

// --  --
procedure displaySubChunks(chunk: unaRIFFChunk; step: unsigned);
var
  i: unsigned;
  m: unsigned;
  size: unsigned;
  pad: string;
  str: string;
  num: byte;
  b: byte;
  ascii: string;
  ofs: unsigned;
  hideMe: bool;
begin
  if (nil <> chunk) then begin
    //
    pad := padChar(' ', step);
    hideMe := (skipMovi and ( ('00dc' = chunk.header.r_id) or ('01wb' = chunk.header.r_id) ));
    //
    if (not hideMe) then
      logMessage(int2Hex(chunk.offset64) + ': ' + pad + string(chunk.header.r_id) + ' [0x' + int2Hex(chunk.header.r_size, 1) + '/0x' + int2Hex(chunk.maxSize64 - 8, 1) + '] ' + choice(chunk.isContainer, string(chunk.header.r_type), ''));
    //
    if (chunk.isContainer) then begin
      //
      i := 0;
      size := 0;
      //
      if (0 = step) then begin
	//
	setLength(rootSign, 4);
	chunk.readBuf(0, @rootSign[1], 4);
      end;
      //
      while (i < chunk.getSubChunkCount) do begin
	//
	displaySubChunks(chunk[i], step + 2);
	inc(size, chunk[i].header.r_size);
	inc(i);
      end;
      logMessage(int2Hex(chunk.offset64 + chunk.header.r_size) + ': ' + pad + string(chunk.header.r_id) + ' total size: 0x' + int2Hex(size));
      //
    end
    else begin
      // display know file headers
      displayChunkHeader(pad, chunk);
      //
      ofs := 0;
      m := min(numBytes, chunk.header.r_size);
      if (0 < m) then begin
	//
	i := 0;
	str := '  ' + int2Hex(chunk.offset64 + 8) + '/' + int2Hex(ofs) + ': ';
	ascii := '';
	num := 0;
	//
	if (nil <> chunk.loadDataBuf(m)) then try
	  //
	  while (i < m) do begin
	    //
	    b := byte(chunk.dataBuf[i]);
	    str := str + int2Hex(b, 2) + ' ';
	    ascii := ascii + choice((b < 32) or (b > 127), '.', char(b));
	    inc(i);
	    inc(num);
	    if (8 = num) then
	      str := str + '| ';
	    //
	    if (15 < num) then begin
	      //
	      str := str + '   ' + ascii;
	      if (i < m) then
		str := str + #13#10 + '  ' + int2Hex(chunk.offset64 + 8 + i) + '/' + int2Hex(ofs + i) + ': ';
	      //
	      ascii := '';
	      num := 0;
	    end;
	  end;
	finally
	  chunk.releaseDataBuf();
	end;
	//
	if (0 <> num) then
	  str := str + padChar(' ', unsigned(16 - num) * 3 + choice(8 > num, unsigned(2), 0)) + '   ' + ascii;
	//
	logMessage(str);
      end;
    end; // if (isContainer) ...
    //
  end;
end;

// -- main --

var
  riff: unaRIFile;
  nameW: wideString;
begin
  logMessage('RIFF dump, version 2.5.4  Copyright (c) 2002-2011 Lake of Soft');
  //
  if (0 < paramCount) then begin
    // file name
    nameW := paramStrW(1);
    logMessage(' ');
    //
    numBytes := switchValue('D', false, 0);
    skipMovi := hasSwitch('skipmovi');
    //  
    logMessage('Number of bytes to dump: ' + int2str(numBytes));
    //
    // create unaRIFile
    logMessage('Parsing [' + string(wide2ansi(nameW, CP_OEMCP)) + '], please wait..'#13#10);
    //
    if (fileExists(nameW)) then begin
      //
      riff := unaRIFile.create(nameW);
      try
	// display riff chunks
	if (riff.isValid) then begin
	  //
	  logMessage('<begin>'#13#10);
	  displaySubChunks(riff.rootChunk, 0);
	  logMessage(#13#10'<end>');
	end
	else
	  logMessage('Input file does not appear to be a valid RIFF file.');
	//
	// release file
      finally
	freeAndNil(riff);
      end;
    end
    else
      logMessage('Unable to open input file.');
    //
  end
  else begin
    //
    logMessage(' ');
    logMessage(' syntax: riffDump <riff_file> [/D=NN] [/skipmovi]');
    logMessage(' ');
    logMessage(' riff_file'#9'- input RIFF file');
    logMessage(' /D=NN'#9#9'- dump NN bytes in each chunk (default NN is 0)');
    logMessage(' /skipmovi'#9'- do not show AVI movi chunks');
    logMessage(' ');
  end;
  //
  logMessage(#13#10'RIFF dump normal termination, have a nice DOS.');
end.

