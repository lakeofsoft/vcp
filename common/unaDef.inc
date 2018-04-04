
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

	  unaDef.inc
	  compiler options and conditional defines

	----------------------------------------------
	  Copyright (c) 2001-2011 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, Apr 2001

	  modified by:
		Lake, Jan-Oct 2002
		Lake, Jan-Jul 2003
		Lake, Sep-Dec 2005
		Lake, Dec 2007
		Lake, Jan-Dec 2010
		Lake, May 2011

	----------------------------------------------
*)

{xx $DEFINE DEBUG       }      	// debug version
{xx $DEFINE UNA_SERVICE }	// service module
{xx $DEFINE FMX         }       // FireMonkey

{$IFDEF UNA_NEED_ANSI }
{$ELSE }
  {$DEFINE NO_ANSI_SUPPORT }	// undefine this symbol if you do need support for ANSI version of Windows API (Win9x)
{$ENDIF UNA_NEED_ANSI }


  //
  {$IFDEF NO_ANSI_SUPPORT }
    //
    {$DEFINE VC25_OVERLAPPED }      // enable overlapped calls
    {$DEFINE VC25_WINSOCK20 }       // enable WinSock 2.0 extensions
    //
    {$IFDEF FPC }
    {$ELSE }
      {$IFDEF VC25_OVERLAPPED }
	{$DEFINE VC25_IOCP }            // enable IOCP calls
      {$ENDIF VC25_OVERLAPPED }
    {$ENDIF FPC }
    //
  {$ENDIF NO_ANSI_SUPPORT }

// --  --

{$I delphi_versions.inc }

// --  --

{$IFDEF DEBUG }

  //=================
  // DEBUG OPTIONS
  //=================

  {$IFDEF VER90 }          // Delphi 2.0
  {$ELSE }

    {$IFDEF FORCE_OPTIMIZATION }
      // override optimization options
      {$ASSERTIONS OFF }
      //
    {$ELSE}
      //
      {$ASSERTIONS ON }		// $C+
      //			// generation of assersion code (affects binary code)
    {$ENDIF FORCE_OPTIMIZATION }

    {$IFDEF VER100 }         // Delphi 3.0
    {$ELSE }
      //
      {$IFDEF VER110 }         // CBuilder 3.0
      {$ELSE }
	{$IFDEF FPC }
	{$ELSE }
	  {$DEFINITIONINFO ON }	// $YD
				// generation of symbol reference information
	{$ENDIF FPC }
      {$ENDIF VER110 }
      //
    {$ENDIF VER100 }
    //
  {$ENDIF VER90 }

  {$DEBUGINFO ON }      // $D+ generation of debug info

  {$IFNDEF FPC }
    {$LOCALSYMBOLS ON }	// $L+ generation of local symbol information
    {$REFERENCEINFO ON }	// $Y+ generation of symbol reference information
  {$ENDIF FPC }

  {$IFDEF FORCE_OPTIMIZATION }
    //
    // override optimization options
    {$IOCHECKS OFF }
    {$OPTIMIZATION ON }
    {$OVERFLOWCHECKS OFF }
    {$RANGECHECKS OFF }
    {$STACKFRAMES OFF }
  {$ELSE}
    {$IOCHECKS ON }		// $I+ generation of checking I/O results code (affects binary code)
    {$OPTIMIZATION OFF }	// $O- turn off optimization (affects binary code)
    {$OVERFLOWCHECKS ON }	// $Q+ generation of overflow checking code (affects binary code)
    {$RANGECHECKS ON }		// $R+ generation of range-checking code (affects binary code)
    {$STACKFRAMES ON }		// $W+ generation of stack frames for procedures and functions (affects binary code)
  {$ENDIF FORCE_OPTIMIZATION }

  {$IFNDEF NO_VC_HINT_COMPILE_MESSAGES }
    {$DEFINE VC_HINT_COMPILE_MESSAGES }  // show some compile hints
  {$ENDIF  NO_VC_HINT_COMPILE_MESSAGES }

