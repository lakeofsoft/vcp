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
	  unaSocks_STUN.pas
	  STUN (RFC 5389)
	----------------------------------------------
	  Delphi implementation:
	  (c) 2012 Lake of Soft

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 16 Jan 2012

	  modified by:
		Lake, Jan-Feb 2012

	----------------------------------------------
*)

{$I unaDef.inc }

{$IFDEF DEBUG }
  {$DEFINE UNA_STUN_LOG_INFOS }		// define to log informational messages
  {$DEFINE UNA_STUN_LOG_ERRORS }	// define to log error messages
{$ENDIF DEBUG }

{*
	- STUN (RFC 5389)

	@Author Lake

	Version 2.5.2012.01 First release (UDP mostly)
}

unit
  unaSocks_STUN;

interface

uses
  Windows, WinSock,
  unaTypes, unaClasses, unaSockets, unaSocks_DNS;

const
  // transport
  C_STUN_PROTO_UDP	= 1;
  C_STUN_PROTO_TCP	= 2;
  C_STUN_PROTO_TLS	= 3;	// TODO: yep

  // classes
  C_STUN_CLASS_REQ		= 00;
  C_STUN_CLASS_INDICATION	= 01;
  C_STUN_CLASS_RESP_SUCCESS	= 02;
  C_STUN_CLASS_RESP_ERROR	= 03;

  //
  C_MAGIC_COOKIE		= $2112A442;
  C_FINGERPRINT_XOR		= $5354554e;

  // methods
  C_STUN_MSGTYPE_BINDING	= 01;

  // default port
  C_STUN_DEF_PORT		= 3478;
  C_STUN_DEF_PORT_TLS		= 5349;

  // attributes
  // Comprehension-required range (0x0000-0x7FFF):
  C_STUN_ATTR_Reserved                          = $0000;
  C_STUN_ATTR_MAPPED_ADDRESS                    = $0001;
  C_STUN_ATTR_Reserved_was_RESPONSE_ADDRESS	= $0002;
  C_STUN_ATTR_Reserved_was_CHANGE_ADDRESS       = $0003;
  C_STUN_ATTR_Reserved_was_SOURCE_ADDRESS       = $0004;
  C_STUN_ATTR_Reserved_was_CHANGED_ADDRESS      = $0005;
  C_STUN_ATTR_USERNAME				= $0006;
  C_STUN_ATTR_Reserved_was_PASSWORD		= $0007;
  C_STUN_ATTR_MESSAGE_INTEGRITY			= $0008;
  C_STUN_ATTR_ERROR_CODE			= $0009;
  C_STUN_ATTR_UNKNOWN_ATTRIBUTES		= $000A;
  C_STUN_ATTR_Reserved_was_REFLECTED_FROM       = $000B;
  C_STUN_ATTR_REALM                             = $0014;
  C_STUN_ATTR_NONCE                             = $0015;
  C_STUN_ATTR_XOR_MAPPED_ADDRESS                = $0020;
  //
  // Comprehension-optional range (0x8000-0xFFFF)
  C_STUN_ATTR_SOFTWARE                          = $8022;
  C_STUN_ATTR_ALTERNATE_SERVER                  = $8023;
  C_STUN_ATTR_FINGERPRINT                       = $8028;

  // error codes
  C_STUN_ERR_ALTERNATE		= 300; // Try Alternate
  C_STUN_ERR_BAD_REQUEST	= 400; // Bad Request
  C_STUN_ERR_UNAUTHORIZED	= 401; // Unauthorized
  C_STUN_ERR_UNKNOWN_ATTR	= 420; // Unknown Attribute
  C_STUN_ERR_STALE_NONCE	= 438; // Stale Nonce
  C_STUN_ERR_SERVER_ERROR	= 500; // Server Error

  //
  C_INITIAL_RTO		= 1000;	// 1 second
  C_TOTAL_Rc		= 5;	// number of re-trasmits before give-up


type
  {*
	STUN message header
  }
  punaSTUN_hdr = ^unaSTUN_hdr;
  unaSTUN_hdr = packed record
    //
    r_msgType: uint16;
    r_msgLen: uint16;
    r_cookie: uint32;
    r_transactionID: array[0..11] of byte;
  end;

  {*
	STUN attribute header
  }
  punaSTUN_attrHdr = ^unaSTUN_attrHdr;
  unaSTUN_attrHdr = packed record
    //
    r_attrType: uint16;
    r_attrLen: uint16;
    r_value: record end;
  end;

  {*
	MAPPED-ADDRESS attr
  }
  punaSTUN_MAPPED_ADDRESS_attr = ^unaSTUN_MAPPED_ADDRESS_attr;
  unaSTUN_MAPPED_ADDRESS_attr = packed record
    //
    r_hdr: unaSTUN_attrHdr;
    r_family: uint16;
    r_port: uint16;
    r_address: record end;	// (32 bits or 128 bits)
  end;

  {*
	XOR-MAPPED-ADDRESS attr
  }
  punaSTUN_XOR_MAPPED_ADDRESS_attr = ^unaSTUN_XOR_MAPPED_ADDRESS_attr;
  unaSTUN_XOR_MAPPED_ADDRESS_attr = packed record
    //
    r_hdr: unaSTUN_attrHdr;
    r_family: uint16;
    r_x_port: uint16;
    r_x_address: record end;	// (32 bits or 128 bits)
  end;

  {*
	USERNAME attr
  }
  punaSTUN_USERNAME_attr = ^unaSTUN_USERNAME_attr;
  unaSTUN_USERNAME_attr = packed record
    //
    r_hdr: unaSTUN_attrHdr;
    r_username: record end;
  end;

  {*
	MESSAGE-INTEGRITY attr
  }
  punaSTUN_MESSAGE_INTEGRITY_attr = ^unaSTUN_MESSAGE_INTEGRITY_attr;
  unaSTUN_MESSAGE_INTEGRITY_attr = packed record
    //
    r_hdr: unaSTUN_attrHdr;
    r_msg: record end;
  end;

  {*
	FINGERPRINT attr
  }
  punaSTUN_FINGERPRINT_attr = ^unaSTUN_FINGERPRINT_attr;
  unaSTUN_FINGERPRINT_attr = packed record
    //
    r_hdr: unaSTUN_attrHdr;
    r_fingerprint: record end;
  end;

  {*
	ERROR-CODE attr
  }
  punaSTUN_ERROR_CODE_attr = ^unaSTUN_ERROR_CODE_attr;
  unaSTUN_ERROR_CODE_attr = packed record
    //
    r_hdr: unaSTUN_attrHdr;
    r_zero: uint16;
    r_class_number: uint16;
    r_reason: record end;	// variable len UTF-8 string
  end;

  {*
	REALM attr
  }
  punaSTUN_REALM_attr = ^unaSTUN_REALM_attr;
  unaSTUN_REALM_attr = packed record
    //
    r_hdr: unaSTUN_attrHdr;
    r_realm: record end;
  end;

  {*
	NONCE attr
  }
  punaSTUN_NONCE_attr = ^unaSTUN_NONCE_attr;
  unaSTUN_NONCE_attr = packed record
    //
    r_hdr: unaSTUN_attrHdr;
    r_nonce: record end;
  end;

  {*
	UNKNOWN-ATTRIBUTES attr
  }
  punaSTUN_UNKNOWN_ATTRIBUTES_attr = ^unaSTUN_UNKNOWN_ATTRIBUTES_attr;
  unaSTUN_UNKNOWN_ATTRIBUTES_attr = packed record
    //
    r_hdr: unaSTUN_attrHdr;
    r_unknown_attr_list: array[0..0] of uint16;
  end;

  {*
	SOFTWARE attr
  }
  punaSTUN_SOFTWARE_attr = ^unaSTUN_SOFTWARE_attr;
  unaSTUN_SOFTWARE_attr = packed record
    //
    r_hdr: unaSTUN_attrHdr;
    r_software: record end;
  end;

  {*
	ALTERNATE-SERVER attr
  }
  punaSTUN_ALTERNATE_SERVER_attr = ^unaSTUN_ALTERNATE_SERVER_attr;
  unaSTUN_ALTERNATE_SERVER_attr = packed record
    //
    r_hdr: unaSTUN_attrHdr;
    r_alt_server: record end;
  end;


