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

	  unaEncoderAPI.pas
	  Voice Communicator components version 2.5
	  API for external encoders/decoders

	----------------------------------------------
	  Copyright (c) 2002-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 21 Oct 2002

	  modified by:
		Lake, Oct-Nov 2002
		Lake, Jan-Oct 2003
		Lake, Mar-Oct 2005
		Lake, Apr 2007

	----------------------------------------------
*)

{$I unaDef.inc}
{$I unaBassDef.inc }
{$I unaVorbisDef.inc }

{*
  Contains library API and wrapper classes for Blade/Lame MP3 encoders, Vorbis/Ogg libraries, BASS library and OpenH323 plugin model.

  @Author Lake

  2.5.2008.07 Still here
}

unit
  unaEncoderAPI;

interface

uses
  Windows, unaTypes, unaClasses,
  unaBladeEncAPI, unaVorbisAPI, unaBassAPI, unaOpenH323PluginAPI;


// ============= una errors ========================

const
  UNA_ENCODER_ERR_NOT_SUPPORTED		   =	$10000003;
  UNA_ENCODER_ERR_CONFIG_REQUIRED	   =	$10000004;
  UNA_ENCODER_ERR_FEED_MORE_DATA	   =	$10000005;	// not an error

type
  UNA_ENCODER_ERR = int;

  // --  --
  {*
    Class event for data availabitity notification.
  }
  tUnaEncoderDataAvailableEvent = procedure (sender: tObject; data: pointer; size: unsigned; var copyToStream: bool) of object;

  //
  // -- unaAbstractEncoder --
  //

  {*
    Base abstract class for stream encoder/decoder.
  }
  unaAbstractEncoder = class(unaObject)
  private
    f_priority: integer;
    //
    f_outStream: unaMemoryStream;
    f_inStream: unaMemoryStream;
    f_lazyThread: unaThread;
    //
    f_onDA: tUnaEncoderDataAvailableEvent;
    //f_gate: unaInProcessGate;
    //
    function get_priority(): integer;
    procedure set_priority(value: integer);
    //
    procedure _write();
    function get_availableDataSize(index: integer): unsigned;
  protected
    f_errorCode: UNA_ENCODER_ERR;
    f_configOK: bool;
    f_opened: bool;
    //
    f_inBuf: pointer;
    f_inBufSize: unsigned;
    f_outBuf: pointer;
    f_outBufSize: unsigned;
    f_outBufUsed: DWORD;
    f_inputChunkSize: int;	// must be set by doSetup();
    //
    f_minOutputBufSize: DWORD;
    f_encodedDataSize: unsigned;
    //
    {*
    }
    function doDAEvent(data: pointer; size: unsigned): bool; virtual;
    {*
      Override this method to provide implementation of encoder configuration.

      @returns status code of encoder after config information provided with config parameter was applied.
    }
    function doSetConfig(config: pointer): UNA_ENCODER_ERR; virtual; abstract;
    {*
      Override this method to provide implementation of opening the encoder.

      @returns status code of encoder after it was opened.
    }
    function doOpen(): UNA_ENCODER_ERR; virtual; abstract;
    {*
      Override this method to provide implementation of closing the encoder.

      @returns status code of encoder after was closed.
    }
    function doClose(): UNA_ENCODER_ERR; virtual; abstract;
    {*
      Override this method to provide implementation of encoding the portion of data.

      @returns status code of encoding.
    }
    function doEncode(data: pointer; nBytes: unsigned; out bytesUsed: unsigned): UNA_ENCODER_ERR; virtual; abstract;
    //
    function enter(timeout: tTimeout): bool;
    //
    function leave(): bool;
  public
    {*
      Creates an encoder with specified priority.

      @priority has meaning with lazyWrite() method only.
    }
    constructor create(priority: integer = THREAD_PRIORITY_NORMAL);
    procedure AfterConstruction(); override;
    procedure BeforeDestruction(); override;
    //
    {*
      Configures encoder with specific stream parameters.
    }
    function setConfig(config: pointer): UNA_ENCODER_ERR;
    {*
      Activates the encoder.
    }
    function open(): UNA_ENCODER_ERR;
    {*
      Deactivates the encoder.
    }
    function close(): UNA_ENCODER_ERR;
    {*
      Returns number of bytes produced by encoder.
      Encoded data is first sent to onDataAvailable() event (if handler is assigned).
      If this event has no handler assigned, or handler returns writeToStream = true,
      data is also written into ouput stream.

      	Check errorCode property if 0 was returned.

	Do not mix lazyWrite() and encodeChunk() calls.
    }
    function encodeChunk(data: pointer; size: unsigned; lastOne: bool = false): unsigned;
    {*
      Encodes a chunk of data. Encoded data is copied into outBuf.
      Returns actual number of bytes produced by this function or zero if some error has occured.
      Writes encoded data into outBuf.
      Number of bytes written into outBuf will not exceed outBufSize (which could be less than required).
      This function does not call onDataAvailable() and does not write any data into output stream.
      Size parameter also used to return number of bytes used in input buffer. 

      Check errorCode property if 0 was returned.

      Do not mix lazyWrite() and encodeChunkInPlace() calls.
    }
    function encodeChunkInPlace(data: pointer; var size: unsigned; outBuf: pointer; outBufSize: unsigned): unsigned;
    {*
      Returns immediately after copying the data from buffer.
      Uses internal thread to feed the encoder.

      Do not mix lazyWrite() and encodeChunk() calls.
    }
    procedure lazyWrite(buf: pointer; size: unsigned);
    {*
      Reads data from the encoder output buffer.

      @returns number of bytes read from output buffer.
    }
    function read(buf: pointer; size: unsigned = 0): unsigned;
    {*
      Returns number of bytes available to read from output stream.
    }
    property availableOutputDataSize: unsigned index 0 read get_availableDataSize;
    {*
      Returns number of bytes awaiting to be processed in the input stream.
    }
    property availableInputDataSize: unsigned index 1 read get_availableDataSize;
    {*
      Returns number of bytes awaiting to be processed in the input stream of lazy thread.
    }
    property availableLazyDataSize: unsigned index 2 read get_availableDataSize;
    {*
      Size of input chunk in bytes.
    }
    property inputChunkSize: int read f_inputChunkSize;
    {*
      Number of bytes encoded so far.
    }
    property encodedDataSize: unsigned read f_encodedDataSize;
    {*
      Encoder status code.
    }
    property errorCode: UNA_ENCODER_ERR read f_errorCode;
    {*
      Priority of encoder thread.
      Has meaning only when you are using lazyWrite().
    }
    property priority: integer read get_priority write set_priority;
    {*
      Can be fired from internal thread, so do not use VCL calls in the handler.
      If you assign a handler for this event, and will not change the copyToStream parameter, data will not be copied into output stream.
    }
    property onDataAvailable: tUnaEncoderDataAvailableEvent read f_onDA write f_onDA;
  end;


// =========================== BLADE MP3 ENCODER ==========================

  //
  // -- unaBladeMp3Enc --
  //
  {*
    Provides access to Blade MP3 encoder.
    Requires Blade library DLL (BladeEnc.dll)

    http://bladeenc.mp3.no/
  }
  unaBladeMp3Enc = class(unaAbstractEncoder)
  private
    f_bladeProc: tBladeLibrary_proc;
  protected
    f_dllPathAndName: wString;
    f_version: PBE_VERSION;
    //
    f_stream: HBE_STREAM;
    //
    {*
      Loads Blade encoder DLL into process memory.
    }
    function loadDLL(): int; virtual;
    {*
      Unloads Blade encoder DLL from process memory.
    }
    function unloadDLL(): int; virtual;
    //
    {*
      Returns version of loaded Blade encoder.
    }
    procedure getVersion(); virtual;
    //
    {*
      Opens Blade encoder.
    }
    function doOpen(): UNA_ENCODER_ERR; override;
    {*
      Configures Blade encoder.
    }
    function doSetConfig(config: pointer): UNA_ENCODER_ERR; override;
    {*
      Closes Blade encoder.
    }
    function doClose(): UNA_ENCODER_ERR; override;
    {*
      Encodes a chunk of data.
    }
    function doEncode(data: pointer; nBytes: unsigned; out bytesUsed: unsigned): UNA_ENCODER_ERR; override;
  public
    {*
      Creates Blade encoder API provider.
    }
    constructor create(const dllPathAndName: wString = ''; priority: integer = THREAD_PRIORITY_NORMAL);
    procedure AfterConstruction(); override;
    procedure BeforeDestruction(); override;
    {*
      Version of Blade encoder.
    }
    property version: PBE_VERSION read f_version;
  end;


// =========================== LAME MP3 ENCODER ==========================

  //
  // -- unaLameMp3Enc --
  //

  {*
    Provides access to Lame MP3 encoder.
    Requires Lame library DLL (lame_enc.dll)

    http://www.mp3dev.org/
  }
  unaLameMp3Enc = class(unaBladeMp3Enc)
  private
    f_lameProc: tLameLibrary_proc;
  protected
    {*
      Loads Lame encoder DLL into process memory.
    }
    function loadDLL(): int; override;
    {*
      Unloads Lame encoder DLL into process memory.
    }
    function unloadDLL(): int; override;
    {*
      Returns version of loaded Lame encoder.
    }
    procedure getVersion(); override;
    {*
      Configures Lame encoder.
    }
    function doSetConfig(config: pointer): UNA_ENCODER_ERR; override;
    {*
      Closes Lame encoder.
    }
    function doClose(): UNA_ENCODER_ERR; override;
    {*
      Encodes a chunk of data.
    }
    function doEncode(data: pointer; nBytes: unsigned; out bytesUsed: unsigned): UNA_ENCODER_ERR; override;
  end;


{$IFNDEF VC_LIBVORBIS_ONLY }	// classes below are doomed to full version of Vorbis API

// =========================== VORBIS ENCODER/DECODER ==========================

  // --  --
  tVorbisEncodeMethodEnum = (vemABR, vemVBR, vemRateManage);

  // --  --
  pVorbisSetup = ^tVorbisSetup;
  tVorbisSetup = packed record
    //
    r_numOfChannels: byte;	// 1 - monophonic; 2 - stereo; 3 - 1d-surround; 4 - quadraphonic surround; 5 - five-channel surround; 5 - 5,1 surround
    r_samplingRate: unsigned;	// from 8000 up to 192000
    //
    case r_encodeMethod: tVorbisEncodeMethodEnum of

      vemABR:
	(r_min_bitrate: int;	// all bitrates are from about 48000 up to 360000 or -1
	 r_normal_bitrate: int;
	 r_max_bitrate: int);

      vemVBR:
	(r_quality: single);		// from -0.9999 (lowest) up to 1.0

      vemRateManage:
	(r_manage_minBitrate: int;
	 r_manage_normalBitrate: int;
	 r_manage_maxBitrate: int;
	 r_manage_mode: int);		// see OV_ECTL_RATEMANAGE_XXXX
  end;


  //
  // -- unaVorbisAbstract --
  //
  {*
    Provides access to Vorbis library API.
  }
  unaVorbisAbstract = class(unaAbstractEncoder)
  private
    f_vi: tVorbis_info;
    f_vc: tVorbis_comment;
    f_vd: tVorbis_dsp_state;
    f_vb: tVorbis_block;
    //
    f_popPacketBuf: pointer;
    f_popPacketBufSize: unsigned;
    //
    function get_vb(): pVorbis_block;
    function get_vc(): pVorbis_comment;
    function get_vd(): pVorbis_dsp_state;
    function get_vi(): pVorbis_info;
  protected
    f_vorbisDllPathAndName: wString;
    f_version: int;
    //
    {*
      Loads Vorbis DLL into process memory.
    }
    function loadDLL(): int; virtual;
    {*
      Unloads Vorbis DLL from process memory.
    }
    function unloadDLL(): int; virtual;
    {*
      Closes Vorbis library.
    }
    function doClose(): UNA_ENCODER_ERR; override;
    {*
      Pops Ogg packet (if any) from output stream.
      NOTE: All packets share same buffer, so only one packet at a time must be popped.
    }
    function doPopPacket(var packet: tOgg_packet): bool;
  public
    {*
      Creates Vorbis library API provider.
    }
    constructor create(const vorbisDll: wString = ''; priority: integer = THREAD_PRIORITY_NORMAL);
    procedure AfterConstruction(); override;
    procedure BeforeDestruction(); override;
    {*
      same as doPopPacket();
    }
    function popPacket(var packet: tOgg_packet): bool;
    {*
      Version of Vorbis library.
    }
    property version: int read f_version;
    //
    property vi: pVorbis_info read get_vi;
    property vc: pVorbis_comment read get_vc;
    property vd: pVorbis_dsp_state read get_vd;
    property vb: pVorbis_block read get_vb;
  end;


  //
  // -- unaVorbisEnc --
  //
  {*
    Provides interface of Vorbis/Ogg stream encoding.
    Requires Vorbis/Ogg libraries DLLs (ogg.dll, vorbis.dll and vorbisenc.dll)

    http://www.xiph.org/ogg/vorbis/
  }
  unaVorbisEnc = class(unaVorbisAbstract)
  private
    f_vorbisEncDllPathAndName: wString;
    f_isFirstChunk: bool;
    f_isLastChunk: bool;
    //
    procedure vorbis_analyze();
    procedure pushPacket(const packet: tOgg_packet);
  protected
    {*
      Loads Vorbis encoder DLLs into process memory.
    }
    function loadDLL(): int; override;
    {*
      Unloads Vorbis DLLs from process memory.
    }
    function unloadDLL(): int; override;
    {*
      Opens Vorbis encoder.
    }
    function doOpen(): UNA_ENCODER_ERR; override;
    {*
      Configures Vorbis encoder.
    }
    function doSetConfig(config: pointer): UNA_ENCODER_ERR; override;
    {*
      Closes Vorbis encoder.
    }
    function doClose(): UNA_ENCODER_ERR; override;
    {*
      Encodes a chunk of data.
    }
    function doEncode(data: pointer; nBytes: unsigned; out bytesUsed: unsigned): UNA_ENCODER_ERR; override;
  public
    {*
      Creates Vorbis/Ogg encoder interface.
    }
    constructor create(const vorbisDll: wString = ''; const vorbisEncDll: wString = ''; priority: integer = THREAD_PRIORITY_NORMAL);
    {*
      Adds comments to Vorbis stream header.
    }
    procedure vorbis_addComment(const tagName, tagValue: string);
  end;


const
  // -- ogg additional error codes --
  OV_ERR_FILEHANDLE_INVALID	= -6001;

type
  // --  --
  pConvBuffArray = ^tConvBuffArray;
  tConvBuffArray = array[0 .. maxInt div sizeOf(ogg_int16_t) - 1] of ogg_int16_t;

  unaOggFile = class;

  //
  // -- unaVorbisDecoder --
  //
  {*
    Provides interface of Vorbis/Ogg stream decoding.
    Requires Vorbis/Ogg libraries DLLs (ogg.dll and vorbis.dll)

    http://www.xiph.org/ogg/vorbis/
  }
  unaVorbisDecoder = class(unaVorbisAbstract)
  private
    f_outBufSizeInSamples: unsigned;
    //
    f_vorbisEos: int;
    f_oggFile: unaOggFile;
  protected
    {*
      Opens Vorbis decoder.
    }
    function doOpen(): UNA_ENCODER_ERR; override;
    {*
      Configures Vorbis decoder.
    }
    function doSetConfig(config: pointer): UNA_ENCODER_ERR; override;
    {*
      Closes Vorbis decoder.
    }
    function doClose(): UNA_ENCODER_ERR; override;
    {*
      Decodes a chunk of data.
    }
    function doEncode(data: pointer; nBytes: unsigned; out bytesUsed: unsigned): UNA_ENCODER_ERR; override;
  public
    {*
      Reads specified amount of data from decoder output.
      Returns number of bytes actually read, or 0 if no more data is available.
    }
    function readDecode(buf: pointer; size: unsigned): unsigned;
    {*
      Feeds decoder with new packet.
    }
    function synthesis_packet(const packet: tOgg_packet): int;
    {*
      Feeds decoder with new data from buffer.
    }
    function synthesis_blockin(): int;
    {*
      Reads PCM data (if any) from decoder. Returns number of samples read.
    }
    function synthesis_pcmout(var pcm: pSingleSamples): int;
    //
    {*
      Initializates decoder.
    }
    function decode_initBuffer(size: unsigned): int;
    {*
      Returns number of samples decoded.
    }
    function decode_packet(const packet: tOgg_packet; out wasClipping: bool): int;
  end;


  //
  //  - unaOggFile --
  //
  tUnaDataAvailableEvent = procedure (sender: tObject; data: pointer; size: unsigned) of object;

  {*
    Provides interface of Ogg file stream.
    Requires Ogg library DLL (ogg.dll)

    http://www.xiph.org/ogg/vorbis/
  }
  unaOggFile = class(unaObject)
  private
    f_onDA: tUnaDataAvailableEvent;
    //
    f_fileName: wString;
    f_fileHandle: tHandle;
    f_serialno: int;
    f_access: unsigned;
    f_errorCode: int;
    //
    f_os: tOgg_stream_state;
    f_oy: tOgg_sync_state; //* sync and verify incoming physical bitstream */
    //
    function get_os: pOgg_stream_state;
  public
    {*
      Creates or opens existing Ogg stream file.
    }
    constructor create(const fileName: wString; serialno: int = -1; access: unsigned = GENERIC_READ);
    procedure AfterConstruction(); override;
    procedure BeforeDestruction(); override;
    //
    {*
      Writes packet into Ogg stream.
    }
    function packetIn(const packet: tOgg_packet): int;
    {*
      Flushes all pending segments/pages. Next packet is ensured to start on a new page.
    }
    function flush(): int;
    {*
      Writes out any pending pages into a physical file.
    }
    function pageOut(): int;
    //
    {*
      Initializes Ogg reader.
    }
    function sync_init(): int;
    {*
      Allocates Ogg reader buffer with given size.
    }
    function sync_buffer(size: unsigned): pointer;
    {*
      Feeds Ogg reader with new data from buffer.
    }
    function sync_wrote(size: unsigned): int;
    {*
      Pops new page (if any) from Ogg reader.
    }
    function sync_pageout(var og: tOgg_page): int;
    {*
      Feeds Ogg reader with size bytes from physical file.
    }
    function sync_blockRead(size: unsigned): unsigned;
    //
    {*
      Feeds Ogg stream with new page.
    }
    function stream_pagein(const og: tOgg_page): int;
    {*
      Pops Ogg packet (if any) from Ogg stream.
    }
    function stream_packetOut(var op: tOgg_packet): int;
    //
    {*
      Initializes Vorbis decoder with header data from Ogg stream.

      @Returns 0 if successfull.
    }
    function vorbis_decode_int(decoder: unaVorbisDecoder): int;
    //
    property os: pOgg_stream_state read get_os;
    property errorCode: int read f_errorCode;
    property onDataAvailable: tUnaDataAvailableEvent read f_onDA write f_onDA;
  end;

