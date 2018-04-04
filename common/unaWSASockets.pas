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

	  unaWSASockets.pas
	  WSA sockets wrapper classes

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

{$IFDEF VC25_WINSOCK20 }
{$ELSE }
  {$MESSAGE ERROR 'VC25_WINSOCK20 symbol must be defined' }
{$ENDIF }

{*
	WSA sockets wrapper classes
}
unit
  unaWSASockets;

interface

{DP:UNIT
  Contains Windows sockets version 2.0 implementation.
}

uses
  Windows, unaTypes, WinSock, unaClasses;

const
//  The  following  may  be used in place of the address family, socket type, or
//  protocol  in  a  call  to WSASocket to indicate that the corresponding value
//  should  be taken from the supplied WSAPROTOCOL_INFO structure instead of the
//  parameter itself.
{$EXTERNALSYM FROM_PROTOCOL_INFO }
  FROM_PROTOCOL_INFO = -1;

//  WinSock 2 extension -- manifest constants for WSASocket()
{$EXTERNALSYM WSA_FLAG_OVERLAPPED }
{$EXTERNALSYM WSA_FLAG_MULTIPOINT_C_ROOT }
{$EXTERNALSYM WSA_FLAG_MULTIPOINT_C_LEAF }
{$EXTERNALSYM WSA_FLAG_MULTIPOINT_D_ROOT }
{$EXTERNALSYM WSA_FLAG_MULTIPOINT_D_LEAF }
  WSA_FLAG_OVERLAPPED        	= $01;
  WSA_FLAG_MULTIPOINT_C_ROOT	= $02;
  WSA_FLAG_MULTIPOINT_C_LEAF	= $04;
  WSA_FLAG_MULTIPOINT_D_ROOT	= $08;
  WSA_FLAG_MULTIPOINT_D_LEAF	= $10;

  // WinSock 2 extension -- new flags for WSASend(), WSASendTo(), WSARecv() and WSARecvFrom()
{$EXTERNALSYM MSG_INTERRUPT }
{$EXTERNALSYM MSG_MAXIOVLEN }
  MSG_INTERRUPT		= $10;    // send/recv in the interrupt context
  MSG_MAXIOVLEN    	= $10;

  //  WinSock 2 extension -- manifest constants for WSAIoctl()