{$ELSE }

  //=================
  // RELEASE OPTIONS
  //=================

  {$DEFINE RELEASE }

  {$IFDEF VER90 }    // Delphi 2.0
  {$ELSE }
    {$ASSERTIONS OFF }	// $C-
			// generation of assersion code (affects binary code)
    {$IFDEF VER100 }         // Delphi 3.0
    {$ELSE }
      {$IFDEF VER110 }         // CBuilder 3.0
      {$ELSE }
	//
	{$IFDEF FPC }
	{$ELSE }
	  {$DEFINITIONINFO OFF }  // $Y-
				  // disallow generation of symbol reference information
	{$ENDIF FPC }
      {$ENDIF }
    {$ENDIF }
  {$ENDIF }

  {$IFNDEF FPC }
    {$LOCALSYMBOLS OFF }	// $L- generation of local symbol information
    {$REFERENCEINFO OFF }	// $Y- generation of symbol reference information
  {$ELSE }
    {$DEFINE NO_UNA_DESCR }
  {$ENDIF FPC }

  {$DEBUGINFO OFF }     // $D- no debug info
  {$OPTIMIZATION ON }	// $O+ turn on optimization (affects binary code)
  {$IOCHECKS OFF }	// $I- generation of checking I/O results code (affects binary code)
  {$OVERFLOWCHECKS OFF }// $Q- generation of overflow checking code (affects binary code)
  {$RANGECHECKS OFF }	// $R- generation of range-checking code (affects binary code)
  {$STACKFRAMES OFF }	// $W- generation of stack frames for procedures and functions (affects binary code)
{$ENDIF }


// COMMON (RELEASE and DEBUG) options

{$IFDEF FPC }
{$ELSE }
  {$E-}	// ?
  {$F-}	// ?
  {$K-}	// ?
  {$N-} // ?
{$ENDIF FPC }

{$S-} // ?

// -- common --

{$IFDEF VER90 }          // Delphi 2.0
{$ELSE}

  {$IFDEF FPC }
  {$ELSE }
    {$IMPORTEDDATA ON }	// $G+ turn on creation of imported data references
			// NOTE: C++ Builder ?.0 crashes when installing packages compiled with $G-
  {$ENDIF FPC }

  {$IFDEF VER100 }         // Delphi 3.0
  {$ELSE }
    {$IFDEF VER110 }         // CBuilder 3.0
    {$ELSE }

      {$IFDEF FPC }
      {$ELSE }
        {$REALCOMPATIBILITY OFF }	// Real type is equivalent to Double
      {$ENDIF FPC }

    {$ENDIF VER110 }
  {$ENDIF VER100 }
{$ENDIF VER90 }

{$A+ }		        // $A+ align records to 8/16 boundaries (unless packed modifier is specified)
{$BOOLEVAL OFF }        // $B- turn off full boolean evaluation
			// WARNING! turning is option on will introduce certain access violations
{$IFDEF FPC }
  {$LONGSTRINGS ON }	// $H+ turn on long string support
{$ELSE }
  {$SAFEDIVIDE OFF }	// $U- turn off guards against the flawed FDIV instruction exhibited by certain early Pentium processors
{$ENDIF FPC }

{$WRITEABLECONST OFF }	// $J- turn off writeable const
{$TYPEINFO OFF }	// $M- turn off RTTI (when possible)

{$IFDEF __AFTER_D24__}
  {$TYPEDADDRESS OFF }	// $T- turn off typed pointers for XE4 and later
{$ELSE}
  {$TYPEDADDRESS ON }	// $T+ turn on typed pointers
{$ENDIF __AFTER_D24__ }

{$EXTENDEDSYNTAX ON }   // $X+ turn on extended syntax
{$MINENUMSIZE 4 }	// $Z+ or $Z4 set enum element size to 4 bytes

{$IFDEF __AFTER_DC__ }
  {xx $RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])} // ends up in internal error :)
  {$WEAKLINKRTTI ON}
{$ENDIF __AFTER_DC__ }

{$P+}	// short string? who still needs them..
{$V+}	// short string? who still needs them..



{$IFDEF __AFTER_D7__ }
  {$IFDEF DEBUG }
  {$ELSE }
    //
    {$DEFINE UNA_OK_INLINE }	// inline is OK after Delphi 7, but it is bad for debugging
    //
  {$ENDIF DEBUG }
{$ENDIF __AFTER_D7__ }

{$IFDEF __AFTER_D9__ }
  {$IFDEF DEBUG }
  {$ELSE }
    //
    {$DEFINE UNA_OK_INLINE9 }	// some inlines are OK only after Delphi 2006
    //
  {$ENDIF DEBUG }
{$ENDIF __AFTER_D9__ }


{$IFDEF CPUX64 }	// defined by dcc64 only
  {$DEFINE CPU64 }
{$ENDIF CPUX64 }

{$IFDEF WIN64 }		// defined by dcc64 only
  {$DEFINE CPU64 }
{$ENDIF CPUX64 }

{$IFDEF FPC }
  {$MODE DELPHI }
  {$ASMMODE Intel }
  {$DEFINE VER170 }
  {$DEFINE __STRANSI__ }
  //
  {$IFDEF CPU64 }
    {$DEFINE FPC64 }
  {$ENDIF CPU64 }
{$ENDIF FPC }