{$ENDIF VC_LIBVORBIS_ONLY }


// ================== BASS LIBRARY WITH MP3 DECODER ======================

const
  // error codes
  BASS_ERROR_NOLIBRARY	= BASS_ERROR_UNKNOWN - 1;

type

  unaBass = class;
  unaBassChannel = class;

  unaBassDSPCallbackEvent = procedure(sender: tobject; channel: DWORD; data: pointer; len: unsigned) of object;

  unaBassConsumer = class
  private
    f_bass: unaBass;
    f_isValid: bool;
    f_handle: DWORD;
    f_channel: unaBassChannel;
    f_dsp: HDSP;
    f_onDSPCallback: unaBassDSPCallbackEvent;
    //
    procedure initDSPCallback();
    procedure freeDSPCallback();
  protected
    procedure setHandle(value: DWORD); virtual;
    procedure freeResources(); virtual;
    //
    function supportsDSP(): bool; virtual;
    procedure doDSPCallback(channel: DWORD; data: pointer; len: unsigned); virtual;
  public
    constructor create(bass: unaBass; noChannel: bool = false);
    procedure BeforeDestruction(); override;
    //
    function bytes2seconds(pos: QWORD): Single;
    function seconds2bytes(const pos: Single): QWORD;
    //
    property bass: unaBass read f_bass;
    property handle: DWORD read f_handle write setHandle;
    property asChannel: unaBassChannel read f_channel;
    //
    property onDSPCallback: unaBassDSPCallbackEvent read f_onDSPCallback write f_onDSPCallback;
  end;


  {*
    Provides interface for BASS.
    Requires BASS library (bass.dll)

    http://www.un4seen.com/
  }
  unaBass = class
  private
    f_bass: tBassProc;
    f_isValid: bool;
    //
    f_bassLibName: wString;
    f_deviceId: int;
    f_freq: DWORD;
    f_flags: DWORD;
    f_win: HWND;
    //
    f_consumers: unaObjectList;
  protected
    function bass_init(device: Integer; freq, flags: DWORD; win: HWND): bool;
    procedure bass_free();
  public
    constructor create(const libraryFileName: wString = ''; deviceId: int = {$IFDEF BASS_AFTER_18 }1{$ELSE }-1{$ENDIF }; freq: DWORD = 44100; flags: DWORD = BASS_DEVICE_LEAVEVOL; handle: int = 0);
    //
    procedure AfterConstruction(); override;
    procedure BeforeDestruction(); override;
    //
    function initialize(deviceId: int = -1; freq: DWORD = 44100; flags: DWORD = BASS_DEVICE_LEAVEVOL; win: HWND = 0; force: bool = false): bool;
    //
    function get_version(): DWORD;
    function get_versionStr(): string;
    function get_errorCode(): int;
    function get_info(out info: BASS_INFO): bool;
    function get_CPU(): int;	// 1% = 100
    //
    function get_deviceDescription(deviceNum: unsigned): string;
    function get_DSObject(obj: DWORD): pointer;
    function set_CLSID(clsid: TGUID): bool;
    //
    function set_logCurves(volume, pan: bool): bool;
    function set_bufferLength(const len: Single): Single;
    function set_netConfig(option, value: DWORD): DWORD;
    //
    function get_globalVolumes(out musvol, samvol, strvol: int): bool;
    function set_globalVolumes(musvol, samvol, strvol: int): bool;
    function get_volume(): int;
    function set_volume(volume: int): bool;
    //
    function start(): bool;
    function stop(): bool;
    function pause(): bool;
    function update(): bool;
    //
    function apply3D(): bool;
    function get_3DPosition(out pos, vel, front, top: BASS_3DVECTOR): bool;
    function set_3DPosition(const pos, vel, front, top: BASS_3DVECTOR): bool;
    function get_3DFactors(out distf, rollf, doppf: Single): bool;
    function set_3DFactors(const distf, rollf, doppf: Single): bool;
    function get_EAXParameters(out env: int32; out vol, decay, damp: Single): bool;
    function set_EAXParameters(env: int; const vol, decay, damp: Single): bool;
    function set_3DAlgorithm(algo: DWORD): bool;
    //
    function cd_init(drive: char; flags: DWORD): bool;
    function cd_free(): bool;
    function cd_inDrive(): bool;
    function cd_play(track: DWORD; loop: bool = false; wait: bool = false): bool;
    function cd_stop(): bool;
    function cd_get_tracks(): int;
    function cd_get_trackLength(track: DWORD): DWORD;
    function cd_get_ID(id: DWORD): string;
    function cd_door(doOpen: bool): bool;
    //
    function record_get_deviceDescription(deviceId: int): string;
    function record_init(deviceId: int): bool;
    function record_free(): bool;
    function record_getInfo(out info: BASS_RECORDINFO): bool;
    function record_start(freq, flags: DWORD; proc: RECORDPROC; user: DWORD): bool;
    function record_getLineName(line: DWORD): string;
    function record_selectLine(line: DWORD; settings: DWORD): bool;
    function record_getLineInfo(line: DWORD): DWORD;
  end;


  {*
    Provides interface for BASS module music support.
    Requires BASS library (bass.dll)

    http://www.un4seen.com/
  }
  unaBassMusic = class(unaBassConsumer)
  private
    f_ampLevel: DWORD;
    f_panSep: DWORD;
  protected
    procedure music_free();
    procedure freeResources(); override;
    procedure setHandle(value: DWORD); override;
    //
    function supportsDSP(): bool; override;
  public
    function load(const fileName: wString; offset: DWORD = 0; maxLength: DWORD = 0; flags: DWORD = 0): bool; overload;
    function load(buf: pointer; len: DWORD; flags: DWORD = 0): bool; overload;
    //
    function get_name(): string;
    function get_length(playlen: bool = true): QWORD;
    function set_positionScaler(scale: DWORD): bool;
    function get_channelVol(channel: DWORD): int;
    function set_channelVol(channel, volume: DWORD): bool;
    //
    function get_ampLevel(): DWORD;
    function set_ampLevel(amp: DWORD): bool;
    function get_panSeparation(): DWORD;
    function set_panSeparation(pan: DWORD): bool;
    //
    function play(ensureBass: bool = true): bool;
    function playEx(position: int{in seconds}; flags: DWORD = BASS_MUSIC_SURROUND; reset: bool = true): bool; overload;
    function playEx(row, order: DWORD; flags: DWORD = BASS_MUSIC_SURROUND; reset: bool = false): bool; overload;
    function preBuf(len: DWORD = 0): bool;
  end;


  {*
    Provides interface for BASS sample support.
    
	Requires BASS library (bass.dll)
  }
  unaBassSample = class(unaBassConsumer)
  protected
    procedure sample_free();
    procedure freeResources(); override;
  public
    function load(const fileName: wString; offset: DWORD = 0; maxLength: DWORD = 0; maxOver: DWORD = 16; flags: DWORD = BASS_SAMPLE_OVER_VOL): bool; overload;
    function load(buf: pointer; len: DWORD; maxOver: DWORD = 16; flags: DWORD = BASS_SAMPLE_OVER_VOL): bool; overload;
    //
    function createSample(buf: pointer; len: unsigned; freq, max, flags: DWORD; chans: DWORD = 0): bool;
    //
    function get_info(out info: BASS_SAMPLE): bool;
    function set_info(const info: BASS_SAMPLE): bool;
    function play(): HCHANNEL;
    function playEx(start: DWORD; freq, volume, pan: Integer; loop: bool): HCHANNEL;
    function play3D(const pos, orient, vel: BASS_3DVECTOR): HCHANNEL;
    function play3DEx(const pos, orient, vel: BASS_3DVECTOR; start: DWORD; freq, volume: Integer; loop: bool): HCHANNEL;
    function stop(handle: HSAMPLE): bool;
  end;


  {*
    Provides interface for BASS stream support.
    Requires BASS library (bass.dll)

    http://www.un4seen.com/
  }
  unaBassStream = class(unaBassConsumer)
  protected
    procedure stream_free();
    procedure freeResources(); override;
    //
{$IFDEF BASS_AFTER_18 }
    procedure onDownloadURL(buf: pointer; len: unsigned); virtual;
{$ENDIF BASS_AFTER_18 }
  public
    function createStream(freq, flags: DWORD; proc: pointer; user: DWORD): bool; overload;
    function createStream(const fileName: wString; offset, maxLength, flags: DWORD): bool; overload;
    function createStream(const url: string; offset: DWORD; flags: DWORD; const localCopy: string = ''): bool; overload;
    function createStream(data: pointer; len, flags: DWORD): bool; overload;
    //
    function get_length(): QWORD;
    function get_filePosition(mode: DWORD): DWORD;
    function get_tags(tags: DWORD): pAnsiChar;
    //
    function play(flush: bool; flags: DWORD): bool;
    function preBuf(len: DWORD = 0): bool;
    //
    procedure closeStream();
    function isOpen(): bool;
  end;


  {*
    Provides interface for BASS channel support.
    Requires BASS library (bass.dll)

    http://www.un4seen.com/
  }
  unaBassChannel = class(unaBassConsumer)
  protected
    procedure freeResources(); override;
  public
    function init(channel: HCHANNEL): bool;
    //
    function get_flags(): DWORD;
    function get_attributes(out freq, volume, pan: int32): bool;
    function set_attributes(freq, volume, pan: int): bool;
    function get_3DAttributes(out mode: int32; out min, max: Single; out iangle, oangle, outvol: int32): bool;
    function set_3DAttributes(const mode: int; min, max: Single; iangle, oangle, outvol: int32): bool;
    function get_position(orderRow: bool = false): QWORD;
    function set_position(RO: QWORD; orderRow: bool = false): bool;
    function get_3DPosition(out pos, orient, vel: BASS_3DVECTOR): bool;
    function set_3DPosition(const pos, orient, vel: BASS_3DVECTOR): bool;
    function set_EAXMix(const mix: Single): bool;
    function get_EAXMix(out mix: Single): bool;
    function set_slideAttributes(freq, volume, pan: Integer; time: DWORD): bool;
    function get_isSliding(): DWORD;
    //
    function stop(): bool;
    function pause(): bool;
    function resume(): bool;
    //
    function get_isActive(): DWORD;
    function get_level(): DWORD;
    function get_data(buf: pointer; len: DWORD): int;
    function get_dataAvailSize(): int;
  {$IFDEF BASS_AFTER_22 }
    function get_tags(handle: DWORD; tags: DWORD): pAnsiChar;
  {$ENDIF BASS_AFTER_22 }
    //
    function remove_sync(sync: HSYNC): bool;
    function remove_DSP(dsp: HDSP): bool;
    function remove_link(chan: DWORD): bool;
    function remove_FX(fx: HFX): bool;
    function set_sync(atype: DWORD; param: QWORD; proc: SYNCPROC; user: DWORD): HSYNC;
    function set_DSP(proc: DSPPROC; user: DWORD): HDSP;
    function set_link(chan: DWORD): bool;
    function set_FX(etype: DWORD; priority: int = 0): HFX;
    //
    function FX_set_parameters(fx: HFX; par: pointer): bool;
    function FX_get_parameters(fx: HFX; par: pointer): bool;
  end;


  tUnaBassApplySampling = procedure(sender: tObject; rate, bits, channels: unsigned) of object;
  tUnaBassDataAvailable = procedure(sender: tObject; data: pointer; size: unsigned) of object;

  // --  --
  unaBassStreamDecoder = class(unaThread)
  private
    f_dataTimeout: tTimeout;
    f_bassStream: unaBassStream;
    f_dataStream: unaAbstractStream;
    f_onAS: tUnaBassApplySampling;
    f_onDA: tUnaBassDataAvailable;
  protected
    function execute(threadId: unsigned): int; override;
    procedure startOut(); override;
    //
    procedure applySampling(rate, bits, channels: unsigned); virtual;
    procedure dataAvailable(data: pointer; size: unsigned); virtual;
  public
    constructor create(bassStream: unaBassStream; dataStream: unaAbstractStream; dataTimeout: tTimeout = 1000);
    procedure BeforeDestruction(); override;
    //
    property onApplySampling: tUnaBassApplySampling read f_onAS write f_onAS;
    property onDataAvailable: tUnaBassDataAvailable read f_onDA write f_onDA;
    //
    property dataTimeout: tTimeout read f_dataTimeout write f_dataTimeout;	// ms
  end;


  {*
    Decoder based on BASS library

    http://www.un4seen.com/
  }
  unaBassDecoder = class
  private
    f_libName: wString;
    f_bass: unaBass;
    f_bassStream: unaBassStream;
    f_bassError: int;
    f_dataStream: unaMemoryStream;
    f_bassStreamThread: unaBassStreamDecoder;
  public
    constructor create(const libName: wString = '');
    procedure AfterConstruction(); override;
    procedure BeforeDestruction(); override;
    //
    procedure open();
    procedure close();
    procedure updateConfig(const libName: wString = '');
    procedure write(data: pointer; len: unsigned);
    //
    property libName: wString read f_libName;
    property bassError: int read f_bassError;
    property bassStreamThread: unaBassStreamDecoder read f_bassStreamThread;
  end;


// ====================== Open H.323 plugins support ==================

type
  //
  popenH323pluginCodecs = ^openH323pluginCodecs;
  openH323pluginCodecs = array[word] of pluginCodec_definition;


  {*
	Codec based on OpenH323 plugin model.
	http://openh323.sourceforge.net/
  }
  una_openH323plugin = class(unaAbstractEncoder)
  private
    f_libName: wString;
    f_ilbcProc: plugin_proc;
    f_procOK: bool;
    //
    f_codecDefCnt: uint32;
    f_codecDefRoot: popenH323pluginCodecs;
    //
    f_codec: ppluginCodec_definition;	// selected codec
    f_context: pointer;			// codec instance
    f_codecIndex: int;
    //
    function getCodecDef(index: int): ppluginCodec_definition;
    procedure setCodecIndex(value: int);
  protected
    {*
      Loads plugin DLL into process memory.
    }
    function loadDLL(): int; virtual;
    {*
      Unloads plugin DLL from process memory.
    }
    function unloadDLL(): int; virtual;
    //
    {*
      Opens plugin codec
    }
    function doOpen(): UNA_ENCODER_ERR; override;
    {*
      Configures plugin codec
    }
    function doSetConfig(config: pointer): UNA_ENCODER_ERR; override;
    {*
      Closes plugin codec
    }
    function doClose(): UNA_ENCODER_ERR; override;
    {*
      Encodes a chunk of data.
    }
    function doEncode(data: pointer; nBytes: unsigned; out bytesUsed: unsigned): UNA_ENCODER_ERR; override;
  public
    {*
      Creates plugin codec class
    }
    constructor create(const dllPathAndName: wString; priority: integer = THREAD_PRIORITY_NORMAL);
    //
    procedure AfterConstruction(); override;
    procedure BeforeDestruction(); override;
    //
    function selectCodec(index: int): UNA_ENCODER_ERR;
    //
    function isEncoder(index: int = -1): bool;
    //
    {*
      Returns version of loaded plugin
    }
    function getVersion(): int;
    //
    property codecDefCount: uint32 read f_codecDefCnt;
    property codecDef[index: int]: ppluginCodec_definition read getCodecDef;
    //
    property codecIndex: int read f_codecIndex write setCodecIndex;
  end;


