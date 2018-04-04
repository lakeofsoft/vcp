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

	  acmEnum.dpr
	  Voice Communicator components version 2.5
	  Audio Tools - simple ACM enumeration application

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

{$DEFINE NO_SU_AUTODEFINE }

{$I unaDef.inc}

{$APPTYPE CONSOLE }

program
  acmEnum;

uses
  Windows, MMSystem,
  unaTypes, unaUtils, unaMsAcmAPI;

// --  --
function htmlFix(const value: string): string;
var
  i, len: int;
begin
  result := '';
  len := length(value);
  i := 1;
  //
  while (i <= len) do begin
    //
    case (value[i]) of

      '&':
	result := result + '&amp;';

      '©':
	result := result + '(c)';

      '®':
	result := result + '(r)';

      #160:
	result := result + ' ';

      else
	result := result + value[i];

    end;
    //
    inc(i);
  end;
end;

// -- --
function WriteWave(const wave: WAVEFORMATEX; size: unsigned; const ident: string = ''): bool;
var
  i: unsigned;
begin
  infoMessage(ident + '<waveformatex tag="' + int2Str(wave.wFormatTag) + '" formatSize="' + int2Str(size) + '">');
  infoMessage(ident + '  <nChannels value="' + int2Str(wave.nChannels) + '" />');
  infoMessage(ident + '  <nSamplesPerSec value="' + int2Str(wave.nSamplesPerSec) + '" />');
  infoMessage(ident + '  <nAvgBytesPerSec value="' + int2Str(wave.nAvgBytesPerSec) + '" />');
  infoMessage(ident + '  <nBlockAlign value="' + int2Str(wave.nBlockAlign) + '" />');
  infoMessage(ident + '  <wBitsPerSample value="' + int2Str(wave.wBitsPerSample) + '" />');
  //
  if (size >= sizeOf(WAVEFORMATEX)) then begin
    infoMessage(ident + '  <cbSize value="' + int2Str(wave.cbSize) + '" />');
    if (wave.cbSize > 0) then begin
      infoMessage(ident + '  <wave_data>');
      i := 0;
      while (i < wave.cbSize) do begin
	infoMessage(adjust(int2Str(byte(pchar(@wave.cbSize)[sizeof(wave.cbSize) + i]), 16), 2, '0') + ' ');
	inc(i);
      end;
      infoMessage('</wave_data>');
    end;
  end;
  //
  infoMessage(ident + '</waveformatex>');
  result := true;
end;

// -- --
function myFilterTagEnumCB(hadid: HACMDRIVERID; paftd: pACMFILTERTAGDETAILSA; dwInstance: DWORD; fdwSupport: DWORD): Windows.BOOL; stdcall;
begin
  infoMessage('        <filter tag="' + int2Str(paftd.dwFilterTag) + '"' +
			' info="' + htmlFix(string(paftd.szFilterTag)) + '" />');
  result := true;
end;

// -- --
function myFormatEnumCB(hadid: HACMDRIVERID; const pafd: ACMFORMATDETAILSA; dwInstance: DWORD; fdwSupport: DWORD): Windows.BOOL; stdcall;
begin
  infoMessage('        <format tag="' + int2Str(pafd.dwFormatTag) + '"' +
			' index="' + int2Str(pafd.dwFormatIndex) + '"' +
			' info="' + htmlFix(string(pafd.szFormat)) + '" >');
  WriteWave(pafd.pwfx^, pafd.cbwfx, '          ');
  infoMessage('        </format>');
  result := true;
end;

// -- --
function myFormatTagEnumCB(hadid: HACMDRIVERID; const paftd: ACMFORMATTAGDETAILSA; had: unsigned; fdwSupport: unsigned): Windows.BOOL; stdcall;
var
  afd: ACMFORMATDETAILS;
  pwfx: pWAVEFORMATEX;
  size: unsigned;
