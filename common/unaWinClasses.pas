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

	  unaWinClasses.pas
	  Windows classes

	----------------------------------------------
	  Copyright (c) 2002-2010 Lake of Soft
		     All rights reserved

	  http://lakeofsoft.com/
	----------------------------------------------

	  created by:
		Lake, 19 Mar 2002

	  modified by:
		Lake, Mar 2002
		Lake, Jun-Dec 2002
		Lake, Jan-Dec 2003
		Lake, Jan-Mar 2004
		Lake, Oct 2005
                Lake, Jun 2009

	----------------------------------------------
*)

{$I unaDef.inc}

{*
  Contains standard Windows GUI classes wrappers.

  @Author Lake

  Version 2.5.2009.06 Fixed some unicode-related bugs

  Version 2.5.2008.07 Still here
}


unit
  unaWinClasses;

interface

uses
  Windows, unaTypes, Messages, unaClasses;

resourcestring
  //
  rstr_caption_exit	= 'E&xit';
  rstr_caption_start	= '&Start';
  rstr_caption_stop	= 'S&top';

type

  {*
	This class encapsulates the Windows class object.
  }
  unaWinClass = class(unaObject)
  private
    f_classOwner: bool;
    f_wndClassW: TWNDCLASSEXW;
    f_nameW: wString;
    f_atom: ATOM;
    f_isCommon: bool;
    // subclassing
    f_wasSubclassed: bool;
    f_subClassWnd: hWnd;
    f_oldClassWndProc: int;
  public
    {*
      Creates and registers new Windows class.
    }
    constructor create(const name: string = ''; style: unsigned = 0; icon: hIcon = 0; smallIcon: hIcon = 0; cursor: hCursor = 0; brBrush: hBrush = COLOR_WINDOW + 1; menuName: int = 0; instance: hModule = 0; force: bool = true);
    {*
      Creates and registers new "standard" Windows class, such as BUTTON, EDIT and so on.
    }
    constructor createStdClass(const name: string; instance: hModule = 0);
    destructor Destroy(); override;
    //
    {*
      Registers Windows class.
    }
    function registerClass(force: bool = true): ATOM;
    {*
      Unregisters Windows class.
    }
    procedure unregister();
    {*
      Returns atom received after registering of class. Registers class if necessary.
    }
    function getAtom(): ATOM;	// registers class if necessary
    {*
      Returns pointer on WNDCLASSEX structure corresponding to this class.
    }
    function getWndClassW(): pWNDCLASSEXW;
    {*
      Returns true if class is already registered.
    }
    class function classIsRegistered(const className: string; instance: hModule = 0): bool;
    // subclassing
    {*
      Subclasses the Windows class.
    }
    function createSubclass(mainWnd: hWnd; newWndProc: pointer): bool;
    {*
      Removes subclassing from the class.
    }
    procedure removeSubclass();
    {*
      Calls subclassed WndProc.
    }
    function callSubClassedWndProc(window: hWnd; message, wParam, lParam: int): int;
    {*
      Returns atom received after registering of class.
    }
    property atom: ATOM read f_atom;
    {*
      Returns true if this Windows class was subclassed. 
    }
    property subClassed: bool read f_wasSubclassed;
    {*
      Returns true if this Windows class is common or "standard" class (such as BUTTON, EDIT and so on).  
    }
    property isCommon: bool read f_isCommon;
    //
    property wndClassW: TWNDCLASSEXW read f_wndClassW;
  end;

