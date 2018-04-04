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

	  unaVC_wave.pas - VC 2.5 Pro audio wave pipe components
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
		Lake, May 2010
		Lake, Mar-Apr 2011

	----------------------------------------------
*)

{$I unaDef.inc }
{$I unaMSACMDef.inc }

{$IFDEF DEBUG }
  {$DEFINE LOG_UNAVC_WAVE_INFOS }	// log informational messages
  {$DEFINE LOG_UNAVC_WAVE_ERRORS }	// log critical errors
{$ENDIF DEBUG }

{*
  Contains audio wave pipes to be used in Delphi/C++Builder IDE.

  Wave components:
  @unorderedList(
    @itemSpacing Compact
    @item @link(unavclWaveInDevice WaveIn)
    @item @link(unavclWaveOutDevice WaveOut)
    @item @link(unavclWaveCodecDevice WaveCodec)
    @item @link(unavclWaveRiff WaveRiff)
    @item @link(unavclWaveMixer WaveMixer)
    @item @link(unavclWaveResampler WaveResampler)
  )

  @Author Lake

	Version 2.5.2008.02 Split from unaVCIDE.pas unit
}

unit
  unaVC_wave;

interface

uses
  Windows, unaTypes, unaClasses,
  MMSystem, unaMsAcmApi, unaMsAcmClasses, unaWave, unaVC_pipe,
  Classes;


// -----------------------
//  -- wave components --
// -----------------------


const
  {*
	Default value for overNum property.
	6 chunks of 1/50 second each.
  }
  defOverNumValue = 6;


