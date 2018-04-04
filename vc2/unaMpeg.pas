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

	  unaMpeg.pas
	  MPEG Frame parsers

	----------------------------------------------
	  Copyright (c) 2008-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 19 June 2008

	  modified by:
		Lake, June-July 2008
                Lake, Jun 2009
		Lake, Jul 2010
		lake, Apr 2011

	----------------------------------------------
*)

{$I unaDef.inc }

{$IFDEF DEBUG }
  {$DEFINE LOG_UNAMPEGAUDIO_INFOS }	// log informational messages
  {$DEFINE LOG_UNAMPEGAUDIO_ERRORS }	// log critical error messages
  {x $DEFINE LOG_UNAMPEGAUDIO_TSX }	// log MPEG-TS extra info
{$ENDIF DEBUG }

{*
  MPEG frame parsers.

  @Author Lake

	2.5.2009.06	- initial release

	2.5.2011.08 	- more versatile demuxer
}

unit
  unaMpeg;

interface

uses
  Windows, unaTypes, unaClasses;

const
  {*
  Defines various MP3 bitrates:
   - first index is 1 for MPEG1, 2 for MPEG2, 3 for MPEG2.5
   - second index is [header.bitrate_index] field
   - third index is 1 (layer I), 2 (layer II) or 3 (layer III)
  }
  c_mpeg_bitrate: array[1..3, 0..14, 1..3] of int =
    (
     // MPEG1
     (
// LAYER 1    2    3
      (  0,   0,   0),
      ( 32,  32,  32),
      ( 64,  48,  40),
      ( 96,  56,  48),
      (128,  64,  56),
      (160,  80,  64),
      (192,  96,  80),
      (224, 112,  96),
      (256, 128, 112),
      (288, 160, 128),
      (320, 192, 160),
      (352, 224, 192),
      (384, 256, 224),
      (416, 320, 256),
      (448, 384, 320)
     ),

     // MPEG2
     (
// LAYER 1    2    3
      (  0,   0,   0),
      ( 32,   8,   8),
      ( 48,  16,  16),
      ( 56,  24,  24),
      ( 64,  32,  32),
      ( 80,  40,  40),
      ( 96,  48,  48),
      (112,  56,  56),
      (128,  64,  64),
      (144,  80,  80),
      (160,  96,  96),
      (176, 112, 112),
      (192, 128, 128),
      (224, 144, 144),
      (256, 160, 160)
     ),

     // MPEG2.5
     (
// LAYER 1    2    3
      (  0,   0,   0),
      ( 32,   8,   8),
      ( 48,  16,  16),
      ( 56,  24,  24),
      ( 64,  32,  32),
      ( 80,  40,  40),
      ( 96,  48,  48),
      (112,  56,  56),
      (128,  64,  64),
      (144,  80,  80),
      (160,  96,  96),
      (176, 112, 112),
      (192, 128, 128),
      (224, 144, 144),
      (256, 160, 160)
     )

    );

  {*
  Defines sampling rates for MPEG audio frame:
   - first index is 1 for MPEG1, 2 for MPEG2, 3 for MPEG2.5
   - second index is [header.sampling_frequency] field
  }
  c_mpegFreq: array[1..3, 0..3] of int =
    (
     // MPEG1
     (44100, 48000, 32000, 0),
     // MPEG2
     (22050, 24000, 16000, 0),
     // MPEG2.5
     (11025, 12000, 8000, 0)
    );


type
  {*
	Abstract base class for bit-reader.
	Provides methods like EOF(), nextBits() and skipBytes().
  }
  unaBitReader_abstract = class(unaObject)
  private
    f_bitOfs: int64;
    //
    f_sb: pArray;
    f_sbAllocated: bool;
    f_sbSize: int;
    f_sbOfs: int;
    //
    f_outfill: bool;
    f_outfillOfs: int;
    f_outfillBuf: pArray;
    //
    procedure pushOutfill(numBytes: int = 1);
    //
    function getIsEOF(): bool;
    //
    procedure setOutfill(value: bool);
  protected
    procedure sbAssign(v: pointer; sz: int);
    procedure sbAlloc(sz: int; append: bool);
    {*
	Returns pointer on internal bytes

	@param at Offset, or -1 = at f_subBufSize; -2 = at f_subBufOfs. Default is -2
	@return pointer to offset in subbuffer
    }
    function sbAt(at: int = -2): pointer;
    function sbLeft(): int;
    procedure sbIncrease(delta: int);
    //
    {*
	Checks if end of file/stream is reached.

	@param numBits Number of bits parsers expects to read.

	@return True if given number of bits cannot be read or False otherwise.
    }
    function EOF(numBits: unsigned = 8): bool; virtual; abstract;
    {*
	Fills subBuf with new portion of data.
	subBufSize is set to size of data addressed by subBuf.
	subBufOfs is set to zero.
    }
    procedure readSubBuf(reqSize: int = -1; append: bool = false); virtual; abstract;
    {*
	Cleans up the reader.
    }
    procedure doRestart(); virtual;
  public
    {*

    }
    procedure BeforeDestruction(); override;
    {*
	Reads given number of bits from buffer.

	@param numBits Number of bits parsers wants to read. Must be from 1 to 32.

	@return Bitstream from buffer.
    }
    function nextBits(numBits: unsigned = 8): uint32;
    {*
	Reads given number of bytes into buffer.

	@param numBytes Number of bits parsers wants to read.
	@param buf Buffer to be filled with bytes

	@return Actual number of bytes read.
    }
    function readBytes(numBytes: int; buf: pointer): uint32;
    {*
	Skips given number of bytes.

	@param numBytes Number of bytes parsers wants to skip.
    }
    procedure skipBytes(numBytes: unsigned);
    {*
	Skips all bits till next byte, making sure next bit-read will start from byte boundary.
    }
    procedure skipToByte();
    {*
	Cleans up the reader/parser before new file/stream.
    }
    procedure restart();
    {*
	Set outfill buffer.
    }
    procedure setOutfillBuf(buf: pointer);
    {*
	Reset outfill buffer/offset.
    }
    procedure resetOutfillBuf();
    {*
	Moves bit position.
    }
    procedure moveBitOfs(delta: int);
    //
    // -- properties --
    //
    {*
	When outfill is true, all reading/skipping will fill the outfill buffer as well.
    }
    property outfill: bool read f_outfill write setOutfill;
    {*
	Offset in outfill buffer
    }
    property outfillOfs: int read f_outfillOfs;
    {*
    }
    property bytesLeft: int read sbLeft;
    {*
	True if end of stream/file is reached, False otherwise.
    }
    property isEOF: bool read getIsEOF;
    {*
	Current offset in bits from beginning of file/stream.
    }
    property bitOfs: int64 read f_bitOfs;
  end;


  {*
	Bit-reader based on file storage.
  }
  unaBitReader_file = class(unaBitReader_abstract)
  private
    f_f: tHandle;
    f_fsizeBits: int64;
    f_mf: unaMappedFile;
    f_mfLastMap: pointer;
  protected
    {*
	Checks if end of file is reached.
    }
    function EOF(numBits: unsigned = 8): bool; override;
    {*
	Reads next portion of bytes from file.
    }
    procedure readSubBuf(reqSize: int = -1; append: bool = false); override;
    {*
	Cleans up the reader.
    }
    procedure doRestart(); override;
  public
    {*
	Creates bit-readed based on buffered file operations.

	@param fileName Name of file to be opened for reading.
    }
    constructor create(const fileName: wideString); overload;
    {*
	Creates bit-readed based on mapped file object.

	@param mf Mapped file object to be used for reading.
    }
    constructor create(mf: unaMappedFile); overload;
    {*
	Cleans up the instance.
    }
    procedure BeforeDestruction(); override;
  end;


  {*
	Bit-reader based on streaming.
  }
  unaBitReader_stream = class(unaBitReader_abstract)
  private
    f_stream: unaMemoryStream;
  protected
    {*
	Returns True if end of stream reached.
	Most streams may never ends, until closed.
    }
    function EOF(numBits: unsigned = 8): bool; override;
    {*
	Reads next portion of data from stream.
    }
    procedure readSubBuf(reqSize: int = -1; append: bool = false); override;
    {*
	Provides callback-like notification for streamer when more data is needed.
	Streamer must push some bytes using write() method.

	@param size Number of bytes parser may expect to read. Streamer may provide more or less bytes.
    }
    procedure needMoreData(size: int); virtual;
    {*
	Cleans up the reader.
    }
    procedure doRestart(); override;
  public
    {*
    }
    constructor create();
    {*
    }
    procedure BeforeDestruction(); override;
    {*
	Pushes new data into stream, making it available for parser.

	@param data Data buffer.
	@param size Number of bytes pointed by data buffer.
    }
    procedure write(data: pointer; size: int);
  end;


// ----------
// == MPEG ==
// ----------

  {*
	MPEG Audio header.
  }
  unaMpegHeader = packed record
    //
    ID,
    layer,
    protection_bit,
    bitrate_index,
    sampling_frequency,
    padding_bit,
    private_bit,
    mode,
    mode_extension,
    copyright,
    originalCopy,
    emphasis: byte;
    // optional
    crc: uint16;
  end;


  {*
	MPEG audio frame parser.
	Supports MPEG1 and MPEG2 layer I, II and III frames.
  }
  unaMpegAudio_layer123 = class(unaObject)
  private
    f_reader: unaBitReader_abstract;
    //
    f_cMpegID: int;
    f_cSamplingRate: int;
    f_cLayer: int;
    //
    f_mpgSPF: int;
    f_mpgSR: int;
    f_mpgLayer: int;
    f_mpgChannels: int;
    f_mpgID: int;
    //
    {
    scfsi: array[0..1, 0..3] of int;
    part2_3_length: array[0..1, 0..1] of int;
    big_values: array[0..1, 0..1] of int;
    global_gain: array[0..1, 0..1] of int;
    scalefac_compress: array[0..1, 0..1] of int;
    window_switching_flag: array[0..1, 0..1] of int;
    block_type: array[0..1, 0..1] of int;
    mixed_block_flag: array[0..1, 0..1] of int;
    table_select: array[0..1, 0..1, 0..2] of int;
    subblock_gain: array[0..1, 0..1, 0..2] of int;
    region0_count: array[0..1, 0..1] of int;
    region1_count: array[0..1, 0..1] of int;
    preflag: array[0..1, 0..1] of int;
    scalefac_scale: array[0..1, 0..1] of int;
    count1table_select: array[0..1, 0..1] of int;
    }
    //
    function readHeader(var h: unaMpegHeader): unsigned;
    function error_check(var h: unaMpegHeader): HRESULT;
    function crc_check(var h: unaMpegHeader): HRESULT;
  protected
    {*
	Parses audio part of a frame.
    }
    procedure audio_data(const h: unaMpegHeader); virtual;
    {*
	Parses ancillary part of a frame.
    }
    procedure ancillary_data(const h: unaMpegHeader); virtual;
  public
    {*
	Creates MPEG audio parser.

	@param reader Bit-reader which provides audio data for parser.
    }
    constructor create(reader: unaBitReader_abstract);
    {*
	Tries to locate and read next audio frame from bitstream.

	@param h MPEG audio frame header.
	@param foundAt [OUT] Offset in bytes from beginning of stream where frame header was found.
	@param skipOnResynch [OUT] Number of bytes skipped before frame.
	@param outBuf [OUT] Pointer to buffer to be filled with frame data. Could be nil.
	@param frameSize [OUT] Size of frame in bytes.

	@return S_OK if frame was found, -1 otherwise.
    }
    function nextFrame(var h: unaMpegHeader; out foundAt: int64; out skipOnResynch: int; outBuf: pointer; out frameSize: int; panicOnSmallBuf: bool = false): HRESULT;
    {*
	Bit-reader provided to parser.
    }
    property reader: unaBitReader_abstract read f_reader;
    {*
	Number of samples per frame.
	Not valid unless first frame is found.
    }
    property mpegSamplesPerFrame: int read f_mpgSPF;
    {*
	Number of samples per second.
	Not valid unless first frame is found.
    }
    property mpegSamplingRate: int read f_mpgSR;
    {*
	Layer: 1 = Layer I, 2 = Layer II, 3 = Layer III.
	Not valid unless first frame is found.
    }
    property mpegLayer: int read f_mpgLayer;
    {*
	Number of channels: 1 for mono, 2 for stereo.
	Not valid unless first frame is found.
    }
    property mpegChannels: int read f_mpgChannels;
    {*
	MPEG format: 1 for MPEG1, 2 for MPEG2, 3 for MPEG2.5
	Not valid unless first frame is found.
    }
    property mpegID: int read f_mpgID;
  end;


// -------------
// == MPEG TS ==
// -------------

