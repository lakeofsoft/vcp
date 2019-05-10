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

	  unaIOCPSockets.pas
	  Windows sockets wrapper classes (IOCP model)

	----------------------------------------------
	  Copyright (c) 2007-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, Dec 2007

	  modified by:
		Lake, Dec 2007
		Lake, Jan-Nov 2008
		Lake, Jan-May 2009

	----------------------------------------------
*)

{$I unaDef.inc }

{$IFDEF VC25_WINSOCK20 }
{$ELSE }
    {$MESSAGE ERROR 'VC25_WINSOCK20 symbol must be defined' }
{$ENDIF VC25_WINSOCK20 }

{$IFDEF VC25_IOCP }
{$ELSE }
    {$MESSAGE ERROR 'VC25_IOCP symbol must be defined' }
{$ENDIF VC25_IOCP }

{$IFNDEF NO_ANSI_SUPPORT }
    {$MESSAGE ERROR 'NO_ANSI_SUPPORT symbol should be defined' }
{$ENDIF NO_ANSI_SUPPORT }

{$IFDEF DEBUG }
  {x $DEFINE LOG_SOCKS_THREADS }	// log main thread routines
  {x $DEFINE LOG_WORKER_THREADS }	// log worker thread routines
{$ENDIF DEBUG }

//
{$IFDEF LOG_SOCKS_THREADS }
  {$DEFINE LOG_ENABLED }
{$ELSE }
  {$IFDEF LOG_WORKER_THREADS }
    //
    {$DEFINE LOG_ENABLED }
    //
  {$ENDIF LOG_WORKER_THREADS }
{$ENDIF LOG_SOCKS_THREADS }

{*

  @Author Lake

  2.5.2009.05 - occasional UDP timeouts bug fixed.

}

unit
  unaIOCPSockets;

interface

uses
  Windows, unaTypes, WinSock,
  unaClasses, unaSockets, unaIOCP, unaWSASockets;


type
  //
  // -- unaIOCPSocks --
  //
  unaIOCPSocks = class(unaSocks)
  private
  public
  end;


const
  // IO Operations
  OP_ACCEPT     = 0;    // AcceptEx()
  OP_RECV	= 1;    // WSARecv()
  OP_SEND	= 2;	// WSASend()
  OP_RECVFROM	= 3;	// WSARecvFrom()
  OP_SENDTO	= 4;	// WSASendTo()

  //
  c_max_OLs		= 65536;	// max number of OLs

  // max buf sizes
  c_max_tcp_buf	= 4096;
  c_max_udp_buf	= 2048;

  //
  c_max_iocp_threads	= 256;

  //
  c_socket_write_timeout		= 15000;	// how long socket can remain in "cannot write to" state (ms)

var
  v_max_iocp_threads: unsigned		= c_max_iocp_threads;		// max number of threads in a pool
  v_iocp_threadsPerCore: unsigned	= 2;				// number of IOCP threads per CPU core

type
  //
  // -- unaIOCPSockWorkerOL --
  //
  punaIOCPSockWorkerOL = ^unaIOCPSockWorkerOL;
  unaIOCPSockWorkerOL = packed record
    //
    ol: WSAOVERLAPPED;
    op: int;         	// type of operation submitted
    //
    {$IFDEF DEBUG }
    opPostNum: int;
    opNopostNum: int;
    {$ENDIF DEBUG }
    //
    sc: tSocket;		// socket
    acceptSocket: tSocket;	// socket for accept op
    socketOwner: bool;	// does this OL has ownership of the socket?
    //
    connId: tConID;		// connection ID
    //
    wbuf: WSABUF;	// data buffer
    //
    addrLocal: sockaddr_in;
    addrLocalLen: int;
    //
    addrRemote: sockaddr_in;
    addrRemoteLen: int;
    addrRemoteFixed: bool;	// do not clear remote addr after successfull RECVFROM
    //
    acquired: int;	// acquired if not 0
    acTimemark: uint64;
    //
    olDataTimemark: uint64;	// last data received at..
    olIsReceiver: bool;		// is this OL stands for receiving? ( see BUG: 23 MAY'09 )
    //
    isDone: bool;	// done, worker thread should stop processing
  end;

  //
  unaIOCPSocksThread = class;

  //
  // -- unaIOCPSockWorkerThread --
  //
  unaIOCPSockWorkerThread = class(unaIOCPWorkerThread)
  private
    f_index: tConID;
    f_master: unaIOCPSocksThread;
    //
    f_waiting: uint64;
    f_working: uint64;
    f_busy: int;
    //
  protected
    function execute(threadID: unsigned): int; override;
    //
    procedure onIOComplete(numBytes, key: DWORD; o: POVERLAPPED); override;
    procedure onIOError(key: DWORD; o: POVERLAPPED; err: DWORD); override;
  public
    constructor create(index: tConID; master: unaIOCPSocksThread; port: unaIOCPClass; activate: bool; prio: DWORD = THREAD_PRIORITY_TIME_CRITICAL; timeout: tTimeout = 200);
    //
    property index: tConID read f_index;
  end;


  //
  // -- unaIOCPOLList --
  //
  unaIOCPOLList	= class(unaRecordList)
  private
    f_master: unaIOCPSocksThread;
  protected
    procedure releaseItem(index: int; doFree: unsigned); override;
  public
    constructor create(master: unaIOCPSocksThread);
  end;


  //
  // -- unaIOCPSocksThread_stats --
  //
  unaIOCPSocksThread_stats = packed record
    //
    r_num_workerThreads: unsigned;
    r_num_OL: int;			// number of OLs
    r_num_OL_done: int;		// number of "done" OLs
    r_num_OL_acquired: int;	// number of acquired OLs
    //
    r_workerWait: array[byte] of int64;
    r_workerWork: array[byte] of int64;
    r_workerBusy: array[byte] of int;
  end;


  //
  // -- unaIOCPSocksThread --
  //
  unaIOCPSocksThread = class(unaSocksThread)
  private
    f_port: unaIOCPClass;
    f_pool: array[0..c_max_iocp_threads - 1] of unaIOCPSockWorkerThread;
    f_poolThreadCount: unsigned;
    //
    f_ready: bool;
    f_spawnCount: unsigned;
    //
    f_olist: unaIOCPOLList;
    f_terminated: tHandle;
    //
    f_olDoneCount: int;
    f_olAcquiredCount: int;
    //
    f_acceptEx: proc_acceptEx;
    f_getAcceptExSockaddrs: proc_getAcceptExSockAddrs;
    f_maxDataSize: unsigned;
    //
    f_proto: int;
    f_s: tSocket;
    //
{$IFDEF LOG_SOCKS_THREADS }
    f_hadleIO_cnt: int;
    f_postRq_cnt: int;
{$ENDIF LOG_SOCKS_THREADS }
    //
    function addNewOL(acquire: bool = true): punaIOCPSockWorkerOL;
    //
    function acquireOL(index: unsigned): bool; overload;
    function acquireOL(item: punaIOCPSockWorkerOL): bool; overload;
    procedure releaseOL(index: unsigned); overload;
    procedure releaseOL(item: punaIOCPSockWorkerOL); overload;
    {*
	Try to find unaquired OL. If none, create.
    }
    function acquireOL(): punaIOCPSockWorkerOL; overload;
    //
    procedure createPortAndThreads();
    procedure releasePortAndThreads();
    //
    {$IFDEF LOG_ENABLED }
    function OLinfo(item: punaIOCPSockWorkerOL): string;
    {$ENDIF LOG_ENABLED }
  protected
    function execute(globalIndex: unsigned): int; override;
    //
    function sendDataTo(connId: tConID; data: pointer; len: uint; out asynch: bool; timeout: tTimeout): int; override;
    function doGetRemoteHostAddr(connId: tConID): pSockAddrIn; override;
    //
    function postRequest(item: punaIOCPSockWorkerOL; op: int; flags: DWORD; out itemKilled: bool): int;
    function handleIO(worker: unaIOCPSockWorkerThread; item: punaIOCPSockWorkerOL; bytesReceived: DWORD; key: DWORD; out itemKilled: bool): int;
  public
    procedure AfterConstruction(); override;
    procedure BeforeDestruction(); override;
    //
    function removeConnection(connId: tConID; item: pointer = nil): bool;
    {$IFDEF DEBUG }
    procedure ol_getStats(out stats: unaIOCPSocksThread_stats);
    property ol_List: unaIOCPOLList read f_olist;
    {$ENDIF DEBUG }
    //
    property iocpPort: unaIOCPClass read f_port;
  end;


implementation


uses
  unaUtils;


{ unaIOCPSockWorkerThread }

// --  --
constructor unaIOCPSockWorkerThread.create(index: tConID; master: unaIOCPSocksThread; port: unaIOCPClass; activate: bool; prio: DWORD; timeout: tTimeout);
begin
  f_index := index;
  f_master := master;
  //
  inherited create(port, activate, prio, timeout);
end;

// --  --
function unaIOCPSockWorkerThread.execute(threadID: unsigned): int;
var
  numBytes: DWORD;
  key: DWORD;
  ol: LPWSAOVERLAPPED;
  fatal: unsigned;
  err: int;
  //
  waitTM, workTM, busyTM: uint64;
