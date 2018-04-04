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

	  unaASIOAPI.pas
	  ASIO API wrapper

	----------------------------------------------
	  (c) 2004-2012 Lake of Soft
	  All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 29 Feb 2004

	  modified by:
		Lake, Feb 2004
		Lake, May 2006
		Lake, May 2008
		Lake, Mar-Apr 2012

	----------------------------------------------
*)

{$I unaDef.inc }

{$IFDEF CPU64 }
{$ELSE }
  {$OPTIMIZATION OFF }	// there seems to be some problems with optiomizaion ON and assembly calls
{$ENDIF CPU64 }

{*
	ASIO API

	version 1.0: first version

	version 1.1: added x64 support

}

unit
  unaASIOAPI;

interface

uses
  Windows, unaTypes, unaClasses;


{$DEFINE ASIO_FLIPINT64 }	// undefine if ASIO driver has native int64 support

// --- asio.h ---

//---------------------------------------------------------------------------------------------------

(*
	Steinberg Audio Stream I/O API
	(c) 1997 - 2005, Steinberg Media Technologies GmbH

	ASIO Interface Specification v 2.1
	2005 - Added support for DSD sample data (in cooperation with Sony)

*)

// force 4 byte alignment
{$Z+ }

//- - - - - - - - - - - - - - - - - - - - - - - - -
// Type definitions
//- - - - - - - - - - - - - - - - - - - - - - - - -

type
  {$EXTERNALSYM long }
  long = int32;

  // number of samples data type is 64 bit integer
  {$EXTERNALSYM ASIOSamples }
  ASIOSamples = int64;

  // Timestamp data type is 64 bit integer,
  // Time format is Nanoseconds.
  {$EXTERNALSYM ASIOTimeStamp }
  ASIOTimeStamp = int64;

  // Samplerates are expressed in IEEE 754 64 bit double float,
  // native format as host computer
  {$EXTERNALSYM ASIOSampleRate }
  pASIOSampleRate = ^ASIOSampleRate;
  ASIOSampleRate = double;

  // Boolean values are expressed as long
  {$EXTERNALSYM ASIOBool }
  ASIOBool = long;

  // Sample Types are expressed as long
  {$EXTERNALSYM ASIOSampleType }
  ASIOSampleType = long;


const
  //
  ASIOFalse 		= 0;
  ASIOTrue         	= 1;

  ASIOSTInt16MSB   	= 0;
  ASIOSTInt24MSB   	= 1;		// used for 20 bits as well
  ASIOSTInt32MSB   	= 2;
  ASIOSTFloat32MSB 	= 3;		// IEEE 754 32 bit float
  ASIOSTFloat64MSB 	= 4;		// IEEE 754 64 bit double float

  // these are used for 32 bit data buffer, with different alignment of the data inside
  // 32 bit PCI bus systems can be more easily used with these
  ASIOSTInt32MSB16 	= 8;		// 32 bit data with 18 bit alignment
  ASIOSTInt32MSB18 	= 9;		// 32 bit data with 18 bit alignment
  ASIOSTInt32MSB20 	= 10;		// 32 bit data with 20 bit alignment
  ASIOSTInt32MSB24 	= 11;		// 32 bit data with 24 bit alignment

  ASIOSTInt16LSB   	= 16;
  ASIOSTInt24LSB   	= 17;		// used for 20 bits as well
  ASIOSTInt32LSB   	= 18;
  ASIOSTFloat32LSB 	= 19;		// IEEE 754 32 bit float, as found on Intel x86 architecture
  ASIOSTFloat64LSB 	= 20; 		// IEEE 754 64 bit double float, as found on Intel x86 architecture

  // these are used for 32 bit data buffer, with different alignment of the data inside
  // 32 bit PCI bus systems can more easily used with these
  ASIOSTInt32LSB16 	= 24;		// 32 bit data with 18 bit alignment
  ASIOSTInt32LSB18 	= 25;		// 32 bit data with 18 bit alignment
  ASIOSTInt32LSB20 	= 26;		// 32 bit data with 20 bit alignment
  ASIOSTInt32LSB24 	= 27;		// 32 bit data with 24 bit alignment

  //	ASIO DSD format.
  ASIOSTDSDInt8LSB1 	= 32;		// DSD 1 bit data, 8 samples per byte. First sample in Least significant bit.
  ASIOSTDSDInt8MSB1 	= 33;		// DSD 1 bit data, 8 samples per byte. First sample in Most significant bit.
  ASIOSTDSDInt8NER8 	= 40;		// DSD 8 bit data, 1 sample per byte. No Endianness required.
  ASIOSTLastEntry   	= ASIOSTDSDInt8NER8 + 1;

  //*-----------------------------------------------------------------------------

  //- - - - - - - - - - - - - - - - - - - - - - - - -
  // Error codes
  //- - - - - - - - - - - - - - - - - - - - - - - - -

type
  //
  {$EXTERNALSYM ASIOError }
  ASIOError = long;

const
  //
  ASE_OK                = 0;                    // This value will be returned whenever the call succeeded
  ASE_SUCCESS           = $3f4847a0;	        // unique success return value for ASIOFuture calls
  ASE_NotPresent        = -1000;                // hardware input or output is not present or available
  ASE_HWMalfunction     = ASE_NotPresent + 1;   // hardware is malfunctioning (can be returned by any ASIO function)
  ASE_InvalidParameter	= ASE_NotPresent + 2;   // input parameter invalid
  ASE_InvalidMode       = ASE_NotPresent + 3;   // hardware is in a bad mode or used in a bad mode
  ASE_SPNotAdvancing    = ASE_NotPresent + 4;   // hardware is not running when sample position is inquired
  ASE_NoClock 	        = ASE_NotPresent + 5;   // sample clock or rate cannot be determined or is not present
  ASE_NoMemory 	        = ASE_NotPresent + 6;   // not enough memory for completing the request

//---------------------------------------------------------------------------------------------------

type
  //- - - - - - - - - - - - - - - - - - - - - - - - -
  // Time Info support
  //- - - - - - - - - - - - - - - - - - - - - - - - -

  // --  --
  {$EXTERNALSYM ASIOTimeCodeFlags }
  ASIOTimeCodeFlags = long;

  // --  --
  {$EXTERNALSYM ASIOTimeCode }
  pASIOTimeCode = ^ASIOTimeCode;
  ASIOTimeCode = packed record
    speed: double;                      // speed relation (fraction of nominal speed)
					// optional; set to 0. or 1. if not supported
    timeCodeSamples: ASIOSamples;       // time in samples
    flags: ASIOTimeCodeFlags;           // some information flags (see below)
    future: array[0..63] of aChar;
  end;

const
  kTcValid              = 1;
  kTcRunning            = 1 shl 1;
  kTcReverse            = 1 shl 2;
  kTcOnspeed            = 1 shl 3;
  kTcStill              = 1 shl 4;
  kTcSpeedValid         = 1 shl 8;


type
  // --  --
  {$EXTERNALSYM AsioTimeInfoFlags }
  AsioTimeInfoFlags = long;

  // --  --
  {$EXTERNALSYM AsioTimeInfo }
  pAsioTimeInfo = ^AsioTimeInfo;
  AsioTimeInfo = packed record
    //
    speed: double;                      // absolute speed (1. = nominal)
    systemTime: ASIOTimeStamp;          // system time related to samplePosition, in nanoseconds
					// on mac, must be derived from Microseconds() (not UpTime()!)
					// on windows, must be derived from timeGetTime()
    samplePosition: ASIOSamples;
    sampleRate: ASIOSampleRate;         // current rate
    flags: AsioTimeInfoFlags;           // (see below)
    reserved: array [0..11] of aChar;
  end;


const
  //
  kSystemTimeValid      = 1;             // must always be valid
  kSamplePositionValid  = 1 shl 1;       // must always be valid
  kSampleRateValid      = 1 shl 2;
  kSpeedValid           = 1 shl 3;

  kSampleRateChanged    = 1 shl 4;
  kClockSourceChanged   = 1 shl 5;


type
  // --  --
  {$EXTERNALSYM ASIOTime }
  pASIOTime = ^ASIOTime;
  ASIOTime = packed record              // both input/output
    reserved: array[0..3] of long;      // must be 0
    timeInfo: AsioTimeInfo;             // required
    timeCode: ASIOTimeCode;             // optional, evaluated if (timeCode.flags & kTcValid)
  end;

  // --  --
  {$EXTERNALSYM ASIOClockSource }
  pASIOClockSource = ^ASIOClockSource;
  ASIOClockSource = packed record
    index: long;			// as used for ASIOSetClockSource()
    associatedChannel: long;		// for instance, S/PDIF or AES/EBU
    associatedGroup: long;		// see channel groups (ASIOGetChannelInfo())
    isCurrentSource: ASIOBool;	        // ASIOTrue if this is the current clock source
    name: array[1..31] of aChar;         // for user selection
  end;

  //
  pASIOClockSources = ^ASIOClockSources;
  ASIOClockSources = array[byte] of ASIOClockSource;


//- - - - - - - - - - - - - - - - - - - - - - - - -
// application's audio stream handler callbacks
//- - - - - - - - - - - - - - - - - - - - - - - - -

  proc_bufferSwitch = procedure(index: long; processNow: ASIOBool); cdecl;
  proc_sampleRateChanged = procedure(sRate: ASIOSampleRate); cdecl;
  proc_asioMessage = function(selector: long; value: long; message: pointer; opt: pDouble): long; cdecl;
  proc_bufferSwitchTimeInfo = function(timeInfo: pASIOTime; index: long; processNow: ASIOBool): pASIOTime; cdecl;

  {$EXTERNALSYM ASIOCallbacks }
  pASIOCallbacks = ^ASIOCallbacks;
  ASIOCallbacks = packed record
    //
    bufferSwitch: proc_bufferSwitch;
    sampleRateChanged: proc_sampleRateChanged;
    asioMessage: proc_asioMessage;
    bufferSwitchTimeInfo: proc_bufferSwitchTimeInfo;
  end;

// asioMessage selectors
const
  //
  kAsioSelectorSupported	= 1;    // selector in <value>, returns 1L if supported,
					// 0 otherwise
  kAsioEngineVersion	        = 2;	// returns engine (host) asio implementation version,
					// 2 or higher
  kAsioResetRequest	        = 3;	// request driver reset. if accepted, this
					// will close the driver (ASIO_Exit() ) and
					// re-open it again (ASIO_Init() etc). some
					// drivers need to reconfigure for instance
					// when the sample rate changes, or some basic
					// changes have been made in ASIO_ControlPanel().
					// returns 1L; note the request is merely passed
					// to the application, there is no way to determine
					// if it gets accepted at this time (but it usually
					// will be).
  kAsioBufferSizeChange         = 4;	// not yet supported, will currently always return 0L.
					// for now, use kAsioResetRequest instead.
					// once implemented, the new buffer size is expected
					// in <value>, and on success returns 1L
  kAsioResyncRequest    	= 5;	// the driver went out of sync, such that
					// the timestamp is no longer valid. this
					// is a request to re-start the engine and
					// slave devices (sequencer). returns 1 for ok,
					// 0 if not supported.
  kAsioLatenciesChanged         = 6; 	// the drivers latencies have changed. The engine
					// will refetch the latencies.
  kAsioSupportsTimeInfo         = 7;	// if host returns true here, it will expect the
					// callback bufferSwitchTimeInfo to be called instead
					// of bufferSwitch
  kAsioSupportsTimeCode         = 8;	// ?
  kAsioMMCCommand               = 9;	// unused - value: number of commands, message points to mmc commands
  kAsioSupportsInputMonitor     = 10;   // kAsioSupportsXXX return 1 if host supports this
  kAsioSupportsInputGain        = 11;   // unused and undefined
  kAsioSupportsInputMeter       = 12;   // unused and undefined
  kAsioSupportsOutputGain       = 13;   // unused and undefined
  kAsioSupportsOutputMeter      = 14;   // unused and undefined
  kAsioOverload                 = 15;   // driver detected an overload
  kAsioNumMessageSelectors      = 16;   // ?

//---------------------------------------------------------------------------------------------------

//- - - - - - - - - - - - - - - - - - - - - - - - -
// (De-)Construction
//- - - - - - - - - - - - - - - - - - - - - - - - -

type
  {$EXTERNALSYM ASIODriverInfo }
  pASIODriverInfo = ^ASIODriverInfo;
  ASIODriverInfo = packed record
    //
    asioVersion: long;		                // currently, 2
    driverVersion: long;		        // driver specific
    name: array[0..31] of aChar;
    errorMessage: array[0..123] of aChar;
    sysRef: pointer;			        // on input: system reference
						// (Windows: application main window handle, Mac & SGI: 0)
  end;

  {$EXTERNALSYM ASIOChannelInfo }
  pASIOChannelInfo = ^ASIOChannelInfo;
  ASIOChannelInfo = packed record
    channel: long;		// on input, channel index
    isInput: ASIOBool;		// on input
    isActive: ASIOBool;		// on exit
    channelGroup: long;		// dto
    _type: ASIOSampleType;	// dto
    name: array[0..31] of aChar; // dto
  end;


  //- - - - - - - - - - - - - - - - - - - - - - - - -
  // Buffer preparation
  //- - - - - - - - - - - - - - - - - - - - - - - - -

  {$EXTERNALSYM ASIOBufferInfo }
  pASIOBufferInfo = ^ASIOBufferInfo;
  ASIOBufferInfo = packed record
    //
    isInput: ASIOBool;			// on input:  ASIOTrue: input, else output
    channelNum: long;			// on input:  channel index
    buffers: array[0..1] of pArray;	// on output: double buffer addresses
  end;