{$EXTERNALSYM IOC_UNIX }
{$EXTERNALSYM IOC_WS2 }
{$EXTERNALSYM IOC_PROTOCOL }
{$EXTERNALSYM IOC_VENDOR }
  IOC_UNIX      = $00000000;
  IOC_WS2       = $08000000;
  IOC_PROTOCOL  = $10000000;
  IOC_VENDOR    = $18000000;

  //
{$EXTERNALSYM SIO_ASSOCIATE_HANDLE }
{$EXTERNALSYM SIO_ENABLE_CIRCULAR_QUEUEING }
{$EXTERNALSYM SIO_FIND_ROUTE }
{$EXTERNALSYM SIO_FLUSH }
{$EXTERNALSYM SIO_GET_BROADCAST_ADDRESS }
{$EXTERNALSYM SIO_GET_EXTENSION_FUNCTION_POINTER }
{$EXTERNALSYM SIO_GET_QOS }
{$EXTERNALSYM SIO_GET_GROUP_QOS }
{$EXTERNALSYM SIO_MULTIPOINT_LOOPBACK }
{$EXTERNALSYM SIO_MULTICAST_SCOPE }
{$EXTERNALSYM SIO_SET_QOS }
{$EXTERNALSYM SIO_SET_GROUP_QOS }
{$EXTERNALSYM SIO_TRANSLATE_HANDLE }
{$EXTERNALSYM SIO_ROUTING_INTERFACE_QUERY }
{$EXTERNALSYM SIO_ROUTING_INTERFACE_CHANGE }
{$EXTERNALSYM SIO_ADDRESS_LIST_QUERY }
{$EXTERNALSYM SIO_ADDRESS_LIST_CHANGE }
{$EXTERNALSYM SIO_QUERY_TARGET_PNP_HANDLE }
{$EXTERNALSYM SIO_ADDRESS_LIST_SORT }
  SIO_ASSOCIATE_HANDLE                =  1 OR IOC_WS2 OR IOC_IN;
  SIO_ENABLE_CIRCULAR_QUEUEING        =  2 OR IOC_WS2 OR IOC_VOID;
  SIO_FIND_ROUTE                      =  3 OR IOC_WS2 OR IOC_OUT;
  SIO_FLUSH                           =  4 OR IOC_WS2 OR IOC_VOID;
  SIO_GET_BROADCAST_ADDRESS           =  5 OR IOC_WS2 OR IOC_OUT;
  SIO_GET_EXTENSION_FUNCTION_POINTER  =  6 OR IOC_WS2 OR IOC_INOUT;
  SIO_GET_QOS                         =  7 OR IOC_WS2 OR IOC_INOUT;
  SIO_GET_GROUP_QOS                   =  8 OR IOC_WS2 OR IOC_INOUT;
  SIO_MULTIPOINT_LOOPBACK             =  9 OR IOC_WS2 OR IOC_IN;
  SIO_MULTICAST_SCOPE                 = 10 OR IOC_WS2 OR IOC_IN;
  SIO_SET_QOS                         = 11 OR IOC_WS2 OR IOC_IN;
  SIO_SET_GROUP_QOS                   = 12 OR IOC_WS2 OR IOC_IN;
  SIO_TRANSLATE_HANDLE                = 13 OR IOC_WS2 OR IOC_INOUT;
  SIO_ROUTING_INTERFACE_QUERY         = 20 OR IOC_WS2 OR IOC_INOUT;
  SIO_ROUTING_INTERFACE_CHANGE        = 21 OR IOC_WS2 OR IOC_IN;
  SIO_ADDRESS_LIST_QUERY              = 22 OR IOC_WS2 OR IOC_OUT; // see below SOCKET_ADDRESS_LIST
  SIO_ADDRESS_LIST_CHANGE             = 23 OR IOC_WS2 OR IOC_VOID;
  SIO_QUERY_TARGET_PNP_HANDLE         = 24 OR IOC_WS2 OR IOC_OUT;
  SIO_ADDRESS_LIST_SORT               = 25 OR IOC_WS2 OR IOC_INOUT;
  //
{$EXTERNALSYM WSAID_ACCEPTEX }
  WSAID_ACCEPTEX		: tGuid = (D1:$B5367DF1; D2:$CBAC; D3:$11CF; D4:($95, $CA, $00, $80, $5F, $48, $A1, $92));
{$EXTERNALSYM WSAID_GETACCEPTEXSOCKADDRS }
  WSAID_GETACCEPTEXSOCKADDRS	: tGuid = (D1:$B5367DF2; D2:$CBAC; D3:$11CF; D4:($95, $CA, $00, $80, $5F, $48, $A1, $92));


{$EXTERNALSYM WSA_IO_PENDING }
{$EXTERNALSYM WSA_INVALID_PARAMETER }
{$EXTERNALSYM WSA_IO_INCOMPLETE }
  WSA_IO_PENDING	= ERROR_IO_PENDING;
  WSA_INVALID_PARAMETER	= ERROR_INVALID_PARAMETER;
  WSA_IO_INCOMPLETE	= ERROR_IO_INCOMPLETE;

  
{$EXTERNALSYM WSAPROTOCOL_LEN }
{$EXTERNALSYM MAX_PROTOCOL_CHAIN }
  WSAPROTOCOL_LEN       = 255;
  MAX_PROTOCOL_CHAIN    = 7;



