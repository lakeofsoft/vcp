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

	  unaVC_pipe.pas - VC 2.5 basic pipe component
	  Voice Communicator components version 2.5 Pro

	----------------------------------------------
	  Copyright (c) 2002-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 01 Jun 2002

	  modified by:
		Lake, Jun-Dec 2002
		Lake, Jan-Dec 2003
		Lake, Jan-May 2004
		Lake, May-Oct 2005
		Lake, Mar-Dec 2007
		Lake, Jan-Nov 2008
		Lake, Jan-May 2009
		Lake, May 2010

	----------------------------------------------
*)

{$I unaDef.inc}

{$IFDEF DEBUG }
  //
  {$DEFINE LOG_UNAVC_PIPE_INFOS }	// log informational messages
  {xx $DEFINE LOG_UNAVC_PIPE_INFOEX }	// log extra informational messages
  {$DEFINE LOG_UNAVC_PIPE_ERRORS }	// log critical errors
{$ENDIF DEBUG }

{xx $DEFINE LOG_DUMP_TEXTHEADER }		// define to log textual headers into DumpOutput file

{*
  Contains basic pipe class - unavclInOutPipe.

  @Author Lake
  
Version 2.5.2008.02 Split from unaVCIDE.pas unit
}

unit
  unaVC_pipe;

interface

uses
  Windows, unaTypes, unaUtils, unaClasses,
  Classes;


// ------------------------------------
//  -- basic abstract pipe component --
// ------------------------------------


const
  //
// Size of proxy thread data array
  c_proxyDataArraySize	= 64;	

  //
  // ignore provider options
  unavcl_ipo_autoActivate	= $0001;
  unavcl_ipo_formatProvider	= $0002;


