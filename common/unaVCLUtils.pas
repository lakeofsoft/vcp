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

	  unaVCLUtils.pas
	  VCL utility functions and classes

	----------------------------------------------
	  Copyright (c) 2002-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 29 Apr 2002

	  modified by:
		Lake, Apr-Dec 2002
		Lake, Jan-Oct 2003

	----------------------------------------------
*)

{$I unaDef.inc}

{*
	VCL utility functions and classes
}
unit
  unaVCLUtils;

interface

uses
  Windows, unaTypes, unaClasses, Classes, Controls, ComCtrls;

function loadControlPosition(control: tControl; ini: unaIniAbstractStorage; const section: string = 'settings'; allowFormOptions: bool = true; allowSizeChange: bool = true): bool;
function saveControlPosition(control: tControl; ini: unaIniAbstractStorage; const section: string = 'settings'; allowFormOptions: bool = true): bool;

function loadStringList(list: tStrings; ini: unaIniAbstractStorage; const section: string = 'settings'; noEmpty: bool = false): integer;
function saveStringList(list: tStrings; ini: unaIniAbstractStorage; const section: string = 'settings'; noEmpty: bool = false): integer;

function dummyWinpos(handle: tHandle; width, height: int): int;

function getREWideText(re: hWnd): wString;
function setREWideText(re: hWnd; const text: wString): LRESULT;


implementation


uses
  unaUtils, Messages, RichEdit, Forms;

// --  --
function loadControlPosition(control: tControl; ini: unaIniAbstractStorage; const section: string; allowFormOptions: bool; allowSizeChange: bool): bool;
var
  isForm: bool;
  ws: TWindowState;
  _name: string;
begin
  if (ini.enter(section)) then
    try
      if (nil <> control) then begin
	//
	isForm := (control is tCustomForm);
	//
	with control, ini do begin
	  //
          _name := name;
          //
	  left    := get(_name + '.left', left);
	  top     := get(_name + '.top', top);
	  //
	  if (allowSizeChange) then begin
	    //
	    width   := get(_name + '.width', width);
	    height  := get(_name + '.height', height);
	  end;
	  //
	  enabled := get(_name + '.enabled', enabled);
	  //
	  if (not isForm) then
	    visible := get(_name + '.visible', visible);
	  //
	  dockOrientation := tDockOrientation(get(_name + '.dockOrnt', ord(dockOrientation)));
	end;
	//
	if (isForm and allowFormOptions) then begin
	  //
	  with (control as tCustomForm) do begin
	    //
	    ws := tWindowState(ini.get(_name + '.windowState', ord(wsNormal)));
	    //
	    if (windowState <> ws) then
	      windowState := ws;
	  end;
	end;
	//
      end;
      //
      result := true;
    finally
      ini.leave();
    end
  else
    result := false;
end;

// --  --
function saveControlPosition(control: tControl; ini: unaIniAbstractStorage; const section: string; allowFormOptions: bool): bool;
var
  isForm: bool;
  _name: string;
begin
  if ((nil <> ini) and (nil <> control) and ini.enter(section)) then try
    //
    isForm := (control is tCustomForm);
    with (control) do begin
      //
      _name := name;
      //
      if (isForm and allowFormOptions) then begin
	//
	with (control as tCustomForm) do begin
	  //
	  ini.setValue(_name + '.windowState', ord(windowState));
	  windowState := wsNormal;
	end;
      end;
      //
      with (ini) do begin
	//
	setValue(_name + '.left', Left);
	setValue(_name + '.top', Top);
	setValue(_name + '.width', Width);
	setValue(_name + '.height', Height);
	setValue(_name + '.enabled', Enabled);
	setValue(_name + '.docked', HostDockSite <> nil);
	setValue(_name + '.dockOrnt', ord(dockOrientation));
	//
	if (not isForm) then
	  setValue(_name + '.visible', Visible);
      end;
    end;
    //
    result := true;
  finally
    ini.leave();
  end
  else
    result := false;
end;

// --  --
function loadStringList(list: tStrings; ini: unaIniAbstractStorage; const section: string; noEmpty: bool): integer;
var
  i: integer;
  max: integer;
  s: string;
