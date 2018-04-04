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

	  unaIPStreaming.pas - VC 2.5 basic IP streaming components
	  VC components version 2.5

	----------------------------------------------
	  Copyright (c) 2010-2011 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 08 Feb 2010

	  modified by:
		Lake, Feb-Dec 2010
		Lake, Jan-Jun 2011
		Lake, Jan-Dec 2012

	----------------------------------------------
*)

{$I unaDef.inc }

{$IFDEF DEBUG }
  {$DEFINE LOG_IPStreaming_INFOS }	// log informational messages
  {$DEFINE LOG_IPStreaming_ERRORS }	// log critical errors
{$ENDIF DEBUG }

{*

  Basic IP Streaming classes.

  @author Lake

  	1.0 first release
  
	Jun 11: [+] bitrate property now works with CELT codec

	Oct/Nov 11: [+] G7221, GSM codecs

	Feb 12: [+] RTSP Server

}

unit
  unaIPStreaming;

interface

uses
  Windows, WinSock,
  unaTypes, unaClasses, unaParsers, 						// general classes
  unaVC_pipe,									// pipes
  unaG711, unaG7221, unaSpeexAPI, unaBladeEncAPI, unaMpgLibAPI,			// various audio decoders and encoders
  unaADPCM, unaLibCELT, unaGSM,                                       		// even more audio decoders and encoders
  unaWave,									// low-level wave routines
  unaMpeg,									// MPEG-TS demuxer
  unaRE,
  unaSockets, unaSocks_RTP, unaSocks_RTSP, unaSocks_SHOUT, unaSocks_STUN,	// sockets and protocols
  unaRTPTunnel
  ;

const
  // known protocols
  c_ips_protocol_ERROR	= -1;
  // no protocol
  c_ips_protocol_RAW	= 1;
  // RTP
  c_ips_protocol_RTP	= 2;
  // RTSP
  c_ips_protocol_RTSP	= 3;
  // not yet
  c_ips_protocol_SIP	= 4;
  // SHOUTcast/IceCast
  c_ips_protocol_SHOUT	= 5;

  // known socket types

  // unicast UDP
  c_ips_socket_UDP_unicast	= 1;
  // multicast UDP
  c_ips_socket_UDP_multicast	= 2;
  // broadcast UDP
  c_ips_socket_UDP_broadcast	= 3;
  // TCP socket
  c_ips_socket_TCP		= 4;

  // known additional payloads (defined as 'dynamic')
  // Speex NB (8000)
  c_ips_payload_speexNB		= 110;
  // Speex WB (16000)
  c_ips_payload_speexWB		= 111;
  // Speex UWB (32000)
  c_ips_payload_speexUWB	= 112;
  // t140 text
  c_ips_payload_text		= 113;
  // OGG/Vorbis
  c_ips_payload_vorbis		= 114;
  // VDVI
  c_ips_payload_vdvi		= 115;
  // CELT 16000 mono
  c_ips_payload_celt_16000m	= 116;
  // CELT 24000 mono
  c_ips_payload_celt_24000m	= 117;
  // CELT 48000 stereo
  c_ips_payload_celt_48000s	= 118;
  // GSM49 - MS GSM
  c_ips_payload_GSM49   	= 119;
  // G.722.1 (24kbps)
  c_ips_payload_G7221_24   	= 120;
  // G.722.1 (48kbps)
  c_ips_payload_G7221_48   	= 121;

type
  // known libraries
  unaKnownLibEnum = (
    // lame_enc.dll
    c_lib_lame,
    // libcelt.dll
    c_lib_celt,
    // libmpg123-0.dll
    c_lib_mpg,
    // libspeex.dll
    c_lib_speex,
    // libspeexdsp.dll
    c_lib_speexDSP
  );


  {*
	Parameters passed to onIPStreamOnRTCPApp event
  }
  punaIPStreamOnRTCPAppParams = ^unaIPStreamOnRTCPAppParams;
  unaIPStreamOnRTCPAppParams = record
    r_SSRC: uint32;
    r_fromIP4: uint32;
    r_fromPort: uint16;
    r_cmd: array[0..4] of aChar;
    r_subtype: byte;
    r_data: pointer;
    r_len: int32;
  end;

  {*
	Event fired when new RTCP APP packet is received
  }
  unavcIPStreamOnRTCPApp = procedure(sender: unavclInOutPipe; const params: unaIPStreamOnRTCPAppParams) of object;

  {*
	Basic IP streamer class.
	Contains code shared by IPReceiver and IPTransmitter.
  }
  unaIPStreamer = class(unavclInOutPipe)
  private
    f_loStreamer: unaObject;	// low level streamer
    //
    f_exLib: array[unaKnownLibEnum] of string;
    //
    f_crack: unaURIcrack;
    f_URI: string;
    //
    f_URIHost: string;
    f_URIPort: string;
    f_SDPPort: string;
    f_URIuserName: string;
    f_URIuserPass: string;
    //
    f_active: bool;
    f_protocol: int;
    f_socketType: int;
    f_descInfo: string;
    f_descError: string;
    f_SDP: string;
    f_sdp_role: c_peer_role;
    f_encode: boolean;
    f_frameSize: int;	// samples per frame
    f_memberTR: int;
    //
    f_idleThread: unaThread;
    //
    f_ssrc: u_int32;
    //
    f_mapping: unaRTPMap;
    f_sdpParser: unaSDPParser;
    f_SDPignoreP: boolean;
    //
    f_exvcFormat: unaWaveFormat;	// format for consumers
    //
    f_sps, f_nch, f_bits, f_enc, f_br: int;
    //
    f_bind2port: string;
    f_bind2ip: string;
    f_swrb: boolean;
    //
    f_buf: pointer;
    f_bufSize: unsigned;
    //
    f_bwTM: uint64;
    f_bwInDelta, f_bwOutDelta: int64;
    f_bwIn, f_bwOut: int;
    f_bwAcq: unaAcquireType;
    //
    f_enableRTCP: boolean;
    f_cpa: boolean;
    //
    f_ttl: int;
    //
    f_mpegTS_PID: TPID;
    f_mpegTS_aware: boolean;
    f_mpegTS_enabled: boolean;
    //
    f_STUNserver: string;
    f_STUNPort: string;
    //
    f_onRTCPApp: unavcIPStreamOnRTCPApp;
    f_ignoreLocalIPs: boolean;
    //
    procedure setNewFormat(sps, nch, bits, enc: int; br: int = 0);
    procedure setSDP(const value: string);
    //
    function getMapping(): punaRTPMap;
    //
    procedure updateBW(isIN: bool; delta: int);
    //
    function getTR(): int32;
    procedure setTR(value: int32);
    //
    function getExLib(index: unaKnownLibEnum): string;
    procedure setExLib(index: unaKnownLibEnum; const value: string);
    //
    procedure setSTUNserver(const value: string);
    {*
	Internal RTCP parser.
    }
    procedure parseRTCP(ssrc: u_int32; addr: pSockAddrIn; hdr: prtcp_common_hdr; packetSize: uint; firstOne: bool);
  protected
    {*
	Assigns RTCP parameters (like timeouts, etc).
	Override if additional RTCP configuration is needed.
    }
    procedure setupSessionParams(); virtual;
    {*
	Got idle, do something useful.

	Updates In/Out bandwidth.
    }
    procedure onIdle(); virtual;
    {*
	Got new RTCP packet.
    }
    procedure onRTCP(ssrc: u_int32; addr: PSockAddrIn; hdr: prtcp_common_hdr; packetSize: int); virtual;
    {*
	Some of destinations got BYE or timedout
    }
    procedure onRTCPBye(si: prtp_site_info; soft: bool); virtual;
    {*
	Parses URI and assigns required properties.

	@param value URI to parse
    }
    procedure setURI(const value: string); virtual;
    {*
    }
    function doGetRTCP(): unaRTCPstack; virtual; abstract;
    {*
    }
    procedure onFormatChange(rate, channels, bits, encoding, bitrate: int); virtual;
    {*
    }
    function doOpen(): bool; override;
    {*
    }
    procedure doClose(); override;
    {*
    }
    function getFormatExchangeData(out data: pointer): uint; override;
    {*
	Reads data from the pipe.
    }
    function doRead(data: pointer; len: uint): uint; override;
    {*
	Returns data size available in the pipe (bytes).
    }
    function getAvailableDataLen(index: integer): uint; override;
    {*
	Returns component's active state.

	@return True if component was activated succesfully.
    }
    function isActive(): bool; override;
    {*
	Makes holes in NAT.

	@param st remote socket type, refer c_ips_socket_XXX for valid values.
	@param host remote host
	@param portRTP remote RTP port
	@param portRTCP remote RTCP port. If not specified (default), RTP port + 1 will be used
    }
    procedure needHoles(st: int; const host, portRTP: string; const portRTCP: string = ''); virtual;
    //
    // ---- properties ----
    //
    {*
	Internal, do not use.
    }
    property frameSize: int read f_frameSize write f_frameSize;
    {*
    }
    property URI: string read f_URI write setURI;
    {*
	STUN is needed for RTSP client, for example
    }
    property STUNserver: string read f_STUNserver write setSTUNserver;
    {*
	Read-ony, set STUNServer to change it
    }
    property STUNPort: string read f_STUNPort;
  public
    {*
	Sets initial properties values for streamer
    }
    procedure AfterConstruction(); override;
    {*
	Releases memory buffers, SDP parser and idle thread
    }
    procedure BeforeDestruction(); override;
    //
    {*
	Sends RTCP APP packet to remote side.

	@param subtype command subtype, any integer from 0 to 255
	@param cmd APP command, any 4 ansi characters
	@param data optional data to send
	@param len optional data length (must be aligned to 32-bit)
	@param sendCNAME if True will send CNAME in same packet
	@param toAddr Send to this address only

	@return 0 if data was sent successfully, or specific WSA error otherwise.
    }
    function sendRTCPApp(subtype: byte; const cmd: aString; data: pointer = nil; len: uint = 0; sendCNAME: bool = false; toAddr: PSockAddrIn = nil): int;
    //
    // -- properties --
    //
    {*
	Specifies additional parameters of audio stream.
    }
    property SDP: string read f_SDP write setSDP;
    {*
	Specifies whether port number from SDP will be ignored.
	Default is true.
    }
    property SDPignorePort: boolean read f_SDPignoreP write f_SDPignoreP;
    {*
	RTP mapping used for dynamic payload.
    }
    property mapping: punaRTPMap read getMapping;
    {*
	Host name provided in URI.
	(In case of multicast - this is multicast group address).
    }
    property uriHost: string read f_URIHost;
    {*
	Port number provided in URI.
    }
    property uriPort: string read f_URIPort;
    {*
	Protocol to be used by streamer. See c_ips_protocol_XXX for valid values.
    }
    property protocol: int read f_protocol;
    {*
	Socket type to be used by streamer. See c_ips_socket_XXX for valid values.
    }
    property socketType: int read f_socketType;
    {*
	Stream description (usually received from remote side).
    }
    property descriptionInfo: string read f_descInfo;
    {*
	Stream error message (mostly for debugging).
    }
    property descriptionError: string read f_descError;
    {*
	Swap bytes in 16bit words after receiving them from network before passing to consumer.
	Swap bytes in 16bit words before transmitting them into network.

	Applies for RAW protocol and uncompressed encodings only.
	Default is False.
    }
    property swapRAWbytes: boolean read f_swrb write f_swrb;
    {*
	Bind internal socket to this locat port.
	Default is '0', means use first available port.

	2012.05.01: made read-only, use SDP to assign non-zero port
    }
    property bind2port: string read f_bind2port;
    {*
	Bind internal socket to this IP.
	Default is '0.0.0.0', means bind to all.
    }
    property bind2ip: string read f_bind2ip write f_bind2ip;
    {*
	External library name.
    }
    property exLib[index: unaKnownLibEnum]: string read getExLib write setExLib;
    {*
	Input bandwidth.
    }
    property inBandwidth: int read f_bwIn;
    {*
	Output bandwidth.
    }
    property outBandwidth: int read f_bwOut;
    {*
	SSRC
    }
    property _SSRC: u_int32 read f_ssrc write f_ssrc;
    {*
	RTCP stack. Could be nil.
    }
    property rtcp: unaRTCPstack read doGetRTCP;
    {*
	TTL for multicast.
    }
    property TTL: int read f_ttl write f_ttl;
    {*
	If True (default) - Reveiver: checks if payload is encapsulated in MPEG-TS stream and decode audio specifed by mpegTS_PID.
			    Transmitter: encapsulate audio into MPEG-TS (not implemented yet).

	Applies to RAW and RTP MP2T payloads only.
    }
    property mpegTS_aware: boolean read f_mpegTS_aware write f_mpegTS_aware;
    {*
	True (default) if MPEG TS streaming is anabled

	Applies to RAW and RTP MP2T payloads only.
    }
    property mpegTS_enabled: boolean read f_mpegTS_enabled;
    {*
	Specifies bitrate to be used with encodings aware it.
    }
    property bitrate: int read f_br write f_br;
    {*
	User name (used as SDES in RTCP)
    }
    property URIuserName: string read f_URIuserName write f_URIuserName;
    {*
	User password
    }
    property URIuserPass: string read f_URIuserPass write f_URIuserPass;
    {*
	Do not treat local IPs as special case.
	This allows debugging IPTransmitter and IPReceiver on same machine.
    }
    property ignoreLocalIPs: boolean read f_ignoreLocalIPs write f_ignoreLocalIPs;
  published
    {*
	Try to decode/encode supported payloads.
	Default is True.
    }
    property doEncode: boolean read f_encode write f_encode default true;
    {*
	When true the component will use RTCP when applicable (for RTP streaming).
	Default is true.
    }
    property enableRTCP: boolean read f_enableRTCP write f_enableRTCP default true;
    {*
	When true the component will analyze custom payloads (such as c_ips_payload_speexNB and other) and initialize accordingly.
	Default is true.
    }
    property customPayloadAware: boolean read f_cpa write f_cpa default true;
    {*
	RTCP stack timeout. Set to 0 to disable. Default is 6.
    }
    property rtcpTimeoutReports: int32 read getTR write setTR default 6;
    {*
	MPEG TS PID to use.
    }
    property mpegTS_PID: TPID read f_mpegTS_PID write f_mpegTS_PID;
    {*
    }
    property onRTCPApp: unavcIPStreamOnRTCPApp read f_onRTCPApp write f_onRTCPApp;
    //
    property isFormatProvider;
    property onDataAvailable;
    property onFormatChangeAfter;
    property onFormatChangeBefore;
  end;


const
  // time interval to wait for before re-connecting receiver in case of no data
  c_receiver_noDataWatchDogTimeout	= 20000;	// 20 sec

type
  //
  unavcIPStreamerTextEvent = procedure(sender: unavclInOutPipe; const data: pwChar) of object;
  unavcIPReceiverRTPHdr = procedure(sender: unavclInOutPipe; hdr: prtp_hdr; data: pointer; len: integer) of object;
  //
  unavcIPDataWrite = procedure(sender: unavclInOutPipe; data: pointer; len: integer; out newData: pointer; out newLen: integer) of object;

  {*
	Basic IP receiving class.
  }
  TunaIPReceiver = class(unaIPStreamer)
  private
    f_receiverRTP: unaRTPReceiver;
    f_receiverRTSP: unaRTSPClient;
    f_receiverSHOUT: unaSHOUTReceiver;
    //
    f_dataWatchDog: unaThread;
    f_keepWD: bool;	// keep WD thread running
    //
    f_addrRTP, f_addrRTCP: sockaddr_in;	// dest addresses
    f_addrST: int;			// dest socket type
    //
    f_noHoles: bool;
    //
    f_decoderMPEG: unaLibmpg123Decoder;
    f_speexLib: unaSpeexLib;
    f_decoderSpeex: unaSpeexDecoder;
    f_decoderADPCM: unaADPCM_decoder;
    f_decoderCELT: unaLibCELTdecoder;
    f_decoderG7221: unaG7221Decoder;
    f_decoderGSM: unaGSMDecoder;
    //
    f_onText: unavcIPStreamerTextEvent;
    f_onRTPHdr: unavcIPReceiverRTPHdr;
    //
    f_onBeforeDecodeWrite: unavcIPDataWrite;
    f_onAfterDecodeWrite: unavcIPDataWrite;
    //
    f_receiverRTSP_session: string;	// internal RTSP session name
    //
    f_mastered: bool;    		// rely on master, do not use own transport
    f_master: unaIPStreamer;
    //
    f_rifnd: boolean;
    //
    f_cnri: int;
    //
    function getDemuxer(): unaMpegTSDemuxer;
    function getCNRI(): int;
    procedure setCNRI(value: int);
  protected
    {*
	Applies required changes on RTCP object.
    }
    procedure setupSessionParams(); override;
    {*
	Returns internal RTCP stack object.
    }
    function doGetRTCP(): unaRTCPstack; override;
    {*
	Fired when new RTP header is received.
    }
    procedure onRTPHdr(hdr: prtp_hdr; data: pointer; len: int); virtual;
    {*
	Fired when new portion of text is received from remote side.
    }
    procedure onNewText(data: pointer; len: int); virtual;
    {*
	Creates and opens internal receiver/decoder classes.
    }
    function doOpen(): bool; override;
    {*
	Closes the receiver.
    }
    procedure doClose(); override;
    {*
	Applies new format on decoders.
    }
    procedure onFormatChange(rate, channels, bits, encoding, bitrate: int); override;
    {*
	Passes compressed data to decoders according to encoding property.
    }
    function doWrite(_data: pointer; _len: uint; provider: pointer = nil): uint; override;
    {*
	Processes new data available from the pipe.

	@return True if successfull.
    }
    function onNewData(_data: pointer; _len: uint; provider: pointer = nil): bool; override;
    {*
	Returns component's active state.

	@return True if component was activated succesfully.
    }
    function isActive(): bool; override;
    {*
	Sends RTCP and RTP packets to remote side to make holes in NAT
    }
    procedure needHoles(st: int; const host, portRTP: string; const portRTCP: string = ''); override;
    {*
	RTSP error
    }
    procedure rtspGotError(const uri, control: string; req: int; errorCode: HRESULT); virtual;
    {*
	RTSP response
    }
    procedure rtspGotResponse(const uri, control: string; req: int; response: unaHTTPparser); virtual;
  public
    {*
	Creates encoders and decoders for receiver
    }
    procedure AfterConstruction(); override;
    {*
	Disposes receivers, encoders and decoders
    }
    procedure BeforeDestruction(); override;
    //
    {*
	Low-level RTP receiver.
    }
    property rec: unaRTPReceiver read f_receiverRTP;
    {*
	MPEG TS demuxer.
    }
    property mpegTS_demuxer: unaMpegTSDemuxer read getDemuxer;
  published
    {*
	RTSP client should use it
    }
    property STUNserver;
    {*
	Possible values:

	-- RAW --
	  udp://192.168.0.10:7654  - receive RAW unicast stream (set SDP to specify stream format)
				    192.168.0.10 	- remote address
				    7654      		- remote port

	  udp://224.0.1.2:7654	   - receive RAW multicast stream (set SDP to specify stream format)
				    224.0.1.2 	- join this multicast group
				    7654	- communicate on this port

	  tcp://192.168.0.170:5008 - RAW unicast TCP stream
				      192.168.0.170 - remote server address
				      5008          - remote server port

	-- RTP --
	  rtp://192.168.0.12:1254  - receive RTP unicast stream (may need additional SDP in case of dynamic payload)
				    192.168.0.12	- use this IP for streaming
				    1254      		- use this port for RTP (1255 will be used for RTCP)

	  rtp://224.0.1.2:1254	- receive RTP multicast stream (may need additional SDP in case of dynamic payload)
				    224.0.1.2 	- join this multicast group
				    1254      	- communicate on this port

	-- RTSP --
	  rtsp://192.168.0.170/ - use RTSP streaming negotiation (check SDP for details)
				    192.168.0.170 - connect to this host for RTSP server
				    Default port is 554

	-- SHOUTcast --
	  http://87.98.132.103:8230	- receive  SHOUTcast stream
				    87.98.132.103 - connect to this host for SHOUTcast stream
				    8230 	  - use this port for communication

    }
    property URI;
    {*
	Fired when new text is received.
    }
    property onText: unavcIPStreamerTextEvent read f_onText write f_onText;
    {*
	Fired when new RTP packet is received.
    }
    property onRTPHeader: unavcIPReceiverRTPHdr read f_onRTPHdr write f_onRTPHdr;
    {*
	Fired before data received from network is about to be passed to decoders.
    }
    property onBeforeDecodeWrite: unavcIPDataWrite read f_onBeforeDecodeWrite write f_onBeforeDecodeWrite;
    {*
	Fired when data is decoded and is about to be passed to consumer(s)
    }
    property onAfterDecodeWrite: unavcIPDataWrite read f_onAfterDecodeWrite write f_onAfterDecodeWrite;
    {*
	Reconnects to remote stream if no data is received for some time.
    }
    property reconnectIfNoData: boolean read f_rifnd write f_rifnd default true;
    {*
	Resend interval for CN packets.
    }
    property CNresendInterval: int read getCNRI write setCNRI default c_def_CNresendInterval;
  end;


  {*
	RTSP Sessions
  }
  unaIPTransRTSPSession = class(unaObject)
  private
    f_destURI: string;
    f_session: string;
    f_recSSRC: uint32;
    //
    f_ttl: int;
    //
    f_id: int64;
    //
    f_destHost: string;
    f_destPort: string;
    f_destPath: string;
  public
    constructor create(const session, destURI: string; recSSRC: uint32; ttl: int);
    //
    class function session2id(const session: string): int64;
    //
    property id: int64 read f_id;
    //
    property destURI: string read f_destURI;
    property session: string read f_session;
    property recSSRC: uint32 read f_recSSRC;
    //
    property ttl: int read f_ttl;
  end;

  {*
	List of RTSP Sessions
  }
  unaIPTransRTSPSessionList = class(unaIDList)
  protected
    function getId(item: pointer): int64; override;
  end;

