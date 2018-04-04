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
	  unaSocks_RTSP.pas
	  Real Time Streaming Protocol (RTSP) / RFC 2326
	----------------------------------------------
	  Copyright (c) 2009-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 09 Apr 2009

	  modified by:
		Lake, Apr-May 2009
		Lake, Jan 2012

	----------------------------------------------
*)

{$I unaDef.inc }

{$IFDEF DEBUG }
  {$DEFINE LOG_Socks_RTSP_INFOS }	// log informational messages
  {$DEFINE LOG_Socks_RTSP_ERRORS }	// log critical errors
{$ENDIF DEBUG }

{*

  * RTSP / RFC 2326

  @Author Lake

  Version 2.5.2009.04 + RTCP Client

  Version 2.5.2012.02 + RTCP Server

}

unit
  unaSocks_RTSP;

interface

uses
  Windows, WinSock,
  unaTypes, unaClasses, unaSockets, unaParsers;

const
  // methods
  c_RTSP_METHOD_1st		= 0;	//
  //
  c_RTSP_METHOD_DESCRIBE	= c_RTSP_METHOD_1st;
  c_RTSP_METHOD_ANNOUNCE	= 1;
  c_RTSP_METHOD_GET_PARAMETER	= 2;
  c_RTSP_METHOD_OPTIONS		= 3;
  c_RTSP_METHOD_PAUSE		= 4;
  c_RTSP_METHOD_PLAY		= 5;
  c_RTSP_METHOD_RECORD		= 6;
  c_RTSP_METHOD_REDIRECT	= 7;
  c_RTSP_METHOD_SETUP		= 8;
  c_RTSP_METHOD_SET_PARAMETER	= 9;
  c_RTSP_METHOD_TEARDOWN	= 10;
  //
  c_RTSP_METHOD_last		= c_RTSP_METHOD_TEARDOWN;

  // method strings
  c_RTSP_methods: array[c_RTSP_METHOD_1st .. c_RTSP_METHOD_last] of string =
    ('DESCRIBE', 'ANNOUNCE', 'GET_PARAMETER', 'OPTIONS', 'PAUSE', 'PLAY', 'RECORD', 'REDIRECT', 'SETUP', 'SET_PARAMETER', 'TEARDOWN');


  // response codes
  // 1XX
  c_RTSP_RESPCODE_Continue		= 100;	/// Continue
  // 2XX
  c_RTSP_RESPCODE_OK			= 200;	/// OK
  c_RTSP_RESPCODE_Created		= 201;	/// Created
  c_RTSP_RESPCODE_LowStorage		= 250;	/// Low on Storage Space
  // 3XX
  c_RTSP_RESPCODE_MultipleChoices  	= 300;	/// Multiple Choices
  c_RTSP_RESPCODE_MovedPermanently	= 301;	/// Moved Permanently
  c_RTSP_RESPCODE_MovedTemporarily	= 302;	/// Moved Temporarily
  c_RTSP_RESPCODE_SeeOther		= 303;	/// See Other
  c_RTSP_RESPCODE_NotModified		= 304;	/// Not Modified
  c_RTSP_RESPCODE_UseProxy		= 305;	/// Use Proxy
  // 4XX
  c_RTSP_RESPCODE_BadRequest		= 400;	/// Bad Request
  c_RTSP_RESPCODE_Unauthorized		= 401;	/// Unauthorized
  c_RTSP_RESPCODE_PaymentRequired	= 402;	/// Payment Required
  c_RTSP_RESPCODE_Forbidden		= 403;	/// Forbidden
  c_RTSP_RESPCODE_NotFound		= 404;	/// Not Found
  c_RTSP_RESPCODE_MethodNotAllowed	= 405;	/// Method Not Allowed
  c_RTSP_RESPCODE_NotAcceptable		= 406;	/// Not Acceptable
  c_RTSP_RESPCODE_ProxyAuth		= 407;	/// Proxy Authentication Required
  c_RTSP_RESPCODE_RequestTimeout 	= 408;	/// Request Time-out
  c_RTSP_RESPCODE_Gone			= 410;	/// Gone
  c_RTSP_RESPCODE_LengthRequired	= 411;	/// Length Required
  c_RTSP_RESPCODE_PreconditionFailed	= 412;	/// Precondition Failed
  c_RTSP_RESPCODE_RequestEntityTooLarge	= 413;	/// Request Entity Too Large
  c_RTSP_RESPCODE_RequestURITooLarge	= 414;	/// Request-URI Too Large
  c_RTSP_RESPCODE_UnsupportedMediaType	= 415;	/// Unsupported Media Type
  c_RTSP_RESPCODE_ParamNotUnderstood  	= 451;	/// Parameter Not Understood
  c_RTSP_RESPCODE_ConferenceNotFound	= 452;	/// Conference Not Found
  c_RTSP_RESPCODE_NotEnoughBandwidth	= 453;	/// Not Enough Bandwidth
  c_RTSP_RESPCODE_SessionNotFound	= 454;	/// Session Not Found
  c_RTSP_RESPCODE_MethodNotValid	= 455;	/// Method Not Valid in This State
  c_RTSP_RESPCODE_HeaderFieldNotValid	= 456;	/// Header Field Not Valid for Resource
  c_RTSP_RESPCODE_InvalidRange		= 457;	/// Invalid Range
  c_RTSP_RESPCODE_ParameterIsReadOnly	= 458;	/// Parameter Is Read-Only
  c_RTSP_RESPCODE_AggregateOpNotAllowed	= 459;	/// Aggregate operation not allowed
  c_RTSP_RESPCODE_OnlyAggregateOpAllowed= 460;	/// Only aggregate operation allowed
  c_RTSP_RESPCODE_UnsupportedTransport	= 461;	/// Unsupported transport
  c_RTSP_RESPCODE_DestinationUnreachable= 462;	/// Destination unreachable
  // 5XX
  c_RTSP_RESPCODE_InternalServerError 	= 500;	/// Internal Server Error
  c_RTSP_RESPCODE_NotImplemented	= 501;	/// Not Implemented
  c_RTSP_RESPCODE_BadGateway		= 502;	/// Bad Gateway
  c_RTSP_RESPCODE_ServiceUnavailable	= 503;	/// Service Unavailable
  c_RTSP_RESPCODE_GatewayTimeout	= 504;	/// Gateway Time-out
  c_RTSP_RESPCODE_RTSPVerNotSupported	= 505;	/// RTSP Version not supported
  c_RTSP_RESPCODE_OptionNotSupported  	= 551;	/// Option not supported


  // headers
  c_RTSP_HDR_1st  	= 001;
  // general-headers
  c_RTSP_GENHDR_CacheControl  	= c_RTSP_HDR_1st;
  c_RTSP_GENHDR_Connection	= 002;
  c_RTSP_GENHDR_Date            = 003;
  c_RTSP_GENHDR_Via		= 004;
  // request-headers
  c_RTSP_REQHDR_Accept  	= 005;
  c_RTSP_REQHDR_AcceptEncoding	= 006;
  c_RTSP_REQHDR_AcceptLanguage  = 007;
  c_RTSP_REQHDR_Authorization   = 008;
  c_RTSP_REQHDR_From            = 009;
  c_RTSP_REQHDR_IfModifiedSince = 010;
  c_RTSP_REQHDR_Range           = 011;
  c_RTSP_REQHDR_Referer         = 012;
  c_RTSP_REQHDR_UserAgent       = 013;
  // response header
  c_RTSP_RESHDR_Location        = 014;
  c_RTSP_RESHDR_ProxyAuthenticate=015;
  c_RTSP_RESHDR_Public		= 016;
  c_RTSP_RESHDR_RetryAfter	= 017;
  c_RTSP_RESHDR_Server		= 018;
  c_RTSP_RESHDR_Vary		= 019;
  c_RTSP_RESHDR_WWWAuthenticate	= 020;
  // entity-headers
  c_RTSP_ENTHDR_Allow           = 021;
  c_RTSP_ENTHDR_ContentBase     = 022;
  c_RTSP_ENTHDR_ContentEncoding = 023;
  c_RTSP_ENTHDR_ContentLanguage = 024;
  c_RTSP_ENTHDR_ContentLength   = 025;
  c_RTSP_ENTHDR_ContentLocation = 026;
  c_RTSP_ENTHDR_ContentType     = 027;
  c_RTSP_ENTHDR_Expires         = 028;
  c_RTSP_ENTHDR_LastModified    = 029;
  // other
  c_RTSP_OTHHDR_Bandwidth       = 030;
  c_RTSP_OTHHDR_Blocksize       = 031;
  c_RTSP_OTHHDR_Conference      = 032;
  c_RTSP_OTHHDR_CSeq            = 033;
  c_RTSP_OTHHDR_ProxyRequire   	= 034;
  c_RTSP_OTHHDR_Require         = 035;
  c_RTSP_OTHHDR_RTPInfo        	= 036;
  c_RTSP_OTHHDR_Scale           = 037;
  c_RTSP_OTHHDR_Session         = 038;
  c_RTSP_OTHHDR_Speed           = 039;
  c_RTSP_OTHHDR_Transport       = 040;
  c_RTSP_OTHHDR_Unsupported     = 041;
  //
  c_RTSP_HDR_last    = c_RTSP_OTHHDR_Unsupported;


  c_RTSP_headers: array[c_RTSP_HDR_1st .. c_RTSP_HDR_last] of string = (
    // general
    'Cache-Control',
    'Connection',
    'Date',
    'Via',
    // request
    'Accept',
    'Accept-Encoding',
    'Accept-Language',
    'Authorization',
    'From',
    'If-Modified-Since',
    'Range',
    'Referer',
    'User-Agent',
    // response
    'Location',
    'Proxy-Authenticate',
    'Public',
    'Retry-After',
    'Server',
    'Vary',
    'WWW-Authenticate',
    // entity
    'Allow',
    'Content-Base',
    'Content-Encoding',
    'Content-Language',
    'Content-Length',
    'Content-Location',
    'Content-Type',
    'Expires',
    'Last-Modified',
    // other
    'Bandwidth',
    'Blocksize',
    'Conference',
    'CSeq',
    'Proxy-Require',
    'Require',
    'RTP-Info',
    'Scale',
    'Session',
    'Speed',
    'Transport',
    'Unsupported'
  );


  // default port number
  c_RTSP_PORT_Default		= 554;