type
  {*
	STUN base agent
  }
  unaSTUNagent = class(unaThread)
  private
    f_socket: unaSocket;
    f_active: bool;
    //
    f_port: string;
    f_bind2ip: string;
    f_proto: int;
    //
    f_socketError: int;
    //
    procedure createSocket();
  protected
    {*
	Prepares socket
    }
    procedure startIn(); override;
    {*
    }
    function execute(threadID: unsigned): int; override;
    //
    {*
	Prepare for open.
    }
    procedure doOpen(); virtual;
    {*
	Reads data from internal or exteranal socket(s)
	Client and server will do it differently.

	@param buf buffer to read data into
	@param maxSize size of buffer
	@param addr OUT UDP ONLY: remote address

	@return Size of data actually read
    }
    function readData(buf: pointer; maxSize: int; out addr: sockaddr_in): int; virtual; abstract;
    {*
	Processes any pending job.

	@param buf ponter to data buffer
	@param dataLen size of data in buffer. Could be 0, which means no data was read in last cycle

	@return True if some job was done, or False if there was nothing to do
    }
    function doYourJob(addr: PSockAddrIn; buf: pointer; dataLen: int): bool; virtual; abstract;
  public
    {*
    }
    constructor create(proto: int = C_STUN_PROTO_UDP; port: string = ''; const bind2ip: string = '0.0.0.0');
    {*
    }
    destructor Destroy(); override;
    //
    {*
	Closes client or server.
    }
    procedure close();
    {*
	Opens client or server.
    }
    function open(): bool;
    //
    {*
	True if server or client is active.
    }
    property active: bool read f_active;
    {*
	Local server port for STUN Server
	Remote server port for STUN Client
    }
    property port: string read f_port;
    {*
	Fatal socket error or 0 if no error.
    }
    property socketError: int read f_socketError;
    {*
	Internal socket proto
    }
    property proto: int read f_proto;
  end;


  {*
	STUN Client server
  }
  unaSTUNClient_server = class(unaObject)
  private
    f_priority: unsigned;
    f_weight: unsigned;
    f_shost: string;
    f_sport: string;
  public
    constructor create(const shost, sport: string; priority, weight: unsigned);
    //
    property shost: string read f_shost;
    property sport: string read f_sport;
    property priority: unsigned read f_priority;
    property weight: unsigned read f_weight;
  end;


  {*
	STUN Client request
  }
  unaSTUNClient_req = class(unaObject)
  private
    f_data: punaSTUN_hdr;
    f_dataRawLen: int;
    //
    f_sentTM: uint64;	// when this packet was sent last time
    f_sentCount: int;	// how many time this req was sent
    //
    f_socket: unaSocket;
    f_event: tHandle;
    //
    f_response: punaSTUN_hdr;
    //
    f_fatalError: bool;
  public
    {*
    }
    constructor create(method: int; attrs: pointer; len: int; socket: unaSocket = nil; event: tHandle = 0);
    {*
    }
    destructor Destroy(); override;
    //
    {*
	Check if hdr has same transaction ID as request
	If same, will also store hdr as response

	@param hdr response
	@return True if transaction id is the same
    }
    function sameTrans(hdr: punaSTUN_hdr): bool;
    {*
	Original request
    }
    property request: punaSTUN_hdr read f_data;
    {*
	Response
    }
    property response: punaSTUN_hdr read f_response;
    {*
	True if no response was received and some fatal error occured (like server is down)
    }
    property fatalError: bool read f_fatalError;
    {*
	External socket
    }
    property socket: unaSocket read f_socket;
    {*
	Event to set when response is received
    }
    property event: tHandle read f_event;
  end;

  {*
	STUN client
  }
  unaSTUNclient = class(unaSTUNagent)
  private
    f_defHost: string;
    f_defPort: string;
    f_bind2port: string;
    //
    f_useDNSSRV: bool;
    //
    f_dns: unaDNSClient;
    f_srvList: unaObjectList;
    f_srvBrokenList: unaList;	// list of broken services (indexes in f_srvList)
    f_dnsDone: bool;
    f_srvAddr: sockaddr_in;
    f_srvIndex: int;
    f_haveTriedRootSrv: bool;
    //
    f_requests: unaObjectList;
    //
    f_host: string;
    //
    f_noJobTM: uint64;
    //
    procedure checkRR(rr: unaDNSRR);
    {*
	Locates next server and assigns host/port accordingly
    }
    function nextServer(): int;
    {*
    }
    procedure notifyResponse(r: unaSTUNClient_req);
  protected
    {*
	Handle DNS responses if using SRV records
    }
    procedure startIn(); override;
    {*
	Cleans up
    }
    procedure startOut(); override;
    {*
	Issue DNSSRV lookup if needed.
    }
    procedure doOpen(); override;
    {*
	Send pending requests
    }
    function doYourJob(addr: PSockAddrIn; buf: pointer; dataLen: int): bool; override;
    {*
	Reads data from socket(s)
    }
    function readData(buf: pointer; maxSize: int; out addr: sockaddr_in): int; override;
    {*
	Got DNS reply
    }
    procedure onDNSAnswer(query: unaDNSQuery); virtual;
    {*
	Got STUN response, IPv4 address
    }
    procedure onResponse4(r: unaSTUNClient_req; error: int; const ip4H: TIPv4H; port, boundPort: uint16); virtual;
    {*
	Got STUN response, IPv6 address
    }
    procedure onResponse6(r: unaSTUNClient_req; error: int; const ip6H: TIPV6H; port, boundPort: uint16); virtual;
  public
    {*
	Creates STUN client

	@param host remote host
	@param proto UDP/TCP
	@param useDNSSRV Issue DNS SRV query if True, otherwise use provided host/port
	@param port remote server port number. If useDNSSRV is false, default port value is C_STUN_DEF_PORT
	@param bind2ip bind client socket to this IP
    }
    constructor create(const host: string; proto: int = C_STUN_PROTO_UDP; useDNSSRV: bool = true; const port: string = ''; const bind2ip: string = '0.0.0.0');
    {*
	Destroys STUN Client object
    }
    destructor Destroy(); override;
    //
    {*
	Sends a request to remote server.

	@param method method to use, default is C_STUN_MSGTYPE_BINDING
	@param attrs pointer to additional attributes to send
	@param attrsLen size of additional attributes
	@param socket Use this socket instead of internal one
	@param event set this event when request is notified

	@return internal index of request ( > 0), or -1 in case of some error
    }
    function req(method: int = C_STUN_MSGTYPE_BINDING; attrs: pointer = nil; attrsLen: int = 0; socket: unaSocket = nil; event: tHandle = 0): int;
    //
    {*
	Remote STUN server host.
    }
    property host: string read f_host;
    {*
	Bind client to this port.
    }
    property bind2port: string read f_bind2port write f_bind2port;
  end;


  {*
	Response event.
  }
  unaSTUNServerOnResponse	= procedure(sender: tObject; addr: PSockAddrIn; req: punaSTUN_hdr) of object;

  {*
	STUN server
  }
  unaSTUNserver = class(unaSTUNagent)
  private
    f_numReq: int64;
    //
    f_onResponse: unaSTUNServerOnResponse;
  protected
    {*
	Sends response to client

	@param addr For UDP only: source address
	@param r original request
	@param _class Response class
	@param attr Attribute to add
	@param datai Integer data for attribute. Meanign depends on attribute
	@param datas String data for attribute. Meanign depends on attribute
    }
    procedure sendResponse(addr: PSockAddrIn; r: punaSTUN_hdr; _class, attr, datai: uint; const datas: wString; msg: int = C_STUN_MSGTYPE_BINDING); overload;
    {*
	Sends response to client

	@param addr For UDP only: source address
	@param r original request
	@param _class Response class
	@param attrs Attributes to add
	@param attrsLen Size of all attributes
    }
    procedure sendResponse(addr: PSockAddrIn; r: punaSTUN_hdr; _class: int; attrs: pointer; attrsLen: int; msg: int = C_STUN_MSGTYPE_BINDING); overload;
    {*
	Start listening
    }
    procedure startIn(); override;
    {*
	Process clients' requests
    }
    function doYourJob(addr: PSockAddrIn; buf: pointer; dataLen: int): bool; override;
    {*
	Reads data from server TCP socket
    }
    function readData(buf: pointer; maxSize: int; out addr: sockaddr_in): int; override;
    {*
	Notifies of response
    }
    procedure doOnResponse(addr: PSockAddrIn; req: punaSTUN_hdr);
  public
    {*
	Number of requsts handled by server
    }
    property numRequests: int64 read f_numReq;
    {*
    }
    property onResponse: unaSTUNServerOnResponse read f_onResponse write f_onResponse;
  end;