begin
  result := 0;
  //
  if (ini.enter(section)) then
    try
      if (nil <> list) then begin
	//
	list.clear();
	max := ini.get('list.count', integer(0));
	i := 0;
	//
	while (i < max) do begin
	  //
	  s := ini.get('list.item' + int2str(i), '');
	  if (noEmpty and ('' = trimS(s))) then
	    // skip empty entrie
	  else begin
            //
	    list.add(strUnescape(s));
	    inc(result);
	  end;
	  //
	  inc(i);
	end;
      end;
    finally
      ini.leave();
    end;
end;

// --  --
function saveStringList(list: tStrings; ini: unaIniAbstractStorage; const section: string; noEmpty: bool): integer;
var
  i: integer;
  s: string;
begin
  result := 0;
  //
  if (ini.enter(section)) then
    try
      if (nil <> list) then begin
	//
	i := 0;
	while (i < list.count) do begin
          //
	  s := list[i];
	  if (noEmpty and ('' = trimS(s))) then
	    // do not save empty entries
	  else begin
            //
	    ini.setValue('list.item' + int2str(result), strEscape(s));
	    inc(result);
	  end;
	  //
	  inc(i);
	end;
	//
	ini.setValue('list.count', result);
      end;
    finally
      ini.leave();
    end
end;

// --  --
function dummyWinpos(handle: tHandle; width, height: int): int;
var
  pos: WINDOWPOS;
begin
  pos.hwnd := handle;
  pos.cx := width;
  pos.cy := height;
  pos.flags := SWP_NOACTIVATE or SWP_NOCOPYBITS or SWP_NOOWNERZORDER or SWP_NOREDRAW or SWP_NOSENDCHANGING or SWP_NOZORDER or SWP_NOMOVE;
  result := SendMessage(handle, WM_WINDOWPOSCHANGED, 0, int(@pos));
end;

{$IFDEF __BEFORE_D5__ }
type
  GETTEXTEX = tGETTEXTEX;
{$ENDIF __BEFORE_D5__ }

// --  --
function getREwideText(re: hWnd): wString;
var
  gte: GETTEXTEX;
  len: int;
{$IFNDEF NO_ANSI_SUPPORT }
  resultA: aString;
{$ENDIF NO_ANSI_SUPPORT }
begin
{$IFNDEF NO_ANSI_SUPPORT }
  if (g_wideApiSupported) then begin
{$ENDIF NO_ANSI_SUPPORT }
    //
    setLength(result, 65535);
    //
    fillChar(gte, sizeof(gte), 0);
    gte.cb := 65534 * 2;
    gte.flags := GT_DEFAULT;
    gte.codepage := 1200;
    //
    len := sendMessage(re, EM_GETTEXTEX, wParam(@gte), lParam(@result[1]));
    if (0 < len) then
      setLength(result, len)
    else
      result := '';
{$IFNDEF NO_ANSI_SUPPORT }
  end
  else begin
    //
    len := GetWindowTextLength(re);
    if (0 < len) then begin
      //
      setLength(resultA, len);
      if (0 < len) then begin
	//
	GetWindowTextA(re, @resultA[1], len + 1);
	result := wString(resultA);
      end;
    end
    else
      result := '';
  end;
{$ENDIF NO_ANSI_SUPPORT }
end;


const
//* Flags for the SETEXTEX data structure */
  ST_DEFAULT	= 0;
  ST_KEEPUNDO	= 1;
  ST_SELECTION	= 2;

  //
  EM_SETTEXTEX	= WM_USER + 97;

type
  //
  SETTEXTEX = packed record
    flags: DWORD;
    codepage: UINT;
  end;


// --  --
function setREwideText(re: hWnd; const text: wString): LRESULT;
var
  ste: SETTEXTEX;
  buf: array[0..0] of wChar;
begin
{$IFNDEF NO_ANSI_SUPPORT }
  if (g_wideApiSupported) then begin
{$ENDIF NO_ANSI_SUPPORT }
    //
    ste.flags := ST_DEFAULT;
    ste.codepage := 1200;
    if ('' = text) then begin
      //
      buf[0] := #0;
      result := LRESULT(SendMessage(re, EM_SETTEXTEX, WPARAM(@ste), LPARAM(@buf[0])))
    end
    else
      result := LRESULT(SendMessage(re, EM_SETTEXTEX, WPARAM(@ste), LPARAM(@text[1])))
{$IFNDEF NO_ANSI_SUPPORT }
  end
  else begin
    //
    SetWindowTextA(re, paChar(aString(text)));
    result := length(text);
  end;
{$ENDIF NO_ANSI_SUPPORT }
end;


end.

