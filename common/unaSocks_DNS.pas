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
	  unaSocks_DNS.pas
	  Basic DNS client -- queries (and responses)
	----------------------------------------------
	  Copyright (c) 2011-2012 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 15 Dec 2011

	  modified by:
		Lake, Jan 2012

	----------------------------------------------
*)

{$I unaDef.inc }

{*
  DNS [RFC 1035]

  @Author Lake

  Version 2.5.2011.12 First release
}

unit
  unaSocks_DNS;

interface

uses
  unaTypes, unaClasses, unaSockets;

const
  // query/response types
  //
  // RFC 1035
  c_DNS_TYPE_A          = 1;    // a host address
  c_DNS_TYPE_NS         = 2;    // an authoritative name server
  c_DNS_TYPE_MD         = 3;    // a mail destination (Obsolete - use MX)
  c_DNS_TYPE_MF         = 4;    // a mail forwarder (Obsolete - use MX)
  c_DNS_TYPE_CNAME      = 5;    // the canonical name for an alias
  c_DNS_TYPE_SOA        = 6;    // marks the start of a zone of authority
  c_DNS_TYPE_MB         = 7;    // a mailbox domain name (EXPERIMENTAL)
  c_DNS_TYPE_MG         = 8;    // a mail group member (EXPERIMENTAL)
  c_DNS_TYPE_MR         = 9;    // a mail rename domain name (EXPERIMENTAL)
  c_DNS_TYPE_NULL       = 10;   // a null RR (EXPERIMENTAL)
  c_DNS_TYPE_WKS        = 11;   // a well known service description
  c_DNS_TYPE_PTR        = 12;   // a domain name pointer
  c_DNS_TYPE_HINFO      = 13;   // host information
  c_DNS_TYPE_MINFO      = 14;   // mailbox or mail list information
  c_DNS_TYPE_MX         = 15;   // mail exchange
  c_DNS_TYPE_TXT        = 16;   // text strings
  //
  // RFC 1183
  c_DNS_TYPE_RP         = 17;   // Responsible Person
  c_DNS_TYPE_AFSDB      = 18;   // AFS
  c_DNS_TYPE_X25        = 19;   // x25
  c_DNS_TYPE_ISDN       = 20;   // ISDN
  c_DNS_TYPE_RT         = 21;   // Route Through
  //
  // RFC 1706
  c_DNS_TYPE_NSAP       = 22;   // Network Service Access Protocol
  //
  // RFC 2931/2535
  c_DNS_TYPE_SIG        = 24;   // signature
  //
  // RFC 2535
  c_DNS_TYPE_KEY        = 25;   // key
  //
  // RFC 2163
  c_DNS_TYPE_PX         = 26;   // pointer to X.400/RFC822 mapping information
  //
  // RFC 3596
  c_DNS_TYPE_AAAA       = 28;   // IPv6 address
  //
  // RFC 1876
  c_DNS_TYPE_LOC        = 29;   // geo location
  //
  // RFC 2535
  c_DNS_TYPE_NXT        = 30;   // next
  //
  // RFC 2782
  c_DNS_TYPE_SRV        = 33;   // SRV
  //
  // RFC 3403, 3404
  c_DNS_TYPE_NAPTR      = 35;   // Naming Authority Pointer
  //
  // RFC 2230
  c_DNS_TYPE_KX         = 36;   // Key Exchange Delegation Record
  //
  // RFC 4398
  c_DNS_TYPE_CERT       = 37;   // Certificates
  //
  // RFC 2672
  c_DNS_TYPE_DNAME      = 39;   // Non-Terminal DNS Name Redirection
  //
  // RFC 3123
  c_DNS_TYPE_APL        = 42;   // Address Prefixes
  //
  // RFC 4034
  c_DNS_TYPE_DS         = 43;   // DS
  c_DNS_TYPE_IPSECKEY   = 45;   // IPsec Keying Material, RFC 4025
  c_DNS_TYPE_RRSIG      = 46;   // RRSIG
  c_DNS_TYPE_NSEC       = 47;   // NSEC
  c_DNS_TYPE_DNSKEY     = 48;   // DNSKEY
  //
  // RFC 4701
  c_DNS_TYPE_DHCID      = 49;   // Dynamic Host Configuration Protocol Information
  //
  // RFC 5155
  c_DNS_TYPE_NSEC3      = 50;   // NSEC3
  c_DNS_TYPE_NSEC3PARAM = 51;   // NSEC3 parameters
  //
  // RFC 5205
  c_DNS_TYPE_HIP        = 55;   // Host Identity Protocol
  //
  // RFC 2930
  c_DNS_TYPE_TKEY       = 249;  // Secret Key Establishment
  //
  // RFC 2845
  c_DNS_TYPE_TSIG       = 250;  // Secret Key Transaction Authentication

  // query only
  c_DNS_TYPE_AXFR       = 252; // A request for a transfer of an entire zone
  c_DNS_TYPE_MAILB      = 253; // A request for mailbox-related records (MB, MG or MR)
  c_DNS_TYPE_MAILA      = 254; // A request for mail agent RRs (Obsolete - see MX)
  c_DNS_TYPE_ANY        = 255; // A request for all records
  //
  // RFC ????
  c_DNS_TYPE_TA         = 32768;
  //
  // RFC 4431
  c_DNS_TYPE_DLV        = 32769; // DNSSEC Lookaside Validation

  // classes
  c_DNS_CLASS_IN        = 1;    // the Internet
  c_DNS_CLASS_CS        = 2;    // CSNET class (Obsolete - used only for examples in some obsolete RFCs)
  c_DNS_CLASS_CH        = 3;    // CHAOS class
  c_DNS_CLASS_HS        = 4;    // Hesiod [Dyer 87]
  //
  c_DNS_CLASS_ANY       = 255;  // any class

  // header bitfields
  //
  c_DNS_HDR_ISRESPONSE_MASK     = 1 shl 15;   // whether this message is a response
  //
  c_DNS_HDR_OPCODE_QUERY        = 0;   // a standard query
  c_DNS_HDR_OPCODE_IQUERY       = 1;   // an inverse query
  c_DNS_HDR_OPCODE_STATUS       = 0;   // a server status request
  //
  c_DNS_HDR_MASK_AA             = 1 shl 10;     // Authoritative Answer
  c_DNS_HDR_MASK_TC             = 1 shl 9;      // TrunCation
  c_DNS_HDR_MASK_RD             = 1 shl 8;      // Recursion Desired
  c_DNS_HDR_MASK_RA             = 1 shl 7;      // Recursion Available
  //
  c_DNS_HDR_RCODE_NO_ERROR              = 0;    // No error condition
  c_DNS_HDR_RCODE_FORMAT_ERROR          = 1;    // Format error
  c_DNS_HDR_RCODE_SERVER_FAILURE        = 2;    // Server failure
  c_DNS_HDR_RCODE_NAME_ERROR            = 3;    // Name Error
  c_DNS_HDR_RCODE_NOT_IMPLEMENTED       = 4;    // Not Implemented
  c_DNS_HDR_RCODE_REFUSED               = 5;    // Refused