const
  // future selectors
  kAsioEnableTimeCodeRead       = 1; // no arguments
  kAsioDisableTimeCodeRead      = 2; // no arguments
  kAsioSetInputMonitor          = 3; // ASIOInputMonitor* in params
  kAsioTransport                = 4; // ASIOTransportParameters* in params
  kAsioSetInputGain             = 5; // ASIOChannelControls* in params, apply gain
  kAsioGetInputMeter            = 6; // ASIOChannelControls* in params, fill meter
  kAsioSetOutputGain            = 7; // ASIOChannelControls* in params, apply gain
  kAsioGetOutputMeter           = 8; // ASIOChannelControls* in params, fill meter
  kAsioCanInputMonitor          = 9; // no arguments for kAsioCanXXX selectors
  kAsioCanTimeInfo              = 10;
  kAsioCanTimeCode              = 11;
  kAsioCanTransport             = 12;
  kAsioCanInputGain             = 13;
  kAsioCanInputMeter            = 14;
  kAsioCanOutputGain            = 15;
  kAsioCanOutputMeter           = 16;
  //	DSD support
  //	The following extensions are required to allow switching
  //	and control of the DSD subsystem.
  kAsioSetIoFormat		= $23111961;		//* ASIOIoFormat * in params.			*/
  kAsioGetIoFormat		= $23111983;		//* ASIOIoFormat * in params.			*/
  kAsioCanDoIoFormat    	= $23112004;		//* ASIOIoFormat * in params.			*/

type
  // --  --
  {$EXTERNALSYM ASIOInputMonitor }
  pASIOInputMonitor = ^ASIOInputMonitor;
  ASIOInputMonitor = packed record
    input: long;	// this input was set to monitor (or off), -1: all
    output: long;	// suggested output for monitoring the input (if so)
    gain: long;		// suggested gain, ranging 0 - 0x7fffffffL (-inf to +12 dB)
    state: ASIOBool;	// ASIOTrue => on, ASIOFalse => off
    pan: long;		// suggested pan, 0 => all left, 0x7fffffff => right
  end;

  // --  --
  {$EXTERNALSYM ASIOChannelControls }
  pASIOChannelControls = ^ASIOChannelControls;
  ASIOChannelControls = packed record
    channel: long;		// on input, channel index
    isInput: ASIOBool;          // on input
    gain: long;			// on input,  ranges 0 thru 0x7fffffff
    meter: long;		// on return, ranges 0 thru 0x7fffffff
    future: array[0..31] of aChar;
  end;

  // --  --
  {$EXTERNALSYM ASIOTransportParameters }
  pASIOTransportParameters = ^ASIOTransportParameters;
  ASIOTransportParameters = packed record
    command: long;		                // see enum below
    samplePosition: ASIOSamples;
    track: long;
    trackSwitches: array[0..15] of long;        // 512 tracks on/off
    future: array[0..63] of aChar;
  end;

const
  //
  kTransStart           = 1;
  kTransStop            = 2;
  kTransLocate          = 3;	// to samplePosition
  kTransPunchIn         = 4;
  kTransPunchOut        = 5;
  kTransArmOn           = 6;	// track
  kTransArmOff          = 7;	// track
  kTransMonitorOn       = 8;	// track
  kTransMonitorOff      = 9;	// track
  kTransArm             = 10;	// trackSwitches
  kTransMonitor         = 11;	// trackSwitches

type
  ASIOIoFormatType = long;

//enum ASIOIoFormatType_e

const
  kASIOFormatInvalid = -1;
  kASIOPCMFormat     = 0;
  kASIODSDFormat     = 1;

type
  {$EXTERNALSYM ASIOIoFormat_s }
  pASIOIoFormat_s = ^ASIOIoFormat_s;
  ASIOIoFormat_s = packed record
    FormatType:	ASIOIoFormatType;
    future: array[0..512 - sizeof(ASIOIoFormatType) - 1] of aChar;
  end;
  ASIOIoFormat = ASIOIoFormat_s;

// ------ iasiodrv.h -----

{$IFDEF CPU64 }
{$ELSE }
const
  cofs_init			= 12;
  cofs_getDriverName            = cofs_init + 4 * 1;
  cofs_getDriverVersion         = cofs_init + 4 * 2;
  cofs_getErrorMessage          = cofs_init + 4 * 3;
  cofs_start                    = cofs_init + 4 * 4;
  cofs_stop                     = cofs_init + 4 * 5;
  cofs_getChannels              = cofs_init + 4 * 6;
  cofs_getLatencies             = cofs_init + 4 * 7;
  cofs_getBufferSize            = cofs_init + 4 * 8;
  cofs_canSampleRate            = cofs_init + 4 * 9;
  cofs_getSampleRate            = cofs_init + 4 * 10;
  cofs_setSampleRate            = cofs_init + 4 * 11;
  cofs_getClockSources          = cofs_init + 4 * 12;
  cofs_setClockSource           = cofs_init + 4 * 13;
  cofs_getSamplePosition	= cofs_init + 4 * 14;
  cofs_getChannelInfo           = cofs_init + 4 * 15;
  cofs_createBuffers            = cofs_init + 4 * 16;
  cofs_disposeBuffers           = cofs_init + 4 * 17;
  cofs_controlPanel             = cofs_init + 4 * 18;
  cofs_future                   = cofs_init + 4 * 19;
  cofs_outputReady              = cofs_init + 4 * 20;
{$ENDIF CPU64 }

type
  // --  --
  {*
	ASIO COM Interface
  }
  {$EXTERNALSYM IASIO }
  IASIO = interface
    //
    function init(sysHandle: pointer): ASIOBool;
    procedure getDriverName(name: paChar);
    function getDriverVersion(): long;
    procedure getErrorMessage(str: paChar);
    //
    function start(): ASIOError;
    function stop(): ASIOError;
    //
    function getChannels(out numInputChannels: long; out numOutputChannels: long): ASIOError;
    function getLatencies(out inputLatency: long; out outputLatency: long): ASIOError;
    function getBufferSize(out minSize: long; out maxSize: long; out preferredSize: long; out granularity: long): ASIOError;
    //
    function canSampleRate(sampleRate: ASIOSampleRate): ASIOError;
    function getSampleRate(out sampleRate: ASIOSampleRate): ASIOError;
    function setSampleRate(sampleRate: ASIOSampleRate): ASIOError;
    //
    function getClockSources(clocks: pASIOClockSources; var numSources: long): ASIOError;
    function setClockSource(reference: long): ASIOError;
    //
    function getSamplePosition(out sPos: ASIOSamples; out tStamp: ASIOTimeStamp): ASIOError;
    function getChannelInfo(out info: ASIOChannelInfo): ASIOError;
    //
    function createBuffers(bufferInfos: pASIOBufferInfo; numChannels: long; bufferSize: long; callbacks: pASIOCallbacks): ASIOError;
    function disposeBuffers(): ASIOError;
    //
    function controlPanel(): ASIOError;
    //
    function future(selector: long; opt: pointer): ASIOError;
    function outputReady(): ASIOError;
  end;

// ------ asiodrv.h -----


(*
	Steinberg Audio Stream I/O API
	(c) 1996, Steinberg Soft- und Hardware GmbH
	charlie (May 1996)

	asiodrvr.h
	c++ superclass to implement asio functionality. from this,
	you can derive whatever required
*)

const
  // number of input and outputs supported by the host application
  // you can change these to higher or lower values
  kMaxInputChannels = 256;
  kMaxOutputChannels = 256;


type
  // callback events prototypes
  //
  bufferSwitchEvent = procedure(sender: tObject; index: long; processNow: bool) of object;
  sampleRateChangedEvent = procedure(sender: tObject; rate: ASIOSampleRate) of object;
  asioMessageEvent = procedure(sender: tObject; selector: long; value: long; message: pointer; opt: pDouble; out result: long) of object;
  bufferSwitchTimeInfoEvent = procedure(sender: tObject; timeInfo: pASIOTime; index: long; processNow: bool; time: pASIOTime) of object;


  // forward declaration
  unaAsioDriver = class;

  //
  // -- unaAsioBufferProcessor --
  //
  unaAsioBufferProcessor = class(unaObject)
  private
    f_drv: unaAsioDriver;
  protected
    function doBufferSwitch(index: long; processNow: bool): bool; virtual;
    function doBufferSwitchTimeInfo(timeInfo: pASIOTime; index: long; processNow: bool; res: pASIOTime): bool; virtual;
    function doSampleRateChanged(sRate: ASIOSampleRate): bool; virtual;
    function doAsioMessage(selector: long; value: long; message: pointer; opt: pDouble; out res: long): bool; virtual;
  public
    constructor create(driver: unaAsioDriver);
    procedure BeforeDestruction(); override;
    //
    property drv: unaAsioDriver read f_drv;
  end;

  //
  unaASIOSampleOp = (soAdd, soSub, soReplace);

  //
  unaASIODriverState = (dsLoaded, dsInitialized, dsPrepared, dsRunning);

  //
  // -- unaAsioDriver --
  //
  unaAsioDriver = class(unaObject)
  private
    f_asio: iASIO;
    f_handle: long;			// on input: system reference
    f_driverInfo: ASIODriverInfo;
    f_driverState: unaASIODriverState;
    //
    f_callbacks: ASIOCallbacks;
    f_di: int;
    f_bp: unaAsioBufferProcessor;
    //
    f_maxBufSize: long;
    f_minBufSize: long;
    f_actualBufSize: long;
    f_preferredBufSize: long;
    f_outputChannels: long;
    f_inputChannels: long;
    f_postOutput: bool;
    f_outputLatency: long;
    f_inputLatency: long;
    f_granularity: long;
    //
    f_looksLike24: bool;
    //
    f_shouldReset: bool;	// if True, driver must be reset ASAP
    //
    f_bufferInfo : array[0.. kMaxInputChannels + kMaxOutputChannels - 1] of ASIOBufferInfo; // buffer info's
    f_channelInfo: array[0.. kMaxInputChannels + kMaxOutputChannels - 1] of ASIOChannelInfo;
    //
    f_onBS: bufferSwitchEvent;
    f_onSRC: sampleRateChangedEvent;
    f_onBSTI: bufferSwitchTimeInfoEvent;
    f_onAM: asioMessageEvent; // channel info's
    //
    function getDriverInfo(): pASIODriverInfo;
    function getBufferInfoByIndex(index: int): pASIOBufferInfo;
    function getChannelInfoByIndex(index: int): pASIOChannelInfo;
    function getChannelInfo(out info: ASIOChannelInfo): ASIOError;
    function getSampleRate(): ASIOSampleRate;
    //
    function internalCreateBuffers(bufSize: int = -1): ASIOError;
    function internalGetStaticInfo(): ASIOError;
    //
    procedure setBufferProcessor(bp: unaAsioBufferProcessor);
  protected
    procedure doBufferSwitch(index: long; processNow: bool); virtual;
    function  doBufferSwitchTimeInfo(timeInfo: pASIOTime; index: long; processNow: bool): pASIOTime; virtual;
    procedure doSampleRateChanged(rate: ASIOSampleRate); virtual;
    function  doAsioMessage(selector: long; value: long; message: pointer; opt: pDouble): long; virtual;
    //
    // ASIO interface
    function getBufferSize(out minSize, maxSize, preferredSize, granularity: long): ASIOError;
    function getChannels(out numInputChannels: long; out numOutputChannels: long): ASIOError;
    function getLatencies(out inputLatency: long; out outputLatency: long): ASIOError;
    function createBuffers(bufferInfos: pASIOBufferInfo; numChannels: long; bufferSize: long; callbacks: pASIOCallbacks): ASIOError;
    function disposeBuffers(): ASIOError;
    //
    function getDriverName(hardCall: bool = false): aString;
    function getDriverVersion(hardCall: bool = false): long;
  public
    constructor create(asio: iASIO);
    destructor Destroy(); override;
    //
    function init(sysref: long = 0; createBuffers: bool = true; bufSize: int = -1): ASIOError;
    function release(): bool;
    //
    function start(createBuffers: bool = false; bufSize: int = -1): ASIOError;
    function stop(releaseBuffers: bool = false): ASIOError;
    //
    function canSampleRate(sampleRate: ASIOSampleRate): bool;
    function setSampleRate(const sampleRate: ASIOSampleRate): ASIOError;
    //
    function getClockSources(clocks: pASIOClockSources; var numSources: long): ASIOError;
    function setClockSource(reference: long): ASIOError;
    //
    function setSample(channelIndex,  bufIndex, sampleIndex, value: int32; op: unaASIOSampleOp = soAdd): ASIOError; overload;
    function setSample(channelIndex,  bufIndex, sampleIndex: int; value: double; op: unaASIOSampleOp = soAdd): ASIOError; overload;
    function setSamples(channelIndex, bufIndex, startSampleIndex, samplesCount: int; value: pInt32; op: unaASIOSampleOp = soAdd): ASIOError; overload;
    function setSamples(channelIndex, bufIndex, startSampleIndex, samplesCount: int; values: pDouble; op: unaASIOSampleOp = soAdd): ASIOError; overload;
    //
    {*
	Returns input samples as 16-bit values.
	NOTE: outBuffer must be large enough to hold all samples

	@param channelIndex index of input channel (from 0 to inputChannels - 1), or -1 to return all channels
	@param bufIndex index of buffer to read data from (usually passed via callback)
	@param outBuffer array of int16 values to be filled with samples
	@param startSampleIndex first sample to copy
	@param samplesCount number of samples to copy, or -1 to copy the whole buffer
	@return ASE_OK or error code
    }
    function getSamples(channelIndex, bufIndex: int; outBuffer: pInt16Array; startSampleIndex: int = 0; samplesCount: int = -1): ASIOError;
    {*
	Sets output samples as 16-bit values.
	NOTE: inBuffer must be large enough to hold all samples

	@param channelIndex index of input channel (from 0 to outputChannels - 1), or -1 to set all channels
	@param bufIndex index of buffer to set data at (usually passed via callback)
	@param inBuffer array of int16 values to assigted to samples
	@param startSampleIndex first sample to set
	@param samplesCount number of samples to set, or -1 to set the whole buffer
	@return ASE_OK or error code
    }
    function setSamples(channelIndex, bufIndex: int; inBuffer: pInt16Array; startSampleIndex: int = 0; samplesCount: int = -1): ASIOError; overload;
    {*
    }
    function getSamplePosition(out sPos: ASIOSamples; out tStamp: ASIOTimeStamp): ASIOError;
    //
    {*
    }
    function controlPanel(): ASIOError;
    {*
    }
    function future(selector: long; opt: pointer = nil): ASIOError;
    {*
    }
    function outputReady(): ASIOError;
    {*
    }
    function getDriverError(hardCall: bool = true): aString;
    // --------------------
    {*
    }
    property driverInfo: pASIODriverInfo read getDriverInfo;
    {*
    }
    property driverState: unaASIODriverState read f_driverState;
    {*
    }
    property postOutput: bool read f_postOutput;
    //
    {*
	Number of input channels
    }
    property inputChannels: long read f_inputChannels;
    {*
	Number of output channels
    }
    property outputChannels: long read f_outputChannels;
    //
    {*
	Minimum buffer size (samples)
    }
    property bufMinSize: long read f_minBufSize;
    {*
	Maximum buffer size (samples)
    }
    property bufMaxSize: long read f_maxBufSize;
    {*
	Preferred buffer size (samples)
    }
    property bufPreferredSize: long read f_preferredBufSize;
    {*
	Granularity (samples)
    }
    property bufGranularity: long read f_granularity;
    {*
	Actually allocated buffers size (samples)
    }
    property bufActualSize: long read f_actualBufSize;
    {*
	Input latency (samples)
    }
    property inputLatency: long read f_inputLatency;
    {*
	Output latency (samples)
    }
    property outputLatency: long read f_outputLatency;
    //
    {*
	Returns number of bytes in buffer allocated for channel

	@param chIndex index of channel
    }
    function getBufferSizeInBytes(chIndex: int): int;
    {*
	Current sampling rate (samples/second)
    }
    property sampleRate: ASIOSampleRate read getSampleRate;
    //
    {*
	Buffer information

	bufferInfo and channelInfo share the same indexing, as the data in them are linked together
	max index is inputChannels + outputChannels - 1, input channels go first
    }
    property bufferInfo[index: int]: pASIOBufferInfo read getBufferInfoByIndex;
    {*
	Channel information

	bufferInfo and channelInfo share the same indexing, as the data in them are linked together
	max index is inputChannels + outputChannels - 1, input buffers go first
    }
    property channelInfo[index: int]: pASIOChannelInfo read getChannelInfoByIndex;
    {*
	Buffer switch event
    }
    property bufferProcessor: unaAsioBufferProcessor read f_bp write setBufferProcessor;
    //
    // -- Event -------------
    //
    {*
	Buffer switch event
    }
    property onBufferSwitch: bufferSwitchEvent read f_onBS;
    {*
	SR change event
    }
    property onSampleRateChanged: sampleRateChangedEvent read f_onSRC;
    {*
	ASIO Message event
    }
    property onAsioMessage: asioMessageEvent read f_onAM;
    {*
	Buffer switch event
    }
    property onBufferSwitchTimeInfo: bufferSwitchTimeInfoEvent read f_onBSTI;
  end;


