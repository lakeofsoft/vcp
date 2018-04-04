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

	  unaVC_script.pas - VC 2.5 Pro scripting component
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
		Lake, Jan-Feb 2008

	----------------------------------------------
*)

{$I unaDef.inc }

{$IFDEF DEBUG }
  {$DEFINE LOG_UNAVC_SCRIPT_INFOS }	// log informational messages
  {$DEFINE LOG_UNAVC_SCRIPT_ERRORS }	// log critical errors
{$ENDIF DEBUG }

{*
  Contains scripting component to be used in Delphi/C++Builder IDE.
  
    @link unavclScriptor component.

  @Author Lake
  
Version 2.5.2008.02 Split from unaVCIDE.pas
}

unit
  unaVC_script;

interface

uses
  Windows, unaTypes, unaClasses,
  Classes, unaVC_pipe, unaVC_wave, unaVC_socks;


// --------------------------
//  -- scriptor component --
// --------------------------

const
  // result codes
  UNAS_HRES_INVALIDSCRIPTSYNTAX		= $301 or (SEVERITY_ERROR shl 31) or (FACILITY_ITF shl 16);	/// Invalid script syntax
  UNAS_HRES_NOTIMPLEMENTED		= $302 or (SEVERITY_ERROR shl 31) or (FACILITY_ITF shl 16);	/// Feature not implemented
  UNAS_HRES_GATEISBUSY			= $303 or (SEVERITY_ERROR shl 31) or (FACILITY_ITF shl 16);	/// Script is busy
  //
  UNAS_HRES_NOSUCHCOMPONENT		= $311 or (SEVERITY_ERROR shl 31) or (FACILITY_ITF shl 16);	/// Component not found
  UNAS_HRES_NOSUCHCOMPONENTPROPERTY	= $312 or (SEVERITY_ERROR shl 31) or (FACILITY_ITF shl 16);	/// Property not found
  UNAS_HRES_INVALIDPROPERTYVALUE	= $313 or (SEVERITY_ERROR shl 31) or (FACILITY_ITF shl 16);	/// Invalid property value
  UNAS_HRES_PROPERTYREADONLY		= $314 or (SEVERITY_ERROR shl 31) or (FACILITY_ITF shl 16);	/// Property is read-only
  //
  UNAS_HRES_INVALIDCOMPONENTINDEX	= $321 or (SEVERITY_ERROR shl 31) or (FACILITY_ITF shl 16);	/// Invalid component index
  //
  UNAS_HRES_UNKNOWNCOMMAND		= $331 or (SEVERITY_ERROR shl 31) or (FACILITY_ITF shl 16);	/// Unknown script command


  {*
	Classes known to scriptor component.
  }
  unaScriptorKnownClasses: array[0..9] of unavclInOutPipeClass = (
    //
    {00}unavclWaveInDevice,
    {01}unavclWaveOutDevice,
    {02}unavclWaveCodecDevice,
    {03}unavclWaveRiff,
    {04}unavclWaveMixer,
    {05}unavclWaveResampler,
    //
    {06}unavclIPClient,
    {07}unavclIPServer,
    {08}unavclIPBroadcastServer,
    {09}unavclIPBroadcastClient
  );

  {*
	Known scriptor commands.
  }
  unaScriptorKnownCommands: array[0..1] of string =
    ('clear', 'pause');


  {*
	Components' properties known to scriptor.
  }
  unaScriptorKnownProperties: array[0..45] of string =
    (
     'className',		// RO: AnsiString	 - all classes
     'name',			// RW: AnsiString	 - all classes

     'availableDataLenIn',	// RO: unsigned	 - all VC classes
     'availableDataLenOut',	// RO: unsigned	 - all VC classes
     'inBytes',			// RO: int64	 - all VC classes
     'outBytes',		// RO: int64	 - all VC classes

     'active',			// RW: bool	 - all VC classes
     'consumer',		// RW: component - all VC classes
     'dumpInput',		// RW: strign	 - all VC classes
     'dumpOutput',		// RW: AnsiString	 - all VC classes
     'isFormatProvider',	// RW: bool      - all VC classes
     'autoActivate',		// RW: bool      - all VC classes

     'onDataAvailable',		// RW: event	 - all VC classes

     'deviceId',		// RW: integer   - all VC WAVE classes
     'formatTag',		// RW: unsigned  - all VC WAVE classes
     'formatTagImmunable',	// RW: bool      - all VC WAVE classes
     'mapped',			// RW: bool      - all VC WAVE classes
     'direct',			// RW: bool      - all VC WAVE classes
     'overNum',			// RW: unsigned  - all VC WAVE classes
     'realTime',		// RW: bool      - all VC WAVE classes
     'loop',                    // RW: bool      - all VC WAVE classes
     'inputIsPcm',		// RW: bool      - all VC WAVE classes
     'pcm_SamplesPerSec',	// RW: unsigned  - all VC WAVE classes
     'pcm_BitsPerSample',	// RW: unsigned  - all VC WAVE classes
     'pcm_NumChannels',		// RW: unsigned  - all VC WAVE classes
     'calcVolume',		// RW: bool      - all VC WAVE classes

     'addSilence',		// RW: bool     - TunavclMixer and TunavclResampler

     'minActiveTime',		// RW: unsigned - TunavclWaveInDevice
     'minVolumeLevel',		// RW: unsigned - TunavclWaveInDevice

     'isInput',			// RW: bool     - TunavclWaveRiff
     'fileName',		// RW: string   - TunavclWaveRiff

     'dst_SamplesPerSec',	// RW: unsigned - TunavclWaveResampler
     'dst_BitsPerSample',       // RW: unsigned - TunavclWaveResampler
     'dst_NumChannels',         // RW: unsigned - TunavclWaveResampler

     'port',			// RW: string   - all VC IP classes

     'host',			// RW: string   - all VC TCP/IP classes
     'proto',			// RW: string   - all VC TCP/IP classes

     'waveFormatTag',		// RW: unsigned - all VC UDP BROADCAST classes
     'waveSamplesPerSec',	// RW: unsigned - all VC UDP BROADCAST classes
     'waveNumChannels',		// RW: unsigned - all VC UDP BROADCAST classes
     'waveNumBits',		// RW: unsigned - all VC UDP BROADCAST classes

     'packetsSent',		// RO: unsigned - TunavclIPBroadcastServer

     'packetsLost',		// RO: unsigned - TunavclIPBroadcastClient
     'packetsReceived',		// RO: unsigned - TunavclIPBroadcastClient
     'remoteHost',		// RO: unsigned - TunavclIPBroadcastClient
     'remotePort'		// RO: unsigned - TunavclIPBroadcastClient
    );