type
  //
  punaDNS_HDR = ^unaDNS_HDR;
  unaDNS_HDR = packed record
    r_ID: uint16;
    r_QR_OPCODE_AATCRD_RA_Z_RCODE: uint16;
    r_QDCOUNT,
    r_ANCOUNT,
    r_NSCOUNT,
    r_ARCOUNT: uint16;
  end;

  // forward
  unaDNSRR = class;

  {*
	General RR section
  }
  unaDNSRR_subType = class(unaObject)
  private
    f_parser: unaDNSRR;
  protected
    procedure parse(data: pArray; maxOfs, ofs: int); virtual; abstract;
  public
    constructor create(parser: unaDNSRR; data: pArray; maxOfs, ofs: int);
  end;

  {*
	A RR
  }
  unaDNSRR_A = class(unaDNSRR_subType)
  private
    f_ip: TIPv4H;
  protected
    procedure parse(data: pArray; maxOfs, ofs: int); override;
  public
    property ipH: TIPv4H read f_ip;
  end;

  {*
	AAAA RR
  }
  unaDNSRR_AAAA = class(unaDNSRR_subType)
  private
    f_ip: TIPv6H;
    //
    function getIP(): pIPv6H;
  protected
    procedure parse(data: pArray; maxOfs, ofs: int); override;
  public
    property ipH: pIPv6H read getIP;
  end;

  {*
	CNAME RR
  }
  unaDNSRR_CNAME = class(unaDNSRR_subType)
  private
    f_cname: string;
  protected
    procedure parse(data: pArray; maxOfs, ofs: int); override;
  public
    property cname: string read f_cname;
  end;

  {*
        MX RR
  }
  unaDNSRR_MX = class(unaDNSRR_subType)
  private
    f_pref: int;
    f_exchange: string;
  protected
    procedure parse(data: pArray; maxOfs, ofs: int); override;
  public
    property preference: int read f_pref;
    property exchange: string read f_exchange;
  end;

  {*
        TXT RR
  }
  unaDNSRR_TXT = class(unaDNSRR_subType)
  private
    f_text: string;
  protected
    procedure parse(data: pArray; maxOfs, ofs: int); override;
  public
    property text: string read f_text;
  end;

  {*
        NS RR
  }
  unaDNSRR_NS = class(unaDNSRR_subType)
  private
    f_ns: string;
  protected
    procedure parse(data: pArray; maxOfs, ofs: int); override;
  public
    property ns: string read f_ns;
  end;

  {*
        RP RR
  }
  unaDNSRR_RP = class(unaDNSRR_subType)
  private
    f_mbox: string;
    f_dname: string;
  protected
    procedure parse(data: pArray; maxOfs, ofs: int); override;
  public
    property mbox: string read f_mbox;
    property dname: string read f_dname;
  end;

  {*
	PTR RR
  }
  unaDNSRR_PTR = class(unaDNSRR_subType)
  private
    f_domain: string;
  protected
    procedure parse(data: pArray; maxOfs, ofs: int); override;
  public
    property domain: string read f_domain;
  end;

  {*
	SRV RR
  }
  unaDNSRR_SRV = class(unaDNSRR_subType)
  private
    f_priority: uint;
    f_weight: uint;
    f_port: uint;
    f_target: string;
  protected
    procedure parse(data: pArray; maxOfs, ofs: int); override;
  public
    property priority: uint read f_priority;
    property weight: uint read f_weight;
    property port: uint read f_port;
    property target: string read f_target;
  end;

  {*
	SOA RR
  }
  unaDNSRR_SOA = class(unaDNSRR_subType)
  private
    f_mname, f_rname: string;
    f_serial, f_refresh, f_retry, f_expire, f_min: uint32;
  protected
    procedure parse(data: pArray; maxOfs, ofs: int); override;
  public
    property mname: string read f_mname;
    property rname: string read f_rname;
    //
    property serial     : uint32 read f_serial;
    property refresh    : uint32 read f_refresh;
    property retry      : uint32 read f_retry;
    property expire     : uint32 read f_expire;
    property min        : uint32 read f_min;
  end;

  {*
        NAPTR RR
  }
  unaDNSRR_NAPTR = class(unaDNSRR_subType)
  private
    f_order, f_pref: uint;
    f_flags, f_services, f_regexp, f_replace: string;
  protected
    procedure parse(data: pArray; maxOfs, ofs: int); override;
  public
    property order: uint read f_order;
    property pref: uint read f_pref;
    property flags: string read f_flags;
    property services: string read f_services;
    property regexp: string read f_regexp;
    property replace: string read f_replace;
  end;

  {*
        RRSIG RR
  }
  unaDNSRR_RRSIG = class(unaDNSRR_subType)
  private
    f_typeCovered, f_algo, f_labels, f_originalTTL,
    f_signatureExpiration, f_signatureInception, f_keyTag: uint;
    f_signer: string;
    f_signature: aString;
  protected
    procedure parse(data: pArray; maxOfs, ofs: int); override;
  public
    property typeCovered: uint read f_typeCovered;
    property algo: uint read f_algo;
    property labels: uint read f_labels;
    property originalTTL: uint read f_originalTTL;
    property signatureExpiration: uint read f_signatureExpiration;
    property signatureInception: uint read f_signatureInception;
    property keyTag: uint read f_keyTag;
    property signer: string read f_signer;
    property signature: aString read f_signature;
  end;

  {*
	DNSKEY RR
  }
  unaDNSRR_DNSKEY = class(unaDNSRR_subType)
  private
    f_zoneKF, f_SEP: bool;
    f_proto: uint;
    f_algo: uint;
    f_pubKey: aString;
  protected
    procedure parse(data: pArray; maxOfs, ofs: int); override;
  public
    property algo: uint read f_algo;
    property proto: uint read f_proto;	// must be 3
    property pubKey: aString read f_pubKey;
    //
    property zoneKF: bool read f_zoneKF;
    property SEP: bool read f_SEP;
  end;

  {*
	NSEC RR
  }
  unaDNSRR_NSEC = class(unaDNSRR_subType)
  private
    f_nextDomain: string;
    f_bitmap: aString;
  protected
    procedure parse(data: pArray; maxOfs, ofs: int); override;
  public
    property nextDomain: string read f_nextDomain;
    property bitmap: aString read f_bitmap;
  end;

  {*
	NSEC3PARAM RR
  }
  unaDNSRR_NSEC3PARAM = class(unaDNSRR_subType)
  private
    f_algo: uint;
    f_flags: uint;
    f_iterations: uint;
    f_salt: aString;
  protected
    procedure parse(data: pArray; maxOfs, ofs: int); override;
  public
    property algo: uint read f_algo;
    property flags: uint read f_flags;
    property iterations: uint read f_iterations;
    property salt: aString read f_salt;
  end;


  {*
	DNS RR parser
  }
  unaDNSRR = class(unaObject)
  private
    f_name: string;
    f_type: int;
    f_class: int;
    f_ttl: uint32;
    f_rdlen: int;
    f_rdata: pointer;
    f_isQuestion: bool;
    //
    f_rdataObj: unaDNSRR_subType;
    //
    function expandLabel(data: pArray; maxLen: int; var ofs: int; noLoop: bool = false): string;
    function readInt16(data: pArray; var ofs: int): int16;
    function readUInt16(data: pArray; var ofs: int): uint16;
    function readUInt32(data: pArray; var ofs: int): uint32;
    function readBlock(data: pArray; var ofs: int; len: int): aString;
    //
    procedure parse(data: pArray; var ofs: int; maxLen: int; isQuestion: bool);
  public
    constructor create(data: pointer; var ofs: int; maxLen: int; isQuestion: bool);
    {*
        Releases resources
    }
    destructor Destroy(); override;
    //
    {*
        True if this RR is original question
    }
    property isQuestion: bool read f_isQuestion;
    {*
        RR name
    }
    property rname: string read f_name;
    {*
        RR type
    }
    property rtype: int read f_type;
    {*
        RR class
    }
    property rclass: int read f_class;
    {*
        RR TTL (valid only if isQuestion is false)
    }
    property rttl: uint32 read f_ttl;
    {*
	RDATA length (valid only if isQuestion is false)
    }
    property rdlen: int read f_rdlen;
    {*
	RDATA (valid only if isQuestion is false)
    }
    property rdata: pointer read f_rdata;
    {*
	Parsed RDATA (valid only if isQuestion is false).
	Actual class depends on rtype property.
	For example, if rtype = c_DNS_TYPE_MX, subData will be unaDNSRR_MX
	This property could be nil, in which case you have to parse RDATA manually
    }
    property rdataObj: unaDNSRR_subType read f_rdataObj;
  end;


  {*
	RFC 5966 now requires DNS servers to handle requests over TCP
  }
  unaDNS_transport = (
// UDP only, do not try TCP
    unaDnsTR_UDP,               
// TCP only, do not try UDP
    unaDnsTR_TCP,               
// try UDP first, if truncated, empty or unavailable, try TCP (default)
    unaDnsTR_UDP_then_TCP,      
// try TCP first, if unavailable, try UDP
    unaDnsTR_TCP_then_UDP       
  );


  {*
        DNS Query/Response
  }
  unaDNSQuery = class(unaObject)
  private
    f_id: int;
    f_dnsServers: unaStringList;
    f_resources: unaStringList;
    f_qtype, f_opCode, f_qClass: int;
    f_recurse: bool;
    //
    f_QD, f_AN, f_NS, f_AR: unaObjectList;
    //
    f_req, f_resp: punaDNS_HDR;
    f_reqSize, f_respSize: int;
    f_prepared: bool;
    //
    f_timeout: uint64;
    f_transport: unaDNS_transport;
    f_queryWasTCP: bool;
    f_issuedCount: int;
    //
    f_status: int;
    //
    f_buf: pArray;
    f_bufSize: int;
    //
    f_sockU: unaUDPSocket;
    f_sockT: unaTCPSocket;
    //
    f_respCode: int;
    //
    {*
	Saves resources as lables in buf

	@return number of bytes taken for all labels
    }
    function doLabels(const resource: string; buf: pArray): int;
    {*
	Allocates new request

	@return 0 if OK
    }
    function prepareReq(): int;
    {*
	@return RR by index/rindex
    }
    function getRR(rindex: int; index: integer): unaDNSRR;
  protected
    {*
	Parse response, size of valid data in buffer is already set in respSize

	@return 0 if parsed all data successfully
	@return -1 if parsed data is malformed and cannot be parsed
	@return -2 if data is incolmplete (TCP only)
	@return -3 if data cannot be accepted and retry is possible
    }
    function parse(transport: unaDNS_transport): int;
    {*
	Sends request to next server from the list and assigns a timeout mark
    }
    function issue(transport: unaDNS_transport): bool;
    {*
	Read response (if any), sets respSize if read was successfull

	@param timeout read timeout
	@param buf data buffer to fill
	@param bufSize size of buffer

	@return True if socket has read something
    }
    function readFrom(timeout: int): bool;
    {*
	Prepares for next issue().
    }
    procedure reset(doneWithServer: bool);
    //
    property timeout: uint64 read f_timeout;
  public
    {*
	Do not create this object directly, use unaDNSClient instead
    }
    constructor create(id: int; const dnsServers, resources: string; qtype: int; opCode, qClass: int; recurse: bool; transport: unaDNS_transport);
    {*
	Releases query resources
    }
    destructor Destroy(); override;
    {*
	Query id. This is same id returned by unaDNSClient.query() method
    }
    property id: int read f_id;
    property dnsServers: unaStringList read f_dnsServers;
    property resources: unaStringList read f_resources;
    property qtype: int read f_qtype;
    property opCode: int read f_opCode;
    property qClass: int read f_qClass;
    //
    property req: punaDNS_HDR read f_req;
    property resp: punaDNS_HDR read f_resp;
    property respSize: int read f_respSize;