type
  // -- ahead declarations --
  unavclInOutPipe = class;
  unavclInOutPipeClass = class of unavclInOutPipe;

  {*
    Data availability notification event.
  }
  unavclPipeDataEvent = procedure(sender: unavclInOutPipe; data: pointer; len: cardinal) of object;

  {*
    Before format change notification event.
  }
  unavclPipeBeforeFormatChangeEvent = procedure(sender: unavclInOutPipe; provider: unavclInOutPipe; newFormat: pointer; len: cardinal; out allowFormatChange: bool) of object;

  {*
    After format change notification event.
  }
  unavclPipeAfterFormatChangeEvent = procedure(sender: unavclInOutPipe; provider: unavclInOutPipe; newFormat: pointer; len: cardinal) of object;


  //
  // -- unavclInOutPipe --
  //
  {*
    Base abstract class for all components.
  }
  unavclInOutPipe = class(tComponent)
  private
    f_lockObj: unaObject;
    //
    f_shouldActivate: bool;
    f_isFormatProvider: boolean;
    f_autoActivate: boolean;
    f_enableDataProxy: boolean;
    //
    f_closing: bool;
    //
    f_activateState: int;	//  0 - none
				// +1 - setting active := true
				// -1 - setting active := false
    //
    f_enableDP: boolean;
    //
    f_dumpOutput: wideString;
    f_dumpInput: wideString;
    f_dumpOutputOK: bool;
    f_dumpInputOK: bool;
    //
    f_ipo: unsigned;
    //
    f_inBytes: array[0..7] of int64;
    f_outBytes: array[0..7] of int64;
    //
    f_dataAvail: unavclPipeDataEvent;
    f_dataDSP: unavclPipeDataEvent;
    //
    f_afterFormatChange: unavclPipeAfterFormatChangeEvent;
    f_beforeFormatChange: unavclPipeBeforeFormatChangeEvent;
    //
    f_formatCRC: uint;
    //
    f_consumers: unaObjectList;
    f_providers: unaObjectList;
    f_dataProxyThread: unaThread;
    //
    procedure triggerDataAvailEvent(data: pointer; len: uint);
    procedure triggerDataDSPEvent(data: pointer; len: uint);
    //
    function getActive(): boolean;
    procedure setActive(value: boolean);
    //
    function getConsumerOneAndOnly(): unavclInOutPipe;
    function getProviderOneAndOnly(): unavclInOutPipe;
    procedure setConsumerOneAndOnly(value: unavclInOutPipe);
    function applyFormatOnConsumers(data: pointer; len: uint; restoreActiveState: bool; provider: unavclInOutPipe): bool;
    //
    procedure setEnableDP(value: boolean);
    {*
	Returns number of consumers.

	@return Number of consumers.
    }
    function getConsumerCount(): int;
    {*
	Returns number of providers.

	@return Number of providers.
    }
    function getProviderCount(): int;
    {*
	Returns consumer.

	@param index Index of consumer (from 0 to getConsumerCount() - 1).

	@return Consumer of a pipe.
    }
    function getConsumer(index: int = 0): unavclInOutPipe;
    {*
	Returns provider.

	@param index Index of consumer (from 0 to getProviderCount() - 1).

	@return Provider of a pipe.
    }
    function getProvider(index: int = 0): unavclInOutPipe;
    function getInBytes(index: int): int64;
    function getOutBytes(index: int): int64;
  protected
    {*
      Writes data into the pipe.
    }
    function doWrite(data: pointer; len: uint; provider: pointer = nil): uint; virtual; abstract;
    {*
      Reads data from the pipe.
    }
    function doRead(data: pointer; len: uint): uint; virtual; abstract;
    {*
      Returns data size available in the pipe (bytes).
    }
    function getAvailableDataLen(index: integer): uint; virtual; abstract;
    {*
	Increments (or decrements) in/outBytes property by delta.

	@param index counter index, from 0 to 7. 0 is reserved for consumers/providers, 1 for network
	@param isIn true for input
	@param delta delta size
	@return New value of in/outBytes
    }
    function incInOutBytes(index: int; isIn: bool; delta: int): int64;
    {*
	Opens the pipe.
    }
    function doOpen(): bool; virtual;
    {*
	Closes the pipe.
    }
    procedure doClose(); virtual;
    {*
	Returns component's active state.

	@return True if component was activated succesfully.
    }
    function isActive(): bool; virtual; abstract;
    {*
	Sets active state of the pipe.
    }
    function doSetActive(value: bool; timeout: tTimeout = 3000; provider: unavclInOutPipe = nil): bool;
    {*
	Processes new data available from the pipe.

	@return True if successfull.
    }
    function onNewData(data: pointer; len: uint; provider: pointer = nil): bool; virtual;
    {*
	Applies new format of the data stream.

	@return True if successfull.
    }
    function applyFormat(data: pointer; len: uint; provider: unavclInOutPipe = nil; restoreActiveState: bool = false): bool; virtual;
    {*
	Fills the format of the data stream.

	@return Stream data format.
    }
    function getFormatExchangeData(out data: pointer): uint; virtual;
    {*
	Calls f_beforeFormatChange or f_afterFormatChange if assigned.
    }
    procedure doBeforeAfterFC(doBefore: bool; provider: unavclInOutPipe; data: pointer; len: uint; out allowFC: bool);
    {*
	Checks if component is format provider and applies format to consumer if it is (and format was not applied before).
    }
    function checkIfFormatProvider(restoreActiveState: bool): bool;
    {*
	Checks if autoActivate property is True and activates/deactivates consumers if yes.
    }
    function checkIfAutoActivate(value: bool; timeout: tTimeout = 10054): bool;
    {*
	Implements positions retrieval routine.

	@return Current position in stream (if applicable).
    }
    function doGetPosition(): int64; virtual;
    {*
	Assigns new provider for the pipe.
	Not all components are designed to work with more that one provider.

	@return True if successfull.
    }
    function doAddProvider(provider: unavclInOutPipe): bool; virtual;
    {*
	Removes one of pipe's providers.
    }
    procedure doRemoveProvider(provider: unavclInOutPipe); virtual;
    {*
	Adds new consumer for the pipe.

	@return True if successfull.
    }
    function doAddConsumer(consumer: unavclInOutPipe; forceNewFormat: bool = true): bool; virtual;
    {*
	Removes consumer from the pipe.
    }
    procedure doRemoveConsumer(consumer: unavclInOutPipe); virtual;
    {*
	Notify all consumers there is no more such provider (self).
    }
    procedure notifyConsumers();
    {*
	Notify all providers there is new consumer (self), or consumer is removed (value = nil).
    }
    procedure notifyProviders(value: unavclInOutPipe);
    {*
	Sets enableDataProcessing value.
    }
    procedure doSetEnableDP(value: boolean); virtual;
    {*
	Usually creates an internal device of the pipe, and activates the component if needed.
    }
    procedure Loaded(); override;
    {*
	IDE/VCL notification for components removal/insertion.
    }
    procedure Notification(component: tComponent; operation: tOperation); override;
    {*
	True if component is being closed.
    }
    property closing: bool read f_closing write f_closing;
    {*
	List of consumers.
    }
    property _consumers: unaObjectList read f_consumers;
    {*
	List of providers.
    }
    property _providers: unaObjectList read f_providers;
    {*
      When True the component will assign stream format to the consumer (if any).
      This simplifies the process of distributing stream format among linked components.

      For example @link unavclWaveRiff component
      can assign PCM format for linked @link unavclWaveOutDevice
      component, so WAVe file will be played back correctly.
    }
    property isFormatProvider: boolean read f_isFormatProvider write f_isFormatProvider default false;
    {*
	Data will be placed to proxy thread before processing.
	This allows component to return from the write() method as soon as possible.
    }
    property enableDataProxy: boolean read f_enableDataProxy write f_enableDataProxy default false;
    //
    // -- EVENTS --
    //
    {*
      This event is fired every time component has produced or received new chunk of data.
      Use this event to access the raw stream data.
      Any modifications you made with data will not affect data consumers.
      To modify data before it will passed to consumers, use onDataDSP() event.

      NOTE: VCL is NOT multi-threading safe, and you should avoid using VCL routines and classes in this event
    }
    property onDataAvailable: unavclPipeDataEvent read f_dataAvail write f_dataAvail;
    {*
      This event is fired every time component has produced or received new
      chunk of data.
      Use this event to access the raw stream data.
      Any modifications you made on data will be passed to comsumers.
      To modify data without affecting consumers, use onDataAvailable() event.

      NOTE: VCL is NOT multi-threading safe, and you should avoid using VCL routines and classes in this event
    }
    property onDataDSP: unavclPipeDataEvent read f_dataDSP write f_dataDSP;
    {*
      This event is fired after new format was applied to a pipe.

      NOTE: VCL is NOT multi-threading safe, and you should avoid using VCL routines and classes in this event
    }
    property onFormatChangeAfter: unavclPipeAfterFormatChangeEvent read f_afterFormatChange write f_afterFormatChange;
    {*
      This event is fired before new format is about to be applied to a pipe.
      Using allowFormatChange parameter it is possible to disable format's applying.

      NOTE: VCL is NOT multi-threading safe, and you should avoid using VCL routines and classes in this event
    }
    property onFormatChangeBefore: unavclPipeBeforeFormatChangeEvent read f_beforeFormatChange write f_beforeFormatChange;
  public
    {*
	Creates list of consumers and providers, internal critical section and data proxy thread.
    }
    procedure AfterConstruction(); override;
    {*
	Destroys the pipe.
    }
    procedure BeforeDestruction(); override;
    {*
	Enters the internal critical section.

	@param ro True for read-only lock.
	@return True if critical section was entered.
    }
    function enter(ro: bool; timeout: tTimeout = 100): bool;
    {*
	Leaves the internal critical section.
    }
    procedure leaveRO();
    procedure leaveWO();
    {*
	Writes data into the pipe.

	@param data Data to write into the pipe.
	@param len Size of memory block pointed by data parameter.
	@param provider Provider of the data (if any).

	@return Number of bytes actually written.
    }
    function write(data: pointer; len: uint; provider: unavclInOutPipe = nil): uint; overload;
    {*
	Writes data into the pipe.

	@param data Data to write into the pipe.
	@param provider Provider of the data (if any).

	@return Number of bytes actually written.
    }
    function write(const data: aString; provider: unavclInOutPipe = nil): uint; overload;
    {*
	If you did not specify the consumer for the pipe, you must call
	this method periodically to access the stream output data.
	Best place to do that is in onDataAvailable() event handler.

	@return Number of bytes actually read.
    }
    function read(data: pointer; len: uint): uint; overload;
    {*
	Reads data as a AnsiString.

	@return Data read.
    }
    function read(): aString; overload;
    {*
	Opens the pipe.

	@return True if successfull.
    }
    function open(provider: unavclInOutPipe = nil): bool;
    {*
	Closes the pipe.
    }
    procedure close(timeout: tTimeout = 0; provider: unavclInOutPipe = nil);
    {*
	Adds new provider for the pipe.

	@param provider Provider to be added.

	@return True if successfull.
    }
    function addProvider(provider: unavclInOutPipe): bool;
    {*
	Removes one of pipe's providers.

	@param provider Provider to be removed.
    }
    procedure removeProvider(provider: unavclInOutPipe);
    {*
	Adds new consumer for the pipe.

	@param consumer Consumer to add.

	@return True if successfull.
    }
    function addConsumer(consumer: unavclInOutPipe; forceNewFormat: bool = true): bool;
    {*
	Removes consumer from the pipe.
    }
    procedure removeConsumer(consumer: unavclInOutPipe);
    {*
	Returns index of consumer.

	@return index of specified consumer.
    }
    function getConsumerIndex(value: unavclInOutPipe): int;
    {*
	Returns index of provider.

	@return index of specified provider.
    }
    function getProviderIndex(value: unavclInOutPipe): int;
    {*
	Returns position in stream.

	@return Current position in stream (if applicable).
    }
    function getPosition(): int64;
    {*
	Forces component to assign its format to consumers (if isFormatProvider is True).
	Call this method before activation.
    }
    procedure clearFormatCRC();
    //
    // -- PROPERTIES --
    //
    {*
	Returns data written into but not yet processed by the pipe.
    }
    property availableDataLenIn: uint index 0 read getAvailableDataLen;
    {*
	Returns data size available to read from the pipe.
    }
    property availableDataLenOut: uint index 1 read getAvailableDataLen;
    {*
	Number of bytes received by the pipe.

	@param index 0 - received from providers; 1 - received from network
    }
    property inBytes[index: int]: int64 read getInBytes;
    {*
	Number of bytes produced by the pipe.

	@param index 0 - sent to consumers; 1 - sent to network
    }
    property outBytes[index: int]: int64 read getOutBytes;
    {*
	Specifies whether the component would perform any data processing.
    }
    property enableDataProcessing: boolean read f_enableDP write setEnableDP default True;
    {*
	Current position in stream (if applicable).
    }
    property position: int64 read getPosition;
    {*
	Returns first provider of a component (if any).
    }
    property providerOneAndOnly: unavclInOutPipe read getProviderOneAndOnly;
    {*
	Returns consumer.

	@param index Index of consumer (from 0 to consumerCount - 1).

	@return Consumer of a pipe.
    }
    property consumers[index: int]: unavclInOutPipe read getConsumer;
    {*
	Returns provider.

	@param index Index of consumer (from 0 to getProviderCount() - 1).

	@return Provider of a pipe.
    }
    property providers[index: int]: unavclInOutPipe read getProvider;
    {*
	Number of consumers.
    }
    property consumerCount: int read getConsumerCount;
    {*
	Number of providers.
    }
    property providerCount: int read getProviderCount;
    {*
	Specifies which proviers options will be ignored.
    }
    property ignoreProviderOptions: unsigned read f_ipo write f_ipo;
  published
    //
    // -- PROPERTIES --
    //
    {*
	Returns or sets the active state of the pipe.
	Set to True to activate (open) the component.
	All other properties should be set to proper values before activation.
	Set to False to deactivate (close) the component.
    }
    property active: boolean read getActive write setActive default false;
    {*
      Specifies the consumer of component.
      When set, specified consumer will receive all the stream data
      from the component.
      This allows linking the components to create a data flow chain.
    }
    property consumer: unavclInOutPipe read getConsumerOneAndOnly write setConsumerOneAndOnly;
    {*
      Specifies the file name to store the stream into.
      dumpInput is be used to store the input stream,
      which is coming as input for component.
      Stream will be saved in "as is" format.

      For example, @link unavclWaveOutDevice will
      store input stream as a sequence of PCM samples.
    }
    property dumpInput: wideString read f_dumpInput write f_dumpInput;
    {*
      Specifies the file name to store the stream into.
      dumpOutput is be used to store the output stream, which is coming as
      output from the component.
      Stream will be saved in "as is" format.

      For example, @link unavclWaveInDevice will
      store output stream as sequence of PCM samples.
    }
    property dumpOutput: wideString read f_dumpOutput write f_dumpOutput;
    {*
       When True tells the component it must activate consumer (if any)
       before activating itself. Same applies for deactivation.

       When @False the component does not change the consumer state.
    }
    property autoActivate: boolean read f_autoActivate write f_autoActivate default true;
  end;

  {*
	Non-absract dummy implementation of base pipe
  }
  unavclInOutPipeImpl = class(unavclInOutPipe)
  protected
    function doWrite(data: pointer; len: uint; provider: pointer = nil): uint; override;
    function doRead(data: pointer; len: uint): uint; override;
    function getAvailableDataLen(index: integer): uint; override;
    function isActive(): bool; override;
  end;


