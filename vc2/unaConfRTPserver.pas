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

	  unaConfRTPserver.pas
	  Conf RTP server class

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
  unaConfRTP server class.

  @Author Lake
  @Version 2.5.2010.03 Still here
  @Version 2.5.2010.10 Room/users names
  @Version 2.5.2010.12 RTCP
}

{$IFDEF DEBUG }
  {xx $DEFINE DEBUG_LOST_FIRST_REPLY }	// define to emulate loss of first reply from server
  {$DEFINE LOG_unaConfRTPserver_INFOS }	// define to let server log some info
{$ENDIF DEBUG }


unit
  unaConfRTPserver;

interface

uses
  Windows, unaTypes, unaClasses, unaConfRTP,
  WinSock, Classes,
  unaSockets, unaVC_pipe, unaSocks_RTP;

type
  tRoomID       = int32;        // must be compatible with integer


  {*
	List of conference rooms.
  }
  unaConfRTProomList = class(unaIDList)
  protected
    function getId(item: pointer): int64; override;
  end;

  {*
	List of users in a conference rooms.
  }
  unaConfRTProomUserList = class(unaIDList)
  protected
    function getId(item: pointer): int64; override;
  end;

  //
  TunaConfRTPserver = class;

  {*
	RTP Conference user.
  }
  unaConfRTProomUser = class(unaObject)
  private
    f_userID: u_int32;
    //
    f_srv: TunaConfRTPserver;
    //
    f_addrRTP: sockaddr_in;
    f_addrRTPValid: bool;
    //
    f_addrRTCP: sockaddr_in;
    f_addrRTCPValid: bool;
    //
    f_allowIN: bool;
    f_allowOUT: bool;
    //
    f_bwTM: uint64;
    f_bwAcq: unaAcquireType;
    f_bwInDelta, f_bwOutDelta: int64;
    f_bwIn, f_bwOut: int;	// bits per second
    //
    f_mustReplyWith: uint32;	//
    f_RTCPtm: uint64;
    //
    f_verified: bool;
    f_lastAudioCodec: int;
  public
    {*
	Creates a new user object.
    }
    constructor create(srv: TunaConfRTPserver; userID: u_int32);
    {*
    }
    destructor Destroy(); override;
    //
    {*
	Copies RTCP information.

	@param info Buffer to receive the info
	@return True if successfull
    }
    function copyRTCPInfo(var info: rtp_site_info): bool;
    {*
	User ID (SSRC)
    }
    property userID: u_int32 read f_userID;
    //
    // -- properties --
    //
    {*
	Incoming bandwidth.
    }
    property bwIn: int read f_bwIn;
    {*
	Outgoing bandwidth.
    }
    property bwOut: int read f_bwOut;
    {*
	User is allowed to stream inbound audio into room.
    }
    property allowIN : bool read f_allowIN  write f_allowIN ;
    {*
	User is allowed to receive outbound audio from room.
    }
    property allowOUT: bool read f_allowOUT write f_allowOUT;
    {*
	User was authorized.
    }
    property verified: bool read f_verified;
    {*
	Last auido payload used in transmit.
    }
    property lastAudioCodec: int read f_lastAudioCodec;
  end;


  {*
	RTP Conference room
  }
  unaConfRTProom = class(unaObject)
  private
    f_roomID: tRoomID;
    f_roomName: wString;
    //
    f_srv: TunaConfRTPserver;
    //
    f_seats: unaList;	// sorted list seats with participating users
    //
    f_abandonedTM: uint64;
    //
    f_bwTM: uint64;
    f_bwInDelta, f_bwOutDelta: int64;
    f_bwIn, f_bwOut: int;	// bits per second
    //
    f_closed: bool;
    //
    procedure updateBw(isIn: bool; delta: int; cln: unaConfRTProomUser);
    //
    function getCC(): int;
  protected
    {*
	Returns index.
    }
    function addUser(userID: u_int32): int;
  public
    {*
	Creates a new room.
    }
    constructor create(srv: TunaConfRTPserver; const roomName: wString; roomID: tRoomID = -1);
    {*
	Destroys room.
    }
    destructor Destroy(); override;
    //
    {*
	Removes user from this room.

	@param userID user ID
        @return True if user was found and removed from room seats
    }
    function dropUser(userID: u_int32): bool;
    {*
	Locates user in room.

	@param index user index (from 0 to userCount - 1)
	@param ro Indicates access level to user object, true means read-only
	@param timeout timeout

	@return Acquired user object or nil. Object must be released with .release() when it is no longer needed.
    }
    function userByIndexAcquire(index: int; ro: bool = true; timeout: tTimeout = 100): unaConfRTProomUser;
    {*
	Locates user in room.

	@param userID user ID

	@return True if user with specified ID is listed in this room.
    }
    function hasUser(userID: u_int32): bool;
    {*
	Sends some message to all clients in the room.

	@param msg Text to be announced.
    }
    procedure announce(const msg: wString);
    //
    {*
	True if room is closed.
	Use srv.roomStartup() / srv.roomShutdown to open/close the room.
    }
    property closed: bool read f_closed;	//
    {*
	Room ID.
    }
    property roomID: tRoomID read f_roomID;
    {*
	Room Name.
    }
    property roomName: wString read f_roomName;
    {*
	Number of users.
    }
    property userCount: int read getCC;
    {*
	Incoming bandwidth.
    }
    property bwIn: int read f_bwIn;
    {*
	Outgoing bandwidth.
    }
    property bwOut: int read f_bwOut;
  end;


  //
  punaConfRTPsynchEvent = ^unaConfRTPsynchEvent;
  unaConfRTPsynchEvent = packed record
    r_type: int32;
    r_userID: u_int32;
    r_roomID: tRoomID;
    r_addr: sockaddr_in;
  end;


  // -- server events --
  //
  evonUserConnect = procedure(sender: tObject; userID: int32; roomID: tRoomID; const IP, port: string; isConnected: bool) of object;
  evonUserVerify = procedure(sender: tObject; userID: int32; roomID: tRoomID; const IP, port: string; var accept: bool) of object;
  evonRoomAddRemove = procedure(sender: tObject; roomID: tRoomID; doAdd: bool) of object;


  {*
  	RTP Conference server
  }
  TunaConfRTPserver = class(unavclInOutPipe)
  private
    f_port: string;
    f_bind2ip: string;
    //
    f_acr, f_arr: boolean;
    //
    f_idleRoomIndex: int;
    f_roomlessUserIndex: int;
    f_srvLock: unaObject;
    //
    f_rooms2: unaConfRTProomList;
    f_users2: unaConfRTProomUserList;
    f_deadUserID: unaList;
    //
    f_userSInOneRoom: boolean;
    //
    f_roomNameA: aString;
    f_roomNameW: string;
    //
    f_trans: unaRTPTransmitter;
    f_lostTrans: int64;
{$IFDEF VCX_DEMO }
    f_totalTrans: int64;
{$ENDIF VCX_DEMO }
    //
    f_masterKey: unaConfRTPkey;
    f_sessionKey: unaConfRTPkey;
    //
    f_onUC: evonUserConnect;
    f_onUserVerify: evonUserVerify;
    f_onRoomAddRemove: evonRoomAddRemove;
    //
    f_idleThread: unaThread;
    f_randThread: unaRandomGenThread;
    //
    f_syncEvents: unaRecordList;
    //
    f_roomNames: unaWideStringList;
    //
    f_srvName: string;
    //
    procedure setMasterKey(const value: string);
    //
    procedure addSynchEvent(etype: int32; userID: u_int32; roomID: tRoomID; addr: psockaddrin);
    //
    procedure handleClnCmd(userID: u_int32; addr: pSockAddrIn; const cmd: aString; cmdData: punaConfRTPcmd);
    //
    function getErrorCode(): int;
    function getSSRC(): u_int32;
    //
    function _acr(obj: unaObject; ro: bool; timeout: tTimeout {$IFDEF DEBUG }; const reason: string {$ENDIF DEBUG }): unaObject;
    //
    function getRoomCount2(): int;
    function getUserCount2(): int;
    function getRTCP(): unaRTCPstack;
    //
    procedure dropLockedUser(var user: unaConfRTProomUser; roomID: tRoomID; removeFromRoom: bool);
    function roomIndexByUserID(userID: u_int32; out index: int; timeout: tTimeout = 50): bool;
    //
    function getUserAllow(userID: u_int32; isIn: bool): bool;
    procedure setUserAllow(userID: u_int32; isIn: bool; value: bool);
  protected
    {*
	Does nothing.

	@return 0
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
	@return True if server is active (listening on ports)
    }
    function isActive(): bool; override;
    {*
	Sends a command to client.

	@param addr Client address
	@param cmd Command to send
	@param idata Integer parameter
	@param dataBuf Optional data
	@param dataBufSize Size in bytes of data in dataBuf
    }
    procedure sendSrvCmd(addr: PSockAddrIn; const cmd: aString; idata: int32; dataBuf: pointer = nil; dataBufSize: unsigned = 0);
    {*
	Sends a packet to all users in a room.

	@param userID Original sender
	@param data Packet data
	@param len Packet length
	@param addr Source address of sender
	@param isRTCP True for RTCP packet, false for RTP
    }
    procedure transPacket(userID: u_int32; data: pointer; len: uint; const addr: sockaddr_in; isRTCP: bool);
    {*
	Virifies if user is granted to join the room.
    }
    function doUserVerify(userID: u_int32; roomID: tRoomID; const IP, port: string): HRESULT; virtual;
    {*
	Fired when new user is connected or old user is disconnected.
    }
    procedure doConn(userID: u_int32; roomID: tRoomID; const IP, port: string; isConnected: bool); virtual;
    {*
	Fired when new room is created or old room is removed.
    }
    procedure doRoomAddRemove(roomID: tRoomID; doAdd: bool); virtual;
    {*
	Closes the server.
    }
    procedure doClose(); override;
    {*
	Stratups the server.
    }
    function doOpen(): bool; override;
    {*
	Closes the room and disconnects all users joined to it.
    }
    function roomShutdown(room: unaConfRTProom; markClosed: bool = true): HRESULT; overload;
    {*
	Internal. Returns index.
    }
    function roomResolveName(const roomName: wString): int; virtual;
    {*
	Fired from context of idle thread.
    }
    procedure idle(); virtual;
  public
    {*
	Creates server component.
    }
    constructor Create(AOwner: TComponent); override;
    {*
	Destroys server component.
    }
    destructor Destroy(); override;
    //
    {*
	Adds new room.
    }
    function roomAdd(const roomName: string; roomID: tRoomID = -1; ro: bool = true): unaConfRTProom;
    {*
	Removes a room. All users from this room will be disconnected from server.
    }
    function roomDrop(roomID: tRoomID): HRESULT;
    {*
	Re-opens a room.
    }
    function roomStartup(roomID: tRoomID): HRESULT;
    {*
	Closes a room.
	All users from this room will be disconnected from server.
    }
    function roomShutdown(roomID: tRoomID): HRESULT; overload;
    {*
    }
    function roomByIDAcquire(roomID: tRoomID; ro: bool = true; timeout: tTimeout = 100): unaConfRTProom;
    {*
	Locks room by index.
    }
    function roomByIndexAcquire(index: int; ro: bool = true; timeout: tTimeout = 100): unaConfRTProom;
    {*
    }
    function roomByUserIDAcquire(userID: u_int32; ro: bool = true; timeout: tTimeout = 100): unaConfRTProom;
    {*
    }
    function roomGetNumUsers(roomID: tRoomID): int;
    {*
	Returns room name.

	@param roomID room ID
	@return room name
    }
    function roomGetName(roomID: tRoomID): wString;
    //
    {*
	Removes user from server, user is disconnected.
    }
    function userDrop(userID: u_int32): HRESULT; overload;
    {*
	Removes user from server, user is disconnected.
    }
    function userDrop(user: unaConfRTProomUser): HRESULT; overload;
    {*
	Acquires a lock on user object.
	If object is acquired, make sure to call .releaseRO()/releaseWO() when done with it.

	@return User object or nil if it cannot be acquired now.
    }
    function userByIDAcquire(userID: u_int32; ro: bool = true; timeout: tTimeout = 100): unaConfRTProomUser;
    {*
	Acquires a lock on user object.
	If object is acquired, make sure to call .releaseRO()/releaseWO() when done with it.

	@return User object or nil if it cannot be acquired now.
    }
    function userByIndexAcquire(index: int; ro: bool = true; timeout: tTimeout = 100): unaConfRTProomUser;
    {*
	Adds a new user and acquires a lock on user object.
	If object is acquired, make sure to call .releaseRO()/releaseWO() when done with it.

	@return User object or nil if it cannot be acquired now.
    }
    function userAddAcquire(userID: u_int32; ro: bool = true): unaConfRTProomUser;
    {*
	Returns user name.
    }
    function userGetName(userID: u_int32; out cname: wString): bool;
    //
    // -- public properties --
    //
    {*
	Number of audio/RTCP transmits being lost due to timeouts or other reasons
    }
    property lostTrans: int64 read f_lostTrans;
    {*
	Last error code.
    }
    property errorCode: int read getErrorCode;
    {*
	Server's master key. Not stored.
    }
    property masterKey: string write setMasterKey;
    {*
	Number of rooms.
    }
    property roomCount: int read getRoomCount2;
    {*
	Number of users (in all rooms).
    }
    property userCount: int read getUserCount2;
    {*
	Controls users I/O.
    }
    property userAllow[ID: u_int32; isIn: bool]: bool read getUserAllow write setUserAllow;
    {*
	Internal RTCP stack.
    }
    property rtcp: unaRTCPstack read getRTCP;
    {*
        Servers' SSRC
    }
    property SSRC: u_int32 read getSSRC;
  published
    {*
	Bind to this IP. Use 0.0.0.0 to bind to all interfaces.
    }
    property bind2ip: string read f_bind2ip write f_bind2ip;
    {*
	Listen on this UDP port. Port + 1 will be used for RTCP.
    }
    property port: string read f_port write f_port;
    {*
	Name of server.
    }
    property serverName: string read f_srvName write f_srvName;
    {*
	Automatically create rooms of users' request.
    }
    property autoCreateRooms: boolean read f_acr write f_acr default true;
    {*
	When set to true, causes server to remove rooms being abandoned for some time.
    }
    property autoRemoveRooms: boolean read f_arr write f_arr default true;
    {*
	When true one user can join one room at a time only.
	When false one user can participate in many rooms.
    }
    property userStrictlyInOneRoom: boolean read f_userSInOneRoom write f_userSInOneRoom default true;
    {*
	Fired when new used is connected.
    }
    property onUserConnect: evonUserConnect read f_onUC write f_onUC;
    {*
	Fired when new user is about to join the server
    }
    property onUserVerify: evonUserVerify read f_onUserVerify write f_onUserVerify;
    {*
	Fired when new room is added or old room is removed
    }
    property onRoomAddRemove: evonRoomAddRemove read f_onRoomAddRemove write f_onRoomAddRemove;
  end;