// c_DNS_HDR_RCODE_XXX
    property respCode: int read f_respCode;     
    //
    property QD[rindex: int]: unaDNSRR index 0 read getRR;
    property AN[rindex: int]: unaDNSRR index 1 read getRR;
    property NS[rindex: int]: unaDNSRR index 2 read getRR;
    property AR[rindex: int]: unaDNSRR index 3 read getRR;
    //
    {*
	 >0     = status equals some socket error
	 0   	= OK
	-1 	= no respose/timeout
	-2 	= malformed response
	-3	= internal error

    }
    property status: int read f_status;
  end;


  {*
	DNS Client
  }
  unaDNSClient = class(unaThread)
  private
    f_id: int;
    f_queries: unaObjectList;
    f_dnsServers: string;
    f_transport: unaDNS_transport;
    f_idleTM: uint64;
  protected
    {*
	//
    }
    function execute(threadID: unsigned): int; override;
    {*
	Override to receive answers.

	@param query
    }
    procedure onAnswer(query: unaDNSQuery); virtual;
    {*
	@return query id
    }
    function push(query: unaDNSQuery): int;
    {*
	@return query id
    }
    procedure pop(query: unaDNSQuery; onError: bool);
  public
    {*
	Creates DNS client with default servers list (by default it is empty, in which case it will be filled by calling getDNSServersList() method)
    }
    constructor Create(const dnsServers: string = ''; transport: unaDNS_transport = unaDnsTR_UDP_then_TCP);
    {*
	Releases (hopefully) all resources.
    }
    destructor Destroy(); override;
    {*
	@return query ID, which should be tracked in onAnswer() method
    }
    function query(const dnsServers, resources: string; qtype: int = c_DNS_TYPE_A; opCode: int = c_DNS_HDR_OPCODE_QUERY; qClass: int = c_DNS_CLASS_IN; recurse: bool = true): int; overload;
    {*
	Uses DNS servers specified in constructor.

	@return query ID, which should be tracked in onAnswer() method
    }
    function query(const resources: string; qtype: int = c_DNS_TYPE_A; opCode: int = c_DNS_HDR_OPCODE_QUERY; qClass: int = c_DNS_CLASS_IN; recurse: bool = true): int; overload;
    {*
	@return List of configured DNS servers, separated by #13#10
    }
    class function getDNSServersList(): string;
    //
    {*
	DNS server list, specified in constructor. Could be empty.
    }
    property dnsServers: string read f_dnsServers;
    {*
	Transport to use.
    }
    property transport: unaDNS_transport read f_transport write f_transport;
  end;