implementation


type
  //
  // -- unaDataProxyChunk --
  //
  punaDataProxyChunk = ^tunaDataProxyChunk;
  tunaDataProxyChunk = record
    r_len: uint;		// chunk data size
    r_provider: pointer;	// not a gtreat idea of storing pointers, but..
    r_data: pointer;		// data itself
    r_dataSize: uint;   	// size of data buffer allocated so far
{$IFDEF DEBUG }
    r_leadIn: uint64;		// time when buffer was filled
{$ENDIF DEBUG }
  end;


  //
  // -- unaDataProxyThread --
  //
  unaDataProxyThread = class(unaThread)
  private
    //
    //  /------- order of fields is important ---------\
    f_dataArray: array[0..c_proxyDataArraySize - 1] of tunaDataProxyChunk;
    f_head: unsigned;
    f_tail: unsigned;
    //  \------- order of fields is important ---------/
    //
{$IFDEF DEBUG}
    f_totalLatency: uint64;
{$ENDIF DEBUG }
    f_owner: unavclInOutPipe;
    f_destroying: bool;
    //
    f_dataEvent: unaEvent;
    //
    function write(data: pointer; len: uint; provider: unavclInOutPipe = nil): uint; overload;
  protected
    function execute(globalIndex: unsigned): int; override;
    //
    procedure startIn(); override;
  public
    constructor create(owner: unavclInOutPipe);
    procedure AfterConstruction(); override;
    procedure BeforeDestruction(); override;
  end;