{*
	IDE Integration.
}
procedure Register();


implementation


uses
  unaUtils;


type
  //
  // --  --
  //
  mySrvTrans = class(unaRTPTransmitter)
  private
    f_srv: TunaConfRTPserver;
  protected
    procedure onPayload(addr: pSockAddrIn; hdr: prtp_hdr; data: pointer; len, packetSize: uint); override;
    procedure onRTCPPacket(ssrc: u_int32; addr: pSockAddrIn; hdr: prtcp_common_hdr; packetSize: uint); override;
    procedure notifyBye(si: prtp_site_info; soft: bool); override;
  end;


  {*
	Simple Idle thread.
  }
  myIdleThread = class(unaThread)
  private
    f_srv: TunaConfRTPserver;
  protected
    function execute(threadID: unsigned): int; override;
  public
    constructor create(srv: TunaConfRTPserver);
  end;


{ mySrvTrans }

// --  --
procedure mySrvTrans.notifyBye(si: prtp_site_info; soft: bool);
begin
  inherited;
  //
  // drop user due to RTCP timeout or BYE
  f_srv.userDrop(si.r_ssrc);
end;

// --  --
procedure mySrvTrans.onPayload(addr: PSockAddrIn; hdr: prtp_hdr; data: pointer; len, packetSize: uint);
var
  user: unaConfRTProomUser;
  ssrc: u_int32;
  isPing: bool;
  pt: int;
begin
  inherited;
  //
  pt := (hdr.r_M_PT and $7F);
  case (pt) of

    c_rtpPTa_CN,

    c_rtpPTs_conf_speex_8000,
    c_rtpPTs_conf_speex_16000,
    c_rtpPTs_conf_speex_32000,
    //
    c_rtpPTs_conf_mpeg_8000,
    c_rtpPTs_conf_mpeg_16000,
    c_rtpPTs_conf_mpeg_32000,
    //
    c_rtpPTs_conf_CELT_8000,
    c_rtpPTs_conf_CELT_16000,
    c_rtpPTs_conf_CELT_24000,
    //
    c_rtpPTs_conf_G7221_8000,
    c_rtpPTs_conf_G7221_16000,
    c_rtpPTs_conf_G7221_32000,
    //
    c_rtpPTs_conf_uLaw_8000,
    c_rtpPTs_conf_uLaw_16000,
    c_rtpPTs_conf_uLaw_32000,
    //
    c_rtpPTs_conf_PCM_8000,
    c_rtpPTs_conf_PCM_16000,
    c_rtpPTs_conf_PCM_32000,
    //
    c_rtpPTs_conf_ALaw_8000,
    c_rtpPTs_conf_ALaw_16000,
    c_rtpPTs_conf_ALaw_32000: begin
      //
      // audio stream
      try
	isPing := (c_rtpPTa_CN = pt);
	ssrc := swap32u(hdr.r_ssrc_NO);
	user := f_srv.userByIDAcquire(ssrc, true, 10);
	if (nil <> user) then try
	  //
	  if (not isPing) then
	    user.f_lastAudioCodec := pt;
	  //
	  if (not user.f_addrRTPValid or isPing) then begin
	    //
	    user.f_addrRTP := addr^;
	    user.f_addrRTPValid := true;
	  end;
	finally
	  user.releaseRO();
	end;
	//
	if (not isPing) then
	  f_srv.transPacket(swap32u(hdr.r_ssrc_NO), hdr, packetSize, addr^, false);
	//
      except
      end;
    end;

  end;