var
  v_DNS_timeout: int    = 12000;        // wait 15 seconds for response from server
  v_DNS_port: int       = 53;           // default port


implementation


uses
  Windows, unaUtils, unaIPHelperAPI, WinSock,
  unaRE;


  { unaDNSRR_subType }

// --  --
constructor unaDNSRR_subType.create(parser: unaDNSRR; data: pArray; maxOfs, ofs: int);
begin
  inherited create();
  //
  f_parser := parser;
  //
  parse(data, maxOfs, ofs);
end;

  { unaDNSRR_A }

// --  --
procedure unaDNSRR_A.parse(data: pArray; maxOfs, ofs: int);
begin
  if (maxOfs - ofs >= 4)  then
    f_ip := f_parser.readUInt32(data, ofs);
end;

  { unaDNSRR_AAAA }

// --  --
function unaDNSRR_AAAA.getIP(): pIPv6H;
begin
  result := @f_ip;
end;

// --  --
procedure unaDNSRR_AAAA.parse(data: pArray; maxOfs, ofs: int);
begin
  if (maxOfs - ofs >= sizeof(TIPv6H))  then
    move(data[ofs], f_ip, sizeof(TIPv6H));
end;

  { unaDNSRR_CNAME }

// --  --
procedure unaDNSRR_CNAME.parse(data: pArray; maxOfs, ofs: int);
begin
  f_cname := f_parser.expandLabel(data, maxOfs, ofs);
end;

  { unaDNSRR_MX }

// --  --
procedure unaDNSRR_MX.parse(data: pArray; maxOfs, ofs: int);
begin
  if (maxOfs - ofs >= 2) then begin
    //
    f_pref := f_parser.readInt16(data, ofs);
    f_exchange := f_parser.expandLabel(data, maxOfs, ofs);
  end;
end;

  { unaDNSRR_TXT }

// --  --
procedure unaDNSRR_TXT.parse(data: pArray; maxOfs, ofs: int);
begin
  f_text := f_parser.expandLabel(data, maxOfs, ofs, true);
end;

  { unaDNSRR_NS }

// --  --
procedure unaDNSRR_NS.parse(data: pArray; maxOfs, ofs: int);
begin
  f_ns := f_parser.expandLabel(data, maxOfs, ofs);
end;

  { unaDNSRR_RP }

// --  --
procedure unaDNSRR_RP.parse(data: pArray; maxOfs, ofs: int);
begin
  f_mbox := f_parser.expandLabel(data, maxOfs, ofs);
  f_dname := f_parser.expandLabel(data, maxOfs, ofs);
end;

  { unaDNSRR_PTR }

// --  --
procedure unaDNSRR_PTR.parse(data: pArray; maxOfs, ofs: int);
begin
  f_domain := f_parser.expandLabel(data, maxOfs, ofs);
end;

  { unaDNSRR_SRV }

// --  --
procedure unaDNSRR_SRV.parse(data: pArray; maxOfs, ofs: int);
begin
  if (maxOfs - ofs >= 6) then begin
    //
    f_priority := f_parser.readUInt16(data, ofs);
    f_weight   := f_parser.readUInt16(data, ofs);
    f_port     := f_parser.readUInt16(data, ofs);
  end;
  //
  f_target := f_parser.expandLabel(data, maxOfs, ofs);
end;

  { unaDNSRR_SOA }

// --  --
procedure unaDNSRR_SOA.parse(data: pArray; maxOfs, ofs: int);
begin
  f_mname   := f_parser.expandLabel(data, maxOfs - 21, ofs);
  f_rname   := f_parser.expandLabel(data, maxOfs - 20, ofs);
  if (maxOfs - ofs >= 20) then begin
    //
    f_serial  := f_parser.readUInt32(data, ofs);
    f_refresh := f_parser.readUInt32(data, ofs);
    f_retry   := f_parser.readUInt32(data, ofs);
    f_expire  := f_parser.readUInt32(data, ofs);
    f_min     := f_parser.readUInt32(data, ofs);
  end;
end;

  { unaDNSRR_NAPTR }

// --  --
procedure unaDNSRR_NAPTR.parse(data: pArray; maxOfs, ofs: int);
begin
  if (maxOfs - ofs >= 4) then begin
    //
    f_order := f_parser.readUInt16(data, ofs);
    f_pref  := f_parser.readUInt16(data, ofs);
  end;
  //
  f_flags    := f_parser.expandLabel(data, maxOfs, ofs, true);
  f_services := f_parser.expandLabel(data, maxOfs, ofs, true);
  f_regexp   := f_parser.expandLabel(data, maxOfs, ofs, true);
  f_replace  := f_parser.expandLabel(data, maxOfs, ofs);
end;

  { unaDNSRR_RRSIG }

