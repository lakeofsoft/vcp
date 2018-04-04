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


var
  g_logOL: array[byte] of OVERLAPPED;		// array of OL
  g_logOLOffs: int;				// offset of next OL operation
  g_logOLEvents: array[byte] of tHandle;	// array of OL event handles
  g_logOLBufs: array[byte] of pointer;		// array of OL buffers
  g_logOLBufsSz: array[byte] of int;		// array of OL buffer sizes
  g_logOLCount: int;				// number of OLs

// --  --
function incMT(var v: int; delta: int): int;
begin
  result := InterlockedExchangeAdd(v, delta);
end;

// --  --
function write2file(handle: tHandle; var offset: int; buf: pointer; len: unsigned): bool;
var
  i: DWORD;
  OL: POVERLAPPED;
  ofs: unsigned;
begin
  result := false;	//
  if ((0 < len) and (nil <> buf)) then begin
    //
    ofs := incMT(offset, len);
    //
    // find non-pending OL
    i := 0;
    if (0 < g_logOLCount) then begin
      //
      i := WaitForMultipleObjects(g_logOLCount, PWOHandleArray(@g_logOLEvents), false, 10);	// do not wait for too long, better create a new OL
      if (i < WAIT_OBJECT_0 + unsigned(g_logOLCount)) then
	OL := @g_logOL[i - WAIT_OBJECT_0]
      else
	OL := nil;	// all are busy
    end
    else
      OL := nil;
    //
    if ((nil = OL) and (g_logOLCount <= high(g_logOL) - low(g_logOL))) then begin
      //
      i := low(g_logOL) + incMT(g_logOLCount, 1);
      g_logOLEvents[i] := CreateEvent(nil, false, false, nil);	// auto-reset event
      g_logOL[i].hEvent := g_logOLEvents[i];
      //
      OL := @g_logOL[i];
    end;
    //
    if (nil <> OL) then begin
      //
      if (int(len) > g_logOLBufsSz[i]) then begin
	//
	mrealloc(g_logOLBufs[i], len);
	g_logOLBufsSz[i] := len;
      end;
      //
      move(buf^, g_logOLBufs[i]^, len);
      //
      OL.Offset := ofs and $FFFFFFFF;
      {$IFDEF CPU64 }
      OL.OffsetHigh := ofs shr 32;
      {$ELSE }
      OL.OffsetHigh := 0;
      {$ENDIF CPU64 }
      //
      result := WriteFile(handle, g_logOLBufs[i], len, nil, OL);
      if (not result and (ERROR_IO_PENDING = GetLastError())) then
	result := true	// report no error
      else
	SetEvent(OL.hEvent);
      //
    end;
    //
  end;
end;

// --  --
procedure releaseOLs();
var
  i: int;
  w: unsigned;
begin
  if (0 < g_logOLCount) then begin
    //
    WaitForMultipleObjects(g_logOLCount, PWOHandleArray(@g_logOLEvents), true, 3000);
    //
    i := 0;
    while (i < g_logOLCount) do begin
      //
      w := WaitForSingleObject(g_logOLEvents[i], 10);
      if (WAIT_OBJECT_0 = w) then begin
	//
	CloseHandle(g_logOLEvents[i]);
	mrealloc(g_logOLBufs[i]);
      end;
      //
      inc(i);
    end;
    //
    g_logOLCount := 0;
  end;
end;