type
  {*
	Clinet socket with URI
  }
  unaRTSPClientSocket = class(unaObject)
  private
    f_socket: unaSocket;
    f_id: int64;
    f_uri: string;
    f_response: unaHTTPparser;
    f_lastActivityTM: uint64;
    f_cseq: int;
    f_connFailures: int;
    //
    procedure updateActivityTM();
    procedure incConnFailure();
  protected
    property id: int64 read f_id;
  public
    constructor create(socket: unaSocket; const uri: string; id: int64);
    destructor Destroy(); override;
    //
    {*
	@return idle time (time since last network activity) in milliseconds
    }
    function getIdleTime(): uint64;
    {*
	@return next sequence number
    }
    function nextSeq(): int;
    {*
	@return True if socket is connected and ready to send data
    }
    function okSendReq(): bool;
    //
    class function uri2id(const scheme, host, port: string): int64;
    //
    property socket: unaSocket read f_socket;
    property response: unaHTTPparser read f_response;
    property connFailures: int read f_connFailures;
    property uri: string read f_uri;
  end;

  {*
	List of clinet sockets
  }
  unaRTSPClientSocketList = class(unaIDList)
  protected
    function getId(item: pointer): int64; override;
  end;


  {*
	Basic RTSP client.
  }
  unaRTSPClient = class(unaThread)
  private
    f_userAgent: string;
    //
    f_sockets: unaRTSPClientSocketList;
    f_requests: unaStringList;
    //
    f_lastURI2: string;
    //
    function setupSocket(const uri: string): unaRTSPClientSocket;
    //
    function handleRequest(index: int): HRESULT;
  protected
    //
    function execute(threadID: unsigned): int; override;
    //
    procedure onResponse(const uri, control: string; req: int; response: unaHTTPparser); virtual;
    //
    procedure onReqError(const uri, control: string; req: int; errorCode: HRESULT); virtual;
  public
    {*
	Creates RTPS client.
    }
    constructor create(const userAgent: string = 'unaRTPSClient/1.1');
    {*
	Cleans up socket.
    }
    procedure BeforeDestruction(); override;
    {*
	Sends request to server.

	@param req one of c_RTSP_METHOD_XXXX
	@param uri server address. If uri is '', will use last uri from previous call (passing '' as uri is not MT-safe!)
	@param control Individual
	@param params additional headers
    }
    function sendRequest(req: int; const uri: string = ''; const control: string = ''; const params: string = ''): HRESULT;
    {*
	Closes an open connections to a server.
	If URI is '', closes all connections.
    }
    procedure close(const uri: string = '');
  end;

  {*
	//
  }
  unaRTSPServerParser = class(unaHTTPParser)
  private
    f_id: int64;
    f_idleTime: uint64;
  public
    constructor create(id: int64);
    //
    property id: int64 read f_id;
  end;

  {*
	//
  }
  unaParsersList = class(unaIDList)
  protected
    function getId(item: pointer): int64; override;
  end;

  {*
	Basic RTSP server.
  }
  unaRTSPServer = class(unaSocks)
  private
    f_parsers: unaParsersList;
    f_active: bool;
    f_threadID: tConID;
  protected
    procedure event(event: unaSocketEvent; id, connId: tConID; data: pointer = nil; size: uint = 0); override;
    //
    procedure handleRequest(reqInt: int; const fromIP: string; request: unaRTSPServerParser); virtual;
    //
    procedure onRequest(reqInt: int; const fromIP: string; request: unaRTSPServerParser; var headers, body, msg: string; var respcode: int); virtual;
  public
    {*
	//
    }
    constructor create();
    {*
	Opens a new server.

	@param transport UDP or TCP, default is TCP
	@param port default is c_RTSP_PORT_Default (554)
	@param bindTo bind to one of local IPs, default is 0.0.0.0
	@return S_OK or some error otherwise
    }
    function open(transport: int = IPPROTO_TCP; const port: string = ''; const bindTo: string = '0.0.0.0'): HRESULT;
    {*
	Closes server thread
    }
    procedure close();
    {*
	Sends response back to client
    }
    procedure sendResponse(request: unaRTSPServerParser; responseCode: int = c_RTSP_RESPCODE_OK; const headers: string = ''; const body: string = ''; const humanMsg: string = '');
    {*
    	True when server is active
    }
    property active: bool read f_active;
    {*
	Socks thread ID
    }
    property threadID: tConID read f_threadID;
  end;