end;

// --  --
procedure mySrvTrans.onRTCPPacket(ssrc: u_int32; addr: pSockAddrIn; hdr: prtcp_common_hdr; packetSize: uint);
var
  len: uint;
  data: pointer;
  cmd: aString;
  user: unaConfRTProomUser;
begin
  inherited;
  //
  try
    user := f_srv.userByIDAcquire(ssrc, false, 10);
    if (nil <> user) then try
      //
      //  allows user to publish his/her new RTCP addr by sending an APP request
      //  (will also render RTP address invalid in case of new RTCP address)
      if (not user.f_addrRTCPValid or (RTCP_APP = hdr.r_pt)) then begin
	//
	if (not sameAddr(user.f_addrRTCP, addr^)) then
	  user.f_addrRTPValid := false; // this will also ensure RTP address update in case of address change
	//
	user.f_addrRTCP := addr^;
	user.f_addrRTCPValid := true;
      end;
      //
      user.f_RTCPtm := timeMarkU();	// mark when last RTCP packet was received from user
    finally
      user.releaseWO();
    end;
    //
    repeat
      //
      case (hdr.r_pt) of

	RTCP_APP: begin
	  //
	  data := hdr;
	  inc(unsigned(data), 8); // skip length and SSRC
	  setLength(cmd, 4);
	  move(data^, cmd[1], 4);
	  cmd := upCase(cmd);
	  inc(unsigned(data), 4); // skip name
	  //
	  if (c_rtcp_appCmd_RTT = cmd) then
	    // route RTT packet to other users in room
	    f_srv.transPacket(ssrc, hdr, packetSize, addr^, true)
	  else
	    if ( (packetSize >= sizeof(rtcp_common_hdr) + 8 + sizeof(unaConfRTPcmd) + uint(punaConfRTPcmd(data).r_dataBufSz)) ) then try
	      //
	      f_srv.handleClnCmd(ssrc, addr, cmd, data);
	    except
	    end;
	end;

	RTCP_SR,
	RTCP_RR,
	RTCP_SDES,
	RTCP_BYE: begin
	  // route the packet to other users
	  f_srv.transPacket(ssrc, hdr, packetSize, addr^, true);
	end;

      end; // case
      //
      len := rtpLength2bytes(hdr.r_length_NO_);
      if (len < packetSize) then begin
	//
	dec(packetSize, len);
	hdr := prtcp_common_hdr(@pArray(hdr)[len]);
      end
      else
	break;
      //
    until (false);
    //
  except
  end;
end;



{ unaConfRTProomList }

// --  --
function unaConfRTProomList.getId(item: pointer): int64;
begin
  if (nil <> item) then
    result := unaConfRTProom(item).roomID
  else
    result := -1;
end;


{ unaConfRTPUserList }

// --  --
function unaConfRTProomUserList.getId(item: pointer): int64;
begin
  if (nil <> item) then
    result := unaConfRTProomUser(item).f_userID
  else
    result := -1;
end;


{ unaConfRTProom }

// --  --
function unaConfRTProom.addUser(userID: u_int32): int;
begin
  result := f_seats.indexOf(userID);
  if (0 > result) then
    result := f_seats.add(userID);
  //
{$IFDEF LOG_unaConfRTPserver_INFOS }
  logMessage(':RTPSRV: room.addUser(userid=' + int2str(userID) + ')');
{$ENDIF LOG_unaConfRTPserver_INFOS }
end;

// --  --
procedure unaConfRTProom.announce(const msg: wString);
var
  u_index: int;
  user: unaConfRTProomUser;
  data: aString;
begin
  data := UTF162UTF8(msg);
  if (0 < length(data)) then begin
    //
    for u_index := 0 to userCount - 1 do begin
      //
      user := userByIndexAcquire(u_index);
      if (nil <> user) then try
	//
	f_srv.sendSrvCmd(@user.f_addrRTCP, c_confSrvCmd_announce, f_roomID, @data[1], length(data));
      finally
	user.releaseRO();
      end;
    end;
  end;
end;

// --  --
constructor unaConfRTProom.create(srv: TunaConfRTPserver; const roomName: wString; roomID: tRoomID);
begin
  f_roomID := roomID;
  f_roomName := roomName;
  //
  f_srv := srv;
  //
  f_seats := unaList.create(uldt_int32, true);
  //
  inherited create();
  //
{$IFDEF LOG_unaConfRTPserver_INFOS }
  logMessage(':RTPSRV: room.create(name=' + roomname + '; id=' + int2str(roomID) + ')');
{$ENDIF LOG_unaConfRTPserver_INFOS }
end;

// --  --
destructor unaConfRTProom.Destroy();
begin
  inherited;
  //
  freeAndNil(f_seats);
  //
{$IFDEF LOG_unaConfRTPserver_INFOS }
  logMessage(':RTPSRV: room.Destroy(roomID=' + int2str(roomID) + ')');
{$ENDIF LOG_unaConfRTPserver_INFOS }
end;

// --  --
function unaConfRTProom.dropUser(userID: u_int32): bool;
begin
  result := false;
  if (acquire(false, 200, false {$IFDEF DEBUG }, '.dropUser(userID=' + int2str(userID) + ')' {$ENDIF DEBUG })) then try
    //
    result := f_seats.removeItem(userID);
    //
    if (1 > userCount) then
      f_abandonedTM := timeMarkU();
  finally
    releaseWO();
  end;
  //
{$IFDEF LOG_unaConfRTPserver_INFOS }
  logMessage(':RTPSRV: room.dropUser(userID=' + int2str(userID) + ')');
{$ENDIF LOG_unaConfRTPserver_INFOS }
end;

// --  --
function unaConfRTProom.getCC(): int;
begin
  result := f_seats.count;
end;

// --  --
function unaConfRTProom.hasUser(userID: u_int32): bool;
begin
  result := (0 <= f_seats.indexOf(userID));
end;

// --  --
procedure unaConfRTProom.updateBw(isIn: bool; delta: int; cln: unaConfRTProomUser);
begin
  if (0 = f_bwTM) then
    f_bwTM := timeMarkU();
  //
  if (isIn) then
    inc(f_bwInDelta, delta)
  else
    inc(f_bwOutDelta, delta);
  //
{$IFDEF VCX_DEMO }
  inc(f_srv.f_totalTrans, delta and 1);
{$ENDIF VCX_DEMO }
  //
  if (2000 < timeElapsed64U(f_bwTM)) then begin
    //
    f_bwIn := f_bwInDelta shl 2;
    f_bwOut := f_bwOutDelta shl 2;
    //
    f_bwTM := timeMarkU();
    f_bwInDelta := 0;
    f_bwOutDelta := 0;
  end;
  //
  if ((nil <> cln) and acquire32(cln.f_bwAcq, 10)) then try
    //
    if (0 = cln.f_bwTM) then
      cln.f_bwTM := timeMarkU();
    //
    if (isIn) then
      inc(cln.f_bwInDelta, delta)
    else
      inc(cln.f_bwOutDelta, delta);
    //
    if (2000 < timeElapsed64U(cln.f_bwTM)) then begin
      //
      cln.f_bwIn := cln.f_bwInDelta shl 2;
      cln.f_bwOut := cln.f_bwOutDelta shl 2;
      //
      cln.f_bwTM := timeMarkU();
      cln.f_bwInDelta := 0;
      cln.f_bwOutDelta := 0;
    end;
  finally
    release32(cln.f_bwAcq);
  end;
end;

// --  --
function unaConfRTProom.userByIndexAcquire(index: int; ro: bool; timeout: tTimeout): unaConfRTProomUser;
begin
  result := nil;
  if (lockNonEmptyList_r(f_seats, true, timeout {$IFDEF DEBUG }, '.userByIndexAcquire(index=' + int2str(index) + ')'{$ENDIF DEBUG })) then try
    //
    result := f_srv.userByIDAcquire(u_int32(f_seats[index]), ro, timeout);
  finally
    unlockListRO(f_seats);
  end;
end;


{ myIdleThread }

// --  --
constructor myIdleThread.create(srv: TunaConfRTPserver);
begin
  f_srv := srv;
  //
  inherited create();
