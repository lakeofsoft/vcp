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

	  unaIPHelperAPI.pas
	  Internet Protocol Helper API

	----------------------------------------------
	  Copyright (c) 2002-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 17 Apr 2002

	  modified by:
		Lake, 17 Apr 2002
                Lake, 16 Dec 2011

	----------------------------------------------
*)

{$I unaDef.inc}

{x $DEFINE IPHLPAPI_STATICLINK }	// link IPHLPAPI.DLL statically
{x $DEFINE IPHLPAPI_NICEMACPROC }	// include iph_getAdapterMAC() routine
					// NOTE: will link statically to netapi32.dll ('Netbios')
unit
  unaIPHelperAPI;

interface

uses
  Windows, unaTypes;

(*++

Copyright (c) Microsoft Corporation. All rights reserved.

Module Name:

    iphlpapi.h

Abstract:
    Header file for functions to interact with the IP Stack for MIB-II and
    related functionality

--*)

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
// IPRTRMIB.H has the definitions of the strcutures used to set and get     //
// information                                                              //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////

//#include <iprtrmib.h>
(*++

Copyright (c) Microsoft Corporation. All rights reserved.

Module Name:

    iprtrmib.h

Abstract:
    This file contains:
	o Definitions of the MIB_XX structures passed to and from the IP Router Manager
	    to query and set MIB variables handled by the IP Router Manager
	o The #defines for the MIB variables IDs  handled by the IP Router Manager
	    and made accessible by the MprAdminMIBXXX APIs
	o The Routing PID of the IP Router Manager (as mentioned in ipinfoid.h)

--*)

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
// Included to get the value of MAX_INTERFACE_NAME_LEN                      //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////

//#include <mprapi.h>
const
  MAX_INTERFACE_NAME_LEN  = 256;

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
// Included to get the necessary constants                                  //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////

//#include <ipifcons.h>
(*++

Copyright (c) Microsoft Corporation. All rights reserved.

Module Name:

    ipifcons.h

Abstract:
    Constants needed for the Interface Object

--*)

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
// Media types                                                              //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////

const
  MIN_IF_TYPE                     = 1;

  IF_TYPE_OTHER                   = 1;   // None of the below
  IF_TYPE_REGULAR_1822            = 2;
  IF_TYPE_HDH_1822                = 3;
  IF_TYPE_DDN_X25                 = 4;
  IF_TYPE_RFC877_X25              = 5;
  IF_TYPE_ETHERNET_CSMACD         = 6;
  IF_TYPE_IS088023_CSMACD         = 7;
  IF_TYPE_ISO88024_TOKENBUS       = 8;
  IF_TYPE_ISO88025_TOKENRING      = 9;
  IF_TYPE_ISO88026_MAN            = 10;
  IF_TYPE_STARLAN                 = 11;
  IF_TYPE_PROTEON_10MBIT          = 12;
  IF_TYPE_PROTEON_80MBIT          = 13;
  IF_TYPE_HYPERCHANNEL            = 14;
  IF_TYPE_FDDI                    = 15;
  IF_TYPE_LAP_B                   = 16;
  IF_TYPE_SDLC                    = 17;
  IF_TYPE_DS1                     = 18;  // DS1-MIB
  IF_TYPE_E1                      = 19;  // Obsolete; see DS1-MIB
  IF_TYPE_BASIC_ISDN              = 20;
  IF_TYPE_PRIMARY_ISDN            = 21;
  IF_TYPE_PROP_POINT2POINT_SERIAL = 22;  // proprietary serial
  IF_TYPE_PPP                     = 23;
  IF_TYPE_SOFTWARE_LOOPBACK       = 24;
  IF_TYPE_EON                     = 25;  // CLNP over IP
  IF_TYPE_ETHERNET_3MBIT          = 26;
  IF_TYPE_NSIP                    = 27;  // XNS over IP
  IF_TYPE_SLIP                    = 28;  // Generic Slip
  IF_TYPE_ULTRA                   = 29;  // ULTRA Technologies
  IF_TYPE_DS3                     = 30;  // DS3-MIB
  IF_TYPE_SIP                     = 31;  // SMDS, coffee
  IF_TYPE_FRAMERELAY              = 32;  // DTE only
  IF_TYPE_RS232                   = 33;
  IF_TYPE_PARA                    = 34;  // Parallel port
  IF_TYPE_ARCNET                  = 35;
  IF_TYPE_ARCNET_PLUS             = 36;
  IF_TYPE_ATM                     = 37;  // ATM cells
  IF_TYPE_MIO_X25                 = 38;
  IF_TYPE_SONET                   = 39;  // SONET or SDH
  IF_TYPE_X25_PLE                 = 40;
  IF_TYPE_ISO88022_LLC            = 41;
  IF_TYPE_LOCALTALK               = 42;
  IF_TYPE_SMDS_DXI                = 43;
  IF_TYPE_FRAMERELAY_SERVICE      = 44;  // FRNETSERV-MIB
  IF_TYPE_V35                     = 45;
  IF_TYPE_HSSI                    = 46;
  IF_TYPE_HIPPI                   = 47;
  IF_TYPE_MODEM                   = 48;  // Generic Modem
  IF_TYPE_AAL5                    = 49;  // AAL5 over ATM
  IF_TYPE_SONET_PATH              = 50;
  IF_TYPE_SONET_VT                = 51;
  IF_TYPE_SMDS_ICIP               = 52;  // SMDS InterCarrier Interface
  IF_TYPE_PROP_VIRTUAL            = 53;  // Proprietary virtual/internal
  IF_TYPE_PROP_MULTIPLEXOR        = 54;  // Proprietary multiplexing
  IF_TYPE_IEEE80212               = 55;  // 100BaseVG
  IF_TYPE_FIBRECHANNEL            = 56;
  IF_TYPE_HIPPIINTERFACE          = 57;
  IF_TYPE_FRAMERELAY_INTERCONNECT = 58;  // Obsolete, use 32 or 44
  IF_TYPE_AFLANE_8023             = 59;  // ATM Emulated LAN for 802.3
  IF_TYPE_AFLANE_8025             = 60;  // ATM Emulated LAN for 802.5
  IF_TYPE_CCTEMUL                 = 61;  // ATM Emulated circuit
  IF_TYPE_FASTETHER               = 62;  // Fast Ethernet (100BaseT)
  IF_TYPE_ISDN                    = 63;  // ISDN and X.25
  IF_TYPE_V11                     = 64;  // CCITT V.11/X.21
  IF_TYPE_V36                     = 65;  // CCITT V.36
  IF_TYPE_G703_64K                = 66;  // CCITT G703 at 64Kbps
  IF_TYPE_G703_2MB                = 67;  // Obsolete; see DS1-MIB
  IF_TYPE_QLLC                    = 68;  // SNA QLLC
  IF_TYPE_FASTETHER_FX            = 69;  // Fast Ethernet (100BaseFX)
  IF_TYPE_CHANNEL                 = 70;
  IF_TYPE_IEEE80211               = 71;  // Radio spread spectrum
  IF_TYPE_IBM370PARCHAN           = 72;  // IBM System 360/370 OEMI Channel
  IF_TYPE_ESCON                   = 73;  // IBM Enterprise Systems Connection
  IF_TYPE_DLSW                    = 74;  // Data Link Switching
  IF_TYPE_ISDN_S                  = 75;  // ISDN S/T interface
  IF_TYPE_ISDN_U                  = 76;  // ISDN U interface
  IF_TYPE_LAP_D                   = 77;  // Link Access Protocol D
  IF_TYPE_IPSWITCH                = 78;  // IP Switching Objects
  IF_TYPE_RSRB                    = 79;  // Remote Source Route Bridging
  IF_TYPE_ATM_LOGICAL             = 80;  // ATM Logical Port
  IF_TYPE_DS0                     = 81;  // Digital Signal Level 0
  IF_TYPE_DS0_BUNDLE              = 82;  // Group of ds0s on the same ds1
  IF_TYPE_BSC                     = 83;  // Bisynchronous Protocol
  IF_TYPE_ASYNC                   = 84;  // Asynchronous Protocol
  IF_TYPE_CNR                     = 85;  // Combat Net Radio
  IF_TYPE_ISO88025R_DTR           = 86;  // ISO 802.5r DTR
  IF_TYPE_EPLRS                   = 87;  // Ext Pos Loc Report Sys
  IF_TYPE_ARAP                    = 88;  // Appletalk Remote Access Protocol
  IF_TYPE_PROP_CNLS               = 89;  // Proprietary Connectionless Proto
  IF_TYPE_HOSTPAD                 = 90;  // CCITT-ITU X.29 PAD Protocol
  IF_TYPE_TERMPAD                 = 91;  // CCITT-ITU X.3 PAD Facility
  IF_TYPE_FRAMERELAY_MPI          = 92;  // Multiproto Interconnect over FR
  IF_TYPE_X213                    = 93;  // CCITT-ITU X213
  IF_TYPE_ADSL                    = 94;  // Asymmetric Digital Subscrbr Loop
  IF_TYPE_RADSL                   = 95;  // Rate-Adapt Digital Subscrbr Loop
  IF_TYPE_SDSL                    = 96;  // Symmetric Digital Subscriber Loop
  IF_TYPE_VDSL                    = 97;  // Very H-Speed Digital Subscrb Loop
  IF_TYPE_ISO88025_CRFPRINT       = 98;  // ISO 802.5 CRFP
  IF_TYPE_MYRINET                 = 99;  // Myricom Myrinet
  IF_TYPE_VOICE_EM                = 100; // Voice recEive and transMit
  IF_TYPE_VOICE_FXO               = 101; // Voice Foreign Exchange Office
  IF_TYPE_VOICE_FXS               = 102; // Voice Foreign Exchange Station
  IF_TYPE_VOICE_ENCAP             = 103; // Voice encapsulation
  IF_TYPE_VOICE_OVERIP            = 104; // Voice over IP encapsulation
  IF_TYPE_ATM_DXI                 = 105; // ATM DXI
  IF_TYPE_ATM_FUNI                = 106; // ATM FUNI
  IF_TYPE_ATM_IMA                 = 107; // ATM IMA
  IF_TYPE_PPPMULTILINKBUNDLE      = 108; // PPP Multilink Bundle
  IF_TYPE_IPOVER_CDLC             = 109; // IBM ipOverCdlc
  IF_TYPE_IPOVER_CLAW             = 110; // IBM Common Link Access to Workstn
  IF_TYPE_STACKTOSTACK            = 111; // IBM stackToStack
  IF_TYPE_VIRTUALIPADDRESS        = 112; // IBM VIPA
  IF_TYPE_MPC                     = 113; // IBM multi-proto channel support
  IF_TYPE_IPOVER_ATM              = 114; // IBM ipOverAtm
  IF_TYPE_ISO88025_FIBER          = 115; // ISO 802.5j Fiber Token Ring
  IF_TYPE_TDLC                    = 116; // IBM twinaxial data link control
  IF_TYPE_GIGABITETHERNET         = 117;
  IF_TYPE_HDLC                    = 118;
  IF_TYPE_LAP_F                   = 119;
  IF_TYPE_V37                     = 120;
  IF_TYPE_X25_MLP                 = 121; // Multi-Link Protocol
  IF_TYPE_X25_HUNTGROUP           = 122; // X.25 Hunt Group
  IF_TYPE_TRANSPHDLC              = 123;
  IF_TYPE_INTERLEAVE              = 124; // Interleave channel
  IF_TYPE_FAST                    = 125; // Fast channel
  IF_TYPE_IP                      = 126; // IP (for APPN HPR in IP networks)
  IF_TYPE_DOCSCABLE_MACLAYER      = 127; // CATV Mac Layer
  IF_TYPE_DOCSCABLE_DOWNSTREAM    = 128; // CATV Downstream interface
  IF_TYPE_DOCSCABLE_UPSTREAM      = 129; // CATV Upstream interface
  IF_TYPE_A12MPPSWITCH            = 130; // Avalon Parallel Processor
  IF_TYPE_TUNNEL                  = 131; // Encapsulation interface
  IF_TYPE_COFFEE                  = 132; // Coffee pot
  IF_TYPE_CES                     = 133; // Circuit Emulation Service
  IF_TYPE_ATM_SUBINTERFACE        = 134; // ATM Sub Interface
  IF_TYPE_L2_VLAN                 = 135; // Layer 2 Virtual LAN using 802.1Q
  IF_TYPE_L3_IPVLAN               = 136; // Layer 3 Virtual LAN using IP
  IF_TYPE_L3_IPXVLAN              = 137; // Layer 3 Virtual LAN using IPX
  IF_TYPE_DIGITALPOWERLINE        = 138; // IP over Power Lines
  IF_TYPE_MEDIAMAILOVERIP         = 139; // Multimedia Mail over IP
  IF_TYPE_DTM                     = 140; // Dynamic syncronous Transfer Mode
  IF_TYPE_DCN                     = 141; // Data Communications Network
  IF_TYPE_IPFORWARD               = 142; // IP Forwarding Interface
  IF_TYPE_MSDSL                   = 143; // Multi-rate Symmetric DSL
  IF_TYPE_IEEE1394                = 144; // IEEE1394 High Perf Serial Bus
  IF_TYPE_RECEIVE_ONLY            = 145; // TV adapter type

  MAX_IF_TYPE                     = 145;

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
// Access types                                                             //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////