// ----------- asiolist.h -------------

const
  //
  DRVERR			= -5000;
  DRVERR_INVALID_PARAM		= DRVERR - 1;
  DRVERR_DEVICE_ALREADY_OPEN	= DRVERR - 2;
  DRVERR_DEVICE_NOT_FOUND	= DRVERR - 3;

  MAXPATHLEN			= 512;
  MAXDRVNAMELEN	            	= 128;

type
  //
  CLSID = TGUID;
  TIID  = TGUID;

  //
  {$EXTERNALSYM ASIODRVSTRUCT }
  pASIODRVSTRUCT = ^ASIODRVSTRUCT;
  ASIODRVSTRUCT = packed record
    //
    drvID: int32;
    clsid: CLSID;
    dllpath: array[0..MAXPATHLEN - 1] of aChar;
    drvname: array[0..MAXDRVNAMELEN - 1] of aChar;
    asiodrv: unaAsioDriver;
    next: pASIODRVSTRUCT;
  end;

  //
  // -- unaAsioDriverList --
  //
  unaAsioDriverList = class(unaObject)
  private
    f_numdrv: int;
    f_lpdrvlist: pASIODRVSTRUCT;
    //
    function getDrvStruct(drvID: int): pASIODRVSTRUCT;
  public
    procedure AfterConstruction(); override;
    procedure BeforeDestruction(); override;
    //
    function asioOpenDriver(drvID: int; out asiodrv: unaAsioDriver): HRESULT;
    function asioCloseDriver(drvID: int): HRESULT;
    //
    // nice to have
    function asioGetNumDev(): int;
    function asioGetDrvID(index: int): int;
    function asioGetDriverName(drvID: int): aString;
    function asioGetDriverPath(drvID: int): aString;
    function asioGetDriverCLSID(drvID: int; out clsid: CLSID): HRESULT;
    //
    // or use directly access
    property lpdrvlist: pASIODRVSTRUCT read f_lpdrvlist;
    property numDrv: int read f_numdrv;
  end;


{$EXTERNALSYM timeGetTime }
function timeGetTime(): DWORD; stdcall;

// --  --
function asioChannelType2str(_type: int): string;


const
  // flags passed as the coInit parameter to CoInitializeEx.
  {$EXTERNALSYM COINIT_MULTITHREADED}
  COINIT_MULTITHREADED      = 0;      // OLE calls objects on any thread.
  {$EXTERNALSYM COINIT_APARTMENTTHREADED}
  COINIT_APARTMENTTHREADED  = 2;      // Apartment model
  {$EXTERNALSYM COINIT_DISABLE_OLE1DDE}
  COINIT_DISABLE_OLE1DDE    = 4;      // Dont use DDE for Ole1 support.
  {$EXTERNALSYM COINIT_SPEED_OVER_MEMORY}
  COINIT_SPEED_OVER_MEMORY  = 8;      // Trade memory for speed.


  {$EXTERNALSYM CLSCTX_INPROC_SERVER}
  CLSCTX_INPROC_SERVER     = 1;
  {$EXTERNALSYM CLSCTX_INPROC_HANDLER}
  CLSCTX_INPROC_HANDLER    = 2;
  {$EXTERNALSYM CLSCTX_LOCAL_SERVER}
  CLSCTX_LOCAL_SERVER      = 4;
  {$EXTERNALSYM CLSCTX_INPROC_SERVER16}
  CLSCTX_INPROC_SERVER16   = 8;
  {$EXTERNALSYM CLSCTX_REMOTE_SERVER}
  CLSCTX_REMOTE_SERVER     = $10;
  {$EXTERNALSYM CLSCTX_INPROC_HANDLER16}
  CLSCTX_INPROC_HANDLER16  = $20;
  {$EXTERNALSYM CLSCTX_INPROC_SERVERX86}
  CLSCTX_INPROC_SERVERX86  = $40;
  {$EXTERNALSYM CLSCTX_INPROC_HANDLERX86}
  CLSCTX_INPROC_HANDLERX86 = $80;

  
// -- externals --

{$EXTERNALSYM CLSIDFromString }
function CLSIDFromString(psz: pwChar; out clsid: TGUID): HResult; stdcall; external 'ole32.dll' name 'CLSIDFromString';

{$EXTERNALSYM CoInitialize }
function CoInitialize(res: pointer): HResult; stdcall; external 'ole32.dll' name 'CoInitialize';

{$EXTERNALSYM CoInitializeEx }
function CoInitializeEx(pvReserved: Pointer; coInit: Longint): HResult; stdcall; external 'ole32.dll' name 'CoInitializeEx';

{$EXTERNALSYM CoUninitialize }
procedure CoUninitialize(); stdcall; external 'ole32.dll' name 'CoUninitialize';

{$EXTERNALSYM CoCreateInstance}
function CoCreateInstance(const clsid: CLSID; unkOuter: IUnknown; dwClsContext: Longint; const iid: TIID; out pv): HResult; stdcall; external 'ole32.dll' name 'CoCreateInstance';



implementation


uses
  unaUtils;

const
  // hidden
  ASIODRV_DESC   = 'description';
  INPROC_SERVER	 = 'InprocServer32';
  ASIO_PATH	 = 'software\asio';
  COM_CLSID	 = 'clsid';

// -- asiolist.cpp --

// ******************************************************************
// Local Functions
// ******************************************************************
function findDrvPath(const clsidstr: aString; out dllpath: string): HRESULT;
var
  hkPath: HKEY;
  dataType: DWORD;
  databuf: array[0..MAX_PATH] of aChar;
  dataSize: DWORD;