// ====================== some well-known open H.323 plugin libraries ==================

const
  c_openH323plugin_libraryName_g726	= 'g726codec_pwplugin.dll';
  c_openH323plugin_libraryName_GSM610	= 'gsm0610_pwplugin.dll';
  c_openH323plugin_libraryName_iLBC	= 'ilbccodec_pwplugin.dll';
  c_openH323plugin_libraryName_ADPCM	= 'IMA_ADPCM_pwplugin.dll';
  c_openH323plugin_libraryName_LPC	= 'LPC_10_pwplugin.dll';
  c_openH323plugin_libraryName_speeX	= 'speexcodec_pwplugin.dll';


implementation


uses
  unaUtils;

//============== una classes ===================

type

  //
  // -- unaBladeLazyWriteThread --
  //
  unaLazyWriteThread = class(unaThread)
  private
    f_encoder: unaAbstractEncoder;
    f_waitEvent: unaEvent;
    f_needToFlush: bool;
    //
    f_lazyStream: unaMemoryStream;
    f_lazyBuf: pointer;
  protected
    function execute(threadIndex: unsigned): int; override;
  public
    constructor create(encoder: unaAbstractEncoder);
    procedure BeforeDestruction(); override;
    //
    procedure write(buf: pointer; size: unsigned);
    procedure flush();
  end;


{ unaLazyWriteThread }

// --  --
procedure unaLazyWriteThread.BeforeDestruction();
begin
  inherited;
  //
  mrealloc(f_lazyBuf);
  freeAndNil(f_waitEvent);
  freeAndNil(f_lazyStream);
end;

// --  --
constructor unaLazyWriteThread.create(encoder: unaAbstractEncoder);
begin
  f_encoder := encoder;
  f_waitEvent := unaEvent.create();
  //
  f_lazyBuf := nil;
  f_lazyStream := unaMemoryStream.create();
  //
  inherited create(false, encoder.f_priority);
end;

// --  --
function unaLazyWriteThread.execute(threadIndex: unsigned): int;
var
  size: unsigned;
  avail: unsigned;
  used: unsigned;
begin
  size := f_encoder.f_inputChunkSize;
  mrealloc(f_lazyBuf, size);
  f_needToFlush := false;
  //
  while (not shouldStop and f_encoder.f_opened) do begin
    //
    if (f_waitEvent.waitFor(100)) then begin
      //
      if (acquire(false, 100)) then try
        //
        avail := f_lazyStream.getAvailableSize();
        if ((size <= avail) or f_needToFlush) then begin
          //
          if (f_needToFlush) then
            size := min(size, avail);
          //
          if (0 < size) then begin
            //
            avail := f_lazyStream.read(f_lazyBuf, int(size));
            if (0 < avail) then begin
              //
              result := f_encoder.doEncode(f_lazyBuf, avail, used);
              //
              if (BE_ERR_SUCCESSFUL = result) then
                f_encoder._write();
              //
              if (used < avail) then begin
                //
                // some bytes were left unused, need to re-use them later
                // TODO:
                used := avail;
              end;
            end;
            //
            avail := f_lazyStream.getAvailableSize();
            if (0 < avail) then
              f_waitEvent.setState();	// go read rest of the buffer
          end;
          //
          if (f_needToFlush) then
            // restore size value
            size := f_encoder.f_inputChunkSize;
        end;
      finally
        releaseWO();
      end
      else
	f_waitEvent.setState();	// try one more time
    end;
    //
  end;
  //
  result := 0;
end;

// --  --
procedure unaLazyWriteThread.flush();
begin
  if (acquire(false, 3000)) then try
    //f_needToFlush := true;
  finally
    releaseWO();
  end;
  //
  f_needToFlush := true;	// must be set anyway
  //
  while (0 < f_lazyStream.getAvailableSize()) do begin
    //
    f_waitEvent.setState();
    //
    if ((unatsRunning <> status) or (GetCurrentThreadId() = getThreadId())) then
      break	// no sence to wait any longer, since we are in the same thread as execute() method, or thread is not running
    else
      sleepThread(100);	// give encoder some CPU
  end;
end;

// --  --
procedure unaLazyWriteThread.write(buf: pointer; size: unsigned);
begin
  if ((nil <> buf) and (0 < size) and (unatsRunning = status)) then begin
    //
    f_lazyStream.write(buf, size);
    f_waitEvent.setState();	// notify about new data
  end;
end;


{ unaAbstractEncoder }

// --  --
procedure unaAbstractEncoder.AfterConstruction();
begin
  inherited;
  //
  f_inBuf := nil;
  f_inBufSize := 0;
  //
  f_outBuf := nil;
  f_outBufSize := 0;
  f_outStream := unaMemoryStream.create();
  f_inStream := unaMemoryStream.create();
  //f_gate := unaInProcessGate.create();
  //
  f_lazyThread := unaLazyWriteThread.create(self);
  //priority := f_priority;	- not required since thread will use our f_priority field
end;

// --  --
procedure unaAbstractEncoder.BeforeDestruction();
begin
  close();
  //
  inherited;
  //
  mrealloc(f_inBuf);
  mrealloc(f_outBuf);
  f_inBufSize := 0;
  f_outBufSize := 0;
  f_errorCode := BE_ERR_SUCCESSFUL;
  //
  //freeAndNil(f_gate);
  freeAndNil(f_outStream);
  freeAndNil(f_inStream);
  freeAndNil(f_lazyThread);
end;

// --  --
function unaAbstractEncoder.close(): UNA_ENCODER_ERR;
begin
  if (f_opened) then begin
    //
    unaLazyWriteThread(f_lazyThread).flush();	// give thread a chance to flush the buffer
    f_lazyThread.stop();
  end;
  //
  if (f_configOK) then begin
    //
    result := doClose();
    //
    if (BE_ERR_SUCCESSFUL = result) then
      _write();	// do not forget to write the last chunk (if any)
    //
    f_opened := false;
    f_configOK := false;
  end
  else
    result := BE_ERR_SUCCESSFUL;
  //
  f_errorCode := result;
end;

// --  --
constructor unaAbstractEncoder.create(priority: integer);
begin
  inherited create();
  //
  f_priority := priority;
end;

// --  --
function unaAbstractEncoder.doDAEvent(data: pointer; size: unsigned): bool;
begin
  if (assigned(f_onDA)) then begin
    //
    result := false;
    f_onDA(self, data, size, result);
  end
  else
    result := true;
end;

// --  --
function unaAbstractEncoder.encodeChunk(data: pointer; size: unsigned; lastOne: bool): unsigned;
var
  dataSize: unsigned;
  used: unsigned;
begin
  if (f_opened) then begin
    //
    if (lastOne or ((nil <> data) and (0 < size))) then begin
      //
      f_inStream.write(data, size);
      result := UNA_ENCODER_ERR_FEED_MORE_DATA;
      //
      while (lastOne or (f_inStream.getAvailableSize() >= f_inputChunkSize)) do begin
	//
	dataSize := min(f_inStream.getAvailableSize(), f_inputChunkSize);
	if (dataSize > f_inBufSize) then begin
	  //
	  // increase size of input buffer
	  f_inBufSize := dataSize;
	  mrealloc(f_inBuf, f_inBufSize);
	end;
	//
	if ({f_sampleSize}2 <= dataSize) then begin
	  //
	  f_inStream.read(f_inBuf, int(dataSize));
	  result := doEncode(f_inBuf, dataSize, used);
	  //
	  if (BE_ERR_SUCCESSFUL = result) then begin
	    //
	    _write();
	    //
	    if (used < dataSize) then begin
	      //
	      // some bytes were left unused, need to re-use them later
	      // TODO:
	      used := dataSize;
	    end;
	  end
	  else begin
	    //assert(false, 'encode fails');
	    break;
	  end;
	end
	else
	  break;
      end;
      //
    end
    else
      result := BE_ERR_SUCCESSFUL;
  end
  else
    result := UNA_ENCODER_ERR_CONFIG_REQUIRED
end;

// --  --
function unaAbstractEncoder.encodeChunkInPlace(data: pointer; var size: unsigned; outBuf: pointer; outBufSize: unsigned): unsigned;
var
  res: UNA_ENCODER_ERR;
  sz: int;
  used: unsigned;
begin
  if (outBufSize > f_outBufSize) then begin
    //
    // need to adjust output buffer size, so doEncode() will not exceed supplied outBuf
    f_outBufSize := outBufSize;
    mrealloc(f_outBuf, f_outBufSize);
  end;
  //
  if (enter(112)) then try
    //
    res := doEncode(data, size, used);
    if (BE_ERR_SUCCESSFUL = res) then begin
      //
      sz := min(f_outBufUsed, outBufSize);
      if (0 < sz) then
        move(f_outBuf^, outBuf^, sz);
      //
      inc(f_encodedDataSize, f_outBufUsed);
      result := f_outBufUsed;
      f_outBufUsed := 0;
      //
      if (0 < used) then
        size := used
      else
        size := 0;
    end
    else
      result := 0;	// check error code
    //
  finally
    leave();
  end
  else
    result := 0;
end;

// --  --
function unaAbstractEncoder.enter(timeout: tTimeout): bool;
begin
  result := acquire(false, timeout);
end;

// --  --
function unaAbstractEncoder.get_availableDataSize(index: integer): unsigned;
begin
  case (index) of

    0: result := f_outStream.getAvailableSize();
    1: result := f_inStream.getAvailableSize();
    2: result := unaLazyWriteThread(f_lazyThread).f_lazyStream.getAvailableSize();
    
    else
       result := 0;
  end;
end;

// --  --
function unaAbstractEncoder.get_priority(): integer;
begin
  result := f_lazyThread.priority;
end;

// --  --
procedure unaAbstractEncoder.lazyWrite(buf: pointer; size: unsigned);
begin
  unaLazyWriteThread(f_lazyThread).write(buf, size);
end;

// --  --
function unaAbstractEncoder.leave(): bool;
begin
  //f_gate.leave();
  release({$IFDEF DEBUG }false{$ENDIF DEBUG });
  result := true;
end;

// --  --
function unaAbstractEncoder.open(): UNA_ENCODER_ERR;
begin
  if (f_configOK) then begin
    //
    if (not f_opened) then begin
      //
      f_inStream.clear();
      f_outStream.clear();
      f_encodedDataSize := 0;
      //
      doOpen();
      //
      f_opened := true;
      //
      f_lazyThread.start();
    end;
    result := BE_ERR_SUCCESSFUL;
  end
  else
    result := UNA_ENCODER_ERR_CONFIG_REQUIRED;
  //
  f_errorCode := result;
end;

// --  --
function unaAbstractEncoder.read(buf: pointer; size: unsigned): unsigned;
begin
  result := f_outStream.read(buf, int(size));
end;

// --  --
function unaAbstractEncoder.setConfig(config: pointer): UNA_ENCODER_ERR;
begin
  close();	// make sure stream is closed
  //
  result := doSetConfig(config);
  if (BE_ERR_SUCCESSFUL = result) then begin
    //
    if (f_outBufSize < f_minOutputBufSize) then begin
      //
      mrealloc(f_outBuf, f_minOutputBufSize);
      f_outBufSize := f_minOutputBufSize;
    end;
  end;
  //
  f_errorCode := result;
  f_configOK := (BE_ERR_SUCCESSFUL = result);
end;

// --  --
procedure unaAbstractEncoder.set_priority(value: integer);
begin
  f_lazyThread.priority := value;
end;

// --  --
procedure unaAbstractEncoder._write();
begin
  if (0 < f_outBufUsed) then begin
    //
    inc(f_encodedDataSize, f_outBufUsed);
    //
    if (doDAEvent(f_outBuf, f_outBufUsed)) then
      f_outStream.write(f_outBuf, f_outBufUsed);
    //
    f_outBufUsed := 0;
  end;
end;


{ unaBladeMp3Enc }

// --  --
procedure unaBladeMp3Enc.AfterConstruction();
begin
  inherited;
  //
  new(f_version);
  f_stream := $FFFFFFFF;
  //
  if (0 = loadDll()) then
    f_errorCode := BE_ERR_SUCCESSFUL
  else
    f_errorCode := UNA_ENCODER_ERR_NO_DLL;
  //
  if (BE_ERR_SUCCESSFUL = errorCode) then
    getVersion();
end;

// --  --
procedure unaBladeMp3Enc.BeforeDestruction();
begin
  inherited;
  //
  dispose(f_version);
  //
  unloadDll();
end;

// --  --
constructor unaBladeMp3Enc.create(const dllPathAndName: wString; priority: integer);
begin
  inherited create(priority);
  //
  f_dllPathAndName := dllPathAndName;
end;

// --  --
function unaBladeMp3Enc.doClose(): UNA_ENCODER_ERR;
begin
  result := beDeinitStream(f_bladeProc, f_stream, f_outBuf, f_outBufUsed);
  //
  if (BE_ERR_SUCCESSFUL = result) then
    result := beCloseStream(f_bladeProc, f_stream);
  //
  f_stream := $FFFFFFFF;
end;

// --  --
function unaBladeMp3Enc.doEncode(data: pointer; nBytes: unsigned; out bytesUsed: unsigned): UNA_ENCODER_ERR;
begin
  result := beEncodeChunk(f_bladeProc, f_stream, nBytes shr 1 {16 bits; regardless of number of channels}, data, f_outBuf, f_outBufUsed);
  bytesUsed := nBytes;	// I hope so
end;

// --  --
function unaBladeMp3Enc.doOpen(): UNA_ENCODER_ERR;
begin
  // blade has no openStream()
  result := BE_ERR_SUCCESSFUL;
end;

// --  --
function unaBladeMp3Enc.doSetConfig(config: pointer): UNA_ENCODER_ERR;
var
  nSamples: DWORD;
begin
  result := beInitStream(f_bladeProc, config, nSamples, f_minOutputBufSize, f_stream);
  //
  // -- all samples are 2 bytes long, regadless is it mono/stereo --
  //
  f_inputChunkSize := nSamples shl 1 {* f_sampleSize};
end;

// --  --
procedure unaBladeMp3Enc.getVersion();
begin
  beVersion(f_bladeProc, f_version^);
end;

// --  --
function unaBladeMp3Enc.loadDLL(): int;
begin
  result := blade_loadDLL(f_bladeProc, f_dllPathAndName);
end;

// --  --
function unaBladeMp3Enc.unloadDLL(): int;
begin
  result := blade_unloadDLL(f_bladeProc);
end;


{ unaLameMp3Enc }

// --  --
function unaLameMp3Enc.doClose(): UNA_ENCODER_ERR;
begin
  result := lameDeinitStream(f_lameProc, f_stream, f_outBuf, f_outBufUsed);
  if (BE_ERR_SUCCESSFUL = result) then begin
    //
    // work around for stupid lame DLL bug
    lameWriteVBRHeader(f_lameProc, '');
    //
    result := lameCloseStream(f_lameProc, f_stream);
  end;
  //
  f_stream := $FFFFFFFF;
end;

// --  --
function unaLameMp3Enc.doEncode(data: pointer; nBytes: unsigned; out bytesUsed: unsigned): UNA_ENCODER_ERR;
begin
  result := lameEncodeChunk(f_lameProc, f_stream, nBytes shr 1 {16 bits; regardless of number of channels}, data, f_outBuf, f_outBufUsed);
  bytesUsed := nBytes;	// I hope so
end;

// --  --
function unaLameMp3Enc.doSetConfig(config: pointer): UNA_ENCODER_ERR;
var
  nSamples: DWORD;
begin
  result := lameInitStream(f_lameProc, PBE_CONFIG_FORMATLAME(config), nSamples, f_minOutputBufSize, f_stream);
  //
  // -- all samples are 2 bytes long, regadless is it mono/stereo --
  //
  f_inputChunkSize := nSamples shl 1 {* f_sampleSize};
end;

// --  --
procedure unaLameMp3Enc.getVersion();
begin
  lameVersion(f_lameProc, f_version^);
end;

// --  --
function unaLameMp3Enc.loadDLL(): int;
begin
  result := lame_loadDLL(f_lameProc, f_dllPathAndName);
end;

// --  --
function unaLameMp3Enc.unloadDLL(): int;
begin
  result := lame_unloadDLL(f_lameProc);
end;

{$IFNDEF VC_LIBVORBIS_ONLY }

{ unaVorbisAbstract }

// --  --
procedure unaVorbisAbstract.AfterConstruction();
begin
  inherited;
  //
  f_popPacketBuf := nil;
  f_popPacketBufSize := 0;
  //
  if (0 = loadDll()) then
    f_errorCode := BE_ERR_SUCCESSFUL
  else
    f_errorCode := UNA_ENCODER_ERR_NO_DLL;
end;

// --  --
procedure unaVorbisAbstract.BeforeDestruction();
begin
  inherited;
  //
  mrealloc(f_popPacketBuf);
  //
  unloadDll();
end;

// --  --
constructor unaVorbisAbstract.create(const vorbisDll: wString; priority: integer);
begin
  inherited create(priority);
  //
  f_vorbisDllPathAndName := vorbisDll;
  f_priority := priority;
end;