const
  c_TS_packet_size	= 188;
  //
  // PIDs
  c_PID_PAT		= $0000;
  c_PID_CAT		= $0001;
  c_PID_TSDT		= $0002;
  c_PID_IPMP		= $0003;
  //
  c_PID_NIT     	= $0010;
  c_PID_SDT_BAT		= $0011;
  c_PID_EIT		= $0012;
  c_PID_RST		= $0013;
  c_PID_TDT_TOT		= $0014;
  c_PID_NS		= $0015;
  c_PID_RNT		= $0016;
  //
  c_PID_IS		= $001C;
  c_PID_MEAS		= $001D;
  c_PID_DIT		= $001E;
  c_PID_SIT		= $001F;
  //
  c_PID_null		= $1FFF;
  //
  //c_PID_PMT		= $FFFF;	// this is not an actual PID, rather an internal flag


  //: Allocation of table_id values
  c_table_id_PAT	= $00; // program_association_section
  c_table_id_CAT	= $01; // conditional_access_section
  c_table_id_PMT	= $02; // program_map_section
  c_table_id_TSDT	= $03; // transport_stream_description_section
  //04 to 0x3F reserved
  c_table_id_NIT_a	= $40; // network_information_section - actual_network
  c_table_id_NIT_o	= $41; // network_information_section - other_network
  c_table_id_SDT_ats	= $42; // service_description_section - actual_transport_stream
  //43 to 0x45 reserved for future use
  c_table_id_SDT_o	= $46; // service_description_section - other_transport_stream
  //47 to 0x49 reserved for future use
  c_table_id_BAT	= $4A; // bouquet_association_section
  //4B to 0x4D reserved for future use
  c_table_id_EIT_a	= $4E; // event_information_section - actual_transport_stream, present/following
  c_table_id_EIT_o	= $4F; // event_information_section - other_transport_stream, present/following
  //50 to 0x5F event_information_section - actual_transport_stream, schedule
  //60 to 0x6F event_information_section - other_transport_stream, schedule
  c_table_id_TDT	= $70; // time_date_section
  c_table_id_RST	= $71; // running_status_section
  c_table_id_ST		= $72; // stuffing_section
  c_table_id_TOT	= $73; // time_offset_section
  c_table_id_AIT	= $74; // application information section (TS 102 812 [15])
  c_table_id_CT		= $75; // container section (TS 102 323 [13])
  c_table_id_RCT	= $76; // related content section (TS 102 323 [13])
  c_table_id_CIT	= $77; // content identifier section (TS 102 323 [13])
  c_table_id_MPE_FEC	= $78; // MPE-FEC section (EN 301 192 [4])
  c_table_id_RNT	= $79; // resolution notification section (TS 102 323 [13])
  c_table_id_MPE_IFEC	= $7A; // MPE-IFEC section (TS 102 772 [51])
  //7B to 0x7D reserved for future use
  c_table_id_DIT	= $7E; // discontinuity_information_section
  c_table_id_SIT	= $7F; // selection_information_section
  //80 to 0xFE user defined
  c_table_id_forbidden	= $FF; // forbidden


  // PES stream types
  c_PESST_program_stream_map		= $BC; 	// 1011 1100
  c_PESST_private_stream_1		= $BD; 	// 1011 1101
  c_PESST_padding_stream		= $BE; 	// 1011 1110
  c_PESST_private_stream_2		= $BF; 	// 1011 1111
  //
  c_PESST_audio_stream_x		= $C0; 	// 110x xxxx - up to 32 audio streams
  c_PESST_video_stream_x		= $E0; 	// 1110 xxxx - up to 16 video streams
  c_PESST_audio_stream_x_mask	  	= $E0; 	// 1110 0000
  c_PESST_video_stream_x_mask		= $F0; 	// 1111 0000
  //
  c_PESST_ECM_stream			= $F0; 	// 1111 0000
  c_PESST_EMM_stream			= $F1; 	// 1111 0001
  c_PESST_stream_A_or_DSMCC		= $F2; 	// 1111 0010
  c_PESST_stream_13522			= $F3; 	// 1111 0011
  c_PESST_stream_222_A			= $F4; 	// 1111 0100
  c_PESST_stream_222_B	 		= $F5; 	// 1111 0101
  c_PESST_stream_222_C			= $F6; 	// 1111 0110
  c_PESST_stream_222_D			= $F7; 	// 1111 0111
  c_PESST_stream_222_E			= $F8; 	// 1111 1000
  c_PESST_ancillary_stream		= $F9; 	// 1111 1001
  c_PESST_stream_14496_SL		= $FA; 	// 1111 1010
  c_PESST_stream_14496_FlexMux		= $FB; 	// 1111 1011
  c_PESST_stream_reserved_FC		= $FC;  // 1111 1100 … 1111 1110 reserved data stream
  c_PESST_stream_reserved_FD		= $FD;  // 1111 1100 … 1111 1110 reserved data stream
  c_PESST_stream_reserved_FE		= $FE;  // 1111 1100 … 1111 1110 reserved data stream
  c_PESST_program_stream_directory	= $FF; 	// 1111 1111

  // PMT stream types
  c_PMTST_reserved			= $00; // ITU-T | ISO/IEC Reserved
  c_PMTST_MPEG1_video			= $01; // ISO/IEC 11172-2 Video
  c_PMTST_MPEG2_video			= $02; // ITU-T Rec. H.262 | ISO/IEC 13818-2 Video or ISO/IEC 11172-2 constrained parameter video stream
  c_PMTST_MPEG1_audio			= $03; // ISO/IEC 11172-3 Audio
  c_PMTST_MPEG2_audio			= $04; // ISO/IEC 13818-3 Audio
  c_PMTST_MPEG2_private			= $05; // ITU-T Rec. H.222.0 | ISO/IEC 13818-1 private_sections
  c_PMTST_MPEG2_PESprivate		= $06; // ITU-T Rec. H.222.0 | ISO/IEC 13818-1 PES packets containing private data
  c_PMTST_MHEG				= $07; // ISO/IEC 13522 MHEG
  c_PMTST_MPEG2_DSM_CC			= $08; // ITU-T Rec. H.222.0 | ISO/IEC 13818-1 Annex A DSM-CC
  c_PMTST_H222_1			= $09; // ITU-T Rec. H.222.1
  c_PMTST_MPEG2_6_typeA			= $0A; // ISO/IEC 13818-6 type A
  c_PMTST_MPEG2_6_typeB			= $0B; // ISO/IEC 13818-6 type B
  c_PMTST_MPEG2_6_typeC			= $0C; // ISO/IEC 13818-6 type C
  c_PMTST_MPEG2_6_typeD			= $0D; // ISO/IEC 13818-6 type D
  c_PMTST_MPEG2_aux			= $0E; // ITU-T Rec. H.222.0 | ISO/IEC 13818-1 auxiliary
  c_PMTST_MPEG2_ADTS		        = $0F; // ISO/IEC 13818-7 Audio with ADTS transport syntax
  c_PMTST_AVC_visual			= $10; // ISO/IEC 14496-2 Visual
  c_PMTST_AVC_audio			= $11; // ISO/IEC 14496-3 Audio with the LATM transport syntax as defined in ISO/IEC 14496-3
  c_PMTST_AVC_1_pack_PES		= $12; // ISO/IEC 14496-1 SL-packetized stream or FlexMux stream carried in PES packets
  c_PMTST_AVC_1_pack			= $13; // ISO/IEC 14496-1 SL-packetized stream or FlexMux stream carried in ISO/IEC 14496_sections
  c_PMTST_MPEG2_SDP			= $14; // ISO/IEC 13818-6 Synchronized Download Protocol
  c_PMTST_meta_PES    		 	= $15; // Metadata carried in PES packets
  c_PMTST_meta_meta    			= $16; // Metadata carried in metadata_sections
  c_PMTST_meta_DC    			= $17; // Metadata carried in ISO/IEC 13818-6 Data Carousel
  c_PMTST_meta_object			= $18; // Metadata carried in ISO/IEC 13818-6 Object Carousel
  c_PMTST_meta_SDP		    	= $19; // Metadata carried in ISO/IEC 13818-6 Synchronized Download Protocol
  c_PMTST_MPEG2_IPMP		    	= $1A; // IPMP stream (defined in ISO/IEC 13818-11, MPEG-2 IPMP)
  c_PMTST_AVC_H264_video	    	= $1B; // AVC video stream as defined in ITU-T Rec. H.264 | ISO/IEC 14496-10 Video
  c_PMTST_MPEG2_reserved_start    	= $1C; //
  c_PMTST_MPEG2_reserved_end		= $7E; // ITU-T Rec. H.222.0 | ISO/IEC 13818-1 Reserved
  c_PMTST_IPMP				= $7F; // IPMP stream
  c_PMTST_user_private_start		= $80; //
  c_PMTST_user_private_end		= $FF; // User Private


  // descriptor tag possible values
  c_descTag_res00		= $00;
  c_descTag_res01		= $01; // Reserved
  c_descTag_video		= $02; // video_stream_desc
  c_descTag_audio		= $03; // audio_stream_desc
  c_descTag_hierarchy		= $04; // hierarchy_desc
  c_descTag_registration	= $05; // registration_desc
  c_descTag_DS_alignment	= $06; // DS_alignment_desc
  c_descTag_TBG			= $07; // TBG_desc
  c_descTag_video_window	= $08; // video_window_desc
  c_descTag_CA			= $09; // CA_desc
  c_descTag_ISO_639_lang	= $0A; // ISO_639_lang_desc
  c_descTag_system_clock	= $0B; // system_clock_desc
  c_descTag_MBU			= $0C; // MBU_desc
  c_descTag_copyright		= $0D; // copyright_desc
  c_descTag_maxbitrate		= $0E; // maxbitrate_desc
  c_descTag_PDI			= $0F; // PDI_desc
  c_descTag_SMB			= $10; // SMB_desc
  c_descTag_STD			= $11; // STD_desc
  c_descTag_IBP			= $12; // IBP_desc
  c_descTag_13818_6_13		= $13; //
  c_descTag_13818_6_14		= $14; //
  c_descTag_13818_6_15		= $15; //
  c_descTag_13818_6_16		= $16; //
  c_descTag_13818_6_17		= $17; //
  c_descTag_13818_6_18		= $18; //
  c_descTag_13818_6_19		= $19; //
  c_descTag_13818_6_1A		= $1A; //
  c_descTag_MPEG4_video		= $1B; // MPEG-4_video_d
  c_descTag_MPEG4_audio		= $1C; // MPEG-4_audio_d
  c_descTag_IOD			= $1D; // IOD_desc
  c_descTag_SL			= $1E; // SL_desc
  c_descTag_FMC			= $1F; // FMC_desc
  c_descTag_external_ES_ID	= $20; // external_ES_ID_descriptor
  c_descTag_MuxCode		= $21; // MuxCode_descriptor
  c_descTag_FmxBufferSize	= $22; // FmxBufferSize_descriptor
  c_descTag_multiplexbuffer	= $23; // multiplexbuffer_descriptor
  c_descTag_content_labeling	= $24; // content_labeling_descriptor
  c_descTag_metadata_pointer	= $25; // metadata_pointer_descriptor
  c_descTag_metadata		= $26; // metadata_descriptor
  c_descTag_metadata_STD	= $27; // metadata_STD_descriptor
  c_descTag_AVC_video		= $28; // AVC video desc
  c_descTag_IPMP		= $29; // IPMP_desc
  c_descTag_AVC_timing		= $2A; // AVC timing/HRD
  c_descTag_MPEG2_AAC_audio	= $2B; // MPEG-2_AAC_audio
  c_descTag_FlexMuxTiming	= $2C; // _desc
  c_descTag_res2D_start		= $2D; //
  c_descTag_res3F_end		= $3F;
  c_descTag_userPriv_start	= $40; //
  c_descTag_userPriv_end	= $FF;

  // DBV descriptors
  c_descTagDVB_network_name			= $40;
  c_descTagDVB_service_list			= $41;
  c_descTagDVB_stuffing				= $42;
  c_descTagDVB_satellite_delivery_system	= $43;
  c_descTagDVB_cable_delivery_system		= $44;
  c_descTagDVB_VBI_data				= $45;
  c_descTagDVB_VBI_teletext			= $46;
  c_descTagDVB_bouquet_name			= $47;
  c_descTagDVB_service				= $48;
  c_descTagDVB_country_availability		= $49;
  c_descTagDVB_linkage				= $4A;
  c_descTagDVB_NVOD_reference			= $4B;
  c_descTagDVB_time_shifted_service		= $4C;
  c_descTagDVB_short_event			= $4D;
  c_descTagDVB_extended_event			= $4E;
  c_descTagDVB_time_shifted_event		= $4F;
  c_descTagDVB_component			= $50;
  c_descTagDVB_mosaic				= $51;
  c_descTagDVB_stream_identifier		= $52;
  c_descTagDVB_CA_identifier			= $53;
  c_descTagDVB_content				= $54;
  c_descTagDVB_parental_rating			= $55;
  c_descTagDVB_teletext				= $56;
  c_descTagDVB_telephone			= $57;
  c_descTagDVB_local_time_offset		= $58;
  c_descTagDVB_subtitling			= $59;
  c_descTagDVB_terrestrial_delivery_system	= $5A;
  c_descTagDVB_multilingual_network_name	= $5B;
  c_descTagDVB_multilingual_bouquet_name	= $5C;
  c_descTagDVB_multilingual_service_name	= $5D;
  c_descTagDVB_multilingual_component		= $5E;
  c_descTagDVB_private_data_specifier		= $5F;
  c_descTagDVB_service_move			= $60;
  c_descTagDVB_short_smoothing_buffer		= $61;
  c_descTagDVB_frequency_list			= $62;
  c_descTagDVB_partial_transport_stream		= $63;
  c_descTagDVB_data_broadcast			= $64;
  c_descTagDVB_scrambling			= $65;
  c_descTagDVB_data_broadcast_id		= $66;
  c_descTagDVB_transport_stream			= $67;
  c_descTagDVB_DSNG				= $68;
  c_descTagDVB_PDC				= $69;
  c_descTagDVB_AC3				= $6A;
  c_descTagDVB_ancillary_data			= $6B;
  c_descTagDVB_cell_list			= $6C;
  c_descTagDVB_cell_frequency_link		= $6D;
  c_descTagDVB_announcement_support		= $6E;
  c_descTagDVB_application_signalling		= $6F;
  c_descTagDVB_adaptation_field_data		= $70;
  c_descTagDVB_service_identifier		= $71;
  c_descTagDVB_service_availability		= $72;
  c_descTagDVB_default_authority		= $73;
  c_descTagDVB_related_content			= $74;
  c_descTagDVB_TVA_id				= $75;
  c_descTagDVB_content_identifier		= $76;
  c_descTagDVB_time_slice_fec_identifier	= $77;
  c_descTagDVB_ECM_repetition_rate		= $78;
  c_descTagDVB_S2_satellite_delivery_system	= $79;
  c_descTagDVB_enhanced_AC3			= $7A;
  c_descTagDVB_DTS				= $7B;
  c_descTagDVB_AAC				= $7C;
  c_descTagDVB_XAIT_location			= $7D;
  c_descTagDVB_FTA_content_management		= $7E;
  c_descTagDVB_extension			= $7F;


  // audio types for ISO_639_lang tag
  c_descISO639_undef		= $00; // Undefined
  c_descISO639_cleanef		= $01; // Clean effects
  c_descISO639_hearingImp	= $02; // Hearing impaired
  c_descISO639_visualImp	= $03; // Visual impaired commentary
  c_descISO639_userPriv_start	= $04; // User Private
  c_descISO639_userPriv_end	= $7F;
  c_descISO639_res_start	= $80; // Reserved
  c_descISO639_res_end		= $FF;