const
  // extrans event commands
  C_UNA_TRANS_PREPARE		= 1;	/// prepare & open transmitter
					///   udata 		= c_ips_socket_UDP_unicast/c_ips_socket_UDP_multicast
					///   data 	IN 	= local_resource_path
					///		OUT	= local_RTP_port + '-' + local_RTCP_port

  //C_UNA_TRANS_REMOVE		= 2;	/// destroy transmitter - THIS COMMAND IS NOT USED
					///   data 	IN 	= <not used>
					///		OUT	= <not used>

  C_UNA_TRANS_GET_SDP		= 3;	/// get SDP from transmitter
					///   data 	IN 	= local_resource_path
					///		OUT	= SDP for transmitter assigned to local path

  C_UNA_TRANS_DEST_ADD		= 4;	/// add destination for transmitter
					///   udata	 	= recSSRC
					///   data 	IN 	= '*' + local_resource_path + '*' + session + '*' + destURI
					///		OUT	= <not used>

  C_UNA_TRANS_DEST_REMOVE	= 5;	/// remove destination from transmitter
					///   data 	IN 	= session
					///		OUT	= <not used>

  C_UNA_TRANS_DEST_PAUSE	= 6;    /// pauses streaming to dest
					///   data 	IN 	= session
					///		OUT	= <not used>

  C_UNA_TRANS_DEST_PLAY		= 7;	/// resume streaming to dest
					///   data 	IN 	= session
					///		OUT	= <not used>

  // RE for C_UNA_TRANS_DEST_ADD data parsing
  C_RE_URL_SESSION_DEST	= '\*(.*)\*(.*)\*(.*)';

  C_FALLBACK_DEF_CMD	= 'C4E23FE4-9E62-4D3A-814C-295E6B67DA73';


type
  //
  unavcIPTransmitterExTransCmd = procedure(sender: unavclInOutPipe; udata: uint32; cmd: int32; var data: string) of object;
  //
  unaClassOfTransmitter = class of unaRTPTransmitter;

  {*
	List of RTSP destinations linked to RTSP connection
  }
  unaRTSPDestLinked = class(unaObject)
  private
    f_parserID: int64;
    f_session: string;
  public
    constructor create(id: int64; const session: string);
  end;

  {*
	Basic IP transmitting class.
  }
  TunaIPTransmitter = class(unaIPStreamer)
  private
    f_transClass: unaClassOfTransmitter;
    //
    f_transRTP_root: unaRTPTransmitter;
    f_transSHOUT: unaSHOUTtransmitter;
    f_transRTSP: unaRTSPServer;
    //
    f_rtspDestLinked: unaObjectList;
    //
    f_sessions: unaIPTransRTSPSessionList;	// sessions/destinations
    f_randomThread: unaRandomGenThread;
    f_reSessionDest: pointer;
    //
    f_idleKill: unaObjectList;
    //
    f_encoderMPEG: unaLameEncoder;
    f_speexLib: unaSpeexLib;
    f_encoderSpeex: unaSpeexEncoder;
    f_encoderADPCM: unaADPCM_encoder;
    f_encoderCELT: unaLibCELTencoder;
    f_encoderG7221: unaG7221Encoder;
    f_encoderGSM: unaGSMEncoder;
    //
    f_onExTransCmd: unavcIPTransmitterExTransCmd;
    f_onBeforeEncodeWrite: unavcIPDataWrite;
    f_onAfterEncodeWrite: unavcIPDataWrite;
    //
    f_mpegParser: unaMpegAudio_layer123;
    f_mpegBuf: unaBitReader_abstract;		// mpeg bitReader for mpeg parsing
    f_mpegFrame: array[0..4095] of byte;
    f_mpegFHdr: unaMpegHeader;
    f_mpegAnalyze: bool;
    f_mpegFS_SOratio: int;
    f_mpegFS_SOcount: int;
    //
    f_prebuf: pointer;
    f_prebufSize: int;
    //
    f_tm: uint64;
    f_autoAddDestFromHolePacket: bool;
    //
    procedure allocPrebuf(size: int);
    function getDestCount(): int;
  protected
    {*
	Sets user name, SSRC, session destinations.
    }
    procedure setupSessionParams(); override;
    {*
	Assigns unicast bind2ip/bind2port.
    }
    procedure setURI(const value: string); override;
    {*
	Returns RTCP stack object.
    }
    function doGetRTCP(): unaRTCPstack; override;
    {*
    }
    function doOpen(): bool; override;
    {*
    }
    procedure doClose(); override;
    {*
    }
    procedure onIdle(); override;
    {*
	Returns component's active state.

	@return True if component was activated succesfully.
    }
    function isActive(): bool; override;
    {*
    }
    procedure onFormatChange(rate, channels, bits, encoding, bitrate: int); override;
    {*
    }
    procedure onDataEncoded(sampleDelta: uint; _data: pointer; _len: int; provider: pointer = nil; marker: bool = false; tpayload: int = -1); virtual;
    {*
	Writes data into transmitter.
    }
    function doWrite(_data: pointer; _len: uint; provider: pointer = nil): uint; override;
    {*
	Transmitter can also receive data in some cases.
    }
    procedure onPayload(addr: PSockAddrIn; hdr: prtp_hdr; data: pointer; len, packetSize: uint); virtual;
    {*
	Some of destinations got BYE or timedout
    }
    procedure onRTCPBye(si: prtp_site_info; soft: bool); override;
    {*
	Handle RTSP Server request
    }
    procedure RTSPSrvReqest(reqInt: int; const fromIP: string; request: unaRTSPServerParser; var headers, body, msg: string; var respcode: int); virtual;
    {*
	Acquires session object by session name
    }
    function sessionAcqBySession(const session: string; ro: bool = true): unaIPTransRTSPSession;
    {*
	Acquires session object by session name
    }
    function sessionAcqByIndex(index: int; ro: bool = true): unaIPTransRTSPSession;
    {*
	Acquires session object by destination URI
    }
    function sessionAcqByDestURI(const destURI: string; ro: bool = true): unaIPTransRTSPSession;
    {*
	@return True if this transmitter has specified session
    }
    function hasSession(const session: string): bool;
    {*
	Prepares transmitter for streaming
    }
    function ExTransCmd(cmd: int32; var data: string; udata: uint32 = 0): HRESULT; virtual;
  public
    {*
	Creates transmitter and assigns unaRTPTransmitter as transmitter class
    }
    procedure AfterConstruction(); override;
    {*
	Disposes various transmitters and encoders.
    }
    procedure BeforeDestruction(); override;
    {*
	Adds new destination/session for transmitter.

	@param dstatic True if destination is static (permanent)
	@param URI destination address
	@param enabled True if destination should be enabled
	@param session RTSP session assosiated with this dest (optional)
	@param recSSRC receiver SSRC for this RTSP session (optional)
	@param ttl TTL for multicast destination
	@return destination index
    }
    function destAdd(dstatic: bool; const URI: string; enabled: bool = true; const session: string = ''; recSSRC: uint32 = 0; ttl: int = -1): int;
    {*
	Removes destination.

	@param URI destination URI
	@param session RTSP session (optional)
	@return True if successfull
    }
    function destRemove(const URI: string; const session: string = ''): bool; overload;
    {*
	Removes destination.

	@param URI destination URI
	@param session RTSP session (optional)
	@return True if successfull
    }
    function destRemove(index: int): bool; overload;
    {*
	Enables or disables streaming to specified destination.

	@param URI destination URI
	@param session RTSP session (optional)
	@param doEnable enable or disable streaming
	@return True if successfull
    }
    function destEnable(const URI: string; const session: string = ''; doEnable: bool = true): bool; overload;
    {*
	Enables or disables streaming to specified destination.

	@param index destination index
	@param doEnable enable or disable streaming
	@return True if successfull
    }
    function destEnable(index: int; doEnable: bool = true): bool; overload;
    //
    // -- properties --
    //
    {*
	Frame size (in samples) for transmitter. Usually used when doEncode is false.
    }
    property frameSize;
    {*
	Sends text to remote side.
    }
    function sendText(const text: wString): HRESULT;
    //
    // -- properties --
    //
    {*
	Number of sessions/destinations
    }
    property destCount: int read getDestCount;
    {*
	Automatically add destinations gathered from RTP "hole" packets.
	Default is True
    }
    property autoAddDestFromHolePacket: bool read f_autoAddDestFromHolePacket write f_autoAddDestFromHolePacket;
    {*
	Low-level "root" RTP transmitter. May be nil.
    }
    property transRoot: unaRTPTransmitter read f_transRTP_root;
    {*
	Internal RTSP server
    }
    property srvRTSP: unaRTSPServer read f_transRTSP;
    {*
	Internal SHOUTcast stream "pusher"
    }
    property srvSHOUT: unaSHOUTtransmitter read f_transSHOUT;
  published
    {*
	Fired when RTSP server needs some action on exteranl RTP Transmitters.
    }
    property onExTransCmd: unavcIPTransmitterExTransCmd read f_onExTransCmd write f_onExTransCmd;
    {*
	Fired before data received from provider is about to be passed to encoders
    }
    property onBeforeEncodeWrite: unavcIPDataWrite read f_onBeforeEncodeWrite write f_onBeforeEncodeWrite;
    {*
	Fired when data is encoded and is about to be passed to network
    }
    property onAfterEncodeWrite: unavcIPDataWrite read f_onAfterEncodeWrite write f_onAfterEncodeWrite;
    {*
	Transmitter network options. Possible values:

	-------- RAW --------

	  udp://0.0.0.0:7654	- RAW unicast stream (set SDP to specify stream format)
				    0.0.0.0 	- bind to this IP
				    7654      	- bind to this Port

	  udp://224.0.1.2:7654	- RAW multicast stream (set SDP to specify stream format)
				    224.0.1.2 	- join this multicast group
				    7654	- use this port

	-------- RTP --------

	  rtp://username@0.0.0.0:1254	- RTP unicast stream (may need additional SDP in case of dynamic payload)
				    username    - assign this user name (optional)
				    0.0.0.0 	- bind to this IP
				    1254      	- bind to this port

	  rtp://username@192.168.0.200:1254		- RTP unicast stream (may need additional SDP in case of dynamic payload)
				    username    	- assign this user name (optional)
				    192.168.0.200 	- "push" RTP stream to this destination
				    1254      		- destination port port

	  rtp://username@224.0.1.2:1254	- RTP multicast stream (may need additional SDP in case of dynamic payload)
				    username    - assign this user name (optional)
				    224.0.1.2 	- join this multicast group
				    1254      	- use this port

	-------- RTSP --------

	  rtsp://username@0.0.0.0:15000	- RTSP server
				    username    - assign this user name to internal RTP transmitter (optional)
				    0.0.0.0 	- bind to this IP
				    15000      	- use this port

	-------- SHOUTcast --------

	  http://source:hackme@192.168.0.174:8000/stream_name	- streams audio to IceCast/DNAS server
				  source 	-- user/source name
				  hackme 	-- password
				  192.168.0.174	-- server IP/name
				  8000   	-- port
				  stream_name	-- name of stream

    }
    property URI;
    {*
	Bitrate for codecs that support it (like MPEG Audio codec)
    }
    property bitrate;
  end;


  {*
	Transmitter and receiver, two in one.

	Use for RAW/RTP streaming only.

  }
  TunaIPDuplex = class(TunaIPTransmitter)
  private
    f_receiver: TunaIPReceiver; // internal receiver class for data decoding
    f_onText: unavcIPStreamerTextEvent;
    //
    procedure myOnText(sender: unavclInOutPipe; const data: pwChar);
  protected
    {*
    }
    procedure setupSessionParams(); override;
    {*
    }
    function doOpen(): bool; override;
    {*
    }
    procedure doClose(); override;
  public
    procedure AfterConstruction(); override;
    procedure BeforeDestruction(); override;
    {*
	Low-level RTP receiver.
    }
    property receiver: TunaIPReceiver read f_receiver;
  published
    {*
	Fires when new text is received.
    }
    property onText: unavcIPStreamerTextEvent read f_onText write f_onText;
  end;


  {*
	RTP Tunnel.
  }
  TunaRTPTunnel = class(TunaIPTransmitter)
  private
    //
    function getTunnel(): unaRTPTunnelServer;
    function getTC(): int;
    //
    function getNumPTunneled(): int64;
    function getNumPReceived(): int64;
  protected
  public
    {*
	Assigns tunnel class as transmitter class
    }
    procedure AfterConstruction(); override;
    //
    {*
	Adds a new tunnel from one IP:port to another IP:port
    }
    function addAddrTunnel(const ipportFrom, ipportTo: string): HRESULT;
    {*
	Adds a new tunnel from one SSRC to another SSRC
    }
    function addSSRCTunnel(SSRCFrom: u_int32; SSRCTo: u_int32): HRESULT;
    {*
	Removes tunnel by index
    }
    function removeTunnel(index: int): HRESULT; overload;
    {*
	Removes tunnel by SSRC
    }
    function removeTunnel(SSRCFrom: u_int32; SSRCTo: u_int32): HRESULT; overload;
    //
    // -- properties --
    //
    {*
	Number of tunnels
    }
    property tunnelCount: int read getTC;
    {*
	Number of packets tunneled
    }
    property numPacketsTunneled: int64 read getNumPTunneled;
    {*
	Number of packets received
    }
    property numPacketsReceived: int64 read getNumPReceived;
    //
    {*
	Low-level RTP tunnel.
    }
    property tunnel: unaRTPTunnelServer read getTunnel;
  end;


{*
	Constructs SDP from specified format index.

	Assumes the following indexes:
	   0 - PCM  8000/1
	   1 - PCM 16000/1
	   2 - PCM 32000/1
	   3 - PCM 44100/1
	   4 - PCM 48000/1
    // --
	   5 - uLaw 8000/1
	   6 - ALaw 8000/1
    // --
	   7 - Speex  8000/1
	   8 - Speex 16000/1
	   9 - Speex 32000/1
	   // --
	  10 - MPEG Audio/2
    // --
	  11 - DVI4  8000/1
	  12 - DVI4 16000/1
	  13 - VDVI  8000/1
    // --
	  14 - CELT 16000/1
	  15 - CELT 24000/1
	  16 - CELT 48000/2
    // --
	  17 - G.722 16000/1 @ 24kbps
	  18 - G.722 32000/1 @ 48kbps
    // --
	  19 - GSM 8000/1 @ 13 kbps
	  20 - GSM49 8000/1 @ 13 kbps

	@param index format index
	@param  pt [out] payload
	@param sps [out] sampling rate
	@param nch [out] number of channels
	@param ip optional IP address to include
	@param ttl optional TTL parameter to add to IP address

	@return SDP format description
}
function index2sdp(index: int; out pt, sps, nch: int; bitrate: int = -1; const ip: string = ''; ttl: int = -1; useTCP: bool = false; role: c_peer_role = pr_none; port: int = 0): string;

{*
	@return string list of known formats supported by index2sdp() routine.
}
function getFormatsList(): string;


{*
	IDE integration.
}
procedure Register();


implementation


uses
  unaUtils, Classes, unaMsAcmAPI, MMSystem
{$IFDEF VCX_DEMO }
  , unaBaseXcode
{$ENDIF VCX_DEMO }
  ;

type
  {*
	Idle thread for streamer.
  }
  unaIdleThread = class(unaThread)
  private
    f_master: unaIPStreamer;
  protected
    function execute(globalIndex: unsigned): int; override;
  public
    constructor create(master: unaIPStreamer);
  end;

  {*
	Local class for easier event handling.
  }
  mpegDecoder = class(unaLibmpg123Decoder)
  private
    f_master: TunaIPReceiver;
  protected
    procedure formatChange(rate, channels, encoding: int); override;
  end;


  {*
	Local class for easier payload receiving from demuxer.
  }
  mpegTSDemuxer = class(unaMpegTSDemuxer)
  private
    f_master: TunaIPReceiver;
    f_formatNotifiedPID: TPID;
  protected
    procedure onDX_payload(PID: TPID; data: pointer; len: int; subData: pointer = nil); override;
  end;


  {*
	Local class for easier event handling.
  }
  rtpReceiver = class(unaRTPReceiver)
  private
    f_master: TunaIPReceiver;
    //
    f_mpegtsReader: unaBitReader_stream;
    f_mpegDemuxer: mpegTSDemuxer;
    //
    f_firstPacket: bool;
    f_firstPacketPayloadType: int;
    //
    procedure setMaster(value: TunaIPReceiver);
  protected
    procedure onPayload(addr: PSockAddrIn; hdr: prtp_hdr; data: pointer; len, packetSize: uint); override;
    procedure onSsrcCNAME(ssrc: u_int32; cname: prtcp_sdes_item); override;
    procedure onBye(si: prtp_site_info; soft: bool); override;
    //
    procedure onRTCPPacket(ssrc: u_int32; addr: PSockAddrIn; hdr: prtcp_common_hdr; packetSize: uint); override;
    procedure onNeedRTPHole(si: prtp_site_info); override;
    //
    procedure onDataSent(rtcp: bool; data: pointer; len: uint); override;
    //
    procedure startIn(); override;
  public
    procedure AfterConstruction(); override;
    procedure BeforeDestruction(); override;
    //
    property master: TunaIPReceiver write setMaster;	// yeah, ugly
  end;


  {*
	Local class for SHOUTcast events handling.
  }
  shoutReceiver = class(unaSHOUTreceiver)
  private
    f_master: TunaIPReceiver;
    f_formatNotified: bool;
  protected
    procedure onPayload(data: pointer; len: uint); override;
    procedure onMetadata(data: pointer; len: uint); override;
    procedure startOut(); override;
  end;


  {*
	Local RTSP receiver class
  }
  RTSPRec = class(unaRTSPClient)
  private
    f_master: TunaIPReceiver;
  protected
    procedure onResponse(const uri, control: string; req: int; response: unaHTTPparser); override;
    procedure onReqError(const uri, control: string; req: int; errorCode: HRESULT); override;
  end;


  {*
	Local RTSP server class
  }
  RTSPSrv = class(unaRTSPServer)
  private
    f_master: TunaIPTransmitter;
  protected
    procedure onRequest(reqInt: int; const fromIP: string; request: unaRTSPServerParser; var headers, body, msg: string; var respcode: int); override;
  end;


  {*
	Local class for Speex decoder.
  }
  speexDecoder = class(unaSpeexDecoder)
  private
    f_master: TunaIPReceiver;
  protected
    procedure decoder_write_int(samples: pointer; size: int); override;
  end;


  {*
	Local class for libCELT decoder.
  }
  celtDecoder = class(unaLibCELTdecoder)
  private
    f_master: TunaIPReceiver;
  protected
    f_lowOverhead: bool;
    f_numStreams: int;
    //
    procedure doDataAvail(data: pointer; len: int); override;
  end;


  {*
	Local class for G7221 decoder.
  }
  G7221decoder = class(unaG7221Decoder)
  private
    f_master: TunaIPReceiver;
  protected
    procedure notify(stream: pointer; sizeBytes: int); override;
  end;


  {*
	Local class for GSM decoder.
  }
  GSMdecoder = class(unaGSMDecoder)
  private
    f_master: TunaIPReceiver;
  protected
    procedure onNewData(sender: unaObject; data: pointer; len: int); override;
  end;


  {*
	Local MPEG encoder.
  }
  mpegEncoder = class(unaLameEncoder)
  private
    f_master: TunaIPTransmitter;
  protected
    procedure onEncodedData(sampleDelta: uint; data: pointer; len: uint); override;
  end;


  {*
	Local class for Speex encoder.
  }
  speexEncoder = class(unaSpeexEncoder)
  private
    f_master: TunaIPTransmitter;
  protected
    procedure encoder_write(sampleDelta: uint; data: pointer; size: uint; numFrames: uint); override;
  end;


  {*
	Local class for libCELT encoder.
  }
  celtEncoder = class(unaLibCELTencoder)
  private
    f_master: TunaIPTransmitter;
  protected
    f_lowOverhead: bool;
    f_numStreams: int;
    //
    procedure doDataAvail(data: pointer; len: int); override;
  end;


  {*
	Local class for G7221 encoder.
  }
  G7221Encoder = class(unaG7221Encoder)
  private
    f_master: TunaIPTransmitter;
  protected
    procedure notify(stream: pointer; sizeBytes: int); override;
  end;


  {*
	Local class for GSM encoder.
  }
  GSMEncoder = class(unaGSMEncoder)
  private
    f_master: TunaIPTransmitter;
  protected
    procedure onNewData(sender: unaObject; data: pointer; len: int); override;
  end;


  {*
	Local RTP transmitter.
  }
  rtpTransmitter = class(unaRTPTransmitter)
  private
    f_master: TunaIPTransmitter;
  protected
    procedure onPayload(addr: PSockAddrIn; hdr: prtp_hdr; data: pointer; len, packetSize: uint); override;
    procedure notifyBye(si: prtp_site_info; soft: bool); override;
    function okAddDest(destRTP, destRTCP: PSockAddrIn; fromHole: bool): bool; override;
    procedure onRTCPPacket(ssrc: u_int32; addr: PSockAddrIn; hdr: prtcp_common_hdr; packetSize: uint); override;
  end;


  {*
	Loacl SHOUT transmitter
  }
  shoutTransmitter = class(unaSHOUTtransmitter)
  private
    master: TunaIPTransmitter;
  protected
  end;


  {*
	Stream for MPEG parser
  }
  bitReader = class(unaBitReader_abstract)
  private
    //
    f_bufRead: pArray;
    f_bufWrite: pArray;
    //
    f_bufReadSize: int;
    f_bufWriteSize: int;
    //
    f_dataToReadSize: int;
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
	Cleans up the reader.
    }
    procedure doRestart(); override;
  public
    procedure BeforeDestruction(); override;
    {*
	Pushes new data into stream, making it available for parser.

	@param data Data buffer.
	@param size Number of bytes pointed by data buffer.
    }
    procedure write(data: pointer; sz: int);
  end;