// --  --
function unaVorbisAbstract.doClose(): UNA_ENCODER_ERR;
begin
  vorbis_block_clear(f_vb);
  vorbis_dsp_clear(f_vd);
  vorbis_comment_clear(f_vc);
  vorbis_info_clear(f_vi);
  //
  result := BE_ERR_SUCCESSFUL;
end;

// --  --
function unaVorbisAbstract.doPopPacket(var packet: tOgg_packet): bool;
begin
  if (f_outStream.getAvailableSize() >= sizeOf(packet) - sizeOf(pointer)) then begin
    //
    f_outStream.read(@packet.bytes, int(sizeOf(packet) - sizeOf(pointer)));
    if (0 < packet.bytes) then begin
      //
      if (unsigned(packet.bytes) > f_popPacketBufSize) then begin
	mrealloc(f_popPacketBuf, packet.bytes);
	f_popPacketBufSize := packet.bytes;
      end;
      //
      packet.packet := f_popPacketBuf;
      packet.bytes := f_outStream.read(packet.packet, int(packet.bytes));
    end
    else
      packet.packet := nil;
    //
    result := true;
  end
  else
    result := false;
end;

// --  --
function unaVorbisAbstract.get_vb(): pVorbis_block;
begin
  result := @f_vb;
end;

// --  --
function unaVorbisAbstract.get_vc(): pVorbis_comment;
begin
  result := @f_vc;
end;

// --  --
function unaVorbisAbstract.get_vd(): pVorbis_dsp_state;
begin
  result := @f_vd;
end;

// --  --
function unaVorbisAbstract.get_vi(): pVorbis_info;
begin
  result := @f_vi;
end;

// --  --
function unaVorbisAbstract.loadDLL(): int;
begin
  if (vorbis_load_library(cunav_dll_vorbis, f_vorbisDllPathAndName)) then begin
    //
    vorbis_info_init(f_vi);
    //
    f_version := f_vi.version;
    result := BE_ERR_SUCCESSFUL;
  end
  else
    result := -1;
end;

// --  --
function unaVorbisAbstract.popPacket(var packet: tOgg_packet): bool;
begin
  result := doPopPacket(packet);
end;

// --  --
function unaVorbisAbstract.unloadDLL(): int;
begin
  vorbis_unload_library(cunav_dll_vorbis);
  result := 1;
end;


{ unaVorbisEnc }

// --  --
constructor unaVorbisEnc.create(const vorbisDll, vorbisEncDll: wString; priority: integer);
begin
  inherited create(vorbisDll, priority);
  //
  f_vorbisEncDllPathAndName := vorbisEncDll;
end;

// --  --
function unaVorbisEnc.doClose(): UNA_ENCODER_ERR;
begin
  if (not f_isLastChunk) then begin
    //
    f_isLastChunk := true;
    //
    { End of file. This can be done implicitly in the mainline, but it's easier to see here in non-clever fashion.
      Tell the library we're at end of stream so that it can handle the last frame and mark end of stream in the output properly
    }
    result := vorbis_analysis_wrote(f_vd, 0);
    //
    vorbis_analyze();
    //
    inherited doClose();
  end
  else
    result := BE_ERR_SUCCESSFUL;
end;

// --  --
function unaVorbisEnc.doEncode(data: pointer; nBytes: unsigned; out bytesUsed: unsigned): UNA_ENCODER_ERR;
var
  i, j: int;
  nSamples: int;
  buf: pSingleSamples;
  psia: pSmallInt;
  //
  header: tOgg_packet;
  header_comm: tOgg_packet;
  header_code: tOgg_packet;
begin
  bytesUsed := 0;
  //
  if (f_isFirstChunk) then begin
    //
    //* set up our packet->stream encoder */
    //
    { Vorbis streams begin with three headers; the initial header (with
      most of the codec setup parameters) which is mandated by the Ogg
      bitstream spec.  The second header holds any comment fields.  The
      third header holds the bitstream codebook.  We merely need to
      make the headers, then pass them to libvorbis one at a time;
      libvorbis handles the additional Ogg bitstream constraints
    }
    vorbis_analysis_headerout(f_vd, f_vc, header, header_comm, header_code);
    pushPacket(header);
    pushPacket(header_comm);
    pushPacket(header_code);
    //
    f_isFirstChunk := false;
  end;
  //
  if (0 < nBytes) then begin
    //
    nSamples := (nBytes div unsigned(f_vi.channels)) shr 1 { 16 bit };
    //
    //* expose the buffer to submit data */
    buf := vorbis_analysis_buffer(f_vd, nSamples);
    //
    //* uninterleave samples */
    i := 0;
    psia := data;
    while (i < nSamples) do begin
      //
      for j := 0 to f_vi.channels - 1 do begin
	//
	{ old ugly code

	buf[j][i] := smallInt( (pArray(data)[i shl f_vi.channels + j shl 1 + 1] shl 8) or
				pArray(data)[i shl f_vi.channels + j shl 1 + 0]
			     ) / 32768;
	}
	//
	buf[j][i] := psia^ / 32768;
	//
	inc(psia);
      end;
      //
      inc(i);
    end;
    //
    //* tell the library how much we actually submitted */
    result := vorbis_analysis_wrote(f_vd, nSamples);
    //
    bytesUsed := nBytes;	// looks so
    //
    vorbis_analyze();
  end
  else
    result := BE_ERR_SUCCESSFUL;
end;

// --  --
function unaVorbisEnc.doOpen(): UNA_ENCODER_ERR;
begin
  result := vorbis_analysis_init(f_vd, f_vi);
  if (0 = result) then
    result := vorbis_block_init(f_vd, f_vb);
  //
  if (0 = result) then
    vorbis_comment_init(f_vc);
  //
  f_isFirstChunk := true;
  f_isLastChunk := false;
end;

// --  --
function unaVorbisEnc.doSetConfig(config: pointer): UNA_ENCODER_ERR;
begin
  vorbis_info_clear(f_vi);
  vorbis_info_init(f_vi);
  //
  with pVorbisSetup(config)^ do begin
    //
    case (r_encodeMethod) of

      vemABR: begin
	//
	result := vorbis_encode_init(f_vi, r_numOfChannels, r_samplingRate, r_max_bitrate, r_normal_bitrate, r_min_bitrate);
      end;

      vemVBR: begin
	//
	result := vorbis_encode_init_vbr(f_vi, r_numOfChannels, r_samplingRate, r_quality);
      end;

      vemRateManage: begin
	//
	result := vorbis_encode_setup_managed(f_vi, r_numOfChannels, r_samplingRate, r_manage_maxBitrate, r_manage_normalBitrate, r_manage_minBitrate) or
		  vorbis_encode_ctl(f_vi, r_manage_mode, nil) or
		  vorbis_encode_setup_init(f_vi);
      end;

      else
	result := BE_ERR_SUCCESSFUL;
    end;
  end;
  //
  f_inputChunkSize := 1024 * 4;	// just a moderate number of bytes
end;

// --  --
function unaVorbisEnc.loadDLL(): int;
begin
  result := inherited loadDLL();
  //
  if ((0 = result) and vorbis_load_library(cunav_dll_vorbisenc, f_vorbisEncDllPathAndName)) then
  else
    result := -1;
end;

// --  --
procedure unaVorbisEnc.pushPacket(const packet: tOgg_packet);
var
  reqSize: unsigned;
begin
  reqSize := packet.bytes + sizeOf(packet) - sizeOf(pointer);
  //
  if (reqSize > f_outBufSize) then begin
    //
    mrealloc(f_outBuf, reqSize);
    f_outBufSize := reqSize;
  end;
  //
  move(packet.bytes, f_outBuf^, sizeOf(packet) - sizeOf(pointer));
  move(packet.packet^, pArray(f_outBuf)[sizeOf(packet) - sizeOf(pointer)], packet.bytes);
  //
  f_outBufUsed := reqSize;
  //
  // flush packet data
  _write();
end;

// --  --
function unaVorbisEnc.unloadDLL(): int;
begin
  result := inherited unloadDLL();
  //
  vorbis_unload_library(cunav_dll_vorbisenc);
end;

// --  --
procedure unaVorbisEnc.vorbis_addComment(const tagName, tagValue: string);
begin
  vorbis_comment_add_tag(f_vc, paChar(aString(tagName)), paChar(aString(tagValue)));
end;

// --  --
procedure unaVorbisEnc.vorbis_analyze();
var
  op: tOgg_packet;
begin
  { vorbis does some data preanalysis, then divvies up blocks for
    more involved (potentially parallel) processing.  Get a single block for encoding now
  }
  while (1 = vorbis_analysis_blockout(f_vd, f_vb)) do begin
    //
    //* analysis, assume we want to use bitrate management */
    try
      vorbis_analysis(f_vb, nil);
      //
      vorbis_bitrate_addblock(f_vb);
    except
    end;
    //
    while (0 <> vorbis_bitrate_flushpacket(f_vd, op)) do begin
      //
      pushPacket(op);
    end;
  end;
end;


{ unaVorbisDecoder }

// --  --
function unaVorbisDecoder.decode_initBuffer(size: unsigned): int;
begin
  //* OK, got and parsed all three headers. Initialize the Vorbis packet->PCM decoder. */
  result := vorbis_synthesis_init(f_vd, f_vi); //* central decode state */
  if (0 = result) then
    result := vorbis_block_init(f_vd, f_vb);     (* local state for most of the decode so multiple block decodes can proceed in parallel.
						    We could init multiple vorbis_block structures for vd here *)
  //
  mrealloc(f_outBuf, size);
  f_outBufSize := size;
  f_outBufSizeInSamples := (size div unsigned(f_vi.channels)) shr 1;
  f_vorbisEos := 0;
end;

// --  --
function unaVorbisDecoder.decode_packet(const packet: tOgg_packet; out wasClipping: bool): int;
var
  i, j: int;
  samples: int;
  pcm: pSingleSamples;
  mono: pSingleArray;
  bout: int;
  val: int;
  consumed: int;
begin
  result := 0;
  //
  if (0 = synthesis_packet(packet)) then //* test for success! */
    synthesis_blockin();
  (*
  **pcm is a multichannel float vector.  In stereo, for
  example, pcm[0] is left, and pcm[1] is right.  samples is
  the size of each channel.  Convert the float values
  (-1.<=range<=1.) to whatever PCM format and write it out *)
  //
  //
  wasClipping := false;
  repeat
    samples := synthesis_pcmout(pcm);
    if (1 > samples) then
      break;
    //
    consumed := 0;
    while (consumed < samples) do begin
      //
      bout := min(unsigned(samples - consumed), f_outBufSizeInSamples);
      //* convert floats to 16 bit signed ints (host order) and interleave */
      i := 0;
      while (i < f_vi.channels) do begin
	//
	mono := pcm[i];
	j := 0;
	while (j < bout) do begin
	  //
	  val := trunc(mono[consumed + j] * 32767);
	  //
	  //* optional dither */
	  //int val = val + drand48() - 0.5f;
	  //
	  //* might as well guard against clipping */
	  if (val > 32767) then begin
	    //
	    val := 32767;
	    wasClipping := true;
	  end;
	  if (val < -32768) then begin
	    //
	    val := -32768;
	    wasClipping := true;
	  end;
	  //
	  pConvBuffArray(f_outBuf)[i + f_vi.channels * j] := val;
	  inc(j);
	end;
	//
	inc(i);
      end;
      //
      inc(result, bout);
      inc(consumed, bout);
      //
      f_outBufUsed := vi.channels * bout shl 1 {16 bit};
      _write();
    end;
    //
    vorbis_synthesis_read(f_vd, consumed); //* tell libvorbis how  many samples we actually consumed */
    //
  until (false);
end;

// --  --
function unaVorbisDecoder.doClose(): UNA_ENCODER_ERR;
begin
  result := inherited doClose();
end;

// --  --
function unaVorbisDecoder.doEncode(data: pointer; nBytes: unsigned; out bytesUsed: unsigned): UNA_ENCODER_ERR;
var
  res: int;
  clipping: bool;
  og: tOgg_page;
  op: tOgg_packet;
begin
  bytesUsed := 0;	// seems input buffer is not used
  //
  if (nil <> f_oggFile) then begin
    //
    while (0 = f_vorbisEos) do begin
      //
      res := f_oggFile.sync_pageout(og);
      if (0 = res) then
	break; //* need more data */
      //
      if (0 > res) then //* missing or corrupt data at this page position */
	//
	//infoMessage('  corrupt or missing data in bitstream; continuing...')
      else begin
	//
	f_oggFile.stream_pagein(og); //* can safely ignore errors at this point */
	//
	while (true) do begin
	  //
	  res := f_oggFile.stream_packetout(op);
	  if (0 = res) then
	    break; //* need more data */
	  //
	  if (0 > res) then //* missing or corrupt data at this page position */
	    //* no reason to complain; already complained above */
	  else
	    //* we have a packet. decode it */
	    decode_packet(op, clipping);
	end;
	//
	if (0 <> ogg_page_eos(og)) then
	  f_vorbisEos := 1;	// end of page
      end;
    end;
    //
    if (0 = f_vorbisEos) then begin
      //
      // write('  [ ] decoding vorbis stream, page #' + int2str(ogg.os.pageno) + '     '#13);
      if (0 = f_oggFile.sync_blockRead(f_outBufSize)) then
	f_vorbisEos := 1;
    end;
    //
    result := BE_ERR_SUCCESSFUL;
  end
  else
    result := -1;
end;

// --  --
function unaVorbisDecoder.doOpen(): UNA_ENCODER_ERR;
begin
  //result := inherited doOpen();   // -- abstract
  result := 0;
end;

// --  --
function unaVorbisDecoder.doSetConfig(config: pointer): UNA_ENCODER_ERR;
begin
  result := BE_ERR_SUCCESSFUL;
end;

// --  --
{
  Jul 31, 2003 : bug fixed with help of Thomas Schoessow.
  Dec 11, 2003 : yet another bug fixed with help of Jim Margarit.

  -Lake
}
function unaVorbisDecoder.readDecode(buf: pointer; size: unsigned): unsigned;
var
  readSize: unsigned;
  used: unsigned;	// not used :)
begin
  result := 0;
  //
  if ((nil <> buf) and (0 < size) and enter(200)) then begin
    try
      //
      repeat
	//
	readSize := f_outStream.read(@pArray(buf)[result], int(size - result));
	//
	if (1 > readSize) then
	  doEncode(nil, 0, used)	// decode more data
	else
	  inc(result, readSize);
	//
      until ((result >= size) or (0 <> f_vorbisEos));	// also break if there is no more data!
      //
    finally
      leave();
    end;
  end;
end;

// --  --
function unaVorbisDecoder.synthesis_blockin(): int;
begin
  result := vorbis_synthesis_blockin(f_vd, f_vb);
end;

// --  --
function unaVorbisDecoder.synthesis_packet(const packet: tOgg_packet): int;
begin
  result := vorbis_synthesis(f_vb, packet);
end;

// --  --
function unaVorbisDecoder.synthesis_pcmout(var pcm: pSingleSamples): int;
begin
  result := vorbis_synthesis_pcmout(f_vd, pcm);
end;


{ unaOggFile }

// --  --
procedure unaOggFile.AfterConstruction();
var
  flags: unsigned;
begin
  inherited;
  //
  if (vorbis_load_library(cunav_dll_ogg)) then begin
    //
    f_errorCode := ogg_stream_init(f_os, f_serialno);
    if (0 = f_errorCode) then begin
      //
      if (fileExists(f_fileName)) then
	flags := OPEN_EXISTING
      else
	flags := CREATE_NEW;
      //
{$IFNDEF NO_ANSI_SUPPORT }
      if (g_wideApiSupported) then
{$ENDIF NO_ANSI_SUPPORT }
	f_fileHandle := CreateFileW(pwChar(f_fileName), f_access, FILE_SHARE_READ + FILE_SHARE_WRITE, nil, flags, FILE_ATTRIBUTE_NORMAL, 0)
{$IFNDEF NO_ANSI_SUPPORT }
      else
	f_fileHandle := CreateFileA(paChar(aString(f_fileName)), f_access, FILE_SHARE_READ + FILE_SHARE_WRITE, nil, flags, FILE_ATTRIBUTE_NORMAL, 0)
{$ENDIF NO_ANSI_SUPPORT }
      ;
    end;
  end
  else
    f_errorCode := OV_ERR_NO_DLL_LOADED;
end;

// --  --
procedure unaOggFile.BeforeDestruction();
begin
  inherited;
  //
  ogg_stream_clear(f_os);
  windows.CloseHandle(f_fileHandle);
  //
  vorbis_unload_library(cunav_dll_ogg);
end;

// --  --
constructor unaOggFile.create(const fileName: wString; serialno: int; access: unsigned);
begin
  inherited create();
  //
  f_fileName := fileName;
  if (0 > serialno) then begin
    randomize();
    f_serialno := serialno;
  end
  else
    f_serialno := serialno;
  //
  f_access := access;
end;

// --  --
function unaOggFile.flush(): int;
var
  og: tOgg_page;