// --  --
procedure unaDNSRR_RRSIG.parse(data: pArray; maxOfs, ofs: int);
begin
  if (maxOfs - ofs >= 18) then begin
    //
    f_typeCovered := f_parser.readUInt16(data, ofs);
    f_algo        := data[ofs]; inc(ofs);
    f_labels      := data[ofs]; inc(ofs);
    f_originalTTL := f_parser.readUInt32(data, ofs);
    f_signatureExpiration := f_parser.readUInt32(data, ofs);
    f_signatureInception := f_parser.readUInt32(data, ofs);
    f_keyTag := f_parser.readUInt16(data, ofs);
  end;
  //
  f_signer := f_parser.expandLabel(data, maxOfs, ofs, true);
  f_signature := f_parser.readBlock(data, ofs, maxOfs - ofs);
end;

  { unaDNSRR_DNSKEY }

// --  --
procedure unaDNSRR_DNSKEY.parse(data: pArray; maxOfs, ofs: int);
var
  w32: uint32;
begin
  if (maxOfs - ofs >= 4) then begin
    //
    w32 := swap32u(f_parser.readUInt32(data, ofs));
    f_algo := w32 shr 24;
    f_proto := (w32 shr 16) and $FF;
    f_zoneKF := (0 <> (w32 and (1 shl 8)));
    f_SEP := (0 <> (w32 and 1));
  end;
  //
  f_pubKey := f_parser.readBlock(data, ofs, maxOfs - ofs);
end;

  { unaDNSRR_NSEC }

// --  --
procedure unaDNSRR_NSEC.parse(data: pArray; maxOfs, ofs: int);
begin
  f_nextDomain := f_parser.expandLabel(data, maxOfs, ofs, false);
  f_bitmap := f_parser.readBlock(data, ofs, maxOfs - ofs);
end;

  { unaDNSRR_NSEC3PARAM }

// --  --
procedure unaDNSRR_NSEC3PARAM.parse(data: pArray; maxOfs, ofs: int);
var
  len: int;
begin
  if (maxOfs - ofs > 4) then begin
    //
    f_algo    := data[ofs + 0];
    f_flags   := data[ofs + 1];
    inc(ofs, 2);
    f_iterations := f_parser.readUInt16(data, ofs);
    //
    len := min(maxOfs - ofs, data[ofs]);
    inc(ofs);
    //
    if (0 < len) then begin
      //
      setLength(f_salt, len);
      move(data[ofs], f_salt[1], len);
    end
    else
      f_salt := '-';	// from RFC 5155: This field is represented as "-" (without the quotes) when the Salt Length field is zero.
  end;
end;


  { unaDNSRR }

// --  --
constructor unaDNSRR.create(data: pointer; var ofs: int; maxLen: int; isQuestion: bool);
begin
  inherited create();
  //
  parse(data, ofs, maxLen, isQuestion);
end;

// --  --
destructor unaDNSRR.Destroy();
begin
  inherited;
  //
  freeAndNil(f_rdataObj);
end;

// --  --
function unaDNSRR.expandLabel(data: pArray; maxLen: int; var ofs: int; noLoop: bool): string;
var
  sz: unsigned;
  ofs2: int;
  bufA: array[0..511] of aChar;
begin
  result := '';
  //
  while (ofs < maxLen) do begin
    //
    sz := (data[ofs]);
    if ($C0 <= sz) then begin
      //
      // ptr
      sz := (data[ofs] shl 8) + data[ofs + 1];
      ofs2 := sz and $3FFF;
      //
      if ('' <> result) then
        result := result + '.';
      //
      if (ofs2 < maxLen) then
        result := result + expandLabel(data, maxLen, ofs2);
      //
      inc(ofs, 2);
      //
      break;    // no data is allowed after pointer
    end
    else begin
      //
      inc(ofs);
      if (0 < sz) then begin
	//
	if (ofs + int(sz) <= maxLen) then begin
	  //
	  if ('' <> result) then
	    result := result + '.';
	  //
	  move(data[ofs], bufA[0], sz);
	  bufA[sz] := #0;
	  //
	  result := result + string(bufA);
	  inc(ofs, sz);
	end
	else
	  break;        // wrong lable length or <root>/EOS
      end
      else begin
	//
	if ('' = result) then
	  result := '.';
	//
	break;  // EOS
      end;
    end;
    //
    if (noLoop) then
      break;
  end;
end;

// --  --
procedure unaDNSRR.parse(data: pArray; var ofs: int; maxLen: int; isQuestion: bool);
begin
  if (ofs < maxLen) then begin
    //
    f_name := expandLabel(data, maxLen - 4, ofs);
    f_isQuestion := isQuestion;
    //
    f_type := readUInt16(data, ofs);
    f_class := readUInt16(data, ofs);
    //
    if (not isQuestion and (ofs < maxLen)) then begin
      //
      f_ttl := readUInt32(data, ofs);
      //
      f_rdlen := min(readUInt16(data, ofs), maxLen - ofs);
      f_rdata := @data[ofs];
      //
      case (f_type) of

	c_DNS_TYPE_A    : f_rdataObj := unaDNSRR_A.create    (self, data, ofs + f_rdlen, ofs);
	c_DNS_TYPE_AAAA : f_rdataObj := unaDNSRR_AAAA.create (self, data, ofs + f_rdlen, ofs);
	c_DNS_TYPE_CNAME: f_rdataObj := unaDNSRR_CNAME.create(self, data, ofs + f_rdlen, ofs);
	c_DNS_TYPE_MX   : f_rdataObj := unaDNSRR_MX.create   (self, data, ofs + f_rdlen, ofs);
	c_DNS_TYPE_TXT  : f_rdataObj := unaDNSRR_TXT.create  (self, data, ofs + f_rdlen, ofs);
	c_DNS_TYPE_RP   : f_rdataObj := unaDNSRR_RP.create   (self, data, ofs + f_rdlen, ofs);
	c_DNS_TYPE_NS   : f_rdataObj := unaDNSRR_NS.create   (self, data, ofs + f_rdlen, ofs);
	c_DNS_TYPE_PTR  : f_rdataObj := unaDNSRR_PTR.create  (self, data, ofs + f_rdlen, ofs);
	c_DNS_TYPE_SRV  : f_rdataObj := unaDNSRR_SRV.create  (self, data, ofs + f_rdlen, ofs);
	c_DNS_TYPE_SOA  : f_rdataObj := unaDNSRR_SOA.create  (self, data, ofs + f_rdlen, ofs);
	c_DNS_TYPE_NAPTR: f_rdataObj := unaDNSRR_NAPTR.create(self, data, ofs + f_rdlen, ofs);
	//
	c_DNS_TYPE_RRSIG : f_rdataObj := unaDNSRR_RRSIG.create (self, data, ofs + f_rdlen, ofs);
	c_DNS_TYPE_DNSKEY: f_rdataObj := unaDNSRR_DNSKEY.create(self, data, ofs + f_rdlen, ofs);
	c_DNS_TYPE_NSEC  : f_rdataObj := unaDNSRR_NSEC.create  (self, data, ofs + f_rdlen, ofs);
	c_DNS_TYPE_NSEC3PARAM: f_rdataObj := unaDNSRR_NSEC3PARAM.create(self, data, ofs + f_rdlen, ofs);

      end;
      //
      inc(ofs, rdlen);
    end;
  end;