type
  //
  TPID	 = uint32;

  // fwd
  unaMpegTSDescriptorList = class;

  {*
	Abstract class with ID, which can read itself from reader
  }
  unaMpegTS_pwnID = class(unaObject)
  private
    f_ID: TPID;
    f_desc2: unaMpegTSDescriptorList;
  protected
    procedure reparse(reader: unaBitReader_abstract; var len: int); virtual;
    //
    property desc: unaMpegTSDescriptorList read f_desc2;
  public
    constructor create(ID: TPID; reader: unaBitReader_abstract; var len: int);
    destructor Destroy(); override;
    //
    property ID: TPID read f_ID;
  end;


  {*
	Base list which indexes unaMpegTS_pwnID objects by their tags
  }
  unaMpegTS_pwnIDList = class(unaIDList)
  protected
    function getId(item: pointer): int64; override;
  public
    constructor Create();
  end;


  {*
	TS Descriptor
  }
  unaMpegTSDescriptor = class(unaMpegTS_pwnID)
  private
    f_data: array[byte] of byte;
    f_dataLen: int;
    //
    function getData(): pArray;
    function getAsString(): string;
  protected
    procedure reparse(reader: unaBitReader_abstract; var len: int); override;
  public
    {*
    }
    property data: pArray read getData;
    {*
    }
    property dataLen: int read f_dataLen;
    {*
    }
    property asString: string read getAsString;
  end;


  {*
	List of Descriptors
  }
  unaMpegTSDescriptorList = class(unaMpegTS_pwnIDList)
  private
    //
    function getDAsString(tag: TPID): string;
  public
    {*
	Read descriptors for this stream.

	@param reader Reader to use
	@param len IN: max number of bytes; OUT: actual number of bytes consumed
    }
    procedure addDesc(reader: unaBitReader_abstract; var len: int);
    //
    property dvalue[tag: TPID]: string read getDAsString;
  end;


  {*
	TS Event
  }
  unaMpegTSEvent = class(unaMpegTS_pwnID)
  private
    f_ts_id: TPID;
    f_network_id: TPID;
    f_service_id: TPID;
    //
    f_start_time: array[0..4] of byte;
    f_duration: uint32;		// 24 bits used
    f_running_status: int;	// 3 bits
    f_free_CA_mode: bool;	// 1 bit
    //
    function getST(): uint64;
  protected
    procedure reparse(reader: unaBitReader_abstract; var len: int); override;
  public
    constructor create(evID, TSID, NID, srvID: TPID; reader: unaBitReader_abstract; var len: int);
    //
    property TSID: TPID read f_ts_id;		// 16 bits
    property NID: TPID read f_network_id;		// 16 bits
    property srvID: TPID read f_service_id;		// 16 bits
    //
    property startTime: uint64 read getST;		// 40 bits (network order?)
    property duration: uint32 read f_duration;		// 24 bits used
    property running_status: int read f_running_status;	// 3 bits
    property free_CA_mode: bool read f_free_CA_mode;	// 1 bit
    //
    property desc;
  end;


  {*
	TS Service
  }
  unaMpegTSService = class(unaMpegTS_pwnID)
  private
    f_network_id: TPID;
    f_ts_id: TPID;
    f_this_stream: bool;
    //
    f_EIT_schedule_flag,
    f_EIT_present_folloing_flag,
    f_running_status,
    f_free_CA_mode: unsigned;
    //
  protected
    procedure reparse(reader: unaBitReader_abstract; var len: int); override;
  public
    constructor create(srvID, NID, TSID: TPID; this: bool; reader: unaBitReader_abstract; var len: int);
    //
    property NID: TPID read f_network_id;		// 16 bits
    property TSID: TPID read f_ts_id;		// 16 bits
    property this_stream: bool read f_this_stream;
    //
    property desc;
  end;


  {*
	Elementary stream
  }
  unaMpegES = class(unaMpegTS_pwnID)
  private
    f_streamID: int;
    f_NID: TPID;
    //
    f_continuity: int;
    f_scrambled: bool;
    f_priority: bool;
    //
    f_totalCnt: int64;
    //
    f_streamType: uint8;		// from PMT
  public
    {*
	Creates new TS with specified PID and continuity
    }
    constructor Create(PID, NID: TPID; continuity: int);
    {*
	Updates Continuity counter.

	@param continuity_counter New counter value
	@param tolerate True means continuity errors will be ignored
	@return True if continuity as expected
    }
    function updateContinuity(continuity_counter: int): bool;
    //
    // --  --
    {*
	Descriptors.
    }
    property desc;
    {*
	Stream ID (from PES) [not a PID!]
    }
    property streamID: int read f_streamID;
    {*
	Stream type (from PMT)
    }
    property streamType: uint8 read f_streamType;
    {*
	True if scrambled
    }
    property scrambled: bool read f_scrambled;
    {*
	True if has hight priority
    }
    property priority: bool read f_priority;
    {*
	network ID
    }
    property NID: TPID read f_NID;
    {*
	Total count.
    }
    property totalCnt: int64 read f_totalCnt;
  end;


  {*
	MPEG-TS Program
  }
  unaMpegTSProgram = class(unaMpegTS_pwnID)
  private
    f_PID_PMT: TPID;
    f_PID_PCR: TPID;
    //
    f_streams: unaList;
  public
    constructor Create(num, PMT, PCR: TPID);
    destructor Destroy(); override;
    //
    property PID_PMT: TPID read f_PID_PMT;
    property PID_PCR: TPID read f_PID_PCR;
    //
    property desc;
    //
    property streams: unaList read f_streams;	// list of streams IDs
  end;


  // forward
  unaMpegTSDemuxer = class;


  {*
	MPEG-TS Network
  }
  unaMpegTSNetwork = class(unaMpegTS_pwnID)
  private
    f_demuxer: unaMpegTSDemuxer;
  protected
    procedure reparse(reader: unaBitReader_abstract; var len: int); override;
  public
    constructor create(dex: unaMpegTSDemuxer; ID: TPID; reader: unaBitReader_abstract; var len: int);
    //
    property desc;
  end;


  {*
	Internal section reader helper.
  }
  unaMpegTSDemuxerSectionReader = class(unaBitReader_stream)
  private
    f_demuxer: unaMpegTSDemuxer;
    //
    f_pid: TPID;
    f_table_id: TPID;
    //
    f_expectedLen: int;
    f_syntax: bool;
    f_subID: unsigned;
    f_version: int;
    f_current: bool;
    f_sec_num: int;
    f_sec_lastNum: int;
    //
    f_subReadBuf: array[byte] of byte;
    //
    procedure header(reader: unaBitReader_abstract; var len: int);
    //
    procedure parse(reader: unaBitReader_abstract; out consumed: int);
    //
    procedure readFrom(reader: unaBitReader_abstract; len: int);
    //
    procedure startOver(reader: unaBitReader_abstract; var len: int);
  protected
    {*
	Restart payload reader (as on continuity error or something else).
    }
    procedure doRestart(); override;
  public
    {*
	Creates a new reader on a section.
    }
    constructor create(dex: unaMpegTSDemuxer; PID: TPID; reader: unaBitReader_abstract; var len: int);
    {*
	Appends new portion of payload.
    }
    procedure append(reader: unaBitReader_abstract; var len: int; ps: bool);
    {*
	PID of stream this section belong to
    }
    property PID: TPID read f_pid;
    {*
	ID of a stream/program/service/whatever this sections refers to
    }
    property subID: unsigned read f_subID;
  end;


  {*
	List of Section readers
  }
  unaMpegSReaderList = class(unaIDList)
  protected
    function getId(item: pointer): int64; override;
  public
    constructor Create();
  end;


  {*
	Some statistic
  }
  punaMpegTSDemuxerStat = ^unaMpegTSDemuxerStat;
  unaMpegTSDemuxerStat = record
    r_totalPackets: int64;
    r_totalPacketsSkipped: int64;
    r_totalPayload: int64;
  end;

  {*
	MPEG-TS Demuxer
  }
  unaMpegTSDemuxer = class(unaObject)
  private
    f_reader: unaBitReader_abstract;
    //
    f_payload: array[byte] of byte;
    //
    f_ts_id: TPID;
    f_NID: TPID;
    //
    f_known_PES: array[byte] of TPID;
    f_known_PEScount: int;
    //
    f_estreams: unaMpegTS_pwnIDList;
    f_programs: unaMpegTS_pwnIDList;
    f_descripors: unaMpegTSDescriptorList;
    f_services: unaMpegTS_pwnIDList;
    f_networks: unaMpegTS_pwnIDList;
    //
    f_stat: punaMpegTSDemuxerStat;
    //
    f_sreaders: unaMpegSReaderList;
    //
    f_tolerateC: bool;
    //
    f_statOOSPackets: int;
    f_statOKPackets: int;
    f_statPackets: int;
    //
    {*
	Decodes adaptation field.

	@maxLen Maximum size of adaptaion
	@return Number of bytes read
    }
    function adaptation_field(maxLen: int): int;
    {*
	Decodes PS header (PSI or PES).

	@PID packet ID
	@streamID returns stream ID
	@len On input, specifies max size of section. On output set to number of bytes consumed by this function.
	@return True if decoded successfully
    }
    function PS_header(PID: TPID; out streamID: int; var len: int): bool;
    {*
	Decodes PSI header.

	@PID packet ID
	@len On input, specifies max size of section. On output set to number of bytes consumed by this function.
	@return True if decoded successfully
    }
    function PSI_header(PID: TPID; var len: int): bool;
    {*
	Decodes PES header.

	@PID packet ID
	@streamID returns stream ID
	@len On input, specifies max size of section. On output set to number of bytes consumed by this function.
	@return True if decoded successfully
    }
    function PES_header(PID: TPID; out streamID: int; var len: int): bool;
  protected
    {*
	  Override to get demuxed payload.
    }
    procedure onDX_payload(PID: TPID; data: pointer; len: int; userData: pointer = nil); virtual;
    {*
	  Override to get events as they appear in stream.
    }
    procedure onDX_event(PID: TPID; EV: unaMpegTSEvent); virtual;
    {*
	  Override to get notified about tables.
    }
    procedure onDX_table(PID: TPID; tableID: TPID); virtual;
    //
    {*
	Bit reader used by demuxer
    }
    property reader: unaBitReader_abstract read f_reader;
    {*
	Transport Stream ID
    }
    property TSID: TPID read f_ts_id;
    {*
	NID
    }
    property NID: TPID read f_NID;
  public
    {*
	Creates a demuxer, prividing a reader for it.
    }
    constructor Create(reader: unaBitReader_abstract);
    {*
	Destroys demuxer.
    }
    destructor Destroy(); override;
    {*
	Demux another portion of raw data available in reader.

	@param loop continue demuxing until no more bytes are available in reader
	@param lookupSynch True = read stream until new sych byte is found, when out of packet's synch; False = fail on first bad synch found
	@param userData any data to be passed to onDX_payload

	@return True if demuxing of at least one packet was successfull
    }
    function demux(loop, lookupSynch: bool; userData: pointer = nil): bool;
    //
    {*
	Some statistic
    }
    property stat: punaMpegTSDemuxerStat read f_stat;
    {*
	Elementary streams, indexed by PIDs
    }
    property estreams: unaMpegTS_pwnIDList read f_estreams;
    {*
	Programs, indexed by program numbers
    }
    property programs: unaMpegTS_pwnIDList read f_programs;
    {*
	Services, indexed by service id
    }
    property services: unaMpegTS_pwnIDList read f_services;
    {*
	Networks, indexed by nid
    }
    property networks: unaMpegTS_pwnIDList read f_networks;
    {*
	Global TS descriptors, indexed by tags
    }
    property desc: unaMpegTSDescriptorList read f_descripors;
    {*
	Tolerate minor continuity errors
    }
    property tolerateContinuity: bool read f_tolerateC write f_tolerateC;
  end;


