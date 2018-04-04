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
	  unaBassAPI.pas
	  API for Bass library
	----------------------------------------------

	  This source is based on original bass.pas unit
	  from BASS 1.7 - 2.3 installations

	  BASS 1.7 - 2.3 Multimedia Library interface
	  -----------------------------
	  (c) 1999-2006 Ian Luck.

	  Additional Delphi source code:

	  Copyright (c) 2003-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/

	----------------------------------------------

	  created by:
		Lake, 07 Jan 2003

	  modified by:
		Lake, Jan-Dec 2003
		Lake, March 2005
		Lake, Apr 2007

	----------------------------------------------
*)

{$I unaDef.inc }
{$I unaBassDef.inc }

{*
  BASS.DLL wrapper.

  @Author Lake
  
Version 2.5.2008.07 Still here
}

unit
  unaBassAPI;

interface

uses
  Windows, unaTypes;

//---- bass.pas --

const
  BASSVERSION = $203;             // API version
  BASSVERSIONTEXT = '2.4';

  // Use these to test for error from functions that return a DWORD or QWORD
  DW_ERROR = LongWord(-1); // -1 (DWORD)
  QW_ERROR = Int64(-1);    // -1 (QWORD)

  // Error codes returned by BASS_GetErrorCode()
  BASS_OK                 = 0;    // all is OK
  BASS_ERROR_MEM          = 1;    // memory error
  BASS_ERROR_FILEOPEN     = 2;    // can't open the file
  BASS_ERROR_DRIVER       = 3;    // can't find a free sound driver
  BASS_ERROR_BUFLOST      = 4;    // the sample buffer was lost - please report this!
  BASS_ERROR_HANDLE       = 5;    // invalid handle
  BASS_ERROR_FORMAT       = 6;    // unsupported format
  BASS_ERROR_POSITION     = 7;    // invalid playback position
  BASS_ERROR_INIT         = 8;    // BASS_Init has not been successfully called
  BASS_ERROR_START        = 9;    // BASS_Start has not been successfully called
  BASS_ERROR_INITCD       = 10;   // can't initialize CD
  BASS_ERROR_CDINIT       = 11;   // BASS_CDInit has not been successfully called
  BASS_ERROR_NOCD         = 12;   // no CD in drive
  BASS_ERROR_CDTRACK      = 13;   // can't play the selected CD track
  BASS_ERROR_ALREADY      = 14;   // already initialized
  BASS_ERROR_CDVOL        = 15;   // CD has no volume control
  BASS_ERROR_NOPAUSE      = 16;   // not paused
  BASS_ERROR_NOTAUDIO     = 17;   // not an audio track
  BASS_ERROR_NOCHAN       = 18;   // can't get a free channel
  BASS_ERROR_ILLTYPE      = 19;   // an illegal type was specified
  BASS_ERROR_ILLPARAM     = 20;   // an illegal parameter was specified
  BASS_ERROR_NO3D         = 21;   // no 3D support
  BASS_ERROR_NOEAX        = 22;   // no EAX support
  BASS_ERROR_DEVICE       = 23;   // illegal device number
  BASS_ERROR_NOPLAY       = 24;   // not playing
  BASS_ERROR_FREQ         = 25;   // illegal sample rate
  BASS_ERROR_NOA3D        = 26;   // A3D.DLL is not installed
  BASS_ERROR_NOTFILE      = 27;   // the stream is not a file stream (WAV/MP3/MP2/MP1/OGG)
  BASS_ERROR_NOHW         = 29;   // no hardware voices available
  BASS_ERROR_EMPTY        = 31;	  // the MOD music has no sequence data
  BASS_ERROR_NONET        = 32;	  // no internet connection could be opened
  BASS_ERROR_CREATE       = 33;   // couldn't create the file
  BASS_ERROR_NOFX         = 34;   // effects are not enabled
  BASS_ERROR_PLAYING      = 35;   // the channel is playing
  BASS_ERROR_NOTAVAIL     = 37;   // requested data is not available
  BASS_ERROR_DECODE       = 38;   // the channel is a "decoding channel"
  BASS_ERROR_DX           = 39;   // a sufficient DirectX version is not installed
  BASS_ERROR_TIMEOUT      = 40;   // connection timedout
  // v2.0
  BASS_ERROR_FILEFORM     = 41;   // unsupported file format
  // v2.0
  BASS_ERROR_SPEAKER      = 42;   // unavailable speaker
  // v2.3
  BASS_ERROR_VERSION      = 43;   // invalid BASS version (used by add-ons)
  BASS_ERROR_CODEC        = 44;   // codec is not available/supported
  // v2.4
  BASS_ERROR_ENDED        = 45;   // the channel/file has ended
  //
  BASS_ERROR_UNKNOWN      = -1;   // some other mystery error

  // Device setup flags
  BASS_DEVICE_8BITS       = 1;    // use 8 bit resolution, else 16 bit
  BASS_DEVICE_MONO        = 2;    // use mono, else stereo
  BASS_DEVICE_3D          = 4;    // enable 3D functionality
  {
    If the BASS_DEVICE_3D flag is not specified when
    initilizing BASS, then the 3D flags (BASS_SAMPLE_3D
    and BASS_MUSIC_3D) are ignored when loading/creating
    a sample/stream/music.
  }
  BASS_DEVICE_LEAVEVOL	  = 32;	  // leave the volume as it is
  BASS_DEVICE_NOTHREAD    = 128;  // update buffers manually (using BASS_Update)
  BASS_DEVICE_LATENCY     = 256;  // calculate device latency (BASS_INFO struct)
  BASS_DEVICE_VOL1000     = 512;  // 0-1000 volume range (else 0-100)
  // v2.0
  BASS_DEVICE_SPEAKERS    = 2048; // force enabling of speaker assignment
  // v2.3
  BASS_DEVICE_NOSPEAKER   = 4096; // ignore speaker arrangement

  // DirectSound interfaces (for use with BASS_GetDSoundObject)
  BASS_OBJECT_DS          = 1;   // IDirectSound
  BASS_OBJECT_DS3DL       = 2;   // IDirectSound3DListener

  // BASS_INFO flags (from DSOUND.H)
  DSCAPS_CONTINUOUSRATE   = $00000010;
  { supports all sample rates between min/maxrate }
  DSCAPS_EMULDRIVER       = $00000020;
  { device does NOT have hardware DirectSound support }
  DSCAPS_CERTIFIED        = $00000040;
  { device driver has been certified by Microsoft }
  {
    The following flags tell what type of samples are
    supported by HARDWARE mixing, all these formats are
    supported by SOFTWARE mixing
  }
  DSCAPS_SECONDARYMONO    = $00000100;     // mono
  DSCAPS_SECONDARYSTEREO  = $00000200;     // stereo
  DSCAPS_SECONDARY8BIT    = $00000400;     // 8 bit
  DSCAPS_SECONDARY16BIT   = $00000800;     // 16 bit

  // BASS_RECORDINFO flags (from DSOUND.H)
  DSCCAPS_EMULDRIVER = DSCAPS_EMULDRIVER;
  { device does NOT have hardware DirectSound recording support }
  DSCCAPS_CERTIFIED = DSCAPS_CERTIFIED;
  { device driver has been certified by Microsoft }

  // defines for formats field of BASS_RECORDINFO (from MMSYSTEM.H)
  WAVE_FORMAT_1M08_       = $00000001;      // 11.025 kHz, Mono,   8-bit
  WAVE_FORMAT_1S08_       = $00000002;      // 11.025 kHz, Stereo, 8-bit
  WAVE_FORMAT_1M16_       = $00000004;      // 11.025 kHz, Mono,   16-bit
  WAVE_FORMAT_1S16_       = $00000008;      // 11.025 kHz, Stereo, 16-bit
  WAVE_FORMAT_2M08_       = $00000010;      // 22.05  kHz, Mono,   8-bit
  WAVE_FORMAT_2S08_       = $00000020;      // 22.05  kHz, Stereo, 8-bit
  WAVE_FORMAT_2M16_       = $00000040;      // 22.05  kHz, Mono,   16-bit
  WAVE_FORMAT_2S16_       = $00000080;      // 22.05  kHz, Stereo, 16-bit
  WAVE_FORMAT_4M08_       = $00000100;      // 44.1   kHz, Mono,   8-bit
  WAVE_FORMAT_4S08_       = $00000200;      // 44.1   kHz, Stereo, 8-bit
  WAVE_FORMAT_4M16_       = $00000400;      // 44.1   kHz, Mono,   16-bit
  WAVE_FORMAT_4S16_       = $00000800;      // 44.1   kHz, Stereo, 16-bit

  // Sample info flags
  BASS_SAMPLE_8BITS       = 1;   // 8 bit, else 16 bit
  BASS_SAMPLE_MONO        = 2;   // mono, else stereo
  BASS_SAMPLE_LOOP        = 4;   // looped
  BASS_SAMPLE_3D          = 8;   // 3D functionality enabled
  BASS_SAMPLE_SOFTWARE    = 16;  // it's NOT using hardware mixing
  BASS_SAMPLE_MUTEMAX     = 32;  // muted at max distance (3D only)
  BASS_SAMPLE_VAM         = 64;  // uses the DX7 voice allocation & management
  BASS_SAMPLE_FX          = 128;     // old implementation of DX8 effects are enabled
  // v2.0
  BASS_SAMPLE_FLOAT       = 256; // 32-bit floating-point
  //
  BASS_SAMPLE_OVER_VOL    = $10000; // override lowest volume
  BASS_SAMPLE_OVER_POS    = $20000; // override longest playing
  BASS_SAMPLE_OVER_DIST   = $30000; // override furthest from listener (3D only)

  BASS_MP3_HALFRATE       = $10000; // reduced quality MP3/MP2/MP1 (half sample rate)
{$IFDEF BASS_AFTER_21 }
  BASS_STREAM_PRESCAN     = $20000; // enable pin-point seeking (MP3/MP2/MP1)
  BASS_MP3_SETPOS         = BASS_STREAM_PRESCAN;
{$ELSE }
  BASS_MP3_SETPOS         = $20000; // enable pin-point seeking on the MP3/MP2/MP1/OGG
{$ENDIF }
  BASS_STREAM_AUTOFREE	  = $40000;// automatically free the stream when it stop/ends
  BASS_STREAM_RESTRATE	  = $80000;// restrict the download rate of internet file streams
  BASS_STREAM_BLOCK       = $100000;// download & play internet
				    // file stream (MPx/OGG) in small blocks
  BASS_STREAM_DECODE      = $200000;// don't play the stream, only decode (BASS_ChannelGetData)
  BASS_STREAM_META        = $400000;// request metadata from a Shoutcast stream
{$IFDEF BASS_AFTER_18 }
  BASS_STREAM_STATUS      = $800000;// give server status info (HTTP/ICY tags) in DOWNLOADPROC
{$ELSE }
  BASS_STREAM_FILEPROC    = $800000;// use a STREAMFILEPROC callback
{$ENDIF }


  {
    Ramping doesn't take a lot of extra processing and
    improves the sound quality by removing "clicks".
    Sensitive ramping will leave sharp attacked samples,
    unlike normal ramping.
  }
{$IFDEF BASS_AFTER_18 }
  // constants fucked up by 2.0
  BASS_MUSIC_FLOAT        = BASS_SAMPLE_FLOAT; // 32-bit floating-point
  BASS_MUSIC_MONO         = BASS_SAMPLE_MONO; // force mono mixing (less CPU usage)
  BASS_MUSIC_LOOP         = BASS_SAMPLE_LOOP;   // loop music
  //
  BASS_MUSIC_3D           = BASS_SAMPLE_3D; // enable 3D functionality
  BASS_MUSIC_FX           = BASS_SAMPLE_FX; // enable old implementation of DX8 effects
  BASS_MUSIC_AUTOFREE     = BASS_STREAM_AUTOFREE; // automatically free the music when it stop/ends
  BASS_MUSIC_DECODE       = BASS_STREAM_DECODE; // don't play the music, only decode (BASS_ChannelGetData)
  //
{$IFDEF BASS_AFTER_21 }
  // fucked in 2.2
  BASS_MUSIC_PRESCAN      = BASS_STREAM_PRESCAN; // calculate playback length
  BASS_MUSIC_CALCLEN      = BASS_MUSIC_PRESCAN;
{$ELSE }
  BASS_MUSIC_CALCLEN      = $8000; // calculate playback length
{$ENDIF }
  BASS_MUSIC_RAMP         = $200;  // normal ramping
  BASS_MUSIC_RAMPS        = $400;  // sensitive ramping
  BASS_MUSIC_SURROUND     = $800;  // surround sound
  BASS_MUSIC_SURROUND2    = $1000; // surround sound (mode 2)
  BASS_MUSIC_FT2MOD       = $2000; // play .MOD as FastTracker 2 does
  BASS_MUSIC_PT1MOD       = $4000; // play .MOD as ProTracker 1 does
  BASS_MUSIC_NONINTER     = $10000; // non-interpolated mixing
  BASS_MUSIC_POSRESET     = $20000; // stop all notes when moving position
  BASS_MUSIC_POSRESETEX   = $400000; // stop all notes and reset bmp/etc when moving position
  BASS_MUSIC_STOPBACK     = $80000; // stop the music on a backwards jump effect
  BASS_MUSIC_NOSAMPLE     = $100000; // don't load the samples
{$ELSE }
  // Music flags
  BASS_MUSIC_LOOP	  = BASS_SAMPLE_LOOP;   // loop music
  BASS_MUSIC_RAMP         = 1;   // normal ramping
  BASS_MUSIC_RAMPS        = 2;   // sensitive ramping
  BASS_MUSIC_FT2MOD       = 16;  // play .MOD as FastTracker 2 does
  BASS_MUSIC_PT1MOD       = 32;  // play .MOD as ProTracker 1 does
  BASS_MUSIC_MONO         = 64;  // force mono mixing (less CPU usage)
  BASS_MUSIC_3D           = 128; // enable 3D functionality
  BASS_MUSIC_POSRESET     = 256; // stop all notes when moving position
  BASS_MUSIC_SURROUND	  = 512; // surround sound
  BASS_MUSIC_SURROUND2	  = 1024;// surround sound (mode 2)
  BASS_MUSIC_STOPBACK	  = 2048;// stop the music on a backwards jump effect
  BASS_MUSIC_FX           = 4096;// enable old implementation of DX8 effects
  BASS_MUSIC_CALCLEN      = 8192;// calculate playback length
  BASS_MUSIC_DECODE       = BASS_STREAM_DECODE;// don't play the music, only decode (BASS_ChannelGetData)
  BASS_MUSIC_NOSAMPLE     = $400000;// don't load the samples
{$ENDIF }

  // 2.0: Speaker assignment flags
  BASS_SPEAKER_FRONT      = $1000000;  // front speakers
  BASS_SPEAKER_REAR       = $2000000;  // rear/side speakers
  BASS_SPEAKER_CENLFE     = $3000000;  // center & LFE speakers (5.1)
  BASS_SPEAKER_REAR2      = $4000000;  // rear center speakers (7.1)
  BASS_SPEAKER_LEFT       = $10000000; // modifier: left
  BASS_SPEAKER_RIGHT      = $20000000; // modifier: right
  BASS_SPEAKER_FRONTLEFT  = BASS_SPEAKER_FRONT or BASS_SPEAKER_LEFT;
  BASS_SPEAKER_FRONTRIGHT = BASS_SPEAKER_FRONT or BASS_SPEAKER_RIGHT;
  BASS_SPEAKER_REARLEFT   = BASS_SPEAKER_REAR or BASS_SPEAKER_LEFT;
  BASS_SPEAKER_REARRIGHT  = BASS_SPEAKER_REAR or BASS_SPEAKER_RIGHT;
  BASS_SPEAKER_CENTER     = BASS_SPEAKER_CENLFE or BASS_SPEAKER_LEFT;
  BASS_SPEAKER_LFE        = BASS_SPEAKER_CENLFE or BASS_SPEAKER_RIGHT;
  BASS_SPEAKER_REAR2LEFT  = BASS_SPEAKER_REAR2 or BASS_SPEAKER_LEFT;
  BASS_SPEAKER_REAR2RIGHT = BASS_SPEAKER_REAR2 or BASS_SPEAKER_RIGHT;

  // v2.0
  BASS_UNICODE            = $80000000;

  // v2.0
  BASS_RECORD_PAUSE       = $8000; // start recording paused

  // DX7 voice allocation flags
  BASS_VAM_HARDWARE       = 1;
  {
    Play the sample in hardware. If no hardware voices are available then
    the "play" call will fail
  }
  BASS_VAM_SOFTWARE       = 2;
  {
    Play the sample in software (ie. non-accelerated). No other VAM flags
    may be used together with this flag.
  }

  // DX7 voice management flags
  {
    These flags enable hardware resource stealing... if the hardware has no
    available voices, a currently playing buffer will be stopped to make room
    for the new buffer. NOTE: only samples loaded/created with the
    BASS_SAMPLE_VAM flag are considered for termination by the DX7 voice
    management.
  }
  BASS_VAM_TERM_TIME      = 4;
  {
    If there are no free hardware voices, the buffer to be terminated will be
    the one with the least time left to play.
  }
  BASS_VAM_TERM_DIST      = 8;
  {
    If there are no free hardware voices, the buffer to be terminated will be
    one that was loaded/created with the BASS_SAMPLE_MUTEMAX flag and is
    beyond
    it's max distance. If there are no buffers that match this criteria, then
    the "play" call will fail.
  }
  BASS_VAM_TERM_PRIO      = 16;
  {
    If there are no free hardware voices, the buffer to be terminated will be
    the one with the lowest priority.
  }

  // 2.0: BASS_CHANNELINFO types
  BASS_CTYPE_SAMPLE       = 1;
  BASS_CTYPE_RECORD       = 2;
  BASS_CTYPE_STREAM       = $10000;
  BASS_CTYPE_STREAM_OGG   = $10002;
  BASS_CTYPE_STREAM_MP1   = $10003;
  BASS_CTYPE_STREAM_MP2   = $10004;
  BASS_CTYPE_STREAM_MP3   = $10005;
  //
  BASS_CTYPE_STREAM_AIFF  = $10006;
  //
  BASS_CTYPE_MUSIC_MOD    = $20000;
  BASS_CTYPE_MUSIC_MTM    = $20001;
  BASS_CTYPE_MUSIC_S3M    = $20002;
  BASS_CTYPE_MUSIC_XM     = $20003;
  BASS_CTYPE_MUSIC_IT     = $20004;
  BASS_CTYPE_MUSIC_MO3    = $00100; // mo3 flag