implementation


uses
  unaUtils,
  WinInet;


{ unaRTSPClientSocket }

// --  --
constructor unaRTSPClientSocket.create(socket: unaSocket; const uri: string; id: int64);
begin
  f_socket := socket;
  f_uri := uri;
  f_id := id;
  //
  f_response := unaHTTPparser.create();
  //
  inherited create();
end;

// --  --
destructor unaRTSPClientSocket.Destroy();
begin
  inherited;
  //
  freeAndNil(f_socket);
  freeAndNil(f_response);
end;

// --  --
function unaRTSPClientSocket.getIdleTime(): uint64;
begin
  if (0 = f_lastActivityTM) then
    updateActivityTM();
  //
  result := timeElapsed64U(f_lastActivityTM);
end;

// --  --
procedure unaRTSPClientSocket.incConnFailure();
begin
  inc(f_connFailures);
end;

// --  --
function unaRTSPClientSocket.nextSeq(): int;
begin
  result := InterlockedIncrement(f_cseq);
end;

// --  --
function unaRTSPClientSocket.okSendReq(): bool;
begin
  result := false;
  //
  if (not socket.isConnected(10)) then begin
    //
    if (f_connFailures < 50) then
      socket.connect()
    else
      exit;	// too many connection errors
  end;
  //
  result := (socket.isConnected(10) and socket.okToWrite());