type
  {*
        ACM request event handler
  }
  tunaOnAcmReq = procedure (sender: tObject; req: uint; var acm: unaMsAcm) of object;

  //
  // -- unaInOutWavePipe --
  //
  {*
    Base abstract class for wave devices.
  }
  unavclInOutWavePipe = class(unavclInOutPipe)
  private
    f_deviceId: int;
    f_mapped: bool;
    f_deviceWasCreated: bool;
    f_iNeedDriver: bool;
    f_needToUnloadDriver: bool;
    f_driverMode: unaAcmCodecDriverMode;
    f_driverLibrary: wString;
    //
    f_direct: bool;
    f_realTime: boolean;
    f_applyFormatTagImmunable: boolean;
    f_needApplyFormatOnCreate: bool;	// some devices already has format assigned after creation,
					// and this flag should be set to true in that case
    //
    f_minVolume: unsigned;
    f_minActiveTime: unsigned;
    //
    f_onThreshold: unaWaveOnThresholdEvent;
    //
    f_overNum: unsigned;
    f_formatTag: unsigned;
    f_loop: boolean;
    f_inputIsPcm: boolean;
    f_addSilence: boolean;
    f_calcVolume: boolean;
    f_sdmCache: unaWaveInSDMethods;
    //
    f_pcmChannelMaskIsNotDefault: bool;
    //
    f_waveError: int;
    //
    f_formatExt: PWAVEFORMATEXTENSIBLE;	//
    //
    f_acm2: unaMsAcm;
    f_loaded: bool;
    f_driver: unaMsAcmDriver;
    f_device: unaMsAcmStreamDevice;
    f_onAcmReq: tunaOnAcmReq;
    //
    f_sdo: bool;
    f_channelMixMask: int;
    f_channelConsumeMask: int;
    //
    f_waveEngine: unaVCWaveEngine;
    //
    function getSamplingParam(index: integer): unsigned;
    function getWaveErrorAsString(): string;
    function getMinActiveTime(): unsigned;
    function getMinVolLevel(): unsigned;
    //
    procedure myOnDA(sender: tObject; data: pointer; len: cardinal);
    procedure myOnGetProviderFormat(var f: PWAVEFORMATEXTENSIBLE);
    //
    procedure setMapped(value: bool);
    procedure setDirect(value: bool);
    procedure setOverNum(value: unsigned);
    procedure setRealTime(value: boolean);
    procedure setInputIsPcm(value: boolean);
    procedure setCalcVolume(value: boolean);
    //
    procedure setDeviceId(value: int);
    procedure setFormatTag(value: unsigned);
    procedure setFormat(value: PWAVEFORMATEXTENSIBLE);
    procedure setDriver(value: unaMsAcmDriver);
    procedure setSamplingParam(index: integer; value: unsigned);
    //
    procedure setAddSilence(value: boolean);
    procedure setLoop(value: boolean);
    procedure setDriverMode(value: unaAcmCodecDriverMode);
    procedure setDriverLibrary(const value: wString);
    //
    procedure setMinActiveTime(value: unsigned);
    procedure setMinVolLevel(value: unsigned);
    procedure setOnThreshold(value: unaWaveOnThresholdEvent);
    //
    procedure setSdm(value: unaWaveInSDMethods);
    procedure setChannelMixMask(value: int);
    procedure setChannelConsumeMask(value: int);
    procedure setWaveEngine(value: unaVCWaveEngine);
  protected
    {*
	Initializes the wave device.
    }
    procedure Loaded(); override;
    {*
	Returns current position in device.

	@return Current position in data stream (if applicable).
    }
    function doGetPosition(): int64; override;
    {*
        If enableDataProcessing is True, writes data into the wave device using its write() method.
        Otherwise passes data to onNewData() method (thus removing the component from data chain).
        Does nothing if device is nil.

        @param data Stream data.
        @param len Size of data pointed by data.
        @return Number of bytes passed to device.
    }
    function doWrite(data: pointer; len: uint; provider: pointer = nil): uint; override;
    {*
	Reads data from the wave device.

	@return Number of bytes read from device.
    }
    function doRead(data: pointer; len: uint): uint; override;
    {*
	Returns available data size.

	@return Data size available to read from the wave device.
    }
    function getAvailableDataLen(index: integer): uint; override;
    {*
	Creates and opens the wave device.

	@return True if successfull.
    }
    function doOpen(): bool; override;
    {*
	Closes the wave device.
    }
    procedure doClose(); override;
    {*
	Returns active state of the component.

	@return True if wave device was open successfully.
    }
    function  isActive(): bool; override;
    {*
	Applies new data stream format on the device.
	First, it closes the device.
	Next, is assigns driverMode and driverLibrary properties.
	If formatTagImmunable property is False, a new format tag will be assigned.
	New format will be stored in pcmFormatExt.
	Finally, applyDeviceFormat() will be called.
	If device was not re-opened, it also calls checkIfFormatProvider().

	@param data Usually pointer to unavclWavePipeFormatExchange record.
	@param len Size of format pointed by data.
	@param provider Provider of format.
	@param restoreActiveState	Should the device be re-activated after applying of new format.

	@return True if successfull.
    }
    function applyFormat(data: pointer; len: uint; provider: unavclInOutPipe = nil; restoreActiveState: bool = false): bool; override;
    {*
	Fills format exchange data of the pipe stream.

	@param data Data format. Must be deallocated by mrealloc().

	@return Size in bytes of data buffer.
    }
    function getFormatExchangeData(out data: pointer): uint; override;
    {*
        Adds provider to the wave device.
    }
    function doAddProvider(provider: unavclInOutPipe): bool; override;
    {*
        Adds consumer to the wave device.
    }
    function doAddConsumer(consumer: unavclInOutPipe; forceNewFormat: bool = true): bool; override;
    {*
        Removes provider from the wave device.
    }
    procedure doRemoveProvider(provider: unavclInOutPipe); override;
    {*
	Sets new device ID and re-creates device object if needed.

        @param value New device ID value.
    }
    procedure doSetDeviceId(value: int); virtual;
    {*
        Sets new format tag and re-creates device and driver objects if needed.

        @param value New format tag value.
    }
    procedure doSetFormatTag(value: unsigned); virtual;
    procedure doSetFormat(value: PWAVEFORMATEXTENSIBLE); virtual;
    procedure doSetDriver(value: unaMsAcmDriver); virtual;
    procedure doSetSamplingParam(index: int; value: unsigned); virtual;
    //
    procedure doSetAddSilence(value: boolean); virtual;
    procedure doSetLoop(value: boolean); virtual;
    procedure doSetDriverMode(value: unaAcmCodecDriverMode); virtual;
    procedure doSetDriverLibrary(const value: wString); virtual;
    {*
	Returns chunk size (in bytes).

	@return Size of input data chunk in bytes.
    }
    function getChunkSize(): uint; virtual;
    {*
	Some devices (like codecs) may have different sife of input and output chunks.

	@return Size of output data chunk in bytes.
    }
    function getDstChunkSize(): uint; virtual;
    {*
	Triggers when device driver has been changed.
    }
    procedure onDriverChanged(); virtual;
    {*
    }
    procedure initWaveParams(); virtual;
    {*
	Does all the job of device creation.
	Should be overriten with actual implementation.
	Should not be called directly.
    }
    procedure createNewDevice(); virtual;
    {*
	Called when new device is about to be created.
    }
    procedure destroyOldDevice(); virtual;
    {*
	Applies new data stream format for the wave device.
	This implementation assumes device is descendand from unaWaveDevice.

	@param format New data format.
	@param isSrc True if format specifies input data format, False for output.

	@return True if successfull.
    }
    function applyDeviceFormat(format: PWAVEFORMATEXTENSIBLE; isSrc: bool = true): bool; virtual;
    {*
	ACM reqest.

	Used mostly to disable default ACM enumeration.
    }
    procedure doAcmReq(req: uint; var acm: unaMsAcm); virtual;
    //
    // -- properties --
    //
    {*
	Internal.
    }
    property deviceWasCreated: bool read f_deviceWasCreated;
    {*
	Specifies whether device should add silence when it runs out of audio data.
    }
    property addSilence: boolean read f_addSilence write setAddSilence default false;
    {*
	Specifies device ID for the wave device.
	Ranges from 0 to number of wave devices - 1.
	Default value is WAVE_MAPPER, which forces the component to use
	default device assigned in Control Panel.
    }
    property deviceId: int read f_deviceId write setDeviceId;
    {*
	Specifies audio format tag for the wave device.
    }
    property formatTag: unsigned read f_formatTag write setFormatTag default WAVE_FORMAT_PCM;
    {*
	Specifies the device is immunable for format tag changes (usually useful for codecs).
    }
    property formatTagImmunable: boolean read f_applyFormatTagImmunable write f_applyFormatTagImmunable default false;
    {*
	Specifies whether wave device is mapped (obsolete).
    }
    property mapped: bool read f_mapped write setMapped default false;
    {*
	Specifies whether wave device is direct (obsolete).
    }
    property direct: bool read f_direct write setDirect default false;
    {*
	Specifies whether device is working in real-time manner.
    }
    property realTime: boolean read f_realTime write setRealTime default false;
    {*
	Specifies whether wave stream should be looped from end to beginning.
    }
    property loop: boolean read f_loop write setLoop default false;
    {*
	Specifies whether format of input stream of the device is PCM.
    }
    property inputIsPcm: boolean read f_inputIsPcm write setInputIsPcm default true;
    {*
	Specifies driver mode for device.
    }
    property driverMode: unaAcmCodecDriverMode read f_driverMode write setDriverMode default unacdm_acm;
    {*
	Specifies driver library for device.
    }
    property driverLibrary: wString read f_driverLibrary write setDriverLibrary;
    {*
	Specifies which method will be used to detect silence.

	minActiveTime and minVolumeLevel properties control the silence detection behavior for unasdm_VC.
    }
    property silenceDetectionMode: unaWaveInSDMethods read f_sdmCache write setSdm default unasdm_none;
    {*
	MME, ASIO or DS
    }
    property waveEngine: unaVCWaveEngine read f_waveEngine write setWaveEngine default unavcwe_MME;
  public
    {*
    }
    constructor Create(AOwner: TComponent); override;
    {*
	Creates the wave device and assigns default values for properties.
    }
    procedure AfterConstruction(); override;
    {*
	Destroys the wave device.
    }
    procedure BeforeDestruction(); override;
    {*
	Destroys previuosly created wave device, then creates new one.
	Assigns required callbacks for device.
    }
    procedure createDevice();
    {*
	Creates ACM or openH323plugin driver for device (if needed).
    }
    procedure createDriver();
    //
    {*
	Refreshes the device format.
    }
    procedure ensureFormat();
    {*
	Returns current volume of audio signal passing "through" wave device.
	Returned volume range from 0 (silence) to 32768. Scale is linear. Use getLogVolume() method to get volume in logarithmic scale.

	@param channel Channel number to return volume for. Default is $FFFFFFFF (median).
    }
    function getVolume(channel: uint = $FFFFFFFF): unsigned;
    {*
	Returns unchenaged volume of audio signal passing "through" wave device.
	Returned volume range from 0 (silence) to 32768. Scale is linear. Use getLogVolume() method to get volume in logarithmic scale.

	@param channel Channel number to return volume for. Default is $FFFFFFFF (median).
    }
    function getUnVolume(channel: uint = $FFFFFFFF): unsigned;
    {*
	Returns current volume of audio signal passing "through" wave device.
	Returned volume range from 0 (silence) to 100. Scale is logarithmic. Use getVolume() method to get volume in linear scale.

	@param channel Channel number to return volume for. Default is $FFFFFFFF (median).
    }
    function getLogVolume(channel: uint = $FFFFFFFF): unsigned;
    {*
	Changes the volume of specified channel.

	@param volume 100 means no volume change (100%); 50 = 50%; 200 = 200% and so on.
	@param channel Default value of -1 means this volume will be applied on all channels.
    }
    procedure setVolume100(volume: unsigned = 100; channel: int = -1);
    {*
	Flushes any data panding.
    }
    procedure flush();
    {*
	Share ASIO driver with other device.
    }
    procedure shareASIOwith(pipe: unavclInOutWavePipe);
    //
    // -- properties --
    //
    {*
	ACM manager for the device (if any).
    }
    property acm2: unaMsAcm read f_acm2;
    {*
	Device driver.
    }
    property driver: unaMsAcmDriver read f_driver write setDriver;
    {*
	Wave device associated with the pipe.
    }
    property device: unaMsAcmStreamDevice read f_device;
    {*
	PCM format of the wave device.
    }
    property pcmFormatExt: PWAVEFORMATEXTENSIBLE read f_formatExt write setFormat;
    {*
	Input chunk size.
    }
    property chunkSize: uint read getChunkSize;
    {*
	Output chunk size.
    }
    property dstChunkSize: uint read getDstChunkSize;
    {*
	Last wave error.
    }
    property waveError: int read f_waveError;
    {*
	Last wave error as string.
    }
    property waveErrorAsString: string read getWaveErrorAsString;
    //
    {*
	When True tells the component to calculate audio volume of a data stream
	coming into or from the component.
	Use the getVolume() method to get the current volume level.

	This property must be also set to True if silenceDetectionMode is set to unasdm_VC.
    }
    property calcVolume: boolean read f_calcVolume write setCalcVolume default false;
    {*
	Specifies whether device should be "started" after open.
	Default is True.
	Mostly used with codecs, if data processing is done from one main thread
	rather than seperate codec threads.
    }
    property startDeviceOnOpen: bool read f_sdo write f_sdo default true;
    {*
	Specifies channel mask for multi-channel data streams.
    }
    property pcm_channelMask: unsigned index 3 read getSamplingParam write setSamplingParam default c_defSamplingChannelMask;
    {*
	Minimum volume level for recording.
    }
    property minVolumeLevel: unsigned read getMinVolLevel write setMinVolLevel default 0;
    {*
	Minimum active time for recording.
    }
    property minActiveTime: unsigned read getMinActiveTime write setMinActiveTime default 0;
    {*
	Fired when current level of signal has crossed the "silence" mark.
    }
    property onThreshold: unaWaveOnThresholdEvent read f_onThreshold write setOnThreshold;
  published
    {*
	Specifies how many chunks of data (every chunk can hold 1/50 second of audio)
	component can store in the input or output buffer, if data cannot be processed immediately.

	Set this property to 0 to disable the buffer overflow checking
	(this could lead to uncontrolled memory usage grow).
    }
    property overNum: unsigned read f_overNum write setOverNum default defOverNumValue;
    {*
	Specifies number of samples per second for wave device.
	Common values are 44100, 22050, 11025 and 8000.
    }
    property pcm_samplesPerSec: unsigned index 0 read getSamplingParam write setSamplingParam default c_defSamplingSamplesPerSec;
    {*
	Specifies number of bits per sample for wave device.
	Common values are 8 and 16.
    }
    property pcm_bitsPerSample: unsigned index 1 read getSamplingParam write setSamplingParam default c_defSamplingBitsPerSample;
    {*
	Specifies number of channels per sample for wave device.
	Common values are 1 (mono) and 2 (stereo).
    }
    property pcm_numChannels: unsigned index 2 read getSamplingParam write setSamplingParam default c_defSamplingNumChannels;
    {*
	Specifies whether device should not utilize ACM
    }
    property onAcmReq: tunaOnAcmReq read f_onAcmReq write f_onAcmReq;
    {*
	When -1 (default) all channels are included in output stream
	When >= 0, only one specified channel is included
    }
    property channelMixMask: int read f_channelMixMask write setChannelMixMask default -1;
    {*
	Which channels to consume.
    }
    property channelConsumeMask: int read f_channelConsumeMask write setChannelConsumeMask default -1;
    //
    property onDataDSP;
    property enableDataProxy;
    property isFormatProvider;
    property onDataAvailable;
    property onFormatChangeAfter;
    property onFormatChangeBefore;
  end;


  //
  // -- unavclWaveInDevice --
  //
  {*
    Real time PCM audio stream recording from the sound card or other hardware device.

    @bold(Usage): If components has no provider component with
    formatProvider set to True, specify PCM stream parameters before
    activating: pcm_SamplesPerSec, pcm_BitsPerSample and pcm_NumChannels.
    Set deviceId property if required.

    @bold(Example): refer to the vcTalkNow demo. It has waveIn_server
    and waveIn_client components.
    Both are used to record real-time PCM stream to be sent to remote side.
    waveIn_server has c_codec_serverOut component as a consumer.
    That means PCM stream produced by waveIn_server will be passed to
    c_codec_serverOut component automatically.
  }
  unavclWaveInDevice = class(unavclInOutWavePipe)
  private
    function getWaveInDevice(): unaWaveInDevice;
  protected
    {*
      Creates waveIn (recording) device.
    }
    procedure createNewDevice(); override;
  public
    //
    procedure AfterConstruction(); override;
    //
    {*
      Returns waveIn device.
    }
    property waveInDevice: unaWaveInDevice read getWaveInDevice;
  published
    //
    property deviceId;
    property calcVolume;
    //
    {*
      waveIn component is usually a format provider--so this property value was changed to be true by default.
    }
    property isFormatProvider default true;
    property silenceDetectionMode;
    property minVolumeLevel;
    property minActiveTime;
    property onThreshold;
    {*
      Specifies whether the component would produce any data.
      Setting this property to False does not release the waveIn device.
      Set active property to False to release the device as well.
    }
    property enableDataProcessing;
    //
    property waveEngine;
  end;


  // playback options
  unavcPlaybackOption = (unapo_smoothStartup, unapo_jitterRepeat);
  unavcPlaybackOptions = set of unavcPlaybackOption;

  //
  // -- unavclWaveOutDevice --
  //
  {*
    Real time PCM audio stream playback using the sound card or other hardware device.

    @bold(Usage): If components has no provider component with
    formatProvider=true, specify PCM stream parameters before
    activating: pcm_SamplesPerSec, pcm_BitsPerSample and pcm_NumChannels.

    @bold(Example): refer to the vcTalkNow demo.
    It has waveOut_server and waveOut_client components.
    Both are used to playback real-time PCM stream received from remote side.
    In this demo, waveOut_server is a consumer of c_codec_serverIn component.
    That means PCM stream, produced by c_codec_serverIn will be passed
    to waveOut_server automatically.
  }
  unavclWaveOutDevice = class(unavclInOutWavePipe)
  private
    f_onFC: unavclPipeDataEvent;
    f_onFD: unavclPipeDataEvent;
    //
    f_po: unavcPlaybackOptions;
    //
    function getWaveOutDevice(): unaWaveOutDevice;
    procedure myOnACF(sender: tObject; data: pointer; size: cardinal);
    procedure myOnACD(sender: tObject; data: pointer; size: cardinal);
  protected
    {*
      Creates wave Out (playback) device.
    }
    procedure createNewDevice(); override;
    {*
      Since waveOut device is output device, and output format is PCM, we should specify input format as not PCM.
    }
    property inputIsPcm default false;
    {*
	Sets enableDataProcessing value.
    }
    procedure doSetEnableDP(value: boolean); override;
    {*
	Assign playback options
    }
    function doOpen(): bool; override;
  public
    {*
    }
    procedure AfterConstruction(); override;
    //
    {*
      Returns waveOut device.
    }
    property waveOutDevice: unaWaveOutDevice read getWaveOutDevice;
  published
    property deviceId;
    property calcVolume;
    {*
      Specifies whether the component would playback any data.
      Setting this property to False does not release the waveOut device.
      Set active property to False to release the device as well.
    }
    property enableDataProcessing;
    //
    {*
      Fired when another audio chunk was passed to driver for playback.
      If you are self-feeding the playback, it means you have to feed another chunk to achieve continuous playback.

      WARNING: This event is deprecated, refer to onFeedDone.

     <STRONG>NOTE</STRONG>: VCL is NOT multi-threading safe, and you should avoid using VCL routines and classes in this event.
    }
    property onFeedChunk: unavclPipeDataEvent read f_onFC write f_onFC;
    {*
      Fired when chunk was just played out by device.
      This is a good place for any user feedback. Since the data passed
      to this event was played out about 1/50 second ago, you can achieve
      very short delay between actual data being played back, and feedback.
      For example, if you draw an oscilloscope of a wave, use this event
      to be in synch with actual playback.

      <STRONG>NOTE</STRONG>: VCL is NOT multi-threading safe, and you should avoid using VCL routines and classes in this event.
    }
    property onFeedDone: unavclPipeDataEvent read f_onFD write f_onFD;
    //
    property waveEngine;
    {*
	Controls how playback is started and what to do when waveout queue is out of audio data.
    }
    property playbackOptions: unavcPlaybackOptions read f_po write f_po;
  end;


  //
  // -- unavclWaveCodecDevice --
  //

  {*
    Audio stream conversion from one supported format to another.
    It can convert PCM stream to other format (compression) or other
    format to PCM (decompression).

    @bold(Usage): If components has no provider component with
    formatProvider=true, specify PCM stream parameters before
    activating: pcm_SamplesPerSec, pcm_BitsPerSample and pcm_NumChannels.

    Set formatTag property to specify the audio format you wish to
    compress to or decompress from.
    Refer to WAVE_FORMAT_XXXX constants from unaMsAcmAPI.pas unit for possible
    values of this property, or you can use the output of amcEnum demo to
    receive the list of installed formats.

    Set inputIsPCM to true, if you wish to convert PCM stream to another
    audio format (compression).
    Set inputIsPCM to false, if you wish to convert some audio format to
    PCM stream (decompression).

    @bold(Example): refer to the vcTalkNow demo.
    It has c_codec_serverOut component, which is a consumer of waveIn_server
    component.

    That means PCM stream, produced by waveIn_server will be passed to
    c_codec_serverOut automatically.
    It also has ip_server as a consumer.
    That means compressed audio stream will be passed to ip_server automatically.
  }
  unavclWaveCodecDevice = class(unavclInOutWavePipe)
  private
    function getCodec(): unaMsAcmCodec;
  protected
    procedure doSetDriverMode(value: unaAcmCodecDriverMode); override;
    procedure doSetDriverLibrary(const value: wString); override;
    //
    {*
    }
    procedure initWaveParams(); override;
    {*
      Creates ACM codec device.
    }
    procedure createNewDevice(); override;
    {*
      Notifies ACM codec device about driver change.
    }
    procedure onDriverChanged(); override;
    {*
      Applies PCM format for ACM codec device.
    }
    function applyDeviceFormat(format: PWAVEFORMATEXTENSIBLE; isSrc: bool = true): bool; override;
    {*
      Returns format exchange data of the codec.
    }
    function getFormatExchangeData(out data: pointer): uint; override;
  public
    {*
    }
    procedure AfterConstruction(); override;
    //
    //function getVolume(channel: int = 0): int; override;
    {*
      Sets non-PCM format for ACM codec device.
    }
    function setNonPCMFormat(format: PWAVEFORMATEXTENSIBLE): bool;
    {*
      Returns ACM codec device.
    }
    property codec: unaMsAcmCodec read getCodec;
  published
    //
    property formatTag;
    //property realTime;	 // MARCH 07: removed from published, since it makes more confusion than sence
    {*
    }
    property inputIsPcm;
    property calcVolume;
    //
    {*
      Codecs usually does not use the format tag provided by other PCM devices.
    }
    property formatTagImmunable default true;
    {*
      ACM driver mode. When set to unacdm_acm, codec uses ACM to access stream conversion routines.
      unacdm_installable tells codec to use installable driver, specified by driverLibrary.
      unacdm_internal is not currently used.
    }
    property driverMode;
    {*
      When driverMode is set to unacdm_installable this property specifies the name of driver library to use.
      Refer to MSDN documentation for more information about installable drivers.
    }
    property driverLibrary;
    {*
     @noAutoLink(codec) component is usually a format provider--so default value for was changed to true.
    }
    property isFormatProvider default true;
    {*
      Specifies whether the component would perform any data conversion.
    }
    property enableDataProcessing;
    property silenceDetectionMode;
    property minVolumeLevel;
    property minActiveTime;
    property onThreshold;
  end;


  //
  // -- unavclWaveRiff --
  //

  {*
    Reads audio stream from a WAV file, producing PCM stream,
    or creates and writes new WAV file.

    @bold(Usage): set fileName property to specify the file to use.
    Set isInput to true if you wish to read from WAV file.
    Set isInput to false if you wish to create and write into WAV file.
    Set active to true, or call the open() method to start reading or writing.
    Set active to false, or call the close() method to stop reading, or close
    the produced WAV file.
    Set realTime to true if you wish the stream read from WAV file will
    be available in real time manner.

    @bold(Example reading): refer to the vcWavePlayer demo.
    Look for wavIn component, which is used to read the stream from WAV file.
    It has waveResampler as a consumer, that means read audio stream will
    be passed to waveResampler automatically.

    @bold(Example writing): refer to the voiceRecDemo sample.
    Look for waveRiff component, which is a consumer of waveIn component.
    That means PCM stream, produced by waveIn will be passed to
    waveRiff automatically. In this demo waveRiff component is used to
    create the WAV file.
  }
  unavclWaveRiff = class(unavclInOutWavePipe)
  private
    f_isInput: boolean;
    f_fileName: wString;
    f_acod: boolean;
    f_onStreamIsDone: unaOnRiffStreamIsDone;
    f_tmpToKill: wString;
    //
    function getRiff(): unaRiffStream;
    //
    procedure setFileName(const value: wString);
    procedure setIsInput(value: boolean);
    //
    procedure riffOnStreamIsDone(sender: tObject);
  protected
    procedure doSetLoop(value: boolean); override;
    //
    {*
      Creates Riff wave device.
    }
    procedure createNewDevice(); override;
    {*
      This method is supported in WAV-writing mode only (isInput = false),
      and only PCM formats are supported.
    }
    function applyDeviceFormat(format: PWAVEFORMATEXTENSIBLE; isSrc: bool = true): bool; override;
    {*
    }
    function getFormatExchangeData(out data: pointer): uint; override;
  public
    {*
      Creates Riff wave device.
    }
    procedure AfterConstruction(); override;
    {*
      Loads data from specified WAV file.
      If asynchronous = false (default), does not return until whole file is loaded, and closes the device after that.
      Otherwise returns immediately after opening the device.
      If autoCloseOnDone property is true (default) device will be closed automatically when reading from file is complete.
      Otherwise use onStreamIsDone() event to be notified when reading from file is complete.

      This function sets realTime property to false and isInput property to true.
    }
    function loadFromFile(const fileName: wString; asynchronous: bool = false): bool;
    {*
      Loads data from specified stream.
      If asynchronous = false (default), does not return until whole file is loaded, and closes the device after that.
      Otherwise returns immediately after opening the device.
      If autoCloseOnDone property is true (default) device will be closed automatically when reading from file is complete.
      Otherwise use onStreamIsDone() event to be notified when reading from file is complete.

      This function sets realTime property to false and isInput property to true.
    }
    function loadFromStream(stream: tStream; asynchronous: bool = false): bool;
    {*
      Saves data into specified WAV file.
      If asynchronous = false (default), does not return until whole data block is written, and closes the device after that.
      Otherwise returns immediately after opening the device and writing the data into it.
      Use the following code to verify if writing is complete: <CODE>if (waveStream.getDataAvailable(true) > chunkSize) then ...</CODE>

      This function sets realTime and isInput properties to false.
    }
    function saveToFile(const fileName: wString; data: pointer; size: uint; asynchronous: bool = false): bool;
    //
    {*
      Returns Riff wave device.
    }
    property waveStream: unaRiffStream read getRiff;
  published
    //
    {*
      Specifies whether reading and writing should be done in real time.
    }
    property realTime;
    {*
      Specifies whether reading should continue from the start upon reaching the end of file.
    }
    property loop;
    {*
      WaveWriter usually does not use the format tag provided by other PCM devices.
    }
    property formatTagImmunable default true;
    {*
      Use this property to specify wave format of non-PCM WAVe files you wish to create.
    }
    property formatTag;
    property calcVolume;
    //
    {*
      Specifies whether Riff wave device is used for reading or writing the audio.
    }
    property isInput: boolean read f_isInput write setIsInput default true;
    {*
      Specifies file to use with Riff wave device.
    }
    property fileName: wString read f_fileName write setFileName;
    {*
      When true, closes the device automatically when reading from file is complete.
    }
    property autoCloseOnDone: boolean read f_acod write f_acod default true;
    {*
      Specifies whether the component would produce or accept any data.
    }
    property enableDataProcessing;
    property silenceDetectionMode;
    {*
      Fired when reading from file is complete.
      Never fired if loop property is set to true.
    }
    property onStreamIsDone: unaOnRiffStreamIsDone read f_onStreamIsDone write f_onStreamIsDone;
  end;


  //
  // -- unavclWaveMixer --
  //
  {*
    Mixes two or more PCM audio streams. No ACM codecs are used by this component.

    @bold(Usage): If components has no provider component with
    formatProvider=true, specify PCM stream parameters before
    activating: set pcm_SamplesPerSec, pcm_BitsPerSample and pcm_NumChannels
    to specify the audio format parameters.

    Set realTime to true if you wish the mixing to be made in real time manner.
    This component will mix as many streams as it has providers.
    Provider is any VC component, which has consumer property set to mixer component.
    Alternatively you can use addStream() and removeStream() method to add and
    remove streams (see Example B below).

    @bold(Example A): c_mixer_client and c_mixer_server components are used
    in vcNetTalk demo to mix PCM streams coming from live recording device
    and WAVe file stored on disk.

    @bold(Example B): mixer is used in vcPulseGen demo to mix unlimited
    number of sine waves. Refer to demo sources for details.
  }
  unavclWaveMixer = class(unavclInOutWavePipe)
  private
    //f_providerStreams: unaList;
    //
    function getMixer(): unaWaveMixerDevice;
    function getStream(provider: unavclInOutPipe): unaAbstractStream;
    procedure setStream(provider: unavclInOutPipe; stream: unaAbstractStream);
    //
  protected
    procedure doSetAddSilence(value: boolean); override;
    //
    {*
      Writes data into mixer.
    }
    function doWrite(data: pointer; len: uint; provider: pointer = nil): uint; override;
    {*
      Creates PCM wave mixer device.
    }
    procedure createNewDevice(); override;
    {*
    }
    function doAddProvider(provider: unavclInOutPipe): bool; override;
    {*
    }
    procedure doRemoveProvider(provider: unavclInOutPipe); override;
  public
    {*
    }
    procedure AfterConstruction(); override;
    {*
    }
    procedure BeforeDestruction(); override;
    {*
      Returns PCM wave mixer device class instance.
    }
    property mixer: unaWaveMixerDevice read getMixer;
  published
    property addSilence;
    property realTime;
    property calcVolume;
    {*
      Specifies whether the component would perform any data mixing.
    }
    property enableDataProcessing;
    property silenceDetectionMode;
    property minVolumeLevel;
    property minActiveTime;
    property onThreshold;
  end;


  //
  // -- unavclWaveResampler --
  //
  {*
    Audio stream conversion from one PCM format to another.
    No ACM codecs are used by this component.

    @bold(Usage): If components has no provider component with
    formatProvider=true, specify PCM stream parameters before
    activating: set pcm_SamplesPerSec, pcm_BitsPerSample and pcm_NumChannels
    to specify the source format parameters.

    Set dst_SamplesPerSec, dst_BitsPerSample and dst_NumChannels properties
    to specify the destination stream format parameters.

    Set realTime to true if you wish the resampling to be made in real time manner.

    @bold(Example): c_resampler_client and c_resampler_server components
    are used in vcNetTalk demo for resampling the streams produced
    by WAV-reading components to PCM parameters required by mixers.
  }
  unavclWaveResampler = class(unavclInOutWavePipe)
  private
    f_dstFormatExt: PWAVEFORMATEXTENSIBLE;
    f_uspeexdsp: boolean;
    //
    function getResampler(): unaWaveResampler;
    function getDstSamplingParam(index: integer): unsigned;
    procedure setDstSamplingParam(index: integer; value: unsigned);
    procedure setDstFormat(value: PWAVEFORMATEXTENSIBLE);
    procedure setUspeexdsp(value: boolean);
  protected
    {*
      Creates PCM wave resampler device.
    }
    procedure createNewDevice(); override;
    {*
      Applies new audio format for PCM wave resampler device.
    }
    function applyDeviceFormat(format: PWAVEFORMATEXTENSIBLE; isSrc: bool = true): bool; override;
    {}
    function getFormatExchangeData(out data: pointer): uint; override;
  public
    procedure BeforeDestruction(); override;
    {*
    }
    procedure AfterConstruction(); override;
    {*
      Returns PCM resampler device.
    }
    property resampler: unaWaveResampler read getResampler;
    {*
      Specifies destination PCM format of resampler device.
    }
    property dstFormatExt: PWAVEFORMATEXTENSIBLE read f_dstFormatExt write setDstFormat;
  published
    //
    property addSilence;
    property realTime;
    property calcVolume;
    //
    {*
      Specifies number of sampler per second for destination PCM format of resampler device.
    }
    property dst_SamplesPerSec: unsigned index 0 read getDstSamplingParam write setDstSamplingParam default c_defSamplingSamplesPerSec;
    {*
      Specifies number of bits per sample for destination PCM format of resampler device.
    }
    property dst_BitsPerSample: unsigned index 1 read getDstSamplingParam write setDstSamplingParam default c_defSamplingBitsPerSample;
    {*
      Specifies number of channels per sample for destination PCM format of resampler device.
    }
    property dst_NumChannels: unsigned index 2 read getDstSamplingParam write setDstSamplingParam default c_defSamplingNumChannels;
    {*
    }
    property useSpeexDSP: boolean read f_uspeexdsp write setUspeexdsp default false;
    {*
      Specifies whether the component would perform any data modifications.
    }
    property enableDataProcessing;
    property silenceDetectionMode;
    property minVolumeLevel;
    property minActiveTime;
    property onThreshold;
  end;