{$IFDEF BASS_AFTER_22 }
  // fucked in 2.3 (or earlier?)
  BASS_CTYPE_STREAM_WAV   = $40000; // WAVE flag, LOWORD=codec
  BASS_CTYPE_STREAM_WAV_PCM = $50001;
  BASS_CTYPE_STREAM_WAV_FLOAT = $50003;
{$ELSE }
  BASS_CTYPE_STREAM_WAV   = $10001;
{$ENDIF }  


  // 3D channel modes
  BASS_3DMODE_NORMAL      = 0;
  { normal 3D processing }
  BASS_3DMODE_RELATIVE    = 1;
  {
    The channel's 3D position (position/velocity/
    orientation) are relative to the listener. When the
    listener's position/velocity/orientation is changed
    with BASS_Set3DPosition, the channel's position
    relative to the listener does not change.
  }
  BASS_3DMODE_OFF         = 2;
  {
    Turn off 3D processing on the channel, the sound will
    be played in the center.
  }

  // EAX environments, use with BASS_SetEAXParameters
  EAX_ENVIRONMENT_OFF               = -1;
  EAX_ENVIRONMENT_GENERIC           = 0;
  EAX_ENVIRONMENT_PADDEDCELL        = 1;
  EAX_ENVIRONMENT_ROOM              = 2;
  EAX_ENVIRONMENT_BATHROOM          = 3;
  EAX_ENVIRONMENT_LIVINGROOM        = 4;
  EAX_ENVIRONMENT_STONEROOM         = 5;
  EAX_ENVIRONMENT_AUDITORIUM        = 6;
  EAX_ENVIRONMENT_CONCERTHALL       = 7;
  EAX_ENVIRONMENT_CAVE              = 8;
  EAX_ENVIRONMENT_ARENA             = 9;
  EAX_ENVIRONMENT_HANGAR            = 10;
  EAX_ENVIRONMENT_CARPETEDHALLWAY   = 11;
  EAX_ENVIRONMENT_HALLWAY           = 12;
  EAX_ENVIRONMENT_STONECORRIDOR     = 13;
  EAX_ENVIRONMENT_ALLEY             = 14;
  EAX_ENVIRONMENT_FOREST            = 15;
  EAX_ENVIRONMENT_CITY              = 16;
  EAX_ENVIRONMENT_MOUNTAINS         = 17;
  EAX_ENVIRONMENT_QUARRY            = 18;
  EAX_ENVIRONMENT_PLAIN             = 19;
  EAX_ENVIRONMENT_PARKINGLOT        = 20;
  EAX_ENVIRONMENT_SEWERPIPE         = 21;
  EAX_ENVIRONMENT_UNDERWATER        = 22;
  EAX_ENVIRONMENT_DRUGGED           = 23;
  EAX_ENVIRONMENT_DIZZY             = 24;
  EAX_ENVIRONMENT_PSYCHOTIC         = 25;
  // total number of environments
  EAX_ENVIRONMENT_COUNT             = 26;

  // software 3D mixing algorithm modes (used with BASS_Set3DAlgorithm)
  BASS_3DALG_DEFAULT                = 0;
  {
    default algorithm (currently translates to BASS_3DALG_OFF)
  }
  BASS_3DALG_OFF                    = 1;
  {
    Uses normal left and right panning. The vertical axis is ignored except
    for scaling of volume due to distance. Doppler shift and volume scaling
    are still applied, but the 3D filtering is not performed. This is the
    most CPU efficient software implementation, but provides no virtual 3D
    audio effect. Head Related Transfer Function processing will not be done.
    Since only normal stereo panning is used, a channel using this algorithm
    may be accelerated by a 2D hardware voice if no free 3D hardware voices
    are available.
  }
  BASS_3DALG_FULL                   = 2;
  {
    This algorithm gives the highest quality 3D audio effect, but uses more
    CPU. Requires Windows 98 2nd Edition or Windows 2000 that uses WDM
    drivers, if this mode is not available then BASS_3DALG_OFF will be used
    instead.
  }
  BASS_3DALG_LIGHT                  = 3;
  {
    This algorithm gives a good 3D audio effect, and uses less CPU than the
    FULL mode. Requires Windows 98 2nd Edition or Windows 2000 that uses WDM
    drivers, if this mode is not available then BASS_3DALG_OFF will be used
    instead.
  }

  {
    Sync types (with BASS_ChannelSetSync() "param" and
    SYNCPROC "data" definitions) & flags.
  }
  BASS_SYNC_POS                     = 0;
  BASS_SYNC_MUSICPOS                = 0;
  {
    Sync when a music or stream reaches a position.
    if HMUSIC...
    param: LOWORD=order (0=first, -1=all) HIWORD=row (0=first, -1=all)
    data : LOWORD=order HIWORD=row
    if HSTREAM...
    param: position in bytes
    data : not used
  }
  BASS_SYNC_MUSICINST               = 1;
  {
    Sync when an instrument (sample for the non-instrument
    based formats) is played in a music (not including
    retrigs).
    param: LOWORD=instrument (1=first) HIWORD=note (0=c0...119=b9, -1=all)
    data : LOWORD=note HIWORD=volume (0-64)
  }
  BASS_SYNC_END                     = 2;
  {
    Sync when a music or file stream reaches the end.
    param: not used
    data : not used
  }
  BASS_SYNC_MUSICFX                 = 3;
  {
    Sync when the "sync" effect (XM/MTM/MOD: E8x/Wxx, IT/S3M: S2x) is used.
    param: 0:data=pos, 1:data="x" value
    data : param=0: LOWORD=order HIWORD=row, param=1: "x" value
  }
  BASS_SYNC_META                    = 4;
  {
    Sync when metadata is received in a Shoutcast stream.
    param: not used
    data : pointer to the metadata
  }
  BASS_SYNC_SLIDE                   = 5;
  {
    Sync when an attribute slide is completed.
    param: not used
    data : the type of slide completed (one of the BASS_SLIDE_xxx values)
  }
  // v2.0
  BASS_SYNC_STALL                   = 6;
  {
    Sync when playback has stalled.
    param: not used
    data : 0=stalled, 1=resumed
  }
  // v2.0
  BASS_SYNC_DOWNLOAD                = 7;
  {
    Sync when downloading of an internet (or "buffered" user file) stream has ended.
    param: not used
    data : not used
  }
  BASS_SYNC_MESSAGE                 = $20000000;
  { FLAG: post a Windows message (instead of callback)
    When using a window message "callback", the message to post is given in the "proc"
    parameter of BASS_ChannelSetSync, and is posted to the window specified in the BASS_Init
    call. The message parameters are: WPARAM = data, LPARAM = user.
  }
  BASS_SYNC_MIXTIME                 = $40000000;
  { FLAG: sync at mixtime, else at playtime }
  BASS_SYNC_ONETIME                 = $80000000;
  { FLAG: sync only once, else continuously }

  // old ones
  CDCHANNEL           = 0; // CD channel, for use with BASS_Channel functions
  RECORDCHAN          = 1; // Recording channel, for use with BASS_Channel functions

  // BASS_ChannelIsActive return values
  BASS_ACTIVE_STOPPED = 0;
  BASS_ACTIVE_PLAYING = 1;
  BASS_ACTIVE_STALLED = 2;
  BASS_ACTIVE_PAUSED  = 3;

  // BASS_ChannelIsSliding return flags
  BASS_SLIDE_FREQ     = 1;
  BASS_SLIDE_VOL      = 2;
  BASS_SLIDE_PAN      = 4;

  // CD ID flags, use with BASS_CDGetID
  BASS_CDID_IDENTITY  = 0;
  BASS_CDID_UPC       = 1;
  BASS_CDID_CDDB      = 2;
  BASS_CDID_CDDB2     = 3;

  // BASS_ChannelGetData flags
  BASS_DATA_AVAILABLE = 0;        // query how much data is buffered
  // new in 2.3:
  BASS_DATA_FLOAT    = $40000000; // flag: return floating-point sample data
  //
  BASS_DATA_FFT512   = $80000000; // 512 sample FFT
  BASS_DATA_FFT1024  = $80000001; // 1024 FFT
  BASS_DATA_FFT2048  = $80000002; // 2048 FFT
  // v2.0
  BASS_DATA_FFT4096  = $80000003; // 4096 FFT
  BASS_DATA_FFT512S  = $80000010; // stereo 512 sample FFT
  BASS_DATA_FFT1024S = $80000011; // stereo 1024 FFT
  BASS_DATA_FFT2048S = $80000012; // stereo 2048 FFT
  BASS_DATA_FFT_INDIVIDUAL = $10; // FFT flag: FFT for each channel, else all combined
  BASS_DATA_FFT_NOWINDOW = $20;   // FFT flag: no Hanning window

  // BASS_StreamGetTags flags : what's returned
  BASS_TAG_ID3   	= 0; // ID3v1 tags : 128 byte block
  BASS_TAG_ID3V2 	= 1; // ID3v2 tags : variable length block
  BASS_TAG_OGG   	= 2; // OGG comments : array of null-terminated strings
  BASS_TAG_HTTP  	= 3; // HTTP headers : array of null-terminated strings
  BASS_TAG_ICY   	= 4; // ICY headers : array of null-terminated strings
  BASS_TAG_META  	= 5; // ICY metadata : null-terminated AnsiString
  BASS_TAG_VENDOR     	= 9; // OGG encoder : null-terminated AnsiString
  BASS_TAG_RIFF_INFO  	= $100;   // RIFF/WAVE tags : array of null-terminated ANSI strings
  BASS_TAG_MUSIC_NAME 	= $10000; // MOD music name : ANSI AnsiString
  BASS_TAG_MUSIC_MESSAGE= $10001; // MOD message : ANSI AnsiString
  BASS_TAG_MUSIC_INST 	= $10100; // + instrument #, MOD instrument name : ANSI AnsiString
  BASS_TAG_MUSIC_SAMPLE = $10300; // + sample #, MOD sample name : ANSI AnsiString

  BASS_FX_CHORUS      = 0;      // GUID_DSFX_STANDARD_CHORUS
  BASS_FX_COMPRESSOR  = 1;      // GUID_DSFX_STANDARD_COMPRESSOR
  BASS_FX_DISTORTION  = 2;      // GUID_DSFX_STANDARD_DISTORTION
  BASS_FX_ECHO        = 3;      // GUID_DSFX_STANDARD_ECHO
  BASS_FX_FLANGER     = 4;      // GUID_DSFX_STANDARD_FLANGER
  BASS_FX_GARGLE      = 5;      // GUID_DSFX_STANDARD_GARGLE
  BASS_FX_I3DL2REVERB = 6;      // GUID_DSFX_STANDARD_I3DL2REVERB
  BASS_FX_PARAMEQ     = 7;      // GUID_DSFX_STANDARD_PARAMEQ
  BASS_FX_REVERB      = 8;      // GUID_DSFX_WAVES_REVERB

  BASS_FX_PHASE_NEG_180 = 0;
  BASS_FX_PHASE_NEG_90  = 1;
  BASS_FX_PHASE_ZERO    = 2;
  BASS_FX_PHASE_90      = 3;
  BASS_FX_PHASE_180     = 4;

  // BASS_RecordSetInput flags
  BASS_INPUT_OFF    = $10000;
  BASS_INPUT_ON     = $20000;
  BASS_INPUT_LEVEL  = $40000;

  // 2.0:
  BASS_INPUT_TYPE_MASK    = $ff000000;
  BASS_INPUT_TYPE_UNDEF   = $00000000;
  BASS_INPUT_TYPE_DIGITAL = $01000000;
  BASS_INPUT_TYPE_LINE    = $02000000;
  BASS_INPUT_TYPE_MIC     = $03000000;
  BASS_INPUT_TYPE_SYNTH   = $04000000;
  BASS_INPUT_TYPE_CD      = $05000000;
  BASS_INPUT_TYPE_PHONE   = $06000000;
  BASS_INPUT_TYPE_SPEAKER = $07000000;
  BASS_INPUT_TYPE_WAVE    = $08000000;
  BASS_INPUT_TYPE_AUX     = $09000000;
  BASS_INPUT_TYPE_ANALOG  = $0a000000;


  // BASS_SetNetConfig flags
  BASS_NET_TIMEOUT  = 0;
  BASS_NET_BUFFER   = 1;

  // STREAMFILEPROC actions
  BASS_FILE_CLOSE   = 0;
  BASS_FILE_READ    = 1;
  BASS_FILE_QUERY   = 2;
  BASS_FILE_LEN     = 3;
  BASS_FILE_SEEK    = 4;

  // 2.0: BASS_StreamGetFilePosition modes
  BASS_FILEPOS_CURRENT    = 0;
  BASS_FILEPOS_DECODE     = BASS_FILEPOS_CURRENT;
  BASS_FILEPOS_DOWNLOAD   = 1;
  BASS_FILEPOS_END        = 2;
  // 2.1
  BASS_FILEPOS_START      = 3;

  // v2.0
  BASS_STREAMPROC_END = $80000000; // end of user stream flag

  // v2.1 - BASS_MusicSet/GetAttribute options
  BASS_MUSIC_ATTRIB_AMPLIFY    = 0;
  BASS_MUSIC_ATTRIB_PANSEP     = 1;
  BASS_MUSIC_ATTRIB_PSCALER    = 2;
  BASS_MUSIC_ATTRIB_BPM        = 3;
  BASS_MUSIC_ATTRIB_SPEED      = 4;
  BASS_MUSIC_ATTRIB_VOL_GLOBAL = 5;
  BASS_MUSIC_ATTRIB_VOL_CHAN   = $100; // + channel #
  BASS_MUSIC_ATTRIB_VOL_INST   = $200; // + instrument #

  // v2.0: BASS_Set/GetConfig options
  BASS_CONFIG_BUFFER        = 0;
  BASS_CONFIG_UPDATEPERIOD  = 1;
  BASS_CONFIG_MAXVOL        = 3;
  BASS_CONFIG_GVOL_SAMPLE   = 4;
  BASS_CONFIG_GVOL_STREAM   = 5;
  BASS_CONFIG_GVOL_MUSIC    = 6;
  BASS_CONFIG_CURVE_VOL     = 7;
  BASS_CONFIG_CURVE_PAN     = 8;
  BASS_CONFIG_FLOATDSP      = 9;
  BASS_CONFIG_3DALGORITHM   = 10;
  BASS_CONFIG_NET_TIMEOUT   = 11;
  BASS_CONFIG_NET_BUFFER    = 12;
  // v2.1
  BASS_CONFIG_PAUSE_NOPLAY  = 13;
{$IFDEF BASS_AFTER_22 }
  // removed in v2.3
  BASS_CONFIG_NET_NOPROXY   = 14;
{$ENDIF }
  BASS_CONFIG_NET_PREBUF    = 15;
  // v2.3
  BASS_CONFIG_NET_AGENT     = 16;
  BASS_CONFIG_NET_PROXY     = 17;
  BASS_CONFIG_NET_PASSIVE   = 18;
  BASS_CONFIG_REC_BUFFER    = 19;
  // v2.4
  BASS_CONFIG_NET_PLAYLIST  = 21;
  BASS_CONFIG_MUSIC_VIRTUAL = 22;
  BASS_CONFIG_VERIFY        = 23;
  BASS_CONFIG_UPDATETHREADS = 24;


