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

	  unaSocks_SHOUT.pas
	  A SHOUTcast protocol implementation

	----------------------------------------------
	  Copyright (c) 2009-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 20 Apr 2009

	  modified by:
		Lake, Apr-Jun 2009

	----------------------------------------------
*)

{$I unaDef.inc }

{$IFDEF DEBUG }
  {xx $DEFINE UNASHOUT_LOGTRANSPORT }	// define to log sockets transfers
  {xx $DEFINE UNASHOUT_LOGMETADATA }	// define to log sockets transfers
{$ENDIF DEBUG }

{*
	A SHOUTcast protocol implementation
}

unit
  unaSocks_SHOUT;

interface

uses
  Windows, unaTypes, unaClasses, unaSockets, unaParsers,
  WinSock;

const
// default agent name
  c_def_ICY_agent = 'VC SHOUTcast receiver 1.0 (c) 2012 Lake of Soft';	

type
  {*
	Basic SHOUTcast receiver (TCP only).
  }
  unaSHOUTreceiver = class(unaThread)
  private
    f_socket: unaTCPSocket;
    f_uri: string;
    f_host: string;
    f_songPath: string;
    f_parser: unaHTTPparser;
    f_mode: int; 	// 0 - about to send GET / HTTP/1.0
			// 1 - about to receive ICY 200 OK
			// 2 - ICY header complete, working with payload only
    f_payloadOffs: int;
    f_metaDataOffs: uint;
    f_metaDataEnabled: bool;
    //
    f_mdBuf: pointer;
    f_mdBufSize: uint;
    f_mdBufUsed: uint;
    //
    f_errorCode: int;
    f_agent: string;
    f_metaOK: bool;
    //
    f_srv_bitrate: string;
    f_srv_genre: string;
    f_srv_name: string;
    f_srv_url: string;
    f_song_title: string;
    f_song_url: string;
    f_libOK: bool;
    //
    function setupSocket(): bool;
    procedure parsePayload(buf: pointer; size: uint);
    procedure parseMetadata(var buf: pointer; var size: uint);
    procedure parseMDtext(buf: pointer; size: uint);
  protected
    procedure startIn(); override;
    procedure startOut(); override;
    function execute(threadID: unsigned): int; override;
    //
    procedure onPayload(data: pointer; size: uint); virtual;
    procedure onMetadata(data: pointer; size: uint); virtual;
  public
    {*
    	Creates a new instance.
    }
    constructor create(const uri: string; const userAgent: string = c_def_ICY_agent; allowMetadata: bool = true);
    {*
	Cleans the instance.
    }
    procedure BeforeDestruction(); override;
    {*
	Returns specifyied ICY header.
    }
    function getICYHeaderValue(const name: string): string;
    //
    {*
	Stream URI.
    }
    property URI: string read f_uri;
    {*
	ICY or some other error code.
    }
    property errorCode: int read f_errorCode;
    {*
    }
    property libOK: bool read f_libOK;
    {*
	User-agent:
    }
    property userAgent: string read f_agent write f_agent;
    {*
    }
    property srv_bitrate: string read f_srv_bitrate;
    {*
    }
    property srv_genre: string read f_srv_genre;
    {*
    }
    property srv_name: string read f_srv_name;
    {*
    }
    property srv_url: string read f_srv_url;
    {*
    }
    property song_title: string read f_song_title;
    {*
    }
    property song_url: string read f_song_url;
  end;


const
  // error codes
  c_err_OK		=  0;
  c_err_SOCKET		= -2;
  c_err_ADDRESS		= -3;
  c_err_PASSWORD	= -4;
// some other ICECAST error, see iceCode property
  c_err_ICE		= -5;	

