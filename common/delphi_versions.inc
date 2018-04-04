
{$IFDEF FPC }

//
// -- cannot use in Delphi ;( --
//
//    {$IF (fpc_version = 2) and (fpc_release < 7) }
//        {$DEFINE FPC_BEFORE_2_7 }
//    {$ENDIF }
//

    {$IFDEF VER2_0 }
        {$DEFINE FPC_BEFORE_2_7 }
    {$ENDIF VER2_0 }
    {$IFDEF VER2_2 }
        {$DEFINE FPC_BEFORE_2_7 }
    {$ENDIF VER2_2 }

{$ELSE }

// --  --

{$IFDEF VER90 }
  // Delphi 2.0
  {$DEFINE __BEFORE_D3__ }	// Not Delphi 3.0 yet
  {$DEFINE __BEFORE_D4__ }	// Not Delphi 4.0 yet
  {$DEFINE __BEFORE_D5__ }	// Not Delphi 5.0 yet
  {$DEFINE __BEFORE_D6__ }	// Not Delphi 6.0 yet
  {$DEFINE __BEFORE_D7__ }	// Not Delphi 7.0 yet
  {$DEFINE __BEFORE_D8__ }	// Not Delphi 8.0 yet
  {$DEFINE __BEFORE_D9__ }	// Not Delphi 2005 yet
  {$DEFINE __BEFORE_DA__ }	// Not Delphi 2006 yet
  {$DEFINE __BEFORE_DB__ }	// Not Delphi 2007 yet
  {$DEFINE __BEFORE_DC__ }	// Not Delphi 2009 yet
  {$DEFINE __BEFORE_DD__ }	// Not Delphi 2010 yet
  {$DEFINE __BEFORE_DE__ }	// Not Delphi XE yet
  {$DEFINE __BEFORE_DF__ }	// Not Delphi XE2 yet
  {$DEFINE __BEFORE_XE3__ }	// Not Delphi XE3 (or later) yet
  {$DEFINE __STRANSI__ }    // ANSI Only Delphi
  //
  {$DEFINE __AFTER_D1__ }	// Delphi 2.0 or later
{$ELSE }
  {$IFDEF VER100 }
    // Delphi 3.0
    {$DEFINE __BEFORE_D4__ }	// Not Delphi 4.0 yet
    {$DEFINE __BEFORE_D5__ }	// Not Delphi 5.0 yet
    {$DEFINE __BEFORE_D6__ }	// Not Delphi 6.0 yet
    {$DEFINE __BEFORE_D7__ }	// Not Delphi 7.0 yet
    {$DEFINE __BEFORE_D8__ }	// Not Delphi 8.0 yet
    {$DEFINE __BEFORE_D9__ }	// Not Delphi 2005 yet
    {$DEFINE __BEFORE_DA__ }	// Not Delphi 2006 yet
    {$DEFINE __BEFORE_DB__ }	// Not Delphi 2007 yet
    {$DEFINE __BEFORE_DC__ }	// Not Delphi 2009 yet
    {$DEFINE __BEFORE_DD__ }	// Not Delphi 2010 yet
    {$DEFINE __BEFORE_DE__ }	// Not Delphi XE yet
    {$DEFINE __BEFORE_DF__ }	// Not Delphi XE2 yet
    {$DEFINE __BEFORE_XE3__ }	// Not Delphi XE3 (or later) yet
    {$DEFINE __STRANSI__ }      // ANSI Only Delphi
    //
    {$DEFINE __AFTER_D1__ }	// Delphi 2.0 or later
    {$DEFINE __AFTER_D2__ }	// Delphi 3.0 or later
  {$ELSE }
    {$IFDEF VER110 }
      // CBuilder 3.0
      {$DEFINE __BEFORE_D4__ }
      {$DEFINE __BEFORE_D5__ }
      {$DEFINE __BEFORE_D6__ }
      {$DEFINE __BEFORE_D7__ }
      {$DEFINE __BEFORE_D8__ }
      {$DEFINE __BEFORE_D9__ }
      {$DEFINE __BEFORE_DA__ }
      {$DEFINE __BEFORE_DB__ }
      {$DEFINE __BEFORE_DC__ }	// Not Delphi 2009 yet
      {$DEFINE __BEFORE_DD__ }	// Not Delphi 2010 yet
      {$DEFINE __BEFORE_DE__ }	// Not Delphi XE yet
      {$DEFINE __BEFORE_DF__ }	// Not Delphi XE2 yet
      {$DEFINE __BEFORE_XE3__ }	// Not Delphi XE3 (or later) yet
      {$DEFINE __STRANSI__ }    // ANSI Only Delphi
      //
      {$DEFINE __AFTER_D1__ }
      {$DEFINE __AFTER_D2__ }
    {$ELSE }
      {$IFDEF VER120 }
        // Delphi 4.0
        {$DEFINE __BEFORE_D5__ }
        {$DEFINE __BEFORE_D6__ }
        {$DEFINE __BEFORE_D7__ }
        {$DEFINE __BEFORE_D8__ }
        {$DEFINE __BEFORE_D9__ }
        {$DEFINE __BEFORE_DA__ }
        {$DEFINE __BEFORE_DB__ }
        {$DEFINE __BEFORE_DC__ }	// Not Delphi 2009 yet
        {$DEFINE __BEFORE_DD__ }	// Not Delphi 2010 yet
        {$DEFINE __BEFORE_DE__ }	// Not Delphi XE yet
        {$DEFINE __BEFORE_DF__ }	// Not Delphi XE2 yet
        {$DEFINE __BEFORE_XE3__ }	// Not Delphi XE3 (or later) yet
        {$DEFINE __STRANSI__ }      // ANSI Only Delphi
        //
        {$DEFINE __AFTER_D1__ }
        {$DEFINE __AFTER_D2__ }
        {$DEFINE __AFTER_D3__ }
      {$ELSE }
        {$IFDEF VER130 }
          // Delphi 5.0 / C++ Builder 5.0
          {$DEFINE __BEFORE_D6__ }
          {$DEFINE __BEFORE_D7__ }
          {$DEFINE __BEFORE_D8__ }
          {$DEFINE __BEFORE_D9__ }
          {$DEFINE __BEFORE_DA__ }
          {$DEFINE __BEFORE_DB__ }
          {$DEFINE __BEFORE_DC__ }	// Not Delphi 2009 yet
          {$DEFINE __BEFORE_DD__ }	// Not Delphi 2010 yet
          {$DEFINE __BEFORE_DE__ }	// Not Delphi XE yet
          {$DEFINE __BEFORE_DF__ }	// Not Delphi XE2 yet
          {$DEFINE __BEFORE_XE3__ }	// Not Delphi XE3 (or later) yet
          {$DEFINE __STRANSI__ }    // ANSI Only Delphi
          //
          {$DEFINE __AFTER_D1__ }
          {$DEFINE __AFTER_D2__ }
          {$DEFINE __AFTER_D3__ }
          {$DEFINE __AFTER_D4__ }
        {$ELSE }
          {$IFDEF VER140 }
            // Delphi 6.0 / C++ Builder 6.0
            {$DEFINE __BEFORE_D7__ }
            {$DEFINE __BEFORE_D8__ }
            {$DEFINE __BEFORE_D9__ }
            {$DEFINE __BEFORE_DA__ }
            {$DEFINE __BEFORE_DB__ }
            {$DEFINE __BEFORE_DC__ }	// Not Delphi 2009 yet
            {$DEFINE __BEFORE_DD__ }	// Not Delphi 2010 yet
            {$DEFINE __BEFORE_DE__ }	// Not Delphi XE yet
            {$DEFINE __BEFORE_DF__ }	// Not Delphi XE2 yet
            {$DEFINE __BEFORE_XE3__ }	// Not Delphi XE3 (or later) yet
            {$DEFINE __STRANSI__ }      // ANSI Only Delphi
            //
            {$DEFINE __AFTER_D1__ }
            {$DEFINE __AFTER_D2__ }
            {$DEFINE __AFTER_D3__ }
            {$DEFINE __AFTER_D4__ }
            {$DEFINE __AFTER_D5__ }
          {$ELSE }
            {$IFDEF VER150 }
              // Delphi 7.0
              {$DEFINE __BEFORE_D8__ }
              {$DEFINE __BEFORE_D9__ }
              {$DEFINE __BEFORE_DA__ }
              {$DEFINE __BEFORE_DB__ }
              {$DEFINE __BEFORE_DC__ }	// Not Delphi 2009 yet
              {$DEFINE __BEFORE_DD__ }	// Not Delphi 2010 yet
              {$DEFINE __BEFORE_DE__ }	// Not Delphi XE yet
              {$DEFINE __BEFORE_DF__ }	// Not Delphi XE2 yet
              {$DEFINE __BEFORE_XE3__ }	// Not Delphi XE3 (or later) yet
              {$DEFINE __STRANSI__ }    // ANSI Only Delphi
              //
              {$DEFINE __AFTER_D1__ }
              {$DEFINE __AFTER_D2__ }
              {$DEFINE __AFTER_D3__ }
              {$DEFINE __AFTER_D4__ }
              {$DEFINE __AFTER_D5__ }
              {$DEFINE __AFTER_D6__ }
            {$ELSE }
              {$IFDEF VER160 }
                // Delphi 8.0
                {$DEFINE __BEFORE_D9__ }
                {$DEFINE __BEFORE_DA__ }
                {$DEFINE __BEFORE_DB__ }
                {$DEFINE __BEFORE_DC__ }	// Not Delphi 2009 yet
                {$DEFINE __BEFORE_DD__ }	// Not Delphi 2010 yet
                {$DEFINE __BEFORE_DE__ }	// Not Delphi XE yet
                {$DEFINE __BEFORE_DF__ }	// Not Delphi XE2 yet
                {$DEFINE __BEFORE_XE3__ }	// Not Delphi XE3 (or later) yet
                {$DEFINE __STRANSI__ }      // ANSI Only Delphi
                //
                {$DEFINE __AFTER_D1__ }
                {$DEFINE __AFTER_D2__ }
                {$DEFINE __AFTER_D3__ }
                {$DEFINE __AFTER_D4__ }
                {$DEFINE __AFTER_D5__ }
                {$DEFINE __AFTER_D6__ }
                {$DEFINE __AFTER_D7__ }
              {$ELSE }
                {$IFDEF VER170 }
                  //
                  // Delphi 2005 (D9)
                  {$DEFINE __BEFORE_DA__ }
                  {$DEFINE __BEFORE_DB__ }
                  {$DEFINE __BEFORE_DC__ }	// Not Delphi 2009 yet
                  {$DEFINE __BEFORE_DD__ }	// Not Delphi 2010 yet
                  {$DEFINE __BEFORE_DE__ }	// Not Delphi XE yet
                  {$DEFINE __BEFORE_DF__ }	// Not Delphi XE2 yet
                  {$DEFINE __BEFORE_XE3__ }	// Not Delphi XE3 (or later) yet
                  {$DEFINE __STRANSI__ }    // ANSI Only Delphi
                  //
                  {$DEFINE __AFTER_D1__ }
                  {$DEFINE __AFTER_D2__ }
                  {$DEFINE __AFTER_D3__ }
                  {$DEFINE __AFTER_D4__ }
                  {$DEFINE __AFTER_D5__ }
                  {$DEFINE __AFTER_D6__ }
                  {$DEFINE __AFTER_D7__ }
                  {$DEFINE __AFTER_D8__ }
                {$ELSE }
                  {$IFDEF VER180 }
                    //
                    {$DEFINE __BEFORE_DC__ }	// Not Delphi 2009 yet
                    {$DEFINE __BEFORE_DD__ }	// Not Delphi 2010 yet
                    {$DEFINE __BEFORE_DE__ }	// Not Delphi XE yet
                    {$DEFINE __BEFORE_DF__ }	// Not Delphi XE2 yet
                    {$DEFINE __BEFORE_XE3__ }	// Not Delphi XE3 (or later) yet
                    {$DEFINE __STRANSI__ }      // ANSI Only Delphi
                    //
                    // Delphi 2006 (DA) or Delphi 2007 (DB),
                    // fortunately we can use VER185 (see below)
                    //
                    {$DEFINE __AFTER_D1__ }  	// Delphi 2.0 or later
                    {$DEFINE __AFTER_D2__ }  	// Delphi 3.0 or later
                    {$DEFINE __AFTER_D3__ }  	// Delphi 4.0 or later
                    {$DEFINE __AFTER_D4__ }  	// Delphi 5.0 or later
                    {$DEFINE __AFTER_D5__ }  	// Delphi 6.0 or later
                    {$DEFINE __AFTER_D6__ }  	// Delphi 7.0 or later
                    {$DEFINE __AFTER_D7__ }  	// Delphi 8.0 or later
                    {$DEFINE __AFTER_D8__ }  	// Delphi 2005 or later
                    {$DEFINE __AFTER_D9__ }	    // Delphi 2006 or later
                    //
                    {$IFDEF VER185 }
                      // Delphi 2007 (11.0) defines both VER180 and VER185 while Delphi 2006 defines VER180 only
                      {$DEFINE __AFTER_DA__ }	// Delphi 2007 or later
                    {$ELSE }
                      {$DEFINE __BEFORE_DB__ }	// Not Delphi 2007 yet
                      //
                      {$DEFINE __STRANSI__ }    // ANSI Only Delphi
                    {$ENDIF VER185 }
                  {$ELSE }
                    //
                    {$IFDEF VER190 }
                      // Delphi 2008? (never released)
                    {$ELSE }
                      {$IFDEF VER200 }
                        //
                        // Delphi 2009 (DC)
                        //
                        {$DEFINE __BEFORE_DD__ }	// Not Delphi 2010 yet
                        {$DEFINE __BEFORE_DE__ }	// Not Delphi XE yet
                        {$DEFINE __BEFORE_DF__ }	// Not Delphi XE2 yet
                        {$DEFINE __BEFORE_XE3__ }	// Not Delphi XE3 (or later) yet
                        //
                        {$DEFINE __AFTER_D1__ }  	// Delphi 2.0 or later
                        {$DEFINE __AFTER_D2__ }  	// Delphi 3.0 or later
                        {$DEFINE __AFTER_D3__ }  	// Delphi 4.0 or later
                        {$DEFINE __AFTER_D4__ }  	// Delphi 5.0 or later
                        {$DEFINE __AFTER_D5__ }  	// Delphi 6.0 or later
                        {$DEFINE __AFTER_D6__ }  	// Delphi 7.0 or later
                        {$DEFINE __AFTER_D7__ }  	// Delphi 8.0 or later
                        {$DEFINE __AFTER_D8__ }  	// Delphi 2005 or later
                        {$DEFINE __AFTER_D9__ }	    // Delphi 2006 or later
                        {$DEFINE __AFTER_DA__ }	    // Delphi 2007 or later
                        {$DEFINE __AFTER_DB__ }	    // Delphi 2009 or later
                        //
                      {$ELSE }
                        {$IFDEF VER210 }
                          //
                          // Delphi 2010 (DD)
                          //
                          {$DEFINE __BEFORE_DE__ }	// Not Delphi XE yet
                          {$DEFINE __BEFORE_DF__ }	// Not Delphi XE2 yet
                          {$DEFINE __BEFORE_XE3__ }	// Not Delphi XE3 (or later) yet
                          //
                          {$DEFINE __AFTER_D1__ }  	// Delphi 2.0 or later
                          {$DEFINE __AFTER_D2__ }  	// Delphi 3.0 or later
                          {$DEFINE __AFTER_D3__ }  	// Delphi 4.0 or later
                          {$DEFINE __AFTER_D4__ }  	// Delphi 5.0 or later
                          {$DEFINE __AFTER_D5__ }  	// Delphi 6.0 or later
                          {$DEFINE __AFTER_D6__ }  	// Delphi 7.0 or later
                          {$DEFINE __AFTER_D7__ }  	// Delphi 8.0 or later
                          {$DEFINE __AFTER_D8__ }  	// Delphi 2005 or later
                          {$DEFINE __AFTER_D9__ }	// Delphi 2006 or later
                          {$DEFINE __AFTER_DA__ }	// Delphi 2007 or later
                          {$DEFINE __AFTER_DB__ }	// Delphi 2009 or later
                          {$DEFINE __AFTER_DC__ }	// Delphi 2010 or later
                        {$ELSE }
                          {$IFDEF VER220 }
                            //
                            // Delphi XE (DE)
                            {$DEFINE __BEFORE_DF__ }	// Not Delphi XE2 yet
                            {$DEFINE __BEFORE_XE3__ }	// Not Delphi XE3 (or later) yet
                            //
                            {$DEFINE __AFTER_D1__ } // Delphi 2.0 or later
                            {$DEFINE __AFTER_D2__ } // Delphi 3.0 or later
                            {$DEFINE __AFTER_D3__ } // Delphi 4.0 or later
                            {$DEFINE __AFTER_D4__ } // Delphi 5.0 or later
                            {$DEFINE __AFTER_D5__ } // Delphi 6.0 or later
                            {$DEFINE __AFTER_D6__ } // Delphi 7.0 or later
                            {$DEFINE __AFTER_D7__ } // Delphi 8.0 or later
                            {$DEFINE __AFTER_D8__ } // Delphi 2005 or later
                            {$DEFINE __AFTER_D9__ }	// Delphi 2006 or later
                            {$DEFINE __AFTER_DA__ }	// Delphi 2007 or later
                            {$DEFINE __AFTER_DB__ }	// Delphi 2009 or later
                            {$DEFINE __AFTER_DC__ }	// Delphi 2010 or later
                            {$DEFINE __AFTER_DD__ }	// Delphi XE or later
                          {$ELSE }
                             //
                            {$IFDEF VER230 }
                              //
                              // Delphi XE2 (DF)
                              {$DEFINE __BEFORE_XE3__ }	// Not Delphi XE3 (or later) yet
                              //
                              {$DEFINE __AFTER_D1__ }  	// Delphi 2.0 or later
                              {$DEFINE __AFTER_D2__ }  	// Delphi 3.0 or later
                              {$DEFINE __AFTER_D3__ }  	// Delphi 4.0 or later
                              {$DEFINE __AFTER_D4__ }  	// Delphi 5.0 or later
                              {$DEFINE __AFTER_D5__ }  	// Delphi 6.0 or later
                              {$DEFINE __AFTER_D6__ }  	// Delphi 7.0 or later
                              {$DEFINE __AFTER_D7__ }  	// Delphi 8.0 or later
                              {$DEFINE __AFTER_D8__ }  	// Delphi 2005 or later
                              {$DEFINE __AFTER_D9__ }	// Delphi 2006 or later
                              {$DEFINE __AFTER_DA__ }	// Delphi 2007 or later
                              {$DEFINE __AFTER_DB__ }	// Delphi 2009 or later
                              {$DEFINE __AFTER_DC__ }	// Delphi 2010 or later
                              {$DEFINE __AFTER_DD__ }	// Delphi XE or later
                              {$DEFINE __AFTER_DE__ }	// Delphi XE2 or later
                            {$ELSE }
                              //
                              {$IFDEF VER240 }
                                //
                                // Delphi XE3 (D24)
                                {$DEFINE __AFTER_D1__ } // Delphi 2.0 or later
                                {$DEFINE __AFTER_D2__ } // Delphi 3.0 or later
                                {$DEFINE __AFTER_D3__ } // Delphi 4.0 or later
                                {$DEFINE __AFTER_D4__ } // Delphi 5.0 or later
                                {$DEFINE __AFTER_D5__ } // Delphi 6.0 or later
                                {$DEFINE __AFTER_D6__ } // Delphi 7.0 or later
                                {$DEFINE __AFTER_D7__ } // Delphi 8.0 or later
                                {$DEFINE __AFTER_D8__ } // Delphi 2005 or later
                                {$DEFINE __AFTER_D9__ }	// Delphi 2006 or later
                                {$DEFINE __AFTER_DA__ }	// Delphi 2007 or later
                                {$DEFINE __AFTER_DB__ }	// Delphi 2009 or later
                                {$DEFINE __AFTER_DC__ }	// Delphi 2010 or later
                                {$DEFINE __AFTER_DD__ }	// Delphi XE or later
                                {$DEFINE __AFTER_DE__ }	// Delphi XE2 or later
                                {$DEFINE __AFTER_DF__}	// Delphi XE3 or later

                              {$ELSE }
                                // ... after XE3

                                // Delphi XE4 (D25) or later
                                {$DEFINE __AFTER_D1__ } // Delphi 2.0 or later
                                {$DEFINE __AFTER_D2__ } // Delphi 3.0 or later
                                {$DEFINE __AFTER_D3__ } // Delphi 4.0 or later
                                {$DEFINE __AFTER_D4__ } // Delphi 5.0 or later
                                {$DEFINE __AFTER_D5__ } // Delphi 6.0 or later
                                {$DEFINE __AFTER_D6__ } // Delphi 7.0 or later
                                {$DEFINE __AFTER_D7__ } // Delphi 8.0 or later
                                {$DEFINE __AFTER_D8__ } // Delphi 2005 or later
                                {$DEFINE __AFTER_D9__ }	// Delphi 2006 or later
                                {$DEFINE __AFTER_DA__ }	// Delphi 2007 or later
                                {$DEFINE __AFTER_DB__ }	// Delphi 2009 or later
                                {$DEFINE __AFTER_DC__ }	// Delphi 2010 or later
                                {$DEFINE __AFTER_DD__ }	// Delphi XE or later
                                {$DEFINE __AFTER_DE__ }	// Delphi XE2 or later
                                {$DEFINE __AFTER_DF__ }	// Delphi XE3 or later
                                {$DEFINE __AFTER_XE3__}	// Delphi XE4 or later

                              {$ENDIF VER240 }
                            {$ENDIF VER230 }
                          {$ENDIF VER220 }
                        {$ENDIF VER210 }
                      {$ENDIF VER200 }
                    {$ENDIF VER190 }
                  {$ENDIF VER180 }
                {$ENDIF VER170 }
              {$ENDIF VER160 }
            {$ENDIF VER150 }
          {$ENDIF VER140 }
        {$ENDIF VER130 }
      {$ENDIF VER120 }
    {$ENDIF VER110 }
  {$ENDIF VER100 }
{$ENDIF VER90 }


{$ENDIF FPC }

// --  --
