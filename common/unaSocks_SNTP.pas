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

	  unaSocks_SNTP.pas
	  Simple Network Time Protocol (SNTP) implementation
	  RFC 1305 (NTP 3.0), RFC 1769 (SNTP), RFC 4330 (SNTP 4.0)

	----------------------------------------------
	  Copyright (c) 2008-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 27 May 2008

	  modified by:
		Lake, May 2008

	----------------------------------------------
*)

{$I unaDef.inc }

{*
	  Simple Network Time Protocol (SNTP) implementation
	  RFC 1305 (NTP 3.0), RFC 1769 (SNTP), RFC 4330 (SNTP 4.0)
}

unit
  unaSocks_SNTP;

interface

uses
  Windows, unaTypes, unaClasses;

const
  PORT_SNTP    = 123;

type

{

First you should try all servers at pool.ntp.org

Some older ones:
time-a.nist.gov 129.6.15.28 NIST, Gaithersburg, Maryland
time-b.nist.gov 129.6.15.29 NIST, Gaithersburg, Maryland
time-a.timefreq.bldrdoc.gov 132.163.4.101 NIST, Boulder, Colorado
time-b.timefreq.bldrdoc.gov 132.163.4.102 NIST, Boulder, Colorado
time-c.timefreq.bldrdoc.gov 132.163.4.103 NIST, Boulder, Colorado
utcnist.colorado.edu 128.138.140.44 University of Colorado, Boulder
time.nist.gov 192.43.244.18 NCAR, Boulder, Colorado
time-nw.nist.gov 131.107.1.10 Microsoft, Redmond, Washington
nist1.datum.com 63.149.208.50 Datum, San Jose, California
nist1.dc.glassey.com 216.200.93.8 Abovenet, Virginia
nist1.ny.glassey.com 208.184.49.9 Abovenet, New York City
nist1.sj.glassey.com 207.126.103.204 Abovenet, San Jose, California
nist1.aol-ca.truetime.com 207.200.81.113 True Time, Sunnyvale, California
nist1.aol-va.truetime.com 205.188.185.33 True Time, Virginia

}


{
   Because NTP timestamps are cherished data and, in fact, represent the
   main product of the protocol, a special timestamp format has been
   established.  NTP timestamps are represented as a 64-bit unsigned
   fixed-point number, in seconds relative to 0h on 1 January 1900.  The
   integer part is in the first 32 bits, and the fraction part in the
   last 32 bits.  In the fraction part, the non-significant low-order
   bits are not specified and are ordinarily set to 0.

      It is advisable to fill the non-significant low-order bits of the
      timestamp with a random, unbiased bitstring, both to avoid
      systematic roundoff errors and to provide loop detection and
      replay detection (see below).  It is important that the bitstring
      be unpredictable by an intruder.  One way of doing this is to
      generate a random 128-bit bitstring at startup.  After that, each
      time the system clock is read, the string consisting of the
      timestamp and bitstring is hashed with the MD5 algorithm, then the
      non-significant bits of the timestamp are copied from the result.

   The NTP format allows convenient multiple-precision arithmetic and
   conversion to UDP/TIME message (seconds), but does complicate the
   conversion to ICMP Timestamp message (milliseconds) and Unix time
   values (seconds and microseconds or seconds and nanoseconds).  The
   maximum number that can be represented is 4,294,967,295 seconds with
   a precision of about 232 picoseconds, which should be adequate for
   even the most exotic requirements.

			   1                   2                   3
       0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                           Seconds                             |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                  Seconds Fraction (0-padded)                  |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

   Note that since some time in 1968 (second 2,147,483,648), the most
   significant bit (bit 0 of the integer part) has been set and that the
   64-bit field will overflow some time in 2036 (second 4,294,967,296).
   There will exist a 232-picosecond interval, henceforth ignored, every
   136 years when the 64-bit field will be 0, which by convention is
   interpreted as an invalid or unavailable timestamp.
}
  punaNTP_timestamp = ^unaNTP_timestamp;
  unaNTP_timestamp = packed record
    //
    r_seconds: uint32;
    r_fraction: uint32;
  end;


