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
	  unaTypes.pas
	----------------------------------------------
	  Copyright (c) 2001-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 25 Aug 2001

	  modified by:
		Lake, Sep-Dec 2001
		Lake, Jan-Dec 2002
		Lake, Jan-Dec 2003
		Lake, Sep 2005
		Lake, Jan-Apr 2007
		Lake, Dec 2009
		Lake, Jan-Jun 2011

	----------------------------------------------
*)

{$I unaDef.inc }

{$IFDEF DEBUG }
  {$IFDEF __AFTER_D5__ }
    {$IFDEF VC_HINT_COMPILE_MESSAGES }
      {$MESSAGE HINT 'VC_DEBUG_VERSION' }
    {$ENDIF VC_HINT_COMPILE_MESSAGES }
  {$ENDIF __AFTER_D5__ }
{$ENDIF DEBUG }


  //
  {$IFDEF __AFTER_D5__ }
    {$IFDEF VC_HINT_COMPILE_MESSAGES }
      {$MESSAGE HINT 'VC_ENTERPRISE' }
    {$ENDIF VC_HINT_COMPILE_MESSAGES }
  {$ENDIF __AFTER_D5__ }
  //
  {$IFDEF NO_ANSI_SUPPORT }
    //
    {$IFDEF __AFTER_D5__ }
      {$IFDEF VC_HINT_COMPILE_MESSAGES }
        {$MESSAGE HINT 'VC NO ANSI' }
      {$ENDIF VC_HINT_COMPILE_MESSAGES }
    {$ENDIF __AFTER_D5__ }
    //
    {$DEFINE VC25_OVERLAPPED }      // enable overlapped calls
    {$DEFINE VC25_WINSOCK20 }       // enable WinSock 2.0 extensions
    //
    {$IFDEF FPC }
    {$ELSE }
      {$IFDEF VC25_OVERLAPPED }
        //
        {$IFDEF __AFTER_D5__ }
          {$IFDEF VC_HINT_COMPILE_MESSAGES }
            {$MESSAGE HINT 'VC_IOCP' }
          {$ENDIF VC_HINT_COMPILE_MESSAGES }
        {$ENDIF __AFTER_D5__ }
        //
	{$DEFINE VC25_IOCP }            // enable IOCP calls
	//
      {$ENDIF VC25_OVERLAPPED }
    {$ENDIF FPC }
  {$ELSE }
    //
    {$IFDEF __AFTER_D5__ }
      {$IFDEF VC_HINT_COMPILE_MESSAGES }
        {$MESSAGE HINT 'VC ANSI OK' }
      {$ENDIF VC_HINT_COMPILE_MESSAGES }
    {$ENDIF __AFTER_D5__ }
    //
  {$ENDIF NO_ANSI_SUPPORT }
  //

{*

  Contains definition of base types used in other units.
  Most used types are:
    int = int32/64 depending on target CPU
    bool = LongBool
    unsigned = Cardinal

  @Author Lake

  Version 2.5.2009.12 - some cleanup
}


unit
  unaTypes;

interface

type
{$IFDEF __BEFORE_D4__ }	// before Delphi 4.0
  longword = cardinal;
{$ENDIF __BEFORE_D4__ }

// signed 8 bits integer
  int8		= shortint;	
// signed 16 bits integer
  int16		= smallint;	
// signed 32 bits integer
  int32		= longint;	

// unsigned 8 bits integer
  uint8		= byte;		
// unsigned 16 bits integer
  uint16	= word;		
// unsigned 32 bits integer
  uint32	= longword;	
  {$IFNDEF CPU64 }
    {$IFDEF __BEFORE_D9__}
// NOTE: Delphi up to version 7 has no built-in support for unsigned 64-bit integers
    uint64	= int64;	
    {$ENDIF __BEFORE_D9__}
  {$ENDIF CPU64 }

  {*
	unsigned 64 bits integer type defined as two double words record
  }
  uint64Rec	= record
// low double word of unsigned 64 bits integer
    lo,			
// high double word of unsigned 64 bits integer
    hi: uint32;		
  end;

// universal 32 bit unsigned integer
  uint  = LongWord;     

  {$EXTERNALSYM unsigned }
// pointer to value of type "unsigned"
  pUnsigned 	= ^unsigned;	
  {$IFDEF __AFTER_DE__ }
// general unsigned integer type, 32 or 64 or more bits depending on compiler
  unsigned 	= NativeUInt;   
  {$ELSE }
// general unsigned integer type, 32 or 64 or more bits depending on compiler
    {$IFDEF CPU64 }
      unsigned 	= uint64;     
    {$ELSE }
      unsigned 	= Cardinal;   
    {$ENDIF CPU64 }
  {$ENDIF __AFTER_DE__ }

