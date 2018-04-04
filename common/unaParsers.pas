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

	  unaParsers.pas

	  * Object Pascal parser
	  * HTTP-like protocols parser
	  * SDP parser

	----------------------------------------------
	  Copyright (c) 2002-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 03 Apr 2002

	  modified by:
		Lake, Apr 2002
		Lake, Apr-Jul 2009
		Lake, Feb 2010

	----------------------------------------------
*)

{$I unaDef.inc }

{*

  * Object Pascal parser
  * HTTP-like protocols parser

  @Author Lake

  Version 2.5.2009.04 + HTTP-like protocols parser

  Version 2.5.2009.04 + SDP parser

}

{$IFDEF DEBUG }
  {x $DEFINE UNA_OP_CHECK_HTTPP }		// internal, do not define
{$ENDIF DEBUG }

unit
  unaParsers;

interface

uses
  Windows, unaTypes, unaClasses;

type

  //
  unaOPTokenType = (
    unaoptEOF,
    //
    unaoptIdentifier,
    unaoptNumber,
    unaoptChar,
    unaoptString,
    unaoptPunctuationMark,
    unaoptAssigment,
    unaoptComment,
    //
    unaoptError
  );


  {*
	  unaObjectPascalToken
  }
  unaObjectPascalToken = class(unaObject)
  private
    f_value: wString;
    f_type: unaOPTokenType;
    //
    procedure addChar(c: aChar);
  public
    function get(def: byte): byte; overload;
    function get(def: char): char; overload;
    //function get(def: WideChar): WideChar; overload;
    function get(def: int): int; overload;
    function get(def: unsigned): unsigned; overload;
    function get(const def: string): string; overload;
    //function get(const def: WideString): WideString; overload;
    function get(def: double): double; overload;
    function isToken(const value: string): bool; overload;
    //function isToken(const value: wString): bool; overload;
    //
    property tokenType: unaOPTokenType read f_type write f_type;
    property value: wString read f_value;
  end;


  {*
    unaObjectPascalParser
  }
  unaObjectPascalParser = class(unaObject)
  private
    f_lineNum: unsigned;
    f_isAnsiText: bool;
    //
    f_stream: unaAbstractStream;
    f_token: unaObjectPascalToken;
    f_lastToken: unaObjectPascalToken;
  public
    constructor createFromFile(const fileName: wString; isAnsiText: bool);
    constructor create(const script: string); overload;
    {$IFDEF __BEFORE_DC__ }
      {$IFDEF __BEFORE_D6__ }
      {$ELSE }
      constructor create(const script: wString); overload;
      {$ENDIF __BEFORE_D6__ }
    {$ELSE }
    constructor create(const script: aString); overload;
    {$ENDIF __BEFORE_DC__ }
    procedure AfterConstruction(); override;
    destructor Destroy(); override;
    //
    function nextToken(token: unaObjectPascalToken = nil): bool;
    function getLineNum(): unsigned;
    //
    property token: unaObjectPascalToken read f_lastToken;
  end;


  {*
	HTTP-like protocols parser
  }
  unaHTTPparser = class(unaObject)
  private
    f_buf: paChar;
    f_bufSize: int;
    f_headerSize: int;
    f_headerDelimiter: char;
    //
    function getHC(): bool;
    //
    function getNextLine(var offs: int; out line: wString): bool;
    function getHeaderLine(index: int): wString;
  protected
    {*
    	//
    }
    procedure setHeaderDelimiter(newDelimiter: char);
    {*
	//
    }
    procedure doCleanup(); virtual;
  public
    {*
	Initializes instance.
    }
    constructor create();
    {*
	Cleans up the instance.
    }
    procedure BeforeDestruction(); override;
    {*
	Cleans internal buffers and prepares parser for new data.
    }
    procedure cleanup();
    {*
	Drops complete Request/Response with payload (if any).
    }
    procedure dropIfComplete(defaultCL: int = -1);
    {*
	Feeds parser with new portion of data.

	@param data Pointer to new portion of text.
	@param len Size of data in bytes.
    }
    procedure feed(data: pointer; len: int);
    {*
	@returns requested method (if any).
    }
    function getReqMethod(): string;
    {*
	@returns requested URI (if any).
    }
    function getReqURI(): string;
    {*
	@returns request protocol version (if any).
    }
    function getReqProtoVersion(): string;
    {*
	@returns response protocol version (if any).
    }
    function getRespProtoVersion(): string;
    {*
	@returns response code (if any).
    }
    function getRespCode(): int;
    {*
	@returns response code as string (if provided in response).
    }
    function getRespCodeString(): string;
    {*
	@param headerName name of header
	@return specified header value
    }
    function getHeaderValue(const headerName: string; trim: bool = false): string; overload;
    {*
	@param index header index (starting from 0)
	@return specified header value by index.
    }
    function getHeaderValue(index: int; trim: bool = false): string; overload;
    {*
	@return number of headers.
    }
    function getHeaderCount(): int;
    {*
	@return full header.
    }
    function getFullHeader(): aString;
    {*
	@param index header index (starting from 0)
	@return specified header name.
    }
    function getHeaderName(index: int): string;
    {*
	@return payload data (if any).
    }
    function getPayload(): aString;
    {*
	@return current payload size.
    }
    function getPayloadSize(): int;
    {*
	True if complete payload was received.

	@param connected True if socket is still connected
	@param defaultCL Default value if Contnent-Length header is missing. Some protocols (like RTSP) require this to be 0 by default.
	@return True if payload is "completely" present: [Contnent-Length=0 or missing and default is 0 or default is -1 and connection is closed | or at least Contnent-Length bytes of payload is present]
    }
    function getPayloadComplete(connected: bool; defaultCL: int = -1): bool;
    //
    {*
	True if complete header was received.
    }
    property headerComplete: bool read getHC;
    {*
	Returns header size (valid when headerComplete is true).
    }
    property headerSize: int read f_headerSize;
    {*
    	Returns data size, that is size of data written to parser so far, inlcuding header.
    }
    property dataSize: int read f_bufSize;
    {*
    	RAW data access.
    }
    property data: paChar read f_buf;
  end;


  {*
	SDP Connection Info
  }
  punaSDPConnectionInfo = ^unaSDPConnectionInfo;
  unaSDPConnectionInfo = packed record
    //
    r_netType: string;
    r_addrType: string;
    r_connAddr: string;
    r_ttl: int32;			// -1 means not specified
    r_numberOfAddresses: int32;		// default is 1
  end;


  {*
	SDP Media Description
  }
  punaSDPMediaDescription = ^unaSDPMediaDescription;
  unaSDPMediaDescription = packed record
    //
