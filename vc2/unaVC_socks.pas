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

	  unaVC_socks.pas - VC 2.5 Pro socket pipe components
	  Voice Communicator components version 2.5 Pro

	----------------------------------------------
	  (c) 2002-2012 Lake of Soft
	  All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 01 Jun 2002

	  modified by:
		Lake, Jun-Dec 2002
		Lake, Jan-Dec 2003
		Lake, Jan-May 2004
		Lake, May-Oct 2005
		Lake, Mar-Dec 2007
		Lake, Jan-Nov 2008
		Lake, Jan-May 2009
		Lake, Feb 2012

	----------------------------------------------
*)

{$I unaDef.inc }

{$IFDEF DEBUG }
  {$DEFINE LOG_UNAVC_SOCKS_INFOS }	// log informational messages
  {$DEFINE LOG_UNAVC_SOCKS_ERRORS }	// log critical errors
  //
  {xx $DEFINE PACKET_DEBUG }
  {xx $DEFINE PACKET_DEBUG2 }
  {xx $DEFINE PACKET_TCP_DELAY_EMULATE }
{$ENDIF DEBUG }

{*
  Contains socket pipes to be used in Delphi/C++Builder IDE.

  IP components:
  @unorderedList(
    @itemSpacing Compact
    @item @link(unavclIPClient IPClient)
    @item @link(unavclIPServer IPServer)
    @item @link(unavclIPBroadcastServer IPBroadcastServer)
    @item @link(unavclIPBroadcastClient IPBroadcastClient)
  )

  @Author Lake
  
	Version 2.5.2008.02 Split from unaVCIDE.pas unit

 	Version 2.5.2012.02 STUN C/S and DNS C
}

unit
  unaVC_socks;

{$IFDEF PACKET_DEBUG }
  {$DEFINE PACKET_DEBUG_OR_DELAY_EMULATE }
{$ENDIF PACKET_DEBUG }
// OR
{$IFDEF PACKET_TCP_DELAY_EMULATE }
  {$DEFINE PACKET_DEBUG_OR_DELAY_EMULATE }
{$ENDIF PACKET_TCP_DELAY_EMULATE }

interface

uses
  Windows, Classes,
  unaTypes, unaClasses,
  MMSystem, WinSock, unaSockets,
{$IFDEF VC_LIC_PUBLIC }
{$ELSE }
  unaSocks_DNS, unaSocks_STUN,
{$ENDIF VC_LIC_PUBLIC }
  unaVC_pipe;


// ---------------------
//  -- IP components --
// ---------------------

const
// Hello command
  cmd_inOutIPPacket_hello	= $01;	
  cmd_inOutIPPacket_bye		= $02;
  cmd_inOutIPPacket_outOfSeats	= $03;
  cmd_inOutIPPacket_needFormat	= $04;
  //
  cmd_inOutIPPacket_formatAudio	= $10;
  cmd_inOutIPPacket_formatVideo	= $11;
  //
  cmd_inOutIPPacket_audio	= $20;
  cmd_inOutIPPacket_video	= $21;
  cmd_inOutIPPacket_text	= $22;
  cmd_inOutIPPacket_userData	= $23;
  //
  cmd_inOutIPPacket_byeIndexed		= $29;
  cmd_inOutIPPacket_audioIndexed    	= $2A;
  cmd_inOutIPPacket_videoIndexed    	= $2B;
  cmd_inOutIPPacket_textIndexed	    	= $2C;
  cmd_inOutIPPacket_userDataIndexed 	= $2D;
  cmd_inOutIPPacket_formatAudioIndexed	= $2E;
  cmd_inOutIPPacket_formatVideoIndexed	= $2F;

  c_umaMaxOutpackets	= 4096;

type
// Pointer to a packet
  punavclInOutIPPacket = ^unavclInOutIPPacket;	
  {*
	Packet record.
  }
  unavclInOutIPPacket = packed record
    //
    case r_command: uint8 of

      0: (
	r_crc16: uint16;
	r_seqNum: uint16;
	r_curLast: uint8;
	r_dataSize: uint16;
	r_data: record end;
      );

      1: (
	r_subCmd: uint16;
	r_align: uint8;
	r_data_noCheck: record end;
      );
  end;


  {*
	Sockets proto. Could be UDP or TCP.
  }
  tunavclProtoType = (unapt_TCP, unapt_UDP);

  {*
	Streaming mode. Could be VC compatible or RAW.
  }
  tunavclStreamingMode = (unasm_VC, unasm_RAW);

  {*
	Result of send operation. OK or fail.
  }
  tunaSendResult = (unasr_OK, unasr_fail);


// OnText event
  tunavclTextDataEvent = procedure (sender: tObject; connId: tConID; const data: string) of object;	
// OnUserData event
  tunavclUserDataEvent = procedure (sender: tObject; connId: tConID; data: pointer; len: uint) of object;	
// OnPacket event
  tunavclPacketEvent = procedure (sender: tObject; connId: tConID; cmd: uint; data: pointer; len: uint) of object;	
// OnSocketEvent event
  tunavclSocketEvent = procedure (sender: tObject; connId: tConID; event: unaSocketEvent; data: pointer; len: uint) of object;	

  {*
	http://lakeofsoft.com/vcx/automatic-byte-order-detection.html for RAW streaming.
	@unorderedList(
	  @itemSpacing Compact
		@item (unasbo_dontCare - byte order not changed)
		@item (unasbo_swap - low and high bytes are always swapped)
		@item (unasbo_autoDetectOnce - byte order is detected once)
		@item (unasbo_autoDetectCont - byte order is detected continuously)
	)
  }
  tunavclStreamByteOrder = (unasbo_dontCare, unasbo_swap, unasbo_autoDetectOnce, unasbo_autoDetectCont);

  {*
	Internal structure for byte order swapping.
  }
  tunavclInOutIpPipeSwapBuf = packed record
    //
    r_swapSubLock: unaObject;//unaInProcessGate;
    r_swapSubBuf: pArray;
    r_swapSubBufSize: uint32;
    r_swapSubBufUsedSize: uint32;
  end;


  {*
	Base abstract class for TCP/IP stream pipes.
  }
  unavclInOutIpPipe = class(unavclInOutPipe)
  private
    f_socksId: tConID;
    f_errorCode: int;
    f_host: string;
    f_port: string;
    f_proto: tunavclProtoType;
    f_bindToIP: string;
    f_bindToPort: string;
    //
    f_localFormat: pointer;
    f_localFormatSize: unsigned;
    f_remoteFormat: pointer;
    f_remoteFormatSize: unsigned;
    //
{$IFDEF PACKET_TCP_DELAY_EMULATE }
    f_windowFillSize: unsigned;
{$ENDIF PACKET_TCP_DELAY_EMULATE }
    f_crcErrors: unsigned;
    f_dupCount: unsigned;
    f_outOfSeq: unsigned;
    //
    f_insideOnPacket: int;
    f_insideOnPacketMustClose: bool;
    //
    //f_packetSendGate: unaInProcessGate;
    f_packetsToSendAcquire: array[0.. c_umaMaxOutpackets - 1] of int;
    f_packetsToSendData: array[0.. c_umaMaxOutpackets - 1] of punavclInOutIPPacket;
    f_packetsToSendSize: array[0.. c_umaMaxOutpackets - 1] of unsigned;
    //
    f_inPacketsCount: int64;
    f_outPacketsCount: int64;
    f_bytesSent: int64;
    f_bytesReceived: int64;
    //
    f_streamingMode: tunavclStreamingMode;
    //
    f_inStreamByteOrder: tunavclStreamByteOrder;
    f_outStreamByteOrder: tunavclStreamByteOrder;
    f_inAutoDetectDone: bool;
    f_outAutoDetectDone: bool;
    f_inAutoDetectMustSwap: bool;
    f_outAutoDetectMustSwap: bool;
    //
    f_swapSubBuf: array[0..1] of tunavclInOutIpPipeSwapBuf;	// 0 - input
    //								// 1 - output
    f_socks: unaSocks;
    //
    f_onTextData: tunavclTextDataEvent;
    f_onUserData: tunavclUserDataEvent;
    f_onPacketEvent: tunavclPacketEvent;
    f_onSocketEvent: tunavclSocketEvent;
    f_onDataSent: tunavclUserDataEvent;
    //
    function getPacketData(len: uint): int;
    //
    function getProto(): uint;
    procedure adjustSocketOption(socket: tSocket; isMainSocket: bool);
    //
    procedure analyzeByteOrder(isInput: bool; data: pointer; len: int; out outLen: int);
    procedure writeIntoSwapBuf(bufIndex: int; data: pointer; len: int);
    {$IFDEF VC25_IOCP }
    function getIsIOCPSocks(): bool;
    procedure setIsIOCPSocks(value: bool);
    {$ENDIF VC25_IOCP }
  protected
    {*
      Sends a packet to remote side.
    }
    function doSendPacket(connId: tConID; cmd: uint; out asynch: bool; data: pointer = nil; len: uint = 0; timeout: tTimeout = 79): tunaSendResult; virtual; abstract;
    {*
      //
    }
    function sendPacketToSocket(connId: tConID; seqNum, cmd: uint; out asynch: bool; data: pointer = nil; len: uint = 0; timeout: tTimeout = 78): tunaSendResult;
    {*
      Fired by underlying socket provider.
      See also handleSocketEvent().
    }
    procedure doOnSocketEvent(sender: tObject; event: unaSocketEvent; id, connId: tConID; data: pointer; len: uint); virtual;
    {*
      Returns active state of the TCP/IP stream.
    }
    function isActive(): bool; override;
    {*
      Should write data into the TCP/IP stream.
    }
    function doWrite(data: pointer; len: uint; provider: pointer = nil): uint; override;
    {*
      You cannot read from a socket.

      Use onDataAvailable event or override the onNewData() method to be notified when new data arrives.
      
    	@return This method always returns 0.
    }
    function doRead(data: pointer; len: uint): uint; override;
    {*
    	@return This method always returns 0.
    }
    function getAvailableDataLen(index: integer): uint; override;
    {*
      Sends goodbye command to all underlying connections.
    }
    procedure sendGoodbye(connId: tConID); virtual; abstract;
    {*
	Sends local format (if specified) to remote side.
    }
    procedure sendFormat(connId: tConID);
    {*
      Opens the TCP/IP stream.
    }
    function doOpen(): bool; override;
    {*
      Closes the TCP/IP stream.
    }
    procedure doClose(); override;
    {*
    }
    function getFormatExchangeData(out data: pointer): uint; override;
    {*
      Triggers when new packet is available for the TCP/IP stream.
    }
    function onNewPacketData(dataType: int; data: pointer; len: uint): bool; virtual;
    function onNewPacket(cmd: uint; data: pointer; len: uint; connId: tConID; worker: uint): bool; virtual;
    procedure onPacketsLost(connId: tConID; lostCount: int; worker: uint); virtual;
    {*
      Initializes the TCP/IP stream socket.
    }
    function initSocksThread(): tConID; virtual; abstract;
    {*
      Handles socket event.
    }
    function handleSocketEvent(event: unaSocketEvent; id, connId: tConID; data: pointer; len: uint): bool; virtual;
    //
    {*
      Since IP components sends and receives format from remote side, we should not bother local consumers,
      as it is done in parent's applyFormat(), unless we had received a remote format
    }
    function applyFormat(data: pointer; len: uint; provider: unavclInOutPipe = nil; restoreActiveState: bool = false): bool; override;
    {*
      Specifies host name (or IP address) for the client TCP/IP socket.
    }
    property host: string read f_host write f_host;
    {*
      Specifies port name/number to bind to when socket is about to be open (either for listening or for connection).
      Default is '0' which means socket will bind to first available port.
    }
    property bindToPort: string read f_bindToPort write f_bindToPort;
  public
    {*
    }
    procedure AfterConstruction(); override;
    procedure BeforeDestruction(); override;
    {*
      Returns client connection object.
      NOTE! Connection's release() method must be called when connection object is no longer needed.
    }
    function getHostAddr(connId: tConID = $FFFFFFFF): pSockAddrIn;
    function getHostInfo(out ip, port: string; connId: tConID = $FFFFFFFF): bool; overload;
    {*
    }
    function getErrorCode(): int;
    {*
      Sends a packet into the IP stream.
    }
    function sendPacket(connId: tConID; cmd: uint; data: pointer = nil; len: uint = 0; timeout: tTimeout = 80): tunaSendResult;
    {*
      Sends a text into the IP stream.
    }
    function sendText(connId: tConID; const data: aString): tunaSendResult;
    {*
      Sends user data into the IP stream.
    }
    function sendData(connId: tConID; data: pointer; len: uint): tunaSendResult;
    {*
      Returns number of packets received.
    }
    property inPacketsCount: int64 read f_inPacketsCount;
    {*
      Returns number of packets sent.
    }
    property outPacketsCount: int64 read f_outPacketsCount;
    {*
    }
    property inPacketsCrcErrors: unsigned read f_crcErrors;
    property inPacketsDupCount: unsigned read f_dupCount;
    property inPacketsOutOfSeq: unsigned read f_outOfSeq;
    //
    property bytesSent: int64 read f_bytesSent;
    property bytesReceived: int64 read f_bytesReceived;
    //
    property socksId: tConID read f_socksId;
    {$IFDEF VC25_IOCP }
    {*
    }
    property useIOCPSocketsModel: bool read getIsIOCPSocks write setIsIOCPSocks;
    {$ENDIF VC25_IOCP }
    {*
    }
    property socks: unaSocks read f_socks;
    //
    property localFormat: pointer read f_localFormat;
    property remoteFormat: pointer read f_remoteFormat;
  published
    //
    {*
      Specifies port number for the client/server TCP/IP socket.
    }
    property port: string read f_port write f_port;
    //
    {*
      Specifies Proto for the TCP/IP socket (TCP or UDP).
    }
    property proto: tunavclProtoType read f_proto write f_proto default unapt_UDP;
    //
    {*
      Specifies IP address to bind to when socket is about to be open (either for listening or for connection).
      Default is '0.0.0.0' which means socket will bind to first available interface.
    }
    property bindTo: string read f_bindToIP write f_bindToIP;
    //
    {*
      Specifies the low-level streaming mode.
    }
    property streamingMode: tunavclStreamingMode read f_streamingMode write f_streamingMode default unasm_VC;
    {*
      Specifies how to analyze the byte order and position in received data when doing PCM raw streaming.
      It could leave bytes as they are, always swap, or autodetect the order. Default is unasbo_dontCare (leave bytes as they are).
      Has meaning for RAW uncompressed streaming only.
    }
    property streamByteOrderInput: tunavclStreamByteOrder read f_inStreamByteOrder write f_inStreamByteOrder default unasbo_dontCare;
    {*
      Specifies how to analyze the byte order and position in data being sent when doing PCM raw streaming.
      It could leave bytes as they are, always swap, or autodetect the order. Default is unasbo_dontCare (leave bytes as they are).
      Has meaning for RAW uncompressed streaming only.
    }
    property streamByteOrderOutput: tunavclStreamByteOrder read f_outStreamByteOrder write f_outStreamByteOrder default unasbo_dontCare;
    //
    {*
      Triggers when text data is available.

      NOTE: VCL is NOT multi-threading safe, and you should avoid using VCL routines and classes in this event.
    }
    property onTextData: tunavclTextDataEvent read f_onTextData write f_onTextData;
    //
    {*
      Triggers when user data is available.

      NOTE: VCL is NOT multi-threading safe, and you should avoid using VCL routines and classes in this event.
    }
    property onUserData: tunavclUserDataEvent read f_onUserData write f_onUserData;
    //
    {*
      Triggers when new packet is available.

      NOTE: VCL is NOT multi-threading safe, and you should avoid using VCL routines and classes in this event.
    }
    property onPacketEvent: tunavclPacketEvent read f_onPacketEvent write f_onPacketEvent;
    //
    {*
      Triggers when socket event occurs.
    }
    property onSocketEvent: tunavclSocketEvent read f_onSocketEvent write f_onSocketEvent;
    //
    {*
      Triggers when new portion of data was sent to remote host.
    }
    property onDataSent: tunavclUserDataEvent read f_onDataSent write f_onDataSent;
    //
    property isFormatProvider;
    property onDataAvailable;
    property onFormatChangeAfter;
    property onFormatChangeBefore;
  end;


  //
  tunavclConnectEvent = procedure (sender: tObject; connId: tConID; connected: bool) of object;


  //
  // -- unavclIPClient --
  //
  {*
    IP Client: connects to remote server, sends and receives audio stream over TCP/IP network.

    @bold(Usage): set host, proto and port properties to specify the remote host.
    Set active to true or call the open() method to initiate the connection.

    @bold(Example): refer to vcTalkNow demo, with ip_client it is possible
    to send compressed audio stream over network and receive audio stream from
    remote server for playback.
  }
  unavclIPClient = class(unavclInOutIpPipe)
  private
    f_clientPacketStack: unaThread;	// client packet processor
    f_connId: tConID;			// client connection Id
    //
    f_isConnected: bool;	// client is connected
    //
    f_onClientConnect: tunavclConnectEvent;
    f_onClientDisconnect: tunavclConnectEvent;
    //
    f_pingMark: uint64;
    f_pingInterval: uint32;
  protected
    {*
      Writes data into the TCP/IP stream to be sent to server.
    }
    function doWrite(data: pointer; len: uint; provider: pointer = nil): uint; override;
    {*
      Sends a packet to server.
    }
    function doSendPacket(connId: tConID; cmd: uint; out asynch: bool; data: pointer = nil; len: uint = 0; timeout: tTimeout = 81): tunaSendResult; override;
    {*
      Sends goodbye packet to the server.
    }
    procedure sendGoodbye(connId: tConID); override;
    {*
    }
    function initSocksThread(): tConID; override;
    {*
    }
    function handleSocketEvent(event: unaSocketEvent; id, connId: tConID; data: pointer; len: uint): bool; override;
    {*
    }
    function onNewPacket(cmd: uint; data: pointer; len: uint; connId: tConID; worker: uint): bool; override;
    {*
      Returns active state of IP Client.
    }
    function isActive(): bool; override;
  public
    procedure AfterConstruction(); override;
    procedure BeforeDestruction(); override;
    //
    {*
      Client socket connection Id.
    }
    property clientConnId: tConID read f_connId;
    {*
      Returns true if client socket is connected to remote host
    }
    property isConnected: bool read f_isConnected;
  published
    {*
      Local port number client should bind to. 0 means client will let system to select any free port.
    }
    property bindToPort;
    {*
      Remote host DNS name/IP address to connect to.
    }
    property host;
    {*
      Triggers when client has been connected to the server.
      
	NOTE: VCL is NOT multi-threading safe, and you should avoid using VCL routines and classes in this event.
    }
    property onClientConnect: tunavclConnectEvent read f_onClientConnect write f_onClientConnect;
    {*
      Triggers when client has been disconnected from the server.

      NOTE: VCL is NOT multi-threading safe, and you should avoid using VCL routines and classes in this event.
    }
    property onClientDisconnect: tunavclConnectEvent read f_onClientDisconnect write f_onClientDisconnect;
    {*
	Specifies the inteval in milliseconds the client should send a dummy "ping" packet to the server.
	Use this with UDP client only which do not send data to server, so server will not disconnect
	the client due to timeout.
	Default value is 0, means ping is disabled.
    }
    property pingInterval: uint32 read f_pingInterval write f_pingInterval default 0;
  end;


  //
  // -- conference mode for IPServer --
  //
  unaIpServerConferenceMode = (
			       uipscm_oneToMany		// vc25pro
			       // more to come
			      );

  // --  --
  tunavclAcceptClient = procedure (sender: tObject; connId: tConID; var accept: bool) of object;