end;

// --  --
function unaDNSRR.readBlock(data: pArray; var ofs: int; len: int): aString;
begin
  if (0 < len) then begin
    //
    setLength(result, len);
    move(data[ofs], result[1], len);
    inc(ofs, len);
  end
  else
    result := '';
end;

// --  --
function unaDNSRR.readInt16(data: pArray; var ofs: int): int16;
begin
  move(data[ofs], result, 2);
  inc(ofs, 2);
  //
  result := swap16i(result);
end;

// --  --
function unaDNSRR.readUInt16(data: pArray; var ofs: int): uint16;
begin
  move(data[ofs], result, 2);
  inc(ofs, 2);
  //
  result := swap16u(result);
end;

// --  --
function unaDNSRR.readUInt32(data: pArray; var ofs: int): uint32;
begin
  move(data[ofs], result, 4);
  inc(ofs, 4);
  //
  result := swap32u(result);
end;


  { unaDNSQuery }

// --  --
constructor unaDNSQuery.create(id: int; const dnsServers, resources: string; qtype, opCode, qClass: int; recurse: bool; transport: unaDNS_transport);
begin
  f_dnsServers := unaStringList.create();
  f_dnsServers.text := dnsServers;
  //
  f_resources := unaStringList.create();
  f_resources.text := resources;
  //
  f_transport := transport;
  //
  f_qtype := qtype;
  f_opCode := opCode;
  f_qClass := qClass;
  f_recurse := recurse;
  //
  f_QD := unaObjectList.create();
  f_AN := unaObjectList.create();
  f_NS := unaObjectList.create();
  f_AR := unaObjectList.create();
  //
  f_ID := id;
  //
  f_status := prepareReq();
  f_prepared := (0 = f_status);
  //
  inherited create();
end;

// --  --
destructor unaDNSQuery.Destroy();
begin
  inherited;
  //
  freeAndNil(f_dnsServers);
  freeAndNil(f_resources);
  //
  freeAndNil(f_QD);
  freeAndNil(f_AN);
  freeAndNil(f_NS);
  freeAndNil(f_AR);
  //
  freeAndNil(f_sockU);
  freeAndNil(f_sockT);
  //
  mrealloc(f_buf);
  //
  dec(pByte(f_req), 2);	// shift back 2 bytes reserved for TCP
  mrealloc(f_req);
end;

// --  --
function unaDNSQuery.doLabels(const resource: string; buf: pArray): int;
var
  p, pFrom: int;
  bufA: aString;
  bufOfs: int;

  // --  --
  function newLabel(): bool;
  var
    sz: int;
  begin
    sz := min(63, p - pFrom);
    if (0 < sz) then begin
      //
      result := false;
      if (bufOfs + sz < 255) then begin
        //
        buf[bufOfs] := sz and (64 - 1);
        inc(bufOfs);
        //
        move(bufA[pFrom], buf[bufOfs], sz);
	inc(bufOfs, sz);
        inc(pFrom, sz + 1);
      end;
    end
    else begin
      //
      result := true;
      if (bufOfs < 255) then begin
        //
        buf[bufOfs] := 0;
        inc(bufOfs);
        //
        inc(pFrom);
      end;
    end;
  end;

var
  root: bool;
begin
  bufA := aString(resource);     // Punycodes? maybe later
  //
  p := 1;
  pFrom := p;
  bufOfs := 0;
  //
  root := false;
  while (p <= length(bufA)) do begin
    //
    if ('.' = bufA[p]) then begin
      //
      if ( (p > pFrom) or (p >= length(bufA)) ) then
        root := newLabel()
      else
        inc(pFrom); // skip dot at begining
      //
      if (root) then
        break;
    end;
    //
    inc(p);
  end;
  //
  if (not root) then begin
    //
    root := newLabel();
    if (not root) then begin
      //
      p := pFrom;
      newLabel();   // terminate with 0
    end;
  end;
  //
  result := bufOfs;
end;

// --  --
function unaDNSQuery.getRR(rindex: int; index: integer): unaDNSRR;
var
  list: unaList;
begin
  case (index) of

    0: list := f_QD;
    1: list := f_AN;
    2: list := f_NS;
    3: list := f_AR;
    else
       list := nil;

  end;
  //
  if (nil <> list) then
    result := list[rindex]
  else
    result := nil;
end;

// --  --
function unaDNSQuery.issue(transport: unaDNS_transport): bool;
var
  addr: sockaddr_in;
  tcpPacket: pByte;
  ip: TIPv4H;
begin
  result := false;
  //
  if (f_issuedCount > 15) then begin
    //
    f_status := -3;
    exit;	// something is wrong with internal logic, let not hammer the UDP server
  end;
  //
  case (transport) of

    unaDnsTR_UDP: begin
      //
      inc(f_issuedCount);
      //
      if (nil = f_sockU) then begin
	//
	freeAndNil(f_sockT);
	//
	f_sockU := unaUDPSocket.create();
	f_sockU.bind();
      end;
      //
      if ( (0 < dnsServers.count) and f_sockU.isConnected(1) ) then begin
	//
	ip := lookupHostH(dnsServers.get(0));
	if (0 <> ip) then begin
	  //
	  if (makeAddr(dnsServers.get(0), int2str(v_DNS_port), addr)) then begin
	    //
	    f_queryWasTCP := false;
	    f_respSize := 0;
	    //
	    f_status := f_sockU.sendto(addr, f_req, f_reqSize, 0, 200);
	    result := (0 = status);
	  end
	  else
	    f_status := -1;
	end
	else
	  f_status := WSAGetLastError(); 	// soket problems?
	//
	if (result) then
	  f_timeout := timeMarkU();
      end;
    end;

    unaDnsTR_TCP: begin
      //
      inc(f_issuedCount);
      //
      if (nil = f_sockT) then begin
	//
	freeAndNil(f_sockU);
	//
	f_sockT := unaTCPSocket.create();
      end;
      //
      if (0 < dnsServers.count) then begin
	//
	f_sockT.host := dnsServers.get(0);
	f_sockT.setPort(v_DNS_port);
	if (0 = f_sockT.connect()) then begin
	  //
	  f_queryWasTCP := true;
	  f_respSize := 0;
	  //
	  tcpPacket := pByte(f_req);
	  dec(tcpPacket, 2);
	  //
	  f_status := f_sockT.send(tcpPacket, f_reqSize + 2, false);
	  result := (0 = status);
	end
	else
	  f_status := WSAGetLastError();
	//
	if (result) then
	  f_timeout := timeMarkU();
      end;
    end;

    unaDnsTR_UDP_then_TCP: begin
      //
      if (nil <> f_sockU) then
	result := issue(unaDnsTR_TCP)
      else
	result := issue(unaDnsTR_UDP);
    end;

    unaDnsTR_TCP_then_UDP: begin
      //
      if (nil <> f_sockT) then
	result := issue(unaDnsTR_UDP)
      else
	result := issue(unaDnsTR_TCP);
    end;

    else begin
      //
      inc(f_issuedCount);	// just to make sure we will not loop on unknown transport
      //
      f_status := -3;	// internal error
    end;

  end;