end;

// --  --
function myIdleThread.execute(threadID: unsigned): int;
begin
  while (not shouldStop) do begin
    //
    try
      f_srv.idle();
    except
    end;
    //
    sleepThread(100);
  end;
  //
  result := 0;
end;


{ unaConfRTProomUser }

// --  --
function unaConfRTProomUser.copyRTCPInfo(var info: rtp_site_info): bool;
begin
  result := false;
  if (acquire(true, 100, false {$IFDEF DEBUG }, '.copyRTCPInfo()' {$ENDIF DEBUG })) then try
    //
    if ( (nil <> f_srv.f_trans) and (nil <> f_srv.f_trans.rtcp) ) then
      result := f_srv.f_trans.rtcp.copyMember(userID, info);
  finally
    releaseRO();
  end;
end;

// --  --
constructor unaConfRTProomUser.create(srv: TunaConfRTPserver; userID: u_int32);
begin
  f_userID := userID;
  f_srv := srv;
  //
  f_allowIN := true;
  f_allowOUT := true;
  //
  inherited create();
  //
{$IFDEF LOG_unaConfRTPserver_INFOS }
  logMessage(':RTPSRV: user.create(userID=' + int2str(userID) + ')');
{$ENDIF LOG_unaConfRTPserver_INFOS }
end;

// --  --
destructor unaConfRTProomUser.Destroy();
begin
  inherited;
  //
{$IFDEF LOG_unaConfRTPserver_INFOS }
  logMessage(':RTPSRV: user.Destroy(userID=' + int2str(userID) + ')');
{$ENDIF LOG_unaConfRTPserver_INFOS }
end;


{ TunaConfRTPserver }

// --  --
procedure TunaConfRTPserver.addSynchEvent(etype: int32; userID: u_int32; roomID: tRoomID; addr: psockaddrin);
var
  event: punaConfRTPsynchEvent;
begin
  event := malloc(sizeof(event^));
  //
  event.r_type := etype;
  event.r_userID := userID;
  event.r_roomID := roomID;
  if (nil <> addr) then
    event.r_addr := addr^;
  //
  f_syncEvents.add(event);
end;

// --  --
constructor TunaConfRTPserver.Create(AOwner: TComponent);
begin
  port := '5004';
  bind2ip := '0.0.0.0';
  //
  autoCreateRooms := true;
  autoRemoveRooms := true;
  //
  f_rooms2 := unaConfRTProomList.create(uldt_obj, true);
  f_rooms2.timeout := 400;
  //
  f_users2 := unaConfRTProomUserList.create(uldt_obj, true);
  f_users2.timeout := 200;
  //
  f_deadUserID := unaList.create(uldt_int32);
  //
  f_syncEvents := unaRecordList.create();
  f_idleThread := myIdleThread.create(self);
  f_randThread := unaRandomGenThread.create();
  f_roomNames := unaWideStringList.create();
  f_srvLock := unaObject.create();
  //
  userStrictlyInOneRoom := true;
  //
  inherited create(AOwner);
  //
{$IFDEF LOG_unaConfRTPserver_INFOS }
  logMessage(':RTPSRV: server.create()');
{$ENDIF LOG_unaConfRTPserver_INFOS }
end;

// --  --
destructor TunaConfRTPserver.Destroy();
begin
  if (f_srvLock.acquire(false, 3000, false {$IFDEF DEBUG }, '.Destroy()' {$ENDIF DEBUG })) then try
    //
    close();
    //
    inherited;
    //
    freeAndNil(f_idleThread);
    freeAndNil(f_trans);
    freeAndNil(f_rooms2);
    freeAndNil(f_users2);
    freeAndNil(f_deadUserID);
    freeAndNil(f_syncEvents);
    freeAndNil(f_randThread);
    freeAndNil(f_roomNames);
    freeAndNil(f_srvLock);
  finally
    f_srvLock.releaseWO();
  end;
  //
{$IFDEF LOG_unaConfRTPserver_INFOS }
  logMessage(':RTPSRV: server.Destroy()');
{$ENDIF LOG_unaConfRTPserver_INFOS }
end;

// --  --
procedure TunaConfRTPserver.doClose();
var
  i: int;
begin
  if (f_srvLock.acquire(false, 3000, false {$IFDEF DEBUG }, '.doClose()' {$ENDIF DEBUG })) then try
    //
    f_idleThread.askStop();
    //
    // shutdown all rooms
    if (lockNonEmptyList_r(f_rooms2, false, 700 {$IFDEF DEBUG }, '.doClose()'{$ENDIF DEBUG })) then try
      //
      for i := 0 to roomCount - 1 do
	roomShutdown(unaConfRTProom(f_rooms2[i]), false);
    finally
      f_rooms2.releaseWO();
    end;
    //
    inherited doClose();
    //
    freeAndNil(f_trans);
    //
    f_idleThread.stop();
  finally
    f_srvLock.releaseWO();
  end;
  //
{$IFDEF LOG_unaConfRTPserver_INFOS }
  logMessage(':RTPSRV: server.doClose()');
{$ENDIF LOG_unaConfRTPserver_INFOS }
end;

// --  --
procedure TunaConfRTPserver.doConn(userID: u_int32; roomID: tRoomID; const IP, port: string; isConnected: bool);
begin
  if (assigned(f_onUC)) then
    f_onUC(self, int32(userID), roomID, IP, port, isConnected);
end;

// --  --
function TunaConfRTPserver.doOpen(): bool;
var
  i: integer;
  bindAddr: TSockAddrIn;
begin
  result := false;
  //
  if (f_srvLock.acquire(false, 1200, false {$IFDEF DEBUG }, '.doOpen()' {$ENDIF DEBUG })) then try
    //
    if (not active) then begin
      //
      result := inherited doOpen();
      if (result) then begin
	//
	freeAndNil(f_trans); // just in case
	//
{$IFDEF VCX_DEMO }
	f_totalTrans := random(100);
{$ENDIF VCX_DEMO }
	//
	f_deadUserID.clear();
	//
	makeaddr(bind2ip, port, bindAddr);
	f_trans := mySrvTrans.create(bindAddr, 0, false, false);
	f_trans.receiver.userName := serverName;
	//
	mySrvTrans(f_trans).f_srv := self;
	f_trans.rtpPing := true;	// let server update clients' RTP holes
	//
	if (f_trans.open(true)) then
	  f_idleThread.start();
	//
	if (active) then begin
	  //
	  for i := 0 to sizeof(f_sessionKey) - 1 do
	    f_sessionKey[i] := (f_randThread.random($FFFFFFFF, 100) and $FF);
	end;
      end;
    end;
    //
    result := active;
    //
  finally
    f_srvLock.releaseWO();
  end;
  //
{$IFDEF LOG_unaConfRTPserver_INFOS }
  logMessage(':RTPSRV: server.doOpen()');
{$ENDIF LOG_unaConfRTPserver_INFOS }
end;

// --  --
function TunaConfRTPserver.doRead(data: pointer; len: uint): uint;
begin
  result := 0;
end;

// --  --
procedure TunaConfRTPserver.doRoomAddRemove(roomID: tRoomID; doAdd: bool);
begin
  if (assigned(f_onRoomAddRemove)) then
    f_onRoomAddRemove(self, roomID, doAdd);
end;

// --  --
function TunaConfRTPserver.doUserVerify(userID: u_int32; roomID: tRoomID; const IP, port: string): HRESULT;
var
  ok: bool;
begin
  ok := true;
  if (assigned(f_onUserVerify)) then
    f_onUserVerify(self, int32(userID), roomID, IP, port, ok);
  //
  result := choice(ok, S_OK, E_FAIL);
end;

// --  --
function TunaConfRTPserver.doWrite(data: pointer; len: uint; provider: pointer): uint;
begin
  result := 0;
end;

// --  --
procedure TunaConfRTPserver.dropLockedUser(var user: unaConfRTProomUser; roomID: tRoomID; removeFromRoom: bool);
var
  roomLeave: unaConfRTProom;
begin
  if (user.f_verified and (0 <= roomID) and removeFromRoom) then begin
    //
    roomLeave := roomByIDAcquire(roomID, false, 100);
    if (nil <> roomLeave) then try
      //
      roomLeave.dropUser(user.userID);
    finally
      roomLeave.releaseWO();
    end;
  end;
  //
  sendSrvCmd(@user.f_addrRTCP, c_confSrvCmd_drop, c_confSrvError_userKicked);
  //
  // user got disconnected
  if (user.f_verified) then
    addSynchEvent(1, user.userID, roomID, @user.f_addrRTCP);
  //
{$IFDEF LOG_unaConfRTPserver_INFOS }
  logMessage(':RTPSRV: server.dropLockedUser(userID=' + int2str(user.userID) + '; roomID=' + int2str(roomID) + '; rfr=' + bool2strStr(removeFromRoom) + ')');
{$ENDIF LOG_unaConfRTPserver_INFOS }
  //
  f_users2.removeItem(user);
  //
  user := nil;