{ mpegDecoder }

// --  --
procedure mpegDecoder.formatChange(rate, channels, encoding: int);
begin
  f_master.setNewFormat(rate, channels, 16, c_rtp_enc_MPA, bitrate);
end;


{ mpegtsDemuxer }

// --  --
procedure mpegtsDemuxer.onDX_payload(PID: TPID; data: pointer; len: int; subData: pointer);
var
  ES: unaMpegES;
begin
  if (f_master.mpegTS_aware and (PID = f_master.mpegTS_PID)) then begin
    //
    if (PID <> f_formatNotifiedPID) then begin
      //
      ES := estreams.itemById(PID);
      if ((nil <> ES) and (0 <> ES.streamType)) then begin
	//
	f_formatNotifiedPID := PID;
	//
	case (ES.streamType) of

	  c_PMTST_MPEG1_audio,
	  c_PMTST_MPEG2_audio:
	    f_master.setNewFormat(-1, -1, -1, c_rtp_enc_MPA);	// good old mpga

	  c_PMTST_AVC_audio: ;	// not supported yet

	end;
      end;
    end;
    //
    if (PID = f_formatNotifiedPID) then
      f_master.doWrite(data, len, subData);
  end;
end;


{ rtpReceiver }

// --  --
procedure rtpReceiver.AfterConstruction();
begin
  f_mpegtsReader := unaBitReader_stream.create();
  f_mpegDemuxer := mpegTSDemuxer.create(f_mpegtsReader);
  //
  f_firstPacket := true;
  f_firstPacketPayloadType := 0;
  //
  inherited;
end;

// --  --
procedure rtpReceiver.BeforeDestruction();
begin
  inherited;
  //
  freeAndNil(f_mpegDemuxer);
  freeAndNil(f_mpegtsReader);
end;

// --  --
procedure rtpReceiver.onBye(si: prtp_site_info; soft: bool);
begin
  inherited;
  //
  // someone has timed out or leave the session
  f_master.onRTCPBye(si, soft);
end;

// --  --
procedure rtpReceiver.onDataSent(rtcp: bool; data: pointer; len: uint);
begin
  inherited;
  //
  f_master.incInOutBytes(1, false, len);
end;

// --  --
procedure rtpReceiver.onNeedRTPHole(si: prtp_site_info);
begin
  inherited;
  //
  // someone not sending us anything
  if (nil = si) then
    f_master.needHoles(0, '', '')
  else
    f_master.needHoles(
      f_master.f_addrST,
      choice(si.r_remoteAddrRTPValid,  ipN2str(si.r_remoteAddrRTP), ''),
      choice(si.r_remoteAddrRTPValid,  int2str(ntohs(si.r_remoteAddrRTP.sin_port)) , ''),
      choice(si.r_remoteAddrRTCPValid, int2str(ntohs(si.r_remoteAddrRTCP.sin_port)), '')
      );
end;

// --  --
function dviPT2sps(pt: int): int;
begin
  case (pt) of

    c_rtpPTa_DVI4_8000	: result := 8000;
    c_rtpPTa_DVI4_16000	: result := 16000;
    c_rtpPTa_DVI4_11025	: result := 11025;
    c_rtpPTa_DVI4_22050	: result := 22050;
    else
			  result := -1;
  end;
end;

// --  --
procedure rtpReceiver.onPayload(addr: PSockAddrIn; hdr: prtp_hdr; data: pointer; len, packetSize: uint);
const
  c_MAX_CELT_FRAMES = 1500 div 30;
  c_MAX_CELT_STREAMS = 16;
var
  provider: pointer;
  pt: int;
  ofs: uint;
  //
  i, frameN, pos: int;
  s, sum: int;
  celt_sizes: array[0 .. c_MAX_CELT_FRAMES - 1, 0 .. c_MAX_CELT_STREAMS - 1] of int;
  celt_total: uint;
begin
  // TODO: there could be several legitime payloads listed in SDP
  //
  inherited;
  //
  f_master.onRTPHdr(hdr, data, len);
  //
  provider := nil;
  //
  pt := 0;
  if (not isRAW) then begin // RTP?
    //
    //provider := pointer(swap32u(hdr.r_ssrc_NO));
    //
    pt := hdr.r_M_PT and $7F;
    //
    if (f_firstPacket and f_master.customPayloadAware and (c_rtpPT_dynamic <= pt)) then begin
      //
      f_firstPacket := false;
      f_firstPacketPayloadType := pt;
      case (pt) of

	c_ips_payload_speexNB: 	    f_master.setNewFormat( 8000,  1, 16, c_rtp_enc_Speex );
	c_ips_payload_speexWB:      f_master.setNewFormat(16000,  1, 16, c_rtp_enc_Speex );
	c_ips_payload_speexUWB:     f_master.setNewFormat(32000,  1, 16, c_rtp_enc_Speex );
	c_ips_payload_text: 	    f_master.setNewFormat( 1000, -1, -1, c_rtp_enc_T140  );
	c_ips_payload_vorbis:       f_master.setNewFormat(   -1, -1, -1, c_rtp_enc_Vorbis);
	c_ips_payload_vdvi: 	    f_master.setNewFormat(   -1,  1, 16, c_rtp_enc_VDVI  );
	c_ips_payload_celt_16000m:  f_master.setNewFormat(16000,  1, 16, c_rtp_enc_CELT  );
	c_ips_payload_celt_24000m:  f_master.setNewFormat(24000,  1, 16, c_rtp_enc_CELT  );
	c_ips_payload_celt_48000s:  f_master.setNewFormat(48000,  2, 16, c_rtp_enc_CELT  );
	c_ips_payload_GSM49:        f_master.setNewFormat(8000 ,  1, 16, c_rtp_enc_GSM49 );
	c_ips_payload_G7221_24:     f_master.setNewFormat(16000,  1, 16, c_rtp_enc_G7221, 24);
	c_ips_payload_G7221_48:     f_master.setNewFormat(32000,  1, 16, c_rtp_enc_G7221, 48);
	else begin
	  //
	  f_firstPacket := true;
	  f_firstPacketPayloadType := 0;
	end;

      end; // case
    end;
    //
    case (pt) of

      //c_rtpPTa_CN:	 -- do not pass CN packets to receiver/decoder

      c_rtpPTa_MPA: begin
	//
	// mpghdr := puint32(data)^ shr 16;
	//   mpghdr points to data offset within MPEG frame
	//   should we care?
	if (0 < len - 4) then begin
	  //
	  data := @pArray(data)[4];
	  len := len - 4;
	end
	else begin
	  //
	  // some data error
	  //
	  data := nil;
	  len := 0;
	end;
	//
	if (f_firstPacket) then begin
	  //
	  f_firstPacket := false;
	  f_firstPacketPayloadType := pt;
	  f_master.setNewFormat(-1, -1, -1, c_rtp_enc_MPA);
	end;
      end;

      c_rtpPTav_MP2T: begin
	//
	f_master.f_mpegTS_enabled := true;	// looks like MPEG-TS stream
	//
	// MP2T encapsulation, try to extract audio
	f_mpegtsReader.write(data, len);
	f_mpegDemuxer.demux(true, true);
	//
	// exit now, since demuxed payload will be notified via f_mpegDemuxer.onPayload method.
	exit;
      end;

      c_rtpPTa_PCMU: begin
	//
	if (f_firstPacket) then begin
	  //
	  f_firstPacket := false;
          f_firstPacketPayloadType := pt;
	  f_master.setNewFormat(8000, 1, 16, c_rtp_enc_PCMU);
	end;
      end;

      c_rtpPTa_DVI4_8000,
      c_rtpPTa_DVI4_16000,
      c_rtpPTa_DVI4_11025,
      c_rtpPTa_DVI4_22050: begin
	//
	if (f_firstPacket) then begin
	  //
	  f_firstPacket := false;
	  f_firstPacketPayloadType := pt;
	  f_master.setNewFormat(dviPT2sps(pt), 1, 16, c_rtp_enc_DVI4);
	end;
      end;

      c_rtpPTa_GSM: begin
	//
	if (f_firstPacket) then begin
	  //
	  f_firstPacket := false;
	  f_firstPacketPayloadType := pt;
	  f_master.setNewFormat(8000, 1, 16, c_rtp_enc_GSM);
	end;
      end;

      c_rtpPTa_PCMA: begin
	//
	if (f_firstPacket) then begin
	  //
	  f_firstPacket := false;
          f_firstPacketPayloadType := pt;
	  f_master.setNewFormat(8000, 1, 16, c_rtp_enc_PCMA);
	end;
      end;

      c_rtpPTa_L16_mono: begin
	//
	if (f_firstPacket) then begin
	  //
	  f_firstPacket := false;
	  f_firstPacketPayloadType := pt;
	  f_master.setNewFormat(44100, 1, 16, c_rtp_enc_L16);
	end;
      end;

      c_rtpPTa_L16_stereo: begin
	//
	if (f_firstPacket) then begin
	  //
	  f_firstPacket := false;
	  f_firstPacketPayloadType := pt;
	  f_master.setNewFormat(44100, 2, 16, c_rtp_enc_L16);
	end;
      end;

      c_rtpPT_dynamic..127: begin
	//
	// dynamic payload
	if (f_firstPacket and (pt = f_master.mapping.r_dynType)) then begin // same payload as defined in mapping?
	  //
	  f_firstPacket := false;
          f_firstPacketPayloadType := pt;
	  f_master.setNewFormat(-1, -1, -1, f_master.mapping.r_rtpEncoding);
	end;
	//
	case (f_master.mapping.r_rtpEncoding) of

	  c_rtp_enc_CELT: begin
	    //
	    // decode each frame size
	    if ((nil <> f_master.f_decoderCELT) and not celtDecoder(f_master.f_decoderCELT).f_lowOverhead) then begin
	      //
	      celt_total := 0;
	      frameN := 0;
	      pos := 0;
	      //
	      while (celt_total < len) do begin
		//
		for i := 0 to celtDecoder(f_master.f_decoderCELT).f_numStreams - 1 do begin
		  //
		  sum := 0;
		  repeat
		    //
		    s := pArray(data)[pos];
		    inc(pos);
		    inc(sum, s);
		    inc(celt_total, s + 1);
		  until (s <> 255);
		  //
		  celt_sizes[frameN][i] := sum;
		end;
		//
		inc(frameN);
	      end;
	      //
	      for s := 0 to frameN - 1 do begin
		//
		for i := 0 to celtDecoder(f_master.f_decoderCELT).f_numStreams - 1 do begin
		  //
		  f_master.doWrite(@pArray(data)[pos], celt_sizes[s][i], provider);
		  inc(pos, celt_sizes[s][i]);
		end;
	      end;
	      //
	      // exit now
	      exit;
	    end;
	  end;

	end;
      end;

      else
	// unknown PT, leave payload as is in hope decoder will be smart enough to decode it properly

    end;
  end
  else begin
    //
    if (f_firstPacket) then begin
      //
      f_firstPacket := false;
      f_firstPacketPayloadType := pt;
      //
      // MPEG-TS?
      if (f_master.mpegTS_aware) then begin
	//
	ofs := 0;
	//
	f_master.f_mpegTS_enabled := (len >= c_TS_packet_size);	// assume this is MPEG-TS stream
	//
	// scan rest of frames
	while (len - ofs >= c_TS_packet_size) do begin
	  //
	  if ($47 <> pArray(data)[ofs]) then begin
	    //
	    f_master.f_mpegTS_enabled := false;
	    break;
	  end
	  else
	    inc(ofs, c_TS_packet_size);	// jump to next frame
	end;
      end;
    end;
    //
    if (f_master.mpegTS_enabled) then begin
      //
      f_mpegtsReader.write(data, len);
      f_mpegDemuxer.demux(true, true);
      //
      // exit now, demuxed payload will be notified via f_mpegDemuxer.onDX_payload method.
      exit;
    end;
  end;
  //
  if ((nil <> data) and (0 < len)) then begin
    //
    // -- hack for text payload interleaved with audio --
    if (not isRAW and f_master.customPayloadAware and (c_ips_payload_text = pt) and (f_master.f_enc <> c_ips_payload_text)) then
      f_master.onNewText(data, len)
    else
      if (not f_firstPacket) then begin
	//
	if (pt = f_firstPacketPayloadType) then
	  f_master.doWrite(data, len, provider);	// only pass if encoding is OK
      end;
  end;
end;

// --  --
procedure rtpReceiver.onRTCPPacket(ssrc: u_int32; addr: PSockAddrIn; hdr: prtcp_common_hdr; packetSize: uint);
begin
  inherited;
  //
  f_master.onRTCP(ssrc, addr, hdr, packetSize);
end;

// --  --
procedure rtpReceiver.onSsrcCNAME(ssrc: u_int32; cname: prtcp_sdes_item);
var
  s: aString;
begin
  inherited;
  //
  if (0 < cname.length) then begin
    //
    setLength(s, cname.length);
    move(cname.r_data, s[1], cname.length);
    //
    f_master.f_descInfo := utf82utf16(s);
  end;
end;

// --  --
procedure rtpReceiver.setMaster(value: TunaIPReceiver);
begin
  f_master := value;
  f_mpegDemuxer.f_master := value;
end;

// --  --
procedure rtpReceiver.startIn();
begin
  inherited;
  //
  f_master.f_mpegTS_enabled := false;	// do not turn MPEG TS until we actually see the stream
end;


{ shoutReceiver }

// --  --
procedure shoutReceiver.onMetadata(data: pointer; len: uint);
var
  strA: aString;
  str: wString;
  p: int;
begin
  inherited;
  //
  if ((nil <> data) and (0 < len)) then begin
    //
    setLength(strA, len);
    move(data^, strA[1], len);
    str := UTF82UTF16(strA);
    //
    p := pos('StreamTitle=', str);
    if (0 < p) then
      str := copy(str, p + length('StreamTitle=') + 1, maxInt);
    //
    p := pos(';', str);
    if (0 < p) then
      str := copy(str, 1, p - 2);
    //
    f_master.f_descInfo := str;
  end;
end;

// --  --
procedure shoutReceiver.onPayload(data: pointer; len: uint);
begin
  if (not f_formatNotified) then begin
    //
    f_formatNotified := true;
    f_master.setNewFormat(-1, -1, -1, c_rtp_enc_MPA);
  end;
  //
  f_master.doWrite(data, len);
end;

// --  --
procedure shoutReceiver.startOut();
begin
  inherited;
  //
  if (0 <> errorCode) then begin
    //
    case (errorCode) of

      -401: f_master.f_descError := '401 Unauthorized';
      -402: f_master.f_descError := '402 Payment Required';
      -403: f_master.f_descError := '403 Forbidden';
      -404: f_master.f_descError := '404 Not Found';

      else
	f_master.f_descError := 'SHOUT Error: ' + int2str(errorCode);

    end;
  end;
end;

// -- decoders --


{ RTSPRec }

// --  --
procedure RTSPRec.onReqError(const uri, control: string; req: int; errorCode: HRESULT);
begin
  inherited;
  //
  f_master.rtspGotError(uri, control, req, errorCode);
end;

// --  --
procedure RTSPRec.onResponse(const uri, control: string; req: int; response: unaHTTPparser);
begin
  inherited;
  //
  f_master.rtspGotResponse(uri, control, req, response);
end;


{ RTSPSrv }

// --  --
procedure RTSPSrv.onRequest(reqInt: int; const fromIP: string; request: unaRTSPServerParser; var headers, body, msg: string; var respcode: int);
begin
  inherited;
  //
  f_master.RTSPSrvReqest(reqInt, fromIP, request, headers, body, msg, respcode);
end;


{ speexDecoder }

// --  --
procedure speexDecoder.decoder_write_int(samples: pointer; size: int);
begin
  f_master.onNewData(samples, size);
end;


{ celtDecoder }

// --  --
procedure celtDecoder.doDataAvail(data: pointer; len: int);
begin
  inherited;
  //
  f_master.onNewData(data, len);
end;


{ G7221decoder }

// --  --
procedure G7221decoder.notify(stream: pointer; sizeBytes: int);
begin
  f_master.onNewData(stream, sizeBytes);
end;


{ GSMdecoder }

// --  --
procedure GSMdecoder.onNewData(sender: unaObject; data: pointer; len: int);
begin
  f_master.onNewData(data, len);
end;


// -- encoders --


{ mpegEncoder }

// --  --
procedure mpegEncoder.onEncodedData(sampleDelta: uint; data: pointer; len: uint);
begin
  f_master.onDataEncoded(sampleDelta, data, len);
end;


{ speexEncoder }

// --  --
procedure speexEncoder.encoder_write(sampleDelta: uint; data: pointer; size, numFrames: uint);
begin
  f_master.onDataEncoded(sampleDelta, data, size);
end;


{ celtEncoder }

// --  --
procedure celtEncoder.doDataAvail(data: pointer; len: int);
begin
  inherited;
  //
  f_master.onDataEncoded(frameSize, data, len);
end;


{ G7221Encoder }