const
  IF_ACCESS_LOOPBACK              = 1;
  IF_ACCESS_BROADCAST             = 2;
  IF_ACCESS_POINTTOPOINT          = 3;
  IF_ACCESS_POINTTOMULTIPOINT     = 4;

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
// Interface Capabilities (bit flags)                                       //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////

  IF_CHECK_NONE                   = $00;
  IF_CHECK_MCAST                  = $01;
  IF_CHECK_SEND                   = $02;


//////////////////////////////////////////////////////////////////////////////
//                                                                          //
// Connection Types                                                         //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////

  IF_CONNECTION_DEDICATED         = 1;
  IF_CONNECTION_PASSIVE           = 2;
  IF_CONNECTION_DEMAND            = 3;

  IF_ADMIN_STATUS_UP              = 1;
  IF_ADMIN_STATUS_DOWN            = 2;
  IF_ADMIN_STATUS_TESTING         = 3;

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
// The following are the the operational states for WAN and LAN interfaces. //
// The order of the states seems weird, but is done for a purpose. All      //
// states >= CONNECTED can transmit data right away. States >= DISCONNECTED //
// can tx data but some set up might be needed. States < DISCONNECTED can   //
// not transmit data.                                                       //
// A card is marked UNREACHABLE if DIM calls InterfaceUnreachable for       //
// reasons other than failure to connect.                                   //
//                                                                          //
// NON_OPERATIONAL -- Valid for LAN Interfaces. Means the card is not       //
//                      working or not plugged in or has no address.        //
// UNREACHABLE     -- Valid for WAN Interfaces. Means the remote site is    //
//                      not reachable at this time.                         //
// DISCONNECTED    -- Valid for WAN Interfaces. Means the remote site is    //
//                      not connected at this time.                         //
// CONNECTING      -- Valid for WAN Interfaces. Means a connection attempt  //
//                      has been initiated to the remote site.              //
// CONNECTED       -- Valid for WAN Interfaces. Means the remote site is    //
//                      connected.                                          //
// OPERATIONAL     -- Valid for LAN Interfaces. Means the card is plugged   //
//                      in and working.                                     //
//                                                                          //
// It is the users duty to convert these values to MIB-II values if they    //
// are to be used by a subagent                                             //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////

  IF_OPER_STATUS_NON_OPERATIONAL  = 0;
  IF_OPER_STATUS_UNREACHABLE      = 1;
  IF_OPER_STATUS_DISCONNECTED     = 2;
  IF_OPER_STATUS_CONNECTING       = 3;
  IF_OPER_STATUS_CONNECTED        = 4;
  IF_OPER_STATUS_OPERATIONAL      = 5;

  MIB_IF_TYPE_OTHER               = 1;
  MIB_IF_TYPE_ETHERNET            = 6;
  MIB_IF_TYPE_TOKENRING           = 9;
  MIB_IF_TYPE_FDDI                = 15;
  MIB_IF_TYPE_PPP                 = 23;
  MIB_IF_TYPE_LOOPBACK            = 24;
  MIB_IF_TYPE_SLIP                = 28;

  MIB_IF_ADMIN_STATUS_UP          = 1;
  MIB_IF_ADMIN_STATUS_DOWN        = 2;
  MIB_IF_ADMIN_STATUS_TESTING     = 3;

  MIB_IF_OPER_STATUS_NON_OPERATIONAL      = 0;
  MIB_IF_OPER_STATUS_UNREACHABLE          = 1;
  MIB_IF_OPER_STATUS_DISCONNECTED         = 2;
  MIB_IF_OPER_STATUS_CONNECTING           = 3;
  MIB_IF_OPER_STATUS_CONNECTED            = 4;
  MIB_IF_OPER_STATUS_OPERATIONAL          = 5;

// end of ipifcons.h

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
// This is the Id for IP Router Manager.  The Router Manager handles        //
// MIB-II, Forwarding MIB and some enterprise specific information.         //
// Calls made with any other ID are passed on to the corresponding protocol //
// For example, an MprAdminMIBXXX call with a protocol ID of PID_IP and    //
// a routing Id of 0xD will be sent to the IP Router Manager and then       //
// forwarded to OSPF                                                        //
// This lives in the same number space as the protocol Ids of RIP, OSPF     //
// etc, so any change made to it should be done keeping this in mind        //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////

const
  IPRTRMGR_PID = 10000;

  ANY_SIZE = 1;

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
// The following #defines are the Ids of the MIB variables made accessible  //
// to the user via MprAdminMIBXXX Apis.  It will be noticed that these are  //
// not the same as RFC 1213, since the MprAdminMIBXXX APIs work on rows and //
// groups instead of scalar variables                                       //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////

const
  IF_NUMBER           = 0;
  IF_TABLE            = (IF_NUMBER          + 1);
  IF_ROW              = (IF_TABLE           + 1);
  IP_STATS            = (IF_ROW             + 1);
  IP_ADDRTABLE        = (IP_STATS           + 1);
  IP_ADDRROW          = (IP_ADDRTABLE       + 1);
  IP_FORWARDNUMBER    = (IP_ADDRROW         + 1);
  IP_FORWARDTABLE     = (IP_FORWARDNUMBER   + 1);
  IP_FORWARDROW       = (IP_FORWARDTABLE    + 1);
  IP_NETTABLE         = (IP_FORWARDROW      + 1);
  IP_NETROW           = (IP_NETTABLE        + 1);
  ICMP_STATS          = (IP_NETROW          + 1);
  TCP_STATS           = (ICMP_STATS         + 1);
  TCP_TABLE           = (TCP_STATS          + 1);
  TCP_ROW             = (TCP_TABLE          + 1);
  UDP_STATS           = (TCP_ROW            + 1);
  UDP_TABLE           = (UDP_STATS          + 1);
  UDP_ROW             = (UDP_TABLE          + 1);
  MCAST_MFE           = (UDP_ROW            + 1);
  MCAST_MFE_STATS     = (MCAST_MFE          + 1);
  BEST_IF             = (MCAST_MFE_STATS    + 1);
  BEST_ROUTE          = (BEST_IF            + 1);
  PROXY_ARP           = (BEST_ROUTE         + 1);
  MCAST_IF_ENTRY      = (PROXY_ARP          + 1);
  MCAST_GLOBAL        = (MCAST_IF_ENTRY     + 1);
  IF_STATUS           = (MCAST_GLOBAL       + 1);
  MCAST_BOUNDARY      = (IF_STATUS          + 1);
  MCAST_SCOPE         = (MCAST_BOUNDARY     + 1);
  DEST_MATCHING       = (MCAST_SCOPE        + 1);
  DEST_LONGER         = (DEST_MATCHING      + 1);
  DEST_SHORTER        = (DEST_LONGER        + 1);
  ROUTE_MATCHING      = (DEST_SHORTER       + 1);
  ROUTE_LONGER        = (ROUTE_MATCHING     + 1);
  ROUTE_SHORTER       = (ROUTE_LONGER       + 1);
  ROUTE_STATE         = (ROUTE_SHORTER      + 1);
  MCAST_MFE_STATS_EX  = (ROUTE_STATE        + 1);
  IP6_STATS           = (MCAST_MFE_STATS_EX + 1);
  UDP6_STATS          = (IP6_STATS          + 1);
  TCP6_STATS          = (UDP6_STATS         + 1);

  NUMBER_OF_EXPORTED_VARIABLES    = (TCP6_STATS + 1);


//////////////////////////////////////////////////////////////////////////////
//                                                                          //
// MIB_OPAQUE_QUERY is the structure filled in by the user to identify a    //
// MIB variable                                                             //
//                                                                          //
//  dwVarId     ID of MIB Variable (One of the Ids #defined above)          //
//  dwVarIndex  Variable sized array containing the indices needed to       //
//              identify a variable. NOTE: Unlike SNMP we dont require that //
//              a scalar variable be indexed by 0                           //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////

type
  PMIB_OPAQUE_QUERY = ^MIB_OPAQUE_QUERY;
  MIB_OPAQUE_QUERY = packed record
    dwVarId: DWORD;
    rgdwVarIndex: array[0..ANY_SIZE - 1] of DWORD;
  end;

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
// The following are the structures which are filled in and returned to the //
// user when a query is made, OR  are filled in BY THE USER when a set is   //
// done                                                                     //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////

type
  PMIB_IFNUMBER = ^MIB_IFNUMBER;
  MIB_IFNUMBER = packed record
    dwValue: DWORD;
  end;

const
  MAXLEN_IFDESCR = 256;
  MAXLEN_PHYSADDR = 8;

type
  PMIB_IFROW = ^MIB_IFROW;
  MIB_IFROW = packed record
    wszName: array[0..MAX_INTERFACE_NAME_LEN - 1] of wChar;
    dwIndex:           DWORD;
    dwType:            DWORD;
    dwMtu:             DWORD;
    dwSpeed:           DWORD;
    dwPhysAddrLen:     DWORD;
    bPhysAddr: array[0..MAXLEN_PHYSADDR - 1] of BYTE;
    dwAdminStatus:     DWORD;
    dwOperStatus:      DWORD;
    dwLastChange:      DWORD;
    dwInOctets:        DWORD;
    dwInUcastPkts:     DWORD;
    dwInNUcastPkts:    DWORD;
    dwInDiscards:      DWORD;
    dwInErrors:        DWORD;
    dwInUnknownProtos: DWORD;
    dwOutOctets:       DWORD;
    dwOutUcastPkts:    DWORD;
    dwOutNUcastPkts:   DWORD;
    dwOutDiscards:     DWORD;
    dwOutErrors:       DWORD;
    dwOutQLen:         DWORD;
    dwDescrLen:        DWORD;
    bDescr: array[0..MAXLEN_IFDESCR - 1] of BYTE;
  end;

  PMIB_IFTABLE = ^MIB_IFTABLE;
  MIB_IFTABLE = packed record
    dwNumEntries: DWORD;
    table: array[0..ANY_SIZE - 1] of MIB_IFROW;
  end;