end;

// --  --
function TunaConfRTPserver.getAvailableDataLen(index: integer): uint;
begin
  result := 0;
end;

// --  --
function TunaConfRTPserver.getUserAllow(userID: u_int32; isIn: bool): bool;
var
  user: unaConfRTProomUser;
begin
  user := userByIDAcquire(userID);
  if (nil <> user) then try
    //
    if (isIn) then
      result := user.f_allowIN
    else
      result := user.f_allowOUT;
    //
  finally
    user.releaseRO();
  end
  else
    result := true;
end;

// --  --
function TunaConfRTPserver.getUserCount2(): int;
begin
  result := f_users2.count;
end;

// --  --
function TunaConfRTPserver.getErrorCode(): int;
begin
  result := f_trans.receiver.socketError;
end;

// --  --
function TunaConfRTPserver.getRoomCount2(): int;
begin
  result := f_rooms2.count;
end;

// --  --
function TunaConfRTPserver.getRTCP(): unaRTCPstack;
begin
  if (nil <> f_trans) then
    result := f_trans.rtcp
  else
    result := nil;
end;

// --  --
function TunaConfRTPserver.getSSRC(): u_int32;
begin
  if (nil <> f_trans) then
    result := f_trans._SSRC
  else
    result := 0;
end;

// --  --
procedure TunaConfRTPserver.handleClnCmd(userID: u_int32; addr: PSockAddrIn; const cmd: aString; cmdData: punaConfRTPcmd);
var
  room: unaConfRTProom;
  roomOld: unaConfRTProom;
  cln: unaConfRTProomUser;
  key: unaConfRTPkey;
  encIData: uint32;
  //
  roomNameA: aString;
  //
  roomID: tRoomID;
  {$IFDEF DEBUG_LOST_FIRST_REPLY }
  justAdded: bool;
  {$ENDIF DEBUG_LOST_FIRST_REPLY }
begin
  if (f_srvLock.acquire(true, 20, false {$IFDEF DEBUG }, '.handleClnCmd(userID=' + int2str(userID) + ')' {$ENDIF DEBUG })) then try
    //
  {$IFDEF LOG_unaConfRTPserver_INFOS }
    logMessage(':RTPSRV: server.handleClnCmd(userID=' + int2str(userID) + '; cmd=' + string(cmd) + ')');
  {$ENDIF LOG_unaConfRTPserver_INFOS }
    //
    case crc32(cmd) of

      c_confClnCmd_join_crc: begin
	//
	if (0 < cmdData.r_dataBufSz) then begin
	  //
	  setLength(f_roomNameA, cmdData.r_dataBufSz);
	  move(cmdData.r_dataBuf, f_roomNameA[1], cmdData.r_dataBufSz);
	  //
	  f_roomNameW := utf82utf16(f_roomNameA);
	  roomID := roomResolveName(f_roomNameW);
	end
	else begin
	  //
	  f_roomNameW := '';
	  roomID := cmdData.r_i_data;
	end;
	//
	// user want to join the room
	if (SUCCEEDED(doUserVerify( userID, roomID, ipN2str(TIPv4N(addr.sin_addr.S_addr)), int2str(ntohs(addr.sin_port)) ))) then begin
	  //
	  room := roomByIDAcquire(roomID, false, 200);
	  if ((nil = room) and autoCreateRooms) then begin
	    //
	    // add new room
	    room := roomAdd(f_roomNameW, roomID, false);
	    if (nil <> room) then
	      // new room
	      addSynchEvent(2, userID, roomID, nil);
	  end;
	  //
	  if (nil <> room) then try
	    //
	    if (c_max_users_per_room > room.userCount) then begin
	      //
	      if (not room.closed) then begin
		//
		key := f_sessionKey;
		try
		  //
		  // encode SK with masterkey
		  encode(@key, sizeof(unaConfRTPkey), @f_masterKey, sizeof(unaConfRTPkey));
		  //
		{$IFDEF DEBUG_LOST_FIRST_REPLY }
		  justAdded := false;
		{$ENDIF DEBUG_LOST_FIRST_REPLY }
		  //
		  cln := userByIDAcquire(userID, false, 10);
		  if (nil = cln) and (0 > f_users2.indexOfId(userID)) then begin
		    //
		    cln := userAddAcquire(userID, false);
		    //
		{$IFDEF DEBUG_LOST_FIRST_REPLY }
		    justAdded := true;
		{$ENDIF DEBUG_LOST_FIRST_REPLY }
		  end;
		  //
		  if (nil <> cln) then try
		    //
		    // mark last RTCP packet time
		    cln.f_RTCPtm := timeMarkU();
		    //
		    // check if we need to drop user from other room(s)
		    //
		    if (userStrictlyInOneRoom) then begin
		      //
		      repeat
			//
			roomOld := roomByUserIDAcquire(userID, false, 100);
			if (nil <> roomOld) then try
			  //
			  // remove user from that room
			  roomOld.dropUser(userID);
			finally
			  roomOld.releaseWO();
			end
			else
			  break;
			//
		      until (nil = roomOld);
		    end;
		    //
		    // put user in new room
		    //
		    room.addUser(userID);
		    //
		    // if user was never verified, send SK
                    //
		    if (not cln.verified) then begin
		      //
		      cln.f_verified := false;
		      cln.f_mustReplyWith := f_randThread.random($FFFFFFFF, 1);	// no much time to think now,
		      //
		      encIData := cln.f_mustReplyWith;
		      //
		      // also, encode users's "must reply with" data with SK
		      encode(@encIData, 4, @f_sessionKey, sizeof(unaConfRTPkey));
		      //
		  {$IFDEF DEBUG_LOST_FIRST_REPLY }
		      if (not justAdded) then
		  {$ENDIF DEBUG_LOST_FIRST_REPLY }
			sendSrvCmd(addr, c_confSrvCmd_joinOK, int32(encIData), @key, sizeof(unaConfRTPkey));	// send OK and encoded session key
		      //
		    end;
		    //
		  finally
		    cln.releaseWO();
		  end
		  else
		    sendSrvCmd(addr, c_confSrvCmd_FAIL, c_confSrvError_pleaseTryAgain);	// try again
		  //
		except
		end;
	      end
	      else
		sendSrvCmd(addr, c_confSrvCmd_FAIL, c_confSrvError_roomClosed);	// room is closed
	      //
	    end
	    else
	      sendSrvCmd(addr, c_confSrvCmd_FAIL, c_confSrvError_outOfSeats);	// out of seats in this room
	    //
	  finally
	    room.releaseWO();
	  end
	  else
	    sendSrvCmd(addr, c_confSrvCmd_FAIL, c_confSrvError_roomDoesNotExist);	// no room? hm..
	  //
	end
	else
	  sendSrvCmd(addr, c_confSrvCmd_FAIL, c_confSrvError_accessDenied);	// has no access
      end;

      c_confClnCmd_joinHasKey_crc: begin
	//
	//  user want to join the room (idata = roomID)
	//  and now we have to verify user's reply
	//
	room := roomByUserIDAcquire(userID);		// get last room where user was joined
	if (nil <> room) then try
	  //
	  if (not room.closed) then try
	    //
	    cln := userByIDAcquire(userID);
	    if (nil <> cln) then try
	      //
	      if (sameAddr(cln.f_addrRTCP, addr^)) then begin
		//
		if (4 <= cmdData.r_dataBufSz) then begin
		  //
		  cln.f_RTCPtm := timeMarkU();
		  //
		  move(cmdData.r_dataBuf, encIData, 4);
		  if (cln.f_mustReplyWith = encIData) then begin
		    //
		    // user connected
		    cln.f_verified := true;
		    //
		    addSynchEvent(0, userID, room.roomID, addr);
		    //
		    sendSrvCmd(addr, c_confSrvCmd_joinOK, room.userCount);	// send OK and number of users in the room
		  end
		  else
		    sendSrvCmd(addr, c_confSrvCmd_FAIL, c_confSrvError_invalidPassword);	// invalid password
		  //
		end
		else
		  sendSrvCmd(addr, c_confSrvCmd_FAIL, c_confSrvError_malformedData);	// malformed data from client
		//
	      end
	      else
		sendSrvCmd(addr, c_confSrvCmd_FAIL, c_confSrvError_suchUserFromWrongAddr);	// hm, address was lost in transit
	      //
	    finally
	      cln.releaseRO();
	    end
	    else begin
	      //
	      if (0 > f_users2.indexOfId(userID)) then
		sendSrvCmd(addr, c_confSrvCmd_FAIL, c_confSrvError_noSuchUserID, @userID, sizeof(u_int32))	// hm, user was lost in transit
	      else
		sendSrvCmd(addr, c_confSrvCmd_FAIL, c_confSrvError_userObjLocked);	// user object is locked, try again later
	    end;
	    //
	  except
	    // ignore exceptions
	  end
	  else
	    sendSrvCmd(addr, c_confSrvCmd_FAIL, c_confSrvError_roomClosed);	// room is closed for some reason
	  //
	finally
	  room.releaseRO();
	end
	else
	  sendSrvCmd(addr, c_confSrvCmd_FAIL, c_confSrvError_roomDoesNotExist);	// no room? hm..
	//
      end;

      c_confClnCmd_leave_crc: begin
        //
	if (0 < cmdData.r_dataBufSz) then begin
	  //
	  setLength(roomNameA, cmdData.r_dataBufSz);
	  move(cmdData.r_dataBuf, roomNameA[1], cmdData.r_dataBufSz);
	  //
	  roomID := roomResolveName(utf82utf16(roomNameA));
          room := roomByIDAcquire(roomID);
          if (nil <> room) then begin
            //
            room.dropUser(userID);
            sendSrvCmd(addr, c_confSrvCmd_LEAVE, roomID);
          end;
	end;
      end;

    end;
  finally
    f_srvLock.releaseRO();
  end;