begin
  if (0 = f_errorCode) then begin
    //
    //* flush all pending data (if any) so new data will start on new page */
    result := 0;
    //
    repeat
      if (0 = ogg_stream_flush(f_os, og)) then
	break;
      //
      writeToFile(f_fileHandle, og.header, og.header_len);
      inc(result, og.header_len);
      //
      writeToFile(f_fileHandle, og.body, og.body_len);
      inc(result, og.body_len);
    until (false);
  end
  else
    result := f_errorCode;
end;

// --  --
function unaOggFile.get_os(): pOgg_stream_state;
begin
  result := @f_os;
end;

// --  --
function unaOggFile.packetIn(const packet: tOgg_packet): int;
begin
  result := ogg_stream_packetin(f_os, packet);
end;

// --  --
function unaOggFile.pageOut(): int;
var
  og: tOgg_page;
begin
  if (0 = f_errorCode) then begin
    //
    //* write out pages (if any) */
    result := 0;
    repeat
      if (0 = ogg_stream_pageout(f_os, og)) then
	break;
      //
      writeToFile(f_fileHandle, og.header, og.header_len);
      inc(result, og.header_len);
      //
      writeToFile(f_fileHandle, og.body, og.body_len);
      inc(result, og.body_len);
    until (false);
  end
  else
    result := f_errorCode;
end;

// --  --
function unaOggFile.stream_packetOut(var op: tOgg_packet): int;
begin
  result := ogg_stream_packetout(f_os, op);
end;

// --  --
function unaOggFile.stream_pagein(const og: tOgg_page): int;
begin
  result := ogg_stream_pagein(f_os, og);
end;

// --  --
function unaOggFile.sync_blockRead(size: unsigned): unsigned;
var
  buffer: pointer;
begin
  //* submit a block to libvorbis' Ogg layer */
  result := size;
  buffer := sync_buffer(result);
  readFromFile(f_fileHandle, buffer, result);
  sync_wrote(result);
end;

// --  --
function unaOggFile.sync_buffer(size: unsigned): pointer;
begin
  result := ogg_sync_buffer(f_oy, size);
end;

// --  --
function unaOggFile.sync_init(): int;
begin
  result := ogg_sync_init(f_oy); //* Now we can read pages */
end;

// --  --
function unaOggFile.sync_pageout(var og: tOgg_page): int;
begin
  result := ogg_sync_pageout(f_oy, og);
end;

// --  --
function unaOggFile.sync_wrote(size: unsigned): int;
begin
  result := ogg_sync_wrote(f_oy, size);
end;

// --  --
function unaOggFile.vorbis_decode_int(decoder: unaVorbisDecoder): int;
var
  i, res: int;
  //
  buffer: pointer;
  readCount: unsigned;
  //
  og: tOgg_page; //* one Ogg bitstream page.  Vorbis packets are inside */
  op: tOgg_packet; //* one raw packet of data for decode */
begin
  //********** Decode setup ************/
  result := -1;
  (* grab some data at the head of the stream.  We want the first page
     (which is guaranteed to be small and only contain the Vorbis
     stream initial header) We need the first page to get the stream serialno. *)
  sync_blockRead(4096);
  //
  //* Get the first page. */
  if (1 <> sync_pageout(og)) then begin
    //* have we simply run out of data?  If so, we're done. */
    if (readCount < 4096) then begin
      //
      result := OV_EOF;
      exit;
    end;
    //
    //* Input does not appear to be an Ogg bitstream. */
    result := OV_ENOTVORBIS;
    exit;
  end;
  //
  //* Get the serial number and set up the rest of decode. */
  //* serialno first; use it to set up a logical stream */
  ogg_stream_init(f_os, ogg_page_serialno(og));
  //
  //* extract the initial header from the first page and verify that the Ogg bitstream is in fact Vorbis data */
  //
  (* I handle the initial header first instead of just having the code
     read all three Vorbis headers at once because reading the initial
     header is an easy way to identify a Vorbis bitstream and it's
     useful to see that functionality seperated out.
  *)
  //
  vorbis_info_init(decoder.f_vi);
  vorbis_comment_init(decoder.f_vc);
  //
  if (0 > stream_pagein(og)) then begin
    //* Error reading first page of Ogg bitstream data. */
    result := OV_EVERSION;
    exit;
  end;
  //
  if (1 <> stream_packetout(op)) then begin
    //* Error reading initial header packet */
    result := OV_EBADHEADER;
    exit;
  end;
  //
  if (0 > vorbis_synthesis_headerin(decoder.f_vi, decoder.f_vc, op)) then begin
    //* 'This Ogg bitstream does not contain Vorbis audio data.' */
    result := OV_ENOTAUDIO;
    exit;
  end;
  //
  (* At this point, we're sure we're Vorbis.  We've set up the logical
     (Ogg) bitstream decoder.  Get the comment and codebook headers and
     set up the Vorbis decoder *)

  (* The next two packets in order are the comment and codebook headers.
     They're likely large and may span multiple pages.  Thus we reead
     and submit data until we get our two pacakets, watching that no
     pages are missing.  If a page is missing, error out; losing a
     header page is the only place where missing data is fatal. *)
  //
  i := 0;
  while (2 > i) do begin
    //
    while (2 > i) do begin
      //
      res := sync_pageout(og);
      if (0 = res) then
	break; //* Need more data */
      //
      //* Don't complain about missing or corrupt data yet.  We'll catch it at the packet output phase */
      if (1 = res) then begin
	//
	stream_pagein(og); //* we can ignore any errors here as they'll also become apparent at packetout */
	//
	while (2 > i) do begin
	  //
	  res := stream_packetout(op);
	  if (0 = res) then
	    break;
	  //
	  if (0 > res) then begin
	    //* Uh oh; data at some point was corrupted or missing! We can't tolerate that in a header.  Die. */
	    // Corrupt secondary header.  Exiting.
	    result := OV_EBADPACKET;
	    exit;
	  end;
	  //
	  vorbis_synthesis_headerin(decoder.f_vi, decoder.f_vc, op);
	  inc(i);
	end;
      end;
    end;
    //
    //* no harm in not checking before adding more */
    readCount := 4096;
    buffer := sync_buffer(readCount);
    readFromFile(f_fileHandle, buffer, readCount);
    //
    if ((0 = readCount) and (2 > i)) then begin
      // End of file before finding all Vorbis headers!
      result := OV_EBADHEADER;
      exit;
    end;
    //
    sync_wrote(readCount);
  end;
  //
  if (2 <= i) then
    result := 0;
  //
  if (0 = result) then
    decoder.f_oggFile := self;
end;

{$ENDIF VC_LIBVORBIS_ONLY }


// ================================ BASS =========================

// -- DSP callback --

procedure bass_dsp(handle: HDSP; channel: DWORD; buffer: Pointer; length: DWORD; user: DWORD); stdcall;
begin
  if (0 <> user) then
    unaBassConsumer(user).doDSPCallback(channel, buffer, length);
end;


{ unaBassConsumer }

// --  --
procedure unaBassConsumer.BeforeDestruction();
begin
  inherited;
  //
  freeResources();
  //
  if (self <> f_channel) then
    freeAndNil(f_channel);
  //
  if ((nil <> bass) and (nil <> bass.f_consumers)) then
    bass.f_consumers.removeItem(self, 0);	// no need to free self here
end;

// --  --
function unaBassConsumer.bytes2seconds(pos: QWORD): Single;
begin
  if (f_isValid) then
    result := f_bass.f_bass.r_channelBytes2Seconds(handle, pos)
  else
    result := 0.0;
end;

// --  --
constructor unaBassConsumer.create(bass: unaBass; noChannel: bool);
begin
  inherited create();
  //
  f_bass := bass;
  f_isValid := (nil <> bass) and (bass.f_isValid);
  //
  if (noChannel) then
    f_channel := self as unaBassChannel
  else begin
    f_channel := unaBassChannel.create(bass, true);
    //
    if (nil <> bass) then
      bass.f_consumers.add(self);
  end;
end;

// --  --
procedure unaBassConsumer.doDSPCallback(channel: DWORD; data: pointer; len: unsigned);
begin
  if (assigned(f_onDSPCallback)) then
    f_onDSPCallback(self, channel, data, len);
end;

// --  --
procedure unaBassConsumer.freeDSPCallback();
begin
  if (f_isValid and (0 <> f_dsp)) then begin
    //
    f_bass.f_bass.r_channelRemoveDSP(handle, f_dsp);
    f_dsp := 0;
  end;
end;

// --  --
procedure unaBassConsumer.freeResources();
begin
  freeDSPCallback();
end;

// --  --
procedure unaBassConsumer.initDSPCallback();
begin
  if (f_isValid and supportsDSP()) then
{$IFDEF BASS_AFTER_18 }
    f_dsp := f_bass.f_bass.r_channelSetDSP(handle, bass_dsp, DWORD(self), 0);
{$ELSE }
    f_dsp := f_bass.f_bass.r_channelSetDSP(handle, bass_dsp, DWORD(self));
{$ENDIF BASS_AFTER_18 }
end;

// --  --
function unaBassConsumer.seconds2bytes(const pos: Single): QWORD;
begin
  if (f_isValid) then
    result := f_bass.f_bass.r_channelSeconds2Bytes(handle, pos)
  else
    result := 0;
end;

// --  --
procedure unaBassConsumer.setHandle(value: DWORD);
begin
  if (f_handle <> value) then begin
    //
    freeResources();
    f_handle := value;
    f_channel.init(value);
    if (0 <> handle) then
      initDSPCallback();
  end;
end;

// --  --
function unaBassConsumer.supportsDSP(): bool;
begin
  result := false;	// most consumers do not support DSP
end;


{ unaBass }

// --  --
procedure unaBass.AfterConstruction();
begin
  inherited;
  //
  f_consumers := unaObjectList.create();
  //
  f_isValid := load_bass(f_bass, trimS(f_bassLibName));
  // NOTE: bass_init() checks the f_isValid flag
  bass_init(f_deviceId, f_freq, f_flags, f_win);
end;

// --  --
function unaBass.apply3D(): bool;
begin
  if (f_isValid) then begin
    //
    f_bass.r_apply3D();
    result := true;
  end
  else
    result := false;
end;

// --  --
procedure unaBass.bass_free();
var
  i: int;
begin
  if (lockNonEmptyList_r(f_consumers, false, 1000 {$IFDEF DEBUG }, '.bass_free()'{$ENDIF DEBUG })) then
    try
      i := 0;
      while (i < f_consumers.count) do begin
	//
	unaBassConsumer(f_consumers[i]).freeResources();
	//
	inc(i);
      end;
    finally
      unlockListWO(f_consumers);
    end;
  //
  if (f_isValid) then
    f_bass.r_free();
end;

// --  --
function unaBass.bass_init(device: Integer; freq, flags: DWORD; win: HWND): bool;
begin
  if (f_isValid) then
{$IFDEF BASS_AFTER_18 }
    // fucked up in 2.0
    result := f_bass.r_init(device, freq, flags, win, nil)
{$ELSE }
    result := f_bass.r_init(device, freq, flags, win)
{$ENDIF BASS_AFTER_18 }
  else
    result := false;
end;

// --  --
procedure unaBass.BeforeDestruction();
begin
  inherited;
  //
  stop();
  //
  record_free();
  cd_free();
  bass_free();
  //
  freeAndNil(f_consumers);
  //
  unload_bass(f_bass);
end;

// --  --
function unaBass.cd_door(doOpen: bool): bool;
begin
  if (f_isValid) then begin
    //
{$IFDEF BASS_AFTER_18 }
    // fucked up in 2.0
    result := false;
{$ELSE }
    result := f_bass.r_CDDoor(doOpen);
{$ENDIF BASS_AFTER_18 }
  end
  else
    result := false;
end;

// --  --
function unaBass.cd_free(): bool;
begin
  if (f_isValid) then begin
{$IFDEF BASS_AFTER_18 }
    // fucked up in 2.0
    result := false;
{$ELSE }
    f_bass.r_CDFree();
    result := true;
{$ENDIF BASS_AFTER_18 }
  end
  else
    result := false;
end;

// --  --
function unaBass.cd_get_ID(id: DWORD): string;
begin
  if (f_isValid) then
{$IFDEF BASS_AFTER_18 }
    // fucked up in 2.0
    result := ''
{$ELSE }
    result := f_bass.r_CDGetID(id)
{$ENDIF BASS_AFTER_18 }
  else
    result := '';
end;

// --  --
function unaBass.cd_get_trackLength(track: DWORD): DWORD;
begin
  if (f_isValid) then
{$IFDEF BASS_AFTER_18 }
    // fucked up in 2.0
    result := 0
{$ELSE }
    result := f_bass.r_CDGetTrackLength(track)
{$ENDIF BASS_AFTER_18 }
  else
    result := 0;
end;

// --  --
function unaBass.cd_get_tracks(): int;
begin
  if (f_isValid) then
{$IFDEF BASS_AFTER_18 }
    // fucked up in 2.0
    result := 0
{$ELSE}
    result := f_bass.r_CDGetTracks()
{$ENDIF BASS_AFTER_18 }
  else
    result := -1;
end;

// --  --
function unaBass.cd_inDrive(): bool;
begin
  if (f_isValid) then
{$IFDEF BASS_AFTER_18 }
    // fucked up in 2.0
    result := false
{$ELSE }
    result := f_bass.r_CDInDrive()
{$ENDIF BASS_AFTER_18 }
  else
    result := false;
end;

// --  --
function unaBass.cd_init(drive: char; flags: DWORD): bool;
{$IFDEF BASS_AFTER_18 }
{$ELSE }
var
  pdrive: array[0..2] of char;
{$ENDIF BASS_AFTER_18 }
begin
  if (f_isValid) then begin
{$IFDEF BASS_AFTER_18 }
    // fucked up in 2.0
    result := false;
{$ELSE }
    pdrive := 'X:';
    pdrive[0] := drive;
    result := f_bass.r_CDInit(@pdrive, flags)
{$ENDIF BASS_AFTER_18 }
  end
  else
    result := false;
end;

// --  --
function unaBass.cd_play(track: DWORD; loop, wait: BOOL): bool;
begin
  if (f_isValid) then
{$IFDEF BASS_AFTER_18 }
    // fucked up in 2.0
    result := false
{$ELSE }
    result := f_bass.r_CDPlay(track, loop, wait)
{$ENDIF BASS_AFTER_18 }
  else
    result := false;
end;

// --  --
function unaBass.cd_stop(): bool;
begin
  if (f_isValid) then
    result := f_bass.r_channelStop(CDCHANNEL)
  else
    result := false;
end;

// --  --
constructor unaBass.create(const libraryFileName: wString; deviceId: int; freq: DWORD; flags: DWORD; handle: int);
begin
  inherited create();
  //
  f_bassLibName := libraryFileName;
  f_deviceId := deviceId;
  f_freq := freq;
  f_flags := flags;
  f_win := handle;
end;

// --  --
function unaBass.get_3DFactors(out distf, rollf, doppf: Single): bool;
begin
  if (f_isValid) then
    result := f_bass.r_get3DFactors(distf, rollf, doppf)
  else
    result := false;
end;

// --  --
function unaBass.get_3DPosition(out pos, vel, front, top: BASS_3DVECTOR): bool;
begin
  if (f_isValid) then
    result := f_bass.r_get3DPosition(pos, vel, front, top)
  else
    result := false;
end;

// --  --
function unaBass.get_CPU(): int;
begin
  if (f_isValid) then
    result := trunc(100 * f_bass.r_getCPU())
  else
    result := 0;
end;

// --  --
function unaBass.get_deviceDescription(deviceNum: unsigned): string;
begin
  if (f_isValid) then
    result := string(f_bass.r_getDeviceDescription(deviceNum))
  else
    result := '';
end;

// --  --
function unaBass.get_DSObject(obj: DWORD): pointer;
begin
  if (f_isValid) then
    result := f_bass.r_getDSoundObject(obj)
  else
    result := nil;
end;

// --  --
function unaBass.get_EAXParameters(out env: int32; out vol, decay, damp: Single): bool;
begin
  if (f_isValid) then
    result := f_bass.r_getEAXParameters(env, vol, decay, damp)
  else
    result := false;
end;

// --  --
function unaBass.get_errorCode(): int;
begin
  if (f_isValid) then
    result := int(f_bass.r_errorGetCode())
  else
    result := BASS_ERROR_NOLIBRARY;
end;

// --  --
function unaBass.get_globalVolumes(out musvol, samvol, strvol: int): bool;
begin
  if (f_isValid) then begin
{$IFDEF BASS_AFTER_18 }
    musvol := int(f_bass.r_getConfig(BASS_CONFIG_GVOL_MUSIC));
    samvol := int(f_bass.r_getConfig(BASS_CONFIG_GVOL_SAMPLE));
    strvol := int(f_bass.r_getConfig(BASS_CONFIG_GVOL_STREAM));
{$ELSE }
    f_bass.r_getGlobalVolumes(musvol, samvol, strvol);
{$ENDIF BASS_AFTER_18 }
    result := true;
  end
  else
    result := false;
end;

// --  --
function unaBass.get_info(out info: BASS_INFO): bool;
begin
  if (f_isValid) then begin
    //
    info.size := sizeOf(info);
    f_bass.r_getInfo(info);
    result := true;
  end
  else
    result := false;