type
  {*
	Basic SHOUTcast transmitter (TCP only).
  }
  unaSHOUTtransmitter = class(unaThread)
  private
    f_crack: unaURIcrack;
    f_err: int;
    f_iceErr: int;
    //
    f_socket: tSOCKET;
    f_dnasCompatible: bool;
    //
    f_ice_URL: string;
    f_ice_name: string;
    f_ice_genre: string;
    f_ice_public: bool;
    //
    procedure setSocket(socket: tSocket = 0);
  protected
    function execute(threadID: unsigned): int; override;
  public
    {*
	Opens the streamer.

	@param uri Address of DNAS server.
	@return S_OK if streamer was successfully started.
    }
    function open(const uri: string): HRESULT;
    {*
	Closes the streamer.
    }
    procedure close();
    //
    {*
	Returns number of bytes actually sent.
    }
    function send(buf: pointer; len: uint): uint;
    //
// see c_err_XXX
    property error: int read f_err;	
    property iceCode: int read f_iceErr;
    //
    property ice_public: bool read f_ice_public write f_ice_public;
    property ice_genre: string read f_ice_genre write f_ice_genre;
    property ice_URL: string read f_ice_URL write f_ice_URL;
    property ice_name: string read f_ice_name write f_ice_name;
  end;


implementation


uses
  unaUtils,
  WinInet;


{ unaSHOUTreceiver }

// --  --
procedure unaSHOUTreceiver.BeforeDestruction();
begin
  inherited;
  //
  freeAndNil(f_socket);
end;

// --  --
constructor unaSHOUTreceiver.create(const uri, userAgent: string; allowMetadata: bool);
begin
  f_uri := uri;
  f_agent := userAgent;
  f_metaOK := allowMetadata;
  //
  f_libOK := setupSocket();
  //
  inherited create();
end;

// --  --
function unaSHOUTreceiver.execute(threadID: unsigned): int;
var
  buf: pointer;
  bufSize: unsigned;
  sz: uint;
  req: string;
  ok: bool;
  tm: uint64;