end;

// --  --
procedure TunaConfRTPserver.idle();
var
  i, climit: int;
  room: unaConfRTProom;
  roomIndex: int;
  user: unaConfRTProomUser;
  userID: u_int32;
  tm: uint64;
  event: punaConfRTPsynchEvent;
begin
  // mark entrance time
  tm := timeMarkU();
  //
  // 1) check rooms/users timeout
  //
  if (active) then begin
    //
    if (autoRemoveRooms) then begin
      //
      inc(f_idleRoomIndex);
      if (f_idleRoomIndex >= f_rooms2.count) then
	f_idleRoomIndex := 0;
      //
      if (f_idleRoomIndex < f_rooms2.count) then
	room := roomByIndexAcquire(f_idleRoomIndex, false, 10)
      else
	room := nil;
      //
      if (nil <> room) then try
	//
	// check fantom clients (a client in a room without RTCP)
	i := 0;
	while (i < room.userCount) do try
	  //
	  if (60 < timeElapsed64U(tm)) then
	    break;
	  //
	  user := room.userByIndexAcquire(i, false, 10);
	  if (nil <> user) then try
	    //
	    room.updateBw(true, 0, user);
	    room.updateBw(false, 0, user);
	    //
	    if (60000 < timeElapsed64U(user.f_RTCPtm)) then begin
	      //
	    {$IFDEF LOG_unaConfRTPserver_INFOS }
	      logMessage(':RTPSRV: server.idle(fantom userID=' + int2str(user.userID) + ' will be dropped from roomID=' + int2str(room.roomID) + ')');
	    {$ENDIF LOG_unaConfRTPserver_INFOS }
	      //
	      dropLockedUser(user, room.roomID, true);
	      break;
	    end
	    else begin
	      //
	      // user are required to send pings anyways (so NAT ports will not fade out)
	      // so there is no need to send NPNG any more
	      //
	      //if ( (nil <> f_trans.rtcp) and not user.f_addrRTPValid and user.f_verified and user.f_addrRTCPValid ) then
	      //  f_trans.rtcp.sendAPPto(@user.f_addrRTCP, 0, 'NPNG');
	    end;
	  finally
	    user.releaseWO();
	  end;
	finally
	  inc(i);
	end;
	//
	// update room's bw
	room.updateBw(true, 0, nil);
	room.updateBw(false, 0, nil);
	//
	// see if room is abandoned for some time
	if (1 > room.userCount) then begin
	  //
	  if (0 = room.f_abandonedTM) then
	    room.f_abandonedTM := timeMarkU();
	  //
	  if (42000 < timeElapsed64U(room.f_abandonedTM)) then begin
	    //
	  {$IFDEF LOG_unaConfRTPserver_INFOS }
	    logMessage(':RTPSRV: server.idle(abandoned room will be removed, roomID=' + int2str(room.roomID) + ')');
	  {$ENDIF LOG_unaConfRTPserver_INFOS }
	    //
	    // room closed
	    addSynchEvent(3, 0, room.f_roomID, nil);
	    roomDrop(room.f_roomID);
	    room := nil;
	  end;
	end
	else begin
	  //
	  // check if no seat is taken by a ghost
	  for i := 0 to room.f_seats.count - 1 do begin
	    //
	    userID := u_int32(room.f_seats.get(i));
	    if (0 > f_users2.indexOfId(userID)) then begin
	      //
	      Sleep(10);  // FIXME!!
	      if (0 > f_users2.indexOfId(userID)) then begin	// just make sure there is really no such user
								// indexOf() may fail due to lock
		//
	      {$IFDEF LOG_unaConfRTPserver_INFOS }
		logMessage(':RTPSRV: server.idle(ghost user will be removed, userID=' + int2str(userID) + ')');
	      {$ENDIF LOG_unaConfRTPserver_INFOS }
		//
		room.dropUser(userID);
	      end;
	    end;
	    //
	  end;
	end;
	//
      finally
	room.releaseWO();
      end;
    end;
    //
    // 2) check sync events
    climit := 12;
    while (not f_idleThread.shouldStop and (0 < f_syncEvents.count) and (0 <= climit)) do begin
      //
      if (60 < timeElapsed64U(tm)) then
	break;
      //
      event := f_syncEvents[0];
      if (nil <> event) then begin
	//
	case (event.r_type) of

	  0, 1: doConn(event.r_userID, event.r_roomID, ipN2str(TIPv4N(event.r_addr.sin_addr.S_addr)), int2str(ntohs(event.r_addr.sin_port)), 0 = event.r_type);
	  2, 3: doRoomAddRemove(event.r_roomID, 2 = event.r_type);

	end;
      end;
      //
      f_syncEvents.removeFromEdge();
      dec(climit);
    end;
    //
    // 3) check dead clients
    if (lockNonEmptyList_r(f_deadUserID, false, 10 {$IFDEF DEBUG }, '.idle(_check_dead_clients_)'{$ENDIF DEBUG })) then try
      //
      i := random(f_deadUserID.count);
      userID := u_int32(f_deadUserID.get(i));
      if (0 <= f_users2.indexOfId(userID)) then begin
	//
	user := userByIDAcquire(userID, false, 10);
	if (nil <> user) then try
	  //
	{$IFDEF LOG_unaConfRTPserver_INFOS }
	  logMessage(':RTPSRV: server.idle(dead user will be removed, userID=' + int2str(user.userID) + ')');
	{$ENDIF LOG_unaConfRTPserver_INFOS }
	  if (not roomIndexByUserID(userID, roomIndex)) then
	    roomIndex := -1;
	  //
	  dropLockedUser(user, roomIndex, (0 <= roomIndex));	//
	  //
	  f_deadUserID.removeByIndex(i);	// user was released, remove ID
	finally
	  user.releaseWO();
	end
      end
      else
	f_deadUserID.removeFromEdge(true);	// no such ID in users list, remove the ID
      //
    finally
      unlockListWO(f_deadUserID);
    end;
    //
    if (60 < timeElapsed64U(tm)) then
      exit;
    //
    // 4) check some roomless clients
    //
    climit := 12;
    repeat
      //
      if (f_roomlessUserIndex >= f_users2.count) then
	f_roomlessUserIndex := f_users2.count - 1;
      //
      if (0 <= f_roomlessUserIndex) then begin
	//
	user := userByIndexAcquire(f_roomlessUserIndex, false, 90 - timeElapsed64U(tm));
	if (nil <> user) then try
	  //
	  if (roomIndexByUserID(user.userID, roomIndex) and (0 > roomIndex)) then begin
	    //
	  {$IFDEF LOG_unaConfRTPserver_INFOS }
	    logMessage(':RTPSRV: server.idle(roomless user will be removed, userID=' + int2str(user.userID) + ')');
	  {$ENDIF LOG_unaConfRTPserver_INFOS }
	    //
	    dropLockedUser(user, -1, false);
	  end;
	  //
	finally
	  user.releaseWO()
	end;
      end;
      //
      inc(f_roomlessUserIndex );
      if (f_roomlessUserIndex >= f_users2.count) then begin
	//
	f_roomlessUserIndex := 0;
	break; // wrapped around, probably there are not so many user, leave loop now
      end;
      //
      dec(climit);
      //
    until (1 > climit);
  end
  else
    f_idleThread.askStop();
end;

// --  --
function TunaConfRTPserver.isActive(): bool;
begin
  if (nil <> f_trans) then
    result := f_trans.active
  else
    result := false;
end;

// --  --
function TunaConfRTPserver.roomAdd(const roomName: string; roomID: tRoomID; ro: bool): unaConfRTProom;
var
  index: int;