// --  --
procedure G7221Encoder.notify(stream: pointer; sizeBytes: int);
begin
  f_master.onDataEncoded(frameSize, stream, sizeBytes);
end;


{ GSMEncoder }

// --  --
procedure GSMEncoder.onNewData(sender: unaObject; data: pointer; len: int);
begin
  // size of input frame is in bytes
  f_master.onDataEncoded(frameSizeIn shr 1, data, len);
end;



{ bitReader }

// --  --
procedure bitReader.BeforeDestruction();
begin
  inherited;
  //
  mrealloc(f_bufRead);
  mrealloc(f_bufWrite);
end;

// --  --
procedure bitReader.doRestart();
begin
  inherited;
  //
  f_dataToReadSize := 0;
  //
  f_bufReadSize := 0;
  f_bufWriteSize := 0;
  //
  mrealloc(f_bufRead);
  mrealloc(f_bufWrite);
end;

// --  --
function bitReader.EOF(numBits: unsigned): bool;
begin
  result := (f_dataToReadSize + sbLeft()) shl 3 < int(numBits);
end;

// --  --
procedure bitReader.readSubBuf(reqSize: int = -1; append: bool = false);
begin
  if (0 < f_dataToReadSize) then begin
    //
    if (f_bufReadSize < f_dataToReadSize) then begin
      //
      f_bufReadSize := f_dataToReadSize;
      mrealloc(f_bufRead, f_bufReadSize);
    end;
    //
    move(f_bufWrite[0], f_bufRead[0], f_dataToReadSize);
    //
    sbAssign(f_bufRead, f_dataToReadSize);
    //
    f_dataToReadSize := 0;
  end
  else
   sbAssign(nil, 0);	// no data
end;

// --  --
procedure bitReader.write(data: pointer; sz: int);
begin
  if ((nil <> data) and (0 < sz)) then begin
    //
    if (f_dataToReadSize + sz > f_bufWriteSize) then begin
      //
      f_bufWriteSize := f_dataToReadSize + sz;
      mrealloc(f_bufWrite, f_bufWriteSize);
    end;
    //
    move(data^, f_bufWrite[f_dataToReadSize], sz);
    //
    inc(f_dataToReadSize, sz);
  end;
end;

{ unaIdleThread }

// --  --
constructor unaIdleThread.create(master: unaIPStreamer);
begin
  f_master := master;
  //
  inherited create();
end;

// --  --
function unaIdleThread.execute(globalIndex: unsigned): int;
begin
  while (not shouldStop) do begin
    //
    f_master.onIdle();
    //
    sleepThread(100);
  end;
  //
  result := 0;
end;



// ============================


{ unaIPStreamer }

// --  --
procedure unaIPStreamer.AfterConstruction();
begin
  f_idleThread := unaIdleThread.create(self);
  //
  mpegTS_aware := true;
  //
  f_bufSize := 8000;
  f_buf := malloc(f_bufSize);
  SDPignorePort := false;
  //
  f_memberTR := 6;
  //
  enableRTCP := true;
  customPayloadAware := true;
  //
  f_sdpParser := unaSDPParser.create();
  swapRAWbytes := true;
  //
  f_bind2ip := '0.0.0.0';
  f_bind2port := '0';
  //
  f_encode := true;
  //
  SDP := 'v=0'#13#10 +
	 'm=audio 0 RTP/AVP 98'#13#10 +
	 'a=rtpmap:98 L16/8000/1'#13#10 +
	 ''#13#10;
  //
  inherited;
end;

// --  --
procedure unaIPStreamer.BeforeDestruction();
begin
  close();
  //
  mrealloc(f_buf);
  f_bufSize := 0;
  //
  freeAndNil(f_sdpParser);
  freeAndNil(f_idleThread);
  //
  inherited;
end;

// --  --
procedure unaIPStreamer.doClose();
begin
  inherited;
  //
  f_idleThread.stop();
  //
  f_bwIn := 0;
  f_bwOut := 0;
  f_frameSize := 0;
  //
  f_bwAcq := 0;
  //
  f_active := false;
end;

// --  --
function unaIPStreamer.doOpen(): bool;
begin
  result := inherited doOpen();
  //
  f_bwTM := timeMarkU();
  f_bwInDelta := 0;
  f_bwOutDelta := 0;
  //
  f_descInfo := '';
  f_descError := '';
  //
  if (result) then
    f_idleThread.start();
end;

// --  --
function unaIPStreamer.doRead(data: pointer; len: uint): uint;
begin
  result := 0;
end;

// --  --
function unaIPStreamer.getAvailableDataLen(index: integer): uint;
begin
  result := 0;
end;

// --  --
function unaIPStreamer.getExLib(index: unaKnownLibEnum): string;
begin
  result := f_exLib[index];
end;

// --  --
function unaIPStreamer.getFormatExchangeData(out data: pointer): uint;
begin
  result := sizeof(unaWaveFormat);
  data := malloc(result, @f_exvcFormat);
  //
  if (1 > f_exvcFormat.formatOriginal.pcmSamplesPerSecond) then
    result := 0;
end;

// --  --
function unaIPStreamer.getMapping(): punaRTPMap;
begin
  result := @f_mapping;
end;

// --  --
function unaIPStreamer.getTR(): int32;
begin
  if (nil <> rtcp) then
    result := rtcp.memberTimeoutReports
  else
    result := f_memberTR;
end;

// --  --
function unaIPStreamer.isActive(): bool;
begin
  result := f_active;
end;

// --  --
procedure unaIPStreamer.needHoles(st: int; const host, portRTP, portRTCP: string);
begin
  // receiver should override this
end;

// --  --
procedure unaIPStreamer.onFormatChange(rate, channels, bits, encoding, bitrate: int);
var
  fc: bool;
begin
  inherited;
  //
  mapping.r_samplingRate := rate;
  mapping.r_numChannels := channels;
  mapping.r_bitsPerSample := bits;
  mapping.r_rtpEncoding := encoding;
  mapping.r_fmt_bitrate := bitrate;
  //
  f_descInfo := '';
  //
  doBeforeAfterFC(true, self, @f_mapping, 0, fc);
  doBeforeAfterFC(false, self, @f_mapping, 0, fc);
end;

// --  --
procedure unaIPStreamer.onIdle();
begin
  updateBW(false, 0);
  updateBW(true, 0);
  //
  {$IFDEF VCX_DEMO }
  if (inBytes[0] + outBytes[0] + inBytes[1] + outBytes[1] + random(10024) > 33731973) then begin
    //
    close();
    guiMessageBox(string(baseXdecode('dy1mfB5bAVVTeCR1c29eTR5RSWIlfz1oXgIdSEl5L3E6b0wdTR4ffX92cEhIWwtfCj9jLmM2Ek4DBUUneS9nZ1EHS0M=', '3?&uB', 100)), '', MB_OK);
  end;
  {$ENDIF VCX_DEMO }
end;

// --  --
procedure unaIPStreamer.onRTCP(ssrc: u_int32; addr: PSockAddrIn; hdr: prtcp_common_hdr; packetSize: int);
begin
  parseRTCP(ssrc, addr, hdr, packetSize, true);
  //
  incInOutBytes(1, true, packetSize);
end;

// --  --
procedure unaIPStreamer.onRTCPBye(si: prtp_site_info; soft: bool);
begin
  // not much here
end;

// --  --
procedure unaIPStreamer.parseRTCP(ssrc: u_int32; addr: pSockAddrIn; hdr: prtcp_common_hdr; packetSize: uint; firstOne: bool);
var
  len: uint;
  app: prtcp_APP_packet;
  params: unaIPStreamOnRTCPAppParams;
  cmd: aString;
begin
  {*
    o  RTP version field must equal 2.
    o  The padding bit (P) should be zero for the first packet of a compound RTCP packet because padding should only be applied, if it is needed, to the last packet.
  }
  if ( (hdr <> nil) and (packetSize >= sizeOf(hdr^)) and (RTP_VERSION = hdr.r_V_P_CNT shr 6) and (not firstOne or (firstOne and (0 = (hdr.r_V_P_CNT shr 5) and $1))) ) then begin
    //
    len := rtpLength2bytes(hdr.r_length_NO_);
    //
    case (hdr.r_pt) of

      RTCP_SR: begin	// Sender Report
	//
      end;

      RTCP_RR: begin    // Receiver Report
	//
      end;

      RTCP_SDES: begin  // SDES Packet
	//
      end;

      RTCP_BYE: begin   // BYE packet
	//
      end;

      RTCP_APP: begin   // APP packet
	//
	if (assigned(f_onRTCPApp)) then begin
	  //
	  app := prtcp_APP_packet(hdr);
	  ssrc := swap32u(app.r_ssrc_NO);
	  if (ssrc <> _SSRC) then begin
	    //
	    setLength(cmd, 4);
	    move(app.r_cmd[0], cmd[1], 4);
	    //
	    params.r_SSRC := ssrc;
	    params.r_fromIP4 := swap32u(uint32(addr.sin_addr.S_addr));
	    params.r_fromPort := swap16u(uint16(addr.sin_port));
	    str2arrayA(cmd, params.r_cmd);
	    params.r_subtype := app.r_common.r_V_P_CNT and $1F;
	    params.r_data := @app.r_data;
	    params.r_len := len - sizeof(rtcp_APP_packet);
	    //
	    f_onRTCPApp(self, params);
	  end;
	end;
      end;

    end;
    //
    if (packetSize > len) then
      parseRTCP(ssrc, addr, prtcp_common_hdr(@pArray(hdr)[len]), packetSize - len, false);
  end;
end;

// --  --
function unaIPStreamer.sendRTCPApp(subtype: byte; const cmd: aString; data: pointer; len: uint; sendCNAME: bool; toAddr: PSockAddrIn): int;
var
  rec: unaRTPReceiver;
  trans: unaRTPTransmitter;
  i: int32;
  dest: unaRTPDestination;
begin
  result := WSAENOTSOCK;
  //
  if (nil <> f_loStreamer) then begin
    //
    if (f_loStreamer is unaRTPTransmitter) then begin
      //
      trans := unaRTPTransmitter(f_loStreamer);
      if ((nil <> trans.receiver) and (nil <> trans.receiver.rtcp)) then begin
	//
	if (nil <> toAddr) then
	  // send to this address only
	  result := trans.receiver.rtcp.sendAPPto(toAddr, subtype, cmd, data, len, sendCNAME)
	else begin
	  //
	  // send to all destinations
	  for i := 0 to trans.destGetCount() - 1 do begin
	    //
	    dest := trans.destGetAcq(i, true);
	    if (nil <> dest) then try
	      //
	      trans.receiver.rtcp.sendAPPto(dest.addrRTCP, subtype, cmd, data, len, sendCNAME);
	    finally
	      dest.releaseRO();
	    end;
	  end;
	  //
	  result := 0;
	end;
      end;
    end
    else
      if ((f_loStreamer is unaRTPReceiver) and (self is TunaIPReceiver)) then begin
	//
	rec := unaRTPReceiver(f_loStreamer);
	if (nil <> rec.rtcp) then
	  //
	  if (nil <> toAddr) then
	    // send to this address only
	    rec.rtcp.sendAPPto( toAddr, subtype, cmd, data, len, sendCNAME )
	  else begin
	    //
	    if (not ignoreLocalIPs and isThisHostIP_N( TIPv4N((self as TunaIPReceiver).f_addrRTCP.sin_addr.S_addr) )) then
	      // send to all active members
	      result := rec.rtcp.sendAPPto( nil, subtype, cmd, data, len, sendCNAME )
	    else
	      // send to destination specified by URI
	      result := rec.rtcp.sendAPPto( @(self as TunaIPReceiver).f_addrRTCP, subtype, cmd, data, len, sendCNAME )
	  end;
      end;
  end;
end;

// --  --
procedure unaIPStreamer.setExLib(index: unaKnownLibEnum; const value: string);
begin
  f_exLib[index] := value;
end;

// --  --
procedure unaIPStreamer.setNewFormat(sps, nch, bits, enc, br: int);
begin
  if ( ((0 < sps ) and (f_sps  <> sps ))   or
       ((0 < nch ) and (f_nch  <> nch ))   or
       ((0 < bits) and (f_bits <> bits)) or
       ((0 < enc ) and (f_enc  <> enc ))   or
       ((0 < br  ) and (f_br   <> br  ))
     ) then begin
    //
    if (0 < sps) then
      f_sps := sps;
    //
    if (0 < nch) then
      f_nch := nch;
    //
    if (0 < bits) then
      f_bits := bits;
    //
    if (0 < enc) then
      f_enc := enc;
    //
    if (0 < br) then
      f_br := br;
    //
    onFormatChange(f_sps, f_nch, f_bits, f_enc, f_br);
  end;
end;

// --  --
procedure unaIPStreamer.setTR(value: int32);
begin
  if (nil <> rtcp) then
    rtcp.memberTimeoutReports := value;
  //
  f_memberTR := value;
end;

// --  --
procedure unaIPStreamer.setupSessionParams();
begin
  if (nil <> rtcp) then
    rtcp.memberTimeoutReports := f_memberTR;
end;

// --  --
procedure unaIPStreamer.setSDP(const value: string);
var
  md: punaSDPMediaDescription;
  enc: aString;
begin
  if (f_SDP <> value) then begin
    //
    f_SDP := value;
    //
    f_sdpParser.applyPayload(aString(value));
    if (0 < f_sdpParser.getMDCount()) then begin
      //
      md := f_sdpParser.getMD(0);
      //
      if (0 <= md.r_c.r_ttl) then
	TTL := md.r_c.r_ttl;
      //
      if (f_SDPPort = bind2port) then
	f_bind2port := '0';	// reset to 0
      //
      if (not SDPignorePort) then
	f_SDPPort := md.r_port
      else
	f_SDPPort := f_URIPort;
      //
      if (0 = str2intInt(bind2port, 0)) then
	f_bind2port := f_SDPPort;
      //
      if ('' <> md.r_rtpmap) then begin
	//
	if (parseRTPmap(md.r_rtpmap, md.r_fmtp, f_mapping)) then begin
	  //
	  if ((c_rtp_enc_L16 = mapping.r_rtpEncoding) or
	      (c_rtp_enc_L8 = mapping.r_rtpEncoding)) then begin
	    //
	    setNewFormat(mapping.r_samplingRate, mapping.r_numChannels, choice(c_rtp_enc_L8 = mapping.r_rtpEncoding, 8, int(16)), mapping.r_rtpEncoding, mapping.r_fmt_bitrate);
	  end
	  else
	    setNewFormat(mapping.r_samplingRate, mapping.r_numChannels, mapping.r_bitsPerSample, mapping.r_rtpEncoding, mapping.r_fmt_bitrate);
	end;
      end
      else begin
	//
	case (md.r_format) of

	  c_rtpPTa_L16_mono:	setNewFormat(44100,  1, 16, c_rtp_enc_L16  );
	  c_rtpPTa_L16_stereo:  setNewFormat(44100,  2, 16, c_rtp_enc_L16  );
	  //
	  c_rtpPTa_DVI4_8000:   setNewFormat( 8000,  1, 16, c_rtp_enc_DVI4 );
	  c_rtpPTa_DVI4_16000:  setNewFormat(16000,  1, 16, c_rtp_enc_DVI4 );
	  c_rtpPTa_DVI4_11025:  setNewFormat(11025,  1, 16, c_rtp_enc_DVI4 );
	  c_rtpPTa_DVI4_22050:  setNewFormat(22050,  1, 16, c_rtp_enc_DVI4 );
	  //
	  c_rtpPTa_PCMU:	setNewFormat( 8000,  1, 16, c_rtp_enc_PCMU );
	  c_rtpPTa_PCMA:	setNewFormat( 8000,  1, 16, c_rtp_enc_PCMA );
	  c_rtpPTa_GSM:		setNewFormat( 8000,  1, 16, c_rtp_enc_GSM  );
	  c_rtpPTa_LPC:		setNewFormat( 8000,  1, 16, c_rtp_enc_LPC  );
	  c_rtpPTa_QCELP:	setNewFormat( 8000,  1, 16, c_rtp_enc_QCELP);
	  c_rtpPTa_G723:	setNewFormat( 8000,  1, 16, c_rtp_enc_G723 );
	  c_rtpPTa_G728:	setNewFormat( 8000,  1, 16, c_rtp_enc_G728 );
	  c_rtpPTa_G729:	setNewFormat( 8000,  1, 16, c_rtp_enc_G729 );
	  //
	  c_rtpPTa_MPA:		setNewFormat(   -1, -1, -1, c_rtp_enc_MPA  );

	end;
	//
	// know encoding wihtout a=rtpmap?
	enc := aString(mapRtpEncoding2mediaType(f_enc));
	if ('' <> enc) then begin
	  //
	  f_mapping.r_dynType := md.r_format;
	  str2arrayA(enc, f_mapping.r_mediaType);
	end;
      end;
      //
      if (0 < pos('tcp', loCase(md.r_proto))) then begin
	//
	if (0 < pos('setup:active', loCase(md.r_a))) then
	  f_sdp_role := pr_active
	else
	  if (0 < pos('setup:passive', loCase(md.r_a))) then
	    f_sdp_role := pr_passive
	  else
	    if (0 < pos('setup:actpass', loCase(md.r_a))) then
	      f_sdp_role := pr_actpass
	    else
	      if (0 < pos('setup:holdconn', loCase(md.r_a))) then
		f_sdp_role := pr_holdconn;
	//
	f_socketType := c_ips_socket_TCP;
      end
      else
	f_sdp_role := pr_none;
    end
    else
      setNewFormat(8000, 1, 16, c_rtp_enc_L16);
    //
  end;
end;

// --  --
procedure unaIPStreamer.setSTUNserver(const value: string);
var
  crack: unaURIcrack;
begin
  if (crackURI(value, crack)) then begin
    //
    if (('' = crack.r_scheme) or ('stun' = loCase(crack.r_scheme))) then begin
      //
      f_STUNserver := crack.r_hostName;
      if (0 < f_crack.r_port) then
	f_STUNPort := int2str(crack.r_port)
      else
	f_STUNPort := int2str(C_STUN_DEF_PORT);
    end;
  end;
end;

// --  --
procedure unaIPStreamer.setURI(const value: string);
var
  scheme: string;
  noPort: bool;
begin
  close();
  //
  if (crackURI(value, f_crack)) then begin
    //
    f_URI := value;
    //
    scheme := f_crack.r_scheme;
    f_URIHost := f_crack.r_hostName;
    //
    noPort := false;
    if (0 <= f_crack.r_port) then
      f_URIPort := int2str(f_crack.r_port)
    else
      noPort := true;
    //
    if ('udp' = scheme) then begin
      //
      f_protocol := c_ips_protocol_RAW;
      //
      if (isMulticastAddr(URIHost)) then
	f_socketType := c_ips_socket_UDP_multicast
      else
	f_socketType := c_ips_socket_UDP_unicast;
      //
    end else
    if ('tcp' = scheme) then begin
      //
      f_protocol := c_ips_protocol_RAW;
      f_socketType := c_ips_socket_TCP;
    end else
    if ('rtp' = scheme) then begin
      //
      f_protocol := c_ips_protocol_RTP;
      //
      if (isMulticastAddr(URIHost)) then
	f_socketType := c_ips_socket_UDP_multicast
      else begin
	//
	if (pr_none = f_sdp_role) then
	  f_socketType := c_ips_socket_UDP_unicast
	else
	  f_socketType := c_ips_socket_TCP;
      end;
      //
      if (noPort) then
	f_URIPort := int2str(C_RTP_PORT_Default);
    end else
    if ('rtsp' = scheme) then begin
      //
      f_protocol := c_ips_protocol_RTSP;
      f_socketType := c_ips_socket_TCP;
      //
      if (noPort) then
	f_URIPort := int2str(C_RTSP_PORT_Default);
    end else
    if ('rtspu' = scheme) then begin
      //
      f_protocol := c_ips_protocol_RTSP;
      f_socketType := c_ips_socket_UDP_unicast;
      //
      if (noPort) then
	f_URIPort := int2str(C_RTSP_PORT_Default);
    end else
    if ('http' = scheme) then begin
      //
      f_protocol := c_ips_protocol_SHOUT;
      f_socketType := c_ips_socket_TCP;
    end else
      f_protocol := c_ips_protocol_ERROR;
    //
    f_URIuserName := f_crack.r_userName;
    f_URIuserPass := f_crack.r_password;
  end
  else
    f_descError := 'Invalid URI, err=' + int2str(GetLastError());