type

{$IFDEF __BEFORE_D5__ }
  HRESULT = LongInt;
{$ENDIF}

  //
  // -- unavclScriptor --
  //

{*

The syntax of VC 2.5 Pro script is simple.

1) Creating a component
2) Assigning property value
3) Special commands
4) General syntax issues

----------------------
1) Creating a component
----------------------

To create a component, specify component's name and the base class you with to create:

<componentName> = <baseClassName>;

For example, to create a recording device component use the following operator:

myRecorder = unavclWaveInDevice;

The following base class names are supported:

  // wave classes
  //
  unavclWaveInDevice 	 - wave in device (recorder) component
  unavclWaveOutDevice 	 - wave out device (playback) component

  unavclWaveCodecDevice	 - Audio Compression Manager (ACM) codec device component
  unavclWaveRiff	 - WAVe reader and writer component
  unavclWaveMixer	 - PCM mixer device component
  unavclWaveResampler	 - PCM resampler device component

  // IP classes
  //
  unavclIPClient	 - IP (TCP/UDP) client component
  unavclIPServer	 - IP (TCP/UDP) server component

  unavclIPBroadcastClient - IP (UDP) broadcast client component
  unavclIPBroadcastServer - IP (UDP) broadcast server component


----------------------------
2) Assigning property values
----------------------------

To assign a value for component's property, use the following operator:

<componentName>.<propertyName> = <value>;

Following properties are supported:

     'className',	        // RO: string	 - all classes
     'name',			// RW: string	 - all classes

     'availableDataLenIn',	// RO: unsigned	 - all VC classes
     'availableDataLenOut',	// RO: unsigned	 - all VC classes
     'inBytes',			// RO: int64	 - all VC classes
     'outBytes',		// RO: int64	 - all VC classes

     'active',			// RW: bool	 - all VC classes
     'consumer',		// RW: component - all VC classes
     'dumpInput',		// RW: strign	 - all VC classes
     'dumpOutput',		// RW: string	 - all VC classes
     'isFormatProvider',	// RW: bool      - all VC classes
     'autoActivate',		// RW: bool      - all VC classes

     'onDataAvailable',		// RW: event	 - all VC classes

     'deviceId',		// RW: integer   - all VC WAVE classes
     'formatTag',		// RW: unsigned  - all VC WAVE classes
     'formatTagImmunable',	// RW: bool      - all VC WAVE classes
     'mapped',			// RW: bool      - all VC WAVE classes
     'direct',			// RW: bool      - all VC WAVE classes
     'overNum',			// RW: unsigned  - all VC WAVE classes
     'realTime',		// RW: bool      - all VC WAVE classes
     'loop',                    // RW: bool      - all VC WAVE classes
     'inputIsPcm',		// RW: bool      - all VC WAVE classes
     'pcm_SamplesPerSec',	// RW: unsigned  - all VC WAVE classes
     'pcm_BitsPerSample',	// RW: unsigned  - all VC WAVE classes
     'pcm_NumChannels',		// RW: unsigned  - all VC WAVE classes
     'calcVolume',		// RW: bool      - all VC WAVE classes

     'addSilence',		// RW: bool      - TunavclMixer and TunavclResampler

     'minActiveTime',		// RW: unsigned  - TunavclWaveInDevice
     'minVolumeLevel',		// RW: unsigned  - TunavclWaveInDevice

     'isInput',			// RW: bool      - TunavclWaveRiff
     'fileName',		// RW: string    - TunavclWaveRiff

     'dst_SamplesPerSec',	// RW: unsigned - TunavclWaveResampler
     'dst_BitsPerSample',       // RW: unsigned  - TunavclWaveResampler
     'dst_NumChannels',         // RW: unsigned  - TunavclWaveResampler

     'port',			// RW: string    - all VC IP classes

     'host',			// RW: string    - all VC TCP/IP classes
     'proto',			// RW: string    - all VC TCP/IP classes

     'waveFormatTag',		// RW: unsigned  - all VC UDP BROADCAST classes
     'waveSamplesPerSec',	// RW: unsigned  - all VC UDP BROADCAST classes
     'waveNumChannels',		// RW: unsigned  - all VC UDP BROADCAST classes
     'waveNumBits',		// RW: unsigned  - all VC UDP BROADCAST classes

     'packetsSent',		// RO: unsigned  - TunavclIPBroadcastServer

     'packetsLost',		// RO: unsigned  - TunavclIPBroadcastClient
     'packetsReceived',		// RO: unsigned  - TunavclIPBroadcastClient
     'remoteHost',		// RO: unsigned  - TunavclIPBroadcastClient
     'remotePort'		// RO: unsigned  - TunavclIPBroadcastClient