{
			   1                   2                    3
       0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9  0  1
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |LI | VN  |Mode |    Stratum    |     Poll      |   Precision    |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                          Root  Delay                           |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                       Root  Dispersion                         |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                     Reference Identifier                       |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                                                                |
      |                    Reference Timestamp (64)                    |
      |                                                                |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                                                                |
      |                    Originate Timestamp (64)                    |
      |                                                                |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                                                                |
      |                     Receive Timestamp (64)                     |
      |                                                                |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                                                                |
      |                     Transmit Timestamp (64)                    |
      |                                                                |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                 Key Identifier (optional) (32)                 |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      |                                                                |
      |                                                                |
      |                 Message Digest (optional) (128)                |
      |                                                                |
      |                                                                |
      +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

			Figure 1.  NTP Packet Header
}

  punaNTP_packet = ^unaNTP_packet;
  unaNTP_packet = packed record
    //
    r_flags: uint8;		// LI.VN.Mode
    r_stratum: uint8;		//
    r_poll: uint8;		//
    r_precision: uint8;		//
    //
    r_rootDelay: int32;		// This is a 32-bit signed fixed-point number indicating the
				//   total roundtrip delay to the primary reference source, in seconds
				//   with the fraction point between bits 15 and 16.
    r_rootDispersion: uint32;	// This is a 32-bit unsigned fixed-point number
				//   indicating the maximum error due to the clock frequency tolerance, in
				//   seconds with the fraction point between bits 15 and 16.
    r_referenceIdentifier: uint32;		// This is a 32-bit bitstring identifying the
						//   particular reference source
    r_referenceTimestamp: unaNTP_timestamp;	// This field is the time the system clock was last set or corrected.
    r_originateTimestamp: unaNTP_timestamp;	// This is the time at which the request departed the client for the server.
    r_receiveTimestamp: unaNTP_timestamp;	// This is the time at which the request arrived at the server or the reply arrived at the client.
    r_transmitTimestamp: unaNTP_timestamp;	// This is the time at which the request departed the client or the reply departed the server
    //
    //r_key: uint32		;		// Optional auth field
  end;


  {*
	SNTP implementation class.
  }
  unaSNTP = class(unaThread)
  private
    f_serverList: unaStringList;
    f_rtd: int64;
    f_co: int64;
    //
    f_stratum: unsigned;
    f_refCode: unsigned;
  protected
    function execute(threadID: unsigned): int; override;
  public
    procedure AfterConstruction(); override;
    procedure BeforeDestruction(); override;
    //
    {*
	Posts unicast NTP request to specified NTP server.

	@param server NTP server to use. Default is 'pool.ntp.org'

	@return Number of IPs the host resolves to.
    }
    function synch(const server: string = 'pool.ntp.org'): int;
    //
    function nowNTP(out ntp: unaNTP_timestamp; adjustOffest: bool = true): bool;
    //
    function getRefCodeAsString(): string;
    //
    property roundtripDelay: int64 read f_rtd;	// ms
    property clockOffset: int64 read f_co;	// ms
    property stratum: unsigned read f_stratum;	// 0      - kiss-o'-death
						// 1      - primary source
						// 2-15   - synchronized by NTP/SNTP
						// 16-254 - reserved
						// 255    - query in progress, please wait
    property refCode: unsigned read f_refCode;	// reference code / KoD message code
  end;


{*
	Converts UTC time into NTP timestamp.
}
procedure UTC2NTP(const utc: SYSTEMTIME; out ntp: unaNTP_timestamp);
{*
	Converts NTP timestamp into UTC time.
}
procedure NTP2UTC(const ntp: unaNTP_timestamp; out utc: SYSTEMTIME);
{*
	Converts NTP timestamp into milliseconds value.
}
function NTP2ms(const ntp: unaNTP_timestamp): int64;
{*
	Converts milliseconds value into NTP timestamp.
}
procedure ms2NTP(const ms: int64; out ntp: unaNTP_timestamp);


implementation


uses
  unaUtils,
  WinSock, unaSockets;


// -- globals --

const
  c_secondsPerDay	= 24 * 60 * 60;
  c_secondsPerYear: array[boolean] of uint = (365 * c_secondsPerDay, 366 * c_secondsPerDay);
  //
  c_daysPassed: array [boolean, 0..12] of int =
    ((0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365),
     (0, 31, 60, 91, 121, 152, 182, 213, 244, 274, 305, 335, 366));

var
  g_ms2frac: array[0..999] of uint32;


// --  --
function leapYearsSince1900(y: int): int;
begin
  if (y < 1905) then
    result := 0
  else begin
    //
    result := (y - 1901) div 4;
    if (2100 < y) then
      result := result - (y - 2001) div 100 + (y - 2001) div 400;
    //
  end;
end;

// --  --
procedure UTC2NTP(const utc: SYSTEMTIME; out ntp: unaNTP_timestamp);
var
  seconds: int64;
