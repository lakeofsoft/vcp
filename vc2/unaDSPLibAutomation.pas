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

	  DSP Lib Automation
	----------------------------------------------
	  Copyright (c) 2007-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  modified by:
		Lake, Mar 2007
                Lake, Jun 2009

	----------------------------------------------

*)

{$i unaDef.inc }

{*
  Universal DSP processor.

  @Author Lake

  2.5.2008.07 Still here
}

unit
  unaDSPLibAutomation;

interface

uses
  Windows, unaTypes, unaClasses, unaDSPLibH;

const
  //
  c_defAutomatSection 	= 'dsplib.automat';


type
  unaDSPLibAutomat = class;


  {*
	List of DSP objects.
  }
  unaDSPLibObjectList = class(unaList)
  private
    f_automat: unaDSPLibAutomat;
  protected
    procedure releaseItem(index: int; doFree: unsigned); override;
  public
    constructor create(automat: unaDSPLibAutomat);
  end;


  {*
	Universal DSP automat.
  }
  unaDSPLibAutomat = class(unaObject)
  private
    f_root: unaDspLibAbstract;
    //f_gate: unaInProcessGate;
    f_objects: unaDSPLibObjectList;
    f_objectParams: unaStringList;
    //
    f_subAutos: unaObjectList;
    f_subAutosDirty: bool;
    //
    f_rate, f_bits, f_channels: int;
    f_bitsSHR: int;
    //
    f_inBuf, f_outBuf: pFloatArray;
    f_bufSize: int;
    f_multiOutBuf: unaRecordList;
    f_multiOutBufSize: int;
    //
    f_defIni: unaIniAbstractStorage;
    f_defSection: string;
    //
    function isMultiOutID(id: dspl_int): bool;
    function isMultiOutObj(obj: dspl_handle): bool;
    function bufAllocate(nSamples: int; checkMultiOutOnly: bool = false): HRESULT;
    procedure assignBuf2obj(obj: dspl_handle);
    procedure convertFloatIn(data: pointer; samples: int; channel: int);
    procedure convertFloatOut(data: pointer; samples: int; channel: int);
    function processChunkChannel(data: pointer; channel, nSamples: unsigned; forceProcessByMe: bool = false; writeOutput: bool = true): HRESULT;
  public
    constructor create(root: unaDspLibAbstract);
    procedure AfterConstruction(); override;
    procedure BeforeDestruction(); override;
    //
    {*
      //
      Loads the automat configuration from a ini storage.
    }
    function automatLoad(ini: unaIniAbstractStorage; const sectionName: string = c_defAutomatSection): HRESULT; overload;
    {*
      //
      Loads the automat configuration from a string.
    }
    function automatLoad(const config: string): HRESULT; overload;
    //
    {*
      //
      Saves the automat configuration.
      If unaIniAbstractStorage is nil (default) the one provided in last call of automatLoad() will be used.
      If automatLoad() was not called before, the funtion will fail.
      //
      If sectionName is '' (default) the name provided in automatLoad() will be used.
      If automatLoad() was not called before, c_defAutomatSection will be used as section name.
    }
    function automatSave(ini: unaIniAbstractStorage = nil; const sectionName: string = ''): HRESULT; overload;
    {*
      //
      Saves the automat configuration as a string.
    }
    function automatSave(out config: string): HRESULT; overload;
    //
    {*
      Specifies audio stream format. Only mono streams are supported.
    }
    function setFormat(rate, bits, channels: int; isSubAuto: bool = false): HRESULT;
    {*
      Processes an audio chunk. Use channel to specify channel number in a non-mono stream.
      Output data will be saved in provided buffer, or in case of multiOut object, output
      data can be read using getOutData() method.
      //
      NOTE: only one automat must be used to process one channel, so do not use one automat to
	    process left and right channels consequently, this will not provide any good results.
	    When you do not specify a channel number, automat will create internal automats
	    one per each channel for non-mono streams.
      //
      NOTE: multiOut objects will overwrite the output buffers of each other. Currently only
	    one multiOut object per automat is supported.
    }
    function processChunk(data: pointer; len: unsigned; channel: int = -1; nSamples: int = -1; writeOutput: bool = true): HRESULT;
    //
    {*
      Returns raw output audio buffer assigned to objects.
    }
    function getOutData(channel: unsigned; out data: pdspl_float; out nSamples: unsigned): HRESULT;
    {*
      Returns raw output audio buffer assigned to multi-output objects.
      Parameter n specifies the number of output stream (band), and must be from 0 to num of outputs - 1.
    }
    function getMultiOutData(channel: unsigned; n: unsigned; out data: pdspl_float; out nSamples: unsigned): HRESULT;
    {*
      Returns number of audio samples which can be stored in specified number of bytes.
    }
    function bytes2samples(numBytes: int): int;
    //
    {*
      Returns number of DSPLib objects.
    }
    function dspl_objCount(): int;
    {*
      Returns a DSPLib object handle.
    }
    function dspl_objGet(index: int): dspl_handle;
    {*
      Creates new DSPLib object of a given type.
    }
    function dspl_objNew(objID: int): dspl_handle;
    {*
      Returns the index of a DSPLib object in the list.
    }
    function dspl_objIndex(obj: dspl_handle): int;
    {*
      Removes DSPLib object from the list.
    }
    function dspl_objDrop(index: int): dspl_result;
    {*
      Exchanges two DSPLib object places.
    }
    function dspl_objSwap(index1, index2: int): dspl_result;
    //
    {*
      Sets an integer property of a DSPLib object.
    }
    function dspl_obj_seti(obj: dspl_handle; param_id: int; value: dspl_int): dspl_result;
    {*
      Sets an integer property of a DSPLib object.
    }
    function dspl_obj_setf(obj: dspl_handle; param_id: int; value: dspl_float): dspl_result;
    {*
      Sets an integer property of a DSPLib object.
    }
    function dspl_obj_setc(obj: dspl_handle; param_id: int; const value: dspl_chunk): dspl_result; overload;
    function dspl_obj_setc(obj: dspl_handle; param_id: int; fp: pdspl_float; len: dspl_int): dspl_result; overload;
    {*
      Returns object parameter value.
    }
    function dspl_obj_getf(obj: dspl_handle; channel: int; param_id: int; out fp: dspl_float): dspl_result; overload;
    //
    {*
      Abstract DSPLib interface.
    }
    property root: unaDspLibAbstract read f_root;
  end;


