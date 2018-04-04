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

	  unaConfRTPclient.pas
	  unaConfRTP client class

	----------------------------------------------
	  Copyright (c) 2009-2011 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, Feb 2010

	  modified by:
		Lake, Feb-Dec 2010
		Lake, Jan-Apr 2011

	----------------------------------------------
*)

{$I unaDef.inc }

{*
    unaConfRTP client class.

    @Author Lake

    2.5.2010.03 Still here

    2.5.2010.03 Room/client names

    2.5.2011.01 CELT codec
}

unit
  unaConfRTPclient;

interface

uses
  Windows, unaTypes, WinSock,
  unaClasses, unaSocks_RTP, unaConfRTP,
  unaSpeexAPI, unaMpgLibAPI, unaBladeEncAPI, unaG711, unaLibCelt, unaG7221,
  unaVC_pipe, unaMsAcmClasses,
  Classes;

type
  //
  evonConnected = procedure(sender: tObject; userID: int32) of object;
  evonVolChange = procedure(sender: tObject; level: int32; maxLevel: int32) of object;

  //
  unaConfClientConnStat = packed record
    //
    r_timeLeft: int32;
    r_announce: wString;
    r_announceFresh: pBool;
    r_serverRTT: uint64;
    r_serverInfo: rtp_site_info;
    r_serverInfoValid: bool;
  end;

  //
  punaConfChannelInfo = ^unaConfChannelInfo;
  unaConfChannelInfo = packed record
    //
    r_payload: int32;
    r_muted: bool;
    r_rtt: uint64;
  end;

  {*
	A simple but powerfull RTP conference client.
  }
  TunaConfRTPclient = class(unavclInOutPipe)
  private
    f_connStatus: int;	// 1 = initiate connection
			// 2 = got first reply from server
			// 3 = joined the room
			// 4 = sent join request, waiting for reply
			//
			// -2 = join fail for some reason (see error property)
			// -4 = server timeout
			// -5 = disconnected by server request
			// -6 = disconnected by user request after being connected
			// -7 = server data error
			// -8 = local socket failure
			// -9 = server down or unreachable
    //
    f_connTM: uint64; 	// helps to timeout on server we never hear from
    //
    f_error: HRESULT;
    f_errorData: pointer;
    f_errorDataSize: int;
    //
    f_disconnecting: bool;
    //
    f_bin, f_bout: int;
    f_bwIn, f_bwOut: int;
    f_bwTM: uint64;
    //
    f_idleLock: unaObject;
    //
    f_micON: bool;
    f_playbackON: bool;
    //
    f_micLevel: int;
    f_playbackLevel: int;
    //
    f_inVolume, f_outVolume: int;
    //
    f_onConn: evonConnected;
    f_onDisconn: evonConnected;
    //
    f_userName: wString;
    f_lastRoomName: wString;
    f_srvAddrRTP: sockaddr_in;
    f_srvAddrRTCP: sockaddr_in;
    //
    f_srvSSRC: u_int32;
    f_srvCNAME: wString;
    //
    f_joined: bool;
    //
    f_sps: int;
    f_encoding: int;
    f_payload: int;
    //
    f_bufEnc: pointer;
    f_bufEncSize: unsigned;
    f_bufDec: pointer;
    f_bufDecSize: unsigned;
    f_bufResIn: pointer;
    f_bufResInSize: unsigned;
    f_bufResOut: array[0..c_max_audioStreams_per_room - 1] of pointer;
    f_bufResOutSize: unsigned;
    f_bufNoEcho: pointer;
    f_bufNoEchoSize: unsigned;
    //
    f_trans: unaRTPTransmitter;
    //
    f_mixer: unaWaveMixerDevice;
    //
    f_srvMasterkey: unaConfRTPkey;
    f_srvSessionKey: unaConfRTPkey;
    //
    f_speex: unaSpeexLib;
    //
    f_decoderSpeex_8000: array[0..c_max_audioStreams_per_room - 1] of unaSpeexDecoder;
    f_decoderSpeex_16000: array[0..c_max_audioStreams_per_room - 1] of unaSpeexDecoder;
    f_decoderSpeex_32000: array[0..c_max_audioStreams_per_room - 1] of unaSpeexDecoder;
    //
    f_decoderMpeg: array[0..c_max_audioStreams_per_room - 1] of unaLibmpg123Decoder;
    f_decoderCELT: array[0..c_max_audioStreams_per_room - 1] of unaLibCELTdecoder;
    f_decoderG7221: array[0..c_max_audioStreams_per_room - 1] of unaG7221Decoder;
    //
    f_decoder_SSRC: array[0..c_max_audioStreams_per_room - 1] of u_int32;
    f_decoder_TM  : array[0..c_max_audioStreams_per_room - 1] of uint64;
    f_decoder_info: array[0..c_max_audioStreams_per_room - 1] of unaConfChannelInfo;
    //
    f_encoderSpeex_8000: unaSpeexEncoder;
    f_encoderSpeex_16000: unaSpeexEncoder;
    f_encoderSpeex_32000: unaSpeexEncoder;
    f_encoderMpeg: unaLameEncoder;
    f_encoderCELT: unaLibCELTencoder;
    f_encoderG7221: unaG7221Encoder;
    //
    f_dsp: unaSpeexDSP;
    f_dspOut: array[0..c_max_audioStreams_per_room - 1] of unaSpeexDSP;
    //
    f_dspProp: array[0..3] of bool;
    f_dspReady: bool;
    //
    f_URI: string;
    f_b2port: string;
    f_b2ip: string;
    //
    f_charBuf: aString;
    f_announce: wString;
    f_announceFresh: bool;
    //
    f_audioSrcIsPCM: boolean;
    f_frameSize: int32;
    //
    procedure closeCoders();
    procedure openEncoders();
    procedure closeDecoders(index: int);
    procedure openDecoders(index: int);
    //
    procedure mixerDA(sender: tObject; data: pointer; size: cardinal);
    //
    function sendJoin(): int;
    //
    function locateSSRC(ssrc: u_int32): int;
    //
    procedure setSrvMasterkey(const value: string);
    //
    procedure onRoomJoin();
    //
    procedure updateBW(isIn: bool; delta: int);
    //
    function getConnected(): bool;
    function getDSPbool(index: integer): bool;
    procedure setDSPbool(index: integer; value: bool);
    //
    function getSSRC(): u_int32;
    procedure setSSRC(value: u_int32);
    //
    procedure setURI(const value: string);
    //
    function getChInfo(index: int): punaConfChannelInfo;
    function getEDInt: int32;
  protected
    {*
	@return 0 if successfull
    }
    function sendClnCmd(const cmd: aString; idata: int32 = 0; data: pointer = nil; len: uint = 0): int;
    {*
	Called from context of idle thread.
    }
    procedure onIdle(rtcpIdle: bool);
    {*
	Resamples and passes data to encoder.
    }
    function doWrite(data: pointer; len: uint; provider: pointer = nil): uint; override;
    {*
	Does nothing.

	@return 0
    }
    function doRead(data: pointer; len: uint): uint; override;
    {*
	Does nothing.

	@return 0
    }
    function getAvailableDataLen(index: integer): uint; override;
    {*
	Opens/connects the client.

	@return true if successfull
    }
    function doOpen(): bool; override;
    {*
	Closes/disconnects the client.
    }
    procedure doClose(); override;
    {*
	Sends data to server. Updates BW.
    }
    procedure onEncodedData(sampleDelta: int; data: pointer; size: int); virtual;
    {*
	Handles remote data received over network
    }
    procedure handlePayload(addr: pSockAddrIn; hdr: prtp_hdr; data: pointer; len: uint); virtual;
    {*
	Handles server command
    }
    procedure handleSrvCmd(userID: u_int32; addr: pSockAddrIn; const cmd: aString; cmdData: punaConfRTPcmd); virtual;
    {*
	Resamples and sends decompressed data to internal mixer.
    }
    procedure onDecodedData(samples: pointer; size: int; index: int; sps: int); virtual;
    {*
	@return True if client is active/connected.
    }
    function isActive(): bool; override;
    {*
	Connects to server.
    }
    function connect(): HRESULT; overload;
    {*
	Disconnect from server.
    }
    procedure disconnect(newConnStatus: int);
    //
    // -- protected properties --
    //
    {*
	Payload type. *internal*
    }
    property payload: int read f_payload;
    {*
	Speex DSP object. *internal*
    }
    property dsp: unaSpeexDSP read f_dsp;
  public
    {*
	Creates an RTP Conference client.
    }
    constructor Create(aOwner: tComponent); override;
    {*
	Creates dummy RTP Conference client (mostly for debug).
    }
    constructor createDummy();
    {*
	Destroys RTP Conference client.
    }
    destructor Destroy(); override;
    {*
	Connects to server. Constructs URI property and call open().

	@param userName user name.
	@param roomName room name to join.
	@param srvAddress server address.
	@param srvPort server port (UDP).
	@return True if no error occured.
    }
    function connect(const userName, roomName: wString; const srvAddress, srvPort: string): bool; overload;
    {*
	Returns status of client connection.
    }
    function getConnectStatus(var stat: unaConfClientConnStat; needFullInfo: bool = false): int;
    {*
	@return current level of played back signal.
    }
    function getPlaybackVolume(): int;
    {*
	@return current level of recording signal.
    }
    function getMicVolume(): int;
    {*
	Must be called right after new audio chunk was released from WaveOut queue.
	NOTE: This is needed mostly for Speex AEC module to work.
    }
    procedure feedOut(data: pointer; len: unsigned; inbuf: unsigned);
    {*
	Specifies new sps/encoding to use.

	@param value One of c_rtp_enc_XXXXX
	@param sps Sampling rate
    }
    procedure setEncoding(value: int; sps: int);
    {*
	Returns SSRC of remote user.

	@return SSRC of client with specified index
    }
    function getInStreamSSRC(index: int): u_int32;
    {*
	Returns CNAME or remote user.

	@return CNAME of remote client with specified SSRC
    }
    function getRemoteName(ssrc: u_int32; out cname: wString): bool;
    {*
	Joins another room.

	@return 0 if request was sent successfully.
    }
    function roomJoin(const roomName: wString): int;
    {*
	Leaves some room.

	@return 0 if request was sent successfully.
    }
    function roomLeave(const roomName: wString): int;
    //
    // -- properties --
    //
    {*
	True when connection was established.
    }
    property connected: bool read getConnected;
    {*
	Encoding type. Must be one of supported c_rtp_enc_XXXX.
    }
    property encoding: int read f_encoding;
    {*
	Sampling rate. Must be 8000, 16000 or 32000.
    }
    property sps: int read f_sps;
    {*
	Modify playback level (from 0 to 100). Default is 100 (no modify).
    }
    property playbackLevel: int read f_playbackLevel write f_playbackLevel;
    {*
	Modify recording level (from 0 to 100). Default is 100 (no modify).
    }
    property recordingLevel: int read f_micLevel write f_micLevel;
    {*
	Enable/disable playback.
    }
    property playbackEnabled: bool read f_playbackON write f_playbackON;
    {*
	Enable/disable recording.
    }
    property recordingEnabled: bool read f_micON write f_micON;
    {*
	RTP/RTCP transmitter.
    }
    property trans: unaRTPTransmitter read f_trans;
    {*
	Mixer object *use as read-only*
    }
    property mixer: unaWaveMixerDevice read f_mixer;
    {*
	Client's RTP SSRC
    }
    property SSRC: u_int32 read getSSRC write setSSRC;
    {*
	Local user Name.
    }
    property userName: wString read f_userName;
    {*
	Last room name client was joining.
    }
    property lastRoomName: wString read f_lastRoomName;
    {*
	Output bandwidth in bits per second.
    }
    property bw_out: int read f_bwOut;
    {*
	Input bandwidth in bits per second.
    }
    property bw_in: int read f_bwIn;
    {*
	Last error code.
    }
    property error: HRESULT read f_error;
    {*
	Additional error data.
    }
    property errorDataInt: int32 read getEDInt;
    {*
	Server master key (write-only).
    }
    property srvMasterkey: string write setSrvMasterkey;
    {*
	SpeexDSP: noise suppression ON/OFF
    }
    property dsp_ns: bool index 0 read getDSPbool write setDSPbool;
    {*
	SpeexDSP: auto-gain control ON/OFF
    }
    property dsp_agc: bool index 1 read getDSPbool write setDSPbool;
    {*
	SpeexDSP: voice activity detection ON/OFF
    }
    property dsp_vad: bool index 2 read getDSPbool write setDSPbool;
    {*
	SpeexDSP: acoustic echo cancellation ON/OFF
    }
    property dsp_aec: bool index 3 read getDSPbool write setDSPbool;
    {*
	SSRC of server
    }
    property srvSSRC: u_int32 read f_srvSSRC;
    {*
	CNAME of server
    }
    property srvCNAME: wString read f_srvCNAME;
    {*
	Channel info
    }
    property channelInfo[index: int]: punaConfChannelInfo read getChInfo;
    {*
	If data is already encoded, set this property to False.
	Default is True
    }
    property audioSrcIsPCM: boolean read f_audioSrcIsPCM write f_audioSrcIsPCM;
    {*
	If audioSrcIsPCM is False, this property should specify frame size in samples.
    }
    property frameSize: int32 read f_frameSize write f_frameSize;
  published
    {*
	URI, like:

	rtp://lake:hackme@servername:8000/room_name
    }
    property URI: string read f_URI write setURI;
    {*
	Bind to this local port (default is 0, means auto-select first available port).
    }
    property bind2port: string read f_b2port write f_b2port;
    {*
	Bind to this interface (default is 0.0.0.0, means bind to all interfaces).
    }
    property bind2ip: string read f_b2ip write f_b2ip;
    {*
	Fired when client is connected.
    }
    property onConnect: evonConnected read f_onConn write f_onConn;
    {*
	Fired when client is disconnected.
    }
    property onDisconnect: evonConnected read f_onDisconn write f_onDisconn;
  end;

