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

	  unaConfRTPsrv.dpr
	  unaConfRTPsrv application - project source

	----------------------------------------------
	  Copyright (c) 2009-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, Feb 2010

	  modified by:
		Lake, Feb 2010

	----------------------------------------------
*)

{$I unaDef.inc }

program
  unaConfRTPsrv;

uses
  Forms,
  unaUtils,
  u_unaConfRTPsrv_main in 'u_unaConfRTPsrv_main.pas' {c_form_main},
  u_unaConfRTPsrv_srvConfig in 'u_unaConfRTPsrv_srvConfig.pas' {c_form_params};

{$R *.res}

// tell we are OK with XP themes
{$IFDEF __BEFORE_D7__ }
  {$R unaWindowsXP.res }
{$ELSE }
  {$R WindowsXP.res }
{$ENDIF __BEFORE_D7__ }

begin
  Application.Initialize;
  Application.Title := 'VC 2.5 - Conf RTP server';
  Application.CreateForm(Tc_form_main, c_form_main);
  Application.CreateForm(Tc_form_params, c_form_params);
  Application.Run;
end.