implementation


uses
  unaUtils,
  unaOpenH323PluginAPI;


{ MS ACM global }

var
// global ACM object
  g_unavclACM: unaMsAcm;	
// True if ACM drivers enumeration was not performed yet.
  g_unavclACMNeedEnum: bool = false;	
// ACM drivers enumeration flags.
  g_unavclACMEnumFlags: uint;	

// --  --
function setAcm(value: unaMsAcm = nil; flags: uint = 0): unaMsAcm;
begin
  if (nil <> value) then
    freeAndNil(g_unavclACM);
  //
  if (nil <> value) then begin
    //
    g_unavclACM := value;
    g_unavclACMNeedEnum := false;
  end
  else begin
    //
    if (nil = g_unavclACM) then begin
      //
      g_unavclACM := unaMsAcm.create();
      g_unavclACMNeedEnum := true;
      g_unavclACMEnumFlags := flags;
    end;
    //
    value := g_unavclACM;
  end;
  //
  result := value;
end;


{ unavclInOutWavePipe }

// --  --
procedure unavclInOutWavePipe.AfterConstruction();
begin
  inherited;
  //
  initWaveParams();
  //
  formatTag := WAVE_FORMAT_PCM;
  pcm_channelMask := SPEAKER_DEFAULT;
end;

// --  --
function unavclInOutWavePipe.applyDeviceFormat(format: PWAVEFORMATEXTENSIBLE; isSrc: bool): bool;
begin
  if (nil <> device) then
    result := (device as unaWaveDevice).setSamplingExt(isSrc, format)
  else
    result := false;