type
  {$EXTERNALSYM DWORD }
  DWORD = cardinal;
  {xx $EXTERNALSYM BOOL }
  //BOOL = LongBool;
  {$EXTERNALSYM FLOAT }
  FLOAT = Single;
  QWORD = int64;

  HMUSIC = DWORD;       // MOD music handle
  HSAMPLE = DWORD;      // sample handle
  HCHANNEL = DWORD;     // playing sample's channel handle
  HSTREAM = DWORD;      // sample stream handle
  // v2.0
  HRECORD = DWORD;      // recording handle
  HSYNC = DWORD;        // synchronizer handle
  HDSP = DWORD;         // DSP handle
  HFX = DWORD;          // DX8 effect handle
  HPLUGIN = DWORD;      // Plugin handle

  BASS_INFO = record
{$IFDEF BASS_AFTER_21 }
    // fucked in 2.2
    size: DWORD;        // size of this struct (set this before calling the function)
{$ENDIF }
    flags: DWORD;       // device capabilities (DSCAPS_xxx flags)
    {
      The following values are irrelevant if the device
      doesn't have hardware support
      (DSCAPS_EMULDRIVER is specified in flags)
    }
    hwsize: DWORD;      // size of total device hardware memory
    hwfree: DWORD;      // size of free device hardware memory
    freesam: DWORD;     // number of free sample slots in the hardware
    free3d: DWORD;      // number of free 3D sample slots in the hardware
    minrate: DWORD;     // min sample rate supported by the hardware
    maxrate: DWORD;     // max sample rate supported by the hardware
    eax: BOOL;          // device supports EAX? (always FALSE if BASS_DEVICE_3D was not used)
    minbuf: DWORD;      // recommended minimum buffer length in ms (requires BASS_DEVICE_LATENCY)
    dsver: DWORD;       // DirectSound version (use to check for DX5/7 functions)
    latency: DWORD;     // delay (in ms) before start of playback (requires BASS_DEVICE_LATENCY)
{$IFDEF BASS_AFTER_18 }
    initflags: DWORD;   // "flags" parameter of BASS_Init call
    speakers: DWORD;    // number of speakers available
    driver: pAnsiChar;      // driver
{$ENDIF }
{$IFDEF BASS_AFTER_22 }
    // v2.3
    freq: DWORD;        // current output rate (OSX only)
{$ENDIF }
  end;

  BASS_RECORDINFO = record
{$IFDEF BASS_AFTER_21 }
    // fucked in 2.2
    size: DWORD;        // size of this struct (set this before calling the function)
{$ENDIF }
    flags: DWORD;       // device capabilities (DSCCAPS_xxx flags)
    formats: DWORD;     // supported standard formats (WAVE_FORMAT_xxx flags)
    inputs: DWORD;      // number of inputs
    singlein: BOOL;     // only 1 input can be set at a time
{$IFDEF BASS_AFTER_18 }
    driver: pAnsiChar;      // driver
{$ENDIF }
{$IFDEF BASS_AFTER_22 }
    // v2.3
    freq: DWORD;        // current output rate (OSX only)
{$ENDIF }
  end;

  // v2.0
  BASS_CHANNELINFO = record
    freq: DWORD;        // default playback rate
    chans: DWORD;       // channels
    flags: DWORD;       // BASS_SAMPLE/STREAM/MUSIC/SPEAKER flags
    ctype: DWORD;       // type of channel
{$IFDEF BASS_AFTER_20 }
    // v2.1
    origres: DWORD;     // original resolution
{$ENDIF }
{$IFDEF BASS_AFTER_22 }
    // v2.3
    plugin: HPLUGIN;    // plugin
{$ENDIF }
  end;