begin
  result := nil;
  if (f_rooms2.acquire(false, 600, false {$IFDEF DEBUG }, '.roomAdd(roomName=' + roomName + ')' {$ENDIF DEBUG })) then try
    //
    if (0 <= roomID) then
      index := f_rooms2.indexOfId(roomID)
    else begin
      //
      roomID := roomResolveName(roomName);
      index := f_rooms2.indexOfId(roomID);
    end;
    //
    if (0 > index) then begin
      //
      if (f_rooms2.count < c_max_rooms) then begin
	//
	result := unaConfRTProom.create(self, roomName, roomID);
	f_rooms2.add(result);
      end;
    end
    else
      result := f_rooms2[index];
    //
    if (nil <> result) then
      result.acquire(ro, 200, false {$IFDEF DEBUG }, 'in roomAdd()' {$ENDIF DEBUG });
    //
  finally
    f_rooms2.releaseWO();
  end;
  //
{$IFDEF LOG_unaConfRTPserver_INFOS }
  logMessage(':RTPSRV: server.roomAdd(roomname=' + roomName + ')');
{$ENDIF LOG_unaConfRTPserver_INFOS }
end;

// --  --
function TunaConfRTPserver.roomByIDAcquire(roomID: tRoomID; ro: bool; timeout: tTimeout): unaConfRTProom;
begin
  result := nil;
  if (lockNonEmptyList_r(f_rooms2, true, timeout {$IFDEF DEBUG }, '.roomByIDAcquire(id=' + int2str(roomID) + ')'{$ENDIF DEBUG })) then try
    //
    result := unaConfRTPRoom(_acr(f_rooms2.itemById(roomID), ro, timeout {$IFDEF DEBUG }, '.roomByIDAcquire(roomID=' + int2str(roomID) + ')' {$ENDIF DEBUG }));
  finally
    unlockListRO(f_rooms2);
  end;
end;

// --  --
function TunaConfRTPserver.roomByUserIDAcquire(userID: u_int32; ro: bool; timeout: tTimeout): unaConfRTProom;
var
  r: int;
  room: unaConfRTProom;
begin
  result := nil;
  //
  if (lockNonEmptyList_r(f_rooms2, true, timeout {$IFDEF DEBUG }, '.roomByUserIdAcquire(userid=' + int2str(userID) + ')'{$ENDIF DEBUG })) then try
    //
    for r := 0 to roomCount - 1 do begin
      //
      room := roomByIndexAcquire(r, true, timeout);
      if (nil <> room) then try
	//
	if (room.hasUser(userID)) then begin
	  //
	  result := room;
	  break;
	end;
	//
      finally
	room.releaseRO();
	//
	if (nil <> result) then
	  result := unaConfRTProom(_acr(result, ro, timeout {$IFDEF DEBUG }, '.roomByUserIDAcquire(userID=' + int2str(userID) + ')' {$ENDIF DEBUG }));
      end;
    end;
    //
  finally
    unlockListRO(f_rooms2);
  end;
end;

// --  --
function TunaConfRTPserver.roomByIndexAcquire(index: int; ro: bool; timeout: tTimeout): unaConfRTProom;
begin
  result := nil;
  if (lockNonEmptyList_r(f_rooms2, true, timeout {$IFDEF DEBUG }, '.roomByIndexAcquire(index=' + int2str(index) + ')'{$ENDIF DEBUG })) then try
    //
    result := unaConfRTPRoom(_acr(f_rooms2[index], ro, timeout {$IFDEF DEBUG }, '.roomByIndexAcquire(index=' + int2str(index) + ')' {$ENDIF DEBUG }));
  finally
    unlockListRO(f_rooms2);
  end;
end;

// --  --
function TunaConfRTPserver.roomDrop(roomID: tRoomID): HRESULT;
var
  room: unaConfRTProom;
begin
  room := roomByIDAcquire(roomID, false);
  if (nil <> room) then try
    //
    // shutdown the room
    roomShutdown(roomID);
    //
    // remove room
    f_rooms2.removeById(roomID);
    room := nil;
    //
    result := S_OK;
  finally
    room.releaseWO();
  end
  else
    result := E_FAIL;
  //
{$IFDEF LOG_unaConfRTPserver_INFOS }
  logMessage(':RTPSRV: server.roomDrop(roomID=' + int2str(roomID) + ')');
{$ENDIF LOG_unaConfRTPserver_INFOS }
end;

// --  --
function TunaConfRTPserver.roomGetName(roomID: tRoomID): wString;
var
  room: unaConfRTProom;
begin
  room := roomByIDAcquire(roomID);
  if (nil <> room) then try
    //
    result := room.roomName
  finally
    room.releaseRO();
  end
  else
    result := '';
end;

// --  --
function TunaConfRTPserver.roomGetNumUsers(roomID: tRoomID): int;
var
  room: unaConfRTProom;
begin
  room := roomByIDAcquire(roomID);
  if (nil <> room) then try
    //
    result := room.userCount
  finally
    room.releaseRO();
  end
  else
    result := 0;
end;

// --  --
function TunaConfRTPserver.roomIndexByUserID(userID: u_int32; out index: int; timeout: tTimeout): bool;
var
  r: int;
  room: unaConfRTProom;
begin
  result := true;
  index := -1;
  //
  for r := 0 to roomCount - 1 do begin
    //
    room := roomByIndexAcquire(r, true, timeout);
    if (nil <> room) then try
      //
      if (room.hasUser(userID)) then begin
	//
	index := r;
	break;
      end;
      //
    finally
      room.releaseRO();
    end
    else begin
      //
      result := false;
      break;	// fail on some room, cannot return reliable index
    end;
  end;
end;

// --  --
function TunaConfRTPserver.roomResolveName(const roomName: wString): int;
begin
  result := -1;
  if (lockList_r(f_roomNames, false, 500 {$IFDEF DEBUG }, '.roomResolveNames(name=' + roomname + ')'{$ENDIF DEBUG })) then try
    //
    // make sure each unique name get unique id
    result := f_roomNames.indexOf(roomName);
    if (0 > result) then
      result := f_roomNames.add(roomName);
    //
    inc(result);	// base 1
  finally
    unlockListWO(f_roomNames);
  end;
end;

// --  --
function TunaConfRTPserver.roomShutdown(roomID: tRoomID): HRESULT;
var
  room: unaConfRTPRoom;
begin
  room := roomByIDAcquire(roomID, false, 700);
  if (nil <> room) then try
    result := roomShutdown(room);
  finally
    room.releaseWO();
  end
  else
    result := HRESULT(-1);
end;

// --  --
function TunaConfRTPserver.roomShutdown(room: unaConfRTProom; markClosed: bool): HRESULT;
var
  c: int;
  user: unaConfRTProomUser;
  userID: u_int32;
begin
  result := E_FAIL;
  //
  if ( ((nil <> room) and room.acquire(false, 500, false {$IFDEF DEBUG }, '.roomShutdown()' {$ENDIF DEBUG })) ) then try
    //
    // disconnect all users from room
    for c := 0 to room.userCount - 1 do begin
      //
      userID := u_int32(room.f_seats[c]);
      user := userByIDAcquire(userID, false, 30);
      if (nil <> user) then try
	//
	// user got disconnected
	dropLockedUser(user, room.roomID, false);
      finally
	user.releaseWO();
      end
      else
	if (0 <= f_users2.indexOfId(userID)) then
	  f_deadUserID.add(userID);
      //
    end;
    //
    if (markClosed) then
      room.f_closed := true;
    //
    room.f_seats.clear();
    //
    result := S_OK;
  finally
    room.releaseWO();
  end;
  //
{$IFDEF LOG_unaConfRTPserver_INFOS }
  logMessage(':RTPSRV: server.roomShutdown(roomID=' + int2str(room.roomID) + ')');
{$ENDIF LOG_unaConfRTPserver_INFOS }
end;

// --  --
function TunaConfRTPserver.roomStartup(roomID: tRoomID): HRESULT;
var
  room: unaConfRTProom;
begin
  result := E_FAIL;
  //
  room := roomByIDAcquire(roomID, true, 300);
  if (nil <> room) then try
    //
    room.f_closed := false;
    //
    result := S_OK;
  finally
    room.releaseRO();
  end;
  //
{$IFDEF LOG_unaConfRTPserver_INFOS }
  logMessage(':RTPSRV: server.roomStartup(roomID=' + int2str(roomID) + ')');
{$ENDIF LOG_unaConfRTPserver_INFOS }
end;

// --  --
procedure TunaConfRTPserver.sendSrvCmd(addr: PSockAddrIn; const cmd: aString; idata: int32; dataBuf: pointer; dataBufSize: unsigned);
var
  cmdBuf: unaConfRTPcmd;
  cmdPtr: punaConfRTPcmd;
  dealloc: bool;
  sz: int;