end;

// --  --
procedure unaRTSPClientSocket.updateActivityTM();
begin
  f_lastActivityTM := timeMarkU();
end;

// --  --
class function unaRTSPClientSocket.uri2id(const scheme, host, port: string): int64;
begin
  result := crc32(aString(scheme)) or (crc32(aString(revStr(host))) shl 31) xor crc32(aString(port));	// high bit will be 0
end;


{ unaRTSPClientSocketList }

// --  --
function unaRTSPClientSocketList.getId(item: pointer): int64;
begin
  if (nil <> item) then
    result := unaRTSPClientSocket(item).id
  else
    result := -1;
end;


{ unaRTSPClient }

// --  --
procedure unaRTSPClient.BeforeDestruction();
begin
  inherited;
  //
  close();
  //
  freeAndNil(f_sockets);
  freeAndNil(f_requests);
end;

// --  --
procedure unaRTSPClient.close(const uri: string);
var
  crack: unaURIcrack;
  id: int64;
  sock: unaRTSPClientSocket;
begin
  if ('' = uri) then begin
    //
    stop();	// make sure sockets are not busy
    //
    f_sockets.clear()
  end
  else begin
    //
    if (crackURI(uri, crack)) then begin
      //
      id := unaRTSPClientSocket.uri2id(crack.r_scheme, crack.r_hostName, int2str(crack.r_port));
      sock := f_sockets.lockObject(f_sockets.indexOfId(id), false, 2000) as unaRTSPClientSocket;	// make sure socket is not busy
      if (nil <> sock) then
        f_sockets.removeById(id);
    end;
  end;