implementation


uses
  unaUtils;


{ unaDSPLibObjectList }

// --  --
constructor unaDSPLibObjectList.create(automat: unaDSPLibAutomat);
begin
  f_automat := automat;
  //
  inherited create(uldt_obj);
  autoFree := false;
end;

// --  --
procedure unaDSPLibObjectList.releaseItem(index: int; doFree: unsigned);
var
  obj: dspl_handle;
begin
  if (0 <> doFree) then begin	// mapDoFree() is of no good here, since autoFree is false
    //
    try
      obj := dspl_handle(get(index));
      //
      if (DSPL_INVALID_HANDLE <> obj) then
	f_automat.f_root.destroyObj(obj);
    except
    end;
  end;
  //
  inherited releaseItem(index, doFree);	// items is freed already, so it should not try to release the object once more
end;


{ unaDSPLibAutomat }

// --  --
procedure unaDSPLibAutomat.AfterConstruction();
begin
  //
  inherited;
end;

// --  --
function unaDSPLibAutomat.automatLoad(const config: string): HRESULT;
var
  objId: int;
  obj: dspl_handle;
  i, j: int;
  numObjects: int;
  //
  numParams: int;
  paramID: int;
  paramType: aChar;
  paramValue: aString;
  paramValueC: dspl_chunk;
  paramValueF: dspl_float;
  paramValueI: dspl_int;