begin
{$IFDEF LOG_WORKER_THREADS }
  logMessage('WORKER.execute(' + choice(f_master.isServer, 'SRV', 'CLN') + ') - ENTER (timeout = ' + int2str(timeout) + ')..');
{$ENDIF LOG_WORKER_THREADS }
  //
  if (iocpAvailable()) then begin
    //
    fatal := 0;
    workTM := 0;
    busyTM := timeMarkU();
    //
    while (not shouldStop) do begin
      //
      try
	if (0 <> workTM) then
	  inc(f_working, timeElapsed64U(workTM));
	//
	f_busy := percent(timeElapsed64U(workTM), timeElapsed64U(busyTM));
	busyTM := timeMarkU();
	//
	waitTM := timeMarkU();
	if (g_getQCS(port.handle, numBytes, key, ol, timeout)) then begin
	  //
	  workTM := timeMarkU();
	  inc(f_waiting, timeElapsed64U(waitTM));
	  //
	  if ((nil <> ol) and (0 > f_master.f_olist.indexOf(ol))) then begin
	    //
	    {$IFDEF LOG_WORKER_THREADS }
	    logMessage('WORKER.e(): alien OL=$' + int2str(UIntPtr(OL)));
	    {$ENDIF LOG_WORKER_THREADS }
	    //
	    continue; // not "our" OL
	  end;
	  //
	  {$IFDEF LOG_WORKER_THREADS }
	  if (nil <> ol) then
	    logMessage('WORKER.e(): ' + f_master.OLinfo(punaIOCPSockWorkerOL(ol)));
	  {$ENDIF LOG_WORKER_THREADS }
	  //
	  if ((nil <> ol) and punaIOCPSockWorkerOL(ol).isDone) then begin
	    //
	    //if (0 < punaIOCPSockWorkerOL(ol).s) then
	    //  CancelIo(punaIOCPSockWorkerOL(ol).s);
	    //
	    if (0 < punaIOCPSockWorkerOL(ol).acquired) then
	      f_master.releaseOL(punaIOCPSockWorkerOL(ol));
	    //
	    SetEvent(ol.hEvent);
	  end
	  else
	    onIOComplete(numBytes, key, ol);
	  //
	end
	else begin
	  //
	  workTM := timeMarkU();
	  inc(f_waiting, timeElapsed64U(waitTM));
	  //
	  if ((nil <> ol) and (0 > f_master.f_olist.indexOf(ol))) then begin
	    //
	    {$IFDEF DEBUG }
	    ol.Internal := ol.Internal;
	    {$ENDIF DEBUG }
	    //
	    continue; // not "our" OL
	  end;
	  //
	  if (nil <> ol) then begin
	    //
	    err := WSAGetLastError();
	    //
	    {$IFDEF LOG_WORKER_THREADS }
	    if (nil <> ol) then
	      logMessage('WORKER.execute() - error#' + int2str(err) + ' at our ' + f_master.OLinfo(punaIOCPSockWorkerOL(ol)) );
	    {$ENDIF LOG_WORKER_THREADS }
	    //
	    if (punaIOCPSockWorkerOL(ol).isDone) then begin
	      //
	      //if (0 < punaIOCPSockWorkerOL(ol).s) then
	      //  CancelIo(punaIOCPSockWorkerOL(ol).s);
	      //
	      if (0 < punaIOCPSockWorkerOL(ol).acquired) then
		f_master.releaseOL(punaIOCPSockWorkerOL(ol));
	      //
	      SetEvent(ol.hEvent);
	    end
	    else
	      onIOError(key, ol, uint(err));
	    //
	  end
	  else begin
	    //
	    if (WAIT_TIMEOUT = GetLastError()) then
	      // timed out, loop again
	    else begin
	      // wrong GetQueuedCompletionStatus() call
	      inc(fatal);
	      //
	      if (99 < fatal) then
		break;	// do not hammer the system with wrong IOCP calls
	    end;
	  end;
	  //
	end; // if (GetQueuedCompletionStatus()) ..
      except
	//
	{$IFDEF DEBUG }
	if (nil <> ol) then
	  logMessage('WORKER.execute(' + choice(f_master.isServer, 'SRV', 'CLN') + ') - ' + choice(f_master.isServer, 'Server', 'Client') + ' broken OL: $' + int2str(int(ol), 16));
	{$ENDIF DEBUG }
      end;
      //
    end; // while (not shouldStop) ...
    //
    if (1 > fatal) then
      result := 0
    else begin
      //
      if (99 < fatal) then
	result := -2	// exit due to big amount of invalid GetQueuedCompletionStatus() calls
      else
	result := -1;	// exit with some invalid GetQueuedCompletionStatus() calls
    end;
  end
  else
    result := -3;
  //
{$IFDEF LOG_WORKER_THREADS }
  logMessage('WORKER.execute(' + choice(f_master.isServer, 'SRV', 'CLN') + ') - LEAVE, result=' + int2str(result));
{$ENDIF LOG_WORKER_THREADS }
end;

// --  --
procedure unaIOCPSockWorkerThread.onIOComplete(numBytes, key: DWORD; o: POVERLAPPED);
var
  itemKilled: bool;
begin
  if (nil <> o) then begin
    //
    if (0 <> f_master.handleIO(self, punaIOCPSockWorkerOL(o), numBytes, key, itemKilled)) then begin
      //
      if (not itemKilled) then
	f_master.releaseOL(punaIOCPSockWorkerOL(o));	// release if new IO was not posted, and item was not killed
      //
    end
    else begin
      //
      if (not itemKilled) then
	punaIOCPSockWorkerOL(o).acTimemark := timeMarkU();
    end;
  end;
end;

// --  --
procedure unaIOCPSockWorkerThread.onIOError(key: DWORD; o: POVERLAPPED; err: DWORD);
var
  canStop: bool;
  itemKilled: bool;
begin
  itemKilled := false;
  if (nil <> o) then begin
    //
    try
      with punaIOCPSockWorkerOL(o)^ do begin
	//
	canStop := not f_master.isServer;
	if (0 < connId) then begin
	  //
	  if (f_master.isServer and (f_master.f_s = sc)) then
	    itemKilled := f_master.removeConnection(connId, o)
	  else
	    unaIOCPSocks(f_master.socks).event(unaseClientDisconnect, f_master.id, connId);
	  //
	  if (not itemKilled) then begin
	    //
	    if (socketOwner and (0 <> sc)) then begin
	      //
	      if (f_master.f_s = sc) then
		f_master.threadSocket.close()
	      else begin
		WinSock.shutdown(sc, SD_BOTH);
		WinSock.closesocket(sc);
	      end;
	    end;
	    //
	    // do not remove this item, just mark is as Done
	    if (not isDone) then
	      InterlockedIncrement(f_master.f_olDoneCount);
	    //
	    isDone := true;
	  end;
	end;
	//
	f_master.checkSocketError(err, nil, canStop);
      end;
      //
    finally
      if (not itemKilled and (0 < punaIOCPSockWorkerOL(o).wbuf.len)) then
	f_master.releaseOL(punaIOCPSockWorkerOL(o));
    end;
  end;
end;


{ unaIOCPOLList }

// --  --
constructor unaIOCPOLList.create(master: unaIOCPSocksThread);
begin
  f_master := master;
  //
  inherited create();
end;

// --  --
procedure unaIOCPOLList.releaseItem(index: int; doFree: unsigned);
var
  item: punaIOCPSockWorkerOL;
begin
  if (mapDoFree(doFree)) then begin
    //
    item := get(index);
    if (nil <> item) then try
      //
      item.wbuf.len := 0;
      mrealloc(item.wbuf.buf);
      //
      CloseHandle(item.ol.hEvent);
      //
      //fillChar(item^, sizeOf(item^), #0);
      if (item.isDone) then
	InterlockedDecrement(f_master.f_olDoneCount);
      //
      if (0 < item.acquired) then
	InterlockedDecrement(f_master.f_olAcquiredCount);
      //
      item.isDone := true;
    except
      //
    end;
  end;
  //
  inherited;
end;


{ unaIOCPSocksThread }

// --  --
function unaIOCPSocksThread.acquireOL(): punaIOCPSockWorkerOL;
var
  i: int;
begin
  result := nil;
  i := 0;
  //
  while (i < f_olist.count) do begin
    //
    if (acquireOL(i)) then begin
      //
      result := punaIOCPSockWorkerOL(f_olist[i]);
      //
      if ((f_s <> result.sc) and not result.isDone and (0 = result.connId)) then
	break
      else
	result := nil;
    end;
    //
    releaseOL(i);
    //
    inc(i);
  end;
  //
  if (nil = result) then
    result := addNewOL();
end;

// --  --
function unaIOCPSocksThread.acquireOL(index: unsigned): bool;
begin
  result := acquireOL(f_olist.get(index));
end;

// --  --
function unaIOCPSocksThread.acquireOL(item: punaIOCPSockWorkerOL): bool;
begin
  result := (nil <> item) and (0 = InterlockedExchangeAdd(item.acquired, 1));
  if (result) then begin
    //
    InterlockedIncrement(f_olAcquiredCount);
    item.acTimemark := timeMarkU();
  end;
