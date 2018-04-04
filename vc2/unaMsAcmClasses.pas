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

	  unaMsAcmClasses.pas - MS ACM classes
	  Voice Communicator components version 2.5

	----------------------------------------------
	  (c) 2012 Lake of Soft
	  All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 01 Jan 2002

	  modified by:
		Lake, Jan-Dec 2002
		Lake, Jan-Dec 2003
		Lake, Jan-Dec 2004
		Lake, Jan-Oct 2005
		Lake, Mar-Dec 2007
		Lake, Jan-Nov 2008
		Lake, Jan-Feb 2009
		Lake, Feb-Dec 2010
		Lake, Mar-Jun 2011
		Lake, Jan-May 2012

	----------------------------------------------
*)

{$I unaDef.inc }
{$I unaMSACMDef.inc }

{$IFNDEF VC_LIC_PUBLIC }
  {$DEFINE UNA_VC_ACMCLASSES_USE_DSP }		// define to link with DSPDlib modules
{$ENDIF VC_LIC_PUBLIC }

{*

  Contains Microsoft ACM wrapper and core VC wave device classes.

  @Author Lake

  Version 2.5.2009.07:
    + new getUnVolume() method;

  Version 2.5.2008.07:
    + new callback model;
    + SetVolume100()/GetVolume() for all wave components;
    + Silence detection built in into all wave components;

  Version 2.5.2010.02:
    + new VAD mode based on 3GPP codec;

  Version 2.5.2010.12:
    * jitter effect on WaveOut;

  Version 2.5.2012.04:
    * ASIO;

}

unit
  unaMsAcmClasses;

interface

{$IFDEF DEBUG }
  //
  {$DEFINE LOG_UNAMSACMCLASSES_INFOS }		// log informational messages
  {$DEFINE LOG_UNAMSACMCLASSES_ERRORS }		// log critical errors
  {x $DEFINE LOG_UNAMSACMCLASSES_INFOS_EX }	// log extra informational messages
  //
  // low level logging
  {xx $DEFINE DEBUG_LOG }
  {xx $DEFINE DEBUG_LOG_CODEC }
  {xx $DEFINE DEBUG_LOG_RT }	// real timer logging
  {xx $DEFINE DEBUG_LOG_MIXER }
  {xx $DEFINE DEBUG_LOG_MIXER2 }
  {xx $DEFINE DEBUG_LOG_MARKBUFF }
  {xx $DEFINE DEBUG_LOG_JITTER }
  {xx $DEFINE DEBUG_LOG_RIFF_MPEG }
{$ENDIF DEBUG }

uses
  Windows, unaTypes, MMSystem, unaMsAcmAPI,
  unaUtils, unaClasses, unaWave,
{$IFNDEF VC_LIC_PUBLIC }
  unaMpeg,
{$ENDIF VC_LIC_PUBLIC }
  unaOpenH323PluginAPI, unaBladeEncAPI, unaEncoderAPI, unaSpeexAPI,
  una3GPPVAD,
{$IFDEF UNA_VCACM_USE_ASIO }
  unaASIOAPI,
{$ENDIF UNA_VCACM_USE_ASIO }
{$IFDEF UNA_PROFILE }
  unaProfile,
{$ENDIF UNA_PROFILE }
{$IFDEF UNA_VC_ACMCLASSES_USE_DSP }
  unaDspLibH, unaDSPDLib, unaDspLibAutomation,
{$ENDIF UNA_VC_ACMCLASSES_USE_DSP }
  unaRiff;

var
  {*
	Number of chunks per second (in real time mode)

	Default value was changed from 20 to 25 (for 11025 rate to be handled better)
	AUG'03: changed to 50, for 11025 it will be 49
  }
  c_defChunksPerSecond: unsigned		= 50;

{$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
  // In callback model all chunks are put into playback queue as soon as they arrive.
{$ELSE }

  {*
	Number of chunks which should be present in input buffer
	of waveOutDevice component, before actual driver will be fed with data
	(helps avoid cuts, but increases the latency)
	Default value is 4
  }
  c_defPlaybackChunksAheadNumber: unsigned	= 4;

  {*
	Limits the number of chunks which can be feed ahead to waveOut driver.
	Default value is c_defPlaybackChunksAheadNumber + 3.
  }
  c_def_max_playbackChunksAheadNumber: unsigned	= 4 + 3;

{$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }

  {*
	Number of chunks to put into waveIn recording queue (does not afftect the latency).
	Default value is 10
  }
  c_defRecordingChunksAheadNum: unsigned	= 10;

  {*
	Number of chunks to put into waveOut before unpausing.
	Default value is 2
  }
  c_waveOut_unpause_after: unsigned	= 2;


const
  //
  c_defSamplingSamplesPerSec	= 44100;
  c_defSamplingBitsPerSample	= 16;
  c_defSamplingNumChannels	= 2;
  c_defSamplingChannelMask      = KSAUDIO_SPEAKER_STEREO;
  {*
	Max number of headers to utilize
  }
  c_max_wave_headers	= 200;


{$IFDEF UNA_PROFILE }
var
  profId_unaMsAcmStreamDevice_internalWrite: unsigned;
  profId_unaMsAcmStreamDevice_internalRead: unsigned;
  profId_unaMsAcmStreamDevice_getDataAvail: unsigned;
  profId_unaMsAcmStreamDevice_locateHeader: unsigned;
  profId_unaMsAcmCodec_insideCodec: unsigned;
  profId_unaWaveExclusiveMixer_pump: unsigned;
{$ENDIF UNA_PROFILE }

const
  c_unaRiffFileType_unknown	= 0;
  c_unaRiffFileType_riff	= 1;
{$IFDEF VC_LIC_PUBLIC }
{$ELSE }
  c_unaRiffFileType_mpeg	= 2;
{$ENDIF VC_LIC_PUBLIC }

type

  {*
	ACM Details enumeration.
  }
  tunaAcmDetailsType = (
    uadtUnused,
    uadtFilterDetails,
    uadtFormatDetails
  );

  {*
	ACM Details record.
  }
  punaAcmDetails = ^unaAcmDetails;
  unaAcmDetails = record
    r_type: tunaAcmDetailsType;
    case tunaAcmDetailsType of
      uadtUnused: (r_unused: uint);
      uadtFilterDetails: (
	r_filterDetails: ACMFILTERDETAILS;
      );
      uadtFormatDetails: (
	r_formatDetails: ACMFORMATDETAILS;
      );
  end;


  //
  unaMsAcmDriver = class;
  unaMsAcmObjectTag = class;


  {*
    This base class is designed to store an ACM object, such as format or filter.
  }
  unaMsAcmObject = class(unaObject)
  private
    f_driver: unaMsAcmDriver;
    f_details: unaAcmDetails;
    f_tag: unaMsAcmObjectTag;
  protected
    procedure deleteDetails(); virtual;
  public
    constructor create(); overload; virtual;
    constructor create(tag: unaMsAcmObjectTag); overload;
    procedure BeforeDestruction(); override;
    //
    {*
      Returns details stored in this object.
    }
    function getDetails(): punaAcmDetails;
    //
    property tag: unaMsAcmObjectTag read f_tag;
  end;


  //
  // -- unaMsAcmFilter --
  //
  {*
    This class stores information about the given MS ACM filter.
  }
  unaMsAcmFilter = class(unaMsAcmObject)
  private
  public
    constructor create(); overload; override;
    constructor create(tag: unaMsAcmObjectTag; details: pACMFILTERDETAILS); overload;
  end;


  //
  // -- unaMsAcmFormat --
  //
  {*
    This class stores information about the given MS ACM format.
  }
  unaMsAcmFormat = class(unaMsAcmObject)
  public
    constructor create(); overload; override;
    constructor create(tag: unaMsAcmObjectTag; details: pACMFORMATDETAILS); overload;
    {*
	Brings up UI dialog with format enumeration.
    }
    function formatChoose(bufW: pACMFORMATCHOOSEW; const title: wString = ''): MMRESULT;
  end;


  //
  // -- unaMsAcmObjectTag --
  //
  {*
    This base class is designed to store the information about an ACM object tag, such as format tag or filter tag.
  }
  unaMsAcmObjectTag = class(unaObject)
  private
    f_driver: unaMsAcmDriver;
  public
    constructor create(driver: unaMsAcmDriver); overload;
  end;


  //
  // -- unaMsAcmFilterTag --
  //
  {*
    This class stores information about an ACM filter tag.
  }
  unaMsAcmFilterTag = class(unaMsAcmObjectTag)
  private
    f_tag: ACMFILTERTAGDETAILS;
  public
    constructor create(driver: unaMsAcmDriver; tag: pACMFILTERTAGDETAILS); overload;
    //
    property tag: ACMFILTERTAGDETAILS read f_tag;
  end;


  //
  // -- unaMsAcmFormatTag --
  //
  {*
    This class stores information about an ACM format tag.
  }
  unaMsAcmFormatTag = class(unaMsAcmObjectTag)
  private
    f_tag: ACMFORMATTAGDETAILS;
  public
    constructor create(driver: unaMsAcmDriver; tag: pACMFORMATTAGDETAILS); overload;
    //
    property tag: ACMFORMATTAGDETAILS read f_tag;
  end;


  //
  // -- unaMsAcmDriver --
  //

  unaMsAcm = class;
  unaWaveDevice = class;

  {*
    List of installed drivers is maintained by unaMsAcm class, so usually there is no need to create/destroy the driver class explicitly.
    Use the unaMsAcm.getDriver() method instead.

    Driver has lists of associated wave formats and filters.
    You should explicitly call enumFilters() or enumFormats() to enumerate the filters and formats supported by driver. Driver will be opened for enumeration purposes.
    Explicitly opening the driver by calling the open() method ensures the driver handle will be valid until class is destroyed, or method close() is called.

    Use getDetails() method to retrieve pointer on ACMDRIVERDETAILSW structure. You should treat this structure as read-only.
  }
  unaMsAcmDriver = class(unaObject)
  private
    f_details: ACMDRIVERDETAILSW;
    f_detailsValid: bool;
    //
    f_id: HACMDRIVERID;
    //
    f_isInstallable: bool;
    f_libName: wString;
    f_refCount: int;
    //
    f_handle: HACMDRIVER;
    f_support: unsigned;
    f_maxWaveFormatSize: unsigned;
    f_enumFormatsFlag: uint;
    //
    f_formatWasEnum: bool;
    f_formatLastEnumFlags: uint;
    f_formatLastEnumWave: WAVEFORMATEX;
    f_formatLastEnumTagsOnly: bool;
    //
    f_filters: unaObjectList;
    f_filterTags: unaObjectList;
    f_formats: unaObjectList;
    f_formatTags: unaObjectList;
    f_acm: unaMsAcm;
    //
    procedure addFilter(tag: unaMsAcmObjectTag; pafd: pACMFILTERDETAILS);
    procedure addFormat(tag: unaMsAcmObjectTag; pafd: pACMFORMATDETAILS);
    procedure fillDetails();
  protected
    function isMyLib(const libName: wString): bool;
    function refInc(delta: int): int;
  public
    {*
      Initializes the instance of MS ACM driver object. id parameters specifies the ID of driver to use.
    }
    constructor create(acm: unaMsAcm; id: HACMDRIVERID; support: unsigned; const libName: wString = '');
    destructor Destroy(); override;
    //
    procedure AfterConstruction(); override;
    procedure BeforeDestruction(); override;
    // -- enum --
    {*
      Enumerates waveform-audio filters available from the ACM driver.
      Enumerated filters will be stored in the filters list. You can access them using getFilter() method.
    }
    function enumFilters(flags: uint = 0): MMRESULT;
    {*
      Enumerates waveform-audio formats available from the ACM driver.
      You can specify any combination of the following values for flags parameter:
      @unorderedList(
	@itemSpacing Compact
		@item (ACM_FORMATENUMF_HARDWARE - The enumerator should only enumerate formats that are supported as native input or output formats on one or more of the installed waveform-audio devices)
		@item (ACM_FORMATENUMF_INPUT - Enumerator should enumerate only formats that are supported for input (recording))
		@item (ACM_FORMATENUMF_NCHANNELS - The nChannels member of the WAVEFORMATEX structure pointed to by the pwfx parameter is valid. The enumerator will enumerate only a format that conforms to this attribute)
		@item (ACM_FORMATENUMF_NSAMPLESPERSEC - The nSamplesPerSec member of the WAVEFORMATEX structure pointed to by the pwfx parameter is valid. The enumerator will enumerate only a format that conforms to this attribute)
		@item (ACM_FORMATENUMF_OUTPUT - Enumerator should enumerate only formats that are supported for output (playback))
		@item (ACM_FORMATENUMF_WBITSPERSAMPLE - The wBitsPerSample member of the WAVEFORMATEX structure pointed to by the pwfx parameter is valid. The enumerator will enumerate only a format that conforms to this attribute)
		@item (ACM_FORMATENUMF_WFORMATTAG - This is default flag, and you should use it in most cases)
      )
      Enumerated formats will be stored in the formats list. You can access them using getFormat() method.
    }
    function enumFormats(flags: uint = 0; force: bool = false; pwfx: pWAVEFORMATEX = nil; tagsOnly: bool = false): MMRESULT;
    // -- handle --
    {*
      Opens the ACM driver.
      Installabe drivers need not to be opened.

      @return MMSYSERR_NOERROR if successfull.
    }
    function open(): MMRESULT;
    {*
      Closes a previously opened ACM driver instance.

      @return MMSYSERR_NOERROR if successfull.
    }
    function close(): MMRESULT;
    {*
      Returns true if driver was successfully opened or false otherwise.

      @return True if driver is opened.
    }
    function isOpen(): bool;
    {*
      Returns driver handle returned by acmDriverOpen() function
    }
    function getHandle(): HACMDRIVER;
    {*
      Sends a message to installed or opened driver.
    }
    function sendDriverMessage(msg: UINT; lParam1: LongInt; lParam2: Longint = 0): Longint;
    //
    {*
      Returns driver details.
    }
    function getDetails(): pACMDRIVERDETAILSW;
    {*
      Returns true if driver is enabled.
    }
    function isEnabled(): bool;
    {*
      Returns ACM priority of the driver.
    }
    function getPriority(): unsigned;
    {*
      Sets ACM priority of the driver.
    }
    procedure setPriority(value: unsigned);
    {*
      Enables of disables the driver.
    }
    procedure setEnabled(value: bool);
    // -- filters and formats --
    {*
      Returns number of formats stored in format list.
    }
    function getFormatCount(): unsigned;
    function getFormatTagCount(): unsigned;
    {*
      Returns number of filters stored in filter list.
    }
    function getFilterCount(): unsigned;
    {*
      Returns wave format object by its index in format list.
    }
    function getFormat(index: unsigned): unaMsAcmFormat;
    function getFormatTag(index: unsigned): unaMsAcmFormatTag;
    {*
      Returns wave filter object by its index in filter list.
    }
    function getFilter(index: unsigned): unaMsAcmFilter;
    // -- helping functions --
    {*
      Displays a custom About dialog box from an ACM driver.
      If the driver does not support a custom About dialog box, MMSYSERR_NOTSUPPORTED will be returned.
    }
    function about(wnd: HWND): MMRESULT;
    {*
      Queries the ACM driver to suggest a destination format for the supplied source format.
      srcFormat is a WAVEFORMATEX structure that identifies the source format for which a destination format will be suggested by the driver.
      dstFormat is a WAVEFORMATEX structure that will receive the suggested destination format for the srcFormat format. Depending on the flags parameter, some members of the structure pointed to by dstFormat may require initialization.
      The following values are defined for flags parameter:
	@unorderedList(
     		@itemSpacing Compact
		@item (ACM_FORMATSUGGESTF_NCHANNELS - The nChannels member of the structure pointed to by dstFormat is valid. The ACM will query the driver if it can suggest a destination format matching nChannels or fail)
		@item (ACM_FORMATSUGGESTF_NSAMPLESPERSEC - The nSamplesPerSec member of the structure pointed to by dstFormat is valid. The ACM will query acceptable the driver if it can suggest a destination format matching nSamplesPerSec or fail)
		@item (ACM_FORMATSUGGESTF_WBITSPERSAMPLE - The wBitsPerSample member of the structure pointed to by dstFormat is valid. The ACM will query acceptable the driver if it can suggest a destination format matching wBitsPerSample or fail)
		@item (ACM_FORMATSUGGESTF_WFORMATTAG - The wFormatTag member of the structure pointed to by dstFormat is valid. The ACM will query the driver if it can suggest a destination format matching wFormatTag or fail)
      )

      @Returns MMSYSERR_NOERROR if successful or an error code otherwise.
    }
    function suggestCodecFormat(srcFormat: pWAVEFORMATEX; dstFormat: pWAVEFORMATEX; flags: uint): MMRESULT;
    // -- other --
    {*
      Calls the master acm class to fill the given ACMFORMATDETAILS structure.
    }
    function preparePafd(var pafd: ACMFORMATDETAILS; tag: unsigned = 0; index: unsigned = 0): bool;
    {*
      Retrieves format details and fills the PCM sampling parameters of given wave device.
    }
    function assignFormat(tag: unsigned; index: unsigned; device: unaWaveDevice): bool;
    // -- properties --
    {*
      id of the driver.
    }
    property id: HACMDRIVERID read f_id;
    {*
      unaMsAcm class instance.
    }
    property acm: unaMsAcm read f_acm;
    {*
      Read-only property which indicates whether the driver was created as installable.
    }
    property isInstallable: bool read f_isInstallable;
  end;


  //
  // -- unaMsAcm --
  //
  {*
    This class holds a list of drivers installed on the system.
    Driver usually corresponds to one specific audio format and may contain converters, codecs and filters.
    You should explicitly call enumDrivers() method to enumerate installed drivers.

    Every installed driver has unique manufacturer and product identifiers (MID and PID).
    You can use these identifiers to locate specific driver.
    Use getDriver() method to retrieve driver by index or MID/PID pair.
  }
  unaMsAcm = class(unaObject)
  private
    f_version: unsigned;
    f_drivers: unaObjectList;
    //
    function getAcmCount(index: integer): unsigned;
  protected
    {*
      Adds driver to the list of drivers.
    }
    procedure addEnumedDriver(id: HACMDRIVERID; support: unsigned); virtual;
  public
    {*
      Allocates internal structures needed for class instance.
    }
    constructor create();
    destructor Destroy(); override;
    //
    {*
      Enumerates installed ACM drivers.
      The following values are defined for flags parameter:
	@unorderedList(
	 @itemSpacing Compact
		@item (ACM_DRIVERENUMF_DISABLED - Disabled ACM drivers should be included in the enumeration)
		@item (ACM_DRIVERENUMF_NOLOCAL - Only global drivers should be included in the enumeration)
      )
      Enumerated drivers are stored in driver list. You can access them using the getDriver() method.
    }
    procedure enumDrivers(flags: uint = 0);
    {*
      Searches the list of drivers for driver with specified mid and pid values.
    }
    function getDriver(mid, pid: unsigned): unaMsAcmDriver; overload;
    {*
      Returns driver from the list of drivers. Driver is specified by the index in the list (starting from 0).
    }
    function getDriver(index: unsigned): unaMsAcmDriver; overload;
    {*
      Returns driver from the list of drivers. Driver is specified by the format tag supported by driver.
    }
    function getDriverByFormatTag(formatTag: unsigned): unaMsAcmDriver;
    {*
      Returns number of drivers enumerated by enumDrivers() method.
    }
    function getDriverCount(): unsigned;
    {*
      Opens installable ACM driver.
    }
    function openDriver(const driverLibrary: wString): unaMsAcmDriver;
    {*
      Closes installable ACM driver opened previously with openDriver();
    }
    procedure closeDriver(driver: unaMsAcmDriver);
    //
    {*
      Allocates given ACMFORMATDETAILS structure.
    }
    function preparePafd(var pafd: ACMFORMATDETAILS; tag: unsigned = 0; index: unsigned = 0; driver: unsigned = 0): bool;
    //
    {*
      Version of ACM.
    }
    property version: unsigned read f_version;
    //
    {*
      Total number of enabled global ACM drivers (of all support types) in the system.
    }
    property countDrivers   : unsigned index ACM_METRIC_COUNT_DRIVERS    read getACMCount;
    {*
      Number of global ACM compressor or decompressor drivers in the system.
    }
    property countCodecs    : unsigned index ACM_METRIC_COUNT_CODECS     read getACMCount;
    {*
      Number of global ACM converter drivers in the system.
    }
    property countConverters: unsigned index ACM_METRIC_COUNT_CONVERTERS read getACMCount;
    {*
      Number of global ACM filter drivers in the system.
    }
    property countFilters   : unsigned index ACM_METRIC_COUNT_FILTERS    read getACMCount;
    {*
      Number of global disabled ACM drivers (of all support types) in the system.
    }
    property countDisabled  : unsigned index ACM_METRIC_COUNT_DISABLED   read getACMCount;
    {*
      Number of global ACM hardware drivers in the system.
    }
    property countHardware  : unsigned index ACM_METRIC_COUNT_HARDWARE   read getACMCount;
    {*
      Total number of enabled local ACM drivers (of all support types) for the calling task.
    }
    property countLocalDrivers   : unsigned index ACM_METRIC_COUNT_LOCAL_DRIVERS    read getACMCount;
    {*
      Number of local ACM compressor drivers, ACM decompressor drivers, or both for the calling task.
    }
    property countLocalCodecs    : unsigned index ACM_METRIC_COUNT_LOCAL_CODECS     read getACMCount;
    {*
      Number of local ACM converter drivers for the calling task.
    }
    property countLocalConverters: unsigned index ACM_METRIC_COUNT_LOCAL_CONVERTERS read getACMCount;
    {*
      Number of local ACM filter drivers for the calling task.
    }
    property countLocalFilters   : unsigned index ACM_METRIC_COUNT_LOCAL_FILTERS    read getACMCount;
    {*
      Total number of local disabled ACM drivers, of all support types, for the calling task.
    }
    property countLocalDisabled  : unsigned index ACM_METRIC_COUNT_LOCAL_DISABLED   read getACMCount;
  end;


  //
  unaMsAcmStreamDevice = class;

  //
  // -- unaMsAcmStreamHeader --
  //
  {*
    Base class for storing the wave and stream headers of wave and ACM devices.
  }
  unaMsAcmDeviceHeader = class(unaObject)
  private
    f_device: unaMsAcmStreamDevice;
{$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
{$ELSE }
    f_num: unsigned;
{$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
    f_needRePrepare: bool;
    f_isFree: bool;
    //f_gate: unaInProcessGate;
  protected
    {*
      Returns status of header. Descendant classes must override this method.
    }
    function getStatus(index: integer): bool; virtual; abstract;
    {*
      Sets status of header. Descendant classes must override this method.
    }
    procedure setStatus(index: integer; value: bool); virtual; abstract;
    //
    {*
	Prepares the header before first usage. This class calls prepareHeader() method of device to do this.
    }
    function prepare(): MMRESULT; virtual;
    {*
	Unprepares the header before first usage. This class calls unprepareHeader() method of device to do this.
    }
    function unprepare(): MMRESULT; virtual;
    {*
	Prepares the header after it was used once or more.
    }
    procedure rePrepare(); virtual;
    //
    {*
      	Returns true if header contains data what was produced or used by device and can be changed or re-used. Descendant classes must override this method.
    }
    function isDoneHeader(): bool; virtual; abstract;
    function isInQueue(): bool; virtual; abstract;
    //
    function enter(timeout: tTimeout): bool;
    procedure leave();
  public
    {*
      Creates device buffer header. This buffer is used to pass data to and from device.
    }
    constructor create(device: unaMsAcmStreamDevice);
    procedure AfterConstruction(); override;
    procedure BeforeDestruction(); override;
    //
    property isFree: bool read f_isFree write f_isFree;
  end;


  {*
      This event is used to inform the class owner about new data when it becomes available.
      It should be used only with classes which produces the data (like unaWaveInDevice or unaMsAcmCodec).
  }
  unaWaveDataEvent = procedure (sender: tObject; data: pointer; size: Cardinal) of object;

  {*
	Fired when switching from silence to voice and back.
  }
  unaWaveOnThresholdEvent = procedure (sender: tObject; var passThrough: bool) of object;

  {*
  	Returns external provider format
  }
  unaWaveGetProviderFormatEvent = procedure (var f: PWAVEFORMATEXTENSIBLE) of object;


  {*
	Voice Activity Detection (VAD) methods
  }
  unaWaveInSDMethods = 
(
//no silence detection
	unasdm_none, 
//"old" method, which uses minVolumeLevel and minActiveTime
	unasdm_VC,
//uses DSP library to filter silence
	unasdm_DSP, 
//"new" 3GPP method (recommended)
	unasdm_3GPPVAD1
);


  {$IFDEF UNA_VC_ACMCLASSES_USE_DSP }
  //
  unaDspSignalData 	= array[byte] of pdspl_float;
  unaDspSignalDataSize	= array[byte] of unsigned;
  //
  {$ENDIF UNA_VC_ACMCLASSES_USE_DSP }

  //
  // -- unaMsAcmStreamDevice --
  //
  {*
    This is abstract class used as a base for classes dealing with audio streams (codecs, waveIn and waveOut, mixers).

    Before opening stream device you should specify source and destination formats of audio streams device will work with.
    Method setFormat() will be called to set up source and destination format structures. You can access these structures later using the srcFormat and dstFormat properties.
    They are pointers on WAVEFORMATEX and should be treated as read-only data. Destructor takes care about releasing these structures.

    All stream processing is done chunk by chunk. Chunk is the minimal amount of data which can be processed once in a time.
    Chunk size is calculated automatically, and it will be enough to hold about 1/10 of second of audio. Use chunkSize property to examine current size of chunk.

    Since processing the audio stream could take some time, unaMsAcmStreamDevice has build-in mechanism which prevents stream overloading.
    Use the checkOverload property to enable or disable this mechanism. numOverload property specifies maximum number of unprocessed chunks in output or input stream.
    When actual number reaches this value, all new chunks will be discarded, until there will be enough space in the stream to put new chunk of data.

    inBytes and outBytes properties holds the amount of audio data written to and read from device.
  }
  unaMsAcmStreamDevice = class(unaThread)
  private
    f_handle: unsigned;
    f_openDone: bool;
    //
    f_inBytes: int64;
    f_outBytes: int64;
    f_skipTotal: int64;
    f_closing: bool;
    f_flushing: bool;
    f_realtime: bool;
    f_chunkSize: unsigned;
    f_dstChunkSize: unsigned;
    f_chunkPerSecond: unsigned;
    f_flushBeforeClose: bool;
    //
    f_srcFormatInfo: string;
    f_dstFormatInfo: string;
    //
    f_inOverCN: unsigned;	// in chunks (0 - do not check)
    f_outOverCN: unsigned;	// in chunks (0 - do not check)
    f_inOverSize: unsigned;	// in bytes
    f_outOverSize: unsigned;	// in bytes
    f_inOverloadTotal: int64;		// total amount of in-data skipped due to overload
    f_outOverloadTotal: int64;		// total amount of out-data skipped due to overload
    f_careInStreamDestroy: bool;
    f_careOutStreamDestroy: bool;
    f_inStreamIsunaMemoryStream: bool;
    f_outStreamIsunaMemoryStream: bool;
    //
    f_waitInterval: unsigned;
    //
    f_savedCV: bool;	// this is used by some devices when they change CV value
    f_calcVolume: bool;
{$IFDEF VCX_DEMO }
    f_headersServed: int64;
{$ENDIF VCX_DEMO }
    f_volume: array[byte] of unsigned;		// up to 256 channels
    f_setVolume: array[byte] of unsigned;	// up to 256 channels
    f_prevVolume: array[byte] of unsigned;	// up to 256 channels
    f_unVolume: array[byte] of unsigned;	// up to 256 channels
    f_needVolumeAdjust: bool;
    //
    f_onDA: unaWaveDataEvent;
    //
    {$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
    f_headers: array[0..c_max_wave_headers - 1] of pointer;		//
    f_nextHdr: int;
    {$ELSE }
    f_headers: unaObjectList;
    f_lastHeaderNum: int;
    f_lastDoneHeaderNum: unsigned;
    {$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
    f_inProgress: unsigned;	// number of headers in queue (our version)
    //
    f_srcFormatExt: PWAVEFORMATEXTENSIBLE;
    f_dstFormatExt: PWAVEFORMATEXTENSIBLE;
    //
    f_openCloseEvent: unaEvent;
    //f_dataInEvent: unaEvent;
    //f_dataOutEvent: unaEvent;
    //f_gate: unaInProcessGate;
    f_deviceEvent: unaEvent;
    //
    f_inStream: unaAbstractStream;
    f_outStream: unaAbstractStream;
    f_consumers: unaList;
    f_notifyDevices: unaList;
    //
    // -- silence detection
    f_minAT: unsigned;
    f_minVL: unsigned;
    f_timeActive: unsigned;
    //
    f_3gppvad1: pvadState;
    f_3gppvad1_buf: array[0..una3GPPVAD.FRAME_LEN - 1] of una3GPPVAD.Word16;
    f_vad_prev: bool;
    f_vad_cooldown: int;
    //
    f_isSilence: bool;
    f_isSilencePrev: bool;
    f_isSilenceFirstTime: bool;
    f_passThrough: bool;
    //
    {$IFDEF UNA_VC_ACMCLASSES_USE_DSP }
    f_dspl: unaDspDLibRoot;
    f_dsplAutoLD: unaDSPLibAutomat;
    f_dsplAutoND: unaDSPLibAutomat;
    f_dsplObjLD: dspl_handle;
    f_dsplObjND: dspl_handle;
    //
    f_dsplOutBufLD: unaDspSignalData;
    f_dsplOutBufND: unaDspSignalData;
    f_dsplOutBufLDSize: unaDspSignalDataSize;
    f_dsplOutBufNDSize: unaDspSignalDataSize;
    f_outBufValid: bool;
    {$ENDIF UNA_VC_ACMCLASSES_USE_DSP }
    //
    f_sdm: unaWaveInSDMethods;
    //
    f_channelMixMask: int;
    f_channelMixBuf, f_channelMixBufEx: pointer;
    f_channelMixBufSize: int;
    //
    f_channelConsumeMask: int;
    f_channelConsumeBuf, f_channelConsumeBufEx: pointer;
    f_channelConsumeBufSize: int;
    //
    f_onThreshold: unaWaveOnThresholdEvent;
    //
    f_onGetProviderFormat: unaWaveGetProviderFormatEvent;
    //
    procedure setMinVL(value: unsigned);
    {*
	Calls beforeNewChunk() to check for silence, volume adjust, etc.
	If no silence (or silence detection is not enabled):
	  2) passes chunk to consumers (if any)
	  3) writes chunk into internal buffer (if assigned)

	internalWrite() is called when:
	  waveCodec - produces new chunk
	  waveIn - produces new chunk
	  waveRiff - reads new chunk
	  waveMixer - produces new chunk
	  waveResampler - produces new chunk
    }
    function internalWrite(buf: pointer; size: unsigned; formatExt: PWAVEFORMATEXTENSIBLE): unsigned;
    {*
	Checks if channelConsumeMask is not -1 and mixes channels as necessary
    }
    procedure internalConsumeData(var buf: pointer; var size: unsigned);
    {*
	Reads size bytes from internal buffer into buf.
	Calls beforeNewChunk() to check for silence, volume adjust, etc.
	Returns number of bytes actually read (could be 0 if no data, or silence, etc).

	internalRead() is called when:
	  waveCodec - wants to read new chunk from input buffer
	  waveOut - wants to read new chunk from input buffer
	  waveRiff - wants to read new chunk from input buffer
	  waveResampler - wants to read new chunk from input buffer
    }
    function internalRead(buf: pointer; size: unsigned; formatExt: PWAVEFORMATEXTENSIBLE): unsigned;
    //
    procedure destroyStream(isInStream: bool);
    procedure notifyRemove();
    procedure addNotification(device: unaMsAcmStreamDevice);
    procedure removeNotification(device: unaMsAcmStreamDevice);
    //
    function adjustVolume100(buf: pointer; size: unsigned; format: PWAVEFORMATEXTENSIBLE): unsigned;
    //
    {$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
    {$ELSE }
    function getNextHeaderNum(): int;
    function adjustLastDoneHeaderNum(num: unsigned): bool;
    function locateHeaderTry(header: unaMsAcmDeviceHeader; locateUnused: bool = false; locateNotInQuery: bool = false): bool;
    function locateHeader(locateUnused: bool = false; locateNotInQuery: bool = false): unaMsAcmDeviceHeader;
    {$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
    procedure clearHeaders();
    procedure setCalcVolume(const Value: bool);
    function formatChoose(var format: pWAVEFORMATEX; const title: wString; style: unsigned; enumFlag: unsigned; enumFormat: pWAVEFORMATEX = nil): MMRESULT;
    //
    procedure setInOverCN(value: unsigned);
    procedure setOutOverCN(value: unsigned);
    {*
	Checks silence. Returns True if chunk is not silent (or silence detection is not enabled).
    }
    function checkSilence(data: pointer; len: unsigned; formatExt: PWAVEFORMATEXTENSIBLE): bool;
  protected
    {*
      	Sets the source or destination PCM format for device.
      	Format is given in string representation using base64 encoding.
    }
    function setFormat(isSrc: bool; const format: aString): bool; overload;
    {*
      	Sets the source or destination PCM format for device.
      	Format is given in string representation using base64 encoding.
    }
    function setFormatExt(isSrc: bool; const formatExt: string): bool; overload;
    {*
      	Sets the source or destination PCM format for device. Format is given as WAVEFORMATEX structure.
    }
    function setFormat(isSrc: bool; format: pWAVEFORMATEX): bool; overload; virtual;
    function setFormatExt(isSrc: bool; formatExt: PWAVEFORMATEXTENSIBLE): bool; overload; virtual;
    //
    {*
      	Opens device. This method is usually overrided by descendant classes to perform the actual job.
    }
    function doOpen(flags: uint): MMRESULT; virtual;
    function open2(query: bool = false; timeout: tTimeout = 10001; flags: uint = 0; startDevice: bool = true): MMRESULT; virtual;
    {*
	Closes device. This method is usually overrided by descendant classes to perform the actual job.
    }
    function doClose(timeout: tTimeout = 1): MMRESULT; virtual;
    {*
	Uses mmGetErrorCodeText2() to produce the error message.
	Other devices could have own doGetErrorText() implementation.
    }
    function doGetErrorText(errorCode: MMRESULT): string; virtual;
    {}
    function doGetPosition(): int64; virtual;
    {*
	Adjusts volume as needed (if calcVolume is True).
	Calculates f_volume[] values (if calcVolume is True) for PCM data.
	Returns the result of checkSilence() routine.
    }
    function beforeNewChunk(data: pointer; size: unsigned; formatExt: PWAVEFORMATEXTENSIBLE): bool; virtual;
    //
    {*
	Prepares the buffer header before first use. Descendant classes must override this method.
    }
    function prepareHeader(header: pointer): MMRESULT; virtual; abstract;
    {*
	Unprepares the buffer header after last use. Descendant classes must override this method.
    }
    function unprepareHeader(header: pointer): MMRESULT; virtual; abstract;
    //
    {$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
    procedure removeHeader(var header: pointer); virtual; abstract;
    {$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
    //
    {*
	Called after the device was opened. Descendant classes may override this method to perform additional actions required by hardware/software.
    }
    function afterOpen(): MMRESULT; virtual;
    procedure afterClose(closeResult: MMRESULT); virtual;
    function close2(timeout: tTimeout = 10011): MMRESULT; virtual;
    //
    procedure startIn(); override;
    procedure startOut(); override;
    //
    function flush2(waitForComplete: bool = true): bool; virtual;
    function doWrite(buf: pointer; size: unsigned): unsigned; virtual;
    //
    function getProviderFormat(): PWAVEFORMATEXTENSIBLE; virtual;
    //
    function getMasterIsSrc2(): bool; virtual; abstract;
    function formatChooseDef2(var format: pWAVEFORMATEX): MMRESULT; dynamic;
    //
    procedure setDspProperty(isLD: bool; propID: unsigned; value: int); overload;
    procedure setDspProperty(isLD: bool; propID: unsigned; const value: float); overload;
    function getDspProperty(isLD: bool; propID: unsigned; def: int = 0): int; overload;
    function getDspProperty(isLD: bool; propID: unsigned; const def: float = 0.0): float; overload;
    //
    procedure setRealTime(value: bool); virtual;
    //
    // -- properties --
    //
    {*
	Size in bytes of internal buffer used to handle the audio stream data.
    }
    property dstChunkSize: unsigned read f_dstChunkSize;
    {*
	WinAPI device handle (if applicable)
    }
    property handle: unsigned read f_handle;
  public
    {*
	Initializates class instance.
    }
    constructor create(createInStream: bool = true; createOutStream: bool = true; inOverNum: unsigned = 0; outOverNum: unsigned = 0; calcVolume: bool = false);
    destructor Destroy(); override;
    procedure AfterConstruction(); override;
    procedure BeforeDestruction(); override;
    {*
	Opens the device.
    }
    function open(query: bool = false; timeout: tTimeout = 10002; flags: uint = 0; startDevice: bool = true): MMRESULT;
    {*
	Closes the device.
    }
    function close(timeout: tTimeout = 10012): MMRESULT;
    {*
	Returns true if device was opened successfully.
    }
    function isOpen(): bool;
    //
    {*
	Returns current volume level for open device.
	Volume range is from 0 to 32768.

	@param channel Channel number to read volume of.
	If default value is specifed ($FFFFFFFF), returns median volume of all channels
    }
    function getVolume(channel: unsigned = $FFFFFFFF): unsigned;
    {*
	Returns unchanged volume level for open device.
	Volume range is from 0 to 32768.

	@param channel Channel number to read volume of.
	If default value is specifed ($FFFFFFFF), returns median volume of all channels
    }
    function getUnVolume(channel: unsigned = $FFFFFFFF): unsigned;
    {*
	Returns previous volume level for open device.

	@param channel Channel number to read volume of.
	If default value is specifed ($FFFFFFFF), returns median volume of all channels
    }
    function getPrevVolume(channel: unsigned = $FFFFFFFF): unsigned;
    {*
	Changes the volume of specified channel.

	@param volume 100 means no volume change (100%); 50 = 50%; 200 = 200% and so on.
	@param channel Default value of -1 means this volume will be applied on all channels.
    }
    procedure setVolume100(channel: int = -1; volume: unsigned = 100);
    //
    {*
	Use this method to check if you can read new data from device.
    }
    function okToRead(): bool;
    {*
	Returns current position in samples.
    }
    function getPosition(): int64;
    //
    {*
	Reads data from device.
	Returns size of actual returned data.
	Specify 0 as size parameter value when reading from ACM codec device.
    }
    function read(buf: pointer; size: unsigned = 0): unsigned;
    {*
	Sends data to device.
    }
    function write(buf: pointer; size: unsigned): unsigned;
    //
    function flush(waitForComplete: bool = true): bool;
    {*
	Returns number of bytes available to read from the device.
    }
    function getDataAvailable(isIn: bool): unsigned;
    {*
	Returns true if device is output device (playback or codec).
	Returns false if device is input device (recording).
    }
    function getMasterIsSrc(): bool;
    //
    {*
	Assigns input or output stream for device.
	You can specify nil as stream to disable the input/output.
	If you wish the device to destroy the stream in own destructor - specify true in careDestroy parameter.
    }
    function assignStream(isInStream: bool; stream: unaAbstractStream; careDestroy: bool = false): unaAbstractStream; overload;
    {*
	Assigns input or output stream for device.
	Stream will be created using the provided stream class.
	If you wish the device to destroy the stream in own destructor - specify true in careDestroy parameter.
    }
    function assignStream(streamClass: unaAbstractStreamClass; isInStream: bool; careDestroy: bool = true): unaAbstractStream; overload;
    {*
	Adds a new consumer for device output.
	All data produced by device will be passed to all consumers added by this method.
	If you wish to destroy the output stream leave the default true value for removeOutStream parameter.
	(Stream will be destroyed only if it was not a stream assigned by assignStream() with careDestroy = false).
    }
    function addConsumer(device: unaMsAcmStreamDevice; removeOutStream: bool = true): unsigned;
    {*
	Removes consumer from consumers list.
    }
    function removeConsumer(device: unaMsAcmStreamDevice): bool;
    //
    {*
	Default implementation of format choosing routine.
    }
    function formatChooseDef(var format: pWAVEFORMATEX): MMRESULT;
    {*
	Returns error message text corresponding to given errorCode parameter.
    }
    function getErrorText(errorCode: MMRESULT): string;
    {*
	Waits for data either in inStream or in outStream.
	Returns true if data is available, false if timeout has expired
    }
    function waitForData(waitForInData: bool; timeout: tTimeout; expectedDataSize: unsigned = 0): bool;
    //
    //
    {*
	Size in bytes of internal buffer used to handle the audio stream data.
    }
    property chunkSize: unsigned read f_chunkSize;
    {*
	Specifies number of chunks produced by component per second.
	Note, that not all components are working in real time, in which case this property has no meaning.
	Readonly property, change the global c_defChunksPerSecond variable if you wish to change this number.
    }
    property chunkPerSecond: unsigned read f_chunkPerSecond;
    {*
	Specifies whether volume level calculation should be performed.
	Set to true if planning to use silence detection when silenceDetectionMode is set to unasdm_VC.
    }
    property calcVolume: bool read f_calcVolume write setCalcVolume;
    //
    {*
	Number of bytes passed to device (as input). Playback and codec devices increase this value.
    }
    property inBytes: int64 read f_inBytes;
    {*
	Number of bytes produced by device (as output). Recording and codec devices increase this value.
    }
    property outBytes: int64 read f_outBytes;
    {*
	Returns source format for device.
    }
    property srcFormatExt: PWAVEFORMATEXTENSIBLE read f_srcFormatExt;
    {*
	Returns destination format for device.
    }
    property dstFormatExt: PWAVEFORMATEXTENSIBLE read f_dstFormatExt;
    //
    {*
	Returns string representation of source format.
    }
    property srcFormatInfo: string read f_srcFormatInfo;
    {*
	Returns string representation of destination wave format.
    }
    property dstFormatInfo: string read f_dstFormatInfo;
    //
    {*
	Data passed to device first is strored in inStream
    }
    property inStream: unaAbstractStream read f_inStream;
    {*
	Data produced by device first is stored in outStream
    }
    property outStream: unaAbstractStream read f_outStream;
    {*
	Number of chunks passed to Windows ACM or wave device and not yet processed.
    }
    property inProgress: unsigned read f_inProgress;
    //
    {*
    }
    property realTime: bool read f_realTime write setRealTime;
    {*
	Number of input chunks which could be queued
    }
    property overNumIn: unsigned read f_inOverCN write setInOverCN;
    {*
	Total amount of in-data skipped due to overload
    }
    property inOverloadTotal: int64 read f_inOverloadTotal;
    {*
	Number of output chunks which could be queued
    }
    property overNumOut: unsigned read f_outOverCN write setOutOverCN;
    {*
	Total amount of out-data skipped due to overload
    }
    property outOverloadTotal: int64 read f_outOverloadTotal;
    {*
	Specifies whether component will flush unfinished data before closing.
    }
    property flushBeforeClose: bool read f_flushBeforeClose write f_flushBeforeClose;
    {*
	Specifies the minimum value of volume level for silence detection.
	Has meaning only when silenceDetectionMode is set to unasdm_VC.

	Set this property to 0 to disable the volume detection feature.
    }
    property minVolumeLevel: unsigned read f_minVL write setMinVL;
    {*
	Specifies the minimum amount of time (in milliseconds) for silence detection to be active once activated.
	Has meaning only when silenceDetectionMode is set to unasdm_VC.
    }
    property minActiveTime: unsigned read f_minAT write f_minAT;
    {*
	True if components is currently not producing any audio chunks due to low signal level.
    }
    property isSilence: bool read f_isSilence;
    {*
	Specifies which method will be used to detect silence.
    }
    property silenceDetectionMode: unaWaveInSDMethods read f_sdm write f_sdm;
    {
	The channel(s) to pass to consumers. Default is -1 ($FFFFFFFF), means all channels.

	Each bit set to 1 means the channel will be passed to consumers.
	Least significant bit corresponds to channel #0.
	All channels are mixed into one (mono) channel, unless -1 is specified as mask.

	NOTE: for stereo, mask 3 and -1 are different.
	 3 means two channels will be mixed into one
	-1 means two channels will be passed as is

	If this filed is set to 0, no data will be passed to consumers.

	Consumers must be smart enough to receive only 1 channel even if data format has more channels.
    }
    property channelMixMask: int read f_channelMixMask write f_channelMixMask;
    {*
	Mix incoming channels into one. Default is -1 ($FFFFFFFF), means no mixing.

	Each bit set to 1 means the channel will mixed.
	Least significant bit corresponds to channel #0.
	All channels are mixed into one (mono) channel, unless -1 is specified as mask.

	NOTE: for stereo, mask 3 and -1 are different.
	 3 means two channels will be mixed into one
	-1 means two channels will be consumed as is

	If this filed is set to 0, no data will be consumed.
    }
    property channelConsumeMask: int read f_channelConsumeMask write f_channelConsumeMask;
    //
    //-- events --
    //
    {*
	This event is fired when current level of signal is crossing the "silence" mark.
    }
    property onThreshold: unaWaveOnThresholdEvent read f_onThreshold write f_onThreshold;
    {*
	This event is called when new data is available.
    }
    property onDataAvailable: unaWaveDataEvent read f_onDA write f_onDA;
    {*
	Returns format assigned to external provider.
    }
    property onGetProviderFormat: unaWaveGetProviderFormatEvent read f_onGetProviderFormat write f_onGetProviderFormat;
  end;


  //
  // -- unaMsAcmCodecHeader --
  //

  unaMsAcmCodec = class;

  {*
    This class stores the data used by MS ACM codec.
  }
  unaMsAcmCodecHeader = class(unaMsAcmDeviceHeader)
  private
    f_header: ACMSTREAMHEADER;
    f_drvHeader: ACMDRVSTREAMHEADER;
    //
    f_codec: unaMsAcmCodec;
  protected
    {*
	Used to return different statuses of header.
    }
    function getStatus(index: integer): bool; override;
    {*
      	Used to set different statuses of header.
    }
    procedure setStatus(index: integer; value: bool); override;
    //
    function isDoneHeader(): bool; override;
    function isInQueue(): bool; override;
    procedure rePrepare(); override;
  public
    {*
	Creates ACM codec header and allocates required buffers.
    }
    constructor create(codec: unaMsAcmCodec; srcSize: unsigned; dstSize: unsigned);
    destructor Destroy(); override;
    //
    {*
	Writes data to the source codec buffer.
    }
    procedure write(data: pointer; size: unsigned; offset: unsigned = 0);
    {*
	Reallocate source buffer.
    }
    procedure grow(newsize: unsigned);
    //
    {*
	Returns true if header is released by codec.
    }
    property isDone: bool index ACMSTREAMHEADER_STATUSF_DONE read getStatus write setStatus;
    {*
	Returns true if header is still in codec queue.
    }
    property inQueue: bool index ACMSTREAMHEADER_STATUSF_INQUEUE read getStatus write setStatus;
    {*
      	Returns true if header was prepared.
    }
    property isPrepared: bool index ACMSTREAMHEADER_STATUSF_PREPARED read getStatus write setStatus;
  end;


  // --  --
  unaAcmCodecDriverMode = (unacdm_acm, unacdm_installable, unacdm_internal, unacdm_openH323plugin);


  //
  // -- unaMsAcmCodec --
  //

  {*
    This class is wrapper over Windows Multimedia streams API. Create it specifying the driver you wish to use with the stream.
    You can get list of available drivers from unaMsAcm class instance.

    Codec usually takes source (input) stream, converts it into another wave format, and produces destination (output) stream.
    Before opening the codec you should specify source and destination formats using the setFormat() method.
    isSrc parameter is true for source format and false for destination. tag and index are specific for selected driver.

    For example, Microsoft PCM Converter driver has tag = 1 and index specifies sampling parameters.
    So, if you specify tag=1, index=1 as source and tag=1, index=9 as destination, codec will convert 8,000 kHz; 8 Bit; stereo PCM stream into 22,050 kHz; 8 Bit; stereo PCM stream.
    You can easily enumerate all formats supported by specific driver using the unaMsAcmDriver.enumFormats() method.

    After setting source and destination formats call the open() method to activate the codec.
    If you wish to check specified formats conversion is supported by codec, rather than opening it, specify true for query parameter.
    open() returns MMSYSERR_NOERR if codec was activated successfully. After that you need to feed the source stream using write() method, and periodically check destination stream, calling read() method.
    When you are finished with codec, destroy it or call the close() method.
  }
  unaMsAcmCodec = class(unaMsAcmStreamDevice)
  private
    f_driver: unaMsAcmDriver;
    f_driverLibrary: wString;
    f_driverMode: unaAcmCodecDriverMode;
    //
    f_oH323codec: una_openH323plugin;
    f_oH323codecOldIndex: int;
    //
    //f_async: bool;
    f_highPriority: bool;
    f_streamInstance: ACMDRVSTREAMINSTANCE;	// used by installable drivers
    //
    f_chunk: pointer;
    f_flags: uint;
    f_subSize: unsigned;
    f_subBuf: pointer;
    f_subBufSize: unsigned;
    //
    f_header: unaMsAcmCodecHeader;
    f_acmHeader: pACMSTREAMHEADER;
    //
    f_filterFormat: pWAVEFILTER;
    //
    function reset(timeout: tTimeout): MMRESULT;
    function getChunkSize(inSize: unsigned; out outSize: unsigned; flags: uint = ACM_STREAMSIZEF_SOURCE): MMRESULT;
    function streamConvert(header: unaMsAcmCodecHeader; flags: uint): MMRESULT;
    procedure setDriverLibrary(const value: wString);
    function getoH323pluginDesc(index: int): ppluginCodec_definition;
    procedure setDriver(value: unaMsAcmDriver);
  protected
    function execute(globalIndex: unsigned): int; override;
    //
    function processNextChunk(): bool;
    //
    function doOpen(flags: uint): MMRESULT; override;
    function doClose(timeout: tTimeout = 1): MMRESULT; override;
    function open2(query: bool = false; timeout: tTimeout = 10003; flags: uint = 0; startDevice: bool = true): MMRESULT; override;
    {*
	//
    }
    function doWrite(buf: pointer; size: unsigned): unsigned; override;
    //
    function prepareHeader(header: pointer): MMRESULT; override;
    function unprepareHeader(header: pointer): MMRESULT; override;
    {$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
    procedure removeHeader(var header: pointer); override;
    {$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
    {*
      Returns true.
    }
    function getMasterIsSrc2(): bool; override;
  public
    {*
      Creates ACM codec class instance.
    }
    constructor create(driver: unaMsAcmDriver; realtime: bool = false; overNum: unsigned = 0; highPriority: bool = false; driverMode: unaAcmCodecDriverMode = unacdm_acm);
    //
    procedure BeforeDestruction(); override;
    //
    {*
	Sets the source or destination format for codec.
    }
    procedure setFormatIndex(isSrc: bool; tag, index: unsigned);
    {*
	Use this method when you do not know the exact format supported by the codec, but do know the driver, tag and index of the desired format.
    }
    procedure setFormatSuggest(isSrc: bool; desiredDriver: unaMsAcmDriver; tag, index: unsigned; flags: uint = ACM_FORMATSUGGESTF_NCHANNELS + ACM_FORMATSUGGESTF_NSAMPLESPERSEC + ACM_FORMATSUGGESTF_WBITSPERSAMPLE); overload;
    {*
	Use this method when you do know non-PCM parameters of source or dest stream.
    }
    function setFormatSuggest(isSrcPCM: bool; const format: WAVEFORMATEX): bool; overload;
    {*
	Use this method when you do know PCM parameters of source or dest stream.
    }
    function setPcmFormatSuggest(isSrcPCM: bool; samplesPerSec: unsigned = c_defSamplingSamplesPerSec; bitsPerSample: unsigned = c_defSamplingBitsPerSample; numChannels: unsigned = c_defSamplingNumChannels; formatTag: unsigned = 0): bool; overload;
    {*
	Use this method when you do know PCM parameters of source or dest stream.
    }
    function setPcmFormatSuggest(isSrcPCM: bool; pcmFormat: pWAVEFORMATEX; formatTag: unsigned): bool; overload;
    {*
	Returns the driver used to perform the codec job.
    }
    property driver: unaMsAcmDriver read f_driver write setDriver;
    {*
	Specifies library file (DLL) for a driver. Not used with ACM codecs, where you should specify driver directly instead.
    }
    property driverLibrary: wString read f_driverLibrary write setDriverLibrary;
    {*
	Since codec is input/output device, we need to have second chunk of data.
    }
    property dstChunkSize;
    {*
	Specifies driver mode: ACM, installable or internal.
    }
    property driverMode: unaAcmCodecDriverMode read f_driverMode write f_driverMode;
    {*
	H323 Codec description
    }
    property oH323codecDesc[index: int]: ppluginCodec_definition read getoH323pluginDesc;
    {*
	WinAPI ACM handle
    }
    property handle;
  end;


{$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
  //
  unaWaveHeader = pWAVEHDR;
{$ELSE }

  //
  // -- unaWaveHeader --
  //
  {*
    This class stores the wave data which will be send or received to/from Windows wave device.
  }
  unaWaveHeader = class(unaMsAcmDeviceHeader)
  private
    f_header: WAVEHDR;
  protected
    procedure rePrepare(); override;
    //
    function getStatus(index: int): bool; override;
    procedure setStatus(index: int; value: bool); override;
    //
    function isDoneHeader(): bool; override;
    function isInQueue(): bool; override;
  public
    {*
      Creates wave buffer header and allocates required buffers.
    }
    constructor create(device: unaWaveDevice; size: unsigned; data: pointer = nil);
    destructor Destroy(); override;
    //
    function setData(data: pointer; size: unsigned; offset: int = 0): int;
    //
    {*
      Returns true if header is released by device.
    }
    property isDone: bool index WHDR_DONE read getStatus write setStatus;
    {*
      Returns true if header is still in device queue.
    }
    property inQueue: bool index WHDR_INQUEUE read getStatus write setStatus;
    {*
      Returns true if header was prepared.
    }
    property isPrepared: bool index WHDR_PREPARED read getStatus write setStatus;
    {*
      Returns true if header is the beginning of the loop.
    }
    property isBeginLoop: bool index WHDR_BEGINLOOP read getStatus write setStatus;
    {*
      Returns true if header is the end of the loop.
    }
    property isEndLoop: bool index WHDR_ENDLOOP read getStatus write setStatus;
  end;

{$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }


  {*
	DS is not supported yet.
  }
  unaVCWaveEngine = (unavcwe_MME, unavcwe_ASIO, unavcwe_DS);


  //
  // -- unaWaveDevice --
  //
  {*
      This abstract class is used as base for unaWaveInDevice (recorder) and unaWaveOutDevice (playback) devices.

      Since both In and Out devices are working with PCM streams only, we can simplify the process of specifying wave formats.
      Instead of tag/index pair setSampling() method takes three parameters: samples per second, bits per sample and number of channels.
      Commonly used values for samples per second are 8,000; 11,025; 22,050 and 44,100. Bits per sample could be 8 or 16 or more.
      Number of channels is usually 1 (mono) or 2 (stereo).
  }
  unaWaveDevice = class(unaMsAcmStreamDevice)
  private
    f_deviceID: uint;
    f_noCaps: bool;
    //
    f_mapped: bool;
    f_direct: bool;
    f_handles: array[byte] of tHandle;
    f_handlesCnt: unsigned;
    f_handlesNonHdrCnt: unsigned;
    //
    f_waveEngine: unaVCWaveEngine;
    //
{$IFDEF UNA_VCACM_USE_ASIO }
    f_asioDriverList: unaAsioDriverList;
    f_asioDriver: unaAsioDriver;
    f_asioBP: unaAsioBufferProcessor;
    //
    f_ASIODriverIsShared: bool;
{$ENDIF UNA_VCACM_USE_ASIO }
    //
    f_sharedASIODevice: unaWaveDevice;
    f_ASIODuplex: bool;
    //
    procedure setWaveEngine(value: unaVCWaveEngine);
    procedure setDeviceId(value: uint);
    //
{$IFDEF DEBUG_LOG }
    function displayHeadersUsage(): bool;
{$ENDIF DEBUG_LOG }
  protected
    function addHeader(header: unaWaveHeader): MMRESULT; virtual; abstract;
    function onHeaderDone(header: unaWaveHeader; wakeUpByHeaderDone: bool): bool; virtual;
    {$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
    procedure removeHeader(var header: pointer); override;
    {$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
    //
    function execute(globalIndex: unsigned): int; override;
    {*

    }
    function open2(query: bool = false; timeout: tTimeout = 10004; flags: uint = 0; startDevice: bool = true): MMRESULT; override;
    {*
    }
    function close2(timeout: tTimeout = 10014): MMRESULT; override;
  public
    {*
	  @param mapped - The deviceID parameter specifies a waveform-audio device to be mapped to by the wave mapper.
	  @param direct - If this flag is specified, the ACM driver does not perform conversions on the audio data.
    }
    constructor create(deviceID: uint = WAVE_MAPPER; mapped: bool = false; direct: bool = false; isIn: bool = true; overNum: unsigned = 0);
    {*
    }
    procedure BeforeDestruction(); override;
    {*
	Since most wave devices supports PCM formats only it is handy to have this method.
    }
    function setSampling(samplesPerSec: unsigned = c_defSamplingSamplesPerSec; bitsPerSample: unsigned = c_defSamplingBitsPerSample; numChannels: unsigned = c_defSamplingNumChannels): bool; overload;
    {*
	Since most wave devices supports PCM formats only it is handy to have this method.
    }
    function setSampling(pcmFormat: pWAVEFORMATEX): bool; overload;
    {*
	Since most wave devices supports PCM formats only it is handy to have this method.
    }
    function setSampling(const pcmFormat: unaPCMFormat): bool; overload;
    {*
	Since most wave devices supports PCM formats only it is handy to have this method.
    }
    function setSamplingExt(isSrc: bool; format: PWAVEFORMATEXTENSIBLE): bool;
{$IFDEF UNA_VCACM_USE_ASIO }
    {*
	ASIO driver assigned for device.
    }
    function asioDriver(): unaAsioDriver;
{$ENDIF UNA_VCACM_USE_ASIO }
    {*
	Share ASIO driver with specified device.
	When ASIO is shared, no new ASIO driver will be initialized.

	@param device Wave device to share ASIO driver with. If nil, old share will be removed (if any).
    }
    procedure shareASIOwith(device: unaWaveDevice);
    //
    {*
	If this flag is specified, the ACM driver does not perform conversions on the audio data.
    }
    property direct: bool read f_direct write f_direct;
    {*
	The deviceID parameter specifies a waveform-audio device to be mapped to by the wave mapper.
    }
    property mapped: bool read f_mapped write f_mapped;
    {*
	Device Id.
    }
    property deviceId: uint read f_deviceId write setDeviceId;
    {*
	MME, ASIO or DS
    }
    property waveEngine: unaVCWaveEngine read f_waveEngine write setWaveEngine;
  end;


  //
  // -- unaWaveInDevice --
  //
  {*
    Use this class to record live audio.
    deviceID parameter used to construct instances of this class can be
    from 0 to unaWaveInDevice.getDeviceCount() - 1, or you can use WAVE_MAPPER value instead.

    After opening the device check periodically output stream by calling read() method,
    or use onDataAvailable() event to receive new data chunks.
  }
  unaWaveInDevice = class(unaWaveDevice)
  private
    f_caps: WAVEINCAPSW;
    //
    function feedHeader(header: unawaveHeader = nil; feedMore: bool = true): bool;
  protected
    procedure startIn(); override;
    procedure startOut(); override;
    //
    function doOpen(flags: uint): MMRESULT; override;
    function doClose(timeout: tTimeout = 1): MMRESULT; override;
    function doGetErrorText(errorCode: MMRESULT): string; override;
    function doGetPosition(): int64; override;
    //
    function afterOpen(): MMRESULT; override;
    //
    function prepareHeader(header: pointer): MMRESULT; override;
    function unprepareHeader(header: pointer): MMRESULT; override;
    function addHeader(header: unaWaveHeader): MMRESULT; override;
    //
    function onHeaderDone(header: unaWaveHeader; wakeUpByHeaderDone: bool): bool; override;
    {*
      Displays a format choose dialog. Reallocates (if necessary) given format.
    }
    function formatChooseDef2(var format: pWAVEFORMATEX): MMRESULT; override;
    {*
      Returns false.
    }
    function getMasterIsSrc2(): bool; override;
  public
    {*
	Creates wave recording device.
    }
    constructor create(deviceID: uint = WAVE_MAPPER; mapped: bool = false; direct: bool = true; overNum: unsigned = 0);
    {*
	MME only.

	@return device caps.
    }
    function getInCaps(): pWAVEINCAPSW;
    {*
	Displays format selection dialog.
    }
    function formatChoose(var format: pWAVEFORMATEX; const title: wString = ''; style: unsigned = ACMFORMATCHOOSE_STYLEF_INITTOWFXSTRUCT; enumFlag: unsigned = ACM_FORMATENUMF_HARDWARE + ACM_FORMATENUMF_INPUT; enumFormat: pWAVEFORMATEX = nil): MMRESULT;
    //
    {*
	MME only.

	@return device caps.
    }
    class function getCaps(deviceID: uint; var caps: WAVEINCAPSW): bool; overload;
    {*
	MME only.

	@return recording device count.
    }
    class function getDeviceCount(): unsigned;
    {*
	MME only.

	@return device error text.
    }
    class function getErrorText(errorCode: MMRESULT): string;
    {*
	WinAPI MME handle
    }
    property handle;
  end;


  //
  // -- unaWaveOutDevice --
  //
  {*
    Use this class to playback PCM audio stream.
    deviceID parameter used to construct instance of this class can be
    from 0 to unaWaveOutDevice.getDeviceCount() - 1, or you can use WAVE_MAPPER value instead.

    After opening the device feed periodically input stream by calling write() method.
    If device is unable to load next chunk when needed it can produce a chunk of "silence" and feed it automatically to hardware.
    Use autoFeed property to enable/disable this behavior.
  }
  unaWaveOutDevice = class(unaWaveDevice)
  private
    f_caps: WAVEOUTCAPSW;
    //
    f_outOfStream: int64;
    f_outOfData: int64;
    //
    f_dwReentranceCnt: int;
    //
  {$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
    f_awaitingPrefill: bool;
    f_smoothStartup: bool;
    f_jitterRepeat: bool;
    //
    f_hdrIndex: int;
  {$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
  {$IFDEF UNA_VCACM_USE_ASIO }
    f_asioBuf: unaMemoryStream;
  {$ENDIF UNA_VCACM_USE_ASIO }
    //
    f_onACF: unaWaveDataEvent;
    f_onACD: unaWaveDataEvent;
    //
    function getPitch(): unsigned;
    function getPlaybackRate(): unsigned;
    function getDeviceVolume(): unsigned;
    procedure setPitch(value: unsigned);
    procedure setPlaybackRate(value: unsigned);
    procedure setDeviceVolume(value: unsigned);
  protected
    procedure startIn(); override;
    procedure startOut(); override;
    //
    function doOpen(flags: uint): MMRESULT; override;
    function doClose(timeout: tTimeout = 1): MMRESULT; override;
    function doGetErrorText(errorCode: MMRESULT): string; override;
    function doGetPosition(): int64; override;
    //
    function afterOpen(): MMRESULT; override;
    //
    function prepareHeader(header: pointer): MMRESULT; override;
    function unprepareHeader(header: pointer): MMRESULT; override;
    function addHeader(header: unaWaveHeader): MMRESULT; override;
    //
    function onHeaderDone(header: unaWaveHeader; wakeUpByHeaderDone: bool): bool; override;
    {*
      Displays a format choose dialog.
      Reallocates (if necessary) the given format.
    }
    function formatChooseDef2(var format: pWAVEFORMATEX): MMRESULT; override;
    {*
	Returns true.
    }
    function getMasterIsSrc2(): bool; override;
    {*
	Flushes all data pending to be played back.
    }
    function flush2(waitForComplete: bool = true): bool; override;
    {*
	Passes data to waweout buffers.
    }
    function doWrite(buf: pointer; size: unsigned): unsigned; override;
{$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
    {*
    }
    property awaitingPrefill: bool read f_awaitingPrefill;
{$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
  public
    constructor create(deviceID: uint = WAVE_MAPPER; mapped: bool = false; direct: bool = false; overNum: unsigned = 0);
    {*
	Allocates resources.
    }
    procedure AfterConstruction(); override;
    {*
	Releases resources.
    }
    procedure BeforeDestruction(); override;
    {*
	MME only.

	@return device caps.
    }
    function getOutCaps(): pWAVEOUTCAPSW;
    {*
	MME only.

	@return device caps.
    }
    class function getCaps(deviceID: uint; var caps: WAVEOUTCAPSW): bool; overload;
    {*
	MME only.

	@return device caps.
    }
    class function getDeviceCount(): unsigned;
    {*
	MME only.

	@return device caps.
    }
    class function getErrorText(errorCode: MMRESULT): string;
    {*
	Displays format selection dialog.
    }
    function formatChoose(var format: pWAVEFORMATEX; const title: wString = ''; style: unsigned = ACMFORMATCHOOSE_STYLEF_INITTOWFXSTRUCT; enumFlag: unsigned = ACM_FORMATENUMF_HARDWARE + ACM_FORMATENUMF_OUTPUT; enumFormat: pWAVEFORMATEX = nil): MMRESULT;
    {*
	Not supported yet. Use getVolume() instead.
    }
    property volume: unsigned read getDeviceVolume write setDeviceVolume;
    {*
	Not supported yet.
    }
    property pitch: unsigned read getPitch write setPitch;
    {*
	Not supported yet.
    }
    property playbackRate: unsigned read getPlaybackRate write setPlaybackRate;
    {*
	Amount of audio data which appear too late to be played back in real time.
    }
    property outOfData: int64 read f_outOfData;
    {*
	Fires every time new chunk was feed to wave-out device.
    }
    property onAfterChunkFeed: unaWaveDataEvent read f_onACF write f_onACF;
    {*
	Fires every time chunk was just played out by wave-out device.
    }
    property onAfterChunkDone: unaWaveDataEvent read f_onACD write f_onACD;
{$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
    {*
	If True (default), when out of buffers (or during startup) WaveOut be paused till c_waveOut_unpause_after buffers are prepared for playback.
	If False, playback will start immediately.
    }
    property smoothStartup: bool read f_smoothStartup write f_smoothStartup;
    {*
	If True (default), when out of buffers will repeat last chunk several times until WaveOut has enough buffers for playback (but no more than 5 times).
	If False, no chunks will be repeated.
    }
    property jitterRepeat: bool read f_jitterRepeat write f_jitterRepeat;
{$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
    {*
	WinAPI MME handle
    }
    property handle;
  end;


  unaMMTimer = class;

  //
  // -- unaWaveSoftwareDevice --
  //
  {*
    This is base class for software devices, such as wave mixer.
  }
  unaWaveSoftwareDevice = class(unaWaveDevice)
  private
    f_realTimerCount: int;
{$IFDEF DEBUG_LOG_RT }
    f_timerTM: uint64;
    f_timerPassed: int64;
{$ENDIF DEBUG_LOG_RT }
    //
    f_realTimer: unaAbstractTimer;
    f_nonrealTimeDelay: unsigned;
    //
    procedure checkRealTimer();
    procedure adjustRTInterval(isSrc: bool);
  protected
    procedure onTick(sender: tObject); virtual;
    {*
      WARNING! this call will change the realtime clock interval.
      so, be careful when setting the format of realtime devices with non-default timer interval.
    }
    function setFormat(isSrc: bool; format: pWAVEFORMATEX): bool; override;
    procedure setRealTime(value: bool); override;
    //
    function prepareHeader(header: pointer): MMRESULT; override;
    function unprepareHeader(header: pointer): MMRESULT; override;
    //
    function afterOpen(): MMRESULT; override;
    procedure afterClose(closeResult: MMRESULT); override;
    function open2(query: bool = false; timeout: tTimeout = 10005; flags: uint = 0; startDevice: bool = true): MMRESULT; override;
    //
    function addHeader(header: unaWaveHeader): MMRESULT; override;
    function onHeaderDone(header: unaWaveHeader; wakeUpByHeaderDone: bool): bool; override;
    {*
      Returns true.
    }
    function getMasterIsSrc2(): bool; override;
  public
    constructor create(realTime: bool = false; isIn: bool = true; overNum: unsigned = 0);
    procedure AfterConstruction(); override;
    procedure BeforeDestruction(); override;
    //
    property realTimer: unaAbstractTimer read f_realTimer;
  end;


  unaOnRiffStreamIsDone = procedure(sender: tObject) of object;

  //
  // -- unaRiffStream --
  //
  {*
    RIFF WAVE stream.
    Use this class to read or create RIFF WAVE files.
    Non-PCM files will be automatically converted to PCM format when possible.
    Creation of non-PCM files is also possible.
  }
  unaRiffStream = class(unaWaveSoftwareDevice)
  private
    f_realTimeFeedSize: unsigned;
    f_status: int;
    //
    f_streamSize: unsigned;
    f_streamPos: unsigned;
    f_streamPosHistory: unsigned;
    f_readingIsDone: bool;
    f_streamIsDone: bool;
{$IFDEF VCX_DEMO }
    f_headersServedRiff: int;
{$ENDIF VCX_DEMO }
    f_fileName: wString;
    //
    f_factSize: unsigned;
    f_dataSizeOfs: unsigned;
    f_riffSrcFormat: pWAVEFORMATEX;
    f_riffDstFormatTag: unsigned;
    //
    f_srcChunk: pointer;
    f_dstChunk: pointer;
    //
    f_loop: bool;
    f_dataChunk: unaRiffChunk;
    f_dataChunkOfs: unsigned;
    // input
    f_acm: unaMsAcm;
    f_riff: unaRIFile;
    f_codec: unaMsAcmCodec;
    f_playbackHistory: unaList;
    //
{$IFNDEF VC_LIC_PUBLIC }
    f_mpeg: unaMpegAudio_layer123;
    f_mpegReader: unaBitReader_file;
    f_mpegBuf: pointer;
    f_mpegBufSize: int;
    f_mpegBufInUse: int;
    f_mpegHdr: unaMpegHeader;
    //
    f_mpegSamplesWritten: int;
    f_mpegSamplesNeeded: int;
    f_mpegSamplesPerChunk: int;
{$ENDIF VC_LIC_PUBLIC }
    //
    f_fileType: int;
    //
    // output
    f_riffStream: unaFileStream;
    //
    f_onStreamIsDone: unaOnRiffStreamIsDone;
    //
    function browseRiff(chunk: unaRiffChunk; options: unsigned): bool;
    //
    procedure clearPlaybackHistory();
    procedure setStreamPos(value: unsigned);
    function readNextChunk(): bool;
{$IFNDEF VC_LIC_PUBLIC }
    function getMpegFS(): int;
{$ENDIF VC_LIC_PUBLIC }
  protected
    function afterOpen(): MMRESULT; override;
    procedure afterClose(closeResult: MMRESULT); override;
    //
    function onHeaderDone(header: unaWaveHeader; wakeUpByHeaderDone: bool): bool; override;
    {*
	Forces all awaiting data to be resampled.
    }
    function flush2(waitForComplete: bool = true): bool; override;
    {*
	Returns current position in wav stream.
    }
    function doGetPosition(): int64; override;
    {*

    }
    function doWrite(buf: pointer; size: unsigned): unsigned; override;
  public
    {*
	Opens existing file for reading.
    }
    constructor create(const fileName: wString; realTime: bool = false; loop: bool = false; acm: unaMsAcm = nil);
    {*
	Creates new RIFF WAVE file for writing.
    }
    constructor createNew(const fileName: wString; const srcFormat: WAVEFORMATEX; dstFormatTag: unsigned = WAVE_FORMAT_PCM; acm: unaMsAcm = nil);
    constructor createNewExt(const fileName: wString; srcFormat: pWAVEFORMATEXTENSIBLE; dstFormatTag: unsigned = WAVE_FORMAT_PCM; acm: unaMsAcm = nil);
    //
    destructor Destroy(); override;
    procedure AfterConstruction(); override;
    //
    {*
	Assigns new existing file for reading.
    }
    function assignRIFile(const fileName: wString): int;
    {*
	Assigns ouput file for writing.
    }
    function assignRIFileWriteSrc(const fileName: wString; srcFormat: pWAVEFORMATEX; dstFormatTag: unsigned = WAVE_FORMAT_PCM): int;
    {*
	Assigns ouput file for writing.
    }
    function assignRIFileWriteDst(const fileName: wString; dstFormat: pWAVEFORMATEX): int;
    //
    procedure passiveOpen();
    function readData(buf: pointer; maxSize: unsigned): unsigned;
    //
    {*
5       - output riff: no filename was specified
4	- output riff: cannot locate required codec format
3	- output riff: cannot locate required codec
2	- output riff: cannot create output stream
1	- output riff: OK
-------
0	- input riff: OK
-1	- input riff: file is not valid RIFF
-2	- input riff: file is valid RIFF file, but is not a valid WAVE file
-3	- input riff: not acm was specified (but it is required for conversion)
-4	- input riff: unknown driver (cannot locate MS ACM codec)
-5	- input riff: unknown format (for selected MS ACM codec)
$0FFFFFFF - no init
    }
    property status: int read f_status;
    {*
	Codec used for compression or decompression.
    }
    property codec: unaMsAcmCodec read f_codec;
    {*
	WAV file name.
    }
    property fileName: wString read f_fileName;
    {*
	WAVe stream size in bytes.
    }
    property streamSize: unsigned read f_streamSize;
    {*
	Current position in WAVe stream in bytes.
    }
    property streamPosition: unsigned read f_streamPos write setStreamPos;
    {*
	True when no more data can be read from stream (and loop = false).
    }
    property streamIsDone: bool read f_streamIsDone;
    {*
	Number of bytes indicated in 'fact' chunk.
    }
    property factSize: unsigned read f_factSize;
    {*
	Set this property to true if you wish to loop the file reading operation from end to beginning.
    }
    property loop: bool read f_loop write f_loop;
    {*
	Type of file (RIFF/MP3, etc), see c_unaRiffFileType_XXXX constants.
    }
    property fileType: int read f_fileType;
{$IFNDEF VC_LIC_PUBLIC }
    {*
	Frame saze (in samples) of mpeg audio stream.
    }
    property mpegFrameSize: int read getMpegFS;
{$ENDIF VC_LIC_PUBLIC }
    {*
	This event is fired when reading from file is done.
    }
    property onStreamIsDone: unaOnRiffStreamIsDone read f_onStreamIsDone write f_onStreamIsDone;
  end;


  //
  // -- unaWaveMultiStreamDevice --
  //
  {*
    This is base class for devices working with more than two streams.
  }
  unaWaveMultiStreamDevice = class(unaWaveSoftwareDevice)
  private
    f_streams: unaObjectList;
    f_autoAddSilence: bool;
  protected
    procedure action(stream: unaAbstractStream); virtual;
    function pump2(size: unsigned = 0): unsigned; virtual;
  public
    constructor create(realTime: bool = false; autoAddSilence: bool = true; overNum: unsigned = 0);
    destructor Destroy(); override;
    //
    function addStream(stream: unaAbstractStream = nil): unaAbstractStream;
    function removeStream(stream: unaAbstractStream = nil): bool;
    function getStream(index: int): unaAbstractStream;
    function getStreamCount(): unsigned;
    //
    function pump(size: unsigned = 0): unsigned;
    //
    property addSilence: bool read f_autoAddSilence write f_autoAddSilence;
  end;


  //
  // -- unaWaveMixDevice --
  //
  {*
    This class performs software mixing of input streams.
  }
  unaWaveMixerDevice = class(unaWaveMultiStreamDevice)
  private
    f_bufSrc: pArray;
    f_bufDst: pArray;
    f_bufSrcSize: unsigned;
    f_bufDstSize: unsigned;
    //
    f_oob: array[byte] of int64;
    f_oobHadSome: array[byte] of int64;
    f_svol: array[byte] of int;
    //
    function getOOB(index: int): int64;		// store data for up to 256 channels
    function getSVolume(index: int): int; 	// store data for up to 256 channels
  protected
    procedure onTick(sender: tObject); override;
    function doOpen(flags: uint): MMRESULT; override;
    function onHeaderDone(header: unaWaveHeader; wakeUpByHeaderDone: bool): bool; override;
  public
    destructor Destroy(); override;
    //
    {
	Mixes streams.

	@return number of bytes mixed
    }
    function mix(): int;
    //
    property oob[index: int]: int64 read getOOB;
    //
    property streamVolume[index: int]: int read getSVolume;
  end;


  //
  // -- unaWaveExclusiveMixerDevice --
  //
  {*
    This class performs exclusive mixing of input streams.
  }
  unaWaveExclusiveMixerDevice = class(unaWaveMultiStreamDevice)
  private
    f_buf: pArray;
    f_bufSilent: pArray;	// buffer used for "silent" streams, has same size as f_buf
    f_bufSMX: pArray;
    //
    f_lastBufSize: unsigned;
    f_lastBuffSMXSize: unsigned;
    //
    f_subSilence: int64;
    //
    function getSize(): unsigned;
  protected
    function pump2(mixSize: unsigned = 0): unsigned; override;
    function afterOpen(): MMRESULT; override;
  public
    destructor Destroy(); override;
    //
    property subSilence: int64 read f_subSilence;
  end;


  //
  // -- unaWaveResampler --
  //

  {*
    This class can resample audio stream from one PCM format to another.
    It does not use ACM codecs.

    8, 16 and 32 bits samples with virtually unlimited number of channels and samples per second are supported.
  }
  unaWaveResampler = class(unaWaveSoftwareDevice)
  private
    f_srcChunk: unaPCMChunk;
    f_dstChunk: unaPCMChunk;
    //
    f_useSpeexDSP: bool;
    f_useSpeexDSPwasAutoReset: bool;
    f_speexdsp: array[0..31] of unaSpeexDSP;	// up to 32 channels
    f_speextried: bool;
    f_speexavail2: bool;
    //
    f_inputConsumed: bool;
    //
    f_subBuf: pArray;
    f_subBufSize: int;
    f_subBufPos: int;
    //
    f_channelBuf: pointer;
    f_channelBufOut: pointer;
    f_channelBufSize: unsigned;
  protected
    function onHeaderDone(header: unaWaveHeader; wakeUpByHeaderDone: bool): bool; override;
    function afterOpen(): MMRESULT; override;
    procedure afterClose(closeResult: MMRESULT); override;
    {*
      Returns false.
    }
    function getMasterIsSrc2(): bool; override;
    {*
      Forces all awaiting data to be resampled.
    }
    function flush2(waitForComplete: bool = true): bool; override;
    {*
	//
    }
    function doWrite(buf: pointer; size: unsigned): unsigned; override;
  public
    constructor create(realTime: bool = false; overNum: unsigned = 0);
    procedure AfterConstruction(); override;
    {*
    }
    destructor Destroy(); override;
    //
    {*
      Sets the source or destination stream format.
    }
    function setSampling(isSrc: bool; const format: WAVEFORMATEX): bool; overload;
    function setSamplingExt(isSrc: bool; format: PWAVEFORMATEXTENSIBLE): bool; overload;
    {*
      Sets the source or destination stream format.
    }
    function setSampling(isSrc: bool; samplesPerSec: unsigned = c_defSamplingSamplesPerSec; bitsPerSample: unsigned = c_defSamplingBitsPerSample; numChannels: unsigned = c_defSamplingNumChannels): bool; overload;
    {*
	Try to use Speex DSP resampler if available.
    }
    property useSpeexDSP: bool read f_useSpeexDSP write f_useSpeexDSP;
  end;


  //
  // -- unaMMTimer --
  //
  {*
	Multimedia timer wrapper class.
  }
  unaMMTimer = class(unaAbstractTimer)
  private
    f_timeEvent: MMRESULT;
    f_minPeriod: unsigned;
    f_lastMinPeriod: unsigned;
    f_caps: TIMECAPS;
  protected
    procedure changeInterval(var newValue: unsigned); override;
    function doStart(): bool; override;
    procedure doStop(); override;
  public
    constructor create(interval: unsigned = 1000; minPeriod: unsigned = 0);
    procedure BeforeDestruction(); override;
    //
    function getCaps(): pTIMECAPS;
    //
    property minPeriod: unsigned read f_minPeriod write f_minPeriod;
  end;


// --  --
{*
  Returns true if specified errorCode is equal to MMSYSERR_NOERROR.
}
function mmNoError(errorCode: MMRESULT): bool;

// --  --
{*
  Returns text message describing the specified errorCode
  this is generic function, use getErrorText() instead if possible.
  Returns empty string if error code is unknown.
}
function mmGetErrorCodeText(errorCode: MMRESULT): string;

// --  --
{*
  Same as mmGetErrorCodeText(), but additionally prefixes the result
  with numeric presentation of error code. Also encloses text in ( ) pair.
}
function mmGetErrorCodeTextEx(errorCode: MMRESULT): string;

// --  --
{*
  Helper function for acm_formatChoose routine.
  Fills cbStruct, fdwStyle and pszTitle members before calling Win API.
}
function formatChoose(bufW: pACMFORMATCHOOSEW; const title: wString = ''; style: unsigned = ACMFORMATCHOOSE_STYLEF_INITTOWFXSTRUCT; enumFlag: unsigned = 0; enumFormat: pWAVEFORMATEX = nil): MMRESULT;
{*
  Displays format choose dialog.
  Allocates wave format if necessary.
}
function formatChooseAlloc(var format: pWAVEFORMATEX; defFormatTag: unsigned = WAVE_FORMAT_PCM; defSamplesPerSec: unsigned = c_defSamplingSamplesPerSec; const title: wString = ''; style: unsigned = ACMFORMATCHOOSE_STYLEF_INITTOWFXSTRUCT; enumFlag: unsigned = 0; enumFormat: pWAVEFORMATEX = nil; formatSize: unsigned = 0; wndHandle: hWnd = 0): MMRESULT;

// --  --
{*
}
function formatIsPCM(format: pWAVEFORMATEX): bool; overload;
function formatIsPCM(format: pWAVEFORMATEXTENSIBLE): bool; overload;

// --  --
{*
  Fills the WAVEFORMATEX structure according to the specified sampling parameters.
  Returns pointer on format parameter (result := @@format).
}
function fillPCMFormat(var format: WAVEFORMATEX; samplesPerSecond: unsigned = c_defSamplingSamplesPerSec; bitsPerSample: unsigned = c_defSamplingBitsPerSample; numChannels: unsigned = c_defSamplingNumChannels): pWAVEFORMATEX; overload;
{*
  Fills the WAVEFORMATEX structure according to the specified sampling parameters.
  Returns filled PCM format.
}
function fillPCMFormat(samplesPerSecond: unsigned = c_defSamplingSamplesPerSec; bitsPerSample: unsigned = c_defSamplingBitsPerSample; numChannels: unsigned = c_defSamplingNumChannels): WAVEFORMATEX; overload;
{*
  Fills the PWAVEFORMATEXTENSIBLE structure according to the specified sampling parameters.
  Returns pointer on format parameter (result := @@format).
}
function fillPCMFormatExt(var format: PWAVEFORMATEXTENSIBLE; samplesPerSecond: unsigned = c_defSamplingSamplesPerSec; containerSize: unsigned = c_defSamplingBitsPerSample; validBitsPerSample: unsigned = c_defSamplingBitsPerSample; numChannels: unsigned = c_defSamplingNumChannels; channelMask: DWORD = SPEAKER_DEFAULT): PWAVEFORMATEXTENSIBLE; overload;
function fillPCMFormatExt(var format: PWAVEFORMATEXTENSIBLE; const subtype: tGuid; samplesPerSecond: unsigned = c_defSamplingSamplesPerSec; containerSize: unsigned = c_defSamplingBitsPerSample; validBitsPerSample: unsigned = c_defSamplingBitsPerSample; numChannels: unsigned = c_defSamplingNumChannels; channelMask: DWORD = SPEAKER_DEFAULT): PWAVEFORMATEXTENSIBLE; overload;
function fillFormatExt(var format: PWAVEFORMATEXTENSIBLE; source: pWAVEFORMATEX): PWAVEFORMATEXTENSIBLE;

//
function waveExt2wave(format: PWAVEFORMATEXTENSIBLE; var fmt: pWAVEFORMATEX; ignoreChannelLayout: bool = false; allocSize: uint = 0): bool;
function waveExt2str(format: PWAVEFORMATEXTENSIBLE): string;
//
function str2waveFormatExt(const str: string; var format: PWAVEFORMATEXTENSIBLE): bool;
function waveFormatExt2str(format: PWAVEFORMATEXTENSIBLE): string;

// --  --
function duplicateFormat(source: pWAVEFORMATEX; var dup: pWAVEFORMATEX; allocSize: unsigned = 0): unsigned; overload;
function duplicateFormat(source: pWAVEFORMATEX; var dup: PWAVEFORMATEXTENSIBLE; allocSize: unsigned = 0): unsigned; overload;
function duplicateFormat(source: PWAVEFORMATEXTENSIBLE; var dup: PWAVEFORMATEXTENSIBLE; allocSize: unsigned = 0): unsigned; overload;
function duplicateFormat(source: PWAVEFORMATEXTENSIBLE; var dup: pWAVEFORMATEX; allocSize: unsigned = 0): unsigned; overload;

//
function getFormatTagExt(fmt: PWAVEFORMATEXTENSIBLE): DWORD;

{*
  Returns true if two formats are equal.
}
function formatEqual(const format1, format2: WAVEFORMATEX): bool;

{*
  Returns string representation of PCM sampling parameters.
}
function sampling2str(samplesPerSecond: unsigned = c_defSamplingSamplesPerSec; bitsPerSample: unsigned = c_defSamplingBitsPerSample; numChannels: unsigned = c_defSamplingNumChannels): string;

{*
  Returns string representation of some audio format tags, or #NNN if tag is unknown.
}
function formatTag2str(formatTag: unsigned): string;

{*
  Returns string representation of audio format.
}
function format2str(const format: WAVEFORMATEX): string;


{$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }

// --  --
{*
  Creates new wave header.

  @param device Wave device assotiated with header.
  @param size Size of data to be put into header after creation.
  @param data Pointer to data buffer.

  @return New wave header.
}
function newWaveHdr(device: unaWaveDevice; size: unsigned; data: pointer = nil; prepare: bool = true): unaWaveHeader;
{*
  Destroys header object.

  @param hdr Wave device header to be disposed.
  @param device Wave device assotiated with header.

  @return True if successfull (header is not nil).
}
function removeWaveHdr(var hdr: unaWaveHeader; device: unaWaveDevice): bool;

{$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }


implementation

{$IFDEF VCX_DEMO }
uses
  unaBaseXcode;
{$ENDIF VCX_DEMO }

{ unaMsAcmObject }

// --  --
constructor unaMsAcmObject.create();
begin
  inherited;
  //
  fillChar(f_details, sizeof(unaAcmDetails), #0);
  f_details.r_type := uadtUnused;
end;

// --  --
procedure unaMsAcmObject.BeforeDestruction();
begin
  inherited;
  //
  deleteDetails();
end;

// --  --
constructor unaMsAcmObject.create(tag: unaMsAcmObjectTag);
begin
  inherited create();
  //
  f_tag := tag;
  f_driver := tag.f_driver;
end;

// --  --
procedure unaMsAcmObject.deleteDetails();
begin
  case (f_details.r_type) of
    // -- format --
    uadtFormatDetails: with f_details.r_formatDetails do begin
      //
      if (pwfx <> nil) then
	deleteWaveFormat(pwfx);
      //
      pwfx := nil;
      cbwfx := 0;
    end;
    // -- filter --
    uadtFilterDetails: with f_details.r_filterDetails do begin
      //
      if (pwfltr <> nil) then
	mrealloc(pwfltr);
      //	
      pwfltr := nil;
      cbwfltr := 0;
    end;
  end;
end;

// --  --
function unaMsAcmObject.getDetails(): punaAcmDetails;
begin
  result := @f_details;
end;


  { unaMsAcmFilter }

// --  --
constructor unaMsAcmFilter.create();
begin
  inherited;
  //
  f_details.r_type := uadtFilterDetails;
end;

// --  --
constructor unaMsAcmFilter.create(tag: unaMsAcmObjectTag; details: pACMFILTERDETAILS);
var
  size: unsigned;
begin
  inherited create(tag);
  //
  f_details.r_type := uadtFilterDetails;
  f_details.r_filterDetails := details^;
  //
  with f_details.r_filterDetails do begin
    //
    size := cbwfltr;
    if (size > 0) then begin
      //
      pwfltr := malloc(size);
      move(details.pwfltr^, pwfltr^, size);
    end;
  end;
end;


  { unaMsAcmFormat }

// --  --
constructor unaMsAcmFormat.create();
begin
  inherited;
  //
  f_details.r_type := uadtFormatDetails;
end;

// --  --
constructor unaMsAcmFormat.create(tag: unaMsAcmObjectTag; details: pACMFORMATDETAILS);
var
  size: unsigned;
begin
  inherited create(tag);
  //
  f_details.r_type := uadtFormatDetails;
  f_details.r_formatDetails := details^;
  //
  with f_details.r_formatDetails do begin
    //
    size := max(cbwfx, sizeOf(pwfx^));
    //
    pwfx := malloc(size, true);
    move(details.pwfx^, pwfx^, cbwfx);
    pwfx.cbSize := size - sizeOf(pwfx^);
  end;
end;

// --  --
function unaMsAcmFormat.formatChoose(bufW: pACMFORMATCHOOSEW; const title: wString): MMRESULT;
begin
  fillChar(bufW, sizeOf(ACMFORMATCHOOSEW), #0);
  bufW.pwfx := f_details.r_formatDetails.pwfx;
  bufW.cbwfx := f_details.r_formatDetails.cbwfx;
  result := unaMsAcmClasses.formatChoose(bufW, title);
end;


  { unaMsAcmObjectTag }

// --  --
constructor unaMsAcmObjectTag.create(driver: unaMsAcmDriver);
begin
  inherited create();
  //
  f_driver := driver;
end;


  { unaMsAcmFilterTag }

// --  --
constructor unaMsAcmFilterTag.create(driver: unaMsAcmDriver; tag: pACMFILTERTAGDETAILS);
begin
  inherited create(driver);
  //
  f_tag := tag^;
end;


  { unaMsAcmFormatTag }

// --  --
constructor unaMsAcmFormatTag.create(driver: unaMsAcmDriver; tag: pACMFORMATTAGDETAILS);
begin
  inherited create(driver);
  //
  f_tag := tag^;
end;


  { unaMsAcmDriver }

// --  --
function unaMsAcmDriver.about(wnd: HWND): MMRESULT;
begin
  result := open();
  //
  if (mmNoError(result)) then begin
    result := sendDriverMessage(ACMDM_DRIVER_ABOUT, -1);	// query
    //
    if (mmNoError(result))then
      result := sendDriverMessage(ACMDM_DRIVER_ABOUT, wnd);
  end;
end;

// --  --
procedure unaMsAcmDriver.addFilter(tag: unaMsAcmObjectTag; pafd: pACMFILTERDETAILS);
begin
  f_filters.add(unaMsAcmFilter.create(tag, pafd));
end;

// --  --
procedure unaMsAcmDriver.addFormat(tag: unaMsAcmObjectTag; pafd: pACMFORMATDETAILS);
begin
  f_formats.add(unaMsAcmFormat.create(tag, pafd));
end;

// --  --
procedure unaMsAcmDriver.AfterConstruction();
begin
  inherited;
  //
  f_maxWaveFormatSize := getMaxWaveFormatSize(f_id);
end;

// --  --
function unaMsAcmDriver.assignFormat(tag: unsigned; index: unsigned; device: unaWaveDevice): bool;
var
  pafd: ACMFORMATDETAILS;
begin
  result := false;
  //
  if ((nil <> device) and (preparePafd(pafd, tag, index))) then try
    //
    if (mmNoError(acm_formatDetails(getHandle(), @pafd, ACM_FORMATDETAILSF_INDEX))) then
      result := device.setSampling(pafd.pwfx.nSamplesPerSec, pafd.pwfx.wBitsPerSample, pafd.pwfx.nChannels);
    //
  finally
    mrealloc(pafd.pwfx);
  end;
end;

// --  --
procedure unaMsAcmDriver.BeforeDestruction();
begin
  inherited;
  //
  close();
end;

// --  --
function unaMsAcmDriver.close(): MMRESULT;
begin
  if (not f_isInstallable and isOpen()) then begin
    //
    result := acm_driverClose(f_handle, 0);
    f_handle := 0;
  end
  else
    result := MMSYSERR_NOERROR;
end;

// --  --
constructor unaMsAcmDriver.create(acm: unaMsAcm; id: HACMDRIVERID; support: unsigned; const libName: wString);
begin
  inherited create();
  //
  f_acm := acm;
  f_id := id;
  f_support := support;
  f_libName := trimS(libName);
  f_refCount := 0;
  f_isInstallable := ('' <> f_libName);
  if (f_isInstallable) then
    f_handle := f_id;
  //
  f_formats := unaObjectList.create();
  f_filters := unaObjectList.create();
  f_formatTags := unaObjectList.create();
  f_filterTags := unaObjectList.create();
end;

// --  --
destructor unaMsAcmDriver.Destroy();
begin
  inherited;
  //
  freeAndNil(f_filters);
  freeAndNil(f_formats);
  freeAndNil(f_filterTags);
  freeAndNil(f_formatTags);
end;

// --  --
function myFilterEnumCB(hadid: HACMDRIVERID; pafd: pACMFILTERDETAILS; dwInstance: DWORD; fdwSupport: DWORD): Windows.BOOL; stdcall;
var
  ft: unaMsAcmFilterTag absolute dwInstance;
  driver: unaMsAcmDriver;
begin
  result := false;
  if (ft <> nil) then begin
    //
    driver := ft.f_driver;
    if (driver <> nil) then begin
      //
      driver.addFilter(ft, pafd);
      result := true;
    end
  end;
end;

// --  --
function myFilterTagEnumCB(hadid: HACMDRIVERID; pafd: pACMFILTERTAGDETAILS; dwInstance: DWORD; fdwSupport: DWORD): Windows.BOOL; stdcall;
var
  driver: unaMsAcmDriver absolute dwInstance;
  pafild: ACMFILTERDETAILS;
  pwf: pWAVEFILTER;
  ft: unaMsAcmFilterTag;
begin
// fdwSupport should be = pafd.fdwSupport ?
  if (nil <> driver) then begin
    //
    ft := unaMsAcmFilterTag.create(driver, pafd);
    driver.f_filterTags.add(ft);
    //
    pwf := malloc(pafd.cbFilterSize);
    pwf.cbStruct := pafd.cbFilterSize;
    pwf.dwFilterTag := pafd.dwFilterTag;
    //
    fillChar(pafild, sizeof(ACMFILTERDETAILS), #0);
    pafild.cbStruct := sizeof(ACMFILTERDETAILS);
    pafild.dwFilterTag := pafd.dwFilterTag;
    pafild.pwfltr := pwf;
    pafild.cbwfltr := pafd.cbFilterSize;
    //
    // enum filters
    acm_filterEnum(driver.getHandle(), @pafild, myFilterEnumCB, UIntPtr(ft), ACM_FILTERENUMF_DWFILTERTAG);
    //
    result := true;
  end
  else
    result := false;
end;

// --  --
function unaMsAcmDriver.enumFilters(flags: uint): MMRESULT;
var
  pafild: ACMFILTERTAGDETAILS;
begin
  result := open();
  if (mmNoError(result)) then begin
    //
    f_filters.clear();
    f_filterTags.clear();
    //
    fillChar(pafild, sizeof(ACMFILTERTAGDETAILS), #0);
    //
    result := acm_filterTagEnum(f_handle, @pafild, MyFilterTagEnumCB, UintPtr(self), flags);
  end;
end;

// --  --
function myFormatEnumCB(hadid: HACMDRIVERID; pafd: pACMFORMATDETAILSA; dwInstance: DWORD; fdwSupport: DWORD): BOOL; stdcall;
var
  ft: unaMsAcmFormatTag;
  driver: unaMsAcmDriver;
begin
  result := false;
  ft := unaMsAcmFormatTag(dwInstance);
  if (ft <> nil) then begin
    //
    driver := ft.f_driver;
    if (driver <> nil) then begin
      //
      driver.addFormat(ft, pafd);
      result := true;
    end;
  end;
end;

// --  --
function myFormatTagEnumCB(hadid: HACMDRIVERID; paftd: pACMFORMATTAGDETAILSA; dwInstance: DWORD; fdwSupport: DWORD): BOOL; stdcall;
var
  driver: unaMsAcmDriver;
  pwfx: pWAVEFORMATEX;
  ft: unaMsAcmFormatTag;
  afd: ACMFORMATDETAILS;
  size: unsigned;
begin
  driver := unaMsAcmDriver(dwInstance);
  if (nil <> driver) then begin
    //
    ft := unaMsAcmFormatTag.create(driver, paftd);
    driver.f_formatTags.add(ft);
    //
    if (not driver.f_formatLastEnumTagsOnly) then begin
      //
      size := max(driver.f_maxWaveFormatSize, sizeOf(pwfx^));
      //
      pwfx := malloc(size, true);
      pwfx.wFormatTag := paftd.dwFormatTag;
      pwfx.cbSize := size - sizeof(WAVEFORMATEX);
      pwfx.nChannels := driver.f_formatLastEnumWave.nChannels;
      pwfx.nSamplesPerSec := driver.f_formatLastEnumWave.nSamplesPerSec;
      pwfx.wBitsPerSample := driver.f_formatLastEnumWave.wBitsPerSample;
      //
      fillChar(afd, sizeof(ACMFORMATDETAILS), #0);
      afd.cbStruct := sizeof(ACMFORMATDETAILS);
      afd.dwFormatTag := paftd.dwFormatTag;
      afd.pwfx := pwfx;
      afd.cbwfx := driver.f_maxWaveFormatSize;
      //
      acm_formatEnumA(driver.getHandle(), @afd, ACMFORMATENUMCBA(@myFormatEnumCB), uint(ft), driver.f_enumFormatsFlag);
      mrealloc(pwfx);
    end;
    //
    result := true;
  end
  else
    result := false;
end;

// --  --
function unaMsAcmDriver.enumFormats(flags: uint; force: bool; pwfx: pWAVEFORMATEX; tagsOnly: bool): MMRESULT;
var
  aftd: ACMFORMATTAGDETAILS;
begin
  //
  if (f_formatWasEnum and not force and (f_formatLastEnumFlags = flags) and (f_formatLastEnumTagsOnly = tagsOnly)) then
    result := MMSYSERR_NOERROR
  else begin
    //
    result := open();
    if (mmNoError(result)) then begin
      //
      f_formats.clear();
      f_formatTags.clear();
      //
      fillChar(aftd, sizeof(ACMFORMATTAGDETAILS), #0);
      aftd.cbStruct := sizeof(ACMFORMATTAGDETAILS);
      if (nil <> pwfx) then
	f_formatLastEnumWave := pwfx^
      else
	fillChar(f_formatLastEnumWave, sizeof(WAVEFORMATEX), #0);
      //
      f_enumFormatsFlag := flags;
      f_formatLastEnumTagsOnly := tagsOnly;
      //
      result := acm_formatTagEnumA(f_handle, @aftd, ACMFORMATTAGENUMCBA(@myFormatTagEnumCB), UintPtr(self), 0);
      if (mmNoError(result)) then begin
        //
	f_formatWasEnum := true;
	f_formatLastEnumFlags := flags;
      end;
    end;
  end;
end;

// --  --
procedure unaMsAcmDriver.fillDetails();
{$IFNDEF NO_ANSI_SUPPORT }
var
  detailsA: ACMDRIVERDETAILSA;
{$ENDIF NO_ANSI_SUPPORT }
begin
{$IFNDEF NO_ANSI_SUPPORT }
  if (not g_wideApiSupported and not f_isInstallable) then
    detailsA.cbStruct := sizeof(ACMDRIVERDETAILSA);
{$ENDIF NO_ANSI_SUPPORT }
  // allways return wide
  f_details.cbStruct := sizeof(ACMDRIVERDETAILSW);
  //
  if (f_isInstallable) then
    // installable drivers always returns unicode
    f_detailsValid := mmNoError(sendDriverMessage(ACMDM_DRIVER_DETAILS, int(@f_details)))
  else
{$IFNDEF NO_ANSI_SUPPORT }
    if (not g_wideApiSupported) then begin
      //
      f_detailsValid := mmNoError(acm_driverDetailsA(id, @detailsA, 0));
      //
      if (f_detailsValid) then begin
	//
	with f_details do begin
	  //
	  fccType := detailsA.fccType;
	  fccComp := detailsA.fccComp;
	  wMid := detailsA.wMid;
	  wPid := detailsA.wPid;
	  vdwACM := detailsA.vdwACM;
	  vdwDriver := detailsA.vdwDriver;
	  fdwSupport  := detailsA.fdwSupport;
	  cFormatTags := detailsA.cFormatTags;
	  cFilterTags := detailsA.cFilterTags;
	  hicon := detailsA.hicon;
	  //
          {$IFDEF __BEFORE_D6__ }
	  str2arrayW(wString(detailsA.szShortName), szShortName);
	  str2arrayW(wString(detailsA.szLongName), szLongName);
	  str2arrayW(wString(detailsA.szCopyright), szCopyright);
	  str2arrayW(wString(detailsA.szLicensing), szLicensing);
	  str2arrayW(wString(detailsA.szFeatures), szFeatures);
          {$ELSE }
	  str2arrayW(wString(detailsA.szShortName), szShortName);
	  str2arrayW(wString(detailsA.szLongName), szLongName);
	  str2arrayW(wString(detailsA.szCopyright), szCopyright);
	  str2arrayW(wString(detailsA.szLicensing), szLicensing);
	  str2arrayW(wString(detailsA.szFeatures), szFeatures);
          {$ENDIF __BEFORE_D6__ }
	end;
      end;
    end
    else
{$ENDIF NO_ANSI_SUPPORT }
      try
	f_detailsValid := mmNoError(acm_driverDetailsW(id, @f_details, 0));
      finally
	if (f_detailsValid) then
	  f_detailsValid := f_detailsValid;
      end;
end;

// --  --
function unaMsAcmDriver.getDetails(): pACMDRIVERDETAILSW;
begin
  if (not f_detailsValid) then
    fillDetails();
  //
  result := @f_details;
end;

// --  --
function unaMsAcmDriver.getFilter(index: unsigned): unaMsAcmFilter;
begin
  result := unaMsAcmFilter(f_filters[index]);
end;

// --  --
function unaMsAcmDriver.getFilterCount(): unsigned;
begin
  result := f_filters.count;
end;

// --  --
function unaMsAcmDriver.getFormat(index: unsigned): unaMsAcmFormat;
begin
  result := unaMsAcmFormat(f_formats[index]);
end;

// --  --
function unaMsAcmDriver.getFormatCount(): unsigned;
begin
  result := f_formats.count;
end;

// --  --
function unaMsAcmDriver.getFormatTag(index: unsigned): unaMsAcmFormatTag;
begin
  result := f_formatTags[index];
end;

// --  --
function unaMsAcmDriver.getFormatTagCount(): unsigned;
begin
  result := f_formatTags.count;
end;

// --  --
function unaMsAcmDriver.getHandle(): HACMDRIVER;
begin
  if (mmNoError(open())) then
    result := f_handle
  else
    result := 0;
end;

// --  --
function unaMsAcmDriver.getPriority(): unsigned;
begin
  acm_metrics(f_handle, ACM_METRIC_DRIVER_PRIORITY, result);
end;

// --  --
function unaMsAcmDriver.isEnabled(): bool;
begin
  result := (0 = (getDetails().fdwSupport and ACMDRIVERDETAILS_SUPPORTF_DISABLED));
end;

// --  --
function unaMsAcmDriver.isMyLib(const libName: wString): bool;
begin
  result := sameString(f_libName, libName);
end;

// --  --
function unaMsAcmDriver.isOpen(): bool;
begin
  result := (0 <> f_handle);
end;

// --  --
function unaMsAcmDriver.open(): MMRESULT;
begin
  if (not isOpen()) then begin
    //
    result := acm_driverOpen(@f_handle, f_id, 0);
    if (not mmNoError(result)) then
      f_handle := 0;
    //
    f_formatWasEnum := false;
  end
  else
    result := MMSYSERR_NOERROR;
end;

// --  --
function unaMsAcmDriver.preparePafd(var pafd: ACMFORMATDETAILS; tag, index: unsigned): bool;
begin
  result := f_acm.preparePafd(pafd, tag, index, getHandle());
end;

// --  --
function unaMsAcmDriver.refInc(delta: int): int;
begin
  if (0 < delta) then
    result := InterlockedIncrement(f_refCount)
  else
    if (0 = delta) then
      result := f_refCount
    else
      result := InterlockedDecrement(f_refCount);
end;

// --  --
function unaMsAcmDriver.sendDriverMessage(msg: UINT; lParam1, lParam2: Integer): Longint;
begin
  if (f_isInstallable) then
    result := MMSystem.sendDriverMessage(f_handle, msg, lParam1, lParam2)
  else
    result := acm_driverMessage(getHandle(), msg, lParam1, lParam2);  
end;

// --  --
procedure unaMsAcmDriver.setEnabled(value: bool);
begin
  if (mmNoError(acm_driverPriority(f_handle, 0 {no change}, choice(value, uint(ACM_DRIVERPRIORITYF_ENABLE), ACM_DRIVERPRIORITYF_DISABLE)))) then
    //
    if (0 < getDetails().cbStruct) then
      acm_metrics(f_handle, ACM_METRIC_DRIVER_SUPPORT, getDetails().fdwSupport);
end;

// --  --
procedure unaMsAcmDriver.setPriority(value: unsigned);
begin
  acm_driverPriority(f_handle, value, 0);
end;

// --  --
function unaMsAcmDriver.suggestCodecFormat(srcFormat: pWAVEFORMATEX; dstFormat: pWAVEFORMATEX; flags: uint): MMRESULT;
var
  drvSuggest: ACMDRVFORMATSUGGEST;
begin
  if (f_isInstallable) then begin
    //
    with drvSuggest do begin
      //
      cbStruct := sizeof(ACMDRVFORMATSUGGEST);
      pwfxSrc := srcFormat;		// Source Format
      cbwfxSrc := sizeof(WAVEFORMATEX) + choice(WAVE_FORMAT_PCM = srcFormat.wFormatTag, int(0), srcFormat.cbSize);		// Source Size
      pwfxDst := dstFormat;		// Dest format
      cbwfxDst := sizeof(WAVEFORMATEX) + choice(WAVE_FORMAT_PCM = dstFormat.wFormatTag, int(0), dstFormat.cbSize);		// Dest Size
      //
      pwfxDst.nSamplesPerSec := pwfxSrc.nSamplesPerSec;
      fdwSuggest := flags or ACM_FORMATSUGGESTF_NSAMPLESPERSEC;		// Suggest flags
    end;
    //
    result := sendDriverMessage(ACMDM_FORMAT_SUGGEST, int(@drvSuggest), 0);
  end
  else begin
    //
    dstFormat.nSamplesPerSec := srcFormat.nSamplesPerSec;
    dstFormat.nChannels := srcFormat.nChannels;
    result := acm_formatSuggest(f_handle, srcFormat, dstFormat, sizeof(WAVEFORMATEX) + choice(WAVE_FORMAT_PCM = dstFormat.wFormatTag, -2, dstFormat.cbSize), flags or ACM_FORMATSUGGESTF_NSAMPLESPERSEC or ACM_FORMATSUGGESTF_NCHANNELS);
  end;
end;


  { unaMsAcm }

// --  --
procedure unaMsAcm.addEnumedDriver(id: HACMDRIVERID; support: unsigned);
begin
  f_drivers.add(unaMsAcmDriver.create(self, id, support));
end;

// --  --
procedure unaMsAcm.closeDriver(driver: unaMsAcmDriver);
begin
  if (nil <> driver) then begin
    //
    driver.refInc(-1);
    //
    if (0 = driver.refInc(0)) then begin
      //
      MMSystem.closeDriver(driver.id, 0, 0);
      f_drivers.removeItem(driver);
    end;
  end;
end;

// --  --
constructor unaMsAcm.create();
begin
  inherited;
  //
  f_version := acm_getVersion();
  f_drivers := unaObjectList.create();
end;

// --  --
destructor unaMsAcm.Destroy();
begin
  inherited;
  //
  freeAndNil(f_drivers);
end;

// --  --
function myDriverEnumCB(hadid: HACMDRIVERID; dwInstance: DWORD; fdwSupport: DWORD): Windows.BOOL; stdcall;
begin
  unaMsAcm(dwInstance).addEnumedDriver(hadid, fdwSupport);
  result := true;
end;

procedure unaMsAcm.enumDrivers(flags: uint);
begin
  f_drivers.clear();
  acm_driverEnum(myDriverEnumCB, UintPtr(self), flags);
end;

// --  --
function unaMsAcm.getAcmCount(index: integer): unsigned;
begin
  acm_metrics(0, index, result);
end;

// --  --
function unaMsAcm.getDriver(index: unsigned): unaMsAcmDriver;
begin
  result := unaMsAcmDriver(f_drivers[index]);
end;

// --  --
function unaMsAcm.getDriver(mid, pid: unsigned): unaMsAcmDriver;
var
  i: int;
begin
  result := nil;
  i := 0;
  while (i < f_drivers.count) do begin
    //
    result := getDriver(i);
    if ((result.getDetails().wMid = mid) and (result.getDetails().wPid = pid)) then begin
      // got it!
      break;
    end
    else
      result := nil;
    //
    inc(i);
  end;
end;

// --  --
function unaMsAcm.getDriverByFormatTag(formatTag: unsigned): unaMsAcmDriver;
var
  i: int;
  f: unaMsAcmFormatTag;
  u: unsigned;
  ok: bool;
begin
  if (WAVE_FORMAT_PCM = formatTag) then
    result := getDriver(MM_MICROSOFT, MM_MSFT_ACM_PCM)
  else begin
    //
    result := nil;
    i := 0;
    while (i < f_drivers.count) do begin
      //
      result := getDriver(i);
      result.enumFormats(0, false, nil, true);
      u := 0;
      ok := false;
      while (u < result.getFormatTagCount()) do begin
	//
	f := result.getFormatTag(u);
	if (formatTag = f.tag.dwFormatTag) then begin
	  //
	  ok := true;
	  break;
	end;
	//
	inc(u);
      end;
      //
      if (ok) then
	break
      else
	result := nil;
      //
      inc(i);
    end;
  end;
end;

// --  --
function unaMsAcm.getDriverCount(): unsigned;
begin
  result := f_drivers.count;
end;

// --  --
function unaMsAcm.openDriver(const driverLibrary: wString): unaMsAcmDriver;
var
  handle: hdrvr;
begin
  result := nil;
  handle := MMSystem.openDriver(pwChar(driverLibrary), nil, 0);
  //
  if (0 <> handle) then begin
    //
    result := unaMsAcmDriver.create(self, handle, 0, driverlibrary);
    result.refInc(1);
    f_drivers.add(result);
  end;
end;

// --  --
function unaMsAcm.preparePafd(var pafd: ACMFORMATDETAILS; tag, index: unsigned; driver: unsigned): bool;
var
  size: unsigned;
begin
  fillChar(pafd, sizeof(ACMFORMATDETAILS), #0);
  pafd.cbStruct := sizeof(ACMFORMATDETAILS);
  pafd.dwFormatIndex := index;
  pafd.dwFormatTag := tag;
  //
  size := max(sizeOf(WAVEFORMATEX), getMaxWaveFormatSize(driver));
  pafd.pwfx := malloc(size, true);
  pafd.cbwfx := size;
  //
  result := true;
end;


  { unaMsAcmDeviceHeader }

// --  --
procedure unaMsAcmDeviceHeader.AfterConstruction();
begin
  inherited;
  //
  //f_gate := unaInProcessGate.create();
end;

// --  --
procedure unaMsAcmDeviceHeader.BeforeDestruction();
begin
  if (enter(100)) then
    try
      unprepare();
    finally
      leave();
    end;
  //
  //freeAndNil(f_gate);
  //
  inherited;
end;

// --  --
constructor unaMsAcmDeviceHeader.create(device: unaMsAcmStreamDevice);
begin
  inherited create();
  //
  f_device := device;
  f_needRePrepare := true;
  f_isFree := true;
end;

// --  --
function unaMsAcmDeviceHeader.enter(timeout: tTimeout): bool;
begin
  result := acquire(false, timeout); //f_gate.enter(timeout);
end;

// --  --
procedure unaMsAcmDeviceHeader.leave();
begin
  //f_gate.leave();
  release({$IFDEF DEBUG }false{$ENDIF DEBUG });
end;

// --  --
function unaMsAcmDeviceHeader.prepare(): MMRESULT;
begin
  if (nil <> f_device) then
    result := f_device.prepareHeader(self)
  else
    result := MMSYSERR_NODRIVER;
end;

// --  --
procedure unaMsAcmDeviceHeader.rePrepare();
begin
{$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
{$ELSE }
  if (f_needRePrepare) then
    if (nil <> f_device) then
      f_num := unsigned(f_device.getNextHeaderNum());
  //
  f_needRePrepare := true;
  f_isFree := false;
{$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
end;

// --  --
function unaMsAcmDeviceHeader.unprepare(): MMRESULT;
begin
  if (nil <> f_device) then
    result := f_device.unprepareHeader(self)
  else
    result := MMSYSERR_NODRIVER;
end;


  { unaMsAcmStreamDevice }

// --  --
function unaMsAcmStreamDevice.addConsumer(device: unaMsAcmStreamDevice; removeOutStream: bool): unsigned;
begin
  if (acquire(false, 1000)) then try
    //
    if ((nil <> device) and (0 > f_consumers.indexOf(device))) then begin
      //
      device.addNotification(self);
      result := f_consumers.add(device);
    end
    else
      result := high(unsigned);
    //
    if (removeOutStream) then
      assignStream(false, nil, false{, true});
  finally
    releaseWO();
  end
  else
    result := unsigned(-1);
end;

// --  --
procedure unaMsAcmStreamDevice.addNotification(device: unaMsAcmStreamDevice);
begin
  f_notifyDevices.add(device);
end;

{$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
{$ELSE }

// --  --
function unaMsAcmStreamDevice.adjustLastDoneHeaderNum(num: unsigned): bool;
asm
//	IN:	EAX = Self
//		EDX = num
//
//	OUT:	EAX = result
//
	mov	ecx, eax	// self
	mov	eax, edx	// num
	dec	eax

	cmp	dword ptr [ecx + f_outOverCN - 8], $160
	jbe	@below

  lock	cmpxchg [ecx + f_lastDoneHeaderNum], edx

	inc	eax

  @below:
	cmp	eax, edx
	setz	al
	cbw
	cwde			// improtant, since bool is longBool
end;

{$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }

// --  --
function unaMsAcmStreamDevice.adjustVolume100(buf: pointer; size: unsigned; format: PWAVEFORMATEXTENSIBLE): unsigned;
var
  i: int;
  //volume: unsigned;
  nChannels: unsigned;
  samples: unsigned;
begin
  result := 0;
  //
  if (nil <> format) then begin
    //
    nChannels := format.Format.nChannels;
    if (f_needVolumeAdjust and (0 < nChannels)) then begin
      //
      if ((0 < format.Format.wBitsPerSample) and (0 < nChannels)) then
	samples := (size shl 3) div (format.Format.wBitsPerSample * nChannels)
      else
	samples := 0;
      //
      if (0 < samples) then begin
	//
	// adjust volume as necessary
	for i := 0 to nChannels - 1 do
	  result := waveModifyVolume100(f_setVolume[i], buf, samples, format.Format.wBitsPerSample, nChannels, i);
	//
      end;
    end;
  end;
end;

// --  --
procedure unaMsAcmStreamDevice.afterClose(closeResult: MMRESULT);
begin
  fillChar(f_volume, sizeOf(f_volume), #0);
end;

// --  --
procedure unaMsAcmStreamDevice.AfterConstruction();
var
  i: int;
begin
  f_minVL := 0;
  f_minAT := 100;
  //
  vad1_init(f_3gppvad1);
  //
  {$IFDEF UNA_VC_ACMCLASSES_USE_DSP }
  //
  f_dspl := unaDspDLibRoot.create();
  f_dsplAutoLD := unaDSPLibAutomat.create(f_dspl);
  f_dsplAutoND := unaDSPLibAutomat.create(f_dspl);
  //
  f_dsplObjLD := f_dsplAutoLD.dspl_objNew(DSPL_OID or DSPL_LD);
  f_dsplObjND := f_dsplAutoND.dspl_objNew(DSPL_OID or DSPL_ND);
  {$ENDIF UNA_VC_ACMCLASSES_USE_DSP }
  //
  f_sdm := unasdm_none;
  //
  for i := low(f_setVolume) to high(f_setVolume) do
    f_setVolume[i] := 100;
end;

// --  --
function unaMsAcmStreamDevice.afterOpen(): MMRESULT;
{$IFDEF UNA_VC_ACMCLASSES_USE_DSP }
var
  fmtExt: PWAVEFORMATEXTENSIBLE;
{$ENDIF UNA_VC_ACMCLASSES_USE_DSP }
begin
  f_inBytes := 0;
  f_outBytes := 0;
  //
  f_isSilence := true;
  f_isSilenceFirstTime := true;
  //
  {$IFDEF UNA_VC_ACMCLASSES_USE_DSP }
  fmtExt := PWAVEFORMATEXTENSIBLE(choice(getMasterIsSrc(), f_srcFormatExt, f_dstFormatExt));
  if (nil <> fmtExt) then begin
    //
    if (not formatIsPCM(fmtExt)) then
      // try other format
      fmtExt := PWAVEFORMATEXTENSIBLE(choice(not getMasterIsSrc(), f_srcFormatExt, f_dstFormatExt));
    //
    if (nil <> fmtExt) then begin
      //
      with (fmtExt.format) do begin
	//
	f_dsplAutoLD.setFormat(nSamplesPerSec, wBitsPerSample, nChannels);
	f_dsplAutoND.setFormat(nSamplesPerSec, wBitsPerSample, nChannels);
	//
	f_dsplAutoND.dspl_obj_setf(f_dsplObjND, DSPL_PID or DSPL_P_NFRQ or DSPL_ND_SAMPLE_RATE, nSamplesPerSec);
      end;
    end;
  end;
  //
  f_outBufValid := false;
  {$ENDIF UNA_VC_ACMCLASSES_USE_DSP }
  //
  result := MMSYSERR_NOERROR;
end;

// --  --
function unaMsAcmStreamDevice.assignStream(isInStream: bool; stream: unaAbstractStream; careDestroy: bool): unaAbstractStream;
begin
  if (acquire(false, 1000, false {$IFDEF DEBUG }, '.assignStream()' {$ENDIF DEBUG })) then try
    //
    destroyStream(isInStream);
    //
    if (isInStream) then begin
      //
      f_inStream := stream;
      if (nil <> stream) then
        f_inStreamIsunaMemoryStream := (stream is unaMemoryStream)
      else
        f_inStreamIsunaMemoryStream := false;
      //
      f_careInStreamDestroy := careDestroy;
    end
    else begin
      //
      f_outStream := stream;
      if (nil <> stream) then
        f_outStreamIsunaMemoryStream := (stream is unaMemoryStream)
      else
        f_outStreamIsunaMemoryStream := false;
      //
      f_careOutStreamDestroy := careDestroy;
    end;
    //
    result := stream;
  finally
    releaseWO();
  end
  else
    result := nil;
end;

// --  --
function unaMsAcmStreamDevice.assignStream(streamClass: unaAbstractStreamClass; isInStream: bool; careDestroy: bool): unaAbstractStream;
begin
  result := assignStream(isInStream, streamClass.create(), careDestroy);
end;

// --  --
procedure unaMsAcmStreamDevice.BeforeDestruction();
begin
  close();	// close device before terminating the main thread
  //
  notifyRemove();
  //
  inherited;
  //
  if ((nil <> inStream) and (inStream is unaMemoryStream)) then
    inStream.clear();
  //
  if ((nil <> outStream) and (outStream is unaMemoryStream)) then
    outStream.clear();
  //
  {$IFDEF UNA_VC_ACMCLASSES_USE_DSP }
  //
  freeAndNil(f_dsplAutoLD);
  freeAndNil(f_dsplAutoND);
  freeAndNil(f_dspl);
  {$ENDIF UNA_VC_ACMCLASSES_USE_DSP }
  //
  freeAndNil(f_deviceEvent);
  //
  mrealloc(f_channelMixBuf);
  mrealloc(f_channelMixBufEx);
  //
  mrealloc(f_channelConsumeBuf);
  mrealloc(f_channelConsumeBufEx);
  //
  vad1_exit(f_3gppvad1);
end;

// --  --
function unaMsAcmStreamDevice.beforeNewChunk(data: pointer; size: unsigned; formatExt: PWAVEFORMATEXTENSIBLE): bool;
var
  bits: unsigned;
  nc: unsigned;
  i: unsigned;
begin
  if (formatIsPCM(formatExt) and calcVolume and (0 < size)) then begin
    //
    // 1. remember and adjust volume (if needed)
    nc := formatExt.format.nChannels;
    bits := formatExt.format.wBitsPerSample;
    if (0 < nc) then begin
      //
      for i := 0 to nc - 1 do
        f_unVolume[i] := waveGetVolume(data, (size shl 3) div (bits * nc), bits, nc, i);
    end;
    //
    adjustVolume100(data, size, formatExt);
    //
    // 2. calculate volume
    if (0 < nc) then begin
      //
      for i := 0 to nc - 1 do begin
	//
	f_prevVolume[i] := f_volume[i];
	f_volume[i] := waveGetVolume(data, (size shl 3) div (bits * nc), bits, nc, i);
      end;
    end;
  end;
  //
  result := checkSilence(data, size, formatExt);
end;

// --  --
function unaMsAcmStreamDevice.checkSilence(data: pointer; len: unsigned; formatExt: PWAVEFORMATEXTENSIBLE): bool;
var
  i: unsigned;
  isBelow: bool;
  nCh: unsigned;
  {$IFDEF UNA_VC_ACMCLASSES_USE_DSP }
  nSamples, sz: unsigned;
  c, s: int;
  fp: dspl_float;
  son: bool;
  dataF: pdspl_float;
  maxS: float;
  {$ENDIF UNA_VC_ACMCLASSES_USE_DSP }
begin
  case (silenceDetectionMode) of

    unasdm_VC: begin
      //
      if (nil <> formatExt) then
	nCh := formatExt.format.nChannels
      else
	nCh := 0;
      //
      if (formatIsPCM(formatExt) and (0 < nCh)) then begin
	//
	result := true;
	if (calcVolume and (0 < f_minVL)) then begin
	  //
	  // check if minimum time has been passed
	  if ((0 = f_timeActive) or (GetTickCount() - f_timeActive > f_minAT)) then begin
	    //
	    isBelow := true;
	    //
	    for i := 0 to nCh - 1 do begin
	      //
	      if (getVolume(i) >= f_minVL) then begin
		// we have found loud enough channel
		isBelow := false;
		break;
	      end;
	    end;
	    //
	    // check if we need to turn on recording stream
	    if (isSilence and not isBelow) then begin
	      // initializate timer and restore stream flow
	      f_timeActive := 0;
	      f_isSilence := false;
	    end;
	    //
	    // check if we need to turn off recording stream
	    if (not isSilence and isBelow) then begin
	      //
	      // if timer was not activated
	      if (0 = f_timeActive) then
		// activate timer
		f_timeActive := GetTickCount()
	      else begin
		// stop timer, stop stream
		f_timeActive := 0;
		f_isSilence := true;
	      end;
	    end;
	    //
	    if ((f_isSilenceFirstTime or (f_isSilence <> f_isSilencePrev)) and assigned(f_onThreshold)) then begin
	      //
	      f_isSilenceFirstTime := false;
	      f_isSilencePrev := f_isSilence;
	      //
	      f_passThrough := not f_isSilence;
	      f_onThreshold(self, f_passThrough);
	      //
	      result := f_passThrough;
	    end
	    else begin
	      //
	      // -- block or allow this chunk --
	      result := not isSilence;
	    end;
	    //
	  end
	end
	else begin
	  // make sure timer is stopped
	  f_timeActive := 0;
	  f_isSilence := false;
	  //
	  if ((f_isSilence <> f_isSilencePrev) and assigned(f_onThreshold)) then begin
	    //
	    f_isSilencePrev := f_isSilence;
	    f_onThreshold(self, f_isSilence);
	  end;
	end;
	//
      end
      else begin
	// assume no silence
	f_isSilence := false;
	result := true;
      end;
    end;

    unasdm_DSP: begin
      //
    {$IFDEF UNA_VC_ACMCLASSES_USE_DSP }
      if (nil <> formatExt) then
	nCh := formatExt.format.nChannels
      else
	nCh := 0;
      //
      if (formatIsPCM(formatExt) and (0 < nCh)) then begin
	//
	// pass chunk to LD
	f_dsplAutoLD.processChunk(data, len, -1, -1, false);	// not interested in output to be placed into data buffer
	f_dsplAutoND.processChunk(data, len, -1, -1, false);	// not interested in output to be placed into data buffer
	//
	// check if we have the output buffers
	if (not f_outBufValid) then begin
	  //
	  for c := 0 to nCh - 1 do begin
	    //
	    f_dsplAutoLD.getOutData(c, f_dsplOutBufLD[c], f_dsplOutBufLDSize[c]);
	    f_dsplAutoND.getOutData(c, f_dsplOutBufND[c], f_dsplOutBufNDSize[c]);
	  end;
	  //
	  f_outBufValid := true;
	end;
	//
	// check if we need to pass only non-noise signal
	f_isSilence := true;
	//
	// calculate mean LD and ND values
	if (f_dsplOutBufLDSize[0] = f_dsplOutBufNDSize[0]) then begin
	  //
	  for c := 0 to nCh - 1 do begin
	    //
	    if (DSPL_SUCCESS = f_dsplAutoND.dspl_obj_getf(f_dsplObjND, c, DSPL_PID or DSPL_P_OUT, fp)) then begin
	      //
	      // -- calculate mean level of chunk --
	      //
	      // plotResult( f_dsplOutBufLD[c]       fp,               f_dsplOutBufLDSize[0] );
	      //             data: pdspl_float;      ND: dspl_float;   len: uint;
	      maxS := 0.0;
	      dataF := f_dsplOutBufLD[c];
	      if (0 < f_dsplOutBufLDSize[c]) then begin
		//
		for s := 0 to f_dsplOutBufLDSize[c] - 1 do begin
		  //
		  if (maxS < dataF^) then
		    maxS := dataF^;
		  //
		  inc(dataF);
		end;
	      end;
	      //
	      son := (maxS > fp);
	    end
	    else
	      son := true;	// some DSP error, assume signal is over noise
	    //
	    if (son) then begin
	      //
	      f_isSilence := false;	// at least in one channel
	      break;
	    end;
	  end;	// for [c] all channels
	end
	else
	  ; //should not be here
	//
	if ((f_isSilenceFirstTime or (f_isSilence <> f_isSilencePrev)) and assigned(f_onThreshold)) then begin
	  //
	  f_isSilenceFirstTime := false;
	  f_isSilencePrev := f_isSilence;
	  //
	  f_passThrough := not f_isSilence;
	  f_onThreshold(self, f_passThrough);
	  //
	  result := f_passThrough;
	end
	else begin
	  //
	  // -- block or allow this chunk --
	  result := not isSilence;
	end;
      end
      else begin
	// assume no silence
	f_isSilence := false;
	result := true;
      end;
    {$ELSE }
      // no silence
      f_isSilence := false;
      result := true;
    {$ENDIF UNA_VC_ACMCLASSES_USE_DSP }
    end; // unasdm_DSP

    unasdm_3GPPVAD1: begin
      //
      if (nil <> formatExt) then
	nCh := formatExt.format.nChannels
      else
	nCh := 0;
      //
      if (formatIsPCM(formatExt) and (0 < nCh) and (8 <= formatExt.format.wBitsPerSample)) then begin
	//
	f_isSilence := true;
	sz := (formatExt.format.wBitsPerSample shr 3) * nCh;	// size of 1 sample in bytes
	repeat
	  // check if we have enough samples
	  nSamples := len div sz;
	  if (una3GPPVAD.FRAME_LEN <= nSamples) then begin
	    //
	    if ((1 < nCh) or (8000 <> formatExt.format.nSamplesPerSec) or (16 <> formatExt.format.wBitsPerSample)) then
	      waveResample(data, @f_3gppvad1_buf, una3GPPVAD.FRAME_LEN, nCh, 1, formatExt.format.wBitsPerSample, 16, formatExt.format.nSamplesPerSec, 8000)
	    else
	      move(data^, f_3gppvad1_buf, una3GPPVAD.FRAME_LEN);
	    //
	    if (vad1(f_3gppvad1^, pWord16array(@f_3gppvad1_buf))) then begin
	      //
	      f_isSilence := false;
	      break;
	    end
	    else begin
	      //
	      if (una3GPPVAD.FRAME_LEN * sz shl 1 <= len) then begin
		//
		dec(len, una3GPPVAD.FRAME_LEN * sz);
		data := @pArray(data)[sz];
	      end
	      else
		break;	// no more data
	    end;
	  end
	  else
	    break; // exit loop
	  //
	until (false);
	//
      end
      else
	// assume no silence
	f_isSilence := false;
      //
      // cooldown
      //
      if (f_vad_prev and f_isSilence) then begin
	//
	if (0 = f_vad_cooldown) then begin
	  //
	  f_vad_cooldown := 21;	// 20 * 20ms = 200ms
	  f_isSilence := false;	// override vad
	end
	else begin
	  //
	  if (1 < f_vad_cooldown) then begin
	    //
	    dec(f_vad_cooldown);
	    f_isSilence := false;	// override vad
	  end
	  else begin
	    //
	    f_vad_prev := false;
	  end;
	end;
      end
      else begin
	//
	f_vad_prev := not f_isSilence;
	//
	if (not f_isSilence) then
	  f_vad_cooldown := 0;
      end;
      //
      result := not f_isSilence;
    end; // unasdm_3GPPVAD1

    else begin
      // assume no silence
      f_isSilence := false;
      result := true;
    end;

  end; // case
end;

// --  --
procedure unaMsAcmStreamDevice.clearHeaders();
var
{$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
  i: int;
{$ELSE }
  header: unaMsAcmDeviceHeader;
  notFound: bool;
{$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
begin
{$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
  i := high(f_headers);
  while (0 <= i) do begin
    //
    if (nil <> f_headers[i]) then
      removeHeader(f_headers[i]);
    //
    dec(i);
  end;
  //
  f_nextHdr := 0;
  //
{$ELSE }
  if (nil <> f_headers) then begin
    //
    while (0 < f_headers.count) do begin
      //
      notFound := false;
      //
      if (lockNonEmptyList_r(f_headers, false, 100)) then begin
	//
	try
	  header := locateHeader();
	  if (nil = header) then
	    header := locateHeader(true, true);
	  //
	  if (nil <> header) then
	    f_headers.removeItem(header)
	  else
	    notFound := true;
	  //
	finally
	  unlockListWO(f_headers);
	end;
      end;
      //
      if (notFound and (0 < f_headers.count)) then
	sleepThread(10);
    end;
  end;
{$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
end;

// --  --
function unaMsAcmStreamDevice.close(timeout: tTimeout): MMRESULT;
begin
  // BCB stub
  result := close2(timeout);
end;

// --  --
function unaMsAcmStreamDevice.close2(timeout: tTimeout): MMRESULT;
begin
  if (acquire(false, timeout, false {$IFDEF DEBUG }, '.close2()' {$ENDIF DEBUG })) then try
    //
    if (isOpen()) then begin
      //
      // 0. clear buffered data if needed
      flush(flushBeforeClose);
      //
      f_closing := true;
      f_openDone := false;
      //
      // 1. -- stop thread cycle
      stop(timeout);
      //
      try
	clearHeaders();
      except
      end;
      //
      // 2. -- close device
      f_openCloseEvent.setState(false);
      //
      result := doClose(timeout);
      if (mmNoError(result)) then begin
	//
	// 3. -- wait for close to complete
	if (f_openCloseEvent.waitFor(timeout)) then begin
	  //
	  // 4. -- close complete
	  result := MMSYSERR_NOERROR
	end
	else begin
	  //
	  {$IFDEF LOG_UNAMSACMCLASSES_INFOS }
	  logMessage(self._classID + '.close2(' + int2str(timeout) + ') - timeout expired');
	  {$ENDIF LOG_UNAMSACMCLASSES_INFOS }
	  //
	  result := MMSYSERR_HANDLEBUSY;	// ?
	end;
	//
	f_handle := 0;
      end
      else begin
	//
	{$IFDEF LOG_UNAMSACMCLASSES_INFOS }
	logMessage(self._classID + '.close2(' + int2str(timeout) + ') fails, code=' + getErrorText(result));
	{$ENDIF LOG_UNAMSACMCLASSES_INFOS }
      end;
      //
      afterClose(result);
      //
      f_closing := false;
    end
    else begin
      //
      if (0 < f_nextHdr) then try
	clearHeaders();
      except
      end;

      result := MMSYSERR_NOERROR;
    end;
    //
  finally
    releaseWO();
  end
  else
    result := MMSYSERR_HANDLEBUSY;	// ?
end;

// --  --
constructor unaMsAcmStreamDevice.create(createInStream: bool; createOutStream: bool; inOverNum: unsigned; outOverNum: unsigned; calcVolume: bool);
begin
  inherited create();
  //
  f_openCloseEvent := unaEvent.create();
  f_deviceEvent := unaEvent.create();
  //
  if (createInStream) then begin
    //
    f_inStream := unaMemoryStream.create(100, {$IFDEF DEBUG }_classID + '(f_inStream)'{$ENDIF DEBUG });
    f_inStreamIsunaMemoryStream := true;
  end;
  //
  if (createOutStream) then begin
    //
    f_outStream := unaMemoryStream.create(100, {$IFDEF DEBUG }_classID + '(f_outStream)'{$ENDIF DEBUG });
    f_outStreamIsunaMemoryStream := true;
  end;
  //
  overNumIn := inOverNum;
  overNumOut := outOverNum;
  //
  f_careInStreamDestroy := true;
  f_careOutStreamDestroy := true;
  //
  f_channelMixMask := -1;
  f_channelConsumeMask := -1;
  //
  f_calcVolume := calcVolume;
  //
{$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
{$ELSE }
  f_headers := unaObjectList.create();
{$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
  //
  f_consumers := unaList.create(uldt_ptr);
  f_notifyDevices := unaList.create(uldt_ptr);
  //f_gate := unaInProcessGate.create({$IFDEF DEBUG }_classID + '(f_gate)'{$ENDIF DEBUG });
end;

// --  --
destructor unaMsAcmStreamDevice.Destroy();
begin
  inherited;
  //
  mrealloc(f_srcFormatExt);
  mrealloc(f_dstFormatExt);
  //
  freeAndNil(f_openCloseEvent);
  //
  destroyStream(true);
  destroyStream(false);
  //
{$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
  clearHeaders();
{$ELSE }
  freeAndNil(f_headers);
{$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
  freeAndNil(f_consumers);
  freeAndNil(f_notifyDevices);
end;

// --  --
procedure unaMsAcmStreamDevice.destroyStream(isInStream: bool);
begin
  if (isInStream and f_careInStreamDestroy) then
    freeAndNil(f_inStream);
  //
  if (not isInStream and f_careOutStreamDestroy) then
    freeAndNil(f_outStream);
end;

// --  --
function unaMsAcmStreamDevice.doClose(timeout: tTimeout): MMRESULT;
begin
  f_openCloseEvent.setState();
  //
  if ((nil <> inStream) and (inStream is unaMemoryStream)) then
    inStream.clear();
  //
  if ((nil <> outStream) and (outStream is unaMemoryStream)) then
    outStream.clear();
  //
  result := MMSYSERR_NOERROR;
end;

// --  --
function unaMsAcmStreamDevice.doGetErrorText(errorCode: MMRESULT): string;
begin
  // by default it uses mmGetErrorCodeTextEx()
  // other devices could have own doGetErrorText() inmplementation
  result := mmGetErrorCodeTextEx(errorCode);
end;

// --  --
function unaMsAcmStreamDevice.doGetPosition(): int64; 
begin
  if (getMasterIsSrc()) then
    // output device
    result := f_inBytes  div (dstFormatExt.format.wBitsPerSample shr 3) div dstFormatExt.format.nChannels
  else
    // input device
    result := f_outBytes div (dstFormatExt.format.wBitsPerSample shr 3) div dstFormatExt.format.nChannels;
end;

// --  --
function unaMsAcmStreamDevice.doOpen(flags: uint): MMRESULT;
begin
{$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
{$ELSE }
  f_lastHeaderNum := 0;//$FFFFFFFE;
  f_lastDoneHeaderNum := 0;//$FFFFFFFE;
{$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
  f_inOverloadTotal := 0;
  //
  if (nil <> inStream) then
    inStream.clear();
  //
  if (nil <> outStream) then
    outStream.clear();
  //
  f_openCloseEvent.setState();
  //
{$IFDEF VCX_DEMO }
  f_headersServed := 0;
{$ENDIF VCX_DEMO }
  //
  result := MMSYSERR_NOERROR;
end;

// --  --
function unaMsAcmStreamDevice.doWrite(buf: pointer; size: unsigned): unsigned;
begin
  internalConsumeData(buf, size);
  //
  result := 0;
  //
  if (isOpen() and (not f_closing or f_flushing)) then begin
    //
    if ((nil <> inStream) and inStream.enter(false, f_waitInterval shl 2)) then begin
      //
      try
	if ((0 < overNumIn) and (inStream.getAvailableSize() > int(f_inOverSize))) then begin
	  //
	  inc(f_inOverloadTotal, size);
	  //
	  // that is not an error, so simply log this case
	  {$IFDEF LOG_UNAMSACMCLASSES_INFOS }
	  logMessage(self._classID + '.write(buf, ' + int2str(size) + ') overload (' + int2str(inStream.getAvailableSize()) + '>' + int2str(f_inOverSize) + ') | total=' + int2Str(f_inOverloadTotal, 10, 3));
	  {$ENDIF LOG_UNAMSACMCLASSES_INFOS }
	end
	else
	  result := inStream.write(buf, size);
	//
      finally
	inStream.leaveWO();
      end;
    end;
  end;
end;

// --  --
function unaMsAcmStreamDevice.flush(waitForComplete: bool): bool;
begin
  // BCB stub
  result := flush2(waitForComplete);
end;

// --  --
function unaMsAcmStreamDevice.flush2(waitForComplete: bool): bool;
begin
  // nothing here
  result := true;
end;

// --  --
function unaMsAcmStreamDevice.formatChoose(var format: pWAVEFORMATEX; const title: wString; style, enumFlag: unsigned; enumFormat: pWAVEFORMATEX): MMRESULT;
begin
  result := unaMsAcmClasses.formatChooseAlloc(format, WAVE_FORMAT_PCM, c_defSamplingSamplesPerSec, title, style, enumFlag, enumFormat);
end;

// --  --
function unaMsAcmStreamDevice.formatChooseDef(var format: pWAVEFORMATEX): MMRESULT;
begin
  // BCB stub
  result := formatChooseDef2(format);
end;

// --  --
function unaMsAcmStreamDevice.formatChooseDef2(var format: pWAVEFORMATEX): MMRESULT;
begin
  result := formatChoose(format, '', choice(nil <> format, unsigned(ACMFORMATCHOOSE_STYLEF_INITTOWFXSTRUCT), 0), 0, nil);
end;

// --  --
function unaMsAcmStreamDevice.getDataAvailable(isIn: bool): unsigned;
begin
{$IFDEF UNA_PROFILE }
  profileMarkEnter(profId_unaMsAcmStreamDevice_getDataAvail);
{$ENDIF UNA_PROFILE }
  if (isIn) then
    if (nil <> inStream) then
      result := inStream.getAvailableSize()
    else
      result := 0
  else
    if (nil <> outStream) then
      result := outStream.getAvailableSize()
    else
      result := 0;
  //
{$IFDEF UNA_PROFILE }
  profileMarkLeave(profId_unaMsAcmStreamDevice_getDataAvail);
{$ENDIF UNA_PROFILE }
end;

// --  --
function unaMsAcmStreamDevice.getDspProperty(isLD: bool; propID: unsigned; const def: float): float;
begin
  {$IFDEF UNA_VC_ACMCLASSES_USE_DSP }
  if (isLD) then
    result := f_dsplAutoLD.root.getf(f_dsplObjLD, propID)
  else
    result := f_dsplAutoND.root.getf(f_dsplObjND, propID);
  //
  {$ELSE }
  result := def;
  {$ENDIF UNA_VC_ACMCLASSES_USE_DSP }
end;

// --  --
function unaMsAcmStreamDevice.getDspProperty(isLD: bool; propID: unsigned; def: int): int;
begin
  {$IFDEF UNA_VC_ACMCLASSES_USE_DSP }
  if (isLD) then
    result := f_dsplAutoLD.root.geti(f_dsplObjLD, propID)
  else
    result := f_dsplAutoND.root.geti(f_dsplObjND, propID);
  {$ELSE }
  result := def;
  {$ENDIF UNA_VC_ACMCLASSES_USE_DSP }
end;

// --  --
function unaMsAcmStreamDevice.getErrorText(errorCode: MMRESULT): string;
begin
  // there is no acmStreamGetErrorText() function
  result := doGetErrorText(errorCode);
end;

// --  --
function unaMsAcmStreamDevice.getMasterIsSrc(): bool;
begin
  // BCB stub
  result := getMasterIsSrc2();
end;

{$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
{$ELSE }

// --  --
function unaMsAcmStreamDevice.getNextHeaderNum(): int;
begin
  result := InterlockedIncrement(f_lastHeaderNum);
end;

{$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }

// --  --
function unaMsAcmStreamDevice.getPrevVolume(channel: unsigned): unsigned;
begin
  result := unsigned(f_prevVolume[channel]);
end;

// --  --
function unaMsAcmStreamDevice.getProviderFormat(): PWAVEFORMATEXTENSIBLE;
var
  device: unaMsAcmStreamDevice;
begin
  if (assigned(f_onGetProviderFormat)) then
    f_onGetProviderFormat(result)
  else begin
    //
    result := nil;
    //
    if (0 < f_notifyDevices.count) then begin
      //
      device := f_notifyDevices[0];
      if (nil <> device) then begin
	//
	if (nil <> device.dstFormatExt) then
	  result := device.dstFormatExt
	else
	  result := device.srcFormatExt;
      end;
    end;
  end;
end;

// --  --
function unaMsAcmStreamDevice.getPosition(): int64;
begin
  result := doGetPosition();
end;

// --  --
function unaMsAcmStreamDevice.getVolume(channel: unsigned): unsigned;
var
  i: int;
  nch: unsigned;
begin
  if ($FFFFFFFF = channel) then begin
    //
    nch := 1;
    if getMasterIsSrc() then begin
      //
      if (nil <> f_srcFormatExt) then
	nch := f_srcFormatExt.Format.nChannels
    end
    else begin
      //
      if (nil <> f_dstFormatExt) then
	nch := f_dstFormatExt.Format.nChannels;
    end;
    //
    result := 0;
    for i := 0 to nch - 1 do
      result := result + f_volume[i];
    //
    result := result div nch;
  end
  else
    result := f_volume[channel and $FF];
end;

// --  --
function unaMsAcmStreamDevice.getUnVolume(channel: unsigned): unsigned;
begin
  result := f_unVolume[channel and $FF];
end;

// --  --
procedure unaMsAcmStreamDevice.internalConsumeData(var buf: pointer; var size: unsigned);
var
  nCh, bits, sz, nsamples, chNum, mask: int;
  f: PWAVEFORMATEXTENSIBLE;
  fillCh: int;
begin
  if (-1 <> channelConsumeMask) then begin
    //
    f := getProviderFormat();
    if (nil <> f) then begin
      //
      nCh := f.Format.nChannels;
      bits := f.Format.wBitsPerSample;
    end
    else begin
      //
      nCh := 1;
      bits := 16;
    end;
    //
    // more than 1 channel and mask is non-zero?
    if ((1 < nCh) and (0 <> channelConsumeMask)) then begin
      //
      sz := int(size) div nCh;
      if (sz > f_channelConsumeBufSize) then begin
	//
	f_channelConsumeBufSize := sz;
	mrealloc(f_channelConsumeBuf, f_channelConsumeBufSize);
	mrealloc(f_channelConsumeBufEx, f_channelConsumeBufSize);
      end;
      //
      if (8 = bits) then
	fillCh := $80
      else
	fillCh := $0;
      //
      fillChar(f_channelConsumeBuf^, f_channelConsumeBufSize, fillCh);
      //
      nsamples := (int(size) div nCh) div (bits shr 3);
      //
      chNum := 0;
      mask := channelConsumeMask;
      while (0 <> mask) do begin
	//
	if (1 = (1 and mask)) then begin
	  //
	  waveExtractChannel(buf, f_channelConsumeBufEx, nsamples, bits, nCh, chNum);
	  waveMix(f_channelConsumeBufEx, f_channelConsumeBuf, f_channelConsumeBuf, nsamples, bits, bits, bits);
	end;
	//
	mask := mask shr 1;
	inc(chNum);
      end;
      //
      // replace values
      buf := f_channelConsumeBuf;
      size := sz;
    end
    else begin
      //
      if (0 = channelConsumeMask) then
	size := 0	// no channels -- no data
      else begin
	//
	// we have 1 channel, let see if it is in the mask
	if (1 <> (channelConsumeMask and 1)) then
	  size := 0	// no luck, even mono channel is not included in the mask -- no data
      end;
    end;
  end;
end;

// --  --
function unaMsAcmStreamDevice.internalRead(buf: pointer; size: unsigned; formatExt: PWAVEFORMATEXTENSIBLE): unsigned;
begin
{$IFDEF UNA_PROFILE }
  profileMarkEnter(profId_unaMsAcmStreamDevice_internalRead);
{$ENDIF UNA_PROFILE }
  if ((0 < size) and (nil <> inStream)) then begin
    //
    result := inStream.read(buf, int(size));
    if (result < size) then
      fillChar(pArray(buf)[result], size - result, #0);
    //
    if (0 < result) then begin
      //
      if (beforeNewChunk(buf, result, formatExt)) then
	// increase number of input bytes
	inc(f_inBytes, result)
      else begin
	//
	inc(f_skipTotal, result);
	result := 0;
      end;
    end;
  end
  else
    result := 0;
{$IFDEF UNA_PROFILE }
  profileMarkLeave(profId_unaMsAcmStreamDevice_internalRead);
{$ENDIF UNA_PROFILE }
end;

// --  --
function unaMsAcmStreamDevice.internalWrite(buf: pointer; size: unsigned; formatExt: PWAVEFORMATEXTENSIBLE): unsigned;
var
  i: int;
  f: PWAVEFORMATEXTENSIBLE;
  nCh, sz, nsamples, fillCh, mask, chNum, bits: int;
begin
{$IFDEF UNA_PROFILE }
  profileMarkEnter(profId_unaMsAcmStreamDevice_internalWrite);
{$ENDIF UNA_PROFILE }
  result := 0;
  //
  if (0 < size) then begin
    //
    if (beforeNewChunk(buf, size, formatExt)) then begin
      //
      if (-1 <> channelMixMask) then begin
	//
	if (nil <> formatExt) then
	  f := formatExt
	else
	  if (nil <> dstFormatExt) then
	    f := dstFormatExt
	  else
	    f := srcFormatExt;
	//
	if (nil <> f) then begin
	  //
	  nCh := f.Format.nChannels;
	  bits := f.Format.wBitsPerSample;
	end
	else begin
	  //
	  nCh := 1;
	  bits := 16;
	end;
	//
	// more than 1 channel and mask is non-zero?
	if ((1 < nCh) and (0 <> channelMixMask)) then begin
	  //
	  sz := int(size) div nCh;
	  if (sz > f_channelMixBufSize) then begin
	    //
	    f_channelMixBufSize := sz;
	    mrealloc(f_channelMixBuf, f_channelMixBufSize);
	    mrealloc(f_channelMixBufEx, f_channelMixBufSize);
	  end;
	  //
	  if (8 = bits) then
	    fillCh := $80
	  else
	    fillCh := $0;
	  //
	  fillChar(f_channelMixBuf^, f_channelMixBufSize, fillCh);
	  //
	  nsamples := (int(size) div nCh) div (bits shr 3);
	  //
	  chNum := 0;
	  mask := channelMixMask;
	  while (0 <> mask) do begin
	    //
	    if (1 = (1 and mask)) then begin
	      //
	      waveExtractChannel(buf, f_channelMixBufEx, nsamples, bits, nCh, chNum);
	      waveMix(f_channelMixBufEx, f_channelMixBuf, f_channelMixBuf, nsamples, bits, bits, bits);
	    end;
	    //
	    mask := mask shr 1;
	    inc(chNum);
	  end;
	  //
	  // replace values, assumes consumers are smart enough to understand there is the only one chnannel
	  buf := f_channelMixBuf;
	  size := sz;
	end
	else begin
	  //
	  if (0 = channelMixMask) then
	    size := 0	// no channels -- no data
	  else begin
	    //
	    // we have 1 channel, let see if it is in the mask
	    if (1 <> (channelMixMask and 1)) then
	      size := 0	// no luck, even mono channel is not included in the mask -- no data
	  end;
	end;
      end;
      //
      // signal onDA event
      if (assigned(f_onDA)) then begin
	//
	f_onDA(self, buf, size);
	result := size;
      end;
      //
      // pass data to consumers
      i := 0;
      while (i < f_consumers.count) do begin
	//
	result := unaMsAcmStreamDevice(f_consumers[i]).write(buf, size);
	//assert(assertLog(self._classID + '.internalWrite() - passed ' + int2str(size) + ' bytes to consumer #' + int2str(i) + ' (' + unaMsAcmStreamDevice(f_consumers[i])._classID + ')'));
	inc(i);
      end;
      //
      // write data into stream (if assigned)
      if (nil <> outStream) then begin
	//
	if ((0 < f_outOverCN) and (outStream.getAvailableSize() > int(f_outOverSize))) then begin
	  //
	  result := 0;
	  inc(f_outOverloadTotal, size);
	  //
	{$IFDEF LOG_UNAMSACMCLASSES_INFOS_EX }
	  logMessage(_classID + '.internalWrite() overload, skipped ' + int2str(size) + ' bytes, stream size = ' + int2str(outStream.getAvailableSize()) + ', total skipped=' + int2str(f_outOverloadTotal, 10, 3));
	{$ENDIF LOG_UNAMSACMCLASSES_INFOS_EX }
	end
	else
	  result := outStream.write(buf, size);
      end;
    end
    else begin
      //
      inc(f_skipTotal, size);
      result := 0;
    end;
  end;
  //
{$IFDEF UNA_PROFILE }
  profileMarkLeave(profId_unaMsAcmStreamDevice_internalWrite);
{$ENDIF UNA_PROFILE }
end;

// --  --
function unaMsAcmStreamDevice.isOpen(): bool;
begin
  result := ((0 <> f_handle) and f_openDone);
end;

{$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
{$ELSE }

// --  --
function unaMsAcmStreamDevice.locateHeader(locateUnused, locateNotInQuery: bool): unaMsAcmDeviceHeader;
var
  i: int;
  ok: bool;
begin
{$IFDEF UNA_PROFILE }
  profileMarkEnter(profId_unaMsAcmStreamDevice_locateHeader);
{$ENDIF UNA_PROFILE }
  result := nil;
  //
  i := 0;
  while (i < f_headers.count) do begin
    //
    result := f_headers[i];
    //
    ok := (0 < f_options) and locateHeaderTry(result, locateUnused, locateNotInQuery);
      //
    if (ok) then begin
{$IFDEF VCX_DEMO }
      inc(f_headersServed);
{$ENDIF VCX_DEMO }
      break
    end
    else
      result := nil;
    //
    inc(i);
  end;
  //
{$IFDEF UNA_PROFILE }
  profileMarkLeave(profId_unaMsAcmStreamDevice_locateHeader);
{$ENDIF UNA_PROFILE }
end;

// --  --
function unaMsAcmStreamDevice.locateHeaderTry(header: unaMsAcmDeviceHeader; locateUnused: bool; locateNotInQuery: bool): bool;
begin
  if ((nil <> header) and (nil <> header.f_device)) then begin
    //
    try
      result := (locateNotInQuery and not header.isInQueue());
      //
      if (not result and header.isDoneHeader()) then begin
	//
	if (locateUnused) then
	  result := header.isFree
	else
	  result := adjustLastDoneHeaderNum(header.f_num);
      end;
      //
    except
      // some soundcards may trash the header
      result := false;
    end;
  end
  else
    result := false;
end;

{$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }

// --  --
procedure unaMsAcmStreamDevice.notifyRemove();
var
  i: int;
begin
  i := 0;
  while (i < f_notifyDevices.count) do begin
    //
    unaMsAcmStreamDevice(f_notifyDevices[i]).removeConsumer(self);
    inc(i);
  end;
  //
  i := 0;
  while (i < f_consumers.count) do begin
    //
    unaMsAcmStreamDevice(f_consumers[i]).removeNotification(self);
    inc(i);
  end;
end;

// --  --
function unaMsAcmStreamDevice.okToRead(): bool;
begin
  result := (0 < getDataAvailable(false))
end;

// --  --
function unaMsAcmStreamDevice.open(query: bool; timeout: tTimeout; flags: uint; startDevice: bool): MMRESULT;
begin
  // stub for BCB
  result := open2(query, timeout, flags, startDevice);
end;

// --  --
function unaMsAcmStreamDevice.open2(query: bool; timeout: tTimeout; flags: uint; startDevice: bool): MMRESULT;
begin
  if (acquire(false, 1100, false {$IFDEF DEBUG }, '.open2()' {$ENDIF DEBUG } )) then try
    //
    if (not isOpen()) then begin

      // 1. -- open device
      f_openCloseEvent.setState(false);
      result := doOpen(flags);
      //
      if (mmNoError(result)) then begin
        //
        if (not query) then begin
          //
          // 2. -- wait for open to complete
          if (f_openCloseEvent.waitFor(timeout)) then begin
            //
            // 3. -- do after open initialization
            {$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
            {$ELSE }
            f_headers.clear();
            {$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
            //
            result := afterOpen();
            if (mmNoError(result)) then begin
              //
              f_openDone := true;
              //
              // 4. -- start thread cycle
              if (startDevice) then
                start();
              //
            end
            else begin
              //
              {$IFDEF LOG_UNAMSACMCLASSES_ERRORS }
              logMessage(self._classID + '.open2() fails, code=' + getErrorText(result));
              {$ENDIF LOG_UNAMSACMCLASSES_ERRORS }
            end;
            //
          end
          else begin
            //
            close();
            result := MMSYSERR_HANDLEBUSY;	//
            //
            {$IFDEF LOG_UNAMSACMCLASSES_INFOS }
            logMessage(self._classID + '.open2(' + int2str(timeout) + ') timeout expired');
            {$ENDIF LOG_UNAMSACMCLASSES_INFOS }
          end;
          //
        end
        else
          // just a query - do nothing
          ;
      end
      else begin
        //
        f_handle := 0;
        //
        {$IFDEF LOG_UNAMSACMCLASSES_ERRORS }
        logMessage(self._classID + '.open2() fails, code=' + getErrorText(result));
        {$ENDIF LOG_UNAMSACMCLASSES_ERRORS }
      end;
      //
    end
    else
      result := MMSYSERR_NOERROR;
    //
  finally
    releaseWO();
  end
  else
    result := MMSYSERR_HANDLEBUSY;	//
end;

// --  --
function unaMsAcmStreamDevice.read(buf: pointer; size: unsigned): unsigned;
begin
  result := 0;
  //
  if (nil <> outStream) then begin
    //
    if (0 = size) then begin
      //
      if (f_outStreamIsunaMemoryStream) then
	result := outStream.read(buf, unaMemoryStream(outStream).firstChunkSize())
    end
    else
      result := outStream.read(buf, int(size));
  end;
end;

// --  --
function unaMsAcmStreamDevice.removeConsumer(device: unaMsAcmStreamDevice): bool;
begin
  if (acquire(false, 1000)) then try
    //
    if (nil <> device) then
      device.removeNotification(self);
    //
    result := f_consumers.removeItem(device);
  finally
    releaseWO();
  end
  else
    result := false;
end;

// --  --
procedure unaMsAcmStreamDevice.removeNotification(device: unaMsAcmStreamDevice);
begin
  f_notifyDevices.removeItem(device);
end;

// --  --
procedure unaMsAcmStreamDevice.setCalcVolume(const Value: bool);
begin
  f_calcVolume := Value;
  f_savedCV := value;	// override values saved by other devices,
			// so they will not change CV when restoring it
end;

// --  --
procedure unaMsAcmStreamDevice.setDspProperty(isLD: bool; propID: unsigned; const value: float);
begin
  {$IFDEF UNA_VC_ACMCLASSES_USE_DSP }
  if (isLD) then
    f_dsplAutoLD.root.setf(f_dsplObjLD, propID, value)
  else
    f_dsplAutoND.root.setf(f_dsplObjND, propID, value);
  //
  {$ENDIF UNA_VC_ACMCLASSES_USE_DSP }
end;

// --  --
procedure unaMsAcmStreamDevice.setDspProperty(isLD: bool; propID: unsigned; value: int);
begin
  {$IFDEF UNA_VC_ACMCLASSES_USE_DSP }
  if (isLD) then
    f_dsplAutoLD.root.seti(f_dsplObjLD, propID, value)
  else
    f_dsplAutoND.root.seti(f_dsplObjND, propID, value);
  {$ENDIF UNA_VC_ACMCLASSES_USE_DSP }
end;

// --  --
function unaMsAcmStreamDevice.setFormat(isSrc: bool; const format: aString): bool;
var
  wFormat: pWAVEFORMATEX;
begin
  str2waveFormat(format, wFormat);
  try
    result := setFormat(isSrc, wFormat);
  finally
    mrealloc(wFormat);
  end;
end;

// --  --
function unaMsAcmStreamDevice.setFormat(isSrc: bool; format: pWAVEFORMATEX): bool;
var
  value: unsigned;
  perSec: unsigned;
  blockAlign: unsigned;
  cps: unsigned;
  //
  wFormatExt: PWAVEFORMATEXTENSIBLE;
  isPCM: bool;
begin
  if (acquire(false, 1000, false {$IFDEF DEBUG }, '.setFormat()' {$ENDIF DEBUG })) then try
    //
    if (isSrc) then begin
      //
      //mrealloc(f_srcFormatEx);
      fillFormatExt(f_srcFormatExt, format);
      wFormatExt := f_srcFormatExt;
      f_srcFormatInfo := format2str(format^);
    end
    else begin
      //
      //mrealloc(f_dstFormat);
      fillFormatExt(f_dstFormatExt, format);
      wFormatExt := f_dstFormatExt;
      f_dstFormatInfo := format2str(format^);
    end;
    //
    isPCM := formatIsPCM(format);
    //
    if (isPCM or (0 = wFormatExt.format.nAvgBytesPerSec)) then
      perSec := (max(1000, wFormatExt.format.nSamplesPerSec) * max(unsigned(1), wFormatExt.format.nChannels) * max(unsigned(8), wFormatExt.format.wBitsPerSample)) shr 3
    else
      perSec := wFormatExt.format.nAvgBytesPerSec;
    //
    if ((11025 = perSec) and (50 = c_defChunksPerSecond)) then
      cps := 49
    else
      cps := c_defChunksPerSecond;
    //
    if (isPCM) then begin
      //
      if (isSrc = getMasterIsSrc()) then begin
        //
        f_chunkPerSecond := cps;
        //
        if (gcd(perSec, f_chunkPerSecond) <> f_chunkPerSecond) then begin
          //
          f_chunkPerSecond := c_defChunksPerSecond;
          // make sure perSec will divide at least on 5
          if (1 = gcd(perSec, 5)) then
            perSec := ((perSec + 4) div 5) * 5;
          //
          while ((f_chunkPerSecond > 5) and
                 ((gcd(perSec, f_chunkPerSecond) <> f_chunkPerSecond) or
                  (gcd(1000, f_chunkPerSecond) <> f_chunkPerSecond))
                ) do begin
            //
            dec(f_chunkPerSecond);
          end;
        end;
        //
        cps := f_chunkPerSecond;
      end;
    end
    else
      if (isSrc = getMasterIsSrc()) then
        f_chunkPerSecond := cps;
    //
    blockAlign := wFormatExt.format.nBlockAlign;
    if (0 = blockAlign) then
      blockAlign := 128;
    //
    value := ((perSec div cps + blockAlign - 1) div blockAlign) * blockAlign;
    //
    if (isSrc = getMasterIsSrc()) then
      f_chunkSize := value
    else
      f_dstChunkSize := value;
    //
    if (isSrc) then
      f_inOverSize := overNumIn * value
    else
      f_outOverSize := overNumOut * value;
    //
    result := true;
  finally
    releaseWO();
  end
  else
    result := false;
end;

// --  --
function unaMsAcmStreamDevice.setFormatExt(isSrc: bool; formatExt: PWAVEFORMATEXTENSIBLE): bool;
var
  fmt: pWAVEFORMATEX;
begin
  fmt := nil;
  try
    if (waveExt2wave(formatExt, fmt, true)) then begin
      //
      result := setFormat(isSrc, pWAVEFORMATEX(fmt));
      if (result) then begin
	//
	if (isSrc) then
	  duplicateFormat(formatExt, f_srcFormatExt)
	else
	  duplicateFormat(formatExt, f_dstFormatExt);
	//
      end;
    end
    else
      result := false;
    //
  finally
    mrealloc(fmt);
  end;
end;

// --  --
function unaMsAcmStreamDevice.setFormatExt(isSrc: bool; const formatExt: string): bool;
var
  format: PWAVEFORMATEXTENSIBLE;
begin
  str2waveFormatExt(formatExt, format);
  try
    result := setFormatExt(isSrc, format);
  finally
    mrealloc(format);
  end;
end;

// --  --
procedure unaMsAcmStreamDevice.setInOverCN(value: unsigned);
begin
  // waveOut can have up to c_max_wave_headers headers
  if ((overNumIn <> value) and (c_max_wave_headers >= value)) then begin
    //
    f_inOverCN := value;
    f_inOverSize := overNumIn * f_chunkSize;
    //
    if ((nil <> inStream) and f_inStreamIsunaMemoryStream and (0 < value)) then
      unaMemoryStream(inStream).maxCacheSize := value + 2;
  end;
end;

// --  --
procedure unaMsAcmStreamDevice.setMinVL(value: unsigned);
begin
  if (f_minVL <> value) then begin
    //
    f_minVL := Value;
    if (0 <> f_minVL) then begin
      //
      f_savedCV := calcVolume;
      f_calcVolume := true;	// assign directly, since f_savedCV will be overriten in setCalcVolume
    end
    else
      calcVolume := f_savedCV;
  end;
end;

// --  --
procedure unaMsAcmStreamDevice.setOutOverCN(value: unsigned);
begin
  f_outOverCN := value;
  f_outOverSize := f_outOverCN * f_chunkSize;
  //
  if ((nil <> outStream) and f_outStreamIsunaMemoryStream and (0 < value)) then
    unaMemoryStream(outStream).maxCacheSize := value + 2;
end;

// --  --
procedure unaMsAcmStreamDevice.setRealTime(value: bool);
begin
  f_realTime := value;
end;

// --  --
procedure unaMsAcmStreamDevice.setVolume100(channel: int; volume: unsigned);
var
  i: int;
begin
  if (0 > channel) then begin
    //
    // set volume level for all channels
    for i := low(f_setVolume) to high(f_setVolume) do
      f_setVolume[i] := volume;
    //
    f_needVolumeAdjust := (100 <> volume);
  end
  else begin
    //
    // set volume level for specified channels
    f_setVolume[channel and $FF] := volume;
    //
    if (not f_needVolumeAdjust) then
      f_needVolumeAdjust := (100 <> volume);
  end;
  //
  calcVolume := calcVolume or f_needVolumeAdjust;
end;

// --  --
procedure unaMsAcmStreamDevice.startIn();
begin
  inherited;
end;

// --  --
procedure unaMsAcmStreamDevice.startOut();
begin
  inherited;
end;

// --  --
function unaMsAcmStreamDevice.waitForData(waitForInData: bool; timeout: tTimeout; expectedDataSize: unsigned): bool;
var
  mark: uint64;
  dataMark: unsigned;
  stream: unaAbstractStream;
begin
  if (waitForInData) then
    stream := inStream
  else
    stream := outStream;
  //
  if (nil <> stream) then begin
    //
    if (0 < expectedDataSize) then begin
      //
      // we should wait for some specific amount of data
      if (getDataAvailable(waitForInData) < expectedDataSize) then begin
	//
	mark := timeMarkU();
	repeat
	  stream.dataEvent.waitFor(timeout);
	  //
	until ((timeElapsed64U(mark) > timeout) or (getDataAvailable(waitForInData) >= expectedDataSize));
	//
	result := (getDataAvailable(waitForInData) >= expectedDataSize);
      end
      else
	result := true;	// data is here
      //
    end
    else begin
      //
      // we should wait just for some new data to appear
      result := stream.waitForData(timeout);
    end;
  end
  else begin
    //
    // there is no stream.. just wait for data
    if (0 < expectedDataSize) then begin
      //
      // we should wait for some specific amount of data
      if (getDataAvailable(waitForInData) < expectedDataSize) then begin
	//
	mark := timeMarkU();
	repeat
	  sleepThread(10);
	  //
	until ((timeElapsed64U(mark) > timeout) or (getDataAvailable(waitForInData) >= expectedDataSize));
	//
	result := (getDataAvailable(waitForInData) >= expectedDataSize);
      end
      else
	result := true;	// data is here
      //
    end
    else begin
      //
      // we should wait just for some new data to appear
      mark := timeMarkU();
      dataMark := getDataAvailable(waitForInData);
      while ((timeElapsed64U(mark) < timeout) and (getDataAvailable(waitForInData) = dataMark)) do begin
	//
	sleepThread(10);
      end;
      //
      result := (getDataAvailable(waitForInData) > dataMark);
    end;
  end;
end;

// --  --
function unaMsAcmStreamDevice.write(buf: pointer; size: unsigned): unsigned;
begin
  result := doWrite(buf, size);
end;


{ unaMsAcmCodecHeader }

// --  --
constructor unaMsAcmCodecHeader.create(codec: unaMsAcmCodec; srcSize: unsigned; dstSize: unsigned);
begin
  inherited create(codec);
  f_codec := codec;
  //
  case (codec.driverMode) of

    unacdm_acm,
    unacdm_openH323plugin: begin
      //
      fillChar(f_header, sizeof(ACMSTREAMHEADER), #0);
      with f_header do begin
	//
	cbStruct := sizeof(ACMSTREAMHEADER);
	//
	dwUser := UintPtr(self);
	//
	pbSrc := malloc(srcSize);
	cbSrcLength := srcSize;
	//
	pbDst := malloc(dstSize);
	cbDstLength := dstSize;
      end;
    end;

    unacdm_installable: begin
      //
      fillChar(f_drvHeader, sizeof(ACMDRVSTREAMHEADER), #0);
      with f_drvHeader do begin
        //
	cbStruct := sizeof(ACMDRVSTREAMHEADER);
	//
	dwUser := UintPtr(self);
	//
	pbSrc := malloc(srcSize);
	cbSrcLength := srcSize;
	//
	pbDst := malloc(dstSize);
	cbDstLength := dstSize;
      end;
    end;

    unacdm_internal:
      ;

    else
      ;
  end;
end;

// --  --
destructor unaMsAcmCodecHeader.Destroy();
begin
  inherited;
  //
  case (f_codec.driverMode) of

    unacdm_acm,
    unacdm_openH323plugin,    
    unacdm_installable: begin
      //
      if (unacdm_acm = f_codec.driverMode) then
	mrealloc(f_header.pbSrc)
      else
	mrealloc(f_drvHeader.pbSrc);
      //
      if (unacdm_acm = f_codec.driverMode) then
	mrealloc(f_header.pbDst)
      else
	mrealloc(f_drvHeader.pbDst);
    end;

    unacdm_internal:
      ;

    else
      ;
  end;
end;

// --  --
function unaMsAcmCodecHeader.getStatus(index: integer): bool;
begin
  case (f_codec.driverMode) of

    unacdm_acm,
    unacdm_openH323plugin: begin
      //
      with (f_header) do begin
	//
	result := (0 <> (fdwStatus and uint(index)));
      end;
    end;

    unacdm_installable: begin
      //
      with (f_drvHeader) do begin
	//
	result := (0 <> (fdwStatus and uint(index)));
      end;
    end;

    unacdm_internal:
      result := false;

    else
      result := false;
  end;
end;

// --  --
procedure unaMsAcmCodecHeader.grow(newsize: unsigned);
var
  dstsize: unsigned;
begin
  case (f_codec.driverMode) of

    unacdm_acm,
    unacdm_openH323plugin: begin
      //
      unprepare();
      //
      mrealloc(f_header.pbSrc, newsize);
      f_header.cbSrcLength := newsize;
      //
      if (mmNoError(f_codec.getChunkSize(newsize, dstsize, ACM_STREAMSIZEF_SOURCE))) then begin
	//
	f_codec.f_chunksize := newsize;
	f_codec.f_dstChunkSize := dstsize;
	//
	mrealloc(f_header.pbDst, dstsize);
	f_header.cbDstLength := dstsize;
      end;
      //
      prepare();
    end;

    unacdm_installable: begin
      //
      mrealloc(f_drvHeader.pbSrc, newsize);
      f_drvHeader.cbSrcLength := newsize;
    end;

  end;
end;

// --  --
function unaMsAcmCodecHeader.isDoneHeader(): bool;
begin
  result := isDone and isPrepared and not inQueue;
end;

// --  --
function unaMsAcmCodecHeader.isInQueue(): bool;
begin
  result := isPrepared and inQueue;
end;

// --  --
procedure unaMsAcmCodecHeader.rePrepare();
begin
  inherited;
  //
  case (f_codec.driverMode) of

    unacdm_acm,
    unacdm_openH323plugin: begin
      //
      with f_header do begin
	//
	cbSrcLengthUsed := 0;
	cbDstLengthUsed := 0;
      end;
    end;

    unacdm_installable: begin
      //
      with f_drvHeader do begin
	//
	cbSrcLengthUsed := 0;
	cbDstLengthUsed := 0;
      end;
    end;

    unacdm_internal:
      ;

    else
      ;
  end;
end;

// --  --
procedure unaMsAcmCodecHeader.setStatus(index: integer; value: bool);
begin
  case (f_codec.driverMode) of

    unacdm_acm,
    unacdm_openH323plugin: begin
      //
      with f_header do begin
	//
	if (value) then
	  fdwStatus := fdwStatus or uint(index)
	else
	  fdwStatus := fdwStatus and not uint(index);
      end;
    end;

    unacdm_installable: begin
      //
      with f_drvHeader do begin
	//
	if (value) then
	  fdwStatus := fdwStatus or uint(index)
	else
	  fdwStatus := fdwStatus and not uint(index);
      end;
    end;

    unacdm_internal:
      ;

    else
      ;
  end;
end;

// --  --
procedure unaMsAcmCodecHeader.write(data: pointer; size: unsigned; offset: unsigned);
begin
  case (f_codec.driverMode) of

    unacdm_acm,
    unacdm_openH323plugin: begin
      //
      with f_header do begin
	//
	if (0 < size) then
	  move(data^, pAnsiChar(pbSrc)[offset], size);
      end;
    end;

    unacdm_installable: begin
      //
      with f_drvHeader do begin
	//
	if (0 < size) then
	  move(data^, pAnsiChar(pbSrc)[offset], size);
      end;
    end;

    unacdm_internal:
      ;

    else
      ;
  end;
end;


  { unaMsAcmCodec }

// --  --
procedure unaMsAcmCodec.BeforeDestruction();
begin
  inherited;
  //
  freeAndNil(f_oH323codec);
end;

// --  --
constructor unaMsAcmCodec.create(driver: unaMsAcmDriver; realtime: bool; overNum: unsigned; highPriority: bool; driverMode: unaAcmCodecDriverMode);
begin
  inherited create(true, true, overNum, overNum);
  //
  f_driver := driver;
  self.realtime := realtime;
  f_highPriority := highPriority;
  f_driverMode := driverMode;
  //
  //  uncomment two lines below at your own risk
  //
  //f_async := (0 <> (f_driver.getDetails().fdwSupport and ACMDRIVERDETAILS_SUPPORTF_ASYNC));
  //f_async := false;
end;

// --  --
function unaMsAcmCodec.doClose(timeout: tTimeout): MMRESULT;
begin
  result := reset(timeout);
  if (mmNoError(result)) then begin
    //
    case (driverMode) of

      unacdm_acm: begin
	//
	result := acm_streamClose(f_handle, 0);
	f_handle := 0;
      end;

      unacdm_installable: begin
	//
	if (nil <> driver) then
	  result := driver.sendDriverMessage(ACMDM_STREAM_CLOSE, int(@f_streamInstance), 0)
	else
	  result := MMSYSERR_NODRIVER;
	//
	f_handle := 0;	// indicate success of closing
      end;

      unacdm_internal:
	result := MMSYSERR_NOTSUPPORTED;

      unacdm_openH323plugin: begin
	//
	if (nil <> f_oH323codec) then begin
	  //
	  f_oH323codecOldIndex := f_oH323codec.codecIndex;
	  f_oH323codec.close();
	end;
	//
	f_handle := 0;	// indicate success of closing
      end;

      else
	result := MMSYSERR_INVALPARAM;

    end;
  end;
  //
  //if (not f_async) then
    f_deviceEvent.setState();
  //
  if (mmNoError(result)) then
    inherited doClose(timeout);
  //
  mrealloc(f_chunk);
  mrealloc(f_subBuf);
  f_subBufSize := 0;
  //
end;

// --  --
procedure hackG723(format: PWAVEFORMATEX);
asm
{$IFDEF CPU64 }
        // 2do
{$ELSE }
	or	eax, eax
	jz	@exit

	cmp	dword ptr [eax], $10000 or WAVE_FORMAT_MSG723	// mono + formatTag
	jne	@exit

	cmp	byte ptr [eax][$10], 10
	jb	@exit

	//
	mov	dword ptr [eax][$14], $0F7329ACE
	mov	dword ptr [eax][$18], $0ACDEAEA2
{$ENDIF CPU64 }
  @exit:
end;

// --  --
function unaMsAcmCodec.doOpen(flags: uint): MMRESULT;
var
  localChunkSize: unsigned;
  driverHandle: tHandle;
  fmts, fmtd: pWAVEFORMATEX;
  dstsize: unsigned;
begin
  if (nil <> driver) then
    driverHandle := driver.getHandle()
  else
    driverHandle := 0;
  //
  result := inherited doOpen(flags);
  if (MMSYSERR_NOERROR = result) then begin
    //
    // Check if we are dealing with MS G.723
    fmts := nil;
    fmtd := nil;
    try
      if (waveExt2wave(f_srcFormatExt, fmts)) then
	hackG723(fmts);
      //
      if (waveExt2wave(f_dstFormatExt, fmtd)) then
	hackG723(fmtd);
      //
      case (driverMode) of

	unacdm_acm: begin
	  //
	  result := acm_streamOpen(pHACMSTREAM(@f_handle), driverHandle, fmts, fmtd, f_filterFormat, choice(false{f_async}, f_deviceEvent.handle, 0), choice(false{f_async}, UIntPtr(self), 0), flags);
	end;

	unacdm_installable: begin
	  //
	  if (nil <> driver) then begin
	    //
	    f_streamInstance.cbStruct := sizeOf(ACMDRVSTREAMINSTANCE);
	    with f_streamInstance do begin
	      //
	      pwfxSrc := fmts;
	      pwfxDst := fmtd;
	      pwfltr := f_filterFormat;
	      dwCallback := choice(false{f_async}, f_deviceEvent.handle, 0);
	      dwInstance := choice(false{f_async}, UIntPtr(self), 0);
	      fdwOpen := flags;
	      //
	      has := int(self);
	    end;
	    //
	    result := driver.sendDriverMessage(ACMDM_STREAM_OPEN, int(@f_streamInstance), 0);
	    //
	    if (mmNoError(result)) then
	      f_handle := 1;	// indicate success of opening
	  end
	  else
	    result := MMSYSERR_NODRIVER;
	end;

	unacdm_internal: result := MMSYSERR_NOTSUPPORTED;

	unacdm_openH323plugin: begin
	  //
	  if (nil <> f_oH323codec) then begin
	    //
	    if (0 > f_oH323codec.codecIndex) then
	      f_oH323codec.selectCodec(f_oH323codecOldIndex);	// restore old codec index, which was lost after closing
	    //
	    f_oH323codec.open();
	    //
	    f_handle := 1;	// indicate success of opening
	    result := MMSYSERR_NOERROR;
	  end
	  else
	    result := MMSYSERR_NODRIVER;
	end;

	else
	  result := MMSYSERR_INVALPARAM;

      end;
      //
      if (mmNoError(result)) then begin
	//
	//if (not f_async) then
	  f_deviceEvent.setState();
	//
	if (formatIsPCM(f_srcFormatExt)) then begin
	  //
	  if (mmNoError(getChunkSize(f_dstChunkSize, localChunkSize, ACM_STREAMSIZEF_DESTINATION))) then
	    f_chunkSize := localChunkSize
	  else begin
	    //
	    f_dstChunkSize := f_dstFormatExt.Format.nAvgBytesPerSec div 10;
	    if (mmNoError(getChunkSize(f_dstChunkSize, localChunkSize, ACM_STREAMSIZEF_DESTINATION))) then
	      f_chunkSize := localChunkSize
	  end;
	end;
	//
	if (not mmNoError(getChunkSize(chunkSize, f_dstChunkSize, ACM_STREAMSIZEF_SOURCE))) then begin
	  //
	  if (formatIsPCM(f_srcFormatExt)) then begin
	    //
	    if (mmNoError(getChunkSize(f_srcFormatExt.format.nAvgBytesPerSec div c_defChunksPerSecond, f_dstChunkSize, ACM_STREAMSIZEF_SOURCE))) then
	      // fine, f_dstChunkSize is now set by codec itself
	    else
	      // sometimes div 25 works
	      if (mmNoError(getChunkSize(f_srcFormatExt.format.nAvgBytesPerSec div 25, f_dstChunkSize, ACM_STREAMSIZEF_SOURCE))) then
	      else
		// sometimes div 10 works even better
		if (mmNoError(getChunkSize(f_srcFormatExt.format.nAvgBytesPerSec div 10, f_dstChunkSize, ACM_STREAMSIZEF_SOURCE))) then
		else
		  f_dstChunkSize := chunkSize div 10;
	  end
	  else
	    f_dstChunkSize := chunkSize * 10;
	  //
	  // that is not an error, so simply log this case
	  {$IFDEF LOG_UNAMSACMCLASSES_INFOS }
	  logMessage(self._classID + '.doOpen() - acm_streamSize() fails, dstChunkSize=' + int2str(dstChunkSize));
	  {$ENDIF LOG_UNAMSACMCLASSES_INFOS }
	end
	else begin
	  //
	  {$IFDEF LOG_UNAMSACMCLASSES_INFOS }
	  logMessage(self._classID + '.doOpen() - dstChunkSize=' + int2str(dstChunkSize));
	  {$ENDIF LOG_UNAMSACMCLASSES_INFOS }
	end;
	//
	if (not mmNoError(getChunkSize(dstChunkSize, localChunkSize, ACM_STREAMSIZEF_DESTINATION))) then begin
	  //f_chunkSize := chunkSize;
	  // that is not an error, so simply log this case
	  {$IFDEF LOG_UNAMSACMCLASSES_INFOS }
	  logMessage(self._classID + '.doOpen() - acm_streamSize() fails, chunkSize=' + int2str(chunkSize));
	  {$ENDIF LOG_UNAMSACMCLASSES_INFOS }
	end
	else begin
	  //
	  if (chunkSize <> localChunkSize) then begin
	    //
	    // that is not an error, so simply log this case
	    {$IFDEF LOG_UNAMSACMCLASSES_INFOS }
	    logMessage(self._classID + '.doOpen() - chunkSize=' + int2str(localChunkSize) + ' (was ' + int2str(chunkSize) + ')');
	    {$ENDIF LOG_UNAMSACMCLASSES_INFOS }
	    //
	    f_chunkSize := localChunkSize;
	    //
	    if (mmNoError(getChunkSize(chunkSize, dstsize, ACM_STREAMSIZEF_SOURCE))) then begin
	      //
	      if (f_dstChunkSize <> dstsize) then begin
		//
		{$IFDEF LOG_UNAMSACMCLASSES_INFOS }
		logMessage(self._classID + '.doOpen() - dstChunkSize adjusted to ' + int2str(dstsize) + ' (was ' + int2str(f_dstChunkSize) + ')');
		{$ENDIF LOG_UNAMSACMCLASSES_INFOS }
		f_dstChunkSize := dstsize;
              end;
	    end;
	  end
	  else begin
	    // that is not an error, so simply log this case
	    {$IFDEF LOG_UNAMSACMCLASSES_INFOS }
	    logMessage(self._classID + '.doOpen() - chunkSize=' + int2str(localChunkSize));
	    {$ENDIF LOG_UNAMSACMCLASSES_INFOS }
	  end;
	end;
	//
	f_inOverSize := overNumIn * f_chunkSize;
	f_outOverSize := overNumOut * f_dstChunkSize;
	//
	f_inProgress := 0;
      end;
      //
      f_chunk := malloc(chunkSize); // will be deallocated on close()
      //
      f_flags := ACM_STREAMCONVERTF_BLOCKALIGN or ACM_STREAMCONVERTF_START;
      f_subSize := 0;
      //f_subBuf := nil;
      f_header := nil;
      f_acmHeader := nil;
      //
    finally
      mrealloc(fmts);
      mrealloc(fmtd);
    end;
  end;
end;

// --  --
function unaMsAcmCodec.doWrite(buf: pointer; size: unsigned): unsigned;
{$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
var
  deltaSize: int;
  srcSize: unsigned;
  res: MMRESULT;
  bufOffs: unsigned;
{$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
begin
{$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
  internalConsumeData(buf, size);
  //
  result := 0;
  //
  {$IFDEF DEBUG_LOG_MARKBUFF }
  if ((4 < size) and (nil <> buf)) then
    logMessage('BUFMARK: ' + choice(isPCMFormatExt(f_srcFormatExt), '', 'de') + 'codec got new BUF#' + int2str(pUint32(buf)^));
  {$ENDIF DEBUG_LOG_MARKBUFF }
  if ((nil <> buf) and (0 < size) and beforeNewChunk(buf, size, srcFormatExt)) then begin
    //
    if (acquire(false, 100)) then try
      //
      try
	srcSize := size;
	bufOffs := 0;
	//
	// check if we have something to convert
	while (not shouldStop and (chunkSize <= f_subSize + size) or (unacdm_openH323plugin = driverMode)) do begin
	  //
	  if (nil = f_header) then begin
	    //
	    if (unacdm_openH323plugin = driverMode) then
	      f_header := unaMsAcmCodecHeader.create(self, min(size, chunkSize), dstChunkSize)
	    else
	      f_header := unaMsAcmCodecHeader.create(self, chunkSize, dstChunkSize);
	    //
	    f_header.prepare();
	    f_headers[f_nextHdr] := f_header;
	    inc(f_nextHdr);
	  end;
	  //
	  // mark header ready for next conversion
	  f_header.rePrepare();
	  //
          if (nil = f_acmHeader) then begin
            //
            case (driverMode) of

              unacdm_acm,
              unacdm_openH323plugin:
                f_acmHeader := @f_header.f_header;

              unacdm_installable:
                f_acmHeader := pACMSTREAMHEADER(@f_header.f_drvHeader);

              unacdm_internal:
                f_acmHeader := nil;

	      else
                f_acmHeader := nil;

            end;
          end;
          //
	  {
          case (driverMode) of

            unacdm_acm:
              isPCMOutput := isPCMFormatExt(f_dstFormatExt);

            unacdm_openH323plugin:
              isPCMOutput := not f_oH323codec.isEncoder();

            else
              isPCMOutput := false;             // ne yveren -- ne obgonyai

          end;
          }
          //
          // care about data left from previuos chunk
          if ((0 < f_subSize) and (nil <> f_subBuf)) then
            f_header.write(f_subBuf, f_subSize);
          //
          // calculate how much data should we take from buffer
          deltaSize := min(size, chunkSize - f_subSize);
          if (0 < deltaSize) then begin
            //
            //deltaSize := internalRead(f_chunk, deltaSize, isPCMFormatExt(f_srcFormatExt), f_srcFormatExt);
            f_header.write(@pArray(buf)[bufOffs], deltaSize, f_subSize);
            inc(bufOffs, deltaSize);
          end
          else begin
            //
            // that means no data was encoded/decoded in last operation, which is strange
            //
            {$IFDEF LOG_UNAMSACMCLASSES_INFOS }
	    logMessage(self._classID + '.doWrite(), no data has been handled in last convertion..');
            {$ENDIF LOG_UNAMSACMCLASSES_INFOS }
            //
            if ((chunkSize = f_subSize) and (0 < int(size) - int(f_subSize))) then begin
              //
              // no data were processed at all, should we increase source buffer?
              //
              // -------------------------------------------------
              // NOTE: experimental, probably will do nothing good
	      // -------------------------------------------------
              f_header.grow(size + f_subSize);
              deltaSize := size;
              //
              f_header.write(@pArray(buf)[bufOffs], size, f_subSize);
              inc(bufOffs, deltaSize);
	    end;
          end;
          //
          dec(size, deltaSize);
          f_subSize := 0;
          //
          // send header to convertion routine
          inc(f_inBytes, f_header.f_header.cbSrcLength);
          //
	  res := streamConvert(f_header, f_flags);
	  if (mmNoError(res)) then begin
            //
	    if (nil <> f_acmHeader) then begin
	      //
	      // write new chunk (if any)
	      if (0 < f_acmHeader.cbDstLengthUsed) then
		internalWrite(f_acmHeader.pbDst, f_acmHeader.cbDstLengthUsed, f_dstFormatExt);
	      //
	      // something left unprocessed?
	      //
	      // -- fix: 06/JUL/2010 --
	      // -- Even if cbDstLengthUsed/cbSrcLengthUsed is 0, that does not actually means drives has not consumed our bytes
	      // -- so we always assume that driver consume somethign, when res is OK, so no additional saving is needed
              // --
              // -- f_subSize := f_acmHeader.cbSrcLength - f_acmHeader.cbSrcLengthUsed;
              // -- if (0 < f_subSize) then begin
              // --   //
              // --   // should not be here, since dst and src chunks have been set to correct values,
              // --   // so we pass block-aligned buffers only, but let be smart enough to handle this case anyways.
              // --   //
              // --   if (f_subBufSize < f_subSize) then begin
              // --     //
              // --     mrealloc(f_subBuf, f_subSize);
              // --     f_subBufSize := f_subSize;
              // --   end;
              // --   //
              // --   move(pArray(f_acmHeader.pbSrc)[f_acmHeader.cbSrcLengthUsed], f_subBuf^, f_subSize);
              // -- end;
              // --
              // -- end of fix: 06/JUL/2010 --
              // -----------------------------------------------------------------
	      // -- Thanks to Glen Fraser for contibuting support for this fix --
              // -----------------------------------------------------------------
            end;
            //
            f_flags := f_flags and not ACM_STREAMCONVERTF_START;	// clear START flag
            f_header.isDone := true;
	    //
            {$IFDEF VCX_DEMO }
              inc(f_headersServed);
            {$ENDIF VCX_DEMO }
          end
          else begin
            // convertion request was not accepted
            {$IFDEF LOG_UNAMSACMCLASSES_ERRORS }
	    logMessage(self._classID + '.doWrite() - error during convertion:  ' + srcFormatInfo + ' -> ' + dstFormatInfo + '; error(' + int2str(res) + ')=' + getErrorText(res));
            {$ENDIF LOG_UNAMSACMCLASSES_ERRORS }
          end;
          //
          if ((unacdm_openH323plugin = driverMode) and (chunkSize > f_subSize + size)) then
            break;
          //
        end; // while (we have some data ready) do ...
        //
        // something left not converted?
        if (0 < size) then begin
          //
          if (f_subBufSize < size + f_subSize) then begin
            //
            mrealloc(f_subBuf, size + f_subSize);
            f_subBufSize := size + f_subSize;
          end;
          //
          move(pArray(buf)[srcSize - size], pArray(f_subBuf)[f_subSize], size);
          inc(f_subSize, size);
        end;
        //
        result := srcSize;	// assume we have consumed the whole buffer supplied
        //
      {$IFDEF VCX_DEMO }
        if (308 * c_defChunksPerSecond < f_headersServed) then begin
          //
          guiMessageBox(string(baseXdecode('eWImdm4qYmYsfjNgOSZwJSdscHQiPj9zIiZ3LiciamhtOTV+Jidne3cwY3sqNmh9cTxqMz13JSx6ZmQnOzdnPztxbWQgaGRhMjF4PX57AAhZRU4eTk9KAAhfEBReDEEFTQBNBRxJTw0HV1sVTE4NQkADSwhOHR0XC0g=', '<m%', 100)), '', MB_OK);
          close();
        end;
      {$ENDIF VCX_DEMO }
      except
        // ignore exceptions
      end;
    finally
      releaseWO();
    end;
  end;
{$ELSE }
  result := inherited doWrite(buf, size);
{$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
end;

// --  --
function unaMsAcmCodec.getChunkSize(inSize: unsigned; out outSize: unsigned; flags: uint): MMRESULT;
var
  streamSize: ACMDRVSTREAMSIZE;
  sz1, sz2: int;
  os: DWORD;
begin
  case (driverMode) of

    unacdm_acm: begin
      //
      result := acm_streamSize(f_handle, inSize, os, flags);
      outSize := os;
    end;

    unacdm_installable: begin
      //
      if (nil <> driver) then begin
	//
	streamSize.cbStruct := sizeof(ACMDRVSTREAMSIZE);
	with streamSize do begin
	  //
	  fdwSize := flags;
	  if (ACM_STREAMSIZEF_SOURCE = flags) then
	    cbSrcLength := inSize;
	  if (ACM_STREAMSIZEF_DESTINATION = flags) then
	    cbDstLength := inSize;
	end;
	//
	result := driver.sendDriverMessage(ACMDM_STREAM_SIZE, int(@f_streamInstance), int(@streamSize));
	//
	if (mmNoError(result)) then begin
	  //
	  with streamSize do begin
	    //
	    if (ACM_STREAMSIZEF_DESTINATION = flags) then
	      outSize := cbSrcLength;
	    //
	    if (ACM_STREAMSIZEF_SOURCE = flags) then
	      outSize := cbDstLength shl 1;
	  end;
	end;
	//
      end
      else
	result := MMSYSERR_NODRIVER;
    end;

    unacdm_openH323plugin: begin
      //
      if (nil <> f_oH323codec) then begin
	//
	if (0 <= f_oH323codec.codecIndex) then begin
	  //
	  sz1 := f_oH323codec.codecDef[f_oH323codec.codecIndex].samplesPerFrame shl 1;
	  sz2 := f_oH323codec.codecDef[f_oH323codec.codecIndex].bytesPerFrame;
	  //
	  result := MMSYSERR_NOERROR;
	  //
	  if (ACM_STREAMSIZEF_DESTINATION = flags) then begin
	    //
	    if (f_oH323codec.isEncoder()) then
	      outSize := sz1
	    else
	      outSize := sz2;
	    //
	  end
	  else begin
	    //
	    if (ACM_STREAMSIZEF_SOURCE = flags) then begin
	      //
	      if (f_oH323codec.isEncoder()) then
		outSize := sz2
	      else
		outSize := sz1;
	      //
	    end
	    else
	      result := MMSYSERR_INVALFLAG;
          end;    
	end
	else
	  result := MMSYSERR_INVALHANDLE;	// no codec index was selected
	//
      end
      else
	result := MMSYSERR_NODRIVER ;
    end;

    unacdm_internal:
      result := MMSYSERR_NOTSUPPORTED;

    else
      result := MMSYSERR_INVALPARAM;
  end;
end;

// --  --
function unaMsAcmCodec.execute(globalIndex: unsigned): int;
{$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
var
  chunk: pointer;
  sz: unsigned;
{$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
begin
  if (0 < chunkPerSecond) then
    f_waitInterval := 1000 div chunkPerSecond
  else
    f_waitInterval := 40;	//
  //
  if (f_highPriority) then
    priority := THREAD_PRIORITY_TIME_CRITICAL;
  //
  {$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
  chunk := malloc(chunkSize);
  try
  {$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
    while (not shouldStop) do begin
      //
      {$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
      if ((nil <> inStream) and (int(chunkSize) <= inStream.getAvailableSize())) then begin
	//
	sz := inStream.read(chunk, int(chunkSize));
	if (chunkSize <= sz) then
	  write(chunk, chunkSize);
      end
      else
	sleepThread(1000);	// all job will be done in doWrite()
      {$ELSE }
      if (1 > inProgress) then
	// no buffers were added into stream on last cycle, wait for new chunk
	waitForData(true, f_waitInterval, chunkSize);
      //
      processNextChunk();
      {$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
    end;
  {$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
  finally
    mrealloc(chunk);
  end;
  {$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
  //
  result := 0;
end;

// --  --
function unaMsAcmCodec.getMasterIsSrc2(): bool;
begin
  result := true;	// src
end;

// --  --
function unaMsAcmCodec.getoH323pluginDesc(index: int): ppluginCodec_definition;
begin
  if (nil <> f_oH323codec) then begin
    //
    if (0 <= index) then
      result := f_oH323codec.codecDef[index]
    else
      if (0 <= f_oH323codec.codecIndex) then
	result := f_oH323codec.codecDef[f_oH323codec.codecIndex]
      else
        result := nil;
  end
  else
    result := nil;
end;

// --  --
function unaMsAcmCodec.open2(query: bool; timeout: tTimeout; flags: uint; startDevice: bool): MMRESULT;
begin
  if (0 = flags) then begin
    //
    flags := choice(false{f_async}, ACM_STREAMOPENF_ASYNC or CALLBACK_EVENT, uint(0)) or
	     choice(realtime, uint(0), ACM_STREAMOPENF_NONREALTIME) or
	     choice(query, ACM_STREAMOPENF_QUERY, uint(0));
  end;
  //
  result := inherited open2(query, timeout, flags, startDevice);
end;

// --  --
function unaMsAcmCodec.prepareHeader(header: pointer): MMRESULT;
begin
  case (driverMode) of

    unacdm_acm:
      result := acm_streamPrepareHeader(f_handle, @unaMsAcmCodecHeader(header).f_header, 0);

    unacdm_installable: begin
      //
      if (nil <> driver) then begin
	//
	unaMsAcmCodecHeader(header).f_drvHeader.fdwConvert := 0;
	result := driver.sendDriverMessage(ACMDM_STREAM_PREPARE, int(@f_streamInstance), int(@unaMsAcmCodecHeader(header).f_drvHeader));
	//
	if (MMSYSERR_NOTSUPPORTED = result) then
	  result := MMSYSERR_NOERROR;	// driver should not care about header preparing
	//
	if (mmNoError(result)) then
	  unaMsAcmCodecHeader(header).isPrepared := true;
	//
      end
      else
	result := MMSYSERR_NODRIVER;
    end;

    unacdm_openH323plugin: begin
      //
      unaMsAcmCodecHeader(header).isPrepared := true;
      //
      result := MMSYSERR_NOERROR;
    end;

    unacdm_internal:
      result := MMSYSERR_NOTSUPPORTED;

    else
      result := MMSYSERR_INVALPARAM;
  end;
  //
  {$IFDEF LOG_UNAMSACMCLASSES_ERRORS }
  if (not mmNoError(result)) then
    logMessage(self._classID + '.prepareHeader() fails, code=' + getErrorText(result));
  {$ENDIF LOG_UNAMSACMCLASSES_ERRORS }
end;

// --  --
function unaMsAcmCodec.processNextChunk(): bool;
var
  busy: bool;
  deltaSize: unsigned;
  res: MMRESULT;
begin
  result := false;
  //
  try
{$IFDEF DEBUG_LOG_CODEC }
    logMessage('CODEC LOOP: inProgress=' + int2str(inProgress) + '; DataAvail_in=' + int2str(getDataAvailable(true)));
{$ENDIF DEBUG_LOG_CODEC }
    busy := (0 < inProgress);
    //if (f_async) then
    //  f_header := nil;
    //
{$IFDEF UNA_PROFILE }
    profileMarkEnter(profId_unaMsAcmCodec_insideCodec);
{$ENDIF UNA_PROFILE }
    //
    if ((false{f_async} and f_deviceEvent.waitFor(f_waitInterval)) or
	(true{not f_async} and busy)) then begin
      //
      // locate done header (if there is any)
      //if (f_async) then
      //	f_header := unaMsAcmCodecHeader(locateHeader());
      //
{$IFDEF DEBUG_LOG_CODEC }
      logMessage('CODEC LOOP: header=' + int2str(UIntPtr(f_header)));
{$ENDIF DEBUG_LOG_CODEC }
      if (nil <> f_header) then begin
	//
	if (false{f_async} or (nil = f_acmHeader)) then begin
	  //
	  case (driverMode) of

	    unacdm_acm,
	    unacdm_openH323plugin:
	      f_acmHeader := @f_header.f_header;

	    unacdm_installable:
	      f_acmHeader := pACMSTREAMHEADER(@f_header.f_drvHeader);

	    unacdm_internal:
	      f_acmHeader := nil;

	    else
	      f_acmHeader := nil;

	  end;
	end;
	//
	if (nil <> f_acmHeader) then begin
	  //
{$IFDEF DEBUG_LOG_CODEC }
	  logMessage('CODEC LOOP: about to write ' + int2str(f_acmHeader.cbDstLengthUsed) + ' bytes; subSize=' + int2str(f_acmHeader.cbSrcLength - f_acmHeader.cbSrcLengthUsed));
{$ENDIF DEBUG_LOG_CODEC }
	  // write new chunk
	  internalWrite(f_acmHeader.pbDst, f_acmHeader.cbDstLengthUsed, f_dstFormatExt);
	  f_subSize := f_acmHeader.cbSrcLength - f_acmHeader.cbSrcLengthUsed;
	  if (0 < f_subSize) then
	    // should not be here, since dst and src chunks have been set to correct values,
	    // so we pass block-aligned buffers only, but let be smart enough to handle this case anyways.
	    f_subBuf := @pArray(f_acmHeader.pbSrc)[f_acmHeader.cbSrcLengthUsed];
	end;
	//
	f_header.isFree := true;
	InterlockedDecrement(int(f_inProgress));
      end;
    end;
    //
    // do not pass more than 2 buffers at a time
    busy := (2 < inProgress);
    //
{$IFDEF DEBUG_LOG_CODEC }
    logMessage('CODEC LOOP: middle busy, inProgress=' + int2str(inProgress));
{$ENDIF DEBUG_LOG_CODEC }
    //
{$IFDEF VCX_DEMO }
    if (307 * c_defChunksPerSecond < f_headersServed) then begin
      //
      guiMessageBox(string(baseXdecode('eWImdm4qYmYsfjNgOSZwJSdscHQiPj9zIiZ3LiciamhtOTV+Jidne3cwY3sqNmh9cTxqMz13JSx6ZmQnOzdnPztxbWQgaGRhMjF4PX57AAhZRU4eTk9KAAhfEBReDEEFTQBNBRxJTw0HV1sVTE4NQkADSwhOHR0XC0g=', '<m%', 100)), '', MB_OK);
      //
      close();
    end;
{$ENDIF VCX_DEMO }
    //
    // check if we have something to convert
    if (not busy and not shouldStop and (chunkSize <= f_subSize + getDataAvailable(true))) then begin
      //
{$IFDEF DEBUG_LOG_CODEC }
      logMessage('CODEC LOOP: we have something to convert, and we are not busy, so lets do some job now...');
{$ENDIF DEBUG_LOG_CODEC }
      if (nil = f_header) then begin
	//
	// locate unused header (if there is any)
	{$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
	{$ELSE }
	f_header := unaMsAcmCodecHeader(locateHeader(true));
	{$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
	//
	if (nil = f_header) then begin
	  // create new header
{$IFDEF DEBUG_LOG_CODEC }
	  logMessage('CODEC LOOP: new ACM buffer was created');
{$ENDIF DEBUG_LOG_CODEC }
	  f_header := unaMsAcmCodecHeader.create(self, chunkSize, dstChunkSize);
	  f_header.prepare();
{$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
	  f_headers[f_nextHdr] := f_header;
	  inc(f_nextHdr);
	  if (f_nextHdr >= high(f_headers)) then
	    dec(f_nextHdr);
{$ELSE }
	  f_headers.add(f_header);
{$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
	end;
      end;

      // mark header ready for next conversion
      f_header.rePrepare();
      if (false{f_async} or (nil = f_acmHeader)) then begin
        //
	case (driverMode) of

	  unacdm_acm,
	  unacdm_openH323plugin:
	    f_acmHeader := @f_header.f_header;

          unacdm_installable:
	    f_acmHeader := pACMSTREAMHEADER(@f_header.f_drvHeader);

          unacdm_internal:
            f_acmHeader := nil;

          else
	    f_acmHeader := nil;
        end;
      end;
      //
      // care about data left from previuos conversion
      if ((0 < f_subSize) and (nil <> f_subBuf)) then begin
        //
{$IFDEF DEBUG_LOG_CODEC }
	logMessage('CODEC LOOP: eat ' + int2str(f_subSize) + ' from subBuf.');
{$ENDIF DEBUG_LOG_CODEC }
        f_header.write(f_subBuf, f_subSize);
      end;
      //
      // calculate how much data should we read from input stream
      deltaSize := chunkSize - f_subSize;
      if (0 < deltaSize) then begin
	//
	deltaSize := internalRead(f_chunk, deltaSize, f_srcFormatExt);
	f_header.write(f_chunk, deltaSize, f_subSize);
{$IFDEF DEBUG_LOG_CODEC }
	logMessage('CODEC LOOP: delta size was ' + int2str(deltaSize) + ' bytes..');
{$ENDIF DEBUG_LOG_CODEC }
      end
      else begin
	// that means no data was encoded/decoded in last operation, which is strange
	{$IFDEF LOG_UNAMSACMCLASSES_INFOS }
	logMessage(self._classID + '.execute(), no data has been handled in last convertion, strange..');
	{$ENDIF LOG_UNAMSACMCLASSES_INFOS }
      end;
      //
      //
      if (f_chunkSize = f_subSize + deltaSize) then begin
        //
        f_subSize := 0;
        deltaSize := f_chunkSize;
      end;
      //
      if (not shouldStop and (0 < deltaSize)) then begin
        //
        if (f_chunkSize = f_subSize + deltaSize) then begin
          //
{$IFDEF DEBUG_LOG_CODEC }
	  logMessage('CODEC LOOP: about to send a new buffer for ACM conversion');
{$ENDIF DEBUG_LOG_CODEC }
          // send header to convertion routine
	  res := streamConvert(f_header, f_flags);
          if (mmNoError(res)) then begin
            //
	    f_flags := f_flags and not ACM_STREAMCONVERTF_START;	// clear START flag
	    if (false{f_async} and not f_header.inQueue and not f_header.isDone) then begin
              //
              f_acmHeader.cbDstLengthUsed := 0;
              //
	      {$IFDEF LOG_UNAMSACMCLASSES_INFOS }
	      logMessage(self._classID + '.execute() - header was not added into queue.');
	      {$ENDIF LOG_UNAMSACMCLASSES_INFOS }
	    end
            else begin
	      //
	      InterlockedIncrement(int(f_inProgress));
              result := true;
            end;
            //
	    //if (not f_async) then
              f_header.isDone := true;
            //
{$IFDEF VCX_DEMO }
            inc(f_headersServed);
{$ENDIF VCX_DEMO }
          end
          else begin
            // convertion request was not accepted
	    {$IFDEF LOG_UNAMSACMCLASSES_ERRORS }
	    logMessage(self._classID + '.execute() - error during convertion:  ' + srcFormatInfo + ' -> ' + dstFormatInfo + '; error(' + int2str(res) + ')=' + getErrorText(res));
	    {$ENDIF LOG_UNAMSACMCLASSES_ERRORS }
	    //
	    exit;	// exit thread
	  end;
	end
	else begin
	  //
	  // that is not an error, so simply log this case
	  {$IFDEF LOG_UNAMSACMCLASSES_INFOS }
	  logMessage(self._classID + '.execute() - wrong delta: ' + int2str(f_chunkSize) + ' <> ' + int2str(f_subSize) + '+' + int2str(deltaSize) + '.');
	  {$ENDIF LOG_UNAMSACMCLASSES_INFOS }
	  //
	  {$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
	  {$ELSE }
	  adjustLastDoneHeaderNum(f_header.f_num);
	  {$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
          //
          f_header.isDone := true;
	  f_header.f_needRePrepare := false;
	  inc(f_subSize, deltaSize);
	end;
      end
      else begin
        //
        if (not shouldStop) then begin
	  //
          // that is not an error, so simply log this case
	  {$IFDEF LOG_UNAMSACMCLASSES_INFOS }
	  logMessage(self._classID + '.execute() - deltaSize[' + int2str(deltaSize) + '] <= 0.');
	  {$ENDIF LOG_UNAMSACMCLASSES_INFOS }
	  //
	  {$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
	  {$ELSE }
	  adjustLastDoneHeaderNum(f_header.f_num);
	  {$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
	  //
	  f_header.isDone := true;	// header contains no data
	  f_header.isFree := true;
        end;
      end;
      //
    end;
    //
{$IFDEF DEBUG_LOG_CODEC }
    if (not shouldStop) then
      logMessage('CODEC LOOP: goint to next loop...');
{$ENDIF DEBUG_LOG_CODEC }
    //
{$IFDEF UNA_PROFILE }
  profileMarkLeave(profId_unaMsAcmCodec_insideCodec);
{$ENDIF UNA_PROFILE }
    //
  except
    // ignore exceptions
  end;
end;

{$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }

// --  --
procedure unaMsAcmCodec.removeHeader(var header: pointer);
begin
  freeAndNil(unaMsAcmCodecHeader(header));
end;

{$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }

// --  --
function unaMsAcmCodec.reset(timeout: tTimeout): MMRESULT;
begin
  case (driverMode) of

    unacdm_acm: begin
      //
      result := acm_streamReset(f_handle, 0);
    end;

    unacdm_installable: begin
      //
      if (nil <> driver) then
	result := driver.sendDriverMessage(ACMDM_STREAM_RESET, int(@f_streamInstance), 0)
      else
	result := MMSYSERR_NODRIVER;
    end;

    unacdm_openH323plugin: begin
      //
      result := MMSYSERR_NOTSUPPORTED;
    end;

    unacdm_internal: begin
      //
      result := MMSYSERR_NOTSUPPORTED;
    end;

    else
      result := MMSYSERR_INVALPARAM;
  end;
end;

// --  --
procedure unaMsAcmCodec.setDriverLibrary(const value: wString);
begin
  if (f_driverLibrary <> value) then begin
    //
    f_driverLibrary := value;
    case (driverMode) of

      unacdm_openH323plugin: begin
	//
	if (nil <> f_oH323codec) then begin
	  //
	  close();
	  freeAndNil(f_oH323codec);
	end;
	//
	f_oH323codec := una_openH323plugin.create(driverLibrary);
	if (BE_ERR_SUCCESSFUL <> f_oH323codec.errorCode) then begin
	  //
	  f_handle := 0;	//no success
	  freeAndNil(f_oH323codec);
	end;
      end;

    end;
  end;
end;

// --  --
procedure unaMsAcmCodec.setDriver(value: unaMsAcmDriver);
begin
  f_driver := value;
end;

// --  --
procedure unaMsAcmCodec.setFormatIndex(isSrc: bool; tag, index: unsigned);
var
  pafd: ACMFORMATDETAILS;
  pcmFormat: WAVEFORMATEX;
begin
  case (driverMode) of

    unacdm_openH323plugin: begin
      //
      fillChar(pcmFormat, sizeof(WAVEFORMATEX), #0);
      pcmFormat.wFormatTag := tag;
      //
      setFormatSuggest(isSrc, pcmFormat);
    end;

    else begin
      //
      if ((nil <> driver) and driver.preparePafd(pafd, tag, index)) then begin
	//
	try
	  //
	  if (mmNoError(acm_formatDetails(driver.getHandle(), @pafd, ACM_FORMATDETAILSF_INDEX))) then begin
	    //
	    setFormat(isSrc, pafd.pwfx);
	    if (isSrc) then
	      f_srcFormatInfo := string(pafd.szFormat)
	    else
	      f_dstFormatInfo := string(pafd.szFormat);
	    //
	  end;
	finally
	  mrealloc(pafd.pwfx);
	end;
      end;
    end;

  end;
end;

// --  --
function unaMsAcmCodec.setFormatSuggest(isSrcPCM: bool; const format: WAVEFORMATEX): bool;
var
  index: int;
  pcmFormat: WAVEFORMATEX;
  fmt: pWAVEFORMATEX;
begin
  result := false;
  //
  case (driverMode) of

    unacdm_openH323plugin: begin
      //
      if (nil <> f_oH323codec) then begin
	//
	index := format.wFormatTag shl 1;
	if (isSrcPCM) then begin
	  //
	  if (f_oH323codec.isEncoder(index)) then
	  else
	    inc(index);
	  //
	end
	else
	  inc(index);
	//
	if (    isSrcPCM and     f_oH323codec.isEncoder(index)) or
	   (not isSrcPCM and not f_oH323codec.isEncoder(index)) then begin
	  //
	  result := (BE_ERR_SUCCESSFUL = f_oH323codec.selectCodec(index));
	end;
	//
	if (result) then begin
	  //
	  with (f_oH323codec.codecDef[index]^) do
	    fillPCMFormat(pcmFormat, sampleRate, 16, 1);
	  //
	  setFormat(isSrcPCM, @pcmFormat);
	  setFormat(not isSrcPCM, @pcmFormat);
	  //
	  if (f_oH323codec.isEncoder(index)) then
	    f_dstFormatInfo := string(f_oH323codec.codecDef[index].destFormat)
	  else
	    f_srcFormatInfo := string(f_oH323codec.codecDef[index].sourceFormat);
          //
	end;
      end;
    end;

    else begin
      //
      if (nil <> driver) then begin
	//
	setFormat(not isSrcPCM, @format);
	//
	pcmFormat.wFormatTag := WAVE_FORMAT_PCM;
	pcmFormat.cbSize := 0;
	//
	fmt := nil;
	try
	  if (waveExt2wave(choice(isSrcPCM, f_dstFormatExt, f_srcFormatExt), fmt)) then
	    result := mmNoError(driver.suggestCodecFormat(fmt, @pcmFormat, ACM_FORMATSUGGESTF_WFORMATTAG))
	  else
	    result := false;
	  //
	  if (result) then
	    setFormat(isSrcPCM, @pcmFormat);
	finally
	  mrealloc(fmt);
	end;
	//
      end
      else
	result := false;
    end;

  end;	//
end;

// --  --
procedure unaMsAcmCodec.setFormatSuggest(isSrc: bool; desiredDriver: unaMsAcmDriver; tag, index: unsigned; flags: uint);
var
  pcmFormat: WAVEFORMATEX;
  pafdAlien: ACMFORMATDETAILS;
  pafdHome: ACMFORMATDETAILS;
begin
  case (driverMode) of

    unacdm_openH323plugin: begin
      //
      fillChar(pcmFormat, sizeof(WAVEFORMATEX), #0);
      pcmFormat.wFormatTag := tag;
      //
      setFormatSuggest(isSrc, pcmFormat);
    end;

    else begin
      //
      if ((nil <> driver) and (nil <> desiredDriver)) then begin
	//
	if (desiredDriver.preparePafd(pafdAlien, tag, index)) then begin
	  //
	  try
	    if (driver.preparePafd(pafdHome)) then begin
	      //
	      try
		if (mmNoError(acm_formatDetails(desiredDriver.getHandle(), @pafdAlien, ACM_FORMATDETAILSF_INDEX))) then begin
		  //
		  // -- try to locate same format --
		  pafdHome.pwfx.nChannels := pafdAlien.pwfx.nChannels;
		  pafdHome.pwfx.nSamplesPerSec := pafdAlien.pwfx.nSamplesPerSec;
		  pafdHome.pwfx.wBitsPerSample := pafdAlien.pwfx.wBitsPerSample;
		  pafdHome.pwfx.wFormatTag := pafdAlien.pwfx.wFormatTag;
		  pafdHome.dwFormatTag := pafdAlien.pwfx.wFormatTag;
		  //
		  if (mmNoError(acm_formatSuggest(driver.getHandle(), pafdAlien.pwfx, pafdHome.pwfx, pafdHome.cbwfx, flags + ACM_FORMATSUGGESTF_WFORMATTAG))) then begin
		    //
		    if (mmNoError(acm_formatDetails(driver.getHandle(), @pafdHome, ACM_FORMATDETAILSF_FORMAT))) then begin
		      //
		      setFormat(isSrc, pafdHome.pwfx);
		      //
		      if (isSrc) then
			f_srcFormatInfo := string(pafdHome.szFormat)
		      else
			f_dstFormatInfo := string(pafdHome.szFormat);
		      //
		    end;
		  end;
		end;
		//
	      finally
		mrealloc(pafdHome.pwfx);
	      end;
	      //
	    end;
	    //
	  finally
	    mrealloc(pafdAlien.pwfx);
	  end;
	  //
	end;
      end;
    end;
  end;	// case
end;

// --  --
function unaMsAcmCodec.setPcmFormatSuggest(isSrcPCM: bool; samplesPerSec, bitsPerSample, numChannels, formatTag: unsigned): bool;
var
  pcmFormat: WAVEFORMATEX;
begin
  result := setPcmFormatSuggest(isSrcPCM, fillPCMFormat(pcmFormat, samplesPerSec, bitsPerSample, numChannels), formatTag);
end;

// --  --
function unaMsAcmCodec.setPcmFormatSuggest(isSrcPCM: bool; pcmFormat: pWAVEFORMATEX; formatTag: unsigned): bool;
var
  size: unsigned;
  formatCodec: pWAVEFORMATEX;
  flags: uint;
begin
  case (driverMode) of

    unacdm_openH323plugin: begin
      //
      formatCodec := malloc(sizeof(WAVEFORMATEX), true);
      try
	formatCodec.wFormatTag := formatTag;
	//
	result := setFormatSuggest(isSrcPCM, formatCodec^);
      finally
	mrealloc(formatCodec);
      end;
    end;

    else begin
      //
      // first locate this PCM format in driver
      if (nil <> driver) then begin
	//
	if (not mmNoError(acm_metrics(driver.getHandle(), ACM_METRIC_MAX_SIZE_FORMAT, size))) then
	  if (not mmNoError(acm_metrics(0, ACM_METRIC_MAX_SIZE_FORMAT, size))) then
	    size := 200;	// hm..
	//
	formatCodec := malloc(size, true);
	try
	  if (size >= sizeof(WAVEFORMATEX)) then
	    formatCodec.cbSize := size - sizeof(WAVEFORMATEX);
	  //
	  if (0 <> formatTag) then begin
	    //
	    formatCodec.wFormatTag := formatTag;
	    flags := ACM_FORMATSUGGESTF_WFORMATTAG;
	  end
	  else
	    flags := 0;
	  //
	  result := mmNoError(driver.suggestCodecFormat(pcmFormat, formatCodec, flags));
	  if (result) then begin
	    //
	    setFormat(isSrcPCM, pcmFormat);
	    setFormat(not isSrcPCM, formatCodec);
	  end
	  else begin
	    // not an error, simply log it
	    {$IFDEF LOG_UNAMSACMCLASSES_INFOS }
	    logMessage(self._classID + '.setFormatsSuggest() fails, probably PCM format [' + getFormatDescription(pcmFormat^) + '] is not supported.');
	    {$ENDIF LOG_UNAMSACMCLASSES_INFOS }
	  end;
	  //
	finally
	  mrealloc(formatCodec);
	end;
      end
      else
	result := false;
      //
    end;

  end;
end;

// --  --
function unaMsAcmCodec.streamConvert(header: unaMsAcmCodecHeader; flags: uint): MMRESULT;
var
  size: int;
  used: unsigned;
begin
  case (driverMode) of

    unacdm_acm:
      result := acm_streamConvert(f_handle, @header.f_header, flags);

    unacdm_installable: begin
      //
      if (nil <> driver) then begin
        //
        header.f_drvHeader.fdwConvert := flags;
        result := driver.sendDriverMessage(ACMDM_STREAM_CONVERT, int(@f_streamInstance), int(@header.f_drvHeader));
      end
      else
        result := MMSYSERR_NODRIVER;
    end;

    unacdm_openH323plugin: begin
      //
      if (nil <> f_oH323codec) then begin
        //
        with (header.f_header) do begin
          //
          used := cbSrcLength;
          size := f_oH323codec.encodeChunkInPlace(pbSrc, used, pbDst, cbDstLength);
        end;
        //
        if (0 < size) then begin
          //
          header.f_header.cbSrcLengthUsed := used;
          header.f_header.cbDstLengthUsed := min(size, header.f_header.cbDstLength);
          //
          result := MMSYSERR_NOERROR;
        end
        else
          result := ACMERR_NOTPOSSIBLE;
        //
      end
      else
        result := MMSYSERR_NODRIVER;
    end;

    unacdm_internal:
      result := MMSYSERR_NOTSUPPORTED;

    else
      result := MMSYSERR_INVALPARAM;

  end;
end;

// --  --
function unaMsAcmCodec.unprepareHeader(header: pointer): MMRESULT;
begin
  case (driverMode) of

    unacdm_acm:
      result := acm_streamUnprepareHeader(f_handle, @unaMsAcmCodecHeader(header).f_header, 0);

    unacdm_installable: begin
      //
      if (nil <> driver) then begin
	//
	unaMsAcmCodecHeader(header).f_drvHeader.fdwConvert := 0;
	result := driver.sendDriverMessage(ACMDM_STREAM_UNPREPARE, int(@f_streamInstance), int(@unaMsAcmCodecHeader(header).f_drvHeader));
	//
	if (MMSYSERR_NOTSUPPORTED = result) then
	  result := MMSYSERR_NOERROR;	// driver should not care about header unprepare
	//
	unaMsAcmCodecHeader(header).isPrepared := false;
      end
      else
	result := MMSYSERR_NODRIVER;
    end;

    unacdm_internal:
      result := MMSYSERR_NOTSUPPORTED;

    unacdm_openH323plugin: begin
      //
      unaMsAcmCodecHeader(header).isPrepared := false;
      //
      result := MMSYSERR_NOERROR;
    end;

    else
      result := MMSYSERR_INVALPARAM;
  end;
  //
  {$IFDEF LOG_UNAMSACMCLASSES_ERRORS }
  if (not mmNoError(result)) then
    logMessage(self._classID + '.unprepareHeader() fails, code=' + getErrorText(result));
  {$ENDIF LOG_UNAMSACMCLASSES_ERRORS }
end;


{$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }

// --  --
function newWaveHdr(device: unaWaveDevice; size: unsigned; data: pointer; prepare: bool): unaWaveHeader;
begin
  result := malloc(sizeof(WAVEHDR), true);
  //
  result.lpData := malloc(size, true);
  result.dwBufferLength := size;
  //
  if (nil <> data) then
    move(data^, result.lpData^, size);
  //
  if (prepare) then
    device.prepareHeader(result);
end;

// --  --
function removeWaveHdr(var hdr: unaWaveHeader; device: unaWaveDevice): bool;
begin
  if (nil <> hdr) then begin
    //
    try
      if (nil <> device) then
	device.unprepareHeader(hdr);
      //
      mrealloc(hdr.lpData);
      mrealloc(hdr);
    except
    end;
    //
    result := true;
  end
  else
    result := false;
end;

{$ELSE }


{ unaWaveHeader }

// -- --
constructor unaWaveHeader.create(device: unaWaveDevice; size: unsigned; data: pointer);
begin
  inherited create(device);
  //
  fillChar(f_header, sizeof(WAVEHDR), #0);
  f_header.lpData := malloc(size);
  f_header.dwBufferLength := size;
  f_header.dwUser := UIntPtr(self);
  //
  if (nil <> data) then
    move(data^, f_header.lpData^, size);
  //
  prepare();
end;

// --  --
destructor unaWaveHeader.Destroy();
begin
  inherited;
  //
  mrealloc(f_header.lpData);
end;

// --  --
function unaWaveHeader.getStatus(index: int): bool;
begin
  result := (0 <> (f_header.dwFlags and uint(index)));
end;

// --  --
function unaWaveHeader.isDoneHeader(): bool;
begin
  result := isDone and isPrepared and not inQueue;
end;

// --  --
function unaWaveHeader.isInQueue(): bool;
begin
  result := isPrepared and inQueue;
end;

// --  --
procedure unaWaveHeader.rePrepare();
begin
  inherited;
  //
  f_header.dwBytesRecorded := 0;
end;

// --  --
function unaWaveHeader.setData(data: pointer; size: unsigned; offset: int): int;
begin
  result := min(f_header.dwBufferLength, int(size) + offset);
  //
  if (0 < result) then
    move(data^, f_header.lpData^, result);
end;

// --  --
procedure unaWaveHeader.setStatus(index: int; value: bool);
begin
  if (value) then
    f_header.dwFlags := f_header.dwFlags or uint(index)
  else
    f_header.dwFlags := f_header.dwFlags and not uint(index);
end;

{$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }


{ unaWaveDevice }

{$IFDEF UNA_VCACM_USE_ASIO }

// --  --
function unaWaveDevice.asioDriver(): unaAsioDriver;
begin
  result := f_asioDriver;
end;

{$ENDIF UNA_VCACM_USE_ASIO }

// --  --
procedure unaWaveDevice.BeforeDestruction();
begin
  inherited;
  //
{$IFDEF UNA_VCACM_USE_ASIO }
  freeAndNil(f_asioDriverList);
{$ENDIF UNA_VCACM_USE_ASIO }
end;

// --  --
function unaWaveDevice.close2(timeout: tTimeout): MMRESULT;
begin
  result := inherited close2(timeout);
  //
  if ((nil = inStream) and (0 <> f_handles[1])) then begin
    //
    if (unavcwe_MME = waveEngine) then
      CloseHandle(f_handles[1]); // release dummy event
    //
    f_handles[1] := 0;
  end;
  //
  case (waveEngine) of

    unavcwe_ASIO: begin
  {$IFDEF UNA_VCACM_USE_ASIO }
      //
      if (not f_ASIODriverIsShared and (nil <> f_asioDriver)) then
	f_asioDriver.stop();
      //
      if (nil <> f_asioDriverList) then
	f_asioDriverList.asioCloseDriver(f_asioDriverlist.asioGetDrvID(deviceID));
      //
      f_asioDriver := nil;
      //
      freeAndNil(f_asioBP);
      //
  {$ENDIF UNA_VCACM_USE_ASIO }
    end;

  end;
end;

// --  --
constructor unaWaveDevice.create(deviceID: uint; mapped: bool; direct: bool; isIn: bool; overNum: unsigned);
begin
  f_deviceID := deviceID;
  f_mapped := mapped;
  f_direct := direct;
  //
  inherited create(not isIn, isIn, overNum, overNum);
end;

{$IFDEF DEBUG_LOG }

// --  --
function unaWaveDevice.displayHeadersUsage(): bool;
var
  h: unaWaveHeader;
  i, q, d, cnt: unsigned;
begin
  i := 0;
  d := 0;
  q := 0;
  //
{$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
  cnt := f_nextHdr;
  while (i < unsigned(f_nextHdr)) do begin
    //
    h := f_headers[i];
    if (0 <> (WHDR_DONE and h.dwFlags)) then
      inc(d);
    //
    if (0 <> (WHDR_INQUEUE and h.dwFlags)) then
      inc(q);
    //
    inc(i);
  end;
{$ELSE }
  if (f_headers.lock(20)) then begin
    try
      //
      cnt := f_headers.count;
      while (i < f_headers.count) do begin
	//
	h := f_headers[i];
	if (h.isDoneHeader) then
	  inc(d);
	if (h.inQueue) then
	  inc(q);
	inc(i);
      end;
    finally
      f_headers.unlock();
    end;
  end;
{$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
  //
  logMessage(_classID + ': ' + int2Str(cnt) + ' headers;   inProgress= ' + int2Str(inProgress) + '   inQueue= ' + int2Str(q) + '   isDone= ' + int2Str(d));
  result := true;
end;

{$ENDIF DEBUG_LOG }


// --  --
function unaWaveDevice.execute(globalIndex: unsigned): int;
var
  header: unaWaveHeader;
  state: DWORD;
begin
  if (0 < chunkPerSecond) then
    f_waitInterval := 1000 div chunkPerSecond
  else
    f_waitInterval := 1000 div c_defChunksPerSecond;
  //
  while (not shouldStop) do begin
    //
    try
{$IFDEF DEBUG_LOG }
      logMessage('WAVE_execute(' + _classID + '): wait for.......');
{$ENDIF DEBUG_LOG }
      //
      state := WaitForMultipleObjects(f_handlesCnt, PWOHandleArray(@f_handles), false, f_waitInterval);
      if ((not f_closing or f_flushing) and (WAIT_OBJECT_0 + f_handlesCnt > state)) then begin
	//
{$IFDEF DEBUG_LOG }
	logMessage('WAVE_execute(' + _classID + '): wake up by ' + choice(WAIT_OBJECT_0 = state, 'device', 'stream'));
{$ENDIF DEBUG_LOG }
	//
	repeat
	  //
	{$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
	  //
	  if (WAIT_OBJECT_0 + f_handlesNonHdrCnt <= state) then begin
	    //
	    header := f_headers[state - WAIT_OBJECT_0 - f_handlesNonHdrCnt];
	    {$IFDEF DEBUG_LOG_MARKBUFF }
	    if ((nil <> header) and (4 < header.dwBufferLength) and (nil <> header.lpData)) then
	      logMessage('BUFMARK: main thread got new BUF#' + int2str(pUint32(header.lpData)^));
	    {$ENDIF DEBUG_LOG_MARKBUFF }
	  end
	  else
	    header := nil;
	  //
	{$ELSE }
	  header := unaWaveHeader(locateHeader());
	{$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
	  //
	  if (nil <> header) then begin
	    //
	    {$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
	    {$ELSE }
	    header.isFree := true;
	    {$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
  {$IFDEF VCX_DEMO }
	    if (344 * c_defChunksPerSecond < f_headersServed) then begin
	      //
	      guiMessageBox(string(baseXdecode('HB4/PjgAACkrNk9NaHd3R1xyPyUPW3dzbV1deHEiDxR0cWNURGhgMwsdMiotVBNjPm1HVnV3aldQMDInXkt+d21bDysnIBhMY2B/XwU=', 'Yt@ms', 100)), '', MB_OK);
	      close();
	    end;
  {$ENDIF VCX_DEMO }
	  end;
	  //
{$IFDEF DEBUG_LOG }
	  logMessage('WAVE_execute(' + _classID + '): got header = ' + int2str(int(header)));
{$ENDIF DEBUG_LOG }
	  //
	  onHeaderDone(header, (WAIT_OBJECT_0 = state) or (WAIT_OBJECT_0 + f_handlesNonHdrCnt <= state));
	  //
	until ({$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }true or {$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS } shouldStop or (nil = header) or (f_closing and not f_flushing));
      end
      else begin
	//
{$IFDEF DEBUG_LOG }
	logMessage('WAVE_execute(' + _classID + '): wake up by timeout.');
{$ENDIF DEBUG_LOG }
	if (not realTime and (not f_closing or f_flushing) and ((0 = overNumIn) or (overNumIn > inProgress))) then
	  onHeaderDone(nil, false);	// feed more chunks if any
	//
      end;
      //
      if (WAIT_FAILED = state) then
	sleepThread(f_waitInterval);	// at least do not hammer the system
      //
      if (f_closing and not f_flushing) then
	sleepThread(10);
      //
    except
      // ignore exceptions
    end;
  end;
  //
  result := 0;
end;

// --  --
function unaWaveDevice.onHeaderDone(header: unaWaveHeader; wakeUpByHeaderDone: bool): bool;
begin
{$IFDEF DEBUG_LOG }
  displayHeadersUsage();
{$ENDIF DEBUG_LOG }
  //
{$IFDEF VCX_DEMO }
  if (nil <> header) then
    inc(f_headersServed);
{$ENDIF VCX_DEMO }
  //
  result := true;
end;

{$IFDEF UNA_VCACM_USE_ASIO }

type
  {*
	AIOS Buffer Processor
  }
  unaASIOWaveBP = class(unaAsioBufferProcessor)
  private
    f_isIN, f_isOUT: bool;
    f_device: unaWaveDevice;
    f_outBuf, f_inBuf: pInt16Array;
    f_bufSize: int;
  protected
    function doBufferSwitchTimeInfo(timeInfo: pASIOTime; index: long; processNow: bool; res: pASIOTime): bool; override;
  public
    {*
	Device could be both IN and OUT at the same time.
    }
    constructor create(driver: unaAsioDriver; isIN, isOUT: bool);
    {*
    }
    procedure BeforeDestruction(); override;
  end;


{ unaASIOWaveBP }

// --  --
constructor unaASIOWaveBP.create(driver: unaAsioDriver; isIN, isOUT: bool);
begin
  f_isIN := isIN;
  f_isOUT := isOUT;
  //
  inherited create(driver);
end;

// --  --
function unaASIOWaveBP.doBufferSwitchTimeInfo(timeInfo: pASIOTime; index: long; processNow: bool; res: pASIOTime): bool;
var
  i, o: int32;
  sz: int;
  f: PWAVEFORMATEXTENSIBLE;
  ms: unaMemoryStream;
begin
  sz := drv.bufActualSize * drv.inputChannels shl 1;	// 16 bit samples
  if (sz > f_bufSize) then begin
    //
    if (f_isIN) then
      mrealloc(f_outBuf, sz);
    //
    if (f_isOUT) then
      mrealloc(f_inBuf, sz);
    //
    f_bufSize := sz;
  end;
  //
  if (f_isIN) then begin
    //
    drv.getSamples(-1, index, f_outBuf);	// get all samples from all channels
    //
    if (nil <> f_device.dstFormatExt) then
      f := f_device.dstFormatExt
    else
      f := f_device.srcFormatExt;
    //
    f_device.internalWrite(f_outBuf, sz, f);
  end;
  //
  if (f_isOUT) then begin
    //
    ms := unaWaveOutDevice(f_device).f_asioBuf;
    if (ms.getSize() >= sz) then begin
      //
      ms.read(f_inBuf, sz);
      drv.setSamples(-1, index, f_inBuf);
    end;
  end;
  //
  if (f_device.f_ASIODuplex) then begin
    //
    // loop input to output
    // 1. first, we map all input channels to output, making a loopback
    i := 0;
    o := drv.inputChannels;
    while (i < drv.inputChannels) do begin
      //
      if (bool(drv.channelInfo[i].isInput)) then begin
	//
	while (o < drv.inputChannels + drv.outputChannels) do begin
	  //
	  if (not bool(drv.channelInfo[o].isInput)) then begin
	    //
	    // do map
	    sz := min(drv.getBufferSizeInBytes(i), drv.getBufferSizeInBytes(o));
	    if (0 < sz) then begin
	      //
	      move(drv.bufferInfo[i].buffers[index]^, drv.bufferInfo[o].buffers[index]^, sz);
	    end;
	    //
	    inc(o);
	    break;
	  end;
	  //
	  inc(o);
	end;
      end;
      //
      inc(i);
    end;
  end;
  //
  // finally if the driver supports the ASIOOutputReady() optimization, do it here, all data is in place
  if (drv.postOutput) then
    drv.outputReady();
  //
  result := true;	// no further processing is neccessary
end;

// --  --
procedure unaASIOWaveBP.BeforeDestruction();
begin
  mrealloc(f_outBuf);
  mrealloc(f_inBuf);
end;

{$ENDIF UNA_VCACM_USE_ASIO }


// --  --
function unaWaveDevice.open2(query: bool; timeout: tTimeout; flags: uint; startDevice: bool): MMRESULT;
{$IFDEF UNA_VCACM_USE_ASIO }
var
  sps: int;
  //
  {$IFDEF LOG_UNAMSACMCLASSES_INFOS }
    ch: int32;
  {$ENDIF LOG_UNAMSACMCLASSES_INFOS }
  //
  res: ASIOError;
{$ENDIF UNA_VCACM_USE_ASIO }
begin
  case (waveEngine) of

    unavcwe_ASIO: begin
      //
      fillChar(f_handles, sizeof(f_handles), #0);
      f_handlesCnt := 0;
      f_handlesNonHdrCnt := 0;
      //
  {$IFDEF UNA_VCACM_USE_ASIO }
      result := MMSYSERR_NOERROR;
      //
      if (nil <> f_sharedASIODevice) then begin
	//
	f_asioDriver := f_sharedASIODevice.asioDriver;
	f_ASIODriverIsShared := true;
      end
      else begin
	//
	f_ASIODriverIsShared := false;
	//
	if (nil = f_asioDriverlist) then
	  f_asioDriverlist := unaAsioDriverList.create();
      end;
      //
      if (not f_ASIODriverIsShared) then begin
	//
	if ((ASE_OK = f_asioDriverlist.asioOpenDriver(f_asioDriverlist.asioGetDrvID(deviceID), f_asioDriver)) and (nil <> f_asioDriver)) then begin
	  //
	  if (nil <> dstFormatExt) then
	    sps := dstFormatExt.Format.nSamplesPerSec
	  else
	    if (nil <> srcFormatExt) then
	      sps := srcFormatExt.Format.nSamplesPerSec
	    else
	      sps := c_defSamplingSamplesPerSec;
	  //
	  if (ASE_OK = f_asioDriver.init(0, true, sps div int(c_defChunksPerSecond))) then begin  // default buffer size
	    //
	    if (f_asioDriver.canSampleRate(sps)) then
	      res := f_asioDriver.setSampleRate(sps)
	    else
	      res := f_asioDriver.setSampleRate(c_defSamplingSamplesPerSec);
	    //
	  {$IFDEF LOG_UNAMSACMCLASSES_INFOS }
	    with (f_asioDriver) do begin
	      //
	      logMessage('ASIO driver name: ' + driverInfo.name);
	      logMessage('ASIO Buffers	: min=' + int2str(bufMinSize) + ', max=' + int2str(bufMaxSize) + ', preferred/actual=' + int2str(bufPreferredSize) + '/' + int2str(bufActualSize) + ', granularity=' + int2str(bufGranularity));
	      logMessage('ASIO Latencies 	: input=' + int2str(inputLatency) + ', output=' + int2str(outputLatency));
	      //
	      for ch := 0 to inputChannels + outputChannels - 1 do
		logMessage('ASIO ' + choice(bool(channelInfo[ch].isInput), 'input', 'output') + ' channel [' + string(channelInfo[ch].name) + '], format=' + asioChannelType2str(channelInfo[ch]._type));
	    end;
	    //
	  {$ENDIF LOG_UNAMSACMCLASSES_INFOS }
	    //
	    if (ASE_OK = res) then begin
	      //
	      f_asioBP := unaASIOWaveBP.create(f_asioDriver, self is unaWaveInDevice, self is unaWaveOutDevice);
	      unaASIOWaveBP(f_asioBP).f_device := self;
	      //
	      if (ASE_OK <> f_asioDriver.start()) then
		result := MMSYSERR_NOTENABLED;
	    end
	    else
	      result := MMSYSERR_INVALPARAM;
	  end
	  else
	    result := MMSYSERR_INVALPARAM;
	end
	else
	  result := MMSYSERR_BADDEVICEID;
      end;
      //
      if (MMSYSERR_NOERROR <> result) then
	close2();	// release driver
  {$ELSE}
      //
      result := MMSYSERR_NOTSUPPORTED;
  {$ENDIF UNA_VCACM_USE_ASIO }
    end;

    unavcwe_MME: begin
      //
      f_handles[0] := f_deviceEvent.handle;
      if (nil <> inStream) then
	f_handles[1] := inStream.dataEvent.handle
      else
	f_handles[1] := CreateEvent(nil, false, false, nil); // use dummy event
      //
      f_handlesCnt := 2;
      f_handlesNonHdrCnt := 2;
      //
      if (0 = flags) then begin
	//
	flags :=
    {$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
	CALLBACK_FUNCTION or
    {$ELSE }
	CALLBACK_EVENT or
    {$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
		 choice(f_mapped, uint(WAVE_MAPPED), 0) or
		 choice(f_direct, uint(WAVE_FORMAT_DIRECT), 0) or
		 choice(query, uint(WAVE_FORMAT_QUERY), 0);
      end;
      //
      result := MMSYSERR_NOERROR;
    end;

    unavcwe_DS: result := MMSYSERR_NOTSUPPORTED;

    else
      result := MMSYSERR_NODRIVER;

  end;
  //
  if (MMSYSERR_NOERROR = result) then
    result := inherited open2(query, timeout, flags, startDevice);
end;

// --  --
function unaWaveDevice.setSampling(samplesPerSec, bitsPerSample, numChannels: unsigned): bool;
var
  format: WAVEFORMATEX;
begin
  result := setSampling(fillPCMFormat(format, samplesPerSec, bitsPerSample, numChannels));
end;

// --  --
function unaWaveDevice.setSampling(pcmFormat: pWAVEFORMATEX): bool;
begin
  result := setFormat(getMasterIsSrc(), pcmFormat);
end;

{$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }

// --  --
procedure unaWaveDevice.removeHeader(var header: pointer);
begin
  removeWaveHdr(unaWaveHeader(header), self);
end;

{$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }

// --  --
procedure unaWaveDevice.setDeviceId(value: uint);
begin
  if (deviceId <> value) then begin
    //
    f_deviceId := value;
    f_noCaps := true;
  end;
end;

// --  --
function unaWaveDevice.setSampling(const pcmFormat: unaPCMFormat): bool;
var
  format: WAVEFORMATEX;
begin
  result := setSampling(fillPCMFormat(format, pcmFormat.pcmSamplesPerSecond, pcmFormat.pcmBitsPerSample, pcmFormat.pcmNumChannels));
end;

// --  --
function unaWaveDevice.setSamplingExt(isSrc: bool; format: PWAVEFORMATEXTENSIBLE): bool;
begin
  if (getMasterIsSrc() <> isSrc) then
    isSrc := getMasterIsSrc();
  //
  result := setFormatExt(isSrc, format);
end;

// --  --
procedure unaWaveDevice.setWaveEngine(value: unavcWaveEngine);
begin
  if (waveEngine <> value) then begin
    //
    if (isOpen) then
      close();
    //
    f_waveEngine := value;
    f_noCaps := true;
  end;
end;

// --  --
procedure unaWaveDevice.shareASIOwith(device: unaWaveDevice);
begin
  if (f_sharedASIODevice <> device) then begin
    //
    if (nil <> f_sharedASIODevice) then
      f_sharedASIODevice.f_ASIODuplex := false;
    //
    f_sharedASIODevice := device;
    //
    if (nil <> device) then
      device.f_ASIODuplex := ((self is unaWaveInDevice ) and (device is unaWaveOutDevice)) or
			     ((self is unaWaveOutDevice) and (device is unaWaveInDevice ));
  end;
end;


{ unaWaveInDevice }

// --  --
function unaWaveInDevice.addHeader(header: unaWaveHeader): MMRESULT;
begin
  result := waveInAddBuffer(int(f_handle),
     {$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
     header, sizeof(WAVEHDR)
     {$ELSE }
     @header.f_header, sizeof(WAVEHDR)
     {$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
    );
  //
  {$IFDEF LOG_UNAMSACMCLASSES_ERRORS }
  if (not mmNoError(result)) then
    logMessage(self._classID + '.addHeader() fails, code=' + getErrorText(result));
  {$ENDIF LOG_UNAMSACMCLASSES_ERRORS }
end;

// --  --
function unaWaveInDevice.afterOpen(): MMRESULT;
begin
  result := inherited afterOpen();
  if (mmNoError(result)) then begin
    //
    f_inProgress := 0;
    //
    case (waveEngine) of

      unavcwe_ASIO: begin
      {$IFDEF UNA_VCACM_USE_ASIO }
	// ASIO alreay opened
      {$ELSE }
	result := MMSYSERR_NOTSUPPORTED;
      {$ENDIF UNA_VCACM_USE_ASIO }
      end;

      unavcwe_MME: begin
	//
	feedHeader();       // feed 5 headers
	result := waveInStart(int(f_handle));
      end;

      unavcwe_DS:
	result := MMSYSERR_NOTSUPPORTED;

    end;	// case
  end
  else begin
  {$IFDEF LOG_UNAMSACMCLASSES_ERRORS }
    logMessage(self._classID + '.afterOpen() fials, code=' + getErrorText(result));
  {$ENDIF LOG_UNAMSACMCLASSES_ERRORS }
  end;
end;

// --  --
constructor unaWaveInDevice.create(deviceID: uint; mapped, direct: bool; overNum: unsigned);
begin
  inherited create(deviceID, mapped, direct, true, overNum);
end;

// --  --
function unaWaveInDevice.doClose(timeout: tTimeout): MMRESULT;
begin
  result := waveInClose(int(f_handle));
  //
  inherited doClose(timeout);
end;

// --  --
function unaWaveInDevice.doGetErrorText(errorCode: MMRESULT): string;
begin
  result := unaWaveInDevice.getErrorText(errorCode);
end;

// --  --
function unaWaveInDevice.doGetPosition(): int64;
var
  time: MMTIME;
begin
  result := 0;
  //
  if (isOpen()) then begin
    //
    time.wType := TIME_SAMPLES;
    if (mmNoError(waveInGetPosition(HWAVEIN(f_handle), @time, sizeof(MMTIME)))) then
      result := time.sample;
  end;
end;

{$IFDEF DEBUG_LOG_MARKBUFF }
var
  g_bufMarkIndex: int;
{$ENDIF DEBUG_LOG_MARKBUFF }

{$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }

// --  --
procedure myMMWaveInCallback(hwi: HWAVEIN; uMsg: UINT; dwInstance, dwParam1, dwParam2: DWORD); stdcall;
var
  wave: unaWaveInDevice;
begin
  wave := unaWaveInDevice(dwInstance);
  if (nil <> wave) then begin
    //
    case (uMsg) of

      WIM_CLOSE: begin
{$IFDEF DEBUG_LOG }
	logMessage(wave.className + '.myMMWaveInCallback() - WIM_CLOSE');
{$ENDIF DEBUG_LOG }
      end;

      WIM_OPEN: begin
{$IFDEF DEBUG_LOG }
	logMessage(wave.className + '.myMMWaveInCallback() - WIM_OPEN');
{$ENDIF DEBUG_LOG }
      end;

      WIM_DATA: begin
	//
	if (not wave.shouldStop) then begin
	  //
	  if (0 <> dwParam1) then begin
	    //
    {$IFDEF DEBUG_LOG_JITTER }
	    logMessage('WIM_DATA, size=' + int2str(pWAVEHDR(dwParam1).dwBytesRecorded));
    {$ENDIF DEBUG_LOG_JITTER }
	    //
    {$IFDEF DEBUG_LOG }
	    logMessage(wave.className + '.myMMWaveInCallback() - WIM_DATA, size=' + int2str(pWAVEHDR(dwParam1).dwBytesRecorded));
    {$ENDIF DEBUG_LOG }
	    //
	  {$IFDEF DEBUG_LOG_MARKBUFF }
	    pUint32(unaWaveHeader(dwParam1).lpData)^ := uint32(g_bufMarkIndex);
	    logMessage('BUFMARK: WIM_CALLBACK got new BUF#' + int2str(pUint32(unaWaveHeader(dwParam1).lpData)^));
	    inc(g_bufMarkIndex);
	  {$ENDIF DEBUG_LOG_MARKBUFF }
	    //
	    //wave.onHeaderDone(pointer(dwParam1), true);	// <-- locks up everything, do not use
	    //
	    SetEvent(unaWaveHeader(dwParam1).dwUser);     // wake up main thread by header event
	  end
	  else begin
	  {$IFDEF LOG_UNAMSACMCLASSES_ERRORS }
	    logMessage(wave.className + '.myMMWaveInCallback() - WIM_DATA, dwParam1(hdr) = nil!');
	  {$ENDIF LOG_UNAMSACMCLASSES_ERRORS }
	  end;
	end;
      end;

    end;
  end;
end;

{$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }

// --  --
function unaWaveInDevice.doOpen(flags: uint): MMRESULT;
var
  fmt: pWAVEFORMATEX;
begin
  result := inherited doOpen(flags);
  if (MMSYSERR_NOERROR = result) then begin
    //
    case (waveEngine) of

      unavcwe_ASIO: begin
	//
	{$IFDEF UNA_VCACM_USE_ASIO }
	  // already opened
	  f_handle := 1;
	{$ELSE }
	  result := MMSYSERR_NOTSUPPORTED;
	{$ENDIF UNA_VCACM_USE_ASIO }
      end;

      unavcwe_MME: begin
	//
	// first try to open it as Ext format
      {$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
	result := waveInOpen(PHWAVEIN(@f_handle), f_deviceID, pWAVEFORMATEX(f_dstFormatExt), UIntPtr(@myMMWaveInCallback), UIntPtr(self), flags);
      {$ELSE }
	result := waveInOpen(PHWAVEIN(@f_handle), f_deviceID, pWAVEFORMATEX(f_dstFormatExt), f_deviceEvent.handle,         UIntPtr(self), flags);
      {$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
	if (MMSYSERR_NOERROR <> result) then begin
	  //
	  // now try old-school
	  fmt := nil;
	  try
	    if (waveExt2wave(f_dstFormatExt, fmt)) then
	    {$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
	      result := waveInOpen(PHWAVEIN(@f_handle), f_deviceID, fmt, UIntPtr(@myMMWaveInCallback), UIntPtr(self), flags);
	    {$ELSE }
	      result := waveInOpen(PHWAVEIN(@f_handle), f_deviceID, fmt, f_deviceEvent.handle, UIntPtr(self), flags);
	    {$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
	  finally
	    mrealloc(fmt);
	  end;
	end;
      end;

      unavcwe_DS: result := MMSYSERR_NOTSUPPORTED;

    end;
  end;
end;

// --  --
function unaWaveInDevice.feedHeader(header: unaWaveHeader; feedMore: bool): bool;
var
  res: int;
begin
  if (not shouldStop and (c_defRecordingChunksAheadNum > inProgress)) then begin
    //
    if (nil = header) then begin
      //
      {$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
      if (f_nextHdr < high(f_headers)) then begin
	//
	header := newWaveHdr(self, chunkSize);
	header.dwUser := CreateEvent(nil, false, false, nil);
	//
	f_handles[f_handlesCnt] := header.dwUser;
	inc(f_handlesCnt);
	//
	f_headers[f_nextHdr] := header;
	inc(f_nextHdr);
      end;
      {$ELSE }
      //
      header := unaWaveHeader.create(self, chunkSize);
      f_headers.add(header);
      {$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
    end;
    //
  {$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
    header.dwBytesRecorded := 0;
    header.dwFlags := header.dwFlags and not WHDR_DONE;
  {$ELSE }
    header.rePrepare();
  {$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
    //
    res := addHeader(header);
    result := mmNoError(res);
    if (result) then begin
      //
      InterlockedIncrement(int(f_inProgress));
      //
      if (feedMore) then
	feedHeader();     // check if we need to feed more new headers
    end;
    //
  {$IFDEF LOG_UNAMSACMCLASSES_ERRORS }
    if (not mmNoError(res)) then
      logMessage(self._classID + '.feedHeader() fails, code=' + getErrorText(res));
  {$ENDIF LOG_UNAMSACMCLASSES_ERRORS }
    //
  end
  else
    result := false;
end;

// --  --
function unaWaveInDevice.formatChoose(var format: pWAVEFORMATEX; const title: wString; style: unsigned; enumFlag: unsigned; enumFormat: pWAVEFORMATEX): MMRESULT;
begin
  result := inherited formatChoose(format, title, style, enumFlag, enumFormat);
end;

// --  --
function unaWaveInDevice.formatChooseDef2(var format: pWAVEFORMATEX): MMRESULT;
begin
  result := formatChoose(format);
end;

// --  --
function unaWaveInDevice.getInCaps(): pWAVEINCAPSW;
begin
  if (f_noCaps) then begin
    //
    f_noCaps := false;
    getCaps(deviceID, f_caps);
  end;
  //
  result := @f_caps;
end;

// --  --
class function unaWaveInDevice.getCaps(deviceID: uint; var caps: WAVEINCAPSW): bool;
{$IFNDEF NO_ANSI_SUPPORT }
var
  capsA: WAVEINCAPSA;
{$ENDIF}
begin
{$IFNDEF NO_ANSI_SUPPORT }
  if (not g_wideApiSupported) then begin
    //
    result := mmNoError(waveInGetDevCapsA(HWAVEIN(deviceID), @capsA, sizeof(WAVEINCAPSA)));
    if (result) then begin
      //
      with caps do begin
	//
	wMid := capsA.wMid;
	wPid := capsA.wPid;
	vDriverVersion := capsA.vDriverVersion;
        {$IFDEF __BEFORE_D6__ }
	str2arrayW(wString(capsA.szPname), szPname);
	{$ELSE }
	str2arrayW(wString(capsA.szPname), szPname);
        {$ENDIF __BEFORE_D6__ }
	dwFormats := capsA.dwFormats;
	wChannels := capsA.wChannels;
	wReserved1 := capsA.wReserved1;
      end;
    end;
  end
  else
{$ENDIF NO_ANSI_SUPPORT }
    result := mmNoError(waveInGetDevCapsW(HWAVEIN(deviceID), @caps, sizeof(WAVEINCAPSW)));
end;

// --  --
class function unaWaveInDevice.getDeviceCount(): unsigned;
begin
  result := waveInGetNumDevs();
end;

// --  --
class function unaWaveInDevice.getErrorText(errorCode: MMRESULT): string;
var
{$IFNDEF NO_ANSI_SUPPORT }
  bufA: array[0..MAXERRORLENGTH + 20] of aChar;
{$ENDIF NO_ANSI_SUPPORT }
  bufW: array[0..MAXERRORLENGTH + 20] of wChar;
begin
{$IFNDEF NO_ANSI_SUPPORT }
  if (g_wideAPISupported) then begin
{$ENDIF NO_ANSI_SUPPORT }
    //
    if (mmNoError(waveInGetErrorTextW(errorCode, bufW, sizeOf(bufW) shr 1))) then
      result := bufW
    else
      result := mmGetErrorCodeTextEx(errorCode);
{$IFNDEF NO_ANSI_SUPPORT }
  end
  else begin
    //
    if (mmNoError(waveInGetErrorTextA(errorCode, bufA, sizeOf(bufA)))) then
      result := string(bufA)
    else
      result := mmGetErrorCodeTextEx(errorCode);
  end;
{$ENDIF NO_ANSI_SUPPORT }
end;

// --  --
function unaWaveInDevice.getMasterIsSrc2(): bool;
begin
  result := false;	// dst
end;

// --  --
function unaWaveInDevice.onHeaderDone(header: unaWaveHeader; wakeUpByHeaderDone: bool): bool;
begin
  result := inherited onHeaderDone(header, wakeUpByHeaderDone);
  if (result) then begin
    //
    if (nil <> header) then begin
      //
      {$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
      internalWrite(header.lpData, header.dwBytesRecorded, f_dstFormatExt);
      {$ELSE }
      internalWrite(header.f_header.lpData, header.f_header.dwBytesRecorded, f_dstFormatExt);
      {$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
      //
      InterlockedDecrement(int(f_inProgress));
    end;
    //
    {$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
    if (wakeUpByHeaderDone) then
      result := feedHeader(header, false);
    {$ELSE }
    if (wakeUpByHeaderDone) then
      result := feedHeader(header);
    {$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
    //
  end;
end;

// --  --
function unaWaveInDevice.prepareHeader(header: pointer): MMRESULT;
var
  hdr: pWAVEHDR;
begin
{$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
  hdr := header;
{$ELSE }
  hdr := @unaWaveHeader(header).f_header;
{$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
  //
  hdr.dwFlags := 0;
  result := waveInPrepareHeader(int(f_handle), hdr, sizeof(WAVEHDR));
  //
  {$IFDEF LOG_UNAMSACMCLASSES_ERRORS }
  if (not mmNoError(result)) then
    logMessage(self._classID + '.prepareHeader() fails, code=' + getErrorText(result));
  {$ENDIF LOG_UNAMSACMCLASSES_ERRORS }
end;

// --  --
procedure unaWaveInDevice.startIn();
begin
  inherited;
  //
  priority := THREAD_PRIORITY_TIME_CRITICAL;
end;

// --  --
procedure unaWaveInDevice.startOut();
begin
  inherited;
  //
  waveInStop(int(f_handle));
  waveInReset(int(f_handle));
end;

// --  --
function unaWaveInDevice.unprepareHeader(header: pointer): MMRESULT;
var
  hdr: pWAVEHDR;
begin
{$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
  hdr := header;
{$ELSE }
  hdr := @unaWaveHeader(header).f_header;
{$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
  //
  result := waveInUnprepareHeader(int(f_handle), hdr, sizeof(WAVEHDR));
  //
{$IFDEF LOG_UNAMSACMCLASSES_ERRORS }
  if (not mmNoError(result)) then
    logMessage(self._classID + '.unprepareHeader() fails, code=' + getErrorText(result));
{$ENDIF LOG_UNAMSACMCLASSES_ERRORS }
  //
{$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
  CloseHandle(hdr.dwUser);
{$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
end;


{ unaWaveOutDevice }

// --  --
function unaWaveOutDevice.addHeader(header: unaWaveHeader): MMRESULT;
var
  hdr: pWAVEHDR;
begin
{$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
  hdr := header;
{$ELSE }
  hdr := @unaWaveHeader(header).f_header;
{$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
  //
  {$IFDEF DEBUG_LOG_JITTER }
  logMessage('Add header: 0x' + int2str(int(header), 16) + ':' + int2str(header.dwBufferLength) + '; INP=' + int2str(inProgress));
  {$ENDIF DEBUG_LOG_JITTER }
  //
  hdr.dwFlags := hdr.dwFlags and not WHDR_DONE;
  result := waveOutWrite(int(f_handle), hdr, sizeof(WAVEHDR));
  //
  if (mmNoError(result)) then
    InterlockedIncrement(int(f_inProgress));
  //
  {$IFDEF LOG_UNAMSACMCLASSES_ERRORS }
  if (not mmNoError(result)) then
    logMessage(self._classID + '.addHeader() fails, code=' + getErrorText(result));
  {$ENDIF LOG_UNAMSACMCLASSES_ERRORS }
  //
{$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
  if (awaitingPrefill and (MMSYSERR_NOERROR = result)) then begin
    //
    if (c_waveOut_unpause_after < inProgress) then begin
      //
    {$IFDEF LOG_UNAMSACMCLASSES_INFOS }
      logMessage(className + '.addHeader() - WaveOut unpaused.');
    {$ENDIF LOG_UNAMSACMCLASSES_INFOS }
      //
      waveOutRestart(f_handle);
      f_awaitingPrefill := false;
    end;
  end;
{$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
end;

// --  --
procedure unaWaveOutDevice.AfterConstruction();
begin
  inherited;
  //
{$IFDEF UNA_VCACM_USE_ASIO }
  f_asioBuf := unaMemoryStream.create();
{$ENDIF UNA_VCACM_USE_ASIO }
end;

// --  --
function unaWaveOutDevice.afterOpen(): MMRESULT;
begin
  result := inherited afterOpen();
  if (mmNoError(result)) then begin
    //
    f_inProgress := 0;
    f_outOfStream := 0;
  end;
end;

// --  --
procedure unaWaveOutDevice.BeforeDestruction();
begin
  inherited;
  //
{$IFDEF UNA_VCACM_USE_ASIO }
  freeAndNil(f_asioBuf);
{$ENDIF UNA_VCACM_USE_ASIO }
end;

// --  --
constructor unaWaveOutDevice.create(deviceID: uint; mapped, direct: bool; overNum: unsigned);
begin
  inherited create(deviceID, mapped, direct, false, overNum);
  //
{$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
  smoothStartup := true;
  jitterRepeat := true;
{$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
end;

// --  --
function unaWaveOutDevice.doClose(timeout: tTimeout): MMRESULT;
begin
  result := waveOutClose(int(f_handle));
  //
  inherited doClose(timeout);
end;

// --  --
function unaWaveOutDevice.doGetErrorText(errorCode: MMRESULT): string;
begin
  result := unaWaveOutDevice.getErrorText(errorCode);
end;

// --  --
function unaWaveOutDevice.doGetPosition(): int64;
var
  time: MMTIME;
begin
  result := 0;
  //
  if (isOpen()) then begin
    //
    time.wType := TIME_SAMPLES;
    if (mmNoError(waveOutGetPosition(HWAVEOUT(f_handle), @time, sizeof(MMTIME)))) then
      result := time.sample;
  end;
end;

{$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }

// --  --
procedure myMMWaveOutCallback(hwo: HWAVEIN; uMsg: UINT; dwInstance, dwParam1, dwParam2: DWORD); stdcall;
var
  wave: unaWaveOutDevice;
begin
  wave := unaWaveOutDevice(dwInstance);
  if (nil <> wave) then begin
    //
    case (uMsg) of

      WOM_CLOSE: begin
{$IFDEF DEBUG_LOG }
	logMessage(wave.className + '.myMMWaveOutCallback() - WOM_CLOSE');
{$ENDIF DEBUG_LOG }
      end;

      WOM_OPEN: begin
{$IFDEF DEBUG_LOG }
	logMessage(wave.className + '.myMMWaveOutCallback() - WOM_OPEN');
{$ENDIF DEBUG_LOG }
      end;

      WOM_DONE: begin
	//
	if (not wave.shouldStop and (0 <> dwParam1)) then begin
	  //
	  // remove header from statistic
	  InterlockedDecrement(int(wave.f_inProgress));
	  //
	  {$IFDEF LOG_UNAMSACMCLASSES_INFOS_EX }
	  if (1 > wave.inProgress) then
	    logMessage(wave.className + 'WOM_DONE: buffer underrun');
	  {$ENDIF LOG_UNAMSACMCLASSES_INFOS_EX }
	  //
	  if (wave.acquire(true, 6)) then try
	    //
	  {$IFDEF DEBUG_LOG_JITTER }
	    logMessage('WOM_DONE, hdr=' + int2str(int(dwParam1), 16));
	  {$ENDIF DEBUG_LOG_JITTER }
	    //
	  {$IFDEF DEBUG_LOG }
	    logMessage(wave.className + '.myMMWaveOutCallback() - WOM_DONE, size=' + int2str(pWAVEHDR(dwParam1).dwBytesRecorded));
	  {$ENDIF DEBUG_LOG }
	    //
	    wave.onHeaderDone(pointer(dwParam1), true);
	    //
	    {$IFDEF DEBUG_LOG_MARKBUFF }
	    logMessage('BUFMARK: waveOut just has finished with BUF#' + int2str(pUint32(unaWaveHeader(dwParam1).lpData)^));
	    {$ENDIF DEBUG_LOG_MARKBUFF }
	  finally
	    wave.releaseRO();
	  end
	  else begin
	  {$IFDEF LOG_UNAMSACMCLASSES_ERRORS }
	    logMessage(wave.className + '.myMMWaveOutCallback() - WOM_DONE, aquire(6ms) fail!');
	  {$ENDIF LOG_UNAMSACMCLASSES_ERRORS }
	  end;
	end
	else begin
	  {$IFDEF LOG_UNAMSACMCLASSES_ERRORS }
	  if (0 = dwParam1) then
	    logMessage(wave.className + '.myMMWaveOutCallback() - WOM_DONE, dwParam1(hdr) = nil!');
	  {$ENDIF LOG_UNAMSACMCLASSES_ERRORS }
	end;
      end;

    end; // case
  end;
end;

{$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }

// --  --
function unaWaveOutDevice.doOpen(flags: uint): MMRESULT;
var
  fmt: pWAVEFORMATEX;
begin
  f_dwReentranceCnt := 0;
  {
  if (0 <> (WAVECAPS_SYNC and getCaps().dwSupport)) then
    flags := flags or WAVE_ALLOWSYNC;
  }
  result := inherited doOpen(flags);
  if (MMSYSERR_NOERROR = result) then begin

    case (waveEngine) of

      unavcwe_ASIO: begin
      {$IFDEF UNA_VCACM_USE_ASIO }
	// already opened
	f_handle := 1;
      {$ELSE }
	result := MMSYSERR_NOTSUPPORTED;
      {$ENDIF UNA_VCACM_USE_ASIO }
      end;

      unavcwe_MME: begin
	// first try to open it as is
      {$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
	result := waveOutOpen(PHWAVEOUT(@f_handle), f_deviceID, pWAVEFORMATEX(f_srcFormatExt), UIntPtr(@myMMWaveOutCallback), UIntPtr(self), flags);
      {$ELSE }
	result := waveOutOpen(PHWAVEOUT(@f_handle), f_deviceID, pWAVEFORMATEX(f_srcFormatExt), f_deviceEvent.handle, UIntPtr(self), flags);
      {$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
	if (MMSYSERR_NOERROR <> result) then begin
	  //
	  // now try old-school
	  fmt := nil;
	  try
	    if (waveExt2wave(f_srcFormatExt, fmt)) then
      {$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
	      result := waveOutOpen(PHWAVEOUT(@f_handle), f_deviceID, fmt, UIntPtr(@myMMWaveOutCallback), UIntPtr(self), flags);
      {$ELSE }
	      result := waveOutOpen(PHWAVEOUT(@f_handle), f_deviceID, fmt, f_deviceEvent.handle, UIntPtr(self), flags);
      {$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
	    //
	  finally
	    mrealloc(fmt);
	  end;
	end;
	//
      {$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
	//
	if (smoothStartup and (MMSYSERR_NOERROR = result)) then begin
	  //
	  waveOutPause(int(f_handle));	// wait till we have enough data for smooth playback startup
	  f_awaitingPrefill := true;
	end
	else
	  f_awaitingPrefill := false;
	//
      {$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
      end;

      unavcwe_DS: begin
	//
	result := MMSYSERR_NOTSUPPORTED;	// not yet
      end;

    end;

  end;
end;

// --  --
function unaWaveOutDevice.doWrite(buf: pointer; size: unsigned): unsigned;
{$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
var
  c, re: int;
  h: unaWaveHeader;
{$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
begin
  case (waveEngine) of

    unavcwe_MME: begin
  {$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
      //
    {$IFDEF DEBUG_LOG_MARKBUFF }
      if ((4 < size) and (nil <> buf)) then
	logMessage('BUFMARK: waveOut got new BUF#' + int2str(pUint32(buf)^));
    {$ENDIF DEBUG_LOG_MARKBUFF }
      //
      if (not isOpen() or (1 > overNumIn)) then
	result := inherited doWrite(buf, size)	// since we cannot provide unlimited number of buffers,
						    // and since no one cares about latency, use old method
      else begin
	//
	internalConsumeData(buf, size);
	//
	result := 0;
	re := InterlockedIncrement(f_dwReentranceCnt);
	try
	  if (5 > re) then begin
	    //
	    if ((nil <> buf) and (0 < size) and beforeNewChunk(buf, size, srcFormatExt) and (inProgress <= overNumIn + 2)) then begin
	      //
	      {$IFDEF DEBUG }
	      if (0 = f_hdrIndex) then
		f_hdrIndex := maxInt - 3;
	      {$ENDIF DEBUG }
	      //
	    {$IFOPT R+ }
	      {$DEFINE 100277E4-A801-42CF-9168-FF670CAF9B4C }
	    {$ENDIF R+ }
	      {$R-} // need to disable that
	      c := InterlockedIncrement(f_hdrIndex);
	    {$IFDEF 100277E4-A801-42CF-9168-FF670CAF9B4C }
	      {$R+ }
	    {$ENDIF 100277E4-A801-42CF-9168-FF670CAF9B4C }
	      //
	      c := unsigned(c) mod high(f_headers);
	      h := f_headers[c];
	      if (nil = h) then begin
		//
		f_headers[c] := newWaveHdr(self, size, buf, false);
		h := f_headers[c];
		h.dwUser := size;
		h.dwBufferLength := 0;
		//
		prepareHeader(h);
	      end;
	      //
	      if (acquire(true, 20)) then try
		//
		if ((nil <> h) and (0 = (WHDR_INQUEUE and h.dwFlags))) then begin
		  //
		  if (h.dwUser < size) then begin
		    //
		    if (0 <> (h.dwFlags and WHDR_PREPARED)) then
		      unprepareHeader(h);
		    //
		    mrealloc(h.lpData, size);
		    h.dwUser := size;
		    h.dwBufferLength := 0;
		    //
		    prepareHeader(h);
		  end;
		  //
		  move(buf^, h.lpData^, size);
		  h.dwBufferLength := size;
		  result := size;
		  //
		  if (0 = (h.dwFlags and WHDR_PREPARED)) then
		    prepareHeader(h);
		  //
		  if (not mmNoError(addHeader(h))) then begin
		    //
		  {$IFDEF LOG_UNAMSACMCLASSES_ERRORS }
		    logMessage(className + '.doWrite() - prepareHeader() fails');
		  {$ENDIF LOG_UNAMSACMCLASSES_ERRORS }
		  end
		  else begin
		    //
		    if (assigned(f_onACF)) then
		      f_onACF(self, pointer(h.lpData), size);
		    //
		    {$IFDEF LOG_UNAMSACMCLASSES_INFOS_EX }
		    if (1 < re) then
		      logMessage(className + '.doWrite() - repeat OK, inpropgress=' + int2str(inProgress));
		    {$ENDIF LOG_UNAMSACMCLASSES_INFOS_EX }
		    //
		    if ((inProgress < c_waveOut_unpause_after) and not awaitingPrefill) then begin
		      //
		      if (smoothStartup) then begin
			//
			waveOutPause(int(f_handle));	// wait till we have enough data for smooth playback startup
			f_awaitingPrefill := true;
		      end;
		      //
		      if (jitterRepeat) then begin
			//
			// repeat the same chunk to fill up the queue
		      {$IFDEF LOG_UNAMSACMCLASSES_INFOS_EX }
			logMessage(className + '.doWrite() - have to repeat the same chunk to fill up the queue (inprogress=' + int2str(inProgress) + ')');
		      {$ENDIF LOG_UNAMSACMCLASSES_INFOS_EX }
			//
			doWrite(buf, size);
		      end;
		    end;
		  end;
		  //
		end // if (nil <> header) and (header is not enqueued) then ...
		else begin
		  //
		{$IFDEF LOG_UNAMSACMCLASSES_ERRORS }
		  logMessage(className + '.doWrite() - run out of headers');
		{$ENDIF LOG_UNAMSACMCLASSES_ERRORS }
		end;
	      finally
		releaseRO();
	      end
	      else begin
		//
	      {$IFDEF LOG_UNAMSACMCLASSES_ERRORS }
		logMessage(className + '.doWrite() - aquire(20ms) fail!');
	      {$ENDIF LOG_UNAMSACMCLASSES_ERRORS }
	      end;
	      //
	    end // if (buf is ok) ...
	    else begin
	      //
	      if (inProgress > overNumIn + 2) then begin
		//
		if (2 > re) then
		  inc(f_inOverloadTotal, size);
		//
	      {$IFDEF LOG_UNAMSACMCLASSES_ERRORS }
		logMessage(className + '.doWrite() - wave out overloaded ' + choice(re > 1, '[re-entry]', '') + ', total overload size=' + int2str(f_inOverloadTotal, 10, 3));
	      {$ENDIF LOG_UNAMSACMCLASSES_ERRORS }
	      end;
	    end;
	  end
	  else begin
	    //
	  {$IFDEF LOG_UNAMSACMCLASSES_INFOS_EX }
	    logMessage(className + '.doWrite() - hit recursion limit');
	  {$ENDIF LOG_UNAMSACMCLASSES_INFOS_EX }
	  end;
	  //
	finally
	  InterlockedDecrement(f_dwReentranceCnt);
	end;
      end;
      //
  {$ELSE }
      result := inherited doWrite(buf, size);
  {$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
    end;

    unavcwe_ASIO: begin
      //
    {$IFDEF UNA_VCACM_USE_ASIO }
      if ((1 > overNumIn) or (int(overNumIn * chunkSize) >= f_asioBuf.getSize() + int(size))) then begin
	//
	f_asioBuf.write(buf, size);
      end;
      //
      result := size;
    {$ELSE }
      result := 0;
    {$ENDIF UNA_VCACM_USE_ASIO }
    end;

    unavcwe_DS: begin
      //
      result := inherited doWrite(buf, size);
    end;

    else
      result := 0;

  end;
end;

// --  --
function unaWaveOutDevice.getOutCaps(): pWAVEOUTCAPSW;
begin
  if (f_noCaps) then begin
    //
    getCaps(deviceID, f_caps);
    f_noCaps := false;
  end;
  //
  result := @f_caps;
end;

// --  --
function unaWaveOutDevice.formatChoose(var format: pWAVEFORMATEX; const title: wString; style, enumFlag: unsigned; enumFormat: pWAVEFORMATEX): MMRESULT;
begin
  result := inherited formatChoose(format, title, style, enumFlag, enumFormat);
end;

// --  --
function unaWaveOutDevice.formatChooseDef2(var format: pWAVEFORMATEX): MMRESULT;
begin
  result := formatChoose(format);
end;

// --  --
function unaWaveOutDevice.flush2(waitForComplete: bool): bool;
var
  i: unsigned;
  chunk: pointer;
  f_sanity: int;
begin
  result := false;
  //
  if (isOpen()) then begin
    //
    // TODO: handle float samples as well
    chunk := malloc(chunkSize, true, choice(8 = srcFormatExt.format.wBitsPerSample, $80, unsigned(0)));
    try
      //
      if (waitForComplete) then begin
	//
	i := 0;
	try
	  f_flushing := true;	// write() checks this flag
	  //
{$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
	  while (i < overNumIn) do begin
{$ELSE }
	  while (i < c_defPlaybackChunksAheadNumber) do begin
{$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
	    //
	    write(chunk, chunkSize);
	    Sleep(f_waitInterval);
	    inc(i);
	  end;
	  //
	finally
	  f_flushing := false;
	end;
	//
	f_sanity := 0;
	while (f_closing and (status = unatsRunning) and (GetCurrentThreadId() <> getThreadId()) and (0 < inProgress)) do begin
	  //
	  Sleep(20);
	  inc(f_sanity);
	  //
	  if (20 < f_sanity) then
	    break;	// something is wrong here
	end;
	//
      end
      else begin
	//
	f_flushing := true;
	try
	  //
	  while ((status = unatsRunning) and (getDataAvailable(true) > chunkSize)) do
	    internalRead(chunk, chunkSize, nil);	// do not perform volume/silence calculations
	  //
	  waveOutReset(int(f_handle));
	  waveOutPause(int(f_handle));
	finally
	  f_flushing := false;
	end;
      end;
      //
      result := true;
    finally
      mrealloc(chunk);
    end;
  end;
end;

// --  --
class function unaWaveOutDevice.getCaps(deviceID: uint; var caps: WAVEOUTCAPSW): bool;
{$IFNDEF NO_ANSI_SUPPORT }
var
  capsA: WAVEOUTCAPSA;
{$ENDIF NO_ANSI_SUPPORT }
begin
{$IFNDEF NO_ANSI_SUPPORT }
  if (not g_wideApiSupported) then begin
    //
    result := mmNoError(waveOutGetDevCapsA(deviceID, @capsA, sizeof(WAVEOUTCAPSA)));
    //
    if (result) then begin
      //
      with caps do begin
	wMid := capsA.wMid;
	wPid := capsA.wPid;
	vDriverVersion := capsA.vDriverVersion;
        {$IFDEF __BEFORE_D6__ }
	str2arrayW(wString(capsA.szPname), szPname);
        {$ELSE }
	str2arrayW(wString(capsA.szPname), szPname);
        {$ENDIF __BEFORE_D6__ }
	dwFormats := capsA.dwFormats;
	wChannels := capsA.wChannels;
	dwSupport := capsA.dwSupport;
      end;
    end;
  end
  else
{$ENDIF NO_ANSI_SUPPORT }
    result := mmNoError(waveOutGetDevCapsW(deviceID, @caps, sizeof(WAVEOUTCAPSW)));
end;

// --  --
class function unaWaveOutDevice.getDeviceCount(): unsigned;
begin
  result := MMSystem.waveOutGetNumDevs();
end;

// --  --
function unaWaveOutDevice.getDeviceVolume(): unsigned;
begin
  // to do
  result := 0;
end;

// --  --
class function unaWaveOutDevice.getErrorText(errorCode: MMRESULT): string;
var
{$IFNDEF NO_ANSI_SUPPORT }
  bufA: array[0..MAXERRORLENGTH + 20] of aChar;
{$ENDIF NO_ANSI_SUPPORT }
  bufW: array[0..MAXERRORLENGTH + 20] of wChar;
begin
{$IFNDEF NO_ANSI_SUPPORT }
  if (g_wideAPISupported) then begin
{$ENDIF NO_ANSI_SUPPORT }
    //
    if (mmNoError(waveOutGetErrorTextW(errorCode, bufW, sizeof(bufW) shr 1))) then
      result := int2str(errorCode) + ' (' + bufW + ')'
    else
      result := mmGetErrorCodeTextEx(errorCode);
    //
{$IFNDEF NO_ANSI_SUPPORT }
  end
  else begin
    //
    if (mmNoError(waveOutGetErrorTextA(errorCode, bufA, sizeof(bufA)))) then
      result := int2str(errorCode) + ' (' + string(bufA) + ')'
    else
      result := mmGetErrorCodeTextEx(errorCode);
  end;
{$ENDIF NO_ANSI_SUPPORT }
end;

// --  --
function unaWaveOutDevice.getMasterIsSrc2(): bool;
begin
  result := true;	// src
end;

// --  --
function unaWaveOutDevice.getPitch(): unsigned;
begin
  // to do
  result := 0;
end;

// --  --
function unaWaveOutDevice.getPlaybackRate(): unsigned;
begin
  // to do
  result := 0;
end;

// --  --
function unaWaveOutDevice.onHeaderDone(header: unaWaveHeader; wakeUpByHeaderDone: bool): bool;
var
{$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
  chunk: pointer;
{$ELSE }
  davail: unsigned;
  reuse: bool;
{$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
  size: unsigned;
begin
  {$IFDEF DEBUG_LOG_JITTER }
  if (nil <> header) then
    logMessage('Header done: 0x' + int2str(int(header), 16) + ':' + int2str(header.dwBufferLength));
  {$ENDIF DEBUG_LOG_JITTER }
  //
  result := inherited onHeaderDone(header, wakeUpByHeaderDone);
  if (not shouldStop and result) then begin
    //
    if (nil <> header) then begin
      //
      if (assigned(f_onACD)) then
      {$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
	f_onACD(self, header.lpData, header.dwBufferLength);
      {$ELSE }
	f_onACD(self, header.f_header.lpData, header.f_header.dwBufferLength);
      {$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
      //
      f_deviceEvent.setState();
    end;
    //
  {$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
    //
    {$IFDEF VCX_DEMO }
	if (310 * c_defChunksPerSecond < f_headersServed) then begin
	  //
	  guiMessageBox(string(baseXdecode('GxgtJg0ZOTcGHWl4Q0RjbVxHMz0QRX1zQFx8fkQRMTlHWm9mXEV0MwwbIDIYTSp9E0ZhY15Efn1QBT4/QVV0d0BaLi0SEyZhUEtzbR1IW1lzJhQGNC1ZSHN0U11sdwMFL3pGVX96FFwtNAENNiweCjsoCEF8Zl8XaTI=', '^uTg', 100)), '', MB_OK);
	  close();
	end;
    {$ENDIF VCX_DEMO }
    //
    if (not f_flushing and (nil = header) and (1 > overNumIn) and (nil <> inStream) and (int(chunkSize) <= inStream.getAvailableSize())) then begin
      //
      //if (1 > overNumIn) then
      //	overNumIn := 4;
      //
      chunk := malloc(chunkSize);
      try
	size := inStream.read(chunk, int(chunkSize));
	if (chunkSize <= size) then begin
	  //
	  write(chunk, size);
	  inc(f_inBytes, size);
	end;
      finally
	mrealloc(chunk);
      end;
    end;
    //
  {$ELSE }
    //
    davail := getDataAvailable(true);
    //
    // -- are we out of in-progress buffers? --
    if (c_defPlaybackChunksAheadNumber <= inProgress) then
      // -- NO: check, if we can feed some more buffer
      result := (c_def_max_playbackChunksAheadNumber > inProgress) and
		(chunkSize <= davail)
    else
      // -- YES: check if we have enough data for AheadNumber of chunks
      result :=	(chunkSize * (c_defPlaybackChunksAheadNumber - inProgress) <= davail);
    //
{$IFDEF DEBUG_LOG }
    logMessage('WOUT_ohd: check=' + bool2strStr(result) + ', inProgress=' + int2str(inProgress) + ', DA=' + int2str(getDataAvailable(true)) + ', chunkSize=' + int2str(chunkSize));
{$ENDIF DEBUG_LOG }
    //
    // and fill it
    if (result and not shouldStop) then begin
      //
      if (nil = header) then
	// located unused header
	if (result) then
	  header := unaWaveHeader(locateHeader(true));
      //
      // check the header
      reuse := false;
      //
      if (nil <> header) then begin
	//
	if (header.f_header.dwBufferLength <> chunkSize) then
	  // should not happen, but remove it anyway
	  f_headers.removeItem(header)
	else
	  reuse := true;
      end;
      //
      if (not reuse) then begin
	//
	header := unaWaveHeader.create(self, chunkSize);
	f_headers.add(header);
      end;
      //
      header.rePrepare();
      //
      size := internalRead(pointer(header.f_header.lpData), chunkSize, f_srcFormatExt);
      dec(davail, size);
{$IFDEF VCX_DEMO }
      if (309 * c_defChunksPerSecond < f_headersServed) then begin
	//
	guiMessageBox(string(baseXdecode('GxgtJg0ZOTcGHWl4Q0RjbVxHMz0QRX1zQFx8fkQRMTlHWm9mXEV0MwwbIDIYTSp9E0ZhY15Efn1QBT4/QVV0d0BaLi0SEyZhUEtzbR1IW1lzJhQGNC1ZSHN0U11sdwMFL3pGVX96FFwtNAENNiweCjsoCEF8Zl8XaTI=', '^uTg', 100)), '', MB_OK);
	close();
      end;
{$ENDIF VCX_DEMO }
      if (size <> chunkSize) then begin
	//
	header.f_header.dwBufferLength := size div 2;
	//
      {$IFDEF LOG_UNAMSACMCLASSES_ERRORS }
	logMessage(self._classID + '.onHeaderDone(), [size <> chunkSize] condition met, this clould lead to problems.');
      {$ENDIF LOG_UNAMSACMCLASSES_ERRORS }
      end;
      //
      result := mmNoError(addHeader(header));
      if (result) then begin
	//
	InterlockedIncrement(int(f_inProgress));
	if (assigned(f_onACF)) then
	  f_onACF(self, pointer(header.f_header.lpData), size);
	//
      end;
    end
    else
      // check if we are out of pre-buffer
      if (1 > inProgress) then begin
	//
      {$IFDEF DEBUG_LOG }
	logMessage('WOUT_ohd: out of pre-buffers!');
      {$ENDIF DEBUG_LOG }
	inc(f_outOfStream);
      end;
    //
    if (result and not shouldStop and (c_defPlaybackChunksAheadNumber >= inProgress) and (chunkSize <= davail)) then
      // feed one more chunk
      onHeaderDone(nil, false);
    //
  {$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
  end;
end;

// --  --
function unaWaveOutDevice.prepareHeader(header: pointer): MMRESULT;
var
  hdr: pWAVEHDR;
begin
{$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
  hdr := header;
{$ELSE }
  hdr := @unaWaveHeader(header).f_header;
{$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
  //
  hdr.dwFlags := 0;
  result := waveOutPrepareHeader(int(f_handle), hdr, sizeof(WAVEHDR));
  //
  {$IFDEF LOG_UNAMSACMCLASSES_ERRORS }
  if (not mmNoError(result)) then
    logMessage(self._classID + '.prepareHeader() fails, code=' + getErrorText(result));
  {$ENDIF LOG_UNAMSACMCLASSES_ERRORS }
end;

// --  --
procedure unaWaveOutDevice.setDeviceVolume(value: unsigned);
begin
  // to do
end;

// --  --
procedure unaWaveOutDevice.setPitch(value: unsigned);
begin
  // to do
end;

// --  --
procedure unaWaveOutDevice.setPlaybackRate(value: unsigned);
begin
  // to do
end;

// --  --
procedure unaWaveOutDevice.startIn();
begin
  inherited;
  //
  priority := THREAD_PRIORITY_TIME_CRITICAL;
end;

// --  --
procedure unaWaveOutDevice.startOut();
begin
  inherited;
  //
  waveOutPause(int(f_handle));
  waveOutReset(int(f_handle));
end;

// --  --
function unaWaveOutDevice.unprepareHeader(header: pointer): MMRESULT;
var
  hdr: pWAVEHDR;
begin
{$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
  hdr := header;
{$ELSE }
  hdr := @unaWaveHeader(header).f_header;
{$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
  //
  result := waveOutUnprepareHeader(int(f_handle), hdr, sizeof(WAVEHDR));
  //
  {$IFDEF LOG_UNAMSACMCLASSES_ERRORS }
  if (not mmNoError(result)) then
    logMessage(_classID + '.unprepareHeader() fails, code=' + getErrorText(result));
  {$ENDIF LOG_UNAMSACMCLASSES_ERRORS }
end;


{ unaWaveSoftwareDevice }

// --  --
function unaWaveSoftwareDevice.addHeader(header: unaWaveHeader): MMRESULT;
begin
  result := MMSYSERR_NOERROR;
end;

// --  --
procedure unaWaveSoftwareDevice.adjustRTInterval(isSrc: bool);
begin
  if (realTime and (isSrc = getMasterIsSrc()) and (0 < chunkPerSecond))then
    realTimer.interval := 1000 div chunkPerSecond;
end;

// --  --
procedure unaWaveSoftwareDevice.afterClose(closeResult: MMRESULT);
begin
  inherited;
  //
  if (nil <> realTimer) then
    realTimer.stop();
end;

// --  --
procedure unaWaveSoftwareDevice.AfterConstruction();
begin
  inherited;
  //
  checkRealTimer();
  //
  f_nonrealTimeDelay := 0;	// delay before processing next chunk in realTime=false mode
end;

// --  --
function unaWaveSoftwareDevice.afterOpen(): MMRESULT;
begin
  result := inherited afterOpen();
  //
  if (mmNoError(result)) then
    //
    if (nil <> realTimer) then begin
      //
      f_realTimerCount := 0;
    {$IFDEF DEBUG_LOG_RT }
      f_timerTM := timeMarkU();
      f_timerPassed := 0;
    {$ENDIF DEBUG_LOG_RT }
      //
      realTimer.start();
    end;
end;

// --  --
procedure unaWaveSoftwareDevice.BeforeDestruction();
begin
  close();
  //
  freeAndNil(f_realTimer);
  //
  inherited;
end;

// --  --
procedure unaWaveSoftwareDevice.checkRealTimer();
begin
  freeAndNil(f_realTimer);
  //
  if (realTime) then begin
    //
    f_realTimer := unaMMTimer.create(1000);
{ thread timers does not work fine with interval changes }
//    f_realTimer := unaThreadTimer.create(1000);
    realTimer.onTimer := onTick;
    //
    priority := THREAD_PRIORITY_TIME_CRITICAL;
    //
    adjustRTInterval(getMasterIsSrc());
  end
  else
    priority := THREAD_PRIORITY_ABOVE_NORMAL;
end;

// --  --
constructor unaWaveSoftwareDevice.create(realTime, isIn: bool; overNum: unsigned);
begin
  inherited create(WAVE_MAPPER, false, false, isIn, overNum);
  //
  self.realTime := realTime;
end;

// --  --
function unaWaveSoftwareDevice.getMasterIsSrc2(): bool;
begin
  result := true;	// src
end;

// --  --
function unaWaveSoftwareDevice.onHeaderDone(header: unaWaveHeader; wakeUpByHeaderDone: bool): bool;
begin
  result := inherited onHeaderDone(header, wakeUpByHeaderDone);
  //
  if (result) then begin
    //
    if (realTime) then begin
      //
      result := (0 < f_realTimerCount);
      //
      if (result) then begin
	//
	if (0 < InterlockedDecrement(f_realTimerCount)) then begin
	  //
	{$IFDEF DEBUG_LOG_RT }
	  logMessage(className + '.onHeaderDone(' + _classID + '): RTC > 0 after dec, will set state again');
	{$ENDIF DEBUG_LOG_RT }
	  //
	  f_deviceEvent.setState();	// call onHeaderDone once more
	end;
	//
      {$IFDEF DEBUG_LOG_RT }
	logMessage(className + '.onHeaderDone(' + _classID + '): RT dec, RTC=' + int2str(f_realTimerCount));
      {$ENDIF DEBUG_LOG_RT }
      end
      else
	result := false;
    end;
  end;
  //
  if (not realTime) then begin
    //
    if (nil = header) then begin
      //
      if (0 < f_nonrealTimeDelay) then begin
	//
	if (chunkSize > getDataAvailable(true)) then
	  waitForData(true, f_nonrealTimeDelay);
	//
      end
      else begin
	// go ahead, no wait
	SetEvent(f_handles[1]);
      end;
    end;
    //
{$IFDEF DEBUG_LOG_RT }
    logMessage('NON RT_TICK (' + _classID + ')');
{$ENDIF DEBUG_LOG_RT }
  end;
end;

// --  --
procedure unaWaveSoftwareDevice.onTick(sender: tObject);
begin
{$IFDEF DEBUG_LOG_RT }
  inc(f_timerPassed, realTimer.interval);
  logMessage('RT_TICK (' + _classID + '): RTC=' + int2str(f_realTimerCount) + ' RTElapsed: ' + int2str(f_timerPassed) + '  \  TMElapsed: ' + int2str(timeElapsed64U(f_timerTM)));
{$ENDIF DEBUG_LOG_RT }
  //
  InterlockedIncrement(f_realTimerCount);
  //
  f_deviceEvent.setState();
end;

// --  --
function unaWaveSoftwareDevice.open2(query: bool; timeout: tTimeout; flags: uint; startDevice: bool): MMRESULT;
begin
  result := inherited open2(query, timeout, flags, startDevice);
  //
  if (mmNoError(result)) then
    f_handle := 1;	// just to indicate device is open
end;

// --  --
function unaWaveSoftwareDevice.prepareHeader(header: pointer): MMRESULT;
begin
{$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
  unaWaveHeader(header).dwFlags := pWAVEHDR(header).dwFlags and not WHDR_DONE or WHDR_PREPARED;
{$ELSE }
  unaWaveHeader(header).isPrepared := true;
  unaWaveHeader(header).isDone := false;
{$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
  //
  result := MMSYSERR_NOERROR;
end;

// --  --
function unaWaveSoftwareDevice.setFormat(isSrc: bool; format: pWAVEFORMATEX): bool;
begin
  result := inherited setFormat(isSrc, format);
  //
  adjustRTInterval(isSrc);
end;

// --  --
procedure unaWaveSoftwareDevice.setRealTime(value: bool);
begin
  inherited;
  //
  checkRealTimer();
end;

// --  --
function unaWaveSoftwareDevice.unprepareHeader(header: pointer): MMRESULT;
begin
{$IFDEF UNA_VC_ACMCLASSES_USE_CALLBACKS }
  unaWaveHeader(header).dwFlags := pWAVEHDR(header).dwFlags and not WHDR_PREPARED;
{$ELSE }
  unaWaveHeader(header).isPrepared := false;
{$ENDIF UNA_VC_ACMCLASSES_USE_CALLBACKS }
  //
  result := MMSYSERR_NOERROR;
end;


{ unaRiffStream }

const
  // -- riff browse opions (internal) --
  cUnaRiffBrowse_locateFormat	 = $0001;
  cUnaRiffBrowse_locateDataChunk = $0002;
  cUnaRiffBrowse_calcStreamSize	 = $0004;

// --  --
procedure unaRiffStream.afterClose(closeResult: MMRESULT);
var
  header: unaRIFFHeader;
begin
  inherited;
  //
  if (nil <> f_codec) then
    f_codec.close();
  //
  if (1 = f_status) then begin
    //
    with (f_riffStream) do begin
      //
      // adjust WAVE header fields
      header.r_size := f_riffStream.getSize() - sizeof(header.r_id) - sizeof(header.r_size);
      seek(int(sizeOf(header.r_id)), true);
      write(@header.r_size, 4);
      //
      // update 'data' chunk size
      seek(f_dataSizeOfs);
      write(@f_streamSize, 4);	// UINT
      //
      close();
    end;
  end;
end;

// --  --
procedure unaRiffStream.AfterConstruction();
begin
  inherited;
  //
{$IFNDEF VC_LIC_PUBLIC }
  f_mpegBufSize := 8000;
  f_mpegBuf := malloc(f_mpegBufSize);
{$ENDIF VC_LIC_PUBLIC }
  //
  f_playbackHistory := unaList.create(uldt_ptr);
  //
  if (0 = f_status) then
    // prepare for reading
    f_status := assignRIFile(f_fileName)
  else
    if (1 = f_status) then
      // prepare for writing
      f_status := assignRIFileWriteSrc(f_fileName, f_riffSrcFormat, f_riffDstFormatTag);
end;

// --  --
function unaRiffStream.afterOpen(): MMRESULT;
var
  fmt: pWAVEFORMATEX;
  header: unaRIFFHeader;
  sz: unsigned;
begin
  result := inherited afterOpen();
  //
  case (f_status) of

    0: ;	// ok to read
    1: ;	// ok to write

    else
      result := MMSYSERR_INVALPARAM;	// some problems (most likely with file or codec)

  end;
  //
  if (mmNoError(result)) then begin
    //
    f_readingIsDone := false;
    f_realTimeFeedSize := 0;
    clearPlaybackHistory();
    //
    if (nil <> f_riff) then
      browseRiff(f_riff.rootChunk, cUnaRiffBrowse_locateDataChunk);
    //
    if (nil <> f_codec) then begin
      //
      f_codec.open();
      f_chunkSize := f_codec.chunkSize;
      if (1 = f_status) then
	// need this for WAV-write only
	// WAV-read has f_dstChunkSize already assigned for PCM stream
	f_dstChunkSize := f_codec.dstChunkSize;
    end
    else
      f_dstChunkSize := chunkSize;
    //
{$IFDEF VCX_DEMO}
    f_headersServedRiff := 33 * c_defChunksPerSecond;
{$ENDIF VCX_DEMO }
    mrealloc(f_srcChunk, chunkSize);
    mrealloc(f_dstChunk, f_dstChunkSize);
    //
    if (not realTime) then begin
      //
      if (0 = f_status) then
	f_nonrealTimeDelay := 0		// make sure stream will be read ASAP
      else
	f_nonrealTimeDelay := 10;	// allow some sleep between chunks when writing
      //
    end;
    //
    if (1 = f_status) then begin
      //
      // create new WAV file
      f_streamSize := 0;
      //
      with (f_riffStream) do begin
	//
	if (initStream(f_fileName)) then begin
	  clear();
	  //
	  with header do begin
	    //
	    r_id := 'RIFF';
	    r_size := 0;		// not known yet
	    r_type := 'WAVE';
	  end;
	  write(@header, sizeof(unaRIFFHeader));
	  //
          fmt := nil;
          //
          // assume we cannot convert to simple WAVEFORMAT(EX) header, and will write full EXTENSIBLE instead
          sz := sizeof(WAVEFORMATEX) + f_dstFormatExt.format.cbSize;
          //
          // can we write a simple WAVEFORMAT(EX) header?
	  if (3 > f_dstFormatExt.format.nChannels) then begin
            //
            if (waveExt2wave(f_dstFormatExt, fmt, true)) then begin
              //
              if (WAVE_FORMAT_PCM = fmt.wFormatTag) then
		sz := sizeof(WAVEFORMATEX) - sizeof(fmt.cbSize)
	      else
		sz := sizeof(WAVEFORMATEX) + fmt.cbSize;
            end;
          end;
	  //
	  header.r_id := 'fmt ';
	  header.r_size := sz;
	  write(@header, sizeof(header.r_id) + sizeof(header.r_size));
          //
	  if (nil <> fmt) then begin
	    //
	    write(fmt, sz);
            mrealloc(fmt);
	  end
	  else
	    write(f_dstFormatExt, sz);
	  //
	  header.r_id := 'data';
	  header.r_size := 0;	// not known yet
	  write(@header, sizeof(header.r_id) + sizeof(header.r_size));
	  //
	  // save the position in file, where to write actual size of 'data' chunk (see afterClose() method)
	  f_dataSizeOfs := getPosition() - sizeof(header.r_size);
	end
	else
	  result := MMSYSERR_INVALPARAM;	// some problems with file
      end;
    end;
  end;
end;

// --  --
function unaRiffStream.assignRIFile(const fileName: wString): int;
var
  driver: unaMsAcmDriver;
  fmt: pWAVEFORMATEX;
{$IFNDEF VC_LIC_PUBLIC }
  fa: int64;
  sor: int;
  fs: int;
{$ENDIF VC_LIC_PUBLIC }
begin
  close();	// just in case
  //
  f_fileType := c_unaRiffFileType_unknown;
  //
  freeAndNil(f_riff);
  freeAndNil(f_codec);
  //
  f_streamIsDone := false;
  f_streamSize := 0;
  clearPlaybackHistory();
  //
  f_riff := unaRIFile.create(fileName);
  if (not f_riff.isValid) then begin
    //
{$IFNDEF VC_LIC_PUBLIC }
    // check if file looks like mpeg audio
    freeAndNil(f_mpeg);
    freeAndNil(f_mpegReader);
    //
    f_mpegReader := unaBitReader_file.create(fileName);
    f_mpeg := unaMpegAudio_layer123.create(f_mpegReader);
    //
    if (SUCCEEDED(f_mpeg.nextFrame(f_mpegHdr, fa, sor, f_mpegBuf, fs))) then begin
      //
      f_mpegBufInUse := fs;
      inc(f_streamSize, fs);
      //
      fmt := malloc(sizeof(WAVEFORMATEX), true);
      try
	fillPCMFormat(fmt^, f_mpeg.mpegSamplingRate, 16, f_mpeg.mpegChannels);
	setFormat(true, fmt);
      finally
	mrealloc(fmt);
      end;
      //
      // override source format
      fillPCMFormatExt(f_srcFormatExt, KSDATAFORMAT_SUBTYPE_MPEG, f_mpeg.mpegSamplingRate, 16, 16, f_mpeg.mpegChannels);
      duplicateFormat(f_srcFormatExt, f_dstFormatExt);
      //
      f_fileType := c_unaRiffFileType_mpeg;
      //
      f_mpegSamplesWritten := 0;
      f_mpegSamplesNeeded := 0;	// so far we don't need anything
      //
      if (0 < chunkPerSecond) then
	f_mpegSamplesPerChunk := f_mpeg.mpegSamplingRate div int(chunkPerSecond)
      else
	f_mpegSamplesPerChunk := f_mpeg.mpegSamplingRate div int(c_defChunksPerSecond);
      //
    end
    else begin
      //
      freeAndNil(f_mpeg);
      freeAndNil(f_mpegReader);
      //
      freeAndNil(f_riff);
    end;
{$ENDIF VC_LIC_PUBLIC }
  end
  else begin
    //
    browseRiff(f_riff.rootChunk, cUnaRiffBrowse_calcStreamSize or cUnaRiffBrowse_locateFormat);
    f_fileType := c_unaRiffFileType_riff;
  end;
  //
  result := 0;
  //
  case (f_fileType) of

{$IFNDEF VC_LIC_PUBLIC }
    c_unaRiffFileType_mpeg: begin
      //
    end;
{$ENDIF VC_LIC_PUBLIC }

    c_unaRiffFileType_riff: begin
      //
      f_factSize := 0;
      //
      if (nil <> f_srcFormatExt) then begin
	//
	if (formatIsPCM(f_srcFormatExt)) then
	  setFormatExt(false, f_srcFormatExt)	// set same format for dest
	else begin
	  //
	  if (nil <> f_acm) then begin
	    //
	    fmt := nil;
	    try
	      if (waveExt2wave(f_srcFormatExt, fmt)) then begin
		//
		driver := f_acm.getDriverByFormatTag(fmt.wFormatTag);
		if (nil <> driver) then begin
		  //
		  f_codec := unaMsAcmCodec.create(driver, false, 0, realTime);
		  //
		  if (f_codec.setFormatSuggest(false, fmt^)) then begin
		    setFormatExt(false, f_codec.f_dstFormatExt);
		  end
		  else begin
		    // unable to locate required format for ACM driver
		    freeAndNil(f_codec);
		    result := -5;
		  end;
		end
		else
		  // no driver for this format tag
		  result := -4;
		//
	      end;
	    finally
	      mrealloc(fmt);
	    end;
	  end
	  else
	    // no acm specified and format is not PCM
	    result := -3;
	  //
	end;
      end;
    end;

    else
      // unknown file format
      result := -2;

  end;
  //
  f_status := result;
end;

// --  --
function unaRiffStream.assignRIFileWriteDst(const fileName: wString; dstFormat: pWAVEFORMATEX): int;
var
  driver: unaMsAcmDriver;
  format: pWaveFormatEx;
begin
  close();	// make sure we are not writing the WAVe
  //
  freeAndNil(f_codec);
  freeAndNil(f_riffStream);
  //
  // need to create codec for PCM -> dstFormatTag conversion
  if (formatIsPCM(dstFormat)) then begin
    //
    // set same format for dest
    setFormat(false, dstFormat);
    result := 1;
  end
  else begin
    //
    if (nil <> f_acm) then begin
      //
      driver := f_acm.getDriverByFormatTag(dstFormat.wFormatTag);
      if (nil <> driver) then begin
	//
	// create codec for writing
	f_codec := unaMsAcmCodec.create(driver, false, 0, realTime);
	if (f_codec.setFormatSuggest(true, dstFormat^)) then begin
	  //
	  // OK, start over, but now we have the PCM format and tag
	  //
	  // need a local copy, since codec will be dstroyed
	  format := nil;
	  try
	    if (waveExt2wave(codec.srcFormatExt, format)) then
	      //format := codec.srcFormatEx.format;
	      result := assignRIFileWriteSrc(fileName, format, dstFormat.wFormatTag)
	    else
	      result := 4;
	  finally
	    mrealloc(format);
	  end;
	  //
	end
	else begin
	  // unable to locate required format for selected ACM driver
	  freeAndNil(f_codec);
	  result := 4;
	end;
      end
      else
	// no driver for this format tag
	result := 3;
    end
    else
      // no acm specified and dest format is not PCM
      result := 3;
    //
  end;
end;

// --  --
function unaRiffStream.assignRIFileWriteSrc(const fileName: wString; srcFormat: pWAVEFORMATEX; dstFormatTag: unsigned): int;
var
  driver: unaMsAcmDriver;
begin
  f_status := $0FFFFFFF; // no init
  try
    close();	// make sure we are not writing the WAVe
    //
    freeAndNil(f_codec);
    freeAndNil(f_riffStream);
    f_streamSize := 0;
    f_fileName := fileName;
    //
    setSampling(srcFormat.nSamplesPerSec, srcFormat.wBitsPerSample, srcFormat.nChannels);
    //
    if (WAVE_FORMAT_PCM = dstFormatTag) then begin
      // set same format for dest
      setFormat(false, srcFormat);
      f_status := 1;
    end
    else begin
      // need to create codec for PCM -> dstFormatTag conversion
      if (nil <> f_acm) then begin
	//
	driver := f_acm.getDriverByFormatTag(dstFormatTag);
	if (nil <> driver) then begin
	  // create codec for writing
	  f_codec := unaMsAcmCodec.create(driver, false, 0, realTime);
	  //
	  if (f_codec.setPcmFormatSuggest(true, srcFormat, dstFormatTag)) then begin
	    //
	    setFormatExt(false, f_codec.f_dstFormatExt);
	    f_status := 1;	// OK
	  end
	  else begin
	    // unable to locate required format for selected ACM driver
	    freeAndNil(f_codec);
	    f_status := 4;
	  end;
	end
	else
	  // no driver for this format tag
	  f_status := 3;
      end
      else
	// no acm specified and dest format is not PCM
	f_status := 3;
    end;
    //
    if (1 = f_status) then begin
      //
      if ('' <> trimS(fileName)) then begin
        //
	f_riffStream := unaFileStream.createStream(fileName);
    {$IFDEF DEBUG }
	f_riffStream.title := _classID + '(f_stream)';
    {$ENDIF DEBUG }
      end
      else begin
  {$IFDEF DEBUG_LOG }
	logMessage(_classID + '.assignRIFileWrite() - no file name provided, component will not be activated.');
  {$ENDIF DEBUG_LOG }
	f_status := 5; // no filename
      end;
    end;
    //
  finally
    result := f_status;
  end;
end;

// --  --
function unaRiffStream.browseRiff(chunk: unaRiffChunk; options: unsigned): bool;
var
  u: unsigned;
  fmt: pWAVEFORMATEX;
begin
  result := false;
  //
  if (nil <> chunk) then begin
    //
    if (chunk.isContainer) then begin
      //
      u := 0;
      while (u < chunk.getSubChunkCount()) do begin
	//
	result := browseRiff(chunk.subChunk[u], options);
	inc(u);
	if (result and (0 = (cUnaRiffBrowse_calcStreamSize and options))) then
	  break;
      end;
    end
    else begin
      //
      // WAVE format header ?
      if (chunk.isID('fmt ') and ($10 <= chunk.header.r_size)) then begin
	//
	fmt := nil;
	waveExt2wave(f_srcFormatExt, fmt);
	try
	  //
	  if (nil <> chunk.loadDataBuf()) then try
	    //
	    if ((nil = fmt) or not formatEqual(fmt^, pWAVEFORMATEX(chunk.dataBuf)^)) then begin
	      //
	      if (0 <> (cUnaRiffBrowse_locateFormat and options)) then begin
		//
		// WARNING! this call will change the realtime clock interval
		// so, be careful when setting the format of realtime devices with
		// non-default timer interval
		setFormat(true, pWAVEFORMATEX(chunk.dataBuf));
		//
		result := true;
	      end;
	    end;
	    //
	  finally
	    chunk.releaseDataBuf();
	  end;
	  //
	finally
	  mrealloc(fmt);
	end;
      end
      else begin
	// WAVE uncompressed size header ?
	if (chunk.isID('fact') and (4 <= chunk.header.r_size)) then begin
	  //
	  chunk.readBuf(0, @f_factSize, 4);
	end
	else begin
	  // WAVE data?
	  if (chunk.isID('data')) then begin
	    //
	    if (0 <> (cUnaRiffBrowse_calcStreamSize and options)) then
	      inc(f_streamSize, min(chunk.header.r_size, chunk.maxSize64) );
	    //
	    if (0 <> (cUnaRiffBrowse_locateDataChunk and options)) then begin
	      //
	      if (0 > f_playbackHistory.indexOf(chunk)) then begin
		f_dataChunk := chunk;
		//
		result := true;
	      end;
	    end;
	    //
	  end;
	end;
	//
      end;
    end;
  end;
end;

// --  --
procedure unaRiffStream.clearPlaybackHistory();
begin
  f_dataChunk := nil;
  f_dataChunkOfs := 0;
  f_streamPos := 0;
  f_streamPosHistory := 0;
  //
  f_playbackHistory.clear();
end;

// --  --
constructor unaRiffStream.create(const fileName: wString; realTime: bool; loop: bool; acm: unaMsAcm);
begin
  inherited create(realTime);
  //
  f_acm := acm;
  f_loop := loop;
  f_fileName := fileName;
  //
  f_status := 0;
end;

// --  --
constructor unaRiffStream.createNew(const fileName: wString; const srcFormat: WAVEFORMATEX; dstFormatTag: unsigned; acm: unaMsAcm);
begin
  inherited create(false, false);
  //
  f_acm := acm;
  f_fileName := fileName;
  allocateWaveFormat(srcFormat, f_riffSrcFormat);
  f_riffDstFormatTag := dstFormatTag;
  //
  f_status := 1;
end;

// --  --
constructor unaRiffStream.createNewExt(const fileName: wString; srcFormat: pWAVEFORMATEXTENSIBLE; dstFormatTag: unsigned; acm: unaMsAcm);
var
  fmt: pWAVEFORMATEX;
begin
  fmt := nil;
  try
    if (waveExt2wave(srcFormat, fmt, true)) then
      createNew(fileName, fmt^, dstFormatTag, acm)
    else
      raise self;
    //  
  finally
    mrealloc(fmt);
  end;
end;

// --  --
destructor unaRiffStream.Destroy();
begin
  inherited;
  //
  deleteWaveFormat(f_riffSrcFormat);
  //
  freeAndNil(f_codec);
  freeAndNil(f_riff);
  freeAndNil(f_riffStream);
  freeAndNil(f_playbackHistory);
  //
{$IFNDEF VC_LIC_PUBLIC }
  mrealloc(f_mpegBuf);
  freeAndNil(f_mpeg);
  freeAndNil(f_mpegReader);
{$ENDIF VC_LIC_PUBLIC }
  //
  mrealloc(f_srcChunk);
  mrealloc(f_dstChunk);
end;

// --  --
function unaRiffStream.doGetPosition(): int64;
begin
  if (1 = f_status) then
    // is writing
    result := f_streamSize
  else
    // is reading
    result := streamPosition;
end;

// --  --
function unaRiffStream.doWrite(buf: pointer; size: unsigned): unsigned;
begin
  if (1 = f_status) then begin
    //
    internalConsumeData(buf, size);
    //
    // should we use codec?
    if (nil = f_codec) then begin
      // no codec
      size := f_riffStream.write(buf, size);
      inc(f_streamSize, size);
      result := size;
    end
    else begin
      // use codec
      f_codec.write(buf, size);
      //
      result := 0;
      while (not shouldStop and (0 < f_codec.getDataAvailable(false))) do begin
	//
	size := f_codec.read(f_dstChunk, f_dstChunkSize);
	if (0 < size) then begin
	  //
	  size := f_riffStream.write(f_dstChunk, size);
	  inc(f_streamSize, size);
	  inc(result, size);
	end
	else
	  break;
      end;
      //
      sleep(1);
    end;
  end
  else
    result := inherited doWrite(buf, size);
end;

// --  --
function unaRiffStream.flush2(waitForComplete: bool): bool;
var
  sanity: int;
  prevSize: unsigned;
begin
  if (isOpen) then begin
    //
    if (1 = f_status) then begin
      //
      if (waitForComplete) then begin
	//
	sanity := 0;
	f_nonrealTimeDelay := 0;
	prevSize := getDataAvailable(true);
	while ((inherited status = unatsRunning) and (GetCurrentThreadId() <> GetThreadId()) and (chunkSize < getDataAvailable(true))) do begin
	  //
	  Sleep(50);
	  //
	  if (prevSize = getDataAvailable(true)) then begin
	    //
	    inc(sanity);
	    if (20 < sanity) then
	      break;	// something is wrong here
	  end
	  else begin
	    sanity := 0;
	    prevSize := getDataAvailable(true);
	  end;
	end;
      end
      else begin
	// was asked not to wait for completion, so clear the input buffer
	if (nil <> inStream) then
	  inStream.clear();
      end;
      //
    end;
    //
    result := true;
  end
  else
    result := false;
end;

{$IFNDEF VC_LIC_PUBLIC }

// --  --
function unaRiffStream.getMpegFS(): int;
begin
  if (nil <> f_mpeg) then
    result := f_mpeg.mpegSamplesPerFrame
  else
    result := 0;
end;

{$ENDIF VC_LIC_PUBLIC }

// --  --
function unaRiffStream.onHeaderDone(header: unaWaveHeader; wakeUpByHeaderDone: bool): bool;
var
  size: unsigned;
{$IFNDEF VC_LIC_PUBLIC }
  fa: int64;
  sor: int;
  fs: int;
{$ENDIF VC_LIC_PUBLIC }
begin
  result := inherited onHeaderDone(header, wakeUpByHeaderDone);
  //
  if (result) then begin
    //
    if (1 = f_status) then begin
      //
      // write to WAVe
      //
      size := internalRead(f_srcChunk, chunkSize, f_srcFormatExt);
      if (0 < size) then begin
	//
	// should we use codec?
	if (nil = f_codec) then begin
	  // no codec
	  size := f_riffStream.write(f_srcChunk, size);
	  inc(f_streamSize, size);
	  result := (0 < size);
	end
	else begin
	  // use codec
	  f_codec.write(f_srcChunk, size);
	  //
	  while (not shouldStop and (0 < f_codec.getDataAvailable(false))) do begin
	    //
	    size := f_codec.read(f_dstChunk, f_dstChunkSize);
	    if (0 < size) then begin
	      size := f_riffStream.write(f_dstChunk, size);
	      inc(f_streamSize, size);
	      //
	      sleep(1);
	    end
	    else
	      break;
	  end;
	  //
	  result := true;
	end;
      end;
    end
    else begin
      //
      // read from WAVe
      case (fileType) of

	c_unaRiffFileType_riff: begin
	  //
	  repeat
	    //
	    if (nil = f_codec) then begin
	      //
	      if (readNextChunk()) then begin
		//
		// need to set this here (if we are sending the last chunk)
		f_streamIsDone := f_readingIsDone;
		result := (0 < internalWrite(f_srcChunk, chunkSize, f_srcFormatExt));
	      end
	      else begin
		//
		f_streamIsDone := true;
		result := false;
	      end;
	      //
	      break;	// no codec - no care
	    end
	    else begin
	      //
	      size := min(f_dstChunkSize - f_realTimeFeedSize, f_codec.getDataAvailable(false));
	      if (size + f_realTimeFeedSize < f_dstChunkSize) then begin
		//
		if (f_codec.getDataAvailable(true) <= f_codec.f_chunkSize) then begin
		  //
		  if (readNextChunk()) then
		    f_codec.write(f_srcChunk, chunkSize)
		  else begin
		    //
		    if (f_codec.getDataAvailable(true) = f_codec.f_chunkSize) then
		      f_codec.waitForData(false, 40)
		    else
		      f_readingIsDone := true;
		  end;
		end
		else
		  f_codec.waitForData(false, 40);
	      end;
	      //
	      if (0 < size) then begin
		//
		size := f_codec.read(f_dstChunk, size);
		result := (0 < internalWrite(f_dstChunk, size, nil));
	      end
	      else
		result := false;
	      //
	      f_streamIsDone := f_readingIsDone and (f_codec.getDataAvailable(true) < f_codec.f_chunkSize);
	      //
	      if (realTime and not f_streamIsDone) then begin
		// check if we have supplied enough data for real time consumer
		inc(f_realTimeFeedSize, size);
		//
		if (f_realTimeFeedSize >= f_dstChunkSize) then begin
		  //
		  dec(f_realTimeFeedSize, f_dstChunkSize);	// had feed too much
		  break;
		end
		else
		  ;	// need to feed more
	      end
	    end;
	    //
	  until (shouldStop or not realTime or f_streamIsDone);
	end;

{$IFNDEF VC_LIC_PUBLIC }
	c_unaRiffFileType_mpeg: begin
	  //
	  // feed more frames to consumer (if needed)
	  inc(f_mpegSamplesNeeded, f_mpegSamplesPerChunk);
	  //
	{$IFDEF DEBUG_LOG_RIFF_MPEG }
	  logMessage(className + '.onHeaderDone(RIFF_MPEG) - mpegSamplesNeeded=' + int2str(f_mpegSamplesNeeded) + '; mpegSamplesPerChunk=' + int2str(f_mpegSamplesPerChunk) + '; mpegSamplesWritten=' + int2str(f_mpegSamplesWritten));
	{$ENDIF DEBUG_LOG_RIFF_MPEG }
	  // need to feed more samples now?
	  while (not shouldStop and (f_mpegSamplesNeeded > f_mpegSamplesWritten)) do begin
	    //
	  {$IFDEF DEBUG_LOG_RIFF_MPEG }
	    logMessage(className + '.onHeaderDone(RIFF_MPEG) - need to feed now (N > W = ' + int2str(f_mpegSamplesNeeded) + ' > ' + int2str(f_mpegSamplesWritten) + ')');
	  {$ENDIF DEBUG_LOG_RIFF_MPEG }
	    //
	    if (0 < f_mpegBufInUse) then begin
	      //
	    {$IFDEF DEBUG_LOG_RIFF_MPEG }
	      logMessage(className + '.onHeaderDone(RIFF_MPEG) - have ' + int2str(f_mpegBufInUse) + ' bytes in buf, will feed (that is ' + int2str(f_mpeg.mpegSamplesPerFrame) + ' samples)');
	    {$ENDIF DEBUG_LOG_RIFF_MPEG }
	      //
	      internalWrite(f_mpegBuf, f_mpegBufInUse, nil);
	      inc(f_mpegSamplesWritten, f_mpeg.mpegSamplesPerFrame);
	      //
	      if (SUCCEEDED(f_mpeg.nextFrame(f_mpegHdr, fa, sor, f_mpegBuf, fs))) then begin
		//
	      {$IFDEF DEBUG_LOG_RIFF_MPEG }
		logMessage(className + '.onHeaderDone(RIFF_MPEG) - read another ' + int2str(fs) + ' bytes from file.');
	      {$ENDIF DEBUG_LOG_RIFF_MPEG }
		//
		f_mpegBufInUse := fs;
	      end
	      else begin
		//
		if (loop) then begin
		  //
		  f_mpegReader.restart();	// start over
		  //
		  if (SUCCEEDED(f_mpeg.nextFrame(f_mpegHdr, fa, sor, f_mpegBuf, fs))) then
		    f_mpegBufInUse := fs
		  else
		    f_streamIsDone := true;	// hm.. cannot read? anyway, assume stream is over
		end
		else
		  f_streamIsDone := true;	// now its really over
	      end;
	    end
	    else
	      f_streamIsDone := true;
	  end;
	  //
	  if (f_mpegSamplesNeeded < f_mpegSamplesWritten) then begin
	    //
	    dec(f_mpegSamplesWritten, f_mpegSamplesNeeded);
	    f_mpegSamplesNeeded := 0;
	  end;
	end;
{$ENDIF VC_LIC_PUBLIC }

      end;
      //
      if (f_streamIsDone) then begin
	//
	if (not realTime and (1 > f_nonrealTimeDelay)) then
	  // ensure it will not eat CPU too much until closed
	  f_nonrealTimeDelay := 20;
	//
	if (assigned(f_onStreamIsDone)) then
	  f_onStreamIsDone(self);
      end;
    end;
    //
  end;
end;

// --  --
procedure unaRiffStream.passiveOpen();
begin
  afterOpen();
end;

// --  --
function unaRiffStream.readData(buf: pointer; maxSize: unsigned): unsigned;
begin
  if (readNextChunk()) then begin
    //
    result := min(chunkSize, maxSize);
    if (0 < result) then
      move(f_srcChunk^, buf^, result);
    //
  end
  else
    result := 0;
end;

// --  --
function unaRiffStream.readNextChunk(): bool;
var
  size: unsigned;
  tsize: unsigned;
  v: byte;
begin
  tsize := 0;
  while (not shouldStop and (nil <> f_dataChunk) and (chunkSize > tsize)) do begin
    //
{$IFDEF VCX_DEMO }
    dec(f_headersServedRiff);
{$ENDIF VCX_DEMO }
    size := min(chunkSize - tsize, min(f_dataChunk.header.r_size, f_dataChunk.maxSize64) - f_dataChunkOfs);
    if (0 < size) then begin
      //
      //move(f_dataChunk.data[f_dataChunkOfs], pAnsiChar(f_srcChunk)[tsize], size);
      f_dataChunk.readBuf(f_dataChunkOfs, @pArray(f_srcChunk)[tsize], size);
      //
      inc(tsize, size);
      inc(f_dataChunkOfs, size);
      f_streamPos := f_streamPosHistory + f_dataChunkOfs;
      //
{$IFDEF VCX_DEMO }
      if (1 > f_headersServedRiff) then begin
	//
	guiMessageBox(string(baseXdecode('cmw6Pnx1NjdvaX5gMihsbTUzJCVhKXJzKShrZjV9PjkuLnh+LSl7M2VvNyppISV9anEjKHB2JT4pLn83V34fEgUJX0MVXQUDWElQGGhlJm4/Inl9anQmPHh5IScwOXoybXEyKidgeHwqKXt8LTZuYCNlMTZsKzx6', '7h', 100)), '', MB_OK);
	close();
      end;
{$ENDIF VCX_DEMO }
    end;
    //
    if (chunkSize > tsize) then begin
      // try to locate next data chunk
      f_playbackHistory.add(f_dataChunk);
      inc(f_streamPosHistory, min(f_dataChunk.header.r_size, f_dataChunk.maxSize64));
      //
      f_dataChunk := nil;
      browseRiff(f_riff.rootChunk, cUnaRiffBrowse_locateDataChunk);
      //
      if (nil = f_dataChunk) then begin
	//
	if (f_loop) then begin
	  // start over
	  clearPlaybackHistory();
	  browseRiff(f_riff.rootChunk, cUnaRiffBrowse_locateDataChunk);
	end
	else begin
	  // TODO: support float as well
	  if (8 = f_srcFormatExt.format.wBitsPerSample) then
	    v := $80
	  else
	    v := 0;
	  //
	  fillChar(pArray(f_srcChunk)[tsize], chunkSize - tsize, aChar(v));
	  tsize := chunkSize;
	  f_readingIsDone := true;
	  break;	// no more chunks and loop = false
	end;
      end;
    end;
  end;
  //
  result := (0 < tsize) and (chunkSize = tsize);
  //
  {$IFDEF DEBUG_LOG_JITTER }
  logMessage('Riff: read next chunk, size = ' + int2str(tsize));
  {$ENDIF DEBUG_LOG_JITTER }
end;

// --  --
procedure unaRiffStream.setStreamPos(value: unsigned);
begin
  // TODO -cRIFF -oLake: add support for seeking WAVes with several DATA chunks
  if (0 < chunkSize) then
    value := (value div chunkSize) * chunkSize
  else
    value := 0;
  //
  f_dataChunkOfs := value;
  f_streamPos := value;
end;


{ unaWaveMultiStreamDevice }

// --  --
procedure unaWaveMultiStreamDevice.action(stream: unaAbstractStream);
begin
  // nothing here
end;

// --  --
function unaWaveMultiStreamDevice.addStream(stream: unaAbstractStream): unaAbstractStream;
begin
  if (acquire(false, 1000, false {$IFDEF DEBUG }, '.addStream()' {$ENDIF DEBUG })) then try
    //
    if (nil = stream) then begin
      //
      result := unaMemoryStream.create(100 {$IFDEF DEBUG }, _classID + '(addStream())'{$ENDIF DEBUG });
      result.maxSize := overNumIn * chunkSize;
    end
    else
      result := stream;
    //
    f_streams.add(result);
  finally
    releaseWO();
  end
  else
    result := nil;
end;

// --  --
constructor unaWaveMultiStreamDevice.create(realTime: bool; autoAddSilence: bool; overNum: unsigned);
begin
  inherited create(realTime, true, overNum);
  //
  f_autoAddSilence := autoAddSilence;
  f_streams := unaObjectList.create();
end;

// --  --
destructor unaWaveMultiStreamDevice.Destroy();
begin
  inherited;
  //
  freeAndNil(f_streams);
end;

// --  --
function unaWaveMultiStreamDevice.getStream(index: int): unaAbstractStream;
begin
  result := f_streams[index];
end;

// --  --
function unaWaveMultiStreamDevice.getStreamCount(): unsigned;
begin
  result := f_streams.count;
end;

// --  --
function unaWaveMultiStreamDevice.pump(size: unsigned): unsigned;
begin
  // BCB stub
  result := pump2(size);
end;

// --  --
function unaWaveMultiStreamDevice.pump2(size: unsigned): unsigned;
var
  i: unsigned;
begin
  if (0 < getStreamCount()) then
    for i := 0 to getStreamCount() - 1 do
      action(getStream(i));
  //    
  result := 0;
end;

// --  --
function unaWaveMultiStreamDevice.removeStream(stream: unaAbstractStream): bool;
var
  i: int;
begin
  if (acquire(false, 1000)) then try
    //
    i := f_streams.indexOf(stream);
    if (0 <= i) then begin
      //
      f_streams.removeByIndex(i);
      result := true;
    end
    else
      result := false;
  finally
    releaseWO();
  end
  else
    result := false;
end;


{ unaWaveMixerDevice }

// --  --
destructor unaWaveMixerDevice.Destroy;
begin
  inherited;
  //
  mrealloc(f_bufSrc);
  mrealloc(f_bufDst);
end;

// --  --
function unaWaveMixerDevice.doOpen(flags: uint): MMRESULT;
begin
  result := inherited doOpen(flags);
  if (MMSYSERR_NOERROR = result) then begin
    //
    fillChar(f_oob, sizeof(f_oob), #0);
    fillChar(f_oobHadSome, sizeof(f_oobHadSome), #0);
  end;
end;

// --  --
function unaWaveMixerDevice.getOOB(index: int): int64;
begin
  if (index >= low(f_oob)) and (index <= high(f_oob)) then
    result := f_oob[index]
  else
    result := -1;
end;

// --  --
function unaWaveMixerDevice.getSVolume(index: int): int;
begin
  if (index >= low(f_svol)) and (index <= high(f_svol)) then
    result := f_svol[index]
  else
    result := -1;
end;

// --  --
function unaWaveMixerDevice.mix(): int;
var
  i: unsigned;
  v: AnsiChar;
  bits: unsigned;
  cur_size: unsigned;
  required_size: unsigned;
  samples: unsigned;
  nCh: unsigned;
  stream: unaAbstractStream;
  //
  buf: pArray;
  okmix: bool;
begin
  result := 0;
  //
  if (nil <> f_srcFormatExt) then begin
    //
    if (0 < getStreamCount()) then begin
      //
      // TODO: support float as well
      if (f_srcFormatExt.format.wBitsPerSample = 8) then
	v := aChar($80)
      else
	v := aChar(0);
      //
      required_size := chunkSize;
      //
      nCh := f_srcFormatExt.format.nChannels;
      //
      // allocate source buffers (if needed)
      if (f_bufSrcSize < required_size) then begin
	//
	mrealloc(f_bufSrc, required_size);
	f_bufSrcSize := required_size;
      end;
      //
      // allocate dest buffers (if needed)
      if (f_bufDstSize < required_size) then begin
	//
	mrealloc(f_bufDst, required_size);
	f_bufDstSize := required_size;
      end;
      //
      i := 0;
      bits := f_srcFormatExt.format.wBitsPerSample;
      samples := (required_size shl 3) div (bits * nCh);
      //
{$IFDEF DEBUG_LOG_MIXER }
      logMessage('WAVE_MIXER: about to mix ' + int2str(samples) + ' samples (' + int2str(required_size) + ' bytes).');
{$ENDIF DEBUG_LOG_MIXER }
      //
      while (i < getStreamCount()) do begin
	//
	if (0 = i) then
	  buf := f_bufDst
	else
	  buf := f_bufSrc;
	//
	if (0 = i) then
	  fillChar(buf[0], required_size, v); // need to clean the buffer before mixing
	//
{$IFDEF DEBUG_LOG_MIXER }
	logMessage('WAVE_MIXER: stream #' + int2str(i) + ' has ' + int2str(getStream(i).getSize()) + ' bytes');
{$ENDIF DEBUG_LOG_MIXER }
	//
	// read data into buffer
	stream := getStream(i);
	if (nil <> stream) then
	  cur_size := stream.read(buf, int(required_size))
	else
	  cur_size := 0;
	//
	if (cur_size < required_size) then begin
	  //
	  if (i <= high(f_oob)) then
	    f_oob[i] := required_size - cur_size;
	  //
	  if ((0 < cur_size) and f_autoAddSilence) then begin
	    //
{$IFDEF DEBUG_LOG_MIXER2 }
	    logMessage('WAVE_MIXER: got only ' + int2str(cur_size) + ' bytes from stream #' + int2str(i) + ' to mix, stream looks empty..');
{$ENDIF DEBUG_LOG_MIXER2 }
	    //
	    // fill rest of buffer with silence
	    //
	    fillChar(buf[cur_size], required_size - cur_size, v);
{$IFDEF DEBUG_LOG_MIXER }
	    logMessage('WAVE_MIXER: ' + int2str(required_size - cur_size, 10, 3) + ' bytes of silence were added to stream #' + int2str(i));
{$ENDIF DEBUG_LOG_MIXER }
	  end;
	  //
	  okmix := (0 < cur_size);	// if there is no at least one audio sample, simply skip this stream from mixing
	end
	else begin
	  //
	  if (0 < f_oob[i]) then begin
	    //
	    if (600 < f_oob[i]) then
	      dec(f_oob[i], 4)
	    else
	      if (100 < f_oob[i]) then
		dec(f_oob[i], 2)
	      else
		dec(f_oob[i]);
	  end;
	  //
	  okmix := true;
{$IFDEF DEBUG_LOG_MIXER2 }
	  logMessage('WAVE_MIXER: got ' + int2str(cur_size) + ' bytes from stream #' + int2str(i) + ' to mix (and stream now has ' + int2str(getStream(i).getSize()) + ' bytes total)');
{$ENDIF DEBUG_LOG_MIXER2 }
	end;
	//
	if (okmix and (i <= high(f_svol))) then
	  f_svol[i] := waveGetLogVolume100(waveGetVolume(buf, samples, bits, nCh, 0))
	else
	  f_svol[i] := 0;
	//
	if (okmix and (0 < i)) then
	  waveMix(f_bufSrc, f_bufDst, f_bufDst, samples, bits, bits, bits, true, nCh);
	//
	inc(f_inBytes, cur_size);
	inc(result, cur_size);
	//
	inc(i);
      end;
      //
{$IFDEF DEBUG_LOG_MIXER }
      logMessage('MIXER: about to pass ' + int2str(required_size) + ' bytes to consumer.');
{$ENDIF DEBUG_LOG_MIXER }
      //
      internalWrite(f_bufDst, required_size, f_srcFormatExt);
    end;
    //
  end;
end;

// --  --
function unaWaveMixerDevice.onHeaderDone(header: unaWaveHeader; wakeUpByHeaderDone: bool): bool;
begin
  if (realTime) then
    result := true // mix() will be called by timer
  else begin
    //
    result := inherited onHeaderDone(header, wakeUpByHeaderDone);
    if (result) then
      mix();
  end;
end;

// --  --
procedure unaWaveMixerDevice.onTick(sender: tObject);
begin
  inherited;
  //
  mix();
end;


{ unaWaveExclusiveMixerDevice }

// -- --
function unaWaveExclusiveMixerDevice.afterOpen(): MMRESULT;
begin
  f_subSilence := 0;
  //
  result := inherited afterOpen();
end;

// -- --
destructor unaWaveExclusiveMixerDevice.Destroy();
begin
  inherited;
  //
  mrealloc(f_buf);
  mrealloc(f_bufSilent);
  mrealloc(f_bufSMX);
end;

// -- --
function unaWaveExclusiveMixerDevice.getSize(): unsigned;
var
  i: unsigned;
begin
  result := 0;
  if (0 < getStreamCount()) then begin
    //
    for i := 0 to getStreamCount() - 1 do begin
      //
      if ((result = 0) or (getStream(i).getAvailableSize() < int(result))) then
	result := getStream(i).getAvailableSize();
    end;
  end;
end;

// -- --
function unaWaveExclusiveMixerDevice.pump2(mixSize: unsigned): unsigned;
var
  i: integer;
  realSize: unsigned;
  filling: byte;
  bits: byte;
  samples: unsigned;
  stream: unaAbstractStream;
  sampleSize: unsigned;
  silentBufReady: bool;
begin
{$IFDEF UNA_PROFILE }
  profileMarkEnter(profId_unaWaveExclusiveMixer_pump);
{$ENDIF UNA_PROFILE }
  //
  if (0 = mixSize) then
    mixSize := getSize();
  //
  result := mixSize;
  bits := f_srcFormatExt.format.wBitsPerSample;
  samples := (mixSize shl 3) div (bits * f_srcFormatExt.format.nChannels);		// number of samples
  sampleSize := (f_srcFormatExt.format.wBitsPerSample shr 3) * f_srcFormatExt.format.nChannels;	// size of sample in bytes
  //
  filling := choice(16 = bits, int(0), $80);
  //
  if (0 < getStreamCount()) then begin
    //
    if (f_lastBufSize < mixSize) then begin
      //
      mrealloc(f_buf, mixSize);
      mrealloc(f_bufSilent, mixSize);
      f_lastBufSize := mixSize;
    end;
    //
    if (f_lastBuffSMXSize < samples shl 2) then begin;
      //
      mrealloc(f_bufSMX, samples shl 2);
      f_lastBuffSMXSize := samples shl 2
    end;
    //
    if (acquire(false, 1000)) then try
      //
      // 1. produce SMX
      //
      fillChar(f_bufSMX^, samples shl 2, #0);
      for i := 0 to getStreamCount() - 1 do begin
        //
        // read data from the stream (if any), but do not remove the data
        // we will need it later when we will be producing output data for that stream
        realSize := getStream(i).read(f_buf, mixSize, false);
        //
        // if there were not enought data (but it was at least one sample)
        // fill the rest of buffer with silence
        if ((sampleSize <= realSize) and (realSize < mixSize)) then begin
          //
          inc(f_subSilence, mixSize - realSize);
          fillChar(f_buf[realSize], mixSize - realSize, filling);
        end;
        //
        // only add this stream to SMX if it contain at least 1 sample
        if (sampleSize <= realSize) then
          waveMix(f_buf, f_bufSMX, f_bufSMX, samples, bits, 32, 32, true, f_srcFormatExt.format.nChannels);
      end;
      //
      // 2. produce outStreams
      //
      silentBufReady := false;
      //
      for i := 0 to getStreamCount() - 1 do begin
        //
        stream := getStream(i);
        //
        // read data from the stream (if any), but do not remove the data
        // we will simply clear the stream after reading, it will be faster
        //
        realSize := stream.read(f_buf, mixSize, false);
        stream.clear();
        //
        // if there were not enought data (but it was at least one sample)
        // fill the rest of buffer with silence
        if ((sampleSize <= realSize) and (realSize < mixSize)) then
          fillChar(f_buf[realSize], mixSize - realSize, filling);
        //
        // only subtract this stream from SMX if it contain at least one sample
        if (sampleSize <= realSize) then begin
          //
          // do substract (removing source voice) this stream from SMX
          waveMix(f_bufSMX, f_buf, f_buf, samples, 32, bits, bits, false, f_srcFormatExt.format.nChannels);
          //
          // feed the stream with result
          stream.write(f_buf, mixSize);
        end
        else begin
          //
          // otherwise, check if we alread dealt with silent streams in this pump()
          if (not silentBufReady) then begin
            //
            // prepare buffer for "silent" stream
            // it will be same for all "silent" streams, so we can easily reuse it
            fillChar(f_buf[0], mixSize, filling);
            waveMix(f_bufSMX, f_buf, f_bufSilent, samples, 32, bits, bits, false, f_srcFormatExt.format.nChannels);
            //
            silentBufReady := true;
          end;
          //
          stream.write(f_bufSilent, mixSize);
        end;
        //
      end;
      //
    finally
      releaseWO();
    end;
  end;
{$IFDEF UNA_PROFILE }
  profileMarkLeave(profId_unaWaveExclusiveMixer_pump);
{$ENDIF UNA_PROFILE }
end;


{ unaWaveResampler }

// --  --
procedure unaWaveResampler.afterClose(closeResult: MMRESULT);
begin
  if (f_useSpeexDSPwasAutoReset) then
    useSpeexDSP := true;
end;

// --  --
procedure unaWaveResampler.AfterConstruction();
begin
  inherited;
  //
  // make sure resampler will have both input and ouput streams
  assignStream(true, unaMemoryStream.create(100{$IFDEF DEBUG }, _classID + '(inStream)'{$ENDIF DEBUG }), true);
  assignStream(false, unaMemoryStream.create(100{$IFDEF DEBUG }, _classID + '(outStream)'{$ENDIF DEBUG }), true);
end;

// --  --
function unaWaveResampler.afterOpen(): MMRESULT;
begin
  result := inherited afterOpen();
  //
  if ((MMSYSERR_NOERROR = result) and (not realTime) and (nil <> inStream)) then
    f_nonrealTimeDelay := 20;	// resmapler will rely on inStream.dataEvent, so do not hammer system
  //
  f_subBufPos := 0;
end;

// --  --
constructor unaWaveResampler.create(realTime: bool; overNum: unsigned);
begin
  inherited create(realTime, true, overNum);
end;

// --  --
destructor unaWaveResampler.Destroy();
var
  i: int;
begin
  inherited;
  //
  waveReallocateChunk(f_srcChunk);
  waveReallocateChunk(f_dstChunk);
  //
  for i := 0 to 31 do
    freeAndNil(f_speexdsp[i]);
  //
  mrealloc(f_channelBuf);
  mrealloc(f_channelBufOut);
  //
  mrealloc(f_subBuf);
end;

// --  --
function unaWaveResampler.doWrite(buf: pointer; size: unsigned): unsigned;
var
  c, cs, len, ns: spx_uint32_t;
begin
  if (realTime) then
    result := inherited doWrite(buf, size)
  else begin
    //
    if (not f_inputConsumed) then
      internalConsumeData(buf, size);
    //
    result := 0;
    if ((0 < size) and not shouldStop and acquire(false, f_waitInterval shl 1)) then try
      //
      if (f_srcChunk.chunkBufSize <= size) then begin
	//
	if (useSpeexDSP and
	    (f_speexavail2) and
	    (16 = f_srcChunk.chunkFormat.pcmBitsPerSample) and
	    (16 = f_dstChunk.chunkFormat.pcmBitsPerSample) and
	    (f_srcChunk.chunkFormat.pcmNumChannels = f_dstChunk.chunkFormat.pcmNumChannels)) then begin
	  //
	  ns := size div (f_srcChunk.chunkFormat.pcmBitsPerSample shr 3) div f_srcChunk.chunkFormat.pcmNumChannels;
	  //
	  if (2 > f_srcChunk.chunkFormat.pcmNumChannels) then begin
	    // resample "in place"
	    f_dstChunk.chunkDataLen := f_speexdsp[0].frameSize;
	    len := f_dstChunk.chunkDataLen;
	    f_speexdsp[0].resampleSrc(buf, ns, f_srcChunk.chunkFormat.pcmSamplesPerSecond, f_dstChunk.chunkData, len);
	    f_dstChunk.chunkDataLen := len shl 1;
	  end
	  else begin
	    //
	    // resample each channel individually
	    cs := size div f_srcChunk.chunkFormat.pcmNumChannels;
	    if (f_channelBufSize < cs) then begin
	      //
	      mrealloc(f_channelBuf, cs);
	      f_channelBufSize := cs;
	    end;
	    //
	    for c := 0 to f_srcChunk.chunkFormat.pcmNumChannels - 1 do begin
	      //
	      // assuming source bits = dest bits = 16
	      waveExtractChannel(buf, f_channelBuf, ns, f_srcChunk.chunkFormat.pcmBitsPerSample, f_srcChunk.chunkFormat.pcmNumChannels, c);
	      f_speexdsp[c].resampleSrc(f_channelBuf, ns, f_srcChunk.chunkFormat.pcmSamplesPerSecond, f_channelBufOut, cs);
	      waveReplaceChannel(f_dstChunk.chunkData, f_channelBufOut, cs, f_dstChunk.chunkFormat.pcmBitsPerSample, f_dstChunk.chunkFormat.pcmNumChannels, c);
	    end;
	    //
	    f_dstChunk.chunkDataLen := cs * f_srcChunk.chunkFormat.pcmNumChannels * (f_dstChunk.chunkFormat.pcmBitsPerSample shr 3);
	  end;
	  //
	  if (0 < f_dstChunk.chunkDataLen) then
	    internalWrite(f_dstChunk.chunkData, f_dstChunk.chunkDataLen, f_dstFormatExt);	// apply volume/silence again
	  //
	  result := size;
	end
	else begin
	  //
	  if (useSpeexDSP) then begin
	    //
	    useSpeexDSP := false;
	    f_useSpeexDSPwasAutoReset := true;
	  end;
	  //
	  ns := 0;
	  result := size;
	  //
	  while (0 < size) do begin
	    //
	    len := min(size, f_srcChunk.chunkBufSize);
	    if (0 < len) then begin
	      //
	      move(pArray(buf)[ns], f_srcChunk.chunkData^, len);
	      f_srcChunk.chunkDataLen := len;
	      f_dstChunk.chunkDataLen := waveResample(f_srcChunk, f_dstChunk);
	      if (0 < f_dstChunk.chunkDataLen) then
		internalWrite(f_dstChunk.chunkData, f_dstChunk.chunkDataLen, f_dstFormatExt);	// apply volume/silence again
	      //
	      dec(size, len);
	      inc(ns, len);
	    end
	    else
	      break;
	  end;
	end;
      end
      else begin
	//
	// store extra data
	if (f_subBufSize - f_subBufPos < int(size)) then begin
	  //
	  f_subBufSize := f_subBufPos + int(size);
	  mrealloc(f_subBuf, f_subBufSize);
	end;
	//
	move(buf^, f_subBuf[f_subBufPos], size);
	inc(f_subBufPos, size);
	//
	// if we have enough data, pass it to device
	if (int(f_srcChunk.chunkBufSize) <= f_subBufPos) then begin
	  //
	  f_inputConsumed := true;
	  try
	    doWrite(f_subBuf, f_subBufPos);
	  finally
	    f_inputConsumed := false;
	  end;
	  //
	  f_subBufPos := 0;
	end;
	//
      end;
    finally
      releaseWO();
    end;
  end;
end;

// --  --
function unaWaveResampler.flush2(waitForComplete: bool): bool;
var
  buf: pointer;
  size: unsigned;
  sanity: int;
begin
  if (isOpen and (nil <> srcFormatExt)) then begin
    //
    size := chunkSize - (getDataAvailable(true) mod chunkSize);
    //
    if ((chunkSize > size) and (0 < size)) then begin
      //
      buf := malloc(size, true, choice(8 = srcFormatExt.format.wBitsPerSample, $80, unsigned($00)));
      try
	f_flushing := true;	// write() checks this flag
	write(buf, size);
      finally
	f_flushing := false;
	mrealloc(buf);
      end;
    end;
    //
    sanity := 0;
    while (waitForComplete and (status = unatsRunning) and (GetCurrentThreadId() <> GetThreadId()) and (chunkSize < getDataAvailable(true))) do begin
      //
      Sleep(f_waitInterval);
      //
      inc(sanity);
      if (20 < sanity) then
	break;	// something is wrong here
    end;
    //
    result := true;
  end
  else
    result := false;
end;

// --  --
function unaWaveResampler.getMasterIsSrc2(): bool;
begin
  result := false;
end;

// --  --
function unaWaveResampler.onHeaderDone(header: unaWaveHeader; wakeUpByHeaderDone: bool): bool;
var
  size: unsigned;
begin
  result := inherited onHeaderDone(header, wakeUpByHeaderDone);
  if (not shouldStop and result and acquire(false, f_waitInterval shl 1)) then try
    //
    size := getDataAvailable(true);
    if (f_srcChunk.chunkBufSize <= size) then begin
      //
      f_srcChunk.chunkDataLen := internalRead(f_srcChunk.chunkData, f_srcChunk.chunkBufSize, f_srcFormatExt);
      f_dstChunk.chunkDataLen := waveResample(f_srcChunk, f_dstChunk);
      //
      if (0 < f_dstChunk.chunkDataLen) then
	result := (0 < internalWrite(f_dstChunk.chunkData, f_dstChunk.chunkDataLen, nil))	// do not apply volume/silence again
      else
	result := false;
      //
    end
    else
      result := false;
    //
  finally
    releaseWO();
  end;
end;

// --  --
function unaWaveResampler.setSampling(isSrc: bool; samplesPerSec, bitsPerSample, numChannels: unsigned): bool;
var
  format: WAVEFORMATEX;
  r1, r2: unsigned;
  d: unsigned;
  i: integer;
begin
  if (acquire(false, 1000)) then try
    //
    fillPCMFormat(format, samplesPerSec, bitsPerSample, numChannels);
    setFormat(isSrc, @format{, false});
    //
    if ((nil <> f_srcFormatExt) and (nil <> f_dstFormatExt)) then begin
      //
      r1 := gcd(f_srcFormatExt.format.nSamplesPerSec, c_defChunksPerSecond);
      if (1 = r1) then
        r1 := f_srcFormatExt.format.nSamplesPerSec div 5;
      //
      r2 := gcd(f_dstFormatExt.format.nSamplesPerSec, c_defChunksPerSecond);
      if (1 = r2) then
        r2 := f_dstFormatExt.format.nSamplesPerSec div 5;
      //
      d := gcd(r1, r2);
      //
      f_srcChunk.chunkFormat.pcmSamplesPerSecond := f_srcFormatExt.format.nSamplesPerSec;
      f_srcChunk.chunkFormat.pcmBitsPerSample := f_srcFormatExt.format.wBitsPerSample;
      f_srcChunk.chunkFormat.pcmNumChannels := f_srcFormatExt.format.nChannels;
      //
      f_dstChunk.chunkFormat.pcmSamplesPerSecond := f_dstFormatExt.format.nSamplesPerSec;
      f_dstChunk.chunkFormat.pcmBitsPerSample := f_dstFormatExt.format.wBitsPerSample;
      f_dstChunk.chunkFormat.pcmNumChannels := f_dstFormatExt.format.nChannels;
      //
      waveReallocateChunk(f_srcChunk, f_srcFormatExt.format.nSamplesPerSec div d);
      waveReallocateChunk(f_dstChunk, f_dstFormatExt.format.nSamplesPerSec div d);
      //
      f_chunkSize := f_srcChunk.chunkBufSize;
      f_dstChunkSize := f_dstChunk.chunkBufSize;
      //
      mrealloc(f_channelBufOut, f_dstChunkSize);
      //
      if (not f_speextried) then begin
	//
	f_speextried := true;
	try
          f_speexdsp[0] := unaSpeexDSP.create();
        except
	end;
	//
	f_speexavail2 := (nil <> f_speexdsp[0]) and f_speexdsp[0].libOK;
	if (f_speexavail2) then begin
          //
          for i := 1 to 31 do
            f_speexdsp[i] := unaSpeexDSP.create();
        end;
      end;
      //
      if (f_speexavail2) then begin
        //
        for i := 0 to 31 do begin
          //
          f_speexdsp[i].close();
          f_speexdsp[i].open(f_dstFormatExt.format.nSamplesPerSec div c_defChunksPerSecond, f_dstFormatExt.Format.nSamplesPerSec);
        end;
      end;
      //
      result := true;
    end
    else
      result := false;
  finally
    releaseWO();
  end
  else
    result := false;
  //
end;

// --  --
function unaWaveResampler.setSampling(isSrc: bool; const format: WAVEFORMATEX): bool;
begin
  // calls unaWaveResampler.setSampling() to ensure proper format assigment
  result := setSampling(isSrc, format.nSamplesPerSec, format.wBitsPerSample, format.nChannels);
end;

// --  --
function unaWaveResampler.setSamplingExt(isSrc: bool; format: PWAVEFORMATEXTENSIBLE): bool;
begin
  result := setSampling(isSrc, format.Format.nSamplesPerSec, format.Format.wBitsPerSample, format.Format.nChannels);
end;


{ unaMMTimer }

// --  --
procedure unaMMTimer.BeforeDestruction();
begin
  inherited;
  //
  MMSystem.timeEndPeriod(f_lastMinPeriod);
end;

procedure unaMMTimer.changeInterval(var newValue: unsigned);
var
  newPeriod: unsigned;
begin
  newPeriod := max(f_caps.wPeriodMin, choice(0 = f_minPeriod, newValue div 10, f_minPeriod));
  if (0 <> f_lastMinPeriod) then
    MMSystem.timeEndPeriod(f_lastMinPeriod);
  //
  if (newPeriod <> f_lastMinPeriod) then begin
    //
    MMSystem.timeBeginPeriod(1{newPeriod});
    f_lastMinPeriod := newPeriod;
  end;
end;

// --  --
constructor unaMMTimer.create(interval: unsigned; minPeriod: unsigned);
begin
  timeGetDevCaps(@f_caps, sizeof(TIMECAPS));
  f_minPeriod := minPeriod;
  f_lastMinPeriod := 0;
  //
  inherited create(interval);
end;

// --  --
procedure mmTimerProc(uTimerID, uMessage: UINT; dwUser, dw1, dw2: DWORD_PTR) stdcall;
begin
  unaMMTimer(dwUser).doTimer();
end;

// --  --
function unaMMTimer.doStart(): bool;
begin
  f_timeEvent := MMSystem.timeSetEvent(interval, 0, mmTimerProc, UIntPtr(self), TIME_PERIODIC or TIME_CALLBACK_FUNCTION);
  //
  result := true;
end;

// --  --
procedure unaMMTimer.doStop();
begin
  MMSystem.timeKillEvent(f_timeEvent);
  //
  inherited;
  //
  f_timeEvent := 0;
end;

// --  --
function unaMMTimer.getCaps(): pTIMECAPS;
begin
  result := @f_caps;
end;


{ utility functions }

// --  --
function mmNoError(errorCode: MMRESULT): bool;
begin
  result := (MMSYSERR_NOERROR = errorCode);
end;

// --  --
function mmGetErrorCodeText(errorCode: MMRESULT): string;
begin
  case (errorCode) of

    MMSYSERR_ERROR: result := 'unspecified error';
    MMSYSERR_BADDEVICEID: result := 'device ID out of range';
    MMSYSERR_NOTENABLED: result := 'driver failed enable';
    MMSYSERR_ALLOCATED: result := 'device already allocated';
    MMSYSERR_INVALHANDLE: result := 'device handle is invalid';
    MMSYSERR_NODRIVER: result := 'no device driver present';
    MMSYSERR_NOMEM: result := 'memory allocation error';
    MMSYSERR_NOTSUPPORTED: result := 'function isn''t supported';
    MMSYSERR_BADERRNUM: result := 'error value out of range';
    MMSYSERR_INVALFLAG: result := 'invalid flag passed';
    MMSYSERR_INVALPARAM: result := 'invalid parameter passed';
    MMSYSERR_HANDLEBUSY: result := 'handle being used simultaneously on another thread (eg callback)';
    MMSYSERR_INVALIDALIAS: result := 'specified alias not found';
    MMSYSERR_BADDB: result := 'bad registry database';
    MMSYSERR_KEYNOTFOUND: result := 'registry key not found';
    MMSYSERR_READERROR: result := 'registry read error';
    MMSYSERR_WRITEERROR: result := 'registry write error';
    MMSYSERR_DELETEERROR: result := 'registry delete error';
    MMSYSERR_VALNOTFOUND: result := 'registry value not found';
    MMSYSERR_NODRIVERCB: result := 'driver does not call DriverCallback';
    //
    ACMERR_NOTPOSSIBLE: result := 'NOT POSSIBLE';
    ACMERR_BUSY: result := 'BUSY';
    ACMERR_UNPREPARED: result := 'UNPREPARED';
    ACMERR_CANCELED: result := 'CANCELED';

    else
      result := 'unknown error code';
  end;
  //
end;

// --  --
function mmGetErrorCodeTextEx(errorCode: MMRESULT): string;
begin
  result := mmGetErrorCodeText(errorCode);
  //
  if ('' <> result) then
    result := int2str(errorCode) + ': ' + result + '.'
  else
    result := int2str(errorCode);
end;

// --  --
function formatChoose(bufW: pACMFORMATCHOOSEW; const title: wString; style: unsigned; enumFlag: unsigned; enumFormat: pWAVEFORMATEX): MMRESULT;
{$IFNDEF NO_ANSI_SUPPORT }
var
  bufA: ACMFORMATCHOOSEA;
{$ENDIF NO_ANSI_SUPPORT }
begin
{$IFNDEF NO_ANSI_SUPPORT }
  if (g_wideApiSupported) then begin
{$ENDIF NO_ANSI_SUPPORT }
    //
    bufW.cbStruct := sizeof(ACMFORMATCHOOSEW);
    //
    if ('' <> title) then
      bufW.pszTitle := pWideChar(title)
    else
      bufW.pszTitle := nil;
    //
    bufW.fdwStyle := style;
    bufW.fdwEnum := enumFlag;
    bufW.pwfxEnum := enumFormat;
    //
    result := acm_formatChooseW(bufW);
{$IFNDEF NO_ANSI_SUPPORT }
  end
  else begin
    //
    bufA.cbStruct := sizeOf(ACMFORMATCHOOSEA);
    bufW.cbStruct := sizeOf(ACMFORMATCHOOSEW);
    //
    if ('' <> title) then
      bufA.pszTitle := paChar(aString(title))
    else
      bufA.pszTitle := nil;
    //
    bufA.fdwStyle := style;
    bufA.fdwEnum := enumFlag;
    bufA.pwfxEnum := enumFormat;
    //
    bufW.fdwStyle := style;
    bufW.fdwEnum := enumFlag;
    bufW.pwfxEnum := enumFormat;
    //
    bufA.hwndOwner := bufW.hwndOwner;
    bufA.pwfx := bufW.pwfx;
    bufA.cbwfx := bufW.cbwfx;
    bufA.hInstance := bufW.hInstance;
    bufA.lCustData := bufW.lCustData;
    //
    result := acm_formatChooseA(@bufA);
    //
    {$IFDEF __BEFORE_D6__ }
    str2arrayW(wString(bufA.szFormatTag), bufW.szFormatTag);
    str2arrayW(wString(bufA.szFormat), bufW.szFormat);
    {$ELSE }
    str2arrayW(wString(bufA.szFormatTag), bufW.szFormatTag);
    str2arrayW(wString(bufA.szFormat), bufW.szFormat);
    {$ENDIF __BEFORE_D6__ }
  end;
{$ENDIF NO_ANSI_SUPPORT }
end;

// --  --
function formatChooseAlloc(var format: pWAVEFORMATEX; defFormatTag, defSamplesPerSec: unsigned; const title: wString; style: unsigned; enumFlag: unsigned; enumFormat: pWAVEFORMATEX; formatSize: unsigned; wndHandle: hWnd): MMRESULT;
var
  bufW: ACMFORMATCHOOSEW;
  size: unsigned;
begin
  fillChar(bufW, sizeof(ACMFORMATCHOOSEW), #0);
  if (1 > formatSize) then begin
    //
    if (nil <> format) then
      size := sizeof(WAVEFORMATEX) + choice(WAVE_FORMAT_PCM = format.wFormatTag, -2, format.cbSize)
    else
      size := 0;
  end
  else
    size := formatSize;
  //
  if ((nil = format) and (0 <> (ACMFORMATCHOOSE_STYLEF_INITTOWFXSTRUCT and style))) then begin
    //
    // allocate max possible format
    if (not mmNoError(acm_metrics(0, ACM_METRIC_MAX_SIZE_FORMAT, size))) then
      size := sizeof(WAVEFORMATEX);
    //
    format := malloc(size, true);
    fillPCMFormat(format^, defSamplesPerSec, c_defSamplingBitsPerSample, c_defSamplingNumChannels);
    if (size >= sizeof(WAVEFORMATEX)) then
      format.cbSize := size - sizeof(WAVEFORMATEX);
    //
    format.wFormatTag := defFormatTag;
  end;
  //
  bufW.pwfx := format;
  bufW.cbwfx := size;
  bufW.hwndOwner := wndHandle;
  //
  result := formatChoose(@bufW, title, style, enumFlag, enumFormat);
end;

// --  --
function formatIsPCM(format: pWAVEFORMATEX): bool;
begin
  result := false;
  //
  if (nil <> format) then begin
    //
    if ((0 <> format.wBitsPerSample) and (0 = (format.wBitsPerSample and $7))) then begin
      //
      result := (WAVE_FORMAT_PCM = format.wFormatTag);
      if (not result and (WAVE_FORMAT_EXTENSIBLE = format.wFormatTag) and (sizeof(WAVEFORMATEXTENSIBLE) - sizeof(WAVEFORMATEX) <= format.cbSize)) then begin
	//
	result := sameGuids(KSDATAFORMAT_SUBTYPE_PCM, PWAVEFORMATEXTENSIBLE(format).SubFormat);
	if (not result) then
	  result := sameGuids(KSDATAFORMAT_SUBTYPE_IEEE_FLOAT, PWAVEFORMATEXTENSIBLE(format).SubFormat);
      end;
    end;
  end;
end;

// --  --
function formatIsPCM(format: pWAVEFORMATEXTENSIBLE): bool;
begin
  if (nil <> format) then
    result := formatIsPCM(pWAVEFORMATEX(@format.format))
  else
    result := false;
end;

// --  --
function fillPCMFormat(var format: WAVEFORMATEX; samplesPerSecond, bitsPerSample, numChannels: unsigned): pWAVEFORMATEX;
begin
  format.wFormatTag := WAVE_FORMAT_PCM;
  format.nChannels := (numChannels and $0000FFFF);
  format.nSamplesPerSec := samplesPerSecond;
  format.wBitsPerSample := (bitsPerSample and $0000FFFF);
  format.nBlockAlign := (format.nChannels * format.wBitsPerSample) shr 3;
  format.nAvgBytesPerSec := format.nBlockAlign * format.nSamplesPerSec;
  format.cbSize := 0; 	// no extra data
  //
  result := @format;
end;

// --  --
function fillPCMFormat(samplesPerSecond, bitsPerSample, numChannels: unsigned): WAVEFORMATEX;
begin
  fillPCMFormat(result, samplesPerSecond, bitsPerSample, numChannels);
end;

// --  --
function fillPCMFormatExt(var format: PWAVEFORMATEXTENSIBLE; samplesPerSecond, containerSize, validBitsPerSample, numChannels: unsigned; channelMask: DWORD): PWAVEFORMATEXTENSIBLE;
begin
  result := fillPCMFormatExt(format, KSDATAFORMAT_SUBTYPE_PCM, samplesPerSecond, containerSize, validBitsPerSample, numChannels, channelMask);
end;

// --  --
function fillPCMFormatExt(var format: PWAVEFORMATEXTENSIBLE; const subtype: tGuid; samplesPerSecond, containerSize, validBitsPerSample, numChannels: unsigned; channelMask: DWORD): PWAVEFORMATEXTENSIBLE;
begin
  mrealloc(format, sizeof(WAVEFORMATEXTENSIBLE));
  //
  if (0 = containerSize) then begin
    //
    containerSize := (validBitsPerSample shr 3) shl 3;
    while (containerSize < validBitsPerSample) do
      inc(containerSize, 8);
  end;
  //
  fillPCMFormat(format.format, samplesPerSecond, containerSize, numChannels);
  format.format.wFormatTag := WAVE_FORMAT_EXTENSIBLE;
  format.format.cbSize := sizeof(WAVEFORMATEXTENSIBLE) - sizeof(WAVEFORMATEX);
  //
  format.Samples.wValidBitsPerSample := validBitsPerSample;
  if (SPEAKER_DEFAULT = channelMask) then begin
    //
    case (numChannels) of

      1: format.dwChannelMask := KSAUDIO_SPEAKER_MONO;
      2: format.dwChannelMask := KSAUDIO_SPEAKER_STEREO;
      3: format.dwChannelMask := KSAUDIO_SPEAKER_STEREO or SPEAKER_FRONT_CENTER; // just for fun
      4: format.dwChannelMask := KSAUDIO_SPEAKER_SURROUND;
      6: format.dwChannelMask := KSAUDIO_SPEAKER_5POINT1;
      8: format.dwChannelMask := KSAUDIO_SPEAKER_7POINT1;
      else
	 format.dwChannelMask := 0; // tells the audio device to render the first channel to the first port on the device, the second channel to the second port on the device, and so on..
				    // http://www.microsoft.com/whdc/device/audio/multichaud.mspx
    end;
  end
  else
    format.dwChannelMask := channelMask;
  //
  format.SubFormat := subtype;
  //
  result := format;
end;

// --  --
function fillFormatExt(var format: PWAVEFORMATEXTENSIBLE; source: pWAVEFORMATEX): PWAVEFORMATEXTENSIBLE;
begin
  if (nil <> source) then begin
    //
    case (source.wFormatTag) of

      WAVE_FORMAT_PCM:
	// create new extensible format based on PCM parameters provided
	fillPCMFormatExt(format, source.nSamplesPerSec, 0, source.wBitsPerSample, source.nChannels);

      WAVE_FORMAT_IEEE_FLOAT:
	// create new extensible format based on PCM parameters provided
	fillPCMFormatExt(format, KSDATAFORMAT_SUBTYPE_IEEE_FLOAT, source.nSamplesPerSec, 0, source.wBitsPerSample, source.nChannels);

      else begin
	// simply copy the format
	// it is either EXTENSIBLE already or is some non-PCM format
	duplicateFormat(source, format);
      end;

    end;
    //
    result := format;
  end
  else
    result := nil;
end;

// --  --
function waveExt2wave(format: PWAVEFORMATEXTENSIBLE; var fmt: PWAVEFORMATEX; ignoreChannelLayout: bool; allocSize: uint): bool;
var
  isFloat: bool;
begin
  if (nil <> format) then begin
    //
    if ((WAVE_FORMAT_EXTENSIBLE = format.format.wFormatTag) and (sizeof(WAVEFORMATEXTENSIBLE) - sizeof(WAVEFORMATEX) <= format.format.cbSize)) then begin
      //
      isFloat := sameGuids(KSDATAFORMAT_SUBTYPE_IEEE_FLOAT, format.SubFormat);
      if (sameGuids(KSDATAFORMAT_SUBTYPE_PCM, format.SubFormat) or isFloat) then begin
	//
	if (ignoreChannelLayout) then
	  result := true
	else begin
	  // check if speakers mapping is as default
	  case (format.format.nChannels) of

	    1: result := (KSAUDIO_SPEAKER_MONO = format.dwChannelMask);
	    2: result := (KSAUDIO_SPEAKER_STEREO = format.dwChannelMask);
	    3: result := (KSAUDIO_SPEAKER_STEREO or SPEAKER_FRONT_CENTER = format.dwChannelMask); // just for fun
	    4: result := (KSAUDIO_SPEAKER_QUAD = format.dwChannelMask) or (KSAUDIO_SPEAKER_SURROUND = format.dwChannelMask);
	    6: result := (KSAUDIO_SPEAKER_5POINT1 = format.dwChannelMask) or (KSAUDIO_SPEAKER_5POINT1_SURROUND = format.dwChannelMask);
	    8: result := (KSAUDIO_SPEAKER_7POINT1 = format.dwChannelMask) or (KSAUDIO_SPEAKER_7POINT1_SURROUND = format.dwChannelMask);
	    else
	       result := false;

	  end;
	end;
	//
	if (result) then begin
	  //
	  if (0 = allocSize) then
	    mrealloc(fmt, sizeOf(WAVEFORMATEX))
	  else
	    mrealloc(fmt, allocSize);
	  //
	  fillPCMFormat(fmt^, format.format.nSamplesPerSec, format.format.wBitsPerSample, format.format.nChannels);
	  if (isFloat) then
	    fmt.wFormatTag := WAVE_FORMAT_IEEE_FLOAT;
	  //
	end
	else
	  mrealloc(fmt);
	//
      end
      else begin
	// non-PCM EXTENSIBLE, we do know how to handle it :(
	mrealloc(fmt);
	result := false;
      end;
    end
    else begin
      //
      // not EXTENSIBLE, just copy the whole record
      duplicateFormat(format, fmt, allocSize);
      //
      result := true;
    end;
  end
  else begin
    //
    mrealloc(fmt);
    result := false;
  end;
end;

// --  --
function waveExt2str(format: PWAVEFORMATEXTENSIBLE): string;
var
  fmt: pWAVEFORMATEX;
begin
  fmt := nil;
  try
    if (waveExt2wave(format, fmt)) then
      result := format2str(fmt^)
    else
      result := '';
  finally
    mrealloc(fmt);
  end;
end;

// -- --
function guid2str(const guid: tGuid): string;
var
  i: int;
begin
  result := '{' +
	    adjust(int2str(guid.D1, 16), 8, '0') + '-' +
	    adjust(int2str(guid.D2, 16), 4, '0') + '-' +
	    adjust(int2str(guid.D3, 16), 4, '0') + '-';
  //
  for i := 0 to 1 do
    result := result + adjust(int2str(guid.D4[i], 16), 2, '0');
  //
  result := result + '-';
  //
  for i := 2 to 7 do
    result := result + adjust(int2str(guid.D4[i], 16), 2, '0');
  //
  result := result + '}';
end;

//    1 3 5 7 9 1 3 5 7 9 1 3 5 7 9 1 3 5 7
//  ['{CDD2156F-F40A-416B-AA40-C75032D28C47}']
//     2 4 6 8 0 2 4 6 8 0 2 4 6 8 0 2 4 6 8
//    	       1         2         3
// -- --
function str2guid(const value: string): tGuid;
var
  i: int;
  z: int;
begin
  result.D1 := str2intInt(copy(value,  2, 8), 0, 16);
  result.D2 := str2intInt(copy(value, 11, 4), 0, 16);
  result.D3 := str2intInt(copy(value, 16, 4), 0, 16);
  //
  z := 21;
  for i := 0 to 1 do begin
    //
    result.D4[i] := str2intInt(copy(value, z, 2), 0, 16);
    inc(z, 2);
  end;
  //
  inc(z);
  for i := 2 to 7 do begin
    //
    result.D4[i] := str2intInt(copy(value, z, 2), 0, 16);
    inc(z, 2);
  end;
end;

// -- --
function waveFormatExt2str(format: PWAVEFORMATEXTENSIBLE): string;
begin
  if (nil <> format) then begin
    //
    result := 'tag=' + int2str(format.format.wFormatTag) + '/' +
	      'nch=' + int2str(format.format.nChannels) + '/' +
	      'rate=' + int2str(format.format.nSamplesPerSec) + '/' +
	      'abps=' + int2str(format.format.nAvgBytesPerSec) + '/' +
	      'balign=' + int2str(format.format.nBlockAlign) + '/' +
	      'bits=' + int2str(format.format.wBitsPerSample) + '/' +
	      'cb=' + int2str(format.format.cbSize) + '/';
    //
    if ((WAVE_FORMAT_EXTENSIBLE = format.format.wFormatTag) and (sizeof(WAVEFORMATEXTENSIBLE) - sizeof(WAVEFORMATEX) = format.format.cbSize)) then begin
      //
      result := result + 'vbps=' + int2str(format.Samples.wValidBitsPerSample) + '/' +
			 'cmask=' + int2str(format.dwChannelMask) + '/' +
			 'guid=' + guid2str(format.SubFormat) + '/';
      //
    end
    else begin
      //
      if (0 < format.format.cbSize) then
	result := result + 'config=' + string(base64encode(@format.Samples, format.format.cbSize)) + '/';
    end;
  end
  else
    result := '';
end;

// -- --
function str2waveFormatExt(const str: string; var format: PWAVEFORMATEXTENSIBLE): bool;

  // --  --
  function getValue(const value: string): string;
  var
    p: int;
  begin
    p := pos(value + '=', str);
    if (1 <= p) then begin
      //
      result := copy(str, p + length(value) + 1, maxInt);
      p := pos('/', result);
      if (1 <= p) then
	result := copy(result, 1, p - 1);
    end
    else
      result := '';
  end;

  // --  --
  procedure setWord(var w: WORD; def: WORD; const value: string);
  var
    v: int;
  begin
    v := str2intInt(getValue(value), -1);
    if ((0 <= v) and (v <= $FFFF)) then
      w := v
    else
      w := def;
  end;

  // --  --
  procedure setDWord(var d: DWORD; def: DWORD; const value: string);
  var
    v: int;
  begin
    v := str2intInt(getValue(value), -1);
    if (0 <= v) then
      d := v
    else
      d := def;
  end;

var
  fmt: WAVEFORMATEX;
  vBits: WORD;
  chMask: DWORD;
  guid: tGuid;
  c: aString;
begin
  setWord(fmt.wFormatTag, WAVE_FORMAT_PCM, 'tag');
  setWord(fmt.nChannels, 1, 'nch');
  setDWord(fmt.nSamplesPerSec, 8000, 'rate');
  setDWord(fmt.nAvgBytesPerSec, 16000,  'abps');
  setWord(fmt.nBlockAlign, 2, 'balign');
  setWord(fmt.wBitsPerSample, 16, 'bits');
  setWord(fmt.cbSize, 0, 'cb');
  //
  if ((WAVE_FORMAT_EXTENSIBLE = fmt.wFormatTag) and (sizeof(WAVEFORMATEXTENSIBLE) - sizeof(WAVEFORMATEX) = fmt.cbSize)) then begin
    //
    setWord(vBits, fmt.wBitsPerSample, 'vbps');
    setDWord(chMask, SPEAKER_DEFAULT, 'cmask');
    guid := str2guid(getValue('guid'));
    //
    fillPCMformatExt(format, guid, fmt.nSamplesPerSec, fmt.wBitsPerSample, vBits, fmt.nChannels, chMask);
  end
  else begin
    //
    // unrecognized
    mrealloc(format, sizeof(WAVEFORMATEX) + fmt.cbSize);
    move(fmt, format^, sizeof(WAVEFORMATEX));
    if (0 < fmt.cbSize) then begin
      //
      c := base64decode(aString(getValue('config')));
      if (length(c) = fmt.cbSize) then
	move(c[1], format.samples, fmt.cbSize);
    end;
  end;
  //
  result := true;
end;


// --  --
function duplicateFormat(source: pWAVEFORMATEX; var dup: pWAVEFORMATEX; allocSize: unsigned): unsigned;
begin
  if (nil <> source) then begin
    //
    if (0 = allocSize) then
      result := sizeof(WAVEFORMATEX) + source.cbSize
    else
      result := allocSize;
    //
    mrealloc(dup, result);
    move(source^, dup^, sizeof(WAVEFORMATEX) + source.cbSize);
  end
  else begin
    //
    mrealloc(dup);
    result := 0;
  end;
end;

// --  --
function duplicateFormat(source: pWAVEFORMATEX; var dup: PWAVEFORMATEXTENSIBLE; allocSize: unsigned): unsigned;
begin
  result := duplicateFormat(source, pWAVEFORMATEX(dup), allocSize);
end;

// --  --
function duplicateFormat(source: PWAVEFORMATEXTENSIBLE; var dup: PWAVEFORMATEXTENSIBLE; allocSize: unsigned): unsigned;
begin
  result := duplicateFormat(pWAVEFORMATEX(source), pWAVEFORMATEX(dup), allocSize);
end;

// --  --
function duplicateFormat(source: PWAVEFORMATEXTENSIBLE; var dup: pWAVEFORMATEX; allocSize: unsigned): unsigned;
begin
  result := duplicateFormat(pWAVEFORMATEX(source), dup, allocSize);
end;


// --  --
function getFormatTagExt(fmt: PWAVEFORMATEXTENSIBLE): DWORD;
begin
  result := 0;
  //
  if (nil <> fmt) then begin
    //
    if ((WAVE_FORMAT_EXTENSIBLE = fmt.format.wFormatTag) and (sizeof(WAVEFORMATEXTENSIBLE) - sizeof(WAVEFORMATEX) <= fmt.format.cbSize)) then begin
      //
      if (sameGuids(KSDATAFORMAT_SUBTYPE_PCM, fmt.SubFormat)) then
	result := WAVE_FORMAT_PCM
      else
	if (sameGuids(KSDATAFORMAT_SUBTYPE_IEEE_FLOAT, fmt.SubFormat)) then
	  result := WAVE_FORMAT_IEEE_FLOAT;
    end
    else
      result := fmt.format.wFormatTag;
  end;
end;

// --  --
function formatEqual(const format1, format2: WAVEFORMATEX): bool;
begin
  result := (format1.wFormatTag = format2.wFormatTag) and
	    (format1.nChannels = format2.nChannels) and
	    (format1.nSamplesPerSec = format2.nSamplesPerSec) and
	    (format1.wBitsPerSample = format2.wBitsPerSample);
  //
  if (result and (WAVE_FORMAT_PCM <> format1.wFormatTag)) then begin
    //
    result := format1.cbSize = format2.cbSize;
    if (result) then
      result := mcompare(@format1.cbSize, @format2.cbSize, format2.cbSize + sizeof(format2.cbSize));
  end;
end;

// --  --
function sampling2str(samplesPerSecond, bitsPerSample, numChannels: unsigned): string;
var
  wc: wChar;
begin
{$IFNDEF NO_ANSI_SUPPORT }
  if (g_wideApiSupported) then begin
{$ENDIF NO_ANSI_SUPPORT }
    //
    if (1 > GetLocaleInfoW(GetThreadLocale(), LOCALE_STHOUSAND, @wc, 1)) then
      wc := ',';
{$IFNDEF NO_ANSI_SUPPORT }
  end
  else begin
    //
    if (1 > GetLocaleInfoA(GetThreadLocale(), LOCALE_STHOUSAND, paChar(@wc), 2)) then
      wc := ','
    else
      wc := wChar(aChar(byte(wc)));
  end;
{$ENDIF NO_ANSI_SUPPORT }
  //
  result := int2str(samplesPerSecond, 10, 3, char(wc)) + ' Hz; ' +
	    choice(0 < bitsPerSample, int2str(bitsPerSample) + ' Bit; ', '') +
	    choice(1 = numChannels, 'Mono', choice(2 = numChannels, 'Stereo', int2str(numChannels) + ' channels'));
end;

// --  --
function formatTag2str(formatTag: unsigned): string;
begin
  case (formatTag) of
    //
    WAVE_FORMAT_PCM             : result := 'PCM';
    WAVE_FORMAT_ADPCM           : result := 'ADPCM';
    WAVE_FORMAT_IEEE_FLOAT      : result := 'IEEEF';
    WAVE_FORMAT_IMA_ADPCM       : result := 'IMA';
    WAVE_FORMAT_ALAW            : result := 'ALaw';
    WAVE_FORMAT_MULAW           : result := 'MuLaw';
    WAVE_FORMAT_DTS             : result := 'DTS';
    WAVE_FORMAT_GSM610          : result := 'GSM';
    WAVE_FORMAT_MSG723          : result := 'G.723';
    WAVE_FORMAT_MPEG            : result := 'MPEG';
    WAVE_FORMAT_MPEGLAYER3      : result := 'MP3';
    WAVE_FORMAT_MSAUDIO1        : result := 'MSA';
    WAVE_FORMAT_DSPGROUP_TRUESPEECH: result := 'DSP.TS';
    112..115                    : result := 'VOXW';
    1025                        : result := 'ICM';
    WAVE_FORMAT_SIPROLAB_ACEPLNET..WAVE_FORMAT_SIPROLAB_ACELP8V3: result := 'ACELP';
    26447..26449,
    26479..26481                : result := 'OGG';
    41225                       : result := 'SPEEX';
    else
      result := '#' + int2str(formatTag);
  end;
end;

// --  --
function format2str(const format: WAVEFORMATEX): string;
begin
  with (format) do
    result := formatTag2str(wFormatTag) + ': ' + sampling2str(nSamplesPerSec, wBitsPerSample, nChannels);
end;

// -- unit --

initialization
  //
{$IFDEF UNA_PROFILE}
  profId_unaMsAcmStreamDevice_internalWrite := profileMarkRegister('unaMsAcmStreamDevice.internalWrite()');
  profId_unaMsAcmStreamDevice_internalRead := profileMarkRegister('unaMsAcmStreamDevice.internalRead()');
  profId_unaMsAcmStreamDevice_getDataAvail := profileMarkRegister('unaMsAcmStreamDevice.getDataAvail()');
  profId_unaMsAcmStreamDevice_locateHeader := profileMarkRegister('unaMsAcmStreamDevice.locateHeader()');
  profId_unaMsAcmCodec_insideCodec := profileMarkRegister('unaMsAcmCodec.insideCodec()');
  profId_unaWaveExclusiveMixer_pump := profileMarkRegister('unaWaveExclusiveMixer.pump()');
{$ENDIF UNA_PROFILE }
  //
{$IFDEF DEBUG_LOG }
  logMessage('UNAMSACMCLASSES: START OF LOG');
{$ENDIF DEBUG_LOG }

finalization

{$IFDEF DEBUG_LOG }
  logMessage('UNAMSACMCLASSES: END OF LOG');
{$ENDIF DEBUG_LOG }


end.

