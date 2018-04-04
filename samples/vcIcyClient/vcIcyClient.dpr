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

	  vcIcyClient.dpr
	  Icy Streaming Client Demo application - project source

	----------------------------------------------
	  Copyright (c) 2003-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 19 May 2003

	  modified by:
		Lake, May 2003
		Lake, Oct 2005
		Lake, Feb 2006

	----------------------------------------------
*)

{$I unaDef.inc}

program
  vcIcyClient;

uses
  Forms,
  u_icy_client in 'u_icy_client.pas' {c_form_main},
  u_icy_clientStreamConfig in 'u_icy_clientStreamConfig.pas' {c_form_streamerConfig},
  u_icy_clientListenConfig in 'u_icy_clientListenConfig.pas' {c_form_lstConfig},
  u_common_audioConfig in '..\common\u_common_audioConfig.pas' {c_form_common_audioConfig};

{$R *.res}

// tell we are OK with XP themes
{$IFDEF __BEFORE_D7__ }
  {$R unaWindowsXP.res }	
{$ELSE }
  {$R WindowsXP.res }	
{$ENDIF __BEFORE_D7__ }

begin
  Application.Initialize;
  Application.Title := 'VC 2.5 Pro  -  SHOUTCast/IceCast Client demo';
  Application.CreateForm(Tc_form_main, c_form_main);
  Application.CreateForm(Tc_form_streamerConfig, c_form_streamerConfig);
  Application.CreateForm(Tc_form_lstConfig, c_form_lstConfig);
  Application.CreateForm(Tc_form_common_audioConfig, c_form_common_audioConfig);
  Application.Run;
end.