// for some reason this stuff is not included in Windows.pas

  PChooseFontA = ^TChooseFontA;
  PChooseFontW = ^TChooseFontW;
  PChooseFont = PChooseFontA;
  {$EXTERNALSYM tagCHOOSEFONTA}
  tagCHOOSEFONTA = packed record
    lStructSize: DWORD;
    hWndOwner: HWnd;            { caller's window handle }
    hDC: HDC;                   { printer DC/IC or nil }
    lpLogFont: PLogFontA;     { pointer to a LOGFONT struct }
    iPointSize: Integer;        { 10 * size in points of selected font }
    Flags: DWORD;               { dialog flags }
    rgbColors: COLORREF;        { returned text color }
    lCustData: LPARAM;          { data passed to hook function }
    lpfnHook: function(Wnd: HWND; Message: UINT; wParam: WPARAM; lParam: LPARAM): UINT stdcall;
				{ pointer to hook function }
    lpTemplateName: paChar;    { custom template name }
    hInstance: HINST;       { instance handle of EXE that contains
				  custom dialog template }
    lpszStyle: paChar;         { return the style field here
				  must be lf_FaceSize or bigger }
    nFontType: Word;            { same value reported to the EnumFonts
				  call back with the extra fonttype_
				  bits added }
    wReserved: Word;
    nSizeMin: Integer;          { minimum point size allowed and }
    nSizeMax: Integer;          { maximum point size allowed if
				  cf_LimitSize is used }
  end;
  {$EXTERNALSYM tagCHOOSEFONTW}
  tagCHOOSEFONTW = packed record
    lStructSize: DWORD;
    hWndOwner: HWnd;            { caller's window handle }
    hDC: HDC;                   { printer DC/IC or nil }
    lpLogFont: PLogFontW;     { pointer to a LOGFONT struct }
    iPointSize: Integer;        { 10 * size in points of selected font }
    Flags: DWORD;               { dialog flags }
    rgbColors: COLORREF;        { returned text color }
    lCustData: LPARAM;          { data passed to hook function }
    lpfnHook: function(Wnd: HWND; Message: UINT; wParam: WPARAM; lParam: LPARAM): UINT stdcall;
				{ pointer to hook function }
    lpTemplateName: pwChar;    { custom template name }
    hInstance: HINST;       { instance handle of EXE that contains
				  custom dialog template }
    lpszStyle: pwChar;         { return the style field here
				  must be lf_FaceSize or bigger }
    nFontType: Word;            { same value reported to the EnumFonts
				  call back with the extra fonttype_
				  bits added }
    wReserved: Word;
    nSizeMin: Integer;          { minimum point size allowed and }
    nSizeMax: Integer;          { maximum point size allowed if
				  cf_LimitSize is used }
  end;
  {$EXTERNALSYM tagCHOOSEFONT}
  tagCHOOSEFONT = tagCHOOSEFONTA;
  TChooseFontA = tagCHOOSEFONTA;
  TChooseFontW = tagCHOOSEFONTW;
  TChooseFont = TChooseFontA;

{$EXTERNALSYM ChooseFont}
function ChooseFont(var ChooseFont: TChooseFont): Bool; stdcall;
{$EXTERNALSYM ChooseFontA}
function ChooseFontA(var ChooseFont: TChooseFontA): Bool; stdcall;
{$EXTERNALSYM ChooseFontW}
function ChooseFontW(var ChooseFont: TChooseFontW): Bool; stdcall;

const
  {$EXTERNALSYM CF_SCREENFONTS}
  CF_SCREENFONTS = $00000001;
  {$EXTERNALSYM CF_PRINTERFONTS}
  CF_PRINTERFONTS = $00000002;
  {$EXTERNALSYM CF_BOTH}
  CF_BOTH = CF_SCREENFONTS OR CF_PRINTERFONTS;
  {$EXTERNALSYM CF_SHOWHELP}
  CF_SHOWHELP = $00000004;
  {$EXTERNALSYM CF_ENABLEHOOK}
  CF_ENABLEHOOK = $00000008;
  {$EXTERNALSYM CF_ENABLETEMPLATE}
  CF_ENABLETEMPLATE = $00000010;
  {$EXTERNALSYM CF_ENABLETEMPLATEHANDLE}
  CF_ENABLETEMPLATEHANDLE = $00000020;
  {$EXTERNALSYM CF_INITTOLOGFONTSTRUCT}
  CF_INITTOLOGFONTSTRUCT = $00000040;
  {$EXTERNALSYM CF_USESTYLE}
  CF_USESTYLE = $00000080;
  {$EXTERNALSYM CF_EFFECTS}
  CF_EFFECTS = $00000100;
  {$EXTERNALSYM CF_APPLY}
  CF_APPLY = $00000200;
  {$EXTERNALSYM CF_ANSIONLY}
  CF_ANSIONLY = $00000400;
  {$EXTERNALSYM CF_SCRIPTSONLY}
  CF_SCRIPTSONLY = CF_ANSIONLY;
  {$EXTERNALSYM CF_NOVECTORFONTS}
  CF_NOVECTORFONTS = $00000800;
  {$EXTERNALSYM CF_NOOEMFONTS}
  CF_NOOEMFONTS = CF_NOVECTORFONTS;
  {$EXTERNALSYM CF_NOSIMULATIONS}
  CF_NOSIMULATIONS = $00001000;
  {$EXTERNALSYM CF_LIMITSIZE}
  CF_LIMITSIZE = $00002000;
  {$EXTERNALSYM CF_FIXEDPITCHONLY}
  CF_FIXEDPITCHONLY = $00004000;
  {$EXTERNALSYM CF_WYSIWYG}
  CF_WYSIWYG = $00008000; { must also have CF_SCREENFONTS & CF_PRINTERFONTS }
  {$EXTERNALSYM CF_FORCEFONTEXIST}
  CF_FORCEFONTEXIST = $00010000;
  {$EXTERNALSYM CF_SCALABLEONLY}
  CF_SCALABLEONLY = $00020000;
  {$EXTERNALSYM CF_TTONLY}
  CF_TTONLY = $00040000;
  {$EXTERNALSYM CF_NOFACESEL}
  CF_NOFACESEL = $00080000;
  {$EXTERNALSYM CF_NOSTYLESEL}
  CF_NOSTYLESEL = $00100000;
  {$EXTERNALSYM CF_NOSIZESEL}
  CF_NOSIZESEL = $00200000;
  {$EXTERNALSYM CF_SELECTSCRIPT}
  CF_SELECTSCRIPT = $00400000;
  {$EXTERNALSYM CF_NOSCRIPTSEL}
  CF_NOSCRIPTSEL = $00800000;
  {$EXTERNALSYM CF_NOVERTFONTS}
  CF_NOVERTFONTS = $01000000;

{ these are extra nFontType bits that are added to what is returned to the
  EnumFonts callback routine }

  {$EXTERNALSYM SIMULATED_FONTTYPE}
  SIMULATED_FONTTYPE = $8000;
  {$EXTERNALSYM PRINTER_FONTTYPE}
  PRINTER_FONTTYPE = $4000;
  {$EXTERNALSYM SCREEN_FONTTYPE}
  SCREEN_FONTTYPE = $2000;
  {$EXTERNALSYM BOLD_FONTTYPE}
  BOLD_FONTTYPE = $0100;
  {$EXTERNALSYM ITALIC_FONTTYPE}
  ITALIC_FONTTYPE = $0200;
  {$EXTERNALSYM REGULAR_FONTTYPE}
  REGULAR_FONTTYPE = $0400;

  {$EXTERNALSYM OPENTYPE_FONTTYPE}
  OPENTYPE_FONTTYPE = $10000;
  {$EXTERNALSYM TYPE1_FONTTYPE}
  TYPE1_FONTTYPE = $20000;
  {$EXTERNALSYM DSIG_FONTTYPE}
  DSIG_FONTTYPE = $40000;

  {$EXTERNALSYM WM_CHOOSEFONT_GETLOGFONT}
  WM_CHOOSEFONT_GETLOGFONT = WM_USER + 1;
  {$EXTERNALSYM WM_CHOOSEFONT_SETLOGFONT}
  WM_CHOOSEFONT_SETLOGFONT = WM_USER + 101; { removed in 4.0 SDK }
  {$EXTERNALSYM WM_CHOOSEFONT_SETFLAGS}
  WM_CHOOSEFONT_SETFLAGS   = WM_USER + 102; { removed in 4.0 SDK }

// back to our business

type

  //
  // -- unaWinFont --
  //
  {*
    This class encapsulates the Windows font object.
  }
  unaWinFont = class(unaObject)
  private
    f_font: hFont;
  public
    {*
      Creates new Windows font. Usually you should not care about removing the font, this will be done automatically when program exits.
    }
    constructor create(const face: string = ''; h: int = 16; w: int = 6; escapement: int = 0; orientation: int = 0; weight: int = FW_LIGHT; italic: bool = false; underline: bool = false; strikeout: bool = false; charset: unsigned = DEFAULT_CHARSET; precision: unsigned = OUT_DEFAULT_PRECIS; clipPrecision: unsigned = CLIP_DEFAULT_PRECIS; quality: unsigned = DEFAULT_QUALITY; pitchAndFamily: unsigned = VARIABLE_PITCH or FF_SWISS);
    {*
      Creates new Windows font. Usually you should not care about removing the font, this will be done automatically when program exits.
    }
    constructor createIndirect(const font: LOGFONT);
    {*
      Removes all resources used by this font object.
    }
    destructor Destroy(); override;
    {*
      Chooses a font. Displays font choose dialog. Returns true if used had successfully selected a font, or false otherwise.
    }
    class function chooseScreenFont(var font: LOGFONT; owner: hWnd = 0; dc: hDC = 0; flags: unsigned = CF_SCREENFONTS; sizeMin: unsigned = 0; sizeMax: unsigned = 0): bool;
    {*
      Windows font handle.
    }
    property font: hFont read f_font;
  end;


  //
  // -- unaWinWindow --
  //

const
  // child window position anchors
  // default is LEFT + TOP
  unawinAnchor_LEFT	= $0008;
  unaWinAnchor_RIGHT	= $0004;
  unaWinAnchor_TOP	= $0002;
  unaWinAnchor_BOTTOM	= $0001;

type
  punaWinCreateParams = ^unaWinCreateParams;
  unaWinCreateParams = record
    //
    r_class: unaWinClass;
    r_font: unaWinFont;
    r_captionW: wString;
    r_style: unsigned;
    r_exStyle: unsigned;
    r_x: int;
    r_y: int;
    r_width: int;
    r_height: int;
    r_menu: hMenu;
    r_icon: hIcon;
    case r_parentIsHandle: bool of
      true: (r_winParent: hWnd);
      false: (r_unaParent: tObject);
  end;

  tmessageEvent = function (sender: tObject; wParam, lParam: int): int of object;

  {*
    This class encapsulates Windows window object.
  }
  unaWinWindow = class(unaObject)
  private
    f_createParams: unaWinCreateParams;
    f_notifyParent: unaWinWindow;
    f_winListIndex: int;
    f_handle: hWnd;
    f_dc: hDC;
    f_lastDC: hDC;
    f_anchors: unsigned;
    f_rect: TRECT;
    f_sizeRect: TRECT;
    f_minWidth: int;
    f_minHeight: int;
    f_modalResult: int;
    //
    f_children: unaList;
    f_wmCommand: tmessageEvent;
    //
    procedure removeChild(child: unaWinWindow);
    function getWndClass(): unaWinClass;
    function getParent(): hWnd;
    procedure setWinHandle(h: hWnd);
    procedure setWinListIndex(i: int);
    function selectFont(dc: hDC): unsigned;
    function getFont(): unaWinFont;
    procedure setFFont(value: unaWinFont);
    procedure setFAnchors(value: unsigned);
    function getHeight(): int;
    function getLeft(): int;
    function getTop(): int;
    function getWidth(): int;
    procedure setHeight(value: int);
    procedure setLeft(value: int);
    procedure setTop(value: int);
    procedure setWidth(value: int);
    procedure setMinHeight(value: int);
    procedure setMinWidth(value: int);
    //
    function hasStyle(index: integer): bool;
    function getUnaParent: unaWinWindow;
  protected
    f_isCommonDC: bool;
    //
    function initWindow(): bool; virtual;
    {*
      This is Windows WndProc routine.
    }
    function wndProc(message, wParam, lParam: int): int; virtual;
    {*
      WM_NCACTIVATE message handler.
    }
    function notifyActivate(isActivate: bool): bool; virtual;
    {*
      WM_NCCREATE message handler.
    }
    function notifyCreate(cs: pCREATESTRUCT): bool; virtual;
    {*
      WM_NCDESTROY message handler.
    }
    function notifyDestroy(): bool; virtual;
    {*
      WM_ACTIVATE message handler.
    }
    function onActivate(wayOfActivate: unsigned; window: hWnd): bool; virtual;
    {*
      WM_ACTIVATEAPP message handler.
    }
    function onActivateApp(isActivate: bool; activeThreadId: unsigned): bool; virtual;
    {*
      WM_COMMAND message handler.
    }
    function onCommand(cmd: int; wnd: int): bool; virtual;
    {*
      WM_CREATE message handler.
    }
    function onCreate(cs: pCREATESTRUCT): int; virtual;	// return 0 - OK, -1 - fail
    {*
      WM_DESTROY message handler.
    }
    function onDestroy(): bool; virtual;
    {*
      WM_ENTERSIZEMOVE message handler.
    }
    function onEnterSizeMove(): bool; virtual;
    {*
      WM_GETMINMAXINFO message handler.
    }
    function onGetMinMaxInfo(infO: pMINMAXINFO): bool;
    {*
      WM_GETTEXT message handler.
    }
    function onGetText(buf: paChar; maxSize: unsigned): int; virtual;	// return number of characted copied, or -1 to pass contol to defProc
    {*
      WM_MOVE message handler.
    }
    function onMove(x, y: int): bool; virtual;
    {
    }
    function onClick(button: Word; x, y: word): bool; virtual;
    {
    }
    function onKeyDown(vkCode: unsigned; keyData: int): bool; virtual;
    {*
      WM_PAINT message handler.
    }
    function onPaint(param: int): bool; virtual;
    {*
      WM_WINDOWPOSCHANGING message handler.
    }
    function onPosChange(pos: pWINDOWPOS): bool; virtual;
    {*
      WM_CLOSE message handler.
      Returns true, if window should be closed and destroyed.
      Our handler simply hides the window, not destroying it.
    }
    function onClose(): bool; virtual;
    {*
      WM_SHOW message handler.
    }
    function onShow(isShow: bool; reason: unsigned): bool; virtual;
    {*
      WM_SIZE message handler.
    }
    function onSize(action: unsigned; height, width: unsigned): bool; virtual;
    {
    }
    function onGetDlgCode(): LRESULT; virtual;
    {*
    }
    function parentResize(dw, dh: int): unaWinWindow; virtual;
    {*
      This method is called periodically when there are no pending messages in window queue and window is application or is in modal state.
    }
    procedure idle(); virtual;
    {
    }
    function doCreateWindow(): hWnd; virtual;
  public
    {*
      Creates new Windows window.
    }
    constructor create(const params: unaWinCreateParams); overload;
    {*
      Creates new Windows window.
    }
    constructor create(wndClass: unaWinClass = nil; font: unaWinFont = nil; const caption: string = ''; parent: hWnd = 0; style: unsigned = WS_OVERLAPPEDWINDOW or WS_VISIBLE; exStyle: unsigned = 0; x: int = int(CW_USEDEFAULT); y: int = int(CW_USEDEFAULT); w: int = int(CW_USEDEFAULT); h: int = int(CW_USEDEFAULT); menu: hMenu = 0; instance: hModule = 0; icon: hIcon = 0); overload;
    {*
      Creates new "standard" Windows window (such as BUTTON, EDIT and so on).
    }
    constructor createStdWnd(const className: string; const caption: string = ''; parent: unaWinWindow = nil; style: unsigned = 0; exStyle: unsigned = 0; x: int = 2; y: int = 2; w: int = 20; h: int = 20; id: unsigned = 0);
    {*
      Destroys Windows window. If this window has child windows, they will be also destroyed.
    }
    destructor Destroy(); override;
    //
    {*
      Creates Windows window. Returns handle on new created window. If window is already created does nothing and returns handle on previously created window.
    }
    function createWindow(): hWnd;
    {*
      Enters TM-safe lock state, if possible. Returns False if locking was impossible during given time interval.
    }
    function enter(timeout: tTimeout = 10000): bool;
    {*
      Frees the window from TM-safe lock state.
    }
    procedure leave();
    {*
      Destroys Windows window. Child windows (if any) will NOT be destroyed.
    }
    procedure destroyWindow();
    {*
      Returns handle on window. Creates window if necessary.
    }
    function getHandle(): hWnd;	// creates window if necessary
    //
    procedure addChild(child: unaWinWindow);
    {*
      Returns pointer on unaWinCreateParams structure.
    }
    function getCreateParams(): punaWinCreateParams;
    {*
      Sets anchors for window. Default anchors are [unawinAnchor_LEFT or unawinAnchor_TOP].
    }
    function setAnchors(anchors: unsigned = unawinAnchor_LEFT or unawinAnchor_TOP): unaWinWindow;
    {*
      Sets new font for window.
    }
    function setFont(font: unaWinFont): unaWinWindow;
    {*
      Returns length of text associated with window.
    }
    function getTextLength(): int;
    {*
      Returns text associated with window.
    }
    function getText(): string;
    {*
      Sets text to be associated with window.
    }
    function setText(const text: string): unaWinWindow;
    {*
      Default value -1 for wnd means window handle will be used instead.

      You can specify 0 as wnd to retrieve the entire screen DC.

      Make sure you call releaseDC() as soon as possible.
    }
    function getDC(clipRgn: hRGN = 0; flags: unsigned = DCX_WINDOW; wnd: int = -1): hDC;
    {*
      Default value 0 means last DC returned by getDC() method will be used

      Class and private DCs (i.e. when isCommonDC property is false) will not be
      released, and it is safe to call this function for that class styles.
    }
    function releaseDC(dc: hDC = 0): int;
    {*
      Posts a message for window.
    }
    function postMessage(message: unsigned; wParam: int = 0; lParam: int = 0): bool;
    {*
      Sends a message to window.
    }
    function sendMessage(message: unsigned; wParam: int = 0; lParam: int = 0): int;
    {*
      Process all messages waiting in window message queue.
    }
    function processMessages(): unaWinWindow;
    {*
      Displays message box with specified text.
    }
    function messageBox(const text: string; const caption: string = ''; flags: unsigned = MB_OK): unsigned;
    //
    {*
      Show (SW_SHOW) or hides (SW_HIDE) the window.
    }
    function show(cmd: unsigned = SW_SHOW): unaWinWindow;
    {*
    }
    function showModal(cmd: unsigned = SW_SHOW): int;
    {*
    }
    function endModal(modalResult: int = -1): unaWinWindow;
    {*
      Updates the window contents.
    }
    function update(): unaWinWindow;
    {*
      Redraws the window contents.
    }
    function redraw(): unaWinWindow;
    {*
      Sets the focus on window. If firstChild = true sets the focus on first child window.
    }
    function setFocus(firstChild: bool = false): unaWinWindow;
    {*
      Enables or disables the window.
    }
    function enable(doEnable: bool = true): unaWinWindow;
    // -- --
    {*
      For non-common DCs if dc = 0, it will create and release a DC, so use this method carefully (performance issue)
    }
    function textOut(const text: string; x: int = 0; y: int = 0; dc: hDC = 0): bool;
    {*
      Y coordinate of top-left window corner (in relative coordinates).
    }
    property top: int read getTop write setTop;
    {*
      X coordinate of top-left window corner (in relative coordinates).
    }
    property left: int read getLeft write setLeft;
    {*
      Height of the window.
    }
    property height: int read getHeight write setHeight;
    {*
      Width of the window.
    }
    property width: int read getWidth write setWidth;
    {*
      Window anchors.
    }
    property anchors: unsigned read f_anchors write setFAnchors;
    {*
      Minimum value for window width.
    }
    property minWidth: int read f_minWidth write setMinWidth;
    {*
      Minimum value for window height.
    }
    property minHeight: int read f_minHeight write setMinHeight;
    //
    {*
      Window handle.
    }
    property wnd: hWnd read f_handle;	// does not creates window
    {*
      Window class.
    }
    property winClass: unaWinClass read getWndClass;
    {*
      false if this window belongs to class with CS_CLASSDC, CS_OWNDC or CS_PARENTDC style set.
      true otherwise
    }
    property isCommonDC: bool read f_isCommonDC;
    {*
      Returns true if window has WS_VISIBLE style.
    }
    property isVisible: bool index WS_VISIBLE read hasStyle;
    {*
      Returns true if window has WS_MINIMIZE style.
    }
    property isMinimized: bool index WS_MINIMIZE read hasStyle;
    {*
      Returns true if window has WS_MAXIMIZE style.
    }
    property isMaximized: bool index WS_MAXIMIZE read hasStyle;
    {*
      Returns true if window has WS_DISABLED style.
    }
    property isDisabled: bool index WS_DISABLED read hasStyle;
    {*
      Returns true if window has WS_OVERLAPPED style.
    }
    property isOverlapped: bool index WS_OVERLAPPED read hasStyle;
    {*
      This property is valid only if isCommonDC is false.

      Use getDC()/releaseDC() methods otherwise.
    }
    property deviceContext: hDC read f_dc;
    {*
      Window font.
    }
    property font: unaWinFont read getFont write setFFont;
    //
    property rect: tRECT read f_rect;
    //
    property unaParent: unaWinWindow read getUnaParent;
    {*
      Command event. (Handles WM_COMMAND messages).
    }
    property wmCommand: tmessageEvent read f_wmCommand write f_wmCommand;
  end;


  //
  // -- unaWinSplashWindow --
  //
  unaWinStatic = class;

  {*
    This is small centered window without borders.
  }
  unaWinSplashWindow = class(unaWinWindow)
  private
    f_static: unaWinStatic;
  protected
    function parentResize(dw, dh: int): unaWinWindow; override;
    function onClick(button: Word; x, y: word): bool; override;
  public
    {*
      Creates splash window with centered text inside.
    }
    constructor create(const text: string = ''; parent: unaWinWindow = nil; w: int = 200; h: int = 150);
    procedure BeforeDestruction(); override;
    //
    {*
      Changes the text displayed inside the window.
    }
    procedure setText(const text: string; doShow: bool = false);
  end;

  //
  // -- unaWinButton --
  //
  {*
    BUTTON window.
  }
  unaWinButton = class(unaWinWindow)
  public
    {*
      Creates Windows BUTTON window.
    }
    constructor create(const caption: string; parent: unaWinWindow; id: unsigned = 0; x: int = 2; y: int = 2; w: int = 64; h: int = 24; style: unsigned = BS_PUSHBUTTON or WS_CHILD or  WS_TABSTOP or WS_VISIBLE); overload;
  end;


  //
  // -- unaWinCheckBox --
  //
  {*
    Checkbox window.
  }
  unaWinCheckBox = class(unaWinButton)
  private
    function getChecked: bool;
    procedure setChecked(value: bool);
  public
    {*
      Creates Windows BUTTON window with BS_CHECKBOX style set by default.
    }
    constructor create(const caption: string; parent: unaWinWindow; id: unsigned = 0; x: int = 2; y: int = 2; w: int = 64; h: int = 24; style: unsigned = BS_CHECKBOX or BS_AUTOCHECKBOX or WS_CHILD or  WS_TABSTOP or WS_VISIBLE); overload;
    {*
    }
    property checked: bool read getChecked write setChecked;
  end;


  //
  // -- unaWinCombobox --
  //
  {*
    Combobox window.
  }
  unaWinCombobox = class(unaWinWindow)
  private
    function getItemIndex(): int;
    procedure setItemIndex(value: int);
    function getCount(): unsigned;
  public
    {*
      Creates Windows COMBOBOX window with CBS_DROPDOWNLIST style set by default.
    }
    constructor create(parent: unaWinWindow; x: int = 2; y: int = 2; w: int = 80; h: int = 120; style: unsigned = CBS_DROPDOWNLIST or WS_CHILD or WS_TABSTOP or WS_VSCROLL or WS_VISIBLE); overload;
    //
    {*
      Adds a string to combobox list.
    }
    function add(const str: string): unaWinCombobox;
    {*
      Returns string index in combobox list, or -1 if string was not found.
    }
    function findString(const str: string): int;
    //
    {*
      Returns current selected item (string) index, or -1 if no item is selected.
    }
    property itemIndex: int read getItemIndex write setItemIndex;
    {*
      Returns number of items (strings) in combobox list.
    }
    property count: unsigned read getCount;
  end;


  //
  // -- unaWinEdit --
  //
  {*
    EDIT window.
  }
  unaWinEdit = class(unaWinWindow)
  protected
    function onGetDlgCode(): LRESULT; override;
  public
    {*
      Creates EDIT window.
    }
    constructor create(const text: string; parent: unaWinWindow; x: int = 2; y: int = 2; w: int = 64; h: int = 24; style: unsigned = ES_LEFT or ES_AUTOHSCROLL or WS_CHILD or WS_TABSTOP or WS_VISIBLE or WS_BORDER; exStyle: unsigned = WS_EX_CLIENTEDGE); overload;
    //
    {*
      Sets/resets read only mode for edit.
    }
    function setReadOnly(value: bool = true): unaWinEdit;
  end;


  //
  // -- unaWinMemo --
  //
  {*
    Memo window.
  }
  unaWinMemo = class(unaWinEdit)
  protected
    function onCommand(cmd: int; wnd: int): bool; override;
  public
    {*
      Creates EDIT window with ES_MULTILINE style set by default.
    }
    constructor create(const text: string; parent: unaWinWindow; x: int = 2; y: int = 2; w: int = 64; h: int = 18; style: unsigned = ES_LEFT or WS_CHILD or ES_MULTILINE or ES_AUTOVSCROLL or ES_AUTOHSCROLL or WS_HSCROLL or WS_VSCROLL or  WS_TABSTOP or WS_VISIBLE); overload;
    //
    {*
      Sets the selection in memo.
    }
    function setSel(starting, ending: int): unaWinMemo;
    {*
      Replaces selected text with given string.
    }
    function replaceSel(const line: string): unaWinMemo;
    {*
      Returns line from memo with specified index (starting form 0).

      Line length is limited to 65535.
    }
    function getLine(index: unsigned = 0): string;
  end;


  //
  // -- unaWinListBox --
  //
  {*
    LISTBOX window.
  }
  unaWinListBox = class(unaWinWindow)
  public
    {*
      Creates LISTBOX window.
    }
    constructor create(parent: unaWinWindow; x: int = 2; y: int = 2; w: int = 64; h: int = 50; style: unsigned = LBS_STANDARD or WS_CHILD or  WS_TABSTOP or WS_VISIBLE); overload;
  end;


  //
  // -- unaWinStatic --
  //
  {*
    STATIC window
  }
  unaWinStatic = class(unaWinWindow)
  public
    {*
      Creates STATIC window.
    }
    constructor create(const caption: string; parent: unaWinWindow; x: int = 2; y: int = 2; w: int = 64; h: int = 18; style: unsigned = SS_SIMPLE or WS_CHILD or WS_VISIBLE); overload;
  end;


// == tool tips ==

  {$EXTERNALSYM TOOLINFOW}
  TOOLINFOW = packed record
    cbSize: UINT;
    uFlags: UINT;
    hwnd: HWND;
    uId: UINT;
    Rect: TRect;
    hInst: THandle;
    lpszText: pwChar;
    lParam: LPARAM;
  end;

const
  {$EXTERNALSYM TTS_ALWAYSTIP }
  TTS_ALWAYSTIP           = $01;
  {$EXTERNALSYM TTS_NOPREFIX }
  TTS_NOPREFIX            = $02;
  {$EXTERNALSYM TTS_NOANIMATE }
  TTS_NOANIMATE           = $10;
  {$EXTERNALSYM TTS_NOFADE }
  TTS_NOFADE              = $20;
  {$EXTERNALSYM TTS_BALLOON }
  TTS_BALLOON             = $40;
  {$EXTERNALSYM TTS_CLOSE }
  TTS_CLOSE               = $80;

  {$EXTERNALSYM TOOLTIPS_CLASS }
  TOOLTIPS_CLASS = 'tooltips_class32';

  // Use this to center around trackpoint in trackmode
  // -OR- to center around tool in normal mode.
  // Use TTF_ABSOLUTE to place the tip exactly at the track coords when
  // in tracking mode.  TTF_ABSOLUTE can be used in conjunction with TTF_CENTERTIP
  // to center the tip absolutely about the track point.

  {$EXTERNALSYM TTF_IDISHWND }
  TTF_IDISHWND            = $0001;
  {$EXTERNALSYM TTF_CENTERTIP }
  TTF_CENTERTIP           = $0002;
  {$EXTERNALSYM TTF_RTLREADING }
  TTF_RTLREADING          = $0004;
  {$EXTERNALSYM TTF_SUBCLASS }
  TTF_SUBCLASS            = $0010;
  {$EXTERNALSYM TTF_TRACK }
  TTF_TRACK               = $0020;
  {$EXTERNALSYM TTF_ABSOLUTE }
  TTF_ABSOLUTE            = $0080;
  {$EXTERNALSYM TTF_TRANSPARENT }
  TTF_TRANSPARENT         = $0100;
  {$EXTERNALSYM TTF_DI_SETITEM }
  TTF_DI_SETITEM          = $8000;       // valid only on the TTN_NEEDTEXT callback



  {$EXTERNALSYM TTM_ADDTOOLW }
  TTM_ADDTOOLW             = WM_USER + 50;
  {$EXTERNALSYM TTM_DELTOOLW }
  TTM_DELTOOLW             = WM_USER + 51;
  {$EXTERNALSYM TTM_NEWTOOLRECTW }
  TTM_NEWTOOLRECTW         = WM_USER + 52;
  {$EXTERNALSYM TTM_GETTOOLINFOW }
  TTM_GETTOOLINFOW         = WM_USER + 53;
  {$EXTERNALSYM TTM_SETTOOLINFOW }
  TTM_SETTOOLINFOW         = WM_USER + 54;
  {$EXTERNALSYM TTM_HITTESTW }
  TTM_HITTESTW             = WM_USER + 55;
  {$EXTERNALSYM TTM_GETTEXTW }
  TTM_GETTEXTW             = WM_USER + 56;
  {$EXTERNALSYM TTM_UPDATETIPTEXTW }
  TTM_UPDATETIPTEXTW       = WM_USER + 57;
  {$EXTERNALSYM TTM_ENUMTOOLSW }
  TTM_ENUMTOOLSW           = WM_USER + 58;
  {$EXTERNALSYM TTM_GETCURRENTTOOLW }
  TTM_GETCURRENTTOOLW      = WM_USER + 59;
  {$EXTERNALSYM TTM_WINDOWFROMPOINT }
  TTM_WINDOWFROMPOINT      = WM_USER + 16;
  {$EXTERNALSYM TTM_TRACKACTIVATE }
  TTM_TRACKACTIVATE        = WM_USER + 17;  // wParam = TRUE/FALSE start end  lparam = LPTOOLINFO
  {$EXTERNALSYM TTM_TRACKPOSITION }
  TTM_TRACKPOSITION        = WM_USER + 18;  // lParam = dwPos
  {$EXTERNALSYM TTM_SETTIPBKCOLOR }
  TTM_SETTIPBKCOLOR        = WM_USER + 19;
  {$EXTERNALSYM TTM_SETTIPTEXTCOLOR }
  TTM_SETTIPTEXTCOLOR      = WM_USER + 20;
  {$EXTERNALSYM TTM_GETDELAYTIME }
  TTM_GETDELAYTIME         = WM_USER + 21;
  {$EXTERNALSYM TTM_GETTIPBKCOLOR }
  TTM_GETTIPBKCOLOR        = WM_USER + 22;
  {$EXTERNALSYM TTM_GETTIPTEXTCOLOR }
  TTM_GETTIPTEXTCOLOR      = WM_USER + 23;
  {$EXTERNALSYM TTM_SETMAXTIPWIDTH }
  TTM_SETMAXTIPWIDTH       = WM_USER + 24;
  {$EXTERNALSYM TTM_GETMAXTIPWIDTH }
  TTM_GETMAXTIPWIDTH       = WM_USER + 25;
  {$EXTERNALSYM TTM_SETMARGIN }
  TTM_SETMARGIN            = WM_USER + 26;  // lParam = lprc
  {$EXTERNALSYM TTM_GETMARGIN }
  TTM_GETMARGIN            = WM_USER + 27;  // lParam = lprc
  {$EXTERNALSYM TTM_POP }
  TTM_POP                  = WM_USER + 28;
  {$EXTERNALSYM TTM_UPDATE }
  TTM_UPDATE               = WM_USER + 29;

type
  //
  // -- unaWinTooltip --
  //
  {*
    Tooltip window
  }
  unaWinTootip = class(unaObject)
  private
    f_handle: tHandle;
    f_info: TOOLINFOW;
    f_isActive: bool;
    f_tip: string;
    //
    //f_oldWndProc: TFNWndProc;
    //
    procedure setTip(const tip: string);
  public
    {*
      Creates Tooltip window.
    }
    constructor create(const tip: string; parent: tHandle; style: unsigned = WS_POPUP or TTS_NOPREFIX or TTS_BALLOON; flags: DWORD = TTF_SUBCLASS);
    procedure BeforeDestruction(); override;
    //
    function activateTrack(doActivate: bool): LRESULT;
    //
    property handle: tHandle read f_handle;
    //
    property isActive: bool read f_isActive;
    //
    property tip: string read f_tip write setTip;
  end;


  //
  // -- unaWinApp --
  //
  {*
    Window class which can be used as main application window.
  }
  unaWinApp = class(unaWinWindow)
  private
    f_exitCode: int;
    f_okToRun: bool;
    f_isRunning: bool;
    f_sleepEvent: unaEvent;
    f_mustTerminate: bool;
    //
  protected
    function onClose(): bool; override;
    //
    function initWindow(): bool; override;
    {*
      WM_NCDESTROY message handler.

      Calls quit() method to terminate the application.
    }
    function notifyDestroy(): bool; override;
    {*
      WM_ACTIVATEAPP message handler.
    }
    function onActivateApp(isActivate: bool; activeThreadId: unsigned): bool; override;
    //
    function onRunEnterLeave(enter: bool): bool; virtual;
  public
    procedure AfterConstruction(); override;
    procedure BeforeDestruction(); override;
    {*
      Main window cycle. Do not returns the control until WM_QUIT messages is received.
    }
    function run(): unaWinApp;
    {*
      Terminates the application using the PostQuitMessage() routine.
    }
    procedure quit(exitCode: int = 0);	// terminates application
    //
    procedure wakeUp();
    {*
      Specifies exit code used when terminating the application.
    }
    property exitCode: int read f_exitCode write f_exitCode;
    {*
      Specifies exit code used when terminating the application.
    }
    property isRunning: bool read f_isRunning;
  end;


  //
  // -- unaWinGraphicsApp --
  //
  {*
    Windows application whith graphics support.
  }
  unaWinGraphicsApp = class(unaWinApp)
  private
    f_canResize: bool;
    f_memDC: hDC;
    f_grDC: hDC;
    //
    f_fps: unsigned;
    f_actualFps: unsigned;
    f_fcount: int64;
    f_fpsMark: uint64;
    //
    f_frameWidth: unsigned;
    f_frameHeight: unsigned;
    f_bgColor: COLORREF;
    f_bgBrush: hBRUSH;
    //
    f_memXSize: int;
    f_memYSize: int;
    f_memBmpInfo: BITMAPINFO;
    f_memBmpBits: pointer;
    f_memDIB: HBITMAP;
    //
    f_drawTimer: unaThreadTimer;
    f_eraseBg: bool;
    //
    procedure myOnDrawTimer(sender: tObject);
    procedure initApp();
  protected
    function onDrawFrame(): bool; virtual;
    function onRunEnterLeave(enter: bool): bool; override;
    function doCreateWindow(): hWnd; override;
    procedure skipFrame();
  public
    constructor create(fps: unsigned = 20; frameWidth: unsigned = 700; frameHeight: unsigned = 500; bgColor: COLORREF = 0; const title: string = ''; canResize: bool = true; canMinimize: bool = true; x: int = 50; y: int = 20; icon: int = -1; windowFlags: int = -1; windowExFlags: int = -1; memWidth: int = -1; memHeight: int = -1); overload;
    constructor create(wnd: hWnd; fps: unsigned = 20; bgColor: COLORREF = 0; const title: string = ''; canResize: bool = true; memWidth: int = -1; memHeight: int = -1); overload;
    destructor Destroy(); override;
    //
    function setBits(x, y: int; data: pointer; size: unsigned): unsigned;
    //
    property grDC: hDC read f_grDC;
    property memDC: hDC read f_memDC;
    //
    property memDIB: hBITMAP read f_memDIB;
    property memDIBInfo: BITMAPINFO read f_memBmpInfo;
    property memXSize: int read f_memXSize;
    property memYSize: int read f_memYSize;
    //
    property fps: unsigned read f_fps;
    property actualFps: unsigned read f_actualFps;
    property frameWidth: unsigned read f_frameWidth;
    property frameHeight: unsigned read f_frameHeight;
    property bgColor: COLORREF read f_bgColor;
    //
    property eraseBg: bool read f_eraseBg write f_eraseBg;
  end;


  //
  // -- unaWinBitmap --
  //
  {*
    Windows bitmap.
  }
  unaWinBitmap = class(unaObject)
  private
    //f_bitmap: hBITMAP;
    //f_dc: hDC;
  public
  end;


const
  btnCmdExit	= 1004;
  btnCmdStart	= 1005;
  btnCmdStop	= 1006;

  btnCmdFirstAvail	= 1100;

type
  //
  // -- unaWinConsoleApp --
  //
  {*
    Simple console-like application main window class.
  }
  unaWinConsoleApp = class(unaWinApp)
  private
    f_ini: unaIniAbstractStorage;
    f_memo: unaWinMemo;
    f_btnExit: unaWinButton;
    f_btnStart: unaWinButton;
    f_btnStop: unaWinButton;
    f_captionHeight: unsigned;
    f_hasGUI: bool;
    //
  protected
    {*
      WM_COMMAND message handler. cmd values below 10 are reserved for internal usage.
    }
    function onCommand(cmd, wnd: int): bool; override;
    {*
      WM_DESTROY message handler.
    }
    function onDestroy(): bool; override;
    {*
      Called on the start of application.
    }
    procedure onStart(); virtual;
    {*
      Called on the end of application.
    }
    procedure onStop(); virtual;
    {*
      This method can be used to perform additional initialization.
    }
    function doInit(): bool; virtual;
    {*
      This method is used to display "console" memo messages.
    }
    procedure idle(); override;
  public
    {*
      Creates console-like window.
    }
    constructor create(hasGUi: bool; const caption, copy: string; const iniFile: wString = ''; icon: hIcon = 0; captionHeight: unsigned = 32; btnExit: bool = true; btnStart: bool = false; btnStop: bool = false; style: unsigned = WS_OVERLAPPEDWINDOW; exStyle: unsigned = WS_EX_CONTROLPARENT);
    {*
    }
    destructor Destroy(); override;
    //
    {*
      Exit button.
    }
    property btnExit: unaWinButton read f_btnExit;
    {*
      Start button.
    }
    property btnStart: unaWinButton read f_btnStart;
    {*
      Stop button.
    }
    property btnStop: unaWinButton read f_btnStop;
    {*
      Height of upper panel with buttons.
    }
    property captionHeight: unsigned read f_captionHeight;
    //
    property hasGUI: bool read f_hasGUI;
  end;


{*
  Returns Windows class encapsulation instance by given class name.
  Class will be created and registered if necessary.
}
// -- getClass() --
function getClass(const className: string = ''; isStdClass: bool =  false; style: unsigned = 0; icon: hIcon = 0; smallIcon: hIcon = 0; cursor: hCursor = 0; brBrush: hBrush = COLOR_WINDOW; menuName: int = 0; instance: hModule = 0; force: bool = true): unaWinClass;


implementation


uses
  unaUtils;

function ChooseFont;  external 'comdlg32.dll'  name 'ChooseFontA';
function ChooseFontA; external 'comdlg32.dll'  name 'ChooseFontA';
function ChooseFontW; external 'comdlg32.dll'  name 'ChooseFontW';

type
  //
  // --  --
  //
  unaWinList = class(unaIdList)
  protected
    function getId(item: pointer): int64; override;
  public
    function callWndProc(index: int; message: int; wParam: int; lParam: int; window: hWnd = 0): int;
  end;


// --  --
function defWndProc(wnd: hWnd; msg, wParam, lParam: int): int;
begin
{$IFNDEF NO_ANSI_SUPPORT }
  if (g_wideApiSupported) then
{$ENDIF NO_ANSI_SUPPORT }
    result := DefWindowProcW(wnd, msg, wParam, lParam)
{$IFNDEF NO_ANSI_SUPPORT }
  else
    result := DefWindowProcA(wnd, msg, wParam, lParam);
{$ENDIF NO_ANSI_SUPPORT }
  ;
end;

{ unaWinList }

// --  --
function unawinList.callWndProc(index, message, wParam, lParam: int; window: hWnd): int;
var
  w: unaWinWindow;
begin
  w := unaWinWindow(get(index));
  //
  if (nil <> w) then
    result := w.wndProc(message, wParam, lParam)
  else
    result := defWndProc(window, message, wParam, lParam);
end;

// --  --
function unaWinList.getId(item: pointer): int64;
begin
  if (nil <> item) then
    result := unaWinWindow(item).wnd
  else
    result := 0;
end;




var
  g_winList: unaWinList;
  g_winCreateClass: unaWinWindow;
  g_winClasses: unaList;
  g_winFonts: unaList;
  //g_winCreateGate: unaInProcessGate;

// -- --
function getClass(const className: string; isStdClass: bool; style: unsigned; icon, smallIcon: hIcon; cursor: hCursor; brBrush: hBrush; menuName: int; instance: hModule; force: bool): unaWinClass;
var
  i: int;
begin
  result := nil;
  i := 0;
  //
  if (nil <> g_winClasses) then begin
    //
    while (i < g_winClasses.count) do begin
      //
      result := g_winClasses.get(i);
      if ((0 <> result.atom) or result.isCommon) then begin
	//
	if (result.f_wndClassW.lpszClassName = className) then
	  break
	else
	  result := nil;
	//
      end
      else
	result := nil;
      //
      inc(i);
    end;
  end;
  //
  if (nil = result) then begin
    //
    if (isStdClass) then
      result := unaWinClass.createStdClass(className)
    else
      result := unaWinClass.create(className, style, icon, smallIcon, cursor, brBrush, menuName, instance, force);
  end;
end;

// --  --
function unaWndProc(window: hWnd; message, wParam, lParam: int): int; stdcall;
var
  i: int;
  long: unsigned;
begin
  // 1. try to locate this window in our winList
  long := GetWindowLong(window, 0);
  if ($19730000 = long and $FFFF0000) then
    // looks like our window
    i := long and $FFFF
  else
    // could be standard class window
    i := g_winList.indexOfId(window);
  //
  if (0 > i) then begin
    //
    if (nil <> g_winCreateClass) then begin
      //
      g_winCreateClass.setWinHandle(window);
      //
      i := g_winList.add(g_winCreateClass);
      g_winCreateClass.setWinListIndex(i);
    end;
  end;

  // 2. call wndProc
  if (0 <= i) then
    result := g_winList.callWndProc(i, message, wParam, lParam, window)
  else
    result := defWndProc(window, message, wParam, lParam);
end;

// --  --
function unaCreateWindow(window: unaWinWindow): hWnd;
var
  parent: hWnd;
  params: punaWinCreateParams;
begin
  params := window.getCreateParams();
  parent := window.getParent();
  //
  if (window.acquire(false, 1000)) then begin
    //
    try
      g_winCreateClass := window;
      if (params.r_class.isCommon) then
	//
	// subclassing works, but kills standard controls on system dialog boxes, for example
	// I have no time now to investigate what is wrong, so I will disable that, since most
	// importan messages are sent to parent anywhay
	//
	//params.r_class.createSubclass(parent, @unaWndProc);
	;
      //
{$IFNDEF NO_ANSI_SUPPORT }
      if (g_wideApiSupported) then
{$ENDIF NO_ANSI_SUPPORT }
	result := CreateWindowExW(params.r_exStyle, pwChar(params.r_class.f_nameW),          pwChar(params.r_captionW),          params.r_style, params.r_x, params.r_y, params.r_width, params.r_height, parent, params.r_menu, 0, nil)
{$IFNDEF NO_ANSI_SUPPORT }
      else
	result := CreateWindowExA(params.r_exStyle, paChar(aString(params.r_class.f_nameW)), paChar(aString(params.r_captionW)), params.r_style, params.r_x, params.r_y, params.r_width, params.r_height, parent, params.r_menu, 0, nil)
{$ENDIF NO_ANSI_SUPPORT }
      ;
      //
    finally
      g_winCreateClass := nil;
      window.releaseWO();
    end;
  end
  else
    result := 0;
end;

{ unaWinClass }

// --  --
function unaWinClass.callSubClassedWndProc(window: hWnd; message, wParam, lParam: int): int;
begin
  if (f_wasSubClassed and (0 <> f_oldClassWndProc)) then
    //
    result := CallWindowProc(pointer(f_oldClassWndProc), window, message, wParam, lParam)
  else
    result := -1;
end;

// --  --
class function unaWinClass.classIsRegistered(const className: string; instance: hModule): bool;
var
  infoW: TWNDCLASSW;
{$IFNDEF NO_ANSI_SUPPORT }
  infoA: TWNDCLASSA;
{$ENDIF NO_ANSI_SUPPORT }
begin
{$IFNDEF NO_ANSI_SUPPORT }
  if (g_wideApiSupported) then
{$ENDIF NO_ANSI_SUPPORT }
    result := GetClassInfoW(instance, pwChar(wString(className)), infoW)
{$IFNDEF NO_ANSI_SUPPORT }
  else
    result := GetClassInfoA(instance, paChar(aString(className)), infoA);
{$ENDIF NO_ANSI_SUPPORT }
  ;
end;

// --  --
constructor unaWinClass.create(const name: string; style: unsigned; icon, smallIcon: hIcon; cursor: hCursor; brBrush: hBrush; menuName: int; instance: hModule; force: bool);
begin
  inherited create();
  //
  if ('' = name) then
    f_nameW := className
  else
    f_nameW := name;
  //
  f_wndClassW.cbSize := sizeOf(f_wndClassW);
  f_wndClassW.style := style;
  f_wndClassW.lpfnWndProc := @unaWndProc;
  f_wndClassW.cbClsExtra := 0;
  f_wndClassW.cbWndExtra := 4;	// stores pointer to window (Delphi) class instance
  if (0 = instance) then
    f_wndClassW.hInstance := GetModuleHandle(nil)
  else
    f_wndClassW.hInstance := instance;
  //
  f_wndClassW.hIcon := icon;
  //
  if (0 = cursor) then
    f_wndClassW.hCursor := LoadCursor(instance, IDC_ARROW)
  else
    f_wndClassW.hCursor := cursor;
  //
  f_wndClassW.hbrBackground := brBrush;
  f_wndClassW.lpszMenuName := pwChar(pointer(menuName));
  f_wndClassW.lpszClassName := pwChar(f_nameW);
  f_wndClassW.hIconSm := smallIcon;
  //
  if (nil <> g_winClasses) then
    g_winClasses.add(self);
  //
  registerClass(force);
end;

// --  --
constructor unaWinClass.createStdClass(const name: string; instance: hModule);
var
  res: bool;
{$IFNDEF NO_ANSI_SUPPORT }
  wndClassA: TWNDCLASSEXA;
{$ENDIF NO_ANSI_SUPPORT }
begin
  inherited create();
  //
{$IFNDEF NO_ANSI_SUPPORT }
  if (g_wideApiSupported) then begin
{$ENDIF NO_ANSI_SUPPORT }
    //
    f_wndClassW.cbSize := sizeOf(f_wndClassW);
    res := GetClassInfoExW(instance, pwChar(wString(name)), f_wndClassW);
{$IFNDEF NO_ANSI_SUPPORT }
  end
  else begin
    //
    wndClassA.cbSize := sizeOf(wndClassA);
    res := GetClassInfoExA(instance, paChar(aString(name)), wndClassA);
    if (res) then begin
      //
      f_wndClassW.cbSize := sizeOf(f_wndClassW);
      f_wndClassW.style := wndClassA.style;
      f_wndClassW.lpfnWndProc := wndClassA.lpfnWndProc;
      f_wndClassW.cbClsExtra := wndClassA.cbClsExtra;
      f_wndClassW.cbWndExtra := wndClassA.cbWndExtra;
      f_wndClassW.hInstance := wndClassA.hInstance;
      f_wndClassW.hIcon := wndClassA.hIcon;
      f_wndClassW.hCursor := wndClassA.hCursor;
      f_wndClassW.hbrBackground := wndClassA.hbrBackground;
      f_wndClassW.lpszMenuName := pwChar(wString(wndClassA.lpszMenuName));
      //f_wndClassW.lpszClassName := pWideChar(wString(wndClassA.lpszClassName));
      f_wndClassW.hIconSm := wndClassA.hIconSm;
    end;
  end;
{$ENDIF NO_ANSI_SUPPORT }
  //
  if (res) then begin
    //
    f_nameW := name;
    f_classOwner := false;
    f_isCommon := true;
  end
  else
    create(name, 0, 0, 0, 0, 0, 0, instance);
  //
  f_wndClassW.lpszClassName := pwChar(f_nameW);
  //
  if (nil <> g_winClasses) then
    g_winClasses.add(self);
end;

// --  --
function unaWinClass.createSubclass(mainWnd: hWnd; newWndProc: pointer): bool;
var
  oldProc: int;
begin
  if (not f_wasSubclassed) then begin
    //
    // try to subclass a class
    //
    // 1. create a window of that class
{$IFNDEF NO_ANSI_SUPPORT }
    if (g_wideApiSupported) then
{$ENDIF NO_ANSI_SUPPORT }
      f_subClassWnd := CreateWindowW(f_wndClassW.lpszClassName, nil, WS_CHILD, 0, 0, 50, 50, mainWnd, 0, f_wndClassW.hInstance, nil)
{$IFNDEF NO_ANSI_SUPPORT }
    else
      f_subClassWnd := CreateWindowA(paChar(aString(f_wndClassW.lpszClassName)), nil, WS_CHILD, 0, 0, 50, 50, mainWnd, 0, f_wndClassW.hInstance, nil);
{$ENDIF NO_ANSI_SUPPORT }
    ;
    //
    if (0 <> f_subClassWnd) then begin
      //
      // 2. check if class is not already subclassed to this wndProc
      oldProc := GetClassLong(f_subClassWnd, GCL_WNDPROC);
      if (int(newWndProc) <> oldProc) then begin
        //
	// 3. do subclass
	f_oldClassWndProc := oldProc;	// just in case some message will be passed while f_oldClassWndProc is not set (i.e. SetClassLong() is not returned)
	f_wasSubClassed := true;
	f_oldClassWndProc := SetClassLong(f_subClassWnd, GCL_WNDPROC, int(newWndProc));
      end
      else
	// remove the window - its class is already subclassed to given wndProc
	DestroyWindow(f_subClassWnd);
    end;
  end;
  //
  result := f_wasSubclassed;
end;

// --  --
destructor unaWinClass.destroy();
begin
  if (nil <> g_winClasses) then
    g_winClasses.removeItem(self);
  //
  inherited;
  //
  removeSubclass();
  //
  if (f_classOwner) then
    unregister();
  //
  f_nameW := '';
end;

// --  --
function unaWinClass.getAtom(): ATOM;
begin
  result := registerClass();
end;

// --  --
function unaWinClass.getWndClassW(): pWNDCLASSEXW;
begin
  result := @f_wndClassW;
end;

// --  --
function unaWinClass.registerClass(force: bool): atom;

  // --  --
  function getInfo(): bool;
  var
{$IFNDEF NO_ANSI_SUPPORT }
    infoA: TWNDCLASSEXA;
{$ENDIF NO_ANSI_SUPPORT }
    infoW: TWNDCLASSEXW;
  begin
{$IFNDEF NO_ANSI_SUPPORT }
    if (g_wideApiSupported) then begin
{$ENDIF NO_ANSI_SUPPORT }
      //
      infoW.cbSize := sizeOf(infoW);
      result := GetClassInfoExW(f_wndClassW.hInstance, pwChar(f_nameW), infoW);
{$IFNDEF NO_ANSI_SUPPORT }
    end
    else begin
      //
      infoA.cbSize := sizeOf(infoA);
      result := GetClassInfoExA(f_wndClassW.hInstance, paChar(aString(f_nameW)), infoA);
    end;
{$ENDIF NO_ANSI_SUPPORT }
  end;

{$IFNDEF NO_ANSI_SUPPORT }
var
  wndClassA: TWNDCLASSEXA;
{$ENDIF NO_ANSI_SUPPORT }
begin
  if (0 = f_atom) then begin
    //
    if (force) then begin
      //
      while (getInfo()) do begin
	//
	f_nameW := f_nameW + 'a';
	f_wndClassW.lpszClassName := pwChar(f_nameW);
      end;
    end;
    //
{$IFNDEF NO_ANSI_SUPPORT }
    if (g_wideApiSupported) then
{$ENDIF NO_ANSI_SUPPORT }
      result := RegisterClassExW(f_wndClassW)
{$IFNDEF NO_ANSI_SUPPORT }
    else begin
      //
      wndClassA.cbSize := sizeOf(wndClassA);
      wndClassA.style := f_wndClassW.style;
      wndClassA.lpfnWndProc := f_wndClassW.lpfnWndProc;
      wndClassA.cbClsExtra := f_wndClassW.cbClsExtra;
      wndClassA.cbWndExtra := f_wndClassW.cbWndExtra;
      wndClassA.hInstance := f_wndClassW.hInstance;
      wndClassA.hIcon := f_wndClassW.hIcon;
      wndClassA.hCursor := f_wndClassW.hCursor;
      wndClassA.hbrBackground := f_wndClassW.hbrBackground;
      wndClassA.lpszMenuName := paChar(aString(f_wndClassW.lpszMenuName));
      wndClassA.lpszClassName := paChar(aString(f_wndClassW.lpszClassName));
      wndClassA.hIconSm := f_wndClassW.hIconSm;
      //
      result := RegisterClassExA(wndClassA);
    end;
{$ENDIF NO_ANSI_SUPPORT }
    ;
    //
    f_atom := result;
  end
  else
    result := f_atom;
end;

// --  --
procedure unaWinClass.removeSubclass();
begin
  if (f_wasSubclassed) then begin
    // remove the subclass, restore old wndProc
    SetClassLong(f_subClassWnd, GWL_WNDPROC, f_oldClassWndProc);
    // and destroy subclass window
    DestroyWindow(f_subClassWnd);
    //
    f_wasSubclassed := false;
  end;
end;

// --  --
procedure unaWinClass.unregister();
begin
  if ((0 <> f_atom) and not isCommon) then begin
    //
{$IFNDEF NO_ANSI_SUPPORT }
    if (g_wideApiSupported) then begin
{$ENDIF NO_ANSI_SUPPORT }
      //
      if (UnregisterClassW(pwChar(pointer(f_atom)), f_wndClassW.hInstance)) then
	f_atom := 0;
{$IFNDEF NO_ANSI_SUPPORT }
    end
    else begin
      //
      if (UnregisterClassA(paChar(pointer(f_atom)), f_wndClassW.hInstance)) then
        f_atom := 0;
    end;
{$ENDIF NO_ANSI_SUPPORT }
    //
  end;
end;

{ unaWinFont }

// --  --
class function unaWinFont.chooseScreenFont(var font: LOGFONT; owner: hWnd;
  dc: hDC; flags, sizeMin, sizeMax: unsigned): bool;
var
  cf: TCHOOSEFONT;
begin
  cf.lStructSize := sizeOf(cf);
  cf.hWndOwner := owner;
  cf.hDC := dc;
  cf.lpLogFont := PLogFontA(@font);
  cf.iPointSize := 0;
  cf.Flags := flags;
  cf.rgbColors := RGB(0, 0, 0);
  cf.lCustData := 0;
  cf.lpfnHook := nil;
  cf.lpTemplateName := nil;
  cf.hInstance := 0;
  cf.lpszStyle := nil;
  cf.nFontType := SCREEN_FONTTYPE;
  cf.nSizeMin := sizeMin;
  cf.nSizeMin := sizeMax;
  result := unaWinClasses.ChooseFontA(cf);
end;

// --  --
constructor unaWinFont.create(const face: string; h, w, escapement, orientation, weight: int; italic, underline, strikeout: bool; charset,
  precision, clipPrecision, quality, pitchAndFamily: unsigned);
begin
  inherited create();
  //
  f_font := CreateFontA(h, w, escapement, orientation, weight, unsigned(italic), unsigned(underline), unsigned(strikeout), charset, precision, clipPrecision, quality, pitchAndFamily, paChar(aString(face)));
  if (nil <> g_winFonts) then
    g_winFonts.add(self);
end;

// --  --
constructor unaWinFont.createIndirect(const font: LOGFONT);
begin
  inherited create();
  //
  f_font := CreateFontIndirect(font);
  //
  if (nil <> g_winFonts) then
    g_winFonts.add(self);
end;

// --  --
destructor unaWinFont.destroy();
begin
  if (nil <> g_winFonts) then
    g_winFonts.removeItem(self);
  //
  inherited;
  //
  DeleteObject(f_font);
end;

{ unaWinWindow }

// --  --
procedure unaWinWindow.addChild(child: unaWinWindow);
begin
  if (enter(1000)) then begin
    try
      if (0 > f_children.indexOf(child)) then
	//
	f_children.add(child);
	child.f_notifyParent := self;
    finally
      leave();
    end;
  end;
end;

// --  --
constructor unaWinWindow.create(const params: unaWinCreateParams);
begin
  inherited create();
  //
  //f_gate := unaInProcessGate.create({$IFDEF DEBUG}className + '(f_gate)'{$ENDIF});
  f_children := unaList.create(uldt_ptr);
  //
  f_createParams := params;
  // create the window
  if (initWindow()) then
    getHandle();
end;

// --  --
constructor unaWinWindow.create(wndClass: unaWinClass; font: unaWinFont; const caption: string; parent: hWnd; style, exStyle: unsigned; x, y, w, h: int; menu: hMenu; instance: hModule; icon: hIcon);
var
  params: unaWinCreateParams;
begin
  if (nil = wndClass) then
    wndClass := getClass('', false, 0, 0, 0, 0, COLOR_WINDOW + 1, 0, instance);
  //
  params.r_class := wndClass;
  if (nil = font) then
    //if (nil <> parent) then
      //params.r_font := parent.font
    //else
      params.r_font := unaWinFont.create()
  else
    params.r_font := font;
  //
  params.r_captionW := caption;
  params.r_style := style;
  params.r_exStyle := exStyle;
  params.r_x := x;
  params.r_y := y;
  params.r_width := w;
  params.r_height := h;
  params.r_menu := menu;
  params.r_icon := icon;
  //
  params.r_parentIsHandle := true;
  params.r_winParent := parent;
  //
  create(params);
end;

// --  --
constructor unaWinWindow.createStdWnd(const className, caption: string; parent: unaWinWindow; style, exStyle: unsigned; x, y, w, h: int; id: unsigned);
var
  params: unaWinCreateParams;
begin
  params.r_class := getClass(className, true);
  //
  params.r_font := parent.font;
  params.r_captionW := caption;
  params.r_style := style;
  params.r_exStyle := exStyle;
  params.r_x := x;
  params.r_y := y;
  params.r_width := w;
  params.r_height := h;
  params.r_menu := id;
  params.r_icon := 0;
  params.r_parentIsHandle := false;
  params.r_unaParent := parent;
  //
  create(params);
end;

// --  --
function unaWinWindow.createWindow(): hWnd;
begin
  result := doCreateWindow();
end;

// --  --
destructor unaWinWindow.destroy();
begin
  inherited;
  //
  if (nil <> f_notifyParent) then
    f_notifyParent.removeChild(self);
  //
  while (f_children.count > 0) do
    unaWinWindow(f_children[0]).free();
  //
  destroyWindow();
  //
  //freeAndNil(f_gate);
end;

// --  --
procedure unaWinWindow.destroyWindow();
begin
  if (0 <> f_handle) then begin
    //
    if (Windows.DestroyWindow(f_handle)) then
      f_handle := 0;
  end;
end;

// --  --
function unaWinWindow.doCreateWindow(): hWnd;
var
  style: unsigned;
  vis: bool;
begin
  if (0 = f_handle) then begin
    //
    style := f_createParams.r_style;
    vis := (0 <> (WS_VISIBLE and style));
    f_createParams.r_style := style and not WS_VISIBLE;
    f_handle := unaCreateWindow(self);
    //
    if (0 <> f_handle) then begin
      result := f_handle;
      //
      style := f_createParams.r_class.f_wndClassW.style;
      f_isCommonDC := ((0 = (CS_CLASSDC and style)) and
		       (0 = (CS_OWNDC and style)) and
		       (0 = (CS_PARENTDC and style)));
      if (not isCommonDC) then
	Self.f_dc := getDC();
      //
      setAnchors();
      //
      if (not f_createParams.r_class.isCommon) then
	setText(f_createParams.r_captionW);
      //
      setFont(f_createParams.r_font);
      //
      if (0 <> f_createParams.r_icon) then
	sendMessage(WM_SETICON, ICON_BIG, int(f_createParams.r_icon));
      //
      if (nil <> unaParent) then begin
	//
	unaParent.addChild(self);
	//
	SetClassLong(wnd, GCL_HBRBACKGROUND, unaParent.winClass.f_wndClassW.hbrBackground);
      end;
      //
      if (vis) then begin
	//
	if (0 = f_winListIndex) then	// if main window
	  show(SW_SHOWDEFAULT)
	else
	  show(SW_SHOWNORMAL);
	//  
      end;
      //
      GetWindowRect(wnd, f_sizeRect);
      ScreenToClient(getParent(), f_sizeRect.topLeft);
      ScreenToClient(getParent(), f_sizeRect.bottomRight);
      //
      f_rect := f_sizeRect;
    end
    else
      result := 0;
  end
  else
    result := f_handle;
end;

// --  --
function unaWinWindow.enable(doEnable: bool): unaWinWindow;
begin
  EnableWindow(wnd, doEnable);
  result := self;
end;

// --  --
function unaWinWindow.endModal(modalResult: int): unaWinWindow;
begin
  f_modalResult := modalResult;
  result := self;
end;

// --  --
function unaWinWindow.enter(timeout: tTimeout): bool;
begin
  result := acquire(false, timeout); //f_gate.enter(timeout{$IFDEF DEBUG}, className{$ENDIF});
end;

// --  --
function unaWinWindow.getCreateParams(): punaWinCreateParams;
begin
  result := @f_createParams;
end;

// --  --
function unaWinWindow.getDC(clipRgn: hRGN; flags: unsigned; wnd: int): hDC;
var
  rwnd: hWnd;
begin
  result := 0;
  //
  if (-1 = wnd) then begin
    //
    if (not isCommonDC) then
      result := deviceContext;
    //
    rwnd := getHandle();
  end
  else
    rwnd := unsigned(wnd);
  //
  if (0 = result) then begin
    //
    if (0 = clipRgn) then
      result := Windows.GetDC(rwnd)	// do not remove Windows. here !!
    else
      result := Windows.GetDCEx(rwnd, clipRgn, flags);
  end;    
  //
  f_lastDC := result;
end;

// --  --
function unaWinWindow.getFont(): unaWinFont;
begin
  result := f_createParams.r_font;
end;

// --  --
function unaWinWindow.getHandle(): hWnd;
begin
  result := createWindow();
end;

// --  --
function unaWinWindow.getHeight(): int;
begin
  result := f_rect.Bottom - f_rect.Top;
end;

// --  --
function unaWinWindow.getLeft(): int;
begin
  result := f_rect.Left;
end;

// --  --
function unaWinWindow.getParent(): hWnd;
begin
  if (f_createParams.r_parentIsHandle) then begin
    result := f_createParams.r_winParent;
  end
  else
    if (nil <> f_createParams.r_unaParent) then
      result := unaWinWindow(f_createParams.r_unaParent).wnd
    else
      result := 0;
  //
  if (0 = result) then
    result := getDesktopWindow();
end;

// --  --
function unaWinWindow.getText(): string;
var
  len: unsigned;
begin
  len := getTextLength();
  setLength(result, len);
  //
  if (0 < len) then
    GetWindowText(wnd, @result[1], len + 1);
end;

// --  --
function unaWinWindow.getTextLength(): int;
begin
  result := GetWindowTextLength(wnd);
  //
  if (0 > result) then
    result := 0;
end;

// --  --
function unaWinWindow.getTop(): int;
begin
  result := f_rect.Top;
end;

// --  --
function unaWinWindow.getUnaParent(): unaWinWindow;
begin
  if (not f_createParams.r_parentIsHandle) then
    result := f_createParams.r_unaParent as unaWinWindow
  else
    result := nil;
end;

// --  --
function unaWinWindow.getWidth(): int;
begin
  result := f_rect.Right - f_rect.Left;
end;

// --  --
function unaWinWindow.getWndClass(): unaWinClass;
begin
  result := f_createParams.r_class;
end;

// --  --
function unaWinWindow.hasStyle(index: integer): bool;
begin
  result := (0 <> (index and GetWindowLong(wnd, GWL_STYLE)));
end;

// --  --
procedure unaWinWindow.idle();
begin
  // nothing here
end;

// --  --
function unaWinWindow.initWindow(): bool;
begin
  result := true;
end;

// --  --
procedure unaWinWindow.leave();
begin
  releaseWO();
end;

// --  --
function unaWinWindow.messageBox(const text, caption: string; flags: unsigned): unsigned;
begin
  result := guiMessageBox(text, caption, flags or MB_ICONINFORMATION, wnd);
end;

// --  --
function unaWinWindow.notifyActivate(isActivate: bool): bool;
begin
  result := true;	// allow default processing
end;

// --  --
function unaWinWindow.notifyCreate(cs: pCREATESTRUCT): bool;
begin
  result := true;	// accept window creation
end;

// --  --
function unaWinWindow.notifyDestroy(): bool;
begin
  result := false;	// pass control to defProc
end;

// --  --
function unaWinWindow.onActivate(wayOfActivate: unsigned; window: hWnd): bool;
begin
  result := false;	// pass control to defProc
end;

// --  --
function unaWinWindow.onActivateApp(isActivate: bool; activeThreadId: unsigned): bool;
begin
  result := false;	// pass control to defProc
end;

// --  --
function unaWinWindow.onClick(button, x, y: word): bool;
begin
  result := false;	// pass control to defProc
end;

// --  --
function unaWinWindow.onClose(): bool;
begin
  show(SW_HIDE);
  //
  result := false;
end;

// --  --
function unaWinWindow.onCommand(cmd, wnd: int): bool;
begin
  if (assigned(f_wmCommand)) then
    result := (0 = f_wmCommand(self, cmd, wnd))
  else
    result := false;	// pass control to defProc
  //
  if (not result) then
    //
    f_modalResult := cmd and $FFFF;
end;

// --  --
function unaWinWindow.onCreate(cs: pCREATESTRUCT): int;
begin
  result := 0;	// indicate OK
end;

// --  --
function unaWinWindow.onDestroy(): bool;
begin
  f_modalResult := -1;
  result := false;	// pass control to defProc
end;

// --  --
function unaWinWindow.onEnterSizeMove(): bool;
begin
  result := false;	// pass control to defProc
end;

// --  --
function unaWinWindow.onGetDlgCode(): LRESULT;
begin
  result := 0;	// no special Dlg behavior
end;

// --  --
function unaWinWindow.onGetMinMaxInfo(infO: pMINMAXINFO): bool;
begin
  if (0 < f_minWidth) then
    info.ptMinTrackSize.X := f_minWidth;
  if (0 < f_minHeight) then
    info.ptMinTrackSize.Y := f_minHeight;
  //
  result := true;
end;

// --  --
function unaWinWindow.onGetText(buf: paChar; maxSize: unsigned): int;
begin
  result := -1;//length(strCopy(buf, f_caption, maxSize));
end;

// --  --
function unaWinWindow.onKeyDown(vkCode: unsigned; keyData: int): bool;
begin
  result := true;
end;

// --  --
function unaWinWindow.onMove(x, y: int): bool;
begin
  getWindowRect(wnd, f_rect);
  screenToClient(getParent(), f_rect.TopLeft);
  screenToClient(getParent(), f_rect.BottomRight);
  //
  result := false;
end;

// --  --
function unaWinWindow.onPaint(param: int): bool;
begin
  result := false;	// pass control to defProc
end;

// --  --
function unaWinWindow.onPosChange(pos: pWINDOWPOS): bool;
begin
  result := false;	// pass control to defProc
end;

// --  --
function unaWinWindow.onShow(isShow: bool; reason: unsigned): bool;
begin
  result := false;	// pass control to defProc
end;

// --  --
function unaWinWindow.onSize(action, height, width: unsigned): bool;
var
  i: int;
  rect: TRECT;
  dh, dw: int;
begin
  case (action) of

    //
    SIZE_MINIMIZED: begin
      f_rect.Left := 0;
      f_rect.Top := 0;
      f_rect.Right := minWidth;
      f_rect.Bottom := minHeight;
      result := false;
    end;

    //
    SIZE_MAXIMIZED,
    SIZE_RESTORED: begin
      //
      GetWindowRect(wnd, rect);
      i := 0;
      dh := (rect.Bottom - rect.Top) - (f_sizeRect.Bottom - f_sizeRect.Top);
      dw := (rect.Right - rect.Left) - (f_sizeRect.Right - f_sizeRect.Left);
      while (i < f_children.count) do begin
        //
	unaWinWindow(f_children.get(i)).parentResize(dw, dh);
	inc(i);
      end;
      //
      ScreenToClient(getParent(), rect.TopLeft);
      ScreenToClient(getParent(), rect.BottomRight);
      f_rect := rect;
      f_sizeRect := rect;
      update();
      result := false;
    end

    else
      result := false;

  end;
end;

// --  --
function unaWinWindow.parentResize(dw, dh: int): unaWinWindow;
var
  rect: TRECT;
  x, y, h, w: int;
begin
  if ((0 <> getParent()) and ((0 <> dw) or (0 <> dh))) then begin
    //
    GetWindowRect(wnd, rect);
    ScreenToClient(getParent(), rect.TopLeft);
    ScreenToClient(getParent(), rect.BottomRight);

    x := rect.Left;	// left anchor by default
    y := rect.Top;	// top anchor by default

    // BOTTOM:
    if (0 <> f_anchors and unaWinAnchor_BOTTOM) then
      if (0 = f_anchors and unaWinAnchor_TOP) then begin
	h := rect.Bottom - rect.Top;
	inc(y, dh);
      end
      else
	h := rect.Bottom - rect.Top + dh
    else
      h := rect.Bottom - rect.Top;

    // RIGTH:
    if (0 <> f_anchors and unaWinAnchor_RIGHT) then
      if (0 = f_anchors and unaWinAnchor_LEFT) then begin
	w := rect.Right - rect.Left;
	inc(x, dw);
      end
      else
	w := rect.Right - rect.Left + dw
    else
      w := rect.Right - rect.Left;

    //
    MoveWindow(wnd, x, y, w, h, true);
  end;
  result := self;
end;

// --  --
function unaWinWindow.postMessage(message: unsigned; wParam, lParam: int): bool;
begin
  result := Windows.PostMessage(wnd, message, wParam, lParam);
end;

// --  --
function unaWinWindow.processMessages(): unaWinWindow;
var
  msg: tagMSG;
begin
  repeat
    if (PeekMessage(msg, wnd, 0, 0, PM_REMOVE)) then

      if (not IsDialogMessage(wnd, msg)) then begin
	//
	TranslateMessage(msg);
	DispatchMessage(msg);
      end
      else

    else
      break;
  until (false);
  //
  result := self;
end;

// --  --
function unaWinWindow.redraw(): unaWinWindow;
begin
  RedrawWindow(wnd, nil, 0, RDW_ERASE + RDW_INVALIDATE);
  //
  result := self;
end;

// --  --
function unaWinWindow.releaseDC(dc: hDC): int;
var
  rdc: hDC;
begin
  if (not isCommonDC) then
    result := 1
  else begin
    if (0 = dc) then
      rdc := f_lastDC
    else
      rdc := dc;
    //
    result := Windows.ReleaseDC(wnd, rdc);
  end;
end;

// --  --
procedure unaWinWindow.removeChild(child: unaWinWindow);
begin
  f_children.removeItem(child);
end;

// --  --
function unaWinWindow.selectFont(dc: hDC): unsigned;
begin
  if (nil <> f_createParams.r_font) then
    result := SelectObject(dc, f_createParams.r_font.font)
  else
    result := 0;
end;

// --  --
function unaWinWindow.sendMessage(message: unsigned; wParam, lParam: int): int;
begin
{$IFNDEF NO_ANSI_SUPPORT }
  if (g_wideApiSupported) then
{$ENDIF NO_ANSI_SUPPORT }
    result := Windows.SendMessageW(wnd, message, wParam, lParam)
{$IFNDEF NO_ANSI_SUPPORT }
  else
    result := Windows.SendMessageA(wnd, message, wParam, lParam);
{$ENDIF NO_ANSI_SUPPORT }
  ;
end;

// --  --
function unaWinWindow.setAnchors(anchors: unsigned): unaWinWindow;
begin
  setFAnchors(anchors);
  result := self;
end;

// --  --
procedure unaWinWindow.setFAnchors(value: unsigned);
begin
  f_anchors := value;
end;

// --  --
procedure unaWinWindow.setFFont(value: unaWinFont);
begin
  f_createParams.r_font := value;
  //
  if ((nil <> value) and not isCommonDC) then
    postMessage(WM_SETFONT, int(value.font));
end;

// --  --
function unaWinWindow.setFocus(firstChild: bool): unaWinWindow;
begin
  if (firstChild) then
    if (0 < f_children.count) then
      result := f_children.get(0)
    else
      result := nil
  else
    result := self;
  //
  if (nil <> result) then
    Windows.SetFocus(result.wnd);
end;

// --  --
function unaWinWindow.setFont(font: unaWinFont): unaWinWindow;
begin
  setFFont(font);
  result := self;
end;

// --  --
procedure unaWinWindow.setHeight(value: int);
begin
  f_rect.Bottom := f_rect.Top + value;
  MoveWindow(wnd, f_rect.Left, f_rect.Top, getWidth(), getHeight(), true);
end;

// --  --
procedure unaWinWindow.setLeft(value: int);
var
  d: int;
begin
  d := value - f_rect.Left;
  f_rect.Left := value;
  inc(f_rect.Right, d);
  //
  MoveWindow(wnd, value, f_rect.Top, getWidth(), getHeight(), true);
end;

// --  --
procedure unaWinWindow.setMinHeight(value: int);
begin
  if (f_minHeight <> value) then begin
    //
    f_minHeight := value;
    if (height < value) then
      height := value;
  end;
end;

// --  --
procedure unaWinWindow.setMinWidth(value: int);
begin
  if (f_minWidth <> value) then begin
    //
    f_minWidth := value;
    if (width < value) then
      width := value;
  end;
end;

// --  --
function unaWinWindow.setText(const text: string): unaWinWindow;
begin
{$IFNDEF NO_ANSI_SUPPORT }
  if (g_wideApiSupported) then
{$ENDIF NO_ANSI_SUPPORT }
    sendMessage(WM_SETTEXT, 0, int(pwChar(wString(text))))
{$IFNDEF NO_ANSI_SUPPORT }
  else
    sendMessage(WM_SETTEXT, 0, int(paChar(aString(text))));
{$ENDIF NO_ANSI_SUPPORT }
  ;
  //
  result := self;
end;

// --  --
procedure unaWinWindow.setTop(value: int);
var
  d: int;
begin
  d := (value - f_rect.Top);
  f_rect.Top := value;
  inc(f_rect.Bottom, d);
  //
  MoveWindow(wnd, f_rect.Left, f_rect.Top, getWidth(), getHeight(), true);
end;

// --  --
procedure unaWinWindow.setWidth(value: int);
begin
  f_rect.Right := f_rect.Left + value;
  MoveWindow(wnd, f_rect.Left, f_rect.Top, getWidth(), getHeight(), true);
end;

// --  --
procedure unaWinWindow.setWinHandle(h: hWnd);
begin
  if (f_handle <> h) then begin
    //
    f_handle := h;
  end;
end;

// --  --
procedure unaWinWindow.setWinListIndex(i: int);
begin
  f_winListIndex := i;
  //
  if (not f_createParams.r_class.isCommon and (0 < f_handle)) then
    SetWindowLong(f_handle, 0, $19730000 + i);
end;

// --  --
function unaWinWindow.show(cmd: unsigned): unaWinWindow;
begin
  ShowWindow(wnd, cmd);
  result := self;
end;

// --  --
function unaWinWindow.showModal(cmd: unsigned = SW_SHOW): int;
var
  msg: tagMSG;
begin
  f_modalResult := 0;
  show(cmd).redraw().setFocus(true);
  //
  repeat
    if (PeekMessage(msg, wnd, 0, 0, PM_REMOVE)) then
      //
      case (msg.message) of

	WM_QUIT: begin
	  f_modalResult := -1;
	  break;	// WM_QUIT
	end;  

	else begin
	  if (not IsDialogMessage(wnd, msg)) then begin
	    //
	    TranslateMessage(msg);
	    DispatchMessage(msg);
	  end;
	end;
      end

    else begin
      idle();
      Sleep(10);
    end;
    //
  until (0 <> f_modalResult);
  //
  result := f_modalResult;
end;

// --  --
function unaWinWindow.textOut(const text: string; x, y: int; dc: hDC): bool;
var
  rdc: hDC;
begin
  if (0 < length(text)) then begin
    //
    if (not isCommonDC) then begin
      //
      if (0 = dc) then
	rdc := deviceContext
      else
	rdc := dc;
      //
{$IFNDEF NO_ANSI_SUPPORT }
      if (g_wideApiSupported) then
{$ENDIF NO_ANSI_SUPPORT }
	result := Windows.TextOutW(rdc, x, y, pwChar(wString(text)), length(text))
{$IFNDEF NO_ANSI_SUPPORT }
      else
	result := Windows.TextOutA(rdc, x, y, paChar(aString(text)), length(text))
{$ENDIF NO_ANSI_SUPPORT }
      ;
    end
    else begin
      //
      if (0 = dc) then
	rdc := getDC()
      else
	rdc := dc;
      //
      selectFont(rdc);
{$IFNDEF NO_ANSI_SUPPORT }
      if (g_wideApiSupported) then
{$ENDIF NO_ANSI_SUPPORT }
	result := Windows.TextOutW(rdc, x, y, pwChar(wString(text)), length(text))
{$IFNDEF NO_ANSI_SUPPORT }
      else
	result := Windows.TextOutA(rdc, x, y, paChar(aString(text)), length(text));
{$ENDIF NO_ANSI_SUPPORT }
      ;
      //
      if (0 = dc) then
	releaseDC();
    end
  end
  else
    result := true;
end;

// --  --
function unaWinWindow.update(): unaWinWindow;
begin
  UpdateWindow(wnd);
  processMessages();
  //
  result := self;
end;

// --  --
function unaWinWindow.wndProc(message, wParam, lParam: int): int;
var
  dp: bool;
  i: int;
begin
  result := 0;
  //
  case (message) of

    WM_NCCREATE: begin
      //
      result := choice(notifyCreate(pointer(lParam)), unsigned(1), 0);
      dp := false;
    end;


    WM_NCDESTROY: begin
      //
      dp := not notifyDestroy();
      if (lockNonEmptyList_r(g_winList, false, 100 {$IFDEF DEBUG }, '.wndProc(_WM_NCDESTROY_)'{$ENDIF DEBUG })) then try
	// need to update indexes of other windows
	i := f_winListIndex + 1;
	while (i < int(g_winList.count)) do begin
	  //
	  with (unaWinWindow(g_winList[i])) do begin
	    //
	    // NOTE: wnd here is NOT our wnd
	    setWinListIndex(i - 1);
	  end;
	  //
	  inc(i);
	end;
	//
	g_winList.removeById(f_handle);
	//
      finally
	g_winList.unlockWO();
      end;
      //
      f_handle := 0;	// regardless of return value - remove the handle
    end;


    WM_NCACTIVATE: begin
      //
      result := choice(notifyActivate(0 <> wParam), int(1), 0);
      dp := (1 = result);
    end;


    WM_CREATE: begin
      //
      result := onCreate(pointer(lParam));
      dp := (0 = result);
    end;


    WM_DESTROY:
      dp := not onDestroy();


    WM_CLOSE:
      dp := onClose();


    WM_ACTIVATE:
      dp := not onActivate(wParam, lParam);


    WM_ACTIVATEAPP:
      dp := not onActivateApp((0 <> wParam), unsigned(lParam));


    WM_COMMAND:
      dp := not onCommand(wParam, lParam);


    WM_GETMINMAXINFO:
      dp := not onGetMinMaxInfo(pMINMAXINFO(lParam));


    WM_GETTEXT: begin
      //
      result := onGetText(paChar(lParam), wParam);
      dp := (0 <> result);
    end;


    WM_KEYDOWN:
      dp := onKeyDown(wParam, lParam);


    WM_LBUTTONDOWN:
      dp := not onClick(wParam, (lParam and $FFFF), (lParam shr 16));


    WM_ENTERSIZEMOVE:
      dp := not onEnterSizeMove();


    WM_MOVE:
      dp := not onMove(lParam and $FFFF, lParam shr 16);


    WM_PAINT:
      dp := not onPaint(wParam);


    WM_SHOWWINDOW:
      dp := not onShow((0 <> wParam), lParam);


    WM_SIZE:
      // adjust children sizes and positions according to their anchors
      dp := not onSize(wParam, lParam shr 16, lParam and $FFFF);


    WM_WINDOWPOSCHANGING:
      dp := not onPosChange(pointer(lParam));


    WM_GETDLGCODE: begin
      //
      result := onGetDlgCode();
      dp := (0 = result);
    end;

    else
      dp := true;
  end;
  //
  if (f_createParams.r_class.isCommon) then
    result := f_createParams.r_class.callSubClassedWndProc(wnd, message, wParam, lParam)
  else
    if (dp) then
      result := defWndProc(wnd, message, wParam, lParam);
end;


{ unaWinSplashWindow }

// --  --
procedure unaWinSplashWindow.beforeDestruction();
begin
  inherited;
  //
  freeAndNil(f_static);
end;

// --  --
constructor unaWinSplashWindow.create(const text: string; parent: unaWinWindow; w, h: int);
var
  dc: hDC;
  x, y: int;
begin
  dc := Windows.GetDC(0);
  x := (GetDeviceCaps(dc, HORZRES) - w) div 2;
  y := (GetDeviceCaps(dc, VERTRES) - h) div 2;
  inherited create(unaWinClass.create('', CS_SAVEBITS, 0, 0, 0, COLOR_3DHILIGHT), nil, '', parent.wnd, WS_POPUP or WS_BORDER or WS_VISIBLE, 0, x, y, w, h);
  //
  f_static := unaWinStatic.create(text, self, 0, (h - 20) div 2, w - 2, 32, SS_NOPREFIX or SS_CENTER or WS_CHILD or WS_VISIBLE);
  processMessages();
end;

// --  --
function unaWinSplashWindow.onClick(button, x, y: word): bool;
begin
  show(SW_HIDE);
  result := true;
end;

// --  --
function unaWinSplashWindow.parentResize(dw, dh: int): unaWinWindow;
begin
  // splash window should not resize with parent
  result := self;
end;

// --  --
procedure unaWinSplashWindow.setText(const text: string; doShow: bool);
begin
  //
  if (doShow) then begin
    //
    show();
    BringWindowToTop(wnd);
    //
    f_static.show();
    f_static.setText(text);
  end;
end;


{ unaWinButton }

// --  --
constructor unaWinButton.create(const caption: string; parent: unaWinWindow; id: unsigned; x, y, w, h: int; style: unsigned);
begin
  inherited createStdWnd('BUTTON', caption, parent, style, 0, x, y, w, h, id);
end;

{ unaWinCheckBox }

// --  --
constructor unaWinCheckBox.create(const caption: string; parent: unaWinWindow; id: unsigned; x, y, w, h: int; style: unsigned);
begin
  inherited createStdWnd('BUTTON', caption, parent, style, 0, x, y, w, h, id);
end;

// --  --
function unaWinCheckBox.getChecked(): bool;
begin
  result := (BST_CHECKED = sendMessage(BM_GETCHECK));
end;

// --  --
procedure unaWinCheckBox.setChecked(value: bool);
begin
  sendMessage(BM_SETCHECK, choice(value, int(BST_CHECKED), BST_UNCHECKED));
end;


{ unaWinCombobox }

// --  --
function unaWinCombobox.add(const str: string): unaWinCombobox;
begin
{$IFNDEF NO_ANSI_SUPPORT }
  if (g_wideApiSupported) then
{$ENDIF NO_ANSI_SUPPORT }
    sendMessage(CB_ADDSTRING, 0, int(pwChar(wString(str))))
{$IFNDEF NO_ANSI_SUPPORT }
  else
    sendMessage(CB_ADDSTRING, 0, int(paChar(aString(str))));
{$ENDIF NO_ANSI_SUPPORT }
  ;
  //
  result := self;
end;

// --  --
constructor unaWinCombobox.create(parent: unaWinWindow; x, y, w, h: int; style: unsigned);
begin
  inherited createStdWnd('COMBOBOX', '', parent, style, 0, x, y, w, h);
end;

// --  --
function unaWinCombobox.findString(const str: string): int;
begin
{$IFNDEF NO_ANSI_SUPPORT }
  if (g_wideApiSupported) then
{$ENDIF NO_ANSI_SUPPORT }
    result := sendMessage(CB_FINDSTRING, -1, int(pwChar(wString(str))))
{$IFNDEF NO_ANSI_SUPPORT }
  else
    result := sendMessage(CB_FINDSTRING, -1, int(paChar(aString(str))));
{$ENDIF NO_ANSI_SUPPORT }
  ;
  //
  if (CB_ERR = result) then
    result := -1;
end;

// --  --
function unaWinCombobox.getCount(): unsigned;
begin
  result := unsigned(sendMessage(CB_GETCOUNT));
  if (CB_ERR = int(result)) then
    result := 0;
end;

// --  --
function unaWinCombobox.getItemIndex(): int;
begin
  result := sendMessage(CB_GETCURSEL);
  if (CB_ERR = result) then
    result := -1;
end;

// --  --
procedure unaWinCombobox.setItemIndex(value: int);
begin
  sendMessage(CB_SETCURSEL, value);
end;


{ unaWinEdit }

// --  --
constructor unaWinEdit.create(const text: string; parent: unaWinWindow; x, y, w, h: int; style: unsigned; exStyle: unsigned);
begin
  inherited createStdWnd('EDIT', text, parent, style, exStyle, x, y, w, h);
end;

// --  --
function unaWinEdit.onGetDlgCode(): LRESULT;
begin
  result := DLGC_WANTTAB;
end;

// --  --
function unaWinEdit.setReadOnly(value: bool): unaWinEdit;
begin
  sendMessage(EM_SETREADONLY, int(value));
  result := self;
end;


{ unaWinMemo }

// --  --
constructor unaWinMemo.create(const text: string; parent: unaWinWindow; x, y, w, h: int; style: unsigned);
begin
  inherited create(text, parent, x, y, w, h, style);
end;

// --  --
function unaWinMemo.getLine(index: unsigned): string;
var
  bufW: array[0..16383] of wChar;
  bufA: array[0..16383] of aChar;
  len: int;
begin
  len := sizeOf(bufW);
  move(len, bufW[0], 2);
  len := sizeOf(bufA);
  move(len, bufA[0], 2);
  //
{$IFNDEF NO_ANSI_SUPPORT }
  if (g_wideApiSupported) then
{$ENDIF NO_ANSI_SUPPORT }
    len := sendMessage(EM_GETLINE, index, int(@bufW))
{$IFNDEF NO_ANSI_SUPPORT }
  else
    len := sendMessage(EM_GETLINE, index, int(@bufA));
{$ENDIF NO_ANSI_SUPPORT }
  ;
  //
  if (0 < len) then begin
    //
{$IFNDEF NO_ANSI_SUPPORT }
    if (g_wideApiSupported) then
{$ENDIF NO_ANSI_SUPPORT }
      result := string(bufW)
{$IFNDEF NO_ANSI_SUPPORT }
    else
      result := string(bufA);
{$ENDIF NO_ANSI_SUPPORT }
    ;
  end
  else
    result := '';
end;

// --  --
function unaWinMemo.onCommand(cmd, wnd: int): bool;
begin
  result := inherited onCommand(cmd, wnd);
end;

// --  --
function unaWinMemo.replaceSel(const line: string): unaWinMemo;
{$IFNDEF NO_ANSI_SUPPORT }
var
  str: aString;
{$ENDIF NO_ANSI_SUPPORT }
begin
{$IFNDEF NO_ANSI_SUPPORT }
  if (g_wideApiSupported) then
{$ENDIF NO_ANSI_SUPPORT }
    sendMessage(EM_REPLACESEL, 1, int(pwChar(wString(line))))
{$IFNDEF NO_ANSI_SUPPORT }
  else begin
    //
    str := aString(line);
    sendMessage(EM_REPLACESEL, 1, int(paChar(aString(str))));
  end;
{$ENDIF NO_ANSI_SUPPORT }
  ;
  //
  result := self;
end;

// --  --
function unaWinMemo.setSel(starting, ending: int): unaWinMemo;
begin
  sendMessage(EM_SETSEL, starting, ending);
  result := self;
end;


{ unaWinListBox }

// --  --
constructor unaWinListBox.create(parent: unaWinWindow; x, y, w, h: int; style: unsigned);
begin
  inherited createStdWnd('LISTBOX', '', parent, style, 0, x, y, w, h);
end;


{ unaWinStatic }

// --  --
constructor unaWinStatic.create(const caption: string; parent: unaWinWindow; x, y, w, h: int; style: unsigned);
begin
  inherited createStdWnd('STATIC', caption, parent, style, 0, x, y, w, h);
end;


{ unaWinTootip }

// --  --
function unaWinTootip.activateTrack(doActivate: bool): LRESULT;
begin
  result := SendMessage(handle, TTM_TRACKACTIVATE, WPARAM(doActivate), LPARAM(@f_info));
  //
  f_isActive := doActivate;
end;

// --  --
procedure unaWinTootip.BeforeDestruction;
begin
  inherited;
  //
  if (0 <> handle) then begin
    // unsubclass a window
    //SetWindowLong(handle, GWL_WNDPROC, int(f_oldWndProc));
    //
    DestroyWindow(handle);
    //
    f_handle := 0;
  end;
end;

// --  --
constructor unaWinTootip.create(const tip: string; parent: tHandle; style: unsigned; flags: DWORD);
begin
  f_handle := CreateWindowExW(
    //
    WS_EX_TOPMOST,
    TOOLTIPS_CLASS,
    nil,
    style,
    integer(CW_USEDEFAULT),
    integer(CW_USEDEFAULT),
    integer(CW_USEDEFAULT),
    integer(CW_USEDEFAULT),
    parent,
    0,
    hInstance,
    nil
  );
  //
  if (0 <> handle) then begin
    //
    // subclass for multi-line support
    //f_oldCapWndProc := TFNWndProc(SetWindowLong(handle, GWL_WNDPROC, int(@subclassProc)));
    //
    fillChar(f_info, sizeOf(f_info), #0);
    f_info.cbSize := sizeof(f_info);
    f_info.uFlags := flags;
    f_info.hwnd := parent;
    f_info.hinst := hInstance;
    f_info.uId := 0;
    self.tip := tip;
    //
    if (0 = (TTF_TRACK and flags)) then
      Windows.GetClientRect(parent, f_info.rect);
    //
    SendMessage(handle, TTM_ADDTOOLW, 0, LPARAM(@f_info));
  end;
end;

// --  --
procedure unaWinTootip.setTip(const tip: string);
begin
  f_tip := tip;
  f_info.lpszText := pwChar(wString(f_tip));
  //
  SendMessage(handle, TTM_UPDATETIPTEXTW, 0, LPARAM(@f_info));
end;


{ unaWinApp }

// --  --
procedure unaWinApp.afterConstruction();
begin
  inherited;
  //
  f_sleepEvent := unaEvent.create();
end;

// --  --
procedure unaWinApp.beforeDestruction();
begin
  inherited;
  //
  freeAndNil(f_sleepEvent);
end;

// --  --
function unaWinApp.initWindow(): bool;
begin
  f_okToRun := inherited initWindow();
  //
  result := f_okToRun;
end;

// --  --
function unaWinApp.notifyDestroy(): bool;
begin
  quit(exitCode);
  //
  result := false;
end;

// --  --
function unaWinApp.onActivateApp(isActivate: bool; activeThreadId: unsigned): bool;
begin
  result := false;	// pass control to defProc
end;

// --  --
function unaWinApp.onClose(): bool;
begin
  result := inherited onClose();
  //
  quit();
end;

// --  --
function unaWinApp.onRunEnterLeave(enter: bool): bool;
begin
  f_isRunning := enter;
  //
  result := true;
end;

// --  --
procedure unaWinApp.quit(exitCode: int);
begin
  PostQuitMessage(exitCode);
  //
  Sleep(10);
  //
  // sometimes quit message does not reach app run() cycle, so we also set termination code explicitly
  f_mustTerminate := true;
end;

// --  --
function unaWinApp.run(): unaWinApp;
var
  msg: tagMSG;
  ok: bool;
begin
  if (f_okToRun) then begin
    //
    f_mustTerminate := false;
    //
    setFocus(true);
    if (onRunEnterLeave(true)) then begin
      //
      repeat
	//
	ok := PeekMessage(msg, getHandle(), 0, 0, PM_REMOVE);
	//
	if (not ok and f_mustTerminate) then begin
	  //
	  msg.message := WM_QUIT;
	  ok := true;
	end;

	//
	if (ok) then begin
	  //
	  case (msg.message) of

	    WM_QUIT: begin
	    {$IFDEF DEBUG }
	      msg.message := WM_QUIT;	// breakpoint point
	    {$ENDIF }
	      break;	// WM_QUIT
	    end;

	    else begin
	      if (IsDialogMessage(getHandle(), msg)) then
		//
	      else begin
		//
		TranslateMessage(msg);
		DispatchMessage(msg);
	      end;
	    end;

	  end;
	  //
	end
	else begin
	  //
	  f_sleepEvent.waitFor(15);
	  idle();
	end;

      until (false);
    end;
    //
    onRunEnterLeave(false);
  end;
  //
  result := self;
end;

// --  --
procedure unaWinApp.wakeUp();
begin
  f_sleepEvent.setState();
end;


{ unaWinGraphicsApp }

// --  --
constructor unaWinGraphicsApp.create(fps, frameWidth, frameHeight: unsigned; bgColor: COLORREF; const title: string; canResize, canMinimize: bool; x, y, icon, windowFlags, windowExFlags, memWidth, memHeight: int);
begin
  f_fps := fps;
  f_bgColor := bgColor;
  //
  f_canResize := canResize;
  f_frameWidth := frameWidth;
  f_frameHeight := frameHeight;
  //
  f_memXSize := memWidth;	// if = -1, will be set to frameWidth
  f_memYSize := memHeight;	// if = -1, will be set to frameHeigh
  //
  if (-1 = windowExFlags) then
    windowExFlags := WS_EX_WINDOWEDGE or WS_EX_APPWINDOW;
  //
  if (-1 = windowFlags) then
    windowFlags := choice(canMinimize, WS_MINIMIZEBOX, unsigned(0)) or WS_SYSMENU or choice(canResize, WS_SIZEBOX, unsigned(0)) or WS_OVERLAPPED;
  //
  inherited create(getClass('', false, 0, 0, 0, 0, f_bgBrush), nil, title, 0, unsigned(windowFlags), unsigned(windowExFlags), x, y, frameWidth, frameHeight, 0, 0, choice(-1 = icon, LoadIcon(GetModuleHandle(nil), 'MAINICON'), unsigned(icon)));
  //
  initApp();
end;

// --  --
constructor unaWinGraphicsApp.create(wnd: hWnd; fps: unsigned; bgColor: COLORREF; const title: string; canResize: bool; memWidth, memHeight: int);
var
  params: unaWinCreateParams;
begin
  f_handle := wnd;
  f_fps := fps;
  f_bgColor := bgColor;
  //
  f_canResize := canResize;
  f_frameWidth := 0;	// will be taken from wnd
  f_frameHeight := 0;	// will be taken from wnd
  //
  f_memXSize := memWidth;	// if = -1, will be set to frameWidth
  f_memYSize := memHeight;	// if = -1, will be set to frameHeigh
  //
  fillChar(params, sizeof(params), #0);
  inherited create(params);
  //
  initApp();
end;

// --  --
destructor unaWinGraphicsApp.destroy();
begin
  inherited;
  //
  freeAndNil(f_drawTimer);
  //
  DeleteObject(f_memDIB);
  //
  DeleteObject(f_bgBrush);
  DeleteDC(f_memDC);
  //
  releaseDC(grDC);
end;

// --  --
function unaWinGraphicsApp.doCreateWindow(): hWnd;
begin
  result := inherited doCreateWindow()
end;

// --  --
procedure unaWinGraphicsApp.initApp();
var
  rect: tRect;
begin
  f_drawTimer := unaThreadTimer.create(1000 div fps, false);
  f_drawTimer.onTimer := myOnDrawTimer;
  //
  f_bgBrush := CreateSolidBrush(f_bgColor);
  //
  if (0 <> getHandle()) then begin
    //
    if (IsWindow(getHandle())) then begin
      //
      if (GetClientRect(getHandle(), rect)) then begin;
	//
	if (0 = frameHeight) then begin
	  f_frameHeight := rect.Bottom - rect.Top;
	  f_rect := rect;
	end;
	if (0 = frameWidth) then begin
	  f_frameWidth := rect.Right - rect.Left;
	  f_rect := rect;
	end;
	//
	if (frameHeight > unsigned(rect.Bottom)) then
	  height := frameHeight + (frameHeight - unsigned(rect.Bottom));
	if (frameWidth > unsigned(rect.Right)) then
	  width := frameWidth + (frameWidth - unsigned(rect.Right));
      end;
      //
      show();
      //
      f_grDC := getDC();
      SetBkColor(f_grDC, bgColor);
      //
      if (f_memXSize < 0) then
	f_memXSize := frameWidth;
      //
      if (f_memYSize < 0) then
	f_memYSize := frameHeight;
      //
      //
      f_memBmpInfo.bmiHeader.biSize := sizeOf(f_memBmpInfo.bmiHeader);
      //
      f_memBmpInfo.bmiHeader.biWidth := f_memXSize;
      f_memBmpInfo.bmiHeader.biHeight := f_memYSize;
      f_memBmpInfo.bmiHeader.biPlanes := 1;
      f_memBmpInfo.bmiHeader.biClrUsed := 0;
      //
      f_memBmpInfo.bmiHeader.biBitCount := 32;
      f_memBmpInfo.bmiHeader.biSizeImage := f_memXSize * f_memYSize * (f_memBmpInfo.bmiHeader.biBitCount shr 3);
      f_memBmpInfo.bmiHeader.biCompression := BI_RGB;
      f_memDIB := CreateDIBSection(0, f_memBmpInfo, DIB_RGB_COLORS, f_memBmpBits, 0, 0);
      //
      f_memDC := CreateCompatibleDC(0);
      SelectObject(f_memDC, f_memDIB);
      SelectObject(f_memDC, f_bgBrush);
      SetBkColor(f_memDC, bgColor);
    end;
  end;
end;

// --  --
procedure unaWinGraphicsApp.myOnDrawTimer(sender: tObject);
begin
  if (eraseBg) then
    // clear bitmap
    PatBlt(memDC, 0, 0, f_frameWidth, f_frameHeight, PATCOPY);
  //
  inc(f_fcount);
  f_actualFps := (f_fcount * 1000) div timeElapsed32U(f_fpsMark);
  //
  // create new frame
  if (onDrawFrame()) then begin
    //
    if (f_canResize) then
      StretchBlt(f_grDC, 0, 0, width, height, f_memDC, 0, 0, f_memXSize, f_memYSize, SRCCOPY)
    else
      BitBlt(grDC, 0, 0, frameWidth, frameHeight, f_memDC, 0, 0, SRCCOPY);
    //
    wakeUp();
  end;
end;

// --  --
function unaWinGraphicsApp.onDrawFrame(): bool;
{$IFDEF DEBUG}
var
  s: string;
{$ENDIF DEBUG }
begin
{$IFDEF DEBUG}
  s := 'fps:' + int2str(f_actualFps);
{$IFNDEF NO_ANSI_SUPPORT }
  if (g_wideApiSupported) then
{$ENDIF NO_ANSI_SUPPORT }
    TextOutW(f_memDC, 2, 2, pwChar(wString(s)), length(s))
{$IFNDEF NO_ANSI_SUPPORT }
  else
    TextOutA(f_memDC, 2, 2, paChar(aString(s)), length(s));
{$ENDIF NO_ANSI_SUPPORT }
  ;
  //
{$ENDIF DEBUG }
  result := true;
end;

// --  --
function unaWinGraphicsApp.onRunEnterLeave(enter: bool): bool;
begin
  result := inherited onRunEnterLeave(enter);
  //
  if (result and (nil <> f_drawTimer)) then
    //
    if (enter) then begin
      f_fpsMark := timeMarkU();
      f_fcount := 0;
      f_drawTimer.start();
    end
    else
      f_drawTimer.stop();
  //
end;

// --  --
function unaWinGraphicsApp.setBits(x, y: int; data: pointer; size: unsigned): unsigned;
var
  ofs: unsigned;
begin
  result := 0;
  //
  if ((nil <> f_memBmpBits) and enter(40)) then
    try
      //
      y := min(f_memBmpInfo.bmiHeader.biHeight  - 1, max(y, 0));
      x := min(f_memBmpInfo.bmiHeader.biWidth - 1, max(x, 0));
      //
      ofs := (y * f_memBmpInfo.bmiHeader.biWidth + x) * (f_memBmpInfo.bmiHeader.biBitCount shr 3);
      //
      GdiFlush();
      move(data^, pArray(f_memBmpBits)[ofs], min(f_memBmpInfo.bmiHeader.biSizeImage - ofs, size));
      //
      result := size;
    finally
      leave();
    end;
end;

// --  --
procedure unaWinGraphicsApp.skipFrame();
begin
  dec(f_fcount);
end;


{ unaWinConsoleApp }

var
  g_outMessages: unaWideStringList;

// --  --
procedure myInfoMessageProc(const message: string);
begin
  if (nil = g_outMessages) then
    g_outMessages := unaWideStringList.create();
  //
  if (0 < length(message)) then begin
    //
    // due to potential deadlocks in multi-threading environment
    // we will just store messages here, and process them later in idle()
    g_outMessages.add(message);
  end;
end;

// --  --
constructor unaWinConsoleApp.create(hasGUi: bool; const caption, copy: string; const iniFile: wString; icon: hIcon; captionHeight: unsigned; btnExit, btnStart, btnStop: bool; style: unsigned; exStyle: unsigned);
var
  x, y, w, h: int;
  rect: TRECT;
begin
  f_hasGUi := hasGUi;
  //
  f_ini := unaIniFile.create(iniFile, 'debug');
  f_captionHeight := captionHeight;
  //
  setInfoMessageMode(f_ini.get('logFile', '<>'), myInfoMessageProc);
  //
  f_ini.section := 'ConsoleWindow';
  x := f_ini.get('x', int(10));
  y := f_ini.get('y', int(10));
  w := f_ini.get('w', int(400));
  h := f_ini.get('h', int(300));
  //
  inherited create(unaWinClass.create('#32770', CS_DBLCLKS, 0, 0, 0, COLOR_WINDOW, 0, 0, false), unaWinFont.create(), caption, 0, style, exStyle, x, y, w, h, 0, 0, icon);
  //
  if (f_hasGUi) then begin
    // create Exit, Start & Stop buttons
    if (btnExit) then
      f_btnExit := unaWinButton(unaWinButton.create(rstr_caption_exit, self, btnCmdExit));
    if (btnStart) then
      f_btnStart := unaWinButton(unaWinButton.create(rstr_caption_start, self, btnCmdStart, 70));
    if (btnStop) then
      f_btnStop := unaWinButton(unaWinButton.create(rstr_caption_stop, self, btnCmdStop, 138).enable(false));
    //
    // create an output window with nice font
    GetClientRect(wnd, rect);
    h := max(rect.bottom - int(captionHeight), 32);
    //
    f_memo := unaWinMemo(unaWinMemo.create('', self, 0, captionHeight, rect.right, h,
      ES_LEFT or ES_READONLY or WS_CHILD or ES_MULTILINE or ES_AUTOVSCROLL or ES_AUTOHSCROLL or WS_HSCROLL or WS_VSCROLL or WS_VISIBLE, WS_EX_LEFT + WS_EX_LTRREADING + WS_EX_RIGHTSCROLLBAR + WS_EX_NOPARENTNOTIFY + WS_EX_CLIENTEDGE
      ).setAnchors(unawinAnchor_LEFT or unawinAnchor_RIGHT or unawinAnchor_TOP or unawinAnchor_BOTTOM
      ).setFont(unaWinFont.create('', 0, 6, 0, 0, FW_THIN, false, false, false, DEFAULT_CHARSET, 0, 0, 0, FIXED_PITCH or FF_MODERN)
    ));
  end;
  //
  logMessage('winConsole version 1.1.3 / Copyright (c) 2002-2009 Lake of Soft');
  //
  f_okToRun := doInit();
end;

// --  --
destructor unaWinConsoleApp.destroy();
begin
  inherited;
  //
  freeAndNil(f_ini);
  freeAndNil(g_outMessages);
end;

// --  --
function convertMessage(const message: wString; addCRLF: bool): wString;
begin
  case (message[length(message)]) of

    #13: begin // looks like simple LF
      //
      result := message;
      delete(result, length(result), 1);
      result := convertMessage(result, false);
    end;

    #10: begin // looks like CR + LF
      //
      result := message;
      delete(result, length(result) - 1, 2);
      result := convertMessage(#13#10 + result, true);
    end

    else
      if (addCRLF) then
	result := #13#10 + message
      else
	result := message;
  end;
end;

// --  --
function unaWinConsoleApp.doInit(): bool;
begin
  result := true;
end;

// --  --
procedure unaWinConsoleApp.idle();
var
  i: int;
  len: int;
begin
  inherited;

  // 1. remove old information (if needed)
  repeat
    len := f_memo.getTextLength();
    if (hasGUI and (16384 < len)) then begin		// 16 KB should be enough to store old messages in memo
      //
      f_memo.setSel(len - 2048, len);	// 2048 is estimated size of new portion of output strings
      f_memo.replaceSel('');
    end
    else
      break;
    //
  until (false);
  //
  // 2. add new line(s)
  if ((nil <> g_outMessages) and enter(10)) then try
    //
    i := 0;
    //
    while (hasGUI and (i < g_outMessages.count)) do begin
      //
      f_memo.setSel(0, length(f_memo.getLine(0)));
      f_memo.replaceSel(convertMessage(g_outMessages.get(i), true));
      //
      inc(i);
    end;
    //
    g_outMessages.clear();
  finally
    leave();
  end;
end;

// --  --
function unaWinConsoleApp.onCommand(cmd, wnd: int): bool;
begin
  if (BN_CLICKED = cmd shr 16) then begin
    //
    case (cmd and $FFFF) of

      // exit
      btnCmdExit: begin
	//
	onStop();
	processMessages();
	quit();
      end;

      // start
      btnCmdStart:
	onStart();

      // stop
      btnCmdStop:
	onStop();

      else
	setFocus(true);
    end;
  end;
  //
  result := inherited onCommand(cmd, wnd);
end;

// --  --
function unaWinConsoleApp.onDestroy(): bool;
begin
  logMessage('terminating winConsole');
  //
  f_ini.section := 'ConsoleWindow';
  f_ini.setValue('x', left);
  f_ini.setValue('y', top);
  f_ini.setValue('w', width);
  f_ini.setValue('h', height);
  //
  setInfoMessageMode('<>', nil);
  //
  result := inherited onDestroy();
end;

// --  --
procedure unaWinConsoleApp.onStart();
begin
  if (hasGUI) then begin
    //
    if (nil <> f_btnStart) then
      f_btnStart.enable(false);
    //
    if (nil <> f_btnStop) then
      f_btnStop.enable(true);
  end;
end;

// --  --
procedure unaWinConsoleApp.onStop();
begin
  if (hasGUI) then begin
    //
    if (nil <> f_btnStart) then
      f_btnStart.enable(true);
    //
    if (nil <> f_btnStop) then
      f_btnStop.enable(false);
  end;
end;

// -- unit globals --

initialization
  //g_winCreateGate := unaInProcessGate.create({$IFDEF DEBUG}'winCreateGate()'{$ENDIF DEBUG });
  g_winList := unaWinList.create();
  g_winClasses := unaList.create(uldt_ptr);
  g_winFonts := unaList.create(uldt_ptr);

finalization
  //
  while (0 < g_winFonts.count) do
    unaWinFont(g_winFonts[0]).free();
  //
  while (0 < g_winClasses.count) do
    unaWinClass(g_winClasses[0]).free();
  //
  freeAndNil(g_winFonts);
  freeAndNil(g_winClasses);
  freeAndNil(g_winList);
  //freeAndNil(g_winCreateGate);
end.