{*
	IDE registration.
}
procedure Register();

implementation


uses
  unaUtils, unaWave,
  unaMsAcmAPI, unaSockets,
  WinInet, MMSystem;

type
  {*
	Local client transmitter/receiver
  }
  myClnTrans = class(unaRTPTransmitter)
  private
    f_cln: TunaConfRTPclient;
  protected
    {*
	Got new RTP payload from server.
    }
    procedure onPayload(addr: pSockAddrIn; hdr: prtp_hdr; data: pointer; len, packetSize: uint); override;
    {*
	Got new RTCP packet from server.
    }
    procedure onRTCPPacket(ssrc: u_int32; addr: PSockAddrIn; hdr: prtcp_common_hdr; packetSize: uint); override;
    {*
	Got new RTCP BYE packet from server.
    }
    procedure notifyBye(si: prtp_site_info; soft: bool); override;
    {*
	Called from idle thread context.
    }
    procedure onIdle(rtcpIdle: bool); override;
  end;

  {*
	Local SpeeX decoder
  }
  mySpeexDecoder = class(unaSpeexDecoder)
  private
    f_cln: TunaConfRTPclient;
    f_index: int;
    f_sps: int;
  protected
    procedure decoder_write_int(samples: pointer; size: int); override;
  end;

  {*
	Local MPEG decoder
  }
  myMpegDecoder = class(unaLibmpg123Decoder)
  private
    f_cln: TunaConfRTPclient;
    f_index: int;
    f_sps: int;
    f_spsLastOne: int;
  protected
    procedure formatChange(rate, channels, encoding: int); override;
  end;

  {*
	Local CELT decodec class
  }
  myCELTDecoder = class(unaLibCELTdecoder)
  private
    f_cln: TunaConfRTPclient;
    f_index: int;
    f_sps: int;
  protected
    {*
	Called when encoder or decoder is ready with new portion of data.
    }
    procedure doDataAvail(data: pointer; size: int); override;
  end;

  {*
	Local G.722.1 decodec class
  }
  myG7221Decoder = class(unaG7221Decoder)
  private
    f_cln: TunaConfRTPclient;
    f_index: int;
    f_sps: int;
  protected
    {*
	Called when encoder or decoder is ready with new portion of data.
    }
    procedure notify(stream: pointer; sizeBytes: int); override;
  end;


  {*
	Local MPEG encoder
  }
  myMpegEncoder = class(unaLameEncoder)
  private
    f_cln: TunaConfRTPclient;
  protected
    procedure onEncodedData(sampleDelta: uint; data: pointer; len: uint); override;
  end;

  {*
	Local SpeeX encoder
  }
  mySpeexEncoder = class(unaSpeexEncoder)
  private
    f_cln: TunaConfRTPclient;
  protected
    procedure encoder_write(sampleDelta: uint; data: pointer; size: uint; numFrames: uint); override;
  end;

  {*
	Local CELT encoder
  }
  myCELTEncoder = class(unaLibCELTencoder)
  private
    f_cln: TunaConfRTPclient;
  protected
    {*
	Called when encoder or decoder is ready with new portion of data.
    }
    procedure doDataAvail(data: pointer; size: int); override;
  end;

  {*
	Local G.722.1 encoder

  }
  myG7221Encoder = class(unaG7221Encoder)
  private
    f_cln: TunaConfRTPclient;
  protected
    {*
	Called when encoder or decoder is ready with new portion of data.
    }
    procedure notify(stream: pointer; sizeBytes: int); override;
  end;