{$IFDEF VCX_DEMO }
  {$DEFINE VCX_DEMO_LIMIT_CLIENTS 	}
  {$DEFINE VCX_DEMO_LIMIT_DATA 		}
  {x $DEFINE UNA_NO_THREAD_PRIORITY 	}
{$ENDIF VCX_DEMO }

const

{$IFDEF VCX_DEMO_LIMIT_CLIENTS }

    unavcide_maxDemoClients = 100;

{$ENDIF VCX_DEMO_LIMIT_CLIENTS }

  // client options for IP server
// accept inbound data from this client
  c_unaIPServer_co_inbound	= $00000001;	
// send outbound data to this client
  c_unaIPServer_co_outbound	= $00000002;	
  //
// default flags (both inbound and outbound are enabled)
  c_unaIPServer_co_default	= c_unaIPServer_co_inbound or c_unaIPServer_co_outbound;	
  c_unaIPServer_co_invalid	= $80000000;

type
  //
  // -- unavclIPServer --
  //
  {*
    IP Server: initiates listening socket for clients to connect to.
    Receives and sends audio stream to/from client.

    @bold(Usage): set proto and port properties to specify the socket parameters.
    Set active to true or call the open() method to initiate the server.

    @bold(Example): refer to vcTalkNow demo, with ip_server it is possible
    to accept client connections, receive compressed audio stream and send
    audio stream over network.
  }
  unavclIPServer = class(unavclInOutIpPipe)
  private
    f_confMode: unaIpServerConferenceMode;
{$IFDEF VCX_DEMO_LIMIT_CLIENTS }
    f_clients: array[0..unavcide_maxDemoClients - 1] of unaThread;
    f_clientCount: unsigned;
    f_clientsLock: unaObject;
{$ELSE }
    f_clients: unaIdList;	// stack of connected clients
{$ENDIF VCX_DEMO_LIMIT_CLIENTS }
    f_psEnabled: bool;
    f_psMasterThread: unaThread;
    f_deadSockets: unaList;
    //
    f_maxClients: int;
    f_udpTimeout: tTimeout;
    f_tryingToRemoveClient: bool;
    //
    f_onAcceptClient: tunavclAcceptClient;
    f_onServerNewClient: tunavclConnectEvent;
    f_onServerClientDisconnect: tunavclConnectEvent;
    //
    function addNewClient(connId: tConID): bool;
    procedure removeClient(connId: tConID);
    //
    function getClientCount(): unsigned;
    procedure setMaxClients(value: int);
    function getPSbyConnId(connId: tConID): unaThread;
    //
    function lockClients(allowEmpty: bool = false; timeout: tTimeout = 102): bool;
    procedure unlockClients();
  protected
    {*
      Writes data into the TCP/IP stream to be sent to client(s).
    }
    function doWrite(data: pointer; len: uint; provider: pointer = nil): uint; override;
    {*
      Closes the IP server.
    }
    procedure doClose(); override;
    {*
      Sends a packet to specified client.
    }
    function doSendPacket(connId: tConID; cmd: uint; out asynch: bool; data: pointer = nil; len: uint = 0; timeout: tTimeout = 82): tunaSendResult; override;
    {*
      Sends goodbye command to all active clients.
    }
    procedure sendGoodbye(connId: tConID); override;
    {*
    	Initializates sockets thread to be used with server.
    }
    function initSocksThread(): tConID; override;
    {*
	Handles specific events reveived from server component.
    }
    function handleSocketEvent(event: unaSocketEvent; id, connId: tConID; data: pointer; len: uint): bool; override;
    {*
	Handles "hello" and "bye" commands.
    }
    function onNewPacket(cmd: uint; data: pointer; len: uint; connId: tConID; worker: uint): bool; override;
    {*
	Fires onAcceptClient event handler (if assigned).
    }
    procedure doAcceptClient(connId: tConID; var accept: bool); virtual;
    {*
	Fires onServerNewClient or onServerClientDisconnect event handlers (if assigned).
    }
    procedure doServerClientConnection(connId: tConID; isConnected: bool); virtual;
    {*
	Marks specified connection as "dead", so server will no longer attempt to communicate over it.

	@param connId Connection to be marked as "dead".
    }
    procedure addDeadSocket(connId: tConID);
  public
    {*
	Initializates server component.
    }
    procedure AfterConstruction(); override;
    {*
	Destroys internal objects.
    }
    procedure BeforeDestruction(); override;
    //
    {*
      Returns connId for client connection with given index. 

      @param clientIndex Index of client connection (from 0 to clientCount - 1).
    }
    function getClientConnId(clientIndex: int): tConID;
    {*
      Sets new flags for a client.

      @param clientIndex Index of client connection (from 0 to clientCount - 1).
    }
    procedure setClientOptions(clientIndex: int; options: uint = c_unaIPServer_co_default);
    {*
      Returns flags assigned for a client.

      @param clientIndex Index of client connection (from 0 to clientCount - 1).
    }
    function getClientOptions(clientIndex: int): uint;
    {*
      Number of clients currently connected to server.
    }
    property clientCount: unsigned read getClientCount;
    {*
      Client options.

      @param clientIndex Index of client connection (from 0 to clientCount - 1).
    }
    property clientOptions[clientIndex: int]: uint read getClientOptions write setClientOptions;
    {*
    	Enable internal thread for packets' processing. Default is False.
    }
    property packetStackThreadEnabled: bool read f_psEnabled write f_psEnabled;
  published
    {*
      Triggers when new client is connected to the server.

      NOTE: VCL is NOT multi-threading safe, and you should avoid using VCL routines and classes in this event.
    }
    property onServerNewClient: tunavclConnectEvent read f_onServerNewClient write f_onServerNewClient;
    {*
      Triggers when client is disconnected from the server.

      NOTE: VCL is NOT multi-threading safe, and you should avoid using VCL routines and classes in this event.
    }
    property onServerClientDisconnect: tunavclConnectEvent read f_onServerClientDisconnect write f_onServerClientDisconnect;
    {*
      IP server is usually a format provider - so this property value was changed to be true by default.
    }
    property isFormatProvider default true;
    {*
      Conference mode (not used).
    }
    property confMode: unaIpServerConferenceMode read f_confMode write f_confMode default uipscm_oneToMany;	// default is old peer-to-peer mode
    {*
      Max. number of clients allowed. Specify -1 for unlimited number.
    }
    property maxClients: int read f_maxClients write setMaxClients default 1;
    {*
      Timeout for clients "connected" to UDP server. 0 means no timeout.
    }
    property udpTimeout: tTimeout read f_udpTimeout write f_udpTimeout default c_defUdpConnTimeout;
    {*
      Fired when new client is connected. Leave accept true for client to be connected.
    }
    property onAcceptClient: tunavclAcceptClient read f_onAcceptClient write f_onAcceptClient;
  end;


// ======= BROADCAST ======

const
  // -- union fields --
  unavcl_union01_channelMedia_audio		= $0;
  unavcl_union01_channelMedia_video		= $1;
  unavcl_union01_channelMedia_newChunkFlag	= $2;
  //
  unavcl_union01_channelMedia_mask		= $1;
  unavcl_union01_channelMedia_shift		= 0;

  unavcl_union01_channelFormatIndex_mask	= $3;
  unavcl_union01_channelFormatIndex_shift	= 2;

  unavcl_union01_channelSeqNum_mask		= $F;
  unavcl_union01_channelSeqNum_shift		= 4;


  // -- selector fields --
  unavcl_packet_selector00_format	= $00;
  unavcl_packet_selector01_data		= $01;
  unavcl_packet_selector10_sync		= $02;
  unavcl_packet_selector11_custom	= $03;
  unavcl_packet_selector_mask		= $03;
  unavcl_packet_selector_shift		= 6;

  unavcl_packet_selector00_formatIndex_mask	= $3;
  unavcl_packet_selector00_formatIndex_shift	= 0;
  unavcl_packet_selector00_formatReserved_mask	= $7;
  unavcl_packet_selector00_formatReserved_shift	= 2;
  unavcl_packet_selector00_formatChanges_mask	= $1;
  unavcl_packet_selector00_formatChanges_shift	= 5;

  unavcl_packet_selector01_high6bitsSize_mask	= $3F;
  unavcl_packet_selector01_high6bitsSize_shift	= 0;

  unavcl_packet_selector10_high6bitsSync_mask	= $3F;
  unavcl_packet_selector10_high6bitsSync_shift	= 0;

  unavcl_packet_selector11_customValue_res000	= $0;
  unavcl_packet_selector11_customValue_text	= $1;
  unavcl_packet_selector11_customValue_videoFormat = $2;
  unavcl_packet_selector11_customValue_res011	= $3;
  unavcl_packet_selector11_customValue_res100	= $4;
  unavcl_packet_selector11_customValue_res101	= $5;
  unavcl_packet_selector11_customValue_res110	= $6;
  unavcl_packet_selector11_customValue_res111	= $7;

  unavcl_packet_selector11_customValue_mask	= $1F;
  unavcl_packet_selector11_customValue_shift	= 0;

  unavcl_packet_selector11_customReserved_mask	= $1;
  unavcl_packet_selector11_customReserved_shift	= 5;

  //
  unavcl_defaultBroadcastPort	= 17380; 