implementation


uses
  unaUtils;


{ unaBitReader_abstract }

// --  --
procedure unaBitReader_abstract.BeforeDestruction();
begin
  inherited;
  //
  doRestart();	// free all buffers
end;

// --  --
procedure unaBitReader_abstract.doRestart();
begin
  f_bitOfs := 0;
  //
  f_sbSize := 0;
  f_sbOfs := 0;
  //
  if (f_sbAllocated) then
    mrealloc(f_sb);
  //
  resetOutfillBuf();	// reset outfill offset
end;

// --  --
function unaBitReader_abstract.getIsEOF(): bool;
begin
  result := EOF(1);
end;

// --  --
procedure unaBitReader_abstract.moveBitOfs(delta: int);
begin
  inc(f_bitOfs, delta);
end;

// --  --
function unaBitReader_abstract.nextBits(numBits: unsigned): uint32;
const
  uMask: array[1..8] of uint32 =
    ($00000001, $00000003, $00000007, $0000000F,
     $0000001F, $0000003F, $0000007F, $000000FF);
var
  bavail, nba: unsigned;
begin
  if ((32 >= numBits) and not EOF(numBits)) then begin
    //
    if ((nil = f_sb) or (f_sbOfs >= f_sbSize)) then	// no subBuf or done with subBuf?
      readSubBuf();
    //
    result := 0;
    while ((nil <> f_sb) and (0 < numBits)) do begin
      //
{
     Bits:  7  6  5  4  3  2  1  0    7  6  5  4  3  2  1  0    7  6  5  4  3  2  1  0    7  6  5  4  3  2  1  0
	   [-][-][-][-][-][-][-][-]  [-][-][-][-][x][x][x][x]  [-][-][-][-][-][-][-][-]  [-][-][-][-][-][-][-][-]
 Bit Offs:  0  1  2  3  4  5  6  7    8  9  10 11 12 13 14 15   16 17 18 19 20 21 22 23   24 25 26 27 28 29 30 31

}
      bavail := 8 - bitOfs and 7;
      nba := min(numBits, bavail);
      if (0 = nba) then
	break;
      //
      result := result shl nba + (f_sb[f_sbOfs] shr (bavail - nba)) and uMask[nba]; // unsigned((1 shl nba) - 1);
      //
      dec(numBits, nba);
      moveBitOfs(nba);
      //
      if (1 > bavail - nba) then begin	// done with f_subBuf[f_subBufOfs] byte?
	//
	pushOutfill();
	//
	inc(f_sbOfs);
	if (f_sbOfs >= f_sbSize) then	// done with subBuf?
	  readSubBuf();
      end;
    end;  // while () ...
  end
  else
    result := 0;
end;

// --  --
procedure unaBitReader_abstract.pushOutfill(numBytes: int);
begin
  if (outfill and (nil <> sbAt())) then begin
    //
    move(sbAt()^, f_outfillBuf[f_outfillOfs], numBytes);
    inc(f_outfillOfs, numBytes);
  end;
end;

// --  --
function unaBitReader_abstract.readBytes(numBytes: int; buf: pointer): uint32;
begin
  if (bytesLeft < numBytes) then
    readSubBuf(numBytes - bytesLeft, true);	// try to read required amount of bytes
  //
  result := min(numBytes, bytesLeft);
  if (0 < result) then begin
    //
    move(sbAt()^, buf^, result);
    skipBytes(result);
  end;
end;

// --  --
procedure unaBitReader_abstract.resetOutfillBuf();
begin
  setOutfillBuf(f_outfillBuf);
end;

// --  --
procedure unaBitReader_abstract.restart();
begin
  doRestart();
end;

// --  --
procedure unaBitReader_abstract.sbAlloc(sz: int; append: bool);
var
  sb: pointer;
  sbSz: int;
begin
  if ((not f_sbAllocated) or (f_sbAllocated and ( (sz > f_sbSize) or append) )) then begin
    //
    if (append) then begin
      //
      sb := nil;
      try
	//
	// save old data
	sbSz := min(sbLeft(), sz);
	if (0 < sbSz) then begin
	  //
	  sb := malloc(sbSz);
	  move(f_sb[f_sbOfs], sb^, sbSz);
	end;
	//
	mrealloc(f_sb, sz);
	//
	if (append and (0 < sbSz)) then
	  // move data back into buf
	  move(sb^, f_sb^, sbSz);
      finally
	mrealloc(sb);
      end;
    end
    else
      mrealloc(f_sb, sz);
  end;
  //
  f_sbSize := sz;
  f_sbOfs := 0;
  //
  f_sbAllocated := true;
end;

// --  --
procedure unaBitReader_abstract.sbAssign(v: pointer; sz: int);
begin
  if (f_sbAllocated) then
    mrealloc(f_sb);
  //
  f_sb := v;
  f_sbSize := sz;
  f_sbOfs := 0;
  f_sbAllocated := false;
end;

// --  --
function unaBitReader_abstract.sbAt(at: int): pointer;
begin
  case (at) of

    -1: result := @f_sb[f_sbSize];
    -2: result := @f_sb[f_sbOfs];
    else
	result := @f_sb[at];

  end;
end;

// --  --
procedure unaBitReader_abstract.sbIncrease(delta: int);
begin
  inc(f_sbSize, delta);
end;

// --  --
function unaBitReader_abstract.sbLeft(): int;
begin
  result := f_sbSize - f_sbOfs;
end;

// --  --
procedure unaBitReader_abstract.setOutfill(value: bool);
begin
  if (value) then
    f_outfill := (nil <> f_outfillBuf)
  else
    f_outfill := false;
end;

// --  --
procedure unaBitReader_abstract.setOutfillBuf(buf: pointer);
begin
  f_outfillOfs := 0;
  f_outfillBuf := buf;
  //
  outfill := (nil <> f_outfillBuf);
end;

// --  --
procedure unaBitReader_abstract.skipBytes(numBytes: unsigned);
var
  d: int;
begin
  if ((0 = bitOfs and 7) and (4 < numBytes)) then begin
    //
    while (0 < numBytes) do begin
      //
      d := min(sbLeft(), int(numBytes));
      if (0 < d) then begin
	//
	pushOutfill(d);
	//
	inc(f_sbOfs, d);
	moveBitOfs(d shl 3);
	if (f_sbOfs >= f_sbSize) then	// done with subBuf?
	  readSubBuf();
	//
	dec(numBytes, d);
      end
      else begin
	//
	if (f_sbOfs >= f_sbSize) then begin	// done with subBuf?
	  //
	  if (EOF(8)) then
	    break	// no more bytes
	  else
	    readSubBuf();
	end
	else
	  break;	// some problem..
      end;
    end;
  end
  else begin
    //
    if (4 >= numBytes) then
      nextBits(numBytes shl 3)
    else begin
      //
      // seek to byte boundary
      nextBits(8 - bitOfs and 7);
      skipBytes(numBytes - 1);
    end;
  end;
end;

// --  --
procedure unaBitReader_abstract.skipToByte();
var
  br: int;
begin
  br := 8 - bitOfs and 7;
  if (8 <> br) then begin
    //
    pushOutfill();
    //
    inc(f_sbOfs);
    if ((nil = f_sb) or (f_sbOfs >= f_sbSize)) then	// no subBuf or done with subBuf?
      readSubBuf();
    //
    moveBitOfs(br);
  end;
end;


{ unaBitReader_file }

// --  --
constructor unaBitReader_file.create(const fileName: wideString);
begin
  f_f := fileOpen(fileName);
  if (INVALID_HANDLE_VALUE <> f_f) then
    f_fsizeBits := fileSize(f_f) shl 3;
  //
  inherited create();
end;

// --  --
procedure unaBitReader_file.BeforeDestruction();
begin
  inherited;
  //
  if (nil <> f_mf) then
    f_mf.unmapView(f_mfLastMap);
  //
  f_mfLastMap := nil;
  //
  fileClose(f_f);
end;

// --  --
constructor unaBitReader_file.create(mf: unaMappedFile);
begin
  f_mf := mf;
  //
  inherited create();
end;

// --  --
procedure unaBitReader_file.doRestart();
begin
  if (nil = f_mf) then
    SetFilePointer(f_f, 0, nil, FILE_BEGIN)
  else
    f_mf.unmapView(f_mfLastMap);
  //
  inherited;
end;

// --  --
function unaBitReader_file.EOF(numBits: unsigned): bool;
begin
  if (nil = f_mf) then
    result := (bitOfs + numBits >= f_fsizeBits)
  else
    result := (bitOfs + numBits >= f_mf.size64 shl 3);
end;

// --  --
procedure unaBitReader_file.readSubBuf(reqSize: int; append: bool);
var
  sz: int;
  szf: unsigned;
  so: int;
begin
  if (nil <> f_mf) then begin
    //
    if (nil <> f_mfLastMap) then begin
      //
      f_mf.unmapView(f_mfLastMap);
      f_mfLastMap := nil;
    end;
    //
    if (0 < reqSize) then
      sz := reqSize
    else
      sz := f_mf.allocGran shl 6; // about 4 MB
    //
    sz := min(f_mf.size64 - bitOfs shr 3, sz);
    //
    f_mfLastMap := f_mf.mapView(bitOfs shr 3, sz, so);
    if (nil <> f_mfLastMap) then begin
      //
      if (append) then begin
	//
	sbAlloc(sbLeft() + sz, append);
	move(pArray(f_mfLastMap)[so], sbAt(sbLeft())^, sz);
      end
      else
	sbAssign(@pArray(f_mfLastMap)[so], sz);
    end;
  end
  else begin
    //
    if (0 < reqSize) then
      sz := reqSize
    else
      sz := min(f_fsizeBits - bitOfs, $800000) shr 3;	// about 2 MB
    //
    if (append) then
      so := sbLeft()
    else
      so := 0;
    //
    sbAlloc(so + sz, append);
    szf := sz;
    if (0 = readFromFile(f_f, sbAt(so), szf)) then
      f_sbSize := so + int(szf)
    else
      f_sbSize := so;
  end;
end;


{ unaBitReader_stream }

// --  --
procedure unaBitReader_stream.BeforeDestruction();
begin
  inherited;
  //
  freeAndNil(f_stream);
end;

// --  --
constructor unaBitReader_stream.create();
begin
  f_stream := unaMemoryStream.create();
  //
  inherited create();
end;

// --  --
procedure unaBitReader_stream.doRestart();
begin
  f_stream.clear();
  //
  inherited;
end;

// --  --
function unaBitReader_stream.EOF(numBits: unsigned): bool;
begin
  if ((int(f_stream.getAvailableSize()) + sbLeft()) shl 3 < int(numBits)) then
    needMoreData(numBits shr 3 + 1);
  //
  result := ((int(f_stream.getAvailableSize()) + sbLeft()) shl 3 < int(numBits));	//
end;

// --  --
procedure unaBitReader_stream.needMoreData(size: int);
begin
  // override to provide more data for stream
end;

// --  --
procedure unaBitReader_stream.readSubBuf(reqSize: int; append: bool);
const
  c_req_sz	= $100000 shr 3;	// 132 KiB
var
  sz: int;
  so: int;