end;

// --  --
function unaDNSQuery.parse(transport: unaDNS_transport): int;
var
  i: int32;
  ofs: int;
  len: uint16;
  retry: bool;
begin
  if ((0 < respSize) and (nil <> f_buf)) then begin
    //
    if (f_queryWasTCP) then begin
      //
      if (2 < respSize) then
	len := swap16u(pUint16(f_buf)^)
      else
	len := maxWord;
      //
      if (len > respSize - 2) then begin
	//
	result := -2;   // no full data packet yet, exit
	exit;
      end
      else begin
	//
	f_respSize := len;
	f_resp := punaDNS_HDR(@f_buf[2]);	// shift 2 bytes
      end;
    end
    else
      f_resp := punaDNS_HDR(@f_buf[0]);
    //
    ofs := 0;
    //
    f_respCode := int(swap16u(resp.r_QR_OPCODE_AATCRD_RA_Z_RCODE) and $F);
    //
    // should we try other protocol?
    if (f_queryWasTCP) then
      retry := false
    else
      retry := (0 <> (swap16u(resp.r_QR_OPCODE_AATCRD_RA_Z_RCODE) and c_DNS_HDR_MASK_TC));
    //
    if (not retry) then
      //
      case (respCode) of
	c_DNS_HDR_RCODE_SERVER_FAILURE,
	c_DNS_HDR_RCODE_NOT_IMPLEMENTED,
	c_DNS_HDR_RCODE_REFUSED        : retry := true;
      end;
    //
    if (retry) then begin
      //
      // see if we have other options
      case (transport) of

	unaDnsTR_UDP_then_TCP: retry := not f_queryWasTCP;
	unaDnsTR_TCP_then_UDP: retry := f_queryWasTCP;
	else
			       retry := false;	// no other transport options

      end;

    end;
    //
    if (not retry) then begin
      //
      //
      // parse sections
      inc(ofs, sizeof(unaDNS_HDR));
      //
      // 1) parse questions
      for i := 0 to swap16u(resp.r_QDCOUNT) - 1 do
	f_QD.add(unaDNSRR.create(resp, ofs, respSize, true));
      //
      // 2) parse answers
      for i := 0 to swap16u(resp.r_ANCOUNT) - 1 do
	f_AN.add(unaDNSRR.create(resp, ofs, respSize, false));
      //
      // 3) parse name servers
      for i := 0 to swap16u(resp.r_NSCOUNT) - 1 do
	f_NS.add(unaDNSRR.create(resp, ofs, respSize, false));
      //
      // 4) parse additional RRs
      for i := 0 to swap16u(resp.r_ARCOUNT) - 1 do
	f_AR.add(unaDNSRR.create(resp, ofs, respSize, false));
      //
      result := 0;
    end
    else
      result := -3;	// retry on other transport
  end
  else
    result := -1;       // not parsed
end;

// --  --
function unaDNSQuery.prepareReq(): int;
var
  i: int32;
  hdr: punaDNS_HDR;
  buf: array[0..511] of byte;
  bufSz: array[byte] of int;    // store lengths of labels
  rCount: int;
  sz, bufOfs, reqOfs: int;
  w16: uint;
  res: string;
  rec: uint16;
begin
  f_reqSize := sizeof(unaDNS_HDR);
  bufOfs := 0;
  rCount := 0;
  for i := 0 to f_resources.count - 1 do begin
    //
    res := trimS(f_resources.get(i));
    if ('' <> res) then begin
      //
      sz := doLabels(res, pArray(@buf[bufOfs]));
      bufSz[rCount] := sz;
      //
      inc(f_reqSize, sz + 4);
      inc(bufOfs, sz);
      inc(rCount);
    end;
  end;
  //
  mrealloc(f_req, f_reqSize + 2);	// reserve 2 bytes for TCP packet size
  w16 := swap16u(uint16(f_reqSize));
  move(w16, f_req^, 2);			// store packet size for possible TCP request
  //
  inc(pByte(f_req), 2);		// shift req by 2 bytes, dont forget to shift back when unallocating
  hdr := f_req;
  //
  hdr.r_ID := swap16u(uint16(id));
  if (f_recurse) then
    rec := c_DNS_HDR_MASK_RD
  else
    rec := 0;
  //
  hdr.r_QR_OPCODE_AATCRD_RA_Z_RCODE := swap16u(
    (0                 shl 15) or
    ((f_opCode and $F) shl 11) or
    rec or                              // request recursion (or not)
    0
  );
  hdr.r_QDCOUNT := swap16u(uint16(rCount));
  hdr.r_ANCOUNT := swap16u(0);
  hdr.r_NSCOUNT := swap16u(0);
  hdr.r_ARCOUNT := swap16u(0);
  //
  bufOfs := 0;
  reqOfs := sizeof(unaDNS_HDR);
  for i := 0 to rCount - 1 do begin
    //
    sz := bufSz[i];
    if (sz + reqOfs < 512) then begin
      //
      move(buf[bufOfs], pArray(f_req)[reqOfs], sz);
      inc(bufOfs, sz);
      inc(reqOfs, sz);
      //
      w16 := swap16u(uint16(f_qtype));
      move(w16, pArray(f_req)[reqOfs], 2);
      inc(reqOfs, 2);
      //
      w16 := swap16u(uint16(f_qclass));
      move(w16, pArray(f_req)[reqOfs], 2);
      inc(reqOfs, 2);
    end;
  end;
  //
  result := 0;
end;

// --  --
function unaDNSQuery.readFrom(timeout: int): bool;
var
  addr: sockaddr_in;
  sz: uint;
  readStat: int;