// general signed integer type, 32 or 64 or more bits depending on compiler
  {$IFDEF __AFTER_DE__ }
    int = NativeInt;	
  {$ELSE }
    {$IFDEF CPU64 }
    int = int64;	
    {$ELSE }
    int = LongInt;	
    {$ENDIF CPU64 }
  {$ENDIF __AFTER_DE__ }


  {$EXTERNALSYM int }
// pointer to a value of type "int"
  pInt = ^int;		
  {$IFDEF CPU64 }
    //
    {$IFDEF FPC }
      IntPtr = PtrInt;
      UIntPtr = PtrUInt;
    {$ELSE }
    // IntPtr and UIntPtr are defined in System.pas
    {$ENDIF FPC }
  {$ELSE }
    IntPtr = int;
    UIntPtr = unsigned;
  {$ENDIF CPU64 }

  {$EXTERNALSYM PLONG }
  {$EXTERNALSYM LONG }
// pointer to type LONG (int)
  PLONG = ^LONG;	
// another name for type "int"
  LONG = int;		

  {$EXTERNALSYM bool }
  {$IFDEF FPC }
// got some problems with LongBool under FPC64 (as of 2.4.2)
  bool = boolean;	
  {$ELSE }
// general boolean type, 32 (or 64?/more?) bits (depending on compiler?). Defined in System.pas
  bool = LongBool;	
  {$ENDIF FPC }

// pointer to signed 8 bits integer value
  pInt8		= ^int8;	
// pointer to signed 16 bits integer value
  pInt16	= ^int16;	
// pointer to signed 32 bits integer value
  pInt32	= ^int32;	
  {$IFNDEF CPU64 }
// pointer to signed 64 bits integer value
  pInt64	= ^int64;	
  {$ENDIF CPU64 }

// pointer to unsigned 8 bits integer value
  pUint8	= ^uint8;	
// pointer to unsigned 16 bits integer value
  pUint16	= ^uint16;	
// pointer to unsigned 32 bits integer value
  pUint32	= ^uint32;	
// pointer to unsigned 64 bits integer value
  pUint64	= ^uint64;	

  //
  {$EXTERNALSYM float }
// single precision floating-point (4 bytes)
  float		= single;	
  pFloat	= ^float;	

// ansi string (1 char = 1 byte)
  aString       = AnsiString;   
// ansi char (1 byte)
  aChar         = AnsiChar;     

// unicode string
{$IFDEF __AFTER_DB__ }
  wString       = string;       
// unicode char
  wChar         = char;         
{$ELSE }
// wide string
  wString       = wideString;   
{$IFNDEF FPC }
// wide char
  wChar         = wideChar;     
{$ENDIF FPC }
{$ENDIF __AFTER_DB__ }
  
{$IFDEF __AFTER_DB__ }
// pointer to ansi char
  paChar        = pAnsiChar;            
// pointer to unicode char
  pwChar        = pChar;                
{$ELSE }
// pointer to ansi char
  paChar        = pChar;                
// pointer to wide char
  pwChar        = pWideChar;            
{$ENDIF __AFTER_DB__ }

{$IFDEF __BEFORE_DC__ }
  waChar = wChar;
  waString = wString;
{$ELSE }
  waChar = aChar;
  waString = aString;
{$ENDIF __BEFORE_DC__ }
  pwaChar = ^waChar;

{$IFDEF __BEFORE_DB__ }
  {$IFDEF CPU64 }
  {$ELSE }
  DWORD_PTR  = uint32;
  {$ENDIF CPU64 }
{$ENDIF __BEFORE_DB__ }

// used as a counter to lock an object
  unaAcquireType = int;	

const
  c_max_memBlock	= $7FFFFFFF;
  //
  c_max_index_08	= c_max_memBlock;
  c_max_index_16	= c_max_memBlock shr 1;
  c_max_index_32	= c_max_memBlock shr 2;
  c_max_index_64	= c_max_memBlock shr 3;
  c_max_index_80	= c_max_memBlock div 10;
  c_max_index_PTR	= c_max_memBlock div sizeOf(pointer);
  //
  c_isDebug		= {$IFDEF DEBUG }true{$ELSE }false{$ENDIF DEBUG };

type
  {$IFDEF __BEFORE_D6__ }
  pByte = ^byte;
  {$ENDIF __BEFORE_D6__ }

// array of bytes (unsigned 8 bits integer values)
  tArray = array[0 .. c_max_index_08 - 1] of byte;	
// pointer to array of bytes (unsigned 8 bits integer values)
  pArray = ^tArray;					

// array of 1-byte chars
  taCharArray = array[0 .. c_max_index_08 - 1] of aChar;	
// pointer to array of 1-byte chars
  paCharArray = ^taCharArray;					

// array of 2-bytes chars
  twCharArray = array[0 .. c_max_index_16 - 1] of wChar;	
// pointer to array of 2-bytes chars
  pwCharArray = ^twCharArray;					