{ myClnTrans }

// --  --
procedure myClnTrans.notifyBye(si: prtp_site_info; soft: bool);
var
  ncs: int;
begin
  inherited;
  //
  if ( (0 = f_cln.f_srvSSRC) or (0 = si.r_ssrc) or (si.r_ssrc = f_cln.f_srvSSRC) ) then begin
    //
    // got bye from server, or server timeout
    //
    if ((0 = f_cln.f_srvSSRC) or soft) then
      ncs := -4		// never heard anything from server
    else
      ncs := -5;	// got BYE from server
    //
    f_cln.disconnect(ncs);
  end;
end;

// --  --
procedure myClnTrans.onIdle(rtcpIdle: bool);
begin
  inherited;
  //
  f_cln.onIdle(rtcpIdle);
end;

// --  --
procedure myClnTrans.onPayload(addr: pSockAddrIn; hdr: prtp_hdr; data: pointer; len, packetSize: uint);
begin
  f_cln.updateBW(true, packetSize);
  //
  f_cln.handlePayload(addr, hdr, data, len);
end;

// --  --
procedure myClnTrans.onRTCPPacket(ssrc: u_int32; addr: PSockAddrIn; hdr: prtcp_common_hdr; packetSize: uint);
var
  data: pointer;
  cmd: aString;
  len: int;
begin
  inherited;
  //
  // allow RTCP from server only
  if ( ((0 <> f_cln.srvSSRC) and (ssrc = f_cln.srvSSRC)) or
       ((0 =  f_cln.srvSSRC) and sameAddr(f_cln.f_srvAddrRTCP, addr^)) ) then begin
    //
    repeat
      //
      try
	if (1 = f_cln.f_connStatus) then
	  f_cln.f_connStatus := 2;	// got first reply from server
	//
	case (hdr.r_pt) of

	  RTCP_SDES: begin
	    //
	    if (rtcp.getMemberCNAME(ssrc, f_cln.f_srvCNAME)) then
	      if (2 = f_cln.f_connStatus) then
	        f_cln.sendJoin();
	  end;

	  RTCP_APP: begin
	    //
	    data := hdr;
	    inc(unsigned(data), 8); // skip length and SSRC
	    setLength(cmd, 4);
	    move(data^, cmd[1], 4);
	    cmd := upCase(cmd);
	    inc(unsigned(data), 4); // skip name
	    //
	    if ( (packetSize >= sizeof(rtcp_common_hdr) + 8 + sizeof(unaConfRTPcmd) + uint(punaConfRTPcmd(data).r_dataBufSz)) ) then try
	      //
	      f_cln.handleSrvCmd(ssrc, addr, cmd, data);
	    except
	    end;
	  end;

	end; // case
	//
	f_cln.updateBW(true , packetSize);
	f_cln.updateBW(false, 0);
      except
      end;
      //
      len := (swap16u(hdr.r_length_NO_) + 1) shl 2;
      dec(packetSize, len);
      if (0 < packetSize) then
	hdr := prtcp_common_hdr(@pArray(hdr)[len])
      else
	break;
      //
    until (sizeof(rtcp_common_hdr) > packetSize);
  end;
end;


{ mySpeexDecoder }

// --  --
procedure mySpeexDecoder.decoder_write_int(samples: pointer; size: int);
begin
  if (0 = f_sps) then begin
    //
    case (mode) of

      SPEEX_MODEID_NB:  f_sps := 8000;
      SPEEX_MODEID_WB:  f_sps := 16000;
      SPEEX_MODEID_UWB: f_sps := 32000;
      else
			f_sps := c_confRTPcln_mixer_sps;
    end;
  end;
  //
  if (f_cln.f_joined) then
    f_cln.onDecodedData(samples, size, f_index, f_sps);
end;


{ mySpeexEncoder }

// --  --
procedure mySpeexEncoder.encoder_write(sampleDelta: uint; data: pointer; size, numFrames: uint);
begin
  if (f_cln.f_joined) then
    f_cln.onEncodedData(sampleDelta, data, size);
end;


{ myMpegDecoder }

// --  --
procedure myMpegDecoder.formatChange(rate, channels, encoding: int);
begin
  f_sps := rate;
end;


{ myCELTDecoder }

// --   --
procedure myCELTDecoder.doDataAvail(data: pointer; size: int);
begin
  inherited;
  //
  f_cln.onDecodedData(data, size, f_index, f_sps);
end;


{ myG7221Decoder }

// --  --
procedure myG7221Decoder.notify(stream: pointer; sizeBytes: int);
begin
  inherited;
  //
  f_cln.onDecodedData(stream, sizeBytes, f_index, f_sps);
end;


{ myMpegEncoder }

// --  --
procedure myMpegEncoder.onEncodedData(sampleDelta: uint; data: pointer; len: uint);
begin
  if (f_cln.f_joined) then
    f_cln.onEncodedData(sampleDelta, data, len);
end;


{ myCELTEncoder }

// --  --
procedure myCELTEncoder.doDataAvail(data: pointer; size: int);
begin
  inherited;
  //
  if (f_cln.f_joined) then
    f_cln.onEncodedData(frameSize, data, size);
end;


{ myG7221Encoder }

// --  --
procedure myG7221Encoder.notify(stream: pointer; sizeBytes: int);
begin
  inherited;
  //
  if (f_cln.f_joined) then
    f_cln.onEncodedData(frameSize, stream, sizeBytes);
end;


{ TunaConfRTPclient }

// --  --
procedure TunaConfRTPclient.closeCoders();
var
  d: int;
begin
  if (nil <> f_encoderSpeex_8000)	then f_encoderSpeex_8000.close();
  if (nil <> f_encoderSpeex_16000) 	then f_encoderSpeex_16000.close();
  if (nil <> f_encoderSpeex_32000) 	then f_encoderSpeex_32000.close();
  if (nil <> f_encoderMpeg) 		then f_encoderMpeg.close();
  if (nil <> f_encoderCELT)		then f_encoderCELT.close();
  if (nil <> f_encoderG7221)		then f_encoderG7221.close();
  //
  for d := 0 to c_max_audioStreams_per_room - 1 do
    closeDecoders(d);
end;

// --  --
procedure TunaConfRTPclient.closeDecoders(index: int);
begin
  if (nil <> f_decoderSpeex_8000[index]) 	then f_decoderSpeex_8000[index].close();
  if (nil <> f_decoderSpeex_16000[index]) 	then f_decoderSpeex_16000[index].close();
  if (nil <> f_decoderSpeex_32000[index]) 	then f_decoderSpeex_32000[index].close();
  if (nil <> f_decoderMpeg[index]) 		then f_decoderMpeg[index].close();
  if (nil <> f_decoderCELT[index]) 		then f_decoderCELT[index].close();
  if (nil <> f_decoderG7221[index]) 		then f_decoderG7221[index].close();
end;

// --  --
function TunaConfRTPclient.connect(): HRESULT;
var
  addr: sockaddr_in;
begin
  if (not connected) then begin
    //
    f_joined := false;
    //
    f_disconnecting := false;
    f_dspReady := false;
    f_srvSSRC := 0;
    //
    freeAndNil(f_trans);
    //
    makeAddr(bind2ip, bind2port, addr);
    f_trans := myClnTrans.create(addr, c_rtpPTs_conf_speex_32000);
    myClnTrans(f_trans).f_cln := self;
    //
    trans.destAdd(true, @f_srvAddrRTP, nil);
    //trans.bind2ip := bind2ip;
    //trans.bind2port := bind2port;
    trans.receiver.userName := userName;
    //
    f_connStatus := 1;	// initiate connection
    f_connTM := timeMarkU();	// in case server will never reply
    //
    f_bin := 0;
    f_bout := 0;
    //
    f_bwTM := timeMarkU();
    //
    trans.rtcp.conferenceMode := true;
    trans.open();
    //
    sendJoin();
    //
    result := S_OK;
  end
  else
    result := S_OK;	// already connected
end;

// --  --
function TunaConfRTPclient.connect(const userName, roomName: wString; const srvAddress, srvPort: string): bool;
begin
  URI := 'rtp://' + string(urlEncodeA(utf162utf8(userName))) + '@' + srvAddress + ':' + srvPort + '/' + string(urlEncodeA(utf162utf8(roomName)));
  //
  result := open();
end;

// --  --
constructor TunaConfRTPclient.create(aOwner: tComponent);
var
  d: integer;