//#define SIZEOF_IFTABLE(X) (FIELD_OFFSET(MIB_IFTABLE,table[0]) + ((X) * sizeof(MIB_IFROW)) + ALIGN_SIZE)

  MIBICMPSTATS = packed record
    dwMsgs:          DWORD;
    dwErrors:        DWORD;
    dwDestUnreachs:  DWORD;
    dwTimeExcds:     DWORD;
    dwParmProbs:     DWORD;
    dwSrcQuenchs:    DWORD;
    dwRedirects:     DWORD;
    dwEchos:         DWORD;
    dwEchoReps:      DWORD;
    dwTimestamps:    DWORD;
    dwTimestampReps: DWORD;
    dwAddrMasks:     DWORD;
    dwAddrMaskReps:  DWORD;
  end;

  MIBICMPINFO = packed record
    icmpInStats: MIBICMPSTATS;
    icmpOutStats: MIBICMPSTATS;
  end;

  PMIB_ICMP = ^MIB_ICMP;
  MIB_ICMP = packed record
    stats: MIBICMPINFO;
  end;

  PMIB_UDPSTATS = ^MIB_UDPSTATS;
  MIB_UDPSTATS = packed record
    dwInDatagrams:  DWORD;
    dwNoPorts:      DWORD;
    dwInErrors:     DWORD;
    dwOutDatagrams: DWORD;
    dwNumAddrs:     DWORD;
  end;

  PMIB_UDPROW = ^MIB_UDPROW;
  MIB_UDPROW = packed record
    dwLocalAddr: DWORD;
    dwLocalPort: DWORD;
  end;

  PMIB_UDPTABLE = ^MIB_UDPTABLE;
  MIB_UDPTABLE = packed record
    dwNumEntries: DWORD;
    table: array [0..ANY_SIZE - 1] of MIB_UDPROW;
  end;

//#define SIZEOF_UDPTABLE(X) (FIELD_OFFSET(MIB_UDPTABLE, table[0]) + ((X) * sizeof(MIB_UDPROW)) + ALIGN_SIZE)

  PMIB_TCPSTATS = ^MIB_TCPSTATS;
  MIB_TCPSTATS = packed record
    dwRtoAlgorithm: DWORD;
    dwRtoMin:       DWORD;
    dwRtoMax:       DWORD;
    dwMaxConn:      DWORD;
    dwActiveOpens:  DWORD;
    dwPassiveOpens: DWORD;
    dwAttemptFails: DWORD;
    dwEstabResets:  DWORD;
    dwCurrEstab:    DWORD;
    dwInSegs:       DWORD;
    dwOutSegs:      DWORD;
    dwRetransSegs:  DWORD;
    dwInErrs:       DWORD;
    dwOutRsts:      DWORD;
    dwNumConns:     DWORD;
  end;

const
  MIB_TCP_RTO_OTHER       = 1;
  MIB_TCP_RTO_CONSTANT    = 2;
  MIB_TCP_RTO_RSRE        = 3;
  MIB_TCP_RTO_VANJ        = 4;

  MIB_TCP_MAXCONN_DYNAMIC  = DWORD(-1);

type
  PMIB_TCPROW = ^MIB_TCPROW;
  MIB_TCPROW = packed record
    dwState:      DWORD;
    dwLocalAddr:  DWORD;
    dwLocalPort:  DWORD;
    dwRemoteAddr: DWORD;
    dwRemotePort: DWORD;
  end;

const
  MIB_TCP_STATE_CLOSED            = 1;
  MIB_TCP_STATE_LISTEN            = 2;
  MIB_TCP_STATE_SYN_SENT          = 3;
  MIB_TCP_STATE_SYN_RCVD          = 4;
  MIB_TCP_STATE_ESTAB             = 5;
  MIB_TCP_STATE_FIN_WAIT1         = 6;
  MIB_TCP_STATE_FIN_WAIT2         = 7;
  MIB_TCP_STATE_CLOSE_WAIT        = 8;
  MIB_TCP_STATE_CLOSING           = 9;
  MIB_TCP_STATE_LAST_ACK          = 10;
  MIB_TCP_STATE_TIME_WAIT         = 11;
  MIB_TCP_STATE_DELETE_TCB        = 12;

type  
  PMIB_TCPTABLE = ^MIB_TCPTABLE;
  MIB_TCPTABLE = packed record
    dwNumEntries: DWORD;
    table: array [0..ANY_SIZE - 1] of MIB_TCPROW;
  end;

//#define SIZEOF_TCPTABLE(X) (FIELD_OFFSET(MIB_TCPTABLE,table[0]) + ((X) * sizeof(MIB_TCPROW)) + ALIGN_SIZE)

const
  MIB_USE_CURRENT_TTL         = DWORD(-1);
  MIB_USE_CURRENT_FORWARDING  = DWORD(-1);

type
  PMIB_IPSTATS = ^MIB_IPSTATS;
  MIB_IPSTATS = packed record
    dwForwarding:      DWORD;
    dwDefaultTTL:      DWORD;
    dwInReceives:      DWORD;
    dwInHdrErrors:     DWORD;
    dwInAddrErrors:    DWORD;
    dwForwDatagrams:   DWORD;
    dwInUnknownProtos: DWORD;
    dwInDiscards:      DWORD;
    dwInDelivers:      DWORD;
    dwOutRequests:     DWORD;
    dwRoutingDiscards: DWORD;
    dwOutDiscards:     DWORD;
    dwOutNoRoutes:     DWORD;
    dwReasmTimeout:    DWORD;
    dwReasmReqds:      DWORD;
    dwReasmOks:        DWORD;
    dwReasmFails:      DWORD;
    dwFragOks:         DWORD;
    dwFragFails:       DWORD;
    dwFragCreates:     DWORD;
    dwNumIf:           DWORD;
    dwNumAddr:         DWORD;
    dwNumRoutes:       DWORD;
  end;

const
  MIB_IP_FORWARDING               = 1;
  MIB_IP_NOT_FORWARDING           = 2;

// Note: These addr types have dependency on ipdef.h

  MIB_IPADDR_PRIMARY      = $0001;   // Primary ipaddr
  MIB_IPADDR_DYNAMIC      = $0004;   // Dynamic ipaddr
  MIB_IPADDR_DISCONNECTED = $0008;   // Address is on disconnected interface
  MIB_IPADDR_DELETED      = $0040;   // Address being deleted
  MIB_IPADDR_TRANSIENT    = $0080;   // Transient address

type
  PMIB_IPADDRROW = ^MIB_IPADDRROW;
  MIB_IPADDRROW = packed record
    dwAddr: DWORD;
    dwIndex: DWORD;
    dwMask: DWORD;
    dwBCastAddr: DWORD;
    dwReasmSize: DWORD;
    unused1: word;
    wType: word;
  end;

  PMIB_IPADDRTABLE = ^MIB_IPADDRTABLE;
  MIB_IPADDRTABLE = packed record
    dwNumEntries: DWORD;
    table: array[0..ANY_SIZE - 1] of MIB_IPADDRROW;
  end;

//#define SIZEOF_IPADDRTABLE(X) (FIELD_OFFSET(MIB_IPADDRTABLE,table[0]) + ((X) * sizeof(MIB_IPADDRROW)) + ALIGN_SIZE)

  PMIB_IPFORWARDNUMBER = ^MIB_IPFORWARDNUMBER;
  MIB_IPFORWARDNUMBER = packed record
    dwValue: DWORD;
  end;

  PMIB_IPFORWARDROW = ^MIB_IPFORWARDROW;
  MIB_IPFORWARDROW = packed record
    dwForwardDest:      DWORD;
    dwForwardMask:      DWORD;
    dwForwardPolicy:    DWORD;
    dwForwardNextHop:   DWORD;
    dwForwardIfIndex:   DWORD;
    dwForwardType:      DWORD;
    dwForwardProto:     DWORD;
    dwForwardAge:       DWORD;
    dwForwardNextHopAS: DWORD;
    dwForwardMetric1:   DWORD;
    dwForwardMetric2:   DWORD;
    dwForwardMetric3:   DWORD;
    dwForwardMetric4:   DWORD;
    dwForwardMetric5:   DWORD;
  end;

const
  MIB_IPROUTE_TYPE_OTHER        = 1;
  MIB_IPROUTE_TYPE_INVALID      = 2;
  MIB_IPROUTE_TYPE_DIRECT       = 3;
  MIB_IPROUTE_TYPE_INDIRECT     = 4;

  MIB_IPROUTE_METRIC_UNUSED    = DWORD(-1);

//
// THESE MUST MATCH the ids in routprot.h
//

  MIB_IPPROTO_OTHER                = 1;
  MIB_IPPROTO_LOCAL                = 2;
  MIB_IPPROTO_NETMGMT              = 3;
  MIB_IPPROTO_ICMP                 = 4;
  MIB_IPPROTO_EGP                  = 5;
  MIB_IPPROTO_GGP                  = 6;
  MIB_IPPROTO_HELLO                = 7;
  MIB_IPPROTO_RIP                  = 8;
  MIB_IPPROTO_IS_IS                = 9;
  MIB_IPPROTO_ES_IS                = 10;
  MIB_IPPROTO_CISCO                = 11;
  MIB_IPPROTO_BBN                  = 12;
  MIB_IPPROTO_OSPF                 = 13;
  MIB_IPPROTO_BGP                  = 14;

  MIB_IPPROTO_NT_AUTOSTATIC       = 10002;
  MIB_IPPROTO_NT_STATIC           = 10006;
  MIB_IPPROTO_NT_STATIC_NON_DOD   = 10007;

type
  PMIB_IPFORWARDTABLE = ^MIB_IPFORWARDTABLE;
  MIB_IPFORWARDTABLE = packed record
    dwNumEntries: DWORD;
    table: array[0..ANY_SIZE - 1] of MIB_IPFORWARDROW;
  end;

//#define SIZEOF_IPFORWARDTABLE(X) (FIELD_OFFSET(MIB_IPFORWARDTABLE,table[0]) + ((X) * sizeof(MIB_IPFORWARDROW)) + ALIGN_SIZE)

  PMIB_IPNETROW = ^MIB_IPNETROW;
  MIB_IPNETROW = packed record
    dwIndex: DWORD;
    dwPhysAddrLen: DWORD;
    bPhysAddr: array [0..MAXLEN_PHYSADDR - 1] of BYTE;
    dwAddr: DWORD;
    dwType: DWORD;
  end;

const
  MIB_IPNET_TYPE_OTHER        = 1;
  MIB_IPNET_TYPE_INVALID      = 2;
  MIB_IPNET_TYPE_DYNAMIC      = 3;
  MIB_IPNET_TYPE_STATIC       = 4;

type
  PMIB_IPNETTABLE = ^MIB_IPNETTABLE;
  MIB_IPNETTABLE = packed record
    dwNumEntries: DWORD;
    table: array [0..ANY_SIZE - 1] of MIB_IPNETROW;
  end;

