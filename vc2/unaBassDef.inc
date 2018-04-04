
{$IFDEF NO_BASS_VER_DEFINE }

  // do not define BASS version here, it was already defined elsewhere

{$ELSE}

  // Since BASS 2.0 is out, this symbol is defined by default.
  // Undefine it if you wish to stay with earlier versions of BASS.
  // -------------------
  {$DEFINE BASS_AFTER_18 }	// define to link with BASS 2.0 or higher
  // -------------------
  //
  {$IFDEF BASS_AFTER_18 }
    //
    // Since BASS 2.1 is out, this symbol is defined by default.
    // Undefine it if you wish to stay with earlier versions of BASS.
    // -------------------
    {$DEFINE BASS_AFTER_20 }	// define to link with BASS 2.1 or higher
    // -------------------
    //
    {$IFDEF BASS_AFTER_20 }
      //
      // Since BASS 2.2 is out, this symbol is defined by default.
      // Undefine it if you wish to stay with earlier versions of BASS.
      // -------------------
      {$DEFINE BASS_AFTER_21 }	// define to link with BASS 2.2 or higher
      // -------------------
      //
      {$IFDEF BASS_AFTER_21 }
	//
	// Since BASS 2.3 is out, this symbol is defined by default.
	// Undefine it if you wish to stay with earlier versions of BASS.
	// -------------------
	{$DEFINE BASS_AFTER_22 }	// define to link with BASS 2.3 or higher
	// -------------------
	//
      {$ENDIF }
    {$ENDIF }
  {$ENDIF }


  {$IFNDEF BASS_AFTER_18 }
    //
    {$DEFINE BASS_BEFORE_20 }
    {$DEFINE BASS_BEFORE_21 }
    {$DEFINE BASS_BEFORE_22 }
    {$DEFINE BASS_BEFORE_23 }
  {$ENDIF }
  //
  {$IFNDEF BASS_AFTER_20 }
    //
    {$DEFINE BASS_BEFORE_21 }
    {$DEFINE BASS_BEFORE_22 }
    {$DEFINE BASS_BEFORE_23 }
  {$ENDIF }
  //
  {$IFNDEF BASS_AFTER_21 }
    //
    {$DEFINE BASS_BEFORE_22 }
    {$DEFINE BASS_BEFORE_23 }
  {$ENDIF }
  //
  {$IFNDEF BASS_AFTER_22 }
    //
    {$DEFINE BASS_BEFORE_23 }
  {$ENDIF }


{$ENDIF}