begin
  f_micON := true;
  f_playbackON := true;
  //
  f_b2port := '0';
  f_b2ip := '0.0.0.0';
  //
  f_idleLock := unaObject.create();
  //
  f_micLevel := 100;
  f_playbackLevel := 100;
  //
  setEncoding(c_rtp_enc_Speex, c_confRTPcln_mixer_sps);
  //
  try
    f_speex := unaSpeexLib.create();
    if (not f_speex.libOK) then begin
      //
      freeAndNil(f_speex);
      f_error := HRESULT(-12);
    end;
  except
    f_error := HRESULT(-12);
  end;
  //
  f_bufEncSize := 3200;
  f_bufEnc := malloc(f_bufEncSize);
  f_bufDecSize := 36000;
  f_bufDec := malloc(f_bufDecSize);
  f_bufResInSize := 64000;
  f_bufResIn := malloc(f_bufResInSize);
  //
  f_bufNoEchoSize := 32000;
  f_bufNoEcho := malloc(f_bufNoEchoSize);
  //
  f_bufResOutSize := 64000;
  //
  f_mixer := unaWaveMixerDevice.create(true, true, 32);
  mixer.setSampling(c_confRTPcln_mixer_sps, 16, 1);
  mixer.onDataAvailable := mixerDA;
  mixer.assignStream(false, nil);
  //
  for d := 0 to c_max_audioStreams_per_room - 1 do begin
    //
    f_bufResOut[d] := malloc(f_bufResOutSize);
    //
    try
      if (nil <> f_speex) then begin
	//
	f_decoderSpeex_8000 [d] := mySpeexDecoder.create(f_speex, SPEEX_MODEID_NB);
	f_decoderSpeex_16000[d] := mySpeexDecoder.create(f_speex, SPEEX_MODEID_WB);
	f_decoderSpeex_32000[d] := mySpeexDecoder.create(f_speex, SPEEX_MODEID_UWB);
	//
	mySpeexDecoder(f_decoderSpeex_8000[d]).f_cln := self;
	mySpeexDecoder(f_decoderSpeex_8000[d]).f_index := d;
	mySpeexDecoder(f_decoderSpeex_16000[d]).f_cln := self;
	mySpeexDecoder(f_decoderSpeex_16000[d]).f_index := d;
	mySpeexDecoder(f_decoderSpeex_32000[d]).f_cln := self;
	mySpeexDecoder(f_decoderSpeex_32000[d]).f_index := d;
      end;
      //
      try
	f_decoderMpeg[d] := myMpegDecoder.create();
	if (f_decoderMpeg[d].libOK) then begin
	  //
	  myMpegDecoder(f_decoderMpeg[d]).f_cln := self;
	  myMpegDecoder(f_decoderMpeg[d]).f_index := d;
	  myMpegDecoder(f_decoderMpeg[d]).f_sps := 0;
	end
	else begin
	  //
	  freeAndNil(f_decoderMpeg[d]);
	  f_error := HRESULT(-13);
	end;
      except
	f_error := HRESULT(-13);
      end;
      //
      try
	f_decoderCELT[d] := myCELTDecoder.create();
	if (f_decoderCELT[d].libOK) then begin
	  //
	  myCELTDecoder(f_decoderCELT[d]).f_cln := self;
	  myCELTDecoder(f_decoderCELT[d]).f_index := d;
	  myCELTDecoder(f_decoderCELT[d]).f_sps := 0;
	end
	else begin
	  //
	  freeAndNil(f_decoderCELT[d]);
	  f_error := HRESULT(-16);
	end;
      except
	f_error := HRESULT(-16);
      end;
      //
      try
	f_decoderG7221[d] := myG7221Decoder.create();
	if (true) then begin
	  //
	  myG7221Decoder(f_decoderG7221[d]).f_cln := self;
	  myG7221Decoder(f_decoderG7221[d]).f_index := d;
	  myG7221Decoder(f_decoderG7221[d]).f_sps := 0;
	end
	else begin
	  //
	  freeAndNil(f_decoderG7221[d]);
	  f_error := HRESULT(-17);
	end;
      except
	f_error := HRESULT(-17);
      end;
      //
      mixer.addStream();
    except
    end;
  end;
  //
  try
    if (nil <> f_speex) then begin
      //
      f_encoderSpeex_8000 := mySpeexEncoder.create(f_speex, SPEEX_MODEID_NB);
      f_encoderSpeex_16000 := mySpeexEncoder.create(f_speex, SPEEX_MODEID_WB);
      f_encoderSpeex_32000 := mySpeexEncoder.create(f_speex, SPEEX_MODEID_UWB);
      //
      f_encoderSpeex_8000.bitrate := 24600;
      f_encoderSpeex_16000.bitrate := 24600 * 2;
      f_encoderSpeex_32000.bitrate := 24600 * 6;
      //
      f_encoderSpeex_8000.vbr := false;
      f_encoderSpeex_8000.quality := 10;
      f_encoderSpeex_8000.optimizeForRTP := true;
      //
      f_encoderSpeex_16000.vbr := false;
      f_encoderSpeex_16000.quality := 10;
      f_encoderSpeex_16000.optimizeForRTP := true;
      //
      f_encoderSpeex_32000.vbr := true;
      f_encoderSpeex_32000.vbrQuality := 10;
      f_encoderSpeex_32000.optimizeForRTP := false;
      //
      mySpeexEncoder(f_encoderSpeex_8000).f_cln := self;
      mySpeexEncoder(f_encoderSpeex_16000).f_cln := self;
      mySpeexEncoder(f_encoderSpeex_32000).f_cln := self;
    end;
    //
  except
  end;
  //
  try
    f_encoderMpeg := myMpegEncoder.create();
    if (f_encoderMpeg.libOK) then begin
      //
      f_encoderMpeg.nNumChannels := 1;
      myMpegEncoder(f_encoderMpeg).f_cln := self;
    end
    else begin
      //
      freeAndNil(f_encoderMpeg);
      f_error := HRESULT(-15);
    end;
  except
    f_error := HRESULT(-15);
  end;
  //
  try
    f_encoderCELT := myCELTEncoder.create();
    if (f_encoderCELT.libOK) then
      myCELTEncoder(f_encoderCELT).f_cln := self
    else begin
      //
      freeAndNil(f_encoderCELT);
      f_error := HRESULT(-16);
    end;
  except
    f_error := HRESULT(-16);
  end;
  //
  try
    f_encoderG7221 := myG7221Encoder.create();
    if (true) then
      myG7221Encoder(f_encoderG7221).f_cln := self
    else begin
      //
      freeAndNil(f_encoderG7221);
      f_error := HRESULT(-17);
    end;
  except
    f_error := HRESULT(-17);
  end;
  //
  try
    f_dsp := unaSpeexDSP.create();
    if (f_dsp.libOK) then begin
      //
      for d := 0 to c_max_audioStreams_per_room - 1 do
	f_dspOut[d] := unaSpeexDSP.create();
    end
    else begin
      //
      freeAndNil(f_dsp);
      f_error := HRESULT(-14);
    end;
  except
    f_error := HRESULT(-14);
  end;
  //
  dsp_ns  := true;
  dsp_agc := true;
  dsp_vad := false;
  dsp_aec := true;
  //
  inherited create(AOwner);
end;

// --  --
constructor TunaConfRTPclient.createDummy();
var
  addr: TSockAddrIn;
begin
  f_micON := false;
  f_playbackON := false;
  //
  makeAddr('0.0.0.0', '0', addr);
  f_trans := myClnTrans.create(addr, c_rtpPTs_conf_speex_32000);
  myClnTrans(f_trans).f_cln := self;
  //
  inherited create(nil);
end;

// --  --
destructor TunaConfRTPclient.Destroy();
var
  d: integer;
begin
  inherited;
  //
  disconnect(0);
  //
  freeAndNil(f_trans);
  freeAndNil(f_mixer);
  //
  freeAndNil(f_encoderSpeex_8000);
  freeAndNil(f_encoderSpeex_16000);
  freeAndNil(f_encoderSpeex_32000);
  //
  freeAndNil(f_encoderMpeg);
  freeAndNil(f_encoderCELT);
  freeAndNil(f_encoderG7221);
  //
  for d := 0 to c_max_audioStreams_per_room - 1 do begin
    //
    freeAndNil(f_decoderSpeex_8000[d]);
    freeAndNil(f_decoderSpeex_16000[d]);
    freeAndNil(f_decoderSpeex_32000[d]);
    freeAndNil(f_dspOut[d]);
    //
    freeAndNil(f_decoderMpeg[d]);
    freeAndNil(f_decoderCELT[d]);
    freeAndNil(f_decoderG7221[d]);
    //
    mrealloc(f_bufResOut[d]);
  end;
  freeAndNil(f_speex);
  //
  freeAndNil(f_dsp);
  //
  mrealloc(f_bufEnc);
  mrealloc(f_bufDec);
  mrealloc(f_bufResIn);
  mrealloc(f_bufNoEcho);
  //
  mrealloc(f_errorData);
  //
  freeAndNil(f_idleLock);