begin
  result := HRESULT(-1);
  with (unaStringList.create()) do begin
    //
    try
      if (self.acquire(false, 3000)) then try
        //
	text := config;
	//
	f_objects.clear();
	f_objectParams.clear();
	//
	// load and create objects
	numObjects := str2intInt(value['numObjects'], 0);
	i := 0;
	while (i < numObjects) do begin
	  //
	  objId := str2intInt(value['obj.' + int2str(i) + '.id'], 0);
	  if (0 < objId) then begin
	    //
	    obj := dspl_objNew(objId);
	    if (DSPL_INVALID_HANDLE <> obj) then begin
	      //
	      // load object params
	      numParams := str2intInt(value['obj.' + int2str(i) + '.numParams'], 0);
	      j := 0;
	      while (j < numParams) do begin
		//
		paramID := str2intInt(value['obj.' + int2str(i) + '.param.' + int2str(j) + '.id'], 0);
		paramValue := aString(value['obj.' + int2str(i) + '.param.' + int2str(j) + '.value']);
		if ('' <> trimS(paramValue)) then begin
		  //
		  paramType := aChar(System.upCase(char(paramValue[1])));
		  paramValue := aString(base64decode(aString(copy(paramValue, 2, maxInt))));
		end
		else
		  paramType := 'U';
		//
		if ((0 < paramId) and ('' <> paramValue)) then begin
		  //
		  case (paramType) of

		    'C': begin
		      // chunk, paramValue is base64 encoded binary data
		      paramValueC.r_fp := pdspl_float(@paramValue[1]);
		      paramValueC.r_len := length(paramValue) div sizeOf(paramValueC.r_fp^);
		      dspl_obj_setc(obj, paramId, paramValueC);
		    end;

		    'F': begin
		      //
		      if (length(paramValue) = sizeOf(paramValueF)) then begin
			//
			move(paramValue[1], paramValueF, sizeOf(paramValueF));
			dspl_obj_setf(obj, paramId, paramValueF);
		      end;
		    end;

		    'I': begin
		      //
		      if (length(paramValue) = sizeOf(paramValueI)) then begin
			//
			move(paramValue[1], paramValueI, sizeOf(paramValueI));
			dspl_obj_seti(obj, paramId, paramValueI);
		      end;
		    end;

		    else begin
		      // uknown param type
		    end;

		  end;
		  //
		end;
		//
		inc(j);
	      end;	// while (j < numParams) ...
	    end
	    else
	      f_objects.add(pointer(DSPL_INVALID_HANDLE));
	    //
	  end
	  else
	    f_objects.add(pointer(DSPL_INVALID_HANDLE));
	  //
	  inc(i);
	end;
	//
	//
	result := S_OK;
      finally
	self.releaseWO();
      end;
      //
    finally
      free();
    end;
  end;
end;

// --  --
function unaDSPLibAutomat.automatLoad(ini: unaIniAbstractStorage; const sectionName: string): HRESULT;
var
  v: string;
begin
  if (nil <> ini) then begin
    //
    f_defINI := ini;
    //
    if ('' <> trimS(sectionName)) then
      f_defSection := sectionName
    else
      f_defSection := c_defAutomatSection;
    //
    v := f_defIni.getSectionAsText(f_defSection);
    //
    result := automatLoad(v);
  end
  else
    result := HRESULT(-1);
end;

// --  --
function unaDSPLibAutomat.automatSave(out config: string): HRESULT;
var
  i, p, s: int;
  obj: dspl_handle;
  paramCount: int;
  paramID: string;
  paramValue: string;
begin
  result := HRESULT(-1);
  config := '';
  //
  if (acquire(true, 3000)) then begin
    //
    try
      config := '';
      if (lockNonEmptyList_r(f_objects, true, 3000  {$IFDEF DEBUG }, '.automatSave)'{$ENDIF DEBUG })) then try
	//
	config := 'numObjects=' + int2str(f_objects.count) + #13#10;
	//
	for i := 0 to f_objects.count - 1 do begin
	  //
	  obj := dspl_handle(f_objects.get(i));
	  config := config + 'obj.' + int2str(i) + '.id=' + int2str(f_root.getID(obj)) + #13#10;
	  //
	  paramCount := 0;
	  //
	  if (0 < f_objectParams.count) then begin
	    //
	    for p := 0 to f_objectParams.count - 1 do begin
	      //
	      paramID := f_objectParams.get(p);
	      s := pos('=', string(paramID));
	      if (1 < s) then begin
		//
		paramValue := copy(paramID, s + 1, maxInt);
		paramID := copy(paramID, 1, s - 1);
		if (1 = pos(int2str(obj) + '.', paramID)) then begin
		  //
		  paramID := copy(paramID, pos('.', string(paramID)) + 1, maxInt);
		  //
		  config := config + 'obj.' + int2str(i) + '.param.' + int2str(paramCount) + '.id=' + paramID + #13#10;
		  config := config + 'obj.' + int2str(i) + '.param.' + int2str(paramCount) + '.value=' + paramValue + #13#10;
		  //
		  inc(paramCount);
		end;
	      end;
	    end;	// for ..
	  end;
	  //
	  config := config + 'obj.' + int2str(i) + '.numParams=' + int2str(paramCount) + #13#10;
	end;
	//
      finally
	f_objects.unlockRO();
      end;
      //
      result := S_OK;
    finally
      releaseRO();
    end;
  end;
