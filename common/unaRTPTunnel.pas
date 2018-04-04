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

	  unaRTPTunnel.pas
	  P2P RTP Tunnel server class

	----------------------------------------------
	  Copyright (c) 2010-2012 Lake of Soft
	  All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, Jul 2010

	  modified by:
		Lake, Jul-Oct 2010

	----------------------------------------------
*)

{$DEFINE UNA_RTPTUNNEL_ENABLE_LOG   }	// undefine for a (quite) small performance benefit (if you need no callback log notifications)

{$DEFINE UNA_RTPTUNNEL_ENABLE_LOGEX }	// ex log

{$I unaDef.inc }

{*
  P2P RTP Tunnel server class.

  @Author Lake

  Version 2.5.2010.07 First release

  Version 2.5.2010.10 New SSRC map
}

unit
  unaRTPTunnel;

interface

uses
  Windows, WinSock,
  unaTypes, unaSocks_RTP;

const
  //
  c_max_tunnels	 	= 50;		// maximum number of tunnels per server

  // error codes
  E_TOO_MANY_TUNNELS	= -100;		// too many tunnels
  E_BAD_ADDRESS		= -101;		// malformed address
  E_BAD_INDEX		= -102;		// invalid index
  E_LOCKED		= -103;		// server is locked
  E_BAD_SSRC		= -104;		// malformed SSRC

  //
  C_MT_ADDR		= 1;	// map socket addresses
  C_MT_SSRC		= 2;	// map SSRCs

{$IFDEF UNA_RTPTUNNEL_ENABLE_LOG }
  //
// server was started - data is port number
  C_EV_S_STARTED	= 1;	
// server was stopped - data is status code
  C_EV_S_STOPPED	= 2;    
// SSRC tunnel has resolved source address - data is tunnel index
  C_EV_T_RESOLVED_SRC	= 3;	
// SSRC tunnel has resolved dest address - data is tunnel index
  C_EV_T_RESOLVED_DST	= 4;	
// new tunnel was added - data is tunnel index
  C_EV_T_ADDED		= 5;    
// tunnel was updated - data is tunnel index
  C_EV_T_UPDATED	= 6;	
// tunnel was removed - data is tunnel index
  C_EV_T_REMOVED	= 7;	

{$ENDIF UNA_RTPTUNNEL_ENABLE_LOG }


type
  {*
	SRC <-> DSP map rule
  }
  punaTunnelMap = ^unaTunnelMap;
  unaTunnelMap = packed record
    //
    r_num_packets_src: int64;
    r_num_packets_dst: int64;
    r_num_packets_sent: int64;
    //
    case r_mapType: int of

      C_MT_ADDR: (
	r_src_addr: tSockAddrIn;
	r_dst_addr: tSockAddrIn;
      );

      C_MT_SSRC: (
	r_src_ssrc: u_int32;
	r_dst_ssrc: u_int32;
	r_known_src_addr: tSockAddrIn;
	r_known_dst_addr: tSockAddrIn;
      );
  end;