end;

// --  --
procedure unaIPStreamer.updateBW(isIN: bool; delta: int);
begin
  if (acquire32(f_bwAcq, 10)) then try
    //
    if (0 = f_bwTM) then
      f_bwTM := timeMarkU();
    //
    if (isIn) then
      inc(f_bwInDelta, delta)
    else
      inc(f_bwOutDelta, delta);
    //
    if (2000 < timeElapsed64U(f_bwTM)) then begin
      //
      f_bwIn := f_bwInDelta shl 2;
      f_bwOut := f_bwOutDelta shl 2;
      //
      f_bwTM := timeMarkU();
      f_bwInDelta := 0;
      f_bwOutDelta := 0;
    end;
  finally
    release32(f_bwAcq);
  end;
end;


{ unaReceiverDataWatchDog }

type
  {*
	Internal class for data flow check
  }
  unaReceiverDataWatchDog = class(unaThread)
  private
    f_rec: TunaIPReceiver;
    f_dataTM: uint64;
  protected
    function execute(threadID: unsigned): int; override;
  public
    constructor create(rec: TunaIPReceiver);
  end;


// --  --
constructor unaReceiverDataWatchDog.create(rec: TunaIPReceiver);
begin
  f_rec := rec;
  //
  inherited create();
end;

// --  --
function unaReceiverDataWatchDog.execute(threadID: unsigned): int;
begin
  f_dataTM := timeMarkU();
  //
  while (not shouldStop) do begin
    //
    if (c_receiver_noDataWatchDogTimeout < timeElapsedU(f_dataTM)) then begin
      //
      f_dataTM := timeMarkU();
      //
    {$IFDEF LOG_IPStreaming_INFOS }
      logMessage(className + '.execute() - master receiver got no input bandwidth for ' + int2str(c_receiver_noDataWatchDogTimeout, 10, 3) + 'ms, re-opening the receiver.');
    {$ENDIF LOG_IPStreaming_INFOS }
      //
      /// restart streaming
      f_rec.f_keepWD := true;
      try
	f_rec.close();
	f_rec.open();
      finally
        f_rec.f_keepWD := false;
      end;
    end;
    //
    sleepThread(500);	// no reason for short sleeps
    //
    // got input data recently?
    if (not shouldStop and (0 < f_rec.inBandwidth)) then
      f_dataTM := timeMarkU();
  end;
  //
  result := 0;
end;


{ TunaIPReceiver }

// --  --
procedure TunaIPReceiver.AfterConstruction();
begin
  reconnectIfNoData := true;
  //
  CNresendInterval := c_def_CNresendInterval;
  //
  f_decoderMPEG := mpegDecoder.create(exLib[c_lib_mpg]);
  if (f_decoderMPEG.libOK) then
    mpegDecoder(f_decoderMPEG).f_master := self
  else begin
    //
    freeAndNil(f_decoderMPEG);
    f_descError := 'No mpeg decoder';
  end;
  //
  f_speexLib := unaSpeexLib.create(exLib[c_lib_speex]);
  if (not f_speexLib.libOK) then begin
    //
    freeAndNil(f_speexLib);
    f_descError := f_descError + 'No Speex library';
  end;
  //
  f_dataWatchDog := unaReceiverDataWatchDog.create(self);
  //
  inherited;
end;

// --  --
procedure TunaIPReceiver.BeforeDestruction();
begin
  close();
  //
  f_loStreamer := nil;	// do not dispose low-level streamer in inherited class
  freeAndNil(f_receiverRTP);
  freeAndNil(f_receiverRTSP);
  freeAndNil(f_receiverSHOUT);
  //
  freeAndNil(f_decoderMPEG);
  //
  // NOTE: order is important!
  freeAndNil(f_decoderSpeex);
  freeAndNil(f_speexLib);
  //
  freeAndNil(f_decoderADPCM);
  freeAndNil(f_decoderCELT);
  //
  freeAndNil(f_dataWatchDog);
  //
  inherited;
end;

// --  --
procedure TunaIPReceiver.doClose();
begin
  if (not f_keepWD) then
    f_dataWatchDog.stop();
  //
  if (nil <> f_receiverRTSP) then begin
    //
    // shutdown RTSP session
    if ('' <> f_receiverRTSP_session) then
      f_receiverRTSP.sendRequest(c_RTSP_METHOD_TEARDOWN, '', '', 'Session: ' + f_receiverRTSP_session);
    //
    f_receiverRTSP.close();
  end;
  //
  if (nil <> f_receiverRTP) then
    f_receiverRTP.stop();
  //
  if (nil <> f_receiverSHOUT) then
    f_receiverSHOUT.stop();
  //
  if (nil <> f_decoderMPEG) then
    f_decoderMPEG.close();
  //
  if (nil <> f_decoderSpeex) then
    f_decoderSpeex.close();
  //
  //if (nil <> f_decoderADPCM) then
  //  f_decoderADPCM.close();	// nothing to close ;)
  //
  if (nil <> f_decoderCELT) then
    f_decoderCELT.close();
  //
  if (nil <> f_decoderG7221) then
    f_decoderG7221.close();
  //
  inherited;
end;

// --  --
function TunaIPReceiver.doGetRTCP(): unaRTCPstack;
begin
  if (nil <> f_receiverRTP) then
    result := f_receiverRTP.rtcp
  else
    result := nil;
end;

// --  --
function TunaIPReceiver.doOpen(): bool;
var
  res: HRESULT;
  URIipN: TIPv4N;
  bindAddr: TSockAddrIn;
  remoteAddr: PSockAddrIn;
  b2ip, b2port: string;
begin
  res := E_FAIL;
  //
  if (inherited doOpen()) then begin
    //
    f_loStreamer := nil;
    freeAndNil(f_receiverRTP);
    freeAndNil(f_receiverRTSP);
    freeAndNil(f_receiverSHOUT);
    f_noHoles := false;
    //
    case (protocol) of

      c_ips_protocol_RAW, c_ips_protocol_RTP: begin
	//
	if (f_mastered) then begin
	  //
	  // create receiver without a transport socket
	  f_receiverRTP := rtpReceiver.create(c_ips_protocol_RAW = protocol);
	end
	else begin
	  //
	  makeAddr(bind2ip, bind2port, bindAddr);
	  URIipN := lookupHostN(URIHost);
	  //
	  if (ignoreLocalIPs or not isThisHostIP_N(URIipN)) then begin
	    //
	    remoteAddr := malloc(sizeof(TSockAddrIn));
	    makeAddr(URIHost, URIPort, remoteAddr^);
	  end
	  else begin
	    //
	    // URI seems to specify "local" ip, use it if no specific bind2xxx were specifed
	    //
	    if (0 = portHFromAddr(@bindAddr)) then
	      b2port := URIport	// since bind2port does not specify any port, use one from URI
	    else
	      b2port := bind2port;
	    //
	    if (0 = ipN2ipH(@bindAddr)) then
	      b2ip := URIHost	// since bind2ip does not specify any ip, use one from URI
	    else
	      b2ip := bind2ip;
	    //
	    makeAddr(b2ip, b2port, bindAddr);
	    //
	    remoteAddr := nil;	// work as "listening server"
	  end;
	  //
	  try
	    f_receiverRTP := rtpReceiver.create(bindAddr, remoteAddr, not enableRTCP, nil, ttl, c_ips_socket_TCP <> socketType, c_ips_protocol_RAW = protocol, f_sdp_role);
	  finally
	    mrealloc(remoteAddr);
	  end;
	end;
	//
	rtpReceiver(f_receiverRTP).master := self;
	f_receiverRTP.CN_resendInterval := CNresendInterval;
	f_loStreamer := f_receiverRTP;
	//
	setupSessionParams();
	//
	if (f_mastered or f_receiverRTP.start()) then begin
	  //
	  needHoles(socketType, URIHost, URIPort);
	  //
	  if (0 = f_receiverRTP.socketError) then
	    res := S_OK
	  else
	    res := E_FAIL;
	  //
	  if (not SUCCEEDED(res)) then
	    f_descError := 'Socket error: ' + int2str(f_receiverRTP.socketError);
	end;
      end;

      c_ips_protocol_RTSP: begin
	//
	f_noHoles := true;
	f_receiverRTSP := RTSPRec.create();
	RTSPRec(f_receiverRTSP).f_master := self;
	//
	res := f_receiverRTSP.sendRequest(c_RTSP_METHOD_DESCRIBE, URI);
      end;

      c_ips_protocol_SHOUT: begin
	//
	f_receiverSHOUT := shoutReceiver.create(URI);
	if (f_receiverSHOUT.libOK) then begin
	  //
	  shoutReceiver(f_receiverSHOUT).f_master := self;
	  //
	  if (f_receiverSHOUT.start()) then
	    res := S_OK;
	end
	else
	  f_descError := 'No SHOUT receiver';
      end;

    end;
    //
    if (Succeeded(res)) then begin
      //
      // start receiver/decoder
      //
      if (doEncode) then begin
	//
	if (nil <> f_decoderMPEG) then
	  f_decoderMPEG.open();
	//
	if ((nil <> f_decoderSpeex) and not f_decoderSpeex.active) then
	  f_decoderSpeex.open();
	//
	//if (nil <> f_decoderADPCM) then
	//  f_decoderADPCM.open();	// nothing to open ;)
	//
	if ((nil <> f_decoderCELT) and not f_decoderCELT.active) then
	  f_decoderCELT.open();
	//
	if (nil <> f_decoderG7221) then
	  f_decoderG7221.open();
      end;
    end;
  end;
  //
  result := SUCCEEDED(res);
  //
  f_active := result;
  //
  if (active and reconnectIfNoData and not f_keepWD) then
    f_dataWatchDog.start();
end;

// --  --
function TunaIPReceiver.doWrite(_data: pointer; _len: uint; provider: pointer): uint;
var
  subZ: unsigned;
  ret: int;
  lbuf: pointer;
  ndata: pointer;
  nlen: integer;
begin
  if (assigned(f_onBeforeDecodeWrite)) then
    f_onBeforeDecodeWrite(self, _data, _len, ndata, nlen)
  else begin
    //
    ndata := _data;
    nlen := _len;
  end;
  //
  incInOutBytes(choice(nil = provider, 1, int(0)), true, nlen);
  //
  updateBW(true, nlen);
  //
  if (f_mastered and (nil <> f_master)) then
    f_master.updateBW(true, nlen);
  //
  case (f_enc) of

    c_rtp_enc_L8,
    c_rtp_enc_L16: begin
      //
      if ( doEncode and
	   (c_rtp_enc_L16 = f_enc) and (nil <> f_receiverRTP) and
	   ((f_receiverRTP.isRAW and swapRAWbytes) or (not f_receiverRTP.isRAW))
	 ) then
	mswapbuf16(ndata, nlen);
      //
      onNewData(ndata, nlen, self);
    end;

    c_rtp_enc_MPA: begin
      //
      if (doEncode and (nil <> f_decoderMPEG)) then begin
	//
	f_decoderMPEG.feed(ndata, nlen);
	repeat
	  //
	  subZ := f_bufSize;
	  ret := f_decoderMPEG.read(f_buf, subZ);
	  if (MPG123_NEW_FORMAT = ret) then
	    continue;
	  //
	  if ((MPG123_OK = ret) or (MPG123_NEED_MORE = ret)) then begin
	    //
	    if (0 < subZ) then
	      onNewData(f_buf, subZ, self)
	    else
	      break;
	  end
	  else
	    break;
	  //
	until (MPG123_NEED_MORE = ret);
      end
      else
	if (doEncode and (nil = f_decoderMPEG)) then
	  f_descError := 'No mpeg decodign library'
	else
	  onNewData(ndata, nlen, self);
    end;

    c_rtp_enc_PCMA,
    c_rtp_enc_PCMU: begin
      //
      if (doEncode) then begin
	//
	while (0 < nlen) do begin
	  //
	  subZ := nlen; 	// ready to receive subZ decompressed samples (and subZ * 2 bytes)
	  try
	    if (f_bufSize < subZ shl 1) then
	      subZ := f_bufSize shr 1;
	    //
	    if (c_rtp_enc_PCMA = f_enc) then
	      alaw_expand(subZ, ndata, f_buf)
	    else
	      ulaw_expand(subZ, ndata, f_buf);
	    //
	    onNewData(f_buf, subZ shl 1, self);
	  finally
	    dec(nlen, subZ);
	  end;
	end;
      end
      else
	onNewData(ndata, nlen, self);
    end;

    c_rtp_enc_DVI4,
    c_rtp_enc_VDVI: begin
      //
      if (doEncode and (nil <> f_decoderADPCM)) then begin
	//
	ret := f_decoderADPCM.decode(ndata, nlen, lbuf);
	onNewData(lbuf, ret, self);
      end
      else
	onNewData(ndata, nlen, self);
    end;

    c_rtp_enc_Speex: begin
      //
      if (doEncode and (nil <> f_decoderSpeex)) then begin
	//
	f_decoderSpeex.decode(ndata, nlen);
      end
      else
	if (doEncode and (nil = f_decoderSpeex)) then
	  f_descError := 'No Speex decodign library'
	else
	  onNewData(ndata, nlen, self);
    end;

    c_rtp_enc_CELT: begin
      //
      if (doEncode and (nil <> f_decoderCELT)) then begin
	//
	f_decoderCELT.decode(ndata, nlen);
      end
      else
	if (doEncode and (nil = f_decoderCELT)) then
	  f_descError := 'No CELT decodign library'
	else
	  onNewData(ndata, nlen, self);
    end;

    c_rtp_enc_G7221: begin
      //
      if (doEncode and (nil <> f_decoderG7221)) then begin
	//
	f_decoderG7221.write(ndata, nlen);
      end
      else
	if (doEncode and (nil = f_decoderG7221)) then
	  f_descError := 'No G.722.1 decoder'
	else
	  onNewData(ndata, nlen, self);
    end;

    c_rtp_enc_GSM,
    c_rtp_enc_GSM49: begin
      //
      if (doEncode and (nil <> f_decoderGSM)) then
	f_decoderGSM.write(ndata, nlen)
      else
	if (doEncode and (nil = f_decoderGSM)) then
	  f_descError := 'No GSM decoder'
	else
	  onNewData(ndata, nlen, self);
    end;

    c_rtp_enc_Vorbis: begin
      // TODO:
      onNewData(ndata, nlen, self);
    end;

    c_rtp_enc_T140: begin
      // text
      onNewText(ndata, nlen);
    end

    else
      onNewData(ndata, nlen, self);

  end;
  //
  result := nlen;
end;

// --  --
function TunaIPReceiver.getCNRI(): int;
begin
  if (nil <> f_receiverRTP) then begin
    //
    result := f_receiverRTP.CN_resendInterval;
    f_cnri := result;
  end
  else
    result := f_cnri;
end;

// --  --
function TunaIPReceiver.getDemuxer: unaMpegTSDemuxer;
begin
  result := rtpReceiver(f_receiverRTP).f_mpegDemuxer;
end;

// --  --
function TunaIPReceiver.isActive(): bool;
begin
  result := inherited isActive();
  //
  if (result) then begin
    //
    // check if receiver is still running
    if ((nil <> f_receiverRTP) and (unatsRunning <> f_receiverRTP.status)) then begin
      //
      f_active := false;
      result := false;
    end;
  end;
end;

// --  --
procedure TunaIPReceiver.needHoles(st: int; const host, portRTP, portRTCP: string);
begin
  inherited;
  //
  if ('' <> host) then begin
    //
    f_addrST := st;
    makeAddr(host, portRTP, f_addrRTP);
    //
    if ('' = trimS(portRTCP)) then begin
      //
      f_addrRTCP := f_addrRTP;
      if ($FFFF <> unsigned(f_addrRTCP.sin_port)) then
	f_addrRTCP.sin_port := swap16u(swap16u(f_addrRTCP.sin_port) + 1);
    end
    else
      makeAddr(host, portRTCP, f_addrRTCP);
  end;
  //
  // make RTCP hole
  if (enableRTCP and (nil <> f_receiverRTP.rtcp)) then begin
    //
    f_receiverRTP.rtcp.sendAPPto(@f_addrRTCP, 0, c_rtcp_appCmd_hello, nil, 0, true);
  end;
  //
  // make UDP RTP hole
  if (c_ips_socket_UDP_unicast = f_addrST) then begin
    //
  {$IFDEF LOG_IPStreaming_INFOS }
    logMessage(className + '.needHoles() - about to send CN to ' + addr2str(@f_addrRTP));
  {$ENDIF LOG_IPStreaming_INFOS }
    //
    f_receiverRTP.sendRTP_CN_To(@f_addrRTP);
  end;
end;

// --  --
procedure TunaIPReceiver.onFormatChange(rate, channels, bits, encoding, bitrate: int);
begin
  inherited;
  //
  case (encoding) of

    c_rtp_enc_Speex: begin
      //
      freeAndNil(f_decoderSpeex);
      //
      if ((nil <> f_speexLib) and f_speexLib.libOK and doEncode) then begin
	//
	case (rate) of

	  8000 : f_decoderSpeex := speexDecoder.create(f_speexLib, SPEEX_MODEID_NB);
	  16000: f_decoderSpeex := speexDecoder.create(f_speexLib, SPEEX_MODEID_WB);
	  32000: f_decoderSpeex := speexDecoder.create(f_speexLib, SPEEX_MODEID_UWB);

	end;
	//
	if (nil <> f_decoderSpeex.lib) then
	  speexDecoder(f_decoderSpeex).f_master := self
	else begin
	  //
	  freeAndNil(f_decoderSpeex);
	  f_descError := 'No Speex library';
	end;
      end
      else
	f_descError := 'No Speex library';
      //
      if (active and (nil <> f_decoderSpeex)) then
	f_decoderSpeex.open();
    end;

    c_rtp_enc_DVI4,
    c_rtp_enc_VDVI: begin
      //
      freeAndNil(f_decoderADPCM);
      //
      if (c_rtp_enc_DVI4 = encoding) then
	f_decoderADPCM := unaADPCM_decoder.create(adpcm_DVI4)
      else
	f_decoderADPCM := unaADPCM_decoder.create(adpcm_VDVI);
    end;

    c_rtp_enc_G7221: begin
      //
      freeAndNil(f_decoderG7221);
      f_decoderG7221 := G7221Decoder.create(rate, bitrate * 1000);
      G7221Decoder(f_decoderG7221).f_master := self;
    end;

    c_rtp_enc_GSM,
    c_rtp_enc_GSM49: begin
      //
      freeAndNil(f_decoderGSM);
      f_decoderGSM := GSMDecoder.create(c_rtp_enc_GSM49 = encoding);
      GSMDecoder(f_decoderGSM).f_master := self;
    end;

    c_rtp_enc_CELT: begin
      //
      freeAndNil(f_decoderCELT);
      //
      f_frameSize := rate div 50;	// optimized for VC, other frameSize could also be provided
      //
      f_decoderCELT := celtDecoder.create(rate, frameSize, channels, exLib[c_lib_celt]);
      if (f_decoderCELT.libOK) then begin
	//
	celtDecoder(f_decoderCELT).f_master := self;
	celtDecoder(f_decoderCELT).f_lowOverhead := false;	// TODO: take it from SDP
	celtDecoder(f_decoderCELT).f_numStreams := 1;		// TODO: take it from SDP
      end
      else begin
	//
	freeAndNil(f_decoderCELT);
	f_descError := 'No CELT library';
      end;
      //
      if (active and (nil <> f_decoderCELT))  then
	f_decoderCELT.open(rate, frameSize, channels);
    end;

  end;
  //
  f_exvcFormat.formatTag := WAVE_FORMAT_PCM;
  f_exvcFormat.formatOriginal.pcmSamplesPerSecond := rate;
  f_exvcFormat.formatOriginal.pcmBitsPerSample := bits;
  f_exvcFormat.formatOriginal.pcmNumChannels := channels;
  f_exvcFormat.formatChannelMask := SPEAKER_DEFAULT;
  //
  applyFormat(@f_exvcFormat, sizeof(unaWaveFormat), self, true);
end;

// --  --
function TunaIPReceiver.onNewData(_data: pointer; _len: uint; provider: pointer): bool;
var
  ndata: pointer;
  nlen: integer;