type
  //
  {$EXTERNALSYM LPWSABUF }
  {$EXTERNALSYM WSABUF }
  LPWSABUF = ^WSABUF;
  WSABUF = packed record
    len: U_LONG;  { the length of the buffer }
    buf: pArray; { the pointer to the buffer }
  end;

  //
  {$EXTERNALSYM TWSAProtocolChain }
  TWSAProtocolChain = packed record
    //
    chainLen: int32;  // the length of the chain,
    // length = 0 means layered protocol,
    // length = 1 means base protocol,
    // length > 1 means protocol chain
    chainEntries: array[0..MAX_PROTOCOL_CHAIN - 1] of int32; // a list of dwCatalogEntryIds
  end;

  //
  {$EXTERNALSYM LPWSAPROTOCOL_INFO }
  {$EXTERNALSYM WSAPROTOCOL_INFO }
  LPWSAPROTOCOL_INFO = ^WSAPROTOCOL_INFO;
  WSAPROTOCOL_INFO = packed record
    //
    dwServiceFlags1: int32;
    dwServiceFlags2: int32;
    dwServiceFlags3: int32;
    dwServiceFlags4: int32;
    dwProviderFlags: int32;
    ProviderId: TGUID;
    dwCatalogEntryId: int32;
    ProtocolChain: TWSAProtocolChain;
    iVersion: int32;
    iAddressFamily: int32;
    iMaxSockAddr: int32;
    iMinSockAddr: int32;
    iSocketType: int32;
    iProtocol: int32;
    iProtocolMaxOffset: int32;
    iNetworkByteOrder: int32;
    iSecurityScheme: int32;
    dwMessageSize: int32;
    dwProviderReserved: int32;
    szProtocol: array[0..WSAPROTOCOL_LEN] of wideChar;
  end;

  {$EXTERNALSYM TServiceType }
  TServiceType = LongInt;

  {$EXTERNALSYM FLOWSPEC }
  FLOWSPEC = packed record
    TokenRate,               // In Bytes/sec
    TokenBucketSize,         // In Bytes
    PeakBandwidth,           // In Bytes/sec
    Latency,                 // In microseconds
    DelayVariation : LongInt;// In microseconds
    ServiceType : TServiceType;
    MaxSduSize, MinimumPolicedSize : LongInt;// In Bytes
  end;

  {$EXTERNALSYM QOS }
  {$EXTERNALSYM PQOS }
  {$EXTERNALSYM LPQOS }
  QOS = packed record
    SendingFlowspec: FLOWSPEC; { the flow spec for data sending }
    ReceivingFlowspec: FLOWSPEC; { the flow spec for data receiving }
    ProviderSpecific: WSABUF; { additional provider specific stuff }
  end;
  PQOS = ^QOS;
  LPQOS = PQOS;

  //
  {$EXTERNALSYM GROUP }
  {$EXTERNALSYM LPINT }
  GROUP = DWORD;
  LPINT = ^int;

  {$EXTERNALSYM WSAOVERLAPPED }
  {$EXTERNALSYM LPWSAOVERLAPPED }
  {$EXTERNALSYM WSAEVENT }
  WSAOVERLAPPED = TOverlapped;
  LPWSAOVERLAPPED = POverlapped;
  WSAEVENT = THANDLE;

  {$EXTERNALSYM LPWSAOVERLAPPED_COMPLETION_ROUTINE }
  LPWSAOVERLAPPED_COMPLETION_ROUTINE = procedure(const dwError, cbTransferred: DWORD; const lpOverlapped: LPWSAOVERLAPPED; const dwFlags: DWORD); stdcall;

{$IFNDEF NO_ANSI_SUPPORT }
{$ELSE }

  proc_acceptEx = function(sListenSocket, sAcceptSocket: tSocket; lpOutputBuffer: pointer; dwReceiveDataLength, dwLocalAddressLength, dwRemoteAddressLength: DWORD;
			  lpdwBytesReceived: LPDWORD; lpOverlapped: POVERLAPPED): BOOL; stdcall;

  proc_getAcceptExSockaddrs = procedure(lpOutputBuffer: Pointer; dwReceiveDataLength, dwLocalAddressLength, dwRemoteAddressLength: DWORD;
				    out localSockaddr: pSockAddr; out localSockaddrLength: int; out remoteSockaddr: pSockAddr; out remoteSockaddrLength: int); stdcall;

{$ENDIF NO_ANSI_SUPPORT }


// --  --
{$EXTERNALSYM WSAIoctl }
function WSAIoctl(s: tSocket; dwIoControlCode: DWORD; lpvInBuffer: pointer; cbInBuffer: DWORD; lpvOutBuffer: pointer; cbOutBuffer: DWORD;
		  lpcbBytesReturned: LPDWORD; lpOverlapped: LPWSAOVERLAPPED; lpCompletionRoutine: LPWSAOVERLAPPED_COMPLETION_ROUTINE): int; stdcall;