begin
  {$IFDEF UNASHOUT_LOGTRANSPORT }
  logMessage(className + '.execute() - ENTER');
  {$ENDIF UNASHOUT_LOGTRANSPORT }
  //
  bufSize := $4000;
  buf := malloc(bufSize);
  try
    while ((0 = errorCode) and not shouldStop) do begin
      //
      if (0 < f_mode) then begin
	//
	sz := bufSize;
	ok := (0 = f_socket.read(buf, sz, 10)) and (0 < sz);
      end
      else
	ok := true;
      //
      if (ok) then begin

	case (f_mode) of

	  0: begin
	    // send request
	    req := 'GET ' + f_songPath + ' HTTP/1.0'#13#10 +
		   'Host: ' + f_host + #13#10 +
		   'User-Agent: ' + f_agent + #13#10 +
		   'Range: bytes=0-'#13#10 +
		   'Icy-MetaData: ' + choice(f_metaOK, '1', '0') + #13#10 +
		   #13#10;
	    //
	    {$IFDEF UNASHOUT_LOGTRANSPORT }
	    logMessage(className + '.execute() - About to send req=[' + req + ']');
	    {$ENDIF UNASHOUT_LOGTRANSPORT }
	    //
	    f_mode := 1;
	    f_socket.send(aString(req));
	  end;

	  1: begin
	    // parse HTTP/ICY reply
	    f_parser.feed(buf, sz);
	    if (f_parser.headerComplete) then begin
	      //
	      {$IFDEF UNASHOUT_LOGTRANSPORT }
	      logMessage(className + '.execute() - Got reply, code=' + int2str(f_parser.getRespCode));
	      {$ENDIF UNASHOUT_LOGTRANSPORT }
	      //
	      case (f_parser.getRespCode) of

		200: begin
		  //
		  f_mode := 2;
		  f_payloadOffs := 0;
		  f_metaDataOffs := str2intInt(getICYHeaderValue('icy-metaint'), 0);
		  f_metaDataEnabled := (0 < f_metaDataOffs);
		  //
		  {$IFDEF UNASHOUT_LOGMETADATA }
		  logMessage(className + '.execute() - Metadata ofs=' + int2str(f_metaDataOffs));
		  {$ENDIF UNASHOUT_LOGMETADATA }
                  //
		  f_srv_bitrate := getICYHeaderValue('icy-br');
                  f_srv_genre := getICYHeaderValue('icy-genre');
                  f_srv_name := getICYHeaderValue('icy-name');
                  f_srv_url := getICYHeaderValue('icy-url');
		  //
                  if ('' = srv_bitrate) then 	// try Ice 1.3 header
                    f_srv_bitrate := getICYHeaderValue('x-audiocast-bitrate');
                  //
                  if ('' = srv_genre) then		// try Ice 1.3 header
                    f_srv_genre := getICYHeaderValue('x-audiocast-genre');
		  //
                  if ('' = srv_name) then		// try Ice 1.3 header
                    f_srv_name := getICYHeaderValue('x-audiocast-description');
                  //
                  if ('' = srv_url) then		// try Ice 1.3 header
                    f_srv_url := getICYHeaderValue('x-audiocast-server-url');
		  //
		  sz := (f_parser.dataSize - f_parser.headerSize);
		  if (0 < sz) then
		    parsePayload(@f_parser.data[f_parser.headerSize], sz);
		end;

		302: begin
		  //
		  // Found at new URI
		  f_uri := trimS(f_parser.getHeaderValue('Location'));
		  //
		  {$IFDEF UNASHOUT_LOGTRANSPORT }
		  logMessage(className + '.execute() - About to redirect to new URI=[' + f_uri + ']');
		  {$ENDIF UNASHOUT_LOGTRANSPORT }
		  //
		  f_socket.close();
		  //
		  if (setupSocket()) then begin
                    //
                    f_parser.cleanup();
                    f_socket.connect();
		    f_mode := 0;
                    //
                    sleepThread(200);
                    //
                    tm := timeMarkU();
                    while (not f_socket.okToWrite()) do begin
                      //
                      sleep(10);
		      if (3000 < timeElapsed64U(tm)) then
                        break;
                    end;
                  end
                  else
                    askStop();
		end;

                else begin
                  //
                  f_errorCode := 0 - f_parser.getRespCode;
                  askStop();
                end;

	      end;
	    end
            else begin
              // sanity check
              if (16000 < f_parser.headerSize) then begin
                //
                // 16KB received and header still not complete? come on..
                f_errorCode := 0 - f_parser.getRespCode;
                askStop();
	      end;
            end;
	  end;

	  2: begin
	    //
	    {$IFDEF UNASHOUT_LOGTRANSPORT }
	    logMessage(className + '.execute() - Got ' + int2str(sz) + ' payload bytes');
	    {$ENDIF UNASHOUT_LOGTRANSPORT }
	    //
	    // work with payload
	    parsePayload(buf, sz);
	  end;

          -1: begin
            //
            askStop();
          end;

	end;
      end
      else
	sleepThread(20);
      //
    end; // while () ...
    //
  finally
    mrealloc(buf);
  end;
  //
  result := 0;
  //
  {$IFDEF UNASHOUT_LOGTRANSPORT }
  logMessage(className + '.execute() - LEAVE');
  {$ENDIF UNASHOUT_LOGTRANSPORT }
end;

// --  --
function unaSHOUTreceiver.getICYHeaderValue(const name: string): string;
begin
  result := f_parser.getHeaderValue(name);
end;

// --  --
procedure unaSHOUTreceiver.onMetadata(data: pointer; size: uint);
{$IFDEF UNASHOUT_LOGMETADATA }
var
  str: aString;
{$ENDIF UNASHOUT_LOGMETADATA }
begin
  {$IFDEF UNASHOUT_LOGMETADATA }
  setLength(str, size);
  move(data^, str[1], size);
  //
  logMessage(className + '.onMetadata() - MD=[' + string(str) + ']');
  {$ENDIF UNASHOUT_LOGMETADATA }
  //
  parseMDtext(data, size);