{$IFDEF BASS_AFTER_22 }

  // v2.3
  BASS_PLUGINFORM = record
    //
    ctype: DWORD;       // channel type
    name: pAnsiChar;        // format description
    exts: pAnsiChar;	    // file extension filter (*.ext1;*.ext2;etc...)
  end;
  PBASS_PLUGINFORMS = ^TBASS_PLUGINFORMS;
  TBASS_PLUGINFORMS = array[0..maxInt div sizeOf(BASS_PLUGINFORM) - 1] of BASS_PLUGINFORM;

  //
  BASS_PLUGININFO = record
    //
    version: DWORD;             // version (same form as BASS_GetVersion)
    formatc: DWORD;             // number of formats
    formats: PBASS_PLUGINFORMS; // the array of formats
  end;
  PBASS_PLUGININFO = ^BASS_PLUGININFO;

{$ENDIF }

  // Sample info structure
  BASS_SAMPLE = record
    freq: DWORD;        // default playback rate
    volume: DWORD;      // default volume (0-100)
    pan: int32;       // default pan (-100=left, 0=middle, 100=right)
    flags: DWORD;       // BASS_SAMPLE_xxx flags
    length: DWORD;      // length (in samples, not bytes)
    max: DWORD;         // maximum simultaneous playbacks
{$IFDEF BASS_AFTER_20 }
    // really fucked up in 2.1
    origres: DWORD;     // original resolution
{$ENDIF }
{$IFDEF BASS_AFTER_21 }
    // even more fucked up in 2.2
    chans: DWORD;     // Number of channels... 1=mono, 2=stereo, etc...
{$ENDIF }
{$IFDEF BASS_AFTER_22 }
    // one more fuck in 2.3
    mingap: DWORD;      // minimum gap (ms) between creating channels
{$ENDIF }
    {
      The following are the sample's default 3D attributes
      (if the sample is 3D, BASS_SAMPLE_3D is in flags)
      see BASS_ChannelSet3DAttributes
    }
    mode3d: DWORD;      // BASS_3DMODE_xxx mode
    mindist: FLOAT;     // minimum distance
    maxdist: FLOAT;     // maximum distance
    iangle: DWORD;      // angle of inside projection cone
    oangle: DWORD;      // angle of outside projection cone
    outvol: DWORD;      // delta-volume outside the projection cone
    {
      The following are the defaults used if the sample uses the DirectX 7
      voice allocation/management features.
    }
    vam: DWORD;         // voice allocation/management flags (BASS_VAM_xxx)
    priority: DWORD;    // priority (0=lowest, $ffffffff=highest)
  end;

  // 3D vector (for 3D positions/velocities/orientations)
  pBASS_3DVECTOR = ^BASS_3DVECTOR;
  BASS_3DVECTOR = record
    x: FLOAT;           // +=right, -=left
    y: FLOAT;           // +=up, -=down
    z: FLOAT;           // +=front, -=behind
  end;

  BASS_FXCHORUS = record
    fWetDryMix: FLOAT;
    fDepth: FLOAT;
    fFeedback: FLOAT;
    fFrequency: FLOAT;
    lWaveform: DWORD;   // 0=triangle, 1=sine
    fDelay: FLOAT;
    lPhase: DWORD;      // BASS_FX_PHASE_xxx
  end;

  BASS_FXCOMPRESSOR = record
    fGain: FLOAT;
    fAttack: FLOAT;
    fRelease: FLOAT;
    fThreshold: FLOAT;
    fRatio: FLOAT;
    fPredelay: FLOAT;
  end;

  BASS_FXDISTORTION = record
    fGain: FLOAT;
    fEdge: FLOAT;
    fPostEQCenterFrequency: FLOAT;
    fPostEQBandwidth: FLOAT;
    fPreLowpassCutoff: FLOAT;
  end;

  BASS_FXECHO = record
    fWetDryMix: FLOAT;
    fFeedback: FLOAT;
    fLeftDelay: FLOAT;
    fRightDelay: FLOAT;
    lPanDelay: BOOL;
  end;

  BASS_FXFLANGER = record
    fWetDryMix: FLOAT;
    fDepth: FLOAT;
    fFeedback: FLOAT;
    fFrequency: FLOAT;
    lWaveform: DWORD;   // 0=triangle, 1=sine
    fDelay: FLOAT;
    lPhase: DWORD;      // BASS_FX_PHASE_xxx
  end;

  BASS_FXGARGLE = record
    dwRateHz: DWORD;               // Rate of modulation in hz
    dwWaveShape: DWORD;            // 0=triangle, 1=square
  end;

  BASS_FXI3DL2REVERB = record
    lRoom: Longint;                // [-10000, 0]      default: -1000 mB
    lRoomHF: Longint;              // [-10000, 0]      default: 0 mB
    flRoomRolloffFactor: FLOAT;    // [0.0, 10.0]      default: 0.0
    flDecayTime: FLOAT;            // [0.1, 20.0]      default: 1.49s
    flDecayHFRatio: FLOAT;         // [0.1, 2.0]       default: 0.83
    lReflections: Longint;         // [-10000, 1000]   default: -2602 mB
    flReflectionsDelay: FLOAT;     // [0.0, 0.3]       default: 0.007 s
    lReverb: Longint;              // [-10000, 2000]   default: 200 mB
    flReverbDelay: FLOAT;          // [0.0, 0.1]       default: 0.011 s
    flDiffusion: FLOAT;            // [0.0, 100.0]     default: 100.0 %
    flDensity: FLOAT;              // [0.0, 100.0]     default: 100.0 %
    flHFReference: FLOAT;          // [20.0, 20000.0]  default: 5000.0 Hz
  end;

  BASS_FXPARAMEQ = record
    fCenter: FLOAT;
    fBandwidth: FLOAT;
    fGain: FLOAT;
  end;

  BASS_FXREVERB = record
    fInGain: FLOAT;                // [-96.0,0.0]            default: 0.0 dB
    fReverbMix: FLOAT;             // [-96.0,0.0]            default: 0.0 db
    fReverbTime: FLOAT;            // [0.001,3000.0]         default: 1000.0 ms
    fHighFreqRTRatio: FLOAT;       // [0.001,0.999]          default: 0.001
  end;

  // callback function types
  STREAMPROC = function(handle: HSTREAM; buffer: Pointer; length: DWORD; user: DWORD): DWORD; stdcall;
  {
    User stream callback function. NOTE: A stream function should obviously be as
    quick as possible, other streams (and MOD musics) can't be mixed until
    it's finished.
    handle : The stream that needs writing
    buffer : Buffer to write the samples in
    length : Number of bytes to write
    user   : The 'user' parameter value given when calling BASS_StreamCreate
    RETURN : Number of bytes written. Set the BASS_STREAMPROC_END flag to end
	     the stream.
  }

  STREAMFILEPROC = function(action, param1, param2, user: DWORD): DWORD; stdcall;
  {
     User file stream callback function.
     action : The action to perform, one of BASS_FILE_xxx values.
     param1 : Depends on "action"
     param2 : Depends on "action"
     user   : The 'user' parameter value given when calling BASS_StreamCreate
     RETURN : Depends on "action"
  }

  // v2.0
  DOWNLOADPROC = procedure(buffer: pointer; length: DWORD; user: DWORD); stdcall;
  {
    Internet stream download callback function.
    buffer : Buffer containing the downloaded data... NULL=end of download
    length : Number of bytes in the buffer
    user   : The 'user' parameter value given when calling BASS_StreamCreateURL
  }

  SYNCPROC = procedure(handle: HSYNC; channel, data: DWORD; user: DWORD); stdcall;
  {
    Sync callback function. NOTE: a sync callback function should be very
    quick as other syncs cannot be processed until it has finished. If the
    sync is a "mixtime" sync, then other streams and MOD musics can not be
    mixed until it's finished either.
    handle : The sync that has occured
    channel: Channel that the sync occured in
    data   : Additional data associated with the sync's occurance
    user   : The 'user' parameter given when calling BASS_ChannelSetSync
  }

  DSPPROC = procedure(handle: HDSP; channel: DWORD; buffer: Pointer; length: DWORD; user: DWORD); stdcall;
  {
    DSP callback function. NOTE: A DSP function should obviously be as quick
    as possible... other DSP functions, streams and MOD musics can not be
    processed until it's finished.
    handle : The DSP handle
    channel: Channel that the DSP is being applied to
    buffer : Buffer to apply the DSP to
    length : Number of bytes in the buffer
    user   : The 'user' parameter given when calling BASS_ChannelSetDSP
  }

