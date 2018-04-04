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
	  unaSocks_RTP.pas
	  A Transport Protocol for Real-Time Applications / RFC 3550
	----------------------------------------------
	  Copyright (c) 2008-2011 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 29 May 2008

	  modified by:
		Lake, May-Dec 2008
		Lake, Jan-Jun 2009
		Lake, Feb-Dec 2010
		Lake, Jan-Apr 2011
		Lake, Apr-Dec 2012

	----------------------------------------------
*)

{$I unaDef.inc }

{*
    RTP/RTCP implementation.

    @author Lake
    @version 1.0 first release
    @version 1.1 RTCP implemented
    @version 2012.01 some RTCP fixes
}

{$IFDEF DEBUG }
  {x $DEFINE UNA_SOCKSRTP_LOG_RTP }	// define to log RTP operations
  {xx $DEFINE UNA_SOCKSRTP_LOG_RTP_EX }	// define to log even more RTP operations
  {$DEFINE UNA_SOCKSRTP_LOG_RTCP }	// define to log RTCP stack operations
  {xx $DEFINE UNA_SOCKSRTP_LOG_RTCP_EX }	// define to log even more RTCP stack operations
  //
  {x $DEFINE UNA_SOCKSRTP_RTCP_SEQ_DEBUG }	// define to strart seq # from number close to 65535
  {x $DEFINE UNA_SOCKSRTP_RTCP_RTT_DEBUG }	// define to log RTT activity
  {x $DEFINE UNA_SOCKSRTP_LOG_SOCKDATA }	// define to log additional information about each data sent/received over RTP/RTCP sockets
{$ENDIF DEBUG }

unit
  unaSocks_RTP;

interface

uses
  Windows, WinSock,
  unaTypes, unaClasses, unaSockets, unaSocks_SNTP;

{
  * rtp.h -- RTP header file
}
//#include <sys/types.h>

type
{
  * The type definitions below are valid for 32-bit architectures and
  * may have to be adjusted for 16- or 64-bit architectures.
}
  u_int8 	= uint8;
  u_int16	= uint16;
  u_int32	= uint32;

  // int24 type
  int24	= packed record
    r_hi: int8;
    r_low: u_int16;	// in network order
  end;

const
  //
  RTP_VERSION 	= 2;	/// Current protocol version.
  //
  RTP_SEQ_MOD	= 1 shl 16;
  RTP_MAX_SDES	= 255;	//* maximum text length for SDES */

  // RTCP packet type
  RTCP_SR 	= 200;
  RTCP_RR 	= 201;
  RTCP_SDES 	= 202;
  RTCP_BYE 	= 203;
  RTCP_APP 	= 204;

  // SDES type
  RTCP_SDES_END 	= 0;
  RTCP_SDES_CNAME 	= 1;
  RTCP_SDES_NAME 	= 2;
  RTCP_SDES_EMAIL 	= 3;
  RTCP_SDES_PHONE	= 4;
  RTCP_SDES_LOC 	= 5;
  RTCP_SDES_TOOL 	= 6;
  RTCP_SDES_NOTE 	= 7;
  RTCP_SDES_PRIV 	= 8;

  // source is declared valid only after MIN_SEQUENTIAL packets have been received in sequence
  MIN_SEQUENTIAL	= 2;
  C_probation_UNINIT	= MIN_SEQUENTIAL shl 5;

  // The dropout parameter MAX_DROPOUT should be a small fraction of the 16-bit sequence
  // number space to give a reasonable probability that new sequence numbers after a restart
  // will not fall in the acceptable range for sequence numbers from before the restart.
  MAX_DROPOUT 		= 3000;

  // After a source is considered valid, the sequence number is considered valid
  // if it is no more than MAX_DROPOUT ahead of s->max_seq nor more than MAX_MISORDER behind.
  MAX_MISORDER 		= 100;


type
  //
  // -- CSRC list: 0 to 15 items, 32 bits each --
  //
  prtp_csrc_list = ^rtp_csrc_list;
  rtp_csrc_list = array[0..15] of u_int32;

  // -- RTP data header --
  prtp_hdr = ^rtp_hdr;
  rtp_hdr = packed record
    //
    r_V_P_X_CC: u_int8;		// version (V): 2 bits - This field identifies the version of RTP. The version defined by this specification is RTP_VERSION (=2).
				// padding (P): 1 bit -- If the padding bit is set, the packet contains one or more additional padding octets at the end which are not part of the payload.
				// extension (X): 1 bit -- If the extension bit is set, the fixed header MUST be followed by exactly one header extension.
				// CSRC count (CC): 4 bits -- The CSRC count contains the number of CSRC identifiers that follow the fixed header.
				//
    r_M_PT: u_int8;		// marker (M): 1 bit -- The interpretation of the marker is defined by a profile.
				// payload type (PT): 7 bits -- This field identifies the format of the RTP payload.
				//
    r_seq_NO: u_int16;     	// sequence number
                                //
    r_timestamp_NO: u_int32;	// If an audio application reads blocks covering 160 sampling periods from the input device,
				// the timestamp would be increased by 160 for each such block, regardless of whether the
				// block is transmitted in a packet or dropped as silent.
				//
    r_ssrc_NO: u_int32;		// synchronization source
				//
    r_csrc: record end; 	// optional CSRC list (see rtp_csrc_list)
  end;

  //
  // -- RTP header extension --
  //
  prtp_hdr_ex = ^rtp_hdr_ex;
  rtp_hdr_ex = packed record
    //
    r_undefined_NO: u_int16;
    r_lenfgth_NO: u_int16;		// counts the number of 32-bit words in the extension,
				// excluding the four-octet extension header (therefore zero is a valid length).
    r_dataEx: record end;
  end;


  // -- RTCP common header word --
  prtcp_common_hdr = ^rtcp_common_hdr;
  rtcp_common_hdr = packed record
    //
    r_V_P_CNT: u_int8;
    r_pt     : u_int8; 		// RTCP packet type
    r_length_NO_: u_int16; 	// pkt len in dwords, w/o this dword
  end;


const
  // Big-endian mask for version, padding bit and packet type pair
  RTCP_VALID_MASK	= $C000 or $2000 or $0FE;
  RTCP_VALID_VALUE	= RTP_VERSION shl 14 or RTCP_SR;


type
  // -- Reception report block --
  prtcp_rr_block = ^rtcp_rr_block;
  rtcp_rr_block = packed record
    //
    r_ssrc_NO: u_int32;		// data source being reported
    r_fraction_NO: u_int8;	// fraction lost since last SR/RR
    r_lost_NO: int24; 		// cumul. no. pkts lost (signed!)
    r_last_seq_NO: u_int32;	// extended last seq. no. received
    r_jitter_NO: u_int32; 	// interarrival jitter
    r_lsr_NO: u_int32; 		// last SR packet from this source
    r_dlsr_NO: u_int32; 	// delay since last SR packet
  end;

  // -- SDES item --
  prtcp_sdes_item = ^rtcp_sdes_item;
  rtcp_sdes_item = packed record
    //
    r_type: u_int8; 	// type of item (rtcp_sdes_type_t)
    length: u_int8; 	// length of item (in octets)
    r_data: record end; // text, not null-terminated
  end;


  // list of sender reports
  rtcp_rr_list = array[0..31] of rtcp_rr_block;


  {*
	RTCP SR packet header
  }
  prtcp_SR_packet = ^rtcp_SR_packet;
  rtcp_SR_packet = packed record
    //
    r_common: rtcp_common_hdr; 	// common header
    //
    // sender report (SR)
    r_ssrc_NO: u_int32; 	// sender generating this report
    r_ntp_NO: unaNTP_timestamp; // NTP timestamp
    r_rtp_ts_NO: u_int32;	// RTP timestamp
    r_psent_NO: u_int32;	// packets sent
    r_osent_NO: u_int32; 	// octets sent
    r_rr: record end; 		// variable-length list (see rtcp_rr_list);
  end;


  {*
	RTCP RR packet header                                                    	
  }
  prtcp_RR_packet = ^rtcp_RR_packet;
  rtcp_RR_packet = packed record
    //
    r_common: rtcp_common_hdr; 	// common header
    //
    // reception report (RR)
    r_ssrc_NO: u_int32; 	// receiver generating this report
    r_rr: record end; 		// variable-length list (see rtcp_rr_list);
  end;


  {*
	RTCP SDES packet header
  }
  prtcp_SDES_packet = ^rtcp_SDES_packet;
  rtcp_SDES_packet = packed record
    //
    r_common: rtcp_common_hdr; 	// common header
    //
    // source description (SDES) chunk #0
    r_ssrc_NO: u_int32; 	// first SSRC/CSRC
    r_items: rtcp_sdes_item;	// list of items followed by each other
  end;

  {*
	RTCP BYE packet header
  }
  prtcp_BYE_packet = ^rtcp_BYE_packet;
  rtcp_BYE_packet = packed record
    //
    r_common: rtcp_common_hdr; 	// common header
    r_ssrc_NO: u_int32; 	// source
    //
    r_text: record end;		// optional reason text
  end;

  {*
	RTCP APP packet header
  }
  prtcp_APP_packet = ^rtcp_APP_packet;
  rtcp_APP_packet = packed record
    //
    r_common: rtcp_common_hdr; 	// common header
    r_ssrc_NO: u_int32; 	// source
    //
    r_cmd: array[0..3] of aChar;// app text
    r_data: record end;		// optional data
  end;


  // -- Per-source state information --
  prtp_site_info = ^rtp_site_info;
  rtp_site_info = packed record
    //
    r_acq: unaObject;
    //
    r_ssrc: u_int32;		// SSRC
    r_cname: prtcp_sdes_item;	// CNAME
    r_max_seq: u_int16;		// highest seq. number seen
    r_cycles: uint64;		// shifted count of seq. number cycles
    r_base_seq: u_int32;	// base seq number
    r_bad_seq: u_int32;		// last 'bad' seq number + 1
    r_probation: u_int32;	// sequ. packets till source is valid
    r_received: u_int32;	// packets received
    r_expected_prior: u_int32;	// packet expected at last interval
    r_received_prior: u_int32;	// packet received at last interval
    r_transit: u_int32;		// relative trans time for prev pkt
    r_jitter: u_int32;		// estimated jitter
    //
    r_rtt: uint32;		// last evaluated round-time trip (or 0 if unknown)
    r_rttMagic: uint32;		// magic from our last request
    r_rttTMU: uint64;		// rtt timer
    //
    r_remoteAddrRTCPValid: bool;	// remote addr structure is OK and valid
    r_remoteAddrRTCP: sockaddr_in;	// remote RTCP address
    //
    r_remoteAddrRTPValid: bool;		// remote RTP addr structure is OK and valid
    r_remoteAddrRTP: sockaddr_in;	// remote RTP address
    //
    r_lastSRreceived: u_int32;	// The middle 32 bits out of 64 in the NTP timestamp (as explained in Section 4)
				//   received as part of the most recent SR packet from that site.
    r_lastSRreceivedTM: uint64;	// time mark of last SR from this member
    r_lastRRreceivedTM: uint64;	// time mark of last RR from this member
    //
    r_timedout: bool;		// looks like this member is dead (but not sure yet)
    r_hardBye: bool;		// got BYE packet from this member
    r_byeReported: bool;	// BYE packet reported to RTP receiver
    //
    r_lastPayloadTM: uint64;    // time mark of last payload (RPT) packet
    r_heardOf: bool;		// have we heard from it since last RR?
    //
    r_isSender: bool;		// member is currently a sender?
    //
    r_noRRsinceLastReport: bool;// we have not received RR since last RTCP?
    //
    r_stat_lost: uint64;	// lost packets (for statistic only)
    r_stat_received: uint64;	// packets received (long version)
    //
    r_stat_lost_prev: uint64;		// internal
    r_stat_received_prev: uint64;	// internal
    r_stat_lostPercent: uint64;	// % of lost packets since last update
  end;


// -- end of rtp.h --


const
   // recognized audio encodings
   // NOTE: these are NOT payloads!
  c_rtp_enc_DVI4	= 1;
  c_rtp_enc_G722	= 2;
  c_rtp_enc_G723	= 3;
  c_rtp_enc_G726_40	= 4;
  c_rtp_enc_G726_32	= 5;
  c_rtp_enc_G726_24	= 6;
  c_rtp_enc_G726_16	= 7;
  c_rtp_enc_G728	= 8;
  c_rtp_enc_G729	= 9;
  c_rtp_enc_G729D	= 10;
  c_rtp_enc_G729E	= 11;
  c_rtp_enc_GSM		= 12;
  c_rtp_enc_GSM_EFR	= 13;
  c_rtp_enc_L8		= 14;
  c_rtp_enc_L16		= 15;
  c_rtp_enc_LPC		= 16;
  c_rtp_enc_MPA		= 17;
  c_rtp_enc_PCMA	= 18;
  c_rtp_enc_PCMU	= 19;
  c_rtp_enc_QCELP	= 20;
  c_rtp_enc_VDVI	= 21;
  //
  // other encodings (not payloads!)
  c_rtp_enc_Speex	= 101;	// Speex
  c_rtp_enc_Vorbis	= 102;	// OGG/Vorbis
  c_rtp_enc_T140	= 103;	// T140 text terminal
  c_rtp_enc_CELT	= 104;	// CELT
  c_rtp_enc_GSM49	= 105;  // MS GSM
  c_rtp_enc_G7221	= 106;  // G.722.1


  // payloads
  //   PT   encoding                clock rate   channels
  //        name                    (Hz)
  //   ___________________________________________________
  //   0    PCMU                     8,000       1
  c_rtpPTa_PCMU		= 0;	// uLaw
  //   1    reserved
  //   2    reserved
  //   3    GSM                      8,000       1
  c_rtpPTa_GSM		= 3;
  //   4    G723                     8,000       1
  c_rtpPTa_G723		= 4;
  //   5    DVI4                     8,000       1
  c_rtpPTa_DVI4_8000	= 5;
  //   6    DVI4                    16,000       1
  c_rtpPTa_DVI4_16000	= 6;
  //   7    LPC                      8,000       1
  c_rtpPTa_LPC		= 7;
  //   8    PCMA                     8,000       1
  c_rtpPTa_PCMA		= 8;	// ALaw
  //   9    G722                     8,000       1
  c_rtpPTa_G722_		= 9;
  //   10   L16                     44,100       2
  c_rtpPTa_L16_stereo	= 10;
  //   11   L16                     44,100       1
  c_rtpPTa_L16_mono	= 11;
  //   12   QCELP                    8,000       1
  c_rtpPTa_QCELP	= 12;
  //   13   CN                       8,000       1
  c_rtpPTa_CN		= 13;
  //   14   MPA                     90,000       (see text)
  c_rtpPTa_MPA		= 14;	// mpeg audio
  //   15   G728                     8,000       1
  c_rtpPTa_G728		= 15;
  //   16   DVI4                    11,025       1
  c_rtpPTa_DVI4_11025	= 16;
  //   17   DVI4                    22,050       1
  c_rtpPTa_DVI4_22050	= 17;
  //   18   G729                     8,000       1
  c_rtpPTa_G729		= 18;
  //   19   reserved    A
  //   20   unassigned  A
  //   21   unassigned  A
  //   22   unassigned  A
  //   23   unassigned  A
  //   dyn  G726-40     A            8,000       1
  //   dyn  G726-32     A            8,000       1
  //   dyn  G726-24     A            8,000       1
  //   dyn  G726-16     A            8,000       1
  //   dyn  G729D       A            8,000       1
  //   dyn  G729E       A            8,000       1
  //   dyn  GSM-EFR     A            8,000       1
  //   dyn  L8          A            var.        var.
  //   dyn  RED         A                        (see text)
  //   dyn  VDVI        A            var.        1
  //
  //   Table 4: Payload types (PT) for audio encodings


  //   PT      encoding    media type  clock rate
  //           name                    (Hz)
  //   _____________________________________________
  //   24      unassigned  V
  //   25      CelB        V           90,000
  c_rtpPTv_CelB		= 25;
  //   26      JPEG        V           90,000
  c_rtpPTv_JPEG		= 26;
  //   27      unassigned  V
  //   28      nv          V           90,000
  c_rtpPTv_nv		= 28;
  //   29      unassigned  V
  //   30      unassigned  V
  //   31      H261        V           90,000
  c_rtpPTv_H261		= 31;
  //   32      MPV         V           90,000
  c_rtpPTv_MPV		= 32;
  //   33      MP2T        AV          90,000
  c_rtpPTav_MP2T	= 33;
  //   34      H263        V           90,000
  c_rtpPTv_H263		= 34;
  //   35-71   unassigned  ?
  //   72-76   reserved    N/A         N/A
  //   77-95   unassigned  ?
  //   96-127  dynamic     ?
  //   dyn     H263-1998   V           90,000
  //
  //   Table 5: Payload types (PT) for video encodings

  c_rtpPT_dynamic		= 96;	// first dynamic payload


  /// default RTP port
  c_RTP_PORT_Default	 	= 5004;


const
// ========= LoS specific (non-standard!) ========================

  //
  c_rtcp_appCmd_RTT		= '_RTT';	// query/reply _RTT
  c_rtcp_appCmd_hello		= 'HELO';	// hi from remote side
  c_rtcp_appCmd_needRTPPing	= 'NPNG';	// need RTP pingback

  //
  c_rtcp_appCmd_RTT_stRequest	= 1;	// rtt request
  c_rtcp_appCmd_RTT_stResponse	= 2;	// rtt response

  //
  c_def_CNresendInterval	= 12000;