To specify boolean value, use 'true' or 'false' keywords, for example:

  myRecorder.active = true;	// activate recorder

This assigns boolean value 'true' to the active property of myRecorder component.

To specify string value, enclose it into ' ' (single quotes).
Double single quote ('') inside the string indicates one single quote.

proto property can has 'TCP' or 'UDP' values only.

You can reference the component by it's name:

  myPlayback = unavclWaveOutDevice;
  myRecorder.consumer = myPlayback;	// link recorder to payback device, making a loop

You can also use 'null' keyword to remove the consumer or destroy the component:

  myRecorder.consumer = null;	// assigns nil to consumer (removes consumer)
  myPlayback = null;		// destroys myPlayback component

-------------------
3) Special commands
-------------------

There are also several commands which executes some special action:

  <command>;

Following commands are recognized:

  clear;		// clears all created components
  pause;		// pauses execution of script for 1 second


------------------------
4) General syntax issues
------------------------

All operators, component names and keywords are NOT case sensitive.

Operators must be terminated by ";" symbol.

Comments should be enclosed in a pair of curved bracers, or started with // sequence.

}

  unavclScriptor = class(tComponent)
  private
    f_errorLine: unsigned;
    //
    //f_gate: unaInProcessGate;
    f_components: unaObjectList;
    //
    f_onSE: tNotifyEvent;
    //
    function getComponentCount(): unsigned;
    function getComponent(index: unsigned): unavclInOutPipe; overload;
    function getComponent(const name: string): unavclInOutPipe; overload;
    //
    function getSetProperty(component: unavclInOutPipe; const propName: string; var value: string; doGet: bool = true): HRESULT;
    function setProperty(var component: unavclInOutPipe; const propName: string; const value: string): HRESULT;
    //
    function enter(timeout: tTimeout = 2000): bool;
    procedure leave();
  protected
    procedure Notification(component: tComponent; operation: tOperation); override;
  public
    procedure AfterConstruction(); override;
    destructor Destroy(); override;
    //
    {*
      Executes the script.

      @param script Script text to execute.

      @return S_OK if no error ocurred.
    }
    function executeScript(const script: string): HRESULT;
    {*
	Returns error string.

	@param code Error code to retrieve error text for.

	@return Error string for specified error code.
    }
    function getErrorCodeString(code: HRESULT): string;
    {*
	Returns component's property.

	@param componentName Specifies component.
	@param propetyName Specifies component's property.
	@param value [OUT] Property value.

	@return S_OK if successfull.
    }
    function getComponentProperty(const componentName, propertyName: string; out value: string): HRESULT;
    {*
	Sets component's property value.

	@param componentName Specifies component.
	@param proprtyName Specifies component's property.
	@param value Property value.

	@return S_OK if successfull.
    }
    function setComponentProperty(const componentName, propertyName: string; const value: string): HRESULT;
    {*
	Returns component name.

	@param index Index of component (from 0 to unavclScriptor.componentCount - 1).
	@param componentName [OUT]Component name.

	@return S_OK if successfull.
    }
    function getComponentName(index: unsigned; out componentName: string): HRESULT;
    {*
	Line number where error ocurred.
    }
    property errorLine: unsigned read f_errorLine;
    {*
      Number of components.
    }
    property componentCount: unsigned read getComponentCount;
  published
    {*
      Fired before script is about to be executed.
    }
    property onScriptExecute: tNotifyEvent read f_onSE write f_onSE;
  end;


implementation


uses
  unaUtils, MMSystem, unaMsAcmClasses,
  unaParsers;


{ unavclScriptor }

// --  --
procedure unavclScriptor.afterConstruction();
begin
  f_components := unaObjectList.create();
  //f_gate := unaInProcessGate.create();
  //
  inherited;
end;

// --  --
destructor unavclScriptor.destroy();
begin
  inherited;
  //
  freeAndNil(f_components);
  //freeAndNil(f_gate);
end;

// --  --
function unavclScriptor.enter(timeout: tTimeout): bool;
begin
  result := f_components.acquire(false, timeout);// f_gate.enter(timeout);
end;

// --  --
function unavclScriptor.executeScript(const script: string): HRESULT;
var
  i: unsigned;
  parser: unaObjectPascalParser;
  token: unaObjectPascalToken;
  mode: int;
  component: unavclInOutPipe;
  //
  componentName: string;
  propertyName: string;
  propertyValue: string;
  command: string;
  commandIndex: unsigned;