end;

// --  --
procedure TunaConfRTPclient.disconnect(newConnStatus: int);
var
  d, i: int;
begin
  if (not f_disconnecting) then begin
    //
    f_disconnecting := true;
    f_joined := false;
    //
    if (connected and assigned(f_onDisconn)) then
      f_onDisconn(self, int32(SSRC));
    //
    if (0 <> newConnStatus) then
      f_connStatus := newConnStatus;
    //
    if (nil <> trans) then
      trans.close(true);
    //
    closeCoders();
    //
    if (nil <> mixer) then
      mixer.close();
    //
    if (nil <> mixer) then begin
      //
      for i := 0 to c_max_audioStreams_per_room - 1 do begin
	//
	if (nil <> mixer.getStream(i)) then
	  mixer.getStream(i).clear();
      end;
    end;
    //
    if (nil <> dsp) then
      dsp.close();
    //
    for d := 0 to c_max_audioStreams_per_room - 1 do begin
      //
      if (nil <> f_dspOut[d]) then
	f_dspOut[d].close();
    end;
    //
    if (-6 <> f_connStatus) then
      close();
  end;
end;

// --  --
procedure TunaConfRTPclient.doClose();
begin
  disconnect(choice(3 = f_connStatus, -6, -9));
  //
  inherited;
end;

// --  --
function TunaConfRTPclient.doOpen(): bool;
begin
  result := inherited doOpen();
  //
  if (result) then
    result := SUCCEEDED(connect());
end;

// --  --
function TunaConfRTPclient.doRead(data: pointer; len: uint): uint;
begin
  result := 0;
end;

// --  --
function TunaConfRTPclient.doWrite(data: pointer; len: uint; provider: pointer): uint;
var
  subZ, bufUsed: spx_uint32_t;
  res: int;
  vad: bool;
begin
  if (not f_joined) then begin result := 0; exit; end;
  //
  if (audioSrcIsPCM) then begin
    //
    f_inVolume := waveGetLogVolume100(waveGetVolume(data, len shr 1, 16, 1, 0));
    //
    if (connected) then begin
      //
      if (100 <> f_micLevel) then
	waveModifyVolume100(f_micLevel, data, len shr 1, 16, 1, 0);
      //
      if (f_dspReady and (nil <> dsp)) then begin
	//
	if (dsp_aec) then begin
	  //
	  dsp.echo_capture(data, f_bufNoEcho);
	  data := f_bufNoEcho;
	end;
	//
	if (int(len) shr 1 < dsp.frameSize) then
	  vad := true
	else
	  vad := dsp.preprocess(data);
	//
	if (not dsp_vad) then
	  vad := true;
      end
      else
	vad := true;
      //
      res := 0;
      if (vad) then begin
	//
	if (sps <> c_confRTPcln_mixer_sps) then begin
	  //
	  if (f_dspReady and (nil <> dsp) and (int(len) shr 1 >= dsp.frameSize)) then begin
	    //
	    subZ := len shr 1;
	    bufUsed := f_bufResInSize;
	    //
	    dsp.resampleDst(data, subZ, f_bufResIn, sps, bufUsed);
	    //
	    data := f_bufResIn;
	    len := bufUsed shl 1;
	  end
	  else begin
	    //
	    len := waveResample(data, f_bufResIn, len shr 1, 1, 1, 16, 16, c_confRTPcln_mixer_sps, sps);
	    data := f_bufResIn;
	  end;
	end;
	//
	case (encoding) of

	  c_rtp_enc_L16:
	    onEncodedData(len shr 1, data, len);

	  c_rtp_enc_PCMA,
	  c_rtp_enc_PCMU: begin
	    //
	    while (0 < len) do begin
	      //
	      subZ := len shr 1;	// ready to receive subZ encoded bytes (and subZ samples)
	      try
		if (f_bufEncSize < subZ) then
		  subZ := f_bufEncSize;
		//
		if (c_rtp_enc_PCMA = encoding) then
		  alaw_compress(subZ, data, f_bufEnc)
		else
		  ulaw_compress(subZ, data, f_bufEnc);
		//
		onEncodedData(subZ, f_bufEnc, subZ);
	      finally
		dec(len, subZ shl 1);
	      end;
	    end;
	  end;

	  c_rtp_enc_Speex: begin
	    //
	    if (nil <> f_speex) then begin
	      //
	      case (sps) of

		8000: res := f_encoderSpeex_8000.encode_int(data, int(len));
		16000: res := f_encoderSpeex_16000.encode_int(data, int(len));
		32000: res := f_encoderSpeex_32000.encode_int(data, int(len));

	      end;
	    end;
	  end;

	  c_rtp_enc_MPA: begin
	    //
	    if (nil <> f_encoderMpeg) then
	      res := f_encoderMpeg.encode(data, len);
	  end;

	  c_rtp_enc_CELT: begin
	    //
	    if (nil <> f_encoderCELT) then
	      res := f_encoderCELT.encode(data, len);
	  end;

	  c_rtp_enc_G7221: begin
	    //
	    if (nil <> f_encoderG7221) then
	      res := f_encoderG7221.write(data, len);
	  end;


	end;
      end;
      //
      if (0 <= res) then
	result := len
      else
	result := 0;
    end
    else
      result := 0;
  end
  else begin
    //
    // audio is not PCM (== already encoded)
    if (connected) then begin
      //
      onEncodedData(frameSize, data, len);
      result := len;
    end
    else
      result := 0;
  end;
end;

// --  --
procedure TunaConfRTPclient.feedOut(data: pointer; len: unsigned; inbuf: unsigned);
begin
  if (f_joined) then begin
    //
    if (f_dspReady and (nil <> dsp) and dsp_aec) then
      dsp.echo_playback(data);
  end;
end;

// --  --
function TunaConfRTPclient.getAvailableDataLen(index: integer): uint;
begin
  result := 0;
end;

// --  --
function TunaConfRTPclient.getChInfo(index: int): punaConfChannelInfo;
begin
  if ((0 <= index) and (index < c_max_audioStreams_per_room)) then
    result := @f_decoder_info[index]
  else
    result := nil;
end;

// --  --
function TunaConfRTPclient.getConnected(): bool;
begin
  result := (3 = f_connStatus);
end;

// --  --
function TunaConfRTPclient.getConnectStatus(var stat: unaConfClientConnStat; needFullInfo: bool): int;
var
  si: prtp_site_info;
  el: uint64;
begin
  result := f_connStatus;
  if (0 = f_srvSSRC) then begin
    //
    if (0 < f_connTM) then begin
      //
      el := timeElapsed64U(f_connTM);
      if (20000 > el) then
        stat.r_timeLeft := int32(20000 - el)
      else
        stat.r_timeLeft := 0;
    end
    else
      stat.r_timeLeft := 0;
    //
    if (0 > stat.r_timeLeft) then begin
      //
      if (f_disconnecting) then
	f_connStatus := -4;
      //
      disconnect(-4);
    end;
  end
  else begin
    //
    if ( (nil <> trans) and (nil <> trans.rtcp) ) then
      stat.r_timeLeft := trans.rtcp.getMemberTimeout(f_srvSSRC)
    else
      stat.r_timeLeft := -1;
  end;
  //
  stat.r_announce := f_announce;
  stat.r_announceFresh := @f_announceFresh;
  //
  stat.r_serverInfoValid := false;
  //
  if ((0 < srvSSRC) and (nil <> trans) and (nil <> trans.rtcp)) then begin
    //
    si := trans.rtcp.memberBySSRCAcq(srvSSRC, true, 10);
    if (nil <> si) then try
      //
      stat.r_serverRTT := si.r_rtt;
      if (needFullInfo) then begin
	//
	stat.r_serverInfo := si^;
	stat.r_serverInfoValid := true;
      end;
      //
    finally
      trans.rtcp.memberReleaseRO(si);
    end;
  end;
end;

// --  --
function TunaConfRTPclient.getDSPbool(index: integer): bool;
begin
  result := f_dspProp[index];
end;

// --  --
function TunaConfRTPclient.getEDInt(): int32;
begin
  if (3 < f_errorDataSize) then
    move(f_errorData^, result, sizeof(int32))
  else
    result := -1;
end;

// --  --
function TunaConfRTPclient.getMicVolume(): int;
begin
  result := f_inVolume;
end;

// --  --
function TunaConfRTPclient.getPlaybackVolume(): int;
begin
  result := f_outVolume;
end;