{*
	Performs synchronous mapping.

	@param host STUN server host name/IP address
	@param port STUN server port. Default is '', whihc is same as C_STUN_DEF_PORT
	@param mip OUT: mapped IPv4
	@param mport OUT: mapped port
	@param boundPort OUT: port the STUN client was bound to when performing mapping
	@param proto Transport to use, default is C_STUN_PROTO_UDP
	@param timeout Wait this amount of ms before reporting failure
	@param useDNSSRV use DNS SRV lookup to find STUN server
	@param socket use this socket instead of internal one, default is nil, which means use internal socket
	@param bind2ip Bind internal socket to this IP (not used if external socket is specified)
	@param _bind2port Bind internal socket to this port (not used if external socket is specified)

	@return True if mapping was successfull
}
function getMappedIPPort4(const host: string; out mipH: TIPv4H; out mport, boundPort: uint16; const port: string = ''; proto: int = C_STUN_PROTO_UDP; timeout: tTimeout = 20000; useDNSSRV: bool = true; socket: unaSocket = nil; const bind2ip: string = '0.0.0.0'; const _bind2port: string = '0'): bool;


implementation


uses
  unaUtils, unaHash;


// -- STUN utility function --

type
  mySTUNClient = class(unaSTUNclient)
  private
    f_error: int;
    f_ip4: TIPv4H;
    f_port,
    f_boundPort: uint16;
  protected
    procedure onResponse4(r: unaSTUNClient_req; error: int; const ip4H: TIPv4H; port, boundPort: uint16); override;
  end;

{ mySTUNClient }

// --  --
procedure mySTUNClient.onResponse4(r: unaSTUNClient_req; error: int; const ip4H: TIPv4H; port, boundPort: uint16);
begin
  inherited;
  //
  f_error := error;
  if (200 = error) then begin
    //
    f_ip4 := ip4H;
    f_port := port;
    f_boundPort := boundPort;
  end;
end;

// --  --
function getMappedIPPort4(const host: string; out mipH: TIPv4H; out mport, boundPort: uint16; const port: string; proto: int; timeout: tTimeout; useDNSSRV: bool; socket: unaSocket; const bind2ip, _bind2port: string): bool;
var
  event: unaEvent;
begin
  result := false;
  event := unaEvent.create();
  try
    with (mySTUNClient.create(host, proto, useDNSSRV, port, bind2ip)) do try
      //
      mySTUNClient(_this).bind2port := _bind2port;
      //
      if (0 <= req(1, nil, 0, socket, event.handle)) then begin	// async request
	//
	if (event.waitFor(timeout) and (200 = f_error)) then begin
	  //
	  mipH := f_ip4;
	  mport := f_port;
	  boundPort := f_boundPort;
	  //
	  result := true;
	end;
      end;
      //
    {$IFDEF UNA_STUN_LOG_INFOS }
      logMessage('getMappedIPPort4() - done, result=' + bool2strStr(result));
    {$ENDIF UNA_STUN_LOG_INFOS }
    finally
      free();
    end;
  finally
    freeAndNil(event);
  end;
