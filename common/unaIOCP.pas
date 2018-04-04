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

	  unaIOCP.pas
	  IOCP interface

	----------------------------------------------
	  Copyright (c) 2007-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, Dec 2007

	  modified by:
		Lake, Dec 2007

	----------------------------------------------
*)

{$I unaDef.inc }

{$IFDEF VC25_IOCP }
{$ELSE }
  "VC25_IOCP symbol must be defined"
{$ENDIF VC25_IOCP }

unit
  unaIOCP;

interface

uses
  Windows, unaTypes, unaClasses;

type
  //
  // -- unaIOCPClass --
  //
  unaIOCPClass = class(unaObject)
  private
    f_handle: tHandle;
    f_numProc: unsigned;
  public
    constructor create(numberOfConcurrentThreads: DWORD = 0);
    //
    procedure BeforeDestruction(); override;
    //
    {DP:METHOD
      Returns true if association was completed successfully.
    }
    function associate(device: tHandle; key: DWORD; numOfWorkerThreads: uint = 0): bool;
    //
    property handle: tHandle read f_handle;
    //
    property numProcessors: unsigned read f_numProc;
  end;


  //
  // -- unaIOCPWorkerThread --
  //
  unaIOCPWorkerThread = class(unaThread)
  private
    f_port: unaIOCPClass;
    f_timeout: tTimeout;
  protected
    function execute(threadID: unsigned): int; override;
    //
    procedure onIOComplete(numBytes, key: DWORD; ol: POVERLAPPED); virtual;
    procedure onIOError(key: DWORD; ol: POVERLAPPED; err: DWORD); virtual;
  public
    constructor create(port: unaIOCPClass; activate: bool; prio: DWORD = THREAD_PRIORITY_HIGHEST; timeout: tTimeout = 200);
    //
    property port: unaIOCPClass read f_port;
    //
    property timeout: tTimeout read f_timeout write f_timeout;
  end;


  proc_createIOCP = function(fileHandle, existingCompletionPort: tHandle; completionKey, numberOfConcurrentThreads: DWORD): tHandle; stdcall;
  proc_getQCS = function(completionPort: tHandle; var lpNumberOfBytesTransferred, lpCompletionKey: DWORD; var lpOverlapped: pOverlapped; dwMilliseconds: DWORD): bool; stdcall;


var
  g_createIOCP: proc_createIOCP;
  g_getQCS: proc_getQCS;


// --  --
function iocpAvailable(): bool;


implementation


uses
  unaUtils;


var
  g_iocpAvailChecked: bool;
  g_iocpAvailable: bool;

// --  --
function iocpAvailable(): bool;
var
  res: tHandle;
begin
  if (not g_iocpAvailChecked) then begin
    //
    result := assigned(g_createIOCP) and assigned(g_getQCS);
    if (result) then begin
      //
      res := g_createIOCP(INVALID_HANDLE_VALUE, 0, 0, 0);
      if (ERROR_CALL_NOT_IMPLEMENTED = GetLastError()) then
	result := false
      else begin
	//
	if (0 <> res) then
	  CloseHandle(res);
	//
	result := true;
      end;
    end;
    //
    g_iocpAvailable := result;
    g_iocpAvailChecked := true;
  end
  else
    result := g_iocpAvailable;
end;


{ unaIOCPClass }

// --  --
function unaIOCPClass.associate(device: tHandle; key: DWORD; numOfWorkerThreads: uint): bool;
begin
  if (iocpAvailable()) then
    result := (handle = g_createIOCP(device, handle, key, numOfWorkerThreads))
  else
    result := false;
end;

// --  --
procedure unaIOCPClass.BeforeDestruction();
begin
  if (0 <> handle) then
    CloseHandle(handle);
  //
  inherited;
end;

// --  --
constructor unaIOCPClass.create(numberOfConcurrentThreads: DWORD);
var
  si: tSYSTEMINFO;
begin
  GetSystemInfo(si);
  f_numProc := si.dwNumberOfProcessors;
  if (1 > f_numProc) then
    f_numProc := 1;	// assume there is at least one processor
  //
  if (iocpAvailable()) then
    f_handle := g_createIOCP(INVALID_HANDLE_VALUE, 0, 0, numberOfConcurrentThreads)
  else
    f_handle := INVALID_HANDLE_VALUE;
  //
  inherited create();
end;


{ unaIOCPWorkerThread }

// --  --
constructor unaIOCPWorkerThread.create(port: unaIOCPClass; activate: bool; prio: DWORD; timeout: tTimeout);
begin
  f_port := port;
  f_timeout := timeout;
  //
  inherited create(activate, prio {$IFDEF DEBUG }, className{$ENDIF DEBUG });
end;

// --  --
function unaIOCPWorkerThread.execute(threadID: unsigned): int;
var
  numBytes: DWORD;
  key: DWORD;
  ol: POVERLAPPED;
  fatal: unsigned;
begin
  if (iocpAvailable()) then begin
    //
    fatal := 0;
    while (not shouldStop) do begin
      //
      if (g_getQCS(port.handle, numBytes, key, ol, timeout)) then begin
	//
	onIOComplete(numBytes, key, ol);
      end
      else begin
	//
	if (nil <> ol) then
	  onIOError(key, ol, GetLastError())
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
      end;
    end;
    //
    if (1 > fatal) then
      result := 0
    else begin
      //
      if (99 < fatal) then
	result := -2	// exit due big amount of invalid GetQueuedCompletionStatus() calls
      else
	result := -1;	// exit with some invalid GetQueuedCompletionStatus() calls
    end;
  end
  else
    result := -3;	// no IOCP API available
end;

// --  --
procedure unaIOCPWorkerThread.onIOComplete(numBytes, key: DWORD; ol: POVERLAPPED);
begin
  //
end;

// --  --
procedure unaIOCPWorkerThread.onIOError(key: DWORD; ol: POVERLAPPED; err: DWORD);
begin
  //
end;


//
var
  module: hModule;

initialization
  //
{$IFNDEF NO_ANSI_SUPPORT }
  if (g_wideApiSupported) then
{$ENDIF NO_ANSI_SUPPORT }
    module := LoadLibraryW(kernel32)
{$IFNDEF NO_ANSI_SUPPORT }
  else
    module := LoadLibraryA(kernel32);
{$ENDIF NO_ANSI_SUPPORT }
  ;
  //
  if (0 <> module) then begin
    //
    g_createIOCP := GetProcAddress(module, 'CreateIoCompletionPort');
    g_getQCS := GetProcAddress(module, 'GetQueuedCompletionStatus');
  end;
end.