end;

// --  --
procedure unaSHOUTreceiver.onPayload(data: pointer; size: uint);
begin
end;

// --  --
procedure unaSHOUTreceiver.parseMDtext(buf: pointer; size: uint);
var
  text: aString;

  // --  --
  procedure getValue(const name: string; var outval: string);
  var
    vend: uint;
    vstart: uint;
  begin
    vstart := pos(name + '=''', string(loCase(text)));
    if (0 < vstart) then begin
      //
      inc(vstart, length(name) + 2);
      //
      vend := vstart;
      //
      while ((vend < size) and (text[vend] <> '''')) do
        inc(vend);
      //
      if ((vend < size) and (text[vend] = '''')) then
        dec(vend);
      //
      outval := utf82utf16(aString(copy(string(text), vstart, vend + 1 - vstart)));
    end;
  end;

begin
  if (0 < size) then begin
    //
    setLength(text, size);
    move(buf^, text[1], size);
  end
  else
    text := '';
  //
  getValue('streamtitle', f_song_title);
  getValue('streamurl', f_song_url);
end;

// --  --
procedure unaSHOUTreceiver.parseMetadata(var buf: pointer; var size: uint);
var
  sz: uint;
begin
  if ((0 < size) and (nil <> buf)) then begin
    //
    if (0 = f_mdBufSize) then begin
      //
      // start of new metadata
      sz := pArray(buf)[0] shl 4;
      //
      {$IFDEF UNASHOUT_LOGMETADATA }
      logMessage(className + '.parseMetadata() - New MD, size=' + int2str(sz));
      {$ENDIF UNASHOUT_LOGMETADATA }
      //
      dec(size);	// eat 1 byte
      buf := @pArray(buf)[1];
      if (0 < sz) then begin
	//
	mrealloc(f_mdBuf, sz);
	//
	{$IFDEF DEBUG }
	fillChar(f_mdBuf^, sz, #0);
	{$ENDIF DEBUG }
	//
	if (size >= sz) then begin
	  //
	  {$IFDEF UNASHOUT_LOGMETADATA }
	  logMessage(className + '.parseMetadata() - All MD is here, notify and switch to PL');
	  {$ENDIF UNASHOUT_LOGMETADATA }
	  //
	  // all MD is here
	  onMetadata(buf, sz);
	  buf := @pArray(buf)[sz];
	  dec(size, sz);
	  //
	  f_payloadOffs := 0;	// no more MD, switch to payload
	  f_mdBufSize := 0;
	end
	else begin
	  //
	  // not all MD is here, have to store what we have so far
	  {$IFDEF UNASHOUT_LOGMETADATA }
	  logMessage(className + '.parseMetadata() - Only a part of MD is here, size/sz=' + int2str(size) + '/' + int2str(sz));
	  {$ENDIF UNASHOUT_LOGMETADATA }
	  //
	  f_mdBufSize := sz;
	  move(buf^, f_mdBuf^, size);
	  f_mdBufUsed := size;
	  //
	  buf := @pArray(buf)[size];
	  size := 0;
	end;
      end
      else begin
	//
	f_payloadOffs := 0;	// empty MD, switch to payload
      end;
    end
    else begin
      //
      // continue with old metadata
      if (size + f_mdBufUsed >= f_mdBufSize) then begin
	//
	// got all MD, feed and switch to payload
	//
	{$IFDEF UNASHOUT_LOGMETADATA }
	logMessage(className + '.parseMetadata() - Continue MD, got all now, feed and switch to PL');
	{$ENDIF UNASHOUT_LOGMETADATA }
	//
	sz := f_mdBufSize - f_mdBufUsed;
	if (0 < sz) then begin
	  //
	  move(buf^, pArray(f_mdBuf)[f_mdBufUsed], sz);
	  inc(f_mdBufUsed, sz);
	  //
	  onMetadata(f_mdBuf, f_mdBufSize);
	end;
	//
	buf := @pArray(buf)[sz];
	dec(size, sz);
	//
	f_payloadOffs := 0;	// no more MD, switch to payload
	f_mdBufSize := 0;
      end
      else begin
	//
	{$IFDEF UNASHOUT_LOGMETADATA }
	logMessage(className + '.parseMetadata() - Continue MD, still only size/f_mdBufSize=' + int2str(size) + '/' + int2str(f_mdBufSize));
	{$ENDIF UNASHOUT_LOGMETADATA }
	//
	// not all MD is here, just store what we have so far
	move(buf^, pArray(f_mdBuf)[f_mdBufUsed], size);
	inc(f_mdBufUsed, size);
	//
	buf := @pArray(buf)[size];
	size := 0;
      end;
    end;
  end;
end;

// --  --
procedure unaSHOUTreceiver.parsePayload(buf: pointer; size: uint);
var
  sz: int;
begin
  if ((0 < size) and (nil <> buf)) then begin
    //
    if (f_metaDataEnabled) then begin
      //
      if (0 > f_payloadOffs) then
        parseMetadata(buf, size);
      //
      while ((0 < size) and (0 <= f_payloadOffs) and (uint(f_payloadOffs) + size > f_metaDataOffs)) do begin
	//
        if (uint(f_payloadOffs) < f_metaDataOffs) then begin
          //
          sz := f_metaDataOffs - uint(f_payloadOffs);
	  onPayload(buf, sz);
        end
	else
          sz := 0;
        //
        f_payloadOffs := -1;	// switch to MD
        dec(size, sz);
        //
        // parse metadata
        buf := @pArray(buf)[sz];
        parseMetadata(buf, size);
      end;
      //
      if ((0 < size) and (0 <= f_payloadOffs)) then begin
        //
        onPayload(buf, size);
        inc(f_payloadOffs, size);
      end;
    end
    else
      onPayload(buf, size);
    //  
  end;
end;

// --  --
function unaSHOUTreceiver.setupSocket(): bool;
var
  crack: unaURICrack;
  scheme, port: string;
begin
  result := crackURI(f_uri, crack);
  if (result) then begin
    //
    scheme := crack.r_scheme;	// must be HTTP
    if ('http' = scheme) then begin
      //
      f_host := crack.r_hostName;
      port   := int2str(crack.r_port);
      f_songPath := crack.r_path;
      if ('' = trimS(f_songPath)) then
	f_songPath := '/';
      //
      f_socket := unaTCPSocket.create();
      //
      f_socket.setHost(f_host);
      if ('0' = port) then
	f_socket.setPort('80')
      else
	f_socket.setPort(port);
      //
      f_errorCode := 0;
    end
    else begin
      //
      result := false;
      f_errorCode := -2;
    end;
  end
  else
    f_errorCode := -1;
end;

// --  --
procedure unaSHOUTreceiver.startIn();
var
  tm: uint64;
begin
  f_srv_bitrate := '';
  f_srv_genre := '';
  f_srv_name := '';
  f_srv_url := '';
  f_song_title := '';
  f_song_url := '';
  //
  f_errorCode := 0 - f_socket.connect();
  if (0 = f_errorCode) then begin
    //
    f_parser := unaHTTPparser.create();
    f_mode := -1;
    //
    inherited;
    //
    tm := timeMarkU();
    while (not f_socket.okToWrite()) do begin
      //
      sleep(10);
      if (6000 < timeElapsed64U(tm)) then
        break;
    end;
    //
    if f_socket.okToWrite() then
      f_mode := 0;
    //
  end;
end;

// --  --
procedure unaSHOUTreceiver.startOut();
begin
  inherited;
  //
  f_socket.close();
  freeAndNil(f_parser);
  mrealloc(f_mdbuf);
  f_mdBufSize := 0;
end;


{ unaSHOUTtransmitter }

// --  --
procedure unaSHOUTtransmitter.close();
begin
  stop();
end;

// --  --
function unaSHOUTtransmitter.execute(threadID: unsigned): int;
var
  s, s_admin: tSOCKET;
  state: int;
  addr: sockaddr_in;
  host: PHostEnt;
  pw: aString;
  buf: aString;
  sockbuf: array[0..2047] of byte;
  sbufpos: int;
  rec, code: int;
begin
  s := 0;
  state := 0;
  sbufpos := 0;
  //
  while ((0 = f_err) and not shouldStop) do begin
    //
    case (state) of

      0: begin
	//
	// just started, try to connect to server
	//
	s := socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
	if (INVALID_SOCKET = s) then
	  f_err := c_err_SOCKET
	else begin
	  //
	  addr.sin_family := AF_INET;
	  addr.sin_addr.s_addr := inet_addr(paChar(aString(f_crack.r_hostName)));
	  if ((DWORD(INADDR_NONE) = DWORD(addr.sin_addr.s_addr)) or (INADDR_ANY = addr.sin_addr.s_addr)) then begin
	    //
	    // lookup DNS name
	    host := gethostbyname(paChar(aString(f_crack.r_hostName)));
	    if (nil = host)  then begin
	      //
	      f_err := c_err_ADDRESS;
	      break;
	    end
	    else
	      addr.sin_addr.s_addr := pUInt32(host.h_addr_list)^;
	  end;
	  //
	  if (f_dnasCompatible) then
	    addr.sin_port := htons(f_crack.r_port + 1)
	  else
	    addr.sin_port := htons(f_crack.r_port);
	  //
	  if (SOCKET_ERROR = connect(s, addr, sizeof(addr))) then
	    f_err := c_err_SOCKET
	  else
	    state := 1;
	end;
      end;

      1: begin
	// just connected, say hi to server
	if (f_dnasCompatible) then begin
	  //
	  buf := aString(f_crack.r_password) + #10;
	end
	else begin
	  //
	  if ('' = f_crack.r_userName) then
	    pw := 'source'
	  else
	    pw := aString(f_crack.r_userName);
	  //
	  pw := base64encode(pw + ':' + aString(f_crack.r_password));
	  //
	  buf := 'SOURCE ' + aString(f_crack.r_path) + ' HTTP/1.0'#13#10 +
		 'Authorization: Basic ' + pw + #13#10 +
		 'User-Agent: VC2icecast/1.0'#13#10 +
		 'Content-Type: audio/mpeg'#13#10 +
		 'ice-name: ' + aString(f_ice_name) + #13#10 +
		 'ice-public: ' + aString(choice(f_ice_public, '1', '0')) + #13#10 +
		 'ice-url: ' + aString(f_ice_URL) + #13#10 +
		 'ice-genre: ' + aString(f_ice_genre) + #13#10 +
		 'ice-audio-info: bitrate=128;channels=2;samplerate=44100'#13#10 +
		 'ice-description: ' + aString(f_crack.r_extraInfo) + #13#10 +
		 #13#10;
	end;
	//
	if (SOCKET_ERROR = WinSock.send(s, buf[1], length(buf), 0)) then
	  f_err := c_err_SOCKET
	else
	  state := 2;	//
      end;

      2: begin
	//
	// wait for ice reply
	rec := recv(s, sockbuf[sbufpos], sizeof(sockbuf) - sbufpos, 0);
	if (0 < rec) then begin
	  //
	  sbufpos := sbufpos + rec;
	  //
	  // check if we got some reply
	  if (11 < sbufpos) then begin
	    //
	    if (f_dnasCompatible) then begin
	      //
	      code := pos('OK2', string(paChar(@sockbuf)));
	      if (1 = code) then begin
		//
		// update stream info
		//
		buf := 'icy-name: DNAS compatibe VC streamer'#10 +
		       'icy-genre:' + aString(f_ice_genre) + #10 +
		       'icy-url:' + aString(f_ice_URL) + #10 +
		       'icy-irc:#shoutcast'#10 +
		       'icy-icq:ICQ'#10 +
		       'icy-aim:AIM'#10 +
		       'icy-pub:' + aString(choice(f_ice_public, '1', '0')) + #10 +
		       'icy-br:24'#10 +
		       'content-type:audio/mpeg'#10 +
		       #10;
		//
		if (SOCKET_ERROR = WinSock.send(s, buf[1], length(buf), 0)) then
		  f_err := c_err_SOCKET
		else begin
		  //
		  // update song info
		  // (should be done periodically, TODO)
		  //
		  s_admin := socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
		  if (INVALID_SOCKET <> s_admin) then begin
		    //
		    addr.sin_port := htons(f_crack.r_port);
		    if (SOCKET_ERROR = connect(s_admin, addr, sizeof(addr))) then
		      f_err := c_err_SOCKET
		    else begin
		      //
		      // seems to be some problem with that request, not sure why
		      //
		      buf := 'GET /admin.cgi?pass=' + aString(f_crack.r_password) + '&mode=updinfo&song=toolazynow.mp3&url= HTTP/1.0'#10 +
			     'User-Agent: DNAS compatibe VC streamer'#10#10;
		      //
		      if (SOCKET_ERROR = WinSock.send(s_admin, buf[1], length(buf), 0)) then
			f_err := c_err_SOCKET
		      else begin
			setSocket(s);        // can start sending audio now
			state := 3;
                      end;
		    end;
		  end;
		end;
	      end
	      else
		f_err := c_err_ICE;
	    end
	    else begin
	      //
	      sockbuf[12] := 0;
	      code := str2intInt(string(paChar(@sockbuf[9])), 0);
	      if (200 = code) then begin
		//
		setSocket(s);        // can start sending audio now
		state := 3;
	      end
	      else begin
		//
		if (401 = code) then
		  f_err := c_err_PASSWORD
		else begin
		  //
		  f_err := c_err_ICE;
		  f_iceErr := code;
		end;
	      end;
	    end;
	  end
	end
	else begin
	  //
	  // socket closed or some other error :(
	  f_err := c_err_SOCKET;
	end;
      end;

      3: begin
	//
	// just relax
      end;

    end;
    //
    if (0 = f_err) then
      sleepThread(20);
  end;
  //
  setSocket();        // no socket
  //
  if ((0 <> s) and (INVALID_SOCKET <> s)) then
    closesocket(s);
  //
  result := 0;
end;

// --  --
function unaSHOUTtransmitter.open(const uri: string): HRESULT;
begin
  close();
  //
  result := E_FAIL;
  //
  if (crackURI(uri, f_crack)) then begin
    //
    f_err := c_err_OK;
    f_iceErr := 0;
    f_dnasCompatible := ('DNAS' = f_crack.r_userName);
    //
    start();
    //
    result := S_OK;
  end;
end;

// --  --
function unaSHOUTtransmitter.send(buf: pointer; len: uint): uint;
begin
  result := 0;
  //
  if ((0 <> f_socket) and acquire(true, 100)) then try
    //
    if (INVALID_SOCKET <> f_socket) then begin
      //
      if (SOCKET_ERROR = WinSock.send(f_socket, buf^, len, 0)) then
	f_err := c_err_SOCKET
      else
	result := len;
    end;
    //
  finally
    releaseRO();
  end;
end;

// --  --
procedure unaSHOUTtransmitter.setSocket(socket: tSocket);
begin
  if (acquire(false, 400)) then try
    f_socket := socket;
  finally
    releaseWO();
  end
  else
    f_socket := socket;	// set anyway
end;


end.