end;


// -- DNS --

type
  {*
	Custom DNS Client
  }
  myDNSClient = class(unaDNSClient)
  private
    f_master: unaSTUNclient;
  protected
    procedure onAnswer(query: unaDNSQuery); override;
  end;


{ myDNSClient }

// --  --
procedure myDNSClient.onAnswer(query: unaDNSQuery);
begin
  inherited;
  //
  f_master.onDNSAnswer(query);
end;


// -- AGENT --

{ unaSTUNagent }

// --  --
procedure unaSTUNagent.close();
begin
  stop();
  //
  if (nil <> f_socket) then
    f_socket.close();
end;

// --  --
constructor unaSTUNagent.create(proto: int; port: string; const bind2ip: string);
begin
  f_proto := proto;
  f_port := port;
  f_bind2ip := bind2ip;
  //
  inherited create();
end;

// --  --
procedure unaSTUNagent.createSocket();
begin
  freeAndNil(f_socket);
  //
  case (proto) of

    C_STUN_PROTO_UDP: begin
      //
      f_socket := unaUDPSocket.create({$IFDEF VC25_OVERLAPPED }false{$ENDIF VC25_OVERLAPPED });
    end;

    C_STUN_PROTO_TCP: begin
      //
      f_socket.setPort(f_port);
      f_socket := unaTCPSocket.create({$IFDEF VC25_OVERLAPPED }false{$ENDIF VC25_OVERLAPPED });
    end;

  end;
  //
  f_socket.bindToIP := f_bind2ip;
end;

// --  --
destructor unaSTUNagent.Destroy();
begin
  close();
  //
  inherited;
  //
  freeAndNil(f_socket);
end;

// --  --
procedure unaSTUNagent.doOpen();
begin
  // not much here
  f_socketError := 0;
end;

// --  --
function unaSTUNagent.execute(threadID: unsigned): int;
var
  buf: array[0..4095] of byte;
  addr: sockaddr_in;
  dataLen: int;
begin
  f_active := (nil <> f_socket);
  //
  while (active and not shouldStop) do begin
    //
    dataLen := readData(@buf, sizeof(buf), addr);
    if (1 > dataLen) then
      dataLen := 0;
    //
    try
      if (not doYourJob(@addr, @buf, dataLen)) then
	sleepThread(100);
    except
      sleepThread(10);
    end;
  end;
  //
  result := 0;
  //
  f_active := false;
end;

// --  --
function unaSTUNagent.open(): bool;
begin
  if (not active) then begin
    //
    doOpen();
    //
    f_active := true;
    //
    result := start();
  end
  else
    result := true;
end;

// --  --
procedure unaSTUNagent.startIn();
begin
  inherited;
  //
  createSocket();
end;


// -- CLIENT --

{ unaSTUNClient_server }

// --  --
constructor unaSTUNClient_server.create(const shost, sport: string; priority, weight: unsigned);
begin
  inherited create();
  //
  f_shost := shost;
  f_sport := sport;
  f_priority := priority;
  f_weight   := weight;
  //
{$IFDEF UNA_STUN_LOG_INFOS }
  logMessage(className + '.create() - new server [' + shost + ':' + sport + '], prio=' + int2str(priority) + '; weight=' + int2str(weight));
{$ENDIF UNA_STUN_LOG_INFOS }
end;


{ unaSTUNClient_req }