begin
  if (assigned(f_onAfterDecodeWrite)) then
    f_onAfterDecodeWrite(self, _data, _len, ndata, nlen)
  else begin
    //
    ndata := _data;
    nlen := _len;
  end;
  //
  result := inherited onNewData(ndata, nlen, provider);
end;

// --  --
procedure TunaIPReceiver.onNewText(data: pointer; len: int);
var
  a: aString;
begin
  if ((0 < len) and (nil <> data) and assigned(f_onText)) then begin
    //
    setLength(a, len);
    move(data^, a[1], len);
    //
    f_onText(self, pwChar(UTF82UTF16(a)));
  end;
end;

// --  --
procedure TunaIPReceiver.onRTPHdr(hdr: prtp_hdr; data: pointer; len: int);
begin
  if (assigned(f_onRTPHdr)) then
    f_onRTPHdr(self, hdr, data, len);
end;

// --  --
procedure TunaIPReceiver.rtspGotError(const uri, control: string; req: int; errorCode: HRESULT);
begin
  case (req) of

    c_RTSP_METHOD_SETUP: begin
      //
      f_descError := 'Could not SETUP session';
      freeAndNil(f_receiverRTP);
      f_loStreamer := nil;
    end;

    c_RTSP_METHOD_DESCRIBE,
    c_RTSP_METHOD_ANNOUNCE,
    c_RTSP_METHOD_GET_PARAMETER,
    c_RTSP_METHOD_OPTIONS,
    c_RTSP_METHOD_PAUSE,
    c_RTSP_METHOD_PLAY,
    c_RTSP_METHOD_RECORD,
    c_RTSP_METHOD_REDIRECT: ;
    c_RTSP_METHOD_SET_PARAMETER,
    c_RTSP_METHOD_TEARDOWN: begin
      //
      if ((HRESULT(-2) = errorCode) or (HRESULT(-3) = errorCode)) then
	//
	f_descError := 'Could not connect to server, please check URI'
      else begin
	//
	if (HRESULT(-4) = errorCode) then
	  //
	  f_descError := 'Incomplete response, connection was broken'
	else
	  f_descError := 'Unknown RTSP error: ' + int2str(errorCode);
      end;
    end;

  end;
end;

type
  /// dummy class to get access to protected properties of RTCP
  myRTCPstack = class(unaRTCPstack)
  end;

// --  --
procedure TunaIPReceiver.rtspGotResponse(const uri, control: string; req: int; response: unaHTTPparser);
var
  md: punaSDPMediaDescription;
  ok: bool;
  st: int;
  msg, srcPort1, srcPort2: string;
  //
  mipH: TIPv4H;
  mport: uint16;
  //
  mappedRTP, mappedRTCP: string;
  boundPort: uint16;
  bind2addr: TSockAddrIn;
