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

	  unaConfRTP.pas
	  Conf RTP common stuff

	----------------------------------------------
	  Copyright (c) 2009-2011 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, Feb 2010

	  modified by:
		Lake, Feb-Dec 2010
		Lake, Apr 2011

	----------------------------------------------
*)

{$I unaDef.inc }

{*
    unaConfRTP common stuff.

    @Author Lake

    Version 2.5.2010.03 Still here

    Version 2.5.2011.01 CELT added

}

unit
  unaConfRTP;

interface

uses
  Windows, unaTypes;

const
  c_max_rooms	 		= 500;		// maximum number of rooms per server
  c_max_users_per_room		= 1000;		// maximum number of users per room
  c_max_users_per_server	= c_max_rooms * c_max_users_per_room;	// maximum number of users per server
  //
  c_max_audioStreams_per_room	= 8;		// max number of talking (at the same time) people in one room
  //
  c_confRTPcln_mixer_sps	= 32000;	// default mixing rate for clients
  //
  // known audio payloads
  c_rtpPTs_conf_speex_8000	= 101;
  c_rtpPTs_conf_speex_16000	= 102;
  c_rtpPTs_conf_speex_32000	= 103;
  //
  c_rtpPTs_conf_mpeg_8000	= 104;
  c_rtpPTs_conf_mpeg_16000	= 105;
  c_rtpPTs_conf_mpeg_32000	= 106;
  //
  c_rtpPTs_conf_uLaw_8000	= 107;
  c_rtpPTs_conf_uLaw_16000	= 108;
  c_rtpPTs_conf_uLaw_32000	= 109;
  //
  c_rtpPTs_conf_PCM_8000  	= 110;
  c_rtpPTs_conf_PCM_16000	= 111;
  c_rtpPTs_conf_PCM_32000	= 112;
  //
  c_rtpPTs_conf_ALaw_8000	= 113;
  c_rtpPTs_conf_ALaw_16000	= 114;
  c_rtpPTs_conf_ALaw_32000	= 115;
  //
  c_rtpPTs_conf_CELT_8000	= 116;
  c_rtpPTs_conf_CELT_16000	= 117;
  c_rtpPTs_conf_CELT_24000	= 118;
  //
  c_rtpPTs_conf_G7221_8000	= 119;
  c_rtpPTs_conf_G7221_16000	= 120;
  c_rtpPTs_conf_G7221_32000	= 121;
  //
  c_rtcpAPP_subtype_srv		= 1;	// srv command
  c_rtcpAPP_subtype_cln		= 2;	// client command
  //
  // server commans
  c_confSrvCmd_joinOK		= 'JOIN';	// OK for join, dataBuf contains room's session key
  c_confSrvCmd_FAIL		= 'FAIL';	// negative reply, idata may contain error code (c_wizSrvError_xxx)
  c_confSrvCmd_drop		= 'DROP';	// connection will be dropped, idata may contain the reason
  c_confSrvCmd_announce		= 'ANNO';	// some announce from server, dataBuf contains a message
  c_confSrvCmd_LEAVE		= 'LEAV';	// some announce from server, dataBuf contains a message
  //
  // user commans
  c_confClnCmd_join		= 'JOIN';	// join room, data = room_name
  c_confClnCmd_leave		= 'LEAV';	// leave room, data = room_name
  c_confClnCmd_joinHasKey	= 'HKEY';	// join room, data = room_name, now user has the key
  //
  // crc32 of above for quick access
  c_confSrvCmd_joinOK_crc	= 3775646364;
  c_confSrvCmd_FAIL_crc		= 1330460930;
  c_confSrvCmd_drop_crc		= 3112114025;
  c_confSrvCmd_announce_crc	= 260997627;
  //
  // user commans
  c_confClnCmd_join_crc		= 3775646364;
  c_confClnCmd_leave_crc	= 0306315976;
  c_confClnCmd_joinHasKey_crc	= 1668112384;
  //
  // server error codes for server commands
  c_confSrvError_accessDenied		= -1;
  c_confSrvError_roomClosed		= -2;
  c_confSrvError_userKicked		= -3;
  c_confSrvError_outOfSeats		= -4;
  c_confSrvError_roomDoesNotExist	= -5;
  c_confSrvError_pleaseTryAgain		= -6;	// server seems to be a little busy, please try again in few seconds
  c_confSrvError_noSuchUserID		= -7;	//
  c_confSrvError_malformedData		= -8;	//
  c_confSrvError_invalidPassword	= -9;	//
  c_confSrvError_suchUserFromWrongAddr	= -10;	//
  c_confSrvError_userObjLocked		= -11;	// try again later

type
  {*

  }
  unaConfRTPkey = array[0..15] of uint8;

  {*

  }
  punaConfRTPcmd = ^unaConfRTPcmd;
  unaConfRTPcmd = packed record
    //
    r_i_data: int32;
    r_dataBufSz: uint32;
    r_dataBuf: record end;
  end;