begin
  if (reqSize > 0) then
    sz := reqSize
  else
    sz := c_req_sz;
  //
  if (f_stream.getAvailableSize() < sz) then
    needMoreData(sz - f_stream.getAvailableSize());	// request as much as possible
  //
  sz := min(f_stream.getAvailableSize(), sz);
  if (0 < sz) then begin
    //
    if (append) then
      so := sbLeft()
    else
      so := 0;
    //
    sbAlloc(so + sz, append);
    f_stream.read(sbAt(so), sz);
  end;
end;

// --  --
procedure unaBitReader_stream.write(data: pointer; size: int);
begin
  f_stream.write(data, size);
end;


{ unaMpegAudio_layer123 }

// --  --
procedure unaMpegAudio_layer123.ancillary_data(const h: unaMpegHeader);
begin
  //
end;

// --  --
procedure unaMpegAudio_layer123.audio_data(const h: unaMpegHeader);
var
  bpf: int;
begin
  if ((0 < h.bitrate_index) and (15 > h.bitrate_index) and (3 > h.sampling_frequency)) then begin
    //
    bpf := 0;
    case (h.layer) of

      3: begin  // LayerI, 384 samples/frame
	//
	bpf := c_mpeg_bitrate[mpegID][h.bitrate_index][1] * 48000 div c_mpegFreq[mpegID][h.sampling_frequency];
      end;

      2: begin // LayerII, 1152 samples/frame
	//
	bpf := c_mpeg_bitrate[mpegID][h.bitrate_index][2] * 144000 div c_mpegFreq[mpegID][h.sampling_frequency];
      end;

      1: begin // LayerIII, 1152 or 576 samples/frame
	{
	  main_data_begin := reader.nextBits(9);
	  if (3 = h.mode) then begin
	    //
	    nch := 1;
	    private_bits := reader.nextBits(5);
	  end
	  else begin
	    //
	    nch := 2;
	    private_bits := reader.nextBits(3);
	  end;
	  //
	  for ch := 0 to nch - 1 do
	    for scfsi_band := 0 to 3 do
	      scfsi[ch][scfsi_band] := reader.nextBits(1);
	  //
	  maxPart := 0;
	  for gr := 0 to 1 do
	    for ch := 0 to nch - 1 do begin
	      //
	      part2_3_length[gr][ch] := reader.nextBits(12);
	      if (maxPart < part2_3_length[gr][ch]) then
		maxPart := part2_3_length[gr][ch];
	      //
	      big_values[gr][ch] := reader.nextBits(9);
	      global_gain[gr][ch] := reader.nextBits(8);
	      scalefac_compress[gr][ch] := reader.nextBits(4);
	      window_switching_flag[gr][ch] := reader.nextBits(1);
	      //
	      if (0 <> window_switching_flag[gr][ch]) then begin
		//
		block_type[gr][ch] := reader.nextBits(2);
		mixed_block_flag[gr][ch] := reader.nextBits(1);
		for region := 0 to 1 do
		  table_select[gr][ch][region] := reader.nextBits(5);
		for window := 0 to 2 do
		  subblock_gain[gr][ch][window] := reader.nextBits(3);
	      end
	      else begin
		//
		for region := 0 to 2 do
		  table_select[gr][ch][region] := reader.nextBits(5);
		//
		region0_count[gr][ch] := reader.nextBits(4);
		region1_count[gr][ch] := reader.nextBits(3);
	      end;
	      //
	      preflag[gr][ch] := reader.nextBits(1);
	      scalefac_scale[gr][ch] := reader.nextBits(1);
	      count1table_select[gr][ch] := reader.nextBits(1);
	    end;
	  //
	  // -- main data --
	  //
	}
	//
	bpf := c_mpeg_bitrate[mpegID][h.bitrate_index][3] * 144000 div c_mpegFreq[mpegID][h.sampling_frequency];
	if (2 <= mpegID) then
	  bpf := bpf shr 1;
      end;

    end; // case (layer) ...
    //
    if (0 <> h.padding_bit) then
      inc(bpf);
    if (0 = h.protection_bit) then
      dec(bpf, 2);
    //
    dec(bpf, 4);	// header already read
    reader.skipBytes(bpf);
    //
  end; // if () ...
end;

// --  --
function unaMpegAudio_layer123.crc_check(var h: unaMpegHeader): HRESULT;
begin
  h.crc := reader.nextBits(16);
  result := S_OK;
end;

// --  --
constructor unaMpegAudio_layer123.create(reader: unaBitReader_abstract);
begin
  f_reader := reader;
  //
  f_cMpegID := -1;
  f_cSamplingRate := -1;
  f_cLayer := -1;
  //
  f_mpgSPF := -1;
  f_mpgSR := -1;
  f_mpgLayer := -1;
  f_mpgChannels := -1;
  f_mpgID := -1;
  //
  inherited create();
end;

// --  --
function unaMpegAudio_layer123.error_check(var h: unaMpegHeader): HRESULT;
begin
  if (0 = h.protection_bit) then
    result := crc_check(h)
  else
    result := S_OK;
end;

// --  --
function unaMpegAudio_layer123.nextFrame(var h: unaMpegHeader; out foundAt: int64; out skipOnResynch: int; outBuf: pointer; out frameSize: int; panicOnSmallBuf: bool): HRESULT;
var
  v: uint32;
  rsOfs: int64;
  minSize: int;
begin
  result := HRESULT(-1);
  skipOnResynch := 0;
  rsOfs := reader.bitOfs;
  frameSize := 0;
  if (panicOnSmallBuf) then
    minSize := 2000 shl 3
  else
    minSize := 40 shl 3;
  //
  while (not f_reader.EOF(minSize)) do begin
    //
    reader.skipToByte();
    reader.setOutfillBuf(outBuf);
    //
    v := reader.nextBits(12);
    if (($FFF = v) or ($FFE = v)) then begin    // synch?
      //
      readHeader(h);
      if ((0 <> h.layer) and
	  ($F <> h.bitrate_index) and
	  ($3 <> h.sampling_frequency) and
	  ($2 <> h.emphasis)) then begin
	//
	if (-1 = f_cSamplingRate) then
	  f_cSamplingRate := h.sampling_frequency;
	if (-1 = f_cLayer) then
	  f_cLayer := h.layer;
	if (-1 = f_cMpegID) then
	  f_cMpegID := h.ID;
	//
	if ((f_cSamplingRate = h.sampling_frequency) and
	    (f_cLayer = h.layer) and
	    (f_cMpegID = h.ID)) then begin
	  //
	  foundAt := (reader.bitOfs - 32) shr 3;
	  if (not f_reader.EOF(16)) then
	    result := error_check(h)
	  else
	    result := HRESULT(-2);
	  //
	  if (SUCCEEDED(result)) then begin
	    //
	    if (-1 = f_mpgID)       then f_mpgID       := 2 - h.ID + choice($FFE = v, 1, int(0));
	    if (-1 = f_mpgSPF)      then f_mpgSPF      := choice(3 = h.layer, 384, choice(1 < mpegID, 576, int(1152)));
	    if (-1 = f_mpgLayer)    then f_mpgLayer    := 4 - h.layer;
	    if (-1 = f_mpgChannels) then f_mpgChannels := choice(3 = h.mode, 1, int(2));
	    if (-1 = f_mpgSR)       then f_mpgSR       := c_mpegFreq[mpegID][h.sampling_frequency];
	    //
	    audio_data(h);
	    ancillary_data(h);
	    //
	    frameSize := reader.outfillOfs;
	    //
	    break;
	  end
	  else
	    foundAt := 0;
	  //
	end;
	//else
	  //reader.moveBitOfs(-4); // ID, freq or layer changed
      end;
      //else
      //	reader.moveBitOfs(-4); // false synch found
    end
    else begin
      //
      if ($494 = v) then begin  // ID3 tag?
	//
	v := reader.nextBits(12);
	if ($433 = v) then begin
	  //
	  v := reader.nextBits(16);	// read version
	  if ($FF > (v and $FF)) and ($FF > (v shr 8)) then begin
	    //
	    v := reader.nextBits(8);	// read flags
	    //exPresent := (0 <> (v and $40));
	    //
	    if (0 = (v and $1F)) then begin
	      //
	      v := reader.nextBits(32);	// read size
	      if (0 = (v and $80808080)) then begin
		//
                {$IFDEF CPU64 }
                v := (v and $7F) or ((v shr 1) and $7F80) or (((v shr 1) and $7F8000) shr 1) or (((v shr 1) and $7F800000) shr 2);
                {$ELSE }
		asm
		    push	ebx

		    mov		ebx, v
		    and		ebx, 07Fh

		    mov		eax, v
		    shr		eax, 1
		    and		eax, 07F80h
		    or		ebx, eax

		    mov		eax, v
		    shr		eax, 1
		    and		eax, 07F8000h
		    shr		eax, 1
		    or		ebx, eax

		    mov		eax, v
		    shr		eax, 1
		    and		eax, 07F800000h
		    shr		eax, 2
		    or		ebx, eax

		    mov		v, ebx

		    pop	ebx
		end;
                {$ENDIF CPU64 }
		//
		// skip ID3 tag
		reader.outfill := false;	// no need to read this into out buffer
		reader.skipBytes(v);
	      end;
	    end;
	  end;
	end;
      end // if ($494 = v) ?
      else
	reader.moveBitOfs(-4);
      //
    end; // if ($FFF = v) ?
    //
    inc(skipOnResynch, reader.bitOfs - rsOfs);
    rsOfs := reader.bitOfs;
  end; // while
  //
  skipOnResynch := skipOnResynch shr 3;
end;

// --  --
function unaMpegAudio_layer123.readHeader(var h: unaMpegHeader): unsigned;
begin
  with h do begin
    //
    ID			:= reader.nextBits(1);
    layer		:= reader.nextBits(2);
    protection_bit	:= reader.nextBits(1);
    bitrate_index	:= reader.nextBits(4);	// 8
    //
    sampling_frequency	:= reader.nextBits(2);
    padding_bit		:= reader.nextBits(1);
    private_bit		:= reader.nextBits(1);
    mode		:= reader.nextBits(2);
    mode_extension	:= reader.nextBits(2);	// 8
    //
    copyright		:= reader.nextBits(1);
    originalCopy	:= reader.nextBits(1);
    emphasis		:= reader.nextBits(2);  // 4
  end;
  //
  result := 0;
end;



// ---------------------------------------
// MPEG TS
// ---------------------------------------



{ unaMpegTS_pwnID }

// --  --
constructor unaMpegTS_pwnID.create(ID: TPID; reader: unaBitReader_abstract; var len: int);
begin
  f_ID := ID;
  f_desc2 := unaMpegTSDescriptorList.Create();
  //
  inherited create();
  //
  reparse(reader, len);
end;

// --  --
destructor unaMpegTS_pwnID.Destroy();
begin
  inherited;
  //
  freeAndNil(f_desc2);
end;

// --  --
procedure unaMpegTS_pwnID.reparse(reader: unaBitReader_abstract; var len: int);
begin
  len := 0;
end;



{ unaMpegTS_pwnIDList }

// --  --
constructor unaMpegTS_pwnIDList.Create();
begin
  inherited Create(uldt_obj, true);
  //
  allowDuplicateId := false;
end;

// --  --
function unaMpegTS_pwnIDList.getId(item: pointer): int64;
begin
  if (nil <> item) then
    result := unaMpegTS_pwnID(item).ID
  else
    result := -1;
end;



{ unaMpegTSDescriptor }

// --  --
function unaMpegTSDescriptor.getAsString(): string;
var
  i: int;
  a: aString;
begin
  if (0 < dataLen) then begin
    //
    setLength(a, dataLen);
    move(f_data, a[1], dataLen);
    for i := 1 to dataLen do
      if (not (ord(a[i]) in [32..127])) then
	a[i] := ' ';
    //
    result := trimS(string(a));
  end
  else
    result := '';
end;

// --  --
function unaMpegTSDescriptor.getData(): pArray;
begin
  result := pArray(@f_data);
end;

// --  --
procedure unaMpegTSDescriptor.reparse(reader: unaBitReader_abstract; var len: int);
var
  consumed: int;
begin
  f_ID := reader.nextBits(8);
  f_dataLen := min(reader.nextBits(8), min(sizeof(f_data), len - 2));
  consumed := 2;
  //
  f_dataLen := reader.readBytes(f_dataLen, @f_data);
  inc(consumed, f_dataLen);
  //
  len := consumed;
end;


{ unaMpegTSDescriptorList }

// --  --
procedure unaMpegTSDescriptorList.addDesc(reader: unaBitReader_abstract; var len: int);
var
  ds: unaMpegTSDescriptor;
  index: int;
  lenConsumed, maxLen: int;