end;

// --  --
function unavclInOutWavePipe.applyFormat(data: pointer; len: uint; provider: unavclInOutPipe; restoreActiveState: bool): bool;
var
  allowFC: bool;
  format: punavclWavePipeFormatExchange;
  wasActive: bool;
  needCheckFP: bool;
begin
  allowFC := true;
  doBeforeAfterFC(true, provider, data, len, allowFC);
  //
  if (allowFC) then begin
    //
    needCheckFP := false;
    //
    if ((data <> nil) and (sizeOf(format.r_formatM) <= len)) then begin
      //
      wasActive := active{ or ((nil <> provider) and (provider.autoActivate and restoreActiveState))};
      close();
      //
      try
	format := data;
	//
	if ( (sizeOf(format^) <= len) and (unacdm_acm <> unaAcmCodecDriverMode(format.r_driverMode)) ) then begin
	  //
	  // first assign driverMode, then driverLibrary (and finally formatTag)
	  driverMode := unaAcmCodecDriverMode(format.r_driverMode);
	  driverLibrary := utf82utf16(format.r_driverLib8);
	end;
	//
	if (not f_applyFormatTagImmunable) then
	  formatTag := format.r_formatM.formatTag;
	//
	with (format.r_formatM.formatOriginal) do
	  fillPCMFormatExt(f_formatExt, pcmSamplesPerSecond, 0, pcmBitsPerSample, pcmNumChannels, format.r_formatM.formatChannelMask);
	//
	result := applyDeviceFormat(f_formatExt, inputIsPcm);
	//
	needCheckFP := result;
      finally
	if (wasActive and restoreActiveState) then begin
	  //
	  needCheckFP := false;
	  open();
	end;
      end;
    end
    else
      result := false;
    //
    if (needCheckFP) then
      checkIfFormatProvider(restoreActiveState);
    //
    doBeforeAfterFC(false, provider, data, len, allowFC);	// allowFC is not used
  end
  else
    result := false;
end;

// --  --
procedure unavclInOutWavePipe.beforeDestruction();
begin
  inherited;
  //
  destroyOldDevice();
  mrealloc(f_formatExt);
  //
  driver := nil;	// make sure driver is freed
end;

// --  --
constructor unavclInOutWavePipe.Create(AOwner: TComponent);
begin
  f_loaded := true;
  //
  if (nil <> AOwner) then
    if (csLoading in AOwner.ComponentState) then
      f_loaded := false;
  //
  f_channelMixMask := -1;
  f_channelConsumeMask := -1;
  //
  f_waveEngine := unavcwe_MME;
  //
  inherited;
end;

// --  --
procedure unavclInOutWavePipe.createDevice();
begin
  doAcmReq(1, f_acm2);
  //
  if (nil = f_formatExt) then
    fillPCMFormatExt(f_formatExt);
  //
  destroyOldDevice();
  //
  createDriver();
  //
  createNewDevice();
  //
  if (nil <> device) then begin
    //
    device.calcVolume := (calcVolume or device.calcVolume);
    device.onDataAvailable := myOnDA;
    device.onGetProviderFormat := myOnGetProviderFormat;
    device.silenceDetectionMode := f_sdmCache;
  end;
  //
  if (f_needApplyFormatOnCreate) then
    applyDeviceFormat(pcmFormatExt, inputIsPcm);
  //
  if ((nil <> consumer) and (nil <> device)) then
    device.assignStream(false, nil);	// remove output stream if we have some consumers
  //
  notifyProviders(self);
  //
  f_deviceWasCreated := true;
end;

// --  --
procedure unavclInOutWavePipe.createDriver();
begin
  if (f_iNeedDriver) then begin
    //
    case (driverMode) of

      unacdm_acm: begin	// use ACM to locate a driver by formatTag
	//
	if (nil <> acm2) then begin
	  //
	  if (g_unavclACMNeedEnum) then begin
	    //
	    acm2.enumDrivers(g_unavclACMEnumFlags);
	    g_unavclACMNeedEnum := false;
	  end;
	  //
	  driver := acm2.getDriverByFormatTag(f_formatTag);
	end;
	//
	f_needToUnloadDriver := false;
      end;

      unacdm_installable: begin	// use installable driver specified by driverLibrary
	//
        if (nil <> acm2) then
          driver := acm2.openDriver(driverLibrary);
        //
	f_needToUnloadDriver := true;
      end;

      unacdm_openH323plugin: begin
	//
	driver := nil;
	f_needToUnloadDriver := false;
      end;

      unacdm_internal: begin	// internal routines will be used - no need to create a driver
	//
	driver := nil;
	f_needToUnloadDriver := false;
      end;

      else begin		// invalid driver mode - remove current driver
	//
	driver := nil;
	f_needToUnloadDriver := false;
      end;

    end;
  end;
end;