end;

// --  --
function unaBass.get_version(): DWORD;
begin
  if (f_isValid) then
    result := f_bass.r_getVersion()
  else
    result := 0;
end;

// --  --
function unaBass.get_versionStr(): string;
var
  ver: DWORD;
begin
  ver := get_version();
  result := int2str(ver and $FFFF) + '.' + int2str(ver shr 16);
end;

// --  --
function unaBass.get_volume(): int;
begin
  if (f_isValid) then
    result := f_bass.r_getVolume()
  else
    result := 0;
end;

// --  --
function unaBass.initialize(deviceId: int; freq: DWORD; flags: DWORD; win: HWND; force: bool): bool;
begin
  result := bass_init(deviceId, freq, flags, win);
  if (not result and force) then begin
    //
    if (BASS_ERROR_ALREADY = get_errorCode()) then begin
      // free and try once more
      bass_free();
      result := bass_init(deviceId, freq, flags, win);
    end;
  end;
end;

// --  --
function unaBass.pause(): bool;
begin
  if (f_isValid) then
    result := f_bass.r_pause()
  else
    result := false;
end;

// --  --
function unaBass.record_free(): bool;
begin
  if (f_isValid) then begin
    //
    f_bass.r_recordFree();
    result := true;
  end
  else
    result := false;
end;

// --  --
function unaBass.record_get_deviceDescription(deviceId: int): string;
begin
  if (f_isValid) then
    result := string(f_bass.r_recordGetDeviceDescription(deviceId))
  else
    result := '';
end;

// --  --
function unaBass.record_getInfo(out info: BASS_RECORDINFO): bool;
begin
  if (f_isValid) then begin
    //
    info.size := sizeOf(info);
    f_bass.r_recordGetInfo(info);
    result := true;
  end
  else
    result := false;
end;

// --  --
function unaBass.record_getLineInfo(line: DWORD): DWORD;
begin
  if (f_isValid) then
    result := f_bass.r_recordGetInput(line)
  else
    result := 0;
end;

// --  --
function unaBass.record_getLineName(line: DWORD): string;
begin
  if (f_isValid) then
    result := string(f_bass.r_recordGetInputName(line))
  else
    result := '';
end;

// --  --
function unaBass.record_init(deviceId: int): bool;
begin
  if (f_isValid) then
    result := f_bass.r_recordInit(deviceId)
  else
    result := false;
end;

// --  --
function unaBass.record_selectLine(line, settings: DWORD): bool;
begin
  if (f_isValid) then
    result := f_bass.r_recordSetInput(line, settings)
  else
    result := false;
end;

// --  --
function unaBass.record_start(freq, flags: DWORD; proc: RECORDPROC; user: DWORD): bool;
begin
  if (f_isValid) then
    result := f_bass.r_recordStart(freq, flags, proc, user)
  else
    result := false;
end;

// --  --
function unaBass.set_3DAlgorithm(algo: DWORD): bool;
begin
  if (f_isValid) then begin
{$IFDEF BASS_AFTER_18 }
    result := (DWORD(-1) <> f_bass.r_setConfig(BASS_CONFIG_3DALGORITHM, algo));
{$ELSE }
    f_bass.r_set3DAlgorithm(algo);
    result := true;
{$ENDIF BASS_AFTER_18 }
  end
  else
    result := false;
end;

// --  --
function unaBass.set_3DFactors(const distf, rollf, doppf: Single): bool;
begin
  if (f_isValid) then
    result := f_bass.r_set3DFactors(distf, rollf, doppf)
  else
    result := false;
end;

// --  --
function unaBass.set_3DPosition(const pos, vel, front, top: BASS_3DVECTOR): bool;
begin
  if (f_isValid) then
    result := f_bass.r_set3DPosition(pos, vel, front, top)
  else
    result := false;
end;

// --  --
function unaBass.set_bufferLength(const len: Single): Single;
begin
  if (f_isValid) then
    //
{$IFDEF BASS_AFTER_18 }
    result := f_bass.r_setConfig(BASS_CONFIG_BUFFER, round(len))
{$ELSE }
    result := f_bass.r_setBufferLength(len)
{$ENDIF BASS_AFTER_18 }
  else
    result := 0;
end;

// --  --
function unaBass.set_CLSID(clsid: TGUID): bool;
begin
  if (f_isValid) then begin
{$IFDEF BASS_AFTER_18 }
    // nothing here..
{$ELSE }
    f_bass.r_setCLSID(clsid);
{$ENDIF BASS_AFTER_18 }
    result := true;
  end
  else
    result := false;
end;

// --  --
function unaBass.set_EAXParameters(env: int; const vol, decay, damp: Single): bool;
begin
  if (f_isValid) then
    result := f_bass.r_setEAXParameters(env, vol, decay, damp)
  else
    result := false;
end;

// --  --
function unaBass.set_globalVolumes(musvol, samvol, strvol: int): bool;
begin
  if (f_isValid) then begin
    //
{$IFDEF BASS_AFTER_18 }
    f_bass.r_setConfig(BASS_CONFIG_GVOL_MUSIC, DWORD(musvol));
    f_bass.r_setConfig(BASS_CONFIG_GVOL_SAMPLE, DWORD(samvol));
    f_bass.r_setConfig(BASS_CONFIG_GVOL_STREAM, DWORD(strvol));
{$ELSE }
    f_bass.r_setGlobalVolumes(musvol, samvol, strvol);
{$ENDIF BASS_AFTER_18 }
    result := true;
  end
  else
    result := false;
end;

// --  --
function unaBass.set_logCurves(volume, pan: bool): bool;
begin
  if (f_isValid) then begin
{$IFDEF BASS_AFTER_18 }
    f_bass.r_setConfig(BASS_CONFIG_CURVE_PAN, DWORD(pan));
    f_bass.r_setConfig(BASS_CONFIG_CURVE_VOL, DWORD(volume));
{$ELSE }
    f_bass.r_setLogCurves(volume, pan);
{$ENDIF BASS_AFTER_18 }
    result := true;
  end
  else
    result := false;
end;

// --  --
function unaBass.set_netConfig(option, value: DWORD): DWORD;
begin
  if (f_isValid) then
{$IFDEF BASS_AFTER_18 }
    result := f_bass.r_setConfig(BASS_CONFIG_NET_BUFFER, value)
{$ELSE }
    result := f_bass.r_setNetConfig(option, value)
{$ENDIF BASS_AFTER_18 }
  else
    result := 0;
end;

// --  --
function unaBass.set_volume(volume: int): bool;
begin
  if (f_isValid) then
    result := f_bass.r_setVolume(volume)
  else
    result := false;
end;

// --  --
function unaBass.start(): bool;
begin
  if (f_isValid) then
    result := f_bass.r_start()
  else
    result := false;
end;

// --  --
function unaBass.stop(): bool;
begin
  if (f_isValid) then
    result := f_bass.r_stop()
  else
    result := false;
end;

// --  --
function unaBass.update(): bool;
begin
  if (f_isValid) then
    result := f_bass.r_update()
  else
    result := false;
end;


{ unaBassMusic }

// --  --
procedure unaBassMusic.freeResources();
begin
  music_free();
  //
  inherited;
end;

// --  --
function unaBassMusic.get_ampLevel(): DWORD;
begin
  result := f_ampLevel;
end;

// --  --
function unaBassMusic.get_channelVol(channel: DWORD): int;
begin
  if (f_isValid) then begin
{$IFDEF BASS_AFTER_18 }
  //
  {$IFDEF BASS_AFTER_20 }
    // v 2.0
    result := int(f_bass.f_bass.r_musicGetAttribute(handle, channel))
  {$ELSE}
    // v 2.0
    result := f_bass.f_bass.r_musicGetVolume(handle, channel)
  {$ENDIF BASS_AFTER_20 }
{$ELSE}
    // v 1.8
    result := f_bass.f_bass.r_musicGetChannelVol(handle, channel)
{$ENDIF BASS_AFTER_18 }
  end
  else
    result := -1;
end;

// --  --
function unaBassMusic.get_length(playlen: bool): QWORD;
begin
  if (f_isValid) then begin
{$IFDEF BASS_AFTER_21 }
    //
    { 2.2
      BASS_StreamGetLength, BASS_MusicGetLength
      //
      These functions have been merged into BASS_ChannelGetLength, which gives the byte length of a channel.
      To get the number of orders in a MOD music, BASS_MusicGetOrders has been added.
      Also note that requesting the length when streaming in blocks will now result in a BASS_ERROR_NOTAVAIL error, instead of just 0.
    }
    result := f_bass.f_bass.r_channelGetLength(handle);
    if (QWORD(-1) = result) then begin
      //
      if (BASS_ERROR_NOTAVAIL = f_bass.f_bass.r_errorGetCode()) then
	result := 0;
    end;
    //
{$ELSE }
    result := f_bass.f_bass.r_musicGetLength(handle, playlen)
{$ENDIF BASS_AFTER_21 }
  end
  else
    result := 0;
end;

// --  --
function unaBassMusic.get_name(): string;
begin
  if (f_isValid) then
{$IFDEF BASS_AFTER_22 }
    result := string(f_bass.f_bass.r_channelGetTags(handle, BASS_TAG_MUSIC_NAME))
{$ELSE }
    // fucked in 2.3
    result := string(f_bass.f_bass.r_musicGetName(handle))
{$ENDIF BASS_AFTER_22 }
  else
    result := '';
end;

// --  --
function unaBassMusic.get_panSeparation(): DWORD;
begin
  result := f_panSep;
end;

// --  --
function unaBassMusic.load(const fileName: wString; offset: DWORD; maxLength: DWORD; flags: DWORD): bool;
begin
  if (f_isValid) then begin
    //
    if (0 = flags) then
{$IFDEF BASS_AFTER_21 }
      flags := BASS_MUSIC_CALCLEN or BASS_MUSIC_PRESCAN;
{$ELSE }
      flags := BASS_MUSIC_CALCLEN;
{$ENDIF BASS_AFTER_21 }
    //
{$IFDEF BASS_AFTER_18 }
    handle := f_bass.f_bass.r_musicLoad(false, pwChar(fileName), offset, maxLength, flags, 0);
{$ELSE }
    handle := f_bass.f_bass.r_musicLoad(false, paChar(aString(fileName)), offset, maxLength, flags);
{$ENDIF BASS_AFTER_18 }
    result := (0 <> handle);
  end
  else
    result := false;
end;

// --  --
function unaBassMusic.load(buf: pointer; len: DWORD; flags: DWORD): bool;
begin
  if (f_isValid) then begin
    //
    if (0 = flags) then
{$IFDEF BASS_AFTER_21 }
      flags := BASS_MUSIC_CALCLEN or BASS_MUSIC_PRESCAN;
{$ELSE }
      flags := BASS_MUSIC_CALCLEN;
{$ENDIF BASS_AFTER_21 }
    //
{$IFDEF BASS_AFTER_18 }
    handle := f_bass.f_bass.r_musicLoad(true, buf, 0, len, flags, 0);
{$ELSE }
    handle := f_bass.f_bass.r_musicLoad(true, buf, 0, len, flags);
{$ENDIF BASS_AFTER_18 }
    //
    result := (0 <> handle);
  end
  else
    result := false;
end;

// --  --
procedure unaBassMusic.music_free();
begin
  if (f_isValid and (0 <> handle)) then
    f_bass.f_bass.r_musicFree(handle);
end;

// --  --
function unaBassMusic.play(ensureBass: bool): bool;
begin
  if (f_isValid) then begin
    //
{$IFDEF BASS_AFTER_20 }
    // v 2.1
    result := f_bass.f_bass.r_channelPlay(handle, true);
{$ELSE }
    // v 1.8
    result := f_bass.f_bass.r_musicPlay(handle);
{$ENDIF BASS_AFTER_20 }
    //
    if (not result and ensureBass) then begin
      //
      if (BASS_ERROR_START = f_bass.get_errorCode()) then begin
	// try once more
	f_bass.start();
	//
	result := play(false);
      end;
    end;
  end
  else
    result := false;
end;

// --  --
function unaBassMusic.playEx(row, order, flags: DWORD; reset: bool): bool;
begin
  if (f_isValid) then begin
    //
{$IFDEF BASS_AFTER_20 }
    // v 2.1
    result := f_bass.f_bass.r_channelSetPosition(handle, order or (row shl 16));
    result := result and f_bass.f_bass.r_channelSetFlags( handle, int(flags) or choice(reset, BASS_MUSIC_POSRESETEX, int(0)) );
    //
    result := result and f_bass.f_bass.r_channelPlay(handle, false);
{$ELSE }
    // v 1.8
    result := f_bass.f_bass.r_musicPlayEx(handle, order or (row shl 16), flags, reset)
{$ENDIF BASS_AFTER_20 }
  end
  else
    result := false;
end;

// --  --
function unaBassMusic.playEx(position: int; flags: DWORD; reset: bool): bool;
begin
  if (f_isValid) then begin
{$IFDEF BASS_AFTER_20 }
    // v 2.1
    result := f_bass.f_bass.r_channelSetPosition(handle, DWORD(position or ($FFFF shl 16)));
    result := result and f_bass.f_bass.r_channelSetFlags(handle, int(flags) or choice(reset, BASS_MUSIC_POSRESETEX, int(0)));
    //
    result := result and f_bass.f_bass.r_channelPlay(handle, false);
{$ELSE }
    // v 1.8
    result := f_bass.f_bass.r_musicPlayEx(handle, DWORD(position or ($FFFF shl 16)), flags, reset)
{$ENDIF BASS_AFTER_20 }
  end
  else
    result := false;
end;

// --  --
function unaBassMusic.preBuf(len: DWORD): bool;
begin
  if (f_isValid) then
{$IFDEF BASS_AFTER_20 }
  {$IFDEF BASS_AFTER_21 }
    // parameters were fucked in 2.2
    result := f_bass.f_bass.r_channelPreBuf(handle, len)
  {$ELSE }
    // v 2.1
    result := f_bass.f_bass.r_channelPreBuf(handle)
  {$ENDIF BASS_AFTER_21 }
{$ELSE}
    result := f_bass.f_bass.r_musicPreBuf(handle)
{$ENDIF BASS_AFTER_20 }
  else
    result := false;
end;

// --  --
procedure unaBassMusic.setHandle(value: DWORD);
begin
  inherited;
  //
  f_ampLevel := 50;
  f_panSep := 50;
end;

// --  --
function unaBassMusic.set_ampLevel(amp: DWORD): bool;
begin
  if (f_isValid) then
{$IFDEF BASS_AFTER_20 }
    // v 2.1
    result := (DW_ERROR <> f_bass.f_bass.r_musicSetAttribute(handle, BASS_MUSIC_ATTRIB_AMPLIFY, amp))
{$ELSE }
    result := f_bass.f_bass.r_musicSetAmplify(handle, amp)
{$ENDIF BASS_AFTER_20 }
  else
    result := false;
  //
  if (result) then
    f_ampLevel := amp;
end;

// --  --
function unaBassMusic.set_channelVol(channel, volume: DWORD): bool;
begin
  if (f_isValid) then
{$IFDEF BASS_AFTER_18 }
  {$IFDEF BASS_AFTER_20 }
    // v 2.1
    result := (DW_ERROR <> f_bass.f_bass.r_musicSetAttribute(handle, BASS_MUSIC_ATTRIB_VOL_CHAN + channel, volume))
  {$ELSE }
    // v 2.0
    result := f_bass.f_bass.r_musicSetVolume(handle, channel, volume)
  {$ENDIF BASS_AFTER_20 }
{$ELSE }
    result := f_bass.f_bass.r_musicSetChannelVol(handle, channel, volume)
{$ENDIF BASS_AFTER_18 }
  else
    result := false;
end;

// --  --
function unaBassMusic.set_panSeparation(pan: DWORD): bool;
begin
  if (f_isValid) then
{$IFDEF BASS_AFTER_20 }
    // v 2.1
    result := (DW_ERROR <> f_bass.f_bass.r_musicSetAttribute(handle, BASS_MUSIC_ATTRIB_PANSEP, pan))
{$ELSE }
    result := f_bass.f_bass.r_musicSetPanSep(handle, pan)
{$ENDIF BASS_AFTER_20 }
  else
    result := false;
  //
  if (result) then
    f_panSep := pan;
end;

// --  --
function unaBassMusic.set_positionScaler(scale: DWORD): bool;
begin
  if (f_isValid) then
{$IFDEF BASS_AFTER_20 }
    // v 2.1
    result := (DW_ERROR <> f_bass.f_bass.r_musicSetAttribute(handle, BASS_MUSIC_ATTRIB_PSCALER, scale))
{$ELSE }
    result := f_bass.f_bass.r_musicSetPositionScaler(handle, scale)
{$ENDIF BASS_AFTER_20 }
  else
    result := false;
end;

// --  --
function unaBassMusic.supportsDSP(): bool;
begin
  result := true;
end;


{ unaBassSample }

// --  --
function unaBassSample.createSample(buf: pointer; len: unsigned; freq, max, flags, chans: DWORD): bool;
var
  sample: pointer;