begin
  if (1900 <= utc.wYear) then begin
    //
    seconds := int64(utc.wYear - 1900) * c_secondsPerYear[false];
    inc(seconds, int64(leapYearsSince1900(utc.wYear)) * c_secondsPerDay);
    //
    inc(seconds, c_secondsPerDay * c_daysPassed[isLeapYear(utc.wYear)][utc.wMonth - 1]);
    inc(seconds, c_secondsPerDay * (utc.wDay - 1));
    inc(seconds,         60 * 60 *  utc.wHour);
    inc(seconds,              60 *  utc.wMinute);
    inc(seconds,                    utc.wSecond);
    //
    ntp.r_seconds := seconds and $FFFFFFFF;
    ntp.r_fraction := g_ms2frac[utc.wMilliseconds mod 1000];	// mod is just in case here
  end
  else
    ntp.r_seconds := 0;
end;

// --  --
procedure NTP2UTC(const ntp: unaNTP_timestamp; out utc: SYSTEMTIME);
var
  seconds: uint32;
  days: int;
  y, m: int;
begin
  seconds := ntp.r_seconds;
  //
  y := 1900;
  while (c_secondsPerYear[isLeapYear(y)] <= seconds) do begin
    //
    dec(seconds, c_secondsPerYear[isLeapYear(y)]);
    inc(y);
  end;
  //
  days := seconds div c_secondsPerDay;
  m := 1;
  while (days >= c_daysPassed[isLeapYear(y)][m]) do
    inc(m);
  //
  dec(seconds, c_daysPassed[isLeapYear(y)][m - 1] * c_secondsPerDay);
  //
  utc.wYear := y;
  utc.wMonth := m;
  //
  utc.wDay := seconds div c_secondsPerDay + 1;
  dec(seconds, (utc.wDay - 1) * c_secondsPerDay);
  //
  utc.wHour := seconds div (60 * 60);
  dec(seconds, utc.wHour * 60 * 60);
  //
  utc.wMinute := seconds div 60;
  dec(seconds, utc.wMinute * 60);
  //
  utc.wSecond := seconds;
  //
  utc.wMilliseconds := NTP2ms(ntp) - int64(ntp.r_seconds) * 1000;
  utc.wDayOfWeek := 0;	// not converted yet
end;

// --  --
function NTP2ms(const ntp: unaNTP_timestamp): int64;
begin
  result := int64(ntp.r_seconds) * 1000 + round( int64(ntp.r_fraction) * 1000 / $100000000 );
end;

// --  --
procedure ms2NTP(const ms: int64; out ntp: unaNTP_timestamp);
begin
  ntp.r_seconds := ms div 1000;
  ntp.r_fraction := g_ms2frac[ms mod 1000];
end;

// --  --
procedure swapNTP(var ntp: unaNTP_timestamp);
asm
{$IFDEF CPU64 }
	//	RCX = pointer to unaNTP_timestamp structure
	//
	mov	edx, [rcx]
        //
	xchg    dl, dh
	rol	edx, 16
	xchg    dl, dh
	mov     [rcx], edx
	//
	inc	rcx
	inc	rcx
	inc	rcx
	inc	rcx
	//
	mov	edx, [rcx]
	xchg    dl, dh
	rol	edx, 16
	xchg    dl, dh
	mov     [rcx], edx
{$ELSE }
	//	EAX = pointer to unaNTP_timestamp structure
	//
	mov	edx, [eax]
	xchg    dl, dh
	rol	edx, 16
	xchg    dl, dh
	mov     [eax], edx
	//
	inc	eax
	inc	eax
	inc	eax
	inc	eax
	//
	mov	edx, [eax]
	xchg    dl, dh
	rol	edx, 16
	xchg    dl, dh
	mov     [eax], edx
{$ENDIF CPU64 }
end;


{ unaSNTP }

// --  --
procedure unaSNTP.AfterConstruction();
begin
  f_serverList := unaStringList.create();
  //
  f_stratum := 1;
  move(aString('LOCL'), f_refCode, 4);
  //
  inherited;
end;

// --  --
procedure unaSNTP.BeforeDestruction();
begin
  inherited;
  //
  freeAndNil(f_serverList);
end;

// --  --
function unaSNTP.execute(threadID: unsigned): int;
var
  transport: unaUDPSocket;
  addr: sockaddr_in;
  packet: unaNTP_packet;
  i: int;
  //
  tm: uint64;
  res: int;
  buf: array[0..4095] of byte;
  reply: punaNTP_packet;
  //
  ntpGot: unaNTP_timestamp;
  T1, T2, T3, T4: int64;
  //
  rtd: int64;
  co : int64;
  rtd_i: int64;
  co_i : int64;
  //
  lastChance: bool;