end;

// --  --
constructor unaRTSPClient.create(const userAgent: string);
begin
  f_userAgent := userAgent;
  //
  f_sockets := unaRTSPClientSocketList.create(uldt_obj);
  f_requests := unaStringList.create();
  //
  inherited create();
end;

// --  --
function unaRTSPClient.execute(threadID: unsigned): int;
var
  i: int;
  sock: unaRTSPClientSocket;
  idle: bool;
begin
  while (not shouldStop) do begin
    //
    idle := true;
    try
      //
      // 1. handle request if any
      if (0 < f_requests.count) then begin
	//
	handleRequest(0);
	f_requests.removeFromEdge();
	//
	idle := false;
      end;
      //
      // 2. check sockets activity
      i := 0;
      while (not shouldStop and (i < f_sockets.count)) do begin
	//
	try
	  sock := f_sockets.lockObject(i) as unaRTSPClientSocket;
	  if (nil <> sock) then try
	    //
	    if (30000 < sock.getIdleTime()) then begin
	      //
	      if (sock.okSendReq()) then begin
		//
		sendRequest(c_RTSP_METHOD_GET_PARAMETER, sock.uri, '');	// "ping"
		sock.updateActivityTM();
		//
		idle := false;
	      end;
	    end;
	    //
	  finally
	    sock.releaseRO();
	  end;
	finally
	  inc(i);
	end;
      end;
    except
      // ignore expceptions
    end;
    //
    if (idle) then
      sleepThread(50);
  end;
  //
  result := 0;
end;

// --  --
function unaRTSPClient.handleRequest(index: int): HRESULT;
var
  req: int;
  uri, control, params, reqS, uri2: string;
  buf: pointer;
  sz: uint;
  bufSize: unsigned;
  sock: unaRTSPClientSocket;
  tm: uint64;