begin
  if (nil <> f_trans.rtcp) then begin
    //					       apply some sanity
    if ((nil = dataBuf) or (1 > dataBufSize) or (dataBufSize > 5000)) then begin
      //
      cmdPtr := @cmdBuf;
      cmdPtr.r_dataBufSz := 0;
      sz := sizeof(unaConfRTPcmd);
      //
      dealloc := false;
    end
    else begin
      //
      sz := sizeof(unaConfRTPcmd) + dataBufSize;
      cmdPtr := malloc(sz);
      cmdPtr.r_dataBufSz := dataBufSize;
      move(dataBuf^, cmdPtr.r_dataBuf, dataBufSize);
      //
      dealloc := true;
    end;
    cmdPtr.r_i_data := idata;
    //
{$IFDEF VCX_DEMO }
    inc(f_totalTrans);
{$ENDIF VCX_DEMO }
    //
    try
      f_trans.rtcp.sendAPPto(addr, c_rtcpAPP_subtype_srv, cmd, cmdPtr, sz);
    finally
      if (dealloc) then
	mrealloc(cmdPtr);
    end;
    //
  {$IFDEF LOG_unaConfRTPserver_INFOS }
    logMessage(':RTPSRV: room.sendSrvCmd(cmd=' + string(cmd) + '; addr=' + addr2str(addr) + ')');
  {$ENDIF LOG_unaConfRTPserver_INFOS }
  end;
end;

// --  --
procedure TunaConfRTPserver.setMasterkey(const value: string);
begin
  fillChar(f_masterkey, sizeof(unaConfRTPkey), #0);
  pwHash(value, f_masterkey);
end;

// --  --
procedure TunaConfRTPserver.setUserAllow(userID: u_int32; isIn: bool; value: bool);
var
  user: unaConfRTProomUser;
begin
  user := userByIDAcquire(userID);
  if (nil <> user) then try
    //
    if (isIn) then
      user.f_allowIN := value
    else
      user.f_allowOUT := value;
    //
  finally
    user.releaseRO();
  end;
end;

// --  --
procedure TunaConfRTPserver.transPacket(userID: u_int32; data: pointer; len: uint; const addr: sockaddr_in; isRTCP: bool);
var
  r, d: int;
  user, userOUT: unaConfRTProomUser;
  room: unaConfRTProom;
  loop: bool;
begin
  if (f_srvLock.acquire(true, 10, false {$IFDEF DEBUG }, '.transPacket(userId=' + int2str(userId) + ')' {$ENDIF DEBUG })) then try
    //
    try
      r := 0;
      while (r < roomCount) do begin
	//
	room := roomByIndexAcquire(r, true, 20);
	if (nil <> room) then try
	  //
	  if (room.hasUser(userID)) then begin
	    //
	    user := userByIDAcquire(userID, true, 10);
	    if (nil <> user) then try
	      //
	      if (
		   user.f_verified and			// user verivied?
		   (user.f_allowIN or isRTCP) and	// is this uses allowed to stream into room (or is it RTCP)?
		   // also check if packet is actually received from verified user ip:port
		   ( (isRTCP and user.f_addrRTCPValid and sameAddr(user.f_addrRTCP, addr)) or (not isRTCP and user.f_addrRTPValid and sameAddr(user.f_addrRTP, addr)) )  //
		 ) then begin
		//
		room.updateBw(true, len, user);
		//
		// re-transmit audio/RTCP to all destinations in this room
		for d := 0 to room.userCount - 1 do begin
		  //
		  userOUT := userByIDAcquire(u_int32(room.f_seats[d]), true, 1);
		  if (nil <> userOUT) then try
		    //
		    if (userOUT.f_verified and (userOUT.f_allowOUT or isRTCP) and {$IFDEF VCX_DEMO }(f_totalTrans < 119837){$ELSE }true{$ENDIF VCX_DEMO }) then begin
		      //
		      // do not send audio back to source (unless DEBUG is defined and there is only 1 participant)
		      // also never send RTCP back to original user, it will surely confuse it alot ;)
		      loop := (user.userID = userOUT.userID);
		      if ({$IFDEF DEBUG }(not loop or (loop and (1 = room.userCount) and not isRTCP)) {$ELSE }not loop{$ENDIF DEBUG }) then begin
			//
			if (isRTCP) then begin
			  //
			  if (userOUT.f_addrRTCPValid) then
			    if (0 = f_trans.send_To(@userOUT.f_addrRTCP, data, len, isRTCP, false)) then
			      room.updateBw(false, len, userOUT);
			end
			else begin
			  //
			  if (userOUT.f_addrRTPValid) then
			    if (0 = f_trans.send_To(@userOUT.f_addrRTP, data, len, isRTCP, false)) then
			      room.updateBw(false, len, userOUT);
			end;
			//
		      end;
		    end;
		  finally
		    userOUT.releaseRO();
		  end;
		end; // for
		//
		if (userStrictlyInOneRoom) then
		  break;
	      end;
	      //
	    finally
	      user.releaseRO();
	    end
	    else
	      inc(f_lostTrans);
	    //
	  end;	// if room.hasUser()
	  //
	finally
	  room.releaseRO();
	end
	else
	  inc(f_lostTrans);
	//
	inc(r);
      end;
      //
    except
    end;
  finally
    f_srvLock.releaseRO();
  end
  else
    inc(f_lostTrans);
end;

// --  --
function TunaConfRTPserver.userAddAcquire(userID: u_int32; ro: bool): unaConfRTProomUser;
begin
  result := unaConfRTProomUser.create(self, userID);
  // this should always succeed, it is a local variable after all
  result.acquire(ro, 10, false {$IFDEF DEBUG }, '.userAddAcquire(userID=' + int2str(userID) + ')' {$ENDIF DEBUG });
  //
  f_users2.add(result);
end;

// --  --
function TunaConfRTPserver.userByIDAcquire(userID: u_int32; ro: bool; timeout: tTimeout): unaConfRTProomUser;
begin
  result := nil;
  if (lockNonEmptyList_r(f_users2, true, timeout {$IFDEF DEBUG }, '.userByIDAcquire(userid=' + int2str(userid) + ')'{$ENDIF DEBUG })) then try
    //
    result := unaConfRTProomUser(_acr(f_users2.itemById(userID), ro, timeout {$IFDEF DEBUG }, '.userByIDAcquire(userid=' + int2str(userid) + ')'{$ENDIF DEBUG }));
  finally
    unlockListRO(f_users2);
  end;
end;

// --  --
function TunaConfRTPserver.userByIndexAcquire(index: int; ro: bool; timeout: tTimeout): unaConfRTProomUser;
begin
  result := nil;
  if (lockNonEmptyList_r(f_users2, true, timeout {$IFDEF DEBUG }, '.userByIndexAcquire(index=' + int2str(index) + ')'{$ENDIF DEBUG })) then try
    //
    result := unaConfRTProomUser(_acr(f_users2.item[index], ro, timeout {$IFDEF DEBUG }, '.userByIndexAcquire(index=' + int2str(index) + ')'{$ENDIF DEBUG }));
  finally
    unlockListRO(f_users2);
  end;
end;

// --  --
function TunaConfRTPserver.userDrop(userID: u_int32): HRESULT;
var
  user: unaConfRTProomUser;
  roomLeave: unaConfRTProom;
  roomID: int;
begin
  result := E_FAIL;
  //
  roomID := -1;
  roomLeave := roomByUserIDAcquire(userID, false, 100);
  if (nil <> roomLeave) then try
    //
    roomLeave.dropUser(userID);
    roomID := roomLeave.roomID;
  finally
    roomLeave.releaseWO();
  end;
  //
  user := userByIDAcquire(userID, false, 500);
  if (nil <> user) then try
    //
    dropLockedUser(user, roomID, false);
    result := S_OK;
  finally
    user.releaseWO();
  end
  else
    if (0 <= f_users2.indexOfId(userID)) then
      f_deadUserID.add(userID);
  //
{$IFDEF LOG_unaConfRTPserver_INFOS }
  logMessage(':RTPSRV: server.userDrop(roomID=' + int2str(roomID) + ')');
{$ENDIF LOG_unaConfRTPserver_INFOS }
end;

// --  --
function TunaConfRTPserver.userDrop(user: unaConfRTProomUser): HRESULT;
begin
  if (nil <> user) then
    result := userDrop(user.userID)
  else
    result := E_FAIL;
end;

// --  --
function TunaConfRTPserver.userGetName(userID: u_int32; out cname: wString): bool;
begin
  if (nil <> rtcp) then
    result := rtcp.getMemberCNAME(userID, cname)
  else
    result := false;
end;

// --  --
function TunaConfRTPserver._acr(obj: unaObject; ro: bool; timeout: tTimeout {$IFDEF DEBUG }; const reason: string {$ENDIF DEBUG }): unaObject;
begin
  result := nil;
  //
  if (nil <> obj) then begin
    //
    if (obj.acquire(ro, timeout, false {$IFDEF DEBUG }, reason {$ENDIF DEBUG })) then
      result := obj;
  end;
end;

//
// -- resister components in IDE --
//
procedure Register();
begin
  RegisterComponents(c_VC_reg_RTP_section_name, [
    //
    TunaConfRTPserver
  ]);
end;


end.