begin
  msg := response.getRespCodeString();
  ok := (200 <= response.getRespCode()) and (300 > response.getRespCode());
  if (not ok) then
    // TODO: handle redirects, etc
    f_descError := 'RTSP: ' + int2str(response.getRespCode) + ' / ' + response.getRespCodeString();
  //
  case (req) of

    c_RTSP_METHOD_DESCRIBE: begin
      //
      if (ok) then begin
	//
	self.SDP := string(response.getPayload());
	if (0 < f_sdpParser.getMDCount()) then begin
	  //
	  md := f_sdpParser.getMD(0);	// request first media in list
	  //
	{$IFDEF LOG_IPStreaming_INFOS }
	  logMessage(className + '.rtspGotResponse() - binding RTP to ' + bind2port);
	{$ENDIF LOG_IPStreaming_INFOS }
	  //
	  makeAddr(bind2port, bind2ip, bind2addr);
	  f_receiverRTP := rtpReceiver.create(bind2addr, nil, false, nil, ttl);	// unicast for now only
	  f_loStreamer := f_receiverRTP;
	  f_receiverRTP.rentSockets(true);
	  try
	    f_receiverRTP.setNewSSRC(_SSRC);
	    //
	    rtpReceiver(f_receiverRTP).master := self;
	    f_receiverRTP.start(100);
	    //
	    mipH := lookupHostH(uriHost);
	    if (not isLocalNetworkAddrH(mipH) and ('' <> STUNServer)) then begin
	      //
	      Sleep(100);
	      if (getMappedIPPort4(STUNServer, mipH, mport, boundPort, STUNPort, C_STUN_PROTO_UDP, 6000, true, rtpReceiver(f_receiverRTP).in_socket)) then begin
		//
		mappedRTP := int2str(mport);
		//
	      {$IFDEF LOG_IPStreaming_INFOS }
		logMessage(className + '.rtspGotResponse() - STUN maps RTP from L' + int2str(boundPort) + ' to W' + mappedRTP);
	      {$ENDIF LOG_IPStreaming_INFOS }
		//
		if (getMappedIPPort4(STUNServer, mipH, mport, boundPort, STUNPort, C_STUN_PROTO_UDP, 6000, true, myRTCPStack(f_receiverRTP.rtcp).socketObjRTCP)) then begin
		  //
		  mappedRTCP := int2str(mport);
		  //
		{$IFDEF LOG_IPStreaming_INFOS }
		  logMessage(className + '.rtspGotResponse() - STUN maps RTCP from L' + int2str(boundPort) + ' to W' + mappedRTCP);
		{$ENDIF LOG_IPStreaming_INFOS }
		end
		else
		  mappedRTCP := f_receiverRTP.rtcp.bind2port;
	      end;
	    end
	    else begin
	      //
	      // no STUN? assume port mapping won't re-map the ports
	      mappedRTP := f_receiverRTP.portLocal;
	      mappedRTCP := f_receiverRTP.rtcp.bind2port;
	      //
	    {$IFDEF LOG_IPStreaming_INFOS }
	      logMessage(className + '.rtspGotResponse() - no STUN, mapping RTP/RTCP to L/W ' + mappedRTP + '/' + mappedRTCP);
	    {$ENDIF LOG_IPStreaming_INFOS }
	    end;
	  finally
	    f_receiverRTP.rentSockets(false);
	  end;
	  //
	  msg := 'Transport: RTP/AVP;unicast;ssrc=' + int2str(f_receiverRTP._SSRC) + ';client_port=' + mappedRTP + '-' + mappedRTCP;
	  f_receiverRTSP.sendRequest(
	    c_RTSP_METHOD_SETUP,
	    string(URI),
	    md.r_control,	// TODO: handle relative/absolute path
	    msg
	  );
	{$IFDEF LOG_IPStreaming_INFOS }
	  logMessage(className + '.rtspGotResponse() - sent [SETUP] ' + msg);
	{$ENDIF LOG_IPStreaming_INFOS }
	  //
	  f_noHoles := false;
	end;
      end;
    end;

    c_RTSP_METHOD_ANNOUNCE,
    c_RTSP_METHOD_GET_PARAMETER,
    c_RTSP_METHOD_OPTIONS,
    c_RTSP_METHOD_PAUSE: ;

    c_RTSP_METHOD_PLAY: begin
      //
      if (ok) then
	f_descInfo := response.getHeaderValue('RTP-Info');
    end;

    c_RTSP_METHOD_RECORD,
    c_RTSP_METHOD_REDIRECT: ;

    c_RTSP_METHOD_SETUP: begin
      //
      msg := loCase(response.getHeaderValue('Transport'));
      //
    {$IFDEF LOG_IPStreaming_INFOS }
      logMessage(className + '.rtspGotResponse() - SETUP: Transport=' + msg);
    {$ENDIF LOG_IPStreaming_INFOS }
      //
      srcPort1 := replace(msg, '.*server_port=([0-9]*)-([0-9]*)', '\1');
      srcPort2 := replace(msg, '.*server_port=([0-9]*)-([0-9]*)', '\2');
      if (1 < pos('unicast', msg)) then
	st := c_ips_socket_UDP_unicast
      else
	if (1 < pos('multicast', msg)) then
	  st := c_ips_socket_UDP_multicast
	else
	  st := c_ips_socket_UDP_unicast;	// TODO: or TCP?
      //
      // TODO: use 'source' from Transport instead of URIGost, but verify it is non-local IP (or in same local network)
      needHoles(st, URIHost, srcPort1, srcPort2);
      //
      f_receiverRTSP_session := trimS(response.getHeaderValue('Session'));
      if ('' <> f_receiverRTSP_session) then begin
	//
	// start RTSP media playback
	f_receiverRTSP.sendRequest(c_RTSP_METHOD_PLAY, '', '', 'Session: ' + f_receiverRTSP_session + #13#10'Range: ntp=0.000-' );
      end;
    end;

    c_RTSP_METHOD_SET_PARAMETER,
    c_RTSP_METHOD_TEARDOWN: ;

  end;
end;

// --  --
procedure TunaIPReceiver.setCNRI(value: int);
begin
  f_cnri := value;
  //
  if (nil <> f_receiverRTP) then
    f_receiverRTP.CN_resendInterval := value;
end;

// --  --
procedure TunaIPReceiver.setupSessionParams();
begin
  inherited;
  //
  if (nil <> f_receiverRTP) then begin
    //
    if ('' <> f_URIuserName) then
      f_receiverRTP.userName := f_URIuserName;
    //
    f_receiverRTP.setNewSSRC(_SSRC);
  end;
end;


{ rtpTransmitter }

// --  --
procedure rtpTransmitter.notifyBye(si: prtp_site_info; soft: bool);
begin
  if (nil <> f_master) then
    f_master.onRTCPBye(si, soft);
  //
  // IMPORTANT: inherited may remove RTP destination, so it should be called _after_ master.onRTCPBye()
  inherited;
end;

// --  --
function rtpTransmitter.okAddDest(destRTP, destRTCP: PSockAddrIn; fromHole: bool): bool;
begin
  if ((nil <> f_master) and not f_master.autoAddDestFromHolePacket) then
    result := not fromHole
  else
    result := inherited okAddDest(destRTP, destRTCP, fromHole);
end;

// --  --
procedure rtpTransmitter.onPayload(addr: PSockAddrIn; hdr: prtp_hdr; data: pointer; len, packetSize: uint);
begin
  inherited;
  //
  if (nil <> f_master) then
    f_master.onPayload(addr, hdr, data, len, packetSize);
end;

// --  --
procedure rtpTransmitter.onRTCPPacket(ssrc: u_int32; addr: PSockAddrIn; hdr: prtcp_common_hdr; packetSize: uint);
begin
  inherited;
  //
  f_master.onRTCP(ssrc, addr, hdr, packetSize);
end;


{ unaRTSPDestLinked }

// --  --
constructor unaRTSPDestLinked.create(id: int64; const session: string);
begin
  f_parserID := id;
  f_session := session;
  //
  inherited create();
end;


{ unaIPTransRTSPSession }

// --  --
constructor unaIPTransRTSPSession.create(const session, destURI: string; recSSRC: uint32; ttl: int);
var
  crack: unaURICrack;
begin
  f_session := session;
  f_destURI := destURI;
  f_recSSRC := recSSRC;
  //
  f_ttl := ttl;
  //
  crackURI(destURI, crack);
  f_destHost := crack.r_hostName;
  f_destPort := int2str(crack.r_port);
  f_destPath := crack.r_path;
  //
  f_id := session2id(session);
  //
  inherited create();
end;

// --  --
class function unaIPTransRTSPSession.session2id(const session: string): int64;
begin
  result := str2intInt64(session, -1, 32);	// assuming session is a 32-base value!
end;


{ unaIPTransRTSPSessionList }

// --  --
function unaIPTransRTSPSessionList.getId(item: pointer): int64;
begin
  if (nil <> item) then
    result := unaIPTransRTSPSession(item).id
  else
    result := -1;
end;


{ TunaIPTransmitter }

// --  --
procedure TunaIPTransmitter.AfterConstruction();
begin
  inherited;
  //
  f_transClass := rtpTransmitter;	// tunnel will override this
  //
  f_mpegBuf := bitReader.create();
  //
  f_autoAddDestFromHolePacket := true;
  //
  f_sessions := unaIPTransRTSPSessionList.create(uldt_obj);
  //
  f_idleKill := unaObjectList.create();
  f_rtspDestLinked := unaObjectList.create();
  //
  f_tm := timeMarkU();
end;

// --  --
procedure TunaIPTransmitter.allocPrebuf(size: int);
begin
  if (f_prebufSize < size) then begin
    //
    mrealloc(f_prebuf, size);
    f_prebufSize := size;
  end;
end;

// --  --
procedure TunaIPTransmitter.BeforeDestruction();
begin
  close();
  //
  freeAndNil(f_idleKill);
  freeAndNil(f_rtspDestLinked);
  //
  f_loStreamer := nil;	// do not dispose low-level streamer in inherited class
  freeAndNil(f_transRTP_root);
  //
  freeAndNil(f_transSHOUT);
  freeAndNil(f_transRTSP);
  freeAndNil(f_randomThread);
  if (nil <> f_reSessionDest) then
    disposeEA(f_reSessionDest);
  //
  freeAndNil(f_encoderMPEG);
  //
  // NOTE: Order is important!
  freeAndNil(f_encoderSpeex);
  freeAndNil(f_speexLib);
  //
  freeAndNil(f_encoderADPCM);
  freeAndNil(f_encoderCELT);
  //
  freeAndNil(f_mpegBuf);		// bitReader
  freeAndNil(f_sessions);
  //
  f_prebufSize := 0;
  mrealloc(f_prebuf);
  //
  inherited;
end;

// --  --
function TunaIPTransmitter.destAdd(dstatic: bool; const URI: string; enabled: bool; const session: string; recSSRC: uint32; ttl: int): int;
var
  id: int64;
  sess: unaIPTransRTSPSession;
begin
  sess := unaIPTransRTSPSession.create(session, URI, recSSRC, ttl);
  id := sess.id;
  result := f_sessions.indexOfId(id);
  //
  if (0 <= result) then
    freeAndNil(sess)	// already exists
  else begin
    //
    result := f_sessions.add(sess);
    //
    if (nil <> transRoot) then
      transRoot.destAdd(dstatic, URI, enabled, ttl, recSSRC)
  end;
end;

// --  --
function TunaIPTransmitter.destEnable(index: int; doEnable: bool): bool;
begin
  transRoot.destEnable(index, doEnable);
  result := true;
end;

// --  --
function TunaIPTransmitter.destEnable(const URI, session: string; doEnable: bool): bool;
var
  sess: unaIPTransRTSPSession;
begin
  if (nil <> transRoot) then begin
    //
    sess := sessionAcqBySession(session, true);
    if (nil <> sess) then try
      transRoot.destEnable(sess.f_destURI, doEnable);
    finally
      sess.releaseRO();
    end
    else
      transRoot.destEnable(URI, doEnable);
    //
    result := true;
  end
  else
    result := false;
end;

// --  --
function TunaIPTransmitter.destRemove(index: int): bool;
begin
  result := f_sessions.removeByIndex(index);
end;

// --  --
function TunaIPTransmitter.destRemove(const URI: string; const session: string): bool;
var
  sess: unaIPTransRTSPSession;
begin
  sess := sessionAcqBySession(session, true);
  if (nil <> sess) then
    sess.releaseRO()
  else begin
    //
    sess := sessionAcqByDestURI(URI, true);
    if (nil <> sess) then
      sess.releaseRO();
  end;
  //
  if (nil <> sess) then begin
    //
    if (nil <> transRoot) then
      transRoot.destRemove(sess.f_destURI);
    //
    f_sessions.removeItem(sess);
  end;
  //
  result := (nil <> sess);
end;

// --  --
procedure TunaIPTransmitter.doClose();
begin
  inherited;	// need active to be set to false
  //
  if (nil <> f_idleKill) then
    f_idleKill.clear();
  //
  if (nil <> f_rtspDestLinked) then
    f_rtspDestLinked.clear();
  //
  if (nil <> transRoot) then
    transRoot.close();
  //
  if (nil <> f_transSHOUT) then
    f_transSHOUT.close();
  //
  if (nil <> f_transRTSP) then
    f_transRTSP.close();
  //
  if (nil <> f_randomThread) then
    f_randomThread.stop();
  //
  if (nil <> f_encoderMPEG) then
    f_encoderMPEG.close();
  //
  if (nil <> f_encoderSpeex) then
    f_encoderSpeex.close();
  //
  //if (nil <> f_encoderADPCM) then
  //  f_encoderADPCM.close();	// nothing to close ;)
  //
  if (nil <> f_encoderCELT) then
    f_encoderCELT.close();
  //
  freeAndNil(f_mpegParser);
  //
  if (nil <> f_mpegBuf) then
    f_mpegBuf.restart();
end;

// --  --
function TunaIPTransmitter.doGetRTCP(): unaRTCPstack;
begin
  if ( (nil <> transRoot) and (nil <> transRoot.receiver) ) then
    result := transRoot.receiver.rtcp
  else
    result := nil;
end;

// --  --
function TunaIPTransmitter.doOpen(): bool;
var
  res: HRESULT;
  ok: bool;
  data: string;
begin
  ok := true;
  f_mpegAnalyze := false;
  f_mpegFS_SOratio := 0;
  f_mpegFS_SOcount := 0;
  //
  if (doEncode) then begin
    //
    case (f_enc) of

      c_rtp_enc_MPA: begin
	//
	freeAndNil(f_encoderMPEG);
	//
	f_encoderMPEG := mpegEncoder.create(exLib[c_lib_lame]);
	if (f_encoderMPEG.libOK) then
	  mpegEncoder(f_encoderMPEG).f_master := self
	else begin
	  //
	  freeAndNil(f_encoderMPEG);
	  f_descError := 'No mpeg encoding library';
	end;
	//
	f_mpegBuf.restart();
	f_mpegParser := unaMpegAudio_layer123.create(f_mpegBuf);
	//
	ok := (nil <> f_encoderMPEG);
      end;

      c_rtp_enc_Speex: begin
	//
	ok := (nil <> f_encoderSpeex);
	if (not ok) then
	  f_descError := 'No Speex library.';
      end;

      c_rtp_enc_DVI4,
      c_rtp_enc_VDVI:
	ok := (nil <> f_encoderADPCM);

      c_rtp_enc_G7221:
	ok := (nil <> f_encoderG7221);

      c_rtp_enc_GSM,
      c_rtp_enc_GSM49:
	ok := (nil <> f_encoderGSM);

      c_rtp_enc_CELT: begin
	//
	ok := (nil <> f_encoderCELT);
	if (not ok) then
	  f_descError := 'No CELT library.';
      end;

    end;
    //
  end
  else
    ok := true;
  //
  res := E_FAIL;
  //
  if (ok and inherited doOpen()) then begin
    //
    f_idleKill.add(transRoot);
    f_loStreamer := nil;
    f_transRTP_root := nil;
    //
    freeAndNil(f_transSHOUT);
    freeAndNil(f_transRTSP);
    //
    case (protocol) of

      c_ips_protocol_RAW, c_ips_protocol_RTP: begin
	//
	autoAddDestFromHolePacket := true;
	//
	data := C_FALLBACK_DEF_CMD;	// WAS: uriHost + ':' + uriPort;
			//  a small hack, so if OnExTransCmd is overriden, but don't do anything usefull (like in VCX),
			//  it will fallback to default handler
	res := ExTransCmd(C_UNA_TRANS_PREPARE, data, socketType);
      end;

      c_ips_protocol_RTSP: begin
	//
	if (nil = f_randomThread) then begin
	  //
	  f_randomThread := unaRandomGenThread.create();
	  f_randomThread.start();
	end;
	//
	autoAddDestFromHolePacket := false;
	//
	f_transRTSP := RTSPSrv.create();
	RTSPSrv(f_transRTSP).f_master := self;
	//
	res := f_transRTSP.open(choice(f_socketType = c_ips_socket_TCP, int(IPPROTO_TCP), IPPROTO_UDP), URIPort, bind2ip);
      end;

      c_ips_protocol_SHOUT: begin
	//
	// SHOUT pusher
	f_transSHOUT := shoutTransmitter.create();
	shoutTransmitter(f_transSHOUT).master := self;
	//
	res := f_transSHOUT.open(uri);
      end;

    end;
    //
    if (Succeeded(res)) then begin
      //
      // start receiver/decoder
      //
      if (doEncode) then begin
	//
	case (f_enc) of

	  c_rtp_enc_MPA: begin
	    //
	    if (nil <> f_encoderMPEG) then begin
	      //
	      f_encoderMPEG.close();
	      //
	      f_encoderMPEG.nSamplesPerSecond := f_sps;
	      f_encoderMPEG.nNumChannels := f_nch;
	      //
	      if (BE_ERR_SUCCESSFUL <> f_encoderMPEG.open(bitrate)) then
		f_descError := 'MPEG encoder failed to initialize.';
	    end;
	  end;

	  c_rtp_enc_Speex: begin
	    //
	    if (nil <> f_encoderSpeex) then
	      f_encoderSpeex.open();
	  end;

	  c_rtp_enc_DVI4,
	  c_rtp_enc_VDVI: ;     // always ready

	  c_rtp_enc_G7221: ;     // f_encoderG7221 is always ready

	  c_rtp_enc_GSM,
	  c_rtp_enc_GSM49: ;     // f_encoderGSM is always ready

	  c_rtp_enc_CELT: begin
	    //
	    if (nil <> f_encoderCELT) then begin
	      //
	      if (0 < bitrate) then
		f_encoderCELT.bitrate := bitrate;
	      //
	      f_encoderCELT.open();
	    end;
	  end;

	end;
	//
      end;
    end;
  end;
  //
  result := SUCCEEDED(res);
  f_active := result;
end;

// --  --
function TunaIPTransmitter.doWrite(_data: pointer; _len: uint; provider: pointer): uint;
var
  subZ: unsigned;
  fat: int64;
  ds, fs, so: int;
  fst, sot: int;
  lbuf: pointer;
  ndata: pointer;
  nlen: integer;
begin
  if (assigned(f_onBeforeEncodeWrite)) then
    f_onBeforeEncodeWrite(self, _data, _len, ndata, nlen)
  else begin
    //
    ndata := _data;
    nlen := _len;
  end;
  //
  case (f_enc) of

    c_rtp_enc_L8,
    c_rtp_enc_L16: begin
      //
      if ( doEncode and (c_rtp_enc_L16 = f_enc) and (nil <> transRoot) and ((transRoot.isRAW and swapRAWbytes) or (not transRoot.isRAW)) ) then
	mswapbuf16(ndata, nlen);
      //
      onDataEncoded(int(nlen) div (f_bits shr 3) div f_nch, ndata, nlen, self);	//
    end;

    c_rtp_enc_MPA: begin
      //
      if (doEncode and (nil <> f_encoderMPEG)) then begin
	//
	f_encoderMPEG.encode(ndata, nlen);
      end
      else begin
	//
	if (not f_mpegAnalyze and (0 = frameSize)) then
	  f_mpegAnalyze := true;
	//
	if (f_mpegAnalyze) then begin
	  //
	  // make sure MPEG frames are property aligned
	  if (nil = f_mpegParser) then begin
	    //
	    f_mpegBuf.restart();
	    f_mpegParser := unaMpegAudio_layer123.create(f_mpegBuf);
	  end;
	  //
	  bitReader(f_mpegBuf).write(ndata, nlen);
	  fst := 0;
	  sot := 0;
	  try
	    while (SUCCEEDED(f_mpegParser.nextFrame(f_mpegFHdr, fat, so, @f_mpegFrame, fs, true))) do begin
	      //
	      frameSize := f_mpegParser.mpegSamplesPerFrame;
	      onDataEncoded(frameSize, @f_mpegFrame, fs, self);
	      //
	      inc(fst, fs);
	      inc(sot, so);
	    end;
	  except
	    //on E: Exception do ;
	  end;
	  //
	  inc(sot, so);
	  f_mpegFS_SOratio := (f_mpegFS_SOratio + percent(sot, fst)) shr 1;
	  //
	  inc(f_mpegFS_SOcount);
	  if (100 < f_mpegFS_SOcount) then begin
	    //
	    f_mpegFS_SOcount := 0;
	    if (200 < f_mpegFS_SOratio) then
	      f_mpegAnalyze := false;	// it does not look like mpeg stream (too many oos bytes)
	  end;
	end
	else
	  onDataEncoded(frameSize, ndata, nlen, self);
      end;
    end;

    c_rtp_enc_PCMA,
    c_rtp_enc_PCMU: begin
      //
      if (doEncode) then begin
	//
	while (0 < nlen) do begin
	  //
	  subZ := nlen shr 1;	// ready to receive subZ encoded bytes (and subZ samples)
	  try
	    if (f_bufSize < subZ) then
	      subZ := f_bufSize;
	    //
	    if (c_rtp_enc_PCMA = f_enc) then
	      alaw_compress(subZ, ndata, f_buf)
	    else
	      ulaw_compress(subZ, ndata, f_buf);
	    //
	    onDataEncoded(subZ, f_buf, subZ, self);
	  finally
	    dec(nlen, subZ shl 1);
	  end;
	end;
      end
      else
	onDataEncoded(frameSize, ndata, nlen, self);
    end;

    c_rtp_enc_DVI4,
    c_rtp_enc_VDVI: begin
      //
      if (doEncode and (nil <> f_encoderADPCM)) then begin
	//
	ds := f_encoderADPCM.encode(ndata, nlen shr 1, lbuf);
	//
	onDataEncoded(nlen shr 1, lbuf, ds, self);
      end
      else
	onDataEncoded(frameSize, ndata, nlen, self);
    end;

    c_rtp_enc_G7221: begin
      //
      if (doEncode and (nil <> f_encoderG7221)) then begin
	//
	f_encoderG7221.write(ndata, nlen);
      end
      else
	onDataEncoded(frameSize, ndata, nlen, self);
    end;

    c_rtp_enc_GSM,
    c_rtp_enc_GSM49: begin
      //
      if (doEncode and (nil <> f_encoderGSM)) then
	f_encoderGSM.write(ndata, nlen)
      else
	onDataEncoded(frameSize, ndata, nlen, self);
    end;

    c_rtp_enc_Speex: begin
      //
      if (doEncode and (nil <> f_encoderSpeex)) then begin
	//
	f_encoderSpeex.encode_int(ndata, nlen);
      end
      else
	onDataEncoded(frameSize, ndata, nlen, self);
    end;

    c_rtp_enc_CELT: begin
      //
      if (doEncode and (nil <> f_encoderCELT)) then begin
	//
	f_encoderCELT.encode(ndata, nlen);
      end
      else
	onDataEncoded(frameSize, ndata, nlen, self);
    end;

    c_rtp_enc_Vorbis: begin
      ; //onDataEncoded(0, data, len, self); // todo
    end;

    else
      onDataEncoded(frameSize, ndata, nlen, self);

  end;
  //
  result := nlen;
end;

// --  --
function TunaIPTransmitter.getDestCount(): int;
begin
  result := f_sessions.count;
end;

// --  --
function TunaIPTransmitter.hasSession(const session: string): bool;
begin
  result := (0 <= f_sessions.indexOfId( unaIPTransRTSPSession.session2id(session) ));
end;

// --  --
function TunaIPTransmitter.isActive(): bool;
var
  err: int;
begin
  result := inherited isActive();
  //
  if (result) then begin
    //
    case (protocol) of

      c_ips_protocol_RAW, c_ips_protocol_RTP: begin
	//
	result := (nil <> transRoot) and transRoot.active;
	//
	if ((not result) and (nil <> transRoot)) then begin
	  //
	  if (nil <> transRoot.receiver) then
	    if (0 <> transRoot.receiver.socketError) then
	      f_descError := 'Socket error: ' + int2str(transRoot.receiver.socketError);
	end;
      end;

      c_ips_protocol_RTSP: begin
	//
	if (nil <> f_transRTSP) then begin
	  //
	  result := f_transRTSP.active;
	  if (not result) then begin
	    //
	    err := f_transRTSP.getSocketError(f_transRTSP.threadID);
	    if (0 <> err) then
	      f_descError := 'RTSP socket error: ' + int2str(err)  + ' ';
	  end;
	end
	else
	  result := false;
      end;

      c_ips_protocol_SHOUT: begin
	//
	result := (nil <> f_transSHOUT) and (c_err_OK = f_transSHOUT.error);
      end;

      else
	result := false;	// unknown or not implemented protocol

    end;

  end;
end;

// --  --
procedure TunaIPTransmitter.onDataEncoded(sampleDelta: uint; _data: pointer; _len: int; provider: pointer; marker: bool; tpayload: int);
var
  i: int32;
  sent: uint;
  //
  pb: pointer;
  pbSize: int;
  slen: int;
  //
  ndata: pointer;
  nlen: integer;
begin
  if (assigned(f_onAfterEncodeWrite)) then
    f_onAfterEncodeWrite(self, _data, _len, ndata, nlen)
  else begin
    //
    ndata := _data;
    nlen := _len;
  end;
  //
  // assuming only one transmitter (RTP or SHOUT or other) was created
  case (f_enc) of

    c_rtp_enc_MPA: begin
      //
      i := 0;
      //
      pb := @i;
      pbSize := 4;
    end;

    c_rtp_enc_CELT: begin
      //
      if ( (nil <> f_encoderCELT) and not celtEncoder(f_encoderCELT).f_lowOverhead ) then begin
	//
	pbSize := 1;
	slen := nlen;
	//
	while (255 <= slen) do begin
	  //
	  inc(pbSize);
	  dec(slen, 255);
	end;
	//
	allocPrebuf(pbSize);
	pArray(f_prebuf)[pbSize - 1] := slen;
	//
	i := 0;
	while (i < pbSize - 1) do begin
	  //
	  pArray(f_prebuf)[i] := 255;
	  inc(i);
	end;
	//
	pb := f_prebuf;
      end
      else begin
	//
	pb := nil;
	pbSize := 0;
      end;
    end;

    else begin
      //
      pb := nil;
      pbSize := 0;
    end;

  end;
  //
  sent := 0;
  try
    //
    if (nil <> transRoot) then
      sent := transRoot.transmit(sampleDelta, ndata, nlen, marker, tpayload, nil, pb, pbSize);
    //
    if (nil <> f_transSHOUT) then
      sent := sent + f_transSHOUT.send(ndata, nlen);
  finally
    //
    incInOutBytes(1, false, sent);
    updateBW(false, sent);
  end;
end;

// --  --
procedure TunaIPTransmitter.onFormatChange(rate, channels, bits, encoding, bitrate: int);
begin
  inherited;
  //
  case (encoding) of

    c_rtp_enc_Speex: begin
      //
      if (nil = f_speexLib) then begin
	//
	f_speexLib := unaSpeexLib.create(f_exLib[c_lib_speex]);
	if (f_speexLib.libOK) then
	else begin
	  //
	  freeAndNil(f_speexLib);
	  f_descError := 'No Speex library';
	end;
      end;
      //
      freeAndNil(f_encoderSpeex);
      if (nil <> f_speexLib) then begin
	//
	case (rate) of

	  8000 : f_encoderSpeex := speexEncoder.create(f_speexLib, SPEEX_MODEID_NB);
	  16000: f_encoderSpeex := speexEncoder.create(f_speexLib, SPEEX_MODEID_WB);
	  32000: f_encoderSpeex := speexEncoder.create(f_speexLib, SPEEX_MODEID_UWB);

	end;
      end;
      //
      if (nil <> f_encoderSpeex) then begin
	//
	speexEncoder(f_encoderSpeex).f_master := self;
	f_encoderSpeex.optimizeForRTP := true;
      end;
    end;

    c_rtp_enc_DVI4,
    c_rtp_enc_VDVI: begin
      //
      freeAndNil(f_encoderADPCM);
      if (c_rtp_enc_DVI4 = encoding) then
	f_encoderADPCM := unaADPCM_encoder.create(adpcm_DVI4)
      else
	f_encoderADPCM := unaADPCM_encoder.create(adpcm_VDVI);
    end;

    c_rtp_enc_G7221: begin
      //
      freeAndNil(f_encoderG7221);
      f_encoderG7221 := G7221Encoder.create(rate, bitrate * 1000);
      G7221Encoder(f_encoderG7221).f_master := self;
    end;

    c_rtp_enc_GSM,
    c_rtp_enc_GSM49: begin
      //
      freeAndNil(f_encoderGSM);
      f_encoderGSM := GSMEncoder.create(c_rtp_enc_GSM49 = encoding);
      GSMEncoder(f_encoderGSM).f_master := self;
    end;

    c_rtp_enc_CELT: begin
      //
      if (0 = frameSize) then
	f_frameSize := rate div 50;	// optimize for VC, different frameSize could also be provided
      //
      freeAndNil(f_encoderCELT);
      f_encoderCELT := celtEncoder.create(rate, frameSize, channels, exLib[c_lib_celt]);
      if (f_encoderCELT.libOK) then begin
	//
	celtEncoder(f_encoderCELT).f_master := self;
	//
	celtEncoder(f_encoderCELT).f_lowOverhead := false;	// TODO: take it from SDP
	celtEncoder(f_encoderCELT).f_numStreams := 1;		// TODO: take it from SDP
      end
      else begin
	//
	freeAndNil(f_encoderCELT);
	f_descError := 'No CELT library';
      end;
    end;

  end;
end;

// --  --
procedure TunaIPTransmitter.onIdle();
begin
  inherited;
  //
  f_idleKill.clear();
end;

// --  --
procedure TunaIPTransmitter.onPayload(addr: PSockAddrIn; hdr: prtp_hdr; data: pointer; len, packetSize: uint);
var
  rec: TunaIPReceiver;
begin
  if (self is TunaIPDuplex) then begin
    //
    rec := (self as TunaIPDuplex).f_receiver;
    if (nil <> rec.f_receiverRTP) then
      rtpReceiver(rec.f_receiverRTP).onPayload(addr, hdr, data, len, packetSize);
  end;
  //
  incInOutBytes(1, true, len);
end;

// --  --
procedure TunaIPTransmitter.onRTCPBye(si: prtp_site_info; soft: bool);
var
  i: int32;
  session: string;
  sess: unaIPTransRTSPSession;
  addr: sockaddr_in;
  thisOne: bool;
begin
  session := '';
  //
  // see if that is one of our sessions
  if (lockNonEmptyList_r(f_sessions, true, 150)) then try
    //
    for i := 0 to f_sessions.count - 1 do begin
      //
      sess := f_sessions[i];
      if (nil <> sess) then begin
	//
	thisOne := ((0 <> sess.f_recSSRC) and (sess.f_recSSRC = si.r_ssrc));
	if ((not thisOne and si.r_remoteAddrRTPValid)) then begin
	  //
	  makeAddr(sess.f_destHost, sess.f_destPort, addr);
	  thisOne := sameAddr(addr, si.r_remoteAddrRTP);
	end;
	//
	if (thisOne) then begin
	  //
	  session := sess.session;
	  break;
	end;
      end;
    end;
    //
  finally
    unlockListRO(f_sessions);
  end;
  //
  if ('' <> session) then
    ExTransCmd(C_UNA_TRANS_DEST_REMOVE, session);
end;

// --  --
function TunaIPTransmitter.ExTransCmd(cmd: int32; var data: string; udata: uint32): HRESULT;
var
  sess: unaIPTransRTSPSession;
  destURI: string;
  def: bool;
  bind2addr: TSockAddr;
  pDest: PSockAddrIn;
  b2port, b2ip: string;
  ipN: TIPv4N;
begin
  result := S_OK;
  //
  if (assigned(f_onExTransCmd)) then begin
    //
    def := false;
    destURI := data;
    f_onExTransCmd(self, udata, cmd, data);
    if (C_FALLBACK_DEF_CMD = data) then begin
      //
      data := destURI;
      def := true;
    end;
  end
  else
    def := true;
  //
  if (def) then begin
    //
    case (cmd) of

      C_UNA_TRANS_PREPARE: begin
	//
	if (nil = transRoot) then begin
	  //
	  makeAddr(bind2ip, bind2port, bind2addr);
	  ipN := lookuphostN(URIHost);
	  //
	  if (ignoreLocalIPs or not isThisHostIP_N(ipN)) then begin
	    //
	    pDest := malloc(sizeof(TSockAddr));
	    makeAddr(URIHost, URIPort, pDest^);
	  end
	  else begin
	    //
	    // this host IP is specified in URI, work as "RTP server"
	    //
	    if (0 = portHFromAddr(@bind2addr)) then
	      b2port := URIPort
	    else
	      b2port := bind2port;
	    //
	    if (0 = ipN2ipH(@bind2addr)) then
	      b2ip := URIHost
	    else
	      b2ip := bind2ip;
	    //
	    makeAddr(b2ip, b2port, bind2addr);
	    //
	    pDest := nil;
	  end;
	  //
	  try
	    f_transRTP_root := f_transClass.create
	    (
	      bind2addr,
	      f_mapping.r_dynType,
	      (c_ips_protocol_RAW = protocol),
	      not enableRTCP or (c_ips_protocol_RAW = protocol),
	      ttl,
	      pDest,
	      (pr_none = f_sdp_role),
	      f_sdp_role
	    );
	  finally
            mrealloc(pDest);
          end;
	  //
	  if (f_transRTP_root is rtpTransmitter) then
	    rtpTransmitter(f_transRTP_root).f_master := self;
	  //
	  f_loStreamer := f_transRTP_root;
	  //
	  transRoot.setNewSSRC(_SSRC);
	  transRoot.samplingRate := f_sps;
	  //
	  setupSessionParams();
	  //
	  if (transRoot.open()) then
	    result := S_OK
	  else begin
	    //
	    result := HRESULT(-10);
	    //
	    if (0 <> transRoot.socketError) then
	      f_descError := 'Socket error: ' + int2str(transRoot.socketError)
	    else
	      f_descError := 'Transmitter startup error.';
	  end;
	end;
	//
	data := transRoot.receiver.portLocal;
	if (nil <> transRoot.receiver.rtcp) then
	  data := data + '-' + transRoot.receiver.rtcp.bind2port;
      end;

      {
      C_UNA_TRANS_REMOVE: begin
	//
	freeAndNil(f_transRTP_root);
      end;
      }

      C_UNA_TRANS_GET_SDP: begin
	//
	data := sdp;
      end;

      C_UNA_TRANS_DEST_ADD: begin
	//
	if (nil = f_reSessionDest) then
	  parse(C_RE_URL_SESSION_DEST, f_reSessionDest);
	//
	destURI := replace(f_reSessionDest, data, '\3');
	destAdd(false, destURI, false, replace(f_reSessionDest, data, '\2'), udata);
      end;

      C_UNA_TRANS_DEST_REMOVE: begin
	//
	destRemove('', data);
	if (1 > f_sessions.count) then begin
	  //
	  // remove transmitter when no more sessions/destinations
	  f_idleKill.add(transRoot);
	  //
	  f_loStreamer := nil;
	  f_transRTP_root := nil;
	end;
      end;

      C_UNA_TRANS_DEST_PLAY,
      C_UNA_TRANS_DEST_PAUSE: begin
	//
	sess := sessionAcqBySession(data);
	if ((nil <> sess) and (nil <> transRoot)) then try
	  //
	  transRoot.destEnable(sess.f_destURI, C_UNA_TRANS_DEST_PLAY = cmd);
	finally
	  sess.releaseRO();
	end;
      end;

    end;
    //
  end;
end;

// --  --
procedure TunaIPTransmitter.RTSPSrvReqest(reqInt: int; const fromIP: string; request: unaRTSPServerParser; var headers, body, msg: string; var respcode: int);
var
  data, trsdp, session: string;
  adata: aString;
  hdrName: string;
  transport, s, destIP, destPortRTP, destPortRTCP: string;
  sockType: int;
  ix: int32;
  res: HRESULT;
  foundMedia: bool;
  recSSRC: uint32;
  crack: unaURICrack;
  RD: unaRTSPDestLinked;
begin
  crackURI(request.getReqURI(), crack);
  //
  case (reqInt) of

    c_RTSP_METHOD_DESCRIBE: begin
      //
    {$IFDEF LOG_IPStreaming_INFOS }
      logMessage(className + '.RTSPSrvReqest() - DESCRIBE(' + crack.r_path + ')');
    {$ENDIF LOG_IPStreaming_INFOS }
      //
      foundMedia := false;
      //
      data := crack.r_path;
      ExTransCmd(C_UNA_TRANS_GET_SDP, data);
      adata := aString(data);	// SDP
      //
      // skip SDP header, extract media only
      with unaSDPParser.create() do try
	//
	applyPayload(adata);
	trsdp := '';
	for ix := 0 to getHeaderCount - 1 do begin
	  //
	  hdrName := getHeaderName(ix);
	  if (foundMedia or ('m' = loCase(hdrName))) then begin
	    //
	    foundMedia := true;
	    trsdp := trsdp + hdrName + '=' + getHeaderValue(ix) + #13#10;
	  end;
	end;
      finally
	free();
      end;
      //
      body :=
	'v=0' + #13#10 +
	'o=- ' + int2str(IntPtr(request)) + '1 IN IP4 0.0.0.0' + #13#10 +	// use STUN to get external IP?
	's=Live streaming by ' + className + #13#10 +
	'i=VC' + #13#10 +
	't=0 0' + #13#10 +
	trimS(trsdp);
    end;

    c_RTSP_METHOD_PAUSE: begin
      //
    {$IFDEF LOG_IPStreaming_INFOS }
      logMessage(className + '.RTSPSrvReqest() - PAUSE[' + request.getHeaderValue('Session') + ']');
    {$ENDIF LOG_IPStreaming_INFOS }
      //
      // pause streaming to particular destination
      data := request.getHeaderValue('Session');
      ExTransCmd(C_UNA_TRANS_DEST_PAUSE, data);
    end;

    c_RTSP_METHOD_PLAY: begin
      //
    {$IFDEF LOG_IPStreaming_INFOS }
      logMessage(className + '.RTSPSrvReqest() - PLAY[' + request.getHeaderValue('Session') + ']');
    {$ENDIF LOG_IPStreaming_INFOS }
      //
      headers := 'Range: npt=0.000-';	// assume live stream
      //
      // unpause streaming to particular destination
      data := request.getHeaderValue('Session');
      ExTransCmd(C_UNA_TRANS_DEST_PLAY, data);
    end;

    c_RTSP_METHOD_RECORD: begin
      //
    {$IFDEF LOG_IPStreaming_INFOS }
      logMessage(className + '.RTSPSrvReqest() - RECORD[' + request.getHeaderValue('Session') + ']');
    {$ENDIF LOG_IPStreaming_INFOS }
      //
      respcode := c_RTSP_RESPCODE_MethodNotAllowed;	// todo: support recording via IPReceiver
    end;

    c_RTSP_METHOD_SETUP: begin
      //
      destPortRTP := '';
      destPortRTCP := '';
      destIP := fromIP;
      sockType := c_ips_socket_UDP_unicast;
      //
      transport := request.getHeaderValue('Transport') + ';';
      //
    {$IFDEF LOG_IPStreaming_INFOS }
      logMessage(className + '.RTSPSrvReqest() - SETUP(' + crack.r_path + '): Transport=' + transport);
    {$ENDIF LOG_IPStreaming_INFOS }
      //
      if ('' <> transport) then begin
	//
	// profile
	s := copy(transport, 1, pos(';', transport) - 1);
	if (1 = pos('rtp/avp', loCase(trimS(s)))) then begin
	  //
	  // other params
	  recSSRC := 0;
	  repeat
	    //
	    delete(transport, 1, length(s) + 1);
	    s := loCase(trimS(copy(transport, 1, pos(';', transport) - 1)));
	    //
	    if ('' <> s) then begin
	      //
	      if (1 = pos('client_port', s)) then begin
		//
		destPortRTP  := rematch(1, s, '[0-9]*');
		destPortRTCP := copy(rematch(2, s, '-[0-9]*'), 2, maxInt);
	      end
	      else
	      if (1 = pos('multicast', s)) then
		sockType := c_ips_socket_UDP_multicast
	      else
	      if (1 = pos('destination', s)) then
		destIP := copy(rematch(2, s, '=.*'), 2, maxInt)
	      else
	      if (1 = pos('ssrc', s)) then
		recSSRC := uint32(str2intInt(rematch(2, s, '[0-9]*'), 0));
	    end
	    else
	      break;
	    //
	  until ('' = s);
	  //
	  data := crack.r_path;
	  res := ExTransCmd(C_UNA_TRANS_PREPARE, data, sockType);
	  trsdp := data;	// local_RTP_port + '-' + local_RTCP_port
	  if (SUCCEEDED(res)) then begin
	    //
	    session := int2str(uint64(f_randomThread.random() shl 16) xor timeElapsed64U(f_tm), 32);	// base is 32, yep
	    //
	    data := '*' + crack.r_path + '*' + session + '*rtp://' + destIP + ':' + destPortRTP + '/';
	    //
	    f_rtspDestLinked.add(unaRTSPDestLinked.create(request.id, session));
	    //
	    ExTransCmd(C_UNA_TRANS_DEST_ADD, data, recSSRC);
	    //
	  {$IFDEF LOG_IPStreaming_INFOS }
	    logMessage(className + '.RTSPSrvReqest() - SETUP: addDest ( @' + session + '@rtp://' + destIP + ':' + destPortRTP + '/)');
	  {$ENDIF LOG_IPStreaming_INFOS }
	    //
	    headers :=
	      'Transport: RTP/AVP;' +
	      choice(c_ips_socket_UDP_multicast = sockType, 'multicast', 'unicast') + ';' +
	      'source=' + bind2ip + ';' +	// todo: use STUN?
	      'destination=' + destIP + ';' +
	      'client_port=' + destPortRTP + '-' + destPortRTCP + ';' +
	      'server_port=' + trsdp +
	      '';
	    //
	    headers := headers + #13#10 +
	      'Session: ' + session;
	  end
	  else begin
	    //
	    respcode := c_RTSP_RESPCODE_PreconditionFailed;
	    msg := 'RTP setup returned ' + int2str(res);
	  end;
	end
	else begin
	  //
	  respcode := c_RTSP_RESPCODE_NotAcceptable;
	  msg := 'I know only RTP/AVP transport!';
	end;
      end
      else begin
	//
	respcode := c_RTSP_RESPCODE_HeaderFieldNotValid;
	msg := 'Hey, I need Transport!';
      end;
    end;

    c_RTSP_METHOD_TEARDOWN: begin
      //
    {$IFDEF LOG_IPStreaming_INFOS }
      logMessage(className + '.RTSPSrvReqest() - TEARDOWN[' + request.getHeaderValue('Session') + ']');
    {$ENDIF LOG_IPStreaming_INFOS }
      //
      data := request.getHeaderValue('Session');
      if ('' = data) then begin
	//
	// remove all destinations linked to this connection
	if (lockNonEmptyList_r(f_rtspDestLinked, false, 100)) then try
	  //
	  ix := 0;
	  while (ix < f_rtspDestLinked.count) do begin
	    //
	    RD := f_rtspDestLinked.get(ix);
	    if ((nil <> RD) and (RD.f_parserID = request.id)) then begin
	      //
	      data := RD.f_session;
	      ExTransCmd(C_UNA_TRANS_DEST_REMOVE, data);
	      f_rtspDestLinked.removeByIndex(ix);
	      //
	      dec(ix);
	    end;
	    //
	    inc(ix);
	  end;
	finally
	  unlockListWO(f_rtspDestLinked);
	end;
      end
      else
	ExTransCmd(C_UNA_TRANS_DEST_REMOVE, data);
    end;

  end;
end;

// --  --
function TunaIPTransmitter.sendText(const text: wString): HRESULT;
var
  a: aString;
begin
  result := E_FAIL;
  //
  if ('' <> text) then begin
    if (nil <> transRoot) then begin
      //
      a := UTF162UTF8(text);
      onDataEncoded(length(text), @a[1], length(a), nil, false, choice(customPayloadAware, c_ips_payload_text, -1));
      //
      result := S_OK;
    end;
  end;
end;

// --  --
function TunaIPTransmitter.sessionAcqByDestURI(const destURI: string; ro: bool): unaIPTransRTSPSession;
var
  i: int32;
  sess: unaIPTransRTSPSession;
begin
  result := nil;
  if (lockNonEmptyList_r(f_sessions, true, 150)) then try
    //
    for i := 0 to f_sessions.count - 1 do begin
      //
      sess := f_sessions[i];
      if ((nil <> sess) and (sameString(sess.f_destURI, destURI))) then begin
	//
	if (sess.acquire(ro, 1001)) then
	  result := sess;
	//
	break;
      end;
    end;
    //
  finally
    unlockListRO(f_sessions);
  end;
end;

// --  --
function TunaIPTransmitter.sessionAcqByIndex(index: int; ro: bool): unaIPTransRTSPSession;
var
  sess: unaIPTransRTSPSession;
begin
  result := nil;
  if (lockNonEmptyList_r(f_sessions, true, 150)) then try
    //
    sess := f_sessions[index];
    if (nil <> sess) then begin
      //
      if (sess.acquire(ro, 101)) then
	result := sess;
    end;
  finally
    unlockListRO(f_sessions);
  end;
end;

// --  --
function TunaIPTransmitter.sessionAcqBySession(const session: string; ro: bool): unaIPTransRTSPSession;
var
  id: int64;
  sess: unaIPTransRTSPSession;
begin
  result := nil;
  if (lockNonEmptyList_r(f_sessions, true, 150)) then try
    //
    id := unaIPTransRTSPSession.session2id(session);
    sess := f_sessions.itemById(id);
    if (nil <> sess) then begin
      //
      if (sess.acquire(ro, 101)) then
	result := sess;
    end;
  finally
    unlockListRO(f_sessions);
  end;
end;

// --  --
procedure TunaIPTransmitter.setupSessionParams();
var
  i: int32;
  sess: unaIPTransRTSPSession;
begin
  inherited;
  //
  if (nil <> transRoot) then begin
    //
    if ((nil <> transRoot.receiver) and ('' <> f_URIuserName)) then
      transRoot.receiver.userName := f_URIuserName;
    //
    transRoot.setNewSSRC(_SSRC);
    //
    if (lockNonEmptyList_r(f_sessions, true, 10 {$IFDEF DEBUG }, '.setupSessionParams()' {$ENDIF DEBUG })) then try
      //
      for i := 0 to f_sessions.count - 1 do begin
	//
	sess := f_sessions[i];
	transRoot.destAdd(false, sess.f_destURI, true, sess.f_ttl, sess.f_recSSRC);
      end;
    finally
      f_sessions.releaseRO();
    end;
  end;
end;

// --  --
procedure TunaIPTransmitter.setURI(const value: string);
begin
  inherited;
  //
  if (c_ips_socket_UDP_multicast <> socketType) then begin
    //
    if (c_ips_protocol_RTSP = protocol) then
      f_bind2port := '0'
    else begin
      // unicast transmitter is basically a server, so we use host:port from URI as bindTo options
      //
      // 2012.05.01: commented out, bind2port will be 0 or taken from SDP
      //bind2port := URIPort;
    end;
    //
    // 2012.06.15: commented out, bind2ip will be 0.0.0.0 or assigned from URI in case of this host IP
    // bind2ip := URIHost;
  end;
end;


{ TunaIPDuplex }

// --  --
procedure TunaIPDuplex.AfterConstruction();
begin
  f_receiver := TunaIPReceiver.create(nil);
  f_receiver.f_mastered := true;        // we will handle all transport job for receiver
  f_receiver.f_master := self;
  f_receiver.onText := myOnText;
  //
  inherited;
end;

// --  --
procedure TunaIPDuplex.BeforeDestruction();
begin
  inherited;
  //
  freeAndNil(f_receiver);
end;

// --  --
procedure TunaIPDuplex.doClose();
begin
  f_receiver.close();
  //
  inherited;
end;

// --  --
function TunaIPDuplex.doOpen(): bool;
begin
  result := inherited doOpen();
  //
  if (result) then begin
    //
    destAdd(true, URI);
    //
    f_receiver.isFormatProvider := isFormatProvider;
    f_receiver.consumer := consumer;
    f_receiver.URI := URI;
    f_receiver.SDP := SDP;
    //
    result := f_receiver.open();
  end;
end;

// --  --
procedure TunaIPDuplex.myOnText(sender: unavclInOutPipe; const data: pwChar);
begin
  if (assigned(f_onText)) then
    f_onText(f_receiver, data);
end;

// --   --
procedure TunaIPDuplex.setupSessionParams();
begin
  inherited;
  //
  if (nil <> f_receiver) then begin
    //
    f_receiver._SSRC := _SSRC;
    f_receiver.f_URIuserName := f_URIuserName;
    //
    f_receiver.setupSessionParams();
  end;
end;


{ TunaRTPTunnel }

// --  --
function TunaRTPTunnel.addAddrTunnel(const ipportFrom, ipportTo: string): HRESULT;
begin
  if (nil <> tunnel) then
    result := tunnel.addTunnel(ipportFrom, ipportTo)
  else
    result := E_FAIL;
end;

// --  --
function TunaRTPTunnel.addSSRCTunnel(SSRCFrom, SSRCTo: u_int32): HRESULT;
begin
  if (nil <> tunnel) then
    result := tunnel.addTunnel(SSRCFrom, SSRCTo)
  else
    result := E_FAIL;
end;

// --  --
procedure TunaRTPTunnel.AfterConstruction();
begin
  inherited;
  //
  f_transClass := unaRTPTunnelServer;
  //
  doEncode := false;
  //
  sdp := 'v=0'#13#10 +		// some valid SDP, not actually used for anything
	 'm=audio 0 RTP/AVP 98'#13#10 +
	 'a=rtpmap:98 L16/8000/1';
end;

// --  --
function TunaRTPTunnel.getNumPReceived(): int64;
begin
  if (nil <> tunnel) then
    result := tunnel.packetsReceived
  else
    result := 0;
end;

// --  --
function TunaRTPTunnel.getNumPTunneled(): int64;
begin
  if (nil <> tunnel) then
    result := tunnel.packetsSent
  else
    result := 0;
end;

// --  --
function TunaRTPTunnel.getTC(): int;
begin
  if (nil <> tunnel) then
    result := tunnel.tunnelCount
  else
    result := 0;
end;

// --  --
function TunaRTPTunnel.getTunnel(): unaRTPTunnelServer;
begin
  if (nil <> f_transRTP_root) then
    result := (f_transRTP_root as unaRTPTunnelServer)
  else
    result := nil;
end;

// --  --
function TunaRTPTunnel.removeTunnel(SSRCFrom, SSRCTo: u_int32): HRESULT;
begin
  if (nil <> tunnel) then
    result := tunnel.removeTunnel(SSRCFrom, SSRCTo)
  else
    result := E_FAIL;
end;

// --  --
function TunaRTPTunnel.removeTunnel(index: int): HRESULT;
begin
  if (nil <> tunnel) then
    result := tunnel.removeTunnel(index)
  else
    result := E_FAIL;
end;


// ================

// -- utility --

// --  --
function role2str(role: c_peer_role): string;
begin
  case (role) of

    pr_active	: result := 'active';
    pr_passive	: result := 'passive';
    pr_actpass	: result := 'actpass';
    pr_holdconn : result := 'holdconn';
    else
      result := '';

  end;
end;

// --  --
function index2sdp(index: int; out pt, sps, nch: int; bitrate: int; const ip: string; ttl: int; useTCP: bool; role: c_peer_role; port: int): string;
begin
  pt := 0;
  sps := 0;
  nch := 1;
  //
  result := '';
  case (index) of

    0..4: begin
      //
      pt := 98;
      case (index) of

	0 : sps := 8000;
	1 : sps := 16000;
	2 : sps := 32000;
	3 : sps := 44100;
	4 : sps := 48000;

      end;
      //
      result := 'L16';
    end;

    5, 6: begin
      //
      pt := choice(6 = index, c_rtpPTa_PCMA, int(c_rtpPTa_PCMU));
      sps := 8000;
      result := choice(6 = index, 'PCMA', 'PCMU');
    end;

    7..9: begin
      //
      case (index) of

	7 : begin sps := 8000;  pt := c_ips_payload_speexNB;  end;
	8 : begin sps := 16000; pt := c_ips_payload_speexWB;  end;
	9 : begin sps := 32000; pt := c_ips_payload_speexUWB; end;

      end;
      //
      result := 'speex';
    end;

    10: begin
      //
      pt := 14;
      sps := 44100;
      nch := 2;
      result := 'mpa';
      bitrate := 128;
    end;

    11: begin
      //
      pt := c_rtpPTa_DVI4_8000;
      sps := 8000;
      result := 'DVI4';
    end;

    12: begin
      //
      pt := c_rtpPTa_DVI4_16000;
      sps := 16000;
      result := 'DVI4';
    end;

    13: begin
      //
      pt := c_ips_payload_vdvi;
      sps := 8000;
      result := 'VDVI';
    end;

    14, 15: begin
      //
      pt := choice(14 = index, int(c_ips_payload_celt_16000m), c_ips_payload_celt_24000m);
      sps := choice(14 = index, int(16000), 24000);
      result := 'CELT';
    end;

    16: begin
      //
      pt := c_ips_payload_celt_48000s;
      sps := 48000;
      nch := 2;
      result := 'CELT';
    end;

    17, 18: begin
      //
      nch := 1;
      result := 'G7221';
      if (17 = index) then begin
	//
	sps := 16000;
	bitrate := 24;
	pt := c_ips_payload_G7221_24;
      end
      else begin
	//
	sps := 32000;
	bitrate := 48;
	pt := c_ips_payload_G7221_48;
      end;
    end;

    19: begin
      //
      pt := c_rtpPTa_GSM;
      sps := 8000;
      nch := 1;
      result := 'GSM';
    end;

    20: begin
      //
      pt := c_ips_payload_GSM49;
      sps := 8000;
      nch := 1;
      result := 'GSM49';
    end;

  end;	// case
  //
  if ('' <> result) then begin
    //
    if (pr_active = role) then
      port := 9	// tcp client should not specify any port
    else
      if (0 > port) then
	port := 0;
    //
    result := 'v=0'#13#10 +
	   'm=audio ' + int2str(port) + ' ' + choice(useTCP, 'TCP/', '') + 'RTP/AVP ' + int2str(pt) + #13#10 +
	   'a=rtpmap:' + int2str(pt) + ' ' + result + '/' + int2str(sps) + '/' + int2str(nch);
    //
    if (pr_none <> role) then begin
      //
      result := result + #13#10 +
	'a=setup:' + role2str(role) + #13#10 +
	'a=connection:new';
    end;
    //
    if (0 <= ttl) then
      result := result + #13#10 + 'c=IN IP4 ' + ip + '/' + int2str(ttl);
    //
    if (0 < bitrate) then
      result := result + #13#10 + 'a=fmtp:' + int2str(pt) + '; bitrate=' + int2str(bitrate);
    //
  end;
end;

// --  --
function getFormatsList(): string;
begin
  result :=
    'PCM 8kHz/128kbps'#13#10 +          // 0
    'PCM 16kHz/256kbps'#13#10 +         // 1
    'PCM 32kHz/512kbps'#13#10 +         // 2
    'PCM 44.1kHz/700kbps'#13#10 +       // 3
    'PCM 48kHz/768kbps'#13#10 +         // 4
    //
    'uLaw 8kHz/64kbps'#13#10 +          // 5
    'ALaw 8kHz/64kbps'#13#10 +          // 6
    //
    'Speex NB 8kHz'#13#10 +             // 7
    'Speex WB 16kHz'#13#10 +            // 8
    'Speex UWB 32kHz'#13#10 +           // 9
    //
    'MPEG Audio (MP3) stereo'#13#10 +   // 10
    //
    'DVI4 (ADPCM)  8kHz'#13#10 +        // 11
    'DVI4 (ADPCM) 16kHz'#13#10 +        // 12
    'VDVI (ADPCM)  8kHz'#13#10 +        // 13
    //
    'CELT 16kHz '#13#10 +               // 14
    'CELT 24kHz '#13#10 +               // 15
    'CELT 48kHz stereo'#13#10 +         // 16
    //
    'G.722.1 16kHz/24kbps'#13#10 +      // 17
    'G.722.1 32kHz/48kbps'#13#10 +      // 18
    //
    'GSM 8kHz/13kbps'#13#10 +           // 19
    'GSM49 8kHz/13kbps'                 // 20
    ;
end;

//
// -- IDE --
//
procedure Register();
begin
  RegisterComponents(c_VC_reg_RTP_section_name,
  [
    TunaIPTransmitter,
    TunaIPReceiver,
    TunaIPDuplex
  ]);
end;


end.

