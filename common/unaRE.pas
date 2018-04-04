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
	  unaRE.pas
	  RE - regular expressions
	----------------------------------------------
	  Copyright (c) 2011-2012 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 23 Dec 2011

	  modified by:
		Lake, Jan 2012

	----------------------------------------------
*)

{$I unaDef.inc }

{$IFDEF __AFTER_DD__ }
  {x $DEFINE UNARE_INCLUDE_PCRE }		// include PCRE wrapper
{$ENDIF __AFTER_DD__ }

{$DEFINE UNARE_STRICT_1003 }		// stay compatible with IEEE Std 1003.1

{$IFDEF DEBUG }
  {x $DEFINE UNARE_LOG_RARSER }		// log parsed REs
{$ENDIF DEBUG }

{*
	RE [ IEEE Std 1003.1 ]
	http://pubs.opengroup.org/onlinepubs/009695399/basedefs/xbd_chap09.html

	@Author Lake

	Version 2.5.2011.12 First release

	Version 2.5.2012.01 - some fixes of * handling
}

unit
  unaRE;

interface

uses
  Windows, unaTypes, unaClasses;

const
  RE_DUP_MAX 		= maxInt;	// max count of elements for * exp
  //
  unaRE_error_OK	=  0;	// no error
  unaRE_error_noMatch	= -1;	// no match found
  //
  unaRE_error_sroot	= -4;	// rare error in sroot		(should not happen, consider as internal error)
  unaRE_error_srootExp	= -5;	// root must be a subexpression	(should not happen, consider as internal error)
  unaRE_error_mm	= -10;	// general error in {}
  unaRE_error_mmOrder	= -11;	// min/max out of order in {}
  unaRE_error_escape	= -12;	// unknown escape
  unaRE_error_backref	= -13;	// wrong backref
  unaRE_error_escape2	= -14;	// out of escape chars
  unaRE_error_emptySeq	= -15;	// sequence is empty


{$IFDEF UNARE_INCLUDE_PCRE }

{*
	@subject text to find the match in
	@regexp regular expression
	@param startFrom start lookup from this position
	@return position of new match or rises an exception in case of some error
}
function match_PCRE(const subject, regexp: string; out matchlen: int; startFrom: int = 1): int;

{$ENDIF UNARE_INCLUDE_PCRE }


{*
	Parses regexp.
	Don't forget to dispose the result with disposeEA()

	@param startFrom start lookup from this position

	@return unaRE_error_OK, or one of unaRE_error_XXX error codes
}
function parse(const regexp: wString; var ea: pointer): int; overload;

{*
	Releases memory taken by parsed expression
}
procedure disposeEA(var ea: pointer);

{*
	Looks for first match from specified position.

	@param subject text to find the match in
	@param regexp regular expression
	@param startFrom start lookup from this position (from 1 to length(subject) )

	@return position of new match, or one of unaRE_error_XXX error codes
}
function rematch(const subject, regexp: wString; out matchlen: int; startFrom: int = 1): int; overload;

{*
	Looks for first match from specified position.

	@param subject text to find the match in
	@param regexp regular expression
	@param startFrom start lookup from this position (from 1 to length(subject) )

	@return first match, or empty string
}
function rematch(startFrom: int; const subject, regexp: wString): string; overload;

{*
	Looks for first match from specified position.

	@param ea parsed regexp (use parse() to receive it)
	@param subject text to find the match in
	@param startFrom start lookup from this position (from 1 to length(subject) )

	@return position of new match, or one of unaRE_error_XXX error codes
}
function rematch(ea: pointer; const subject: wString; out matchlen: int; startFrom: int = 1): int; overload;

{*
	Replaces first or all matches with substitution, which can include backrefs.

	@param subject text to find the match and replace in
	@param regexp regular expression
	@param substitution replace any matches with that (may include backrefs)
	@param startFrom start lookup from this position (from 1 to length(subject) )
	@param global repeat replacement for whole string

	@return resulting string
}
function replace(const subject, regexp, substitution: wString; startFrom: int = 1; global: bool = false): wString; overload;

{*
	Replaces first or all matches with substitution, which can include backrefs.

	@param ea parsed regular expression (use parse() to receive it from regexp string)
	@param subject text to find the match and replace in
	@param substitution replace any matches with that (may include backrefs)
	@param startFrom start lookup from this position (from 1 to length(subject) )
	@param global repeat replacement for whole string

	@return resulting string
}
function replace(ea: pointer; const subject, substitution: wString; startFrom: int = 1; global: bool = false): wString; overload;