begin
  result := HRESULT(-1);
  //
  uri := f_requests.get(index);
  if ('' <> uri) then begin
    //
    control := copy(uri, pos(#9, uri) + 1, maxInt);
    params := copy(control, pos(#9, control) + 1, maxInt);
    req := str2intInt(copy(params, 1, pos(#9, params) - 1), -1);
    //
    uri := copy(uri, 1, pos(#9, uri) - 1);
    params := copy(params, pos(#9, params) + 1, maxInt);
    control := copy(control, 1, pos(#9, control) - 1);
    //
    if ('' = trimS(uri)) then
      uri2 := f_lastURI2
    else
      uri2 := uri;
    //
    if ('' <> control) then
      uri2 := uri2 + '/' + control;
    //
    sock := setupSocket(uri2);
    if (nil <> sock) then try
      //
      reqS := c_RTSP_methods[req] + ' ' + uri2 + ' RTSP/1.0'#13#10;
      reqS := reqS + 'CSeq: ' + int2str(sock.nextSeq()) + #13#10;
      if ('' <> params) then
	reqS := reqS + params + #13#10;
      //
      case (req) of

	c_RTSP_METHOD_DESCRIBE		: reqS := reqS + 'Accept: application/sdp'#13#10;
	c_RTSP_METHOD_ANNOUNCE		: ;
	c_RTSP_METHOD_GET_PARAMETER	: ;
	c_RTSP_METHOD_OPTIONS		: ;
	c_RTSP_METHOD_PAUSE		: ;
	c_RTSP_METHOD_PLAY		: ;
	c_RTSP_METHOD_RECORD		: ;
	c_RTSP_METHOD_REDIRECT		: ;
	c_RTSP_METHOD_SETUP		: ;
	c_RTSP_METHOD_SET_PARAMETER	: ;
	c_RTSP_METHOD_TEARDOWN		: ;

      end;
      //
      reqS := reqS + 'User-Agent: ' + f_userAgent + #13#10;
      reqS := reqS + #13#10;
      //
      sock.response.cleanup();
      //
      if (sock.socket.okToWrite()) then
	sock.socket.send(aString(reqS))
      else begin
	//
	result := HRESULT(-3);	// timeout
	exit;
      end;
      //
      f_lastURI2 := uri2;
      //
      bufSize := 4096;
      buf := malloc(bufSize);
      try
	//
	result := HRESULT(-4);	// incomplete response
	tm := timeMarkU();
	//
	while (not shouldStop and sock.socket.isConnected() and (14000 > timeElapsedU(tm))) do begin
	  //
	  sz := bufSize;
	  if (sock.socket.okToRead() and (0 = sock.socket.read(buf, sz, 100000, true))) then begin
	    //
	    sock.response.feed(buf, sz);
	    if (sock.response.headerComplete and sock.response.getPayloadComplete(true, 0)) then begin
	      //
	      onResponse(uri, control, req, sock.response);
	      sock.updateActivityTM();
	      //
	      result := S_OK;
	      break;
	    end;
	  end;
	end;
	//
      finally
	mrealloc(buf);
      end;
      //
    finally
      sock.releaseWO();
    end
    else
      result := HRESULT(-2);
    //
    if (not SUCCEEDED(result)) then
      onReqError(uri, control, req, result);
  end;
end;

// --  --
procedure unaRTSPClient.onReqError(const uri, control: string; req: int; errorCode: HRESULT);
begin
  // override to be notified
end;

// --  --
procedure unaRTSPClient.onResponse(const uri, control: string; req: int; response: unaHTTPparser);
begin
  // override to be notified
end;

// --  --
function unaRTSPClient.sendRequest(req: int; const uri, control, params: string): HRESULT;
begin
  f_requests.add(uri + #9 + control + #9 + int2str(req) + #9 + params);
  //
  if (unatsRunning <> status) then
    start();
  //
  result := S_OK;
end;

// --  --
function unaRTSPClient.setupSocket(const uri: string): unaRTSPClientSocket;
var
  crack: unaURIcrack;
  scheme, host, port: string;
  tm: uint64;
  id: int64;
  socket: unaSocket;
begin
  result := nil;
  if (crackURI(uri, crack)) then begin
    //
    scheme := crack.r_scheme;
    host   := crack.r_hostName;
    port   := int2str(crack.r_port);
    //
    id := unaRTSPClientSocket.uri2id(scheme, host, port);
    result := f_sockets.itemById(id);
    if (nil <> result) then
      if (not result.acquire(false, 1000)) then
	result := nil;
    //
    if ((nil = result) or (not result.socket.okToWrite(10))) then begin
      //
      if (nil = result) then begin
	//
	if (1 = pos('rtpsu', scheme)) then
	  socket := unaUDPSocket.create()
	else
	  socket := unaTCPSocket.create();
	//
	result := unaRTSPClientSocket.create(socket, uri, id);
	result.acquire(false, 100);
	//
	f_sockets.add(result);
      end;
      //
      result.socket.close();
      //
      result.socket.setHost(host);
      if ('0' = port) then
	result.socket.setPort(c_RTSP_PORT_Default)
      else
	result.socket.setPort(port);
      //
      result.socket.connect();
      //
      tm := timeMarkU();
      while (not shouldStop and result.socket.isConnected() and not result.socket.okToWrite()) do begin
	//
	sleep(10);
	if (6000 < timeElapsed64U(tm)) then
	  break;
      end;
      //
      if (not result.socket.isConnected()) then
	result.incConnFailure();
      //
    end;
  end;
end;


{ unaRTSPServerParser }

// --  --
constructor unaRTSPServerParser.create(id: int64);
begin
  f_id := id;
  f_idleTime := timeMarkU();
  //
  inherited create();
end;


{ unaParsersList }

// --  --
function unaParsersList.getId(item: pointer): int64;
begin
  if (nil <> item) then
    result := unaRTSPServerParser(item).id
  else
    result := -1;
end;


{ unaRTSPServer }

// --  --
procedure unaRTSPServer.close();
begin
  closeThread(f_threadID);
  f_threadID := 0;
  //
  clear(true, true);
end;

// --  --
constructor unaRTSPServer.create();
begin
  inherited create();
  //
  f_parsers := unaParsersList.create(uldt_obj, true);
end;

// --  --
procedure unaRTSPServer.event(event: unaSocketEvent; id, connId: tConID; data: pointer; size: uint);
var
  parser: unaRTSPServerParser;
  req: string;
  i, reqI: int32;
  conn: unaSocksConnection;
begin
  inherited;
  //
  connId := connId and $00FFFFFF;
  //
  case (event) of

    unaseThreadStartupError: begin
      //
      // someone already listening on same port?
    end;

    unaseServerListen	: f_active := true;

    unaseServerStop	: f_active := false;

    unaseServerConnect	: begin
      //
      f_parsers.add(unaRTSPServerParser.create(connId));
    end;

    unaseServerData,
    unaseServerDisconnect: begin
      //
      parser := unaRTSPServerParser(f_parsers.itemById(connId));
      if (nil <> parser) then begin
	//
	case (event) of

	  unaseServerData: begin
	    //
	    parser.feed(data, size);
	    if (parser.headerComplete and parser.getPayloadComplete(true, 0)) then begin
	      //
	      req := loCase(parser.getReqMethod());
	      reqI := -1;
	      for i := low(c_RTSP_methods) to high(c_RTSP_methods) do begin
		//
		if (loCase(c_RTSP_methods[i]) = req) then begin
		  //
		  reqI := i;
		  break;
		end;
	      end;
	      //
	      conn := getConnection(id, connId, 300, true);
	      if (nil <> conn) then try
		//
		handleRequest(reqI, ipN2str(TIPv4N(conn.paddr.sin_addr.S_addr)), parser);
	      finally
		conn.release();
	      end;
	      //
	      parser.dropIfComplete(0);
	    end;
	  end;

	  unaseServerDisconnect: begin
	    //
	    handleRequest(c_RTSP_METHOD_TEARDOWN, '', parser);
	    //
	    f_parsers.removeById(connId);
	  end;

	end;
      end;
    end;

  end;
end;

// --  --
procedure unaRTSPServer.handleRequest(reqInt: int; const fromIP: string; request: unaRTSPServerParser);
var
  headers, body, msg: string;
  respcode: int;
begin
  request.f_idleTime := timeMarkU();
  //
  respcode := 200;
  body := '';
  headers := '';
  msg := 'OK';
  //
  case (reqInt) of

    c_RTSP_METHOD_DESCRIBE	: begin
      //
      onRequest(reqInt, fromIP, request, headers, body, msg, respcode);
      if ('' = headers) then begin
	//
	headers :=
	  'Content-Base: ' + request.getReqURI() + #13#10 +
	  'Content-Type: application/sdp' +
	  '';
      end;
      //
      // body must be filled with SDP data
    end;

    c_RTSP_METHOD_ANNOUNCE,
    c_RTSP_METHOD_SET_PARAMETER,
    c_RTSP_METHOD_GET_PARAMETER: begin
      //
      onRequest(reqInt, fromIP, request, headers, body, msg, respcode);
    end;

    c_RTSP_METHOD_OPTIONS: begin
      //
      headers := 'Public: OPTIONS, DESCRIBE, TEARDOWN, PLAY, PAUSE, GET_PARAMETER, SET_PARAMETER';
    end;

    c_RTSP_METHOD_PAUSE: begin
      //
      // TODO: make sure we are Playing/Recording in this Session
      //
      onRequest(reqInt, fromIP, request, headers, body, msg, respcode);
    end;

    c_RTSP_METHOD_PLAY: begin
      //
      // TODO: make sure we are Playing/Recording in this Session
      //
      onRequest(reqInt, fromIP, request, headers, body, msg, respcode);
    end;

    c_RTSP_METHOD_RECORD: begin
      //
      // TODO: make sure we are not Playing/Recording in this Session
      //
      onRequest(reqInt, fromIP, request, headers, body, msg, respcode);
    end;

    c_RTSP_METHOD_REDIRECT: begin
      sendResponse(request, c_RTSP_RESPCODE_MethodNotAllowed, '', '', 'S->C only');	//
    end;

    c_RTSP_METHOD_SETUP: begin
      //
      // TODO: make sure we Ready in this Session
      //
      onRequest(reqInt, fromIP, request, headers, body, msg, respcode);
    end;

    c_RTSP_METHOD_TEARDOWN: begin
      //
      // TODO: make sure we are Playing/Recording
      //
      onRequest(reqInt, fromIP, request, headers, body, msg, respcode);
    end;

    else begin
      //
      respcode := c_RTSP_RESPCODE_BadRequest;
      msg := 'Cant handle ' + request.getReqMethod();
    end;

  end;
  //
  sendResponse(request, respcode, headers, body, msg);
end;

// --  --
procedure unaRTSPServer.onRequest(reqInt: int; const fromIP: string; request: unaRTSPServerParser; var headers, body, msg: string; var respcode: int);
begin
  // overide to be notified and provide headers and body for response
end;

// --  --
function unaRTSPServer.open(transport: int; const port, bindTo: string): HRESULT;
var
  _port: string;
begin
  if (0 <> f_threadID) then
    closeThread(f_threadID);
  //
  if (('' = port) or ('0' = trimS(port))) then
    _port := int2str(c_RTSP_PORT_Default)
  else
    _port := port;
  //
  f_threadID := createServer(_port, transport, true, 4, 60000, bindTo {$IFDEF VC25_OVERLAPPED }, false{$ENDIF VC25_OVERLAPPED });
  if (0 <> f_threadID) then
    result := S_OK
  else
    result := HRESULT(-1);
end;

const
  c_dow: array[0..6] of string = ('Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat');
  c_month: array[1..12] of string = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');

// --  --
function now2str(): string;
var
  st: SYSTEMTIME;
begin
  GetSystemTime(st);
  //
  result := c_dow[st.wDayOfWeek] + ', ' + c_month[st.wMonth] + ' ' + int2str(st.wDay) + ' ' + int2str(st.wYear) + ' ' +
	    adjust(int2str(st.wHour), 2, '0') + ':' +
	    adjust(int2str(st.wMinute), 2, '0') + ':' +
	    adjust(int2str(st.wSecond), 2, '0') + ' GMT';
end;

// --  --
procedure unaRTSPServer.sendResponse(request: unaRTSPServerParser; responseCode: int; const headers, body, humanMsg: string);
var
  data, cl, session: string;
  dataA: aString;
  conn: unaSocksConnection;
  asynch: bool;
begin
  conn := getConnection(f_threadID, request.id, 300, true);
  if (nil <> conn) then try
    //
    if (0 < length(body)) then
      cl := 'Content-Length: ' + int2str(length(body))
    else
      cl := '';
    //
    session := request.getHeaderValue('Session');
    if ('' <> session) then
      session := 'Session: ' + session;
    //
    data := 'RTSP/1.0 ' + int2str(responseCode) + ' ' + humanMsg + #13#10 +
	    choice('' <> headers, headers + #13#10, '') +
	    'CSeq: ' + request.getHeaderValue('CSeq') + #13#10 +
	    choice('' <> session, string(session) + #13#10, '') +
	    'Date: ' + now2str() + #13#10 +
	    choice('' <> cl, string(cl) + #13#10, '') +
	    #13#10 +
	    body;
    //
    dataA := UTF162UTF8(data);
    sendData(f_threadID, @dataA[1], length(dataA), request.id, asynch);
  finally
    conn.release();
  end;
end;


end.