// --  --
procedure unavclInOutWavePipe.createNewDevice();
begin
  if (nil <> device) then begin
    //
    device.minVolumeLevel := f_minVolume;
    device.minActiveTime := f_minActiveTime;
    device.onThreshold := f_onThreshold;
    device.channelMixMask := channelMixMask;
    device.channelConsumeMask := channelConsumeMask;
    //
    if (device is unaWaveDevice) then
      (device as unaWaveDevice).waveEngine := waveEngine;
  end;
end;

// --  --
procedure unavclInOutWavePipe.destroyOldDevice();
begin
  freeAndNil(f_device);
end;

// --  --
procedure unavclInOutWavePipe.doAcmReq(req: uint; var acm: unaMsAcm);
begin
  if (Assigned(f_onAcmReq)) then begin
    //
    // transfer resposibility to handler
    f_onAcmReq(self, req, acm);
  end
  else begin
    //
    if (f_loaded) then begin
      //
      // default behavior
      case (req) of

        1: acm := setAcm();       // create

      end;
    end;
  end;
end;

// --  --
function unavclInOutWavePipe.doAddConsumer(consumer: unavclInOutPipe; forceNewFormat: bool): bool;
begin
  result := inherited doAddConsumer(consumer, forceNewFormat);
  //
  if (result and (nil <> device)) then
    device.assignStream(false, nil);	// remove output stream for provider
end;

// --  --
function unavclInOutWavePipe.doAddProvider(provider: unavclInOutPipe): bool;
begin
  result := inherited doAddProvider(provider);
  //
  if (result and (provider is unavclInOutWavePipe) and (nil <> unavclInOutWavePipe(provider).device)) then
    unavclInOutWavePipe(provider).device.assignStream(false, nil);	// remove output stream for provider
end;

// --  --
procedure unavclInOutWavePipe.doClose();
begin
  if (nil <> device) then
    device.close();
  //
  inherited;
end;

// --  --
function unavclInOutWavePipe.doGetPosition(): int64;
begin
  if (nil <> device) then
    result := device.getPosition()
  else
    result := -1;
end;

// --  --
function unavclInOutWavePipe.doOpen(): bool;
{$IFDEF UNA_VCACM_USE_ASIO }
var
  nCh: int;
{$ENDIF UNA_VCACM_USE_ASIO }
begin
  inherited doOpen();
  //
  if (not f_deviceWasCreated) then
    createDevice();
  //
  if (nil <> device) then begin
    //
    f_waveError := device.open(false, 2000, 0, startDeviceOnOpen);
    result := mmNoError(f_waveError);
    //
    {$IFDEF LOG_UNAVC_WAVE_ERRORS }
    if (not result) then
      logMessage(self.className + '.doOpen() - returned ' + int2str(f_waveError) + ' [' + device.getErrorText(f_waveError) + ']');
    {$ENDIF LOG_UNAVC_WAVE_ERRORS }
    //
    case (waveEngine) of

      unavcwe_ASIO: begin
	//
	// update format with actual number of channels
	//
    {$IFDEF UNA_VCACM_USE_ASIO }
	if ((nil <> f_formatExt) and (device is unaWaveDevice)) then begin
	  //
	  if (self is unavclWaveInDevice) then
	    nCh := (device as unaWaveDevice).asioDriver().inputChannels
	  else
	    nCh := (device as unaWaveDevice).asioDriver().outputChannels;
	  //
	  fillPCMFormatExt(f_formatExt, trunc((device as unaWaveDevice).asioDriver().sampleRate), 16, 16, nCh);
	  applyDeviceFormat(pcmFormatExt, inputIsPcm);
	end;
    {$ENDIF UNA_VCACM_USE_ASIO }
      end;

    end;
  end
  else
    result := f_deviceWasCreated;
end;

// --  --
function unavclInOutWavePipe.doRead(data: pointer; len: uint): uint;
begin
  if (nil <> device) then
    result := device.read(data, len)
  else
    result := 0;
end;

// --  --
procedure unavclInOutWavePipe.doRemoveProvider(provider: unavclInOutPipe);
begin
  inherited;
  //
  if ((provider is unavclInOutWavePipe) and (nil <> unavclInOutWavePipe(provider).device)) then
    unavclInOutWavePipe(provider).device.assignStream(unaMemoryStream, false);
end;

// --  --
procedure unavclInOutWavePipe.doSetAddSilence(value: boolean);
begin
  f_addSilence := value;
end;

// --  --
procedure unavclInOutWavePipe.doSetDeviceId(value: int);
begin
  if (f_deviceId <> value) then begin
    //
    f_deviceId := value;
    //
    if (f_deviceWasCreated) then
      createDevice();	// need to re-create the device with new deviceId
  end;
end;

// --  --
procedure unavclInOutWavePipe.doSetDriver(value: unaMsAcmDriver);
begin
  if (f_driver <> value) then begin
    //
    if (f_needToUnloadDriver and (nil <> acm2)) then begin
      //
      acm2.closeDriver(f_driver);
      f_needToUnloadDriver := false;
    end;
    //
    f_driver := value;
  end;
  //
  onDriverChanged();
end;

// --  --
procedure unavclInOutWavePipe.doSetDriverLibrary(const value: wString);
begin
  f_driverLibrary := value;
end;

// --  --
procedure unavclInOutWavePipe.doSetDriverMode(value: unaAcmCodecDriverMode);
begin
  f_driverMode := value;
end;

// --  --
procedure unavclInOutWavePipe.doSetFormat(value: PWAVEFORMATEXTENSIBLE);
begin
  if (nil <> value) then begin
    //
    applyDeviceFormat(value, inputIsPcm);
    //
    if (formatIsPCM(value)) then begin
      //
      duplicateFormat(value, f_formatExt);
      //fillPCMFormatExt(f_formatEx, @value.format)
    end
    else begin
      //
      with (value.format) do begin
	//
	pcm_samplesPerSec := nSamplesPerSec;
	pcm_bitsPerSample := wBitsPerSample;
	pcm_numChannels := nChannels;
	pcm_channelMask := value.dwChannelMask;
	//
	if (WAVE_FORMAT_EXTENSIBLE <> value.Format.wFormatTag) then
	  formatTag := value.Format.wFormatTag;
      end;
    end;
  end;
end;

// --  --
procedure unavclInOutWavePipe.doSetFormatTag(value: unsigned);
begin
  if ((f_formatTag <> value) or (unacdm_acm <> driverMode)) then begin
    //
    f_formatTag := value;
    //
    if (not f_deviceWasCreated) then
      createDevice();
    //
    if (f_deviceWasCreated) then
      createDriver();
    //
    // also ensure device has proper format
    applyDeviceFormat(pcmFormatExt, inputIsPcm);
  end;
end;

// --  --
procedure unavclInOutWavePipe.doSetLoop(value: boolean);
begin
  f_loop := value;
end;

// --  --
procedure unavclInOutWavePipe.doSetSamplingParam(index: int; value: unsigned);
var
  needUpdate: bool;
  wasActive: bool;
  E: WAVEFORMATEXTENSIBLE;
begin
  if (nil = f_formatExt) then begin
    //
    E.Format.nSamplesPerSec := c_defSamplingSamplesPerSec;
    E.Format.nChannels := c_defSamplingNumChannels;
    E.Format.wBitsPerSample := c_defSamplingBitsPerSample;
    E.dwChannelMask := c_defSamplingChannelMask;
    //
    needUpdate := true
  end
  else begin
    //
    E := f_formatExt^;
    case (index) of

      0: needUpdate := (f_formatExt.format.nSamplesPerSec <> value);
      1: needUpdate := (f_formatExt.format.wBitsPerSample <> value);
      2: needUpdate := (f_formatExt.format.nChannels <> value);
      3: needUpdate := (f_formatExt.dwChannelMask <> value);

      else
	 needUpdate := false;

    end;
  end;
  //
  if (needUpdate) then begin
    //
    wasActive := active;
    close();
    //
    if ((3 = index) and (SPEAKER_DEFAULT <> value)) then
      f_pcmChannelMaskIsNotDefault := true;
    //
    fillPCMFormatExt(f_formatExt,
      choice(0 = index, value, E.format.nSamplesPerSec),
      0,
      choice(1 = index, value, E.format.wBitsPerSample),
      choice(2 = index, value, E.format.nChannels),
      choice(3 = index, value, choice(f_pcmChannelMaskIsNotDefault, E.dwChannelMask, unsigned(SPEAKER_DEFAULT)))
    );
    //
    applyDeviceFormat(pcmFormatExt, inputIsPcm);
    //
    if (wasActive) then
      open();
  end;
end;

// --  --
function unavclInOutWavePipe.doWrite(data: pointer; len: uint; provider: pointer): uint;
begin
  if (nil <> device) then begin
    //
    if (enableDataProcessing) then
      result := device.write(data, len)
    else begin
      //
      // pass through
      result := len;
      onNewData(data, result, self);
    end;
    //
{$IFDEF PACKET_DEBUG }
    if (nil = provider) then
      infoMessage(name + '.doWrite() - put new data, len=' + int2str(len) + '; provider=nil')
    else
      infoMessage(name + '.doWrite() - put new data, len=' + int2str(len) + '; provider=' + provider.name);
{$ENDIF PACKET_DEBUG }
  end
  else
    result := 0;
end;

// --  --
procedure unavclInOutWavePipe.ensureFormat();
begin
  if ((nil <> device) and (device is unaWaveDevice)) then
    unaWaveDevice(device).setSampling(pcm_samplesPerSec, pcm_bitsPerSample, pcm_numChannels);
end;

// --  --
procedure unavclInOutWavePipe.flush();
begin
  if (nil <> device) then
    device.flush();
end;

// --  --
function unavclInOutWavePipe.getAvailableDataLen(index: integer): uint;
begin
  if (nil <> device) then
    result := device.getDataAvailable(0 = index)
  else
    result := 0;
end;

// --  --
function unavclInOutWavePipe.getChunkSize(): uint;
begin
  if (nil <> device) then
    result := device.chunkSize
  else
    result := 0;
end;

// --  --
function unavclInOutWavePipe.getDstChunkSize(): uint;
begin
  result := chunkSize;	// true for all devices, except codecs
end;

// --  --
function unavclInOutWavePipe.getFormatExchangeData(out data: pointer): uint;
begin
  result := sizeOf(unaWaveFormat);	// by default allocate data for r_format only
  data := malloc(result, true, 0);
  //
  with punavclWavePipeFormatExchange(data).r_formatM do begin
    //
    formatTag := self.formatTag;
    if (nil <> f_formatExt) then begin
      //
      formatOriginal.pcmSamplesPerSecond := f_formatExt.format.nSamplesPerSec;
      formatOriginal.pcmBitsPerSample := f_formatExt.format.wBitsPerSample;
      formatOriginal.pcmNumChannels := f_formatExt.format.nChannels;
      //
      formatChannelMask := f_formatExt.dwChannelMask;
    end
    else begin
      //
      formatOriginal.pcmSamplesPerSecond := 44100;
      formatOriginal.pcmBitsPerSample := 16;
      formatOriginal.pcmNumChannels := 2;
      //
      formatChannelMask := 0;
    end;
  end;