// --  --
function TunaConfRTPclient.getRemoteName(ssrc: u_int32; out cname: wString): bool;
begin
  if ((nil <> trans) and (nil <> trans.rtcp)) then
    result := trans.rtcp.getMemberCNAME(ssrc, cname)
  else
    result := false;
end;

// --  --
function TunaConfRTPclient.getSSRC(): u_int32;
begin
  if (nil <> trans) then
    result := trans._SSRC
  else
    result := 0;
end;

// --  --
function TunaConfRTPclient.getInStreamSSRC(index: int): u_int32;
begin
  result := f_decoder_SSRC[index];
end;

// --  --
procedure TunaConfRTPclient.handlePayload(addr: pSockAddrIn; hdr: prtp_hdr; data: pointer; len: uint);
var
  res, index, pt: int;
  dex: unaSpeexDecoder;
  subZ: unsigned;
  si: prtp_site_info;
begin
  index := -1;
  //
  pt := hdr.r_M_PT and $7F;
  case (pt) of

    c_rtpPTs_conf_speex_8000,
    c_rtpPTs_conf_speex_16000,
    c_rtpPTs_conf_speex_32000: begin
      //
      index := locateSSRC(hdr.r_ssrc_NO);
      if ((0 <= index) and not f_decoder_info[index].r_muted) then begin
	//
	dex := nil;
	case (pt) of
	  c_rtpPTs_conf_speex_8000 : dex := f_decoderSpeex_8000[index];
	  c_rtpPTs_conf_speex_16000: dex := f_decoderSpeex_16000[index];
	  c_rtpPTs_conf_speex_32000: dex := f_decoderSpeex_32000[index];
	end;
	//
	if (nil <> dex) then
	  dex.decode(data, len);
      end;
    end;

    c_rtpPTs_conf_mpeg_8000,
    c_rtpPTs_conf_mpeg_16000,
    c_rtpPTs_conf_mpeg_32000: begin
      //
      index := locateSSRC(hdr.r_ssrc_NO);
      if ((0 <= index) and not f_decoder_info[index].r_muted) then begin
	//
	if (nil <> f_decoderMPEG[index]) then begin
	  //
	  if (myMPEGDecoder(f_decoderMpeg[index]).f_sps <> pt2sps(pt)) then begin
	    //
	    if (myMPEGDecoder(f_decoderMpeg[index]).f_spsLastOne <> pt2sps(pt)) then begin
	      //
	      myMPEGDecoder(f_decoderMpeg[index]).f_spsLastOne := pt2sps(pt);
	      f_decoderMPEG[index].close();
	      myMPEGDecoder(f_decoderMpeg[index]).f_sps := pt2sps(pt);
	      f_decoderMPEG[index].open();
	    end;
	  end;
	  //
	  f_decoderMPEG[index].feed(data, len);
	  repeat
	    //
	    subZ := f_bufDecSize;
	    res := f_decoderMPEG[index].read(f_bufDec, subZ);
	    if (MPG123_NEW_FORMAT = res) then
	      continue;
	    //
	    if ((MPG123_OK = res) or (MPG123_NEED_MORE = res)) then begin
	      //
	      if (0 < subZ) then
		onDecodedData(f_bufDec, subZ, index, myMpegDecoder(f_decoderMPEG[index]).f_sps)
	      else
		break;
	    end
	    else
	      break;
	    //
	  until (MPG123_NEED_MORE = res);
	end
      end;
    end;

    c_rtpPTs_conf_CELT_8000,
    c_rtpPTs_conf_CELT_16000,
    c_rtpPTs_conf_CELT_24000: begin
      //
      index := locateSSRC(hdr.r_ssrc_NO);
      if ((0 <= index) and not f_decoder_info[index].r_muted) then begin
	//
	if (nil <> f_decoderCELT[index]) then begin
	  //
	  if (myCELTDecoder(f_decoderCELT[index]).f_sps <> pt2sps(pt)) then begin
	    //
	    f_decoderCELT[index].close();
	    myCELTDEcoder(f_decoderCELT[index]).f_sps := pt2sps(pt);
	    f_decoderCELT[index].open(myCELTDEcoder(f_decoderCELT[index]).f_sps, myCELTDEcoder(f_decoderCELT[index]).f_sps div 50);
	  end;
	  //
	  f_decoderCELT[index].decode(data, len);
	end
      end;
    end;

    c_rtpPTs_conf_G7221_8000,
    c_rtpPTs_conf_G7221_16000,
    c_rtpPTs_conf_G7221_32000: begin
      //
      index := locateSSRC(hdr.r_ssrc_NO);
      if ((0 <= index) and not f_decoder_info[index].r_muted) then begin
	//
	if (nil <> f_decoderG7221[index]) then begin
	  //
	  if (myG7221Decoder(f_decoderG7221[index]).f_sps <> pt2sps(pt)) then begin
	    //
	    freeAndNil(f_decoderG7221[index]);
	    //
	    f_decoderG7221[index] := myG7221Decoder.create(pt2sps(pt), choice(c_rtpPTs_conf_G7221_32000 = pt, int(48000), 24000));
	    myG7221Decoder(f_decoderG7221[index]).f_cln := self;
	    myG7221Decoder(f_decoderG7221[index]).f_index := index;
	    myG7221Decoder(f_decoderG7221[index]).f_sps := pt2sps(pt);
	    //
	    f_decoderG7221[index].open();
	  end;
	  //
	  f_decoderG7221[index].write(data, len);
	end
      end;
    end;

    c_rtpPTs_conf_uLaw_8000,
    c_rtpPTs_conf_uLaw_16000,
    c_rtpPTs_conf_uLaw_32000,
    c_rtpPTs_conf_ALaw_8000,
    c_rtpPTs_conf_ALaw_16000,
    c_rtpPTs_conf_ALaw_32000: begin
      //
      index := locateSSRC(hdr.r_ssrc_NO);
      if ((0 <= index) and not f_decoder_info[index].r_muted) then begin
	//
	while (0 < len) do begin
	  //
	  subZ := len; 	// ready to receive subZ decompressed samples ( and subZ * 2 bytes )
	  try
	    if (f_bufDecSize < subZ shl 1) then
	      subZ := f_bufDecSize shr 1;
	    //
	    case (pt) of

	      c_rtpPTs_conf_uLaw_8000,
	      c_rtpPTs_conf_uLaw_16000,
	      c_rtpPTs_conf_uLaw_32000:
		ulaw_expand(subZ, data, f_bufDec)
	      else
		alaw_expand(subZ, data, f_bufDec)
	    end;
	    //
	    onDecodedData(f_bufDec, subZ shl 1, index, pt2sps(pt));
	  finally
	    dec(len, subZ);
	  end;
	end;
      end;
    end;

    c_rtpPTs_conf_PCM_8000,
    c_rtpPTs_conf_PCM_16000,
    c_rtpPTs_conf_PCM_32000: begin
      //
      index := locateSSRC(hdr.r_ssrc_NO);
      if ((0 <= index) and not f_decoder_info[index].r_muted) then
	onDecodedData(data, len, index, pt2sps(pt));
    end;

  end; // case
  //
  if (0 <= index) then begin
    //
    f_decoder_TM[index] := timeMarkU();
    f_decoder_info[index].r_payload := pt;
    //
    if ((nil <> trans) and (nil <> trans.rtcp)) then begin
      //
      si := trans.rtcp.memberBySSRCAcq(swap32u(hdr.r_ssrc_NO), true, 1);
      if (nil <> si) then try
	//
	f_decoder_info[index].r_rtt := si.r_rtt;
      finally
	trans.rtcp.memberReleaseRO(si);
      end;
    end;
  end;
end;

// --  --
procedure TunaConfRTPclient.handleSrvCmd(userID: u_int32; addr: pSockAddrIn; const cmd: aString; cmdData: punaConfRTPcmd);
var
  encData: uint32;