begin
  infoMessage('    <format_tag tag="' + int2str(paftd.dwFormatTag) + '"' +
		       ' index="' + int2str(paftd.dwFormatTagIndex) + '"' +
		       '  info="' + htmlFix(string(paftd.szFormatTag)) + '" >');
  infoMessage('      <format_size>' + int2str(paftd.cbFormatSize) +
	       '</format_size>');
  infoMessage('      <num_formats>' + int2str(paftd.cStandardFormats) +
	       '</num_formats>');
  infoMessage('      <formats>');

  size := getMaxWaveFormatSize(hadid);

  getMem(pwfx, size);
  fillChar(pwfx^, size, #0);
  pwfx.wFormatTag := paftd.dwFormatTag;
  if (size >= sizeOf(pwfx^)) then
    pwfx.cbSize := size - sizeof(pwfx^);

  fillChar(afd, sizeof(afd), #0);
  afd.cbStruct := sizeOf(afd);
  afd.dwFormatTag := paftd.dwFormatTag;
  afd.pwfx := pwfx;
  afd.cbwfx := size;

  acm_FormatEnum(had, @afd, ACMFORMATENUMCBA(@myFormatEnumCB), 0, ACM_FORMATENUMF_WFORMATTAG);
  freeMem(pwfx);

  infoMessage('      </formats>');
  infoMessage('    </format_tag>');
  result := true;
end;

// --  --
procedure displayVersion(const tagName: string; value: unsigned);
begin
  infoMessage('  <' + tagName + '>' + int2Str((value and $FF000000) shr 24) + '.' +
			      int2Str((value and $00FF0000) shr 16) + ', build ' +
			      int2Str((value and $0000FFFF)) +
	   '</' + tagName + '>');
end;

// -- myDriverEnumCB --
function myDriverEnumCB(hadid: HACMDRIVERID; instance: DWORD; support: DWORD): Windows.BOOL; stdcall;
var
  details: ACMDRIVERDETAILS;
  paftd: ACMFORMATTAGDETAILS;
  pafild: ACMFILTERTAGDETAILS;
  had: HACMDRIVER;
begin
  fillChar(details, sizeOf(details), #0);
  details.cbStruct := sizeOf(details);

  acm_DriverDetails(hadid, @details, 0);

  infoMessage('<driver '{id="0x' + int2Str(hadid, 16) + '"'} +
		//' details_size="' + int2Str(details.cbStruct) + '"' +
		' info="' + htmlFix(string(details.szShortName)) + '"' +
		' mid="' + int2str(details.wMid) + '"' +
		' midInfo="' + mid2str(details.wMid) + '"' +
		' pid="' + int2str(details.wPid) + '" >');

  infoMessage('  <type>' + choice(ACMDRIVERDETAILS_FCCTYPE_AUDIOCODEC = details.fccType, 'codec', 'unknown') +
	   '</type>');

  infoMessage('  <subtype>' + int2Str(details.fccComp) +
	   '</subtype>');

  displayVersion('expected_acm_version', details.vdwACM);
  displayVersion('driver_version', details.vdwDriver);

  infoMessage('  <support>' + choice(0 <> (details.fdwSupport and ACMDRIVERDETAILS_SUPPORTF_ASYNC),     'ASYNC (supports asynchronous conversions)', '') +
			      choice(0 <> (details.fdwSupport and ACMDRIVERDETAILS_SUPPORTF_CODEC),     ' CODEC (supports conversion between two different format tags)', '') +
			      choice(0 <> (details.fdwSupport and ACMDRIVERDETAILS_SUPPORTF_CONVERTER), ' CONVERTER (supports conversion between two different formats of the same format tag)', '') +
			      choice(0 <> (details.fdwSupport and ACMDRIVERDETAILS_SUPPORTF_DISABLED),  ' DISABLED (has been disabled)', '') +
			      choice(0 <> (details.fdwSupport and ACMDRIVERDETAILS_SUPPORTF_FILTER),    ' FILTER (supports a modification of the data without changing any of the format attributes)', '') +
			      choice(0 <> (details.fdwSupport and ACMDRIVERDETAILS_SUPPORTF_HARDWARE),  ' HARDWARE (supports hardware input, output, or both through a waveform-audio device)', '') +
			      choice(0 <> (details.fdwSupport and ACMDRIVERDETAILS_SUPPORTF_LOCAL),     ' LOCAL (has been installed locally with respect to the current task)', '') +
	      '</support>');

  infoMessage('  <num_tags>' + int2Str(details.cFormatTags) +
	   '</num_tags>');

  infoMessage('  <num_filters>' + int2Str(details.cFilterTags) +
	   '</num_filters>');

  infoMessage('  <hicon>0x' + int2Str(details.hicon, 16) +
	   '</hicon>');

  infoMessage('  <description>');
  infoMessage('    <short_name>' + htmlFix(string(details.szShortName)) + '</short_name>');
  infoMessage('    <long_name>' + htmlFix(string(details.szLongName)) + '</long_name>');
  infoMessage('    <copyright>' + htmlFix(string(details.szCopyright)) + '</copyright>');
  infoMessage('    <licensing>' + htmlFix(string(details.szLicensing)) + '</licensing>');
  infoMessage('    <features>' + htmlFix(string(details.szFeatures)) + '</features>');
  infoMessage(' </description>');

  if (0 = acm_DriverOpen(@had, hadid, 0)) then begin
    infoMessage('');
    infoMessage('   <format_tags>');
    fillChar(paftd, sizeof(paftd), #0);
    paftd.cbStruct := sizeof(paftd);
    acm_FormatTagEnum(had, @paftd, ACMFORMATTAGENUMCBA(@myFormatTagEnumCB), had, 0);
    infoMessage('  </format_tags>');

    infoMessage('');
    infoMessage('   <filters>');
    fillChar(pafild, sizeof(pafild), #0);
    pafild.cbStruct := sizeof(pafild);
    acm_FilterTagEnum(had, @pafild, ACMFILTERTAGENUMCBA(@myFilterTagEnumCB), had, 0);
    infoMessage('  </filters>');

    acm_DriverClose(had, 0);
  end;

  infoMessage('</driver>');
  result := true;
end;

// --  --
function showAllocMemSize(): bool;
var
  s: string;
begin
  s := '<debug AllocMemSize="' + int2Str(ams()) + '" />';
  infoMessage(s);
  result := true;
end;

// --  --
procedure init();
begin
  infoMessage('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
  infoMessage('<acm>');
  assert(showAllocMemSize());
  infoMessage('<info>' +
		'<author>acmEnum, version 2.5.4</author>' +
		'<copyright>Copyright (c) 2001-2009 Lake of Soft</copyright>' +
		'<legal>Visit http://lakeofsoft.com/vc for more information</legal>' +
	  '</info>');
  displayVersion('acm_version', acm_GetVersion());	  
end;

// --  --
procedure done();
begin
  assert(showAllocMemSize());
  infoMessage('</acm>');
end;

// -- main --
begin
  init();
  acm_DriverEnum(myDriverEnumCB, 0, 0);
  done();
end.