end;

// --  --
function unavclInOutWavePipe.getLogVolume(channel: uint): unsigned;
begin
  result := unaWave.waveGetLogVolume100(getVolume(channel));
end;

// --  --
function unavclInOutWavePipe.getMinActiveTime(): unsigned;
begin
  if (nil <> device) then
    result := device.minActiveTime
  else
    result := f_minActiveTime;
end;

// --  --
function unavclInOutWavePipe.getMinVolLevel(): unsigned;
begin
  if (nil <> device) then
    result := device.minVolumeLevel
  else
    result := f_minVolume;
end;

// --  --
function unavclInOutWavePipe.getSamplingParam(index: integer): unsigned;
begin
  if (nil <> f_formatExt) then begin
    //
    case (index) of

      0: result := f_formatExt.format.nSamplesPerSec;
      1: result := f_formatExt.format.wBitsPerSample;
      2: result := f_formatExt.format.nChannels;
      3: result := f_formatExt.dwChannelMask;

      else
	 result := 0;
    end;
  end
  else begin
    //
    case (index) of

      0: result := c_defSamplingSamplesPerSec;
      1: result := c_defSamplingBitsPerSample;
      2: result := c_defSamplingNumChannels;
      3: result := c_defSamplingChannelMask;

      else
	 result := 0;
    end;
  end;
end;

function unavclInOutWavePipe.getUnVolume(channel: uint): unsigned;
begin
  if (nil <> device) then begin
    //
    if (not calcVolume) then
      calcVolume := true;
    //
    result := device.getUnVolume(channel)
  end
  else
    result := 0;
end;

// --  --
function unavclInOutWavePipe.getVolume(channel: uint): unsigned;
begin
  if (nil <> device) then begin
    //
    if (not calcVolume) then
      calcVolume := true;
    //
    result := device.getVolume(channel)
  end
  else
    result := 0;
end;

// --  --
function unavclInOutWavePipe.getWaveErrorAsString(): string;
begin
  if (nil <> device) then
    result := device.getErrorText(waveError)
  else
    result := '';
end;

// --  --
procedure unavclInOutWavePipe.initWaveParams();
begin
  f_deviceId := int(WAVE_MAPPER);
  f_realTime := false;
  f_sdo := True;
  //
  f_iNeedDriver := false;
  f_driverMode := unacdm_acm;
  f_driverLibrary := '';
  f_mapped := false;
  f_direct := false;	// True does not
  f_overNum := defOverNumValue;
  f_loop := false;
  f_inputIsPcm := true;
  f_addSilence := false;
  f_calcVolume := false;
  f_sdmCache := unasdm_none;
  //
  f_applyFormatTagImmunable := false;
  //
  f_deviceWasCreated := false;
  f_needToUnloadDriver := false;
  //
  f_needApplyFormatOnCreate := true;
end;

// --  --
function unavclInOutWavePipe.isActive(): bool;
begin
  if (nil <> device) then begin
    result := device.isOpen() and not closing;
  end
  else
    result := false;
end;

// --  --
procedure unavclInOutWavePipe.loaded();
begin
  f_loaded := true;
  //
  createDevice();
  //
  inherited;
end;

// --  --
procedure unavclInOutWavePipe.myOnDA(sender: tObject; data: pointer; len: cardinal);
begin
  if (enableDataProcessing) then
    onNewData(data, len, self);
end;

// --  --
procedure unavclInOutWavePipe.myOnGetProviderFormat(var f: PWAVEFORMATEXTENSIBLE);
begin
  if ((nil <> providerOneAndOnly) and (providerOneAndOnly is unavclInOutWavePipe)) then
    f := (providerOneAndOnly as unavclInOutWavePipe).f_formatExt
  else
    f := nil;
end;

// --  --
procedure unavclInOutWavePipe.onDriverChanged();
begin
  // nothing here
end;

// --  --
procedure unavclInOutWavePipe.setAddSilence(value: boolean);
begin
  doSetAddSilence(value);
end;

// --  --
procedure unavclInOutWavePipe.setCalcVolume(value: boolean);
begin
  f_calcVolume := value;
  //
  if (nil <> device) then
    device.calcVolume := value;
end;

// --  --
procedure unavclInOutWavePipe.setDeviceId(value: int);
begin
  doSetDeviceId(value);
end;

// --  --
procedure unavclInOutWavePipe.setDirect(value: bool);
begin
  f_direct := value;
  //
  if ((nil <> device) and (device is unaWaveDevice)) then
    (device as unaWaveDevice).direct := value;
end;

// --  --
procedure unavclInOutWavePipe.setDriver(value: unaMsAcmDriver);
begin
  doSetDriver(value);
end;

// --  --
procedure unavclInOutWavePipe.setDriverLibrary(const value: wString);
begin
  doSetdriverLibrary(value);
end;

// --  --
procedure unavclInOutWavePipe.setDriverMode(value: unaAcmCodecDriverMode);
begin
  doSetDriverMode(value);
end;

// --  --
procedure unavclInOutWavePipe.setFormat(value: PWAVEFORMATEXTENSIBLE);
begin
  doSetFormat(value);
end;

// --  --
procedure unavclInOutWavePipe.setFormatTag(value: unsigned);
begin
  doSetFormatTag(value);
end;

// --  --
procedure unavclInOutWavePipe.setInputIsPcm(value: boolean);
begin
  if (f_inputIsPcm <> value) then begin
    //
    f_inputIsPcm := value;
    //
    if (f_deviceWasCreated) then
      createDevice();	// need to re-create the device
  end;
end;

procedure unavclInOutWavePipe.setLoop(value: boolean);
begin
  doSetLoop(value);
end;

// --  --
procedure unavclInOutWavePipe.setMapped(value: bool);
begin
  f_mapped := value;
  //
  if ((nil <> device) and (device is unaWaveDevice)) then
    (device as unaWaveDevice).mapped := value;
end;

// --  --
procedure unavclInOutWavePipe.setMinActiveTime(value: unsigned);
begin
  f_minActiveTime := value;
  //
  if (nil <> device) then
    device.minActiveTime := value;
  //
  if (not calcVolume) then
    calcVolume := true;
end;

// --  --
procedure unavclInOutWavePipe.setMinVolLevel(value: unsigned);
begin
  f_minVolume := value;
  //
  if (nil <> device) then
    device.minVolumeLevel := value;
  //
  if (not calcVolume) then
    calcVolume := true;
end;

// --  --
procedure unavclInOutWavePipe.setOnThreshold(value: unaWaveOnThresholdEvent);
begin
  f_onThreshold := value;
  //
  if (nil <> device) then
    device.onThreshold := value;
end;

// --  --
procedure unavclInOutWavePipe.setOverNum(value: unsigned);
begin
  f_overNum := value;
  //
  if (nil <> device) then begin
    //
    device.overNumIn := value;
    device.overNumOut := value;
  end;
end;

// --  --
procedure unavclInOutWavePipe.setRealTime(value: boolean);
begin
  if (f_realTime <> value) then
    close();
  //
  f_realTime := value;
  //
  if (nil <> device) then
    device.realTime := value;
end;

// --  --
procedure unavclInOutWavePipe.setSamplingParam(index: integer; value: unsigned);
begin
  doSetSamplingParam(index, value);
end;

// --  --
procedure unavclInOutWavePipe.setSdm(value: unaWaveInSDMethods);
begin
  if (calcVolume and (unasdm_VC = f_sdmCache)) then
    calcVolume := (unasdm_DSP <> value)			// reset calcVolume when switching from VC to DSP
  else
    calcVolume := calcVolume or (unasdm_VC = value);	// set calcVolume when switching to VC
  //
  f_sdmCache := value;
  //
  if (nil <> device) then
    device.silenceDetectionMode := value;
end;

// --  --
procedure unavclInOutWavePipe.setChannelConsumeMask(value: int);
begin
  if (channelConsumeMask <> value) then begin
    //
    if (nil <> device) then
      device.channelConsumeMask := value;
    //
    f_channelConsumeMask := value;
  end;
end;

// --  --
procedure unavclInOutWavePipe.setChannelMixMask(value: int);
begin
  if (channelMixMask <> value) then begin
    //
    if (nil <> device) then
      device.channelMixMask := value;
    //
    f_channelMixMask := value;
  end;
end;

// --  --
procedure unavclInOutWavePipe.setWaveEngine(value: unavcWaveEngine);
begin
  if (waveEngine <> value) then begin
    //
    if ((nil <> device) and (device is unaWaveDevice)) then
      (device as unaWaveDevice).waveEngine := value;
    //
    f_waveEngine := value;
  end;
end;

// --  --
procedure unavclInOutWavePipe.shareASIOwith(pipe: unavclInOutWavePipe);
var
  sd: unaWaveDevice;
begin
  if ((nil <> device) and (device is unaWaveDevice)) then begin
    //
    if ((nil <> pipe) and (nil <> pipe.device) and (pipe.device is unaWaveDevice))  then
      sd := pipe.device as unaWaveDevice
    else
      sd := nil;
    //
    (device as unaWaveDevice).shareASIOwith(sd);
  end;
end;

// --  --
procedure unavclInOutWavePipe.setVolume100(volume: unsigned; channel: int);
begin
  if (nil <> device) then
    device.setVolume100(channel, volume);
end;


{ unavclWaveInDevice }

// --  --
procedure unavclWaveInDevice.afterConstruction();
begin
  inherited;
  //
  f_minActiveTime := 0;
  isFormatProvider := true;	// default
end;

// --  --
procedure unavclWaveInDevice.createNewDevice();
begin
  f_device := unaWaveInDevice.create(uint(deviceId), mapped, direct, overNum);
  f_device.assignStream(false, nil);
  //
  inherited;
end;

// --  --
function unavclWaveInDevice.getWaveInDevice(): unaWaveInDevice;
begin
  result := unaWaveInDevice(device);
end;


{ unavclWaveOutDevice }

// --  --
procedure unavclWaveOutDevice.afterConstruction();
begin
  inherited;
  //
  inputIsPCM := false;
  //
  playbackOptions := [unapo_smoothStartup, unapo_jitterRepeat];
end;