end;

// --  --
function unaDSPLibAutomat.automatSave(ini: unaIniAbstractStorage; const sectionName: string): HRESULT;
var
  sec: string;
  v: string;
begin
  if (nil <> f_defINI) then begin
    //
    if ('' <> trimS(sectionName)) then
      sec := sectionName
    else
      if ('' = f_defSection) then
	sec := c_defAutomatSection
      else
	sec := f_defSection;
    //
    result := automatSave(v);
    if (Succeeded(result)) then
      f_defIni.setSectionAsText(f_defSection, v);
  end
  else
    result := HRESULT(-1);
end;

// --  --
procedure unaDSPLibAutomat.BeforeDestruction();
begin
  if (acquire(false, 2000, false {$IFDEF DEBUG }, '.BeforeDestruction()' {$ENDIF DEBUG })) then begin
    try
      bufAllocate(0);	// release buffers
      //
      freeAndNil(f_subAutos);
      freeAndNil(f_objectParams);
      freeAndNil(f_objects);
      freeAndNil(f_multiOutBuf);
    finally
      releaseWO();
    end;
  end;
  //
  //freeAndNil(f_gate);
  inherited;
end;

// --  --
function unaDSPLibAutomat.bufAllocate(nSamples: int; checkMultiOutOnly: bool): HRESULT;
var
  i, j: int;
  p: pointer;
  n: dspl_int;
  obj: dspl_handle;
begin
  result := S_OK;
  //
  // buffers are too small or too large or should be unallocated?
  if ( (f_bufSize <> nSamples) or ((0 = nSamples) and (0 < f_bufSize)) or checkMultiOutOnly ) then begin
    //
    if (acquire(false, 3000)) then begin
      try
	if (not checkMultiOutOnly) then begin
	  //
	  mrealloc(f_inBuf,  sizeOf(f_inBuf[0])  * nSamples);
	  mrealloc(f_outBuf, sizeOf(f_outBuf[0]) * nSamples);
	  //
	  f_bufSize := nSamples;
	end;
	//
	if (0 < f_objects.count) then begin
	  //
	  for i := 0 to f_objects.count - 1 do begin
	    //
	    obj := dspl_objGet(i);
	    if (DSPL_INVALID_HANDLE <> obj) then begin
	      //
	      if (isMultiOutObj(obj)) then begin
		//
		// this is multi-out object, check if we have buffers allocated
		if (checkMultiOutOnly or (f_multiOutBufSize <> nSamples) ) then begin
		  //
		  n := root.geti(obj, DSPL_PID or DSPL_P_OTHER);	// number of out buffers
		  j := 0;
		  while (j < n) do begin
		    //
		    if (j < int(f_multiOutBuf.count)) then begin
		      // reallocate buffer size
		      p := f_multiOutBuf.get(j);
		      mrealloc(p, nSamples * sizeOf(dspl_float));
		      f_multiOutBuf.setItem(j, p, 0);
		    end
		    else
		      // add new buffer
		      f_multiOutBuf.add(malloc(nSamples * sizeOf(dspl_float)));
		    //
		    inc(j);
		  end;
		  //
		  f_multiOutBufSize := nSamples;
		end;
	      end;
	      //
	      assignBuf2Obj(obj);
	    end;
	  end;
	end;
	//
      finally
	releaseWO();
      end;
    end
    else
      result := HRESULT(-1);
    //
  end;
end;

// --  --
function unaDSPLibAutomat.bytes2samples(numBytes: int): int;
begin
  result := (numBytes shr f_bitsSHR) div f_channels;
end;

// --  --
procedure unaDSPLibAutomat.convertFloatIn(data: pointer; samples, channel: int);
var
  i: int;
  p: int;