type
  {*
	RTT REQ/RESP data
	LE order
  }
  punaRTCPRTTReq = ^unaRTCPRTTReq;
  unaRTCPRTTReq = packed record
    //
    r_tmU: uint64;	// timemark
    r_magic: uint32;	// our magic random data
    r_srcSSRC: u_int32;	// our SSRC
    r_dstSSRC: u_int32; // SSRC in question
  end;


  {*
	List of Sources.
  }
  unaRTCPSourceList = class(unaIDList)
  protected
    function getId(item: pointer): int64; override;
    procedure releaseItem(index: int; doFree: unsigned); override;
  public
    function indexByAddrRTCP_(const addr: sockaddr_in): int;
    function indexByAddrRTP_(const addr: sockaddr_in): int;
  end;


  // forward
  unaRTPStreamer = class;

  {*
	Basic RTCP stack (UDP only)
  }
  unaRTCPstack = class(unaThread)
  private
    f_b2portRTCP: string;
    //
    f_outBuf: pArray;
    f_outBufSize: unsigned;
    //
    f_members: unaRTCPSourceList;
    f_socket_U: unaUDPSocket;
    f_socket_M: unaMulticastSocket;
    f_socket_T: unaTCPSocket;
    //
    f_readyEv: unaEvent;
    //
    f_socketError: int;
    f_streamer: unaRTPStreamer;
    //
    f_seq: int;	/// our last seq #
    //
    f_tp: uint64; 	/// the last time an RTCP packet was transmitted;
    f_tc: uint64;	/// the current time;
    f_tn: unsigned;     /// the next scheduled transmission time of an RTCP packet;
    f_pmembers: int; 	/// the estimated number of session members at the time tn was last recomputed;
    //f_members: int; 	/// the most current estimate for the number of session members;
    f_senders: unaAcquireType; 	/// the most current estimate for the number of senders in the session;
    f_rtcp_bw: int; 	/// The target RTCP bandwidth, i.e., the total bandwidth that will be used for RTCP
			/// packets by all members of this session, in octets per second.
			/// This will be a specied fraction of the "session bandwidth" parameter supplied
			/// to the application at startup.
    f_we_sent: unaAcquireType;	/// Flag that is true ( < 0) if the application has sent data since the 2nd previous RTCP report was transmitted.
    f_we_sentEver: bool;	/// Have we sent anything at all?
    f_avg_rtcp_size: int;	/// The average compound RTCP packet size, in octets, over all RTCP packets sent
				/// and received by this participant.
    f_initial: bool;	/// Flag that is true if the application has not yet sent an RTCP packet.
    f_C: int;
    f_Tmin: int;
    f_Td: int;	        /// deterministic calculated interval
    f_T: int;
    f_n: int;           /// usually = members - senders
    //
    f_rtpTS_no: uint32;		// RTP timestamp (already in network order)
    //
    f_rtpPCount: uint32;	// total number of RTP packets sent
    f_rtpPSize: uint32;		// total number of RTP payload octets sent
    //
    f_idleThread: unaThread;	// thread for RTCP timer stuff
    //
    f_rttEnabled: bool;		// rtt support
    f_rttLastIndex: int;	// last SI index we have sent rtt request to
    //
    f_lastRRIndex: int;         // last member index reported (if we have many members to report to)
    //
    f_memberTR: int;            // timeout reports
    f_confMode: bool;
    //
    f_acar: bool;
    //
    function calcTI(): unsigned;
    function sendRTCP(bye: bool = false): bool;
    //
    procedure timeoutMembers();
    procedure checkRTT();
    //
    procedure issueSRhdr(var ofs: int);
    procedure issueRRhdr(var ofs: int);
    procedure issueBYEhdr(var ofs: int);
    procedure issueRRBlock(var ofs: int; si: prtp_site_info);
    function  issueSDES(var ofs: int; probe: bool; altBuf: pointer = nil): int;
    //
    procedure ensureMember(ssrc: u_int32; addr: PSockAddrIn);
    function getSocket(): unaSocket;
  protected
    {*
	Returns member info.
	Always call memberRelease() when done working with member.

	@param index Member index from 0 to memberCount - 2
	@param ro Read-only (True) or write-only (False) acquire
	@return Session member or nil.
    }
    function memberByIndexAcq(index: int; ro: bool; timeout: tTimeout = 100): prtp_site_info;
    {*
	Returns number of memebers. When active there is always one member - we.
    }
    function getMemberCount(): int;
    {*
	Should be called to maintain RTCP sanity just after new RTP packet was sent.
    }
    procedure weSentRTP(addr: PSockAddrIn; hdr: prtp_hdr; payloadLen: uint);
    {*
	Received new RTCP packet.
    }
    procedure gotPacket(addr: PSockAddrIn; hdr: prtcp_common_hdr; packetSize: uint; firstOne: bool); virtual;
    {*
	Received new RTP packet.
    }
    procedure gotRTPpacket(addr: pSockAddrIn; hdr: prtp_hdr; packetSize: uint); virtual;
    {*
	Time to send RTCP packets (if needed).
    }
    procedure gotIdle(); virtual;
    {*
	Received new RTCP SR packet.
    }
    procedure updateOnSR(addr: PSockAddrIn; hdr: prtcp_SR_packet);
    {*
	Received new RTCP RR packet.
    }
    procedure updateOnRR(addr: PSockAddrIn; hdr: prtcp_RR_packet);
    {*
	Received new RTCP SDES packet.
    }
    procedure updateOnSDES(ssrc: u_int32; item: prtcp_sdes_item); overload;
    {*
	Received APP packet.
    }
    procedure udapteOnAPP(addr: PSockAddrIn; hdr: prtcp_APP_packet; subtype: int; const cmd: aString; data: pointer; size: int); virtual;
    {*
	Creates new session member record.
	Locks new member with WO access, so it must be released by memberReleaseWO()

	@param ssrc SSRC to assign to new member
	@return member info
    }
    function newMemberAcq(ssrc: u_int32): prtp_site_info;
    {*
    }
    procedure init_seq(si: prtp_site_info; seq: u_int16);
    {*
    }
    function update_seq(ssrc: u_int32; seq: u_int16): bool;
    {*
    }
    procedure startIn(); override;
    {*
    }
    procedure startOut(); override;
    {*
	Runs RTCP receiving socket cycle.
	Calls gotPacket() each time new chunk of bytes is received.
    }
    function execute(threadID: unsigned): int; override;
    {*
	Returns next RTP seq#
    }
    function getNextSeq(): unsigned;
    {*
	Sends data using RTCP socket

	@return 0 if data was sent successfully, or specific WSA error otherwise.
    }
    function sendDataRTCP(addr: PSockAddrIn; data: pointer; len: uint): int;
    //
    // --- properties ---
    //
    {*
	Internal socket object
    }
    property socketObjRTCP: unaSocket read getSocket;
  public
    {*
	Creates RTCP stack
    }
    constructor create(streamer: unaRTPStreamer; useNTP: bool = false);
    {*
	Cleans the instance.
    }
    procedure BeforeDestruction(); override;
    {*
	Returns member info.
	Always call memberRelease() when done working with member.

	@param ssrc SSRC of member
	@return Session member or nil.
    }
    function memberBySSRCAcq(ssrc: u_int32; ro: bool; timeout: tTimeout = 100): prtp_site_info;
    {*
	Returns member info.
	Always call memberRelease() when done working with member.

	@param addr RTP/RTCP address of member
	@return Session member or nil.
    }
    function memberByAddrAcq(isRTP: bool; addr: PSockAddrIn; ro: bool; timeout: tTimeout = 100): prtp_site_info;
    {*
	Returns member SSRC by index.

	@param index member index
	@param ssrc SSRC of member
	@return True if successfull
    }
    function memberSSRCbyIndex(index: int; out ssrc: u_int32): bool;
    {*
	Releases member info after RO acquision..
	Must always be called after memberGet().

	@param member Member to release.
    }
    procedure memberReleaseRO(member: prtp_site_info);
    {*
	Releases member info after WO acquision.
	Must always be called after successfull memberByXXX().

	@param member Member to release.
    }
    procedure memberReleaseWO(member: prtp_site_info);
    {*
	Copies member info.

	@param ssrc SSRC of memeber
	@param info Buffer to copy to
	@return True if successfull
    }
    function copyMember(ssrc: u_int32; var info: rtp_site_info): bool;
    {*
	Returns member timeout. If memberTimeoutReports is not 0 and no RR will be received from
	this member after memberTimeoutReports reports, BYE will be sent to remote side and
	it will be removed from the members table.

	@param ssrc SSRC of member
	@return Timeout in ms.
    }
    function getMemberTimeout(ssrc: u_int32): int;
    {*
	Returns member CNAME.

	@param ssrc SSRC of member
	@return CNAME or ''
    }
    function getMemberCNAME(ssrc: u_int32; out cname: wString): bool;
    {*
	Returns current NTP time if available.

	@param st Time structure to be filled with current date/time
	@return True if successfull
    }
    function timeNTPnow(var st: SYSTEMTIME): bool;
    {*
	Sends custom APP packet to remote side.

	@param addr	send to this addr
	@param subtype	subtype (0..31)
	@param cmd	command (4 ansi chars)
	@param data	data data pointer
	@param len	size of data
	@param sendCNAMEasWell	include SDES packet as well

	@return 0 if data was sent successfully, or specific WSA error otherwise.
    }
    function sendAPPto(addr: PSockAddrIn; subtype: byte; const cmd: aString; data: pointer = nil; len: uint = 0; sendCNAMEasWell: bool = false): int;
    //
    // -- properties --
    //
    {*
	Port number to receive RTCP payload on.
    }
    property bind2port: string read f_b2portRTCP write f_b2portRTCP;
    {*
    }
    property socketError: int read f_socketError;
    {*
	RTP transport.
    }
    property streamer: unaRTPStreamer read f_streamer;
    {*
	Number of session members.
    }
    property memberCount: int read getMemberCount;
    {*
	Number of reports for session member to timeout.
	Default value is 6, means a member will be removed from table if 6 successive reports are missing from it.
	Set to 0 to disable timeout check.
    }
    property memberTimeoutReports: int read f_memberTR write f_memberTR;
    {*
	When in conference mode, client should send RTCP packets to conference server only.
    }
    property conferenceMode: bool read f_confMode write f_confMode;
    {*
	When true (default) will query for and reply on RTT requests.
    }
    property rttEnabled: bool read f_rttEnabled write f_rttEnabled;
    {*
	Last seq#, mostly for stat display.
    }
    property seqNum: int read f_seq;
    {*
	Resolve remote address change automatically.
	Default is true.
    }
    property addrChangeAutoResolve: bool read f_acar;
  end;


  {*
	TCP peer roles (client or server)
  }
  c_peer_role	= (pr_none, pr_active, pr_passive, pr_actpass, pr_holdconn);


  {*
	Basic RTP streamer.
  }
  unaRTPStreamer = class(unaThread)
  private
    f_noRTCP: bool;
    f_isRAW: bool;
    //
    f_socketNoReading: bool;
    //
    f_ssrc: u_int32;
    f_ssrcParent: u_int32;
    f_cname8: aString;
    f_userName: wString;
    //
    f_isUDP: bool;
    f_isMC: bool;
    f_role: c_peer_role;
    //
    f_pingsockInProgress: bool;
    f_pingsockDone: bool;
    f_socket_UCP: unaSocket;
    f_socketError: int;
    f_ttl: int;
    f_mcport: word;
    //
    f_rtcp: unaRTCPstack;
    //
    f_active: bool;
  protected
    {*
	"Pings" main listening socket so it will return from select().
    }
    function grantStop(): bool; override;
    {*
	Sends 1 byte to main listening socket so it will return from select() immediately.
    }
    procedure pingsock();
    {*
	Streamer (like transmitter) could have own set of destinations, give it a chance to push RTCP data over
    }
    procedure onRTCPPacketSent(packet: pointer; len: uint); virtual;
    {*
	New RTP packed was received.

	@param addr Remote address packet was received from.
	@param hdr RTP packet header.
	@param data Packet payload.
	@param len Payload size.
	@param packetSize Packet size including padding.
    }
    procedure onPayload(addr: PSockAddrIn; hdr: prtp_hdr; data: pointer; len, packetSize: uint); virtual;
    {*
	Called from RTCP thread when new RTCP packed was received.

	@param ssrc Generator of packet
	@param addr Remote address packet was received from.
	@param hdr RTCP packet header.
	@param packetSize Packet size including padding.
    }
    procedure onRTCPPacket(ssrc: u_int32; addr: PSockAddrIn; hdr: prtcp_common_hdr; packetSize: uint); virtual;
    {*
	Called each time new packet is sent to remote side

	@param rtcp true if that was RTCP payload
	@param data data sent
	@param len size of data sent
    }
    procedure onDataSent(rtcp: bool; data: pointer; len: uint); virtual;
    {*
	Called from RTCP thread when SDES packet was received.
    }
    procedure onSsrcCNAME(ssrc: u_int32; cname: prtcp_sdes_item); virtual;
    {*
	Called from RTCP thread when BYE packet was received.
    }
    procedure onBye(si: prtp_site_info; soft: bool); virtual;
    {*
	Called from context of idle thread.
    }
    procedure onIdle(rtcpIdle: bool); virtual;
    {*
	Thread just started.
    }
    procedure startIn(); override;
    //
    {*
	Use rentSockets() to enable/disable
    }
    property socketNoReading: bool read f_socketNoReading;
    {*
	Internal socket.
    }
    property in_socket: unaSocket read f_socket_UCP;
  public
    procedure AfterConstruction(); override;
    procedure BeforeDestruction(); override;
    //
    {*
	Disables or enables internal sockets from reading.
	Some clients (like STUN) may need to disable sockets for short time.
    }
    procedure rentSockets(doRent: bool);
    //
    // -- properties --
    //
    {*
	SSRC
    }
    property _SSRC: u_int32 read f_ssrc;
    {*
	UTF8 version of CNAME
    }
    property cname8: aString read f_cname8;
    {*
	@True if receiver is RAW (no RTP/RTCP will be used).
    }
    property isRAW: bool read f_isRAW write f_isRAW;
    {*
	@True if receiver uses UDP transport, @false for TCP.
    }
    property isUDP: bool read f_isUDP;
    {*
	@True if multicast, @false for unicast.
    }
    property isMulticast: bool read f_isMC;
    {*
	@True if no RTCP support is required.
    }
    property noRTCP: bool read f_noRTCP write f_noRTCP;
    {*
	@True when receiver is active. Set to @False to close receiver.
    }
    property active: bool read f_active;
    {*
	Last socket error. 0 if no error.
    }
    property socketError: int read f_socketError;
    {*
	RTCP user name. Default is className.
    }
    property userName: wString read f_userName write f_userName;
    {*
	RTCP stack. Could be nil.
    }
    property rtcp: unaRTCPstack read f_rtcp;
    {*
	TTL value (mostly for multicast)
    }
    property ttl: int read f_ttl write f_ttl;
  end;


  {*
	Fired when new destination is added, either manually or from hole

	@param sender transmitter
	@param fromHole was dest added manually or from "hole" packet
	@param dest destination
	@param accept Accept or decline new destination
  }
  unaRTPOnAddDestination = procedure(sender: tObject; fromHole: boolean; destRTP, destRTCP: PSockAddrIn; var accept: boolean) of object;


  // forward class declaration
  unaRTPTransmitter = class;


  {*
	Basic RTP receiver
  }
  unaRTPReceiver = class(unaRTPStreamer)
  private
    f_tcp_clients: unaList;
    //
    f_tcp_buf: pointer;
    f_tcp_bufSize: int;
    f_tcp_bufLock: unaObject;
    //
    f_bind2port: string;
    f_bind2ip: string;
    //
    f_ip: string;
    f_lastIdleCheckIndex: int;
    //
    f_CN_resendInterval: int;
    //
    f_isServer: bool;
    f_broken: int;
    f_portL: string;
    //
    f_transmitter: unaRTPTransmitter;
  protected
    {*
	Should be called just after new RTP packet was sent.
    }
    procedure weSent(addr: PSockAddrIn; data: pointer; len: uint);
    //
    procedure startIn(); override;
    procedure startOut(); override;
    function execute(threadID: unsigned): int; override;
    //
    {*
	Notifies transmitter (if any) on RTP packet
    }
    procedure onPayload(addr: PSockAddrIn; hdr: prtp_hdr; data: pointer; len, packetSize: uint); override;
    {*
	Notifies transmitter (if any) on CNAME packet received from remote side
    }
    procedure onSsrcCNAME(ssrc: u_int32; cname: prtcp_sdes_item); override;
    {*
	Notifies transmitter (if any) on BYE packet received from remote side
    }
    procedure onBye(si: prtp_site_info; soft: bool); override;
    {*
	Override to send RTP_CN to destinataion to make a hole or perform some other required action
    }
    procedure onNeedRTPHole(si: prtp_site_info); virtual;
    {*
	New RTCP packed was received.

	@param ssrc Generator of packet
	@param addr Remote address packet was received from.
	@param hdr RTCP packet header.
	@param packetSize Packet size including padding.
    }
    procedure onRTCPPacket(ssrc: u_int32; addr: PSockAddrIn; hdr: prtcp_common_hdr; packetSize: uint); override;
    {*
	Called from context of idle thread.
    }
    procedure onIdle(rtcpIdle: bool); override;
    {*
	Notify transmitter (if any) of new RTCP packet
    }
    procedure onRTCPPacketSent(packet: pointer; len: uint); override;
    {*
	Sends data over TCP socket.

	@param addr remote address to send data to
	@param packet full packet data, including header
	@param packetSize size of packet data
	@param lenAlreadyPrefixed @True if data buffer is already prefixed with 2-bytes (network order) length field

	@return 0 if succesfull, socket error code otherwise
    }
    function sendTCPData_To(addr: PSockAddrIn; packet: pointer; packetSize: uint; lenAlreadyPrefixed: bool): int;
  public
    {*
	Creates a new receiver instance.

	@param bind2addr bind to this local address
	@param remoteAddr use this address as session address. Could be nil, in which case will use bind2addr as session address.
	@param noRTCP Disable RTCP if @true
	@param transmitter Master transmitter (if any)
	@param ttl TTL for multicast
	@param isUDP @True for UDP, @False for TCP
	@param isRAW true if non-RTP streaming
	@param role TCP role (client or server)
    }
    constructor create(const bind2addr: TSockAddrIn; remoteAddr: PSockAddrIn = nil; noRTCP: bool = false; transmitter: unaRTPTransmitter = nil; ttl: int = -1; isUDP: bool = true; isRAW: bool = false; role: c_peer_role = pr_none); overload;
    {*
	Creates a new instance without a socket.
    }
    constructor create(isRAW: bool = false); overload;
    {*
	Initializes required fields
    }
    procedure AfterConstruction(); override;
    {*
    }
    procedure BeforeDestruction(); override;
    {*
	Sends RTP CN (comfort noise) packet (payload = c_rtpPTa_CN) to remote side.
	Used mostly at beginning of streaming to make holes in NAT.

	@param addr Remote address to send packet to
	@return 0 if successfull or winsock error code otherwise.
    }
    function sendRTP_CN_To(addr: PSockAddrIn): int;
    {*
	Constructs RTP header, and sends RTP payload packet to remote side.

	@param addr Remote address to send data to
	@param payloadType type of payload in packet
	@param payload payload buffer
	@param len size of payload
	@param mark put mark flag
	@return 0 if successfull or winsock error code otherwise.
    }
    function sendRTP_To(addr: PSockAddrIn; payloadType: byte; payload: pointer; len: int; mark: bool): int;
    {*
	Updates SSRC property.
    }
    procedure setNewSSRC(newssrc: u_int32);
    //
    // -- properties --
    //
    {*
	Port number (to receive RTP payload on).
	In case of TCP socket - remote port number to connect to.
    }
    property bind2port: string read f_bind2port;
    {*
	Bind to this interface (default is 0.0.0.0 means bind to all interfaces).
    }
    property bind2ip: string read f_bind2ip;
    {*
	Actual local RTP port number used in this session.
	Could be used to get port number assigned by system when bind2port property is 0.
    }
    property portLocal: string read f_portL;
    {*
	True if TCP server.
    }
    property isServer: bool read f_isServer;
    {*
	In case of multicast - group IP
	In case of unicast UDP/TCP sockets - remote host IP (set to '0.0.0.0' for TCP server)
    }
    property ip: string read f_ip;
    {*
	Re-send interval for CN packets.
	Set to 0 to disable sending packets.
    }
    property CN_resendInterval: int read f_CN_resendInterval write f_CN_resendInterval;
  end;


  {*
	RTP Destiation.
	Could be unicast/multicast UDP.
  }
  unaRTPDestination = class(unaObject)
  private
    f_trans: unaRTPTransmitter;
    f_msocket: unaMulticastSocket;	// multicast dest
    f_bsocket: unaUDPSocket;		// broadcast dest
    f_mgroup: string;
    //
    f_destAddrRTP,
    f_destAddrRTCP: sockaddr_in;
    f_scope: int;
    f_recSSRC: uint32;
    //
    f_isOpen: bool;
    f_enabled: bool;
    f_socketOwned: bool;	// do not create socket, use receiver
    //
    f_ttl: int;
    f_dstatic: bool;
    //
    f_lastRRTM: uint64;		// time mark of last RR received, reporting about this destination
    f_closeOnBye: bool;
    //
    function makeAddr(const destHost, destPortRTP, destPortRTCP: string): bool;
    procedure setupSocket();
    function getAddrRTP(): PSockAddrIn;
    function getAddrRTCP(): PSockAddrIn;
    procedure setTTL(value: int);
  protected
    {*
	Opens destination
    }
    procedure open();
    {*
	Closes destination
    }
    procedure close();
  public
    {*
	Creates new destination with specified destHost, destPort, etc
	Will not create own socket (assuming usage of receiver's socket)
    }
    constructor create(dstatic: bool; trans: unaRTPTransmitter; const destHost, destPortRTP, destPortRTCP: string; doOpen: bool = false; ttl: int = -1; recSSRC: uint32 = 0); overload;
    {*
	Creates new destination with specified addrRTP, etc
	Will not create own socket (assuming usage of receiver's socket)
    }
    constructor create(dstatic: bool; trans: unaRTPTransmitter; addrRTP, addrRTCP: PSockAddrIn; doOpen: bool = false; ttl: int = -1; recSSRC: uint32 = 0); overload;
    {*
	Creates new destination which will work only through transmiter's receiver's socket.
	Will create own socket
    }
    constructor create(dstatic: bool; trans: unaRTPTransmitter; const ipN: TIPv4N); overload;
    {*
	Releases sockets.
    }
    procedure BeforeDestruction(); override;
    {*
	Transmits data to remote destination.

	Return 0 for success, or socket-specific error code otherwise.
    }
    function transmit(data: pointer; len: uint; isRTCP: bool = false; tcpLenAlreadyPrefixed: bool = false): int;
    {*
	Check if provided address is the same as of destination
    }
    function sameAddr(isRTP: bool; const addr: sockaddr_in; checkIPOnly: bool = false): bool;
    //
    // -------
    {*
	0 - unicast
	1 - broadcast
	2 - multicast
    }
    property scope: int read f_scope;
    {*
	Remote RTP addr.
    }
    property addrRTP: PSockAddrIn read getAddrRTP;
    {*
	Remote RTCP addr.
    }
    property addrRTCP: PSockAddrIn read getAddrRTCP;
    {*
	SSRC of receiver (if known)
    }
    property recSSRC: uint32 read f_recSSRC;
    {*
	Data streaming is enabled?
    }
    property enabled: bool read f_enabled write f_enabled;
    {*
	TTL
    }
    property ttl: int read f_ttl write setTTL;
    {*
	True for static (persistent), false for dynamic destination.
	Dynamic destination will be removed upon streamer's close() or when BYE is received.
	Static destination will be closed on BYE (if closeOnBye is True), but will be re-opened on HELLO. It will also survive streamer's close().
    }
    property dstatic: bool read f_dstatic;
    {*
	True if destination transport is ready
    }
    property isOpen: bool read f_isOpen;
    {*
	Default if false.
    }
    property closeOnBye: bool read f_closeOnBye;
  end;


  {*
	Basic RTP transmitter
  }
  unaRTPTransmitter = class(unaObject)
  private
    f_isRAW: bool;
    //
    f_bind2ip: string;
    f_bind2port: string;
    //
    f_hdr: rtp_hdr;
    f_timestamp: uint32;
    f_sendBuf: pointer;
    f_sendBufSize: unsigned;
    f_isTranslator: bool;
    f_socketError: int;
    //
    f_paused: bool;
    //
    f_ttl: int;
    //
    f_payload: int;
    f_RTPclockRate: unsigned;
    f_sr: unsigned;
    //
    f_destinations: unaObjectList;
    f_lastDestTOCheckTM: uint64;
    //
    f_rtpPing: bool;
    f_rtpPingTM: uint64;     // "RTP Ping" timer
    //
    f_seq: int;	/// last seq #
    //
    f_receiver: unaRTPReceiver;
    //
    f_onAddDest: unaRTPOnAddDestination;
    //
    function getSsrc(): u_int32;
    procedure setPayload(value: int);
    function getActive(): bool;
    procedure setActive(value: bool);
    function getRTCP(): unaRTCPstack;
    function getDest(index: int): unaRTPDestination;
    {*
	If got disconnected for unknown reason, check this function first.
    }
    procedure checkDestTimeouts(SSRC: uint32; rr: prtcp_rr_block = nil; rrCount: int = 0; rtcpAddr: PSockAddrIn = nil);
    {*
	Returns next RTP seq#
    }
    function getNextSeq(): unsigned;
  protected
    {*
	Transmitter could have own set of destinations, give it a chance to push RTCP data over
    }
    procedure onRTCPPacketSent(packet: pointer; len: uint); virtual;
    {*
    }
    function doOpen(waitForThreadsToStart: bool = true): bool; virtual;
    {*
    }
    procedure doClose(); virtual;
    {*
    }
    procedure onPayload(addr: PSockAddrIn; hdr: prtp_hdr; data: pointer; len, packetSize: uint); virtual;
    {*
    	Override to get notified on remote SDES items received
    }
    procedure onSsrcCNAME(ssrc: u_int32; cname: prtcp_sdes_item); virtual;
    {*
	New RTCP packed was received.

	@param ssrc Generator of packet
	@param addr Remote address packet was received from.
	@param hdr RTCP packet header.
	@param packetSize Packet size including padding.
    }
    procedure onRTCPPacket(ssrc: u_int32; addr: PSockAddrIn; hdr: prtcp_common_hdr; packetSize: uint); virtual;
    {*
	Called from context of receiver thread.
    }
    procedure notifyBye(si: prtp_site_info; soft: bool); virtual;
    {*
	Called from context of idle thread.
    }
    procedure onIdle(rtcpIdle: bool); virtual;
    {*
	Called just before adding a new destination.
	Fires onAddDest if assigned, otherwise always return True
	Override for different behaviour

	@param dest Destination to be added
	@param fromHole destination was obtained from "hole" packet
	@return True if it is OK to add this destination
    }
    function okAddDest(destRTP, destRTCP: PSockAddrIn; fromHole: bool): bool; virtual;
  public
    {*
	Creates a new instance of IPTransmitter.

	@param payload payload to assign by default on transmitted packets
	@param isRAW non-RTP sockets
	@param noRTCP disable/enable RTCP stack
	@param bind2addr bind socket to this local ip:port, if nil, will bind to 0.0.0.0:0
	@param ttl assign this TTL
	@param primaryDest primary destination. If nil, transmitter will add fixed destination. In case of multicast, push data to this remote address or join this multicast group
	@param isUDP Use UDP or TCP transport
    }
    constructor create(const bind2addr: TSockAddrIn; payload: int; isRAW: bool = false; noRTCP: bool = false; ttl: int = -1; primaryDest: PSockAddrIn = nil; isUDP: bool = true; role: c_peer_role = pr_none);
    {*
	Releases destinations and other resources.
    }
    procedure BeforeDestruction(); override;
    {*
	Adds new destination for transmission.

	@returns index of just added destination.
    }
    function destAdd(dstatic: bool; const uri: string; doOpen: bool = false; ttl: int = -1; recSSRC: uint32 = 0): int; overload;
    {*
	Adds new destination for transmission.

	@returns index of just added destination.
    }
    function destAdd(dstatic: bool; const remoteHost, remotePortRTP, remotePortRTCP: string; doOpen: bool = false; ttl: int = -1; recSSRC: uint32 = 0; fromHole: bool = false): int; overload;
    {*
	Adds new destination for transmission.

	@return index of new dest
    }
    function destAdd(dstatic: bool; addrRTP, addrRTCP: PSockAddrIn; doOpen: bool = false; fromHole: bool = false; recSSRC: uint32 = 0): int; overload;
    {*
	Adds new destination for transmission.
	It will use receiver's socket for communication.
	This method is mostly used for multicast sockets.

	@return index of new dest
    }
    function destAdd(dstatic: bool; const ipN: TIPv4N): int; overload;
    {*
	Checks if specified dest was already added.

	@return True if dest already exsits
    }
    function destHas(const addr: sockaddr_in): bool;
    {*
	Temporarely enables/disables streaming to specified destination.
    }
    procedure destEnable(index: int; doEnable: bool); overload;
    {*
	Temporarely enables/disables streaming to specified destination.
    }
    procedure destEnable(const uri: string; doEnable: bool); overload;
    {*
	Returns number of destinations.
    }
    function destGetCount(): int;
    {*
	Removes destination.
    }
    procedure destRemove(index: int); overload;
    {*
	Removes destination.
    }
    procedure destRemove(dest: unaRTPDestination); overload;
    {*
	Removes destination.
    }
    procedure destRemove(const addrRTP: sockaddr_in); overload;
    {*
	Removes destination.
    }
    procedure destRemove(const uri: string); overload;
    {*
	Returns destination by index. Acquires it as well.
    }
    function destGetAcq(index: int; ro: bool): unaRTPDestination; overload;
    {*
	Returns destination by RTP address. Acquires it as well.
    }
    function destGetAcq(const addrRTP: sockaddr_in; ro: bool): unaRTPDestination; overload;
    {*
	Opens transmitter.
    }
    function open(waitForThreadsToStart: bool = true): bool;
    {*
	Closes transmitter.
    }
    procedure close(clearAllDest: bool = false);
    {*
	Transmits data over RTP. Adds RTP header if required.

	@param samplesDelta samples taken since last transfer
	@param data payload data
	@param len size of data buffer in bytes
	@param marker marker bit value. Default if 0
	@param tpayload override payload. Default is -1, means use payload property
	@param addr send to this address only. Default is nil, means send to all destinations

	@return number of bytes actually sent to network
    }
    function transmit(samplesDelta: uint; data: pointer; len: uint; marker: bool = false; tpayload: int = -1; addr: PSockAddrIn = nil; prebufData: pointer = nil; prebufDataLen: uint = 0; updateWeSent: bool = true): int;
    {*
	Re-transmits data to all destinations.
	Assumes data is already points to RTP header, or is pure payload in RAW mode.
    }
    function retransmit(data: pointer; len: uint; updateWeSent: bool = true; isRTCP: bool = false; tcpLenAlreadyPrefixed: bool = false): int;
    {*
	Sends data to specified destination.

	@return 0 if all data was send successfully, or WinSock error otherwise.
    }
    function send_To(addr: PSockAddrIn; data: pointer; len: uint; isRTCP: bool; ownPacket: bool = true; tcpLenAlreadyPrefixed: bool = false): int;
    {*
	Not everyday function.
    }
    procedure setNewSSRC(newssrc: u_int32);
    //
    // -- properties --
    //
    {*
	Payload for own transmits.
    }
    property payload: int read f_payload write setPayload;
    {*
	Sampling rate of a stream.
    }
    property samplingRate: unsigned read f_sr write f_sr;
    {*
    }
    property socketError: int read f_socketError;
    {*
	Timestamp clock rate.
    }
    property RTPclockRate: unsigned read f_RTPclockRate write f_RTPclockRate;
    {*
	SSRC
    }
    property _SSRC: u_int32 read getSsrc;
    {*
	True if receiver is RAW (no RTP/RTCP will be used).
    }
    property isRAW: bool read f_isRAW write f_isRAW;
    {*
    }
    property isTranslator: bool read f_isTranslator write f_isTranslator;
    {*
    }
    property active: bool read getActive write setActive;
    {*
    }
    property bind2ip: string read f_bind2ip write f_bind2ip;
    {*
    }
    property bind2port: string read f_bind2port;
    {*
    }
    property receiver: unaRTPReceiver read f_receiver;
    {*
    }
    property rtcp: unaRTCPstack read getRTCP;
    {*
	Send CN packets over RTP when not streaming data.
	Default is true.
    }
    property rtpPing: bool read f_rtpPing write f_rtpPing;
    {*
	TTL value
    }
    property ttl: int read f_ttl write f_ttl;
    {*
	When true, no packets are sent
    }
    property paused: bool read f_paused write f_paused;
    {*
	Destination
    }
    property dest[index: int]: unaRTPDestination read getDest;
    {*
	Fired when new destination is about to be added
    }
    property onAddDest: unaRTPOnAddDestination read f_onAddDest write f_onAddDest;
  end;


type
  {*
	RTP dynamict payload mapping
  }
  punaRTPMap = ^unaRTPMap;
  unaRTPMap = packed record
    //
// dyn type used for this mapping
    r_dynType: int32;			
// L16 for example
    r_mediaType: array[0..7] of aChar;	
// see c_rtp_enc_XXX (this is not a payload!)
    r_rtpEncoding: int32;		
    //
// sampling rate
    r_samplingRate: int32;		
// number of channels
    r_numChannels: int32;		
// usually 8 or 16
    r_bitsPerSample: int32;		
    //
// frame size or 0
    r_fmt_frameSize: int32;             
// bitrate or 0
    r_fmt_bitrate: int32;		
  end;


const
  //
// max number of clients in TCP Server mode
  v_maxSrv_clients: int	 = 1;	


{*
	Aligns length to 32-bit words:
	  0 -> 0
	  1 -> 4
	  2 -> 4
	  3 -> 4
	  4 -> 4
	  5 -> 8
	  6 -> 8

	@return aligned value
}
function align32(sz: unsigned): unsigned;
{*
	Computes length of packet in 32-bit words minus one.
	Returns bytes in network order.

	@param sz size of whole packet, including headers and padding
	@return value for length header field
}
function rtpLength(sz: uint16): uint16;
{*
	Computes length of packet in bytes given Length value from header.

	@param rtpLen length field from RTP header (network order)
	@return size in bytes
}
function rtpLength2bytes(rtpLen: uint16): uint16;
{*
	Parses rtpmap attribute from an SDP response.
}
function parseRTPMap(const rtp_map, rtp_fmt: string; var map: unaRTPMap): bool;
{*
	Maps known media types to known RTP encodings.

	@return One of c_rtp_enc_XXX constants or -1 if media type is unknown.
}
function mapMediaType2rtpEncoding(const mtype: string): int32;
{*
	Maps known RTP encodings into media types.

	@return String representation of encoding.
}
function mapRtpEncoding2mediaType(const enc: int): string;



implementation


uses
  unaUtils;

// --  --
function parseRTPfmtp(const fmtp: string; var map: unaRTPMap): bool;
var
  p: int;
begin
  if ('' <> fmtp) then begin
    //
    p := pos('frame-size=', fmtp);
    if (1 < p) then
      map.r_fmt_frameSize := str2intInt(copy(fmtp, p + 11, maxInt), 0, 10, true);
    //
    p := pos('bitrate=', fmtp);
    if (1 < p) then
      map.r_fmt_bitrate := str2intInt(copy(fmtp, p + 8, maxInt), 0, 10, true);
    //
    result := true;
  end
  else
    result := false;
end;

// --  --
function align32(sz: unsigned): unsigned;
begin
  result := sz + ((4 - sz and $3) and $3);
end;

// --  --
function rtpLength(sz: uint16): uint16;
begin
  if (0 < sz) then
    result := swap16u( ((sz - 1) and $FFFC) shr 2 )
  else
    result := 0;
end;

// -- --
function rtpLength2bytes(rtpLen: uint16): uint16;
begin
  result := (swap16u(rtpLen) + 1) shl 2;
end;

// --  --
function parseRTPMap(const rtp_map, rtp_fmt: string; var map: unaRTPMap): bool;
var
  p1, p2: int;
  submap: string;
begin
  result := false;
  //
  p1 := pos(#13, rtp_map);
  if (0 < p1) then
    submap := copy(rtp_map, 1, p1 - 1)
  else
    submap := trimS(rtp_map);
  //
  p1 := pos(' ', submap);
  if (0 < p1) then begin
    //
    map.r_dynType := str2intInt(copy(submap, 1, p1 - 1), 96);
    //
    p2 := pos('/', submap);
    if (0 >= p2) then
      p2 := length(submap) + 1;
    //
    if (p1 < p2) then begin
      //
      str2arrayA(aString(copy(submap, p1 + 1, p2 - p1 - 1)), map.r_mediaType);
      map.r_rtpEncoding := mapMediaType2rtpEncoding(string(map.r_mediaType));
      //
      submap := copy(submap, p2 + 1, maxInt);
      p1 := pos('/', submap);
      if (0 < p1) then begin
	//
	map.r_samplingRate := str2intInt(copy(submap, 1, p1 - 1), 8000);
	//
	{*
	   For audio streams, <encoding parameters> indicates the number
	   of audio channels.  This parameter is OPTIONAL and may be
	   omitted if the number of channels is one, provided that no
	   additional parameters are needed.
	}
	map.r_numChannels := str2intInt(trimS(copy(submap, p1 + 1, maxInt)), 1);
      end
      else begin
	//
	map.r_samplingRate := str2intInt(submap, 8000);
	map.r_numChannels := 1;
      end;
      //
      parseRTPfmtp(rtp_fmt, map);
      //
      result := true;
    end;
  end;
end;

// --  --
function mapMediaType2rtpEncoding(const mtype: string): int32;
begin
  if (sameString(mtype, 'DVI4'))    	then result := c_rtp_enc_DVI4 else
  if (sameString(mtype, 'G722'))    	then result := c_rtp_enc_G722 else
  if (sameString(mtype, 'G723'))    	then result := c_rtp_enc_G723 else
  if (sameString(mtype, 'G726-40')) 	then result := c_rtp_enc_G726_40 else
  if (sameString(mtype, 'G726-32')) 	then result := c_rtp_enc_G726_32 else
  if (sameString(mtype, 'G726-24')) 	then result := c_rtp_enc_G726_24 else
  if (sameString(mtype, 'G726-16')) 	then result := c_rtp_enc_G726_16 else
  if (sameString(mtype, 'G728')) 	then result := c_rtp_enc_G728 else
  if (sameString(mtype, 'G729')) 	then result := c_rtp_enc_G729 else
  if (sameString(mtype, 'G729D')) 	then result := c_rtp_enc_G729D else
  if (sameString(mtype, 'G729E')) 	then result := c_rtp_enc_G729E else
  if (sameString(mtype, 'GSM')) 	then result := c_rtp_enc_GSM else
  if (sameString(mtype, 'GSM_EFR')) 	then result := c_rtp_enc_GSM_EFR else
  if (sameString(mtype, 'GSM49')) 	then result := c_rtp_enc_GSM49 else
  if (sameString(mtype, 'L8')) 		then result := c_rtp_enc_L8 else
  if (sameString(mtype, 'L16')) 	then result := c_rtp_enc_L16 else
  if (sameString(mtype, 'LPC')) 	then result := c_rtp_enc_LPC else
  if (sameString(mtype, 'MPA')) 	then result := c_rtp_enc_MPA else
  if (sameString(mtype, 'PCMA')) 	then result := c_rtp_enc_PCMA else
  if (sameString(mtype, 'PCMU')) 	then result := c_rtp_enc_PCMU else
  if (sameString(mtype, 'QCELP')) 	then result := c_rtp_enc_QCELP else
  if (sameString(mtype, 'VDVI')) 	then result := c_rtp_enc_VDVI else
  //
  if (sameString(mtype, 'speex')) 	then result := c_rtp_enc_Speex else
  if (sameString(mtype, 'vorbis')) 	then result := c_rtp_enc_Vorbis else
  if (sameString(mtype, 'CELT')) 	then result := c_rtp_enc_CELT else
  if (sameString(mtype, 't140c')) 	then result := c_rtp_enc_T140 else
  if (sameString(mtype, 'G7221'))    	then result := c_rtp_enc_G7221 else
					     result := -1;	// unknown
  //
end;

// --  --
function mapRtpEncoding2mediaType(const enc: int): string;
begin
  case (enc) of

    c_rtp_enc_DVI4   : result := 'DVI4';	// RFC 3555
    c_rtp_enc_G722   : result := 'G722';	// RFC 3555
    c_rtp_enc_G723   : result := 'G723';	// RFC 3555
    c_rtp_enc_G726_40: result := 'G726-40';	// RFC 3555
    c_rtp_enc_G726_32: result := 'G726-32';	// RFC 3555
    c_rtp_enc_G726_24: result := 'G726-24';	// RFC 3555
    c_rtp_enc_G726_16: result := 'G726-16';	// RFC 3555
    c_rtp_enc_G728   : result := 'G728';	// RFC 3555
    c_rtp_enc_G729   : result := 'G729';	// RFC 3555
    c_rtp_enc_G729D  : result := 'G729D';	// RFC 3555
    c_rtp_enc_G729E  : result := 'G729E';	// RFC 3555
    c_rtp_enc_GSM    : result := 'GSM';		// RFC 3555
    c_rtp_enc_GSM_EFR: result := 'GSM_EFR';	// RFC 3555
    c_rtp_enc_GSM49  : result := 'GSM49';	//
    c_rtp_enc_L8     : result := 'L8';		// RFC 3555
    c_rtp_enc_L16    : result := 'L16';		// RFC 3555
    c_rtp_enc_LPC    : result := 'LPC';		// RFC 3555
    c_rtp_enc_MPA    : result := 'MPA';		// RFC 3555
    c_rtp_enc_PCMA   : result := 'PCMA';	// RFC 3555
    c_rtp_enc_PCMU   : result := 'PCMU';	// RFC 3555
    c_rtp_enc_QCELP  : result := 'QCELP';	// RFC 3555
    c_rtp_enc_VDVI   : result := 'VDVI';	// RFC 3555
    //
    c_rtp_enc_speex  : result := 'speex';	// RFC 5574
    c_rtp_enc_vorbis : result := 'vorbis';	// RFC 5215
    c_rtp_enc_CELT   : result := 'CELT';	//
    c_rtp_enc_t140   : result := 't140c';	// RFC 4351
    c_rtp_enc_G7221  : result := 'G7221';	// RFC 5577
    else
		       result := '';
  end;
end;


{ unaRTCPSourceList }

// --  --
function unaRTCPSourceList.getId(item: pointer): int64;
begin
  if (nil <> item) then
    result := prtp_site_info(item).r_ssrc
  else
    result := 0;
end;

// --  --
function unaRTCPSourceList.indexByAddrRTCP_(const addr: sockaddr_in): int;
var
  i: int;
  si: prtp_site_info;
begin
  result := -1;
  for i := 0 to count - 1 do begin
    //
    si := get(i);
    if (si.r_remoteAddrRTCPValid and sameAddr(addr, si.r_remoteAddrRTCP)) then begin
      //
      result := i;
      break;
    end;
  end;
end;

// --  --
function unaRTCPSourceList.indexByAddrRTP_(const addr: sockaddr_in): int;
var
  i: int;
  si: prtp_site_info;
begin
  result := -1;
  for i := 0 to count - 1 do begin
    //
    si := get(i);
    if (si.r_remoteAddrRTPValid and sameAddr(addr, si.r_remoteAddrRTP)) then begin
      //
      result := i;
      break;
    end;
  end;
end;

// --  --
procedure unaRTCPSourceList.releaseItem(index: int; doFree: unsigned);
var
  si: prtp_site_info;
begin
  si := get(index);
  if (mapDoFree(doFree) and (nil <> si)) then begin
    //
    si.r_acq.acquire(false, 100{$IFDEF DEBUG}, false, className + '.releaseItem()'{$ENDIF DEBUG });	// make sure no one else uses this object
    freeAndNil(si.r_acq);
    //
    mrealloc(si.r_cname);
  end;
  //
  inherited;
end;


var
  g_ntp: unaSNTP;
  g_ntpDone: bool = false;

// --  --
function getNTP(ntp: punaNTP_timestamp): bool;
var
  stat: bool;
begin
  stat := false;
  //
  if (not g_ntpDone and g_ntp.acquire(false, 300{$IFDEF DEBUG}, false, '.getNTP()'{$ENDIF DEBUG })) then try
    //
    if (nil = g_ntp) then begin
      //
      g_ntp := unaSNTP.create();
      stat := true;
      //
    {$IFDEF DEBUG }
      // do not hammer NTP servers each time we start debugging something,
      // simply assume clock offset is zero
      result := true;
    {$ELSE }
      // get clock offset from default NTP servers
      result := (0 < g_ntp.synch());
    {$ENDIF DEBUG }
    end
    else
      result := true;
    //
    result := result and (nil <> g_ntp);
    //
    if (result and (nil <> ntp)) then
      g_ntp.nowNTP(ntp^);
    //
  finally
    if (stat) then
      g_ntp.releseStatic()	// so release() will not complain about wrong order
    else
      g_ntp.releaseWO();
  end
  else
    result := false;
end;


type
  {*
	RTCP idle thread
  }
  unaRTCPIdleThread = class(unaThread)
  private
    f_rtcp: unaRTCPstack;
  protected
    function execute(threadID: unsigned): int; override;
  public
    constructor create(rtcp: unaRTCPstack);
  end;



{ unaRTCPIdleThread }

// --  --
constructor unaRTCPIdleThread.create(rtcp: unaRTCPstack);
begin
  f_rtcp := rtcp;
  //
  inherited create();
end;

// --  --
function unaRTCPIdleThread.execute(threadID: unsigned): int;
begin
  sleepThread(100);
  //
  while (not shouldStop) do begin
    //
    try
      f_rtcp.gotIdle();
    except
    end;
    //
    sleepThread(100);
  end;
  //
  result := 0;
end;


{ unaRTCPstack }

// --  --
procedure unaRTCPstack.BeforeDestruction();
begin
  inherited;
  //
  f_outBufSize := 0;
  mrealloc(f_outBuf);
  //
  freeAndNil(f_members);
  freeAndNil(f_socket_M);
  freeAndNil(f_socket_U);
  freeAndNil(f_socket_T);
  freeAndNil(f_idleThread);
  freeAndNil(f_readyEv);
end;

// --  --
function unaRTCPstack.calcTI(): unsigned;
begin
  {*
    1) If the number of senders is less than or equal to 25% of the membership (members),
    the interval depends on whether the participant is a sender or not (based on the value of we_sent).
  }
  if (25 >= percent(f_senders, memberCount)) then begin
    //
    if (0 < f_we_sent) then begin
      {*
        If the participant is a sender (we_sent true), the constant C is set to the
        average RTCP packet size (avg_rtcp_size) divided by 25% of the RTCP bandwidth (rtcp_bw),
        and the constant n is set to the number of senders.
      }
      f_C := f_avg_rtcp_size div (f_rtcp_bw shr 2);
      f_n := f_senders;
    end
    else begin
      {*
        If we_sent is not true, the constant C is set to the average RTCP packet size divided
        by 75% of the RTCP bandwidth.
        The constant n is set to the number of receivers (members - senders).
      }
      f_C := f_avg_rtcp_size div ((f_rtcp_bw * 75) div 100);
      f_n := memberCount - f_senders;
    end;
  end
  else begin
    {*
      If the number of senders is greater than 25%, senders and receivers are treated together.
      The constant C is set to the average RTCP packet size divided by the total RTCP bandwidth
      and n is set to the total number of members.
    }
    f_C := f_avg_rtcp_size div f_rtcp_bw;
    f_n := memberCount;
  end;
  //
{*
  2) If the participant has not yet sent an RTCP packet (the variable
     initial is true), the constant Tmin is set to 2.5 seconds, else it is set to 5 seconds.
}
  if (f_initial) then
    f_Tmin := 2500
  else
    f_Tmin := 5000;
  //
{*
  3) The deterministic calculated interval Td is set to max(Tmin, n*C).
}
  f_Td := max(f_Tmin, f_n * f_C);
  //
{*
  4) The calculated interval T is set to a number uniformly distributed
     between 0.5 and 1.5 times the deterministic calculated interval.
     The resulting value of T is divided by e-3/2=1.21828 to compensate
     for the fact that the timer reconsideration algorithm converges
     to a value of the RTCP bandwidth below the intended average.
}
  f_T := trunc(f_Td * ( (50 + random(100)) / 100 ) / 1.21828);
  //
  result := f_T;