end;

// --  --
function unaIOCPSocksThread.addNewOL(acquire: bool): punaIOCPSockWorkerOL;
begin
  if (c_max_OLs > f_olist.count) then begin
    //
    result := malloc(sizeOf(result^), true);
    //
    result.wbuf.buf := malloc(f_maxDataSize);
    result.wbuf.len := f_maxDataSize;
    //
    result.ol.hEvent := CreateEvent(nil, true, false, nil);
    //
    if (acquire) then
      acquireOL(result);
    //
    f_olist.add(result);
    //
    {$IFDEF LOG_SOCKS_THREADS }
    logMessage(className + '.addNewOL() - ' + choice(isServer, 'Server', 'Client') + ' new OL added: $' + int2str(int(result), 16));
    {$ENDIF LOG_SOCKS_THREADS }
  end
  else
    result := nil;
end;

// --  --
procedure unaIOCPSocksThread.AfterConstruction();
begin
  f_terminated := CreateEvent(nil, true, true, nil);
  //
  f_olist := unaIOCPOLList.create(self);
  f_olist.sort();
  //
  inherited;
end;

// --  --
procedure unaIOCPSocksThread.BeforeDestruction();
begin
  inherited;
  //
  WaitForSingleObject(f_terminated, 1000);
  CloseHandle(f_terminated);
  //
  freeAndNil(f_olist);
end;

// --  --
procedure unaIOCPSocksThread.createPortAndThreads();
var
  c: unsigned;
begin
  f_port := unaIOCPClass.create();
  //
  f_poolThreadCount := min(f_port.numProcessors * v_iocp_threadsPerCore + 1, v_max_iocp_threads);
  c := 0;
  while (c < f_poolThreadCount) do begin
    //
    f_pool[c] := unaIOCPSockWorkerThread.create(c + 1, self, f_port, false);	// do not pass index=0, as it is will be same as "worker not specified"
    inc(c);
  end;
end;

// --  --
function unaIOCPSocksThread.doGetRemoteHostAddr(connId: tConID): pSockAddrIn;
var
  i: int;
  ol: punaIOCPSockWorkerOL;
begin
  result := nil;
  //
  i := 0;
  while (i < f_olist.count) do begin
    //
    ol := punaIOCPSockWorkerOL(f_olist.get(i));
    if ((nil <> ol) and (ol.connId = connId)) then begin
      //
      if (ol.socketOwner or (0 <> ol.addrRemote.sin_port)) then begin
	//
	result := @ol.addrRemote;
	break;
      end
      else
	inc(i);
      //
    end
    else
      inc(i);
    //
  end;
end;

// --  --
function unaIOCPSocksThread.execute(globalIndex: unsigned): int;
var
  ok: bool;
  res: int;
  resBool: bool;
  //
  c: uint;
  socketIndex: tConID;
  maxSocketCount: unsigned;
  item: punaIOCPSockWorkerOL;
  itemKilled: bool;
  bytes, flags: DWORD;
  //
  connectEvent: WSAEVENT;
  connId: tConID;
  error: int;
  errorLen: int32;
  //
  nowrite: uint64;
  //
  ms: tSocket;