begin
  f_errorLine := 0;
  //
  if (assigned(f_onSE)) then
    f_onSE(self);
  //
  mode := 0;
  result := S_OK;
  parser := nil;
  component := nil;
  commandIndex := $FFFFFFFF;
  //
  if (enter()) then begin
    try
      //
      parser := unaObjectPascalParser.create(script);
      while (parser.nextToken()) do begin
	//
	f_errorLine := parser.getLineNum();
	token := parser.token;
	//
	case (token.tokenType) of

	  unaoptEOF: begin
	    //
	    break;
	  end;

	  unaoptIdentifier: begin
	    //
	    case (mode) of

	      0: begin
		//
		command := loCase(token.value);
                //
		for i := low(unaScriptorKnownCommands) to high(unaScriptorKnownCommands) do begin
                  //
		  if (unaScriptorKnownCommands[i] = command) then begin
                    //
		    commandIndex := i;
		    mode := 8;
		    break;
		  end;
                end;
		//
		if (8 <> mode) then begin
                  //
		  componentName := token.value;
		  component := getComponent(token.value);
		  propertyName := token.value;
		  mode := 1;
		end;
		//
		result := UNAS_HRES_INVALIDSCRIPTSYNTAX;
	      end;

	      2: begin
		//
		propertyValue := token.value;
		if (('true' = loCase(propertyValue)) or
		    ('false' = loCase(propertyValue))) then
		  mode := 5
		else
		  mode := 6;
	      end;

	      3: begin
		//
		propertyName := token.value;
		mode := 4;
	      end;

	      7: begin
		//
		propertyValue := propertyValue + '.' + token.value;
		mode := 5;
	      end;

	      else
		break;

	    end;
	  end;

	  unaoptNumber, unaoptChar, unaoptString: begin
	    //
	    case (mode) of

	      2: begin
                //
		propertyValue := token.value;
		mode := 5;
	      end;

	      0: begin
                //
		result := UNAS_HRES_INVALIDSCRIPTSYNTAX
	      end;

	      else
		break;

	    end;
	  end;

	  unaoptPunctuationMark: begin
	    //
	    case (mode) of

	      1: begin
		//
		case (token.get(' ')) of

		  '=': begin
		    mode := 2;
		  end;

		  '.': begin
		    mode := 3;
		  end;

		  else
		    break;	// some problem

		end;
	      end;

	      4: begin
		//
		case (token.get(' ')) of

		  '=': begin
		    mode := 2;
		  end;

		  else
		    break;
		end;
	      end;

	      5, 6, 8: begin
	        //
		case (token.get(' ')) of

		  ';': begin
		    // 5, 6 or 8
		    if (8 = mode) then begin
                      //
		      case (commandIndex) of

			0: begin	// clear
			  //
			  f_components.clear();
			end;

			1: begin	// pause
			  //
			  Sleep(1000);
			end;

			else begin
                          //
			  result := UNAS_HRES_UNKNOWNCOMMAND;
			  break;
			end;

		      end;
		      //
		      mode := 0;
		    end
		    else begin
                      //
		      result := setProperty(component, propertyName, propertyValue);
		      if (not Windows.Succeeded(result)) then
			break
		      else
			mode := 0;
		    end;
		  end;

		  '.': begin
		    // 6 only
		    if (6 = mode) then
		      mode := 7
		    else
		      break;
		  end;

		  else
		    break;
		end;
	      end;

	      else
		break;

	    end;
	  end;

	  unaoptAssigment: begin
            //
	    // ":=" found
	    case (mode) of

	      1: begin
		mode := 2;
	      end;

	      else
		break;
	    end;
	  end;

	  unaoptComment: begin

	  end;

	  unaoptError: begin
            //
	    result := UNAS_HRES_INVALIDSCRIPTSYNTAX;
	    break;
	  end;

	  else
	    break;

	end;
      end;
      //
    finally
      //
      freeAndNil(parser);
      leave();
    end
  end
  else
    result := UNAS_HRES_GATEISBUSY;
end;

// --  --
function unavclScriptor.getComponent(index: unsigned): unavclInOutPipe;
begin
  result := f_components[index];
end;

// --  --
function unavclScriptor.getComponent(const name: string): unavclInOutPipe;
var
  i: int;
  lowName: string;
begin
  i := 0;
  result := nil;
  //
  lowName := loCase(name);
  if ('null' <> lowName) then begin
    //
    if (enter()) then try
      //
      while (i < f_components.count) do begin
	//
	result := getComponent(i);
	if (nil <> result) then begin
	  //
	  if (lowName = loCase(result.name)) then
	    break
	  else
	    result := nil;
	end;    
	//
	inc(i);
      end;
    finally
      leave();
    end;
  end;  
end;

// --  --
function unavclScriptor.getComponentCount(): unsigned;
begin
  result := f_components.count;
end;

// --  --
function unavclScriptor.getComponentName(index: unsigned; out componentName: string): HRESULT;
var
  component: unavclInOutPipe;
begin
  component := getComponent(index);
  //
  if (nil <> component) then begin
    //
    componentName := component.name;
    result := S_OK;
  end
  else
    result := UNAS_HRES_NOSUCHCOMPONENT;
end;

// --  --
function unavclScriptor.getComponentProperty(const componentName, propertyName: string; out value: string): HRESULT;
var
  component: unavclInOutPipe;