begin
  maxLen := len;
  while ( (maxLen > 0) and not reader.EOF() ) do begin
    //
    lenConsumed := maxLen;
    ds := unaMpegTSDescriptor.Create(0, reader, lenConsumed);
    index := indexOfId(ds.ID);
    if (0 <= index) then
      removeByIndex(index);
    //
    add(ds);
    //
    dec(maxLen, lenConsumed);
  end;
  //
  if (0 < maxLen)  then
    len := len - maxLen;
end;

// --  --
function unaMpegTSDescriptorList.getDAsString(tag: TPID): string;
var
  D: unaMpegTSDescriptor;
begin
  D := itemByID(tag);
  if (nil <> D) then
    result := D.asString
  else
    result := '';
end;


{ unaMpegTSEvent }

// --  --
constructor unaMpegTSEvent.create(evID, TSID, NID, srvID: TPID; reader: unaBitReader_abstract; var len: int);
begin
  f_ts_id := TSID;
  f_network_id := NID;
  f_service_id := srvID;
  //
  inherited create(evID, reader, len);
end;

// --  --
function unaMpegTSEvent.getST(): uint64;
begin
  result := 0;
  move(f_start_time, result, 5);
end;

// --  --
procedure unaMpegTSEvent.reparse(reader: unaBitReader_abstract; var len: int);
var
  b: byte;
  des_len: int;
  consumed: int;
begin
  if (10 < len) then begin
    //
    f_start_time[0] := reader.nextBits(8);
    f_start_time[1] := reader.nextBits(8);
    f_start_time[2] := reader.nextBits(8);
    f_start_time[3] := reader.nextBits(8);
    f_start_time[4] := reader.nextBits(8);        // +5
    //
    f_duration := reader.nextBits(24);            // +3
    f_running_status := reader.nextBits(3);
    b := reader.nextBits(1);
    f_free_CA_mode := (0 <> b);
    //
    consumed := 10;
    //
    des_len := min(len - consumed, reader.nextBits(12));     // +2
    desc.addDesc(reader, des_len);
    inc(consumed, des_len);	// assume we read them all
    //
    len := consumed;
  end
  else
    len := 0;	// dont read anything
end;


{ unaMpegTSService }

// --  --
constructor unaMpegTSService.create(srvID, NID, TSID: TPID; this: bool; reader: unaBitReader_abstract; var len: int);
begin
  f_network_id := NID;
  f_ts_id := TSID;
  //
  inherited create(srvID, reader, len);
end;

// --  --
procedure unaMpegTSService.reparse(reader: unaBitReader_abstract; var len: int);
var
  des_len: int;
  consumed: int;
begin
  if (6 < len) then begin
    //
    {reserved_future_use :=} reader.nextBits(6);
    f_EIT_schedule_flag := reader.nextBits(1);
    f_EIT_present_folloing_flag := reader.nextBits(1);
    f_running_status := reader.nextBits(3);
    f_free_CA_mode  := reader.nextBits(1);
    //
    consumed := 3;
    //
    des_len := min(len - consumed, reader.nextBits(12));     // +2
    desc.addDesc(reader, des_len);
    inc(consumed, des_len);	// assume we read them all
    //
    len := consumed;
  end
  else
    len := 0;	// dont read anything
end;


{ unaMpegES }

// --  --
constructor unaMpegES.Create(PID, NID: TPID; continuity: int);
var
  dummy: int;
begin
  f_continuity := continuity;
  f_NID := NID;
  //
  if (0 <= continuity) then
    f_totalCnt := 1;
  //
  dummy := 0;
  inherited Create(PID, nil, dummy);
end;

// --  --
function unaMpegES.updateContinuity(continuity_counter: int): bool;
begin
  if (0 > f_continuity) then begin
    //
    if (0 = continuity_counter) then
      f_continuity := 15
    else
      f_continuity := continuity_counter - 1;
  end;
  //
  inc(f_continuity);
  if (15 < f_continuity) then
    f_continuity := 0;
  //
  result := (f_continuity = continuity_counter);
  //
{$IFDEF LOG_UNAMPEGAUDIO_INFOS }
  if (not result) then
    logMessage('MPEG-TS: PID=' + int2str(ID) + ', continuity expected ' + int2str(f_continuity) + '; got ' + int2str(continuity_counter));
{$ENDIF LOG_UNAMPEGAUDIO_INFOS }
  //
  // update continuity anyways
  f_continuity := continuity_counter;
  //
  if (result) then
    inc(f_totalCnt);
end;


{ unaMpegTSProgram }

// --  --
constructor unaMpegTSProgram.Create(num, PMT, PCR: TPID);
var
  dummy: int;
begin
  f_PID_PMT := PMT;
  f_PID_PCR := PCR;
  //
  f_streams := unaList.create(uldt_int32, true);
  //
  inherited Create(num, nil, dummy);
end;

// --  --
destructor unaMpegTSProgram.Destroy();
begin
  inherited;
  //
  freeAndNil(f_streams);
end;


{ unaMpegTSNetwork }

// --  --
constructor unaMpegTSNetwork.create(dex: unaMpegTSDemuxer; ID: TPID; reader: unaBitReader_abstract; var len: int);
begin
  f_demuxer := dex;
  //
  inherited create(ID, reader, len);
end;

// --  --
procedure unaMpegTSNetwork.reparse(reader: unaBitReader_abstract; var len: int);
var
  maxLen, maxLen2, consumed: int;
  //
  esID, esNID: int;
  ES: unaMpegES;
begin
  {reserved_future_use := } reader.nextBits(4); {4 bslbf}
  maxLen := reader.nextBits(12); {12 uimsbf}
  consumed := 2;
  //
  maxLen := min(len - consumed, maxLen);
  desc.addDesc(reader, maxLen);
  inc(consumed, maxLen);
  //
  if (2 <= len - consumed) then begin
    //
    {reserved_future_use := } reader.nextBits(4); {4 bslbf}
    maxLen := reader.nextBits(12); { 12 uimsbf }
    inc(consumed, 2);
    //
    maxLen := min(len - consumed, maxLen);
    while (6 <= maxLen) do begin
      //
      esID := reader.nextBits(16); {16 uimsbf}
      esNID := reader.nextBits(16); {16 uimsbf}
      //
      ES := f_demuxer.estreams.itemById(esID);
      if (nil = ES) then begin
	//
	ES := unaMpegES.Create(esID, esNID, -1);
	f_demuxer.estreams.add(ES);
      end
      else
        ES.f_NID := esNID;	// update NID in case it was wrong
      //
      {reserved_future_use := } reader.nextBits(4); {4 bslbf}
      maxLen2 := reader.nextBits(12); { 12 uimsbf }
      //
      inc(consumed, 6);
      dec(maxLen, 6);
      //
      maxLen2 := min(maxLen, maxLen2);
      ES.desc.addDesc(reader, maxLen2);
      inc(consumed, maxLen2);
      dec(maxLen, maxLen2);
    end;
  end;
  //
  len := consumed;
end;


{ unaMpegTSDemuxerSectionReader }

// --  --
procedure unaMpegTSDemuxerSectionReader.append(reader: unaBitReader_abstract; var len: int; ps: bool);
var
  ptr: int;
  skip: int;
  consumed, consumed2: int;
