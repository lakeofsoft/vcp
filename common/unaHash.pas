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
	  unaHash.pas

	  MD5
	  Digest Access Authentication
	  SHA
	----------------------------------------------
	  Delphi version (c) 2012 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 15 Jan 2012

	  modified by:
		Lake, Jan 2012

	----------------------------------------------
*)

{$I unaDef.inc }


{$DEFINE UNA_MD5_SELFTEST }	// include self-test routine

{*
	- MD5 (RFC 1321)
	- Digest Access Authentication (RFC 2617)
	- SHA ( http://www.itl.nist.gov/fipspubs/fip180-1.htm )

	@Author Lake

	Version 2.5.2012.01 First release
}

unit
  unaHash;

interface

uses
  Windows, unaTypes;

//===== RFC 1321 ==============================================================

type
  unaMD5digest = array[0..15] of byte;

{*
	Computes MD5 hash

	@param str	data to hash
	@param lowCase	return hex-string in low case
	@return 	hex respresentation of md5 hash, like '0cc175b9c0f1b6a831c399e269772661'
}
function md5(const str: aString; lowCase: bool = false): aString; overload;
{*
	Computes MD5 hash

	@param buf	data to hash
	@param len	size of buffer
	@param d	md5 hash of data
}
procedure md5(buf: pointer; len: uint; out d: unaMD5digest); overload;
{*
	Computes MD5 hash

	@param str	data to hash
	@param d	md5 hash of data
}
procedure md5(const str: aString; out d: unaMD5digest); overload;
{*
	Represents MD5 digest as ANSI hex-string

	@param d	digest
	@param lowCase	use low case (abcdef instead of ABCDEF)
}
function digest2str(const d: unaMD5digest; lowCase: bool = false): aString; overload;
{*
	Represents digest of any length as ANSI hex-string

	@param d	pointer to digest bytes
	@param len	size of digest
	@param lowCase	use low case (abcdef instead of ABCDEF)
}
function digest2str(d: pointer; len: int; lowCase: bool = false): aString; overload;



//===== RFC 2617 ==============================================================


const
  HASHHEXLEN 	= 32;

type
  HASHHEX = array [0..HASHHEXLEN] of aChar;	// no -1 here!

{*
	Calculate H(A1) as per HTTP Digest spec

	@param pszAlg 		IN pszAlg - algorith to use ('md5')
	@param pszUserName	IN pszUserName - user name
	@param pszRealm		IN pszRealm - realm
	@param pszPassword	IN pszPassword - password
	@param pszNonce		IN pszNonce - nonce
	@param pszCNonce	IN pszCNonce - Cnonce
	@param SessionKey	OUT SessionKey - key
*}
procedure DigestCalcHA1(
    const pszAlg,
	  pszUserName,
	  pszRealm,
	  pszPassword,
	  pszNonce,
	  pszCNonce: aString;
    out   SessionKey: HASHHEX
  );

{*
	Calculate request-digest/response-digest as per HTTP Digest spec

	@param HA1		IN H(A1)
	@param pszNonce		IN nonce from server
	@param pszNonceCount	IN 8 hex digits
	@param pszCNonce	IN client nonce
	@param pszQop		IN qop-value: "", "auth", "auth-int"
	@param pszMethod	IN method from the request
	@param pszDigestUri	IN requested URL
	@param HEntity		IN H(entity body) if qop="auth-int"
	@param Response     	OUT request-digest or response-digest
*}
procedure DigestCalcResponse(
    const HA1: HASHHEX;
    const pszNonce,
	  pszNonceCount,
	  pszCNonce,
	  pszQop,
	  pszMethod,
	  pszDigestUri: aString;
    const HEntity: HASHHEX;
    out   Response: HASHHEX
  );


// ========== SHA ============================================

type
  HashWordType5		= array[0..4] of uint32;	// for SHA-1
  HashWordType8 	= array[0..7] of uint32;	// for SHA-256
  HashWordType8x64	= array[0..7] of uint64;	// for SHA-512

{*
}
procedure sha512(data: pointer; len: uint64; out digest: HashWordType8x64); overload;

{*
}
function sha512(const data: aString; lowCase: bool = false): aString; overload;


{*
	Performs "self-test" of all hashes.
}
function selftest(): bool;


implementation


uses
  unaUtils;

type
  array32_4 = array[0..3] of uint32;
  array8_64 = array[0..63] of uint8;

  {*
	Context
  }
  punaMD5context = ^unaMD5context;
  unaMD5context = packed record
    //
    state: array32_4;	// 16
    count: array[0..1] of uint32;	// 8
    buffer: array8_64;	// 64
  end;


const
  S11	= 7;
  S12	= 12;
  S13	= 17;
  S14	= 22;
  S21	= 5;
  S22	= 9;
  S23	= 14;
  S24	= 20;
  S31	= 4;
  S32	= 11;
  S33	= 16;
  S34	= 23;
  S41	= 6;
  S42	= 10;
  S43	= 15;
  S44	= 21;

var
  pad: array[0..63] of byte = (
    $80, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  );

{$IFOPT R+ }
  {$DEFINE D_0F1E9BD78E8E462CBF710601B57495F1 }
{$ENDIF R+ }
//
{$IFOPT Q+ }
  {$DEFINE D_8BDB211C53D54EADAB75BED8936C3F58 }
{$ENDIF Q+ }

{$R-}
{$Q-}

//* F, G, H and I are basic MD5 functions. */
// --  --
function F(x, y, z: uint32): uint32; {$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
begin
  result := (x and y) or (not x and z);
end;
// --  --
function G(x, y, z: uint32): uint32; {$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
begin
  result := (x and z) or (y and not z);
end;
// --  --
function H(x, y, z: uint32): uint32; {$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
begin
  result := (x xor y xor z);
end;
// --  --
function I(x, y, z: uint32): uint32; {$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
begin
  result := y xor (x or not z);
end;

//* ROTATE_LEFT rotates x left n bits. */
// --  --
function ROTATE_LEFT(x, n: uint32): uint32; {$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
begin
  result := (x shl n) or (x shr (32 - n));
end;

//* ROTATE_RIGTH rotates x right n bits. */
// --  --
function ROTATE_RIGTH(x, n: uint32): uint32; {$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
begin
  result := (x shr n) or (x shl (32 - n));
end;

//* ROTATE_RIGTH rotates x right n bits. */
// --  --
function ROTATE_RIGTH64(x, n: uint64): uint64; {$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
begin
  result := (x shr n) or (x shl (64 - n));
end;

//* FF, GG, HH, and II transformations for rounds 1, 2, 3, and 4. Rotation is separate from addition to prevent recomputation. */
// --  --
procedure FF(var a: uint32; b, c, d, x, s, ac: uint32); {$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
begin
 a := ROTATE_LEFT(a + F(b, c, d) + x + ac, s) + b;
end;
// --  --
procedure GG(var a: uint32; b, c, d, x, s, ac: uint32); {$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
begin
 a := ROTATE_LEFT(a + G(b, c, d) + x + ac, s) + b;
end;
// --  --
procedure HH(var a: uint32; b, c, d, x, s, ac: uint32); {$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
begin
 a := ROTATE_LEFT(a + H(b, c, d) + x + ac, s) + b;
end;
// --  --
procedure II(var a: uint32; b, c, d, x, s, ac: uint32); {$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
begin
 a := ROTATE_LEFT(a + I(b, c, d) + x + ac, s) + b;
end;

//* Encodes input (UINT4) into output (unsigned char). Assumes len is a multiple of 4. */
// -- endian-independed --
procedure encode(output: pUint8Array; input: pUint32; len: uint); {$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
var
  j: uint;
begin
  j := 0;
  while (j < len) do begin
    //
    output[j    ] := byte( input^         and $ff);
    output[j + 1] := byte((input^ shr  8) and $ff);
    output[j + 2] := byte((input^ shr 16) and $ff);
    output[j + 3] := byte((input^ shr 24) and $ff);
    //
    inc(j, 4);
    inc(input);
  end;
end;

//* Decodes input (unsigned char) into output (UINT4). Assumes len is a multiple of 4. */
// -- endian-independed --
procedure decode(output: pUint32; input: pUint8Array; len: uint); {$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
var
  j: uint;
begin
  j := 0;
  while (j < len) do begin
    //
    output^ :=
      (uint32(input[j    ])       ) or
      (uint32(input[j + 1]) shl  8) or
      (uint32(input[j + 2]) shl 16) or
      (uint32(input[j + 3]) shl 24);
    //
    inc(j, 4);
    inc(output);
  end;
end;

//* MD5 basic transformation. Transforms state based on block. */
// --  --
procedure md5Transform(var state: array32_4; block: pointer);
var
  a, b, c, d: uint32;
  x: array[0..15] of uint32;
begin
  a := state[0];
  b := state[1];
  c := state[2];
  d := state[3];
  //
  decode(pUint32(@x), block, 64);
  //
  //* Round 1 */
  FF(a, b, c, d, x[ 0], S11, $d76aa478); //* 1 */
  FF(d, a, b, c, x[ 1], S12, $e8c7b756); //* 2 */
  FF(c, d, a, b, x[ 2], S13, $242070db); //* 3 */
  FF(b, c, d, a, x[ 3], S14, $c1bdceee); //* 4 */
  FF(a, b, c, d, x[ 4], S11, $f57c0faf); //* 5 */
  FF(d, a, b, c, x[ 5], S12, $4787c62a); //* 6 */
  FF(c, d, a, b, x[ 6], S13, $a8304613); //* 7 */
  FF(b, c, d, a, x[ 7], S14, $fd469501); //* 8 */
  FF(a, b, c, d, x[ 8], S11, $698098d8); //* 9 */
  FF(d, a, b, c, x[ 9], S12, $8b44f7af); //* 10 */
  FF(c, d, a, b, x[10], S13, $ffff5bb1); //* 11 */
  FF(b, c, d, a, x[11], S14, $895cd7be); //* 12 */
  FF(a, b, c, d, x[12], S11, $6b901122); //* 13 */
  FF(d, a, b, c, x[13], S12, $fd987193); //* 14 */
  FF(c, d, a, b, x[14], S13, $a679438e); //* 15 */
  FF(b, c, d, a, x[15], S14, $49b40821); //* 16 */
  //
  //* Round 2 */
  GG(a, b, c, d, x[ 1], S21, $f61e2562); //* 17 */
  GG(d, a, b, c, x[ 6], S22, $c040b340); //* 18 */
  GG(c, d, a, b, x[11], S23, $265e5a51); //* 19 */
  GG(b, c, d, a, x[ 0], S24, $e9b6c7aa); //* 20 */
  GG(a, b, c, d, x[ 5], S21, $d62f105d); //* 21 */
  GG(d, a, b, c, x[10], S22, $2441453 ); //* 22 */
  GG(c, d, a, b, x[15], S23, $d8a1e681); //* 23 */
  GG(b, c, d, a, x[ 4], S24, $e7d3fbc8); //* 24 */
  GG(a, b, c, d, x[ 9], S21, $21e1cde6); //* 25 */
  GG(d, a, b, c, x[14], S22, $c33707d6); //* 26 */
  GG(c, d, a, b, x[ 3], S23, $f4d50d87); //* 27 */
  GG(b, c, d, a, x[ 8], S24, $455a14ed); //* 28 */
  GG(a, b, c, d, x[13], S21, $a9e3e905); //* 29 */
  GG(d, a, b, c, x[ 2], S22, $fcefa3f8); //* 30 */
  GG(c, d, a, b, x[ 7], S23, $676f02d9); //* 31 */
  GG(b, c, d, a, x[12], S24, $8d2a4c8a); //* 32 */
  //
  //* Round 3 */
  HH(a, b, c, d, x[ 5], S31, $fffa3942); //* 33 */
  HH(d, a, b, c, x[ 8], S32, $8771f681); //* 34 */
  HH(c, d, a, b, x[11], S33, $6d9d6122); //* 35 */
  HH(b, c, d, a, x[14], S34, $fde5380c); //* 36 */
  HH(a, b, c, d, x[ 1], S31, $a4beea44); //* 37 */
  HH(d, a, b, c, x[ 4], S32, $4bdecfa9); //* 38 */
  HH(c, d, a, b, x[ 7], S33, $f6bb4b60); //* 39 */
  HH(b, c, d, a, x[10], S34, $bebfbc70); //* 40 */
  HH(a, b, c, d, x[13], S31, $289b7ec6); //* 41 */
  HH(d, a, b, c, x[ 0], S32, $eaa127fa); //* 42 */
  HH(c, d, a, b, x[ 3], S33, $d4ef3085); //* 43 */
  HH(b, c, d, a, x[ 6], S34, $4881d05 ); //* 44 */
  HH(a, b, c, d, x[ 9], S31, $d9d4d039); //* 45 */
  HH(d, a, b, c, x[12], S32, $e6db99e5); //* 46 */
  HH(c, d, a, b, x[15], S33, $1fa27cf8); //* 47 */
  HH(b, c, d, a, x[ 2], S34, $c4ac5665); //* 48 */
  //
  //* Round 4 */
  II(a, b, c, d, x[ 0], S41, $f4292244); //* 49 */
  II(d, a, b, c, x[ 7], S42, $432aff97); //* 50 */
  II(c, d, a, b, x[14], S43, $ab9423a7); //* 51 */
  II(b, c, d, a, x[ 5], S44, $fc93a039); //* 52 */
  II(a, b, c, d, x[12], S41, $655b59c3); //* 53 */
  II(d, a, b, c, x[ 3], S42, $8f0ccc92); //* 54 */
  II(c, d, a, b, x[10], S43, $ffeff47d); //* 55 */
  II(b, c, d, a, x[ 1], S44, $85845dd1); //* 56 */
  II(a, b, c, d, x[ 8], S41, $6fa87e4f); //* 57 */
  II(d, a, b, c, x[15], S42, $fe2ce6e0); //* 58 */
  II(c, d, a, b, x[ 6], S43, $a3014314); //* 59 */
  II(b, c, d, a, x[13], S44, $4e0811a1); //* 60 */
  II(a, b, c, d, x[ 4], S41, $f7537e82); //* 61 */
  II(d, a, b, c, x[11], S42, $bd3af235); //* 62 */
  II(c, d, a, b, x[ 2], S43, $2ad7d2bb); //* 63 */
  II(b, c, d, a, x[ 9], S44, $eb86d391); //* 64 */

  inc(state[0], a);
  inc(state[1], b);
  inc(state[2], c);
  inc(state[3], d);

  //* Zeroize sensitive information.*/
  fillChar(x, sizeof(x), #0);
end;

{$IFDEF D_0F1E9BD78E8E462CBF710601B57495F1 }
  {$R+}
{$ENDIF D_0F1E9BD78E8E462CBF710601B57495F1 }
//
{$IFDEF D_8BDB211C53D54EADAB75BED8936C3F58 }
  {$Q+}
{$ENDIF D_8BDB211C53D54EADAB75BED8936C3F58}


{*
	Initializates MD5 context
}
procedure md5Init(var ctx: unaMD5context); {$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
begin
  ctx.count[0] := 0;
  ctx.count[1] := 0;
  ctx.state[0] := $67452301;
  ctx.state[1] := $efcdab89;
  ctx.state[2] := $98badcfe;
  ctx.state[3] := $10325476;
end;

{*
	Updates MD5
}
procedure md5Update(ctx: punaMD5context; buf: pArray; len: uint); overload;
var
  i: uint32;
  index, partLen: uint;
begin
  //* Compute number of bytes mod 64 */
  index := (ctx.count[0] shr 3) and $3F;
  //
  //* Update number of bits */
  inc(ctx.count[0], len shl 3);
  if (ctx.count[0] < (len shl 3)) then
     inc(ctx.count[1]);
  //
  inc(ctx.count[1], len shr 29);
  //
  partLen := 64 - index;
  //
  //* Transform as many times as possible. */
  if (len >= partLen) then begin
    //
    move(buf^, ctx.buffer[index], partLen);
    md5Transform(ctx.state, @ctx.buffer);
    //
    i := partLen;
    while (i + 63 < len) do begin
      //
      MD5Transform(ctx.state, @buf[i]);
      inc(i, 64);
    end;
    //
    index := 0;
  end
  else
    i := 0;
  //
  //* Buffer remaining input */
  if (0 < len - i) then
    move(buf[i], ctx.buffer[index], len - i);
end;

// --  --
procedure md5Update(ctx: punaMD5context; const str: aString); overload;
begin
  if ('' <> str) then
    md5Update(ctx, pArray(@str[1]), length(str))
  else
    md5Update(ctx, nil, 0);
end;

// --  --
procedure md5Final(out d: unaMD5digest; ctx: punaMD5context);
var
  bits: array[0..7] of uint8;
  index, padLen: uint;
begin
  //* Save number of bits */
  encode(pUint8Array(@bits), pUint32(@ctx.count), 8);
  //
  //* Pad out to 56 mod 64. */
  index := ((ctx.count[0] shr 3) and $3f);
  if (index < 56) then
    padLen := (56 - index)
  else
    padLen := (120 - index);
  //
  md5Update(ctx, pArray(@pad), padLen);
  //
  //* Append length (before padding) */
  md5Update(ctx, pArray(@bits), 8);
  //
  //* Store state in digest */
  encode(pUint8array(@d), pUint32(@ctx.state), 16);
  //
  //* Zeroize sensitive information. */
  fillchar(ctx^, sizeof(ctx^), #0);
end;

// -- md5 utility functions --

// --  --
function md5(const str: aString; lowCase: bool): aString;
var
  d: unaMD5digest;
begin
  if ('' <> str) then
    md5(@str[1], length(str), d)
  else
    md5(nil, 0, d);
  //
  result := digest2str(d, lowCase);
end;

// --  --
procedure md5(buf: pointer; len: uint; out d: unaMD5digest);
var
  ctx: unaMD5context;
begin
  md5Init(ctx);
  md5Update(@ctx, buf, len);
  md5Final(d, @ctx);
end;

// --  --
procedure md5(const str: aString; out d: unaMD5digest); overload;
begin
  if ('' <> str) then
    md5(@aString(str)[1], length(aString(str)), d)
  else
    md5(nil, 0, d);
end;

// --  --
function digest2str(const d: unaMD5digest; lowCase: bool): aString;
begin
  result := digest2str(@d, sizeof(unaMD5digest), lowCase);
end;

// --  --
function digest2str(d: pointer; len: int; lowCase: bool): aString;
var
  i: int32;
  data: pUint8Array absolute d;
begin
  result := '';
  for i := 0 to len - 1 do
    result := result + aString(adjust(int2str(data[i], 16), 2, '0'));
  //
  if (lowCase) then
    result := loCase(result);
end;


//===== RFC 2617 ==============================================================


// --  --
procedure CvtHex(const Bin: unaMD5digest; out Hex: HASHHEX);
var
  i: uint32;
  j: byte;
begin
  for i := low(Bin) to high(Bin) do begin
    //
    j := (Bin[i] shr 4) and $F;
    if (j <= 9) then
      Hex[i shl 1] := aChar(j + ord('0'))
    else
      Hex[i shl 1] := aChar(j + ord('a') - 10);
    //
    j := Bin[i] and $F;
    if (j <= 9) then
      Hex[i shl 1 + 1] := aChar(j + ord('0'))
    else
      Hex[i shl 1 + 1] := aChar(j + ord('a') - 10);
  end;
  //
  Hex[HASHHEXLEN] := #0;
end;

//* calculate H(A1) as per spec */
procedure DigestCalcHA1(
    const pszAlg,
	  pszUserName,
	  pszRealm,
	  pszPassword,
	  pszNonce,
	  pszCNonce: aString;
    out   SessionKey: HASHHEX
  );
var
  Md5Ctx: unaMD5context;
  HA1: unaMD5digest;
begin
  md5Init(Md5Ctx);
  md5Update(@Md5Ctx, pszUserName);
  md5Update(@Md5Ctx, ':');
  md5Update(@Md5Ctx, pszRealm);
  md5Update(@Md5Ctx, ':');
  md5Update(@Md5Ctx, pszPassword);
  md5Final(HA1, @Md5Ctx);
  //
  if ('md5-sess' = loCase(pszAlg)) then begin
    //
    md5Init(Md5Ctx);
    md5Update(@Md5Ctx, pArray(@HA1), sizeof(HA1));
    md5Update(@Md5Ctx, ':');
    md5Update(@Md5Ctx, pszNonce);
    md5Update(@Md5Ctx, ':');
    md5Update(@Md5Ctx, pszCNonce);
    md5Final(HA1, @Md5Ctx);
  end;
  //
  CvtHex(HA1, SessionKey);
end;

//* calculate request-digest/response-digest as per HTTP Digest spec */
procedure DigestCalcResponse(
    const HA1: HASHHEX;
    const pszNonce,
	  pszNonceCount,
	  pszCNonce,
	  pszQop,
	  pszMethod,
	  pszDigestUri: aString;
    const HEntity: HASHHEX;
    out   Response: HASHHEX
  );
var
  Md5Ctx: unaMD5context;
  HA2: unaMD5digest;
  RespHash: unaMD5digest;
  HA2Hex: HASHHEX;
begin
  // calculate H(A2)
  md5Init(Md5Ctx);
  md5Update(@Md5Ctx, pszMethod);
  md5Update(@Md5Ctx, ':');
  md5Update(@Md5Ctx, pszDigestUri);
  if ('auth-int' = loCase(pszQop)) then begin
      //
      md5Update(@Md5Ctx, ':');
      md5Update(@Md5Ctx, pArray(@HEntity), HASHHEXLEN);
  end;
  md5Final(HA2, @Md5Ctx);
  CvtHex(HA2, HA2Hex);
  //
  // calculate response
  md5Init(Md5Ctx);
  md5Update(@Md5Ctx, pArray(@HA1), HASHHEXLEN);
  md5Update(@Md5Ctx, ':');
  md5Update(@Md5Ctx, pszNonce);
  md5Update(@Md5Ctx, ':');
  if ('' <> pszQop) then begin
    //
    md5Update(@Md5Ctx, pszNonceCount);
    md5Update(@Md5Ctx, ':');
    md5Update(@Md5Ctx, pszCNonce);
    md5Update(@Md5Ctx, ':');
    md5Update(@Md5Ctx, pszQop);
    md5Update(@Md5Ctx, ':');
  end;
  //
  md5Update(@Md5Ctx, pArray(@HA2Hex), HASHHEXLEN);
  md5Final(RespHash, @Md5Ctx);
  //
  CvtHex(RespHash, Response);
end;


// === SHA =======================================================================

// --  --
procedure sha1Init(var s: HashWordType5);
begin
  s[0] := $67452301;
  s[1] := $EFCDAB89;
  s[2] := $98BADCFE;
  s[3] := $10325476;
  s[4] := $C3D2E1F0;
end;

{$IFOPT R+ }
  {$DEFINE D_0F1E9BD78E8E462CBF710601B57495F1 }
{$ENDIF R+ }
//
{$IFOPT Q+ }
  {$DEFINE D_8BDB211C53D54EADAB75BED8936C3F58 }
{$ENDIF Q+ }

{$R-}
{$Q-}

// --  --
function f1(x, y, z: uint32): uint32; {$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
begin
  result := (z xor (x and (y xor z)));
end;

// --  --
function f2(x, y, z: uint32): uint32; {$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
begin
  result := (x xor y xor z);
end;

// --  --
function f3(x, y, z: uint32): uint32; {$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
begin
  result := ((x and y) or (z and (x or y)));
end;

// --  --
function f4(x, y, z: uint32): uint32; {$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
begin
  result := (x xor y xor z);
end;

// --  --
procedure SHA1_Transform(var s: HashWordType5; data: pUint32Array);
var
  _W: array[0..15] of uint32;

  // --  --
  procedure R0(v: uint32; var w: uint32; x, y: uint32; var z: uint32; i: uint32);
  begin
    _W[i] := data[i];
    //
    z := z + f1(w, x, y) + _W[i] + $5A827999 + ROTATE_LEFT(v, 5);
    w := ROTATE_LEFT(w, 30);
  end;

  // --  --
  procedure R1(v: uint32; var w: uint32; x, y: uint32; var z: uint32; i: uint32);
  begin
    _W[i and 15] := ROTATE_LEFT(_W[(i + 13) and 15] and _W[(i + 8) and 15] xor _W[(i + 2) and 15] xor _W[i and 15], 1);
    //
    z := z + f1(w, x, y) + _W[i and 15] + $5A827999 + ROTATE_LEFT(v, 5);
    w := ROTATE_LEFT(w, 30);
  end;

  // --  --
  procedure R2(v: uint32; var w: uint32; x, y: uint32; var z: uint32; i: uint32);
  begin
    _W[i and 15] := ROTATE_LEFT(_W[(i + 13) and 15] and _W[(i + 8) and 15] xor _W[(i + 2) and 15] xor _W[i and 15], 1);
    //
    z := z + f2(w, x, y) + _W[i and 15] + $6ED9EBA1 + ROTATE_LEFT(v, 5);
    w := ROTATE_LEFT(w, 30);
  end;

  // --  --
  procedure R3(v: uint32; var w: uint32; x, y: uint32; var z: uint32; i: uint32);
  begin
    _W[i and 15] := ROTATE_LEFT(_W[(i + 13) and 15] and _W[(i + 8) and 15] xor _W[(i + 2) and 15] xor _W[i and 15], 1);
    //
    z := z + f3(w, x, y) + _W[i and 15] + $8F1BBCDC + ROTATE_LEFT(v, 5);
    w := ROTATE_LEFT(w, 30);
  end;

  // --  --
  procedure R4(v: uint32; var w: uint32; x, y: uint32; var z: uint32; i: uint32);
  begin
    _W[i and 15] := ROTATE_LEFT(_W[(i + 13) and 15] and _W[(i + 8) and 15] xor _W[(i + 2) and 15] xor _W[i and 15], 1);
    //
    z := z + f4(w, x, y) + _W[i and 15] + $CA62C1D6 + ROTATE_LEFT(v, 5);
    w := ROTATE_LEFT(w, 30);
  end;

var
  a, b, c, d, e: uint32;
begin
  // save
  a := s[0];
  b := s[1];
  c := s[2];
  d := s[3];
  e := s[4];

  // 4 rounds
  R0(a,b,c,d,e, 0); R0(e,a,b,c,d, 1); R0(d,e,a,b,c, 2); R0(c,d,e,a,b, 3);
  R0(b,c,d,e,a, 4); R0(a,b,c,d,e, 5); R0(e,a,b,c,d, 6); R0(d,e,a,b,c, 7);
  R0(c,d,e,a,b, 8); R0(b,c,d,e,a, 9); R0(a,b,c,d,e,10); R0(e,a,b,c,d,11);
  R0(d,e,a,b,c,12); R0(c,d,e,a,b,13); R0(b,c,d,e,a,14); R0(a,b,c,d,e,15);
  //
  R1(e,a,b,c,d,16); R1(d,e,a,b,c,17); R1(c,d,e,a,b,18); R1(b,c,d,e,a,19);
  //
  R2(a,b,c,d,e,20); R2(e,a,b,c,d,21); R2(d,e,a,b,c,22); R2(c,d,e,a,b,23);
  R2(b,c,d,e,a,24); R2(a,b,c,d,e,25); R2(e,a,b,c,d,26); R2(d,e,a,b,c,27);
  R2(c,d,e,a,b,28); R2(b,c,d,e,a,29); R2(a,b,c,d,e,30); R2(e,a,b,c,d,31);
  R2(d,e,a,b,c,32); R2(c,d,e,a,b,33); R2(b,c,d,e,a,34); R2(a,b,c,d,e,35);
  R2(e,a,b,c,d,36); R2(d,e,a,b,c,37); R2(c,d,e,a,b,38); R2(b,c,d,e,a,39);
  //
  R3(a,b,c,d,e,40); R3(e,a,b,c,d,41); R3(d,e,a,b,c,42); R3(c,d,e,a,b,43);
  R3(b,c,d,e,a,44); R3(a,b,c,d,e,45); R3(e,a,b,c,d,46); R3(d,e,a,b,c,47);
  R3(c,d,e,a,b,48); R3(b,c,d,e,a,49); R3(a,b,c,d,e,50); R3(e,a,b,c,d,51);
  R3(d,e,a,b,c,52); R3(c,d,e,a,b,53); R3(b,c,d,e,a,54); R3(a,b,c,d,e,55);
  R3(e,a,b,c,d,56); R3(d,e,a,b,c,57); R3(c,d,e,a,b,58); R3(b,c,d,e,a,59);
  //
  R4(a,b,c,d,e,60); R4(e,a,b,c,d,61); R4(d,e,a,b,c,62); R4(c,d,e,a,b,63);
  R4(b,c,d,e,a,64); R4(a,b,c,d,e,65); R4(e,a,b,c,d,66); R4(d,e,a,b,c,67);
  R4(c,d,e,a,b,68); R4(b,c,d,e,a,69); R4(a,b,c,d,e,70); R4(e,a,b,c,d,71);
  R4(d,e,a,b,c,72); R4(c,d,e,a,b,73); R4(b,c,d,e,a,74); R4(a,b,c,d,e,75);
  R4(e,a,b,c,d,76); R4(d,e,a,b,c,77); R4(c,d,e,a,b,78); R4(b,c,d,e,a,79);

  // sum back
  inc(s[0], a);
  inc(s[1], b);
  inc(s[2], c);
  inc(s[3], d);
  inc(s[4], e);
end;

// --  --
procedure sha224Init(var s: HashWordType8);
begin
  s[0] := $c1059ed8;
  s[1] := $367cd507;
  s[2] := $3070dd17;
  s[3] := $f70e5939;
  s[4] := $ffc00b31;
  s[5] := $68581511;
  s[6] := $64f98fa7;
  s[7] := $befa4fa4;
end;

// --  --
procedure sha256Init(var s: HashWordType8);
begin
  s[0] := $6a09e667;
  s[1] := $bb67ae85;
  s[2] := $3c6ef372;
  s[3] := $a54ff53a;
  s[4] := $510e527f;
  s[5] := $9b05688c;
  s[6] := $1f83d9ab;
  s[7] := $5be0cd19;
end;

// --  --
const
  SHA256_K: array[0..63] of uint32 = (
    $428a2f98, $71374491, $b5c0fbcf, $e9b5dba5,
    $3956c25b, $59f111f1, $923f82a4, $ab1c5ed5,
    $d807aa98, $12835b01, $243185be, $550c7dc3,
    $72be5d74, $80deb1fe, $9bdc06a7, $c19bf174,
    $e49b69c1, $efbe4786, $0fc19dc6, $240ca1cc,
    $2de92c6f, $4a7484aa, $5cb0a9dc, $76f988da,
    $983e5152, $a831c66d, $b00327c8, $bf597fc7,
    $c6e00bf3, $d5a79147, $06ca6351, $14292967,
    $27b70a85, $2e1b2138, $4d2c6dfc, $53380d13,
    $650a7354, $766a0abb, $81c2c92e, $92722c85,
    $a2bfe8a1, $a81a664b, $c24b8b70, $c76c51a3,
    $d192e819, $d6990624, $f40e3585, $106aa070,
    $19a4c116, $1e376c08, $2748774c, $34b0bcb5,
    $391c0cb3, $4ed8aa4a, $5b9cca4f, $682e6ff3,
    $748f82ee, $78a5636f, $84c87814, $8cc70208,
    $90befffa, $a4506ceb, $bef9a3f7, $c67178f2
  );

// --  --
procedure sha256Transform(var s: HashWordType8; data: pUint32Array);
var
  _W: array[0..15] of uint32;
  _T: array[0..7] of uint32;
  j: int;

  // --  --
  function Ch(x, y, z: uint32): uint32;{$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
  begin
    result := (z xor (x and (y xor z)));
  end;

  // --  --
  function Maj(x, y, z: uint32): uint32;{$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
  begin
    result := (y xor ((x xor y) and (y xor z)));
  end;

  // --  --
  function _S0(x: uint32): uint32; {$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
  begin
    result := ROTATE_RIGTH(x, 2) xor ROTATE_RIGTH(x, 13) xor ROTATE_RIGTH(x, 22);
  end;

  // --  --
  function _S1(x: uint32): uint32; {$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
  begin
    result := ROTATE_RIGTH(x, 6) xor ROTATE_RIGTH(x, 11) xor ROTATE_RIGTH(x, 25);
  end;

  // --  --
  function s0(x: uint32): uint32; {$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
  begin
    result := ROTATE_RIGTH(x, 7) xor ROTATE_RIGTH(x, 18) xor (x shr 3);
  end;

  // --  --
  function s1(x: uint32): uint32; {$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
  begin
    result := ROTATE_RIGTH(x, 17) xor ROTATE_RIGTH(x, 19) xor (x shr 10);
  end;

  // --  --
  procedure R(i: int);
  begin
    inc(_T[(7 - i) and 7], _S1(_T[(4 - i) and 7]) + Ch(_T[(4 - i) and 7], _T[(5 - i) and 7], _T[(6 - i) and 7]) + SHA256_K[i + j]);
    if (0 = j) then begin
      //
      _W[i] := data[i];
      inc(_T[(7 - i) and 7], _W[i]);
    end
    else begin
      //
      inc(_W[i and 15], s1(_W[(i - 2) and 15]) + _W[(i - 7)and 15] + s0(_W[(i - 15) and 15]) );
      inc(_T[(7 - i) and 7], _W[i and 15]);
    end;
    //
    inc(_T[(3 - i) and 7], _T[(7 - i) and 7]);
    inc(_T[(7 - i) and 7], _S0(_T[(0 - i) and 7]) + Maj(_T[(0 - i) and 7], _T[(1 - i) and 7], _T[(2 - i) and 7]));
  end;

begin
  // save
  move(s, _T, sizeof(_T));
  //
  j := 0;
  while (j < 64) do begin
    //
    R( 0); R( 1); R( 2); R( 3);
    R( 4); R( 5); R( 6); R( 7);
    R( 8); R( 9); R(10); R(11);
    R(12); R(13); R(14); R(15);
    //
    inc(j, 16);
  end;
  //
  // sum back
  inc(s[0], _T[0]);
  inc(s[1], _T[1]);
  inc(s[2], _T[2]);
  inc(s[3], _T[3]);
  inc(s[4], _T[4]);
  inc(s[5], _T[5]);
  inc(s[6], _T[6]);
  inc(s[7], _T[7]);
end;


// *************************************************************

procedure sha384Init(var s: HashWordType8x64);
begin
  s[0] := $cbbb9d5dc1059ed8;
  s[1] := $629a292a367cd507;
  s[2] := $9159015a3070dd17;
  s[3] := $152fecd8f70e5939;
  s[4] := $67332667ffc00b31;
  s[5] := $8eb44a8768581511;
  s[6] := $db0c2e0d64f98fa7;
  s[7] := $47b5481dbefa4fa4;
end;

procedure sha512Init(var s: HashWordType8x64);
begin
  s[0] := $6a09e667f3bcc908;
  s[1] := $bb67ae8584caa73b;
  s[2] := $3c6ef372fe94f82b;
  s[3] := $a54ff53a5f1d36f1;
  s[4] := $510e527fade682d1;
  s[5] := $9b05688c2b3e6c1f;
  s[6] := $1f83d9abfb41bd6b;
  s[7] := $5be0cd19137e2179;
end;

const
  SHA512_K: array[0..79] of uint64 = (
    $428a2f98d728ae22, $7137449123ef65cd,
    $b5c0fbcfec4d3b2f, $e9b5dba58189dbbc,
    $3956c25bf348b538, $59f111f1b605d019,
    $923f82a4af194f9b, $ab1c5ed5da6d8118,
    $d807aa98a3030242, $12835b0145706fbe,
    $243185be4ee4b28c, $550c7dc3d5ffb4e2,
    $72be5d74f27b896f, $80deb1fe3b1696b1,
    $9bdc06a725c71235, $c19bf174cf692694,
    $e49b69c19ef14ad2, $efbe4786384f25e3,
    $0fc19dc68b8cd5b5, $240ca1cc77ac9c65,
    $2de92c6f592b0275, $4a7484aa6ea6e483,
    $5cb0a9dcbd41fbd4, $76f988da831153b5,
    $983e5152ee66dfab, $a831c66d2db43210,
    $b00327c898fb213f, $bf597fc7beef0ee4,
    $c6e00bf33da88fc2, $d5a79147930aa725,
    $06ca6351e003826f, $142929670a0e6e70,
    $27b70a8546d22ffc, $2e1b21385c26c926,
    $4d2c6dfc5ac42aed, $53380d139d95b3df,
    $650a73548baf63de, $766a0abb3c77b2a8,
    $81c2c92e47edaee6, $92722c851482353b,
    $a2bfe8a14cf10364, $a81a664bbc423001,
    $c24b8b70d0f89791, $c76c51a30654be30,
    $d192e819d6ef5218, $d69906245565a910,
    $f40e35855771202a, $106aa07032bbd1b8,
    $19a4c116b8d2d0c8, $1e376c085141ab53,
    $2748774cdf8eeb99, $34b0bcb5e19b48a8,
    $391c0cb3c5c95a63, $4ed8aa4ae3418acb,
    $5b9cca4f7763e373, $682e6ff3d6b2b8a3,
    $748f82ee5defb2fc, $78a5636f43172f60,
    $84c87814a1f0ab72, $8cc702081a6439ec,
    $90befffa23631e28, $a4506cebde82bde9,
    $bef9a3f7b2c67915, $c67178f2e372532b,
    $ca273eceea26619c, $d186b8c721c0c207,
    $eada7dd6cde0eb1e, $f57d4f7fee6ed178,
    $06f067aa72176fba, $0a637dc5a2c898a6,
    $113f9804bef90dae, $1b710b35131c471b,
    $28db77f523047d84, $32caab7b40c72493,
    $3c9ebe0a15c9bebc, $431d67c49c100d4c,
    $4cc5d4becb3e42b6, $597f299cfc657e2a,
    $5fcb6fab3ad6faec, $6c44198c4a475817
  );

// --  --
procedure sha512Transform(var s: HashWordType8x64; data: pUint64Array);
var
  _W: array[0..15] of uint64;
  _T: array[0..7] of uint64;
  j: int;

  // --  --
  function Ch(x, y, z: uint64): uint64;{$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
  begin
    result := (z xor (x and (y xor z)));
  end;

  // --  --
  function Maj(x, y, z: uint64): uint64;{$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
  begin
    result := (y xor ((x xor y) and (y xor z)));
  end;

  // --  --
  function _S0(x: uint64): uint64; {$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
  begin
    result := ROTATE_RIGTH64(x, 28) xor ROTATE_RIGTH64(x, 34) xor ROTATE_RIGTH64(x, 39);
  end;

  // --  --
  function _S1(x: uint64): uint64; {$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
  begin
    result := ROTATE_RIGTH64(x, 14) xor ROTATE_RIGTH64(x, 18) xor ROTATE_RIGTH64(x, 41);
  end;

  // --  --
  function s0(x: uint64): uint64; {$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
  begin
    result := ROTATE_RIGTH64(x, 1) xor ROTATE_RIGTH64(x, 8) xor (x shr 7);
  end;

  // --  --
  function s1(x: uint64): uint64; {$IFDEF UNA_OK_INLINE }inline;{$ENDIF UNA_OK_INLINE }
  begin
    result := ROTATE_RIGTH64(x, 19) xor ROTATE_RIGTH64(x, 61) xor (x shr 6);
  end;

  // --  --
  procedure R(i: int);
  begin
    inc(_T[(7 - i) and 7], _S1(_T[(4 - i) and 7]) + Ch(_T[(4 - i) and 7], _T[(5 - i) and 7], _T[(6 - i) and 7]) + SHA512_K[i + j]);
    if (0 = j) then begin
      //
      _W[i] := swap64u(data[i]);
      inc(_T[(7 - i) and 7], _W[i]);
    end
    else begin
      //
      inc(_W[i and 15], s1(_W[(i - 2) and 15]) + _W[(i - 7) and 15] + s0(_W[(i - 15) and 15]) );
      inc(_T[(7 - i) and 7], _W[i and 15]);
    end;
    //
    inc(_T[(3 - i) and 7], _T[(7 - i) and 7]);
    //
    inc(_T[(7 - i) and 7], _S0(_T[(0 - i) and 7]) + Maj(_T[(0 - i) and 7], _T[(1 - i) and 7], _T[(2 - i) and 7]));
  end;

begin
  //* save
  move(s, _T, sizeof(_T));
  //
  j := 0;
  while (j < 80) do begin
    //
    R( 0); R( 1); R( 2); R( 3);
    R( 4); R( 5); R( 6); R( 7);
    R( 8); R( 9); R(10); R(11);
    R(12); R(13); R(14); R(15);
    //
    inc(j, 16);
  end;
  //
  // sum back
  inc(s[0], _T[0]);
  inc(s[1], _T[1]);
  inc(s[2], _T[2]);
  inc(s[3], _T[3]);
  inc(s[4], _T[4]);
  inc(s[5], _T[5]);
  inc(s[6], _T[6]);
  inc(s[7], _T[7]);
end;

{$IFDEF D_0F1E9BD78E8E462CBF710601B57495F1 }
  {$R+}
{$ENDIF D_0F1E9BD78E8E462CBF710601B57495F1 }
//
{$IFDEF D_8BDB211C53D54EADAB75BED8936C3F58 }
  {$Q+}
{$ENDIF D_8BDB211C53D54EADAB75BED8936C3F58}

// --  --
procedure sha512(data: pointer; len: uint64; out digest: HashWordType8x64);
var
  slen: uint64;
  buf: array[0..127] of byte;
begin
  sha512Init(digest);
  slen := len;
  //
  while (len >= 128) do begin
    //
    sha512Transform(digest, data);
    //
    inc(pByte(data), 128);
    dec(len, 128);
  end;
  //
  fillChar(buf, sizeof(buf), #0);
  if (0 < len) then
    move(data^, buf[0], len);
  //
  buf[len] := $80;
  if (len >= 112) then begin
    //
    sha512Transform(digest, pUint64Array(@buf));
    fillChar(buf, sizeof(buf), #0);
  end;
  //
  pUInt64(@buf[112])^ := swap64u(slen shr 60);
  pUInt64(@buf[120])^ := swap64u(slen shl 3);
  sha512Transform(digest, pUint64Array(@buf));
  //
  digest[0] := swap64u(digest[0]);
  digest[1] := swap64u(digest[1]);
  digest[2] := swap64u(digest[2]);
  digest[3] := swap64u(digest[3]);
  digest[4] := swap64u(digest[4]);
  digest[5] := swap64u(digest[5]);
  digest[6] := swap64u(digest[6]);
  digest[7] := swap64u(digest[7]);
end;

// --  --
function sha512(const data: aString; lowCase: bool): aString;
var
  digest: HashWordType8x64;
begin
  if ('' <> data) then
    sha512(@data[1], length(data), digest)
  else
    sha512(nil, 0, digest);
  //
  result := digest2str(@digest, sizeof(HashWordType8x64), lowCase);
end;


{$IFDEF UNA_MD5_SELFTEST }

// --  --
function selftest(): bool;
var
  pszNonce,
  pszCNonce,
  pszUser,
  pszRealm,
  pszPass,
  pszAlg,
  pszMethod,
  pszQop,
  pszURI: aString;
  //
  szNonceCount: array[0..8] of aChar;
  //
  HA1,
  HA2,
  Response: HASHHEX;
begin
  result := true;
  //
  try
    assert( (md5('', true) = 'd41d8cd98f00b204e9800998ecf8427e') and
	    (md5('a', true) = '0cc175b9c0f1b6a831c399e269772661') and
	    (md5('abc', true) = '900150983cd24fb0d6963f7d28e17f72') and
	    (md5('message digest', true) = 'f96b697d7cb7938d525a2f31aaf161d0') and
	    (md5('abcdefghijklmnopqrstuvwxyz', true) = 'c3fcd3d76192e4007dfb496cca67e13b') and
	    (md5('ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789', true) = 'd174ab98d277d9f5a5611c2c9f419d9f') and
	    (md5('12345678901234567890123456789012345678901234567890123456789012345678901234567890', true) = '57edf4a22be3c955ac49da2e2107b67a') and
	    true
	    ,
	   'MD5 self-test fail');
    //
    pszNonce := 'dcd98b7102dd2f0e8b11d0f600bfb0c093';
    pszCNonce := '0a4f113b';
    pszUser := 'Mufasa';
    pszRealm := 'testrealm@host.com';
    pszPass := 'Circle Of Life';
    pszAlg := 'md5';
    pszMethod := 'GET';
    pszQop := 'auth';
    pszURI := '/dir/index.html';
    szNonceCount := '00000001';
    HA2 := '';
    //
    DigestCalcHA1(pszAlg, pszUser, pszRealm, pszPass, pszNonce, pszCNonce, HA1);
    DigestCalcResponse(HA1, pszNonce, szNonceCount, pszCNonce, pszQop, pszMethod, pszURI, HA2, Response);
    //
    assert('939e7578ed9e3c518a452acee763bce9' = HA1, 'DigestCalcHA1() test fail');
    assert('6629fae49393a05397450978507c4ef1' = Response, 'DigestCalcResponse() test fail');
    //
    pszAlg := 'md5-sess';
    DigestCalcHA1(pszAlg, pszUser, pszRealm, pszPass, pszNonce, pszCNonce, HA1);
    //
    pszQop := 'auth-int';
    str2arrayA(md5('Mesasge Body', true), HA2);
    DigestCalcResponse(HA1, pszNonce, szNonceCount, pszCNonce, pszQop, pszMethod, pszURI, HA2, Response);
    //
    assert('71f45625a6e5fcdd072ce44e8e101a01' = HA1, 'DigestCalcHA1() test fail');
    assert('12d6b491f338f83f5accf239d61dcf5a' = Response, 'DigestCalcResponse() test fail');
    //
    assert('44E228D9FD5F042FDE160C10A38D05AD70C5822D53F5E000DF3021F286B8CC782AC3D1153D078D4C107D3893B78596BAA44478A9108F3837FADFB963FE3F10E1' = sha512('Lake of Soft'), 'sha512 test fail');
  except
    result := false;
  end;
end;

{$ENDIF UNA_MD5_SELFTEST }


end.