type

  //
  // -- unavclIPBroadcastPacketUnion --
  //
  {*
    Broadcast packet format.
    
    NOTE: If you add something here, do not forget to change the calcPacketRawSize() routine!
  }
  punavclIPBroadcastPacketUnion = ^unavclIPBroadcastPacketUnion;
  unavclIPBroadcastPacketUnion = packed record
    case byte of
      0: (	// stream format
	r_00_formatTag: uint16;
	r_00_samplingRate: uint16;
	r_00_numBits: byte;
	r_00_numChannels: byte;
	 );
      1: (	// stream data
	r_01_lowSize: byte;
	r_01_streamChannel: byte;	{ [xxxx][xx][x][x] :: [seq#][format index][cb][media]
					      |   |  |  |
					      |   |  |  ---- 0 = audio channel
					      |   |  |       1 = video channel
					      |   |  |
					      |   |  ----- 0 = chunk continued
					      |   |        1 = new chunk
					      |   |
					      |   ------ 00 = format index #0
					      |          01 = format index #1
					      |          10 = format index #2
					      |          11 = format index #3
					      |
					      -------- 0000 = seq# 00
						       ...
						       1111 = seq# 15
					}
	r_01_data: record end;
	 );
      2: (	// stream sync
	r_10_lowSync: uint16;
	 );
      3: (	// custom packet
	r_11_customSize: uint16;
	r_11_data: record end;
	 );
  end;


  //
  // -- unavclIPBroadcastPacketSelector --
  //
  punavclIPBroadcastPacketSelector = ^unavclIPBroadcastPacketSelector;
  unavclIPBroadcastPacketSelector = packed record
    r_crc8: byte;
    r_selector: byte;	{
			    [xx] [xxxxxx]
			    |        |
			    |        |
			    -- 00 = audio stream format
			    |        |
			    |        --[x][xxx][xx] :: changes :: reserved :: format index
			    |        |  |    |   |
			    |        |  |    |   --- 00 = format index #0
			    |        |  |    |       01 = format index #1
			    |        |  |    |       10 = format index #2
			    |        |  |    |       11 = format index #3
			    |        |  |    |
			    |        |  |    ------ 000 = reserved
			    |        |  |           ...
			    |        |  |           111 = reserved
			    |        |  |
			    |        |  ------------- 0 = no changes since last sent
			    |        |                1 = some changes since last sent
			    |        |
			    -- 01 = stream data
			    |        |
			    |        --[xxxxxx] :: high-order 6 bits of packet size
			    |        |       |
			    |        |       -- 000000..111111
			    |        |
			    |        |
			    -- 10 = stream sync
			    |        |
			    |        --[xxxxxx] :: high-order 6 bits of packet sync
			    |        |       |
			    |        |       -- 000000..111111
			    |        |
			    -- 11 = custom packet
				     |
				     --[x][xxxxx] :: reserved :: custom packet sub-code
					|      |
					|      -- 00000 = reserved
					|         00001 = text data
					|	  00010 = video format
					|         00011 = reserved
					|	  ...
					|	  00111 = reserved
					|	  01000 = user-defined
					|	  ...
					|	  11111 = user-defined
					|
					------------- 0 = reserved
						      1 = reserved
			}
    r_union: unavclIPBroadcastPacketUnion;
  end;


  //
  // -- unavclIPBroadcastPipe --
  //

  {*
    Implements basic broadcast pipe.
  }
  unavclIPBroadcastPipe = class(unavclInOutPipe)
  private
    f_socks: unaSocks;		// to make sure unaWSA was created
    f_socket: unaUdpSocket;
    f_addr: sockaddr_in;
    f_isActive: bool;
    //
    f_bindToIP: string;
    //
    f_waveFormatTag: unsigned;
    f_waveSamplesPerSec: unsigned;
    f_waveNumBits: unsigned;
    f_waveNumChannels: unsigned;
    f_waveFormatChanged: bool;
    //
    f_channelSeqNum: unsigned;
    f_packet: punavclIPBroadcastPacketSelector;
    f_packetSize: unsigned;
    //
    procedure setwaveParam(index: integer; value: unsigned);
    procedure setPort(const value: string);
    function getPort: string;
    // -- packet --
    function allocPacket(selector: byte; dataLen: uint = 0): uint;
    function calcPacketRawSize(dataLen: uint = 0): uint; overload;
    function calcPacketRawSize(selector: byte; dataLen: uint): uint; overload;
  protected
    {*
      Reads data from pipe.
    }
    function doRead(data: pointer; len: uint): uint; override;
    {*
      Returns 0.
    }
    function getAvailableDataLen(index: integer): uint; override;
    {*
      Opens a pipe.
    }
    function doOpen(): bool; override;
    {*
      Closes a broadcast pipe.
    }
    procedure doClose(); override;
    {*
      Returns active state of a pipe.
    }
    function isActive(): bool; override;
    {*
      Returns format exchange packet.
    }
    function getFormatExchangeData(out data: pointer): uint; override;
    {*
      Applies format on a pipe.
    }
    function applyFormat(data: pointer; len: uint; provider: unavclInOutPipe = nil; restoreActiveState: bool = false): bool; override;
    {*
      Binds socket on a port (client) or broadcast address (server).
    }
    procedure bindSocket(); virtual;
    {*
      Sets the port for broadcast socket.
    }
    procedure doSetPort(const value: string); virtual;
  public
    {*
      Creates a broadcast pipe.
    }
    procedure AfterConstruction(); override;
    {*
      Destroys broadcast pipe.
    }
    procedure BeforeDestruction(); override;
    {*
	Sets the specific broadcast address.
    }
    procedure setBroadcastAddr(const addrH: TIPv4H = TIPv4H(INADDR_BROADCAST));
    //
    {*
      Specifies format tag of pipe audio stream.
    }
    property waveFormatTag: unsigned index 0 read f_waveFormatTag write setwaveParam default WAVE_FORMAT_PCM;
    {*
      Specifies samples per second for pipe audio stream.
    }
    property waveSamplesPerSec: unsigned index 1 read f_waveSamplesPerSec write setwaveParam default 44100;
    {*
      Specifies number of channels for pipe audio stream.
    }
    property waveNumChannels: unsigned index 2 read f_waveNumChannels write setwaveParam default 2;
    {*
      Specifies number of bits for pipe audio stream.
    }
    property waveNumBits: unsigned index 3 read f_waveNumBits write setwaveParam default 16;
  published
    {*
      Specifies port number for broadcast socket.
    }
    property port: string read getPort write setPort;
    {*
      Specifies IP address the socket should bind to.
      Default '0.0.0.0' means socket should bind to first available interface.
    }
    property bindTo: string read f_bindToIP write f_bindToIP;
  end;


  //
  // -- unavclIPBroadcastServer --
  //
  {*
    Broadcasts audio stream over LAN using the broadcast destination
    IP address and UDP sockets.

    @bold(Usage): set the port property to specify the port number to broadcast to.
    Calling the open() method or setting the active property
    to True will initiate broadcasting.

    @bold(Example): refer to vcBroadcast demo for details.
  }
  unavclIPBroadcastServer = class(unavclIPBroadcastPipe)
  private
    f_formatCountdown: unsigned;
    f_formatIndexCountdown: unsigned;
    f_packetsSent: unsigned;
    //
    function sendRawData(data: pointer; len: uint): tunaSendResult;
    function sendPacket(rawSize: uint = 0; len: uint = 0; calcCRC: bool = true): tunaSendResult;
  protected
    procedure bindSocket(); override;
    {*
      Writes data into broadcast stream.
    }
    function doWrite(data: pointer; len: uint; provider: pointer = nil): uint; override;
  public
    function doOpen(): bool; override;
    {*
      Sends a specified media packet. Only audio packets are currently supported.
      Returns 0 if data was sent successfully, or socket error otherwise.
    }
    function sendStreamData(channelMedia: byte; data: pointer = nil; len: uint = 0; isNewChunk: bool = true): tunaSendResult;
    {*
      Sends an audio stream format to client(s).
    }
    function sendAudioStreamFormat(): tunaSendResult;
    {*
      Sends stream synchronization (not implemented yet).
    }
    function sendStreamSync(sync: uint): tunaSendResult;
    {*
      Sends custom data over a pipe.
    }
    function sendCustomData(customType: byte; data: pointer; len: uint): tunaSendResult;
    //
    {*
      Returns number of total packets being sent.
    }
    property packetsSent: unsigned read f_packetsSent;
  end;


  //
  // -- unavclIPBroadcastClient --
  //

  {*
    Receives audio stream being broadcasted by server component over LAN.

    @bold(Usage): set the port property to specify the port number to
    listen at for stream being broadcasted.
    Calling the open() method or setting the active property to true
    will initiate listening.
    As soon as broadcast packets will be received, this component can produce
    output stream to be played back.
    No data will be send back to server.

    @bold(Example): refer to vcBroadcast demo for details.
  }
  unavclIPBroadcastClient = class(unavclIPBroadcastPipe)
  private
    f_thread: unaThread;
    f_formatIndex: unsigned;
    f_packetsReceived: unsigned;
    f_packetsLost: unsigned;
    f_remoteHost: TIPv4H;
    f_remotePort: uint16;
    //
    f_subData: unaMemoryStream;
    f_subDataBuf: pointer;
    f_subDataBufSize: uint;
    //
    f_chunkSize: uint;
    //
    procedure onNewBroadPacket(data: pointer; size: uint; const addr: WinSock.sockAddr_In);
  protected
    procedure doClose(); override;
    function doOpen(): bool; override;
    function doWrite(data: pointer; len: uint; provider: pointer = nil): uint; override;
    //
    procedure bindSocket(); override;
    procedure doSetPort(const value: string); override;
  public
    procedure AfterConstruction(); override;
    procedure BeforeDestruction(); override;
    //
    {*
        Returns total number of packets being lost.
    }
    property packetsLost: unsigned read f_packetsLost;
    {*
	Returns number of received packets.
    }
    property packetsReceived: unsigned read f_packetsReceived;
    {*
	Remote host.
    }
    property remoteHost: TIPv4H read f_remoteHost;
    {*
	Remote port.
    }
    property remotePort: uint16 read f_remotePort;
  published
    {*
	Broadcast client is usually a format provider - so this property value was changed to be true by default.
    }
    property isFormatProvider default true;
  end;


{$IFDEF VC_LIC_PUBLIC }
{$ELSE }

// ==== STUN ====

  {*
	STUN Base
  }
  unavclSTUNBase = class(unavclInOutPipeImpl)
  private
    f_port: string;
    f_proto: tunavclProtoType;
    f_bind2ip: string;
    f_stunProto: int;
    //
    f_agent: unaSTUNagent;
    //
    procedure setProto(value: tunavclProtoType);
  protected
    function createAgent(): bool; virtual; abstract;
    //
    function doOpen(): bool; override;
    procedure doClose(); override;
    function isActive(): bool; override;
  public
    procedure AfterConstruction(); override;
  published
    {*
	Client: Remote STUN Server port
	Server: Local port to listen on
    }
    property port: string read f_port write f_port;
    {*
	Transport to use: UDP or TCP
    }
    property proto: tunavclProtoType read f_proto write setProto default unapt_UDP;
    {*
	Bind client or server to this local IP. Default is 0.0.0.0
    }
    property bind2ip: string read f_bind2ip write f_bind2ip;
  end;

  {*
	@param sender object instance
	@param error error code, or 200 if no error
	@param
  }
  unaSTUNCLientResponseEvent = procedure(sender: tObject; error: int32; mappedIP: uint32; mappedPort, boundPort: uint16) of object;

  {*
	STUN Client
  }
  unavclSTUNClient = class(unavclSTUNBase)
  private
    f_host: string;
    f_useDNSSRV: boolean;
    //
    f_lastResponse: unaSTUNClient_req;
    //
    f_onResponse: unaSTUNCLientResponseEvent;
    f_bind2port: string;
    //
    function getClient(): unaSTUNClient; {$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
  protected
    function createAgent(): bool; override;
    //
    {*
	Called from context of internal thread when STUN response is received
    }
    procedure doOnResponse(r: unaSTUNClient_req; error: int; mappedIP: uint32; mappedPort, boundPort: uint16); virtual;
  public
    procedure AfterConstruction(); override;
    {*
	Sends a request to remote server.

	@param method method to use, default is C_STUN_MSGTYPE_BINDING
	@param attrs pointer to additional attributes to send
	@param attrsLen size of additional attributes

	@return internal index of request ( > 0), or -1 in case of some error
    }
    function req(method: int = C_STUN_MSGTYPE_BINDING; attrs: pointer = nil; attrsLen: int = 0): int;
    //
    property client: unaSTUNClient read getClient;
  published
    {*
	Remote STUN Server address
    }
    property host: string read f_host write f_host;
    {*
	Bind client to this port
    }
    property bind2port: string read f_bind2port write f_bind2port;
    {*
	User DNS SRV query to locate server(s)
    }
    property useDNSSRV: boolean read f_useDNSSRV write f_useDNSSRV default true;
    {*
	Response received by onResponse event.
	Valid only in context of onResponse() event handler.
    }
    property lastResponse: unaSTUNClient_req read f_lastResponse;
    {*
	Called from context of internal thread when STUN response is received
    }
    property onResponse: unaSTUNCLientResponseEvent read f_onResponse write f_onResponse;
  end;


  {*
	STUN Server
  }
  unavclSTUNServer = class(unavclSTUNBase)
  private
    f_onResponse: unaSTUNServerOnResponse;
    //
    function getServer(): unaSTUNServer;{$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
    function getNumReq(): int64; {$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
    function getSocketError(): int;{$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
    //
    procedure setOnResponse(value: unaSTUNServerOnResponse);
  protected
    function createAgent(): bool; override;
  public
    property server: unaSTUNServer read getServer;
    {*
	Number of requsts handled by server
    }
    property numRequests: int64 read getNumReq;
    {*
	Fatal socket error or 0 if no error
    }
    property socketError: int read getSocketError;
  published
    {*
	OnReponse event.
    }
    property onResponse: unaSTUNServerOnResponse read f_onResponse write setOnResponse;
  end;

// === DNS ====

  {*
	DNS Client
  }
  unavclDNSClient = class(unavclInOutPipeImpl)
  private
    f_cln: unaDNSClient;
    //
    f_lastAnswer: unaDNSQuery;
    f_onAnswer: TNotifyEvent;
  protected
    function doOpen(): bool; override;
    procedure doClose(); override;
    function isActive(): bool; override;
    //
    {*
    	Called from context of low-level DNS client thread.
    }
    procedure doOnAnswer(query: unaDNSQuery); virtual;
  public
    procedure AfterConstruction(); override;
    procedure BeforeDestruction(); override;
    {*
	Returns list of DNS servers assigned by TCP/IP configuration.
    }
    function getDNSServersList(): string;
    {*
    	Low-level component, use it to get access to full functionality of DNS client.
    }
    property client: unaDNSClient read f_cln;
    {*
	Answer returned by server.

	NOTE: Access this property from OnAnswer event handler only!
    }
    property answer: unaDNSQuery read f_lastAnswer;
  published
    {*
	Fired when new answer was returned by server.
    }
    property onAnswer: TNotifyEvent read f_onAnswer write f_onAnswer;
  end;

{$ENDIF VC_LIC_PUBLIC }


implementation


uses
  unaUtils, unaWave
{$IFDEF VCX_DEMO }
  , unaBaseXcode
{$ENDIF VCX_DEMO }
  ;


type
  //
  // -- unavclIpPacketsStack --
  //
  unavclIpPacketsStack = class(unaThread)
  private
    f_connId: tConID;	// master should know the connId
    f_formatSent: bool;
    f_formatReceived: bool;
    //
    f_expectedSeqNum: int;
    f_subPackets: array[$00..$7F] of punavclInOutIPPacket;
    f_subPacketsCount: unsigned;
    //
    f_lastSubIndex: unsigned;
    f_lastSubIndexReceived: bool;
    f_packetDataBuf: pointer;
    f_packetDataBufSize: uint;
    //
    f_seqNum: int;
    //
{$IFDEF VCX_DEMO_LIMIT_DATA }
    f_totalData: int64;
{$ENDIF VCX_DEMO_LIMIT_DATA }
    //
{$IFDEF PACKET_DEBUG }
    f_deltaMark1: int64;
    f_deltaMark2: int64;
{$ENDIF}
    //
    f_packets: unaRecordList;
    f_master: unavclInOutIpPipe;
    f_savedDataStream: unaMemoryStream;
    // server clients only
    f_clientOptions: uint;
    //
    procedure cleanupSubPackets();
    function parseSocketData(data: pArray; len: uint): bool;
    function doSendPacket(cmd: uint; out asynch: bool; data: pointer = nil; len: uint = 0; timeout: tTimeout = 83): tunaSendResult;
  protected
    function execute(globalIndex: unsigned): int; override;
    //
    procedure processPackets(globalIndex: unsigned);
    //
    procedure startIn(); override;
    //
    function psNewSocketData(data: pointer; len: uint; worker: uint): bool;
  public
    constructor create(master: unavclInOutIpPipe; connId: tConID);
    procedure AfterConstruction(); override;
    procedure BeforeDestruction(); override;
    {*
      //
    }
    function getNextSeqNum(): unsigned;
    //
    function psAddPacket(packet: pointer): bool;
  end;


{ unaPacketsStack }

// --  --
procedure unavclIpPacketsStack.afterConstruction();
begin
  inherited;
  //
  f_packets := unaRecordList.create();
  f_savedDataStream := unaMemoryStream.create();
  f_packetDataBuf := nil;
  //
  f_clientOptions := c_unaIPServer_co_default;
end;

// --  --
procedure unavclIpPacketsStack.beforeDestruction();
begin
  // try to make sure no one else is locking us
  if (acquire(false, 1000)) then
    releaseWO();
  //
  inherited;
  //
  try
    cleanupSubPackets();
  except
  end;  
  //
  mrealloc(f_packetDataBuf);
  freeAndNil(f_packets);
  freeAndNil(f_savedDataStream);
end;

// --  --
procedure unavclIpPacketsStack.cleanupSubPackets();
var
  i: uint;
begin
  // cleanup the whole f_subPackets array
  for i := low(f_subPackets) to high(f_subPackets) do begin
    //
    mrealloc(f_subPackets[i]);
    f_subPackets[i] := nil;
  end;
  //
  f_subPacketsCount := 0;
  f_lastSubIndexReceived := false;
end;

// --  --
constructor unavclIpPacketsStack.create(master: unavclInOutIpPipe; connId: tConID);
begin
  f_master := master;
  f_connId := connId;
  //
  inherited create(false, THREAD_PRIORITY_TIME_CRITICAL);
end;

// --  --
function unavclIpPacketsStack.doSendPacket(cmd: uint; out asynch: bool; data: pointer; len: uint; timeout: tTimeout): tunaSendResult;
begin
  result := unasr_OK;
  //
  case (cmd) of
    //
    cmd_inOutIPPacket_audio,
    cmd_inOutIPPacket_video: begin
      //
      // check if we can send media data
      if (not f_formatSent) then begin
	//
	if (unasm_RAW <> f_master.streamingMode) then	// in RAW mode we should always send packets
	  result := unasr_fail;	// do not send now
	//
{$IFDEF LOG_UNAVC_SOCKS_INFOS }
	logMessage(className + '.doSendPacket() - format was not sent, so we did not send audio packet too.');
{$ENDIF LOG_UNAVC_SOCKS_INFOS }
      end
      else begin
	// check if we can send data to this client
	if (0 = (f_clientOptions and c_unaIPServer_co_outbound)) then begin
	  //
	  result := unasr_fail;		// do not send to this client
{$IFDEF LOG_UNAVC_SOCKS_INFOS }
	  //logMessage(className + '.doSendPacket() - packet was not sent due to client options restriction.');
{$ENDIF LOG_UNAVC_SOCKS_INFOS }
	end;
      end;
    end;

    else
      if (unasm_VC <> f_master.streamingMode) then begin
	//
	// there is no reason to send non-media VC packets in RAW mode, since all packets will be treated as raw data
	result := unasr_fail;
      end;

  end;
  //
  if (unasr_OK = result) then
    result := f_master.sendPacketToSocket(f_connId, getNextSeqNum(), cmd, asynch, data, len, timeout);
  //
  if (not f_formatSent) then begin
    //
    case (f_master.streamingMode) of

      unasm_RAW: begin
	// assume we have sent the format (even if result is not oK)
	f_formatSent := true;
      end;

      unasm_VC: begin
	//
	// check if we just had sent the format
	case (cmd) of

	  cmd_inOutIPPacket_formatAudio,
	  cmd_inOutIPPacket_formatVideo: begin
	    //
	    f_formatSent := (unasr_OK = result);
	  end;

	end;
      end;

    end;
    //
  end;
  //
end;

// --  --
function unavclIpPacketsStack.execute(globalIndex: unsigned): int;
begin
  setDefaultStopTimeout(500);	// this thread could be stopped from inside execute()
  //
  while (not shouldStop) do begin
    //
    try
      //
      if (f_packets.waitForData()) then
	processPackets(globalIndex);
      //
      if (not unaThread.shouldStopThread(globalIndex)) then begin
	//
	if (0 < f_packets.count) then
	  f_packets.checkDataEvent();
      end
      else
	break;
      //
    except
      // ignore exceptions
    end;
    //
  end;
  //
  result := 0;
end;

// --  --
function unavclIpPacketsStack.getNextSeqNum(): unsigned;
begin
  result := unsigned(InterlockedExchangeAdd(f_seqNum, 1));
  if ($7FFFFFFF = result) then begin
    //
    f_seqNum := 0;
    result := 0;
  end;
end;

// --  --
function unavclIpPacketsStack.parseSocketData(data: pArray; len: uint): bool;
var
  packet: punavclInOutIPPacket;
  crc32u: uint;
  curIndex: unsigned;
  i: unsigned;
  totalDataSize: unsigned;
  packetData: pointer;
{$IFDEF PACKET_DEBUG}
  delta: int64;
{$ENDIF}
  dataOffset: unsigned;
  packetSize: unsigned;
  newData: pointer;
begin
  if ((nil <> data)) then begin
    //
    packetSize := f_savedDataStream.getAvailableSize();
    if (0 < packetSize) then begin
      //
      inc(packetSize, len);
      newData := malloc(packetSize);
      try
	f_savedDataStream.write(data, len);
	f_savedDataStream.read(newData, int(packetSize));
	//
	// recurse with new data buffer
	result := parseSocketData(newData, packetSize);
      finally
	mrealloc(newData);
      end;
      //
      exit;
    end;
    //
    dataOffset := 0;
    while (sizeOf(packet^) <= len) do begin
      //
      packet := punavclInOutIPPacket(@data[dataOffset]);
      packetSize := sizeOf(packet^) + packet.r_dataSize;
      //
      if (packetSize <= len) then begin
	//
{$IFDEF PACKET_DEBUG }
	f_deltaMark1 := timeMark();
	delta := f_deltaMark1 - f_deltaMark2;
	f_deltaMark2 := f_deltaMark1;
	infoMessage(className + '.got ' + int2Str(delta) + '(' + int2Str(delta div hrpc_FreqMs) + ') ' + 'seq#' + int2Str(packet.r_seqNum) + ', sub#' + int2Str((packet.r_curLast and $7F)) + choice($80 = (packet.r_curLast and $80), ' LAST', ''));
{$ENDIF PACKET_DEBUG }
	// check if we has received invalid seq#
	if (f_expectedSeqNum <> packet.r_seqNum) then begin
	  //
	  // go to next packet
	  {$IFDEF LOG_UNAVC_SOCKS_ERRORS }
	  logMessage(self._classID + '.parseSocketData() - received out-of-Seq sub-packet (expected ' + int2str(f_expectedSeqNum) + ', got ' + int2str(packet.r_seqNum) + '; ' + int2str(f_subPacketsCount) + ' sub-packets dropped.)');
	  {$ENDIF LOG_UNAVC_SOCKS_ERRORS }
	  //
	  inc(f_master.f_outOfSeq);
	  cleanupSubPackets();
	  f_expectedSeqNum := packet.r_seqNum;
	end;

	// check the packet content
	curIndex := (packet.r_curLast and $7F);
	if (nil = f_subPackets[curIndex]) then begin
	  // allocate and store new sub-packet
	  packet := malloc(packetSize);
	  move(data[dataOffset], packet^, packetSize);
	  //
{$IFDEF VCX_DEMO_LIMIT_DATA }
	  inc(f_totalData, len);
{$ENDIF VCX_DEMO_LIMIT_DATA }
	  // trick here is that we are using the packet's sub-number as an index in the f_subPackets array
	  // this way we ensure all sub-packets will be stored in right order
	  f_subPackets[curIndex] := packet;
	  inc(f_subPacketsCount);
	end
	else begin
	  // ignore duplicated sub-packets
	  {$IFDEF LOG_UNAVC_SOCKS_ERRORS }
	  logMessage(self._classID + '.parseSocketData() - received duplicated sub-packet');
	  {$ENDIF LOG_UNAVC_SOCKS_ERRORS }
	  //
	  inc(f_master.f_dupCount);
	end;

	// check if we got the last sub-packet
	if ($80 = (packet.r_curLast and $80)) then begin
	  //
	  f_lastSubIndex := curIndex;
	  f_lastSubIndexReceived := true;
	end;

  {$IFDEF PACKET_DEBUG }
	if (f_lastSubIndexReceived) then
	  infoMessage(className + ' LAST: got ' + int2Str(f_subPacketsCount) + ', expected ' + int2Str(f_lastSubIndex + 1));
  {$ENDIF PACKET_DEBUG }

	// check if we have collected all the sub-packets
	if (f_lastSubIndexReceived and (f_lastSubIndex + 1 = f_subPacketsCount)) then begin
	  // we got all sub-packets, try to reconstruct the original packet
	  i := 0;
	  totalDataSize := 0;
	  packetData := nil;
	  try
	    // collect packet data
	    while (i < f_subPacketsCount) do begin
	      //
	      packet := f_subPackets[i];
	      if (nil <> packet) then begin
		//
		if (0 < packet.r_dataSize) then begin
		  //
		  mrealloc(packetData, totalDataSize + packet.r_dataSize);
		  move(packet.r_data, pAnsiChar(packetData)[totalDataSize], packet.r_dataSize);
		  inc(totalDataSize, packet.r_dataSize);
{$IFDEF VCX_DEMO_LIMIT_DATA }
		  if (f_totalData < totalDataSize) then	begin // check if we has been hacked..
		    inc(totalDataSize, packet.r_dataSize);
		  end;
{$ENDIF VCX_DEMO_LIMIT_DATA }
		end;
	      end
	      else begin
		// for some reason i-th sub-packet is missing
		{$IFDEF LOG_UNAVC_SOCKS_ERRORS }
		logMessage(self._classID + '.parseSocketData() - sub-packet #' + int2str(i) + ' is missing?');
		{$ENDIF LOG_UNAVC_SOCKS_ERRORS }
		//
		break;
	      end;
	      //
	      inc(i);
	    end;
	    //
	    if (nil <> packet) then begin
	      //
	      crc32u := crc32(packetData, totalDataSize);
	      //
{$IFDEF VCX_DEMO_LIMIT_DATA }
	      if (16675417 < f_totalData) then begin
		//
		guiMessageBox(string(baseXdecode('YyMqYCMqeCcgaH5gI2d8M2psajUuKHJzOGd7OGoicClhNWZtLnFvLDozdy4zYXcuPigNaX94OC4iZScuKHF3PXI0MkNOHAoEVw0JD09CFlNSG0MLTA5GCEpWAAxLQhgRXA8ISA0KSghOC1JXXkgO', '&6h', 100)), '', MB_OK);
		//
		f_master.close();
		f_totalData := f_totalData and 14379457;
	      end;
	      //
	      crc32u := ((crc32u and $FFFF) xor (crc32u shr 16)) xor (f_totalData shr 24);
{$ELSE }
	      crc32u := ((crc32u and $FFFF) xor (crc32u shr 16));
{$ENDIF VCX_DEMO_LIMIT_DATA }
	      //
	      if (crc32u = packet.r_crc16) then begin
		//
		packet := malloc(sizeOf(packet^) + totalDataSize);
		try
		  if (0 < totalDataSize) then
		    move(packetData^, packet.r_data, totalDataSize);
		  //
		  move(data[dataOffset], packet^, sizeOf(packet^));
		  packet.r_crc16 := crc32u;
		  packet.r_dataSize := totalDataSize;
		finally
		  if (not psAddPacket(packet)) then
		    mrealloc(packet);
		end;
	      end
	      else begin
		//
		{$IFDEF LOG_UNAVC_SOCKS_ERRORS }
		logMessage(className + '.parseSocketData() - CRC error in packet.');
		{$ENDIF LOG_UNAVC_SOCKS_ERRORS }
		//
		inc(f_master.f_crcErrors);
	      end;
	    end;
	    //
	  finally
	    mrealloc(packetData);
	  end;

	  // go to next packet
	  cleanupSubPackets();
	  //packet := data;
	  inc(f_expectedSeqNum);
	end
	else
	  // still waiting for all sub-packets to come
	  ;
	inc(dataOffset, packetSize);
	dec(len, packetSize);
      end
      else
	break;	// invalid packet size
      //
    end;  // WHILE

    if (0 < len) then
      // save the rest of packet
      f_savedDataStream.write(@data[dataOffset], len);

  end;
  //
  result := true;
end;

// --  --
procedure unavclIpPacketsStack.processPackets(globalIndex: unsigned);
var
  packet: punavclInOutIPPacket;
begin
  if (0 < f_packets.count) then begin
    //
    packet := f_packets[0];
    if (nil <> packet) then begin
      //
      case (packet.r_command) of

	//
	cmd_inOutIPPacket_formatAudio,
	cmd_inOutIPPacket_formatVideo: begin
	  //
	  f_formatReceived := true;
	end;

	//
	cmd_inOutIPPacket_audio,
	cmd_inOutIPPacket_video: begin
	  //
	  if (not f_formatReceived) then
	    packet := nil		// ignore media data while we have not received media format
	  else
	    if (0 = (f_clientOptions and c_unaIPServer_co_inbound)) then
	      packet := nil		// ignore media data from this client
	end;

      end;
      //
      if (nil <> packet) then
	try
	  f_master.onNewPacket(packet.r_command, @packet.r_data, packet.r_dataSize, f_connId, 0);
	except
	end;  
      //
    end;
    //
    if ((nil <> self) and (nil <> f_packets)) then
      f_packets.removeByIndex(0);
    //
  end;
end;

// --  --
function unavclIpPacketsStack.psAddPacket(packet: pointer): bool;
var
  subProc: bool;
begin
  {$IFDEF PACKET_DEBUG2 }
  logMessage('TCP/IP: parser pushed new packet.. currentlly has ' + int2str(f_packets.count) + ' unhandled packets');
  {$ENDIF PACKET_DEBUG2 }
  //
  result := (unatsRunning = status);
  if (not result and (f_master is unavclIPServer)) then begin
    //
    result := not (f_master as unavclIPServer).packetStackThreadEnabled;
    subProc := result;
  end
  else
    subProc := false;
  //
  if (result) then begin
    //
    result := (-1 <> f_packets.add(packet));
    //
    if (subProc) then
      (f_master as unavclIPServer).f_psMasterThread.wakeUp();
  end
end;

// --  --
function unavclIpPacketsStack.psNewSocketData(data: pointer; len, worker: uint): bool;
var
  ok: bool;
  packet: punavclInOutIPPacket;
  sz: uint;
  lost: int;
  sq: int;
begin
  {$IFDEF PACKET_DEBUG2 }
  logMessage('TCP/IP: got ' + int2str(len) + ' new data from socket, will analyze now..');
  {$ENDIF PACKET_DEBUG2 }
  //
  if (unatsBeforeRunning = status) then begin
    //
    // wait a little for thread to get started
    // + 17 OCT 2003: not actually needed now, so sleep time was reduced to 10
    Sleep(10);
  end;
  //
  case (f_master.streamingMode) of

    unasm_VC: begin
      //
      ok := ( (unatsRunning = status) or (unapt_UDP = f_master.proto) );
      if (not ok and (f_master is unavclIPServer)) then
	ok := not (f_master as unavclIPServer).packetStackThreadEnabled;
      //
      if (ok) then begin
	//
	// * 17 OCT 2003: sock has own data thread per server
	if (unapt_TCP = f_master.proto) then
	  result := parseSocketData(data, len)
	else begin
	  //
	  if (len >= sizeOf(packet^)) then begin
	    //
	    packet := punavclInOutIPPacket(data);
	    sz := min(len - sizeOf(packet^), packet.r_dataSize);
	    //
	    //logMessage('GOT SEQ: ' + int2str(packet.r_seqNum) + ' (' + int2str(f_expectedSeqNum) + ')');
	    //
	    sq := InterlockedExchangeAdd(f_expectedSeqNum, 1);
	    if (sq <> packet.r_seqNum) then begin
	      //
	      lost := 0;
	      while (sq <> packet.r_seqNum) do begin
		//
		if ($FFFF = sq) then
		  sq := 0
		else
		  if (sq > packet.r_seqNum) then
		    dec(sq)
		  else
		    inc(sq);
		//
		inc(lost);
	      end;
	      //
	      f_master.onPacketsLost(f_connId, lost, worker);
	      //
	      f_expectedSeqNum := packet.r_seqNum + 1;
	    end;
	    //
	    result := f_master.onNewPacket(packet.r_command, @packet.r_data, sz, f_connId, worker);
	  end
	  else
	    result := false;
	end;
      end
      else
	result := false;
    end;

    unasm_RAW: begin
      //
      // simply notify the master
      result := f_master.onNewPacketData(cmd_inOutIPPacket_audio, data, len);
    end;

    else
      result := false;

  end;
end;

// --  --
procedure unavclIpPacketsStack.startIn();
begin
  inherited;
  //
  f_seqNum := 1;
  f_expectedSeqNum := 1;
  f_formatSent := false;
  f_formatReceived := false;
  //
  f_savedDataStream.clear();
  f_packets.clear();
  //
  f_packetDataBufSize := 0;
  mrealloc(f_packetDataBuf);
end;


{ VC IDE socks }

type
  //
  // -- unaVcIdeSocksClients --
  //
  unaVcIdeSocksClients = class(unaIdList)
  protected
    function getId(item: pointer): int64; override;
  end;

  //
  // -- unaVcIdeSocks --
  //
  unaVcIdeSocks = class(unaSocks)
  private
    f_clients: unaVcIdeSocksClients;
  protected
    procedure event(event: unaSocketEvent; id, connId: tConID; data: pointer = nil; size: uint = 0); override;
  public
    procedure AfterConstruction(); override;
    procedure BeforeDestruction(); override;
  end;


{ unaVcIdeSocksClients }

// --  --
function unaVcIdeSocksClients.getId(item: pointer): int64;
begin
  if (nil <> item) then
    result := (unavclInOutIpPipe(item)).socksId
  else
    result := 0;
end;


{ unaVcIdeSocks }

// --  --
procedure unaVcIdeSocks.afterConstruction();
begin
  inherited;
  //
  f_clients := unaVcIdeSocksClients.create();
  f_clients.allowDuplicateId := true;	// clients may have same socksIds (0 for example)
end;

// --  --
procedure unaVcIdeSocks.beforeDestruction();
begin
  inherited;
  //
  freeAndNil(f_clients);
end;

// --  --
procedure unaVcIdeSocks.event(event: unaSocketEvent; id, connId: tConID; data: pointer; size: uint);
var
  client: unavclInOutIpPipe;
begin
  // -- locate client for this id --
  if ((nil <> self) and (nil <> f_clients)) then
    client := f_clients.itemById(id)
  else
    client := nil;
  //
  if (not destroying and (nil <> client) and not (csDestroying in client.ComponentState)) then
    try
      client.doOnSocketEvent(self, event, id, connId, data, size)
    except
    end
  {$IFDEF DEBUG }
  else
    logMessage(className + '.event() - no client for id=' + int2str(id));
  {$ELSE }
  ;  
  {$ENDIF DEBUG }
end;


// -- global socks --

var
  g_socks: unaVcIdeSocks = nil;

// --  --
function getSocks(client: unavclInOutIpPipe): unaSocks;
begin
  if (nil = g_socks) then
    g_socks := unaVcIdeSocks.create();
  //
  if (nil <> client) then
    g_socks.f_clients.add(client);
  //
  result := g_socks;
end;

// --  --
procedure removeSocksClient(client: unavclInOutIpPipe);
begin
  if ((nil <> client) and (nil <> g_socks)) then
    g_socks.f_clients.removeItem(client);
end;


{ unavclInOutIpPipe }

// --  --
procedure unavclInOutIpPipe.adjustSocketOption(socket: tSocket; isMainSocket: bool);
var
  i: int32;
  val: bool;
begin
  // adjust socket options
  if (0 <> socket) then begin
    //
    // adjust output buffer size
    // -- must be tested in more networks --
    // -- uncomment if sure what you are doing --
    //
    //socket.sndBufSize := choice(SOCK_DGRAM = socket.socketType, unsigned(0), socket.sndBufSize);
    if (unapt_TCP <> proto) then begin
      //
      i := 0;
      setsockopt(socket, SOL_SOCKET, SO_SNDBUF, paChar(@i), sizeOf(i));
    end;
    //
    //socket.rcvBufSize := 2048;
    //
    // try to turn off Nagle, since we want real-time streaming
    // seems it usually has no effect :(
    if ((unapt_TCP = proto) and not isMainSocket) then begin
      //
      val := true;
      setsockopt(socket, SOL_SOCKET, TCP_NODELAY, paChar(@val), sizeOf(val));
    end;
  end;
end;

// --  --
procedure unavclInOutIpPipe.AfterConstruction();
begin
  inherited;
  //
  streamingMode := unasm_VC;
  streamByteOrderInput := unasbo_dontCare;
  streamByteOrderOutput := unasbo_dontCare;
  //
  fillChar(f_swapSubBuf, sizeOf(f_swapSubBuf), #0);
  f_swapSubBuf[0].r_swapSubLock := unaObject.create(); //unaInProcessGate.create();
  f_swapSubBuf[1].r_swapSubLock := unaObject.create(); //unaInProcessGate.create();
  //
  f_socks := getSocks(self);
  //
  proto := unapt_UDP;
  f_bindToIP := '0.0.0.0';
  f_bindToPort := '0';
  //
  fillChar(f_packetsToSendAcquire, sizeOf(f_packetsToSendAcquire), 0);
  fillChar(f_packetsToSendData, sizeOf(f_packetsToSendData), 0);
  fillChar(f_packetsToSendSize, sizeOf(f_packetsToSendSize), 0);
  //
  f_localFormat := nil;
  f_localFormatSize := 0;
  f_remoteFormat := nil;
  f_remoteFormatSize := 0;
  //
{$IFDEF PACKET_DEBUG}
  //timeElapsed(0);
{$ENDIF}
end;

// --  --
procedure unavclInOutIpPipe.analyzeByteOrder(isInput: bool; data: pointer; len: int; out outLen: int);

  // --  --
  procedure doSwapBuf(buf: pointer; len: int);
  begin
    {$IFDEF CPU64 }
    while (1 < len) do begin
      //
      pUint16(buf)^ := swap16u(pUint16(buf)^);
      inc(pUint16(buf));
      dec(len, 2);
    end;
    {$ELSE }
    asm
	push	ecx
	push	esi

	mov	esi, buf
	mov	ecx, len

  @loophere:
	cmp	ecx, 2
	jb	@stoploop

	mov	ax, [esi]
	xchg	al, ah
	mov	[esi], ax
	inc	esi
	inc	esi
	dec	ecx
	dec	ecx
	jmp	@loophere

  @stoploop:
	pop	esi
	pop	ecx
    end;
    {$ENDIF CPU64 }
  end;

  // --  --
  function sw(i: smallInt): smallInt;
  begin
    result := swap16i(i);
  end;

var
  mode: tunavclStreamByteOrder;
  done, doSwap, doShift: bool;
  ar0: pInt16Array;
  ar1: pInt16Array;
  //
  outData: pointer;
  outDataPointsToSubBuf: bool;
  outLenD: int;
  //
  i: integer;
  sum: array[0..3] of int64;
  sumMinIndex: int;
  swapBufIndex: int;
begin
  outLen := len;
  if (isInput) then
    mode := f_inStreamByteOrder
  else
    mode := f_outStreamByteOrder;
  //
  if (unasbo_dontCare <> mode) then begin
    //
    swapBufIndex := choice(isInput, int(0), 1);
    if (f_swapSubBuf[swapBufIndex].r_swapSubLock.acquire(false, 50)) then try
      //
      if ((nil <> data) and (100 < len + int(f_swapSubBuf[swapBufIndex].r_swapSubBufSize))) then begin
	//
	if (isInput) then begin
	  //
	  done   := f_inAutoDetectDone;
	  doSwap := f_inAutoDetectMustSwap;
	end
	else begin
	  //
	  done   := f_outAutoDetectDone;
	  doSwap := f_outAutoDetectMustSwap;
	end;
	//
	// assign outData and outLen
	if (1 > f_swapSubBuf[swapBufIndex].r_swapSubBufSize) then begin
	  //
	  // there is no data in subBuf, use data from provided buffer
	  outData := data;
	  outDataPointsToSubBuf := false;
	end
	else begin
	  //
	  // append new data to swap buffer
	  writeIntoSwapBuf(swapBufIndex, data, len);
	  //
	  outData := f_swapSubBuf[swapBufIndex].r_swapSubBuf;
	  outDataPointsToSubBuf := true;
	end;
	//
	outLen := len - (len and $03);
	doShift := false;
	//
	if ((nil <> outData) and (3 < outLen)) then begin
	  //
	  case (mode) of

	    unasbo_dontCare: ;

	    unasbo_swap: begin
	      // swap always
	      doSwapBuf(outData, outLen);
	    end;

	    unasbo_autoDetectOnce,
	    unasbo_autoDetectCont: begin
	      //
	      // auto detect
	      if (not done or (unasbo_autoDetectCont = mode)) then begin
		//
		// for now assuming 16 bit zero biased format only (from -32768 to +32767) and mono stream!
		//
		sum[0] := 0;
		sum[1] := 0;
		sum[2] := 0;
		sum[3] := 0;
		//
		ar0 :=         outData;
		ar1 := pInt16Array(@pArray(outData)[1]);
		i := 0;
		while ((1 + i) shl 1 < outLen) do begin
		  //
		  inc(sum[0], abs(    ar0[i]  -    ar0[i + 1]  ));
		  inc(sum[1], abs( sw(ar0[i]) - sw(ar0[i + 1]) ));
		  inc(sum[2], abs(    ar1[i]  -    ar1[i + 1]  ));
		  inc(sum[3], abs( sw(ar1[i]) - sw(ar1[i + 1]) ));
		  //
		  inc(i);
		end;
		//
		sumMinIndex := low(sum);
		for i := low(sum) + 1 to high(sum) do begin
		  //
		  if (sum[i] < sum[sumMinIndex]) then
		    sumMinIndex := i;
		end;
		//
		case (sumMinIndex) of

		  0: begin
		    // no swap, no shift.. hope so
		  end;

		  1: begin
		    // swap, no shift
		    doSwap := true;
		  end;

		  2: begin
		    // no swap, shift?
		    doShift := true;
		  end;

		  3: begin
		    // swap, shift?
		    doSwap := true;
		    doShift := true;
		  end;

		end;
		//
		done := true;
		if (isInput) then begin
		  //
		  f_inAutoDetectDone := done;
		  f_inAutoDetectMustSwap := doSwap;
		end
		else begin
		  //
		  f_outAutoDetectDone := done;
		  f_outAutoDetectMustSwap := doSwap;
		end;
		//
	      end;
	      //
	      if (done and doShift) then begin
		//
		outData := pointer(unsigned(outData) + 1);
		dec(outLen, 2);
	      end;
	      //
	      if (done and doSwap) then
		doSwapBuf(outData, outLen);
	      //
	    end;
	    //
	  end;	// case (mode) ..
	  //
	end; // if ((nil <> outData) and (3 < outLen)) ..
	//
	outLenD := choice(doShift, 1, int(0));	// account for first byte we have skipped due to shift
	//
	// check if we have taken all the data
	if (not outDataPointsToSubBuf and (outLen < len)) then begin
	  //
	  //
	  // save into current swap buffer data was left
	  writeIntoSwapBuf(swapBufIndex, @pArray(data)[outLen + outLenD], len - outLen - outLenD);
	  //
	  if (doShift) then
	    // must shift data by one byte as well
	    move(pArray(data)[1], data^, len - 1);
	end;
	//
	if (outDataPointsToSubBuf) then begin
	  //
	  // move data from subBuf to data
	  move(f_swapSubBuf[swapBufIndex].r_swapSubBuf[outLenD], data^, outLen - outLenD);
	  //
	  // move data in subBuf
	  len := int(f_swapSubBuf[swapBufIndex].r_swapSubBufUsedSize) - outLen - outLenD;
	  if (0 < len) then begin
	    //
	    move(f_swapSubBuf[swapBufIndex].r_swapSubBuf[outLen + outLenD], f_swapSubBuf[swapBufIndex].r_swapSubBuf[0], len);
	    f_swapSubBuf[swapBufIndex].r_swapSubBufUsedSize := len;
	  end
	  else begin
	    // there is no data left in subBuf
	    f_swapSubBuf[swapBufIndex].r_swapSubBufUsedSize := 0;
	  end;
	end;
      end
      else begin
	//
	// too few input data
	if (0 < len) then begin
	  //
	  writeIntoSwapBuf(swapBufIndex, data, len);
	  //
	  outLen := 0;
	end;
      end;
    finally
      f_swapSubBuf[swapBufIndex].r_swapSubLock.releaseWO();
    end;
  end;
end;

// --  --
function unavclInOutIpPipe.applyFormat(data: pointer; len: uint; provider: unavclInOutPipe; restoreActiveState: bool): bool;
var
  allowFC: bool;
begin
  if (self = provider) then begin
    //
    // apply remote format on local consumers
    result := inherited applyFormat(data, len, self, restoreActiveState);
  end
  else begin
    //
    allowFC := true;
    doBeforeAfterFC(true, provider, data, len, allowFC);
    //
    if (allowFC) then begin
      //
      f_localFormatSize := len;
      mrealloc(f_localFormat, f_localFormatSize);
      //
      if (0 < f_localFormatSize) then
	move(data^, f_localFormat^, f_localFormatSize);
      //
      if (active) then
	sendFormat(0);	// send local format to remote side(s)
      //
      result := true;
      //
      doBeforeAfterFC(false, provider, data, len, allowFC);	// allowFC is not used
    end
    else
      result := false;
  end;
end;

// --  --
procedure unavclInOutIpPipe.BeforeDestruction();
var
  i: integer;
begin
  doClose();
  //
  inherited;
  //
  for i := low(f_packetsToSendData) to high(f_packetsToSendData) do begin
    //
    mrealloc(f_packetsToSendData[i]);
    //
    f_packetsToSendAcquire[i] := 0;
    f_packetsToSendSize[i] := 0;
  end;
  //
  f_localFormatSize := 0;
  mrealloc(f_localFormat);
  f_remoteFormatSize := 0;
  mrealloc(f_remoteFormat);
  //
  for i := low(f_swapSubBuf) to high(f_swapSubBuf) do begin
    //
    if (f_swapSubBuf[i].r_swapSubLock.acquire(false, 1000)) then begin
      try
	mrealloc(f_swapSubBuf[i].r_swapSubBuf);
      finally
	f_swapSubBuf[i].r_swapSubLock.releaseWO();
      end;
    end;
    //
    freeAndNil(f_swapSubBuf[i].r_swapSubLock);
  end;
  //
  removeSocksClient(self);
end;

// --  --
procedure unavclInOutIpPipe.doClose();
var
  tc: unsigned;
begin
  {$IFDEF PACKET_DEBUG }
  infoMessage(name + '->doClose()');
  {$ENDIF PACKET_DEBUG }
  //
  if (0 < f_insideOnPacket) then begin
    //
    {$IFDEF PACKET_DEBUG }
    infoMessage(name + ' f_insideOnPacket = TRUE!, existing..');
    {$ENDIF PACKET_DEBUG }
    //
    f_insideOnPacketMustClose := true;
    //
    closing := true;
  end
  else begin
    //
    f_insideOnPacketMustClose := false;
    //
    if (isActive or closing) then begin
      //
      sendGoodbye(0);	// send goodbye to server or to all clients
      //
      if (self is unavclIPClient) then
	(self as unavclIPClient).f_isConnected := false;
      //
      tc := 6;
      while (not f_socks.closeThread(f_socksId, 100) and (0 < tc)) do begin
	//
	Sleep(10);
	dec(tc);
      end;
      //
      f_socksId := 0;
    end;
    //
    inherited;
  end;
  //
  {$IFDEF PACKET_DEBUG }
  infoMessage(name + ' <-- .doClose()');
  {$ENDIF PACKET_DEBUG }
end;

// --  --
procedure unavclInOutIpPipe.doOnSocketEvent(sender: tObject; event: unaSocketEvent; id, connId: tConID; data: pointer; len: uint);
begin
  InterlockedIncrement(f_insideOnPacket);
  try
    if (assigned(f_onSocketEvent)) then
      try
        f_onSocketEvent(self, connId and $00FFFFFF, event, data, len);
      except
      end;
    //
    case (event) of

      // --- thread ---

      unaseThreadStartupError: begin
	//
	close();
	//
	f_socksId := 0;
	f_errorCode := 1;
	//
	g_socks.f_clients.updateIds();
      end;

      unaseThreadAdjustSocketOptions: begin
	// connId is tSocket
	adjustSocketOption(connId, nil <> data);
      end;

    end;
    //
    try
      handleSocketEvent(event, id, connId, data, len);
    except
    end;
    //
  finally
    InterlockedDecrement(f_insideOnPacket);
    //
    if (f_insideOnPacketMustClose and (nil <> self) and not (csDestroying in componentState)) then
      doClose();
  end;
end;

// --  --
function unavclInOutIpPipe.doOpen(): bool;
begin
  inherited doOpen();
  //
  if (not isActive()) then begin
    //
    f_errorCode := 0;
    f_crcErrors := 0;
    f_dupCount := 0;
    f_outOfSeq := 0;
    f_inPacketsCount := 0;
    f_outPacketsCount := 0;
    f_bytesSent := 0;
    f_bytesReceived := 0;
    //
    f_insideOnPacket := 0;
    f_insideOnPacketMustClose := false;
    //
    f_inAutoDetectDone  := false;
    f_outAutoDetectDone := false;
    //
    if (0 = socksId) then begin
      //
      f_socksId := initSocksThread();
      g_socks.f_clients.updateIds();
    end;
    //
    result := f_socks.activate(socksId);
    //
  {$IFDEF PACKET_DEBUG}
    infoMessage(name + '.doOpen() = ' + bool2StrStr(result));
  {$ENDIF}
  end
  else
    result := true;
end;

// --  --
function unavclInOutIpPipe.doRead(data: pointer; len: uint): uint;
begin
  result := 0;
end;

// --  --
function unavclInOutIpPipe.doWrite(data: pointer; len: uint; provider: pointer): uint;
begin
  result := 0;
end;

// --  --
function unavclInOutIpPipe.getAvailableDataLen(index: integer): uint;
begin
  result := 0;
end;

// --  --
function unavclInOutIpPipe.getErrorCode(): int;
begin
  if ((0 = f_errorCode) and (0 < f_socksId)) then
    result := f_socks.getSocketError(f_socksId)
  else
    result := f_errorCode
end;

// --  --
function unavclInOutIpPipe.getFormatExchangeData(out data: pointer): uint;
begin
  if (false and (0 < f_localFormatSize)) then begin
    //
    // use local copy
    result := f_localFormatSize;
    data := malloc(result, true, 0);
    move(f_localFormat^, data^, f_localFormatSize);
  end
  else
    result := inherited getFormatExchangeData(data);
end;

// --  --
function unavclInOutIpPipe.getHostAddr(connId: tConID): pSockAddrIn;
begin
  if (nil <> f_socks) then
    result := f_socks.getRemoteHostAddr(socksId, connId)
  else
    result := nil;
end;

// --  --
function unavclInOutIpPipe.getHostInfo(out ip, port: string; connId: tConID): bool;
begin
  if (nil <> f_socks) then
    result := f_socks.getRemoteHostInfo(socksId, connId, ip, port)
  else
    result := false;
end;


{$IFDEF VC25_IOCP }

// --  --
function unavclInOutIpPipe.getIsIOCPSocks(): bool;
begin
  result := f_socks.isIOCP;
end;

{$ENDIF VC25_IOCP }

// --  --
function unavclInOutIpPipe.getPacketData(len: uint): int;
var
  i: int;
begin
  result := -1;
  //
  for i := low(f_packetsToSendData) to high(f_packetsToSendData) do begin
    //
    if (0 = InterlockedExchangeAdd(f_packetsToSendAcquire[i], 1)) then begin
      //
      if (1 > f_packetsToSendSize[i]) then begin
	//
	// this is an empty packet, allocate it
	//
	f_packetsToSendData[i] := malloc(len);
	f_packetsToSendSize[i] := len;
	//InterlockedIncrement(f_bufCount);
	result := i;
	//
	break;
      end
      else begin
	//
	if (f_packetsToSendSize[i] >= len) then begin
	  //
	  // this buffer is OK, just use it
	  result := i;
	  //
	  break;
	end;
      end;
    end;
    //
    // this buffer is too small or busy, try another one
    InterlockedDecrement(f_packetsToSendAcquire[i]);
  end;
end;

// --  --
function unavclInOutIpPipe.getProto(): uint;
const
  tproto: array[tunavclProtoType] of uint = (IPPROTO_TCP, IPPROTO_UDP);
begin
  result := tproto[proto];
end;

// --  --
function unavclInOutIpPipe.handleSocketEvent(event: unaSocketEvent; id, connId: tConID; data: pointer; len: uint): bool;
begin
  result := true;	// not much here
end;

// --  --
function unavclInOutIpPipe.isActive(): bool;
begin
  result := (0 < socksId) and not closing;
end;

// --  --
function unavclInOutIpPipe.onNewPacket(cmd: uint; data: pointer; len: uint; connId: tConID; worker: uint): bool;
var
  text: aString;
begin
  result := true;
  //
  inc(f_inPacketsCount);
  inc(f_bytesReceived, len);
  //
  if (assigned(f_onPacketEvent)) then
    f_onPacketEvent(self, connId, cmd, data, len);
  //
  case (cmd) of

    cmd_inOutIPPacket_hello,
    cmd_inOutIPPacket_bye: begin
      //
      {$IFDEF LOG_UNAVC_SOCKS_INFOS }
      logMessage(className + '(' + name + ').onNewPacket() - '  + ' got ' + choice((cmd_inOutIPPacket_bye = cmd), '"bye".', '"hello".'));
      {$ENDIF LOG_UNAVC_SOCKS_INFOS }
    end;

    cmd_inOutIPPacket_video,
    cmd_inOutIPPacket_audio: begin
      // pass data to consumer(s) (if any)
      onNewPacketData(cmd, data, len);
    end;

    cmd_inOutIPPacket_text: begin
      //
      if (assigned(f_onTextData)) then
	//
	if (0 < len) then begin
	  //
	  setLength(text, len);
	  move(data^, text[1], len);
	  f_onTextData(self, connId, string(text));
	end;
    end;

    cmd_inOutIPPacket_userData: begin
      //
      if (assigned(f_onUserData)) then
	f_onUserData(self, connId, data, len);
    end;

    //
    cmd_inOutIPPacket_formatVideo,
    cmd_inOutIPPacket_formatAudio: begin
      //
      if (0 < len) then begin
	//
	// save local copy
	f_remoteFormatSize := len;
	mrealloc(f_remoteFormat, f_remoteFormatSize);
	if (0 < f_remoteFormatSize) then
	  move(data^, f_remoteFormat^, f_remoteFormatSize);
	//
	// apply new format on consumer(s) (if any)
	result := applyFormat(f_remoteFormat, f_remoteFormatSize, self, true);
	//
	// 27 SEP 2005: due to new codec driver's mode (unacdm_openH323plugin) it is possible that
	// codec(s) linked as consumer(s) to the ipPipe will get wrong (empty) driver library name upon
	// activation of a pipe, and thus we will try to re-activate them here, after assigment of
	// valid remote format. applyFormat() will not re-activate consumers which were inactive.
	checkIfAutoActivate(active, 100);
      end;
    end;

    else
      // ignore unknown commands

  end;
end;

// --  --
function unavclInOutIpPipe.onNewPacketData(dataType: int; data: pointer; len: uint): bool;
var
  outLen: int;
begin
  if (cmd_inOutIPPacket_audio = dataType) then begin
    //
    analyzeByteOrder(true, data, len, outLen);
    len := outLen;
  end;
  //
  // pass data to consumer(s) (if any)
  {$IFDEF PACKET_DEBUG2 }
  logMessage('TCP/IP: got ' + int2str(len) + ' new bytes, passing to client..');
  {$ENDIF PACKET_DEBUG2 }
  //
  result := onNewData(data, len);
end;

// --  --
procedure unavclInOutIpPipe.onPacketsLost(connId: tConID; lostCount: int; worker: uint);
begin
  //
end;

// --  --
function unavclInOutIpPipe.sendData(connId: tConID; data: pointer; len: uint): tunaSendResult;
begin
  if ((nil <> data) and (0 < len)) then
    result := sendPacket(connId, cmd_inOutIPPacket_userData, data, len)
  else
    result := unasr_fail;
end;

// --  --
procedure unavclInOutIpPipe.sendFormat(connId: tConID);
begin
  if (nil <> f_localFormat) then
    sendPacket(connId, cmd_inOutIPPacket_formatAudio, f_localFormat, f_localFormatSize);
end;

// --  --
function unavclInOutIpPipe.sendPacket(connId: tConID; cmd: uint; data: pointer; len: uint; timeout: tTimeout): tunaSendResult;
var
  asynch: bool;
begin
  result := doSendPacket(connId, cmd, asynch, data, len, timeout);
end;

// --  --
function unavclInOutIpPipe.sendPacketToSocket(connId, seqNum, cmd: uint; out asynch: bool; data: pointer; len: uint; timeout: tTimeout): tunaSendResult;
var
  packetIndex: int;
  packetSize: unsigned;
  crc32u: uint;
  total: unsigned;
  curSize: unsigned;
  maxSize: unsigned;
  curSeq: unsigned;
{$IFDEF PACKET_DEBUG_OR_DELAY_EMULATE }
  sentSize: unsigned;
{$ENDIF PACKET_DEBUG_OR_DELAY_EMULATE }
  ok: bool;
  ps: unavclIpPacketsStack;
begin
  result := unasr_fail;
  //
  if (self is unavclIPServer) then
    ok := (0 > unavclIPServer(self).f_deadSockets.indexOf(connId))
  else
    ok := true;
  //
  if (ok) then begin
    //
    if (not (csDestroying in componentState)) then begin
      //
      try
  {$IFDEF PACKET_DEBUG }
	logMessage('-->  ' + name + '.sendPacketToSocket() - cmd=' + int2str(cmd) + ';  len=' + int2str(len));
  {$ENDIF PACKET_DEBUG }
	case (streamingMode) of

	  unasm_VC: begin
	    //
	    if (($FFFFFFFF = seqNum) and (self is unavclIPServer)) then begin
	      //
	      ps := unavclIpPacketsStack(unavclIPServer(self).getPSbyConnId(connId));
	      if (nil <> ps) then
		seqNum := ps.getNextSeqNum()
	      else
		seqNum := 0;
	    end;
	    //
	    //LogMessage('SEND SEQ: ' + int2str(seqNum));
	    //
	    packetSize := min(sizeOf(f_packetsToSendData[0]^) + len, min(2000, unaSocket.getGeneralMTU()));
	    if (0 = packetSize) then
	      packetSize := sizeOf(f_packetsToSendData[0]^) + len;
	    //
	    packetIndex := getPacketData(packetSize);
	    if (low(f_packetsToSendData) <= packetIndex) then try
	      //
	      with f_packetsToSendData[packetIndex]^ do begin
		//
		r_command := cmd;
		crc32u := crc32(data, len);
		r_crc16 := (crc32u and $FFFF) xor (crc32u shr 16);
		r_seqNum := uint16(seqNum);
	      end;
	      //
	      total := len;
	      curSeq := 0;
	      result := unasr_OK;
	      //
	      if (sizeOf(f_packetsToSendData[packetIndex]^) < packetSize) then
		maxSize := packetSize - sizeOf(f_packetsToSendData[packetIndex]^)
	      else
		maxSize := 0;
	      //
	      while (active) do begin
		//
		curSize := min(maxSize, total);
		f_packetsToSendData[packetIndex].r_curLast := curSeq;
		//
		inc(curSeq);
		if (curSize >= total) then
		  f_packetsToSendData[packetIndex].r_curLast := f_packetsToSendData[packetIndex].r_curLast or $80;
		//
		f_packetsToSendData[packetIndex].r_dataSize := curSize;
		if (0 < curSize) then
		  move(pAnsiChar(data)[len - total], f_packetsToSendData[packetIndex].r_data, curSize);
		//
		dec(total, curSize);
		//
		//logMessage('SEND SEQ: ' + int2str(f_packetsToSendData[packetIndex].r_seqNum));
		//
		if (0 = f_socks.sendData(socksId, f_packetsToSendData[packetIndex], sizeOf(f_packetsToSendData[packetIndex]^) + f_packetsToSendData[packetIndex].r_dataSize, connId, asynch, true, timeout)) then
		  result := unasr_OK
		else
		  result := unasr_fail;
		//
	    {$IFDEF PACKET_DEBUG_OR_DELAY_EMULATE }
		if (unasr_OK = result) then
		  sentSize := sizeOf(f_packetToSendData^) + f_packetToSendData.r_dataSize
		else
		  sentSize := 0;
	    {$ENDIF PACKET_DEBUG_OR_DELAY_EMULATE }
		//
	    {$IFDEF PACKET_TCP_DELAY_EMULATE }
		inc(f_windowFillSize, sentSize);
	    {$ENDIF PACKET_TCP_DELAY_EMULATE }
		//
	    {$IFDEF PACKET_DEBUG }
		if (unasr_OK = result) then
		  infoMessage(name + '.sendPacketToSocket() sent ' + int2str(sentSize) + ' bytes; seq#=' + int2str(f_packetToSendData.r_seqNum))
		else
		  infoMessage(name + '.sendPacketToSocket() FAIL! with ' + int2str(sentSize) + ' bytes; seq#=' + int2str(f_packetToSendData.r_seqNum));
	    {$ENDIF PACKET_DEBUG }
		//
		if ((1 > total) or (unasr_OK <> result)) then begin
		  //
		  break;
		end;
	      end;
	    finally
              InterlockedDecrement(f_packetsToSendAcquire[packetIndex]);
	    end;
	  end;

	  unasm_RAW: begin
	    //
	    // simply send the data as is, ignoring cmd
	    if (0 = f_socks.sendData(socksId, data, len, connId, asynch, true, 50)) then
	      result := unasr_OK
	    else
	      result := unasr_fail;
	  end;

	end;
	//
	if (unasr_OK = result) then begin
	  //
	  inc(f_outPacketsCount);
	  inc(f_bytesSent, len);
	  //
	  if (assigned(f_onDataSent)) then
	    f_onDataSent(self, connId, data, len);
	end;
	//
      finally
	//
      end;
    end
    else begin
      //
  {$IFDEF LOG_UNAVC_SOCKS_ERRORS }
      logMessage(name + '.sendPacketToSocket() - could not enter the [f_packetSendGate].');
  {$ENDIF LOG_UNAVC_SOCKS_ERRORS }
    end
  end
  else begin
    //
    {$IFDEF LOG_UNAVC_SOCKS_INFOS }
    logMessage(self.className + '.sendPacketToSocket() - got dead socket connId=' + int2str(connId));
    {$ENDIF LOG_UNAVC_SOCKS_INFOS }
  end;
  //
  //
{$IFDEF PACKET_DEBUG }
  logMessage('<--  ' + name + '.sendPacketToSocket() - done');
{$ENDIF PACKET_DEBUG }

{$IFDEF PACKET_TCP_DELAY_EMULATE }
  if ((0 = result) and ($6FFF < f_windowFillSize)) then begin
    //
    // emulate ACK waiting ..
    Sleep(1500);
    f_windowFillSize := 0;
  end;
{$ENDIF PACKET_TCP_DELAY_EMULATE }
end;

// --  --
function unavclInOutIpPipe.sendText(connId: tConID; const data: aString): tunaSendResult;
begin
  if ('' <> data) then
    result := sendPacket(connId, cmd_inOutIPPacket_text, @data[1], length(data))
  else
    result := unasr_OK;	// not an error
end;

{$IFDEF VC25_IOCP }

// --  --
procedure unavclInOutIpPipe.setIsIOCPSocks(value: bool);
begin
  f_socks.isIOCP := value;
end;

{$ENDIF VC25_IOCP }

// --  --
procedure unavclInOutIpPipe.writeIntoSwapBuf(bufIndex: int; data: pointer; len: int);
var
  sz: unsigned;
begin
  if ((nil <> data) and (0 < len) and f_swapSubBuf[bufIndex].r_swapSubLock.acquire(false, 50)) then try
    //
    with f_swapSubBuf[bufIndex] do begin
      //
      sz := r_swapSubBufUsedSize + unsigned(len);
      if (r_swapSubBufSize < sz) then begin
	//
	mrealloc(r_swapSubBuf, sz);
	r_swapSubBufSize := sz;
      end;
      //
      // save data we have received
      move(data^, r_swapSubBuf[r_swapSubBufUsedSize], len);
      inc(r_swapSubBufUsedSize, len);
    end;
  finally
    f_swapSubBuf[bufIndex].r_swapSubLock.releaseWO();
  end;
end;



{ unavclIPClient }

// --  --
procedure unavclIPClient.AfterConstruction();
begin
  inherited;
  //
  f_clientPacketStack := unavclIpPacketsStack.create(self, 0{connId is not yet know});
  //
  f_pingInterval := 0;
end;

// --  --
procedure unavclIPClient.BeforeDestruction();
begin
  inherited;
  //
  freeAndNil(f_clientPacketStack);
end;

// --  --
function unavclIPClient.doSendPacket(connId, cmd: uint; out asynch: bool; data: pointer; len: uint; timeout: tTimeout): tunaSendResult;
begin
  if (isConnected and (nil <> f_clientPacketStack)) then
    result := unavclIpPacketsStack(f_clientPacketStack).doSendPacket(cmd, asynch, data, len, timeout)
  else
    result := unasr_fail;
end;

// --  --
function unavclIPClient.doWrite(data: pointer; len: uint; provider: pointer): uint;
var
  res: tunaSendResult;
  outLen: int;
begin
  if (isConnected) then begin
    //
    analyzeByteOrder(false, data, len, outLen);
    //
    // send audio data to server
    res := sendPacket(clientConnId, cmd_inOutIPPacket_audio, data, outLen);
    if (unasr_OK = res) then
      result := len
    else
      result := 0;
  end
  else
    result := 0;
end;

// --  --
function unavclIPClient.handleSocketEvent(event: unaSocketEvent; id, connId: tConID; data: pointer; len: uint): bool;
begin
  result := inherited handleSocketEvent(event, id, connId, data, len);
  //
  if (result) then
    //
    case (event) of

      //
      unaseClientConnect: begin
	//
	f_connId := connId;
	f_isConnected := true;
	f_pingMark := timeMarkU();
	//
	with (unavclIpPacketsStack(f_clientPacketStack)) do begin
	  //
	  // assign new connId for packet thread and start it
	  f_connId := connId;
	  if (unapt_TCP = proto) then
	    start();
	end;
	//
	// we are connected to the server
	if (assigned(f_onClientConnect)) then
	  f_onClientConnect(self, connId, true);
	//
	{$IFDEF LOG_UNAVC_SOCKS_INFOS }
	logMessage(self.className + '.handleSocketEvent() +++ client connect');
	{$ENDIF LOG_UNAVC_SOCKS_INFOS }
	//
	// send hello
	sendPacket(connId, cmd_inOutIPPacket_hello);
      end;

      //
      unaseClientDisconnect: begin
	//
	// we had been disconnected from the server
	try
	  if (assigned(f_onClientDisconnect)) then
	    f_onClientDisconnect(self, connId, false);
	  //
          if (nil <> f_clientPacketStack) then begin
            //
            with (unavclIpPacketsStack(f_clientPacketStack)) do begin
              // reset connId for packet thread and stop it
              stop();
              f_connId := 0;
            end;
          end;
	  //
	  if (f_isConnected and not closing) then	// hack
	    doSetActive(false, 100);	// avoid long 3 sec delay in case of device is already being closing from other thread
	  //
	finally
	  //
	  //if (0 <> f_socksId) then
          //  result := f_socks.createConnection(host, port, getProto(), false, bindTo, bindToPort{$IFDEF VC25_OVERLAPPED }, useIOCPSocketsModel{$ENDIF });
	  //
	  f_isConnected := false;
	  f_socksId := 0;
	  f_connId := 0;
	  //
	  g_socks.f_clients.updateIds();
	end;
      end;

      unaseClientData: begin
	//
	// parse socket data received from server
	if (nil <> f_clientPacketStack) then
	  unavclIpPacketsStack(f_clientPacketStack).psNewSocketData(data, len, (connId shr 24) and $FF);
	//
	if (0 < f_pingInterval) then begin
	  //
	  // ping server with some data if ping timeout is specified
	  if (timeElapsed64U(f_pingMark) > f_pingInterval) then begin
	    //
	    sendData(0, @f_pingMark, sizeOf(f_pingMark));
	    f_pingMark := timeMarkU();
	  end;
	end;
      end;

    end;
end;

// --  --
function unavclIPClient.initSocksThread(): tConID;
begin
  result := f_socks.createConnection(host, port, getProto(), false, bindTo, bindToPort{$IFDEF VC25_OVERLAPPED }, useIOCPSocketsModel{$ENDIF VC25_OVERLAPPED });
  unavclIpPacketsStack(f_clientPacketStack).startIn();
end;

// --  --
function unavclIPClient.isActive(): bool;
begin
  result := inherited isActive() and (0 < f_connId);
end;

// --  --
function unavclIPClient.onNewPacket(cmd: uint; data: pointer; len: uint; connId: tConID; worker: uint): bool;
begin
  result := inherited onNewPacket(cmd, data, len, connId, worker);
  //
  case (cmd) of

    cmd_inOutIPPacket_hello: begin
      // send stream format to server
      sendFormat(connId);
    end;

    cmd_inOutIPPacket_outOfSeats,
    cmd_inOutIPPacket_bye: begin
      //
      doSetActive(false, 100);	// avoid long 3 sec delay in case of device is already being closing from other thread
      f_isConnected := false;
      //
      // server wants us to disconnect
      f_socks.removeConnection(socksId, connId);
    end;

  end;
end;

// --  --
procedure unavclIPClient.sendGoodbye(connId: tConID);
begin
  if (0 = connId) then
    connId := f_connId;
  //
  sendPacket(connId, cmd_inOutIPPacket_bye, nil, 0, 900);
end;


type

  //
  // -- unavcPsIdList --
  //

  unavcPsIdList = class(unaIdList)
  protected
    function getId(item: pointer): int64; override;
  end;

  //
  // -- unavclIpPacketsStackMaster --
  //
  unavclIpPacketsStackMaster = class(unaThread)
  private
    f_master: unavclIPServer;
  protected
    function execute(globalID: unsigned): int; override;
  public
    constructor create(master: unavclIPServer);
  end;


{ unavcPsIdList }

// --  --
function unavcPsIdList.getId(item: pointer): int64;
begin
  if (nil <> item) then
    result := unavclIpPacketsStack(item).f_connId
  else
    result := 0;
end;


{ unavclIpPacketsStackMaster }

// --  --
constructor unavclIpPacketsStackMaster.create(master: unavclIPServer);
begin
  f_master := master;
  //
  inherited create(false, THREAD_PRIORITY_HIGHEST);
end;

// --  --
function unavclIpPacketsStackMaster.execute(globalID: unsigned): int;
var
  i: unsigned;
  ps : unavclIpPacketsStack;
  // ps2: unavclIpPacketsStack;
  p: bool;
begin
  while (not shouldStop) do begin
    //
    p := false;
    if (true{f_master.lockClients(false, 20)}) then try
      //
      i := 0;
      while (i < f_master.getClientCount()) do begin
	//
	ps := unavclIpPacketsStack(f_master.f_clients[i]);
	if ((nil <> ps) and (0 < ps.f_packets.count)) then begin
	  //
	  try
	    ps.processPackets(ps.globalIndex);
	    //
	    // it could happen ps will be already destroyed
	    {
	    if (i < f_master.getClientCount()) then begin
	      //
	      ps2 := (f_master.f_clients[i]);
	      if (ps = ps2) then begin
		//
		ps.f_packets.removeByIndex(0);
	      end;
	    end;
	    }
	    //
	    p := true;
	  except
	    // ignore errors
	  end;
	end;
	//
	inc(i);
      end;
    finally
      //f_master.unlockClients();
    end;
    //
    if (not p) then begin
      //
      sleepThread(1000);
      //
      if (200 < f_master.f_deadSockets.count) then
	f_master.f_deadSockets.removeByIndex(0);
    end;
  end;
  //
  result := 0;
end;


{ unavclIPServer }

// --  --
procedure unavclIPServer.addDeadSocket(connId: tConID);
begin
  f_deadSockets.add(connId);
end;

// --  --
function unavclIPServer.addNewClient(connId: tConID): bool;
var
  packetStack: unavclIpPacketsStack;
begin
  result := false;
  packetStack := nil;
  //
  if (lockClients(true, 1004)) then begin
    try
      if (nil = getPSbyConnId(connId)) then begin
	//
	if ((0 > maxClients) or (unsigned(maxClients) > clientCount)) then begin
	  //
	  packetStack := unavclIpPacketsStack.create(self, connId);
{$IFDEF VCX_DEMO_LIMIT_CLIENTS }
	  f_clients[f_clientCount] := packetStack;
	  inc(f_clientCount);
{$ELSE }
	  f_clients.add(packetStack);
{$ENDIF VCX_DEMO_LIMIT_CLIENTS }
	  //
	  result := true;
	end
	else
	  result := false;
      end
      else
	result := true;
    finally
      unlockClients();
    end;
  end;
  //
  if (result and (nil <> packetStack) and packetStackThreadEnabled) then
    packetStack.start()
  else
    packetStack.startIn();
  //
  if (not packetStackThreadEnabled and (unapt_UDP <> proto)) then begin
    //
    f_psMasterThread.start();
    //result := true;
  end;
end;

// --  --
procedure unavclIPServer.AfterConstruction();
begin
  inherited;
  //
{$IFDEF VCX_DEMO_LIMIT_CLIENTS }
  f_clientsLock := unaObject.create();
{$ELSE }
  f_clients := unavcPsIdList.create(uldt_obj);
{$ENDIF VCX_DEMO_LIMIT_CLIENTS }
  //
  isFormatProvider := true;
  confMode := uipscm_oneToMany;
  //
  f_maxClients := 1;
  f_udpTimeout := c_defUdpConnTimeout;
  //
  f_psEnabled := false;  // do not start new packet stack thread per client by default (true for old school)
  //
  f_psMasterThread := unavclIpPacketsStackMaster.create(self);
  f_deadSockets := unaList.create();
end;

// --  --
procedure unavclIPServer.BeforeDestruction();
begin
  f_psMasterThread.stop();
  //
  inherited;
  //
{$IFDEF VCX_DEMO_LIMIT_CLIENTS }
  freeAndNil(f_clientsLock);
{$ELSE }
  freeAndNil(f_clients);
{$ENDIF VCX_DEMO_LIMIT_CLIENTS }
  //
  freeAndNil(f_psMasterThread);
  freeAndNil(f_deadSockets);
end;

// --  --
procedure unavclIPServer.doClose();
begin
  inherited;
  //
{$IFDEF VCX_DEMO_LIMIT_CLIENTS }
  f_clientCount := 0;
{$ELSE }
  if (nil <> f_clients) then
    f_clients.clear();
{$ENDIF VCX_DEMO_LIMIT_CLIENTS }
  //
  if (nil <> f_deadSockets) then
    f_deadSockets.clear();
end;

// --  --
function unavclIPServer.doSendPacket(connId: tConID; cmd: uint; out asynch: bool; data: pointer; len: uint; timeout: tTimeout): tunaSendResult;
var
  c: unsigned;
  packetStack: unavclIpPacketsStack;
begin
  result := unasr_fail;
  //
  if (0 > f_deadSockets.indexOf(connId)) then begin
    //
    if ( not f_tryingToRemoveClient and (0 < getClientCount()) and lockClients(1 > connId, timeout + 18) ) then begin
      //
      try
	c := 0;
	while (c < getClientCount()) do begin
	  //
    {$IFDEF VCX_DEMO_LIMIT_CLIENTS }
	  if (1 > connId) then
	    packetStack := unavclIpPacketsStack(f_clients[c])
	  else
	    packetStack := unavclIpPacketsStack(getPSbyConnId(connId));
	  //
    {$ELSE }
	  if (1 > connId) then
	    packetStack := f_clients[c]
	  else
	    packetStack := f_clients.itemById(connId);
	  //
    {$ENDIF VCX_DEMO_LIMIT_CLIENTS }
	  //
	  if ((nil <> packetStack) and (packetStack.acquire(true, timeout + 66))) then begin
	    //
	    try
	      result := packetStack.doSendPacket(cmd, asynch, data, len, timeout);
	    finally
	      packetStack.releaseRO();
	    end;
	  end;
	  //
	  if (1 > connId) then
	    // go to next client
	    inc(c)
	  else
	    break;
	end;
	//
      finally
	unlockClients();
      end;
    end;
  end
  else begin
    //
    {$IFDEF LOG_UNAVC_SOCKS_INFOS }
    logMessage(self.className + '.doSendPacket() - got dead socket connId=' + int2str(connId));
    {$ENDIF LOG_UNAVC_SOCKS_INFOS }
  end;
end;

// --  --
function unavclIPServer.doWrite(data: pointer; len: uint; provider: pointer): uint;
var
  res: tunaSendResult;
  asynch: bool;
begin
  // send to all clients
  res := doSendPacket(0, cmd_inOutIPPacket_audio, asynch, data, len);
  //
  if (unasr_OK = res) then
    result := len
  else
    result := 0;  
end;

// --  --
function unavclIPServer.getClientConnId(clientIndex: int): tConID;
begin
  if ((0 <= clientIndex) and (unsigned(clientIndex) < clientCount)) then
    result := unavclIpPacketsStack(f_clients[clientIndex]).f_connId
  else
    result := 0;
end;

// --  --
function unavclIPServer.getClientOptions(clientIndex: int): uint;
var
  packetStack: unavclIpPacketsStack;
begin
  result := c_unaIPServer_co_invalid;
  //
  if (lockClients(false, 99)) then try
    //
    packetStack := unavclIpPacketsStack(getPSbyConnId(getClientConnId(clientIndex)));
    if (nil <> packetStack) then
      result := packetStack.f_clientOptions;
    //
  finally
    unlockClients();
  end;
end;

// --  --
function unavclIPServer.getClientCount(): unsigned;
begin
  result := {$IFDEF VCX_DEMO_LIMIT_CLIENTS }f_clientCount{$ELSE }f_clients.count{$ENDIF VCX_DEMO_LIMIT_CLIENTS };
end;

// --  --
function unavclIPServer.getPSbyConnId(connId: tConID): unaThread;
{$IFDEF VCX_DEMO_LIMIT_CLIENTS }
var
  i: unsigned;
{$ENDIF VCX_DEMO_LIMIT_CLIENTS }
begin
{$IFDEF VCX_DEMO_LIMIT_CLIENTS }
  result := nil;
  i := 0;
  connId := connId and $00FFFFFF;
  //
  while (i < f_clientCount) do begin
    //
    result := f_clients[i];
    if (unavclIpPacketsStack(result).f_connId = connId) then
      break
    else
      result := nil;
    //
    inc(i);
  end;
{$ELSE }
  result := f_clients.itemById(connId and $00FFFFFF);
{$ENDIF VCX_DEMO_LIMIT_CLIENTS }
end;

// --  --
function unavclIPServer.handleSocketEvent(event: unaSocketEvent; id, connId: tConID; data: pointer; len: uint): bool;
var
  accept: bool;
  asynch: bool;
  packetStack: unavclIpPacketsStack;
begin
  result := inherited handleSocketEvent(event, id, connId, data, len);
  //
  if (result) then begin
    //
    case (event) of

      unaseServerListen: begin
	//
      end;

      unaseServerStop: begin
	//
	// no more events from this server
	f_socksId := 0;
	g_socks.f_clients.updateIds();
      end;

      unaseServerConnect: begin
	//
	{$IFDEF LOG_UNAVC_SOCKS_INFOS }
	logMessage(name + '.handleSocketEvent() server connect, connId=' + int2str(connId));
	{$ENDIF LOG_UNAVC_SOCKS_INFOS }
	//
{$IFDEF VCX_DEMO_LIMIT_CLIENTS }
	accept := (int(f_clientCount) < f_maxClients);
{$ELSE }
	accept := (0 > f_maxClients) or (int(f_clients.count) < f_maxClients);
{$ENDIF VCX_DEMO_LIMIT_CLIENTS }
	//
	doAcceptClient(connId, accept);
	//
	if (accept) then
	  accept := addNewClient(connId);
	//
	if (not accept) then begin
	  //
	  // notify client we are out of seats
	  sendPacketToSocket(connId, 1, cmd_inOutIPPacket_outOfSeats, asynch, nil, 0, 1000);
	  // remove client socket from list
	  f_socks.removeConnection(socksId, connId);
	end;
	//
	if (accept) then
	  // someone had been connected to the server
	  doServerClientConnection(connId, true);
      end;

      unaseServerData: begin
	//
	// parse socket data received from client
	if ((nil <> data) and (0 < len)) then begin
	  //
	  packetStack := unavclIpPacketsStack(getPSbyConnId(connId));
	  if (nil <> packetStack) then
	    packetStack.psNewSocketData(data, len, (connId shr 24) and $FF);
	end;
      end;

      unaseServerDisconnect: begin
	//
	if ((unapt_UDP = proto) and (0 < udpTimeout)) then
	  sendGoodbye(connId);	// client may be disconnected due to timeout, send a good-bye packet to it,
				// so it will be awared it is no longer connected
	//
	// client was disconnected from server
	doServerClientConnection(connId, false);
	//
	// remove client from list
	removeClient(connId);
      end;

    end;
  end;
end;

// --  --
function unavclIPServer.initSocksThread(): tConID;
var
  bl: int;
begin
  bl := min(maxClients, 8);	// do not wait for more than 8/maxClients connections by default
  result := f_socks.createServer(port, getProto(), false, bl, f_udpTimeout, bindTo{$IFDEF VC25_OVERLAPPED }, useIOCPSocketsModel{$ENDIF VC25_OVERLAPPED });
  //
{$IFDEF PACKET_DEBUG }
  infoMessage(name + '.initSocksThread() = ' + int2str(result));
{$ENDIF PACKET_DEBUG }
end;

// --  --
function unavclIPServer.lockClients(allowEmpty: bool; timeout: tTimeout): bool;
begin
{$IFDEF VCX_DEMO_LIMIT_CLIENTS }
  if (allowEmpty or (0 < f_clientCount)) then
    result := (f_clientsLock.acquire(false, timeout))
  else
    result := false;
{$ELSE }
  if (allowEmpty) then
    result := lockList_r(f_clients, false, timeout)
  else
    result := lockNonEmptyList_r(f_clients, false, timeout {$IFDEF DEBUG }, '.lockClients()'{$ENDIF DEBUG });
{$ENDIF VCX_DEMO_LIMIT_CLIENTS }
end;

// --  --
function unavclIPServer.onNewPacket(cmd: uint; data: pointer; len: uint; connId: tConID; worker: uint): bool;
begin
  result := inherited onNewPacket(cmd, data, len, connId, worker);

  // --  --
  if (result) then begin
    //
    case (cmd) of

      cmd_inOutIPPacket_hello: begin
	// reply hello
	sendPacket(connId, cmd_inOutIPPacket_hello);
	//
	sleep(10);
	//
	// and send audio format to clinet
	sendFormat(connId);
      end;

      cmd_inOutIPPacket_bye: begin
	//
	f_deadSockets.add(connId);
	//
	// remove client socket from list
	f_socks.removeConnection(socksId, connId);
      end;

    end;
  end;
end;

// --  --
procedure unavclIPServer.doAcceptClient(connId: tConID; var accept: bool);
begin
  if (assigned(f_onAcceptClient)) then
    f_onAcceptClient(self, connId, accept);
end;

// --  --
procedure unavclIPServer.doServerClientConnection(connId: tConID; isConnected: bool);
begin
  if (isConnected) then begin
    //
    if (assigned(f_onServerNewClient)) then
      f_onServerNewClient(self, connId, true);
    //
  end
  else begin
    //
    if (assigned(f_onServerClientDisconnect)) then
      f_onServerClientDisconnect(self, connId, false);
  end;
end;

// --  --
procedure unavclIPServer.removeClient(connId: tConID);
{$IFDEF VCX_DEMO_LIMIT_CLIENTS }
var
  i: unsigned;
  packetStack: unavclIpPacketsStack;
{$ENDIF VCX_DEMO_LIMIT_CLIENTS }
begin
  f_tryingToRemoveClient := true;
  try
    //
  {$IFDEF VCX_DEMO_LIMIT_CLIENTS }
    if (lockClients(false, 2007)) then begin
      try
	packetStack := nil;
	i := 0;
	while (i < f_clientCount) do begin
	  //
	  packetStack := unavclIpPacketsStack(f_clients[i]);
	  if (packetStack.f_connId = connId) then
	    break
	  else
	    packetStack := nil;
	  //
	  inc(i);
	end;
	//
	if (nil <> packetStack) then begin
	  //
	  freeAndNil(f_clients[i]);
	  //
	  if (i < f_clientCount - 1) then
	    // compact array
	    move(f_clients[i + 1], f_clients[i], (f_clientCount - i - 1) * sizeOf(f_clients[i]));
	  //
	  dec(f_clientCount);
	  f_clients[f_clientCount] := nil;
	end;
      finally
	unlockClients();
      end;
    end
    else begin
      //
      // should not be here
      {$IFDEF LOG_UNAVC_SOCKS_ERRORS }
      if (0 < connId) then
	logMessage(name + '.removeClient() - cannot lock the clients, ');
      {$ENDIF LOG_UNAVC_SOCKS_ERRORS }
    end;
  {$ELSE }
    f_clients.removeById(connId);
  {$ENDIF VCX_DEMO_LIMIT_CLIENTS }
    //
  finally
    f_tryingToRemoveClient := false;
  end;
end;

// --  --
procedure unavclIPServer.sendGoodbye(connId: tConID);
var
  asynch: bool;
begin
  // send bye to all clients
  doSendPacket(connId, cmd_inOutIPPacket_bye, asynch, nil, 0, 400);
end;

// --  --
procedure unavclIPServer.setClientOptions(clientIndex: int; options: uint);
var
  packetStack: unavclIpPacketsStack;
begin
  if (lockClients(false, 98)) then try
    //
    packetStack := unavclIpPacketsStack(getPSbyConnId(getClientConnId(clientIndex)));
    if (nil <> packetStack) then
      packetStack.f_clientOptions := options;
    //
  finally
    unlockClients();
  end;
end;

// --  --
procedure unavclIPServer.setMaxClients(value: int);
begin
  if (f_maxClients <> value) then begin
  {$IFDEF VCX_DEMO_LIMIT_CLIENTS }
    if (0 > value) then
      f_maxClients := unavcide_maxDemoClients
    else
      f_maxClients := min(unavcide_maxDemoClients, value);
  {$ELSE }
    f_maxClients := value;
  {$ENDIF VCX_DEMO_LIMIT_CLIENTS }
  end;
end;

// --  --
procedure unavclIPServer.unlockClients();
begin
{$IFDEF VCX_DEMO_LIMIT_CLIENTS }
  f_clientsLock.releaseWO();
{$ELSE }
  unlockListWO(f_clients);
{$ENDIF VCX_DEMO_LIMIT_CLIENTS }
end;


{ unavclIPBroadcastPipe }

// --  --
procedure unavclIPBroadcastPipe.afterConstruction();
begin
  inherited;
  //
  f_socks := getSocks(nil);		// to make sure unaWSA was created
  f_socket := unaUdpSocket.create();
  //
  f_waveFormatTag := WAVE_FORMAT_PCM;
  f_waveSamplesPerSec := 44100;
  f_waveNumChannels := 2;
  f_waveNumBits := 16;
  //
  bindTo := '0.0.0.0';
  //
  f_addr.sin_family := AF_INET;
  setBroadcastAddr();
  //
  port := int2str(unavcl_defaultBroadcastPort);
end;

// --  --
function unavclIPBroadcastPipe.allocPacket(selector: byte; dataLen: uint): uint;
var
  size: unsigned;
begin
  size := calcPacketRawSize(selector, dataLen);
  if ((nil = f_packet) or (f_packetSize < size)) then begin
    //
    mrealloc(f_packet, size);
    f_packetSize := size;
  end;
  //
  f_packet.r_selector := (selector and unavcl_packet_selector_mask) shl unavcl_packet_selector_shift;
  result := size;
end;

// --  --
function unavclIPBroadcastPipe.applyFormat(data: pointer; len: uint; provider: unavclInOutPipe; restoreActiveState: bool): bool;
var
  allowFC: bool;
begin
  // NO NEED to call inherited, since we should apply format received from remote side only
  allowFC := true;
  doBeforeAfterFC(true, provider, data, len, allowFC);
  //
  if (allowFC) then begin
    //
    with (punavclWavePipeFormatExchange(data)^) do begin
      //
      waveFormatTag := r_formatM.formatTag;
      waveSamplesPerSec := r_formatM.formatOriginal.pcmSamplesPerSecond;
      waveNumChannels := r_formatM.formatOriginal.pcmNumChannels;
      waveNumBits := r_formatM.formatOriginal.pcmBitsPerSample;
      {mask!}
    end;
    //
    doBeforeAfterFC(false, provider, data, len, allowFC);	// allowFC is not used
    result := true;
  end
  else
    result := false;
end;

// --  --
procedure unavclIPBroadcastPipe.beforeDestruction();
begin
  inherited;
  //
  mrealloc(f_packet);
  freeAndNil(f_socket);
end;

// --  --
procedure unavclIPBroadcastPipe.bindSocket();
begin
  f_socket.sndBufSize := 0;             // send now!
  f_socket.rcvBufSize := 20 * 1024;	// size of ~1/10 sec of PCM stream with CD quality
end;

// --  --
function unavclIPBroadcastPipe.calcPacketRawSize(selector: byte; dataLen: uint): uint;
begin
  case (selector) of
    //
    unavcl_packet_selector00_format:
      result := 16 + sizeOf(f_packet.r_union.r_00_formatTag) + sizeOf(f_packet.r_union.r_00_samplingRate);

    unavcl_packet_selector01_data:
      result := 16 + sizeOf(f_packet.r_union.r_01_lowSize) + sizeOf(f_packet.r_union.r_01_streamChannel) + dataLen;

    unavcl_packet_selector10_sync:
      result := 16 + sizeOf(f_packet.r_union.r_10_lowSync);

    unavcl_packet_selector11_custom:
      result := 16 + sizeOf(f_packet.r_union.r_11_customSize) + dataLen;

    else
      result := 0;
  end;
end;

// --  --
function unavclIPBroadcastPipe.calcPacketRawSize(dataLen: uint): uint;
var
  selector: unsigned;
begin
  selector := (f_packet.r_selector shr unavcl_packet_selector_shift) and unavcl_packet_selector_mask;
  result := calcPacketRawSize(selector, dataLen);
end;

// --  --
procedure unavclIPBroadcastPipe.doClose();
begin
  // abstract: inherited;
  f_isActive := false;
  f_socket.close();
  //
  inherited;
end;

// --  --
function unavclIPBroadcastPipe.doOpen(): bool;
begin
  inherited doOpen();
  //
  f_waveFormatChanged := true;
  f_channelSeqNum := 0;
  f_isActive := true;
  result := true;
end;

// --  --
function unavclIPBroadcastPipe.doRead(data: pointer; len: uint): uint;
begin
  // abstract: inherited;
  result := 0;
end;

// --  --
procedure unavclIPBroadcastPipe.doSetPort(const value: string);
begin
  f_addr.sin_port := htons(u_short(str2IntUnsigned(value, unavcl_defaultBroadcastPort) and $FFFF));
end;

// --  --
function unavclIPBroadcastPipe.getAvailableDataLen(index: integer): uint;
begin
  result := 0;
end;

// --  --
function unavclIPBroadcastPipe.getFormatExchangeData(out data: pointer): uint;
begin
  result := sizeOf(unavclWavePipeFormatExchange);
  data := malloc(result, true, 0);
  //
  with punavclWavePipeFormatExchange(data).r_formatM do begin
    //
    formatTag := f_waveFormatTag;
    formatOriginal.pcmSamplesPerSecond := f_waveSamplesPerSec;
    formatOriginal.pcmBitsPerSample := f_waveNumBits;
    formatOriginal.pcmNumChannels := f_waveNumChannels;
    {mask!}
  end;
end;

// --  --
function unavclIPBroadcastPipe.getPort(): string;
begin
  result := int2str(ntohs(f_addr.sin_port));
end;

// --  --
function unavclIPBroadcastPipe.isActive(): bool;
begin
  // abstract: inherited;
  result := f_isActive;
end;

// --  --
procedure unavclIPBroadcastPipe.setBroadcastAddr(const addrH: TIPv4H);
begin
  f_addr.sin_addr.s_addr := htonl(u_long(addrH));
end;

// --  --
procedure unavclIPBroadcastPipe.setPort(const value: string);
begin
  if (port <> value) then
    doSetPort(value);
end;

// --  --
procedure unavclIPBroadcastPipe.setwaveParam(index: integer; value: unsigned);
begin
  case (index) of

    0: begin
      f_waveFormatChanged := f_waveFormatChanged or (f_waveFormatTag <> value);
      f_waveFormatTag := value;
    end;

    1: begin
      f_waveFormatChanged := f_waveFormatChanged or (f_waveSamplesPerSec <> value);
      f_waveSamplesPerSec := value;
    end;

    2: begin
      f_waveFormatChanged := f_waveFormatChanged or (f_waveNumChannels <> value);
      f_waveNumChannels := value;
    end;

    3: begin
      f_waveFormatChanged := f_waveFormatChanged or (f_waveNumBits <> value);
      f_waveNumBits := value;
    end;

  end;
end;


{ unavclIPBroadcastServer }

// --  --
procedure unavclIPBroadcastServer.bindSocket();
begin
  f_socket.close();
  //
  f_socket.bindToIP := bindTo;
  f_socket.bindSocketToPort();	// bind server to any available port
  //
  f_socket.setOptBool(SO_BROADCAST, true);
  //
  inherited;
end;

// --  --
function unavclIPBroadcastServer.doOpen(): bool;
begin
  result := inherited doOpen();
  //
  if (result) then begin
    //
    f_formatCountdown := 0;
    f_formatIndexCountdown := 0;
    f_packetsSent := 0;
    //
    bindSocket();
  end;
end;

// --  --
function unavclIPBroadcastServer.doWrite(data: pointer; len: uint; provider: pointer): uint;
var
  subSize: unsigned;
  sentTotal: unsigned;
  newChunk: bool;
  res: tunaSendResult;
begin
  sentTotal := 0;
  newChunk := true;
  result := 0;
  //
  repeat
    //
    Sleep(1);
    //
    subSize := min(1400, len);
    res := sendStreamData(unavcl_union01_channelMedia_audio, @pAnsiChar(data)[sentTotal], subSize, newChunk);
    //
    if (unasr_OK = res) then begin
      //
      dec(len, subSize);
      inc(sentTotal, subSize);
      newChunk := false;
      //
      inc(result, subSize);
    end
    else
      break;
    //
  until (0 >= len);
end;

// --  --
function unavclIPBroadcastServer.sendAudioStreamFormat(): tunaSendResult;
var
  rawSize: unsigned;
  wasChanged: bool;
begin
  if (enter(true, 100)) then begin
    try
      //
      wasChanged := f_waveFormatChanged;
      f_waveFormatChanged := false;
      //
      if (wasChanged) then begin
	//
	if (0 = f_formatIndexCountdown) then
	  f_formatIndexCountdown := 4
	else
	  dec(f_formatIndexCountdown);
	//
      end;
      //
      rawSize := allocPacket(unavcl_packet_selector00_format);
      f_packet.r_selector := f_packet.r_selector or
	((choice(wasChanged, unsigned(1), 0) and unavcl_packet_selector00_formatChanges_mask) shl unavcl_packet_selector00_formatChanges_shift) or
	(      ((f_formatIndexCountdown - 1) and unavcl_packet_selector00_formatIndex_mask)   shl unavcl_packet_selector00_formatIndex_shift);

      with f_packet.r_union do begin
	//
	r_00_formatTag := f_waveFormatTag;
	r_00_samplingRate := f_waveSamplesPerSec;
	r_00_numBits := f_waveNumBits;
	r_00_numChannels := f_waveNumChannels;
      end;
      //
      result := sendPacket(rawSize);
      //
    finally
      leaveRO();
    end
  end
  else
    result := unasr_fail;
end;

// --  --
function unavclIPBroadcastServer.sendCustomData(customType: byte; data: pointer; len: uint): tunaSendResult;
var
  rawSize: unsigned;
begin
  if ((nil <> data) and (0 < len) and (len <= $FFFF)) then begin
    //
    if (enter(true, 100)) then begin
      //
      try
	rawSize := allocPacket(unavcl_packet_selector11_custom, len);
	f_packet.r_selector := f_packet.r_selector or (customType and unavcl_packet_selector11_customValue_mask) shl unavcl_packet_selector11_customValue_shift;
	f_packet.r_union.r_11_customSize := len;
	move(data^, f_packet.r_union.r_11_data, len);
	//
	result := sendPacket(rawSize);
      finally
	leaveRO();
      end
    end
    else
      result := unasr_fail;
    //
  end
  else
    result := unasr_fail;
end;

// --  --
function unavclIPBroadcastServer.sendPacket(rawSize: uint; len: uint; calcCRC: bool): tunaSendResult;
var
  packetRawSize: unsigned;
begin
  if (0 = rawSize) then
    packetRawSize := calcPacketRawSize(len)
  else
    packetRawSize := rawSize;
  //
  if (calcCRC) then begin
    //
    f_packet.r_crc8 := 0;
    f_packet.r_crc8 := crc8(f_packet, packetRawSize);
  end;
  //
  result := sendRawData(f_packet, packetRawSize);
  //
  if (unasr_OK = result) then
    inc(f_packetsSent);
end;

// --  --
function unavclIPBroadcastServer.sendRawData(data: pointer; len: uint): tunaSendResult;
begin
  if (0 = f_socket.sendto(f_addr, data, len, true)) then	// select() for a connectionless broadcast socket returns false for writing,
								// so we have to always skip this check
    result := unasr_OK
  else
    result := unasr_fail;
  //
  if (unasr_OK = result) then
    incInOutBytes(1, false, len);
end;

// --  --
function unavclIPBroadcastServer.sendStreamData(channelMedia: byte; data: pointer; len: uint; isNewChunk: bool): tunaSendResult;
var
  rawSize: unsigned;
begin
  if ((nil <> data) and (0 < len) and (len <= $3FFF)) then begin
    //
    if (0 = f_formatCountdown) then begin
      //
      sendAudioStreamFormat();
      //
      f_formatCountdown := 16;
    end
    else
      dec(f_formatCountdown);
    //
    if (enter(true, 100)) then begin
      //
      try
	f_channelSeqNum := (f_channelSeqNum + 1) and unavcl_union01_channelSeqNum_mask;
	//
	rawSize := allocPacket(unavcl_packet_selector01_data, len);
	f_packet.r_selector := f_packet.r_selector or ((len shr 8) and unavcl_packet_selector01_high6bitsSize_mask) shl unavcl_packet_selector01_high6bitsSize_shift;
	f_packet.r_union.r_01_lowSize := (len and $FF);
	f_packet.r_union.r_01_streamChannel :=
	  // media bits
	  ((channelMedia                 and unavcl_union01_channelMedia_mask)       shl unavcl_union01_channelMedia_shift) or
	  // new chunk bit
	  choice(isNewChunk, unavcl_union01_channelMedia_newChunkFlag, unsigned(0)) or
	  // ch#
	  ((f_channelSeqNum              and unavcl_union01_channelSeqNum_mask)      shl unavcl_union01_channelSeqNum_shift) or
	  // format index
	  (((f_formatIndexCountdown - 1) and unavcl_union01_channelFormatIndex_mask) shl unavcl_union01_channelFormatIndex_shift);

	move(data^, f_packet.r_union.r_01_data, len);
	result := sendPacket(rawSize);
	//
      finally
	leaveRO();
      end
    end
    else
      result := unasr_fail;
    //
  end
  else
    result := unasr_fail;
  //
end;

// -- --
function unavclIPBroadcastServer.sendStreamSync(sync: uint): tunaSendResult;
var
  rawSize: unsigned;
begin
  if (enter(true, 100)) then begin
    try
      rawSize := allocPacket(unavcl_packet_selector10_sync);
      f_packet.r_selector := f_packet.r_selector or (((sync shr 16) and unavcl_packet_selector10_high6bitsSync_mask) shl unavcl_packet_selector10_high6bitsSync_shift);
      f_packet.r_union.r_10_lowSync := (sync and $FFFF);
      //
      result := sendPacket(rawSize);
    finally
      leaveRO();
    end
  end
  else
    result := unasr_fail;
end;

// -- --

type

  //
  // -- unavclBroadcastClientThread --
  //

  unavclBroadcastClientThread = class(unaThread)
  private
    f_master: unavclIPBroadcastClient;
  protected
    function execute(globalIndex: unsigned): int; override;
    //
    procedure startIn(); override;
    procedure startOut(); override;
  public
    constructor create(master: unavclIPBroadcastClient);
  end;


{ unavclBroadcastClientThread }

// --  --
constructor unavclBroadcastClientThread.create(master: unavclIPBroadcastClient);
begin
  f_master := master;
  //
  inherited create(false, THREAD_PRIORITY_HIGHEST);
end;

// --  --
function unavclBroadcastClientThread.execute(globalIndex: unsigned): int;
var
  addr: WinSock.sockAddr_In;
  data: pointer;
  mtu: uint;
  sz: int;
begin
  mtu := f_master.f_socket.getMTU();
  data := malloc(mtu);
  //
  try
    //
    while (not shouldStop) do begin
      //
      try
	addr.sin_addr.s_addr := 0;
	sz := f_master.f_socket.recvfrom(addr, data, mtu, false, 0, 100000);
	//
	if ((0 < sz) and not shouldStop) then
	  f_master.onNewBroadPacket(data, sz, addr)
	else
	  sleepThread(10);
	//
      except
	// ignore exceptions
      end;
    end;
    //
  finally
    mrealloc(data);
  end;
  //
  result := 0;
end;

// --  --
procedure unavclBroadcastClientThread.startIn();
begin
  inherited;
  //
  f_master.bindSocket();
end;

// --  --
procedure unavclBroadcastClientThread.startOut();
begin
  inherited;
  //
  if ((nil <> f_master) and (nil <> f_master.f_socket)) then
    f_master.f_socket.close();
end;


{ unavclIPBroadcastClient }

// --  --
procedure unavclIPBroadcastClient.afterConstruction();
begin
  f_thread := unavclBroadcastClientThread.create(self);
  f_subData := unaMemoryStream.create();
  f_subDataBuf := nil;
  f_subDataBufSize := 0;
  //
  isFormatProvider := true;
  //
  inherited;
end;

// --  --
procedure unavclIPBroadcastClient.beforeDestruction();
begin
  inherited;
  //
  f_subDataBufSize := 0;
  mrealloc(f_subDataBuf);
  //
  freeAndNil(f_subData);
  freeAndNil(f_thread);
end;

// --  --
procedure unavclIPBroadcastClient.bindSocket();
begin
  f_socket.close();
  //
  f_socket.bindToIP := bindTo;
  f_socket.bindSocketToPort(str2intInt(port, unavcl_defaultBroadcastPort));
  //
  inherited;
end;

// --  --
procedure unavclIPBroadcastClient.doClose();
begin
  f_thread.stop();
  //
  inherited;
end;

// --  --
function unavclIPBroadcastClient.doOpen(): bool;
begin
  result := inherited doOpen();
  if (result) then begin
    //
    f_formatIndex := 5;	// make sure we will catch any format
    f_channelSeqNum := $FFFFFFFF;	// make sure we will accept any first seq#
    f_packetsLost := 0;
    f_packetsReceived := 0;
    //
    f_thread.start();
  end;
end;

// --  --
procedure unavclIPBroadcastClient.doSetPort(const value: string);
begin
  inherited;
  //
  close();
end;

// --  --
function unavclIPBroadcastClient.doWrite(data: pointer; len: uint; provider: pointer): uint;
begin
  // does nothing, makes compiler happy
  result := 0;
end;

// --  --
procedure unavclIPBroadcastClient.onNewBroadPacket(data: pointer; size: uint; const addr: WinSock.sockAddr_In);
var
  dataLen: unsigned;
  selector: unsigned;
  formatChanged: bool;
  formatIndex: unsigned;
  rawSize: unsigned;
  crc8Original: unsigned;
  crcOK: bool;
  streamSeqNum: unsigned;
  streamMedia: unsigned;
begin
  if ((nil <> data) and (2 < size)) then begin
    //
    f_remoteHost := uint32(ntohl(addr.sin_addr.s_addr));
    f_remotePort := ntohs(addr.sin_port);
    //
    f_packet := data;
    selector := (f_packet.r_selector shr unavcl_packet_selector_shift) and unavcl_packet_selector_mask;
    inc(f_packetsReceived);
    //
    case (selector) of

      unavcl_packet_selector01_data: begin
	dataLen := (((f_packet.r_selector shr unavcl_packet_selector01_high6bitsSize_shift) and unavcl_packet_selector01_high6bitsSize_mask) shl 8) + f_packet.r_union.r_01_lowSize;
      end;

      unavcl_packet_selector11_custom: begin
	dataLen := f_packet.r_union.r_11_customSize;
      end;

      else begin
	dataLen := 0;
      end;

    end;

    rawSize := calcPacketRawSize(selector, dataLen);
    if (rawSize = size) then begin

      crc8Original := f_packet.r_crc8;
      f_packet.r_crc8 := 0;
      crcOK := (crc8Original = crc8(f_packet, rawSize));

      if (crcOK) then
	//
	case (selector) of

	  unavcl_packet_selector00_format: begin
	    // check if we need to apply new format
	    formatChanged := (0 <> ((f_packet.r_selector shr unavcl_packet_selector00_formatChanges_shift) and unavcl_packet_selector00_formatChanges_mask));
	    formatIndex := ((f_packet.r_selector shr unavcl_packet_selector00_formatIndex_shift) and unavcl_packet_selector00_formatIndex_mask);
	    if (formatChanged or (f_formatIndex <> formatIndex)) then begin
	      //
	      f_waveFormatTag := f_packet.r_union.r_00_formatTag;
	      f_waveSamplesPerSec := f_packet.r_union.r_00_samplingRate;
	      f_waveNumBits := f_packet.r_union.r_00_numBits;
	      f_waveNumChannels := f_packet.r_union.r_00_numChannels;
	      //
	      checkIfFormatProvider(true);
	      //
	      if ((nil <> consumer) and not (csDestroying in consumer.ComponentState)) then begin
		//
		// we do not care about chunk size
		f_chunkSize := 0; //unavclInOutWavePipe(consumer).chunkSize;
		if (f_subDataBufSize < f_chunkSize) then begin
		  //
		  mrealloc(f_subDataBuf, f_chunkSize);
		  f_subDataBufSize := f_chunkSize;
		end;
	      end
	      else
		f_chunkSize := 0;
	      //
	      f_subData.clear();
	      f_formatIndex := formatIndex;
	    end;
	  end;

	  unavcl_packet_selector01_data: begin
	    //
	    formatIndex :=  ((f_packet.r_union.r_01_streamChannel shr unavcl_union01_channelFormatIndex_shift) and unavcl_union01_channelFormatIndex_mask);
	    if (f_formatIndex = formatIndex) then begin
	      //
	      streamSeqNum := ((f_packet.r_union.r_01_streamChannel shr unavcl_union01_channelSeqNum_shift) and unavcl_union01_channelSeqNum_mask);
	      if ((f_channelSeqNum = $FFFFFFFF) or (streamSeqNum = f_channelSeqNum)) then begin
		//
		streamMedia :=  ((f_packet.r_union.r_01_streamChannel shr unavcl_union01_channelMedia_shift) and unavcl_union01_channelMedia_mask);
		case (streamMedia) of

		  unavcl_union01_channelMedia_audio: begin
		    //
		    // check if we have full chunk here
		    if ((0 < f_chunkSize) and (dataLen < f_chunkSize)) then begin
		      //
		      if (0 <> (f_packet.r_union.r_01_streamChannel and unavcl_union01_channelMedia_newChunkFlag)) then	// new chunk?
			f_subData.clear();
		      //
		      f_subData.write(@f_packet.r_union.r_01_data, dataLen);
		      //
		      if (int(f_chunkSize) <= f_subData.getSize()) then
			// feed one chunk
			onNewData(f_subDataBuf, f_subData.read(f_subDataBuf, int(f_chunkSize)));
		    end
		    else begin
		      //
		      // do not care
		      //
		      if (0 < f_subData.getSize()) then
			// feed what we have so far
			onNewData(f_subDataBuf, f_subData.read(f_subDataBuf, int(f_chunkSize)));
		      //
		      onNewData(@f_packet.r_union.r_01_data, dataLen);
		    end;
		  end;

		end;
	      end
	      else
		inc(f_packetsLost);
	      //
	      // go to next packet seq#
	      f_channelSeqNum := (streamSeqNum + 1) and unavcl_union01_channelSeqNum_mask;
	    end;
	  end;

	  unavcl_packet_selector11_custom: begin
	    // TO DO: add onCustomData event here
	  end;

	end;
    end;
    //
  end;
  //
  f_packet := nil;
end;


{$IFDEF VC_LIC_PUBLIC }
{$ELSE }


{ unavclSTUNBase }

// --  --
procedure unavclSTUNBase.AfterConstruction();
begin
  inherited;
  //
  port := int2str(C_STUN_DEF_PORT);
  proto := unapt_UDP;
  bind2ip := '0.0.0.0';
end;

// --  --
procedure unavclSTUNBase.doClose();
begin
  inherited;
  //
  freeAndNil(f_agent);
end;

// --  --
function unavclSTUNBase.doOpen(): bool;
begin
  freeAndNil(f_agent);
  //
  if (inherited doOpen() and createAgent()) then begin
    //
    f_agent.open();
    result := true;
  end
  else
    result := false;
end;

// --  --
function unavclSTUNBase.isActive(): bool;
begin
  result := (nil <> f_agent) and (f_agent.status = unatsRunning);
end;

// --  --
procedure unavclSTUNBase.setProto(value: tunavclProtoType);
begin
  f_proto := value;
  //
  case (value) of

    unapt_UDP: f_stunProto := C_STUN_PROTO_UDP;
    unapt_TCP: f_stunProto := C_STUN_PROTO_TCP;

  end;
end;


type
  mySTUNClient = class(unaSTUNClient)
  private
    f_master: unavclSTUNClient;
  protected
    procedure onResponse4(r: unaSTUNClient_req; error: int; const ip4H: TIPv4H; port, boundPort: uint16); override;
  end;


{ mySTUNClient }

// --  --
procedure mySTUNClient.onResponse4(r: unaSTUNClient_req; error: int; const ip4H: TIPv4H; port, boundPort: uint16);
begin
  inherited;
  //
  f_master.doOnResponse(r, error, ip4H,  port, boundPort);
end;


{ unavclSTUNClient }

// --  --
procedure unavclSTUNClient.AfterConstruction();
begin
  f_bind2port := '0';
  f_useDNSSRV := true;
  //
  inherited;
end;

// --  --
function unavclSTUNClient.createAgent(): bool;
begin
  f_agent := mySTUNClient.create(host, f_stunProto, f_useDNSSRV, port, bind2ip);
  mySTUNClient(f_agent).bind2port := bind2port;
  mySTUNClient(f_agent).f_master := self;
  //
  result := true;
end;

// --  --
procedure unavclSTUNClient.doOnResponse(r: unaSTUNClient_req; error: int; mappedIP: uint32; mappedPort, boundPort: uint16);
begin
  if (assigned(f_onResponse)) then begin
    //
    f_lastResponse := r;
    try
      f_onResponse(self, error, mappedIP, mappedPort, boundPort);
    finally
      f_lastResponse := nil;
    end;
  end;
end;

// --  --
function unavclSTUNClient.getClient(): unaSTUNClient;
begin
  result := unaSTUNClient(f_agent);
end;

// --  --
function unavclSTUNClient.req(method: int; attrs: pointer; attrsLen: int): int;
begin
  open();
  //
  if (nil <> client) then
    result := client.req(method, attrs, attrsLen)
  else
    result := -1;	// some problem with client
end;


{ unavclSTUNServer }

// --  --
function unavclSTUNServer.createAgent(): bool;
begin
  f_agent := unaSTUNserver.create(f_stunProto, port, bind2ip);
  unaSTUNserver(f_agent).onResponse := f_onResponse;
  //
  result := true;
end;

// --  --
function unavclSTUNServer.getNumReq(): int64;
begin
  if (nil <> server) then
    result := server.numRequests
  else
    result := 0;
end;

// --  --
function unavclSTUNServer.getServer(): unaSTUNServer;
begin
  result := unaSTUNServer(f_agent);
end;

// --  --
function unavclSTUNServer.getSocketError(): int;
begin
  if (nil <> server) then
    result := server.socketError
  else
    result := 0;
end;

// --  --
procedure unavclSTUNServer.setOnResponse(value: unaSTUNServerOnResponse);
begin
  f_onResponse := value;
  if (nil <> server) then
    server.onResponse := value;
end;



type
  {*
	Internal class to override the onAnswer method
  }
  myDNSClient = class(unaDNSClient)
  private
    f_master: unavclDNSClient;
  protected
    procedure onAnswer(query: unaDNSQuery); override;
  public
    constructor create(master: unavclDNSClient);
  end;


{ myDNSClient }

// --  --
constructor myDNSClient.create(master: unavclDNSClient);
begin
  f_master := master;
  //
  inherited create();
end;

// --  --
procedure myDNSClient.onAnswer(query: unaDNSQuery);
begin
  inherited;
  //
  f_master.doOnAnswer(query);
end;


{ unavclDNSClient }

// --  --
procedure unavclDNSClient.AfterConstruction();
begin
  f_cln := myDNSClient.create(self);
  //
  inherited;
end;

// --  --
procedure unavclDNSClient.BeforeDestruction();
begin
  inherited;
  //
  freeAndNil(f_cln);
end;

// --  --
procedure unavclDNSClient.doClose();
begin
  inherited;
  //
  client.stop();
end;

// --  --
procedure unavclDNSClient.doOnAnswer(query: unaDNSQuery);
begin
  if (assigned(f_onAnswer)) then begin
    //
    f_lastAnswer := query;
    f_onAnswer(self);
    f_lastAnswer := nil;	// query will be removed right after returning from this method
  end;
end;

// --  --
function unavclDNSClient.doOpen(): bool;
begin
  result := (nil <> client) and client.start();
end;

// --  --
function unavclDNSClient.getDNSServersList(): string;
begin
  if (nil <> client) then
    result := client.getDNSServersList()
  else
    result := '';
end;

// --  --
function unavclDNSClient.isActive(): bool;
begin
  result := (nil <> client) and (unatsRunning = client.status);
end;

{$ENDIF VC_LIC_PUBLIC }


initialization

// --  --
finalization
  // release global objects
  freeAndNil(g_socks);
end.