{$IFDEF UNA_RTPTUNNEL_ENABLE_LOG }
  {*
	Notifies server events

	@param event see C_EV_xxx constants
  }
  proc_unaTunnelServerOnLog	= procedure(sender: tObject; event: int; data: int) of object;
{$ENDIF UNA_RTPTUNNEL_ENABLE_LOG }

  {*
	RTP Tunnel server class.
  }
  unaRTPTunnelServer = class(unaRTPTransmitter)
  private
    f_tunnels: array[0..c_max_tunnels - 1] of unaTunnelMap;
    f_tc: int;
    //
    f_ptOut: int64;
    f_ptIn: int64;
    //
{$IFDEF UNA_RTPTUNNEL_ENABLE_LOG }
    f_log: proc_unaTunnelServerOnLog;
{$ENDIF UNA_RTPTUNNEL_ENABLE_LOG }
    //
    function getTM(index: int): punaTunnelMap;
{$IFDEF UNA_RTPTUNNEL_ENABLE_LOG }
    procedure log(event, data: int);
{$ENDIF UNA_RTPTUNNEL_ENABLE_LOG }
  protected
    {*
	Need to do some cleanup before opening.
    }
    function doOpen(waitForThreadsToStart: bool = true): bool; override;
    procedure doClose(); override;
    {*
	Analyze and redirect packets according to rules.
    }
    procedure onPayload(addr: pSockAddrIn; hdr: prtp_hdr; data: pointer; len, packetSize: uint); override;
  public
    function addTunnel(const src, dst: tSockAddrIn): HRESULT; overload;
    function addTunnel(const src, dst: string): HRESULT; overload;
    function addTunnel(srcSSRC, dstSSRC: u_int32): HRESULT; overload;
    //
    function updateTunnel(index: int; const src, dst: string): HRESULT; overload;
    function updateTunnel(index: int; srcSSRC, dstSSRC: u_int32): HRESULT; overload;
    //
    function removeTunnel(index: int): HRESULT; overload;
    function removeTunnel(srcSSRC, dstSSRC: u_int32): HRESULT; overload;
    //
    property tunnelCount: int read f_tc;
    property tunnel[index: int]: punaTunnelMap read getTM;
    //
    property packetsSent: int64 read f_ptOut;
    property packetsReceived: int64 read f_ptIn;
    //
{$IFDEF UNA_RTPTUNNEL_ENABLE_LOG }
    {*
	Notifies on some server events.
    }
    property onLogEvent: proc_unaTunnelServerOnLog read f_log write f_log;
{$ENDIF UNA_RTPTUNNEL_ENABLE_LOG }
  end;


implementation


uses
  unaUtils, unaClasses, unaSockets;



// --  --
function str2addr(const ipport: string; var addr: tSockAddrIn): bool;
var
  p: int;
begin
  p := pos(':', ipport);
  result := makeAddr( copy(ipport, 1, p - 1), copy(ipport, p + 1, maxInt), addr );
end;


{ unaRTPTunnelServer }

// --  --
function unaRTPTunnelServer.addTunnel(const src, dst: tSockAddrIn): HRESULT;
begin
  result := HRESULT(E_LOCKED);
  //
  if (acquire(false, 1000)) then try
    //
    if (f_tc < c_max_tunnels) then begin
      //
      if (sameAddr(src, dst)) then
	result := HRESULT(E_BAD_ADDRESS)
      else begin
	//
	f_tunnels[f_tc].r_mapType := C_MT_ADDR;
	f_tunnels[f_tc].r_src_addr := src;
	f_tunnels[f_tc].r_dst_addr := dst;
	inc(f_tc);
	//
{$IFDEF UNA_RTPTUNNEL_ENABLE_LOG }
	log(C_EV_T_ADDED, f_tc - 1);
{$ENDIF UNA_RTPTUNNEL_ENABLE_LOG }
	//
	result := S_OK;
      end;
    end
    else
      result := HRESULT(E_TOO_MANY_TUNNELS);
  finally
    releaseWO();
  end;
end;

// --  --
function unaRTPTunnelServer.addTunnel(const src, dst: string): HRESULT;
var
  srca, dsta: tSockAddrIn;
begin
  if (str2addr(src, srca) and str2addr(dst, dsta)) then
    result := addTunnel(srca, dsta)
  else
    result := HRESULT(E_BAD_ADDRESS);
end;