type
  {*
	RegExp utility class.
  }
  unaRegExp = class(unaObject)
  private
    f_regexp: wString;
    f_subj: wString;
    //
    f_ea: pointer;
    f_error: int;
    //
    f_lookupPos: int;
    //
    procedure setRegexp(const value: wString);
    procedure setSubj(const value: wString);
  public
    {*
	Creates a new class for regexp.
    }
    constructor create(const regexp: wString);
    {*
	Releases regexp resources.
    }
    destructor Destroy(); override;
    {*
	Returns first match.
	Updates lookupPos property if new non-empty subject was specified or match was found.
	Also updates subj property if new non-empty subject was specified.

	@param subject source to find match in. If not specified ('') will use subj property instead
	@param startFrom start lookup from this position. If not specified (-1), value of lookupPos property will be used instead

	@return first match or empty string if no match found
    }
    function match(const subject: wString = ''; startFrom: int = -1): wString; overload;
    {*
	Returns first match position and length.
	Updates lookupPos property if match was found, new non-empty subject was specified or startFrom was specified.
	Also updates subj property if new non-empty subject was specified.

	@param len [OUT] match length
	@param subject source to find match in. If not specified ('') will use subj property instead
	@param startFrom start lookup from this position. If not specified (-1), value of lookupPos property will be used instead

	@return first match position, 0 if no match was found or one of unaRE_error_XXX if regexp is incorrect
    }
    function match(out len: int; const subject: wString = ''; startFrom: int = -1): int; overload;
    {*
	Replaces first or all matches with substitution, which can also include backrefs.

	@param substitution replace any matches with that string (may include backrefs)
	@param subject text to find the match and replace in. If not specified ('') will use subj property instead
	@param startFrom start lookup from this position. If not specified (-1), value of lookupPos property will be used instead
	@param global repeat replacement for the whole subject

	@return resulting string
    }
    function replace(const substitution: wString; const subject: wString = ''; startFrom: int = -1; global: bool = false): string;
    //
    {*
	Regexp to use.
    }
    property regexp: wString read f_regexp write setRegexp;
    {*
	Subject to use.
    }
    property subj: wString read f_subj write setSubj;
    {*
	Starting position for a lookup.
    }
    property lookupPos: int read f_lookupPos write f_lookupPos;
    {*
	Regexp error code, unaRE_error_OK means no error
    }
    property error: int read f_error;
  end;


implementation


uses
  unaUtils
{$IFDEF UNARE_INCLUDE_PCRE }
  , RegularExpressionsCore
{$ENDIF UNARE_INCLUDE_PCRE }
  ;


{$IFDEF UNARE_INCLUDE_PCRE }

// --  --
function match_PCRE(const subject, regexp: string; out matchlen: int; startFrom: int): int;
var
  exp: TPerlRegEx;
begin
  exp := TPerlRegEx.Create();
  try
    exp.Subject := utf8string(subject);
    exp.RegEx := utf8string(regexp);
    exp.Start := startFrom;
    //
    if (exp.MatchAgain()) then begin
      //
      matchlen := exp.MatchedLength;
      result := exp.MatchedOffset;
    end
    else
      result := -1;
  finally
    exp.Free();
  end;
end;

{$ENDIF UNARE_INCLUDE_PCRE }

(*

ALPHANUM:
	A..Z, a..z, 0..9	= match themself

DOT:
	.			= match any char

REPEAT (must appear after some element to be repeated):
	?			= 0 or 1 char ( equal to {0, 1} )
	+			= 1 or more chars ( equal to {1, } )
	*			= 0 or more chars ( equal to {0, } )
	{n,}			= n or more chars
	{,m}			= 0 or more chars, up to m
	{n,m}			= n or more chars, up to m
	{n}			= exactly n chars


ASSERSIONS:
	^			= beginning of the line
	$			= end of the line
	<			= beginning of a word
	>			= end of a word

Subexpression:
	(exp) 			= exp is subexpression

Sequences:
	[seq]			= seq is matching sequence
	[^seq]			= seq is non-mathcing sequence
	[ [.SYM.] ]		= collating SYM


Shortcuts:
	\d			= a digit [0-9]
	\D			= a non-digit [^0-9]
	\w			= a word (alphanumeric) [a-zA-Z0-9]
	\W			= a non-word [^a-zA-Z0-9]
	\s			= a whitespace [ \t\n\r\f ]
	\S			= a non-whitespace [^ \t\n\r\f ]

Backref:
	\N			= back reference to subexp #N (N from 1 to 9)


Examples:
	[][.-.]-0]		= matches either a right bracket or any character or collating element that collates between hyphen and 0
*)