begin
  consumed := 0;
  //
  if (ps) then begin
    //
    // section payload starts with 1 byte pointer
    ptr := reader.nextBits(8);
    inc(consumed);
    //
    if (ptr < len) then begin
      //
      // were we waiting for more data?
      if (0 < f_expectedLen) then begin
	//
	// data after pointer should be all ours
	//
	// read up to ptr bytes from reader, parse section
	consumed2 := min(ptr, f_expectedLen - bytesLeft);
	readFrom(reader, consumed2);
	inc(consumed, consumed2);
	//
	// still not full section?
	if (bytesLeft < f_expectedLen) then begin
	  //
	  // fill rest of section with zeroes
	  skip := f_expectedLen - bytesLeft;
	  fillChar(f_subReadBuf[0], skip, #0);
	  write(@f_subReadBuf, skip);
	end;
	//
	parse(self, skip);
	//
	if (consumed2 < ptr) then begin
	  //
	  reader.skipBytes(ptr - consumed2);
	  inc(consumed, ptr - consumed2);
	end;
	//
	// start of a new section
	consumed2 := len - consumed;
	startOver(reader, consumed2);
	inc(consumed, consumed2);
      end
      else begin
	//
	// skip the ptr bytes and prepare for new section
	skip := min(len - consumed, ptr);
	if (0 < skip) then begin
	  //
	  reader.skipBytes(skip);
	  inc(consumed, skip);
	end;
	//
	// start of a new section
	consumed2 := len - consumed;
	startOver(reader, consumed2);
	inc(consumed, consumed2);
      end;
    end
    else begin
      //
      // ptr seems to be wrong, start over new session next time
      restart();
    end;
  end
  else begin  // not a payload start
    //
    // were we waiting for more data?
    if (0 < f_expectedLen) then begin
      //
      // read rest of bytes from reader, and parse section (if complete)
      consumed2 := min(len - consumed, f_expectedLen - bytesLeft);
      readFrom(reader, consumed2);
      inc(consumed, consumed2);
      //
      if (bytesLeft >= f_expectedLen) then begin
	//
	// ok, all data is here, lets parse it
	parse(self, skip);
	//
	restart();
      end;
    end
    else begin
      //
      // we are in a middle of some unknown payload, just skip it all over
      reader.skipBytes(len);
      consumed := len;
    end;
  end;
  //
  len := consumed;
end;

// --  --
constructor unaMpegTSDemuxerSectionReader.create(dex: unaMpegTSDemuxer; PID: TPID; reader: unaBitReader_abstract; var len: int);
begin
  inherited create();
  //
  f_demuxer := dex;
  f_pid := PID;
  //
  append(reader, len, true);
end;

// --  --
procedure unaMpegTSDemuxerSectionReader.doRestart();
begin
  inherited;
  //
  f_expectedLen := 0;
end;

// --  --
procedure unaMpegTSDemuxerSectionReader.header(reader: unaBitReader_abstract; var len: int);
var
  c, bit1: int;
begin
  if (2 < len) then begin
    //
    f_table_id := reader.nextBits(8);
    if (c_table_id_forbidden <> f_table_id) then begin
      //
      bit1 := reader.nextBits(1);	// should be 1
      {bit0 := } reader.nextBits(1);	// should be 0
      {res2 := } reader.nextBits(2);	// reserved
      //
      f_syntax := (0 <> bit1);
      //
      f_expectedLen := reader.nextBits(12);	// we read 5 bytes after this field
      if (f_syntax) then begin
	//
	f_subID := reader.nextBits(16);	// sub ID
	//
	{res2 := } reader.nextBits(2);	// reserved
	f_version := reader.nextBits(5);	// version
	c := reader.nextBits(1);		// current?
	f_current := (0 <> c);
	f_sec_num := reader.nextBits(8);
	f_sec_lastNum := reader.nextBits(8);
	//
	dec(f_expectedLen, 5);
	len := 8;
      end
      else begin
	//
	// unknown section syntax (probably private section?)
	len := 3;
      end;
    end
    else begin
      //
      // looks like padding, eat it up
      reader.skipBytes(len - 1);
    end;
  end
  else begin
    // section is too small even for a mandatory table_id + syntax bit + section_lenght fields, pretend we did not see anything
    f_expectedLen := 0;
    len := 0;
  end;
end;

// --  --
procedure unaMpegTSDemuxerSectionReader.parse(reader: unaBitReader_abstract; out consumed: int);
var
  consumed2,
  len: int;
  //
  stuff: uint32;
  evid: int;
  //
  nid, stype, map, maxLen, ESLen: int;
  ES: unaMpegES;
  P: unaMpegTSProgram;
  EV: unaMpegTSEvent;
  S: unaMpegTSService;
  N: unaMpegTSNetwork;
  //
//  CRC32: uint32;
begin
  len := f_expectedLen;
  consumed := 0;	// so far
  //
  case (f_table_id) of
    //
    c_table_id_PAT: begin // program_association_section
      //
      // subID - TS ID
      //
      f_demuxer.f_ts_id := subID;	// udpate TS ID
      //
      while (consumed < len - 4) do begin
	//
	stuff := reader.nextBits(16);		// program NUM
	map   := reader.nextBits(16) and $1FFF;	// mapped PID
	inc(consumed, 4);
	//
	if (0 = stuff) then
	  f_demuxer.f_NID := map
	else begin
	  //
	  P := f_demuxer.programs.itemById(stuff);
	  if (nil = P) then begin
	    //
	    P := unaMpegTSProgram.Create(stuff, map, $FFFFFFFF); // PRC PID is not known yet
	    f_demuxer.f_programs.add(P);
	  end;
	  //
	  P.f_PID_PMT := map;	// update PMT_PID just in case
	end;
      end;
      //
      {CRC32 := }reader.nextBits(32);
      inc(consumed, 4);
    end;

    c_table_id_CAT: begin // conditional_access_section
      //
      // subID - not used
      //
      ES := f_demuxer.estreams.itemById(PID);
      if (nil <> ES) then begin
	//
	maxLen := len - consumed;
	if (4 < maxLen) then begin
	  //
	  ES.desc.addDesc(reader, maxLen);
	  inc(consumed, maxLen);
	end;
      end;
      //
      {CRC32 := }reader.nextBits(32);
      inc(consumed, 4);
    end;

    c_table_id_PMT: begin // program_map_section
      //
      // subID - program num (ID)
      //
      //
      {stuff := }reader.nextBits(3);
      map := reader.nextBits(13);	// PCR PID
      {stuff := }reader.nextBits(4);
      maxLen := reader.nextBits(12);	// program_info_length
      //
      inc(consumed, 4);
      //
      P := f_demuxer.programs.itemById(subID);	// subID here is program number
      if (nil = P) then begin
	//
	P := unaMpegTSProgram.Create(subID, $FFFFFFFF, map);	// PMT not known yet
	f_demuxer.f_programs.add(P);
      end;
      //
      P.f_PID_PCR := map;	// update PCR_PID just in case
      //
      maxLen := min(maxLen, len - consumed);
      if (0 < maxLen) then begin
	//
	P.desc.addDesc(reader, maxLen);
	inc(consumed, maxLen);
      end;
      //
      P.streams.clear();
      //
      // do we have at least 5 bytes?
      while (consumed <= len - 5) do begin
	//
	stype := reader.nextBits(8);	// stream type
	{stuff := }reader.nextBits(3);	//
	map := reader.nextBits(13);	// PID
	{stuff := }reader.nextBits(4);	//
	ESLen := reader.nextBits(12);	// length of descriptors for this stream
	//
	inc(consumed, 5);
	//
	P.streams.add(map);
	//
	ES := f_demuxer.estreams.itemById(map);
	if (nil = ES) then begin
	  //
	  ES := unaMpegES.Create(map, f_demuxer.NID, -1);
	  f_demuxer.f_estreams.add(ES);
	end;
	//
	ES.f_streamType := stype;
	ES.f_NID := f_demuxer.NID;	// update in case demuxer's NID was updated
	//
	maxLen := min(ESLen, len - consumed);
	ES.desc.addDesc(reader, maxLen);
	inc(consumed, maxLen);
      end;
      //
      {CRC32 := }reader.nextBits(32);
      inc(consumed, 4);
    end;

    c_table_id_TSDT: begin // transport_stream_description_section
      //
      // subID - program num (ID)
      //
      maxLen := len - consumed;
      f_demuxer.f_descripors.addDesc(reader, maxLen);
      inc(consumed, maxLen);
      //
      {CRC32 := }reader.nextBits(32);
      inc(consumed, 4);
    end;

    c_table_id_EIT_a, 	// event_information_section - actual_transport_stream, present/following
    c_table_id_EIT_o, 	// event_information_section - other_transport_stream, present/following
    $50..$5F, 		// event_information_section - actual_transport_stream, schedule
    $60..$6F: begin 	// event_information_section - other_transport_stream, schedule
      //
      // subID - service ID
      //
      //
      map := reader.nextBits(16);	// transport_stream_id		16
      nid := reader.nextBits(16);	// original_network_id		16
      {last_num := }reader.nextBits(8);	// segment_last_section_number	8
      {num := }reader.nextBits(8);	// last_table_id			8
      //
      inc(consumed, 6);
      //
      // do we have at least 14 bytes?
      while (consumed <= len - 14) do begin
	//
	evid := reader.nextBits(16);
	inc(consumed, 2);
	//
	consumed2 := len - consumed;
	EV := unaMpegTSEvent.create(evid, map, nid, subID, reader, consumed2);
	try
	  f_demuxer.onDX_Event(PID, EV);
	  //
	  inc(consumed, consumed2);
	finally
	  freeAndNil(EV);
	end;
      end;
      //
      {CRC32 := }reader.nextBits(32);
      inc(consumed, 4);
    end;

    c_table_id_SDT_o,
    c_table_id_SDT_ats: begin 	// service_description_section - actual_transport_stream
      //
      // subID - TS ID
      //
      nid := reader.nextBits(16);
      {reserved := } reader.nextBits(8);
      //
      inc(consumed, 3);
      //
      while (8 < len - consumed) do begin
	//
	evid := reader.nextBits(16);	// service id 		16
	inc(consumed, 2);
	//
	maxLen := len - consumed;
	S := f_demuxer.services.itemById(evid);
	if (nil = S) then begin
	  //
	  S := unaMpegTSService.create(evid, nid, subID, (c_table_id_SDT_ats = f_table_id), reader, maxLen);
	  f_demuxer.services.add(S);
	end
	else
	  S.reparse(reader, maxLen);
	//
	inc(consumed, maxLen);
      end;
      //
      {CRC32 := }reader.nextBits(32);
      inc(consumed, 4);
    end;

    c_table_id_TDT, 		// time_date_section
    c_table_id_TOT: begin		// time_offset_section
      // no one cares
      reader.skipBytes(len);
      consumed := len;
    end;

    c_table_id_NIT_a, 		// network_information_section - actual_network
    c_table_id_NIT_o: begin 		// network_information_section - other_network
      //
      // subID - network ID
      //
      consumed2 := len;
      //
      N := f_demuxer.networks.itemById(subID);
      if (nil = N) then begin
	//
	N := unaMpegTSNetwork.create(f_demuxer, subID, reader, consumed2);
        f_demuxer.networks.add(N);
      end
      else
	N.reparse(reader, consumed2);
      //
      inc(consumed, consumed2);
      //
      reader.skipBytes(len);
      consumed := len;
    end;

    //43 to 0x45 reserved for future use
    //47 to 0x49 reserved for future use
    c_table_id_BAT, 		// bouquet_association_section
    //4B to 0x4D reserved for future use
    c_table_id_RST, 		// running_status_section
    c_table_id_ST, 		// stuffing_section
    c_table_id_AIT, 		// application information section (TS 102 812 [15])
    c_table_id_CT, 		// container section (TS 102 323 [13])
    c_table_id_RCT, 		// related content section (TS 102 323 [13])
    c_table_id_CIT, 		// content identifier section (TS 102 323 [13])
    c_table_id_MPE_FEC, 	// MPE-FEC section (EN 301 192 [4])
    c_table_id_RNT, 		// resolution notification section (TS 102 323 [13])
    c_table_id_MPE_IFEC, 	// MPE-IFEC section (TS 102 772 [51])
    //7B to 0x7D reserved for future use
    c_table_id_DIT, 		// discontinuity_information_section
    c_table_id_SIT: begin// selection_information_section
      //
      // no one cares
      reader.skipBytes(len);
      consumed := len;
    end;

    else
      consumed := 0;

  end;
  //
  if (len <> consumed) then begin
    //
    {$DEFINE LOG_UNAMPEGAUDIO_INFO }
    logMessage('[PID=' + int2str(PID) + ']: Not the whole section was parsed (' + int2str(consumed) + ' out of ' + int2str(len) + ')');
    {$DEFINE LOG_UNAMPEGAUDIO_INFO }
  end;
  //
  f_demuxer.onDX_table(PID, f_table_id);
end;

// --  --
procedure unaMpegTSDemuxerSectionReader.readFrom(reader: unaBitReader_abstract; len: int);
begin
  len := reader.readBytes(min(high(f_subReadBuf), len), @f_subReadBuf);
  //
  write(@f_subReadBuf, len);
  //
  readSubBuf(len, true);
end;

// --  --
procedure unaMpegTSDemuxerSectionReader.startOver(reader: unaBitReader_abstract; var len: int);
var
  consumed, consumed2: int;
begin
  restart();
  //
  consumed := 0;
  //
  consumed2 := len;
  header(reader, consumed2);
  inc(consumed, consumed2);
  //
  // do we have a full section here?
  if ((0 < f_expectedLen) and (f_expectedLen <= len - consumed)) then begin
    //
    // parse the section and reset
    consumed2 := len;	// parse() does not use this, as it relies on f_expecedLen,
			// but let assign it anyways
    parse(reader, consumed2);
    inc(consumed, consumed2);
    //
    restart();
  end
  else begin
    //
    // eat rest of data (if any)
    if (0 < f_expectedLen) then begin
      //
      consumed2 := min(len - consumed, f_expectedLen);
      if (0 < consumed2) then begin
	//
	readFrom(reader, consumed2);
	inc(consumed, consumed2);
      end;
    end
    else begin
      //
      // skip padding
      consumed2 := len - consumed;
      reader.skipBytes(consumed2);
      inc(consumed, consumed2);
    end;
  end;
  //
  // do we have some data unparsed?
  while (consumed < len) do begin
    //
    consumed2 := len - consumed;
    //
    // there are seems to be padding only, no need to parse it
    {
    startOver(reader, consumed2);
    }
    // just skip it instead
    reader.skipBytes(consumed2);
    //
    inc(consumed, consumed2);
  end;
  //
  len := consumed;
end;

{ unaMpegSReaderList }

// --  --
constructor unaMpegSReaderList.Create;
begin
  inherited Create(uldt_obj, true);
  //
  allowDuplicateId := false;
end;

// --  --
function unaMpegSReaderList.getId(item: pointer): int64;
begin
  if (nil <> item) then
    result := unaMpegTSDemuxerSectionReader(item).PID
  else
    result := -1;
end;



{ unaMpegTSDemuxer }

// --  --
function unaMpegTSDemuxer.adaptation_field(maxLen: int): int;
var
  adaptation_field_length: int;
begin
  adaptation_field_length := min(maxLen, reader.nextBits(8));
  if (0 < adaptation_field_length) then
    reader.skipBytes(adaptation_field_length);	// just ignore the adaptation block for now
  //
  {$IFDEF LOG_UNAMPEGAUDIO_TSX }
  logMessage('Adaptation: ' + int2str(adaptation_field_length) + ' bytes.');
  {$ENDIF LOG_UNAMPEGAUDIO_TSX }
  //
  result := adaptation_field_length;
end;

// --  --
constructor unaMpegTSDemuxer.Create(reader: unaBitReader_abstract);
begin
  f_reader := reader;
  f_estreams := unaMpegTS_pwnIDList.Create();
  f_programs := unaMpegTS_pwnIDList.Create();
  f_sreaders := unaMpegSReaderList.Create();
  f_descripors := unaMpegTSDescriptorList.Create();
  f_services := unaMpegTS_pwnIDList.create();
  f_networks := unaMpegTS_pwnIDList.create();
  //
  f_stat := malloc(sizeof(unaMpegTSDemuxerStat), true, 0);
  //
  f_NID := TPID(-1);	// = not specified
  //
  inherited Create();
end;

// --  --
function unaMpegTSDemuxer.demux(loop, lookupSynch: bool; userData: pointer): bool;
var
  sync_byte,
  transport_error_indicator,
  payload_unit_start_indicator,
  transport_priority,
  continuity_counter,
  transport_scrambling_control,
  adaptation_field_control: int;
  PID: TPID;
  cok, skip: bool;
  consumedBytes, PS_len: int;
  streamID: int;
  cnt: bool;
  ES: unaMpegES;
  r: unaMpegTSDemuxerSectionReader;
  outOfSynch: bool;
begin
  result := false;	// no packets demuxed yet
  cnt := true;		// continue the loop, at least once
  //
  reader.readSubBuf(c_TS_packet_size - reader.sbLeft(), true);	// try to load the full packet
  //
{$IFDEF LOG_UNAMPEGAUDIO_TSX }
  logMessage('Got new ' + int2str(reader.bytesLeft) + ' bytes');
{$ENDIF LOG_UNAMPEGAUDIO_TSX }
  //
  outOfSynch := false;
  //
  while (cnt and (c_TS_packet_size <= reader.sbLeft())) do begin
    //
  {$IFDEF LOG_UNAMPEGAUDIO_TSX }
    logMessage('Parsing subuf size/at ofs: ' + int2str(reader.f_sbSize) + '/ @'  + int2str(reader.f_sbOfs));
  {$ENDIF LOG_UNAMPEGAUDIO_TSX }
    //
    sync_byte := reader.nextBits(8);
    if ($47 = sync_byte) then begin
      //
      outOfSynch := false;
      //
      inc(f_stat.r_totalPackets);
      result := true;
      //
      // fixed header, 24 bits
      transport_error_indicator := reader.nextBits(1);
      payload_unit_start_indicator := reader.nextBits(1);
      transport_priority := reader.nextBits(1);
      PID := reader.nextBits(13);
      transport_scrambling_control := reader.nextBits(2);
      adaptation_field_control := reader.nextBits(2);
      continuity_counter := reader.nextBits(4);
      //
    {$IFDEF LOG_UNAMPEGAUDIO_TSX }
      logMessage('Packet #' + int2str(f_totalPackets) + '; PID=' + int2str(PID));
    {$ENDIF LOG_UNAMPEGAUDIO_TSX }
      //
      consumedBytes := 1 + 3;	// synch and 3 bytes header
      //
      // skip this packet?
      skip := (0 <> transport_error_indicator) or (c_PID_null = PID);
      if ( not skip and (0 <> adaptation_field_control) )  then begin
	//
	// adaptation?
	if ( ($3 = adaptation_field_control) or ($2 = adaptation_field_control) ) then
	  inc(consumedBytes, adaptation_field(c_TS_packet_size - consumedBytes) + 1);	// skip adaptation block, 1 is for length field, which is always present (1 byte)
	//
	// do we have any payload?
	if (($1 = adaptation_field_control) or ($3 = adaptation_field_control)) then begin
	  //
	  r := nil;
	  //
	  // check if we have ES with this PID already
	  ES := self.estreams.itemById(PID);
	  if (nil = ES) then begin
	    //
	    // add new stream
	    ES := unaMpegES.Create(PID, NID, continuity_counter);
	    estreams.add(ES);
	  end
	  else begin
	    //
	    cok := ES.updateContinuity(continuity_counter);
	    if (not cok) then begin
	      //
	      // check if we have section reader on this TS
	      r := f_sreaders.itemById(PID);
	      if (nil <> r) then
		r.restart();	// continuity is broken, forget what you have
	      //
	    end;
	    //
	    skip := not (cok or tolerateContinuity);
	  end;
	  //
	  ES.f_scrambled := (0 <> transport_scrambling_control);
	  ES.f_priority := (0 <> transport_priority);
	  //
	  // ps?
	  if (not skip and (1 = payload_unit_start_indicator)) then begin
	    //
	    // decode PS header
	    PS_len := c_TS_packet_size - consumedBytes;		// max size of PES data
	    skip := not PS_header(PID, streamID, PS_len);	// check if valid header
	    //
	  {$IFDEF LOG_UNAMPEGAUDIO_INFOS }
	    if (skip) then
	      logMessage('MPEG-TS: Unrecognized PS_header (PID=' + int2str(PID) + ').');
	  {$ENDIF LOG_UNAMPEGAUDIO_INFOS }
	    //
	    inc(consumedBytes, PS_len);
	  end
	  else begin
	    //
	    // have section reader waiting for payload?
	    if (nil = r) then
	      r := f_sreaders.itemById(PID);
	    //
	    if (nil <> r) then begin
	      //
	      PS_len := c_TS_packet_size - consumedBytes;		// max size of PES data
	      r.append(reader, PS_len, false);
	      //
	      inc(consumedBytes, PS_len);
	    end;
	  end;
	  //
	  // should we notify payload?
	  if (not skip and (0 < c_TS_packet_size - consumedBytes)) then begin
	    //
	    move(reader.sbAt()^, f_payload, c_TS_packet_size - consumedBytes);
	    //
	  {$IFDEF LOG_UNAMPEGAUDIO_TSX }
	    logMessage('Notifying payload, ' + int2str(c_TS_packet_size - consumedBytes) + ' bytes.');
	  {$ENDIF LOG_UNAMPEGAUDIO_TSX }
	    //
	    onDX_payload(PID, @f_payload, c_TS_packet_size - consumedBytes, userData);
	    //
	    inc(f_stat.r_totalPayload, c_TS_packet_size - consumedBytes);
	  end;
	end; // do we have payload?
	//
      end // packet looks healthy?
      else begin
	//
	inc(f_stat.r_totalPacketsSkipped);
	//
      {$IFDEF LOG_UNAMPEGAUDIO_INFOS }
	if (skip) then begin
	  //
	  if (c_PID_null <> PID) then
	    logMessage('MPEG-TS: Packet [PID=' + int2str(PID) + '] was skipped due to transport error.');
	end;
      {$ENDIF LOG_UNAMPEGAUDIO_INFOS }
      end;
      //
      if (0 < c_TS_packet_size - consumedBytes) then
	reader.skipBytes(c_TS_packet_size - consumedBytes);
      //
      inc(f_statOKPackets);
      inc(f_statPackets);
      //
      // continue demuxing next packet?
      cnt := loop;
    end
    else begin
      //
      if (not outOfSynch) then begin
	//
	outOfSynch := true;
	//
	inc(f_statOOSPackets);
        inc(f_statPackets);
	//
    {$IFDEF LOG_UNAMPEGAUDIO_INFOS }
	logMessage('MPEG-TS: Out of synch, offs=' + int2str(reader.bitOfs shr 3) + '; expected $47, got $' + int2str(sync_byte, 16));
    {$ENDIF LOG_UNAMPEGAUDIO_INFOS }
      end;
      //
      // continue looking for synch?
      cnt := lookupSynch;
    end;
    //
    if (100 < f_statPackets) then begin
      //
      // see if we got too many oos packets
      if (f_statOOSPackets > f_statOKPackets) then begin
	//
	cnt := false;	// got more oos packets than OK packets, no reason to parse any more
	//
    {$IFDEF LOG_UNAMPEGAUDIO_INFOS }
	logMessage('MPEG-TS: Too many out of synch packets, no reason to parse any more');
    {$ENDIF LOG_UNAMPEGAUDIO_INFOS }
      end;
      //
      f_statOOSPackets := 0;
      f_statOKPackets := 0;
      f_statPackets := 0;
    end;
    //
    if (cnt and (reader.sbLeft() < c_TS_packet_size)) then
      reader.readSubBuf(c_TS_packet_size - reader.sbLeft(), true);	// try to load rest of packet
  end;
  //
{$IFDEF LOG_UNAMPEGAUDIO_INFOS }
  if ( (c_TS_packet_size > reader.sbLeft()) and (0 < reader.sbLeft()) ) then
    logMessage('Out of demux bytes, only ' + int2str(reader.sbLeft()) + ' bytes in subBuf left.');
{$ENDIF LOG_UNAMPEGAUDIO_INFOS }
end;

// --  --
destructor unaMpegTSDemuxer.Destroy();
begin
  inherited;
  //
  freeAndNil(f_estreams);
  freeAndNil(f_programs);
  freeAndNil(f_services);
  freeAndNil(f_sreaders);
  freeAndNil(f_descripors);
  freeAndNil(f_networks);
  //
  mrealloc(f_stat);
end;

// --  --
procedure unaMpegTSDemuxer.onDX_table(PID, tableID: TPID);
begin
  // Override to get notified about tables.
end;

// --  --
procedure unaMpegTSDemuxer.onDX_event(PID: TPID; EV: unaMpegTSEvent);
begin
  // Override to get events as they appear in stream.
end;

// --  --
procedure unaMpegTSDemuxer.onDX_payload(PID: TPID; data: pointer; len: int; userData: pointer);
begin
  // override to get demuxed data
end;

// --  --
function unaMpegTSDemuxer.PES_header(PID: TPID; out streamID: int; var len: int): bool;
var
  packet_start_code_prefix: int;
{$IFDEF LOG_UNAMPEGAUDIO_TSX }
  PES_packet_length: unsigned;
{$ENDIF LOG_UNAMPEGAUDIO_TSX }
  stuff: unsigned;
  skip, consumed: int;
begin
  result := false;
  if (6 > len) then
    exit;
  //
  packet_start_code_prefix := reader.nextBits(24);	// +3 = 3
  if ($000001 = packet_start_code_prefix) then begin
    //
    streamID := reader.nextBits(8);			// +1 = 4
    {$IFDEF LOG_UNAMPEGAUDIO_TSX }PES_packet_length := {$ENDIF LOG_UNAMPEGAUDIO_TSX }reader.nextBits(16);		// +2 = 6
    //
    consumed := 6;
    //
    {$IFDEF LOG_UNAMPEGAUDIO_TSX }
    logMessage('PES streamID=' + int2str(streamID) + '; packetlen=' + int2str(PES_packet_length));
    {$ENDIF LOG_UNAMPEGAUDIO_TSX }
    //
    case (streamID) of

      c_PESST_private_stream_2,
      c_PESST_ECM_stream,
      c_PESST_EMM_stream,
	//
	// PES packets of type private_stream_2, ECM_stream and EMM_stream are similar to private_stream_1
	// except no syntax is specified after PES_packet_length field.
	//
      c_PESST_program_stream_map,
      c_PESST_program_stream_directory,
      c_PESST_stream_A_or_DSMCC,
      c_PESST_stream_222_A .. c_PESST_stream_222_E,
      c_PESST_padding_stream: begin
	//
	//
      end;

      else begin  //
	//
	// c_PESST_private_stream_1,
	// c_PESST_audio_stream_x,
	// c_PESST_vdeo_stream_x,
	// c_PESST_stream_13522,
	// c_PESST_ancillary_stream,
	// c_PESST_stream_14496_SL,
	// c_PESST_stream_14496_FlexMux,
	// c_PESST_stream_reserved_FC..c_PID_stream_reserved_FE:
	//
	stuff := reader.nextBits(2);	// '10' 2 bslbf
	if ($02 = stuff) then begin
	  //
	  {
	  nextBits(2);	// nextBitsPES_scrambling_control 2 bslbf
	  nextBits(1);	// PES_priority 1 bslbf
	  nextBits(1);	// data_alignment_indicator 1 bslbf
	  nextBits(1);	// copyright 1 bslbf
	  nextBits(1);	// original_or_copy 1 bslbf
				// len = 7

	  nextBits(2);	// PTS_DTS_flags 2 bslbf
	  nextBits(1);	// ESCR_flag 1 bslbf
	  nextBits(1);	// ES_rate_flag 1 bslbf
	  nextBits(1);	// DSM_trick_mode_flag 1 bslbf
	  nextBits(1);	// additional_copy_info_flag 1 bslbf
	  nextBits(1);	// PES_CRC_flag 1 bslbf
	  nextBits(1);	// PES_extension_flag 1 bslbf
				// len = 8
	  }
	  reader.nextBits(14); // flags, as commented above	// +2=8
	  inc(consumed, 2);
	  //
	  // get size of additional header data
	  inc(consumed);
	  skip := min(reader.nextBits(8), len - consumed); // PES_header_data_length 8 uimsbf // +1=9
	  if (0 < skip) then begin
	    //
	    // skip additional data
	    reader.skipBytes(skip);	// read rest of header
	    inc(consumed, skip);
	  end;
	  //
	  // header is followed by payload
	  //
	  result := true;
	end
	else begin
	  //
	  // wrong packet format?
	  reader.skipToByte();
	  inc(consumed);
	end;
      end;

    end;

  end
  else
    consumed := 3;
  //
  len := consumed;
end;

// --  --
function unaMpegTSDemuxer.PSI_header(PID: TPID; var len: int): bool;
var
  r: unaMpegTSDemuxerSectionReader;
begin
  // find a reader for this PID
  r := f_sreaders.itemById(PID);
  if (nil = r) then begin
    //
    r := unaMpegTSDemuxerSectionReader.create(self, PID, reader, len);
    f_sreaders.add(r);
  end
  else
    r.append(reader, len, true);
  //
  result := true;
end;

// --  --
function unaMpegTSDemuxer.PS_header(PID: TPID; out streamID: int; var len: int): bool;
var
  synch: uint32;
  PSI, PES, knownPES: bool;
  i: int;
begin
  result := false;
  if (6 > len) then
    exit;
  //
  PSI := false;
  PES := false;
  synch := $FFFFFFFF;
  knownPES := false;
  //
  case (PID) of

    // "known" PIDs
    c_PID_PAT, c_PID_CAT, c_PID_TSDT, c_PID_IPMP,
    c_PID_NIT, c_PID_SDT_BAT, c_PID_EIT, c_PID_RST, c_PID_TDT_TOT, c_PID_NS, c_PID_RNT,
    c_PID_IS, c_PID_MEAS, c_PID_DIT, c_PID_SIT:
      PSI := true;

    else begin
      //
      if (f_NID = PID) then
	PSI := true	// NIT
      else begin
	//
	// maybe "known" PES?
	knownPES := (nil <> mscand(@f_known_PES, f_known_PEScount, PID));
	if (not knownPES) then begin
	  //
	  // see if any program has this PID as PMT
	  for i := 0 to f_programs.count - 1 do
	    if ( (PID = unaMpegTSProgram(programs[i]).PID_PMT) ) then
	      PSI := true;
	end
	else
	  PES := true;
      end;
      //
      if (not PES and not PSI) then begin
	//
	// "unknown" PID, see if first 3 bytes are PES synch ($000001)
	synch := 0;
	move(reader.sbAt()^, synch, 3);
	PES := ($10000 = synch);
      end;
    end;

  end;
  //
  if (PSI) then
    result := PSI_header(PID, len)
  else
    if (PES) then begin
      //
      result := PES_header(PID, streamID, len);
      if (result and not knownPES) then begin
	//
	// add this PID to known PES list
	f_known_PES[f_known_PEScount] := PID;
	inc(f_known_PEScount);
      end;
    end
    else begin
      //
      len := 0;
      result := true;	// some (yet) unknown payload
    end;
end;


end.
