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

	  unaIcyStreamer.pas
	  Icy-compatible streamers

	----------------------------------------------
	  Copyright (c) 2003-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 20 May 2003

	  modified by:
		Lake, May 2003
		Lake, Aug 2004
		Lake, Feb 2006
                Lake, Jun 2009

	----------------------------------------------
*)

{$I unaDef.inc }

{*
  ICY Client and Server.

  @Author Lake

  2.5.2008.07 Still here
}

unit
  unaIcyStreamer;

interface

uses
  Windows, unaTypes, unaUtils, unaClasses, unaSockets;


type
  // --  --
  tunaIcyStreamerStatus = (iss_disconnected, iss_connecting, iss_connected);


  //
  // -- unaIcyStreamers --
  //
  unaIcyStreamers = class(unaThread)
  private
    f_host: string;
    f_port: string;
    f_URL: string;
    //
    f_status: tunaIcyStreamerStatus;
    //
    f_socks: unaSocks;
    f_socksId: unsigned;
    f_connId: unsigned;
    f_timeOut: tTimeout;
    f_connStartMark: uint64;
  protected
    procedure handleStatus(); virtual; abstract;
    procedure handleSocketEvent(event: unaSocketEvent; id, connId: tConID; data: pointer; len: uint); virtual; abstract;
    //
    function execute(threadIndex: unsigned): int; override;
    procedure onSocksEvent(sender: tObject; event: unaSocketEvent; id, connId: tConID; data: pointer; size: uint);
    //
    procedure startIn(); override;
    procedure startOut(); override;
    //
    function sendDataTo(data: pointer; len: unsigned; id, connId: unsigned): unsigned;
  public
    constructor create(const host, port: string);
    //
    procedure AfterConstruction(); override;
    procedure BeforeDestruction(); override;
    //
    function sendData(data: pointer; len: unsigned): unsigned;
    function sendText(const text: aString): unsigned;
    //
    property host: string read f_host write f_host;
    property port: string read f_port write f_port;
    property URL: string read f_URL write f_URL;
    //
    property status: tunaIcyStreamerStatus read f_status;
    property timeOut: tTimeout read f_timeOut write f_timeOut;
  end;


  //
  // -- ICY stream provider --
  //
  unaIcyStreamProvider = class(unaIcyStreamers)
  private
    f_password: aString;	// must not be empty
    f_title: string;
    f_genre: string;
    f_allowPublishing: bool;
    f_bitrate: int;
    f_passIsOK: bool;
    //
    f_socksIdPush: unsigned;
    //
    f_icyCaps: int;
    //
    procedure setPassword(const value: aString);
    function getPassword(): aString;
    procedure extractCaps(const data: string);
    procedure sendStreamMetadata();
  protected
    procedure handleStatus(); override;
    procedure handleSocketEvent(event: unaSocketEvent; id, connId: tConID; data: pointer; len: uint); override;
    procedure startIn(); override;
  public
    function pushSongTitle(const title: string; const url: string = ''): HRESULT;
    //
    property password: aString read getPassword write setPassword;
    property title: string read f_title write f_title;
    property genre: string read f_genre write f_genre;
    property bitrate: int read f_bitrate write f_bitrate;
    property allowPublishing: bool read f_allowPublishing write f_allowPublishing;
    //
    property icyCaps: int read f_icyCaps;
    property passwordIsOK: bool read f_passIsOK;
  end;


  //
  tunaIcySongInfoUpdate = procedure(sender: tObject; const newTitle, newUrl: string) of object;
  tunaIcyDataAvailable = procedure(sender: tObject; data: pointer; size: unsigned) of object;

  //
  // -- ICY stream consumer --
  //
  unaIcyStreamConsumer = class(unaIcyStreamers)
  private
    f_header: string;
    f_headerIsDone: bool;
    f_songTitle: string;
    f_songUrl: string;
    //
    f_metaDataAlign: unsigned;
    f_dataBuf: unaMemoryStream;
    f_isMetaData: bool;
    f_metaDataSize: unsigned;
    f_metaDataBuf: pointer;
    f_metaDataBufSize: unsigned;
    //
    f_onSIU: tunaIcySongInfoUpdate;
    f_onDA: tunaIcyDataAvailable;
    //
    procedure sendHello(id: int = -1; connId: int = -1);
    procedure checkMetadata(size: unsigned; ptext: pointer); overload;
    procedure checkMetadata(); overload;
    procedure notifyAudioFromBuf();
    function loadMetaDataFromBuf(): unsigned;
  protected
    procedure handleStatus(); override;
    procedure handleSocketEvent(event: unaSocketEvent; id, connId: tConID; data: pointer; len: uint); override;
    procedure startIn(); override;
    procedure startOut(); override;
    //
    procedure updateSongInfo(const title, url: string); virtual;
    procedure dataAvail(data: pointer; size: unsigned); virtual;
  public
    procedure AfterConstruction(); override;
    procedure BeforeDestruction(); override;
    //
    function getServerHeaderValue(const key: string): string;
    //
    property serverHeader: string read f_header;
    property songTitle: string read f_songTitle;
    property songUrl: string read f_songUrl;
    //
    property onSongInfoUpdate: tunaIcySongInfoUpdate read f_onSIU write f_onSIU;
    property onDataAvailable: tunaIcyDataAvailable read f_onDA write f_onDA;
  end;