{$IFDEF BASS_AFTER_18 }
  // fucked up by 2.0
  RECORDPROC = function(handle: HRECORD; buffer: Pointer; length: DWORD; user: DWORD): BOOL; stdcall;
{$ELSE }
  RECORDPROC = function(buffer: Pointer; length: DWORD; user: DWORD): BOOL; stdcall;
{$ENDIF }
  {
    Recording callback function.
    buffer : Buffer containing the recorded sample data
    length : Number of bytes
    user   : The 'user' parameter value given when calling BASS_RecordStart
    RETURN : TRUE = continue recording, FALSE = stop
  }


  pBassProc = ^tBassProc;
  tBassProc = record
    //
    r_module: hModule;
    r_refCount: int;
    //
    // -- FUNCTIONS EXPORTED FROM BASS.DLL --
    //
    {21}r_getVersion:           function(): DWORD; stdcall;
    //
    {21}r_getDeviceDescription: function(devnum: DWORD): pAnsiChar; stdcall;
{$IFDEF BASS_AFTER_18 }
    // removed in 2.0
{$ELSE }
    r_setBufferLength:      function(length: FLOAT): FLOAT; stdcall;
    r_setGlobalVolumes:     procedure(musvol, samvol, strvol: int32); stdcall;
    r_getGlobalVolumes:     procedure(out musvol, samvol, strvol: int32); stdcall;
    r_setLogCurves:         procedure(volume, pan: BOOL); stdcall;
    r_set3DAlgorithm:       procedure(algo: DWORD); stdcall;
{$ENDIF }
    {21}r_errorGetCode:         function(): DWORD; stdcall;
    //
{$IFDEF BASS_AFTER_18 }
    // fucked up in 2.0
    {21}r_init:                 function(device: int32; freq, flags: DWORD; win: HWND; clsid: PGUID): BOOL; stdcall;
{$ELSE }
    r_init:                     function(device: int32; freq, flags: DWORD; win: HWND): BOOL; stdcall;
{$ENDIF }    
    {21}r_free:                 function(): bool; stdcall;
    //
    {21}r_getDSoundObject:      function(obj: DWORD): pointer; stdcall;
    {21}r_getInfo:              procedure(out info: BASS_INFO); stdcall;
    {21}r_getCPU:               function(): FLOAT; stdcall;
    {21}r_start:                function(): BOOL; stdcall;
    {21}r_stop:                 function(): BOOL; stdcall;
    {21}r_pause:                function(): BOOL; stdcall;
    {21}r_setVolume:            function(volume: DWORD): BOOL; stdcall;
    {21}r_getVolume:            function(): int32; stdcall;
    //
    {21}r_set3DFactors:         function(distf, rollf, doppf: FLOAT): BOOL; stdcall;
    {21}r_get3DFactors:         function(out distf, rollf, doppf: FLOAT): BOOL; stdcall;
    {21}r_set3DPosition:        function(const pos, vel, front, top: BASS_3DVECTOR): BOOL; stdcall;
    {21}r_get3DPosition:        function(out pos, vel, front, top: BASS_3DVECTOR): BOOL; stdcall;
    {21}r_apply3D:              procedure(); stdcall;
    {21}r_setEAXParameters:     function(env: int32; vol, decay, damp: FLOAT): BOOL; stdcall;
    {21}r_getEAXParameters:     function(out env: int32; out vol, decay, damp: FLOAT): BOOL; stdcall;
    //
{$IFDEF BASS_AFTER_18 }
    // fucked up by 2.0
    {21}r_musicLoad:            function(mem: BOOL; f: Pointer; offset, length, flags, freq: DWORD): HMUSIC; stdcall;
{$ELSE }
    r_musicLoad:             function(mem: BOOL; f: Pointer; offset, length, flags: DWORD): HMUSIC; stdcall;
{$ENDIF }

    {21}r_musicFree:            procedure(handle: HMUSIC); stdcall;
{$IFDEF BASS_AFTER_22 }
{$ELSE }
    // fucked in 2.3
    {21}r_musicGetName:         function(handle: HMUSIC): pAnsiChar; stdcall;
{$ENDIF }
    //
{$IFDEF BASS_BEFORE_22 }
    // removed in 2.2
    {21}r_musicGetLength:       function(handle: HMUSIC; playlen: BOOL): DWORD; stdcall;
{$ENDIF }
{$IFDEF BASS_AFTER_20 }
    // removed in 2.1
{$ELSE }
    r_musicPlay:             function(handle: HMUSIC): BOOL; stdcall;
    r_musicPlayEx:           function(handle: HMUSIC; pos: DWORD; flags: int32; reset: BOOL): BOOL; stdcall;
    //
    r_musicSetAmplify:       function(handle: HMUSIC; amp: DWORD): BOOL; stdcall;
    r_musicSetPanSep:        function(handle: HMUSIC; pan: DWORD): BOOL; stdcall;
    r_musicSetPositionScaler: function(handle: HMUSIC; scale: DWORD): BOOL; stdcall;
{$ENDIF }
{$IFDEF BASS_AFTER_20 }
    // new in 2.1
    {21}r_musicSetAttribute:    function(handle: HMUSIC; attrib,value: DWORD): DWORD; stdcall;
    {21}r_musicGetAttribute:    function(handle: HMUSIC; attrib: DWORD): DWORD; stdcall;
{$ENDIF }

    //
    {21}r_sampleLoad:           function(mem: BOOL; f: Pointer; offset, length, max, flags: DWORD): HSAMPLE; stdcall;
  {$IFDEF BASS_AFTER_21 }
    // parameters were fucked in 2.2
    {22}r_sampleCreate:         function(length, freq, chans, max, flags: DWORD): Pointer; stdcall;
  {$ELSE }
    {21}r_sampleCreate:         function(length, freq, max, flags: DWORD): Pointer; stdcall;
  {$ENDIF }
    {21}r_sampleCreateDone:     function(): HSAMPLE; stdcall;
    {21}r_sampleFree:           procedure(handle: HSAMPLE); stdcall;
    {21}r_sampleGetInfo:        function(handle: HSAMPLE; out info: BASS_SAMPLE): BOOL;stdcall;
    {21}r_sampleSetInfo:        function(handle: HSAMPLE; const info: BASS_SAMPLE): BOOL; stdcall;
{$IFDEF BASS_AFTER_20 }
    // new in 2.1
    {21}r_sampleGetChannel:     function(handle: HSAMPLE; onlynew: BOOL): HCHANNEL; stdcall;
{$ENDIF }
{$IFDEF BASS_AFTER_20 }
    // removed in 2.1
{$ELSE}
    r_samplePlay:            function(handle: HSAMPLE): HCHANNEL; stdcall;
    r_samplePlayEx:          function(handle: HSAMPLE; start: DWORD; freq, volume, pan: int32; loop: BOOL): HCHANNEL; stdcall;
    r_samplePlay3D:          function(handle: HSAMPLE; const pos, orient, vel: BASS_3DVECTOR): HCHANNEL; stdcall;
    r_samplePlay3DEx:        function(handle: HSAMPLE; const pos, orient, vel: BASS_3DVECTOR; start: DWORD; freq, volume: int32; loop: BOOL): HCHANNEL; stdcall;
{$ENDIF }
    {21}r_sampleStop:           function(handle: HSAMPLE): BOOL; stdcall;
    //
    {21}r_streamCreate:         function(freq, flags: DWORD; proc: pointer; user: DWORD): HSTREAM; stdcall;
    {21}r_streamCreateFile:     function(mem: BOOL; f: Pointer; offset, length, flags: DWORD): HSTREAM; stdcall;
    {21}r_streamFree:           procedure(handle: HSTREAM); stdcall;
{$IFDEF BASS_BEFORE_22 }
    // removed in 2.2
    {21}r_streamGetLength:      function(handle: HSTREAM): QWORD; stdcall;
{$ENDIF }
{$IFDEF BASS_AFTER_20 }
    // removed in 2.1
{$ELSE}
    r_streamPlay:            function(handle: HSTREAM; flush: BOOL; flags: DWORD): BOOL; stdcall;
{$ENDIF }
    //
{$IFDEF BASS_AFTER_18 }
    // removed in 2.0
{$ELSE }
    r_CDInit:                function(drive: pAnsiChar; flags: DWORD): BOOL; stdcall;
    r_CDFree:                procedure(); stdcall;
    r_CDInDrive:             function(): BOOL; stdcall;
    r_CDPlay:                function(track: DWORD; loop: BOOL; wait: BOOL): BOOL; stdcall;
{$ENDIF }
    //
{$IFDEF BASS_AFTER_18 }
    // removed in 2.0
{$ELSE }
    r_channelGetFlags:       function(handle: DWORD): DWORD; stdcall;
{$ENDIF }
    {21}r_channelStop:          function(handle: DWORD): BOOL; stdcall;
    {21}r_channelPause:         function(handle: DWORD): BOOL; stdcall;
{$IFDEF BASS_AFTER_20 }
    // removed in 2.1
{$ELSE }
    r_channelResume:         function(handle: DWORD): BOOL; stdcall;
{$ENDIF }
    {21}r_channelSetAttributes: function(handle: DWORD; freq, volume, pan: int32): BOOL; stdcall;
    {21}r_channelGetAttributes: function(handle: DWORD; out freq, volume, pan: Integer): BOOL; stdcall;
    {21}r_channelSet3DAttributes: function(handle: DWORD; mode: int32; min, max: FLOAT; iangle, oangle, outvol: int32): BOOL; stdcall;
    {21}r_channelGet3DAttributes: function(handle: DWORD; out mode: int32; out min, max: FLOAT; out iangle, oangle, outvol: int32): BOOL; stdcall;
    {21}r_channelSet3DPosition: function(handle: DWORD; const pos, orient, vel: BASS_3DVECTOR): BOOL; stdcall;
    {21}r_channelGet3DPosition: function(handle: DWORD; out pos, orient, vel: BASS_3DVECTOR): BOOL; stdcall;
    {21}r_channelSetPosition:   function(handle: DWORD; pos: QWORD): BOOL; stdcall;
    {21}r_channelGetPosition:   function(handle: DWORD): QWORD; stdcall;
    {21}r_channelGetLevel:      function(handle: DWORD): DWORD; stdcall;
    {21}r_channelGetData:       function(handle: DWORD; buffer: pointer; length: DWORD): DWORD; stdcall;
    {21}r_channelSetSync:       function(handle: DWORD; atype: DWORD; param: QWORD; proc: SYNCPROC; user: DWORD): HSYNC; stdcall;
    {21}r_channelRemoveSync:    function(handle: DWORD; sync: HSYNC): BOOL; stdcall;
{$IFDEF BASS_AFTER_18 }
    // fucked up by 2.0
    {21}r_channelSetDSP:        function(handle: DWORD; proc: DSPPROC; user: DWORD; priority: int32): HDSP; stdcall;
{$ELSE }
    r_channelSetDSP:          function(handle: DWORD; proc: DSPPROC; user: DWORD): HDSP; stdcall;
{$ENDIF }
    {21}r_channelRemoveDSP:     function(handle: DWORD; dsp: HDSP): BOOL; stdcall;
    {21}r_channelSetEAXMix:     function(handle: DWORD; mix: FLOAT): BOOL; stdcall;
    {21}r_channelGetEAXMix:     function(handle: DWORD; out mix: FLOAT): BOOL; stdcall;

    // these were added/changed in v0.9
    {21}r_streamGetFilePosition: function(handle:HSTREAM; mode:DWORD): DWORD; stdcall;
{$IFDEF BASS_AFTER_18 }
    // removed in 2.0
{$ELSE }
    r_CDGetTracks:            function(): int32; stdcall;
    r_CDGetTrackLength:       function(track:DWORD):DWORD; stdcall;
{$ENDIF }
    {21}r_channelIsActive:       function(handle: DWORD): DWORD; stdcall;

    // v1.1
{$IFDEF BASS_AFTER_18 }
    // removed in 2.0
{$ELSE }
    r_CDGetID:                function(id: DWORD):pAnsiChar; stdcall;
{$ENDIF }
{$IFDEF BASS_AFTER_20 }
    // fucked up in 2.1
    {21}r_channelSetFX:          function(handle, etype: DWORD; priority: int32): HFX; stdcall;
{$ELSE }
    r_channelSetFX:           function(handle, etype: DWORD): HFX; stdcall;
{$ENDIF }
    {21}r_channelRemoveFX:       function(handle: DWORD; fx: HFX): BOOL; stdcall;
    {21}r_FXSetParameters:       function(handle: HFX; par: Pointer): BOOL; stdcall;
    {21}r_FXGetParameters:       function(handle: HFX; par: Pointer): BOOL; stdcall;

    // v1.2
    {21}r_channelSetLink:        function(handle, chan: DWORD): BOOL; stdcall;
    {21}r_channelRemoveLink:     function(handle, chan: DWORD): BOOL; stdcall;
{$IFDEF BASS_AFTER_20 }
    // removed in 2.1
{$ELSE }
    r_musicPreBuf:            function(handle: HMUSIC): BOOL; stdcall;
    r_streamPreBuf:           function(handle: HMUSIC): BOOL; stdcall;
{$ENDIF }

    // v1.3
    {21}r_update:                function(): BOOL; stdcall;
{$IFDEF BASS_AFTER_22 }
    {21}r_channelGetTags:         function(handle: HSTREAM; tags : DWORD): pAnsiChar; stdcall;
{$ELSE }
    // fucked in 2.3
    {21}r_streamGetTags:         function(handle: HSTREAM; tags : DWORD): pAnsiChar; stdcall;
{$ENDIF }
    //
{$IFDEF BASS_AFTER_18 }
    // fucked up in 2.0
    {21}r_streamCreateURL:       function(URL: pAnsiChar; offset: DWORD; flags: DWORD; proc: DOWNLOADPROC; user:DWORD):HSTREAM; stdcall;
{$ELSE }
    r_streamCreateURL:        function(URL: pAnsiChar; offset: DWORD; flags: DWORD; save: pAnsiChar):HSTREAM;stdcall;
{$ENDIF }
    {21}r_channelBytes2Seconds:  function(handle: DWORD; pos: QWORD): FLOAT; stdcall;
    {21}r_channelSeconds2Bytes:  function(handle: DWORD; pos: FLOAT): QWORD; stdcall;

    // v1.4
{$IFDEF BASS_AFTER_18 }
    // removed in 2.0
{$ELSE }
    r_setCLSID:               procedure(clsid: TGUID); stdcall;
    r_musicSetChannelVol:     function(handle: HMUSIC; channel,volume: DWORD): BOOL; stdcall;
    r_musicGetChannelVol:     function(handle: HMUSIC; channel: DWORD): int32; stdcall;
{$ENDIF }

    // v1.5
    {21}r_recordGetDeviceDescription: function(devnum: DWORD): pAnsiChar; stdcall;
    {21}r_recordInit:            function(device: int32): BOOL; stdcall;
    {21}r_recordFree:            procedure(); stdcall;
    {21}r_recordGetInfo:         procedure(out info: BASS_RECORDINFO); stdcall;
    {21}r_recordStart:	      function(freq, flags: DWORD; proc: RECORDPROC; user: DWORD): BOOL; stdcall;

    // v1.6
{$IFDEF BASS_AFTER_18 }
    // removed in 2.0
{$ELSE }
    r_CDDoor:                 function(open:BOOL): BOOL; stdcall;
{$ENDIF }
    {21}r_recordGetInputName:    function(input: DWORD): pAnsiChar; stdcall;
    {21}r_recordSetInput:        function(input: DWORD; setting: DWORD): BOOL; stdcall;
    {21}r_recordGetInput:        function(input: DWORD): DWORD; stdcall;

    // v1.7
{$IFDEF BASS_AFTER_18 }
    // removed in 2.0
{$ELSE }
    r_setNetConfig:           function(option, value: DWORD): DWORD; stdcall;
{$ENDIF }
    {21}r_channelSlideAttributes: function(handle: DWORD; freq, volume, pan: int32; time: DWORD): BOOL; stdcall;
    {21}r_channelIsSliding:       function(handle: DWORD): DWORD; stdcall;

    // v2.0
{$IFDEF BASS_AFTER_18 }
    {21}r_setConfig:	      function(option, value: DWORD): DWORD; stdcall;
    {21}r_getConfig:	      function(option: DWORD): DWORD; stdcall;
    {21}r_setDevice:          function(device: DWORD): BOOL; stdcall;
    {21}r_getDevice:	      function(): DWORD; stdcall;
{$IFDEF BASS_AFTER_20 }
    // removed in 2.1
{$ELSE }
    r_musicSetVolume:	      function(handle: HMUSIC; chanins,volume: DWORD): BOOL; stdcall;
    r_musicGetVolume:	      function(handle: HMUSIC; chanins: DWORD): int32; stdcall;
{$ENDIF }
    {21}r_streamCreateFileUser:   function(buffered: BOOL; flags: DWORD; proc: STREAMFILEPROC; user: DWORD): HSTREAM; stdcall;
    {21}r_recordSetDevice:        function(device: DWORD): BOOL; stdcall;
    {21}r_recordGetDevice:        function(): DWORD; stdcall;
    {21}r_channelGetDevice:       function(handle: DWORD): DWORD; stdcall;
    {21}r_channelGetInfo:         function(handle: DWORD; out info: BASS_CHANNELINFO): BOOL; stdcall;
{$ENDIF }
    //
{$IFDEF BASS_AFTER_20 }
    // new in 2.1
    {21}r_channelSetFlags:	      function(handle, flags: DWORD): BOOL; stdcall;
  {$IFDEF BASS_AFTER_21 }
    // parameters were fucked in 2.2
    {22}r_channelPreBuf:	      function(handle, length: DWORD): BOOL; stdcall;
  {$ELSE}
    {21}r_channelPreBuf:	      function(handle: DWORD): BOOL; stdcall;
  {$ENDIF }
    {21}r_channelPlay:	              function(handle: DWORD; restart: BOOL): BOOL; stdcall;
{$ENDIF }
{$IFDEF BASS_AFTER_21 }
    // new in 2.2
    {22}r_channelGetLength:	 function(handle: DWORD): QWORD; stdcall;
    {22}r_musicGetOrders: 	 function(handle: HMUSIC): DWORD; stdcall;
    {22}r_musicGetOrderPosition: function(handle: HMUSIC): DWORD; stdcall;
{$ENDIF }
{$IFDEF BASS_AFTER_22 }
    {23}r_pluginLoad: 		function(filename: pAnsiChar; flags: DWORD): HPLUGIN; stdcall;
    {23}r_pluginFree: 	 	function(handle: HPLUGIN): BOOL; stdcall;
    {23}r_pluginGetInfo: 	function(handle: HPLUGIN): PBASS_PLUGININFO; stdcall;
{$ENDIF }
  end;