begin
  case crc32(cmd) of

    c_confSrvCmd_joinOK_crc: begin
      //
      case (f_connStatus) of

	2: begin
	  //
	  if (assigned(f_onConn)) then
	    f_onConn(self, int32(SSRC));
	  //
	  // got session key and other stuff, must reply with join2
	  //
	  if (sizeof(unaConfRTPkey) <= cmdData.r_dataBufSz) then begin
	    //
	    encode(@cmdData.r_dataBuf, sizeof(unaConfRTPkey), @f_srvMasterKey, sizeof(unaConfRTPkey));
	    move(cmdData.r_dataBuf, f_srvSessionKey, sizeof(unaConfRTPkey));
	    //
	    encData := uint32(cmdData.r_i_data);
	    encode(@encData, 4, @f_srvSessionKey, sizeof(unaConfRTPkey));
	    //
	    if (0 = srvSSRC) then
	      f_srvSSRC := userID;
	    //
	    f_connStatus := 4;
	    //
	    sendClnCmd(c_confClnCmd_joinHasKey, 0, @encData, 4);
	  end
	  else
	    disconnect(-7);
	end;

	4: begin
	  //
	  // joined the room
	  f_connStatus := 3;
	  //
	  onRoomJoin();
	  //
	  // in case the client will go always silent,
	  //  ping RTP hole, so server will know where to send incoming audio for us
	  //
	  if ((nil <> trans) and (nil <> trans.receiver)) then
	    trans.receiver.sendRTP_CN_To(@f_srvAddrRTP);
	end;

      end;
    end;

    c_confSrvCmd_FAIL_crc: begin
      //
      // could not join the room
      //
      f_error := HRESULT(cmdData.r_i_data);
      if (0 < cmdData.r_dataBufSz) then begin
	//
	if (int(cmdData.r_dataBufSz) > f_errorDataSize) then begin
	  //
	  f_errorDataSize := min(cmdData.r_dataBufSz, 2000);
	  mrealloc(f_errorData, f_errorDataSize);
	end;
	//
	move(cmdData.r_dataBuf, f_errorData^, f_errorDataSize);
      end;
      //
      disconnect(-2);
    end;

    c_confSrvCmd_drop_crc: begin
      //
      // disconnected from room
      f_error := HRESULT(cmdData.r_i_data);
      //
      disconnect(-5);
    end;

    c_confSrvCmd_announce_crc: begin
      //
      if (0 < cmdData.r_dataBufSz) then begin
	//
	setLength(f_charBuf, cmdData.r_dataBufSz);
	move(cmdData.r_dataBuf, f_charBuf[1], cmdData.r_dataBufSz);
	f_announce := UTF82UTF16(f_charBuf);
	f_announceFresh := true;
      end;
    end;

  end;
end;

// --  --
function TunaConfRTPclient.isActive(): bool;
begin
  result := (0 < f_connStatus);
end;

// --  --
function TunaConfRTPclient.locateSSRC(ssrc: u_int32): int;
var
  i, index, iSpot: int32;
begin
  // locate this SSRC
  index := -1;
  iSpot := -1;
  ssrc := swap32u(ssrc);
  //
  for i := 0 to c_max_audioStreams_per_room - 1 do begin
    //
    if (ssrc = f_decoder_SSRC[i]) then begin
      //
      index := i;
      break;
    end
    else begin
      //
      if (0 = f_decoder_SSRC[i]) then
	iSpot := i;
    end;
  end;
  //
  if (0 > index) then begin
    //
    if (0 <= iSpot) then begin
      //
      index := iSpot;
      f_decoder_SSRC[index] := ssrc;
      f_decoder_info[index].r_muted := false;
      //
      openDecoders(index);
    end
    else begin
      //
      for i := 0 to c_max_audioStreams_per_room - 1 do begin
	//
	if (18000 < timeElapsed64U(f_decoder_TM[i])) then begin
	  //
	  index := i;
	  f_decoder_SSRC[index] := ssrc;
	  f_decoder_info[index].r_muted := false;
	  //
	  closeDecoders(index);
	  openDecoders(index);
	  //
	  break;
	end;
      end;
    end;
  end;
  //
  result := index;
end;

// --  --
procedure TunaConfRTPclient.mixerDA(sender: tObject; data: pointer; size: cardinal);
begin
  if (f_joined) then begin
    //
    if (100 <> f_playbackLevel) then
      waveModifyVolume100(f_playbackLevel, data, size shr 1, 16, 1, 0);
    //
    f_outVolume := waveGetLogVolume100(waveGetVolume(data, size shr 1, 16, 1, 0));
    //
    onNewData(data, size, self);
  end;
end;

// --  --
procedure TunaConfRTPclient.onDecodedData(samples: pointer; size: int; index: int; sps: int);
var
  outUsed,
  sz: spx_uint32_t;
begin
  if (f_joined) then begin
    //
    // resample to 32000 from sps
    if (sps <> c_confRTPcln_mixer_sps) then begin
      //
      // speex resampler available?
      if (nil <> f_dspOut[index]) then begin
	//
	// use speex resampler
	outUsed := f_bufResOutSize;
	sz := size shr 1;
	f_dspOut[index].resampleSrc(samples, sz, sps, f_bufResOut[index], outUsed);
	//
	samples := f_bufResOut[index];
	size := outUsed shl 1;
      end
      else begin
	//
	// use our poor resampler
	size := waveResample(samples, f_bufResOut[index], size shr 1, 1, 1, 16, 16, sps, c_confRTPcln_mixer_sps);
	samples := f_bufResOut[index];
      end;
    end;
    //
    if ( playbackEnabled and (nil <> mixer) and (nil <> mixer.getStream(index)) ) then
      mixer.getStream(index).write(samples, size);
  end;
end;

// --  --
procedure TunaConfRTPclient.onEncodedData(sampleDelta: int; data: pointer; size: int);
begin
  if (f_joined and f_micON and (nil <> trans)) then
    updateBW(false, trans.transmit(sampleDelta, data, size, false, payload));
end;

// --  --
procedure TunaConfRTPclient.onIdle(rtcpIdle: bool);
var
  stat: unaConfClientConnStat;
  resend: bool;
begin
  if (f_idleLock.acquire(false, 10, false {$IFDEF DEBUG }, '.onIdle()' {$ENDIF DEBUG })) then try
    //
    if (rtcpIdle and (3 = f_connStatus) and (nil <> trans) and (nil <> trans.receiver)) then begin
      //
      // check if the server has received our RTP hole ping
      getConnectStatus(stat, true);
      resend := (not stat.r_serverInfoValid or not stat.r_serverInfo.r_remoteAddrRTPValid) and (nil <> trans.rtcp);
      //
      if (resend) then begin
	//
	// make hole again
	trans.receiver.sendRTP_CN_To(@f_srvAddrRTP);
	//
	// and request a ping personally for us
	trans.rtcp.sendAPPto(@f_srvAddrRTCP, c_rtcpAPP_subtype_cln, c_rtcp_appCmd_needRTPPing);
      end;
    end;
    //
    if (rtcpIdle and (1 = f_connStatus)) then begin
      //
      // still waiting for first server reply? send request once again
      sendJoin();
    end;
    //
  finally
    f_idleLock.releaseWO();
  end;
end;

// --  --
procedure TunaConfRTPclient.onRoomJoin();
var
  d: int;
  fs: int;