end;

// --  --
procedure unaRTCPstack.checkRTT();
var
  si: prtp_site_info;
  req: unaRTCPRTTReq;
begin
  if (rttEnabled) then begin
    //
    // query next site for RTT
    if (f_rttLastIndex < f_members.count) then begin
      //
      // lock site info
      // (lock as RO, although we modidfy some field. That assumes those fiels are modified from this thread only)
      si := memberByIndexAcq(f_rttLastIndex, true, 40);
      if (nil <> si) then try
	//
	if (si.r_remoteAddrRTCPValid and ((0 = si.r_rttTMU) or (15000 < timeElapsedU(si.r_rttTMU))) ) then begin
	  //
	  si.r_rttTMU := timeMarkU();
	  //
	  req.r_magic := si.r_ssrc xor uint32(random($7FFFFFFF));
	  si.r_rttMagic := req.r_magic;
	  req.r_srcSSRC := streamer._SSRC;
	  req.r_dstSSRC := si.r_ssrc;
	  //
	  req.r_tmU := timeMarkU();
	  sendAPPto(@si.r_remoteAddrRTCP, c_rtcp_appCmd_RTT_stRequest, c_rtcp_appCmd_RTT, @req, sizeof(unaRTCPRTTReq));
	  //
	  {$IFDEF UNA_SOCKSRTP_RTCP_RTT_DEBUG }
	  logMessage('--> SENT RTT REQ to ' + int2str(si.r_ssrc) + '@' + addr2str(@si.r_remoteAddrRTCP));
	  {$ENDIF UNA_SOCKSRTP_RTCP_RTT_DEBUG }
	end;
	//
      finally
	memberReleaseRO(si);
      end;
      //
      inc(f_rttLastIndex);
    end
    else
      f_rttLastIndex := 0;
    //
  end;
end;

// --  --
function unaRTCPstack.copyMember(ssrc: u_int32; var info: rtp_site_info): bool;
var
  si: prtp_site_info;
begin
  result := false;
  si := memberBySSRCAcq(ssrc, true, 100);
  if (nil <> si) then try
    //
    move(si.r_ssrc, info.r_ssrc, sizeof(rtp_site_info) - sizeof(pointer));	// copy everything except r_acq
    result := true;
  finally
    memberReleaseRO(si);
  end;
end;

// --  --
constructor unaRTCPstack.create(streamer: unaRTPStreamer; useNTP: bool);
begin
  f_members := unaRTCPSourceList.create(uldt_record);
  f_streamer := streamer;
  memberTimeoutReports := 6;
  f_acar := true;
  //
  f_readyEv := unaEvent.create(true, false);
  //
  rttEnabled := true;
  //
  f_idleThread := unaRTCPIdleThread.create(self);
  //
  if (streamer.isMulticast) then
    f_socket_M := unaMulticastSocket.create()
  else
    if (streamer.isUDP) then
      f_socket_U := unaUDPSocket.create()
    else
      f_socket_T := unaTCPSocket.create();
  //
  if (useNTP) then
    getNTP(nil);
  //
  inherited create();
end;

// --  --
procedure unaRTCPstack.ensureMember(ssrc: u_int32; addr: PSockAddrIn);
var
  si: prtp_site_info;
  wo: bool;
begin
  if (0 <> ssrc) then begin
    //
    si := memberBySSRCAcq(ssrc, true, 10);
    if ((nil = si) or not si.r_remoteAddrRTCPValid) then begin
      //
      wo := false;
      if ((nil = si) and (0 > f_members.indexOfId(ssrc))) then begin
	//
	wo := true;
	si := newMemberAcq(ssrc);
      end;
      //
      if (nil <> si) then try
	//
	if (not si.r_remoteAddrRTCPValid) then begin
	  //
	  si.r_remoteAddrRTCP := addr^;
	  si.r_remoteAddrRTCPValid := true;
	  //
	{$IFDEF UNA_SOCKSRTP_LOG_RTCP }
	  logMessage(className + '.enusreMember() - New RTCP address for [' + int2str(ssrc) + '=' + addr2str(addr) + ']');
	{$ENDIF UNA_SOCKSRTP_LOG_RTCP }
	end
	else begin
	  //
	  if (not sameAddr(si.r_remoteAddrRTCP, addr^)) then begin
	    //
	    // RTCP with same SSRC but from different address.. is that occational conflict or attack?
	    if (addrChangeAutoResolve) then
	      si.r_remoteAddrRTCP := addr^
	    else begin
	      //
	      // TODO: call an event probably?
	    end;
	  end;
	end;
	//
      finally
	if (wo) then
	  memberReleaseWO(si)
	else
	  memberReleaseRO(si);
      end;
    end
    else
      memberReleaseRO(si);
  end;
end;

// --  --
function unaRTCPstack.execute(threadID: unsigned): int;
var
  szRTCP: int;
  addr: sockaddr_in;
  bufSize: uint;
  buf: pointer;
  tot: int;
begin
  f_readyEv.setState(true);
  //
  if ( (streamer is unaRTPReceiver) and (not streamer.isUDP and not (streamer as unaRTPReceiver).isServer) ) then
    // TCP client connection might take much time, so do it here, in separate thread.
    f_socketError := socketObjRTCP.connect();
  //
  if (0 <> socketError) then begin
    //
    result := -1;
    exit;
  end;
  //
  bufSize := 4096;
  buf := malloc(bufSize);
  tot := 100;
  //
  try
    while (not shouldStop) do begin
      //
      try
	if (streamer.socketNoReading) then begin
	  //
	  szRTCP := 0;
	  sleepThread(10);
	end
	else begin
	  //
	  if (nil <> f_socket_U) then
	    szRTCP := f_socket_U.recvfrom(addr, buf, bufSize, false, 0, tot)
	  else begin
	    //
	    if (nil <> f_socket_M) then
	      szRTCP := f_socket_M.recvfrom(addr, buf, bufSize, false, 0, tot)
	    else
	      if (nil <> f_socket_T) then begin
		//
		szRTCP := f_socket_T.read(buf, bufSize, tot, false);
		if (0 < szRTCP) then
		  f_socket_T.getSockAddr(addr);
	      end
	      else begin
		//
		sleepThread(100);
		szRTCP := 0;	// if no socket, RTCP packets will be notified via streamer's socket
	      end;
	  end;
	end;
	//
	if (0 < szRTCP) then begin
	  //
	  tot := 18;
	  //
	  {$IFDEF UNA_SOCKSRTP_LOG_SOCKDATA }
	  logMessage('RTCP: got ' + int2str(szRTCP) + ' bytes from ' + addr2str(@addr));
	  {$ENDIF UNA_SOCKSRTP_LOG_SOCKDATA }
	  //
	  gotPacket(@addr, prtcp_common_hdr(buf), szRTCP, true);
	  //
	  {*
	    For each compound RTCP packet received, the value of avg_rtcp_size is updated:
	      avg_rtcp_size = (1/16) * packet_size + (15/16) * avg_rtcp_size
	  }
	  f_avg_rtcp_size := szRTCP shr 4 + trunc(15 / 16 * f_avg_rtcp_size);
	end
	else begin
	  //
	  if (tot < 2240) then
	    tot := tot shl 1;
	end;
	//
      except
      end;
    end;
    //
    f_idleThread.stop();
    //
    sendRTCP(true);	// send BYE to all members
    //
  finally
    mrealloc(buf);
  end;
  //
  f_readyEv.setState(false);
  //
  result := 0;
end;

// --  --
function unaRTCPstack.getMemberCNAME(ssrc: u_int32; out cname: wString): bool;
var
  si: prtp_site_info;
  aName: aString;
begin
  if (ssrc = streamer._SSRC) then begin
    //
    cname := {$IFDEF DEBUG }'<myself>'{$ELSE }''{$ENDIF DEBUG };
    result := true;
  end
  else begin
    //
    result := false;
    si := memberBySSRCAcq(ssrc, true, 100);
    if (nil <> si) then try
      //
      if (nil <> si.r_cname) then begin
        //
        setLength(aName, si.r_cname.length);
        if (0 < si.r_cname.length) then begin
          //
          move(si.r_cname.r_data, aName[1], si.r_cname.length);
          cname := utf82utf16(aName);
          result := true;
        end;
      end
      else
        cname := {$IFDEF DEBUG }'<no CNAME>'{$ELSE }''{$ENDIF DEBUG };
      //
    finally
      memberReleaseRO(si);
    end
    else
      cname := {$IFDEF DEBUG }'<nil,ssrc=' + int2str(ssrc) + '>'{$ELSE }''{$ENDIF DEBUG };
  end;
end;

// --  --
function unaRTCPstack.getMemberCount(): int;
begin
  result := f_members.count + 1;	// assuming at least one member (us)
end;

// --  --
function unaRTCPstack.getMemberTimeout(ssrc: u_int32): int;
var
  si: prtp_site_info;
  p1, p2: unsigned;
begin
  si := memberBySSRCAcq(ssrc, true, 100);
  if (nil <> si) then try
    //
    if (0 = si.r_lastRRreceivedTM) then
      result := -1	// unknown timeout, should not be here
    else begin
      //
      p1 := unsigned(memberTimeoutReports) * f_tn;
      p2 := timeElapsed32U(si.r_lastRRreceivedTM);
      if (p1 > p2) then
	result := p1 - p2
      else
	result := 1000;
    end;
  finally
    memberReleaseRO(si);
  end
  else
    result := -2;
end;

// --  --
function unaRTCPstack.getNextSeq(): unsigned;
begin
  if (nil = self) then
    result := 0
  else begin
    {$IFOPT R+ }
      {$DEFINE 5240629F_4CD4_47C0_A82C_F0F765B34960 }
    {$ENDIF R+ }
    {$R-} // otherwise it will fail on f_seq = $7FFFFFFF;
    result := InterlockedIncrement(f_seq) and $FFFF;
    {$IFDEF 5240629F_4CD4_47C0_A82C_F0F765B34960 }
      {$R+ }
    {$ENDIF 5240629F_4CD4_47C0_A82C_F0F765B34960 }
  end;
end;

// --  --
function unaRTCPstack.getSocket(): unaSocket;
begin
  if (nil <> f_socket_U) then
    result := f_socket_U
  else
    if (nil <> f_socket_M) then
      result := f_socket_M
    else
      if (nil <> f_socket_T) then
	result := f_socket_T
      else
	result := nil;
end;

// --  --
procedure unaRTCPstack.gotIdle();
var
  T: unsigned;
  rtcpIdle: bool;