begin
  transport := unaUDPSocket.create();
  try
    //
    f_stratum := $FF;	// query in progress
    f_refCode := 0;
    //
    rtd := 0;
    co := 0;
    i := 0;
    while ((i < int(f_serverList.count)) and not shouldStop) do begin
      //
      lastChance := (i = int(f_serverList.count) - 1);
      //
      transport.setHost('64.6.144.6'{f_serverList.get(i)});	// '38.117.195.101'
      transport.setPort(PORT_SNTP);
      //
      res := transport.getSockAddr(addr);
      if (0 = res) then begin
	//
	res := transport.bindSocketToPort();
	if (0 = res) then begin
	  //
	  transport.getSockAddr(addr);
	  //
	  fillChar(packet, sizeOf(packet), #0);
	  packet.r_flags := $DB;	//   LI = 00  (clock is not synch)
					// Mode = 011 (unicast client)
					//  Ver = 011 (3)
	  packet.r_poll := 1;
	  packet.r_precision := $FA;
	  packet.r_rootDispersion := $40100;
	  //
	  nowNTP(packet.r_transmitTimestamp, false);
	  swapNTP(packet.r_transmitTimestamp);	// swap to big-endian
						//   this swap is not actually needed, since server will not analyze this field,
						//   but rather will copy it to r_originateTimestamp.
						//   We swap it here anyways (do not forget to swap it back when server reply)
	  //
	  res := transport.sendto(addr, @packet, sizeof(packet), 0, 1000);
	  if (0 = res) then begin
	    //
	    tm := timeMarkU();
	    while (not shouldStop) do begin
	      //
	      res := transport.recvfrom(addr, @buf, sizeOf(buf), false, 0, 100);
	      if (sizeof(reply^) <= res) then begin
		//
		nowNTP(ntpGot, false);		// ntpGot will be T4, see below, no time to waste now, hurry up!
		//
		reply := punaNTP_packet(@buf);
		if (0 <> reply.r_stratum) then begin	// KoD?
		  //
		  swapNTP(reply.r_referenceTimestamp);
		  swapNTP(reply.r_originateTimestamp);
		  swapNTP(reply.r_receiveTimestamp);
		  swapNTP(reply.r_transmitTimestamp);
		  //
		  {
		     When the server reply is received, the client determines a
		     Destination Timestamp variable as the time of arrival according to
		     its clock in NTP timestamp format.  The following table summarizes
		     the four timestamps.

			Timestamp Name          ID   When Generated
			------------------------------------------------------------
			Originate Timestamp     T1   time request sent by client
			Receive Timestamp       T2   time request received by server
			Transmit Timestamp      T3   time reply sent by server
			Destination Timestamp   T4   time reply received by client

		     The roundtrip delay d and system clock offset t are defined as:

			d = (T4 - T1) - (T3 - T2)     t = ((T2 - T1) + (T3 - T4)) / 2.

		  }
		  //
		  T1 := NTP2ms(reply.r_originateTimestamp);
		  T2 := NTP2ms(reply.r_receiveTimestamp);
		  T3 := NTP2ms(reply.r_transmitTimestamp);
		  T4 := NTP2ms(ntpGot);
		  //
		  rtd_i :=  (T4 - T1) - (T3 - T2);
		  co_i  := ((T2 - T1) + (T3 - T4)) div 2;
		  //
		  if (0 = rtd) then
		    rtd := rtd_i
		  else
		    rtd := (rtd + rtd_i) div 2;
		  //
		  if (0 = co) then
		    co := co_i
		  else
		    co := (co + co_i) div 2;
		  //
		  f_stratum := reply.r_stratum;
		  f_refCode := reply.r_referenceIdentifier;
		end
		else begin
		  //
		  if (($FF = f_stratum) and lastChance) then begin
		    //
		    f_stratum := 0;	// KoD
		    f_refCode := reply.r_referenceIdentifier;
		  end;
		end;
		//
		break;
	      end
	      else begin
		//
		if (0 = res) then
		  break;	// connection was closed
		//
		if (3000 < timeElapsed32U(tm)) then
		  break;	// reply with more than 3 seconds delay is useless
	      end;
	      //
	      Sleep(10);
	    end;  // while (not shouldStop) ...
	    //
	  end;  // if (sendto() is OK) ...
	end;  // if (bind OK) ...
      end; // if (addr is OK) ...
      //
      transport.close();
      //
      inc(i);
    end; // while (i < count) ...
    //
    if (0 <> rtd) then
      f_rtd := rtd;
    //
    if (0 <> co) then
      f_co := co;
    //
  finally
    freeAndNil(transport);
    f_serverList.clear();
  end;
  //
  result := 0;
end;

// --  --
function unaSNTP.getRefCodeAsString(): string;
var
  buf: array[0..4] of aChar;
begin
  case (stratum) of

    0, 1: begin
      //
      buf[4] := #0;
      move(refCode, buf[0], 4);
      result := string(buf);
      //
      if (0 = stratum) then
	result := 'KoD, ' + result
      else
	result := 'Primary, ' + result;
    end;

    2..15:
      result := 'Src=' + ipN2str(TIPv4N(u_long(refCode)));

    else
      result := '0x' + int2str(refCode, 16);

  end;
end;

// --  --
function unaSNTP.nowNTP(out ntp: unaNTP_timestamp; adjustOffest: bool): bool;
var
  ms: int64;
begin
  UTC2NTP(nowUTC(), ntp);
  if (adjustOffest and (0 <> clockOffset)) then begin
    //
    ms := NTP2ms(ntp) + clockOffset;
    ms2NTP(ms, ntp);
  end;
  //
  result := true;
end;

// --  --
function unaSNTP.synch(const server: string): int;
var
  ip: string;
begin
  f_serverList.clear();
  lookupHost(server, ip, f_serverList);
  result := f_serverList.count;
  //
  if (0 < result) then
    start();
end;


{
500.0              ms = 1/2          sec = 1000.0000,0000.0000,0000.0000,0000.0000 = $8000.0000
250.0              ms = 1/4          sec = 0100.0000,0000.0000,0000.0000,0000.0000 = $4000.0000
125.0              ms = 1/8          sec = 0010.0000,0000.0000,0000.0000,0000.0000 = $2000.0000
 62.5              ms = 1/16         sec = 0001.0000,0000.0000,0000.0000,0000.0000 = $1000.0000
 31.25             ms = 1/32         sec = 0000.1000,0000.0000,0000.0000,0000.0000 = $0800.0000
 15.625            ms = 1/64         sec = 0000.0100,0000.0000,0000.0000,0000.0000 = $0400.0000
  7.8125           ms = 1/128        sec = 0000.0010,0000.0000,0000.0000,0000.0000 = $0200.0000
  3.90625          ms = 1/256        sec = 0000.0001,0000.0000,0000.0000,0000.0000 = $0100.0000
  1.953125         ms = 1/512        sec = 0000.0000,1000.0000,0000.0000,0000.0000 = $0080.0000
  0.9765625        ms = 1/1024       sec = 0000.0000,0100.0000,0000.0000,0000.0000 = $0040.0000
  0.48828125       ms = 1/2048       sec = 0000.0000,0010.0000,0000.0000,0000.0000 = $0020.0000
  0.244140625      ms = 1/4096       sec = 0000.0000,0001.0000,0000.0000,0000.0000 = $0010.0000
  0.1220703125	   ms = 1/8912       sec = 0000.0000,0000.1000,0000.0000,0000.0000 = $0008.0000
  0.06103515625    ms = 1/16384      sec = 0000.0000,0000.0100,0000.0000,0000.0000 = $0004.0000
  0.030517578125   ms = 1/32768      sec = 0000.0000,0000.0010,0000.0000,0000.0000 = $0002.0000
  0.0152587890625  ms = 1/65536      sec = 0000.0000,0000.0001,0000.0000,0000.0000 = $0001.0000
  ....
  2.3283064365e-07 ms = 1/4294967296 sec = 0000.0000,0000.0000,0000.0000,0000.0001 = $0000.0001
}

var
  ms, b, v: int;
  msd: double;
  f: uint32;
initialization
  //
  g_ms2frac[0] := 0;
  for ms := 1 to 999 do begin
    //
    v := 1;
    f := 0;
    msd := ms;
    for b := 31 downto 1 do begin	// yes, we ignore 1/4294967296 sec (lsb), otherwise v must be a 64 bit integer
      //
      v := v shl 1;
      if (msd >= 1000 / v) then begin
	//
	f := f or 1 shl b;
	msd := msd - 1000 / v;
      end;
    end;
    //
    g_ms2frac[ms] := f;
  end;
end.