{*
	Returns hash for given password.

	Replace with better hash for improved security
}
procedure pwHash(const pw: string; var hash: unaConfRTPkey);
{*
	Encodes block of data.

	Replace with better cipher for improved security
}
procedure encode(data: pointer; dataLen: int; key: pointer; keyLen: int);
{*
	Returns sampling rate for specified payload.
}
function pt2sps(pt: int): int;
{*
	Returns string representation of specified payload.
}
function pt2str(pt: int): string;


implementation


uses
  unaUtils;

// --  --
procedure pwHash(const pw: string; var hash: unaConfRTPkey);
var
  s: aString;
  i: int32;
  h: int;
  v: uint16;
begin
  s := base64encode(base64encode(aString(int2str(crc32(aString(pw)))) + aString(pw)));
  //
  h := low(hash);
  for i := 1 to length(s) - 1 do begin
    //
    v := byte(s[i]) * byte(s[i + 1]);
    hash[h] := hash[h] xor byte(crc32(@v, 2));
    //
    inc(h);
    if (h > high(hash)) then
      h := low(hash);
  end;
end;

// --  --
procedure encode(data: pointer; dataLen: int; key: pointer; keyLen: int);
var
  i, j: int;
begin
  if ((0 < dataLen) and (0 < keyLen) and (nil <> data) and (nil <> key)) then begin
    //
    j := 0;
    for i := 0 to dataLen - 1 do begin
      //
      pArray(data)[i] := pArray(data)[i] xor pArray(key)[j];
      //
      inc(j);
      if (j >= keyLen) then
	j := 0;
    end;
  end;
end;

// --  --
function pt2sps(pt: int): int;
begin
  case (pt) of

    c_rtpPTs_conf_speex_8000	: result := 8000;
    c_rtpPTs_conf_speex_16000	: result := 16000;
    c_rtpPTs_conf_speex_32000	: result := 32000;
    //
    c_rtpPTs_conf_uLaw_8000	: result := 8000;
    c_rtpPTs_conf_uLaw_16000	: result := 16000;
    c_rtpPTs_conf_uLaw_32000	: result := 32000;
    //
    c_rtpPTs_conf_PCM_8000	: result := 8000;
    c_rtpPTs_conf_PCM_16000	: result := 16000;
    c_rtpPTs_conf_PCM_32000	: result := 32000;
    //
    c_rtpPTs_conf_ALaw_8000	: result := 8000;
    c_rtpPTs_conf_ALaw_16000	: result := 16000;
    c_rtpPTs_conf_ALaw_32000	: result := 32000;
    //
    c_rtpPTs_conf_mpeg_8000	: result := 8000;
    c_rtpPTs_conf_mpeg_16000	: result := 16000;
    c_rtpPTs_conf_mpeg_32000	: result := 32000;
    //
    c_rtpPTs_conf_CELT_8000	: result := 8000;
    c_rtpPTs_conf_CELT_16000	: result := 16000;
    c_rtpPTs_conf_CELT_24000	: result := 24000;
    //
    c_rtpPTs_conf_G7221_8000	: result := 8000;
    c_rtpPTs_conf_G7221_16000	: result := 16000;
    c_rtpPTs_conf_G7221_32000	: result := 32000;

    else
      result := c_confRTPcln_mixer_sps;	// does not matter, actually, assuming it will be figured out in some other way

  end;
end;

// --  --
function pt2str(pt: int): string;
begin
  case (pt) of

    c_rtpPTs_conf_speex_8000,
    c_rtpPTs_conf_speex_16000,
    c_rtpPTs_conf_speex_32000	: result := 'Speex';
    //
    c_rtpPTs_conf_uLaw_8000,
    c_rtpPTs_conf_uLaw_16000,
    c_rtpPTs_conf_uLaw_32000	: result := 'uLaw';
    //
    c_rtpPTs_conf_PCM_8000,
    c_rtpPTs_conf_PCM_16000,
    c_rtpPTs_conf_PCM_32000	: result := 'PCM';
    //
    c_rtpPTs_conf_ALaw_8000,
    c_rtpPTs_conf_ALaw_16000,
    c_rtpPTs_conf_ALaw_32000	: result := 'ALaw';
    //
    c_rtpPTs_conf_mpeg_8000,
    c_rtpPTs_conf_mpeg_16000,
    c_rtpPTs_conf_mpeg_32000	: result := 'MP3';
    //
    c_rtpPTs_conf_CELT_8000,
    c_rtpPTs_conf_CELT_16000,
    c_rtpPTs_conf_CELT_24000	: result := 'CELT';
    //
    c_rtpPTs_conf_G7221_8000,
    c_rtpPTs_conf_G7221_16000,
    c_rtpPTs_conf_G7221_32000	: result := 'G.722.1';

    else
      result := 'Unknown payload: ' + int2str(pt);

  end;
end;


end.