type
  EType = (
	et_char,		// single character
	et_anychar,		// any single character
	et_charset,		// set of character
	et_anchor_L,		// anchor, start/end of line
{$IFDEF UNARE_STRICT_1003 }
{$ELSE }
	et_anchor_W,		// anchor, start/end of word
{$ENDIF UNARE_STRICT_1003 }
	et_ref,			// reference to sub-expression
	et_emptystr,		// empty string, as in "a(bc|)"
	et_subexp		// subexpression
  );


  {*
	Single expression with optional link to next one
  }
  pE = ^E;
  E = record
    //
    r_repeatMin: int32;	// from 0 to RE_DUP_MAX
    r_repeatMax: int32;	// from 0 to RE_DUP_MAX
    r_not      : bool;		// not this char, or not char in set
    //
    r_nextIndex: int32;	// points to next expression in subexp, or nil otherwise
    //
    r_fitAt    : int32;		// where this element fits
    r_eatsMin  : int32;		// how many chars this exp will consume
    r_eatsMax  : int32;		// how many chars this exp can consume
    //
    case r_type: EType of

      // single character
      et_char		: (r_char	: wChar);

      // sequence or [not] set of characters
      et_charset	: (r_charset	: pwChar);

      // any single character
      et_anychar	: ();

      // backref
      et_ref		: (r_refIndex   : int32);

      // reference to subexpression
      et_subexp		: (r_refnum	: int32;		// # of ref
			   r_alt	: pInt32Array;		// array of alt parts
			   r_altc	: int32;		// number of alternatives
			   r_altFitIndex: int32;		// index of selected alternative
			  );
  end;
  //
  pEA 	= ^EA;
  EA 	= record
    //
    // NOTE!! If you add/remove any fields below, make sure you visit the addE() local routine in parse() function below
    r_c: int32;
    r_foundSome: bool;
    // NOTE!! If you add/remove any fields above, make sure you visit the addE() local routine in parse() function below
    //
    r_a: array[word] of E;
  end;


// -- parses regexp --
function parse(const regexp: wString; var ea: pEA; var regexpos: int; var subCount: int; subExp: bool = false; childOf: int32 = 0): int; overload;