begin
  result := HRESULT(-1);
  if (ERROR_SUCCESS = RegOpenKeyA(HKEY_CLASSES_ROOT, paChar(COM_CLSID + '\' + clsidstr + '\' + INPROC_SERVER), hkPath)) then begin
    //
    dataType := REG_SZ;
    dataSize := sizeOf(databuf);
    result := RegQueryValueExA(hkPath, nil, nil, @datatype, pByte(@databuf), @dataSize);
    if (ERROR_SUCCESS = result) then
      dllpath := string(databuf);
    //
    RegCloseKey(hkPath);
  end;
end;

// --  --
function newDrvStruct(key: HKEY; const keyname: aString; drvID: int; lpdrv: pASIODRVSTRUCT): pASIODRVSTRUCT;
var
  hksub: HKEY;
  databuf: array[0..255] of aChar;
  dllpath: string;
  wData: array[0..100] of WORD;
  _clsid: CLSID;
  datatype: DWORD;
  datasize: DWORD;
  cr: LONG;
begin
  if (nil = lpdrv) then begin
    //
    if (ERROR_SUCCESS = RegOpenKeyExA(key, paChar(keyname), 0, KEY_READ, hksub)) then begin
      //
      datatype := REG_SZ;
      datasize := 256;
      if (ERROR_SUCCESS = RegQueryValueExA(hksub, COM_CLSID, nil, @datatype, pByte(@databuf), @datasize)) then begin
	//
	if (ERROR_SUCCESS = findDrvPath(databuf, dllpath)) then begin
	  //
	  lpdrv := malloc(sizeOf(ASIODRVSTRUCT), true, 0);
	  if (nil <> lpdrv) then begin
	    //
	    lpdrv.drvID := drvID;
            //
            str2arrayA(aString(dllpath), lpdrv.dllpath);
	    //
	    MultiByteToWideChar(CP_ACP, 0, databuf, -1, pwChar(@wData), 100);
	    cr := CLSIDFromString(pwChar(@wData), _clsid);
	    if (S_OK = cr)  then
	      move(_clsid, lpdrv.clsid, sizeOf(_clsid));
	    //
	    datatype := REG_SZ;
	    datasize := 256;
	    if (ERROR_SUCCESS = RegQueryValueExA(hksub, ASIODRV_DESC, nil, @datatype, pByte(@databuf), @datasize)) then
	      move(databuf, lpdrv.drvname, min(datasize, sizeOf(lpdrv.drvname)))
	    else
	      move(keyname[1], lpdrv.drvname, min(length(keyname), int(sizeOf(lpdrv.drvname))));
	    //
	  end;
	end;
      end;
      //
      RegCloseKey(hksub);
    end;
  end
  else
    lpdrv.next := newDrvStruct(key, keyname, drvID + 1, lpdrv.next);
  //
  result := lpdrv;
end;

// --  --
procedure deleteDrvStruct(lpdrv: pASIODRVSTRUCT);
begin
  if (nil <> lpdrv) then begin
    //
    deleteDrvStruct(lpdrv.next);
    //
    if (nil <> lpdrv.asiodrv) then
      freeAndNil(lpdrv.asiodrv);
    //
    mrealloc(lpdrv);
  end;
end;

// --  --
function asioChannelType2str(_type: int): string;
begin
  case (_type) of

    ASIOSTInt16MSB: result := 'MSB: 16 bit data word';
    ASIOSTInt24MSB: result := 'MSB: packed 18/20/24 bit format. 2 data words will spawn consecutive 6 bytes in memory';
    ASIOSTInt32MSB: result := 'MSB: 24/32 bit data';
    ASIOSTFloat32MSB: result := 'MSB: IEEE 754 32 bit float';
    ASIOSTFloat64MSB: result := 'MSB: IEEE 754 64 bit double float';
    //
    ASIOSTInt32MSB16: result := 'MSB: 16 bits, the other bits are sign extended to 32 bits';
    ASIOSTInt32MSB18: result := 'MSB: 18 bits, the other bits are sign extended to 32 bits';
    ASIOSTInt32MSB20: result := 'MSB: 20 bits, the other bits are sign extended to 32 bits';
    ASIOSTInt32MSB24: result := 'MSB: 24 bits, the other bits are sign extended to 32 bits';
    //
    ASIOSTInt16LSB: result := 'LSB: 16 bit data word';
    ASIOSTInt24LSB: result := 'LSB: packed 18/20/24 bit format. 2 data words will spawn consecutive 6 bytes in memory';
    ASIOSTInt32LSB: result := 'LSB: 24/32 bit data';
    ASIOSTFloat32LSB: result := 'LSB: IEEE 754 32 bit float';
    ASIOSTFloat64LSB: result := 'LSB: IEEE 754 64 bit double float';
    //
    ASIOSTInt32LSB16: result := 'LSB: 32 bit data with 16 bit sample data right aligned';
    ASIOSTInt32LSB18: result := 'LSB: 32 bit data with 18 bit sample data right aligned';
    ASIOSTInt32LSB20: result := 'LSB: 32 bit data with 20 bit sample data right aligned';
    ASIOSTInt32LSB24: result := 'LSB: 32 bit data with 24 bit sample data right aligned';
    //
    ASIOSTDSDInt8LSB1: result := 'DSD 1 bit data, 8 samples per byte. First sample in Least significant bit';
    ASIOSTDSDInt8MSB1: result := 'DSD 1 bit data, 8 samples per byte. First sample in Most significant bit';
    ASIOSTDSDInt8NER8: result := 'DSD 8 bit data, 1 sample per byte. No Endianness required';
    //
    else
      result := 'Unknown type: ' + int2str(_type);

  end;
end;


// ******************************************************************

const
  c_max_drivers	= 16;

var
  g_driver: array[0..c_max_drivers - 1] of unaAsioDriver;	// array of drivers
  g_callbacks: array[0..c_max_drivers - 1] of ASIOCallbacks;
  g_lock: unaAcquireType;


{*
	@return first available driver index, or -1 if no more space for drivers is available
}
function getGDriverIndex(driver: unaAsioDriver): int;
var
  i: int32;
begin
  result := -1;
  //
  if (acquire32(g_lock, 200)) then try
    //
    for i := 0 to c_max_drivers - 1 do begin
      //
      if (nil = g_driver[i]) then begin
	//
	g_driver[i] := driver;
	//
	result := i;
	break;
      end;
    end;
    //
  finally
    release32(g_lock);
  end;
end;


// -- AsioDriver callbacks --

// -- hostsample.cpp --

// --  --
procedure sampleRateChanged(i: int; rate: ASIOSampleRate);
begin
  // do whatever you need to do if the sample rate changed
  // usually this only happens during external sync.
  // Audio processing is not stopped by the driver, actual sample rate
  // might not have even changed, maybe only the sample rate status of an
  // AES/EBU or S/PDIF digital input at the audio device.
  // You might have to update time/sample related conversion routines, etc.
  //
  if (nil <> g_driver[i])  then
    g_driver[i].doSampleRateChanged(rate);
end;

// --  --
function asioMessage(i: int; selector: long; value: long; message: pointer; opt: pDouble): long;
begin
  {$IFDEF DEBUG }
  logMessage('CB: asioMessage() - selector=' + int2str(selector) + ', value=' + int2str(value));
  {$ENDIF DEBUG }
  //
  if (nil <> g_driver[i]) then
    result := g_driver[i].doAsioMessage(selector, value, message, opt)
  else
    result := 0;
end;

// --  --
function timeGetTime; external 'winmm.dll' name 'timeGetTime';

// --  --
function bufferSwitchTimeInfo(i: int; timeInfo: pASIOTime; index: long; processNow: ASIOBool): pASIOTime;
begin
  if (nil <> g_driver[i]) then
    result := g_driver[i].doBufferSwitchTimeInfo(timeInfo, index, bool(processNow))
  else
    result := nil;
end;

// --  --
procedure bufferSwitch(i: int; index: long; processNow: ASIOBool);
begin
  if (nil <> g_driver[i]) then
    g_driver[i].doBufferSwitch(index, bool(processNow));
end;


// --
// -- start of ugly code (thanks to ASIO callback "design") --
// --
procedure sampleRateChanged_00(rate: ASIOSampleRate); cdecl; begin sampleRateChanged(00, rate); end;
procedure sampleRateChanged_01(rate: ASIOSampleRate); cdecl; begin sampleRateChanged(01, rate); end;
procedure sampleRateChanged_02(rate: ASIOSampleRate); cdecl; begin sampleRateChanged(02, rate); end;
procedure sampleRateChanged_03(rate: ASIOSampleRate); cdecl; begin sampleRateChanged(03, rate); end;
procedure sampleRateChanged_04(rate: ASIOSampleRate); cdecl; begin sampleRateChanged(04, rate); end;
procedure sampleRateChanged_05(rate: ASIOSampleRate); cdecl; begin sampleRateChanged(05, rate); end;
procedure sampleRateChanged_06(rate: ASIOSampleRate); cdecl; begin sampleRateChanged(06, rate); end;
procedure sampleRateChanged_07(rate: ASIOSampleRate); cdecl; begin sampleRateChanged(07, rate); end;
procedure sampleRateChanged_08(rate: ASIOSampleRate); cdecl; begin sampleRateChanged(08, rate); end;
procedure sampleRateChanged_09(rate: ASIOSampleRate); cdecl; begin sampleRateChanged(09, rate); end;
procedure sampleRateChanged_10(rate: ASIOSampleRate); cdecl; begin sampleRateChanged(10, rate); end;
procedure sampleRateChanged_11(rate: ASIOSampleRate); cdecl; begin sampleRateChanged(11, rate); end;
procedure sampleRateChanged_12(rate: ASIOSampleRate); cdecl; begin sampleRateChanged(12, rate); end;
procedure sampleRateChanged_13(rate: ASIOSampleRate); cdecl; begin sampleRateChanged(13, rate); end;
procedure sampleRateChanged_14(rate: ASIOSampleRate); cdecl; begin sampleRateChanged(14, rate); end;
procedure sampleRateChanged_15(rate: ASIOSampleRate); cdecl; begin sampleRateChanged(15, rate); end;

// --  --
function asioMessage_00(selector: long; value: long; message: pointer; opt: pDouble): long; cdecl; begin result := asioMessage(00, selector, value, message, opt); end;
function asioMessage_01(selector: long; value: long; message: pointer; opt: pDouble): long; cdecl; begin result := asioMessage(01, selector, value, message, opt); end;
function asioMessage_02(selector: long; value: long; message: pointer; opt: pDouble): long; cdecl; begin result := asioMessage(02, selector, value, message, opt); end;
function asioMessage_03(selector: long; value: long; message: pointer; opt: pDouble): long; cdecl; begin result := asioMessage(03, selector, value, message, opt); end;
function asioMessage_04(selector: long; value: long; message: pointer; opt: pDouble): long; cdecl; begin result := asioMessage(04, selector, value, message, opt); end;
function asioMessage_05(selector: long; value: long; message: pointer; opt: pDouble): long; cdecl; begin result := asioMessage(05, selector, value, message, opt); end;
function asioMessage_06(selector: long; value: long; message: pointer; opt: pDouble): long; cdecl; begin result := asioMessage(06, selector, value, message, opt); end;
function asioMessage_07(selector: long; value: long; message: pointer; opt: pDouble): long; cdecl; begin result := asioMessage(07, selector, value, message, opt); end;
function asioMessage_08(selector: long; value: long; message: pointer; opt: pDouble): long; cdecl; begin result := asioMessage(08, selector, value, message, opt); end;
function asioMessage_09(selector: long; value: long; message: pointer; opt: pDouble): long; cdecl; begin result := asioMessage(09, selector, value, message, opt); end;
function asioMessage_10(selector: long; value: long; message: pointer; opt: pDouble): long; cdecl; begin result := asioMessage(10, selector, value, message, opt); end;
function asioMessage_11(selector: long; value: long; message: pointer; opt: pDouble): long; cdecl; begin result := asioMessage(11, selector, value, message, opt); end;
function asioMessage_12(selector: long; value: long; message: pointer; opt: pDouble): long; cdecl; begin result := asioMessage(12, selector, value, message, opt); end;
function asioMessage_13(selector: long; value: long; message: pointer; opt: pDouble): long; cdecl; begin result := asioMessage(13, selector, value, message, opt); end;
function asioMessage_14(selector: long; value: long; message: pointer; opt: pDouble): long; cdecl; begin result := asioMessage(14, selector, value, message, opt); end;
function asioMessage_15(selector: long; value: long; message: pointer; opt: pDouble): long; cdecl; begin result := asioMessage(15, selector, value, message, opt); end;

// --  --
function bufferSwitchTimeInfo_00(timeInfo: pASIOTime; index: long; processNow: ASIOBool): pASIOTime; cdecl; begin result := bufferSwitchTimeInfo(00, timeInfo, index, processNow); end;
function bufferSwitchTimeInfo_01(timeInfo: pASIOTime; index: long; processNow: ASIOBool): pASIOTime; cdecl; begin result := bufferSwitchTimeInfo(01, timeInfo, index, processNow); end;
function bufferSwitchTimeInfo_02(timeInfo: pASIOTime; index: long; processNow: ASIOBool): pASIOTime; cdecl; begin result := bufferSwitchTimeInfo(02, timeInfo, index, processNow); end;
function bufferSwitchTimeInfo_03(timeInfo: pASIOTime; index: long; processNow: ASIOBool): pASIOTime; cdecl; begin result := bufferSwitchTimeInfo(03, timeInfo, index, processNow); end;
function bufferSwitchTimeInfo_04(timeInfo: pASIOTime; index: long; processNow: ASIOBool): pASIOTime; cdecl; begin result := bufferSwitchTimeInfo(04, timeInfo, index, processNow); end;
function bufferSwitchTimeInfo_05(timeInfo: pASIOTime; index: long; processNow: ASIOBool): pASIOTime; cdecl; begin result := bufferSwitchTimeInfo(05, timeInfo, index, processNow); end;
function bufferSwitchTimeInfo_06(timeInfo: pASIOTime; index: long; processNow: ASIOBool): pASIOTime; cdecl; begin result := bufferSwitchTimeInfo(06, timeInfo, index, processNow); end;
function bufferSwitchTimeInfo_07(timeInfo: pASIOTime; index: long; processNow: ASIOBool): pASIOTime; cdecl; begin result := bufferSwitchTimeInfo(07, timeInfo, index, processNow); end;
function bufferSwitchTimeInfo_08(timeInfo: pASIOTime; index: long; processNow: ASIOBool): pASIOTime; cdecl; begin result := bufferSwitchTimeInfo(08, timeInfo, index, processNow); end;
function bufferSwitchTimeInfo_09(timeInfo: pASIOTime; index: long; processNow: ASIOBool): pASIOTime; cdecl; begin result := bufferSwitchTimeInfo(09, timeInfo, index, processNow); end;
function bufferSwitchTimeInfo_10(timeInfo: pASIOTime; index: long; processNow: ASIOBool): pASIOTime; cdecl; begin result := bufferSwitchTimeInfo(10, timeInfo, index, processNow); end;
function bufferSwitchTimeInfo_11(timeInfo: pASIOTime; index: long; processNow: ASIOBool): pASIOTime; cdecl; begin result := bufferSwitchTimeInfo(11, timeInfo, index, processNow); end;
function bufferSwitchTimeInfo_12(timeInfo: pASIOTime; index: long; processNow: ASIOBool): pASIOTime; cdecl; begin result := bufferSwitchTimeInfo(12, timeInfo, index, processNow); end;
function bufferSwitchTimeInfo_13(timeInfo: pASIOTime; index: long; processNow: ASIOBool): pASIOTime; cdecl; begin result := bufferSwitchTimeInfo(13, timeInfo, index, processNow); end;
function bufferSwitchTimeInfo_14(timeInfo: pASIOTime; index: long; processNow: ASIOBool): pASIOTime; cdecl; begin result := bufferSwitchTimeInfo(14, timeInfo, index, processNow); end;
function bufferSwitchTimeInfo_15(timeInfo: pASIOTime; index: long; processNow: ASIOBool): pASIOTime; cdecl; begin result := bufferSwitchTimeInfo(15, timeInfo, index, processNow); end;

// --  --
procedure bufferSwitch_00(index: long; processNow: ASIOBool); cdecl; begin bufferSwitch(00, index, processNow); end;
procedure bufferSwitch_01(index: long; processNow: ASIOBool); cdecl; begin bufferSwitch(01, index, processNow); end;
procedure bufferSwitch_02(index: long; processNow: ASIOBool); cdecl; begin bufferSwitch(02, index, processNow); end;
procedure bufferSwitch_03(index: long; processNow: ASIOBool); cdecl; begin bufferSwitch(03, index, processNow); end;
procedure bufferSwitch_04(index: long; processNow: ASIOBool); cdecl; begin bufferSwitch(04, index, processNow); end;
procedure bufferSwitch_05(index: long; processNow: ASIOBool); cdecl; begin bufferSwitch(05, index, processNow); end;
procedure bufferSwitch_06(index: long; processNow: ASIOBool); cdecl; begin bufferSwitch(06, index, processNow); end;
procedure bufferSwitch_07(index: long; processNow: ASIOBool); cdecl; begin bufferSwitch(07, index, processNow); end;
procedure bufferSwitch_08(index: long; processNow: ASIOBool); cdecl; begin bufferSwitch(08, index, processNow); end;
procedure bufferSwitch_09(index: long; processNow: ASIOBool); cdecl; begin bufferSwitch(09, index, processNow); end;
procedure bufferSwitch_10(index: long; processNow: ASIOBool); cdecl; begin bufferSwitch(10, index, processNow); end;
procedure bufferSwitch_11(index: long; processNow: ASIOBool); cdecl; begin bufferSwitch(11, index, processNow); end;
procedure bufferSwitch_12(index: long; processNow: ASIOBool); cdecl; begin bufferSwitch(12, index, processNow); end;
procedure bufferSwitch_13(index: long; processNow: ASIOBool); cdecl; begin bufferSwitch(13, index, processNow); end;
procedure bufferSwitch_14(index: long; processNow: ASIOBool); cdecl; begin bufferSwitch(14, index, processNow); end;
procedure bufferSwitch_15(index: long; processNow: ASIOBool); cdecl; begin bufferSwitch(15, index, processNow); end;

// --
// -- now I feel a bit dizzy --
// --


// ******************************************************************

{ unaAsioBufferProcessor }

// -- --
procedure unaAsioBufferProcessor.BeforeDestruction();
begin
  inherited;
  //
  if ((nil <> f_drv) and (drv.bufferProcessor = self)) then
    f_drv.bufferProcessor := nil;
end;

// -- --
constructor unaAsioBufferProcessor.create(driver: unaAsioDriver);
begin
  driver.bufferProcessor := self;
  //
  inherited create();
end;

// -- --
function unaAsioBufferProcessor.doAsioMessage(selector, value: long; message: pointer; opt: pDouble; out res: long): bool;
begin
  result := false;	// continue processing
end;

// -- --
function unaAsioBufferProcessor.doBufferSwitch(index: long; processNow: bool): bool;
begin
  result := false;	// continue processing
end;

// -- --
function unaAsioBufferProcessor.doBufferSwitchTimeInfo(timeInfo: pASIOTime; index: long; processNow: bool; res: pASIOTime): bool;
begin
  result := false;	// continue processing
end;

// -- --
function unaAsioBufferProcessor.doSampleRateChanged(sRate: ASIOSampleRate): bool;
begin
  result := false;	// continue processing
end;


{ unaAsioDriver }

(*
    [ About Steinberg and COM. ]

    http://www.audiomulch.com/~rossb/code/calliasio

    BACKGROUND

    The IASIO interface declared in the Steinberg ASIO 2 SDK declares
    functions with no explicit calling convention. This causes MSVC++ to default
    to using the thiscall convention, which is a proprietary convention not
    implemented by some non-microsoft compilers - notably borland BCC,
    C++Builder, and gcc. MSVC++ is the defacto standard compiler used by
    Steinberg. As a result of this situation, the ASIO sdk will compile with
    any compiler, however attempting to execute the compiled code will cause a
    crash due to different default calling conventions on non-Microsoft
    compilers.

    THISCALL DEFINITION

    A number of definitions of the thiscall calling convention are floating
    around the internet. The following definition has been validated against
    output from the MSVC++ compiler:

    For non-vararg functions, thiscall works as follows: the object (this)
    pointer is passed in ECX. All arguments are passed on the stack in
    right to left order. The return value is placed in EAX. The callee
    clears the passed arguments from the stack.

*)

// --  --
function unaAsioDriver.canSampleRate(sampleRate: ASIOSampleRate): bool;
begin
{$IFDEF CPU64 }
  result := bool(f_asio.canSampleRate(sampleRate));
{$ELSE }
  asm
	push    dword ptr [sampleRate + 04]
	push    dword ptr [sampleRate + 00]
	//
	mov	eax, [self]
	mov	ecx, [eax][f_asio]
	mov	eax, [ecx]
	call	dword ptr [eax + cofs_canSampleRate]
	//
	mov	result, eax
  end;
{$ENDIF CPU64 }
  //
  result := (ASE_OK = int(result));
end;

// --  --
function unaAsioDriver.controlPanel(): ASIOError;
begin
{$IFDEF CPU64 }
  result := f_asio.controlPanel();
{$ELSE }
  asm
	mov	eax, [self]
	mov	ecx, [eax][f_asio]
	mov	eax, [ecx]
	call	dword ptr [eax + cofs_controlPanel]
	//
	mov	result, eax
  end;
{$ENDIF CPU64 }
end;

// --  --
constructor unaAsioDriver.create(asio: iASIO);
begin
  f_asio := asio;
  f_driverState := dsLoaded;
  //
  inherited create();
end;

// --  --
function unaAsioDriver.createBuffers(bufferInfos: pASIOBufferInfo; numChannels, bufferSize: long; callbacks: pASIOCallbacks): ASIOError;
begin
{$IFDEF CPU64 }
  result := f_asio.createBuffers(bufferInfos, numChannels, bufferSize, callbacks);
{$ELSE }
  asm
	// push in back order
	push    callbacks
	push	bufferSize
	push	numChannels
	push	bufferInfos
	//
	mov	eax, [self]
	mov	ecx, [eax][f_asio]
	mov	eax, [ecx]
	call	dword ptr [eax + cofs_createBuffers]
	//
	mov	result, eax
  end;
{$ENDIF CPU64 }
end;

// --  --
destructor unaAsioDriver.destroy();
begin
  stop(true);
  release();
  //
  inherited;
  //
  f_asio := nil;
end;

// --  --
function unaAsioDriver.disposeBuffers(): ASIOError;
begin
  if (dsRunning = driverState) then begin
    //
    stop(true);
    result := ASE_OK;
  end
  else begin
    //
    if (dsPrepared = driverState) then begin
      //
{$IFDEF CPU64 }
      result := f_asio.disposeBuffers();
{$ELSE }
      asm
	mov	eax, [self]
	mov	ecx, [eax][f_asio]
	mov	eax, [ecx]
	call	dword ptr [eax + cofs_disposeBuffers]
	//
	mov	result, eax
      end;
{$ENDIF CPU64 }
    end
    else
      result := ASE_InvalidMode;
    //
    if (ASE_OK = result) then
      fillChar(f_bufferInfo, sizeOf(f_bufferInfo), 0);
    //
    f_driverState := dsInitialized;
  end;
end;

// --  --
function unaAsioDriver.doAsioMessage(selector, value: long; message: pointer; opt: pDouble): long;
var
  done: bool;
begin
  if (nil <> bufferProcessor) then
    done := bufferProcessor.doAsioMessage(selector, value, message, opt, result)
  else
    done := false;
  //
  if (not done) then begin
    //
    // currently the parameters "message" and "opt" are not used.
    case (selector) of

      kAsioSelectorSupported: begin
	//
	if ((kAsioResetRequest = value) or
	    (kAsioEngineVersion = value) or
	    (kAsioResyncRequest = value) or
	    (kAsioLatenciesChanged = value) or
	    // the following three were added for ASIO 2.0, you don't necessarily have to support them
	    (kAsioSupportsTimeInfo = value) or
	    (kAsioSupportsTimeCode = value) or
	    (kAsioSupportsInputMonitor = value)) then
	  result := ASIOTrue
	else
	  result := ASIOFalse;
      end;

      kAsioResetRequest: begin
	// defer the task and perform the reset of the driver during the next "safe" situation
	// You cannot reset the driver right now, as this code is called from the driver.
	// Reset the driver is done by completely destruct is. I.e. ASIOStop(), ASIODisposeBuffers(), Destruction
	// Afterwards you initialize the driver again.
	f_shouldReset := true;
	result := ASIOTrue;
      end;

      kAsioResyncRequest: begin
	// This informs the application, that the driver encountered some non fatal data loss.
	// It is used for synchronization purposes of different media.
	// Added mainly to work around the Win16Mutex problems in Windows 95/98 with the
	// Windows Multimedia system, which could loose data because the Mutex was hold too long
	// by another thread.
	// However a driver can issue it in other situations, too.
	result := ASIOTrue;
      end;

      kAsioLatenciesChanged: begin
	// This will inform the host application that the drivers were latencies changed.
	// Beware, it this does not mean that the buffer sizes have changed!
	// You might need to update internal delay data.
	result := ASIOTrue;
      end;

      kAsioEngineVersion: begin
	// return the supported ASIO version of the host application
	// If a host applications does not implement this selector, ASIO 1.0 is assumed
	// by the driver
	result := kAsioEngineVersion;
      end;

      kAsioSupportsTimeInfo: begin
	// informs the driver wether the asioCallbacks.bufferSwitchTimeInfo() callback is supported.
	// For compatibility with ASIO 1.0 drivers the host application should always support
	// the "old" bufferSwitch method, too.
	result := ASIOTrue;
      end;

      kAsioSupportsTimeCode: begin
	// informs the driver wether application is interested in time code info.
	// If an application does not need to know about time code, the driver has less work to do.
	result := ASIOFalse;	// TODO
      end;

      else
	result := ASIOFalse;

    end; // case () ...
    //
    if (assigned(onAsioMessage)) then
      onAsioMessage(self, selector, value, message, opt, result);
    //
  end;
end;

// --  --
procedure unaAsioDriver.doBufferSwitch(index: long; processNow: bool);
var
  done: bool;
  timeInfo: ASIOTime;
begin
  if (nil <> bufferProcessor) then
    done := bufferProcessor.doBufferSwitch(index, processNow)
  else
    done := false;
  //
  if (not done) then begin
    //
    if (assigned(onBufferSwitch)) then
      onBufferSwitch(self, index, processNow);
    //
    // the actual processing callback.
    // Beware that this is normally in a seperate thread, hence be sure that you take care
    // about thread synchronization. This is omitted here for simplicity.
    //
    // as this is a "back door" into the bufferSwitchTimeInfo a timeInfo needs to be created
    // though it will only set the timeInfo.samplePosition and timeInfo.systemTime fields and the according flags
    fillChar(timeInfo, sizeof(timeInfo), 0);
    timeInfo.timeInfo.speed := 1;
    timeInfo.timeInfo.sampleRate := getSampleRate();
    //
    // get the time stamp of the buffer, not necessary if no
    // synchronization to other media is required
    if (ASE_OK = getSamplePosition(timeInfo.timeInfo.samplePosition, timeInfo.timeInfo.systemTime)) then
      timeInfo.timeInfo.flags := kSystemTimeValid or kSamplePositionValid;
    //
    doBufferSwitchTimeInfo(@timeInfo, index, processNow);
  end;
end;

// --  --
function unaAsioDriver.doBufferSwitchTimeInfo(timeInfo: pASIOTime; index: long; processNow: bool): pASIOTime;
var
  done: bool;
  i: int;
  sz: unsigned;
begin
  result := timeInfo;
  //
  if (nil <> bufferProcessor) then
    done := bufferProcessor.doBufferSwitchTimeInfo(timeInfo, index, processNow, timeInfo)
  else
    done := false;
  //
  if (not done) then begin
    //
    // the actual processing callback.
    // Beware that this is normally in a seperate thread, hence be sure that you take care
    // about thread synchronization. This is omitted here for simplicity.
    //
    // perform the processing
    for i := inputChannels to outputChannels - 1 do begin
      //
      if (not bool(channelInfo[i].isInput) and bool(channelInfo[i].isActive)) then begin
	//
	// OK do processing for the outputs only
	sz := getBufferSizeInBytes(i);
	if (0 < sz) then
	  fillChar(bufferInfo[i].buffers[index]^, sz, 0);
	//
      end;  // if (not Input and Active) ...
    end; // for (i) ...
    //
    if (assigned(onBufferSwitchTimeInfo)) then
      onBufferSwitchTimeInfo(self, timeInfo, index, processNow, timeInfo);
    //
    // finally if the driver supports the ASIOOutputReady() optimization, do it here, all data are in place
    if (postOutput) then
      outputReady();
  end;
end;

// --  --
procedure unaAsioDriver.doSampleRateChanged(rate: ASIOSampleRate);
var
  done: bool;
begin
  if (nil <> bufferProcessor) then
    done := bufferProcessor.doSampleRateChanged(rate)
  else
    done := false;
  //
  if (not done) then begin
    //
    if (assigned(onSampleRateChanged)) then
      onSampleRateChanged(self, rate);
    //
  end;  
end;

// --  --
function unaAsioDriver.future(selector: long; opt: pointer): ASIOError;
begin
{$IFDEF CPU64 }
  result := f_asio.future(selector, opt);
{$ELSE }
  asm
	// push in back order
	push    opt
	push	selector
	//
	mov	eax, [self]
	mov	ecx, [eax][f_asio]
	mov	eax, [ecx]
	call	dword ptr [eax + cofs_future]
	//
	mov	result, eax
  end;
{$ENDIF CPU64 }
end;

// --  --
function unaAsioDriver.getBufferInfoByIndex(index: int): pASIOBufferInfo;
begin
  if (index < inputChannels + outputChannels) then
    result := @f_bufferInfo[index]
  else
    result := nil;  
end;

// --  --
function unaAsioDriver.getBufferSize(out minSize, maxSize, preferredSize, granularity: long): ASIOError;
begin
{$IFDEF CPU64 }
  result := f_asio.getBufferSize(minSize, maxSize, preferredSize, granularity);
{$ELSE }
  asm
	// push in back order
	push    granularity
	push	preferredSize
	push	maxSize
	push	minSize
	//
	mov	eax, [self]
	mov	ecx, [eax][f_asio]
	mov	eax, [ecx]
	call	dword ptr [eax + cofs_getBufferSize]
	//
	mov	result, eax
  end;
{$ENDIF CPU64 }
end;

function unaAsioDriver.getBufferSizeInBytes(chIndex: int): int;
var
  m: int;
begin
  if (chIndex < inputChannels + outputChannels) then begin
    //
    case (channelInfo[chIndex]._type) of

      //
      ASIOSTInt16LSB:   m := 2;
      ASIOSTInt24LSB:   m := 3;		// used for 20 bits as well
      ASIOSTInt32LSB:   m := 4;
      ASIOSTFloat32LSB: m := 4;		// IEEE 754 32 bit float, as found on Intel x86 architecture
      ASIOSTFloat64LSB: m := 8;		// IEEE 754 64 bit double float, as found on Intel x86 architecture

      // these are used for 32 bit data buffer, with different alignment of the data inside
      // 32 bit PCI bus systems can more easily used with these
      ASIOSTInt32LSB16,			// 32 bit data with 18 bit alignment
      ASIOSTInt32LSB18,			// 32 bit data with 18 bit alignment
      ASIOSTInt32LSB20,			// 32 bit data with 20 bit alignment
      ASIOSTInt32LSB24: m := 4;		// 32 bit data with 24 bit alignment

      ASIOSTInt16MSB:   m := 2;
      ASIOSTInt24MSB:   m := 3;
      ASIOSTInt32MSB:   m := 4;
      ASIOSTFloat32MSB: m := 4;		// IEEE 754 32 bit float, as found on Intel x86 architecture
      ASIOSTFloat64MSB: m := 8;		// IEEE 754 64 bit double float, as found on Intel x86 architecture

      // these are used for 32 bit data buffer, with different alignment of the data inside
      // 32 bit PCI bus systems can more easily used with these
      ASIOSTInt32MSB16,			// 32 bit data with 18 bit alignment
      ASIOSTInt32MSB18,			// 32 bit data with 18 bit alignment
      ASIOSTInt32MSB20,			// 32 bit data with 20 bit alignment
      ASIOSTInt32MSB24: m := 4;		// 32 bit data with 24 bit alignment

      else
	m := 1;	// unknow channel type, assume at least 1 byte per sample

    end; // case (channel type) ..
    //
    result := bufActualSize * m;
  end
  else
    result := -1;
end;

// --  --
function unaAsioDriver.getChannelInfo(out info: ASIOChannelInfo): ASIOError;
begin
{$IFDEF CPU64 }
  result := f_asio.getChannelInfo(info);
{$ELSE }
  asm
	// push in back order
	push    info
	//
	mov	eax, [self]
	mov	ecx, [eax][f_asio]
	mov	eax, [ecx]
	call	dword ptr [eax + cofs_getChannelInfo]
	//
	mov	result, eax
  end;
{$ENDIF CPU64 }
end;

// --  --
function unaAsioDriver.getChannelInfoByIndex(index: int): pASIOChannelInfo;
begin
  if (index < inputChannels + outputChannels) then
    result := @f_channelInfo[index]
  else
    result := nil;  
end;

// --  --
function unaAsioDriver.getChannels(out numInputChannels, numOutputChannels: long): ASIOError;
begin
{$IFDEF CPU64 }
  result := f_asio.getChannels(numInputChannels, numOutputChannels);
{$ELSE }
  asm
	// push in back order
	push    numOutputChannels
	push	numInputChannels
	//
	mov	eax, [self]
	mov	ecx, [eax][f_asio]
	mov	eax, [ecx]
	call	dword ptr [eax + cofs_getChannels]
	//
	mov	result, eax
  end;
{$ENDIF CPU64 }
end;

// --  --
function unaAsioDriver.getClockSources(clocks: pASIOClockSources; var numSources: long): ASIOError;
begin
{$IFDEF CPU64 }
  result := f_asio.getClockSources(clocks, numSources);
{$ELSE }
  asm
	// push in back order
	push    numSources
	push	clocks
	//
	mov	eax, [self]
	mov	ecx, [eax][f_asio]
	mov	eax, [ecx]
	call	dword ptr [eax + cofs_getClockSources]
	//
	mov	result, eax
  end;
{$ENDIF CPU64 }
end;

// --  --
function unaAsioDriver.getDriverInfo(): pASIODriverInfo;
begin
  result := @f_driverInfo;
end;

// --  --
function unaAsioDriver.getDriverName(hardCall: bool): aString;
var
  name: array[byte] of aChar;
begin
  if (hardCall) then begin
    //
{$IFDEF CPU64 }
    f_asio.getDriverName(name);
{$ELSE }
    asm
	  lea	eax, name
	  push	eax
	  //
	  mov	eax, [self]
	  mov	ecx, [eax][f_asio]
	  mov	eax, [ecx]
	  call	dword ptr [eax + cofs_getDriverName]
    end;
{$ENDIF CPU64 }
    //
    result := name;
  end
  else
    result := driverInfo.name;
end;

// --  --
function unaAsioDriver.getDriverVersion(hardCall: bool): long;
begin
  if (hardCall) then begin
    //
{$IFDEF CPU64 }
    result := f_asio.getDriverVersion()
{$ELSE }
    asm
	mov	eax, [self]
	mov	ecx, [eax][f_asio]
	mov	eax, [ecx]
	call	dword ptr [eax + cofs_getDriverVersion]
	//
	mov	result, eax
    end;
{$ENDIF CPU64 }
  end
  else
    result := driverInfo.asioVersion;
end;

// --  --
function unaAsioDriver.getDriverError(hardCall: bool): aString;
var
  message: array[byte] of aChar;
begin
  if (hardCall) then begin
    //
{$IFDEF CPU64 }
    f_asio.getErrorMessage(message);
{$ELSE }
    asm
	  lea	eax, message
	  push	eax
	  //
	  mov	eax, [self]
	  mov	ecx, [eax][f_asio]
	  mov	eax, [ecx]
	  call	dword ptr [eax + cofs_getErrorMessage]
    end;
{$ENDIF CPU64 }
    //
    result := message;
  end
  else
    result := driverInfo.errorMessage;
end;

// --  --
function unaAsioDriver.getLatencies(out inputLatency, outputLatency: long): ASIOError;
begin
{$IFDEF CPU64 }
  result := f_asio.getLatencies(inputLatency, outputLatency);
{$ELSE }
  asm
	// push in back order
	push    outputLatency
	push	inputLatency
	//
	mov	eax, [self]
	mov	ecx, [eax][f_asio]
	mov	eax, [ecx]
	call	dword ptr [eax + cofs_getLatencies]
	//
	mov	result, eax
  end;
{$ENDIF CPU64 }
end;

// --  --
function unaAsioDriver.getSamplePosition(out sPos: ASIOSamples; out tStamp: ASIOTimeStamp): ASIOError;
begin
{$IFDEF CPU64 }
  result := f_asio.getSamplePosition(sPos, tStamp);
  {$IFDEF ASIO_FLIPINT64 }
  sPos := swap64i(sPos);
  tStamp := swap64i(tStamp);
  {$ENDIF ASIO_FLIPINT64 }
{$ELSE }
  asm
	// push in back order
	push    tStamp
	push	sPos
	//
	mov	eax, [self]
	mov	ecx, [eax][f_asio]
	mov	eax, [ecx]
	call	dword ptr [eax + cofs_getSamplePosition]
	//
	mov	result, eax
	//
{$IFDEF ASIO_FLIPINT64 }
	//
	// for some crazy reason int64 is stored in hi, lo order..
	mov	eax, [tStamp]
	mov	ebx, [eax + 00]
	mov	ecx, [eax + 04]
	mov	[eax + 00], ecx
	mov	[eax + 04], ebx
	//
	mov	eax, [sPos]
	mov	ebx, [eax + 00]
	mov	ecx, [eax + 04]
	mov	[eax + 00], ecx
	mov	[eax + 04], ebx
	//
{$ENDIF ASIO_FLIPINT64 }
  end;
{$ENDIF CPU64 }
end;

// --  --
function unaAsioDriver.getSampleRate(): ASIOSampleRate;
begin
{$IFDEF CPU64 }
  {result := }f_asio.getSampleRate(result);
{$ELSE }
  asm
	// push in back order
	lea	eax, result
	push    eax
	//
	mov	eax, [self]
	mov	ecx, [eax][f_asio]
	mov	eax, [ecx]
	call	dword ptr [eax + cofs_getSampleRate]
  end;
{$ENDIF CPU64 }
end;

// --  --
function unaAsioDriver.getSamples(channelIndex, bufIndex: int; outBuffer: pInt16Array; startSampleIndex, samplesCount: int): ASIOError;
var
  s, nCh, ch, chFrom, chTo: int32;
  buf: pointer;
begin
  if ((channelIndex < inputChannels) and (0 <= startSampleIndex) and (bufActualSize > startSampleIndex)) then begin
    //
    result := ASE_OK;
    if (0 > samplesCount) then
      samplesCount := bufActualSize;
    //
    nCh := inputChannels;
    //
    if (0 > channelIndex) then begin
      //
      chFrom := 0;
      chTo := inputChannels - 1;
    end
    else begin
      //
      chFrom := channelIndex;
      chTo := channelIndex;
    end;
    //
    for ch := chFrom to chTo do begin
      //
      if (ASE_OK <> result) then
	break;
      //
      buf := bufferInfo[ch].buffers[bufIndex];
      for s := startSampleIndex to startSampleIndex + samplesCount - 1 do begin
	//
	case (channelInfo[ch]._type) of

	  // -- MSB -
	  ASIOSTInt16MSB: // 16 bit data word
	    outBuffer[ch + (nCh * s)] := swap16i(pInt16Array(buf)[s]);

	  ASIOSTInt24MSB: // (NOT SUPPORTED) This is the packed 24 bit format. 2 data words will spawn consecutive 6 bytes in memory.
	    result := ASE_NotPresent;

	  ASIOSTInt32MSB: // This format should also be used for 24 bit data, if the sample data is left aligned.
			  //	Lowest 8 bit should be reset or dithered whatever the hardware/software provides.
	    outBuffer[ch + (nCh * s)] := sshr( swap32i(pInt32Array(buf)[s]), 16);

	  ASIOSTFloat32MSB: // (NOT SUPPORTED) IEEE 754 32 bit float, as found on PowerPC implementation
	    result := ASE_NotPresent;

	  ASIOSTFloat64MSB: // (NOT SUPPORTED) IEEE 754 64 bit float, as found on PowerPC implementation
	    result := ASE_NotPresent;

	  // -- LSB --
	  ASIOSTInt16LSB: // 16 bit data word
	    outBuffer[ch + (nCh * s)] := pInt16Array(buf)[s];

	  ASIOSTInt24LSB: // (NOT SUPPORTED) This is the packed 24 bit format. 2 data words will spawn consecutive 6 bytes in memory.
	    result := ASE_NotPresent;

	  ASIOSTInt32LSB: begin// This format should also be used for 24 bit data, if the sample data is left aligned.
	    //
	    if (f_looksLike24) then begin
	      //
	      if (pInt32Array(buf)[s] > $7FFFFF)
		or
		 (pInt32Array(buf)[s] < -8388608)
	      then
		f_looksLike24 := false;
	    end;
	    //
	    if (f_looksLike24) then
	      outBuffer[ch + (nCh * s)] := sshr( pInt32Array(buf)[s], 8)
	    else
	      outBuffer[ch + (nCh * s)] := sshr( pInt32Array(buf)[s], 16);
	  end;

	  ASIOSTFloat32LSB: // IEEE 754 32 bit float, as found on Intel x86 architecture
	    outBuffer[ch + (nCh * s)] := trunc(pSingleArray(buf)[s] * $7FFF);

	  ASIOSTFloat64LSB: // IEEE 754 64 bit float, as found on Intel x86 architecture
	    outBuffer[ch + (nCh * s)] := trunc(pDoubleArray(buf)[s] * $7FFF);

	  else
	    result := ASE_NotPresent;			// (NOT SUPPORTED)

	end; // case
	//
	if (ASE_OK <> result) then
	  break;
	//
      end; // for (s in samples)
      //
    end; // for (ch in channels)
    //
  end // if (index is OK) ..
  else
    result := ASE_InvalidParameter;
end;

// --  --
function unaAsioDriver.init(sysref: long; createBuffers: bool; bufSize: int): ASIOError;
var
  res: ASIOBool;
begin
  if ((driverState = dsLoaded) or ((driverState = dsInitialized) and createBuffers)) then begin
    //
    if (driverState = dsLoaded) then begin
      //
{$IFDEF CPU64 }
      res := f_asio.init(pointer(sysref));
{$ELSE }
      asm
	    push	sysref
	    //
	    mov		eax, [self]
	    mov		ecx, [eax][f_asio]
	    mov		eax, [ecx]
	    call	dword ptr [eax + cofs_init]
	    //
	    mov	res, eax
      end;
{$ENDIF CPU64 }
    end
    else
      res := ASIOTrue;
    //
    if (not bool(res)) then begin
      //
      str2arrayA(getDriverError(), f_driverInfo.errorMessage);
      //
      result := ASE_NotPresent;
    end
    else begin
      //
      f_driverInfo.asioVersion := kAsioEngineVersion;
      f_driverInfo.driverVersion := getDriverVersion(true);
      //
      str2arrayA(getDriverName(true), f_driverInfo.name);
      //
      f_handle := sysref;
      f_driverInfo.errorMessage := '';
      //
      // I hate this, but that is by ASIO design
      f_di := getGDriverIndex(self);
      if (0 <= f_di) then begin
	//
	f_driverState := dsInitialized;
	//
	// set up the asioCallback structure and create the ASIO data buffer (if told so)
	f_callbacks := g_callbacks[f_di];
	//
	if (createBuffers) then begin
	  //
	  result := internalCreateBuffers(bufSize);
	  //
	  future(kAsioEnableTimeCodeRead);  // inform driver we are OK with new buffer CB
					    // (seems not working with most drivers)
	end
	else
	  result := ASE_OK;
      end
      else
	result := ASE_NoMemory;	// out of space in drivers array
    end;
  end
  else
    result := ASE_InvalidMode;
end;

// --  --
function unaAsioDriver.internalCreateBuffers(bufSize: int): ASIOError;
var
  i: long;
begin
  if (dsInitialized = driverState) then begin
    //
    result := internalGetStaticInfo();
    if (ASE_OK = result) then begin
      //
      if (0 > bufSize) then
	f_actualBufSize := f_preferredBufSize
      else
	f_actualBufSize := min(max(bufSize, bufMinSize), bufMaxSize);
      //
      // prepare inputs (Though this is not necessaily required, no opened inputs will work, too)
      for i := 0 to f_inputChannels - 1 do begin
	//
	f_bufferInfo[i].isInput := ASIOTrue;
	f_bufferInfo[i].channelNum := i;
	f_bufferInfo[i].buffers[0] := nil;
	f_bufferInfo[i].buffers[1] := nil;
      end;
      //
      // prepare outputs
      for i := f_inputChannels to f_inputChannels + f_outputChannels - 1 do begin
	//
	f_bufferInfo[i].isInput := ASIOFalse;
	f_bufferInfo[i].channelNum := i - f_inputChannels;
	f_bufferInfo[i].buffers[0] := nil;
	f_bufferInfo[i].buffers[1] := nil;
      end;
      //
      // create and activate buffers
      result := createBuffers(pASIOBufferInfo(@f_bufferInfo), f_inputChannels + f_outputChannels, f_actualBufSize, @f_callbacks);
      if (ASE_OK = result) then begin
	//
	// now get all the channel details, sample word length, name, word clock group and activation
	for i := 0 to f_inputChannels + f_outputChannels - 1 do begin
	  //
	  f_channelInfo[i].channel := f_bufferInfo[i].channelNum;
	  f_channelInfo[i].isInput := f_bufferInfo[i].isInput;
	  //
	  result := getChannelInfo(f_channelInfo[i]);
	  if (ASE_OK <> result) then
	    break;
	  //
	end;
	//
	if (ASE_OK = result) then begin
	  //
	  // get the input and output latencies
	  // Latencies often are only valid after ASIOCreateBuffers()
	  // (input latency is the age of the first sample in the currently returned audio block)
	  // (output latency is the time the first sample in the currently returned audio block requires to get to the output)
	  //
	  result := getLatencies(f_inputLatency, f_outputLatency);
	end;
	//
	f_driverState := dsPrepared;
      end;
    end;
  end
  else
    result := ASE_InvalidMode;
end;

// --  --
function unaAsioDriver.internalGetStaticInfo(): ASIOError;
var
  rate: ASIOSampleRate;
begin
  result := -1;
  //
  if (dsLoaded <> driverState) then begin
    //
    // collect the informational data of the driver
    // get the number of available channels
    if (ASE_OK = getChannels(f_inputChannels, f_outputChannels)) then begin
      //
      f_inputChannels := min(kMaxInputChannels, f_inputChannels);
      f_outputChannels := min(kMaxOutputChannels, f_outputChannels);
      //
      // get the usable buffer sizes
      if (ASE_OK = getBufferSize(f_minBufSize, f_maxBufSize, f_preferredBufSize, f_granularity)) then begin
	//
	// get the currently selected sample rate
	rate := getSampleRate();
	if ((rate < 1.0) or (rate > 96000.0)) then begin
	  //
	  // Driver does not store it's internal sample rate, so set it to a know one.
	  // Usually you should check beforehand, that the selected sample rate is valid
	  // with ASIOCanSampleRate().
	  if (ASE_OK = setSampleRate(44100.0)) then
	  else begin
	    //
	    result := -5;
	    exit;
	  end;
	end;
	//
	// check wether the driver requires the ASIOOutputReady() optimization
	// (can be used by the driver to reduce output latency by one block)
	f_postOutput := (ASE_OK = outputReady());
	//
	result := ASE_OK;
      end;
    end;
  end;
end;

// --  --
function unaAsioDriver.outputReady(): ASIOError;
begin
{$IFDEF CPU64 }
  result := f_asio.outputReady();
{$ELSE }
  asm
	mov	eax, [self]
	mov	ecx, [eax][f_asio]
	mov	eax, [ecx]
	call	dword ptr [eax + cofs_outputReady]
	//
	mov	result, eax
  end;
{$ENDIF CPU64 }
end;

// --  --
function unaAsioDriver.release(): bool;
begin
  stop(true);	// just in case driver was not stopped
  //
  disposeBuffers();
  //
  g_driver[f_di] := nil;
  f_di := -1;
  //
  result := true;
end;

// --  --
procedure unaAsioDriver.setBufferProcessor(bp: unaAsioBufferProcessor);
begin
  if (nil <> bufferProcessor) then
    bufferProcessor.f_drv := nil;
  //
  f_bp := bp;
  //
  if (nil <> bufferProcessor) then
    bufferProcessor.f_drv := self;
end;

// --  --
function unaAsioDriver.setClockSource(reference: long): ASIOError;
begin
{$IFDEF CPU64 }
  result := f_asio.setClockSource(reference);
{$ELSE }
  asm
	push    reference
	//
	mov	eax, [self]
	mov	ecx, [eax][f_asio]
	mov	eax, [ecx]
	call	dword ptr [eax + cofs_setClockSource]
	//
	mov	result, eax
  end;
{$ENDIF CPU64 }
end;


{$IFDEF CPU64 }

// --  --
function add16(v: int16; f: double): int16;
var
  r: uint32;
begin
  r := trunc(v + f);
  //
  // todo:
  result := r;
end;

{$ELSE }

// --  --
function add16(v: int16; f: double): int16; assembler;
asm
	fld	f

	cwde				// sign extend ax to eax
	push	eax

	fiadd	dword ptr [esp]
	fistp	dword ptr [esp]
	fwait

	pop	eax

//  $0000.0000 ... $0000.7FFF -> OK
//  $0000.8000 ... $7FFF.FFFF -> $7FFF
//  $8000.0000 ... $FFFF.7FFF -> $8000
//  $FFFF.8000 ... $FFFF.FFFF -> OK

	cmp	eax, $00007fff
	jle	@check2

	mov	eax, $00007fff
	jmp	@done

  @check2:
	cmp	eax, $ffff8000
	jnl	@done

	mov	eax, $ffff8000
  @done:
end;

{$ENDIF CPU64 }


// --  --
function add32(v: int32; f: double): int32;
var
  d: double;
begin
{$IFDEF CPU64 }
  d := v + f;
{$ELSE }
  asm
	fld	f

	push	eax

	fiadd	dword ptr [esp]
	fstp	qword ptr [d]
	fwait

	pop	eax
  end;
{$ENDIF CPU64 }
  //
  if (d < int32($80000000)) then
    result := int32($80000000)
  else
    if (d > $7FFFFFFF) then
      result := $7FFFFFFF
    else
      result := trunc(d);
end;

// --  --
function add24(v: int32; f: double): int32;
var
  d: double;
begin
{$IFDEF CPU64 }
  d := v + f;
{$ELSE }
  asm
	fld	f

	push	eax

	fiadd	dword ptr [esp]
	fstp	qword ptr [d]
	fwait

	pop	eax
  end;
{$ENDIF CPU64 }
  //
  if (d < -8388608) then
    result := -8388608
  else
    if (d > 8388607) then
      result := 8388607
    else
      result := trunc(d);
end;

// --  --
function unaAsioDriver.setSample(channelIndex, bufIndex, sampleIndex: int; value: double; op: unaASIOSampleOp): ASIOError;
var
  buf: pointer;
begin
  if (channelIndex < inputChannels + outputChannels) then begin
    //
    result := ASE_OK;
    //
    buf := bufferInfo[channelIndex].buffers[bufIndex];
    case (channelInfo[channelIndex]._type) of

      ASIOSTInt16MSB: // 16 bit data word
	case (op) of
	  soAdd    : pInt16Array(buf)[sampleIndex] := swap16u( add16(swap16u(pInt16Array(buf)[sampleIndex]),  value * $7FFF) );
	  soSub    : pInt16Array(buf)[sampleIndex] := swap16u( add16(swap16u(pInt16Array(buf)[sampleIndex]), -value * $7FFF) );
	  soReplace: pInt16Array(buf)[sampleIndex] := swap16u( add16(0, value * $7FFF) );
	end;

      ASIOSTInt24MSB: // (NOT SUPPORTED) This is the packed 24 bit format. 2 data words will spawn consecutive 6 bytes in memory.
	case (op) of
	  soAdd    : result := ASE_InvalidParameter;
	  soSub    : result := ASE_InvalidParameter;
	  soReplace: result := ASE_InvalidParameter;
	end;

      ASIOSTInt32MSB: // This format should also be used for 24 bit data, if the sample data is left
	case (op) of
	  soAdd    : pInt32Array(buf)[sampleIndex] := swap32u( add32(swap32u(pInt32Array(buf)[sampleIndex]),  value * $7FFFFFFF) );
	  soSub    : pInt32Array(buf)[sampleIndex] := swap32u( add32(swap32u(pInt32Array(buf)[sampleIndex]), -value * $7FFFFFFF) );
	  soReplace: pInt32Array(buf)[sampleIndex] := swap32u( add32(0, value * $7FFFFFFF) );
	end;
									// aligned. Lowest 8 bit should be reset or dithered whatever the
									// hardware/software provides.

      ASIOSTFloat32MSB:	// (NOT SUPPORTED) IEEE 754 32 bit float, as found on PowerPC implementation
	case (op) of
	  soAdd    : result := ASE_InvalidParameter;
	  soSub    : result := ASE_InvalidParameter;
	  soReplace: result := ASE_InvalidParameter;
	end;

      ASIOSTFloat64MSB: // (NOT SUPPORTED) IEEE 754 64 bit float, as found on PowerPC implementation
	case (op) of
	  soAdd    : result := ASE_InvalidParameter;
	  soSub    : result := ASE_InvalidParameter;
	  soReplace: result := ASE_InvalidParameter;
	end;

      // --  --

      ASIOSTInt16LSB: // 16 bit data word
	case (op) of
	  soAdd    : pInt16Array(buf)[sampleIndex] := add16(pInt16Array(buf)[sampleIndex],  value * $7FFF);
	  soSub    : pInt16Array(buf)[sampleIndex] := add16(pInt16Array(buf)[sampleIndex], -value * $7FFF);
	  soReplace: pInt16Array(buf)[sampleIndex] := add16(0, value * $7FFF);
	end;

      ASIOSTInt24LSB: // (NOT SUPPORTED) This is the packed 24 bit format. 2 data words will spawn consecutive 6 bytes in memory.
	case (op) of
	  soAdd    : result := ASE_InvalidParameter;
	  soSub    : result := ASE_InvalidParameter;
	  soReplace: result := ASE_InvalidParameter;
	end;

      ASIOSTInt32LSB: // This format should also be used for 24 bit data, if the sample data is left aligned.
	case (op) of
	  soAdd    : pInt32Array(buf)[sampleIndex] := add32(pInt32Array(buf)[sampleIndex],  value * $7FFFFFFF);
	  soSub    : pInt32Array(buf)[sampleIndex] := add32(pInt32Array(buf)[sampleIndex], -value * $7FFFFFFF);
	  soReplace: pInt32Array(buf)[sampleIndex] := add32(0, value * $7FFFFFFF);
	end;

      ASIOSTFloat32LSB: // IEEE 754 32 bit float, as found on Intel x86 architecture
	case (op) of
	  soAdd    : pSingleArray(buf)[sampleIndex] := pSingleArray(buf)[sampleIndex] + value;
	  soSub    : pSingleArray(buf)[sampleIndex] := pSingleArray(buf)[sampleIndex] - value;
	  soReplace: pSingleArray(buf)[sampleIndex] := value;
	end;

      ASIOSTFloat64LSB: // IEEE 754 64 bit float, as found on Intel x86 architecture
	case (op) of
	  soAdd    : pDoubleArray(buf)[sampleIndex] := pDoubleArray(buf)[sampleIndex] + value;
	  soSub    : pDoubleArray(buf)[sampleIndex] := pDoubleArray(buf)[sampleIndex] - value;
	  soReplace: pDoubleArray(buf)[sampleIndex] := value;
	end;

      else
	result := ASE_NotPresent;			// (NOT SUPPORTED)

    end;
  end
  else
    result := ASE_InvalidParameter;
end;

// --  --
function unaAsioDriver.setSample(channelIndex, bufIndex, sampleIndex, value: int32; op: unaASIOSampleOp): ASIOError;
begin
  result := setSample(channelIndex, bufIndex, sampleIndex, value / $7FFFFFFF, op);
end;

// --  --
function unaAsioDriver.setSampleRate(const sampleRate: ASIOSampleRate): ASIOError;
begin
{$IFDEF CPU64 }
  result := f_asio.setSampleRate(sampleRate);
{$ELSE }
  asm
	push    dword ptr [sampleRate + 04]
	push    dword ptr [sampleRate + 00]
	//
	mov	eax, [self]
	mov	ecx, [eax][f_asio]
	mov	eax, [ecx]
	call	dword ptr [eax + cofs_setSampleRate]
	//
	mov	result, eax
  end;
{$ENDIF CPU64 }
end;

// --  --
function unaAsioDriver.setSamples(channelIndex, bufIndex, startSampleIndex, samplesCount: int; values: pDouble; op: unaASIOSampleOp): ASIOError;
begin
  result := ASE_NotPresent;	// NOT SUPPORTED
end;

// --  --
function unaAsioDriver.setSamples(channelIndex, bufIndex, startSampleIndex, samplesCount: int; value: pInt32; op: unaASIOSampleOp): ASIOError;
begin
  result := ASE_NotPresent;	// NOT SUPPORTED
end;

// --  --
function unaAsioDriver.setSamples(channelIndex, bufIndex: int; inBuffer: pInt16Array; startSampleIndex, samplesCount: int): ASIOError;
var
  s, nCh, ch, chFrom, chTo: int32;
  //buf: pointer;
begin
  if ((channelIndex < outputChannels) and (0 <= startSampleIndex) and (bufActualSize > startSampleIndex)) then begin
    //
    result := ASE_OK;
    //
    if (0 > samplesCount) then
      samplesCount := bufActualSize;
    //
    nCh := outputChannels;
    //
    if (0 > channelIndex) then begin
      //
      chFrom := inputChannels;
      chTo := inputChannels + outputChannels - 1;
    end
    else begin
      //
      chFrom := inputChannels + channelIndex;
      chTo := inputChannels + channelIndex;
    end;
    //
    for ch := chFrom to chTo do begin
      //
      if (ASE_OK <> result) then
	break;
      //
      //buf := bufferInfo[ch].buffers[bufIndex];
      for s := startSampleIndex to startSampleIndex + samplesCount - 1 do begin
	//
	result := setSample(ch, bufIndex, s, int32(int64(inBuffer[ch - inputChannels + (nCh * s)]) shl 16), soReplace);
      end; // for (s in samples)
      //
    end; // for (ch in channels)
    //
  end // if (index is OK) ..
  else
    result := ASE_InvalidParameter;
end;


// --  --
function unaAsioDriver.start(createBuffers: bool;  bufSize: int): ASIOError;
begin
  f_looksLike24 := true;
  //
  if (createBuffers) then
    result := internalCreateBuffers(bufSize)
  else
    result := ASE_OK;
  //
  if ((ASE_OK = result) and (dsPrepared = driverState)) then begin
    //
{$IFDEF CPU64 }
    result := f_asio.start();
{$ELSE }
    asm
	mov	eax, [self]
	mov	ecx, [eax][f_asio]
	mov	eax, [ecx]
	call	dword ptr [eax + cofs_start]
	//
	mov	result, eax
    end;
{$ENDIF CPU64 }
    //
    if (ASE_OK = result) then
      f_driverState := dsRunning;
  end
  else
    result := ASE_InvalidMode;
end;

// --  --
function unaAsioDriver.stop(releaseBuffers: bool): ASIOError;
begin
  if (dsRunning = driverState) then begin
    //
{$IFDEF CPU64 }
    result := f_asio.stop();
{$ELSE }
    asm
	  mov	eax, [self]
	  mov	ecx, [eax][f_asio]
	  mov	eax, [ecx]
	  call	dword ptr [eax + cofs_stop]
	  //
	  mov	result, eax
    end;
{$ENDIF CPU64 }
    //
    f_driverState := dsPrepared;
  end
  else
    result := ASE_OK;
  //
  if ((ASE_OK = result) and releaseBuffers) then
    result := disposeBuffers();
end;



{ unaAsioDriverList }

// --  --
procedure unaAsioDriverList.AfterConstruction();
var
  hkEnum: HKEY;
  keyname: array[0..MAXDRVNAMELEN - 1] of aChar;
  pdl: pASIODRVSTRUCT;
  cr: LONG;
  index: DWORD;
begin
  hkEnum := 0;
  index := 0;
  //
  cr := RegOpenKey(HKEY_LOCAL_MACHINE, ASIO_PATH, hkEnum);
  while (ERROR_SUCCESS = cr) do begin
    //
    cr := RegEnumKeyA(hkEnum, index, keyname, MAXDRVNAMELEN);
    inc(index);
    if (ERROR_SUCCESS = cr) then
      f_lpdrvlist := newDrvStruct(hkEnum, keyname, 0, f_lpdrvlist);
  end;
  //
  if (0 <> hkEnum) then
    RegCloseKey(hkEnum);
  //
  pdl := lpdrvlist;
  while (nil <> pdl) do begin
    //
    inc(f_numdrv);
    pdl := pdl.next;
  end;
  //
  if (0 < numDrv) then begin
    //
    //CoInitializeEx(nil, COINIT_APARTMENTTHREADED {COINIT_MULTITHREADED or COINIT_SPEED_OVER_MEMORY});	// initialize COM for current thread
    CoInitialize(nil);	// initialize COM
  end;
  //
  inherited;
end;

// --  --
function unaAsioDriverList.asioCloseDriver(drvID: int): HRESULT;
var
  lpdrv: pASIODRVSTRUCT;
begin
  lpdrv := getDrvStruct(drvID);
  if (nil <> lpdrv) then
    freeAndNil(lpdrv.asiodrv);
  //
  result := S_OK;
end;

// --  --
function unaAsioDriverList.asioGetDriverCLSID(drvID: int; out clsid: CLSID): HRESULT;
var
  lpdrv: pASIODRVSTRUCT;
begin
  lpdrv := getDrvStruct(drvID);
  if (nil <> lpdrv) then begin
    //
    move(lpdrv.clsid, clsid, sizeof(clsid));
    result := S_OK;
  end
  else
    result := HRESULT(DRVERR_DEVICE_NOT_FOUND);
end;

// --  --
function unaAsioDriverList.asioGetDriverName(drvID: int): aString;
var
  lpdrv: pASIODRVSTRUCT;
begin
  lpdrv := getDrvStruct(drvID);
  if (nil <> lpdrv) then
    result := lpdrv.drvname
  else
    result := '';
end;

// --  --
function unaAsioDriverList.asioGetDriverPath(drvID: int): aString;
var
  lpdrv: pASIODRVSTRUCT;
begin
  lpdrv := getDrvStruct(drvID);
  if (nil <> lpdrv) then
    result := lpdrv.dllpath
  else
    result := '';
end;

// --  --
function unaAsioDriverList.asioGetDrvID(index: int): int;
var
  s: pASIODRVSTRUCT;
begin
  s := lpdrvlist;
  while ((0 < index) and (nil <> s)) do begin
    //
    s := s.next;
    dec(index);
  end;
  //
  if (nil <> s) then
    result := s.drvID
  else
    result := -1;
end;

// --  --
function unaAsioDriverList.asioGetNumDev(): int;
begin
  result := numDrv;
end;

// --  --
function unaAsioDriverList.asioOpenDriver(drvID: int; out asiodrv: unaAsioDriver): HRESULT;
var
  lpdrv: pASIODRVSTRUCT;
  comObj: iAsio;
begin
  lpdrv := getDrvStruct(drvID);
  if (nil <> lpdrv) then begin
    //
    if (nil = lpdrv.asiodrv) then begin
      //
      result := CoCreateInstance(lpdrv.clsid, nil, CLSCTX_INPROC_SERVER, lpdrv.clsid, comObj);
      if (S_OK = result) then begin
	//
	lpdrv.asiodrv := unaAsioDriver.create(comObj);
	asiodrv := lpdrv.asiodrv;
      end;
    end
    else begin
      //
      asiodrv := lpdrv.asiodrv;
      result := S_OK;
    end;
  end
  else
    result := HRESULT(DRVERR_DEVICE_NOT_FOUND);
end;

// --  --
procedure unaAsioDriverList.BeforeDestruction();
begin
  inherited;
  //
  deleteDrvStruct(lpdrvlist);
  f_lpdrvlist := nil;
  //
  if (0 < numDrv) then
    CoUninitialize();
  //
  f_numDrv := 0;
end;

// --  --
function unaAsioDriverList.getDrvStruct(drvID: int): pASIODRVSTRUCT;
begin
  result := lpdrvlist;
  while (nil <> result) do begin
    //
    if (result.drvID = drvID) then
      break
    else
      result := result.next;
  end;
end;


initialization
  //
  // let the fun begin
  //
  g_callbacks[00].bufferSwitch := bufferSwitch_00;
  g_callbacks[01].bufferSwitch := bufferSwitch_01;
  g_callbacks[02].bufferSwitch := bufferSwitch_02;
  g_callbacks[03].bufferSwitch := bufferSwitch_03;
  g_callbacks[04].bufferSwitch := bufferSwitch_04;
  g_callbacks[05].bufferSwitch := bufferSwitch_05;
  g_callbacks[06].bufferSwitch := bufferSwitch_06;
  g_callbacks[07].bufferSwitch := bufferSwitch_07;
  g_callbacks[08].bufferSwitch := bufferSwitch_08;
  g_callbacks[09].bufferSwitch := bufferSwitch_09;
  g_callbacks[10].bufferSwitch := bufferSwitch_10;
  g_callbacks[11].bufferSwitch := bufferSwitch_11;
  g_callbacks[12].bufferSwitch := bufferSwitch_12;
  g_callbacks[13].bufferSwitch := bufferSwitch_13;
  g_callbacks[14].bufferSwitch := bufferSwitch_14;
  g_callbacks[15].bufferSwitch := bufferSwitch_15;
  //
  g_callbacks[00].sampleRateChanged := sampleRateChanged_00;
  g_callbacks[01].sampleRateChanged := sampleRateChanged_01;
  g_callbacks[02].sampleRateChanged := sampleRateChanged_02;
  g_callbacks[03].sampleRateChanged := sampleRateChanged_03;
  g_callbacks[04].sampleRateChanged := sampleRateChanged_04;
  g_callbacks[05].sampleRateChanged := sampleRateChanged_05;
  g_callbacks[06].sampleRateChanged := sampleRateChanged_06;
  g_callbacks[07].sampleRateChanged := sampleRateChanged_07;
  g_callbacks[08].sampleRateChanged := sampleRateChanged_08;
  g_callbacks[09].sampleRateChanged := sampleRateChanged_09;
  g_callbacks[10].sampleRateChanged := sampleRateChanged_10;
  g_callbacks[11].sampleRateChanged := sampleRateChanged_11;
  g_callbacks[12].sampleRateChanged := sampleRateChanged_12;
  g_callbacks[13].sampleRateChanged := sampleRateChanged_13;
  g_callbacks[14].sampleRateChanged := sampleRateChanged_14;
  g_callbacks[15].sampleRateChanged := sampleRateChanged_15;
  //
  g_callbacks[00].asioMessage := asioMessage_00;
  g_callbacks[01].asioMessage := asioMessage_01;
  g_callbacks[02].asioMessage := asioMessage_02;
  g_callbacks[03].asioMessage := asioMessage_03;
  g_callbacks[04].asioMessage := asioMessage_04;
  g_callbacks[05].asioMessage := asioMessage_05;
  g_callbacks[06].asioMessage := asioMessage_06;
  g_callbacks[07].asioMessage := asioMessage_07;
  g_callbacks[08].asioMessage := asioMessage_08;
  g_callbacks[09].asioMessage := asioMessage_09;
  g_callbacks[10].asioMessage := asioMessage_10;
  g_callbacks[11].asioMessage := asioMessage_11;
  g_callbacks[12].asioMessage := asioMessage_12;
  g_callbacks[13].asioMessage := asioMessage_13;
  g_callbacks[14].asioMessage := asioMessage_14;
  g_callbacks[15].asioMessage := asioMessage_15;
  //
  g_callbacks[00].bufferSwitchTimeInfo := bufferSwitchTimeInfo_00;
  g_callbacks[01].bufferSwitchTimeInfo := bufferSwitchTimeInfo_01;
  g_callbacks[02].bufferSwitchTimeInfo := bufferSwitchTimeInfo_02;
  g_callbacks[03].bufferSwitchTimeInfo := bufferSwitchTimeInfo_03;
  g_callbacks[04].bufferSwitchTimeInfo := bufferSwitchTimeInfo_04;
  g_callbacks[05].bufferSwitchTimeInfo := bufferSwitchTimeInfo_05;
  g_callbacks[06].bufferSwitchTimeInfo := bufferSwitchTimeInfo_06;
  g_callbacks[07].bufferSwitchTimeInfo := bufferSwitchTimeInfo_07;
  g_callbacks[08].bufferSwitchTimeInfo := bufferSwitchTimeInfo_08;
  g_callbacks[09].bufferSwitchTimeInfo := bufferSwitchTimeInfo_09;
  g_callbacks[10].bufferSwitchTimeInfo := bufferSwitchTimeInfo_10;
  g_callbacks[11].bufferSwitchTimeInfo := bufferSwitchTimeInfo_11;
  g_callbacks[12].bufferSwitchTimeInfo := bufferSwitchTimeInfo_12;
  g_callbacks[13].bufferSwitchTimeInfo := bufferSwitchTimeInfo_13;
  g_callbacks[14].bufferSwitchTimeInfo := bufferSwitchTimeInfo_14;
  g_callbacks[15].bufferSwitchTimeInfo := bufferSwitchTimeInfo_15;

finalization

end.