// --  --
function unaRTPTunnelServer.addTunnel(srcSSRC, dstSSRC: u_int32): HRESULT;
begin
  if ((0 <> srcSSRC) and (0 <> dstSSRC)) then begin
    //
    result := HRESULT(E_LOCKED);
    //
    if (acquire(false, 1000)) then try
      //
      if (f_tc < c_max_tunnels) then begin
	//
	f_tunnels[f_tc].r_mapType := C_MT_SSRC;
	f_tunnels[f_tc].r_src_ssrc := swap32u(srcSSRC);
	f_tunnels[f_tc].r_dst_ssrc := swap32u(dstSSRC);
	fillchar(f_tunnels[f_tc].r_known_src_addr, sizeof(tSockAddrIn), #0);
	fillchar(f_tunnels[f_tc].r_known_dst_addr, sizeof(tSockAddrIn), #0);
	//
	inc(f_tc);
{$IFDEF UNA_RTPTUNNEL_ENABLE_LOG }
	log(C_EV_T_ADDED, f_tc - 1);
{$ENDIF UNA_RTPTUNNEL_ENABLE_LOG }
	//
      {$IFDEF UNA_RTPTUNNEL_ENABLE_LOGEX }
	logMessage(className + '.addTunnel() - new tunnel srcSSRC=' + int2str(srcSSRC) + '/dstSSRC=' + int2str(dstSSRC));
      {$ENDIF UNA_RTPTUNNEL_ENABLE_LOGEX }
	//
	result := S_OK;
      end
      else
	result := HRESULT(E_TOO_MANY_TUNNELS);
    finally
      releaseWO();
    end;
  end
  else
    result := HRESULT(E_BAD_SSRC);
end;

// --  --
procedure unaRTPTunnelServer.doClose();
begin
  inherited;
  //
{$IFDEF UNA_RTPTUNNEL_ENABLE_LOG }
  log(C_EV_S_STOPPED, 0);
{$ENDIF UNA_RTPTUNNEL_ENABLE_LOG }
end;

// --  --
function unaRTPTunnelServer.doOpen(waitForThreadsToStart: bool): bool;
var
  i: int;
begin
  if (acquire(false, 130)) then try
    //
    for i := 0 to tunnelCount - 1 do begin
      //
      case (f_tunnels[i].r_mapType) of

	C_MT_ADDR: ;

	C_MT_SSRC: begin
	  //
	  fillchar(f_tunnels[i].r_known_src_addr, sizeof(tSockAddrIn), #0);
	  fillchar(f_tunnels[i].r_known_dst_addr, sizeof(tSockAddrIn), #0);
	end;

      end;
      //
      f_tunnels[i].r_num_packets_src := 0;
      f_tunnels[i].r_num_packets_dst := 0;
      f_tunnels[i].r_num_packets_sent := 0;
    end;
  finally
    releaseWO();
  end;
  //
  f_ptOut := 0;
  f_ptIn := 0;
  //
  result := inherited doOpen(waitForThreadsToStart);
  //
{$IFDEF UNA_RTPTUNNEL_ENABLE_LOG }
  if (result) then
    log(C_EV_S_STARTED, str2intInt(bind2port, 0));
{$ENDIF UNA_RTPTUNNEL_ENABLE_LOG }
end;

// --  --
function unaRTPTunnelServer.getTM(index: int): punaTunnelMap;
begin
  if (index < f_tc) then
    result := @f_tunnels[index]
  else
    result := nil;
end;

{$IFDEF UNA_RTPTUNNEL_ENABLE_LOG }
// --  --
procedure unaRTPTunnelServer.log(event, data: int);
begin
  if (assigned(f_log)) then
    f_log(self, event, data);
end;
{$ENDIF UNA_RTPTUNNEL_ENABLE_LOG }

// --  --
procedure unaRTPTunnelServer.onPayload(addr: pSockAddrIn; hdr: prtp_hdr; data: pointer; len, packetSize: uint);
var
  i: int;
  //
  src, dst: bool;
  dest_addr: pSockAddrIn;
{$IFDEF UNA_RTPTUNNEL_ENABLE_LOGEX }
  found: bool;
{$ENDIF UNA_RTPTUNNEL_ENABLE_LOGEX }
begin
  inc(f_ptIn);	// update total number of packets received
  //
  // see if addr is one of our tunnel map rules
  if (acquire(true, 10)) then try
    //
  {$IFDEF UNA_RTPTUNNEL_ENABLE_LOGEX }
    found := false;
  {$ENDIF UNA_RTPTUNNEL_ENABLE_LOGEX }
    //
    for i := 0 to tunnelCount - 1 do begin
      //
      dest_addr := nil;
      src := false;
      dst := false;
      //
      case (f_tunnels[i].r_mapType) of

	C_MT_ADDR: begin
	  //
	  if (sameAddr(addr^, f_tunnels[i].r_src_addr)) then begin
	    //
	    src := true;
	    dest_addr := @f_tunnels[i].r_dst_addr;
	  end
	  else begin
	    //
	    if (sameAddr(addr^, f_tunnels[i].r_dst_addr)) then begin
	      //
	      dst := true;
	      dest_addr := @f_tunnels[i].r_src_addr;
	    end;
	  end;
	end;

	C_MT_SSRC: begin
	  //
	  if (hdr.r_ssrc_NO = f_tunnels[i].r_src_ssrc) then begin
	    //
	  {$IFDEF UNA_RTPTUNNEL_ENABLE_LOGEX }
	    found := true;
	  {$ENDIF UNA_RTPTUNNEL_ENABLE_LOGEX }
	    //
	    src := true;
	    if (0 = f_tunnels[i].r_known_src_addr.sin_addr.S_addr) then begin
	      //
	      f_tunnels[i].r_known_src_addr := addr^;
	      //
	    {$IFDEF UNA_RTPTUNNEL_ENABLE_LOGEX }
	      logMessage(className + '.onPayload() - now we know the address for srcSSRC=' + int2str(swap32u(hdr.r_ssrc_NO)) + ' and the address is ' + addr2str(@f_tunnels[i].r_known_src_addr));
	    {$ENDIF UNA_RTPTUNNEL_ENABLE_LOGEX }
	      //
{$IFDEF UNA_RTPTUNNEL_ENABLE_LOG }
	      log(C_EV_T_RESOLVED_SRC, i);
{$ENDIF UNA_RTPTUNNEL_ENABLE_LOG }
	    end;
	    //
	    if (0 <> f_tunnels[i].r_known_dst_addr.sin_addr.S_addr) then
	      dest_addr := @f_tunnels[i].r_known_dst_addr
	    else begin
	      //
	    {$IFDEF UNA_RTPTUNNEL_ENABLE_LOGEX }
	      logMessage(className + '.onPayload() - we know the address for srcSSRC=' + int2str(swap32u(hdr.r_ssrc_NO)) + ' but destination address for dstSSRC=' + int2str(swap32u(f_tunnels[i].r_dst_ssrc)) + ' is not known yet.');
	    {$ENDIF UNA_RTPTUNNEL_ENABLE_LOGEX }
	    end;
	  end
	  else begin
	    //
	    if (hdr.r_ssrc_NO = f_tunnels[i].r_dst_ssrc) then begin
	      //
	    {$IFDEF UNA_RTPTUNNEL_ENABLE_LOGEX }
	      found := true;
	    {$ENDIF UNA_RTPTUNNEL_ENABLE_LOGEX }
	      //
	      dst := true;
	      if (0 = f_tunnels[i].r_known_dst_addr.sin_addr.S_addr) then begin
		//
		f_tunnels[i].r_known_dst_addr := addr^;
		//
	      {$IFDEF UNA_RTPTUNNEL_ENABLE_LOGEX }
		logMessage(className + '.onPayload() - now we know the address for dstSSRC=' + int2str(swap32u(hdr.r_ssrc_NO)) + ' and the address is ' + addr2str(@f_tunnels[i].r_known_dst_addr));
	      {$ENDIF UNA_RTPTUNNEL_ENABLE_LOGEX }
		//
	      {$IFDEF UNA_RTPTUNNEL_ENABLE_LOG }
		log(C_EV_T_RESOLVED_DST, i);
	      {$ENDIF UNA_RTPTUNNEL_ENABLE_LOG }
	      end;
	      //
	      if (0 <> f_tunnels[i].r_known_src_addr.sin_addr.S_addr) then
		dest_addr := @f_tunnels[i].r_known_src_addr
	      else begin
		//
	      {$IFDEF UNA_RTPTUNNEL_ENABLE_LOGEX }
		logMessage(className + '.onPayload() - we know the address for dstSSRC=' + int2str(swap32u(hdr.r_ssrc_NO)) + ' but destination address for srcSSRC=' + int2str(swap32u(f_tunnels[i].r_src_ssrc)) + ' is not known yet.');
	      {$ENDIF UNA_RTPTUNNEL_ENABLE_LOGEX }
	      end;
	    end;
	  end;
	  //
	end;

      end;	// case
      //
      if (src) then
	inc(f_tunnels[i].r_num_packets_src);
      if (dst) then
	inc(f_tunnels[i].r_num_packets_dst);
      //
      if (nil <> dest_addr) then begin
	//
	if (0 = send_To(dest_addr, hdr, packetSize, false)) then begin
	  //
	  inc(f_tunnels[i].r_num_packets_sent);
	  inc(f_ptOut);	// update total number of packets received
	end;
      end;
      //
    end; // for (all tunnels)
    //
  {$IFDEF UNA_RTPTUNNEL_ENABLE_LOGEX }
    if (not found) then
      logMessage(className + '.onPayload() - unknown SSRC=' + int2str(swap32u(hdr.r_ssrc_NO)));
  {$ENDIF UNA_RTPTUNNEL_ENABLE_LOGEX }
    //
  finally
    releaseRO();
  end;
end;

function unaRTPTunnelServer.removeTunnel(srcSSRC, dstSSRC: u_int32): HRESULT;
var
  i: int32;
  index: int;
begin
  result := HRESULT(E_LOCKED);
  //
  if (acquire(false, 1000)) then try
    //
    index := -1;
    srcSSRC := swap32u(srcSSRC);
    dstSSRC := swap32u(dstSSRC);
    //
    for i := 0 to tunnelCount - 1 do begin
      //
      if (C_MT_SSRC = tunnel[i].r_mapType) and
	 (srcSSRC = tunnel[i].r_src_ssrc) and
	 (dstSSRC = tunnel[i].r_dst_ssrc) then begin
	//
	index := i;
	break;
      end;
    end;
    //
    if (0 <= index) then
      result := removeTunnel(index)
    else
      result := HRESULT(E_BAD_INDEX);
  finally
    releaseWO();
  end;
end;

// --  --
function unaRTPTunnelServer.removeTunnel(index: int): HRESULT;
var
  nm: int;
begin
  result := HRESULT(E_LOCKED);
  //
  if (acquire(false, 1000)) then try
    //
    if ((0 <= index) and (index < tunnelCount)) then begin
      //
      nm := tunnelCount - index;
      if (1 < nm) then
	move(f_tunnels[index + 1], f_tunnels[index], nm * sizeof(f_tunnels[0]));
      //
      dec(f_tc);
      //
{$IFDEF UNA_RTPTUNNEL_ENABLE_LOG }
      log(C_EV_T_REMOVED, index);
{$ENDIF UNA_RTPTUNNEL_ENABLE_LOG }
      //
      result := S_OK;
    end
    else
      result := HRESULT(E_BAD_INDEX);
  finally
    releaseWO();
  end;
end;

// --  --
function unaRTPTunnelServer.updateTunnel(index: int; const src, dst: string): HRESULT;
var
  srca, dsta: tSockAddrIn;
begin
  if (index < f_tc) then begin
    //
    if (str2addr(src, srca) and str2addr(dst, dsta)) then begin
      //
      f_tunnels[index].r_src_addr := srca;
      f_tunnels[index].r_dst_addr := dsta;
      f_tunnels[index].r_mapType := C_MT_ADDR;
      result := S_OK;
    end
    else
      result := HRESULT(E_BAD_ADDRESS);
  end
  else
    result := HRESULT(E_INVALIDARG);
end;

// --  --
function unaRTPTunnelServer.updateTunnel(index: int; srcSSRC, dstSSRC: u_int32): HRESULT;
begin
  if (index < f_tc) then begin
    //
    if ((0 <> srcSSRC) and (0 <> dstSSRC)) then begin
      //
      f_tunnels[index].r_src_ssrc := swap32u(srcSSRC);
      f_tunnels[index].r_dst_ssrc := swap32u(dstSSRC);
      fillchar(f_tunnels[index].r_known_src_addr, sizeof(tSockAddrIn), #0);
      fillchar(f_tunnels[index].r_known_dst_addr, sizeof(tSockAddrIn), #0);
      f_tunnels[index].r_mapType := C_MT_SSRC;
      //
      result := S_OK;
    end
    else
      result := HRESULT(E_BAD_SSRC);
  end
  else
    result := HRESULT(E_INVALIDARG);
end;


end.