var
  // subexp root and alternatives
  srootIndex, altIndex, prevIndex: int;

  // --  --
  procedure markRef(ref: int);
  begin
    if ((0 <= prevIndex) and (0 <= altIndex)) then
      ea.r_a[prevIndex].r_nextIndex := ref;	// add self as next to prev expression
    //
    if ((0 > altIndex) and (0 <= srootIndex)) then begin
      //
      // new alternative
      altIndex := ref;
      //
      inc(ea.r_a[srootIndex].r_altc);
      mrealloc(ea.r_a[srootIndex].r_alt, sizeof(pE) * ea.r_a[srootIndex].r_altc);
      ea.r_a[srootIndex].r_alt[ea.r_a[srootIndex].r_altc - 1] := altIndex;
    end;
    //
  end;

  // --  --
  function addE(t: EType; const chars: wString = ''; min: int = 1; max: int = 1; _not: bool = false): int;
  var
    exp: pE;
    c: int;
  begin
    if (nil = ea) then
      c := 0
    else
      c := ea.r_c;
    //
    result := c;
    inc(c);
    mrealloc(ea, sizeof(ea.r_c) + sizeof(ea.r_foundSome) + c * sizeof(ea.r_a[0]));
    ea.r_c := c;
    //
    exp := @ea.r_a[result];
    //
    fillChar(exp^, sizeof(exp^), #0);
    exp.r_repeatMin := min;
    exp.r_repeatMax := max;
    exp.r_not := _not;
    //
    exp.r_type := t;
    case (t) of
      et_char		: exp.r_char := chars[1];
      et_charset	: exp.r_charset := {$IFDEF __BEFORE_D6__ }strNewW(chars){$ELSE }strNew(chars){$ENDIF __BEFORE_D6__ };
      et_subexp         : exp.r_altFitIndex := -1;
    end;
    //
    markRef(result);
    //
    prevIndex := result;
  end;

  // --  --
  procedure modifyPrev(min: int = 0; max: int = 1);
  begin
    if (0 < prevIndex) then begin
      //
      ea.r_a[prevIndex].r_repeatMin := min;
      ea.r_a[prevIndex].r_repeatMax := max;
    end;
  end;

var
  ch, seqChF, seqChL, seqCh: wChar;
  i, p, min, max, ref: int;
  minFound, _not, atb: bool;
  error: int;
  seq, seqRange: wString;
begin
  error := unaRE_error_OK;
  //
  prevIndex := -1;		// no prev exp on this level
  srootIndex := -1;		// start new subexpression
  altIndex := -1;		// start new alternative
  srootIndex := addE(et_subexp);
  if (0 <= srootIndex) then
    ea.r_a[srootIndex].r_refnum := subCount	// subindex index
  else
    error := unaRE_error_sroot;	// rare error in sroot
  //
  while ((unaRE_error_OK = error) and (regexpos <= length(regexp))) do begin
    //
    ch := regexp[regexpos];
    inc(regexpos);
    case (ch) of

      '.': addE(et_anychar);

      '?': modifyPrev();		// {0, 1}

      '+': modifyPrev(1, RE_DUP_MAX);	// {1, RE_DUP_MAX}

      '*': modifyPrev(0, RE_DUP_MAX);	// {0, RE_DUP_MAX}

      '^': addE(et_anchor_L);

      '$': addE(et_anchor_L, '', 1, 1, true);

{$IFDEF UNARE_STRICT_1003 }
{$ELSE }
      '<': addE(et_anchor_W);

      '>': addE(et_anchor_W, '', 1, 1, true);

{$ENDIF UNARE_STRICT_1003 }

      '{': begin
	//
	// parse {m,n}
	min := 0;
	max := 0;
	minFound := false;
	//
	while (regexpos <= length(regexp)) do begin
	  //
	  case (regexp[regexpos]) of

	    '0'..'9': begin
	      //
	      p := regexpos;
	      while ( (regexpos <= length(regexp)) and (aChar(regexp[regexpos]) in ['0'..'9']) ) do
		inc(regexpos);
	      //
	      if (minFound) then begin
		//
		max := str2intInt(copy(regexp, p, regexpos - p));
		break;
	      end
	      else begin
		//
		min := str2intInt(copy(regexp, p, regexpos - p));
		max := min;
		minFound := true;
	      end;
	    end;

	    ' ': inc(regexpos);

	    ',': begin
	      //
	      inc(regexpos);
	      minFound := true;
	      max := RE_DUP_MAX;
	    end;

	    '}': break;

	    else
	      break;

	  end;	// case
	end;
	//
	if ( (regexpos <= length(regexp)) and ('}' = regexp[regexpos]) ) then begin
	  //
	  if (max >= min) then
	    // add repeat mofifier to prev exp
	    modifyPrev(min, max)
	  else
	    error := unaRE_error_mmOrder;	// wrong order of min/max
	  //
	  inc(regexpos);
	end
	else
	  error := unaRE_error_mm;	// some error in {}
      end;

      '(': begin
	//
	// parse new (subexpression)
	p := ea.r_c;	// remember next exp index
	inc(subCount);
	error := parse(regexp, ea, regexpos, subCount, true);
	if ((unaRE_error_OK = error) and (ea.r_c > p)) then
	  markRef(p);
	//
	prevIndex := p;
      end;

      ')': begin
	//
	if (subExp) then
	  break			// end of subexpression
	else
	  addE(et_char, ch);	// "The close-parenthesis shall be considered special in this context only if matched with a preceding open-parenthesis."
      end;

      '[': begin
	//
	// parse [sequence]
	_not := false;
	atb := true;
	p := regexpos;
	//
	while (regexpos <= length(regexp)) do begin
	  //
	  case (regexp[regexpos]) of

	    ']': begin
	      //
	      if (atb) then begin   // []..] or [^]..]
		//
		atb := false;
		inc(regexpos);
	      end
	      else
		break;	// end of set
	    end;

	    '^': begin
	      //
	      if (p = regexpos) then
		_not := true // [^...]
	      else
		atb := false;	// [^^..]
	      //
	      inc(regexpos);
	    end;

	    else begin
	      //
	      atb := false;
	      inc(regexpos);
	    end;

	  end;
	end;
	//
	if (_not) then
	  inc(p);
	//
	if (regexpos > p) then begin
	  //
	  seq := copy(regexp, p, regexpos - p);
	  repeat
	    //
	    p := pos('-', copy(seq, 2, length(seq) - 2));
	    if (0 < p) then begin
	      //
	      seqChF := seq[p + 0];
	      seqChL := seq[p + 2];
	      seqRange := '';
	      for seqCh := seqChF to seqChL do
		seqRange := seqRange + seqCh;
	      //
	      delete(seq, p, 3);
	      insert(seqRange, seq, p);
	    end
	    else
	      break;
	    //
	  until (false);
	  //
	  addE(et_charset, seq, 1, 1, _not);
	  //
	  inc(regexpos);
	end
	else
	  error := unaRE_error_emptySeq;
      end;

      '|': begin
	//
	// new alternative
	altIndex := -1;
      end;

      '\': begin
	//
	// parse escaped char
	if (regexpos <= length(regexp)) then begin
	  //
	  ch := regexp[regexpos];
	  inc(regexpos);
	  case (ch) of

	    '?', '+', '.', '[', '\', '(', ')', '{', '|', '^', '$', '*': addE(et_char, ch);

	    '0'..'9': begin
	      //
	      // backref
	      p := regexpos - 1;
	      //
	    {$IFDEF UNARE_STRICT_1003 }
	      // force to use only 1 digit
	    {$ELSE }
	      while (regexpos <= length(regexp)) do begin
		//
		case (regexp[regexpos]) of

		  '0'..'9': inc(regexpos);

		  else
		    break;

		end;	// case
		//
	      end;
	    {$ENDIF UNARE_STRICT_1003}
	      //
	      ref := str2intInt(copy(regexp, p, regexpos - p), -1);
	      if ((ref > 0) and (ref <= subCount)) then begin
		//
		i := 1;
		while ((i < ea.r_c) and (0 < ref)) do begin
		  //
		  if (et_subexp = ea.r_a[i].r_type) then begin
		    //
		    dec(ref);
		    if (1 > ref) then
		      break;
		  end;
		  //
		  inc(i);
		end;
		//
		if (0 = ref) then begin
		  //
		  addE(et_ref);
		  ea.r_a[prevIndex].r_refIndex := i;
		end
		else
		  error := unaRE_error_backref;	// wrong backref
	      end
	      else
		error := unaRE_error_backref;	// wrong backref
	    end;

	    else
	      error := unaRE_error_escape;	// unknown escape

	  end;
	end
	else
	  error := unaRE_error_escape2;	// out of escape chars
      end;

      else
	addE(et_char, ch);

    end;	// case (ch) ..
  end;	// while ..
  //
  result := error;
end;

// --  --
procedure disposeEA(var ea: pointer);
begin
  while ((nil <> ea) and (0 < pEA(ea).r_c)) do begin
    //
    dec(pEA(ea).r_c);
    case (pEA(ea).r_a[pEA(ea).r_c].r_type) of

      et_charset: strDisposeW(pEA(ea).r_a[pEA(ea).r_c].r_charset);
      et_subexp	: mrealloc(pEA(ea).r_a[pEA(ea).r_c].r_alt);

    end;
  end;
  //
  mrealloc(ea);
end;

// --  --
function parse(const regexp: wString; var ea: pointer): int;
var
  rpos, sc: int;
begin
  if (nil <> ea) then
    pEA(ea).r_c := 0;
  //
  rpos := 1;
  sc := 0;	// "root" subexpression (= "main" expression)
  //
  result := parse(regexp, pEA(ea), rpos, sc);
end;


// -- forward --
function matchE(ea: pEA; index: int; const subj: wString; lastmatch: int; out minLen, maxLen: int; backRef: bool = false): bool; forward;

// --  --
function matched(ea: pEA; el: pE; const subj: wString; lastmatch: int; out minLen, maxLen: int; backRef: bool): bool;
var
  i: int32;
  lMin, lMax: int;
  sel: pE;
  found: bool;
  ch: wChar;
begin
  result := false;
  minLen := 1;
  maxLen := 1;
  //
  case (el.r_type) of

    et_char,
    et_anychar,
    et_charset: begin
      //
      if (lastmatch <= length(subj)) then begin
	//
	if (backref) then
	  result := ((0 < el.r_fitAt) and (subj[lastmatch] = subj[el.r_fitAt]))	// compare char at current pos with captured char
	else begin
	  //
	  case (el.r_type) of

	    et_char     : result := (subj[lastmatch] = el.r_char);	// compare char at current pos with element's char
	    et_anychar  : result := true;				// any char fits
	    et_charset  : begin
	      //
	      ch := subj[lastmatch];
	      found := false;
	      //
	      for i := 0 to length(el.r_charset) - 1 do begin
		//
		found := (ch = el.r_charset[i]);
		if (found) then
		  break;
	      end;
	      //
	      result := (el.r_not xor found);
	    end;

	  end;	// case (el.r_type)
	  //
	end;
      end // if (lastmatch <= length(subj))
    end;

    et_anchor_L: begin
      //
      if (el.r_not) then
	result := (lastmatch = length(subj) + 1)
      else
	result := (lastmatch = 1);
      //
      minLen := 0;
      maxLen := 0;
    end;

    et_ref: result := matchE(ea, el.r_refIndex, subj, lastmatch, minLen, maxLen, true);	// do not follow next element and use best alt we have found so far

    et_emptystr: begin
      //
      minLen := 0;
      maxLen := 0;
      result := (lastmatch <= length(subj) + 1);
    end;

    et_subexp: begin
      //
      if (not backRef) then begin
	//
	maxLen := -1;	// 0 is better than nothing (-1)
	for i := 0 to el.r_altc - 1 do begin
	  //
	  if (matchE(ea, el.r_alt[i], subj, lastmatch, lMin, lMax, backRef)) then begin
	    //
	    if (lMax > maxLen) then begin
	      //
	      maxLen := lMax;
	      el.r_altFitIndex := i;
	    end;
	    //
	    result := true;	// at least one alt fits
	  end;
	end;
	//
	if (result) then begin
	  //
	  minLen := 0;
	  maxLen := 0;
	  //
	  // sum max len of all elements and sub-elements
	  if (0 <= el.r_altFitIndex) then begin
	    //
	    sel := @ea.r_a[el.r_alt[el.r_altFitIndex]];
	    repeat
	      //
	      inc(minLen, sel.r_eatsMin);
	      inc(maxLen, sel.r_eatsMax);
	      //
	      if (0 < sel.r_nextIndex) then
		sel := @ea.r_a[sel.r_nextIndex]
	      else
		break;
	      //
	    until (false);
	  end
	  else
	    minLen := 0;
	  //
	  el.r_eatsMin := minLen;
	  el.r_eatsMax := maxLen;
	  el.r_fitAt := lastmatch;
	end;
      end
      else begin
	//
	if (0 <= el.r_altFitIndex) then begin
	  //
	  result := matchE(ea, el.r_alt[el.r_altFitIndex], subj, lastmatch, lMin, lMax, false);
	  if (result) then begin
	    //
	    minLen := el.r_eatsMin;
	    maxLen := el.r_eatsMax;
	  end;
        end;
      end;
    end;

  end;
end;

// --  --
procedure clearEAlt(ea: pEA; index, startFrom: int);
var
  i: int32;
  el: pE;
begin
  el := @ea.r_a[index];
  //
  if (et_subexp = el.r_type) then begin
    //
    if (index >= startFrom) then
      // reset subexpression's best alternative
      el.r_altFitIndex := -1;
    //
    for i := 0 to el.r_altc - 1 do
      clearEAlt(ea, el.r_alt[i], startFrom);
  end;
  //
  if (index >= startFrom) then begin
    //
    el.r_fitAt := 0;
    el.r_eatsMin := 0;
    el.r_eatsMax := 0;
  end;
  //
  if (0 < el.r_nextIndex) then
    clearEAlt(ea, el.r_nextIndex, startFrom);
end;

// --  --
function matchE(ea: pEA; index: int; const subj: wString; lastmatch: int; out minLen, maxLen: int; backRef: bool): bool;
var
  r: int32;
  el: pE;
  matchLenLast, rcount, fitAt: int;
  minR, maxR, lMin, lMax, lExtra: int;
begin
  el := @ea.r_a[index];
  //
  if (0 = index) then
    // root
    result := matched(ea, el, subj, lastmatch, minLen, maxLen, backRef)
  else begin
    //
    minLen := 0;
    maxLen := 0;
    rcount := 0;
    fitAt := lastmatch;
    result := true;
    //
    if (backRef) then
      minR := 1
    else
      minR := el.r_repeatMin;
    //
    for r := 1 to minR do begin
      //
      if (matched(ea, el, subj, lastmatch, lMin, lMax, backRef)) then begin
	//
	if (el.r_type <> et_subexp) then
	  ea.r_foundSome := true;
	//
	inc(rcount);
	//
	inc(minLen, lMin);
	inc(maxLen, lMax);
	inc(lastmatch, lMax);
      end
      else begin
	//
	result := false;
	break;	// required amound of repeats not found
      end;
    end;
    //
    matchLenLast := 0;
    //
    // any bonus?
    if (result) then begin
      //
      if (backRef) then
	maxR := 1
      else
	maxR := el.r_repeatMax;
      //
      for r := rcount + 1 to maxR do begin
	//
	if (matched(ea, el, subj, lastmatch, lMin, lMax, backRef)) then begin
	  //
	  if (el.r_type <> et_subexp) then
	    ea.r_foundSome := true;
	  //
	  matchLenLast := lMin;
	  inc(maxLen, lMax);
	  inc(lastmatch, lMax);
	end
	else
	  break;	// enough is enough
      end;
    end;
    //
    if (maxLen < minLen) then
      maxLen := 1;
    //
    // in case of success, check the next element (if any and if required)
    if (result and not backRef and (0 < el.r_nextIndex)) then begin
      //
      if (1 > matchLenLast) then
	matchLenLast := 1;
      //
      lExtra := maxLen - minLen;
      //
      result := false;
      repeat
	//
	if (matchE(ea, el.r_nextIndex, subj, lastmatch, lMin, lMax, backRef)) then begin
	  //
	  result := true;
	  break;
	end;
	//
	// try seeking back, not very optimal, but should work
	dec(lExtra, matchLenLast);
	dec(maxLen, matchLenLast);
	dec(lastmatch, matchLenLast);
	//
	clearEAlt(ea, el.r_nextIndex, el.r_nextIndex);
	//
      until ((0 > lExtra) or (1 > lastmatch));
    end;
    //
    if (result and not backref) then begin
      //
      el.r_eatsMin := minLen;
      el.r_eatsMax := maxLen;
      //
      if ((0 < maxLen) or (index < ea.r_c - 1) or ea.r_foundSome) then begin
	//
	if ((et_subexp = el.r_type) and ((1 > el.r_fitAt) or (fitAt < el.r_fitAt))) then
	  el.r_fitAt := fitAt
	else
	  if (et_subexp <> el.r_type) then
	    el.r_fitAt := fitAt;
	//
      end
      else
        result := false;
    end;
  end;
end;

// --  --
function tryMatch(ea: pEA; const subject: wString; out matchlen: int; lastmatch: int): int;
var
  minLen, maxLen: int;
begin
  matchlen := 0;
  //
  if ((nil <> ea) and (et_subexp = ea.r_a[0].r_type)) then begin
    //
    ea.r_foundSome := false;
    //
    result := unaRE_error_noMatch;
    while (lastmatch <= length(subject)) do begin
      //
      clearEAlt(ea, 0, 0);
      if (matchE(ea, 0, subject, lastmatch, minLen, maxLen)) then begin
	//
	matchlen := maxLen;
	result := lastmatch;
	break;
      end
      else
	inc(lastmatch);
    end;
  end
  else
    result := unaRE_error_srootExp;
end;


{$IFDEF UNARE_LOG_RARSER }

// --  --
function e2str(ea: pEA; el: pE; subOnly: bool): string;
var
  v: string;
begin
  case (el.r_type) of

    et_char		: v := el.r_char;
    et_anychar 		: v := '.';
    et_charset		: v := '[' + choice(el.r_not, '^', '') + el.r_charset + ']';
    et_anchor_L		: if (el.r_not) then v := '$' else v := '^';
{$IFDEF UNARE_STRICT_1003 }
{$ELSE }
    et_anchor_W		: if (el.r_not) then v := '\w' else v := '\W';
{$ENDIF UNARE_STRICT_1003 }
    et_ref		: v := '\' + int2str(ea.r_a[el.r_refIndex].r_refnum);

    et_emptystr,
    et_subexp		: v := '';

    else
      v := '~uknown type (' + int2str(ord(el.r_type)) + ')~';

  end;
  //
  if (subOnly) then
    result := v + '@' + int2str(el.r_fitAt) + ':' + int2str(el.r_eatsMin) + '-' + int2str(el.r_eatsMin) + ','
  else
    result := v;
end;

// --  --
function minMax2str(el: pE): string;
begin
  case el.r_repeatMin of

    0: begin
      //
      if (1 = el.r_repeatMax) then
	result := '?'						// ?
      else
	if (RE_DUP_MAX = el.r_repeatMax) then
	  result := '*'						// *
	else
	  result := '{,' + int2str(el.r_repeatMax) + '}';	// {,m}
    end;

    1: begin
      //
      if (RE_DUP_MAX = el.r_repeatMax) then
	result := '+'						// +
      else
	result := '{1,' + int2str(el.r_repeatMax) + '}';	// {1, m}
    end;

    else begin
      //
      if (el.r_repeatMax = el.r_repeatMin) then
	result := '{' + int2str(el.r_repeatMax) + '}'		// {m}
      else
	if (RE_DUP_MAX = el.r_repeatMax) then
	  result := '{' + int2str(el.r_repeatMin) + ',}'	// {n,}
	else
	  result := '{' + int2str(el.r_repeatMin) + ',' + int2str(el.r_repeatMax) + '}';	// {n, m}
    end;

  end;
end;

// --  --
function printE(ea: pEA; index: int; subOnly: bool): string;
var
  ia: int32;
  el: pE;
begin
  el := @ea.r_a[index];
  case (el.r_type) of

    et_subexp: begin
      //
      if (0 < index) then
	result := '('
      else
	result := '';	// root should not be embrased in ()
      //
      for ia := 0 to el.r_altc - 1 do begin
	//
	result := result + printE(ea, el.r_alt[ia], subOnly);
	//
	if (ia < el.r_altc - 1) then
	  result := result + '|';
      end;
      //
      if (0 < index) then begin
	//
	result := result + ')';
	//
	if (subOnly) then
	  result := result + e2str(ea, el, subOnly);
      end;
    end;

    else
      result := e2str(ea, el, subOnly);

  end;
  //
  if ((1 <> el.r_repeatMin) or (1 <> el.r_repeatMax)) then
    if (subOnly) then
      result := minMax2str(el) + result
    else
      result := result + minMax2str(el);
  //
  if (0 < el.r_nextIndex) then
    result := result + printE(ea, el.r_nextIndex, subOnly);
end;

// --  --
function printEA(ea: pEA; subOnly: bool): string;
begin
  if (et_subexp = ea.r_a[0].r_type) then begin
    //
    result := printE(ea, 0, subOnly);
  end
  else
    result := 'root must be subexp';
end;

{$ENDIF UNARE_LOG_RARSER }


// --  --
function rematch(const subject, regexp: wString; out matchlen: int; startFrom: int): int;
var
  ea: pEA;
begin
  // parse regexp
  ea := nil;
  result := parse(regexp, pointer(ea));
  if (1 > startFrom) then
    startFrom := 1;
  //
  try
    if (unaRE_error_OK = result) then begin
      //
  {$IFDEF UNARE_LOG_RARSER }
      logMessage(printEA(ea, false));
  {$ENDIF UNARE_LOG_RARSER }
      //
      result := tryMatch(ea, subject, matchlen, startFrom);
      //
  {$IFDEF UNARE_LOG_RARSER }
      logMessage(printEA(ea, true));
  {$ENDIF UNARE_LOG_RARSER }
    end
    else begin
      //
  {$IFDEF UNARE_LOG_RARSER }
      logMessage('parse regexp: error=' + int2str(result));
  {$ENDIF UNARE_LOG_RARSER }
    end;
  finally
    disposeEA(pointer(ea));
  end
end;

// --  --
function rematch(startFrom: int; const subject, regexp: wString): string;
var
  p, mlen: int;
begin
  p := rematch(subject, regexp, mlen, startFrom);
  if (1 < mlen) then
    result := copy(subject, p, mlen)
  else
    result := '';
end;

// --  --
function rematch(ea: pointer; const subject: wString; out matchlen: int; startFrom: int): int;
begin
  result := tryMatch(ea, subject, matchlen, startFrom);
end;

// --  --
function replace(const subject, regexp, substitution: wString; startFrom: int; global: bool): wString;
var
  ea: pEA;
begin
  // parse regexp
  ea := nil;
  if (unaRE_error_OK = parse(regexp, pointer(ea))) then try
    //
    result := replace(ea, subject, substitution, startFrom, global);
  finally
    disposeEA(pointer(ea));
  end;
end;

// --  --
function replace(ea: pointer; const subject, substitution: wString; startFrom: int; global: bool): wString; overload;

  procedure addSubj(from, len: int);
  begin
    result := result + copy(subject, from, len);
  end;

var
  fitAt, fitLen, p, s, ref, lastFitAt: int;
  replace, subref: wString;
  i: int;
begin
  result := '';
  lastFitAt := 1;
  //
  if (1 > startFrom) then
    startFrom := 1;
  //
  repeat
    //
    fitAt := rematch(ea, subject, fitLen, startFrom);
    if ((0 < fitAt) and (0 < fitLen)) then begin
      //
      // replace
      replace := substitution;
      //
      // check for backrefs
      p := 1;
      while (p <= length(replace)) do begin

	case (replace[p]) of

	  '\': begin
	    //
	    inc(p);
	    s := p;
	    // parse backref number
	    if (p <= length(replace)) then begin
	      //
	      case (replace[p]) of

		'0'..'9': begin
		  //
		  // backref
		  //
		{$IFDEF UNARE_STRICT_1003 }
		  inc(p);	// force 1 char only
		{$ELSE }
		  //
		  while (p <= length(replace)) do begin
		    //
		    case (replace[p]) of

		      '0'..'9': inc(p);

		      else
			break;

		    end;	// case (replace[p2]) of
		  end;
		{$ENDIF UNARE_STRICT_1003 }
		  //
		  ref := str2intInt(copy(replace, s, p - s), -1);
		  if (ref > 0) then begin
		    //
		    i := 1;
		    while ((i < pEA(ea).r_c) and (0 < ref)) do begin
		      //
		      if (et_subexp = pEA(ea).r_a[i].r_type) then begin
			//
			dec(ref);
			if (1 > ref) then
			  break;
		      end;
		      //
		      inc(i);
		    end;
		    //
		    if (0 = ref) then begin
		      //
		      // replace replace
		      subref := copy(subject, pEA(ea).r_a[i].r_fitAt, pEA(ea).r_a[i].r_eatsMax);
		      delete(replace, s - 1, p - s + 1);
		      insert(subref, replace, s - 1);
		      //
		      p := s + length(subref);
		    end;
		  end;
		end;	// 0..9

		else
		  inc(p);	// not a backref

	      end;	// case (replace[p]) of
	    end;
	  end;

	  else
	    inc(p);

	end;	// case (replace[p]) of ..
      end;
      //
      addSubj(lastFitAt, fitAt - lastFitAt);
      result := result + replace;
      lastFitAt := fitAt + fitLen;
      //
      startFrom := lastFitAt;
    end
    else
      break;	// no more matches
    //
  until (not global);
  //
  addSubj(lastFitAt, maxInt);
end;


{ unaRegExp }

// --  --
constructor unaRegExp.create(const regexp: wString);
begin
  self.regexp := regexp;
  //
  inherited create();
end;

// --  --
destructor unaRegExp.Destroy();
begin
  disposeEA(f_ea);
  //
  inherited;
end;

// --  --
function unaRegExp.match(out len: int; const subject: wString; startFrom: int): int;
begin
  if (unaRE_error_OK = error) then begin
    //
    if ('' <> subject) then
      subj := subject;	// resets lookupPos to 1 if new subject
    //
    if (0 < startFrom) then
      lookupPos := startFrom;
    //
    result := rematch(f_ea, subj, len, lookupPos);
    if (0 < result) then
      lookupPos := result + len;
  end
  else
    result := error;	// should solve the problem with regexp first
end;

// --  --
function unaRegExp.replace(const substitution, subject: wString; startFrom: int; global: bool): string;
begin
  if (unaRE_error_OK = error) then begin
    //
    if ('' <> subject) then
      subj := subject;	// resets lookupPos to 1 if new subject
    //
    if (0 < startFrom) then
      lookupPos := startFrom;
    //
    result := unaRE.replace(f_ea, subj, substitution, lookupPos, global);
  end
  else
    result := '';	// should solve the problem with regexp first
end;

// --  --
function unaRegExp.match(const subject: wString; startFrom: int): wString;
var
  pos, len: int;
begin
  pos := match(len, subject, startFrom);
  if (0 < pos) then
    result := copy(subj, pos, len)
  else
    result := '';
end;

// --  --
procedure unaRegExp.setRegexp(const value: wString);
begin
  if (f_regexp <> value) then begin
    //
    f_error := parse(value, f_ea);
    if (unaRE_error_OK = error) then
      f_regexp := value;
  end;
end;

// --  --
procedure unaRegExp.setSubj(const value: wString);
begin
  if (f_subj <> value) then begin
    //
    f_subj := value;
    lookupPos := 1;
  end;
end;


end.