// --  --
{$EXTERNALSYM WSASocket }
function WSASocket(af, iType, protocol: int; lpProtocolInfo: LPWSAPROTOCOL_INFO; g: GROUP; dwFlags: DWORD): tSocket; stdcall;

// --  --
{$EXTERNALSYM WSAConnect }
function WSAConnect(s: tSocket; name: pSockAddr; namelen: int; lpCallerData, lpCalleeData: LPWSABUF; lpSQOS, lpGQOS: LPQOS): int; stdcall;

// --  --
{$EXTERNALSYM WSARecv }
function WSARecv(s: tSocket; lpBuffers: LPWSABUF; dwBufferCount: DWORD; lpNumberOfBytesRecvd: LPDWORD; lpFlags: LPDWORD; lpOverlapped: LPWSAOVERLAPPED; lpCompletionRoutine: LPWSAOVERLAPPED_COMPLETION_ROUTINE): int; stdcall;

// --  --
{$EXTERNALSYM WSASend }
function WSASend(s: tSocket; lpBuffers: LPWSABUF; dwBufferCount: DWORD; lpNumberOfBytesSent:  LPDWORD; dwFlags: DWORD;   lpOverlapped: LPWSAOVERLAPPED; lpCompletionRoutine: LPWSAOVERLAPPED_COMPLETION_ROUTINE): int; stdcall;

// --  --
{$EXTERNALSYM WSASendTo }
function WSASendTo(s: tSocket; lpBuffers: LPWSABUF; dwBufferCount: DWORD; lpNumberOfBytesSent: LPDWORD; dwFlags: DWORD;
		   lpTo: pSockAddr; iTolen: int; lpOverlapped: LPWSAOVERLAPPED; lpCompletionRoutine: LPWSAOVERLAPPED_COMPLETION_ROUTINE): int; stdcall;
// --  --
{$EXTERNALSYM WSARecvFrom }
function WSARecvFrom(s: tSocket; lpBuffers: LPWSABUF; dwBufferCount: DWORD; lpNumberOfBytesRecvd: LPDWORD; lpFlags: LPDWORD;
		     lpFrom: pSockAddr; lpFromlen: LPINT; lpOverlapped: LPWSAOVERLAPPED; lpCompletionRoutine: LPWSAOVERLAPPED_COMPLETION_ROUTINE): int; stdcall;
// --  --
{$EXTERNALSYM WSARecvFrom }
function WSAGetOverlappedResult(s: tSocket; lpOverlapped: LPWSAOVERLAPPED; lpcbTransfer: LPDWORD; fWait: BOOL; lpdwFlags: LPDWORD ): BOOL; stdcall;

{$EXTERNALSYM WSAEventSelect }
function WSAEventSelect(s: tSocket; hEventObject: WSAEVENT; lNetworkEvents: long): int; stdcall;



// --  --
function getWSAProcAddr(s: tSocket; const guid: tGuid): pointer;


implementation


uses
  unaUtils;

const
  winsock2 = 'WS2_32.DLL';


//
function WSAIoctl; external winsock2 name 'WSAIoctl';
function WSASocket; external winsock2 name 'WSASocketW';
function WSAConnect; external winsock2 name 'WSAConnect';
function WSARecv; external winsock2 name 'WSARecv';
function WSASend; external winsock2 name 'WSASend';
function WSASendTo; external winsock2 name 'WSASendTo';
function WSARecvFrom; external winsock2 name 'WSARecvFrom';
function WSAGetOverlappedResult; external winsock2 name 'WSAGetOverlappedResult';
function WSAEventSelect; external winsock2 name 'WSAEventSelect';

// --  --
function getWSAProcAddr(s: tSocket; const guid: tGuid): pointer;
var
  b: DWORD;
begin
  WSAIoctl(s, SIO_GET_EXTENSION_FUNCTION_POINTER, @guid, sizeOf(guid), @result, sizeOf(result), @b, nil, nil);
end;


end.