begin
  if (enter()) then
    //
    try
      component := getComponent(componentName);
      if (nil <> component) then
	result := getSetProperty(component, loCase(propertyName), value, true)
      else
	result := UNAS_HRES_NOSUCHCOMPONENT;
    finally
      leave();
    end
    //
  else
    result := UNAS_HRES_GATEISBUSY;
end;

// --  --
function unavclScriptor.getErrorCodeString(code: HRESULT): string;
begin
  case (code) of

    UNAS_HRES_INVALIDSCRIPTSYNTAX:
      result := 'Invalid script syntax';

    UNAS_HRES_NOTIMPLEMENTED:
      result := 'Feature not implemented';

    UNAS_HRES_GATEISBUSY:
      result := 'Scriptor gate is busy';

    UNAS_HRES_NOSUCHCOMPONENT:
      result := 'No such component ';

    UNAS_HRES_NOSUCHCOMPONENTPROPERTY:
      result := 'No such property';

    UNAS_HRES_INVALIDPROPERTYVALUE:
      result := 'Invalid property value';

    UNAS_HRES_PROPERTYREADONLY:
      result := 'Property is readonly';

    UNAS_HRES_INVALIDCOMPONENTINDEX:
      result := 'Invalid component index';

    else
      result := 'Unknow error code';
  end;
end;


type
  {*
	Internal class used to access protected members of unavclInOutWavePipe class.
  }
  unavclInOutWavePipe_protected = class(unavclInOutWavePipe)
  end;

// --  --
function unavclScriptor.getSetProperty(component: unavclInOutPipe; const propName: string; var value: string; doGet: bool): HRESULT;
var
  i: unsigned;
  name: string;