//#define SIZEOF_IPNETTABLE(X) (FIELD_OFFSET(MIB_IPNETTABLE, table[0]) + ((X) * sizeof(MIB_IPNETROW)) + ALIGN_SIZE)

  PMIB_IPMCAST_OIF = ^MIB_IPMCAST_OIF;
  MIB_IPMCAST_OIF = packed record
    dwOutIfIndex: DWORD;
    dwNextHopAddr: DWORD;
    dwReserved: DWORD;
    dwReserved1: DWORD;
  end;

  PMIB_IPMCAST_MFE = ^MIB_IPMCAST_MFE;
  MIB_IPMCAST_MFE = packed record
    dwGroup:         DWORD;
    dwSource:        DWORD;
    dwSrcMask:       DWORD;
    dwUpStrmNgbr:    DWORD;
    dwInIfIndex:     DWORD;
    dwInIfProtocol:  DWORD;
    dwRouteProtocol: DWORD;
    dwRouteNetwork:  DWORD;
    dwRouteMask:     DWORD;
    ulUpTime:        ULONG;
    ulExpiryTime:    ULONG;
    ulTimeOut:       ULONG;
    ulNumOutIf:      ULONG;
    fFlags:          DWORD;
    dwReserved:      DWORD;
    rgmioOutInfo: array [0..ANY_SIZE - 1] of MIB_IPMCAST_OIF;
  end;

  PMIB_MFE_TABLE = ^MIB_MFE_TABLE;
  MIB_MFE_TABLE = packed record
    dwNumEntries: DWORD;
    table: array [0..ANY_SIZE - 1] of MIB_IPMCAST_MFE;
  end;

//#define SIZEOF_BASIC_MIB_MFE          \
//    (ULONG)(FIELD_OFFSET(MIB_IPMCAST_MFE, rgmioOutInfo[0]))

//#define SIZEOF_MIB_MFE(X)             \
//    (SIZEOF_BASIC_MIB_MFE + ((X) * sizeof(MIB_IPMCAST_OIF)))

  PMIB_IPMCAST_OIF_STATS = ^MIB_IPMCAST_OIF_STATS;
  MIB_IPMCAST_OIF_STATS = packed record
    dwOutIfIndex:  DWORD;
    dwNextHopAddr: DWORD;
    dwDialContext: DWORD;
    ulTtlTooLow:   ULONG;
    ulFragNeeded:  ULONG;
    ulOutPackets:  ULONG;
    ulOutDiscards: ULONG;
  end;

  PMIB_IPMCAST_MFE_STATS = ^MIB_IPMCAST_MFE_STATS;
  MIB_IPMCAST_MFE_STATS = packed record
    dwGroup:           DWORD;
    dwSource:          DWORD;
    dwSrcMask:         DWORD;
    dwUpStrmNgbr:      DWORD;
    dwInIfIndex:       DWORD;
    dwInIfProtocol:    DWORD;
    dwRouteProtocol:   DWORD;
    dwRouteNetwork:    DWORD;
    dwRouteMask:       DWORD;
    ulUpTime:          ULONG;
    ulExpiryTime:      ULONG;
    ulNumOutIf:        ULONG;
    ulInPkts:          ULONG;
    ulInOctets:        ULONG;
    ulPktsDifferentIf: ULONG;
    ulQueueOverflow:   ULONG;
    rgmiosOutStats: array[0..ANY_SIZE - 1] of MIB_IPMCAST_OIF_STATS;
  end;

  PMIB_MFE_STATS_TABLE = ^MIB_MFE_STATS_TABLE;
  MIB_MFE_STATS_TABLE = packed record
    dwNumEntries: DWORD;
    table: array[0..ANY_SIZE - 1] of MIB_IPMCAST_MFE_STATS;
  end;

//#define SIZEOF_BASIC_MIB_MFE_STATS    \
//    (ULONG)(FIELD_OFFSET(MIB_IPMCAST_MFE_STATS, rgmiosOutStats[0]))

//#define SIZEOF_MIB_MFE_STATS(X)       \
//    (SIZEOF_BASIC_MIB_MFE_STATS + ((X) * sizeof(MIB_IPMCAST_OIF_STATS)))


  PMIB_IPMCAST_MFE_STATS_EX = ^MIB_IPMCAST_MFE_STATS_EX;
  MIB_IPMCAST_MFE_STATS_EX = packed record
    dwGroup:           DWORD;
    dwSource:          DWORD;
    dwSrcMask:         DWORD;
    dwUpStrmNgbr:      DWORD;
    dwInIfIndex:       DWORD;
    dwInIfProtocol:    DWORD;
    dwRouteProtocol:   DWORD;
    dwRouteNetwork:    DWORD;
    dwRouteMask:       DWORD;
    ulUpTime:          ULONG;
    ulExpiryTime:      ULONG;
    ulNumOutIf:        ULONG;
    ulInPkts:          ULONG;
    ulInOctets:        ULONG;
    ulPktsDifferentIf: ULONG;
    ulQueueOverflow:   ULONG;
    ulUninitMfe:       ULONG;
    ulNegativeMfe:     ULONG;
    ulInDiscards:      ULONG;
    ulInHdrErrors:     ULONG;
    ulTotalOutPackets: ULONG;
    rgmiosOutStats: array[0..ANY_SIZE - 1] of MIB_IPMCAST_OIF_STATS;
  end;

  PMIB_MFE_STATS_TABLE_EX = ^MIB_MFE_STATS_TABLE_EX;
  MIB_MFE_STATS_TABLE_EX = packed record
    dwNumEntries: DWORD;
    table: array[0..ANY_SIZE - 1] of MIB_IPMCAST_MFE_STATS_EX;
  end;

//#define SIZEOF_BASIC_MIB_MFE_STATS_EX    \
//    (ULONG)(FIELD_OFFSET(MIB_IPMCAST_MFE_STATS_EX, rgmiosOutStats[0]))

//#define SIZEOF_MIB_MFE_STATS_EX(X)       \
//    (SIZEOF_BASIC_MIB_MFE_STATS_EX + ((X) * sizeof(MIB_IPMCAST_OIF_STATS)))


  PMIB_IPMCAST_GLOBAL = ^MIB_IPMCAST_GLOBAL;
  MIB_IPMCAST_GLOBAL  = packed record
    dwEnable: DWORD;
  end;

  PMIB_IPMCAST_IF_ENTRY = ^MIB_IPMCAST_IF_ENTRY;
  MIB_IPMCAST_IF_ENTRY = packed record
    dwIfIndex:        DWORD;
    dwTtl:            DWORD;
    dwProtocol:       DWORD;
    dwRateLimit:      DWORD;
    ulInMcastOctets:  ULONG;
    ulOutMcastOctets: ULONG;
  end;

  PMIB_IPMCAST_IF_TABLE = ^MIB_IPMCAST_IF_TABLE;
  MIB_IPMCAST_IF_TABLE = packed record
    dwNumEntries: DWORD;
    table: array[0..ANY_SIZE - 1] of MIB_IPMCAST_IF_ENTRY;
  end;

//#define SIZEOF_MCAST_IF_TABLE(X) (FIELD_OFFSET(MIB_IPMCAST_IF_TABLE,table[0]) + ((X) * sizeof(MIB_IPMCAST_IF_ENTRY)) + ALIGN_SIZE)

  PMIB_IPMCAST_BOUNDARY = ^MIB_IPMCAST_BOUNDARY;
  MIB_IPMCAST_BOUNDARY = packed record
    dwIfIndex: DWORD;
    dwGroupAddress: DWORD;
    dwGroupMask: DWORD;
    dwStatus: DWORD;
  end;

  PMIB_IPMCAST_BOUNDARY_TABLE = ^MIB_IPMCAST_BOUNDARY_TABLE;
  MIB_IPMCAST_BOUNDARY_TABLE = packed record
    dwNumEntries: DWORD;
    table: array[0..ANY_SIZE - 1] of MIB_IPMCAST_BOUNDARY;
  end;

//#define SIZEOF_BOUNDARY_TABLE(X) (FIELD_OFFSET(MIB_IPMCAST_BOUNDARY_TABLE,table[0]) + ((X) * sizeof(MIB_IPMCAST_BOUNDARY)) + ALIGN_SIZE)

  PMIB_BOUNDARYROW = ^MIB_BOUNDARYROW;
  MIB_BOUNDARYROW = packed record
    dwGroupAddress: DWORD;
    dwGroupMask: DWORD;
  end;

// Structure matching what goes in the registry in a block of type
// IP_MCAST_LIMIT_INFO.  This contains the fields of
// MIB_IPMCAST_IF_ENTRY which are configurable.

  PMIB_MCAST_LIMIT_ROW = ^MIB_MCAST_LIMIT_ROW;
  MIB_MCAST_LIMIT_ROW = packed record
    dwTtl: DWORD;
    dwRateLimit: DWORD;
  end;

const
  MAX_SCOPE_NAME_LEN = 255;

//
// Scope names are unicode.  SNMP and MZAP use UTF-8 encoding.
//

type
  SN_CHAR = WCHAR;
  SCOPE_NAME = ^SCOPE_NAME_BUFFER;
  SCOPE_NAME_BUFFER = array[0..MAX_SCOPE_NAME_LEN] of SN_CHAR;

  PMIB_IPMCAST_SCOPE = ^MIB_IPMCAST_SCOPE;
  MIB_IPMCAST_SCOPE = packed record
    dwGroupAddress: DWORD;
    dwGroupMask: DWORD;
    snNameBuffer: SCOPE_NAME_BUFFER;
    dwStatus: DWORD;
  end;

  PMIB_IPDESTROW = ^MIB_IPDESTROW;
  MIB_IPDESTROW = packed record
    ForwardRow: MIB_IPFORWARDROW;
    dwForwardPreference: DWORD;
    dwForwardViewSet: DWORD;
  end;

  PMIB_IPDESTTABLE = ^MIB_IPDESTTABLE;
  MIB_IPDESTTABLE = packed record
    dwNumEntries: DWORD;
    table: array [0..ANY_SIZE - 1] of MIB_IPDESTROW;
  end;

  PMIB_BEST_IF = ^MIB_BEST_IF;
  MIB_BEST_IF = packed record
    dwDestAddr: DWORD;
    dwIfIndex: DWORD;
  end;

  PMIB_PROXYARP = ^MIB_PROXYARP;
  MIB_PROXYARP = packed record
    dwAddress: DWORD;
    dwMask: DWORD;
    dwIfIndex: DWORD;
  end;

  PMIB_IFSTATUS = ^MIB_IFSTATUS;
  MIB_IFSTATUS = packed record
    dwIfIndex: DWORD;
    dwAdminStatus: DWORD;
    dwOperationalStatus: DWORD;
    bMHbeatActive: BOOL;
    bMHbeatAlive: BOOL;
  end;

  PMIB_ROUTESTATE = ^MIB_ROUTESTATE;
  MIB_ROUTESTATE = packed record
    bRoutesSetToStack: BOOL;
  end;

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
// All the info passed to (SET/CREATE) and from (GET/GETNEXT/GETFIRST)      //
// IP Router Manager is encapsulated in the following "discriminated"       //
// union.  To pass, say MIB_IFROW, use the following code                   //
//                                                                          //
//  PMIB_OPAQUE_INFO    pInfo;                                              //
//  PMIB_IFROW          pIfRow;                                             //
//  DWORD rgdwBuff[(MAX_MIB_OFFSET + sizeof(MIB_IFROW))/sizeof(DWORD) + 1]; //
//                                                                          //
//  pInfo   = (PMIB_OPAQUE_INFO)rgdwBuffer;                                 //
//  pIfRow  = (MIB_IFROW *)(pInfo->rgbyData);                               //
//                                                                          //
//  This can also be accomplished by using the following macro              //
//                                                                          //
//  DEFINE_MIB_BUFFER(pInfo,MIB_IFROW, pIfRow);                             //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////

  ULONGLONG = int64;	// cardinal64

  PMIB_OPAQUE_INFO = ^MIB_OPAQUE_INFO;
  MIB_OPAQUE_INFO = packed record
    dwId: DWORD;
    case DWORD of
      0: (
	ullAlign: ULONGLONG;
      );
      1: (
	rgbyData: array[0..0] of BYTE;
      );
  end;

const
  MAX_MIB_OFFSET      = 8;

//#define MIB_INFO_SIZE(S)                \
//    (MAX_MIB_OFFSET + sizeof(S))

