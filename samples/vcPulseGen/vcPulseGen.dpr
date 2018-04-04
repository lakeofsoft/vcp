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

	  u_pulseGen_main.pas
	  Voice Communicator components version 2.5
	  VC Pulse Generator demo application - main form

	----------------------------------------------
	  Copyright (c) 2002-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 03 Aug 2002

	  modified by:
		Lake, Aug 2002
		Lake, Jan-May 2003

	----------------------------------------------
*)

{$I unaDef.inc}

program
  vcPulseGen;

uses
  Forms,
  u_pulseGen_main in 'u_pulseGen_main.pas' {c_pg_main},
  u_vcPulse_main in 'u_vcPulse_main.pas' {c_form_pulse};

{$R *.res}

// tell we are OK with XP themes
{$IFDEF __BEFORE_D7__ }
  {$R unaWindowsXP.res }	
{$ELSE }
  {$R WindowsXP.res }	
{$ENDIF __BEFORE_D7__ }

begin
  Application.Initialize;
  Application.Title := 'VC 2.5 Pro - Pulse Generator demo';
  Application.CreateForm(Tc_pg_main, c_pg_main);
  Application.Run;
end.