begin
  result := false;
  //
  if (f_isValid and (nil <> buf)) then begin
    //
  {$IFDEF BASS_AFTER_21 }
    // parameters were fucked in 2.2
    if (0 = chans) then
      chans := choice(0 <> (BASS_SAMPLE_MONO and flags), 1, unsigned(2));
    //
    sample := f_bass.f_bass.r_sampleCreate(len, freq, chans, max, flags);
  {$ELSE }
    sample := f_bass.f_bass.r_sampleCreate(len, freq, max, flags);
  {$ENDIF BASS_AFTER_21 }
    if (nil <> sample) then begin
      //
      move(buf^, sample^, len);
      handle := f_bass.f_bass.r_sampleCreateDone();
      result := (0 <> handle);
    end;
  end;
end;

// --  --
procedure unaBassSample.freeResources();
begin
  sample_free();
  //
  inherited;
end;

// --  --
function unaBassSample.get_info(out info: BASS_SAMPLE): bool;
begin
  if (f_isValid) then
    result := f_bass.f_bass.r_sampleGetInfo(handle, info)
  else
    result := false;
end;

// --  --
function unaBassSample.load(buf: pointer; len, maxOver, flags: DWORD): bool;
begin
  if (f_isValid) then begin
    //
    handle := f_bass.f_bass.r_sampleLoad(true, buf, 0, len, maxOver, flags);
    result := (0 <> handle);
  end
  else
    result := false;
end;

// --  --
function unaBassSample.load(const fileName: wString; offset, maxLength, maxOver, flags: DWORD): bool;
begin
  if (f_isValid) then begin
    //
    handle := f_bass.f_bass.r_sampleLoad(false, paChar(aString(fileName)), offset, maxLength, maxOver, flags);
    result := (0 <> handle);
  end
  else
    result := false;
end;

// --  --
function unaBassSample.play(): HCHANNEL;
begin
  if (f_isValid) then begin
    //
{$IFDEF BASS_AFTER_20 }
    // v 2.1
    result := f_bass.f_bass.r_sampleGetChannel(handle, false);
    //
    if (0 <> result) then
      f_bass.f_bass.r_channelPlay(result, false);
{$ELSE }
    result := f_bass.f_bass.r_samplePlay(handle)
{$ENDIF BASS_AFTER_20 }
  end
  else
    result := 0;
end;

// --  --
function unaBassSample.play3D(const pos, orient, vel: BASS_3DVECTOR): HCHANNEL;
begin
  if (f_isValid) then begin
    //
{$IFDEF BASS_AFTER_20 }
    // v 2.1
    result := f_bass.f_bass.r_sampleGetChannel(handle, false);
    //
    if (0 <> result) then begin
      //
      f_bass.f_bass.r_channelSet3DPosition(result, pos, orient, vel);
      f_bass.f_bass.r_channelPlay(result, false);
    end;
{$ELSE }
    result := f_bass.f_bass.r_samplePlay3D(handle, pos, orient, vel);
{$ENDIF BASS_AFTER_20 }
  end
  else
    result := 0;
end;

// --  --
function unaBassSample.play3DEx(const pos, orient, vel: BASS_3DVECTOR; start: DWORD; freq, volume: Integer; loop: bool): HCHANNEL;
{$IFDEF BASS_AFTER_20 }
var
  info: BASS_CHANNELINFO;
{$ENDIF BASS_AFTER_20 }
begin
  if (f_isValid) then begin
    //
{$IFDEF BASS_AFTER_20 }
    // v 2.1
    result := f_bass.f_bass.r_sampleGetChannel(handle, false);
    //
    if (0 <> result) then begin
      //
      f_bass.f_bass.r_channelSet3DPosition(result, pos, orient, vel);
      f_bass.f_bass.r_channelSetAttributes(result, freq, volume, -101);
      if (loop) then begin
	//
	f_bass.f_bass.r_channelGetInfo(result, info);
	f_bass.f_bass.r_channelSetFlags(result, info.flags or BASS_SAMPLE_LOOP);
      end;
      //
      f_bass.f_bass.r_channelSetPosition(result, start);
      f_bass.f_bass.r_channelPlay(result, false);
    end;
{$ELSE }
    result := f_bass.f_bass.r_samplePlay3DEx(handle, pos, orient, vel, start, freq, volume, loop);
{$ENDIF BASS_AFTER_20 }
  end
  else
    result := 0;
end;

// --  --
function unaBassSample.playEx(start: DWORD; freq, volume, pan: Integer; loop: bool): HCHANNEL;
{$IFDEF BASS_AFTER_20 }
var
  info: BASS_CHANNELINFO;
{$ENDIF }
begin
  if (f_isValid) then begin
    //
{$IFDEF BASS_AFTER_20 }
    // v 2.1
    result := f_bass.f_bass.r_sampleGetChannel(handle, false);
    //
    if (0 <> result) then begin
      //
      f_bass.f_bass.r_channelSetAttributes(result, freq, volume, pan);
      if (loop) then begin
	//
	f_bass.f_bass.r_channelGetInfo(result, info);
	f_bass.f_bass.r_channelSetFlags(result, info.flags or BASS_SAMPLE_LOOP);
      end;
      //
      f_bass.f_bass.r_channelSetPosition(result, start);
      f_bass.f_bass.r_channelPlay(result, false);
    end;
{$ELSE }
    result := f_bass.f_bass.r_samplePlayEx(handle, start, freq, volume, pan, loop);
{$ENDIF BASS_AFTER_20 }
  end
  else
    result := 0;
end;

// --  --
procedure unaBassSample.sample_free();
begin
  if (f_isValid) then
    f_bass.f_bass.r_sampleFree(handle)
end;

// --  --
function unaBassSample.set_info(const info: BASS_SAMPLE): bool;
begin
  if (f_isValid) then
    result := f_bass.f_bass.r_sampleSetInfo(handle, info)
  else
    result := false;
end;

// --  --
function unaBassSample.stop(handle: HSAMPLE): bool;
begin
  if (f_isValid) then
    result := f_bass.f_bass.r_sampleStop(handle)
  else
    result := false;
end;


{ unaBassStream }

// --  --
procedure unaBassStream.closeStream();
begin
  freeResources();
end;

// --  --
function unaBassStream.createStream(const fileName: wString; offset, maxLength, flags: DWORD): bool;
begin
  if (f_isValid) then begin
    handle := f_bass.f_bass.r_streamCreateFile(false, paChar(aString(fileName)), offset, maxLength, flags);
    result := (0 <> handle);
  end
  else
    result := false;
end;

// --  --
function unaBassStream.createStream(data: pointer; len, flags: DWORD): bool;
begin
  if (f_isValid) then begin
    //
    handle := f_bass.f_bass.r_streamCreateFile(true, data, 0, len, flags);
    result := (0 <> handle);
  end
  else
    result := false;
end;

// --  --
function unaBassStream.createStream(freq, flags: DWORD; proc: pointer; user: DWORD): bool;
begin
  if (f_isValid) then begin
{$IFDEF BASS_AFTER_18 }
    handle := f_bass.f_bass.r_streamCreateFileUser(true, flags, proc, user);
{$ELSE }
    handle := f_bass.f_bass.r_streamCreate(freq, flags, proc, user);
{$ENDIF BASS_AFTER_18 }
    result := (0 <> handle);
  end
  else
    result := false;
end;

{$IFDEF BASS_AFTER_18 }

// -- download proc --
procedure myURLDownloadProc(buffer: pointer; length: DWORD; user: DWORD); stdcall;
begin
  if ((0 <> user) and (nil <> buffer) and (0 < length)) then begin
    //
    unaBassStream(user).onDownloadURL(buffer, length);
  end;
end;

{$ENDIF BASS_AFTER_18 }

// --  --
function unaBassStream.createStream(const url: string; offset, flags: DWORD; const localCopy: string): bool;
begin
  if (f_isValid) then begin
    //
{$IFDEF BASS_AFTER_18 }
    // fucked up in 2.0
    handle := f_bass.f_bass.r_streamCreateURL(paChar(aString(url)), offset, flags, myURLDownloadProc, DWORD(self));
{$ELSE }
    handle := f_bass.f_bass.r_streamCreateURL(paChar(aString(url)), offset, flags, pStrA(localCopy));
{$ENDIF BASS_AFTER_18 }
    result := (0 <> handle);
  end
  else
    result := false;
end;

// --  --
procedure unaBassStream.freeResources();
begin
  stream_free();
  //
  inherited;
end;

// --  --
function unaBassStream.get_filePosition(mode: DWORD): DWORD;
begin
  if (f_isValid) then
    result := f_bass.f_bass.r_streamGetFilePosition(handle, mode)
  else
    result := 0;
end;

// --  --
function unaBassStream.get_length(): QWORD;
begin
  if (f_isValid) then
{$IFDEF BASS_AFTER_21 }
    //
    { 2.2
      BASS_StreamGetLength, BASS_MusicGetLength
      //
      These functions have been merged into BASS_ChannelGetLength, which gives the byte length of a channel.
      To get the number of orders in a MOD music, BASS_MusicGetOrders has been added.
      Also note that requesting the length when streaming in blocks will now result in a BASS_ERROR_NOTAVAIL error, instead of just 0.
    }
    result := f_bass.f_bass.r_channelGetLength(handle)
{$ELSE }
    result := f_bass.f_bass.r_streamGetLength(handle)
{$ENDIF BASS_AFTER_21 }
  else
    result := 0;
end;

// --  --
function unaBassStream.get_tags(tags: DWORD): pAnsiChar;
begin
  if (f_isValid) then
{$IFDEF BASS_AFTER_22 }
    result := f_bass.f_bass.r_channelGetTags(handle, tags)
{$ELSE }
    result := f_bass.f_bass.r_streamGetTags(handle, tags)
{$ENDIF BASS_AFTER_22 }
  else
    result := nil;
end;

// --  --
function unaBassStream.isOpen(): bool;
begin
  result := (0 <> handle);
end;

{$IFDEF BASS_AFTER_18 }

// --  --
procedure unaBassStream.onDownloadURL(buf: pointer; len: unsigned);
begin
  // override to do something with downloaded bytes
end;

{$ENDIF BASS_AFTER_18 }

// --  --
function unaBassStream.play(flush: bool; flags: DWORD): bool;
begin
  if (f_isValid) then begin
    //
{$IFDEF BASS_AFTER_20 }
    //
    result := f_bass.f_bass.r_channelSetFlags(handle, flags);
    result := result and f_bass.f_bass.r_channelPlay(handle, false);
{$ELSE }
    result := f_bass.f_bass.r_streamPlay(handle, flush, flags);
{$ENDIF BASS_AFTER_20 }
  end
  else
    result := false;
end;

// --  --
function unaBassStream.preBuf(len: DWORD): bool;
begin
  if (f_isValid) then
{$IFDEF BASS_AFTER_20 }
  {$IFDEF BASS_AFTER_21 }
    // parameters were fucked in 2.2
    result := f_bass.f_bass.r_channelPreBuf(handle, len)
  {$ELSE }
    // v 2.1
    result := f_bass.f_bass.r_channelPreBuf(handle)
  {$ENDIF BASS_AFTER_21 }
{$ELSE }
    result := f_bass.f_bass.r_streamPreBuf(handle)
{$ENDIF BASS_AFTER_20 }
  else
    result := false;
end;

// --  --
procedure unaBassStream.stream_free();
begin
  if (f_isValid) then
    f_bass.f_bass.r_streamFree(handle);
end;


{ unaBassChannel }

// --  --
procedure unaBassChannel.freeResources();
begin
  // nothing here
  inherited;
end;

// --  --
function unaBassChannel.FX_get_parameters(fx: HFX; par: pointer): bool;
begin
  if (f_isValid) then
    result := f_bass.f_bass.r_FXGetParameters(fx, par)
  else
    result := false;
end;

// --  --
function unaBassChannel.FX_set_parameters(fx: HFX; par: pointer): bool;
begin
  if (f_isValid) then
    result := f_bass.f_bass.r_FXSetParameters(fx, par)
  else
    result := false;
end;

// --  --
function unaBassChannel.get_3DAttributes(out mode: int32; out min, max: Single; out iangle, oangle, outvol: int32): bool;
begin
  if (f_isValid) then
    result := f_bass.f_bass.r_channelGet3DAttributes(handle, mode, min, max, iangle, oangle, outvol)
  else
    result := false;
end;

// --  --
function unaBassChannel.get_3DPosition(out pos, orient, vel: BASS_3DVECTOR): bool;
begin
  if (f_isValid) then
    result := f_bass.f_bass.r_channelGet3DPosition(handle, pos, orient, vel)
  else
    result := false;
end;

// --  --
function unaBassChannel.get_attributes(out freq, volume, pan: int32): bool;
begin
  if (f_isValid) then
    result := f_bass.f_bass.r_channelGetAttributes(handle, freq, volume, pan)
  else
    result := false;
end;

// --  --
function unaBassChannel.get_data(buf: pointer; len: DWORD): int;
begin
  if (f_isValid) then
    result := int(f_bass.f_bass.r_channelGetData(handle, buf, len))
  else
    result := -1;
end;

// --  --
function unaBassChannel.get_dataAvailSize(): int;
begin
  if (f_isValid) then
    result := int(f_bass.f_bass.r_channelGetData(handle, nil, BASS_DATA_AVAILABLE))
  else
    result := -1;
end;

// --  --
function unaBassChannel.get_EAXMix(out mix: Single): bool;
begin
  if (f_isValid) then
    result := f_bass.f_bass.r_channelGetEAXMix(handle, mix)
  else
    result := false;
end;

// --  --
function unaBassChannel.get_flags(): DWORD;
{$IFDEF BASS_AFTER_18 }
var
  info: BASS_CHANNELINFO;
{$ENDIF BASS_AFTER_18 }
begin
  if (f_isValid) then begin
{$IFDEF BASS_AFTER_18 }
    //
    result := 0;
    //
    if (f_bass.f_bass.r_channelGetInfo(handle, info)) then begin
      //
      // flags may incorrectly not include BASS_SAMPLE_MONO flags even for 1-channel streams
      if (1 = info.chans) then
	info.flags := info.flags or BASS_SAMPLE_MONO;
      //
      result := info.flags;
    end;
{$ELSE }
    result := f_bass.f_bass.r_channelGetFlags(handle)
{$ENDIF BASS_AFTER_18 }
  end
  else
    result := 0;
end;

// --  --
function unaBassChannel.get_isActive(): DWORD;
begin
  if (f_isValid) then
    result := f_bass.f_bass.r_channelIsActive(handle)
  else
    result := 0;
end;

// --  --
function unaBassChannel.get_isSliding(): DWORD;
begin
  if (f_isValid) then
    result := f_bass.f_bass.r_channelIsSliding(handle)
  else
    result := 0;
end;

// --  --
function unaBassChannel.get_level(): DWORD;
begin
  if (f_isValid) then
    result := f_bass.f_bass.r_channelGetLevel(handle)
  else
    result := 0;
end;

// --  --
function unaBassChannel.get_position(orderRow: bool): QWORD;
begin
  if (f_isValid) then
{$IFDEF BASS_AFTER_21 }
    // fucked in 2.2
    if (orderRow) then
      result := f_bass.f_bass.r_musicGetOrderPosition(handle)
    else
      result := f_bass.f_bass.r_channelGetPosition(handle)
{$ELSE }
    result := f_bass.f_bass.r_channelGetPosition(handle)
{$ENDIF BASS_AFTER_21 }
  else
    result := 0;
end;

{$IFDEF BASS_AFTER_22 }

// --  --
function unaBassChannel.get_tags(handle, tags: DWORD): pAnsiChar;
begin
  if (f_isValid) then
    result := f_bass.f_bass.r_channelGetTags(handle, tags)
  else
    result := nil;
end;

{$ENDIF BASS_AFTER_22 }	// after 2.2

// --  --
function unaBassChannel.init(channel: HCHANNEL): bool;
begin
  handle := channel;
  result := true;
end;

// --  --
function unaBassChannel.pause(): bool;
begin
  if (f_isValid) then
    result := f_bass.f_bass.r_channelPause(handle)
  else
    result := false;
end;

// --  --
function unaBassChannel.remove_DSP(dsp: HDSP): bool;
begin
  if (f_isValid) then
    result := f_bass.f_bass.r_channelRemoveDSP(handle, dsp)
  else
    result := false;
end;

// --  --
function unaBassChannel.remove_FX(fx: HFX): bool;
begin
  if (f_isValid) then
    result := f_bass.f_bass.r_channelRemoveFX(handle, fx)
  else
    result := false;
end;

// --  --
function unaBassChannel.remove_link(chan: DWORD): bool;
begin
  if (f_isValid) then
    result := f_bass.f_bass.r_channelRemoveLink(handle, chan)
  else
    result := false;
end;

// --  --
function unaBassChannel.remove_sync(sync: HSYNC): bool;
begin
  if (f_isValid) then
    result := f_bass.f_bass.r_channelRemoveSync(handle, sync)
  else
    result := false;
end;

// --  --
function unaBassChannel.resume(): bool;
begin
  if (f_isValid) then
{$IFDEF BASS_AFTER_20 }
    // v 2.1
    result := f_bass.f_bass.r_channelPlay(handle, false)
{$ELSE }
    result := f_bass.f_bass.r_channelResume(handle)
{$ENDIF BASS_AFTER_20 }
  else
    result := false;