begin
  result := S_OK;

  // 00..09
  if ('classname' = propName) then begin
    //
    if (doGet) then
      value := component.className
    else
      result := UNAS_HRES_PROPERTYREADONLY;
    //
  end  
  else
  if ('name' = propName) then
    //
    if (doGet) then
      value := component.name
    else begin
      //
      i := 0;
      if (nil <> getComponent(value)) then begin
	//
	// assign unique name for component
	repeat
	  //
	  name := value + int2str(i);
	  inc(i);
	until (nil = getComponent(name));
      end
      else
	name := value;
      //
      component.name := string(name);
    end
  else
  //
  if ('availabledatalenin' = propName) then
    //
    if (doGet) then
      value := int2str(component.availableDataLenIn)
    else
      result := UNAS_HRES_PROPERTYREADONLY
  else
  //
  if ('availabledatalenout' = propName) then
    //
    if (doGet) then
      value := int2str(component.availableDataLenOut)
    else
      result := UNAS_HRES_PROPERTYREADONLY
  else
  //
  if ('inbytes' = propName) then
    //
    if (doGet) then
      value := int2str(component.inBytes[0])
    else
      result := UNAS_HRES_PROPERTYREADONLY
  else
  //
  if ('outbytes' = propName) then
    //
    if (doGet) then
      value := int2str(component.outBytes[0])
    else
      result := UNAS_HRES_PROPERTYREADONLY
  else
  //
  if ('active' = propName) then
    //
    if (doGet) then
      value := bool2strStr(component.active)
    else
      component.active := strStr2bool(value, false)
  else
  //
  if ('consumer' = propName) then
    //
    if (doGet) then begin
      //
      if (nil <> component.consumer) then
	value := component.consumer.name
      else
	value := 'null';
    end
    else
      component.consumer := getComponent(value)
  else
  //
  if ('dumpinput' = propName) then
    //
    if (doGet) then
      value := component.dumpInput
    else
      component.dumpInput := value
  else
  //
  if ('dumpoutput' = propName) then
    //
    if (doGet) then
      value := component.dumpOutput
    else
      component.dumpOutput := value
  else
  //
  if ('isformatprovider' = propName) then
    //
    if (component is unavclInOutWavePipe) then begin
      //
      if (doGet) then
	value := bool2strStr(unavclInOutWavePipe(component).isFormatProvider)
      else
	unavclInOutWavePipe(component).isFormatProvider := strStr2bool(value, false)
    end
    else
      if (component is unavclInOutIpPipe) then begin
	//
	if (doGet) then
	  value := bool2strStr(unavclInOutIpPipe(component).isFormatProvider)
	else
	  unavclInOutIpPipe(component).isFormatProvider := strStr2bool(value, false)
      end
  else
  //
  if ('autoactivate' = propName) then
    //
    if (doGet) then
      value := bool2strStr(component.autoActivate)
    else
      component.autoActivate := strStr2bool(value, false)
  else
  //
  if ('ondataavailable' = propName) then
    result := UNAS_HRES_NOTIMPLEMENTED
  else

  // 00..05:
  if ('deviceid' = propName) then begin
    //
    if (component is unavclInOutWavePipe) then begin
      //
      if (doGet) then
	value := int2str(unavclInOutWavePipe_protected(component).deviceId)
      else
	unavclInOutWavePipe_protected(component).deviceId := str2intInt(value, -1);
      //
    end
    else
      result := UNAS_HRES_NOSUCHCOMPONENTPROPERTY;
    //
  end  
  else
  //
  if ('formattag' = propName) then
    //
    if (component is unavclInOutWavePipe) then
      //
      if (doGet) then
	value := int2str(unavclInOutWavePipe_protected(component).formatTag)
      else
	unavclInOutWavePipe_protected(component).formatTag := str2intUnsigned(value, WAVE_FORMAT_PCM)
    else
      result := UNAS_HRES_NOSUCHCOMPONENTPROPERTY
  else
  //
  if ('formattagimmunable' = propName) then
    //
    if (component is unavclInOutWavePipe) then
      if (doGet) then
	value := bool2strStr(unavclInOutWavePipe_protected(component).formatTagImmunable)
      else
	unavclInOutWavePipe_protected(component).formatTagImmunable := strStr2bool(value, false)
    else
      result := UNAS_HRES_NOSUCHCOMPONENTPROPERTY
  else
  //
  if ('mapped' = propName) then
    //
    if (component is unavclInOutWavePipe) then
      if (doGet) then
	value := bool2strStr(unavclInOutWavePipe_protected(component).mapped)
      else
	unavclInOutWavePipe_protected(component).mapped := strStr2bool(value, true)
    else
      result := UNAS_HRES_NOSUCHCOMPONENTPROPERTY
  else
  //
  if ('direct' = propName) then
    //
    if (component is unavclInOutWavePipe) then
      if (doGet) then
	value := bool2strStr(unavclInOutWavePipe_protected(component).direct)
      else
	unavclInOutWavePipe_protected(component).direct := strStr2bool(value, false)
    else
      result := UNAS_HRES_NOSUCHCOMPONENTPROPERTY
  else
  //
  if ('overnum' = propName) then
    //
    if (component is unavclInOutWavePipe) then
      if (doGet) then
	value := int2Str(unavclInOutWavePipe_protected(component).overNum)
      else
	unavclInOutWavePipe_protected(component).overNum := str2IntUnsigned(value, 5)
    else
      result := UNAS_HRES_NOSUCHCOMPONENTPROPERTY
  else
  //
  if ('realtime' = propName) then
    //
    if (component is unavclInOutWavePipe) then
      if (doGet) then
	value := bool2strStr(unavclInOutWavePipe_protected(component).realTime)
      else
	unavclInOutWavePipe_protected(component).realTime := strStr2bool(value, true)
    else
      result := UNAS_HRES_NOSUCHCOMPONENTPROPERTY
  else
  //
  if ('loop' = propName) then
    //
    if (component is unavclInOutWavePipe) then
      if (doGet) then
	value := bool2strStr(unavclInOutWavePipe_protected(component).loop)
      else
	unavclInOutWavePipe_protected(component).loop := strStr2bool(value, false)
    else
      result := UNAS_HRES_NOSUCHCOMPONENTPROPERTY
  else
  //
  if ('addsilence' = propName) then
    //
    if (component is unavclInOutWavePipe) then
      if (doGet) then
	value := bool2strStr(unavclInOutWavePipe_protected(component).addSilence)
      else
	unavclInOutWavePipe_protected(component).addSilence := strStr2bool(value, true)
    else
      result := UNAS_HRES_NOSUCHCOMPONENTPROPERTY
  else
  //
  if ('inputispcm' = propName) then
    //
    if (component is unavclInOutWavePipe) then
      if (doGet) then
	value := bool2strStr(unavclInOutWavePipe_protected(component).inputIsPcm)
      else
	unavclInOutWavePipe_protected(component).inputIsPcm := strStr2bool(value, true)
    else
      result := UNAS_HRES_NOSUCHCOMPONENTPROPERTY
  else
  //
  if ('pcm_samplespersec' = propName) then
    //
    if (component is unavclInOutWavePipe) then
      if (doGet) then
	value := int2str(unavclInOutWavePipe_protected(component).pcm_SamplesPerSec)
      else
	unavclInOutWavePipe_protected(component).pcm_SamplesPerSec := str2intUnsigned(value, c_defSamplingSamplesPerSec)
    else
      result := UNAS_HRES_NOSUCHCOMPONENTPROPERTY
  else
  //
  if ('pcm_bitspersample' = propName) then
    //
    if (component is unavclInOutWavePipe) then
      if (doGet) then
	value := int2str(unavclInOutWavePipe_protected(component).pcm_BitsPerSample)
      else
	unavclInOutWavePipe_protected(component).pcm_BitsPerSample := str2intUnsigned(value, c_defSamplingBitsPerSample)
    else
      result := UNAS_HRES_NOSUCHCOMPONENTPROPERTY
  else
  //
  if ('pcm_numchannels' = propName) then
    //
    if (component is unavclInOutWavePipe) then
      if (doGet) then
	value := int2str(unavclInOutWavePipe_protected(component).pcm_NumChannels)
      else
	unavclInOutWavePipe_protected(component).pcm_NumChannels := str2intUnsigned(value, c_defSamplingNumChannels)
    else
      result := UNAS_HRES_NOSUCHCOMPONENTPROPERTY
  else
  //
  if ('calcvolume' = propName) then
    //
    if (component is unavclInOutWavePipe) then
      if (doGet) then
	value := bool2strStr(unavclInOutWavePipe_protected(component).calcVolume)
      else
	unavclInOutWavePipe_protected(component).calcVolume := strStr2bool(value, false)
    else
      result := UNAS_HRES_NOSUCHCOMPONENTPROPERTY
  else

  //
  if ('minactivetime' = propName) then
    //
    if (component is unavclWaveInDevice) then
      if (doGet) then
	value := int2str((component as unavclWaveInDevice).minActiveTime)
      else
	(component as unavclWaveInDevice).minActiveTime := str2intUnsigned(value, 100)
    else
      result := UNAS_HRES_NOSUCHCOMPONENTPROPERTY
  else
  //
  if ('minvolumelevel' = propName) then
    //
    if (component is unavclWaveInDevice) then
      if (doGet) then
	value := int2str((component as unavclWaveInDevice).minVolumeLevel)
      else
	(component as unavclWaveInDevice).minVolumeLevel := str2intUnsigned(value, 0)
    else
      result := UNAS_HRES_NOSUCHCOMPONENTPROPERTY
  else

  // 03:
  if ('isinput' = propName) then
    //
    if (component is unavclWaveRiff) then
      if (doGet) then
	value := bool2strStr((component as unavclWaveRiff).isInput)
      else
	(component as unavclWaveRiff).isInput := strStr2bool(value, true)
    else
      result := UNAS_HRES_NOSUCHCOMPONENTPROPERTY
  else
  //
  if ('filename' = propName) then
    //
    if (component is unavclWaveRiff) then
      if (doGet) then
	value := (component as unavclWaveRiff).fileName
      else
	(component as unavclWaveRiff).fileName := value
    else
      result := UNAS_HRES_NOSUCHCOMPONENTPROPERTY
  else

  // 05:
  if ('dst_samplespersec' = propName) then
    //
    if (component is unavclWaveResampler) then
      if (doGet) then
	value := int2str((component as unavclWaveResampler).dst_samplesPerSec)
      else
	(component as unavclWaveResampler).dst_samplesPerSec := str2intUnsigned(value, c_defSamplingSamplesPerSec)
    else
      result := UNAS_HRES_NOSUCHCOMPONENTPROPERTY
  else
  //
  if ('dst_bitspersample' = propName) then
    //
    if (component is unavclWaveResampler) then
      if (doGet) then
	value := int2str((component as unavclWaveResampler).dst_bitsPerSample)
      else
	(component as unavclWaveResampler).dst_bitsPerSample := str2intUnsigned(value, c_defSamplingBitsPerSample)
    else
      result := UNAS_HRES_NOSUCHCOMPONENTPROPERTY
  else
  //
  if ('dst_numchannels' = propName) then
    //
    if (component is unavclWaveResampler) then
      if (doGet) then
	value := int2str((component as unavclWaveResampler).dst_numChannels)
      else
	(component as unavclWaveResampler).dst_numChannels := str2intUnsigned(value, c_defSamplingNumChannels)
    else
      result := UNAS_HRES_NOSUCHCOMPONENTPROPERTY
  else

  // 06..07
  if ('port' = propName) then
    //
    if (doGet) then
      if (component is unavclInOutIpPipe) then
	value := (component as unavclInOutIpPipe).port
      else
      if (component is unavclIPBroadcastPipe) then
	value := (component as unavclIPBroadcastPipe).port
      else
	result := UNAS_HRES_NOSUCHCOMPONENTPROPERTY
    else
      if (component is unavclInOutIpPipe) then
	(component as unavclInOutIpPipe).port := value
      else
      if (component is unavclIPBroadcastPipe) then
	(component as unavclIPBroadcastPipe).port := value
      else
	result := UNAS_HRES_NOSUCHCOMPONENTPROPERTY
  else
  //
  if ('host' = propName) then
    //
    if (component is unavclIPClient) then
      if (doGet) then
	value := (component as unavclIPClient).host
      else
	(component as unavclIPClient).host := value
    else
      result := UNAS_HRES_NOSUCHCOMPONENTPROPERTY
  else
  //
  if ('proto' = propName) then
    //
    if (component is unavclInOutIpPipe) then
      if (doGet) then
	case ((component as unavclInOutIpPipe).proto) of
	  unapt_TCP:
	    value := 'TCP';
	  unapt_UDP:
	    value := 'UDP';
	  else
	    value := 'UDP';
	end
      else
	if ('tcp' = loCase(value)) then
	  (component as unavclInOutIpPipe).proto := unapt_TCP
	else
	  (component as unavclInOutIpPipe).proto := unapt_UDP
    else
      result := UNAS_HRES_NOSUCHCOMPONENTPROPERTY
  else

  // 08..09
  if ('waveformattag' = propName) then
    //
    if (component is unavclIPBroadcastPipe) then
      if (doGet) then
	value := int2str((component as unavclIPBroadcastPipe).waveFormatTag)
      else
	(component as unavclIPBroadcastPipe).waveFormatTag := str2intUnsigned(value, WAVE_FORMAT_PCM)
    else
      result := UNAS_HRES_NOSUCHCOMPONENTPROPERTY
  else
  //
  if ('wavesamplespersec' = propName) then
    //
    if (component is unavclIPBroadcastPipe) then
      if (doGet) then
	value := int2str((component as unavclIPBroadcastPipe).waveSamplesPerSec)
      else
	(component as unavclIPBroadcastPipe).waveSamplesPerSec := str2intUnsigned(value, c_defSamplingSamplesPerSec)
    else
      result := UNAS_HRES_NOSUCHCOMPONENTPROPERTY
  else
  //
  if ('wavenumchannels' = propName) then
    //
    if (component is unavclIPBroadcastPipe) then
      if (doGet) then
	value := int2str((component as unavclIPBroadcastPipe).waveNumChannels)
      else
	(component as unavclIPBroadcastPipe).waveNumChannels := str2intUnsigned(value, c_defSamplingNumChannels)
    else
      result := UNAS_HRES_NOSUCHCOMPONENTPROPERTY
  else
  //
  if ('wavenumbits' = propName) then
    //
    if (component is unavclIPBroadcastPipe) then
      if (doGet) then
	value := int2str((component as unavclIPBroadcastPipe).waveNumBits)
      else
	(component as unavclIPBroadcastPipe).waveNumBits := str2intUnsigned(value, c_defSamplingBitsPerSample)
    else
      result := UNAS_HRES_NOSUCHCOMPONENTPROPERTY
  else

  if ('packetsSent' = propName) then
    //
    if (component is unavclIPBroadcastServer) then
      if (doGet) then
	value := int2str((component as unavclIPBroadcastServer).packetsSent)
      else
	result := UNAS_HRES_PROPERTYREADONLY
    else
      result := UNAS_HRES_NOSUCHCOMPONENTPROPERTY
  else
  //
  if ('packetslost' = propName) then
    //
    if (component is unavclIPBroadcastClient) then
      if (doGet) then
	value := int2str((component as unavclIPBroadcastClient).packetsLost)
      else
	result := UNAS_HRES_PROPERTYREADONLY
    else
      result := UNAS_HRES_NOSUCHCOMPONENTPROPERTY
  else
  //
  if ('packetsreceived' = propName) then
    //
    if (component is unavclIPBroadcastClient) then
      if (doGet) then
	value := int2str((component as unavclIPBroadcastClient).packetsReceived)
      else
	result := UNAS_HRES_PROPERTYREADONLY
    else
      result := UNAS_HRES_NOSUCHCOMPONENTPROPERTY
  else
  //
  if ('remotehost' = propName) then
    //
    if (component is unavclIPBroadcastClient) then
      if (doGet) then
	value := int2str((component as unavclIPBroadcastClient).remoteHost)
      else
	result := UNAS_HRES_PROPERTYREADONLY
    else
      result := UNAS_HRES_NOSUCHCOMPONENTPROPERTY
  else
  //
  if ('remoteport' = propName) then
    //
    if (component is unavclIPBroadcastClient) then
      if (doGet) then
	value := int2Str((component as unavclIPBroadcastClient).remotePort)
      else
	result := UNAS_HRES_PROPERTYREADONLY
    else
      result := UNAS_HRES_NOSUCHCOMPONENTPROPERTY

  //
  else
    result := UNAS_HRES_NOSUCHCOMPONENTPROPERTY;