{*
  This function is defined in the implementation part of this unit.
  It is not part of BASS.DLL but an extra function which makes it easier
  to set the predefined EAX environments.
  env    : a EAX_ENVIRONMENT_xxx constant
}
function BASS_EAXPreset(const bassProc: tBassProc; env: int32): BOOL;

// MACROS

// --  --
function MAKEMUSICPOS(order, row: DWORD): DWORD;
function BASS_SPEAKER_N(n: DWORD): DWORD;

// -- DLL specific --

const
  c_bassLibrary	= 'bass.dll';


{*
  Loads the BASS Library.
  NOTE: load and unload functions are not multi-thread safe.
}
function load_BASS(var bassProc: tBassProc; const dllFile: wideString = c_bassLibrary): BOOL;

{*
  Unloads BASS Library.
  NOTE: load and unload functions are not multi-thread safe.
}
procedure unload_BASS(var bassProc: tBassProc);



implementation

uses
  unaUtils;

// -- --
function BASS_SPEAKER_N(n: DWORD): DWORD;
begin
  result := (n shl 24);
end;

// -- --
function MAKEMUSICPOS(order, row: DWORD): DWORD;
begin
  result := ($80000000 or DWORD(MAKELONG(order, row)));
end;


// --  --
function load_BASS(var bassProc: tBassProc; const dllFile: wideString): BOOL;
var
  libFile: wideString;