// array of signed 8 bit integers
  tInt8Array = array[0 .. c_max_index_08 - 1] of int8;	
// pointer to array of signed 8 bit integers
  pInt8Array = ^tInt8Array;				

// array of unsigned 8 bits integer values
  tUint8Array = tArray;					
// pointer to array of unsigned 8 bits integer values
  pUint8Array = ^tUint8Array;				

// array of signed 16 bit integers
  tInt16Array = array[0 .. c_max_index_16 - 1] of int16;	
// pointer to array of signed 16 bit integers
  pInt16Array = ^tInt16Array;					

// array of signed 16 bit integers
  tUint16Array = array[0 .. c_max_index_16 - 1] of uint16;	
// pointer to array of signed 16 bit integers
  pUint16Array = ^tUint16Array;					

// array of signed 32 bit integers
  tInt32Array  = array[0 .. c_max_index_32 - 1] of int32;	
// pointer to array of signed 32 bit integers
  pInt32Array = ^tInt32Array;					

// array of unsigned 32 bit integers
  tUint32Array  = array[0 .. c_max_index_32 - 1] of uint32;	
// pointer to array of unsigned 32 bit integers
  pUint32Array = ^tUint32Array;					

// array of signed 64 bit integers
  tInt64Array  = array[0 .. c_max_index_64 - 1] of int64;	
// pointer to array of signed 64 bit integers
  pInt64Array = ^tInt64Array;                           	

// array of unsigned 64 bit integers
  tUint64Array  = array[0 .. c_max_index_64 - 1] of uint64;	
// pointer to array of signed 64 bit integers
  pUint64Array = ^tUint64Array;                           	

// array of unsigned 32/64 bit integers
  tUnsignedArray  = array[0 .. c_max_index_PTR - 1] of unsigned;
// pointer to array of unsigned 32/64 bit integers
  pUnsignedArray = ^tUnsignedArray;                           	

// array of pointers (32/64/more bits integers)
  tPtrArray = array [0 .. c_max_index_PTR - 1] of pointer;	
// pointer to array of pointers (32/64/more bits integers)
  pPtrArray = ^tPtrArray;					

// array of paChars
  tPaCharArray = array [0 .. c_max_index_PTR - 1] of paChar;	
// pointer to array of paChars
  pPaCharArray = ^tPaCharArray;					

// array of pwChars
  tPwCharArray = array [0 .. c_max_index_PTR - 1] of pwChar;	
// pointer to array of pwChars
  pPwCharArray = ^tPwCharArray;					

// array of single precision floating-point (4 bytes) values
  tSingleArray  = array[0 .. c_max_index_32 - 1] of single;	
// pointer to array of single precision floating-point (4 bytes) values
  pSingleArray = ^tSingleArray;					

// array of single precision floating-point (4 bytes) values
  tFloatArray  = tSingleArray;				
// pointer to array of single precision floating-point (4 bytes) values
  pFloatArray = ^tFloatArray;				
  
// array of pointers to arrays of single precision floating-point (4 bytes) values
  tFloatArrayPArray = array[0 .. c_max_index_PTR - 1] of pFloatArray;		
// pointer to array of pointers to arrays of single precision floating-point (4 bytes) values
  pFloatArrayPArray = ^tFloatArrayPArray;					

// array of double precision floating-point (8 bytes) values
  tDoubleArray  = array[0 .. c_max_index_64 - 1] of double;	
// pointer to array of double precision floating-point (8 bytes) values
  pDoubleArray = ^tDoubleArray;					

// array of extended floating-point (10 bytes) values
  tExtendedArray  = array[0 .. c_max_index_80 - 1] of extended;	
// pointer to array of extended floating-point (10 bytes) values
  pExtendedArray = ^tExtendedArray;				

  {*
	Complex single float
  }
  pComplexFloat = ^tComplexFloat;
  tComplexFloat = record
    re: float;
    im: float;
  end;
  {*
	Complex double float
  }
  pComplexDouble = ^tComplexDouble;
  tComplexDouble = record
    re: double;
    im: double;
  end;

  //
  pComplexFloatArray = ^tComplexFloatArray;
  tComplexFloatArray = array[0..c_max_memBlock div sizeof(tComplexFloat) - 1] of tComplexFloat;

  //
  pComplexDoubleArray = ^tComplexDoubleArray;
  tComplexDoubleArray = array[0..c_max_memBlock div sizeof(tComplexDouble) - 1] of tComplexDouble;

  // timeout type, currently is signed integer
  //
  tTimeout = int;	// INFINITE will be passed as -1

const
{$IFDEF FPC }
// Not so wide version of RT_RCDATA
  RT_RCDATAW = #10;			
{$ELSE }
// Wide version of RT_RCDATA
  RT_RCDATAW = pWideChar(#10);		
{$ENDIF }

implementation

initialization

end.