begin
  if (not f_readyEv.waitFor(100)) then
    exit;
  //
{*
  When the packet transmission timer expires, the participant performs the following operations:
}
  if (f_tn < timeElapsed32U(f_tc)) then begin
    //
  {$IFDEF UNA_SOCKSRTP_LOG_RTCP_EX }
    logMessage(className + '.gotIdle() - RTCP timer.');
  {$ENDIF UNA_SOCKSRTP_LOG_RTCP_EX }
    //
    f_tc := timeMarkU();
    //
    if (0 < f_we_sent) then begin
      //
      if (release32(f_we_sent)) then	// just decrease the count
	release32(f_senders);	// remove ourself from senders
    end;
    {*
      The transmission interval T is computed as described in Section 6.3.1, including the randomization factor.
    }
    T := calcTI();
    if ( (0 = f_tp) or (T <= timeElapsed32U(f_tp)) ) then begin
      {*
	If tp + T is less than or equal to tc, an RTCP packet is transmitted.
      }
      sendRTCP();
      //
      timeoutMembers();
      //
      checkRTT();
      //
      {*
	tp is set to tc, then another value for T is calculated as in the previous step and tn is set to tc + T.
	The transmission timer is set to expire again at time tn.
      }
      f_tp := timeMarkU();
      f_tn := calcTI();
    end
    else begin
      {*
	If tp + T is greater than tc, tn is set to tp + T.
	No RTCP packet is transmitted. The transmission timer is set to expire at time tn.
      }
      f_tn := T;
    end;
    {*
      pmembers is set to members.
    }
    f_pmembers := memberCount;
    //
    rtcpIdle := true;
  end
  else
    rtcpIdle := false;
  //
  if (nil <> streamer) then
    try
      streamer.onIdle(rtcpIdle);
    except
    end;
end;

// --  --
procedure unaRTCPstack.gotPacket(addr: PSockAddrIn; hdr: prtcp_common_hdr; packetSize: uint; firstOne: bool);
var
  sr: prtcp_SR_packet;
  rr: prtcp_RR_packet;
  bye: prtcp_BYE_packet;
  app: prtcp_APP_packet;
  cmd: aString;
  //
  sdes: prtcp_SDES_packet;
  item: prtcp_sdes_item;
  len: uint;
  si: prtp_site_info;
  ssrc: u_int32;
  //
{$IFDEF UNA_SOCKSRTP_LOG_RTCP_EX }
  pn: string;
{$ENDIF UNA_SOCKSRTP_LOG_RTCP_EX }
begin
  {*
    o  RTP version field must equal 2.
    o  The padding bit (P) should be zero for the first packet of a compound RTCP packet because padding should only be applied, if it is needed, to the last packet.
  }
  if ( (hdr <> nil) and (packetSize >= sizeOf(hdr^)) and (RTP_VERSION = hdr.r_V_P_CNT shr 6) and (not firstOne or (firstOne and (0 = (hdr.r_V_P_CNT shr 5) and $1))) ) then begin
    //
    len := rtpLength2bytes(hdr.r_length_NO_);
    //
    ssrc := 0;
  {$IFDEF UNA_SOCKSRTP_LOG_RTCP_EX }
    pn := '? ' + int2str(hdr.r_pt);
  {$ENDIF UNA_SOCKSRTP_LOG_RTCP_EX }
    //
    case (hdr.r_pt) of

      RTCP_SR: begin	// Sender Report
	//
	if (packetSize >= sizeof(rtcp_SR_packet)) then begin
	  //
	{$IFDEF UNA_SOCKSRTP_LOG_RTCP_EX }
	  pn := 'SR';
	{$ENDIF UNA_SOCKSRTP_LOG_RTCP_EX }
	  //
	  sr := prtcp_SR_packet(hdr);
	  ssrc := swap32u(sr.r_ssrc_NO);
	  if (ssrc <> streamer._SSRC) then begin
	    //
	    ensureMember(ssrc, addr);
	    updateOnSR(addr, sr);
	  end
	  else begin
	  {$IFDEF UNA_SOCKSRTP_LOG_RTCP }
	    logMessage(className + '.gotPacket(SR) - loopback SSRC');
	  {$ENDIF UNA_SOCKSRTP_LOG_RTCP }
	  end;
	end;
      end;

      RTCP_RR: begin    // Receiver Report
	//
	if (packetSize >= sizeof(rtcp_RR_packet)) then begin
	  //
	{$IFDEF UNA_SOCKSRTP_LOG_RTCP_EX }
	  pn := 'RR';
	{$ENDIF UNA_SOCKSRTP_LOG_RTCP_EX }
	  //
	  rr := prtcp_RR_packet(hdr);
	  ssrc := swap32u(rr.r_ssrc_NO);
	  ensureMember(ssrc, addr);
	  if (ssrc <> streamer._SSRC) then begin
	    //
	    updateOnRR(addr, rr);
	  end
	  else begin
	  {$IFDEF UNA_SOCKSRTP_LOG_RTCP }
	    logMessage(className + '.gotPacket(RR) - loopback SSRC');
	  {$ENDIF UNA_SOCKSRTP_LOG_RTCP }
	  end;
	end;
      end;

      RTCP_SDES: begin  // SDES Packet
	//
      {$IFDEF UNA_SOCKSRTP_LOG_RTCP_EX }
	pn := 'SDES';
      {$ENDIF UNA_SOCKSRTP_LOG_RTCP_EX }
	//
	sdes := prtcp_SDES_packet(hdr);
	//count := (sdes.r_common.r_V_P_CNT and $1F);
	ssrc := swap32u(sdes.r_ssrc_NO);
        if (ssrc <> streamer._SSRC) then begin
	  //
          ensureMember(ssrc, addr);
          //
          item := prtcp_sdes_item(@sdes.r_items);
	  while (RTCP_SDES_END <> item.r_type) do begin
            //
            updateOnSDES(ssrc, item);
            if (RTCP_SDES_CNAME = item.r_type) then
              streamer.onSsrcCNAME(ssrc, item);
            //
            item := prtcp_sdes_item(@pArray(item)[2 + item.length]);
          end;
	  //
          // TODO: parse other chunks (while (0 < count) ...) as well
        end
        else begin
    {$IFDEF UNA_SOCKSRTP_LOG_RTCP }
	  logMessage(className + '.gotPacket(SDES) - loopback SSRC');
    {$ENDIF UNA_SOCKSRTP_LOG_RTCP }
        end;
      end;

      RTCP_BYE: begin   // BYE packet
	//
	if (sizeof(rtcp_BYE_packet) <= packetSize) then begin
	  //
  {$IFDEF UNA_SOCKSRTP_LOG_RTCP_EX }
	  pn := 'BYE';
  {$ENDIF UNA_SOCKSRTP_LOG_RTCP_EX }
	  //
	  bye := prtcp_BYE_packet(hdr);
	  ssrc := swap32u(bye.r_ssrc_NO);
	  if (ssrc <> streamer._SSRC) then begin
	    //
	    si := memberBySSRCAcq(ssrc, false);
	    if (nil <> si) then try
	      //
    {$IFDEF UNA_SOCKSRTP_LOG_RTCP }
	      logMessage(className + '.gotPacket(BYE) - HardBYE on SSRC=' + int2str(ssrc));
    {$ENDIF UNA_SOCKSRTP_LOG_RTCP }
	      //
	      si.r_hardBye := true;
	      if (not si.r_byeReported) then begin  // better do it now
		//
		si.r_byeReported := true;
		//
      {$IFDEF UNA_SOCKSRTP_LOG_RTCP }
		logMessage(className + '.gotPacket(BYE) - Notify we got BYE on SSRC=' + int2str(si.r_ssrc));
      {$ENDIF UNA_SOCKSRTP_LOG_RTCP }
		//
		streamer.onBye(si, false);
	      end;
	      //
	    finally
	      memberReleaseWO(si);
	    end;
	  end
	  else begin
	  {$IFDEF UNA_SOCKSRTP_LOG_RTCP }
	    logMessage(className + '.gotPacket(BYE) - loopback SSRC');
	  {$ENDIF UNA_SOCKSRTP_LOG_RTCP }
	  end;
	end;
      end;

      RTCP_APP: begin   // APP packet
	//
	app := prtcp_APP_packet(hdr);
      {$IFDEF UNA_SOCKSRTP_LOG_RTCP_EX }
	pn := 'APP(' + app.r_cmd + ')';
      {$ENDIF UNA_SOCKSRTP_LOG_RTCP_EX }
	//
	ssrc := swap32u(app.r_ssrc_NO);
	if (ssrc <> streamer._SSRC) then begin
	  //
	  ensureMember(ssrc, addr);
	  //
	  setLength(cmd, 4);
	  move(app.r_cmd[0], cmd[1], 4);
	  //
	  udapteOnAPP(addr, app, app.r_common.r_V_P_CNT and $1F, cmd, @app.r_data, len - sizeof(rtcp_APP_packet));
	end
	else begin
	{$IFDEF UNA_SOCKSRTP_LOG_RTCP }
	  logMessage(className + '.gotPacket(APP) - loopback SSRC');
	{$ENDIF UNA_SOCKSRTP_LOG_RTCP }
	end;
      end;

    end;
    //
    if (packetSize > len) then
      gotPacket(addr, prtcp_common_hdr(@pArray(hdr)[len]), packetSize - len, false);
    //
  {$IFDEF UNA_SOCKSRTP_LOG_RTCP_EX }
    logMessage('--> RTCP packet (' + pn + ') from [' + int2str(ssrc) + ']');
  {$ENDIF UNA_SOCKSRTP_LOG_RTCP_EX }
    //
    if (firstOne and (0 <> ssrc) and (ssrc <> streamer._SSRC)) then
      streamer.onRTCPPacket(ssrc, addr, hdr, packetSize);
    //
  end
  else begin
    //
  {$IFDEF UNA_SOCKSRTP_LOG_RTCP }
    logMessage('--> malformed RTCP packet.');
  {$ENDIF UNA_SOCKSRTP_LOG_RTCP }
  end;
end;

// --  --
procedure unaRTCPstack.gotRTPpacket(addr: pSockAddrIn; hdr: prtp_hdr; packetSize: uint);
var
  si: prtp_site_info;
  ssrc: u_int32;
begin
  if (packetSize >= sizeof(hdr^)) then begin
    //
    ssrc := swap32u(hdr.r_ssrc_NO);
    if ( (ssrc <> streamer._SSRC) or {$IFDEF DEBUG }conferenceMode{$ELSE }false{$ENDIF DEBUG } ) then begin  // in debug conference we can hear ourself
      //
      si := memberBySSRCAcq(ssrc, false, 20);
      if (nil <> si) then try
	//
	if (not si.r_remoteAddrRTPValid) then begin
	  //
	  si.r_remoteAddrRTP := addr^;
	  si.r_remoteAddrRTPValid := true;
	  //
	{$IFDEF UNA_SOCKSRTP_LOG_RTP }
	  logMessage('New RTP address for [' + int2str(ssrc) + '=' + addr2str(addr) + ']');
	{$ENDIF UNA_SOCKSRTP_LOG_RTP }
	end;
	//
	si.r_lastPayloadTM := timeMarkU();
	si.r_heardOf := true;
	if (not si.r_isSender) then begin
	  //
	  si.r_isSender := true;
	  if (ssrc <> streamer._SSRC) then
	    acquire32NonExclusive(f_senders);	// unconditional increase
	  //
	{$IFDEF UNA_SOCKSRTP_LOG_RTCP_EX }
	  logMessage(className + '.gotRTPpacket() - ssrc=' + int2str(ssrc) + ' is now a sender, payload=' + int2str(hdr.r_M_PT and 7));
	{$ENDIF UNA_SOCKSRTP_LOG_RTCP_EX }
	end;
	//
      finally
	memberReleaseWO(si);
      end;
    end
    else begin
    {$IFDEF UNA_SOCKSRTP_LOG_RTCP }
      logMessage(className + '.gotRTPPacket() - loopback SSRC');
    {$ENDIF UNA_SOCKSRTP_LOG_RTCP }
    end;
  end;
end;

// --  --
procedure unaRTCPstack.init_seq(si: prtp_site_info; seq: u_int16);
begin
  if (nil <> si) then begin
    //
    si.r_base_seq := seq;
    si.r_max_seq := seq;
    si.r_bad_seq := RTP_SEQ_MOD + 1;   //* so seq == bad_seq is false */
    si.r_cycles := 0;
    si.r_received := 0;
    si.r_received_prior := si.r_received;
    si.r_expected_prior := si.r_received;
  end;
end;

// --  --
procedure unaRTCPstack.issueBYEhdr(var ofs: int);
var
  hdr: rtcp_BYE_packet;
  sz: int;