end;

// --  --
procedure unavclScriptor.leave();
begin
  //f_gate.leave();
  f_components.releaseWO();
end;

// --  --
procedure unavclScriptor.notification(component: tComponent; operation: tOperation);
begin
  inherited;
  //
  if (opRemove = operation) then
    f_components.removeItem(component);
end;

// --  --
function unavclScriptor.setComponentProperty(const componentName, propertyName, value: string): HRESULT;
var
  component: unavclInOutPipe;
begin
  if (enter()) then
    //
    try
      component := getComponent(componentName);
      if (nil <> component) then
	result := setProperty(component, propertyName, value)
      else
	result := UNAS_HRES_NOSUCHCOMPONENT;
    finally
      leave();
    end
    //
  else
    result := UNAS_HRES_GATEISBUSY;
end;

// --  --
function unavclScriptor.setProperty(var component: unavclInOutPipe; const propName, value: string): HRESULT;
var
  lowValue: string;
  i: unsigned;
  theClass: unavclInOutPipeClass;
  theValue: string;
begin
  theClass := nil;
  lowValue := loCase(value);
  //
  for i := low(unaScriptorKnownClasses) to high(unaScriptorKnownClasses) do begin
    //
    if (loCase(unaScriptorKnownClasses[i].className) = lowValue) then begin
      //
      theClass := unaScriptorKnownClasses[i];
      break;
    end;
  end;
  //
  lowValue := loCase(propName);
  if (('' = propName) or (nil <> theClass)) then begin
    // create new component
    if ((nil = component) and (nil = theClass)) then begin
      //
      result := UNAS_HRES_NOSUCHCOMPONENT;
    end
    else begin
      //
      freeAndNil(component);
      //
      if (nil <> theClass) then begin
	component := theClass.create(nil);  // if we use self instead of nil here,
					    // components will be destroyed without notification..
	component.name := propName;
	case (i) of

	  0..5:
	    (component as unavclInOutWavePipe).createDevice();

	end;
	//
	f_components.add(component);
      end;
      //
      result := S_OK;
    end
  end
  else begin
    //
    if (nil = component) then begin
      result := UNAS_HRES_NOSUCHCOMPONENT;
    end
    else begin
      //
      theValue := value;
      result := getSetProperty(component, lowValue, theValue, false);
    end;
  end;
end;



initialization

{$IFDEF LOG_UNAVC_SCRIPT_INFOS }
  logMessage('unaVC_script - DEBUG is defined.');
{$ENDIF LOG_UNAVC_SCRIPT_INFOS }

end.