begin
  if (1 = f_channels) and (1 > channel) and (32 = f_bits) then begin
    //
    // no need to transcode
    move(data^, f_inBuf^, samples * sizeOf(f_inBuf[0]));
  end
  else begin
    //
    if (channel < f_channels) then begin
      //
      p := channel;
      for i := 0 to samples - 1 do begin
	//
	case (f_bits) of

	   8: f_inBuf[i] := (pArray(data)[p] - $80) / $FF;
	  16: f_inBuf[i] := pInt16Array(data)[p] / $7FFF;
	  24: f_inBuf[i] := pInt32Array(data)[p] / $7FFFFF;
	  32: f_inBuf[i] := pFloatArray(data)[p];

	end;
	//
	inc(p, f_channels);
      end;
    end;
  end;
end;

// --  --
procedure unaDSPLibAutomat.convertFloatOut(data: pointer; samples, channel: int);
var
  i: int;
  p: int;
begin
  if (1 = f_channels) and (1 > channel) and (32 = f_bits) then begin
    //
    // no need to transcode
    move(f_outBuf^, data^, samples * sizeOf(f_outBuf[0]));
  end
  else begin
    //
    if (channel < f_channels) then begin
      //
      p := channel;
      for i := 0 to samples - 1 do begin
	//
	if (f_outBuf[i] > 1.0) then
	  f_outBuf[i] := 1.0;
	//
	if (f_outBuf[i] < -1.0) then
	  f_outBuf[i] := -1.0;
	//
	case (f_bits) of

	   8: pArray(data)[p] 	      := trunc(f_outBuf[i] * $FF + $80);
	  16: pInt16Array(data)[p]    := trunc(f_outBuf[i] * $7FFF);
	  24: pInt32Array(data)[p]    := trunc(f_outBuf[i] * $7FFFFF);
	  32: pFloatArray(data)[p]    := f_outBuf[i];

	end;
	//
	inc(p, f_channels);
      end;
    end;
  end;
end;

// --  --
constructor unaDSPLibAutomat.create(root: unaDspLibAbstract);
begin
  f_root := root;
  //
  //f_gate := unaInProcessGate.create();
  f_objects := unaDSPLibObjectList.create(self);
  f_objectParams := unaStringList.create();
  f_subAutos := unaObjectList.create();
  f_multiOutBuf := unaRecordList.create();
  f_multiOutBufSize := 0;
  //
  inherited create();
end;

// --  --
procedure unaDSPLibAutomat.assignBuf2obj(obj: dspl_handle);
var
  n: dspl_int;
begin
  root.setc(obj, DSPL_PID or DSPL_P_IN,  pdspl_float(f_inBuf),  f_bufSize);
  root.setc(obj, DSPL_PID or DSPL_P_OUT, pdspl_float(f_outBuf), f_bufSize);
  //
  if (isMultiOutObj(obj)) then begin
    //
    n := root.geti(obj, DSPL_PID or DSPL_P_OTHER);	// number of out buffers
    while (0 < n) do begin
      //
      dec(n);
      root.setc(obj, DSPL_PID or DSPL_P_OUT or n, pdspl_float(f_multiOutBuf.get(n)), f_multiOutBufSize);
    end;
  end;
end;

// --  --
function unaDSPLibAutomat.dspl_objCount(): int;
begin
  result := int(f_objects.count);
end;

// --  --
function unaDSPLibAutomat.dspl_objDrop(index: int): dspl_result;
var
  obj: dspl_handle;
  i: int;
begin
  result := false;
  //
  if (acquire(false, 3000)) then begin
    try
      obj := dspl_objGet(index);
      if (DSPL_INVALID_HANDLE <> obj) then begin
	//
	result := f_objects.removeByIndex(index);	// obj will be destroyed by DSPLib in that call
	if (result) then begin
	  //
	  // remove all params for this object as well
	  i := 0;
	  while (i < int(f_objectParams.count)) do begin
	    //
	    if (1 = pos(int2str(obj) + '.', f_objectParams.get(i))) then begin
	      //
	      f_objectParams.removeByIndex(i);
	    end
	    else
	      inc(i);
	    //
	  end;
	  //
	  f_subAutosDirty := true;
	end;
      end;
      //
    finally
      releaseWO();
    end;
  end;
end;

// --  --
function unaDSPLibAutomat.dspl_objGet(index: int): dspl_handle;
begin
  result := dspl_handle(f_objects.get(index));
end;

// --  --
function unaDSPLibAutomat.dspl_obj_getf(obj: dspl_handle; channel, param_id: int; out fp: dspl_float): dspl_result;
var
  idx: int;