// Currently defined media are "audio", "video", "text", "application", and "message", although this list may be extended in the future.
    r_type: string;
// Could be '0'.
    r_port: string;
// Could be 'udp', 'RTP/AVP' or 'RTP/SAVP' or 'TCP/RTP/AVP'.
    r_proto: string;
// First format index
    r_format: int;
    //
// absolute or relative URL
    r_control: string;
// rtmap attribute
    r_rtpmap: string;
// fmtp attribute
    r_fmtp: string;
    //
// media title
    r_i: string;
// connection information -- optional if included at session level
    r_c: unaSDPConnectionInfo;
// zero or more bandwidth information lines
    r_b: string;
// encryption key
    r_k: string;
// zero or more media attribute lines
    r_a: string;	        
  end;


  {*
	Originator and session identifier
  }
  punaSDPSessionInfo = ^unaSDPSessionInfo;
  unaSDPSessionInfo = packed record
    //
// is the user's login on the originating host, or it is "-" if the originating host does not support the concept of user IDs.
    r_username,				
// is a numeric string that forms a globally unique identifier for the session
    r_sessid,				
// version number for this session description
    r_sessversion,			
// Initially "IN" is defined to have the meaning "Internet"
    r_nettype,				
// Initially "IP4" and "IP6" are defined
    r_addrtype,				
// is the address of the machine from which the session was created
    r_unicastAddress: string;		
  end;


  {*
    unaSDPMDList
  }
  unaSDPMDList = class(unaRecordList)
  protected
    procedure releaseItem(index: int; doFree: unsigned); override;
  end;


  {*
	Basic SDP parser
  }
  unaSDPParser = class(unaHTTPparser)
  private
    f_k: string;
    f_i: string;
    f_o: punaSDPSessionInfo;
    f_b: string;
    f_c: unaSDPConnectionInfo;
    f_e: string;
    f_z: string;
    f_s: string;
    f_p: string;
    f_v: int;
    f_t: string;
    f_u: string;
    f_a: string;
    //
    f_md: unaSDPMDList;
    //
    function parseConnInfo(const data: string; var ci: unaSDPConnectionInfo): bool;
    procedure parse();
    function getCI: punaSDPConnectionInfo;
  protected
    procedure doCleanup(); override;
  public
    {*
	Creates SDP parser.

	@param response Optional HTTP/RTSP response with SDP payload received from remote side.
    }
    constructor create(response: unaHTTPparser = nil);
    {*
    }
    procedure BeforeDestruction(); override;
    {*
	Assigns SDP data from a HTTP/RTSP response with SDP payload received from remote side.
    }
    procedure applyPayload(response: unaHTTPparser); overload;
    {*
	Assigns SDP data from a sting.
    }
    procedure applyPayload(const payload: aString); overload;
    {*
	Returns number of media descriptions.
    }
    function getMDCount(): int;
    {*
	Returns media description by index.
    }
    function getMD(index: int): punaSDPMediaDescription;
    //
// protocol version
    property v: int read f_v;			
// originator and session identifier
    property o: punaSDPSessionInfo read f_o;	
// session name
    property s: string read f_s;		
// session information
    property i: string read f_i;		
// URI of description
    property u: string read f_u;		
// email address
    property e: string read f_e;		
// phone number
    property p: string read f_p;		
// connection information -- not required if included in all media
    property c: punaSDPConnectionInfo read getCI;		
// zero or more bandwidth information lines
    property b: string read f_b;		
// One or more time descriptions (time the session is active)
    property t: string read f_t;		
// time zone adjustments
    property z: string read f_z;		
// encryption key
    property k: string read f_k;		
// global session attributes
    property a: string read f_a;		
  end;


{$IFDEF UNA_OP_CHECK_HTTPP }
procedure checkHTTPp();
{$ENDIF UNA_OP_CHECK_HTTPP }

implementation


uses
  unaUtils;

{ unaObjectPascalToken }

// --  --
procedure unaObjectPascalToken.addChar(c: aChar);
begin
  f_value := f_value + wideChar(c);
end;

// --  --
function unaObjectPascalToken.get(def: byte): byte;
begin
  result := str2intByte(f_value, def);
end;

// --  --
function unaObjectPascalToken.get(def: char): char;
begin
  if (0 < length(f_value)) then
    result := char(f_value[1])
  else
    result := def;
end;