begin
  if (respSize >= f_bufSize) then begin
    //
    // allocate another 512 bytes
    inc(f_bufSize, 512);
    mrealloc(f_buf, f_bufSize);
  end;
  //
  sz := f_bufSize - respSize;
  if (f_queryWasTCP) then
    readStat := f_sockT.read(@f_buf[respSize], sz, timeout)
  else begin
    //
    readStat := f_sockU.recvfrom(addr, @f_buf[respSize], sz, false, 0, timeout);
    if (0 < readStat) then begin
      //
      sz := readStat;
      readStat := 0;
    end;
  end;
  //
  // read something?
  result := (0 = readStat);    // 0 if TCP has read somethigng, < 0 if UDP has read something
  if (result) then
    inc(f_respSize, sz);
end;

// --  --
procedure unaDNSQuery.reset(doneWithServer: bool);
begin
  f_timeout := 0;
  f_resp := nil;
  f_respSize := 0;
  //
  // remove current server
  if (doneWithServer) then
    f_dnsServers.removeFromEdge();
  //
  if (f_prepared) then
    f_status := 0;
end;


  { unaDNSClient }

// --  --
constructor unaDNSClient.Create(const dnsServers: string; transport: unaDNS_transport);
begin
  if ('' = dnsServers) then
    f_dnsServers := getDNSServersList()
  else
    f_dnsServers := dnsServers;
  //
  f_queries := unaObjectList.create();
  //
  f_transport := transport;
  //
  inherited create(false);
end;

// --  --
destructor unaDNSClient.Destroy();
begin
  inherited;    // stop thread
  //
  freeAndNil(f_queries);
end;

// --  --
function unaDNSClient.execute(threadID: unsigned): int;
var
  i: int;
  q: unaDNSQuery;
begin
  f_idleTM := TimeMarkU();
  //
  while (not shouldStop) do begin
    //
    if (0 < f_queries.count) then begin
      //
      i := 0;
      while (i < f_queries.count) do begin
	//
	q := f_queries[i];
	if (nil <> q) then begin
	  //
	  if ( (0 = q.timeout) and (0 = q.status) ) then begin
	    //
	    f_idleTM := TimeMarkU();
	    //
	    // issue new query on next server from list
            if (not q.issue(transport)) then
	      pop(q, true)   // if not issued and no more servers, will be notified and removed.
            else
              ; // Otherwise q will be kept in list with (timeout <> 0), so it will be read from on next loop
	  end
          else begin
            //
	    if (0 = q.status) then begin
              //
              // timeout?
              if (v_DNS_timeout > timeElapsed64U(q.timeout)) then begin
                //
                // no, let try reading something
		if (q.readFrom(10)) then begin
		  //
		  case (q.parse(transport)) of   // try to parse what we have read so far

		     // parsed OK
		     0: pop(q, false);   // notify and remove

		     // malformed response
		    -1: pop(q, true);	// notify and remove if no more transport options/servers

		     // need more data
		    -2: ;               // do nothing, hope we read rest of data on next loop

		     // retry
		    -3: q.reset(false);	// reset status and try other transport

		    else
                      // internal error, unknown parse result
                      pop(q, true);     // notify and remove if no more transport options/servers

                  end;
                end
                else
		  ; // it did not timed out yet, but nothing was read yet too, so wait a bit more
	      end
	      else
		pop(q, true);   // notify and remove if no more transport options/servers, or prepare for next issue if there are more options to try
	    end
	    else
	      pop(q, true);     // some problem with socket?
	  end;
	end
	else
	  // should not be here
	  f_queries.removeByIndex(i);
	//
	inc(i);
      end;
      //
      sleepThread(10);  // no need to push hard, wait a little
    end
    else
      sleepThread(50);  // wait for new queries
    //
    if ( not shouldStop and (1 > f_queries.count) and (20000 < timeElapsed64U(f_idleTM)) ) then
      break;	// exit if idle for some time
  end;
  //
  result := 0;
end;

// --  --
class function unaDNSClient.getDNSServersList(): string;
var
  table: PMIB_IFTABLE;
  row: PMIB_IFROW;
  //
  info: PIP_PER_ADAPTER_INFO;
  addr: PIP_ADDR_STRING;
  astr: string;
begin
  result := '';
  //
  table := GetIfTable(false);
  if (nil <> table) then try
    //
    row := @table.table[0];
    while (0 < table.dwNumEntries) do begin
      //
      info := GetPerAdapterInfo(row.dwIndex);
      if (nil <> info) then try
        //
        addr := @info.DnsServerList;
        while (nil <> addr) do begin
          //
          astr := string(addr.IpAddress.aString);
          if ('' <> trimS(astr)) then
            result := result + astr + #13#10;
          //
          addr := addr.Next;
        end;
        //
      finally
        mrealloc(info);
      end;
      //
      dec(table.dwNumEntries);
      inc(row);
    end;
    //
  finally
    mrealloc(table);
  end;
end;

// --  --
procedure unaDNSClient.onAnswer(query: unaDNSQuery);
begin
  // override to get answers
end;

// --  --
procedure unaDNSClient.pop(query: unaDNSQuery; onError: bool);
var
  doneWithServer, remove: bool;
begin
  doneWithServer := true;
  case (transport) of

    unaDnsTR_UDP_then_TCP: doneWithServer := (nil <> query.f_sockT);        // done if TCP was used already
    unaDnsTR_TCP_then_UDP: doneWithServer := (nil <> query.f_sockU);        // done if UDP was used already

  end;
  //
  if (onError) then
    remove := doneWithServer and (2 > query.f_dnsServers.count)		// in case of error, remove only if we are done with current server
									// and there are no more servers
  else
    remove := true;     // no error - just notify and remove
  //
  if (remove) then begin
    //
    if ((nil = query.resp) and (0 = query.status)) then
      query.f_status := -1;		// no response
    //
    onAnswer(query);
    //
    f_queries.removeItem(query);
  end
  else
    query.reset(doneWithServer);      // reset timeout and move to next DNS server if neccessary
end;

// --  --
function unaDNSClient.push(query: unaDNSQuery): int;
begin
  result := query.id;
  f_queries.add(query);
end;

// --  --
function unaDNSClient.query(const resources: string; qtype, opCode, qClass: int; recurse: bool): int;
begin
  result := query(dnsServers, resources, qtype, opCode, qClass, recurse);
end;

// --  --
function unaDNSClient.query(const dnsServers, resources: string; qtype: int; opCode, qClass: int; recurse: bool): int;
begin
  result := push(unaDNSQuery.create(interlockedIncrement(f_id) and $FFFF, dnsServers, resources, qtype, opCode, qClass, recurse, transport));
  //
  start();
end;


end.