const
  // --  --
  c_maxClientsPerServer	= 4096;

type
  unaIcyServer = class;

  //
  // -- unaIcyServerClientConnection --
  //
  unaIcyServerClientConnection = class(unaObject)
  private
    f_server: unaIcyServer;
    f_serverId: unsigned;
    f_connId: unsigned;
    f_timeMark: uint64;
    f_streamPos: unsigned;
    f_metadata: unaStringList;
    f_metaDataAlign: unsigned;
    //
    f_verLevel: int;	// if 2 or greater, that means OK
    f_header: string;
  public
    constructor create(server: unaIcyServer; serverId, connId, metaDataAlign: unsigned);
    procedure AfterConstruction(); override;
    procedure BeforeDestruction(); override;
    //
    procedure write(data: pArray; len: unsigned);
    function checkTimeout(timeout: tTimeout): bool;
    //
    property connId: unsigned read f_connId;
    property metadata: unaStringList read f_metadata;
    property verLevel: int read f_verLevel write f_verLevel;
    property header: string read f_header write f_header;
  end;

  //
  // -- unaIcyServerClientList --
  //
  unaIcyServerClientList = class(unaIdList)
  protected
    function getId(item: pointer): int64; override;
  public
    constructor create();
  end;


  {*
  	ICY server
  }
  unaIcyServer = class(unaIcyStreamers)
  private
    f_maxClients: unsigned;
    f_metaDataAlign: unsigned;
    f_bitrate: int;
    f_special: string;
    //
    f_clients: unaIcyServerClientList;
    f_dataStream: unaMemoryStream;
    f_dataBuf: pArray;
    f_dataBufSize: unsigned;
    //
    f_metaDataStream: unaMemoryStream;
    f_metaDataBuf: aString;
    //
    f_clientsToDrop: array[byte] of unsigned;	// connIDs
    f_clientsToDropCount: unsigned;
    //
    f_servedBytes: int64;
    //
    procedure onNewClientData(connId: unsigned; data: pArray; len: unsigned);
  protected
    procedure handleStatus(); override;
    procedure handleSocketEvent(event: unaSocketEvent; id, connId: tConID; data: pointer; len: uint); override;
  public
    constructor create(const port: string; maxClients: unsigned = 3; metaDataAlign: unsigned = $2000; bitrate: int = 128; const special: string = '');
    procedure AfterConstruction(); override;
    procedure BeforeDestruction(); override;
    //
    function write(data: pArray; len: unsigned): unsigned;
    function writeMetadata(const title, url: aString): unsigned;
    //
    property clients: unaIcyServerClientList read f_clients;
    property servedBytes: int64 read f_servedBytes;
  end;


{*
  
}
function iss2str(status: tunaIcyStreamerStatus): string;


implementation


uses
  WinSock;

// --  --
function iss2str(status: tunaIcyStreamerStatus): string;
const
  statusStr: array[tunaIcyStreamerStatus] of string =
    ('disconnected', 'connecting', 'connected');
begin
  result := statusStr[status];
end;


{ unaIcyStreamers }

// --  --
procedure unaIcyStreamers.afterConstruction();
begin
  f_socks := unaSocks.create();
  f_socks.onEvent := onSocksEvent;
  //
  inherited;
end;

// --  --
procedure unaIcyStreamers.beforeDestruction();
begin
  inherited;
  //
  freeAndNil(f_socks);
end;

// --  --
constructor unaIcyStreamers.create(const host, port: string);
begin
  f_host := host;
  f_port := port;
  f_timeOut := 5000;	// 5 sec.
  //
  inherited create();
end;

// --  --
function unaIcyStreamers.execute(threadIndex: unsigned): int;
begin
  while (not shouldStop) do begin
    //
    handleStatus();
    //
    sleep(100);	// sleep while nothing to do
  end;
  //
  f_status := iss_disconnected;
  result := 0;
end;

// --  --
procedure unaIcyStreamers.onSocksEvent(sender: tObject; event: unaSocketEvent; id, connId: tConID; data: pointer; size: uint);
begin
  handleSocketEvent(event, id, connId, data, size);
  //
  wakeUp();