begin
  result := DSPL_SUCCESS;
  if (0 = channel) then begin
    //
    fp := root.getf(obj, param_id);
  end
  else begin
    //
    result := DSPL_FAILURE;
    dec(channel);
    if (channel < int(f_subAutos.count)) then begin
      //
      idx := dspl_objIndex(obj);
      if (0 <= idx) then begin
	//
	obj := unaDSPLibAutomat(f_subAutos[channel]).dspl_objGet(idx);
	if (0 < obj) then begin
	  //
	  fp := unaDSPLibAutomat(f_subAutos[channel]).root.getf(obj, param_id);
	  result := DSPL_SUCCESS;
	end;
      end;
    end;
  end;
end;

// --  --
function unaDSPLibAutomat.dspl_objIndex(obj: dspl_handle): int;
begin
  result := f_objects.indexOf(obj);
end;

// --  --
function unaDSPLibAutomat.dspl_objNew(objID: int): dspl_handle;
begin
  result := f_root.createObj(objID);
  if (DSPL_INVALID_HANDLE <> result) then begin
    //
    f_objects.add(result);
    assignBuf2obj(result);
    //
    f_subAutosDirty := true;
  end;
end;

// --  --
function unaDSPLibAutomat.dspl_objSwap(index1, index2: int): dspl_result;
var
  obj1, obj2: dspl_handle;
begin
  result := DSPL_FAILURE;
  //
  if (lockNonEmptyList_r(f_objects, false, 3000 {$IFDEF DEBUG }, '.dspl_objSwap()'{$ENDIF DEBUG })) then begin
    try
      obj1 := dspl_objGet(index1);
      obj2 := dspl_objGet(index1);
      //
      f_objects.setItem(index1, pointer(obj2), 0);	// do not release older item
      f_objects.setItem(index2, pointer(obj1), 0);	// do not release older item
      //
      result := DSPL_SUCCESS;
      //
      f_subAutosDirty := true;
    finally
      f_objects.unlockWO();
    end;
  end;
end;

// --  --
function unaDSPLibAutomat.dspl_obj_setc(obj: dspl_handle; param_id: int; const value: dspl_chunk): dspl_result;
begin
  result := dspl_obj_setc(obj, param_id, value.r_fp, value.r_len);
end;

// --  --
function unaDSPLibAutomat.dspl_obj_setc(obj: dspl_handle; param_id: int; fp: pdspl_float; len: dspl_int): dspl_result;
var
  i: int;
  val: string;
  index: int;
begin
  if (acquire(false, 3000)) then begin
    try
      result := f_root.setc(obj, param_id, fp, len);
      if (DSPL_SUCCESS = result) then begin
	//
	if ( ( DSPL_PID or DSPL_P_IN   = (param_id and $F0F00) )
	     or
	     ( DSPL_PID or DSPL_P_OUT  = (param_id and $F0F00) )
	   ) then begin
	  //
	  // there is no need to save IN/OUT buffers in config
	end
	else begin
	  //
	  if ((nil <> fp) and (0 < len)) then
	    val := string(base64encode(fp, len * sizeOf(fp^)))
	  else
	    val := '';
	  //
	  f_objectParams.value[int2str(obj) + '.' + int2str(param_id)] := 'C' + val;
	  //
	  if (not f_subAutosDirty and (0 < f_subAutos.count)) then begin
	    //
	    index := dspl_objIndex(obj);
	    for i := 0 to f_subAutos.count - 1 do begin
	      //
	      if (index < unaDSPLibAutomat(f_subAutos[i]).dspl_objCount()) then begin
		//
		obj := unaDSPLibAutomat(f_subAutos[i]).dspl_objGet(index);
		unaDSPLibAutomat(f_subAutos[i]).dspl_obj_setc(obj, param_id, fp, len);
	      end
	      else begin
		//
		f_subAutosDirty := true;
		break;
	      end;
	    end;
	  end;
	end;
	//
      end;
      //
    finally
      releaseWO();
    end;
  end
  else
    result := false;
end;

// --  --
function unaDSPLibAutomat.dspl_obj_setf(obj: dspl_handle; param_id: int; value: dspl_float): dspl_result;
var
  i: int;
  index: int;