begin
  fillChar(f_decoder_SSRC, sizeof(f_decoder_SSRC), #0);
  //
  f_inVolume := 0;
  f_outVolume := 0;
  //
  openEncoders();
  //
  if (nil <> dsp) then begin
    //
    if (nil <> f_encoderSpeex_32000) then
      fs := f_encoderSpeex_32000.frameSize
    else
      fs := 640;
    //
    dsp.open(fs, c_confRTPcln_mixer_sps, dsp_aec);
    dsp.dsp_denoise := dsp_ns;
    dsp.dsp_agc := dsp_agc;
    dsp.dsp_vad := dsp_vad;
    //
    for d := 0 to c_max_audioStreams_per_room - 1 do begin
      //
      if (nil <> f_dspOut[d]) then
	f_dspOut[d].open(fs, c_confRTPcln_mixer_sps);	// no aec here
    end;
  end;
  //
  f_dspReady := true;
  //
  f_joined := true;
  //
  if (nil <> mixer) then
    mixer.open();
end;

// --  --
procedure TunaConfRTPclient.openDecoders(index: int);
var
  format: unaWaveFormat;
begin
  if (nil <> f_decoderSpeex_8000[index]) 	then f_decoderSpeex_8000[index].open();
  if (nil <> f_decoderSpeex_16000[index]) 	then f_decoderSpeex_16000[index].open();
  if (nil <> f_decoderSpeex_32000[index]) 	then f_decoderSpeex_32000[index].open();
  if (nil <> f_decoderMpeg[index]) 		then f_decoderMpeg[index].open();
  if (nil <> f_decoderCELT[index]) 		then f_decoderCELT[index].open();
  if (nil <> f_decoderG7221[index]) 		then f_decoderG7221[index].open();
  //
  format.formatTag := WAVE_FORMAT_PCM;
  format.formatOriginal.pcmSamplesPerSecond := c_confRTPcln_mixer_sps;
  format.formatOriginal.pcmBitsPerSample := 16;
  format.formatOriginal.pcmNumChannels := 1;
  format.formatChannelMask := KSAUDIO_SPEAKER_MONO;
  //
  applyFormat(@format, sizeof(unaWaveFormat), self, true);
end;

// --  --
procedure TunaConfRTPclient.openEncoders();
begin
  if (nil <> f_encoderSpeex_8000 ) then f_encoderSpeex_8000.open();
  if (nil <> f_encoderSpeex_16000) then f_encoderSpeex_16000.open();
  if (nil <> f_encoderSpeex_32000) then f_encoderSpeex_32000.open();
  if (nil <> f_encoderMpeg)        then f_encoderMpeg.open();
  if (nil <> f_encoderCELT)        then f_encoderCELT.open();
  if (nil <> f_encoderG7221)       then f_encoderG7221.open();
end;

// --  --
function TunaConfRTPclient.roomJoin(const roomName: wString): int;
begin
  f_lastRoomName := roomName;
  //
  result := sendJoin();
end;

// --  --
function TunaConfRTPclient.roomLeave(const roomName: wString): int;
var
  rname: aString;
begin
  rname := utf162utf8(roomName);
  //
  result := sendClnCmd(c_confClnCmd_leave, 0, @rname[1], length(rname));
end;

// --  --
function TunaConfRTPclient.sendClnCmd(const cmd: aString; idata: int32; data: pointer; len: uint): int;
var
  cmdBuf: unaConfRTPcmd;
  sendMe: punaConfRTPcmd;
  releaseMe: bool;
  meSize: int;
begin
  result := -1;
  //
  if (not f_disconnecting and (nil <> trans) and (nil <> trans.rtcp)) then begin
    //
    if (0 < len) then begin
      //
      meSize := sizeof(sendme^) + len;
      sendMe := malloc(meSize);
      releaseMe := true;
      //
      sendMe.r_i_data := idata;
      sendMe.r_dataBufSz := len;
      move(data^, sendMe.r_dataBuf, len);
    end
    else begin
      //
      cmdBuf.r_i_data := idata;
      cmdBuf.r_dataBufSz := 0;
      //
      sendMe := @cmdBuf;
      releaseMe := false;
      meSize := sizeof(unaConfRTPcmd);
    end;
    //
    try
      if (0 = trans.rtcp.sendAPPto(@f_srvAddrRTCP, c_rtcpAPP_subtype_cln, cmd, sendMe, meSize, true)) then begin
	//
	updateBW(false, meSize);
	result := 0;
      end
      else begin
	//
	// fatal problem with system commands? give up
	if (10049 = trans.socketError) then
	  disconnect(-9)
	else
	  disconnect(-8);
      end;
    finally
      if (releaseMe) then
	mrealloc(sendMe);
    end;
  end;
end;

// --  --
function TunaConfRTPclient.sendJoin(): int;
var
  rname: aString;
begin
  rname := utf162utf8(lastRoomName);
  //
  result := sendClnCmd(c_confClnCmd_join, 0, @rname[1], length(rname));
end;

// --  --
procedure TunaConfRTPclient.setDSPbool(index: integer; value: bool);
begin
  f_dspProp[index] := value;
  //
  if ((nil <> dsp) and dsp.active) then begin
    //
    case (index) of

      0: dsp.dsp_denoise := value;
      1: dsp.dsp_agc := value;
      2: dsp.dsp_vad := value;
      3: ; // no reason to change aec here

    end;
  end;
end;

// --  --
procedure TunaConfRTPclient.setEncoding(value: int; sps: int);
var
  wo: bool;
begin
  f_encoding := value;
  f_sps := sps;
  //
  case (value) of

    c_rtp_enc_speex: case (sps) of
      //
      8000: f_payload := c_rtpPTs_conf_speex_8000;
      16000: f_payload := c_rtpPTs_conf_speex_16000;
      32000: f_payload := c_rtpPTs_conf_speex_32000;
    end;

    c_rtp_enc_MPA: begin
      //
      if (nil <> f_encoderMpeg) then begin
	//
	wo := f_encoderMpeg.active;
	try
	  f_encoderMpeg.close();
	  f_encoderMpeg.nSamplesPerSecond := sps;
	finally
	  if (wo) then
	    f_encoderMpeg.open();
	end;
      end;
      //
      case (sps) of

	8000: f_payload := c_rtpPTs_conf_mpeg_8000;
	16000: f_payload := c_rtpPTs_conf_mpeg_16000;
	32000: f_payload := c_rtpPTs_conf_mpeg_32000;
      end;
    end;

    c_rtp_enc_CELT: begin
      //
      if (32000 = sps) then begin
	//
	sps := 24000;
	f_sps := sps;
      end;
      //
      if (nil <> f_encoderCELT) then begin
	//
	wo := f_encoderCELT.active;
	try
	  f_encoderCELT.close();
	finally
	  if (wo) then
	    f_encoderCELT.open(sps, sps div 50);
	end;
      end;
      //
      case (sps) of

	8000: f_payload := c_rtpPTs_conf_CELT_8000;
	16000: f_payload := c_rtpPTs_conf_CELT_16000;
	24000: f_payload := c_rtpPTs_conf_CELT_24000;
      end;
    end;

    c_rtp_enc_G7221: begin
      //
      if (nil <> f_encoderG7221) then begin
	//
	freeAndNil(f_encoderG7221);
	f_encoderG7221 := myG7221Encoder.create(sps, choice(32000 = sps, int(48000), 24000));
	myG7221Encoder(f_encoderG7221).f_cln := self;
	//
	f_encoderG7221.open();
      end;
      //
      case (sps) of

	8000: f_payload := c_rtpPTs_conf_G7221_8000;
	16000: f_payload := c_rtpPTs_conf_G7221_16000;
	32000: f_payload := c_rtpPTs_conf_G7221_32000;
      end;
    end;

    c_rtp_enc_PCMA: case (sps) of
      //
      8000: f_payload := c_rtpPTs_conf_ALaw_8000;
      16000: f_payload := c_rtpPTs_conf_ALaw_16000;
      32000: f_payload := c_rtpPTs_conf_ALaw_32000;
    end;

    c_rtp_enc_PCMU: case (sps) of
      //
      8000: f_payload := c_rtpPTs_conf_uLaw_8000;
      16000: f_payload := c_rtpPTs_conf_uLaw_16000;
      32000: f_payload := c_rtpPTs_conf_uLaw_32000;
    end;

    c_rtp_enc_L16: case (sps) of
      //
      8000: f_payload := c_rtpPTs_conf_PCM_8000;
      16000: f_payload := c_rtpPTs_conf_PCM_16000;
      32000: f_payload := c_rtpPTs_conf_PCM_32000;
    end;

  end;
end;

// --  --
procedure TunaConfRTPclient.setSrvMasterkey(const value: string);
begin
  fillChar(f_srvMasterkey, sizeof(unaConfRTPkey), #0);
  pwHash(value, f_srvMasterkey);
end;

// --  --
procedure TunaConfRTPclient.setSSRC(value: u_int32);
begin
  if (nil <> trans) then
    trans.setNewSSRC(value);
end;

// --  --
procedure TunaConfRTPclient.setURI(const value: string);
var
  crack: unaURICrack;
  scheme: string;
  roomName: wString;
begin
  if (crackURI(value, crack)) then begin
    //
    scheme := crack.r_scheme;	// must be RTP
    //
    makeAddr(crack.r_hostName, int2str(crack.r_port), f_srvAddrRTP);
    f_srvAddrRTCP := f_srvAddrRTP;
    f_srvAddrRTCP.sin_port := swap16u(swap16u(f_srvAddrRTCP.sin_port) + 1);
    f_userName := utf82utf16(aString(urlDecode(crack.r_userName)));
    roomName := utf82utf16(aString(urlDecode(crack.r_path)));
    //
    if (('' <> roomName) and ('/' = roomName[1])) then
      roomName := copy(roomName, 2, maxInt);
    //
    if ('' = trimS(roomName)) then
      roomName := '/';
    //
    f_lastRoomName := roomName;
  end;
  //
  f_URI := value;
end;

// --  --
procedure TunaConfRTPclient.updateBW(isIn: bool; delta: int);
begin
  if (f_idleLock.acquire(false, 10, false {$IFDEF DEBUG }, '.updateBW()' {$ENDIF DEBUG })) then try
    //
    if (isIn) then
      inc(f_bin, delta)
    else
      inc(f_bout, delta);
    //
    if (0 = f_bwTM) then
      f_bwTM := timeMarkU();
    //
    if (2000 < timeElapsed32U(f_bwTM)) then begin
      //
      f_bwIn := f_bin shl 2;
      f_bwOut := f_bout shl 2;
      //
      f_bin := 0;
      f_bout := 0;
      //
      f_bwTM := timeMarkU();
    end;
    //
  finally
    f_idleLock.releaseWO();
  end;
end;


// -- resister components in IDE --
//
procedure Register();
begin
  RegisterComponents(c_VC_reg_RTP_section_name, [
    //
    TunaConfRTPclient
  ]);
end;

end.