end;

// --  --
function unaIcyStreamers.sendData(data: pointer; len: unsigned): unsigned;
begin
  result := sendDataTo(data, len, f_socksId, f_connId);
end;

// --  --
function unaIcyStreamers.sendDataTo(data: pointer; len, id, connId: unsigned): unsigned;
var
  asynch: bool;
begin
  if (0 < id) then
    result := f_socks.sendData(id, data, len, connId, asynch)
  else
    result := WSANOTINITIALISED;
end;

// --  --
function unaIcyStreamers.sendText(const text: aString): unsigned;
begin
  if (0 < length(text)) then
    result := sendData(@text[1], length(text))
  else
    result := 0;
end;

// --  --
procedure unaIcyStreamers.startIn();
begin
  f_socksId := 0;
  f_status := iss_disconnected;
  //
  inherited;
end;

// --  --
procedure unaIcyStreamers.startOut();
var
  id: unsigned;
begin
  if (0 < f_socksId) then begin
    //
    id := f_socksId;
    f_socksId := 0;
    f_socks.closeThread(id);
  end;
  //
  inherited;
end;


{ unaIcyStreamProvider }

// --  --
procedure unaIcyStreamProvider.extractCaps(const data: string);
var
  capsPos: int;
  caps: string;
  i: int;
begin
  capsPos := pos('icy-caps:', string(loCase(data)));
  //
  if (0 < capsPos) then begin
    //
    inc(capsPos, length('icy-caps:'));
    caps := copy(data, capsPos, maxInt);
    //
    i := 1;
    while (i < length(caps)) and (aChar(caps[i]) in ['0'..'9']) do
      inc(i);
    //
    caps := copy(caps, 1, i - 1);
    f_icyCaps := str2intInt(caps, 0);
  end;
end;

// --  --
function unaIcyStreamProvider.getPassword(): aString;
begin
  result := trimS(f_password);
end;

// --  --
procedure unaIcyStreamProvider.handleSocketEvent(event: unaSocketEvent; id, connId: tConID; data: pointer; len: uint);
var
  str: aString;
  reply: paChar;