begin
  if (acquire(false, 2000, false {$IFDEF DEBUG }, '.dspl_obj_setf()' {$ENDIF DEBUG } )) then begin
    try
      result := f_root.setf(obj, param_id, value);
      if (DSPL_SUCCESS = result) then begin
	//
	f_objectParams.value[int2str(obj) + '.' + int2str(param_id)] := 'F' + string(base64encode(@value, sizeOf(value)));
	//
	if (not f_subAutosDirty and (0 < f_subAutos.count)) then begin
	  //
	  index := dspl_objIndex(obj);
	  for i := 0 to f_subAutos.count - 1 do begin
	    //
	    if (index < unaDSPLibAutomat(f_subAutos[i]).dspl_objCount()) then begin
	      //
	      obj := unaDSPLibAutomat(f_subAutos[i]).dspl_objGet(index);
	      unaDSPLibAutomat(f_subAutos[i]).dspl_obj_setf(obj, param_id, value);
	    end
	    else begin
	      //
	      f_subAutosDirty := true;
	      break;
	    end;
	  end;
	end;
      end;
      //
    finally
      releaseWO();
    end;
  end
  else
    result := false;
end;

// --  --
function unaDSPLibAutomat.dspl_obj_seti(obj: dspl_handle; param_id: int; value: dspl_int): dspl_result;
var
  i: int;
  index: int;
begin
  if (acquire(false, 3000)) then begin
    try
      result := f_root.seti(obj, param_id, value);
      if (DSPL_SUCCESS = result) then begin
	//
	f_objectParams.value[int2str(obj) + '.' + int2str(param_id)] := 'I' + string(base64encode(@value, sizeOf(value)));
	//
	if (isMultiOutObj(obj) and (DSPL_PID or DSPL_P_OTHER = param_id)) then
	  // number of out buffers may change, so check buffer allocation once more
	  bufAllocate(f_multiOutBufSize, true);
	//
	if (not f_subAutosDirty and (0 < f_subAutos.count)) then begin
	  //
	  index := dspl_objIndex(obj);
	  for i := 0 to f_subAutos.count - 1 do begin
	    //
	    if (index < unaDSPLibAutomat(f_subAutos[i]).dspl_objCount()) then begin
	      //
	      obj := unaDSPLibAutomat(f_subAutos[i]).dspl_objGet(index);
	      unaDSPLibAutomat(f_subAutos[i]).dspl_obj_seti(obj, param_id, value);
	    end
	    else begin
	      //
	      f_subAutosDirty := true;
	      break;
	    end;
	  end;
	end;
      end;
      //
    finally
      releaseWO();
    end;
  end
  else
    result := false;
end;

// --  --
function unaDSPLibAutomat.getMultiOutData(channel, n: unsigned; out data: pdspl_float; out nSamples: unsigned): HRESULT;
var
  buf: unaList;
begin
  if (0 = channel) then
    buf := f_multiOutBuf
  else begin
    //
    if (int(channel) <= f_subAutos.count) then
      buf := unaDSPLibAutomat(f_subAutos[channel - 1]).f_multiOutBuf
    else
      buf := nil;
    //
  end;
  //
  if (nil <> buf) then begin
    //
    if (int(n) < buf.count) then begin
      //
      data := buf[n];
      nSamples := f_multiOutBufSize;
      //
      result := S_OK;
    end
    else
      result := E_FAIL;
    //
  end
  else
    result := E_FAIL;
  //
end;

// --  --
function unaDSPLibAutomat.getOutData(channel: unsigned; out data: pdspl_float; out nSamples: unsigned): HRESULT;
begin
  result := S_OK;
  //
  if (0 = channel) then begin
    //
    data := pointer(f_outBuf);
    nSamples := f_bufSize;
  end
  else begin
    //
    if (int(channel) <= f_subAutos.count) then begin
      //
      data := pointer(unaDSPLibAutomat(f_subAutos[channel - 1]).f_outBuf);
      nSamples := unaDSPLibAutomat(f_subAutos[channel - 1]).f_bufSize;
    end
    else
      result := E_FAIL;
    //
  end;
end;

// --  --
function unaDSPLibAutomat.isMultiOutID(id: dspl_int): bool;
begin
  result := (DSPL_OID or DSPL_MBSP = id);
end;

// --  --
function unaDSPLibAutomat.isMultiOutObj(obj: dspl_handle): bool;
begin
  result := isMultiOutID(root.getID(obj));
