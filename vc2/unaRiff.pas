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
	  unaRIFF.pas
	----------------------------------------------
	  Copyright (c) 2002-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 20 May 2002

	  modified by:
		Lake, May-Dec 2002
		Lake, May 2003
		Lake, Aug 2004
		Lake, Dec 2009

	----------------------------------------------
*)

{$I unaDef.inc}

{*
  Simple Resource Interchange File Format (RIFF) parser.

  @Author Lake

 	Version 2.5.2008.07

	Version 2.5.2009.09 some cleanup

	Version 2.5.2011.10 x64 compatibility fixes
}

unit
  unaRIFF;

interface

uses
  Windows, unaTypes, unaClasses;

type
  // --  --
  fourCC = packed array[0..3] of aChar;

  // --  --
  punaRIFFHeader = ^unaRIFFHeader;
  unaRIFFHeader = packed record
    //
    r_id: fourCC;
    r_size: uint32;	// size of data right after this field (including r_type)
    r_type: fourCC;
  end;

  //
  unaRIFile = class;

  {*
	RIFF Chunk.
  }
  unaRIFFChunk = class(unaObject)
  private
    f_offset64: int64;
    f_maxSize64: int64;
    f_isContainer: bool;
    f_header: punaRIFFHeader;
    f_data64KB: pArray;
    f_data64KBSize: int;
    //
    f_subChunks: unaObjectList;
    f_master: unaRIFile;
    f_parent: unaRIFFChunk;
    //
    function getSubChunk(index: unsigned): unaRIFFChunk;
    procedure parse();
  public
    constructor create(master: unaRIFile; parent: unaRIFFChunk; maxSize: int64; offset: int64 = 0);
    destructor Destroy(); override;
    //
    function getSubChunkCount(): unsigned;
    function isID(const id: fourCC): bool;
    //
    function readBuf(offset: int64; buf: pointer; sz: unsigned): unsigned;
    function loadDataBuf(maxSize: int = -1): pArray;
    procedure releaseDataBuf();
    //
    function getSubPtr(offs: int64; size: unsigned; out subOfs: int): pointer;
    procedure releaseSubPtr(baseAddr: pointer);
    //
    property subChunk[index: unsigned]: unaRIFFChunk read getSubChunk; default;
    property isContainer: bool read f_isContainer;
    property header: punaRIFFHeader read f_header;
    property offset64: int64 read f_offset64;
    property maxSize64: int64 read f_maxSize64;
    //
    property dataBuf: pArray read f_data64KB;
    property dataBufSize: int read f_data64KBSize;
    //
    property master: unaRIFile read f_master;
  end;


  //
  // -- unaRIFile --
  //
  {*
	RIFF file parser.
  }
  unaRIFile = class(unaObject)
  private
    f_mapFile: unaMappedFile;
    f_fileName: wideString;
    //
    f_dataBuf: pArray;
    f_dataSize64: int64;
    f_rootChunk: unaRIFFChunk;
    //
    procedure parse();
    function getIsValid(): bool;
  public
    constructor create(const fileName: wideString; access: unsigned = PAGE_READONLY); overload;
    constructor create(dataBuf: pointer; len: unsigned); overload;
    destructor Destroy(); override;
    procedure AfterConstruction(); override;
    //
    function getPtr(offset: int64; size: unsigned; out subOfs: int): pointer;
    function releasePtr(baseAddr: pointer): bool;
    //
    property rootChunk: unaRIFFChunk read f_rootChunk;
    property isValid: bool read getIsValid;
    property fileName: wideString read f_fileName;
    property dataSize64: int64 read f_dataSize64;
  end;


implementation


uses
  unaUtils;

{ unaRIFFChunk }

// --  --
constructor unaRIFFChunk.create(master: unaRIFile; parent: unaRIFFChunk; maxSize: int64; offset: int64);
var
  subOfs: int;
  hdr: punaRIFFHeader;
begin
  inherited create();
  //
  f_master := master;
  f_parent := parent;
  //
  f_offset64 := offset;
  f_maxSize64 := maxSize;
  //
  hdr := master.getPtr(offset, sizeOf(hdr^), subOfs);
  if (nil <> hdr) then begin
    //
    f_header := malloc(sizeOf(f_header^));
    move(pArray(hdr)[subOfs], f_header^, sizeOf(f_header^));
    master.releasePtr(hdr);
    //
    if (nil <> f_header) then begin
      //
      f_isContainer := (isID('RIFF') or isID('LIST'));
      if (isContainer) then begin
	//
	f_subChunks := unaObjectList.create();
	parse();
      end;
    end;
  end;
end;

// --  --
destructor unaRIFFChunk.Destroy();
begin
  inherited;
  //
  freeAndNil(f_subChunks);
  //
  mrealloc(f_header);
  mrealloc(f_data64KB);
end;

// --  --
function unaRIFFChunk.getSubChunk(index: unsigned): unaRIFFChunk;
begin
  if (nil <> f_subChunks) then
    result := f_subChunks[index]
  else
    result := nil;
end;

// --  --
function unaRIFFChunk.getSubChunkCount(): unsigned;
begin
  if (nil <> f_subChunks) then
    result := f_subChunks.count
  else
    result := 0;