// --  --
procedure unavclWaveOutDevice.createNewDevice();
begin
  f_device := unaWaveOutDevice.create(uint(deviceId), mapped, direct, overNum);
  //
  inherited;
  //
  with (unaWaveOutDevice(device)) do begin
    //
    onAfterChunkFeed := myOnACF;
    onAfterChunkDone := myOnACD;
  end;
end;

type
  myWaveOutDev = class(unaWaveOutDevice)
  end;

// --  --
function unavclWaveOutDevice.doOpen: bool;
begin
  case (waveEngine) of

    unavcwe_MME: begin
      //
      unaWaveOutDevice(device).smoothStartup := (unapo_smoothStartup in playbackOptions);
      unaWaveOutDevice(device).jitterRepeat := (unapo_jitterRepeat in playbackOptions);
    end;

  end;
  //
  result := inherited doOpen();
end;

// --  --
procedure unavclWaveOutDevice.doSetEnableDP(value: boolean);
begin
  inherited;
  //
  if (not value and (nil <> getWaveOutDevice())) then
    myWaveOutDev(getWaveOutDevice()).flush2(false);
end;

// --  --
function unavclWaveOutDevice.getWaveOutDevice(): unaWaveOutDevice;
begin
  result := unaWaveOutDevice(device);
end;

// --  --
procedure unavclWaveOutDevice.myOnACD(sender: tObject; data: pointer; size: cardinal);
begin
  if (assigned(f_onFD)) then
    f_onFD(self, data, size);
end;

// --  --
procedure unavclWaveOutDevice.myOnACF(sender: tObject; data: pointer; size: cardinal);
begin
  if (assigned(f_onFC)) then
    f_onFC(self, data, size);
end;


{ unavclWaveCodecDevice }

// --  --
procedure unavclWaveCodecDevice.AfterConstruction();
begin
  inherited;
  //
  isFormatProvider := true;
end;

// --  --
function unavclWaveCodecDevice.applyDeviceFormat(format: PWAVEFORMATEXTENSIBLE; isSrc: bool): bool;
var
  desc: ppluginCodec_definition;
  rate: int;
begin
  if ((nil <> codec) and (nil <> format)) then begin
    //
    if (isSrc and not inputIsPcm) or
       (not isSrc and inputIsPcm) then
      formatTag := format.format.wFormatTag;
    //
    if (formatIsPCM(format)) then begin
      //
      result := codec.setPcmFormatSuggest(inputIsPcm, format.format.nSamplesPerSec, format.format.wBitsPerSample, format.format.nChannels, formatTag);
      if (result) then begin
	//
	if (inputIsPcm) then begin
	  //
	  if (nil <> codec.srcFormatExt) then begin
	    //
	    duplicateFormat(codec.srcFormatExt, f_formatExt);
	    //fillPCMFormatExt(f_formatEx, @codec.srcFormatEx.format);
	  end;
	end
	else begin
	  //
	  if (nil <> codec.dstFormatExt) then begin
	    //
	    duplicateFormat(codec.dstFormatExt, f_formatExt);
	    //fillPCMFormatEx(f_formatEx, @codec.dstFormatEx.format);
	  end;
	end;
	//
      end;
    end
    else
      result := setNonPCMFormat(format);
    //
    case (driverMode) of

      unacdm_openH323plugin: begin
	//
	desc := codec.oH323codecDesc[-1];
	if (nil <> desc) then
	  rate := desc.sampleRate
	else
	  rate := 8000;	// most H323 codecs works at this rate
	//
	fillPCMFormatExt(f_formatExt, rate, 0, 16, 1, KSAUDIO_SPEAKER_MONO);
      end;

    end;
  end
  else
    result := false;
  //
end;

// --  --
procedure unavclWaveCodecDevice.createNewDevice();
begin
  f_device := unaMsAcmCodec.create(driver, false, overNum, realTime, driverMode);
  //
  inherited;
  //
  codec.driverLibrary := driverLibrary;
end;

// --  --
function unavclWaveCodecDevice.getCodec(): unaMsAcmCodec;
begin
  result := unaMsAcmCodec(device);
end;

// --  --
function unavclWaveCodecDevice.getFormatExchangeData(out data: pointer): uint;
begin
  result := sizeOf(unavclWavePipeFormatExchange);	// allocate full data
  data := malloc(result, true, 0);
  //
  with punavclWavePipeFormatExchange(data).r_formatM do begin
    //
    formatTag := self.formatTag;
    formatOriginal.pcmSamplesPerSecond := f_formatExt.format.nSamplesPerSec;
    formatOriginal.pcmBitsPerSample := f_formatExt.format.wBitsPerSample;
    formatOriginal.pcmNumChannels := f_formatExt.format.nChannels;
    formatChannelMask := f_formatExt.dwChannelMask;
  end;
  //
  with (punavclWavePipeFormatExchange(data)^) do begin
    //
    punavclWavePipeFormatExchange(data).r_driverMode := ord(driverMode);
    str2arrayA(utf162utf8(extractFileName(driverLibrary)), punavclWavePipeFormatExchange(data).r_driverLib8);
  end;
end;

// --  --
procedure unavclWaveCodecDevice.initWaveParams();
begin
  inherited;
  //
  f_applyFormatTagImmunable := true;
  f_iNeedDriver := true;
end;

// --  --
procedure unavclWaveCodecDevice.doSetDriverMode(value: unaAcmCodecDriverMode);
begin
  inherited;
  //
  if (nil <> codec) then begin
    //
    codec.driverMode := value;
  end;
end;

// --  --
procedure unavclWaveCodecDevice.doSetDriverLibrary(const value: wString);
begin
  inherited;
  //
  if (nil <> codec) then begin
    //
    codec.driverLibrary := value;
  end;
end;

// --  --
procedure unavclWaveCodecDevice.onDriverChanged();
begin
  inherited;
  //
  if (nil <> codec) then begin
    //
    case (driverMode) of

      unacdm_openH323plugin: begin
	//
	codec.driverLibrary := driverLibrary;
      end;

      else begin
	//
        codec.driver := driver;
      end;

    end;
  end;
end;

// --  --
function unavclWaveCodecDevice.setNonPCMFormat(format: PWAVEFORMATEXTENSIBLE): bool;
var
  fmt: pWAVEFORMATEX;
begin
  result := false;
  //
  if (nil = device) then
    createDevice();
  //
  if ((nil <> codec) and (nil <> format)) then begin
    //
    fmt := nil;
    try
      if (waveExt2wave(format, fmt)) then begin
	//
	formatTag := fmt.wFormatTag;
	result := codec.setFormatSuggest(inputIsPcm, fmt^);
	//
	if (result) then begin
	  //
	  if (inputIsPcm) then
	    duplicateFormat(codec.srcFormatExt, f_formatExt)
	    //fillPCMFormatEx(f_formatEx, @codec.srcFormatEx.format)
	    //move(codec.srcFormat^, f_pcmFormat, sizeOf(f_pcmFormat))
	  else
	    duplicateFormat(codec.dstFormatExt, f_formatExt);
	    //fillPCMFormatEx(f_formatEx, @codec.dstFormatEx.format);
	    //move(codec.dstFormat^, f_pcmFormat, sizeOf(f_pcmFormat));
	end;
      end;
    finally
      mrealloc(fmt);
    end;
  end;
end;


{ unavclWaveRiff }

// --  --
procedure unavclWaveRiff.afterConstruction();
begin
  inherited;
  //
  f_needApplyFormatOnCreate := false;
  f_applyFormatTagImmunable := true;
  isInput := true;
  f_fileName := '';
  f_iNeedDriver := true;
  f_acod := true;
end;

// --  --
function unavclWaveRiff.applyDeviceFormat(format: PWAVEFORMATEXTENSIBLE; isSrc: bool): bool;
var
  fmt: PWAVEFORMATEX;
begin
  if (isInput) then
    // cannot change the input format
    result := false
  else begin
    //
    if ((nil <> format) and (formatIsPCM(format))) then begin
      //
      if (f_deviceWasCreated) then begin
        //
        fmt := nil;
        if (waveExt2wave(format, fmt, true)) then begin
          //
	  waveStream.assignRIFileWriteSrc(f_fileName, fmt, formatTag);	// need to re-create the WAVe device
          mrealloc(fmt);
        end;
      end;
      //
      result := true;
    end
    else
      result := false;
  end;
end;

// --  --
procedure unavclWaveRiff.createNewDevice();
var
  fmt: pWAVEFORMATEX;
begin
  // drivers must be enumerated before ACM is passed to waveRIFF
  if (g_unavclACMNeedEnum and (nil <> acm2)) then begin
    //
    acm2.enumDrivers(g_unavclACMEnumFlags);
    g_unavclACMNeedEnum := false;
  end;
  //
  if (isInput) then
    f_device := unaRiffStream.create(fileName, realTime, loop, acm2)
  else begin
    //
    fmt := nil;
    try
      if (waveExt2wave(pcmFormatExt, fmt)) then
	f_device := unaRiffStream.createNew(fileName, fmt^, formatTag, acm2);
      //	
    finally
      mrealloc(fmt);
    end;
  end;
  //
  inherited;
  //
  with (unaRiffStream(f_device)) do begin
    //
    overNumIn := overNum;
    overNumOut := overNum;
    onStreamIsDone := riffOnStreamIsDone;
  end;
end;

// --  --
procedure unavclWaveRiff.doSetLoop(value: boolean);
begin
  inherited;
  //
  if (nil <> device) then
    waveStream.loop := value;
end;

// --  --
function unavclWaveRiff.getFormatExchangeData(out data: pointer): uint;
var
  fmt: PWAVEFORMATEXTENSIBLE;
begin
  result := inherited getFormatExchangeData(data);
  //
  if (isInput) then begin
    //
    if (nil = device) then
      createDevice();
    //
    with punavclWavePipeFormatExchange(data).r_formatM do begin
      //
      case (waveStream.status) of

	0: fmt := waveStream.dstFormatExt;
	1: fmt := waveStream.srcFormatExt;
	else
	   fmt := nil;
      end;
      //
      if (nil <> fmt) then begin
	// input is OK
	formatOriginal.pcmSamplesPerSecond := fmt.format.nSamplesPerSec;
	formatOriginal.pcmBitsPerSample := fmt.format.wBitsPerSample;
	formatOriginal.pcmNumChannels := fmt.format.nChannels;
	formatChannelMask := fmt.dwChannelMask;
	//
	// also update the internal format, so properties will correspond to file parameters
	duplicateFormat(fmt, f_formatExt);
      end;
    end;
    //
  end;
end;