//#define MIB_INFO_SIZE_IN_DWORDS(S)      \
//    ((MIB_INFO_SIZE(S))/sizeof(DWORD) + 1)

//#define DEFINE_MIB_BUFFER(X,Y,Z)                                        \
//    DWORD        __rgdwBuff[MIB_INFO_SIZE_IN_DWORDS(Y)]; \
//    PMIB_OPAQUE_INFO    X = (PMIB_OPAQUE_INFO)__rgdwBuff;               \
//    Y *                 Z = (Y *)(X->rgbyData)

//#define CAST_MIB_INFO(X,Y,Z)    Z = (Y)(X->rgbyData)

//end of iprtrmib.h

//#include <ipexport.h>

(********************************************************************/
/**                     Microsoft LAN Manager                      **/
/**     Copyright (c) Microsoft Corporation. All rights reserved.  **/
/********************************************************************/
/* :ts=4 *)

//** IPEXPORT.H - IP public definitions.
//
//  This file contains public definitions exported to transport layer and
//  application software.
//

//
// IP type definitions.
//
type
  IPAddr = ULONG;       // An IP address.
  IPMask = ULONG;       // An IP subnet mask.
  IP_STATUS = ULONG;    // Status code returned from IP APIs.

//#ifndef s6_addr
//
// Duplicate these definitions here so that this file can be included by
// kernel-mode components which cannot include ws2tcpip.h, as well as
// by user-mode components which do.
//

  USHORT = WORD;

  IN6_ADDR = packed record
    case boolean of
      true: (
	uByte: array[0..16 - 1] of UCHAR;
      );
      false: (
	uWord: array[0..8 - 1] of USHORT;
      );
  end;

  in_addr6 = IN6_ADDR;

//
// Defines to match RFC 2553.
//
//#define _S6_un      u
//#define _S6_u8      Byte
//#define s6_addr     _S6_un._S6_u8

//
// Defines for our implementation.
//
//#define s6_bytes    u.Byte
//#define s6_words    u.Word

//#endif

  IPv6Addr = in6_addr;

(*INC*)

//
// The ip_option_information structure describes the options to be
// included in the header of an IP packet. The TTL, TOS, and Flags
// values are carried in specific fields in the header. The OptionsData
// bytes are carried in the options area following the standard IP header.
// With the exception of source route options, this data must be in the
// format to be transmitted on the wire as specified in RFC 791. A source
// route option should contain the full route - first hop thru final
// destination - in the route data. The first hop will be pulled out of the
// data and the option will be reformatted accordingly. Otherwise, the route
// option should be formatted as specified in RFC 791.
//

  PIP_OPTION_INFORMATION = ^IP_OPTION_INFORMATION;
  IP_OPTION_INFORMATION = packed record
    Ttl: UCHAR;                // Time To Live
    Tos: UCHAR;                // Type Of Service
    Flags: UCHAR;              // IP header flags
    OptionsSize: UCHAR;        // Size in bytes of options data
    OptionsData: PUCHAR;        // Pointer to options data
  end;

//#if defined(_WIN64)
(*
typedef struct ip_option_information32 {
    UCHAR   Ttl;
    UCHAR   Tos;
    UCHAR   Flags;
    UCHAR   OptionsSize;
    UCHAR * POINTER_32 OptionsData;
} IP_OPTION_INFORMATION32, *PIP_OPTION_INFORMATION32;
*)
//#endif // _WIN64

//
// The icmp_echo_reply structure describes the data returned in response
// to an echo request.
//

  PVOID = pointer;
  
  PICMP_ECHO_REPLY = ^ICMP_ECHO_REPLY;
  ICMP_ECHO_REPLY = packed record
    Address: IPAddr;            // Replying address
    Status: ULONG;             // Reply IP_STATUS
    RoundTripTime: ULONG;      // RTT in milliseconds
    DataSize: USHORT;           // Reply data size in bytes
    Reserved: USHORT;           // Reserved for system use
    Data: PVOID;               // Pointer to the reply data
    Options: ip_option_information; // Reply options
  end;

//#if defined(_WIN64)
(*
typedef struct icmp_echo_reply32 {
    IPAddr  Address;
    ULONG   Status;
    ULONG   RoundTripTime;
    USHORT  DataSize;
    USHORT  Reserved;
    VOID * POINTER_32 Data;
    struct ip_option_information32 Options;
} ICMP_ECHO_REPLY32, *PICMP_ECHO_REPLY32;
*)
//#endif // _WIN64

  PARP_SEND_REPLY = ^ARP_SEND_REPLY;
  ARP_SEND_REPLY = packed record
    DestAddress: IPAddr;
    SrcAddress: IPAddr;
  end;

  PTCP_RESERVE_PORT_RANGE = ^TCP_RESERVE_PORT_RANGE;
  TCP_RESERVE_PORT_RANGE = packed record
    UpperRange: USHORT;
    LowerRange: USHORT;
  end;

const
  MAX_ADAPTER_NAME = 128;

type
  PIP_ADAPTER_INDEX_MAP = ^IP_ADAPTER_INDEX_MAP;
  IP_ADAPTER_INDEX_MAP = packed record
    Index: ULONG;
    Name: array[0..MAX_ADAPTER_NAME - 1] of WCHAR;
  end;

  LONG = integer;
  
  PIP_INTERFACE_INFO = ^IP_INTERFACE_INFO;
  IP_INTERFACE_INFO = packed record
    NumAdapters: LONG;
    Adapter: array[0..0] of IP_ADAPTER_INDEX_MAP;
  end;

  PIP_UNIDIRECTIONAL_ADAPTER_ADDRESS = ^IP_UNIDIRECTIONAL_ADAPTER_ADDRESS;
  IP_UNIDIRECTIONAL_ADAPTER_ADDRESS = packed record
    NumAdapters: ULONG;
    Address: array[0..0] of IPAddr;
  end;

  PIP_ADAPTER_ORDER_MAP = ^IP_ADAPTER_ORDER_MAP;
  IP_ADAPTER_ORDER_MAP = packed record
    NumAdapters: ULONG;
    AdapterOrder: array[0..0] of ULONG;
  end;

  ULONG64 = int64;	// cardinal64

  PIP_MCAST_COUNTER_INFO = ^IP_MCAST_COUNTER_INFO;
  IP_MCAST_COUNTER_INFO = packed record
    InMcastOctets: ULONG64;
    OutMcastOctets: ULONG64;
    InMcastPkts: ULONG64;
    OutMcastPkts: ULONG64;
  end;

//
// IP_STATUS codes returned from IP APIs
//
const
  IP_STATUS_BASE              = 11000;

  IP_SUCCESS                  = 0;
  IP_BUF_TOO_SMALL            = (IP_STATUS_BASE + 1);
  IP_DEST_NET_UNREACHABLE     = (IP_STATUS_BASE + 2);
  IP_DEST_HOST_UNREACHABLE    = (IP_STATUS_BASE + 3);
  IP_DEST_PROT_UNREACHABLE    = (IP_STATUS_BASE + 4);
  IP_DEST_PORT_UNREACHABLE    = (IP_STATUS_BASE + 5);
  IP_NO_RESOURCES             = (IP_STATUS_BASE + 6);
  IP_BAD_OPTION               = (IP_STATUS_BASE + 7);
  IP_HW_ERROR                 = (IP_STATUS_BASE + 8);
  IP_PACKET_TOO_BIG           = (IP_STATUS_BASE + 9);
  IP_REQ_TIMED_OUT            = (IP_STATUS_BASE + 10);
  IP_BAD_REQ                  = (IP_STATUS_BASE + 11);
  IP_BAD_ROUTE                = (IP_STATUS_BASE + 12);
  IP_TTL_EXPIRED_TRANSIT      = (IP_STATUS_BASE + 13);
  IP_TTL_EXPIRED_REASSEM      = (IP_STATUS_BASE + 14);
  IP_PARAM_PROBLEM            = (IP_STATUS_BASE + 15);
  IP_SOURCE_QUENCH            = (IP_STATUS_BASE + 16);
  IP_OPTION_TOO_BIG           = (IP_STATUS_BASE + 17);
  IP_BAD_DESTINATION          = (IP_STATUS_BASE + 18);

//
// Variants of the above using IPv6 terminology, where different
//

  IP_DEST_NO_ROUTE            = (IP_STATUS_BASE + 2);
  IP_DEST_ADDR_UNREACHABLE    = (IP_STATUS_BASE + 3);
  IP_DEST_PROHIBITED          = (IP_STATUS_BASE + 4);
//  IP_DEST_PORT_UNREACHABLE    = (IP_STATUS_BASE + 5);
  IP_HOP_LIMIT_EXCEEDED       = (IP_STATUS_BASE + 13);
  IP_REASSEMBLY_TIME_EXCEEDED = (IP_STATUS_BASE + 14);
  IP_PARAMETER_PROBLEM        = (IP_STATUS_BASE + 15);

//
// IPv6-only status codes
//

  IP_DEST_UNREACHABLE         = (IP_STATUS_BASE + 40);
  IP_TIME_EXCEEDED            = (IP_STATUS_BASE + 41);
  IP_BAD_HEADER               = (IP_STATUS_BASE + 42);
  IP_UNRECOGNIZED_NEXT_HEADER = (IP_STATUS_BASE + 43);
  IP_ICMP_ERROR               = (IP_STATUS_BASE + 44);
  IP_DEST_SCOPE_MISMATCH      = (IP_STATUS_BASE + 45);

//
// The next group are status codes passed up on status indications to
// transport layer protocols.
//
  IP_ADDR_DELETED             = (IP_STATUS_BASE + 19);
  IP_SPEC_MTU_CHANGE          = (IP_STATUS_BASE + 20);
  IP_MTU_CHANGE               = (IP_STATUS_BASE + 21);
  IP_UNLOAD                   = (IP_STATUS_BASE + 22);
  IP_ADDR_ADDED               = (IP_STATUS_BASE + 23);
  IP_MEDIA_CONNECT            = (IP_STATUS_BASE + 24);
  IP_MEDIA_DISCONNECT         = (IP_STATUS_BASE + 25);
  IP_BIND_ADAPTER             = (IP_STATUS_BASE + 26);
  IP_UNBIND_ADAPTER           = (IP_STATUS_BASE + 27);
  IP_DEVICE_DOES_NOT_EXIST    = (IP_STATUS_BASE + 28);
  IP_DUPLICATE_ADDRESS        = (IP_STATUS_BASE + 29);
  IP_INTERFACE_METRIC_CHANGE  = (IP_STATUS_BASE + 30);
  IP_RECONFIG_SECFLTR         = (IP_STATUS_BASE + 31);
  IP_NEGOTIATING_IPSEC        = (IP_STATUS_BASE + 32);
  IP_INTERFACE_WOL_CAPABILITY_CHANGE  = (IP_STATUS_BASE + 33);
  IP_DUPLICATE_IPADD          = (IP_STATUS_BASE + 34);

  IP_GENERAL_FAILURE          = (IP_STATUS_BASE + 50);
  MAX_IP_STATUS               = IP_GENERAL_FAILURE;
  IP_PENDING                  = (IP_STATUS_BASE + 255);


//
// Values used in the IP header Flags field.
//
  IP_FLAG_DF      = $02;         // Don't fragment this packet.

//
// Supported IP Option Types.
//
// These types define the options which may be used in the OptionsData field
// of the ip_option_information structure.  See RFC 791 for a complete
// description of each.
//
  IP_OPT_EOL      = 0;          // End of list option
  IP_OPT_NOP      = 1;          // No operation
  IP_OPT_SECURITY = $82;       // Security option
  IP_OPT_LSRR     = $83;       // Loose source route
  IP_OPT_SSRR     = $89;       // Strict source route
  IP_OPT_RR       = $7;        // Record route
  IP_OPT_TS       = $44;       // Timestamp
  IP_OPT_SID      = $88;       // Stream ID (obsolete)
  IP_OPT_ROUTER_ALERT = $94;  // Router Alert Option

  MAX_OPT_SIZE    = 40;         // Maximum length of IP options in bytes

//#ifdef CHICAGO

// Ioctls code exposed by Memphis tcpip stack.
// For NT these ioctls are define in ntddip.h  (private\inc)

  IOCTL_IP_RTCHANGE_NOTIFY_REQUEST   = 101;
  IOCTL_IP_ADDCHANGE_NOTIFY_REQUEST  = 102;
  IOCTL_ARP_SEND_REQUEST             = 103;
  IOCTL_IP_INTERFACE_INFO            = 104;
  IOCTL_IP_GET_BEST_INTERFACE        = 105;
  IOCTL_IP_UNIDIRECTIONAL_ADAPTER_ADDRESS        = 106;

//#endif


// end of ipexport.h

//#include <iptypes.h>

(*++

Copyright (c) Microsoft Corporation. All rights reserved.

Module Name:

    iptypes.h

--*)

//#include <time.h>

type
  time_t = long;

// Definitions and structures used by getnetworkparams and getadaptersinfo apis
const
  MAX_ADAPTER_DESCRIPTION_LENGTH  = 128; // arb.
  MAX_ADAPTER_NAME_LENGTH         = 256; // arb.
  MAX_ADAPTER_ADDRESS_LENGTH      = 8;   // arb.
  DEFAULT_MINIMUM_ENTITIES        = 32;  // arb.
  MAX_HOSTNAME_LEN                = 128; // arb.
  MAX_DOMAIN_NAME_LEN             = 128; // arb.
  MAX_SCOPE_ID_LEN                = 256; // arb.

//
// types
//

// Node Type

  BROADCAST_NODETYPE              = 1;
  PEER_TO_PEER_NODETYPE           = 2;
  MIXED_NODETYPE                  = 4;
  HYBRID_NODETYPE                 = 8;

//
// IP_ADDRESS_STRING - store an IP address as a dotted decimal string
//

type
  PIP_ADDRESS_STRING = ^IP_ADDRESS_STRING;
  IP_ADDRESS_STRING = packed record
    aString: array [0..16 - 1] of aChar;
  end;

  PIP_MASK_STRING = ^IP_MASK_STRING;
  IP_MASK_STRING = IP_ADDRESS_STRING;

//
// IP_ADDR_STRING - store an IP address with its corresponding subnet mask,
// both as dotted decimal strings
//

  PIP_ADDR_STRING = ^IP_ADDR_STRING;
  IP_ADDR_STRING = packed record
    Next: PIP_ADDR_STRING;
    IpAddress: IP_ADDRESS_STRING;
    IpMask: IP_MASK_STRING;
    Context: DWORD;
  end;

//
// ADAPTER_INFO - per-adapter information. All IP addresses are stored as
// strings
//
  PIP_ADAPTER_INFO = ^IP_ADAPTER_INFO;
  IP_ADAPTER_INFO = packed record
    Next: PIP_ADAPTER_INFO;
    ComboIndex: DWORD;
    AdapterName: array[0..MAX_ADAPTER_NAME_LENGTH + 4 - 1] of aChar;
    Description: array[0..MAX_ADAPTER_DESCRIPTION_LENGTH + 4 - 1] of aChar;
    AddressLength: UINT;
    Address: array[0..MAX_ADAPTER_ADDRESS_LENGTH - 1] of BYTE;
    Index: DWORD;
    aType: UINT;
    DhcpEnabled: UINT;
    CurrentIpAddress: PIP_ADDR_STRING;
    IpAddressList: IP_ADDR_STRING;
    GatewayList: IP_ADDR_STRING;
    DhcpServer: IP_ADDR_STRING;
    HaveWins: BOOL;
    PrimaryWinsServer: IP_ADDR_STRING;
    SecondaryWinsServer: IP_ADDR_STRING;
    LeaseObtained: time_t;
    LeaseExpires: time_t;
  end;

//#ifdef _WINSOCK2API_

//
// The following types require Winsock2.
//

  IP_PREFIX_ORIGIN = (
    IpPrefixOriginOther,
    IpPrefixOriginManual,
    IpPrefixOriginWellKnown,
    IpPrefixOriginDhcp,
    IpPrefixOriginRouterAdvertisement);

  IP_SUFFIX_ORIGIN = (
    IpSuffixOriginOther,
    IpSuffixOriginManual,
    IpSuffixOriginWellKnown,
    IpSuffixOriginDhcp,
    IpSuffixOriginLinkLayerAddress,
    IpSuffixOriginRandom);

  IP_DAD_STATE = (
    IpDadStateInvalid,
    IpDadStateTentative,
    IpDadStateDuplicate,
    IpDadStateDeprecated,
    IpDadStatePreferred);


  IP_ADDRESS_SUB_REC = packed record
    case boolean of
      true: (
	Alignment: ULONGLONG;
      );
      false: (
	Length: ULONG;
	Flags: DWORD;
      );
  end;

// from WinSock.h

  u_short = word;
  
(*
 * Structure used by kernel to store most
 * addresses.
 *)
  sockaddr = packed record
    sa_family: u_short;              //* address family */
    sa_data: array [0..14 - 1] of char;            //* up to 14 bytes of direct address */
  end;


// from NspAPI.h

//
// SockAddr Information
//
  LPSOCKADDR = ^sockaddr;
  //INT = int32;

  PSOCKET_ADDRESS = ^SOCKET_ADDRESS;
  SOCKET_ADDRESS = packed record
    lpSockaddr: LPSOCKADDR;
    iSockaddrLength: INT32;
  end;
  LPSOCKET_ADDRESS = PSOCKET_ADDRESS;

  PIP_ADAPTER_UNICAST_ADDRESS = ^IP_ADAPTER_UNICAST_ADDRESS;
  IP_ADAPTER_UNICAST_ADDRESS = packed record
    subRec: IP_ADDRESS_SUB_REC;
    Next: PIP_ADAPTER_UNICAST_ADDRESS;
    Address: SOCKET_ADDRESS;

    PrefixOrigin: IP_PREFIX_ORIGIN;
    SuffixOrigin: IP_SUFFIX_ORIGIN;
    DadState: IP_DAD_STATE;

    ValidLifetime: ULONG;
    PreferredLifetime: ULONG;
    LeaseLifetime: ULONG;
  end;

  PIP_ADAPTER_ANYCAST_ADDRESS = ^IP_ADAPTER_ANYCAST_ADDRESS;
  IP_ADAPTER_ANYCAST_ADDRESS = packed record
    subRec: IP_ADDRESS_SUB_REC;
    Next: PIP_ADAPTER_ANYCAST_ADDRESS;
    Address: SOCKET_ADDRESS;
  end;

  PIP_ADAPTER_MULTICAST_ADDRESS = ^IP_ADAPTER_MULTICAST_ADDRESS;
  IP_ADAPTER_MULTICAST_ADDRESS = packed record
    subRec: IP_ADDRESS_SUB_REC;
    Next: PIP_ADAPTER_MULTICAST_ADDRESS;
    Address: SOCKET_ADDRESS;
  end;

//
// Per-address Flags
//
const
  IP_ADAPTER_ADDRESS_DNS_ELIGIBLE = $01;
  IP_ADAPTER_ADDRESS_TRANSIENT    = $02;

type  
  PIP_ADAPTER_DNS_SERVER_ADDRESS = ^IP_ADAPTER_DNS_SERVER_ADDRESS;
  IP_ADAPTER_DNS_SERVER_ADDRESS = packed record
    subRec: IP_ADDRESS_SUB_REC;
    Next: PIP_ADAPTER_DNS_SERVER_ADDRESS;
    Address: SOCKET_ADDRESS;
  end;

//
// Per-adapter Flags
//
const
  IP_ADAPTER_DDNS_ENABLED            = $01;
  IP_ADAPTER_REGISTER_ADAPTER_SUFFIX = $02;
  IP_ADAPTER_DHCP_ENABLED            = $04;

//
// OperStatus values from RFC 2863
//
type
  IF_OPER_STATUS = (
    IfOperStatus_NULL,	// this is required, since IfOperStatusUp must be = 1
    IfOperStatusUp,
    IfOperStatusDown,
    IfOperStatusTesting,
    IfOperStatusUnknown,
    IfOperStatusDormant,
    IfOperStatusNotPresent,
    IfOperStatusLowerLayerDown);


  PIP_ADAPTER_ADDRESSES = ^IP_ADAPTER_ADDRESSES;
  IP_ADAPTER_ADDRESSES = packed record
    subRec: IP_ADDRESS_SUB_REC;
    Next: PIP_ADAPTER_ADDRESSES;
    AdapterName: paCHAR;
    FirstUnicastAddress: PIP_ADAPTER_UNICAST_ADDRESS;
    FirstAnycastAddress: PIP_ADAPTER_ANYCAST_ADDRESS;
    FirstMulticastAddress: PIP_ADAPTER_MULTICAST_ADDRESS;
    FirstDnsServerAddress: PIP_ADAPTER_DNS_SERVER_ADDRESS;
    DnsSuffix: PWCHAR;
    Description: PWCHAR;
    FriendlyName: PWCHAR;
    PhysicalAddress: array[0..MAX_ADAPTER_ADDRESS_LENGTH - 1] of BYTE;
    PhysicalAddressLength: DWORD;
    Flags: DWORD;
    Mtu: DWORD;
    IfType: DWORD;
    OperStatus: IF_OPER_STATUS;
  end;

//
// Flags used as argument to GetAdaptersAddresses()
//
const
  GAA_FLAG_SKIP_UNICAST      = $0001;
  GAA_FLAG_SKIP_ANYCAST      = $0002;
  GAA_FLAG_SKIP_MULTICAST    = $0004;
  GAA_FLAG_SKIP_DNS_SERVER   = $0008;

//#endif /* _WINSOCK2API_ */

//
// IP_PER_ADAPTER_INFO - per-adapter IP information such as DNS server list.
//
type
  PIP_PER_ADAPTER_INFO = ^IP_PER_ADAPTER_INFO;
  IP_PER_ADAPTER_INFO = packed record
    AutoconfigEnabled: UINT;
    AutoconfigActive: UINT;
    CurrentDnsServer: PIP_ADDR_STRING;
    DnsServerList: IP_ADDR_STRING;
  end;

//
// FIXED_INFO - the set of IP-related information which does not depend on DHCP
//

  PFIXED_INFO = ^FIXED_INFO;
  FIXED_INFO = packed record
    HostName: array[0..MAX_HOSTNAME_LEN + 4 - 1] of char;
    DomainName: array[0..MAX_DOMAIN_NAME_LEN + 4 - 1] of char;
    CurrentDnsServer: PIP_ADDR_STRING;
    DnsServerList: IP_ADDR_STRING;
    NodeType: UINT;
    ScopeId: array[0..MAX_SCOPE_ID_LEN + 4 - 1] of char;
    EnableRouting: UINT;
    EnableProxy: UINT;
    EnableDns: UINT;
  end;

// end of iptypes.h

{$IFDEF IPHLPAPI_NICEMACPROC }
{*
        Returns adapter's MAC address
}
function iph_getAdapterMAC(index: int = -1): string;

{$ENDIF IPHLPAPI_NICEMACPROC }

{$IFDEF IPHLPAPI_STATICLINK }

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
// The GetXXXTable APIs take a buffer and a size of buffer.  If the buffer  //
// is not large enough, the APIs return ERROR_INSUFFICIENT_BUFFER  and      //
// *pdwSize is the required buffer size                                     //
// The bOrder is a BOOLEAN, which if TRUE sorts the table according to      //
// MIB-II (RFC XXXX)                                                        //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////////////
//                                                                          //
// Retrieves the number of interfaces in the system. These include LAN and  //
// WAN interfaces                                                           //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////
{$EXTERNALSYM GetNumberOfInterfaces}
function GetNumberOfInterfaces({OUT} pdwNumIf: PDWORD): DWORD; stdcall;

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
// Gets the MIB-II ifEntry                                                  //
// The dwIndex field of the MIB_IFROW should be set to the index of the     //
// interface being queried                                                  //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////
function GetIfEntry({IN OUT} pIfRow: PMIB_IFROW): DWORD; stdcall;

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
// Gets the MIB-II IfTable                                                  //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////
function GetIfTable({OUT} pIfTable: PMIB_IFTABLE;
		    {IN OUT} pdwSize: PULONG;
		    {IN} bOrder: BOOL): DWORD; stdcall;

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
// Gets the Interface to IP Address mapping                                 //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////
function GetIpAddrTable({OUT} pIpAddrTable: PMIB_IPADDRTABLE;
			{IN OUT} pdwSize: PULONG;
			{IN} bOrder: BOOL): DWORD; stdcall;

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
// Gets the current IP Address to Physical Address (ARP) mapping            //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////
function GetIpNetTable({OUT} pIpNetTable: PMIB_IPNETTABLE;
		       {IN OUT} pdwSize: PULONG;
		       {IN} bOrder: BOOL): DWORD; stdcall;

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
// Gets the IP Routing Table  (RFX XXXX)                                    //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////
function GetIpForwardTable({OUT} pIpForwardTable: PMIB_IPFORWARDTABLE;
			   {IN OUT} pdwSize: PULONG;
			   {IN} bOrder: BOOL): DWORD; stdcall;

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
// Gets TCP Connection/UDP Listener Table                                   //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////
function GetTcpTable(
    {OUT}    pTcpTable: PMIB_TCPTABLE;
    {IN OUT} pdwSize: PDWORD;
    {IN}     bOrder: BOOL
    ): DWORD; stdcall;

function GetUdpTable(
    {OUT}    pUdpTable: PMIB_UDPTABLE;
    {IN OUT} pdwSize: PDWORD;
    {IN}     bOrder: BOOL
    ): DWORD; stdcall;

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
// Gets IP/ICMP/TCP/UDP Statistics                                          //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////
function GetIpStatistics(
    {OUT}  pStats: PMIB_IPSTATS
    ): DWORD; stdcall;

function GetIpStatisticsEx(
    {OUT}  pStats: PMIB_IPSTATS;
    {IN}   dwFamily: DWORD
    ): DWORD; stdcall;

function GetIcmpStatistics(
    {OUT} pStats: PMIB_ICMP
    ): DWORD; stdcall;

function GetTcpStatistics(
    {OUT} pStats: PMIB_TCPSTATS
    ): DWORD; stdcall;

function GetTcpStatisticsEx(
    {OUT} pStats: PMIB_TCPSTATS;
    {IN}  dwFamily: DWORD
    ): DWORD; stdcall;

function GetUdpStatistics(
    {OUT} pStats: PMIB_UDPSTATS
    ): DWORD; stdcall;

function GetUdpStatisticsEx(
    {OUT} pStats: PMIB_UDPSTATS;
    {IN}  dwFamily: DWORD
    ): DWORD; stdcall;

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
// Used to set the ifAdminStatus on an interface.  The only fields of the   //
// MIB_IFROW that are relevant are the dwIndex (index of the interface      //
// whose status needs to be set) and the dwAdminStatus which can be either  //
// MIB_IF_ADMIN_STATUS_UP or MIB_IF_ADMIN_STATUS_DOWN                       //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////
function SetIfEntry(
    {IN} pIfRow: PMIB_IFROW
    ): DWORD; stdcall;

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
// Used to create, modify or delete a route.  In all cases the              //
// dwForwardIfIndex, dwForwardDest, dwForwardMask, dwForwardNextHop and     //
// dwForwardPolicy MUST BE SPECIFIED. Currently dwForwardPolicy is unused   //
// and MUST BE 0.                                                           //
// For a set, the complete MIB_IPFORWARDROW structure must be specified     //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////
function CreateIpForwardEntry(
    {IN} pRoute: PMIB_IPFORWARDROW
    ): DWORD; stdcall;

function SetIpForwardEntry(
    {IN} pRoute: PMIB_IPFORWARDROW
    ): DWORD; stdcall;

function DeleteIpForwardEntry(
    {IN} pRoute: PMIB_IPFORWARDROW
    ): DWORD; stdcall;

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
// Used to set the ipForwarding to ON or OFF (currently only ON->OFF is     //
// allowed) and to set the defaultTTL.  If only one of the fields needs to  //
// be modified and the other needs to be the same as before the other field //
// needs to be set to MIB_USE_CURRENT_TTL or MIB_USE_CURRENT_FORWARDING as  //
// the case may be                                                          //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////
function SetIpStatistics(
    {IN} pIpStats: PMIB_IPSTATS
    ): DWORD; stdcall;

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
// Used to set the defaultTTL.                                              //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////
function SetIpTTL(
    {?} nTTL: UINT 
    ): DWORD; stdcall;

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
// Used to create, modify or delete an ARP entry.  In all cases the dwIndex //
// dwAddr field MUST BE SPECIFIED.                                          //
// For a set, the complete MIB_IPNETROW structure must be specified         //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////
function CreateIpNetEntry(
    {IN} pArpEntry: PMIB_IPNETROW
    ): DWORD; stdcall;

function SetIpNetEntry(
    {IN} pArpEntry: PMIB_IPNETROW
    ): DWORD; stdcall;

function DeleteIpNetEntry(
    {IN} pArpEntry: PMIB_IPNETROW
    ): DWORD; stdcall;

function FlushIpNetTable(
    {IN} dwIfIndex: DWORD
    ): DWORD; stdcall;


//////////////////////////////////////////////////////////////////////////////
//                                                                          //
// Used to create or delete a Proxy ARP entry. The dwIndex is the index of  //
// the interface on which to PARP for the dwAddress.  If the interface is   //
// of a type that doesnt support ARP, e.g. PPP, then the call will fail     //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////
function CreateProxyArpEntry(
    {IN}  dwAddress: DWORD;
    {IN}  dwMask: DWORD;
    {IN}  dwIfIndex: DWORD   
    ): DWORD; stdcall;

function DeleteProxyArpEntry(
    {IN}  dwAddress: DWORD;
    {IN}  dwMask: DWORD;
    {IN}  dwIfIndex: DWORD   
    ): DWORD; stdcall;

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
// Used to set the state of a TCP Connection. The only state that it can be //
// set to is MIB_TCP_STATE_DELETE_TCB.  The complete MIB_TCPROW structure   //
// MUST BE SPECIFIED                                                        //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////
function SetTcpEntry(
    {IN} pTcpRow: PMIB_TCPROW 
    ): DWORD; stdcall;

function GetInterfaceInfo(
    {IN} pIfTable: PIP_INTERFACE_INFO;
    {OUT} dwOutBufLen: PULONG
    ): DWORD; stdcall;

function GetUniDirectionalAdapterInfo(
    {OUT} pIPIfInfo: PIP_UNIDIRECTIONAL_ADAPTER_ADDRESS;
    {OUT} dwOutBufLen: PULONG
    ): DWORD; stdcall;

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
// Gets the "best" outgoing interface for the specified destination address //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////
function GetBestInterface(
    {IN}  dwDestAddr: IPAddr;
    {OUT} pdwBestIfIndex: PDWORD
    ): DWORD; stdcall;

//////////////////////////////////////////////////////////////////////////////
//                                                                          //
// Gets the best (longest matching prefix) route for the given destination  //
// If the source address is also specified (i.e. is not 0x00000000), and    //
// there are multiple "best" routes to the given destination, the returned  //
// route will be one that goes out over the interface which has an address  //
// that matches the source address                                          //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////
function GetBestRoute(
    {IN}  dwDestAddr: DWORD;
    {IN}  dwSourceAddr: DWORD;
    {OUT} pBestRoute: PMIB_IPFORWARDROW
    ): DWORD; stdcall;

type
  lpOverlapped = POverlapped;

function NotifyAddrChange(
    {OUT} Handle: PHANDLE;
    {IN}  overlapped: LPOVERLAPPED
    ): DWORD; stdcall;

function NotifyRouteChange(
    {OUT} Handle: PHANDLE;
    {IN}  overlapped: LPOVERLAPPED
    ): DWORD; stdcall;

function GetAdapterIndex(
    {IN}  AdapterName: LPWSTR;
    {OUT} IfIndex: PULONG
    ): DWORD; stdcall;

function AddIPAddress(
    Address: IPAddr;
    IpMask: IPMask;
    IfIndex: DWORD;
    NTEContext: PULONG;
    NTEInstance: PULONG
    ): DWORD; stdcall;

function DeleteIPAddress(
    NTEContext: ULONG
    ): DWORD; stdcall;

function GetNetworkParams(
    pFixedInfo: PFIXED_INFO;
    pOutBufLen: PULONG
    ): DWORD; stdcall;

function GetAdaptersInfo(
    pAdapterInfo: PIP_ADAPTER_INFO;
    pOutBufLen: PULONG
    ): DWORD; stdcall;

//
// The following functions require Winsock2.
//

function GetAdaptersAddresses(
    Family: ULONG;
    Flags: DWORD;
    Reserved: PVOID;
    pAdapterAddresses: PIP_ADAPTER_ADDRESSES;
    pOutBufLen: PULONG
    ): DWORD; stdcall;


function GetPerAdapterInfo(
    IfIndex: ULONG;
    pPerAdapterInfo: PIP_PER_ADAPTER_INFO;
    pOutBufLen: PULONG
    ): DWORD; stdcall;

function IpReleaseAddress(
    AdapterInfo: PIP_ADAPTER_INDEX_MAP
    ): DWORD; stdcall;


function IpRenewAddress(
    AdapterInfo: PIP_ADAPTER_INDEX_MAP
    ): DWORD; stdcall;

function SendARP(
    DestIP: IPAddr;
    SrcIP: IPAddr;
    pMacAddr: PULONG;
    PhyAddrLen: PULONG
    ): DWORD; stdcall;

function GetRTTAndHopCount(
    DestIpAddress: IPAddr;
    HopCount: PULONG;
    MaxHops: ULONG;
    RTT: PULONG
    ): BOOL; stdcall;

function GetFriendlyIfIndex(
    IfIndex: DWORD
    ): DWORD; stdcall;

function EnableRouter(
    pHandle: PHANDLE;
    pOverlapped: POVERLAPPED
    ): DWORD; stdcall;

function UnenableRouter(
    pOverlapped: POVERLAPPED;
    lpdwEnableCount: LPDWORD
    ): DWORD; stdcall;

function DisableMediaSense(
    pHandle: PHANDLE;
    pOverLapped: POVERLAPPED
    ): DWORD; stdcall;

function RestoreMediaSense(
    pOverlapped: POVERLAPPED;
    lpdwEnableCount: LPDWORD
    ): DWORD; stdcall;

function GetIpErrorString(
    {IN}     ErrorCode: IP_STATUS;
    {OUT}    Buffer: PWCHAR;
    {IN OUT} Size: PDWORD
    ): DWORD; stdcall;

{$ELSE }

// -- non-statically linked versions --
function GetAdaptersInfo(pAdapterInfo: PIP_ADAPTER_INFO; pOutBufLen: PULONG): DWORD;
{*
        @param IfIndex interface index
        @return newly allocated info or nil (use GetLastError() to see what went wrong)
}
function GetPerAdapterInfo(IfIndex: ULONG): PIP_PER_ADAPTER_INFO;
{*
        @return newly allocated table or nil (use GetLastError() to see what went wrong)
}
function GetIfTable(bOrder: BOOL): PMIB_IFTABLE;


{$ENDIF IPHLPAPI_STATICLINK }


implementation


uses
  unaUtils
{$IFDEF IPHLPAPI_NICEMACPROC }
  , nb30
{$ENDIF IPHLPAPI_NICEMACPROC }
  ;

const
  iphlpapi  = 'iphlpapi.dll';

{$IFDEF IPHLPAPI_STATICLINK }
{$ELSE}

type
  proc_GetAdaptersInfo = function(pAdapterInfo: PIP_ADAPTER_INFO; pOutBufLen: PULONG): DWORD; stdcall;
  proc_GetPerAdapterInfo = function(IfIndex: ULONG; pPerAdapterInfo: PIP_PER_ADAPTER_INFO; pOutBufLen: PULONG): DWORD; stdcall;
  proc_GetIfTable = function({OUT} pIfTable: PMIB_IFTABLE; {IN OUT} pdwSize: PULONG; {IN} bOrder: BOOL): DWORD; stdcall;

var
  g_ipModule: hModule = 0;
  gp_GAI: proc_GetAdaptersInfo = nil;
  gp_GPAI: proc_GetPerAdapterInfo = nil;
  gp_GIT: proc_GetIfTable = nil;

// --  --
function loadGP(const gpname: string): pointer;
begin
  if (0 = g_ipModule) then begin
    // try to load the iphlpapi.dll
    g_ipModule := loadLibrary(iphlpapi);
    if (0 = g_ipModule) then
      g_ipModule := hModule(-1);
  end;
  //
  if (hModule(-1) <> g_ipModule) then
    result := getProcAddress(g_ipModule, pChar(gpname))
  else
    result := nil;
end;

// --  --
function GetAdaptersInfo(pAdapterInfo: PIP_ADAPTER_INFO; pOutBufLen: PULONG): DWORD;
begin
  if (not assigned(gp_GAI)) then
    gp_GAI := loadGP('GetAdaptersInfo');
  //
  if (assigned(gp_GAI)) then
    result := gp_GAI(pAdapterInfo, pOutBufLen)
  else
    result := ERROR_NOT_SUPPORTED;
end;

// --  --
function GetPerAdapterInfo(IfIndex: ULONG): PIP_PER_ADAPTER_INFO;
var
  info: PIP_PER_ADAPTER_INFO;
  sz: ULONG;
  res: DWORD;
begin
  if (not assigned(gp_GPAI)) then
    gp_GPAI := loadGP('GetPerAdapterInfo');
  //
  result := nil;
  if (assigned(gp_GPAI)) then begin
    //
    sz := sizeof(IP_PER_ADAPTER_INFO);
    info := malloc(sz);
    res := gp_GPAI(IfIndex, info, @sz);
    if (ERROR_BUFFER_OVERFLOW = res) then begin
      //
      mrealloc(info, sz);
      res := gp_GPAI(IfIndex, info, @sz);
      if (NO_ERROR = res) then
        result := info
      else
        SetLastError(res);
    end
    else
      if (NO_ERROR = res) then
        result := info
      else
        SetLastError(res);
  end
  else
    SetLastError(ERROR_INVALID_FUNCTION);
end;

// --  --
function GetIfTable(bOrder: BOOL): PMIB_IFTABLE;
var
  table: PMIB_IFTABLE;
  pdwSize: ULONG;
  res: DWORD;
begin
  if (not assigned(gp_GIT)) then
    gp_GIT := loadGP('GetIfTable');
  //
  result := nil;
  if (assigned(gp_GIT)) then begin
    //
    pdwSize := sizeof(MIB_IFTABLE);
    table := malloc(pdwSize);
    res := gp_GIT(table, @pdwSize, bOrder);
    if (ERROR_INSUFFICIENT_BUFFER = res) then begin
      //
      mrealloc(table, pdwSize);
      res := gp_GIT(table, @pdwSize, bOrder);
      if (NO_ERROR = res) then
        result := table
      else
        SetLastError(res);
    end
    else
      if (NO_ERROR = res) then
        result := table
      else
        SetLastError(res);
  end
  else
    SetLastError(ERROR_INVALID_FUNCTION);
end;


{$ENDIF IPHLPAPI_STATICLINK }

{$IFDEF IPHLPAPI_NICEMACPROC }

type
  pASTAT = ^ASTAT;
  ASTAT = packed record
    //
    adapt: tADAPTERSTATUS;
    NameBuff: array[0..29] of TNameBuffer;
  end;

// --  --
function try_NetBios(): string;
var
  Adapter: ASTAT;
  ncb: tNCB;
  uRetCode: aChar;
  i: int;
begin
  // reset the adapter
  fillChar(ncb, sizeof(ncb), #0);
  ncb.ncb_command := char(NCBRESET);
  ncb.ncb_lana_num := char(0);
  //
  Netbios(@ncb);
  //
  // get ASTAT
  fillChar(ncb, sizeof(ncb), #0);
  ncb.ncb_command := char(NCBASTAT);
  ncb.ncb_lana_num := char(0);

  ncb.ncb_callname := '*               ';
  ncb.ncb_buffer := paChar(@Adapter);
  ncb.ncb_length := sizeof(Adapter);

  uRetCode := Netbios(@ncb);
  //  printf( "The NCBASTAT return code is: 0x%x \n", uRetCode );

  if (#0 = uRetCode) then begin
    {
	printf( "The Ethernet Number is: %02x%02x%02x%02x%02x%02x\n",
		Adapter.adapt.adapter_address[0],
		Adapter.adapt.adapter_address[1],
		Adapter.adapt.adapter_address[2],
		Adapter.adapt.adapter_address[3],
		Adapter.adapt.adapter_address[4],
		Adapter.adapt.adapter_address[5] );
    }
    for i := 0 to 5 do
      result := result + adjust(int2str(byte(Adapter.adapt.adapter_address[i]), 16), 2, '0')
  end
  else
    result := '';
end;

// --  --
function iph_getAdapterMAC(index: int): string;

  function getInfo(adapter: PIP_ADAPTER_INFO): string;
  var
    i: int;
    ok: bool;
    c: char;
  begin
    if (0 < adapter.AddressLength) then
      //
      for i := 0 to adapter.AddressLength - 1 do
	result := result + adjust(int2str(byte(paChar(@adapter.Address)[i]), 16), 2, '0')
      else
	result := string(adapter.AdapterName);
    //
    ok := false;
    for c := '1' to '9' do
      if (1 <= pos(c, result)) then begin
	ok := true;
	break;
      end;
    //
    if (not ok) then
      for c := 'A' to 'E' do
	if (1 <= pos(c, result)) then begin
	  ok := true;
	  break;
	end;
    //
    if (not ok) then
      result := '';
  end;

var
  n: ULONG;
  res: DWORD;
  adapters: PIP_ADAPTER_INFO;
  adapter: PIP_ADAPTER_INFO;
  lastHope: PIP_ADAPTER_INFO;
begin
  result := '';
  //
  n := sizeOf(adapters^);
  adapters := malloc(n);
  //
  res := GetAdaptersInfo(adapters, @n);
  if (ERROR_BUFFER_OVERFLOW = res) then begin
    //
    mrealloc(adapters, n);
    res := GetAdaptersInfo(adapters, @n);
  end;
  //
  lastHope := nil;
  case (res) of

    ERROR_SUCCESS: begin
      //
      adapter := adapters;
      while (nil <> adapter) do begin
	//
	case (adapter.aType) of

	  MIB_IF_TYPE_OTHER:
	    lastHope := adapter;

	  MIB_IF_TYPE_ETHERNET,
	  MIB_IF_TYPE_TOKENRING,
	  MIB_IF_TYPE_FDDI: begin
	    result := getInfo(adapter);
	    //
	    if ('' <> result) then
	      break;
	  end;

	  else
	    // go to next adapter
	end;

	adapter := adapter.Next;
      end;
      //
      if (('' = result) and (nil <> lastHope)) then
	result := getInfo(lastHope);
    end;

    ERROR_NOT_SUPPORTED:
      result := try_NetBios();

    else
      result := '';

  end;
  //
  mrealloc(adapters);
end;

function getCPUID(): string;
begin
end;

{$ENDIF IPHLPAPI_NICEMACPROC }

{$IFDEF IPHLPAPI_STATICLINK }

function GetNumberOfInterfaces; external iphlpapi;
function GetIfEntry; external iphlpapi;
function GetIfTable; external iphlpapi;
function GetIpAddrTable; external iphlpapi;
function GetIpNetTable; external iphlpapi;
function GetIpForwardTable; external iphlpapi;
function GetTcpTable; external iphlpapi;
function GetUdpTable; external iphlpapi;
function GetIpStatistics; external iphlpapi;
function GetIpStatisticsEx; external iphlpapi;
function GetIcmpStatistics; external iphlpapi;
function GetTcpStatistics; external iphlpapi;
function GetTcpStatisticsEx; external iphlpapi;
function GetUdpStatistics; external iphlpapi;
function GetUdpStatisticsEx; external iphlpapi;
function SetIfEntry; external iphlpapi;
function CreateIpForwardEntry; external iphlpapi;
function SetIpForwardEntry; external iphlpapi;
function DeleteIpForwardEntry; external iphlpapi;
function SetIpStatistics; external iphlpapi;
function SetIpTTL; external iphlpapi;
function CreateIpNetEntry; external iphlpapi;
function SetIpNetEntry; external iphlpapi;
function DeleteIpNetEntry; external iphlpapi;
function FlushIpNetTable; external iphlpapi;
function CreateProxyArpEntry; external iphlpapi;
function DeleteProxyArpEntry; external iphlpapi;
function SetTcpEntry; external iphlpapi;
function GetInterfaceInfo; external iphlpapi;
function GetUniDirectionalAdapterInfo; external iphlpapi;
function GetBestInterface; external iphlpapi;
function GetBestRoute; external iphlpapi;
function NotifyAddrChange; external iphlpapi;
function NotifyRouteChange; external iphlpapi;
function GetAdapterIndex; external iphlpapi;
function AddIPAddress; external iphlpapi;
function DeleteIPAddress; external iphlpapi;
function GetNetworkParams; external iphlpapi;
function GetAdaptersInfo; external iphlpapi;
function GetAdaptersAddresses; external iphlpapi;
function GetPerAdapterInfo; external iphlpapi;
function IpReleaseAddress; external iphlpapi;
function IpRenewAddress; external iphlpapi;
function SendARP; external iphlpapi;
function GetRTTAndHopCount; external iphlpapi;
function GetFriendlyIfIndex; external iphlpapi;
function EnableRouter; external iphlpapi;
function UnenableRouter; external iphlpapi;
function DisableMediaSense; external iphlpapi;
function RestoreMediaSense; external iphlpapi;
function GetIpErrorString; external iphlpapi;

{$ENDIF IPHLPAPI_STATICLINK }

initialization

finalization

{$IFDEF IPHLPAPI_STATICLINK }
{$ELSE}

  gp_GAI := nil;
  gp_GPAI := nil;
  //
  if ((0 <> g_ipModule) and (hModule(-1) <> g_ipModule)) then begin
    //
    freeLibrary(g_ipModule);
    g_ipModule := 0;
  end;

{$ENDIF IPHLPAPI_STATICLINK }

end.