end;

// --  --
function unaBassChannel.set_3DAttributes(const mode: int; min, max: Single; iangle, oangle, outvol: int32): bool;
begin
  if (f_isValid) then
    result := f_bass.f_bass.r_channelSet3DAttributes(handle, mode, min, max, iangle, oangle, outvol)
  else
    result := false;
end;

// --  --
function unaBassChannel.set_3DPosition(const pos, orient, vel: BASS_3DVECTOR): bool;
begin
  if (f_isValid) then
    result := f_bass.f_bass.r_channelSet3DPosition(handle, pos, orient, vel)
  else
    result := false;
end;

// --  --
function unaBassChannel.set_attributes(freq, volume, pan: int): bool;
begin
  if (f_isValid) then
    result := f_bass.f_bass.r_channelSetAttributes(handle, freq, volume, pan)
  else
    result := false;
end;

// --  --
function unaBassChannel.set_DSP(proc: DSPPROC; user: DWORD): HDSP;
begin
  if (f_isValid) then
{$IFDEF BASS_AFTER_18 }
    result := f_bass.f_bass.r_channelSetDSP(handle, proc, user, 0)
{$ELSE }
    result := f_bass.f_bass.r_channelSetDSP(handle, proc, user)
{$ENDIF BASS_AFTER_18 }
  else
    result := 0;
end;

// --  --
function unaBassChannel.set_EAXMix(const mix: Single): bool;
begin
  if (f_isValid) then
    result := f_bass.f_bass.r_channelSetEAXMix(handle, mix)
  else
    result := false;
end;

// --  --
function unaBassChannel.set_FX(etype: DWORD; priority: int): HFX;
begin
  if (f_isValid) then
{$IFDEF BASS_AFTER_20 }
    // v 2.1
    result := f_bass.f_bass.r_channelSetFX(handle, etype, priority)
{$ELSE }
    result := f_bass.f_bass.r_channelSetFX(handle, etype)
{$ENDIF BASS_AFTER_20 }
  else
    result := 0;
end;

// --  --
function unaBassChannel.set_link(chan: DWORD): bool;
begin
  if (f_isValid) then
    result := f_bass.f_bass.r_channelSetLink(handle, chan)
  else
    result := false;
end;

// --  --
function unaBassChannel.set_position(RO: QWORD; orderRow: bool): bool;
begin
  if (f_isValid) then
{$IFDEF BASS_AFTER_21 }
    // fucked in 2.2
    if (orderRow) then
      // RO is Row/Order
      result := f_bass.f_bass.r_channelSetPosition(handle, RO)
    else
      // RO is bytes
      result := f_bass.f_bass.r_channelSetPosition(handle, RO)
{$ELSE }
    if (orderRow) then
      // RO is Row/Order
      result := f_bass.f_bass.r_channelSetPosition(handle, RO)
    else
      // RO is seconds
      result := f_bass.f_bass.r_channelSetPosition(handle, ($FFFF shl 16) or (RO and $FFFF))
{$ENDIF BASS_AFTER_21 }
  else
    result := false;
end;

// --  --
function unaBassChannel.set_slideAttributes(freq, volume, pan: Integer; time: DWORD): bool;
begin
  if (f_isValid) then
    result := f_bass.f_bass.r_channelSlideAttributes(handle, freq, volume, pan, time)
  else
    result := false;
end;

// --  --
function unaBassChannel.set_sync(atype: DWORD; param: QWORD; proc: SYNCPROC; user: DWORD): HSYNC;
begin
  if (f_isValid) then
    result := f_bass.f_bass.r_channelSetSync(handle, atype, param, proc, user)
  else
    result := 0;
end;

// --  --
function unaBassChannel.stop(): bool;
begin
  if (f_isValid) then
    result := f_bass.f_bass.r_channelStop(handle)
  else
    result := false;
end;


// ------- BASS stream decoder -------

{$IFDEF CPU64 }
// who needs this stuff anyways..
{$ELSE }

// --  --
function bassStreamFileProc(action, param1, param2, user: DWORD): DWORD; stdcall;
var
  readSize: unsigned;
  mark: uint64;
  total: uint32;
  decoder: unaBassStreamDecoder;
begin
  result := 0;
  decoder := unaBassStreamDecoder(user);
  //
  case (action) of

    BASS_FILE_CLOSE: begin
      //
      //assert(logMessage('BASS_FILE_CLOSE'));
    end;

    BASS_FILE_READ: begin
      //
      total := 0;
      mark := timeMarkU();
      //
      //assert(debugMessage('BASS_FILE_READ: BASS wants to read ' + int2str(param1) + ' bytes, buf=$' + adjust(int2str(param2, 16), 8, '0') + ''));
      repeat
	//
	with (decoder.f_dataStream) do begin
	  //
	  if (waitForData(20)) then begin
	    //
	    readSize := read(@pArray(param2)[total], int(param1 - total));
	    inc(total, readSize);
	    //
	    //assert(debugMessage('Read ' + int2str(readSize) + ' bytes, in this call so far: ' + int2str(total) + ' bytes.'));
	  end
	  else begin
	    //
	    if ((0 = decoder.dataTimeout) or (decoder.dataTimeout < timeElapsed64U(mark))) then
	      break;
	    //
	  end;
	end;
	//
      until (decoder.shouldStop or (total >= param1));
      //
      result := total;
      //
      //assert(debugMessage('About to return ' + int2str(result) + ' bytes to BASS.'));
    end;

    BASS_FILE_QUERY: begin
      //
      //assert(debugMessage('BASS_FILE_QUERY: enter, BASS wants max. ' + int2str(param1) + ' bytes.'));
      //
      mark := timeMarkU();
      while (int(param1) > decoder.f_dataStream.getAvailableSize()) do begin
	//
	if (decoder.shouldStop) then begin
	  //
	  break;
	end;
	//
	decoder.f_dataStream.waitForData(20);
	//
	if ((0 = decoder.dataTimeout) or (decoder.dataTimeout < timeElapsed64U(mark))) then
	  break;
	//
      end;
      //
      result := min(param1, decoder.f_dataStream.getAvailableSize());	//
      //
      //assert(debugMessage('BASS_FILE_QUERY: returns: ' + int2str(result) + ' bytes are available.'));
    end;

    BASS_FILE_LEN: begin
      //
      //assert(debugMessage('BASS_FILE_LEN: returns: ' + int2str(result) + ' bytes are available.'));
    end;

  end;
end;

{$ENDIF CPU64 }

{ unaBassStreamDecoder }

// --  --
procedure unaBassStreamDecoder.applySampling(rate, bits, channels: unsigned);
begin
  if (assigned(f_onAS)) then
    f_onAS(self, rate, bits, channels);
end;

// --  --
procedure unaBassStreamDecoder.BeforeDestruction();
begin
  inherited;
  //
  f_bassStream := nil;
  f_dataStream := nil;
end;

// --  --
constructor unaBassStreamDecoder.create(bassStream: unaBassStream; dataStream: unaAbstractStream; dataTimeout: tTimeout);
begin
  f_bassStream := bassStream;
  f_dataStream := dataStream;
  //
  f_dataTimeout := dataTimeout;
  //
  inherited create(false, THREAD_PRIORITY_TIME_CRITICAL);
end;

// --  --
procedure unaBassStreamDecoder.dataAvailable(data: pointer; size: unsigned);
begin
  if (assigned(f_onDA)) then
    f_onDA(self, data, size);
end;

// --  --
function unaBassStreamDecoder.execute(threadId: unsigned): int;
var
  availBytes: int;
  localBuf: pointer;
  localBufSize: unsigned;
  //
  freq, volume, pan: int32;
  flags: DWORD;
  rate, bits, channels: unsigned;
  rate2, bits2, channels2: unsigned;
begin
  if (not shouldStop) then
{$IFDEF BASS_AFTER_18 }
{$IFDEF CPU64 }
    begin
      result := 0;
      exit;
    end;
{$ELSE }
    f_bassStream.createStream(0, BASS_STREAM_DECODE, @bassStreamFileProc, DWORD(self));
{$ENDIF CPU64 }
{$ELSE }
    f_bassStream.createStream(0, BASS_STREAM_DECODE or BASS_STREAM_FILEPROC, @bassStreamFileProc, DWORD(self));
{$ENDIF BASS_AFTER_18 }
  //
  localBufSize := $1000;
  localBuf := malloc(localBufSize);
  //
  rate2 := 0;
  bits2 := 0;
  channels2 := 0;
  //
  while (not shouldStop) do begin
    //
    sleep(10);
    //
    // read from BASS uncomressed data
    if (f_bassStream.isOpen()) then begin
      //
      repeat
	//
	availBytes := f_bassStream.asChannel.get_data(localBuf, localBufSize);
	if (0 < availBytes) then begin
	  //
	  // write decoded data
	  f_bassStream.asChannel.get_attributes(freq, volume, pan);
	  flags := f_bassStream.asChannel.get_flags();
	  //
	  rate := freq;
	  //
	  if (0 <> (BASS_SAMPLE_8BITS and flags)) then
	    bits := 8
	  else
	    bits := 16;
	  //
	  if (0 <> (BASS_SAMPLE_MONO and flags)) then
	    channels := 1
	  else
	    channels := 2;
	  //
	  if (rate <> rate2) or (bits <> bits2) or (channels <> channels2) then begin
	    //
	    rate2 := rate;
	    bits2 := bits;
	    channels2 := channels;
	    //
	    applySampling(rate, bits, channels);
	  end;
	  //
	  dataAvailable(localBuf, availBytes);
	end
	else
	  sleepThread(10);	// OCT 2003
	//
      until (shouldStop or (availBytes < $100));
    end
    else
      break;
    //
  end;
  //
  mrealloc(localBuf);
  //
  result := 0;
end;

// --  --
procedure unaBassStreamDecoder.startOut();
begin
  inherited;
  //
  f_bassStream.closeStream();
end;


{ unaBassDecoder }

// --  --
procedure unaBassDecoder.AfterConstruction();
begin
  inherited;
  //
  f_dataStream := unaMemoryStream.create();
  f_dataStream.maxCacheSize := 55;
  //
  updateConfig(libName);
end;

// --  --
procedure unaBassDecoder.BeforeDestruction();
begin
  close();
  //
  freeAndNil(f_bassStreamThread);
  freeAndNil(f_bassStream);
  freeAndNil(f_bass);
  freeAndNil(f_dataStream);
  //
  inherited;
end;

// --  --
procedure unaBassDecoder.close();
begin
  if (nil <> f_bass) then begin
    // clear data stream
    f_dataStream.clear();
    f_bassStreamThread.stop();
  end;
end;

// --  --
constructor unaBassDecoder.create(const libName: wString);
begin
  inherited create();
  //
  f_libName := libName;
end;

// --  --
procedure unaBassDecoder.open();
begin
  if ((nil <> f_bass) and (BASS_OK = bassError)) then begin
    // clear data stream
    f_dataStream.clear();
  end;
end;

// --  --
procedure unaBassDecoder.updateConfig(const libName: wString);
begin
  freeAndNil(f_bassStreamThread);
  freeAndNil(f_bassStream);
  freeAndNil(f_bass);
  //
  f_bass := unaBass.create(libName, -2, 44100{doesn't matter?}, BASS_DEVICE_NOTHREAD);
  f_bassError := f_bass.get_errorCode();
  if (BASS_OK = f_bassError) then begin
    //
    f_bassStream := unaBassStream.create(f_bass);
    f_bassStreamThread := unaBassStreamDecoder.create(f_bassStream, f_dataStream);
    //
  end
  else begin
    //
    f_bassError := -1;
    freeAndNil(f_bass);
  end;
end;

// --  --
procedure unaBassDecoder.write(data: pointer; len: unsigned);
begin
  f_dataStream.write(data, len);
  //
  f_bassStreamThread.start();
end;




{ una_openH323plugin }

// --  --
procedure una_openH323plugin.AfterConstruction();
begin
  loadDLL();
  //
  inherited;
end;

// --  --
procedure una_openH323plugin.BeforeDestruction();
begin
  inherited;
  //
  unloadDLL();
end;

// --  --
constructor una_openH323plugin.create(const dllPathAndName: wString; priority: integer);
begin
  f_libName := dllPathAndName;
  //
  f_codecIndex := -1;
  //
  inherited create(priority);
end;

// --  --
function una_openH323plugin.doClose(): UNA_ENCODER_ERR;
begin
  if (nil <> f_codec) then begin
    //
    if (nil <> f_context) then
      f_codec.destroyCodec(f_codec, f_context);
    //
    f_context := nil;
    f_codec := nil;
    f_codecIndex := -1; 
  end;
  //
  result := BE_ERR_SUCCESSFUL;
end;

// --  --
function una_openH323plugin.doEncode(data: pointer; nBytes: unsigned; out bytesUsed: unsigned): UNA_ENCODER_ERR;
var
  res: int;
  flags: uint32;
  fromLen: uint32;
  destLen: uint32;
begin
  if ((nil <> f_codec) and (nil <> f_context)) then begin
    //
    flags := 0;
    fromLen := nBytes;
    destLen := f_outBufSize;
    //
    res := f_codec.codecFunction(f_codec, f_context, data, fromLen, f_outBuf, destLen, flags);
    if (0 <> res) then begin
      //
      bytesUsed := fromLen;
      f_outBufUsed := destLen;
      //
      result := BE_ERR_SUCCESSFUL;
    end
    else
      result := BE_ERR_BUFFER_TOO_SMALL;
    //
  end
  else
    result := BE_ERR_INVALID_FORMAT;
end;

// --  --
function una_openH323plugin.doOpen(): UNA_ENCODER_ERR;
begin
  doClose();	 // just in case
  //
  if ((0 <= f_codecIndex) and (f_codecIndex < int(codecDefCount))) then begin
    //
    f_codec := codecDef[f_codecIndex];
    f_context := f_codec.createCodec(f_codec);
    //
    result := BE_ERR_SUCCESSFUL;
  end
  else
    result := BE_ERR_INVALID_FORMAT;
end;

// --  --                                       
function una_openH323plugin.doSetConfig(config: pointer): UNA_ENCODER_ERR;
var
  index: int;
begin
  index := int(config);
  //
  if ((0 <= index) and (index < int(codecDefCount))) then begin
    //
    if (isEncoder(index)) then begin
      //
      f_inputChunkSize := codecDef[index].samplesPerFrame shl 1;	// all streams are 16 bits mono
      f_minOutputBufSize := codecDef[index].bytesPerFrame;
    end
    else begin
      //
      f_minOutputBufSize := codecDef[index].samplesPerFrame shl 1;	// all streams are 16 bits mono
      f_inputChunkSize := codecDef[index].bytesPerFrame;
    end;
    //
    result := BE_ERR_SUCCESSFUL;
  end
  else
    result := BE_ERR_INVALID_FORMAT;
end;

// --  --
function una_openH323plugin.getCodecDef(index: int): ppluginCodec_definition;
begin
  if (index < int(f_codecDefCnt)) then
    //
    result := @f_codecDefRoot[index]
  else
    result := nil;
end;

// --  --
function una_openH323plugin.getVersion(): int;
begin
  if (f_procOK) then
    result := f_ilbcProc.rproc_getAPIVersionFunction()
  else
    result := -1;
end;

// --  --
function una_openH323plugin.isEncoder(index: int): bool;
begin
  if (0 > index) then
    index := codecIndex;
  //
  if (((0 <= index) and (index < int(codecDefCount))) or (nil <> f_codec)) then begin
    //
    if (nil <> f_codec) then
      result := ('L16' = trimS(f_codec.sourceFormat))
    else
      result := ('L16' = trimS(codecDef[index].sourceFormat))
    //
  end
  else
    result := false;
end;

// --  --
function una_openH323plugin.loadDLL(): int;
begin
  result := plugin_loadDLL(f_ilbcProc, f_libname);
  //                                stdcall
  if (0 = result) then
    f_errorCode := BE_ERR_SUCCESSFUL
  else
    f_errorCode := UNA_ENCODER_ERR_NO_DLL;
  //
  f_procOK := (BE_ERR_SUCCESSFUL = f_errorCode);
  //
  if (f_procOK) then
    pointer(f_codecDefRoot) := f_ilbcProc.rproc_getCodecFunction(f_codecDefCnt, PLUGIN_CODEC_VERSION);
end;

// --  --
function una_openH323plugin.selectCodec(index: int): UNA_ENCODER_ERR;
begin
  if (not f_configOK or (f_codecIndex <> index)) then begin
    //
    result := setConfig(pointer(index));
    //
    if (BE_ERR_SUCCESSFUL = result) then
      f_codecIndex := index
    else
      f_codecIndex := -1;
    //
  end
  else
    result := BE_ERR_SUCCESSFUL;
end;

// --  --
procedure una_openH323plugin.setCodecIndex(value: int);
begin
  selectCodec(value);
end;

// --  --
function una_openH323plugin.unloadDLL(): int;
begin
  result := plugin_unloadDLL(f_ilbcProc);
end;


end.