end;

// --  --
function unaDSPLibAutomat.processChunk(data: pointer; len: unsigned; channel, nSamples: int; writeOutput: bool): HRESULT;
var
  i, ch: int;
  config: string;
begin
  result := HRESULT(-1);
  if (acquire(true, 3000)) then begin
    //
    try
      result := S_OK;
      //
      if (0 <= nSamples) then
	nSamples := min(nSamples, bytes2samples(len))
      else
	nSamples := bytes2samples(len);
      //
      if ((0 > channel) and (1 < f_channels)) then begin
	//
	// we have more than one channel, and no specific channel was provided, so we have to make sure sub-automats are ready
	//
	if (f_subAutosDirty) then begin
	  //
	  // we have to assign same objects for all autos we have
	  automatSave(config);
	  if (0 < f_subAutos.count) then begin
	    //
	    for i := 0 to f_subAutos.count - 1 do begin
	      //
	      with (unaDSPLibAutomat(f_subAutos[i])) do begin
		//
		setFormat(self.f_rate, self.f_bits, self.f_channels, true);
		automatLoad(config);
		//
		bufAllocate(nSamples);
	      end;
	    end;
	  end;
	  //
	  f_subAutosDirty := false;
	end;
      end;
      //
      result := bufAllocate(nSamples);
      //
      if (Succeeded(result)) then begin
	//
	if (0 > channel) then begin
	  //
	  for ch := 0 to f_channels - 1 do begin
	    try
	      processChunkChannel(data, ch, nSamples, false, writeOutput);
	    except
	      // ignore excepts, if any, process other channels
	    end;
	  end;
	end
	else
	  result := processChunkChannel(data, channel, nSamples, false, writeOutput);
	//
      end;
      //
    finally
      releaseRO();
    end;
  end;
end;

// --  --
function unaDSPLibAutomat.processChunkChannel(data: pointer; channel, nSamples: unsigned; forceProcessByMe, writeOutput: bool): HRESULT;
var
  i: int;
  obj: dspl_handle;
  subAuto: unaDSPLibAutomat;
begin
  result := S_OK;
  //
  if (0 < f_objects.count) then begin
    //
    if ((0 = channel) or forceProcessByMe) then begin
      //
      // channel #0 is always processed using main automat
      for i := 0 to f_objects.count - 1 do begin
	//
	convertFloatIn(data, nSamples, channel);
	obj := dspl_objGet(i);
	try
	  //
	  root.process(obj, nSamples);
	finally
	  if (isMultiOutObj(obj)) then begin
	    //
	    // nothing to convert, output buffers alreay contain all information
	  end
	  else
	    if (writeOutput) then
	      convertFloatOut(data, nSamples, channel);
	end;
      end;
    end
    else begin
      //
      // other channels are always processed using sub-automat(s)
      subAuto := f_subAutos[channel - 1];
      if (nil <> subAuto) then
	result := subAuto.processChunkChannel(data, channel, nSamples, true, writeOutput)	// force processing by this auto
      else
	result := HRESULT(-1);	// no sub-auto for this channel..
    end;
    //
  end
  else
    move(f_inBuf^, f_outBuf^, nSamples * sizeOf(f_outBuf[0]));	// just copy all samples to outbuf when we have no filters
end;

// --  --
function unaDSPLibAutomat.setFormat(rate, bits, channels: int; isSubAuto: bool): HRESULT;
var
  i: int;
begin
  result := E_FAIL;
  //
  if ((0 < rate) and (bits in [8, 16, 24, 32]) and (0 < channels)) then begin
    //
    if (acquire(false, 2000, false {$IFDEF DEBUG }, '.setFormat()' {$ENDIF DEBUG } )) then begin
      //
      try
	f_rate := rate;
	f_bits := bits;
	f_channels := channels;
	//
	if (24 = f_bits) then
	  f_bitsSHR := 32 shr 4
	else
	  f_bitsSHR := f_bits shr 4;
	//
	f_subAutos.clear();
	if ((1 < channels) and not isSubAuto) then begin
	  //
	  for i := 1 to channels - 1 do
	    f_subAutos.add(unaDSPLibAutomat.create(root));
	  //
	  f_subAutosDirty := true;
	end;
	//
	result := S_OK;
      finally
	releaseWO();
      end;
    end;
  end;
end;


end.