// --  --
function unavclWaveRiff.getRiff(): unaRiffStream;
begin
  result := unaRiffStream(device);
end;

// --  --
function unavclWaveRiff.loadFromFile(const fileName: wString; asynchronous: bool): bool;
begin
  result := true;
  //
  realTime := false;
  self.fileName := fileName;
  isInput := true;
  //
  open();
  //
  if (not asynchronous) then begin
    //
    while (not waveStream.streamIsDone) do
      Sleep(50);
    //
    close();
  end;
end;

// --  --
function unavclWaveRiff.loadFromStream(stream: tStream; asynchronous: bool): bool;
begin
  f_tmpToKill := getTemporaryFileName();
  with (tFileStream.create(f_tmpToKill, 0)) do begin
    //
    CopyFrom(stream, stream.Size);
    Free();
  end;
  //
  result := loadFromFile(f_tmpToKill, asynchronous);
end;

// --  --
procedure unavclWaveRiff.riffOnStreamIsDone(sender: tObject);
begin
  if (assigned(f_onStreamIsDone)) then
    f_onStreamIsDone(self);
  //
  if (f_acod) then
    close();
  //
  if ('' <> f_tmpToKill) then begin
    //
    fileDelete(f_tmpToKill);
    f_tmpToKill := '';
  end;
end;

// --  --
function unavclWaveRiff.saveToFile(const fileName: wString; data: pointer; size: uint; asynchronous: bool): bool;
begin
  if ((nil <> data) and (0 < size)) then begin
    //
    realTime := false;
    self.fileName := fileName;
    isInput := false;
    //
    open();
    write(data, size);
    //
    if (not asynchronous) then begin
      //
      while (waveStream.getDataAvailable(true) > chunkSize) do
	Sleep(100);
      //
      close();
    end;
    //
    result := true;
  end
  else
    result := false;
end;

// --  --
procedure unavclWaveRiff.setFileName(const value: wString);
var
  fmt: pWAVEFORMATEX;
  fEx: PWAVEFORMATEXTENSIBLE;
begin
  f_fileName := value;
  //
  if (nil <> device) then begin
    //
    if (isInput) then begin
      //
      // re-assign new input file
      waveStream.assignRIFile(value);
      //
      // 14-SEP-2010: update pcm_XXX properties
      //
      if (0 = waveStream.status) then begin
	//
	// 03-jun-2012: changed to dstFormatExt
	if (nil <> waveStream.dstFormatExt) then
	  fEx := waveStream.dstFormatExt
	else
	  fEx := waveStream.srcFormatExt;
	//
	pcm_samplesPerSec := fEx.Format.nSamplesPerSec;
	pcm_bitsPerSample := fEx.Format.wBitsPerSample;
	pcm_numChannels := fEx.Format.nChannels;
	//
	case (waveStream.fileType) of

	  c_unaRiffFileType_riff: formatTag := WAVE_FORMAT_PCM;
{$IFNDEF VC_LIC_PUBLIC }
	  c_unaRiffFileType_mpeg: formatTag := WAVE_FORMAT_MPEGLAYER3;
{$ENDIF VC_LIC_PUBLIC }

	end;
      end;
      // 14-SEP-2010: //
    end
    else begin
      //
      // re-create with new output file
      fmt := nil;
      try
	if (waveExt2wave(pcmFormatExt, fmt)) then
	  waveStream.assignRIFileWriteSrc(value, fmt, formatTag);
      finally
	mrealloc(fmt);
      end;
    end;
  end;
end;

// --  --
procedure unavclWaveRiff.setIsInput(value: boolean);
begin
  if (f_isInput <> value) then begin
    //
    if (not active) then begin
      //
      f_isInput := value;
      f_deviceWasCreated := false	// need to re-create the device
    end;
  end;
end;


{ unavclWaveMixer }

// --  --
procedure unavclWaveMixer.afterConstruction();
begin
  inherited;
  //
  //f_providerStreams := unaObjectList.create(false);
end;

// --  --
procedure unavclWaveMixer.beforeDestruction();
begin
  inherited;
  //
  //freeAndNil(f_providerStreams);
end;

// --  --
procedure unavclWaveMixer.createNewDevice();
var
  i: int;
begin
  f_device := unaWaveMixerDevice.create(realTime, addSilence, overNum);
  //
  inherited;
  //
  if (lockNonEmptyList_r(_providers, true, 1000 {$IFDEF DEBUG }, '.createNewDevice()'{$ENDIF DEBUG })) then begin
    try
      i := 0;
      while (i < _providers.count) do begin
	//
	setStream(_providers[i], mixer.addStream());
	//
	inc(i);
      end;
    finally
      unlockListRO(_providers);
    end;
  end;
end;

// --  --
function unavclWaveMixer.doAddProvider(provider: unavclInOutPipe): bool;
begin
  result := inherited doAddProvider(provider);
  //
  if (result and (nil <> mixer)) then
    setStream(provider, mixer.addStream(nil{, false}));
end;

// --  --
procedure unavclWaveMixer.doRemoveProvider(provider: unavclInOutPipe);
var
  stream: unaAbstractStream;
begin
  if ((nil <> provider) and (nil <> mixer)) then begin
    //
    stream := getStream(provider);
    mixer.removeStream(stream{, false});
    setStream(provider, nil);
  end;
  //
  inherited;
end;

// --  --
function unavclWaveMixer.doWrite(data: pointer; len: uint; provider: pointer): uint;
var
  stream: unaAbstractStream;
begin
  stream := getStream(provider);
  if (nil <> stream) then begin
    //
    if ((0 < overNum) and (nil <> device) and (stream.getAvailableSize() > int(overNum * device.chunkSize))) then
      // stream overload
      result := 0
    else
      result := stream.write(data, len)
  end
  else
    result := 0;
end;

// --  --
function unavclWaveMixer.getMixer(): unaWaveMixerDevice;
begin
  result := unaWaveMixerDevice(device);
end;

// --  --
function unavclWaveMixer.getStream(provider: unavclInOutPipe): unaAbstractStream;
var
  i: int;
begin
  if (nil <> _providers) then
    i := _providers.indexOf(provider)
  else
    i := -1;
  //
  if (0 <= i) then
    result := mixer.getStream(i)
  else
    result := nil;
end;

// --  --
procedure unavclWaveMixer.doSetAddSilence(value: boolean);
begin
  inherited;
  //
  if (nil <> device) then
    mixer.addSilence := value;
end;

// --  --
procedure unavclWaveMixer.setStream(provider: unavclInOutPipe; stream: unaAbstractStream);
begin
  {if (nil = stream) then
    // remove stream
    f_providerStreams.removeItem(getStream(provider))
  else
    // add stream
    f_providerStreams.add(stream);
  }  
end;


{ unavclWaveResampler }

// --  --
procedure unavclWaveResampler.afterConstruction();
begin
  fillPCMFormatExt(f_dstFormatExt);
  //
  inherited;
  //
  dst_SamplesPerSec := c_defSamplingSamplesPerSec;
  dst_BitsPerSample := c_defSamplingBitsPerSample;
  dst_NumChannels := c_defSamplingNumChannels;
  //
  f_uspeexdsp := false;
end;

// --  --
function unavclWaveResampler.applyDeviceFormat(format: PWAVEFORMATEXTENSIBLE; isSrc: bool): bool;
begin
  if ((nil <> device) and (nil <> format)) then begin
    //
    result := resampler.setSampling(isSrc, format.format);
    resampler.useSpeexDSP := useSpeexDSP;
  end
  else
    result := false;
end;

// --  --
procedure unavclWaveResampler.BeforeDestruction();
begin
  inherited;
  //
  mrealloc(f_dstFormatExt);
end;

// --  --
procedure unavclWaveResampler.createNewDevice();
begin
  f_device := unaWaveResampler.create(realTime, overNum);
  //
  inherited;
  //
  applyDeviceFormat(f_dstFormatExt, false);
end;

// --  --
function unavclWaveResampler.getDstSamplingParam(index: integer): unsigned;
begin
  if (nil <> resampler) then
    // ensure we are in synch with resampler format
    duplicateFormat(resampler.dstFormatExt, f_dstFormatExt);
  //
  if (nil = f_dstFormatExt) then
    fillPCMFormatExt(f_dstFormatExt, pcm_samplesPerSec, pcm_bitsPerSample, pcm_bitsPerSample, pcm_numChannels);
  //
  case (index) of

    0: result := f_dstFormatExt.format.nSamplesPerSec;
    1: result := f_dstFormatExt.format.wBitsPerSample;
    2: result := f_dstFormatExt.format.nChannels;
    3: result := f_dstFormatExt.dwChannelMask;

    else
       result := 0;
  end;
end;

// --  --
function unavclWaveResampler.getFormatExchangeData(out data: pointer): uint;
begin
  result := inherited getFormatExchangeData(data);
  //
  with punavclWavePipeFormatExchange(data).r_formatM do begin
    //
    formatOriginal.pcmSamplesPerSecond := f_dstFormatExt.format.nSamplesPerSec;
    formatOriginal.pcmBitsPerSample := f_dstFormatExt.format.wBitsPerSample;
    formatOriginal.pcmNumChannels := f_dstFormatExt.format.nChannels;
    formatChannelMask := f_dstFormatExt.dwChannelMask;
  end;
end;

// --  --
function unavclWaveResampler.getResampler(): unaWaveResampler;
begin
  result := unaWaveResampler(device);
end;

// --  --
procedure unavclWaveResampler.setDstFormat(value: PWAVEFORMATEXTENSIBLE);
begin
  applyDeviceFormat(value, false);
  //
  if (nil <> value) then
    duplicateFormat(value, f_dstFormatExt);
end;

// --  --
procedure unavclWaveResampler.setDstSamplingParam(index: integer; value: unsigned);
begin
  case (index) of

    0: f_dstFormatExt.format.nSamplesPerSec := value;
    1: f_dstFormatExt.format.wBitsPerSample := value;
    2: f_dstFormatExt.format.nChannels := value;
    3: f_dstFormatExt.dwChannelMask := value;

  end;
  //
  applyDeviceFormat(dstFormatExt, false);
end;

// --  --
procedure unavclWaveResampler.setUspeexdsp(value: boolean);
begin
  f_uspeexdsp := value;
  //
  if (nil <> resampler) then
    resampler.useSpeexDSP := value;
end;




initialization

{$IFDEF LOG_UNAVC_WAVE_INFOS }
  logMessage('unaVC_wave - DEBUG is defined.');
{$ENDIF LOG_UNAVC_WAVE_INFOS }

// --  --
finalization
  // release global objects
  freeAndNil(g_unavclACM);
  
end.