end;

// --  --
function unaRIFFChunk.getSubPtr(offs: int64; size: unsigned; out subOfs: int): pointer;
begin
  result := f_master.getPtr(f_offset64 + 8 + offs, size, subOfs);
end;

// --  --
function unaRIFFChunk.isID(const id: fourCC): bool;
begin
  result := (nil <> f_header) and (id = f_header.r_id);
end;

// --  --
function unaRIFFChunk.loadDataBuf(maxSize: int): pArray;
var
  data: pArray;
  subOfs: int;
begin
  if (0 > maxSize) then
    f_data64KBSize := min(64 * 1024, f_maxSize64 - 8)
  else begin
    //
    f_data64KBSize := min(maxSize, f_maxSize64 - 8);
    if (f_data64KBSize < maxSize) then
      f_data64KBSize := 0;	// cannot map that size of data, return nil
  end;
  //
  if (0 < f_data64KBSize) then begin
    //
    data := master.getPtr(f_offset64 + 8, f_data64KBSize, subOfs);
    if (nil <> data) then begin
      //
      mrealloc(f_data64KB, f_data64KBSize);
      move(pArray(data)[subOfs], f_data64KB^, f_data64KBSize);
      master.releasePtr(data);
    end;
  end
  else
    mrealloc(f_data64KB);
  //
  result := f_data64KB;
end;

// --  --
procedure unaRIFFChunk.parse();
var
  ofs: int64;
  maxSize: int64;
  chunk: unaRIFFChunk;
begin
  if (isContainer) then begin
    //
    f_subChunks.clear();
    maxSize := min(int(f_header.r_size) + 8, f_maxSize64);
    //
    ofs := sizeOf(f_header^);
    while (ofs + 8 <= maxSize) do begin
      //
      try
	{$IFDEF DEBUG }
	//logMessage('About to load new chunk at 0x' + int2str(f_offset64 + ofs, 16));
	{$ENDIF DEBUG }
	chunk := unaRIFFChunk.create(f_master, self, maxSize - ofs, f_offset64 + ofs);
	f_subChunks.add(chunk);
	//
	if (nil <> chunk.f_header) then
	  inc(ofs, min(int(chunk.f_header.r_size) + 8, chunk.f_maxSize64))
	else
	  inc(ofs, min(8, chunk.f_maxSize64));
	//
	ofs := (ofs + 1) and $FFFFFFFFFFFFFFFE;	// align to word boundary
      except
	//
        inc(ofs, sizeOf(unaRIFFHeader));
      end;
    end;
  end;
end;

// --  --
function unaRIFFChunk.readBuf(offset: int64; buf: pointer; sz: unsigned): unsigned;
begin
  result := f_master.f_mapFile.read(f_offset64 + 8 + offset, buf, sz)
end;

// --  --
procedure unaRIFFChunk.releaseDataBuf();
begin
  f_data64KBSize := 0;
  mrealloc(f_data64KB);
end;

// --  --
procedure unaRIFFChunk.releaseSubPtr(baseAddr: pointer);
begin
  f_master.releasePtr(baseAddr);
end;


{ unaRIFile }

// --  --
constructor unaRIFile.create(const fileName: wideString; access: unsigned);
begin
  inherited create();
  //
  f_mapFile := unaMappedFile.create(fileName, access);
  f_dataBuf := nil;
  f_dataSize64 := f_mapFile.size64;
  //
  f_fileName := fileName;
end;

// --  --
procedure unaRIFile.AfterConstruction();
begin
  inherited;
  //
  if (12 <= f_dataSize64) then
    parse();
end;

// --  --
constructor unaRIFile.create(dataBuf: pointer; len: unsigned);
begin
  f_dataBuf := dataBuf;
  f_dataSize64 := len;
  f_mapFile := nil;
  //
  f_fileName := '';
end;

// --  --
destructor unaRIFile.Destroy();
begin
  inherited;
  //
  freeAndNil(f_rootChunk);
  freeAndNil(f_mapFile);
end;

// --  --
function unaRIFile.getIsValid(): bool;
begin
  result := (nil <> rootChunk) and (rootChunk.isID('RIFF'));
end;

// --  --
function unaRIFile.getPtr(offset: int64; size: unsigned; out subOfs: int): pointer;
begin
  if (nil <> f_mapFile) then
    result := f_mapFile.mapView(offset, size, subOfs)
  else
    if ((nil <> f_dataBuf) and (offset + size < dataSize64)) then
      result := @f_dataBuf[offset]
    else
      result := nil;
  //
  if (nil = result) then
    result := result;   
end;

// --  --
procedure unaRIFile.parse();
begin
  freeAndNil(f_rootChunk);
  //
  if ((nil <> f_mapFile) or (nil <> f_dataBuf)) then
    f_rootChunk := unaRIFFChunk.create(self, nil, f_dataSize64)
  else
    f_rootChunk := nil;
end;

// --  --
function unaRIFile.releasePtr(baseAddr: pointer): bool;
begin
  if (nil <> f_mapFile) then
    result := f_mapFile.unmapView(baseAddr)
  else
    result := true;
end;


end.