{ unaDataProxyThread }

// --  --
procedure unaDataProxyThread.afterConstruction();
begin
  inherited;
  //
  fillChar(f_dataArray, sizeOf(f_dataArray), #0);
  //
  f_dataEvent := unaEvent.create();
end;

// --  --
procedure unaDataProxyThread.beforeDestruction();
var
  i: integer;
begin
  f_destroying := true; // make sure write() will not start the thread again
  //
  inherited;
  //
  i := low(f_dataArray);
  while (i <= high(f_dataArray)) do begin
    //
    mrealloc(f_dataArray[i].r_data);
    inc(i);
  end;
  //
  freeAndNil(f_dataEvent);
end;

// --  --
constructor unaDataProxyThread.create(owner: unavclInOutPipe);
begin
  f_owner := owner;
  //
  inherited create(false, THREAD_PRIORITY_TIME_CRITICAL);
end;

// --  --
function unaDataProxyThread.execute(globalIndex: unsigned): int;
var
  fileCopy: bool;
begin
  fileCopy := f_owner.f_dumpInputOK;
  //
  while (not shouldStop) do begin
    //
    try
      if ((f_tail <> f_head) or f_dataEvent.waitFor(100)) then begin
	//
	while (not shouldStop and (f_tail <> f_head)) do begin
          //
	  inc(f_tail);
	  if (f_tail > high(f_dataArray)) then
	    f_tail := low(f_dataArray);
	  //
	  with (f_dataArray[f_tail]) do begin
	    //
  {$IFDEF DEBUG }
	    inc(f_totalLatency, timeElapsed64U(r_leadIn));
  {$ENDIF DEBUG }
	    f_owner.doWrite(r_data, r_len, r_provider);
	    //
	    if (fileCopy) then
	      writeToFile(f_owner.dumpInput, r_data, r_len);
	  end;
	end;
      end;
      //
    except
      // ignore exceptions
    end;

  end;
  //
  result := 0;
end;

// --  --
procedure unaDataProxyThread.startIn();
begin
{$IFDEF DEBUG}
  f_totalLatency := 0;
{$ENDIF}
  f_tail := low(f_dataArray);
  f_head := f_tail;	// make snake zero length
  //
  inherited;
end;

// --  --
function unaDataProxyThread.write(data: pointer; len: uint; provider: unavclInOutPipe): uint;
var
  newHead: unsigned;
{$IFDEF DEBUG }
  leadIn: uint64;
{$ENDIF DEBUG }
begin
{$IFDEF DEBUG }
  leadIn := timeMarkU();
{$ENDIF DEBUG }
  result := 0;
  //
  if (not f_destroying and (0 < len)) then begin
    //
    if (unatsRunning <> status) then
      start();
    //
    newHead := f_head;
    inc(newHead);
    if (newHead > high(f_dataArray)) then
      newHead := low(f_dataArray);
    //
    if (newHead <> f_tail) then begin
      //
      with f_dataArray[newHead] do begin
{$IFDEF DEBUG }
	r_leadIn := leadIn;
{$ENDIF DEBUG }
	r_len := len;
	r_provider := provider;
	//
	if (r_dataSize < len) then begin
          //
	  mrealloc(r_data, len);
	  r_dataSize := len;
	end;
	//
	move(data^, r_data^, len);
	f_head := newHead;
	//
	f_dataEvent.setState();
	//
	result := len;
      end;
    end
    else begin
      //
      {$IFDEF LOG_UNAVC_PIPE_ERRORS }
      logMessage(self._classID + '.write() - snake overload');
      {$ENDIF LOG_UNAVC_PIPE_ERRORS }
    end;
  end;
end;


{ unavclInOutPipe }

// --  --
function unavclInOutPipe.addConsumer(consumer: unavclInOutPipe; forceNewFormat: bool): bool;
begin
  // BCB stuff
  result := doAddConsumer(consumer, forceNewFormat);
end;

// --  --
function unavclInOutPipe.addProvider(provider: unavclInOutPipe): bool;
begin
  // BCB stuff
  result := doAddProvider(provider);
end;

// --  --
procedure unavclInOutPipe.AfterConstruction();
begin
  f_lockObj := unaObject.create();
  //
  inherited;
  //
  f_autoActivate := true;
  f_consumers := unaObjectList.create(false, true);
  f_consumers.timeOut := 300;
  f_providers := unaObjectList.create(false, true);
  f_providers.timeOut := 300;
  //
  f_enableDP := true;
  //
  f_dataProxyThread := unaDataProxyThread.create(self);
end;

// --  --
function unavclInOutPipe.applyFormat(data: pointer; len: uint; provider: unavclInOutPipe; restoreActiveState: bool): bool;
var
  allowFC: bool;
begin
  allowFC := true;
  if (assigned(f_beforeFormatChange)) then
    f_beforeFormatChange(self, provider, data, len, allowFC);
  //
  if (allowFC) then begin
    //
    result := applyFormatOnConsumers(data, len, restoreActiveState, provider);
    //
    if (assigned(f_afterFormatChange)) then
      f_afterFormatChange(self, provider, data, len);
  end
  else
    result := false;
end;

// --  --
function unavclInOutPipe.applyFormatOnConsumers(data: pointer; len: uint; restoreActiveState: bool; provider: unavclInOutPipe): bool;
var
  i: int;
begin
  result := true;
  //
  if (isFormatProvider) then begin
    //
    if (lockNonEmptyList_r(f_consumers, true, 1006 {$IFDEF DEBUG }, '.applyFormatOnConsumers()'{$ENDIF DEBUG })) then begin
      try
	//
	i := 0;
	while (i < f_consumers.count) do begin
	  //
	  if (not (csDesigning in ComponentState)) and (0 = (unavclInOutPipe(f_consumers[i]).ignoreProviderOptions and unavcl_ipo_formatProvider)) then
	    result := unavclInOutPipe(f_consumers[i]).applyFormat(data, len, provider, restoreActiveState) and result;
	  //
	  inc(i);
	end;
	//
      finally
	unlockListRO(f_consumers);
      end;
      //
    end
    else
      result := false;
  end;
end;

// --  --
procedure unavclInOutPipe.beforeDestruction();
begin
  inherited;
  //
  close();
  //
  notifyProviders(nil);
  notifyConsumers();
  //
  freeAndNil(f_consumers);
  freeAndNil(f_providers);
  freeAndNil(f_dataProxyThread);
  //
  freeAndNil(f_lockObj);
end;

// --  --
function unavclInOutPipe.checkIfAutoActivate(value: bool; timeout: tTimeout): bool;
var
  i: int;
begin
  if (autoActivate and lockNonEmptyList_r(f_consumers, true, timeout {$IFDEF DEBUG }, '.checkIfAutoActivate(value=' + bool2strStr(value) + ')'{$ENDIF DEBUG })) then begin
    //
    try
      //
      i := 0;
      while (i < f_consumers.count) do begin
	//
	if (0 = (unavclInOutPipe(f_consumers[i]).ignoreProviderOptions and unavcl_ipo_autoActivate)) then
	  unavclInOutPipe(f_consumers[i]).doSetActive(value, timeout, self);
	//
	inc(i);
      end;
      //
    finally
      unlockListRO(f_consumers);
    end;
  end;  
  //
  result := true;
end;

// --  --
function unavclInOutPipe.checkIfFormatProvider(restoreActiveState: bool): bool;
var
  len: uint;
  format: pointer;
  formatCRC: uint;
begin
  result := isFormatProvider;
  //
  if (result and (0 < getConsumerCount())) then begin
    //
    len := getFormatExchangeData(format);
    if (0 < len) then begin
      try
	formatCRC := crc32(format, len);
	if (f_formatCRC <> formatCRC) then begin
	  //
	  f_formatCRC := formatCRC;
	  applyFormatOnConsumers(format, len, restoreActiveState, self);
	end;
	//
      finally
	mrealloc(format);
      end;
    end;
  end;
end;

// --  --
procedure unavclInOutPipe.clearFormatCRC();
begin
  f_formatCRC := 0;
end;

// --  --
procedure unavclInOutPipe.close(timeout: tTimeout; provider: unavclInOutPipe);
begin
  doSetActive(false, choice(0 = timeout, 3000, timeout), provider);
end;

// --  --
function unavclInOutPipe.doAddConsumer(consumer: unavclInOutPipe; forceNewFormat: bool): bool;
var
  newProvider: bool;
begin
  if ((nil <> consumer) and lockList_r(f_consumers, false, 1005 {$IFDEF DEBUG }, '.doAddConsumer()'{$ENDIF DEBUG })) then begin
    //
  {$IFDEF LOG_UNAVC_PIPE_INFOS }
    logMessage(name + ':' + className + '.doAddConsumer(' + consumer.name + ':' + consumer.className + ')');
  {$ENDIF LOG_UNAVC_PIPE_INFOS }
    try
      //
      if (0 > getConsumerIndex(consumer)) then begin
	//
	f_consumers.add(consumer);
	newProvider := true;
      end
      else
	newProvider := false;
      //
      if (0 > consumer.getProviderIndex(self)) then
	consumer.addProvider(self);
      //
      if (forceNewFormat or newProvider) then begin
	//
	if (forceNewFormat) then
	  f_formatCRC := 0;	// ensure format will be applied on all new consumers
	//
	checkIfFormatProvider(active);
        //
        if (newProvider) then
	  checkIfAutoActivate(active);
      end;
      //
      result := true;
    finally
      unlockListWO(f_consumers);
    end;
    //
  end
  else
    result := false;
end;

// --  --
function unavclInOutPipe.doAddProvider(provider: unavclInOutPipe): bool;
begin
  if ((nil <> provider) and lockList_r(f_providers, false, 1007 {$IFDEF DEBUG }, '.doAddProvider()'{$ENDIF DEBUG })) then begin
    //
  {$IFDEF LOG_UNAVC_PIPE_INFOS }
      logMessage(name + ':' + className + '.doAddProvider(' + provider.name + ':' + provider.className + ')');
  {$ENDIF LOG_UNAVC_PIPE_INFOS }
    try
      if (0 > getProviderIndex(provider)) then
	f_providers.add(provider);
      //
      if (0 > provider.getConsumerIndex(self)) then
	provider.addConsumer(self);
      //
      result := true;
    finally
      unlockListWO(f_providers);
    end;
  end
  else
    result := false;
end;

// --  --
procedure unavclInOutPipe.doBeforeAfterFC(doBefore: bool; provider: unavclInOutPipe; data: pointer; len: uint; out allowFC: bool);
begin
  if (doBefore) then begin
    //
    if (assigned(f_beforeFormatChange)) then
      f_beforeFormatChange(self, provider, data, len, allowFC);
  end
  else begin
    //
    if (assigned(f_afterFormatChange)) then
      f_afterFormatChange(self, provider, data, len);
  end;
end;

// --  --
procedure unavclInOutPipe.doClose();
begin
  if (nil <> f_dataProxyThread) then
    f_dataProxyThread.stop();
  //
  {$IFDEF LOG_DUMP_TEXTHEADER }
  if (f_dumpOutputOK) then
    writeToFile(f_dumpOutput, #13#10'--- Log Stopped: ' + sysDate2str() + ' ' + sysTime2str() + ' ---'#13#10);
  if (f_dumpInputOK) then
    writeToFile(f_dumpInput, #13#10'--- Log Stopped: ' + sysDate2str() + ' ' + sysTime2str() + ' ---'#13#10);
  {$ENDIF LOG_DUMP_TEXTHEADER }
  //
  f_closing := true;
end;

// --  --
function unavclInOutPipe.doGetPosition(): int64;
begin
  result := 0;
end;

// --  --
function unavclInOutPipe.doOpen(): bool;
begin
  if (not active) then begin
    //
    // clear statistics
    fillChar(f_inBytes, sizeof(f_inBytes), #0);
    fillChar(f_outBytes, sizeof(f_outBytes), #0);
    //
    f_closing := false;
    //
    f_dumpOutputOK := (0 < length(trimS(dumpOutput)));
    f_dumpInputOK := (0 < length(trimS(dumpInput)));
    //
    {$IFDEF LOG_DUMP_TEXTHEADER }
    if (f_dumpOutputOK) then
      writeToFile(f_dumpOutput, #13#10'--- Log Started: ' + sysDate2str() + ' ' + sysTime2str() + ' ---'#13#10);
    if (f_dumpInputOK) then
      writeToFile(f_dumpInput, #13#10'--- Log Started: ' + sysDate2str() + ' ' + sysTime2str() + ' ---'#13#10);
    {$ENDIF LOG_DUMP_TEXTHEADER }
    //
    f_dumpOutputOK := f_dumpOutputOK and (unaUtils.fileExists(dumpOutput) or (INVALID_HANDLE_VALUE <> unaUtils.fileCreate(dumpOutput, false, false)));
    f_dumpInputOK :=  f_dumpInputOK  and (unaUtils.fileExists(dumpInput)  or (INVALID_HANDLE_VALUE <> unaUtils.fileCreate(dumpOutput, false, false)));
    //
    result := true;
  end
  else
    result := true;
end;

// --  --
procedure unavclInOutPipe.doRemoveConsumer(consumer: unavclInOutPipe);
begin
  if (nil <> consumer) then begin
    //
{$IFDEF LOG_UNAVC_PIPE_INFOS }
    logMessage(name + ':' + className + '.doRemoveConsumer(' + consumer.name + ':' + consumer.className + ')');
{$ENDIF LOG_UNAVC_PIPE_INFOS }
    //
    f_consumers.removeItem(consumer);
    //
    if (0 <= consumer.getProviderIndex(self)) then
      consumer.removeProvider(self);
  end;
end;

// --  --
procedure unavclInOutPipe.doRemoveProvider(provider: unavclInOutPipe);
begin
  if (nil <> provider) then begin
    //
{$IFDEF LOG_UNAVC_PIPE_INFOS }
    logMessage(name + ':' + className + '.doRemoveProvider(' + provider.name + ':' + provider.className + ')');
{$ENDIF LOG_UNAVC_PIPE_INFOS }
    //
    f_providers.removeItem(provider);
    //
    if (0 <= provider.getConsumerIndex(self)) then
      provider.removeConsumer(self);
  end;
end;

// --  --
function unavclInOutPipe.doSetActive(value: bool; timeout: tTimeout; provider: unavclInOutPipe): bool;
var
  notReal: bool;
  activeState: int;
  entryMark: uint64;
  {$IFDEF LOG_UNAVC_PIPE_INFOEX }
  provName: string;
  {$ENDIF LOG_UNAVC_PIPE_INFOEX }
begin
{$IFDEF LOG_UNAVC_PIPE_INFOEX }
  if (nil <> provider) then
    provName := provider.name
  else
    provName := 'nil';
  //
  logMessage(className + '[' + name + '].doSetActive(v=' + bool2strStr(value) + ' /a=' + bool2strStr(active) + ' /to=' + int2str(timeout) + ') by ' + provName);
{$ELSE }
    //
  {$IFDEF LOG_UNAVC_PIPE_INFOS }
    logMessage('  =: ' + className + '[' + name + '].doSetActive(' + bool2strStr(active) + '=>' + bool2strStr(value) + ') :=');
  {$ENDIF LOG_UNAVC_PIPE_INFOS }
    //
{$ENDIF LOG_UNAVC_PIPE_INFOEX }
  //
  notReal := ((csLoading in componentState) or (csDesigning in componentState){ or (csDestroying in componentState)});
  if (notReal) then
    f_shouldActivate := value
  else begin
    //
    activeState := choice(value, +1, -1);
    entryMark := timeMarkU();
    //
    repeat
      //
      if ((0 = InterlockedCompareExchange(f_activateState, activeState, 0))) then begin
	//
	if (enter(true, timeout)) then begin
	  try
	    //
	    if (value) then
	      checkIfFormatProvider(value);
	    //
	    // the line above is moved there, before actually activating the component,
	    // which is especially important for IP components, as they can start
	    // receiving packet _before_ consumers will be able to activate..
	    // 14 Aug 2007 / Lake
	    //
	    if (value) then begin
	      //
	    {$IFDEF LOG_UNAVC_PIPE_INFOEX }
	      logMessage(self.className + '[' + name + ']' + '.doSetActive(true) - about to call checkIfAutoActivate()..');
	    {$ENDIF LOG_UNAVC_PIPE_INFOEX }
	      checkIfAutoActivate(value, timeout);
	    {$IFDEF LOG_UNAVC_PIPE_INFOEX }
	      logMessage(self.className + '[' + name + ']' + '.doSetActive(true) - done.');
	    {$ENDIF LOG_UNAVC_PIPE_INFOEX }
	    end;
	    //
	    // need to call doClose() even if getActive() returns false
	    if (not value or (getActive() <> value)) then begin
	      //
	      try
		//
		if (value) then begin
		{$IFDEF LOG_UNAVC_PIPE_INFOEX }
		  logMessage(self.className + '[' + name + ']' + ': before doOpen()..');
		{$ENDIF LOG_UNAVC_PIPE_INFOEX }
		  //
		  doOpen();
		end
		else begin
		  //
		{$IFDEF LOG_UNAVC_PIPE_INFOEX }
		  logMessage(self.className + '[' + name + ']' + ': before doClose()..');
		{$ENDIF LOG_UNAVC_PIPE_INFOEX }
		  //
		  doClose();
		  //
		  f_closing := false;
		end;
		//
	      {$IFDEF LOG_UNAVC_PIPE_INFOEX }
		logMessage(self.className + '[' + name + ']' + ': done with doOpen()/doClose().');
	      {$ENDIF LOG_UNAVC_PIPE_INFOEX }
	      except
	      end;
	    end;
	    //
	    if (not value) then begin
	      //
	    {$IFDEF LOG_UNAVC_PIPE_INFOEX }
	      logMessage(self.className + '[' + name + ']' + '.doSetActive(false) - about to call checkIfAutoActivate()..');
	    {$ENDIF LOG_UNAVC_PIPE_INFOEX }
	      checkIfAutoActivate(value, timeout);
	    {$IFDEF LOG_UNAVC_PIPE_INFOEX }
	      logMessage(self.className + '[' + name + ']' + '.doSetActive(false) - done.');
	    {$ENDIF LOG_UNAVC_PIPE_INFOEX }
	    end;
	    //
	    break; // exit repeat
	    //
	  finally
	    f_activateState := 0;
	    //
	    leaveRO();
	  end;
	end;
	//
      end
      else
	Sleep(1);
      //
    until ((timeout < tTimeout(timeElapsed32U(entryMark))) or (getActive() = value));
  end;
  //
  try
    result := active;
  finally
  end;
  //
{$IFDEF LOG_UNAVC_PIPE_INFOEX }
  logMessage(className + '[' + name + '].doSetActive() -- EXIT');
{$ENDIF LOG_UNAVC_PIPE_INFOEX }
end;

// --  --
procedure unavclInOutPipe.doSetEnableDP(value: boolean);
begin
  if (enableDataProcessing <> value) then
    f_enableDP := value;
end;

// --  --
function unavclInOutPipe.enter(ro: bool; timeout: tTimeout): bool;
begin
  result := f_lockObj.acquire(ro, timeout, false {$IFDEF DEBUG }, '.enter()' {$ENDIF DEBUG });
end;

// --  --
function unavclInOutPipe.getActive(): boolean;
begin
  if ((csLoading in componentState) or (csDesigning in componentState)) then
    result := f_shouldActivate
  else
    result := isActive();
end;

// --  --
function unavclInOutPipe.getConsumer(index: int): unavclInOutPipe;
begin
  result := f_consumers[index]
end;

// --  --
function unavclInOutPipe.getConsumerCount(): int;
begin
  result := f_consumers.count;
end;

// --  --
function unavclInOutPipe.getConsumerIndex(value: unavclInOutPipe): int;
begin
  result := f_consumers.indexOf(value);
end;

// --  --
function unavclInOutPipe.getConsumerOneAndOnly(): unavclInOutPipe;
begin
  if (0 < f_consumers.count) then
    result := getConsumer()
  else
    result := nil;
end;

// --  --
function unavclInOutPipe.getFormatExchangeData(out data: pointer): uint;
begin
  result := 0;
  data := nil;
end;

// --  --
function unavclInOutPipe.getInBytes(index: int): int64;
begin
  result := f_inBytes[index and 7];
end;

// --  --
function unavclInOutPipe.getOutBytes(index: int): int64;
begin
  result := f_outBytes[index and 7];
end;

// --  --
function unavclInOutPipe.getPosition(): int64;
begin
  // BCB stuff
  result := doGetPosition();
end;

// --  --
function unavclInOutPipe.getProvider(index: int): unavclInOutPipe;
begin
  result := f_providers[index]
end;

// --  --
function unavclInOutPipe.getProviderCount(): int;
begin
  result := f_providers.count;
end;

// --  --
function unavclInOutPipe.getProviderIndex(value: unavclInOutPipe): int;
begin
  result := f_providers.indexOf(value);
end;

// --  --
function unavclInOutPipe.getProviderOneAndOnly(): unavclInOutPipe;
begin
  if (0 < f_providers.count) then
    result := getProvider()
  else
    result := nil;
end;

// --  --
function unavclInOutPipe.incInOutBytes(index: int; isIn: bool; delta: int): int64;
begin
  if (isIn) then begin
    //
    inc(f_inBytes[index and 7], delta);
    result := f_inBytes[index and 7];
  end
  else begin
    //
    inc(f_outBytes[index and 7], delta);
    result := f_outBytes[index and 7];
  end;
end;

// --  --
procedure unavclInOutPipe.leaveRO();
begin
  f_lockObj.releaseRO();
end;

// --  --
procedure unavclInOutPipe.leaveWO();
begin
  f_lockObj.releaseWO();
end;

// --  --
procedure unavclInOutPipe.loaded();
begin
  inherited;
  //
  if (f_shouldActivate) then
    active := true;
end;

// --  --
procedure unavclInOutPipe.notification(component: tComponent; operation: tOperation);
var
  i: int;
begin
  inherited;
  //
  if ((opRemove = operation) and (component is unavclInOutPipe)) then begin
    //
    if (lockNonEmptyList_r(f_providers, false, 100 {$IFDEF DEBUG }, '.notofication(_1_)'{$ENDIF DEBUG })) then
      try
	//
	i := getProviderIndex(component as unavclInOutPipe);
	if (0 <= i) then
	  f_providers.removeByIndex(i);
      finally
	unlockListWO(f_providers);
      end;
    //
    if (lockNonEmptyList_r(f_consumers, false, 100 {$IFDEF DEBUG }, '.notification(_2_)'{$ENDIF DEBUG })) then
      try
	//
	i := getConsumerIndex(component as unavclInOutPipe);
	if (0 <= i) then
	  f_consumers.removeByIndex(i)
      finally
	unlockListWO(f_consumers);
      end;
  end;
end;

// --  --
procedure unavclInOutPipe.notifyConsumers();
var
  i: int;
  consumer: unavclInOutPipe;
  copy: unaList;
begin
  if (lockNonEmptyList_r(f_consumers, false, 300 {$IFDEF DEBUG }, '.notifyConsumers()'{$ENDIF DEBUG })) then
    try
      // need a copy here, because consumers will remove themselfs from f_consumers
      copy := unaList.create();
      try
	copy.assign(f_consumers);
	//
	i := 0;
	while (i < copy.count) do begin
	  //
	  consumer := copy[i];
	  if (nil <> consumer) then
	    consumer.removeProvider(self);
	  //
	  inc(i);
	end;
      finally
	freeAndNil(copy);
      end;
    finally
      unlockListWO(f_consumers);
    end;
end;

// --  --
procedure unavclInOutPipe.notifyProviders(value: unavclInOutPipe);
var
  i: int;
  provider: unavclInOutPipe;
  copy: unaList;
begin
  if (lockNonEmptyList_r(f_providers, false, 300 {$IFDEF DEBUG }, '.notifyProviders()'{$ENDIF DEBUG })) then
    try
      // need a local copy here, because providers may remove themselfs from f_providers
      copy := unaList.create();
      try
	copy.assign(f_providers);
	//
	i := 0;
	while (i < copy.count) do begin
	  //
	  provider := copy[i];
	  if (nil <> provider) then
	    //
	    if (nil = value) then
	      provider.removeConsumer(self)
	    else
	      provider.addConsumer(self);
	  //
	  inc(i);
	end;
      finally
	freeAndNil(copy);
      end;
    finally
      unlockListWO(f_providers);
    end;
end;

// --  --
function unavclInOutPipe.onNewData(data: pointer; len: uint; provider: pointer): bool;
var
  i: int;
begin
  result := (nil <> data) and (0 < len);
  if (result) then begin
    //
    triggerDataDSPEvent(data, len);
    //
    if (lockNonEmptyList_r(f_consumers, true, 50 {$IFDEF DEBUG }, '.onNewData(len=' + int2str(len) + ')'{$ENDIF DEBUG })) then
      try
	i := 0;
	while (i < f_consumers.count) do begin
	  //
	  with (unavclInOutPipe(f_consumers[i])) do begin
	    //
	    if (active) then
	      write(data, len, unavclInOutPipe(provider));
	  end;
	  //
	  inc(i);
	end;
      finally
	unlockListRO(f_consumers);
      end;
    //
    if (f_dumpOutputOK) then begin
      //
    {$IFDEF LOG_DUMP_TEXTHEADER }
      writeToFile(dumpOutput, #13#10'--- New chunk added: ' + sysDate2str() + ' ' + sysTime2str() + ' ---'#13#10);
    {$ENDIF LOG_DUMP_TEXTHEADER }
      writeToFile(dumpOutput, data, len);
    end;
    //
    if (0 < len) then
      incInOutBytes(0, false, len);
    //
    triggerDataAvailEvent(data, len);
  end;
end;

// --  --
function unavclInOutPipe.open(provider: unavclInOutPipe): bool;
begin
  if (nil <> self) then
    doSetActive(true, 3000, provider);
  //
  result := active;
end;

// --  --
function unavclInOutPipe.read(data: pointer; len: uint): uint;
begin
  result := doRead(data, len);
end;

// --  --
function unavclInOutPipe.read(): aString;
var
  len: uint;
begin
  len := availableDataLenIn;
  setLength(result, len);
  //
  if (0 < len) then
    read(@result[1], len);
end;

// --  --
procedure unavclInOutPipe.removeConsumer(consumer: unavclInOutPipe);
begin
  // BCB stuff
  doRemoveConsumer(consumer);
end;

// --  --
procedure unavclInOutPipe.removeProvider(provider: unavclInOutPipe);
begin
  // BCB stuff
  doRemoveProvider(provider);
end;

// --  --
procedure unavclInOutPipe.setActive(value: boolean);
begin
  if (nil <> self) then
    doSetActive(value);
end;

// --  --
procedure unavclInOutPipe.setConsumerOneAndOnly(value: unavclInOutPipe);
begin
  if (lockList_r(f_consumers, false, 1008 {$IFDEF DEBUG }, '.setConsumerOneAndOnly()'{$ENDIF DEBUG })) then
    try
      if (consumer <> value) then begin
	//
	if (nil <> consumer) then
	  // remove current consumer
	  removeConsumer(consumer);
	//
	addConsumer(value)
      end;
      //
    finally
      unlockListWO(f_consumers);
    end;
end;

// --  --
procedure unavclInOutPipe.setEnableDP(value: boolean);
begin
  doSetEnableDP(value);
end;

// --  --
procedure unavclInOutPipe.triggerDataAvailEvent(data: pointer; len: uint);
begin
  if (assigned(f_dataAvail)) then
    f_dataAvail(self, data, len);
end;

// --  --
procedure unavclInOutPipe.triggerDataDSPEvent(data: pointer; len: uint);
begin
  if (assigned(f_dataDSP)) then
    f_dataDSP(self, data, len);
end;

// --  --
function unavclInOutPipe.write(data: pointer; len: uint; provider: unavclInOutPipe): uint;
begin
  if ((nil <> data) and (0 < len)) then begin
    //
    if (enableDataProxy) then
      result := unaDataProxyThread(f_dataProxyThread).write(data, len, provider)
    else begin
      //
      try
	result := doWrite(data, len, provider);
      except
        result := 0;
      end;
      //
      if (f_dumpInputOK) then begin
	//
      {$IFDEF LOG_DUMP_TEXTHEADER }
	writeToFile(dumpInput, #13#10'--- New chunk added: ' + sysDate2str() + ' ' + sysTime2str() + ' ---'#13#10);
      {$ENDIF LOG_DUMP_TEXTHEADER }
	writeToFile(dumpInput, data, len);
      end;
    end;
    //
    if (0 < result) then
      incInOutBytes(0, true, result);
  end
  else
    result := 0;
end;

// --  --
function unavclInOutPipe.write(const data: aString; provider: unavclInOutPipe): uint;
begin
  if (0 < length(data)) then
    result := write(@data[1], length(data), provider)
  else
    result := 0;
end;


{ unavclInOutPipeImpl }

// --  --
function unavclInOutPipeImpl.doRead(data: pointer; len: uint): uint;
begin
  // do nothing
  result := 0;
end;

// --  --
function unavclInOutPipeImpl.doWrite(data: pointer; len: uint; provider: pointer): uint;
begin
  // do nothing
  result := 0;
end;

// --  --
function unavclInOutPipeImpl.getAvailableDataLen(index: integer): uint;
begin
  result := 0;
end;

// --  --
function unavclInOutPipeImpl.isActive(): bool;
begin
  result := false;
end;



initialization
{$IFDEF LOG_UNAVC_PIPE_INFOS }
  logMessage('unaVC_pipe - initialization.');
{$ENDIF LOG_UNAVC_PIPE_INFOS }

finalization
{$IFDEF LOG_UNAVC_PIPE_INFOS }
  logMessage('unaVC_pipe - finalization.');
{$ENDIF LOG_UNAVC_PIPE_INFOS }

end.