// --  --
function methodClass2int(method, _class: uint16): uint16; {$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
begin
		      //0..3              //4..6                      //7..11
  result := (method and $F) or ((method and $70) shl 1) or ((method and $F80) shl 2) or
	    ((_class and $1) shl 4) or ((_class and $2) shl 7);
end;

// --  --
constructor unaSTUNClient_req.create(method: int; attrs: pointer; len: int; socket: unaSocket; event: tHandle);
var
  d: unaMD5digest;
begin
  inherited create();
  //
  f_socket := socket;
  f_event := event;
  //
  f_dataRawLen := sizeof(unaSTUN_hdr) + (len + 3) and not 3;
  f_data := malloc(f_dataRawLen);
  //
  f_data.r_msgType := swap16u( methodClass2int(C_STUN_MSGTYPE_BINDING, C_STUN_CLASS_REQ) );
  f_data.r_msgLen := swap16u( f_dataRawLen - sizeof(unaSTUN_hdr) );
  f_data.r_cookie := swap32u( C_MAGIC_COOKIE );
  //
  md5(aString(sysTime2str(nowUTC())), d);
  d[0] := d[0] xor d[15];
  d[2] := d[2] xor d[14];
  d[5] := d[5] xor d[13];
  d[9] := d[9] xor d[12];
  //
  move(d, f_data.r_transactionID, 12);	// 96 bits
  //
  if ((nil <> attrs) and (0 < len)) then
    move(attrs^, pArray(f_data)[sizeof(unaSTUN_hdr)], len);
  //
  f_sentCount := 0;	// not sent yet
  f_response := nil;
  f_fatalError := false;
end;

// --  --
destructor unaSTUNClient_req.Destroy();
begin
  inherited;
  //
  mrealloc(f_data);
end;

// --  --
function unaSTUNClient_req.sameTrans(hdr: punaSTUN_hdr): bool;
begin
  result := mcompare(@hdr.r_cookie, @f_data.r_cookie, 16);
  //
  if (result) then
    f_response := hdr;
end;


{ unaSTUNclient }

// --  --
procedure unaSTUNclient.checkRR(rr: unaDNSRR);
var
  srv: unaSTUNClient_server;
begin
  if ((nil <> rr) and not rr.isQuestion) then begin
    //
    case (rr.rtype) of

      c_DNS_TYPE_SRV:  with (rr.rdataObj as unaDNSRR_SRV) do begin
	//
      {$IFDEF UNA_STUN_LOG_INFOS }
	logMessage(className + '.checkRR() - got DNS SRV data');
      {$ENDIF UNA_STUN_LOG_INFOS }
	//
	with (rr.rdataObj as unaDNSRR_SRV) do
	  srv := unaSTUNClient_server.create(target, int2str(port), priority, weight);
	//
	f_srvList.add(srv);
      end;

    end;
  end;
end;

// --  --
constructor unaSTUNclient.create(const host: string; proto: int; useDNSSRV: bool; const port, bind2ip: string);
begin
  f_defHost := host;
  f_defPort := port;
  //
  f_useDNSSRV := useDNSSRV;
  //
  if (useDNSSRV) then begin
    //
    f_srvList := unaObjectList.create();
    f_srvBrokenList := unaList.create();
  end;
  //
  f_requests := unaObjectList.create();
  //
  inherited create(proto, port, bind2ip);
end;

// --  --
destructor unaSTUNclient.Destroy();
begin
  inherited;
  //
  freeAndNil(f_dns);
  freeAndNil(f_srvList);
  freeAndNil(f_srvBrokenList);
  //
  freeAndNil(f_requests);
end;

// --  --
procedure unaSTUNclient.doOpen();
begin
  inherited;
  //
  f_requests.clear();
  //
  if (f_useDNSSRV) then begin
    //
    f_dnsDone := false;
    f_srvList.clear();
    f_srvBrokenList.clear();
    //
    if (nil = f_dns) then begin
      //
      f_dns := myDNSClient.Create();
      myDNSClient(f_dns).f_master := self;
    end;
    //
    case (proto) of

      C_STUN_PROTO_UDP: f_dns.query('_stun._udp.' + f_defHost, c_DNS_TYPE_SRV);
      C_STUN_PROTO_TCP: f_dns.query('_stun._tcp.' + f_defHost, c_DNS_TYPE_SRV);

    end;
    //
  {$IFDEF UNA_STUN_LOG_INFOS }
    logMessage(className + '.doOpen() - sent DNS SRV query on ' + f_defHost);
  {$ENDIF UNA_STUN_LOG_INFOS }
  end
  else
    f_dnsDone := true;
end;

{$IFDEF UNA_STUN_LOG_INFOS }

// --  --
function id2str(hdr: punaSTUN_hdr): string;
begin
  result := int2str(hdr.r_cookie, 16) + ':' + byteArray2str(pArray(@hdr.r_transactionID), 12);
end;

{$ENDIF UNA_STUN_LOG_INFOS }

// --  --
function unaSTUNclient.doYourJob(addr: PSockAddrIn; buf: pointer; dataLen: int): bool;
var
  i: int32;
  r: unaSTUNClient_req;
  sendNow: bool;
  hdr: punaSTUN_hdr;
  willStop: bool;
  okData: bool;
  err: int;
begin
  result := false;
  hdr := nil;
  //
  willStop := (30000 < timeElapsed64U(f_noJobTM));
  //
  if (0 < dataLen) then begin
    //
    // got response
    //
    case (proto) of

      C_STUN_PROTO_UDP: begin
	// assuming the whole response is here
	hdr := buf;
      end;

      C_STUN_PROTO_TCP: begin
	// todo: collect the whole response before processing
	hdr := buf;
      end;

    end;
  end;
  //
  // send all pending requests
  if (lockNonEmptyList_r(f_requests, false, 10)) then try
    //
    for i := 0 to f_requests.count - 1 do begin
      //
      r := f_requests[i];
      if ((nil <> r) and (nil = r.response)) then begin
	//
	result := true;
	case (proto) of

	  C_STUN_PROTO_UDP: begin
	    //
	    sendNow := false;
	    //
	    // first time?
	    if (0 = r.f_sentCount) then
	      sendNow := true
	    else begin
	      // should we re-send it?
	      if (C_INITIAL_RTO * r.f_sentCount < timeElapsed64U(r.f_sentTM)) then begin
		//
		if (r.f_sentCount < C_TOTAL_Rc) then
		  sendNow := true
		else begin
		  //
		  // server seems to be dead, lookup next one
		  if (not f_haveTriedRootSrv) then begin
		    //
		    f_srvBrokenList.add(f_srvIndex);	// exclude this server from server lookup list
		    //
		    // get next server address
		    nextServer();
		    //
		    r.f_sentCount := 0;
		    //
		    sendNow := true;
		  end
		  else
		    r.f_fatalError := true;
		end;
	      end;
	    end;
	    //
	    if (sendNow) then begin
	      //
	      if (nil <> r.socket) then
		err := (r.socket as unaUDPSocket).sendto(f_srvAddr, r.f_data, r.f_dataRawLen, false)
	      else
		err := (f_socket as unaUDPSocket).sendto(f_srvAddr, r.f_data, r.f_dataRawLen, false);
	      //
	      if (0 = err) then begin
		//
	      {$IFDEF UNA_STUN_LOG_INFOS }
		logMessage(className + '.doYourJob() - send request (' + id2str(r.request) + ') to [' + addr2str(@f_srvAddr) + ']; RepeatCount=' + int2str(r.f_sentCount));
	      {$ENDIF UNA_STUN_LOG_INFOS }
              end
	      else begin
		//
	      {$IFDEF UNA_STUN_LOG_ERRORS }
		logMessage(className + '.doYourJob() - fail to send request (' + id2str(r.request) + ') to [' + addr2str(@f_srvAddr) + ']; RepeatCount=' + int2str(r.f_sentCount) + '; error code=' + int2str(err));
	      {$ENDIF UNA_STUN_LOG_ERRORS }
	      end;
	      //
	      r.f_sentTM := timeMarkU();
	      inc(r.f_sentCount);
	    end;
	  end;

	  C_STUN_PROTO_TCP: begin
	    //
	    sendNow := false;
	    //
	    // first time?
	    if (0 = r.f_sentCount) then
	      sendNow := true;
	    //
	    if (sendNow) then begin
	      //
	      (f_socket as unaTCPSocket).send(r.f_data, r.f_dataRawLen, false);
	      //
	      r.f_sentTM := timeMarkU();
	      inc(r.f_sentCount);
	    end;
	  end;

	end;
	//
	if (willStop or (0 < dataLen) or r.fatalError) then begin
	  //
	  // our response?
	  if (0 < dataLen) then
	    okData := r.sameTrans(hdr)
	  else
	    okData := false;
	  //
	  if (willStop or okData or r.fatalError) then begin
	    //
	    if (willStop) then
	      r.f_fatalError := True;
	    //
	    // notify response
	    notifyResponse(r);
	    //
	    //dataLen := 0;    yes, other requests must not match same transaction, but I think its better to continue lookup anyway
	  end;
	end;
	//
      end;
    end;
    //
    // remove notified/dead request
    i := 0;
    while (i < f_requests.count) do begin
      //
      r := f_requests[i];
      if (willStop or ((nil <> r) and ((nil <> r.response) or r.fatalError))) then begin
	//
      {$IFDEF UNA_STUN_LOG_INFOS }
	logMessage(className + '.doYourJob() - about to remove ' + choice(willStop or ((nil <> r) and r.fatalError), 'fatal', 'notified') + ' request (' + id2str(r.request) + '), index=' + int2str(i));
      {$ENDIF UNA_STUN_LOG_INFOS }
	//
	// request got response (or fatal error) and was notified, no need to keep it any longer
	f_requests.removeByIndex(i);
	//
	result := true;
      end
      else
	inc(i);
    end;
    //
  finally
    unlockListWO(f_requests);
  end;
  //
  if (not result) then begin
    //
    // idle for 30 seconds?
    if (willStop) then begin
      askStop();	// no need to run this thread anymore
      //
    {$IFDEF UNA_STUN_LOG_INFOS }
      logMessage(className + '.doYourJob() - idle too much, asked to stop the thread.');
    {$ENDIF UNA_STUN_LOG_INFOS }
    end;
  end
  else
    f_noJobTM := timeMarkU();
end;

// --  --
function unaSTUNclient.nextServer(): int;
var
  minp, minw: unsigned;
  foundp: bool;
  i: int32;
begin
  result := -1;
  if (f_useDNSSRV and (0 < f_srvList.count) and (f_srvBrokenList.count < f_srvList.count)) then begin
    //
    minp := $FFFF + 1;
    foundp := false;
    for i := 0 to f_srvList.count - 1 do
      if (0 > f_srvBrokenList.indexOf(i)) then
	if (unaSTUNClient_server(f_srvList[i]).priority < minp) then begin
	  //
	  minp := unaSTUNClient_server(f_srvList[i]).priority;
	  foundp := true;
	end;
    //
    if (foundp) then begin
      //
      minw := $FFFF + 1;
      for i := 0 to f_srvList.count - 1 do
	if (0 > f_srvBrokenList.indexOf(i)) then
	  with (unaSTUNClient_server(f_srvList[i])) do
	    //
	    if ((priority <= minp) and (weight < minw)) then begin
	      //
	      minw := weight;
	      result := i;
	    end;
    end;
  end;
  //
  if (0 <= result) then begin
    //
    with (unaSTUNClient_server(f_srvList[result])) do begin
      //
      f_host := shost;
      f_port := sport;
    end;
    //
  {$IFDEF UNA_STUN_LOG_INFOS }
    logMessage(className + '.nextServer() - found next server to try [' + f_host + ':' + f_port + ']');
  {$ENDIF UNA_STUN_LOG_INFOS }
  end
  else begin
    //
    f_haveTriedRootSrv := true;
    f_host := f_defHost;
    f_port := f_defPort;
  end;
  //
  f_srvIndex := result;
  //
  makeAddr(f_host, f_port, f_srvAddr);
end;

// --  --
procedure int2methodClass(data: uint16; out method, _class: uint16); {$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
begin
  _class := data and $110;
  _class := ((_class shr 4) and 1) or (_class shr 7);
  //
  method := (data and $F) or ((data and $E0) shr 1) or ((data and $3E00) shr 2);
end;

// --  --
procedure unaSTUNclient.notifyResponse(r: unaSTUNClient_req);
var
  attrh: punaSTUN_attrHdr;
  ma: punaSTUN_MAPPED_ADDRESS_attr;
  mxa: punaSTUN_XOR_MAPPED_ADDRESS_attr;
  e: punaSTUN_ERROR_CODE_attr;
  //
  ip4: uint32;
  port: uint16;
  error: int32;
  len: int;
  //
  method, _class: uint16;
  //
  addr: sockaddr_in;
begin
  ip4 := 0;
  port := 0;
  if (not r.fatalError and (nil <> r.response)) then begin
    //
    error := 200;
    //
    int2methodClass(swap16u(r.response.r_msgType), method, _class);
    case (_class) of

      C_STUN_CLASS_REQ: begin
	// shound not be here
	error := 400;
      end;

      C_STUN_CLASS_INDICATION: begin
	// some indication
      end;

      C_STUN_CLASS_RESP_SUCCESS: begin
	// OK
      end;

      C_STUN_CLASS_RESP_ERROR: begin
	// exact error will be notified via attribute
      end;

    end;
    //
    if (200 = error) then begin
      //
      // locate mapped attr attribute
      len := 0;
      attrh := punaSTUN_attrHdr(@pArray(r.response)[sizeof(unaSTUN_hdr)]);
      while (len + sizeof(unaSTUN_attrHdr) + 4 < swap16u(r.response.r_msgLen)) do begin
	//
	inc(len, sizeof(unaSTUN_attrHdr) + (swap16u(attrh.r_attrLen) + 3) and not 3);
	if (len <= swap16u(r.response.r_msgLen)) then begin
	  //
	  case swap16u(attrh.r_attrType) of

	    C_STUN_ATTR_MAPPED_ADDRESS: begin
	      //
	      ma := punaSTUN_MAPPED_ADDRESS_attr(attrh);
	      if (8 = swap16u(attrh.r_attrLen)) then begin
		//
		// IPv4
		move(ma.r_address, ip4, 4);
		ip4 := swap32u(ip4);
		port := swap16u(ma.r_port);
	      end;
	    end;

	    C_STUN_ATTR_XOR_MAPPED_ADDRESS: begin
	      //
	      mxa := punaSTUN_XOR_MAPPED_ADDRESS_attr(attrh);
	      if (8 = swap16u(attrh.r_attrLen)) then begin
		//
		// IPv4
		move(mxa.r_x_address, ip4, 4);
		ip4 := swap32u(ip4) xor swap32u(r.request.r_cookie);
		port := swap16u(mxa.r_x_port) xor (swap32u(r.request.r_cookie) shr 16);
	      end;
	    end;

	    C_STUN_ATTR_ERROR_CODE: begin
	      //
	      e := punaSTUN_ERROR_CODE_attr(attrh);
	      error := swap16u(e.r_class_number);
	      error := (error and $FF) + ((error and $700) shr 8) * 100;
	    end;

	  end;
	end;
	//
	inc(pByte(attrh), len);
      end;	// while () ..
    end;
  end
  else
    error := -1;	// fatal
  //
  if (nil <> r.socket) then
    r.socket.getSockAddrBound(addr)
  else
    f_socket.getSockAddrBound(addr);
  //
  onResponse4(r, error, ip4, port, swap16u(addr.sin_port));
  if (0 <> r.event) then
    SetEvent(r.event);
end;

// --  --
procedure unaSTUNclient.onDNSAnswer(query: unaDNSQuery);
var
  i: int32;
  hdr: punaDNS_HDR;
begin
{$IFDEF UNA_STUN_LOG_INFOS }
  logMessage(className + '.onDNSAnswer() - got some DNS reply');
{$ENDIF UNA_STUN_LOG_INFOS }
  //
  if (0 = query.status) then begin
    //
    hdr := query.resp;
    if (0 <> (swap16u(hdr.r_QR_OPCODE_AATCRD_RA_Z_RCODE) and c_DNS_HDR_ISRESPONSE_MASK)) then begin
      //
      for i := 0 to swap16u(hdr.r_ANCOUNT) - 1 do
	checkRR(query.AN[i]);
      //
      for i := 0 to swap16u(hdr.r_NSCOUNT) - 1 do
	checkRR(query.NS[i]);
      //
      for i := 0 to swap16u(hdr.r_ARCOUNT) - 1 do
	checkRR(query.AR[i]);
    end;
  end;
  //
  f_dnsDone := true;	// no matter what DNS says, its done for now
end;

// --  --
procedure unaSTUNclient.onResponse4(r: unaSTUNClient_req; error: int; const ip4H: TIPv4H; port, boundPort: uint16);
begin
  // override to be notified
  //
{$IFDEF UNA_STUN_LOG_INFOS }
  logMessage(className + '.onResponse() - got STUN IPV4 response, err=' + int2str(error) + '; ip4=' + ipH2str(ip4H) + '; mport=' + int2str(port) + '; bport=' + int2str(boundPort));
{$ENDIF UNA_STUN_LOG_INFOS }
end;

// --  --
procedure unaSTUNclient.onResponse6(r: unaSTUNClient_req; error: int; const ip6H: TIPv6H; port, boundPort: uint16);
begin
  // override to be notified
  //
{$IFDEF UNA_STUN_LOG_INFOS }
  logMessage(className + '.onResponse() - got STUN IPV6 response');
{$ENDIF UNA_STUN_LOG_INFOS }
end;

// --  --
function unaSTUNclient.readData(buf: pointer; maxSize: int; out addr: sockaddr_in): int;
var
  sz: uint;
  i: int32;
  r: unaSTUNClient_req;
begin
  result := 0;
  //
  case (proto) of

    C_STUN_PROTO_UDP: begin
      //
      // send all pending requests
      if (lockNonEmptyList_r(f_requests, true, 10)) then try
	//
	for i := 0 to f_requests.count - 1 do begin
	  //
	  r := f_requests[i];
	  if ((nil <> r) and (nil = r.response) and (nil <> r.socket) and (r.socket is unaUDPSocket)) then begin
	    //
	  {$IFDEF UNA_STUN_LOG_INFOS }
	    logMessage(className + '.readData() - tryin to read UDP data from external socket...');
	  {$ENDIF UNA_STUN_LOG_INFOS }
	    result := (r.socket as unaUDPSocket).recvfrom(addr, buf, maxSize, false, 0, 20);
	    if (0 < result) then begin
	      //
	    {$IFDEF UNA_STUN_LOG_INFOS }
	      logMessage(className + '.readData() - got UDP data from external, len=' + int2str(result));
	    {$ENDIF UNA_STUN_LOG_INFOS }
	      //
	      break;	// handle this data
	    end;
	  end;
	end;
	//
      finally
	unlockListRO(f_requests);
      end;
      //
      // no data received from exteranl sockets? try internal
      if (1 > result) then begin
	//
	result := (f_socket as unaUDPSocket).recvfrom(addr, buf, maxSize, false, 0, 10);
	//
	if (0 < result) then begin
	  //
	{$IFDEF UNA_STUN_LOG_INFOS }
	  logMessage(className + '.readData() - got STUN UDP data from external, len=' + int2str(result));
	{$ENDIF UNA_STUN_LOG_INFOS }
        end;
      end;
    end;

    C_STUN_PROTO_TCP: begin
      //
      sz := maxSize;
      if (0 = (f_socket as unaTCPSocket).read(buf, sz, 10)) then
	result := sz
      else
	result := 0;
    end;

  end;
end;

// --  --
function unaSTUNclient.req(method: int; attrs: pointer; attrsLen: int; socket: unaSocket; event: tHandle): int;
begin
  if (open()) then begin
    //
    result := f_requests.add(unaSTUNClient_req.create(method, attrs, attrsLen, socket, event));
    //
  {$IFDEF UNA_STUN_LOG_INFOS }
    logMessage(className + '.req() - added new request');
  {$ENDIF UNA_STUN_LOG_INFOS }
  end
  else
    result := -1;
end;

// --  --
procedure unaSTUNclient.startIn();
var
  saneTM: uint64;
begin
  if (f_useDNSSRV) then begin
    //
    saneTM := timeMarkU();
    //
    // wait up to 40sec till DNS is complete
    while (not shouldStop and not f_dnsDone and (40000 > timeElapsedU(saneTM))) do
      sleepThread(100);
  end;
  //
  f_haveTriedRootSrv := false;
  nextServer();
  //
  inherited;	// prepares socket
  //
  // connect to remote host
  case (proto) of

    C_STUN_PROTO_UDP: begin
      //
      f_socket.bindToPort := bind2port;
      f_socket.bind();
    end;

    C_STUN_PROTO_TCP: f_socket.connect(@f_srvAddr);

  end;
  //
  f_noJobTM := timeMarkU();
end;

// --  --
procedure unaSTUNclient.startOut();
begin
  inherited;
  //
  if (nil <> f_srvBrokenList) then
    f_srvBrokenList.clear();
end;


// -- SERVER --

{ unaSTUNserver }

// --  --
procedure unaSTUNserver.doOnResponse(addr: PSockAddrIn; req: punaSTUN_hdr);
begin
  if (assigned(f_onResponse)) then
    f_onResponse(self, addr, req);
end;

// --  --
function unaSTUNserver.doYourJob(addr: PSockAddrIn; buf: pointer; dataLen: int): bool;
var
  hdr: punaSTUN_hdr;
  method, _class: uint16;
begin
  result := false;
  //
  if (0 < dataLen) then begin
    //
    inc(f_numReq);
    //
{$IFDEF UNA_STUN_LOG_INFOS }
  logMessage(className + '.doYourJob() - got STUN request');
{$ENDIF UNA_STUN_LOG_INFOS }
    //
    case (proto) of

      C_STUN_PROTO_UDP: ; // assuming full request is here

      C_STUN_PROTO_TCP: ; // todo: make sure to collect the whole packet

    end;
    //
    hdr := buf;
    if ((0 = ($C000 and hdr.r_msgType)) and (0 = swap16u(hdr.r_msgLen) and $3)) then begin
      //
      int2methodClass(swap16u(hdr.r_msgType), method, _class);
      //
      result := true;
      case (_class) of

	C_STUN_CLASS_REQ: case (method) of

	  C_STUN_MSGTYPE_BINDING: begin
	    //
	    // todo: process attributes
	    //
	    doOnResponse(addr, hdr);
	    //
	    // send response
	    if (C_MAGIC_COOKIE <> swap32u(hdr.r_cookie)) then
	      sendResponse(addr, hdr, C_STUN_CLASS_RESP_SUCCESS, C_STUN_ATTR_MAPPED_ADDRESS,     swap16u(addr.sin_port), ipN2str(addr^))
	    else
	      sendResponse(addr, hdr, C_STUN_CLASS_RESP_SUCCESS, C_STUN_ATTR_XOR_MAPPED_ADDRESS, swap16u(addr.sin_port), ipN2str(addr^));
	  end;

	  else
	    sendResponse(addr, hdr, C_STUN_CLASS_RESP_ERROR, C_STUN_ATTR_ERROR_CODE, 400, 'Uknown method: ' + int2str(method));

	end;

	C_STUN_CLASS_INDICATION: begin
	  //
	  // some indication, dont care
	end;

	else
	  sendResponse(addr, hdr, C_STUN_CLASS_RESP_ERROR, C_STUN_ATTR_ERROR_CODE, 400, 'Wrong class: ' + int2str(_class));

      end;
    end
    else
      sendResponse(addr, hdr, C_STUN_CLASS_RESP_ERROR, C_STUN_ATTR_ERROR_CODE, 400, 'Malformed request');
  end;
end;

// --  --
function unaSTUNserver.readData(buf: pointer; maxSize: int; out addr: sockaddr_in): int;
begin
  case (proto) of

    C_STUN_PROTO_UDP: begin
      //
      result := (f_socket as unaUDPSocket).recvfrom(addr, buf, maxSize, false, 0, 10);
    end;

    C_STUN_PROTO_TCP: begin
      // TODO: read data from all connected tcp clients
      result := 0;
    end;

    else
      result := 0;

  end;
end;

// --  --
procedure unaSTUNserver.sendResponse(addr: PSockAddrIn; r: punaSTUN_hdr; _class, attr, datai: uint; const datas: wString; msg: int);
var
  ma: punaSTUN_MAPPED_ADDRESS_attr;
  mxa: punaSTUN_XOR_MAPPED_ADDRESS_attr;
  ea: punaSTUN_ERROR_CODE_attr;
  ipN: TIPv4N;
  a: pointer;
  len: int;
  datas8: aString;
begin
  a := nil;
  len := 0;
  //
  case (attr) of

    C_STUN_ATTR_MAPPED_ADDRESS: begin
      //
      len := sizeof(unaSTUN_MAPPED_ADDRESS_attr) + 4;	// IPv4
      ma := malloc(len, true, 0);
      //
      ma.r_hdr.r_attrType := swap16u(attr);
      ma.r_hdr.r_attrLen := swap16u(8);	// IPv4
      ma.r_family := swap16u(1);
      ma.r_port := swap16u(datai);
      ipN := str2ipN(datas);
      move(ipN, ma.r_address, 4);	// IPv4
      //
      a := ma;
    end;

    C_STUN_ATTR_XOR_MAPPED_ADDRESS: begin
      //
      len := sizeof(unaSTUN_XOR_MAPPED_ADDRESS_attr) + 4;	// IPv4
      mxa := malloc(len, true, 0);
      //
      mxa.r_hdr.r_attrType := swap16u(attr);
      mxa.r_hdr.r_attrLen := swap16u(8);	// IPv4
      mxa.r_family := swap16u(1);
      mxa.r_x_port := swap16u( datai xor (swap32u(r.r_cookie) shr 16));
      //
      ipN := ipH2ipN(str2ipH(datas) xor swap32u(r.r_cookie));	// IPv4
      move(ipN, mxa.r_x_address, 4);				// IPv4
      //
      a := mxa;
    end;

    C_STUN_ATTR_ERROR_CODE: begin
      //
      datas8 := UTF162UTF8(copy(datas, 1, 128));
      len := sizeof(unaSTUN_ERROR_CODE_attr) + length(datas8);
      //
      ea := malloc(len, true, 0);
      ea.r_hdr.r_attrType := swap16u(attr);
      ea.r_hdr.r_attrLen := swap16u(4 + length(datas8));
      ea.r_class_number := swap16u( (datai mod 100) or (((datai div 100) and 7) shl 8) );
      //
      if ('' <> datas8) then
	move(datas8[1], ea.r_reason, length(datas8));
      //
      a := ea;
      //
    {$IFDEF UNA_STUN_LOG_INFOS }
      logMessage(className + '.sendResponse() - sending error ' + int2str(datai) + ', reason: <' + datas + '>');
    {$ENDIF UNA_STUN_LOG_INFOS }
    end;

  end;
  //
  try
    sendResponse(addr, r, _class, a, len, msg);
  finally
    mrealloc(a);
  end;
end;

// --  --
procedure unaSTUNserver.sendResponse(addr: PSockAddrIn; r: punaSTUN_hdr; _class: int; attrs: pointer; attrsLen: int; msg: int);
var
  hdr: punaSTUN_hdr;
  dataRawLen: int;
  err: int;
begin
  dataRawLen := sizeof(unaSTUN_hdr) + (attrsLen + 3) and not 3;
  hdr := malloc(dataRawLen, true, 0);
  try
    //
    hdr.r_msgType := swap16u( methodClass2int(msg, _class) );
    hdr.r_msgLen  := swap16u( dataRawLen - sizeof(unaSTUN_hdr) );
    hdr.r_cookie  := r.r_cookie;
    move(r.r_transactionID, hdr.r_transactionID, sizeof(hdr.r_transactionID));
    //
    if ((nil <> attrs) and (0 < attrsLen)) then
      move(attrs^, pArray(hdr)[sizeof(unaSTUN_hdr)], attrsLen);
    //
    case (proto) of

      C_STUN_PROTO_UDP: err := (f_socket as unaUDPSocket).sendto(addr^, hdr, dataRawLen, 0, 100);

      C_STUN_PROTO_TCP: err := (f_socket as unaTCPSocket).send(hdr, dataRawLen, false);

      else
	err := -3;	// unknown/unsupported transport

    end;
    //
    if (0 = err) then begin
      //
    {$IFDEF UNA_STUN_LOG_INFOS }
      logMessage(className + '.sendResponse() - sent STUN response to ' + addr2str(addr));
    {$ENDIF UNA_STUN_LOG_INFOS }
    end
    else begin
      //
    {$IFDEF UNA_STUN_LOG_ERRORS }
      logMessage(className + '.sendResponse() - unable to sent STUN response, error=' + int2str(err));
    {$ENDIF UNA_STUN_LOG_ERRORS }
    end;
    //
  finally
    mrealloc(hdr);
  end;
end;

// --  --
procedure unaSTUNserver.startIn();
begin
  f_numReq := 0;
  //
  inherited;	// prepares socket
  //
  // start listening
  case (proto) of

    C_STUN_PROTO_UDP: begin
      //
      f_socket.bindToPort := f_port;
      f_socketError := f_socket.bind();
      if (0 <> f_socketError) then
        askStop();
    end;

    C_STUN_PROTO_TCP: f_socket.listen();

  end;
end;


end.