begin
  sz := sizeof(rtcp_BYE_packet);	// this is already 32-bit aligned
  fillChar(hdr, sz, #0);
  //
  hdr.r_common.r_V_P_CNT := RTP_VERSION shl 6 or 1;		// no padding, 1 source
  hdr.r_common.r_pt := RTCP_BYE;
  hdr.r_common.r_length_NO_ := rtpLength(sz);
  //
  hdr.r_ssrc_NO := swap32u(streamer._ssrc);
  //
  move(hdr, f_outBuf[ofs], sz);
  inc(ofs, sz);
end;

// --  --
procedure unaRTCPstack.issueRRBlock(var ofs: int; si: prtp_site_info);
var
  report: rtcp_rr_block;
  rs: int;
  lost, expected: uint64;
  lost_interval, received_interval, expected_interval: int;
begin
  rs := sizeof(rtcp_rr_block);
  fillChar(report, rs, #0);
  report.r_ssrc_NO := swap32u(si.r_ssrc);
  report.r_last_seq_NO := swap32u(si.r_cycles or si.r_max_seq);
  report.r_jitter_NO := swap32u(241);	// TODO: implement proper jitter
  report.r_lsr_NO := swap32u(si.r_lastSRreceived);
  report.r_dlsr_NO := swap32u(uint32((timeElapsed64U(si.r_lastSRreceivedTM) shl 16) div 1000));
  //
  try
  {$IFOPT R+ }
    {$DEFINE 5240629F_4CD4_47C0_A82C_F0F765B34960 }
  {$ENDIF R+ }
    {$R- }
  //
  {$IFOPT Q+ }
    {$DEFINE 1A203308_ED95_4644_9499_A528987687D9 }
  {$ENDIF Q+ }
    {$Q- }
    //
    expected := si.r_cycles + si.r_max_seq - si.r_base_seq + 1;
    //
    lost := expected - si.r_received;
    if ($FFFF0000 < lost) then begin
      //
      expected := si.r_received;
      lost := 0;
    end;
    //
    report.r_lost_NO.r_low := swap16u(u_int16(lost and $FFFF));
    report.r_lost_NO.r_hi := int8(lost shr 16);
    //
    si.r_stat_lost := lost;
    si.r_stat_lostPercent   := percent(si.r_stat_lost - si.r_stat_lost_prev, si.r_stat_received - si.r_stat_received_prev);
    si.r_stat_lost_prev     := si.r_stat_lost;
    si.r_stat_received_prev := si.r_stat_received;
    //
    expected_interval := expected - si.r_expected_prior;
    received_interval := si.r_received - si.r_received_prior;
    lost_interval := expected_interval - received_interval;
    //
  {$IFDEF 1A203308_ED95_4644_9499_A528987687D9 }
    {$Q+ }
  {$ENDIF 1A203308_ED95_4644_9499_A528987687D9 }
  //
  {$IFDEF 5240629F_4CD4_47C0_A82C_F0F765B34960 }
    {$R+ }
  {$ENDIF 5240629F_4CD4_47C0_A82C_F0F765B34960 }
    //
    si.r_expected_prior := u_int32(expected);
    si.r_received_prior := si.r_received;
    //
    if ((0 = expected_interval) or (0 >= lost_interval)) then
      report.r_fraction_NO := 0
    else begin
      //
      lost_interval := (lost_interval shl 8) div expected_interval;
      if ($FF <= lost_interval) then
	report.r_fraction_NO := $FF
      else
	report.r_fraction_NO := lost_interval;
    end;
  except
  end;
  //
  move(report, f_outBuf[ofs], rs);
  inc(ofs, rs);
end;

// --  --
procedure unaRTCPstack.issueRRhdr(var ofs: int);
var
  rr: rtcp_RR_packet;
  sz: int;
begin
  sz := sizeof(rtcp_RR_packet);
  fillChar(rr, sz, #0);
  //
  // rr.r_common.r_V_P_CNT := RTP_VERSION shl 6 or 0;	// will be overwtitten later, we do not know the count now
  // rr.r_common.r_length_NO := 0;			// will be overwtitten later, we do not know the length now
  rr.r_common.r_pt := RTCP_RR;
  rr.r_ssrc_NO := swap32u(streamer._ssrc);
  //
  move(rr, f_outBuf[ofs], sz);
  inc(ofs, sz);
end;

// --  --
function unaRTCPstack.issueSDES(var ofs: int; probe: bool; altBuf: pointer): int;
var
  len: uint;
  sdes: prtcp_SDES_packet;
  sdes_item: prtcp_sdes_item;
begin
  len := length(streamer.cname8);
  result := sizeof(rtcp_SDES_packet) + sizeof(rtcp_sdes_item) + len + 1;
  result := align32(result);	// align to 4 bytes
  //
  if (not probe) then begin
    //
    try
      if (nil = altBuf) then
	sdes := prtcp_SDES_packet(@f_outBuf[ofs])
      else
	sdes := prtcp_SDES_packet(@pArray(altBuf)[ofs]);
      //
      sdes.r_common.r_V_P_CNT := RTP_VERSION shl 6 or 1;	// no padding, 1 source
      sdes.r_common.r_pt := RTCP_SDES;
      sdes.r_common.r_length_NO_ := rtpLength(result);
      sdes.r_ssrc_NO := swap32u(streamer._ssrc);
      //
      sdes_item := @sdes.r_items;
      //
      sdes_item.r_type := RTCP_SDES_CNAME;
      sdes_item.length := len;
      if (0 < len) then
	move(streamer.cname8[1], sdes_item.r_data, len);
      //
      sdes_item := prtcp_sdes_item(@pArray(@sdes_item.r_data)[len]);
      //
      sdes_item.r_type := RTCP_SDES_END;
      //
      inc(ofs, result);
    except
    end;
  end;
end;

// --  --
procedure unaRTCPstack.issueSRhdr(var ofs: int);
var
  sr: rtcp_SR_packet;
  ntp: unaNTP_timestamp;
  sz: int;
begin
  sz := sizeof(rtcp_SR_packet);
  fillChar(sr, sz, #0);
  //
  // sr.r_common.r_V_P_CNT := RTP_VERSION shl 6 or 0;	// will be overwtitten later, we do not know the count now
  // sr.r_common.r_length_NO := 0;			// will be overwtitten later, we do not know the length now
  sr.r_common.r_pt := RTCP_SR;
  sr.r_ssrc_NO := swap32u(streamer._ssrc);
  //
  getNTP(@ntp);
  sr.r_ntp_NO.r_seconds := swap32u(ntp.r_seconds);
  sr.r_ntp_NO.r_fraction := swap32u(ntp.r_fraction);
  //
  sr.r_rtp_ts_NO := f_rtpTS_no;
  //
{$IFDEF UNA_SOCKSRTP_LOG_RTCP_EX }
  logMessage(className + '.issueSRhdr() - NTP.sec=' + int2str(ntp.r_seconds) + '/frac=' + int2str(ntp.r_fraction) + ';  RTP.timestamp=' + int2str(swap32u(f_rtpTS_no)));
{$ENDIF UNA_SOCKSRTP_LOG_RTCP_EX }
  //
  sr.r_psent_NO := swap32u(f_rtpPCount);
  sr.r_osent_NO := swap32u(f_rtpPSize);
  //
  move(sr, f_outBuf[ofs], sz);
  inc(ofs, sz);
end;

// --  --
function unaRTCPstack.memberByAddrAcq(isRTP: bool; addr: PSockAddrIn; ro: bool; timeout: tTimeout): prtp_site_info;
var
  i: int32;
  same: bool;
begin
  result := nil;
  if (f_members.lock(true, 200 {$IFDEF DEBUG }, '.memberByAddrAcq(..)' {$ENDIF DEBUG })) then try
    //
    for i := 0 to f_members.count - 1 do begin
      //
      result := f_members[i];
      if (nil <> result) then begin
	//
	if (isRTP) then
	  same := result.r_remoteAddrRTPValid  and sameAddr(addr^, result.r_remoteAddrRTP )
	else
	  same := result.r_remoteAddrRTCPValid and sameAddr(addr^, result.r_remoteAddrRTCP);
	//
	if (not same or not result.r_acq.acquire(ro, timeout{$IFDEF DEBUG}, false, 'in memberByIndexAcq()'{$ENDIF DEBUG })) then
	  result := nil;
      end;
      //
      if (nil <> result) then
        break;
    end;
  finally
    f_members.unlockRO();
  end;
end;

// --  --
function unaRTCPstack.memberByIndexAcq(index: int; ro: bool; timeout: tTimeout): prtp_site_info;
begin
  result := nil;
  if (lockNonEmptyList_r(f_members, true, 200 {$IFDEF DEBUG }, '.memberByIndexAcq(index=' + int2str(index) + ')' {$ENDIF DEBUG })) then try
    //
    //if (f_members.lock(true, 200 {$IFDEF DEBUG }, '.memberByIndexAcq(index=' + int2str(index) + ')' {$ENDIF DEBUG })) then try
    //
    result := f_members[index];
    if (nil <> result) then begin
      //
      if (not result.r_acq.acquire(ro, timeout{$IFDEF DEBUG}, false, 'in memberByIndexAcq()'{$ENDIF DEBUG })) then
	result := nil;
    end;
  finally
    //f_members.unlockRO();
    unlockListRO(f_members);
  end;
end;

// --  --
function unaRTCPstack.memberBySSRCAcq(ssrc: u_int32; ro: bool; timeout: tTimeout): prtp_site_info;
begin
  result := nil;
  if (lockNonEmptyList_r(f_members, true, timeout {$IFDEF DEBUG }, '.memberBySSRCAcq()'{$ENDIF DEBUG })) then try
    //
    result := f_members.itemById(ssrc);
    if (nil <> result) then begin
      //
      if (not result.r_acq.acquire(ro, timeout{$IFDEF DEBUG}, false, 'memberBySSRCAcq()'{$ENDIF DEBUG })) then
	result := nil;
    end;
    //
  finally
    f_members.unlockRO();
  end;
end;

// --  --
procedure unaRTCPstack.memberReleaseRO(member: prtp_site_info);
begin
  if ((nil <> member) and (nil <> member.r_acq)) then
    member.r_acq.releaseRO();
end;

// --  --
procedure unaRTCPstack.memberReleaseWO(member: prtp_site_info);
begin
  if ((nil <> member) and (nil <> member.r_acq)) then
    member.r_acq.releaseWO();
end;

// --  --
function unaRTCPstack.memberSSRCbyIndex(index: int; out ssrc: u_int32): bool;
var
  si: prtp_site_info;
begin
  result := false;
  si := memberByIndexAcq(index, true);
  if (nil <> si) then try
    //
    ssrc := si.r_ssrc;
    result := true;
  finally
    memberReleaseRO(si);
  end;
end;

// --  --
function unaRTCPstack.newMemberAcq(ssrc: u_int32): prtp_site_info;
begin
  result := malloc(sizeof(result^), true);
  result.r_ssrc := ssrc;
  result.r_probation := C_probation_UNINIT;
  result.r_lastRRreceivedTM := timeMarkU();
  //
  result.r_acq := unaObject.create();
  result.r_acq.acquire(false, 1{$IFDEF DEBUG}, false, className + '.newMemberAcq()'{$ENDIF DEBUG });
  //
  f_members.add(result);
  //
  {$IFDEF UNA_SOCKSRTP_LOG_RTCP }
  logMessage(className + '.newMemberAcq() - ** new member, ssrc=' + int2str(ssrc) + ' **');
  {$ENDIF UNA_SOCKSRTP_LOG_RTCP }
end;

// --  --
function unaRTCPstack.sendAPPto(addr: PSockAddrIn; subtype: byte; const cmd: aString; data: pointer; len: uint; sendCNAMEasWell: bool): int;
var
  sz: unsigned;
  pk: prtcp_APP_packet;
  ofs: int;
  buf: pointer;
  bufSz: int;
  i: int32;
  si: prtp_site_info;
begin
  if ((nil <> socketObjRTCP) and ( (nil = addr) or (0 <> addr.sin_addr.S_addr) or (nil <> f_socket_M) )) then begin
    //
    ofs := 0;
    if (sendCNAMEasWell) then begin
      //
      bufSz := issueSDES(ofs, true);
      buf := malloc(bufSz);
      try
	ofs := 0;
	issueSDES(ofs, false, buf);
	//
	//result := sendDataRTCP(addr, buf, ofs);
	//
	//Sleep(10);
      finally
	//mrealloc(buf);
      end;
    end
    else begin
      //
      bufSz := 0;
      buf := nil;
    end;
    //
    sz := align32(sizeof(rtcp_common_hdr) + 8 + unsigned(len));		// allocate 32-bit aligned size
    //
    if (nil = buf) then begin
      //
      pk := malloc(sz, true, 0);
    end
    else begin
      //
      inc(bufSz, sz);
      mrealloc(buf, bufSz);
      pk := prtcp_APP_packet(@(pArray(buf)[ofs]));
      fillChar(pk^, sz, #0);
    end;
    //
    try
      pk.r_common.r_V_P_CNT := RTP_VERSION shl 6 or (subtype and $1F);
      pk.r_common.r_pt := RTCP_APP;
      pk.r_common.r_length_NO_ := rtpLength(sz);
      //
      pk.r_ssrc_NO := swap32u(streamer._ssrc);
      move(cmd[1], pk.r_cmd[0], 4);
      //
      if ((0 < len) and (nil <> data)) then
	move(data^, pk.r_data, len);
      //
      if (nil <> buf) then begin
	//
	pk := buf;
	sz := BufSz;
      end;
      //
      if ((nil <> addr) or (nil <> f_socket_M)) then
	result := sendDataRTCP(addr, pk, sz)
      else begin
	//
	result := 0;
	if (lockNonEmptyList_r(f_members, true, 100)) then try
	  //
	  for i := 0 to f_members.count - 1 do begin
	    //
	    if (shouldStop) then
	      break;
	    //
	    si := memberByIndexAcq(i, true, 10);
	    if (nil <> si) then try
	      //
	      if (si.r_remoteAddrRTCPValid) then
		result := sendDataRTCP(@si.r_remoteAddrRTCP, pk, sz)
	    finally
	      memberReleaseRO(si);
	    end;
	  end;
	finally
	  unlockListRO(f_members);
	end;
      end;
      //
    {$IFDEF UNA_SOCKSRTP_LOG_RTCP_EX }
      logMessage('<-- RTCP APP(' + string(cmd) + ') packet sent to /' + addr2str(addr) + '/, res=' + int2str(result));
    {$ENDIF UNA_SOCKSRTP_LOG_RTCP_EX }
    finally
      if (nil = buf) then
	mrealloc(pk)
      else
	mrealloc(buf);
    end;
    //
    if (0 <> result) then
      f_socketError := result;
  end
  else
    if (nil <> socketObjRTCP) then
      result := 0      // dest address is 0.0.0.0, ignore
    else
      result := WSAENOTSOCK;
end;

// --  --
function unaRTCPstack.sendDataRTCP(addr: PSockAddrIn; data: pointer; len: uint): int;
begin
  {$IFDEF UNA_SOCKSRTP_LOG_SOCKDATA }
    logMessage('RTCP: about to send ' + int2str(len) + ' bytes to ' + addr2str(addr));
  {$ENDIF UNA_SOCKSRTP_LOG_SOCKDATA }
  //
  if (nil <> f_socket_U) then
    result := f_socket_U.sendto(addr^, data, len, false)
  else
    if (nil <> f_socket_M) then
      result := f_socket_M.sendData(data, len, false)
    else
      if (nil <> f_socket_T) then
	result := f_socket_T.send(data, len, false)
      else
	result := 0;
  //
  if ((0 = result) and (nil <> f_streamer)) then
    f_streamer.onDataSent(true, data, len);
end;

// --  --
function unaRTCPstack.sendRTCP(bye: bool): bool;
var
  isBye, isSR: bool;
  u8: uint8;
  u16: uint16;
  //
  i, rr_count, SDESLen: int;
  //
  ofs, hdrOfs: int;
  //
  si: prtp_site_info;
  //
  {$IFDEF UNA_SOCKSRTP_LOG_RTCP_EX }
  res: int;
  pn: string;
  {$ENDIF UNA_SOCKSRTP_LOG_RTCP_EX }
begin
  {$IFDEF UNA_SOCKSRTP_LOG_RTCP_EX }
  rr_count := 0;
  pn := '??';
  {$ENDIF UNA_SOCKSRTP_LOG_RTCP_EX }
  //
  if (bye) then begin
    {*
	A participant which never sent an RTP or RTCP packet MUST NOT send a BYE packet when they leave the group.
    }
    //
    if (f_initial and not f_we_sentEver) then begin
      //
      result := false;
      exit;
    end;
    //
    isBye := true;
    isSR := false;
    {$IFDEF UNA_SOCKSRTP_LOG_RTCP_EX }
    pn := 'BYE';
    {$ENDIF UNA_SOCKSRTP_LOG_RTCP_EX }
  end
  else begin
    //
    isSR := (0 < f_we_sent);	// SR if we have sent something recently, RR otherwise
    isBye := false;
    //
    {$IFDEF UNA_SOCKSRTP_LOG_RTCP_EX }
    pn := choice(isSR, 'SR', 'RR');
    {$ENDIF UNA_SOCKSRTP_LOG_RTCP_EX }
  end;
  //
  if (f_outBufSize < $1000) then begin
    //
    f_outBufSize := $1000;
    mrealloc(f_outBuf, f_outBufSize);	// 4KB, more than any MTU
  end;
  //
  ofs := 0;
  hdrOfs := ofs;
  //
  if (not isBye) then begin
    //
    // this is just to calculate the length of SDES packet, actual SDES data will be added later
    SDESLen := issueSDES(ofs, true);
    //
    if (isSR) then
      issueSRhdr(ofs)
    else
      issueRRhdr(ofs);
  end
  else begin
    //
    issueBYEhdr(ofs);
    SDESLen := 0;
  end;
  //
  if (not isBye) then begin
    //
    i := f_lastRRIndex + 1;
    while ((i <> f_lastRRIndex) and (ofs + 8 + 24 + SDESLen < 1450)) do begin  // reserve some space for UDP headers
      //
      rr_count := 0;
      while ((rr_count < 31) and (ofs + 24 + SDESLen < 1450)) do begin
	//
	if (i >= f_members.count) then
	  i := 0;
	//
	if (f_lastRRIndex > f_members.count) then
	  f_lastRRIndex := f_members.count;
	//
	if (0 < f_members.count) then begin
	  //
	  si := memberByIndexAcq(i, false, 20);
	  if (nil <> si) then try
	    //
	    si.r_noRRsinceLastReport := true;
	    if (not si.r_hardBye and not si.r_timedout and si.r_heardOf and si.r_remoteAddrRTCPValid) then begin
	      //
	      issueRRBlock(ofs, si);
	      //
	      if (rr_count < 31) then
		inc(rr_count)
	      else
		break;
	    end;
	    //
	    si.r_heardOf := false;
	  finally
	    memberReleaseWO(si);
	  end;
	end
	else
	  break;
	//
	if (i = f_lastRRIndex) then
	  break;	// we made a full loop
	//
	inc(i);
      end;
      //
      // update rr_count in packet's header
      u8 := RTP_VERSION shl 6 or rr_count;		// no padding
      move(u8,  f_outBuf[hdrOfs + 0], 1);
      //
      // update length in packet's header
      u16 := swap16u(ofs shr 2 - 1);
      move(u16, f_outBuf[hdrOfs + 2], 2);
      //
      if ((i <> f_lastRRIndex) and (ofs + 8 + 24 + SDESLen < 1450)) then begin  // do we have space for one more RR packet with at least one report block?
	//
	// issue another RR packet
	hdrOfs := ofs;
	issueRRhdr(ofs);
      end
      else
	break;
    end;
    //
    f_lastRRIndex := i;
    //
    // add SDES with CNAME
    issueSDES(ofs, false);
  end;
  //
  // distribute our valuable report among all non-dead members
  if (streamer.isMulticast) then begin
    //
    // use multicast transport
    result := (0 = unaMulticastSocket(socketObjRTCP).sendData(f_outBuf, ofs));
    //
  {$IFDEF UNA_SOCKSRTP_LOG_RTCP_EX }
    logMessage('<-- RTCP ' + pn + ' multicast packet sent, res=' + bool2strStr(result));
  {$ENDIF UNA_SOCKSRTP_LOG_RTCP_EX }
  end
  else begin
    //
    for i := 0 to f_members.count - 1 do begin
      //
      if (shouldStop and not bye) then
	break;
      //
      si := memberByIndexAcq(i, true, 10);
      if (nil <> si) then try
	//
	if (si.r_remoteAddrRTCPValid and not si.r_hardBye) then begin
	  //
	  {$IFDEF UNA_SOCKSRTP_LOG_RTCP_EX }res := {$ENDIF UNA_SOCKSRTP_LOG_RTCP_EX }sendDataRTCP(@si.r_remoteAddrRTCP, f_outBuf, ofs);
	  //
  {$IFDEF UNA_SOCKSRTP_LOG_RTCP_EX }
	  logMessage('<-- RTCP ' + pn + ' packet sent to [' + int2str(si.r_ssrc) + '], res=' + int2str(res));
  {$ENDIF UNA_SOCKSRTP_LOG_RTCP_EX }
	end
	else begin
	  //
  {$IFDEF UNA_SOCKSRTP_LOG_RTCP_EX }
	  logMessage('<-- RTCP ' + pn + ' packet to [' + int2str(si.r_ssrc) + '], was not sent, ' + choice(si.r_remoteAddrRTCPValid, '', 'RTCP is not valid!') + choice(si.r_hardBye, 'Hard BYE', ''));
  {$ENDIF UNA_SOCKSRTP_LOG_RTCP_EX }
	end;
	//
	if (conferenceMode) then
	  break;	// server will re-distribute our packet as needed
	//
      finally
	memberReleaseRO(si);
      end;
    end;
    //
    if (not conferenceMode) then
      streamer.onRTCPPacketSent(f_outBuf, ofs);
    //
    result := true;
  end;
  //
  if (result) then begin
    //
    {*
      If an RTCP packet is transmitted, the value of initial is set to FALSE. Furthermore, the value of avg_rtcp_size is updated:
	avg_rtcp_size = (1/16) * packet_size + (15/16) * avg_rtcp_size
    }
    f_initial := false;
    f_avg_rtcp_size := ofs shr 4 + trunc(15 / 16 * f_avg_rtcp_size);
    //
  {$IFDEF UNA_SOCKSRTP_LOG_RTCP_EX }
    logMessage(':: RTCP.' + pn + ', RR count=' + int2str(rr_count) + ', size/avg=' + int2str(ofs) + '/' + int2str(f_avg_rtcp_size) + '; we_sent=' + int2str(f_we_sent) + '; senders/members=' + int2str(f_senders) + '/' + int2str(f_pmembers));
  {$ENDIF UNA_SOCKSRTP_LOG_RTCP_EX }
  end;
end;

// --  --
procedure unaRTCPstack.startIn();
var
  bindOK: bool;
  sanity: int;
{$IFDEF UNA_SOCKSRTP_LOG_RTCP }
  addr: sockaddr_in;
{$ENDIF UNA_SOCKSRTP_LOG_RTCP }
  isServer: bool;
begin
  if (nil <> socketObjRTCP) then begin
    //
    if (streamer is unaRTPReceiver) then begin
      //
      socketObjRTCP.bindToIP := (streamer as unaRTPReceiver).bind2ip;
      isServer := (streamer as unaRTPReceiver).isServer;
      //
      if (not streamer.isUDP) then begin
	//
	socketObjRTCP.host := streamer.in_socket.host;
	if (not isServer) then
	  socketObjRTCP.setPort(streamer.in_socket.getPortInt() + 1)
	else
	  socketObjRTCP.setPort(bind2port);
      end;
    end
    else
      isServer := false;
    //
    sanity := 100;
    repeat
      //
  {$IFDEF UNA_SOCKSRTP_LOG_RTCP }
      logMessage('RTCP stack, trying port #' + bind2port);
  {$ENDIF UNA_SOCKSRTP_LOG_RTCP }
      //
      if (streamer.isUDP) then
	bindOK := (0 = socketObjRTCP.bindSocketToPort(str2intInt(bind2port, 0)))
      else
	bindOK := true;
      //
      if (not bindOK) then
	f_b2portRTCP := int2str(str2intInt(bind2port, 1000) + 1);
      //
      if (bindOK and not streamer.isUDP) then begin
	//
	if (isServer) then
	  f_socketError := socketObjRTCP.listen()
	else begin
	  //
	  // TCP client will try to connect in execute(), as it might take too long
	end;
      end;
      //
      dec(sanity);
      //
    until (bindOK or (1 > sanity));
    //
    if (not bindOK) then begin
      //
      f_socketError := 10048;
      //
  {$IFDEF UNA_SOCKSRTP_LOG_RTCP }
      logMessage('RTCP stack, fail to bind to a port');
  {$ENDIF UNA_SOCKSRTP_LOG_RTCP }
    end
    else begin
      //
      if ((nil <> f_socket_M) and (streamer is unaRTPReceiver)) then begin
	//
	f_socket_M.setPort(bind2port, true);	// need this so multicast RTCP will send RTCP packets to proper port
						// NOTE: since socket is bound, it will not update the port if noCheck is false
	f_socketError := f_socket_M.mjoin(unaRTPReceiver(streamer).ip, c_unaMC_receive or c_unaMC_send, unaRTPReceiver(streamer).ttl);
      end
      else
	f_socketError := 0;
    end;
  end;
  //
  Randomize();
  //
{*
  Upon joining the session, the participant initializes tp to 0, tc to 0, senders to 0, pmembers to 1,
  members to 1, we_sent to false, rtcp_bw to the specified fraction of the session bandwidth,
  initial to true, and avg_rtcp_size to the probable size of the first RTCP packet that the application
  will later construct.
}
  f_tp := 0;
  f_tn := 0;
  f_pmembers := 0;
  //f_members := 1;
  f_senders := 0;
  f_rtcp_bw := 200;	// FIXME
  f_we_sent := 0;
  f_we_sentEver := false;
  f_avg_rtcp_size := 100;
  f_initial := true;
  //
{*
	The calculated interval T is then computed, and the first packet is scheduled for
	time tn = T. This means that a transmission timer is set which expires at time T.
}
  f_tc := timeMarkU();
  f_tn := calcTI();
  //
{*
	The participant adds its own SSRC to the member table.
	(Not actually needed as for now).
}
  //
  f_rtpTS_no := 0;
  f_rtpPCount := 0;
  f_rtpPSize := 0;
  //
  f_idleThread.start();
  //
  {$IFDEF UNA_SOCKSRTP_RTCP_SEQ_DEBUG }
  f_seq := $F000 + random($1000);
  {$ELSE}
  f_seq := random($10000);
  {$ENDIF UNA_SOCKSRTP_RTCP_SEQ_DEBUG }
  //
  inherited;
  //
  {$IFDEF UNA_SOCKSRTP_LOG_RTCP }
  if (0 = f_socketError) then begin
    //
    socketObjRTCP.getSockAddrBound(addr);
    logMessage('*** === RTCP stack is up, SSRC=' + int2str(streamer._ssrc) + '; boud to: ' + addr2str(@addr) + '=== ***');
  end
  else
    logMessage('*** === RTCP stack cound not bind the socket, error code=' + int2str(socketError) + ' ***');
  {$ENDIF UNA_SOCKSRTP_LOG_RTCP }
end;

// --  --
procedure unaRTCPstack.startOut();
begin
  f_idleThread.stop();
  //
  inherited;
  //
  if (nil <> f_socket_M) then
    f_socket_M.mleave();
  //
  if (nil <> socketObjRTCP) then
    socketObjRTCP.close();
  //
  f_members.clear();
  //
  {$IFDEF UNA_SOCKSRTP_LOG_RTCP }
  logMessage('=== *** RTCP stack is down, SSRC was ' + int2str(streamer._ssrc) + ' *** ===');
  {$ENDIF UNA_SOCKSRTP_LOG_RTCP }
end;

// --  --
function unaRTCPstack.timeNTPnow(var st: SYSTEMTIME): bool;
var
  ntp: unaNTP_timestamp;
begin
  result := getNTP(@ntp);
  if (result) then
    NTP2UTC(ntp, st);
end;

// --  --
procedure unaRTCPstack.timeoutMembers();
var
  i: int;
  si: prtp_site_info;
begin
  i := 0;
  while ( not shouldStop and (i < f_members.count) ) do begin
    //
    si := memberByIndexAcq(i, false, 20);
    if (nil <> si) then try
      //
      if (si.r_ssrc <> streamer._SSRC) then begin
	//
    {$IFDEF UNA_SOCKSRTP_LOG_RTCP_EX }
	logMessage('Member [' + int2str(si.r_ssrc) + '] timeout ?');
    {$ENDIF UNA_SOCKSRTP_LOG_RTCP_EX }
	if (not si.r_hardBye and not si.r_timedout and not si.r_heardOf and si.r_noRRsinceLastReport) then begin  // not heard of and not bye? timeout?
	  //
	  if (si.r_isSender) then begin
	    //
	    if (f_tn * 3 < timeElapsed32U(si.r_lastPayloadTM)) then begin
	      //
	      si.r_isSender := false;
	      //
	      if (0 < f_senders) then
		release32(f_senders);
	    end;
	  end;
	  //
	  if ( (0 < memberTimeoutReports) and (0 <> si.r_lastRRreceivedTM) and (f_tn * unsigned(memberTimeoutReports) < timeElapsed32U(si.r_lastRRreceivedTM)) ) then begin
	    //
    {$IFDEF UNA_SOCKSRTP_LOG_RTCP_EX }
	    logMessage('Member timedout, SSRC=' + int2str(si.r_ssrc) + '; time since last report: ' + int2str(timeElapsed32U(si.r_lastRRreceivedTM)) + ' ms');
    {$ENDIF UNA_SOCKSRTP_LOG_RTCP_EX }
	    //
	    si.r_timedout := true;
	  end;
	end
	else begin
	  //
    {$IFDEF UNA_SOCKSRTP_LOG_RTCP_EX }
	  logMessage('Member [' + int2str(si.r_ssrc) + '] timeout was not checked..');
    {$ENDIF UNA_SOCKSRTP_LOG_RTCP_EX }
	end;
      end;
      //
      if (si.r_byeReported) then begin
	//
	if (si.r_hardBye) then begin
	  //
	  if (si.r_isSender and (0 < f_senders)) then
	    release32(f_senders);
	  //
	  // remove dead member
	  f_members.removeByIndex(i);
	  si := nil;
	  //
	  dec(i);
	end
	else
	  si.r_hardBye := true;
	//
      end
      else begin
	//
	if (si.r_hardBye or si.r_timedout) then begin
	  //
	  if (not si.r_byeReported) then begin
	    //
	    si.r_byeReported := true;
	    //
  {$IFDEF UNA_SOCKSRTP_LOG_RTCP }
	    logMessage('Notify we got timeout (bye) on SSRC=' + int2str(si.r_ssrc));
  {$ENDIF UNA_SOCKSRTP_LOG_RTCP }
	    //
	    streamer.onBye(si, not si.r_hardBye);
	  end;
	end;
      end;
      //
    finally
      memberReleaseWO(si);
    end;
    //
    inc(i);
  end;
end;

// --  --
procedure unaRTCPstack.updateOnSDES(ssrc: u_int32; item: prtcp_sdes_item);
var
  si: prtp_site_info;
begin
  if ((nil <> item) and (RTCP_SDES_CNAME = item.r_type)) then begin
    //
    si := memberBySSRCAcq(ssrc, false, 60);
    if (nil <> si) then try
      //
      if ((nil = si.r_cname) or (si.r_cname.length <> item.length)) then begin
	//
	mrealloc(si.r_cname);
	si.r_cname := malloc(item.length + 2, item);
      end
      else
	move(item.r_data, si.r_cname.r_data, item.length);
      //
    finally
      memberReleaseWO(si);
    end
    else begin
      //
  {$IFDEF UNA_SOCKSRTP_LOG_RTCP_EX }
      logMessage('--> RTCP CNAME [' + int2str(ssrc) + ']: no such member');
  {$ENDIF UNA_SOCKSRTP_LOG_RTCP_EX }
    end;
  end;
end;

// --  --
procedure unaRTCPstack.udapteOnAPP(addr: PSockAddrIn; hdr: prtcp_APP_packet; subtype: int; const cmd: aString; data: pointer; size: int);
var
  ssrc: u_int32;
  si: prtp_site_info;
  resp: punaRTCPRTTReq;
  rtt: uint64;
begin
  if (rttEnabled and (c_rtcp_appCmd_RTT = cmd) and (sizeof(unaRTCPRTTReq) <= size)) then begin
    //
    case (subtype) of

      c_rtcp_appCmd_RTT_stRequest: begin
	//
	// got RTT request, reply asap
	resp := data;
	if (resp.r_dstSSRC = streamer._SSRC) then begin
	  //
	  sendAPPto(addr, c_rtcp_appCmd_RTT_stResponse, cmd, data, size);
	  //
	  {$IFDEF UNA_SOCKSRTP_RTCP_RTT_DEBUG }
	  logMessage('<--> RTT REQ from ' + int2str(swap32(hdr.r_ssrc_NO)) + '@' + addr2str(addr));
	  {$ENDIF UNA_SOCKSRTP_RTCP_RTT_DEBUG }
	end;
      end;

      c_rtcp_appCmd_RTT_stResponse: begin
	//
	// got RTT responce, update SI
	resp := data;
	rtt := timeElapsedU(resp.r_tmU);
	if (resp.r_srcSSRC = streamer._SSRC) then begin
	  //
	  ssrc := swap32u(hdr.r_ssrc_NO);
	  if (ssrc = resp.r_dstSSRC) then begin
	    //
	    si := memberBySSRCAcq(ssrc, true, 10);
	    if (nil <> si) then try
	      //
	      if (si.r_rttMagic = resp.r_magic) then begin
		//
		si.r_rtt := rtt;
		//
	      {$IFDEF UNA_SOCKSRTP_RTCP_RTT_DEBUG }
		logMessage('--> RTT RESP from ' + int2str(ssrc) + '@' + addr2str(addr) + '/RTT=' + int2str(rtt));
	      {$ENDIF UNA_SOCKSRTP_RTCP_RTT_DEBUG }
	      end
	      else begin
		//
	      {$IFDEF UNA_SOCKSRTP_RTCP_RTT_DEBUG }
		logMessage('-!-> RTT RESP from ' + int2str(ssrc) + '@' + addr2str(addr) + ' -- wrong magic.');
	      {$ENDIF UNA_SOCKSRTP_RTCP_RTT_DEBUG }
	      end;
	      //
	    finally
	      memberReleaseRO(si);
	    end;
	  end
	  else begin
	    //
	  {$IFDEF UNA_SOCKSRTP_RTCP_RTT_DEBUG }
	    logMessage('-!-> RTT RESP, req is ours, but resp from wrong party (got ' + int2str(ssrc) + ', exp ' + int2str(resp.r_dstSSRC) + ') @' + addr2str(addr));
	  {$ENDIF UNA_SOCKSRTP_RTCP_RTT_DEBUG }
	  end;
	  //
	end
	else begin
	  //
	{$IFDEF UNA_SOCKSRTP_RTCP_RTT_DEBUG }
	  logMessage('-!-> RTT RESP, req is not ours (got ' + int2str(resp.r_srcSSRC) + ', exp ' + int2str(streamer._SSRC) + ') @' + addr2str(addr));
	{$ENDIF UNA_SOCKSRTP_RTCP_RTT_DEBUG }
	end;
	//
      end;

    end; // case
    //
  end;
end;

// --  --
procedure unaRTCPstack.updateOnRR(addr: PSockAddrIn; hdr: prtcp_RR_packet);
var
  si: prtp_site_info;
  ssrc: u_int32;
begin
  if (nil <> hdr) then begin
    //
    ssrc := swap32u(hdr.r_ssrc_NO);
    si := memberBySSRCAcq(ssrc, false, 20);
    if (nil <> si) then try
      //
      si.r_lastRRreceivedTM := timeMarkU();
      si.r_noRRsinceLastReport := false;
      si.r_timedout := si.r_hardBye;
    finally
      memberReleaseWO(si);
    end;
  end;
end;

// --  --
procedure unaRTCPstack.updateOnSR(addr: PSockAddrIn; hdr: prtcp_SR_packet);
var
  si: prtp_site_info;
  ssrc: u_int32;
begin
  if (nil <> hdr) then begin
    //
    ssrc := swap32u(hdr.r_ssrc_NO);
    si := memberBySSRCAcq(ssrc, false, 20);
    if (nil <> si) then try
      //
      si.r_lastSRreceived := (swap32u(hdr.r_ntp_NO.r_seconds) shl 16) or uint32(swap16u(hdr.r_ntp_NO.r_fraction and $FFFF));
      si.r_lastSRreceivedTM := timeMarkU();
      si.r_lastRRreceivedTM := si.r_lastSRreceivedTM;
      //
      si.r_noRRsinceLastReport := false;
      si.r_timedout := si.r_hardBye;
    finally
      memberReleaseWO(si);
    end;
  end;
end;

// --  --
function unaRTCPstack.update_seq(ssrc: u_int32; seq: u_int16): bool;
var
  //i: int;
  ok: bool;
  si: prtp_site_info;
  udelta: u_int16;
begin
  if ( (ssrc = streamer._SSRC) and {$IFDEF DEBUG } not conferenceMode{$ELSE }true{$ENDIF DEBUG } ) then begin  // in debug conference we can hear ourself
    //
  {$IFDEF UNA_SOCKSRTP_LOG_RTCP }
    logMessage(className + '.update_seq() - loopback SSRC');
  {$ENDIF UNA_SOCKSRTP_LOG_RTCP }
    //
    result := false;
    exit;
  end;
  //
  {*
	The routine update_seq shown below ensures that a source is declared
	valid only after MIN_SEQUENTIAL packets have been received in
	sequence.  It also validates the sequence number seq of a newly
	received packet and updates the sequence state for the packet's
	source in the structure to which s points.
  }
  //
  si := memberBySSRCAcq(ssrc, false, 40);
  if ((nil = si) or ((nil <> si) and (C_probation_UNINIT = si.r_probation))) then begin
    //
    {*
	When a new source is heard for the first time, that is, its SSRC
	identifier is not in the table (see Section 8.2), and the per-source
	state is allocated for it, s->probation is set to the number of
	sequential packets required before declaring a source valid
	(parameter MIN_SEQUENTIAL) and other variables are initialized:
    }
    if ( (nil = si) and (0 > f_members.indexOfId(ssrc)) ) then
      si := newMemberAcq(ssrc);
    //
    if (nil <> si) then begin
      //
      init_seq(si, seq);
      //
    {$IFDEF UNA_SOCKSRTP_LOG_RTP }
      logMessage(className + '.update_seq(?) - SSRC=' + int2str(ssrc) + ' seq was initialized to ' + int2str(seq));
    {$ENDIF UNA_SOCKSRTP_LOG_RTP }
      //
      if (0 < seq) then
	si.r_max_seq := seq - 1
      else
	si.r_max_seq := $FFFF;
      //
      si.r_probation := MIN_SEQUENTIAL;
    end;
  end;
  //
  if (nil <> si) then try
    //
    if (conferenceMode and (nil <> si) and (0 = f_members.indexOfId(ssrc))) then begin
      //
      // when in conference mode, server seq# is usually out of seq. Just ignore it
      result := true;
    end
    else begin
      //
    {$IFOPT R+ }
      {$DEFINE 5240629F_4CD4_47C0_A82C_F0F765B34960 }
    {$ENDIF R+ }
      {$R-}// otherwise it will fail if seq < si.r_max_seq
      udelta := u_int16(seq - si.r_max_seq);
    {$IFDEF 5240629F_4CD4_47C0_A82C_F0F765B34960 }
      {$R+ }
    {$ENDIF 5240629F_4CD4_47C0_A82C_F0F765B34960 }
      //
      {
	    A non-zero s->probation marks the source as not yet valid so the
	    state may be discarded after a short timeout rather than a long one,
	    as discussed in Section 6.2.1

	    * Source is not valid until MIN_SEQUENTIAL packets with
	    * sequential sequence numbers have been received.
      }
      if (0 < si.r_probation) then begin
	//
	//* packet is in sequence? */
	if ($FFFF = si.r_max_seq) then
	  ok := (0 = seq)
	else
	  ok := (seq = si.r_max_seq + 1);
	//
	if (ok) then begin
	  //
	  dec(si.r_probation);
	  si.r_max_seq := seq;
	  //
	{$IFDEF UNA_SOCKSRTP_LOG_RTP }
	  logMessage(className + '.update_seq(OK) - probation for prob.SSRC=' + int2str(ssrc) + ' was decreased to ' + int2str(si.r_probation));
	{$ENDIF UNA_SOCKSRTP_LOG_RTP }
	  //
	  if (0 = si.r_probation) then
	    init_seq(si, seq);
	  //
	  result := true;
	end
	else begin
	  //
	{$IFDEF UNA_SOCKSRTP_LOG_RTP }
	  logMessage(className + '.update_seq(FAIL) - bad seq for prob.SSRC=' + int2str(ssrc) + ', expecting ' + int2str(int(si.r_max_seq + 1)) + ', but got ' + int2str(seq));
	{$ENDIF UNA_SOCKSRTP_LOG_RTP }
	  //
	  si.r_probation := MIN_SEQUENTIAL - 1;
	  si.r_max_seq := seq;
	  //
	  result := false;
	end;
      end
      else begin
	//
	{
	    After a source is considered valid, the sequence number is considered
	    valid if it is no more than MAX_DROPOUT ahead of s->max_seq nor more
	    than MAX_MISORDER behind. If the new sequence number is ahead of
	    max_seq modulo the RTP sequence number range (16 bits), but is
	    smaller than max_seq, it has wrapped around and the (shifted) count
	    of sequence number cycles is incremented.  A value of one is returned
	    to indicate a valid sequence number.
	}
	if (udelta < MAX_DROPOUT) then begin
	  //
	  //* in order, with permissible gap */
	  if (seq < si.r_max_seq) then begin
	    //
	  {$IFDEF UNA_SOCKSRTP_LOG_RTCP_EX }
	    logMessage(className + '.update_seq(OK) - for SSRC=' + int2str(ssrc) + ' seq wrap around: ' + int2str(si.r_max_seq + 1) + '   -   got: ' + int2str(seq));
	  {$ENDIF UNA_SOCKSRTP_LOG_RTCP_EX }
	    {
	      Sequence number wrapped - count another 64K cycle.
	    }
	    si.r_cycles := si.r_cycles + RTP_SEQ_MOD;
	  end;
	  //
	{$IFDEF UNA_SOCKSRTP_LOG_RTCP }
	  if (1 < udelta) then
	    logMessage(className + '.update_seq(OK) - for SSRC=' + int2str(ssrc) + ' expected: ' + int2str(int(si.r_max_seq + 1)) + '   -   got: ' + int2str(seq));
	{$ENDIF UNA_SOCKSRTP_LOG_RTCP }
	  //
	  si.r_max_seq := seq;
	  result := true;
	end
	else begin
	  //
	  if (udelta <= RTP_SEQ_MOD - MAX_MISORDER) then begin
	    //
	    // the sequence number made a very large jump */
	    if (seq = si.r_bad_seq) then begin
	      //
	      {
		Two sequential packets -- assume that the other side
		restarted without telling us so just re-sync
		(i.e., pretend this was the first packet).
	      }
	    {$IFDEF UNA_SOCKSRTP_LOG_RTCP }
	      if (1 < udelta) then
		logMessage(className + '.update_seq(OK) - for SSRC=' + int2str(ssrc) + ' two seq packets: ' + int2str(int(si.r_max_seq + 1)) + '   -   got: ' + int2str(seq));
	    {$ENDIF UNA_SOCKSRTP_LOG_RTCP }
	      //
	      init_seq(si, seq);
	      result := true;
	    end
	    else begin
	      //
	      {
		    Otherwise, the value zero is returned to indicate that the validation
		    failed, and the bad sequence number plus 1 is stored.  If the next
		    packet received carries the next higher sequence number, it is
		    considered the valid start of a new packet sequence presumably caused
		    by an extended dropout or a source restart.  Since multiple complete
		    sequence number cycles may have been missed, the packet loss
		    statistics are reset.
	      }
	      si.r_bad_seq := (seq + 1) and (RTP_SEQ_MOD - 1);
	      //
	    {$IFDEF UNA_SOCKSRTP_LOG_RTCP }
	      if (1 < udelta) then
		logMessage(className + '.update_seq(FAIL) - for SSRC=' + int2str(ssrc) + ' bad seq, exp: ' + int2str(int(si.r_max_seq + 1)) + '   -   got: ' + int2str(seq) + ' / r_bad_seq := ' + int2str(si.r_bad_seq));
	    {$ENDIF UNA_SOCKSRTP_LOG_RTCP }
	      //
	      result := false;
	    end;
	  end
	  else begin
	    //* duplicate or reordered packet */
	  {$IFDEF UNA_SOCKSRTP_LOG_RTCP }
	    if (1 < udelta) then
	      logMessage(className + '.update_seq(FAIL) - for SSRC=' + int2str(ssrc) + ' duplicate or reordered packet, exp: ' + int2str(int(si.r_max_seq + 1)) + '   -   got: ' + int2str(seq));
	  {$ENDIF UNA_SOCKSRTP_LOG_RTCP }
	    //
	    result := false;
	  end;
	end;
      end;
      //
      if (result) then begin
	//
    {$IFOPT Q+ }
      {$DEFINE 1A203308_ED95_4644_9499_A528987687D9 }
    {$ENDIF Q+ }
    {$Q- }
	inc(si.r_received);
    {$IFDEF 1A203308_ED95_4644_9499_A528987687D9 }
      {$Q+ }
    {$ENDIF 1A203308_ED95_4644_9499_A528987687D9 }
	inc(si.r_stat_received);
      end;
      //
    end;
  finally
    memberReleaseWO(si);
  end
  else
    result := false;
end;

// --  --
procedure unaRTCPstack.weSentRTP(addr: PSockAddrIn; hdr: prtp_hdr; payloadLen: uint);
begin
  if ((nil <> self) and (5 > f_we_sent)) then begin
    //
    if (acquire32NonExclusive(f_we_sent)) then	// just increase the count
      acquire32NE(f_senders);	// we also became a sender
  end;
  //
  f_we_sentEver := true;
  //
  f_rtpTS_no := hdr.r_timestamp_NO;
  //
  if (0 < payloadLen) then
    inc(f_rtpPCount);
  //
  if (0 < payloadLen) then
    inc(f_rtpPSize, payloadLen);
end;


{ unaRTPStreamer }

// --  --
procedure unaRTPStreamer.AfterConstruction();
begin
  f_userName := className;
  //
  inherited;
end;

// --  --
procedure unaRTPStreamer.BeforeDestruction();
begin
  stop();
  //
  inherited;
  //
  freeAndNil(f_rtcp);
  freeAndNil(f_socket_UCP);
end;

// --  --
function unaRTPStreamer.grantStop(): bool;
begin
  result := inherited grantStop();
  //
  if (result and not f_pingsockInProgress) then
    pingsock();
end;

// --  --
procedure unaRTPStreamer.onBye(si: prtp_site_info; soft: bool);
begin
  //
end;

procedure unaRTPStreamer.onDataSent(rtcp: bool; data: pointer; len: uint);
begin
  //
end;

// --  --
procedure unaRTPStreamer.onIdle(rtcpIdle: bool);
begin
  //
end;

// --  --
procedure unaRTPStreamer.onPayload(addr: PSockAddrIn; hdr: prtp_hdr; data: pointer; len, packetSize: uint);
begin
  //
end;

// --  --
procedure unaRTPStreamer.onRTCPPacket(ssrc: u_int32; addr: PSockAddrIn; hdr: prtcp_common_hdr; packetSize: uint);
begin
  //
end;

// --  --
procedure unaRTPStreamer.onSsrcCNAME(ssrc: u_int32; cname: prtcp_sdes_item);
begin
  //
end;

// --  --
procedure unaRTPStreamer.pingsock();
var
  sock: tSocket;
  nl: int32;
  addr: sockaddr_in;
begin
  if (isUDP and (nil <> in_socket)) then begin
    //
    sock := socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if (INVALID_SOCKET <> sock) then try
      //
      nl := sizeof(addr);
      if (0 = getsockname(in_socket.handle, addr, nl)) then begin
	//
	if (0 = addr.sin_addr.S_addr) then
	  addr.sin_addr.S_addr := u_long(str2ipN('127.0.0.1'));
	//
	{$IFDEF UNA_SOCKSRTP_LOG_SOCKDATA }
	  logMessage('RTP: pingsock() ' + int2str(1) + ' bytes to local socket.');
	{$ENDIF UNA_SOCKSRTP_LOG_SOCKDATA }
	//
	f_pingsockInProgress := true;
	f_pingsockDone := (0 < sendto(sock, nl, 1, 0, addr, sizeof(addr)));	// send 1 byte of any data
      end;
      //
    finally
      closesocket(sock);
    end;
  end;
end;

// --  --
procedure unaRTPStreamer.onRTCPPacketSent(packet: pointer; len: uint);
begin
  //
end;

// --  --
procedure unaRTPStreamer.rentSockets(doRent: bool);
begin
  f_socketNoReading := doRent;
end;

// --  --
procedure unaRTPStreamer.startIn();
begin
  inherited;
  //
  f_cname8 := utf162utf8(userName + '@' + hostName());
  //
  f_pingsockInProgress := false;
  f_pingsockDone := false;
end;


{ unaRTPReceiver }

// --  --
constructor unaRTPReceiver.create(const bind2addr: TSockAddrIn; remoteAddr: PSockAddrIn; noRTCP: bool; transmitter: unaRTPTransmitter; ttl: int; isUDP: bool; isRAW: bool; role: c_peer_role);
var
{$IFDEF NO_ANSI_SUPPORT }
{$ELSE }
  nameA: array[byte] of aChar;
{$ENDIF NO_ANSI_SUPPORT }
  nameW: array[byte] of wChar;
  sz: DWORD;
  ipH: TIPv4H;
  port: word;
begin
  self.isRAW := isRAW;
  self.noRTCP := noRTCP;
  f_isUDP := isUDP;
  f_role := role;
  self.ttl := ttl;
  //
  ipH := ipN2ipH(remoteAddr);
  f_ip := ipH2str(ipH);
  //
  f_transmitter := transmitter;
  f_tcp_clients := unaList.create(uldt_obj);		// take care of object's disposal
  //
  f_isMC := isMulticastAddr(f_ip);
  if ((nil <> remoteAddr) and (nil = transmitter)) then
    f_mcport := ntohs(remoteAddr.sin_port)
  else
    f_mcport := 0;
  //
  if (not isRAW and not noRTCP) then
    f_rtcp := unaRTCPstack.create(self, (nil <> f_transmitter));
  //
  inherited create(false, THREAD_PRIORITY_HIGHEST);
  //
  if (isMulticast) then begin
    //
    f_socket_UCP := unaMulticastSocket.create({$IFDEF VC25_OVERLAPPED }false{$ENDIF VC25_OVERLAPPED });
    in_socket.bindToPort := int2str(f_mcport);
    //
    in_socket.setPort(portHFromAddr(remoteAddr));
  end
  else begin
    //
    if (isUDP) then
      f_socket_UCP := unaUDPSocket.create({$IFDEF VC25_OVERLAPPED }false{$ENDIF VC25_OVERLAPPED })
    else begin
      //
      f_socket_UCP := unaTCPSocket.create({$IFDEF VC25_OVERLAPPED }false{$ENDIF VC25_OVERLAPPED });
      in_socket.host := f_ip;
      //
      case (f_role) of

	pr_active:  f_isServer := false;
	pr_passive: f_isServer := true;
	else begin
	  //
	  f_isServer := ('0.0.0.0' = f_ip) or ('' = f_ip);
	end;
      end;
      //
      if (not isServer) then begin
	//
	if (nil <> remoteAddr) then
	  port := htons(remoteAddr.sin_port)
	else
	  port := htons(bind2addr.sin_port);
      end
      else
	port := htons(bind2addr.sin_port);
      //
      in_socket.setPort(port);
    end;
  end;
  //
  f_bind2ip := ipH2str(ipN2ipH(@bind2addr));
  f_bind2port := int2str(ntohs(bind2addr.sin_port));
  //
  if ('9' = f_bind2port) then
    f_bind2port := '0';	// use any port
  //
  randomize();
  //
  sz := 255;
{$IFNDEF NO_ANSI_SUPPORT }
  if (g_wideApiSupported) then begin
{$ENDIF NO_ANSI_SUPPORT }
    //
    GetComputerNameW(nameW, sz);
{$IFNDEF NO_ANSI_SUPPORT }
  end
  else begin
    //
    GetComputerNameA(nameA, sz);
    str2arrayW(wString(nameA), nameW);
  end;
{$ENDIF NO_ANSI_SUPPORT }
end;

// --  --
procedure unaRTPReceiver.AfterConstruction();
begin
  inherited;
  //
  CN_resendInterval := c_def_CNresendInterval;	// 12 sec
  //
  f_tcp_bufLock := unaObject.create();
end;

// --  --
procedure unaRTPReceiver.BeforeDestruction();
begin
  inherited;
  //
  freeAndNil(f_tcp_bufLock);
end;

constructor unaRTPReceiver.create(isRAW: bool);
begin
  self.isRAW := isRAW;
  self.noRTCP := true;
  f_isUDP := true;
  f_isServer := false;
  //
  f_tcp_clients := unaList.create(uldt_obj);		// take care of object's disposal
  //
  inherited create(false);
end;

// --  --
function unaRTPReceiver.execute(threadID: unsigned): int;

var
  dataBuf: pointer;	//
  bufSize: int;		//
  //
  tot: int;		// current socket timeout
  //
  tcpbuf: pArray;	// pointer in buf to tcp data
  tcpbufUsed: int;	// size of tcp data collected so far
  tcpPacketSize: int;	// size of tcp packet being received
  //
  dataPtr: pointer;	// pointer to UDP or TCP data received

  // --  --
  function readTcpSocket(socket: unaTCPSocket; out dataSize: int): int;
  var
    szu: uint;
  begin
    if (isRaw) then begin
      //
      szu := bufSize;
      result := socket.read(dataBuf, szu, tot, false);
      if (0 = result) then
	dataSize := szu
      else
	dataSize := 0;
    end
    else begin
      //
      // already reported full packet?
      if ((0 < tcpPacketSize) and (tcpbufUsed >= tcpPacketSize)) then begin
	//
	// move buffer ptr forward by one packet
	inc(pUint8(tcpbuf), tcpPacketSize);
	dec(tcpbufUsed, tcpPacketSize);
	//
	// indicate we have to parse new packet
	tcpPacketSize := -1;
	//
	// see if we should move data to the beginning of buffer
	if ( (paChar(tcpbuf) - paChar(dataBuf)) > bufSize div 2) then begin
	  //
	  if (0 < tcpbufUsed) then
	    move(tcpbuf^, dataBuf^, tcpbufUsed);
	  //
	  tcpbuf := dataBuf;
	end;
      end;
      //
      szu := bufSize - tcpbufUsed - (paChar(tcpbuf) - paChar(dataBuf));
      result := socket.read(@tcpbuf[tcpbufUsed], szu, tot, false);
      //
      dataSize := 0;
      if (0 = result) then begin
	//
	inc(tcpbufUsed, szu);
	//
	// if we haven't received packet's size yet, and got at least 2 bytes so far, extract packet size
	if ((0 > tcpPacketSize) and (2 <= tcpbufUsed)) then begin
	  //
	  move(tcpbuf^, tcpPacketSize, 2);
	  tcpPacketSize := swap16u(unsigned(tcpPacketSize));
	  //
	  dec(tcpbufUsed, 2);
	  inc(pUint8(tcpbuf), 2);
	end;
	//
	// got packet size? see if we got full packet
	if (0 < tcpPacketSize) then begin
	  //
	  if (tcpbufUsed >= tcpPacketSize) then begin
	    //
	    dataSize := tcpPacketSize;
	    dataPtr := tcpbuf;
	  end;
	end;
      end;
    end;
  end;

var
  sz: int;
  hdr: prtp_hdr;
  hdrSize: int;
  paddingSize: int;
  ok: bool;
  addr: sockaddr_in;
  //
  i: int;
  maxTot: int;
  error: int;
  clientsToRemove: unaList;
  newSocket: unaSocket;
  //
  tcpReadResult: int;	// status of last read operation
  //
  tcpSocket: unaTCPSocket;
begin
  if (0 <> socketError) then begin
    //
    result := -1;
    exit;
  end;
  //
  if (not isUDP) then
    bufSize := 14096
  else
    bufSize := 4096;
  //
  dataBuf := malloc(bufSize);
  tcpbuf := dataBuf;
  tcpbufUsed := 0;
  tcpPacketSize := -1;
  //
  dataPtr := dataBuf;
  //
  tot := 100;
  //
  if (isServer) then
    clientsToRemove := unaList.create(uldt_ptr)	// does not care about disposal
  else
    clientsToRemove := nil;
  //
  if (not isUDP and (nil <> in_socket)) then begin
    //
    tcppacketsize := 0;
    ///
    sleep(100);
    if (isServer) then
      f_socketError := in_socket.listen()
    else
      f_socketError := in_socket.connect();
    //
    in_socket.getSockAddrBound(addr);
    f_portL := int2str(swap16u(addr.sin_port));
    //
    in_socket.getSockAddr(addr);
    //
    if (isServer) then
      maxTot := 50
    else
      maxTot := 500;
  end
  else begin
    //
    f_socketError := 0;
    maxTot := 1800;
  end;
  //
  try
    while ((0 = socketError) and not shouldStop) do begin
      //
      try
	if (isUDP) then begin
	  //
	  if (nil <> in_socket) then begin
	    //
	    if (not socketNoReading) then
	      sz := unaUDPSocket(in_socket).recvfrom(addr, dataBuf, bufSize, false, 0, tot)
	    else begin
	      //
	      sz := 0;
	      sleepThread(10);
	    end;
	  end
	  else
	    sz := 0;
	  //
	  if (sz > int(bufSize)) then        // should not happen, but who knows
	    sz := bufSize;
	end
	else begin
	  //
	  if (isServer and (nil <> in_socket)) then begin
	    //
	    newSocket := in_socket.accept(error, 1);	// 1 ms. delay
	    if (nil <> newSocket) then begin
	      // add new connection
	      if (f_tcp_clients.count < v_maxSrv_clients) then
		f_tcp_clients.add(newSocket);
	    end;
	    //
	    sz := 0;
	    if (lockNonEmptyList_r(f_tcp_clients, true, 100)) then try
	      //
	      for i := 0 to f_tcp_clients.count - 1 do begin
		//
		tcpSocket := unaTCPSocket(f_tcp_clients[i]);
		tcpReadResult := readTcpSocket(tcpSocket, sz);
		if (0 = tcpReadResult) then begin
		  //
		  tcpSocket.getSockAddr(addr);
		  //
		  // can handle only one client at a time
		  break;
		end
		else begin
		  //
		  // see if client got closed due to error
		  if (not tcpSocket.isConnected(1)) then
		    clientsToRemove.add(f_tcp_clients[i]);
		  //
		  sz := 0;
		end;
	      end;
	    finally
	      unlockListRO(f_tcp_clients);
	    end;
	    //
	    for i := 0 to clientsToRemove.count - 1 do
	      f_tcp_clients.removeItem(clientsToRemove[i]);
	    //
	    clientsToRemove.clear();
	  end
	  else
	    if (0 <> readTcpSocket(unaTCPSocket(in_socket), sz)) then
	      sz := 0;
	end;
	//
	if (0 < sz) then
	  tot := 1
	else begin
	  //
	  if (tot < maxTot) then
	    tot := tot shl 1;
	end;
	//
	if ((0 < sz) and not f_pingsockInProgress) then begin
	  //
	{$IFDEF UNA_SOCKSRTP_LOG_SOCKDATA }
	  logMessage('RTP: got ' + int2str(sz) + ' bytes from ' + addr2str(@addr));
	{$ENDIF UNA_SOCKSRTP_LOG_SOCKDATA }
	  //
	  hdr := dataPtr;
	  hdrSize := 0;
	  paddingSize := 0;
	  //
	  if (isRAW) then
	    ok := true
	  else begin
	    //
	    // check RTP packet header
	    if (sizeof(hdr^) <= sz) then begin
	      //
	      // weak validity checks
	      ok := (RTP_VERSION = hdr.r_V_P_X_CC shr 6) and (RTCP_SR <> hdr.r_M_PT and $7F) and (RTCP_RR <> hdr.r_M_PT and $7F);
	      if (ok) then begin
		//
		f_broken := 0;
		//
		hdrSize := sizeof(hdr^) + (hdr.r_V_P_X_CC and $0F) shl 2;
		if (0 <> (hdr.r_V_P_X_CC shr 5 and $1)) then
		  paddingSize := pArray(dataPtr)[sz - 1]
		else
		  paddingSize := 0;
		//
		if (nil <> rtcp) then begin
		  //
		  rtcp.gotRTPpacket(@addr, hdr, sz);
		  ok := rtcp.update_seq(swap32u(hdr.r_ssrc_NO), swap16u(hdr.r_seq_NO));
		end;
	      end
	      else begin
		//
		inc(f_broken);
		if (4 < f_broken) then // 5 or more broken successive packets, switch to RAW .
		  isRaw := true;
	      end;
	    end
	    else
	      ok := false;
	  end;
	  //
	  if (ok) then
	    onPayload(@addr, hdr, @pArray(dataPtr)[hdrSize], int(sz) - hdrSize - paddingSize, sz);
	end
	else
	  sz := 0;
	//
	if (1 > sz) then begin
	  //
	  if (not isUDP) then
	    sleepThread(10);
	end;
	//
      except
      end;
    end;
    //
  finally
    mrealloc(dataBuf);
    //
    freeAndNil(clientsToRemove);
  end;
  //
  result := 0;
end;

// --  --
procedure unaRTPReceiver.onBye(si: prtp_site_info; soft: bool);
begin
  inherited;
  //
  if (nil <> f_transmitter) then
    f_transmitter.notifyBye(si, soft);
end;

// --  --
procedure unaRTPReceiver.onIdle(rtcpIdle: bool);
var
  i: int;
  si: prtp_site_info;
begin
  inherited;
  //
  if ( (nil <> rtcp) and rtcpIdle ) then begin
    //
    if (1 > rtcp.f_members.count) then
      onNeedRTPHole(nil)
    else begin
      //
      i := f_lastIdleCheckIndex;
      if (i >= rtcp.f_members.count) then
	i := 0;
      //
      si := rtcp.memberByIndexAcq(i, true, 20);
      if (nil <> si) then try
	//
	if (_SSRC <> si.r_ssrc) then begin
	  //
	  if ( (1 > si.r_received) or ((0 < CN_resendInterval) and (CN_resendInterval < timeElapsed64U(si.r_lastPayloadTM))) ) then
	    onNeedRTPHole(si);
	end
	else begin
	  //
	  // there is only 1 member, and this member is me?
	  if (2 > rtcp.f_members.count) then
	    onNeedRTPHole(nil);
	end;
	//
      finally
	rtcp.memberReleaseRO(si);
      end;
      //
      f_lastIdleCheckIndex := i;
    end;
  end;
  //
  if (nil <> f_transmitter) then
    f_transmitter.onIdle(rtcpIdle);
end;

// --  --
procedure unaRTPReceiver.onNeedRTPHole(si: prtp_site_info);
begin
  //
end;

// --  --
procedure unaRTPReceiver.onPayload(addr: PSockAddrIn; hdr: prtp_hdr; data: pointer; len, packetSize: uint);
begin
  inherited;
  //
  if (nil <> f_transmitter) then
    f_transmitter.onPayload(addr, hdr, data, len, packetSize);
end;

// --  --
procedure unaRTPReceiver.onRTCPPacket(ssrc: u_int32; addr: PSockAddrIn; hdr: prtcp_common_hdr; packetSize: uint);
begin
  inherited;
  //
  if (nil <> f_transmitter) then
    f_transmitter.onRTCPPacket(ssrc, addr, hdr, packetSize);
end;

// --  --
procedure unaRTPReceiver.onSsrcCNAME(ssrc: u_int32; cname: prtcp_sdes_item);
begin
  inherited;
  //
  if (nil <> f_transmitter) then
    f_transmitter.onSsrcCNAME(ssrc, cname);
end;

procedure unaRTPReceiver.onRTCPPacketSent(packet: pointer; len: uint);
begin
  inherited;
  //
  if (nil <> f_transmitter) then
    f_transmitter.onRTCPPacketSent(packet, len);
end;

// --  --
function unaRTPReceiver.sendRTP_To(addr: PSockAddrIn; payloadType: byte; payload: pointer; len: int; mark: bool): int;
var
  dataSize: word;
  tcpBuf: pUint16;
  hdr: prtp_hdr;
  rtcpStack: unaRTCPstack;
begin
  if ((nil <> in_socket) and ((0 <> addr.sin_addr.S_addr) or not isUDP)) then begin
    //
    if ((len < 0) or (nil = payload)) then
      len := 0;
    //
    dataSize := choice(isUDP, 0, int(2)) + sizeof(rtp_hdr) + len;
    hdr := malloc(dataSize);
    try
      if (not isUDP) then begin
	//
	tcpBuf := pointer(hdr);
	tcpBuf^ := swap16u(dataSize - 2);
	//
	// shift header pointer by 2 bytes
	hdr := prtp_hdr(@pByte(hdr)[2]);
      end
      else
        tcpBuf := nil;
      //
      hdr.r_V_P_X_CC := (RTP_VERSION shl   6) and $C0;	// no padding, no extension, no CSRC
      hdr.r_M_PT     := (payloadType and $7F) or choice(mark, $80, uint(0));
      //
      if (nil <> f_transmitter) then
	rtcpStack := f_transmitter.rtcp
      else
	rtcpStack := rtcp;
      //
      if (nil <> rtcpStack) then
	hdr.r_seq_NO := swap16u(rtcpStack.getNextSeq())
      else
	hdr.r_seq_NO := swap16u(1);
      //
      hdr.r_timestamp_NO := swap32u(0);	// TODO: should be calculated properly
      //
      if (nil <> f_transmitter) then
	hdr.r_ssrc_NO := swap32u(f_transmitter._ssrc)
      else
	hdr.r_ssrc_NO := swap32u(_ssrc);
      //
    {$IFDEF UNA_SOCKSRTP_LOG_RTP_EX }
      logMessage('About to send RTP (' + int2str(payloadType) + ') to [' + addr2str(addr) + ']');
    {$ENDIF UNA_SOCKSRTP_LOG_RTP_EX }
      //
      // put payload in place
      if (0 < len) then
	move(payload^, pUint8Array(hdr)[sizeof(rtp_hdr)], len);
      //
      if (isUDP) then
	result := unaUDPSocket(in_socket).sendto(addr^, hdr, dataSize, 0, 50, false)
      else
	result := sendTCPData_To(addr, tcpBuf, dataSize, true);
      //
      if (0 <> result) then
	f_socketError := result;
      //
      if (0 = result) then
	onDataSent(false, hdr, sizeof(rtp_hdr) + 1);
      //
    finally
      mrealloc(hdr);
    end;
  end
  else
    if (nil <> in_socket) then
      result := 0       // dest address is 0.0.0.0, ignore
    else
      result := WSAENOTSOCK;
end;

// --  --
function unaRTPReceiver.sendRTP_CN_To(addr: PSockAddrIn): int;
var
  p: byte;
begin
  p := 0;
  result := sendRTP_To(addr, c_rtpPTa_CN, @p, 1, false);
end;

// --  --
function unaRTPReceiver.sendTCPData_To(addr: PSockAddrIn; packet: pointer; packetSize: uint; lenAlreadyPrefixed: bool): int;
var
  i: int32;
  sockAddr: sockaddr_in;
  bufRelease: bool;
  bufSize: word;
begin
  if (nil <> packet) then begin
    //
    result := WSAENOTSOCK;
    //
    bufRelease := false;
    try
      if (not lenAlreadyPrefixed) then begin
	//
	if (f_tcp_bufLock.acquire(false, 100)) then try
	  //
	  if (f_tcp_bufSize < int(packetSize) + 2) then begin
	    //
	    f_tcp_bufSize := packetSize + 2;
	    f_tcp_buf := malloc(f_tcp_bufSize);
	  end;
	  //
	  bufSize := swap16u(packetSize);
	  move(bufSize, f_tcp_buf^, 2);
	  move(packet^, pArray(f_tcp_buf)[2], packetSize);
	  //
	  // update pointer and packet length
	  packet := f_tcp_buf;
	  inc(packetSize, 2);
	finally
	  bufRelease := true;
	end
	else begin
	  //
	  // unable to lock the buffer, return error
	  result := WSAEACCES;
	  exit;
	end;
      end;
      //
      if ( isServer ) then begin
	//
	if ( lockNonEmptyList_r(f_tcp_clients, true, 100) ) then try
	  //
	  for i := 0 to f_tcp_clients.count - 1 do begin
	    //
	    unaTCPSocket(f_tcp_clients[i]).getSockAddr(sockAddr);
	    if (sameAddr(sockAddr, addr^)) then begin
	      //
	      result := unaTCPSocket(f_tcp_clients[i]).send(packet, packetSize);
	      //
	      break;
	    end;
	  end;
	finally
	  unlockListRO( f_tcp_clients );
	end;
      end
      else
	result := in_socket.send(packet, packetSize);
      //
    finally
      if (bufRelease) then
	f_tcp_bufLock.releaseWO();
    end;
  end
  else
    result := WSAEBADF;
end;

// --  --
procedure unaRTPReceiver.setNewSSRC(newssrc: u_int32);
begin
  f_ssrcParent := newssrc;
end;

// --  --
procedure unaRTPReceiver.startIn();
var
  addr: sockaddr_in;
begin
  inherited;
  //
  f_broken := 0;
  if (0 = f_ssrcParent) then begin
    //
    f_ssrc := 0;
    while (0 = f_ssrc) do
      f_ssrc := u_int32(random( integer($FFFFFFFF) )) {$IFDEF DEBUG }or $80000000{$ENDIF DEBUG };
  end
  else
    f_ssrc := f_ssrcParent;
  //
  f_portL := '<none>';
  //
  if (nil <> in_socket) then begin
    //
    in_socket.bindToIP := bind2ip;
    //
    if (isMulticast) then begin
      //
      if ('' <> bind2port) and (0 <> str2intInt(bind2port, 0)) then
	in_socket.bindToPort := bind2port;
      //
      f_socketError := unaMulticastSocket(in_socket).mjoin(f_ip, c_unaMC_receive or choice(nil <> f_transmitter, c_unaMC_send, int(0)) );	// will also bind socket to port
    end
    else begin
      //
      if (isUDP) then begin
	//
	if (('' = bind2port) or (0 = str2intInt(bind2port, 0))) then
	  f_socketError := in_socket.bindSocketToPort()           	// bind to first available port
	else
	  f_socketError := in_socket.bindSocketToPort(str2intInt(bind2port, 14000));
      end
      else begin
	//
	if (isServer) then
	  in_socket.setPort(bind2port);
	//
	f_socketError := 0
      end;
    end;
    //
    if (0 = socketError) then begin
      //
      //f_socket.setOptInt(SO_RCVBUF, 32000);	// increase the size of input buffer
      //
      if (isUDP) then
	in_socket.getSockAddrBound(addr)
      else
	in_socket.getSockAddr(addr);
      //
      f_portL := int2str(swap16u(addr.sin_port));
      if (nil <> rtcp) then begin
	//
	// assigns RTCP port as well
	if (('0' <> f_portL) and (isUDP or isServer)) then begin
	  //
	  if (f_isMC) then
	    rtcp.bind2port := int2str(int(f_mcport) + 1)
	  else
	    rtcp.bind2port := int2str(uint32(swap16u(addr.sin_port) + 1));
        end;
	//
	rtcp.start();
	//
	rtcp.f_readyEv.waitFor(1000);	// wait for RTCP to get healthy
      end;
      //
    {$IFDEF UNA_SOCKSRTP_LOG_RTP }
      logMessage('RTP socket started on ' + bind2ip + ':' + f_portL);
    {$ENDIF UNA_SOCKSRTP_LOG_RTP }
      //
      f_active := true;
    end;
  end
  else
    f_socketError := 0;
end;

// --  --
procedure unaRTPReceiver.startOut();
begin
  inherited;
  //
  if (nil <> in_socket) then begin
    //
    if (isMulticast) then
      unaMulticastSocket(in_socket).mleave();
    //
    in_socket.close();
  end;
  //
  if (nil <> rtcp) then
    rtcp.stop();
  //
  f_active := false;
end;

// --  --
procedure unaRTPReceiver.weSent(addr: PSockAddrIn; data: pointer; len: uint);
begin
  if (nil <> rtcp) then
    rtcp.weSentRTP(addr, data, len - sizeof(rtp_hdr));
end;


{ unaRTPDestination }

// --  --
procedure unaRTPDestination.BeforeDestruction();
begin
  close();
  //
  freeAndNil(f_msocket);
  freeAndNil(f_bsocket);
  //
  inherited;
end;

// --  --
procedure unaRTPDestination.close();
begin
  case (scope) of

    0: ; // unicast uses receiver's socket

    1: if (nil <> f_bsocket) then
      f_bsocket.close();

    2: begin
      //
      if (nil <> f_msocket) then begin
	//
	f_msocket.mleave();
	f_msocket.close();
      end;
    end;

  end;
  //
  f_isOpen := false;
end;

// --  --
constructor unaRTPDestination.create(dstatic: bool; trans: unaRTPTransmitter; const ipN: TIPv4N);
begin
  f_trans := trans;
  f_dstatic := dstatic;
  f_socketOwned := true;
  //
  f_destAddrRTP.sin_addr.S_addr := u_long(ipN);
  //
  setupSocket();
  //
  inherited create();
  //
  f_lastRRTM := timeMarkU();	// assume last RR report about this dest was receivied right now
end;

// --  --
constructor unaRTPDestination.create(dstatic: bool; trans: unaRTPTransmitter; addrRTP, addrRTCP: PSockAddrIn; doOpen: bool; ttl: int; recSSRC: uint32);
begin
  f_trans := trans;
  self.ttl := ttl;
  f_recSSRC := recSSRC;
  f_socketOwned := false;
  //
  f_destAddrRTP := addrRTP^;
  if (nil <> addrRTCP) then
    f_destAddrRTCP := addrRTCP^
  else begin
    //
    f_destAddrRTCP := addrRTP^;
    f_destAddrRTCP.sin_port := htons(ntohs(f_destAddrRTCP.sin_port) + 1);
  end;
  //
  f_dstatic := dstatic;
  //
  setupSocket();
  //
  inherited create();
  //
  if (doOpen) then
    open()
  else
    f_lastRRTM := timeMarkU();	// assume last RR report about this dest was receivied right now
end;

// --  --
constructor unaRTPDestination.create(dstatic: bool; trans: unaRTPTransmitter; const destHost, destPortRTP, destPortRTCP: string; doOpen: bool; ttl: int; recSSRC: uint32);
begin
  f_trans := trans;
  self.ttl := ttl;
  //
  f_dstatic := dstatic;
  f_recSSRC := recSSRC;
  f_socketOwned := false;
  //
  makeAddr(destHost, destPortRTP, destPortRTCP);
  //
  setupSocket();
  //
  inherited create();
  //
  if (doOpen) then
    open()
  else
    f_lastRRTM := timeMarkU();	// assume last RR report about this dest was receivied right now
end;

// --  --
function unaRTPDestination.getAddrRTCP(): PSockAddrIn;
begin
  result := @f_destAddrRTCP;
end;

// --  --
function unaRTPDestination.getAddrRTP(): PSockAddrIn;
begin
  result := @f_destAddrRTP;
end;

// --  --
function unaRTPDestination.makeAddr(const destHost, destPortRTP, destPortRTCP: string): bool;
begin
  result := unaSockets.makeAddr(destHost, destPortRTP, f_destAddrRTP);
  if (result) then
    result := unaSockets.makeAddr(destHost, destPortRTCP, f_destAddrRTCP);
end;

// --  --
procedure unaRTPDestination.open();
begin
  f_lastRRTM := timeMarkU();	// assume last RR report about this dest was receivied right now
  //
  case (scope) of

    0: begin
      //
      // will use receiver socket
      f_isOpen := true;
    end;

    1: begin
      //
      if (not f_socketOwned) then begin
	//
	if (nil <> f_trans.receiver) then
	  f_bsocket.bindToIP := f_trans.receiver.bind2ip
	else
	  f_bsocket.bindToIP := f_trans.bind2ip;
	//
	f_bsocket.bindToPort := f_trans.bind2port;
	if (0 = f_bsocket.bindSocketToPort()) then begin
	  //
	  f_bsocket.setOptBool(SO_BROADCAST, true);
	  //
	  f_isOpen := true;
	end
	else
	  f_isOpen := false;
      end
      else
	f_isOpen := (nil <> f_trans.receiver);
    end;

    2: begin
      //
      if (not f_socketOwned) then begin
	//
	if (nil <> f_trans.receiver) then
	  f_msocket.bindToIP := f_trans.receiver.bind2ip
	else
	  f_msocket.bindToIP := f_trans.bind2ip;
	//
	f_msocket.bindToPort := f_trans.bind2port;
	f_msocket.setPort(swap16u(f_destAddrRTP.sin_port));
	//
	f_isOpen := (0 = f_msocket.mjoin(f_mgroup, c_unaMC_receive or c_unaMC_send, ttl));
      end
      else
	f_isOpen := (nil <> f_trans.receiver);
    end;

  end;
end;

// --  --
function unaRTPDestination.sameAddr(isRTP: bool; const addr: sockaddr_in; checkIPOnly: bool): bool;
begin
  if (isRTP) then
    result := unaSockets.sameAddr(f_destAddrRTP,  addr, checkIPOnly)
  else
    result := unaSockets.sameAddr(f_destAddrRTCP, addr, checkIPOnly);
end;

// --  --
procedure unaRTPDestination.setTTL(value: int);
begin
  f_ttl := value;
  //
  if (nil <> f_msocket) then
    f_msocket.ttl := f_ttl;
end;

// --  --
procedure unaRTPDestination.setupSocket();
var
  ipN: TIPv4N;
begin
  ipN := TIPv4N(f_destAddrRTP.sin_addr.S_addr);
  //
  if isMulticastAddrN(ipN) then
    f_scope := 2
  else
    if isBroadcastAddrN(ipN) then
      f_scope := 1
    else
      f_scope := 0;
  //
  case (scope) of

    0: begin  // unicast
      //
      // will use receiver socket
    end;

    1: begin  // broadcast
      //
      if (not f_socketOwned) then
	f_bsocket := unaUDPSocket.create({$IFDEF VC25_OVERLAPPED }false{$ENDIF VC25_OVERLAPPED });	//
    end;

    2: begin  // multicast
      //
      if (not f_socketOwned) then begin
        //
	f_msocket := unaMulticastSocket.create({$IFDEF VC25_OVERLAPPED }false{$ENDIF VC25_OVERLAPPED });	//
	f_mgroup := ipN2str(ipN);
      end;
    end;

  end;
  //
  f_enabled := true;
  f_closeOnBye := false;	// seem to be right
end;

// --  --
function unaRTPDestination.transmit(data: pointer; len: uint; isRTCP: bool; tcpLenAlreadyPrefixed: bool): int;
var
  addr: sockaddr_in;
  rs: unaSocket;
begin
  if (isOpen) then begin
    //
    if (enabled) then begin
      //
      if (isRTCP) then
	addr := f_destAddrRTCP
      else
	addr := f_destAddrRTP;
      //
      if (isRTCP and (nil <> f_trans.rtcp)) then
	result := f_trans.rtcp.sendDataRTCP(@addr, data, len)
      else begin
	//
      {$IFDEF UNA_SOCKSRTP_LOG_SOCKDATA }
	logMessage('RTP: destination, about to send ' + int2str(len) + ' bytes to ' + addr2str(@addr));
      {$ENDIF UNA_SOCKSRTP_LOG_SOCKDATA }
	//
	if (nil <> f_trans.receiver) and (nil <> f_trans.receiver.in_socket) then
	  rs := f_trans.receiver.in_socket
	else
	  rs := nil;
	//
	case (scope) of

	  1: begin
	    //
	    if (nil <> f_bsocket) then
	      result := f_bsocket.sendto(addr, data, len, 0, 10, false)	        // broadcast
	    else begin
	      //
	      if (f_socketOwned and (nil <> rs) and (rs is unaUDPSocket)) then
		result := unaUDPSocket(rs).sendto(addr, data, len, 0, 10, false)	        // broadcast
	      else
		result := WSAENOTSOCK;
	    end;
	  end;

	  2: begin
	    //
	    if (nil <> f_msocket) then
	      result := f_msocket.sendData(data, len)				// multicast
	    else begin
	      //
	      if (f_socketOwned and (nil <> rs) and (rs is unaMulticastSocket)) then
		result := unaMulticastSocket(rs).sendData(data, len)				// multicast
	      else
		result := WSAENOTSOCK;
	    end;
	  end;

	  else begin                                                          	// unicast
	    //
	    if (nil <> rs) then begin
	      //
	      if (f_trans.receiver.isUDP) then
		result := unaUDPSocket(rs).sendto(addr, data, len, 0, 10, false)
	      else
		result := f_trans.receiver.sendTCPData_To(@addr, data, len, tcpLenAlreadyPrefixed);
	    end
	    else
	      result := WSAENOTSOCK;
	  end;
	end
      end;
      //
      if ((0 = result) and (nil <> f_trans) and (nil <> f_trans.f_receiver)) then
	f_trans.f_receiver.onDataSent(isRTCP, data, len);
    end
    else
      result := 0;
  end
  else
    result := WSAENOTSOCK;
end;


{ unaRTPTransmitter }

// --  --
procedure unaRTPTransmitter.BeforeDestruction();
begin
  close();
  //
  freeAndNil(f_destinations);
  freeAndNil(f_receiver);
  //
  mrealloc(f_sendBuf);
  f_sendBufSize := 0;
  //
  inherited;
end;

// --  --
procedure unaRTPTransmitter.checkDestTimeouts(SSRC: uint32; rr: prtcp_rr_block; rrCount: int; rtcpAddr: PSockAddrIn);
var
  i, j: int32;
  dest: unaRTPDestination;
  _si: rtp_site_info;
  rrSave: prtcp_rr_block;
  hasRR: bool;
  ok: bool;
{$IFDEF UNA_SOCKSRTP_LOG_RTP_EX }
  rrSSRC, rrAddr: string;
{$ENDIF UNA_SOCKSRTP_LOG_RTP_EX }
begin
  hasRR := (nil <> rr) and (0 < rrCount) and (nil <> rtcpAddr);	// got any RR block(s)?
  if (hasRR or (6000 < timeElapsed64U(f_lastDestTOCheckTM))) then begin
    //
  {$IFDEF UNA_SOCKSRTP_LOG_RTP_EX }
    logMessage(className + '.checkDestTimeouts() - hasRR=' + bool2strStr(hasRR) + ', destCount=' + int2str(f_destinations.count) + '; last check: ' + int2str(timeElapsed64U(f_lastDestTOCheckTM)) + 'ms ago.');
  {$ENDIF UNA_SOCKSRTP_LOG_RTP_EX }
    //
    f_lastDestTOCheckTM := timeMarkU();
    //
    {*
	In case of no RTCP or RTCP timeout disabled, exit now.
    }
    if (nil = rtcp) then
      exit
    else begin
      //
      {*
	  In case of conference, we assume server will timeout via standard RTCP means, so checking destinations is not neccessary.
      }
      if ((1 > rtcp.memberTimeoutReports) or rtcp.conferenceMode) then
	exit;
    end;
    //
    if (lockNonEmptyList_r(f_destinations, true, 20 {$IFDEF DEBUG }, '.checkDestTimeouts()'{$ENDIF DEBUG })) then try
      //
      rrSave := rr;
      for i := 0 to f_destinations.count - 1 do begin
	//
	rr := rrSave;
	dest := f_destinations[i];
	if ((0 < rrCount) and not dest.dstatic) then begin
	  //
	  for j := 0 to rrCount - 1 do begin
	    //
	  {$IFDEF UNA_SOCKSRTP_LOG_RTP_EX }
	    //
	    if (hasRR) then begin
	      //
	      rrSSRC := int2str(swap32u(rr.r_ssrc_NO));
	      rrAddr := addr2str(rtcpAddr);
	    end
	    else begin
	      //
	      rrAddr := '?';
	      rrSSRC := '?';
	    end;
	    //
	    logMessage(className + '.checkDestTimeouts() - dest[' + int2str(i) + '], sameAddr[' + int2str(j) + ']?   Got:' + rrAddr + ' <> Exp:' + addr2str(@dest.f_destAddrRTCP) + '  and same SSRC: ' + int2str(dest.f_trans._SSRC) + '<>' + rrSSRC + ' or (' + int2str(dest.recSSRC) + '=' + int2str(SSRC) + ')');
	    //
	  {$ENDIF UNA_SOCKSRTP_LOG_RTP_EX }
	    //
	    if (0 <> dest.recSSRC) then
	      ok := (dest.recSSRC = SSRC)
	    else
	      ok := hasRR and (dest.f_trans._SSRC = swap32u(rr.r_ssrc_NO)) and (sameAddr(rtcpAddr^, dest.f_destAddrRTCP));
	    //
	    if (ok) then begin
	      //
	    {$IFDEF UNA_SOCKSRTP_LOG_RTP_EX }
	      logMessage(className + '.checkDestTimeouts() - same!');
	    {$ENDIF UNA_SOCKSRTP_LOG_RTP_EX }
	      //
	      dest.f_lastRRTM := timeMarkU();
	      break;
	    end;
	    //
	    inc(rr);
	  end;
	end;
      end;
    finally
      unlockListRO(f_destinations);
    end;
    //
    if (lockNonEmptyList_r(f_destinations, false, 20 {$IFDEF DEBUG }, '.checkDestTimeouts()'{$ENDIF DEBUG })) then try
      //
      // see if we have some destinations still abandoned
      i := 0;
      while (i < f_destinations.count) do begin
	//
	dest := f_destinations[i];
	if (not dest.dstatic) then begin
	  //
	{$IFDEF UNA_SOCKSRTP_LOG_RTP_EX }
	  logMessage(className + '.checkDestTimeouts() - dest[' + int2str(i) + '] lastRR: ' + int2str(timeElapsed64U(dest.f_lastRRTM)) + 'ms ago.');
	{$ENDIF UNA_SOCKSRTP_LOG_RTP_EX }
	  //
	  // no one reports of our data for 25 seconds?
	  if (25000 < timeElapsed64U(dest.f_lastRRTM)) then begin
	    //
	    fillChar(_si, sizeof(_si), #0);
	    _si.r_remoteAddrRTCPValid := true;
	    _si.r_remoteAddrRTCP := dest.f_destAddrRTCP;
	    _si.r_remoteAddrRTPValid := true;
	    _si.r_remoteAddrRTP := dest.f_destAddrRTP;
	    //
	  {$IFDEF UNA_SOCKSRTP_LOG_RTP_EX }
	    logMessage(className + '.checkDestTimeouts() - dest[' + int2str(i) + '] is ' + choice(dest.dstatic, 'static, will be closed.', 'dynamic, will be removed!'));
	  {$ENDIF UNA_SOCKSRTP_LOG_RTP_EX }
	    //
	    if (dest.dstatic and dest.isOpen) then
	      dest.close()
	    else begin
	      //
	      f_destinations.removeItem(dest);
	      dec(i);
	    end;
	    //
	    notifyBye(@_si, true);
	  end;
	end
	else
	  ; // static destinations should not timeout
	//
	inc(i);
      end;
      //
    finally
      unlockListWO(f_destinations);
    end;
  end;
end;

// --  --
procedure unaRTPTransmitter.close(clearAllDest: bool);
begin
  if (active) then
    doClose();
  //
  if (clearAllDest and (nil <> f_destinations)) then
    f_destinations.clear();
end;

// --  --
constructor unaRTPTransmitter.create(const bind2addr: TSockAddrIn; payload: int; isRAW: bool; noRTCP: bool; ttl: int; primaryDest: PSockAddrIn; isUDP: bool; role: c_peer_role);
var
  ipH: TIPv4H;
  b2portInt: int;
begin
  self.isRaw := isRaw;
  self.ttl := ttl;
  //
  rtpPing := true;
  //
  self.payload := payload;
  //
  inherited create();
  //
  f_destinations := unaObjectList.create();
  //
  if (nil <> primaryDest) then begin
    //
    ipH := ipN2ipH(primaryDest);
    //
    // looks like we have a destination specified, assume that is RAW/RTP dest address
    // add it as static destination
    if (isMulticastAddrH(ipH)) then
      // multicast should be handled by receiver socket, dest will not
      destAdd(true, ipH2ipN(ipH))
    else begin
      //
      b2portInt := portHFromAddr(primaryDest);
      destAdd(true, ipH2str(ipH), int2str(b2portInt), int2str(b2portInt + 1), false, ttl);
    end;
  end;
  //
  f_bind2port := int2str(portHFromAddr(@bind2addr));
  if ('9' = f_bind2port) then
    f_bind2port := '0';	// use any port
  //
  f_bind2ip := ipH2str(ipN2ipH(@bind2addr));
  //
  f_receiver := unaRTPReceiver.create(bind2addr, primaryDest, noRTCP, self, ttl, isUDP, isRAW, role);
  f_receiver.CN_resendInterval := 0;	// no need for CN packets in transmitter
end;

// --  --
function unaRTPTransmitter.destAdd(dstatic: bool; const remoteHost, remotePortRTP, remotePortRTCP: string; doOpen: bool; ttl: int; recSSRC: uint32; fromHole: bool): int;
var
  addrRTP, addrRTCP: sockaddr_in;
begin
  makeAddr(remoteHost, remotePortRTP, addrRTP);
  makeAddr(remoteHost, remotePortRTCP, addrRTCP);
  result := destAdd(dstatic, @addrRTP, @addrRTCP, doOpen, fromHole, recSSRC);
end;

// --  --
function unaRTPTransmitter.destAdd(dstatic: bool; addrRTP, addrRTCP: PSockAddrIn; doOpen: bool; fromHole: bool; recSSRC: uint32): int;
begin
  result := -1;
  if ((nil <> addrRTP) and not destHas(addrRTP^)) then begin
    //
    if (okAddDest(addrRTP, addrRTCP, fromHole)) then begin
      //
      result := f_destinations.add(unaRTPDestination.create(dstatic, self, addrRTP, addrRTCP, doOpen, ttl, recSSRC));
      //
    {$IFDEF UNA_SOCKSRTP_LOG_RTP }
      logMessage(className + '.destAdd() - new ' + choice(dstatic, 'static', 'dynamic') + ' destination [' + addr2str(addrRTP) + ']/' + int2str(ttl));
    {$ENDIF UNA_SOCKSRTP_LOG_RTP }
    end;
  end
  else begin
    //
  {$IFDEF UNA_SOCKSRTP_LOG_RTP }
    logMessage(className + '.destAdd() - address already in destinations [' + addr2str(addrRTP) + ']');
  {$ENDIF UNA_SOCKSRTP_LOG_RTP }
  end;
end;

// --  --
function unaRTPTransmitter.destAdd(dstatic: bool; const ipN: TIPv4N): int;
begin
  result := f_destinations.add(unaRTPDestination.create(dstatic, self, ipN));
  //
{$IFDEF UNA_SOCKSRTP_LOG_RTP }
  logMessage(className + '.destAdd() - new "rec" ' + choice(dstatic, 'static', 'dynamic') + ' address [' + ipN2str(ipN) + ']');
{$ENDIF UNA_SOCKSRTP_LOG_RTP }
end;

// --  --
function unaRTPTransmitter.destAdd(dstatic: bool; const uri: string; doOpen: bool; ttl: int; recSSRC: uint32): int;
var
  crack: unaURICrack;
begin
  if (crackURI(uri, crack)) then
    result := destAdd(dstatic, crack.r_hostName, int2str(crack.r_port), int2str(word(crack.r_port + 1)), doOpen, ttl, recSSRC)
  else
    result := -1;
end;

// --  --
procedure unaRTPTransmitter.destEnable(const uri: string; doEnable: bool);
var
  dest: unaRTPDestination;
  crack: unaURICrack;
  addr: sockaddr_in;
begin
  crackURI(uri, crack);
  makeAddr(crack.r_hostName, int2str(crack.r_port), addr);
  //
  dest := destGetAcq(addr, true);
  if (nil <> dest) then try
    //
    if (doEnable and not dest.isOpen) then
      dest.open();
    //
    dest.enabled := doEnable;
  finally
    dest.releaseRO();
  end;
end;

// --  --
procedure unaRTPTransmitter.destEnable(index: int; doEnable: bool);
var
  dest: unaRTPDestination;
begin
  dest := destGetAcq(index, true);
  if (nil <> dest) then try
    //
    if (doEnable and not dest.isOpen) then
      dest.open();
    //
    dest.enabled := doEnable;
  finally
    dest.releaseRO();
  end;
end;

// --  --
function unaRTPTransmitter.destGetAcq(index: int; ro: bool): unaRTPDestination;
begin
  if (nil <> f_destinations) then
    result := f_destinations.get(index)
  else
    result := nil;
  //
  if ((nil <> result) and not result.acquire(ro, 60{$IFDEF DEBUG}, false, className + '.destGetAcq()'{$ENDIF DEBUG })) then
    result := nil;
end;

// --  --
function unaRTPTransmitter.destGetAcq(const addrRTP: sockaddr_in; ro: bool): unaRTPDestination;
var
  i: int32;
begin
  result := nil;
  if (lockNonEmptyList_r(f_destinations, true, 998 {$IFDEF DEBUG }, '.close()'{$ENDIF DEBUG })) then try
    //
    for i := 0 to destGetCount() - 1 do begin
      //
      result := f_destinations[i];
      if ((nil <> result) and result.sameAddr(true, addrRTP)) then begin
	//
	if (not result.acquire(ro, 999)) then
	  result := nil;
	//
	break;
      end
      else
	result := nil;
    end;
  finally
    unlockListRO(f_destinations);
  end;
end;

// --  --
function unaRTPTransmitter.destGetCount(): int;
begin
  if (nil <> f_destinations) then
    result := f_destinations.count
  else
    result := 0;
end;

// --  --
function unaRTPTransmitter.destHas(const addr: sockaddr_in): bool;
var
  dest: unaRTPDestination;
begin
  result := false;
  dest := destGetAcq(addr, true);
  if (nil <> dest) then try
    result := true;
  finally
    dest.releaseRO();
  end;
end;

// --  --
procedure unaRTPTransmitter.destRemove(const uri: string);
var
  crack: unaURICrack;
  addr: sockaddr_in;
begin
  if (crackURI(uri, crack)) then begin
    //
    if (makeAddr(crack.r_hostName, int2str(crack.r_port), addr)) then
      destRemove(addr);
  end;
end;

// --  --
procedure unaRTPTransmitter.destRemove(const addrRTP: sockaddr_in);
var
  dest: unaRTPDestination;
begin
  dest := destGetAcq(addrRTP, true);
  if (nil <> dest) then begin
    //
    dest.releaseRO();
    destRemove(dest);
  end;
end;

// --  --
procedure unaRTPTransmitter.destRemove(dest: unaRTPDestination);
begin
  f_destinations.removeItem(dest);
end;

// --  --
procedure unaRTPTransmitter.destRemove(index: int);
begin
  f_destinations.removeByIndex(index);
end;

// --  --
procedure unaRTPTransmitter.doClose();
var
  i: int32;
  dest: unaRTPDestination;
begin
  receiver.askStop();
  //
  if (lockNonEmptyList_r(f_destinations, true, 998 {$IFDEF DEBUG }, '.close()'{$ENDIF DEBUG })) then try
    //
    for i := 0 to destGetCount() - 1 do begin
      //
      dest := destGetAcq(i, true);
      if (nil <> dest) then try
	dest.close();
      finally
	dest.releaseRO();
      end;
    end;
  finally
    unlockListRO(f_destinations);
  end;
  //
  receiver.stop();
  //
  inherited;
  //
  mrealloc(f_sendBuf);
  f_sendBufSize := 0;
end;

// --  --
function unaRTPTransmitter.doOpen(waitForThreadsToStart: bool): bool;
var
  i: int32;
begin
  randomize();
  //
  f_timestamp := random($70000000);
  f_rtpPingTM := 0;     // restart timer
  //
  if (lockNonEmptyList_r(f_destinations, true, 1000 {$IFDEF DEBUG }, '.doOpen()'{$ENDIF DEBUG })) then try
    //
    for i := 0 to destGetCount() - 1 do
      unaRTPDestination(f_destinations[i]).open();
  finally
    unlockListRO(f_destinations);
  end;
  //
  //receiver.bind2port := bind2port;
  //receiver.bind2ip := bind2ip;
  //
  result := receiver.start();
  if (waitForThreadsToStart and (nil <> rtcp)) then
    rtcp.waitForExecute();
  //
  if (0 <> receiver.socketError) then
    f_socketError := receiver.socketError;
  //
  f_lastDestTOCheckTM := timeMarkU();
end;

// --  --
function unaRTPTransmitter.getActive(): bool;
begin
  if (nil <> receiver) then
    result := receiver.active
  else
    result := false;
end;

// --  --
function unaRTPTransmitter.getDest(index: int): unaRTPDestination;
begin
  result := f_destinations[index];
end;

// --  --
function unaRTPTransmitter.getNextSeq(): unsigned;
begin
  if (nil = self) then
    result := 0
  else begin
    {$IFOPT R+ }
      {$DEFINE 5240629F_4CD4_47C0_A82C_F0F765B34960 }
    {$ENDIF R+ }
    {$R-} // otherwise it will fail on f_seq = $7FFFFFFF;
    result := InterlockedIncrement(f_seq) and $FFFF;
    {$IFDEF 5240629F_4CD4_47C0_A82C_F0F765B34960 }
      {$R+ }
    {$ENDIF 5240629F_4CD4_47C0_A82C_F0F765B34960 }
  end;
end;

// --  --
function unaRTPTransmitter.getRTCP(): unaRTCPstack;
begin
  if (nil <> receiver) then
    result := receiver.rtcp
  else
    result := nil;
end;

// --  --
function unaRTPTransmitter.getSsrc(): u_int32;
begin
  if (nil <> receiver) then
    result := receiver._ssrc
  else
    result := 0;
end;

// --  --
procedure unaRTPTransmitter.notifyBye(si: prtp_site_info; soft: bool);
var
  i: int;
  dest: unaRTPDestination;
  ok: bool;
begin
  if ((nil <> rtcp) and not rtcp.conferenceMode) then begin
    //
    if (lockNonEmptyList_r(f_destinations, false, 100 {$IFDEF DEBUG }, '.notifyBye()'{$ENDIF DEBUG })) then try
      //
      i := 0;
      while (i < destGetCount()) do begin
	//
	dest := destGetAcq(i, false);
	if (nil <> dest) then try
	  //
	  ok := (dest.sameAddr(false, si.r_remoteAddrRTCP));
	  if (ok) then begin
	    //
	    if (dest.dstatic) then begin
	      //
	      if (dest.closeOnBye) then
	      	dest.close();
	    end
	    else begin
	      //
	      f_destinations.removeItem(dest);
	      dest := nil;
	      dec(i);
	    end;
	  end;
	finally
	  dest.releaseWO();
	end;
	//
	inc(i);
      end;
      //
    finally
      unlockListWO(f_destinations);
    end;
  end;
end;

// --  --
function unaRTPTransmitter.okAddDest(destRTP, destRTCP: PSockAddrIn; fromHole: bool): bool;
var
  b: boolean;
begin
  if (assigned(f_onAddDest)) then begin
    //
    b := true;
    f_onAddDest(self, fromHole, destRTP, destRTCP, b);
    result := b;
  end
  else
    result := true;	// that is how it worked before
end;

// --  --
procedure unaRTPTransmitter.onIdle(rtcpIdle: bool);
begin
  // check timeouts
  checkDestTimeouts(0);
end;

// --  --
procedure unaRTPTransmitter.onPayload(addr: PSockAddrIn; hdr: prtp_hdr; data: pointer; len, packetSize: uint);
var
{$IFDEF UNA_SOCKSRTP_LOG_RTP }
  res: int;
{$ENDIF UNA_SOCKSRTP_LOG_RTP }
  si: prtp_site_info;
  addrRTCP: PSockAddrIn;
begin
  case (hdr.r_M_PT and $7F) of

    c_rtpPTa_CN: begin
      //
      // someone making a hole here.. lets add it to dynamic destinations
      addrRTCP := nil;
      if (nil <> rtcp) then begin
	//
	si := rtcp.memberBySSRCAcq(swap32u(hdr.r_ssrc_NO), true);
	if (nil <> si) then try
	  //
	  if (si.r_remoteAddrRTCPValid) then
	    addrRTCP := @si.r_remoteAddrRTCP;
	finally
	  rtcp.memberReleaseRO(si);
	end;
      end;
      //
      {$IFDEF UNA_SOCKSRTP_LOG_RTP }res := {$ENDIF UNA_SOCKSRTP_LOG_RTP }destAdd(false, addr, addrRTCP, true, true, swap32u(hdr.r_ssrc_NO));
      //
    {$IFDEF UNA_SOCKSRTP_LOG_RTP }
      logMessage(className + '.onPayload() - RTP address by hole: [' + int2str(swap32u(hdr.r_ssrc_NO)) + '@' + addr2str(addr) + '], index=' + int2str(res));
    {$ENDIF UNA_SOCKSRTP_LOG_RTP }
    end;

  end;
  //
  if (f_isTranslator) then
    retransmit(hdr, packetSize, false);	// translator should not update we_sent
end;

// --  --
procedure unaRTPTransmitter.onRTCPPacket(ssrc: u_int32; addr: PSockAddrIn; hdr: prtcp_common_hdr; packetSize: uint);
var
  rr: prtcp_rr_block;
  app: prtcp_APP_packet;
  //
  si: prtp_site_info;
  len, count: uint;
  okPing, timePassed: bool;
begin
  repeat
    //
    len := rtpLength2bytes(hdr.r_length_NO_);
    //
    case (hdr.r_pt) of

      //
      RTCP_SR: begin
	//
	rr := prtcp_rr_block(@prtcp_SR_packet(hdr).r_rr);
	count := (len - sizeof(rtcp_SR_packet)) div sizeof(rtcp_rr_block);
	//
	checkDestTimeouts(ssrc, rr, count, addr);
      end;

      //
      RTCP_RR: begin
	//
	rr := prtcp_rr_block(@prtcp_RR_packet(hdr).r_rr);
	count := (len - sizeof(rtcp_RR_packet)) div sizeof(rtcp_rr_block);
	//
	checkDestTimeouts(ssrc, rr, count, addr);
      end;

      // got APP?
      RTCP_APP: begin
	//
	if (packetSize >= sizeof(rtcp_APP_packet)) then begin
	  //
	  app := prtcp_APP_packet(hdr);
	  if (c_rtcp_appCmd_hello = app.r_cmd) then begin
	    //
	    // hm.. seems like we should do something here, but I dont know what exactly atm ^^
	  end
	  else begin
	    //
	    if (c_rtcp_appCmd_needRTPPing = app.r_cmd) then begin
	      //
	      if (nil <> rtcp) then begin
		//
		si := rtcp.memberBySSRCAcq(ssrc, true);
		if (nil <> si) then try
		  //
		  if (si.r_remoteAddrRTPValid) then begin
		    //
		  {$IFDEF UNA_SOCKSRTP_LOG_RTP_EX }
		    logMessage(' ** will send RTP ping to [' + int2str(ssrc) + '] due to NPNG request from remote side ** ');
		  {$ENDIF UNA_SOCKSRTP_LOG_RTP_EX }
		    //
		    // remote side needs a ping from us, let do it now
		    if (nil <> receiver) then
		      receiver.sendRTP_CN_To(@si.r_remoteAddrRTP);
		  end
		  else begin
		    //
		  {$IFDEF UNA_SOCKSRTP_LOG_RTP }
		    logMessage(' ** will NOT send RTP ping (due to NPNG request from remote side) to [' + int2str(ssrc) + '], remote RTP addr is unknown ** ');
		  {$ENDIF UNA_SOCKSRTP_LOG_RTP }
		  end;
		  //
		finally
		  rtcp.memberReleaseRO(si);
		end
		else begin
		  //
		  {$IFDEF UNA_SOCKSRTP_LOG_RTP }
		    logMessage(' ** will NOT send RTP ping (due to NPNG request from remote side) to [' + int2str(ssrc) + '], siteinfo is blocked or missing ** ');
		  {$ENDIF UNA_SOCKSRTP_LOG_RTP }
		end;
	      end;
	      //
	    end;
	  end;
	end;
	//
      end;

    end;	// case
    //
    dec(packetSize, len);
    if (0 < packetSize) then
      hdr := prtcp_common_hdr(@pArray(hdr)[len])
    else
      break;
    //
  until (sizeof(rtcp_common_hdr) > packetSize);
  //
  if ( rtpPing and (0 <> ssrc) and (nil <> rtcp) and (nil <> receiver) and (1 > rtcp.f_we_sent) ) then begin
    //
    okPing := (not rtcp.conferenceMode) or (0 = rtcp.f_members.indexOfId(ssrc));	// in conference mode only ping server
    //
    if (okPing and (0 = f_rtpPingTM)) then
      f_rtpPingTM := timeMarkU();
    //
    timePassed := (5000 < timeElapsed64U(f_rtpPingTM));
    si := nil;
    //
    {*
	Silent client will not be included in RR reports from conference server.
	So SSRC may never be from server (index = 0, see check above).
	But RTP "ping" still need to be send for two reasons:
	  1) keep "RTP hole" open
	  2) server will include us in RR -> our timeout check will be happy
    }
    if (timePassed and not okPing and rtcp.conferenceMode) then begin
      //
      // 0 is conf. server index
      si := rtcp.memberByIndexAcq(0, true);
      okPing := (nil <> si);
    end;
    //
    if (okPing and timePassed) then begin
      //
      if (nil = si) then
	si := rtcp.memberBySSRCAcq(ssrc, true);
      //
      if (nil <> si) then try
	//
	if (si.r_remoteAddrRTPValid) then begin
	  //
	{$IFDEF UNA_SOCKSRTP_LOG_RTP_EX }
	  logMessage(' ** will send RTP ping to [' + int2str(ssrc) + '] due to timer ** ');
	{$ENDIF UNA_SOCKSRTP_LOG_RTP_EX }
	  //
	  receiver.sendRTP_CN_To(@si.r_remoteAddrRTP);
	  //
	  f_rtpPingTM := timeMarkU();
	end
	else begin
	{$IFDEF UNA_SOCKSRTP_LOG_RTP }
	  logMessage(' ** will NOT send RTP ping to [' + int2str(ssrc) + '] - remote RTP address is unknown ** ');
	{$ENDIF UNA_SOCKSRTP_LOG_RTP }
	end;
	//
      finally
	rtcp.memberReleaseRO(si);
      end;
    end;
  end;
  //
  if (rtpPing and (nil <> rtcp) and (1 <= rtcp.f_we_sent)) then
    f_rtpPingTM := timeMarkU();
end;

// --  --
procedure unaRTPTransmitter.onSsrcCNAME(ssrc: u_int32; cname: prtcp_sdes_item);
begin
  //
end;

// --  --
function unaRTPTransmitter.open(waitForThreadsToStart: bool): bool;
begin
  if (not active) then
    doOpen(waitForThreadsToStart);
  //
  result := active;
end;

// --  --
procedure unaRTPTransmitter.onRTCPPacketSent(packet: pointer; len: uint);
begin
  retransmit(packet, len, false, true);
end;

// --  --
function unaRTPTransmitter.retransmit(data: pointer; len: uint; updateWeSent: bool; isRTCP: bool; tcpLenAlreadyPrefixed: bool): int;
var
  i: int32;
  dest: unaRTPDestination;
  res: int;
  si: prtp_site_info;
begin
  result := 0;
  //
  // send data to all destinations
  if (not paused and (nil <> data) and (0 < len) and lockNonEmptyList_r(f_destinations, true, 40 {$IFDEF DEBUG }, '.retransmit()'{$ENDIF DEBUG })) then try
    //
    for i := 0 to destGetCount() - 1 do begin
      //
      dest := destGetAcq(i, true);
      if (nil <> dest) then try
	//
	res := -1;
	if (isRTCP and (nil <> rtcp)) then begin
	  //
	  si := rtcp.memberByAddrAcq(false, @dest.f_destAddrRTCP, true);
	  if (nil <> si) then try
	    res := 0;   // RTCP already sent via RTCP stack member
	  finally
	    rtcp.memberReleaseRO(si);
	  end;
	end;
	//
	if (0 <> res) then
	  res := dest.transmit(data, len, isRTCP, tcpLenAlreadyPrefixed);	// no SI member for this dest, send manually
	//
	if (0 = res) then begin
	  //
	  inc(result, len);
	  if (updateWeSent) then
	    receiver.weSent(@dest.f_destAddrRTP, data, len);
	end;
	//
	if (0 <> res) then
	  f_socketError := res;
      finally
	dest.releaseRO();
      end;
    end;
    //
  finally
    unlockListRO(f_destinations);
  end;
end;

// --  --
function unaRTPTransmitter.send_To(addr: PSockAddrIn; data: pointer; len: uint; isRTCP: bool; ownPacket, tcpLenAlreadyPrefixed: bool): int;
begin
  result := 0;
  //
  if (paused) then
    exit;
  //
  if ((nil <> addr) and (nil <> receiver)) then begin
    //
  {$IFDEF UNA_SOCKSRTP_LOG_SOCKDATA }
    logMessage('RTP: transmitter, about to send ' + int2str(len) + choice(isRTCP, 'RTCP', 'RTP') + ' bytes to ' + addr2str(addr));
  {$ENDIF UNA_SOCKSRTP_LOG_SOCKDATA }
    //
    if (isRTCP) then begin
      //
      if (nil <> receiver.rtcp) then
	result := receiver.rtcp.sendDataRTCP(addr, data, len)
      else
	result := WSAENOTSOCK;
    end
    else begin
      //
      if (nil <> receiver.in_socket) then begin
	//
	if (receiver.isUDP) then
	  result := unaUDPSocket(receiver.in_socket).sendto(addr^, data, len, 0, 10, false)
	else
	  result := receiver.sendTCPData_To(addr, data, len, tcpLenAlreadyPrefixed);
      end
      else
	result := WSAENOTSOCK;
      //
      if (0 = result) then
	f_receiver.onDataSent(false, data, len);
    end;
  end
  else
    result := WSAENOTSOCK;
  //
  if ((0 = result) and not isRTCP and ownPacket and (nil <> receiver)) then
    receiver.weSent(addr, data, len);	// NOTE: remote member will not be added into member table since its source addr:port is not known here
  //
  if (0 <> result) then
    f_socketError := result;
end;

// --  --
procedure unaRTPTransmitter.setActive(value: bool);
begin
  if (active <> value) then begin
    //
    if value then
      open()
    else
      close();
  end;
end;

// --  --
procedure unaRTPTransmitter.setNewSSRC(newssrc: u_int32);
begin
  if (nil <> receiver) then
    receiver.setNewSSRC(newssrc);
end;

// --  --
procedure unaRTPTransmitter.setPayload(value: int);
begin
  f_payload := value;
  //
  case (f_payload) of

    c_rtpPTa_MPA: begin
      //
      RTPclockRate := 90000;
      f_sr := 44100;
    end;

    c_rtpPTa_L16_stereo,
    c_rtpPTa_L16_mono: begin
      //
      RTPclockRate := 44100;
      f_sr := 44100;
    end

    else begin
      //
      RTPclockRate := 8000;
      f_sr := 8000;
    end;

  end;
end;

// --  --
function unaRTPTransmitter.transmit(samplesDelta: uint; data: pointer; len: uint; marker: bool; tpayload: int; addr: PSockAddrIn; prebufData: pointer; prebufDataLen: uint; updateWeSent: bool): int;
var
  lv: int64;
  szHdr: unsigned;
  pt: int;
  dataSize, packetSize: uint;
  isUDP: bool;
begin
  result := 0;
  //
  // create new packet and send it to all destinations
  if (not paused and active) then begin
    //
    if (isRAW) then
      result := retransmit(data, len, false, false)
    else begin
      //
      // -- RTP --
      //
      if (nil <> receiver) then
	isUDP := receiver.isUDP
      else
	isUDP := true;
      //
      if (0 <= tpayload) then
	pt := tpayload
      else
	pt := payload;
      //
      szHdr := sizeof(rtp_hdr) + choice(isUDP, 0, uint(2));
      //
      f_hdr.r_V_P_X_CC := (RTP_VERSION shl 6) and $C0;	// no padding, no extension, no CSRC
      f_hdr.r_M_PT := choice(marker, $80, int(0)) or (pt and $7F);
      if (nil <> rtcp) then
	f_hdr.r_seq_NO := swap16u(rtcp.getNextSeq())
      else
	f_hdr.r_seq_NO := swap16u(getNextSeq());
      //
      lv := int64(samplesDelta * RTPclockRate) div f_sr + f_timestamp;
      f_timestamp := lv and $FFFFFFFF;
      f_hdr.r_timestamp_NO := swap32u(f_timestamp);
      //
      f_hdr.r_ssrc_NO := swap32u(_ssrc);
      //
      if (nil = data) then
	len := 0;
      //
      if (nil = prebufData) then
	prebufDataLen := 0;
      //
      if ((0 < len) or (0 < prebufDataLen)) then
	dataSize := len + szHdr + prebufDataLen
      else
	dataSize := int(szHdr);
      //
      if (f_sendBufSize < dataSize) then begin
	//
	f_sendBufSize := dataSize;
	mrealloc(f_sendBuf, f_sendBufSize);
      end;
      //
      if ((0 < len) or (0 < prebufDataLen)) then begin
	//
	// put pre-buffer data in place
	if (0 < prebufDataLen) then
	  move(prebufData^, pArray(f_sendBuf)[szHdr], prebufDataLen);
	//
	// put payload in place
	if (0 < len) then
	  move(data^, pArray(f_sendBuf)[szHdr + unsigned(prebufDataLen)], len);
      end;
      //
    {$IFDEF UNA_SOCKSRTP_LOG_SOCKDATA }
      logMessage('RTP: about to transmit() ' + int2str(len) + ' bytes to ' + addr2str(addr));
    {$ENDIF UNA_SOCKSRTP_LOG_SOCKDATA }
      //
      // put header in place
      if (isUDP) then
	move(f_hdr, f_sendBuf^, szHdr)
      else begin
	//
	move(f_hdr, pArray(f_sendBuf)[2], szHdr - 2);
	packetSize := swap16u(dataSize - 2);
	move(packetSize, f_sendBuf^, 2);
      end;
      //
      if (nil = addr) then
	result := retransmit(f_sendBuf, dataSize, updateWeSent)
      else
	result := send_To(addr, f_sendBuf, dataSize, false, updateWeSent);
    end;
  end;
end;


initialization


finalization
  //
  g_ntpDone := true;
  freeAndNil(g_ntp);
end.