// --  --
function unaObjectPascalToken.get(def: double): double;
begin
  // to do
  result := 0;
end;

// --  --
function unaObjectPascalToken.get(def: int): int;
begin
  result := str2intInt(f_value, def);
end;

// --  --
function unaObjectPascalToken.get(const def: string): string;
begin
  result := f_value;
end;

// --  --
function unaObjectPascalToken.get(def: unsigned): unsigned;
begin
  result := str2intUnsigned(f_value, def);
end;

// --  --
//function unaObjectPascalToken.get(def: WideChar): WideChar;
//begin
//  if (0 < length(f_value)) then
//    result := f_value[1]
//  else
//    result := def;
//end;

// --  --
//function unaObjectPascalToken.get(const def: WideString): WideString;
//begin
//  result := f_value;
//end;

// --  --
function unaObjectPascalToken.isToken(const value: string): bool;
begin
  result := sameString(f_value, value, true);
end;

// --  --
//function unaObjectPascalToken.isToken(const value: WideString): bool;
//begin
//  result := (0 = compareStr(lowerCase(f_value), lowerCase(value)));
//end;


{ unaObjectPascalParser }

// --  --
procedure unaObjectPascalParser.afterConstruction();
begin
  inherited;
  //
  f_token := unaObjectPascalToken.create();
end;

// --  --
constructor unaObjectPascalParser.createFromFile(const fileName: wString; isAnsiText: bool);
begin
  inherited create();
  //
  f_stream := unaFileStream.createStream(fileName, GENERIC_READ);
  f_isAnsiText := isAnsiText;
end;

// --  --
constructor unaObjectPascalParser.create(const script: string);
begin
  f_stream := unaMemoryStream.create();
  f_stream.write(aString(script));
  f_isAnsiText := false;
end;

{$IFDEF __BEFORE_DC__ }

{$IFDEF __BEFORE_D6__ }
{$ELSE }

// --  --
constructor unaObjectPascalParser.create(const script: wString);
begin
  f_stream := unaMemoryStream.create();
  f_stream.write(aString(script));
  f_isAnsiText := true;
end;

{$ENDIF __BEFORE_D6__ }

{$ELSE }

// --  --
constructor unaObjectPascalParser.create(const script: aString);
begin
  f_stream := unaMemoryStream.create();
  f_stream.write(script);
  f_isAnsiText := true;
end;

{$ENDIF __BEFORE_DC__ }

// --  --
destructor unaObjectPascalParser.destroy();
begin
  inherited;
  //
  freeAndNil(f_token);
  freeAndNil(f_stream);
end;

// --  --
function unaObjectPascalParser.getLineNum(): unsigned;
begin
  result := f_lineNum + 1;
end;

// --  --
function unaObjectPascalParser.nextToken(token: unaObjectPascalToken): bool;
var
  c: array[0..1] of AnsiChar;
  mode: byte;
  noAdd: bool;