begin
  case (event) of

    // -- client --

    unaseClientConnect: begin
      //
      if (f_socksIdPush = id) then begin
	//
	str := aString('GET /admin.cgi?pass=' + urlEncode(string(password)) + '&mode=updinfo&song=' + urlEncode(title) + '&url=' + urlEncode(url) + ' HTTP/1.0'#10 +
	               'User-Agent: VC IcyStreamer (Mozilla Compatible)'#10#10);
	//
	sendDataTo(@str[1], length(str), id, connId);
	//
	Sleep(100);
	//
	f_socks.closeThread(id);
      end
      else begin
	//
	// check if we are waiting for data channel connection
	f_connId := connId;
	if (status = iss_connecting) then begin
	  //
	  // send hello (password) to data server
	  sendDataTo(@f_password[1], length(f_password), id, connId);
	end;
      end;
    end;

    unaseClientData: begin
      //
      // check if we are waiting for server authorization reply
      if ((status = iss_connecting) and (id = f_socksId)) then begin
	//
	// check reply
	reply := data;
	if (1 = pos('OK2', string(reply))) then begin
	  //
	  // get server caps
	  extractCaps(string(reply));
	  // send metadata
	  sendStreamMetadata();
	  // indicate we are ready
	  f_status := iss_connected;
	end
	else
	  if (1 = pos('invalid password', string(reply))) then begin
	    //
	    // password is invalid, stop thread
	    f_passIsOK := false;
	    askStop();
	  end;
      end;
    end;

    unaseClientDisconnect,
    unaseThreadStartupError: begin
      //
      if (id = f_socksId) then begin
	// have to stop due to connection error/disconnection
	askStop();
      end;
    end;

  end;
end;

// --  --
procedure unaIcyStreamProvider.handleStatus();
var
  dataPort: word;
begin
  case (status) of

    iss_disconnected: begin
      //
      f_status := iss_connecting;
      f_connStartMark := timeMarkU();
      //
      // start data connection
      dataPort := str2intUnsigned(port, 8000) + 1;
      f_socksId := f_socks.createConnection(host, int2str(dataPort));
    end;

    iss_connecting: begin
      // check if we had timed out
      if (timeOut < tTimeOut(timeElapsed32U(f_connStartMark))) then
	askStop();
    end;

    iss_connected: begin
      //
    end;

  end;
end;

// --  --
function unaIcyStreamProvider.pushSongTitle(const title, url: string): HRESULT;
begin
  // start HTTP-push connection
  f_socksIdPush := f_socks.createConnection(host, port);
  // TODO?
  result := HRESULT(-1);
end;

// --  --
procedure unaIcyStreamProvider.sendStreamMetadata();
var
  data: string;
begin
  data := 'icy-name:' + f_title + #10 +
	  'icy-genre:' + f_genre + #10 +
	  'icy-url:' + f_url + #10 +
	  'icy-irc:#none' + #10 +
	  'icy-icq:0' + #10 +
	  'icy-aim:N/A' + #10 +
	  'icy-pub:' + choice(f_allowPublishing, '1', '0') + #10 +
	  'icy-br:' + int2str(f_bitrate) + #10#10;
  //
  sendText(aString(data));
end;

// --  --
procedure unaIcyStreamProvider.setPassword(const value: aString);
begin
  assert('' <> trimS(value), 'Password must not be empty');
  //
  f_password := trimS(value) + #10;
end;

// --  --
procedure unaIcyStreamProvider.startIn();
begin
  f_passIsOK := true;
  //
  inherited;
end;


{ unaIcyStreamConsumer }

// --  --
procedure unaIcyStreamConsumer.afterConstruction();
begin
  inherited;
  //
  f_dataBuf := unaMemoryStream.create();
  f_dataBuf.maxCacheSize := 100;	// give this stream lots of buffers
end;

// --  --
procedure unaIcyStreamConsumer.beforeDestruction();
begin
  inherited;
  //
  freeAndNil(f_dataBuf);
end;

// --  --
procedure unaIcyStreamConsumer.checkMetadata(size: unsigned; ptext: pointer);
var
  text: aString;

  function getValue(vstart: unsigned): string;
  var
    vend: unsigned;
  begin
    vend := vstart;
    //
    while ((vend < size) and (text[vend] <> '''')) do
      inc(vend);
    //
    if ((vend < size) and (text[vend] = '''')) then
      dec(vend);
    //
    result := copy(string(text), vstart, vend + 1 - vstart );
  end;

var
  vpos: int;
  title: string;
  url: string;
begin
  if (0 < size) then begin
    //
    setLength(text, size);
    move(pText^, text[1], size);
  end
  else
    text := '';
  //
  vpos := pos('streamtitle=''', string(loCase(text)));
  if (0 < vpos) then
    title := getValue(vpos + length('streamtitle='''));
  //
  vpos := pos('streamurl=''', string(loCase(text)));
  if (0 < vpos) then
    url := getValue(vpos + length('streamurl='''));
  //
  if ('' = title) then
    // try Ice 1.3 header
    title := getServerHeaderValue('x-audiocast-name');
  //
  if ('' = url) then
    // try Ice 1.3 header
    url := getServerHeaderValue('x-audiocast-url');
  //
  updateSongInfo(title, url);
end;

// --  --
procedure unaIcyStreamConsumer.checkMetadata();
begin
  checkMetaData(loadMetaDataFromBuf(), paChar(f_metaDataBuf));
end;

// --  --
procedure unaIcyStreamConsumer.dataAvail(data: pointer; size: unsigned);
begin
  if (assigned(f_onDA)) then
    f_onDA(self, data, size);
end;

// --  --
function unaIcyStreamConsumer.getServerHeaderValue(const key: string): string;
var
  vpos: int;
  vend: int;
  len: int;
begin
  result := '';
  len := length(f_header);
  //
  if (0 < len) then begin
    //
    vpos := pos(loCase(key) + ':', loCase(f_header));
    if (0 < vpos) then begin
      //
      inc(vpos, length(key) + 1);
      vend := vpos;
      //
      while ((vend < len) and (f_header[vend] <> #13) and (f_header[vend] <> #10)) do
	inc(vend);
      //
      result := trimS(copy(f_header, vpos, vend + 1 - vpos));
    end;
  end;
end;

// --  --
procedure unaIcyStreamConsumer.handleSocketEvent(event: unaSocketEvent; id, connId: tConID; data: pointer; len: uint);
var
  text: paChar;
  eoh: int;
  blockSize: unsigned;
  dataLeft: int;
begin
  case (event) of

    // -- client --

    unaseClientConnect: begin
      //
      // check if we are waiting for channel connection
      f_connId := connId;
      if (status = iss_connecting) then begin
	//
	// send hello (GET / HTTP/1.0) to server
	sendHello(id, connId);
      end;
    end;

    unaseClientData: begin
      //
      // got some data from server
      if (0 < len) then begin
	//
	text := data;
	dataLeft := len;
	//
	if (
	     (status = iss_connecting) and (
	       (1 = pos('ICY 200', string(text))) or
	       (1 = pos('HTTP/1.0 200', string(text))) or
	       (1 = pos('HTTP/1.1 200', string(text)))
	     )
	   ) then
	  f_status := iss_connected;
	//
	if (not f_headerIsDone) then begin
	  //
	  eoh := pos(#13#10#13#10, string(text));
	  if (0 < eoh) then
	    f_headerIsDone := true
	  else
	    eoh := len + 1;
	  //
	  f_header := f_header + copy(string(text), 1, eoh - 1);
	  //
	  inc(text, eoh + 3);
	  dec(dataLeft, eoh + 3);
	  //
	  if (f_headerIsDone) then begin
	    //
	    f_dataBuf.clear();
	    f_metaDataAlign := str2intInt(getServerHeaderValue('icy-metaint'), 0);
	    f_isMetaData := false;	// stream starts with audio data
	    //
	    checkMetadata();
	  end;
	end;
	//
	if (f_headerIsDone) then
	  //
	  while (0 < dataLeft) do begin
	    //
	    if (f_isMetaData) then begin
	      //
	      if (0 = f_metaDataSize) then begin
		// we are at the beginning of metadata
		f_metaDataSize := ord(text[0]) shl 4;
		inc(text);
		dec(dataLeft);
	      end;
	      //
	      if (int(f_dataBuf.getSize()) + dataLeft >= int(f_metaDataSize)) then begin
		//
		// all metadata is here
		if (0 < f_metaDataSize) then begin
		  // notify about metadata
		  //
		  // check if we can notify directly from text
		  if ((1 > f_dataBuf.getSize()) and (dataLeft >= int(f_metaDataSize))) then
		    // yes, we can
		    checkMetadata(f_metaDataSize, text)
		  else begin
		    // no, notify from buffer
		    blockSize := f_dataBuf.write(text, int(f_metaDataSize) - f_dataBuf.getSize());
		    inc(text, blockSize);
		    dec(dataLeft, blockSize);
		    //
		    checkMetadata();
		  end;
		end;
		//
		// back to audio
		inc(text, f_metaDataSize);
		dec(dataLeft, f_metaDataSize);
		//
		f_isMetaData := false;
	      end
	      else begin
		// not all metadata is here, save what we got now into buffer
		blockSize := f_dataBuf.write(text, dataLeft);
		inc(text, blockSize);
		dec(dataLeft, blockSize);
	      end;
	    end
	    else begin
	      //
	      // check if we need to care about metadata
	      if (0 < f_metaDataAlign) then begin
		//
		if (f_dataBuf.getSize() + dataLeft >= int(f_metaDataAlign)) then begin
		  // write rest of audio data into buffer
		  blockSize := f_dataBuf.write(text, int(f_metaDataAlign) - f_dataBuf.getSize());
		  // notify audio data from buffer
		  notifyAudioFromBuf();
		  //
		  inc(text, blockSize);
		  dec(dataLeft, blockSize);
		  //
		  f_isMetaData := true;
		  f_metaDataSize := 0;
		end
		else begin
		  // store data for now
		  f_dataBuf.write(text, dataLeft);
		  dataLeft := 0;
		end;
	      end
	      else begin
		// simply notify audio data
		dataAvail(text, dataLeft);
		dataLeft := 0;
	      end;
	    end;
	    //
	  end;	// WHILE (0 < dataLeft) ...
	//
      end;
    end;

    unaseClientDisconnect,
    unaseThreadStartupError: begin
      // have to stop due to connection error/disconnection
      f_connId := 0;
      askStop();
    end;

  end;
end;

// --  --
procedure unaIcyStreamConsumer.handleStatus();
begin
  case (status) of

    iss_disconnected: begin
      //
      f_status := iss_connecting;
      f_connStartMark := timeMarkU();
      // start data connection
      f_socksId := f_socks.createConnection(host, port);
    end;

    iss_connecting: begin
      // check if we had timed out
      if (timeOut < tTimeout(timeElapsed32U(f_connStartMark))) then
	askStop();
    end;

    iss_connected: begin
      //
    end;

  end;
end;

// --  --
function unaIcyStreamConsumer.loadMetaDataFromBuf(): unsigned;
begin
  result := f_dataBuf.getSize();
  if (f_metaDataBufSize < result) then begin
    //
    f_metaDataBufSize := result;
    mrealloc(f_metaDataBuf, f_metaDataBufSize);
  end;
  //
  result := f_dataBuf.read(f_metaDataBuf, result);
end;

// --  --
procedure unaIcyStreamConsumer.notifyAudioFromBuf();
var
  size: unsigned;
begin
  //
  // WARNIGN! Since f_metaDataBuf can be modified by loadMetaDataFromBuf()
  // we have to store the result (size) locally. That is because passing the
  // return value directly as second parameter for dataAvail() may lead to
  // passing invalid value as first parameter
  //
  size := loadMetaDataFromBuf();
  //
  dataAvail(f_metaDataBuf, size);
end;

// --  --
procedure unaIcyStreamConsumer.sendHello(id, connId: int);
var
  hello: aString;
  socksId: unsigned;
begin
  if (0 > id) then
    socksId := f_socksId
  else
    socksId := unsigned(id);
  //
  if (0 > connId) then
    connId := f_connId;
  //
  if ('' = trimS(f_url)) then
    f_url := '/';
  //
  hello := aString('GET ' + f_url + ' HTTP/1.0'#13#10 +
	   'Host:' + f_host + #13#10 +
	   'Accept:*/*'#13#10 +
	   'User-Agent:VC 2.5 Listener 1.0'#13#10 +
	   'Icy-Metadata:1'#13#10 +
	   #13#10);
  //
  sendDataTo(@hello[1], length(hello), socksId, connId);
end;

// --  --
procedure unaIcyStreamConsumer.startIn();
begin
  f_header := '';
  f_headerIsDone := false;
  f_songTitle := '';
  f_songUrl := '';
  //
  inherited;
end;

// --  --
procedure unaIcyStreamConsumer.startOut();
begin
  inherited;
  //
  mrealloc(f_metaDataBuf);
  f_metaDataBufSize := 0;
end;

// --  --
procedure unaIcyStreamConsumer.updateSongInfo(const title, url: string);
begin
  if ((trimS(title) <> f_songTitle) or
      (trimS(url)   <> f_songUrl)) then begin
    //
    f_songTitle := title;
    f_songUrl := url;
    //
    if (assigned(f_onSIU)) then
      f_onSIU(self, title, url);
  end;
end;


{ unaIcyServerClientConnection }

// --  --
procedure unaIcyServerClientConnection.afterConstruction();
begin
  f_metadata := unaStringList.create();
  //
  inherited;
end;

// --  --
procedure unaIcyServerClientConnection.beforeDestruction();
begin
  inherited;
  //
  freeAndNil(f_metadata);
end;

// --  --
function unaIcyServerClientConnection.checkTimeout(timeout: tTimeout): bool;
begin
  result := (2 <= verLevel) or (timeout > tTimeout(timeElapsed32U(f_timeMark)));
end;

// --  --
constructor unaIcyServerClientConnection.create(server: unaIcyServer; serverId, connId, metaDataAlign: unsigned);
begin
  f_server := server;
  f_serverId := serverId;
  f_connId := connId;
  f_metaDataAlign := metaDataAlign;
  //
  f_timeMark := timeMarkU();
  f_streamPos := 0;
  //
  inherited create();
end;

// --  --
procedure unaIcyServerClientConnection.write(data: pArray; len: unsigned);
var
  md: aString;
  sz: unsigned;
  b: byte;
  asynch: bool;
begin
  if (2 <= verLevel) then begin
    //
    if ((0 < f_metaDataAlign) and (f_metaDataAlign <= f_streamPos)) then begin
      //
      // write metadata
      if (0 < f_metadata.count) then begin
	//
	md := aString(f_metadata.get(f_metadata.count - 1));
	f_metadata.clear();
      end
      else
	md := '';	// no metadata, but we still need to write "0"
      //
      sz := length(md);
      //
      if (0 = sz) then
	b := 0
      else
	b := ((sz - 1) and $FFFFFFF0) shr 4 + 1;
      //
      if (0 < sz) then
	md := adjust(md, b shl 4, aChar(' '), false);
      //
      if (1 > b) then begin
	// simply send b as it is
	inc(f_server.f_servedBytes, f_server.f_socks.sendData(f_serverId, @b, 1, f_connId, asynch));
      end
      else begin
	//
	md := AnsiChar(b) + md;
	//
	inc(f_server.f_servedBytes, f_server.f_socks.sendData(f_serverId, @md[1], 1 + b shl 4, f_connId, asynch));
      end;
      //
      f_streamPos := 0;	// reset offset
    end;
    //
    if (0 < f_metaDataAlign) then
      sz := min(f_metaDataAlign - f_streamPos, len)
    else
      sz := len;
    //
    inc(f_server.f_servedBytes, f_server.f_socks.sendData(f_serverId, data, sz, f_connId, asynch));
    //
    inc(f_streamPos, sz);	// shift the offset
    //
    if (sz < len) then begin
      //
      // still have some data in buffer, let's recorse
      write(pArray(@data[sz]), len - sz);
    end;
  end;
end;


{ unaIcyServerClientList }

// --  --
constructor unaIcyServerClientList.create();
begin
  // simply tell the parent we are dealing with objects
  inherited create(uldt_obj);
end;

// --  --
function unaIcyServerClientList.getId(item: pointer): int64;
begin
  if (nil <> item) then
    result := unaIcyServerClientConnection(item).f_connId
  else
    result := 0;
end;


{ unaIcyServer }

// --  --
procedure unaIcyServer.afterConstruction();
begin
  f_clients := unaIcyServerClientList.create();
  f_dataStream := unaMemoryStream.create();
  f_metaDataStream := unaMemoryStream.create();
  //
  inherited;
end;

// --  --
procedure unaIcyServer.beforeDestruction();
begin
  inherited;
  //
  f_dataBufSize := 0;
  mrealloc(f_dataBuf);
  //
  freeAndNil(f_clients);
  freeAndNil(f_dataStream);
  freeAndNil(f_metaDataStream);
end;

// --  --
constructor unaIcyServer.create(const port: string; maxClients, metaDataAlign: unsigned; bitrate: int; const special: string);
begin
  f_maxClients := min(maxClients, c_maxClientsPerServer);
  f_metaDataAlign := metaDataAlign;
  f_bitrate := bitrate;
  f_special := special;
  //
  inherited create('', port);
end;

// --  --
procedure unaIcyServer.handleSocketEvent(event: unaSocketEvent; id, connId: tConID; data: pointer; len: uint);
var
  index: int;
begin
  //
  case (event) of

    // -- client --
    // do not care about client, we have only server here

    // -- server --

    unaseServerConnect: begin
      //
      if (f_clients.count < int(f_maxClients)) then begin
	//
	// accept new client
	f_clients.add(unaIcyServerClientConnection.create(self, id, connId, f_metaDataAlign));
	//
	if (iss_connecting = status) then
	  f_status := iss_connected;
      end
      else
	// drop the client
	f_socks.removeConnection(id, connId);
    end;

    unaseServerData: begin
      //
      onNewClientData(connId, data, len);
    end;

    unaseServerDisconnect: begin
      //
      // drop the client
      index := f_clients.indexOfId(connId);
      //
      if (0 <= index) then
	f_clients.removeByIndex(index);
      //
      if ((1 > f_clients.count) and (iss_connected = status)) then
	f_status := iss_connecting;	// return to sleepy mode
    end;

    // thread
    unaseThreadStartupError: begin
      //
      askStop();
    end;

  end;
end;

{

Possible server replies:

  ICY 401 Service Unavailable
  icy-notice1:<BR>SHOUTcast Distributed Network Audio Server/win32 v1.9.2<BR>
  icy-notice2:The resource requested is currently unavailable<BR>


  ICY 200 OK
  icy-notice1:<BR>This stream requires <a href="http://www.winamp.com/">Winamp</a><BR>
  icy-notice2:SHOUTcast Distributed Network Audio Server/win32 v1.9.2<BR>
  icy-name:VC 2.5 Streamer
  icy-genre:Rock2
  icy-url:http://lakeofsoft.com/vc/
  Content-Type:audio/mpeg
  icy-pub:0
  icy-metaint:8192
  icy-br:96


Metadata example:

  StreamTitle='';StreamUrl='';

}

// --  --
procedure unaIcyServer.handleStatus();
var
  i: unsigned;
  sz: unsigned;
begin
  //
  case (status) of

    iss_disconnected: begin
      //
      f_status := iss_connecting;
      //
      // start data connection
      f_socksId := f_socks.createServer(port, f_connId);
    end;

    iss_connecting: begin
      //
    end;

    iss_connected: begin
      //
      // check if we have metadata to send
      sz := f_metaDataStream.firstChunkSize();
      if ((0 < sz) and (0 < f_clients.count)) then begin
	//
	setLength(f_metaDataBuf, sz);
	sz := f_metaDataStream.read(@f_metaDataBuf[1], sz);
	//
	if ((0 < sz) and lockNonEmptyList_r(f_clients, true, 100 {$IFDEF DEBUG }, '.handleStatus(_iss_connected_)'{$ENDIF DEBUG } )) then begin
	  //
	  try
	    //
	    for i := 0 to f_clients.count - 1 do begin
	      //
	      unaIcyServerClientConnection(f_clients[i]).metadata.add(string(f_metaDataBuf));
	    end;
	  finally
	    f_clients.unlockRO();
	  end;
	end;
      end;
      //
      sz := f_dataStream.getSize();
      //
      if ((f_metaDataAlign < sz) and (0 < f_clients.count)) then begin
	//
	if (sz > f_dataBufSize) then begin
	  //
	  f_dataBufSize := sz;
	  mrealloc(f_dataBuf, f_dataBufSize);
	end;
	//
	sz := f_dataStream.read(f_dataBuf, sz);
	//
	if ((0 < sz) and lockNonEmptyList_r(f_clients, true, 100{$IFDEF DEBUG }, '.handleStatus(_update_meta_)'{$ENDIF DEBUG } )) then begin
	  //
	  try
	    //
	    for i := 0 to f_clients.count - 1 do begin
	      //
	      with (unaIcyServerClientConnection(f_clients[i])) do begin
		//
		if (checkTimeout(5000)) then begin	// give client 5 sec to report player ID
		  //
		  write(f_dataBuf, sz);
		end
		else begin
		  // drop this client (later)
		  if (f_clientsToDropCount < high(f_clientsToDrop)) then begin
		    //
		    f_clientsToDrop[f_clientsToDropCount] := connId;
		    inc(f_clientsToDropCount);
		  end;
		end;
		//
	      end;
	      //
	    end;
	  finally
	    f_clients.unlockRO();
	  end;
	end;
	//
      end;
      //
      //
      if (0 < f_clientsToDropCount) then begin
	//
	for i := 0 to f_clientsToDropCount - 1 do
	  f_socks.removeConnection(f_socksId, f_clientsToDrop[i]);
	//
	f_clientsToDropCount := 0;
      end;
    end;

  end;
end;

// --  --
procedure unaIcyServer.onNewClientData(connId: unsigned; data: pArray; len: unsigned);
var
  asynch: bool;
  index: int;
  hello: aString;
  p: int;
  client: unaIcyServerClientConnection;
label
  levm1, lev1, lev2;
begin
  index := f_clients.indexOfId(connId);
  //
  if (0 <= index) then begin
    //
    client := unaIcyServerClientConnection(f_clients[index]);
    with (client) do begin
      //
	{
	  possible client hello:

	  GET / HTTP/1.0
	  Host:192.168.1.1
	  Accept:*/*
	  User-Agent:VC 2.5 Listener 1.0
	  Icy-Metadata:1
	  #13#10

	}
      if (2 > verLevel) then
	// add tcp data to client request header
	header := header + string(paChar(data));
      //
      case (verLevel) of

	-1: begin
  levm1:
	  //
	  // send goodbye to client
	  hello := 'ICY 401 Service Unavailable'#13#10 +
		   ''#13#10;
	  //
	  inc(f_servedBytes, f_socks.sendData(f_socksId, @hello[1], length(hello), connId, asynch));
	  //
	end;

	0: begin
	  //
	  if (1 = pos('GET /', string(header))) then begin
	    //
	    verLevel := 1;
	    goto lev1;
	  end;
	end;

	1: begin
  lev1:
	  //
	  p := pos('User-Agent:', string(header));
	  //
	  if (0 < p) then begin
	    //
	    if (('' = f_special) or (0 < pos(f_special, string(paChar(@header[p]))))) then begin
	      //
	      verLevel := 2;
	      goto lev2;
	    end
	    else begin
	      // check if all header is here
	      if (0 < pos(#13#10#13#10, string(header))) then begin
		//
		// say goodbye to client
		verLevel := -1;
		goto levm1;
	      end;
	    end;
	    //
	  end;
	end;

	2: begin
  lev2:
	  //
	  verLevel := 3;	// do not send hello again
	  //
	  // send hello to client
	  hello := aString('ICY 200 OK'#13#10 +
		   'icy-notice1:<BR>This stream requires Winamp or compatible player<BR>'#13#10 +
		   'icy-notice2:SHOUTcast compatible Audio Server v1.0 (c) Lake of Soft, Ltd<BR>'#13#10 +
		   'icy-name:Live Streamer 1.0'#13#10 +
		   'icy-genre:Rock'#13#10 +
		   'icy-url:http://lakeofsoft.com/vc/'#13#10 +
		   'Content-Type:audio/mpeg'#13#10 +
		   'icy-pub:0'#13#10 +
		   'icy-metaint:' + int2str(f_metaDataAlign) + #13#10 +
		   'icy-br:' + int2str(f_bitrate) + #13#10#13#10);
	  //
	  inc(f_servedBytes, f_socks.sendData(f_socksId, @hello[1], length(hello), connId, asynch));
	end;

      end;  // case
      //
    end;  // with
  end;
end;

// --  --
function unaIcyServer.write(data: pArray; len: unsigned): unsigned;
begin
  result := 0;
  //
  if (0 < f_clients.count) then begin
    //
    result := f_dataStream.write(data, len);
    //
    wakeUp();
  end
  else
    f_dataStream.clear();
end;

// --  --
function unaIcyServer.writeMetadata(const title, url: aString): unsigned;
var
  data: aString;
begin
  data := 'StreamTitle=''' + title + ''';StreamUrl=''' + url + '''';
  //
  result := f_metaDataStream.write(@data[1], length(data));
  //
  wakeUp();
end;


end.