begin
{$IFDEF LOG_SOCKS_THREADS }
  logMessage(_classID + '.execute(' + choice(isServer, 'SRV', 'CLN') + ') - ENTER');
{$ENDIF LOG_SOCKS_THREADS }
  //
  WaitForSingleObject(f_terminated, 1000);
  ResetEvent(f_terminated);
  //
  if (nil = threadSocket) then begin
    //
    result := -2;
    exit;
  end;
  //
  f_proto := threadSocket.socketProtocol;
  f_s := 0;
  f_olDoneCount := 0;
  f_olAcquiredCount := 0;
  f_spawnCount := 0;
  //
  createPortAndThreads();
  try
    //
    initDone.setState(false);
    //
    if (isServer) then
      newConnId(5500)	// just a plain number ot start with
    else
      newConnId(5600);	// just a plain number ot start with
    //
    connId := 0;
    connectEvent := 0;
    try
      //
      if (isServer) then begin
	//
	// TCP or UDP server
	case (f_proto) of

	  IPPROTO_UDP: begin
	    // UDP SERVER
	    ok := not checkSocketError(threadSocket.bindSocketToPort(threadSocket.getPortInt()), nil, true);
	    threadSocket.setOptInt(SO_RCVBUF, 40000);
	    threadSocket.setOptInt(SO_SNDBUF, 40000);
	  end;

	  IPPROTO_TCP: begin
	    // TCP SERVER
	    ok := not checkSocketError(threadSocket.listen(backlog), nil, true);
	  end;

	  else
	    ok := false;	// unknown proto

	end;
	//
	ok := ok and threadSocket.isActive;
	if (ok) then begin
	  //
	  f_s := threadSocket.getSocket();
	  unaIOCPSocks(socks).event(unaseServerListen, id, 0);	// notify server starts listening
	end;
	//
      end
      else begin
	//
	// UDP/TCP CLIENT
	connectEvent := CreateEventW(nil, false, false, nil);
	ok := (0 = WSAEventSelect(threadSocket.getSocket(), connectEvent, FD_CONNECT));
	ok := ok and not checkSocketError(threadSocket.connect(), nil, true);	// call would be non-blocking
	//
	threadSocket.setOptInt(SO_RCVBUF, 16000);
	//
	if (ok) then
	  f_s := threadSocket.getSocket();
      end;
      //
      if (ok) then
	ok := iocpPort.associate(f_s, id);	// main thread id will be the key
      //
      initDone.setState(true);
      //
  {$IFDEF LOG_SOCKS_THREADS }
      logMessage(_classID + '.execute(' + choice(isServer, 'SRV', 'CLN') + ') - Before main loop, ok=' + bool2strStr(ok));
  {$ENDIF LOG_SOCKS_THREADS }
      //
      if (ok) then begin
	//
	if (IPPROTO_TCP = f_proto) then
	  f_maxDataSize := c_max_tcp_buf	//
	else
	  f_maxDataSize := c_max_udp_buf;	//
	//
	// get AcceptEx() address for TCP server socket
	if (isServer and (IPPROTO_TCP = f_proto)) then begin
	  //
	  f_acceptEx := getWSAProcAddr(f_s, WSAID_ACCEPTEX);
	  f_getAcceptExSockaddrs := getWSAProcAddr(f_s, WSAID_GETACCEPTEXSOCKADDRS);
	end;
	//
	if (isServer) then begin
	  //
	  item := addNewOL();
	  if (nil <> item) then begin
	    //
	    item.socketOwner := true;
	    itemKilled := false;
	    if (nil <> item) then begin
	      //
	      case (f_proto) of

		IPPROTO_UDP: res := postRequest(item, OP_RECVFROM, 0, itemKilled);
		IPPROTO_TCP: res := postRequest(item, OP_ACCEPT,   0, itemKilled);
		else         res := WSAEFAULT;

	      end;
	      //
	      if (not itemKilled and (0 <> res)) then
		releaseOL(item);
	      //
	      checkSocketError(res, nil, true);	// check if fatal error
	    end
	    else
	      ok := false;
	  end
	  else
	    ok := false;
	  //
	end;
	//
	if (ok) then begin
	  //
	  c := 0;
	  while (c < f_poolThreadCount) do begin
	    //
	    f_pool[c].start();
	    inc(c);
	  end;
	end;
	//
	socketIndex := 0;
	nowrite := 0;
	while (ok and not shouldStop) do begin
	  //
	  f_ready := true;
	  //
	  try
	    //
	    if (isServer) then begin
	      //
	      // -- SERVER
	      case (f_proto) of

		IPPROTO_TCP: begin
		  //
		  // TCP Server
		  //
		  maxSocketCount := 64;
		  while ((int(socketIndex) < f_olist.count) and (0 < maxSocketCount)) do begin
		    //
		    item := f_olist[socketIndex];
		    inc(socketIndex);
		    dec(maxSocketCount);
		    //
		    if (not item.isDone and (0 <> item.sc) and (1 = item.acquired) and (OP_ACCEPT <> item.op) and (0 <> item.acTimemark) and (5000 < timeElapsed64U(item.acTimemark))) then begin
		      //
		      // check if socket has some problems
		      resBool := WSAGetOverlappedResult(item.sc, @item.ol, @bytes, false, @flags);
		      if (resBool) then begin
			//
			// If WSAGetOverlappedResult succeeds, the return value is TRUE.
			// This means that the overlapped operation has completed successfully and that the
			// value pointed to by lpcbTransfer has been updated
		      end
		      else begin
			//
			// If WSAGetOverlappedResult returns FALSE, this means that either the overlapped operation
			// has not completed, the overlapped operation completed but with errors, or the overlapped
			// operation's completion status could not be determined due to errors in one or more
			// parameters to WSAGetOverlappedResult
			//
			if (c_socket_write_timeout < timeElapsed64U(item.acTimemark)) then begin
			  //
			{$IFDEF LOG_SOCKS_THREADS }
			  logMessage('MAIN.e() - looks like it stuck: ' + OLinfo(item));
			{$ENDIF LOG_SOCKS_THREADS }
			  //
			  res := WSAECONNRESET;	// assume connection was reset by client
			end
			else
			  res := WSAGetLastError();
			//
			case (res) of

			  WSA_INVALID_PARAMETER,
			  WSA_IO_INCOMPLETE,
			  WSAEFAULT: // IO is not complete yet, or there are some problems with parameters
				     // in any way, we do not care

			  else begin	// some problem with OL
			    //
			    if (item.socketOwner and (0 <> item.sc)) then
			      // WARNING: "item" may be removed there
			      // (for now we do not care)
			      removeConnection(item.connId, item)
			    else begin
			      //
			    {$IFDEF LOG_SOCKS_THREADS }
			      logMessage('MAIN.e() - about to be notified with 0 bytes: ' + OLinfo(item));
			    {$ENDIF LOG_SOCKS_THREADS }
			      PostQueuedCompletionStatus(iocpPort.handle, 0, id, POVERLAPPED(item));
			    end;
			  end;

			end; // case
		      end;
		    end;
		    //
		  end;	// while ...
		  //
		  if (int(socketIndex) >= f_olist.count) then
		    socketIndex := 0;
		  //
		  sleepThread(400);	// just sleep
		end;


		IPPROTO_UDP: begin
		  //
		  // UDP server
		  //
		  // check if our main socket is receiving something
		  item := f_olist[0];
		  if (nil <> item) then begin
		    //
		    if (acquireOL(item)) then begin
		      //
		      fillChar(item.addrRemote, sizeOf(item.addrRemote), #0);
		      res := postRequest(item, OP_RECVFROM, 0, itemKilled);
		      if (not itemKilled and (0 <> res)) then begin
			//
			releaseOL(item);
			//
			if (WSAECONNRESET = res) then begin
			  //
			  // sometimes UDP server may receive WSAECONNRESET when issuing RECVFROM op
			  // in this case we just re-issue same request, and check again
			  sleepThread(1);
			  continue;	// (timeout checking skipped)
			end
			else
			  // was it not WSAECONNRESET? Anyways, re-issue our request once again after short sleep
			  sleepThread(10);
		      end;
		    end
		    else begin
		      //
		      releaseOL(item);
		      sleepThread(300);	// sleep well
		    end;
		  end
		  else begin
		    //
		    // no main socket? die out
  {$IFDEF LOG_SOCKS_THREADS }
		    logMessage(_classID + '.execute(' + choice(isServer, 'SRV', 'CLN') + ') - no main socket!');
  {$ENDIF LOG_SOCKS_THREADS }
		    //
		    break;
		  end;
		  //
		  // check UDP timeout (if specified)
		  if (not shouldStop and (0 < udpConnectionTimeout)) then begin
		    //
		    maxSocketCount := 64;
		    if (0 = socketIndex) then
		      inc(socketIndex);	// do not touch main socket
		    //
		    while ((int(socketIndex) < f_olist.count) and (0 < maxSocketCount)) do begin
		      //
		      item := f_olist[socketIndex];
		      inc(socketIndex);
		      dec(maxSocketCount);
		      //
		      itemKilled := false;
		      if (acquireOL(item)) then begin
			//
			if (not item.isDone and item.olIsReceiver and (0 <> item.olDataTimemark) and (udpConnectionTimeout < timeElapsed64U(item.olDataTimemark))) then begin
			  //
			  // UDP timeout, remove connection
			  // WARNING: "item" may be removed there
			  itemKilled := removeConnection(item.connId, item);
			end;
		      end;
		      //
		      if (not itemKilled) then
			releaseOL(item);
		    end;
		    //
		    if (int(socketIndex) >= f_olist.count) then
		      socketIndex := 1;	// do not touch main socket
		  end;
		end;


		else	// non TCP/UDP server.. nothing to do, exit thread
		  break;

	      end; // case (proto) ...

	    end
	    else begin
	      //
	      // -- TCP/UDP CLIENT
	      //
	      case (f_proto) of

		IPPROTO_TCP,
		IPPROTO_UDP: begin
		  //
		  if (0 >= connId) then begin
		    //
		    // check if connection event (successfull or not) has occured on socket
		    if (WAIT_OBJECT_0 = WaitForSingleObject(connectEvent, 100)) then begin
		      //
		      if (threadSocket.oktoWrite(100)) then begin
			//
			connId := newConnId();
			//
			item := addNewOL();	// item is acquired
			if (nil <> item) then begin
			  //
			  item.connId := connId;
			  item.socketOwner := true;	// indicate we are main item
			  //
			  threadSocket.getSockAddr(item.addrRemote);
			  item.addrRemoteLen := sizeOf(item.addrRemote);
			  item.addrRemoteFixed := true;	// do not clear remoteAddr after successfull RECVFROM
			  //
			  if (IPPROTO_UDP = f_proto) then
			    res := postRequest(item, OP_RECVFROM, 0, itemKilled)
			  else
			    res := postRequest(item, OP_RECV, 0, itemKilled);
			  //
			  if (not itemKilled and (0 <> res)) then
			    releaseOL(item);
			  //
			  if (not checkSocketError(res, nil, true)) then
			    unaIOCPSocks(socks).event(unaseClientConnect, id, connId);
			end
			else
			  ok := false;
			//
		      end
		      else begin
			//
			errorLen := sizeOf(error);
			if (SOCKET_ERROR = getsockopt(f_s, SOL_SOCKET, SO_ERROR, paChar(@error), errorLen)) then
			  error := WSAGetLastError();
			//
			unaIOCPSocks(socks).event(unaseThreadStartupError, id, newConnId(0), @error, errorLen);
			//
			checkSocketError(error, nil, true);
			//
			break;	// exit thread regardless of fatal/non fatal error
		      end;
		    end;
		  end
		  else begin
		    //
		    if (threadSocket.okToWrite(10)) then begin
		      //
		      nowrite := 0;
		      sleepThread(400);
		    end
		    else begin
		      //
		      if (0 = nowrite) then
			nowrite := timeMarkU()
		      else begin
			//
			if (c_socket_write_timeout < timeElapsed32U(nowrite)) then
			  // some problem with main socket, terminate the thread
			  askStop();
		      end;
		    end;
		    //
		    sleepThread(400);
		  end; // if (0 >= connId) ...
		  //
		end; // case UDP/TCP

		else
		  break;	// unknown proto

	      end; // case (proto) of ...

	    end;	// else (if client/server )

	  except
	    // ignore exceptions
	  end;
	  //
	end; // while (not shouldStop) do ...
	//
      end
      else begin // not ok ..
	//
	error := WSAGetLastError();
	unaIOCPSocks(socks).event(unaseThreadStartupError, id, connId, @error, sizeOf(error));
      end;
      //
    finally
  {$IFDEF LOG_SOCKS_THREADS }
      logMessage(_classID + '.execute(' + choice(isServer, 'SRV', 'CLN') + ') - Finally.. about to close client connection (if any).');
  {$ENDIF LOG_SOCKS_THREADS }
      //
      f_ready := false;
      //
      if (0 < connId) then
	unaIOCPSocks(socks).event(unaseClientDisconnect, id, connId);
      //
      if (0 <> connectEvent) then
	CloseHandle(connectEvent);
      //
  {$IFDEF LOG_SOCKS_THREADS }
      logMessage(_classID + '.execute(' + choice(isServer, 'SRV', 'CLN') + ') - Finally.. about to close server (if any).');
  {$ENDIF LOG_SOCKS_THREADS }
      //
      if (isServer) then
	unaIOCPSocks(socks).event(unaseServerStop, id, 0);
      //
  {$IFDEF LOG_SOCKS_THREADS }
      logMessage(_classID + '.execute(' + choice(isServer, 'SRV', 'CLN') + ') - Finally.. about to cancel all IOs.');
  {$ENDIF LOG_SOCKS_THREADS }
      //
  {$IFDEF LOG_SOCKS_THREADS }
      logMessage(_classID + '.execute(' + choice(isServer, 'SRV', 'CLN') + ') - Finally.. about post completion status on all OLs.');
  {$ENDIF LOG_SOCKS_THREADS }
      //
      if (0 < f_olist.count) then begin
	//
	for c := 0 to f_olist.count - 1 do begin
	  //
	  item := f_olist.get(c);
      if (nil = item) then continue;

	  if (not item.isDone and (0 < item.sc)) then begin
	    //
	    if (not item.isDone) then
	      InterlockedIncrement(f_olDoneCount);
	    //
	    item.isDone := true;
	    //
	    if (item.socketOwner) then begin
	      //
	      {$IFDEF LOG_SOCKS_THREADS }
		logMessage(_classID + '.execute(' + choice(isServer, 'SRV', 'CLN') + ') - Finally.. about to close the socket for ' + OLinfo(item));
	      {$ENDIF LOG_SOCKS_THREADS }
	      //
	      if (f_s = item.sc) then
		threadSocket.close()
	      else begin
		//
		WinSock.shutdown(item.sc, SD_BOTH);
		WinSock.closesocket(item.sc);		// release socket handle
		item.sc := 0;
	      end;
	    end
	    else begin
	      //
	      {$IFDEF LOG_SOCKS_THREADS }
		logMessage(_classID + '.execute(' + choice(isServer, 'SRV', 'CLN') + ') - Finally.. about post completion status on ' + OLinfo(item));
	      {$ENDIF LOG_SOCKS_THREADS }
	      PostQueuedCompletionStatus(iocpPort.handle, 0, id, POVERLAPPED(item));
	    end;
	    //
	    Sleep(1);
	    //
	    if (not acquireOL(item)) then begin
	      //
	      releaseOL(item);
	      //
  {$IFDEF LOG_SOCKS_THREADS }
	      logMessage(_classID + '.execute(' + choice(isServer, 'SRV', 'CLN') + ') - Finally.. this OL is busy, will wait for 400 ms..');
  {$ENDIF LOG_SOCKS_THREADS }
	      WaitForSingleObject(item.ol.hEvent, 200);
	    end;
	    //
	  end;
	end;
      end;
      //
      // release socket
      ms := f_s;
      releaseSocket();
      //
      // cancel all IO on master socket (just in case)
      CancelIo(ms);
      //
  {$IFDEF LOG_SOCKS_THREADS }
      logMessage(_classID + '.execute(' + choice(isServer, 'SRV', 'CLN') + ') - Finally.. about to stop all worker threads');
  {$ENDIF LOG_SOCKS_THREADS }
      //
      c := 0;
      while (c < f_poolThreadCount) do begin
	//
	f_pool[c].stop(566);
	inc(c);
      end;
      //
  {$IFDEF LOG_SOCKS_THREADS }
      logMessage(_classID + '.execute(' + choice(isServer, 'SRV', 'CLN') + ') - Finally.. about to close the socket.');
  {$ENDIF LOG_SOCKS_THREADS }
      //
      //
  {$IFDEF LOG_SOCKS_THREADS }
      logMessage(_classID + '.execute(' + choice(isServer, 'SRV', 'CLN') + ') - Finally.. about to remove all OLs.');
  {$ENDIF LOG_SOCKS_THREADS }
      //
      f_olist.clear();	// remove all OL records we have collected so far
      //
  {$IFDEF LOG_SOCKS_THREADS }
      logMessage(_classID + '.execute(' + choice(isServer, 'SRV', 'CLN') + ') - Finally.. about to reset initDone Event.');
  {$ENDIF LOG_SOCKS_THREADS }
      //
      // reset state
      initDone.setState(false);
    end;
    //
    SetEvent(f_terminated);
    //
  finally
    releasePortAndThreads();
  end;  
  //
  result := 0;
  //
{$IFDEF LOG_SOCKS_THREADS }
  logMessage(_classID + '.execute(' + choice(isServer, 'SRV', 'CLN') + ') - EXIT');
{$ENDIF LOG_SOCKS_THREADS }
end;

{$IFDEF LOG_SOCKS_THREADS }

// --  --
function addrInfo(const addr: sockaddr_in): string;
begin
  result :=   'F=' + int2str(addr.sin_family) +
	    ' /P=' + int2str(addr.sin_port) +
	    ' /A=' + string(inet_ntoa(addr.sin_addr));
end;

{$ENDIF LOG_SOCKS_THREADS }

// --  --
function unaIOCPSocksThread.handleIO(worker: unaIOCPSockWorkerThread; item: punaIOCPSockWorkerOL; bytesReceived, key: DWORD; out itemKilled: bool): int;
var
  i: uint;
  connId: tConID;
  ritem: punaIOCPSockWorkerOL;
  portOK: bool;
  ol: punaIOCPSockWorkerOL;
  p1, p2: pSockAddr;
{$IFDEF LOG_SOCKS_THREADS }
  fid: int;
{$ENDIF LOG_SOCKS_THREADS }
begin
  result := SOCKET_ERROR;
  itemKilled := false;
  //
  if (nil <> item) then begin
    //
{$IFDEF LOG_SOCKS_THREADS }
    fid := InterlockedIncrement(f_hadleIO_cnt);
    logMessage('MAIN.handleIO[hio_' + int2str(fid) + '](bytes=' + int2str(bytesReceived) + '): ' + OLinfo(item) + ' -- ENTER');
{$ENDIF LOG_SOCKS_THREADS }
    //
    case (item.op) of

      OP_ACCEPT: begin    // AcceptEx()
	//
	// client connection was accepted
	//
	// 1. create new socket and connection
	connId := newConnId();
	unaIOCPSocks(socks).event(unaseServerConnect, id, connId);
	//
	// 2. associate new socket with our port
	portOK := f_port.associate(item.acceptSocket, id);	// main thread id will be the key
	if (portOK) then begin
	  //
	  // 3. create new OL item and issue new recv() request on it
	  ritem := addNewOL();
	  if (nil <> ritem) then begin
	    //
	    ritem.sc := item.acceptSocket;
	    ritem.connId := connId;
	    ritem.socketOwner := (0 = setsockopt(item.acceptSocket, SOL_SOCKET, SO_UPDATE_ACCEPT_CONTEXT, paChar(@item.sc), sizeOf(item.sc)));
	    //
	    if (assigned(f_getAcceptExSockaddrs)) then begin
	      //
	      f_getAcceptExSockaddrs(item.wbuf.buf, item.wbuf.len - ( sizeOf(item.addrLocal) + 16 + sizeOf(item.addrRemote) + 16 ),
				     sizeOf(item.addrLocal) + 16,
				     sizeOf(item.addrRemote) + 16,
				     p1, ritem.addrLocalLen,
				     p2, ritem.addrRemoteLen);
	      //
	      if (0 < ritem.addrLocalLen) then
		move(p1^, ritem.addrLocal, ritem.addrLocalLen);
	      //
	      if (0 < ritem.addrRemoteLen) then
		move(p2^, ritem.addrRemote, ritem.addrRemoteLen);
	      //
	      ritem.addrRemoteFixed := true;	// just in case
	    end;
	    //
	    if (0 <> postRequest(ritem, OP_RECV, 0, itemKilled)) then begin
	      //
	      if (not itemKilled) then
		releaseOL(ritem);
	    end;
	  end;
	end;
	//
	// 4. if we have received some data, notify it now
	if (0 < bytesReceived) then
	  unaIOCPSocks(socks).event(unaseServerData, id, connId, item.wbuf.buf, bytesReceived);
	//
	// 4. re-post accept on same socket
	result := postRequest(item, OP_ACCEPT, 0, itemKilled);
      end;

      OP_RECV: begin    // WSARecv()
	//
	if (0 < bytesReceived) then begin
	  //
	  if (isServer) then
	    unaIOCPSocks(socks).event(unaseServerData, id, item.connId, item.wbuf.buf, bytesReceived)
	  else
	    unaIOCPSocks(socks).event(unaseClientData, id, item.connId, item.wbuf.buf, bytesReceived);
	  //
	  // issue another IO request on same socket (OL)
	  result := postRequest(item, OP_RECV, 0, itemKilled);
	end
	else begin
	  //
	  // number of bytes is zero, that means the connection has been gracefuly closed, so remove it
	  if (isServer and item.socketOwner) then
	    itemKilled := removeConnection(item.connId, item)
	  else
	    if (not isServer) then
	      unaIOCPSocks(socks).event(unaseClientDisconnect, id, item.connId);
	  //
	  if (not itemKilled) then begin
	    //
	    if (not isServer or item.socketOwner) then begin
	      //
	      if (item.socketOwner and (0 <> item.sc)) then begin
		//
		if (f_s = item.sc) then
		  threadSocket.close()
		else begin
		  //
		  WinSock.shutdown(item.sc, SD_BOTH);
		  WinSock.closesocket(item.sc);
		end;
	      end;
	      //
	      // stop the thread, if not server
	      checkSocketError(WSAECONNRESET, nil, not isServer);
	      //
	      // mark this item as done
	      if (not item.isDone) then
		InterlockedIncrement(f_olDoneCount);
	      //
	      item.isDone := true;
	    end;
	    //
	    item.wbuf.len := 0;
	  end;
	end;
      end;

      OP_SEND: begin	// WSASend()
	//
	if (0 < bytesReceived) then begin
	  // OK
	end
	else begin
	  //
	  // number of bytes is zero, that means the connection has been gracefully closed, so remove it
	  if (isServer and item.socketOwner) then
	    itemKilled := removeConnection(item.connId, item)
	  else
	    if (not isServer) then
	      unaIOCPSocks(socks).event(unaseClientDisconnect, id, item.connId);
	  //
	  if (not itemKilled) then begin
	    //
	    if (not isServer or item.socketOwner) then begin
	      //
	      if (item.socketOwner and (0 <> item.sc)) then begin
		//
		if (f_s = item.sc) then
		  threadSocket.close()
		else begin
		  //
		  WinSock.shutdown(item.sc, SD_BOTH);
		  WinSock.closesocket(item.sc);
		end;
	      end;
	      // stop the thread, if not server
	      checkSocketError(WSAECONNRESET, nil, not isServer);
	      //
	      // mark this item as done
	      if (not item.isDone) then
		InterlockedIncrement(f_olDoneCount);
	      //
	      item.isDone := true;
	    end;
	    //
	    item.wbuf.len := 0;
	  end;
	end;
      end;

      OP_RECVFROM: begin	// WSARecvFrom()
	//
	// It is quite important to issue another OP_RECVFROM before doing anything else.
	// Otherwise multi-core CPU will behave more like single-core.
	//
	if ((item.sc <> f_s) or (f_spawnCount < f_poolThreadCount)) then begin
	  //
	  ol := acquireOL();
	  if (nil <> ol) then begin
	    //
	    ol.sc := item.sc;
	    //
	    move(item.addrLocal, ol.addrLocal, item.addrLocalLen);
	    ol.addrLocalLen := ol.addrLocalLen;
	    //
	    if (not item.addrRemoteFixed) then
	      fillChar(ol.addrRemote, sizeOf(ol.addrRemote), #0)
	    else
	      move(item.addrRemote, ol.addrRemote, item.addrRemoteLen);
	    //
	    ol.addrRemoteLen := item.addrRemoteLen;
	    //
	    if (0 = postRequest(ol, OP_RECVFROM, 0, itemKilled)) then begin
	      //
	      if (item.sc = f_s) then
		inc(f_spawnCount);
	    end;
	  end;
	end;
	//
	connId := 0;
	//
	if (false) then begin
	  //
	end
	else begin
	  //
	  // try to locate connection with same remote address
	  if (lockNonEmptyList_r(f_olist, true, 50 {$IFDEF DEBUG }, '.handleIO(_RECVFROM_)'{$ENDIF DEBUG })) then try
	    //
	    for i := 1 to f_olist.count - 1 do begin
	      //
	      ol := punaIOCPSockWorkerOL(f_olist.get(i));
          if (nil = ol) then continue;

	      if (not ol.isDone and ol.olIsReceiver and (0 < ol.addrRemoteLen) and (ol.addrRemoteLen = item.addrRemoteLen) and (0 <> ol.connId)) then begin
		//
		{$IFDEF LOG_SOCKS_THREADS }
		//logMessage('MAIN.handleIO(bytes=' + int2str(bytesReceived) + '): about to compare [' + addrInfo(ol.addrRemote) + '] and [' + addrInfo(item.addrRemote) + ']');
		{$ENDIF LOG_SOCKS_THREADS }
		//
		if (mcompare(@ol.addrRemote, @item.addrRemote, item.addrRemoteLen)) then begin
		  //
		  connId := ol.connId;
		  ol.olDataTimemark := timeMarkU();
		  //
		  //break;  	// BUG: 23 MAY'09
				// Some connection may have more than one receiving OL assigned to them.
				// Breaking here would cause other receiving OLs to timeout on UDP.
				//
				// Many thanks to Deon Bezuidenhout for helping with fixing of this bug.
				//
		end;
	      end;
	    end;
	  finally
	    f_olist.unlockRO();
	  end
	  else
	    connID := tConID(-1);
	end;
	//
	if (0 = connId) then begin
	  //
	  // create new item, so it can be used for client/server I/O
	  //
	  connId := newConnId();
	  {$IFDEF LOG_SOCKS_THREADS }
	  logMessage('MAIN.handleIO[hio_' + int2str(fid) + '](bytes=' + int2str(bytesReceived) + ') - got new connection: ' + int2str(connId));
	  {$ENDIF LOG_SOCKS_THREADS }
	  //
	  ol := addNewOL();
	  if (nil <> ol) then begin
	    try
	      if ({bad idea: isServer}false) then begin
		//
		// ol.sc := WSASocket(threadSocket.addressFamily, threadSocket.socketType, threadSocket.socketProtocol, nil, 0, WSA_FLAG_OVERLAPPED);
		// iocpPort.associate(ol.sc, id);
		// ol.socketOwner := true;
	      end
	      else
		ol.sc := item.sc;
	      //
	      ol.connId := connId;
	      //
	      move(item.addrRemote, ol.addrRemote, item.addrRemoteLen);
	      ol.addrRemoteLen := item.addrRemoteLen;
	      //
	      ol.olDataTimemark := timeMarkU();
	      ol.olIsReceiver := true;	// mark this OL as receiving item, so we can relay on its olDataTimemark field (see BUG: 23 MAY'09 remarks)
	      //
	      if (isServer) then
		unaIOCPSocks(socks).event(unaseServerConnect, id, connId, @ol.addrRemote, ol.addrRemoteLen)	//
	      else
		; // UDP client do not need this notification
	    finally
	      releaseOL(ol);
	    end;
	  end;
	end;
	//
	if ((tConID(-1) <> connID) and (0 < connId) and (0 < bytesReceived)) then begin
	  //
	  if (isServer) then
	    unaIOCPSocks(socks).event(unaseServerData, id, connId or ((worker.index and $FF) shl 24), item.wbuf.buf, bytesReceived)
	  else
	    unaIOCPSocks(socks).event(unaseClientData, id, connId or ((worker.index and $FF) shl 24), item.wbuf.buf, bytesReceived);
	end;
	//
{$IFDEF LOG_SOCKS_THREADS }
	logMessage('MAIN.handleIO[hio_' + int2str(fid) + '](bytes=' + int2str(bytesReceived) + '): ' + OLinfo(item) + ' -- About to re-issue same Req, ARF=' + bool2strStr(item.addrRemoteFixed));
{$ENDIF LOG_SOCKS_THREADS }
	//
	if (not isServer or ({(0 = item.connId) and} item.sc = f_s)) then begin
	  //
	  // issue another IO request with same item
	  if (not item.addrRemoteFixed) then
	    fillChar(item.addrRemote, sizeOf(item.addrRemote), #0);
	  //
	  result := postRequest(item, OP_RECVFROM, 0, itemKilled);
	end
	else
	  result := 1; // release item
      end;

      OP_SENDTO: begin	// WSASendTo()
	//
	// data was sent, no notification for now
      end;

    end; // case
    //
{$IFDEF LOG_SOCKS_THREADS }
    logMessage('MAIN.handleIO[hio_' + int2str(fid) + '](bytes=' + int2str(bytesReceived) + '): ' + OLinfo(item) + ' -- LEAVE');
{$ENDIF LOG_SOCKS_THREADS }
  end;
end;

{$IFDEF LOG_ENABLED }

// --  --
function op2str(op: int): string;
begin
  case (op) of

    OP_ACCEPT: result := 'ACCEPT';
    OP_RECV: result := 'RECV';
    OP_SEND: result := 'SEND';
    OP_RECVFROM: result := 'RECVFROM';
    OP_SENDTO: result := 'SENDTO';

    else result := 'Unknown';

  end;
end;

// --  --
function unaIOCPSocksThread.OLinfo(item: punaIOCPSockWorkerOL): string;
var
  s: string;
begin
  if (nil <> item) then begin
    //
    if (0 = item.sc) then
      s := '0(' + int2str(f_s) + ')'
    else
      s := int2str(item.sc);
    //
    if (0 = item.op) then
      s := s + '/acceptS=' + int2str(item.acceptSocket);
    //
    result := 'OL[' + choice(isServer, 'S', 'C') + ':$' + int2str(int(item), 16) + choice(item.isDone, '/DONE!', '') + ']-' +
	       op2str(item.op) +
	       '; S' + choice(item.socketMaster, 'M', '') + '=' + s + '/' + int2str(item.connId) +
	       '; Aq=' + int2str(item.acquired);
    //
    if (0 <> item.acTimemark) then
      result := result + '; t=' + int2str(timeElapsed64(item.acTimemark), 10, 3)
    else
      result := result + '; t=n/a';
  end
  else
    result := 'nil';
end;

{$ENDIF LOG_ENABLED }


{$IFDEF DEBUG }

// --  --
procedure unaIOCPSocksThread.ol_getStats(out stats: unaIOCPSocksThread_stats);
//var
  //w: int;
begin
  stats.r_num_workerThreads := f_poolThreadCount;
  stats.r_num_OL := f_olist.count;
  stats.r_num_OL_done := f_olDoneCount;
  stats.r_num_OL_acquired := f_olAcquiredCount;
  //
  {
  for w := 0 to f_poolThreadCount - 1 do begin
    //
    stats.r_workerWait[w] := unaIOCPSockWorkerThread(f_pool[w]).f_waiting;
    stats.r_workerWork[w] := unaIOCPSockWorkerThread(f_pool[w]).f_working;
    stats.r_workerBusy[w] := unaIOCPSockWorkerThread(f_pool[w]).f_busy;
  end;
  }
end;

{$ENDIF DEBUG }

// --  --
function unaIOCPSocksThread.postRequest(item: punaIOCPSockWorkerOL; op: int; flags: DWORD; out itemKilled: bool): int;
var
  br: DWORD;
  fg: DWORD;
  wsares: int;
  wsabool: BOOL;
  ev: tHandle;
  loopCount: int;
  {$IFDEF LOG_SOCKS_THREADS }
  fid: int;
  {$ENDIF LOG_SOCKS_THREADS }
begin
  result := SOCKET_ERROR;
  itemKilled := false;
  //
  {$IFDEF LOG_SOCKS_THREADS }
  fid := InterlockedIncrement(f_postRq_cnt);
  logMessage('MAIN.postRq[prq_' + int2str(fid) + '](f=' + int2str(flags) + '; op=' + op2str(op) + '): OL=' + OLinfo(item) + ' -- ENTER');
  {$ENDIF LOG_SOCKS_THREADS }
  //
  if ((nil <> item) and not item.isDone) then begin
    //
    // issue an overlapped request
    ev := item.ol.hEvent;
    fillChar(item.ol, sizeOf(item.ol), #0);
    item.ol.hEvent := ev;
    //
    item.op := op;
    {$IFDEF DEBUG }
    inc(item.opPostNum);
    {$ENDIF DEBUG }
    //
    if (0 = item.sc) then
      item.sc := f_s;
    //
    item.addrLocalLen := sizeOf(item.addrLocal);
    item.addrRemoteLen := sizeOf(item.addrRemote);
    //
    fg := flags;
    br := 0;
    //
    case (op) of

      OP_ACCEPT: begin	// AcceptEx()
	//
	// create new socket for accept
	item.acceptSocket := WinSock.socket(threadSocket.addressFamily, threadSocket.socketType, f_proto);
	if (INVALID_SOCKET <> item.acceptSocket) then begin
	  //
	  if (assigned(f_acceptEx)) then begin
	    //
	    {$IFDEF LOG_SOCKS_THREADS }
	    logMessage('MAIN.postRequest[prq_' + int2str(fid) + '](f=' + int2str(flags) + '): ' + OLinfo(item));
	    {$ENDIF LOG_SOCKS_THREADS }
	    //
	    wsabool := f_acceptEx(item.sc, item.acceptSocket, item.wbuf.buf, item.wbuf.len - ( sizeOf(item.addrLocal) + 16 + sizeOf(item.addrRemote) + 16 ), sizeOf(item.addrLocal) + 16, sizeOf(item.addrRemote) + 16, @br, POVERLAPPED(item));
	    if (wsabool) then begin
	      //
	      //result := handleIO(item, br, fg, itemKilled)	// handle IO and post another request if neccessary
	      result := 0;
	      //
	      {$IFDEF LOG_SOCKS_THREADS }
	      logMessage('MAIN.postRequest[prq_' + int2str(fid) + '](f=' + int2str(flags) + '): synch OP_ACCEPT? ' + OLinfo(item))
	      {$ENDIF LOG_SOCKS_THREADS }
	    end
	    else begin
	      //
	      result := WSAGetLastError();
	      if (WSA_IO_PENDING = result) then
		result := 0;  // request was enqueued, exit with success
	      //
	    end;
	  end
	  else
	    result := WSAEFAULT;	// return some fatal error
	  //
	end
	else
	  result := WSAGetLastError();
	//
      end;

      OP_RECV: begin	// WSARecv()
	//
	{$IFDEF LOG_SOCKS_THREADS }
	  logMessage('MAIN.postRequest[prq_' + int2str(fid) + '](f=' + int2str(flags) + '): ' + OLinfo(item));
	{$ENDIF LOG_SOCKS_THREADS }
	wsares := WSARecv(item.sc, @item.wbuf, 1, @br, @fg, POVERLAPPED(item), nil);
	if (0 = wsares) then begin
	  //
	  //result := handleIO(item, br, fg, itemKilled);	// handle IO and issue same request
	  result := 0;
	  //
	  {$IFDEF LOG_SOCKS_THREADS }
	  logMessage('MAIN.postRequest[prq_' + int2str(fid) + '](f=' + int2str(flags) + '): synch OP_RECV? ' + OLinfo(item))
	  {$ENDIF LOG_SOCKS_THREADS }
	end
	else begin
	  //
	  if (SOCKET_ERROR = wsares) then begin
	    //
	    result := WSAGetLastError();
	    if (WSA_IO_PENDING = result) then
	      result := 0; // request was enqueued, exit with success
	    //
	  end
	  else
	    result := wsares;	// unknown return code, fail out
	  //
	end;
      end;

      OP_SEND: begin	// WSASend()
	//
      end;

      OP_RECVFROM: begin	// WSARecvFrom()
	//
	{$IFDEF LOG_SOCKS_THREADS }
	logMessage('MAIN.postRequest[prq_' + int2str(fid) + '](f=' + int2str(flags) + '): ' + OLinfo(item));
	{$ENDIF LOG_SOCKS_THREADS }
	wsares := WSARecvFrom(item.sc, @item.wbuf, 1, @br, @fg, @item.addrRemote, @item.addrRemoteLen, POVERLAPPED(item), nil);
	if (0 = wsares) then begin
	  //
	  //result := handleIO(item, br, fg, itemKilled)	// handle IO and issue same request
	  result := 0;
	  //
	  {$IFDEF LOG_SOCKS_THREADS }
	  logMessage('MAIN.postRequest[prq_' + int2str(fid) + '](f=' + int2str(flags) + '): synch OP_RECVFROM? ' + OLinfo(item))
	  {$ENDIF LOG_SOCKS_THREADS }
	end
	else begin
	  //
	  if (SOCKET_ERROR = wsares) then begin
	    //
	    result := WSAGetLastError();
	    if (WSA_IO_PENDING = result) then
	      result := 0;	// request was enqueued, exit with success
	    //
	    //
	    if ((WSAENETRESET = result) or (WSAECONNRESET = result)) then begin
	      //
	      //  WSAENETRESET: For a datagram socket, this error indicates that the time to live has expired.
	      // WSAECONNRESET: On a UDP-datagram socket this error indicates a previous send operation resulted in an ICMP Port Unreachable message.
	      //
	      loopCount := 100;
	      while (not shouldStop and ((WSAENETRESET = result) or (WSAECONNRESET = result)) and (0 < loopCount)) do begin
		//
		if (not item.addrRemoteFixed) then
		  fillChar(item.addrRemote, sizeOf(item.addrRemote), #0);
		//
		wsares := WSARecvFrom(item.sc, @item.wbuf, 1, @br, @fg, @item.addrRemote, @item.addrRemoteLen, POVERLAPPED(item), nil);
		if (SOCKET_ERROR = wsares) then begin
		  //
		  result := WSAGetLastError();
		  if (WSA_IO_PENDING = result) then
		    result := 0	// request was enqueued, exit with success
		  //
		end
		else
		  result := wsares;	// 0 or something else
		//
		dec(loopCount);
		if (loopCount < 2) then
		  loopCount := loopCount;
	      end;
	    end;
	  end
	  else
	    result := wsares;	// unknown return code, fail out
	end;
      end;

      OP_SENDTO: begin	// WSASendTo()
	//
      end;

    end; // case (op) of ..
    //
  end; // if (nil <> item) then ..
  //
  {$IFDEF LOG_SOCKS_THREADS }
  logMessage('MAIN.postRequest[prq_' + int2str(fid) + '](f=' + int2str(flags) + '): result=' + int2str(result) + ' for ' + OLinfo(item) + ' -- LEAVE');
  {$ENDIF LOG_SOCKS_THREADS }
end;

// --  --
procedure unaIOCPSocksThread.releaseOL(index: unsigned);
begin
  releaseOL(f_olist.get(index));
end;

// --  --
procedure unaIOCPSocksThread.releaseOL(item: punaIOCPSockWorkerOL);
begin
  if (nil <> item) then begin
    //
    {$IFDEF DEBUG }
    if (1 > item.acquired) then begin
      //
      logMessage('Invalid release OL count..');
      item.acquired := 1;
    end;
    {$ENDIF DEBUG }
    //
    if (1 = InterlockedExchangeAdd(item.acquired, -1)) then begin
      //
      // since item was just released, reset timemark
      item.acTimemark := 0;
      InterlockedDecrement(f_olAcquiredCount);
    end
  end;
end;

// --  --
procedure unaIOCPSocksThread.releasePortAndThreads();
var
  c: unsigned;
begin
  c := 0;
  while (c < f_poolThreadCount) do begin
    //
    freeAndNil(f_pool[c]);
    inc(c);
  end;
  //
  freeAndNil(f_port);
end;

// --  --
function unaIOCPSocksThread.removeConnection(connId: tConID; item: pointer): bool;
var
  i: int;
  ol: punaIOCPSockWorkerOL;
  s: tSocket;
  notified: bool;
begin
  {$IFDEF LOG_SOCKS_THREADS }
  logMessage('MAIN.removeConnection(connId=' + int2str(connId) + '; item=' + OLInfo(item) + ') -- ENTER');
  {$ENDIF LOG_SOCKS_THREADS }
  //
  s := 0;
  i := 0;
  notified := false;
  result := false;
  //
  while (i < f_olist.count) do begin
    //
    ol := punaIOCPSockWorkerOL(f_olist.get(i));
    if ((nil <> ol) and (ol.connId = connId)) then begin
      //
      {$IFDEF LOG_SOCKS_THREADS }
      logMessage('MAIN.removeConnection() - [s=' + int2str(s) + '] found OL with same connId = ' + OLInfo(ol));
      {$ENDIF LOG_SOCKS_THREADS }
      //
      if ((0 = s) and ol.socketOwner) then begin
	//
	s := ol.sc;
	{$IFDEF LOG_SOCKS_THREADS }
	logMessage('MAIN.removeConnection() - s := ' + int2str(s));
	{$ENDIF LOG_SOCKS_THREADS }
      end;
      //
      if (not ol.isDone) then
	InterlockedIncrement(f_olDoneCount);
      //
      ol.isDone := true;
      if (isServer) then begin
	//
	if (not notified) then begin
	  //
	  {$IFDEF LOG_SOCKS_THREADS }
	  logMessage('MAIN.removeConnection() - notify server connection is removed.');
	  {$ENDIF LOG_SOCKS_THREADS }
	  //
	  notified := true;
	  unaIOCPSocks(socks).event(unaseServerDisconnect, id, connId);
	end;
	//
	if (0 < ol.acquired) then begin
	  //
	  {$IFDEF LOG_SOCKS_THREADS }
	  logMessage('MAIN.removeConnection() - ol.acquired=' + int2str(ol.acquired) + ' posting PostQueuedCompletionStatus() and sleeping(100)!');
	  {$ENDIF LOG_SOCKS_THREADS }
	  //
	  PostQueuedCompletionStatus(iocpPort.handle, 0, id, POVERLAPPED(ol));
	  sleepThread(100);
	end;
	//
	result := result or (ol = item);
	//
	{$IFDEF LOG_SOCKS_THREADS }
	logMessage('MAIN.removeConnection() - about to remove OL from list, OL=' + OLInfo(ol));
	{$ENDIF LOG_SOCKS_THREADS }
	//
	f_olist.removeItem(ol);
      end
      else
	inc(i);
      //
    end
    else
      inc(i);
    //
  end;
  //
  if (0 <> s) then begin
    //
    {$IFDEF LOG_SOCKS_THREADS }
    logMessage('MAIN.removeConnection() - f_s=' + int2str(f_s) + '; s=' + int2str(s));
    {$ENDIF LOG_SOCKS_THREADS }
    //
    if (f_s = s) then
      threadSocket.close()
    else begin
      //
      WinSock.shutdown(s, SD_BOTH);
      WinSock.closesocket(s);
    end;
    //
    if (nil = item) then
      result := true;
  end
  else begin
    //
    if (nil = item) then
      result := false;
  end;
  //
  {$IFDEF LOG_SOCKS_THREADS }
  logMessage('MAIN.removeConnection(connId=' + int2str(connId) + '); result=' + bool2strStr(result) + ' -- LEAVE');
  {$ENDIF LOG_SOCKS_THREADS }
end;

// --  --
function unaIOCPSocksThread.sendDataTo(connId: tConID; data: pointer; len: uint; out asynch: bool; timeout: tTimeout): int;
var
  i: integer;
  ol, olOK, olNew: punaIOCPSockWorkerOL;
  ac: bool;
  bs: DWORD;
  error: int;
  errorLen: int32;
begin
{$IFDEF LOG_SOCKS_THREADS }
  logMessage('MAIN.sendDataTo(connId=' + int2str(connId) + ', len=' + int2str(len) + ') - ENTER..');
{$ENDIF LOG_SOCKS_THREADS }
  //
  asynch := false;
  //
  if (f_ready) then begin
    //
    result := 0;
    case (f_proto) of

      IPPROTO_TCP: begin
	//
	if (len > c_max_tcp_buf) then
	  result := WSAEMSGSIZE;
      end;

      IPPROTO_UDP: begin
	//
	if (len > c_max_udp_buf) then
	  result := WSAEMSGSIZE;
      end;

      else
	result := WSAEFAULT;

    end;
    //
    if (0 = result) then begin
      //
      error := WSAENOTCONN;
      ol := nil;
      olOK := nil;
      //
      // locate connection by connId
      if (isServer) then begin
	//
	// -- SERVER --
	//
	ol := nil;
	ac := false;
	for i := 0 to f_olist.count - 1 do begin
	  //
	  ol := punaIOCPSockWorkerOL(f_olist.get(i));
	  if ((nil <> ol) and not ol.isDone and (ol.connId = connId)) then begin
	    //
	    olOK := ol;
	    if (acquireOL(ol)) then begin
	      //
	      ac := true;
	      break;
	    end
	    else
	      releaseOL(ol);
	  end
	  else
	    ol := nil;
	end;
	//
	if (not ac and (nil <> olOK)) then begin
	  //
	  olNew := addNewOL();
	  if (nil <> olNew) then begin
	    //
	    olNew.sc := olOK.sc;  // -- no, bad idea: WSASocket(threadSocket.addressFamily, threadSocket.socketType, threadSocket.socketProtocol, nil, 0, WSA_FLAG_OVERLAPPED); //;
	    //port.associate(olNew.sc, id);
	    //olNew.socketOwner := true;
	    olNew.connId := olOK.connId;
	    //
	    move(olOK.addrLocal, olNew.addrLocal, olOK.addrLocalLen);
	    olNew.addrLocalLen := olOK.addrLocalLen;
	    //
	    move(olOK.addrRemote, olNew.addrRemote, olOK.addrRemoteLen);
	    olNew.addrRemoteLen := olOK.addrRemoteLen;
	  end;
	  //
	  ol := olNew;
	end;
      end
      else begin
	//
	// -- CLIENT --
	//
	if (threadSocket.okToWrite() and (0 < f_olist.count)) then begin
	  //
	  i := 0;
	  repeat
	    //
	    ol := f_olist.get(i);
	    inc(i);
        if (nil = ol) then continue;

	    //
	    if (not acquireOL(ol)) then begin
	      //
	      releaseOL(ol);
	      if (i >= f_olist.count) then begin
		//
		errorLen := sizeOf(error);
		if (SOCKET_ERROR = getsockopt(f_s, SOL_SOCKET, SO_ERROR, paChar(@error), errorLen)) then
		  error := WSAGetLastError();
		//
		if (0 = error) then begin
		  //
		  olNew := addNewOL();
		  if (nil <> olNew) then begin
		    //
		    olNew.sc := ol.sc;
		    olNew.connId := ol.connId;
		    move(ol.addrLocal, olNew.addrLocal, ol.addrLocalLen);
		    olNew.addrLocalLen := ol.addrLocalLen;
		    //
		    move(ol.addrRemote, olNew.addrRemote, ol.addrRemoteLen);
		    olNew.addrRemoteLen := ol.addrRemoteLen;
		  end;
		  //
		  ol := olNew;
		end
		else begin
		  //
		  ol := nil;
		  break;	// report some error with main socket
		end;
		//
	      end // if (i >= count)...
	      else
		ol := nil;
	      //
	    end; // if (not acquire(ol)) ..
	    //
	  until (nil <> ol);
	end
	else
	  error := WSAECONNRESET;
      end;
      //
      if (f_ready and (nil <> ol)) then begin
	//
	len := min(len, f_maxDataSize);
	if (0 < len) then begin
	  //
	  move(data^, ol.wbuf.buf^, len);
	  ol.wbuf.len := len;
	  //
	  case (f_proto) of

	    IPPROTO_UDP: begin
	      //
	      ol.op := OP_SENDTO;
	      {$IFDEF DEBUG }
	      inc(ol.opNopostNum);
	      {$ENDIF DEBUG }
	      //
	      {$IFDEF LOG_SOCKS_THREADS }
		logMessage('MAIN.sendDataTo() - about to post ' + OLinfo(ol));
	      {$ENDIF LOG_SOCKS_THREADS }
	      //
	      result := WSASendTo(ol.sc, @ol.wbuf, 1, @bs, 0, @ol.addrRemote, ol.addrRemoteLen, POVERLAPPED(ol), nil);
	    end;

	    IPPROTO_TCP: begin
	      //
	      ol.op := OP_SEND;
	      {$IFDEF DEBUG }
	      inc(ol.opNopostNum);
	      {$ENDIF DEBUG }
	      //
	      {$IFDEF LOG_SOCKS_THREADS }
		logMessage('MAIN.sendDataTo() - about to post ' + OLinfo(ol));
	      {$ENDIF LOG_SOCKS_THREADS }
	      //
	      result := WSASend(ol.sc, @ol.wbuf, 1, @bs, 0, POVERLAPPED(ol), nil);
	    end;

	    else begin
	      //
	      releaseOL(ol);
	      result := WSAEFAULT;
	    end;

	  end; // case
	  //
	  if (0 <> result) then begin
	    //
	    if ( (SOCKET_ERROR = result) and (WSA_IO_PENDING = WSAGetLastError()) ) then begin
	      //
	      result := 0;	// not an error
	      asynch := true;
	    end
	    else begin
	      //
	      releaseOL(ol);
	      result := WSAGetLastError();
	    end;
	  end;
	end
	else begin
	  //
	  releaseOL(ol);
	  result := 0;
	end;
	//
      end
      else begin
  {$IFDEF LOG_SOCKS_THREADS }
	logMessage('MAIN.sendDataTo() - got no OL, error=' + int2str(error));
  {$ENDIF LOG_SOCKS_THREADS }
	result := error;	// report some error
      end;
      //
    end; // if (0 = result) ...
  end
  else
    result := WSAENOTCONN;
  //
{$IFDEF LOG_SOCKS_THREADS }
  logMessage('MAIN.sendDataTo(connId=' + int2str(connId) + '; len=' + int2str(len) + '); result=' + int2str(result) + ' - LEAVE..');
{$ENDIF LOG_SOCKS_THREADS }
end;


end.