begin
  if (nil = token) then
    token := f_token;
  //
  token.f_type := unaoptEOF;
  token.f_value := '';
  //
  mode := 0;	// white space
  //
  while (1 <= f_stream.getAvailableSize()) do begin
    //
    f_stream.read(@c, 2, false);
    noAdd := false;
    if (#10 = c[0]) then
      inc(f_lineNum);
    //
    case (mode) of

      0: begin	// "white space" mode

	case (c[0]) of

	  'A'..'Z',
	  'a'..'z',
	  '_': begin
            //
	    mode := 1;		// identifier
	    token.f_type := unaoptIdentifier;
	  end;

	  '/': begin
            //
	    if ('/' = c[1]) then begin
              //
	      mode := 2;	// "//" comment
	      token.f_type := unaoptComment;
	    end
	    else begin
              //
	      mode := 10;	// end of parse
	      token.f_type := unaoptPunctuationMark;
	    end;
	  end;

	  '(': begin
            //
	    if ('*' = c[1]) then begin
              //
	      mode := 3;	// "(*" comment
	      token.f_type := unaoptComment;
	    end
	    else begin
	      mode := 10;	// end of parse
	      token.f_type := unaoptPunctuationMark;
	    end;
	  end;

	  '{': begin
	    mode := 4;		// start of "{" comment
	    token.f_type := unaoptComment;
	  end;

	  '0'..'9': begin
	    mode := 5;	// start of number
	    token.f_type := unaoptNumber;
	  end;

	  ':' : begin
            //
	    if ('=' = c[1]) then begin
              //
	      f_stream.read(@c, 2);
	      token.addChar(c[0]);
	      token.addChar(c[1]);
	      mode := 11;	// assigment
	      token.f_type := unaoptAssigment;
	    end
	    else begin
              //
	      mode := 10;	// end of parse
	      token.f_type := unaoptPunctuationMark;
	    end;
	  end;

	  '#': begin
            //
	    if (c[1] in ['0'..'9']) then begin
              //
	      mode := 7;	// start of # AnsiChar
	      token.f_type := unaoptChar;
	    end
	    else begin
              //
	      mode := 10;	// end of parse
	      token.f_type := unaoptError;
	    end;
	  end;

	  '''': begin
	    noAdd := true;	// do not add '
	    mode := 8;		// start of char or string
	    token.f_type := unaoptString;
	  end;

	  #0..#32:
	    mode := 0;		// white space

	  '"', #128..#255: begin
	    mode := 10;
	    token.f_type := unaoptError;	// invalid symbol
	  end;

	  else begin
	    mode := 10;		// punctuation mark
	    token.f_type := unaoptPunctuationMark;
	  end;

	end; // end case (c), mode = 0

      end;	// mode 0

      1: begin	// "identifier" mode
	case (c[0]) of

	  'a'..'z',
	  'A'..'Z',
	  '0'..'9',
	  '_':	;	// continue

	  else
	    mode := 11;	// stop

	end; // end case (c[0]), mode = 1
      end;	// mode 1

      2: begin	// '"//" comment' mode
	case (c[0]) of

	  #13, #10:
	    mode := 11;	// stop

	end; // end case (c[0]), mode = 2
      end;	// mode 2

      3: begin	// '"(*" comment' mode
	case (c[0]) of

	  '*':
	    if (')' = c[1]) then begin
              //
	      f_stream.read(@c, 1);
	      token.addChar(c[0]);
	      mode := 10;	// stop
	    end;

	end; // end case (c[0]), mode = 3
      end;	// mode 3

      4: begin	// '"{" comment' mode
	case (c[0]) of

	  '}':
	    mode := 10;	// stop

	end; // end case (c[0]), mode = 4
      end;	// mode 4

      5: begin	// "number" mode
	case (c[0]) of

	  '0'..'9': ;	// ok to continue

	  '.':
	    if ('.' = c[1]) then	// .. sign follows digit
	      mode := 11	// stop now
	    else begin
              //
	      if (c[1] in ['0'..'9', 'e', 'E']) then begin
                //
		if (0 > pos('.', token.value)) then
		  // ok to continue
		else begin
		  // have found two dots - indicate error
		  token.f_type := unaoptError;
		  mode := 10;	// stop
		end
              end
	      else
		mode := 10;	// stop now - end of digit
            end;

	  'e', 'E': begin
            //
	    case (c[1]) of
              //
	      '-', '+': begin
                //
		f_stream.read(@c, 1);	// add 'E'
		token.addChar(c[0]);
	      end;
	    end;
            //
	    mode := 6;	// switch do "float number" mode
	  end;

	  else
	    mode := 11;	// stop

	end; // end case (c[0]), mode = 5
      end;	// mode 5

      6: begin	// "float number" mode
        //
	case (c[0]) of

	  '0'..'9': ;	// ok to continue

	  else
	    mode := 11;	// stop

	end; // end case (c[0]), mode = 6
      end;	// mode 6

      7: begin	// "# AnsiChar" mode

	case (c[0]) of

	  '0'..'9': ;	// ok to continue

	  else
	    mode := 11;	// stop

	end; // end case (c[0]), mode = 7
      end;	// mode 7

      8: begin	// "" mode
        //
	case (c[0]) of

	  '''': begin
            //
	    noAdd := true;
	    if ('''' = c[1]) then	// this is double '' - skip it
	      f_stream.read(@c, 1)
	    else
	      mode := 10;	// end of string - stop
	  end;

	  #13, #10: // unterminated string - indicate error
	    mode := 10;

	end; // end case (c[0]), mode = 8
      end;	// mode 8

    end;  // end of case
    //
    if (11 <> mode) then begin
      //
      f_stream.read(@c, 1);
      if (not noAdd and (0 <> mode)) then
	token.addChar(c[0]);
    end;
    //
    if (10 <= mode) then
      break;
  end;
  //
  result := (unaoptError <> token.f_type);
  f_lastToken := token;
end;


{ unaHTTPparser }

// --  --
procedure unaHTTPparser.BeforeDestruction();
begin
  inherited;
  //
  cleanup();
end;

// --  --
procedure unaHTTPparser.cleanup();
begin
  doCleanup();
end;

// --  --
constructor unaHTTPparser.create();
begin
  f_headerDelimiter := ':';
  //
  inherited;
end;

// --  --
procedure unaHTTPparser.doCleanup();
begin
  f_bufSize := 0;
  f_headerSize := 0;
  mrealloc(f_buf);
end;

// --  --
procedure unaHTTPparser.dropIfComplete(defaultCL: int);
var
  len, lenSave: int;
begin
  if (headerComplete and getPayloadComplete(true, defaultCL)) then begin
    //
    len := f_headerSize + getPayloadSize();
    lenSave := f_bufSize - len;
    if (0 < lenSave) then begin
      //
      f_buf := malloc(lenSave, @pArray(f_buf)[len]);
      f_bufSize := lenSave;
      f_headerSize := 0;
    end
    else
      cleanup();
  end;
end;

// --  --
procedure unaHTTPparser.feed(data: pointer; len: int);
var
  oldPos: int;
begin
  if ((nil <> data) and (0 < len)) then begin
    //
    oldPos := f_bufSize;
    inc(f_bufSize, len);
    mrealloc(f_buf, f_bufSize);
    //
    move(data^, f_buf[oldPos], len);
  end;
end;

// --  --
function unaHTTPparser.getFullHeader(): aString;
begin
  setLength(result, f_headerSize);
  if (0 < f_headerSize) then
    move(f_buf[0], result[1], f_headerSize);
end;

// --  --
function unaHTTPparser.getHC(): bool;
var
  doubleCRLF: uint32;
  minPos, posAA, posDD, posADAD: pointer;
  len: int;
begin
  if (0 = f_headerSize) then begin
    //
    doubleCRLF := $0A0A;
    posAA := mscanbuf(pointer(f_buf), f_bufSize, @doubleCRLF, 2);
    //
    doubleCRLF := $0A0D0A0D;
    posADAD := mscanbuf(pointer(f_buf), f_bufSize, @doubleCRLF, 4);
    //
    doubleCRLF := $0D0D;
    posDD := mscanbuf(pointer(f_buf), f_bufSize, @doubleCRLF, 2);
    //
    if (0 <> (int(posAA) or int(posADAD) or int(posDD))) then begin
      //
      minPos := posAA;
      len := 2;
      if ( (nil = minPos) or ((nil <> posADAD) and (int(minPos) > int(posADAD))) ) then begin
	//
	minPos := posADAD;
	len := 4;
      end;
      //
      if ((nil = minPos) or ((nil <> posDD) and (int(minPos) > int(posDD))) ) then begin
	//
	minPos := posDD;
	len := 2;
      end;
      //
      f_headerSize := int(minPos) - int(f_buf) + len;
      result := true;
    end
    else
      result := false;
  end
  else
    result := true;
end;

// --  --
function unaHTTPparser.getHeaderCount(): int;
var
  offs: int;
  l: wString;
begin
  offs := 0;
  result := 0;
  while (getNextLine(offs, l)) do
    inc(result);
  //
  if (0 < result) then
    dec(result);
end;

// --  --
function unaHTTPparser.getHeaderLine(index: int): wString;
var
  offs: int;
begin
  offs := 0;
  if (getNextLine(offs, result)) then begin
    //
    result := '';
    while ((0 <= index) and (getNextLine(offs, result))) do
      dec(index);
  end
  else
    result := '';
end;

// --  --
function unaHTTPparser.getHeaderName(index: int): string;
var
  p: int;
begin
  result := getHeaderLine(index);
  p := pos(f_headerDelimiter, result);
  if (0 < p) then
    result := copy(result, 1, p - 1);
end;

// --  --
function unaHTTPparser.getHeaderValue(const headerName: string; trim: bool): string;
var
  index: int;
  hn: string;
begin
  index := 0;
  repeat
    //
    hn := getHeaderName(index);
    if (loCase(headerName) = loCase(hn)) then
      break
    else
      inc(index);
    //
  until ('' = hn);
  //
  if ('' <> hn) then
    result := getHeaderValue(index, trim);
end;

// --  --
function unaHTTPparser.getHeaderValue(index: int; trim: bool): string;
var
  p: int;
begin
  result := getHeaderLine(index);
  p := pos(f_headerDelimiter, result);
  if (0 < p) then
    result := copy(result, p + 1, maxInt);
  //
  if (trim) then
    result := trimS(result);
end;

// --  --
function unaHTTPparser.getNextLine(var offs: int; out line: wString): bool;
var
  o, ptr: pointer;
  CRLF: word;
  len: int;
  str: aString;
begin
  line := '';
  result := false;
  //
  if ((nil <> f_buf) and (0 <= offs) and (0 < f_bufSize - offs)) then begin
    //
    CRLF := $0A;
    len := 1;
    o := @pArray(f_buf)[offs];
    ptr := mscanb(o, f_bufSize - offs, CRLF);
    if (nil = ptr) then begin
      //
      CRLF := $0D;
      ptr := mscanb(o, f_bufSize - offs, CRLF);
    end;
    //
    if (nil <> ptr) then begin
      //
      inc(int(ptr), len);
      len := int(ptr) - int(o);
      if (0 < len) then begin
	//
	setLength(str, len);
	move(f_buf[offs], str[1], len);
	line := utf82utf16(trimS(str));
      end;
      //
      inc(offs, len);
      result := ('' <> trimS(line));
    end;
  end;
end;

// --  --
function unaHTTPparser.getPayload(): aString;
var
  len: int;
begin
  if (headerComplete) then begin
    //
    len := getPayloadSize();
    if (0 < len) then begin
      //
      setLength(result, len);
      move(f_buf[f_headerSize], result[1], len);
    end
    else
      result := '';
  end
  else
    result := '';
end;

// --  --
function unaHTTPparser.getPayloadSize(): int;
begin
  result := str2intInt(getHeaderValue('Content-Length'), -1);
  if (0 > result) then
    result := f_bufSize - f_headerSize
  else
    result := min(result, f_bufSize - f_headerSize);
end;

// --  --
function unaHTTPparser.getPayloadComplete(connected: bool; defaultCL: int): bool;
var
  len: int;
begin
  result := getHC();
  if (result) then begin
    //
    len := str2intInt(getHeaderValue('Content-Length'), defaultCL);
    if (0 <= len) then
      result := (len <= f_bufSize - f_headerSize)
    else
      result := not connected;
  end;
end;

// --  --
function unaHTTPparser.getReqMethod(): string;
var
  l: wString;
  p: int;
  offs: int;
begin
  result := '';
  offs := 0;
  if (getNextLine(offs, l)) then begin
    //
    p := pos(' ', l);
    if (0 < p) then
      result := copy(l, 1, p - 1);
  end;
end;

// --  --
function unaHTTPparser.getReqProtoVersion(): string;
var
  l: wString;
  p: int;
  offs: int;
begin
  result := '';
  offs := 0;
  if (getNextLine(offs, l)) then begin
    //
    p := pos(' ', l);
    if (0 < p) then begin
      //
      l := copy(l, p + 1, maxInt);
      p := pos(' ', l);
      if (0 < p) then 
	result := copy(l, p + 1, maxInt);
    end;
  end;
end;

// --  --
function unaHTTPparser.getReqURI(): string;
var
  l: wString;
  p: int;
  offs: int;
begin
  result := '';
  offs := 0;
  if (getNextLine(offs, l)) then begin
    //
    p := pos(' ', l);
    if (0 < p) then begin
      //
      l := copy(l, p + 1, maxInt);
      p := pos(' ', l);
      if (1 > p) then
	p := length(l) + 1;	// no message
      //
      if (0 < p) then
	result := copy(l, 1, p - 1);
    end;
  end;
end;

// --  --
function unaHTTPparser.getRespCode(): int;
begin
  result := str2intInt(getReqURI(), -1);
end;

// --  --
function unaHTTPparser.getRespCodeString(): string;
begin
  result := getReqProtoVersion();
end;

// --  --
function unaHTTPparser.getRespProtoVersion(): string;
begin
  result := getReqMethod();
end;

// --  --
procedure unaHTTPparser.setHeaderDelimiter(newDelimiter: char);
begin
  f_headerDelimiter := newDelimiter;
end;


{ unaSDPMDList }

// --  --
procedure unaSDPMDList.releaseItem(index: int; doFree: unsigned);
var
  md: punaSDPMediaDescription;
begin
  md := get(index);
  if (mapDoFree(doFree) and (nil <> md)) then begin
    //
    md.r_type := '';
    md.r_port := '';
    md.r_proto := '';
    md.r_control := '';
    md.r_rtpmap := '';
    md.r_fmtp := '';
    md.r_i := '';
    md.r_c.r_netType := '';
    md.r_c.r_addrType := '';
    md.r_c.r_connAddr := '';
    md.r_b := '';
    md.r_k := '';
    md.r_a := '';
  end;
  //
  inherited;
end;


{ unaSDPParser }

// --  --
procedure unaSDPParser.applyPayload(response: unaHTTPparser);
begin
  if ((nil <> response) and (response.getPayloadComplete(true))) then
    applyPayload(response.getPayload())
end;

// --  --
procedure unaSDPParser.applyPayload(const payload: aString);
var
  dummy: aString;
begin
  if (0 < length(payload)) then begin
    //
    cleanup();
    //
    dummy := 'DUMMY SDP HEADER'#13#10;	// makes HTTP parser happy
    feed(@dummy[1], length(dummy));
    feed(@payload[1], length(payload));
    if (1 > pos(#13#10#13#10, string(payload))) then begin
      //
      dummy := #13#10#13#10;
      feed(@dummy[1], length(dummy));
    end;
    //
    parse();
  end;
end;

// --  --
procedure unaSDPParser.BeforeDestruction();
begin
  inherited;
  //
  f_o.r_username := '';
  f_o.r_sessid := '';
  f_o.r_sessversion := '';
  f_o.r_nettype := '';
  f_o.r_addrtype := '';
  f_o.r_unicastAddress := '';
  mrealloc(f_o);
  //
  freeAndNil(f_md);
end;

// --  --
constructor unaSDPParser.create(response: unaHTTPparser);
begin
  f_o := malloc(sizeOf(unaSDPSessionInfo), true);
  f_md := unaSDPMDList.create();
  //
  inherited create();
  //
  setHeaderDelimiter('=');
  //
  applyPayload(response);
end;

// --  --
procedure unaSDPParser.doCleanup();
begin
  inherited;
  //
  f_md.clear();
end;

// --  --
function unaSDPParser.getCI(): punaSDPConnectionInfo;
begin
  result := @f_c;
end;

// --  --
function unaSDPParser.getMD(index: int): punaSDPMediaDescription;
begin
  result := f_md.get(index);
end;

// --  --
function unaSDPParser.getMDCount(): int;
begin
  result := f_md.count;
end;

// --  --
procedure unaSDPParser.parse();

  // --  --
  function nextToken(var value: string): string;
  var
    p: int;
  begin
    p := pos(' ', value);
    if (1 > p) then
      p := length(value) + 1;
    //
    if (0 < p) then begin
      //
      result := copy(value, 1, p - 1);
      value := copy(value, p + 1, maxInt);
    end
    else
      result := '';
  end;

var
  index: int;
  name, value: string;
  md: punaSDPMediaDescription;
  outofscope: bool;
begin
  f_md.clear();
  f_k := '';
  f_i := '';
  f_o.r_username := '';
  f_o.r_sessid := '';
  f_o.r_sessversion := '';
  f_o.r_nettype := '';
  f_o.r_addrtype := '';
  f_o.r_unicastAddress := '';
  f_b := '';
  f_c.r_netType := '';
  f_c.r_addrType := '';
  f_c.r_connAddr := '';
  f_c.r_ttl := -1;
  f_c.r_numberOfAddresses := 1;
  f_e := '';
  f_z := '';
  f_s := '';
  f_p := '';
  f_v := -1;
  f_t := '';
  f_u := '';
  f_a := '';
  //
  index := 0;
{
      Session description
         v=  (protocol version)
         o=  (originator and session identifier)
         s=  (session name)
         i=* (session information)
         u=* (URI of description)
         e=* (email address)
         p=* (phone number)
         c=* (connection information -- not required if included in
              all media)
	 b=* (zero or more bandwidth information lines)
	 One or more time descriptions ("t=" and "r=" lines; see below)
	 z=* (time zone adjustments)
	 k=* (encryption key)
	 a=* (zero or more session attribute lines)
	 Zero or more media descriptions

      Time description
	 t=  (time the session is active)
	 r=* (zero or more repeat times)

      Media description, if present
	 m=  (media name and transport address)
	 i=* (media title)
	 c=* (connection information -- optional if included at
	      session level)
	 b=* (zero or more bandwidth information lines)
	 k=* (encryption key)
	 a=* (zero or more media attribute lines)

}
  // v=0
  if ('v' <> getHeaderName(index)) then
    exit;
  //
  f_v := str2intInt(getHeaderValue(index), -1);
  inc(index);
  if (0 > f_v) then
    exit;
  //
  // o=<username> <sess-id> <sess-version> <nettype> <addrtype> <unicast-address>
  if ('o' = getHeaderName(index)) then begin
    //
    value := getHeaderValue(index);
    f_o.r_username := nextToken(value);
    f_o.r_sessid := nextToken(value);
    f_o.r_sessversion := nextToken(value);
    f_o.r_nettype := nextToken(value);
    f_o.r_addrtype := nextToken(value);
    f_o.r_unicastAddress := nextToken(value);
    inc(index);
  end;
  //
  // s=<session name>
  if ('s' = getHeaderName(index)) then begin
    //
    f_s := getHeaderValue(index);
    inc(index);
  end;
  //
  name := getHeaderName(index);
  if ('i' = name) then begin
    // i=<session description>
    f_i := getHeaderValue(index);
    inc(index);
    name := getHeaderName(index);
  end;
  //
  if ('u' = name) then begin
    // u=<uri>
    f_u := getHeaderValue(index);
    inc(index);
    name := getHeaderName(index);
  end;
  //
  if ('e' = name) then begin
    // e=<email-address>
    f_e := getHeaderValue(index);
    inc(index);
    name := getHeaderName(index);
  end;
  //
  if ('p' = name) then begin
    // p=<phone-number>
    f_p := getHeaderValue(index);
    inc(index);
    name := getHeaderName(index);
  end;
  //
  if ('c' = name) then begin
    // c=<nettype> <addrtype> <connection-address>
    parseConnInfo(getHeaderValue(index), f_c);
    inc(index);
    name := getHeaderName(index);
  end;
  //
  while ('b' = name) do begin
    // b=<bwtype>:<bandwidth>
    f_b := f_b + getHeaderValue(index) + #13#10;
    inc(index);
    name := getHeaderName(index);
  end;
  f_b := trimS(f_b);
  //
  while ('t' = name) do begin
    // t=<start-time> <stop-time>
    f_t := f_t + getHeaderValue(index) + #13#10;
    inc(index);
    name := getHeaderName(index);
    //
    while ('r' = name) do begin
      //
      //f_t := f_t + getHeaderValue(index) + #13#10;
      inc(index);
      name := getHeaderName(index);
    end;
  end;
  f_t := trimS(f_t);
  //
  if ('z' = name) then begin
    // z=<adjustment time> <offset> <adjustment time> <offset> ....
    f_z := getHeaderValue(index);
    inc(index);
    name := getHeaderName(index);
  end;
  //
  if ('k' = name) then begin
    // k=<method>
    // k=<method>:<encryption key>
    f_k := getHeaderValue(index);
    inc(index);
    name := getHeaderName(index);
  end;
  //
  while ('a' = name) do begin
    // a=<attribute>
    // a=<attribute>:<value>
    f_a := f_a + getHeaderValue(index) + #13#10;
    inc(index);
    name := getHeaderName(index);
  end;
  f_a := trimS(f_a);
  //
  // MDs..
  while ('m' = name) do begin
    //
    {
      m=  (media name and transport address)
      i=* (media title)
      c=* (connection information -- optional if included at session level)
      b=* (zero or more bandwidth information lines)
      k=* (encryption key)
      a=* (zero or more media attribute lines)
    }
    md := malloc(sizeOf(unaSDPMediaDescription), true);
    //
    value := getHeaderValue(index);
    md.r_type := nextToken(value);
    md.r_port := nextToken(value);
    md.r_proto := nextToken(value);
    md.r_format := str2intInt(nextToken(value), -1);
    md.r_c.r_ttl := -1;
    //
    inc(index);
    name := getHeaderName(index);
    //
    repeat
      //
      outofscope := true;
      //
      if ('i' = name) then begin
	// i=<media title>
	md.r_i := getHeaderValue(index);
	inc(index);
	name := getHeaderName(index);
	outofscope := false;
      end;
      //
      if ('c' = name) then begin
	// c=<nettype> <addrtype> <connection-address>
	parseConnInfo(getHeaderValue(index), md.r_c);
	inc(index);
	name := getHeaderName(index);
	outofscope := false;
      end;
      //
      while ('b' = name) do begin
	// b=<bwtype>:<bandwidth>
	md.r_b := md.r_b + getHeaderValue(index) + #13#10;
	inc(index);
	name := getHeaderName(index);
	outofscope := false;
      end;
      //
      if ('k' = name) then begin
	// k=<method>
	// k=<method>:<encryption key>
	md.r_k := getHeaderValue(index);
	inc(index);
	name := getHeaderName(index);
	outofscope := false;
      end;
      //
      while ('a' = name) do begin
	// a=<attribute>
	// a=<attribute>:<value>
	value := getHeaderValue(index);
	md.r_a := md.r_a + value + #13#10;
	if (1 = pos('control:', value)) then
	  md.r_control := md.r_control + copy(value, length('control: '), maxInt) + #13#10
	else
	  if (1 = pos('rtpmap:', value)) then
	    md.r_rtpmap := md.r_rtpmap + copy(value, length('rtpmap: '), maxInt) + #13#10
	  else
	    if (1 = pos('fmtp:', value)) then
	      md.r_fmtp := md.r_fmtp + copy(value, length('fmtp: '), maxInt) + #13#10;
	//
	inc(index);
	name := getHeaderName(index);
	outofscope := false;
      end;
      //
    until (outofscope);
    //
    md.r_control := trimS(md.r_control);
    md.r_rtpmap := trimS(md.r_rtpmap);
    //
    f_md.add(md);
  end; // while ('m' = name) ...
end;

// --  --
function unaSDPParser.parseConnInfo(const data: string; var ci: unaSDPConnectionInfo): bool;
var
  p: int;
  v: string;
begin
  result := false;
  p := pos(' ', data);
  if (0 < p) then begin
    //
    ci.r_netType := copy(data, 1, p - 1);
    ci.r_addrType := copy(data, p + 1, maxInt);
    p := pos(' ', ci.r_addrType);
    if (0 < p) then begin
      //
      ci.r_connAddr := copy(ci.r_addrType, p + 1, maxInt);
      ci.r_addrType := copy(ci.r_addrType, 1, p - 1);
      //
      ci.r_ttl := -1;
      ci.r_numberOfAddresses := 1;
      //
      p := pos('/', ci.r_connAddr);
      if (0 < p) then begin
	//
	v := copy(ci.r_connAddr, p + 1, maxInt);
	ci.r_connAddr := copy(ci.r_connAddr, 1, p - 1);
	//
	p := pos('/', v);
	if (0 < p) then begin
	  //
	  ci.r_ttl := str2intInt(copy(v, 1, p - 1), -1);
	  ci.r_numberOfAddresses := str2intInt(copy(v, p + 1, maxInt), -1);
	  if (1 > ci.r_numberOfAddresses) then
	    ci.r_numberOfAddresses := 1;
	end
	else
	  ci.r_ttl := str2intInt(v, -1);
      end;
      //
      result := true;
    end;
  end;
end;



{$IFDEF UNA_OP_CHECK_HTTPP }

// --  --
procedure checkP(p: unaHTTPparser; i: int);
var
  s: string;
begin
  s := #13#10#13#10 + int2str(i) + '> METHOD=' + p.getReqMethod();
  s := s + #13#10 + 'URI=' + p.getReqURI();
  s := s + #13#10 + 'VER=' + p.getReqProtoVersion();
  s := s + #13#10 + 'PROTO=' + p.getRespProtoVersion();
  s := s + #13#10 + 'Code=' + int2str(p.getRespCode());
  s := s + #13#10 + 'HumanCode=' + p.getRespCodeString();
  s := s + #13#10 + '================';
  s := s + #13#10 + 'Date: ' + p.getHeaderValue('Date');
  s := s + #13#10 + 'Content-Length: ' + p.getHeaderValue('Content-Length');
  s := s + #13#10 + 'Content-Type: ' + p.getHeaderValue('Content-Type');
  s := s + #13#10 + 'Dummy: ' + p.getHeaderValue('Content-Type');
  s := s + #13#10 + '================';
  s := s + #13#10 + 'Header count=' + int2str(p.getHeaderCount());
  s := s + #13#10 + '0=' + p.getHeaderName(0) + ': ' + p.getHeaderValue(0);
  s := s + #13#10 + '3=' + p.getHeaderName(3) + ': ' + p.getHeaderValue(3);
  s := s + #13#10 + '7=' + p.getHeaderName(7) + ': ' + p.getHeaderValue(7);
  s := s + #13#10 + '8=' + p.getHeaderName(8) + ': ' + p.getHeaderValue(8);
  s := s + #13#10 + '================';
  s := s + #13#10 + 'Date (by index): ' + p.getHeaderValue(0);
  s := s + #13#10 + 'Content-Length (by index): ' + p.getHeaderValue(5);
  s := s + #13#10 + 'Content-Type (by index): ' + p.getHeaderValue(7);
  s := s + #13#10 + '================';
  s := s + #13#10 + 'HC=' + bool2strStr(p.headerComplete);
  s := s + #13#10 + 'PC=' + bool2strStr(p.payloadComplete);
  s := s + #13#10 + 'Paylaod=[' + string(p.getPayload()) + ']';
  //
  //writeToFile('D:\parser_testlog.txt', aString(s));
end;

const
  resp: aString = 'HTTP/1.1 200 OK'#13#10 +
	 'Date: Wed, 14 Apr 2004 11:47:05 GMT'#13#10 +
	 'Server: Apache/1.3.12 (Win32) PHP/4.0.6'#13#10 +
	 'Last-Modified: Sat, 10 Nov 2001 01:07:58 GMT'#13#10 +
	 'ETag: "0-39c-3bec7dee"'#13#10 +
	 'Accept-Ranges: bytes'#13#10 +
	 'Content-Length: 7'#13#10 +
	 'Connection: close'#13#10 +
	 'Content-Type: text/html'#13#10 +
	 ''#13#10 +
	 '1234:56GET /hello.gif HTTP/1.2'#13#10 +
	 'Content-Length: 7'#13#10 +
	 ''#13#10 +
	 '1234567';

procedure checkHTTPp();
var
  p: unaHTTPparser;
  i: int;
begin
  p := unaHTTPparser.create();
  //
  for i := 1 to 261 do begin
    //
    case i of
      1, 2, 17,
      53, 54, 55, 56,
      94, 95, 96,
      250, 251, 252, 253, 259, 260: checkP(p, i);
    end;
    //
    p.feed(@resp[i], 1);
  end;
  checkP(p, 262);
  //
  p.dropIfComplete();
  //
  p.feed(@resp[262], length(resp) - 262 + 1);
  checkP(p, 300);
  //
  freeAndNil(p);
end;

{$ENDIF UNA_OP_CHECK_HTTPP }



end.