begin
  with bassProc do begin
    //
    if (0 <> r_module) then begin
      //
      if (0 < r_refCount) then
	inc(r_refCount);
    end
    else begin
      //
      libFile := dllFile;
      if ('' = libFile) then
	libFile := c_bassLibrary;
      //
      fillChar(bassProc, sizeOf(bassProc), #0);
      //
{$IFNDEF NO_ANSI_SUPPORT }
      if (g_wideApiSupported) then
{$ENDIF NO_ANSI_SUPPORT }
        r_module := LoadLibraryW(pWideChar(libFile))
{$IFNDEF NO_ANSI_SUPPORT }
      else
        r_module := LoadLibraryA(pAnsiChar(AnsiString(libFile)));
{$ENDIF NO_ANSI_SUPPORT }
      ;
      //
      if (0 <> r_module) then begin
	//
	@r_getVersion           := GetProcAddress(r_module, 'BASS_GetVersion');
	@r_getDeviceDescription := GetProcAddress(r_module, 'BASS_GetDeviceDescription');
{$IFDEF BASS_AFTER_18 }
	// removed in 2.0
{$ELSE }
	@r_setBufferLength      := GetProcAddress(r_module, 'BASS_SetBufferLength');
	@r_setGlobalVolumes     := GetProcAddress(r_module, 'BASS_SetGlobalVolumes');
	@r_getGlobalVolumes     := GetProcAddress(r_module, 'BASS_GetGlobalVolumes');
	@r_setLogCurves         := GetProcAddress(r_module, 'BASS_SetLogCurves');
	@r_set3DAlgorithm       := GetProcAddress(r_module, 'BASS_Set3DAlgorithm');
{$ENDIF }
	@r_errorGetCode         := GetProcAddress(r_module, 'BASS_ErrorGetCode');
	//
	@r_init                 := GetProcAddress(r_module, 'BASS_Init');
	@r_free                 := GetProcAddress(r_module, 'BASS_Free');
	//
	@r_getDSoundObject      := GetProcAddress(r_module, 'BASS_GetDSoundObject');
	@r_getInfo              := GetProcAddress(r_module, 'BASS_GetInfo');
	@r_getCPU               := GetProcAddress(r_module, 'BASS_GetCPU');
	@r_start                := GetProcAddress(r_module, 'BASS_Start');
	@r_stop                 := GetProcAddress(r_module, 'BASS_Stop');
	@r_pause                := GetProcAddress(r_module, 'BASS_Pause');
	@r_setVolume            := GetProcAddress(r_module, 'BASS_SetVolume');
	@r_getVolume            := GetProcAddress(r_module, 'BASS_GetVolume');
	@r_set3DFactors         := GetProcAddress(r_module, 'BASS_Set3DFactors');
	@r_get3DFactors         := GetProcAddress(r_module, 'BASS_Get3DFactors');
	@r_set3DPosition        := GetProcAddress(r_module, 'BASS_Set3DPosition');
	@r_get3DPosition        := GetProcAddress(r_module, 'BASS_Get3DPosition');
	@r_apply3D              := GetProcAddress(r_module, 'BASS_Apply3D');
	@r_setEAXParameters     := GetProcAddress(r_module, 'BASS_SetEAXParameters');
	@r_getEAXParameters     := GetProcAddress(r_module, 'BASS_GetEAXParameters');
	//
	@r_musicLoad            := GetProcAddress(r_module, 'BASS_MusicLoad');
	@r_musicFree            := GetProcAddress(r_module, 'BASS_MusicFree');
{$IFDEF BASS_AFTER_22 }
{$ELSE }
        // fucked in 2.3
	@r_musicGetName         := GetProcAddress(r_module, 'BASS_MusicGetName');
{$ENDIF }	
{$IFDEF BASS_BEFORE_22 }
	// removed in 2.2
	@r_musicGetLength       := GetProcAddress(r_module, 'BASS_MusicGetLength');
{$ELSE }
	// new in 2.2
	@r_channelGetLength	:= GetProcAddress(r_module, 'BASS_ChannelGetLength');
	@r_musicGetOrders 	:= GetProcAddress(r_module, 'BASS_MusicGetOrders');
	@r_musicGetOrderPosition:= GetProcAddress(r_module, 'BASS_MusicGetOrderPosition');
{$ENDIF }
	//
{$IFDEF BASS_AFTER_20 }
        // removed in 2.1
{$ELSE }
	@r_musicPlay            := GetProcAddress(r_module, 'BASS_MusicPlay');
	@r_musicPlayEx          := GetProcAddress(r_module, 'BASS_MusicPlayEx');
	@r_musicSetAmplify      := GetProcAddress(r_module, 'BASS_MusicSetAmplify');
	@r_musicSetPanSep       := GetProcAddress(r_module, 'BASS_MusicSetPanSep');
	@r_musicSetPositionScaler := GetProcAddress(r_module, 'BASS_MusicSetPositionScaler');
{$ENDIF }
{$IFDEF BASS_AFTER_20 }
	// new in 2.1
	@r_musicSetAttribute    := GetProcAddress(r_module, 'BASS_MusicSetAttribute');
	@r_musicGetAttribute    := GetProcAddress(r_module, 'BASS_MusicGetAttribute');
{$ENDIF }
	//
	@r_sampleLoad           := GetProcAddress(r_module, 'BASS_SampleLoad');
	@r_sampleCreate         := GetProcAddress(r_module, 'BASS_SampleCreate');
	@r_sampleCreateDone     := GetProcAddress(r_module, 'BASS_SampleCreateDone');
	@r_sampleFree           := GetProcAddress(r_module, 'BASS_SampleFree');
	@r_sampleGetInfo        := GetProcAddress(r_module, 'BASS_SampleGetInfo');
	@r_sampleSetInfo        := GetProcAddress(r_module, 'BASS_SampleSetInfo');
{$IFDEF BASS_AFTER_20 }
	// new in 2.1
	@r_sampleGetChannel     := GetProcAddress(r_module, 'BASS_SampleGetChannel');
{$ENDIF }
{$IFDEF BASS_AFTER_20 }
    // removed in 2.1
{$ELSE}
	@r_samplePlay           := GetProcAddress(r_module, 'BASS_SamplePlay');
	@r_samplePlayEx         := GetProcAddress(r_module, 'BASS_SamplePlayEx');
	@r_samplePlay3D         := GetProcAddress(r_module, 'BASS_SamplePlay3D');
	@r_samplePlay3DEx       := GetProcAddress(r_module, 'BASS_SamplePlay3DEx');
{$ENDIF }
	@r_sampleStop           := GetProcAddress(r_module, 'BASS_SampleStop');
	//
	@r_streamCreate         := GetProcAddress(r_module, 'BASS_StreamCreate');
	@r_streamCreateFile     := GetProcAddress(r_module, 'BASS_StreamCreateFile');
	@r_streamFree           := GetProcAddress(r_module, 'BASS_StreamFree');
{$IFDEF BASS_BEFORE_22 }
	// removed in 2.2
	@r_streamGetLength      := GetProcAddress(r_module, 'BASS_StreamGetLength');
{$ENDIF }
{$IFDEF BASS_AFTER_20 }
	// removed in 2.1
{$ELSE }
	@r_streamPlay           := GetProcAddress(r_module, 'BASS_StreamPlay');
{$ENDIF }
{$IFDEF BASS_AFTER_18 }
	// removed in 2.0
{$ELSE }
	@r_CDInit               := GetProcAddress(r_module, 'BASS_CDInit');
	@r_CDFree               := GetProcAddress(r_module, 'BASS_CDFree');
	@r_CDInDrive            := GetProcAddress(r_module, 'BASS_CDInDrive');
	@r_CDPlay               := GetProcAddress(r_module, 'BASS_CDPlay');
	//
	@r_channelGetFlags      := GetProcAddress(r_module, 'BASS_ChannelGetFlags');
{$ENDIF }
	@r_channelStop          := GetProcAddress(r_module, 'BASS_ChannelStop');
	@r_channelPause         := GetProcAddress(r_module, 'BASS_ChannelPause');
{$IFDEF BASS_AFTER_20 }
	// removed up in 2.1
{$ELSE }
	@r_channelResume        := GetProcAddress(r_module, 'BASS_ChannelResume');
{$ENDIF }
	//
	@r_channelSetAttributes := GetProcAddress(r_module, 'BASS_ChannelSetAttributes');
	@r_channelGetAttributes := GetProcAddress(r_module, 'BASS_ChannelGetAttributes');
	@r_channelSet3DAttributes := GetProcAddress(r_module, 'BASS_ChannelSet3DAttributes');
	@r_channelGet3DAttributes := GetProcAddress(r_module, 'BASS_ChannelGet3DAttributes');
	@r_channelSet3DPosition := GetProcAddress(r_module, 'BASS_ChannelSet3DPosition');
	@r_channelGet3DPosition := GetProcAddress(r_module, 'BASS_ChannelGet3DPosition');
	@r_channelSetPosition   := GetProcAddress(r_module, 'BASS_ChannelSetPosition');
	@r_channelGetPosition   := GetProcAddress(r_module, 'BASS_ChannelGetPosition');
	@r_channelGetLevel      := GetProcAddress(r_module, 'BASS_ChannelGetLevel');
	@r_channelGetData       := GetProcAddress(r_module, 'BASS_ChannelGetData');
	@r_channelSetSync       := GetProcAddress(r_module, 'BASS_ChannelSetSync');
	@r_channelRemoveSync    := GetProcAddress(r_module, 'BASS_ChannelRemoveSync');
	//
	@r_channelSetDSP        := GetProcAddress(r_module, 'BASS_ChannelSetDSP');
	@r_channelRemoveDSP     := GetProcAddress(r_module, 'BASS_ChannelRemoveDSP');
	@r_channelSetEAXMix     := GetProcAddress(r_module, 'BASS_ChannelSetEAXMix');
	@r_channelGetEAXMix     := GetProcAddress(r_module, 'BASS_ChannelGetEAXMix');

	// new in v0.9
	@r_streamGetFilePosition := GetProcAddress(r_module, 'BASS_StreamGetFilePosition');

{$IFDEF BASS_AFTER_18 }
	// removed in 2.0
{$ELSE }
	@r_CDGetTracks           := GetProcAddress(r_module, 'BASS_CDGetTracks');
	@r_CDGetTrackLength      := GetProcAddress(r_module, 'BASS_CDGetTrackLength');
{$ENDIF }
	@r_channelIsActive       := GetProcAddress(r_module, 'BASS_ChannelIsActive');

	// v1.1
{$IFDEF BASS_AFTER_18 }
	// removed in 2.0
{$ELSE }
	@r_CDGetID              := GetProcAddress(r_module, 'BASS_CDGetID');
{$ENDIF }
	@r_channelSetFX         := GetProcAddress(r_module, 'BASS_ChannelSetFX');
	@r_channelRemoveFX      := GetProcAddress(r_module, 'BASS_ChannelRemoveFX');
	@r_FXSetParameters      := GetProcAddress(r_module, 'BASS_FXSetParameters');
	@r_FXGetParameters      := GetProcAddress(r_module, 'BASS_FXGetParameters');

	// v1.2
	@r_channelSetLink       := GetProcAddress(r_module, 'BASS_ChannelSetLink');
	@r_channelRemoveLink    := GetProcAddress(r_module, 'BASS_ChannelRemoveLink');
{$IFDEF BASS_AFTER_20 }
	// removed up in 2.1
{$ELSE }
	@r_musicPreBuf          := GetProcAddress(r_module, 'BASS_MusicPreBuf');
	@r_streamPreBuf         := GetProcAddress(r_module, 'BASS_StreamPreBuf');
{$ENDIF }

	// v1.3
	@r_update               := GetProcAddress(r_module, 'BASS_Update');
{$IFDEF BASS_AFTER_22 }
	@r_channelGetTags        := GetProcAddress(r_module, 'BASS_ChannelGetTags');
{$ELSE }
	// fucked in 2.3
	@r_streamGetTags        := GetProcAddress(r_module, 'BASS_StreamGetTags');
{$ENDIF }
	@r_streamCreateURL      := GetProcAddress(r_module, 'BASS_StreamCreateURL');
	//
	@r_channelBytes2Seconds := GetProcAddress(r_module, 'BASS_ChannelBytes2Seconds');
	@r_channelSeconds2Bytes := GetProcAddress(r_module, 'BASS_ChannelSeconds2Bytes');

	// v1.4
{$IFDEF BASS_AFTER_18 }
	// removed in 2.0
{$ELSE }
	@r_setCLSID             := GetProcAddress(r_module, 'BASS_SetCLSID');
	@r_musicSetChannelVol   := GetProcAddress(r_module, 'BASS_MusicSetChannelVol');
	@r_musicGetChannelVol   := GetProcAddress(r_module, 'BASS_MusicGetChannelVol');
{$ENDIF }

	// v1.5
	@r_recordGetDeviceDescription := GetProcAddress(r_module, 'BASS_RecordGetDeviceDescription');
	@r_recordInit           := GetProcAddress(r_module, 'BASS_RecordInit');
	@r_recordFree           := GetProcAddress(r_module, 'BASS_RecordFree');
	@r_recordGetInfo        := GetProcAddress(r_module, 'BASS_RecordGetInfo');
	@r_recordStart          := GetProcAddress(r_module, 'BASS_RecordStart');

	// v1.6
{$IFDEF BASS_AFTER_18 }
	// removed in 2.0
{$ELSE }
	@r_CDDoor               := GetProcAddress(r_module, 'BASS_CDDoor');
{$ENDIF }
	@r_recordGetInputName   := GetProcAddress(r_module, 'BASS_RecordGetInputName');
	@r_recordSetInput       := GetProcAddress(r_module, 'BASS_RecordSetInput');
	@r_recordGetInput       := GetProcAddress(r_module, 'BASS_RecordGetInput');

	// v1.7
{$IFDEF BASS_AFTER_18 }
	// removed in 2.0
{$ELSE }
	@r_setNetConfig           := GetProcAddress(r_module, 'BASS_SetNetConfig');
{$ENDIF }
	@r_channelSlideAttributes := GetProcAddress(r_module, 'BASS_ChannelSlideAttributes');
	@r_channelIsSliding       := GetProcAddress(r_module, 'BASS_ChannelIsSliding');

{$IFDEF BASS_AFTER_18 }
	// new in 2.0
	@r_setConfig	      	:= GetProcAddress(r_module, 'BASS_SetConfig');
	@r_getConfig	      	:= GetProcAddress(r_module, 'BASS_GetConfig');
	@r_setDevice          	:= GetProcAddress(r_module, 'BASS_SetDevice');
	@r_getDevice	      	:= GetProcAddress(r_module, 'BASS_GetDevice');
{$IFDEF BASS_AFTER_20 }
	// removed in 2.1
{$ELSE }
	@r_musicSetVolume	:= GetProcAddress(r_module, 'BASS_MusicSetVolume');
	@r_musicGetVolume	:= GetProcAddress(r_module, 'BASS_MusicGetVolume');
{$ENDIF }
	@r_streamCreateFileUser	:= GetProcAddress(r_module, 'BASS_StreamCreateFileUser');
	@r_recordSetDevice	:= GetProcAddress(r_module, 'BASS_RecordSetDevice');
	@r_recordGetDevice	:= GetProcAddress(r_module, 'BASS_RecordGetDevice');
	@r_channelGetDevice	:= GetProcAddress(r_module, 'BASS_ChannelGetDevice');
	@r_channelGetInfo	:= GetProcAddress(r_module, 'BASS_ChannelGetInfo');
{$ENDIF } // 2.0
	//
{$IFDEF BASS_AFTER_20 }
	// new in 2.1
	@r_channelSetFlags	:= GetProcAddress(r_module, 'BASS_ChannelSetFlags');
	@r_channelPreBuf	:= GetProcAddress(r_module, 'BASS_ChannelPreBuf');
	@r_channelPlay	        := GetProcAddress(r_module, 'BASS_ChannelPlay');
{$ENDIF } // 2.1
{$IFDEF BASS_AFTER_22 }
	@r_pluginLoad 		:= GetProcAddress(r_module, 'BASS_PluginLoad');
	@r_pluginFree 	 	:= GetProcAddress(r_module, 'BASS_PluginFree');
	@r_pluginGetInfo 	:= GetProcAddress(r_module, 'BASS_PluginGetInfo');
{$ENDIF } // 2.3
	//
	//
	if (
	    assigned(r_getVersion) and
	    assigned(r_getDeviceDescription) and
{$IFDEF BASS_AFTER_18 }
	    // removed in 2.0
{$ELSE }
	    assigned(r_setBufferLength) and
	    assigned(r_setGlobalVolumes) and
	    assigned(r_getGlobalVolumes) and
	    assigned(r_setLogCurves) and
	    assigned(r_set3DAlgorithm) and
{$ENDIF }
	    assigned(r_errorGetCode) and
	    assigned(r_init) and
	    assigned(r_free) and
	    assigned(r_getDSoundObject) and
	    assigned(r_getInfo) and
	    assigned(r_getCPU) and
	    assigned(r_start) and
	    assigned(r_stop) and
	    assigned(r_pause) and
	    assigned(r_setVolume) and
	    assigned(r_getVolume) and
	    assigned(r_set3DFactors) and
	    assigned(r_get3DFactors) and
	    assigned(r_set3DPosition) and
	    assigned(r_get3DPosition) and
	    assigned(r_apply3D) and
	    assigned(r_setEAXParameters) and
	    assigned(r_getEAXParameters) and
	    //
	    assigned(r_musicLoad) and
	    assigned(r_musicFree) and
{$IFDEF BASS_AFTER_22 }
{$ELSE }
            // fucked in 2.3
	    assigned(r_musicGetName) and
{$ENDIF }
{$IFDEF BASS_BEFORE_22 }
	    // removed in 2.2
	    assigned(r_musicGetLength) and
{$ENDIF }	    
{$IFDEF BASS_AFTER_20 }
	    // removed in 2.1
{$ELSE }	    
	    assigned(r_musicPlay) and
	    assigned(r_musicPlayEx) and
	    assigned(r_musicSetAmplify) and
	    assigned(r_musicSetPanSep) and
	    assigned(r_musicSetPositionScaler) and
{$ENDIF }
            //
{$IFDEF BASS_AFTER_20 }
	    // new in 2.1
	    assigned(r_musicSetAttribute) and
	    assigned(r_musicGetAttribute) and
{$ENDIF }
	    //
	    assigned(r_sampleLoad) and
	    assigned(r_sampleCreate) and
	    assigned(r_sampleCreateDone) and
	    assigned(r_sampleFree) and
	    assigned(r_sampleGetInfo) and
	    assigned(r_sampleSetInfo) and
{$IFDEF BASS_AFTER_20 }
	    // new in 2.1
	    assigned(r_sampleGetChannel) and
{$ENDIF }
	    //
{$IFDEF BASS_AFTER_20 }
            // removed in 2.1
{$ELSE}
	    assigned(r_samplePlay) and
	    assigned(r_samplePlayEx) and
	    assigned(r_samplePlay3D) and
	    assigned(r_samplePlay3DEx) and
{$ENDIF }
	    //
	    assigned(r_sampleStop) and
	    //
	    assigned(r_streamCreate) and
	    assigned(r_streamCreateFile) and
	    assigned(r_streamFree) and
{$IFDEF BASS_BEFORE_22 }
	    // removed in 2.2
	    assigned(r_streamGetLength) and
{$ENDIF }	    
{$IFDEF BASS_AFTER_20 }
	    // removed in 2.1
{$ELSE}
	    assigned(r_streamPlay) and
{$ENDIF }
	    //
{$IFDEF BASS_AFTER_18 }
	    // removed in 2.0
{$ELSE }
	    assigned(r_CDInit) and
	    assigned(r_CDFree) and
	    assigned(r_CDInDrive) and
	    assigned(r_CDPlay) and
	    //
	    assigned(r_channelGetFlags) and
{$ENDIF }
	    assigned(r_channelStop) and
	    assigned(r_channelPause) and
{$IFDEF BASS_AFTER_20 }
            // removed in 2.1
{$ELSE }
	    assigned(r_channelResume) and
{$ENDIF }
	    assigned(r_channelSetAttributes) and
	    assigned(r_channelGetAttributes) and
	    assigned(r_channelSet3DAttributes) and
	    assigned(r_channelGet3DAttributes) and
	    assigned(r_channelSet3DPosition) and
	    assigned(r_channelGet3DPosition) and
	    assigned(r_channelSetPosition) and
	    assigned(r_channelGetPosition) and
	    assigned(r_channelGetLevel) and
	    assigned(r_channelGetData) and
	    assigned(r_channelSetSync) and
	    assigned(r_channelRemoveSync) and
	    //
	    assigned(r_channelSetDSP) and
	    assigned(r_channelRemoveDSP) and
	    assigned(r_channelSetEAXMix) and
	    assigned(r_channelGetEAXMix) and

	    // new in v0.9
	    assigned(r_streamGetFilePosition) and
{$IFDEF BASS_AFTER_18 }
	    // removed in 2.0
{$ELSE }
	    assigned(r_CDGetTracks) and
	    assigned(r_CDGetTrackLength) and
{$ENDIF }
	    assigned(r_channelIsActive) and

	    // v1.1
{$IFDEF BASS_AFTER_18 }
	    // removed in 2.0
{$ELSE }
	    assigned(r_CDGetID) and
{$ENDIF }
	    assigned(r_channelSetFX) and
	    assigned(r_channelRemoveFX) and
	    assigned(r_FXSetParameters) and
	    assigned(r_FXGetParameters) and

	    // v1.2
	    assigned(r_channelSetLink) and
	    assigned(r_channelRemoveLink) and
{$IFDEF BASS_AFTER_20 }
	    // removed in 2.1
{$ELSE }
	    assigned(r_MusicPreBuf) and
	    assigned(r_StreamPreBuf) and
{$ENDIF }	    

	    // v1.3
	    assigned(r_update) and
{$IFDEF BASS_AFTER_22 }
	    assigned(r_channelGetTags) and
{$ELSE }
	    assigned(r_streamGetTags) and
{$ENDIF }
	    assigned(r_streamCreateURL) and
	    assigned(r_channelBytes2Seconds) and
	    assigned(r_channelSeconds2Bytes) and

	    // v1.4
{$IFDEF BASS_AFTER_18 }
	    // removed in 2.0
{$ELSE }
	    assigned(r_setCLSID) and
	    assigned(r_musicSetChannelVol) and
	    assigned(r_musicGetChannelVol) and
{$ENDIF }
	    // v1.5
	    assigned(r_recordGetDeviceDescription) and
	    assigned(r_recordInit) and
	    assigned(r_recordFree) and
	    assigned(r_recordGetInfo) and
	    assigned(r_recordStart) and

	    // v1.6
{$IFDEF BASS_AFTER_18 }
	    // removed in 2.0
{$ELSE }
	    assigned(r_CDDoor) and
{$ENDIF }
	    assigned(r_recordGetInputName) and
	    assigned(r_recordSetInput) and
	    assigned(r_recordGetInput) and

	    // v1.7
{$IFDEF BASS_AFTER_18 }
	    // removed in 2.0
{$ELSE }
	    assigned(r_setNetConfig) and
{$ENDIF }
	    assigned(r_channelSlideAttributes) and
	    assigned(r_channelIsSliding) and

{$IFDEF BASS_AFTER_18 }
	    // v2.0
	    assigned(r_setConfig) and
	    assigned(r_getConfig) and
	    assigned(r_setDevice) and
	    assigned(r_getDevice) and
{$IFDEF BASS_AFTER_20 }
	    // removed in 2.1
{$ELSE }
	    assigned(r_musicSetVolume) and
	    assigned(r_musicGetVolume) and
{$ENDIF }
	    assigned(r_streamCreateFileUser) and
	    assigned(r_recordSetDevice) and
	    assigned(r_recordGetDevice) and
	    assigned(r_channelGetDevice) and
	    assigned(r_channelGetInfo) and
{$ENDIF } // 2.0
	    //
{$IFDEF BASS_AFTER_20 }
	    // new in 2.1
	    assigned(r_channelSetFlags) and
	    assigned(r_channelPreBuf) and
	    assigned(r_channelPlay) and
{$ENDIF }
{$IFDEF BASS_AFTER_22 }
	    // new in 2.3
	    assigned(r_pluginLoad) and
	    assigned(r_pluginFree) and
	    assigned(r_pluginGetInfo) and
{$ENDIF } // 2.3

	    //
{$IFDEF BASS_AFTER_21 }
  //
  {$IFDEF BASS_AFTER_22 }
	    (BASSVERSION = (r_getVersion() shr 16))
  {$ELSE }
	    ($20002 = r_getVersion())
  {$ENDIF }
  //
{$ELSE }
	    (true)
{$ENDIF }
	  ) then begin
	  //
	  r_refCount := 1;
	end
	else begin
	  // something is missing, close the library
	  FreeLibrary(r_module);
	  //
	  fillChar(bassProc, sizeOf(bassProc), #0);
	end;
      end;
    end;

    //
    result := (0 <> r_module);
  end;
end;

// --  --
procedure unload_BASS(var bassProc: tBassProc);
begin
  with bassProc do begin
    //
    if (1 = r_refCount) then begin
      //
      if assigned(r_free) then
	r_free(); // make sure we kick out everything
      //
      FreeLibrary(r_module);
      // clean up
      fillChar(bassProc, sizeOf(bassProc), #0);
    end
    else
      dec(r_refCount);
  end;
end;

// --  --
function BASS_EAXPreset(const bassProc: tBassProc; env: int32): BOOL;
const
  envPresets: array[0 .. 3 * (1 + EAX_ENVIRONMENT_COUNT) - 1] of FLOAT = (
    //
    0.5,   1.493, 0.5,                  // 00 - EAX_ENVIRONMENT_GENERIC
    0.25,  0.1,   0,                    // 01 - EAX_ENVIRONMENT_PADDEDCELL
    0.417, 0.4,   0.666,                // 02 - EAX_ENVIRONMENT_ROOM
    0.653, 1.499, 0.166,                // 03 - EAX_ENVIRONMENT_BATHROOM
    0.208, 0.478, 0,                    // 04 - EAX_ENVIRONMENT_LIVINGROOM
    //
    0.5,   2.309, 0.888,                // 05 - EAX_ENVIRONMENT_STONEROOM
    0.403, 4.279, 0.5,                  // 06 - EAX_ENVIRONMENT_AUDITORIUM
    0.5,   3.961, 0.5,                  // 07 - EAX_ENVIRONMENT_CONCERTHALL
    0.5,   2.886, 1.304,                // 08 - EAX_ENVIRONMENT_CAVE
    0.361, 7.284, 0.332,                // 09 - EAX_ENVIRONMENT_ARENA
    //
    0.5,   10.0,  0.3,                  // 10 - EAX_ENVIRONMENT_HANGAR
    0.153, 0.259, 2.0,                  // 11 - EAX_ENVIRONMENT_CARPETEDHALLWAY
    0.361, 1.493, 0,                    // 12 - EAX_ENVIRONMENT_HALLWAY
    0.444, 2.697, 0.638,                // 13 - EAX_ENVIRONMENT_STONECORRIDOR
    0.25,  1.752, 0.776,                // 14 - EAX_ENVIRONMENT_ALLEY
    //
    0.111, 3.145, 0.472,                // 15 - EAX_ENVIRONMENT_FOREST
    0.111, 2.767, 0.224,                // 16 - EAX_ENVIRONMENT_CITY
    0.194, 7.841, 0.472,                // 17 - EAX_ENVIRONMENT_MOUNTAINS
    1,     1.499, 0.5,                  // 18 - EAX_ENVIRONMENT_QUARRY
    0.097, 2.767, 0.224,                // 19 - EAX_ENVIRONMENT_PLAIN
    //
    0.208, 1.652, 1.5,                  // 20 - EAX_ENVIRONMENT_PARKINGLOT
    0.652, 2.886, 0.25,                 // 21 - EAX_ENVIRONMENT_SEWERPIPE
    1,     1.499, 0,                    // 22 - EAX_ENVIRONMENT_UNDERWATER
    0.875, 8.392, 1.388,                // 23 - EAX_ENVIRONMENT_DRUGGED
    0.139, 17.234, 0.666,               // 24 - EAX_ENVIRONMENT_DIZZY
    //
    0.486, 7.563, 0.806,                // 25 - EAX_ENVIRONMENT_PSYCHOTIC
    0,     -1,    -1			// 26 - OFF
  );
begin
  with (bassProc) do begin
    //
    if ((0 <> r_module) and assigned(r_setEAXParameters)) then begin
      //
      case (env) of
	EAX_ENVIRONMENT_GENERIC,
	EAX_ENVIRONMENT_PADDEDCELL,
	EAX_ENVIRONMENT_ROOM,
	EAX_ENVIRONMENT_BATHROOM,
	EAX_ENVIRONMENT_LIVINGROOM,
	EAX_ENVIRONMENT_STONEROOM,
	EAX_ENVIRONMENT_AUDITORIUM,
	EAX_ENVIRONMENT_CONCERTHALL,
	EAX_ENVIRONMENT_CAVE,
	EAX_ENVIRONMENT_ARENA,
	EAX_ENVIRONMENT_HANGAR,
	EAX_ENVIRONMENT_CARPETEDHALLWAY,
	EAX_ENVIRONMENT_HALLWAY,
	EAX_ENVIRONMENT_STONECORRIDOR,
	EAX_ENVIRONMENT_ALLEY,
	EAX_ENVIRONMENT_FOREST,
	EAX_ENVIRONMENT_CITY,
	EAX_ENVIRONMENT_MOUNTAINS,
	EAX_ENVIRONMENT_QUARRY,
	EAX_ENVIRONMENT_PLAIN,
	EAX_ENVIRONMENT_PARKINGLOT,
	EAX_ENVIRONMENT_SEWERPIPE,
	EAX_ENVIRONMENT_UNDERWATER,
	EAX_ENVIRONMENT_DRUGGED,
	EAX_ENVIRONMENT_DIZZY,
	EAX_ENVIRONMENT_PSYCHOTIC:
	  result := r_setEAXParameters(env, envPresets[env * 3 + 0], envPresets[env * 3 + 1], envPresets[env * 3 + 2]);
	else
	  result := r_setEAXParameters(env, envPresets[(EAX_ENVIRONMENT_PSYCHOTIC + 1) * 3 + 0], envPresets[(EAX_ENVIRONMENT_PSYCHOTIC + 1) * 3 + 1], envPresets[(EAX_ENVIRONMENT_PSYCHOTIC + 1) * 3 + 2]);
      end;
    end
    else
      result := false;
    //
  end;	// with..
end;


end.
